#ifndef UNIFLASH_WINBOND_ALGORITHMS_H
#define UNIFLASH_WINBOND_ALGORITHMS_H

#include "uniflash/manufacturer_common.h"

bool uf_flash_erase_winbond_sector(struct uf_flash_service *service, uf_rom_offset_t sector_address);
bool uf_flash_register_winbond_algorithms(uf_flash_algorithm_registry_t *registry);

#endif
