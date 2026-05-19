#!/usr/bin/env bash
# Run as the clairy user (not root). Installs OpenCode, Hermes Agent, and starts signal-cli.
# Requires: OPENROUTER_API_KEY set in ~/.config/openrouter/env
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo ">>> Setting up OpenRouter env"
mkdir -p ~/.config/openrouter
if [ ! -f ~/.config/openrouter/env ]; then
    echo "ERROR: Create ~/.config/openrouter/env with OPENROUTER_API_KEY=<key> first"
    exit 1
fi
chmod 600 ~/.config/openrouter/env

grep -q "openrouter/env" ~/.bashrc || cat >> ~/.bashrc <<'EOF'

# OpenRouter
if [ -f ~/.config/openrouter/env ]; then
    export $(grep -v '^#' ~/.config/openrouter/env | xargs)
fi
EOF

source ~/.config/openrouter/env
export OPENROUTER_API_KEY

echo ">>> Installing OpenCode"
curl -fsSL https://opencode.ai/install | bash

mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json <<'EOF'
{
  "provider": {
    "openrouter": {
      "apiKey": "env:OPENROUTER_API_KEY",
      "models": {
        "kimi-k2.6": {
          "id": "moonshotai/kimi-k2.6",
          "name": "Kimi K2.6",
          "canReason": true
        }
      }
    }
  },
  "model": {
    "default": "openrouter/kimi-k2.6"
  }
}
EOF

echo ">>> Installing Hermes Agent"
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

echo ">>> Configuring Hermes for OpenRouter + Kimi K2.6"
sed -i 's|default: "anthropic/claude-opus-4.6"|default: "moonshotai/kimi-k2.6"|' ~/.hermes/config.yaml
sed -i 's|provider: "auto"|provider: "openrouter"|' ~/.hermes/config.yaml

cat > ~/.hermes/.env <<EOF
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
EOF
chmod 600 ~/.hermes/.env

echo ">>> Starting signal-cli-rest-api container"
mkdir -p ~/infra
cat > ~/infra/docker-compose.yml <<'EOF'
services:
  signal-cli:
    image: bbernhard/signal-cli-rest-api:latest
    container_name: signal-cli
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      - MODE=json-rpc
    volumes:
      - signal-cli-data:/home/.local/share/signal-cli
    mem_limit: 512m

volumes:
  signal-cli-data:
EOF

docker compose -f ~/infra/docker-compose.yml up -d

echo ">>> Waiting for signal-cli to start..."
sleep 10
curl -s http://localhost:8080/v1/about && echo ""

echo ">>> Done. Next: register the Signal number (requires CAPTCHA)."
echo "    See README.md for registration steps."
