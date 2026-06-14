---
phase: 108-consumer-normalization
plan: "02"
subsystem: brand-normalization
tags: [offline-ui, css-tokens, generator, a11y, tailwind-retirement]
dependency_graph:
  requires: [107-token-source-distribution]
  provides: [offline.css-vendored, offline-templates-token-backed, generator-no-clobber-offline]
  affects: [crosswake.gen.offline_ui, offline_page, offline_root]
tech_stack:
  added: []
  patterns: [vendor-by-copy, semantic-only-token-refs, ensure_file-no-clobber, cw-offline-class-namespace]
key_files:
  created:
    - priv/static/crosswake/offline.css
  modified:
    - priv/templates/crosswake/offline_ui/offline_root.html.heex.eex
    - priv/templates/crosswake/offline_ui/offline_page.html.heex.eex
    - lib/mix/tasks/crosswake.gen.offline_ui.ex
decisions:
  - "Used .cw-offline-* class namespace with 10 semantic classes: page, card, heading, status, status-label, status-value, session-list, session-item, session-title, session-subtitle"
  - "Status treatment: border-left (4px solid --cw-border-strong) as non-color shape cue per D-07 (no status-color fill behind light text — avoids D-06 wake-500 AA failure)"
  - "Body styling lives entirely in offline.css (.cw-offline-page); <body> tag carries no classes"
  - "Spacing expressed as calc(var(--cw-spacing-base) * N) multiples, no fallbacks"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-14"
  tasks_completed: 3
  tasks_total: 3
  files_created: 1
  files_modified: 3
---

# Phase 108 Plan 02: Offline UI Generator — Token Normalization Summary

**One-liner:** Vendored `offline.css` with `.cw-offline-*` semantic-class rules (consuming the Phase 107 token tier), Tailwind-free template rewrite with a11y upgrades, and generator wired to copy offline.css via the existing no-clobber mechanism with honest phx.gen.auth-style guidance.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author vendored priv/static/crosswake/offline.css | 1118702 | priv/static/crosswake/offline.css (created) |
| 2 | Rewrite offline_root + offline_page templates | f26b498 | offline_root.html.heex.eex, offline_page.html.heex.eex |
| 3 | Vendor offline.css in generator + retire stale block | 3c2e025 | lib/mix/tasks/crosswake.gen.offline_ui.ex |

## What Was Built

### Task 1 — `priv/static/crosswake/offline.css`

New vendored component stylesheet with 10 `.cw-offline-*` classes covering the full offline page structure:

- `.cw-offline-page` — page wrapper (full-height flex centering, bg/color/font from semantic tokens)
- `.cw-offline-card` — content card (surface-inset bg, border-default border, radius-lg)
- `.cw-offline-heading` — h1 (font-display, text-scale-xl, tracking-tight)
- `.cw-offline-status` — status card (surface-raised bg, border-default + 4px border-left in border-strong for D-07 non-color cue)
- `.cw-offline-status-label` — "Status" label (text-muted, text-scale-sm, font-display)
- `.cw-offline-status-value` — "Available offline" value (text-default, text-scale-lg)
- `.cw-offline-session-list` — ul wrapper (flex-col gap)
- `.cw-offline-session-item` — li item (surface-inset bg, border-default, radius-sm)
- `.cw-offline-session-title` — session title (text-default, font-weight 600)
- `.cw-offline-session-subtitle` — session subtitle (text-muted, text-scale-sm — NOT text-subtle per D-05)

**Required D-07 rules included:**
- `:root { color-scheme: light dark; }` — browser chrome/scrollbars track theme
- `:focus-visible { outline: var(--cw-focus-ring-width) solid var(--cw-action-focus-ring); outline-offset: 2px; }` — `outline`, not `box-shadow` (visible in Windows Forced-Colors)

**Status treatment decision:** `border-left: 4px solid var(--cw-border-strong)` shape cue, not a status-color fill. This avoids the D-06 `--cw-status-success` dark-mode AA failure (wake-500 on white ~2.9:1). Color-not-alone WCAG 1.4.1 compliance via structural shape.

### Task 2 — Templates rewritten

**offline_root.html.heex.eex:**
- Added `<link phx-track-static rel="stylesheet" href={~p"/assets/offline.css"} />` after tokens.css and app.css
- Removed `class="bg-cw-foam-50 text-cw-current-950 antialiased"` from `<body>` — body styling lives in offline.css
- Link order confirmed: tokens.css (byte 390) < app.css (byte 467) < offline.css (byte 541)

**offline_page.html.heex.eex:**
- All 33 Tailwind utility/color classes retired (min-h-screen, flex, bg-white, bg-cw-foam-50, text-cw-current-950, border-cw-*, border-gray-*, text-gray-*, space-y-4, max-w-md, etc.)
- Replaced with `.cw-offline-*` semantic classes matching offline.css
- D-08 a11y: `role="status"` on status div, `role="list"` on session ul, `<h2>` heading for "Status"
- Session list: `<div class="space-y-4">/<div>` → `<ul role="list">/<li>` semantic structure
- D-09 microcopy preserved verbatim: "Offline Workspace", "Status", "Available offline", "Study Session A", "Pending server confirmation", "Study Session B", "Draft only"
- HTML comment marks proto-copy as placeholder for adopters

### Task 3 — Generator (`crosswake.gen.offline_ui.ex`)

- Added `get_offline_css_path/0` private function mirroring `get_tokens_css_path/0` pattern (Application.app_dir + File.cwd! fallback)
- Added `offline_css_dest = Path.join([dir, "priv", "static", "assets", "offline.css"])`
- Added `ensure_file(offline_css_dest, File.read!(get_offline_css_path()))` after the tokens.css copy
- Retired stale Tailwind/esbuild Next-steps block (legacy blue `#699cc9` / amber `#e1b982` theme, `tailwind.config.js`, `Configure esbuild to bundle offline.js`) per D-11
- Replaced with honest phx.gen.auth-style guidance: states tokens.css + offline.css are host-owned, editable, no-clobber, no CSS build step required
- Preserved: `Offline UI components generated successfully!`, router mount step, legitimate JS bundling guidance
- `mix compile` passes with no new errors (verified from main repo with deps)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All `.cw-offline-*` class names wire to rules in offline.css. Proto-copy comment is intentional per D-09 (microcopy preserved, not changed).

## Threat Flags

None. No new network endpoints or trust boundaries introduced. The generator emits only static files and guidance text; EEx interpolation remains limited to `web_module`/`app_module` (T-108-03 unchanged). The no-clobber `ensure_file/2` guard covers T-108-04.

## Self-Check: PASSED

Files created/modified:
- priv/static/crosswake/offline.css — FOUND
- priv/templates/crosswake/offline_ui/offline_root.html.heex.eex — FOUND
- priv/templates/crosswake/offline_ui/offline_page.html.heex.eex — FOUND
- lib/mix/tasks/crosswake.gen.offline_ui.ex — FOUND

Commits:
- 1118702 feat(108-02): author vendored priv/static/crosswake/offline.css — FOUND
- f26b498 feat(108-02): rewrite offline_root + offline_page onto .cw-offline-* classes — FOUND
- 3c2e025 feat(108-02): vendor offline.css in generator (no-clobber) and retire stale Next-steps block — FOUND
