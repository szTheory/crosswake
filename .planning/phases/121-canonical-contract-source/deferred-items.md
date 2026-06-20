# Deferred Items — Phase 121 Plan 01

Pre-existing test failures encountered during full-suite run (not caused by Plan 01 changes).
These were failing BEFORE Plan 01 changes were applied (confirmed via git stash verification).

## Out-of-Scope Pre-existing Failures (6 total)

| Test | File | Failure Reason | Note |
|------|------|---------------|------|
| README guide link hygiene | test/crosswake/hex_page_test.exs:82 | guides/adoption.md has relative links to non-package path | Pre-v121 drift |
| HexDocs sidebar grouping | test/crosswake/hex_page_test.exs:133 | Missing :Setup group in groups_for_extras | Pre-v121 drift |
| CHANGELOG v3.7 claims | test/crosswake/proof/phase48_provider_adapter_proof_test.exs:269 | CHANGELOG missing required v3.7 unreleased claim text | Pre-v121 drift |
| Phase69 Android JVM parity | test/crosswake/proof/phase69_docs_contract_parity_test.exs:63 | guides_support missing expected Android JVM hermetic promotion phrase | Pre-v121 drift |
| Phase52 inspect fixture | test/crosswake/proof/phase52_operator_truth_test.exs:75 | Normalized inspect JSON differs from stale fixture | Pre-v121 fixture drift |
| Phase52 readiness fixture | test/crosswake/proof/phase52_operator_truth_test.exs:101 | Normalized readiness JSON differs from stale fixture | Pre-v121 fixture drift |

These are deferred for a separate cleanup phase. They are NOT caused by the bridge-protocol axis
single-sourcing changes in Plan 01.
