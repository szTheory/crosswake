---
phase: 129-stable-companion-contract-surface
plan: "01"
subsystem: proof-test
status: complete
tags: [proof, seam, tdd, d18]
completed: "2026-06-25"
duration: "1m"

dependency_graph:
  requires: []
  provides: [phase129-companion-contract-freeze-test]
  affects: [test/crosswake/proof/]

tech_stack:
  added: []
  patterns:
    - MapSet.equal? callback freeze (upgrade from membership-only, D-12)
    - Code.fetch_docs/1 EEP-48 moduledoc/typedoc assertion (first use in Phase 129)
    - Mix.Project.config()[:docs][:groups_for_modules] single-source-of-truth derivation (D-15)

key_files:
  created:
    - test/crosswake/proof/phase129_companion_contract_freeze_test.exs
  modified: []

decisions:
  - "async: true (read-only test — no Application.put_env, unlike phase38/phase65)"
  - "MapSet.equal? catches both callback additions AND removals (D-12 upgrade from membership-only)"
  - "@struct_contract_modules hardcoded list for typedoc test; contract_modules() derives from Mix.Project.config() for moduledoc/boundary tests (D-15)"
  - "Intentionally fails on Finding-present + guide-exists + typedoc until plan 129-02 lands (D-18)"

requirements: [SEAM-01, SEAM-03]
---

# Phase 129 Plan 01: Write Phase 129 Companion-Contract Freeze Proof Test Summary

Write-test-first (D-18) merge-blocking freeze test asserting the 6-callback Companion shape, non-hidden moduledocs, typedocs on t(), Shell.Denial boundary exclusion, and companion_contract.md guide existence — all encoded before any source changes land.

## What Was Built

Created `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` as an untagged, `async: true` proof test in the existing PR-gating lane. The test encodes SEAM-01 and SEAM-03 as merge-blocking CI assertions:

1. **Callback freeze** — `MapSet.equal?` asserts exactly the 6 frozen `{name, arity}` tuples. Both additions and removals fail (D-12 upgrade from prior membership-only idiom).
2. **moduledoc non-hidden** — loops over `contract_modules()` (derived from `Mix.Project.config()[:docs][:groups_for_modules]`) and asserts each returns a map moduledoc from `Code.fetch_docs/1`. Passes vacuously until 129-02 adds the "Companion Contract" group.
3. **typedoc on t/0** — loops over `@struct_contract_modules` (4 struct types) and asserts `{:type, :t, 0}` doc entry is a map via EEP-48.
4. **Denial absent** — `refute Crosswake.Shell.Denial in contract_modules()` (boundary test, D-19).
5. **Finding present** — `assert Crosswake.Compatibility.Finding in contract_modules()` (SEAM-03 active gate).
6. **Guide exists** — `File.exists?("guides/companion_contract.md")`.

## Test Run Result (before 129-02)

```
6 tests, 3 failures
```

Expected failures (D-18 write-test-first forcing function):
- Test 3 (typedoc): `@moduledoc false` struct modules return `:none` typedoc — fails until 129-02 promotes them
- Test 5 (Finding present): "Companion Contract" group does not yet exist in `mix.exs` — fails until 129-02
- Test 6 (guide exists): `guides/companion_contract.md` does not yet exist — fails until 129-02

Passing tests (correct green state):
- Test 1 (callback freeze): confirmed 6 callbacks match exactly
- Test 2 (moduledoc): passes vacuously — `contract_modules()` returns `[]`
- Test 4 (Denial absent): correct — Denial not in empty `[]` group

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write Phase 129 companion-contract freeze proof test | be33ecb | test/crosswake/proof/phase129_companion_contract_freeze_test.exs |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The test is intentionally failing (D-18); the failures are the stubs that 129-02 resolves.

## Threat Flags

None — read-only ExUnit reflection test. No new network surface, no auth paths, no data storage.

## Self-Check: PASSED

- [x] `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` exists
- [x] Commit be33ecb present in git log
- [x] Test compiles and runs: 6 tests, 3 expected failures
- [x] No `@tag` decorators present (untagged)
- [x] `async: true` set
- [x] `@expected_callbacks` contains exactly 6 frozen tuples
- [x] `contract_modules/0` reads from `Mix.Project.config()`, not a hardcoded list
