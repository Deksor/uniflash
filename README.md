Released in 1998 and updated until 2005, this is the original source code to the Uniflash project, by Pascal Van Leeuwen, Galkowski Adam and Ondrej Zary (aka Rainbow Software) now released on github.

You can find their respective websites on archive.org here

- http://ourworld.compuserve.com/homepages/pvanleeuwen/techforum.htm
- https://web.archive.org/web/20070820105814/http://www.uniflash.org/

## Modern DOS cross-build environment

This tree targets real DOS on 386-class hardware, not a modern host runtime. `UNIFLASH.PAS` uses Borland-style directives such as `{$M ...}` and `{$G+}`, the `Dos` and `Crt` units, and low-level flat-real-mode code. A plain Debian `fpc` install is not enough because it only ships the native Linux compiler.

The workspace now includes a reproducible container workflow that builds and installs the Free Pascal real-mode DOS cross compiler from the packaged FPC sources, configured for 386 code generation.

### What is in the repo now

- `Dockerfile` installs a modern Debian-based toolchain and bootstraps `ppcross8086`.
- `scripts/bootstrap-fpc-cross.sh` builds the real-mode DOS cross compiler and installs its RTL/packages under `/opt/fpc-cross`.
- `Makefile` provides a single command for compiling `UNIFLASH.PAS` to DOS.

### Build inside the container

Build the image:

```sh
docker build -t uniflash-dev .
```

Run a shell in the project:

```sh
docker run --rm -it -v "$PWD":/workspaces/uniflash -w /workspaces/uniflash uniflash-dev
```

Compile UniFlash for DOS:

```sh
make
```

The expected output path is `build/msdos/UNIFLASH.EXE`.

### Notes

- The compiler mode is set to Turbo Pascal compatibility with `-Mtp`.
- FPC names the real-mode DOS backend `i8086-msdos`, but the build is pinned to a 386-class CPU with `-Cp386 -Op386`.
- That keeps the executable in the DOS real-mode model that UniFlash expects, instead of moving it to a 32-bit extender target such as `go32v2`.
- `dosbox` is installed in the container so you can do basic smoke testing of the produced DOS executable.