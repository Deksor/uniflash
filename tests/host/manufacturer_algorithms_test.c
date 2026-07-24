#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "uniflash/all_algorithms.h"

typedef struct mock_backend {
    uf_rom_offset_t write_addresses[128];
    uint8_t write_values[128];
    uint16_t write_count;
    uf_phys_addr_t phys_addresses[64];
    uint8_t phys_and_masks[64];
    uint8_t phys_or_masks[64];
    uint8_t phys_count;
    uf_rom_offset_t last_read_address;
} mock_backend_t;

static bool mock_read(void *context, uf_rom_offset_t address, uint8_t *value) {
    mock_backend_t *mock = context;

    mock->last_read_address = address;
    *value = UINT8_C(0x80);
    return true;
}

static bool mock_write(void *context, uf_rom_offset_t address, uint8_t value) {
    mock_backend_t *mock = context;

    if (mock->write_count < 128) {
        mock->write_addresses[mock->write_count] = address;
        mock->write_values[mock->write_count] = value;
        ++mock->write_count;
    }
    return true;
}

static bool mock_delay(void *context, uint32_t microseconds) {
    (void)context;
    (void)microseconds;
    return true;
}

static bool mock_source(void *context, uf_phys_addr_t address, uint8_t *value) {
    (void)context;
    (void)address;
    *value = UINT8_C(0x80);
    return true;
}

static bool mock_update_phys(void *context, uf_phys_addr_t address, uint8_t and_mask, uint8_t or_mask) {
    mock_backend_t *mock = context;
    uint8_t index = mock->phys_count;

    assert(index < 64);
    mock->phys_addresses[index] = address;
    mock->phys_and_masks[index] = and_mask;
    mock->phys_or_masks[index] = or_mask;
    ++mock->phys_count;
    return true;
}

static void init_service(uf_flash_service_t *service,
    mock_backend_t *mock,
    uf_flash_algorithm_registry_t *registry,
    uf_flash_chip_t *chip) {
    uf_flash_access_t access;

    memset(mock, 0, sizeof(*mock));
    memset(&access, 0, sizeof(access));
    access.context = mock;
    access.read_byte = mock_read;
    access.write_byte = mock_write;
    access.delay_us = mock_delay;
    access.read_source_byte = mock_source;
    access.update_phys_byte = mock_update_phys;
    assert(uf_flash_service_init(service, &access, 0));
    assert(uf_flash_service_set_algorithms(service, registry));
    service->chip = chip;
}

static void test_complete_registry(void) {
    uf_flash_algorithm_registry_t registry;
    uint16_t manufacturer_index;

    memset(&registry, 0, sizeof(registry));
    assert(uf_flash_register_all_algorithms(&registry));
    for (manufacturer_index = 0; manufacturer_index < uf_rom_manufacturer_count; ++manufacturer_index) {
        const uf_flash_manufacturer_t *manufacturer = &uf_rom_manufacturers[manufacturer_index];
        uint16_t chip_index;

        for (chip_index = 0; chip_index < manufacturer->chip_count; ++chip_index) {
            const uf_flash_chip_t *chip = &manufacturer->chips[chip_index];

            assert(chip->program_algorithm != UF_FLASH_PROGRAM_NONE);
            assert(registry.program[chip->program_algorithm] != NULL);
            if (chip->erase_algorithm != UF_FLASH_ERASE_NONE) {
                assert(registry.erase[chip->erase_algorithm] != NULL);
            }
        }
    }
}

static void test_winbond_erase_command(void) {
    uf_flash_algorithm_registry_t registry;
    uf_flash_service_t service;
    mock_backend_t mock;
    uf_flash_chip_t chip;
    uint16_t index;
    bool found = false;

    memset(&registry, 0, sizeof(registry));
    memset(&chip, 0, sizeof(chip));
    chip.capacity_bytes = UF_KIB(512);
    chip.page_size_bytes = 1;
    assert(uf_flash_register_all_algorithms(&registry));
    init_service(&service, &mock, &registry, &chip);
    assert(registry.erase[UF_FLASH_ERASE_WINBOND_SECTOR](&service, UINT32_C(0x12000)));
    for (index = 0; index < mock.write_count; ++index) {
        if (mock.write_addresses[index] == UINT32_C(0x12000) && mock.write_values[index] == UINT8_C(0x50)) {
            found = true;
        }
    }
    assert(found);
}

static void test_atmel_legacy_poll_and_fwh2_locks(void) {
    uf_flash_algorithm_registry_t registry;
    uf_flash_service_t service;
    mock_backend_t mock;
    uf_flash_chip_t chip;

    memset(&registry, 0, sizeof(registry));
    memset(&chip, 0, sizeof(chip));
    chip.capacity_bytes = UF_KIB(256);
    chip.page_size_bytes = 64;
    assert(uf_flash_register_all_algorithms(&registry));
    init_service(&service, &mock, &registry, &chip);
    assert(registry.program[UF_FLASH_PROGRAM_ATMEL_PAGE](&service, UINT32_C(0x1000), UINT32_C(0x2000)));
    assert(mock.last_read_address == UINT32_C(0x107F));

    chip.page_size_bytes = 1;
    memset(&mock, 0, sizeof(mock));
    assert(registry.program[UF_FLASH_PROGRAM_ATMEL_FWH2](&service, UINT32_C(0x3A000), UINT32_C(0x2000)));
    assert(mock.phys_count == 4);
    assert(mock.phys_addresses[0] == UINT32_C(0xFFBFA002));
    assert(mock.phys_addresses[1] == UINT32_C(0xFF7FA002));
    assert(mock.phys_and_masks[0] == UINT8_C(0xFC));
    assert(mock.phys_or_masks[2] == UINT8_C(0x01));
}

static void test_shared_32k_lock_mapping(void) {
    uf_flash_service_t service;
    uf_flash_chip_t chip;

    memset(&service, 0, sizeof(service));
    memset(&chip, 0, sizeof(chip));
    chip.capacity_bytes = UF_KIB(256);
    service.chip = &chip;
    assert(uf_flash_fwh_32k_lock_address(&service, UINT32_C(0x39000)) == UINT32_C(0xFFBF0002));
}

int main(void) {
    test_complete_registry();
    test_winbond_erase_command();
    test_atmel_legacy_poll_and_fwh2_locks();
    test_shared_32k_lock_mapping();
    puts("manufacturer algorithm tests passed");
    return 0;
}
