#!/usr/bin/env bash

set -eu

declare -r SRC_DIR="$(dirname "$BASH_SOURCE")"
declare -r SRC_FILE="$SRC_DIR/hw3_part1.c"
declare -r BUILD="$SRC_DIR/build.sh"
declare -r EXE="${1-./prf}"
declare -r WATCH_FILES=("$SRC_FILE" "$BUILD")

declare -r TEST_DIR="$SRC_DIR/test_files"
declare -r ELF_SRC_FILES=("$TEST_DIR/main.c" "$TEST_DIR/foo.c")
declare -r STATIC_ELF="$TEST_DIR/static"
declare -r SHARED_ELF="$TEST_DIR/shared"
declare -r STATIC_FLAGS=(-static)
declare -r SHARED_FLAGS=(-no-pie)
declare -r ELF_WATCH_FILES=("${ELF_SRC_FILES[@]}" "$BASH_SOURCE")

if [[ "$(uname -s)" == Darwin ]]; then
    declare -r STAT_ARGS=(-f '%m %N')
else
    declare -r STAT_ARGS=(-c '%Y %n')
fi

if [[ ! -f "$EXE" || $(stat "${STAT_ARGS[@]}" "$EXE" "${WATCH_FILES[@]}" | sort -n | tail -1 | awk '{ print $2 }') != "$EXE" ]]; then
    "$BUILD" "$EXE"
fi

fail() {
    echo "$0: '$EXE ${SYMBOL-something} ${ELF-${BAD_ELF-??}}' failed: $*" >&2
    false
}

indent() {
    local -r INDENT="$1"
    while read -r LINE; do
        echo "$INDENT$LINE"
    done
}

run() {
    (
        set -x
        "$@"
    )
}

build_elf() {
    local -n ELF=${1^^}_ELF
    local -n FLAGS=${1^^}_FLAGS

    if [[ ! -f "$ELF" || $(stat "${STAT_ARGS[@]}" "$ELF" "${ELF_WATCH_FILES[@]}" | sort -n | tail -1 | awk '{ print $2 }') != "$ELF" ]]; then
        run gcc -std=gnu99 ${FLAGS[@]} ${LINKFLAGS[@]} "${ELF_SRC_FILES[@]}" -o "$ELF"
    fi
}

show_var() {
    if [[ -v $1 ]]; then
        printf "%s=%s\n" $1 "${!1}"
    else
        printf '%s is unset\n' $1
    fi
}

show_array_values() {
    if [[ -v $1 ]]; then
        local -n ARR=$1
        printf "%s=(%s)\n" $1 "${ARR[*]}"
    else
        printf '%s is unset\n' $1
    fi
}

show_array() {
    local -n ARR=$1
    local REPR=""
    for IDX in "${!ARR[@]}"; do
        REPR+=" [$IDX]=${ARR[$IDX]}"
    done
    printf '%s=(%s)\n' $1 "$(tail -c +2 <<< $REPR)"
}

from_array() {
    local -n ARR=$1
    for KEY in "${!ARR[@]}"; do
        printf "['%s']='%s'\n" "$KEY" "${ARR[$KEY]}"
    done
}

declare -r NOT_ELF="not an executable"
declare -r NOT_GLOBAL="is not a global symbol"
declare -r NOT_FOUND="not found"
declare -r NOT_DEFINED="is a global symbol, but will come from a shared library"
declare -rA BAD_SYMBOLS=(
    [nope]="$NOT_FOUND"
    [local_func]="$NOT_GLOBAL"
    [local_bss_var]="$NOT_GLOBAL"
    [local_data_var]="$NOT_GLOBAL"
)
eval declare -rA BAD_STATIC_SYMBOLS=($(from_array BAD_SYMBOLS))
eval declare -rA BAD_SHARED_SYMBOLS=(
    $(from_array BAD_SYMBOLS)
    [printf@@GLIBC_2.2.5]="'$NOT_DEFINED'"
)
declare -r GOOD_SYMBOLS=(
    main
    global_func
    global_and_local_func
    global_bss_var
    global_data_var
    global_bss_and_local_bss_var
    global_bss_and_local_data_var
    global_data_and_local_bss_var
    global_data_and_local_data_var
)
declare -r GOOD_STATIC_SYMBOLS=("${GOOD_SYMBOLS[@]}" printf)
declare -r GOOD_SHARED_SYMBOLS=("${GOOD_SYMBOLS[@]}")

addressof() {
    local SYMBOL=$1
    local ELF=$2
    nm "$ELF" | grep -Fw "$SYMBOL" | grep -vE '[[:space:]]+[a-z][[:space:]]+' | awk '{ print $1 }'
}

load_message() {
    printf 'will be loaded to 0x%lx' 0x$(addressof "$@")
}

expect() {
    local SYMBOL=$1
    local ELF=$2
    local PATTERN=$3
    local OUTPUT=$(run "$EXE" "$SYMBOL" "$ELF")
    local -i LINES=$(wc -l <<< $OUTPUT)
    if (( LINES > 1 )); then
        fail "too much output:"$'\n'"$(indent '> ' <<< $OUTPUT)"
    elif ! grep -qP "$PATTERN" <<< $OUTPUT; then
        fail "expected output matcing '$PATTERN', actual: '$OUTPUT'"
    fi
}

check() {
    local LINKTYPE=$1
    local -n ELF=${1^^}_ELF
    local -n ELF_BAD_SYMBOLS=BAD_${1^^}_SYMBOLS
    local -n ELF_GOOD_SYMBOLS=GOOD_${1^^}_SYMBOLS

    build_elf $LINKTYPE

    for SYMBOL in "${!ELF_BAD_SYMBOLS[@]}"; do
        expect "$SYMBOL" "$ELF" "${ELF_BAD_SYMBOLS[$SYMBOL]}"
    done

    for SYMBOL in "${ELF_GOOD_SYMBOLS[@]}"; do
        expect "$SYMBOL" "$ELF" "$(load_message "$SYMBOL" "$ELF")"
    done
}

for BAD_ELF in "$BASH_SOURCE" /dev/null /dev/zero; do
    expect something "$BAD_ELF" "$NOT_ELF"
done

for LINKTYPE in static shared; do
    check $LINKTYPE
done

rm -f "$STATIC_ELF" "$SHARED_ELF" "$EXE"  # cleanup only if checks pass
echo "All tests passed"
