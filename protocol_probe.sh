#!/usr/bin/env bash
set -u

DEV="${1:-/dev/ttyUSB0}"
BAUD="${2:-115200}"
OUT="uart_probe_$(date +%Y%m%d_%H%M%S)"

PROBES=(00 55 AA FF 7F 20 0D 0A)

mkdir -p "$OUT"

[[ -e "$DEV" ]] || {
    echo "Device not found: $DEV"
    exit 1
}

echo "UART controlled probe"
echo "Device : $DEV"
echo "Baud   : $BAUD"
echo "Output : $OUT"
echo
echo "TX will be limited to ${#PROBES[@]} single-byte probes."
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

    cat "$tx" > "$DEV"

    timeout 0.25 dd if="$DEV" of="$rx" bs=1 \
        status=none 2>/dev/null || true

    bytes=$(wc -c < "$rx")

    if (( bytes )); then
        printf '[RX] %d bytes\n' "$bytes"
        xxd -g1 "$rx"
    else
        echo "[RX] none"
    fi

    echo
    sleep 0.2
done
