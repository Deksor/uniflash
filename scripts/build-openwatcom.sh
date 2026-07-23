#!/usr/bin/env sh
set -eu

project_root="${1:-$(pwd)}"
build_dir="$project_root/build/msdos-c"

for tool in wcc wcl wlink; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Open Watcom tool not found: $tool" >&2
        exit 1
    fi
done

mkdir -p "$build_dir"
rm -f \
    "$build_dir/main.obj" \
    "$build_dir/flashsvc.obj" \
    "$build_dir/genalgo.obj" \
    "$build_dir/intelalgo.obj" \
    "$build_dir/sharpalgo.obj" \
    "$build_dir/mancommon.obj" \
    "$build_dir/pmcalgo.obj" \
    "$build_dir/wbalgo.obj" \
    "$build_dir/mxalgo.obj" \
    "$build_dir/atalgo.obj" \
    "$build_dir/sstalgo.obj" \
    "$build_dir/stalgo.obj" \
    "$build_dir/allalgo.obj" \
    "$build_dir/hardware.obj" \
    "$build_dir/doshw.obj" \
    "$build_dir/cmos.obj" \
    "$build_dir/pci.obj" \
    "$build_dir/flashback.obj" \
    "$build_dir/chipset.obj" \
    "$build_dir/ctflash.obj" \
    "$build_dir/pcirom.obj" \
    "$build_dir/runtime.obj" \
    "$build_dir/dosxms.obj" \
    "$build_dir/imgstore.obj" \
    "$build_dir/readflow.obj" \
    "$build_dir/language.obj" \
    "$build_dir/menu.obj" \
    "$build_dir/dosgui.obj" \
    "$build_dir/romdb.obj" \
    "$build_dir/UNIFLASH.EXE" \
    "$build_dir/uniflash.map"

cd "$project_root"

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/main.obj" \
    src/main.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/flashsvc.obj" \
    src/flash/flash_service.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/genalgo.obj" \
    src/flash/generic_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/intelalgo.obj" \
    src/flash/intel_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/sharpalgo.obj" \
    src/flash/sharp_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/mancommon.obj" \
    src/flash/manufacturer_common.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/pmcalgo.obj" \
    src/flash/pmc_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/wbalgo.obj" \
    src/flash/winbond_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/mxalgo.obj" \
    src/flash/macronix_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/atalgo.obj" \
    src/flash/atmel_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/sstalgo.obj" \
    src/flash/sst_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/stalgo.obj" \
    src/flash/st_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/allalgo.obj" \
    src/flash/all_algorithms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/hardware.obj" \
    src/hardware/hardware.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/doshw.obj" \
    src/hardware/dos_hardware.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/cmos.obj" \
    src/hardware/cmos.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/pci.obj" \
    src/hardware/pci.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/flashback.obj" \
    src/hardware/flash_backend.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/chipset.obj" \
    src/hardware/chipset.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/ctflash.obj" \
    src/hardware/ct_flasher.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/pcirom.obj" \
    src/hardware/pci_rom.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/runtime.obj" \
    src/hardware/runtime.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/dosxms.obj" \
    src/hardware/dos_xms.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/imgstore.obj" \
    src/app/image_store.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/readflow.obj" \
    src/app/read_workflow.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/language.obj" \
    src/app/language.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/menu.obj" \
    src/app/menu.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/dosgui.obj" \
    src/app/dos_gui.c

wcc -q -bt=dos -3 -mh -d2 -od -wx \
    -dUF_TARGET_DOS16 \
    -i=. -i=include \
    -fo="$build_dir/romdb.obj" \
    src/flash/rom_database.c

wcl -q -bt=dos -lr -3 -mh -k16384 -d2 -od -wx \
    -fe="$build_dir/UNIFLASH.EXE" \
    -fm="$build_dir/uniflash.map" \
    "$build_dir/main.obj" \
    "$build_dir/flashsvc.obj" \
    "$build_dir/genalgo.obj" \
    "$build_dir/intelalgo.obj" \
    "$build_dir/sharpalgo.obj" \
    "$build_dir/mancommon.obj" \
    "$build_dir/pmcalgo.obj" \
    "$build_dir/wbalgo.obj" \
    "$build_dir/mxalgo.obj" \
    "$build_dir/atalgo.obj" \
    "$build_dir/sstalgo.obj" \
    "$build_dir/stalgo.obj" \
    "$build_dir/allalgo.obj" \
    "$build_dir/hardware.obj" \
    "$build_dir/doshw.obj" \
    "$build_dir/cmos.obj" \
    "$build_dir/pci.obj" \
    "$build_dir/flashback.obj" \
    "$build_dir/chipset.obj" \
    "$build_dir/ctflash.obj" \
    "$build_dir/pcirom.obj" \
    "$build_dir/runtime.obj" \
    "$build_dir/dosxms.obj" \
    "$build_dir/imgstore.obj" \
    "$build_dir/readflow.obj" \
    "$build_dir/language.obj" \
    "$build_dir/menu.obj" \
    "$build_dir/dosgui.obj" \
    "$build_dir/romdb.obj"

if [ ! -s "$build_dir/UNIFLASH.EXE" ]; then
    echo "The UniFlash C executable was not created" >&2
    exit 1
fi

file "$build_dir/UNIFLASH.EXE"
