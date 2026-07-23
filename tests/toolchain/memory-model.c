#include <stddef.h>
#include <stdint.h>

#if !defined(__WATCOMC__)
#error This test must be compiled by Open Watcom
#endif

#if !defined(_DOS)
#error The Open Watcom target is not DOS
#endif

#if !defined(__I86__) && !defined(_M_I86)
#error The Open Watcom target is not 16-bit x86
#endif

#if !defined(__HUGE__) && !defined(__SW_MH)
#error The Open Watcom huge memory model is not enabled
#endif

#define STATIC_SIZE_ASSERT(name, expression) \
    typedef char static_size_assert_##name[(expression) ? 1 : -1]

STATIC_SIZE_ASSERT(uint8_is_1, sizeof(uint8_t) == 1);
STATIC_SIZE_ASSERT(uint16_is_2, sizeof(uint16_t) == 2);
STATIC_SIZE_ASSERT(uint32_is_4, sizeof(uint32_t) == 4);
STATIC_SIZE_ASSERT(int_is_2, sizeof(int) == 2);
STATIC_SIZE_ASSERT(long_is_4, sizeof(long) == 4);
STATIC_SIZE_ASSERT(data_pointer_is_4, sizeof(void *) == 4);
STATIC_SIZE_ASSERT(function_pointer_is_4, sizeof(void (*)(void)) == 4);
STATIC_SIZE_ASSERT(size_t_is_2, sizeof(size_t) == 2);

int main(void)
{
    return 0;
}
