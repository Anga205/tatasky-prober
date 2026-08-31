#!/usr/bin/env bash
# tests/test_parse.sh — self-check parsing without hardware
set -euo pipefail

source ../lib/parse.sh

parse_hex "AA" || exit 1
parse_hex "00" || exit 1
parse_hex "bad" && exit 1 || true
parse_baud 115200 || exit 1
parse_baud 99999 || exit 1

echo "parse tests OK"
