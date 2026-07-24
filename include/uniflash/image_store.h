#ifndef UNIFLASH_IMAGE_STORE_H
#define UNIFLASH_IMAGE_STORE_H

#include "uniflash/flash_service.h"
#include "uniflash/hardware.h"

typedef struct uf_image_store {
    const uf_hardware_t *hardware;
    uf_phys_addr_t linear_base;
    uf_rom_size_t capacity_bytes;
    uf_rom_size_t image_size_bytes;
} uf_image_store_t;

bool uf_image_store_init(uf_image_store_t *store,
    const uf_hardware_t *hardware,
    uf_phys_addr_t linear_base,
    uf_rom_size_t capacity_bytes);
bool uf_image_store_capture(uf_image_store_t *store, uf_flash_service_t *flash, uf_rom_size_t image_size_bytes);
bool uf_image_store_read(const uf_image_store_t *store,
    uf_rom_offset_t offset,
    void *destination,
    uf_rom_size_t size_bytes);

#endif
