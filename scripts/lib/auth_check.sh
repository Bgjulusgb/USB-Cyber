#!/usr/bin/env bash
# auth_check.sh - zentrale Authorisierungs-Pruefung
#
# Usage:
#   source "$TOOLKIT/scripts/lib/auth_check.sh"
#   require_auth "<target_identifier>"
#
# require_auth bricht das Script ab (exit 2) wenn das Target nicht in
# authorized-targets/targets.yaml whitelisted ist. Match ist Substring
# auf scope-Felder.

set -u

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
TARGETS_FILE="${TARGETS_FILE:-$TOOLKIT/authorized-targets/targets.yaml}"
AUDIT_LOG="${AUDIT_LOG:-$TOOLKIT/output/audit.log}"

_auth_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
_auth_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
_auth_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

require_auth() {
    local target="${1:-}"
    local caller="${BASH_SOURCE[1]:-$0}"

    if [[ -z "$target" ]]; then
        _auth_red "[-] require_auth: kein Target uebergeben"
        return 1
    fi

    if [[ ! -f "$TARGETS_FILE" ]]; then
        _auth_red "[-] targets.yaml nicht gefunden: $TARGETS_FILE"
        _auth_yellow "    Lege die Datei an oder setze TARGETS_FILE."
        exit 2
    fi

    # Match: Substring auf scope-Eintraege. Comments und leere Zeilen raus.
    local scopes
    scopes="$(grep -E '^\s*scope:' "$TARGETS_FILE" | sed -E 's/^\s*scope:\s*//; s/\s*#.*$//; s/^["'\'']//; s/["'\'']$//')"

    if [[ -z "$scopes" ]]; then
        _auth_red "[-] Keine 'scope:' Eintraege in $TARGETS_FILE"
        _auth_yellow "    Trage mindestens ein Target ein bevor du aktive Tools laufen laesst."
        exit 2
    fi

    local matched=0
    # CIDR-Math via python (mit substring-Fallback wenn python fehlt)
    if command -v python3 >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        if python3 - "$target" <<EOF
import ipaddress, sys
target = sys.argv[1]
scopes = """$scopes""".strip().splitlines()
for scope in scopes:
    scope = scope.strip()
    if not scope:
        continue
    try:
        net = ipaddress.ip_network(scope, strict=False)
        try:
            ip = ipaddress.ip_address(target.split('/')[0])
            if ip in net:
                sys.exit(0)
        except ValueError:
            pass
    except ValueError:
        pass
    if target in scope or scope in target:
        sys.exit(0)
sys.exit(1)
EOF
        then
            matched=1
        fi
    else
        while IFS= read -r scope; do
            [[ -z "$scope" ]] && continue
            if [[ "$target" == *"$scope"* ]] || [[ "$scope" == *"$target"* ]]; then
                matched=1
                break
            fi
            # /24 Prefix-Trick als Fallback
            if [[ "$scope" == */24 ]]; then
                local prefix="${scope%.0/24}."
                if [[ "$target" == "$prefix"* ]]; then matched=1; break; fi
            fi
        done <<< "$scopes"
    fi

    if [[ $matched -eq 0 ]]; then
        _auth_red "[-] Target '$target' ist NICHT autorisiert."
        _auth_yellow "    Trage es in $TARGETS_FILE ein oder breche ab."
        _auth_yellow "    Lauf wird beendet (StGB Compliance)."
        exit 2
    fi

    # Audit-Log
    mkdir -p "$(dirname "$AUDIT_LOG")"
    printf '%s | %s | %s | %s\n' \
        "$(date -Iseconds)" \
        "$(whoami)" \
        "$(basename "$caller")" \
        "$target" >> "$AUDIT_LOG"

    _auth_green "[+] Auth OK fuer: $target"
}

# Hilfsfunktion: interaktive Bestaetigung fuer destruktive Aktionen
confirm_destructive() {
    local prompt="${1:-Aktion ausfuehren?}"
    local answer
    _auth_yellow "[!] $prompt [y/N]"
    read -r answer
    if [[ ! "$answer" =~ ^[yYjJ]$ ]]; then
        _auth_yellow "[-] Abgebrochen."
        exit 0
    fi
}
