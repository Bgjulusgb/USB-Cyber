#!/usr/bin/env bash
# copy-emails.sh - Outlook (PST/OST), Thunderbird, Apple Mail Daten kopieren
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"
# shellcheck source=../lib/auth_check.sh
source "$TOOLKIT/scripts/lib/auth_check.sh"
require_bin rsync

LAPTOP_ID="${1:-}"
ROOT="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$ROOT" ]] && { echo "Usage: $0 <laptop-id> <mount-root>"; exit 1; }
require_auth "$LAPTOP_ID"

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-emails-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"

log_info "Outlook PST/OST"
find "$ROOT" -type f \( -iname '*.pst' -o -iname '*.ost' -o -iname '*.nst' \) 2>/dev/null | \
    while IFS= read -r f; do
        rel="${f#$ROOT/}"
        dst="$outdir/outlook/$rel"
        mkdir -p "$(dirname "$dst")"
        cp -v "$f" "$dst" 2>&1 | tail -1
    done

log_info "Thunderbird-Profile"
find "$ROOT" -type d -path '*Thunderbird/Profiles/*' 2>/dev/null | \
    while IFS= read -r d; do
        user="$(echo "$d" | grep -oE 'Users/[^/]+|home/[^/]+' | head -1 | cut -d/ -f2)"
        profile="$(basename "$d")"
        rsync -a --info=progress2 "$d/" "$outdir/thunderbird/${user:-unknown}-$profile/" 2>&1 | tail -3
    done

log_info "Apple Mail (falls macOS-Volume)"
for mailroot in $(find "$ROOT" -type d -path '*/Library/Mail' 2>/dev/null); do
    user="$(echo "$mailroot" | grep -oE 'Users/[^/]+' | head -1 | cut -d/ -f2)"
    rsync -a --info=progress2 "$mailroot/" "$outdir/apple-mail/${user:-unknown}/" 2>&1 | tail -3
done

log_info "Generische .eml/.mbox"
find "$ROOT" -type f \( -iname '*.eml' -o -iname '*.mbox' \) 2>/dev/null | head -200 | \
    rsync -a --files-from=- "$ROOT/" "$outdir/loose-emails/" 2>/dev/null || true

du -sh "$outdir"
log_ok "$outdir"
