#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/network"

while true; do
    CH="$(choose "Network Scans" \
        "1:Quick Discovery (nmap -sn)" \
        "2:Full Portscan (nmap -sV -sC -p-)" \
        "3:Vuln Scan (nmap+nuclei)" \
        "4:Web Recon (subfinder->httpx->nuclei)" \
        "5:SMB Enum (enum4linux+netexec)" \
        "0:Zurueck")" || break

    case "$CH" in
        1) t=$(ask "Subnet (z.B. 192.168.1.0/24):"); run_script "$S/quick-discovery.sh" "$t" ;;
        2) t=$(ask "Host/CIDR:"); run_script "$S/full-portscan.sh" "$t" ;;
        3) t=$(ask "Host/URL:"); run_script "$S/vuln-scan.sh" "$t" ;;
        4) t=$(ask "Domain:"); run_script "$S/web-recon.sh" "$t" ;;
        5) t=$(ask "Host/CIDR:"); run_script "$S/smb-enum.sh" "$t" ;;
        0|"") break ;;
    esac
done
