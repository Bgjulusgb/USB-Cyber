# wifi-saved-pw.ps1 - alle gespeicherten WLAN-Profile + Klartext-Keys
# Nur auf eigenen Geraeten. Erfordert Admin.

param([string]$TargetId = "$env:COMPUTERNAME")

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $TargetId

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\forensics\${TargetId}-wifi-$stamp.txt"
New-Item -ItemType Directory -Path (Split-Path $out) -Force | Out-Null

$profiles = (netsh wlan show profiles) | Select-String "All User Profile" |
    ForEach-Object { ($_ -split ":\s*")[-1].Trim() }

"# WLAN-Profile auf $env:COMPUTERNAME ($(Get-Date -Format 'o'))" | Out-File $out

foreach ($p in $profiles) {
    "## $p" | Add-Content $out
    netsh wlan show profile name="$p" key=clear | Add-Content $out
    "" | Add-Content $out
}

Write-AuthGreen "[+] Output: $out"
Get-Content $out | Select-String "(SSID name|Key Content)"
