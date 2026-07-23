#include "uniflash/read_workflow.h"

static uf_bool_t read_chunk(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_offset_t offset,
    uint8_t *buffer,
    uint16_t size
)
{
    uint16_t index;

    if (store != NULL && store->image_size_bytes != 0) {
        return uf_image_store_read(store, offset, buffer, size);
    }
    if (flash->access.read_block != NULL) {
        return uf_flash_service_read_block(flash, offset, buffer, size);
    }
    for (index = 0; index < size; ++index) {
        if (!uf_flash_service_read_byte(
            flash, offset + index, &buffer[index]
        )) {
            return UF_FALSE;
        }
    }
    return UF_TRUE;
}

static uf_read_result_t validate_arguments(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_size_t image_size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
)
{
    if (
        flash == NULL
        || image_size_bytes == 0
        || path == NULL
        || path[0] == '\0'
        || buffer == NULL
        || buffer_size == 0
        || (
            store != NULL
            && store->image_size_bytes != image_size_bytes
        )
    ) {
        return UF_READ_RESULT_INVALID_ARGUMENT;
    }
    return UF_READ_RESULT_OK;
}

uf_read_result_t uf_read_workflow_dump(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_size_t image_size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
)
{
    return uf_read_workflow_dump_range(
        flash,
        store,
        0,
        image_size_bytes,
        path,
        buffer,
        buffer_size
    );
}

uf_read_result_t uf_read_workflow_dump_range(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_offset_t image_offset,
    uf_rom_size_t size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
)
{
    FILE *file;
    uf_rom_offset_t offset = 0;
    if (
        flash == NULL
        || size_bytes == 0
        || path == NULL
        || path[0] == '\0'
        || buffer == NULL
        || buffer_size == 0
        || image_offset > UINT32_MAX - size_bytes
        || (
            store != NULL
            && (
                image_offset > store->image_size_bytes
                || size_bytes > store->image_size_bytes - image_offset
            )
        )
    ) {
        return UF_READ_RESULT_INVALID_ARGUMENT;
    }
    file = fopen(path, "wb");
    if (file == NULL) {
        return UF_READ_RESULT_FILE_OPEN;
    }
    while (offset < size_bytes) {
        uf_rom_size_t remaining = size_bytes - offset;
        uint16_t chunk = remaining < buffer_size
            ? (uint16_t)remaining
            : buffer_size;

        if (!read_chunk(
            flash, store, image_offset + offset, buffer, chunk
        )) {
            fclose(file);
            return UF_READ_RESULT_FLASH_IO;
        }
        if (fwrite(buffer, 1, chunk, file) != chunk) {
            fclose(file);
            return UF_READ_RESULT_FILE_IO;
        }
        offset += chunk;
    }
    if (fclose(file) != 0) {
        return UF_READ_RESULT_FILE_IO;
    }
    return UF_READ_RESULT_OK;
}

uf_read_result_t uf_read_workflow_compare(
    uf_flash_service_t *flash,
    const uf_image_store_t *store,
    uf_rom_size_t image_size_bytes,
    const char *path,
    uint8_t *buffer,
    uint16_t buffer_size
)
{
    FILE *file;
    long file_size;
    uf_rom_offset_t offset = 0;
    uf_read_result_t validation = validate_arguments(
        flash, store, image_size_bytes, path, buffer, buffer_size
    );

    if (validation != UF_READ_RESULT_OK) {
        return validation;
    }
    file = fopen(path, "rb");
    if (file == NULL) {
        return UF_READ_RESULT_FILE_OPEN;
    }
    if (
        fseek(file, 0, SEEK_END) != 0
        || (file_size = ftell(file)) < 0
        || fseek(file, 0, SEEK_SET) != 0
    ) {
        fclose(file);
        return UF_READ_RESULT_FILE_IO;
    }
    if ((uint32_t)file_size != image_size_bytes) {
        fclose(file);
        return UF_READ_RESULT_FILE_SIZE;
    }
    while (offset < image_size_bytes) {
        uf_rom_size_t remaining = image_size_bytes - offset;
        uint16_t chunk = remaining < buffer_size
            ? (uint16_t)remaining
            : buffer_size;
        uint16_t index;

        if (fread(buffer, 1, chunk, file) != chunk) {
            fclose(file);
            return UF_READ_RESULT_FILE_IO;
        }
        for (index = 0; index < chunk; ++index) {
            uint8_t value;
            if (
                store != NULL
                && store->image_size_bytes != 0
            ) {
                if (!uf_image_store_read(
                    store, offset + index, &value, 1
                )) {
                    fclose(file);
                    return UF_READ_RESULT_FLASH_IO;
                }
            } else if (!uf_flash_service_read_byte(
                flash, offset + index, &value
            )) {
                fclose(file);
                return UF_READ_RESULT_FLASH_IO;
            }
            if (buffer[index] != value) {
                fclose(file);
                return UF_READ_RESULT_DIFFERENT;
            }
        }
        offset += chunk;
    }
    if (fclose(file) != 0) {
        return UF_READ_RESULT_FILE_IO;
    }
    return UF_READ_RESULT_OK;
}

const char *uf_read_result_message(uf_read_result_t result)
{
    switch (result) {
    case UF_READ_RESULT_OK:
        return "operation completed";
    case UF_READ_RESULT_INVALID_ARGUMENT:
        return "invalid argument";
    case UF_READ_RESULT_FLASH_IO:
        return "ROM read failed";
    case UF_READ_RESULT_FILE_OPEN:
        return "cannot open file";
    case UF_READ_RESULT_FILE_IO:
        return "file I/O failed";
    case UF_READ_RESULT_FILE_SIZE:
        return "file size does not match ROM size";
    case UF_READ_RESULT_DIFFERENT:
        return "file differs from ROM";
    default:
        return "unknown error";
    }
}
