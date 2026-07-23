#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "uniflash/image_store.h"
#include "uniflash/read_workflow.h"

#define TEST_IMAGE_SIZE 70000U
#define TEST_PHYS_SIZE 140000U

typedef struct test_context {
    uint8_t physical[TEST_PHYS_SIZE];
} test_context_t;

static uf_bool_t unused_in8(void *context, uf_io_port_t port, uint8_t *value)
{
    (void)context;
    (void)port;
    *value = 0;
    return UF_TRUE;
}

static uf_bool_t unused_in16(
    void *context, uf_io_port_t port, uint16_t *value
)
{
    (void)context;
    (void)port;
    *value = 0;
    return UF_TRUE;
}

static uf_bool_t unused_in32(
    void *context, uf_io_port_t port, uint32_t *value
)
{
    (void)context;
    (void)port;
    *value = 0;
    return UF_TRUE;
}

static uf_bool_t unused_out8(
    void *context, uf_io_port_t port, uint8_t value
)
{
    (void)context;
    (void)port;
    (void)value;
    return UF_TRUE;
}

static uf_bool_t unused_out16(
    void *context, uf_io_port_t port, uint16_t value
)
{
    (void)context;
    (void)port;
    (void)value;
    return UF_TRUE;
}

static uf_bool_t unused_out32(
    void *context, uf_io_port_t port, uint32_t value
)
{
    (void)context;
    (void)port;
    (void)value;
    return UF_TRUE;
}

static uf_bool_t phys_read(
    void *context, uf_phys_addr_t address, uint8_t *value
)
{
    test_context_t *test = context;
    if (address >= TEST_PHYS_SIZE) {
        return UF_FALSE;
    }
    *value = test->physical[address];
    return UF_TRUE;
}

static uf_bool_t phys_write(
    void *context, uf_phys_addr_t address, uint8_t value
)
{
    test_context_t *test = context;
    if (address >= TEST_PHYS_SIZE) {
        return UF_FALSE;
    }
    test->physical[address] = value;
    return UF_TRUE;
}

static uf_bool_t delay_us(void *context, uint32_t microseconds)
{
    (void)context;
    (void)microseconds;
    return UF_TRUE;
}

static uf_bool_t flash_read(
    void *context, uf_rom_offset_t address, uint8_t *value
)
{
    return phys_read(context, address, value);
}

static uf_bool_t flash_write(
    void *context, uf_rom_offset_t address, uint8_t value
)
{
    return phys_write(context, address, value);
}

int main(void)
{
    static test_context_t test;
    uf_hardware_t hardware;
    uf_flash_access_t access;
    uf_flash_service_t flash;
    uf_image_store_t store;
    uint8_t buffer[4096];
    uint32_t index;
    FILE *file;

    memset(&hardware, 0, sizeof(hardware));
    hardware.context = &test;
    hardware.in8 = unused_in8;
    hardware.in16 = unused_in16;
    hardware.in32 = unused_in32;
    hardware.out8 = unused_out8;
    hardware.out16 = unused_out16;
    hardware.out32 = unused_out32;
    hardware.phys_read8 = phys_read;
    hardware.phys_write8 = phys_write;
    hardware.delay_us = delay_us;

    memset(&access, 0, sizeof(access));
    access.context = &test;
    access.read_byte = flash_read;
    access.write_byte = flash_write;
    for (index = 0; index < TEST_IMAGE_SIZE; ++index) {
        test.physical[index] = (uint8_t)(index * 37U);
    }
    assert(uf_flash_service_init(&flash, &access, 0));
    assert(uf_image_store_init(
        &store, &hardware, TEST_IMAGE_SIZE, TEST_IMAGE_SIZE
    ));
    assert(uf_image_store_capture(&store, &flash, TEST_IMAGE_SIZE));
    assert(uf_read_workflow_dump(
        &flash,
        &store,
        TEST_IMAGE_SIZE,
        "build/host/read-workflow.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_OK);
    assert(uf_read_workflow_compare(
        &flash,
        &store,
        TEST_IMAGE_SIZE,
        "build/host/read-workflow.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_OK);
    assert(uf_read_workflow_dump_range(
        &flash,
        &store,
        TEST_IMAGE_SIZE - 8192,
        8192,
        "build/host/read-workflow-range.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_OK);
    file = fopen("build/host/read-workflow-range.bin", "rb");
    assert(file != NULL);
    assert(fseek(file, 0, SEEK_END) == 0);
    assert(ftell(file) == 8192L);
    assert(fclose(file) == 0);
    assert(remove("build/host/read-workflow-range.bin") == 0);

    file = fopen("build/host/read-workflow.bin", "r+b");
    assert(file != NULL);
    assert(fseek(file, 35000L, SEEK_SET) == 0);
    assert(fputc(0xA5, file) != EOF);
    assert(fclose(file) == 0);
    assert(uf_read_workflow_compare(
        &flash,
        &store,
        TEST_IMAGE_SIZE,
        "build/host/read-workflow.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_DIFFERENT);
    assert(remove("build/host/read-workflow.bin") == 0);

    assert(uf_read_workflow_dump(
        &flash,
        NULL,
        TEST_IMAGE_SIZE,
        "build/host/read-workflow-stream.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_OK);
    assert(uf_read_workflow_compare(
        &flash,
        NULL,
        TEST_IMAGE_SIZE,
        "build/host/read-workflow-stream.bin",
        buffer,
        sizeof(buffer)
    ) == UF_READ_RESULT_OK);
    assert(remove("build/host/read-workflow-stream.bin") == 0);
    puts("read workflow tests passed");
    return 0;
}
