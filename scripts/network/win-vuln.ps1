# win-vuln.ps1 - nmap vuln-script (Windows portable)
param([Parameter(Mandatory=$true)][string]$Target)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $Target

$nmap = Join-Path $env:TOOLKIT "tools\windows-portable\nmap\nmap.exe"
if (-not (Test-Path $nmap)) {
    Write-AuthRed "[-] nmap.exe nicht gefunden"
    exit 1
}

$safe = ($Target -replace '[\\/:.]', '_')
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\scans\vuln_${safe}_$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null

& $nmap -sV --script vuln $Target -oA (Join-Path $out "nmap-vuln") |
    Tee-Object (Join-Path $out "nmap-vuln.txt")

Write-AuthGreen "[+] Output: $out"
