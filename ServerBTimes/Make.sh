#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ut2004_dir=$(CDPATH= cd -- "$project_dir/../.." && pwd)
package_name=$(basename -- "$project_dir")
build_dir=$ut2004_dir/$package_name
system_dir=$ut2004_dir/System

if [ ! -x "$system_dir/ucc-bin" ]; then
    echo "UT2004 Linux compiler not found or not executable: $system_dir/ucc-bin" >&2
    exit 1
fi

rm -f "$system_dir/$package_name.u"
mkdir -p "$build_dir/System" "$build_dir/Classes"
cp -R "$project_dir/System/." "$build_dir/System/"
rm -f "$build_dir/Classes/"*.uc "$build_dir/Classes/"*.uci
find "$project_dir/Classes" -type f \( -name '*.uc' -o -name '*.uci' \) \
    -exec cp -f {} "$build_dir/Classes/" \;

cd "$system_dir"
./ucc-bin editor.MakeCommandlet -SILENTBUILD -AUTO "-ini=$project_dir/make.ini"
