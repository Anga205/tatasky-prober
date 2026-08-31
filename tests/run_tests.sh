#!/usr/bin/env bash
# tests/run_tests.sh — run all software-only tests
set -euo pipefail

cd "$(dirname "$0")"

for t in test_*.sh; do
    echo "=== $t ==="
    bash "$t"
done

echo "All software tests passed."
