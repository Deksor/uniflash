#include <string.h>

#include "uniflash/xms.h"

#if defined(UF_TARGET_DOS16)

static uf_bool_t find_xms_entry(uint32_t *entry_point)
{
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
        return UF_FALSE;
    }
    *entry_point =
        ((uint32_t)entry_segment << 16) | (uint32_t)entry_offset;
    return UF_TRUE;
}

static uf_bool_t query_largest_block(
    uint32_t entry_point,
    uint16_t *size_kib
)
{
    uint16_t largest = 0;

    _asm {
        mov ah,08h                 /* Query free extended memory */
        call dword ptr entry_point
        mov largest,ax
    }
    *size_kib = largest;
    return largest != 0 ? UF_TRUE : UF_FALSE;
}

static uf_bool_t allocate_block(
    uint32_t entry_point,
    uint16_t size_kib,
    uint16_t *handle
)
{
    uint16_t result = 0;
    uint16_t allocated_handle = 0;

    _asm {
        mov dx,size_kib
        mov ah,09h                 /* Allocate extended-memory block */
        call dword ptr entry_point
        mov result,ax
        mov allocated_handle,dx
    }
    *handle = allocated_handle;
    return result == 1 ? UF_TRUE : UF_FALSE;
}

static uf_bool_t lock_block(
    uint32_t entry_point,
    uint16_t handle,
    uf_phys_addr_t *linear_base
)
{
    uint16_t result = 0;
    uint16_t address_low = 0;
    uint16_t address_high = 0;

    _asm {
        mov dx,handle
        mov ah,0ch                 /* Lock extended-memory block */
        call dword ptr entry_point
        mov result,ax
        mov address_low,bx
        mov address_high,dx
    }
    *linear_base =
        ((uint32_t)address_high << 16) | (uint32_t)address_low;
    return result == 1 ? UF_TRUE : UF_FALSE;
}

static uf_bool_t xms_simple_call(
    uint32_t entry_point,
    uint16_t handle,
    uint8_t function
)
{
    uint16_t result = 0;

    _asm {
        mov dx,handle
        mov ah,function
        call dword ptr entry_point
        mov result,ax
    }
    return result == 1 ? UF_TRUE : UF_FALSE;
}

uf_bool_t uf_xms_init(uf_xms_t *xms)
{
    uint16_t size_kib;

    if (xms == NULL) {
        return UF_FALSE;
    }
    memset(xms, 0, sizeof(*xms));
    if (
        !find_xms_entry(&xms->entry_point)
        || !query_largest_block(xms->entry_point, &size_kib)
        || !allocate_block(xms->entry_point, size_kib, &xms->handle)
    ) {
        memset(xms, 0, sizeof(*xms));
        return UF_FALSE;
    }
    xms->allocated = UF_TRUE;
    if (!lock_block(
        xms->entry_point, xms->handle, &xms->linear_base
    )) {
        (void)xms_simple_call(xms->entry_point, xms->handle, 0x0A);
        memset(xms, 0, sizeof(*xms));
        return UF_FALSE;
    }
    xms->locked = UF_TRUE;
    if (!xms_simple_call(xms->entry_point, 0, 0x03)) {
        (void)uf_xms_shutdown(xms);
        return UF_FALSE;
    }
    xms->a20_enabled = UF_TRUE;
    xms->size_bytes = (uf_rom_size_t)size_kib << 10;
    return UF_TRUE;
}

uf_bool_t uf_xms_shutdown(uf_xms_t *xms)
{
    uf_bool_t result = UF_TRUE;

    if (xms == NULL) {
        return UF_FALSE;
    }
    if (
        xms->locked
        && !xms_simple_call(xms->entry_point, xms->handle, 0x0D)
    ) {
        result = UF_FALSE;
    }
    if (
        xms->allocated
        && !xms_simple_call(xms->entry_point, xms->handle, 0x0A)
    ) {
        result = UF_FALSE;
    }
    if (
        xms->a20_enabled
        && !xms_simple_call(xms->entry_point, 0, 0x04)
    ) {
        result = UF_FALSE;
    }
    memset(xms, 0, sizeof(*xms));
    return result;
}

#else

uf_bool_t uf_xms_init(uf_xms_t *xms)
{
    if (xms != NULL) {
        memset(xms, 0, sizeof(*xms));
    }
    return UF_FALSE;
}

uf_bool_t uf_xms_shutdown(uf_xms_t *xms)
{
    if (xms == NULL) {
        return UF_FALSE;
    }
    memset(xms, 0, sizeof(*xms));
    return UF_TRUE;
}

#endif
