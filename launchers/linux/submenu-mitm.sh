#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/mitm"

while true; do
    CH="$(choose "MITM-Toolkit (eigenes LAN)" \
        "1:Network-Sniff (tcpdump rotation)" \
        "2:ARP-Spoof zwischen Target + Gateway" \
        "3:bettercap quick (ARP+Sniff+Probe)" \
        "4:Responder (LLMNR/NBT-NS Poisoning)" \
        "5:DNS-Spoof (dnsmasq)" \
        "0:Zurueck")" || break

    case "$CH" in
        1) i=$(ask "Interface:"); f=$(ask "BPF-Filter [Enter=default]:"); run_script "$S/network-sniff.sh" "$i" "$f" ;;
        2) i=$(ask "Interface:"); t=$(ask "Target-IP:"); g=$(ask "Gateway-IP:"); run_script "$S/arp-spoof.sh" "$i" "$t" "$g" ;;
        3) i=$(ask "Interface:"); t=$(ask "Target:"); run_script "$S/bettercap-quick.sh" "$i" "$t" ;;
        4) i=$(ask "Interface:"); n=$(ask "Network-ID (targets.yaml):"); run_script "$S/responder-quick.sh" "$i" "$n" ;;
        5) i=$(ask "Interface:"); n=$(ask "Network-ID:"); run_script "$S/dns-spoof.sh" "$i" "$n" ;;
        0|"") break ;;
    esac
done
