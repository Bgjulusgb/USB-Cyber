#!/usr/bin/env bash
# wifi-monitor-start.sh - Monitor-Mode aktivieren, MAC randomisieren
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

require_bin airmon-ng
require_bin ip

IFACE="${1:-}"
if [[ -z "$IFACE" ]]; then
    log_info "Verfuegbare Interfaces:"
    iw dev 2>/dev/null | awk '$1=="Interface"{print "  " $2}'
    read -r -p "Interface: " IFACE
fi
[[ -n "$IFACE" ]] || { log_err "Kein Interface"; exit 1; }

log_info "Toete blockierende Prozesse"
sudo airmon-ng check kill

log_info "Aktiviere monitor-mode auf $IFACE"
sudo airmon-ng start "$IFACE"

# airmon-ng nennt das Interface meist ifaceXmon oder mon0
MON_IFACE="$(iw dev | awk '/Interface/ && /mon/ {print $2; exit}')"
[[ -z "$MON_IFACE" ]] && MON_IFACE="${IFACE}mon"

if command -v macchanger >/dev/null 2>&1; then
    log_info "Randomisiere MAC auf $MON_IFACE"
    sudo ip link set "$MON_IFACE" down
    sudo macchanger -r "$MON_IFACE" || log_warn "macchanger failed"
    sudo ip link set "$MON_IFACE" up
else
    log_warn "macchanger nicht installiert - MAC bleibt original"
fi

log_ok "Monitor-Mode aktiv: $MON_IFACE"
echo
echo "Beenden mit:"
echo "  sudo airmon-ng stop $MON_IFACE && sudo systemctl start NetworkManager"
