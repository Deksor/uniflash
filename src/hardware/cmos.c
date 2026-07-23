#include <stdio.h>

#include "uniflash/cmos.h"

static bool indexed_read(
    const uf_hardware_t *hardware,
    uf_io_port_t index_port,
    uint8_t index,
    uint8_t *value)
{
    return (
               hardware->out8(hardware->context, index_port, index) && hardware->in8(
                                                                           hardware->context,
                                                                           (uf_io_port_t)(index_port + 1),
                                                                           value))
               ? true
               : false;
}

static bool indexed_write(
    const uf_hardware_t *hardware,
    uf_io_port_t index_port,
    uint8_t index,
    uint8_t value)
{
    return (
               hardware->out8(hardware->context, index_port, index) && hardware->out8(
                                                                           hardware->context,
                                                                           (uf_io_port_t)(index_port + 1),
                                                                           value))
               ? true
               : false;
}

bool uf_cmos_detect_last_index(
    const uf_hardware_t *hardware,
    uint8_t *last_index)
{
    uint8_t standard_10;
    uint8_t standard_50;
    uint8_t changed;
    uint8_t extended_90;
    uint8_t standard_probe;
    uint8_t extended_probe;

    if (!uf_hardware_is_valid(hardware) || last_index == NULL)
    {
        return false;
    }
    if (
        !indexed_read(hardware, UINT16_C(0x70), 0x10, &standard_10) || !indexed_read(hardware, UINT16_C(0x70), 0x50, &standard_50))
    {
        return false;
    }

    if (standard_10 == standard_50)
    {
        if (
            !indexed_write(
                hardware, UINT16_C(0x70), 0x50,
                standard_10 ^ UINT8_C(0x55)) ||
            !indexed_read(
                hardware, UINT16_C(0x70), 0x10, &changed))
        {
            (void)indexed_write(
                hardware, UINT16_C(0x70), 0x10, standard_10);
            (void)indexed_write(
                hardware, UINT16_C(0x70), 0x50, standard_50);
            return false;
        }
        if (
            !indexed_write(
                hardware, UINT16_C(0x70), 0x10, standard_10) ||
            !indexed_write(
                hardware, UINT16_C(0x70), 0x50, standard_50))
        {
            return false;
        }
        if (changed == (uint8_t)(standard_10 ^ UINT8_C(0x55)))
        {
            *last_index = UINT8_C(0x3F);
            return true;
        }
    }

    if (!indexed_read(
            hardware, UINT16_C(0x72), 0x90, &extended_90))
    {
        return false;
    }
    if (
        !indexed_write(hardware, UINT16_C(0x70), 0x10, 0x55) || !indexed_write(hardware, UINT16_C(0x72), 0x90, 0xAA) || !indexed_read(hardware, UINT16_C(0x70), 0x10, &standard_probe) || !indexed_read(hardware, UINT16_C(0x72), 0x90, &extended_probe))
    {
        (void)indexed_write(
            hardware, UINT16_C(0x70), 0x10, standard_10);
        (void)indexed_write(
            hardware, UINT16_C(0x72), 0x90, extended_90);
        return false;
    }
    if (
        !indexed_write(hardware, UINT16_C(0x70), 0x10, standard_10) || !indexed_write(hardware, UINT16_C(0x72), 0x90, extended_90))
    {
        return false;
    }
    *last_index = (standard_probe == UINT8_C(0x55) && extended_probe == UINT8_C(0xAA)) ? UINT8_C(0xFF) : UINT8_C(0x7F);
    return true;
}

bool uf_cmos_read(
    const uf_hardware_t *hardware,
    uint8_t last_index,
    uint8_t *data,
    uint16_t capacity,
    uint16_t *size_bytes)
{
    uint16_t required;
    uint16_t output = 0;
    uint16_t index;
    uint16_t standard_last = last_index;

    if (
        !uf_hardware_is_valid(hardware) || data == NULL || size_bytes == NULL || last_index < UF_CMOS_FIRST_SAVED_INDEX)
    {
        return false;
    }
    required = (uint16_t)last_index - (uint16_t)UF_CMOS_FIRST_SAVED_INDEX + 1;
    if (capacity < required)
    {
        return false;
    }
    if (standard_last > UINT16_C(0x7F))
    {
        standard_last = UINT16_C(0x7F);
    }
    for (
        index = UF_CMOS_FIRST_SAVED_INDEX;
        index <= standard_last;
        ++index)
    {
        if (!indexed_read(
                hardware, UINT16_C(0x70), (uint8_t)index, &data[output]))
        {
            return false;
        }
        ++output;
    }
    if (last_index > UINT8_C(0x7F))
    {
        for (index = 0x80; index <= last_index; ++index)
        {
            if (!indexed_read(
                    hardware,
                    UINT16_C(0x72),
                    (uint8_t)index,
                    &data[output]))
            {
                return false;
            }
            ++output;
        }
    }
    *size_bytes = output;
    return true;
}

bool uf_cmos_save_file(
    const uf_hardware_t *hardware,
    uint8_t last_index,
    const char *path)
{
    uint8_t data[UF_CMOS_MAX_SAVED_BYTES];
    uint16_t size_bytes;
    FILE *file;
    bool written;
    bool closed;

    if (
        path == NULL || path[0] == '\0' || !uf_cmos_read(hardware, last_index, data, sizeof(data), &size_bytes))
    {
        return false;
    }
    file = fopen(path, "wb");
    if (file == NULL)
    {
        return false;
    }
    written = fwrite(data, 1, size_bytes, file) == size_bytes
                  ? true
                  : false;
    closed = fclose(file) == 0 ? true : false;
    return written && closed ? true : false;
}
