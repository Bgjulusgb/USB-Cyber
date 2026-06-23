#!/usr/bin/env bash
# wifi-scan.sh - passiver WLAN-Scan mit iw
# Listet sichtbare Netze + Signalstaerke. Kein Auth-Check, rein passiv.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

require_bin iw

IFACE="${1:-}"
if [[ -z "$IFACE" ]]; then
    log_info "Verfuegbare Interfaces:"
    iw dev | awk '$1=="Interface"{print "  " $2}'
    read -r -p "Interface fuer Scan: " IFACE
fi

[[ -n "$IFACE" ]] || { log_err "Kein Interface angegeben"; exit 1; }

outdir="$(make_outdir scans wifi)"
out="$outdir/scan-$(date +%H%M%S).txt"

log_info "Scanne mit $IFACE (Sudo ggf. erforderlich)"
sudo iw dev "$IFACE" scan \
    | awk '/^BSS / { bssid=$2; gsub(/\(.*/, "", bssid) }
           /signal:/ { signal=$2 }
           /SSID:/   { ssid=$0; sub(/^.*SSID: /, "", ssid);
                       printf "%-20s %-8s %s\n", bssid, signal, ssid }' \
    | sort -k2 -n -r \
    | tee "$out"

log_ok "Ergebnis: $out"
