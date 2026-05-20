# Signal: Why It Didn't Work

Signal was the original messaging channel for the agent. Here's why it was abandoned.

## The VoIP Problem

Signal requires a phone number to register. We bought a Twilio number for $1.15/mo. When we tried to register with Signal, it returned "unsupported phone line type."

This is because Twilio numbers are VoIP lines. Signal explicitly blocks VoIP numbers to prevent bot/spam accounts. This is a deliberate policy decision by Signal, not a bug, and there is no workaround on the Twilio side.

## Alternatives We Considered

- **Prepaid SIM** (~$15/mo) — would work but requires a physical phone or SIM reader
- **JMP.chat** (~$3/mo) — provides real mobile numbers that forward SMS, explicitly supports Signal registration
- **Google Voice** — also VoIP, same problem

## The CAPTCHA Problem

Even with a valid phone number, signal-cli registration requires solving a CAPTCHA in a browser. On the droplet, this meant:

1. RDP into the box over Tailscale (laggy)
2. Open a browser (which was crashing because Ubuntu snaps don't work right in xrdp)
3. Solve the CAPTCHA
4. Copy a `signalcaptcha://` URL
5. POST it to the signal-cli-rest-api container

This is a one-time operation, but the browser situation on the droplet was bad enough that we never completed it.

## signal-cli Operational Concerns

Even if registration had worked, signal-cli has ongoing maintenance issues:

- Requires Java 25 (latest signal-cli 0.14.3), which Ubuntu 24.04 doesn't ship. We used a Docker container to work around this.
- Signal pushes protocol changes that can break signal-cli without notice. When this happens, messages stop flowing until the container is updated.
- The session keys in the Docker volume are irreplaceable — losing them means re-registration from scratch.
- The JVM uses 300-500MB RAM at runtime.

## Why Telegram is Better for This Use Case

- Bots are created instantly via BotFather, no phone number needed
- No CAPTCHA, no registration ceremony
- The Bot API is a simple HTTP REST API — poll or webhook
- No JVM, no Docker container, no session keys to lose
- Works from any device where you have Telegram installed
- Much lighter operationally
