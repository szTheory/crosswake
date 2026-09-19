---
status: resolved
trigger: "Gate 1 published a companion after a local runbook ancestry check passed, but the runbook commit was not on remote main."
created: 2026-09-19
updated: 2026-09-19T15:40:00-04:00
---

# Remote Runbook Ancestry

## Symptoms

- Expected: before any publish, the incident-runbook commit must be an ancestor of the exact remote merge commit that triggers release.
- Actual: local `git merge-base --is-ancestor d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 HEAD` passed, but after PR #147 merged as `096371e3008d19da775c0d561d092fb3d349b26e`, fetching `origin/main` and comparing the runbook commit to that merge exited 1.
- Error: `runbook-ancestor-exit=1` against the actual remote merge commit.
- Timeline: discovered immediately after the successful Gate 1 publish of `crosswake_rulestead 0.1.1`.
- Reproduction: retain a runbook documentation commit only in local history, then use local `HEAD` as the ancestry target while merging a remote PR.

## Current Focus

- confirmed_root_cause: Gate 1's executable guard checked local `HEAD` instead of an exact fetched remote PR/base/merge commit, and the required runbook commit existed only on the divergent local branch. Those two conditions together allowed the check to pass while the publish-triggering remote merge omitted the runbook entirely.
- bug_class: bohrbug
- reasoning_checkpoint:
    hypothesis: Gate 1 falsely authorized the publish because its executable ancestry guard selected local `HEAD`, not the exact remote commit graph that the PR merge would publish, while the runbook commit was present only on the divergent local branch.
    confirming_evidence:
      - The same runbook SHA is an ancestor of local `HEAD` but not of PR #147's live base, head, or merge SHA.
      - `175-07-PLAN.md` fetches exact `headRefOid` and `baseRefOid` values but its gate, pre-merge recheck, verification, and incident record all execute `merge-base ... HEAD`.
      - The runbook file itself is absent from PR #147's base, head, merge, and current `origin/main` trees.
    falsification_test: The hypothesis would be false if the runbook SHA were reachable from the exact PR base/head/merge despite the local/remote divergence, or if the executable gate already bound its target to one of those exact remote OIDs.
    fix_rationale: Require an explicit 40-character target OID, reject symbolic `HEAD`, verify both objects and the runbook path, and make the remaining publish plans use a freshly fetched remote base before merge plus the exact merge OID afterward; this binds the assertion to the operation it protects.
    blind_spots: A remote branch could advance after the gate; the plan must therefore compare the fetched remote SHA to GitHub's live `baseRefOid` immediately before merge and keep the existing non-BEHIND/head-stability checks. The already-published 0.1.1 artifact cannot be undone, so the record must remain explicitly noncompliant rather than retroactively green.
    candidate_causes:
      - code: the executable guard hardcodes symbolic local `HEAD` instead of accepting the exact remote target OID.
      - config/process: incident-response documentation was committed and validated only on a local branch, with no remote-main reachability gate before the one-way operation.
      - environment: local `main` had diverged 23-ahead/7-behind from `origin/main`, exposing the target-selection defect.
      - data: PR #147's base/head/merge trees contain no `docs/RELEASE-INCIDENT-RESPONSE.md` blob.
    and_gate: yes; the false green requires both the wrong local target and a divergent/local-only runbook commit. Either an exact remote target guard or a remotely landed runbook would have prevented this specific incident.
- next_action: archived; parent agent owns integration and commits.

## Eliminated

- hypothesis: `origin/main` was merely stale locally while the real GitHub merge contained the runbook.
  evidence: live GitHub reports merge `096371e3`, identical to local `origin/main`, and that commit's tree has no incident-response runbook.
  timestamp: 2026-09-19T15:10:00-04:00

- hypothesis: a squash or rebase rewrote the runbook commit but preserved the document in the published tree.
  evidence: the runbook path is absent, not merely rewritten, in PR #147's base, head, merge, and `origin/main` trees.
  timestamp: 2026-09-19T15:10:00-04:00

- hypothesis: the release gate lacked access to exact remote identities.
  evidence: Gate 1 already queries `headRefOid` and `baseRefOid`, and post-merge GitHub exposes `mergeCommit.oid`; the failure is using those values for display but not as the ancestry target.
  timestamp: 2026-09-19T15:10:00-04:00

## Evidence

- timestamp: 2026-09-19T14:54:20-04:00
  checked: `.planning/debug/knowledge-base.md`
  found: no project debug knowledge base exists.
  implication: there is no prior resolved pattern to prioritize; investigate the incident directly.

- timestamp: 2026-09-19T14:54:20-04:00
  checked: spectrum-based fault localization applicability
  found: no failing/passing per-test coverage spectrum exists for this release-process ancestry incident.
  implication: SBFL is skipped; deterministic commit-graph reproduction and working backwards from the published merge are the appropriate Bohrbug route.

- timestamp: 2026-09-19T14:58:00-04:00
  checked: local git reachability for runbook commit `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`
  found: it is an ancestor of local `HEAD` `1d3c152481e3f6b18a54d127c11e73d211d051f6`, but is not an ancestor of `origin/main` or the actual PR #147 merge `096371e3008d19da775c0d561d092fb3d349b26e`; only local branch `main` contains it.
  implication: the reported false pass reproduces deterministically and is explained by selecting a local-only target.

- timestamp: 2026-09-19T14:58:00-04:00
  checked: live PR #147 metadata from GitHub
  found: PR #147 merged at `096371e3008d19da775c0d561d092fb3d349b26e`; GitHub reports base `4627170fffb6688dcb2750c07fae3a18c6d0ee19` and head `491c7a74e2128f7e77c411d50aa22276626c6f51`.
  implication: exact remote identities are available at the gate; a guard need not rely on mutable local `HEAD`.

- timestamp: 2026-09-19T15:03:00-04:00
  checked: Phase 175 Gate 1 implementation in `175-07-PLAN.md` and `175-INCIDENT-DOC-COMMIT.md`
  found: the prose requires checking the commit the leg would publish from, and the task already fetches PR `headRefOid`/`baseRefOid`, but both gate and pre-merge executable commands use `git merge-base --is-ancestor <runbook-sha> HEAD`; the final verification repeats `HEAD`.
  implication: the guard's subject is misbound in code/process, not merely omitted from an operator checklist.

- timestamp: 2026-09-19T15:03:00-04:00
  checked: exact PR #147 base/head/merge reachability
  found: the runbook commit is not an ancestor of base `4627170f`, head `491c7a74`, or merge `096371e3`.
  implication: every remote object relevant to the actual one-way operation refutes the local `HEAD` result.

- timestamp: 2026-09-19T15:03:00-04:00
  checked: local versus remote branch topology
  found: local `main` is 23 commits ahead and 7 behind `origin/main`, with merge base `c0774e29`; the runbook commit lives only on the local side while the companion release and publish-triggering merge live only on the remote side.
  implication: local/remote divergence is the trigger condition that turns the wrong-target check into a false pass.

- timestamp: 2026-09-19T15:14:00-04:00
  checked: new divergent-history regression test before the fix
  found: all three cases are RED because the explicit-target guard does not exist; the fixture also directly proves the old `merge-base <runbook> HEAD` command passes while the sibling remote target excludes the runbook.
  implication: the test reproduces the root-cause mechanism with a specified oracle and is ready to drive the minimal guard implementation.

- timestamp: 2026-09-19T15:31:00-04:00
  checked: focused regression suite after explicit-OID guard implementation
  found: 5 tests pass, covering divergent exact target, reachable exact target, symbolic `HEAD` rejection, deleted-runbook boundary, and active-plan binding to exact remote identities.
  implication: the fix closes the original target-selection path and adjacent path-presence/symbolic-target escape cases.

- timestamp: 2026-09-19T15:36:00-04:00
  checked: exact incident and boundary oracles through `script/check_release_runbook_ancestry.sh`
  found: the real PR #147 merge `096371e3008d19da775c0d561d092fb3d349b26e` fails with `RUNBOOK_NOT_ANCESTOR` and status 1, the exact local containing commit passes with status 0, and symbolic `HEAD` is rejected with `TARGET_OID_INVALID` and status 2.
  implication: the new guard distinguishes the published remote graph from the misleading local graph and cannot regress to the original symbolic-target behavior.

- timestamp: 2026-09-19T15:36:00-04:00
  checked: fix-acceptance target, adjacent, formatting, syntax, and diff checks
  found: the focused plus adjacent ExUnit selection passes 25 tests with 0 failures; `mix format --check-formatted`, `shellcheck`, `bash -n`, `git diff --check`, and the static search for automated `merge-base ... HEAD` commands all pass.
  implication: the guard, its callers, and adjacent release-boundary/config contracts are internally consistent and clean.

- timestamp: 2026-09-19T15:36:00-04:00
  checked: broader planning regression suite
  found: 89 of 90 tests pass; the sole `MilestoneTransitionResetTest` failure rejects an existing `.continue-here.md` breadcrumb already present in the committed `STATE.md` before this fix, and the changed diff does not touch that line.
  implication: the broader failure is pre-existing and unrelated to the remote-OID fix; it is disclosed but does not reject this scoped change.

- timestamp: 2026-09-19T15:36:00-04:00
  checked: revert-and-reconfirm at the guard seam
  found: pointing the regression suite at a missing pre-fix guard makes the focused reproduction fail, then restoring the implemented guard makes all 5 focused tests pass.
  implication: the regression suite is sensitive to the fix rather than passing independently of it.

- timestamp: 2026-09-19T15:36:00-04:00
  checked: mutation tooling availability and change shape
  found: no Stryker or other mutation framework is configured; the change is not deletion-only and adds an executable guard plus direct regression coverage.
  implication: the mutation signal is explicitly skipped under the guardrail policy, while the no-op/deletion signal passes.

## Resolution

root_cause: Gate 1's executable guard checked local `HEAD` instead of an exact fetched remote PR/base/merge commit; simultaneously, the incident-runbook commit existed only on a divergent local branch and was absent from the remote publish graph.
fix: Added an explicit full-OID runbook ancestry guard with path and object validation; rewired remaining Phase 175 gates to fetch/match live remote base/head identities before merge and audit the exact GitHub merge OID afterward; recorded Gate 1 and REL-10 as historically noncompliant across project, roadmap, requirements, state, validation, incident record, and resume context.
verification:
  target_test:
    result: pass
    evidence: 5 focused regression tests pass and the real PR #147 merge reproduces the required fail-closed result.
  mutation_check:
    result: skipped
    reason_if_skipped: no Stryker or other mutation framework is configured in the repository.
    mutant_killed: not_applicable
  no_op_deletion:
    result: pass
    deletion_justified_by_rca: false
  adjacent_tests:
    result: pass
    suites_run:
      - `mix test test/crosswake/proof/phase175_runbook_ancestry_test.exs test/crosswake/planning/release_please_config_test.exs test/crosswake/guides/release_boundaries_test.exs` — 25 tests, 0 failures
      - broader planning suite — 89 of 90 pass; one pre-existing unrelated breadcrumb failure documented in Evidence
  revert_and_reconfirm:
    result: pass
    bug_returned_on_revert: true
    fixed_on_reapply: true
  guardrail_verdict: accepted
files_changed:
  - script/check_release_runbook_ancestry.sh
  - test/crosswake/proof/phase175_runbook_ancestry_test.exs
  - .planning/PROJECT.md
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/ROADMAP.md
  - .planning/workstreams/quality-ratchet-release/STATE.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-10-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-VALIDATION.md
oracle_type: specified — the Phase 175 contract requires the runbook commit to precede the first publish and the bug report specifies ancestry of the exact remote publish-triggering merge.

## Prevention

### Blameless 5-Whys

**Code/process branch**

1. The publish gate returned green because its executable ancestry check targeted local `HEAD`.
2. Local `HEAD` was accepted because the plan described the remote publication contract but did not encode the exact target identity as a required command argument.
3. That mismatch remained possible because the gate and its verification reused the same inline command, so verification repeated rather than independently challenged the target-selection assumption.
4. The assumption was not challenged because no regression fixture modeled a local branch containing the runbook alongside a divergent remote publication branch that omitted it.
5. The actionable condition was the absence of a reusable fail-closed guard and a divergent-history regression test.

**Environment/data branch**

1. The incorrect local check disagreed with the published result because local `main` and the remote PR graph had diverged.
2. The divergence mattered because the runbook commit and file existed only on the local side, while PR #147's base, head, and merge existed on the remote side.
3. The missing remote document was not surfaced because the gate checked commit ancestry only against local state and did not assert that the runbook path existed in the exact target tree.
4. Exact remote identities were available from GitHub, but they were treated as displayed evidence rather than inputs to the guard.
5. The actionable condition was failure to bind both object reachability and path presence to the immutable remote OID used by the one-way operation.

**AND-gate conclusion:** both conditions contributed: the wrong symbolic/local target and a local-only runbook commit. Either exact remote-OID validation or a remotely landed runbook would have prevented this incident; the recurrence guard now enforces both ancestry and target-tree path presence.

### Why Wasn't This Caught?

The existing Phase 175 pre-publish verify gate should have caught this class, but it repeated the same `git merge-base ... HEAD` assumption as the gate it was verifying. No independent test covered divergent local and remote histories, so review, verification, and the command all shared one blind spot.

why_not_caught: The Phase 175 verification gate repeated the production gate's symbolic local `HEAD` target, and no divergent-history regression test existed.

### Recurrence Guard

- `script/check_release_runbook_ancestry.sh` requires immutable full commit OIDs, rejects symbolic `HEAD`, verifies both objects, requires the recorded runbook commit to touch the runbook path, checks ancestry, and requires the path to remain present in the target tree.
- `test/crosswake/proof/phase175_runbook_ancestry_test.exs` covers the original divergent-history false green, a valid containing target, symbolic-target rejection, target-side path deletion, and the remaining plans' use of live base/head/merge identities. The suite passes 5 tests with 0 failures.
- The remaining Phase 175 publish plans invoke the helper against freshly fetched live remote identities before merge and the exact `mergeCommit.oid` after merge; the historical Gate 1 result remains recorded as noncompliant rather than being retroactively greened.

recurrence_guard: Regression test `test/crosswake/proof/phase175_runbook_ancestry_test.exs` plus fail-closed assertion helper `script/check_release_runbook_ancestry.sh`, verified by 5 passing focused tests and 25 passing focused/adjacent tests.
