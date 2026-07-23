# Legacy Pascal implementation

This directory preserves the original UniFlash Pascal source, historical
documentation, and the later Free Pascal real-mode DOS build environment.
It is the behavioral reference for the UniFlash 2.00 C port.

The last build published by Ondrej Zary is available from the
[UniFlash 1.40 release](https://github.com/Deksor/uniflash/releases/tag/1.40).

To build the Pascal version from the repository root:

```sh
docker build -f legacy/pascal/Dockerfile -t uniflash-pascal .
docker run --rm \
  -v "$PWD:/workspaces/uniflash" \
  -w /workspaces/uniflash/legacy/pascal \
  uniflash-pascal make
```

The expected output is `legacy/pascal/build/msdos/UNIFLASH.EXE`.
