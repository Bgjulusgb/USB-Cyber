#!/usr/bin/env bash
# _menu_lib.sh - helpers fuer alle submenu-*.sh
set -uo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"

# Fuehre ein Script in einer Subshell aus, fange Output ab, warte am Ende auf Enter
run_script() {
    local script="$1"; shift
    clear
    echo "==> $script $*"
    echo "----------------------------------------"
    if [[ -x "$script" ]]; then
        "$script" "$@" || true
    else
        bash "$script" "$@" || true
    fi
    echo "----------------------------------------"
    read -r -p "Weiter mit Enter..." _
}

# Frage einen Eingabewert ab
ask() {
    local prompt="$1"
    local var
    if command -v whiptail >/dev/null 2>&1; then
        var="$(whiptail --inputbox "$prompt" 10 60 3>&1 1>&2 2>&3)" || return 1
    else
        read -r -p "$prompt " var
    fi
    printf '%s' "$var"
}

# Menue-Auswahl, Items als "key:label"-Pairs
choose() {
    local title="$1"; shift
    local args=()
    for pair in "$@"; do
        args+=("${pair%%:*}" "${pair#*:}")
    done
    whiptail --title "$title" --menu "Auswahl" 20 70 12 "${args[@]}" 3>&1 1>&2 2>&3
}
