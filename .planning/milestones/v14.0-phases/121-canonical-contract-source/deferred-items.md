# Deferred Items — Phase 121 Plan 01

Pre-existing test failures encountered during full-suite run (not caused by Plan 01 changes).
These were failing BEFORE Plan 01 changes were applied (confirmed via git stash verification).

## Deferred Items

All six were re-run individually on 2026-09-16 during the v22.0 milestone close. **Every one
passes.** They were repaired incrementally across later phases (the two `phase52` fixtures are
explicitly recorded as fixed in Phase 135 by Phase 132's own deferred-items note) and this record
was simply never updated. One had also drifted by two lines, which is why the original citation
no longer resolved to a test.

Re-verified with:

```
mix test test/crosswake/hex_page_test.exs:82 test/crosswake/hex_page_test.exs:133 \
  test/crosswake/proof/phase48_provider_adapter_proof_test.exs:269 \
  test/crosswake/proof/phase69_docs_contract_parity_test.exs:65 \
  test/crosswake/proof/phase52_operator_truth_test.exs:75 \
  test/crosswake/proof/phase52_operator_truth_test.exs:101
```

- README guide link hygiene — test/crosswake/hex_page_test.exs:82 — guides/adoption.md has relative links to non-package path — Pre-v121 drift
  status: resolved
  verified: 2026-09-16 — passes
- HexDocs sidebar grouping — test/crosswake/hex_page_test.exs:133 — Missing :Setup group in groups_for_extras — Pre-v121 drift
  status: resolved
  verified: 2026-09-16 — passes
- CHANGELOG v3.7 claims — test/crosswake/proof/phase48_provider_adapter_proof_test.exs:269 — CHANGELOG missing required v3.7 unreleased claim text — Pre-v121 drift
  status: resolved
  verified: 2026-09-16 — passes
- Phase69 Android JVM parity — test/crosswake/proof/phase69_docs_contract_parity_test.exs:63 — guides_support missing expected Android JVM hermetic promotion phrase — Pre-v121 drift
  status: resolved
  verified: 2026-09-16 — passes, now at :65 (the test moved; the original :63 citation matches no test, which is why a location-scoped re-run silently reported "0 tests" rather than a failure)
- Phase52 inspect fixture — test/crosswake/proof/phase52_operator_truth_test.exs:75 — Normalized inspect JSON differs from stale fixture — Pre-v121 fixture drift
  status: resolved
  verified: 2026-09-16 — passes; fixture refreshed in Phase 135
- Phase52 readiness fixture — test/crosswake/proof/phase52_operator_truth_test.exs:101 — Normalized readiness JSON differs from stale fixture — Pre-v121 fixture drift
  status: resolved
  verified: 2026-09-16 — passes; fixture refreshed in Phase 135

## Note on shape

This file previously recorded the six items as a GFM table. The audit scanner reads table rows as
items, but `audit-open acknowledge` refuses to write to a table-row span
(`audit.cjs:1455` — "the CLI writer cannot anchor a safe write to it — edit the file directly"),
so these six could be surfaced but never cleared, hard-blocking a milestone close with no CLI path
out. Converted to bullet shape, which both the scanner and the writer handle. The original table's
content is preserved verbatim in the bullets above; only the shape changed.
