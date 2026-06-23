#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/network"

while true; do
    CH="$(choose "Network Scans" \
        "W:WIZARD (discover->scan->vuln->report)" \
        "1:Quick Discovery (nmap -sn)" \
        "2:ARP-Scan (LAN-only, sehr schnell)" \
        "3:Masscan (extrem schnell, grosses Range)" \
        "4:Full Portscan (nmap -sV -sC -p-)" \
        "5:Vuln Scan (nmap+nuclei)" \
        "6:Web Recon (subfinder->httpx->nuclei)" \
        "7:SMB Enum (enum4linux+netexec)" \
        "8:Router-Recon (eigener Router komplett)" \
        "9:IoT-Discovery (UPnP/mDNS/SSDP)" \
        "0:Zurueck")" || break

    case "$CH" in
        W) run_script "$TOOLKIT/scripts/wizards/network-pentest-wizard.sh" ;;
        1) t=$(ask "Subnet:"); run_script "$S/quick-discovery.sh" "$t" ;;
        2) t=$(ask "Subnet:"); i=$(ask "Interface [Enter=auto]:"); run_script "$S/arp-scan.sh" "$t" "$i" ;;
        3) t=$(ask "Target:"); p=$(ask "Ports [1-65535]:"); r=$(ask "Rate [10000]:")
           run_script "$S/masscan-quick.sh" "$t" "${p:-1-65535}" "${r:-10000}" ;;
        4) t=$(ask "Host/CIDR:"); run_script "$S/full-portscan.sh" "$t" ;;
        5) t=$(ask "Host/URL:"); run_script "$S/vuln-scan.sh" "$t" ;;
        6) t=$(ask "Domain:"); run_script "$S/web-recon.sh" "$t" ;;
        7) t=$(ask "Host/CIDR:"); run_script "$S/smb-enum.sh" "$t" ;;
        8) r=$(ask "Router-IP [Enter=auto]:"); run_script "$S/router-recon.sh" "$r" ;;
        9) n=$(ask "Netz-CIDR:"); run_script "$S/iot-discovery.sh" "$n" ;;
        0|"") break ;;
    esac
done
