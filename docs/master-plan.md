# Pentest-USB Master-Plan & Build-Prompt (Referenz)

> Dies ist die Original-Spezifikation, nach der das Toolkit gebaut wurde.
> Bei Konflikten zwischen Doku und Implementierung -> Implementierung ist Wahrheit.

**Zweck:** Aufbau eines Dual-Mode USB-Sticks (Windows-Host + Kali-Live) mit modularem,
klick-/menübasiertem Script-Arsenal für autorisierte Penetration-Tests, WiFi-Audits,
Hash-Cracking und Forensik auf eigenen Geräten.

## 0. Scope & rechtlicher Rahmen

Alle aktiven Tests setzen voraus, dass das Ziel in `authorized-targets/targets.yaml`
steht - sonst weigern sich die Scripts zu starten. Rechtlicher Bezugsrahmen DE:
StGB §202a/b/c, §303a/b.

Gueltige Authorisierungen:
- Eigenes Heimnetz / eigene Geraete
- Dediziertes Lab (isoliertes VLAN, kein Internet-Routing)
- Schriftlich beauftragte Engagements mit unterschriebenem Rules-of-Engagement
- CTF/HTB/THM-Labs (eigene VPN-Range)

## 1. USB-Layout (drei Partitionen)

| # | Partition     | FS      | Groesse | Zweck                       |
|---|---------------|---------|---------|-----------------------------|
| 1 | KALI-LIVE     | ISO9660 | ~5 GB   | Kali Live-Boot DD-Image     |
| 2 | persistence   | ext4    | 20 GB   | Kali Persistenz             |
| 3 | TOOLKIT       | exFAT   | Rest    | Scripts/Tools/Captures (W+L)|

## 2. Phasen

1. USB physisch vorbereiten -> `docs/playbooks/usb-setup.md`
2. Kali konfigurieren -> `docs/playbooks/kali-config.md`
3. Repo- und NPM-Manifest -> `repos/manifest.yaml`
4. Bootstrap-Script -> `scripts/lib/bootstrap.sh`
5. Core-Library Auth+Logging -> `scripts/lib/auth_check.{sh,ps1}`, `logging.sh`
6. Scripts-Katalog -> `scripts/{wifi,network,hashcrack,forensics,recon-passive,reporting}/`
7. Launcher-Menues -> `launchers/{linux,windows}/`
8. Mode-Switch (passiv) -> `docs/playbooks/mode-switch.md`
9. Testing-Checkliste -> `docs/playbooks/testing-checklist.md`

## 3. Erweiterungen (spaeter)

- Caldera/Sliver C2 fuer Red-Team-Engagements
- AutoRecon als Recon-Wrapper
- GoPhish portable fuer authorisierte Phishing-Tests
- Burp Suite Community
- MITRE ATT&CK Navigator als statische HTML
- Hashtopolis-Worker-Image fuer dedizierte Crack-Maschinen

## 4. Wartung

```bash
cd /mnt/toolkit
bash scripts/lib/bootstrap.sh
sudo apt update && sudo apt -y full-upgrade
hashcat --version && nmap --version
```

Backup:
```bash
sudo dd if=/dev/sdX3 of=~/toolkit-backup-$(date +%F).img bs=4M status=progress
```

---
**Version:** 1.0
**Basis:** Kali 2026.1, Kernel 6.18
