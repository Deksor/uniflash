# UniFlash 2.00 TODO

This list records functionality present in the Pascal implementation but not
yet exposed or completed in the C port.

## Release blockers for destructive operations

- [ ] Port the application-level erase, program, and verify workflow.
- [ ] Preserve partial-sector and partial-page contents during programming.
- [ ] Implement boot-block inclusion/exclusion and mismatch handling.
- [ ] Add progress reporting, cancellation boundaries, retry handling, and
      useful flash error details.
- [ ] Disable caching safely around programming and restore the original CPU
      state on every exit path.
- [ ] Validate every programming algorithm on representative physical chips.
- [ ] Add an explicit high-risk confirmation model before enabling any write
      action in the GUI or CLI.

## GUI

- [ ] Enable “Flash BIOS image INCLUDING bootblock.”
- [ ] Enable “Flash backup BIOS image to Flash ROM.”
- [ ] Enable “Flash BIOS image WITHOUT bootblock.”
- [ ] Enable “Flash bootblock to Flash ROM.”
- [ ] Add CT-Flasher selection and PCI expansion-ROM selection screens.
- [ ] Restore progress-bar and last-write-status behavior.
- [ ] Restore safe logging and error-history presentation.

## CMOS, BIOS, and board information

- [ ] Port CMOS restore (`-CMOSR`) with verification and confirmation.
- [ ] Port CMOS clear (`-CMOSC`) with verification and confirmation.
- [ ] Keep an in-memory CMOS backup and implement the original restore-backup
      menu action.
- [ ] Port SMBIOS/DMI discovery and board/system/BIOS information.
- [ ] Port legacy BIOS identification.
- [ ] Port the AMI flash interface (`-AMI`).
- [ ] Port the ASUS flash interface (`-ASUS`).

## Command-line compatibility

- [ ] Port emergency flashing (`-E`).
- [ ] Port erased-chip-ID repair (`-REPAIR`).
- [ ] Port boot-block unlocking (`-UNLOCK`).
- [ ] Port reboot-after-flashing (`-REBOOT`).
- [ ] Port file logging (`-LOG`).
- [ ] Restore redirected-output pagination and legacy diagnostic messages.

The options above are intentionally rejected or unavailable until their
underlying behavior is complete. Read-only `-FORCE` support must never imply
permission to program a forced or unknown chip.

## Hardware lifecycle and compatibility

- [ ] Implement and call the equivalent of `FlatRealOff` during normal and
      error shutdown.
- [ ] Restore the original CPU capability checks around flat-real-mode setup.
- [ ] Allow the ISA CT-Flasher path to operate without requiring PCI-chipset
      detection.
- [ ] Test XMS initialization and fallback behavior with multiple XMS
      managers and without HIMEM.
- [ ] Validate ROM-enable state restoration for every supported chipset.
- [ ] Validate PCI expansion-ROM state restoration for every card backend.
- [ ] Test 64-, 128-, and 256-byte CMOS implementations on physical systems.
- [ ] Add physical test results for each confirmed motherboard, chipset,
      flash chip, CT-Flasher, and PCI card combination.
- [ ] Investigate support for pre-386 systems only as a future project; do
      not weaken the current 386 build assumptions without hardware tests.

## Languages and data

- [ ] Port and review French messages.
- [ ] Port and review Dutch messages.
- [ ] Port and review Italian messages.
- [ ] Port and review German messages.
- [ ] Add language selection to the GUI once another translation is current.
- [ ] Document the process for adding manufacturers, chips, and algorithms.

## Testing and release engineering

- [ ] Add automated CLI-parser tests independent of DOS hardware.
- [ ] Add deterministic screen/menu rendering tests.
- [ ] Add a DOS emulator smoke run where practical; physical hardware remains
      mandatory for hardware access.
- [ ] Record release checksums and physical test results for each release.
