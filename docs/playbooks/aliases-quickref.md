# Aliase Quickref

Nach `bash scripts/kali-setup/install-aliases.sh` und neuer Shell:

| Alias        | Was                                          |
|--------------|----------------------------------------------|
| `pt`         | Hauptmenue (Toolkit)                          |
| `targets`    | targets.yaml editieren                        |
| `audit`      | Audit-Log live tail                           |
| `wifimon`    | Monitor-Mode starten                          |
| `wifiscan`   | passiver WiFi-Scan                            |
| `wifiwiz`    | WiFi-Audit-Wizard (alles in einem)            |
| `discover`   | nmap -sn (auth-checked)                       |
| `portscan`   | nmap full mit Output                          |
| `arpscan`    | arp-scan LAN                                  |
| `routerscan` | Router-Recon                                  |
| `iotscan`    | IoT-Discovery                                 |
| `crack`      | auto Hash-Detect + crack                      |
| `hashid`     | nur Hash-Typ identifizieren                   |
| `laptopwiz`  | Laptop-Daten-Wizard                           |
| `mountlap`   | Laptop-Partitionen mounten                    |
| `dumpcreds`  | Windows-Credentials dumpen                    |
| `sniff`      | tcpdump auf Interface                         |
| `mitm`       | bettercap ARP-Spoof + Sniff                   |
| `osint`      | Domain OSINT                                  |
| `subs`       | Subdomain-Enum                                |
| `report`     | Markdown-Report generieren                    |
| `ptupdate`   | Toolkit + Kali komplett updaten               |
| `cdt`        | cd ins Toolkit                                |
| `cdo`        | cd ins Output                                 |
| `nm <t>`     | wrapper Funktion fuer nmap full               |
| `randmac <i>`| MAC eines Interfaces randomisieren            |

## Quick-Tool (vermittelnde Wrapper)

```bash
# Direkt nutzen:
bash /mnt/toolkit/scripts/wizards/quick-tool.sh <tool> [args]

# Beispiele:
quick-tool.sh nmap 192.168.1.1
quick-tool.sh hydra 192.168.1.1 ssh
quick-tool.sh sqlmap http://test.local/index.php?id=1
quick-tool.sh gobuster http://test.local
```
