#ifndef UNIFLASH_CLI_H
#define UNIFLASH_CLI_H

#include "uniflash/pci.h"
#include "uniflash/types.h"

typedef enum uf_cli_action {
    UF_CLI_GUI = 0, UF_CLI_HELP, UF_CLI_INFO, UF_CLI_DUMP, UF_CLI_BOOTBLOCK,
    UF_CLI_COMPARE, UF_CLI_CHIPLIST, UF_CLI_CMOS_SAVE, UF_CLI_LANGUAGES
} uf_cli_action_t;

typedef enum uf_cli_target { UF_CLI_TARGET_SYSTEM = 0, UF_CLI_TARGET_CT, UF_CLI_TARGET_PCI } uf_cli_target_t;

typedef struct uf_cli_options {
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

#endif
