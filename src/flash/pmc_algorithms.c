#include "uniflash/pmc_algorithms.h"

static uf_bool_t pmc_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    uf_bool_t use_32k_lock
)
{
    uf_phys_addr_t lock_address;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    lock_address = use_32k_lock
        ? uf_flash_fwh_32k_lock_address(service, position)
        : uf_flash_fwh_64k_lock_address(service, position);
    return uf_flash_run_protected_program(
        service,
        position,
        source_address,
        &lock_address,
        UINT8_C(1),
        UINT8_C(0xFC),
        uf_flash_program_amd_sector
    );
}

static uf_bool_t pmc_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address,
    uf_bool_t use_32k_lock
)
{
    uf_phys_addr_t lock_address;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }
    lock_address = use_32k_lock
        ? uf_flash_fwh_32k_lock_address(service, sector_address)
        : uf_flash_fwh_64k_lock_address(service, sector_address);
    return uf_flash_run_protected_erase(
        service,
        sector_address,
        &lock_address,
        UINT8_C(1),
        UINT8_C(0xFC),
        uf_flash_erase_amd_sector
    );
}

static uf_bool_t program_fwh(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    return pmc_program(service, position, source_address, UF_FALSE);
}

static uf_bool_t program_fwh2(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    return pmc_program(service, position, source_address, UF_TRUE);
}

static uf_bool_t erase_fwh(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
)
{
    return pmc_erase(service, sector_address, UF_FALSE);
}

static uf_bool_t erase_fwh2(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
)
{
    return pmc_erase(service, sector_address, UF_TRUE);
}

uf_bool_t uf_flash_register_pmc_algorithms(
    uf_flash_algorithm_registry_t *registry
)
{
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return UF_FALSE;
    }
    registry->program[UF_FLASH_PROGRAM_PMC_FWH] = program_fwh;
    registry->program[UF_FLASH_PROGRAM_PMC_FWH2] = program_fwh2;
    registry->erase[UF_FLASH_ERASE_PMC_FWH] = erase_fwh;
    registry->erase[UF_FLASH_ERASE_PMC_FWH2] = erase_fwh2;
    return UF_TRUE;
}
