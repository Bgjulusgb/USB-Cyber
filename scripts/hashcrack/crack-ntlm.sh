#!/usr/bin/env bash
# crack-ntlm.sh - hashcat wrapper fuer Windows-NTLM
HC_MODE=1000
HC_NAME="ntlm"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
