#!/bin/bash
set -e

echo "Pi-hole setup"
echo "============="

# Check Docker is available
if ! command -v docker &>/dev/null; then
  echo "Error: Docker not found. Install Docker Desktop and try again."
  exit 1
fi

# Create .env from example if it doesn't exist
if [[ ! -f .env ]]; then
  cp .env.example .env
  chmod 600 .env
  echo ""
  echo "Created .env from .env.example."
  echo "Fill in your values (password, SERVER_IP, subnet) then re-run this script."
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
