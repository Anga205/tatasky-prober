# tatasky-prober -- UART Investigation Toolkit

A minimal, safe toolkit for characterizing unknown chips over UART using a CP2102 USB-to-UART adapter on vanilla Debian.

## Safety & Wiring Precautions

- **GND first**: Connect CP2102 GND to target GND before any other wire.
- **VCC never assumed**: Do NOT connect CP2102 VCC to the target until voltage compatibility is verified with a multimeter.
- **No destructive operations**: Scripts never flash, reset, or erase targets. All TX probes are bounded and configurable.
- **Conservative probing**: Only single-byte probes with configurable limits; no uncontrolled fuzzing.

## Dependencies

- `bash` (4+)
- `stty`, `dd`, `timeout`, `xxd`, `date`, `tr`, `wc`, `printf`
- Optional: `shellcheck` (for linting), `python3` (for extended analysis)

Install on Debian:
```bash
sudo apt update && sudo apt install coreutils binutils
```

## Directory Structure

```
.
├── config/defaults.conf      # Conservative defaults
├── lib/                      # Reusable helpers (log, parse, analyze)
├── tests/                    # Software-only self-checks
├── probe_uart.sh             # Passive baud scanning (no TX)
├── protocol_probe.sh         # Bounded single-byte TX probes
├── uart_charectorize.sh      # Passive framing/baud scanner
└── README.md                 # This file
```

## Usage Examples

```bash
# Passive scan with custom baud list
./probe_uart.sh /dev/ttyUSB0 5 "115200 9600 4800"

# Controlled probe with custom bytes (max 16)
./protocol_probe.sh /dev/ttyUSB0 115200 "00 55 AA FF"

# Framing scan with longer duration
./uart_charectorize.sh /dev/ttyUSB0 10

# Run software-only tests
bash tests/run_tests.sh
```

## Logging

All transmitted and received data is logged with timestamps and configuration context in `uart_investigate.log`. Each run creates a timestamped output directory (`uart_probe_YYYYMMDD_HHMMSS/`).
