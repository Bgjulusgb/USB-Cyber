#!/usr/bin/env bash
# osint-domain.sh - whois, DNS, certificate transparency, theHarvester
# Rein passiv, kein Auth-Gate.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

DOMAIN="${1:-}"
[[ -z "$DOMAIN" ]] && { echo "Usage: $0 <domain>"; exit 1; }

outdir="$(make_outdir scans osint-${DOMAIN})"

log_info "WHOIS"
whois "$DOMAIN" > "$outdir/whois.txt" 2>&1 || true

log_info "DNS"
{
    echo "=== A ==="
    dig +short A "$DOMAIN"
    echo "=== AAAA ==="
    dig +short AAAA "$DOMAIN"
    echo "=== MX ==="
    dig +short MX "$DOMAIN"
    echo "=== TXT ==="
    dig +short TXT "$DOMAIN"
    echo "=== NS ==="
    dig +short NS "$DOMAIN"
} > "$outdir/dns.txt"

log_info "Certificate Transparency (crt.sh)"
curl -s "https://crt.sh/?q=%25.${DOMAIN}&output=json" \
    | python3 -c 'import json,sys; [print(x["name_value"]) for x in json.load(sys.stdin)]' 2>/dev/null \
    | sort -u > "$outdir/crtsh.txt" || log_warn "crt.sh failed"

if command -v theHarvester >/dev/null 2>&1; then
    log_info "theHarvester"
    theHarvester -d "$DOMAIN" -b bing,duckduckgo,crtsh -f "$outdir/theharvester.html" \
        > "$outdir/theharvester.txt" 2>&1 || log_warn "theHarvester failed"
fi

log_ok "Output: $outdir"
