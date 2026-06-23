#!/usr/bin/env bash
# hidpi-toggle.sh - HiDPI Modus an/aus (fuer 4k-Displays)
if command -v kali-hidpi-mode >/dev/null 2>&1; then
    kali-hidpi-mode
else
    echo "[-] kali-hidpi-mode nicht vorhanden, manuell ueber xrandr setzen:"
    echo "    xrandr --output <DISPLAY> --scale 0.5x0.5"
fi
