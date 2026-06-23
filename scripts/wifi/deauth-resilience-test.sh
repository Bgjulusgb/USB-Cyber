#!/usr/bin/env bash
# deauth-resilience-test.sh - testet wie das eigene Netz auf deauth reagiert
# (Management-Frame-Protection / PMF aktiv?)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
BSSID="${2:-}"
COUNT="${3:-10}"
[[ -z "$IFACE" || -z "$BSSID" ]] && {
    echo "Usage: $0 <monitor_iface> <bssid> [count=10]"
    exit 1
}
require_auth "$BSSID"

require_bin aireplay-ng

log_info "Sende $COUNT deauths auf $BSSID"
log_info "Beobachte ob Clients tatsaechlich rausfliegen (=PMF aus)"

sudo aireplay-ng --deauth "$COUNT" -a "$BSSID" "$IFACE" 2>&1 | tee /tmp/deauth.log

if grep -q "no associated clients" /tmp/deauth.log; then
    log_warn "Keine assoziierten Clients - Test ohne Wirkung"
elif grep -q "Sending DeAuth" /tmp/deauth.log; then
    log_info "Frames gesendet. Pruefe ob Clients auf eigenem AP rausgefallen sind."
fi

echo
log_info "PMF/802.11w aktiv = Clients ignorieren deauth (gut!)"
log_info "PMF aus           = deauth wirkt = Netz vulnerable"
