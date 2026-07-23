# Flash ROM definitions

This directory will contain one declarative `.def` file per manufacturer.
Executable programming and erase routines belong under `src/flash/`, not in
these data files.

Each manufacturer file uses three macros:

```c
UF_ROM_BEGIN(symbol, manufacturer_id, "Manufacturer name")

UF_ROM_CHIP(
    device_id,
    "Chip name",
    capacity_bytes,
    page_size_bytes,
    behavior,
    program_algorithm,
    erase_algorithm,
    region_count,
    region_0_count, region_0_size_bytes,
    region_1_count, region_1_size_bytes,
    region_2_count, region_2_size_bytes,
    region_3_count, region_3_size_bytes,
    region_4_count, region_4_size_bytes
)

UF_ROM_END()
```

Rules:

- Capacities and sector sizes are stored in bytes, using `UF_KIB()` where
  useful.
- Unused sector regions are written as `0, 0`.
- A chip may have at most five sector regions, matching the Pascal record.
- Behavior and algorithm names come from `uniflash/flash_chip.h`.
- Definitions are compiled into the executable; they are not parsed at
  runtime.
- A manufacturer file is added only after its Pascal definitions have been
  translated and checked individually.
- Each checked manufacturer file is included once by `catalog.def`.
