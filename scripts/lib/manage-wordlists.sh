#!/usr/bin/env bash
# manage-wordlists.sh - rockyou bereitstellen, eigene Listen generieren
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=./logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

WORDLISTS="$TOOLKIT/wordlists"
mkdir -p "$WORDLISTS/custom"

action="${1:-menu}"

unpack_rockyou() {
    local target="$WORDLISTS/rockyou.txt"
    if [[ -f "$target" ]]; then
        log_ok "rockyou.txt vorhanden"
        return 0
    fi
    local src="/usr/share/wordlists/rockyou.txt.gz"
    if [[ -f "$src" ]]; then
        log_info "Entpacke rockyou aus $src"
        gunzip -c "$src" > "$target"
        log_ok "rockyou.txt bereit ($(wc -l < "$target") Zeilen)"
        return 0
    fi
    if [[ -f "/usr/share/wordlists/rockyou.txt" ]]; then
        cp /usr/share/wordlists/rockyou.txt "$target"
        log_ok "rockyou.txt kopiert"
        return 0
    fi
    log_warn "rockyou nicht gefunden. Auf Kali: sudo apt install wordlists"
}

link_seclists() {
    local src="$TOOLKIT/repos/seclists"
    local link="$WORDLISTS/seclists"
    if [[ -d "$src" ]] && [[ ! -e "$link" ]]; then
        ln -s "$src" "$link"
        log_ok "seclists symlink erstellt"
    fi
}

gen_custom() {
    local name="${1:-custom-$(date +%Y%m%d)}"
    local out="$WORDLISTS/custom/${name}.txt"
    log_info "Generiere benutzerdefinierte Liste -> $out"
    require_bin cewl 2>/dev/null || { log_warn "cewl fehlt - skip"; return 1; }
    read -r -p "URL fuer cewl scrape: " url
    cewl -d 2 -m 5 "$url" -w "$out"
    log_ok "$(wc -l < "$out") Wortern in $out"
}

stats() {
    log_info "Wordlist-Verzeichnis: $WORDLISTS"
    find "$WORDLISTS" -maxdepth 2 -type f -name '*.txt' -printf '%p\t%s\n' \
        | awk -F'\t' '{ printf "  %-60s %d bytes\n", $1, $2 }'
}

case "$action" in
    rockyou) unpack_rockyou ;;
    seclists) link_seclists ;;
    custom)  gen_custom "${2:-}" ;;
    stats)   stats ;;
    menu|*)
        echo "Usage: $0 {rockyou|seclists|custom [name]|stats}"
        echo
        echo "Vorschlaege:"
        echo "  $0 rockyou       # rockyou.txt entpacken/kopieren"
        echo "  $0 seclists      # SecLists symlinken"
        echo "  $0 custom mylist # cewl scrape -> wordlists/custom/mylist.txt"
        echo "  $0 stats         # Uebersicht"
        ;;
esac
