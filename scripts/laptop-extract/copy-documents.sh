#!/usr/bin/env bash
# copy-documents.sh - alle Dokumente, Bilder, Videos sammeln (rekursiv)
# Filter ueber Endung, kein Vertrauen auf Ordnerstruktur (Daten sind oft verstreut).
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"
require_bin rsync

LAPTOP_ID="${1:-}"
ROOT="${2:-}"
KINDS="${3:-docs+media}"   # docs | media | docs+media | all
[[ -z "$LAPTOP_ID" || -z "$ROOT" ]] && {
    echo "Usage: $0 <laptop-id> <mount-root> [docs|media|docs+media|all]"
    exit 1
}
require_auth "$LAPTOP_ID"

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-files-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"
LIST="$outdir/_filelist.txt"

DOC_EXT='pdf|docx?|xlsx?|pptx?|odt|ods|odp|rtf|txt|md|csv|tsv|json|yaml|yml|html?|epub|mobi|tex|ps|djvu'
MEDIA_EXT='jpe?g|png|gif|bmp|tiff?|webp|raw|cr2|nef|arw|heic|mp4|mov|avi|mkv|webm|wmv|mp3|wav|flac|m4a|ogg|opus|aac'
ARCH_EXT='zip|7z|rar|tar|gz|bz2|xz|tgz'

case "$KINDS" in
    docs)        REGEX="\.($DOC_EXT)$" ;;
    media)       REGEX="\.($MEDIA_EXT)$" ;;
    docs+media)  REGEX="\.($DOC_EXT|$MEDIA_EXT)$" ;;
    all)         REGEX="\.($DOC_EXT|$MEDIA_EXT|$ARCH_EXT)$" ;;
    *)           log_err "Unknown kind: $KINDS"; exit 1 ;;
esac

log_info "Finde Dateien (regex: $REGEX)"
find "$ROOT" -type f \
    -not -path '*/Windows/*' -not -path '*/Program Files/*' -not -path '*/Program Files (x86)/*' \
    -not -path '*/AppData/Local/Temp/*' -not -path '*/$Recycle.Bin/*' \
    -regextype posix-egrep -iregex ".*$REGEX" \
    2>/dev/null > "$LIST"

count="$(wc -l < "$LIST")"
size="$(du -hcs $(head -1000 "$LIST" 2>/dev/null) 2>/dev/null | tail -1 | cut -f1)"
log_info "Gefunden: $count Dateien (Sample-Groesse ~$size)"
log_warn "Diese Operation kopiert moeglicherweise GBs - reicht der Toolkit-Platz?"
df -h "$TOOLKIT" | tail -1

read -r -p "Wirklich kopieren? [y/N] " ans
[[ "$ans" =~ ^[yYjJ]$ ]] || { log_warn "Abgebrochen"; exit 0; }

log_info "rsync kopiert nach $outdir/files/"
rsync -a --info=progress2 --files-from="$LIST" / "$outdir/files/" 2>&1 | tail -5

du -sh "$outdir"
log_ok "$outdir"
