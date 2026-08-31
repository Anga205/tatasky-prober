#!/usr/bin/env bash
# protocol_probe.sh — conservative single-byte TX probe
# Usage: ./protocol_probe.sh [DEVICE] [BAUD] [PROBE_LIST]
# Example: ./protocol_probe.sh /dev/ttyUSB0 115200 "00 55 AA"

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/defaults.conf" 2>/dev/null || true
source "$SCRIPT_DIR/lib/log.sh" 2>/dev/null || true

usage() {
    cat <<EOF
Usage: $(basename "$0") [DEVICE] [BAUD] [PROBE_LIST]
  DEVICE     UART device (default: $DEFAULT_DEV)
  BAUD       Baud rate (default: $DEFAULT_BAUD)
  PROBE_LIST Space-separated hex bytes (default: $DEFAULT_PROBE_BYTES)

Safety: TX is bounded to ${MAX_PROBE_BYTES} bytes. No destructive ops.
Dependencies: stty, dd, printf, xxd, date
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

DEV="${1:-$DEFAULT_DEV}"
BAUD="${2:-$DEFAULT_BAUD}"
PROBES=(${3:-$DEFAULT_PROBE_BYTES})

# Validation
command -v stty >/dev/null || { echo "stty missing"; exit 1; }
[[ -e "$DEV" ]] || { echo "Device not found: $DEV"; exit 1; }
[[ "$BAUD" =~ ^[0-9]+$ ]] || { echo "Invalid baud"; exit 1; }

if (( ${#PROBES[@]} > MAX_PROBE_BYTES )); then
    echo "Too many probes (${#PROBES[@]} > $MAX_PROBE_BYTES). Aborting."
    exit 1
fi

OUT="uart_probe_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

log_info "Controlled probe start: $DEV baud=$BAUD probes=${#PROBES[@]}"
echo "UART controlled probe"
echo "Device : $DEV"
echo "Baud   : $BAUD"
echo "Output : $OUT"
echo
echo "TX will be limited to ${#PROBES[@]} single-byte probes (max $MAX_PROBE_BYTES)."
echo

stty -F "$DEV" "$BAUD" cs8 -parenb -cstopb \
    -ixon -ixoff -crtscts \
    -echo -icanon min 0 time 1

for hex in "${PROBES[@]}"; do
    tx="$OUT/tx_${hex}.bin"
    rx="$OUT/rx_${hex}.bin"

    printf '\x%s' "$hex" > "$tx"

    dd if="$DEV" of=/dev/null bs=4096 \
        iflag=nonblock status=none 2>/dev/null || true

    printf '[TX] %s  ' "$hex"
    log_tx "$hex"

    cat "$tx" > "$DEV"

    timeout 0.25 dd if="$DEV" of="$rx" bs=1 \
        status=none 2>/dev/null || true

    bytes=$(wc -c < "$rx")

    if (( bytes )); then
        printf '[RX] %d bytes\n' "$bytes"
        log_rx "$bytes"
        xxd -g1 "$rx" || true
    else
        echo "[RX] none"
    fi

    echo
    sleep 0.2
done
