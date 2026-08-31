#!/usr/bin/env bash
# uart_charectorize.sh — passive UART framing/baud scanner
# Usage: ./uart_charectorize.sh [DEVICE] [SECONDS] [FORMATS]
# Example: ./uart_charectorize.sh /dev/ttyUSB0 3

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/defaults.conf" 2>/dev/null || true
source "$SCRIPT_DIR/lib/log.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib/analyze.sh" 2>/dev/null || true

usage() {
    cat <<EOF
Usage: $(basename "$0") [DEVICE] [SECONDS] [FORMATS]
  DEVICE     UART device (default: $DEFAULT_DEV)
  SECONDS    Duration per config (default: 3)
  FORMATS    Space-separated stty format strings (optional)

Safety: TX is NEVER used. Only passive receive.
Dependencies: stty, dd, timeout, xxd, tr, wc
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

DEV="${1:-$DEFAULT_DEV}"
SECONDS_TO_TEST="${2:-3}"
FORMATS=(${3:-"cs8 -parenb -cstopb" "cs8 parenb -cstopb" "cs8 parenb cstopb"})

[[ -e "$DEV" ]] || { echo "Device not found: $DEV"; exit 1; }
[[ "$SECONDS_TO_TEST" =~ ^[0-9]+$ ]] || { echo "Invalid seconds"; exit 1; }

OUT="uart_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

BAUDS=(1200 2400 4800 9600 19200 38400 57600 115200)

log_info "Passive framing scan start: $DEV duration=${SECONDS_TO_TEST}s"
echo "UART passive scanner"
echo "Device: $DEV"
echo "Duration: ${SECONDS_TO_TEST}s/configuration"
echo "Output: $OUT"
echo
echo "TX is NEVER used."
echo

score_file() {
    local f="$1"
    analyze_file "$f"
}

for baud in "${BAUDS[@]}"; do
    for fmt in "${FORMATS[@]}"; do
        tag="${baud}_$(echo "$fmt" | tr ' ' '_')"
        file="$OUT/${tag}.bin"

        echo "[*] $baud / $fmt"

        stty -F "$DEV" "$baud" $fmt \
            -ixon -ixoff -crtscts \
            -echo -icanon \
            min 0 time 1 2>/dev/null || {
                echo "    unable to configure"
                continue
            }

        # Flush pending input before each measurement.
        dd if="$DEV" of=/dev/null bs=4096 \
            iflag=nonblock status=none 2>/dev/null || true

        timeout "$SECONDS_TO_TEST" \
            dd if="$DEV" of="$file" bs=1 status=none \
            2>/dev/null || true

        bytes=$(wc -c < "$file")
        score=$(analyze_file "$file")

        if (( bytes > 0 )); then
            echo "    ${bytes} bytes, score=${score}"
            echo "    hex:"
            xxd -g1 -l32 "$file" | sed 's/^/      /'

            echo "    text:"
            LC_ALL=C tr -cd '[:print:][:space:]' < "$file" |
                head -c 100 |
                sed 's/^/      /'
            echo
        else
            echo "    no data"
        fi
    done
done

echo
echo "=== Candidate configurations ==="

for f in "$OUT"/*.bin; do
    [[ -s "$f" ]] || continue
    score=$(analyze_file "$f")
    bytes=$(wc -c < "$f")
    printf '%8s  score=%4s  %s\n' "$bytes" "$score" "$(basename "$f")"
done | sort -k2,2nr

echo
echo "Captures saved under: $OUT/"
log_info "Passive framing scan complete: $OUT"