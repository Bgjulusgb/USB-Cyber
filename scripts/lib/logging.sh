#!/usr/bin/env bash
# logging.sh - einfaches Logging fuer alle Scripts
#
# Usage:
#   source "$TOOLKIT/scripts/lib/logging.sh"
#   log_info "Starte scan"
#   log_warn "Adapter nicht im monitor-mode"
#   log_err  "nmap not found"

set -u

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
LOG_DIR="${LOG_DIR:-$TOOLKIT/output}"
mkdir -p "$LOG_DIR"

_log_ts() { date +'%Y-%m-%dT%H:%M:%S%z'; }

log_info() { printf '\033[36m[%s] [INF] %s\033[0m\n' "$(_log_ts)" "$*"; }
log_warn() { printf '\033[33m[%s] [WRN] %s\033[0m\n' "$(_log_ts)" "$*" >&2; }
log_err()  { printf '\033[31m[%s] [ERR] %s\033[0m\n' "$(_log_ts)" "$*" >&2; }
log_ok()   { printf '\033[32m[%s] [OK ] %s\033[0m\n' "$(_log_ts)" "$*"; }

# Verlange ein Binary, sonst exit
require_bin() {
    local bin="$1"
    if ! command -v "$bin" >/dev/null 2>&1; then
        log_err "Binary '$bin' nicht gefunden. Installiere es oder pruefe \$PATH."
        exit 127
    fi
}

# Erstelle Output-Dir mit Zeitstempel und gib den Pfad zurueck
make_outdir() {
    local subdir="${1:-misc}"
    local target_id="${2:-run}"
    local outdir="$TOOLKIT/output/$subdir/${target_id}_$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$outdir"
    echo "$outdir"
}
