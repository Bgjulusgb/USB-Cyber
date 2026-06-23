#!/usr/bin/env bash
# unlock-bitlocker.sh - BitLocker-Partition mit Recovery-Key oder Passwort entsperren
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin dislocker

LAPTOP_ID="${1:-}"
DEV="${2:-}"

if [[ -z "$LAPTOP_ID" || -z "$DEV" ]]; then
    cat <<EOF
Usage: $0 <laptop-id> <device-path>

Beispiel:
  $0 old-thinkpad /dev/nvme0n1p3

Verlangt Recovery-Key (48 Ziffern) oder User-Passwort interaktiv.
EOF
    exit 1
fi

require_auth "$LAPTOP_ID"

unlocked="/mnt/${LAPTOP_ID}-bl"
mounted="/mnt/${LAPTOP_ID}-win"
sudo mkdir -p "$unlocked" "$mounted"

echo "Authentifizierung waehlen:"
echo "  1) Recovery-Key (48 Ziffern, Format XXXXXX-XXXXXX-...)"
echo "  2) Passwort"
echo "  3) BEK-File"
read -r -p "[1-3]: " choice

case "$choice" in
    1) read -r -p "Recovery-Key: " key
       sudo dislocker -r -V "$DEV" -p"$key" -- "$unlocked" ;;
    2) read -rs -p "BitLocker-Passwort: " pw; echo
       sudo dislocker -r -V "$DEV" -u"$pw" -- "$unlocked" ;;
    3) read -r -p "Pfad zur BEK-Datei: " bek
       sudo dislocker -r -V "$DEV" -f "$bek" -- "$unlocked" ;;
    *) log_err "Ungueltige Wahl"; exit 1 ;;
esac

log_ok "BitLocker entschluesselt -> $unlocked/dislocker-file"

sudo mount -o ro,loop "$unlocked/dislocker-file" "$mounted"
log_ok "Windows-Volume gemounted unter $mounted (read-only)"

echo
echo "Naechste Schritte:"
echo "  $TOOLKIT/scripts/laptop-extract/copy-user-data.sh '$LAPTOP_ID' '$mounted'"
echo "  $TOOLKIT/scripts/laptop-extract/dump-windows-creds.sh '$LAPTOP_ID' '$mounted'"
