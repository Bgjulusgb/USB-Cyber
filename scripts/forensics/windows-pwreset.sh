#!/usr/bin/env bash
# windows-pwreset.sh - chntpw auf gemountete Windows-SAM
#
# Nur fuer eigene Geraete. Reset eines Admin-Passwortes per Live-Boot.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin chntpw

TARGET_ID="${1:-}"
WIN_MOUNT="${2:-}"

if [[ -z "$TARGET_ID" || -z "$WIN_MOUNT" ]]; then
    cat <<EOF
Usage: $0 <target-id> <windows-mount-point>

Beispiel:
  sudo mount /dev/nvme0n1p3 /mnt/win
  $0 own-laptop /mnt/win
EOF
    exit 1
fi

require_auth "$TARGET_ID"

SAM="$WIN_MOUNT/Windows/System32/config/SAM"
[[ -f "$SAM" ]] || { log_err "SAM nicht gefunden unter $SAM"; exit 1; }

# Backup
backup="$TOOLKIT/output/forensics/${TARGET_ID}-SAM-$(date +%Y%m%d-%H%M%S).bak"
mkdir -p "$(dirname "$backup")"
cp "$SAM" "$backup"
log_ok "SAM-Backup: $backup"

confirm_destructive "chntpw interaktiv auf $SAM starten?"
chntpw -i "$SAM"
log_warn "Reboot dann Windows. Backup liegt unter $backup falls Rollback noetig."
