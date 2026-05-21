---
name: gws-email
description: Read, search, and manage Gmail via gws CLI. Use for checking email, reading messages, searching inbox, or unsubscribing.
allowed-tools: Bash
---

# Gmail via Google Workspace CLI (gws)

Access Gmail through the `gws` CLI tool. The authenticated account is **ryan@ckfce.com**.

## Critical: gws only outputs raw JSON

The gws CLI has no markdown, table, or human-readable output for Gmail. Every operation returns raw JSON that must be parsed. **Always use a single Python script** for any operation that touches multiple messages. Bash for-loops with piped python parsing silently fail because gws writes keyring messages to stderr that corrupt the pipe.

## The One Pattern That Works

For checking email, always use this pattern — a single Python script that lists then fetches:

```bash
python3 -c "
import json, subprocess

result = subprocess.run(
    ['gws', 'gmail', 'users', 'messages', 'list', '--params',
     json.dumps({'userId': 'me', 'q': 'in:inbox is:unread newer_than:7d', 'maxResults': 25})],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
msgs = data.get('messages', [])
print(f'Found {len(msgs)} unread messages')
print()

for m in msgs:
    mid = m['id']
    r = subprocess.run(
        ['gws', 'gmail', 'users', 'messages', 'get', '--params',
         json.dumps({'userId': 'me', 'id': mid, 'format': 'full'})],
        capture_output=True, text=True
    )
    try:
        d = json.loads(r.stdout)
        hdrs = {h['name']: h['value'] for h in d.get('payload', {}).get('headers', [])}
        print(f\"FROM: {hdrs.get('From', '?')}\")
        print(f\"SUBJ: {hdrs.get('Subject', '?')}\")
        print(f\"DATE: {hdrs.get('Date', '?')}\")
        print(f\"SNIP: {d.get('snippet', '')[:180]}\")
        print('---')
    except Exception as e:
        print(f'FAILED: {mid} - {e}')
        print('---')
" 2>/dev/null
```

After fetching, triage the results for the user: categorize into action items, worth a glance, and noise. Be opinionated about what matters vs what's marketing spam.

## New in gws 0.18+ (Gmail Helpers)

These features were added in gws 0.18-0.22 and simplify common operations:

- **`+read` helper:** Extracts message body and key headers directly — avoids manual base64 decoding for simple reads.
- **Attachments:** `-a/--attach` flags with 25MB validation for sending.
- **`--draft` flag (0.22+):** Save messages as drafts instead of sending immediately. Available on send helpers.
- **Forward with attachments:** Forward now includes original message attachments by default.
- **`+reply/+reply-all --html`:** Preserves inline images in HTML replies.
- **Auto From header:** Send auto-populates From with display name from send-as settings.

## Key Gotchas

1. **stderr noise:** gws prints `Using keyring backend: keyring` to stderr. Always use `2>/dev/null` when piping to python/jq, or use `capture_output=True` in subprocess.
2. **Always use `format: full`:** The `format: metadata` with `metadataHeaders` param is unreliable — headers silently don't appear. Use `format: full` and parse `.payload.headers[]` (array of `{name, value}` objects).
3. **Never use bash for-loops:** Bash loops that pipe gws output to python fail silently. Always use a single Python script with `subprocess.run()` for batch operations.
4. **userId is always "me":** For the authenticated user, pass `"userId": "me"`.
5. **Snippets are HTML-encoded:** Snippets contain `&#39;` for apostrophes, `&amp;` for ampersands, etc. Good enough for triage but decode if displaying to user.
6. **Auth token migration (0.22.3+):** gws moved to strict OS keychain on macOS. After upgrading, credentials are wiped — must re-auth with `gws auth login`. The old `credentials.json`/`credentials.enc` files are no longer used.

## Gmail Search Operators

The `q` parameter accepts standard Gmail search syntax:

| Operator | Example | Purpose |
|----------|---------|---------|
| `from:` | `from:kagi` | Sender |
| `to:` | `to:me` | Recipient |
| `subject:` | `subject:invoice` | Subject line |
| `in:` | `in:inbox`, `in:sent` | Mailbox |
| `is:` | `is:unread`, `is:starred` | Message state |
| `has:` | `has:attachment` | Has attachment |
| `after:` | `after:2026/03/01` | Date filter |
| `before:` | `before:2026/03/10` | Date filter |
| `newer_than:` | `newer_than:7d` | Relative date |
| `label:` | `label:important` | By label |
| `""` | `"exact phrase"` | Exact match |
| `-` | `-from:noreply` | Exclude |
| `OR` | `from:a OR from:b` | Either match |
| `category:` | `category:promotions` | Gmail category |

Common queries:
- Unread this week: `in:inbox is:unread newer_than:7d`
- From a person: `from:someone@example.com`
- Alerts only: `from:alert@dtdg.co OR from:noreply+signals@firehydrant.com`
- Skip noise: `in:inbox is:unread -category:promotions -category:social`

## Reading a Single Message

```bash
# Quick snippet (headers may be missing but snippet is there)
gws gmail users messages get --params '{"userId": "me", "id": "MESSAGE_ID", "format": "metadata"}' 2>/dev/null

# Full headers and body parts
gws gmail users messages get --params '{"userId": "me", "id": "MESSAGE_ID", "format": "full"}' 2>/dev/null
```

Body is base64url-encoded in `.payload.body.data` or nested in `.payload.parts[].body.data` for multipart messages:

```python
import base64
base64.urlsafe_b64decode(data + '==').decode('utf-8')
```

## Unsubscribing from Promotional Email

Extract `List-Unsubscribe` header from `format: full`, then POST to the https URL:

```python
import urllib.request, urllib.parse

# List-Unsubscribe header is comma-separated, may have mailto: and https: URLs
# Always pick the https one. Split on comma, strip whitespace and angle brackets.
url = "https://..."
data = urllib.parse.urlencode({'List-Unsubscribe': 'One-Click'}).encode()
req = urllib.request.Request(url, data=data, method='POST')
req.add_header('User-Agent', 'Mozilla/5.0')
resp = urllib.request.urlopen(req, timeout=15)
print(f'{resp.status} - unsubscribed')
```

For batch unsubscribe, collect all URLs first, then confirm with the user which senders to keep before firing. Confirm before unsubscribing — it's irreversible.

## Sending Email

```python
import base64
from email.mime.text import MIMEText

msg = MIMEText("Body text here")
msg['to'] = 'recipient@example.com'
msg['subject'] = 'Subject line'
raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
```

```bash
gws gmail users messages send --params '{"userId": "me"}' --json '{"raw": "BASE64_HERE"}' 2>/dev/null
```

## Other Operations

```bash
# List labels
gws gmail users labels list --params '{"userId": "me"}' 2>/dev/null

# Modify labels (mark as read) — requires gmail.modify scope
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"removeLabelIds": ["UNREAD"]}' 2>/dev/null

# Trash a message
gws gmail users messages trash --params '{"userId": "me", "id": "MSG_ID"}' 2>/dev/null

# Get full thread
gws gmail users threads get --params '{"userId": "me", "id": "THREAD_ID"}' 2>/dev/null
```

## Auth Setup

- GCP project: `rpollockgwscli` (owned by ryan@ckfce.com)
- OAuth consent screen has ryan@ckfce.com as a test user
- Current scopes include gmail.readonly, gmail.send, gmail.labels (but NOT gmail.modify — label changes may fail)
- Switch accounts: `gws auth logout && gws auth login`
- Check status: `gws auth status 2>/dev/null`
