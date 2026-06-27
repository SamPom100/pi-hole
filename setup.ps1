# Pi-hole setup script for Windows
# Run from the repo root in PowerShell: .\setup.ps1

Write-Host "Pi-hole setup"
Write-Host "============="

# Check Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found. Install Docker Desktop (with WSL2 backend) and try again."
    exit 1
}

# Detect this machine's LAN IP via the default route interface
function Get-LocalIP {
    try {
        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
                 Sort-Object RouteMetric |
                 Select-Object -First 1
        $addr = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex |
                Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
                Select-Object -First 1
        return $addr.IPAddress
    } catch {
        return $null
    }
}

# Create .env from example if it doesn't exist
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env

    $localIP = Get-LocalIP
    if ($localIP) {
        $parts  = $localIP -split '\.'
        $subnet = "$($parts[0]).$($parts[1]).$($parts[2]).0/24"

        (Get-Content .env) -replace 'SERVER_IP=.*',              "SERVER_IP=$localIP"    | Set-Content .env
        (Get-Content .env) -replace 'FTLCONF_webserver_acl=.*',  "FTLCONF_webserver_acl=+127.0.0.1,+[::1],+$subnet" | Set-Content .env

        Write-Host ""
        Write-Host "Detected LAN IP: $localIP  (subnet $subnet)"
    }

    Write-Host ""
    Write-Host "Created .env -- set your admin password in .env then re-run this script."
    exit 0
}

# Bail if password placeholder is still set
if (Select-String -Path .env -Pattern "CHANGE_ME" -Quiet) {
    Write-Error ".env still contains CHANGE_ME. Set your admin password and re-run."
    exit 1
}

# Create directories Pi-hole and dnsmasq expect to exist
New-Item -ItemType Directory -Force -Path "etc-pihole\hosts" | Out-Null
New-Item -ItemType Directory -Force -Path "etc-dnsmasq.d"   | Out-Null

# Wait for Docker daemon to be ready
Write-Host "Waiting for Docker daemon..."
while (-not (docker info 2>$null)) {
    Start-Sleep -Seconds 2
}

docker compose up -d

$serverIP = (Select-String -Path .env -Pattern "^SERVER_IP=(.+)").Matches.Groups[1].Value
Write-Host ""
Write-Host "Done. Pi-hole is running."
Write-Host "Admin UI: https://$serverIP/admin"
