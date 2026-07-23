#include "uniflash/sharp_algorithms.h"

#define UF_SHARP_TOP_LOCK_ADDRESS UINT32_C(0x001F0000)

static bool raw_write(
    struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t value)
{
    if (service->access.write_byte == NULL)
    {
        return false;
    }
    return service->access.write_byte(
        service->access.context,
        address,
        value);
}

static bool raw_read(
    struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t *value)
{
    if (service->access.read_byte == NULL)
    {
        return false;
    }
    return service->access.read_byte(
        service->access.context,
        address,
        value);
}

static bool set_protection(
    struct uf_flash_service *service,
    uint8_t command,
    uf_flash_error_t error)
{
    uint8_t status;

    if (
        !raw_write(service, 0, UINT8_C(0x60)) || !raw_write(service, 0, command) || !raw_read(service, 0, &status))
    {
        service->error = error;
        return false;
    }
    if ((status & UINT8_C(0xBA)) != UINT8_C(0x80))
    {
        if (
            !service->access.delay_us(
                service->access.context,
                UINT32_C(10)) ||
            !raw_read(service, 0, &status))
        {
            service->error = error;
            return false;
        }
        if ((status & UINT8_C(0xBA)) != UINT8_C(0x80))
        {
            service->error = error;
        }
    }
    return true;
}

static bool clear_top_block_lock(
    struct uf_flash_service *service,
    uf_flash_error_t error)
{
    uint16_t timeout = UINT16_C(6000);
    uint8_t status;

    /*
     * SHARP.PAS deliberately uses 0x1F0000 for this command even on its
     * 1-MiB parts. Use the injected raw backend rather than normal bounded
     * ROM access so the legacy command address remains observable.
     */
    if (
        !raw_write(service, 0, UINT8_C(0x60)) || !raw_write(
                                                     service,
                                                     UF_SHARP_TOP_LOCK_ADDRESS,
                                                     UINT8_C(0xD0)))
    {
        service->error = error;
        return false;
    }
    do
    {
        if (
            !raw_read(service, UF_SHARP_TOP_LOCK_ADDRESS, &status) || !service->access.delay_us(
                                                                          service->access.context,
                                                                          UINT32_C(1000)))
        {
            service->error = error;
            return false;
        }
        --timeout;
    } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);

    if (
        timeout == 0 || (status & UINT8_C(0xBA)) != UINT8_C(0x80))
    {
        service->error = error;
    }
    return true;
}

static bool address_is_in_top_64k(
    const struct uf_flash_service *service,
    uf_rom_offset_t address)
{
    return address >= service->chip->capacity_bytes - UINT32_C(0x10000)
               ? true
               : false;
}

bool uf_flash_program_sharp_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    bool transport_ok;
    bool operation_ok = false;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    transport_ok = set_protection(
        service,
        UINT8_C(0xDB),
        UF_FLASH_ERROR_PROGRAM);
    if (transport_ok && address_is_in_top_64k(service, position))
    {
        transport_ok = clear_top_block_lock(
            service,
            UF_FLASH_ERROR_PROGRAM);
    }
    if (transport_ok)
    {
        operation_ok = uf_flash_program_intel_sector(
            service,
            position,
            source_address);
    }
    if (
        !set_protection(
            service,
            UINT8_C(0xBB),
            UF_FLASH_ERROR_PROGRAM))
    {
        return false;
    }
    return (
               transport_ok && operation_ok && service->error == UF_FLASH_ERROR_NONE)
               ? true
               : false;
}

bool uf_flash_erase_sharp_sector(
    struct uf_flash_service *service,
    uf_rom_offset_t sector_address)
{
    bool transport_ok;
    bool operation_ok = false;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    transport_ok = set_protection(
        service,
        UINT8_C(0xDB),
        UF_FLASH_ERROR_ERASE);
    if (transport_ok && address_is_in_top_64k(service, sector_address))
    {
        transport_ok = clear_top_block_lock(
            service,
            UF_FLASH_ERROR_ERASE);
    }
    if (transport_ok)
    {
        operation_ok = uf_flash_erase_intel_sector(
            service,
            sector_address);
    }
    if (
        !set_protection(
            service,
            UINT8_C(0xBB),
            UF_FLASH_ERROR_ERASE))
    {
        return false;
    }
    return (
               transport_ok && operation_ok && service->error == UF_FLASH_ERROR_NONE)
               ? true
               : false;
}

bool uf_flash_register_sharp_algorithms(
    uf_flash_algorithm_registry_t *registry)
{
    if (!uf_flash_algorithm_registry_is_valid(registry))
    {
        return false;
    }
    registry->program[UF_FLASH_PROGRAM_SHARP_SECTOR] =
        uf_flash_program_sharp_sector;
    registry->erase[UF_FLASH_ERASE_SHARP_SECTOR] =
        uf_flash_erase_sharp_sector;
    return true;
}
