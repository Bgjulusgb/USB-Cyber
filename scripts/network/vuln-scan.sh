#!/usr/bin/env bash
# vuln-scan.sh - nmap --script vuln + optional nuclei
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin nmap

TARGET="${1:-}"
[[ -z "$TARGET" ]] && { echo "Usage: $0 <host-or-url>"; exit 1; }
require_auth "$TARGET"

safe_target="$(echo "$TARGET" | tr '/.:' '___')"
outdir="$(make_outdir scans vuln-${safe_target})"

log_info "nmap --script vuln auf $TARGET"
sudo nmap -sV --script vuln -oA "$outdir/nmap-vuln" "$TARGET" \
    | tee "$outdir/nmap-vuln.txt"

if command -v nuclei >/dev/null 2>&1; then
    log_info "Nuclei-Scan"
    nuclei -target "$TARGET" \
        -severity medium,high,critical \
        -o "$outdir/nuclei.txt" \
        -j -je "$outdir/nuclei.jsonl" \
        || log_warn "nuclei exit non-zero"
else
    log_warn "nuclei nicht installiert - skip"
fi

log_ok "Output: $outdir"
