---
phase: 167-documentation-and-pull-request-reconciliation
reviewed: 2026-09-12T19:46:25Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - script/check_phase167_pr_dispositions.py
  - test/js/phase167_pr_dispositions.test.mjs
findings:
  critical: 0
  warning: 5
  info: 0
  total: 5
status: issues_found
---

# Phase 167: Code Review Report

**Reviewed:** 2026-09-12T19:46:25Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Fix commit `5342df62` resolves both blockers from the preceding review. Local reconciliation now hashes each runtime file against the receipt's pinned digest, so the currently drifted runtime state fails closed with exit 1. Closeout resolution now binds the raw baseline bytes to the payload commit and the raw scope bytes to the exact tested closeout-head blob; the new reserialization regression passes.

No blocker remains in the reviewed fix. Five warnings remain: three unchanged warnings from the original Phase 167 review, the unpaginated comment-marker check from the preceding review, and one new test-reliability defect caused by removing the valid local-reconciliation baseline and masking the runtime-file mutation case.

## Prior Finding Resolution

| Finding | Current status | Evidence |
|---|---|---|
| Previous CR-01: runtime hashes were not enforced | Resolved | Lines 1234-1239 hash each target-repository file and compare it directly with the pinned receipt value. The current drifted runtime state now exits 1. |
| Previous CR-02: evidence bytes were not bound to tested history | Resolved | Lines 885-890 bind baseline bytes to the payload Git blob; lines 904-915 bind scope bytes to the tested-head Git blob. The reserialized-scope negative test passes. |
| Original CR-02: impossible `:available` adoption claims | Resolved | Unchanged from the preceding review; exact three-tuple validation remains in place. |
| Original WR-01 through WR-03 | Open | Those files are unchanged from the prior review; the findings are retained below. |
| Previous WR-04: marker pagination | Open | The query still reads only `comments(last:100)` without pagination or a truncation guard. |

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Canonical capability rows still contain tuples rejected by the authority contract

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/lib/crosswake/capability_map.ex:631-645`

**Issue:** `row/1` defaults every row to `:crosswake_contract` and `:repository_bound`, while every `:demoed` row receives `activation_state: :reference_evidence`. That combination contradicts the exact reference tuple enforced for adoption claims, which requires `:reference_host` and `:source_bound`. Canonical rows are not passed through the tuple validator and do not carry the remaining authority fields, so the public capability source still exposes internally inconsistent evidence metadata.

**Fix:** Give rows an explicit coherent row-level proof tuple, or separate capability-row proof posture from adoption-claim authority. Add a semantic canonical-row validator/test rather than vocabulary-only assertions.

### WR-02: CI manifest still publishes the superseded Phase 41 remediation command

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/.github/workflows/crosswake-ci.yml:560-583`; `/Users/jon/projects/crosswake/script/ci_leaf_manifest.json:159-163`

**Issue:** The executable Phase 41 job runs the doctor test, a serialized `phase41_nested_process` partition, and a separately seeded broad suite. The leaf manifest still advertises the old two-command remediation, and an unused environment variable preserves that stale string so parity checks find it. A maintainer following the manifest skips the isolation and deterministic scheduling added after the prior failure.

**Fix:** Put the exact three-command sequence from the job summary in `ci_leaf_manifest.json`, remove `PHASE41_SUPERSEDED_MANIFEST_REMEDIATION`, and make parity inspect executable steps or the explicit remediation summary rather than arbitrary environment text.

### WR-03: Generated support matrix still omits the executable owner of most support facts

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex:19-25`

**Issue:** The generated header names only `Crosswake.CapabilityMap` for first-adopter claim layers. It does not identify `Crosswake.SupportMatrix`, which supplies the rest of the rendered support matrix and is named by contribution guidance as its executable owner.

**Fix:** Render both ownership boundaries explicitly and assert both in renderer tests: `Crosswake.SupportMatrix` owns the support matrix, while `Crosswake.CapabilityMap` owns the embedded first-adopter claim layers.

### WR-04: Exact defer-marker validation ignores comments older than 100 entries

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/script/check_phase167_pr_dispositions.py:1038-1045`; `/Users/jon/projects/crosswake/script/check_phase167_pr_dispositions.py:1070-1084`

**Issue:** The live GraphQL query reads only `comments(last:100)` and treats the returned marker count as complete. A duplicate exact marker older than those 100 comments is invisible, so the required exactly-one-marker invariant can pass incorrectly. The query requests no `pageInfo`, preventing even a fail-closed truncation check.

**Fix:** Paginate comments until exhausted, or at minimum request `pageInfo` and reject any truncated result before evaluating marker cardinality.

### WR-05: Local-reconciliation suite has no valid baseline and masks its runtime-file mutation

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake/test/js/phase167_pr_dispositions.test.mjs:117-133`; `/Users/jon/projects/crosswake/test/js/phase167_pr_dispositions.test.mjs:269-281`; `/Users/jon/projects/crosswake/test/js/phase167_pr_dispositions.test.mjs:348-349`

**Issue:** The shared synthetic repository copies the already-drifted runtime files from the working root, and the former positive-path test was changed to expect that baseline to fail. The suite consequently has no fixture proving that a fully valid local reconciliation can succeed. More specifically, the `runtime file bytes` subtest mutates the config file at lines 348-349, but the repository already fails because other copied runtime bytes differ from the receipt; that subtest remains green even if the validator stops checking the config mutation. The earlier ref, scope, index, and residue cases encounter their checks before the runtime hash gate, but the runtime-boundary coverage and success path are no longer discriminating.

**Fix:** Split fixture setup into two modes. Preserve the drifted-root fixture for the dedicated current-drift regression, but add pinned fixture bytes whose hashes match the receipt. Require the unmodified pinned repository to pass, then mutate one pinned runtime file and require failure so the production success path and each runtime hash check are both exercised.

## Verification Evidence

- `python3 script/check_phase167_pr_dispositions.py --verify-closeout-resolution ...` — passed.
- `python3 script/check_phase167_pr_dispositions.py --verify-closeout-resolution ... --live` — passed with ordinary=7, recovery=4, handoff=5.
- `python3 script/check_phase167_pr_dispositions.py --verify-local-reconciliation ... --scope ...` — exited 1 with `FAIL closed_failure`, as required for the current drifted runtime state.
- `node --test test/js/phase167_pr_dispositions.test.mjs` — 37 tests passed.
- `git diff --check 5342df62^ 5342df62 -- script/check_phase167_pr_dispositions.py test/js/phase167_pr_dispositions.test.mjs` — passed.

---

_Reviewed: 2026-09-12T19:46:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
