#ifndef UNIFLASH_CMOS_H
#define UNIFLASH_CMOS_H

#include "uniflash/hardware.h"

#define UF_CMOS_FIRST_SAVED_INDEX UINT8_C(0x0E)
#define UF_CMOS_MAX_SAVED_BYTES UINT16_C(242)

uf_bool_t uf_cmos_detect_last_index(
    const uf_hardware_t *hardware,
    uint8_t *last_index
);
uf_bool_t uf_cmos_read(
    const uf_hardware_t *hardware,
    uint8_t last_index,
    uint8_t *data,
    uint16_t capacity,
    uint16_t *size_bytes
);
uf_bool_t uf_cmos_save_file(
    const uf_hardware_t *hardware,
    uint8_t last_index,
    const char *path
);

#endif
