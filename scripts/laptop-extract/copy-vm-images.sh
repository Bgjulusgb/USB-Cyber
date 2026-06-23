#!/usr/bin/env bash
# copy-vm-images.sh - VirtualBox/VMware/Hyper-V/QEMU Images sichern
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
ROOT="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$ROOT" ]] && { echo "Usage: $0 <laptop-id> <mount-root>"; exit 1; }
require_auth "$LAPTOP_ID"

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-vms-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"

log_info "Suche VM-Images"
find "$ROOT" -type f \
    \( -iname '*.vmdk' -o -iname '*.vmx' -o -iname '*.vdi' -o -iname '*.vbox' \
       -o -iname '*.vhd' -o -iname '*.vhdx' -o -iname '*.qcow2' -o -iname '*.img' -o -iname '*.iso' \) \
    -size +50M 2>/dev/null | tee "$outdir/_vmlist.txt"

count="$(wc -l < "$outdir/_vmlist.txt")"
[[ $count -eq 0 ]] && { log_warn "Keine VM-Images gefunden"; exit 0; }

log_warn "$count VM-Files gefunden. Koennen sehr gross sein!"
du -hcs $(head -50 "$outdir/_vmlist.txt") 2>/dev/null | tail -1

read -r -p "Wirklich alle kopieren? [y/N] " ans
[[ "$ans" =~ ^[yYjJ]$ ]] || { log_warn "Skip"; exit 0; }

rsync -a --info=progress2 --files-from="$outdir/_vmlist.txt" / "$outdir/vms/" 2>&1 | tail -3
log_ok "$outdir"
