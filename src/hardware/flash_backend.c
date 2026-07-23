#include <string.h>

#include "uniflash/flash_backend.h"

static uf_bool_t map_address(
    uf_system_flash_backend_t *backend,
    uf_rom_offset_t offset,
    uf_bool_t writing,
    uf_phys_addr_t *physical
)
{
    uf_phys_addr_t base = writing
        ? backend->write_base
        : backend->rom_base;

    if (backend->bank_size != 0) {
        uint32_t bank32 = offset / backend->bank_size;
        uint8_t bank;

        if (bank32 > UINT8_MAX || backend->select_bank == NULL) {
            return UF_FALSE;
        }
        bank = (uint8_t)bank32;
        if (
            (!backend->bank_selected || bank != backend->current_bank)
            && !backend->select_bank(backend->bank_context, bank)
        ) {
            return UF_FALSE;
        }
        backend->current_bank = bank;
        backend->bank_selected = UF_TRUE;
        offset %= backend->bank_size;
    }
    if (base > UINT32_MAX - offset) {
        return UF_FALSE;
    }
    *physical = base + offset;
    return UF_TRUE;
}

static uf_bool_t shadow(
    uf_system_flash_backend_t *backend,
    uf_bool_t disable
)
{
    if (backend->control_shadow == NULL) {
        return UF_TRUE;
    }
    return backend->control_shadow(
        backend->shadow_context,
        disable
    );
}

static uf_bool_t read_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t *value
)
{
    uf_system_flash_backend_t *backend = context;
    uf_phys_addr_t physical;
    uf_bool_t result;

    if (
        value == NULL
        || !map_address(backend, address, UF_FALSE, &physical)
        || !shadow(backend, UF_TRUE)
    ) {
        return UF_FALSE;
    }
    result = backend->hardware->phys_read8(
        backend->hardware->context,
        physical,
        value
    );
    if (!shadow(backend, UF_FALSE)) {
        return UF_FALSE;
    }
    return result;
}

static uf_bool_t write_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t value
)
{
    uf_system_flash_backend_t *backend = context;
    uf_phys_addr_t physical;

    if (!map_address(backend, address, UF_TRUE, &physical)) {
        return UF_FALSE;
    }
    return backend->hardware->phys_write8(
        backend->hardware->context,
        physical,
        value
    );
}

static uf_bool_t read_block(
    void *context,
    uf_rom_offset_t flash_address,
    void *destination,
    uf_rom_size_t size_bytes
)
{
    uf_system_flash_backend_t *backend = context;
    uint8_t *bytes = destination;
    uf_rom_size_t offset;

    for (offset = 0; offset < size_bytes; ++offset) {
        if (!read_byte(backend, flash_address + offset, &bytes[offset])) {
            return UF_FALSE;
        }
    }
    return UF_TRUE;
}

static uf_bool_t write_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes
)
{
    uf_system_flash_backend_t *backend = context;
    const uint8_t *bytes = source;
    uf_rom_size_t offset;

    for (offset = 0; offset < size_bytes; ++offset) {
        if (!write_byte(backend, flash_address + offset, bytes[offset])) {
            return UF_FALSE;
        }
    }
    return UF_TRUE;
}

static uf_bool_t compare_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    uf_bool_t *equal
)
{
    uf_system_flash_backend_t *backend = context;
    const uint8_t *bytes = source;
    uf_rom_size_t offset;

    if (equal == NULL) {
        return UF_FALSE;
    }
    *equal = UF_FALSE;
    for (offset = 0; offset < size_bytes; ++offset) {
        uint8_t value;

        if (!read_byte(backend, flash_address + offset, &value)) {
            return UF_FALSE;
        }
        if (value != bytes[offset]) {
            return UF_TRUE;
        }
    }
    *equal = UF_TRUE;
    return UF_TRUE;
}

static uf_bool_t delay_us(void *context, uint32_t microseconds)
{
    uf_system_flash_backend_t *backend = context;

    return backend->hardware->delay_us(
        backend->hardware->context,
        microseconds
    );
}

static uf_bool_t select_window(void *context, uf_phys_addr_t rom_base)
{
    uf_system_flash_backend_t *backend = context;

    backend->rom_base = rom_base;
    if (backend->bank_size == 0) {
        backend->write_base = rom_base;
    }
    backend->bank_selected = UF_FALSE;
    return UF_TRUE;
}

static uf_bool_t read_source_byte(
    void *context,
    uf_phys_addr_t source_address,
    uint8_t *value
)
{
    uf_system_flash_backend_t *backend = context;

    return backend->hardware->phys_read8(
        backend->hardware->context,
        source_address,
        value
    );
}

static uf_bool_t update_phys_byte(
    void *context,
    uf_phys_addr_t address,
    uint8_t and_mask,
    uint8_t or_mask
)
{
    uf_system_flash_backend_t *backend = context;
    uint8_t value;

    if (
        !backend->hardware->phys_read8(
            backend->hardware->context,
            address,
            &value
        )
    ) {
        return UF_FALSE;
    }
    value = (value & and_mask) | or_mask;
    return backend->hardware->phys_write8(
        backend->hardware->context,
        address,
        value
    );
}

static uf_bool_t set_write_lock(
    void *context,
    uf_phys_addr_t address,
    uf_bool_t locked
)
{
    return update_phys_byte(
        context,
        address,
        locked ? UINT8_C(0xFF) : UINT8_C(0xF8),
        locked ? UINT8_C(0x01) : UINT8_C(0)
    );
}

uf_bool_t uf_system_flash_backend_init(
    uf_system_flash_backend_t *backend,
    const uf_hardware_t *hardware,
    uf_phys_addr_t rom_base
)
{
    if (backend == NULL || !uf_hardware_is_valid(hardware)) {
        return UF_FALSE;
    }
    memset(backend, 0, sizeof(*backend));
    backend->hardware = hardware;
    backend->rom_base = rom_base;
    backend->write_base = rom_base;
    return UF_TRUE;
}

uf_bool_t uf_system_flash_backend_set_banking(
    uf_system_flash_backend_t *backend,
    uf_rom_size_t bank_size,
    uf_phys_addr_t write_base,
    uf_flash_bank_select_fn select_bank,
    void *bank_context
)
{
    if (
        backend == NULL
        || bank_size == 0
        || select_bank == NULL
    ) {
        return UF_FALSE;
    }
    backend->bank_size = bank_size;
    backend->write_base = write_base;
    backend->select_bank = select_bank;
    backend->bank_context = bank_context;
    backend->bank_selected = UF_FALSE;
    return UF_TRUE;
}

uf_bool_t uf_system_flash_backend_set_shadow_control(
    uf_system_flash_backend_t *backend,
    uf_flash_shadow_control_fn control_shadow,
    void *shadow_context
)
{
    if (backend == NULL || control_shadow == NULL) {
        return UF_FALSE;
    }
    backend->control_shadow = control_shadow;
    backend->shadow_context = shadow_context;
    return UF_TRUE;
}

uf_bool_t uf_system_flash_backend_make_access(
    uf_system_flash_backend_t *backend,
    uf_flash_access_t *access
)
{
    if (backend == NULL || access == NULL || backend->hardware == NULL) {
        return UF_FALSE;
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
    return UF_TRUE;
}
