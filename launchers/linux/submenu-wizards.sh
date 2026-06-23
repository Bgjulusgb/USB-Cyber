#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/wizards"

while true; do
    CH="$(choose "WIZARDS (One-Shot Workflows)" \
        "1:WiFi-Audit (scan->capture->crack)" \
        "2:Laptop-Daten-Extract (alter Laptop)" \
        "3:Network-Pentest (discover->scan->vuln->report)" \
        "4:Crack-Anything (auto Hash-Detect)" \
        "5:Quick-WPA-Crack (interaktiv)" \
        "0:Zurueck")" || break

    case "$CH" in
        1) run_script "$S/wifi-audit-wizard.sh" ;;
        2) run_script "$S/laptop-extract-wizard.sh" ;;
        3) run_script "$S/network-pentest-wizard.sh" ;;
        4) h=$(ask "Hash oder Hash-File:"); run_script "$S/crack-anything.sh" "$h" ;;
        5) i=$(ask "Monitor-Interface:"); run_script "$TOOLKIT/scripts/wifi/wpa-quick-crack.sh" "$i" ;;
        0|"") break ;;
    esac
done
