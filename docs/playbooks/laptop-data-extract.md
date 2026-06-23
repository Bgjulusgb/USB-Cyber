# Playbook: Daten + Passwoerter vom alten Laptop kopieren

Szenario: Alter Laptop liegt rum, du willst alle eigenen Daten und
Credentials darauf in Sicherheit bringen. Live-Boot Kali vom USB-Stick auf
dem alten Laptop, dann Wizard starten.

## Voraussetzungen

- [ ] Alter Laptop ist DEIN Eigentum (in `targets.yaml` als `own_device`)
- [ ] Toolkit-USB-Stick hat genug Platz fuer die Daten
  - Faustregel: USB-Stick-Groesse >= 1.5x Daten-Volumen
- [ ] Stromversorgung am Laptop (Akku reicht oft nicht)

## Schritt 0: Authorisierung eintragen

```bash
nano /mnt/toolkit/authorized-targets/targets.yaml
```

Eintrag:
```yaml
- id: old-thinkpad
  scope: old-thinkpad
  type: own_device
  authorization: own_property
  notes: ThinkPad T470, Serien-Nr XYZ, Kauf 2018
```

## Schritt 1: Live-Boot

1. USB-Stick in alten Laptop einstecken
2. Einschalten, Bootmenue (F12/F8/F2/Del)
3. "Live USB Persistence" oder "Live (forensic mode)" waehlen
   - **forensic mode**: keine Auto-Mounts, sauberer Forensik-Start
   - **persistence**: bequem, eigene Configs werden gespeichert

## Schritt 2: Wizard starten

```bash
pt   # Hauptmenue (alias)
# -> L: Laptop-Daten-Extract
# -> W: WIZARD

# Oder direkt:
bash /mnt/toolkit/scripts/wizards/laptop-extract-wizard.sh
```

Der Wizard fragt nur das Noetigste und macht den Rest automatisch.

## Schritt 3: Was wird gesichert?

### Variante "ALLE 1-5" (Standard):
1. **Credentials**
   - SAM/SYSTEM/SECURITY/SOFTWARE Hives
   - NTUSER.DAT pro Benutzer
   - DPAPI Master Keys (User + System)
   - WLAN-Profile XML (mit verschluesseltem Key)
   - Browser-Datenbanken (Chrome/Edge/Firefox)
   - automatisch NTLM-Hashes extrahiert (impacket-secretsdump)
2. **User-Daten**
   - Desktop, Documents, Downloads, Pictures, Videos, Music
   - OneDrive lokaler Cache
   - AppData: Outlook, Thunderbird, Firefox-Profile, Chrome-User-Data
3. **Cred-Search**
   - Grep nach `password=`, `api_key=`, `BEGIN PRIVATE KEY`, etc.
4. **SSH/PuTTY/GPG**
5. **Emails**
   - PST, OST, Thunderbird-Profiles, Apple Mail

### Optional zusaetzlich:
6. **VM-Images** (.vmdk/.vdi/.qcow2 etc.)
7. **Vollscan Dokumente+Media** (rekursiv, Filter auf Endung)
8. **Forensisches dd-Image der Disk** (sehr gross, aber komplett)

## Schritt 4: Auswertung in Kali

### NTLM-Hashes cracken
```bash
crack /mnt/toolkit/output/laptop-extract/old-thinkpad-creds-*/parsed/ntlm-hashes.txt
```

### Browser-Passwoerter
Schnellster Weg: alter Laptop normal booten, LaZagne ausfuehren
(`tools/windows-portable/LaZagne.exe all`). LaZagne nutzt den live-User-DPAPI
und entschluesselt alle Passwoerter sofort.

Offline ist aufwendiger - braucht DPAPI-Master-Key entschluesselt mit
User-Passwort oder NTLM-Hash.

### WLAN-Klartextkeys
Schneller: normal in Windows booten, dann
```cmd
netsh wlan show profile name="SSID" key=clear
```

Offline: dpapick3 mit User-Master-Key.

### Daten ueberpruefen
```bash
cd /mnt/toolkit/output/laptop-extract
du -sh */
ls old-thinkpad-userdata-*/users/*/Documents
```

## Schritt 5: Sichern auf externes Backup

Toolkit-Stick ist nicht dafuer gedacht, dauerhaft Daten zu halten:
```bash
# Auf externe Platte / NAS kopieren
rsync -avP /mnt/toolkit/output/laptop-extract/ /mnt/external/laptop-archive/
```

## Schritt 6: Laptop entsorgen / loeschen

Wenn der Laptop weg soll, vorher sicher loeschen:
```bash
# Komplette Disk schreddern (Stunden, aber gruendlich)
sudo shred -v -n 1 -z /dev/nvme0n1

# Schneller bei SSD: ATA Secure Erase via hdparm
sudo hdparm --user-master u --security-set-pass p /dev/sdX
sudo hdparm --user-master u --security-erase p /dev/sdX
```

## Troubleshooting

### "Mount failed: BitLocker erkannt"
- Recovery-Key suchen: in deinem Microsoft-Konto (account.microsoft.com/devices/recoverykey)
  oder in der AD/AAD wenn Firmenlaptop
- `bash /mnt/toolkit/scripts/laptop-extract/unlock-bitlocker.sh <laptop-id> <device>`

### "secretsdump: kein Output"
- Hives sind in-use? Live-Windows muss runter sein
- Falsche Pfade? `ls -la $outdir/hives/`
- `apt install impacket-scripts` checken

### Laptop hat kein BIOS-Bootmenue
- Klassische BIOS-Tasten: F2/F8/F10/F12/Del/Esc
- Surface: Lauter-Taste halten beim Einschalten
- MacBook: Option/Alt halten

### Persistence funktioniert nicht
- `forensic mode` deaktiviert persistence absichtlich
- Persistence-Partition Label muss exakt `persistence` heissen

### Disk-Image laeuft voll
- Splitting: `dd | split -b 4G ...`
- Komprimieren: `dd | gzip > image.gz`
- Statt Vollimage selektiv kopieren (Schritte 1-5)
