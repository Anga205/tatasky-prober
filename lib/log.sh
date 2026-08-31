#!/usr/bin/env bash
# lib/log.sh — timestamped logging with config context
# Usage: source lib/log.sh; log_info "msg"; log_tx "00"; log_rx 3

LOG_FILE="${LOG_FILE:-uart_investigate.log}"

log_info() {
    printf '%s [INFO] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

log_warn() {
    printf '%s [WARN] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

log_tx() {
    printf '%s [TX] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

log_rx() {
    printf '%s [RX] %s bytes\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}
