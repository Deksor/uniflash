#include "uniflash/st_algorithms.h"

static uint8_t st_lock_addresses(
    const struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t variant,
    uf_phys_addr_t *locks)
{
    uint8_t count = UINT8_C(1);

    if (variant == 2)
    {
        if (
            address >= service->chip->capacity_bytes - UINT32_C(0x8000))
        {
            locks[0] = UINT32_C(0xFFBF8002);
            if (
                address >= service->chip->capacity_bytes - UINT32_C(0x6000))
            {
                locks[0] = address >= service->chip->capacity_bytes - UINT32_C(0x4000)
                               ? UINT32_C(0xFFBFC002)
                               : UINT32_C(0xFFBFA002);
            }
        }
        else
        {
            locks[0] = uf_flash_fwh_64k_lock_address(service, address);
        }
        return count;
    }

    uf_phys_addr_t base = uf_flash_fwh_64k_lock_address(service, address);
    locks[0] = base;
    if (variant == 1)
    {
        return count;
    }
    if (
        (variant == 3 && (address < UINT32_C(0x10000) || address >= service->chip->capacity_bytes - UINT32_C(0x20000))) || (variant == 4 && (address < UINT32_C(0x20000) || address >= service->chip->capacity_bytes - UINT32_C(0x10000))))
    {
        count = UINT8_C(16);
        for (uint8_t index = 1; index < count; ++index)
        {
            locks[index] = base + (uf_phys_addr_t)index * UINT32_C(0x1000);
        }
    }
    return count;
}

static bool protected_program(
    struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address,
    uint8_t variant)
{
    uf_phys_addr_t locks[16];
    uint8_t count;

    if (service == NULL || service->chip == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }
    count = st_lock_addresses(service, position, variant, locks);
    return uf_flash_run_protected_program(
        service,
        position,
        source_address,
        locks,
        count,
        UINT8_C(0xF8),
        uf_flash_program_intel_sector);
}

static bool protected_erase(
    struct uf_flash_service *service,
    uf_rom_offset_t address,
    uint8_t variant)
{
    uf_phys_addr_t locks[16];
    uint8_t count;

    if (service == NULL || service->chip == NULL)
    {
        if (service != NULL)
        {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    count = st_lock_addresses(service, address, variant, locks);
    return uf_flash_run_protected_erase(
        service,
        address,
        locks,
        count,
        UINT8_C(0xF8),
        uf_flash_erase_intel_sector);
}

#define DEFINE_ST_VARIANT(suffix, variant_value)                 \
    static bool program_##suffix(                                \
        struct uf_flash_service *service,                        \
        uf_rom_offset_t position,                                \
        uf_phys_addr_t source_address)                           \
    {                                                            \
        return protected_program(                                \
            service, position, source_address, variant_value);   \
    }                                                            \
    static bool erase_##suffix(                                  \
        struct uf_flash_service *service,                        \
        uf_rom_offset_t address)                                 \
    {                                                            \
        return protected_erase(service, address, variant_value); \
    }

DEFINE_ST_VARIANT(sector, UINT8_C(1))
DEFINE_ST_VARIANT(sector_b, UINT8_C(2))
DEFINE_ST_VARIANT(sector_a_variant, UINT8_C(3))
DEFINE_ST_VARIANT(sector_b_variant, UINT8_C(4))

bool uf_flash_register_st_algorithms(
    uf_flash_algorithm_registry_t *registry)
{
    if (!uf_flash_algorithm_registry_is_valid(registry))
    {
        return false;
    }
    registry->program[UF_FLASH_PROGRAM_ST_SECTOR] = program_sector;
    registry->program[UF_FLASH_PROGRAM_ST_SECTOR_B] = program_sector_b;
    registry->program[UF_FLASH_PROGRAM_ST_SECTOR_A_VARIANT] =
        program_sector_a_variant;
    registry->program[UF_FLASH_PROGRAM_ST_SECTOR_B_VARIANT] =
        program_sector_b_variant;
    registry->erase[UF_FLASH_ERASE_ST_SECTOR] = erase_sector;
    registry->erase[UF_FLASH_ERASE_ST_SECTOR_B] = erase_sector_b;
    registry->erase[UF_FLASH_ERASE_ST_SECTOR_A_VARIANT] =
        erase_sector_a_variant;
    registry->erase[UF_FLASH_ERASE_ST_SECTOR_B_VARIANT] =
        erase_sector_b_variant;
    return true;
}
