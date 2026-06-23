#!/usr/bin/env bash
# full-update.sh - Kali komplett aktualisieren
set -euo pipefail
TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"

log_info "apt update + upgrade"
sudo apt update
sudo apt -y full-upgrade
sudo apt -y autoremove

log_info "pipx upgrade-all"
pipx upgrade-all 2>/dev/null || true

log_info "Toolkit-Bootstrap (repos + npm + win)"
bash "$TOOLKIT/scripts/lib/bootstrap.sh"

log_info "nuclei templates"
command -v nuclei >/dev/null 2>&1 && nuclei -update-templates 2>&1 | tail -3 || true

log_ok "Update fertig"
