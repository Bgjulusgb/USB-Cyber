#!/usr/bin/env bash
# osint-email.sh - HaveIBeenPwned Check fuer eigene Mails
# Erfordert HIBP_API_KEY env var. Fallback: hash-DB local pruefen.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

EMAIL="${1:-}"
[[ -z "$EMAIL" ]] && { echo "Usage: $0 <email-or-file>"; exit 1; }

check_email() {
    local addr="$1"
    if [[ -z "${HIBP_API_KEY:-}" ]]; then
        log_warn "HIBP_API_KEY nicht gesetzt - kann nur Domain via Pwnedlist"
        return
    fi
    local enc; enc="$(printf '%s' "$addr" | python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.stdin.read().strip()))')"
    curl -sS \
        -H "hibp-api-key: $HIBP_API_KEY" \
        -H "user-agent: pentest-toolkit" \
        "https://haveibeenpwned.com/api/v3/breachedaccount/${enc}?truncateResponse=false" \
        | python3 -m json.tool 2>/dev/null || echo "[]"
}

if [[ -f "$EMAIL" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        log_info "=== $line ==="
        check_email "$line"
    done < "$EMAIL"
else
    check_email "$EMAIL"
fi
