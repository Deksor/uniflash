# Release checklist

## Source and documentation

- [ ] `UF_VERSION_STRING` matches the intended release.
- [ ] `CHANGELOG.md` has a release date and no longer says “Unreleased.”
- [ ] `TODO.md` accurately identifies disabled functionality.
- [ ] README commands match `UNIFLASH -H`.
- [ ] The legacy Pascal reference tree remains buildable.

## Automated validation

- [ ] `make test`
- [ ] `make toolchain-smoke`
- [ ] `make build`
- [ ] `git diff --check`
- [ ] Confirm `build/msdos-c/UNIFLASH.EXE` is an MS-DOS MZ executable.
- [ ] `make release`
- [ ] Inspect the ZIP contents and verify its SHA-256 checksum.

## Physical DOS validation

- [ ] GUI starts, navigates, and exits with chipset state restored.
- [ ] Automatic ROM detection works.
- [ ] Known working `-BASE` override still works.
- [ ] ROM backup matches a second independent read.
- [ ] ROM comparison detects a deliberately modified file.
- [ ] Boot-block backup is exactly 8192 bytes.
- [ ] CMOS backup size and contents are plausible.
- [ ] Test any CT-Flasher or PCI-card path claimed by the release notes.

## Publication

- [ ] Record tested motherboard, chipset, flash chip, DOS, and memory manager.
- [ ] Attach the ZIP and `.sha256` file.
- [ ] Publish known limitations prominently.
