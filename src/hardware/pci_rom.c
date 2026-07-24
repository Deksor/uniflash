#include <stdio.h>
#include <string.h>

#include "uniflash/pci_rom.h"

#define UF_PCI_FLASH_POLL_LIMIT UINT32_C(1000000)

static bool probe_rom_size(const uf_pci_interface_t *pci, const uf_pci_function_info_t *device, uf_rom_size_t *size) {
    uint32_t saved_command = 0;
    uint32_t saved_bar = 0;
    uint32_t stuck_zero;
    uint32_t stuck_one;
    bool result = false;
    bool command_saved = false;
    bool bar_saved = false;
    bool interrupts_disabled = false;

    if (pci->hardware->interrupts_disable != NULL && pci->hardware->interrupts_restore != NULL) {
        interrupts_disabled = pci->hardware->interrupts_disable(pci->hardware->context);
    }
    if (!uf_pci_read32(pci, device->address, UINT8_C(0x04), &saved_command)) {
        goto restore;
    }
    command_saved = true;
    if (!uf_pci_read32(pci, device->address, UINT8_C(0x30), &saved_bar)) {
        goto restore;
    }
    bar_saved = true;
    if (!uf_pci_write32(pci, device->address, UINT8_C(0x04), saved_command | UINT32_C(0x02)) ||
        !uf_pci_write32(pci, device->address, UINT8_C(0x30), UINT32_MAX) ||
        !uf_pci_read32(pci, device->address, UINT8_C(0x30), &stuck_zero) ||
        !uf_pci_write32(pci, device->address, UINT8_C(0x30), UINT32_C(1)) ||
        !uf_pci_read32(pci, device->address, UINT8_C(0x30), &stuck_one)) {
        goto restore;
    }
    uint32_t image = stuck_zero ^ stuck_one;
    uint8_t bit;
    for (bit = 1; bit < 32; ++bit) {
        if ((image & (UINT32_C(1) << bit)) != 0) {
            break;
        }
    }
    if (bit < 32 && image == (UINT32_MAX << bit)) {
        *size = UINT32_C(1) << bit;
        result = true;
    }

restore:
    if (bar_saved) {
        (void)uf_pci_write32(pci, device->address, UINT8_C(0x30), saved_bar);
    }
    if (command_saved) {
        (void)uf_pci_write32(pci, device->address, UINT8_C(0x04), saved_command);
    }
    if (interrupts_disabled) {
        (void)pci->hardware->interrupts_restore(pci->hardware->context);
    }
    return result;
}

static bool scan_visit(void *context, const uf_pci_function_info_t *device) {
    uf_pci_rom_scan_context_t *scan = context;
    uf_rom_size_t size;

    if (scan->list->count < UF_PCI_ROM_MAX_DEVICES && probe_rom_size(scan->pci, device, &size)) {
        uf_pci_rom_device_t *rom = &scan->list->devices[scan->list->count++];
        rom->pci_device = *device;
        rom->maximum_size = size;
    }
    return true;
}

bool uf_pci_rom_scan(uf_pci_rom_list_t *list, const uf_hardware_t *hardware) {
    uf_pci_interface_t pci;
    uf_pci_rom_scan_context_t scan;

    if (list == NULL || !uf_pci_bus_init(&pci, hardware)) {
        return false;
    }
    memset(list, 0, sizeof(*list));
    scan.list = list;
    scan.pci = &pci;
    return uf_pci_enumerate(&pci, scan_visit, &scan);
}

static bool find_io_base(const uf_pci_interface_t *pci, uf_pci_address_t address, uf_io_port_t *base) {
    for (uint8_t reg = UINT8_C(0x10); reg <= UINT8_C(0x28); reg += 4) {
        uint32_t value;

        if (!uf_pci_read32(pci, address, reg, &value)) {
            return false;
        }
        if ((value & UINT32_C(1)) != 0) {
            *base = (uf_io_port_t)(value & UINT32_C(0xFFFC));
            return true;
        }
        if ((value & UINT32_C(7)) == UINT32_C(4)) {
            reg += 4;
        }
    }
    return false;
}

static bool find_memory_base(const uf_pci_interface_t *pci, uf_pci_address_t address, uf_phys_addr_t *base) {
    for (uint8_t reg = UINT8_C(0x10); reg <= UINT8_C(0x28); reg += 4) {
        uint32_t value;

        if (!uf_pci_read32(pci, address, reg, &value)) {
            return false;
        }
        if ((value & UINT32_C(1)) == 0) {
            *base = value & UINT32_C(0xFFFFFFF0);
            return true;
        }
    }
    return false;
}

static uf_pci_flash_kind_t card_kind(uint16_t vendor, uint16_t device) {
    if (vendor == 0x104A && (device == 0x0981 || device == 0x2774)) {
        return UF_PCI_FLASH_ADMTEK;
    }
    if (vendor == 0x1050 && device == 0x0840) {
        return UF_PCI_FLASH_WINBOND;
    }
    if (vendor == 0x10B7 && device == 0x9001) {
        return UF_PCI_FLASH_3COM;
    }
    if (vendor == 0x10EC && (device == 0x8129 || device == 0x8139)) {
        return UF_PCI_FLASH_REALTEK;
    }
    if (vendor == 0x10EC && device == 0x8169) {
        return UF_PCI_FLASH_REALTEK_1000;
    }
    if (vendor == 0x1106 && (device == 0x3065 || device == 0x3106)) {
        return UF_PCI_FLASH_VIA;
    }
    if (vendor == 0x1317) {
        switch (device) {
        case 0x0981:
        case 0x0985:
        case 0x1985:
        case 0x9511:
        case 0x9513:
        case 0x9514:
            return UF_PCI_FLASH_ADMTEK;
        }
    }
    if (vendor == 0x13F0 && device == 0x0201) {
        return UF_PCI_FLASH_SUNDANCE;
    }
    return UF_PCI_FLASH_MEMORY;
}

bool uf_pci_rom_backend_init(uf_pci_rom_backend_t *backend,
    const uf_hardware_t *hardware,
    const uf_pci_rom_device_t *device) {
    if (backend == NULL || device == NULL) {
        return false;
    }
    memset(backend, 0, sizeof(*backend));
    if (!uf_pci_bus_init(&backend->pci, hardware)) {
        return false;
    }
    backend->hardware = hardware;
    backend->device = *device;
    backend->kind = card_kind(device->pci_device.vendor_id, device->pci_device.device_id);
    bool needs_io = backend->kind != UF_PCI_FLASH_MEMORY ||
                    (device->pci_device.vendor_id == 0x10B8 && device->pci_device.device_id == 0x0006);
    if (needs_io && !find_io_base(&backend->pci, device->pci_device.address, &backend->io_base)) {
        return false;
    }
    if (backend->kind == UF_PCI_FLASH_MEMORY && device->pci_device.vendor_id == 0x9004 &&
        device->pci_device.device_id == 0x6915 &&
        !find_memory_base(&backend->pci, device->pci_device.address, &backend->memory_base)) {
        return false;
    }
    return true;
}

static bool poll32_clear(uf_pci_rom_backend_t *backend, uf_io_port_t port, uint32_t mask, uint32_t *value) {
    uint32_t timeout = UF_PCI_FLASH_POLL_LIMIT;

    do {
        if (!backend->hardware->in32(backend->hardware->context, port, value)) {
            return false;
        }
        --timeout;
    } while ((*value & mask) != 0 && timeout > 0);
    return timeout > 0;
}

static bool indirect_read(uf_pci_rom_backend_t *backend, uf_rom_offset_t address, uint8_t *value) {
    const uf_hardware_t *hardware = backend->hardware;
    uint32_t data;
    uint8_t status;

    switch (backend->kind) {
    case UF_PCI_FLASH_WINBOND:
        if (!hardware->out32(hardware->context, backend->io_base + UINT16_C(0x28), address) ||
            !hardware->in32(hardware->context, backend->io_base + UINT16_C(0x24), &data) ||
            !hardware->out32(hardware->context,
                backend->io_base + UINT16_C(0x24),
                (data & UINT32_C(0xFFFFF7FF)) | UINT32_C(0x4000)) ||
            !poll32_clear(backend, backend->io_base + UINT16_C(0x24), UINT32_C(0x4000), &data)) {
            return false;
        }
        *value = (uint8_t)data;
        return true;
    case UF_PCI_FLASH_3COM:
        return hardware->out32(hardware->context, backend->io_base + 4, address) &&
               hardware->in8(hardware->context, backend->io_base + 8, value);
    case UF_PCI_FLASH_REALTEK:
    case UF_PCI_FLASH_REALTEK_1000: {
        uf_io_port_t port =
            backend->io_base + (backend->kind == UF_PCI_FLASH_REALTEK ? UINT16_C(0xD4) : UINT16_C(0x30));
        if (!hardware->out32(hardware->context, port, address | UINT32_C(0x1A0000)) ||
            !hardware->in32(hardware->context, port, &data)) {
            return false;
        }
        *value = (uint8_t)(data >> 24);
        return true;
    }
    case UF_PCI_FLASH_VIA:
        if (!hardware->out16(hardware->context, backend->io_base + UINT16_C(0x8C), (uint16_t)address) ||
            !hardware->out8(hardware->context, backend->io_base + UINT16_C(0x90), UINT8_C(1))) {
            return false;
        }
        data = UF_PCI_FLASH_POLL_LIMIT;
        do {
            if (!hardware->in8(hardware->context, backend->io_base + UINT16_C(0x90), &status)) {
                return false;
            }
            --data;
        } while ((status & UINT8_C(0x80)) == 0 && data > 0);
        return data > 0 && hardware->in8(hardware->context, backend->io_base + UINT16_C(0x91), value);
    case UF_PCI_FLASH_ADMTEK:
        if (!hardware->in32(hardware->context, backend->io_base + UINT16_C(0xA0), &data) ||
            !hardware->out32(hardware->context,
                backend->io_base + UINT16_C(0xA0),
                (data & UINT32_C(0x78000000)) | (address << 8) | UINT32_C(0x08000000)) ||
            !poll32_clear(backend, backend->io_base + UINT16_C(0xA0), UINT32_C(0x08000000), &data)) {
            return false;
        }
        *value = (uint8_t)data;
        return true;
    case UF_PCI_FLASH_SUNDANCE:
        return hardware->out32(hardware->context, backend->io_base + UINT16_C(0x40), address) &&
               hardware->in8(hardware->context, backend->io_base + UINT16_C(0x44), value);
    default:
        return backend->hardware->phys_read8(backend->hardware->context, backend->memory_base + address, value);
    }
}

static bool indirect_write(uf_pci_rom_backend_t *backend, uf_rom_offset_t address, uint8_t value) {
    const uf_hardware_t *hardware = backend->hardware;
    uint32_t data;
    uint8_t status;

    switch (backend->kind) {
    case UF_PCI_FLASH_WINBOND:
        return hardware->out32(hardware->context, backend->io_base + UINT16_C(0x28), address) &&
               hardware->in32(hardware->context, backend->io_base + UINT16_C(0x24), &data) &&
               hardware->out32(hardware->context,
                   backend->io_base + UINT16_C(0x24),
                   (data & UINT32_C(0xFFFFF700)) | value | UINT32_C(0x2000)) &&
               poll32_clear(backend, backend->io_base + UINT16_C(0x24), UINT32_C(0x2000), &data);
    case UF_PCI_FLASH_3COM:
        return hardware->out32(hardware->context, backend->io_base + 4, address) &&
               hardware->out8(hardware->context, backend->io_base + 8, value);
    case UF_PCI_FLASH_REALTEK:
    case UF_PCI_FLASH_REALTEK_1000: {
        uf_io_port_t port =
            backend->io_base + (backend->kind == UF_PCI_FLASH_REALTEK ? UINT16_C(0xD4) : UINT16_C(0x30));
        return hardware->out32(hardware->context, port, address | UINT32_C(0x160000) | ((uint32_t)value << 24));
    }
    case UF_PCI_FLASH_VIA:
        if (!hardware->out16(hardware->context, backend->io_base + UINT16_C(0x8C), (uint16_t)address) ||
            !hardware->out8(hardware->context, backend->io_base + UINT16_C(0x8F), value) ||
            !hardware->out8(hardware->context, backend->io_base + UINT16_C(0x90), UINT8_C(2))) {
            return false;
        }
        data = UF_PCI_FLASH_POLL_LIMIT;
        do {
            if (!hardware->in8(hardware->context, backend->io_base + UINT16_C(0x90), &status)) {
                return false;
            }
            --data;
        } while ((status & UINT8_C(0x80)) == 0 && data > 0);
        return data > 0;
    case UF_PCI_FLASH_ADMTEK:
        return hardware->in32(hardware->context, backend->io_base + UINT16_C(0xA0), &data) &&
               hardware->out32(hardware->context,
                   backend->io_base + UINT16_C(0xA0),
                   (data & UINT32_C(0x78000000)) | (address << 8) | value | UINT32_C(0x04000000)) &&
               poll32_clear(backend, backend->io_base + UINT16_C(0xA0), UINT32_C(0x04000000), &data);
    case UF_PCI_FLASH_SUNDANCE:
        return hardware->out32(hardware->context, backend->io_base + UINT16_C(0x40), address) &&
               hardware->out8(hardware->context, backend->io_base + UINT16_C(0x44), value);
    default:
        return backend->hardware->phys_write8(backend->hardware->context, backend->memory_base + address, value);
    }
}

static bool access_read(void *context, uf_rom_offset_t address, uint8_t *value) {
    return indirect_read(context, address, value);
}

static bool access_write(void *context, uf_rom_offset_t address, uint8_t value) {
    return indirect_write(context, address, value);
}

static bool access_read_block(void *context, uf_rom_offset_t address, void *destination, uf_rom_size_t size) {
    uint8_t *bytes = destination;
    for (uf_rom_size_t offset = 0; offset < size; ++offset) {
        if (!indirect_read(context, address + offset, &bytes[offset])) {
            return false;
        }
    }
    return true;
}

static bool access_write_block(void *context, const void *source, uf_rom_offset_t address, uf_rom_size_t size) {
    const uint8_t *bytes = source;
    for (uf_rom_size_t offset = 0; offset < size; ++offset) {
        if (!indirect_write(context, address + offset, bytes[offset])) {
            return false;
        }
    }
    return true;
}

static bool
access_compare(void *context, const void *source, uf_rom_offset_t address, uf_rom_size_t size, bool *equal) {
    const uint8_t *bytes = source;
    if (equal == NULL) {
        return false;
    }
    *equal = false;
    for (uf_rom_size_t offset = 0; offset < size; ++offset) {
        uint8_t value;
        if (!indirect_read(context, address + offset, &value)) {
            return false;
        }
        if (value != bytes[offset]) {
            return true;
        }
    }
    *equal = true;
    return true;
}

static bool access_delay(void *context, uint32_t microseconds) {
    uf_pci_rom_backend_t *backend = context;
    return backend->hardware->delay_us(backend->hardware->context, microseconds);
}

static bool access_source(void *context, uf_phys_addr_t address, uint8_t *value) {
    uf_pci_rom_backend_t *backend = context;
    return backend->hardware->phys_read8(backend->hardware->context, address, value);
}

static bool access_select(void *context, uf_phys_addr_t base) {
    uf_pci_rom_backend_t *backend = context;
    backend->memory_base = base;
    return true;
}

static bool access_update_phys(void *context, uf_phys_addr_t address, uint8_t and_mask, uint8_t or_mask) {
    uf_pci_rom_backend_t *backend = context;
    uint8_t value;
    return backend->hardware->phys_read8(backend->hardware->context, address, &value) &&
           backend->hardware->phys_write8(backend->hardware->context, address, (value & and_mask) | or_mask);
}

static bool access_lock(void *context, uf_phys_addr_t address, bool locked) {
    return access_update_phys(context,
        address,
        locked ? UINT8_C(0xFF) : UINT8_C(0xF8),
        locked ? UINT8_C(1) : UINT8_C(0));
}

bool uf_pci_rom_backend_make_access(uf_pci_rom_backend_t *backend, uf_flash_access_t *access) {
    if (backend == NULL || access == NULL || backend->hardware == NULL) {
        return false;
    }
    memset(access, 0, sizeof(*access));
    access->context = backend;
    access->read_byte = access_read;
    access->write_byte = access_write;
    access->read_block = access_read_block;
    access->write_block = access_write_block;
    access->compare_block = access_compare;
    access->delay_us = access_delay;
    access->select_window = access_select;
    access->read_source_byte = access_source;
    access->set_write_lock = access_lock;
    access->update_phys_byte = access_update_phys;
    return true;
}

bool uf_pci_rom_backend_set_enabled(uf_pci_rom_backend_t *backend, bool enabled) {
    if (backend == NULL || backend->hardware == NULL || backend->enabled == enabled) {
        return backend != NULL;
    }
    uf_pci_address_t address = backend->device.pci_device.address;
    if (enabled) {
        if (!uf_pci_read32(&backend->pci, address, UINT8_C(0x04), &backend->saved_command)) {
            return false;
        }
        if (!uf_pci_read32(&backend->pci, address, UINT8_C(0x30), &backend->saved_rom_bar)) {
            return false;
        }
        if (!uf_pci_write32(&backend->pci, address, UINT8_C(0x04), backend->saved_command | UINT32_C(0x02)) ||
            !uf_pci_write32(&backend->pci, address, UINT8_C(0x30), UINT32_C(0x80000001))) {
            goto enable_failed;
        }
        if (backend->device.pci_device.vendor_id != 0x9004 || backend->device.pci_device.device_id != 0x6915) {
            backend->memory_base = UINT32_C(0x80000000);
        }
        if (backend->device.pci_device.vendor_id == 0x10B8 && backend->device.pci_device.device_id == 0x0006) {
            if (!backend->hardware->in32(backend->hardware->context,
                    backend->io_base + UINT16_C(0x10),
                    &backend->saved_card_register) ||
                !backend->hardware->out32(backend->hardware->context,
                    backend->io_base + UINT16_C(0x10),
                    backend->saved_card_register | UINT32_C(0x100))) {
                goto enable_failed;
            }
        }
        if (backend->device.pci_device.vendor_id == 0x121A && backend->device.pci_device.device_id == 0x0003) {
            if (!uf_pci_read32(&backend->pci, address, UINT8_C(0x14), &backend->saved_card_register) ||
                !uf_pci_write32(&backend->pci, address, UINT8_C(0x14), backend->saved_card_register | UINT32_C(0x10))) {
                goto enable_failed;
            }
        }
    } else {
        if (backend->device.pci_device.vendor_id == 0x10B8 && backend->device.pci_device.device_id == 0x0006 &&
            !backend->hardware->out32(backend->hardware->context,
                backend->io_base + UINT16_C(0x10),
                backend->saved_card_register)) {
            return false;
        }
        if (backend->device.pci_device.vendor_id == 0x121A && backend->device.pci_device.device_id == 0x0003 &&
            !uf_pci_write32(&backend->pci, address, UINT8_C(0x14), backend->saved_card_register)) {
            return false;
        }
        if (!uf_pci_write32(&backend->pci, address, UINT8_C(0x30), backend->saved_rom_bar) ||
            !uf_pci_write32(&backend->pci, address, UINT8_C(0x04), backend->saved_command)) {
            return false;
        }
    }
    backend->enabled = enabled;
    return true;

enable_failed:
    (void)uf_pci_write32(&backend->pci, address, UINT8_C(0x30), backend->saved_rom_bar);
    (void)uf_pci_write32(&backend->pci, address, UINT8_C(0x04), backend->saved_command);
    return false;
}

static const char *fallback_device_name(const uf_pci_rom_device_t *device) {
    if (device == NULL) {
        return "PCI or AGP card";
    }
    uint16_t vendor = device->pci_device.vendor_id;
    uint16_t id = device->pci_device.device_id;
    if (vendor == 0x104A && (id == 0x0981 || id == 0x2774))
        return "STMicroelectronics STE10/100";
    if (vendor == 0x1050 && id == 0x0840)
        return "Winbond W89C840AF";
    if (vendor == 0x10B7 && id == 0x9001)
        return "3Com EtherLink XL";
    if (vendor == 0x10B8 && id == 0x0006)
        return "SMSC LAN83C175";
    if (vendor == 0x10EC && (id == 0x8129 || id == 0x8139))
        return "Realtek RTL8129/8139";
    if (vendor == 0x10EC && id == 0x8169)
        return "Realtek RTL8169";
    if (vendor == 0x1106 && id == 0x3065)
        return "VIA VT6102";
    if (vendor == 0x1106 && id == 0x3106)
        return "VIA VT6105M";
    if (vendor == 0x121A && id == 0x0003)
        return "3Dfx Banshee";
    if (vendor == 0x1317)
        return "ADMtek Ethernet";
    if (vendor == 0x13F0 && id == 0x0201)
        return "Sundance ST201";
    if (vendor == 0x9004 && id == 0x6915)
        return "Adaptec AIC-6915";
    return "PCI or AGP card";
}

static int hex_digit_value(char digit) {
    if (digit >= '0' && digit <= '9') {
        return digit - '0';
    }
    if (digit >= 'a' && digit <= 'f') {
        return digit - 'a' + 10;
    }
    if (digit >= 'A' && digit <= 'F') {
        return digit - 'A' + 10;
    }
    return -1;
}

static bool parse_pci_id(const char *text, uint16_t *id) {
    uint16_t value = 0;

    for (uint8_t index = 0; index < 4; ++index) {
        int digit = hex_digit_value(text[index]);
        if (digit < 0) {
            return false;
        }
        value = (uint16_t)((value << 4) | (uint16_t)digit);
    }
    if (text[4] != ' ' && text[4] != '\t') {
        return false;
    }
    *id = value;
    return true;
}

static void copy_pci_name(char *destination, size_t capacity, const char *source) {
    while (*source == ' ' || *source == '\t') {
        ++source;
    }
    size_t length = strcspn(source, "\r\n");
    if (length >= capacity) {
        length = capacity - 1;
    }
    memcpy(destination, source, length);
    destination[length] = '\0';
}

const char *uf_pci_rom_device_name_from_ids(const uf_pci_rom_device_t *device, const char *path) {
    static char line[256];
    static char vendor_name[80];
    static char device_name[128];
    static char combined_name[208];

    if (device == NULL || path == NULL) {
        return fallback_device_name(device);
    }
    FILE *file = fopen(path, "rt");
    if (file == NULL) {
        return fallback_device_name(device);
    }

    bool matching_vendor = false;
    vendor_name[0] = '\0';
    while (fgets(line, sizeof(line), file) != NULL) {
        uint16_t id;

        if (line[0] != '\t') {
            if (!parse_pci_id(line, &id)) {
                continue;
            }
            if (matching_vendor) {
                break;
            }
            matching_vendor = id == device->pci_device.vendor_id;
            if (matching_vendor) {
                copy_pci_name(vendor_name, sizeof(vendor_name), line + 4);
            }
            continue;
        }
        if (matching_vendor && line[1] != '\t' && parse_pci_id(line + 1, &id) && id == device->pci_device.device_id) {
            copy_pci_name(device_name, sizeof(device_name), line + 5);
            fclose(file);
            if (vendor_name[0] == '\0') {
                return device_name;
            }
            snprintf(combined_name, sizeof(combined_name), "%s %s", vendor_name, device_name);
            return combined_name;
        }
    }
    fclose(file);
    return fallback_device_name(device);
}

const char *uf_pci_rom_device_name(const uf_pci_rom_device_t *device) {
    return uf_pci_rom_device_name_from_ids(device, "PCI.IDS");
}
