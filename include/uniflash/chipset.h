#ifndef UNIFLASH_CHIPSET_H
#define UNIFLASH_CHIPSET_H

#include "uniflash/pci.h"

typedef uint16_t uf_chipset_method_t;

typedef struct uf_chipset {
    uf_pci_interface_t pci;
    uf_pci_function_info_t north;
    uf_pci_function_info_t south;
    uf_bool_t north_found;
    uf_bool_t south_found;
    uf_chipset_method_t north_method;
    uf_chipset_method_t south_method;
    uf_chipset_method_t lpc_method;
    uf_io_port_t lpc_base;
    const char *north_name;
    const char *south_name;
    const char *name;
    char name_storage[96];
    uint32_t north_saved[4];
    uint32_t south_saved[8];
    uint8_t south_saved_valid;
    uint8_t lpc_saved;
    uf_bool_t rom_enabled;
} uf_chipset_t;

uf_bool_t uf_chipset_detect(
    uf_chipset_t *chipset,
    const uf_hardware_t *hardware
);
uf_bool_t uf_chipset_rom_set_enabled(
    uf_chipset_t *chipset,
    uf_bool_t enabled
);

#endif
