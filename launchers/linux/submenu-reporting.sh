#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/reporting"

while true; do
    CH="$(choose "Reporting" \
        "1:Sammel-Report (Markdown)" \
        "2:nmap XML -> HTML" \
        "3:Screenshots einsammeln" \
        "0:Zurueck")" || break

    case "$CH" in
        1) t=$(ask "Report-Titel:"); run_script "$S/gen-report.sh" "$t" ;;
        2) x=$(ask "Pfad zur nmap.xml:"); run_script "$S/nmap-to-html.sh" "$x" ;;
        3) s=$(ask "Source-Dir [Enter=~/Pictures]:")
           [[ -z "$s" ]] && s="$HOME/Pictures"
           run_script "$S/screenshot-collect.sh" "$s" ;;
        0|"") break ;;
    esac
done
