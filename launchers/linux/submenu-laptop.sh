#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/laptop-extract"

while true; do
    CH="$(choose "Laptop-Daten-Extract" \
        "W:WIZARD (kompletter Workflow)" \
        "M:Mount Partitionen automatisch" \
        "B:BitLocker entsperren" \
        "1:Credentials dump (SAM/Browser/WLAN)" \
        "2:User-Daten kopieren (Desktop/Docs)" \
        "3:Cred-Search (Files greppen)" \
        "4:SSH/PuTTY/GPG-Keys" \
        "5:Emails (Outlook/Thunderbird)" \
        "6:VM-Images" \
        "7:Volldokumenten-Scan" \
        "F:Forensisches Disk-Image (dd)" \
        "0:Zurueck")" || break

    case "$CH" in
        W) run_script "$TOOLKIT/scripts/wizards/laptop-extract-wizard.sh" ;;
        M) id=$(ask "Laptop-ID:"); mode=$(ask "ro oder rw [ro]:"); run_script "$S/mount-laptop.sh" "$id" "${mode:-ro}" ;;
        B) id=$(ask "Laptop-ID:"); dev=$(ask "Device (/dev/...):"); run_script "$S/unlock-bitlocker.sh" "$id" "$dev" ;;
        1) id=$(ask "Laptop-ID:"); win=$(ask "Windows-Mount:"); run_script "$S/dump-windows-creds.sh" "$id" "$win" ;;
        2) id=$(ask "Laptop-ID:"); root=$(ask "Mount-Root:"); run_script "$S/copy-user-data.sh" "$id" "$root" ;;
        3) id=$(ask "Laptop-ID:"); root=$(ask "Search-Root:"); run_script "$S/find-credentials.sh" "$id" "$root" ;;
        4) id=$(ask "Laptop-ID:"); root=$(ask "Search-Root:"); run_script "$S/copy-ssh-keys.sh" "$id" "$root" ;;
        5) id=$(ask "Laptop-ID:"); root=$(ask "Search-Root:"); run_script "$S/copy-emails.sh" "$id" "$root" ;;
        6) id=$(ask "Laptop-ID:"); root=$(ask "Search-Root:"); run_script "$S/copy-vm-images.sh" "$id" "$root" ;;
        7) id=$(ask "Laptop-ID:"); root=$(ask "Search-Root:"); kind=$(ask "Kind [docs+media]:"); run_script "$S/copy-documents.sh" "$id" "$root" "${kind:-docs+media}" ;;
        F) id=$(ask "Laptop-ID:"); dev=$(ask "Device (/dev/nvme0n1):"); run_script "$S/full-disk-image.sh" "$id" "$dev" ;;
        0|"") break ;;
    esac
done
