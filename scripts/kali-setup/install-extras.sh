#!/usr/bin/env bash
# install-extras.sh - optionale Tools nachinstallieren
set -euo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"

EXTRAS=(
    # Forensics
    sleuthkit autopsy
    testdisk gddrescue guymager
    libfvde libbde-utils
    foremost scalpel
    bulk-extractor
    # AD / Network
    bloodhound rdp-tools freerdp2-x11
    crackmapexec  # falls noch im Repo
    # Web
    burpsuite zaproxy
    sqlmap nikto whatweb
    gobuster ffuf wfuzz
    # Wireless
    wifite kismet
    pixiewps
    # Pwning
    metasploit-framework
    # Reporting
    pandoc
    # Komfort
    gparted exfatprogs
    htop iotop atop
    tmux
)

log_info "Installing extras (kann lange dauern)"
sudo apt install -y "${EXTRAS[@]}" || log_warn "Einige Pakete sind nicht in deiner Kali-Version"

log_ok "Extras-Install fertig"
