#!/usr/bin/env bash
# tests/test_log.sh — self-check logging
set -euo pipefail

source ../lib/log.sh

LOG_FILE=/tmp/test_log_$$.log
rm -f "$LOG_FILE"
log_info "test"
grep -q "test" "$LOG_FILE" || exit 1
echo "log tests OK"
