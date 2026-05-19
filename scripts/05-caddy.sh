#!/usr/bin/env bash
# Run as root. Installs Caddy reverse proxy.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> Installing Caddy"
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qq
apt-get install -y caddy

cat > /etc/caddy/Caddyfile <<'EOF'
# Clairy reverse proxy config
# Add site blocks here as services are deployed
EOF

systemctl enable caddy
systemctl restart caddy

echo ">>> Caddy $(caddy version) installed"
