#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/recon-passive"

while true; do
    CH="$(choose "Passive Recon" \
        "1:Domain-OSINT (whois/DNS/crt.sh/theHarvester)" \
        "2:Email-Breach Check (HIBP)" \
        "3:Subdomain-Enumeration" \
        "0:Zurueck")" || break

    case "$CH" in
        1) d=$(ask "Domain:"); run_script "$S/osint-domain.sh" "$d" ;;
        2) e=$(ask "Email oder Datei:"); run_script "$S/osint-email.sh" "$e" ;;
        3) d=$(ask "Domain:"); run_script "$S/subdomain-enum.sh" "$d" ;;
        0|"") break ;;
    esac
done
