#include <string.h>

#include "uniflash/runtime.h"

static uf_bool_t finali_select_bank(void *context, uint8_t bank)
{
    uf_runtime_t *runtime = context;
    const uf_hardware_t *hardware = &runtime->hardware;
    uint8_t value;

    if (bank > 1) {
        return UF_FALSE;
    }
    return (
        hardware->out8(
            hardware->context,
            UINT16_C(0x22),
            UINT8_C(0x03)
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x23),
            UINT8_C(0xC5)
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x22),
            UINT8_C(0x2B)
        )
        && hardware->in8(
            hardware->context,
            UINT16_C(0x23),
            &value
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x22),
            UINT8_C(0x2B)
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x23),
            bank == 0
                ? value | UINT8_C(0x20)
                : value & UINT8_C(0xDF)
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x22),
            UINT8_C(0x03)
        )
        && hardware->out8(
            hardware->context,
            UINT16_C(0x23),
            UINT8_C(0)
        )
    ) ? UF_TRUE : UF_FALSE;
}

static uf_bool_t aladdin_shadow_control(
    void *context,
    uf_bool_t disable
)
{
    uf_runtime_t *runtime = context;

    return uf_pci_write32(
        &runtime->chipset.pci,
        runtime->chipset.north.address,
        UINT8_C(0x4C),
        runtime->chipset.north_saved[0]
            & (disable
                ? UINT32_C(0x00FF00FF)
                : UINT32_C(0x00FFFFFF))
    );
}

uf_bool_t uf_runtime_init(
    uf_runtime_t *runtime,
    uf_phys_addr_t initial_rom_base
)
{
    uf_phys_addr_t rom_base = initial_rom_base;

    if (runtime == NULL) {
        return UF_FALSE;
    }
    memset(runtime, 0, sizeof(*runtime));
    if (
        !uf_dos_hardware_init(&runtime->hardware)
        || !uf_chipset_detect(&runtime->chipset, &runtime->hardware)
    ) {
        memset(runtime, 0, sizeof(*runtime));
        return UF_FALSE;
    }
    if (runtime->chipset.north_method == UINT16_C(0x0300)) {
        rom_base = UINT32_C(0x000E0000);
    } else if (runtime->chipset.north_method == UINT16_C(0x0301)) {
        rom_base = UINT32_C(0xFFFF0000);
    }
    if (
        !uf_system_flash_backend_init(
            &runtime->flash_backend,
            &runtime->hardware,
            rom_base
        )
        || (
            runtime->chipset.north_method == UINT16_C(0x0300)
            && !uf_system_flash_backend_set_shadow_control(
                &runtime->flash_backend,
                aladdin_shadow_control,
                runtime
            )
        )
        || (
            runtime->chipset.north_method == UINT16_C(0x0301)
            && !uf_system_flash_backend_set_banking(
                &runtime->flash_backend,
                UINT32_C(0x10000),
                UINT32_C(0x000F0000),
                finali_select_bank,
                runtime
            )
        )
        || !uf_system_flash_backend_make_access(
            &runtime->flash_backend,
            &runtime->flash_access
        )
        || !uf_flash_service_init(
            &runtime->flash,
            &runtime->flash_access,
            rom_base
        )
        || !uf_flash_register_all_algorithms(&runtime->algorithms)
        || !uf_flash_service_set_algorithms(
            &runtime->flash,
            &runtime->algorithms
        )
    ) {
        memset(runtime, 0, sizeof(*runtime));
        return UF_FALSE;
    }
    runtime->initialized = UF_TRUE;
    runtime->flash_target = UF_RUNTIME_FLASH_SYSTEM;
    return UF_TRUE;
}

static uf_bool_t set_flash_access(
    uf_runtime_t *runtime,
    const uf_flash_access_t *access,
    uf_phys_addr_t rom_base
)
{
    runtime->flash_access = *access;
    return (
        uf_flash_service_init(
            &runtime->flash,
            &runtime->flash_access,
            rom_base
        )
        && uf_flash_service_set_algorithms(
            &runtime->flash,
            &runtime->algorithms
        )
    ) ? UF_TRUE : UF_FALSE;
}

uf_bool_t uf_runtime_set_rom_enabled(
    uf_runtime_t *runtime,
    uf_bool_t enabled
)
{
    if (
        runtime == NULL
        || !runtime->initialized
    ) {
        return UF_FALSE;
    }
    if (runtime->flash_target == UF_RUNTIME_FLASH_PCI) {
        if (!uf_pci_rom_backend_set_enabled(&runtime->pci_rom, enabled)) {
            return UF_FALSE;
        }
    } else if (
        runtime->flash_target == UF_RUNTIME_FLASH_SYSTEM
        && !uf_chipset_rom_set_enabled(&runtime->chipset, enabled)
    ) {
        return UF_FALSE;
    }
    runtime->rom_enabled = enabled;
    return UF_TRUE;
}

uf_bool_t uf_runtime_use_system_rom(uf_runtime_t *runtime)
{
    uf_flash_access_t access;

    if (
        runtime == NULL
        || !runtime->initialized
        || runtime->rom_enabled
        || !uf_system_flash_backend_make_access(
            &runtime->flash_backend,
            &access
        )
        || !set_flash_access(
            runtime,
            &access,
            runtime->flash_backend.rom_base
        )
    ) {
        return UF_FALSE;
    }
    runtime->flash_target = UF_RUNTIME_FLASH_SYSTEM;
    return UF_TRUE;
}

uf_bool_t uf_runtime_use_ct_flasher(
    uf_runtime_t *runtime,
    uf_io_port_t requested_port,
    uf_bool_t size_512k
)
{
    uf_flash_access_t access;

    if (
        runtime == NULL
        || !runtime->initialized
        || runtime->rom_enabled
        || !uf_ct_flasher_detect(
            &runtime->ct_flasher,
            &runtime->hardware,
            requested_port,
            size_512k
        )
        || !uf_ct_flasher_make_access(&runtime->ct_flasher, &access)
        || !set_flash_access(
            runtime,
            &access,
            runtime->ct_flasher.window_base
        )
    ) {
        return UF_FALSE;
    }
    runtime->flash_target = UF_RUNTIME_FLASH_CT;
    return UF_TRUE;
}

uf_bool_t uf_runtime_scan_pci_roms(
    uf_runtime_t *runtime,
    uf_pci_rom_list_t *list
)
{
    if (runtime == NULL || !runtime->initialized) {
        return UF_FALSE;
    }
    return uf_pci_rom_scan(list, &runtime->hardware);
}

uf_bool_t uf_runtime_use_pci_rom(
    uf_runtime_t *runtime,
    const uf_pci_rom_device_t *device
)
{
    uf_flash_access_t access;

    if (
        runtime == NULL
        || !runtime->initialized
        || runtime->rom_enabled
        || !uf_pci_rom_backend_init(
            &runtime->pci_rom,
            &runtime->hardware,
            device
        )
        || !uf_pci_rom_backend_make_access(&runtime->pci_rom, &access)
        || !set_flash_access(
            runtime,
            &access,
            runtime->pci_rom.memory_base
        )
    ) {
        return UF_FALSE;
    }
    runtime->flash_target = UF_RUNTIME_FLASH_PCI;
    return UF_TRUE;
}

uf_bool_t uf_runtime_shutdown(uf_runtime_t *runtime)
{
    uf_bool_t result = UF_TRUE;

    if (runtime == NULL || !runtime->initialized) {
        return UF_FALSE;
    }
    if (runtime->rom_enabled) {
        result = uf_runtime_set_rom_enabled(runtime, UF_FALSE);
    }
    runtime->initialized = UF_FALSE;
    return result;
}
