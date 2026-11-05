# Phase 198 deferred items

- `test/crosswake/proof/phase52_operator_truth_test.exs:101` (publish-readiness JSON fixture differs) and its wrapper `Phase135CiOpsProofTest` "phase52_operator_truth" fail on this branch with and without the Plan 08 Task 2 edits (verified 2026-11-05 by reverting the lib, guide and drift-test edits and rerunning the single test). Pre-existing, out of scope; not fixed.
- `test/crosswake/proof/phase175_linked_authorization_test.exs` (2 tests) fail with `Crosswake.ReleaseCandidate.EvidenceLiveTest.fixture/1 is undefined` when `test/crosswake/proof` is run without the release-candidate test directory; a partial-run artifact, not caused by Phase 198.
