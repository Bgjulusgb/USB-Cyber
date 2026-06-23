# Mode-Switch: Windows-Host vs Kali-Live vs Kali-VM (Phase 8)

Es gibt keinen aktiven "Mode-Switch" - der Mode ergibt sich aus dem
Bootverhalten. Die `TOOLKIT`-Partition ist in allen Modi mountbar, dh.
`authorized-targets/`, `output/`, `wordlists/` sind geteilt.

## Windows-Host-Mode

1. Stick in laufendes Windows einstecken
2. Laufwerk `TOOLKIT` (z.B. `E:`) oeffnen
3. `launchers/windows/pentest-menu.bat` doppelklicken
4. Tools laufen als portable Binaries unter dem User-Profil

Limitierungen:
- Kein WiFi-Monitor-Mode (Treiber-bedingt)
- Kein chntpw etc., dafuer LaZagne und PS-Forensics
- Manche AV-Loesungen melden Tools (Exclusion noetig)

## Kali-Live-Mode

1. Stick einstecken, Rechner einschalten
2. BIOS/UEFI-Bootmenue (F12/F8/F11)
3. Stick auswaehlen -> "Live USB Persistence"
4. Desktop-Launcher `Pentest USB Toolkit` doppelklicken
   oder `bash ~/toolkit/launchers/linux/pentest-menu.sh`

Vorteile:
- Voller Werkzeugkasten (aircrack, hashcat, nmap nativ)
- Persistenz fuer eigene Configs / WPA-Captures / cracked Hashes
- GPU-Treiber u.U. besser fuer hashcat (proprietaere NVIDIA-Treiber)

## Kali-VM-Mode (Hybrid)

Wenn du nicht rebooten willst:

1. Windows-Host bootet normal
2. VirtualBox/VMware/Hyper-V mit Kali-VM
3. USB-Stick an VM durchreichen
4. In Kali-VM mount + Menue starten

Vorteile:
- Kein Reboot
- Spotlight-Tests (Webapp-Pentest) bequem von der VM
Nachteile:
- WiFi-Monitor-Mode i.d.R. nicht moeglich (USB-WiFi passthrough manchmal)
- Hashcat-GPU-Performance schlechter

## Gemeinsame Daten

In allen drei Modi gleich:
- `authorized-targets/targets.yaml` -> Auth-Gate
- `output/audit.log` -> Lueckenloses Audit-Log
- `wordlists/`, `repos/`, `tools/` -> Wiederverwendung
