#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "uniflash/chipset.h"
#include "uniflash/ct_flasher.h"
#include "uniflash/flash_backend.h"
#include "uniflash/pci_rom.h"

typedef struct config_entry {
    uint32_t address;
    uint32_t value;
} config_entry_t;

typedef struct mock_hardware {
    uint32_t config_address;
    config_entry_t config[32];
    uint8_t config_count;
    uint8_t ports[65536];
    uint8_t physical[65536];
    uf_phys_addr_t last_phys_address;
    uint8_t selected_bank;
    uf_io_port_t ct_port;
    uint8_t ct_status;
} mock_hardware_t;

static config_entry_t *find_config(
    mock_hardware_t *mock,
    uint32_t address
)
{
    uint8_t index;

    for (index = 0; index < mock->config_count; ++index) {
        if (mock->config[index].address == address) {
            return &mock->config[index];
        }
    }
    return NULL;
}

static void set_config(
    mock_hardware_t *mock,
    uf_pci_address_t address,
    uint8_t reg,
    uint32_t value
)
{
    config_entry_t *entry;
    uint32_t key = uf_pci_mechanism1_address(address, reg);

    entry = find_config(mock, key);
    if (entry == NULL) {
        assert(mock->config_count < 32);
        entry = &mock->config[mock->config_count++];
        entry->address = key;
    }
    entry->value = value;
}

static uint32_t get_config(
    mock_hardware_t *mock,
    uf_pci_address_t address,
    uint8_t reg
)
{
    config_entry_t *entry = find_config(
        mock,
        uf_pci_mechanism1_address(address, reg)
    );
    return entry == NULL ? UINT32_MAX : entry->value;
}

static uf_bool_t in8(void *context, uf_io_port_t port, uint8_t *value)
{
    mock_hardware_t *mock = context;
    *value = port == mock->ct_port
        ? mock->ct_status
        : mock->ports[port];
    return UF_TRUE;
}

static uf_bool_t in16(void *context, uf_io_port_t port, uint16_t *value)
{
    mock_hardware_t *mock = context;
    *value = (uint16_t)mock->ports[port]
        | ((uint16_t)mock->ports[(uint16_t)(port + 1)] << 8);
    return UF_TRUE;
}

static uf_bool_t in32(void *context, uf_io_port_t port, uint32_t *value)
{
    mock_hardware_t *mock = context;

    if (port == UF_PCI_CONFIG_DATA_PORT) {
        config_entry_t *entry = find_config(mock, mock->config_address);
        *value = entry == NULL ? UINT32_MAX : entry->value;
    } else {
        *value = (uint32_t)mock->ports[port]
            | ((uint32_t)mock->ports[(uint16_t)(port + 1)] << 8)
            | ((uint32_t)mock->ports[(uint16_t)(port + 2)] << 16)
            | ((uint32_t)mock->ports[(uint16_t)(port + 3)] << 24);
    }
    return UF_TRUE;
}

static uf_bool_t out8(
    void *context,
    uf_io_port_t port,
    uint8_t value
)
{
    mock_hardware_t *mock = context;
    if (port == mock->ct_port) {
        mock->selected_bank = value;
    } else {
        mock->ports[port] = value;
    }
    return UF_TRUE;
}

static uf_bool_t out16(
    void *context,
    uf_io_port_t port,
    uint16_t value
)
{
    mock_hardware_t *mock = context;
    mock->ports[port] = (uint8_t)value;
    mock->ports[(uint16_t)(port + 1)] = (uint8_t)(value >> 8);
    return UF_TRUE;
}

static uf_bool_t out32(
    void *context,
    uf_io_port_t port,
    uint32_t value
)
{
    mock_hardware_t *mock = context;

    if (port == UF_PCI_CONFIG_ADDRESS_PORT) {
        mock->config_address = value;
    } else if (port == UF_PCI_CONFIG_DATA_PORT) {
        config_entry_t *entry = find_config(mock, mock->config_address);
        assert(entry != NULL);
        entry->value = value;
    } else {
        mock->ports[port] = (uint8_t)value;
        mock->ports[(uint16_t)(port + 1)] = (uint8_t)(value >> 8);
        mock->ports[(uint16_t)(port + 2)] = (uint8_t)(value >> 16);
        mock->ports[(uint16_t)(port + 3)] = (uint8_t)(value >> 24);
    }
    return UF_TRUE;
}

static uf_bool_t phys_read(
    void *context,
    uf_phys_addr_t address,
    uint8_t *value
)
{
    mock_hardware_t *mock = context;
    mock->last_phys_address = address;
    *value = mock->physical[(uint16_t)address];
    return UF_TRUE;
}

static uf_bool_t phys_write(
    void *context,
    uf_phys_addr_t address,
    uint8_t value
)
{
    mock_hardware_t *mock = context;
    mock->last_phys_address = address;
    mock->physical[(uint16_t)address] = value;
    return UF_TRUE;
}

static uf_bool_t delay_us(void *context, uint32_t microseconds)
{
    (void)context;
    (void)microseconds;
    return UF_TRUE;
}

static void init_hardware(
    uf_hardware_t *hardware,
    mock_hardware_t *mock
)
{
    memset(mock, 0, sizeof(*mock));
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
    assert(uf_hardware_is_valid(hardware));
}

static uf_bool_t select_bank(void *context, uint8_t bank)
{
    mock_hardware_t *mock = context;
    mock->selected_bank = bank;
    return UF_TRUE;
}

static void test_pci_address(void)
{
    uf_pci_address_t address;

    address.bus = 2;
    address.device = 5;
    address.function = 3;
    assert(
        uf_pci_mechanism1_address(address, UINT8_C(0x4F))
        == UINT32_C(0x80022B4C)
    );
}

static void test_flash_backend_banking(void)
{
    uf_hardware_t hardware;
    mock_hardware_t mock;
    uf_system_flash_backend_t backend;
    uf_flash_access_t access;
    uint8_t value;

    init_hardware(&hardware, &mock);
    assert(uf_system_flash_backend_init(
        &backend,
        &hardware,
        UINT32_C(0x1000)
    ));
    assert(uf_system_flash_backend_set_banking(
        &backend,
        UINT32_C(0x100),
        UINT32_C(0x2000),
        select_bank,
        &mock
    ));
    assert(uf_system_flash_backend_make_access(&backend, &access));
    mock.physical[UINT32_C(0x1055)] = UINT8_C(0xA5);
    assert(access.read_byte(
        access.context,
        UINT32_C(0x255),
        &value
    ));
    assert(value == UINT8_C(0xA5));
    assert(mock.selected_bank == UINT8_C(2));
    assert(access.write_byte(
        access.context,
        UINT32_C(0x355),
        UINT8_C(0x5A)
    ));
    assert(mock.selected_bank == UINT8_C(3));
    assert(mock.physical[UINT32_C(0x2055)] == UINT8_C(0x5A));
}

static void test_intel_chipset_enable_restore(void)
{
    uf_hardware_t hardware;
    mock_hardware_t mock;
    uf_chipset_t chipset;
    uf_pci_address_t north = { 0, 0, 0 };
    uf_pci_address_t south = { 0, 31, 0 };

    init_hardware(&hardware, &mock);
    mock.ports[UINT16_C(0xCFB)] = UINT8_C(0);
    set_config(&mock, north, UINT8_C(0), UINT32_C(0x11308086));
    set_config(&mock, north, UINT8_C(0x08), UINT32_C(0x06000001));
    set_config(&mock, north, UINT8_C(0x0C), UINT32_C(0));
    set_config(&mock, south, UINT8_C(0), UINT32_C(0x24408086));
    set_config(&mock, south, UINT8_C(0x08), UINT32_C(0x06010002));
    set_config(&mock, south, UINT8_C(0x0C), UINT32_C(0));
    set_config(&mock, south, UINT8_C(0x4C), UINT32_C(0x12340000));
    set_config(&mock, south, UINT8_C(0xE0), UINT32_C(0x40000000));

    assert(uf_chipset_detect(&chipset, &hardware));
    assert(chipset.north_found);
    assert(chipset.south_found);
    assert(chipset.south_method == UINT16_C(0x0200));
    assert(uf_chipset_rom_set_enabled(&chipset, UF_TRUE));
    assert(
        get_config(&mock, south, UINT8_C(0x4C))
        == UINT32_C(0x12350000)
    );
    assert(
        get_config(&mock, south, UINT8_C(0xE0))
        == UINT32_C(0xFF000000)
    );
    assert(uf_chipset_rom_set_enabled(&chipset, UF_FALSE));
    assert(
        get_config(&mock, south, UINT8_C(0x4C))
        == UINT32_C(0x12340000)
    );
    assert(
        get_config(&mock, south, UINT8_C(0xE0))
        == UINT32_C(0x40000000)
    );
}

static void test_ct_flasher_window(void)
{
    uf_hardware_t hardware;
    mock_hardware_t mock;
    uf_ct_flasher_t flasher;
    uf_flash_access_t access;
    uint8_t value;

    init_hardware(&hardware, &mock);
    mock.ct_port = UINT16_C(0x300);
    mock.ct_status = UINT8_C(0x98);
    assert(uf_ct_flasher_detect(
        &flasher,
        &hardware,
        UINT16_C(0x300),
        UF_FALSE
    ));
    assert(flasher.window_base == UINT32_C(0xCC000));
    assert(uf_ct_flasher_make_access(&flasher, &access));
    mock.physical[UINT16_C(0xC000)] = UINT8_C(0xA5);
    assert(access.read_byte(access.context, 0, &value));
    assert(value == UINT8_C(0xA5));
    assert(mock.selected_bank == UINT8_C(0x80));
    assert(mock.last_phys_address == UINT32_C(0xCC000));
}

static void test_3com_pci_flash_access(void)
{
    uf_hardware_t hardware;
    mock_hardware_t mock;
    uf_pci_rom_device_t device;
    uf_pci_rom_backend_t backend;
    uf_flash_access_t access;
    uf_pci_address_t address = { 0, 5, 0 };
    uint8_t value;

    init_hardware(&hardware, &mock);
    memset(&device, 0, sizeof(device));
    device.pci_device.address = address;
    device.pci_device.vendor_id = UINT16_C(0x10B7);
    device.pci_device.device_id = UINT16_C(0x9001);
    device.maximum_size = UF_KIB(128);
    set_config(&mock, address, UINT8_C(0x10), UINT32_C(0x301));
    set_config(&mock, address, UINT8_C(0x04), UINT32_C(0x05));
    set_config(&mock, address, UINT8_C(0x30), UINT32_C(0));
    assert(uf_pci_rom_backend_init(&backend, &hardware, &device));
    assert(backend.kind == UF_PCI_FLASH_3COM);
    assert(backend.io_base == UINT16_C(0x300));
    assert(uf_pci_rom_backend_make_access(&backend, &access));
    assert(uf_pci_rom_backend_set_enabled(&backend, UF_TRUE));
    assert(access.write_byte(
        access.context,
        UINT32_C(0x22),
        UINT8_C(0x5A)
    ));
    assert(mock.ports[UINT16_C(0x304)] == UINT8_C(0x22));
    assert(mock.ports[UINT16_C(0x308)] == UINT8_C(0x5A));
    assert(access.read_byte(access.context, UINT32_C(0x22), &value));
    assert(value == UINT8_C(0x5A));
    assert(uf_pci_rom_backend_set_enabled(&backend, UF_FALSE));
    assert(get_config(&mock, address, UINT8_C(0x04)) == UINT32_C(0x05));
    assert(get_config(&mock, address, UINT8_C(0x30)) == UINT32_C(0));
}

int main(void)
{
    test_pci_address();
    test_flash_backend_banking();
    test_intel_chipset_enable_restore();
    test_ct_flasher_window();
    test_3com_pci_flash_access();
    puts("hardware tests passed");
    return 0;
}
