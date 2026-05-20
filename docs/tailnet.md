# Tailnet Setup

## Current Devices

| Hostname | IP | Owner | OS | Status |
|----------|-----|-------|------|--------|
| kwqf93tq6y (work laptop) | 100.119.43.38 | ryan@ | macOS | online |
| ryans-macbook-air | 100.70.222.117 | clairy@ | macOS | online |
| clairy (droplet) | 100.68.70.24 | ryan@ | linux | destroyed |

## Two Different Accounts

The work laptop and the MacBook Air are on different Tailscale accounts (`ryan@` and `clairy@`). This happened because the MacBook was set up with a separate identity.

### What Works Across Accounts
- SSH (if enabled)
- Direct IP connectivity

### What Doesn't Work
- **Taildrop** — file transfer between devices owned by different accounts is blocked. We hit this trying to send keys from the work laptop to the MacBook.

### Workarounds for File Transfer
- SSH + clipboard: `ssh user@100.70.222.117 'cat > file.txt' <<< "content"`
- Google Chat or any messaging app both machines can access
- If SSH remote login is enabled on the MacBook, `scp` works fine

### Fixing It
To make Taildrop work, either:
1. Move both devices to the same Tailscale account
2. Enable node sharing in the Tailscale admin console
3. Set up a shared tailnet (Tailscale's multi-user feature)

This is a minor annoyance, not a blocker. SSH covers most needs.
