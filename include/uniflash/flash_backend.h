#ifndef UNIFLASH_FLASH_BACKEND_H
#define UNIFLASH_FLASH_BACKEND_H

#include "uniflash/flash_service.h"
#include "uniflash/hardware.h"

typedef uf_bool_t (*uf_flash_bank_select_fn)(
    void *context,
    uint8_t bank
);
typedef uf_bool_t (*uf_flash_shadow_control_fn)(
    void *context,
    uf_bool_t disable
);

typedef struct uf_system_flash_backend {
    const uf_hardware_t *hardware;
    uf_phys_addr_t rom_base;
    uf_rom_size_t bank_size;
    uf_phys_addr_t write_base;
    void *bank_context;
    uf_flash_bank_select_fn select_bank;
    void *shadow_context;
    uf_flash_shadow_control_fn control_shadow;
    uint8_t current_bank;
    uf_bool_t bank_selected;
} uf_system_flash_backend_t;

uf_bool_t uf_system_flash_backend_init(
    uf_system_flash_backend_t *backend,
    const uf_hardware_t *hardware,
    uf_phys_addr_t rom_base
);
uf_bool_t uf_system_flash_backend_set_banking(
    uf_system_flash_backend_t *backend,
    uf_rom_size_t bank_size,
    uf_phys_addr_t write_base,
    uf_flash_bank_select_fn select_bank,
    void *bank_context
);
uf_bool_t uf_system_flash_backend_set_shadow_control(
    uf_system_flash_backend_t *backend,
    uf_flash_shadow_control_fn control_shadow,
    void *shadow_context
);
uf_bool_t uf_system_flash_backend_make_access(
    uf_system_flash_backend_t *backend,
    uf_flash_access_t *access
);

#endif
