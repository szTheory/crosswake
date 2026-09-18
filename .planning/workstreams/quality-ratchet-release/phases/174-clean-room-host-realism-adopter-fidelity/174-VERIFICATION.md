---
phase: 174-clean-room-host-realism-adopter-fidelity
verified: 2026-09-18T15:35:00Z
status: complete
score: 7/7 requirements verified (ROOM-03 closed post-merge by run 35366337182)
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "clean-room-proof-rindle executes against the live published crosswake_rindle 0.1.0 and passes, confirmed by a green CI run, not by code inspection (ROADMAP SC#3 / ROOM-03)"
    status: failed
    reason: "clean-room-proof-rehearsal.yml is a workflow_dispatch workflow that exists only on branch phase-174-clean-room-host-realism, not on the default branch (main). GitHub refuses to dispatch a workflow_dispatch workflow absent from the default branch. The dispatch was genuinely attempted (`gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle`) and refused verbatim (`HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch`), with no run id ever created. A search of the last 60 release-please.yml runs found every clean-room-proof-* job `skipped`, confirming no historical run exists to substitute. No log was fabricated."
    artifacts:
      - path: ".github/workflows/clean-room-proof-rehearsal.yml"
        issue: "Correctly built and reviewed (actionlint clean, roster-parity test green, code review found no critical issues), but not yet on the default branch, so it cannot be dispatched and SC#3's required green CI run cannot exist yet."
    missing:
      - "Merge phase-174-clean-room-host-realism (or its PR) to main."
      - "Re-run: gh workflow run clean-room-proof-rehearsal.yml --ref main -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle"
      - "Read the job-level (not run-level) conclusion: gh run list --workflow=clean-room-proof-rehearsal.yml --limit 1 --json databaseId; gh run view <run-id> --json jobs --jq '.jobs[] | {name, conclusion}'"
      - "Capture the resulting log as evidence/174-rindle-ci-run.log, update 174-CLEANROOM-EVIDENCE.md's SC#3 section with the real run id/conclusion, and tick ROOM-03 in REQUIREMENTS.md."
      - "As a downstream consequence, update 174-CLEANROOM-EVIDENCE.md's SC#4 section with the legacy path's real captured-CI-log step= marker roster (the matrix side is already real: 6 markers from run 35324177344) — SC#4 is presently PARTIALLY MEASURED for the same root cause."
---

# Phase 174: Clean-Room Host Realism & Adopter Fidelity Verification Report

**Phase Goal:** The clean-room proof lane exercises what an adopter actually does — declare a
route, run `mix crosswake.install`, then `doctor` — on both the legacy and matrix code paths,
without weakening `doctor`'s own contract, and the two named high-severity adopter gaps are
closed or explicitly deferred.

**Verified:** 2026-09-18T15:35:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase's own record (`174-NON-VACUITY.md`, `174-CLEANROOM-EVIDENCE.md`) already states this
plainly and this verification independently confirms it by direct inspection: **six of seven
phase requirements are genuinely satisfied; ROOM-03 is not, and the phase must not be read as
fully complete until a post-merge action is taken.** This is not a SUMMARY-only claim — every
item below was checked against the artifact, test file, git history, or a command run during
this verification session, not taken from any SUMMARY's prose.

### Per-Requirement Verdicts (goal-backward, independently checked)

| # | Requirement | Verdict | Deciding artifact / evidence (checked directly) |
|---|---|---|---|
| 1 | **ROOM-01** — legacy host declares a real Crosswake route with capability metadata before `doctor` | ✓ VERIFIED | `script/verify_companion_cleanroom.sh` Step 4 generates a `CleanRoomHost.Router` route carrying `metadata: %{crosswake: [id:, runtime:, offline:, security:]}`; `evidence/174-legacy-rindle-local-run.log` (1042 lines, real run, exit 0) exists and is substantive; `test/crosswake/proof/phase174_cleanroom_host_realism_test.exs` exists on disk (8 tests). |
| 2 | **ROOM-02** — legacy path runs `mix crosswake.install` before `doctor` | ✓ VERIFIED (against ROADMAP SC#2's legacy-path wording; broader unscoped requirement text partially open — stated honestly in 174-NON-VACUITY.md's own preamble) | New Step 6.5 in `script/verify_companion_cleanroom.sh`; the committed log contains `Crosswake install complete for clean_room_crosswake_rindle` before the doctor step. Matrix path deliberately not extended (documented, in-scope decision — ROADMAP SC#2 names the legacy path only). |
| 3 | **ROOM-03** — `clean-room-proof-rindle` executes against live `crosswake_rindle 0.1.0` and passes in CI | ✗ **NOT SATISFIED** | `.github/workflows/clean-room-proof-rehearsal.yml` confirmed to exist only on `phase-174-clean-room-host-realism` (`git log --oneline -- .github/workflows/clean-room-proof-rehearsal.yml` shows commit `b4ffa989`, and `git branch --contains` that commit lists only this feature branch — not `main`). GitHub will not dispatch a `workflow_dispatch` workflow absent from the default branch. Verbatim refusal recorded in `174-CLEANROOM-EVIDENCE.md`: `HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch`. No run id was created; no historical run exists to substitute (all 60 inspected `clean-room-proof-*` jobs are `skipped`). See gap below. |
| 4 | **ROOM-04** — legacy path's `step=` logging reaches grep-able parity with the matrix path | ✓ VERIFIED on the requirement's own terms (nine declared, grep-able markers exist and are asserted); ⚠️ the more specific ROADMAP SC#4 (CI-log-to-CI-log comparison) is **PARTIALLY MEASURED** | `LEGACY_STEP_MARKERS`/`legacy_step_marker()` present in `script/verify_companion_cleanroom.sh`; roster-in-log completeness asserted by the phase174_cleanroom_host_realism_test.exs suite. SC#4's specific method (grep two captured CI logs) has only the matrix side real (`evidence/174-matrix-ci-run.log`, 3124 lines, from run 35324177344, 6 distinct markers); the legacy CI-log side does not exist yet, blocked on the same ROOM-03 dispatch. The phase's own record (Finding A in `174-NON-VACUITY.md`) additionally discloses that the `step=` marker-parity measurement itself is asserted by nothing in `phase174_cleanroom_lane_parity_test.exs` — confirmed true by inspecting that test file's actual assertions (it checks roster equality between `release-please.yml` and the rehearsal workflow, never reads either evidence log). This is disclosed honestly, not hidden. |
| 5 | **ROOM-05** — threadline and sigra clean-room failures each have their own separately recorded root-cause finding | ✓ VERIFIED | `174-FINDING-THREADLINE.md` (107 lines) names a distinct mechanism (pre-174-01 unconditional routeless-router Step 4) from `174-FINDING-SIGRA.md` (134 lines, package-unaware no-engine smoke-test template branch, fixed at commit `d16e475a`). Both rest on real local runs: `evidence/174-threadline-run.log` (785 lines) and `evidence/174-sigra-run.log` (573 lines). `test/crosswake/proof/phase174_companion_findings_test.exs` exists and mechanically checks both findings exist and are not byte-identical, rostered from TODO-011. `REQUIREMENTS.md` line 51 confirms `[x] ROOM-05`. |
| 6 | **ROOM-06** — `doctor`'s `manifest_contract` check source is byte-identical before/after this phase | ✓ VERIFIED (re-run this session) | `bash script/assert_manifest_contract_unchanged.sh` → exit 0, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`, run directly in this verification. `git diff --name-only d04397a4~1..HEAD -- lib/crosswake/doctor/doctor.ex` → empty, run directly in this verification. `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs` present on disk. |
| 7 | **FID-01** — SEED-014's CW-REQ-A/CW-REQ-B closed or explicitly deferred | ✓ VERIFIED | `174-FID-01-DISPOSITION.md`: CW-REQ-A recorded `defer-with-reason` with a stated reopen trigger (commit `16851193`, `git diff --name-only HEAD -- lib/` empty for that commit — confirmed the disposition doc states this, consistent with a docs-only commit). CW-REQ-B closed: `exit_status_for/1`/`handle_result/1` present in `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`, with the `join_reports/3` fix. `grep -c 'CW-REQ-A' 174-FID-01-DISPOSITION.md` = 4, `grep -c 'CW-REQ-B'` = 2 — both non-zero, confirmed directly. |

**Score:** 6/7 requirements verified as satisfied. 1 requirement (ROOM-03) confirmed genuinely NOT
satisfied, with the exact post-merge closing procedure named and unambiguous. The phase's own
NOT-SATISFIED verdict on ROOM-03, and the PARTIALLY-MEASURED verdict on the SC#4 sub-claim, are
both confirmed accurate — not overstated, not understated — by this independent check.

### Confirmation of Orchestrator-Provided Known State (all 4 confirmed true)

1. **ROOM-03 is NOT satisfied.** Confirmed: the workflow file exists only on the feature branch
   (verified via `git branch --contains`), the `HTTP 404` refusal is recorded verbatim in
   `174-CLEANROOM-EVIDENCE.md`, and `REQUIREMENTS.md` line 49 still reads `[ ] ROOM-03` (unticked).
   The traceability table (line 167) names the exact post-merge closing command. Nothing was
   fabricated.

2. **SC#4's marker comparison is half-captured, and the measurement itself is unguarded.**
   Confirmed: `evidence/174-matrix-ci-run.log` is real (3124 lines, from a cited real run id).
   `174-NON-VACUITY.md`'s "Finding A" section explicitly and honestly states that
   `phase174_cleanroom_lane_parity_test.exs` never reads either evidence log, and that the
   orchestrator proved this by moving and then truncating the log file and observing the same
   "6 tests, 0 failures" result both times. This finding is present, undiluted, and not softened
   into a success anywhere in the phase's record.

3. **The 9-test regression is fixed and accurately re-recorded.** Confirmed: commit `b4ffa989`
   changes the rehearsal workflow's job `name:` from an expression-bearing string to the stable
   literal `Clean-room proof rehearsal`. `deferred-items.md`'s "RESOLVED" section states the
   fix plainly, including the fact that 174-05 had initially (incorrectly) called the regression
   pre-existing, and that the orchestrator's control run (removing the new workflow file, watching
   failures drop from 9 to 4) is what settled attribution. `mix test --max-cases 1` run in this
   verification session shows 0 failures (1942 tests total — see discrepancy note below),
   consistent with the fix holding.

4. **Both code-review Warnings are fixed.** Confirmed by reading commit `e7e9b925`'s diff
   directly:
   - WR-02: `exit_status_for/1` now has a true catch-all clause `def exit_status_for(_unrecognised), do: 2` after the `is_binary` clause, and `@spec` widened to `term()`.
   - WR-01: a new test `"a complete, correctly-owned report whose assertions are out of contract order is rejected as incomplete"` reverses the device report and asserts `{:blocked, %{rule_id: "PI-REPORT-COMPLETE"}}`. The commit message documents that this test was proven non-vacuous by mutating the completeness check to sort-by-id (order-insensitive) and observing the suite go red (15 tests, 1 failure), then restoring it green (15 tests, 0 failures) — this is exactly the kind of behavioral, mutation-backed evidence this verification looks for, and it was actually performed per the commit message (not independently re-run in this session, since re-mutating shipped code is out of scope for a read-only verification, but the described mechanism is sound and the described before/after counts are internally consistent with the diff).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `script/verify_companion_cleanroom.sh` | Real route, Step 6.5 installer, LEGACY_STEP_MARKERS | ✓ VERIFIED | Confirmed present; ROOM-01/02/04 evidence log and tests exist |
| `test/crosswake/proof/phase174_cleanroom_host_realism_test.exs` | 8 tests, roster/marker assertions | ✓ VERIFIED | Present on disk |
| `script/assert_manifest_contract_unchanged.sh` | Byte-identity guard for manifest_compile_check/1 | ✓ VERIFIED | Present; ran clean in this session (exit 0) |
| `test/support/fixtures/phase174/manifest_contract_baseline.txt` | Pinned baseline @ 8bc77c35 | ✓ VERIFIED | Referenced correctly by the guard script's successful run |
| `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs` | 5 tests | ✓ VERIFIED | Present on disk |
| `174-FID-01-DISPOSITION.md` | CW-REQ-A/B dispositions | ✓ VERIFIED | Present, grep counts confirmed (4/2) |
| `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` | exit_status_for/1, handle_result/1, catch-all | ✓ VERIFIED | Confirmed via diff of e7e9b925; catch-all present |
| `.github/workflows/clean-room-proof-rehearsal.yml` | Dispatchable rehearsal workflow | ⚠️ ORPHANED (from CI's perspective) | Exists and is well-formed on the feature branch only; not reachable via `workflow_dispatch` until merged to `main` — this is exactly ROOM-03's gap, not a separate defect |
| `test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` | Roster parity, 6 tests | ✓ VERIFIED (as a roster-parity check) / ⚠️ does not assert marker parity from the evidence logs (Finding A, disclosed) | Present on disk |
| `174-FINDING-THREADLINE.md`, `174-FINDING-SIGRA.md` | Distinct root-cause findings | ✓ VERIFIED | 107 and 134 lines respectively, distinct mechanisms cited |
| `test/crosswake/proof/phase174_companion_findings_test.exs` | 7 tests | ✓ VERIFIED | Present on disk |
| `174-NON-VACUITY.md` | Vacuity taxonomy + per-requirement disposition | ✓ VERIFIED | 7-row taxonomy, 3 findings (A, B, C) all present and stated plainly |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `script/verify_companion_cleanroom.sh` Step 4 route | `doctor` manifest check | Step 6.5 install → Step 7 doctor | ✓ WIRED | Confirmed by evidence log line order (install completes before doctor invocation) |
| `.github/workflows/clean-room-proof-rehearsal.yml` | GitHub `workflow_dispatch` API | `gh workflow run` | ✗ **NOT WIRED (blocked by default-branch requirement)** | This is precisely ROOM-03's unmet requirement |
| `test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` | `evidence/174-matrix-ci-run.log` / `evidence/174-legacy-rindle-local-run.log` | assertion reading the logs | ✗ **NOT WIRED** | Confirmed by 174-NON-VACUITY.md's own Finding A and by the test file's actual scope (roster comparison against `release-please.yml`, not log-reading) |
| REQUIREMENTS.md ROOM-05 checkbox | `174-FINDING-THREADLINE.md`/`174-FINDING-SIGRA.md` | traceability row | ✓ WIRED | Confirmed ticked, citing both findings and the mechanical check |
| REQUIREMENTS.md ROOM-03 checkbox | `174-CLEANROOM-EVIDENCE.md` | traceability row | ✓ WIRED (honestly, as unticked) | Confirmed the row states the dispatch refusal and the exact post-merge command, and the checkbox is correctly left `[ ]` |

### Behavioral Spot-Checks / Verification Commands (run directly, unpiped, exit codes read)

| Command | Expected | Observed | Status |
| ------- | -------- | -------- | ------ |
| `mix test --max-cases 1` | 1943 tests, 0 failures | **1942 tests, 0 failures (74 excluded)**, exit 0 | ✓ PASS (0 failures; count differs by 1 from the stated expectation — see note below) |
| `mix format --check-formatted` | exit 0 | exit 0 | ✓ PASS |
| `bash script/assert_manifest_contract_unchanged.sh` | exit 0 | exit 0, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED` | ✓ PASS |
| `git diff --name-only d04397a4~1..HEAD -- lib/crosswake/doctor/doctor.ex` | empty | empty, exit 0 | ✓ PASS |

**Note on the 1942 vs. 1943 discrepancy:** the task's stated expectation was 1943 tests; the
actual observed count in this session was 1942 tests, 0 failures, 74 excluded. This is a minor
count mismatch (off by one), not a failure — 0 failures either way. It is reported here per this
verification's instruction to report actual numbers, not expected ones, and is not treated as a
gap since it does not affect any pass/fail determination and the phase's own SUMMARYs report
varying totals across the phase's timeline (729 in the narrower `test/crosswake/proof` lane, 219
in a `test/mix/tasks`+`test/crosswake/proof_lane` lane, 1942/1943 for the full suite) as new tests
were added plan-by-plan. No evidence of a hidden failure was found.

### Anti-Patterns Found

None of TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER found in the phase's key files
(`script/verify_companion_cleanroom.sh`, `script/assert_manifest_contract_unchanged.sh`,
`lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`,
`.github/workflows/clean-room-proof-rehearsal.yml`) beyond the deliberately-disclosed findings
already covered in 174-NON-VACUITY.md's Finding A/B/C, which are followup-referenced (post-merge
command, commit `b4ffa989`) rather than unresolved markers. No debt-marker gate violation.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| ROOM-01 | 174-01 | Real route + metadata before doctor | ✓ SATISFIED | See table above |
| ROOM-02 | 174-01 | mix crosswake.install before doctor (legacy path) | ✓ SATISFIED (legacy-path scope) | See table above |
| ROOM-03 | 174-04 | clean-room-proof-rindle green in CI | ✗ BLOCKED | Not on default branch; dispatch refused |
| ROOM-04 | 174-01/174-04 | step= marker parity | ✓ SATISFIED (own terms) / ⚠️ SC#4 partially measured | See table above |
| ROOM-05 | 174-05 | Threadline/sigra separate findings | ✓ SATISFIED | See table above |
| ROOM-06 | 174-02 | manifest_contract byte-identical | ✓ SATISFIED | See table above |
| FID-01 | 174-03 | SEED-014 CW-REQ-A/B disposed | ✓ SATISFIED | See table above |

No orphaned requirements found for this phase in REQUIREMENTS.md.

### Human Verification Required

None. Every item in this phase resolves programmatically: ROOM-03's gap is not a judgment call
or a visual/UX check — it is a mechanical fact (the workflow file's absence from the default
branch) with a fully specified, mechanical closing procedure (merge, then re-dispatch, then
capture). No ambiguity requires a human decision beyond executing that already-decided procedure.

### Gaps Summary

Phase 174 achieves six of its seven requirements with genuine, independently-checked evidence —
real runs, real logs, real tests demonstrated to fail under mutation, and two code-review
Warnings closed with verifiable diffs. This is a well-evidenced phase that does **not** overstate
its own completion: its own `174-NON-VACUITY.md` and `174-CLEANROOM-EVIDENCE.md` already state
ROOM-03's non-satisfaction plainly, and this verification confirms that self-assessment is
accurate rather than optimistic.

**The one blocking gap: ROOM-03 (`clean-room-proof-rindle` passes in CI`) is not satisfied.**
`clean-room-proof-rehearsal.yml` cannot be dispatched from a non-default branch — this is a
structural GitHub restriction, not a coding defect, and the phase correctly did not fabricate a
result to paper over it. It closes with a mechanical, already-documented procedure once this
branch (or its PR) merges to `main`:

1. Merge `phase-174-clean-room-host-realism` to `main`.
2. `gh workflow run clean-room-proof-rehearsal.yml --ref main -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle`
3. `gh run list --workflow=clean-room-proof-rehearsal.yml --limit 1 --json databaseId` then `gh run view <run-id> --json jobs --jq '.jobs[] | {name, conclusion}'`
4. Capture the log as `evidence/174-rindle-ci-run.log`, update `174-CLEANROOM-EVIDENCE.md`'s SC#3 (and SC#4's legacy half) sections with the real run id/conclusion, and tick ROOM-03 in `REQUIREMENTS.md`.

**This phase must not be read as complete until that post-merge step is taken and recorded.**
Given ROADMAP's own Phase 174 checkbox is unticked (`- [ ] **Phase 174: ...**` in ROADMAP.md line
34) and REQUIREMENTS.md's ROOM-03 checkbox is unticked, the phase's own governing documents
already agree with this verdict — this VERIFICATION.md formalizes and independently confirms
what the phase record already, honestly, says about itself.

---

_Verified: 2026-09-18T15:35:00Z_
_Verifier: Claude (gsd-verifier)_

## Vacuity Taxonomy

Per `VERIFICATION-CONVENTIONS.md`. The full record — every check this phase landed, each with a
measured non-vacuity fact or an explicit escape form and reason — is in the sibling document
[`174-NON-VACUITY.md`](174-NON-VACUITY.md), which carries its own `## Vacuity Taxonomy` section
plus Findings A, B and C. This section single-sources the verdict; that file holds the detail.

Summary of the phase's non-vacuity evidence:

| Check | Non-vacuity evidence | Shape |
|---|---|---|
| `script/assert_manifest_contract_unchanged.sh` (174-02) | Executed mutations, re-run independently by the orchestrator: byte drift → exit 4, function rename → exit 3, empty source file → exit 3, restore → exit 0. Distinct exit codes for drift vs. extraction-empty. | demonstrated |
| `phase174_cleanroom_host_realism_test.exs` (174-01) | 9 `step=` markers asserted against a real 1042-line run log, roster declared literally in the test rather than grepped from the script under test. | demonstrated |
| `exit_status_for/1` (174-03) | Five separately-named tests, one per outcome; un-shadowed a real bug (`PI-REPORT-OUTCOME` was unreachable dead code). Ordinal-position enforcement proved by a reversed-order test shown red under an order-insensitive mutation (WR-01, commit `e7e9b925`). | demonstrated |
| `phase174_companion_findings_test.exs` (174-05) | Roster derived from TODO-011's failure table, not the findings directory; fixture with one finding removed goes red and names the missing companion. | demonstrated |
| `phase174_cleanroom_lane_parity_test.exs` — roster half (174-04) | Fixture with `clean-room-proof-rindle` deleted goes red and names `crosswake_rindle`. | demonstrated |
| `phase174_cleanroom_lane_parity_test.exs` — SC#4 marker half (174-04) | **None. Unguarded.** The test never reads either evidence log: moving `evidence/174-matrix-ci-run.log` out of the tree, and separately truncating it to zero bytes, both left the suite at 6 tests / 0 failures. The `step=` measurement was performed by hand into `174-CLEANROOM-EVIDENCE.md`. | **escape — see Finding A** |

The escape is deliberate and reasoned, not an omission: the legacy-path CI log cannot be captured
until the rehearsal workflow reaches the default branch (the same root cause as ROOM-03's
NOT-SATISFIED verdict), so a guard added now would go red over a measurement nobody can complete.
Faking red is the same class of error as faking green. Finding A records the gap, the mutation
that exposed it, and the condition that closes it.


## Post-Merge Closure — ROOM-03 and SC#4 (2026-09-18)

This report was written while the phase branch was unmerged, when ROOM-03 could not be satisfied
for a platform reason: GitHub will not dispatch a `workflow_dispatch` workflow absent from the
default branch. That condition no longer holds.

PR #184 merged to `main` as `bb570820`. The dispatch was re-run against `main` and **succeeded**:

| Field | Value |
|---|---|
| Run id | `35366337182` |
| Job | `Clean-room proof rehearsal` |
| Conclusion | `success` (read from the run) |
| Under test | live published `crosswake_rindle 0.1.0` |
| Log | `evidence/174-rindle-ci-run.log` (1270 lines) |

`[crosswake] OK: verify_companion_cleanroom: package=crosswake_rindle version=0.1.0 core_floor=~> 0.2 selected_core=0.2.1 profile=engine-present state=passed`

All nine `step=` markers appear in the declared order, with `step=install` (line 1108) genuinely
before `step=doctor` (line 1234). This also closes code review's IN-01: the `mix crosswake.install`
step added by plan 174-01 had never executed in CI, and now has, successfully.

**SC#4 is also closed by the same run.** Its required method — grep two captured CI logs rather
than read the script — is now possible because the legacy-path log exists:

| Path | Captured log | Distinct `step=` markers |
|---|---|---|
| legacy positional | `evidence/174-rindle-ci-run.log` (run `35366337182`) | 9 |
| matrix | `evidence/174-matrix-ci-run.log` (run `35324177344`) | 6 |

9 >= 6, so the legacy roster's granularity is finer than the matrix roster's. Criterion satisfied
from real logs on both sides.

**Revised verdict: 7/7 requirements satisfied.** The gap this report recorded was real when
recorded and is now closed by observation, not by reinterpretation.
