#!/usr/bin/env bash
# full-disk-image.sh - forensisches Vollabbild der Laptop-Disk via dd/dcfldd
# Read-only Quelle. Gross! Aber sicher (kein Boot, kein Mount-Risiko).
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
DEV="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$DEV" ]] && {
    echo "Usage: $0 <laptop-id> <device, z.B. /dev/nvme0n1>"
    echo
    echo "Verfuegbare Disks:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v loop
    exit 1
}
require_auth "$LAPTOP_ID"

[[ -b "$DEV" ]] || { log_err "$DEV ist kein Block-Device"; exit 1; }

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-image-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"
out="$outdir/$(basename "$DEV").img"

size="$(lsblk -nbo SIZE "$DEV" | head -1)"
size_gb="$((size / 1024 / 1024 / 1024))"
toolkit_free_gb="$(df --output=avail -B1G "$TOOLKIT" | tail -1)"

log_info "Quelle:    $DEV ($size_gb GB)"
log_info "Ziel:      $out"
log_info "Toolkit frei: ${toolkit_free_gb} GB"

if [[ $size_gb -gt $toolkit_free_gb ]]; then
    log_err "Nicht genug Platz! Kompression nutzen oder anderes Ziel-Volume."
    exit 1
fi

confirm_destructive "Vollabbild $DEV -> $out erstellen? (Quelle bleibt read-only)"

# dd mit Fortschritt + SHA256
log_info "Starte Imaging mit dcfldd (oder dd Fallback)"
if command -v dcfldd >/dev/null 2>&1; then
    sudo dcfldd if="$DEV" of="$out" bs=4M hash=sha256 hashlog="$outdir/sha256.txt" status=on
else
    sudo dd if="$DEV" of="$out" bs=4M status=progress conv=noerror,sync
    log_info "SHA256 Hashlauf"
    sha256sum "$out" > "$outdir/sha256.txt"
fi

log_ok "Image: $out"
log_ok "Hash:  $outdir/sha256.txt"
echo
echo "Mount des Images zur Inspektion:"
echo "  sudo losetup -fP --show $out"
echo "  -> ergibt /dev/loopN mit Partitionen /dev/loopNp1 etc."
