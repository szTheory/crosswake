# Deferred items — Phase 174 Plan 5

Out-of-scope discoveries logged here per the executor's scope-boundary rule (not fixed, not
investigated further within this plan).

## Pre-existing test failures in `test/crosswake/proof` (unrelated to this plan)

`mix test test/crosswake/proof --max-cases 1` reports **9 failures out of 729 tests** on this
branch. Confirmed pre-existing and unrelated to plan 174-05's changes: checked out the pre-plan
baseline commit (`bdc216b6`, the tip of plan 174-04) into a disposable worktree
(`/tmp/crosswake-baseline-check`, removed after use) and re-ran the same 8 failing test modules
there — **the same 9 failures reproduce at that commit**, before any of this plan's commits exist.

Failing tests (all pre-existing, none touch `174-FINDING-*`, `TODO-011`, or
`phase174_companion_findings_test.exs`):

1. `Crosswake.Proof.Phase153_1GateIntegrityTest` — "every merge-blocking check name is emitted by exactly one job"
2. `Crosswake.Proof.Phase153_1GateIntegrityTest` — "production discovery follows the exact target policy"
3. `Crosswake.Proof.Phase153IosMirrorUnblockTest` — "required-check discovery returns only the target Crosswake CI context"
4. `Crosswake.Proof.Phase165CiPolicyTest` — "manifest, workflow, static needs, and producers have exact parity"
5. `Crosswake.Proof.Phase165EvidenceTest` — "required-check audit binds sole authority to the GitHub Actions app"
6. `Crosswake.Proof.Phase169CheckNameUniquenessTest` — "Task 2: the real tree is clean under both widened assertions"
7. `Crosswake.Proof.Phase135CiOpsProofTest` — "SC5: registration tooling is dry-run-default, parametric, idempotent and detector is fail-closed"
8. `Crosswake.Proof.Phase166RepositoryQualityTest` — "CI authority validator rejects every stage ownership drift mutation"
9. `Crosswake.Proof.Phase164DependencySecurityAndGateAuthorityTest` — "one literal workflow job is the sole dependency-security proof producer"

These are CI-workflow-policy scanning tests (job-manifest parity, check-name uniqueness, gate
authority) that most plausibly drifted from the addition of `.github/workflows/clean-room-proof-
rehearsal.yml` in plan 174-04 (or an earlier phase) — not from anything plan 174-05 touched. Not
investigated further or fixed here per the scope boundary: this plan's own files
(`174-FINDING-THREADLINE.md`, `174-FINDING-SIGRA.md`, the two evidence logs, `TODO-011`'s
addition, and `phase174_companion_findings_test.exs`) are unrelated to any of the nine failing
assertions above, and `mix test test/crosswake/proof/phase174_companion_findings_test.exs
test/crosswake/proof/phase174_cleanroom_host_realism_test.exs
test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs --max-cases 1` — every phase-174 test
this plan or its siblings introduced — is 21 tests, 0 failures.

**Follow-up:** worth a dedicated phase/plan to re-run the full `test/crosswake/proof` suite after
the workflow additions from Phase 174 are reconciled (post-merge), and either fix the 9 pre-
existing failures or file a TODO for whichever plan's workflow change caused the drift.
