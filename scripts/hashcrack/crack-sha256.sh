#!/usr/bin/env bash
# crack-sha256.sh - hashcat wrapper fuer SHA256
HC_MODE=1400
HC_NAME="sha256"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
