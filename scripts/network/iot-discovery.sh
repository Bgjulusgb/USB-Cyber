#!/usr/bin/env bash
# iot-discovery.sh - findet IoT-Geraete im eigenen LAN (UPnP, mDNS, SSDP, MQTT)
set -euo pipefail

TOOLKIT="${TOOLKIT:-/mnt/toolkit}"
source "$TOOLKIT/scripts/lib/logging.sh"
source "$TOOLKIT/scripts/lib/auth_check.sh"

NET="${1:-}"
[[ -z "$NET" ]] && { echo "Usage: $0 <network-cidr>"; exit 1; }
require_auth "$NET"

outdir="$(make_outdir scans iot-${NET//[\/.]/_})"

log_info "1/4 mDNS via avahi-browse"
if command -v avahi-browse >/dev/null 2>&1; then
    timeout 15 avahi-browse -art 2>/dev/null > "$outdir/mdns.txt" || true
fi

log_info "2/4 SSDP / UPnP"
python3 - > "$outdir/ssdp.txt" <<'PYEOF' || true
import socket, time
m = '\r\n'.join([
    'M-SEARCH * HTTP/1.1',
    'HOST: 239.255.255.250:1900',
    'MAN: "ssdp:discover"',
    'MX: 3',
    'ST: ssdp:all',
    '', ''
])
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(4)
s.sendto(m.encode(), ('239.255.255.250', 1900))
end = time.time() + 4
while time.time() < end:
    try:
        data, addr = s.recvfrom(8192)
        print(f"=== {addr[0]}:{addr[1]} ===")
        print(data.decode(errors='ignore'))
    except socket.timeout:
        break
PYEOF

log_info "3/4 nmap IoT-relevante Ports"
sudo nmap -p 80,443,554,1883,5353,1900,8080,8883,8888,49152,8554 -sV \
    --script "ssdp-info,upnp-info,mqtt-subscribe,broadcast-listener" \
    "$NET" -oA "$outdir/nmap-iot" 2>&1 | tee "$outdir/nmap-iot.txt"

log_info "4/4 RTSP-Streams probe (Kameras)"
for ip in $(grep -oE 'Nmap scan report for [0-9.]+' "$outdir/nmap-iot.txt" | awk '{print $NF}'); do
    code="$(curl -ks -m 3 -o /dev/null -w '%{http_code}' "rtsp://$ip:554/" 2>/dev/null)"
    [[ -n "$code" && "$code" != "000" ]] && echo "  $ip:554 -> $code" >> "$outdir/rtsp.txt"
done

log_ok "$outdir"
