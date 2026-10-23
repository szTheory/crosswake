# Deferred Items

- REQUIREMENTS.md header does not name the active milestone "v23.0 Release Pipeline Repair & Proof-Lane Truth"
  status: resolved
  **Resolved:** 2026-10-03. The active `REQUIREMENTS.md` header now names
  "v23.0 Release Pipeline Repair & Proof-Lane Truth". The recorded regressions passed in the
  focused run `MIX_ENV=test mix test
  test/crosswake/planning/milestone_transition_reset_test.exs
  test/crosswake/proof/phase135_ci_ops_proof_test.exs --max-cases 1` (14 tests, 0 failures).
  No code changes were needed; this was completed project-state bookkeeping.
  **Found during:** 169-02's plan-level `mix test` (full suite) verification step.
  **Historical scope:** This was out of scope for 169-02 and confirmed pre-existing at that time;
  it is now closed by the current milestone transition state and regression proof.
