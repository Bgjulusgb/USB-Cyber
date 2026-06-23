#!/usr/bin/env bash
# crack-zip.sh - hashcat wrapper fuer WinZip-PKZIP
HC_MODE=13600
HC_NAME="zip"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
