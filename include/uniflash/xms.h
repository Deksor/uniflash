#ifndef UNIFLASH_XMS_H
#define UNIFLASH_XMS_H

#include "uniflash/types.h"

/*
 * The XMS block is locked for its lifetime.  Its linear address can therefore
 * be accessed through the flat-real-mode hardware interface just like the
 * OldBIOS and NewBIOS linear blocks in the Pascal program.
 */
typedef struct uf_xms {
    uint32_t entry_point;
    uf_phys_addr_t linear_base;
    uf_rom_size_t size_bytes;
    uint16_t handle;
    uf_bool_t allocated;
    uf_bool_t locked;
    uf_bool_t a20_enabled;
} uf_xms_t;

uf_bool_t uf_xms_init(uf_xms_t *xms);
uf_bool_t uf_xms_shutdown(uf_xms_t *xms);

#endif
