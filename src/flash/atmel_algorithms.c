#include "uniflash/atmel_algorithms.h"

static bool source_byte(
    struct uf_flash_service *service,
    uf_phys_addr_t address,
    uint8_t *value)
{
    return (
        service->access.read_source_byte != NULL && service->access.read_source_byte(
                                                        service->access.context,
                                                        address,
                                                        value));
}

static bool erase_bulk(
    struct uf_flash_service *service,
    uf_rom_offset_t ignored_address)
{
    uint16_t timeout = UINT16_C(20000);
    uint8_t status;

    (void)ignored_address;
    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL || !uf_flash_service_command(service, UINT8_C(0x80)) || !uf_flash_service_command(service, UINT8_C(0x10)))
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    do
    {
        if (
            !service->access.delay_us(
                service->access.context,
                UINT32_C(1000)) ||
            !uf_flash_service_read_byte(service, 0, &status))
        {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        --timeout;
    } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);
    if (timeout == 0)
    {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool program_byte(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL || service->access.read_source_byte == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset)
    {
        uint16_t timeout = UINT16_C(10);
        uint8_t value;
        uint8_t status;

        if (
            !source_byte(service, source_address + offset, &value) || !uf_flash_service_command(service, UINT8_C(0xA0)) || !uf_flash_service_write_byte(service, position + offset, value))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        do
        {
            if (
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(10)) ||
                !uf_flash_service_read_byte(
                    service,
                    position + offset,
                    &status))
            {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            --timeout;
        } while (
            (status & UINT8_C(0x80)) != (value & UINT8_C(0x80)) && timeout > 0);
        if (timeout == 0)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

static bool write_page(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset)
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

static bool program_page(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address)
{
    uint8_t expected;
    uint8_t status = 0;

    if (
        service == NULL || service->chip == NULL || service->access.delay_us == NULL || service->access.read_source_byte == NULL || !source_byte(service, source_address + UINT32_C(127), &expected))
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    expected &= UINT8_C(0x80);
    for (uint8_t attempt = 0; attempt < 4; ++attempt)
    {
        uint16_t timeout = UINT16_C(100);

        if (
            !uf_flash_service_command(service, UINT8_C(0xA0)) || !write_page(service, position, source_address) || !service->access.delay_us(service->access.context, UINT32_C(10000)))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        /*
         * ATMEL.PAS always polls byte 127, even for 64-byte pages. Preserve
         * that observable legacy address while porting the algorithm.
         */
        do
        {
            if (
                !uf_flash_service_read_byte(
                    service,
                    position + UINT32_C(127),
                    &status) ||
                !service->access.delay_us(
                    service->access.context,
                    UINT32_C(10)))
            {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            --timeout;
        } while (
            (status & UINT8_C(0x80)) != expected && timeout > 0);
        if (
            !uf_flash_service_read_byte(
                service,
                position + UINT32_C(127),
                &status))
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        if ((status & UINT8_C(0x80)) == expected)
        {
            service->error = UF_FLASH_ERROR_NONE;
            return true;
        }
    }
    service->error = UF_FLASH_ERROR_PROGRAM;
    return false;
}

static uint8_t fwh_addresses(
    const struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t variant,
    uf_phys_addr_t *locks)
{
    if (variant == 1)
    {
        locks[0] = uf_flash_fwh_64k_lock_address(service, address);
        return UINT8_C(1);
    }
    if (variant == 2)
    {
        if (address >= UINT32_C(0x30000))
        {
            locks[0] = UINT32_C(0xFFBF0002);
            if (address >= UINT32_C(0x38000))
            {
                locks[0] = UINT32_C(0xFFBF8002);
            }
            if (address >= UINT32_C(0x3A000))
            {
                locks[0] = UINT32_C(0xFFBFA002);
            }
            if (address >= UINT32_C(0x3C000))
            {
                locks[0] = UINT32_C(0xFFBFC002);
            }
        }
        else
        {
            locks[0] = uf_flash_fwh_64k_lock_address(service, address);
        }
        locks[1] = locks[0] - UINT32_C(0x400000);
        return UINT8_C(2);
    }
    if (variant == 3)
    {
        if (address >= UINT32_C(0x70000))
        {
            locks[0] = UINT32_C(0xFFBF0002);
            locks[1] = UINT32_C(0xFF7F0002);
            if (address >= UINT32_C(0x74000))
            {
                locks[1] = UINT32_C(0xFF7F4002);
            }
            if (address >= UINT32_C(0x76000))
            {
                locks[1] = UINT32_C(0xFF7F6002);
            }
            if (address >= UINT32_C(0x78000))
            {
                locks[1] = UINT32_C(0xFF7F8002);
            }
        }
        else
        {
            locks[0] = uf_flash_fwh_64k_lock_address(service, address);
            locks[1] = (address & UINT32_C(0xFFFF0000)) + UINT32_C(0xFF800002) - service->chip->capacity_bytes;
        }
        return UINT8_C(2);
    }

    if (address < UINT32_C(0x10000))
    {
        locks[0] = UINT32_C(0xFFB88002);
        if (address < UINT32_C(0x8000))
        {
            locks[0] = UINT32_C(0xFFB84002);
        }
        if (address < UINT32_C(0x4000))
        {
            locks[0] = UINT32_C(0xFFB82002);
        }
        if (address < UINT32_C(0x2000))
        {
            locks[0] = UINT32_C(0xFFB80002);
        }
    }
    else
    {
        locks[0] = uf_flash_fwh_64k_lock_address(service, address);
    }
    locks[1] = locks[0] - UINT32_C(0x400000);
    return UINT8_C(2);
}

static bool protected_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    uint8_t variant)
{
    uf_phys_addr_t locks[2];
    uint8_t count;

    if (service == NULL || service->chip == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    count = fwh_addresses(service, position, variant, locks);
    return uf_flash_run_protected_program(
        service,
        position,
        source_address,
        locks,
        count,
        UINT8_C(0xFC),
        uf_flash_program_intel_sector);
}

static bool protected_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t variant)
{
    uf_phys_addr_t locks[2];
    uint8_t count;
    uf_flash_inner_erase_fn operation = variant == 1
                                            ? uf_flash_erase_intel_sector
                                            : uf_flash_erase_intel_sector_u;

    if (service == NULL || service->chip == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    count = fwh_addresses(service, address, variant, locks);
    return uf_flash_run_protected_erase(
        service,
        address,
        locks,
        count,
        UINT8_C(0xFC),
        operation);
}

#define DEFINE_ATMEL_WRAPPERS(suffix, variant_value)             \
    static bool program_fwh##suffix(                             \
        struct uf_flash_service *service,                        \
        uf_rom_offset_t position,                                \
        uf_phys_addr_t source_address)                           \
    {                                                            \
        return protected_program(                                \
            service, position, source_address, variant_value);   \
    }                                                            \
    static bool erase_fwh##suffix(                               \
        struct uf_flash_service *service,                        \
        uf_rom_offset_t address)                                 \
    {                                                            \
        return protected_erase(service, address, variant_value); \
    }

DEFINE_ATMEL_WRAPPERS(1, UINT8_C(1))
DEFINE_ATMEL_WRAPPERS(2, UINT8_C(2))
DEFINE_ATMEL_WRAPPERS(3, UINT8_C(3))
DEFINE_ATMEL_WRAPPERS(4, UINT8_C(4))

bool uf_flash_register_atmel_algorithms(
    uf_flash_algorithm_registry_t *registry)
{
    if (!uf_flash_algorithm_registry_is_valid(registry))
    {
        return false;
    }
    registry->program[UF_FLASH_PROGRAM_ATMEL_BYTE] = program_byte;
    registry->program[UF_FLASH_PROGRAM_ATMEL_PAGE] = program_page;
    registry->program[UF_FLASH_PROGRAM_ATMEL_FWH] = program_fwh1;
    registry->program[UF_FLASH_PROGRAM_ATMEL_FWH2] = program_fwh2;
    registry->program[UF_FLASH_PROGRAM_ATMEL_FWH3] = program_fwh3;
    registry->program[UF_FLASH_PROGRAM_ATMEL_FWH4] = program_fwh4;
    registry->erase[UF_FLASH_ERASE_ATMEL_BULK] = erase_bulk;
    registry->erase[UF_FLASH_ERASE_ATMEL_FWH] = erase_fwh1;
    registry->erase[UF_FLASH_ERASE_ATMEL_FWH2] = erase_fwh2;
    registry->erase[UF_FLASH_ERASE_ATMEL_FWH3] = erase_fwh3;
    registry->erase[UF_FLASH_ERASE_ATMEL_FWH4] = erase_fwh4;
    return true;
}
