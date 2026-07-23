#include <string.h>

#include "uniflash/flash_backend.h"

static bool map_address(
    uf_system_flash_backend_t *backend,
    uf_rom_offset_t offset,
    bool writing,
    uf_phys_addr_t *physical)
{
    uf_phys_addr_t base = writing
                              ? backend->write_base
                              : backend->rom_base;

    if (backend->bank_size != 0)
    {
        uint32_t bank32 = offset / backend->bank_size;
        uint8_t bank;

        if (bank32 > UINT8_MAX || backend->select_bank == NULL)
        {
            return false;
        }
        bank = (uint8_t)bank32;
        if (
            (!backend->bank_selected || bank != backend->current_bank) && !backend->select_bank(backend->bank_context, bank))
        {
            return false;
        }
        backend->current_bank = bank;
        backend->bank_selected = true;
        offset %= backend->bank_size;
    }
    if (base > UINT32_MAX - offset)
    {
        return false;
    }
    *physical = base + offset;
    return true;
}

static bool shadow(
    uf_system_flash_backend_t *backend,
    bool disable)
{
    if (backend->control_shadow == NULL)
    {
        return true;
    }
    return backend->control_shadow(
        backend->shadow_context,
        disable);
}

static bool read_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t *value)
{
    uf_system_flash_backend_t *backend = context;
    uf_phys_addr_t physical;
    bool result;

    if (
        value == NULL || !map_address(backend, address, false, &physical) || !shadow(backend, true))
    {
        return false;
    }
    result = backend->hardware->phys_read8(
        backend->hardware->context,
        physical,
        value);
    if (!shadow(backend, false))
    {
        return false;
    }
    return result;
}

static bool write_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t value)
{
    uf_system_flash_backend_t *backend = context;
    uf_phys_addr_t physical;

    if (!map_address(backend, address, true, &physical))
    {
        return false;
    }
    return backend->hardware->phys_write8(
        backend->hardware->context,
        physical,
        value);
}

static bool read_block(
    void *context,
    uf_rom_offset_t flash_address,
    void *destination,
    uf_rom_size_t size_bytes)
{
    uf_system_flash_backend_t *backend = context;
    uint8_t *bytes = destination;
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        if (!read_byte(backend, flash_address + offset, &bytes[offset]))
        {
            return false;
        }
    }
    return true;
}

static bool write_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes)
{
    uf_system_flash_backend_t *backend = context;
    const uint8_t *bytes = source;
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        if (!write_byte(backend, flash_address + offset, bytes[offset]))
        {
            return false;
        }
    }
    return true;
}

static bool compare_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    bool *equal)
{
    uf_system_flash_backend_t *backend = context;
    const uint8_t *bytes = source;
    if (equal == NULL)
    {
        return false;
    }
    *equal = false;
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        uint8_t value;

        if (!read_byte(backend, flash_address + offset, &value))
        {
            return false;
        }
        if (value != bytes[offset])
        {
            return true;
        }
    }
    *equal = true;
    return true;
}

static bool delay_us(void *context, uint32_t microseconds)
{
    uf_system_flash_backend_t *backend = context;

    return backend->hardware->delay_us(
        backend->hardware->context,
        microseconds);
}

static bool select_window(void *context, uf_phys_addr_t rom_base)
{
    uf_system_flash_backend_t *backend = context;

    backend->rom_base = rom_base;
    if (backend->bank_size == 0)
    {
        backend->write_base = rom_base;
    }
    backend->bank_selected = false;
    return true;
}

static bool read_source_byte(
    void *context,
    uf_phys_addr_t source_address,
    uint8_t *value)
{
    uf_system_flash_backend_t *backend = context;

    return backend->hardware->phys_read8(
        backend->hardware->context,
        source_address,
        value);
}

static bool update_phys_byte(
    void *context,
    uf_phys_addr_t address,
    uint8_t and_mask,
    uint8_t or_mask)
{
    uf_system_flash_backend_t *backend = context;
    uint8_t value;

    if (
        !backend->hardware->phys_read8(
            backend->hardware->context,
            address,
            &value))
    {
        return false;
    }
    value = (value & and_mask) | or_mask;
    return backend->hardware->phys_write8(
        backend->hardware->context,
        address,
        value);
}

static bool set_write_lock(
    void *context,
    uf_phys_addr_t address,
    bool locked)
{
    return update_phys_byte(
        context,
        address,
        locked ? UINT8_C(0xFF) : UINT8_C(0xF8),
        locked ? UINT8_C(0x01) : UINT8_C(0));
}

bool uf_system_flash_backend_init(
    uf_system_flash_backend_t *backend,
    const uf_hardware_t *hardware,
    uf_phys_addr_t rom_base)
{
    if (backend == NULL || !uf_hardware_is_valid(hardware))
    {
        return false;
    }
    memset(backend, 0, sizeof(*backend));
    backend->hardware = hardware;
    backend->rom_base = rom_base;
    backend->write_base = rom_base;
    return true;
}

bool uf_system_flash_backend_set_banking(
    uf_system_flash_backend_t *backend,
    uf_rom_size_t bank_size,
    uf_phys_addr_t write_base,
    uf_flash_bank_select_fn select_bank,
    void *bank_context)
{
    if (
        backend == NULL || bank_size == 0 || select_bank == NULL)
    {
        return false;
    }
    backend->bank_size = bank_size;
    backend->write_base = write_base;
    backend->select_bank = select_bank;
    backend->bank_context = bank_context;
    backend->bank_selected = false;
    return true;
}

bool uf_system_flash_backend_set_shadow_control(
    uf_system_flash_backend_t *backend,
    uf_flash_shadow_control_fn control_shadow,
    void *shadow_context)
{
    if (backend == NULL || control_shadow == NULL)
    {
        return false;
    }
    backend->control_shadow = control_shadow;
    backend->shadow_context = shadow_context;
    return true;
}

bool uf_system_flash_backend_make_access(
    uf_system_flash_backend_t *backend,
    uf_flash_access_t *access)
{
    if (backend == NULL || access == NULL || backend->hardware == NULL)
    {
        return false;
    }
    memset(access, 0, sizeof(*access));
    access->context = backend;
    access->read_byte = read_byte;
    access->write_byte = write_byte;
    access->read_block = read_block;
    access->write_block = write_block;
    access->compare_block = compare_block;
    access->delay_us = delay_us;
    access->select_window = select_window;
    access->read_source_byte = read_source_byte;
    access->set_write_lock = set_write_lock;
    access->update_phys_byte = update_phys_byte;
    return true;
}
