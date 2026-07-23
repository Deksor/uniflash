#ifndef UNIFLASH_ROM_DATABASE_H
#define UNIFLASH_ROM_DATABASE_H

#include "uniflash/flash_chip.h"

extern const uf_flash_manufacturer_t uf_rom_manufacturers[];
extern const uint16_t uf_rom_manufacturer_count;

const uf_flash_manufacturer_t *uf_rom_find_manufacturer(
    uint8_t manufacturer_id);
const uf_flash_chip_t *uf_rom_find_chip(
    const uf_flash_manufacturer_t *manufacturer,
    uint8_t device_id);
bool uf_rom_database_validate(void);

#endif
