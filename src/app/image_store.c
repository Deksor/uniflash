#include <string.h>

#include "uniflash/image_store.h"

bool uf_image_store_init(
    uf_image_store_t *store,
    const uf_hardware_t *hardware,
    uf_phys_addr_t linear_base,
    uf_rom_size_t capacity_bytes)
{
    if (
        store == NULL || !uf_hardware_is_valid(hardware) || linear_base == 0 || capacity_bytes == 0 || linear_base > UINT32_MAX - capacity_bytes)
    {
        return false;
    }
    memset(store, 0, sizeof(*store));
    store->hardware = hardware;
    store->linear_base = linear_base;
    store->capacity_bytes = capacity_bytes;
    return true;
}

bool uf_image_store_capture(
    uf_image_store_t *store,
    uf_flash_service_t *flash,
    uf_rom_size_t image_size_bytes)
{

    if (
        store == NULL || flash == NULL || store->hardware == NULL || image_size_bytes == 0 || image_size_bytes > store->capacity_bytes)
    {
        return false;
    }
    store->image_size_bytes = 0;
    for (uf_rom_offset_t offset = 0; offset < image_size_bytes; ++offset)
    {
        uint8_t value;
        if (
            !uf_flash_service_read_byte(flash, offset, &value) || !store->hardware->phys_write8(
                                                                      store->hardware->context,
                                                                      store->linear_base + offset,
                                                                      value))
        {
            return false;
        }
    }
    store->image_size_bytes = image_size_bytes;
    return true;
}

bool uf_image_store_read(
    const uf_image_store_t *store,
    uf_rom_offset_t offset,
    void *destination,
    uf_rom_size_t size_bytes)
{
    if (
        store == NULL || store->hardware == NULL || (destination == NULL && size_bytes != 0) || offset > store->image_size_bytes || size_bytes > store->image_size_bytes - offset)
    {
        return false;
    }
    return uf_hw_phys_read_block(
        store->hardware,
        store->linear_base + offset,
        destination,
        size_bytes);
}
