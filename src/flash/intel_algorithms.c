#include "uniflash/intel_algorithms.h"

uf_phys_addr_t uf_flash_intel_lock_address(
    const struct uf_flash_service *service,
    uf_rom_offset_t operation_address
)
{
    if (service == NULL || service->chip == NULL) {
        return 0;
    }
    return (
        operation_address & UINT32_C(0xFFFF0000)
    ) + UINT32_C(0xFFC00002) - service->chip->capacity_bytes;
}

static uf_bool_t set_write_lock(
    struct uf_flash_service *service,
    uf_rom_offset_t operation_address,
    uf_bool_t locked
)
{
    if (service->access.set_write_lock == NULL) {
        return UF_FALSE;
    }
    return service->access.set_write_lock(
        service->access.context,
        uf_flash_intel_lock_address(service, operation_address),
        locked
    );
}

uf_bool_t uf_flash_program_intel_sector_u(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    uf_flash_error_t operation_error;
    uf_bool_t result;

    if (
        service == NULL
        || service->chip == NULL
        || !set_write_lock(service, position, UF_FALSE)
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }

    result = uf_flash_program_intel_sector(
        service,
        position,
        source_address
    );
    operation_error = service->error;
    if (!set_write_lock(service, position, UF_TRUE)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return UF_FALSE;
    }
    service->error = operation_error;
    return result;
}

uf_bool_t uf_flash_erase_intel_sector_protected_u(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
)
{
    uf_flash_error_t operation_error;
    uf_bool_t result;

    if (
        service == NULL
        || service->chip == NULL
        || !set_write_lock(service, sector_address, UF_FALSE)
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }

    result = uf_flash_erase_intel_sector_u(service, sector_address);
    operation_error = service->error;
    if (!set_write_lock(service, sector_address, UF_TRUE)) {
        service->error = UF_FLASH_ERROR_ERASE;
        return UF_FALSE;
    }
    service->error = operation_error;
    return result;
}

uf_bool_t uf_flash_register_intel_algorithms(
    uf_flash_algorithm_registry_t *registry
)
{
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return UF_FALSE;
    }
    registry->program[UF_FLASH_PROGRAM_INTEL_SECTOR_U] =
        uf_flash_program_intel_sector_u;
    registry->erase[UF_FLASH_ERASE_INTEL_SECTOR_U] =
        uf_flash_erase_intel_sector_protected_u;
    return UF_TRUE;
}
