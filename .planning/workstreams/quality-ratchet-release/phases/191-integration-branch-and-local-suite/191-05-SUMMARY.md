---
phase: 191-integration-branch-and-local-suite
plan: 05
status: complete
requirements: [LAND-02]
commits: 0
plan_head_before: 2faf15a255f644c869d321508c4d3f3007572138
plan_head_after: 64a60effe28c38d0a1ce9741107cc44f570296be
---

# Phase 191 Plan 05: Format, locale, G1 and privacy fixes Summary

Four commits now sit on `land/v25-v27` in the integration clone, directly after the candidate head 2faf15a2. The recovery checkout itself got no commit (frozen, D-23), so `commits: 0` above refers to it. All four commits carry the Co-Authored-By trailer.

**Downstream note: the integration-clone HEAD after this plan is the PRIVACY commit (last line of `191-EVIDENCE/heads-191.txt`), not G1.**

| Label | SHA | What it fixed |
|---|---|---|
| FORMAT | 909ace5a | Whole-project format check now passes; only `native_shell_upgrade_test.exs` was reformatted (D-15). |
| LOCALE | 5fd65f9f | The five Phase 170 ledger failures. Cause was the C locale, not test order: the Phase 190 "order-dependent" diagnosis was wrong (D-12). |
| G1 | ee9d304d | Root G1 test now asserts the decided fact: host audio command validates to `[]`, and an unknown capability yields exactly one `:capabilities` error (D-13). Ledger regenerated. |
| PRIVACY | 64a60eff | A-14 cleanup of the 3 listed personal values. |

## Proof, red first
- LOCALE: a new C-locale decode test (end of the Phase 170 ledger test file) failed on the unchanged script (`red_exit 2`, JSON invalid byte), then passed. Evidence: `red-LOCALE-191.txt`.
- G1: the old G1 test was the known failure (`red_exit 2`); both new tests pass. Classified sites 243 before and 243 after; collection forms in the test file 1 and 1. Evidence: `red-G1-191.txt`.
- Gates (subset, each `result pass`): FORMAT 4 tests, LOCALE 25 tests, G1 28 tests, PRIVACY (ios_host_config_test) pass, all 0 failures. Format check and `compile --warnings-as-errors` exited 0 before every commit. The ledger `--check` passes under both C and C.UTF-8. Tracked `.exs` count is still 253; no `.planning/` path changed.

## Privacy re-scan (A-14), `EV/scan-privacy-fix-191.txt`
commits 98, gitleaks_findings 0, blocking_final 0, history_sensitive 0, history_personal 2 (accepted old values in preserved history), triaged 1, result clean (exit 0).
- Example host config: the hard-coded home-folder path became `Path.expand("../native/ios", __DIR__)` (verified it resolves to the real directory).
- iOS host config test: the fake attacker origin address now uses the reserved `.invalid` domain; test file 16 tests, 0 failures.

## Deviations from Plan
1. **[Rule 1 - Bug] IO.binwrite alone is not enough.** With plain `IO.binwrite`, the C locale passed but a UTF-8 locale double-encoded the output and broke the ledger-completeness test. Fix: a small `emit_bytes/1` helper that sets stdout to latin1 and then calls `IO.binwrite`, used at both emit sites (output byte-identical to the committed ledger in both locales). Only the inventory script differs from the plan's wording.
2. **Ledger in the LOCALE commit:** not regenerated (not needed; sites 243/243).
3. **Triage row added** (`scan-triage-191.tsv`) for the old fake attacker-style address that remains only in the preserved candidate commit's added lines; the scanner counts an email in history as sensitive even after it leaves the tree. Reason recorded in the row. History was not rewritten.
4. The G1 commit also updated the navigation comment line number above the override entry (40 to 44).

## Self-Check: PASSED
