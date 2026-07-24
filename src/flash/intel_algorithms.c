#include "uniflash/intel_algorithms.h"

uf_phys_addr_t uf_flash_intel_lock_address(const struct uf_flash_service *service, uf_rom_offset_t operation_address) {
    if (service == NULL || service->chip == NULL) {
        return 0;
    }
    return (operation_address & UINT32_C(0xFFFF0000)) + UINT32_C(0xFFC00002) - service->chip->capacity_bytes;
}

static bool set_write_lock(struct uf_flash_service *service, uf_rom_offset_t operation_address, bool locked) {
    if (service->access.set_write_lock == NULL) {
        return false;
    }
    return service->access.set_write_lock(service->access.context,
        uf_flash_intel_lock_address(service, operation_address),
        locked);
}

bool uf_flash_program_intel_sector_u(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    uf_flash_error_t operation_error;
    bool result;

    if (service == NULL || service->chip == NULL || !set_write_lock(service, position, false)) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    result = uf_flash_program_intel_sector(service, position, source_address);
    operation_error = service->error;
    if (!set_write_lock(service, position, true)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    service->error = operation_error;
    return result;
}

bool uf_flash_erase_intel_sector_protected_u(struct uf_flash_service *service, uf_rom_offset_t sector_address) {
    uf_flash_error_t operation_error;
    bool result;

    if (service == NULL || service->chip == NULL || !set_write_lock(service, sector_address, false)) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    result = uf_flash_erase_intel_sector_u(service, sector_address);
    operation_error = service->error;
    if (!set_write_lock(service, sector_address, true)) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = operation_error;
    return result;
}

bool uf_flash_register_intel_algorithms(uf_flash_algorithm_registry_t *registry) {
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return false;
    }
    registry->program[UF_FLASH_PROGRAM_INTEL_SECTOR_U] = uf_flash_program_intel_sector_u;
    registry->erase[UF_FLASH_ERASE_INTEL_SECTOR_U] = uf_flash_erase_intel_sector_protected_u;
    return true;
}
