#ifndef UNIFLASH_MANUFACTURER_COMMON_H
#define UNIFLASH_MANUFACTURER_COMMON_H

#include "uniflash/generic_algorithms.h"

typedef uf_bool_t (*uf_flash_inner_program_fn)(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
);
typedef uf_bool_t (*uf_flash_inner_erase_fn)(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
);

uf_phys_addr_t uf_flash_fwh_64k_lock_address(
    const struct uf_flash_service *service,
    uf_rom_offset_t operation_address
);
uf_phys_addr_t uf_flash_fwh_32k_lock_address(
    const struct uf_flash_service *service,
    uf_rom_offset_t operation_address
);
uf_bool_t uf_flash_update_phys_byte(
    struct uf_flash_service *service,
    uf_phys_addr_t address,
    uint8_t and_mask,
    uint8_t or_mask
);
uf_bool_t uf_flash_run_protected_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    const uf_phys_addr_t *lock_addresses,
    uint8_t lock_count,
    uint8_t unlock_mask,
    uf_flash_inner_program_fn operation
);
uf_bool_t uf_flash_run_protected_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address,
    const uf_phys_addr_t *lock_addresses,
    uint8_t lock_count,
    uint8_t unlock_mask,
    uf_flash_inner_erase_fn operation
);

#endif
