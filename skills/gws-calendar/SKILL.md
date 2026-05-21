---
name: gws-calendar
description: Read and manage Google Calendar via gws CLI. Use for schedule, meetings, free time, or calendar queries.
allowed-tools: Bash
---

# Google Calendar via Google Workspace CLI (gws)

Access Google Calendar through the `gws` CLI tool. The authenticated account is **ryan@ckfce.com**.

## Critical: gws only outputs raw JSON

Same as Gmail — gws has no human-readable output for Calendar. Every operation returns raw JSON. **Always use a single Python script** for any operation that touches multiple events or needs formatting. The same gotchas from gws-email apply: stderr noise, bash for-loop failures, etc.

## The One Pattern That Works

For checking today's schedule, always use this pattern:

```bash
python3 -c "
import json, subprocess, sys
from datetime import datetime, timedelta

# Get today's date boundaries in ISO format with timezone
today = datetime.now().strftime('%Y-%m-%d')
time_min = f'{today}T00:00:00-04:00'
time_max = f'{today}T23:59:59-04:00'

result = subprocess.run(
    ['gws', 'calendar', 'events', 'list', '--params',
     json.dumps({
         'calendarId': 'primary',
         'timeMin': time_min,
         'timeMax': time_max,
         'singleEvents': True,
         'orderBy': 'startTime',
         'maxResults': 50
     })],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
events = data.get('items', [])
print(f'Found {len(events)} events for {today}')
print()

for e in events:
    start = e.get('start', {})
    end = e.get('end', {})
    start_time = start.get('dateTime', start.get('date', '?'))
    end_time = end.get('dateTime', end.get('date', '?'))
    summary = e.get('summary', '(no title)')

    # Format time portion only
    if 'T' in start_time:
        st = start_time.split('T')[1][:5]
        et = end_time.split('T')[1][:5]
        time_str = f'{st}-{et}'
    else:
        time_str = 'all-day'

    # Attendee count (exclude resources)
    attendees = [a for a in e.get('attendees', []) if not a.get('resource')]
    n_attendees = len(attendees)

    # Response status
    my_status = 'unknown'
    for a in e.get('attendees', []):
        if a.get('self'):
            my_status = a.get('responseStatus', 'unknown')

    print(f'{time_str}  {summary}')
    if n_attendees > 0:
        print(f'  {n_attendees} attendees, my status: {my_status}')

    # Show attached docs (meeting notes links)
    for att in e.get('attachments', []):
        print(f'  doc: {att.get(\"title\", \"?\")} -> {att.get(\"fileUrl\", \"\")}')

    # Show Zoom link if present
    conf = e.get('conferenceData', {})
    for ep in conf.get('entryPoints', []):
        if ep.get('entryPointType') == 'video':
            print(f'  zoom: {ep.get(\"uri\", \"\")}')
            break

    print()
" 2>/dev/null
```

After fetching, present the schedule as a readable narrative. Call out conflicts, back-to-backs, and prep-worthy meetings.

## Key Parameters

- **calendarId:** Always `"primary"` for the user's main calendar.
- **timeMin / timeMax:** ISO 8601 with timezone offset. Use `-04:00` for US Eastern (EDT) or `-05:00` for EST.
- **singleEvents:** Must be `true` to expand recurring events into individual instances. Required when using `orderBy: startTime`.
- **orderBy:** Use `"startTime"` (requires `singleEvents: true`).
- **maxResults:** Default 250, max 2500.

## Event Object Key Fields

| Field | Description |
|-------|-------------|
| `summary` | Event title |
| `start.dateTime` / `start.date` | Start time (dateTime for timed, date for all-day) |
| `end.dateTime` / `end.date` | End time |
| `attendees[]` | Array of `{email, displayName, responseStatus, self, resource, organizer}` |
| `attachments[]` | Array of `{fileId, fileUrl, title, mimeType}` — often meeting notes docs |
| `conferenceData` | Zoom/Meet links in `.entryPoints[]` |
| `description` | Event description (may contain HTML) |
| `location` | Physical location or room |
| `status` | `confirmed`, `tentative`, `cancelled` |
| `htmlLink` | Link to the event in Google Calendar |
| `eventType` | `default`, `focusTime`, `outOfOffice`, `workingLocation` |

## Attendee Response Statuses

- `accepted` — confirmed
- `declined` — not attending
- `tentative` — maybe
- `needsAction` — hasn't responded

## Checking Multi-Day Range

Adjust `timeMin` and `timeMax` for any date range. For this week:

```python
from datetime import datetime, timedelta
today = datetime.now()
monday = today - timedelta(days=today.weekday())
friday = monday + timedelta(days=4)
time_min = monday.strftime('%Y-%m-%dT00:00:00-04:00')
time_max = friday.strftime('%Y-%m-%dT23:59:59-04:00')
```

## Finding Free Time

List all events for a day, then compute gaps between them. Events with `eventType: focusTime` or `outOfOffice` are calendar blocks, not real meetings.

## Other Operations

```bash
# List all calendars the user has access to
gws calendar calendarList list 2>/dev/null

# Get a single event by ID
gws calendar events get --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' 2>/dev/null

# Quick check of upcoming events (next N hours)
# Use timeMin=now and timeMax=now+Nhours
```

## New in gws 0.16+ (Calendar Improvements)

- **Account timezone (0.16+):** Calendar helpers now use the Google account timezone (fetched from Calendar Settings API with 24-hour caching) instead of machine local time. This means event times are accurate regardless of machine TZ settings.
- **Google Meet support (0.17+):** Calendar `+insert` helper supports adding Google Meet video conferencing to events.
- **`--dry-run` support (0.19+):** Available on events `+renew` and `+subscribe` commands for testing without side effects.

## Key Gotchas

1. **stderr noise:** gws prints `Using keyring backend: keyring` to stderr. Always use `2>/dev/null` or `capture_output=True`.
2. **singleEvents is required for orderBy:** If you use `orderBy: startTime` without `singleEvents: true`, the API returns an error.
3. **Timezone matters:** Always include the timezone offset in timeMin/timeMax. Without it, the API may use UTC and miss events. As of 0.16+, gws helpers use the account timezone, but raw API calls still need explicit offsets.
4. **All-day events use `date` not `dateTime`:** Check for both `start.dateTime` and `start.date`.
5. **Resource attendees:** Conference rooms show up in attendees with `resource: true`. Filter them out when counting people.
6. **Attachments contain meeting doc links:** Calendar event attachments (usually Google Docs) are the meeting notes. The `fileId` can be passed to `gws docs documents get` to read them.
7. **Auth token migration (0.22.3+):** gws moved to strict OS keychain on macOS. After upgrading, credentials are wiped — must re-auth with `gws auth login`.
