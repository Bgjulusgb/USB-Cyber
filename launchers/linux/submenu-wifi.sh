#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/wifi"

while true; do
    CH="$(choose "WiFi Audits" \
        "1:Passiver Scan (iw)" \
        "2:Monitor-Mode aktivieren" \
        "3:Handshake-Capture (Auth!)" \
        "4:PMKID-Attack (Auth!)" \
        "5:pcap -> hashcat 22000" \
        "6:WPA crack (verweist auf hashcrack-Submenu)" \
        "7:Evil-Twin (LAB ONLY)" \
        "0:Zurueck")" || break

    case "$CH" in
        1) run_script "$S/wifi-scan.sh" ;;
        2) run_script "$S/wifi-monitor-start.sh" ;;
        3) iface=$(ask "Monitor-Interface (z.B. wlan0mon):")
           bssid=$(ask "Target BSSID:")
           ch=$(ask "Channel:")
           ssid=$(ask "Target SSID (optional):")
           run_script "$S/handshake-capture.sh" "$iface" "$bssid" "$ch" "$ssid" ;;
        4) iface=$(ask "Monitor-Interface:")
           bssid=$(ask "Target BSSID:")
           run_script "$S/pmkid-attack.sh" "$iface" "$bssid" ;;
        5) pcap=$(ask "Pfad zur pcap/pcapng:")
           run_script "$S/pcap-to-hashcat.sh" "$pcap" ;;
        6) bash "$TOOLKIT/launchers/linux/submenu-hashcrack.sh" ;;
        7) lab=$(ask "Lab-Target-ID (muss in targets.yaml):")
           iface=$(ask "AP-Interface:")
           ssid=$(ask "SSID (rogue):")
           ch=$(ask "Channel:")
           run_script "$S/evil-twin-setup.sh" "$lab" "$iface" "$ssid" "$ch" ;;
        0|"") break ;;
    esac
done
