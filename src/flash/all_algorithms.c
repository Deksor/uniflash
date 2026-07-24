#include "uniflash/all_algorithms.h"

bool uf_flash_register_all_algorithms(uf_flash_algorithm_registry_t *registry) {
    return uf_flash_register_generic_algorithms(registry) && uf_flash_register_intel_algorithms(registry) &&
           uf_flash_register_sharp_algorithms(registry) && uf_flash_register_pmc_algorithms(registry) &&
           uf_flash_register_winbond_algorithms(registry) && uf_flash_register_macronix_algorithms(registry) &&
           uf_flash_register_atmel_algorithms(registry) && uf_flash_register_sst_algorithms(registry) &&
           uf_flash_register_st_algorithms(registry);
}
