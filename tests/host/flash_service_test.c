#include <assert.h>
#include <string.h>

#include "uniflash/flash_service.h"
#include "uniflash/generic_algorithms.h"
#include "uniflash/intel_algorithms.h"
#include "uniflash/sharp_algorithms.h"

typedef struct mock_flash
{
    uint32_t reads;
    uint32_t writes;
    uint16_t block_reads;
    uint16_t block_writes;
    uint16_t block_compares;
    uint32_t fail_on_write;
    uint32_t delays;
    uint32_t fail_on_delay;
    uint16_t windows;
    uint16_t fail_on_window;
    uint16_t programs;
    uint16_t erases;
    uint16_t lock_changes;
    uint16_t fail_on_lock_change;
    uint32_t source_reads;
    bool fail_algorithm;
    bool toggle_reads;
    bool zero_reads;
    bool use_default_read_value;
    uint8_t default_read_value;
    uint32_t sharp_top_busy_reads;
    uint16_t read_script_count;
    uint16_t read_script_index;
    uf_rom_offset_t block_address;
    uf_rom_size_t block_size;
    uf_rom_offset_t read_addresses[64];
    uint8_t read_values[64];
    uf_rom_offset_t write_addresses[64];
    uint8_t write_values[64];
    uint32_t delay_values[32];
    uf_phys_addr_t window_bases[16];
    uf_rom_offset_t algorithm_position;
    uf_phys_addr_t algorithm_source;
    uf_phys_addr_t source_base;
    uint16_t source_size;
    uint8_t source_values[256];
    uf_rom_offset_t last_write_address;
    uint8_t last_write_value;
    uf_phys_addr_t lock_addresses[4];
    bool lock_states[4];
} mock_flash_t;

static bool mock_read_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t *value)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    if (mock->read_script_index < mock->read_script_count)
    {
        assert(
            address == mock->read_addresses[mock->read_script_index]);
        *value = mock->read_values[mock->read_script_index];
        ++mock->read_script_index;
    }
    else if (
        address == UINT32_C(0x1F0000) && mock->sharp_top_busy_reads > 0)
    {
        --mock->sharp_top_busy_reads;
        *value = UINT8_C(0x00);
    }
    else if (mock->toggle_reads)
    {
        *value = (mock->reads & UINT32_C(1)) != 0
                     ? UINT8_C(0x40)
                     : UINT8_C(0x00);
    }
    else if (mock->zero_reads)
    {
        *value = UINT8_C(0x00);
    }
    else if (mock->use_default_read_value)
    {
        *value = mock->default_read_value;
    }
    else
    {
        *value = UINT8_C(0xFF);
    }
    ++mock->reads;
    return true;
}

static bool mock_write_byte(
    void *context,
    uf_rom_offset_t address,
    uint8_t value)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    if (mock->writes < 64)
    {
        mock->write_addresses[mock->writes] = address;
        mock->write_values[mock->writes] = value;
    }
    mock->last_write_address = address;
    mock->last_write_value = value;
    ++mock->writes;
    if (mock->fail_on_write == mock->writes)
    {
        return false;
    }
    return true;
}

static bool mock_read_source_byte(
    void *context,
    uf_phys_addr_t source_address,
    uint8_t *value)
{
    mock_flash_t *mock = (mock_flash_t *)context;
    uf_phys_addr_t offset;

    if (
        source_address < mock->source_base || source_address - mock->source_base >= mock->source_size)
    {
        return false;
    }
    offset = source_address - mock->source_base;
    *value = mock->source_values[(uint16_t)offset];
    ++mock->source_reads;
    return true;
}

static bool mock_delay_us(void *context, uint32_t microseconds)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    if (mock->delays < 32)
    {
        mock->delay_values[mock->delays] = microseconds;
    }
    ++mock->delays;
    if (mock->fail_on_delay == mock->delays)
    {
        return false;
    }
    return true;
}

static bool mock_select_window(
    void *context,
    uf_phys_addr_t rom_base)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    if (mock->windows < 16)
    {
        mock->window_bases[mock->windows] = rom_base;
    }
    ++mock->windows;
    if (mock->fail_on_window == mock->windows)
    {
        return false;
    }
    return true;
}

static bool mock_set_write_lock(
    void *context,
    uf_phys_addr_t lock_register_address,
    bool locked)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    if (mock->lock_changes < 4)
    {
        mock->lock_addresses[mock->lock_changes] = lock_register_address;
        mock->lock_states[mock->lock_changes] = locked;
    }
    ++mock->lock_changes;
    if (mock->fail_on_lock_change == mock->lock_changes)
    {
        return false;
    }
    return true;
}

static bool mock_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    mock_flash_t *mock = (mock_flash_t *)service->access.context;

    ++mock->programs;
    mock->algorithm_position = position;
    mock->algorithm_source = source_address;
    return mock->fail_algorithm ? false : true;
}

static bool mock_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address)
{
    mock_flash_t *mock = (mock_flash_t *)service->access.context;

    ++mock->erases;
    mock->algorithm_position = sector_address;
    return mock->fail_algorithm ? false : true;
}

static bool mock_read_block(
    void *context,
    uf_rom_offset_t flash_address,
    void *destination,
    uf_rom_size_t size_bytes)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    (void)destination;
    ++mock->block_reads;
    mock->block_address = flash_address;
    mock->block_size = size_bytes;
    return true;
}

static bool mock_write_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    (void)source;
    ++mock->block_writes;
    mock->block_address = flash_address;
    mock->block_size = size_bytes;
    return true;
}

static bool mock_compare_block(
    void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    bool *equal)
{
    mock_flash_t *mock = (mock_flash_t *)context;

    (void)source;
    ++mock->block_compares;
    mock->block_address = flash_address;
    mock->block_size = size_bytes;
    *equal = true;
    return true;
}

int main(void)
{
    mock_flash_t mock;
    uf_flash_access_t access;
    uf_flash_algorithm_registry_t algorithms;
    uf_flash_service_t service;
    uf_flash_id_result_t id_result;
    uint8_t byte_value;
    uint8_t buffer[4];
    bool equal;
    uint16_t candidate_index;
    uint16_t script_index;

    memset(&mock, 0, sizeof(mock));
    memset(&access, 0, sizeof(access));
    access.context = &mock;
    access.read_byte = mock_read_byte;
    access.write_byte = mock_write_byte;
    access.read_block = mock_read_block;
    access.write_block = mock_write_block;
    access.compare_block = mock_compare_block;
    access.delay_us = mock_delay_us;
    access.select_window = mock_select_window;
    access.read_source_byte = mock_read_source_byte;
    access.set_write_lock = mock_set_write_lock;

    assert(uf_flash_access_is_valid(NULL) == false);
    assert(uf_flash_access_is_valid(&access) == true);

    access.read_byte = NULL;
    assert(uf_flash_access_is_valid(&access) == false);
    access.read_byte = mock_read_byte;
    access.write_byte = NULL;
    assert(uf_flash_access_is_valid(&access) == false);
    access.write_byte = mock_write_byte;

    assert(
        uf_flash_service_init(
            &service,
            &access,
            UINT32_C(0xFFF80000)) == true);
    assert(service.rom_base == UINT32_C(0xFFF80000));
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(service.manufacturer_id == UINT8_C(0xFF));
    assert(service.device_id == UINT8_C(0xFF));
    assert(service.error == UF_FLASH_ERROR_NONE);

    assert(uf_flash_service_range_is_valid(&service, UINT32_MAX, 0));
    assert(!uf_flash_service_range_is_valid(&service, UINT32_MAX, 1));
    assert(uf_flash_service_read_byte(&service, 0, &byte_value));
    assert(byte_value == UINT8_C(0xFF));
    assert(mock.reads == 1);
    assert(!uf_flash_service_read_byte(&service, UINT32_MAX, &byte_value));
    assert(mock.reads == 1);
    assert(uf_flash_service_write_byte(&service, 0, UINT8_C(0x12)));
    assert(mock.writes == 1);
    memset(&mock, 0, sizeof(mock));

    assert(uf_flash_service_select_chip(&service, 0x01, 0xA1) == true);
    assert(strcmp(service.manufacturer->name, "AMD") == 0);
    assert(strcmp(service.chip->name, "Am28F256/12V") == 0);
    assert(service.manufacturer_id == UINT8_C(0x01));
    assert(service.device_id == UINT8_C(0xA1));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(uf_flash_service_range_is_valid(&service, UF_KIB(32), 0));
    assert(
        uf_flash_service_range_is_valid(
            &service,
            UF_KIB(32) - UINT32_C(4),
            UINT32_C(4)));
    assert(!uf_flash_service_range_is_valid(&service, UF_KIB(32), 1));

    assert(
        uf_flash_service_read_block(
            &service,
            UF_KIB(32) - sizeof(buffer),
            buffer,
            sizeof(buffer)));
    assert(mock.block_reads == 1);
    assert(mock.block_address == UF_KIB(32) - sizeof(buffer));
    assert(mock.block_size == sizeof(buffer));
    assert(
        !uf_flash_service_read_block(
            &service,
            UF_KIB(32) - sizeof(buffer) + 1,
            buffer,
            sizeof(buffer)));
    assert(mock.block_reads == 1);

    assert(
        uf_flash_service_write_block(
            &service,
            buffer,
            UF_KIB(32) - sizeof(buffer),
            sizeof(buffer)));
    assert(mock.block_writes == 1);
    assert(
        !uf_flash_service_write_block(
            &service,
            buffer,
            UF_KIB(32),
            sizeof(buffer)));
    assert(mock.block_writes == 1);

    equal = false;
    assert(
        uf_flash_service_compare_block(
            &service,
            buffer,
            UF_KIB(32) - sizeof(buffer),
            sizeof(buffer),
            &equal));
    assert(equal == true);
    assert(mock.block_compares == 1);
    assert(
        !uf_flash_service_compare_block(
            &service,
            buffer,
            UF_KIB(32),
            sizeof(buffer),
            &equal));
    assert(mock.block_compares == 1);

    assert(uf_flash_service_select_chip(&service, 0x01, 0x00) == false);
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(service.manufacturer_id == UINT8_C(0xFF));
    assert(service.device_id == UINT8_C(0xFF));
    assert(service.error == UF_FLASH_ERROR_UNKNOWN_CHIP);

    uf_flash_service_clear_selection(&service);
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(service.error == UF_FLASH_ERROR_UNKNOWN_CHIP);
    assert(mock.reads == 0);
    assert(mock.writes == 0);

    assert(uf_flash_service_command(&service, UINT8_C(0x90)) == true);
    assert(mock.writes == 3);
    assert(mock.write_addresses[0] == UINT32_C(0x5555));
    assert(mock.write_values[0] == UINT8_C(0xAA));
    assert(mock.write_addresses[1] == UINT32_C(0x2AAA));
    assert(mock.write_values[1] == UINT8_C(0x55));
    assert(mock.write_addresses[2] == UINT32_C(0x5555));
    assert(mock.write_values[2] == UINT8_C(0x90));

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 1;
    assert(uf_flash_service_command(&service, UINT8_C(0xF0)) == false);
    assert(mock.writes == 1);

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 2;
    assert(uf_flash_service_command(&service, UINT8_C(0xF0)) == false);
    assert(mock.writes == 2);

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 3;
    assert(uf_flash_service_command(&service, UINT8_C(0xF0)) == false);
    assert(mock.writes == 3);

    assert(uf_flash_id_has_odd_parity(UINT8_C(0x00)) == false);
    assert(uf_flash_id_has_odd_parity(UINT8_C(0x01)) == true);
    assert(uf_flash_id_has_odd_parity(UINT8_C(0x03)) == false);
    assert(uf_flash_id_has_odd_parity(UINT8_C(0x7F)) == true);
    assert(uf_flash_id_has_odd_parity(UINT8_C(0xC2)) == true);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x01);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0xA1);
    assert(
        uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));
    assert(id_result.initial_manufacturer_id == UINT8_C(0xFF));
    assert(id_result.initial_device_id == UINT8_C(0xFF));
    assert(id_result.manufacturer_id == UINT8_C(0x01));
    assert(id_result.device_id == UINT8_C(0xA1));
    assert(id_result.valid == true);
    assert(mock.read_script_index == mock.read_script_count);
    assert(mock.writes == 4);
    assert(mock.write_values[2] == UINT8_C(0x90));
    assert(mock.write_addresses[3] == 0);
    assert(mock.write_values[3] == UINT8_C(0xF0));
    assert(mock.delays == 2);
    assert(mock.delay_values[0] == UINT32_C(50));
    assert(mock.delay_values[1] == UINT32_C(1000));

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 6;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x7F);
    mock.read_addresses[3] = 0x100;
    mock.read_values[3] = UINT8_C(0x1C);
    mock.read_addresses[4] = 1;
    mock.read_values[4] = UINT8_C(0x7F);
    mock.read_addresses[5] = 0x101;
    mock.read_values[5] = UINT8_C(0x13);
    assert(
        uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));
    assert(id_result.manufacturer_id == UINT8_C(0x1C));
    assert(id_result.device_id == UINT8_C(0x13));
    assert(id_result.valid == true);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 6;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x7F);
    mock.read_addresses[3] = 0x100;
    mock.read_values[3] = UINT8_C(0x7F);
    mock.read_addresses[4] = 3;
    mock.read_values[4] = UINT8_C(0x1F);
    mock.read_addresses[5] = 1;
    mock.read_values[5] = UINT8_C(0xA0);
    assert(
        uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));
    assert(id_result.manufacturer_id == UINT8_C(0x7F));
    assert(id_result.device_id == UINT8_C(0xA0));
    assert(id_result.valid == true);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0xC2);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0xA4);
    assert(
        uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));
    assert(id_result.manufacturer_id == UINT8_C(0xC2));
    assert(id_result.device_id == UINT8_C(0xA4));
    assert(id_result.valid == true);
    assert(mock.writes == 8);
    assert(mock.write_addresses[3] == 0);
    assert(mock.write_values[3] == UINT8_C(0xF0));
    assert(mock.write_values[6] == UINT8_C(0x90));
    assert(mock.write_addresses[7] == 0);
    assert(mock.write_values[7] == UINT8_C(0xF0));
    assert(mock.delays == 4);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x89);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0x94);
    assert(
        uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_LEGACY,
            &id_result));
    assert(id_result.manufacturer_id == UINT8_C(0x89));
    assert(id_result.device_id == UINT8_C(0x94));
    assert(id_result.valid == true);
    assert(mock.writes == 7);
    assert(mock.write_addresses[6] == 0);
    assert(mock.write_values[6] == UINT8_C(0xFF));

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 2;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.fail_on_delay = 1;
    assert(
        !uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));
    assert(mock.reads == 2);
    assert(mock.writes == 3);
    assert(mock.delays == 1);

    assert(
        !uf_flash_service_probe_id(
            &service,
            UINT8_C(2),
            &id_result));
    assert(!uf_flash_service_probe_id(&service, 0, NULL));
    service.access.delay_us = NULL;
    assert(
        !uf_flash_service_probe_id(
            &service,
            UF_FLASH_ID_METHOD_STANDARD,
            &id_result));

    id_result.manufacturer_id = UINT8_C(0x01);
    id_result.device_id = UINT8_C(0x93);
    id_result.valid = true;
    assert(uf_flash_service_accept_id(&service, &id_result));
    assert(strcmp(service.manufacturer->name, "AMD") == 0);
    assert(strcmp(service.chip->name, "Am29LV065D/3V") == 0);
    assert(service.chip->capacity_bytes == UF_KIB(8192));
    assert(service.rom_base == UINT32_C(0xFF800000));
    assert(service.error == UF_FLASH_ERROR_NONE);

    id_result.manufacturer_id = UINT8_C(0x01);
    id_result.device_id = UINT8_C(0x00);
    id_result.valid = true;
    assert(!uf_flash_service_accept_id(&service, &id_result));
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(service.error == UF_FLASH_ERROR_UNKNOWN_CHIP);
    assert(service.rom_base == UINT32_C(0xFF800000));

    id_result.manufacturer_id = UINT8_C(0x01);
    id_result.device_id = UINT8_C(0xA1);
    id_result.valid = false;
    assert(!uf_flash_service_accept_id(&service, &id_result));
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(service.error == UF_FLASH_ERROR_UNKNOWN_CHIP);
    assert(!uf_flash_service_accept_id(&service, NULL));
    assert(!uf_flash_service_accept_id(NULL, &id_result));

    memset(&mock, 0, sizeof(mock));
    service.access.delay_us = mock_delay_us;
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x89);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0x94);
    assert(uf_flash_service_detect_current_window(&service));
    assert(strcmp(service.manufacturer->name, "Intel") == 0);
    assert(strcmp(service.chip->name, "28F001BX/BN-T/12V") == 0);
    assert(mock.read_script_index == 4);
    assert(mock.writes == 7);
    assert(mock.delays == 2);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 8;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0xFF);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0xFF);
    mock.read_addresses[4] = 0;
    mock.read_values[4] = UINT8_C(0xFF);
    mock.read_addresses[5] = 1;
    mock.read_values[5] = UINT8_C(0xFF);
    mock.read_addresses[6] = 0;
    mock.read_values[6] = UINT8_C(0x01);
    mock.read_addresses[7] = 1;
    mock.read_values[7] = UINT8_C(0xA1);
    assert(uf_flash_service_detect_current_window(&service));
    assert(strcmp(service.manufacturer->name, "AMD") == 0);
    assert(strcmp(service.chip->name, "Am28F256/12V") == 0);
    assert(service.rom_base == UINT32_C(0xFFFF8000));
    assert(mock.read_script_index == 8);
    assert(mock.writes == 11);
    assert(mock.delays == 4);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 2;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.fail_on_delay = 1;
    assert(!uf_flash_service_detect_current_window(&service));
    assert(service.manufacturer == NULL);
    assert(service.chip == NULL);
    assert(mock.read_script_index == 2);
    assert(mock.writes == 6);
    assert(mock.delays == 1);
    assert(!uf_flash_service_detect_current_window(NULL));

    memset(&mock, 0, sizeof(mock));
    service.rom_base = 0;
    script_index = 0;
    for (candidate_index = 0; candidate_index < 6; ++candidate_index)
    {
        mock.read_addresses[script_index] = 0;
        mock.read_values[script_index++] = UINT8_C(0xFF);
        mock.read_addresses[script_index] = 1;
        mock.read_values[script_index++] = UINT8_C(0xFF);
        mock.read_addresses[script_index] = 0;
        mock.read_values[script_index++] = UINT8_C(0xFF);
        mock.read_addresses[script_index] = 1;
        mock.read_values[script_index++] = UINT8_C(0xFF);
    }
    mock.read_addresses[script_index] = 0;
    mock.read_values[script_index++] = UINT8_C(0xFF);
    mock.read_addresses[script_index] = 1;
    mock.read_values[script_index++] = UINT8_C(0xFF);
    mock.read_addresses[script_index] = 0;
    mock.read_values[script_index++] = UINT8_C(0x01);
    mock.read_addresses[script_index] = 1;
    mock.read_values[script_index++] = UINT8_C(0xA1);
    mock.read_script_count = script_index;
    assert(uf_flash_service_detect(&service));
    assert(strcmp(service.manufacturer->name, "AMD") == 0);
    assert(strcmp(service.chip->name, "Am28F256/12V") == 0);
    assert(service.rom_base == UINT32_C(0xFFFF8000));
    assert(mock.read_script_index == 28);
    assert(mock.windows == 8);
    assert(mock.window_bases[0] == UINT32_C(0xFFFF8000));
    assert(mock.window_bases[1] == UINT32_C(0xFFFF0000));
    assert(mock.window_bases[2] == UINT32_C(0xFFFE0000));
    assert(mock.window_bases[3] == UINT32_C(0xFFFC0000));
    assert(mock.window_bases[4] == UINT32_C(0xFFF80000));
    assert(mock.window_bases[5] == UINT32_C(0xFFF00000));
    assert(mock.window_bases[6] == UINT32_C(0xFFFF8000));
    assert(mock.window_bases[7] == UINT32_C(0xFFFF8000));

    memset(&mock, 0, sizeof(mock));
    service.rom_base = UINT32_C(0xFFF80000);
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0xFF);
    mock.read_addresses[1] = 1;
    mock.read_values[1] = UINT8_C(0xFF);
    mock.read_addresses[2] = 0;
    mock.read_values[2] = UINT8_C(0x01);
    mock.read_addresses[3] = 1;
    mock.read_values[3] = UINT8_C(0xA4);
    assert(uf_flash_service_detect(&service));
    assert(strcmp(service.chip->name, "Am29F040(B)/5V") == 0);
    assert(service.rom_base == UINT32_C(0xFFF80000));
    assert(mock.windows == 2);
    assert(mock.window_bases[0] == UINT32_C(0xFFF80000));
    assert(mock.window_bases[1] == UINT32_C(0xFFF80000));

    memset(&mock, 0, sizeof(mock));
    service.rom_base = 0;
    mock.fail_on_window = 1;
    assert(!uf_flash_service_detect(&service));
    assert(mock.windows == 1);
    assert(mock.reads == 0);

    service.access.select_window = NULL;
    assert(!uf_flash_service_detect(&service));
    assert(!uf_flash_service_detect(NULL));

    memset(&algorithms, 0, sizeof(algorithms));
    assert(!uf_flash_algorithm_registry_is_valid(NULL));
    assert(uf_flash_algorithm_registry_is_valid(&algorithms));
    algorithms.program[UF_FLASH_PROGRAM_NONE] = mock_program;
    assert(!uf_flash_algorithm_registry_is_valid(&algorithms));
    algorithms.program[UF_FLASH_PROGRAM_NONE] = NULL;
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_algorithm_registry_is_valid(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;

    assert(!uf_flash_service_set_algorithms(NULL, &algorithms));
    assert(!uf_flash_service_set_algorithms(&service, NULL));
    assert(uf_flash_service_set_algorithms(&service, &algorithms));
    assert(uf_flash_service_select_chip(&service, 0x01, 0xA1));

    memset(&mock, 0, sizeof(mock));
    assert(
        !uf_flash_service_program(
            &service,
            UF_KIB(32) - UINT32_C(128),
            UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.programs == 0);

    algorithms.program[UF_FLASH_PROGRAM_AMD_FLASH] = mock_program;
    assert(
        uf_flash_service_program(
            &service,
            UF_KIB(32) - UINT32_C(128),
            UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.programs == 1);
    assert(mock.algorithm_position == UF_KIB(32) - UINT32_C(128));
    assert(mock.algorithm_source == UINT32_C(0x10000));

    assert(
        !uf_flash_service_program(
            &service,
            UF_KIB(32) - UINT32_C(127),
            UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.programs == 1);

    mock.fail_algorithm = true;
    assert(!uf_flash_service_program(&service, 0, UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.programs == 2);
    mock.fail_algorithm = false;

    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.erases == 0);
    algorithms.erase[UF_FLASH_ERASE_AMD_FLASH] = mock_erase;
    assert(uf_flash_service_erase(&service, UF_KIB(32) - 1));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.erases == 1);
    assert(mock.algorithm_position == UF_KIB(32) - 1);
    assert(!uf_flash_service_erase(&service, UF_KIB(32)));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.erases == 1);

    mock.fail_algorithm = true;
    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.erases == 2);
    mock.fail_algorithm = false;

    assert(uf_flash_service_select_chip(&service, 0x1F, 0xDC));
    assert(service.chip->erase_algorithm == UF_FLASH_ERASE_NONE);
    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(!uf_flash_service_program(NULL, 0, 0));
    assert(!uf_flash_service_erase(NULL, 0));

    memset(&algorithms, 0, sizeof(algorithms));
    assert(!uf_flash_register_amd_sector_erase(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_amd_sector_erase(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_amd_sector_erase(&algorithms));
    assert(
        algorithms.erase[UF_FLASH_ERASE_AMD_SECTOR] == uf_flash_erase_amd_sector);
    assert(uf_flash_service_set_algorithms(&service, &algorithms));
    assert(uf_flash_service_select_chip(&service, 0x01, 0x20));

    memset(&mock, 0, sizeof(mock));
    assert(uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 9);
    assert(mock.reads == 2);
    assert(mock.delays == 0);
    assert(mock.write_addresses[0] == UINT32_C(0x5555));
    assert(mock.write_values[0] == UINT8_C(0xAA));
    assert(mock.write_addresses[1] == UINT32_C(0x2AAA));
    assert(mock.write_values[1] == UINT8_C(0x55));
    assert(mock.write_addresses[2] == UINT32_C(0x5555));
    assert(mock.write_values[2] == UINT8_C(0x80));
    assert(mock.write_addresses[3] == UINT32_C(0x5555));
    assert(mock.write_values[3] == UINT8_C(0xAA));
    assert(mock.write_addresses[4] == UINT32_C(0x2AAA));
    assert(mock.write_values[4] == UINT8_C(0x55));
    assert(mock.write_addresses[5] == UINT32_C(0x1000));
    assert(mock.write_values[5] == UINT8_C(0x30));
    assert(mock.write_values[8] == UINT8_C(0xF0));

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 1;
    assert(!uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 1);
    assert(mock.reads == 0);

    memset(&mock, 0, sizeof(mock));
    mock.toggle_reads = true;
    assert(!uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 36);
    assert(mock.reads == UINT32_C(200004));
    assert(mock.delays == UINT32_C(100000));

    memset(&algorithms, 0, sizeof(algorithms));
    assert(!uf_flash_register_amd_bulk_erase(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_amd_bulk_erase(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_amd_bulk_erase(&algorithms));
    assert(
        algorithms.erase[UF_FLASH_ERASE_AMD_BULK] == uf_flash_erase_amd_bulk);
    assert(uf_flash_service_set_algorithms(&service, &algorithms));
    assert(uf_flash_service_select_chip(&service, 0x20, 0x24));

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 3;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x08);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x80);
    mock.read_addresses[2] = UINT32_C(0x1000);
    mock.read_values[2] = UINT8_C(0x80);
    assert(uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 9);
    assert(mock.reads == 3);
    assert(mock.delays == 0);
    assert(mock.write_values[2] == UINT8_C(0x80));
    assert(mock.write_values[5] == UINT8_C(0x10));
    assert(mock.write_values[8] == UINT8_C(0xF0));

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 4;
    assert(!uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 4);
    assert(mock.reads == 0);

    memset(&mock, 0, sizeof(mock));
    mock.zero_reads = true;
    assert(!uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 36);
    assert(mock.reads == UINT32_C(160064));
    assert(mock.delays == UINT32_C(160060));

    memset(&algorithms, 0, sizeof(algorithms));
    assert(!uf_flash_register_amd_embedded_erase(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_amd_embedded_erase(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_amd_embedded_erase(&algorithms));
    assert(
        algorithms.erase[UF_FLASH_ERASE_AMD_EMBEDDED] == uf_flash_erase_amd_embedded);
    assert(uf_flash_service_set_algorithms(&service, &algorithms));
    assert(uf_flash_service_select_chip(&service, 0x01, 0xA2));

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 1;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0x80);
    assert(uf_flash_service_erase(&service, UINT32_C(0x1000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 2);
    assert(mock.write_addresses[0] == 0);
    assert(mock.write_values[0] == UINT8_C(0x30));
    assert(mock.write_addresses[1] == 0);
    assert(mock.write_values[1] == UINT8_C(0x30));
    assert(mock.delays == 1);
    assert(mock.delay_values[0] == UINT32_C(1000));
    assert(mock.reads == 1);

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_write = 2;
    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 2);
    assert(mock.delays == 0);
    assert(mock.reads == 0);

    memset(&mock, 0, sizeof(mock));
    mock.fail_on_delay = 1;
    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 2);
    assert(mock.delays == 1);
    assert(mock.reads == 0);

    memset(&mock, 0, sizeof(mock));
    mock.zero_reads = true;
    assert(!uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_ERASE);
    assert(mock.writes == 2);
    assert(mock.delays == UINT32_C(25000));
    assert(mock.reads == UINT32_C(25000));

    memset(&algorithms, 0, sizeof(algorithms));
    assert(!uf_flash_register_generic_algorithms(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_generic_algorithms(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_generic_algorithms(&algorithms));
    assert(
        algorithms.program[UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE] == uf_flash_program_generic_page);
    assert(
        algorithms.program[UF_FLASH_PROGRAM_INTEL_SECTOR] == uf_flash_program_intel_sector);
    assert(algorithms.program[UF_FLASH_PROGRAM_INTEL_SECTOR_U] == NULL);
    assert(
        algorithms.program[UF_FLASH_PROGRAM_AMD_SECTOR] == uf_flash_program_amd_sector);
    assert(
        algorithms.program[UF_FLASH_PROGRAM_AMD_EMBEDDED] == uf_flash_program_amd_embedded);
    assert(
        algorithms.program[UF_FLASH_PROGRAM_AMD_FLASH] == uf_flash_program_amd_flash);
    assert(
        algorithms.erase[UF_FLASH_ERASE_INTEL_SECTOR] == uf_flash_erase_intel_sector);
    assert(algorithms.erase[UF_FLASH_ERASE_INTEL_SECTOR_U] == NULL);
    assert(
        algorithms.erase[UF_FLASH_ERASE_AMD_FLASH] == uf_flash_erase_amd_flash);
    assert(!uf_flash_register_intel_algorithms(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_intel_algorithms(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_intel_algorithms(&algorithms));
    assert(
        algorithms.program[UF_FLASH_PROGRAM_INTEL_SECTOR_U] == uf_flash_program_intel_sector_u);
    assert(
        algorithms.erase[UF_FLASH_ERASE_INTEL_SECTOR_U] == uf_flash_erase_intel_sector_protected_u);
    assert(uf_flash_service_set_algorithms(&service, &algorithms));

    assert(uf_flash_service_select_chip(&service, 0xBF, 0x01));
    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x10000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    assert(
        uf_flash_service_program(
            &service,
            0,
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.source_reads == 129);
    assert(mock.writes == 131);
    assert(mock.reads == 2);
    assert(mock.delays == 2);
    assert(mock.delay_values[0] == UINT32_C(5000));
    assert(mock.delay_values[1] == UINT32_C(50));

    assert(uf_flash_service_select_chip(&service, 0x89, 0x94));
    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x20000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.source_reads == 128);
    assert(mock.writes == 5);
    assert(mock.write_values[0] == UINT8_C(0x40));
    assert(mock.write_values[1] == UINT8_C(0x12));
    assert(mock.write_values[2] == UINT8_C(0x50));
    assert(mock.write_values[3] == UINT8_C(0xFF));
    assert(mock.write_values[4] == UINT8_C(0xFF));
    assert(mock.reads == 2);
    assert(mock.delays == 1);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x10000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x10000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(uf_flash_service_erase(&service, UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 5);
    assert(mock.write_values[0] == UINT8_C(0x20));
    assert(mock.write_values[1] == UINT8_C(0xD0));
    assert(mock.write_values[2] == UINT8_C(0x50));
    assert(mock.write_values[3] == UINT8_C(0xFF));
    assert(mock.write_values[4] == UINT8_C(0xFF));

    assert(uf_flash_service_select_chip(&service, 0x89, 0xAD));
    assert(
        uf_flash_intel_lock_address(&service, UINT32_C(0x10000)) == UINT32_C(0xFFB90002));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x28000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.lock_changes == 2);
    assert(mock.lock_states[0] == false);
    assert(mock.lock_states[1] == true);
    assert(mock.lock_addresses[0] == UINT32_C(0xFFB80002));
    assert(mock.lock_addresses[1] == UINT32_C(0xFFB80002));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x28000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.fail_on_write = 1;
    assert(
        !uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.lock_changes == 2);
    assert(mock.lock_states[0] == false);
    assert(mock.lock_states[1] == true);

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x28000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.fail_on_lock_change = 1;
    assert(
        !uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.lock_changes == 1);
    assert(mock.writes == 0);

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x10000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x10000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(uf_flash_service_erase(&service, UINT32_C(0x10000)));
    assert(mock.write_values[0] == UINT8_C(0x21));
    assert(mock.write_values[1] == UINT8_C(0xD0));
    assert(mock.lock_changes == 2);
    assert(mock.lock_states[0] == false);
    assert(mock.lock_states[1] == true);
    assert(mock.lock_addresses[0] == UINT32_C(0xFFB90002));
    assert(mock.lock_addresses[1] == UINT32_C(0xFFB90002));

    assert(uf_flash_service_select_chip(&service, 0x01, 0x20));
    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x30000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x80);
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.source_reads == 128);
    assert(mock.writes == 7);
    assert(mock.write_values[2] == UINT8_C(0xA0));
    assert(mock.write_values[3] == UINT8_C(0x80));
    assert(mock.write_values[6] == UINT8_C(0xF0));

    assert(uf_flash_service_select_chip(&service, 0x01, 0xA2));
    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x40000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x80);
    mock.read_script_count = 2;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x80);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.source_reads == 128);
    assert(mock.writes == 4);
    assert(mock.write_values[0] == UINT8_C(0x10));
    assert(mock.write_values[1] == UINT8_C(0x80));
    assert(mock.write_values[2] == UINT8_C(0xFF));
    assert(mock.write_values[3] == UINT8_C(0xFF));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x41000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 4;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x20);
    mock.read_addresses[1] = UINT32_C(0x1000);
    mock.read_values[1] = UINT8_C(0x20);
    mock.read_addresses[2] = UINT32_C(0x1000);
    mock.read_values[2] = UINT8_C(0x00);
    mock.read_addresses[3] = UINT32_C(0x1000);
    mock.read_values[3] = UINT8_C(0x00);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(mock.writes == 6);
    assert(mock.write_values[0] == UINT8_C(0x10));
    assert(mock.write_values[1] == UINT8_C(0x12));
    assert(mock.write_values[2] == UINT8_C(0x10));
    assert(mock.write_values[3] == UINT8_C(0x00));

    assert(uf_flash_service_select_chip(&service, 0x01, 0xA1));
    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x50000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 1;
    mock.read_addresses[0] = UINT32_C(0x1000);
    mock.read_values[0] = UINT8_C(0x12);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.source_reads == 128);
    assert(mock.writes == 5);
    assert(mock.write_values[0] == UINT8_C(0x40));
    assert(mock.write_values[1] == UINT8_C(0x12));
    assert(mock.write_values[2] == UINT8_C(0xC0));
    assert(mock.delay_values[0] == UINT32_C(10));
    assert(mock.delay_values[1] == UINT32_C(6));
    assert(mock.write_values[3] == UINT8_C(0xFF));
    assert(mock.write_values[4] == UINT8_C(0xFF));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x51000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 25;
    for (candidate_index = 0; candidate_index < 25; ++candidate_index)
    {
        mock.read_addresses[candidate_index] = UINT32_C(0x1000);
        mock.read_values[candidate_index] = candidate_index == 24
                                                ? UINT8_C(0x12)
                                                : UINT8_C(0x00);
    }
    assert(
        !uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.writes == 77);
    assert(mock.reads == 25);
    assert(mock.delays == 50);

    memset(&mock, 0, sizeof(mock));
    assert(uf_flash_service_erase(&service, 0));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == UINT32_C(32772));
    assert(mock.reads == UINT32_C(32768));
    assert(mock.delays == UINT32_C(32769));
    assert(mock.write_values[0] == UINT8_C(0x20));
    assert(mock.write_values[1] == UINT8_C(0x20));
    assert(mock.write_values[2] == UINT8_C(0xA0));
    assert(mock.last_write_address == 0);
    assert(mock.last_write_value == UINT8_C(0xFF));

    assert(!uf_flash_register_sharp_algorithms(NULL));
    algorithms.erase[UF_FLASH_ERASE_NONE] = mock_erase;
    assert(!uf_flash_register_sharp_algorithms(&algorithms));
    algorithms.erase[UF_FLASH_ERASE_NONE] = NULL;
    assert(uf_flash_register_sharp_algorithms(&algorithms));
    assert(
        algorithms.program[UF_FLASH_PROGRAM_SHARP_SECTOR] == uf_flash_program_sharp_sector);
    assert(
        algorithms.erase[UF_FLASH_ERASE_SHARP_SECTOR] == uf_flash_erase_sharp_sector);
    assert(uf_flash_service_select_chip(&service, 0xB0, 0xC9));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x60000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 5;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x1F0000);
    mock.read_values[1] = UINT8_C(0x80);
    mock.read_addresses[2] = UINT32_C(0x0F0000);
    mock.read_values[2] = UINT8_C(0x80);
    mock.read_addresses[3] = UINT32_C(0x0F0000);
    mock.read_values[3] = UINT8_C(0x80);
    mock.read_addresses[4] = 0;
    mock.read_values[4] = UINT8_C(0x80);
    assert(
        uf_flash_service_program(
            &service,
            UINT32_C(0x0F0000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 11);
    assert(mock.write_values[0] == UINT8_C(0x60));
    assert(mock.write_values[1] == UINT8_C(0xDB));
    assert(mock.write_addresses[3] == UINT32_C(0x1F0000));
    assert(mock.write_values[3] == UINT8_C(0xD0));
    assert(mock.write_values[9] == UINT8_C(0x60));
    assert(mock.write_values[10] == UINT8_C(0xBB));
    assert(mock.read_script_index == 5);
    assert(mock.delays == 2);
    assert(mock.delay_values[0] == UINT32_C(1000));
    assert(mock.delay_values[1] == UINT32_C(10));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x60000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 1;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0x80);
    mock.sharp_top_busy_reads = UINT32_C(6000);
    mock.use_default_read_value = true;
    mock.default_read_value = UINT8_C(0x80);
    assert(
        !uf_flash_service_program(
            &service,
            UINT32_C(0x0F0000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.sharp_top_busy_reads == 0);
    assert(mock.reads == UINT32_C(6004));
    assert(mock.delays == UINT32_C(6001));
    assert(mock.write_values[9] == UINT8_C(0x60));
    assert(mock.write_values[10] == UINT8_C(0xBB));

    memset(&mock, 0, sizeof(mock));
    mock.read_script_count = 4;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0x80);
    mock.read_addresses[1] = UINT32_C(0x10000);
    mock.read_values[1] = UINT8_C(0x80);
    mock.read_addresses[2] = UINT32_C(0x10000);
    mock.read_values[2] = UINT8_C(0x80);
    mock.read_addresses[3] = 0;
    mock.read_values[3] = UINT8_C(0x80);
    assert(uf_flash_service_erase(&service, UINT32_C(0x10000)));
    assert(service.error == UF_FLASH_ERROR_NONE);
    assert(mock.writes == 9);
    assert(mock.write_values[0] == UINT8_C(0x60));
    assert(mock.write_values[1] == UINT8_C(0xDB));
    assert(mock.write_values[2] == UINT8_C(0x20));
    assert(mock.write_values[3] == UINT8_C(0xD0));
    assert(mock.write_values[7] == UINT8_C(0x60));
    assert(mock.write_values[8] == UINT8_C(0xBB));

    memset(&mock, 0, sizeof(mock));
    mock.source_base = UINT32_C(0x60000);
    mock.source_size = 128;
    memset(mock.source_values, 0xFF, mock.source_size);
    mock.source_values[0] = UINT8_C(0x12);
    mock.read_script_count = 1;
    mock.read_addresses[0] = 0;
    mock.read_values[0] = UINT8_C(0x80);
    mock.fail_on_write = 3;
    assert(
        !uf_flash_service_program(
            &service,
            UINT32_C(0x1000),
            mock.source_base));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);
    assert(mock.writes == 5);
    assert(mock.write_values[3] == UINT8_C(0x60));
    assert(mock.write_values[4] == UINT8_C(0xBB));

    service.access.read_source_byte = NULL;
    assert(
        !uf_flash_service_program(
            &service,
            0,
            UINT32_C(0x50000)));
    assert(service.error == UF_FLASH_ERROR_PROGRAM);

    assert(uf_flash_service_command(NULL, UINT8_C(0x90)) == false);
    assert(uf_flash_service_init(NULL, &access, 0) == false);
    assert(uf_flash_service_init(&service, NULL, 0) == false);
    return 0;
}
