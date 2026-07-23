#include <string.h>

#include "uniflash/hardware.h"

#if defined(UF_TARGET_DOS16)

static uint16_t dos_flat_gdt[8];

static bool dos_flat_real_on(void)
{
    bool result;

    result = false;
    _asm {
        /* check for protected (V86) mode */
        smsw ax
        test al,1
        jnz flat_done

            /* switch to flat real mode */
        db 66h
        mov bx,ds /* EBX=DS */
        db 66h
        shl bx,4 /* EBX=DS*16 */
        db 66h
        mov si,offset dos_flat_gdt
        dw 0 /* ESI=OFFSET dos_flat_gdt */
        db 66h
        add bx,si /* EBX=linear addr of dos_flat_gdt structure */
        mov word ptr dos_flat_gdt[0],10h /* GDT limit */
        mov word ptr dos_flat_gdt[2],bx /* GDT linear addr lo */
        db 66h
        shr bx,16 /* BX=Hi(EBX) */
        mov word ptr dos_flat_gdt[4],bx /* GDT linear addr hi */
        xor dx,dx
        mov word ptr dos_flat_gdt[10],dx /* segment base bits 0-15 */
        dec dx
        mov word ptr dos_flat_gdt[8],dx /* segment limit bits 0..15 (actually 12-27) */
        mov word ptr dos_flat_gdt[12],09200h /* segment base bits 16-23, R/W,DT1,DPL0,P=1 */
        mov word ptr dos_flat_gdt[14],008fh     /* segment limit bits 16-19 (actually 28-31);
D=0,G=1(4K), segment base bits 24-31 */
        lgdt fword ptr dos_flat_gdt /* Load GDTR */
        inc ax /* PM on */
        cli
        lmsw ax /* switch to PM */
        mov bx,8 /* flat segment */
        mov es,bx /* ES=flat. NOTE:DS=flat->error??!! */
        mov eax,cr0
        dec ax /* PM off */
        mov cr0,eax
        sti
        mov result,1
    flat_done:
    }
    return result;
}

static uint8_t dos_in8_raw(uint16_t port);
#pragma aux dos_in8_raw = \
    "in al,dx" parm[dx] value[al] modify exact[al];

static uint16_t dos_in16_raw(uint16_t port);
#pragma aux dos_in16_raw = \
    "in ax,dx" parm[dx] value[ax] modify exact[ax];

static uint32_t dos_in32_raw(uint16_t port);
#pragma aux dos_in32_raw = \
    "in eax,dx"            \
    "mov edx,eax"          \
    "shr edx,16" parm[dx] value[dx ax] modify exact[ax dx];

static void dos_out8_raw(uint16_t port, uint8_t value);
#pragma aux dos_out8_raw = \
    "out dx,al" parm[dx][al] modify exact[];

static void dos_out16_raw(uint16_t port, uint16_t value);
#pragma aux dos_out16_raw = \
    "out dx,ax" parm[dx][ax] modify exact[];

static void dos_out32_raw(uint16_t port, uint32_t value);
#pragma aux dos_out32_raw = \
    "movzx eax,cx"          \
    "shl eax,16"            \
    "mov ax,bx"             \
    "out dx,eax" parm[dx][cx bx] modify exact[ax];

static uint8_t dos_phys_read8_raw(uint32_t address);
#pragma aux dos_phys_read8_raw = \
    "push es"                    \
    "mov bx,ax"                  \
    "movzx esi,dx"               \
    "shl esi,16"                 \
    "mov si,bx"                  \
    "xor ax,ax"                  \
    "mov es,ax"                  \
    "mov al,es:[esi]"            \
    "pop es" parm[dx ax] value[al] modify exact[ax bx si];

static void dos_phys_write8_raw(uint32_t address, uint8_t value);
#pragma aux dos_phys_write8_raw = \
    "push es"                     \
    "mov cx,ax"                   \
    "movzx esi,dx"                \
    "shl esi,16"                  \
    "mov si,cx"                   \
    "xor cx,cx"                   \
    "mov es,cx"                   \
    "mov es:[esi],bl"             \
    "pop es" parm[dx ax][bl] modify exact[cx si];

static void dos_cli_raw(void);
#pragma aux dos_cli_raw = "cli" modify exact[];

static void dos_sti_raw(void);
#pragma aux dos_sti_raw = "sti" modify exact[];

static bool dos_in8(
    void *context,
    uf_io_port_t port,
    uint8_t *value)
{
    (void)context;
    if (value == NULL)
    {
        return false;
    }
    *value = dos_in8_raw(port);
    return true;
}

static bool dos_in16(
    void *context,
    uf_io_port_t port,
    uint16_t *value)
{
    (void)context;
    if (value == NULL)
    {
        return false;
    }
    *value = dos_in16_raw(port);
    return true;
}

static bool dos_in32(
    void *context,
    uf_io_port_t port,
    uint32_t *value)
{
    (void)context;
    if (value == NULL)
    {
        return false;
    }
    *value = dos_in32_raw(port);
    return true;
}

static bool dos_out8(
    void *context,
    uf_io_port_t port,
    uint8_t value)
{
    (void)context;
    dos_out8_raw(port, value);
    return true;
}

static bool dos_out16(
    void *context,
    uf_io_port_t port,
    uint16_t value)
{
    (void)context;
    dos_out16_raw(port, value);
    return true;
}

static bool dos_out32(
    void *context,
    uf_io_port_t port,
    uint32_t value)
{
    (void)context;
    dos_out32_raw(port, value);
    return true;
}

static bool dos_phys_read8(
    void *context,
    uf_phys_addr_t address,
    uint8_t *value)
{
    (void)context;
    if (value == NULL)
    {
        return false;
    }
    *value = dos_phys_read8_raw(address);
    return true;
}

static bool dos_phys_write8(
    void *context,
    uf_phys_addr_t address,
    uint8_t value)
{
    (void)context;
    dos_phys_write8_raw(address, value);
    return true;
}

static bool dos_delay_us(
    void *context,
    uint32_t microseconds)
{
    uint32_t remaining = microseconds;

    (void)context;
    /*
     * PIT channel 0 runs at 1.193182 MHz on every supported 386-class PC.
     * Reading its latched counter avoids requiring RDTSC (Pentium+) and does
     * not reprogram the BIOS timer.
     */
    while (remaining > 0)
    {
        uint32_t chunk_us = remaining > UINT32_C(50000)
                                ? UINT32_C(50000)
                                : remaining;
        uint16_t target = (uint16_t)((chunk_us * UINT32_C(1193) + UINT32_C(999)) / UINT32_C(1000));
        uint16_t start;
        uint16_t current;
        uint16_t elapsed;
        uint8_t low;
        uint8_t high;

        dos_out8_raw(UINT16_C(0x43), UINT8_C(0));
        low = dos_in8_raw(UINT16_C(0x40));
        high = dos_in8_raw(UINT16_C(0x40));
        start = (uint16_t)low | ((uint16_t)high << 8);
        do
        {
            dos_out8_raw(UINT16_C(0x43), UINT8_C(0));
            low = dos_in8_raw(UINT16_C(0x40));
            high = dos_in8_raw(UINT16_C(0x40));
            current = (uint16_t)low | ((uint16_t)high << 8);
            elapsed = (uint16_t)(start - current);
        } while (elapsed < target);
        remaining -= chunk_us;
        if (target == 0)
        {
            break;
        }
    }
    return true;
}

static bool dos_interrupts_disable(void *context)
{
    (void)context;
    dos_cli_raw();
    return true;
}

static bool dos_interrupts_restore(void *context)
{
    (void)context;
    dos_sti_raw();
    return true;
}

bool uf_dos_hardware_init_io(uf_hardware_t *hardware)
{
    if (hardware == NULL)
    {
        return false;
    }
    memset(hardware, 0, sizeof(*hardware));
    hardware->in8 = dos_in8;
    hardware->in16 = dos_in16;
    hardware->in32 = dos_in32;
    hardware->out8 = dos_out8;
    hardware->out16 = dos_out16;
    hardware->out32 = dos_out32;
    hardware->phys_read8 = dos_phys_read8;
    hardware->phys_write8 = dos_phys_write8;
    hardware->delay_us = dos_delay_us;
    hardware->interrupts_disable = dos_interrupts_disable;
    hardware->interrupts_restore = dos_interrupts_restore;
    return true;
}

bool uf_dos_hardware_init(uf_hardware_t *hardware)
{
    if (hardware == NULL)
    {
        return false;
    }
    return (
               dos_flat_real_on() && uf_dos_hardware_init_io(hardware))
               ? true
               : false;
}

#else

bool uf_dos_hardware_init_io(uf_hardware_t *hardware)
{
    if (hardware != NULL)
    {
        memset(hardware, 0, sizeof(*hardware));
    }
    return false;
}

bool uf_dos_hardware_init(uf_hardware_t *hardware)
{
    if (hardware != NULL)
    {
        memset(hardware, 0, sizeof(*hardware));
    }
    return false;
}

#endif
