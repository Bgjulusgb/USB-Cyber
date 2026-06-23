#!/usr/bin/env bash
# evil-twin-setup.sh - NUR im dediziertem Lab. Setzt Rogue-AP via hostapd.
#
# Warn-Banner und doppelte Bestaetigung sind hier mit Absicht.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

cat <<'BANNER'
================================================================================
 EVIL-TWIN-SETUP

 Rogue Access Point in einem produktiven Netz ist in DE strafbar.

 Erlaubt NUR in:
   * isoliertem Lab (eigene HW, eigener Strom, Funk-faraday-tauglich)
   * autorisiertem Engagement mit explizitem Scope fuer Rogue-AP

 Dieses Script schreibt eine Audit-Eintrag und verlangt zweimal y.
================================================================================
BANNER

LAB_TARGET="${1:-}"
[[ -z "$LAB_TARGET" ]] && { echo "Usage: $0 <lab-identifier z.B. lab-rogue-ap>"; exit 1; }
require_auth "$LAB_TARGET"

confirm_destructive "Wirklich im isolierten Lab starten?"
confirm_destructive "Letzte Warnung - rogue AP starten?"

require_bin hostapd
require_bin dnsmasq

IFACE="${2:-wlan0}"
SSID="${3:-LabRogueAP}"
CHANNEL="${4:-6}"

outdir="$(make_outdir captures eviltwin-$LAB_TARGET)"
HOSTAPD_CONF="$outdir/hostapd.conf"
DNSMASQ_CONF="$outdir/dnsmasq.conf"

cat > "$HOSTAPD_CONF" <<EOF
interface=$IFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
auth_algs=1
ignore_broadcast_ssid=0
EOF

cat > "$DNSMASQ_CONF" <<EOF
interface=$IFACE
dhcp-range=10.0.0.10,10.0.0.50,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
log-dhcp
EOF

log_info "Stoppe NetworkManager"
sudo systemctl stop NetworkManager || true

log_info "Konfiguriere $IFACE"
sudo ip link set "$IFACE" down
sudo ip addr flush dev "$IFACE"
sudo ip link set "$IFACE" up
sudo ip addr add 10.0.0.1/24 dev "$IFACE"

log_info "Starte dnsmasq"
sudo dnsmasq -C "$DNSMASQ_CONF" -d &
DNSMASQ_PID=$!

log_info "Starte hostapd ($SSID auf $IFACE ch $CHANNEL)"
sudo hostapd "$HOSTAPD_CONF" &
HOSTAPD_PID=$!

cleanup() {
    log_info "Cleanup"
    sudo kill "$DNSMASQ_PID" "$HOSTAPD_PID" 2>/dev/null || true
    sudo ip addr flush dev "$IFACE" || true
    sudo systemctl start NetworkManager || true
}
trap cleanup EXIT INT TERM

log_ok "Rogue AP laeuft. Strg+C zum Beenden. Logs in $outdir"
wait
