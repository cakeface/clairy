# Clairy — Cloud AI Agent Droplet

Bootstrap and configuration for an always-on AI agent running on a DigitalOcean droplet, reachable via Signal and manageable over Tailscale.

## Current Status

**Droplet is live and partially configured.** Signal registration is pending (needs CAPTCHA solved via browser on the machine). RDP performance is poor and being investigated — may switch to NoMachine or use a physical laptop on the tailnet for browser tasks.

### What's Done

- [x] Droplet provisioned (Terraform)
- [x] Initial hardening (UFW, fail2ban, unattended-upgrades, swap)
- [x] Tailscale connected, SSH/RDP locked to tailnet only
- [x] XFCE desktop + xrdp installed
- [x] Docker Engine + docker-compose
- [x] Node.js 20 LTS (via nvm)
- [x] Python 3.12 + pip + pipx + venv
- [x] Caddy reverse proxy (empty config, ready for webhooks)
- [x] OpenRouter configured and tested with Kimi K2.6
- [x] OpenCode installed and configured
- [x] Hermes Agent installed, configured for OpenRouter
- [x] signal-cli-rest-api running in Docker (json-rpc mode)
- [x] Twilio phone number purchased: +1 (518) 363-6994
- [x] DNS: clairy.ckfce.com → 167.172.240.17

### What's Remaining

- [ ] Signal registration (CAPTCHA required — needs browser)
- [ ] Wire Signal to Hermes Agent gateway
- [ ] Pushover setup (dead-man's switch)
- [ ] Health check script + cron
- [ ] Daily heartbeat notification
- [ ] Fix RDP performance (disable compositing, install NoMachine, or use laptop)
- [ ] Fix browser crashes (reinstall Firefox/Chromium as .deb not snap)

## Infrastructure

### Droplet Specs

| Property | Value |
|----------|-------|
| Provider | DigitalOcean |
| Plan | s-4vcpu-16gb-amd ($84/mo + $16.80 backups) |
| Region | NYC3 |
| Image | Ubuntu 24.04 LTS x64 |
| Hostname | clairy |
| Public IP | 167.172.240.17 |
| Tailscale IP | 100.68.70.24 |
| Subdomain | clairy.ckfce.com |
| User | clairy (sudo, no password prompt) |
| SSH | Key-only, Tailscale-only |

### Terraform

The droplet and DNS record are managed via Terraform in `./terraform/`. To recreate:

```bash
cd terraform
export DIGITALOCEAN_TOKEN=<your-token>
terraform init
terraform apply
```

### Connecting

```bash
# SSH (Tailscale must be connected)
ssh clairy@100.68.70.24

# RDP (Microsoft Remote Desktop, Tailscale must be connected)
# Host: 100.68.70.24, User: clairy, Password: clairy
# NOTE: RDP performance is poor — may switch to NoMachine
```

## Services Running

### signal-cli-rest-api (Docker)

- Container name: `signal-cli`
- Mode: json-rpc
- Port: 127.0.0.1:8080
- Health check: `curl http://localhost:8080/v1/about`
- Managed via: `~/infra/docker-compose.yml`
- Volume: `infra_signal-cli-data` (Docker named volume)

**CRITICAL:** The Signal session keys live in the Docker volume `infra_signal-cli-data`. Losing this volume means re-registration. Never run `docker system prune` without `--filter` excluding this volume.

```bash
# Volume location on disk:
docker volume inspect infra_signal-cli-data --format '{{ .Mountpoint }}'
# Typically: /var/lib/docker/volumes/infra_signal-cli-data/_data

# Manage the container:
cd ~/infra && docker compose up -d      # start
cd ~/infra && docker compose down       # stop
cd ~/infra && docker compose logs -f    # logs
```

### Hermes Agent

- Install path: `~/.hermes/`
- Config: `~/.hermes/config.yaml`
- API keys: `~/.hermes/.env`
- Identity: `~/.hermes/SOUL.md`
- Model: moonshotai/kimi-k2.6 via OpenRouter
- Gateway: `hermes gateway start` (after Signal registration)

### Caddy

- Config: `/etc/caddy/Caddyfile`
- Status: running, empty config (no sites yet)
- Will be used for webhook endpoints once agent services are deployed

### OpenCode

- Config: `~/.config/opencode/opencode.json`
- Provider: OpenRouter
- Model: Kimi K2.6

## Phone Number

- Number: +1 (518) 363-6994
- Provider: Twilio
- Twilio SID: PNf13f30a7ce8cdedd82c52c077e3beef7
- Purpose: Signal registration for the agent
- Monthly cost: ~$1.15/mo

## Signal Registration (TODO)

Registration requires solving a CAPTCHA in a browser on the machine:

1. Open a browser on the droplet (via RDP or laptop on tailnet)
2. Go to: https://signalcaptchas.org/registration/generate.html
3. Solve the CAPTCHA
4. Right-click "Open Signal" link → Copy Link (starts with `signalcaptcha://`)
5. Run:
   ```bash
   curl -X POST http://localhost:8080/v1/register/+15183636994 \
     -H "Content-Type: application/json" \
     -d '{"captcha": "signalcaptcha://signal-hcaptcha.<TOKEN>", "use_voice": false}'
   ```
6. Enter the SMS verification code:
   ```bash
   curl -X POST http://localhost:8080/v1/register/+15183636994/verify/<CODE> \
     -H "Content-Type: application/json"
   ```

After registration, wire Signal to Hermes by adding to `~/.hermes/.env`:
```
SIGNAL_HTTP_URL=http://127.0.0.1:8080
SIGNAL_ACCOUNT=+15183636994
```

Then: `hermes gateway install && hermes gateway start`

## Security

- SSH: key-only, Tailscale-only (no public access)
- RDP: Tailscale-only (port 3389 blocked from public internet)
- fail2ban: running with default config
- UFW: default deny incoming, allow only on tailscale0 interface
- unattended-upgrades: security patches only
- Root login: disabled
- Password auth: disabled

## File Locations

| What | Where |
|------|-------|
| Terraform config | `./terraform/main.tf` |
| Docker compose | Droplet: `~/infra/docker-compose.yml` |
| Hermes config | Droplet: `~/.hermes/config.yaml` |
| Hermes env/keys | Droplet: `~/.hermes/.env` |
| Hermes identity | Droplet: `~/.hermes/SOUL.md` |
| OpenRouter env | Droplet: `~/.config/openrouter/env` |
| OpenCode config | Droplet: `~/.config/opencode/opencode.json` |
| Caddy config | Droplet: `/etc/caddy/Caddyfile` |
| Signal volume | Droplet: Docker volume `infra_signal-cli-data` |
| UFW rules | Droplet: managed via `ufw` commands |

## Credentials (NOT in this repo)

All secrets live in `.env` (gitignored). Template in `.env.example`:
- `DIGITALOCEAN_TOKEN` — DO API token (used by Terraform)
- `OPENROUTER_KEY` — OpenRouter API key
- `TWILIO_ACCOUNT_SID` — Twilio account
- `TWILIO_ACCOUNT_KEY` — Twilio auth token
- `TWILIO_API_SID` — Twilio API key SID
- `TWILIO_API_KEY` — Twilio API key secret

On the droplet, secrets are in:
- `~/.config/openrouter/env` (mode 600)
- `~/.hermes/.env` (mode 600)
- `~/.config/twilio/env` (mode 600) — not yet created

## Known Issues

1. **RDP is laggy** — xrdp + XFCE over Tailscale has noticeable input delay. Window operations (resize, move) are painful. Consider switching to NoMachine (NX protocol) or using a physical machine on the tailnet for interactive work.

2. **Browsers crash** — Firefox and Chromium installed as snaps, which don't work properly in xrdp sessions. Fix: install .deb versions directly instead of snaps.

3. **signal-cli requires Java 25** — The latest native signal-cli (0.14.3) needs Java 25 which Ubuntu 24.04 doesn't ship. We use the Docker container instead which bundles its own JRE.

4. **XFCE compositing** — Window compositing is enabled by default and makes RDP worse. Disable via: Settings → Window Manager Tweaks → Compositor → uncheck "Enable display compositing"

## Rebuilding From Scratch

1. `terraform apply` to create the droplet and DNS
2. SSH in as root, run hardening (create user, UFW, fail2ban, swap, timezone)
3. Install Tailscale, authenticate, lock down firewall to tailnet
4. Install XFCE + xrdp (or NoMachine)
5. Install Docker, Node.js 20 (nvm), Python 3.12 tools
6. Install Caddy
7. Configure OpenRouter credentials
8. Install OpenCode, configure for OpenRouter
9. Install Hermes Agent, configure for OpenRouter + Kimi K2.6
10. Start signal-cli-rest-api container
11. Register Signal number (CAPTCHA + SMS verification)
12. Wire Signal to Hermes gateway
13. Set up Pushover + health check cron
