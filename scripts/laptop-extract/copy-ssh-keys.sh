#!/usr/bin/env bash
# copy-ssh-keys.sh - SSH-Keys, PuTTY-Keys, GnuPG sammeln
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

LAPTOP_ID="${1:-}"
ROOT="${2:-}"
[[ -z "$LAPTOP_ID" || -z "$ROOT" ]] && { echo "Usage: $0 <laptop-id> <mount-root>"; exit 1; }
require_auth "$LAPTOP_ID"

outdir="$TOOLKIT/output/laptop-extract/${LAPTOP_ID}-keys-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$outdir"/{ssh,putty,gnupg,kerberos,tokens}

# SSH (Linux/macOS .ssh)
find "$ROOT" -type d -name '.ssh' 2>/dev/null | while IFS= read -r sd; do
    user="$(echo "$sd" | grep -oE '(Users|home)/[^/]+' | head -1 | cut -d/ -f2)"
    [[ -z "$user" ]] && user=unknown
    log_info "SSH-Dir fuer $user: $sd"
    cp -r "$sd" "$outdir/ssh/$user" 2>/dev/null || true
done

# PuTTY-Registry-Eintraege (NTUSER.DAT)
find "$ROOT" -type f -iname 'NTUSER.DAT' 2>/dev/null | head -10 | while IFS= read -r hive; do
    user="$(echo "$hive" | grep -oE 'Users/[^/]+' | head -1 | cut -d/ -f2)"
    cp "$hive" "$outdir/putty/NTUSER-${user}.DAT" 2>/dev/null || true
done
log_info "PuTTY-Keys liegen in NTUSER.DAT unter Software\\SimonTatham\\PuTTY"
log_info "Auswertung offline: reglookup oder hivexsh"

# .ppk Dateien
find "$ROOT" -type f -iname '*.ppk' 2>/dev/null | while IFS= read -r f; do
    rel="${f#$ROOT/}"
    dst="$outdir/putty/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$f" "$dst"
done

# GnuPG
find "$ROOT" -type d -name '.gnupg' 2>/dev/null | while IFS= read -r d; do
    user="$(echo "$d" | grep -oE '(Users|home)/[^/]+' | head -1 | cut -d/ -f2)"
    cp -r "$d" "$outdir/gnupg/${user:-unknown}" 2>/dev/null || true
done

# Kerberos krb5
find "$ROOT" -type f -name 'krb5.conf' 2>/dev/null > "$outdir/kerberos/krb5-configs.txt"
find "$ROOT" -type f -name 'krb5.keytab' 2>/dev/null | while IFS= read -r f; do
    cp "$f" "$outdir/kerberos/$(basename "$f")" 2>/dev/null || true
done

# .gitconfig / git-credentials
find "$ROOT" -type f -name '.git-credentials' 2>/dev/null | while IFS= read -r f; do
    user="$(echo "$f" | grep -oE '(Users|home)/[^/]+' | head -1 | cut -d/ -f2)"
    cp "$f" "$outdir/tokens/git-credentials-${user:-unknown}" 2>/dev/null || true
done

# WSL distros
find "$ROOT" -type d -path '*Local/Packages/CanonicalGroupLimited*' 2>/dev/null \
    > "$outdir/tokens/wsl-distros.txt"

log_ok "$outdir"
du -sh "$outdir"
