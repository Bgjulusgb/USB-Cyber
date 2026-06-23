# Kali-Konfiguration nach dem ersten Boot (Phase 2)

## Im Live-System (mit Persistenz aktiv)

### Update

```bash
sudo apt update && sudo apt -y full-upgrade
```

### Toolkit mounten

```bash
sudo mkdir -p /mnt/toolkit
sudo mount -L TOOLKIT /mnt/toolkit
ln -s /mnt/toolkit ~/toolkit
```

### Auto-Mount Eintrag (siehe usb-setup.md Schritt 7)

```bash
echo 'LABEL=TOOLKIT /mnt/toolkit exfat defaults,uid=1000,gid=1000 0 0' \
    | sudo tee -a /etc/fstab
```

### Pflicht-Tools nachinstallieren

```bash
sudo apt install -y \
    nmap masscan \
    aircrack-ng airmon-ng \
    hcxtools hcxdumptool \
    hashcat john \
    wordlists seclists \
    python3-yaml \
    enum4linux-ng \
    whiptail dialog \
    macchanger
```

Optionale Tools mit eigener Repo-Setup:
- NetExec (`pipx install netexec`)
- name-that-hash (`pipx install name-that-hash`)
- nuclei / subfinder / httpx (`apt install nuclei` oder Bootstrap-Repos)

### Bootstrap ausfuehren

```bash
cd ~/toolkit
bash scripts/lib/bootstrap.sh
```

### Wordlists vorbereiten

```bash
bash scripts/lib/manage-wordlists.sh rockyou
bash scripts/lib/manage-wordlists.sh seclists
```

### Desktop-Launcher anlegen

```bash
cp ~/toolkit/launchers/linux/pentest-menu.desktop ~/Desktop/
chmod +x ~/Desktop/pentest-menu.desktop
```

### Erstes Target eintragen

```bash
nano ~/toolkit/authorized-targets/targets.yaml
```

Beispiel (eigener Router):
```yaml
targets:
  - id: home-router
    scope: 192.168.1.0/24
    type: own_network
    authorization: own_property
```

### Smoke-Test

```bash
bash ~/toolkit/scripts/network/quick-discovery.sh 192.168.1.0/24
```

Wenn Auth-Check ablaeuft -> Eintrag in targets.yaml fehlt oder falsch.

## Wartung

Wochentlich:
```bash
sudo apt update && sudo apt -y full-upgrade
bash ~/toolkit/scripts/lib/bootstrap.sh
hashcat --version && nmap --version    # sanity
```

Backup der Toolkit-Partition als Image:
```bash
sudo dd if=/dev/sdX4 of=~/toolkit-backup-$(date +%F).img bs=4M status=progress
```
