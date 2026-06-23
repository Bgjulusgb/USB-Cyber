#!/usr/bin/env bash
# masscan-quick.sh - extrem schneller Portscan auf grossem Range
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

TARGET="${1:-}"
PORTS="${2:-1-65535}"
RATE="${3:-10000}"
[[ -z "$TARGET" ]] && {
    echo "Usage: $0 <cidr-or-host> [ports=1-65535] [rate=10000]"
    exit 1
}
require_auth "$TARGET"

require_bin masscan
outdir="$(make_outdir scans masscan-${TARGET//[\/.]/_})"

log_info "masscan -p$PORTS --rate=$RATE $TARGET"
sudo masscan -p"$PORTS" --rate="$RATE" "$TARGET" \
    -oG "$outdir/masscan.gnmap" \
    -oJ "$outdir/masscan.json" 2>&1 | tee "$outdir/run.log"

log_info "Extrahiere Liste fuer nmap-Followup"
grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' "$outdir/masscan.gnmap" | \
    awk -F: '{ ips[$1]=ips[$1]","$2 } END { for (i in ips) print i, substr(ips[i],2) }' \
    > "$outdir/nmap-targets.txt"

log_ok "Output: $outdir"
log_info "Naechster Schritt: nmap -sV -p$(awk '{print $2}' "$outdir/nmap-targets.txt" | head -1) auf gefundene Ports"
