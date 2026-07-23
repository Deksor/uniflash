#include "uniflash/macronix_algorithms.h"

static bool source_byte(
    struct uf_flash_service *service,
    uf_phys_addr_t address,
    uint8_t *value)
{
    return (
               service->access.read_source_byte != NULL && service->access.read_source_byte(
                                                               service->access.context,
                                                               address,
                                                               value))
               ? true
               : false;
}

static bool write_source_page(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    uint16_t offset;

    for (offset = 0; offset < service->chip->page_size_bytes; ++offset)
    {
        uint8_t value;

        if (
            !source_byte(service, source_address + offset, &value) || !uf_flash_service_write_byte(
                                                                          service,
                                                                          position + offset,
                                                                          value))
        {
            return false;
        }
    }
    return true;
}

static bool reset_macronix(
    struct uf_flash_service *service,
    uf_flash_error_t error)
{
    if (
        !uf_flash_service_write_byte(service, 0, UINT8_C(0xFF)) || !uf_flash_service_write_byte(service, 0, UINT8_C(0xFF)) || !uf_flash_service_command(service, UINT8_C(0)))
    {
        service->error = error;
        return false;
    }
    return true;
}

static bool program_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    uint16_t offset;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL || service->access.read_source_byte == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    for (offset = 0; offset < service->chip->page_size_bytes; ++offset)
    {
        uint8_t value;
        uint8_t attempt;
        uint8_t status = 0;

        if (!source_byte(service, source_address + offset, &value))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        for (attempt = 0; attempt < 4; ++attempt)
        {
            uint8_t timeout = UINT8_C(40);

            if (
                !uf_flash_service_write_byte(
                    service,
                    position + offset,
                    UINT8_C(0x40)) ||
                !uf_flash_service_write_byte(
                    service,
                    position + offset,
                    value))
            {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            while (timeout > 0)
            {
                uint8_t first;
                uint8_t second;

                if (
                    !uf_flash_service_read_byte(
                        service,
                        position + offset,
                        &first) ||
                    !uf_flash_service_read_byte(
                        service,
                        position + offset,
                        &second))
                {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    return false;
                }
                if (
                    (first & UINT8_C(0x40)) == (second & UINT8_C(0x40)))
                {
                    break;
                }
                --timeout;
                if (
                    !service->access.delay_us(
                        service->access.context,
                        UINT32_C(10)))
                {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    return false;
                }
            }
            if (
                !uf_flash_service_read_byte(
                    service,
                    position + offset,
                    &status))
            {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            if (status == value)
            {
                break;
            }
        }
        if (status != value)
        {
            (void)reset_macronix(service, UF_FLASH_ERROR_PROGRAM);
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }
    if (!reset_macronix(service, UF_FLASH_ERROR_PROGRAM))
    {
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool erase_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address)
{
    uint8_t attempt;
    uint8_t status = 0;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    for (attempt = 0; attempt < 4; ++attempt)
    {
        uint16_t timeout = UINT16_C(50000);

        if (
            !uf_flash_service_write_byte(
                service,
                sector_address,
                UINT8_C(0x20)) ||
            !uf_flash_service_write_byte(
                service,
                sector_address,
                UINT8_C(0xD0)) ||
            !service->access.delay_us(
                service->access.context,
                UINT32_C(250)))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        while (timeout > 0)
        {
            uint8_t first;
            uint8_t second;

            if (
                !uf_flash_service_read_byte(
                    service,
                    sector_address,
                    &first) ||
                !uf_flash_service_read_byte(
                    service,
                    sector_address,
                    &second))
            {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            if (
                (first & UINT8_C(0x40)) == (second & UINT8_C(0x40)))
            {
                break;
            }
            --timeout;
            if (
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(100)))
            {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
        }
        if (
            !uf_flash_service_read_byte(
                service,
                sector_address,
                &status))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if ((status & UINT8_C(0x80)) != 0)
        {
            break;
        }
    }
    if (!reset_macronix(service, UF_FLASH_ERROR_ERASE))
    {
        return false;
    }
    if ((status & UINT8_C(0x80)) == 0)
    {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool program_sector_page(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    uint8_t attempt;
    uint8_t status = 0;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL || service->access.read_source_byte == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    for (attempt = 0; attempt < 4; ++attempt)
    {
        uint16_t timeout = UINT16_C(5000);

        if (
            !uf_flash_service_command(service, UINT8_C(0xA0)) || !write_source_page(service, position, source_address) || !service->access.delay_us(service->access.context, UINT32_C(300)))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        do
        {
            if (
                !uf_flash_service_read_byte(
                    service,
                    position + service->chip->page_size_bytes - 1,
                    &status) ||
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(100)))
            {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            --timeout;
        } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);
        if (
            !uf_flash_service_read_byte(
                service,
                position + service->chip->page_size_bytes - 1,
                &status) ||
            !uf_flash_service_command(service, UINT8_C(0x50)))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        if ((status & UINT8_C(0xB0)) == UINT8_C(0x80))
        {
            break;
        }
    }
    if (!uf_flash_service_command(service, UINT8_C(0xF0)))
    {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    if ((status & UINT8_C(0xB0)) != UINT8_C(0x80))
    {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool erase_status_polled(
    struct uf_flash_service *service,
    uf_rom_offset_t status_address,
    bool bulk)
{
    uint8_t attempt;
    uint8_t status = 0;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    for (attempt = 0; attempt < 4; ++attempt)
    {
        uint16_t timeout = UINT16_C(10000);

        if (!uf_flash_service_command(service, UINT8_C(0x80)))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if (bulk)
        {
            if (!uf_flash_service_command(service, UINT8_C(0x10)))
            {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
        }
        else if (
            !uf_flash_service_write_byte(
                service,
                UF_FLASH_COMMAND_ADDRESS_1,
                UF_FLASH_COMMAND_UNLOCK_1) ||
            !uf_flash_service_write_byte(
                service,
                UF_FLASH_COMMAND_ADDRESS_2,
                UF_FLASH_COMMAND_UNLOCK_2) ||
            !uf_flash_service_write_byte(
                service,
                status_address,
                UINT8_C(0x30)))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        do
        {
            if (
                !uf_flash_service_read_byte(
                    service,
                    status_address,
                    &status) ||
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(1000)))
            {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            --timeout;
        } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);
        if (
            !uf_flash_service_read_byte(
                service,
                status_address,
                &status) ||
            !uf_flash_service_command(service, UINT8_C(0x50)))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if ((status & UINT8_C(0xB0)) == UINT8_C(0x80))
        {
            break;
        }
    }
    if (!uf_flash_service_command(service, UINT8_C(0xF0)))
    {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    if ((status & UINT8_C(0xB0)) != UINT8_C(0x80))
    {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool erase_sector_page(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address)
{
    return erase_status_polled(service, sector_address, false);
}

static bool erase_bulk(
    struct uf_flash_service *service,
    uf_rom_offset_t status_address)
{
    return erase_status_polled(service, status_address, true);
}

bool uf_flash_register_macronix_algorithms(
    uf_flash_algorithm_registry_t *registry)
{
    if (!uf_flash_algorithm_registry_is_valid(registry))
    {
        return false;
    }
    registry->program[UF_FLASH_PROGRAM_MACRONIX_SECTOR] =
        program_sector;
    registry->program[UF_FLASH_PROGRAM_MACRONIX_SECTOR_PAGE] =
        program_sector_page;
    registry->erase[UF_FLASH_ERASE_MACRONIX_SECTOR] = erase_sector;
    registry->erase[UF_FLASH_ERASE_MACRONIX_SECTOR_PAGE] =
        erase_sector_page;
    registry->erase[UF_FLASH_ERASE_MACRONIX_BULK] = erase_bulk;
    return true;
}
