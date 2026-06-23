#!/usr/bin/env bash
# first-boot.sh - alles was nach dem ersten Kali-Boot zu tun ist in einem Rutsch
# - Locale auf de_DE
# - Tastatur DE
# - Zeitzone Europe/Berlin
# - apt update + full-upgrade
# - Standard-Tools nachinstallieren
# - 24h Uhrformat
# - HiDPI optional
set -uo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"

log_info "===== Kali First-Boot Setup ====="

log_info "1) Locale auf de_DE.UTF-8"
sudo localectl set-locale LANG=de_DE.UTF-8 || log_warn "localectl failed"

log_info "2) Tastaturlayout DE"
sudo localectl set-keymap de || log_warn "keymap failed"
sudo localectl set-x11-keymap de pc105 nodeadkeys || true

log_info "3) Zeitzone Europe/Berlin"
sudo timedatectl set-timezone Europe/Berlin

log_info "4) NTP an"
sudo timedatectl set-ntp true

log_info "5) apt update"
sudo apt update

log_info "6) apt full-upgrade -y"
sudo apt -y full-upgrade

log_info "7) Pflicht-Tools fuer das Toolkit"
sudo apt install -y \
    nmap masscan arp-scan \
    aircrack-ng wireshark \
    hashcat john hcxtools hcxdumptool \
    wordlists seclists \
    python3-yaml python3-pip pipx \
    whiptail dialog \
    macchanger \
    enum4linux-ng \
    bettercap responder \
    dislocker chntpw libimage-exiftool-perl \
    dnsmasq hostapd \
    cewl \
    impacket-scripts \
    || log_warn "Manche Pakete nicht installierbar (alt/neu Repo)"

log_info "8) pipx Tools (NetExec, name-that-hash, dpapick3)"
pipx ensurepath
pipx install netexec || true
pipx install name-that-hash || true
pipx install dpapick3 || true

log_info "9) HiDPI fragen"
read -r -p "HiDPI-Modus aktivieren? [y/N] " hidpi
if [[ "$hidpi" =~ ^[yYjJ]$ ]]; then
    if command -v kali-hidpi-mode >/dev/null 2>&1; then
        kali-hidpi-mode
    fi
fi

log_info "10) Toolkit-Auto-Mount in /etc/fstab eintragen (falls noch nicht)"
if ! grep -q 'LABEL=TOOLKIT' /etc/fstab; then
    echo 'LABEL=TOOLKIT /mnt/toolkit exfat defaults,uid=1000,gid=1000,nofail 0 0' | sudo tee -a /etc/fstab
    sudo mkdir -p /mnt/toolkit
    log_ok "fstab Eintrag hinzugefuegt"
fi

log_info "11) Toolkit-Bootstrap"
bash "$TOOLKIT/scripts/lib/bootstrap.sh"

log_info "12) Wordlists"
bash "$TOOLKIT/scripts/lib/manage-wordlists.sh" rockyou
bash "$TOOLKIT/scripts/lib/manage-wordlists.sh" seclists

log_info "13) Desktop-Launcher"
mkdir -p "$HOME/Desktop"
cp "$TOOLKIT/launchers/linux/pentest-menu.desktop" "$HOME/Desktop/" 2>/dev/null || true
chmod +x "$HOME/Desktop/pentest-menu.desktop" 2>/dev/null || true

log_info "14) ZSH-Aliase fuer Quick-Access"
bash "$TOOLKIT/scripts/kali-setup/install-aliases.sh"

log_ok "===== First-Boot Setup fertig ====="
log_info "Reboot empfohlen, dann 'pt' (alias) startet das Toolkit-Menue"
