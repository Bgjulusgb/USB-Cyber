# Pentest USB Toolkit

Dual-Mode Pentesting USB-Toolkit (Windows portable + Kali Live + Persistenz). Modular,
menu-basiert, mit hartem Auth-Gate vor jedem aktiven Test.

## Quickstart

### Linux/Kali
```bash
export TOOLKIT=/mnt/toolkit
bash "$TOOLKIT/launchers/linux/pentest-menu.sh"
```

### Windows
```cmd
E:\launchers\windows\pentest-menu.bat
```

## Sicherheits-Disclaimer

**Dieses Toolkit ist ausschliesslich fuer autorisierte Tests gedacht.** Jedes aktive Script
prueft vor dem Start, ob das Ziel in `authorized-targets/targets.yaml` gelistet ist.
Ohne Eintrag bricht der Lauf ab.

Gueltige Authorisierungs-Quellen:
- Eigene Geraete / eigenes Heimnetz
- Dediziertes Lab (isoliertes VLAN)
- Schriftlich beauftragte Pentest-Engagements
- CTF / HTB / TryHackMe (eigene VPN-Range)

Rechtlicher Rahmen DE: StGB §202a/b/c, §303a/b. Vor beruflichem Einsatz: schriftliche
Rules-of-Engagement.

## Verzeichnislayout

| Pfad                  | Inhalt                                              |
|-----------------------|-----------------------------------------------------|
| `authorized-targets/` | Auth-Liste (`targets.yaml`) + Scope-PDFs            |
| `launchers/`          | TUI-Menues fuer Linux + Windows                     |
| `scripts/lib/`        | Gemeinsame Funktionen (auth_check, logging, bootstrap) |
| `scripts/wifi/`       | WLAN-Audits                                         |
| `scripts/network/`    | nmap / nuclei / masscan Workflows                   |
| `scripts/hashcrack/`  | Hashcat-Wrapper je Hash-Typ                         |
| `scripts/forensics/`  | Forensics-Tools (eigene Geraete)                    |
| `scripts/recon-passive/` | OSINT / passive Recon (ohne Auth-Check)          |
| `scripts/reporting/`  | Report-Generatoren                                  |
| `tools/`              | Portable Windows-Binaries + Linux-AppImages         |
| `repos/`              | Geklonte GitHub-Repos (manifest-gesteuert)          |
| `wordlists/`          | rockyou, SecLists, eigene Listen                    |
| `output/`             | Captures, Scans, Cracked, Reports, Audit-Log        |
| `docs/`               | Cheatsheets + Playbooks                             |

## Erst-Setup

1. Hardware-Vorbereitung: siehe `docs/playbooks/usb-setup.md`
2. Kali konfigurieren: siehe `docs/playbooks/kali-config.md`
3. Bootstrap ausfuehren (Repos / NPM / Win-Downloads):
   ```bash
   bash scripts/lib/bootstrap.sh
   ```
4. Erstes Target in `authorized-targets/targets.yaml` eintragen
5. Smoke-Test gegen eigenes Geraet

## Update

```bash
bash scripts/lib/bootstrap.sh
```

## Audit-Log

Jeder aktive Lauf wird in `output/audit.log` geloggt:
```
2026-06-23T10:42:11+00:00 | user | quick-discovery.sh | 192.168.1.0/24
```

## Lizenz / Verantwortung

Toolkit-Code: MIT (siehe LICENSE). Geklonte Third-Party-Tools: jeweilige Originallizenz.
Du allein bist verantwortlich, dass jeder Einsatz autorisiert ist.
