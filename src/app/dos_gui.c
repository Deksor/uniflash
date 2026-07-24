#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(UF_TARGET_DOS16)
#include <conio.h>
#endif

#include "uniflash/cmos.h"
#include "uniflash/gui.h"
#include "uniflash/image_store.h"
#include "uniflash/language.h"
#include "uniflash/menu.h"
#include "uniflash/read_workflow.h"
#include "uniflash/runtime.h"
#include "uniflash/version.h"
#include "uniflash/xms.h"

#if defined(UF_TARGET_DOS16)

enum {
    GUI_BLACK = 0,
    GUI_GREEN = 2,
    GUI_RED = 4,
    GUI_LIGHT_GRAY = 7,
    GUI_YELLOW = 14,
    GUI_WHITE = 15,
    GUI_LIGHT_GREEN = 10,
    GUI_LIGHT_CYAN = 11,
    GUI_LIGHT_MAGENTA = 13,
    GUI_LIGHT_RED = 12
};

typedef struct gui_state gui_state_t;
typedef void (*gui_action_fn)(gui_state_t *state);

typedef struct gui_menu_item {
    uf_message_id_t label_id;
    uf_message_id_t help_id;
    uint8_t row;
    bool enabled;
    gui_action_fn action;
} gui_menu_item_t;

struct gui_state {
    uf_runtime_t runtime;
    uf_xms_t xms;
    uf_image_store_t image_store;
    const uf_image_store_t *captured;
    uint8_t *transfer_buffer;
    uf_rom_size_t image_size;
    uint8_t cmos_last_index;
    bool runtime_ready;
    bool rom_enabled;
    bool xms_ready;
    bool done;
    char status[80];
};

static uint8_t gui_attribute = GUI_LIGHT_GRAY;
static uint8_t gui_column = 1;
static uint8_t gui_row = 1;
static bool gui_monochrome = false;

static const char *message(uf_message_id_t id) { return uf_language_get(&uf_language_english, id); }

static void gui_cursor(bool visible) {
    uint16_t shape = visible ? UINT16_C(0x0607) : UINT16_C(0x2000);
    _asm {
        mov ah,01h
        mov cx,shape
        int 10h
    }
}

static void gui_color(uint8_t foreground, uint8_t background) {
    if (gui_monochrome) {
        gui_attribute =
            background == GUI_BLACK ? (foreground == GUI_GREEN ? UINT8_C(0x07) : UINT8_C(0x0F)) : UINT8_C(0x70);
        return;
    }
    gui_attribute = (uint8_t)((background << 4) | (foreground & UINT8_C(0x0F)));
}

static void gui_move(uint8_t column, uint8_t row) {
    uint8_t bios_column = column - 1;
    uint8_t bios_row = row - 1;

    _asm {
        mov ah,02h
        xor bh,bh
        mov dh,bios_row
        mov dl,bios_column
        int 10h
    }
    gui_column = column;
    gui_row = row;
}

static void gui_put_char(char character) {
    uint8_t value = (uint8_t)character;
    uint8_t attribute = gui_attribute;

    _asm {
        mov ah,09h
        mov al,value
        xor bh,bh
        mov bl,attribute
        mov cx,1
        int 10h
    }
    if (gui_column < 80) {
        gui_move(gui_column + 1, gui_row);
    }
}

static void gui_puts(const char *text) {
    while (*text != '\0') {
        gui_put_char(*text++);
    }
}

static void gui_clear_screen(void) {
    uint8_t attribute = gui_attribute;

    _asm {
        mov ax,0600h
        mov bh,attribute
        xor cx,cx
        mov dx,184fh
        int 10h
    }
    gui_move(1, 1);
}

static void gui_write_at(uint8_t column, uint8_t row, const char *text) {
    gui_move(column, row);
    gui_puts(text);
}

static void gui_clear_line(uint8_t row) {
    gui_move(1, row);
    for (uint8_t column = 0; column < 80; ++column) {
        gui_put_char(' ');
    }
    gui_move(1, row);
}

static void gui_center(uint8_t row, const char *text) {
    size_t length = strlen(text);
    uint8_t column = length < 78 ? (uint8_t)((80U - length) / 2U) : 1;
    gui_write_at(column, row, text);
}

static void gui_set_status(gui_state_t *state, const char *text) {
    strncpy(state->status, text, sizeof(state->status) - 1);
    state->status[sizeof(state->status) - 1] = '\0';
}

static void gui_draw_header(void) {
    gui_clear_screen();
    gui_cursor(false);
    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_write_at(9, 2, UF_PRODUCT_NAME " " UF_VERSION_STRING " ");
    gui_color(GUI_LIGHT_GREEN, GUI_BLACK);
    gui_puts("C port");
    gui_color(GUI_LIGHT_CYAN, GUI_BLACK);
    gui_puts(" (c) 2026 Deksor");
    gui_color(GUI_LIGHT_MAGENTA, GUI_BLACK);
    gui_write_at(9, 3, "Original version by Pascal van Leeuwen & Galkowski Adam");
    gui_write_at(9, 4, "Maintained by Ondrej Zary (Rainbow Software) until 2005");
}

static void format_organisation(const uf_flash_chip_t *chip, char *output, size_t output_size) {
    switch (chip->behavior & UINT8_C(3)) {
    case UF_FLASH_BEHAVIOR_SECTOR:
        snprintf(output, output_size, "sectored (%lu bytes)", (unsigned long)chip->capacity_bytes);
        break;
    case UF_FLASH_BEHAVIOR_PAGE:
        snprintf(output,
            output_size,
            "%lu pages of %u bytes",
            (unsigned long)(chip->capacity_bytes / chip->page_size_bytes),
            (unsigned int)chip->page_size_bytes);
        break;
    case UF_FLASH_BEHAVIOR_BULK_ERASE:
        snprintf(output, output_size, "bulk erase (%lu bytes)", (unsigned long)chip->capacity_bytes);
        break;
    default:
        snprintf(output,
            output_size,
            "%lu sectors of %u bytes",
            (unsigned long)(chip->capacity_bytes / chip->page_size_bytes),
            (unsigned int)chip->page_size_bytes);
        break;
    }
}

static void gui_draw_information(gui_state_t *state) {
    char line[80];
    char organisation[60];

    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(5);
    gui_write_at(2, 5, message(51));
    gui_color(GUI_WHITE, GUI_BLACK);
    snprintf(line, sizeof(line), "%s %s", state->runtime.flash.manufacturer->name, state->runtime.flash.chip->name);
    gui_puts(line);

    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(6);
    gui_write_at(2, 6, message(53));
    gui_color(GUI_WHITE, GUI_BLACK);
    format_organisation(state->runtime.flash.chip, organisation, sizeof(organisation));
    gui_puts(organisation);

    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(7);
    gui_write_at(2, 7, message(61));
    gui_color(GUI_WHITE, GUI_BLACK);
    gui_puts(state->runtime.chipset.name);

    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(8);
    gui_write_at(2, 8, message(62));
    gui_color(GUI_WHITE, GUI_BLACK);
    gui_puts(message(63));

    gui_color(GUI_LIGHT_GRAY, GUI_BLACK);
    gui_clear_line(23);
    snprintf(line,
        sizeof(line),
        "%s%luK XMS%s",
        message(68),
        state->xms_ready ? (unsigned long)(state->xms.size_bytes >> 10) : 0UL,
        state->captured != NULL ? " (ROM image captured)" : "");
    gui_write_at(1, 23, line);
    gui_clear_line(24);
    snprintf(line, sizeof(line), "%s%08lX", message(69), (unsigned long)state->runtime.flash.rom_base);
    gui_write_at(1, 24, line);
}

static bool gui_prompt_filename(const char *prompt, char *path, uint8_t capacity) {
    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(20);
    gui_write_at(11, 20, prompt);
    gui_color(GUI_WHITE, GUI_BLACK);
    gui_cursor(true);
    path[0] = '\0';

    uint8_t length = 0;
    for (;;) {
        int key = getch();
        if (key == 13) {
            break;
        }
        if (key == 27) {
            length = 0;
            break;
        }
        if (key == 8 && length != 0) {
            --length;
            path[length] = '\0';
            if (gui_column > 1) {
                uint8_t previous_column = (uint8_t)(gui_column - 1);
                gui_move(previous_column, gui_row);
                gui_put_char(' ');
                gui_move(previous_column, gui_row);
            }
        } else if (key >= 32 && key <= 126 && length + 1 < capacity) {
            path[length++] = (char)key;
            path[length] = '\0';
            gui_put_char((char)key);
        } else if (key == 0) {
            (void)getch();
        }
    }
    gui_cursor(false);
    gui_clear_line(20);
    return length != 0;
}

static void gui_show_operation_result(gui_state_t *state, uf_read_result_t result, uf_message_id_t success_id) {
    gui_color(result == UF_READ_RESULT_OK ? GUI_LIGHT_GREEN : GUI_LIGHT_RED, GUI_BLACK);
    gui_clear_line(20);
    gui_center(20, result == UF_READ_RESULT_OK ? message(success_id) : uf_read_result_message(result));
    gui_set_status(state, result == UF_READ_RESULT_OK ? message(success_id) : uf_read_result_message(result));
    (void)getch();
    gui_clear_line(20);
}

static void gui_dump(gui_state_t *state) {
    char path[64];
    uf_read_result_t result;

    if (!gui_prompt_filename(message(6), path, sizeof(path))) {
        return;
    }
    result = uf_read_workflow_dump(&state->runtime.flash,
        state->captured,
        state->image_size,
        path,
        state->transfer_buffer,
        UF_READ_WORKFLOW_BUFFER_SIZE);
    gui_show_operation_result(state, result, 143);
}

static void gui_compare(gui_state_t *state) {
    char path[64];
    uf_read_result_t result;

    if (!gui_prompt_filename(message(6), path, sizeof(path))) {
        return;
    }
    result = uf_read_workflow_compare(&state->runtime.flash,
        state->captured,
        state->image_size,
        path,
        state->transfer_buffer,
        UF_READ_WORKFLOW_BUFFER_SIZE);
    gui_show_operation_result(state, result, 144);
}

static void gui_save_bootblock(gui_state_t *state) {
    char path[64];
    uf_read_result_t result;

    if (state->image_size < UINT32_C(8192)) {
        gui_show_operation_result(state, UF_READ_RESULT_INVALID_ARGUMENT, 143);
        return;
    }
    if (!gui_prompt_filename(message(19), path, sizeof(path))) {
        return;
    }
    result = uf_read_workflow_dump_range(&state->runtime.flash,
        state->captured,
        state->image_size - UINT32_C(8192),
        UINT32_C(8192),
        path,
        state->transfer_buffer,
        UF_READ_WORKFLOW_BUFFER_SIZE);
    gui_show_operation_result(state, result, 143);
}

static void gui_save_cmos(gui_state_t *state) {
    char path[64];

    if (!gui_prompt_filename("CMOS data file name: ", path, sizeof(path))) {
        return;
    }
    gui_show_operation_result(state,
        uf_cmos_save_file(&state->runtime.hardware, state->cmos_last_index, path) ? UF_READ_RESULT_OK
                                                                                  : UF_READ_RESULT_FILE_IO,
        145);
}

static bool gui_capture(gui_state_t *state) {
    state->captured = NULL;
    if (state->xms_ready && state->xms.size_bytes >= state->image_size &&
        uf_image_store_init(&state->image_store,
            &state->runtime.hardware,
            state->xms.linear_base,
            state->xms.size_bytes) &&
        uf_image_store_capture(&state->image_store, &state->runtime.flash, state->image_size)) {
        state->captured = &state->image_store;
    }
    return true;
}

static void gui_redetect(gui_state_t *state) {
    gui_color(GUI_YELLOW, GUI_BLACK);
    gui_clear_line(20);
    gui_center(20, "Detecting Flash ROM...");
    if (!uf_flash_service_detect(&state->runtime.flash)) {
        gui_set_status(state, message(60));
        gui_color(GUI_LIGHT_RED, GUI_BLACK);
        gui_clear_line(20);
        gui_center(20, message(60));
        (void)getch();
        return;
    }
    state->image_size = state->runtime.flash.chip->capacity_bytes;
    (void)gui_capture(state);
    gui_set_status(state, message(48));
    gui_clear_line(20);
    gui_draw_information(state);
}

static void gui_unavailable(gui_state_t *state) {
    gui_color(GUI_LIGHT_RED, GUI_BLACK);
    gui_clear_line(20);
    gui_center(20, message(142));
    gui_set_status(state, message(142));
    (void)getch();
    gui_clear_line(20);
}

static void gui_quit(gui_state_t *state) { state->done = true; }

static void gui_draw_item(const gui_menu_item_t *item, bool selected) {
    const char *label = message(item->label_id);
    size_t length = strlen(label) + 2;
    uint8_t column = length < 78 ? (uint8_t)((80U - length) / 2U) : 1;

    gui_color(item->enabled ? GUI_WHITE : GUI_LIGHT_GRAY, selected ? GUI_RED : GUI_BLACK);
    gui_move(column, item->row);
    gui_put_char(' ');
    gui_puts(label);
    gui_put_char(' ');
}

static void gui_clear_menu_area(void) {
    for (uint8_t row = 10; row <= 21; ++row) {
        gui_clear_line(row);
    }
}

static void gui_run_menu_items(gui_state_t *state, gui_menu_item_t *items, uint8_t count, bool main_menu) {
    uint8_t selected = 0;
    bool finished = false;
    while (!state->done && !finished) {
        for (uint8_t index = 0; index < count; ++index) {
            gui_draw_item(&items[index], index == selected);
        }
        gui_color(items[selected].enabled ? GUI_LIGHT_GREEN : GUI_GREEN, GUI_BLACK);
        gui_clear_line(25);
        gui_write_at(1, 25, message(items[selected].help_id));
        switch (getch()) {
        case 13:
            if (items[selected].action == NULL) {
                finished = true;
            } else if (items[selected].enabled) {
                items[selected].action(state);
            } else {
                gui_unavailable(state);
            }
            break;
        case 27:
            if (main_menu) {
                state->done = true;
            } else {
                finished = true;
            }
            break;
        case 0:
            switch (getch()) {
            case 72:
                selected = uf_menu_move_selection(selected, count, UF_MENU_MOVE_UP);
                break;
            case 80:
                selected = uf_menu_move_selection(selected, count, UF_MENU_MOVE_DOWN);
                break;
            case 71:
                selected = uf_menu_move_selection(selected, count, UF_MENU_MOVE_HOME);
                break;
            case 79:
                selected = uf_menu_move_selection(selected, count, UF_MENU_MOVE_END);
                break;
            default:
                break;
            }
            break;
        default:
            break;
        }
    }
}

static void gui_cmos_menu(gui_state_t *state) {
    gui_menu_item_t items[] = {{80, 118, 10, true, gui_save_cmos},
        {81, 119, 11, false, gui_unavailable},
        {88, 120, 12, false, gui_unavailable},
        {89, 121, 13, false, gui_unavailable},
        {79, 130, 15, true, NULL}};

    gui_clear_menu_area();
    gui_run_menu_items(state, items, (uint8_t)(sizeof(items) / sizeof(items[0])), false);
    gui_clear_menu_area();
}

static void gui_advanced_menu(gui_state_t *state) {
    gui_menu_item_t items[] = {{82, 115, 10, false, gui_unavailable},
        {83, 116, 11, true, gui_save_bootblock},
        {84, 117, 12, false, gui_unavailable},
        {140, 141, 13, true, gui_compare},
        {79, 130, 15, true, NULL}};

    gui_clear_menu_area();
    gui_run_menu_items(state, items, (uint8_t)(sizeof(items) / sizeof(items[0])), false);
    gui_clear_menu_area();
}

static void gui_run_menu(gui_state_t *state) {
    gui_menu_item_t items[] = {{85, 122, 10, true, gui_dump},
        {86, 123, 11, false, gui_unavailable},
        {87, 124, 12, false, gui_unavailable},
        {100, 125, 13, true, gui_redetect},
        {101, 126, 14, true, gui_cmos_menu},
        {91, 128, 15, true, gui_advanced_menu},
        {93, 129, 17, true, gui_quit}};

    gui_run_menu_items(state, items, (uint8_t)(sizeof(items) / sizeof(items[0])), true);
}

int uf_gui_run(uf_phys_addr_t rom_base, bool monochrome) {
    gui_state_t state;
    int result = 1;

    memset(&state, 0, sizeof(state));
    gui_monochrome = monochrome;
    state.xms_ready = uf_xms_init(&state.xms);
    if (!uf_runtime_init(&state.runtime, rom_base)) {
        fputs("PCI chipset initialization failed.\r\n", stderr);
        goto cleanup;
    }
    state.runtime_ready = true;
    if (!uf_runtime_set_rom_enabled(&state.runtime, true)) {
        fputs("Could not enable access to the system ROM.\r\n", stderr);
        goto cleanup;
    }
    state.rom_enabled = true;
    if (!uf_flash_service_detect(&state.runtime.flash)) {
        fputs("Flash ROM chip was not identified.\r\n", stderr);
        goto cleanup;
    }
    state.image_size = state.runtime.flash.chip->capacity_bytes;
    if (!uf_cmos_detect_last_index(&state.runtime.hardware, &state.cmos_last_index)) {
        state.cmos_last_index = UINT8_C(0x7F);
    }
    state.transfer_buffer = malloc(UF_READ_WORKFLOW_BUFFER_SIZE);
    if (state.transfer_buffer == NULL) {
        fputs("Could not allocate the file-transfer buffer.\r\n", stderr);
        goto cleanup;
    }
    (void)gui_capture(&state);
    gui_draw_header();
    gui_draw_information(&state);
    gui_run_menu(&state);
    result = 0;

cleanup:
    gui_cursor(true);
    gui_color(GUI_LIGHT_GRAY, GUI_BLACK);
    gui_clear_screen();
    free(state.transfer_buffer);
    if (state.rom_enabled && !uf_runtime_set_rom_enabled(&state.runtime, false)) {
        result = 1;
    }
    if (state.runtime_ready && !uf_runtime_shutdown(&state.runtime)) {
        result = 1;
    }
    if (state.xms_ready && !uf_xms_shutdown(&state.xms)) {
        result = 1;
    }
    return result;
}

#else

int uf_gui_run(uf_phys_addr_t rom_base, bool monochrome) {
    (void)rom_base;
    (void)monochrome;
    return 1;
}

#endif
