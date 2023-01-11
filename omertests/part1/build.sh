#!/usr/bin/env bash

set -eu

declare -r SRC_FILE="$(dirname "$BASH_SOURCE")/hw3_part1.c"

set -x

gcc -std=c99 "$SRC_FILE" -o "${1-prf}"
