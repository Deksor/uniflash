#include <string.h>

#include "uniflash/ct_flasher.h"

static bool ct_select_bank(void *context, uint8_t bank) {
    uf_ct_flasher_t *flasher = context;

    if (!flasher->size_512k) {
        bank |= UINT8_C(0x80);
    }
    return flasher->hardware->out8(flasher->hardware->context, flasher->port, bank);
}

static bool port_is_ct_flasher(const uf_hardware_t *hardware, uf_io_port_t port, uint8_t *status) {
    uint8_t value;

    if (!hardware->in8(hardware->context, port, &value) || (value & UINT8_C(0xC7)) != UINT8_C(0x80) ||
        !hardware->out8(hardware->context, port, UINT8_C(0)) || !hardware->in8(hardware->context, port, &value) ||
        (value & UINT8_C(0xC7)) != UINT8_C(0x80)) {
        return false;
    }
    *status = value;
    return true;
}

bool uf_ct_flasher_detect(uf_ct_flasher_t *flasher,
    const uf_hardware_t *hardware,
    uf_io_port_t requested_port,
    bool size_512k) {
    uf_io_port_t port = requested_port;
    uint8_t status = 0;

    if (flasher == NULL || !uf_hardware_is_valid(hardware)) {
        return false;
    }
    memset(flasher, 0, sizeof(*flasher));
    if (port == 0) {
        for (port = UINT16_C(0x200); port < UINT16_C(0x400); port += 4) {
            if (port_is_ct_flasher(hardware, port, &status)) {
                break;
            }
        }
        if (port >= UINT16_C(0x400)) {
            return false;
        }
    } else if (!port_is_ct_flasher(hardware, port, &status)) {
        return false;
    }

    flasher->hardware = hardware;
    flasher->port = port;
    flasher->window_base = UINT32_C(0xC0000) + ((uf_phys_addr_t)(status & UINT8_C(0x38)) << 11);
    flasher->size_512k = size_512k;
    if (!uf_system_flash_backend_init(&flasher->backend, hardware, flasher->window_base) ||
        !uf_system_flash_backend_set_banking(&flasher->backend,
            UINT32_C(2048),
            flasher->window_base,
            ct_select_bank,
            flasher)) {
        memset(flasher, 0, sizeof(*flasher));
        return false;
    }
    return true;
}

bool uf_ct_flasher_make_access(uf_ct_flasher_t *flasher, uf_flash_access_t *access) {
    if (flasher == NULL || flasher->hardware == NULL) {
        return false;
    }
    return uf_system_flash_backend_make_access(&flasher->backend, access);
}
