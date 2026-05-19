#!/usr/bin/env bash
# Run as root after hardening. Installs Tailscale and locks firewall.
set -euo pipefail

echo ">>> Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo ">>> Starting Tailscale (will print auth URL)"
tailscale up --ssh

echo ""
echo ">>> After authenticating, run these to lock down the firewall:"
echo "    ufw allow in on tailscale0 to any port 22 proto tcp"
echo "    ufw allow in on tailscale0 to any port 3389 proto tcp"
echo "    ufw delete allow 22/tcp"
