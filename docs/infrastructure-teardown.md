# Infrastructure Teardown (May 20, 2026)

## What Was Destroyed

### DigitalOcean Droplet
- **Name:** clairy
- **ID:** 571687722
- **IP:** 167.172.240.17
- **Region:** NYC3
- **Size:** s-4vcpu-16gb-amd (4 vCPU, 16GB RAM)
- **Cost:** $84/mo + $16.80/mo backups = $100.80/mo
- **Method:** `terraform destroy -auto-approve`
- **DNS record:** `clairy.ckfce.com` A record also removed

The droplet had been running since May 18, 2026 (2 days). It was fully configured with XFCE, Docker, Tailscale, signal-cli container, Hermes, OpenCode, and Caddy. None of that state was backed up beyond what's in this git repo — it's all gone.

### Twilio Phone Number
- **Number:** +1 (518) 363-6994
- **SID:** PNf13f30a7ce8cdedd82c52c077e3beef7
- **Cost:** ~$1.15/mo
- **Method:** `DELETE /2010-04-01/Accounts/{SID}/IncomingPhoneNumbers/{NumberSID}.json`
- **Response:** HTTP 204 (success)

The number is released back to Twilio's pool. It cannot be recovered.

## What Still Exists

### Accounts (still active, not deleted)
- **DigitalOcean account** — still has other droplets and the `ckfce.com` domain
- **Twilio account** — still active, just no numbers on it. Could be useful later or closed.
- **OpenRouter account** — still active, API key still valid
- **Tailscale** — both `ryan@` and `clairy@` accounts still active

### Credentials That Are Now Dead
- `DIGITALOCEAN_TOKEN` — still valid for the DO account, but there's nothing to manage with it
- `TWILIO_*` credentials — still valid for the account, but the number is gone

### Credentials Still Useful
- `OPENROUTER_API_KEY` — needed for the MacBook setup
- `TELEGRAM_BOT_TOKEN` — needed for the MacBook setup

## Monthly Savings

| Item | Before | After |
|------|--------|-------|
| Droplet | $84.00 | $0 |
| Backups | $16.80 | $0 |
| Twilio | $1.15 | $0 |
| **Total** | **$101.95** | **$0** |

The MacBook costs nothing beyond electricity and internet already being paid for.
