# live-windows-dump.ps1 - direkt im laufenden Windows auf dem alten Laptop
# Sammelt: WLAN-Klartextkeys, Browser-Passwoerter (LaZagne), Outlook-Profile,
# WiFi-Profile, BitLocker-Recovery, Sysinfo.

param([Parameter(Mandatory=$true)][string]$LaptopId)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $LaptopId

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\laptop-extract\${LaptopId}-livewin-$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$lazagne = Join-Path $env:TOOLKIT "tools\windows-portable\LaZagne.exe"

Write-AuthGreen "[+] Output-Dir: $out"

# 1. Sysinfo
Write-Host "[1/8] Sysinfo"
systeminfo | Out-File (Join-Path $out "01-sysinfo.txt")
Get-ComputerInfo | Format-List | Out-File (Join-Path $out "01-computerinfo.txt")
whoami /all | Out-File (Join-Path $out "01-whoami.txt")

# 2. WLAN-Profile mit Klartext-Keys
Write-Host "[2/8] WLAN-Profile (Klartext)"
$wifiOut = Join-Path $out "02-wifi.txt"
$profiles = (netsh wlan show profiles) | Select-String "All User Profile" |
    ForEach-Object { ($_ -split ":\s*")[-1].Trim() }
"# WLAN $env:COMPUTERNAME $(Get-Date -Format 'o')" | Out-File $wifiOut
foreach ($p in $profiles) {
    "" | Add-Content $wifiOut
    "## $p" | Add-Content $wifiOut
    netsh wlan show profile name="$p" key=clear | Add-Content $wifiOut
}

# 3. BitLocker-Keys
Write-Host "[3/8] BitLocker-Recovery"
if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
    Get-BitLockerVolume | ForEach-Object {
        [pscustomobject]@{
            Mount = $_.MountPoint
            Protected = $_.ProtectionStatus
            RecoveryKeys = ($_.KeyProtector | Where-Object KeyProtectorType -eq "RecoveryPassword" |
                            ForEach-Object { $_.RecoveryPassword }) -join "; "
        }
    } | Format-Table -AutoSize | Out-String | Out-File (Join-Path $out "03-bitlocker.txt")
}

# 4. LaZagne (alles)
Write-Host "[4/8] LaZagne (alle Module)"
if (Test-Path $lazagne) {
    Push-Location (Join-Path $out "04-lazagne")
    New-Item -ItemType Directory -Force -Path . | Out-Null
    & $lazagne all -oN 2>&1 | Out-File "lazagne.log"
    Pop-Location
} else {
    Write-AuthYellow "[!] LaZagne fehlt - tools/windows-portable/LaZagne.exe einbinden"
}

# 5. Browser-Bookmarks + History
Write-Host "[5/8] Browser-Daten"
$browserOut = Join-Path $out "05-browser"
New-Item -ItemType Directory -Path $browserOut -Force | Out-Null
$chromeBookmarks = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
$chromeHistory   = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$edgeBookmarks   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
foreach ($pair in @(
    @{Src=$chromeBookmarks; Name='chrome-bookmarks.json'},
    @{Src=$chromeHistory;   Name='chrome-history.db'},
    @{Src=$edgeBookmarks;   Name='edge-bookmarks.json'}
)) {
    if (Test-Path $pair.Src) {
        Copy-Item $pair.Src (Join-Path $browserOut $pair.Name) -Force
        Write-AuthGreen "    -> $($pair.Name)"
    }
}

# 6. Recently used files (LNK in Recent)
Write-Host "[6/8] Recently used"
$recent = "$env:APPDATA\Microsoft\Windows\Recent"
if (Test-Path $recent) {
    Get-ChildItem $recent -File | Sort-Object LastWriteTime -Descending |
        Select-Object -First 100 Name, LastWriteTime |
        Out-File (Join-Path $out "06-recent.txt")
}

# 7. Installierte Programme + Updates
Write-Host "[7/8] Installierte Software"
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                 HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
                 -ErrorAction SilentlyContinue |
    Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName | Out-File (Join-Path $out "07-software.txt")

# 8. RDP-Verbindungen
Write-Host "[8/8] RDP-Cred-Cache"
$rdpRoot = "$env:LOCALAPPDATA\Microsoft\Remote Desktop\Cache"
if (Test-Path $rdpRoot) {
    Copy-Item $rdpRoot (Join-Path $out "08-rdp-cache") -Recurse -ErrorAction SilentlyContinue
}
cmdkey /list | Out-File (Join-Path $out "08-cmdkey-list.txt")

Write-AuthGreen "[+] Live-Dump fertig: $out"
explorer $out
