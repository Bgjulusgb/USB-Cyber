# win-discovery.ps1 - nmap -sn via portable nmap.exe
param([Parameter(Mandatory=$true)][string]$Target)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $Target

$nmap = Join-Path $env:TOOLKIT "tools\windows-portable\nmap\nmap.exe"
if (-not (Test-Path $nmap)) {
    Write-AuthRed "[-] nmap.exe nicht gefunden unter $nmap"
    Write-AuthYellow "    tools\windows-portable\_downloads\nmap.zip entpacken nach tools\windows-portable\nmap\"
    exit 1
}

$safe = ($Target -replace '[\\/:.]', '_')
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\scans\discovery_${safe}_$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null

& $nmap -sn $Target -oA (Join-Path $out "discovery") | Tee-Object (Join-Path $out "discovery.txt")
Write-AuthGreen "[+] Output: $out"
