UniFlash is a DOS utility for identifying, dumping, and programming flash
ROMs. Development began around 1997. The last release from Ondrej Zary was
1.40 in 2005.

The primary implementation is now the UniFlash 2.00 C port. It targets
16-bit DOS on 386-class and newer x86 systems and is built with Open Watcom
2 in the huge memory model. C sources live in `src/`, public interfaces in
`include/uniflash/`, ROM definitions in `data/roms/`, and language
definitions in `data/languages/`.

The original Turbo Pascal/Free Pascal implementation is preserved under
`legacy/pascal/` as the behavioral reference. Do not remove or rewrite its
assembly when porting behavior. Preserve its comments and instruction
structure where equivalent inline assembly is required.

Use fixed-width integer types from `<stdint.h>` for hardware-facing values.
Remember that `size_t` is 16 bits in the DOS/16 target. Keep hardware access
behind the existing interfaces so host tests never perform real port or
physical-memory operations.

The current C release exposes identification and non-destructive backup
features. Destructive GUI and CLI operations remain disabled until the
application-level programming workflow and physical-hardware validation are
complete. See `TODO.md`.

Run `make test` for host tests, `make toolchain-smoke` for the Open Watcom
memory-model check, and `make build` for the DOS executable.
