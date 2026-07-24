#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "uniflash/cli.h"
#include "uniflash/cmos.h"
#include "uniflash/gui.h"
#include "uniflash/image_store.h"
#include "uniflash/read_workflow.h"
#include "uniflash/rom_database.h"
#include "uniflash/runtime.h"
#include "uniflash/types.h"
#include "uniflash/version.h"
#include "uniflash/xms.h"

int main(int argc, char **argv) {
    uf_cli_options_t options;

    printf(UF_PRODUCT_NAME " " UF_VERSION_STRING " C port (%u manufacturers)\r\n",
        (unsigned int)uf_rom_manufacturer_count);
    if (!uf_cli_parse_options(argc, argv, &options)) {
        fputs("Invalid command line.\r\n\r\n", stderr);
        uf_cli_print_help();
        return 2;
    }
    if (options.action == UF_CLI_HELP) {
        uf_cli_print_help();
        return 0;
    }
    if (options.action == UF_CLI_CHIPLIST) {
        uf_cli_print_chip_list();
        return 0;
    }
    if (options.action == UF_CLI_LANGUAGES) {
        uf_cli_print_languages();
        return 0;
    }
#if defined(UF_TARGET_DOS16)
    if (options.action == UF_CLI_GUI) {
        return uf_gui_run(options.rom_base, options.monochrome);
    }
    return uf_cli_run_read_only(&options);
#else
    fputs("Hardware commands require the DOS/16 build.\n", stderr);
    return 1;
#endif
}
