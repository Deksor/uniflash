#include "uniflash/generic_algorithms.h"

enum { UF_AMD_ERASE_MAX_ATTEMPTS = 4 };

#define UF_AMD_SECTOR_ERASE_POLL_LIMIT UINT16_C(25000)
#define UF_AMD_SECTOR_ERASE_POLL_DELAY_US UINT32_C(1000)

static bool read_source_byte(struct uf_flash_service *service, uf_phys_addr_t source_address, uint8_t *value) {
    if (service->access.read_source_byte == NULL ||
        !service->access.read_source_byte(service->access.context, source_address, value)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    return true;
}

static bool intel_reset(struct uf_flash_service *service) {
    return (uf_flash_service_write_byte(service, 0, UINT8_C(0xFF)) &&
            uf_flash_service_write_byte(service, 0, UINT8_C(0xFF)));
}

bool uf_flash_program_generic_page(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    for (uint8_t attempt = 0; attempt < 4; ++attempt) {
        uint16_t timeout = UINT16_C(1000);
        uint8_t expected;
        uint8_t status = 0;

        if (!uf_flash_service_command(service, UINT8_C(0xA0))) {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset) {
            uint8_t value;

            if (!read_source_byte(service, source_address + (uf_phys_addr_t)offset, &value) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, value)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
        }
        if (!service->access.delay_us(service->access.context, UINT32_C(5000)) ||
            !read_source_byte(service,
                source_address + (uf_phys_addr_t)service->chip->page_size_bytes - 1,
                &expected)) {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        expected &= UINT8_C(0x80);

        do {
            if (!uf_flash_service_read_byte(service,
                    position + (uf_rom_offset_t)service->chip->page_size_bytes - 1,
                    &status) ||
                !service->access.delay_us(service->access.context, UINT32_C(50))) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            --timeout;
        } while ((status & UINT8_C(0x80)) != expected && timeout > 0);
        if (timeout == 0) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        if (!uf_flash_service_read_byte(service,
                position + (uf_rom_offset_t)service->chip->page_size_bytes - 1,
                &status)) {
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
        if ((status & UINT8_C(0x80)) == expected) {
            return service->error == UF_FLASH_ERROR_NONE;
        }
    }

    service->error = UF_FLASH_ERROR_PROGRAM;
    return false;
}

bool uf_flash_program_intel_sector(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        uint8_t value;
        uint8_t attempt;

        if (!read_source_byte(service, source_address + (uf_phys_addr_t)offset, &value)) {
            return false;
        }
        if (value == UINT8_C(0xFF)) {
            continue;
        }

        for (attempt = 0; attempt < 4; ++attempt) {
            uint16_t timeout = UINT16_C(100);
            uint8_t status;

            if (!uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, UINT8_C(0x40)) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, value)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            do {
                if (!uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status) ||
                    !service->access.delay_us(service->access.context, UINT32_C(10))) {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    return false;
                }
                --timeout;
            } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);
            if (timeout == 0) {
                service->error = UF_FLASH_ERROR_PROGRAM;
            }
            if (!uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, UINT8_C(0x50))) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            if ((status & UINT8_C(0x98)) == UINT8_C(0x80)) {
                break;
            }
        }
        if (attempt == 4) {
            (void)intel_reset(service);
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }

    if (!intel_reset(service)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    return service->error == UF_FLASH_ERROR_NONE;
}

static bool erase_intel_sector_with_command(struct uf_flash_service *service,
    uf_rom_offset_t sector_address,
    uint8_t setup_command) {
    uint8_t attempt;
    uint8_t status = 0;

    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    for (attempt = 0; attempt < 4; ++attempt) {
        uint16_t timeout = UINT16_C(65000);

        if (!uf_flash_service_write_byte(service, sector_address, setup_command) ||
            !uf_flash_service_write_byte(service, sector_address, UINT8_C(0xD0))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        do {
            if (!uf_flash_service_read_byte(service, sector_address, &status) ||
                !service->access.delay_us(service->access.context, UINT32_C(1000))) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            --timeout;
        } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);
        if (timeout == 0) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        if (!uf_flash_service_read_byte(service, sector_address, &status) ||
            !uf_flash_service_write_byte(service, sector_address, UINT8_C(0x50))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if ((status & UINT8_C(0xB8)) == UINT8_C(0x80)) {
            break;
        }
    }

    if (!intel_reset(service)) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    if (attempt == 4 || (status & UINT8_C(0xB8)) != UINT8_C(0x80) || service->error != UF_FLASH_ERROR_NONE) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    return true;
}

bool uf_flash_erase_intel_sector(struct uf_flash_service *service, uf_rom_offset_t sector_address) {
    return erase_intel_sector_with_command(service, sector_address, UINT8_C(0x20));
}

bool uf_flash_erase_intel_sector_u(struct uf_flash_service *service, uf_rom_offset_t sector_address) {
    return erase_intel_sector_with_command(service, sector_address, UINT8_C(0x21));
}

bool uf_flash_program_amd_sector(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        uint8_t value;
        uint8_t attempt;

        if (!read_source_byte(service, source_address + (uf_phys_addr_t)offset, &value)) {
            return false;
        }
        if (value == UINT8_C(0xFF)) {
            continue;
        }

        for (attempt = 0; attempt < 4; ++attempt) {
            uint16_t timeout = UINT16_C(30);
            uint8_t status;

            if (!uf_flash_service_command(service, UINT8_C(0xA0)) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, value) ||
                !uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            while ((status & UINT8_C(0x80)) != (value & UINT8_C(0x80)) && timeout > 0) {
                --timeout;
                if (!service->access.delay_us(service->access.context, UINT32_C(10)) ||
                    !uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status)) {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    return false;
                }
            }
            if (!uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            if ((status & UINT8_C(0x80)) == (value & UINT8_C(0x80))) {
                break;
            }
        }
        if (attempt == 4) {
            (void)uf_flash_service_command(service, UINT8_C(0xF0));
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }

    if (!uf_flash_service_command(service, UINT8_C(0xF0))) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    return true;
}

bool uf_flash_erase_amd_sector(struct uf_flash_service *service, uf_rom_offset_t sector_address) {

    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    for (uint8_t attempt = 0; attempt < UF_AMD_ERASE_MAX_ATTEMPTS; ++attempt) {
        uint16_t timeout = UF_AMD_SECTOR_ERASE_POLL_LIMIT;
        uint8_t previous;

        if (!uf_flash_service_command(service, UINT8_C(0x80)) ||
            !uf_flash_service_write_byte(service, (uf_rom_offset_t)UF_FLASH_COMMAND_ADDRESS_1, UINT8_C(0xAA)) ||
            !uf_flash_service_write_byte(service, (uf_rom_offset_t)UF_FLASH_COMMAND_ADDRESS_2, UINT8_C(0x55)) ||
            !uf_flash_service_write_byte(service, sector_address, UINT8_C(0x30)) ||
            !uf_flash_service_read_byte(service, sector_address, &previous)) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }

        while (timeout > 0) {
            uint8_t current;

            if (!uf_flash_service_read_byte(service, sector_address, &current)) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            if ((previous & UINT8_C(0x40)) == (current & UINT8_C(0x40))) {
                break;
            }
            if (!uf_flash_service_read_byte(service, sector_address, &previous) ||
                !service->access.delay_us(service->access.context, UF_AMD_SECTOR_ERASE_POLL_DELAY_US)) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            --timeout;
        }

        if (!uf_flash_service_command(service, UINT8_C(0xF0))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if (timeout > 0) {
            service->error = UF_FLASH_ERROR_NONE;
            return true;
        }
    }

    /*
     * GENFLASH.PAS line 246 tests TimeOut > 0 here, marking the successful
     * path as an erase failure. The loop and its comments show that zero is
     * the timeout condition, so the C port intentionally corrects that typo.
     */
    service->error = UF_FLASH_ERROR_ERASE;
    return false;
}

bool uf_flash_erase_amd_bulk(struct uf_flash_service *service, uf_rom_offset_t status_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    for (uint8_t attempt = 0; attempt < UF_AMD_ERASE_MAX_ATTEMPTS; ++attempt) {
        uint16_t timeout;
        uint8_t status;

        if (!uf_flash_service_command(service, UINT8_C(0x80)) || !uf_flash_service_command(service, UINT8_C(0x10))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }

        timeout = UINT16_C(15);
        while (timeout > 0) {
            if (!uf_flash_service_read_byte(service, status_address, &status)) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            if ((status & UINT8_C(0x08)) != 0) {
                break;
            }
            --timeout;
            if (!service->access.delay_us(service->access.context, UINT32_C(10))) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
        }

        timeout = UINT16_C(40000);
        while (timeout > 0) {
            if (!uf_flash_service_read_byte(service, status_address, &status)) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            if ((status & UINT8_C(0xA0)) != 0) {
                break;
            }
            --timeout;
            if (!service->access.delay_us(service->access.context, UINT32_C(1000))) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
        }

        if (!uf_flash_service_read_byte(service, status_address, &status) ||
            !uf_flash_service_command(service, UINT8_C(0xF0))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        if ((status & UINT8_C(0x80)) != 0) {
            service->error = UF_FLASH_ERROR_NONE;
            return true;
        }
    }

    service->error = UF_FLASH_ERROR_ERASE;
    return false;
}

bool uf_flash_erase_amd_embedded(struct uf_flash_service *service, uf_rom_offset_t ignored_address) {
    uint16_t timeout = UINT16_C(25000);
    uint8_t status;

    (void)ignored_address;
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }
    if (!uf_flash_service_write_byte(service, 0, UINT8_C(0x30)) ||
        !uf_flash_service_write_byte(service, 0, UINT8_C(0x30))) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }

    do {
        if (!service->access.delay_us(service->access.context, UINT32_C(1000))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
        --timeout;
        if (!uf_flash_service_read_byte(service, 0, &status)) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }
    } while ((status & UINT8_C(0x80)) == 0 && timeout > 0);

    if (timeout == 0) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

bool uf_flash_program_amd_embedded(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        uint8_t value;
        uint8_t attempt;

        if (!read_source_byte(service, source_address + (uf_phys_addr_t)offset, &value)) {
            return false;
        }
        if (value == UINT8_C(0xFF)) {
            continue;
        }

        for (attempt = 0; attempt < 4; ++attempt) {
            uint16_t timeout = UINT16_C(1000);
            uint8_t status;

            if (!uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, UINT8_C(0x10)) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, value)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }

            /*
             * GENFLASH.PAS masks Ld in place here. On a retry it therefore
             * writes only bit 7 instead of the original byte. Preserve that
             * observable legacy behavior until hardware evidence justifies
             * changing it.
             */
            value &= UINT8_C(0x80);
            do {
                if (!uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status) ||
                    !service->access.delay_us(service->access.context, UINT32_C(100))) {
                    service->error = UF_FLASH_ERROR_PROGRAM;
                    return false;
                }
                --timeout;
            } while ((status & UINT8_C(0x80)) != value && (status & UINT8_C(0x20)) == 0 && timeout > 0);
            if (timeout == 0) {
                service->error = UF_FLASH_ERROR_PROGRAM;
            }
            if (!uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            if ((status & UINT8_C(0xA0)) == value) {
                break;
            }
        }
        if (attempt == 4) {
            (void)intel_reset(service);
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }

    if (!intel_reset(service)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    return service->error == UF_FLASH_ERROR_NONE;
}

bool uf_flash_program_amd_flash(struct uf_flash_service *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address) {
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return false;
    }

    for (uint16_t offset = 0; offset < service->chip->page_size_bytes; ++offset) {
        uint8_t value;
        uint8_t status = 0;

        if (!read_source_byte(service, source_address + (uf_phys_addr_t)offset, &value)) {
            return false;
        }
        if (value == UINT8_C(0xFF)) {
            continue;
        }

        uint8_t attempt;
        for (attempt = 0; attempt < 25; ++attempt) {
            if (!uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, UINT8_C(0x40)) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, value) ||
                !service->access.delay_us(service->access.context, UINT32_C(10)) ||
                !uf_flash_service_write_byte(service, position + (uf_rom_offset_t)offset, UINT8_C(0xC0)) ||
                !service->access.delay_us(service->access.context, UINT32_C(6)) ||
                !uf_flash_service_read_byte(service, position + (uf_rom_offset_t)offset, &status)) {
                service->error = UF_FLASH_ERROR_PROGRAM;
                return false;
            }
            if (status == value) {
                break;
            }
        }
        /*
         * Pascal treats Attempt >= 25 as failure even when the 25th read
         * first matches. Keep that boundary behavior.
         */
        if (attempt >= 24) {
            (void)intel_reset(service);
            service->error = UF_FLASH_ERROR_PROGRAM;
            return false;
        }
    }

    if (!intel_reset(service)) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return false;
    }
    return true;
}

bool uf_flash_erase_amd_flash(struct uf_flash_service *service, uf_rom_offset_t ignored_address) {
    uint8_t status = 0;

    (void)ignored_address;
    if (service == NULL || service->chip == NULL || service->access.delay_us == NULL) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return false;
    }

    for (uint16_t attempt = 0; attempt < UINT16_C(1000); ++attempt) {
        if (!uf_flash_service_write_byte(service, 0, UINT8_C(0x20)) ||
            !uf_flash_service_write_byte(service, 0, UINT8_C(0x20)) ||
            !service->access.delay_us(service->access.context, UINT32_C(10000))) {
            service->error = UF_FLASH_ERROR_ERASE;
            return false;
        }

        for (uf_rom_offset_t address = 0; address < service->chip->capacity_bytes; ++address) {
            if (!uf_flash_service_write_byte(service, address, UINT8_C(0xA0)) ||
                !service->access.delay_us(service->access.context, UINT32_C(6)) ||
                !uf_flash_service_read_byte(service, address, &status)) {
                service->error = UF_FLASH_ERROR_ERASE;
                return false;
            }
            if (status != UINT8_C(0xFF)) {
                break;
            }
        }
        if (status == UINT8_C(0xFF)) {
            break;
        }
    }

    if (!intel_reset(service)) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    if (status != UINT8_C(0xFF)) {
        service->error = UF_FLASH_ERROR_ERASE;
        return false;
    }
    service->error = UF_FLASH_ERROR_NONE;
    return true;
}

bool uf_flash_register_amd_sector_erase(uf_flash_algorithm_registry_t *registry) {
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return false;
    }
    registry->erase[UF_FLASH_ERASE_AMD_SECTOR] = uf_flash_erase_amd_sector;
    return true;
}

bool uf_flash_register_amd_bulk_erase(uf_flash_algorithm_registry_t *registry) {
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return false;
    }
    registry->erase[UF_FLASH_ERASE_AMD_BULK] = uf_flash_erase_amd_bulk;
    return true;
}

bool uf_flash_register_amd_embedded_erase(uf_flash_algorithm_registry_t *registry) {
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return false;
    }
    registry->erase[UF_FLASH_ERASE_AMD_EMBEDDED] = uf_flash_erase_amd_embedded;
    return true;
}

bool uf_flash_register_generic_algorithms(uf_flash_algorithm_registry_t *registry) {
    if (!uf_flash_algorithm_registry_is_valid(registry)) {
        return false;
    }

    registry->program[UF_FLASH_PROGRAM_GENERIC_PAGE_BYTE] = uf_flash_program_generic_page;
    registry->program[UF_FLASH_PROGRAM_INTEL_SECTOR] = uf_flash_program_intel_sector;
    registry->program[UF_FLASH_PROGRAM_AMD_SECTOR] = uf_flash_program_amd_sector;
    registry->program[UF_FLASH_PROGRAM_AMD_EMBEDDED] = uf_flash_program_amd_embedded;
    registry->program[UF_FLASH_PROGRAM_AMD_FLASH] = uf_flash_program_amd_flash;

    registry->erase[UF_FLASH_ERASE_INTEL_SECTOR] = uf_flash_erase_intel_sector;
    registry->erase[UF_FLASH_ERASE_AMD_SECTOR] = uf_flash_erase_amd_sector;
    registry->erase[UF_FLASH_ERASE_AMD_BULK] = uf_flash_erase_amd_bulk;
    registry->erase[UF_FLASH_ERASE_AMD_EMBEDDED] = uf_flash_erase_amd_embedded;
    registry->erase[UF_FLASH_ERASE_AMD_FLASH] = uf_flash_erase_amd_flash;
    return true;
}
