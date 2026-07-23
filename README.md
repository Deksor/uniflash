# UniFlash 2.00

UniFlash is a DOS utility for identifying, reading, and programming flash
ROMs on PC motherboards and expansion cards. Version 2.00 is an ongoing C
port of the original Pascal program, built for 16-bit DOS with Open Watcom 2.

The C port currently provides hardware detection, flash identification,
ROM and boot-block backups, file comparison, CMOS backup, CT-Flasher access,
and supported PCI expansion-ROM access. Destructive programming features are
deliberately unavailable from the GUI and command line until their complete
workflow has been ported and validated on physical hardware.

> **Warning**
>
> UniFlash performs direct chipset, PCI, I/O-port, and physical-memory
> access. Use it only on supported DOS hardware and keep an independent
> recovery method available. Even read-only identification may send command
> sequences to a flash device.

## Historical releases

The last build published by Ondrej Zary, UniFlash 1.40, is available from
the [1.40 GitHub release](https://github.com/Deksor/uniflash/releases/tag/1.40).

The original Turbo Pascal sources, their later Free Pascal build environment,
and the historical documentation are preserved in
[`legacy/pascal/`](legacy/pascal/README.md).

## Requirements

- Docker with support for `linux/amd64` containers
- GNU Make
- A C99 host compiler for the host-side tests
- `zip` and `sha256sum` for release packaging

The container pins an Open Watcom 2 snapshot and verifies its checksum. The
DOS build uses 386 instructions, the huge memory model, a 16 KiB stack, and
the Open Watcom DOS runtime.

## Build and test

```sh
make test
make toolchain-smoke
make build
```

The DOS executable is written to:

```text
build/msdos-c/UNIFLASH.EXE
```

Run the complete release validation and create a ZIP archive with:

```sh
make release
```

The release archive and SHA-256 checksum are written under `dist/`.

## DOS usage

Running `UNIFLASH` opens the 80×25 text-mode GUI. ROM-base detection is
automatic unless `-BASE` is supplied.

Common non-destructive commands:

```text
UNIFLASH
UNIFLASH -BASE FFFE0000
UNIFLASH -INFO
UNIFLASH -DUMP BACKUP.BIN
UNIFLASH -SAVE BACKUP.BIN -QUIT
UNIFLASH -COMPARE BACKUP.BIN
UNIFLASH -BOOTBLOCK BOOT.BIN
UNIFLASH -CMOSS CMOS.BIN
UNIFLASH -CHIPLIST
UNIFLASH /0
UNIFLASH /1 -MONO
UNIFLASH -INFO -FORCE xxxx
UNIFLASH -INFO -CTFLASH [hex-port]
UNIFLASH -DUMP CARD.BIN -PCIROM [bus device function]
```

With no PCI bus/device/function triple, `-PCIROM` displays an interactive
list of cards with expansion ROMs.

The CMOS backup retains the original file format: CMOS indexes `0Eh` through
the detected end of CMOS are saved. CMOS-size probing restores the values it
temporarily changes.

## Project layout

```text
data/languages/   Compiled language definitions
data/roms/        Declarative flash-ROM database
include/uniflash/ Public C interfaces
src/app/          CLI, GUI, language, and file workflows
src/flash/        Flash detection and algorithms
src/hardware/     DOS, chipset, CMOS, PCI, and XMS access
tests/host/       Hardware-independent regression tests
tests/toolchain/  Open Watcom DOS/16 model checks
legacy/pascal/    Preserved original implementation
```

## Status

Version 2.00 should be treated as a hardware-tested preview. The GUI and
non-destructive functions have been exercised on real DOS hardware, but the
full chipset/card matrix has not been tested. See [TODO.md](TODO.md) for the
remaining port and release work.

UniFlash is distributed under the terms in [LICENSE.TXT](LICENSE.TXT).
