#include <string.h>

#include "uniflash/chipset.h"

#define CHIP(vendor_value, device_value, text, method_value) {vendor_value, device_value, text, method_value, false}
#define CHIP_LPC(vendor_value, device_value, text, method_value) {vendor_value, device_value, text, method_value, true}

static const uf_chipset_id_t north_ids[] = {CHIP(0x8086, 0x04A3, "Intel 82433LX/NX", 0),
    CHIP(0x8086, 0x122D, "Intel 82437FX", 0),
    CHIP(0x8086, 0x1235, "Intel 82437MX", 0),
    CHIP(0x8086, 0x1237, "Intel 82441FX", 0),
    CHIP(0x8086, 0x1250, "Intel 82439HX", 0),
    CHIP(0x8086, 0x7030, "Intel 82437VX", 0),
    CHIP(0x8086, 0x7100, "Intel 82439TX", 0),
    CHIP(0x8086, 0x7180, "Intel 82443LX/EX", 0),
    CHIP(0x8086, 0x7190, "Intel 82443BX/ZX", 0),
    CHIP(0x8086, 0x7192, "Intel 82443BX/ZX", 0),
    CHIP(0x8086, 0x71A0, "Intel 82443GX", 0),
    CHIP(0x8086, 0x71A2, "Intel 82443GX", 0),
    CHIP(0x8086, 0x84C4, "Intel 82454KX/GX", 0),
    CHIP(0x8086, 0x7120, "Intel 82810", 0),
    CHIP(0x8086, 0x7122, "Intel 82810-DC100", 0),
    CHIP(0x8086, 0x7124, "Intel 82810E", 0),
    CHIP(0x8086, 0x1130, "Intel 82815", 0),
    CHIP(0x8086, 0x2500, "Intel 82820", 0),
    CHIP(0x8086, 0x3575, "Intel 82830M", 0),
    CHIP(0x8086, 0x1A21, "Intel 82840", 0),
    CHIP(0x8086, 0x1A30, "Intel 82845", 0),
    CHIP(0x8086, 0x2560, "Intel 82845G/P", 0),
    CHIP(0x8086, 0x2530, "Intel 82850", 0),
    CHIP(0x8086, 0x3580, "Intel 852/855GM", 0),
    CHIP(0x8086, 0x3340, "Intel 855PM", 0),
    CHIP(0x8086, 0x2531, "Intel 82860", 0),
    CHIP(0x8086, 0x2570, "Intel 865", 0),
    CHIP(0x8086, 0x2578, "Intel 875/E7210", 0),
    CHIP(0x8086, 0x255D, "Intel E7205", 0),
    CHIP(0x8086, 0x2588, "Intel E7221", 0),
    CHIP(0x8086, 0x3592, "Intel E7320", 0),
    CHIP(0x8086, 0x2540, "Intel E7500", 0),
    CHIP(0x8086, 0x254C, "Intel E7501", 0),
    CHIP(0x8086, 0x2550, "Intel E7505", 0),
    CHIP(0x8086, 0x3590, "Intel E7520", 0),
    CHIP(0x8086, 0x359E, "Intel E7525", 0),
    CHIP(0x8086, 0x0500, "Intel E8870", 0),
    CHIP(0x8086, 0x2580, "Intel 910/915/925", 0),
    CHIP(0x8086, 0x2590, "Intel mobile 910/915", 0),
    CHIP(0x1106, 0x0505, "VIA VT82C505", 0x0100),
    CHIP(0x1106, 0x0576, "VIA VT82C576M", 0x0100),
    CHIP(0x1106, 0x0585, "VIA VT82C585VP/VPX", 0),
    CHIP(0x1106, 0x0595, "VIA VT82C595/AMD-640", 0),
    CHIP(0x1106, 0x0597, "VIA VT82C597", 0),
    CHIP(0x1106, 0x0598, "VIA VT82C598", 0),
    CHIP(0x1106, 0x0685, "VIA VT82C685", 0x0100),
    CHIP(0x1106, 0x0501, "VIA VT8501", 0),
    CHIP(0x1106, 0x0691, "VIA VT82C691/693/694", 0),
    CHIP(0x1106, 0x0693, "VIA VT82C693", 0),
    CHIP(0x1106, 0x0601, "VIA VT8601", 0),
    CHIP(0x1106, 0x0605, "VIA VT8605", 0),
    CHIP(0x1106, 0x0391, "VIA VT8371", 0),
    CHIP(0x1106, 0x0305, "VIA VT8363/8365", 0),
    CHIP(0x1106, 0x3099, "VIA VT8366", 0),
    CHIP(0x1106, 0x3091, "VIA VT8633", 0),
    CHIP(0x1106, 0x3101, "VIA VT8653", 0),
    CHIP(0x1106, 0x3102, "VIA VT8662", 0),
    CHIP(0x1106, 0x3103, "VIA VT8615", 0),
    CHIP(0x1106, 0x3112, "VIA VT8361", 0),
    CHIP(0x1106, 0x3133, "VIA VT3133", 0),
    CHIP(0x1106, 0x3148, "VIA VT8751", 0),
    CHIP(0x1106, 0x3128, "VIA VT8753/8754", 0),
    CHIP(0x1106, 0x3189, "VIA VT8377", 0),
    CHIP(0x1106, 0x3205, "VIA VT8378", 0),
    CHIP(0x1022, 0x7006, "AMD 751", 0),
    CHIP(0x1022, 0x700E, "AMD 761", 0),
    CHIP(0x1022, 0x700C, "AMD 762", 0),
    CHIP(0x1022, 0x7454, "AMD 8151", 0),
    CHIP(0x1039, 0x0496, "SiS 85C496/497", 0x0200),
    CHIP(0x1039, 0x0406, "SiS 501/5101/5501", 0),
    CHIP(0x1039, 0x5511, "SiS 5511", 0),
    CHIP(0x1039, 0x5571, "SiS 5571", 0),
    CHIP(0x1039, 0x5591, "SiS 5591/5592", 0),
    CHIP_LPC(0x1039, 0x5596, "SiS 5596", 0),
    CHIP(0x1039, 0x5597, "SiS 5597/5598", 0),
    CHIP(0x1039, 0x0530, "SiS 530", 0),
    CHIP(0x1039, 0x0540, "SiS 540", 0),
    CHIP(0x1039, 0x5600, "SiS 600", 0),
    CHIP(0x1039, 0x0620, "SiS 620", 0),
    CHIP_LPC(0x1039, 0x0630, "SiS 630", 0),
    CHIP_LPC(0x1039, 0x0635, "SiS 635", 0),
    CHIP_LPC(0x1039, 0x0640, "SiS 640", 0),
    CHIP_LPC(0x1039, 0x0645, "SiS 645", 0),
    CHIP_LPC(0x1039, 0x0646, "SiS 645DX", 0),
    CHIP_LPC(0x1039, 0x0648, "SiS 648", 0),
    CHIP_LPC(0x1039, 0x0650, "SiS 650", 0),
    CHIP_LPC(0x1039, 0x0651, "SiS 651", 0),
    CHIP_LPC(0x1039, 0x0655, "SiS 655", 0),
    CHIP_LPC(0x1039, 0x0730, "SiS 730", 0),
    CHIP_LPC(0x1039, 0x0733, "SiS 733", 0),
    CHIP_LPC(0x1039, 0x0735, "SiS 735", 0),
    CHIP_LPC(0x1039, 0x0740, "SiS 740", 0),
    CHIP_LPC(0x1039, 0x0745, "SiS 745", 0),
    CHIP_LPC(0x1039, 0x0746, "SiS 746", 0),
    CHIP_LPC(0x1039, 0x0748, "SiS 748", 0),
    CHIP_LPC(0x1039, 0x0755, "SiS 755", 0),
    CHIP(0x10B9, 0x1451, "ALi M1451", 0x0300),
    CHIP(0x10B9, 0x1489, "ALi M1489", 0x0301),
    CHIP(0x10B9, 0x1521, "ALi M1521", 0),
    CHIP(0x10B9, 0x1531, "ALi M1531", 0),
    CHIP(0x10B9, 0x1541, "ALi M1541/1542", 0),
    CHIP(0x10B9, 0x1561, "ALi M1561", 0),
    CHIP(0x10B9, 0x1621, "ALi M1621", 0),
    CHIP(0x10B9, 0x1631, "ALi M1631", 0),
    CHIP(0x10B9, 0x1632, "ALi M1632M", 0),
    CHIP(0x10B9, 0x1641, "ALi M1641", 0),
    CHIP(0x10B9, 0x1647, "ALi M1647", 0),
    CHIP(0x10B9, 0x1651, "ALi M1651", 0),
    CHIP(0x10B9, 0x1671, "ALi M1671", 0),
    CHIP(0x10B9, 0x1672, "ALi M1672", 0),
    CHIP(0x1080, 0x0600, "Cypress CY82C599", 0x0400),
    CHIP(0x1080, 0xC691, "Cypress CY82C691", 0),
    CHIP(0x10DE, 0x01A4, "NVIDIA IGP", 0),
    CHIP(0x10DE, 0x01E0, "NVIDIA IGP2", 0)};

static const uf_chipset_id_t south_ids[] = {CHIP(0x8086, 0x0484, "Intel SIO", 0x0104),
    CHIP(0x8086, 0x122E, "Intel PIIX", 0x0101),
    CHIP(0x8086, 0x1234, "Intel MPIIX", 0x0100),
    CHIP(0x8086, 0x7000, "Intel PIIX3", 0x0101),
    CHIP(0x8086, 0x7110, "Intel PIIX4", 0x0103),
    CHIP(0x8086, 0x2410, "Intel ICH", 0x0200),
    CHIP(0x8086, 0x2420, "Intel ICH0", 0x0200),
    CHIP(0x8086, 0x2440, "Intel ICH2", 0x0200),
    CHIP(0x8086, 0x244C, "Intel ICH2-M", 0x0200),
    CHIP(0x8086, 0x248C, "Intel ICH3-M", 0x0200),
    CHIP(0x8086, 0x2480, "Intel ICH3-S", 0x0200),
    CHIP(0x8086, 0x24C0, "Intel ICH4", 0x0200),
    CHIP(0x8086, 0x24CC, "Intel ICH4-M", 0x0200),
    CHIP(0x8086, 0x24D0, "Intel ICH5", 0x0200),
    CHIP(0x8086, 0x2640, "Intel ICH6", 0x1700),
    CHIP(0x8086, 0x2641, "Intel ICH6-M", 0x1700),
    CHIP(0x8086, 0x2642, "Intel ICH6W", 0x1700),
    CHIP(0x8086, 0x25A1, "Intel 6300ESB", 0x0200),
    CHIP(0x1106, 0x0586, "VIA VT82C586", 0x0300),
    CHIP(0x1106, 0x0596, "VIA VT82C596", 0x0301),
    CHIP(0x1106, 0x0686, "VIA VT82C686", 0x0301),
    CHIP(0x1106, 0x8231, "VIA VT8231", 0x0300),
    CHIP_LPC(0x1106, 0x3074, "VIA VT8233", 0x0310),
    CHIP_LPC(0x1106, 0x3147, "VIA VT8233", 0x0310),
    CHIP_LPC(0x1106, 0x3177, "VIA VT8235", 0x0310),
    CHIP_LPC(0x1106, 0x3227, "VIA VT8237", 0x0310),
    CHIP(0x1022, 0x7408, "AMD 756", 0x0300),
    CHIP(0x1022, 0x7410, "AMD 766", 0x0300),
    CHIP(0x1022, 0x7440, "AMD 768", 0x0300),
    CHIP(0x1022, 0x7468, "AMD 8111", 0x0300),
    CHIP(0x1039, 0x0008, "SiS south bridge", 0),
    CHIP(0x1039, 0x0018, "SiS 950", 0),
    CHIP(0x1039, 0x0964, "SiS 964", 0),
    CHIP(0x10B9, 0x1449, "ALi M1449", 0),
    CHIP(0x10B9, 0x1523, "ALi M1523", 0x0400),
    CHIP(0x10B9, 0x1533, "ALi M1533", 0x0401),
    CHIP(0x10B9, 0x1543, "ALi M1543", 0x0401),
    CHIP(0x10B9, 0x1535, "ALi M1535", 0x0401),
    CHIP(0x1055, 0x9460, "SMSC SLC90E66", 0x0600),
    CHIP(0x10AD, 0x0565, "Winbond W83C553", 0x0700),
    CHIP(0x1283, 0x8872, "ITE IT8871/8872", 0x0801),
    CHIP(0x1283, 0x8888, "ITE IT8888", 0x0802),
    CHIP(0x1166, 0x0200, "ServerWorks OSB4", 0x0900),
    CHIP(0x1066, 0x0002, "PicoPower Vesuvius", 0x1000),
    CHIP(0x1066, 0x8002, "PicoPower Vesuvius", 0x1000),
    CHIP_LPC(0x100B, 0x0500, "National Geode SCx200", 0x1100),
    CHIP_LPC(0x100B, 0x0510, "National Geode SC1100", 0x1100),
    CHIP(0x1078, 0x0000, "Cyrix Cx5510", 0x1100),
    CHIP(0x1078, 0x0002, "Cyrix Cx5520", 0x1100),
    CHIP(0x1078, 0x0100, "Cyrix Cx5530", 0x1100),
    CHIP(0x1045, 0xC558, "OPTi 82C558", 0x1200),
    CHIP(0x1045, 0xC568, "OPTi 82C568", 0x1200),
    CHIP(0x3388, 0x8012, "HiNT VXPro-II", 0x1300),
    CHIP(0x1060, 0x886A, "UMC UM8886BF", 0x1400),
    CHIP(0x1080, 0xC693, "Cypress CY82C693", 0x1500),
    CHIP(0x10DE, 0x01B2, "NVIDIA MCP", 0x1600),
    CHIP(0x10DE, 0x0060, "NVIDIA MCP2", 0x1600)};

enum {
    UF_CHIPSET_METHOD_NONE = 0,
    UF_CHIPSET_NORTH_VIA_OLD = 0x0100,
    UF_CHIPSET_NORTH_SIS_496 = 0x0200,
    UF_CHIPSET_NORTH_ALI = 0x0300,
    UF_CHIPSET_NORTH_FINALI = 0x0301,
    UF_CHIPSET_NORTH_CYPRESS = 0x0400
};

static bool pci_read(const uf_chipset_t *chipset, const uf_pci_function_info_t *device, uint8_t reg, uint32_t *value) {
    return uf_pci_read32(&chipset->pci, device->address, reg, value);
}

static bool pci_write(const uf_chipset_t *chipset, const uf_pci_function_info_t *device, uint8_t reg, uint32_t value) {
    return uf_pci_write32(&chipset->pci, device->address, reg, value);
}

static bool indexed_read8(const uf_hardware_t *hardware,
    uf_io_port_t index_port,
    uf_io_port_t data_port,
    uint8_t index,
    uint8_t *value) {
    return (hardware->out8(hardware->context, index_port, index) && hardware->in8(hardware->context, data_port, value));
}

static bool indexed_write8(const uf_hardware_t *hardware,
    uf_io_port_t index_port,
    uf_io_port_t data_port,
    uint8_t index,
    uint8_t value) {
    return (
        hardware->out8(hardware->context, index_port, index) && hardware->out8(hardware->context, data_port, value));
}

static bool set_north_enabled(uf_chipset_t *chipset, bool enabled) {
    const uf_hardware_t *hardware = chipset->pci.hardware;
    uint8_t value;

    switch (chipset->north_method) {
    case UF_CHIPSET_METHOD_NONE:
        return true;
    case UF_CHIPSET_NORTH_VIA_OLD:
        if (enabled) {
            if (!indexed_read8(hardware, UINT16_C(0xA8), UINT16_C(0xA9), UINT8_C(0x11), &value)) {
                return false;
            }
            chipset->north_saved[0] = value;
            value |= UINT8_C(0x40);
        } else {
            value = (uint8_t)chipset->north_saved[0];
        }
        return indexed_write8(hardware, UINT16_C(0xA8), UINT16_C(0xA9), UINT8_C(0x11), value);
    case UF_CHIPSET_NORTH_SIS_496:
        if (enabled) {
            if (!pci_read(chipset, &chipset->north, UINT8_C(0xD0), &chipset->north_saved[0])) {
                return false;
            }
            return pci_write(chipset, &chipset->north, UINT8_C(0xD0), chipset->north_saved[0] | UINT32_C(0xF8));
        }
        return pci_write(chipset, &chipset->north, UINT8_C(0xD0), chipset->north_saved[0]);
    case UF_CHIPSET_NORTH_ALI:
        if (enabled) {
            if (!pci_read(chipset, &chipset->north, UINT8_C(0x4C), &chipset->north_saved[0])) {
                return false;
            }
            return pci_write(chipset, &chipset->north, UINT8_C(0x4C), chipset->north_saved[0] & UINT32_C(0x00FFFFFF));
        }
        return pci_write(chipset, &chipset->north, UINT8_C(0x4C), chipset->north_saved[0]);
    case UF_CHIPSET_NORTH_FINALI:
        if (enabled) {
            if (!indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x03), UINT8_C(0xC5)) ||
                !indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x12), &value)) {
                return false;
            }
            chipset->north_saved[0] = value;
            if (!indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x12), value | UINT8_C(0x11))) {
                return false;
            }
            if (!indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x21), &value)) {
                return false;
            }
            chipset->north_saved[1] = value;
            if (!indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x21), value | UINT8_C(0x20))) {
                return false;
            }
            if (!indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x2B), &value)) {
                return false;
            }
            chipset->north_saved[2] = value;
            return indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x2B), value | UINT8_C(0x20));
        }
        return (
            indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x12), (uint8_t)chipset->north_saved[0]) &&
            indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x21), (uint8_t)chipset->north_saved[1]) &&
            indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x2B), (uint8_t)chipset->north_saved[2]) &&
            indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x03), UINT8_C(0)));
    case UF_CHIPSET_NORTH_CYPRESS:
        if (enabled) {
            if (!indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x12), &value)) {
                return false;
            }
            chipset->north_saved[0] = value;
            value &= UINT8_C(0xEF);
        } else {
            value = (uint8_t)chipset->north_saved[0];
        }
        return indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x12), value);
    default:
        return false;
    }
}

static bool save_and_write(uf_chipset_t *chipset, uint8_t slot, uint8_t reg, uint32_t and_mask, uint32_t or_mask) {
    if (!pci_read(chipset, &chipset->south, reg, &chipset->south_saved[slot])) {
        return false;
    }
    chipset->south_saved_valid |= (uint8_t)(UINT8_C(1) << slot);
    return pci_write(chipset, &chipset->south, reg, (chipset->south_saved[slot] & and_mask) | or_mask);
}

static bool restore_reg(uf_chipset_t *chipset, uint8_t slot, uint8_t reg) {
    if ((chipset->south_saved_valid & (uint8_t)(UINT8_C(1) << slot)) == 0) {
        return true;
    }
    if (!pci_write(chipset, &chipset->south, reg, chipset->south_saved[slot])) {
        return false;
    }
    chipset->south_saved_valid &= (uint8_t)~(uint8_t)(UINT8_C(1) << slot);
    return true;
}

static bool set_south_simple(uf_chipset_t *chipset, bool enabled, uint8_t reg, uint32_t and_mask, uint32_t or_mask) {
    return enabled ? save_and_write(chipset, 0, reg, and_mask, or_mask) : restore_reg(chipset, 0, reg);
}

static bool set_sis_enabled(uf_chipset_t *chipset, bool enabled) {
    const uf_hardware_t *hardware = chipset->pci.hardware;
    uint8_t subtype = (uint8_t)chipset->south_method;
    uint8_t value;

    if (enabled) {
        if (!save_and_write(chipset, 0, UINT8_C(0x40), UINT32_C(0xFFFFFFFB), UINT32_C(0x0B))) {
            return false;
        }
        if (subtype == 1 || subtype == 2) {
            uint8_t index = subtype == 1 ? UINT8_C(0x80) : UINT8_C(0x50);

            if (!indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), index, &value)) {
                return false;
            }
            chipset->south_saved[1] = value;
            chipset->south_saved_valid |= UINT8_C(0x02);
            if (!indexed_write8(hardware,
                    UINT16_C(0x22),
                    UINT16_C(0x23),
                    index,
                    (value & UINT8_C(0xDF)) | UINT8_C(0x04))) {
                return false;
            }
            if (subtype == 1) {
                if (!indexed_read8(hardware, UINT16_C(0x22), UINT16_C(0x23), UINT8_C(0x70), &value)) {
                    return false;
                }
                chipset->south_saved[2] = value;
                chipset->south_saved_valid |= UINT8_C(0x04);
                return indexed_write8(hardware,
                    UINT16_C(0x22),
                    UINT16_C(0x23),
                    UINT8_C(0x70),
                    (value & UINT8_C(0xDF)) | UINT8_C(0x04));
            }
            return true;
        }
        return save_and_write(chipset,
            1,
            UINT8_C(0x44),
            subtype == 3 ? UINT32_C(0xFFFFDFFF) : UINT32_C(0xFFFF7FFF),
            subtype == 3 ? UINT32_C(0x400) : UINT32_C(0x4000));
    }
    if (!restore_reg(chipset, 0, UINT8_C(0x40))) {
        return false;
    }
    if (subtype == 1 || subtype == 2) {
        uint8_t index = subtype == 1 ? UINT8_C(0x80) : UINT8_C(0x50);

        if ((chipset->south_saved_valid & UINT8_C(0x02)) != 0 &&
            !indexed_write8(hardware, UINT16_C(0x22), UINT16_C(0x23), index, (uint8_t)chipset->south_saved[1])) {
            return false;
        }
        chipset->south_saved_valid &= UINT8_C(0xFD);
        if (subtype == 1 && (chipset->south_saved_valid & UINT8_C(0x04)) != 0 &&
            !indexed_write8(hardware,
                UINT16_C(0x22),
                UINT16_C(0x23),
                UINT8_C(0x70),
                (uint8_t)chipset->south_saved[2])) {
            return false;
        }
        chipset->south_saved_valid &= UINT8_C(0xFB);
        return true;
    }
    return restore_reg(chipset, 1, UINT8_C(0x44));
}

static bool set_south_enabled(uf_chipset_t *chipset, bool enabled) {
    uint8_t family = (uint8_t)(chipset->south_method >> 8);
    uint8_t subtype = (uint8_t)chipset->south_method;

    switch (family) {
    case 0:
        return true;
    case 1: {
        uint32_t mask = UINT32_C(0x00440000);
        if ((subtype & 1) != 0) {
            mask |= UINT32_C(0x00800000);
        }
        if ((subtype & 2) != 0) {
            mask |= UINT32_C(0x02000000);
        }
        if ((subtype & 4) != 0) {
            mask = UINT32_C(0x00C00000);
        }
        return set_south_simple(chipset, enabled, UINT8_C(0x4C), UINT32_MAX, mask);
    }
    case 2:
        if (enabled) {
            return save_and_write(chipset, 0, UINT8_C(0x4C), UINT32_MAX, UINT32_C(0x10000)) &&
                   save_and_write(chipset, 1, UINT8_C(0xE0), UINT32_MAX, UINT32_C(0xFF000000));
        }
        return restore_reg(chipset, 0, UINT8_C(0x4C)) && restore_reg(chipset, 1, UINT8_C(0xE0));
    case 3:
        return set_south_simple(chipset,
            enabled,
            UINT8_C(0x40),
            UINT32_MAX,
            subtype == UINT8_C(0x10)
                ? UINT32_C(0x7F10)
                : UINT32_C(0xC0000001) | ((subtype & 1) != 0 ? UINT32_C(0x20000000) : UINT32_C(0)));
    case 4:
        if (enabled) {
            if (!save_and_write(chipset, 0, UINT8_C(0x44), UINT32_MAX, UINT32_C(0x47000000)) ||
                !save_and_write(chipset, 1, UINT8_C(0x40), UINT32_C(0xFFFFFFFB), UINT32_C(0))) {
                return false;
            }
            if ((subtype & 1) != 0) {
                return save_and_write(chipset, 2, UINT8_C(0x78), UINT32_MAX, UINT32_C(0x1000)) &&
                       save_and_write(chipset, 3, UINT8_C(0x7C), UINT32_MAX, UINT32_C(0x01000000));
            }
            return true;
        }
        if (!restore_reg(chipset, 0, UINT8_C(0x44)) || !restore_reg(chipset, 1, UINT8_C(0x40))) {
            return false;
        }
        return (subtype & 1) == 0 || (restore_reg(chipset, 2, UINT8_C(0x78)) && restore_reg(chipset, 3, UINT8_C(0x7C)));
    case 5:
        return set_sis_enabled(chipset, enabled);
    case 6:
        return set_south_simple(chipset, enabled, UINT8_C(0x4C), UINT32_MAX, UINT32_C(0x02C40000));
    case 7:
        return set_south_simple(chipset, enabled, UINT8_C(0x4C), UINT32_C(0xFFFFDF00), UINT32_C(0xD000));
    case 8:
        return set_south_simple(chipset,
            enabled,
            subtype == 1 ? UINT8_C(0x44) : UINT8_C(0x50),
            subtype == 1 ? UINT32_C(0xFFFF7FFF) : UINT32_C(0xFEFFFFFF),
            subtype == 1 ? UINT32_C(0) : UINT32_C(0xE0000000));
    case 9: {
        const uf_hardware_t *hardware = chipset->pci.hardware;
        uint8_t port_value;

        if (enabled) {
            if (!save_and_write(chipset, 0, UINT8_C(0x40), UINT32_MAX, UINT32_C(0x200)) ||
                !save_and_write(chipset, 1, UINT8_C(0x70), UINT32_MAX, UINT32_C(0x80)) ||
                !hardware->in8(hardware->context, UINT16_C(0x0C6F), &port_value)) {
                return false;
            }
            chipset->south_saved[2] = port_value;
            chipset->south_saved_valid |= UINT8_C(0x04);
            return hardware->out8(hardware->context, UINT16_C(0x0C6F), port_value | UINT8_C(0x40));
        }
        if (!restore_reg(chipset, 0, UINT8_C(0x40)) || !restore_reg(chipset, 1, UINT8_C(0x70))) {
            return false;
        }
        if ((chipset->south_saved_valid & UINT8_C(0x04)) != 0 &&
            !hardware->out8(hardware->context, UINT16_C(0x0C6F), (uint8_t)chipset->south_saved[2])) {
            return false;
        }
        chipset->south_saved_valid &= UINT8_C(0xFB);
        return true;
    }
    case 10: {
        const uf_hardware_t *hardware = chipset->pci.hardware;
        uint8_t value;

        if (enabled) {
            if (!indexed_read8(hardware, UINT16_C(0x24), UINT16_C(0x26), UINT8_C(0x03), &value)) {
                return false;
            }
            chipset->south_saved[0] = value;
            chipset->south_saved_valid |= UINT8_C(0x01);
            value |= UINT8_C(0x40);
        } else {
            if ((chipset->south_saved_valid & UINT8_C(0x01)) == 0) {
                return true;
            }
            value = (uint8_t)chipset->south_saved[0];
        }
        if (!indexed_write8(hardware, UINT16_C(0x24), UINT16_C(0x26), UINT8_C(0x03), value)) {
            return false;
        }
        if (!enabled) {
            chipset->south_saved_valid &= UINT8_C(0xFE);
        }
        return true;
    }
    case 11:
        return set_south_simple(chipset, enabled, UINT8_C(0x50), UINT32_MAX, UINT32_C(0x00060000));
    case 12:
        if (enabled) {
            return save_and_write(chipset, 0, UINT8_C(0x44), UINT32_MAX, UINT32_C(0x80000000)) &&
                   save_and_write(chipset, 1, UINT8_C(0x48), UINT32_C(0x00FFFFFF), UINT32_C(0x3F000000));
        }
        return restore_reg(chipset, 0, UINT8_C(0x44)) && restore_reg(chipset, 1, UINT8_C(0x48));
    case 13:
        return set_south_simple(chipset, enabled, UINT8_C(0x60), UINT32_C(0xFFFFEFFF), UINT32_C(0x02));
    case 14:
        return set_south_simple(chipset, enabled, UINT8_C(0x44), UINT32_C(0xBFFFFFFF), UINT32_C(0));
    case 15:
        return set_south_simple(chipset, enabled, UINT8_C(0x44), UINT32_MAX, UINT32_C(0xE0000000));
    case 16:
        if (enabled) {
            return save_and_write(chipset, 0, UINT8_C(0x44), UINT32_MAX, UINT32_C(0x100)) &&
                   save_and_write(chipset, 1, UINT8_C(0x70), UINT32_C(0xFFE0FFFF), UINT32_C(0xC0)) &&
                   save_and_write(chipset, 2, UINT8_C(0x74), UINT32_C(0), UINT32_C(0)) &&
                   save_and_write(chipset, 3, UINT8_C(0x78), UINT32_C(0), UINT32_C(0)) &&
                   save_and_write(chipset, 4, UINT8_C(0x7C), UINT32_C(0), UINT32_C(0));
        }
        return restore_reg(chipset, 0, UINT8_C(0x44)) && restore_reg(chipset, 1, UINT8_C(0x70)) &&
               restore_reg(chipset, 2, UINT8_C(0x74)) && restore_reg(chipset, 3, UINT8_C(0x78)) &&
               restore_reg(chipset, 4, UINT8_C(0x7C));
    case 17:
        if (enabled) {
            return save_and_write(chipset, 0, UINT8_C(0xDC), UINT32_MAX, UINT32_C(1)) &&
                   save_and_write(chipset, 1, UINT8_C(0xD8), UINT32_MAX, UINT32_C(0xFF0F));
        }
        return restore_reg(chipset, 0, UINT8_C(0xDC)) && restore_reg(chipset, 1, UINT8_C(0xD8));
    default:
        return false;
    }
}

static bool lpc_unlock(uf_chipset_t *chipset) {
    const uf_hardware_t *hardware = chipset->pci.hardware;
    uint8_t sequence[] = {UINT8_C(0x87), UINT8_C(0x87), UINT8_C(0x87), UINT8_C(0x01), UINT8_C(0x55)};

    for (uint8_t index = 0; index < sizeof(sequence); ++index) {
        if (!hardware->out8(hardware->context, chipset->lpc_base, sequence[index])) {
            return false;
        }
    }
    return hardware->out8(hardware->context,
        chipset->lpc_base,
        chipset->lpc_base == UINT16_C(0x2E) ? UINT8_C(0x55) : UINT8_C(0xAA));
}

static bool set_lpc_enabled(uf_chipset_t *chipset, bool enabled) {
    const uf_hardware_t *hardware = chipset->pci.hardware;
    uint8_t family = (uint8_t)(chipset->lpc_method >> 8);
    uint8_t value;

    if (family == 0) {
        return true;
    }
    if ((family != 1 && family != 2) || !lpc_unlock(chipset)) {
        return false;
    }
    if (enabled) {
        if (!indexed_read8(hardware, chipset->lpc_base, chipset->lpc_base + 1, UINT8_C(0x24), &value)) {
            return false;
        }
        chipset->lpc_saved = value;
        value = family == 1 ? value | UINT8_C(0x7C) : (value & UINT8_C(0xC7)) | UINT8_C(0x28);
    } else {
        value = chipset->lpc_saved;
    }
    if (!indexed_write8(hardware, chipset->lpc_base, chipset->lpc_base + 1, UINT8_C(0x24), value)) {
        return false;
    }
    if (family == 1) {
        uint8_t control;
        if (!indexed_read8(hardware, chipset->lpc_base, chipset->lpc_base + 1, UINT8_C(0x02), &control)) {
            return false;
        }
        return indexed_write8(hardware,
            chipset->lpc_base,
            chipset->lpc_base + 1,
            UINT8_C(0x02),
            control | UINT8_C(0x02));
    }
    return hardware->out8(hardware->context, chipset->lpc_base, UINT8_C(0xAA));
}

static const uf_chipset_id_t *find_id(const uf_chipset_id_t *ids, uint16_t count, uint16_t vendor, uint16_t device) {
    for (uint16_t index = 0; index < count; ++index) {
        if (ids[index].vendor == vendor && ids[index].device == device) {
            return &ids[index];
        }
    }
    return NULL;
}

static bool visit_chipset(void *context, const uf_pci_function_info_t *device) {
    uf_chipset_detect_context_t *detect = context;
    const uf_chipset_id_t *id;

    id = find_id(north_ids, (uint16_t)(sizeof(north_ids) / sizeof(north_ids[0])), device->vendor_id, device->device_id);
    if (id != NULL && !detect->chipset->north_found && device->class_code == UINT8_C(0x06) &&
        device->subclass == UINT8_C(0x00)) {
        detect->chipset->north = *device;
        detect->chipset->north_found = true;
        detect->chipset->north_name = id->name;
        detect->chipset->north_method = id->method;
        if (id->detect_lpc) {
            detect->wants_lpc = true;
        }
    }

    id = find_id(south_ids, (uint16_t)(sizeof(south_ids) / sizeof(south_ids[0])), device->vendor_id, device->device_id);
    if (id != NULL && !detect->chipset->south_found && device->class_code == UINT8_C(0x06) &&
        (device->subclass == UINT8_C(0x01) || device->subclass == UINT8_C(0x80) || device->subclass == UINT8_C(0x00))) {
        detect->chipset->south = *device;
        detect->chipset->south_found = true;
        detect->chipset->south_name = id->name;
        detect->chipset->south_method = id->method;
        if (id->detect_lpc) {
            detect->wants_lpc = true;
        }
    }
    return true;
}

static bool lpc_read(uf_chipset_t *chipset, uint8_t index, uint8_t *value) {
    return indexed_read8(chipset->pci.hardware, chipset->lpc_base, chipset->lpc_base + 1, index, value);
}

static bool lpc_lock(uf_chipset_t *chipset, bool ite) {
    const uf_hardware_t *hardware = chipset->pci.hardware;

    if (ite) {
        uint8_t value;
        return lpc_read(chipset, UINT8_C(0x02), &value) &&
               indexed_write8(hardware, chipset->lpc_base, chipset->lpc_base + 1, UINT8_C(0x02), value | UINT8_C(0x02));
    }
    return hardware->out8(hardware->context, chipset->lpc_base, UINT8_C(0xAA));
}

static bool detect_lpc_at(uf_chipset_t *chipset, uf_io_port_t base) {
    uint8_t high;
    uint8_t low;
    uint16_t id;
    bool ite = false;

    chipset->lpc_base = base;
    if (!lpc_unlock(chipset) || !lpc_read(chipset, UINT8_C(0x20), &high) || !lpc_read(chipset, UINT8_C(0x21), &low)) {
        chipset->lpc_base = 0;
        return false;
    }
    id = ((uint16_t)high << 8) | low;
    switch (id) {
    case 0x8702:
    case 0x8711:
    case 0x8712:
    case 0x8722:
        chipset->lpc_method = 0;
        ite = true;
        break;
    case 0x8705:
    case 0x8710:
        chipset->lpc_method = 0x0100;
        ite = true;
        break;
    default:
        switch (id & UINT16_C(0xFFF0)) {
        case 0x5210:
        case 0x5230:
        case 0x5950:
        case 0x7080:
        case 0x8280:
            chipset->lpc_method = 0;
            break;
        case 0x6010:
        case 0x6800:
        case 0x6810:
            chipset->lpc_method = 0x0200;
            break;
        default:
            chipset->lpc_base = 0;
            return false;
        }
        break;
    }
    if (!lpc_lock(chipset, ite)) {
        chipset->lpc_base = 0;
        chipset->lpc_method = 0;
        return false;
    }
    return true;
}

static void apply_integrated_overrides(uf_chipset_t *chipset) {
    if (!chipset->north_found || chipset->north.vendor_id != 0x1039) {
        return;
    }
    switch (chipset->north.device_id) {
    case 0x0496:
        chipset->south_method = 0;
        break;
    case 0x0406:
        chipset->south_method = 0x0501;
        break;
    case 0x5511:
    case 0x5596:
        chipset->south_method = 0x0502;
        break;
    case 0x0540:
    case 0x0630:
    case 0x0635:
    case 0x0640:
    case 0x0645:
    case 0x0646:
    case 0x0648:
    case 0x0650:
    case 0x0651:
    case 0x0655:
    case 0x0730:
    case 0x0733:
    case 0x0735:
    case 0x0740:
    case 0x0745:
    case 0x0746:
    case 0x0748:
    case 0x0755:
        chipset->south_method = 0x0504;
        break;
    default:
        if (chipset->south_method == 0) {
            chipset->south_method = 0x0503;
        }
        break;
    }
}

bool uf_chipset_detect(uf_chipset_t *chipset, const uf_hardware_t *hardware) {
    uf_chipset_detect_context_t detect;
    uint8_t mechanism;

    if (chipset == NULL || !uf_hardware_is_valid(hardware)) {
        return false;
    }
    memset(chipset, 0, sizeof(*chipset));
    if (!uf_pci_bus_init(&chipset->pci, hardware)) {
        return false;
    }
    /*
     * Match PCI.PAS: select configuration mechanism 1 when port CFB is
     * implemented, while leaving an absent (0xFF) register untouched.
     */
    if (hardware->in8(hardware->context, UINT16_C(0xCFB), &mechanism) && mechanism != UINT8_C(0xFF)) {
        (void)hardware->out8(hardware->context, UINT16_C(0xCFB), mechanism | UINT8_C(1));
    }
    detect.chipset = chipset;
    detect.wants_lpc = false;
    if (!uf_pci_enumerate(&chipset->pci, visit_chipset, &detect)) {
        return false;
    }
    apply_integrated_overrides(chipset);
    if (detect.wants_lpc) {
        if (!detect_lpc_at(chipset, UINT16_C(0x2E)) && !detect_lpc_at(chipset, UINT16_C(0x4E))) {
            chipset->lpc_base = 0;
            chipset->lpc_method = 0;
        }
    }
    if (chipset->north_found && chipset->south_found) {
        size_t north_length = strlen(chipset->north_name);
        size_t south_length = strlen(chipset->south_name);
        size_t available = sizeof(chipset->name_storage) - 1;

        if (north_length > available) {
            north_length = available;
        }
        memcpy(chipset->name_storage, chipset->north_name, north_length);
        available -= north_length;
        if (available >= 3) {
            memcpy(chipset->name_storage + north_length, " + ", 3);
            north_length += 3;
            available -= 3;
        }
        if (south_length > available) {
            south_length = available;
        }
        memcpy(chipset->name_storage + north_length, chipset->south_name, south_length);
        chipset->name_storage[north_length + south_length] = '\0';
        chipset->name = chipset->name_storage;
    } else if (chipset->north_found) {
        chipset->name = chipset->north_name;
    } else if (chipset->south_found) {
        chipset->name = chipset->south_name;
    } else {
        chipset->name = "Unknown PCI chipset";
    }
    return (chipset->north_found || chipset->south_found);
}

bool uf_chipset_rom_set_enabled(uf_chipset_t *chipset, bool enabled) {
    bool north_ok;
    bool south_ok;
    bool lpc_ok;

    if (chipset == NULL || chipset->pci.hardware == NULL || chipset->rom_enabled == enabled) {
        return chipset != NULL;
    }
    if (enabled) {
        chipset->south_saved_valid = 0;
        north_ok = set_north_enabled(chipset, true);
        south_ok = north_ok ? set_south_enabled(chipset, true) : false;
        lpc_ok = south_ok ? set_lpc_enabled(chipset, true) : false;
        if (!lpc_ok) {
            if (north_ok) {
                (void)set_south_enabled(chipset, false);
            }
            if (north_ok) {
                (void)set_north_enabled(chipset, false);
            }
            return false;
        }
    } else {
        lpc_ok = set_lpc_enabled(chipset, false);
        south_ok = set_south_enabled(chipset, false);
        north_ok = set_north_enabled(chipset, false);
        if (!lpc_ok || !south_ok || !north_ok) {
            return false;
        }
    }
    chipset->rom_enabled = enabled;
    return true;
}
