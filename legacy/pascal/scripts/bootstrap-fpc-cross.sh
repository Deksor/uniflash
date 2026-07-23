#!/usr/bin/env bash
set -euo pipefail

FPC_SRC="${FPC_SRC:-/opt/fpcbuild-3.2.2/fpcsrc}"
FPC_CROSS_PREFIX="${FPC_CROSS_PREFIX:-/opt/fpc-cross}"
FPC_VERSION="${FPC_VERSION:-3.2.2}"
NATIVE_FPC="${NATIVE_FPC:-fpc}"

compiler_dir="$FPC_SRC/compiler"
rtl_dir="$FPC_SRC/rtl"
packages_dir="$FPC_SRC/packages"
cross_bin="$FPC_CROSS_PREFIX/bin"
cross_lib="$FPC_CROSS_PREFIX/lib/fpc/$FPC_VERSION"
cross_pp="ppcross8086"

mkdir -p "$cross_bin" "$cross_lib"

if [ ! -f "$compiler_dir/Makefile.fpc" ] || [ ! -f "$rtl_dir/Makefile.fpc" ] || [ ! -f "$packages_dir/Makefile.fpc" ]; then
  echo "FPC source tree is incomplete at $FPC_SRC" >&2
  echo "Expected compiler/rtl/packages with Makefile.fpc files" >&2
  exit 1
fi

fpcmake -Tall -r -w "$compiler_dir/Makefile.fpc"
fpcmake -Tall -r -w "$rtl_dir/Makefile.fpc"
fpcmake -Tall -r -w "$packages_dir/Makefile.fpc"

if [ ! -x "$compiler_dir/ppc" ]; then
  if command -v ppcx64 >/dev/null 2>&1; then
    ln -sf "$(command -v ppcx64)" "$compiler_dir/ppc"
  elif command -v ppcx86_64 >/dev/null 2>&1; then
    ln -sf "$(command -v ppcx86_64)" "$compiler_dir/ppc"
  else
    ln -sf "$(command -v $NATIVE_FPC)" "$compiler_dir/ppc"
  fi
fi

if [ ! -e "$packages_dir/compiler" ]; then
  ln -s ../compiler "$packages_dir/compiler"
fi

cd "$FPC_SRC"
cd "$compiler_dir"
make cycle \
  FPC="$NATIVE_FPC" \
  OS_TARGET=msdos \
  CPU_TARGET=i8086 \
  OPT="-dFPC_MSDOS" \
  BINUTILSPREFIX= \
  INSTALL_PREFIX="$FPC_CROSS_PREFIX"

make install \
  FPC="$NATIVE_FPC" \
  OS_TARGET=msdos \
  CPU_TARGET=i8086 \
  BINUTILSPREFIX= \
  INSTALL_PREFIX="$FPC_CROSS_PREFIX" \
  INSTALL_BINDIR="$cross_bin" \
  INSTALL_BASEDIR="$cross_lib"

if [ ! -x "$cross_bin/$cross_pp" ] && [ -x "$cross_lib/$cross_pp" ]; then
  cp "$cross_lib/$cross_pp" "$cross_bin/$cross_pp"
  chmod 755 "$cross_bin/$cross_pp"
fi

cd "$rtl_dir"
make install \
  FPC="$cross_bin/$cross_pp" \
  OS_TARGET=msdos \
  CPU_TARGET=i8086 \
  BINUTILSPREFIX= \
  INSTALL_PREFIX="$FPC_CROSS_PREFIX" \
  INSTALL_BASEDIR="$cross_lib" \
  INSTALL_UNITDIR="$cross_lib/units/i8086-msdos/rtl"

cd "$packages_dir"
make install \
  FPC="$cross_bin/$cross_pp" \
  OS_TARGET=msdos \
  CPU_TARGET=i8086 \
  BINUTILSPREFIX= \
  INSTALL_PREFIX="$FPC_CROSS_PREFIX" \
  INSTALL_BASEDIR="$cross_lib" \
  INSTALL_UNITDIR="$cross_lib/units/i8086-msdos/packages"

cat > /etc/fpc-cross-386-dos.cfg <<EOF
# Search the cross-compiler before any native compiler in PATH.
-FD$cross_bin

# The compiler executable installed by the bootstrap.
-XP

# Cross target.
-Pi8086
-Tmsdos

# UniFlash is a real-mode DOS program for 386-class CPUs.
-Cp80386
-Op80386

# Units and configuration.
-Fu$cross_lib/units/i8086-msdos/*
-Fu$cross_lib/units/i8086-msdos/rtl
-Fu$cross_lib/units/i8086-msdos/packages/*
-Fu$cross_lib/units/i8086-msdos/packages

# Keep builds reproducible inside the container.
-FE.
EOF

"$cross_bin/$cross_pp" -i > /tmp/ppcross8086-info.txt