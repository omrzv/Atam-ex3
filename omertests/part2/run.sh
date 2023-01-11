#!/usr/bin/env bash

set -eu
set -o pipefail
set +o posix

shopt -s nullglob
shopt -s extglob

declare -rA EXPECTED_ADDRESS=(
    [.text]=0x0000000000400000
    [.data]=0x0000000000020000
    [.rodata]=0x0000000090000000
)
declare -rA EXPECTED_FLAGS=(
    [.text]=' WE'
    [.data]=' W '
    [.rodata]='R E'
)
declare -r EXPECTED_ENTRYPOINT=_hw3_dance
declare -r EXPECTED_UNDEF_SYMBOLS=(
    blacks
    greens
)
declare -r EXPECTED_SYMBOLS=(
    "$EXPECTED_ENTRYPOINT"
    "${EXPECTED_UNDEF_SYMBOLS[@]}"
)

declare -r SRC_DIR="$(dirname "$BASH_SOURCE")"
declare -r DEFAULT_FILE="$SRC_DIR/example.s"

if [[ $# -gt 1 || ! -e "${1-$DEFAULT_FILE}" ]]; then
    echo "usage: $0 [TEST]" >&2
    echo >&2
    echo "Run a single test, TEST can be either a single file or a directory with files in it" >&2
    exit 2
fi

if [[ $# -eq 0 || -f "$1" ]]; then
    declare -r SRC_FILES=("${1-$DEFAULT_FILE}")
    declare -r EXE="$(basename "${SRC_FILES[0]%.*}").out"
elif [[ -d "$1" ]]; then
    declare -r SRC_FILES=("$1"/*)
    declare -r EXE="$(basename "${1%.s}").out"
fi

declare -r LD_FILE="$SRC_DIR/hw3_part2.ld"
declare -r BUILD="$SRC_DIR/build.sh"
declare -r WATCH_FILES=("${SRC_FILES[0]}" "$LD_FILE" "$BUILD")

echo "${1-$DEFAULT_FILE}"

if [[ "$(uname -s)" == Darwin ]]; then
    declare -r STAT_ARGS=(-f '%m %N')
else
    declare -r STAT_ARGS=(-c '%Y %n')
fi

if [[ ! -f "$EXE" || $(stat "${STAT_ARGS[@]}" "$EXE" "${WATCH_FILES[@]}" | sort -n | tail -1 | awk '{ print $2 }') != "$EXE" ]]; then
    "$BUILD" "$EXE" "${SRC_FILES[@]}"
fi

readelf() {
    command readelf "$@" "$EXE"
}

fail() {
    echo "$0: '$EXE' failed: $*" >&2
    false
}

check() {
    unset FUNCNAME
    echo ${!ALL_*}
    echo ${!F*}
    echo ${!SEGMENT*}
}

# usage: append ARRAY VALUE
append() {
    local -n ARR=$1
    ARR[${#ARR[@]}]=$2
}

grep_for_all() {
    local WORDS=()
    while (( $# > 0 )); do
        append WORDS -e
        append WORDS "$1"
        shift
    done
    [[ ${#WORDS[@]} -gt 0 ]] && grep -Fw "${WORDS[@]}"
}

parse_program_headers() {
    local ALL_VIRT_ADDRS=()
    local ALL_PHYS_ADDRS=()
    local ALL_FLAGS=()

    while read _ OFFSET VIRT_ADDR PHYS_ADDR; do
        read FILE_SIZE MEM_SIZE FLAGS
        FLAGS=$(sed -r 's/^\s*?([R ][W ][E ])\s+.*$/\1/' <<< "  ${FLAGS%0x*}")
        append ALL_VIRT_ADDRS $VIRT_ADDR
        append ALL_PHYS_ADDRS $PHYS_ADDR
        append ALL_FLAGS "$FLAGS"
    done <<< $( readelf -l | grep -A 1 -Fw LOAD )

    declare -gA SEGMENT_IDX
    declare -ga ALL_SEGMENTS
    while read IDX SEGMENT; do
        [[ -z "$SEGMENT" ]] && continue
        SEGMENT_IDX[$SEGMENT]=$IDX
        ALL_SEGMENTS[$IDX]=$SEGMENT
    done <<< $( readelf -l | grep -E '^[[:space:]]*[[:digit:]]+[[:space:]]+[.[:alnum:]]+[[:space:]]*$' )

    declare -gA SEGMENT_VIRT_ADDR
    declare -gA SEGMENT_PHYS_ADDR
    declare -gA SEGMENT_FLAGS
    for SEGMENT in "${!SEGMENT_IDX[@]}"; do
        SEGMENT_VIRT_ADDR[$SEGMENT]=${ALL_VIRT_ADDRS[${SEGMENT_IDX[$SEGMENT]}]}
        SEGMENT_PHYS_ADDR[$SEGMENT]=${ALL_PHYS_ADDRS[${SEGMENT_IDX[$SEGMENT]}]}
        SEGMENT_FLAGS[$SEGMENT]=${ALL_FLAGS[${SEGMENT_IDX[$SEGMENT]}]}
    done

    declare -g ENTRYPOINT=$(readelf -l | grep -F "Entry point" | grep -oP '0x[a-fA-F0-9]+')
}

parse_symbols() {
    declare -gA SYMBOL_VALUE
    declare -gA SYMBOL_NDX
    while read _ VALUE _ _ _ _ NDX NAME; do
        SYMBOL_VALUE[$NAME]=$VALUE
        SYMBOL_NDX[$NAME]=$NDX
    done <<< $( readelf -s | grep_for_all "${EXPECTED_SYMBOLS[@]}" )
}

parse_program_headers
parse_symbols
# check

if [[ "${ALL_SEGMENTS[*]}" =~ .bss ]]; then
    fail "enexpected segment '.bss' (expected only '.data')"
fi

for SEGMENT in "${!EXPECTED_ADDRESS[@]}"; do
    if [[ ! -v SEGMENT_VIRT_ADDR[$SEGMENT] ]]; then
        # fail "missing segment '${SEGMENT}'"
        continue
    fi

    if [[ "${SEGMENT_VIRT_ADDR[$SEGMENT]}" != "${EXPECTED_ADDRESS[$SEGMENT]}" ]]; then
        fail "unexpected virtual address for '$SEGMENT' (got ${SEGMENT_VIRT_ADDR[$SEGMENT]}, expected ${EXPECTED_ADDRESS[$SEGMENT]})"
    fi

    if [[ "${SEGMENT_PHYS_ADDR[$SEGMENT]}" != "${EXPECTED_ADDRESS[$SEGMENT]}" ]]; then
        fail "unexpected physical address for '$SEGMENT' (got ${SEGMENT_PHYS_ADDR[$SEGMENT]}, expected ${EXPECTED_ADDRESS[$SEGMENT]})"
    fi

    if [[ "${SEGMENT_FLAGS[$SEGMENT]}" != "${EXPECTED_FLAGS[$SEGMENT]}" ]]; then
        fail "unexpected flags for '$SEGMENT' (got ${SEGMENT_FLAGS[$SEGMENT]}, expected ${EXPECTED_FLAGS[$SEGMENT]})"
    fi
done

for SYMBOL in "${EXPECTED_SYMBOLS[@]}"; do
    if [[ ! -v SYMBOL_NDX[$SYMBOL] ]]; then
        fail "missing symbol '${SYMBOL}'"
    fi

    if [[ "${EXPECTED_UNDEF_SYMBOLS[*]}" =~ "$SYMBOL" ]]; then
        if [[ "${SYMBOL_NDX[$SYMBOL]}" != UND ]]; then
            fail "unexpected ndx for '$SYMBOL' (got ${SYMBOL_NDX[$SYMBOL]}, expected UND)"
        fi
    else
        if [[ "${SYMBOL_NDX[$SYMBOL]}" == UND ]]; then
            fail "unexpected ndx for '$SYMBOL' (got UND, expected defined)"
        fi
    fi
done

if [[ "${SYMBOL_VALUE[$EXPECTED_ENTRYPOINT]##+(0)}" != "${ENTRYPOINT##0x*(0)}" ]]; then
    fail "unexpected entrypoint (got $ENTRYPOINT, expected $EXPECTED_ENTRYPOINT which is 0x${SYMBOL_VALUE[$EXPECTED_ENTRYPOINT]##+(0)})"
fi

# if ! [[ "${SEGMENT_FLAGS[${ALL_SEGMENTS[${SYMBOL_NDX[$EXPECTED_ENTRYPOINT]}]}]}" =~ E ]]; then
#     fail "entrypoint is in ${ALL_SEGMENTS[${SYMBOL_NDX[$EXPECTED_ENTRYPOINT]}]} which is not executable (flags: ${SEGMENT_FLAGS[${ALL_SEGMENTS[${SYMBOL_NDX[$EXPECTED_ENTRYPOINT]}]}]})"
# fi

rm -f "$EXE"  # cleanup only if checks pass
echo "${1-$DEFAULT_FILE}: PASS"
