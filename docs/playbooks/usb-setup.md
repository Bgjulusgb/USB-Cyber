# USB-Hardware Setup (Phase 1)

Anleitung fuer das physische Vorbereiten des USB-Sticks mit drei Partitionen.

## Material

- USB-Stick >= 64 GB, USB 3.1 oder schneller
- Empfohlen: SanDisk Extreme Pro, Samsung Bar Plus
  (Random IO ist wichtiger als sequentieller Durchsatz)

## Schritte

### 1. Kali-ISO laden + verifizieren

Von https://www.kali.org/get-kali/ die Live-ISO (Edition `live`, amd64) ziehen.
SHA256 verifizieren:

```bash
wget https://cdimage.kali.org/current/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

### 2. Stick mit dd schreiben (Linux)

```bash
# Vorsicht: of= muss der richtige Stick sein
sudo umount /dev/sdX*
sudo dd if=kali-linux-202X.X-live-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Mit Rufus (Windows): "DD-Mode" auswaehlen, nicht "ISO-Mode".

### 3. Partitionen anlegen

Nach dem dd hat der Stick zwei ISO-Partitionen. Wir erweitern um eine
Persistenz-Partition (ext4) und eine TOOLKIT-Partition (exFAT):

```bash
sudo parted /dev/sdX
# (parted) print
# (parted) mkpart primary ext4 START END         # ~20 GB Persistenz
# (parted) mkpart primary fat32 START 100%       # Rest fuer TOOLKIT
# (parted) quit

# Filesysteme
sudo mkfs.ext4 -L persistence /dev/sdX3
sudo mkfs.exfat -n TOOLKIT /dev/sdX4
```

### 4. Persistenz aktivieren

```bash
sudo mkdir -p /mnt/p
sudo mount /dev/sdX3 /mnt/p
echo "/ union" | sudo tee /mnt/p/persistence.conf
sudo umount /mnt/p
```

### 5. Boot-Test

- Stick einstecken
- BIOS/UEFI-Bootmenue (meist F12/F11/F8)
- "Live USB Persistence" auswaehlen
- Wenn Datei in /root angelegt, neu gebootet, noch da -> Persistenz OK

### 6. TOOLKIT-Partition befuellen

In Kali oder Windows:

```bash
# Diesen Repo-Inhalt nach /mnt/toolkit (bzw. E:\ unter Windows) kopieren
sudo mount -L TOOLKIT /mnt/toolkit
git clone https://github.com/bgjulusgb/usb-cyber.git /tmp/toolkit-src
cp -r /tmp/toolkit-src/* /mnt/toolkit/
```

### 7. Auto-Mount in Persistenz

Damit TOOLKIT bei jedem Kali-Boot gemountet wird, fstab in Persistenz:

```bash
sudo mkdir -p /mnt/p
sudo mount /dev/sdX3 /mnt/p
sudo mkdir -p /mnt/p/rw/etc
# fstab snippet (per persistence overlay)
echo 'LABEL=TOOLKIT /mnt/toolkit exfat defaults,uid=1000,gid=1000 0 0' \
    | sudo tee -a /mnt/p/rw/etc/fstab
sudo umount /mnt/p
```

## Troubleshooting

- **Stick bootet nicht (UEFI):** Secure Boot deaktivieren oder signiertes Image (Kali signed)
- **Persistenz wird nicht erkannt:** Partition-Label muss exakt `persistence` sein, Datei
  `persistence.conf` mit `/ union` (Zeilenende beachten!)
- **TOOLKIT in Kali nicht beschreibbar:** mount-options `uid=1000,gid=1000` setzen
- **exFAT in Linux:** ggf. `sudo apt install exfatprogs` nachinstallieren




https://copilot.microsoft.com/shares/pages/b1xxomDFSfL4cQXn9VSRJ
