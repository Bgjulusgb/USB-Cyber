#!/usr/bin/env bash
# crack-wpa.sh - hashcat wrapper fuer WiFi-WPA-PMKID-EAPOL
HC_MODE=22000
HC_NAME="wpa"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
