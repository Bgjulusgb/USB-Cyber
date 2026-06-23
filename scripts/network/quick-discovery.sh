#!/usr/bin/env bash
# quick-discovery.sh - nmap subnet discovery (-sn)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin nmap

TARGET="${1:-}"
[[ -z "$TARGET" ]] && { echo "Usage: $0 <subnet>  e.g. 192.168.1.0/24"; exit 1; }

require_auth "$TARGET"

outdir="$(make_outdir scans discovery)"
log_info "Subnet-Discovery auf $TARGET"

sudo nmap -sn -PE -PP -PS80,443 -PA80,443 "$TARGET" \
    -oA "$outdir/discovery" \
    | tee "$outdir/discovery.txt"

log_ok "Ergebnis: $outdir/discovery.{txt,xml,nmap,gnmap}"
log_info "Naechster Schritt: full-portscan.sh fuer interessante Hosts"
