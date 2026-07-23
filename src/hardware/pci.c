#include "uniflash/pci.h"

bool uf_pci_bus_init(
    uf_pci_interface_t *pci,
    const uf_hardware_t *hardware)
{
    if (pci == NULL || !uf_hardware_is_valid(hardware))
    {
        return false;
    }
    pci->hardware = hardware;
    return true;
}

uint32_t uf_pci_mechanism1_address(
    uf_pci_address_t address,
    uf_pci_register_t reg)
{
    return UINT32_C(0x80000000) | ((uint32_t)address.bus << 16) | (((uint32_t)address.device & UINT32_C(0x1F)) << 11) | (((uint32_t)address.function & UINT32_C(0x07)) << 8) | ((uint32_t)reg & UINT32_C(0xFC));
}

bool uf_pci_read32(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint32_t *value)
{
    if (pci == NULL || pci->hardware == NULL || value == NULL)
    {
        return false;
    }
    return (
        pci->hardware->out32(
            pci->hardware->context,
            UF_PCI_CONFIG_ADDRESS_PORT,
            uf_pci_mechanism1_address(address, reg)) &&
        pci->hardware->in32(
            pci->hardware->context,
            UF_PCI_CONFIG_DATA_PORT,
            value));
}

bool uf_pci_write32(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint32_t value)
{
    if (pci == NULL || pci->hardware == NULL)
    {
        return false;
    }
    return (
        pci->hardware->out32(
            pci->hardware->context,
            UF_PCI_CONFIG_ADDRESS_PORT,
            uf_pci_mechanism1_address(address, reg)) &&
        pci->hardware->out32(
            pci->hardware->context,
            UF_PCI_CONFIG_DATA_PORT,
            value));
}

bool uf_pci_read16(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint16_t *value)
{
    uint32_t data;

    if (value == NULL || !uf_pci_read32(pci, address, reg, &data))
    {
        return false;
    }
    *value = (uint16_t)(data >> (((uint16_t)reg & UINT16_C(2)) * UINT16_C(8)));
    return true;
}

bool uf_pci_read8(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_register_t reg,
    uint8_t *value)
{
    uint32_t data;

    if (value == NULL || !uf_pci_read32(pci, address, reg, &data))
    {
        return false;
    }
    *value = (uint8_t)(data >> (((uint16_t)reg & UINT16_C(3)) * UINT16_C(8)));
    return true;
}

bool uf_pci_probe(
    const uf_pci_interface_t *pci,
    uf_pci_address_t address,
    uf_pci_function_info_t *device)
{
    uint32_t identity;
    uint32_t class_revision;
    uint8_t header_type;

    if (
        device == NULL || !uf_pci_read32(pci, address, UINT8_C(0), &identity) || (identity & UINT32_C(0xFFFF)) == UINT32_C(0xFFFF) || !uf_pci_read32(pci, address, UINT8_C(0x08), &class_revision) || !uf_pci_read8(pci, address, UINT8_C(0x0E), &header_type))
    {
        return false;
    }
    device->address = address;
    device->vendor_id = (uint16_t)identity;
    device->device_id = (uint16_t)(identity >> 16);
    device->revision = (uint8_t)class_revision;
    device->programming_interface = (uint8_t)(class_revision >> 8);
    device->subclass = (uint8_t)(class_revision >> 16);
    device->class_code = (uint8_t)(class_revision >> 24);
    device->header_type = header_type;
    return true;
}

bool uf_pci_enumerate(
    const uf_pci_interface_t *pci,
    uf_pci_visit_fn visit,
    void *context)
{
    if (pci == NULL || visit == NULL)
    {
        return false;
    }
    for (uint16_t bus_number = 0; bus_number <= UINT8_MAX; ++bus_number)
    {
        for (uint8_t device_number = 0; device_number < 32; ++device_number)
        {

            uf_pci_address_t address;
            address.bus = (uint8_t)bus_number;
            address.device = device_number;
            address.function = 0;
            uf_pci_function_info_t function_zero;
            if (!uf_pci_probe(pci, address, &function_zero))
            {
                continue;
            }
            if (!visit(context, &function_zero))
            {
                return true;
            }
            uint8_t function_count = (function_zero.header_type & UINT8_C(0x80)) != 0 ? UINT8_C(8) : UINT8_C(1);
            for (uint8_t
                     function_number = 1;
                 function_number < function_count;
                 ++function_number)
            {
                uf_pci_function_info_t device;

                address.function = function_number;
                if (
                    uf_pci_probe(pci, address, &device) && !visit(context, &device))
                {
                    return true;
                }
            }
        }
    }
    return true;
}
