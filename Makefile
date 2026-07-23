DOCKER ?= docker
HOST_CC ?= cc
VERSION ?= 2.00
OW_IMAGE ?= uniflash-openwatcom:2026-07-13
OW_PLATFORM ?= linux/amd64
WORKSPACE := /workspaces/uniflash

.DEFAULT_GOAL := build

.PHONY: all env build test toolchain-smoke check release clean distclean \
	c-env c-build c-rom-data-test c-flash-service-test \
	c-manufacturer-algorithms-test \
	c-hardware-test \
	c-read-workflow-test \
	c-language-test \
	c-cmos-test \
	c-host-test c-toolchain-smoke c-clean

all: build

env:
	$(DOCKER) build --platform "$(OW_PLATFORM)" \
		-f Dockerfile \
		-t "$(OW_IMAGE)" .

build: env
	$(DOCKER) run --rm --platform "$(OW_PLATFORM)" \
		-v "$(CURDIR):$(WORKSPACE)" \
		-w "$(WORKSPACE)" \
		"$(OW_IMAGE)" \
		sh scripts/build-openwatcom.sh "$(WORKSPACE)"

c-rom-data-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/flash/rom_database.c \
		tests/host/rom_database_test.c \
		-o build/host/rom_database_test
	./build/host/rom_database_test

c-flash-service-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/flash/rom_database.c \
		src/flash/flash_service.c \
		src/flash/generic_algorithms.c \
		src/flash/intel_algorithms.c \
		src/flash/sharp_algorithms.c \
		tests/host/flash_service_test.c \
		-o build/host/flash_service_test
	./build/host/flash_service_test

c-manufacturer-algorithms-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/flash/rom_database.c \
		src/flash/flash_service.c \
		src/flash/generic_algorithms.c \
		src/flash/intel_algorithms.c \
		src/flash/sharp_algorithms.c \
		src/flash/manufacturer_common.c \
		src/flash/pmc_algorithms.c \
		src/flash/winbond_algorithms.c \
		src/flash/macronix_algorithms.c \
		src/flash/atmel_algorithms.c \
		src/flash/sst_algorithms.c \
		src/flash/st_algorithms.c \
		src/flash/all_algorithms.c \
		tests/host/manufacturer_algorithms_test.c \
		-o build/host/manufacturer_algorithms_test
	./build/host/manufacturer_algorithms_test

c-hardware-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/hardware/hardware.c \
		src/hardware/pci.c \
		src/hardware/flash_backend.c \
		src/hardware/chipset.c \
		src/hardware/ct_flasher.c \
		src/hardware/pci_rom.c \
		tests/host/hardware_test.c \
		-o build/host/hardware_test
	./build/host/hardware_test

c-read-workflow-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/hardware/hardware.c \
		src/flash/rom_database.c \
		src/flash/flash_service.c \
		src/app/image_store.c \
		src/app/read_workflow.c \
		tests/host/read_workflow_test.c \
		-o build/host/read_workflow_test
	./build/host/read_workflow_test

c-language-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/app/language.c \
		src/app/menu.c \
		tests/host/language_test.c \
		-o build/host/language_test
	./build/host/language_test

c-cmos-test:
	mkdir -p build/host
	$(HOST_CC) -std=c99 -Wall -Wextra -Werror \
		-I. -Iinclude \
		src/hardware/hardware.c \
		src/hardware/cmos.c \
		tests/host/cmos_test.c \
		-o build/host/cmos_test
	./build/host/cmos_test

test: c-rom-data-test c-flash-service-test \
	c-manufacturer-algorithms-test c-hardware-test \
	c-read-workflow-test c-language-test c-cmos-test

toolchain-smoke: env
	$(DOCKER) run --rm --platform "$(OW_PLATFORM)" \
		-v "$(CURDIR):$(WORKSPACE)" \
		-w "$(WORKSPACE)" \
		"$(OW_IMAGE)" \
		verify-openwatcom "$(WORKSPACE)"

check: test toolchain-smoke build

release: check
	sh scripts/package-release.sh "$(VERSION)"

clean:
	rm -f \
		build/msdos-c/main.obj \
		build/msdos-c/flashsvc.obj \
		build/msdos-c/genalgo.obj \
		build/msdos-c/intelalgo.obj \
		build/msdos-c/sharpalgo.obj \
		build/msdos-c/mancommon.obj \
		build/msdos-c/pmcalgo.obj \
		build/msdos-c/wbalgo.obj \
		build/msdos-c/mxalgo.obj \
		build/msdos-c/atalgo.obj \
		build/msdos-c/sstalgo.obj \
		build/msdos-c/stalgo.obj \
		build/msdos-c/allalgo.obj \
		build/msdos-c/hardware.obj \
		build/msdos-c/doshw.obj \
		build/msdos-c/cmos.obj \
		build/msdos-c/pci.obj \
		build/msdos-c/flashback.obj \
		build/msdos-c/chipset.obj \
		build/msdos-c/ctflash.obj \
		build/msdos-c/pcirom.obj \
		build/msdos-c/runtime.obj \
		build/msdos-c/dosxms.obj \
		build/msdos-c/imgstore.obj \
		build/msdos-c/readflow.obj \
		build/msdos-c/language.obj \
		build/msdos-c/menu.obj \
		build/msdos-c/dosgui.obj \
		build/msdos-c/romdb.obj \
		build/msdos-c/PCI.IDS \
		build/msdos-c/UNIFLASH.EXE \
		build/msdos-c/uniflash.map \
		build/host/rom_database_test \
		build/host/flash_service_test \
		build/host/manufacturer_algorithms_test \
		build/host/hardware_test \
		build/host/read_workflow_test \
		build/host/language_test \
		build/host/cmos_test \
		build/c-smoke/MEMMODEL.OBJ \
		build/c-smoke/SMOKE.EXE \
		build/c-smoke/SMOKE.OBJ \
		build/c-smoke/smoke.map \
		build/c-smoke/smoke.lst

distclean: clean
	rm -rf build/release dist

c-env: env
c-build: build
c-host-test: test
c-toolchain-smoke: toolchain-smoke
c-clean: clean
