#!/usr/bin/env bash
# tests/test_analyze.sh — self-check analysis without hardware
set -euo pipefail

source ../lib/analyze.sh

# Empty file
: > /tmp/empty.bin
[[ $(analyze_file /tmp/empty.bin) == "0" ]] || exit 1

# Printable only
printf 'hello\n' > /tmp/hello.bin
[[ $(analyze_file /tmp/hello.bin) -gt 0 ]] || exit 1

echo "analyze tests OK"
