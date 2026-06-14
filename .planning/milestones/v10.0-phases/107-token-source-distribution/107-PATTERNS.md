# Phase 107: Token Source & Distribution - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 7 new/modified files
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/tools/compile-tokens.js` | build-tool / transform | batch (JSON → CSS) | itself (extend in-place) | self-analog |
| `brandbook/tools/compile-tokens.test.mjs` | test | batch | itself (extend in-place) | self-analog |
| `priv/static/crosswake/tokens.css` | generated artifact | file-I/O output | `brandbook/tokens/tokens.css` | exact |
| `lib/mix/tasks/crosswake.gen.offline_ui.ex` | Mix generator task | file-I/O / request-response | itself (extend in-place) | self-analog |
| `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` | template | transform | itself (extend in-place) | self-analog |
| `examples/phoenix_host/priv/static/css/tokens.css` | static asset | file-I/O output | `examples/phoenix_host/priv/static/css/app.css` | role-match |
| `guides/tokens.md` | documentation | — | `guides/offline.md` | role-match |
| `mix.exs` | config | — | itself (extend `extras:` list) | self-analog |

---

## Pattern Assignments

### `brandbook/tools/compile-tokens.js` (build-tool, batch transform)

**Analog:** itself — extend in-place.

**Full current file** (`brandbook/tools/compile-tokens.js`, lines 1-74):

```javascript
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const JSON_PATH = path.join(ROOT, 'brandbook/tokens/crosswake.tokens.json');
const CSS_PATH = path.join(ROOT, 'brandbook/tokens/tokens.css');

// Flatten nested DTCG token tree to dot-path -> token map; skip $-prefixed metadata keys
function flattenTokens(obj, prefix, acc) {
  if (acc === undefined) { prefix = ''; acc = {}; }
  for (const [k, v] of Object.entries(obj)) {
    if (k.startsWith('$')) continue;
    const p = prefix ? prefix + '.' + k : k;
    if (v && typeof v === 'object' && '$value' in v) acc[p] = v;
    else if (v && typeof v === 'object') flattenTokens(v, p, acc);
  }
  return acc;
}

// Resolve "{primitive.foam.50}" -> "var(--cw-primitive-foam-50)"; pass non-aliases through
function resolveAlias(value) {
  if (typeof value === 'string' && value.startsWith('{') && value.endsWith('}'))
    return 'var(--cw-' + value.slice(1, -1).replace(/\./g, '-') + ')';
  return value;
}

function props(flat, paths, dark, isPrim) {
  return paths.map(p => {
    const t = flat[p];
    const raw = dark ? (t.$dark || t.$value) : t.$value;
    return '  --cw-' + p.replace(/\./g, '-') + ': ' + (isPrim ? raw : resolveAlias(raw)) + ';';
  }).join('\n');
}

function main() {
  let tokens;
  try { tokens = JSON.parse(fs.readFileSync(JSON_PATH, 'utf8')); }
  catch (err) { process.stderr.write('compile-tokens.js: ' + err.message + '\n'); process.exit(1); }

  const flat = flattenTokens(tokens);
  const all = Object.keys(flat).sort();
  const prim = all.filter(p => p.startsWith('primitive.'));
  const groups = ['surface', 'text', 'action', 'border', 'status', 'runtime'];
  const sem = all.filter(p => groups.some(g => p.startsWith(g + '.')));
  const darkSem = props(flat, sem, true, false);

  const out = [
    '/* GENERATED from crosswake.tokens.json — do not edit */',
    '/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */',
    '',
    '/* ─── Primitive tier (internal — do not reference directly in component CSS) ─── */',
    ':root {', props(flat, prim, false, true), '}', '',
    '/* ─── Semantic tier (public contract) ─── */',
    ':root {', props(flat, sem, false, false), '}', '',
    '/* ─── Dark mode ─── */',
    '@media (prefers-color-scheme: dark) {',
    '  :root:not([data-theme]) {',
    darkSem.replace(/^  /gm, '    '),
    '  }', '}', '',
    '[data-theme="dark"] {', darkSem, '}', '',
    '/* ─── Forbidden pairings (DO NOT USE) ─────────────────────────────────────────── */',
    '/* stone-500 on foam-50:  4.09:1 — fails AA normal text                           */',
    '/* wake-500  on foam-50:  2.95:1 — role issue; dark-surface only                  */',
    '/* mist-200  on foam-50:  1.35:1 — border/dark-surface only                       */',
    '',
  ].join('\n');

  fs.writeFileSync(CSS_PATH, out, 'utf8');
  process.stdout.write('brandbook/tokens/tokens.css written\n');
}

if (require.main === module) main();
module.exports = { flattenTokens, resolveAlias };
```

**Three insertion points for Phase 107:**

**Insertion 1 — new `PRIV_CSS_PATH` constant** (after line 7, alongside `CSS_PATH`):
```javascript
const PRIV_CSS_PATH = path.join(ROOT, 'priv/static/crosswake/tokens.css');
```

**Insertion 2 — new helpers** (add after `props()`, before `main()`):
```javascript
// Non-color token groups to emit in the fonts/dimensions tier
const NON_COLOR_GROUPS = ['font', 'text-scale', 'display-scale', 'line-height',
                           'spacing', 'radius', 'focus', 'tracking'];

// Serialize a non-color token value to a valid CSS string.
// fontFamily: array of family names → comma-joined, multi-word names quoted.
// dimension:  raw $value string (already a valid CSS string like "16px", "-0.02em").
function serializeNonColor(token) {
  if (token['$type'] === 'fontFamily') {
    return token['$value']
      .map(f => f.includes(' ') ? '"' + f + '"' : f)
      .join(', ');
  }
  return token['$value'];
}

function propsNonColor(flat, paths) {
  return paths.map(p => {
    return '  --cw-' + p.replace(/\./g, '-') + ': ' + serializeNonColor(flat[p]) + ';';
  }).join('\n');
}
```

**Insertion 3 — in `main()`** (after line 45 `const sem = ...`, and extending the `out` array, and adding the second write after line 69):
```javascript
// After `const sem = ...` (line 45):
const nonColor = all.filter(p => NON_COLOR_GROUPS.some(g => p.startsWith(g + '.')));

// Extend the `out` array — append new tier before the closing '' entry:
// (add to the array literal before the final .join('\n')):
'/* ─── Fonts & dimensions ─── */',
':root {', propsNonColor(flat, nonColor), '}', '',

// After fs.writeFileSync(CSS_PATH, ...) (line 69), add:
fs.mkdirSync(path.dirname(PRIV_CSS_PATH), { recursive: true });
fs.writeFileSync(PRIV_CSS_PATH, out, 'utf8');
process.stdout.write('priv/static/crosswake/tokens.css written\n');
```

**Critical constraint:** `props()` (line 28) calls `resolveAlias(t.$value)`. For `fontFamily` tokens, `t.$value` is a JS Array; `resolveAlias` returns the Array object, producing broken CSS. Always route non-color tokens through `serializeNonColor()`, never through `props()`.

---

### `brandbook/tools/compile-tokens.test.mjs` (test, batch)

**Analog:** itself — extend in-place. Read the full file above (lines 1-176).

**Import/setup pattern to match** (lines 1-16):
```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const TOKENS_CSS = resolve(ROOT, 'brandbook/tokens/tokens.css');
const COMPILE_SCRIPT = resolve(ROOT, 'brandbook/tools/compile-tokens.js');
```

**Add a new constant** alongside `TOKENS_CSS`:
```javascript
const PRIV_TOKENS_CSS = resolve(ROOT, 'priv/static/crosswake/tokens.css');
```

**Structural pattern for new tests** (copy from lines 109-163 — existsSync check, content read, string assertion):
```javascript
test('tokens.css contains --cw-font-display with quoted font stack', () => {
  const content = readFileSync(TOKENS_CSS, 'utf8');
  assert.ok(content.includes('--cw-font-display: "Space Grotesk"'),
    '--cw-font-display must start with quoted "Space Grotesk"');
});

test('priv/static/crosswake/tokens.css exists after script execution', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  assert.ok(existsSync(PRIV_TOKENS_CSS), 'priv/static/crosswake/tokens.css must exist');
});

test('priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  const brand = readFileSync(TOKENS_CSS, 'utf8');
  const priv  = readFileSync(PRIV_TOKENS_CSS, 'utf8');
  assert.strictEqual(brand, priv, 'both outputs must be byte-identical');
});
```

**Full list of new tests to add** (Wave 0 gaps from RESEARCH.md):
- `tokens.css contains --cw-font-display with quoted font stack`
- `tokens.css contains --cw-font-body with quoted font stack`
- `tokens.css contains --cw-font-mono with quoted font stack`
- `tokens.css contains --cw-text-scale-md: 16px`
- `tokens.css contains --cw-radius-lg: 14px`
- `tokens.css contains --cw-display-scale-sm: 28px`
- `priv/static/crosswake/tokens.css exists after script execution`
- `priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css`

---

### `priv/static/crosswake/tokens.css` (generated artifact, file-I/O output)

**Analog:** `brandbook/tokens/tokens.css` — byte-identical copy, produced by the same generator run.

**Expected complete output** (verified by RESEARCH.md enumeration against live JSON):

```css
/* GENERATED from crosswake.tokens.json — do not edit */
/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */

/* ─── Primitive tier (internal — do not reference directly in component CSS) ─── */
:root {
  --cw-primitive-brass-500: #C98A2E;
  --cw-primitive-brass-700: #946017;
  ... (all 17 primitives, same as brandbook/tokens/tokens.css lines 5-23)
}

/* ─── Semantic tier (public contract) ─── */
:root {
  --cw-action-bg: var(--cw-primitive-wake-700);
  ... (all 25 semantic tokens, same as brandbook/tokens/tokens.css lines 26-54)
}

/* ─── Dark mode ─── */
@media (prefers-color-scheme: dark) { ... }

[data-theme="dark"] { ... }

/* ─── Forbidden pairings (DO NOT USE) ─────────────────────────────────────────── */
...

/* ─── Fonts & dimensions ─── */
:root {
  --cw-display-scale-lg: 56px;
  --cw-display-scale-md: 40px;
  --cw-display-scale-sm: 28px;
  --cw-focus-ring-width: 2px;
  --cw-font-body: "Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --cw-font-display: "Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --cw-font-mono: "JetBrains Mono", SFMono-Regular, Consolas, "Liberation Mono", monospace;
  --cw-line-height-display-lg: 64px;
  --cw-line-height-display-md: 48px;
  --cw-line-height-display-sm: 36px;
  --cw-line-height-lg: 28px;
  --cw-line-height-md: 24px;
  --cw-line-height-sm: 20px;
  --cw-line-height-xl: 30px;
  --cw-line-height-xs: 16px;
  --cw-radius-lg: 14px;
  --cw-radius-md: 10px;
  --cw-radius-sm: 6px;
  --cw-radius-xl: 20px;
  --cw-spacing-base: 4px;
  --cw-text-scale-lg: 18px;
  --cw-text-scale-md: 16px;
  --cw-text-scale-sm: 14px;
  --cw-text-scale-xl: 20px;
  --cw-text-scale-xs: 12px;
  --cw-tracking-tight: -0.02em;
}
```

This file is NOT hand-authored — it is produced entirely by `node brandbook/tools/compile-tokens.js`. The planner should treat it as a verified output spec, not something to write manually.

**Note on existing file:** `brandbook/tokens/tokens.css` (the analog) already exists and carries the generated header on line 1. `priv/static/crosswake/tokens.css` does not exist yet; it will be created by the generator script. The directory `priv/static/crosswake/` does not exist either.

---

### `lib/mix/tasks/crosswake.gen.offline_ui.ex` (Mix generator task, file-I/O)

**Analog:** itself — extend in-place.

**`get_template_path/1` pattern** (lines 101-108) — the exact resolution pattern to copy for the new `get_tokens_css_path/0`:
```elixir
defp get_template_path(filename) do
  path = Application.app_dir(:crosswake, "priv/templates/crosswake/offline_ui/#{filename}")
  if File.exists?(path) do
    path
  else
    Path.join(File.cwd!(), "priv/templates/crosswake/offline_ui/#{filename}")
  end
end
```

**New function to add** (same pattern, new name and path):
```elixir
defp get_tokens_css_path do
  path = Application.app_dir(:crosswake, "priv/static/crosswake/tokens.css")
  if File.exists?(path) do
    path
  else
    Path.join(File.cwd!(), "priv/static/crosswake/tokens.css")
  end
end
```

**`ensure_file/2` pattern** (lines 117-133) — reuse without modification for the tokens.css copy:
```elixir
defp ensure_file(path, contents) do
  File.mkdir_p!(Path.dirname(path))

  case File.read(path) do
    {:ok, _existing} ->
      Mix.shell().info("  reused #{Path.relative_to_cwd(path)}")
      :reused

    {:error, :enoent} ->
      File.write!(path, contents)
      Mix.shell().info("  created #{Path.relative_to_cwd(path)}")
      :created

    {:error, reason} ->
      Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
  end
end
```

**`run/1` call-site pattern** (lines 50-53) — add one new `ensure_file` call alongside the existing four:
```elixir
ensure_file(controller_dest, controller_content)
ensure_file(root_layout_dest, root_layout_content)
ensure_file(page_dest, page_content)
ensure_file(js_dest, js_content)
# ADD:
tokens_css_dest = Path.join([dir, "priv", "static", "assets", "tokens.css"])
ensure_file(tokens_css_dest, File.read!(get_tokens_css_path()))
```

**Destination path note:** The generator writes to `priv/static/assets/tokens.css` (standard Phoenix host convention). The example host uses a non-standard path (`priv/static/css/`) and is vendored manually — not via a generator run.

**Do NOT use `File.cp!/2`** — it overwrites existing files. `ensure_file/2` preserves a host-customized copy and logs "reused".

---

### `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` (template, transform)

**Analog:** itself — extend in-place.

**Full current file** (lines 1-16):
```html
<!DOCTYPE html>
<html lang="en" class="[scrollbar-gutter:stable]">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    <.live_title default="Offline Island">
      {assigns[:page_title]}
    </.live_title>
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static type="module" src={~p"/assets/offline.js"}></script>
  </head>
  <body class="bg-cw-foam-50 text-cw-current-950 antialiased">
    <%%= @inner_content %>
  </body>
</html>
```

**Change:** Insert one `<link>` line immediately before the existing `app.css` link (line 10):
```html
    <link phx-track-static rel="stylesheet" href={~p"/assets/tokens.css"} />
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
```

**Pattern rule:** `phx-track-static` is used on both links (matches the existing `app.css` link convention — Phoenix cache-busting). Token custom properties must be defined before consuming rules, so `tokens.css` must come first.

**Phase 107 scope:** Only the `<link>` is added. The `<body class="bg-cw-foam-50 text-cw-current-950 antialiased">` body classes are unchanged — Phase 108 rewires those to token vars.

---

### `examples/phoenix_host/priv/static/css/tokens.css` (static asset, file-I/O output)

**Analog:** `examples/phoenix_host/priv/static/css/app.css` (sits alongside it) and the package `priv/static/crosswake/tokens.css` (byte-identical source).

**Vendoring mechanism:** This file is a verbatim copy of `priv/static/crosswake/tokens.css` placed in the example host's static CSS directory. It is NOT generated by the generator task (the generator targets `priv/static/assets/` for standard hosts; the example host uses `priv/static/css/`).

**Manual vendor step:** Copy `priv/static/crosswake/tokens.css` → `examples/phoenix_host/priv/static/css/tokens.css`. Commit both files.

**How it is linked** (matches the example host pattern from `DeckLive.Index` line 15 and `DeckLive.Show` line 15):
```html
<link rel="stylesheet" href="/css/tokens.css" />
<link rel="stylesheet" href="/css/app.css" />
```

The existing link pattern in `DeckLive.Index` and `DeckLive.Show` is:
```elixir
<link rel="stylesheet" href="/css/app.css" />
```
Add the `tokens.css` link immediately before this line in both LiveView render functions. Note: the example host uses plain href strings (`"/css/app.css"`), not Phoenix verified routes (`~p"/css/app.css"`). Match that convention.

---

### `guides/tokens.md` (documentation)

**Analog:** `guides/offline.md` — same placement, same capability-oriented naming convention, same ExDoc extras registration pattern.

**Style from `guides/offline.md` line 1-3:**
```markdown
# Crosswake Offline Guide

Crosswake Phase 4 proves one narrow offline story on purpose:
```

**Content outline** (from D-10 and RESEARCH.md §7):
```markdown
# Crosswake Token Distribution

## Source

`crosswake.tokens.json` (W3C DTCG 2025.10, frozen v9.0 brand contract)

## Generate

```
node brandbook/tools/compile-tokens.js
```

Outputs:
- `brandbook/tokens/tokens.css` — brand book reference copy (linked by `brandbook/index.html`)
- `priv/static/crosswake/tokens.css` — distributable copy (ships in the Hex package)

Both files are byte-identical. Diff them to verify parity:
```
diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css
```

## What ships in the package

`priv/static/crosswake/tokens.css` is in the `priv/` tree, which is in the Hex
`files:` whitelist. The `brandbook/` tree is excluded from the package.

## How consumers receive tokens.css

### Via `mix crosswake.gen.offline_ui`

The generator copies `priv/static/crosswake/tokens.css` (no-clobber) into the
host's `priv/static/assets/tokens.css` and adds a `<link>` for it in the generated
`offline_root.html.heex` before `app.css`.

If you have customized the copy in your host, re-running the generator will not
overwrite it (it logs "reused" and skips the write).

### Direct Phoenix host

Copy `priv/static/crosswake/tokens.css` to your host's static CSS directory
(e.g., `priv/static/css/tokens.css` or `priv/static/assets/tokens.css`) and
link it before `app.css`:

```html
<link rel="stylesheet" href="/css/tokens.css" />
<link rel="stylesheet" href="/css/app.css" />
```

`tokens.css` must load before `app.css` so `--cw-*` custom properties are
defined before any rules that consume them.

## Contract

- Never hand-edit `tokens.css` in any consumer — edit `crosswake.tokens.json`
  and regenerate with one Node command.
- All `--cw-*` custom properties are defined in `tokens.css`; consuming rules
  reference them via `var(--cw-*)`.
- The distributable and brand book copies must remain byte-identical. Phase 109
  adds a CI gate that asserts this with `diff`.
```

---

### `mix.exs` (config — `extras:` list)

**Analog:** itself — add one entry to the existing `extras:` list.

**Current `extras:` list** (lines 90-109):
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "LICENSE",
  "guides/install.md",
  "guides/support_matrix.md",
  "guides/adopter_profiles.md",
  "guides/adoption.md",
  "guides/user_flows.md",
  "guides/capabilities.md",
  "guides/bridge.md",
  "guides/offline.md",
  "guides/commerce.md",
  "guides/companions.md",
  "guides/compatibility.md",
  "guides/native_shell.md",
  "guides/android_uat.md",
  "guides/packs.md",
  "guides/threadline.md"
],
```

**Add one entry** — `"guides/tokens.md"` — to this list. Placement: alongside the other capability guides (after `"guides/offline.md"` is a natural fit since it documents the token distribution mechanism that supports offline UI).

**`groups_for_extras:` note** (lines 116-125): The existing `Guides: ~r/guides\//` catch-all regex (line 124) will automatically pick up `guides/tokens.md` under the Guides group in ExDoc. No change needed to `groups_for_extras:`.

**`files:` whitelist** (line 78) — already covers `guides` and `priv`:
```elixir
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides),
```
No change needed — `priv/static/crosswake/tokens.css` ships automatically once created.

---

## Shared Patterns

### Generated-file header
**Source:** `brandbook/tokens/tokens.css` lines 1-2
**Apply to:** `priv/static/crosswake/tokens.css` (by construction — both emitted from same `out` string)
```css
/* GENERATED from crosswake.tokens.json — do not edit */
/* Edit crosswake.tokens.json, then run: node brandbook/tools/compile-tokens.js */
```

### `props()` CSS declaration format
**Source:** `brandbook/tools/compile-tokens.js` lines 28-34
**Apply to:** `serializeNonColor()` / `propsNonColor()` — same `--cw-` prefix, same dot-to-dash replacement, same two-space indent, same trailing `;`
```javascript
'  --cw-' + p.replace(/\./g, '-') + ': ' + value + ';'
```

### `ROOT`-anchored paths in Node scripts
**Source:** `brandbook/tools/compile-tokens.js` lines 5-7
**Apply to:** `PRIV_CSS_PATH` declaration — always use `path.join(ROOT, '...')`, never a relative path
```javascript
const ROOT = path.resolve(__dirname, '../..');
const PRIV_CSS_PATH = path.join(ROOT, 'priv/static/crosswake/tokens.css');
```

### `Application.app_dir` + `File.cwd!()` fallback
**Source:** `lib/mix/tasks/crosswake.gen.offline_ui.ex` lines 101-108
**Apply to:** `get_tokens_css_path/0` — identical dual-branch pattern
```elixir
path = Application.app_dir(:crosswake, "priv/...")
if File.exists?(path), do: path, else: Path.join(File.cwd!(), "priv/...")
```

### `ensure_file/2` no-clobber copy
**Source:** `lib/mix/tasks/crosswake.gen.offline_ui.ex` lines 117-133
**Apply to:** tokens.css copy step in `run/1` — reuse the function as-is, no modification
```elixir
ensure_file(tokens_css_dest, File.read!(get_tokens_css_path()))
```

### `phx-track-static` link attribute
**Source:** `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` line 10
**Apply to:** new `tokens.css` `<link>` in that same template
```html
<link phx-track-static rel="stylesheet" href={~p"/assets/tokens.css"} />
```

### Plain href (no verified route) in example host
**Source:** `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex` line 15
**Apply to:** `tokens.css` link added to `DeckLive.Index` and `DeckLive.Show`
```elixir
<link rel="stylesheet" href="/css/tokens.css" />
```

---

## No Analog Found

None — every file in scope has a strong analog or is a self-extension.

---

## Metadata

**Analog search scope:** `brandbook/tools/`, `lib/mix/tasks/`, `priv/templates/`, `examples/phoenix_host/lib/`, `examples/phoenix_host/priv/static/`, `guides/`, `mix.exs`
**Files read:** 9 source files read in full
**Pattern extraction date:** 2026-06-13
