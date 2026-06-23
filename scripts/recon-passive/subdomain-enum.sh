#!/usr/bin/env bash
# subdomain-enum.sh - subfinder + amass passive
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

DOMAIN="${1:-}"
[[ -z "$DOMAIN" ]] && { echo "Usage: $0 <domain>"; exit 1; }

outdir="$(make_outdir scans subdomains-${DOMAIN})"

if command -v subfinder >/dev/null 2>&1; then
    log_info "subfinder"
    subfinder -d "$DOMAIN" -silent -all > "$outdir/subfinder.txt" || true
fi

if command -v amass >/dev/null 2>&1; then
    log_info "amass passive"
    amass enum -passive -d "$DOMAIN" -o "$outdir/amass.txt" || true
fi

cat "$outdir"/*.txt 2>/dev/null | sort -u > "$outdir/all-unique.txt"
log_ok "$(wc -l < "$outdir/all-unique.txt") unique Subdomains in $outdir/all-unique.txt"
