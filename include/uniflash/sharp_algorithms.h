#ifndef UNIFLASH_SHARP_ALGORITHMS_H
#define UNIFLASH_SHARP_ALGORITHMS_H

#include "uniflash/generic_algorithms.h"

bool uf_flash_program_sharp_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_erase_sharp_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address);
bool uf_flash_register_sharp_algorithms(
    uf_flash_algorithm_registry_t *registry);

#endif
