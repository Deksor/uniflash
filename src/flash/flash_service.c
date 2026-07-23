#include <string.h>

#include "uniflash/flash_service.h"

uf_bool_t uf_flash_access_is_valid(const uf_flash_access_t *access)
{
    if (
        access == NULL
        || access->read_byte == NULL
        || access->write_byte == NULL
    ) {
        return UF_FALSE;
    }
    return UF_TRUE;
}

uf_bool_t uf_flash_algorithm_registry_is_valid(
    const uf_flash_algorithm_registry_t *registry
)
{
    if (
        registry == NULL
        || registry->program[UF_FLASH_PROGRAM_NONE] != NULL
        || registry->erase[UF_FLASH_ERASE_NONE] != NULL
    ) {
        return UF_FALSE;
    }
    return UF_TRUE;
}

void uf_flash_service_clear_selection(uf_flash_service_t *service)
{
    if (service == NULL) {
        return;
    }
    service->manufacturer = NULL;
    service->chip = NULL;
    service->manufacturer_id = UINT8_C(0xFF);
    service->device_id = UINT8_C(0xFF);
}

uf_bool_t uf_flash_service_init(
    uf_flash_service_t *service,
    const uf_flash_access_t *access,
    uf_phys_addr_t rom_base
)
{
    if (service == NULL || !uf_flash_access_is_valid(access)) {
        return UF_FALSE;
    }

    memset(service, 0, sizeof(*service));
    service->access = *access;
    service->rom_base = rom_base;
    uf_flash_service_clear_selection(service);
    return UF_TRUE;
}

uf_bool_t uf_flash_service_set_algorithms(
    uf_flash_service_t *service,
    const uf_flash_algorithm_registry_t *registry
)
{
    if (
        service == NULL
        || !uf_flash_algorithm_registry_is_valid(registry)
    ) {
        return UF_FALSE;
    }
    service->algorithms = registry;
    return UF_TRUE;
}

uf_bool_t uf_flash_service_select_chip(
    uf_flash_service_t *service,
    uint8_t manufacturer_id,
    uint8_t device_id
)
{
    const uf_flash_manufacturer_t *manufacturer;
    const uf_flash_chip_t *chip;

    if (service == NULL) {
        return UF_FALSE;
    }

    uf_flash_service_clear_selection(service);
    service->error = UF_FLASH_ERROR_UNKNOWN_CHIP;

    manufacturer = uf_rom_find_manufacturer(manufacturer_id);
    chip = uf_rom_find_chip(manufacturer, device_id);
    if (chip == NULL) {
        return UF_FALSE;
    }

    service->manufacturer = manufacturer;
    service->chip = chip;
    service->manufacturer_id = manufacturer_id;
    service->device_id = device_id;
    service->error = UF_FLASH_ERROR_NONE;
    return UF_TRUE;
}

uf_bool_t uf_flash_service_range_is_valid(
    const uf_flash_service_t *service,
    uf_rom_offset_t address,
    uf_rom_size_t size_bytes
)
{
    if (service == NULL) {
        return UF_FALSE;
    }
    if (address > UINT32_MAX - size_bytes) {
        return UF_FALSE;
    }
    if (service->chip == NULL) {
        return UF_TRUE;
    }
    if (address > service->chip->capacity_bytes) {
        return UF_FALSE;
    }
    return size_bytes <= service->chip->capacity_bytes - address
        ? UF_TRUE
        : UF_FALSE;
}

uf_bool_t uf_flash_service_read_byte(
    uf_flash_service_t *service,
    uf_rom_offset_t address,
    uint8_t *value
)
{
    if (
        service == NULL
        || value == NULL
        || service->access.read_byte == NULL
        || !uf_flash_service_range_is_valid(service, address, 1)
    ) {
        return UF_FALSE;
    }
    return service->access.read_byte(service->access.context, address, value);
}

uf_bool_t uf_flash_service_write_byte(
    uf_flash_service_t *service,
    uf_rom_offset_t address,
    uint8_t value
)
{
    if (
        service == NULL
        || service->access.write_byte == NULL
        || !uf_flash_service_range_is_valid(service, address, 1)
    ) {
        return UF_FALSE;
    }
    return service->access.write_byte(service->access.context, address, value);
}

uf_bool_t uf_flash_service_read_block(
    uf_flash_service_t *service,
    uf_rom_offset_t flash_address,
    void *destination,
    uf_rom_size_t size_bytes
)
{
    if (
        service == NULL
        || (destination == NULL && size_bytes != 0)
        || service->access.read_block == NULL
        || !uf_flash_service_range_is_valid(
            service,
            flash_address,
            size_bytes
        )
    ) {
        return UF_FALSE;
    }
    return service->access.read_block(
        service->access.context,
        flash_address,
        destination,
        size_bytes
    );
}

uf_bool_t uf_flash_service_write_block(
    uf_flash_service_t *service,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes
)
{
    if (
        service == NULL
        || (source == NULL && size_bytes != 0)
        || service->access.write_block == NULL
        || !uf_flash_service_range_is_valid(
            service,
            flash_address,
            size_bytes
        )
    ) {
        return UF_FALSE;
    }
    return service->access.write_block(
        service->access.context,
        source,
        flash_address,
        size_bytes
    );
}

uf_bool_t uf_flash_service_compare_block(
    uf_flash_service_t *service,
    const void *source,
    uf_rom_offset_t flash_address,
    uf_rom_size_t size_bytes,
    uf_bool_t *equal
)
{
    if (
        service == NULL
        || (source == NULL && size_bytes != 0)
        || equal == NULL
        || service->access.compare_block == NULL
        || !uf_flash_service_range_is_valid(
            service,
            flash_address,
            size_bytes
        )
    ) {
        return UF_FALSE;
    }
    return service->access.compare_block(
        service->access.context,
        source,
        flash_address,
        size_bytes,
        equal
    );
}

uf_bool_t uf_flash_service_command(
    uf_flash_service_t *service,
    uint8_t command
)
{
    if (service == NULL || !uf_flash_access_is_valid(&service->access)) {
        return UF_FALSE;
    }
    if (
        !uf_flash_service_write_byte(
            service,
            (uf_rom_offset_t)UF_FLASH_COMMAND_ADDRESS_1,
            (uint8_t)UF_FLASH_COMMAND_UNLOCK_1
        )
    ) {
        return UF_FALSE;
    }
    if (
        !uf_flash_service_write_byte(
            service,
            (uf_rom_offset_t)UF_FLASH_COMMAND_ADDRESS_2,
            (uint8_t)UF_FLASH_COMMAND_UNLOCK_2
        )
    ) {
        return UF_FALSE;
    }
    return uf_flash_service_write_byte(
        service,
        (uf_rom_offset_t)UF_FLASH_COMMAND_ADDRESS_1,
        command
    );
}

uf_bool_t uf_flash_id_has_odd_parity(uint8_t manufacturer_id)
{
    uint8_t parity = 0;

    while (manufacturer_id != 0) {
        parity ^= (uint8_t)(manufacturer_id & UINT8_C(1));
        manufacturer_id >>= 1;
    }
    return parity != 0 ? UF_TRUE : UF_FALSE;
}

static uf_bool_t send_id_command(
    uf_flash_service_t *service,
    uf_flash_id_method_t method
)
{
    if (method == UF_FLASH_ID_METHOD_LEGACY) {
        if (
            !uf_flash_service_command(service, UINT8_C(0x80))
            || !uf_flash_service_command(service, UINT8_C(0x60))
        ) {
            return UF_FALSE;
        }
    } else if (method == UF_FLASH_ID_METHOD_STANDARD) {
        if (!uf_flash_service_command(service, UINT8_C(0x90))) {
            return UF_FALSE;
        }
    } else {
        return UF_FALSE;
    }
    return service->access.delay_us(
        service->access.context,
        UINT32_C(50)
    );
}

static uf_bool_t reset_after_id(
    uf_flash_service_t *service,
    uint8_t manufacturer_id
)
{
    uint8_t reset_command = manufacturer_id == UINT8_C(0x89)
        ? UINT8_C(0xFF)
        : UINT8_C(0xF0);

    if (!uf_flash_service_write_byte(service, 0, reset_command)) {
        return UF_FALSE;
    }
    return service->access.delay_us(
        service->access.context,
        UINT32_C(1000)
    );
}

uf_bool_t uf_flash_service_probe_id(
    uf_flash_service_t *service,
    uf_flash_id_method_t method,
    uf_flash_id_result_t *result
)
{
    uint8_t extension;

    if (
        service == NULL
        || result == NULL
        || service->access.delay_us == NULL
        || (
            method != UF_FLASH_ID_METHOD_LEGACY
            && method != UF_FLASH_ID_METHOD_STANDARD
        )
    ) {
        return UF_FALSE;
    }

    memset(result, 0, sizeof(*result));
    uf_flash_service_clear_selection(service);
    service->error = UF_FLASH_ERROR_NONE;

    if (
        !uf_flash_service_read_byte(
            service,
            0,
            &result->initial_manufacturer_id
        )
        || !uf_flash_service_read_byte(
            service,
            1,
            &result->initial_device_id
        )
        || !send_id_command(service, method)
        || !uf_flash_service_read_byte(
            service,
            0,
            &result->manufacturer_id
        )
    ) {
        return UF_FALSE;
    }

    if (result->manufacturer_id == UINT8_C(0x7F)) {
        if (!uf_flash_service_read_byte(service, 0x100, &extension)) {
            return UF_FALSE;
        }
        result->manufacturer_id = extension;
        if (result->manufacturer_id == UINT8_C(0x7F)) {
            if (!uf_flash_service_read_byte(service, 3, &extension)) {
                return UF_FALSE;
            }
            if (extension == UINT8_C(0x1F)) {
                result->manufacturer_id = UINT8_C(0x7F);
            }
        }
    }

    if (result->manufacturer_id == UINT8_C(0xC2)) {
        if (
            !reset_after_id(service, result->manufacturer_id)
            || !send_id_command(service, method)
        ) {
            return UF_FALSE;
        }
    }

    if (!uf_flash_service_read_byte(service, 1, &result->device_id)) {
        return UF_FALSE;
    }
    if (result->device_id == UINT8_C(0x7F)) {
        if (!uf_flash_service_read_byte(service, 0x101, &extension)) {
            return UF_FALSE;
        }
        result->device_id = extension;
    }
    if (!reset_after_id(service, result->manufacturer_id)) {
        return UF_FALSE;
    }

    result->valid = (
        (
            result->manufacturer_id != result->initial_manufacturer_id
            || result->device_id != result->initial_device_id
        )
        && uf_flash_id_has_odd_parity(result->manufacturer_id)
    ) ? UF_TRUE : UF_FALSE;
    return UF_TRUE;
}

uf_bool_t uf_flash_service_accept_id(
    uf_flash_service_t *service,
    const uf_flash_id_result_t *result
)
{
    if (service == NULL || result == NULL || result->valid != UF_TRUE) {
        if (service != NULL) {
            uf_flash_service_clear_selection(service);
            service->error = UF_FLASH_ERROR_UNKNOWN_CHIP;
        }
        return UF_FALSE;
    }

    if (
        !uf_flash_service_select_chip(
            service,
            result->manufacturer_id,
            result->device_id
        )
    ) {
        return UF_FALSE;
    }

    service->rom_base =
        UINT32_C(0) - (uf_phys_addr_t)service->chip->capacity_bytes;
    return UF_TRUE;
}

uf_bool_t uf_flash_service_detect_current_window(
    uf_flash_service_t *service
)
{
    uf_flash_id_result_t result;

    if (service == NULL) {
        return UF_FALSE;
    }

    if (
        !uf_flash_service_probe_id(
            service,
            UF_FLASH_ID_METHOD_LEGACY,
            &result
        )
    ) {
        return UF_FALSE;
    }
    if (uf_flash_service_accept_id(service, &result)) {
        return UF_TRUE;
    }

    if (
        !uf_flash_service_probe_id(
            service,
            UF_FLASH_ID_METHOD_STANDARD,
            &result
        )
    ) {
        return UF_FALSE;
    }
    return uf_flash_service_accept_id(service, &result);
}

static uf_bool_t select_rom_window(
    uf_flash_service_t *service,
    uf_phys_addr_t rom_base
)
{
    service->rom_base = rom_base;
    return service->access.select_window(
        service->access.context,
        rom_base
    );
}

uf_bool_t uf_flash_service_detect(uf_flash_service_t *service)
{
    uf_flash_id_result_t result;
    uf_phys_addr_t fixed_rom_base;
    uf_flash_id_method_t method;
    uint8_t minimum_exponent;
    uint8_t maximum_exponent;
    uint8_t exponent;

    if (service == NULL || service->access.select_window == NULL) {
        return UF_FALSE;
    }

    fixed_rom_base = service->rom_base;
    if (fixed_rom_base == 0) {
        minimum_exponent = 15;
        maximum_exponent = 20;
    } else {
        minimum_exponent = 0;
        maximum_exponent = 0;
    }

    for (method = UF_FLASH_ID_METHOD_LEGACY;
         method <= UF_FLASH_ID_METHOD_STANDARD;
         ++method) {
        for (exponent = minimum_exponent;
             exponent <= maximum_exponent;
             ++exponent) {
            uf_phys_addr_t candidate_base = fixed_rom_base;

            if (exponent != 0) {
                candidate_base =
                    UINT32_C(0) - (UINT32_C(1) << exponent);
            }
            if (
                !select_rom_window(service, candidate_base)
                || !uf_flash_service_probe_id(service, method, &result)
            ) {
                return UF_FALSE;
            }
            if (uf_flash_service_accept_id(service, &result)) {
                if (
                    !service->access.select_window(
                        service->access.context,
                        service->rom_base
                    )
                ) {
                    uf_flash_service_clear_selection(service);
                    return UF_FALSE;
                }
                return UF_TRUE;
            }
        }
    }
    return UF_FALSE;
}

uf_bool_t uf_flash_service_program(
    uf_flash_service_t *service,
    uf_rom_offset_t position,
    uf_phys_addr_t source_address
)
{
    uf_flash_program_fn program;

    if (
        service == NULL
        || service->chip == NULL
        || service->algorithms == NULL
        || !uf_flash_service_range_is_valid(
            service,
            position,
            (uf_rom_size_t)service->chip->page_size_bytes
        )
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }

    program = service->algorithms->program[
        service->chip->program_algorithm
    ];
    if (program == NULL) {
        service->error = UF_FLASH_ERROR_PROGRAM;
        return UF_FALSE;
    }

    service->error = UF_FLASH_ERROR_NONE;
    if (!program(service, position, source_address)) {
        if (service->error == UF_FLASH_ERROR_NONE) {
            service->error = UF_FLASH_ERROR_PROGRAM;
        }
        return UF_FALSE;
    }
    return UF_TRUE;
}

uf_bool_t uf_flash_service_erase(
    uf_flash_service_t *service,
    uf_rom_offset_t sector_address
)
{
    uf_flash_erase_fn erase;

    if (
        service == NULL
        || service->chip == NULL
        || service->algorithms == NULL
        || service->chip->erase_algorithm == UF_FLASH_ERASE_NONE
        || !uf_flash_service_range_is_valid(service, sector_address, 1)
    ) {
        if (service != NULL) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }

    erase = service->algorithms->erase[service->chip->erase_algorithm];
    if (erase == NULL) {
        service->error = UF_FLASH_ERROR_ERASE;
        return UF_FALSE;
    }

    service->error = UF_FLASH_ERROR_NONE;
    if (!erase(service, sector_address)) {
        if (service->error == UF_FLASH_ERROR_NONE) {
            service->error = UF_FLASH_ERROR_ERASE;
        }
        return UF_FALSE;
    }
    return UF_TRUE;
}
