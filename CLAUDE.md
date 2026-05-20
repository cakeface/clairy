# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Clairy is a personal AI agent project. This repo contains configuration, identity files, and documentation for an always-on agent that runs on a MacBook Air, communicates via Telegram, and uses OpenRouter for LLM access. There is no application code here yet — it's config, docs, and onboarding material.

## Architecture

```
Ryan (any device) → Telegram → Bot API → Agent runtime (MacBook) → OpenRouter → Kimi K2.6
```

- **Machine:** MacBook Air on a Tailscale tailnet (`ryans-macbook-air`, 100.70.222.117)
- **Agent runtime:** Hermes Agent (or OpenClaw as fallback)
- **LLM:** Kimi K2.6 via OpenRouter
- **Messaging:** Telegram bot (polling mode, no public IP)
- **Coding harness:** OpenCode (not Claude Code — can't auth on this machine)

The MacBook is intentionally not logged into personal accounts. Everything uses API keys.

## Key Files

- `config/hermes/SOUL.md` — agent identity/personality
- `config/hermes/env.example` — env vars template for hermes
- `config/opencode/opencode.json` — OpenCode config for OpenRouter
- `.env` — live credentials (gitignored)
- `.env.example` — credential template

## Documentation

The `docs/` directory contains detailed context that agents working in this repo should read:

- `docs/about-clairy.md` — who Clairy is, personality, purpose, relationship to RYAI
- `docs/about-ryan.md` — owner context, preferences, communication style
- `docs/architecture-research.md` — stack decisions, design principles, alternatives considered
- `docs/telegram.md` — how the Telegram bot works, API examples, security notes
- `docs/tailnet.md` — device topology, the two-account problem, file transfer
- `docs/opencode.md` — why OpenCode, config details
- `docs/history.md` — project narrative from droplet to MacBook
- `docs/signal-postmortem.md` — why Signal was abandoned
- `docs/infrastructure-teardown.md` — what was destroyed, cost savings

Read `docs/about-clairy.md` and `docs/about-ryan.md` first for personality and owner context. Read `docs/architecture-research.md` for technical decisions.

## Credentials

Two env vars power everything:
- `OPENROUTER_API_KEY` — LLM access via OpenRouter
- `TELEGRAM_BOT_TOKEN` — Telegram bot control

These live in `.env` (gitignored). Never commit them.

## Design Principles

These come from Ryan's experience building RYAI (his work AI):

- Single agent with many tools, not multi-agent hierarchies
- State lives in markdown files in git repos
- Cache aggressively — don't re-fetch what you've already found
- Build small CLI tools the agent can call, not complex integration platforms
- Identity and personality live in the repo alongside the code

## Working in This Repo

Always check `docs/` for existing context before starting work. If you learn something new or make a decision, update the relevant doc (or create a new one). The docs are the project's memory — if it's not written down, the next agent session won't know it.

## Style

Ryan prefers prose over bullet lists, informal modern language, no emojis. Write things down as stories. Red/green TDD for any code. Meaningful git commits that explain the "why."
