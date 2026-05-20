# Telegram Bot Setup

## What We Have

A Telegram bot created via BotFather. The token is in `.env` as `TELEGRAM_BOT_TOKEN`.

## How Telegram Bots Work

Telegram bots are not like user accounts. You don't "log in as the bot" on a device. There is no bot UI. Instead:

1. You create the bot via @BotFather in Telegram (done)
2. BotFather gives you a token (done)
3. Your code uses the token to call the Bot API
4. Users (including you) message the bot by finding its @username in Telegram

To **send messages to the bot**, just open regular Telegram on any device and search for the bot's username. It shows up like any other contact.

To **make the bot respond**, you need code running that either:
- Polls `getUpdates` (simpler, no public URL needed, good for a laptop)
- Receives webhooks at a public URL (better for servers)

Since the MacBook is behind a tailnet with no public IP, polling via `getUpdates` is the way to go.

## Bot API Basics

```bash
# Check if the bot is alive
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"

# Get recent messages sent to the bot
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates"

# Send a message (you need the chat_id from getUpdates)
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d "chat_id=CHAT_ID&text=hello from clairy"
```

## Wiring to Hermes

Hermes Agent should be configured to poll the Telegram Bot API for incoming messages and respond via `sendMessage`. The exact config depends on which version of Hermes we end up using and whether it has native Telegram support or needs a gateway script.

## Security Note

The bot token grants full control of the bot. Anyone with the token can read messages and send as the bot. Keep it in `.env` (gitignored) and never commit it.

To restrict who can talk to the bot, the agent code should check the `chat_id` or `user_id` of incoming messages and only respond to Ryan's Telegram account.
