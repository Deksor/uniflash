#ifndef UNIFLASH_GENERIC_ALGORITHMS_H
#define UNIFLASH_GENERIC_ALGORITHMS_H

#include "uniflash/flash_service.h"

bool uf_flash_program_generic_page(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_program_intel_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_erase_intel_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address);
bool uf_flash_erase_intel_sector_u(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address);
bool uf_flash_program_amd_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_erase_amd_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address);
bool uf_flash_erase_amd_bulk(
    struct uf_flash_service *service,
    uf_rom_offset_t status_address);
bool uf_flash_erase_amd_embedded(
    struct uf_flash_service *service,
    uf_rom_offset_t ignored_address);
bool uf_flash_program_amd_embedded(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_program_amd_flash(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address);
bool uf_flash_erase_amd_flash(
    struct uf_flash_service *service,
    uf_rom_offset_t ignored_address);
bool uf_flash_register_amd_sector_erase(
    uf_flash_algorithm_registry_t *registry);
bool uf_flash_register_amd_bulk_erase(
    uf_flash_algorithm_registry_t *registry);
bool uf_flash_register_amd_embedded_erase(
    uf_flash_algorithm_registry_t *registry);
bool uf_flash_register_generic_algorithms(
    uf_flash_algorithm_registry_t *registry);

#endif
