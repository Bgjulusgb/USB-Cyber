#!/usr/bin/env bash
# arp-scan.sh - schneller LAN-Scan via ARP (findet auch Hosts mit Firewall)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

TARGET="${1:-}"
IFACE="${2:-}"
[[ -z "$TARGET" ]] && { echo "Usage: $0 <cidr> [iface]"; exit 1; }
require_auth "$TARGET"

require_bin arp-scan
outdir="$(make_outdir scans arp-${TARGET//[\/.]/_})"

args=()
[[ -n "$IFACE" ]] && args+=(-I "$IFACE")
log_info "arp-scan $TARGET"
sudo arp-scan "${args[@]}" "$TARGET" | tee "$outdir/results.txt"

log_ok "$outdir/results.txt"
