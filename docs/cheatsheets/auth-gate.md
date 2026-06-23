# Auth-Gate Cheatsheet

## Wann muss ich Eintraege machen?

Vor JEDEM aktiven Test (Scan, Probe, Exploit, Capture, Auth-Versuch) gegen ein
externes Ziel. NICHT noetig fuer rein passive Schritte wie OSINT.

## Eintragsbeispiele

### Eigener Router
```yaml
- id: home-router
  scope: 192.168.1.1
  type: own_device
  authorization: own_property
```

### Eigenes LAN
```yaml
- id: home-lan
  scope: 192.168.1.0/24
  type: own_network
  authorization: own_property
```

### WiFi (BSSID + SSID)
```yaml
- id: home-wifi-ssid
  scope: MeinHeimWLAN
  type: wifi_ssid
- id: home-wifi-bssid
  scope: AA:BB:CC:11:22:33
  type: wifi_bssid
```

### Engagement
```yaml
- id: acme-2026q3
  scope: webapp.acme.example
  type: engagement
  valid_until: 2026-09-30
  authorization: engagements/2026q3-acme-roe.pdf
```

### CTF Range
```yaml
- id: htb
  scope: 10.10.0.0/16
  type: ctf
  authorization: htb_subscription
```

## Wie funktioniert der Match?

`auth_check.sh` macht Substring-Match in beide Richtungen:

- Target enthaelt Scope (z.B. Target=`192.168.1.50`, Scope=`192.168.1.`) -> match
- Scope enthaelt Target (z.B. Target=`192.168.1.0/24`, Scope=`192.168.1.0/24`) -> match

Das ist absichtlich grosszuegig, weil sonst CIDR-Math noetig waere. Sei
diszipliniert mit den Eintraegen.

## Audit-Log

Jeder erfolgreiche Auth-Check schreibt nach `output/audit.log`:
```
2026-06-23T10:42:11+00:00 | myuser | full-portscan.sh | 192.168.1.50
```

Behalte das Log dauerhaft als Beleg fuer dich. Bei Engagements gehoert das in
den Bericht-Anhang.

## Nach einem Engagement

Eintraege wieder aus `targets.yaml` entfernen, sonst sammelt sich Scope-Creep an.
