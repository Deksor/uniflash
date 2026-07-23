#ifndef UNIFLASH_RUNTIME_H
#define UNIFLASH_RUNTIME_H

#include "uniflash/all_algorithms.h"
#include "uniflash/chipset.h"
#include "uniflash/ct_flasher.h"
#include "uniflash/flash_backend.h"
#include "uniflash/pci_rom.h"

typedef uint8_t uf_runtime_flash_target_t;

enum
{
    UF_RUNTIME_FLASH_SYSTEM = 0,
    UF_RUNTIME_FLASH_CT,
    UF_RUNTIME_FLASH_PCI
};

typedef struct uf_runtime
{
    uf_hardware_t hardware;
    uf_chipset_t chipset;
    uf_system_flash_backend_t flash_backend;
    uf_ct_flasher_t ct_flasher;
    uf_pci_rom_backend_t pci_rom;
    uf_flash_access_t flash_access;
    uf_flash_algorithm_registry_t algorithms;
    uf_flash_service_t flash;
    bool initialized;
    bool rom_enabled;
    uf_runtime_flash_target_t flash_target;
} uf_runtime_t;

bool uf_runtime_init(
    uf_runtime_t *runtime,
    uf_phys_addr_t initial_rom_base);
bool uf_runtime_set_rom_enabled(
    uf_runtime_t *runtime,
    bool enabled);
bool uf_runtime_use_system_rom(uf_runtime_t *runtime);
bool uf_runtime_use_ct_flasher(
    uf_runtime_t *runtime,
    uf_io_port_t requested_port,
    bool size_512k);
bool uf_runtime_scan_pci_roms(
    uf_runtime_t *runtime,
    uf_pci_rom_list_t *list);
bool uf_runtime_use_pci_rom(
    uf_runtime_t *runtime,
    const uf_pci_rom_device_t *device);
bool uf_runtime_shutdown(uf_runtime_t *runtime);

#endif
