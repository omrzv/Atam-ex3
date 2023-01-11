#!/usr/bin/env bash

set -eu

cmd() {
    (
        set -x
        "$@"
    )
}

declare -r DIR=$(dirname "$BASH_SOURCE")
if [[ $# -lt 1 || "$1" =~ \.s$ ]]; then
    TARGET=a.out
else
    TARGET=$1
    shift
fi
SRC_FILES=("${@-$DIR/example.s}")
OBJECTS=()
trap 'rm -f "${OBJECTS[@]}"' EXIT

for SRC in "${SRC_FILES[@]}"; do
    OBJECT=${SRC%.*}.o
    cmd as "$SRC" -o "$OBJECT"
    OBJECTS[${#OBJECTS[@]}]=$OBJECT
done
cmd ld -T "$DIR/hw3_part2.ld" "${OBJECTS[@]}" -o "$TARGET"
