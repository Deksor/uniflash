#ifndef UNIFLASH_INTEL_ALGORITHMS_H
#define UNIFLASH_INTEL_ALGORITHMS_H

#include "uniflash/generic_algorithms.h"

uf_phys_addr_t uf_flash_intel_lock_address(
    const struct uf_flash_service *service,
    uf_rom_offset_t operation_address
);
uf_bool_t uf_flash_program_intel_sector_u(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
);
uf_bool_t uf_flash_erase_intel_sector_protected_u(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
);
uf_bool_t uf_flash_register_intel_algorithms(
    uf_flash_algorithm_registry_t *registry
);

#endif
