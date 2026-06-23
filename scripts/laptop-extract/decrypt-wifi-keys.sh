#!/usr/bin/env bash
# decrypt-wifi-keys.sh - WLAN-Profile XML aus offline-Windows entschluesseln
# Nutzt DPAPI-Masterkeys + SYSTEM-Key.
#
# Methode: einfacher Pfad via metasploit's smb/wlan oder via dpapick
# Hier: Anleitung + Helper, da volle DPAPI-Entschluesselung manuell oft schneller geht.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
CREDS_DIR="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$CREDS_DIR" ]] && {
    echo "Usage: $0 <laptop-id> <creds-output-dir aus dump-windows-creds.sh>"
    exit 1
}
require_auth "$LAPTOP_ID"

[[ -d "$CREDS_DIR/wifi" ]] || { log_err "Kein wifi/ Unterordner in $CREDS_DIR"; exit 1; }

out="$CREDS_DIR/parsed/wifi-decrypted.txt"
mkdir -p "$(dirname "$out")"
: > "$out"

log_info "Versuche WLAN-Keys zu entschluesseln"

# Methode 1: DPAPick3 falls verfuegbar
if command -v dpapick3 >/dev/null 2>&1; then
    log_info "DPAPick3 vorhanden, versuche Auto-Decrypt"
    # System-DPAPI-Master-Key braucht SYSTEM+SECURITY hive
    log_warn "Anleitung dpapick3: siehe https://github.com/tijldeneut/dpapick3"
fi

# Methode 2: lazagne (online war hier nicht moeglich - aber Output sammeln)
# Methode 3: Parser fuer die XML-Strings selbst
log_info "WLAN-Profile (XML, key noch verschluesselt):"
for x in "$CREDS_DIR/wifi"/*.xml; do
    [[ -f "$x" ]] || continue
    ssid="$(grep -oP '<name>\K[^<]+' "$x" | head -1)"
    auth="$(grep -oP '<authentication>\K[^<]+' "$x" | head -1)"
    keymat="$(grep -oP '<keyMaterial>\K[^<]+' "$x" | head -1)"
    keytype="$(grep -oP '<protected>\K[^<]+' "$x" | head -1)"
    {
        echo "SSID:           $ssid"
        echo "Authentication: $auth"
        echo "Protected:      $keytype  (true = DPAPI-blob, false = Klartext-Hex)"
        echo "KeyMaterial:    $keymat"
        if [[ "$keytype" == "false" ]] && [[ -n "$keymat" ]]; then
            echo "Klartext-Pwd (hex->ascii):"
            echo "  $(printf '%b\n' "$(echo "$keymat" | sed 's/../\\x&/g')")"
        fi
        echo "---"
    } | tee -a "$out"
done

if grep -qE 'protected>false' "$CREDS_DIR/wifi"/*.xml 2>/dev/null; then
    log_ok "Mindestens 1 unprotected (klartext) Profil gefunden"
fi

log_info "Fuer DPAPI-geschuetzte Keys:"
echo "  1. Boot Live-Windows mit dem Laptop"
echo "  2. cmd als Admin -> netsh wlan show profile name=\"SSID\" key=clear"
echo "Alternativ Offline: impacket-secretsdump LSA mit User-Hash + dpapick3"
log_ok "Parsed: $out"
