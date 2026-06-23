#!/usr/bin/env bash
# router-recon.sh - Vollanalyse des eigenen Routers
# nmap-os, nmap-ports, http-fingerprint, snmp, upnp
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

ROUTER="${1:-}"
[[ -z "$ROUTER" ]] && {
    ROUTER="$(ip route | awk '/default/{print $3; exit}')"
    log_info "Auto-Detect Gateway: $ROUTER"
}
[[ -z "$ROUTER" ]] && { echo "Usage: $0 [router-ip]"; exit 1; }
require_auth "$ROUTER"

outdir="$(make_outdir scans router-recon-$ROUTER)"

log_info "nmap top 200 + service + OS"
sudo nmap -sS -sV -O --top-ports 200 -T4 "$ROUTER" -oA "$outdir/nmap" | tee "$outdir/nmap.txt"

log_info "HTTP-Banner"
for port in 80 443 8080 8443; do
    code="$(curl -ks -o /dev/null -w 'http%{ssl}/%{http_code} %{url_effective}' --max-time 4 "http://$ROUTER:$port")"
    echo "  port $port: $code" >> "$outdir/http.txt"
done
log_info "HTTPS-Banner"
echo | openssl s_client -connect "$ROUTER:443" -servername "$ROUTER" 2>/dev/null | \
    openssl x509 -text -noout > "$outdir/cert.txt" 2>/dev/null || true

log_info "SNMP v1/2c public/private"
for comm in public private admin; do
    snmpwalk -v 2c -c "$comm" -t 2 "$ROUTER" sysDescr.0 2>>"$outdir/snmp-errors.log" \
        >> "$outdir/snmp.txt" 2>/dev/null || true
done

log_info "UPnP"
if command -v upnpc >/dev/null 2>&1; then
    upnpc -l > "$outdir/upnp.txt" 2>&1 || true
fi

log_info "WPS-Info auf WiFi (wenn moeglich)"
if command -v wash >/dev/null 2>&1; then
    log_warn "wash braucht Monitor-Interface, hier skipped"
fi

log_info "nuclei: web technologies + CVEs"
if command -v nuclei >/dev/null 2>&1; then
    nuclei -target "http://$ROUTER" -severity medium,high,critical \
        -o "$outdir/nuclei.txt" 2>&1 | tail -10 || true
fi

log_ok "$outdir"
