#include "uniflash/hardware.h"

bool uf_hardware_is_valid(const uf_hardware_t *hardware)
{
    return (
        hardware != NULL && hardware->in8 != NULL && hardware->in16 != NULL && hardware->in32 != NULL && hardware->out8 != NULL && hardware->out16 != NULL && hardware->out32 != NULL && hardware->phys_read8 != NULL && hardware->phys_write8 != NULL && hardware->delay_us != NULL);
}

bool uf_hw_phys_read_block(
    const uf_hardware_t *hardware,
    uf_phys_addr_t source,
    void *destination,
    uf_rom_size_t size_bytes)
{
    uint8_t *bytes = destination;
    if (
        !uf_hardware_is_valid(hardware) || (destination == NULL && size_bytes != 0) || source > UINT32_MAX - size_bytes)
    {
        return false;
    }
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        if (
            !hardware->phys_read8(
                hardware->context,
                source + offset,
                &bytes[offset]))
        {
            return false;
        }
    }
    return true;
}

bool uf_hw_phys_write_block(
    const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes)
{
    const uint8_t *bytes = source;
    if (
        !uf_hardware_is_valid(hardware) || (source == NULL && size_bytes != 0) || destination > UINT32_MAX - size_bytes)
    {
        return false;
    }
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        if (
            !hardware->phys_write8(
                hardware->context,
                destination + offset,
                bytes[offset]))
        {
            return false;
        }
    }
    return true;
}

bool uf_hw_phys_compare_block(
    const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes,
    bool *equal)
{
    const uint8_t *bytes = source;
    if (equal == NULL)
    {
        return false;
    }
    *equal = false;
    if (
        !uf_hardware_is_valid(hardware) || (source == NULL && size_bytes != 0) || destination > UINT32_MAX - size_bytes)
    {
        return false;
    }
    for (uf_rom_size_t offset = 0; offset < size_bytes; ++offset)
    {
        uint8_t value;

        if (
            !hardware->phys_read8(
                hardware->context,
                destination + offset,
                &value))
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
