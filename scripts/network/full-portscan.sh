#!/usr/bin/env bash
# full-portscan.sh - nmap -sV -sC -p- mit Output-Dateien
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin nmap

TARGET="${1:-}"
[[ -z "$TARGET" ]] && { echo "Usage: $0 <host-or-range> [extra-nmap-args...]"; exit 1; }
shift || true

require_auth "$TARGET"

safe_target="$(echo "$TARGET" | tr '/.:' '___')"
outdir="$(make_outdir scans portscan-${safe_target})"

log_info "Full TCP portscan auf $TARGET"
sudo nmap -sV -sC -p- --min-rate 1000 --max-retries 2 \
    "$@" \
    -oA "$outdir/full" \
    "$TARGET" \
    | tee "$outdir/full.txt"

log_info "UDP top 100"
sudo nmap -sU --top-ports 100 -oA "$outdir/udp-top100" "$TARGET" \
    | tee "$outdir/udp.txt"

log_ok "Output: $outdir"
log_info "Naechste Schritte: vuln-scan.sh oder smb-enum.sh"
