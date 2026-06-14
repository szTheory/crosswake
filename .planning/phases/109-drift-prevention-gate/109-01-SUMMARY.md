---
phase: 109-drift-prevention-gate
plan: "01"
subsystem: brandbook/tools
tags: [drift-gate, ci-tooling, brand-normalization, node-script]
dependency_graph:
  requires:
    - brandbook/tools/contrast.mjs (PALETTE named export)
    - priv/static/crosswake/offline.css (manifest target — normalized Phase 108)
    - examples/phoenix_host/priv/static/css/app.css (manifest target — normalized Phase 108)
    - priv/templates/crosswake/offline_ui/offline_page.html.heex.eex (manifest target)
    - priv/templates/crosswake/offline_ui/offline_root.html.heex.eex (manifest target)
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex (manifest target)
  provides:
    - brandbook/tools/check-consumer-drift.mjs (exported API: findHexColors, findPrimitiveRefs, checkCssSemanticCoverage, findRetiredTailwindInClassAttrs, checkFile, MANIFEST)
  affects:
    - .github/workflows/brandbook-verify.yml (Plan 109-03 will wire this script in)
    - brandbook/tools/check-consumer-drift.test.mjs (Plan 109-02 imports exported functions)
tech_stack:
  added: []
  patterns:
    - IS_MAIN guard for module/script dual-use (mirrors check-candidates.mjs)
    - Lookbehind hex regex for value-context-only detection (excludes #id selectors)
    - Curated inline manifest with per-entry type annotation (D-02 pattern)
    - Plain-node exit-0/exit-1 convention (mirrors check-production.mjs)
key_files:
  created:
    - brandbook/tools/check-consumer-drift.mjs
  modified: []
decisions:
  - Used lookbehind regex /(?<=[:,(\s])#([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b/g to exclude #id selectors without post-match heuristics
  - PALETTE lookup for human-readable violation messages only; independent regex for detection (parseHex throws on 3/8-digit)
  - Tailwind check scoped to /class="([^"]*)"/g attribute values to avoid flagging display:flex in inline <style> blocks
  - IS_MAIN guard placed after all exports so Plan 02 can import pure functions without running scan
  - Deferred offender comment uses verified correct path: crosswake_example/saas_portal/step_up_challenge_live.ex (not crosswake_example_web/live/saas_portal/)
metrics:
  duration: "~15 minutes"
  completed: "2026-06-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
---

# Phase 109 Plan 01: Detection Module and Green Baseline Summary

**One-liner:** Browser-free consumer-drift script with 5-entry curated manifest, 4 exported check functions, and green-baseline exit-0 on the current zero-hex normalized tree.

## What Was Built

Created `brandbook/tools/check-consumer-drift.mjs` — a plain Node.js script that scans a curated manifest of 5 normalized consumer files and exits non-zero when any reintroduces brand-color drift.

### Exported API (for Plan 02 contract test imports)

- `findHexColors(content)` — line-by-line scan using lookbehind hex regex; excludes `#id` selectors; PALETTE name-lookup for 6-digit matches
- `findPrimitiveRefs(content)` — detects `var(--cw-primitive-` references
- `checkCssSemanticCoverage(content)` — returns `{ ok: boolean }` based on `var(--cw-` presence
- `findRetiredTailwindInClassAttrs(content)` — scans `class="..."` attribute values for 9-entry retired Tailwind blocklist
- `checkFile(entry, content)` — dispatches all 4 rules per file type
- `MANIFEST` — 5-entry curated inline array (2 CSS, 3 HEEX)

### False-Positive Guards Implemented

| Guard | Mechanism |
|-------|-----------|
| `#id` CSS selectors | Lookbehind `(?<=[:,(\s])` requires value-context before `#` |
| `display:flex` in `<style>` block | Tailwind check scoped to `class="..."` attrs via `/class="([^"]*)"/g` |
| `rgba()` shadows | Naturally excluded — hex regex only matches `#`-prefixed tokens |
| `[scrollbar-gutter:stable]` | Not in RETIRED_TAILWIND list; documented in manifest header comment |

### Curated Manifest (5 entries)

| Path | Type |
|------|------|
| `examples/phoenix_host/priv/static/css/app.css` | css |
| `priv/static/crosswake/offline.css` | css |
| `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` | heex |
| `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` | heex |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` | heex |

Excluded: `offline_study.js` (innerHTML hex), `step_up_challenge_live.ex` (dead Tailwind), `tokens.css` (D-04: parity covered by compile-tokens.test.mjs:222).

## Verification Results

### Task 1 Smoke Test

```
node -e "import('./brandbook/tools/check-consumer-drift.mjs').then(...)"
→ PASS
```

All smoke test assertions confirmed:
- Hex in value position: detected (1 violation)
- `#status` CSS ID selector: NOT flagged (0 violations)
- `rgba()` shadow: NOT flagged (0 violations)
- `flex` in class attr: flagged (1 violation)
- `display:flex` in inline `<style>`: NOT flagged (0 violations)
- `[scrollbar-gutter:stable]` in class attr: NOT flagged (0 violations)
- Zero `var(--cw-` coverage: `{ ok: false }` (correct)

### Task 2 Green Baseline

```
node brandbook/tools/check-consumer-drift.mjs
→ All 5 consumer file(s) passed drift check.
→ exit=0
```

Green baseline confirmed on current normalized tree (PROOF-01 SC #4).

## Deviations from Plan

None — plan executed exactly as written. Both tasks were implemented in a single file creation since they modify the same file (`check-consumer-drift.mjs`) and are inseparable at file creation time.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 + Task 2 | 8747d10 | feat(109-01): create check-consumer-drift.mjs detection module and scan loop |

## Known Stubs

None. The script is fully functional and produces live detection results against the real manifest files.

## Threat Flags

None. Script reads only committed in-repo files via hardcoded manifest. No network, no user input, no secrets.

## Self-Check: PASSED

- [x] `brandbook/tools/check-consumer-drift.mjs` — FOUND
- [x] `.planning/phases/109-drift-prevention-gate/109-01-SUMMARY.md` — FOUND
- [x] Commit `8747d10` — FOUND
