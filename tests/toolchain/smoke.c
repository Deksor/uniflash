#include <stdint.h>
#include <stdio.h>

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

typedef uint32_t uf_phys_addr_t;

int main(void)
{
    const uf_phys_addr_t top_of_first_megabyte = UINT32_C(0x100000);

    printf(
        "UniFlash C toolchain: DOS/16, 386, huge model; address=%lu\r\n",
        (unsigned long)top_of_first_megabyte
    );
    return 0;
}
