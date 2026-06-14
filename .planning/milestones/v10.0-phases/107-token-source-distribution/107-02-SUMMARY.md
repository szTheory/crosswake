---
phase: 107-token-source-distribution
plan: "02"
subsystem: brand-distribution
tags: [tokens, generator, offline-ui, example-host, css, tdd]
dependency_graph:
  requires: ["107-01"]
  provides: ["NORM-03-contract", "generator-tokens-copy", "example-host-vendored-tokens"]
  affects: ["lib/mix/tasks/crosswake.gen.offline_ui.ex", "priv/templates/crosswake/offline_ui/offline_root.html.heex.eex", "examples/phoenix_host/priv/static/css/tokens.css", "examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex", "examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/show.ex", "test/mix/tasks/crosswake.gen.offline_ui_test.exs"]
tech_stack:
  added: []
  patterns:
    - "Application.app_dir + File.cwd! dual-branch path resolution for packaged CSS"
    - "ensure_file no-clobber guard for tokens.css vendor copy"
    - "phx-track-static link before app.css in generator template"
    - "Plain href /css/tokens.css before /css/app.css in example-host LiveViews"
key_files:
  created:
    - examples/phoenix_host/priv/static/css/tokens.css
  modified:
    - lib/mix/tasks/crosswake.gen.offline_ui.ex
    - priv/templates/crosswake/offline_ui/offline_root.html.heex.eex
    - test/mix/tasks/crosswake.gen.offline_ui_test.exs
    - examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex
    - examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/show.ex
decisions:
  - "Used ensure_file/2 (not File.cp!) for tokens.css copy — preserves host-customized copy with 'reused' log (T-107-03 threat mitigation)"
  - "Generator destination is priv/static/assets/tokens.css (standard Phoenix); example host uses priv/static/css/tokens.css (special case — manual vendor)"
  - "Both consumers use same mechanism: vendor-by-copy + <link> — satisfying D-05/D-09/D-11"
  - "Plain href /css/tokens.css in example host LiveViews (not ~p verified routes — matches existing example host convention)"
metrics:
  duration: "~2.5 minutes"
  completed: "2026-06-13"
  tasks_completed: 2
  files_changed: 6
---

# Phase 107 Plan 02: Token Distribution via Copy + Link Summary

One-liner: Generator copies packaged tokens.css via ensure_file no-clobber into host priv/static/assets/, template links it before app.css, and example host vendors a byte-identical copy linked before app.css in both DeckLive views.

## What Was Built

### Task 1: Generator copies tokens.css + template links it (TDD)

Added `get_tokens_css_path/0` to `crosswake.gen.offline_ui.ex` using the identical `Application.app_dir(:crosswake, "priv/static/crosswake/tokens.css")` + `Path.join(File.cwd!(), ...)` fallback pattern as the existing `get_template_path/1`. In `run/1`, added a fifth `ensure_file` call writing the tokens content to `priv/static/assets/tokens.css` in the host dir.

Updated `offline_root.html.heex.eex` to insert `<link phx-track-static rel="stylesheet" href={~p"/assets/tokens.css"} />` immediately before the existing `app.css` link — ensuring token custom properties are defined before consuming rules.

Extended `crosswake.gen.offline_ui_test.exs` with three new assertions:
- `priv/static/assets/tokens.css` exists after `run/1` and contains `--cw-font-display`
- The generated `offline_root.html.heex` string contains `tokens.css` at a byte index before `app.css`
- A second `run/1` call logs "reused" and does NOT overwrite a host-customized tokens.css

### Task 2: Example host vendored tokens.css + LiveView links

Copied `priv/static/crosswake/tokens.css` verbatim to `examples/phoenix_host/priv/static/css/tokens.css` — `diff` exits 0 (byte-identical). This file will be diffable against the generator-produced copy for Phase 109's textual drift gate (D-11).

Added `<link rel="stylesheet" href="/css/tokens.css" />` immediately before `<link rel="stylesheet" href="/css/app.css" />` in both `DeckLive.Index` and `DeckLive.Show` (line 15 in each). Used plain href convention matching the existing example host pattern — not `~p` verified routes. `examples/phoenix_host/assets/css/app.css` is unchanged (Phase 108 scope).

## Verification Results

- `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` — **5 tests, 0 failures**
- `diff priv/static/crosswake/tokens.css examples/phoenix_host/priv/static/css/tokens.css` — **exits 0**
- Both DeckLive views: `/css/tokens.css` at line 15, `/css/app.css` at line 16
- `offline_root.html.heex.eex`: tokens.css at line 10, app.css at line 11

## TDD Gate Compliance

RED commit `cf95f80` — failing tests (3 failures, 2 passing)
GREEN commit `a6bd834` — all tests pass (5/5)

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. The plan's threat model (T-107-03: no-clobber guard) was implemented via `ensure_file/2` as specified. Both copies retain the `/* GENERATED from crosswake.tokens.json — do not edit */` header from Plan 01 (T-107-04 mitigation).

## Commits

| Task | Type | Hash | Description |
|------|------|------|-------------|
| Task 1 RED | test | cf95f80 | Failing tests for tokens.css copy + link-order |
| Task 1 GREEN | feat | a6bd834 | Generator copies tokens.css + template links it before app.css |
| Task 2 | feat | b934f85 | Vendor tokens.css into example host + link before app.css in both LiveViews |

## Self-Check: PASSED

All 7 key files verified present on disk. All 3 task commits verified in git log.
