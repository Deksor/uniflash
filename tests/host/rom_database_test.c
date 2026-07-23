#include <assert.h>
#include <string.h>

#include "uniflash/rom_database.h"

typedef struct expected_uniform_sector_chip {
    uint8_t device_id;
    const char *name;
    uf_rom_size_t capacity_bytes;
    uint16_t sector_count;
    uf_rom_size_t sector_size_bytes;
} expected_uniform_sector_chip_t;

typedef struct expected_sector_chip {
    uint8_t device_id;
    const char *name;
    uf_rom_size_t capacity_bytes;
    uint8_t region_count;
    uf_flash_sector_region_t regions[4];
} expected_sector_chip_t;

typedef struct expected_catalyst_chip {
    uint8_t device_id;
    const char *name;
    uf_rom_size_t capacity_bytes;
    uf_flash_behavior_t behavior;
    uf_flash_program_algorithm_t program_algorithm;
    uf_flash_erase_algorithm_t erase_algorithm;
    uint8_t region_count;
    uf_flash_sector_region_t regions[4];
} expected_catalyst_chip_t;

typedef struct expected_mixed_chip {
    uint8_t device_id;
    const char *name;
    uf_rom_size_t capacity_bytes;
    uint16_t page_size_bytes;
    uf_flash_behavior_t behavior;
    uf_flash_program_algorithm_t program_algorithm;
    uf_flash_erase_algorithm_t erase_algorithm;
    uint8_t region_count;
    uf_flash_sector_region_t regions[4];
} expected_mixed_chip_t;

typedef struct expected_pmc_chip {
    uint8_t device_id;
    const char *name;
    uf_rom_size_t capacity_bytes;
    uf_flash_program_algorithm_t program_algorithm;
    uf_flash_erase_algorithm_t erase_algorithm;
    uint8_t region_count;
    uf_flash_sector_region_t regions[4];
} expected_pmc_chip_t;

static const expected_uniform_sector_chip_t expected_imt_chips[] = {
    { 0xA0, "IM29F001T/5V", UF_KIB(128), 256, 512 },
    { 0xA3, "IM29F001B/5V", UF_KIB(128), 256, 512 },
    { 0xA5, "IM29LV001T/3.3V", UF_KIB(128), 256, 512 },
    { 0xA6, "IM29LV001B/3.3V", UF_KIB(128), 256, 512 },
    { 0xA1, "IM29F002T/5V", UF_KIB(256), 512, 512 },
    { 0xA2, "IM29F002B/5V", UF_KIB(256), 512, 512 },
    { 0xAF, "IM29F004T/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xAE, "IM29F004B/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xA7, "IM29LV004T/3.3V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xA8, "IM29LV004B/3.3V", UF_KIB(512), 512, UF_KIB(1) }
};

static const expected_uniform_sector_chip_t expected_mosel_chips[] = {
    { 0x00, "V29C51000T/5V", UF_KIB(64), 128, 512 },
    { 0xA0, "V29C51000B/5V", UF_KIB(64), 128, 512 },
    { 0x01, "V29C51001T/5V", UF_KIB(128), 256, 512 },
    { 0xA1, "V29C51001B/5V", UF_KIB(128), 256, 512 },
    { 0x02, "V29C51002T/5V", UF_KIB(256), 512, 512 },
    { 0xA2, "V29C51002B/5V", UF_KIB(256), 512, 512 },
    { 0x03, "V29C51004T/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xA3, "V29C51004B/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0x13, "V29C51400T/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xB3, "V29C51400B/5V", UF_KIB(512), 512, UF_KIB(1) },
    { 0x83, "V29C31400T/3.3V", UF_KIB(512), 512, UF_KIB(1) },
    { 0x63, "V29C31004T/3.3V", UF_KIB(512), 512, UF_KIB(1) },
    { 0xC3, "V29C31004B/3.3V", UF_KIB(512), 512, UF_KIB(1) },
    { 0x73, "V29C31004B/3.3V", UF_KIB(512), 512, UF_KIB(1) },
    { 0x20, "V29LC51000/5V", UF_KIB(64), 128, 512 },
    { 0x60, "V29LC51001/5V", UF_KIB(128), 256, 512 },
    { 0x82, "V29LC51002/5V", UF_KIB(256), 512, 512 }
};

static const expected_sector_chip_t expected_alliance_chips[] = {
    {
        0xB0, "AS29F002T/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x51, "AS29F200T/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x34, "AS29F002B/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0x57, "AS29F200B/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0xA4, "AS29F040/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB9, "AS29LV400T/3V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xBA, "AS29LV400B/3V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0xDA, "AS29LV800T/3V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x5B, "AS29LV800B/3V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    }
};

static const expected_sector_chip_t expected_fujitsu_chips[] = {
    {
        0x51, "MBM29F200TC/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xB0, "MBM29F002TC/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x57, "MBM29F200BC/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0x34, "MBM29F002BC/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0xA4, "MBM29F040C/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x23, "MBM29F400TC/5V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xAB, "MBM29F400BC/5V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0xC4, "MBM29LV160TE/3V", UF_KIB(2048), 4,
        {
            { 31, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x49, "MBM29LV160BE/3V", UF_KIB(2048), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 31, UF_KIB(64) }
        }
    },
    {
        0x27, "MBM29PL160TD/3V", UF_KIB(2048), 4,
        {
            { 7, UF_KIB(256) }, { 1, UF_KIB(224) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x45, "MBM29PL160BD/3V", UF_KIB(2048), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(224) }, { 7, UF_KIB(256) }
        }
    },
    {
        0xD4, "MBM29F033C/5V", UF_KIB(4096), 1,
        { { 64, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    }
};

static const expected_sector_chip_t expected_hyundai_chips[] = {
    {
        0xB0, "HY29F002T/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x34, "HY29F002B/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0x40, "HY29F040/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xA4, "HY29F040A/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xD5, "HY29F080/5V", UF_KIB(1024), 1,
        { { 16, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x23, "HY29F400T/5V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xAB, "HY29F400B/5V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0xD6, "HY29F800T/5V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x58, "HY29F800B/5V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    },
    {
        0xC4, "HY29LV160T/5V", UF_KIB(2048), 4,
        {
            { 31, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x49, "HY29LV160B/5V", UF_KIB(2048), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 31, UF_KIB(64) }
        }
    }
};

static const expected_sector_chip_t expected_eon_chips[] = {
    {
        0x92, "EN29F002(A)T/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x97, "EN29F002(A)B/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0x21, "EN29F512/5V", UF_KIB(64), 1,
        { { 4, UF_KIB(16) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x6F, "EN29LV512/3V", UF_KIB(64), 1,
        { { 4, UF_KIB(16) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x20, "EN29F010/5V", UF_KIB(128), 1,
        { { 8, UF_KIB(16) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x6E, "EN29LV010/3V", UF_KIB(128), 1,
        { { 8, UF_KIB(16) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x04, "EN29F040(A)/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x4F, "EN29LV040/3V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x08, "EN29F080/5V", UF_KIB(1024), 1,
        { { 16, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB9, "EN29LV400T/3V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xBA, "EN29LV400B/3V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0x89, "EN29F800T/5V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xDA, "EN29LV800(A)T/3V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x8A, "EN29F800B/5V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    },
    {
        0x5B, "EN29LV800(A)B/3V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    },
    {
        0xC4, "EN29LV160T/3V", UF_KIB(2048), 4,
        {
            { 31, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x49, "EN29LV160B/3V", UF_KIB(2048), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 31, UF_KIB(64) }
        }
    }
};

static const expected_sector_chip_t expected_amic_chips[] = {
    {
        0xA1, "A29001(1)T/5V", UF_KIB(128), 4,
        {
            { 3, UF_KIB(32) }, { 1, UF_KIB(16) },
            { 2, UF_KIB(4) }, { 1, UF_KIB(8) }
        }
    },
    {
        0x4C, "A29001(1)B/5V", UF_KIB(128), 4,
        {
            { 1, UF_KIB(8) }, { 2, UF_KIB(4) },
            { 1, UF_KIB(16) }, { 3, UF_KIB(32) }
        }
    },
    {
        0x8C, "A29002(1)T/5V", UF_KIB(256), 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x0D, "A29002(1)B/5V", UF_KIB(256), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0xA4, "A29010/5V", UF_KIB(128), 1,
        { { 4, UF_KIB(32) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x86, "A29040(A/B)/5V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x92, "A29L040/3V", UF_KIB(512), 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB0, "A29400T/5V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x34, "A29L004T/400B/3V", UF_KIB(512), 4,
        {
            { 7, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x31, "A29400B/5V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0xB5, "A29L004B/400B/5V", UF_KIB(512), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 7, UF_KIB(64) }
        }
    },
    {
        0x0E, "A29800T/5V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x1A, "A29L008T/800T/3V", UF_KIB(1024), 4,
        {
            { 15, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x8F, "A29800B/5V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    },
    {
        0x9B, "A29L008B/800B/3V", UF_KIB(1024), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 15, UF_KIB(64) }
        }
    },
    {
        0xA8, "A29L160T/3V", UF_KIB(2048), 4,
        {
            { 31, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x29, "A29L160B/3V", UF_KIB(2048), 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 31, UF_KIB(64) }
        }
    }
};

static const expected_catalyst_chip_t expected_catalyst_chips[] = {
    {
        0x84, "CAT28F150T/12V", UF_KIB(192),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 4,
        {
            { 1, UF_KIB(64) }, { 1, UF_KIB(96) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x85, "CAT28F150B/12V", UF_KIB(192),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(96) }, { 1, UF_KIB(64) }
        }
    },
    {
        0x94, "CAT28F001T/12V", UF_KIB(128),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 3,
        {
            { 1, UF_KIB(112) }, { 2, UF_KIB(4) },
            { 1, UF_KIB(8) }, { 0, 0 }
        }
    },
    {
        0x95, "CAT28F001B/12V", UF_KIB(128),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 3,
        {
            { 1, UF_KIB(8) }, { 2, UF_KIB(4) },
            { 1, UF_KIB(112) }, { 0, 0 }
        }
    },
    {
        0xB0, "CAT29F(N)002T/5V", UF_KIB(256),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x34, "CAT29F(N)002B/5V", UF_KIB(256),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(32) }, { 3, UF_KIB(64) }
        }
    },
    {
        0x7C, "CAT28F002T/12V", UF_KIB(256),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 4,
        {
            { 1, UF_KIB(128) }, { 1, UF_KIB(96) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x7D, "CAT28F002B/12V", UF_KIB(256),
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(96) }, { 1, UF_KIB(128) }
        }
    },
    {
        0xB4, "CAT28F010/12V", UF_KIB(128),
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING,
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB1, "CAT28F015T/12V", UF_KIB(192),
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING,
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB2, "CAT28F015B/12V", UF_KIB(192),
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING,
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xBD, "CAT28F020/12V", UF_KIB(256),
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING,
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB8, "CAT28F512/12V", UF_KIB(64),
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING,
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    }
};

static const expected_mixed_chip_t expected_winbond_chips[] = {
    {
        0xC8, "W29x512/5V series", UF_KIB(64), 128,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE, UF_FLASH_ERASE_NONE, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xC1, "W29x010/011/012/5V series", UF_KIB(128), 128,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE, UF_FLASH_ERASE_NONE, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x45, "W29C020(C)/022/5V", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE, UF_FLASH_ERASE_NONE, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x46, "W29C040/043/5V", UF_KIB(512), 256,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE, UF_FLASH_ERASE_NONE, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x38, "W39L512/3.3V", UF_KIB(64), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 16, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xA1, "W39F010/5V", UF_KIB(128), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 32, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x31, "W39L010/3.3V", UF_KIB(128), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 32, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB5, "W39L020/3.3V", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 64, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xB6, "W39L040/3.3V", UF_KIB(512), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0xD6, "W39L040A/3.3V", UF_KIB(512), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 8, UF_KIB(64) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x3D, "W39V040A/3.3V (LPC)", UF_KIB(512), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_WINBOND_SECTOR, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x34, "W39V040FA/3.3V (Firmware Hub)", UF_KIB(512), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_WINBOND_FWH, UF_FLASH_ERASE_WINBOND_FWH, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x8C, "W49F020/5V", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_BULK, 0,
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x0B, "W49F002U/5V", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 1, UF_KIB(128) }, { 1, UF_KIB(96) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0xB0, "W49V002(A)/3.3V (LPC)", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x32, "W49V002F(A)/3.3V (Firmware Hub)", UF_KIB(256), 128,
        UF_FLASH_BEHAVIOR_SECTOR,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 3, UF_KIB(64) }, { 1, UF_KIB(32) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    }
};

#define EXPECT_INTEL_BULK(id, name, capacity_kib) \
    { \
        id, name, UF_KIB(capacity_kib), 128, \
        UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING, \
        UF_FLASH_PROGRAM_AMD_FLASH, UF_FLASH_ERASE_AMD_FLASH, 0, \
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }
#define EXPECT_INTEL_SECTOR_1( \
    id, name, capacity_kib, page_size, count_0, size_0 \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, \
        UF_FLASH_BEHAVIOR_SECTOR, \
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 1, \
        { { count_0, UF_KIB(size_0) }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }
#define EXPECT_INTEL_SECTOR_2( \
    id, name, capacity_kib, page_size, count_0, size_0, count_1, size_1 \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, \
        UF_FLASH_BEHAVIOR_SECTOR, \
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 2, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { 0, 0 }, { 0, 0 } \
        } \
    }
#define EXPECT_INTEL_SECTOR_3( \
    id, name, capacity_kib, page_size, \
    count_0, size_0, count_1, size_1, count_2, size_2 \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, \
        UF_FLASH_BEHAVIOR_SECTOR, \
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 3, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { count_2, UF_KIB(size_2) }, { 0, 0 } \
        } \
    }
#define EXPECT_INTEL_SECTOR_4( \
    id, name, capacity_kib, page_size, \
    count_0, size_0, count_1, size_1, count_2, size_2, count_3, size_3 \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, \
        UF_FLASH_BEHAVIOR_SECTOR, \
        UF_FLASH_PROGRAM_INTEL_SECTOR, UF_FLASH_ERASE_INTEL_SECTOR, 4, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { count_2, UF_KIB(size_2) }, { count_3, UF_KIB(size_3) } \
        } \
    }
#define EXPECT_INTEL_FWH(id, name, capacity_kib, count_0, size_0) \
    { \
        id, name, UF_KIB(capacity_kib), 128, \
        UF_FLASH_BEHAVIOR_SECTOR, \
        UF_FLASH_PROGRAM_INTEL_SECTOR_U, UF_FLASH_ERASE_INTEL_SECTOR_U, \
        1, \
        { { count_0, UF_KIB(size_0) }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }

static const expected_mixed_chip_t expected_intel_chips[] = {
    EXPECT_INTEL_BULK(0xB9, "28F256(A)/12V", 32),
    EXPECT_INTEL_BULK(0xB8, "28F512/12V", 64),
    EXPECT_INTEL_BULK(0xB4, "28F010/12V", 128),
    EXPECT_INTEL_BULK(0xBD, "28F020/12V", 256),
    EXPECT_INTEL_SECTOR_3(
        0x94, "28F001BX/BN-T/12V", 128, 128,
        1, 112, 2, 4, 1, 8
    ),
    EXPECT_INTEL_SECTOR_3(
        0x95, "28F001BX/BN-B/12V", 128, 128,
        1, 8, 2, 4, 1, 112
    ),
    EXPECT_INTEL_SECTOR_4(
        0x7C, "28F002-T series (12V/5V)", 256, 128,
        1, 128, 1, 96, 2, 8, 1, 16
    ),
    EXPECT_INTEL_SECTOR_4(
        0x7D, "28F002-B series (12V/5V)", 256, 128,
        1, 16, 2, 8, 1, 96, 1, 128
    ),
    EXPECT_INTEL_SECTOR_4(
        0x78, "28F004-T series (12V/5V)", 512, 128,
        3, 128, 1, 96, 2, 8, 1, 16
    ),
    EXPECT_INTEL_SECTOR_4(
        0x79, "28F004-B series (12V/5V)", 512, 128,
        1, 16, 2, 8, 1, 96, 3, 128
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD4, "28F004B3-T/3V", 512, 128, 7, 64, 8, 8
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD5, "28F004B3-B/3V", 512, 128, 8, 8, 7, 64
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD2, "28F008B3-T/3V", 1024, 128, 15, 64, 8, 8
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD3, "28F008B3-B/3V", 1024, 128, 8, 8, 15, 64
    ),
    EXPECT_INTEL_SECTOR_4(
        0x98, "28F008-T series (5V/3V/2.7V)", 1024, 256,
        7, 128, 1, 96, 2, 8, 1, 16
    ),
    EXPECT_INTEL_SECTOR_4(
        0x99, "28F008-B series (5V/3V/2.7V)", 1024, 256,
        1, 16, 2, 8, 1, 96, 7, 128
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD0, "28F016B3-T/3V", 2048, 128, 31, 64, 8, 8
    ),
    EXPECT_INTEL_SECTOR_2(
        0xD1, "28F016B3-B/3V", 2048, 128, 8, 8, 31, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0xA7, "28F004Sx series (5V/3.3V/2.7V)", 512, 128, 8, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0xA6, "28F008Sx series (5V/3.3V/2.7V)", 1024, 128, 16, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0xA2, "28F008SA/12V", 1024, 128, 16, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0xAA, "28F016Sx series (5V/3.3V/2.7V)", 2048, 128, 32, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0xA0, "28F016S5/SA (5V/3.3V)", 2048, 128, 32, 64
    ),
    EXPECT_INTEL_SECTOR_1(
        0x16, "28F320J3A/3V", 4096, 128, 32, 128
    ),
    EXPECT_INTEL_SECTOR_1(
        0x14, "28F320J5/5V", 4096, 128, 32, 128
    ),
    EXPECT_INTEL_SECTOR_1(
        0x17, "28F640J3A/3V", 8192, 128, 64, 128
    ),
    EXPECT_INTEL_SECTOR_1(
        0x15, "28F640J5/5V", 8192, 128, 64, 128
    ),
    EXPECT_INTEL_SECTOR_1(
        0x18, "28F128J3A/3V", 16384, 128, 128, 128
    ),
    EXPECT_INTEL_FWH(
        0xAD, "82802AB/3.3V (Firmware Hub)", 512, 8, 64
    ),
    EXPECT_INTEL_FWH(
        0xAC, "82802AC/3.3V (Firmware Hub)", 1024, 16, 64
    )
};

#undef EXPECT_INTEL_FWH
#undef EXPECT_INTEL_SECTOR_4
#undef EXPECT_INTEL_SECTOR_3
#undef EXPECT_INTEL_SECTOR_2
#undef EXPECT_INTEL_SECTOR_1
#undef EXPECT_INTEL_BULK

#define EXPECT_SST_NO_GEOMETRY( \
    id, name, capacity_kib, page_size, behavior_value, program_value \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, behavior_value, \
        program_value, UF_FLASH_ERASE_NONE, 0, \
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }
#define EXPECT_SST_SECTOR( \
    id, name, capacity_kib, sector_count, program_value, erase_value \
) \
    { \
        id, name, UF_KIB(capacity_kib), 128, UF_FLASH_BEHAVIOR_SECTOR, \
        program_value, erase_value, 1, \
        { { sector_count, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }

static const expected_mixed_chip_t expected_sst_chips[] = {
    EXPECT_SST_NO_GEOMETRY(
        0x01, "28EE010/011/5V", 128, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x5D, "29EE512/5V", 64, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x3D, "29x512 series (3V/2.7V)", 64, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x20, "29SF512/5V", 64, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x21, "29VF512/2.7V", 64, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x07, "29EE010/5V", 128, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x08, "29x010 series (3V/2.7V)", 128, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x22, "29SF010/5V", 128, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x23, "29VF010/2.7V", 128, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x10, "29EE020/5V", 256, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x12, "29x020 series (3V/2.7V)", 256, 128,
        UF_FLASH_BEHAVIOR_PAGE, UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x24, "29SF020/5V", 256, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x25, "29VF020/2.7V", 256, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x04, "28x040(A) series (5V/3V/2.7V)", 512, 256,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x13, "29SF040/5V", 512, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_NO_GEOMETRY(
        0x14, "29VF040/2.7V", 512, 128,
        UF_FLASH_BEHAVIOR_SMALL_SECTORS, UF_FLASH_PROGRAM_SST_SECTOR2
    ),
    EXPECT_SST_SECTOR(
        0xB4, "39SF512/5V", 64, 16,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD4, "39xF512 series (3V/2.7V)", 64, 16,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xB5, "39SF010(A)/5V", 128, 32,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD5, "39xF010 series (3V/2.7V)", 128, 32,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xB6, "39SF020(A)/5V", 256, 64,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD6, "39xF020 series (3V/2.7V)", 256, 64,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xB7, "39SF040/5V", 512, 128,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD7, "39xF040 series (3V/2.7V)", 512, 128,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD8, "39xF080 series (3V/2.7V)", 1024, 256,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0xD9, "39xF016 series (3V/2.7V)", 2048, 512,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x57, "49LF002(A)/3.3V (Firmware Hub)", 256, 64,
        UF_FLASH_PROGRAM_SST_FWH2, UF_FLASH_ERASE_SST_FWH2
    ),
    EXPECT_SST_SECTOR(
        0x1B, "49LF003A/3.3V (Firmware Hub)", 384, 96,
        UF_FLASH_PROGRAM_SST_FWH, UF_FLASH_ERASE_SST_FWH
    ),
    EXPECT_SST_SECTOR(
        0x58, "49LF004/3.3V (Firmware Hub)", 512, 128,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x60, "49LF004A/B/3.3V (Firmware Hub)", 512, 128,
        UF_FLASH_PROGRAM_SST_FWH, UF_FLASH_ERASE_SST_FWH
    ),
    EXPECT_SST_SECTOR(
        0x59, "49LF008/3.3V (Firmware Hub)", 1024, 256,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x5A, "49LF008A/3.3V (Firmware Hub)", 1024, 256,
        UF_FLASH_PROGRAM_SST_FWH, UF_FLASH_ERASE_SST_FWH
    ),
    EXPECT_SST_SECTOR(
        0x61, "49LF020/3V (LPC)", 256, 64,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x52, "49LF020A/3V (LPC)", 256, 64,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x1C, "49LF030(A)/3V (LPC)", 384, 96,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x51, "49LF040/3V (LPC)", 512, 128,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    ),
    EXPECT_SST_SECTOR(
        0x5B, "49LF080(A)/3V (LPC)", 1024, 256,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR
    )
};

#undef EXPECT_SST_SECTOR
#undef EXPECT_SST_NO_GEOMETRY

#define EXPECT_ATMEL_NO_GEOMETRY( \
    id, name, capacity_kib, page_size, behavior_value, \
    program_value, erase_value \
) \
    { \
        id, name, UF_KIB(capacity_kib), page_size, behavior_value, \
        program_value, erase_value, 0, \
        { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }
#define EXPECT_ATMEL_SECTOR_1( \
    id, name, capacity_kib, program_value, erase_value, count_0, size_0 \
) \
    { \
        id, name, UF_KIB(capacity_kib), 128, UF_FLASH_BEHAVIOR_SECTOR, \
        program_value, erase_value, 1, \
        { { count_0, UF_KIB(size_0) }, { 0, 0 }, { 0, 0 }, { 0, 0 } } \
    }
#define EXPECT_ATMEL_SECTOR_2( \
    id, name, capacity_kib, program_value, erase_value, \
    count_0, size_0, count_1, size_1 \
) \
    { \
        id, name, UF_KIB(capacity_kib), 128, UF_FLASH_BEHAVIOR_SECTOR, \
        program_value, erase_value, 2, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { 0, 0 }, { 0, 0 } \
        } \
    }
#define EXPECT_ATMEL_SECTOR_3( \
    id, name, capacity_kib, program_value, erase_value, \
    count_0, size_0, count_1, size_1, count_2, size_2 \
) \
    { \
        id, name, UF_KIB(capacity_kib), 128, UF_FLASH_BEHAVIOR_SECTOR, \
        program_value, erase_value, 3, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { count_2, UF_KIB(size_2) }, { 0, 0 } \
        } \
    }
#define EXPECT_ATMEL_SECTOR_4( \
    id, name, capacity_kib, program_value, erase_value, \
    count_0, size_0, count_1, size_1, count_2, size_2, count_3, size_3 \
) \
    { \
        id, name, UF_KIB(capacity_kib), 128, UF_FLASH_BEHAVIOR_SECTOR, \
        program_value, erase_value, 4, \
        { \
            { count_0, UF_KIB(size_0) }, { count_1, UF_KIB(size_1) }, \
            { count_2, UF_KIB(size_2) }, { count_3, UF_KIB(size_3) } \
        } \
    }

static const expected_mixed_chip_t expected_atmel_chips[] = {
    EXPECT_ATMEL_NO_GEOMETRY(
        0xDC, "AT29C256/5V or AT29C257/5V", 32, 64,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xBC, "AT29LV256/3V", 32, 64, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x5D, "AT29C512/5V", 64, 128, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x3D, "AT29LV512/3V", 64, 128, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x03, "AT49x512 series (5V/3V/2.7V)", 64, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xD5, "AT29C010(A)/5V", 128, 128, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x17, "AT49x010 series (5V/3V/2.7V)", 128, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x35, "AT29xV010(A) series (3V/2.7V)", 128, 128,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x04, "AT49x001(A)(N)T series (5V/3V/2.7V)", 128, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x05, "AT49x001(A)(N) series (5V/3V/2.7V)", 128, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xDA, "AT29C020(A)/5V", 256, 256, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xBA, "AT29xV020 series (3V/2.7V)", 256, 256,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x0B, "AT49x020 series (5V/3V/2.7V)", 256, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x08, "AT49x002(A)(N)T series (5V/3V/2.7V)", 256, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x07, "AT49x002(A)(N) series (5V/3V/2.7V)", 256, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x82, "AT49x2048(A) series (5V/3V/2.7V)", 256, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_SECTOR_4(
        0xE9, "AT49LH002/3.3V (LPC/FWH)", 256,
        UF_FLASH_PROGRAM_ATMEL_FWH2, UF_FLASH_ERASE_ATMEL_FWH2,
        3, 64, 1, 32, 2, 8, 1, 16
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xA4, "AT29C040A/5V", 512, 256, UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xC4, "AT29xV040A series (3V/2.7V)", 512, 256,
        UF_FLASH_BEHAVIOR_PAGE,
        UF_FLASH_PROGRAM_ATMEL_PAGE, UF_FLASH_ERASE_NONE
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x13, "AT49x040(A) series (5V/3V/2.7V)", 512, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x92, "AT49x4096(A) series (5V/3V/2.7V)", 512, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_SECTOR_4(
        0xED, "AT49LH00B4/3.3V (LPC/FWH)", 512,
        UF_FLASH_PROGRAM_ATMEL_FWH4, UF_FLASH_ERASE_ATMEL_FWH4,
        2, 8, 1, 16, 1, 32, 7, 64
    ),
    EXPECT_ATMEL_SECTOR_4(
        0xEE, "AT49LH004/3.3V (LPC/FWH)", 512,
        UF_FLASH_PROGRAM_ATMEL_FWH3, UF_FLASH_ERASE_ATMEL_FWH3,
        7, 64, 1, 16, 2, 8, 1, 32
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x22, "AT49x008(A) series (5V/2.7V)", 1024, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_SECTOR_3(
        0x21, "AT49x008AT series (5V/2.7V)", 1024,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR,
        1, 992, 2, 8, 1, 16
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x23, "AT49x080 series (5V/3V/2.7V)", 1024, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x27, "AT49x080T series (5V/3V/2.7V)", 1024, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0x4A, "AT49x8011T series (5V/3V/2.7V)", 1024, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_NO_GEOMETRY(
        0xCB, "AT49x8011 series (5V/3V/2.7V)", 1024, 128,
        UF_FLASH_BEHAVIOR_BULK_ERASE,
        UF_FLASH_PROGRAM_ATMEL_BYTE, UF_FLASH_ERASE_ATMEL_BULK
    ),
    EXPECT_ATMEL_SECTOR_1(
        0xE1, "AT49LW080/3.3V (Firmware Hub)", 1024,
        UF_FLASH_PROGRAM_ATMEL_FWH, UF_FLASH_ERASE_ATMEL_FWH, 16, 64
    ),
    EXPECT_ATMEL_SECTOR_2(
        0xC2, "AT49x160/161(4)T series (5V/3V)", 2048,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR,
        31, 64, 8, 8
    ),
    EXPECT_ATMEL_SECTOR_2(
        0xC0, "AT49x160/161(4) series (5V/3V)", 2048,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR,
        8, 8, 31, 64
    ),
    EXPECT_ATMEL_SECTOR_2(
        0xC9, "AT49BV320T/321T/3V", 4096,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR,
        63, 64, 8, 8
    ),
    EXPECT_ATMEL_SECTOR_2(
        0xC8, "AT49BV320/321/3V", 4096,
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR,
        8, 8, 63, 64
    )
};

#undef EXPECT_ATMEL_SECTOR_4
#undef EXPECT_ATMEL_SECTOR_3
#undef EXPECT_ATMEL_SECTOR_2
#undef EXPECT_ATMEL_SECTOR_1
#undef EXPECT_ATMEL_NO_GEOMETRY

static const expected_pmc_chip_t expected_pmc_chips[] = {
    {
        0x1D, "Pm29F002T/5V", UF_KIB(256),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 1, UF_KIB(128) }, { 1, UF_KIB(96) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x2D, "Pm29F002B/5V", UF_KIB(256),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(96) }, { 1, UF_KIB(128) }
        }
    },
    {
        0x1E, "Pm29F004T/5V or Pm29LV104T/3.3V", UF_KIB(512),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 3, UF_KIB(128) }, { 1, UF_KIB(96) },
            { 2, UF_KIB(8) }, { 1, UF_KIB(16) }
        }
    },
    {
        0x2E, "Pm29F004B/5V or Pm29LV104B/3.3V", UF_KIB(512),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 4,
        {
            { 1, UF_KIB(16) }, { 2, UF_KIB(8) },
            { 1, UF_KIB(96) }, { 3, UF_KIB(128) }
        }
    },
    {
        0x1B, "Pm39LV512(R)/3.3V", UF_KIB(64),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 16, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x1C, "Pm39F010/5V or Pm39LV010(R)/3.3V", UF_KIB(128),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 32, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x3D, "Pm39LV020/3.3V", UF_KIB(256),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 64, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x4D, "Pm39F020/5V", UF_KIB(256),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 64, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x3E, "Pm39LV040/3.3V", UF_KIB(512),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x4E, "Pm39F040/5V", UF_KIB(512),
        UF_FLASH_PROGRAM_AMD_SECTOR, UF_FLASH_ERASE_AMD_SECTOR, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x6D, "Pm49FL002/3.3V (LPC/FWH)", UF_KIB(256),
        UF_FLASH_PROGRAM_PMC_FWH2, UF_FLASH_ERASE_PMC_FWH2, 1,
        { { 64, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x6E, "Pm49FL004/3.3V (LPC/FWH)", UF_KIB(512),
        UF_FLASH_PROGRAM_PMC_FWH, UF_FLASH_ERASE_PMC_FWH, 1,
        { { 128, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    },
    {
        0x6A, "Pm49FL008/3.3V (LPC/FWH)", UF_KIB(1024),
        UF_FLASH_PROGRAM_PMC_FWH, UF_FLASH_ERASE_PMC_FWH, 1,
        { { 256, UF_KIB(4) }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    }
};

static void assert_sharp_chip(
    const uf_flash_manufacturer_t *manufacturer,
    uint8_t device_id,
    const char *name,
    uf_rom_size_t capacity_bytes,
    uint8_t region_count,
    const uf_flash_sector_region_t *regions
)
{
    const uf_flash_chip_t *chip;
    uint8_t index;

    chip = uf_rom_find_chip(manufacturer, device_id);
    assert(chip != NULL);
    assert(strcmp(chip->name, name) == 0);
    assert(chip->capacity_bytes == capacity_bytes);
    assert(chip->page_size_bytes == 128);
    assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_SHARP_SECTOR);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_SHARP_SECTOR);
    assert(chip->sector_region_count == region_count);
    for (index = 0; index < region_count; ++index) {
        assert(
            chip->sector_regions[index].sector_count
            == regions[index].sector_count
        );
        assert(
            chip->sector_regions[index].sector_size_bytes
            == regions[index].sector_size_bytes
        );
    }
}

static void fingerprint_byte(uint32_t *fingerprint, uint8_t value)
{
    *fingerprint ^= value;
    *fingerprint *= UINT32_C(16777619);
}

static void fingerprint_u16(uint32_t *fingerprint, uint16_t value)
{
    fingerprint_byte(fingerprint, (uint8_t)value);
    fingerprint_byte(fingerprint, (uint8_t)(value >> 8));
}

static void fingerprint_u32(uint32_t *fingerprint, uint32_t value)
{
    fingerprint_u16(fingerprint, (uint16_t)value);
    fingerprint_u16(fingerprint, (uint16_t)(value >> 16));
}

static uint32_t manufacturer_fingerprint(
    const uf_flash_manufacturer_t *manufacturer
)
{
    uint32_t fingerprint = UINT32_C(2166136261);
    uint16_t chip_index;

    for (chip_index = 0; chip_index < manufacturer->chip_count; ++chip_index) {
        const uf_flash_chip_t *chip = &manufacturer->chips[chip_index];
        const char *name = chip->name;
        uint8_t region_index;

        fingerprint_byte(&fingerprint, chip->device_id);
        do {
            fingerprint_byte(&fingerprint, (uint8_t)*name);
        } while (*name++ != '\0');
        fingerprint_byte(&fingerprint, chip->behavior);
        fingerprint_byte(&fingerprint, chip->program_algorithm);
        fingerprint_byte(&fingerprint, chip->erase_algorithm);
        fingerprint_u16(&fingerprint, chip->page_size_bytes);
        fingerprint_u32(&fingerprint, chip->capacity_bytes);
        fingerprint_byte(&fingerprint, chip->sector_region_count);
        for (region_index = 0;
             region_index < UF_FLASH_MAX_SECTOR_REGIONS;
             ++region_index) {
            fingerprint_u16(
                &fingerprint,
                chip->sector_regions[region_index].sector_count
            );
            fingerprint_u32(
                &fingerprint,
                chip->sector_regions[region_index].sector_size_bytes
            );
        }
    }
    return fingerprint;
}

int main(void)
{
    const uf_flash_manufacturer_t *manufacturer;
    const uf_flash_chip_t *chip;
    const uf_flash_sector_region_t sharp_1m_regions[] = {
        { 15, UF_KIB(64) },
        { 8, UF_KIB(8) }
    };
    const uf_flash_sector_region_t sharp_2m_regions[] = {
        { 16, UF_KIB(4) },
        { 30, UF_KIB(64) },
        { 8, UF_KIB(8) }
    };
    uint16_t index;

    assert(uf_rom_database_validate() == UF_TRUE);
    assert(uf_rom_manufacturer_count == 19);

    manufacturer = uf_rom_find_manufacturer(0x97);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Texas Instruments") == 0);
    assert(manufacturer->chip_count == 1);

    chip = uf_rom_find_chip(manufacturer, 0x94);
    assert(chip != NULL);
    assert(strcmp(chip->name, "TMS29xF040 (3.3/2.7V)") == 0);
    assert(chip->capacity_bytes == UF_KIB(512));
    assert(chip->page_size_bytes == 128);
    assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
    assert(chip->sector_region_count == 1);
    assert(chip->sector_regions[0].sector_count == 8);
    assert(chip->sector_regions[0].sector_size_bytes == UF_KIB(64));

    manufacturer = uf_rom_find_manufacturer(0xD5);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "ISSI") == 0);
    assert(manufacturer->chip_count == 2);

    chip = uf_rom_find_chip(manufacturer, 0xB4);
    assert(chip != NULL);
    assert(strcmp(chip->name, "IS28F010/12V") == 0);
    assert(chip->capacity_bytes == UF_KIB(128));
    assert(chip->page_size_bytes == 128);
    assert(
        chip->behavior == UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING
    );
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_FLASH);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_FLASH);
    assert(chip->sector_region_count == 0);

    chip = uf_rom_find_chip(manufacturer, 0xBD);
    assert(chip != NULL);
    assert(strcmp(chip->name, "IS28F020/12V") == 0);
    assert(chip->capacity_bytes == UF_KIB(256));
    assert(chip->page_size_bytes == 128);
    assert(
        chip->behavior == UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING
    );
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_FLASH);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_FLASH);
    assert(chip->sector_region_count == 0);

    manufacturer = uf_rom_find_manufacturer(0x7F);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "IMT") == 0);
    assert(manufacturer->chip_count == 10);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_uniform_sector_chip_t *expected =
            &expected_imt_chips[index];

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == 1);
        assert(
            chip->sector_regions[0].sector_count == expected->sector_count
        );
        assert(
            chip->sector_regions[0].sector_size_bytes
            == expected->sector_size_bytes
        );
    }

    manufacturer = uf_rom_find_manufacturer(0xB0);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "SHARP") == 0);
    assert(manufacturer->chip_count == 3);

    assert_sharp_chip(
        manufacturer,
        0xC9,
        "LHF00L02/6/7/3.3V (LPC)",
        UF_KIB(1024),
        2,
        sharp_1m_regions
    );
    assert_sharp_chip(
        manufacturer,
        0xCF,
        "LHF00L03/4/5/3.3V (FWH)",
        UF_KIB(1024),
        2,
        sharp_1m_regions
    );
    assert_sharp_chip(
        manufacturer,
        0xCA,
        "LHF00L01/3.3V (LPC)",
        UF_KIB(2048),
        3,
        sharp_2m_regions
    );

    manufacturer = uf_rom_find_manufacturer(0x52);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Alliance") == 0);
    assert(manufacturer->chip_count == 9);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_sector_chip_t *expected =
            &expected_alliance_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }
    assert(uf_rom_find_chip(manufacturer, 0x04) == NULL);

    manufacturer = uf_rom_find_manufacturer(0x04);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Fujitsu") == 0);
    assert(manufacturer->chip_count == 12);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_sector_chip_t *expected =
            &expected_fujitsu_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x40);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Mosel Vitelic") == 0);
    assert(manufacturer->chip_count == 17);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_uniform_sector_chip_t *expected =
            &expected_mosel_chips[index];

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == 1);
        assert(
            chip->sector_regions[0].sector_count == expected->sector_count
        );
        assert(
            chip->sector_regions[0].sector_size_bytes
            == expected->sector_size_bytes
        );
    }

    manufacturer = uf_rom_find_manufacturer(0xAD);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Hyundai") == 0);
    assert(manufacturer->chip_count == 11);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_sector_chip_t *expected =
            &expected_hyundai_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x31);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Catalyst") == 0);
    assert(manufacturer->chip_count == 13);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_catalyst_chip_t *expected =
            &expected_catalyst_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == expected->behavior);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0xDA);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Winbond") == 0);
    assert(manufacturer->chip_count == 16);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_mixed_chip_t *expected =
            &expected_winbond_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == expected->page_size_bytes);
        assert(chip->behavior == expected->behavior);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x1C);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "EON") == 0);
    assert(manufacturer->chip_count == 17);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_sector_chip_t *expected = &expected_eon_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x9D);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "PMC") == 0);
    assert(manufacturer->chip_count == 13);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_pmc_chip_t *expected = &expected_pmc_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x37);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "AMIC") == 0);
    assert(manufacturer->chip_count == 17);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_sector_chip_t *expected = &expected_amic_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == 128);
        assert(chip->behavior == UF_FLASH_BEHAVIOR_SECTOR);
        assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_SECTOR);
        assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_SECTOR);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x89);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Intel") == 0);
    assert(manufacturer->chip_count == 30);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_mixed_chip_t *expected =
            &expected_intel_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == expected->page_size_bytes);
        assert(chip->behavior == expected->behavior);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0xBF);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "SST") == 0);
    assert(manufacturer->chip_count == 37);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_mixed_chip_t *expected = &expected_sst_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == expected->page_size_bytes);
        assert(chip->behavior == expected->behavior);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x1F);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Atmel") == 0);
    assert(manufacturer->chip_count == 34);

    for (index = 0; index < manufacturer->chip_count; ++index) {
        const expected_mixed_chip_t *expected =
            &expected_atmel_chips[index];
        uint8_t region_index;

        chip = uf_rom_find_chip(manufacturer, expected->device_id);
        assert(chip != NULL);
        assert(strcmp(chip->name, expected->name) == 0);
        assert(chip->capacity_bytes == expected->capacity_bytes);
        assert(chip->page_size_bytes == expected->page_size_bytes);
        assert(chip->behavior == expected->behavior);
        assert(chip->program_algorithm == expected->program_algorithm);
        assert(chip->erase_algorithm == expected->erase_algorithm);
        assert(chip->sector_region_count == expected->region_count);
        for (region_index = 0;
             region_index < expected->region_count;
             ++region_index) {
            assert(
                chip->sector_regions[region_index].sector_count
                == expected->regions[region_index].sector_count
            );
            assert(
                chip->sector_regions[region_index].sector_size_bytes
                == expected->regions[region_index].sector_size_bytes
            );
        }
    }

    manufacturer = uf_rom_find_manufacturer(0x20);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "STMicroelectronics") == 0);
    assert(manufacturer->chip_count == 49);
    assert(manufacturer_fingerprint(manufacturer) == UINT32_C(0xCEB2A243));

    chip = uf_rom_find_chip(manufacturer, 0xC4);
    assert(chip != NULL);
    assert(strcmp(chip->name, "M29W160BT/DT/3V") == 0);
    assert(chip->capacity_bytes == UF_KIB(2048));

    chip = uf_rom_find_chip(manufacturer, 0x29);
    assert(chip != NULL);
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_ST_SECTOR_B);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_ST_SECTOR_B);

    chip = uf_rom_find_chip(manufacturer, 0x80);
    assert(chip != NULL);
    assert(
        chip->program_algorithm == UF_FLASH_PROGRAM_ST_SECTOR_A_VARIANT
    );
    assert(chip->erase_algorithm == UF_FLASH_ERASE_ST_SECTOR_A_VARIANT);

    chip = uf_rom_find_chip(manufacturer, 0x81);
    assert(chip != NULL);
    assert(
        chip->program_algorithm == UF_FLASH_PROGRAM_ST_SECTOR_B_VARIANT
    );
    assert(chip->erase_algorithm == UF_FLASH_ERASE_ST_SECTOR_B_VARIANT);

    manufacturer = uf_rom_find_manufacturer(0xC2);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "Macronix") == 0);
    assert(manufacturer->chip_count == 41);
    assert(manufacturer_fingerprint(manufacturer) == UINT32_C(0x6F16B1C3));

    chip = uf_rom_find_chip(manufacturer, 0x18);
    assert(chip != NULL);
    assert(chip->sector_region_count == 5);
    assert(chip->sector_regions[4].sector_count == 1);
    assert(chip->sector_regions[4].sector_size_bytes == UF_KIB(8));

    chip = uf_rom_find_chip(manufacturer, 0x37);
    assert(chip != NULL);
    assert(strcmp(chip->name, "MX29F022B/5V") == 0);

    chip = uf_rom_find_chip(manufacturer, 0xF8);
    assert(chip != NULL);
    assert(
        chip->program_algorithm == UF_FLASH_PROGRAM_MACRONIX_SECTOR_PAGE
    );
    assert(
        chip->erase_algorithm == UF_FLASH_ERASE_MACRONIX_SECTOR_PAGE
    );

    chip = uf_rom_find_chip(manufacturer, 0x6B);
    assert(chip != NULL);
    assert(chip->behavior == UF_FLASH_BEHAVIOR_BULK_ERASE);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_MACRONIX_BULK);

    manufacturer = uf_rom_find_manufacturer(0x01);
    assert(manufacturer != NULL);
    assert(strcmp(manufacturer->name, "AMD") == 0);
    assert(manufacturer->chip_count == 59);
    assert(manufacturer_fingerprint(manufacturer) == UINT32_C(0x2DC69860));

    chip = uf_rom_find_chip(manufacturer, 0xA1);
    assert(chip != NULL);
    assert(
        chip->behavior == UF_FLASH_BEHAVIOR_BULK_ERASE_WITH_BLANKING
    );
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_FLASH);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_FLASH);

    chip = uf_rom_find_chip(manufacturer, 0xA2);
    assert(chip != NULL);
    assert(chip->behavior == UF_FLASH_BEHAVIOR_BULK_ERASE);
    assert(chip->program_algorithm == UF_FLASH_PROGRAM_AMD_EMBEDDED);
    assert(chip->erase_algorithm == UF_FLASH_ERASE_AMD_EMBEDDED);

    chip = uf_rom_find_chip(manufacturer, 0x45);
    assert(chip != NULL);
    assert(strcmp(chip->name, "Am29PL160CB/3V") == 0);
    assert(chip->sector_region_count == 4);
    assert(chip->sector_regions[2].sector_size_bytes == UF_KIB(224));
    assert(chip->sector_regions[3].sector_size_bytes == UF_KIB(256));

    chip = uf_rom_find_chip(manufacturer, 0x93);
    assert(chip != NULL);
    assert(chip->capacity_bytes == UF_KIB(8192));
    assert(chip->sector_regions[0].sector_count == 128);

    assert(uf_rom_find_manufacturer(0x00) == NULL);
    assert(uf_rom_find_chip(manufacturer, 0xFF) == NULL);
    assert(uf_rom_find_chip(NULL, 0x94) == NULL);
    return 0;
}
