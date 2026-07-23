#ifndef UNIFLASH_PCI_H
#define UNIFLASH_PCI_H

#include "uniflash/hardware.h"

#define UF_PCI_CONFIG_ADDRESS_PORT UINT16_C(0x0CF8)
#define UF_PCI_CONFIG_DATA_PORT UINT16_C(0x0CFC)

typedef struct uf_pci_address {
    uf_pci_bus_t bus;
    uf_pci_device_t device;
    uf_pci_function_t function;
} uf_pci_address_t;

typedef struct uf_pci_device {
    uf_pci_address_t address;
    uint16_t vendor_id;
    uint16_t device_id;
    uint8_t revision;
    uint8_t programming_interface;
    uint8_t subclass;
    uint8_t class_code;
    uint8_t header_type;
} uf_pci_function_info_t;

typedef uf_bool_t (*uf_pci_visit_fn)(
    void *context,
    const uf_pci_function_info_t *device
);

typedef struct uf_pci_bus {
    const uf_hardware_t *hardware;
} uf_pci_interface_t;

uf_bool_t uf_pci_bus_init(
    uf_pci_interface_t *pci,
    const uf_hardware_t *hardware
);
uint32_t uf_pci_mechanism1_address(
    uf_pci_address_t address,
    uf_pci_register_t reg
);
uf_bool_t uf_pci_read32(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint32_t *value
);
uf_bool_t uf_pci_write32(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint32_t value
);
uf_bool_t uf_pci_read16(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint16_t *value
);
uf_bool_t uf_pci_read8(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint8_t *value
);
uf_bool_t uf_pci_probe(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_function_info_t *device
);
uf_bool_t uf_pci_enumerate(
    const uf_pci_interface_t *pci,
    uf_pci_visit_fn visit,
    void *context
);

#endif
