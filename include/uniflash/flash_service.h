#ifndef UNIFLASH_FLASH_SERVICE_H
#define UNIFLASH_FLASH_SERVICE_H

#include "uniflash/rom_database.h"

/*
 * These values preserve the public FlashError meanings used by the Pascal
 * application. Hardware backends may add more detailed diagnostics later,
 * but callers can continue to rely on these compatibility codes.
 */
typedef uint16_t uf_flash_error_t;

enum { UF_FLASH_ERROR_NONE = 0, UF_FLASH_ERROR_UNKNOWN_CHIP = 1, UF_FLASH_ERROR_PROGRAM = 2, UF_FLASH_ERROR_ERASE = 3 };

/*
 * FLASH.PAS selected these operations through global procedure variables.
 * The C port injects them explicitly so detection and algorithms can be
 * tested without granting host tests access to physical memory or I/O ports.
 *
 * Addresses are offsets within the selected ROM window. Buffer sizes use
 * uint32_t because size_t is only 16 bits in the DOS/16 huge memory model.
 */
typedef bool (*uf_flash_read_byte_fn)(void *context, uf_rom_offset_t address, uint8_t *value);
typedef bool (*uf_flash_write_byte_fn)(void *context, uf_rom_offset_t address, uint8_t value);
typedef bool (
    *uf_flash_read_block_fn)(void *context, uf_rom_offset_t flash_address, void *destination, uf_rom_size_t size_bytes);
typedef bool (*uf_flash_write_block_fn)(void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes);
typedef bool (*uf_flash_compare_block_fn)(void *context,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    bool *equal);
typedef bool (*uf_flash_delay_us_fn)(void *context, uint32_t microseconds);
typedef bool (*uf_flash_select_window_fn)(void *context, uf_phys_addr_t rom_base);
typedef bool (*uf_flash_read_source_byte_fn)(void *context, uf_phys_addr_t source_address, uint8_t *value);
typedef bool (*uf_flash_set_write_lock_fn)(void *context, uf_phys_addr_t lock_register_address, bool locked);
typedef bool (*uf_flash_update_phys_byte_fn)(void *context, uf_phys_addr_t address, uint8_t and_mask, uint8_t or_mask);

typedef struct uf_flash_access {
    void *context;
    uf_flash_read_byte_fn read_byte;
    uf_flash_write_byte_fn write_byte;
    uf_flash_read_block_fn read_block;
    uf_flash_write_block_fn write_block;
    uf_flash_compare_block_fn compare_block;
    uf_flash_delay_us_fn delay_us;
    uf_flash_select_window_fn select_window;
    uf_flash_read_source_byte_fn read_source_byte;
    uf_flash_set_write_lock_fn set_write_lock;
    uf_flash_update_phys_byte_fn update_phys_byte;
} uf_flash_access_t;

struct uf_flash_service;

typedef bool (
    *uf_flash_program_fn)(struct uf_flash_service *service, uf_rom_offset_t position, uf_phys_addr_t source_address);
typedef bool (*uf_flash_erase_fn)(struct uf_flash_service *service, uf_rom_offset_t sector_address);

typedef struct uf_flash_algorithm_registry {
    uf_flash_program_fn program[UF_FLASH_PROGRAM_COUNT];
    uf_flash_erase_fn erase[UF_FLASH_ERASE_COUNT];
} uf_flash_algorithm_registry_t;

typedef struct uf_flash_service {
    uf_flash_access_t access;
    const uf_flash_algorithm_registry_t *algorithms;
    uf_phys_addr_t rom_base;
    const uf_flash_manufacturer_t *manufacturer;
    const uf_flash_chip_t *chip;
    uf_flash_error_t error;
    uint8_t manufacturer_id;
    uint8_t device_id;
} uf_flash_service_t;

enum {
    UF_FLASH_COMMAND_ADDRESS_1 = 0x5555,
    UF_FLASH_COMMAND_ADDRESS_2 = 0x2AAA,
    UF_FLASH_COMMAND_UNLOCK_1 = 0xAA,
    UF_FLASH_COMMAND_UNLOCK_2 = 0x55
};

typedef uint8_t uf_flash_id_method_t;

enum { UF_FLASH_ID_METHOD_LEGACY = 0, UF_FLASH_ID_METHOD_STANDARD = 1 };

typedef struct uf_flash_id_result {
    uint8_t initial_manufacturer_id;
    uint8_t initial_device_id;
    uint8_t manufacturer_id;
    uint8_t device_id;
    bool valid;
} uf_flash_id_result_t;

bool uf_flash_access_is_valid(const uf_flash_access_t *access);
bool uf_flash_algorithm_registry_is_valid(const uf_flash_algorithm_registry_t *registry);
bool uf_flash_service_init(uf_flash_service_t *service, const uf_flash_access_t *access, uf_phys_addr_t rom_base);
bool uf_flash_service_set_algorithms(uf_flash_service_t *service, const uf_flash_algorithm_registry_t *registry);
bool uf_flash_service_select_chip(uf_flash_service_t *service, uint8_t manufacturer_id, uint8_t device_id);
void uf_flash_service_clear_selection(uf_flash_service_t *service);
bool uf_flash_service_range_is_valid(const uf_flash_service_t *service,
    uf_rom_offset_t address,
    uf_rom_size_t size_bytes);
bool uf_flash_service_read_byte(uf_flash_service_t *service, uf_rom_offset_t address, uint8_t *value);
bool uf_flash_service_write_byte(uf_flash_service_t *service, uf_rom_offset_t address, uint8_t value);
bool uf_flash_service_read_block(uf_flash_service_t *service,
    uf_rom_offset_t flash_address,
    void *destination,
    uf_rom_size_t size_bytes);
bool uf_flash_service_write_block(uf_flash_service_t *service,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes);
bool uf_flash_service_compare_block(uf_flash_service_t *service,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    bool *equal);
bool uf_flash_service_command(uf_flash_service_t *service, uint8_t command);
bool uf_flash_id_has_odd_parity(uint8_t manufacturer_id);
bool uf_flash_service_probe_id(uf_flash_service_t *service, uf_flash_id_method_t method, uf_flash_id_result_t *result);
bool uf_flash_service_accept_id(uf_flash_service_t *service, const uf_flash_id_result_t *result);
bool uf_flash_service_detect_current_window(uf_flash_service_t *service);
bool uf_flash_service_detect(uf_flash_service_t *service);
bool uf_flash_service_program(uf_flash_service_t *service, uf_rom_offset_t position, uf_phys_addr_t source_address);
bool uf_flash_service_erase(uf_flash_service_t *service, uf_rom_offset_t sector_address);

UF_STATIC_ASSERT(flash_error_is_2_bytes, sizeof(uf_flash_error_t) == 2);
UF_STATIC_ASSERT(flash_access_block_size_is_4_bytes, sizeof(uf_rom_size_t) == 4);

#endif
