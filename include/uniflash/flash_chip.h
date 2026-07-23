#ifndef UNIFLASH_FLASH_CHIP_H
#define UNIFLASH_FLASH_CHIP_H

#include "uniflash/types.h"

#define UF_FLASH_MAX_SECTOR_REGIONS 5

#define UF_KIB(value) ((uint32_t)(value) * UINT32_C(1024))

/*
 * These values preserve the Pascal ChipInfo.Flags meanings exactly. Treat
 * them as behavior codes until each corresponding algorithm has been ported.
 */
typedef uint8_t uf_flash_behavior_t;

enum {
    UF_FLASH_BEHAVIOR_SECTOR = 0,
    UF_FLASH_BEHAVIOR_PAGE = 1,
    UF_FLASH_BEHAVIOR_BULK_ERASE = 2,
    UF_FLASH_BEHAVIOR_SMALL_SECTORS = 3,
    UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING = 6
};

/*
 * Data files reference algorithms by ID instead of containing function
 * pointers. The algorithm registry will resolve these IDs in a later step.
 */
typedef uint8_t uf_flash_program_algorithm_t;

enum {
    UF_FLASH_PROGRAM_NONE = 0,
    UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE,
    UF_FLASH_PROGRAM_INTEL_SECTOR,
    UF_FLASH_PROGRAM_INTEL_SECTOR_U,
    UF_FLASH_PROGRAM_AMD_SECTOR,
    UF_FLASH_PROGRAM_AMD_EMBEDDED,
    UF_FLASH_PROGRAM_AMD_FLASH,
    UF_FLASH_PROGRAM_ATMEL_BYTE,
    UF_FLASH_PROGRAM_ATMEL_PAGE,
    UF_FLASH_PROGRAM_ATMEL_FWH,
    UF_FLASH_PROGRAM_ATMEL_FWH2,
    UF_FLASH_PROGRAM_ATMEL_FWH3,
    UF_FLASH_PROGRAM_ATMEL_FWH4,
    UF_FLASH_PROGRAM_MACRONIX_SECTOR,
    UF_FLASH_PROGRAM_MACRONIX_SECTOR_PAGE,
    UF_FLASH_PROGRAM_PMC_FWH,
    UF_FLASH_PROGRAM_PMC_FWH2,
    UF_FLASH_PROGRAM_SHARP_SECTOR,
    UF_FLASH_PROGRAM_SST_SECTOR,
    UF_FLASH_PROGRAM_SST_SECTOR2,
    UF_FLASH_PROGRAM_SST_FWH,
    UF_FLASH_PROGRAM_SST_FWH2,
    UF_FLASH_PROGRAM_ST_SECTOR,
    UF_FLASH_PROGRAM_ST_SECTOR_B,
    UF_FLASH_PROGRAM_ST_SECTOR_A_VARIANT,
    UF_FLASH_PROGRAM_ST_SECTOR_B_VARIANT,
    UF_FLASH_PROGRAM_WINBOND_FWH,
    UF_FLASH_PROGRAM_COUNT
};

typedef uint8_t uf_flash_erase_algorithm_t;

enum {
    UF_FLASH_ERASE_NONE = 0,
    UF_FLASH_ERASE_INTEL_SECTOR,
    UF_FLASH_ERASE_INTEL_SECTOR_U,
    UF_FLASH_ERASE_AMD_SECTOR,
    UF_FLASH_ERASE_AMD_BULK,
    UF_FLASH_ERASE_AMD_EMBEDDED,
    UF_FLASH_ERASE_AMD_FLASH,
    UF_FLASH_ERASE_ATMEL_BULK,
    UF_FLASH_ERASE_ATMEL_FWH,
    UF_FLASH_ERASE_ATMEL_FWH2,
    UF_FLASH_ERASE_ATMEL_FWH3,
    UF_FLASH_ERASE_ATMEL_FWH4,
    UF_FLASH_ERASE_MACRONIX_BULK,
    UF_FLASH_ERASE_MACRONIX_SECTOR,
    UF_FLASH_ERASE_MACRONIX_SECTOR_PAGE,
    UF_FLASH_ERASE_PMC_FWH,
    UF_FLASH_ERASE_PMC_FWH2,
    UF_FLASH_ERASE_SHARP_SECTOR,
    UF_FLASH_ERASE_SST_FWH,
    UF_FLASH_ERASE_SST_FWH2,
    UF_FLASH_ERASE_ST_SECTOR,
    UF_FLASH_ERASE_ST_SECTOR_B,
    UF_FLASH_ERASE_ST_SECTOR_A_VARIANT,
    UF_FLASH_ERASE_ST_SECTOR_B_VARIANT,
    UF_FLASH_ERASE_WINBOND_SECTOR,
    UF_FLASH_ERASE_WINBOND_FWH,
    UF_FLASH_ERASE_COUNT
};

typedef struct uf_flash_sector_region {
    uint16_t sector_count;
    uf_rom_size_t sector_size_bytes;
} uf_flash_sector_region_t;

typedef struct uf_flash_chip {
    const char *name;
    uint8_t device_id;
    uf_flash_behavior_t behavior;
    uf_flash_program_algorithm_t program_algorithm;
    uf_flash_erase_algorithm_t erase_algorithm;
    uint16_t page_size_bytes;
    uf_rom_size_t capacity_bytes;
    uint8_t sector_region_count;
    uf_flash_sector_region_t sector_regions[UF_FLASH_MAX_SECTOR_REGIONS];
} uf_flash_chip_t;

typedef struct uf_flash_manufacturer {
    const char *name;
    uint8_t manufacturer_id;
    const uf_flash_chip_t *chips;
    uint16_t chip_count;
} uf_flash_manufacturer_t;

UF_STATIC_ASSERT(
    flash_sector_region_count_is_2_bytes,
    sizeof(((uf_flash_sector_region_t *)0)->sector_count) == 2
);
UF_STATIC_ASSERT(
    flash_sector_region_size_is_4_bytes,
    sizeof(((uf_flash_sector_region_t *)0)->sector_size_bytes) == 4
);
UF_STATIC_ASSERT(
    flash_chip_capacity_is_4_bytes,
    sizeof(((uf_flash_chip_t *)0)->capacity_bytes) == 4
);
UF_STATIC_ASSERT(
    flash_chip_page_size_is_2_bytes,
    sizeof(((uf_flash_chip_t *)0)->page_size_bytes) == 2
);
UF_STATIC_ASSERT(
    flash_chip_behavior_is_1_byte,
    sizeof(((uf_flash_chip_t *)0)->behavior) == 1
);
UF_STATIC_ASSERT(
    flash_chip_program_algorithm_is_1_byte,
    sizeof(((uf_flash_chip_t *)0)->program_algorithm) == 1
);
UF_STATIC_ASSERT(
    flash_chip_erase_algorithm_is_1_byte,
    sizeof(((uf_flash_chip_t *)0)->erase_algorithm) == 1
);

#endif
