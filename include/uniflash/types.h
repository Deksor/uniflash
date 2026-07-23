#ifndef UNIFLASH_TYPES_H
#define UNIFLASH_TYPES_H

#include <limits.h>
#include <stddef.h>
#include <stdint.h>

#define UF_STATIC_ASSERT(name, expression) \
    typedef char uf_static_assert_##name[(expression) ? 1 : -1]

/*
 * Hardware-facing values use explicit widths. In particular, size_t is only
 * 16 bits in Open Watcom's DOS/16 huge model and cannot represent a ROM size.
 */
typedef uint32_t uf_phys_addr_t;
typedef uint32_t uf_rom_offset_t;
typedef uint32_t uf_rom_size_t;

typedef uint16_t uf_io_port_t;
typedef uint16_t uf_pci_device_id_t;
typedef uint16_t uf_pci_vendor_id_t;

typedef uint8_t uf_bool_t;
typedef uint8_t uf_pci_bus_t;
typedef uint8_t uf_pci_device_t;
typedef uint8_t uf_pci_function_t;
typedef uint8_t uf_pci_register_t;

enum {
    UF_FALSE = 0,
    UF_TRUE = 1
};

UF_STATIC_ASSERT(char_is_8_bits, CHAR_BIT == 8);
UF_STATIC_ASSERT(uint8_is_1_byte, sizeof(uint8_t) == 1);
UF_STATIC_ASSERT(uint16_is_2_bytes, sizeof(uint16_t) == 2);
UF_STATIC_ASSERT(uint32_is_4_bytes, sizeof(uint32_t) == 4);
UF_STATIC_ASSERT(phys_addr_is_4_bytes, sizeof(uf_phys_addr_t) == 4);
UF_STATIC_ASSERT(rom_size_is_4_bytes, sizeof(uf_rom_size_t) == 4);
UF_STATIC_ASSERT(io_port_is_2_bytes, sizeof(uf_io_port_t) == 2);

#if defined(UF_TARGET_DOS16)

#if !defined(__WATCOMC__)
#error UF_TARGET_DOS16 requires Open Watcom
#endif

#if !defined(_DOS)
#error UF_TARGET_DOS16 requires the Open Watcom DOS target
#endif

#if !defined(__I86__) && !defined(_M_I86)
#error UF_TARGET_DOS16 requires the Open Watcom 16-bit x86 compiler
#endif

#if !defined(__HUGE__) && !defined(__SW_MH)
#error UF_TARGET_DOS16 requires the Open Watcom huge memory model
#endif

UF_STATIC_ASSERT(dos16_int_is_2_bytes, sizeof(int) == 2);
UF_STATIC_ASSERT(dos16_long_is_4_bytes, sizeof(long) == 4);
UF_STATIC_ASSERT(dos16_size_t_is_2_bytes, sizeof(size_t) == 2);
UF_STATIC_ASSERT(dos16_data_pointer_is_4_bytes, sizeof(void *) == 4);
UF_STATIC_ASSERT(
    dos16_function_pointer_is_4_bytes,
    sizeof(void (*)(void)) == 4
);

#endif

#endif
