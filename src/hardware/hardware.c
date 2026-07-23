#include "uniflash/hardware.h"

uf_bool_t uf_hardware_is_valid(const uf_hardware_t *hardware)
{
    return (
        hardware != NULL
        && hardware->in8 != NULL
        && hardware->in16 != NULL
        && hardware->in32 != NULL
        && hardware->out8 != NULL
        && hardware->out16 != NULL
        && hardware->out32 != NULL
        && hardware->phys_read8 != NULL
        && hardware->phys_write8 != NULL
        && hardware->delay_us != NULL
    ) ? UF_TRUE : UF_FALSE;
}

uf_bool_t uf_hw_phys_read_block(
    const uf_hardware_t *hardware,
    uf_phys_addr_t source,
    void *destination,
    uf_rom_size_t size_bytes
)
{
    uint8_t *bytes = destination;
    uf_rom_size_t offset;

    if (
        !uf_hardware_is_valid(hardware)
        || (destination == NULL && size_bytes != 0)
        || source > UINT32_MAX - size_bytes
    ) {
        return UF_FALSE;
    }
    for (offset = 0; offset < size_bytes; ++offset) {
        if (
            !hardware->phys_read8(
                hardware->context,
                source + offset,
                &bytes[offset]
            )
        ) {
            return UF_FALSE;
        }
    }
    return UF_TRUE;
}

uf_bool_t uf_hw_phys_write_block(
    const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes
)
{
    const uint8_t *bytes = source;
    uf_rom_size_t offset;

    if (
        !uf_hardware_is_valid(hardware)
        || (source == NULL && size_bytes != 0)
        || destination > UINT32_MAX - size_bytes
    ) {
        return UF_FALSE;
    }
    for (offset = 0; offset < size_bytes; ++offset) {
        if (
            !hardware->phys_write8(
                hardware->context,
                destination + offset,
                bytes[offset]
            )
        ) {
            return UF_FALSE;
        }
    }
    return UF_TRUE;
}

uf_bool_t uf_hw_phys_compare_block(
    const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes,
    uf_bool_t *equal
)
{
    const uint8_t *bytes = source;
    uf_rom_size_t offset;

    if (equal == NULL) {
        return UF_FALSE;
    }
    *equal = UF_FALSE;
    if (
        !uf_hardware_is_valid(hardware)
        || (source == NULL && size_bytes != 0)
        || destination > UINT32_MAX - size_bytes
    ) {
        return UF_FALSE;
    }
    for (offset = 0; offset < size_bytes; ++offset) {
        uint8_t value;

        if (
            !hardware->phys_read8(
                hardware->context,
                destination + offset,
                &value
            )
        ) {
            return UF_FALSE;
        }
        if (value != bytes[offset]) {
            return UF_TRUE;
        }
    }
    *equal = UF_TRUE;
    return UF_TRUE;
}
