#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/kali-setup"

while true; do
    CH="$(choose "Kali-Setup & Komfort" \
        "1:First-Boot Komplett-Setup (Locale, DE-Layout, Update, Tools)" \
        "2:Voll-Update (apt + pipx + bootstrap + nuclei)" \
        "3:Extras nachinstallieren (Burp, Bloodhound, MSF, ...)" \
        "4:HiDPI toggle (4k-Displays)" \
        "5:Undercover-Mode (Windows-Tarnung)" \
        "6:Aliase installieren (pt, wifiwiz, crack, ...)" \
        "0:Zurueck")" || break

    case "$CH" in
        1) run_script "$S/first-boot.sh" ;;
        2) run_script "$S/full-update.sh" ;;
        3) run_script "$S/install-extras.sh" ;;
        4) run_script "$S/hidpi-toggle.sh" ;;
        5) run_script "$S/undercover-toggle.sh" ;;
        6) run_script "$S/install-aliases.sh" ;;
        0|"") break ;;
    esac
done
