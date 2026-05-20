# OpenCode Setup

## Why OpenCode Instead of Claude Code

Claude Code requires OAuth authentication through a browser. Ryan's personal Claude account uses Google auth. On the MacBook Air (which is meant to be an "AI laptop" not logged into personal accounts), there's no way to complete the browser OAuth flow without logging into Ryan's personal Google account on that machine.

Options considered:
- **API key mode** — Claude Code supports `ANTHROPIC_API_KEY` which bypasses OAuth entirely, but bills per-token against API credits instead of using the Pro subscription
- **Copy OAuth credentials** from the authenticated machine — risky and may not work across machines
- **Just use OpenCode** with OpenRouter — clean separation, works immediately

OpenCode with OpenRouter was the path of least resistance.

## Configuration

The config lives at `config/opencode/opencode.json` in this repo. On the MacBook, copy it to `~/.config/opencode/opencode.json`.

```json
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
```

The API key is read from the `OPENROUTER_API_KEY` environment variable. Set it in your shell profile or source it from `~/.config/clairy/env`.

## Model Choice

We're using Kimi K2.6 via OpenRouter as the default model. It's capable, cheap, and available. You can add more models to the config (Claude, GPT-4, etc.) by adding entries to the `models` object and switching `model.default`.

## Installation

Follow https://opencode.ai for current install instructions. On macOS it's typically:

```bash
brew install opencode  # or whatever their current method is
```

Check their docs — install methods change.
