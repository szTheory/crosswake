# Phase 107: Token Source & Distribution — Research

**Researched:** 2026-06-13
**Domain:** DTCG token emission (Node.js), Elixir Mix generator tasks, CSS custom properties, Hex package distribution
**Confidence:** HIGH (all findings verified against live code)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Emit the full font + dimension token set already present in `crosswake.tokens.json` — `font.*` (`display`, `body`, `mono`), `text-scale.*`, `display-scale.*`, `line-height.*`, `spacing.*`, `radius.*`, `focus.*`, `tracking.*` — not just the subset today's consumers reference.
- **D-02:** Keep the existing emit convention: dot-path → `--cw-…` (`font.display → --cw-font-display`, `text-scale.md → --cw-text-scale-md`, `radius.lg → --cw-radius-lg`).
- **D-03:** Font families (DTCG `fontFamily` arrays) serialize to a comma-joined CSS font stack with multi-word names quoted. Dimension tokens emit their raw `$value` string. These are NOT alias values — they bypass the `resolveAlias` path used for semantic colors.
- **D-04:** Non-color tokens are emitted in their own clearly-labeled `:root` block(s) appended after the semantic-color tier. No dark-mode variants (none defined in JSON). NOT duplicated into the dark-mode blocks.
- **D-05:** Single mechanism: generate once → copy the generated artifact → link it. No consumer ever re-declares brand values.
- **D-06:** `brandbook/` excluded from Hex package (`exclude_patterns: ["brandbook"]`). Therefore `compile-tokens.js` must also write a packaged mirror at `priv/static/crosswake/tokens.css`. Both files are byte-identical.
- **D-07:** `crosswake.gen.offline_ui` copies the packaged `tokens.css` verbatim into the host's static assets using the existing `ensure_file` no-clobber guard. Generated `offline_root.html.heex` links it as a separate `<link>` placed before `app.css`.
- **D-08:** The in-repo example host uses the identical mechanism — vendors the same packaged `priv/static/crosswake/tokens.css` into its own static dir and links it. Toolchain-free.
- **D-09:** Rejected — inlining tokens.css into `<style>` block. Rejected — serving dependency's `priv/static` via host-side `Plug.Static`.
- **D-10:** The distribution mechanism must be written down as a doc this phase delivers.
- **D-11:** Paths must be statically checkable — each consumer ends up with a single known file containing `--cw-` declarations; the two generated copies must be byte-diffable for parity.

### Claude's Discretion

- Exact packaged path name (`priv/static/crosswake/tokens.css` recommended) and exact host destination filename.
- Internal refactor of `compile-tokens.js` (`props()` helper split, second `writeFileSync`, font/dimension serialization helpers) is an implementation detail.
- Documentation file placement.

### Deferred Ideas (OUT OF SCOPE)

- Consumer rewiring (`app.css` + offline_ui templates onto semantic tokens; remove Tailwind classes + stale generator theme) → Phase 108.
- Drift-prevention CI gate (fail on hardcoded hex / missing `var(--cw-` in normalized consumers) → Phase 109.
- Parity assertion that both copies are byte-identical → likely Phase 109's gate.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKN-04 | `compile-tokens.js` emits `font.*` family tokens (`--cw-font-display`, `--cw-font-body`, `--cw-font-mono`) into `tokens.css` | D-01/D-03: `flattenTokens()` already produces these keys; new serialization path needed for array `$value`. Exact output verified by simulation. |
| TOKN-05 | `compile-tokens.js` emits dimension tokens (`text-scale.*`, `display-scale.*`, `radius.*`, etc.) into `tokens.css` | D-01/D-03: all 23 dimension tokens enumerated; raw `$value` strings work directly; no `$dark` variants. |
| NORM-03 | `tokens.css` reaches both consumers through one explicit, documented distribution mechanism | D-05..D-10: vendor-by-copy mechanism with `priv/static/crosswake/tokens.css` as the packaged bridge and `ensure_file` as the copy primitive. |

</phase_requirements>

---

## Summary

Phase 107 extends `brandbook/tools/compile-tokens.js` to emit a third `:root` block containing all font and dimension tokens, then establishes and documents the one mechanism that carries `tokens.css` to both consumers.

**The generator change is surgical.** `flattenTokens()` already traverses and captures all 27 non-color tokens (3 `fontFamily` + 24 `dimension`). They are currently silently discarded because the `groups` allow-list at line 44 only includes color group names. The fix adds a new non-color filter, a new serialization helper for `fontFamily` arrays (the existing `props()` function cannot handle array `$value` — it would produce broken CSS), and a second `writeFileSync` to emit the packaged mirror at `priv/static/crosswake/tokens.css`. The directory `priv/static/crosswake/` does not yet exist and must be created by the script.

**The distribution mechanism is already structurally present.** `crosswake.gen.offline_ui.ex` already has `ensure_file/2` (no-clobber copy) and `get_template_path/1` (resolves `Application.app_dir(:crosswake, "priv/...")` with a dev-cwd fallback). The generator needs a new `ensure_file` call to copy `priv/static/crosswake/tokens.css` into the host's static directory, and `offline_root.html.heex.eex` needs a `<link>` for the copied file added before the existing `app.css` link. (Phase 108 will rewire consumer classes; Phase 107 only establishes the link/copy contract.)

**The example host is already almost correct.** It serves CSS from `/css/` (i.e., `priv/static/css/app.css` → served at `/css/app.css`). The vendored `tokens.css` should land alongside it at `priv/static/css/tokens.css`, served as `/css/tokens.css`. The host's LiveView layouts that currently inline `<link rel="stylesheet" href="/css/app.css">` would add a parallel `<link>` for `/css/tokens.css`.

**Primary recommendation:** Implement in this order: (1) extend `compile-tokens.js` with font/dimension emit + priv mirror write + new Node tests, (2) extend `gen.offline_ui` to copy the mirror + add the link stub to the template, (3) vendor the file into the example host manually, (4) write the distribution guide.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token value storage | Build-time JSON | — | `crosswake.tokens.json` is the single source; never edited at runtime |
| Token CSS generation | Node.js build tool | — | `compile-tokens.js` transforms JSON → CSS; no runtime involvement |
| Package-time distribution bridge | `priv/static/crosswake/` | — | `priv/` is in the Hex `files:` whitelist; `brandbook/` is excluded. The mirror bridges the gap. |
| Install-time copy to host | Mix generator task | — | `ensure_file` in `gen.offline_ui.ex` — same pattern as other generated files |
| CSS link declaration | Generator template (`.eex`) | Host layout | Template adds `<link>` stub; host owns actual layout after generation |
| Example host vendored copy | In-repo static file | — | `examples/phoenix_host/priv/static/css/tokens.css` — no build step, direct file copy |
| Distribution documentation | `guides/` | — | Follows ExDoc extras convention; auto-appears in the "Guides" group |

---

## Standard Stack

### Core (no new dependencies)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Node.js `fs`, `path` | stdlib | Read JSON, write two CSS files | Already the only deps in `compile-tokens.js`; test explicitly asserts no npm packages |
| `node:test` + `node:assert/strict` | Node 22.x | Test the extended generator | Already used by `compile-tokens.test.mjs` (17 tests, all green) |
| Elixir `File.cp!/2` or `ensure_file/2` | stdlib | Copy packaged CSS to host static | `ensure_file` already implemented in `gen.offline_ui.ex` |

[VERIFIED: live code] No new npm or Hex dependencies are introduced.

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `mix hex.build --unpack` via `script/verify_hex_tarball.sh` | Validate `priv/static/crosswake/tokens.css` ships in the package | After implementing the priv mirror; confirms `files: ~w(... priv ...)` covers new path |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Second `writeFileSync` in same script | Separate script / `cp` in a Makefile | Single script = one command, one truth; separate script adds toolchain surface. D-10 says one command. |
| `File.cp!/2` in generator | `ensure_file/2` | `ensure_file` provides the no-clobber guard explicitly; `File.cp!` would overwrite host customizations — wrong. |
| `guides/tokens.md` | `brandbook/DISTRIBUTION.md` | `guides/` is in `files:` whitelist and ExDoc extras; `brandbook/` is excluded from the package. The guide must be in `guides/`. |

**Installation:** No packages to install. [VERIFIED: live code — `compile-tokens.js` imports only `fs` and `path`; `package.json` in `brandbook/tools/` has only `opentype.js` as a dependency, which is unrelated to this phase.]

---

## Package Legitimacy Audit

No external packages are installed by this phase. All implementation uses Node.js stdlib (`fs`, `path`) and Elixir stdlib (`File`, `Application`).

**Packages removed due to slopcheck:** none  
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
crosswake.tokens.json
        |
        v
compile-tokens.js  (node brandbook/tools/compile-tokens.js)
        |
        +---> brandbook/tokens/tokens.css       (brand book reference — kept for index.html)
        |
        +---> priv/static/crosswake/tokens.css  (packaged mirror — ships in Hex)
                    |
          [Hex package published]
                    |
          +---------+---------+
          |                   |
          v                   v
mix crosswake.gen.offline_ui   examples/phoenix_host (manual vendor)
          |                         |
          | ensure_file (no-clobber)| direct file copy
          v                         v
host/priv/static/assets/tokens.css  examples/phoenix_host/priv/static/css/tokens.css
          |                         |
          v                         v
offline_root.html.heex              deck_live/index.ex + show.ex
  <link href="/assets/tokens.css">   <link href="/css/tokens.css">
  <link href="/assets/app.css">      <link href="/css/app.css">
```

### Recommended Project Structure (changes only)

```
brandbook/tools/
├── compile-tokens.js          # MODIFIED: add font/dim emit + second writeFileSync
└── compile-tokens.test.mjs    # MODIFIED: add ~6-8 new tests for font/dim/priv

priv/static/                   # NEW directory (does not exist yet)
└── crosswake/
    └── tokens.css             # NEW: packaged mirror, byte-identical to brandbook copy

priv/templates/crosswake/offline_ui/
└── offline_root.html.heex.eex  # MODIFIED: add tokens.css <link> before app.css

examples/phoenix_host/priv/static/css/
├── app.css                    # unchanged
└── tokens.css                 # NEW: vendored copy

guides/
└── tokens.md                  # NEW: distribution mechanism doc (NORM-03)

mix.exs                        # possibly MODIFIED: add guides/tokens.md to extras list
```

### Pattern 1: Non-color token serialization in compile-tokens.js

**What:** A new filter selects the non-color token groups from `flat`, then a new serialization helper converts each token to a CSS declaration, handling `fontFamily` arrays and `dimension` raw strings differently.

**When to use:** Whenever a token's `$type` is `fontFamily` (value is a JS array) vs. `dimension` (value is a plain string).

```javascript
// Source: derived from compile-tokens.js pattern + crosswake.tokens.json structure
// [VERIFIED: live code]

const NON_COLOR_GROUPS = ['font', 'text-scale', 'display-scale', 'line-height',
                           'spacing', 'radius', 'focus', 'tracking'];

function serializeNonColor(token) {
  if (token['$type'] === 'fontFamily') {
    // $value is an array; multi-word names must be quoted for valid CSS
    return token['$value']
      .map(f => f.includes(' ') ? '"' + f + '"' : f)
      .join(', ');
  }
  // $type === 'dimension': $value is already a valid CSS string ("16px", "-0.02em")
  return token['$value'];
}

function propsNonColor(flat, paths) {
  return paths.map(p => {
    return '  --cw-' + p.replace(/\./g, '-') + ': ' + serializeNonColor(flat[p]) + ';';
  }).join('\n');
}
```

**Key constraint:** `props()` at line 28 of `compile-tokens.js` cannot be reused for non-color tokens because it reads `t.$value` and passes it to `resolveAlias()`. For `fontFamily`, `t.$value` is a JavaScript Array object, not a string; `resolveAlias` would return the raw Array, producing broken CSS (`--cw-font-mono: JetBrains Mono,SFMono-Regular,...`). A separate helper is required. [VERIFIED: live code + Node.js simulation]

### Pattern 2: Second writeFileSync for the packaged mirror

**What:** After writing `CSS_PATH` (brandbook copy), write the same content to `PRIV_CSS_PATH`. The directory must exist first (Node.js `fs.mkdirSync` with `{ recursive: true }`).

**When to use:** At the end of `main()`, after `out` is constructed and `CSS_PATH` is written.

```javascript
// Source: compile-tokens.js pattern [VERIFIED: live code]

const PRIV_CSS_PATH = path.join(ROOT, 'priv/static/crosswake/tokens.css');

// In main(), after writing CSS_PATH:
fs.mkdirSync(path.dirname(PRIV_CSS_PATH), { recursive: true });
fs.writeFileSync(PRIV_CSS_PATH, out, 'utf8');
process.stdout.write('priv/static/crosswake/tokens.css written\n');
```

**Why `{ recursive: true }`:** `priv/static/crosswake/` does not yet exist. `mkdirSync` without `recursive` would throw `ENOENT` if intermediate directories are missing. [VERIFIED: live code — `ls priv/` shows only `priv/templates/`; `priv/static/` does not exist]

### Pattern 3: get_template_path resolution for the packaged CSS

**What:** The exact same resolution pattern used for `.eex` templates in `gen.offline_ui.ex` applies to the CSS file.

```elixir
# Source: lib/mix/tasks/crosswake.gen.offline_ui.ex lines 101-108 [VERIFIED: live code]
defp get_tokens_css_path do
  path = Application.app_dir(:crosswake, "priv/static/crosswake/tokens.css")
  if File.exists?(path) do
    path
  else
    Path.join(File.cwd!(), "priv/static/crosswake/tokens.css")
  end
end
```

**Why both branches matter:** In production (installed Hex package), `Application.app_dir` resolves inside the unpacked package's OTP application directory. In dev (path dep `{:crosswake, path: "../.."}`) the `File.cwd!()` fallback resolves against the crosswake repo root. [VERIFIED: live code — same dual-resolution pattern used for all 4 existing templates]

### Pattern 4: ensure_file for the tokens.css copy

**What:** Reuse the existing `ensure_file/2` function to copy the packaged tokens.css into the host's static dir, using the no-clobber semantics already established.

```elixir
# Source: lib/mix/tasks/crosswake.gen.offline_ui.ex lines 117-133 [VERIFIED: live code]

tokens_css_src  = get_tokens_css_path()
tokens_css_dest = Path.join([dir, "priv", "static", "assets", "tokens.css"])

ensure_file(tokens_css_dest, File.read!(tokens_css_src))
```

**Destination path note:** The generator targets standard Phoenix app layout (`priv/static/assets/`). The example host is non-standard (`priv/static/css/`) and is vendored manually (or by running the task in the example host dir). See "Example Host" section for the exact target path. [VERIFIED: live code — example host has `priv/static/css/app.css`, DeckLive links `/css/app.css`]

### Pattern 5: tokens.css link in offline_root template

**What:** Add a `<link>` for `tokens.css` before the existing `app.css` link in `offline_root.html.heex.eex`. Token custom properties must be defined before rules that consume them.

```html
<!-- Source: priv/templates/crosswake/offline_ui/offline_root.html.heex.eex [VERIFIED: live code] -->
<!-- ADD THIS BEFORE the existing app.css link: -->
<link phx-track-static rel="stylesheet" href={~p"/assets/tokens.css"} />
<!-- EXISTING (keep): -->
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
```

**Phase 107 scope:** This phase adds the link to the template. Phase 108 will use those token properties in the template body — the body class `bg-cw-foam-50 text-cw-current-950` is unchanged by this phase.

### Anti-Patterns to Avoid

- **Reusing `props()` for fontFamily tokens:** `props(flat, paths, dark, isPrim)` calls `resolveAlias(t.$value)` which returns the raw Array object for fontFamily tokens, producing `--cw-font-display: Space Grotesk,ui-sans-serif,...` (unquoted, broken). Always route fontFamily through the new serializer.
- **Emitting font/dim tokens in dark-mode blocks:** The JSON has zero `$dark` fields on non-color tokens (verified by enumeration). Adding them to `@media (prefers-color-scheme: dark)` or `[data-theme="dark"]` blocks would emit incorrect duplicate declarations with no dark values.
- **Using `File.cp!/2` instead of `ensure_file/2`:** `File.cp!` overwrites existing files. If a host has customized its `tokens.css`, running the generator again must not silently overwrite it — `ensure_file` preserves it with `reused` message.
- **Placing the doc in `brandbook/`:** `brandbook/` is excluded from the Hex package. A guide in `guides/tokens.md` ships in the package and appears in ExDoc.
- **Omitting `{ recursive: true }` from mkdirSync:** `priv/static/` and `priv/static/crosswake/` both need to be created. Without the flag, the call throws `ENOENT`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| No-clobber file copy to host | Custom file-exists check + write | `ensure_file/2` (already in `gen.offline_ui.ex`) | Already handles `{:ok, _existing}`, `{:error, :enoent}`, and `{:error, reason}` cases with correct Mix shell output |
| Resolve packaged CSS path | Hardcode path or env var | `get_template_path` pattern: `Application.app_dir` + `File.cwd!` fallback | Handles both Hex-installed and `path:` dep scenarios — tested by existing generator integration |
| Directory creation in Node.js | Manual existence check before `mkdirSync` | `fs.mkdirSync(dir, { recursive: true })` | Idempotent; handles intermediate dirs; Node 10.12+ |
| CSS `@import` or JS injection | Building a bundler step into distribution | Static `<link>` before `app.css` | Keeps zero-toolchain constraint; works in any Phoenix host without esbuild config |

**Key insight:** Every primitive needed for this phase already exists in the codebase. The work is connecting them, not building new infrastructure.

---

## Common Pitfalls

### Pitfall 1: props() called with fontFamily tokens produces broken CSS

**What goes wrong:** `props(flat, paths, false, false)` calls `resolveAlias(t.$value)`. For `font.display`, `t.$value` is `["Space Grotesk", "ui-sans-serif", ...]` (an Array). `resolveAlias` checks `typeof value === 'string'` — fails — and returns the raw Array. Node.js Array-to-string coercion in template literals produces `Space Grotesk,ui-sans-serif,...` (comma-joined without quotes). CSS font-family with unquoted multi-word names ("Space Grotesk", "Liberation Mono", etc.) is invalid.
**Why it happens:** The existing `props()` was written only for color tokens, all of which have string `$value` (either a hex literal or a `{...}` alias).
**How to avoid:** Implement a separate `serializeNonColor()` helper that branches on `$type`. For `fontFamily`, map each family name: if it contains a space, wrap in double quotes; join with `', '`.
**Warning signs:** Generated `tokens.css` contains `--cw-font-display: Space Grotesk,...` (no quotes around multi-word names), or `[object Array]`.

### Pitfall 2: priv/static/crosswake/ not created → writeFileSync throws ENOENT

**What goes wrong:** `fs.writeFileSync('priv/static/crosswake/tokens.css', out)` throws `Error: ENOENT: no such file or directory` if the `crosswake/` subdirectory (and `static/`) don't exist.
**Why it happens:** `priv/static/` does not exist in the repo yet. `writeFileSync` does not create intermediate directories.
**How to avoid:** Call `fs.mkdirSync(path.dirname(PRIV_CSS_PATH), { recursive: true })` before the `writeFileSync`. This is idempotent.
**Warning signs:** `node brandbook/tools/compile-tokens.js` exits with ENOENT pointing at the priv path.

### Pitfall 3: PRIV_CSS_PATH uses relative path instead of ROOT-anchored path

**What goes wrong:** The existing `CSS_PATH = path.join(ROOT, 'brandbook/tokens/tokens.css')` correctly anchors to the repo root via `ROOT = path.resolve(__dirname, '../..')`. If `PRIV_CSS_PATH` is declared as a relative path (`'priv/static/crosswake/tokens.css'`), the file lands relative to the process's cwd (which may be `brandbook/tools/` or the repo root depending on how Node is invoked).
**How to avoid:** Always use `path.join(ROOT, 'priv/static/crosswake/tokens.css')`. [VERIFIED: live code — ROOT already defined at line 5]

### Pitfall 4: Stone-600 naming collision concern (false alarm)

**What goes wrong:** Concern that `--cw-text-muted` and `--cw-primitive-stone-600` plus `--cw-stone-600` alias might collide. **This is not a collision** — the existing emit convention does not produce a flat `--cw-stone-600`; primitives are emitted as `--cw-primitive-stone-600`. The non-color groups (`font`, `text-scale`, etc.) have entirely different prefixes. [VERIFIED: CSS name collision check across all 70 tokens found zero duplicates]

### Pitfall 5: Example host destination for tokens.css — /css/, not /assets/

**What goes wrong:** The generator template uses `~p"/assets/tokens.css"` (standard Phoenix convention). The in-repo example host serves static from `/css/` (`priv/static/css/app.css` → `/css/app.css`), not `/assets/`. Copying to `priv/static/assets/tokens.css` would produce a 404 in the example host.
**Why it happens:** The example host predates standard Phoenix asset pipeline conventions and uses `priv/static/css/` as its static dir.
**How to avoid:** For the example host specifically, vendor to `examples/phoenix_host/priv/static/css/tokens.css` and link as `/css/tokens.css`. The generator template (`~p"/assets/tokens.css"`) is correct for new Phoenix apps adopting the generator — the example host is an in-repo special case, vendored manually.

### Pitfall 6: Semantic test asserts "no hex in semantic tier" — must extend to font/dim tier

**What goes wrong:** `compile-tokens.test.mjs` line 129-141 checks that lines with `--cw-[non-primitive]-` properties contain no `#RRGGBB` hex. After adding `--cw-font-display`, `--cw-text-scale-md`, etc., those lines also match the `--cw-(?!primitive-)` regex. Since font/dim values are raw strings (no hex), the existing test continues to pass correctly. But new tests for the font/dim tier should positively assert the expected property names, not rely on the hex-absence check as the only verification.
**Warning signs:** All new tests are absent; only the existing tests run; the regression to old behavior would be undetected.

---

## Code Examples

### Complete output shape for the new `:root` block

The third `:root` block that `compile-tokens.js` should emit (verified by enumeration of `crosswake.tokens.json`):

```css
/* Source: crosswake.tokens.json enumeration [VERIFIED: live code + Node.js simulation] */

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

**Notes on font serialization:**
- `"Space Grotesk"` — quoted (contains space) [VERIFIED]
- `ui-sans-serif`, `system-ui`, `-apple-system` — unquoted (no space) [VERIFIED]
- `BlinkMacSystemFont` — unquoted (no space) [VERIFIED]
- `"Segoe UI"` — quoted (contains space) [VERIFIED]
- `"JetBrains Mono"` — quoted (contains space) [VERIFIED]
- `SFMono-Regular` — unquoted (no space, hyphen only) [VERIFIED]
- `"Liberation Mono"` — quoted (contains space) [VERIFIED]
- `"Atkinson Hyperlegible Next"` — quoted (multiple words with spaces) [VERIFIED]

This matches the existing hand-maintained values in `examples/phoenix_host/assets/css/app.css` exactly, confirming the serialization is correct. [VERIFIED: live code]

### Sort order

`compile-tokens.js` sorts all paths with `all.sort()` before filtering. The non-color filter produces the same sorted order. The output above is already sorted correctly (alphabetical within each group after dot-to-dash mapping). The `sort()` call ensures byte-identical output on repeated runs. [VERIFIED: live code line 42]

---

## Detailed Code Investigation Findings

### 1. compile-tokens.js structure (lines 1-74)

[VERIFIED: live code]

| Lines | Element | Role |
|-------|---------|------|
| 5 | `ROOT` | `path.resolve(__dirname, '../..')` — resolves to repo root |
| 6 | `JSON_PATH` | `ROOT + '/brandbook/tokens/crosswake.tokens.json'` |
| 7 | `CSS_PATH` | `ROOT + '/brandbook/tokens/tokens.css'` (first output) |
| 10-19 | `flattenTokens(obj, prefix, acc)` | Recursively flattens DTCG tree; skips `$`-prefixed keys; produces `{dot.path: tokenObj}` map |
| 22-25 | `resolveAlias(value)` | Converts `{primitive.foam.50}` → `var(--cw-primitive-foam-50)`; passes non-aliases through |
| 28-34 | `props(flat, paths, dark, isPrim)` | Generates CSS declarations; **CANNOT handle fontFamily arrays** (see Pitfall 1) |
| 36-71 | `main()` | Reads JSON, calls `flattenTokens`, filters into `prim` and `sem`, assembles `out`, calls `writeFileSync` once |
| 44 | `groups` allow-list | `['surface', 'text', 'action', 'border', 'status', 'runtime']` — **this is the filter that silently drops font/dim tokens** |
| 69 | `fs.writeFileSync(CSS_PATH, out, 'utf8')` | Single write; second write for priv mirror does not exist yet |
| 74 | `module.exports` | Exports `{ flattenTokens, resolveAlias }` for test consumption |

**Insertion point for Phase 107 changes in `main()`:**

After line 45 (`const sem = ...`), add:
```javascript
const NON_COLOR_GROUPS = ['font', 'text-scale', 'display-scale', 'line-height',
                           'spacing', 'radius', 'focus', 'tracking'];
const nonColor = all.filter(p => NON_COLOR_GROUPS.some(g => p.startsWith(g + '.')));
```

After line 67 (`].join('\n');`), before line 69 (`fs.writeFileSync`), extend the `out` array to append the new `:root` block. Then after line 69, add the second `writeFileSync`.

### 2. crosswake.tokens.json — complete non-color token inventory

[VERIFIED: live code — full enumeration via Node.js]

**`font` group** (`$type: "fontFamily"`, `$value: Array`):

| Token path | CSS property | Value (serialized) |
|------------|-------------|-------------------|
| `font.display` | `--cw-font-display` | `"Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.body` | `--cw-font-body` | `"Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.mono` | `--cw-font-mono` | `"JetBrains Mono", SFMono-Regular, Consolas, "Liberation Mono", monospace` |

**`text-scale` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `text-scale.xs` | `--cw-text-scale-xs` | `12px` |
| `text-scale.sm` | `--cw-text-scale-sm` | `14px` |
| `text-scale.md` | `--cw-text-scale-md` | `16px` |
| `text-scale.lg` | `--cw-text-scale-lg` | `18px` |
| `text-scale.xl` | `--cw-text-scale-xl` | `20px` |

**`display-scale` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `display-scale.sm` | `--cw-display-scale-sm` | `28px` |
| `display-scale.md` | `--cw-display-scale-md` | `40px` |
| `display-scale.lg` | `--cw-display-scale-lg` | `56px` |

**`line-height` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `line-height.xs` | `--cw-line-height-xs` | `16px` |
| `line-height.sm` | `--cw-line-height-sm` | `20px` |
| `line-height.md` | `--cw-line-height-md` | `24px` |
| `line-height.lg` | `--cw-line-height-lg` | `28px` |
| `line-height.xl` | `--cw-line-height-xl` | `30px` |
| `line-height.display-sm` | `--cw-line-height-display-sm` | `36px` |
| `line-height.display-md` | `--cw-line-height-display-md` | `48px` |
| `line-height.display-lg` | `--cw-line-height-display-lg` | `64px` |

**`spacing` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `spacing.base` | `--cw-spacing-base` | `4px` |

**`radius` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `radius.sm` | `--cw-radius-sm` | `6px` |
| `radius.md` | `--cw-radius-md` | `10px` |
| `radius.lg` | `--cw-radius-lg` | `14px` |
| `radius.xl` | `--cw-radius-xl` | `20px` |

**`focus` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `focus.ring-width` | `--cw-focus-ring-width` | `2px` |

**`tracking` group** (`$type: "dimension"`, `$value: String`):

| Token path | CSS property | Value |
|------------|-------------|-------|
| `tracking.tight` | `--cw-tracking-tight` | `-0.02em` |

**Total new properties:** 3 fontFamily + 24 dimension = 27 new CSS custom properties.

**Dark variants:** Zero. All `$dark` fields are absent from all non-color tokens. [VERIFIED: enumeration confirmed `hasDark: []`]

### 3. CSS naming — no collisions

[VERIFIED: live code — collision check found zero duplicates across all 70 flattened tokens]

All color tokens use group-prefixed paths (`primitive.foam.50`, `surface.default`, `action.bg`, etc.) and all non-color tokens use their own group prefixes (`font.display`, `text-scale.md`, etc.). The dot-to-dash substitution produces disjoint CSS property name namespaces. The complete list of non-color CSS property names is enumerated in the table above.

The success criteria names check out verbatim:
- `--cw-font-display` ← `font.display` [CONFIRMED]
- `--cw-font-body` ← `font.body` [CONFIRMED]
- `--cw-font-mono` ← `font.mono` [CONFIRMED]
- `--cw-text-scale-*` ← `text-scale.*` [CONFIRMED]
- `--cw-display-scale-*` ← `display-scale.*` [CONFIRMED]
- `--cw-radius-*` ← `radius.*` [CONFIRMED]

### 4. mix.exs package constraint

[VERIFIED: live code — `mix.exs` lines 78-79]

```elixir
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides),
exclude_patterns: ["brandbook"]
```

`priv` is in the `files:` whitelist. `priv/static/crosswake/tokens.css` (once created) will be included in the Hex tarball. `brandbook/` is excluded. This is exactly the constraint that makes D-06 necessary. `script/verify_hex_tarball.sh` expects `priv` in the tarball and would fail if it were absent.

**`priv/static/` does not yet exist** in the crosswake package. The compile script must create it with `fs.mkdirSync(dir, { recursive: true })`. The directory will then be tracked by git (with the `tokens.css` file inside it).

### 5. Distribution mechanism — gen.offline_ui.ex

[VERIFIED: live code — `lib/mix/tasks/crosswake.gen.offline_ui.ex` lines 101-133]

**`get_template_path/1`** (lines 101-108): resolves `Application.app_dir(:crosswake, "priv/templates/crosswake/offline_ui/#{filename}")` with a `File.cwd!()` fallback for path deps. The identical pattern works for `priv/static/crosswake/tokens.css`.

**`ensure_file/2`** (lines 117-133): reads existing file; if `{:ok, _existing}` → logs "reused", returns `:reused` (no overwrite); if `{:error, :enoent}` → `File.write!` + logs "created"; if `{:error, reason}` → `Mix.raise`. This is the correct no-clobber semantics for D-07.

**Current generator output** (5 calls, each templated file): `controller`, `root_layout`, `page`, `js`. Phase 107 adds a 6th: `tokens.css` copy to host static.

**offline_root.html.heex.eex** (line 10, [VERIFIED: live code]):
```html
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
```
Phase 107 adds a line immediately before this:
```html
<link phx-track-static rel="stylesheet" href={~p"/assets/tokens.css"} />
```
The `phx-track-static` attribute is correct here — Phoenix uses it for cache-busting.

### 6. Example host — static serving layout

[VERIFIED: live code]

The example host (`examples/phoenix_host/`) has:
- No Phoenix.Endpoint defined in its `lib/` — it appears to be a headless test host that gains endpoint behavior from a Phoenix server started by `mix phx.server` via Playwright's `webServer` config.
- Static files served from `priv/static/` at the root path. `priv/static/css/app.css` is linked as `/css/app.css` (confirmed via `DeckLive.Index` and `DeckLive.Show` which both use `<link rel="stylesheet" href="/css/app.css" />`).
- `priv/static/offline_study.js` served at `/offline_study.js` (root-relative, confirmed by `index.html.heex`).

**Consequence for Phase 107:** The vendored `tokens.css` in the example host goes to `examples/phoenix_host/priv/static/css/tokens.css`, served as `/css/tokens.css`. The two LiveView layouts that link `app.css` need a corresponding `tokens.css` link.

**This is distinct from what the generator template emits** (`/assets/tokens.css` for standard Phoenix hosts). The example host is a special case that requires a manual vendor step, not a generator run.

### 7. Documentation placement

[VERIFIED: live code — `mix.exs` docs/extras + `guides/` directory listing]

`guides/` is in `files:` whitelist and in ExDoc `extras:`. New files under `guides/` are automatically included in ExDoc output under the "Guides" group (`groups_for_extras: [... Guides: ~r/guides\//]`). No existing guide covers token distribution. A new `guides/tokens.md` is the correct placement.

**The guide must be added to `mix.exs` `extras:` list** to appear in ExDoc (the `~r/guides\//` glob is for `groups_for_extras`, not `extras:` — the `extras:` list is explicit). Compare existing pattern (e.g., `"guides/offline.md"` is in `extras:` at line 106).

**Recommended content outline for `guides/tokens.md`:**
```
# Crosswake Token Distribution

## Source
crosswake.tokens.json (DTCG 2025.10, frozen v9.0 brand contract)

## Generate
node brandbook/tools/compile-tokens.js
(Outputs: brandbook/tokens/tokens.css + priv/static/crosswake/tokens.css)

## What ships in the package
priv/static/crosswake/tokens.css — the distributable copy

## How consumers receive it
### Generated offline UI
mix crosswake.gen.offline_ui copies tokens.css to host's priv/static/assets/tokens.css
(no-clobber: won't overwrite a host-customized copy)
The generated offline_root.html.heex links it before app.css.

### Example host / direct Phoenix host
Copy priv/static/crosswake/tokens.css to your priv/static/css/tokens.css (or /assets/).
Link before app.css: <link rel="stylesheet" href="/css/tokens.css" />

## Contract
- Never hand-edit tokens.css in any consumer — edit crosswake.tokens.json and regenerate.
- Both copies (brandbook/tokens/tokens.css and priv/static/crosswake/tokens.css) are
  byte-identical; diff them to verify parity.
- All --cw-* custom properties are defined before app.css so consuming rules can reference them.
```

### 8. Verifiability for Phase 109

[VERIFIED: live code + naming analysis]

Phase 107's path choices leave each consumer with a single, well-known file:
- `brandbook/tokens/tokens.css` — brand book copy (source of truth, byte 1)
- `priv/static/crosswake/tokens.css` — package distributable (byte 1 == byte 2 by construction)
- `examples/phoenix_host/priv/static/css/tokens.css` — example host vendored copy
- `host/priv/static/assets/tokens.css` — generator-installed copy

Each of these files contains only `--cw-` declarations. Phase 109's grep gate can:
1. Grep any of these files for `--cw-` and get the complete token list.
2. `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` produces zero output if parity holds.
3. The two generator-placed copies can be diffed against the package distributable at test time.

Nothing in Phase 107's choices makes future textual grep gates impossible. The `--cw-` prefix is globally unique within the codebase. [VERIFIED: live code — no other `--cw-` declarations exist outside the token source and its copies/consumers]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact on Phase 107 |
|--------------|------------------|--------------|---------------------|
| `compile-tokens.js` emits only color tokens (primitive + semantic + dark) | After Phase 107: emits colors + fonts + dimensions | Phase 107 | New `:root` block appended; existing blocks unchanged |
| `priv/static/` does not exist | After Phase 107: `priv/static/crosswake/tokens.css` created | Phase 107 | Directory creation step required |
| `gen.offline_ui` generates 4 files | After Phase 107: generates 5 files + copies tokens.css | Phase 107 | New `ensure_file` call; new template `<link>` |
| Font stacks hand-declared in `app.css` | After Phase 108: consumed from `tokens.css` | Phase 108 (not 107) | Phase 107 does NOT remove hand declarations — that is downstream |

**Deprecated/outdated (to confirm before planning, not to change in 107):**
- The `mix crosswake.gen.offline_ui` instructions output at line 66-98 tells hosts to add Tailwind config (`cw-wake`, `cw-brass`) and run esbuild. These are stale instructions that Phase 108 (NORM-02) removes. Phase 107 does NOT touch this output.
- The existing `compile-tokens.test.mjs` test at line 122 (`>= 20 var(--cw-primitive-)` references) continues to pass after Phase 107 because the semantic tier is unchanged.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The example host's static serving mounts `priv/static/` at the root path (so `/css/app.css` maps to `priv/static/css/app.css`) | Architecture Patterns §6 | If a different path prefix is used, the destination for `tokens.css` would differ. Medium risk — confirmed by DeckLive link patterns, no endpoint.ex found. |

**All other claims in this research were verified or cited from live code.**

---

## Open Questions

1. **Should `guides/tokens.md` be named differently?**
   - What we know: No existing token guide; `guides/` uses capability-oriented names (offline.md, commerce.md, capabilities.md)
   - What's unclear: Whether "tokens" or "brand-tokens" or "token-distribution" is the right name
   - Recommendation: `guides/tokens.md` — short, matches the file being documented, consistent with `offline.md` style

2. **Should compile-tokens.js emit font/dim tokens in sorted order across all NON_COLOR_GROUPS combined, or group-by-group?**
   - What we know: Current color emit is globally sorted within each tier. The simulation above sorted all non-color tokens together alphabetically, which interleaves groups (`display-scale.*`, then `focus.*`, then `font.*`, then `line-height.*`, etc.)
   - What's unclear: Whether developers prefer group-by-group emit (all `font.*` together, then all `text-scale.*`, etc.) for readability
   - Recommendation: Global alpha-sort (consistent with how `prim` and `sem` are sorted). The tier comment at the top identifies the block. A planner could choose either approach; the test just checks for presence, not order.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `compile-tokens.js` | Yes | v22.14.0 | — |
| `node:test` (Node stdlib) | `compile-tokens.test.mjs` | Yes | Node 22 | — |
| `node:fs`, `node:path` | `compile-tokens.js` | Yes | Node 22 | — |
| Elixir `File`, `Application` | `gen.offline_ui.ex` | Yes | Elixir 1.19 | — |
| `mix hex.build` | Tarball verification | Yes (dev) | Hex CLI | Skip verification in CI if not configured |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

---

## Validation Architecture

Nyquist validation is **enabled** (`workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js `node:test` + ExUnit |
| Config file | none (Node: run directly; Elixir: `mix test`) |
| Quick run command | `node --test brandbook/tools/compile-tokens.test.mjs` |
| Full suite command | `node --test brandbook/tools/compile-tokens.test.mjs && mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOKN-04 | `tokens.css` contains `--cw-font-display`, `--cw-font-body`, `--cw-font-mono` | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| TOKN-04 | Font values are quoted-name font stacks (not arrays/garbage) | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| TOKN-05 | `tokens.css` contains `--cw-text-scale-md`, `--cw-display-scale-sm`, `--cw-radius-lg`, etc. | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| TOKN-05 | Dimension values are raw strings (e.g., `16px`, `-0.02em`), not aliases | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| TOKN-04/05 | `priv/static/crosswake/tokens.css` exists after script execution | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| TOKN-04/05 | Both output files are byte-identical | unit | `node --test brandbook/tools/compile-tokens.test.mjs` | Wave 0: new tests needed |
| NORM-03 | `gen.offline_ui` copies `tokens.css` to host static dir | integration | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ exists — needs new assertions |
| NORM-03 | Generated `offline_root.html.heex` contains `tokens.css` link before `app.css` | integration | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ exists — needs new assertions |
| NORM-03 | `guides/tokens.md` exists and contains distribution mechanism text | smoke | `test -f guides/tokens.md` | Wave 0: file to be created |

### Sampling Rate

- **Per task commit:** `node --test brandbook/tools/compile-tokens.test.mjs`
- **Per wave merge:** `node --test brandbook/tools/compile-tokens.test.mjs && mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs`
- **Phase gate:** Full suite green (both commands above) before `/gsd:verify-work`

### Wave 0 Gaps

New tests to add to `brandbook/tools/compile-tokens.test.mjs`:
- [ ] `tokens.css contains --cw-font-display with quoted font stack`
- [ ] `tokens.css contains --cw-font-body with quoted font stack`
- [ ] `tokens.css contains --cw-font-mono with quoted font stack`
- [ ] `tokens.css contains --cw-text-scale-md: 16px`
- [ ] `tokens.css contains --cw-radius-lg: 14px`
- [ ] `tokens.css contains --cw-display-scale-sm: 28px`
- [ ] `priv/static/crosswake/tokens.css exists after script execution`
- [ ] `priv/static/crosswake/tokens.css is byte-identical to brandbook/tokens/tokens.css`

New assertions to add to `test/mix/tasks/crosswake.gen.offline_ui_test.exs`:
- [ ] Generated root layout contains `tokens.css` in a `<link>` tag
- [ ] `tokens.css` is copied to host static dir during `run/1`

---

## Security Domain

This phase involves no authentication, session management, access control, cryptography, or external input processing. CSS custom property files and static asset copying carry no ASVS-relevant attack surface.

The only security-adjacent concern is **supply chain integrity** of the generated CSS: the `/* GENERATED from crosswake.tokens.json — do not edit */` header must appear on both output files so reviewers know not to edit them. This is already enforced by the existing test at line 116-120 of `compile-tokens.test.mjs`.

---

## Sources

### Primary (HIGH confidence — verified against live code)

- `brandbook/tools/compile-tokens.js` — read in full; all function signatures, line numbers, and allow-list confirmed
- `brandbook/tokens/crosswake.tokens.json` — read in full; all 27 non-color tokens enumerated with `$type` and `$value` via Node.js execution
- `brandbook/tools/compile-tokens.test.mjs` — read in full; 17 existing tests, all passing
- `mix.exs` lines 78-79 — `files:` whitelist and `exclude_patterns` confirmed
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — read in full; `ensure_file/2`, `get_template_path/1`, and full run flow confirmed
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — read in full; existing `<link>` placement confirmed
- `examples/phoenix_host/priv/static/` — enumerated; `priv/static/css/app.css` confirmed; `priv/static/` is the static root
- `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex` — `/css/app.css` link confirmed
- `.github/workflows/brandbook-verify.yml` — `brand-structural` vs `brand-visual` split confirmed
- `script/verify_hex_tarball.sh` — `EXPECTED_PATHS` includes `priv`, confirmed tarball contains `priv/`
- Node.js simulation of CSS name collision check — zero collisions confirmed

### Secondary (MEDIUM confidence — read from repo but not executed)

- `examples/phoenix_host/assets/css/app.css` — hand-declared font values confirmed match JSON; confirms serialization is correct
- `guides/` directory listing — no existing token guide confirmed
- `mix.exs` `docs/extras` list — `guides/tokens.md` would need to be added

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all tools verified in live code
- Architecture: HIGH — all integration points confirmed by reading actual source files
- Pitfalls: HIGH — discovered from live code inspection (fontFamily array, missing priv/static/, example host path)
- Non-color token inventory: HIGH — verified by Node.js enumeration of actual JSON
- CSS name collisions: HIGH — verified by programmatic collision check across all 70 tokens

**Research date:** 2026-06-13
**Valid until:** Stable (the JSON source and compile-tokens.js structure are frozen brand contract; valid until Phase 107 lands)
