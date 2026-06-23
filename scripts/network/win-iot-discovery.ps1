# win-iot-discovery.ps1 - PowerShell IoT/Device-Scan im eigenen LAN
param([Parameter(Mandatory=$true)][string]$Network)

. "$PSScriptRoot\..\lib\auth_check.ps1"
Require-Auth -Target $Network

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = Join-Path $env:TOOLKIT "output\scans\iot-win-$stamp"
New-Item -ItemType Directory -Path $out -Force | Out-Null

Write-Host "[+] ARP-Tabelle"
arp -a | Out-File (Join-Path $out "arp.txt")

Write-Host "[+] mDNS via dns-sd (oder Bonjour)"
if (Get-Command dns-sd -ErrorAction SilentlyContinue) {
    Start-Process -Wait -FilePath dns-sd -ArgumentList "-B _services._dns-sd._udp local" `
        -RedirectStandardOutput (Join-Path $out "mdns.txt")
}

Write-Host "[+] SSDP/UPnP via .NET"
$udp = New-Object System.Net.Sockets.UdpClient
$ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse("239.255.255.250"), 1900)
$msg = "M-SEARCH * HTTP/1.1`r`nHOST: 239.255.255.250:1900`r`nMAN: `"ssdp:discover`"`r`nMX: 3`r`nST: ssdp:all`r`n`r`n"
$data = [System.Text.Encoding]::ASCII.GetBytes($msg)
$udp.Send($data, $data.Length, $ep) | Out-Null
$udp.Client.ReceiveTimeout = 4000
$results = @()
try {
    while ($true) {
        $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $udp.Receive([ref]$remote)
        $results += "=== $($remote.Address) ===`n$([System.Text.Encoding]::ASCII.GetString($resp))"
    }
} catch {}
$udp.Close()
$results | Out-File (Join-Path $out "ssdp.txt")

Write-Host "[+] Ping-Sweep"
$base = ($Network -replace '/\d+$','').Trim() -replace '\.0$',''
1..254 | ForEach-Object -Parallel {
    $ip = "$using:base.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        $ip
    }
} -ThrottleLimit 50 | Out-File (Join-Path $out "alive.txt")

Write-Host "[+] Output: $out"
