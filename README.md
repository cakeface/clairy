# Clairy — Personal AI Agent (MacBook)

Configuration and onboarding for an always-on AI agent running on a MacBook Air, reachable via Telegram and connected to the home tailnet.

## Current Status

**Migrating from DigitalOcean droplet to local MacBook.** The droplet and Twilio number have been destroyed. The laptop is on the tailnet and needs agent stack setup.

### What's Done

- [x] MacBook Air on tailnet (`ryans-macbook-air`, 100.70.222.117, `clairy@` account)
- [x] Telegram bot created (token acquired)
- [x] OpenRouter account and API key
- [x] Old droplet destroyed (was $84/mo)
- [x] Old Twilio number released (was $1.15/mo, VoIP numbers can't register with Signal anyway)

### What's Remaining

- [ ] Install OpenCode on the MacBook
- [ ] Configure OpenCode with OpenRouter + Kimi K2.6
- [ ] Install Hermes Agent (or Open Claw as fallback)
- [ ] Wire Telegram bot to agent (BotFather setup, polling or webhook)
- [ ] Test end-to-end: message bot on Telegram, get a response
- [ ] Health check / heartbeat (Pushover or similar)
- [ ] SOUL.md identity filled in

## Architecture

```
[Ryan's phone/any device]
        |
    Telegram
        |
[Telegram Bot API]
        |
    getUpdates polling (or webhook)
        |
[Hermes Agent on MacBook]
        |
    OpenRouter API
        |
[Kimi K2.6 / other models]
```

## The MacBook

| Property | Value |
|----------|-------|
| Device | MacBook Air |
| Tailscale hostname | ryans-macbook-air |
| Tailscale IP | 100.70.222.117 |
| Tailscale account | clairy@ |
| Coding harness | OpenCode (OpenRouter) |
| Agent runtime | Hermes Agent (or Open Claw) |
| Messaging | Telegram bot |

## Credentials Needed on the MacBook

```bash
# These go in ~/.config/clairy/env or wherever the agent reads them:
OPENROUTER_API_KEY=sk-or-v1-...
TELEGRAM_BOT_TOKEN=...
```

See `.env.example` in this repo for the full list.

## Telegram Bot

The bot was created via BotFather. To wire it to the agent:

1. The agent polls `https://api.telegram.org/bot<TOKEN>/getUpdates` for incoming messages
2. When a message arrives, the agent processes it and replies via `sendMessage`
3. To chat with the bot, just open Telegram on any device and message it by its @username

There is no separate "bot UI" — you talk to it from regular Telegram like any other contact.

## Coding Harness: OpenCode

OpenCode is the coding tool on the MacBook (replaces Claude Code since we can't use the Pro subscription without browser OAuth on this machine).

Config: `config/opencode/opencode.json`

## Agent Runtime: Hermes (or Open Claw)

Still deciding between Hermes Agent and Open Claw. Hermes was partially configured on the old droplet and is the current plan. Open Claw is the fallback if Hermes doesn't work well.

Either way, the agent needs:
- A SOUL.md or equivalent identity file
- Telegram as the messaging channel
- OpenRouter as the LLM provider

## Onboarding (run on the MacBook)

This is the checklist for OpenCode on the laptop to pick up:

1. **Install OpenCode** — follow https://opencode.ai install instructions
2. **Set up env** — create `~/.config/clairy/env` with the keys from `.env.example`
3. **Configure OpenCode** — copy `config/opencode/opencode.json` to `~/.config/opencode/opencode.json`
4. **Install Hermes** — clone and install per their docs, configure for OpenRouter
5. **Configure Telegram** — set `TELEGRAM_BOT_TOKEN` in Hermes config, enable polling
6. **Test** — send a message to the bot from your phone, confirm response

## Tailnet Notes

The MacBook (`clairy@`) and work laptop (`ryan@`) are on different Tailscale accounts. This means:
- SSH works between them
- Taildrop does NOT work (different owners) — use SSH or another method to transfer files
- To fix: enable node sharing in Tailscale admin, or move both to same account

## What Was Tried and Abandoned

- **DigitalOcean droplet** — worked but expensive ($100/mo) and RDP was painful. Destroyed 2026-05-20.
- **Signal** — couldn't register because Twilio numbers are VoIP and Signal rejects them. Even with a real SIM, signal-cli registration requires CAPTCHA in a browser which was a hassle on the droplet.
- **Twilio number** (+1 518-363-6994) — released 2026-05-20. Useless for Signal, not needed for Telegram.
- **Claude Code on the laptop** — can't auth without browser OAuth to personal Google account. Using OpenCode + OpenRouter instead.

## File Layout

```
config/
  hermes/
    SOUL.md          — agent identity
    env.example      — hermes env vars template
  opencode/
    opencode.json    — opencode config for OpenRouter
.env.example         — top-level credential template
README.md            — this file
```
