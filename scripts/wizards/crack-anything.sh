#!/usr/bin/env bash
# crack-anything.sh - Auto-Detect Hash und passenden Wrapper aufrufen
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"

INPUT="${1:-}"
[[ -z "$INPUT" ]] && { echo "Usage: $0 <hash-or-file>"; exit 1; }

if [[ -f "$INPUT" ]]; then
    sample="$(head -1 "$INPUT")"
else
    sample="$INPUT"
fi

log_info "Sample: $sample"

# Auto-Detect via name-that-hash
detect() {
    if command -v nth >/dev/null 2>&1; then
        printf '%s\n' "$sample" | nth -g 2>/dev/null
    elif command -v name-that-hash >/dev/null 2>&1; then
        printf '%s\n' "$sample" | name-that-hash -g 2>/dev/null
    fi
}

raw="$(detect | grep -iE 'Hashcat Mode|m=' | head -3)"
log_info "Detection: $raw"

# Mapping nach Pattern
WL="${WORDLIST:-$TOOLKIT/wordlists/rockyou.txt}"
case "$sample" in
    \$2[aby]\$*)                          mode=3200; name=bcrypt ;;
    \$1\$*)                                mode=500;  name=md5crypt ;;
    \$5\$*)                                mode=7400; name=sha256crypt ;;
    \$6\$*)                                mode=1800; name=sha512crypt ;;
    \$argon2id*|\$argon2i*)                mode=34000; name=argon2id ;;
    \$pdf*)                                mode=10500; name=pdf ;;
    aad3b435b51404eeaad3b435b51404ee:*)    mode=1000; name=ntlm ;;
    *::*::*:*:*)                            mode=5600; name=ntlmv2 ;;
    WPA\*02\**)                             mode=22000; name=wpa ;;
    *)
        if [[ "$sample" =~ ^[a-fA-F0-9]{32}$ ]]; then
            mode=0; name=md5
        elif [[ "$sample" =~ ^[a-fA-F0-9]{40}$ ]]; then
            mode=100; name=sha1
        elif [[ "$sample" =~ ^[a-fA-F0-9]{64}$ ]]; then
            mode=1400; name=sha256
        elif [[ "$sample" =~ ^[a-fA-F0-9]{128}$ ]]; then
            mode=1700; name=sha512
        else
            log_err "Hash-Typ nicht erkannt. Manuell:"
            "$TOOLKIT/scripts/hashcrack/identify-hash.sh" "$INPUT"
            exit 1
        fi
        ;;
esac

log_ok "Erkannt: $name (-m $mode)"
log_info "Starte hashcat -m $mode mit $WL"

require_bin hashcat
[[ -f "$WL" ]] || { log_err "Wordlist fehlt: $WL"; exit 1; }

outdir="$(make_outdir cracked "auto-$name")"
hashcat -m "$mode" -a 0 "$INPUT" "$WL" \
    --outfile "$outdir/cracked.txt" --outfile-format=2 || true
hashcat -m "$mode" "$INPUT" --show | tee "$outdir/result.txt"
log_ok "Output: $outdir"
