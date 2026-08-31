#!/usr/bin/env bash
# probe_uart.sh — conservative passive UART scanning
# Usage: ./probe_uart.sh [DEVICE] [DURATION] [BAUD_LIST]
# Example: ./probe_uart.sh /dev/ttyUSB0 5 "115200 9600"

set -euo pipefail

# Source defaults and helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/defaults.conf" 2>/dev/null || true
source "$SCRIPT_DIR/lib/log.sh" 2>/dev/null || true

usage() {
    cat <<EOF
Usage: $(basename "$0") [DEVICE] [DURATION] [BAUD_LIST]
  DEVICE     UART device (default: $DEFAULT_DEV)
  DURATION   Seconds per baud (default: $DEFAULT_DURATION)
  BAUD_LIST  Space-separated baud rates (default: 115200 57600 ...)

Safety: TX is NEVER used. Only passive receive.
Dependencies: stty, dd, timeout, xxd, date
EOF
}

# Argument parsing with help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

DEV="${1:-$DEFAULT_DEV}"
DURATION="${2:-$DEFAULT_DURATION}"
BAUDS=(${3:-115200 57600 38400 19200 9600 4800 2400 1200})

command -v stty >/dev/null || { echo "stty missing"; exit 1; }
[[ -e "$DEV" ]] || { echo "Device $DEV not found"; exit 1; }
[[ "$DURATION" =~ ^[0-9]+$ ]] || { echo "Invalid duration"; exit 1; }

OUT="uart_probe_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

log_info "Passive scan start: $DEV duration=${DURATION}s"
echo "Probing $DEV (passive, no TX)"
echo "Connect CP2102 GND to target GND."
echo "Do NOT connect CP2102 VCC until voltage compatibility is verified."
echo

for baud in "${BAUDS[@]}"; do
    echo "[*] Testing $baud baud..."

    stty -F "$DEV" "$baud" cs8 -cstopb -parenb \
        -ixon -ixoff -crtscts -echo -icanon min 0 time 5 || {
        echo "    stty failed for $baud"
        continue
    }

    timeout "$DURATION" \
        dd if="$DEV" of="$OUT/${baud}.bin" bs=1 status=none \
        2>/dev/null || true

    if [[ -s "$OUT/${baud}.bin" ]]; then
        echo "    Activity detected:"
        xxd -g1 -l256 "$OUT/${baud}.bin"
    else
        echo "    No data"
    fi
done

echo
echo "Results saved in: $OUT/"
log_info "Passive scan complete: $OUT"