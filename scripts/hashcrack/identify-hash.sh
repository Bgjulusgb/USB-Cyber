#!/usr/bin/env bash
# identify-hash.sh - rate Hash-Typ mit name-that-hash oder hashid
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

INPUT="${1:-}"

read_hash() {
    if [[ -n "$INPUT" && -f "$INPUT" ]]; then
        cat "$INPUT"
    elif [[ -n "$INPUT" ]]; then
        printf '%s\n' "$INPUT"
    else
        echo "Hash eingeben (Strg-D zum Beenden):" >&2
        cat
    fi
}

HASH="$(read_hash)"

if command -v nth >/dev/null 2>&1; then
    log_info "name-that-hash:"
    printf '%s' "$HASH" | nth -g
elif command -v name-that-hash >/dev/null 2>&1; then
    printf '%s' "$HASH" | name-that-hash -g
elif [[ -d "$TOOLKIT/repos/name-that-hash" ]]; then
    python3 "$TOOLKIT/repos/name-that-hash/name_that_hash/runner.py" -g <<< "$HASH"
elif command -v hashid >/dev/null 2>&1; then
    log_info "hashid (fallback):"
    printf '%s' "$HASH" | hashid -m
else
    log_err "Weder nth/name-that-hash noch hashid installiert."
    log_warn "pip install name-that-hash  oder  apt install hashid"
    exit 1
fi
