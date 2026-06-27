#!/bin/zsh
# Wait for Docker daemon to be ready
until docker info &>/dev/null; do
  sleep 2
done

cd "$(dirname "$0")"
docker compose up -d
