---
phase: 108-consumer-normalization
plan: "01"
subsystem: brand/css
tags: [brand, css, tokens, dark-mode, normalization]
dependency_graph:
  requires: [107-token-source-distribution]
  provides: [normalized-served-app-css, normalized-offline-page, single-canonical-stylesheet]
  affects: [examples/phoenix_host/priv/static/css/app.css, examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex]
tech_stack:
  added: []
  patterns: [semantic-token-only CSS, vendor-by-link token consumption, D-06 status-button contrast guard]
key_files:
  created: []
  modified:
    - examples/phoenix_host/priv/static/css/app.css
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  deleted:
    - examples/phoenix_host/assets/css/app.css
decisions:
  - "DELETE path for assets/css/app.css: both D-12 safety gate conditions confirmed (no served path references; unique rules style only unserved/self-styled surfaces)"
  - "Used :focus-visible instead of :focus for btn-primary focus rule (D-07 best practice)"
  - "btn-success foreground = text-inverse (theme-aware); btn-danger foreground = text-inverse (consistency per D-06)"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-13"
  tasks_completed: 3
  files_modified: 2
  files_deleted: 1
---

# Phase 108 Plan 01: Served Consumer Normalization Summary

**One-liner:** Deleted flat :root palette + font stacks from served app.css and remapped all component values to semantic --cw-* tokens; retired unserved assets/css/app.css after D-12 safety gate; wired offline page inline styles to tokens.css via semantic custom properties.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Normalize SERVED priv/static/css/app.css onto semantic tokens | 23b329f | examples/phoenix_host/priv/static/css/app.css |
| 2 | Delete unserved assets/css/app.css after D-12 safety gate | c99456a | examples/phoenix_host/assets/css/app.css (deleted) |
| 3 | Normalize offline page index.html.heex inline style block | eef9a54 | examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex |

## What Was Done

### Task 1: Served app.css normalization

Deleted the entire hand-authored flat `:root` block (16 hex palette aliases + duplicate font-stack declarations for --cw-font-display/body/mono). The `tokens.css` is already linked before `app.css` by DeckLive (confirmed lines 15-16 of deck_live/index.ex and show.ex), so all custom properties were already defined upstream.

Remapped every component value to semantic `--cw-*` tier (D-04):
- `body`: foam-50 → `surface-default`; current-950 → `text-default`
- `.page-title`: current-950 → `text-default`
- `.card`: white → `surface-inset`; mist-200 → `border-default`; 14px → `radius-lg`
- `.card-title`: current-950 → `text-default`; 20px → `text-scale-xl`
- `.btn-primary`: wake-700 → `action-bg`; white → `action-fg`; 10px → `radius-md`
- `.btn-primary:hover`: current-950 → `action-hover`
- `.btn-primary:focus-visible`: 2px solid brass-500 → `focus-ring-width solid action-focus-ring` (D-07; used `:focus-visible` not `:focus`)
- `.btn-secondary`: current-950 → `text-default`; mist-200 → `border-default`; 10px → `radius-md`
- `.btn-secondary:hover`: foam-100 → `surface-raised`
- `.badge`: mist-200 → `surface-raised`; current-950 → `text-default`; 6px → `radius-sm`; 12px → `text-scale-xs`
- `.text-sm`: stone-500 → `text-muted` (D-05 — NOT text-subtle); 14px → `text-scale-sm`

Retained `box-shadow: 0 1px 2px rgba(9, 20, 26, 0.06)` — no shadow token exists; this is rgba of current-950, not a 6-hex brand literal (documented defer).

No `var()` fallbacks added (D-10). No `--cw-primitive-*` references remain. No `--cw-text-subtle` usage.

### Task 2: Unserved duplicate reconciliation

**Path taken: DELETE** (not fold).

D-12 safety gate evidence:
- **(a)** `grep -rl 'assets/css/app.css' examples/phoenix_host/lib examples/phoenix_host/config` returns 0 results. All link tags use `/css/app.css` which maps to `priv/static/css/app.css`.
- **(b)** Unique class names in the unserved file:
  - `sync-status-pending`/`sync-status-complete`: only set by `examples/phoenix_host/assets/js/app.js` which is not served (no `<script>` link in any template)
  - `card-front`/`card-back`/`btn-success`/`btn-danger`: appear in `index.html.heex` which has its own inline `<style>` block (normalized in Task 3); the `offline_study.js` injects `card-front`/`card-back` div content but the styling comes from `index.html.heex`'s own styles, not from `assets/css/app.css`
  - `badge-offline`/`badge-native`: not referenced in any served surface

Both conditions hold. Deleted via `git rm`. One canonical example-host stylesheet remains.

### Task 3: offline page index.html.heex normalization

Added `<link rel="stylesheet" href="/css/tokens.css">` in `<head>` (plain link tag — this is a standalone HTML file without PhxVerifiedRoutes `~p` sigil; `tokens.css` already exists at `priv/static/css/tokens.css` served at `/css/tokens.css`).

Replaced all Tailwind-system hex in the inline `<style>` block:
- `body`: `system-ui, sans-serif` → `font-body`; `#f3f4f6` → `surface-default`; `#1f2937` → `text-default`
- `#flashcard-container`: `white` → `surface-inset`; `0.5rem` → `radius-md`; box-shadow `rgba(0,0,0,0.1)` retained (plain rgba, not brand hex)
- `.card-back`: `#e5e7eb` → `border-default`; `#4b5563` → `text-muted` (D-05)
- `button`: `0.25rem` → `radius-sm`
- `.btn-primary`: `#3b82f6` → `action-bg`; `white` → `action-fg`
- `.btn-success`: `#10b981` → `status-success`; `white` → `text-inverse` (D-06: status-success flips to wake-500 in dark mode; text-inverse is theme-aware)
- `.btn-danger`: `#ef4444` → `status-error`; `white` → `text-inverse` (consistency per D-06; error does not flip but text-inverse is preferred)
- `#status`: `0.875rem` → `text-scale-sm`; `#6b7280` → `text-muted` (D-05)

Microcopy unchanged per D-09. Page structure unchanged (no redesign). No `var()` fallbacks (D-10). No `--cw-primitive-*` references.

## Deviations from Plan

### Auto-applied improvements

**1. [Rule 2 - Best Practice] Used :focus-visible instead of :focus for btn-primary focus rule**
- **Found during:** Task 1
- **Issue:** Plan specified `.btn-primary:focus { outline: ... }` but `:focus` also fires on mouse click, which is unnecessary and visually noisy
- **Fix:** Used `.btn-primary:focus-visible { outline: ... }` per D-07 intent (WCAG / Windows Forced-Colors compatible; captures keyboard-only focus)
- **Files modified:** examples/phoenix_host/priv/static/css/app.css
- **Commit:** 23b329f

No other deviations. Plan executed as written.

## Known Stubs

None. The offline page's "Loading flashcards..." placeholder is managed by the served `offline_study.js` JS injection — not a CSS stub.

## Threat Flags

None. This plan edits static CSS and one static HEEx page. No auth, no network surface, no user-controlled input reaches the style block.

## Self-Check: PASSED

Files created/modified:
- [x] examples/phoenix_host/priv/static/css/app.css — FOUND, contains `var(--cw-surface-default)`, `var(--cw-text-muted)`, zero hex literals
- [x] examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex — FOUND, contains `/css/tokens.css` link, `var(--cw-status-success)`, `var(--cw-text-inverse)`, zero Tailwind hex
- [x] examples/phoenix_host/assets/css/app.css — CONFIRMED DELETED

Commits:
- [x] 23b329f — feat(108-01): normalize served example host app.css onto semantic tokens
- [x] c99456a — chore(108-01): delete unserved assets/css/app.css duplicate (D-12)
- [x] eef9a54 — feat(108-01): normalize offline page index.html.heex onto semantic tokens
