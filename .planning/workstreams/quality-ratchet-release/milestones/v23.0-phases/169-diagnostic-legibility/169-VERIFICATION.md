---
phase: 169-diagnostic-legibility
verified: 2026-09-25T20:20:42Z
status: passed
score: 38/38 must-haves verified
covered_files:
  - .github/workflows/phase70-proof.yml
  - .github/workflows/maven-publish-fire-drill.yml
  - .github/workflows/release-please.yml
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/ROADMAP.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-UAT.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - script/check_release_workflow_integrity.exs
  - script/check_required_checks_registered.sh
  - script/list_merge_blocking_checks.py
  - script/required_check_policy.json
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase153_1_gate_integrity_test.exs
  - test/crosswake/proof/phase153_ios_mirror_unblock_test.exs
  - test/crosswake/proof/phase168_version_truth_test.exs
  - test/crosswake/proof/phase169_check_name_uniqueness_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase169_exit_contract_guard_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
covered_digest: "v1:sha256:4699f6e6aeeb191a4dd85a5e3980bcf3b69016120e3b110a01c003aa346f639d"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 24
  total: 24
  not_honored: []
---

# Phase 169: Diagnostic Legibility Verification Report

**Phase Goal:** A maintainer reading any release or verification check failure sees that check's own message, and the system never reports “missing” when the true state is “failing” or “never ran.”

**Verified:** 2026-09-25T20:20:42Z
**Status:** passed
**Re-verification:** No — the prior report had no unresolved `gaps:` section, so the initial verification contract applies. The roadmap marked its covered-file fingerprint stale after a later workflow edit; this report checks current code and workflow state.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A deliberately failing release check exposes its own detail, not only missing IDs. | ✓ VERIFIED | The drifted-manifest test runs the scanner, extracts its FAIL detail, then asserts the same string reaches the owner check and `render/1`; the 53-test proof run passed. |
| 2 | Scanner termination and a never-defined required ID are distinct, with the number of completed roster checks reported. | ✓ VERIFIED | Tests inject crashes before ROSTER and after ROSTER, omit DONE, and separately supply an ID outside the declared roster. They assert distinct labels, counts, states, and the never-defined message. |
| 3 | Version-welded check display names are removed, and duplicate producer names fail detection. | ✓ VERIFIED | The proof suite checks the current producer inventory and triggers synthetic duplicate and version-literal inputs. Current Release Please is push-only; the separate Maven rehearsal is dispatch-only, both checked against live workflow files. |
| 4 | A verification command that finds a defect exits differently from one that cannot run. | ✓ VERIFIED | Subprocess tests assert clean=0, defect=1, and unavailable=3, including printed output before process exit. The status command exits 0 on the current clean tree. |
| 5 | Equal failure details remain distinct when IDs differ, and clean owner output has no continuation lines. | ✓ VERIFIED | Owner construction preserves one entry per failing ID; clean and multi-failure tests exercise owner rendering. |
| 6 | Scanner detail passes through byte-for-byte, and multiple failures keep scanner emission order. | ✓ VERIFIED | The drifted-manifest proof compares the captured scanner text with both message and rendered output; ordering fixtures assert repeated output order. |
| 7 | ROSTER/DONE are emitted exactly once around checks, and the DONE count matches emitted OK/FAIL records. | ✓ VERIFIED | The focused suite asserts these cardinalities and counts; direct scanner run exited 0 with `79 of 79` emitted and `0 failed`. |
| 8 | The declared roster is checked against emitted IDs, and legacy OK-line consumers remain compatible. | ✓ VERIFIED | Roster mutation tests force `release.scanner.roster_exact` to fail; scanner source compares extra and missing IDs. Compatibility suite passed Phase 142 and Phase 153 iOS mirror proofs. |
| 9 | Scoped scanner failures report only their own IDs; foreign errors surface through the owner check, and missing plus failing buckets both appear with failing first. | ✓ VERIFIED | Synthetic evidence-map tests cover foreign and own failures, both buckets, roster wording, and stable ordering. |
| 10 | Empty check sets do not pass; error outranks unverifiable, which outranks warning, independent of input order. | ✓ VERIFIED | Named tests cover `aggregate_status([])`, precedence combinations, reverse order, and the exact `exit_code/1` mapping. |
| 11 | Both crash shapes keep scoped checks unverifiable and expose a cascade pointer; no unknown result reads as a pass or leaks the internal atom. | ✓ VERIFIED | Injected crash tests assert all five scoped checks and the owner check, exit 3, cascade wording, and maintainer-facing `UNVERIFIED` label. |
| 12 | The release-status schema and existing fields retain their contract, and live-registry unverifiable remains an error. | ✓ VERIFIED | Focused status tests assert schema `1.2.0`; the 106-test compatibility suite includes release-status task assertions for live-registry behavior. |
| 13 | Duplicate detection covers all literal display names and version literals in job and artifact names; malformed whitespace and empty inventory cannot pass silently. | ✓ VERIFIED | Synthetic collision and job/artifact version fixtures go red. The detector rejects absent workflow files and empty `jobs` maps; its live inventory returns 108 records. Exact string grouping and tab/newline rejection are in the implementation. |
| 14 | The widened detector and six display-name changes landed atomically; required-check policy and branch-protection configuration were not changed by that commit. | ✓ VERIFIED | `git show --stat ae9b6651` shows the two workflow files and detector together; the commit has no policy-file or branch-protection change. Independently parsed parent `ae9b6651^` workflow YAML has one duplicated producer name and five version literals; current mutation fixtures prove both detector classes can go red. |
| 15 | The Python producer failure reaches the shell entry point before any `gh` call; Release Please and Maven use the isolated trigger partition. | ✓ VERIFIED | A shell fixture asserts Python's named duplicate diagnostic is surfaced and `gh` is not invoked. The current-workflow trigger test asserts exact `push` and `workflow_dispatch` maps and synthetic re-coupling fails. |
| 16 | Exit-code guard data matches entry-point source, detects drift, and has a measured non-vacuity floor. | ✓ VERIFIED | Guard tests compare expected and extracted exit-value sets both ways across six entry points, assert a six-entry floor, and mutate a literal to demonstrate failure. |
| 17 | Exit code 2 stays reserved; runbook and source comments point to one canonical exit contract, while runtime output has no legend. | ✓ VERIFIED | `exit_code/1` docs and guard tests pin 0/1/3 and reserved 2. Runbook link and entry-point header assertions pass; output rendering is checked for runtime microcopy only. |
| 18 | `check_release_version_truth.exs` retains BLOCKED exit 2 and the runbook row remains unchanged. | ✓ VERIFIED | Guard extracts its declared 0/1/2 set; the runbook remains linked to the canonical status contract without replacing the separate BLOCKED meaning. |
| 19 | The reconciled UAT retains the old failing observation, resolves G-169-1, and states current trigger ownership. | ✓ VERIFIED | Current `169-UAT.md` preserves the historical failure, marks it resolved by Plan 169-05, retains the trigger partition, and records the fresh 53-test result. |

The roadmap criteria and plan frontmatter contain 38 distinct truths after removing direct restatements. The grouped rows above map all 38 truths to current source inspection or executable proof; no plan truth was dropped from the evaluation.

**Score:** 38/38 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/release_status.ex` | Scanner parsing, scoped diagnostics, owner check, rendering, and exit states | ✓ VERIFIED | Substantive implementation; test suite exercises parser-to-render path and classifications. |
| `script/check_release_workflow_integrity.exs` | Declared roster, full check emission, completion sentinel, and roster drift check | ✓ VERIFIED | 79 declared IDs; current direct run emits all 79, DONE agrees, and mutation proof forces roster guard failure. |
| `lib/mix/tasks/crosswake.release.status.ex` | Printed output and process exit contract | ✓ VERIFIED | Output is printed before exit dispatch; exact 0/1/3 subprocess cases are tested. |
| `script/list_merge_blocking_checks.py`, `script/check_required_checks_registered.sh` | Unique name/version checks and diagnostic propagation | ✓ VERIFIED | Python fixture tests reject duplicate and version-literal inputs; shell test confirms failure before network access. |
| `.github/workflows/release-please.yml`, `.github/workflows/phase70-proof.yml`, `.github/workflows/maven-publish-fire-drill.yml` | Version-neutral names and isolated triggers | ✓ VERIFIED | Current live YAML is parsed by the proof; exact push-only / dispatch-only partition passes. |
| `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | Diagnostic, termination, roster, and exit behavior proof | ✓ VERIFIED | 53 tests, 0 failures. |
| `test/crosswake/proof/phase169_check_name_uniqueness_test.exs`, `phase169_exit_contract_guard_test.exs` | Name/trigger and exit-contract proof | ✓ VERIFIED | Both included in the same 53-test run; active tests include synthetic negative controls. |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | Canonical exit-code reference | ✓ VERIFIED | Links to `Crosswake.ReleaseStatus.exit_code/1`; no copied runtime legend. |
| `169-UAT.md` | Reconciled gap-closure record | ✓ VERIFIED | G-169-1 is resolved; the historical observation remains recorded. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Scanner stdout | `parse_workflow_integrity_output/1` | Existing anchored OK/FAIL regex | ✓ WIRED | ROSTER/DONE lines are ignored by the parser; existing regex is pinned byte-for-byte in the proof. |
| Parsed scanner entries | `workflow_integrity_owner_check/1` → `checks/5` → `render/1` | Ordered entries retain each ID and detail | ✓ WIRED | Drift fixture proves scanner detail appears unmodified in rendered output. |
| Declared `@roster_ids` | Emitted check IDs | `release.scanner.roster_exact` | ✓ WIRED | The guard compares both missing and extra IDs and is included in the scanner's own output roster. |
| `aggregate_status/1` | `exit_code/1` | Explicit status precedence and clauses | ✓ WIRED | Behavioral assertions cover defect, unknown, warning, and empty-list states. |
| `exit_code/1` | Mix task OS process | Case branch and `exit({:shutdown, 3})` | ✓ WIRED | Subprocess tests observe exact exits 0, 1, and 3. |
| Producer inventory | Shell registration check | `python3 ... --producers || { FAIL; exit 1; }` | ✓ WIRED | Duplicate fixture proves named failure surfaces before `gh`. |
| Release Please / Maven fire drill | Trigger partition predicate | Parsed live `on` maps | ✓ WIRED | Current maps and negative re-coupling controls pass. |
| Exit guard table | Each declared verification entry point | File-kind-specific literal extraction | ✓ WIRED | Guard compares both set differences and proves mutation sensitivity. |
| Plan 169-05 test result | G-169-1 UAT status | Reconciled record | ✓ WIRED | Current UAT identifies the closure plan and exact current trigger contract. |

### Data-Flow Trace (Level 4)

N/A — this is a diagnostics, configuration, and proof phase; it does not render dynamic application data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase diagnostics, exit cases, trigger isolation, and drift guards | `MIX_ENV=test mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/crosswake/proof/phase169_check_name_uniqueness_test.exs test/crosswake/proof/phase169_exit_contract_guard_test.exs` | 53 tests, 0 failures; exit 0 | ✓ PASS |
| Release-status, Phase 142/153 compatibility, and Phase 168 version truth | `MIX_ENV=test mix test test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/crosswake/proof/phase168_version_truth_test.exs` | 106 tests, 0 failures; exit 0 | ✓ PASS |
| Live local producer authority | `bash script/check_required_checks_registered.sh --local-only` | 108 literal producers; exit 0 | ✓ PASS |
| Release-status command on current tree | `mix crosswake.release.status` | Exit 0; all checks clean | ✓ PASS |
| Scanner ROSTER/DONE protocol | `elixir script/check_release_workflow_integrity.exs` | 79/79 roster checks emitted, 0 failed; exit 0 | ✓ PASS |
| Empty/malformed producer scope fails closed | Temporary workflow fixtures through `script/list_merge_blocking_checks.py --producers` | No workflow files and empty `jobs` mapping each emit a named failure and non-zero exit | ✓ PASS |

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `phase169_diagnostic_legibility_test.exs` | MSG-01, MSG-02, MSG-03, FID-02 | Yes | 0 | No | Behavioral and exact-value; scanner output is the producer-side input whose preservation is asserted | ✓ Active, relevant assertions passed |
| `phase169_check_name_uniqueness_test.exs` | MSG-06 | Yes | 0 | No | Behavioral/value; independent synthetic YAML negative controls plus live workflow inputs | ✓ Active, relevant assertions passed |
| `phase169_exit_contract_guard_test.exs` | FID-02 | Yes | 0 | No | Exact-value/source mutation | ✓ Active, drift mutation proved the guard can fail |

No disabled requirement-linked test, circular fixture generation, or insufficient assertion level was found. Both the 53-test phase suite and the 106-test compatibility suite passed.

### Decision Coverage

The decision-coverage check found **24/24** trackable CONTEXT.md decisions honored by shipped artifacts, with no uncovered decisions. The gate is warning-only and does not change phase status.

### Probe Execution

N/A — this phase does not declare or imply probe scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| MSG-01 | 169-01 | Failed check exposes its own detail verbatim | ✓ SATISFIED | Drifted-manifest detail reaches rendered output in the focused test. |
| MSG-02 | 169-02 | Early scanner termination is distinct from never-defined IDs | ✓ SATISFIED | Crash and missing-ID fixtures assert distinct wording and counts. |
| MSG-03 | 169-01 | Missing IDs do not shadow failing checks | ✓ SATISFIED | Both-bucket fixture asserts failing-first composition. |
| MSG-06 | 169-03, 169-05, 169-06 | Version-neutral unique names and exact release/rehearsal trigger partition | ✓ SATISFIED | Live inventory, duplicate/version fixtures, current trigger map test, and UAT. |
| FID-02 | 169-02, 169-04 | Defect and could-not-run states use distinct exit statuses | ✓ SATISFIED | Mix subprocess assertions, status tests, and source drift guard. |

All requirement IDs declared by the six PLAN frontmatters are accounted for in `REQUIREMENTS.md`. The phase traceability table maps exactly these five requirements to Phase 169; no orphaned Phase 169 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | 17 | Unused `@scanner` compiler warning in compatibility run | ℹ️ Info | Existing test warning; suite passed and it does not affect Phase 169 behavior. |
| `script/check_required_checks_registered.sh` | 94–102 | Carried-forward WR-01 UAT note about duplicate-check layering | ⚠️ Warning | Python rejects duplicates before network access; current shell block checks registration coverage and is not an independent global duplicate detector. The requirement remains enforced by the Python preflight. |
| `.github/workflows/phase70-proof.yml` | 17 | Carried-forward IN-01 display-name scope wording | ℹ️ Info | Name is unique and version-neutral; UAT notes it omits StoreKit while the job still runs StoreKit advisory checks. No MSG-06 contract failure. |

No unresolved `TBD`, `FIXME`, or `XXX` debt marker was found in phase implementation files. The `XXXXXX` mktemp templates and a workflow string mentioning `_TODO_release_as` are literals, not untracked implementation markers; the latter references the formal `PROOF-03b` work item.

### Human Verification Required

None — infrastructure/proof phase; all acceptance behavior is covered by automated tests or source and artifact inspection.

### Gaps Summary

No blocking gaps remain. The phase goal is achieved in the current tree. Plan 169-05's trigger proof accepts the intentionally isolated Release Please push-only workflow and Maven fire-drill dispatch-only workflow, and Plan 169-06 keeps G-169-1 resolved in UAT. The focused 53-test suite and 106-test compatibility suite pass.

---

_Verified: 2026-09-25T20:20:42Z_
_Verifier: Codex (gsd-verifier)_
