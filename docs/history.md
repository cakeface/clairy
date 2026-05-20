# Project History

## The Original Plan (May 2026)

The idea was simple: run an always-on AI agent on a DigitalOcean droplet, reachable via Signal messenger. Ryan would text the agent, the agent would respond using Kimi K2.6 via OpenRouter, and life would be good.

We provisioned a beefy droplet (4 vCPU, 16GB RAM, $84/mo plus $16.80 for backups) running Ubuntu 24.04 in NYC3. It had XFCE for a desktop, xrdp for remote access over Tailscale, Docker for signal-cli, Caddy for future webhooks, and the whole thing was hardened with UFW, fail2ban, and key-only SSH.

The agent stack was Hermes Agent talking to OpenRouter, with OpenCode as the coding tool on the box.

## What Went Wrong

Three things derailed the droplet plan:

**Signal registration was a nightmare.** Signal requires a phone number, so we bought a Twilio number (+1 518-363-6994, $1.15/mo). But Signal rejects VoIP numbers outright — "unsupported phone line type." This is an anti-spam measure and there's no workaround. You need a real mobile SIM or a service like JMP.chat that provides actual mobile numbers.

Even if we'd solved the number problem, signal-cli registration requires solving a CAPTCHA in a browser on the machine. The RDP experience was so bad (laggy XFCE over Tailscale) that interactive browser work was painful.

**Claude Code couldn't auth on the droplet.** Ryan's Claude Code subscription uses Google OAuth. The droplet had no way to complete the browser-based auth flow without a working browser session. API keys would work but bill per-token instead of using the Pro subscription — not ideal.

**The droplet was expensive for experimentation.** $100/mo for a box that was mostly sitting idle while we debugged registration issues.

## The Pivot (May 20, 2026)

We decided to scrap the droplet entirely and move to Ryan's MacBook Air, which was already on the tailnet. The changes:

- **Droplet → MacBook Air** on the tailnet (`ryans-macbook-air`, 100.70.222.117)
- **Signal → Telegram** because Telegram bots are trivial to create (BotFather, done) and don't require phone number registration
- **Claude Code → OpenCode** because Claude Code can't auth without browser OAuth to Ryan's personal Google account
- **Twilio → nothing** because Telegram doesn't need a phone number for bots

We destroyed the droplet via `terraform destroy` and released the Twilio number via their API, both on May 20, 2026. Monthly spend went from ~$102/mo to $0.

## Current State

The MacBook is on the tailnet. OpenRouter keys and Telegram bot token exist. The repo has been rewritten with an onboarding checklist. Next step is installing OpenCode and Hermes on the laptop and wiring up the Telegram bot.
