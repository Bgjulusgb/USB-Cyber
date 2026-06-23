#!/usr/bin/env bash
# wifite-auto.sh - wifite2 mit Auto-Filter auf authorisierte BSSIDs
# Ruft wifite mit --bssid Liste aus targets.yaml auf.
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
[[ -z "$IFACE" ]] && {
    echo "Usage: $0 <monitor_iface>"
    echo
    echo "wifite scannt und attackiert NUR die BSSIDs/SSIDs aus targets.yaml."
    exit 1
}

# Sammele alle BSSID-typischen Scopes
BSSIDS="$(grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$TOOLKIT/authorized-targets/targets.yaml" | sort -u)"
SSIDS="$(awk '/scope:/{print $2}' "$TOOLKIT/authorized-targets/targets.yaml" | grep -vE '/|\.|:' | sort -u)"

if [[ -z "$BSSIDS" && -z "$SSIDS" ]]; then
    log_err "Keine WiFi-Targets (BSSID/SSID) in targets.yaml"
    exit 1
fi

# Auth-Log Eintrag
require_auth "${BSSIDS:-$SSIDS}" 2>/dev/null || true

# wifite parameters
args=(-i "$IFACE" --kill --no-wps-only --random-mac --no-deauths)

if [[ -n "$BSSIDS" ]]; then
    while IFS= read -r b; do
        [[ -n "$b" ]] && args+=("--bssid" "$b")
    done <<< "$BSSIDS"
fi
if [[ -n "$SSIDS" ]]; then
    while IFS= read -r s; do
        [[ -n "$s" ]] && args+=("--essid" "$s")
    done <<< "$SSIDS"
fi

outdir="$(make_outdir captures wifite)"
cd "$outdir"

if command -v wifite >/dev/null 2>&1; then
    log_info "wifite ${args[*]}"
    sudo wifite "${args[@]}"
elif [[ -d "$TOOLKIT/repos/wifite2" ]]; then
    log_info "Starte wifite aus repo"
    cd "$TOOLKIT/repos/wifite2"
    sudo python3 Wifite.py "${args[@]}"
else
    log_err "wifite nicht installiert"
    log_warn "sudo apt install wifite  oder  Bootstrap re-run"
    exit 1
fi

log_ok "Ergebnisse in $outdir"
