---
name: gws-docs
description: Read Google Docs and search Drive via gws CLI. Use for Google Docs URLs, fileIds, or requests to read/find documents.
allowed-tools: Bash
---

# Google Docs & Drive via Google Workspace CLI (gws)

Access Google Docs and Google Drive through the `gws` CLI tool. The authenticated account is **ryan@ckfce.com**.

## Critical: gws only outputs raw JSON

Same pattern as other gws skills — raw JSON output, stderr noise, use Python subprocess for anything non-trivial.

## Extracting a Document ID

Google Docs URLs contain the document ID. Extract it from URLs like:
- `https://docs.google.com/document/d/DOCUMENT_ID/edit`
- `https://docs.google.com/document/d/DOCUMENT_ID/edit#heading=h.xxx`

The document ID is the long alphanumeric string between `/d/` and `/edit`.

Calendar event attachments also provide `fileId` directly.

## Reading a Google Doc

**Use the Drive export API for reading.** Export as **markdown** — it preserves tables, links, headers, bold/italic, and correctly resolves smart chips (dates, people, status dropdowns) that the Docs API mangles.

```bash
gws drive files export --params '{"fileId": "DOCUMENT_ID_HERE", "mimeType": "text/markdown"}' -o doc.md 2>/dev/null
```

**Critical: output path must be within the current working directory.** As of gws 0.22.5, the `-o` flag rejects absolute paths that resolve outside `$PWD` (e.g., `-o /tmp/doc.md` fails with a 400 on macOS because `/tmp` → `/private/tmp`). Always use relative paths like `-o doc.md` or `-o ./exports/doc.md`.

**Important: strip base64 images after export.** Google embeds images as inline base64 data URIs that bloat the file 10x+ and waste context. Always strip them:

```bash
# Remove reference-style image definitions (the giant base64 lines at the bottom)
sed -i '' '/^\[image[0-9]*\]: <data:image/d' doc.md
# Replace reference-style image usages with placeholder
sed -i '' 's/!\[\]\[image[0-9]*\]/[image]/g' doc.md
# Also handle inline-style base64 images if present
sed -i '' 's/!\[[^]]*\](data:image[^)]*)/[image]/g' doc.md
```

Google uses reference-style images (`![][image1]` with `[image1]: <data:image/png;base64,...>` at the bottom). This strips both the definitions and the references.

Tables render as proper markdown tables. Links to Jira tickets, Google Docs, and other resources come through as clickable markdown links. Headers preserve their hierarchy.

**Limitations of Drive export:**
- **Multi-tab docs return 0 bytes for markdown export.** This is a known bug. The export "succeeds" but the file is empty. Use `text/plain` as a fallback, or use the Docs API with `includeTabsContent` (see below).
- Exports the entire document — no per-tab targeting.
- **Markdown export does not include comments.** Google Doc comments, suggestions, and margin notes are completely stripped. If you need comments, either use `text/plain` export (comments appear as footnote-style references like `[a]`, `[b]` at the end) or pull comments separately via the Drive Comments API (see below).
- **Smart chip person names** (e.g., `@Ryan Pollock`) render correctly in plain text export but as empty strings in the Docs API `textRun` elements. If you need person names, use the plain text export.

For single-tab docs, markdown export is the default. For multi-tab docs, use plain text export or the Docs API tab-aware pattern below.

## Reading Document Comments

The Drive Comments API provides structured, threaded comment data separately from the document body. This is useful when:
- You need to understand active review discussions on a doc
- The user asks to resolve, summarize, or respond to comments
- You're in a live meeting and need a fresh snapshot of comment activity

```bash
gws drive comments list --params '{"fileId": "DOCUMENT_ID_HERE", "fields": "comments(id,author,content,quotedFileContent,createdTime,resolved,replies)"}' 2>/dev/null
```

Each comment includes:
- `author.displayName` — who wrote it
- `content` — the comment text
- `quotedFileContent.value` — the exact passage being commented on
- `createdTime` — when it was posted
- `resolved` — whether the thread is resolved
- `replies[]` — full reply thread with authors and content

This is richer than the plain text footnotes — you get proper threading, resolution status, and the quoted context. Use it whenever comment content matters rather than relying on the plain text export's footnote format.

## Reading Multi-Tab Documents

Multi-tab Google Docs require the Docs API with `includeTabsContent: True`. The Drive export returns 0 bytes for markdown on multi-tab docs.

**Critical:** Tab content lives at `tabs[].documentTab.body.content`, NOT `tabs[].body.content`. The `documentTab` wrapper is required.

```bash
python3 -c "
import json, subprocess

DOC_ID = 'DOCUMENT_ID_HERE'
TARGET_TAB_ID = 'tab-id-from-url'  # e.g., 't.t3orgb4s23ga' from ?tab=t.t3orgb4s23ga

result = subprocess.run(
    ['gws', 'docs', 'documents', 'get', '--params',
     json.dumps({'documentId': DOC_ID, 'includeTabsContent': True})],
    capture_output=True, text=True)
data = json.loads(result.stdout)

# List all tabs
for tab in data.get('tabs', []):
    props = tab.get('tabProperties', {})
    body = tab['documentTab']['body']
    content = body.get('content', [])
    print(f'Tab: \"{props.get(\"title\", \"\")}\" id={props.get(\"tabId\", \"?\")} elements={len(content)}')

# Extract text from a specific tab
for tab in data.get('tabs', []):
    props = tab.get('tabProperties', {})
    if props.get('tabId') == TARGET_TAB_ID:
        body = tab['documentTab']['body']
        for elem in body.get('content', []):
            if 'paragraph' in elem:
                text = ''
                for pe in elem['paragraph'].get('elements', []):
                    text += pe.get('textRun', {}).get('content', '')
                if text.strip():
                    print(text.rstrip())
            elif 'table' in elem:
                for row in elem['table'].get('tableRows', []):
                    cells = []
                    for cell in row.get('tableCells', []):
                        cell_text = ''
                        for c in cell.get('content', []):
                            if 'paragraph' in c:
                                for pe in c['paragraph'].get('elements', []):
                                    cell_text += pe.get('textRun', {}).get('content', '')
                        cells.append(cell_text.strip())
                    print(' | '.join(cells))
        break
" 2>/dev/null
```

Without `includeTabsContent`, the API returns content in the top-level `body` field (first/default tab only) and `tabs` is empty. With it, content moves into each tab's `documentTab.body` and the top-level `body` is empty. Always use `includeTabsContent: True` to be safe.

**Hybrid approach for multi-tab docs with person names:** Export plain text (which resolves smart chips including person names) AND use the Docs API for structure. The plain text export concatenates all tabs.

**When to use the Docs API instead:**
- Writing/editing a doc (batchUpdate requires the Docs API)
- Finding insert indexes for writes
- Reading link URLs (not in plain text export)
- Inspecting document structure

The Docs API read pattern (for writes or structural inspection only):

```bash
python3 -c "
import json, subprocess, sys

DOC_ID = 'DOCUMENT_ID_HERE'

result = subprocess.run(
    ['gws', 'docs', 'documents', 'get', '--params',
     json.dumps({'documentId': DOC_ID})],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
print(f'Title: {data.get(\"title\", \"?\")}')

body = data.get('body', {})
for i, elem in enumerate(body.get('content', [])[:20]):
    start = elem.get('startIndex', 0)
    end = elem.get('endIndex', 0)
    text = ''
    if 'paragraph' in elem:
        style = elem['paragraph'].get('paragraphStyle', {}).get('namedStyleType', 'NORMAL_TEXT')
        for pe in elem['paragraph'].get('elements', []):
            text += pe.get('textRun', {}).get('content', '')
        print(f'Element {i}: index {start}-{end} style={style}: {repr(text[:80])}')
" 2>/dev/null
```

After reading, summarize the key points for the user rather than dumping the raw text.

## Searching Google Drive for Documents

Use Drive's `files.list` with a query to find documents:

```bash
python3 -c "
import json, subprocess

# Search by name
query = 'name contains \"meeting notes\" and mimeType=\"application/vnd.google-apps.document\"'

result = subprocess.run(
    ['gws', 'drive', 'files', 'list', '--params',
     json.dumps({
         'q': query,
         'pageSize': 10,
         'fields': 'files(id,name,modifiedTime,owners,webViewLink)',
         'orderBy': 'modifiedTime desc'
     })],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
files = data.get('files', [])
print(f'Found {len(files)} documents')
for f in files:
    owner = f.get('owners', [{}])[0].get('displayName', '?') if f.get('owners') else '?'
    print(f'  {f.get(\"name\", \"?\")}')
    print(f'    id: {f.get(\"id\", \"?\")}')
    print(f'    modified: {f.get(\"modifiedTime\", \"?\")}')
    print(f'    owner: {owner}')
    print(f'    link: {f.get(\"webViewLink\", \"\")}')
    print()
" 2>/dev/null
```

## Drive Query Syntax

The `q` parameter for `drive.files.list` uses a specific query language:

| Operator | Example | Purpose |
|----------|---------|---------|
| `name contains` | `name contains "standup"` | Partial name match |
| `name =` | `name = "Exact Title"` | Exact name match |
| `mimeType =` | `mimeType = "application/vnd.google-apps.document"` | File type filter |
| `modifiedTime >` | `modifiedTime > "2026-03-01T00:00:00"` | Modified after date |
| `trashed =` | `trashed = false` | Exclude trashed files |
| `'email' in owners` | `'user@example.com' in owners` | By owner |
| `sharedWithMe` | `sharedWithMe = true` | Shared with me |
| `fullText contains` | `fullText contains "search term"` | Full-text search |

Combine with `and` / `or`:
```
name contains "retro" and mimeType = "application/vnd.google-apps.document" and modifiedTime > "2026-01-01T00:00:00"
```

## Common MIME Types

| Type | MIME |
|------|------|
| Google Doc | `application/vnd.google-apps.document` |
| Google Sheet | `application/vnd.google-apps.spreadsheet` |
| Google Slides | `application/vnd.google-apps.presentation` |
| Google Form | `application/vnd.google-apps.form` |
| Folder | `application/vnd.google-apps.folder` |
| PDF | `application/pdf` |

## Document Structure Reference (Docs API)

Only relevant when writing to docs or inspecting structure. The Docs API body contains `content` elements:

- **paragraph:** Has `paragraphStyle.namedStyleType` (NORMAL_TEXT, HEADING_1-6, TITLE, SUBTITLE) and `elements[]` containing `textRun`, `person`, `dateElement`, or `richLink` objects.
- **table:** Has `tableRows[]`, each with `tableCells[]`, each containing nested `content[]` (paragraphs). Cell values may use smart chips (`dateElement`, `person`) and dropdown status chips (rendered as private-use Unicode like `\ue907` — these are NOT readable via the Docs API).
- **sectionBreak:** Page/section divider, usually ignorable.

**Smart chip element types** (in addition to `textRun`):
- `dateElement` — `dateElementProperties.displayText` has the rendered date
- `person` — `personProperties.name` and `personProperties.email`
- `richLink` — embedded links to other Google resources

**Important:** Status dropdown chips (Completed, In Progress, Not Started) render as opaque Unicode characters in the Docs API. The Drive export (`text/plain`) resolves them correctly. Always use Drive export for reading.

## Writing to a Google Doc

Use `documents.batchUpdate` to insert, delete, or format text. The `--json` flag passes the request body (NOT `--data`).

### Insert text at a position

Every character in a Google Doc has an index. Index 1 is right after the document title element. To insert at the top of the doc body (after the title):

```bash
gws docs documents batchUpdate \
  --params '{"documentId":"DOC_ID"}' \
  --json '{
    "requests": [
      {
        "insertText": {
          "location": {"index": INSERT_INDEX},
          "text": "Your text here\nWith newlines\n"
        }
      }
    ]
  }' 2>/dev/null
```

### Finding the right insert index

Read the doc first and inspect the structural elements to find where to insert:

```bash
gws docs documents get --params '{"documentId":"DOC_ID"}' 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for i, elem in enumerate(data.get('body', {}).get('content', [])[:10]):
    start = elem.get('startIndex', 0)
    end = elem.get('endIndex', 0)
    text = ''
    if 'paragraph' in elem:
        for pe in elem['paragraph'].get('elements', []):
            text += pe.get('textRun', {}).get('content', '')
    print(f'Element {i}: index {start}-{end}: {repr(text[:80])}')
"
```

Typically for 1:1 docs, insert after the title (look for the `endIndex` of the title element, or use the `startIndex` of the first blank line after the title). A common pattern: the title ends at index ~24, with a blank paragraph at 24-25, so inserting at index 25 puts content right below the title.

### Important notes for writing

- **`--json` not `--data`:** The request body flag is `--json`, not `--data`. Using `--data` will error.
- **Inserted text inherits the paragraph style at the insert index.** If you insert into a HEADING_2 paragraph, your text becomes Heading 2. Always check the `paragraphStyle.namedStyleType` of the element at your insert index and make sure it's NORMAL_TEXT. If it's not, find a NORMAL_TEXT paragraph to insert into instead.
- **For bullet lists, use `createParagraphBullets`:** `insertText` alone won't create bullets. After inserting text, add a `createParagraphBullets` request in the same `batchUpdate` with the range covering the lines that should be bulleted and a `bulletPreset` like `"BULLET_DISC_CIRCLE_SQUARE"`. Calculate the start/end indexes carefully.
- **Indexes shift after inserts:** If making multiple inserts in one batchUpdate, process them from bottom to top (highest index first) so earlier inserts don't shift later indexes. Or use a single insert with all the text concatenated.
- **Escape single quotes in bash:** If your text contains apostrophes, use `'\''` to break out of the single-quoted string, or use a Python subprocess to avoid shell escaping issues.
- **The response includes a `requiredRevisionId`:** A successful write returns `{"documentId": "...", "replies": [{}], "writeControl": {"requiredRevisionId": "..."}}`. An empty `replies` array with no error means success.

## Key Gotchas

1. **stderr noise:** Always use `2>/dev/null` or `capture_output=True`.
2. **Large docs are verbose:** The Docs API returns every formatting detail. The Python extraction pattern above strips it down to readable text. For very large docs, the output can be huge — consider reading just the first N paragraphs.
3. **Lists have no list marker in the text:** Bullet/numbered list items are just paragraphs with a `bullet` field. The `bullet.nestingLevel` tells you the indent depth. You must add your own `-` or number.
4. **Tables are deeply nested:** Each cell contains its own array of content elements (paragraphs). The extraction pattern above handles simple single-paragraph cells.
5. **Links are in textStyle, not in the text:** A hyperlink's URL is in `textRun.textStyle.link.url`, not in the visible text.
6. **Drive search is different from Docs read:** Use `gws drive files list` to find documents, then `gws docs documents get` to read them. They're separate APIs.
7. **fields parameter for Drive:** Always specify `fields` in Drive queries to limit response size. Without it you get everything including permissions, thumbnails, etc.
