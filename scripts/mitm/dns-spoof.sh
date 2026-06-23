#!/usr/bin/env bash
# dns-spoof.sh - dnsspoof via dnsmasq fuer kontrolliertes Test-Setup
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
NET_ID="${2:-}"
[[ -z "$IFACE" || -z "$NET_ID" ]] && {
    echo "Usage: $0 <iface> <network-id>"
    exit 1
}
require_auth "$NET_ID"
require_bin dnsmasq

outdir="$(make_outdir captures dnsspoof)"
hosts="$outdir/hosts.conf"

cat > "$hosts" <<EOF
# Beispiele - anpassen!
# 192.168.1.99 fake-bank.de
# 192.168.1.99 mail.eigenedomain.de
EOF

log_info "Bearbeite $hosts dann erneut starten"
${EDITOR:-nano} "$hosts"

log_info "Starte dnsmasq mit Spoof-Hosts"
sudo dnsmasq --no-daemon \
    --interface="$IFACE" \
    --bind-interfaces \
    --addn-hosts="$hosts" \
    --log-queries \
    --log-facility="$outdir/dnsmasq.log" 2>&1 | tee "$outdir/run.log"
