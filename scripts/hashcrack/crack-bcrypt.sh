#!/usr/bin/env bash
# crack-bcrypt.sh - hashcat wrapper fuer bcrypt
HC_MODE=3200
HC_NAME="bcrypt"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
