#!/usr/bin/env bash
# Run as root. Installs Docker, then Node.js and Python tools for the clairy user.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

USERNAME="clairy"

echo ">>> Installing Docker Engine"
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker "$USERNAME"

echo ">>> Verifying Docker"
docker run --rm hello-world

echo ">>> Installing Python tools"
apt-get install -y python3-pip python3-venv pipx

echo ">>> Installing Node.js 20 via nvm (as $USERNAME)"
su - "$USERNAME" -c '
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 20
nvm alias default 20
echo "Node $(node --version) installed"
'

echo ">>> Done."
