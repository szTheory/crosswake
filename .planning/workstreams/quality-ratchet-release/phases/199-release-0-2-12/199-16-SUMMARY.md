---
phase: 199-release-0-2-12
plan: 16
subsystem: docs
tags: [rel-07, sc6, generated-guides, renderers, docs-sync, published-0.2.14]
status: complete

requires:
  - phase: 199-release-0-2-12
    provides: "199-15 reader audit: first release 0.2.12 for ios_host, schema 1.2.0 and the parity ledger"
provides:
  - "Local branch docs/199-record-0-2-14-published (WT crosswake-199-wt), cut from origin/main cbb90031, with the three generated SC6 guides true through their renderers and the qualifier guard test removed"
  - "Full-suite baseline on the fresh base and the post-edit result for the closeout suite floors"
affects: [199-17, 199-18, 199-19, 199-20]

plan_head_before: 282aa7443a0ee0e71c25dbe9ad9ded1a4a0fe2a8
plan_head_after: e64fe56d
commits: 4
commits_note: "2 code commits on the WT branch (base cbb900319b8f4352c46f031927a75b38f5c36bbd, head d9e11b55) plus 2 evidence commits in the main checkout (282aa744..e64fe56d); the SUMMARY commit follows"

actuals:
  tokens: 14000
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Qualifier sentences name the first release that has the behavior (read from the reader audit) and what earlier releases do, so they stay true after later releases"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/docs-truth-199.txt
  modified:
    - lib/crosswake/capability_map/renderer.ex
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/parity_ledger/renderer.ex
    - guides/capability_map.md
    - guides/support_matrix.md
    - guides/parity_ledger.md
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  removed:
    - test/crosswake/guides/unreleased_claim_qualifier_test.exs

key-decisions:
  - "Wording: ios_host is 'read from 0.2.12 on; 0.2.11 and earlier do not read it'; schema 1.2.0 is 'emitted from 0.2.12 on; 0.2.11 and earlier emit 1.1.0'; the vector-set hash and ledger 'ship from 0.2.12 on; 0.2.11 and earlier have neither'. V=0.2.12 was read from the audit line for all three claims. Where a guide tells a reader which version to install, 199-17 uses 0.2.14."

requirements-completed: []
---

# Phase 199 Plan 16: Generated guides name the first release Summary

The three generated guides (capability map, support matrix, parity ledger) no longer say the `:ios_host` declaration, manifest schema 1.2.0 or the parity ledger and vector-set hash are unpublished; each now names 0.2.12, the first release that has it per the 199-15 tarball audit, and states what 0.2.11 and earlier do. Nothing was pushed or merged.

## What was done

- Cut `docs/199-record-0-2-14-published` from fresh `origin/main` (cbb90031, includes PRs 289, 290, 291) in the sibling worktree `~/projects/crosswake-199-wt`. The worktree had been clean on `docs/todo-013-014-record-ledger-and-201-hardening`; that branch was left in place, not deleted and not pushed.
- Task 1 (tracer): removed `test/crosswake/guides/unreleased_claim_qualifier_test.exs` (21 tests), reworded the capability map renderer, regenerated through `mix crosswake.docs.sync`, check passed. Commit b0daed0f.
- Task 2: reworded the two support matrix sites and the parity ledger `@qualifier`, regenerated, check passed. Commit d9e11b55.
- Renderer zero-hit grep for `not in a published release yet` over `lib` and the three generated guides: 0 hits. The generated-guide diff against origin/main lists only the three generated guides. No `latest`, `current release` or `[Unreleased]` remains in the three renderers.
- Evidence: `199-EVIDENCE/docs-truth-199.txt` (branch base, first_release line, baseline_suite, removed_tests, four `site:` lines, sync checks, gate results).

## Measurements for the closeout floors

- Baseline on the fresh base, before any edit: `baseline_suite: base=cbb900319b8f ran=3201 total=3277`, with 19 failures. All 19 were `ExUnit.TimeoutError` (60 s per test) while the machine load average was 11 to 30 (other Phoenix servers running); no assertion failed. Re-running those 19 tests alone gave 19 total, 0 failures. The shared gate printed `verdict=FAIL reason=below_min` for that isolated run only because line-pinned runs make its excluded count larger than the total; mix itself exited 0.
- After both commits, full suite on the closeout branch: `total=3256 excluded=76 ran=3180 failures=0 verdict=PASS`. The total is the baseline 3277 minus the 21 removed tests.
- `removed_tests: 21`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removing the guard test left an orphan row in the collection-assertion ledger and stale counts in the phase 170 test**
- **Found during:** Task 1
- **Issue:** `script/collection_assertion_ledger.json` listed `unreleased_claim_qualifier_test.exs:64`, so `inventory_collection_assertions.exs --check` failed with one orphan, and `phase170_vacuous_assertion_ledger_test.exs` pins the site count (290), the assert_any count (147) and the safe-by-construction count (147).
- **Fix:** Deleted the one orphan row and moved the pins to 289, 146 and 146 with a dated comment. `--check` now prints OK for 289 sites and `--emit-snapshot` is byte-identical to the committed file.
- **Files modified:** `script/collection_assertion_ledger.json`, `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (both additional exact-path edits, in commit b0daed0f)

**2. [Order] Qualifier guard counted after the capability map edit, not before**
- **Issue:** The guard's test total was taken from the file as at origin/main, run once after the capability map was already reworded: 21 tests, 2 failures (the two capability_map claim tests, which fail by design once the qualifier is gone). The total (21) is the number recorded; the failures are the expected effect of the edit.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface.

## Notes for 199-17

- The hand-written guides that still carry the qualifier (architecture, compatibility, native_shell, native_shell_upgrade, and CHANGELOG) are 199-17's. Per the 199-15 caution: where a guide names the version to install use 0.2.14; where a claim names the earliest release that ships it, use the audited first release, 0.2.12.
- 199-17's zero-hit grep over `guides` and `lib` now replaces the removed guard as the check that no site still claims unpublished.

## Self-Check: PASSED

- Commits b0daed0f and d9e11b55 are on `docs/199-record-0-2-14-published` (`git log origin/main..HEAD` lists exactly these two); evidence commits 35a38f58 and e64fe56d are in the main checkout.
- The removed test file is absent in the worktree; `docs.sync --check` exits 0; the four `site:` lines and the baseline awk check pass.
