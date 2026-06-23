# Windows Portable Tools

Liste der portable Binaries die nach `tools/windows-portable/` gehoeren, mit
offiziellen Download-Quellen. Nach `bootstrap.sh`-Lauf liegen die Archive in
`tools/windows-portable/_downloads/` und muessen manuell entpackt werden in
das jeweilige Tool-Verzeichnis.

| Tool          | Ziel-Pfad                                    | Quelle (offiziell) |
|---------------|----------------------------------------------|---------------------|
| nmap          | `tools/windows-portable/nmap/nmap.exe`       | https://nmap.org/download.html |
| Wireshark     | `tools/windows-portable/wireshark/`          | https://www.wireshark.org/download.html (PortableApps-Variante) |
| hashcat       | `tools/windows-portable/hashcat/hashcat.exe` | https://hashcat.net/hashcat/ |
| John the Ripper| `tools/windows-portable/john/run/john.exe`  | https://www.openwall.com/john/ |
| PuTTY         | `tools/windows-portable/putty/putty.exe`     | https://www.chiark.greenend.org.uk/~sgtatham/putty/ |
| 7-Zip portable| `tools/windows-portable/7zip/7z.exe`         | https://www.7-zip.org/download.html |
| Sysinternals  | `tools/windows-portable/sysinternals/`       | https://learn.microsoft.com/sysinternals/downloads/sysinternals-suite |
| LaZagne       | `tools/windows-portable/LaZagne.exe`         | https://github.com/AlessandroZ/LaZagne/releases |
| subfinder     | `tools/windows-portable/subfinder/subfinder.exe` | https://github.com/projectdiscovery/subfinder/releases |
| httpx         | `tools/windows-portable/httpx/httpx.exe`     | https://github.com/projectdiscovery/httpx/releases |
| nuclei        | `tools/windows-portable/nuclei/nuclei.exe`   | https://github.com/projectdiscovery/nuclei/releases |
| name-that-hash| via pip im python-portable, optional        | https://pypi.org/project/name-that-hash/ |

## Schnellabruf

Falls einzelne Tools fehlen, manueller Download:

```powershell
cd $env:TOOLKIT\tools\windows-portable
# Beispiel hashcat
Invoke-WebRequest -Uri "https://hashcat.net/files/hashcat-6.2.6.7z" -OutFile "_downloads\hashcat.7z"
# entpacken mit 7-Zip, dann Ordner zu hashcat\ umbenennen
```

## Hinweis VC++ Runtimes

Manche Windows-Tools (insbesondere Wireshark, Hashcat OpenCL) brauchen die
Visual C++ 2015-2022 Redistributable. Wenn ein Tool mit "missing dll" startet:
https://aka.ms/vs/17/release/vc_redist.x64.exe installieren.

## SmartScreen / AV

Pentest-Tools werden von Defender oft als PUP markiert. Auf eigenen Geraeten
Exclusion fuer `tools/windows-portable/` setzen, sonst werden Binaries
geloescht.
