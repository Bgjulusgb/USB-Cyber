#!/usr/bin/env bash
# pcap-to-hashcat.sh - .pcap/.pcapng -> hashcat 22000 Format
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

require_bin hcxpcapngtool

PCAP="${1:-}"
[[ -f "$PCAP" ]] || { echo "Usage: $0 <pcap-file>"; exit 1; }

outdir="$TOOLKIT/output/handshakes"
mkdir -p "$outdir"
base="$(basename "$PCAP" | sed 's/\.[^.]*$//')"
out="$outdir/${base}.hc22000"

log_info "Konvertiere $PCAP -> $out"
hcxpcapngtool -o "$out" "$PCAP" || true

if [[ -s "$out" ]]; then
    log_ok "$out ($(wc -l < "$out") Hashes)"
    echo
    echo "Crack starten mit:"
    echo "  $TOOLKIT/scripts/hashcrack/crack-wpa.sh '$out'"
else
    log_err "Konvertierung leer - kein gueltiger Handshake im Capture?"
    rm -f "$out"
    exit 2
fi
