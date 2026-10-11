#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ut2004_dir=$(CDPATH= cd -- "$project_dir/../.." && pwd)
package_name=$(basename -- "$project_dir")
version=V7b
# DO NOT CHANGE VX: make.ini and source references use this package name.
compiled_package_name=${package_name}VX
build_dir=$ut2004_dir/$compiled_package_name
system_dir=$ut2004_dir/System

if [ ! -x "$system_dir/ucc-bin" ]; then
    echo "UT2004 Linux compiler not found or not executable: $system_dir/ucc-bin" >&2
    exit 1
fi

rm -f "$system_dir/$compiled_package_name.u" \
    "$system_dir/$compiled_package_name.ucl" \
    "$system_dir/$compiled_package_name.int"

if [ ! -d "$build_dir/Resources" ]; then
    mkdir -p "$build_dir"
    cp -R "$project_dir/Resources" "$build_dir/Resources"
    cp -R "$project_dir/Textures" "$build_dir/Textures"
fi

mkdir -p "$build_dir/Classes"
rm -f "$build_dir/Classes/"*.uc "$build_dir/Classes/"*.uci
find "$project_dir/Classes" -type f \( -name '*.uc' -o -name '*.uci' \) \
    -exec cp -f {} "$build_dir/Classes/" \;

cd "$system_dir"
./ucc-bin MakeCommandlet "-ini=$project_dir/make.ini"
mv -f "$compiled_package_name.u" "$package_name$version.u"
rm -f "$compiled_package_name.ucl"
