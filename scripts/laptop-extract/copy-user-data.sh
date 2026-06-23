#!/usr/bin/env bash
# copy-user-data.sh - alle User-Daten von gemountetem Windows/Linux nach Toolkit kopieren
# Mit rsync, fortsetzbar, mit Fortschrittsanzeige.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

require_bin rsync

LAPTOP_ID="${1:-}"
MOUNT="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$MOUNT" ]] && {
    echo "Usage: $0 <laptop-id> <mount-point>"
    echo "Beispiel: $0 old-thinkpad /mnt/old-thinkpad/Windows"
    exit 1
}

require_auth "$LAPTOP_ID"

[[ -d "$MOUNT" ]] || { log_err "Mount-Pfad fehlt: $MOUNT"; exit 1; }

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-userdata-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"
LOG="$outdir/copy.log"

run_rsync() {
    local src="$1" dst="$2" label="$3"
    [[ -d "$src" ]] || return 0
    log_info "Kopiere $label  ($src -> $dst)"
    mkdir -p "$dst"
    rsync -av --info=progress2 \
        --exclude='*.tmp' \
        --exclude='Temp/' --exclude='Temporary Internet Files/' \
        --exclude='Caches/' --exclude='.cache/' \
        --exclude='Recycle.Bin/' \
        "$src/" "$dst/" 2>&1 | tee -a "$LOG" || log_warn "$label: rsync exit non-zero"
    log_ok "$label fertig"
}

# Windows Users-Profil
if [[ -d "$MOUNT/Users" ]]; then
    for user_dir in "$MOUNT/Users"/*; do
        [[ -d "$user_dir" ]] || continue
        user="$(basename "$user_dir")"
        case "$user" in
            "All Users"|"Default"|"Default User"|"Public"|"WDAGUtilityAccount") continue ;;
        esac
        log_info "===== Windows-User: $user ====="
        user_out="$outdir/users/$user"

        run_rsync "$user_dir/Desktop"   "$user_out/Desktop"   "Desktop"
        run_rsync "$user_dir/Documents" "$user_out/Documents" "Dokumente"
        run_rsync "$user_dir/Downloads" "$user_out/Downloads" "Downloads"
        run_rsync "$user_dir/Pictures"  "$user_out/Pictures"  "Bilder"
        run_rsync "$user_dir/Videos"    "$user_out/Videos"    "Videos"
        run_rsync "$user_dir/Music"     "$user_out/Music"     "Musik"
        run_rsync "$user_dir/Favorites" "$user_out/Favorites" "IE-Favorites"
        run_rsync "$user_dir/Contacts"  "$user_out/Contacts"  "Kontakte"

        # OneDrive lokaler Cache
        for od in "$user_dir/OneDrive"*; do
            [[ -d "$od" ]] && run_rsync "$od" "$user_out/$(basename "$od")" "OneDrive-Cache"
        done

        # AppData wichtige Teile (Email, Sticky Notes, Game Saves)
        for app in Roaming/Microsoft/Outlook Roaming/Microsoft/Signatures \
                   Roaming/Thunderbird Roaming/Mozilla/Firefox/Profiles \
                   Local/Microsoft/Outlook Local/Google/Chrome/User\ Data; do
            run_rsync "$user_dir/AppData/$app" "$user_out/AppData/$app" "AppData/$app"
        done
    done
fi

# Linux /home
if [[ -d "$MOUNT/home" ]]; then
    for hd in "$MOUNT/home"/*; do
        [[ -d "$hd" ]] || continue
        user="$(basename "$hd")"
        log_info "===== Linux-User: $user ====="
        out_user="$outdir/linux-home/$user"

        run_rsync "$hd/Desktop"   "$out_user/Desktop"   "Desktop"
        run_rsync "$hd/Documents" "$out_user/Documents" "Documents"
        run_rsync "$hd/Downloads" "$out_user/Downloads" "Downloads"
        run_rsync "$hd/Pictures"  "$out_user/Pictures"  "Pictures"
        run_rsync "$hd/Videos"    "$out_user/Videos"    "Videos"

        # Configs / Dotfiles selektiv
        for cfg in .ssh .gnupg .mozilla .config/google-chrome .config/chromium \
                   .thunderbird .bashrc .zshrc .gitconfig; do
            [[ -e "$hd/$cfg" ]] && run_rsync "$hd/$cfg" "$out_user/$cfg" ".$cfg"
        done
    done
fi

du -sh "$outdir" | tee -a "$LOG"
log_ok "Output: $outdir"
log_ok "Log:    $LOG"
