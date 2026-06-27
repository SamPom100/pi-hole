# pihole

Pi-hole v6 + dnscrypt-proxy running in Docker. All DNS on the network routes through Pi-hole for ad blocking, then upstream through dnscrypt-proxy to Quad9 over DNSCrypt. No plaintext DNS leaves the machine.

```
LAN clients → Pi-hole :53 → dnscrypt-proxy :5053 (DNSCrypt) → Quad9
```

## Setup

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/).

**macOS / Linux**
```bash
git clone <repo>
cd pihole
./setup.sh
```

**Windows** (PowerShell, Docker Desktop with WSL2 backend)
```powershell
git clone <repo>
cd pihole
.\setup.ps1
```

The first run creates `.env` from `.env.example`, auto-detects this machine's LAN IP and subnet, and exits. Set your admin password in `.env`, then run the script again to start the stack.

### .env

| Variable | Description |
|---|---|
| `FTLCONF_webserver_api_password` | Pi-hole admin UI password |
| `SERVER_IP` | This machine's LAN IP address |
| `FTLCONF_webserver_acl` | Subnets allowed to access the admin UI |

## Admin UI

`https://<SERVER_IP>/admin` — HTTP redirects to HTTPS automatically.

## Auto-start on login (macOS)

A LaunchAgent can run `start.sh` at login. The plist should point to `start.sh` in the repo directory. `start.sh` waits for the Docker daemon before bringing the stack up, so it's safe to run at login before Docker is fully ready.

## DNS chain notes

- dnscrypt-proxy is locked to Quad9 only (`quad9-dnscrypt-ip4-filter-pri` / `alt`)
- ECS (client subnet) is disabled — Quad9 does not see your LAN IPs
- DNSSEC is validated by Quad9 on the encrypted channel
- iCloud Private Relay and Firefox DoH are blocked to keep traffic going through Pi-hole
