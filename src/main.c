#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "uniflash/cmos.h"
#include "uniflash/gui.h"
#include "uniflash/image_store.h"
#include "uniflash/read_workflow.h"
#include "uniflash/rom_database.h"
#include "uniflash/runtime.h"
#include "uniflash/types.h"
#include "uniflash/version.h"
#include "uniflash/xms.h"

typedef enum uf_cli_action
{
    UF_CLI_GUI = 0,
    UF_CLI_HELP,
    UF_CLI_INFO,
    UF_CLI_DUMP,
    UF_CLI_BOOTBLOCK,
    UF_CLI_COMPARE,
    UF_CLI_CHIPLIST,
    UF_CLI_CMOS_SAVE,
    UF_CLI_LANGUAGES
} uf_cli_action_t;

typedef enum uf_cli_target
{
    UF_CLI_TARGET_SYSTEM = 0,
    UF_CLI_TARGET_CT,
    UF_CLI_TARGET_PCI
} uf_cli_target_t;

typedef struct uf_cli_options
{
    uf_cli_action_t action;
    const char *path;
    uf_phys_addr_t rom_base;
    uf_cli_target_t target;
    uf_io_port_t ct_port;
    uf_pci_address_t pci_address;
    bool pci_address_set;
    bool quit_after_action;
    bool monochrome;
    bool force_id;
    uint16_t forced_id;
} uf_cli_options_t;

static int ascii_upper(int value)
{
    if (value >= 'a' && value <= 'z')
    {
        return value - ('a' - 'A');
    }
    return value;
}

static bool option_is(const char *argument, const char *name)
{
    if (
        argument == NULL || (*argument != '-' && *argument != '/'))
    {
        return false;
    }
    ++argument;
    while (*argument != '\0' && *name != '\0')
    {
        if (ascii_upper(*argument) != ascii_upper(*name))
        {
            return false;
        }
        ++argument;
        ++name;
    }
    return *argument == '\0' && *name == '\0';
}

static void print_help(void)
{
    puts(UF_PRODUCT_NAME " " UF_VERSION_STRING " C port - commands");
    puts("");
    puts("  UNIFLASH");
    puts("  UNIFLASH -GUI [-BASE hex-address]");
    puts("  UNIFLASH -INFO [-BASE hex-address]");
    puts("  UNIFLASH -DUMP filename [-BASE hex-address]");
    puts("  UNIFLASH -SAVE filename [-QUIT] [-BASE hex-address]");
    puts("  UNIFLASH -COMPARE filename [-BASE hex-address]");
    puts("  UNIFLASH -BOOTBLOCK filename [-BASE hex-address]");
    puts("  UNIFLASH -CMOSS filename");
    puts("  UNIFLASH -CHIPLIST");
    puts("  UNIFLASH /0                 List available languages");
    puts("  UNIFLASH /1 [-MONO]         English GUI");
    puts("  UNIFLASH -INFO -FORCE xxxx  Force a chip ID (read-only)");
    puts("  UNIFLASH -INFO|-DUMP file -CTFLASH [hex-port]");
    puts("  UNIFLASH -INFO|-DUMP file -PCIROM [bus device function]");
    puts("");
    puts("This build does not expose erase or programming commands.");
}

static bool argument_is_option(const char *argument)
{
    return (
        argument != NULL && (argument[0] == '-' || argument[0] == '/'));
}

static bool parse_decimal_byte(const char *text, uint8_t *value)
{
    if (text == NULL || text[0] == '\0' || value == NULL)
    {
        return false;
    }
    char *end;
    unsigned long parsed = strtoul(text, &end, 10);
    if (*end != '\0' || parsed > UINT8_MAX)
    {
        return false;
    }
    *value = (uint8_t)parsed;
    return true;
}

static bool parse_hex_address(
    const char *text,
    uf_phys_addr_t *address)
{
    if (text == NULL || text[0] == '\0' || address == NULL)
    {
        return false;
    }
    char *end;
    unsigned long value = strtoul(text, &end, 16);
    if (*end != '\0')
    {
        return false;
    }
    *address = (uf_phys_addr_t)value;
    return (unsigned long)*address == value;
}

static bool parse_options(
    int argc,
    char **argv,
    uf_cli_options_t *options)
{
    int index;
    bool action_seen = false;

    memset(options, 0, sizeof(*options));
    options->action = UF_CLI_GUI;
    /* Zero preserves the Pascal behavior: probe ROM sizes at the top of
       the 32-bit address space unless -BASE explicitly forces an address. */
    options->rom_base = UINT32_C(0);
    for (index = 1; index < argc; ++index)
    {
        if (option_is(argv[index], "H") || option_is(argv[index], "?"))
        {
            if (action_seen)
            {
                return false;
            }
            options->action = UF_CLI_HELP;
            action_seen = true;
        }
        else if (option_is(argv[index], "0"))
        {
            if (action_seen)
            {
                return false;
            }
            options->action = UF_CLI_LANGUAGES;
            action_seen = true;
        }
        else if (option_is(argv[index], "1"))
        {
            /* English is currently the only compiled language. */
        }
        else if (option_is(argv[index], "MONO"))
        {
            options->monochrome = true;
        }
        else if (option_is(argv[index], "GUI"))
        {
            if (action_seen)
            {
                return false;
            }
            options->action = UF_CLI_GUI;
            action_seen = true;
        }
        else if (option_is(argv[index], "INFO"))
        {
            if (action_seen)
            {
                return false;
            }
            options->action = UF_CLI_INFO;
            action_seen = true;
        }
        else if (
            option_is(argv[index], "DUMP") || option_is(argv[index], "SAVE") || option_is(argv[index], "BOOTBLOCK") || option_is(argv[index], "COMPARE"))
        {
            if (action_seen || index + 1 >= argc)
            {
                return false;
            }
            if (option_is(argv[index], "COMPARE"))
            {
                options->action = UF_CLI_COMPARE;
            }
            else if (option_is(argv[index], "BOOTBLOCK"))
            {
                options->action = UF_CLI_BOOTBLOCK;
            }
            else
            {
                options->action = UF_CLI_DUMP;
            }
            options->path = argv[++index];
            action_seen = true;
        }
        else if (option_is(argv[index], "CMOSS"))
        {
            if (action_seen || index + 1 >= argc)
            {
                return false;
            }
            options->action = UF_CLI_CMOS_SAVE;
            options->path = argv[++index];
            action_seen = true;
        }
        else if (option_is(argv[index], "CHIPLIST"))
        {
            if (action_seen)
            {
                return false;
            }
            options->action = UF_CLI_CHIPLIST;
            action_seen = true;
        }
        else if (option_is(argv[index], "QUIT"))
        {
            options->quit_after_action = true;
        }
        else if (option_is(argv[index], "FORCE"))
        {
            uf_phys_addr_t forced;
            if (
                options->force_id || index + 1 >= argc || strlen(argv[index + 1]) != 4 || !parse_hex_address(argv[++index], &forced) || forced > UINT16_MAX)
            {
                return false;
            }
            options->forced_id = (uint16_t)forced;
            options->force_id = true;
        }
        else if (option_is(argv[index], "CTFLASH"))
        {
            uf_phys_addr_t port;
            if (options->target != UF_CLI_TARGET_SYSTEM)
            {
                return false;
            }
            options->target = UF_CLI_TARGET_CT;
            if (
                index + 1 < argc && !argument_is_option(argv[index + 1]))
            {
                if (
                    !parse_hex_address(argv[++index], &port) || port > UINT16_MAX)
                {
                    return false;
                }
                options->ct_port = (uf_io_port_t)port;
                options->ct_port &= UINT16_C(0xFFFC);
                if (
                    options->ct_port < UINT16_C(0x200) || options->ct_port > UINT16_C(0x3FC))
                {
                    options->ct_port = 0;
                }
            }
        }
        else if (option_is(argv[index], "PCIROM"))
        {
            uint8_t bus;
            uint8_t device;
            uint8_t function;
            if (options->target != UF_CLI_TARGET_SYSTEM)
            {
                return false;
            }
            options->target = UF_CLI_TARGET_PCI;
            if (
                index + 1 < argc && !argument_is_option(argv[index + 1]))
            {
                if (
                    index + 3 >= argc || !parse_decimal_byte(argv[index + 1], &bus) || !parse_decimal_byte(argv[index + 2], &device) || !parse_decimal_byte(argv[index + 3], &function) || device > 31 || function > 7)
                {
                    return false;
                }
                options->pci_address.bus = bus;
                options->pci_address.device = device;
                options->pci_address.function = function;
                options->pci_address_set = true;
                index += 3;
            }
        }
        else if (option_is(argv[index], "BASE"))
        {
            if (
                index + 1 >= argc || !parse_hex_address(argv[++index], &options->rom_base))
            {
                return false;
            }
        }
        else
        {
            return false;
        }
    }
    if (
        options->target != UF_CLI_TARGET_SYSTEM && (options->action == UF_CLI_GUI || options->action == UF_CLI_CMOS_SAVE || options->action == UF_CLI_CHIPLIST || options->action == UF_CLI_LANGUAGES))
    {
        return false;
    }
    if (options->quit_after_action && !action_seen)
    {
        options->action = UF_CLI_INFO;
    }
    if (options->force_id && options->action == UF_CLI_GUI)
    {
        return false;
    }
    return true;
}

static void print_chip_list(void)
{
    puts("  List of supported flash chips");
    puts("  -----------------------------");
    for (uint16_t manufacturer_index = 0;
         manufacturer_index < uf_rom_manufacturer_count;
         ++manufacturer_index)
    {
        const uf_flash_manufacturer_t *manufacturer =
            &uf_rom_manufacturers[manufacturer_index];
        for (uint16_t chip_index = 0;
             chip_index < manufacturer->chip_count;
             ++chip_index)
        {
            const uf_flash_chip_t *chip =
                &manufacturer->chips[chip_index];
            printf(
                "  %02X%02X - %s %s\r\n",
                (unsigned int)manufacturer->manufacturer_id,
                (unsigned int)chip->device_id,
                manufacturer->name,
                chip->name);
        }
    }
}

static void print_languages(void)
{
    puts("Languages supported in this version:");
    puts("  1. English");
}

#if defined(UF_TARGET_DOS16)

static bool select_flash_target(
    uf_runtime_t *runtime,
    const uf_cli_options_t *options)
{
    uf_pci_rom_list_t list;

    if (options->target == UF_CLI_TARGET_SYSTEM)
    {
        return uf_runtime_set_rom_enabled(runtime, true);
    }
    if (options->target == UF_CLI_TARGET_CT)
    {
        return uf_runtime_use_ct_flasher(
            runtime, options->ct_port, false);
    }
    if (!uf_runtime_scan_pci_roms(runtime, &list))
    {
        return false;
    }
    if (!options->pci_address_set)
    {
        char selection[8];
        char *end;

        puts("PCI devices with expansion ROMs:");
        if (list.count == 0)
        {
            return false;
        }
        puts("    B D F   VEN  DEV  NAME");
        for (uint8_t index = 0; index < list.count; ++index)
        {
            const uf_pci_rom_device_t *device = &list.devices[index];
            printf(
                "%02X  %u %u %u - %04X:%04X %s (%luK max)\r\n",
                (unsigned int)index + 1,
                (unsigned int)device->pci_device.address.bus,
                (unsigned int)device->pci_device.address.device,
                (unsigned int)device->pci_device.address.function,
                (unsigned int)device->pci_device.vendor_id,
                (unsigned int)device->pci_device.device_id,
                uf_pci_rom_device_name(device),
                (unsigned long)(device->maximum_size >> 10));
        }
        printf("Select device (1-%u, 0 to cancel): ",
               (unsigned int)list.count);
        if (fgets(selection, sizeof(selection), stdin) == NULL)
        {
            return false;
        }
        unsigned long selected = strtoul(selection, &end, 10);
        if (
            selected == 0 || selected > list.count || (*end != '\0' && *end != '\r' && *end != '\n'))
        {
            return false;
        }
        return (
            uf_runtime_use_pci_rom(
                runtime, &list.devices[selected - 1]) &&
            uf_runtime_set_rom_enabled(runtime, true));
    }
    for (uint8_t index = 0; index < list.count; ++index)
    {
        const uf_pci_address_t *address =
            &list.devices[index].pci_device.address;
        if (
            address->bus == options->pci_address.bus && address->device == options->pci_address.device && address->function == options->pci_address.function)
        {
            return (
                uf_runtime_use_pci_rom(runtime, &list.devices[index]) && uf_runtime_set_rom_enabled(runtime, true));
        }
    }
    return false;
}

static bool select_forced_chip(
    uf_runtime_t *runtime,
    const uf_cli_options_t *options)
{
    uint8_t manufacturer_id =
        (uint8_t)(options->forced_id >> 8);
    uint8_t device_id = (uint8_t)options->forced_id;

    if (!uf_flash_service_select_chip(
            &runtime->flash, manufacturer_id, device_id))
    {
        return false;
    }
    if (options->target == UF_CLI_TARGET_SYSTEM)
    {
        uf_phys_addr_t base = options->rom_base != 0
                                  ? options->rom_base
                                  : runtime->flash.rom_base;
        if (base == 0)
        {
            base = UINT32_C(0) - runtime->flash.chip->capacity_bytes;
        }
        runtime->flash.rom_base = base;
        return runtime->flash.access.select_window(
            runtime->flash.access.context, base);
    }
    return true;
}

static int run_read_only(const uf_cli_options_t *options)
{
    uf_runtime_t runtime;
    uf_xms_t xms;
    uf_image_store_t store;
    const uf_image_store_t *captured = NULL;
    uint8_t *buffer = NULL;
    uf_rom_size_t image_size;
    uf_read_result_t result = UF_READ_RESULT_OK;
    bool runtime_ready = false;
    bool rom_enabled = false;
    bool xms_ready;
    int exit_code = 1;

    if (options->action == UF_CLI_CMOS_SAVE)
    {
        uf_hardware_t cmos_hardware;
        uint8_t last_index;
        if (
            !uf_dos_hardware_init_io(&cmos_hardware) || !uf_cmos_detect_last_index(&cmos_hardware, &last_index) || !uf_cmos_save_file(&cmos_hardware, last_index, options->path))
        {
            fputs("Could not save CMOS data.\r\n", stderr);
            return 1;
        }
        printf("CMOS data saved to %s\r\n", options->path);
        return 0;
    }
    xms_ready = uf_xms_init(&xms);
    if (!uf_runtime_init(&runtime, options->rom_base))
    {
        fputs("PCI chipset initialization failed.\r\n", stderr);
        goto cleanup;
    }
    runtime_ready = true;
    if (!select_flash_target(&runtime, options))
    {
        fputs("Could not select the requested ROM target.\r\n", stderr);
        goto cleanup;
    }
    rom_enabled = runtime.rom_enabled;
    if (
        options->force_id
            ? !select_forced_chip(&runtime, options)
            : !(
                  options->target == UF_CLI_TARGET_SYSTEM
                      ? uf_flash_service_detect(&runtime.flash)
                      : uf_flash_service_detect_current_window(
                            &runtime.flash)))
    {
        fputs("Flash ROM chip was not identified.\r\n", stderr);
        goto cleanup;
    }
    if (
        options->target == UF_CLI_TARGET_CT && runtime.flash.chip->capacity_bytes >= UF_KIB(512))
    {
        runtime.ct_flasher.size_512k = true;
    }
    if (
        (
            options->target == UF_CLI_TARGET_CT && runtime.flash.chip->capacity_bytes > UF_KIB(512)) ||
        (options->target == UF_CLI_TARGET_PCI && runtime.flash.chip->capacity_bytes > runtime.pci_rom.device.maximum_size))
    {
        fputs("Detected ROM is larger than the selected target.\r\n", stderr);
        goto cleanup;
    }

    image_size = runtime.flash.chip->capacity_bytes;
    printf(
        "Chip: %s %s\r\nSize: %lu bytes\r\n",
        runtime.flash.manufacturer->name,
        runtime.flash.chip->name,
        (unsigned long)image_size);
    if (options->action == UF_CLI_INFO)
    {
        exit_code = 0;
        goto cleanup;
    }

    buffer = malloc(UF_READ_WORKFLOW_BUFFER_SIZE);
    if (buffer == NULL)
    {
        fputs("Could not allocate the file-transfer buffer.\r\n", stderr);
        goto cleanup;
    }

    if (
        xms_ready && xms.size_bytes >= image_size && uf_image_store_init(&store, &runtime.hardware, xms.linear_base, xms.size_bytes))
    {
        fputs("Capturing ROM image in XMS...\r\n", stdout);
        if (!uf_image_store_capture(&store, &runtime.flash, image_size))
        {
            fputs("Could not capture the ROM image in XMS.\r\n", stderr);
            goto cleanup;
        }
        captured = &store;
    }
    else
    {
        fputs(
            "XMS image buffer unavailable; using chunked ROM access.\r\n",
            stdout);
    }

    if (options->action == UF_CLI_DUMP)
    {
        result = uf_read_workflow_dump(
            &runtime.flash,
            captured,
            image_size,
            options->path,
            buffer,
            UF_READ_WORKFLOW_BUFFER_SIZE);
    }
    else if (options->action == UF_CLI_BOOTBLOCK)
    {
        result = image_size < UINT32_C(8192)
                     ? UF_READ_RESULT_INVALID_ARGUMENT
                     : uf_read_workflow_dump_range(
                           &runtime.flash,
                           captured,
                           image_size - UINT32_C(8192),
                           UINT32_C(8192),
                           options->path,
                           buffer,
                           UF_READ_WORKFLOW_BUFFER_SIZE);
    }
    else
    {
        result = uf_read_workflow_compare(
            &runtime.flash,
            captured,
            image_size,
            options->path,
            buffer,
            UF_READ_WORKFLOW_BUFFER_SIZE);
    }
    if (result != UF_READ_RESULT_OK)
    {
        fprintf(stderr, "%s: %s\r\n", options->path,
                uf_read_result_message(result));
        goto cleanup;
    }
    printf(
        (
            options->action == UF_CLI_DUMP || options->action == UF_CLI_BOOTBLOCK)
            ? "ROM image saved to %s\r\n"
            : "ROM and %s are identical.\r\n",
        options->path);
    exit_code = 0;

cleanup:
    free(buffer);
    if (rom_enabled && !uf_runtime_set_rom_enabled(
                           &runtime, false))
    {
        fputs("Warning: ROM access state could not be restored.\r\n", stderr);
        exit_code = 1;
    }
    if (runtime_ready && !uf_runtime_shutdown(&runtime))
    {
        fputs("Warning: chipset shutdown failed.\r\n", stderr);
        exit_code = 1;
    }
    if (xms_ready && !uf_xms_shutdown(&xms))
    {
        fputs("Warning: XMS shutdown failed.\r\n", stderr);
        exit_code = 1;
    }
    return exit_code;
}

#endif

int main(int argc, char **argv)
{
    uf_cli_options_t options;

    printf(
        UF_PRODUCT_NAME " " UF_VERSION_STRING
                        " C port (%u manufacturers)\r\n",
        (unsigned int)uf_rom_manufacturer_count);
    if (!parse_options(argc, argv, &options))
    {
        fputs("Invalid command line.\r\n\r\n", stderr);
        print_help();
        return 2;
    }
    if (options.action == UF_CLI_HELP)
    {
        print_help();
        return 0;
    }
    if (options.action == UF_CLI_CHIPLIST)
    {
        print_chip_list();
        return 0;
    }
    if (options.action == UF_CLI_LANGUAGES)
    {
        print_languages();
        return 0;
    }
#if defined(UF_TARGET_DOS16)
    if (options.action == UF_CLI_GUI)
    {
        return uf_gui_run(options.rom_base, options.monochrome);
    }
    return run_read_only(&options);
#else
    fputs("Hardware commands require the DOS/16 build.\n", stderr);
    return 1;
#endif
}
