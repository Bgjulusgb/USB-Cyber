#!/usr/bin/env bash
# install-aliases.sh - bequeme Aliase + Funktionen in .zshrc/.bashrc
set -euo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"

ALIASES_FILE="$HOME/.toolkit-aliases.sh"
cat > "$ALIASES_FILE" <<'EOF'
# Pentest Toolkit Aliase - auto-generiert. Aenderungen in toolkit/scripts/kali-setup/.
export TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
export PATH="$TOOLKIT/scripts/lib:$PATH"

# Hauptmenue
alias pt='bash "$TOOLKIT/launchers/linux/pentest-menu.sh"'

# Targets
alias targets='${EDITOR:-nano} "$TOOLKIT/authorized-targets/targets.yaml"'
alias audit='tail -f "$TOOLKIT/output/audit.log"'

# WiFi
alias wifimon='bash "$TOOLKIT/scripts/wifi/wifi-monitor-start.sh"'
alias wifiscan='bash "$TOOLKIT/scripts/wifi/wifi-scan.sh"'
alias wifiwiz='bash "$TOOLKIT/scripts/wizards/wifi-audit-wizard.sh"'

# Network
alias discover='bash "$TOOLKIT/scripts/network/quick-discovery.sh"'
alias portscan='bash "$TOOLKIT/scripts/network/full-portscan.sh"'
alias arpscan='bash "$TOOLKIT/scripts/network/arp-scan.sh"'
alias routerscan='bash "$TOOLKIT/scripts/network/router-recon.sh"'
alias iotscan='bash "$TOOLKIT/scripts/network/iot-discovery.sh"'

# Cracking
alias crack='bash "$TOOLKIT/scripts/wizards/crack-anything.sh"'
alias hashid='bash "$TOOLKIT/scripts/hashcrack/identify-hash.sh"'

# Forensics / Laptop
alias laptopwiz='bash "$TOOLKIT/scripts/wizards/laptop-extract-wizard.sh"'
alias mountlap='bash "$TOOLKIT/scripts/laptop-extract/mount-laptop.sh"'
alias dumpcreds='bash "$TOOLKIT/scripts/laptop-extract/dump-windows-creds.sh"'

# MITM
alias sniff='bash "$TOOLKIT/scripts/mitm/network-sniff.sh"'
alias mitm='bash "$TOOLKIT/scripts/mitm/bettercap-quick.sh"'

# OSINT
alias osint='bash "$TOOLKIT/scripts/recon-passive/osint-domain.sh"'
alias subs='bash "$TOOLKIT/scripts/recon-passive/subdomain-enum.sh"'

# Report
alias report='bash "$TOOLKIT/scripts/reporting/gen-report.sh"'

# Quick-Update
alias ptupdate='bash "$TOOLKIT/scripts/lib/bootstrap.sh" && sudo apt update && sudo apt -y full-upgrade'

# Schnell ins Output / Toolkit
alias cdt='cd "$TOOLKIT"'
alias cdo='cd "$TOOLKIT/output"'

# Funktion: schnelles nmap mit Auth-Check
nm() {
    bash "$TOOLKIT/scripts/network/full-portscan.sh" "$@"
}

# Funktion: schnelles wget mit User-Agent
wg() {
    wget --user-agent='Mozilla/5.0' "$@"
}

# Funktion: random MAC fuer Interface
randmac() {
    sudo ip link set "$1" down
    sudo macchanger -r "$1"
    sudo ip link set "$1" up
}
EOF

# In .zshrc / .bashrc einbinden
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ -f "$rc" ]] || continue
    if ! grep -q 'toolkit-aliases.sh' "$rc"; then
        echo "[ -f \"\$HOME/.toolkit-aliases.sh\" ] && source \"\$HOME/.toolkit-aliases.sh\"" >> "$rc"
        echo "  -> $rc patched"
    fi
done

echo "[+] Aliase installiert in $ALIASES_FILE"
echo "    Neue Shell oeffnen oder 'source ~/.toolkit-aliases.sh'"
echo
echo "Kurzform:"
echo "  pt           -> Hauptmenue"
echo "  wifiwiz      -> WiFi-Wizard"
echo "  laptopwiz    -> Laptop-Daten-Wizard"
echo "  crack <file> -> Auto-Detect Hash und Crack"
echo "  targets      -> targets.yaml editieren"
echo "  audit        -> Audit-Log live"
