# Testing-Checkliste vor dem ersten Einsatz (Phase 9)

Vor dem ersten echten Einsatz vollstaendig auf eigenem Equipment durchspielen.

## Hardware-Boot

- [ ] Stick bootet UEFI-Mode auf Test-Laptop A
- [ ] Stick bootet Legacy-BIOS-Mode auf Test-Laptop B
- [ ] Persistenz haelt ueber Reboot
  ```bash
  touch /root/persistence-test && reboot
  # nach Reboot: ls /root/persistence-test
  ```
- [ ] TOOLKIT-Partition wird auto-mounted in Kali (`mount | grep toolkit`)
- [ ] TOOLKIT-Partition als Laufwerk in Windows sichtbar

## Bootstrap

- [ ] `bash scripts/lib/bootstrap.sh` laeuft ohne fatal errors
- [ ] Alle GitHub-Repos in `repos/` vorhanden
- [ ] NPM-Pakete in `npm-tools/node_modules/` vorhanden
- [ ] Windows-Downloads in `tools/windows-portable/_downloads/` vorhanden

## Auth-Gate

- [ ] Aktiver Scan gegen Target das NICHT in `targets.yaml` steht -> Abbruch
- [ ] Aktiver Scan gegen Target das IN `targets.yaml` steht -> Lauf
- [ ] Eintrag in `output/audit.log` wird geschrieben

## WiFi

- [ ] `iw dev` zeigt Adapter
- [ ] `wifi-monitor-start.sh` schaltet erfolgreich in Monitor-Mode
- [ ] Handshake-Capture gegen eigenen Router laeuft
- [ ] pcap-to-hashcat erzeugt 22000-File
- [ ] crack-wpa mit testweise gesetztem schwachen WPA-Key crackt

## Network

- [ ] quick-discovery findet >= 1 Host im eigenen Netz
- [ ] full-portscan gegen eigenen Server liefert Service-Versionen
- [ ] vuln-scan laeuft (auch ohne Findings)

## Hashcracking

- [ ] hashcat -I findet die GPU (oder CPU-Fallback)
- [ ] crack-md5 mit Test-Hash `5f4dcc3b5aa765d61d8327deb882cf99` -> "password"
- [ ] outfile in `output/cracked/` angelegt

## Forensics

- [ ] dump-sam gegen gemountete Windows-Test-VM kopiert Hives
- [ ] (Windows) wifi-saved-pw.ps1 listet eigene WLAN-Profile

## Reporting

- [ ] gen-report erzeugt Markdown-File ohne crash
- [ ] nmap-to-html erzeugt brauchbare HTML

## Windows-Launcher

- [ ] `pentest-menu.bat` startet PS1
- [ ] Menue navigierbar, mind. 1 Submenu funktioniert
- [ ] Auth-Check in PS1 blockiert nicht-whitelisted Target

## Audit-Log Sicht-Check

- [ ] `output/audit.log` enthaelt mind. 5 Eintraege aus den Tests
- [ ] Jeder Eintrag: ISO-Datum, User, Script, Target
