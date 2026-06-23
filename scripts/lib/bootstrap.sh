#!/usr/bin/env bash
# bootstrap.sh - laedt/updated GitHub-Repos, NPM-Pakete, Windows-Tools
# Idempotent: kann beliebig oft laufen.

set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
MANIFEST="$TOOLKIT/repos/manifest.yaml"

# shellcheck source=./logging.sh
source "$TOOLKIT/scripts/lib/logging.sh"

log_info "Bootstrap startet"
log_info "TOOLKIT=$TOOLKIT"
log_info "MANIFEST=$MANIFEST"

[[ -f "$MANIFEST" ]] || { log_err "Manifest fehlt: $MANIFEST"; exit 1; }

require_bin git
require_bin python3

if ! python3 -c 'import yaml' >/dev/null 2>&1; then
    log_warn "Python-Modul 'yaml' fehlt. Installiere via: sudo apt install -y python3-yaml"
    exit 1
fi

cd "$TOOLKIT"

python3 - "$MANIFEST" <<'PYEOF'
import os, sys, subprocess, urllib.request, pathlib, shutil, yaml

manifest_path = sys.argv[1]
toolkit = os.environ.get("TOOLKIT", "/mnt/toolkit")

with open(manifest_path) as f:
    m = yaml.safe_load(f) or {}

def info(msg):  print(f"\033[36m[INF]\033[0m {msg}")
def ok(msg):    print(f"\033[32m[OK ]\033[0m {msg}")
def warn(msg):  print(f"\033[33m[WRN]\033[0m {msg}")
def err(msg):   print(f"\033[31m[ERR]\033[0m {msg}")

# --- GitHub repos ---
repos_dir = pathlib.Path(toolkit) / "repos"
repos_dir.mkdir(exist_ok=True)
for r in m.get("github_repos", []):
    dest = repos_dir / r["dest"]
    if dest.exists():
        info(f"Updating {r['dest']}")
        rc = subprocess.run(["git", "-C", str(dest), "pull", "--ff-only"]).returncode
        if rc != 0:
            warn(f"Pull failed fuer {r['dest']}")
    else:
        info(f"Cloning {r['url']}")
        rc = subprocess.run(["git", "clone", "--depth=1", r["url"], str(dest)]).returncode
        if rc != 0:
            err(f"Clone failed fuer {r['url']}")
            continue
    ok(r["dest"])

# --- NPM ---
pkgs = m.get("npm_packages", [])
if pkgs:
    if shutil.which("npm") is None:
        warn("npm nicht im PATH - skip NPM packages")
    else:
        npm_dir = pathlib.Path(toolkit) / "npm-tools"
        npm_dir.mkdir(exist_ok=True)
        os.chdir(npm_dir)
        if not (npm_dir / "package.json").exists():
            subprocess.run(["npm", "init", "-y"], check=True)
        info(f"Installing npm packages: {', '.join(pkgs)}")
        rc = subprocess.run(["npm", "install", "--prefix", "."] + pkgs).returncode
        if rc != 0:
            err("npm install failed")
        else:
            ok("npm packages installed")
        os.chdir(toolkit)

# --- Windows Downloads ---
win_dir = pathlib.Path(toolkit) / "tools" / "windows-portable" / "_downloads"
win_dir.mkdir(parents=True, exist_ok=True)
for t in m.get("windows_portable", []):
    url = t["url"]
    name = t["name"]
    if t.get("skip_if_placeholder") and "X.X" in url:
        warn(f"Skip {name}: Platzhalter in URL, bitte aktualisieren in manifest.yaml")
        continue
    ext = ".7z" if url.endswith(".7z") else ".zip" if url.endswith(".zip") else ".exe" if url.endswith(".exe") else ".bin"
    out = win_dir / f"{name}{ext}"
    if out.exists():
        ok(f"{name} bereits geladen")
        continue
    info(f"Downloading {name} from {url}")
    try:
        urllib.request.urlretrieve(url, out)
        ok(f"{name} -> {out}")
    except Exception as e:
        err(f"Download failed: {name}: {e}")

print()
ok("Bootstrap fertig.")
PYEOF

log_ok "Bootstrap abgeschlossen"
