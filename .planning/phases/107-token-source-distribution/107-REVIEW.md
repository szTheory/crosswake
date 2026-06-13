---
phase: 107-token-source-distribution
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - brandbook/tools/compile-tokens.js
  - brandbook/tools/compile-tokens.test.mjs
  - examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex
  - examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/show.ex
  - guides/tokens.md
  - lib/mix/tasks/crosswake.gen.offline_ui.ex
  - mix.exs
  - priv/templates/crosswake/offline_ui/offline_root.html.heex.eex
  - test/mix/tasks/crosswake.gen.offline_ui_test.exs
  - brandbook/tokens/tokens.css
  - priv/static/crosswake/tokens.css
  - examples/phoenix_host/priv/static/css/tokens.css
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 107: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Reviewed the full token-distribution pipeline: the Node generator (`compile-tokens.js`),
its test suite, the `crosswake.gen.offline_ui` Mix task, the generated template
(`offline_root.html.heex.eex`), the offline page template, the Elixir task test, and
all three `tokens.css` files. The three CSS artifacts are byte-identical and correctly
structured. The generator logic is sound; `flattenTokens` and `resolveAlias` operate
correctly for all current call paths. The core distribution contract holds.

One critical defect was found: the Tailwind configuration advice emitted by the Mix task
in its `Mix.shell().info` output contains hex values from a completely different color
palette — not the Crosswake brand — and omits two of the four color palettes (`cw-current`
and `cw-foam`) that the generated templates actually use. Any developer who follows those
instructions verbatim will produce visually broken output.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Mix task Tailwind config advice contains wrong hex values and omits required palettes

**File:** `lib/mix/tasks/crosswake.gen.offline_ui.ex:65-96`

**Issue:** The `Mix.shell().info` block printed after generation includes a sample
`tailwind.config.js` snippet telling developers how to wire up Crosswake brand colors.
The hex values for every shade of `cw-wake` and `cw-brass` are incorrect — they describe
a blue palette unrelated to the Crosswake brand. Comparison:

| Token            | Actual (tokens.css)       | Suggested (mix task) |
|------------------|---------------------------|----------------------|
| `cw-wake-500`    | `#4E9A8E` (teal)          | `#699cc9` (blue)     |
| `cw-wake-700`    | `#2B756A` (dark teal)     | `#3c6d99` (blue)     |
| `cw-brass-500`   | `#C98A2E` (amber)         | `#e1b982` (pale gold)|
| `cw-brass-700`   | `#946017` (dark amber)    | `#c59a5e` (tan)      |

Additionally, the two palettes actually consumed by the generated templates are entirely
absent from the snippet:

- `cw-current` — used in `offline_root.html.heex.eex:14` (`text-cw-current-950`) and
  `offline_page.html.heex.eex:3,12,17` (`text-cw-current-950`)
- `cw-foam` — used in `offline_root.html.heex.eex:14` (`bg-cw-foam-50`) and
  `offline_page.html.heex.eex:5` (`bg-cw-foam-50`)

The result is that following the printed instructions produces Tailwind classes with wrong
colors for `cw-wake` and `cw-brass`, and missing classes for `cw-current` and `cw-foam`,
causing the generated offline page and root layout to render with wrong or absent colors.
The test for this output (`crosswake.gen.offline_ui_test.exs:104-105`) only asserts that
the strings `"cw-wake-700"` and `"cw-brass-500"` appear somewhere in the output; it does
not validate hex values or completeness, so the defect passes all tests.

**Fix:** Replace the hardcoded Tailwind snippet with values derived from the actual brand
tokens, and add the missing palettes. Correct values (sourced from `tokens.css`):

```js
colors: {
  'cw-wake': {
    500: '#4E9A8E',
    700: '#2B756A',
  },
  'cw-brass': {
    500: '#C98A2E',
    700: '#946017',
  },
  'cw-current': {
    800: '#162B35',
    900: '#0F1E26',
    950: '#09141A',
  },
  'cw-foam': {
    50:  '#F7F1E6',
    100: '#EFE6D6',
  },
  'cw-mist': {
    200: '#C9D4CF',
  },
}
```

Include all primitive color values actually referenced by the generated templates. Extend
the test to assert that at least one correct hex value is present (e.g.,
`assert output =~ "#4E9A8E"` or `assert output =~ "#2B756A"`).

## Warnings

### WR-01: `flattenTokens` silently resets `prefix` when called with two arguments

**File:** `brandbook/tools/compile-tokens.js:11-12`

**Issue:** The default-parameter guard uses `acc === undefined` as the trigger to
initialize both `prefix` and `acc`:

```js
function flattenTokens(obj, prefix, acc) {
  if (acc === undefined) { prefix = ''; acc = {}; }
```

If a caller passes exactly two arguments — `flattenTokens(obj, 'somePrefix')` — the
check fires because `acc` is `undefined`, and the explicitly-passed `prefix` is silently
discarded (reset to `''`). Internal recursive calls always pass all three arguments so
the current codebase is unaffected. However, the function is exported for external
consumers and tested directly; a caller following the signature `(obj, prefix, acc)` will
get a wrong result with no warning.

**Fix:** Use proper default parameter syntax:

```js
function flattenTokens(obj, prefix = '', acc = {}) {
  for (const [k, v] of Object.entries(obj)) {
```

Drop the guard block entirely. This is valid CJS and is unambiguous about semantics.

### WR-02: Example LiveView components inject `<link>` inside `render()`, placing stylesheet tags in `<body>`

**File:** `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex:15-16`
**File:** `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/show.ex:15-16`

**Issue:** Both `DeckLive.Index` and `DeckLive.Show` inject stylesheet link tags at the
top of their `render/1` function:

```elixir
<link rel="stylesheet" href="/css/tokens.css" />
<link rel="stylesheet" href="/css/app.css" />
```

Because these LiveViews have no root layout, the Phoenix renders this output as the full
page body — meaning the `<link>` elements land inside `<body>`, not `<head>`. This is
invalid HTML5 (the `link` element is metadata content and must appear in `<head>`) and
causes a flash of unstyled content (FOUC): the browser encounters the content nodes
before the stylesheet is requested.

As example code, it directly teaches the wrong pattern to adopters who will read these
files to understand how to integrate tokens into their own LiveViews.

**Fix:** Add a root layout for the `"/decks"` scope (consistent with how the offline
controller sets its layout), or demonstrate the correct approach of putting `<link>` tags
in a shared layout's `<head>`. At minimum, add a comment noting this is a layout-bypass
shortcut for a standalone example and not the recommended production pattern.

### WR-03: `tokens.css exists` test is a precondition assertion, not a self-contained test

**File:** `brandbook/tools/compile-tokens.test.mjs:109-113`

**Issue:**

```js
test('tokens.css exists after script execution', () => {
  // Script must have been run before this test; we just check if it exists
  assert.ok(existsSync(TOKENS_CSS), 'brandbook/tokens/tokens.css must exist');
});
```

The test comment acknowledges it does not run the script. It passes on CI only because
`tokens.css` is committed to the repo. On a fresh clone where the script has not been
run, the assertion would fail. The test title says "after script execution" but execution
is not performed.

The companion test at line 155 (`priv/static/crosswake/tokens.css is byte-identical`)
correctly calls `execSync` before reading. The existence test should follow the same
pattern for consistency and correctness on clean environments.

**Fix:**

```js
test('tokens.css exists after script execution', () => {
  execSync(`node ${COMPILE_SCRIPT}`, { cwd: ROOT });
  assert.ok(existsSync(TOKENS_CSS), 'brandbook/tokens/tokens.css must exist');
});
```

## Info

### IN-01: `offline_root.html.heex.eex` receives `web_module` binding but never uses it

**File:** `lib/mix/tasks/crosswake.gen.offline_ui.ex:46`
**File:** `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex`

**Issue:** The Mix task passes `web_module: web_module` to `EEx.eval_file` for the root
layout template, but the template contains no EEx expression tags — it is a static HEEx
file with no interpolation. The binding is dead.

**Fix:** Remove the `, web_module: web_module` keyword from the `EEx.eval_file` call for
this specific template, or add a comment in the template noting the binding is reserved
for future use (e.g., a `use AppWeb, :html` injection).

### IN-02: Offline page template mixes token classes with raw Tailwind utilities

**File:** `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex:2,11,16`

**Issue:** The generated offline page template uses `cw-*` Tailwind classes from the
brand system alongside unbranded Tailwind utilities (`bg-white`, `border-gray-200`,
`text-gray-500`) that reference Tailwind's default palette rather than `--cw-*` custom
properties. As generated example code, this inconsistency signals to adopters that it is
acceptable to mix the two systems.

**Fix:** Replace the three unbranded utility classes with equivalent `--cw-*` token
expressions. For example: `bg-white` -> `bg-cw-surface-inset`
(`--cw-surface-inset` = `#FFFFFF` in light mode), `border-gray-200` ->
`border-cw-border-subtle`, `text-gray-500` -> `text-cw-text-muted`.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
