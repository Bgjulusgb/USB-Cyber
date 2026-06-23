#!/usr/bin/env bash
# crack-ntlmv2.sh - hashcat wrapper fuer NTLMv2-Responder
HC_MODE=5600
HC_NAME="ntlmv2"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
