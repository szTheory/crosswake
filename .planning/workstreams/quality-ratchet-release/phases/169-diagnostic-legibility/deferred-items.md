# Deferred Items

- REQUIREMENTS.md header does not name the active milestone "v23.0 Release Pipeline Repair & Proof-Lane Truth"
  status: open
  **What:** `test/crosswake/planning/milestone_transition_reset_test.exs` ("live operational
  surfaces all name the milestone from STATE frontmatter") and its dependent
  `test/crosswake/proof/phase135_ci_ops_proof_test.exs` ("deferred core-hermetic failures are now
  green: milestone_transition_reset") both fail because `REQUIREMENTS.md`'s header text has not
  been updated to name the v23.0 milestone.
  **Found during:** 169-02's plan-level `mix test` (full suite) verification step.
  **Scope:** Out of scope for 169-02 — unrelated to `lib/crosswake/release_status.ex`,
  `lib/mix/tasks/crosswake.release.status.ex`, or the scanner's ROSTER/DONE protocol this plan
  touches. Confirmed pre-existing via `git stash` against the committed baseline before any 169-02
  changes. Requires an update to `REQUIREMENTS.md`'s milestone header, which is project-state
  bookkeeping outside this plan's task list.
