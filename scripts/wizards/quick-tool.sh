#!/usr/bin/env bash
# quick-tool.sh - Wrapper-Wahl fuer alle Kali-Tools mit Auth-Gate vorab
# Beispiele:
#   quick-tool.sh nmap 192.168.1.1
#   quick-tool.sh metasploit
#   quick-tool.sh burp
#   quick-tool.sh wireshark
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

TOOL="${1:-}"
shift || true

[[ -z "$TOOL" ]] && {
    cat <<EOF
Usage: $0 <tool> [target/args...]

Bekannte Shortcuts (mit Auth-Check wo sinnvoll):
  nmap <target>      nmap default mit Output
  masscan <target>   masscan-quick.sh
  hydra <target>     hydra mit Standard-Wortlists
  john <hashfile>    john the ripper
  hashcat <m> <file> hashcat
  wireshark          wireshark TUI/GUI
  tshark <iface>     tshark inline mit Filter
  metasploit         msfconsole mit Workspace
  burp               BurpSuite Community
  zap                OWASP ZAP
  sqlmap <url>       sqlmap mit guten Defaults
  nikto <url>        nikto
  gobuster <url>     gobuster dir mit common.txt
  ffuf <url>         ffuf mit common.txt
  whatweb <url>      whatweb
  searchsploit <q>   searchsploit

Beispiele:
  $0 nmap 192.168.1.1
  $0 gobuster http://192.168.1.5
EOF
    exit 0
}

case "$TOOL" in
    nmap)
        [[ -n "${1:-}" ]] && require_auth "$1"
        bash "$TOOLKIT/scripts/network/full-portscan.sh" "$@"
        ;;
    masscan)
        bash "$TOOLKIT/scripts/network/masscan-quick.sh" "$@"
        ;;
    hydra)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin hydra
        target="$1"; shift
        WL_USER="$TOOLKIT/wordlists/seclists/Usernames/top-usernames-shortlist.txt"
        WL_PASS="$TOOLKIT/wordlists/rockyou.txt"
        log_info "hydra -L $WL_USER -P $WL_PASS $* $target"
        hydra -L "$WL_USER" -P "$WL_PASS" "$@" "$target"
        ;;
    john)
        require_bin john
        john "$@"
        ;;
    hashcat)
        require_bin hashcat
        hashcat "$@"
        ;;
    wireshark)
        require_bin wireshark
        wireshark "$@" &
        ;;
    tshark)
        [[ -n "${1:-}" ]] && require_bin tshark
        outdir="$(make_outdir captures tshark-${1:-any})"
        tshark -i "${1:-any}" -w "$outdir/dump.pcap"
        ;;
    metasploit|msf)
        require_bin msfconsole
        outdir="$(make_outdir scans msf)"
        msfconsole -q -x "spool $outdir/console.log; workspace -a $(basename "$outdir")"
        ;;
    burp)
        if command -v burpsuite >/dev/null 2>&1; then burpsuite &
        else log_err "burpsuite nicht installiert (sudo apt install burpsuite)"; fi
        ;;
    zap)
        if command -v zaproxy >/dev/null 2>&1; then zaproxy &
        else log_err "zaproxy nicht installiert"; fi
        ;;
    sqlmap)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin sqlmap
        outdir="$(make_outdir scans sqlmap)"
        sqlmap -u "$1" --batch --output-dir="$outdir"
        ;;
    nikto)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin nikto
        outdir="$(make_outdir scans nikto)"
        nikto -h "$1" -output "$outdir/nikto.txt"
        ;;
    gobuster)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin gobuster
        outdir="$(make_outdir scans gobuster)"
        WL="$TOOLKIT/wordlists/seclists/Discovery/Web-Content/common.txt"
        gobuster dir -u "$1" -w "$WL" -o "$outdir/gobuster.txt"
        ;;
    ffuf)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin ffuf
        outdir="$(make_outdir scans ffuf)"
        WL="$TOOLKIT/wordlists/seclists/Discovery/Web-Content/common.txt"
        ffuf -u "${1}/FUZZ" -w "$WL" -o "$outdir/ffuf.json"
        ;;
    whatweb)
        [[ -n "${1:-}" ]] && require_auth "$1"
        require_bin whatweb
        whatweb -v "$1"
        ;;
    searchsploit)
        require_bin searchsploit
        searchsploit "$@"
        ;;
    *)
        log_err "Unbekanntes Tool: $TOOL"
        $0
        exit 1
        ;;
esac
