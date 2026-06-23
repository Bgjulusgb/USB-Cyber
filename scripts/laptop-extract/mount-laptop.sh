#!/usr/bin/env bash
# mount-laptop.sh - findet und mountet alle Partitionen des alten Laptops
# Read-only standardmaessig, optional rw.
#
# Auth-Gate: Laptop-ID muss in targets.yaml. Nur eigene Geraete.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
MODE="${2:-ro}"   # ro | rw

if [[ -z "$LAPTOP_ID" ]]; then
    cat <<EOF
Usage: $0 <laptop-id> [ro|rw]

Beispiel:
  $0 old-thinkpad ro

ro = read-only (empfohlen fuer Forensik / Datenkopie)
rw = read-write (z.B. fuer chntpw Passwort-Reset)
EOF
    exit 1
fi

require_auth "$LAPTOP_ID"

log_info "Suche Partitionen auf angeschlossenen Disks..."
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT,TYPE | grep -E 'part|disk'

mount_base="/mnt/$LAPTOP_ID"
sudo mkdir -p "$mount_base"

while IFS= read -r line; do
    dev="$(echo "$line" | awk '{print $1}')"
    fstype="$(echo "$line" | awk '{print $3}')"
    label="$(echo "$line" | awk '{print $4}')"
    [[ -z "$fstype" || "$fstype" == "swap" ]] && continue

    # Toolkit-USB ueberspringen
    if echo "$label" | grep -qE 'TOOLKIT|persistence|KALI'; then
        log_info "Skip Toolkit/Persistence: $dev ($label)"
        continue
    fi

    name="${label:-$dev}"
    target="$mount_base/$name"
    sudo mkdir -p "$target"

    opts="$MODE"
    case "$fstype" in
        ntfs|ntfs3) opts="$MODE,uid=1000,gid=1000,umask=022" ;;
        vfat|exfat) opts="$MODE,uid=1000,gid=1000" ;;
        ext2|ext3|ext4|xfs|btrfs) opts="$MODE" ;;
        *) log_warn "Unbekanntes FS $fstype auf $dev"; continue ;;
    esac

    log_info "Mount $dev ($fstype) -> $target [$opts]"
    if sudo mount -o "$opts" "/dev/$dev" "$target" 2>/dev/null; then
        log_ok  "$target"
    else
        log_warn "Mount failed: $dev (BitLocker? LUKS? Defekt?)"
        # BitLocker-Check
        if sudo blkid "/dev/$dev" 2>/dev/null | grep -qi bitlocker; then
            log_warn "  -> BitLocker erkannt. Nutze unlock-bitlocker.sh mit Recovery-Key"
        fi
    fi
done < <(lsblk -ln -o NAME,SIZE,FSTYPE,LABEL | grep -E '^(sd|nvme|mmcblk)[a-z0-9]+p[0-9]+|^(sd[a-z])[0-9]+')

log_ok "Mount-Pfade unter $mount_base/"
ls -la "$mount_base"
