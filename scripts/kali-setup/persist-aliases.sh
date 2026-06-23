#!/usr/bin/env bash
# persist-aliases.sh - in der Kali-Persistenz hinterlegen damit nach Reboot da
set -euo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"

# Aliase ins persistente Home (Persistence-Overlay)
bash "$TOOLKIT/scripts/kali-setup/install-aliases.sh"

# Autostart vom Hauptmenue beim Login (optional, deaktiviert per default)
read -r -p "Toolkit-Menue auto-starten beim Login? [y/N] " a
if [[ "$a" =~ ^[yYjJ]$ ]]; then
    autostart="$HOME/.config/autostart"
    mkdir -p "$autostart"
    cat > "$autostart/pentest-menu.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Pentest USB Toolkit
Exec=xfce4-terminal -e "bash $TOOLKIT/launchers/linux/pentest-menu.sh"
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    log_ok "Autostart aktiviert"
fi

log_ok "Persistence-Setup fertig"
