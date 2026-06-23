#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/wifi"

while true; do
    CH="$(choose "WiFi Audits" \
        "W:WIZARD (alles in einem Lauf)" \
        "1:Passiver Scan (iw)" \
        "2:Monitor-Mode aktivieren" \
        "3:Handshake-Capture (mit deauth)" \
        "4:PMKID-Attack (clientless)" \
        "5:WPS-Attack (reaver/bully)" \
        "6:WPS Pixie-Dust (offline)" \
        "7:Quick-WPA-Crack (scan->cap->crack)" \
        "8:wifite2 Auto (alle Auth-Targets)" \
        "9:pcap -> hashcat 22000" \
        "C:WPA crack (hashcrack-Submenu)" \
        "D:Deauth-Resilienz-Test (PMF check)" \
        "R:Router Default-Creds testen" \
        "E:Evil-Twin (LAB ONLY)" \
        "0:Zurueck")" || break

    case "$CH" in
        W) run_script "$TOOLKIT/scripts/wizards/wifi-audit-wizard.sh" ;;
        1) run_script "$S/wifi-scan.sh" ;;
        2) run_script "$S/wifi-monitor-start.sh" ;;
        3) iface=$(ask "Monitor-Interface:")
           bssid=$(ask "Target BSSID:")
           ch=$(ask "Channel:")
           ssid=$(ask "Target SSID (optional):")
           run_script "$S/handshake-capture.sh" "$iface" "$bssid" "$ch" "$ssid" ;;
        4) iface=$(ask "Monitor-Interface:")
           bssid=$(ask "Target BSSID:")
           run_script "$S/pmkid-attack.sh" "$iface" "$bssid" ;;
        5) iface=$(ask "Monitor-Interface:"); bssid=$(ask "BSSID:"); ch=$(ask "Channel:"); tool=$(ask "Tool [reaver|bully]:")
           run_script "$S/wps-attack.sh" "$iface" "$bssid" "$ch" "${tool:-reaver}" ;;
        6) iface=$(ask "Monitor-Interface:"); bssid=$(ask "BSSID:"); ch=$(ask "Channel:")
           run_script "$S/wps-pixiedust.sh" "$iface" "$bssid" "$ch" ;;
        7) iface=$(ask "Monitor-Interface:")
           run_script "$S/wpa-quick-crack.sh" "$iface" ;;
        8) iface=$(ask "Monitor-Interface:"); run_script "$S/wifite-auto.sh" "$iface" ;;
        9) pcap=$(ask "Pfad zur pcap/pcapng:")
           run_script "$S/pcap-to-hashcat.sh" "$pcap" ;;
        C) bash "$TOOLKIT/launchers/linux/submenu-hashcrack.sh" ;;
        D) iface=$(ask "Monitor-Interface:"); bssid=$(ask "BSSID:")
           run_script "$S/deauth-resilience-test.sh" "$iface" "$bssid" ;;
        R) r=$(ask "Router IP/URL:"); run_script "$S/router-default-creds.sh" "$r" ;;
        E) lab=$(ask "Lab-Target-ID:")
           iface=$(ask "AP-Interface:")
           ssid=$(ask "SSID (rogue):")
           ch=$(ask "Channel:")
           run_script "$S/evil-twin-setup.sh" "$lab" "$iface" "$ssid" "$ch" ;;
        0|"") break ;;
    esac
done
