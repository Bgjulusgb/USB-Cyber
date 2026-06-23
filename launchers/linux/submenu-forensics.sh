#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/forensics"

while true; do
    CH="$(choose "Forensics (eigene Geraete)" \
        "1:Windows Passwort-Reset (chntpw)" \
        "2:SAM/SYSTEM Hives dumpen" \
        "0:Zurueck")" || break

    case "$CH" in
        1) id=$(ask "Target-ID (muss in targets.yaml):")
           mp=$(ask "Windows Mount-Point (z.B. /mnt/win):")
           run_script "$S/windows-pwreset.sh" "$id" "$mp" ;;
        2) id=$(ask "Target-ID:")
           mp=$(ask "Windows Mount-Point:")
           run_script "$S/dump-sam.sh" "$id" "$mp" ;;
        0|"") break ;;
    esac
done
