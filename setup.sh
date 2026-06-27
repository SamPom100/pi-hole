#!/bin/bash
set -e

echo "Pi-hole setup"
echo "============="

# Check Docker is available
if ! command -v docker &>/dev/null; then
  echo "Error: Docker not found. Install Docker Desktop and try again."
  exit 1
fi

# Detect the LAN IP of this machine
detect_ip() {
  # macOS
  if command -v ipconfig &>/dev/null; then
    local iface
    iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
    local ip
    ip=$(ipconfig getifaddr "$iface" 2>/dev/null)
    [[ -n "$ip" ]] && echo "$ip" && return
  fi
  # Linux
  if command -v ip &>/dev/null; then
    ip route get 1 2>/dev/null | awk '{print $7; exit}' && return
  fi
  hostname -I 2>/dev/null | awk '{print $1}'
}

# Create .env from example if it doesn't exist
if [[ ! -f .env ]]; then
  cp .env.example .env
  chmod 600 .env

  LOCAL_IP=$(detect_ip)
  if [[ -n "$LOCAL_IP" ]]; then
    SUBNET=$(echo "$LOCAL_IP" | awk -F. '{print $1"."$2"."$3".0/24"}')
    sed -i.bak "s|SERVER_IP=.*|SERVER_IP=${LOCAL_IP}|" .env
    sed -i.bak "s|FTLCONF_webserver_acl=.*|FTLCONF_webserver_acl=+127.0.0.1,+[::1],+${SUBNET},+172.30.0.0/24|" .env
    rm -f .env.bak
    echo ""
    echo "Detected LAN IP: ${LOCAL_IP} (subnet ${SUBNET})"
  fi

  echo ""
  echo "Created .env — set your admin password and re-run."
  exit 0
fi

chmod 600 .env

# Bail if the password placeholder wasn't replaced
if grep -q "CHANGE_ME" .env; then
  echo "Error: .env still contains CHANGE_ME. Set your values and re-run."
  exit 1
fi

# Create directories Pi-hole and dnsmasq expect to exist
mkdir -p etc-pihole/hosts etc-dnsmasq.d

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon..."
until docker info &>/dev/null 2>&1; do
  sleep 2
done

docker compose up -d

echo ""
echo "Done. Pi-hole is running."
SERVER_IP=$(grep '^SERVER_IP=' .env | cut -d= -f2)
echo "Admin UI: https://${SERVER_IP}/admin"
