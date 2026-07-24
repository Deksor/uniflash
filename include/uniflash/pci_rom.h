#ifndef UNIFLASH_PCI_ROM_H
#define UNIFLASH_PCI_ROM_H

#include "uniflash/flash_service.h"
#include "uniflash/pci.h"

#define UF_PCI_ROM_MAX_DEVICES 20

typedef struct uf_pci_rom_device {
    uf_pci_function_info_t pci_device;
    uf_rom_size_t maximum_size;
} uf_pci_rom_device_t;

typedef struct uf_pci_rom_list {
    uf_pci_rom_device_t devices[UF_PCI_ROM_MAX_DEVICES];
    uint8_t count;
} uf_pci_rom_list_t;

typedef struct uf_pci_rom_scan_context {
    uf_pci_rom_list_t *list;
    const uf_pci_interface_t *pci;
} uf_pci_rom_scan_context_t;

typedef uint8_t uf_pci_flash_kind_t;

enum {
    UF_PCI_FLASH_MEMORY = 0,
    UF_PCI_FLASH_WINBOND,
    UF_PCI_FLASH_3COM,
    UF_PCI_FLASH_REALTEK,
    UF_PCI_FLASH_REALTEK_1000,
    UF_PCI_FLASH_VIA,
    UF_PCI_FLASH_ADMTEK,
    UF_PCI_FLASH_SUNDANCE
};

typedef struct uf_pci_rom_backend {
    const uf_hardware_t *hardware;
    uf_pci_interface_t pci;
    uf_pci_rom_device_t device;
    uf_pci_flash_kind_t kind;
    uf_io_port_t io_base;
    uf_phys_addr_t memory_base;
    uint32_t saved_command;
    uint32_t saved_rom_bar;
    uint32_t saved_card_register;
    bool enabled;
} uf_pci_rom_backend_t;

bool uf_pci_rom_scan(uf_pci_rom_list_t *list, const uf_hardware_t *hardware);
bool uf_pci_rom_backend_init(uf_pci_rom_backend_t *backend,
    const uf_hardware_t *hardware,
    const uf_pci_rom_device_t *device);
bool uf_pci_rom_backend_set_enabled(uf_pci_rom_backend_t *backend, bool enabled);
bool uf_pci_rom_backend_make_access(uf_pci_rom_backend_t *backend, uf_flash_access_t *access);
const char *uf_pci_rom_device_name(const uf_pci_rom_device_t *device);
const char *uf_pci_rom_device_name_from_ids(const uf_pci_rom_device_t *device, const char *path);

#endif
