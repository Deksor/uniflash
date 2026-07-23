#include "uniflash/winbond_algorithms.h"

uf_bool_t uf_flash_erase_winbond_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
)
{
    uint8_t attempt;

    if (
        service == NULL
        || service->chip == NULL
        || service->access.delay_us == NULL
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }

    for (attempt = 0; attempt < 4; ++attempt) {
        uint16_t timeout = UINT16_C(25000);
        uint8_t previous;
        uint8_t current;

        if (
            !uf_flash_service_command(service, UINT8_C(0x80))
            || !uf_flash_service_write_byte(
                service,
                UF_FLASH_COMMAND_ADDRESS_1,
                UF_FLASH_COMMAND_UNLOCK_1
            )
            || !uf_flash_service_write_byte(
                service,
                UF_FLASH_COMMAND_ADDRESS_2,
                UF_FLASH_COMMAND_UNLOCK_2
            )
            || !uf_flash_service_write_byte(
                service,
                sector_address,
                UINT8_C(0x50)
            )
            || !uf_flash_service_read_byte(
                service,
                sector_address,
                &previous
            )
        ) {
            service->error = UF_FLASH_ERROR_ERASE;
            return UF_FALSE;
        }

        while (timeout > 0) {
            if (
                !uf_flash_service_read_byte(
                    service,
                    sector_address,
                    &current
                )
            ) {
                service->error = UF_FLASH_ERROR_ERASE;
                return UF_FALSE;
            }
            if (
                (previous & UINT8_C(0x40))
                == (current & UINT8_C(0x40))
            ) {
                break;
            }
            previous = current;
            --timeout;
            if (
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(1000)
                )
            ) {
                service->error = UF_FLASH_ERROR_ERASE;
                return UF_FALSE;
            }
        }
        if (!uf_flash_service_command(service, UINT8_C(0xF0))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return UF_FALSE;
        }
        /*
         * WINBOND.PAS inverted this test and reported an error on success.
         * Treat a stopped toggle before timeout as the intended success.
         */
        if (timeout > 0) {
            service->error = UF_FLASH_ERROR_NONE;
            return UF_TRUE;
        }
    }
    service->error = UF_FLASH_ERROR_ERASE;
    return UF_FALSE;
}

static uf_bool_t program_fwh(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    uf_phys_addr_t lock_address;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    lock_address = uf_flash_fwh_64k_lock_address(service, position);
    return uf_flash_run_protected_program(
        service,
        position,
        source_address,
        &lock_address,
        UINT8_C(1),
        UINT8_C(0xF8),
        uf_flash_program_amd_sector
    );
}

static uf_bool_t erase_fwh(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address
)
{
    uf_phys_addr_t lock_address;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }
    lock_address = uf_flash_fwh_64k_lock_address(
        service,
        sector_address
    );
    return uf_flash_run_protected_erase(
        service,
        sector_address,
        &lock_address,
        UINT8_C(1),
        UINT8_C(0xF8),
        uf_flash_erase_winbond_sector
    );
}

uf_bool_t uf_flash_register_winbond_algorithms(
    uf_flash_algorithm_registry_t *registry
)
{
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return UF_FALSE;
    }
    registry->program[UF_FLASH_PROGRAM_WINBOND_FWH] = program_fwh;
    registry->erase[UF_FLASH_ERASE_WINBOND_SECTOR] =
        uf_flash_erase_winbond_sector;
    registry->erase[UF_FLASH_ERASE_WINBOND_FWH] = erase_fwh;
    return UF_TRUE;
}
