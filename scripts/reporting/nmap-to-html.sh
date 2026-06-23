#!/usr/bin/env bash
# nmap-to-html.sh - nmap.xml -> HTML via xsltproc
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
# shellcheck source=../lib/logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

require_bin xsltproc

XML="${1:-}"
[[ -f "$XML" ]] || { echo "Usage: $0 <nmap.xml>"; exit 1; }

OUT="${XML%.xml}.html"
XSL="${NMAP_BOOTSTRAP_XSL:-/usr/share/nmap/nmap.xsl}"
[[ -f "$XSL" ]] || XSL="https://raw.githubusercontent.com/honze-net/nmap-bootstrap-xsl/master/nmap-bootstrap.xsl"

xsltproc -o "$OUT" "$XSL" "$XML"
log_ok "$OUT"
