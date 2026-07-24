#ifndef UNIFLASH_HARDWARE_H
#define UNIFLASH_HARDWARE_H

#include "uniflash/types.h"

typedef bool (*uf_hw_in8_fn)(void *context, uf_io_port_t port, uint8_t *value);
typedef bool (*uf_hw_in16_fn)(void *context, uf_io_port_t port, uint16_t *value);
typedef bool (*uf_hw_in32_fn)(void *context, uf_io_port_t port, uint32_t *value);
typedef bool (*uf_hw_out8_fn)(void *context, uf_io_port_t port, uint8_t value);
typedef bool (*uf_hw_out16_fn)(void *context, uf_io_port_t port, uint16_t value);
typedef bool (*uf_hw_out32_fn)(void *context, uf_io_port_t port, uint32_t value);
typedef bool (*uf_hw_phys_read8_fn)(void *context, uf_phys_addr_t address, uint8_t *value);
typedef bool (*uf_hw_phys_write8_fn)(void *context, uf_phys_addr_t address, uint8_t value);
typedef bool (*uf_hw_delay_us_fn)(void *context, uint32_t microseconds);
typedef bool (*uf_hw_interrupt_state_fn)(void *context);

typedef struct uf_hardware {
    void *context;
    uf_hw_in8_fn in8;
    uf_hw_in16_fn in16;
    uf_hw_in32_fn in32;
    uf_hw_out8_fn out8;
    uf_hw_out16_fn out16;
    uf_hw_out32_fn out32;
    uf_hw_phys_read8_fn phys_read8;
    uf_hw_phys_write8_fn phys_write8;
    uf_hw_delay_us_fn delay_us;
    uf_hw_interrupt_state_fn interrupts_disable;
    uf_hw_interrupt_state_fn interrupts_restore;
} uf_hardware_t;

bool uf_hardware_is_valid(const uf_hardware_t *hardware);
bool uf_hw_phys_read_block(const uf_hardware_t *hardware,
    uf_phys_addr_t source,
    void *destination,
    uf_rom_size_t size_bytes);
bool uf_hw_phys_write_block(const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes);
bool uf_hw_phys_compare_block(const uf_hardware_t *hardware,
    const void *source,
    uf_phys_addr_t destination,
    uf_rom_size_t size_bytes,
    bool *equal);
bool uf_dos_hardware_init(uf_hardware_t *hardware);
/*
 * Initializes DOS port-I/O callbacks without entering flat real mode.
 * This is intended for low-memory services such as CMOS backup only.
 */
bool uf_dos_hardware_init_io(uf_hardware_t *hardware);

#endif
