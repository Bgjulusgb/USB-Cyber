# Pentest USB Toolkit

Dual-Mode Pentesting USB-Toolkit (Windows portable + Kali Live + Persistenz). Modular,
menu-basiert, mit hartem Auth-Gate vor jedem aktiven Test.

## Quickstart

### Linux/Kali
```bash
export TOOLKIT=/mnt/toolkit
bash "$TOOLKIT/launchers/linux/pentest-menu.sh"
# oder nach install-aliases:  pt
```

### Windows
```cmd
E:\launchers\windows\pentest-menu.bat
```

## Erst-Setup (einmalig nach Live-Boot)

```bash
bash /mnt/toolkit/scripts/kali-setup/first-boot.sh
```

Macht in einem Lauf:
- Locale + Tastatur DE
- Zeitzone Europe/Berlin
- Voll-Update (apt, pipx)
- Pflicht-Tools (nmap, hashcat, aircrack, hcxtools, impacket, NetExec ...)
- Toolkit-Auto-Mount in fstab
- Bootstrap (Repos, NPM, Win-Downloads)
- Wordlists (rockyou, SecLists)
- Desktop-Launcher
- Aliase (pt, wifiwiz, crack, laptopwiz, ...)

## Sicherheits-Disclaimer

**Ausschliesslich fuer autorisierte Tests.** Jedes aktive Script prueft vor dem
Start, ob das Ziel in `authorized-targets/targets.yaml` gelistet ist. Ohne Eintrag
bricht der Lauf mit Exit-Code 2 ab. Audit-Log unter `output/audit.log`.

Gueltige Authorisierungs-Quellen:
- Eigene Geraete / eigenes Heimnetz
- Dediziertes Lab (isoliertes VLAN)
- Schriftlich beauftragte Pentest-Engagements
- CTF / HTB / TryHackMe (eigene VPN-Range)

Rechtlicher Rahmen DE: StGB §202a/b/c, §303a/b. Vor beruflichem Einsatz: schriftliche
Rules-of-Engagement.

## Was kann das Toolkit?

### Wizards (One-Shot Workflows)
- **WiFi-Audit**: scan -> capture -> deauth -> PMKID-Fallback -> auto-crack
- **Laptop-Daten-Extract**: mount -> creds -> userdata -> emails -> keys (alles vom alten Laptop)
- **Network-Pentest**: discovery -> portscan -> vuln -> SMB-enum -> report
- **Crack-Anything**: auto-detect Hash-Typ und richtigen hashcat-Mode

### WiFi (eigenes WLAN)
- Passiver Scan, Monitor-Mode mit MAC-Random
- Handshake-Capture mit targeted deauth
- PMKID-Attack (clientless)
- WPS reaver/bully + Pixie-Dust offline
- wifite2 mit Auto-Filter auf authorisierte BSSIDs
- WPA-Quick-Crack interaktiv
- Deauth-Resilienz-Test (PMF-Check)
- Router-Default-Cred-Test
- Evil-Twin (Lab-only mit doppelter Bestaetigung)

### Network
- Quick-Discovery (nmap -sn)
- ARP-Scan (LAN sehr schnell)
- Masscan (extrem schnell)
- Full Portscan mit Service-Detection
- Vuln-Scan (nmap+nuclei)
- Web-Recon (subfinder->httpx->nuclei)
- SMB-Enum (enum4linux+NetExec)
- Router-Recon (Vollanalyse eigener Router)
- IoT-Discovery (UPnP/mDNS/SSDP/RTSP/MQTT)

### Hash-Cracking
8 Wrapper je Hash-Typ (NTLM, NTLMv2, WPA, bcrypt, MD5, SHA256, Kerberos, ZIP) plus
Auto-Detect via name-that-hash. Identische Args: `--wordlist`, `--rules`, `--mask`.

### Laptop-Daten-Extract (alter eigener Laptop)
- Auto-Mount aller Partitionen (read-only)
- BitLocker entsperren (Recovery-Key/Passwort/BEK)
- SAM/SYSTEM/SECURITY Hives + auto NTLM-Extract
- Browser-Datenbanken (Chrome/Edge/Firefox/Brave)
- WLAN-Profile + DPAPI-Keys
- User-Daten rsync (Desktop/Docs/Downloads/Pics/Videos/Email)
- SSH/PuTTY/GnuPG/Kerberos-Keys
- Outlook PST + Thunderbird + Apple Mail
- VM-Images (.vmdk/.vdi/.qcow2)
- Cred-Search (grep nach Patterns)
- Volldokumenten-Scan rekursiv
- Forensisches dd-Vollimage mit SHA256

### MITM (eigenes LAN)
- tcpdump-Sniff mit Rotation
- ARP-Spoof bidirektional
- bettercap Quick-Caplet
- Responder (LLMNR/NBT-NS)
- DNS-Spoof via dnsmasq

### Forensics (eigene Geraete, Windows-Live)
- chntpw Passwort-Reset
- SAM-Dump
- Browser-Creds (Win-Live)
- WLAN-Klartextkeys (netsh)
- BitLocker-Recovery-Liste
- LaZagne-Wrapper

### Passive Recon (OSINT)
- Domain (whois/DNS/crt.sh/theHarvester)
- Email (HIBP)
- Subdomain-Enum (subfinder+amass)

### Quick-Tool Wrapper
`scripts/wizards/quick-tool.sh` fuer alle gangbaren Kali-Tools mit Auth-Check vorab:
nmap, masscan, hydra, john, hashcat, wireshark, tshark, metasploit, burp, zap,
sqlmap, nikto, gobuster, ffuf, whatweb, searchsploit.

### Kali-Setup-Komfort
- first-boot.sh: Locale/Keyboard/Update/Tools in einem Lauf
- full-update.sh: apt+pipx+bootstrap+nuclei-templates
- install-extras.sh: optionale Tools (Burp, Bloodhound, MSF, ...)
- hidpi-toggle.sh / undercover-toggle.sh
- install-aliases.sh: pt, wifiwiz, crack, ...

### Reporting
Markdown-Sammelreport, nmap.xml->HTML, Screenshots

## Verzeichnislayout

```
.
├── authorized-targets/
│   ├── targets.yaml         # ZENTRALE Whitelist
│   └── engagements/         # PDF-Scope-Dokumente
├── launchers/
│   ├── linux/               # whiptail-Menues
│   └── windows/             # PowerShell + bat
├── scripts/
│   ├── lib/                 # auth_check, logging, bootstrap, selftest
│   ├── wifi/                # 11 WiFi-Tools
│   ├── network/             # 9 Network-Tools (+ 4 PowerShell)
│   ├── hashcrack/           # 8 Wrapper + identify
│   ├── forensics/           # eigene Geraete live
│   ├── laptop-extract/      # 9 Tools fuer alten Laptop
│   ├── mitm/                # 5 MITM-Tools
│   ├── recon-passive/       # OSINT
│   ├── reporting/           # Markdown/HTML
│   ├── kali-setup/          # Komfort (Locale, Update, Aliase)
│   └── wizards/             # 5 One-Shot-Wizards
├── tools/windows-portable/  # nmap, hashcat, putty, sysinternals, ...
├── repos/                   # Bootstrap-managed (SecLists, NetExec, ...)
├── wordlists/               # rockyou, seclists symlink, custom
├── output/                  # captures, scans, cracked, laptop-extract, reports
├── docs/
│   ├── playbooks/           # Schritt-fuer-Schritt Workflows
│   └── cheatsheets/         # Tool-Referenzen
└── npm-tools/               # node-basierte Tools
```

## Wichtige Playbooks

- `docs/playbooks/usb-setup.md`       — Stick physisch vorbereiten
- `docs/playbooks/kali-config.md`     — Kali nach Erst-Boot
- `docs/playbooks/own-wifi-audit.md`  — Eigenes WLAN auditieren
- `docs/playbooks/laptop-data-extract.md` — Alter Laptop, alles sichern
- `docs/playbooks/mode-switch.md`     — Windows vs Kali-Live vs Kali-VM
- `docs/playbooks/testing-checklist.md`— Vor erstem echten Einsatz
- `docs/playbooks/aliases-quickref.md`— Quick-Aliase
- `docs/playbooks/windows-tools.md`   — Portable Win-Tools laden

## Update

```bash
ptupdate   # alias, oder:
bash /mnt/toolkit/scripts/kali-setup/full-update.sh
```

## Audit-Log

Jeder Auth-Check schreibt:
```
2026-06-23T10:42:11+00:00 | user | wifi-audit-wizard.sh | AA:BB:CC:11:22:33
```

`tail -f` per Alias: `audit`

## Lizenz / Verantwortung

Toolkit-Code: MIT (siehe LICENSE). Third-Party-Tools jeweils Originallizenz.
Du allein bist verantwortlich, dass jeder Einsatz autorisiert ist.
