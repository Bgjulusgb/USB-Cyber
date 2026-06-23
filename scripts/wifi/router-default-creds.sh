#!/usr/bin/env bash
# router-default-creds.sh - testet eigenes Router-Webinterface auf Default-Creds
# Nur gegen eigenen Router.
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

ROUTER="${1:-}"
[[ -z "$ROUTER" ]] && { echo "Usage: $0 <router-ip-or-url>"; exit 1; }
require_auth "$ROUTER"

outdir="$(make_outdir scans router-defcred)"
require_bin curl

DEFCREDS=(
    "admin:admin" "admin:password" "admin:" "root:root" "root:admin"
    "admin:1234" "admin:1234567890" "user:user" "admin:0000"
    "guest:guest" "support:support"
)

URL="$ROUTER"
[[ "$URL" != http* ]] && URL="http://$ROUTER"

log_info "Teste $URL gegen ${#DEFCREDS[@]} Default-Kombis"
log_warn "Eigener Router only. Bei Lockout: kurz warten."

for combo in "${DEFCREDS[@]}"; do
    user="${combo%%:*}"; pass="${combo#*:}"
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -u "$user:$pass" "$URL")"
    printf '%-30s %s\n' "$combo" "$code" | tee -a "$outdir/results.txt"
    case "$code" in 200|302|301) log_ok "Login erfolgreich: $combo" ;; esac
    sleep 1
done

log_ok "Output: $outdir/results.txt"
