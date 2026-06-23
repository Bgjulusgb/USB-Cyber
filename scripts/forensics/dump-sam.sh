#!/usr/bin/env bash
# dump-sam.sh - SAM + SYSTEM Hives kopieren fuer Offline-Analyse
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

TARGET_ID="${1:-}"
WIN_MOUNT="${2:-}"

if [[ -z "$TARGET_ID" || -z "$WIN_MOUNT" ]]; then
    echo "Usage: $0 <target-id> <windows-mount-point>"
    exit 1
fi

require_auth "$TARGET_ID"

CONFIG="$WIN_MOUNT/Windows/System32/config"
[[ -d "$CONFIG" ]] || { log_err "Config-Dir fehlt: $CONFIG"; exit 1; }

outdir="$TOOLKIT/output/forensics/${TARGET_ID}-hives-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"

for hive in SAM SYSTEM SECURITY SOFTWARE; do
    if [[ -f "$CONFIG/$hive" ]]; then
        cp "$CONFIG/$hive" "$outdir/$hive"
        log_ok "$hive kopiert"
    else
        log_warn "$hive nicht gefunden"
    fi
done

log_info "Optional NTLM-Extraktion mit impacket secretsdump.py:"
echo "  impacket-secretsdump -sam $outdir/SAM -system $outdir/SYSTEM LOCAL"
log_ok "Output-Dir: $outdir"
