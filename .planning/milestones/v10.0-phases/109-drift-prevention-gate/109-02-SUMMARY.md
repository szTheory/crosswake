---
phase: 109-drift-prevention-gate
plan: "02"
subsystem: brandbook/tools
tags: [testing, drift-gate, contract-test, node-test, tdd]
dependency_graph:
  requires: [109-01]
  provides: [check-consumer-drift.test.mjs]
  affects: [brand-structural CI gate]
tech_stack:
  added: []
  patterns: [node:test synthetic fixtures, execSync green-baseline, IS_MAIN import-safe module]
key_files:
  created:
    - brandbook/tools/check-consumer-drift.test.mjs
  modified: []
decisions:
  - Static import of execSync at module top (not dynamic await import) for node:test compatibility
  - Both Task 1 and Task 2 committed in a single atomic commit (single file created containing both)
metrics:
  duration: "87s"
  completed: "2026-06-14T06:01:41Z"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
requirements: [PROOF-01]
---

# Phase 109 Plan 02: Contract/Pin Test for check-consumer-drift.mjs Summary

## One-Liner

node:test contract/pin test pinning 5-entry manifest completeness, 4 PROOF-01 rule assertions via synthetic fixtures, 4 false-positive guards, 9-token blocklist pin, and execSync green-baseline proving exit 0 on the current normalized tree.

## What Was Built

`brandbook/tools/check-consumer-drift.test.mjs` — a 14-test `node:test` suite that:

1. **Manifest completeness** — pins `MANIFEST.length === 5` and that every path resolves on disk via `existsSync`.
2. **PROOF-01 SC #1 (hex injection)** — `findHexColors('color: #2B756A;')` returns length 1 with text including both `#2B756A` and palette name `wake-700`.
3. **PROOF-01 SC #2 (lost coverage)** — `checkCssSemanticCoverage('body { color: red; }').ok === false`; and `.ok === true` for a file with `var(--cw-text-default)`.
4. **Primitive injection** — `findPrimitiveRefs('color: var(--cw-primitive-foam-50);')` length ≥ 1; semantic var returns length 0.
5. **Retired Tailwind in class attr** — `findRetiredTailwindInClassAttrs('<div class="flex items-center">')` flags `flex`.
6. **Guard — #id selector** — `findHexColors('#status { color: var(--cw-text-muted); }')` returns length 0.
7. **Guard — rgba() shadow** — `findHexColors('box-shadow: 0 4px 6px rgba(9,20,26,0.06);')` returns length 0.
8. **Guard — display:flex in style block** — `findRetiredTailwindInClassAttrs('<style>body { display: flex; }</style><div class="btn-primary">')` returns length 0.
9. **Guard — [scrollbar-gutter:stable]** — `findRetiredTailwindInClassAttrs('<html lang="en" class="[scrollbar-gutter:stable]">')` returns length 0.
10. **Blocklist pin** — loops all 9 retired tokens (`flex`, `bg-white`, `bg-cw-`, `text-cw-`, `min-h-screen`, `border-cw-`, `border-gray-`, `space-y-`, `max-w-md`), each injected into `<div class="${t}">`, and asserts each is detected.
11. **Green-baseline integration** — `execSync(`node ${scriptPath}`, { cwd: ROOT, stdio: 'pipe' })` inside `assert.doesNotThrow(...)` confirms the gate exits 0 on the current tree.

All 14 tests pass with zero failures.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Synthetic-fixture assertions for every rule + false-positive guard | 8f56d91 | brandbook/tools/check-consumer-drift.test.mjs |
| 2 | Green-baseline integration assertion against the real tree | 8f56d91 | brandbook/tools/check-consumer-drift.test.mjs (extended) |

Note: Both tasks produce output in a single file, committed atomically as one create.

## Verification

```
node --test brandbook/tools/check-consumer-drift.test.mjs
# tests 14
# pass 14
# fail 0
```

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

**Implementation note:** The PATTERNS.md green-baseline test shape showed `await import('node:child_process')` inside the test callback. This was changed to a static top-level import of `execSync` (the module is always available and node:test test callbacks do not need async for this pattern). This is a minor idiom adjustment, not a behavioral deviation.

## Known Stubs

None — the test file contains no placeholders or stub values.

## Threat Flags

None — the test file introduces no new network endpoints, auth paths, file access patterns, or schema changes. It reads only the committed `check-consumer-drift.mjs` module and (in the green-baseline test) runs the real scan across committed consumer files.

## Self-Check

- [x] `brandbook/tools/check-consumer-drift.test.mjs` exists
- [x] Commit 8f56d91 exists and contains the file
- [x] `node --test brandbook/tools/check-consumer-drift.test.mjs` passes (14/14)
- [x] All PROOF-01 success criteria covered by named tests
- [x] All 4 false-positive guards covered by named tests
- [x] 9-token blocklist pin loops all 9 tokens
- [x] Green-baseline test runs real script via execSync and asserts exit 0
