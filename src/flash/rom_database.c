#include <stddef.h>
#include <stdint.h>

#include "uniflash/rom_database.h"

#define UF_ARRAY_COUNT(array) (sizeof(array) / sizeof((array)[0]))

#define UF_ROM_BEGIN(symbol, manufacturer_id, manufacturer_name) \
    static const uf_flash_chip_t symbol##_chips[] = {
#define UF_ROM_CHIP( \
    device_id, chip_name, capacity_bytes, page_size_bytes, behavior, \
    program_algorithm, erase_algorithm, region_count, \
    region_0_count, region_0_size, region_1_count, region_1_size, \
    region_2_count, region_2_size, region_3_count, region_3_size, \
    region_4_count, region_4_size \
) \
    { \
        chip_name, \
        (uint8_t)(device_id), \
        (uf_flash_behavior_t)(behavior), \
        (uf_flash_program_algorithm_t)(program_algorithm), \
        (uf_flash_erase_algorithm_t)(erase_algorithm), \
        (uint16_t)(page_size_bytes), \
        (uf_rom_size_t)(capacity_bytes), \
        (uint8_t)(region_count), \
        { \
            { (uint16_t)(region_0_count), (uf_rom_size_t)(region_0_size) }, \
            { (uint16_t)(region_1_count), (uf_rom_size_t)(region_1_size) }, \
            { (uint16_t)(region_2_count), (uf_rom_size_t)(region_2_size) }, \
            { (uint16_t)(region_3_count), (uf_rom_size_t)(region_3_size) }, \
            { (uint16_t)(region_4_count), (uf_rom_size_t)(region_4_size) } \
        } \
    },
#define UF_ROM_END() };

#include "data/roms/catalog.def"

#undef UF_ROM_END
#undef UF_ROM_CHIP
#undef UF_ROM_BEGIN

#define UF_ROM_BEGIN(symbol, manufacturer_id, manufacturer_name) \
    { \
        manufacturer_name, \
        (uint8_t)(manufacturer_id), \
        symbol##_chips, \
        (uint16_t)UF_ARRAY_COUNT(symbol##_chips) \
    },
#define UF_ROM_CHIP( \
    device_id, chip_name, capacity_bytes, page_size_bytes, behavior, \
    program_algorithm, erase_algorithm, region_count, \
    region_0_count, region_0_size, region_1_count, region_1_size, \
    region_2_count, region_2_size, region_3_count, region_3_size, \
    region_4_count, region_4_size \
)
#define UF_ROM_END()

const uf_flash_manufacturer_t uf_rom_manufacturers[] = {
#include "data/roms/catalog.def"
};

#undef UF_ROM_END
#undef UF_ROM_CHIP
#undef UF_ROM_BEGIN

const uint16_t uf_rom_manufacturer_count =
    (uint16_t)UF_ARRAY_COUNT(uf_rom_manufacturers);

static uf_bool_t behavior_is_valid(uf_flash_behavior_t behavior)
{
    switch (behavior) {
    case UF_FLASH_BEHAVIOR_SECTOR:
    case UF_FLASH_BEHAVIOR_PAGE:
    case UF_FLASH_BEHAVIOR_BULK_ERASE:
    case UF_FLASH_BEHAVIOR_SMALL_SECTORS:
    case UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING:
        return UF_TRUE;
    default:
        return UF_FALSE;
    }
}

static uf_bool_t chip_geometry_is_valid(const uf_flash_chip_t *chip)
{
    uf_rom_size_t total_size;
    uint8_t index;

    if (chip->sector_region_count > UF_FLASH_MAX_SECTOR_REGIONS) {
        return UF_FALSE;
    }

    total_size = 0;
    for (index = 0; index < chip->sector_region_count; ++index) {
        const uf_flash_sector_region_t *region = &chip->sector_regions[index];

        if (region->sector_count == 0 || region->sector_size_bytes == 0) {
            return UF_FALSE;
        }
        if (
            region->sector_size_bytes
            > UINT32_MAX / (uf_rom_size_t)region->sector_count
        ) {
            return UF_FALSE;
        }
        if (
            total_size
            > UINT32_MAX
                - region->sector_size_bytes
                    * (uf_rom_size_t)region->sector_count
        ) {
            return UF_FALSE;
        }
        total_size +=
            region->sector_size_bytes * (uf_rom_size_t)region->sector_count;
    }

    for (index = chip->sector_region_count;
         index < UF_FLASH_MAX_SECTOR_REGIONS;
         ++index) {
        const uf_flash_sector_region_t *region = &chip->sector_regions[index];

        if (region->sector_count != 0 || region->sector_size_bytes != 0) {
            return UF_FALSE;
        }
    }

    if (chip->behavior == UF_FLASH_BEHAVIOR_SECTOR) {
        return total_size == chip->capacity_bytes ? UF_TRUE : UF_FALSE;
    }
    return total_size == 0 ? UF_TRUE : UF_FALSE;
}

static uf_bool_t chip_is_valid(const uf_flash_chip_t *chip)
{
    if (
        chip->name == NULL
        || chip->name[0] == '\0'
        || chip->capacity_bytes == 0
        || chip->page_size_bytes == 0
        || (uf_rom_size_t)chip->page_size_bytes > chip->capacity_bytes
    ) {
        return UF_FALSE;
    }
    if (!behavior_is_valid(chip->behavior)) {
        return UF_FALSE;
    }
    if (
        chip->program_algorithm == UF_FLASH_PROGRAM_NONE
        || chip->program_algorithm >= UF_FLASH_PROGRAM_COUNT
        || chip->erase_algorithm >= UF_FLASH_ERASE_COUNT
    ) {
        return UF_FALSE;
    }
    return chip_geometry_is_valid(chip);
}

const uf_flash_manufacturer_t *uf_rom_find_manufacturer(
    uint8_t manufacturer_id
)
{
    uint16_t index;

    for (index = 0; index < uf_rom_manufacturer_count; ++index) {
        if (
            uf_rom_manufacturers[index].manufacturer_id == manufacturer_id
        ) {
            return &uf_rom_manufacturers[index];
        }
    }
    return NULL;
}

const uf_flash_chip_t *uf_rom_find_chip(
    const uf_flash_manufacturer_t *manufacturer,
    uint8_t device_id
)
{
    uint16_t index;

    if (manufacturer == NULL) {
        return NULL;
    }
    for (index = 0; index < manufacturer->chip_count; ++index) {
        if (manufacturer->chips[index].device_id == device_id) {
            return &manufacturer->chips[index];
        }
    }
    return NULL;
}

uf_bool_t uf_rom_database_validate(void)
{
    uint16_t manufacturer_index;

    for (
        manufacturer_index = 0;
        manufacturer_index < uf_rom_manufacturer_count;
        ++manufacturer_index
    ) {
        const uf_flash_manufacturer_t *manufacturer =
            &uf_rom_manufacturers[manufacturer_index];
        uint16_t chip_index;
        uint16_t previous_index;

        if (
            manufacturer->name == NULL
            || manufacturer->name[0] == '\0'
            || manufacturer->chips == NULL
            || manufacturer->chip_count == 0
        ) {
            return UF_FALSE;
        }

        for (previous_index = 0;
             previous_index < manufacturer_index;
             ++previous_index) {
            if (
                uf_rom_manufacturers[previous_index].manufacturer_id
                == manufacturer->manufacturer_id
            ) {
                return UF_FALSE;
            }
        }

        for (chip_index = 0; chip_index < manufacturer->chip_count;
             ++chip_index) {
            if (!chip_is_valid(&manufacturer->chips[chip_index])) {
                return UF_FALSE;
            }
            for (previous_index = 0; previous_index < chip_index;
                 ++previous_index) {
                if (
                    manufacturer->chips[previous_index].device_id
                    == manufacturer->chips[chip_index].device_id
                ) {
                    return UF_FALSE;
                }
            }
        }
    }
    return UF_TRUE;
}
