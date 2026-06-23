#!/usr/bin/env bash
# laptop-extract-wizard.sh - kompletter Daten-Dump vom alten Laptop
# Live-boot Kali auf dem alten Laptop. Stick einstecken. Dieses Script starten.
set -uo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

log_info "===== Laptop Extract Wizard ====="
echo
echo "Voraussetzungen:"
echo "  1. Kali Live vom Stick AUF DEM ALTEN LAPTOP gebootet"
echo "  2. TOOLKIT-Stick hat genug Platz (df -h /mnt/toolkit)"
echo "  3. Laptop-ID in targets.yaml eingetragen"
echo
read -r -p "Laptop-ID aus targets.yaml: " LAPID
require_auth "$LAPID"

log_info "=== Schritt 1: Disks ==="
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL | grep -v loop

read -r -p "Alle Partitionen automatisch read-only mounten? [Y/n] " m
if [[ ! "$m" =~ ^[nN]$ ]]; then
    bash "$TOOLKIT/scripts/laptop-extract/mount-laptop.sh" "$LAPID" ro
fi

WIN=""
echo
read -r -p "Pfad zum Windows-Mount (z.B. /mnt/$LAPID/Windows) [Enter=skip]: " WIN

if [[ -n "$WIN" ]] && [[ ! -d "$WIN/Windows" ]]; then
    log_warn "Pfad enthaelt kein Windows-Profil. BitLocker entsperren?"
    read -r -p "Device fuer BitLocker (z.B. /dev/nvme0n1p3) [Enter=skip]: " bldev
    if [[ -n "$bldev" ]]; then
        bash "$TOOLKIT/scripts/laptop-extract/unlock-bitlocker.sh" "$LAPID" "$bldev"
        WIN="/mnt/${LAPID}-win"
    fi
fi

log_info "=== Schritt 2: Was extrahieren? ==="
cat <<EOF
  1) Credentials (SAM/SYSTEM/Browser/WLAN)
  2) User-Daten (Desktop/Docs/Downloads/Pics/Videos)
  3) Cred-Search (Dateien nach Passwords greppen)
  4) SSH/PuTTY-Keys + GnuPG
  5) Emails (Outlook/Thunderbird/AppleMail)
  6) VM-Images
  7) Dokumenten/Media-Scan rekursiv (gross!)
  8) Forensisches Vollabbild der Disk (sehr gross!)
  9) ALLE 1-5
EOF
read -r -p "Auswahl (mehrere mit Komma, z.B. 1,2,3): " sel

run_step() {
    case "$1" in
        1) [[ -n "$WIN" ]] && bash "$TOOLKIT/scripts/laptop-extract/dump-windows-creds.sh" "$LAPID" "$WIN" \
                            || log_warn "Schritt 1 ohne WIN-Pfad geskippt" ;;
        2) [[ -n "$WIN" ]] && bash "$TOOLKIT/scripts/laptop-extract/copy-user-data.sh" "$LAPID" "$WIN" \
                            || log_warn "Schritt 2 ohne WIN-Pfad geskippt" ;;
        3) read -r -p "Search-Root (z.B. /mnt/$LAPID): " root
           bash "$TOOLKIT/scripts/laptop-extract/find-credentials.sh" "$LAPID" "$root" ;;
        4) read -r -p "Search-Root: " root
           bash "$TOOLKIT/scripts/laptop-extract/copy-ssh-keys.sh" "$LAPID" "$root" ;;
        5) read -r -p "Search-Root: " root
           bash "$TOOLKIT/scripts/laptop-extract/copy-emails.sh" "$LAPID" "$root" ;;
        6) read -r -p "Search-Root: " root
           bash "$TOOLKIT/scripts/laptop-extract/copy-vm-images.sh" "$LAPID" "$root" ;;
        7) read -r -p "Search-Root: " root
           bash "$TOOLKIT/scripts/laptop-extract/copy-documents.sh" "$LAPID" "$root" ;;
        8) read -r -p "Device (z.B. /dev/nvme0n1): " dev
           bash "$TOOLKIT/scripts/laptop-extract/full-disk-image.sh" "$LAPID" "$dev" ;;
        9) for s in 1 2 3 4 5; do run_step "$s"; done ;;
    esac
}

IFS=',' read -ra steps <<< "$sel"
for s in "${steps[@]}"; do
    s="$(echo "$s" | tr -d ' ')"
    log_info "==> Schritt $s"
    run_step "$s"
done

# Hashes cracken anbieten
hashes="$(find "$TOOLKIT/output/laptop-extract" -name 'ntlm-hashes.txt' -newer "$TOOLKIT/authorized-targets/targets.yaml" 2>/dev/null | head -1)"
if [[ -n "$hashes" ]]; then
    read -r -p "NTLM-Hashes gefunden ($hashes) - jetzt cracken? [Y/n] " c
    if [[ ! "$c" =~ ^[nN]$ ]]; then
        bash "$TOOLKIT/scripts/hashcrack/crack-ntlm.sh" "$hashes"
    fi
fi

log_ok "Wizard fertig. Ergebnisse in $TOOLKIT/output/laptop-extract/"
