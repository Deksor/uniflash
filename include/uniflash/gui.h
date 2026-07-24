#ifndef UNIFLASH_GUI_H
#define UNIFLASH_GUI_H

#include "uniflash/types.h"
#include "uniflash/image_store.h"
#include "uniflash/language.h"
#include "uniflash/runtime.h"
#include "uniflash/xms.h"

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

int uf_gui_run(uf_phys_addr_t rom_base, bool monochrome);

#endif
