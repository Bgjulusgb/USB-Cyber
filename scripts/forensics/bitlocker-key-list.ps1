# bitlocker-key-list.ps1 - Listet BitLocker Recovery-Keys auf eigenen Volumes
# Nur eigene Geraete, erfordert Admin.

param([string]$TargetId = "$env:COMPUTERNAME")

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $TargetId

if (-not (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
    Write-AuthRed "[-] BitLocker Modul nicht verfuegbar. Windows Pro/Enterprise?"
    exit 1
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\forensics\${TargetId}-bitlocker-$stamp.txt"
New-Item -ItemType Directory -Path (Split-Path $out) -Force | Out-Null

$result = foreach ($vol in Get-BitLockerVolume) {
    [pscustomobject]@{
        Mount         = $vol.MountPoint
        ProtectionOn  = $vol.ProtectionStatus
        EncryptionPct = $vol.EncryptionPercentage
        RecoveryKeys  = ($vol.KeyProtector | Where-Object KeyProtectorType -eq "RecoveryPassword" |
                        ForEach-Object { $_.RecoveryPassword }) -join "; "
    }
}

$result | Format-Table -AutoSize | Out-String | Tee-Object $out
Write-AuthGreen "[+] Output: $out"
