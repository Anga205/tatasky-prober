#!/usr/bin/env bash
set -euo pipefail

DEV="${1:-/dev/ttyUSB0}"
DURATION="${2:-5}"
BAUDS=(115200 57600 38400 19200 9600 4800 2400 1200)

command -v stty >/dev/null || { echo "stty not found"; exit 1; }
[[ -e "$DEV" ]] || { echo "Device $DEV not found"; exit 1; }

OUT="uart_probe_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

echo "Probing $DEV"
echo "Connect CP2102 GND to target GND."
echo "Do NOT connect CP2102 VCC until voltage compatibility is verified."
echo

for baud in "${BAUDS[@]}"; do
    echo "[*] Testing $baud baud..."

    stty -F "$DEV" "$baud" cs8 -cstopb -parenb \
        -ixon -ixoff -crtscts \
        -echo -icanon min 0 time 5

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