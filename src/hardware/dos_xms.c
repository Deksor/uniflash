#include <string.h>

#include "uniflash/xms.h"

#if defined(UF_TARGET_DOS16)

static bool find_xms_entry(uint32_t *entry_point) {
    uint16_t available = 0;
    uint16_t entry_offset = 0;
    uint16_t entry_segment = 0;

    _asm {
        mov ax,4300h
        int 2fh
        cmp al,80h
        jne no_xms_entry
        mov ax,4310h
        int 2fh
        mov available,1
        mov entry_offset,bx
        mov entry_segment,es
    no_xms_entry:
    }
    if (!available) {
        return false;
    }
    *entry_point = ((uint32_t)entry_segment << 16) | (uint32_t)entry_offset;
    return true;
}

static bool query_largest_block(uint32_t entry_point, uint16_t *size_kib) {
    uint16_t largest = 0;

    _asm {
        mov ah,08h /* Query free extended memory */
        call dword ptr entry_point
        mov largest,ax
    }
    *size_kib = largest;
    return largest != 0;
}

static bool allocate_block(uint32_t entry_point, uint16_t size_kib, uint16_t *handle) {
    uint16_t result = 0;
    uint16_t allocated_handle = 0;

    _asm {
        mov dx,size_kib
        mov ah,09h /* Allocate extended-memory block */
        call dword ptr entry_point
        mov result,ax
        mov allocated_handle,dx
    }
    *handle = allocated_handle;
    return result == 1;
}

static bool lock_block(uint32_t entry_point, uint16_t handle, uf_phys_addr_t *linear_base) {
    uint16_t result = 0;
    uint16_t address_low = 0;
    uint16_t address_high = 0;

    _asm {
        mov dx,handle
        mov ah,0ch /* Lock extended-memory block */
        call dword ptr entry_point
        mov result,ax
        mov address_low,bx
        mov address_high,dx
    }
    *linear_base = ((uint32_t)address_high << 16) | (uint32_t)address_low;
    return result == 1;
}

static bool xms_simple_call(uint32_t entry_point, uint16_t handle, uint8_t function) {
    uint16_t result = 0;

    _asm {
        mov dx,handle
        mov ah,function
        call dword ptr entry_point
        mov result,ax
    }
    return result == 1;
}

bool uf_xms_init(uf_xms_t *xms) {
    uint16_t size_kib;

    if (xms == NULL) {
        return false;
    }
    memset(xms, 0, sizeof(*xms));
    if (!find_xms_entry(&xms->entry_point) || !query_largest_block(xms->entry_point, &size_kib) ||
        !allocate_block(xms->entry_point, size_kib, &xms->handle)) {
        memset(xms, 0, sizeof(*xms));
        return false;
    }
    xms->allocated = true;
    if (!lock_block(xms->entry_point, xms->handle, &xms->linear_base)) {
        (void)xms_simple_call(xms->entry_point, xms->handle, 0x0A);
        memset(xms, 0, sizeof(*xms));
        return false;
    }
    xms->locked = true;
    if (!xms_simple_call(xms->entry_point, 0, 0x03)) {
        (void)uf_xms_shutdown(xms);
        return false;
    }
    xms->a20_enabled = true;
    xms->size_bytes = (uf_rom_size_t)size_kib << 10;
    return true;
}

bool uf_xms_shutdown(uf_xms_t *xms) {
    bool result = true;

    if (xms == NULL) {
        return false;
    }
    if (xms->locked && !xms_simple_call(xms->entry_point, xms->handle, 0x0D)) {
        result = false;
    }
    if (xms->allocated && !xms_simple_call(xms->entry_point, xms->handle, 0x0A)) {
        result = false;
    }
    if (xms->a20_enabled && !xms_simple_call(xms->entry_point, 0, 0x04)) {
        result = false;
    }
    memset(xms, 0, sizeof(*xms));
    return result;
}

#else

bool uf_xms_init(uf_xms_t *xms) {
    if (xms != NULL) {
        memset(xms, 0, sizeof(*xms));
    }
    return false;
}

bool uf_xms_shutdown(uf_xms_t *xms) {
    if (xms == NULL) {
        return false;
    }
    memset(xms, 0, sizeof(*xms));
    return true;
}

#endif
