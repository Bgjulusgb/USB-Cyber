#!/usr/bin/env bash
# network-sniff.sh - tcpdump-Wrapper mit sinnvollen Defaults
# Erstellt pcap, rotiert nach Groesse, einfach mit wireshark zu oeffnen
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
TARGET="${2:-}"   # optional: BPF-Filter oder Target-IP
[[ -z "$IFACE" ]] && { echo "Usage: $0 <iface> [bpf-filter-or-ip]"; exit 1; }

[[ -n "$TARGET" ]] && require_auth "$TARGET"

require_bin tcpdump

outdir="$(make_outdir captures sniff-$IFACE)"
prefix="$outdir/dump"

filter="${TARGET:-not port 22 and not arp}"
log_info "tcpdump $IFACE [$filter] -> $prefix-*.pcap (rotation 100MB x 10)"

sudo tcpdump -i "$IFACE" -nn \
    -C 100 -W 10 -Z root \
    -w "${prefix}.pcap" \
    "$filter" 2>&1 | tee "$outdir/tcpdump.log"

log_ok "Output: $outdir"
echo
echo "Wireshark oeffnen:"
echo "  wireshark $outdir/dump.pcap"
