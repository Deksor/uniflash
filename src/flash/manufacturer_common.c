#include "uniflash/manufacturer_common.h"

uf_phys_addr_t uf_flash_fwh_64k_lock_address(const struct uf_flash_service *service,
    uf_rom_offset_t operation_address) {
    return (operation_address & UINT32_C(0xFFFF0000)) + UINT32_C(0xFFC00002) - service->chip->capacity_bytes;
}

uf_phys_addr_t uf_flash_fwh_32k_lock_address(const struct uf_flash_service *service,
    uf_rom_offset_t operation_address) {
    uf_rom_offset_t adjusted = operation_address;

    if (operation_address >= UINT32_C(0x38000) && operation_address < UINT32_C(0x3C000)) {
        adjusted -= UINT32_C(0x4000);
    }
    return (adjusted & UINT32_C(0xFFFF8000)) + UINT32_C(0xFFC00002) - service->chip->capacity_bytes;
}

bool uf_flash_update_phys_byte(struct uf_flash_service *service,
    uf_phys_addr_t address,
    uint8_t and_mask,
    uint8_t or_mask) {
    if (service == NULL || service->access.update_phys_byte == NULL) {
        return false;
    }
    return service->access.update_phys_byte(service->access.context, address, and_mask, or_mask);
}

static bool update_locks(struct uf_flash_service *service,
    const uf_phys_addr_t *addresses,
    uint8_t count,
    uint8_t and_mask,
    uint8_t or_mask) {
    for (uint8_t index = 0; index < count; ++index) {
        if (!uf_flash_update_phys_byte(service, addresses[index], and_mask, or_mask)) {
            return false;
        }
    }
    return true;
}

bool uf_flash_run_protected_program(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    const uf_phys_addr_t *lock_addresses,
    uint8_t lock_count,
    uint8_t unlock_mask,
    uf_flash_inner_program_fn operation) {
    bool operation_ok;
    uf_flash_error_t operation_error;

    if (service == NULL || service->chip == NULL || operation == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    if (!update_locks(service, lock_addresses, lock_count, unlock_mask, UINT8_C(0))) {
        (void)update_locks(service, lock_addresses, lock_count, UINT8_C(0xFF), UINT8_C(0x01));
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    operation_ok = operation(service, position, source_address);
    operation_error = service->error;
    if (!update_locks(service, lock_addresses, lock_count, UINT8_C(0xFF), UINT8_C(0x01))) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    service->error = operation_error;
    return operation_ok;
}

bool uf_flash_run_protected_erase(struct uf_flash_service *service,
    uf_rom_offset_t sector_address,
    const uf_phys_addr_t *lock_addresses,
    uint8_t lock_count,
    uint8_t unlock_mask,
    uf_flash_inner_erase_fn operation) {
    bool operation_ok;
    uf_flash_error_t operation_error;

    if (service == NULL || service->chip == NULL || operation == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    if (!update_locks(service, lock_addresses, lock_count, unlock_mask, UINT8_C(0))) {
        (void)update_locks(service, lock_addresses, lock_count, UINT8_C(0xFF), UINT8_C(0x01));
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    operation_ok = operation(service, sector_address);
    operation_error = service->error;
    if (!update_locks(service, lock_addresses, lock_count, UINT8_C(0xFF), UINT8_C(0x01))) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = operation_error;
    return operation_ok;
}
