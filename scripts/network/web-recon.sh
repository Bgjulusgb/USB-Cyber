#!/usr/bin/env bash
# web-recon.sh - subfinder -> httpx -> nuclei Chain
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

DOMAIN="${1:-}"
[[ -z "$DOMAIN" ]] && { echo "Usage: $0 <domain>"; exit 1; }
require_auth "$DOMAIN"

require_bin subfinder
require_bin httpx
require_bin nuclei

outdir="$(make_outdir scans webrecon-${DOMAIN})"
subs="$outdir/subdomains.txt"
alive="$outdir/alive.txt"
report="$outdir/nuclei.txt"

log_info "1/3 subfinder -d $DOMAIN"
subfinder -d "$DOMAIN" -silent > "$subs"
log_ok "$(wc -l < "$subs") Subdomains"

log_info "2/3 httpx probing"
httpx -l "$subs" -silent -title -tech-detect -status-code -o "$alive"
log_ok "$(wc -l < "$alive") alive"

log_info "3/3 nuclei (medium+)"
nuclei -l "$alive" \
    -severity medium,high,critical \
    -o "$report" \
    -j -je "$outdir/nuclei.jsonl" \
    || log_warn "nuclei exit non-zero"

log_ok "Report: $report"
log_ok "Output-Dir: $outdir"
