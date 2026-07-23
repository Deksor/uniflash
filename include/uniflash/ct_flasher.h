#ifndef UNIFLASH_CT_FLASHER_H
#define UNIFLASH_CT_FLASHER_H

#include "uniflash/flash_backend.h"

typedef struct uf_ct_flasher {
    const uf_hardware_t *hardware;
    uf_io_port_t port;
    uf_phys_addr_t window_base;
    uf_bool_t size_512k;
    uf_system_flash_backend_t backend;
} uf_ct_flasher_t;

uf_bool_t uf_ct_flasher_detect(
    uf_ct_flasher_t *flasher,
    const uf_hardware_t *hardware,
    uf_io_port_t requested_port,
    uf_bool_t size_512k
);
uf_bool_t uf_ct_flasher_make_access(
    uf_ct_flasher_t *flasher,
    uf_flash_access_t *access
);

#endif
