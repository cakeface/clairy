# Agent Droplet Spec

Provision a DigitalOcean droplet to host a personal always-on AI agent, reachable via RDP from a Mac and via messaging channels from anywhere. This is an experimentation environment, not production — bias toward simple defaults over hardened ones, but don't leave the box open to the public internet.

## Context you need to know

- I already have a DigitalOcean account with existing droplets and a domain (I'll provide the domain name).
- I have an OpenRouter account. I'll provide the API key.
- I'll be connecting from a Mac, primarily via Microsoft Remote Desktop over Tailscale.
- Budget target is $28/month for the droplet. Don't upsize without asking.
- This replaces a prior plan to buy a Mac mini, which is backordered 10-12 weeks. Assume I may migrate off this droplet in 2-6 months, so prefer portable configs (dotfiles, scripts) over "works only on this box" setups.

## Deliverables

At the end, I want:

1. A running DigitalOcean droplet with a full Linux desktop accessible via RDP over Tailscale.
2. Kimi K2.6 accessible as a model through OpenRouter from inside the droplet.
3. A coding harness (OpenCode) installed and configured with OpenRouter.
4. A persistent-agent runtime (Hermes Agent, fallback OpenClaw) installed, with Signal as the primary messaging channel (the agent gets its own phone number).
5. Pushover as a dead-man's-switch fallback channel — if Signal goes down, the agent can still reach me.
6. A subdomain pointing at the droplet for webhooks.
7. A local copy of all config files, scripts, and install steps so I can rebuild this elsewhere.

## Droplet spec

- Provider: DigitalOcean
- Plan: Basic Premium Intel, 2 vCPU / 4GB RAM / 80GB NVMe (the $28/month tier)
- Region: NYC3 (change only if asked)
- Image: Ubuntu 24.04 LTS x64
- Authentication: SSH key only, no password login
- Hostname: `agent` (or whatever I specify)
- Enable: monitoring, backups (the $5.60/month option is fine, don't skip it)
- Tags: `agent`, `experimentation`

Use the DigitalOcean CLI (`doctl`) or Terraform — your call, but commit the config to a git repo on the droplet under `~/infra/` so I can version it.

## Initial hardening

Before installing anything else:

- Create a non-root user with sudo. Username `admin` unless I specify otherwise.
- Disable root SSH login. Disable password SSH. SSH key only.
- Install and enable `ufw`. Default deny incoming. Allow 22 from anywhere initially (will tighten after Tailscale).
- Install and enable `fail2ban` with default config.
- `unattended-upgrades` for security patches only, not full package upgrades.
- Set timezone to America/New_York.
- Create a 1GB swap file (`fallocate -l 1G /swapfile`, chmod 600, mkswap, swapon, add to fstab). The signal-cli JVM plus XFCE plus the agent runtime will push 4GB. Swap gives us headroom without paying for a bigger droplet.

## Tailscale

- Install Tailscale. Authenticate with my account (I'll paste the auth URL into a browser when prompted).
- Enable SSH-over-Tailscale (`tailscale up --ssh`).
- Once Tailscale is confirmed working from my Mac, update UFW to allow port 3389 (RDP) only from the Tailscale interface (`tailscale0`), not from the public internet.
- Do NOT expose RDP publicly. Ever.

## Desktop environment

- Install XFCE4 (not GNOME, not KDE — XFCE is lighter and works better over RDP).
- Install `xrdp` and configure it to use XFCE as the session.
- Install Firefox and Chromium. Sign-in is manual, I'll do it over RDP.
- Install a few basic desktop apps: a file manager (Thunar comes with XFCE), a text editor (I like VS Code — install it via the official Microsoft apt repo), a terminal emulator (XFCE's default is fine).
- Default RDP session resolution: 1920x1080. Make sure clipboard and audio redirection work.

## Domain and TLS

- I'll give you a subdomain like `agent.mydomain.com`. Create an A record pointing to the droplet's public IP. I'll update DNS manually if you can't do it via API, but prefer to handle it via DO's DNS if the domain is managed there.
- Install Caddy as the reverse proxy. Caddy will auto-fetch Let's Encrypt certs.
- Caddy config should initially be empty (no sites), ready to add webhook endpoints as I install agent services.

## Agent stack

Install in this order. Stop and report back if anything fails — don't keep going past a broken step.

### 1. Docker

- Install Docker Engine (not Docker Desktop) via the official Docker apt repo.
- Add the `admin` user to the `docker` group so it can run containers without sudo.
- Install docker-compose (v2, the `docker compose` plugin form).
- Verify with `docker run hello-world`.

### 2. Node.js and Python

- Node 20 LTS via nvm (installed for the `admin` user, not root).
- Python 3.12 (comes with Ubuntu 24.04) plus `pip`, `pipx`, `venv`.

### 3. OpenRouter setup

- Add `OPENROUTER_API_KEY` to `~/.config/openrouter/env` (mode 600). I'll paste the key.
- Export it from `~/.bashrc` only if the file exists.
- Test it with a simple curl to `https://openrouter.ai/api/v1/chat/completions` calling `moonshotai/kimi-k2.6` (fallback to `moonshotai/kimi-k2.5` if k2.6 isn't available yet on OpenRouter — check the models endpoint first).

### 4. OpenCode

- Install OpenCode from https://opencode.ai (follow their current install instructions).
- Configure it to use OpenRouter as a provider with Kimi K2.6 as the default model.
- Config lives in `~/.config/opencode/opencode.json` — commit this to the infra repo.
- Verify by running a simple "hello world" prompt from the terminal.

### 5. Hermes Agent (primary) or OpenClaw (fallback)

- Try Hermes Agent first: https://github.com/NousResearch/hermes-agent (verify the actual repo URL at install time — the org may have changed).
- Clone, install dependencies per their docs, configure to use OpenRouter + Kimi K2.6.
- If Hermes install fails or their docs are stale, fall back to OpenClaw: https://github.com/openclaw/openclaw. Use `openclaw onboard` for guided setup.
- Either way, I want a SOUL.md (OpenClaw) or equivalent agent identity file that I can edit. Leave it mostly empty with a comment saying "user will fill this in."

### 6. Twilio phone number

- I'll create a Twilio account and buy a phone number ($1/month). I'll provide the Account SID, Auth Token, and the number.
- The number is for Signal registration only right now. Later it may be used for voice calls and SMS, but not yet.
- Store Twilio creds in `~/.config/twilio/env` (mode 600), exported from `.bashrc` like the OpenRouter key.

### 7. Signal via signal-cli

- Run `signal-cli-rest-api` (bbernhard/signal-cli-rest-api) as a Docker container in `json-rpc` mode for lower latency.
- Register the Twilio phone number with Signal using signal-cli. This requires solving a CAPTCHA once — I will do this manually over RDP when prompted. Do not try to automate the CAPTCHA.
- After registration, verify by sending a test message from the droplet to my personal Signal number. I'll provide the number.
- The Docker container should be managed by systemd or docker compose, configured to restart on failure. Signal session keys live in a mounted volume — losing these means re-registration, so make sure the volume path is documented and included in the infra repo README.
- RAM warning: signal-cli-rest-api runs a JVM and will use 300-500MB. On a 4GB droplet this is significant. Monitor with `htop` after setup. If memory is too tight with the full stack running, we may need to resize the droplet — ask me before doing that.

### 8. Wire Signal to the agent

- Configure Hermes Agent (or OpenClaw) to use Signal as its primary messaging channel, pointing at the local signal-cli-rest-api endpoint (usually `http://localhost:8080`).
- The agent's Signal identity should be the Twilio number from step 6.
- Verify I can send a message to the agent's number on Signal from my phone and get a response within 30 seconds.
- This is the primary success criterion for the whole setup.

### 9. Pushover (fallback / dead-man's switch)

- I'll create a Pushover account and give you the User Key and an Application API Token.
- Store these in `~/.config/pushover/env` (mode 600).
- Create a simple health-check script at `~/infra/scripts/health-check.sh` that:
  1. Checks if the signal-cli-rest-api container is running and responsive (curl `http://localhost:8080/v1/about`).
  2. Checks if the agent runtime process is alive.
  3. If either check fails, sends a Pushover notification: "Agent alive but Signal is down — SSH in or check RDP."
  4. If both are fine, does nothing (no spam).
- Run this script via cron every 5 minutes.
- Also configure the agent runtime itself (via SOUL.md or equivalent) with this instruction: "If you detect that your Signal channel is unresponsive or you cannot send/receive messages, immediately send a Pushover alert to the owner using the health-check script, then continue operating and retry Signal every 60 seconds."
- Separately, add a daily heartbeat: at 9am Eastern, the agent sends a Pushover notification saying "Agent online, Signal status: OK/DOWN, uptime: Xd Xh". This is so I know the whole thing is alive even when I haven't talked to it in a while.
- Verify Pushover works by triggering a test notification from the droplet.

## Git and dotfiles

- Create `~/infra/` as a git repo. Commit:
  - Any Terraform/doctl scripts used to create the droplet
  - `/etc/ufw/user.rules` (or equivalent)
  - Caddyfile
  - `docker-compose.yml` for signal-cli-rest-api
  - `scripts/health-check.sh` (the Pushover dead-man's switch)
  - Cron entries (export with `crontab -l > crontab.txt`)
  - A `README.md` with the full install order, volume paths, and any gotchas hit along the way
- Don't commit secrets. Use a `.env.example` with placeholder values and gitignore the real `.env`.

## Things explicitly out of scope

- Do not install local LLM inference (Ollama, LM Studio). This droplet doesn't have a GPU and 4GB RAM is too tight anyway. I'll do that on the Mac mini when/if I buy one.
- Do not set up backups beyond DO's built-in droplet backups.
- Do not configure email sending as a channel. Too much hassle and I don't need it yet.
- Do not try to make iMessage work. It won't, this is Linux.
- Do not install Telegram, WhatsApp, Discord, or other messaging channels. Signal is the primary channel. Pushover is the fallback. Additional channels come later after the stack is validated.
- Do not set up Twilio voice calls or SMS beyond what's needed for Signal registration. Voice is a future project.

## Final report

When done, give me:

- The droplet's public IP and Tailscale IP
- The subdomain URL
- The agent's Signal phone number
- Path to the infra repo
- A one-paragraph summary of anything unexpected that came up
- Memory usage snapshot (`free -h` output) with the full stack running — I need to know how close to the edge we are on 4GB
- A test procedure I can run from my phone to verify end-to-end: "Send a Signal message saying `hello` to [agent number] and confirm you get a response within 30 seconds. Then kill the signal-cli container with `docker stop signal-cli` and confirm a Pushover notification arrives within 5 minutes."

## Failure modes to watch for

- K2.6 may not be on OpenRouter yet under that exact model ID. Check `https://openrouter.ai/api/v1/models` and fall back to `moonshotai/kimi-k2.5` or `moonshotai/kimi-k2-thinking` if needed. Tell me which one you used.
- Hermes Agent and OpenClaw install scripts change frequently. If their README doesn't match reality, stop and ask rather than guessing.
- XRDP + XFCE can have weirdness with session management. If first login shows a black screen, the fix is usually `~/.xsession` needing `startxfce4`.
- UFW can lock you out of SSH if you configure it in the wrong order. Always `ufw allow 22` before `ufw enable`.
- Signal registration can fail if the Twilio number has been previously used with Signal or if Signal's anti-spam blocks it. If registration fails on the first number, I'll buy a second one. Don't spend more than 20 minutes debugging a failed registration — just tell me and we'll try another number.
- signal-cli-rest-api Docker image is large (~800MB) and the JVM takes 300-500MB RAM at runtime. If the droplet OOMs after everything is running, the first thing to try is adding 1GB of swap (`fallocate -l 1G /swapfile`). If that's not enough, we resize the droplet.
- Signal session keys in the Docker volume are irreplaceable without re-registration. Document the exact volume mount path in the README and warn about it. Do not `docker system prune` without excluding that volume.
- signal-cli occasionally breaks when Signal pushes protocol changes. If messages stop flowing and the container logs show protocol errors, check https://github.com/bbernhard/signal-cli-rest-api/issues for known issues before debugging locally. This is why the Pushover fallback exists.
