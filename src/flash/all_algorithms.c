#include "uniflash/all_algorithms.h"

bool uf_flash_register_all_algorithms(uf_flash_algorithm_registry_t *registry) {
    static bool (*const register_functions[])(uf_flash_algorithm_registry_t *registry) = {
        uf_flash_register_generic_algorithms,
        uf_flash_register_intel_algorithms,
        uf_flash_register_sharp_algorithms,
        uf_flash_register_pmc_algorithms,
        uf_flash_register_winbond_algorithms,
        uf_flash_register_macronix_algorithms,
        uf_flash_register_atmel_algorithms,
        uf_flash_register_sst_algorithms,
        uf_flash_register_st_algorithms,
    };

    for (size_t i = 0; i < sizeof(register_functions) / sizeof(register_functions[0]); ++i) {
        if (!register_functions[i](registry)) {
            return false;
        }
    }
    return true;
}
