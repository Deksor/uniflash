#!/usr/bin/env sh
set -eu

version="${1:-2.00}"
project_root="${2:-$(pwd)}"
release_name="uniflash-${version}"
release_root="$project_root/build/release"
stage_dir="$release_root/$release_name"
dist_dir="$project_root/dist"
archive="$dist_dir/$release_name.zip"
checksum="$archive.sha256"
executable="$project_root/build/msdos-c/UNIFLASH.EXE"

if [ ! -s "$executable" ]; then
    echo "Missing DOS executable: $executable" >&2
    exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
    echo "The zip utility is required to package a release" >&2
    exit 1
fi

rm -rf "$stage_dir"
rm -f "$archive" "$checksum"
mkdir -p "$stage_dir" "$dist_dir"

cp "$executable" "$stage_dir/UNIFLASH.EXE"
cp "$project_root/README.md" "$stage_dir/README.md"
cp "$project_root/LICENSE.TXT" "$stage_dir/LICENSE.TXT"
cp "$project_root/CHANGELOG.md" "$stage_dir/CHANGELOG.md"
cp "$project_root/TODO.md" "$stage_dir/TODO.md"
cp "$project_root/RELEASE_CHECKLIST.md" "$stage_dir/RELEASE_CHECKLIST.md"

(
    cd "$release_root"
    zip -qr "$archive" "$release_name"
)
(
    cd "$dist_dir"
    sha256sum "$release_name.zip" > "$release_name.zip.sha256"
)

echo "Created $archive"
echo "Created $checksum"
