#ifndef UNIFLASH_ALL_ALGORITHMS_H
#define UNIFLASH_ALL_ALGORITHMS_H

#include "uniflash/atmel_algorithms.h"
#include "uniflash/intel_algorithms.h"
#include "uniflash/macronix_algorithms.h"
#include "uniflash/pmc_algorithms.h"
#include "uniflash/sharp_algorithms.h"
#include "uniflash/sst_algorithms.h"
#include "uniflash/st_algorithms.h"
#include "uniflash/winbond_algorithms.h"

bool uf_flash_register_all_algorithms(
    uf_flash_algorithm_registry_t *registry);

#endif
