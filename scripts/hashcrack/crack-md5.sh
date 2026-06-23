#!/usr/bin/env bash
# crack-md5.sh - hashcat wrapper fuer MD5
HC_MODE=0
HC_NAME="md5"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
