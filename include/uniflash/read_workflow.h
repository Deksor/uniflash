#ifndef UNIFLASH_READ_WORKFLOW_H
#define UNIFLASH_READ_WORKFLOW_H

#include <stdio.h>

#include "uniflash/flash_service.h"
#include "uniflash/image_store.h"

#define UF_READ_WORKFLOW_BUFFER_SIZE UINT16_C(32768)

typedef enum uf_read_result {
    UF_READ_RESULT_OK = 0,
    UF_READ_RESULT_INVALID_ARGUMENT,
    UF_READ_RESULT_FLASH_IO,
    UF_READ_RESULT_FILE_OPEN,
    UF_READ_RESULT_FILE_IO,
    UF_READ_RESULT_FILE_SIZE,
    UF_READ_RESULT_DIFFERENT
} uf_read_result_t;

uf_read_result_t uf_read_workflow_dump(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_size_t image_size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
);
uf_read_result_t uf_read_workflow_dump_range(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_offset_t image_offset,
    uf_rom_size_t size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
);
uf_read_result_t uf_read_workflow_compare(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_size_t image_size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
);
const char *uf_read_result_message(uf_read_result_t result);

#endif
