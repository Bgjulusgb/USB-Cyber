#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/wizards/quick-tool.sh"

while true; do
    CH="$(choose "Quick-Tool Launcher" \
        "n:nmap (mit Auth-Check)" \
        "m:masscan" \
        "h:hydra (Login-Brute)" \
        "j:john the ripper" \
        "x:hashcat raw" \
        "w:wireshark" \
        "t:tshark capture" \
        "M:metasploit (msfconsole)" \
        "b:BurpSuite" \
        "z:OWASP ZAP" \
        "q:sqlmap" \
        "k:nikto" \
        "g:gobuster dir" \
        "f:ffuf" \
        "W:whatweb" \
        "s:searchsploit" \
        "0:Zurueck")" || break

    case "$CH" in
        n) t=$(ask "Target:"); run_script "$S" nmap "$t" ;;
        m) t=$(ask "Target:"); run_script "$S" masscan "$t" ;;
        h) t=$(ask "Target Protocol://IP:"); proto=$(ask "Protocol (ssh/ftp/etc.):"); run_script "$S" hydra "$t" -s 22 "$proto" ;;
        j) f=$(ask "Hashfile:"); run_script "$S" john "$f" ;;
        x) read -r -p "hashcat args: " args; run_script "$S" hashcat $args ;;
        w) run_script "$S" wireshark ;;
        t) i=$(ask "Interface:"); run_script "$S" tshark "$i" ;;
        M) run_script "$S" metasploit ;;
        b) run_script "$S" burp ;;
        z) run_script "$S" zap ;;
        q) u=$(ask "URL:"); run_script "$S" sqlmap "$u" ;;
        k) u=$(ask "URL:"); run_script "$S" nikto "$u" ;;
        g) u=$(ask "URL:"); run_script "$S" gobuster "$u" ;;
        f) u=$(ask "URL (mit FUZZ optional):"); run_script "$S" ffuf "$u" ;;
        W) u=$(ask "URL:"); run_script "$S" whatweb "$u" ;;
        s) q=$(ask "Query:"); run_script "$S" searchsploit "$q" ;;
        0|"") break ;;
    esac
done
