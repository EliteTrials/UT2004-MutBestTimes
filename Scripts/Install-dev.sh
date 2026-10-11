#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ut2004_dir=$(CDPATH= cd -- "$script_dir/../.." && pwd)

mkdir -p "$ut2004_dir/Textures"
cp -f "$script_dir/Textures/TextureBTimes.utx" "$ut2004_dir/Textures/TextureBTimes.utx"
