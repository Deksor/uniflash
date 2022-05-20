# Change Log

## [1.40] - 28-02-2005

### Added

### Changed
- license to GNU GPL v2

### Fixed

### Removed

## [1.39] - never released

- simplified LPC detection and access code

### Added
- -UNLOCK parameter to unlock bootblocks on some chips (like Winbond W29C020)
- logging to LPC detection
- Winbond W83627(H)F, SF/GF, THF and W83637HF and also ITE IT8702F, IT8711F, IT8712F and IT8722F detection (these don't have flash ROM interface but they have GPIO pins)
- BIOS ID reading from F000 segment if not found at top of 4GB
- specific support for Asus A7V266 and A7V8X-X (they use Super I/O GPO pins) and Abit ZM6, BE6 (same as BX133-RAID)
- Winbond W39V040A (LPC) and W39L040A chips
- support for Asus flash interface! (-ASUS parameter) - with this, it should be possible to flash all newer Asus boards
- support for SMBIOS/DMI board identification (needed for specific support for boards with non-Award BIOSes)
- specific support for MSI MS-6380 2.0 and MS-6380E 1.0
- new Intel chipsets: E7210, E7221, E7320, E7520, E7525, E8870, mobile 910/915 series
- VIA VT8237 south bridge and UniChrome KM400(A) chipset

### Changed

### Fixed

### Removed

## [1.38] - 01-01-2005

- BIOS ID is now shown in lower right corner when detected & needed
- updated SST LPC chip names, so they're marked "(LPC)"

### Added  
- BIOS IDs of Abit BF6, all BE6-II variants, all KT7 variants and MSI MS-6337 v5.x   

### Changed

### Fixed
- quitting on some boards immediately after running
- unprotect for ST FWH and LPC chips (one F is missing from the (un)protect register adresses)
- unprotect for ST 50FLW080A and B
- problems with some W49F002U chips by removing a piece of unknown code from AMD flashing routine

### Removed

## [1.37] - 03-07-2004

### Added
- STMicroelectronics M50FW016 (FWH), M50FLW040A (LPC/FWH), M50FLW040B (LPC/FWH), M50FLW080A (LPC/FWH), M50FLW080B (LPC/FWH), M28W201 chips
- AMIC A29800T, A29800B, A29L004T/400T, A29L004B/400B, A29L008T/800T, A29L008B/800B, A29L160T, A29L160B, A29L040 chips
- IMT IM29LV001T, IM29LV001B chips
- EON EN29F512, EN29F010, EN29LV512, EN29LV010, EN29LV040, EN29LV400T, EN29LV400B, EN29LV800(A)T, EN29LV800(A)B, EN29LV160T, EN29LV160B
- SST 49LF020A chip
- SHARP LHF00L02/6/7 (LPC), LHF00L03/4/5 (FWH) and LHF00L01 (LPC) chips
- Intel 915G/P/925X chipsets with new ICH6
- OPTi Viper M/N/NK/N+/DP, changed Vendetta 82C750 to Viper Max/Vendetta 82C750 and fixed a bug in OPTi chipset support
- VIA 486 chipsets with VT82C505 PCI bridge

### Changed

### Fixed

### Removed
- STMicroelectronics M28F102 (is 16-bit)


## [1.36] - 28-05-2004

- c't Flasher can now be used on systems without PCI bus

### Added
- AMD 8000 chipset detection
- AMD Geode SC1100 and SC1200/2200/3200 support and Cx5510 and Cx5520 device IDs

### Changed

### Fixed
- a bug causing -save and -e parameters to not work correctly when used together
- 256B CMOS size detection on chipsets that provide access to full CMOS range using 72/73h registers

### Removed

## [1.35] - 23-04-2004

### Added
- SiS 964 south bridge detection

### Changed

### Fixed
- i82378ZB vs. i82379AB identify
- a bug causing hangs with Winbond LPC Super I/O chips 

### Removed

## [1.34] - 04-03-2004

### Added
- some new PMC chips: Pm39F010, Pm39F020, Pm39F040, Pm39LV020, Pm39LV040
- support for non-standard BIOS write protection methods by detecting BIOS ID string and matching the board in the list of known boards
- alternative method of supporting 256KB chips on M1533/M1543 south bridges - through GPO[19] (used e.g. on Acer V72MA board) (although it does not seem to work...)
- Intel 865P(E)/G(V)/848P chipsets
- some Atmel chips: AT49x2048(A) series, AT49LH002, AT49LH004, AT49LH00B4 and AT49LW080

### Changed

### Fixed
- a bug causing arithmetic overflow with chips with many sectors (such as SST 49LF008A FWH)
- problems with c't Flasher and 5V chips smaller than 512KB that use pin 1 as #RESET
- problems with logging on a write protected drive

### Removed

## [1.33] - 18-10-2003

- no more flashing when file size is not correct
- english-only - other languages are not compiled in the binary release because the translations are outdated
- flash including bootblock by default, flashing without bootblock is available from the advanced menu

### Added
- support for Winbond LPC Super I/O chips W83697(H)F, W83697SF and W83697UF

### Changed

### Fixed
- reboot when running on QDI Titanium IB+ board
- problems with bootblock erasing on Atmel AT49x001(N)(T) and AT49x002(N)(T) chips (bootblock can't be erased separately -> chip erase must be used)
- Restore backup CMOS data in CMOS menu now works

### Removed

## [1.32] - 01-7-2003

- register contents in LOG file are now written as hex numbers

### Added
-  support for c't flasher 8-bit ISA card, autodetecting port and memory base, supports Flash ROMs up to 512KB
    
### Changed

### Fixed

### Removed

## [1.31] - 27-05-2003

- if the south bridge is not found, the first device with no class code is assumed to be south bridge (for old chipsets)
- moved PCI card support into separate unit (PCICARDS.PAS) and added specific support for these PCI network cards:
- STMicroelectronics STE10/100(A), Winbond W89C840AF, SMSC LAN83C175 EPIC/C, VIA VT6102, VT6105M Rhine III, Realtek RTL8129/30/39, RTL8139 series, RTL8169 series, ADMtek AL981 Comet, AN983,985(B/BL) Centaur (B), ADM9511,9513 Centaur II, Adaptec AIC-6915

### Added
- support for ALi Aladdin, the ALi's first Pentium chipset (uses low E and F segments, disabling shadow during read access)
- SiS 648, 651, 655, 733, 745, 746, 748, 755 chipsets
- i845E, i845G(E/L/V)/845PE, i845MP/MZ, i852GM/855GM, i855PM, i875P, E7205, E7501, E7505 chipsets
- VIA Apollo KT333, KT400(A), Apollo Pro 266T, P4X400
- ALi Aladdin 7, Aladdin Pro III (TNT2), CyberBLADE Aladdin i1, Aladdin Pro 5(T/M), Aladdin-P4, CyberAladdin-P4
- support for PMC Pm49FL002/004/008 FWHs/LPCs
    
### Changed
- chipset detection and identifying code to allow easier implementation of support for new chipsets
- i8xx chipset code to support FWHs up to 4MB (32Mbit)
- multi-language code to save some memory by initializing only the selected language (also reduced EXE file size)

### Fixed
- fixed one line more cleared when changing drives in file browser
- fixed error when opening files with read-only attribute set

### Removed

## [1.30] - 13-04-2003

- graph color during flashing now represents the write status - green means write OK, red means write failed (timeout/error)

### Added
- timeouts to all program/erase routines so there should never be any lockups, even if Flash ROM does not respond
- support for i82801DB ICH4
- a question when flashing without bootblock and there's bootblock mismatch allowing user to flash including bootblock (to prevent users from killing the BIOS because of not reading the manual...)
- nVidia nForce support

### Changed

### Fixed
- incorrect ROM Base when no Flash ROM detected
- (forced) displayed when chip was forced and then redetected
- GenPageProg and AtmelPageProg to avoid extra retries for chips that do not support error bit - it slowed down flashing and reduced chip life (nice to see how fast W29EE011 really is)
- a bug in -BASE parameter (thanks to Krystian Rozycki)
- bug in protect/unprotect code for all FWHs that prevented flashing from working

### Removed
- PnP (ESCD) manipulation (DMI was removed some time ago), it was very dangerous (no checks if there really is ESCD data - easy way to kill the BIOS) and useless

## [1.29] - 01-01-2003

- found old Catalyst datasheets - fixed CAT28F150T, added CAT28F015T and CAT28F015B
- better PCI ROM flashing, added 3Dfx Banshee support
- rewrote ALi FinALi support using these new methods (it was a lot easier now)
- some cosmetic fixes (misaligned error messages, some german texts)
- found a way to unprotect Flash ROM on Abit BX133-RAID (GPO used), might work on other Abit i440BX based boards too
BUT: Flashing failed with Winbond W49F002U - some cache problems?

### Added
- some Winbond Flash ROMs: W39L512, W39F010, W39L010, W39L020, W39L040, W39V040FA (FWH) and W49F020   
- Micron Copperhead+Coppertail chipset detection (has no flash write protection)
- Contaq/Cypress hyperCache chipset (CY82C691+CY82C693(U/UB)) and 386/486 chipsets with PCI (CY82C599 required)
- VIA VT8235 south bridge support
- STMicroelectronics M50LPW040, M50FW002 and M50LPW002 chips
- unprotect for STMicroelectronics LPC and FWH chips

### Changed
- changed i82378ZB SIO and i82379AB SIO.A detection (it has no class code - now detected by vendor and device ID if 82434LX/NX present)
- modified code to allow easier implementation of various flash access methods (external progammers, PCI cards...)

### Fixed
- CMOS size detection detecting falsely 256b on some boards
- flashing on PC Chips M715 board (i440LX) with Award BootBlock BIOS (GPO used for write protection)

### Removed

## [1.28] - 03-08-2002
 
- display Chipset and Flash ROM when only -QUIT parameter specified
- enable/disable menu items after redetect with/without Flash ROM
- verify now shows unchanged areas

### Added
- repair feature to repair the erased IDs (-repair parameter)
- support for ALi FinALi 486 chipset
- logging for north bridge methods
- support for UMC UM8881F+UM8886BF chipset (no datasheets, reverse engineering used)
- user friendly filename editing, default file names when saving a file and file browser when opening a file (press ENTER on the prompt, TAB to change drive)
- I/O error checking for all file operations
- -REBOOT patameter to reboot after flashing using -E
- -BASE parameter to set ROM base address manually and allow UniFlash to run without PCI bus

### Changed

### Fixed
- -SAVE paramter (it was completely broken)
- bug causing reset of ITE LPC Super I/Os (resulting in floppy and COM&LPT ports not working until reboot)
- Macronix chip detection
- Atmel AT29Cxxx detection (again, it really works now)
- Atmel programming routine (chip remained unprotected)
- some SiS chipset support
- Utron 128KB support (again)
- showing SUCCESS when bootblock mismatch and user answered NO
- the detection routine erased vendor and device IDs from some Winbond and SST chips (detected properly once but then unknown, BIOS displayed "Unknown Flash Type" message)
- hang when running under Award BootBlock BIOS with uninitialized or absent graphics card

### Removed
- $4B and $D5 IDs for Macronix MX28F1000P (they were there because of the detection bug which is now fixed)

## [1.27] - 27-05-2002

- success chime sound also in emergency mode
- clear keyboard buffer before asking for file names and also on exit

### Added
- -MONO parameter for monochrome monitors   
- some VIA chipsets: ProSavage KM133(A), P4M266, P4X266(A)/333
- real VIA VT8233 support   
- ITE IT8700F/8705F and IT8710 LPC Super I/O detection with SiS 540 and SiS 630 chipsets and all newer
- some SiS chipsets : SiS 635, SiS 640, SiS 645, SiS 645DX, SiS 650, SiS 730, SiS 735 and SiS 740 - I have no datasheets, but SiS 735 is tested and works

### Changed
- enhanced -PCIROM functionality, you can now manually specify a device by its BUS, DEVICE and FUNCTION numbers (decimal)

### Fixed
- HiNT VXPro-II (Utron UC85C501/502) 128KB Flash ROMs
- hang when EMM386.EXE is loaded (display error message now)
- Atmel AT29Cxxx detection
- memory de-allocation bug when HIMEM.SYS is loaded

### Removed

## [1.26] - 07-04-2002

- ALi FINALi 486 chipset (M1489) is not supported because it doesn't map Flash ROM below 4GB
- PCI-to-ISA posted write buffer is disabled on ALi chipsets during flashing to fix problems with some Flash ROMs (e.g. EON)

### Added
- Intel E7500 chipset with 82801CA (ICH3-S) I/O Controller Hub
- some ALi chipsets: Aladdin III (M1521 and M1523(B)) and Aladdin IV/IV+ (M1531(B))   
- AMD 760MPX chipset with AMD-768 South Bridge
- OPTi Vendetta 82C750 chipset (removed the old disabled code)
- HiNT VXPro-II chipset (I think that it's Utron UC85C501/502, because this one matches it and has programmable Mfg.&Device IDs)
- -QUIT parameter - quits when processed, all comands after will be ignored (useful use: "UNIFLASH -SAVE BACKUP.BIN -QUIT")
- German language support (by Gerald Bottcher)
- unprotect for SST49LF002A/003A/004A/008A FWHs

### Changed

### Fixed

### Removed

## [1.25] - 21-01-2002

- pressing ESC in -chiplist will quit
- CMOS size in log

### Added
- -CMOSS (Save CMOS), -CMOSR (Restore CMOS) and -CMOSC (Clear CMOS) options (they work also in Windows)
- support for 256b CMOS
- ServerWorks ServerSet III LE and HE chipsets with Reliance NB6536 & NB6635 North Bridges (without any info from ServerWorks)
- National Semiconductor PicoPower Vesuvius-LS chipset
- National Semiconductor Geode GX1 CPU with North Bridge (Cyrix MediaGX) and CS5530(A) South Bridge (Cyrix CX5530(A))

### Changed

### Fixed
- crash in Windows on some machines - display error message (thanks to Alejando Pelaez)
- CMOS support to save/restore/clear also bytes 15 and 16
    
### Removed

## [1.24] - 03-12-2001

- AMI Flash Interface is no longer automatically enabled to prevent hangs. You must use "-ami" parameter to activate it.
- pressing Q in -chiplist will quit (like MORE.COM)    

### Added
- support for some ALi chipsets: Aladdin Pro IV and ALiMAGiK 1
- VIA Apollo VP3 with VT82C596 South Bridge
- Redetect Flash ROM function
- added two more IDs for Macronix MX28F1000P - $4B and $D5   
- Reliance/ServerWorks OSB4 South Bridge

### Changed
- simplified detection routine - removed support for multiple Flash ROMs and removed all 16-bit wide ROMs, cleaned up the code 

### Fixed
- 256KB and 512KB support for ALi chipsets
- Macronix MX29F002(N)T slow erase bug

### Removed

## [1.23] - 26-09-2001

- new keyboard handler doesn't use BIOS - this allows UniFlash to work correctly under Award BootBlock BIOS (tested)
- tried to fix but still not fixed SiS 501/5101/5501 support
- some VIA reverse engineering (reserved registers seems to be used) but new VIA/AMD chipsets still not working (if you have "Flash Write Protect" option in BIOS, your chipset will work when you disable it)

### Added
- Italian language support (by Enrico Antongiovanni)
- timeout to GenPageProgB and GenPageProgW (to prevent hangs with boot block protection enabled on Winbond Flash ROMs)
- auto-logging feature (-LOG parameter)
- support for Intel 830MP and 845 chipsets
- simple help on the bottom of screen in menu
- new program/erase routines for Winbond Sectored Flash ROMs (may fix Winbond W29F002U?)
    
### Changed

### Fixed

### Removed

## [1.22] - 30-07-2001

- doesn't exit when no Flash ROM detected in PCI Option ROM mode
- chiplist now pauses after each screen (no need for external more program) but not when stdout is redirected
- heavy menu modifications, removed expert and debug modes - they're not needed anymore, add Home,PgUp/End,PgDown keys
- simplified the detection routine (note: new one is still not done)

### Added
- error messages: running under Windows, PCI bus not found
- new delay routine based on Time Stamp Counter (TSC), it's used on all CPUs that supports TSC (Pentium+), old CPUs use the old routine. This fixed all problems with slow performance on fast computers   
- support for Intel 860 chipset (Xeon) and ALi Aladdin V
- support for 1MB Flash ROMs with VIA VT82C596(A|B) and VT82C686(A) South Bridges  
- beep after successful flashing   
- some Intel chips: 28F008-T series and 28F008-B series
- STMicroelectronics Flash ROMs: M28F256, M28F512, M28F101, M28F102, M28F201, M29F512B, M29F010B, M29F040(B), M29F080A, M29F016B, M29F002(B)(N)T, M29F002(B)B, M29F100(B)T, M29F100(B)B, M29F200(B)T, M29F200(B)B, M29F400(B)T, M29F400(B)B, M29F800AT, M29F800AB, M29F160BT, M29F160BB, M29W512B, M29W010B, M29W022BT, M29W022BB, M29W040(B), M29W200BT, M29W200BB, M29W400(B)T, M29W400(B)B, M29W800(A)T, M29W800(A)B, M29W160BB/DB, M29W004(B)T, M29W004(B)B, M29W008(A)T, M29W008(A)B, M50FW040 (FWH), M50FW080 (FWH) and M50LPW080 (LPC)
- Texas Instruments Flash ROMs: TMS28F210, TMS29xF040 and info about the others into docs
- Fujitsu Flash ROMs: MBM29F002TC, MBM29F002BC, MBM29F200TC, MBM29F200BC, MBM29F400TC, MBM29F400BC, MBM29F040C, MBM29F033C, MBM29LV160TE, MBM29LV160BE, MBM29PL160TD and MBM29PL160BD

### Changed
- waiting times for Page Write Flash ROMs (most of Atmel, SST and Winbond Flash ROMs) to prevent lock-ups
- Mosel support for SyncMOS chips F29C31004B and F29C31400T

### Fixed
- Flash ROM write protect enable/disable - fixed possible chipset register corruption
- i430MX South Bridge detection (thanks to Josh Little but he paid hard for that - his notebook doesn't work anymore because Intel 28F004-T support doesn't work)
- a _VERY_ NASTY BUG in Bulk Erase/Need Blanking chip support this one was there probably from the beginning of UniFlash and actually caused the same byte to be flashed to entire chip... This fixed almost all Bulk Erase/Need Blanking chips.
Nils Emil P. Larsen tested these Bulk Erase/Need Blanking chips, they're working CAT28F010, MX28F1000P, Intel 28F010 and also H.T. M21561 (which is actually MX28F1000P)
- memory corruption when using -chiplist (thanks to Marusceac Claudiu Florin)
- a bit PCI Option ROM enabling (for AGP cards), but flashing still does not work (looks like writes to ROM are ignored - like write protection, the Flash ROM is not responding to commands)

### Removed
- BIOS info (I haven't seen it working anywhere)

## [1.21] - 10-06-2001

Some code size optimizations

### Added
- support for SiS chipsets: 85C496+497, 85C501/5101/5501, 5511, 5571,5591/5592, 5596, 5597/5598/5581/5120, 530, 540, 600, 620 and 630 (all untested). It's unbelievable, but they are using 5 (!) different methods to enable Flash ROM write and what's more, all their south bridges have the same device ID - $0008 (SiS 540 and 630 can have either $0008 or $0018).
- support for SMSC VictoryBX-66 chipset
- support for Winbond/Symphony Labs W83C553F South Bridge
- support for ITE South Bridges IT8871F/2F and IT8888F
- support for Alliance Semiconductor Flash ROMs: AS29F040, AS29F002T, AS29F002B, AS29LV400T, AS29LV400B, AS29F200T, AS29F200B, AS29LV800T and AS29LV800B
- some AMD Flash ROMs: Am29LV001BT, Am29LV001BB, Am29LV010B, Am29F004BT, Am29F004BB, Am29LV040B, Am29LV081B, Am29LV008(B)T, Am29LV008(B)B, Am29LV800BT, Am29LV800BB, Am29SL800CT, Am29SL800CB, Am29F016(B), Am29F017B, Am29LV017B, Am29LV116BT, Am29LV116BB, Am29F160DT, Am29F160DB, Am29LV160BT/DT, Am29LV160BB/DB, Am29SL160CT, Am29SL160CB, Am29PL160CB, Am29F032B, Am29LV033C, Am29LV320DT, Am29LV320DB, Am29LV065D
- some Atmel Flash ROMs: AT29LV512, AT49x512, AT49x010, AT49x001(N)T, AT49x001(N), AT49x002(N)T, AT49x002(N), AT49x2048(A), AT49x4096(A), AT49x008AT, AT49x8192(A)T, AT49x8192(A), AT49x8011T, AT49x8011, AT49x160/161(4)T, AT49x160/161(4), AT49BV320T/321T, AT49BV320/321
- some Catalyst Flash ROMs: CAT28F010, CAT28F020, CAT28F102, CAT28F512
- EON Flash ROMs: EN29F040, EN29F080, EN29F800T, EN29F800B, EN29F002T, EN29F002B
- Hyundai Flash ROMs: HY29F002T, HY29F002B, HY29F040, HY29F040A, HY29F080, HY29F400T, HY29F400B, HY29F800T, HY29F800B, HY29LV160T, HY29LV160B
- IMT Flash ROMs: IM29F001T, IM29F001B, IM29F002T, IM29F002B, IM29F004T, IM29F004B, IM29LV004T, IM29LV004B
- some Intel chips: 28F256A, 28F512, 28F004Sx, 28F008Sx, 28F008SA, 28F016Sx, 28F016S5/SA, 28F320J3A, 28F320J5, 28F640J3A, 28F640J5, 28F128J3A
- ISSI (Integrated Silicon Solution) Flash ROMs: IS28F010 and IS28F020
- some Macronix chips: MX28F2000P, MX28F2000T, MX29F100T, MX29F100B, MX28F002T, MX28F002B, MX29F001T, MX29F001B, MX29F002(N)T, MX29F002(N)B, MX29F022T, MX29F022B, MX29F200T, MX29F200B, MX29F004T, MX29F004B, MX29F400T, MX29F400B, MX29LV004T, MX29LV004B, MX29LV400T, MX29LV400B, MX29F040, MX29LV040, MX29F080, MX29LV081, MX29F800T, MX29F800B, MX29LV008T, MX29LV800T, MX29LV800B, MX29F016, MX29L1611, MX29L1611G, MX29F1610A, MX29LV160T, MX29LV160B, MX29F1615, MX29L3211
- Mosel Vitelic Flash ROMs: V29C51000T, V29C51000B, V29C51001T, V29C51001B, V29C51002T, V29C51002B, V29C51004T, V29C51004B, V29C51400T, V29C51400B, V29C31004T, V29C31004B, V29LC51000, V29LC51001, V29LC51002
- PMC Flash ROMs: Pm39LV512R, Pm39LV010R, Pm29F002T, Pm29F002B, Pm29F004T/5V or Pm29LV104T, Pm29F004B or Pm29LV104B
- some SST Flash ROMs: 29SF512, 29VF512, 29SF010, 29VF010, 29SF020, 29VF020, 29SF040, 29VF040, 39SF512, 39xF512, 39S010(A), 39xF010, 39SF020(A), 39xF020, 39SF040, 39xF040, 39xF080, 39xF016, 39xF200A, 39xF400A, 39xF800A, 39xF160, 49LF002(A), 49LF003A, 49LF004, 49LF004A, 49LF008, 49LF008A, 49LF020, 49LF030, 49LF040, 49LF080
- some Winbond Flash ROMs: W29C040, W49F002U, W49V002(A), W49V002F(A), W29F102 or W49F102, W49L102, W49F201, W49L201

### Changed
- sector structure array - can now hold more sectors (upto 5*65535), 128b to 8MB each (see addchip.faq)

### Fixed
- Flash ROM detection - Device IDs can have even parity

### Removed
- Macronix MX28F1000PC and MX28F1000PPC (not existing)

## [1.20] - 08-05-2001

### Added
- support for these AMIC chips: A29001(1)T, A29001(1)B, A29010, A29002(1)T, A29002(1)B, A29400T, A29400B and A29040 They're all sectored and use AMD commands. (For Matt Choudoir's broken ABIT KT7A with AMIC A29002T) A29002(1)T tested and works correctly, others are untested.
- support for newer VIA chipsets (all untested): Apollo MVP4, Apollo Pro, Apollo Pro Plus/133/133A, Apollo ProMedia, Apollo Pro 133Z/PM133, Apollo KX133, Apollo KT133(A), Apollo KT266, Apollo Pro 266. North Bridges: VT8501, VT82C691/693(A)/694X, VT82C693(A), VT8601, VT8605, VT8371, VT8363(A), VT8366, VT8633 South Bridges: VT82C686(A), VT8231, VT8233 (last two may or may not work because I don't have datasheets). Plus some north bridges that aren't used anywhere (but are in VIA's INF file) - VT8653, VT8662, VT8615, VT8361, VT3133.
- support for AMD 750, 760 and 760MP chipsets (751,761 and 762 north bridges, 756 and 766 south bridges). Registers are almost same as VIA. Untested.

### Changed
 
### Fixed

### Removed

## [1.19] - 08-04-2001
 
### Added
- support for Intel 8xx chipsets (Hub Architecture): i810, 810E, 810E2, 815, 815E(P), 815EM, 820, 820E, 840, 850 with these I/O controller hubs: 82801AA(ICH), 
- 82801AB(ICH0), 82801BA(ICH2), 82801BAM(ICH2-M) (they're all not tested)
- M1543 now support 512KB ROMs, but only some revisions of this chip can really support them (and according to ALi, there is no software way to detect that)

### Changed
 
### Fixed
- ALi chipset detection

### Removed

## [1.18] - 02-02-2001

I (Rainbow Software) am continuing the development of this program after it was abandoned for two years

### Added
- support for i440BX/ZX and i440GX chipsets
- support for ALi M1543 south bridge and ALi M1621 north bridge (ALi Aladdin Pro II chipset)
- some info about ASD chips into this DOC
- support for Intel 82802AB(4Mb)/AC(8Mb)Firmware Hubs
- support for Atmel AT49F002(N)T chip

### Changed
 
### Fixed

### Removed