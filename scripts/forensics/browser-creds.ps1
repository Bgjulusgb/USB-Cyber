# browser-creds.ps1 - eigene Chrome/Firefox-Logins extrahieren
# Nur fuer das aktuell eingeloggte Benutzerprofil.

param(
    [string]$TargetId = "$env:USERNAME-laptop",
    [string]$OutDir = ""
)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $TargetId

if (-not $OutDir) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutDir = Join-Path $env:TOOLKIT "output\forensics\${TargetId}-browser-$stamp"
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

Write-AuthGreen "[+] Output: $OutDir"

# Chrome: kopiert nur die Logindatenbank. Entschluesseln per impacket/dpapi spaeter.
$chromeLogin = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Login Data"
$chromeCookies = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Network\Cookies"

if (Test-Path $chromeLogin) {
    Copy-Item $chromeLogin (Join-Path $OutDir "chrome-LoginData.db") -Force
    Write-AuthGreen "[+] Chrome LoginData kopiert"
}
if (Test-Path $chromeCookies) {
    Copy-Item $chromeCookies (Join-Path $OutDir "chrome-Cookies.db") -Force
    Write-AuthGreen "[+] Chrome Cookies kopiert"
}

# Firefox: alle Profile
$ffRoot = Join-Path $env:APPDATA "Mozilla\Firefox\Profiles"
if (Test-Path $ffRoot) {
    Get-ChildItem $ffRoot -Directory | ForEach-Object {
        $profileOut = Join-Path $OutDir "firefox-$($_.Name)"
        New-Item -ItemType Directory -Path $profileOut -Force | Out-Null
        foreach ($f in @("logins.json", "key4.db", "cookies.sqlite", "formhistory.sqlite")) {
            $src = Join-Path $_.FullName $f
            if (Test-Path $src) { Copy-Item $src (Join-Path $profileOut $f) -Force }
        }
        Write-AuthGreen "[+] Firefox $($_.Name) gesichert"
    }
}

Write-AuthYellow "[!] Hinweis: Chrome-Passwoerter sind DPAPI-verschluesselt mit dem User-Key."
Write-AuthYellow "    Entschluesselung erfordert das Login-Passwort dieses Users."
