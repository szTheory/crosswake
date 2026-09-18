# Phase 173 Plan 04: Fire-Drill Non-Vacuity Record

This file carries the one observation static fixtures cannot make — whether a real dispatch
of `hex-publish.yml`'s `recovery-fire-drill` operation reports its own job `conclusion` as
`failure`, not `skipped`, when the shared exact-public proof body is reached with a
deliberately absent publication record — plus, per `VERIFICATION-CONVENTIONS.md`, the measured
non-vacuity facts for every check this phase (173-01 through 173-04) landed.

## Task 2/3 — the fire-drill runtime observation

**Status: TAKEN — 2026-09-18.** The dispatch was made against `main` once the phase merged, and
the observation the static fixtures could not make has now been made. It did not go the way the
plan expected on the first attempt, and that is the most important thing this file records.

### The observation, in the order it actually happened

**First dispatch: `startup_failure`, no job at all.** Run
[35299245680](https://github.com/szTheory/crosswake/actions/runs/35299245680), dispatched against
`main` at `91bcb093` immediately after PR #180 merged:

```
Invalid workflow file: .github/workflows/hex-publish.yml#L391
The workflow is not valid. .github/workflows/hex-publish.yml (Line: 391, Col: 3):
Error calling workflow 'szTheory/crosswake/.github/workflows/exact-public-proof.yml@91bcb093'.
The nested job 'record-ledger' is requesting 'contents: write, pull-requests: write',
but is only allowed 'contents: read, pull-requests: none'.
```

`gh run view 35299245680 --json jobs` returned an **empty** job list. This is precisely the shape
criterion 1 below exists to reject: a job list with no proof job in it cannot be read as "the proof
was not skipped", because there was nothing there to skip. Had this file's criteria been written as
"the run concluded `failure`", the run's own top-level `conclusion` of `startup_failure` would have
been close enough to wave through — and a broken workflow would have been recorded as a successful
drill. The per-job criterion is what stopped that.

**The drill found a real defect, not a drill defect.** GitHub validates a called workflow's
nested-job `permissions:` requests against the calling job's grant when the file is **parsed** —
before any `if:` is evaluated, and for every job in the file regardless of which `operation` was
dispatched. So the under-granted `recovery-fire-drill` job did not merely break itself: it
invalidated the whole of `hex-publish.yml`. Verified rather than assumed, by dispatching an
unrelated operation that shares nothing with the drill:

| run | operation | conclusion | jobs |
| --- | --- | --- | --- |
| [35299245680](https://github.com/szTheory/crosswake/actions/runs/35299245680) | `recovery-fire-drill` | `startup_failure` | none |
| [35299415965](https://github.com/szTheory/crosswake/actions/runs/35299415965) | `candidate-rehearsal` | `startup_failure` | none |

**The emergency Hex recovery lane was un-dispatchable on `main` for the entire window between
#180 merging and #181 merging.** No proof body, no rehearsal, no recovery — the whole file was
rejected at parse time. This is the defect the fire drill exists to find, found on its first use,
in the lane that by definition is only reached when something has already gone wrong.

Repaired in PR [#181](https://github.com/szTheory/crosswake/pull/181) (`a2761a55`): the drill job
now grants `contents: write` / `pull-requests: write` as a **ceiling** rather than a use, the shared
proof body gained a `record_verdict` input (default `true`) so a drill appends no row to the release
ledger, and `workflow_test.exs` now **derives** the required caller grant from
`exact-public-proof.yml` instead of hard-coding `contents in ["read", "write"]` — the permissive
literal that let the under-grant ship. See "What the old caller-permission check could not see"
below.

### The dispatch that satisfied the criteria

Run [35302554800](https://github.com/szTheory/crosswake/actions/runs/35302554800), dispatched
against `main` at `a2761a55`:

```bash
gh workflow run hex-publish.yml --ref main \
  -f operation=recovery-fire-drill \
  -f package=crosswake \
  -f release_version=0.2.1 \
  -f approved_head=a2761a55ca67d1ac437028d22b2f35b2529770fa \
  -f merge_oid=a2761a55ca67d1ac437028d22b2f35b2529770fa \
  -f candidate_receipt_run_id=0
```

`gh run view 35302554800 --json jobs --jq '.jobs[] | {name, conclusion}'`, verbatim:

```json
{"conclusion":"failure","name":"fire drill: recovery proof fails closed on a missing record / shared: exact-public artifact proof body"}
{"conclusion":"skipped","name":"Rehearse exact six-package Hex candidate"}
{"conclusion":"skipped","name":"recovery: exact-public artifact proof"}
{"conclusion":"skipped","name":"Recover Hex package"}
{"conclusion":"skipped","name":"Recover approved Android core from exact merge"}
{"conclusion":"skipped","name":"fire drill: recovery proof fails closed on a missing record / shared: record the proof verdict in the release ledger"}
```

Against the five criteria stated further down this section:

1. **Present, not absent.** The proof job appears under the caller's composite name
   `fire drill: ... / shared: exact-public artifact proof body`, exactly the child-job shape the
   criterion anticipated for a pure `uses:` call. Contrast the first dispatch, where the list was
   empty — the criterion discriminated between the two.
2. **`conclusion` reads `failure`.** ✓
3. **`conclusion` does not read `skipped`.** ✓ — and the same job list shows five jobs that DID
   read `skipped`, so the value is not a constant in this run.
4. **`publish` never executed.** `Recover Hex package` is `skipped`. No `needs:` edge reaches it
   from the drill, and its `if:` gates on `operation == 'recovery'`.
5. **The failing step names the missing-record condition**, quoted from the run log:

```
[crosswake] no artifact named publication-record-crosswake-a2761a55ca67d1ac437028d22b2f35b2529770fa was uploaded by run 35302554800; the assertion step decides what that means.
[crosswake] FAIL: PUBLICATION_RECORD_MISSING: no publication record at '/home/runner/work/_temp/publication-record/publication-record.json' for package 'crosswake', version '0.2.1', approved_head 'a2761a55ca67d1ac437028d22b2f35b2529770fa'.
[crosswake] What to do next: confirm the publish job for that coordinate ran and uploaded its publication-record artifact; a publish that left no record is not provably a publish.
##[error]Process completed with exit code 4.
```

The proof body reached its applicability decision first and answered `true` —
`[crosswake] OK: exact-public proof applies to crosswake@0.2.1 (lane recovery, head a2761a55...)` —
so the failure is the record assertion firing, not the lane gate refusing to start. Exit code 4 is
`assert_publication_record.sh`'s MISSING branch, distinct from a generic non-zero exit.

**Two further facts the run establishes, neither of which a static fixture could:**

- **The write ceiling is a ceiling, not a use.** The proof body job's own token, as GitHub logged it
  at job start, was `Actions: read` / `Contents: read` / `Metadata: read`. The `contents: write` the
  caller job declares never reached the job that runs the proof.
- **No drill row entered the release ledger.** `shared: record the proof verdict in the release
  ledger` is `skipped`, which is the `record_verdict: false` gate working. A drill is not a release,
  and the ledger is the copy of record.

### What the old caller-permission check could not see

`workflow_test.exs`'s caller check asserted `contents_grant in ["read", "write"]`, reasoning that
the shared proof body only reads while the ledger job writes, so either value is legitimate. The
reasoning is true and irrelevant. Because GitHub validates **every** nested job's request against
the caller's grant at parse time, the binding requirement on a caller is the scope-wise **maximum**
over the called file's jobs — `contents: read` is never sufficient once `record-ledger` exists in
that file. A check that accepts a value the platform rejects is a check that reports green on a
workflow that cannot start.

This is the SEED-019 shape one level up: the requirement was written down as a literal beside the
thing it polices, so a job added to the called file outran it silently. The check now reads
`exact-public-proof.yml` and derives the requirement, so the next job added there raises the bar
automatically. Mutation-verified in both directions — restoring `contents: read` on a caller fails
with `.github/workflows/hex-publish.yml job recovery-exact-public-proof grants contents: "read", but
.github/workflows/exact-public-proof.yml has a job requesting contents: write.`; renaming the drill's
`record_verdict: false` fails the opt-out roster assertion; reverting each restored green.

### Original Case-B reasoning, retained

The reasoning below is kept as written, because it correctly predicted why no dispatch was possible
before merge. It is history now, not status.

**Status at the time of Plan 04's execution: PENDING.** No `workflow_dispatch` of
`recovery-fire-drill` was attempted in that execution session — this was Case B of Task 3's
checkpoint, but for a reason distinct from the platform-refusal case the plan names.

### Why this is Case B, and why the reason differs from the plan's anticipated one

**The binding reason is structural, and it is exactly what the plan's Task 2d anticipated:**
`operation` is a `type: choice` input, and GitHub validates a `workflow_dispatch` call's choice-input
*values* against the workflow definition on the **default branch**, not against the definition at the
dispatched ref — even though the run itself, once accepted, executes the file at the named ref.
`recovery-fire-drill` is a new option this plan's Task 1 added; it is not present in `main`'s
definition of `hex-publish.yml`. Verified directly, contrasting the two option lists:

```
$ git show origin/main:.github/workflows/hex-publish.yml | sed -n '/operation:/,/package:/p'
      operation:
        description: 'Rehearse the exact candidate or recover one immutable registry coordinate.'
        ...
        options:
          - candidate-rehearsal
          - recovery
          - android-recovery
      package:

$ sed -n '/operation:/,/package:/p' .github/workflows/hex-publish.yml
      operation:
        description: 'Rehearse the exact candidate, recover one immutable registry coordinate, or fire-drill the recovery proof with no record and no credential.'
        ...
        options:
          - candidate-rehearsal
          - recovery
          - android-recovery
          - recovery-fire-drill
      package:
```

`main` has three options; this branch has four. Dispatching `operation=recovery-fire-drill` at ANY
ref — branch-scoped or not — would be rejected by GitHub's own input validation against `main`'s
definition, because the value does not appear in the accepted set there. This is not a consequence of
anything this session did or declined to do: **the live observation is structurally post-merge-only**,
regardless of push policy. This is the exact shape Task 2d names: "GitHub refuses the branch-scoped
dispatch because the new operation option is not yet present on the default branch."

**A second, incidental reason also applied in this session, and is recorded for completeness but is
not the binding one:** this execution session additionally operated under an explicit governing
constraint —

> "Do NOT push, do NOT open a PR. I handle the single phase PR at the end."

— issued because Phase 173 lands as ONE pull request covering 173-01 through 173-04 together (the
`<atomicity_constraint>` all four plans carry), opened by the requesting maintainer after this plan
closes, not by the executor mid-phase. Verified before writing this section:

```
$ git rev-parse HEAD
567f717688b1cf4eff4ccd9def31acecc57b3c96
$ git ls-remote origin refs/heads/gsd/phase-173-recovery-path-proof-convergence
(no output — the branch does not exist on the remote)
```

The branch was never pushed, so no `workflow_dispatch` API call was attempted at all in this session
— but even had the branch been pushed, the choice-input validation above would have refused the call
on `operation=recovery-fire-drill` regardless. The push constraint changes *whether an attempt was
made*; it does not change *whether an attempt could have succeeded*. Both facts are recorded, and
neither is allowed to stand in for the other: **an unattempted dispatch, a structurally-impossible
dispatch, and a rejected dispatch are three distinct facts**, and collapsing any two of them would
itself be the vacuity this phase exists to remove. No static assertion is presented anywhere in this
file as a substitute for the runtime observation the plan asks for.

### What must happen next, and who

Once this phase's pull request (covering 173-01 through 173-04) merges to `main`, the
`recovery-fire-drill` operation exists on the default branch and a `workflow_dispatch` can resolve
it. At that point, **a maintainer with dispatch permission on `szTheory/crosswake`** (the phase's
executing maintainer, Jon) must run:

```bash
gh workflow run hex-publish.yml \
  --ref main \
  -f operation=recovery-fire-drill \
  -f package=crosswake \
  -f release_version=0.2.1 \
  -f approved_head=<40-hex commit for which no publication-record-crosswake-<head> artifact exists> \
  -f merge_oid=<any 40-hex commit SHA, e.g. the same value as approved_head> \
  -f candidate_receipt_run_id=<any non-empty value; the drill fails at the record assertion, before this input is read>
```

Then read back the per-job conclusion — not the run's overall summary — with:

```bash
run_id=$(gh run list --workflow hex-publish.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view "$run_id" --json jobs --jq '.jobs[] | {name, conclusion}'
```

The criterion is satisfied when:
1. A job named `fire drill: recovery proof fails closed on a missing record` (or the caller's own
   composite name, since this job is a pure `uses:` call into
   `.github/workflows/exact-public-proof.yml` — GitHub Actions surfaces the reusable workflow's own
   internal job as a child under the caller) is **present** in the job list (not absent — an absent
   job would make a "not skipped" claim vacuously true).
2. That job's `conclusion` reads `failure`.
3. That job's `conclusion` does **not** read `skipped`.
4. The run's job list confirms the `publish` job was never executed (it carries no `needs:` edge from
   `recovery-fire-drill`, and `recovery-fire-drill`'s `if:` gates on `operation == 'recovery-fire-drill'`
   only, so `publish`, gated on `operation == 'recovery'`, cannot appear for this dispatch).
5. The failing step's logged message names the missing-record condition — expected text from
   `script/assert_publication_record.sh`'s `MISSING` branch, e.g. `PUBLICATION_RECORD_MISSING` or
   equivalent record-not-found wording, quoted verbatim from `gh run view --log` once available.

**This instruction has been discharged.** It was carried out on 2026-09-18 across two dispatches
(35299245680, then 35302554800 after the defect the first one exposed was repaired); the run URLs,
run ids, quoted per-job conclusions, quoted record-missing message and confirmed job list are
recorded in "The observation, in the order it actually happened" at the top of this section, and
ROADMAP Success Criterion 2 for Phase 173 is satisfied by that record. The bar it set — that no
phase-close verifier may read this file as satisfying SC2 on the strength of the static fixtures
landed in Task 1 alone — was the right bar, and it held: the first dispatch returned an empty job
list, which only a per-job criterion could tell apart from a passing drill.

### What Task 1's static fixtures already prove, and what they cannot

`test/crosswake/proof/phase173_recovery_proof_convergence_test.exs` and
`script/check_release_workflow_integrity.exs`'s `release.recovery.fire_drill_shares_proof_body`
check prove, hermetically and on every pull request, that:

- The drill's `uses:` reference is byte-identical to the recovery lane's own caller job's `uses:`
  reference (so a real run of the drill exercises the SAME reusable workflow file the real recovery
  lane reaches, not a private copy).
- The drill job reads no registry credential (`HEX_API_KEY` does not appear in its block).
- The drill job never invokes `script/guarded_hex_publish.sh`.
- The drill job carries no `needs:` edge on the `publish` job.

None of this can demonstrate what GitHub's own scheduler *reports* as the job's `conclusion` when
the shared proof body's record-assertion step fails — that is runtime behavior decided by the
platform, not something a text-reading Elixir script can execute. That is exactly the boundary
`173-RESEARCH.md` §F describes, and exactly why this section exists as a separate, explicitly-pending
fact rather than being folded into Task 1's already-green fixtures.

---

## Task 4 — the phase's measured non-vacuity ledger

The six vacuity shapes (`A`-`F`) referenced below are defined at
[`.planning/research/v23/PITFALLS.md`](../../../research/v23/PITFALLS.md) §"Pitfall 4" and are not
restated here, per `VERIFICATION-CONVENTIONS.md`'s link-never-copy rule.

### Scope and counts

**"Check landed" is defined mechanically for this phase, since 173-01/02/03 carry no `coverage:`
frontmatter enumeration (unlike Phase 172's summaries):** a check landed by this phase is every new
ExUnit `test` this phase's diff added, PLUS every new checker-predicate ID this phase's diff added to
`script/check_release_workflow_integrity.exs`'s `@roster_ids`. Both categories are counted, even where
a predicate's own non-vacuity evidence IS a set of fixture tests already counted separately — the
predicate's real-tree `OK:` line and the fixture-driven `mix test` run are two distinct verification
instruments (one hermetic-CI text scan, one `mix test` process), and the plan's own wording ("every new
or extended test... plus each new checker predicate") calls for both.

Measured directly against `git diff <plan_head_before>..<plan HEAD>` for each plan:

| Plan | New tests | New checker predicates | Total |
|---|---|---|---|
| 173-01 | 21 (`test/crosswake/release_candidate/publication_record_test.exs`: 17; `test/crosswake/release_candidate/workflow_test.exs`: 4) | 0 | **21** |
| 173-02 | 11 (`test/crosswake/proof/phase173_recovery_proof_convergence_test.exs`) | 3 (`release.recovery.publication_record_identical`, `release.recovery.proof_record_fails_closed`, `release.recovery.proof_applicability_lane_gated`) | **14** |
| 173-03 | 13 (`test/crosswake/release_candidate/workflow_test.exs`: 4; `test/crosswake/release_candidate/release_ledger_test.exs`: 9) | 0 | **13** |
| 173-04 | 2 (`test/crosswake/proof/phase173_recovery_proof_convergence_test.exs`, this plan's own additions) | 1 (`release.recovery.fire_drill_shares_proof_body`) | **3** |
| **Total** | **47** | **4** | **51** |

Measured counts (not narrated):

```
$ git diff 2cc7d9431d3806cb4d3bf09fc55fe7e3b250f5b6..64fe2b7e -- test/crosswake/release_candidate/publication_record_test.exs | grep -c '  test "'
17
$ git diff 2cc7d9431d3806cb4d3bf09fc55fe7e3b250f5b6..64fe2b7e -- test/crosswake/release_candidate/workflow_test.exs | grep -c '^\+.*test "'
4
$ git show ee032ad0:test/crosswake/proof/phase173_recovery_proof_convergence_test.exs | grep -c '  test "'
11
$ git diff ee032ad0..5132e9ca -- test/crosswake/release_candidate/workflow_test.exs | grep -c '^\+.*test "'
4
$ grep -c '  test "' test/crosswake/release_candidate/release_ledger_test.exs
9
$ grep -c '  test "' test/crosswake/proof/phase173_recovery_proof_convergence_test.exs   # current tree, includes this plan's 2
13
```

**27** of the 51 checks carry a mutation demonstrated red — recorded in the originating plan's own
execution, or reproduced independently in this plan's execution window (the two 173-04 fixtures). The
remaining **24** are named, with a reason, in "Checks landed with no mutation run" below.
`21 + 14 + 13 + 3 = 51 = 27 + 24` is the checkable equality this ledger's reconciliation section
restates with the per-plan breakdown.

### Mutation-backed rows

| # | Check ID (plan / module # test name, exact) | Shape | Mutation applied | Observed output (quoted) | Commit |
|---|---|---|---|---|---|
| 1 | 173-01 `Crosswake.ReleaseCandidate.PublicationRecordTest` # `"reports mismatch when only the version differs"` + `"reports mismatch when only the approved head differs"` (+2 secondary: `"the three rejection classes carry distinct exit codes"`, `"the emitter's real output fails against a different version"`) | escape: matches none of A-F, because it is a deliberate single-field-comparison correctness assertion over a fixed-arity script argument set, not a predicate over a runtime-derived possibly-empty collection, a `needs:`/`if:`/matrix condition, or a shell exit-code-misuse idiom itself. | Both single-field comparisons in `script/assert_publication_record.sh` neutered to `if false` (plan-required mutation). | `17 tests, 4 failures` / `1) test assert_publication_record.sh reports mismatch when only the version differs` / `Assertion with != failed, both sides are exactly equal` / `code: assert code != 0` / `left: 0` / `2) test ... reports mismatch when only the approved head differs` (same shape), plus the distinct-exit-code test and the emitter round-trip mismatch test. Reverted -> `17 tests, 0 failures`. | `9293f6f2` |
| 2 | 173-01 `Crosswake.ReleaseCandidate.PublicationRecordTest` # `"reports record-missing when no record file exists at all"` | escape: same reasoning as row 1. | The missing-record branch's `exit 4` changed to `exit 0` (plan-required mutation). | `17 tests, 2 failures` / `1) test ... reports record-missing when no record file exists at all` / `Assertion with != failed, both sides are exactly equal` / `code: assert code != 0` / `left: 0`. Reverted -> `17/0`. | `9293f6f2` |
| 3 | 173-01 `Crosswake.ReleaseCandidate.WorkflowTest` # `"every caller of the reusable exact-public proof grants actions: read at job level"` (later EXTENDED in place by 173-03 to a by-value, not by-substring, comparison, and by 173-04 to a three-entry declared caller roster — same check, same test name, not a second or third check) | escape: matches none of A-F, because it is a static-source-text assertion over a workflow file's own `permissions:` block plus a declared-roster equality check, mutated at the classifier layer, not a runtime collection/needs-if-matrix/shell-exit-code idiom itself. | 173-01: a caller job's `permissions:` block (granting `actions: read`) deleted from the fixture. 173-03 (same test, extended assertion): `pull-requests: write` removed from `release-please.yml`'s `exact-public-proof` caller job, to prove the new by-value `contents:`/`pull-requests:` conjunct is not vacuous. 173-04: this test's own declared 2-entry caller roster was NOT extended when Task 1 added `recovery-fire-drill` as a third, legitimate caller of the same reusable workflow — the real tree itself became the mutation, with no fixture required. | 173-01: `actionlint` still exited `0`. `workflow_test.exs` failed: `.github/workflows/release-please.yml job exact-public-proof declares no job-level permissions block`. Reverted -> green. This is the row that also surfaced 173-01's own vacuity defect: the FIRST draft of this assertion matched a YAML **comment** beside the caller job (the explanatory prose contains the strings `permissions:` and `actions: read`); fixed by stripping full-line comments before asserting, mirroring `check_release_workflow_integrity.exs`'s own `strip_full_line_comments/1`. 173-03: `1) test every caller of the reusable exact-public proof grants actions: read at job level` / `.github/workflows/release-please.yml job exact-public-proof grants contents: write without pull-requests: write; the ledger job needs both or neither`. Reverted -> green. This mutation also caught that 173-02's OWN negative control (a different test, in the phase173 fixture module) had become a no-op after 173-03 changed the literal it mutated; `Fixtures.replace_in_job/4`'s raise-on-no-op guard caught it and the control was re-aimed rather than deleted (`2d4f73f9`). 173-04 (real defect, not a synthetic fixture): `1) test every caller of the reusable exact-public proof grants actions: read at job level (Crosswake.ReleaseCandidate.WorkflowTest)` / `Assertion with == failed` / `left: [..., {".github/workflows/hex-publish.yml", "recovery-fire-drill"}, ...]` (3 entries) / `right: [...]` (the old, now-stale, 2-entry literal). This is the check doing exactly its declared job: catching a caller roster that changed without the declared expectation changing with it — the SEED-019 shape this test itself exists to prevent, caught by this test against a REAL change rather than a synthetic mutation. Fixed by adding `{@hex_workflow, "recovery-fire-drill"}` to the expected roster; re-run -> `23 tests, 0 failures`. | `64fe2b7e` (173-01), `2327ba0e` (173-03 extension), `08c19383` (173-04 extension) |
| 4 | 173-01 `Crosswake.ReleaseCandidate.WorkflowTest` # `"both publish lanes emit one publication record through the one shared emitter"` | escape: same reasoning as row 3. | The recovery lane's emitter invocation flag order swapped (`--lane` moved before `--ref`). | `actionlint` exited `0`; `workflow_test.exs` failed on the flag-order assertion in this test. Reverted -> green. | `64fe2b7e` |
| 5 | 173-02 `release.recovery.publication_record_identical` (checker predicate) + its 4 fixture tests in `Crosswake.Proof.Phase173RecoveryProofConvergenceTest` (ordinary-lane step removed; recovery-lane step removed **+ control asserted green**; two callers naming different reusable workflows; caller loses `actions: read`) | escape: matches none of A-F, because the predicate compares two structurally-equal-by-declaration references (a `uses:` path, an argument-flag sequence) as EQUAL STRINGS against one declared constant — an identity/equality property, not a collection-emptiness, needs-skip, or shell-exit-code shape. | (a) the check itself weakened to a single presence-only conjunct ("is the emitter script name mentioned anywhere"); (b) the declared `@proof_lanes` roster replaced by a scan filtering to lanes whose publish job already mentions the emitter — both plan-required mutations, applied to `script/check_release_workflow_integrity.exs` directly. | (a): `11 tests, 4 failures` — the ordinary-removal, recovery-removal+control, different-paths, and actions:read-drop fixtures all failed, because a lane-agnostic presence check reports green on a tree where only one lane stopped emitting a record. (b): `11 tests, 2 failures`, with the scanner's own green line reading `[crosswake] OK: release.recovery.publication_record_identical - all 1 declared lanes (recovery)` / `... all 1 declared lanes (ordinary)` — the roster shrank to one lane and reported green about a tree where the OTHER lane had stopped emitting a record (T-173-06/SEED-019 demonstrated, not merely asserted). Reverted both times; checker byte-identical (`git diff --stat` empty). | `f5d0175c` (checker), `a15c4f12` (fixtures) |
| 6 | 173-02 `release.recovery.proof_record_fails_closed` (checker predicate) + its 4 fixture tests (job `if:` gating on an upstream result; assertion swallowed via `continue-on-error: true`; assertion swallowed via `\|\| true`; expected version read out of the record; a record-derived value added ALONGSIDE the input-derived ones) | Also B (a job-level `if:` that can silently gate on an upstream `needs.*.result`, reproducing the skip-instead-of-fail shape XPUB-05 exists to close). | `Fixtures.replace_in_job`/`Fixtures.run_fixture_set` mutations of `.github/workflows/exact-public-proof.yml`: `if: ${{ always() }}` -> `if: ${{ needs.publish.result == 'success' }}`; `continue-on-error: true` added to the record-assertion step; `\|\| true` appended to the assertion command; `VERSION: ${{ inputs.version }}` -> `VERSION: ${{ steps.record.outputs.version }}`; a record-derived `VERSION:` assignment added beside the existing input-sourced ones. | Each fixture individually asserted `exit_code == 1` and `output =~ "[crosswake] FAIL: release.recovery.proof_record_fails_closed"` — reproduced by re-running `mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` this session: `13 tests, 0 failures` (all internal red/green assertions held). | `a15c4f12` |
| 7 | 173-02 `release.recovery.proof_applicability_lane_gated` (checker predicate) + its 2 fixture tests (the un-laned branch restored **+ control asserted green**; the lane validated only AFTER the branch that exits zero on it) — plus the orchestrator's own root-cause finding | Also B (the exact shape: a job reaching a "not applicable, exit 0" branch when it should have failed, indistinguishable downstream from a legitimate skip). | The root-cause mutation, applied and measured directly by extracting and executing the applicability step's `run:` body: recovery lane, `approved_head` and `merge_oid` both empty. | **Before** (`ca23ffcb`): `exit 0`, `GITHUB_OUTPUT` = `applicable=false` — a real recovery publish concludes the proof job `success` having proved nothing. **After** (the fix): `exit 1`, with `[crosswake] FAIL: PROOF_APPLICABILITY_UNDETERMINED - the recovery lane reached the exact-public proof with neither an approved head nor a merge oid.` Table also confirms the ordinary lane (empty/empty) is unaffected (`exit 0, applicable=false` both before and after) and a bogus lane is rejected both before and after. Fixture-level mutations (un-laned branch restored; lane validated too late) both independently reproduced `[crosswake] FAIL: release.recovery.proof_applicability_lane_gated` against an unmutated-control green in the same test body. | `8c3f60dd` (fix), `a15c4f12` (fixtures) |
| 8 | 173-03 `Crosswake.ReleaseCandidate.ReleaseLedgerTest` # `"every non-comment line parses as JSON and carries exactly the required key set"` | escape: matches none of A-F, because it is a cardinality-pinned collection assertion over a bounded, real committed file (`count(conforming) == count(all)`, both counts stated), not an `Enum.all?`/`Enum.any?` scored true on an empty runtime collection. | `lane` key removed from the first data line of a scratch copy of `docs/release-ledger/RELEASE-LEDGER.jsonl`. | `9 tests, 1 failure` / `1 of 3 ledger lines are not JSON objects carrying exactly ["approved_head", "lane", "outcome", "package", "recorded_at", "ref", "run_id", "schema_version", "version"]`. Reverted from the scratch copy; `git status --porcelain` on the real ledger returned empty afterward. | `20c8bd32` |
| 9 | 173-03 `Crosswake.ReleaseCandidate.ReleaseLedgerTest` # `"appending the same run twice leaves one line"` + `"an earlier line is never rewritten by a later append"` + `"a failing verdict is written as faithfully as a passing one"` | escape: same reasoning as row 8 (behavioral/count assertions over the script's real output, not a collection-emptiness or needs/if/matrix shape). | `script/append_release_ledger.sh`'s writer changed from append (`>>`) to overwrite (`>`). | `9 tests, 3 failures`: `1) ... appending the same run twice leaves one line  left: 1  right: 2` / `2) ... an earlier line is never rewritten by a later append  left: 1  right: 2` / `3) ... a failing verdict is written as faithfully as a passing one  left: 1  right: 4`. Reverted -> `9/0`. | `20c8bd32` |
| 10 | 173-04 `release.recovery.fire_drill_shares_proof_body` (checker predicate) + its 2 fixture tests in `Crosswake.Proof.Phase173RecoveryProofConvergenceTest` (drill naming a different reusable workflow **+ control asserted green**; drill gaining a credentialed publish step **+ control asserted green**) | escape: same reasoning as row 5 (an identity/equality-of-reference check, plus a positive assertion of absence for the credential/helper-invocation conjuncts). | (a) `HEX_PUBLISH_WORKFLOW_PATH` fixture with `recovery-fire-drill`'s `uses: ./.github/workflows/exact-public-proof.yml` replaced by `uses: ./.github/workflows/exact-public-proof-drill.yml`; (b) the same job's `uses:` line followed by an injected `env: HEX_API_KEY: ${{ secrets.HEX_API_KEY }}` and a line naming `script/guarded_hex_publish.sh`. Independently reproduced this session against the real `check_release_workflow_integrity.exs`, outside the `mix test` process, via a standalone Elixir fixture script and the `HEX_PUBLISH_WORKFLOW_PATH` env override. | (a): `[crosswake] FAIL: release.recovery.fire_drill_shares_proof_body - job recovery-fire-drill must reach the proof through a uses: value character-identical to job recovery-exact-public-proof's, found "./.github/workflows/exact-public-proof-drill.yml" vs "./.github/workflows/exact-public-proof.yml"` / `DONE: 73 of 73 roster checks emitted; 1 failed.` (b): `[crosswake] FAIL: release.recovery.fire_drill_shares_proof_body - job recovery-fire-drill must read no registry credential; HEX_API_KEY was found referenced in it \| job recovery-fire-drill must never invoke script/guarded_hex_publish.sh` / `DONE: 73 of 73 roster checks emitted; 1 failed.` Both fixtures were built and run against temp files under `/tmp`; the tracked `.github/workflows/hex-publish.yml` and `script/check_release_workflow_integrity.exs` were never touched (`git status --short` confirmed clean before and after). The paired unmutated-control assertions inside the two `mix test` fixture tests themselves independently confirmed `[crosswake] OK: release.recovery.fire_drill_shares_proof_body` against the real tree (`mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` -> `13 tests, 0 failures`). | `567f7176` |

### Checks landed with no mutation run

The following **24** checks were landed by this phase without an individually-run, independently
recorded mutation. None is silently omitted; each carries its own reason, grouped by why no mutation
was run. `27` (rows above, counting bundled tests+predicates) `+ 24` (below) `= 51`.

**Group T — 173-01's `publication_record_test.exs`, exercised by the TDD RED-to-GREEN cycle but not
individually re-mutated beyond rows 1-2 above (12 checks).** Every test in this group is real, was
part of the intentional RED (`17 tests, 17 failures`, every failure
`bash: script/write_publication_record.sh: No such file or directory` — before either script existed)
and the subsequent GREEN (`17 tests, 0 failures`, per 173-01-SUMMARY.md's "TDD (Task 1)" section), and
is exercised on every `mix test` run since.

- `"writes exactly the declared key set and nothing else"`
- `"accepts the recovery lane name"`
- `"rejects an approved head that is not 40 lowercase hex characters"`
- `"rejects a version that is not semver"`
- `"rejects a lane name outside the two declared lanes"`
- `"verifies a record matching the expected triple"`
- `"reports mismatch when only the package differs"`
- `"reports unreadable -- not missing -- on a record that is not valid JSON"`
- `"reports unreadable -- not missing -- on a record missing a required key"`
- `"the missing, mismatch and unreadable outcomes carry distinct exit codes"`
- `"the emitter's real output verifies against the same triple"`
- `"the emitter's real output from the recovery lane verifies identically"`

**Group M — 173-01's `workflow_test.exs`, evidenced by a MEASURED COUNT rather than a mutation (2
checks).** Per `VERIFICATION-CONVENTIONS.md`, a measured count over a real run is independently valid
non-vacuity evidence alongside a mutation.

- `"one reusable workflow carries the only copy of the exact-public proof body"` — evidenced by
  173-01-SUMMARY.md's own measured table: `grep -c -- '--source-mode exact-public'` across the tree
  went from `1` (before, inside `release-please.yml`) to `1` (after, inside the new
  `exact-public-proof.yml`, with `0` in both lane files) — one copy, moved, never duplicated.
- `"native recovery is deliberately left outside this phase's Hex convergence"` — evidenced by
  173-01-SUMMARY.md's byte-identity measurement: `recover-android-core` block extracted and compared
  byte-for-byte (3270 bytes, both sides) against its pre-plan state.

**Group C — the shared positive-path control (1 check).** `"emits every phase-173 check as passing"`
(`Crosswake.Proof.Phase173RecoveryProofConvergenceTest`, 173-02) is the unmutated baseline every
mutated-red assertion in this module compares itself against. A control is definitionally the
un-mutated case; mutating it would make it stop being a control.

**Group R — 173-03's rollup fail-closed tests (4 checks), out of this plan's editable file scope, with
a self-contained adversarial sweep already exercised on every run.** Independently re-mutating these
would require editing `lib/crosswake/release_candidate/workflow.ex`, which this plan's dispatch
explicitly forbids (`Do NOT edit lib/crosswake/release_candidate/workflow.ex`) and which 173-03 itself
left byte-unchanged by design (the criterion being verified is that these semantics SURVIVED the graph
change, not that they were built new). Each test's own body already contains a self-contained
adversarial value sweep exercised on every real `mix test` run — e.g. `"no accepted non-success status
for the exact-public child ever yields COMPLETE"` sweeps BOTH accepted non-success values (`failed`,
`skipped`) AND five rejected values (`cancelled`, `neutral`, `SUCCESS`, `"success "`, `""`), asserting
`ArgumentError` on every rejected one — a Group-A'-style built-in mutation set, not requiring an
external mutation of the module under test.

- `"a skipped exact-public proof beside five successes still rolls up not-complete"`
- `"a skipped exact-public proof is not distinguished from a failed one"`
- `"no accepted non-success status for the exact-public child ever yields COMPLETE"`
- `"the rollup still depends on the exact-public proof job and still reads its result"`

**Group L — 173-03's remaining `release_ledger_test.exs` tests (5 checks), evidenced instead by the
SC#4 measured pair rather than by an internal mutation.** These are read-back/structural/positive-path
assertions over the real committed ledger and the real script's own exit-code contract. The phase's
durability claim for this file (SC#4) rests on the MEASURED PAIR recorded in 173-03-SUMMARY.md — run
`31325689640`'s uploaded artifact reports `"expired": true` (expired 2026-08-23), while the SAME run's
ledger line reads back cleanly via `git show c3eb7cdd...:docs/release-ledger/RELEASE-LEDGER.jsonl` —
which is the evidence these particular tests exist to keep true on every future commit, not a mutation
of any one of them individually.

- `"the backfill boundary is declared and classifies every committed row decidably"`
- `"the measured run's entry is present and records a real, non-invented coordinate"`
- `"a committed entry is readable with git show at an explicit commit, from a directory that does not contain the file"`
- `"a different run for the same coordinate does append a second line"`
- `"each rejected field exits with its own code, so the log names which field was wrong"`

### WINDOWS entry #34 — recorded here because it bounds what the ledger's non-vacuity claims cover

Per the coordinator's instruction, WINDOWS entry #34 (recorded after 173-03) states: `record-ledger` in
`.github/workflows/exact-public-proof.yml` is gated on `needs.exact-public-proof.outputs.applicable ==
'true'`. If the proof job fails INSIDE its own applicability step — a bad `lane` value, or a recovery
call with both `approved_head` and `merge_oid` blank (the exact condition
`release.recovery.proof_applicability_lane_gated`, row 7 above, now refuses rather than skips) — the
`applicable` output is never set at all, `record-ledger`'s `if:` evaluates to false, and the job is
skipped. **No ledger row is written for that failure mode.** This is the one XPUB-05 failure shape the
ledger never records, and it is deliberately deferred, not fixed, by this plan.

This bounds two claims in this record, and both are stated explicitly rather than left to be
discovered later:

- **Row 7's own evidence is unaffected.** `release.recovery.proof_applicability_lane_gated` is a static
  check over the workflow YAML's `if:`/`case` structure — it does not depend on `record-ledger` running
  at all, and its mutation-backed evidence (the before/after table, the two fixture tests) stands
  independently of WINDOWS #34.
- **The Task 2/3 fire-drill design in this plan deliberately does NOT reach the WINDOWS #34 gap.**
  `recovery-fire-drill`'s dispatched inputs (a real 40-hex `approved_head`, a real 40-hex `merge_oid`, a
  non-empty `candidate_receipt_run_id`) are chosen so the applicability step SUCCEEDS
  (`applicable=true` is written) and the job fails LATER, at the record-assertion step. Per the reusable
  workflow's own `outputs: applicable: ${{ steps.applicability.outputs.applicable }}` declaration, a
  step output already written survives a later step's failure in the same job — so `record-ledger`
  WOULD still see `applicable=true` and attempt to write a row for the fire-drill's own failure mode,
  once that observation is taken. The fire-drill therefore exercises a failure mode the ledger DOES
  cover, not the WINDOWS #34 gap. A maintainer who later wants to demonstrate WINDOWS #34's coverage
  gap directly would need a SEPARATE dispatch — e.g. `recovery-fire-drill` with a malformed `lane` or
  with `approved_head`/`merge_oid` both blank — and confirm no `record-ledger` run appears for it at
  all. That is out of this plan's scope and is not claimed as covered here.

### The phase's two source-derived facts

**Retention measurement (from 173-03).** A measured pair about one real run, not an architectural
argument: run `31325689640` (`crosswake_sigra 0.1.3`, `2026-08-09`) — its one uploaded artifact
(`native-release-status`) reports `"expired": true`, `"expires_at": "2026-08-23T17:13:09Z"`
(25 days before the 173-03 measurement) — while the SAME run's ledger line reads back cleanly:

```
$ cd /tmp && git --git-dir=/Users/jon/projects/crosswake/.git \
    show c3eb7cdd9d7e8e948bd2e7635f3f6da55918c81e:docs/release-ledger/RELEASE-LEDGER.jsonl | grep 31325689640
{"schema_version":"1.0.0","package":"crosswake_sigra","version":"0.1.3","approved_head":"70edb8077894fd09d4376591782b511c9d8be664","ref":"refs/tags/crosswake_sigra-v0.1.3","lane":"ordinary","run_id":"31325689640","outcome":"failure","recorded_at":"2026-09-18T00:30:56Z"}
```

1 of 1 artifact for that run is measurably expired; the ledger line for the same run is measurably
readable. ROADMAP Success Criterion 4 is satisfied by this pair, not by the architectural observation
that git has no expiry.

**Fire-drill observation status (from Tasks 2 and 3, this plan).** **TAKEN — 2026-09-18**, run
[35302554800](https://github.com/szTheory/crosswake/actions/runs/35302554800) against `main` at
`a2761a55`. The proof body job is **present** and its `conclusion` reads **`failure`**, not
`skipped`, failing at `PUBLICATION_RECORD_MISSING` with exit code 4; `publish` never executed. The
first attempt (run 35299245680, at `91bcb093`) instead ended in `startup_failure` with an empty job
list and exposed a real defect — the entire `hex-publish.yml` was invalid, making the emergency
recovery lane un-dispatchable — repaired in PR #181. Full evidence, quoted job list and log lines are
in "Task 2/3 — the fire-drill runtime observation" above. **ROADMAP Success Criterion 2 is now
satisfied by this record.**

The pre-merge reasoning below is retained as history. The dispatch was structurally impossible
pre-merge —
`operation` is a `type: choice` input validated by GitHub against the default branch's definition,
which does not carry the `recovery-fire-drill` option (`main`'s option list is
`candidate-rehearsal, recovery, android-recovery`; this branch's is those three plus
`recovery-fire-drill`, confirmed by contrasting `git show origin/main:.github/workflows/hex-publish.yml`
against the working tree) — and, secondarily and incidentally, this session's own "do not push" policy
meant no attempt was made regardless. See "Task 2/3 — the fire-drill runtime observation" above for
the full reasoning, the exact post-merge command, and the named owner (Jon, maintainer of
`szTheory/crosswake`). That command has since been run; see the TAKEN record above.

### Reconciliation

- Mutation-backed: rows 1 (4 checks) + 2 (1) + 3 (1, extended by a second mutation, still 1 check) +
  4 (1) + 5 (5: 4 tests + 1 predicate) + 6 (5: 4 tests + 1 predicate) + 7 (3: 2 tests + 1 predicate) +
  8 (1) + 9 (3) + 10 (3: 2 tests + 1 predicate) = **27**.
- No mutation run: Group T (12) + Group M (2) + Group C (1) + Group R (4) + Group L (5) = **24**.
- **27 + 24 = 51**, matching the per-plan total (`21 + 14 + 13 + 3 = 51`) from "Scope and counts" above.
- Per-plan cross-check: 173-01 mutation-backed (rows 1-4: 4+1+1+1=7) + Group T (12) + Group M (2) = 21.
  173-02 mutation-backed (rows 5-7: 5+5+3=13) + Group C (1) = 14. 173-03 mutation-backed (rows 8-9:
  1+3=4, plus row 3's 173-03 extension which adds no new count) + Group R (4) + Group L (5) = 13.
  173-04 mutation-backed (row 10: 3) = 3. `21 + 14 + 13 + 3 = 51`. ✓
