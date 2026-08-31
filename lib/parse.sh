#!/usr/bin/env bash
# lib/parse.sh — parse hex/baud/config without hardware
# Usage: source lib/parse.sh; parse_hex "AA"; parse_baud 115200

parse_hex() {
    local h="$1"
    printf '%s' "$h" | tr -d '[:space:]' | grep -qE '^[0-9A-Fa-f]+$' || { echo "bad hex: $h"; return 1; }
    printf '%s' "$h"
}

parse_baud() {
    local b="$1"
    [[ "$b" =~ ^[0-9]+$ ]] || { echo "bad baud: $b"; return 1; }
    printf '%s' "$b"
}
