# Playbook: Eigenes WLAN auditieren

End-to-End-Workflow zum Audit des eigenen Heimnetzes.

## Vorbereitung

### Eintragung in targets.yaml
```yaml
- id: home-wifi-ssid
  scope: MeinHeimWLAN
  type: wifi_ssid
- id: home-wifi-bssid
  scope: AA:BB:CC:11:22:33
  type: wifi_bssid
- id: home-lan
  scope: 192.168.1.0/24
  type: own_network
- id: home-router
  scope: 192.168.1.1
  type: own_device
```

### Hardware
- WLAN-Adapter mit Monitor + Injection
  (ALFA AWUS036ACM, AWUS036ACH, Panda PAU09, TP-Link TL-WN722N v1)
- Optional: 2. Adapter fuer Mehr-Channel-Scan

## Schritt 1: WPA-Audit (One-Click Wizard)

```bash
wifiwiz    # alias, oder:
bash /mnt/toolkit/scripts/wizards/wifi-audit-wizard.sh
```

Der Wizard:
1. Aktiviert Monitor-Mode + randomisiert MAC
2. Scannt 25s
3. Listet sichtbare Netze
4. Du waehlst Nummer
5. Capture 60s + deauth bei 10s
6. Fallback PMKID wenn kein 4-way-Handshake
7. Auto-Crack mit rockyou

## Schritt 2: Was wenn rockyou nicht reicht?

```bash
# Custom Wordlist mit Mask
hashcat -m 22000 -a 3 cap.hc22000 ?d?d?d?d?d?d?d?d

# Wordlist + Rules
hashcat -m 22000 cap.hc22000 wordlist.txt -r /usr/share/hashcat/rules/best64.rule

# Eigene Liste mit cewl von eigenem Blog/Profil
cewl -d 2 -m 5 https://meinblog.de -w wl.txt
hashcat -m 22000 cap.hc22000 wl.txt
```

## Schritt 3: WPS-Audit

Viele alte Router haben WPS aktiv. Pixie-Dust ist offline, sehr schnell:
```bash
bash /mnt/toolkit/scripts/wifi/wps-pixiedust.sh wlan0mon AA:BB:CC:11:22:33 6
```

Falls Pixie-Dust nicht klappt: reaver/bully (online, langsam, kann
Router-Lockout triggern):
```bash
bash /mnt/toolkit/scripts/wifi/wps-attack.sh wlan0mon AA:BB:CC:11:22:33 6 reaver
```

## Schritt 4: Router-Webinterface Audit

```bash
routerscan 192.168.1.1
# = bash /mnt/toolkit/scripts/network/router-recon.sh 192.168.1.1
```

Macht: nmap+OS, HTTP/HTTPS-Banner, SSL-Cert-Check, SNMP, UPnP, nuclei.

Default-Creds testen:
```bash
bash /mnt/toolkit/scripts/wifi/router-default-creds.sh 192.168.1.1
```

## Schritt 5: Eigene Resilienz pruefen

### PMF (Protected Management Frames)?
```bash
bash /mnt/toolkit/scripts/wifi/deauth-resilience-test.sh wlan0mon AA:BB:CC:11:22:33 10
```
Wenn deine Geraete trotz Deauth verbunden bleiben -> PMF aktiv (gut!).
Wenn sie rausfliegen -> PMF in Router-Config aktivieren (oft als
"802.11w" oder "Management Frame Protection").

### Schwaches Passwort gefunden?
- Mindestens 16 Zeichen
- Keine Woerterbuchwoerter, kein Geburtsdatum, keine Tastatur-Walks
- Empfehlung: passphrase aus 4-5 zufaelligen Woertern (diceware)

### WPS gecrackt?
- WPS im Router-Webinterface deaktivieren
- Manche Router: WPS-Button physisch abklemmen wenn moeglich

## Schritt 6: IoT-Discovery (Smart-Home)

```bash
iotscan 192.168.1.0/24
# = bash /mnt/toolkit/scripts/network/iot-discovery.sh 192.168.1.0/24
```

Findet UPnP/mDNS/SSDP-Geraete und probt typische IoT-Ports (RTSP fuer
Kameras, MQTT-Broker, etc.). Pruefe ob deine Smart-Home-Geraete unnoetig
exponiert sind.

## Schritt 7: Vollscan eigenes LAN

```bash
bash /mnt/toolkit/scripts/wizards/network-pentest-wizard.sh
# Target: 192.168.1.0/24
```

## Reporting

```bash
report "Heimnetz-Audit $(date +%F)"
```

Erzeugt Markdown-Report mit allen letzten Outputs aus `output/`.

## Anschluss

Schwachstellen-Fixes:
- Router-Firmware updaten (Auto-Update aktivieren)
- WPS aus
- PMF an
- Gastnetz nutzen fuer IoT
- Starkes WPA3-Passwort (falls Router/Geraete unterstuetzen)
- Admin-Passwort am Router aendern
- Telnet/UPnP-WAN deaktivieren
