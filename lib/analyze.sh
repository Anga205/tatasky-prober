#!/usr/bin/env bash
# lib/analyze.sh — conservative response analysis (no protocol claims)
# Usage: source lib/analyze.sh; analyze_file file.bin

analyze_file() {
    local f="$1"
    local bytes printable nulls score
    bytes=$(wc -c < "$f" 2>/dev/null || echo 0)
    (( bytes == 0 )) && { echo "0"; return; }
    printable=$(LC_ALL=C tr -cd '[:print:][:space:]' < "$f" 2>/dev/null | wc -c)
    nulls=$(LC_ALL=C tr -cd '\000' < "$f" 2>/dev/null | wc -c)
    score=$(( printable * 100 / bytes - nulls * 50 / bytes ))
    echo "$score"
}
