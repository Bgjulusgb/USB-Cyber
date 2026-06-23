# win-portscan.ps1 - full TCP portscan via portable nmap.exe
param([Parameter(Mandatory=$true)][string]$Target)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $Target

$nmap = Join-Path $env:TOOLKIT "tools\windows-portable\nmap\nmap.exe"
if (-not (Test-Path $nmap)) {
    Write-AuthRed "[-] nmap.exe nicht gefunden unter $nmap"
    exit 1
}

$safe = ($Target -replace '[\\/:.]', '_')
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\scans\portscan_${safe}_$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null

& $nmap -sV -sC -p- --min-rate 1000 $Target -oA (Join-Path $out "full") |
    Tee-Object (Join-Path $out "full.txt")

Write-AuthGreen "[+] Output: $out"
