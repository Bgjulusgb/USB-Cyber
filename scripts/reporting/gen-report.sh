#!/usr/bin/env bash
# gen-report.sh - sammelt output/ + audit.log -> Markdown-Report
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

TITLE="${1:-Pentest Report}"
stamp="$(date +%Y%m%d-%H%M%S)"
outdir="$TOOLKIT/output/reports"
mkdir -p "$outdir"
report="$outdir/report-${stamp}.md"

{
    echo "# $TITLE"
    echo
    echo "**Generiert:** $(date -Iseconds)"
    echo "**Operator:** $(whoami)"
    echo
    echo "## Audit-Log (letzte 50 Eintraege)"
    echo
    echo '```'
    tail -n 50 "$TOOLKIT/output/audit.log" 2>/dev/null || echo "(leer)"
    echo '```'
    echo

    for section in scans captures handshakes cracked forensics; do
        dir="$TOOLKIT/output/$section"
        [[ -d "$dir" ]] || continue
        echo "## $section"
        echo
        find "$dir" -maxdepth 3 -type f \( -name '*.txt' -o -name '*.md' -o -name '*.log' \) -printf '%T@ %p\n' \
            | sort -nr | head -n 20 | awk '{$1=""; print "- " substr($0,2)}'
        echo
    done

    echo "## Authorized Targets"
    echo
    echo '```yaml'
    grep -E '^\s*-\s+id:|^\s*scope:|^\s*type:' "$TOOLKIT/authorized-targets/targets.yaml" 2>/dev/null || echo "(keine)"
    echo '```'
} > "$report"

log_ok "Report: $report"
echo
echo "HTML-Version optional:"
echo "  pandoc -s -o ${report%.md}.html $report"
