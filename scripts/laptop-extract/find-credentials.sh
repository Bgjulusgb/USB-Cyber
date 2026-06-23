#!/usr/bin/env bash
# find-credentials.sh - greppt Dateien nach typischen Credential-Mustern
# (.env, config.json, *.kdbx, passwords.txt, ssh-keys, hardcoded creds)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
ROOT="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$ROOT" ]] && {
    echo "Usage: $0 <laptop-id> <search-root>"
    exit 1
}
require_auth "$LAPTOP_ID"

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-credfind-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"

log_info "Suche nach Cred-Dateien"

# Dateien-by-Name
{
    echo "=== KeePass-Datenbanken ==="
    find "$ROOT" -type f \( -iname '*.kdbx' -o -iname '*.kdb' \) 2>/dev/null
    echo
    echo "=== Browser-Logins ==="
    find "$ROOT" -type f -iname 'Login Data*' 2>/dev/null
    find "$ROOT" -type f -iname 'logins.json' 2>/dev/null
    echo
    echo "=== Putty/SSH ==="
    find "$ROOT" -type f \( -iname 'id_rsa*' -o -iname 'id_ed25519*' -o -iname 'id_ecdsa*' -o -iname 'known_hosts' -o -iname '*.ppk' \) 2>/dev/null
    echo
    echo "=== Config-Dateien mit moeglichen Secrets ==="
    find "$ROOT" -type f \( -iname '.env*' -o -iname 'wp-config.php' -o -iname 'web.config' -o -iname 'application.properties' -o -iname 'settings.json' -o -iname 'config.json' \) 2>/dev/null
    echo
    echo "=== Notes/Lists ==="
    find "$ROOT" -type f \( -iname '*password*' -o -iname '*passwort*' -o -iname '*kennwort*' -o -iname '*credentials*' \) 2>/dev/null
    echo
    echo "=== AWS/GCP/Azure Configs ==="
    find "$ROOT" -type f \( -path '*/.aws/credentials' -o -path '*/.aws/config' -o -path '*/.gcloud/*' -o -path '*/.azure/*' \) 2>/dev/null
    echo
    echo "=== VS Code / Editor Secrets ==="
    find "$ROOT" -type f -path '*/Code/User/sync/keybindings*' 2>/dev/null
    echo
    echo "=== Outlook PST/OST ==="
    find "$ROOT" -type f \( -iname '*.pst' -o -iname '*.ost' \) 2>/dev/null
    echo
    echo "=== Thunderbird ==="
    find "$ROOT" -type d -name '*.default*' -path '*Thunderbird*' 2>/dev/null
} | tee "$outdir/file-locations.txt"

# Grep nach Patterns in Textdateien (begrenzt auf <2MB Files)
log_info "Inhaltssuche nach Cred-Patterns (kann dauern)"
PATTERNS=(
    'password\s*[:=]\s*["'\''][^"'\'']{6,}'
    'pwd\s*[:=]\s*["'\''][^"'\'']{6,}'
    'passwort\s*[:=]\s*["'\''][^"'\'']{6,}'
    'api[_-]?key\s*[:=]\s*["'\''][^"'\'']{16,}'
    'secret\s*[:=]\s*["'\''][^"'\'']{16,}'
    'token\s*[:=]\s*["'\''][^"'\'']{20,}'
    'BEGIN (RSA|EC|OPENSSH) PRIVATE KEY'
    'aws_(access|secret)_key_id'
)

find "$ROOT" \
    -type f -size -2M \
    \( -iname '*.txt' -o -iname '*.md' -o -iname '*.csv' -o -iname '*.json' -o -iname '*.yaml' -o -iname '*.yml' \
       -o -iname '*.ini' -o -iname '*.conf' -o -iname '*.env*' -o -iname '*.config' -o -iname '*.xml' \
       -o -iname '*.properties' -o -iname '.bashrc' -o -iname '.zshrc' -o -iname '.profile' \) \
    2>/dev/null | \
    while IFS= read -r f; do
        for pat in "${PATTERNS[@]}"; do
            if grep -EiHn "$pat" "$f" >> "$outdir/content-hits.txt" 2>/dev/null; then
                :
            fi
        done
    done

log_ok "File-Locations: $outdir/file-locations.txt"
log_ok "Content-Hits:   $outdir/content-hits.txt"
echo
echo "Vorschau Content-Hits (erste 20):"
head -n 20 "$outdir/content-hits.txt" 2>/dev/null || echo "(leer)"
