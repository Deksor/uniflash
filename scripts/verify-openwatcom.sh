#!/usr/bin/env sh
set -eu

project_root="${1:-$(pwd)}"
build_dir="$project_root/build/c-smoke"

for tool in wcc wcl wlink wdis wmake; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Open Watcom tool not found: $tool" >&2
        exit 1
    fi
done

mkdir -p "$build_dir"
rm -f \
    "$build_dir/MEMMODEL.OBJ" \
    "$build_dir/SMOKE.EXE" \
    "$build_dir/SMOKE.OBJ" \
    "$build_dir/smoke.map" \
    "$build_dir/smoke.lst"

cd "$project_root"

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -fo="$build_dir/MEMMODEL.OBJ" \
    tests/toolchain/memory-model.c

wcl -q -bt=dos -lr -3 -mh -k16384 -d2 -od -wx \
    -fo="$build_dir/SMOKE.OBJ" \
    -fe="$build_dir/SMOKE.EXE" \
    -fm="$build_dir/smoke.map" \
    tests/toolchain/smoke.c

if [ ! -s "$build_dir/SMOKE.EXE" ]; then
    echo "The DOS smoke-test executable was not created" >&2
    exit 1
fi

file_description="$(file "$build_dir/SMOKE.EXE")"
case "$file_description" in
    *DOS*executable*|*MS-DOS*)
        ;;
    *)
        echo "Unexpected smoke-test executable format: $file_description" >&2
        exit 1
        ;;
esac

if ! grep -Eiq 'stack.*(00004000|16384|16K)' "$build_dir/smoke.map"; then
    echo "The linker map does not report the requested 16 KiB stack" >&2
    grep -i 'stack' "$build_dir/smoke.map" >&2 || true
    exit 1
fi

wdis -l="$build_dir/smoke.lst" "$build_dir/SMOKE.OBJ"

echo "$file_description"
echo "Open Watcom 2 DOS/16 386 huge-model smoke test passed."
