#include "uniflash/sst_algorithms.h"

static uf_bool_t source_byte(
    struct uf_flash_service *service,
    uf_phys_addr_t address,
    uint8_t *value
)
{
    return (
        service->access.read_source_byte != NULL
        && service->access.read_source_byte(
            service->access.context,
            address,
            value
        )
    ) ? UF_TRUE : UF_FALSE;
}

static uf_bool_t protection_sequence(
    struct uf_flash_service *service,
    uf_bool_t protect
)
{
    static const uf_rom_offset_t prefix[] = {
        UINT32_C(0x1823), UINT32_C(0x1820), UINT32_C(0x1822),
        UINT32_C(0x0418), UINT32_C(0x041B), UINT32_C(0x0419)
    };
    uint8_t ignored;
    uint8_t index;

    for (index = 0; index < sizeof(prefix) / sizeof(prefix[0]); ++index) {
        if (!uf_flash_service_read_byte(service, prefix[index], &ignored)) {
            return UF_FALSE;
        }
    }
    return uf_flash_service_read_byte(
        service,
        protect ? UINT32_C(0x040A) : UINT32_C(0x041A),
        &ignored
    );
}

static uf_bool_t program_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    uint16_t offset;
    uint16_t timeout = UINT16_C(500);
    uint8_t status = 0;
    uf_bool_t ok = UF_FALSE;

    if (
        service == NULL
        || service->chip == NULL
        || service->access.delay_us == NULL
        || service->access.read_source_byte == NULL
        || !protection_sequence(service, UF_FALSE)
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    if (
        !uf_flash_service_write_byte(service, 0, UINT8_C(0x20))
        || !uf_flash_service_write_byte(
            service,
            position,
            UINT8_C(0xD0)
        )
    ) {
        service->error = UF_FLASH_ERROR_ERASE;
        goto restore;
    }
    do {
        if (
            !uf_flash_service_read_byte(
                service,
                position + UINT32_C(127),
                &status
            )
            || !service->access.delay_us(
                service->access.context,
                UINT32_C(100)
            )
        ) {
            service->error = UF_FLASH_ERROR_ERASE;
            goto restore;
        }
        --timeout;
    } while ((status & UINT8_C(0xA0)) == 0 && timeout > 0);
    if ((status & UINT8_C(0xA0)) != UINT8_C(0x80)) {
        service->error = UF_FLASH_ERROR_ERASE;
        (void)uf_flash_service_write_byte(service, 0, UINT8_C(0xFF));
        goto restore;
    }
    for (offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        if (
            !uf_flash_service_read_byte(
                service,
                position + offset,
                &status
            )
            || status != UINT8_C(0xFF)
        ) {
            service->error = UF_FLASH_ERROR_ERASE;
            (void)uf_flash_service_write_byte(service, 0, UINT8_C(0xFF));
            goto restore;
        }
    }
    for (offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        uint8_t value;
        uint8_t attempt;

        if (!source_byte(service, source_address + offset, &value)) {
            service->error = UF_FLASH_ERROR_PROGRAM;
            goto restore;
        }
        for (attempt = 0; attempt < 4; ++attempt) {
            uint16_t program_timeout = UINT16_C(60);
            uint8_t expected = value & UINT8_C(0x80);

            if (
                !uf_flash_service_write_byte(
                    service,
                    0,
                    UINT8_C(0x10)
                )
                || !uf_flash_service_write_byte(
                    service,
                    position + offset,
                    value
                )
            ) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                goto restore;
            }
            do {
                if (
                    !uf_flash_service_read_byte(
                        service,
                        position + offset,
                        &status
                    )
                    || !service->access.delay_us(
                        service->access.context,
                        UINT32_C(1)
                    )
                ) {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    goto restore;
                }
                --program_timeout;
            } while (
                (status & UINT8_C(0x80)) != expected
                && (status & UINT8_C(0x20)) == 0
                && program_timeout > 0
            );
            if (
                !uf_flash_service_read_byte(
                    service,
                    position + offset,
                    &status
                )
            ) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                goto restore;
            }
            /*
             * SST.PAS tests loop index X instead of status Y here. That
             * makes valid data fail depending on its address. Use Y, which
             * is the evident intended program-status test.
             */
            if ((status & UINT8_C(0xA0)) == expected) {
                break;
            }
        }
        if (attempt == 4) {
            service->error = UF_FLASH_ERROR_PROGRAM;
            (void)uf_flash_service_write_byte(service, 0, UINT8_C(0xFF));
            goto restore;
        }
    }
    service->error = UF_FLASH_ERROR_NONE;
    ok = UF_TRUE;

restore:
    if (!protection_sequence(service, UF_TRUE)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return UF_FALSE;
    }
    return ok;
}

static uf_bool_t erase_sector_20(
    struct uf_flash_service *service,
    uf_rom_offset_t position
)
{
    uint8_t attempt;
    uint8_t status = 0;

    for (attempt = 0; attempt < 4; ++attempt) {
        uint16_t timeout = UINT16_C(15);

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
                position,
                UINT8_C(0x20)
            )
        ) {
            return UF_FALSE;
        }
        while (timeout > 0) {
            if (!uf_flash_service_read_byte(service, position, &status)) {
                return UF_FALSE;
            }
            if ((status & UINT8_C(0x08)) != 0) {
                break;
            }
            --timeout;
            if (
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(10)
                )
            ) {
                return UF_FALSE;
            }
        }
        timeout = UINT16_C(50);
        while (timeout > 0) {
            if (!uf_flash_service_read_byte(service, position, &status)) {
                return UF_FALSE;
            }
            if ((status & UINT8_C(0xA0)) != 0) {
                break;
            }
            --timeout;
            if (
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(1000)
                )
            ) {
                return UF_FALSE;
            }
        }
        if (
            !uf_flash_service_read_byte(service, position, &status)
            || !uf_flash_service_command(service, UINT8_C(0xF0))
        ) {
            return UF_FALSE;
        }
        if ((status & UINT8_C(0x80)) != 0) {
            return UF_TRUE;
        }
    }
    return UF_FALSE;
}

static uf_bool_t program_sector2(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    uf_bool_t erase_ok;

    if (
        service == NULL
        || service->chip == NULL
        || service->access.delay_us == NULL
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    erase_ok = erase_sector_20(service, position);
    if (!erase_ok) {
        service->error = UF_FLASH_ERROR_ERASE;
    }
    /*
     * The Pascal routine proceeds with programming after a failed erase.
     * Retain that ordering, while still returning the earlier erase error.
     */
    if (!uf_flash_program_amd_sector(service, position, source_address)) {
        return UF_FALSE;
    }
    if (!erase_ok) {
        service->error = UF_FLASH_ERROR_ERASE;
        return UF_FALSE;
    }
    return UF_TRUE;
}

static uf_bool_t protected_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    uf_bool_t fwh2
)
{
    uf_phys_addr_t lock;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    lock = fwh2
        ? uf_flash_fwh_32k_lock_address(service, position)
        : uf_flash_fwh_64k_lock_address(service, position);
    return uf_flash_run_protected_program(
        service,
        position,
        source_address,
        &lock,
        UINT8_C(1),
        UINT8_C(0xFC),
        uf_flash_program_amd_sector
    );
}

static uf_bool_t protected_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t address,
    uf_bool_t fwh2
)
{
    uf_phys_addr_t lock;

    if (service == NULL || service->chip == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }
    lock = fwh2
        ? uf_flash_fwh_32k_lock_address(service, address)
        : uf_flash_fwh_64k_lock_address(service, address);
    return uf_flash_run_protected_erase(
        service,
        address,
        &lock,
        UINT8_C(1),
        UINT8_C(0xFC),
        uf_flash_erase_amd_sector
    );
}

#define DEFINE_SST_FWH(suffix, is_fwh2) \
static uf_bool_t program_fwh##suffix( \
    struct uf_flash_service *service, \
    uf_rom_offset_t position, \
    uf_phys_addr_t source_address \
) \
{ \
    return protected_program( \
        service, position, source_address, is_fwh2 \
    ); \
} \
static uf_bool_t erase_fwh##suffix( \
    struct uf_flash_service *service, \
    uf_rom_offset_t address \
) \
{ \
    return protected_erase(service, address, is_fwh2); \
}

DEFINE_SST_FWH(1, UF_FALSE)
DEFINE_SST_FWH(2, UF_TRUE)

uf_bool_t uf_flash_register_sst_algorithms(
    uf_flash_algorithm_registry_t *registry
)
{
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return UF_FALSE;
    }
    registry->program[UF_FLASH_PROGRAM_SST_SECTOR] = program_sector;
    registry->program[UF_FLASH_PROGRAM_SST_SECTOR2] = program_sector2;
    registry->program[UF_FLASH_PROGRAM_SST_FWH] = program_fwh1;
    registry->program[UF_FLASH_PROGRAM_SST_FWH2] = program_fwh2;
    registry->erase[UF_FLASH_ERASE_SST_FWH] = erase_fwh1;
    registry->erase[UF_FLASH_ERASE_SST_FWH2] = erase_fwh2;
    return UF_TRUE;
}
