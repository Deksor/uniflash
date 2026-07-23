#include <assert.h>
#include <string.h>

#include "uniflash/cmos.h"

typedef struct cmos_mock
{
    uint8_t standard[128];
    uint8_t extended[256];
    uint8_t standard_index;
    uint8_t extended_index;
    uint8_t standard_size;
    bool extended_present;
} cmos_mock_t;

static bool in8(void *context, uf_io_port_t port, uint8_t *value)
{
    cmos_mock_t *mock = context;
    if (port == 0x71)
    {
        *value = mock->standard[mock->standard_index % mock->standard_size];
        return true;
    }
    if (port == 0x73)
    {
        *value = mock->extended_present
                     ? mock->extended[mock->extended_index]
                     : 0xFF;
        return true;
    }
    *value = 0;
    return true;
}

static bool in16(
    void *context, uf_io_port_t port, uint16_t *value)
{
    uint8_t low;
    (void)in8(context, port, &low);
    *value = low;
    return true;
}

static bool in32(
    void *context, uf_io_port_t port, uint32_t *value)
{
    uint8_t low;
    (void)in8(context, port, &low);
    *value = low;
    return true;
}

static bool out8(
    void *context, uf_io_port_t port, uint8_t value)
{
    cmos_mock_t *mock = context;
    if (port == 0x70)
    {
        mock->standard_index = value;
    }
    else if (port == 0x71)
    {
        mock->standard[mock->standard_index % mock->standard_size] = value;
    }
    else if (port == 0x72)
    {
        mock->extended_index = value;
    }
    else if (port == 0x73 && mock->extended_present)
    {
        mock->extended[mock->extended_index] = value;
    }
    return true;
}

static bool out16(
    void *context, uf_io_port_t port, uint16_t value)
{
    return out8(context, port, (uint8_t)value);
}

static bool out32(
    void *context, uf_io_port_t port, uint32_t value)
{
    return out8(context, port, (uint8_t)value);
}

static bool phys_read(
    void *context, uf_phys_addr_t address, uint8_t *value)
{
    (void)context;
    (void)address;
    *value = 0;
    return true;
}

static bool phys_write(
    void *context, uf_phys_addr_t address, uint8_t value)
{
    (void)context;
    (void)address;
    (void)value;
    return true;
}

static bool delay_us(void *context, uint32_t value)
{
    (void)context;
    (void)value;
    return true;
}

static void init_hardware(
    uf_hardware_t *hardware,
    cmos_mock_t *mock,
    uint8_t standard_size,
    bool extended_present)
{
    uint16_t index;
    memset(mock, 0, sizeof(*mock));
    for (index = 0; index < 128; ++index)
    {
        mock->standard[index] = (uint8_t)(index * 3 + 1);
    }
    for (index = 0; index < 256; ++index)
    {
        mock->extended[index] = (uint8_t)(index * 5 + 2);
    }
    mock->standard_size = standard_size;
    mock->extended_present = extended_present;
    memset(hardware, 0, sizeof(*hardware));
    hardware->context = mock;
    hardware->in8 = in8;
    hardware->in16 = in16;
    hardware->in32 = in32;
    hardware->out8 = out8;
    hardware->out16 = out16;
    hardware->out32 = out32;
    hardware->phys_read8 = phys_read;
    hardware->phys_write8 = phys_write;
    hardware->delay_us = delay_us;
}

int main(void)
{
    cmos_mock_t mock;
    uf_hardware_t hardware;
    uint8_t last;
    uint8_t data[UF_CMOS_MAX_SAVED_BYTES];
    uint16_t size;
    uint8_t saved_10;
    uint8_t saved_50;
    uint8_t saved_90;

    init_hardware(&hardware, &mock, 64, false);
    saved_10 = mock.standard[0x10];
    saved_50 = mock.standard[0x50 % 64];
    assert(uf_cmos_detect_last_index(&hardware, &last));
    assert(last == 0x3F);
    assert(mock.standard[0x10] == saved_10);
    assert(mock.standard[0x50 % 64] == saved_50);

    init_hardware(&hardware, &mock, 128, false);
    assert(uf_cmos_detect_last_index(&hardware, &last));
    assert(last == 0x7F);
    assert(uf_cmos_read(
        &hardware, last, data, sizeof(data), &size));
    assert(size == 114);
    assert(data[0] == mock.standard[0x0E]);

    init_hardware(&hardware, &mock, 128, true);
    saved_10 = mock.standard[0x10];
    saved_90 = mock.extended[0x90];
    assert(uf_cmos_detect_last_index(&hardware, &last));
    assert(last == 0xFF);
    assert(mock.standard[0x10] == saved_10);
    assert(mock.extended[0x90] == saved_90);
    assert(uf_cmos_read(
        &hardware, last, data, sizeof(data), &size));
    assert(size == 242);
    assert(data[114] == mock.extended[0x80]);
    return 0;
}
