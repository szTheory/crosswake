# Phase 186 Plan 05: BLOCKED (designed stop, not executed)

Status: blocked at Task 1 (full-suite gate). Nothing was committed, no mutation harness was run, and
no requirement is complete. This is not a SUMMARY.

## What was checked and what happened

The whole uncommitted Phase 186 tree was run against the Phase 185 baselines.

Passed:
- Test-file pin literal is 249; 251 test files exist; the flagless checker exits 0 and prints
  "scanned 251 test files, pin 249".
- Swift: 89 tests ran (86 + 3 new). The only failure is the known G4 test, so the failing set equals
  the baseline (this is the accepted adjustment to the plan's "at least 90" clause).
- Focused ExUnit: 159 tests, 0 failures. Guides and readers: 289 tests, 0 failures.
- Docs sync, compile with warnings as errors, format and bash -n all exit 0.
- Adoption scan: the five routing.unclassified_path findings equal the Phase 185 set.
- Boundaries: no .github, Android, generated guide, manifest, BridgeChannel or fixture-resource path;
  the only script/ path is the harness; HEAD is still 25614cf6; push URL still no-push-phase180.

Failed:
1. In-scope, fixed in place (allowlisted file): `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs`
   carried an added `assert Enum.all?(List.delete(checks, config), ...)` line (186-04). The plan forbids
   any added assert Enum.all? line. It is now `others = List.delete(checks, config)`, `assert others != []`
   and an explicit state comparison. That also removed the one unclassified ledger site, so
   `inventory_collection_assertions.exs --check` passes with no ledger regeneration. File stays
   uncommitted in the candidate.
2. Blocking: the full suite has 3 failures, not the 1 baseline failure. The extra two are
   - `test/crosswake/doctor/doctor_test.exs:246`
   - `test/mix/tasks/crosswake_doctor_test.exs:117`
   (the baseline `phase180_twin_feasibility_test.exs:30` is the third.)

## Cause of the blocker

Both tests build a fake iOS fixture `Fixtures/crosswake_manifest.json` containing only
`{"manifest_schema_version":"1.0.0"}`. Phase 186's doctor (SEAM-08) now correctly reports a fixture
with no `routes` map as one `host_commands_stale` error with reason `malformed`, so doctor status
turns `:error` and those two "proof hooks pass" tests fail. The doctor behaviour is the intended
fail-closed one (a dedicated 186-01 test requires it); the two older test fixtures are stale.

Verified in a throwaway copy (since deleted): changing the iOS fixture literal to
`{"manifest_schema_version":"1.0.0","routes":{}}` in those two files makes both files pass
(60 tests, 0 failures). The fix lines are `doctor_test.exs` ~1173 and `crosswake_doctor_test.exs` ~354.

## Why this is a stop

Neither file is on the plan's path allowlist, and the plan says a failure is fixed "in the owning
allowlisted file only". Adding them would widen the commit's path set (the Task 3 verify rejects any
path outside the allowlist), which the instruction told me not to loosen.

## Exact way to reopen

Approve (or re-plan) a two-line fixture fix in the two test files above and add those two paths to the
Task 3 allowlist regex and the 20-26 path bound (22 + 2 = still within 26 only if the ledger is not
regenerated; the fixed tree has 24 changed paths). Then re-run Task 1 from step 4 (focused tests are
already green), the full suite, then Tasks 2 and 3. Evidence so far is in the run directory under
names ending -186 (swift-186-05, quick-186g, guides-186g, fix-186.full.out, adoption-scan-186).

State left behind: candidate HEAD unchanged; 22 uncommitted paths (the 22 from 186-01..04 with the
physical-iPhone test now amended as in item 1); no commit, no push, no mutation copy.
