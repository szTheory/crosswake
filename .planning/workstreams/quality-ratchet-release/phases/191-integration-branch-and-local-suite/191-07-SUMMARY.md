---
phase: 191-integration-branch-and-local-suite
plan: 07
subsystem: testing
tags: [review-fixes, preflight, verify-twin, provenance]
requires: [191-06]
provides: [LAND-02 D-17a review fixes WR-05, WR-01/06, WR-03]
status: complete
commits: 3
plan_head_before: 6b9a6d9c52ae94fa8f1815256990d8feeda09b27
plan_head_after: e8caf915737c412fc6cd74d624e71e3a9894aa10
requirements-completed: []
---

# Phase 191 Plan 07: Phase 190 review findings fixed in the landed code Summary

Three review findings from Phase 190 are now fixed in the integration branch, each with a failing test first and its own commit.

## What changes for the user

- **WR-05 (commit WR-05 `ead01be5`).** The physical-iPhone preflight used to pass a `route_activation.json` that merely parsed (`null`, `[]`, `{}`, a number or list as origin, or an origin that is not a URL). It now blocks all three modes (preflight-only, readiness, run) with PI-PREFLIGHT-CONFIG and the existing plain-language unreadable-activation message. The check is one new `@doc false` function `usable_activation_origin?/1` in the origin-mode module; `observe/2` is byte-identical (diff has zero removed lines). The absent-file case still passes.
- **WR-01 with WR-06 (commit WR-01-06 `62a71f8b`).** A twin run that stops with a surviving child or an already-gone registry now shows its own cause and a plain note in the printed verdict, like a registry timeout. The exit code and the written receipt are unchanged (tests assert the receipt and projection do not mention the cause). The old "other stop results leave the verdict unchanged" test is replaced by one assertion per result.
- **WR-03 test half (commit WR-03 `e8caf915`).** The hostile-git-config provenance test now first asserts the clean tree reads as the real commit under each hostile setting, then makes the file dirty and asserts `git-unknown`. It can no longer pass just because git cannot report a commit.

## How RED proved the old behaviour

- WR-05: 37 tests, exactly the six new table cases failed on the unchanged preflight (EV/red-WR05-191.txt); 0 failures after.
- WR-01: 33 tests, 3 failed first (child_still_alive, registry_gone, and the run-wiring test); see the deviation about a fourth existing test.
- WR-03: the method `path_without_git` could not start (Hex would not load under a git-less PATH), so the allowed fallback was used: a temporary wrong-head edit failed the new assertion (1 failure), then the file was restored byte for byte. Recorded as `method wrong_head_fallback`.

## WR-06 outcome

Shipped in the WR-01 commit. `execute/2` already takes an injected producer, so the wiring test (a producer that stops the registry; the annotated verdict reaches the output, the receipt does not) needed 0 added lib lines for the seam. The lib change for WR-01 is 14 added lines, under the 30-line budget.

## Commits (integration clone, branch land/v25-v27)

Chain after SWIFT-G4 `6b9a6d9c`: WR-05 `ead01be5`, WR-01-06 `62a71f8b`, WR-03 `e8caf915`. Heads lines appended. Each commit passed format, warnings-as-errors and the subset gate (suite-WR-05, suite-WR-01, suite-WR-03 all `result pass`). The tracked `.exs` count stays 253; no `.planning/` path changed in the clone; the clone is clean.

## Deviations from Plan

- **[Rule 1] Existing test updated.** Besides the replaced annotate test, a second pre-existing test ("a registry already released before the receipt never crashes the command") and the older "registry gone leaves a passing verdict unchanged" run test asserted `first cause: none` for a gone registry. They encoded the WR-01 bug; both now expect `registry_gone` (exit 0 kept). The latter was rewritten as the WR-06 wiring test.
- **Ledger regenerated** in the WR-01-06 commit: only one row's display line moved (359 to 363); site count 243 before and after. I first committed without it, noticed `--check` failing, soft-reset my own unpushed commit and recommitted with the regenerated ledger; the heads line and suite evidence were redone.
- **A-14.** The commit chain is FORMAT, LOCALE, G1, PRIVACY, HOST-G2G6, SWIFT-G4; the WR-05 parent is SWIFT-G4 (the last heads line). No denylist clauses used.
- Trailer is `Co-Authored-By: Claude Sonnet 5.5` as instructed. The gate evidence for WR-01 is also copied to suite-WR-01.txt (the commit label is WR-01-06).
- WR-03 RED used the allowed wrong-head fallback (above).

## Self-Check: PASSED

Parents, file sets, RED records, suite records bound to heads, ledger `--check` OK, `.exs` count 253, clone clean.
