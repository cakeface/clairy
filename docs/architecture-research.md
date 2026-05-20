# Architecture Research

What we've learned and decided about how Clairy should be built.

## The stack

Clairy runs on a MacBook Air on Ryan's home tailnet. The machine is not logged into any personal accounts (no Google, no Apple ID for services, no browser OAuth). Everything runs via API keys.

| Layer | Choice | Why |
|-------|--------|-----|
| Hardware | MacBook Air | Already owned, on tailnet, no monthly cost |
| LLM provider | OpenRouter | API key auth, model flexibility, no login |
| Default model | Kimi K2.6 | Capable, cheap via OpenRouter |
| Coding harness | OpenCode | Terminal-native, works with OpenRouter, no OAuth |
| Agent runtime | Hermes Agent (primary) or OpenClaw (fallback) | Self-hosted, Telegram support, persistent memory |
| Messaging | Telegram bot | Trivial setup, no phone number needed, works everywhere |
| Networking | Tailscale | Connects to Ryan's other devices, SSH between machines |

## Why these choices

**OpenRouter over direct API keys:** Model flexibility without managing multiple provider accounts. One key, many models. Can switch from Kimi to Claude to GPT without reconfiguring.

**Telegram over Signal:** Signal requires a real phone number (VoIP numbers are rejected) and registration involves a browser CAPTCHA. Telegram bots are created in 30 seconds via BotFather and need nothing but a token. Detailed postmortem in `signal-postmortem.md`.

**MacBook over a cloud server:** The original plan was a DigitalOcean droplet ($100/mo) but it was expensive for experimentation, RDP was painful, and Claude Code couldn't auth on it. The MacBook costs $0/mo incremental and is on the tailnet already. Detailed teardown in `infrastructure-teardown.md`.

**OpenCode over Claude Code:** Claude Code requires browser OAuth to Ryan's Google account. The MacBook is intentionally not logged into personal accounts. OpenCode works with just an OPENROUTER_API_KEY env var. See `opencode.md`.

## Agent runtime options

### Hermes Agent (primary choice)

Self-improving CLI agent by Nous Research. 156K GitHub stars. Supports 300+ models. Key features: persistent memory, automated skill creation, sandboxed execution, tool use. Should work with OpenRouter as the LLM backend.

The plan is to configure Hermes with Telegram as the messaging channel and OpenRouter as the model provider.

### OpenClaw (fallback)

Self-hosted personal AI assistant framework by Peter Steinberger. A local Gateway (WebSocket server) bridges AI agents to messaging platforms. Supports Telegram natively via grammY. Has a sophisticated system prompt architecture (SOUL.md for personality, AGENTS.md for rules, USER.md for owner context, MEMORY.md for learned patterns).

OpenClaw is more complex to set up but more powerful. It has session management, inter-agent communication, tool sandboxing, and a plugin system. If Hermes doesn't work well with Telegram, OpenClaw is the next thing to try.

Detailed architecture research at RYAI's repo: `ryai-claw/data/research/openclaw-architecture.md`.

## Design principles from RYAI

Ryan built RYAI (his work AI) from scratch and learned a lot. These principles carry over:

**Single agent, many tools.** Don't split into multiple specialized agents. One smart agent with access to many tools beats a hierarchy of dumber agents trying to coordinate.

**State in files.** Markdown files in a git repo are the brain. Tasks, daily logs, research, cached data, operational state. Git gives you versioning and durability for free. If it's not written down, it didn't happen.

**Cache aggressively.** Don't re-search external systems every time. When you find something useful, save it locally. Local files are fast and free.

**Identity in the repo.** The agent's personality, rules, and context all live in the repo alongside the state. The whole thing is portable and auditable.

**Tools over integrations.** Build small CLI tools that the agent can call, rather than complex integration platforms. Each tool does one thing, reads credentials from env vars, and is simple enough to audit.

## Coding harness landscape (May 2026)

For non-agent coding work on the MacBook (setup tasks, debugging, prototyping), the options are:

**Aider** — Best pure BYOK option. Any model (Claude, GPT, Gemini, local via Ollama). Git-native with auto-commits. Auto-test/lint cycle. Python-based. 45K stars.

**OpenCode** — Most polished TUI. 160K stars. 75+ providers. Plan/Build mode. But Anthropic may have blocked direct Claude usage (route through OpenRouter instead).

**Goose** — Most model-flexible general-purpose agent. 15+ providers. Rust-based. MCP extensions. More Swiss army knife than pure coding tool.

**Gemini CLI** — 1000 free requests/day with just a Google API key. Locked to Gemini models but unbeatable free tier for experimentation.

**Codex CLI** — OpenAI's Rust-based terminal agent. Fast, good TUI, but locked to OpenAI models only.

We chose OpenCode for the MacBook's coding harness. Detailed comparison in the RYAI research file: `ryai-claw/data/research/terminal-ai-coding-agents-landscape-2026-05-20.md`.

## What's next

The remaining setup steps (from README.md):

1. Install OpenCode on the MacBook
2. Configure OpenCode with OpenRouter + Kimi K2.6
3. Install Hermes Agent (or OpenClaw as fallback)
4. Wire Telegram bot to agent (polling mode, since no public IP)
5. Test end-to-end: message bot on Telegram, get a response
6. Set up health check / heartbeat
7. Fill in SOUL.md with Clairy's real identity (use `about-clairy.md` as source material)
