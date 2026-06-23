# nmap Cheatsheet

## Discovery

```bash
nmap -sn 192.168.1.0/24                  # ping sweep
nmap -PR 192.168.1.0/24                  # ARP scan (LAN)
nmap -PE -PP -PS80,443 -PA80,443 target  # mehrere probes
```

## Port-Scan

```bash
nmap -sS -p- target                       # full TCP SYN
nmap -sS --top-ports 1000 target          # top 1000
nmap -sU --top-ports 100 target           # UDP top 100
nmap -sV -sC -p- --min-rate 1000 target   # toolkit default
```

## Service / OS

```bash
nmap -sV target
nmap -O target
nmap -A target                            # aggressive (loud!)
```

## NSE Scripts

```bash
nmap --script-help "smb-*"                # was gibt's
nmap --script vuln target
nmap --script smb-enum-shares,smb-enum-users target
nmap --script ssl-enum-ciphers -p 443 target
```

## Output

```bash
nmap -oA basename target                  # all formats
nmap -oN out.txt -oX out.xml target
nmap -oG out.gnmap target | grep open
```

## Toolkit-Wrapper

- `scripts/network/quick-discovery.sh <subnet>` -> sn-scan + multi-format output
- `scripts/network/full-portscan.sh <host>` -> sV+sC+p- mit Output-Dateien
- `scripts/network/vuln-scan.sh <host>` -> vuln scripts + nuclei
