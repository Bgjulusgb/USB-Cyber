#!/usr/bin/env bash
# crack-kerberos.sh - hashcat wrapper fuer Kerberos-AS-REP-23
HC_MODE=13100
HC_NAME="kerberos"
source "$(dirname "$0")/_hashcat_common.sh"
parse_args "$@"
run_hashcat
