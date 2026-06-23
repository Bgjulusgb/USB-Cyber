# win-osint.ps1 - passive Domain-OSINT mit PowerShell-Bordmitteln
param([Parameter(Mandatory=$true)][string]$Domain)

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\scans\osint_${Domain}_$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null

Write-Host "[+] DNS A/AAAA/MX/TXT/NS"
foreach ($type in "A","AAAA","MX","TXT","NS") {
    "=== $type ===" | Out-File -Append (Join-Path $out "dns.txt")
    try {
        Resolve-DnsName -Type $type $Domain -ErrorAction Stop |
            Format-Table | Out-String | Out-File -Append (Join-Path $out "dns.txt")
    } catch {
        "  (none)" | Out-File -Append (Join-Path $out "dns.txt")
    }
}

Write-Host "[+] crt.sh"
try {
    $url = "https://crt.sh/?q=%25.$Domain&output=json"
    $resp = Invoke-RestMethod -Uri $url -TimeoutSec 30
    $resp | ForEach-Object { $_.name_value } | Sort-Object -Unique |
        Out-File (Join-Path $out "crtsh.txt")
    Write-Host "    $((Get-Content (Join-Path $out 'crtsh.txt')).Count) unique entries"
} catch {
    Write-Host "    crt.sh failed: $_" -ForegroundColor Yellow
}

Write-Host "[+] Output: $out"
