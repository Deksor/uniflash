FPC_VERSION ?= 3.2.2
FPC_SRC ?= /usr/share/fpcsrc/$(FPC_VERSION)
FPC_CROSS ?= /opt/fpc-cross/bin/ppcross8086
FPC_CROSS_CFG ?= /etc/fpc-cross-386-dos.cfg

ifeq ($(wildcard $(FPC_SRC)/rtl/msdos/prt0s.asm),)
ifneq ($(wildcard /opt/fpcbuild-$(FPC_VERSION)/fpcsrc/rtl/msdos/prt0s.asm),)
FPC_SRC := /opt/fpcbuild-$(FPC_VERSION)/fpcsrc
endif
endif

ifeq ($(wildcard $(FPC_SRC)/rtl/msdos/prt0s.asm),)
ifneq ($(wildcard /tmp/fpc-source-$(FPC_VERSION)/rtl/msdos/prt0s.asm),)
FPC_SRC := /tmp/fpc-source-$(FPC_VERSION)
endif
endif

ifeq ($(wildcard $(FPC_CROSS)),)
ifneq ($(wildcard /tmp/fpc-source-$(FPC_VERSION)/compiler/ppcross8086),)
FPC_CROSS := /tmp/fpc-source-$(FPC_VERSION)/compiler/ppcross8086
endif
endif

PROGRAM ?= UNIFLASH.PAS
OUTDIR ?= build/msdos
UNITDIR ?= $(OUTDIR)/units
OUTPUT ?= UNIFLASH.exe

# Memory model options: Tiny, Small, Medium, Compact, Large, Huge
MODEL ?= Huge

MSDOS_RTL_DIR := $(FPC_SRC)/rtl/msdos

ifeq ($(MODEL),Small)
STARTUP_OBJ := prt0s.o
else ifeq ($(MODEL),Large)
STARTUP_OBJ := prt0l.o
else ifeq ($(MODEL),Huge)
STARTUP_OBJ := prt0h.o
else
$(error Unsupported MODEL '$(MODEL)'. Use Small, Large, or Huge.)
endif

STARTUP_ASM := $(MSDOS_RTL_DIR)/$(STARTUP_OBJ:.o=.asm)
STARTUP_BIN := $(MSDOS_RTL_DIR)/$(STARTUP_OBJ)

CFG_FLAG :=
ifneq ($(wildcard $(FPC_CROSS_CFG)),)
CFG_FLAG := @$(FPC_CROSS_CFG)
endif

PATH_FLAGS := \
	-Fu$(FPC_SRC)/rtl/msdos \
	-Fu$(FPC_SRC)/rtl/inc \
	-Fu$(FPC_SRC)/rtl/i8086 \
	-Fu$(FPC_SRC)/rtl/objpas \
	-Fu$(FPC_SRC)/packages/rtl-console/src/msdos \
	-Fu$(FPC_SRC)/packages/rtl-console/src/inc \
	-Fi$(FPC_SRC)/rtl/msdos \
	-Fi$(FPC_SRC)/rtl/inc \
	-Fi$(FPC_SRC)/rtl/i8086 \
	-Fi$(FPC_SRC)/rtl/common \
	-Fi$(FPC_SRC)/rtl/objpas \
	-Fi$(FPC_SRC)/packages/rtl-console/src/msdos \
	-Fi$(FPC_SRC)/packages/rtl-console/src/inc

FPCFLAGS := $(CFG_FLAG) -B -Sg -Tmsdos -Pi8086 -Cp80386 -Op80386 -Wm$(MODEL) -Fu. $(PATH_FLAGS) -FU$(UNITDIR) -FE$(OUTDIR) -Fl$(MSDOS_RTL_DIR) -o$(OUTPUT)

.PHONY: all build bootstrap check startup clean distclean info

all: build

build: check startup | $(OUTDIR) $(UNITDIR)
	$(FPC_CROSS) $(FPCFLAGS) $(PROGRAM)

bootstrap:
	bootstrap-fpc-cross

check:
	@test -x "$(FPC_CROSS)"
	@test -f "$(STARTUP_ASM)"
	@command -v nasm >/dev/null

startup: $(STARTUP_BIN)

$(STARTUP_BIN): $(STARTUP_ASM)
	cd "$(MSDOS_RTL_DIR)" && nasm -f obj -o "$(STARTUP_OBJ)" "$(STARTUP_OBJ:.o=.asm)"

$(OUTDIR):
	mkdir -p "$@"

$(UNITDIR):
	mkdir -p "$@"

clean:
	rm -rf "$(OUTDIR)"

distclean: clean
	rm -f *.a *.ppu *.o UNIFLASH.exe

info:
	@echo "FPC_CROSS=$(FPC_CROSS)"
	@echo "FPC_CROSS_CFG=$(FPC_CROSS_CFG)"
	@echo "FPC_SRC=$(FPC_SRC)"
	@echo "MODEL=$(MODEL)"
	@echo "STARTUP_OBJ=$(STARTUP_BIN)"