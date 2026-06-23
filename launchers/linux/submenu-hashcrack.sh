#!/usr/bin/env bash
set -uo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/launchers/linux/_menu_lib.sh"
S="$TOOLKIT/scripts/hashcrack"

while true; do
    CH="$(choose "Hash Cracking" \
        "I:Identify (was fuer ein Hash?)" \
        "1:NTLM (mode 1000)" \
        "2:NTLMv2 (mode 5600)" \
        "3:WPA hc22000 (mode 22000)" \
        "4:bcrypt (mode 3200)" \
        "5:MD5 (mode 0)" \
        "6:SHA256 (mode 1400)" \
        "7:Kerberos AS-REP (mode 13100)" \
        "8:ZIP (mode 13600)" \
        "0:Zurueck")" || break

    case "$CH" in
        I) h=$(ask "Hash oder Datei:"); run_script "$S/identify-hash.sh" "$h" ;;
        1|2|3|4|5|6|7|8)
            f=$(ask "Pfad zur Hash-Datei:")
            w=$(ask "Wordlist [Enter=rockyou]:")
            r=$(ask "Rule-File [Enter=keine]:")
            args=("$f")
            [[ -n "$w" ]] && args+=(--wordlist "$w")
            [[ -n "$r" ]] && args+=(--rules "$r")
            case "$CH" in
                1) run_script "$S/crack-ntlm.sh"     "${args[@]}" ;;
                2) run_script "$S/crack-ntlmv2.sh"   "${args[@]}" ;;
                3) run_script "$S/crack-wpa.sh"      "${args[@]}" ;;
                4) run_script "$S/crack-bcrypt.sh"   "${args[@]}" ;;
                5) run_script "$S/crack-md5.sh"      "${args[@]}" ;;
                6) run_script "$S/crack-sha256.sh"   "${args[@]}" ;;
                7) run_script "$S/crack-kerberos.sh" "${args[@]}" ;;
                8) run_script "$S/crack-zip.sh"      "${args[@]}" ;;
            esac ;;
        0|"") break ;;
    esac
done
