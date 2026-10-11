#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ut2004_dir=$(CDPATH= cd -- "$project_dir/.." && pwd)

if [ ! -x "$ut2004_dir/System/ucc-bin" ]; then
    echo "UT2004 Linux compiler not found or not executable: $ut2004_dir/System/ucc-bin" >&2
    exit 1
fi

for package in Core Engine TrialGroup; do
    if [ ! -f "$ut2004_dir/System/$package.u" ]; then
        echo "Required package missing: $ut2004_dir/System/$package.u" >&2
        exit 1
    fi
done

if ! cmp -s "$project_dir/Scripts/Textures/TextureBTimes.utx" \
    "$ut2004_dir/Textures/TextureBTimes.utx"; then
    echo "Development texture is missing or outdated. Run:" >&2
    printf 'sh "%s/Scripts/Install-dev.sh"\n' "$project_dir" >&2
    exit 1
fi

echo "Installation validated. Building ClientBTimes..."
sh "$project_dir/ClientBTimes/Make.sh"
echo "Building ServerBTimes..."
sh "$project_dir/ServerBTimes/Make.sh"

if [ ! -f "$ut2004_dir/System/ServerBTimes.u" ]; then
    echo "Server build did not produce $ut2004_dir/System/ServerBTimes.u" >&2
    exit 1
fi

echo "Client and server builds completed."
