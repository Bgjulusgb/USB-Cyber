#!/usr/bin/env bash
# undercover-toggle.sh - Kali als Windows 10 tarnen / wieder zurueck
if command -v kali-undercover >/dev/null 2>&1; then
    kali-undercover
else
    echo "[-] kali-undercover nicht installiert"
    echo "    sudo apt install kali-undercover"
fi
