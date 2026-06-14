---
phase: 108-consumer-normalization
reviewed: 2026-06-14T04:26:36Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  - examples/phoenix_host/priv/static/css/app.css
  - lib/mix/tasks/crosswake.gen.offline_ui.ex
  - priv/static/crosswake/offline.css
  - priv/templates/crosswake/offline_ui/offline_page.html.heex.eex
  - priv/templates/crosswake/offline_ui/offline_root.html.heex.eex
  - test/mix/tasks/crosswake.gen.offline_ui_test.exs
findings:
  critical: 2
  warning: 4
  info: 1
  total: 7
status: resolved
resolved: 2026-06-14
---

# Phase 108: Code Review Report

## Remediation (orchestrator, 2026-06-14)

Both criticals and the two highest-value warnings were fixed during the phase code-review gate; the rest were assessed and accepted/deferred with rationale.

| ID | Disposition | Action |
|----|-------------|--------|
| **CR-01** | **Fixed** | `app.css` card `box-shadow` rgba → `color-mix(in srgb, var(--cw-text-default) 6%, transparent)` — theme-adaptive (lightens on dark surfaces). Render-verified in `deck-dark`. |
| **CR-02** | **Fixed** | `index.html.heex` flashcard `box-shadow` rgba(0,0,0) → `color-mix(... var(--cw-text-default) 10% ...)`. No longer an invisible black void on the dark surface. |
| **WR-01** | **Fixed** | Generator link-order test now asserts each stylesheet is present before `:binary.match` destructuring — a missing link fails as a clear assertion, not a `MatchError`. |
| **WR-02** | **Fixed** | `app.css` hard-coded sizes/spacing tokenized: `font-size: 28px` → `var(--cw-display-scale-sm)`; all `24/16/8/4px` → `calc(var(--cw-spacing-base) * N)` (values identical → no visual change). Satisfies 108-01 truth #3. `max-width: 860px` left as a structural content-column width (no brand-scale token exists; commented). |
| WR-03 | Accepted | `index.html.heex` serves `/css/tokens.css` (the example host's own static path) while the generator vendors to `/assets/` (for generated hosts) — two distinct hosts with distinct static layouts, not a live bug. Hypothetical only if the example is moved onto the generated scaffold. |
| WR-04 | Accepted | `csrf-token` meta in `offline_root` is phx.gen boilerplate; the offline page has no forms, so no exploit. Left to match the generated-auth scaffold convention. |
| IN-01 | Deferred | Test `@tmp_dir` relative path works under `mix test` from project root (the standard invocation); cosmetic robustness only. |

Post-fix: generator suite 9/9 green; `app.css` and `index.html.heex` contain 0 `--cw-primitive-*`, 0 `var()` fallbacks, 0 hex/rgba colors; all six render states still AA-pass in both modes.

---



**Reviewed:** 2026-06-14T04:26:36Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 108 normalizes CSS/template consumers onto semantic design tokens (`--cw-*`) and vendors
`offline.css` via the generator's no-clobber copy mechanism. The semantic token discipline is
largely upheld — no `--cw-primitive-*` references, no `--cw-text-subtle` usage, no hand-declared
font stacks, and no `var()` fallbacks appear in any reviewed file. The generator's no-clobber
semantics and CSS link ordering are sound.

Two critical brand-contract violations remain: hard-coded `rgba()` color values in both
`app.css` and `index.html.heex` bypass the token system entirely. Four warnings cover a
crash-prone test assertion, hard-coded layout pixel values in `app.css`, a static asset path
mismatch in the example app, and a CSRF token in a service-worker-cached layout.

---

## Critical Issues

### CR-01: Hard-coded `rgba()` color in `app.css` box-shadow bypasses token system

**File:** `examples/phoenix_host/priv/static/css/app.css:34`

**Issue:** The `.card` rule uses `box-shadow: 0 1px 2px rgba(9, 20, 26, 0.06)`. The color
`rgba(9, 20, 26, ...)` is a hand-declared hex-equivalent that does not respond to the
`--cw-*` token tier, will not adapt to dark mode, and violates the phase-108 brand contract
("no hand-declared hex/font-stacks"). The raw RGB triple `9, 20, 26` is the primitive ink
color hard-coded outside the token cascade.

**Fix:** Replace with a shadow token (preferred) or an alpha-transparent semantic surface:
```css
/* Option A — if a shadow token exists */
box-shadow: var(--cw-shadow-sm);

/* Option B — provisional semantic-safe form until shadow token is minted */
box-shadow: 0 1px 2px color-mix(in srgb, var(--cw-text-default) 6%, transparent);
```

---

### CR-02: Hard-coded `rgba()` color in `index.html.heex` inline style bypasses token system

**File:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex:23`

**Issue:** The inline `<style>` block in the study island page uses
`box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1)`. Like CR-01, this is a hand-declared color
value that does not flow through the `--cw-*` semantic token tier. It will not adapt under
`prefers-color-scheme: dark` and breaks the brand contract for this phase. A pure-black
`rgba(0,0,0,…)` shadow on a dark near-black surface produces zero visual contrast.

**Fix:** Same approach as CR-01 — use a shadow token or a semantic alpha:
```css
/* In the inline <style> block, line 23 */
box-shadow: var(--cw-shadow-md);

/* Or provisional semantic form */
box-shadow: 0 4px 6px -1px color-mix(in srgb, var(--cw-text-default) 10%, transparent);
```

---

## Warnings

### WR-01: Test "offline_root links offline.css after tokens.css and app.css" crashes with `MatchError` on template structure change

**File:** `test/mix/tasks/crosswake.gen.offline_ui_test.exs:171-173`

**Issue:** Lines 171–173 use pattern-match destructuring on the raw return of `:binary.match/2`
without first checking for `:nomatch`:

```elixir
{tokens_pos, _} = :binary.match(content, "tokens.css")
{app_pos, _}    = :binary.match(content, "app.css")
{offline_pos, _} = :binary.match(content, "offline.css")
```

If any of the three strings is absent from the generated file, `:binary.match/2` returns the
atom `:nomatch`. Binding `:nomatch` against `{pos, _}` raises a `MatchError` with no context
about which string was missing — obscuring the actual regression. The earlier test at line 59
(same file) correctly checks `tokens_index != :nomatch` before destructuring; this test does not.

**Fix:**
```elixir
tokens_match = :binary.match(content, "tokens.css")
app_match    = :binary.match(content, "app.css")
offline_match = :binary.match(content, "offline.css")

assert tokens_match != :nomatch, "offline_root.html.heex must link tokens.css"
assert app_match    != :nomatch, "offline_root.html.heex must link app.css"
assert offline_match != :nomatch, "offline_root.html.heex must link offline.css"

{tokens_pos, _}  = tokens_match
{app_pos, _}     = app_match
{offline_pos, _} = offline_match

assert tokens_pos < app_pos,    "tokens.css must precede app.css"
assert app_pos    < offline_pos, "app.css must precede offline.css"
```

---

### WR-02: `app.css` uses hard-coded pixel values for structural layout — should use spacing tokens

**File:** `examples/phoenix_host/priv/static/css/app.css:17,19,23-24,33,35,49,58,74,80,82,99,105,106,121`

**Issue:** Structural layout values (`max-width: 860px`, `font-size: 28px`, `padding: 24px`,
`gap: 24px`, `margin-bottom: 24px`, `padding: 8px 16px`, etc.) are hard-coded pixel integers.
The phase contract requires no hand-declared values outside the token system. `offline.css`
uses `calc(var(--cw-spacing-base) * N)` and `var(--cw-text-scale-*)` throughout — `app.css`
is inconsistent with that discipline. The font-size `28px` on `.page-title` is particularly
exposed: it will not scale with the token system's type-scale cascade.

**Fix:** Migrate to token expressions matching the pattern established in `offline.css`:
```css
/* Before */
.page-container { max-width: 860px; padding: 24px; }
.page-title     { font-size: 28px; margin-bottom: 24px; }

/* After */
.page-container { max-width: 860px; padding: calc(var(--cw-spacing-base) * 6); }
.page-title     { font-size: var(--cw-text-scale-2xl); margin-bottom: calc(var(--cw-spacing-base) * 6); }
```

Note: `860px` for max-width is a layout breakpoint, which may be acceptable as a structural
constant if no layout-width token exists; the type and spacing values are the priority
corrections.

---

### WR-03: `index.html.heex` links `/css/tokens.css` but the generator writes tokens to `/assets/tokens.css`

**File:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex:7`

**Issue:** The study island page links tokens via:
```html
<link rel="stylesheet" href="/css/tokens.css" />
```
The generator (`crosswake.gen.offline_ui`) copies `tokens.css` to
`priv/static/assets/tokens.css`, served at `/assets/tokens.css`. The generated
`offline_root.html.heex.eex` template uses `~p"/assets/tokens.css"`. These are two different
static paths. If the example app is restructured to use the generator output, the study
island page would silently miss tokens and render with no design tokens applied — all
`var(--cw-*)` references would resolve to empty/inherited values.

This is the "served-vs-source app.css landmine" flagged in phase context: the example's
manually-crafted page lives in a different static path than the generated scaffold expects.
As-is, the example serves tokens from `/css/` while the generator targets `/assets/`.

**Fix:** Either align the example page to use `/assets/tokens.css` to match the generator
contract, or add a comment to the example page explicitly documenting that this controller
predates the generator and uses the older `/css/` static path:
```html
<!-- NOTE: This example predates the generator scaffold.
     The generator copies tokens.css to priv/static/assets/ (served at /assets/tokens.css).
     This page intentionally uses the older /css/ path for the example app's static layout. -->
<link rel="stylesheet" href="/css/tokens.css" />
```

---

### WR-04: `offline_root.html.heex.eex` includes CSRF token in a service-worker-cached layout

**File:** `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex:6`

**Issue:**
```html
<meta name="csrf-token" content={get_csrf_token()} />
```

The generated offline root layout is designed to be cached by the service worker and served
offline. CSRF tokens are session-scoped and rotate with each server-rendered request.
A cached offline page will carry a stale CSRF token. If any JavaScript in the offline
context reads `document.querySelector("meta[name='csrf-token']")` and uses it for a
request after reconnection (a common pattern in Phoenix LiveView), the token will be
rejected by the server (403 Invalid CSRF token).

The offline page as currently templated (`offline_page.html.heex.eex`) has no forms and
does not submit CSRF-protected requests, so this is latent rather than active. But the
CSRF meta tag signals to any JavaScript that the page supports CSRF-protected requests,
which is false for a cached offline document.

**Fix:** Remove the CSRF meta tag from the offline root layout, and add a comment
explaining why:
```html
<!-- No CSRF token: this layout is cached by the service worker and served offline.
     CSRF tokens are session-scoped and would be stale in a cached response.
     Mutations should be queued via the offline sync seam, not direct form submission. -->
```

---

## Info

### IN-01: Test `@tmp_dir` is a relative path — sensitive to test runner CWD

**File:** `test/mix/tasks/crosswake.gen.offline_ui_test.exs:7`

**Issue:** `@tmp_dir "tmp_offline_ui_test"` is a bare relative path. `mix test` reliably
sets CWD to the project root, making this work in practice. However if the test suite is
ever invoked from a non-project-root CWD (e.g., a CI step with `cd test && mix test`), the
temp directory is created in the wrong location, the `File.rm_rf!` in `setup` may silently
remove the wrong directory, and `on_exit` cleanup silently fails. `async: false` prevents
parallel collisions within this module but does not address the CWD sensitivity.

**Fix:** Use `System.tmp_dir!/0` combined with a unique subdirectory:
```elixir
@tmp_dir Path.join(System.tmp_dir!(), "crosswake_offline_ui_test_#{System.unique_integer([:positive])}")
```
Or pin it relative to the test file:
```elixir
@tmp_dir Path.join(__DIR__, "../../tmp/offline_ui_test")
```

---

_Reviewed: 2026-06-14T04:26:36Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
