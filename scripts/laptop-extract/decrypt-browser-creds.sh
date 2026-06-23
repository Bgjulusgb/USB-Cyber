#!/usr/bin/env bash
# decrypt-browser-creds.sh - Versuch der Browser-Passwort-Entschluesselung offline
# Chrome/Edge: AES-Key liegt im "Local State" (DPAPI), Passwoerter in "Login Data" (SQLite, AES-GCM).
# Firefox: key4.db + logins.json mit master password (oder leer).
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
CREDS_DIR="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$CREDS_DIR" ]] && {
    echo "Usage: $0 <laptop-id> <creds-output-dir>"
    exit 1
}
require_auth "$LAPTOP_ID"

out="$CREDS_DIR/parsed/browser-creds.txt"
mkdir -p "$(dirname "$out")"
: > "$out"

# --- Firefox: logins.json + key4.db ---
log_info "Firefox-Profile durchsuchen"
for udir in "$CREDS_DIR/browser"/*; do
    [[ -d "$udir" ]] || continue
    user="$(basename "$udir")"
    ff="$udir/firefox-profiles"
    [[ -d "$ff" ]] || continue

    for profile in "$ff"/*; do
        [[ -d "$profile" ]] || continue
        json="$profile/logins.json"
        key="$profile/key4.db"
        if [[ -f "$json" && -f "$key" ]]; then
            log_ok "Firefox-Profil $user/$(basename "$profile")"
            if command -v firefox_decrypt >/dev/null 2>&1; then
                firefox_decrypt -d "$profile" 2>/dev/null | tee -a "$out" || true
            elif command -v pyff_decrypt >/dev/null 2>&1; then
                pyff_decrypt "$profile" | tee -a "$out" || true
            elif [[ -f "/usr/share/firefox_decrypt/firefox_decrypt.py" ]]; then
                python3 /usr/share/firefox_decrypt/firefox_decrypt.py -d "$profile" | tee -a "$out" || true
            else
                {
                    echo "# Firefox $user/$(basename "$profile")"
                    echo "# Toolchain: pip install firefox_decrypt  (oder lazagne)"
                    echo "# Profile-Pfad: $profile"
                    echo
                } >> "$out"
                log_warn "firefox_decrypt fehlt - Profil markiert fuer manuelles Cracken"
            fi
        fi
    done
done

# --- Chrome/Edge: DPAPI nach offline-Decrypt ---
log_info "Chrome/Edge - DPAPI-Decrypt (komplex offline)"
{
    echo "# Chrome/Edge offline Decrypt:"
    echo "# 1. AES-Key aus 'Local State' (encrypted_key) extrahieren"
    echo "# 2. DPAPI-Master-Key des Users entschluesseln (User-Passwort oder NTLM-Hash noetig)"
    echo "# 3. Mit master-key den AES-Key entschluesseln"
    echo "# 4. mit AES-Key die Passwort-DB entschluesseln"
    echo "#"
    echo "# Beste Tools: dpapick3 (https://github.com/tijldeneut/dpapick3)"
    echo "#              donpapi    (https://github.com/login-securite/DonPAPI)"
    echo "#"
    echo "# Schnellster Weg fuer eigenes Geraet: Windows live booten,"
    echo "# LaZagne ausfuehren -> alle Passwoerter mit aktuellem User-DPAPI."
    echo ""
} >> "$out"

# Liste gefundene Datenbanken
for udir in "$CREDS_DIR/browser"/*; do
    [[ -d "$udir" ]] || continue
    user="$(basename "$udir")"
    found="$(find "$udir" -name 'Login Data*' -o -name 'Local State*' 2>/dev/null)"
    if [[ -n "$found" ]]; then
        {
            echo "## Chrome/Edge Datenbanken fuer $user:"
            echo "$found"
            echo
        } >> "$out"
    fi
done

log_ok "Output: $out"
log_info "Empfehlung: Live-Windows-Boot + LaZagne fuer schnelles Ergebnis"
