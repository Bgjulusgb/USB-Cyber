#!/usr/bin/env bash
# screenshot-collect.sh - flameshot-Captures organisieren
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

SRC="${1:-$HOME/Pictures}"
DEST="$TOOLKIT/output/reports/screenshots-$(date +%Y%m%d)"
mkdir -p "$DEST"

count=0
while IFS= read -r -d '' f; do
    cp "$f" "$DEST/"
    count=$((count+1))
done < <(find "$SRC" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' \) -newer "$DEST" -print0 2>/dev/null)

log_ok "$count Screenshots -> $DEST"
