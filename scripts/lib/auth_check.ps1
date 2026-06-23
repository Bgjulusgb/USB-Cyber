# auth_check.ps1 - zentrale Authorisierungs-Pruefung (Windows)
#
# Usage:
#   . "$env:TOOLKIT\scripts\lib\auth_check.ps1"
#   Require-Auth -Target "192.168.1.0/24"

$ErrorActionPreference = "Stop"

if (-not $env:TOOLKIT) {
    $drive = (Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path "$($_.Root)launchers" -ErrorAction SilentlyContinue }).Root | Select-Object -First 1
    if ($drive) { $env:TOOLKIT = $drive.TrimEnd('\') }
}

$script:TargetsFile = if ($env:TARGETS_FILE) { $env:TARGETS_FILE } else { Join-Path $env:TOOLKIT "authorized-targets\targets.yaml" }
$script:AuditLog    = if ($env:AUDIT_LOG)    { $env:AUDIT_LOG }    else { Join-Path $env:TOOLKIT "output\audit.log" }

function Write-AuthRed    { param($Msg) Write-Host $Msg -ForegroundColor Red }
function Write-AuthGreen  { param($Msg) Write-Host $Msg -ForegroundColor Green }
function Write-AuthYellow { param($Msg) Write-Host $Msg -ForegroundColor Yellow }

function Require-Auth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Target,
        [string]$ScriptName = (Split-Path -Leaf $MyInvocation.PSCommandPath)
    )

    if (-not (Test-Path $script:TargetsFile)) {
        Write-AuthRed "[-] targets.yaml nicht gefunden: $($script:TargetsFile)"
        exit 2
    }

    $scopes = Select-String -Path $script:TargetsFile -Pattern '^\s*scope:\s*(.+?)\s*(#.*)?$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.Trim("'""") }

    if (-not $scopes) {
        Write-AuthRed "[-] Keine 'scope:' Eintraege in $($script:TargetsFile)"
        exit 2
    }

    $matched = $false
    foreach ($scope in $scopes) {
        if ([string]::IsNullOrWhiteSpace($scope)) { continue }
        if ($Target -like "*$scope*" -or $scope -like "*$Target*") {
            $matched = $true
            break
        }
    }

    if (-not $matched) {
        Write-AuthRed   "[-] Target '$Target' ist NICHT autorisiert."
        Write-AuthYellow "    Trage es in $($script:TargetsFile) ein oder breche ab."
        exit 2
    }

    $dir = Split-Path -Parent $script:AuditLog
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $entry = "{0} | {1} | {2} | {3}" -f (Get-Date -Format "o"), $env:USERNAME, $ScriptName, $Target
    Add-Content -Path $script:AuditLog -Value $entry

    Write-AuthGreen "[+] Auth OK fuer: $Target"
}

function Confirm-Destructive {
    param([string]$Prompt = "Aktion ausfuehren?")
    Write-AuthYellow "[!] $Prompt [y/N]"
    $answer = Read-Host
    if ($answer -notmatch '^[yYjJ]$') {
        Write-AuthYellow "[-] Abgebrochen."
        exit 0
    }
}
