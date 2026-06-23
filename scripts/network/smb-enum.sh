#!/usr/bin/env bash
# smb-enum.sh - enum4linux-ng + NetExec smb enumeration
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"

TARGET="${1:-}"
[[ -z "$TARGET" ]] && { echo "Usage: $0 <host-or-cidr>"; exit 1; }
require_auth "$TARGET"

safe_target="$(echo "$TARGET" | tr '/.:' '___')"
outdir="$(make_outdir scans smb-${safe_target})"

if command -v enum4linux-ng >/dev/null 2>&1; then
    log_info "enum4linux-ng"
    enum4linux-ng -A "$TARGET" -oA "$outdir/enum4linux" \
        2>&1 | tee "$outdir/enum4linux.log"
elif [[ -d "$TOOLKIT/repos/enum4linux-ng" ]]; then
    log_info "enum4linux-ng aus repo"
    python3 "$TOOLKIT/repos/enum4linux-ng/enum4linux-ng.py" -A "$TARGET" \
        -oA "$outdir/enum4linux" 2>&1 | tee "$outdir/enum4linux.log"
else
    log_warn "enum4linux-ng nicht verfuegbar - apt install enum4linux-ng"
fi

if command -v nxc >/dev/null 2>&1; then
    NXC=nxc
elif command -v netexec >/dev/null 2>&1; then
    NXC=netexec
else
    NXC=""
fi

if [[ -n "$NXC" ]]; then
    log_info "NetExec ($NXC) - SMB"
    "$NXC" smb "$TARGET" --shares 2>&1 | tee "$outdir/netexec-shares.log"
    "$NXC" smb "$TARGET" --users 2>&1 | tee "$outdir/netexec-users.log"
    "$NXC" smb "$TARGET" --pass-pol 2>&1 | tee "$outdir/netexec-passpol.log"
else
    log_warn "NetExec/nxc nicht im PATH - skip"
fi

log_ok "Output: $outdir"
