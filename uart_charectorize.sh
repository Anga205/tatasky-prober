#!/usr/bin/env bash
set -u

DEV="${1:-/dev/ttyUSB0}"
SECONDS_TO_TEST="${2:-3}"
OUT="uart_scan_$(date +%Y%m%d_%H%M%S)"

BAUDS=(1200 2400 4800 9600 19200 38400 57600 115200)
FORMATS=("cs8 -parenb -cstopb" "cs8 parenb -cstopb" "cs8 parenb cstopb")

[[ -e "$DEV" ]] || {
    echo "Device not found: $DEV"
    exit 1
}

mkdir -p "$OUT"

echo "UART passive scanner"
echo "Device: $DEV"
echo "Duration: ${SECONDS_TO_TEST}s/configuration"
echo "Output: $OUT"
echo
echo "TX is NEVER used."
echo

score_file() {
    local f="$1"
    local bytes printable nulls
    bytes=$(wc -c < "$f")

    (( bytes == 0 )) && {
        echo "0"
        return
    }

    printable=$(LC_ALL=C tr -cd '[:print:][:space:]' < "$f" | wc -c)
    nulls=$(LC_ALL=C tr -cd '\000' < "$f" | wc -c)

    echo $(( printable * 100 / bytes - nulls * 50 / bytes ))
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
        score=$(score_file "$file")

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

    score=$(score_file "$f")
    bytes=$(wc -c < "$f")

    printf '%8s  score=%4s  %s\n' "$bytes" "$score" "$(basename "$f")"
done | sort -k2,2nr

echo
echo "Captures saved under: $OUT/"