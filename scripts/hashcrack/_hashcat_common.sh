#!/usr/bin/env bash
# _hashcat_common.sh - shared logic fuer alle crack-*.sh wrapper
#
# Erwartet die env-Variable HC_MODE und HC_NAME.
# Optionale flags: --wordlist|-w, --rules|-r, --mask|-m, --gpu-only

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

require_bin hashcat

HASH_FILE=""
WORDLIST="$TOOLKIT/wordlists/rockyou.txt"
RULES=""
MASK=""
GPU_ONLY=0
EXTRA_ARGS=()

print_usage() {
    cat <<EOF
${HC_NAME:-crack} (hashcat mode $HC_MODE)

Usage: $0 <hashfile> [options]

Options:
  --wordlist|-w <file>   Wordlist (default rockyou.txt)
  --rules|-r    <file>   Hashcat rule file
  --mask|-m     <mask>   Mask attack (?l?l?l?l etc.) - statt wordlist
  --gpu-only             -d 1 plus -D 2 (GPU only)
  --                     alles Folgende als raw hashcat-args
EOF
}

parse_args() {
    if [[ $# -lt 1 ]]; then print_usage; exit 1; fi
    HASH_FILE="$1"; shift
    [[ -f "$HASH_FILE" ]] || { log_err "Hashfile nicht gefunden: $HASH_FILE"; exit 1; }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wordlist|-w) WORDLIST="$2"; shift 2 ;;
            --rules|-r)    RULES="$2"; shift 2 ;;
            --mask|-m)     MASK="$2"; shift 2 ;;
            --gpu-only)    GPU_ONLY=1; shift ;;
            --help|-h)     print_usage; exit 0 ;;
            --)            shift; EXTRA_ARGS=("$@"); break ;;
            *)             EXTRA_ARGS+=("$1"); shift ;;
        esac
    done
}

run_hashcat() {
    local outdir; outdir="$(make_outdir cracked "${HC_NAME:-crack}")"
    local pot="$outdir/cracked.txt"
    local args=("-m" "$HC_MODE" "--outfile" "$pot" "--outfile-format=2")

    [[ $GPU_ONLY -eq 1 ]] && args+=("-D" "2")
    [[ -n "$RULES" ]] && args+=("-r" "$RULES")

    if [[ -n "$MASK" ]]; then
        args+=("-a" "3" "$HASH_FILE" "$MASK")
    else
        [[ -f "$WORDLIST" ]] || { log_err "Wordlist fehlt: $WORDLIST"; exit 1; }
        args+=("-a" "0" "$HASH_FILE" "$WORDLIST")
    fi

    args+=("${EXTRA_ARGS[@]}")

    log_info "hashcat ${args[*]}"
    hashcat "${args[@]}" || log_warn "hashcat exit non-zero (kann ok sein wenn nichts gefunden)"

    log_info "Show cracked:"
    hashcat -m "$HC_MODE" --show "$HASH_FILE" | tee "$outdir/show.txt"

    log_ok "Output: $outdir"
}
