#!/usr/bin/env bash
# selftest.sh - Smoke-Test fuer das Toolkit
# Prueft Struktur, Berechtigungen, Auth-Gate-Funktion, Bash-Syntax.
# Macht KEINE Netzwerkaktivitaet.

set -u

TOOLKIT="${TOOLKIT:-$(dirname "$(dirname "$(realpath "$0")")")/..}"
TOOLKIT="$(realpath "$TOOLKIT")"
export TOOLKIT

pass=0
fail=0
warn=0

ok()    { echo -e "\033[32m[OK ]\033[0m $*"; pass=$((pass+1)); }
fail()  { echo -e "\033[31m[FAI]\033[0m $*"; fail=$((fail+1)); }
warn()  { echo -e "\033[33m[WRN]\033[0m $*"; warn=$((warn+1)); }
section() { echo; echo -e "\033[36m== $* ==\033[0m"; }

section "Verzeichnisstruktur"
for d in authorized-targets launchers/linux launchers/windows scripts/lib scripts/wifi \
         scripts/network scripts/hashcrack scripts/forensics scripts/recon-passive \
         scripts/reporting tools repos wordlists output docs; do
    if [[ -d "$TOOLKIT/$d" ]]; then ok "$d"; else fail "$d fehlt"; fi
done

section "Kritische Dateien"
for f in README.md authorized-targets/targets.yaml repos/manifest.yaml \
         scripts/lib/auth_check.sh scripts/lib/auth_check.ps1 \
         scripts/lib/logging.sh scripts/lib/bootstrap.sh \
         launchers/linux/pentest-menu.sh launchers/windows/pentest-menu.bat \
         launchers/windows/pentest-menu.ps1; do
    if [[ -f "$TOOLKIT/$f" ]]; then ok "$f"; else fail "$f fehlt"; fi
done

section "Bash-Syntax-Check aller .sh"
shopt -s globstar nullglob
syntax_errors=0
for s in "$TOOLKIT"/**/*.sh; do
    if bash -n "$s" 2>/tmp/se.err; then
        :
    else
        fail "Syntax in $s"
        cat /tmp/se.err
        syntax_errors=$((syntax_errors+1))
    fi
done
[[ $syntax_errors -eq 0 ]] && ok "$(find "$TOOLKIT" -name '*.sh' | wc -l) shell scripts ok"

section "Hashcrack Wrapper Vollstaendigkeit"
for w in ntlm ntlmv2 wpa bcrypt md5 sha256 kerberos zip; do
    if [[ -f "$TOOLKIT/scripts/hashcrack/crack-${w}.sh" ]]; then ok "crack-${w}.sh"; else fail "crack-${w}.sh fehlt"; fi
done

section "Auth-Gate Logik"
TMPYAML="$(mktemp)"
cat > "$TMPYAML" <<EOF
targets:
  - id: test-only
    scope: 10.99.99.0/24
    type: lab
EOF

# Erlaubt: muss exit 0
if TOOLKIT="$TOOLKIT" TARGETS_FILE="$TMPYAML" AUDIT_LOG="/tmp/audit-test.log" \
   bash -c 'source "$TOOLKIT/scripts/lib/auth_check.sh"; require_auth 10.99.99.42' >/dev/null 2>&1; then
    ok "Auth erlaubt allowlisted Ziel"
else
    fail "Auth blockiert allowlisted Ziel (sollte durchgehen)"
fi

# Blockiert: muss exit 2
if TOOLKIT="$TOOLKIT" TARGETS_FILE="$TMPYAML" AUDIT_LOG="/tmp/audit-test.log" \
   bash -c 'source "$TOOLKIT/scripts/lib/auth_check.sh"; require_auth 8.8.8.8' >/dev/null 2>&1; then
    fail "Auth liess fremdes Ziel durch (sollte abbrechen)"
else
    ok "Auth blockiert fremdes Ziel"
fi
rm -f "$TMPYAML" /tmp/audit-test.log

section "YAML-Manifest Parse"
if command -v python3 >/dev/null && python3 -c 'import yaml' >/dev/null 2>&1; then
    if python3 -c "import yaml; yaml.safe_load(open('$TOOLKIT/repos/manifest.yaml'))" >/dev/null 2>&1; then
        ok "manifest.yaml parsebar"
    else
        fail "manifest.yaml parse error"
    fi
    if python3 -c "import yaml; yaml.safe_load(open('$TOOLKIT/authorized-targets/targets.yaml'))" >/dev/null 2>&1; then
        ok "targets.yaml parsebar"
    else
        fail "targets.yaml parse error"
    fi
else
    warn "python3+yaml fehlt, YAML-Check skipped"
fi

section "Zusammenfassung"
echo "PASS: $pass | FAIL: $fail | WARN: $warn"
[[ $fail -eq 0 ]]
