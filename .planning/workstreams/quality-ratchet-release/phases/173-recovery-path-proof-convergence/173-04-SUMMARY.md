---
phase: 173-recovery-path-proof-convergence
plan: 04
subsystem: release-candidate-proof
tags: [github-actions, workflow_dispatch, workflow_call, hex-publish, elixir, mutation-testing]
status: complete

# Dependency graph
requires:
  - phase: 173-recovery-path-proof-convergence
    plan: 01
    provides: one reusable exact-public proof body, both lanes calling it, the record emitter idiom
  - phase: 173-recovery-path-proof-convergence
    plan: 02
    provides: the two-graph checker fixtures, the declared @proof_lanes roster, the raise-on-no-op fixture guard
  - phase: 173-recovery-path-proof-convergence
    plan: 03
    provides: the durable release ledger, the fail-closed rollup regression coverage
provides:
  - "recovery-fire-drill — a credential-free workflow_dispatch operation in hex-publish.yml reaching the same reusable exact-public-proof.yml the real recovery lane reaches, with no needs: on publish and no registry credential anywhere in the job"
  - "release.recovery.fire_drill_shares_proof_body — the checker predicate holding the drill's uses: identity to the recovery caller's by exact string equality, plus the absence of any credential or guarded-publish invocation"
  - "173-NON-VACUITY.md — the phase's measured non-vacuity ledger: 51 checks landed across 173-01 through 173-04, 27 mutation-backed, 24 named with reasons, plus the two source-derived facts (retention measurement, fire-drill observation status)"
affects: [174]

# Actuals (#2632)
actuals:
  tokens: 12259
  tasks: 4
  commits: 5
plan_head_before: 3c3f5b8d0084c92ba2624fdb325d5e38a7888032

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A permanent dispatch-only fire drill whose uses: value is held identical to the real lane's by
      a checker predicate rather than by convention — the same shape as the phase's own
      publication-record-identity checks, applied one level up: to the drill itself."
    - "A runtime observation an executor cannot force (a GitHub choice-input value that does not
      exist on the default branch) is recorded as PENDING with a named command and a named owner,
      never inferred as satisfied from adjacent static evidence."
    - "A declared, exact caller roster (not a permissive pattern) catching a real structural change
      immediately, exactly as designed — the check's own SEED-019 discipline working as intended
      against a genuine addition, not a synthetic fixture."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-NON-VACUITY.md
  modified:
    - .github/workflows/hex-publish.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase173_recovery_proof_convergence_test.exs
    - test/crosswake/release_candidate/workflow_test.exs

decisions:
  - "Case B of the Task 3 checkpoint carries TWO reasons, one structural and binding and one incidental. GitHub validates a workflow_dispatch choice input's VALUE against the workflow definition on the default branch, and recovery-fire-drill does not exist there yet -- the dispatch is impossible pre-merge regardless of push policy. The session's own no-push constraint is a second, non-binding reason recorded for completeness. The maintainer (Jon) corrected the record to name the structural reason as primary after independently verifying it."
  - "The fire drill's dispatched inputs (a real 40-hex approved_head/merge_oid, a non-empty candidate_receipt_run_id) are chosen so the shared proof body's applicability step SUCCEEDS and the job fails LATER at the record-assertion step -- deliberately not exercising the WINDOWS #34 gap (record-ledger skips when applicability itself fails), so the ledger's non-vacuity claims are not overstated to cover that path."
  - "'Check landed' is defined mechanically for the non-vacuity ledger (new ExUnit tests + new checker-predicate IDs), since 173-01/02/03 carry no coverage: frontmatter enumeration to inherit the count from."

metrics:
  duration: ~3h (includes a human-verify checkpoint pause)
  completed: 2026-09-17
---

# Phase 173 Plan 04: Recovery-Path Proof Convergence (fire drill + non-vacuity ledger) Summary

A credential-free `recovery-fire-drill` operation now reaches the real recovery proof body by the
same `uses:` path the recovery lane itself uses (held identical by a checker predicate, not
convention), the runtime observation that a real run of it fails closed is recorded honestly as
PENDING with the exact post-merge command and named owner rather than inferred from static fixtures,
and the phase's full measured non-vacuity ledger closes out all 51 checks landed across 173-01
through 173-04 with a mutation or a stated reason for every one.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `567f7176` | `recovery-fire-drill` operation + job in hex-publish.yml; `release.recovery.fire_drill_shares_proof_body` checker predicate; 2 fixture tests |
| 2 | `50e3670c` | `173-NON-VACUITY.md` created; fire-drill observation recorded PENDING |
| — | `0480a1f5` | Jon's correction: the structural (default-branch choice-input validation) blocker named as primary, the push-policy reason as secondary |
| — | `08c19383` | real defect found and fixed: the caller-roster test's 2-entry literal extended to 3 after the fire drill's addition |
| 4 | `08cc53d9` | the phase's full measured non-vacuity ledger: 51 checks, 27 mutation-backed, 24 named with reasons |

## Task 1 — a credential-free fire drill reaching the real proof body

`hex-publish.yml`'s `operation` choice input gained a fourth option, `recovery-fire-drill`, gating a
new job that is purely a `uses:` call into `.github/workflows/exact-public-proof.yml` — no `needs:`
on `publish` (never runs it), no secret read anywhere in the job, and `script/guarded_hex_publish.sh`
never appears in it. Its `permissions:` block (`actions: read`, `contents: read`) exists for the
identical reason `recovery-exact-public-proof`'s does: the file's top-level `permissions:` key lists
only `contents: read`, so a called workflow can only narrow, never widen, the token it is handed.

`release.recovery.fire_drill_shares_proof_body` (new checker predicate) asserts the drill's `uses:`
value is character-identical to the recovery caller's, that no `HEX_API_KEY` or
`script/guarded_hex_publish.sh` reference appears in its block, and that it carries no `needs:` edge
on `publish`. Two fixture tests turn it red: a differently-named reusable workflow reference, and an
injected credentialed publish step — each paired with an unmutated control asserted green in the same
test body.

```
$ elixir script/check_release_workflow_integrity.exs
...
[crosswake] DONE: 73 of 73 roster checks emitted; 0 failed.

$ mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1
13 tests, 0 failures
```

## Task 2/3 — the runtime observation, recorded honestly as PENDING

No `workflow_dispatch` of `recovery-fire-drill` was taken. Two distinct reasons apply, and both are
recorded rather than one standing in for the other:

1. **Structural and binding.** `operation` is a `type: choice` input. GitHub validates a
   `workflow_dispatch` call's choice-input *values* against the workflow definition on the **default
   branch**, not the dispatched ref. `recovery-fire-drill` does not exist in `main`'s definition of
   `hex-publish.yml` (confirmed by contrasting `git show origin/main:...` against the working tree —
   `main` has three options, this branch has four) — the dispatch would be refused on the input value
   alone, at any ref, regardless of push policy. This is exactly the shape the plan's own Task 2d
   names.
2. **Incidental.** This session additionally operated under an explicit "do not push, do not open a
   PR" constraint, so no attempt was made in this session even setting reason 1 aside.

`173-NON-VACUITY.md` names the exact `gh workflow run` / `gh run view --json jobs` commands a
maintainer (Jon) must run after this phase's PR merges, and states explicitly that **ROADMAP Success
Criterion 2 is NOT satisfied by this record** — Task 1's static fixtures prove the drill reaches the
right body by the right path; only a real run can prove GitHub reports that body's failure as
`failure` rather than `skipped`.

At the checkpoint, Jon independently verified the record (branch absent from remote,
Criterion 2 explicitly marked unsatisfied) before approving Case B, and corrected the reasoning to
name the structural blocker as primary — folded into the record per his instruction.

## Task 4 — the phase's measured non-vacuity ledger

`173-NON-VACUITY.md` defines "check landed" mechanically (new ExUnit tests + new checker-predicate
IDs, since 173-01/02/03 carry no `coverage:` frontmatter to inherit a count from), measures 51 checks
across the four plans (21 + 14 + 13 + 3), and carries:

- **10 mutation-backed rows** covering 27 of the 51 checks — several bundling a checker predicate
  with its own fixture tests, since both are distinct verification instruments for the same property.
  Two of 173-04's own checks (the drill's identity and credential-absence conjuncts) were
  independently reproduced this session against the real tree via standalone fixture files and the
  `HEX_PUBLISH_WORKFLOW_PATH` env override — never against the tracked files.
- **24 checks named with a reason** in five groups (TDD-cycle-only, measured-count, control baseline,
  out-of-editable-scope module with a self-contained adversarial sweep, ledger-durability-measured-
  elsewhere) — none silently omitted.
- **A WINDOWS #34 cross-reference**, stating plainly that this plan's fire-drill design does NOT
  exercise that gap (the drill's inputs are chosen so applicability succeeds and the job fails later,
  which the ledger DOES record) and naming what a future maintainer would need to dispatch to
  demonstrate the gap directly.
- **The two source-derived facts**: the 173-03 retention measurement (one real run's artifact
  measurably expired 2026-08-23; the same run's ledger line measurably readable via `git show`), and
  the fire-drill observation status (PENDING, cross-referenced to the Task 2/3 section).

### A real defect the ledger's own preparation surfaced

Adding `recovery-fire-drill` as a caller of `exact-public-proof.yml` immediately red-lined
`Crosswake.ReleaseCandidate.WorkflowTest`'s `"every caller of the reusable exact-public proof grants
actions: read at job level"` test — a pre-existing check (173-01, extended by 173-03) that asserts an
exact, declared 2-entry caller roster. This is precisely the SEED-019 discipline the test itself
exists to enforce, catching a real structural change rather than a synthetic mutation:

```
1) test every caller of the reusable exact-public proof grants actions: read at job level
   Assertion with == failed
   left:  [..., {".github/workflows/hex-publish.yml", "recovery-fire-drill"}, ...]  (3 entries)
   right: [...]  (the old 2-entry literal)
```

Fixed by adding `{@hex_workflow, "recovery-fire-drill"}` to the expected roster (`08c19383`); the
rest of the loop's assertions (permissions grant, contents-by-value, no leftover `runs-on:` /
`timeout-minutes:` / `steps:`) already pass for the drill unmodified, since it was designed to satisfy
them. Re-run: `23 tests, 0 failures`. Recorded in `173-NON-VACUITY.md` row 3 as a third extension of
that check's own evidence, not a new check.

## Deviations from Plan

### [Rule 1 — bug] The caller-roster test's stale 2-entry literal

- **Found during:** the plan's own required full-suite verify (`mix test test/crosswake/proof
  test/crosswake/release_candidate --max-cases 1`).
- **Issue:** `Crosswake.ReleaseCandidate.WorkflowTest`'s declared caller roster did not include the
  new `recovery-fire-drill` caller Task 1 legitimately added.
- **Fix:** extended the expected roster to three entries.
- **Files modified:** `test/crosswake/release_candidate/workflow_test.exs`.
- **Commit:** `08c19383`.

### Case B's reasoning corrected by the maintainer (not an executor deviation, recorded for completeness)

The initial `173-NON-VACUITY.md` draft (commit `50e3670c`) attributed Case B solely to the session's
no-push constraint. Jon corrected this after independently verifying the record: the binding reason
is GitHub's choice-input validation against the default branch, a structural blocker independent of
push policy. Corrected in `0480a1f5`.

## Threat mitigations applied

| Threat | Where |
|---|---|
| T-173-17 (a fire drill exercising a private copy of the proof logic) | `release.recovery.fire_drill_shares_proof_body` asserts `uses:` equality by exact string comparison; two fixtures (different reusable workflow; each paired with a green control) prove it is sensitive to the drift it exists to catch. |
| T-173-18 (a "not skipped" assertion vacuously true on an absent job) | `173-NON-VACUITY.md`'s Task 2/3 section names asserting the job's presence in the run's job list as a separate fact from its conclusion value, for whoever takes the observation post-merge. |
| T-173-19 (a drill operation reaching a real publish) | Task 1 forbids any `needs:` on `publish`, any secret read, and any invocation of `script/guarded_hex_publish.sh` in the drill job; the checker predicate asserts all three. |
| T-173-20 (a pending observation reported as satisfied on static fixtures alone) | `173-NON-VACUITY.md` states explicitly, twice, that ROADMAP Success Criterion 2 is not satisfied by this record; Task 3's checkpoint required Jon's own explicit case confirmation, never auto-approved. |
| T-173-21 (mutation evidence lost with the tree it was run against) | Every row in the ledger carries a quoted output and a commit; the two 173-04-specific mutations were independently reproduced this session and are quoted verbatim. |
| T-173-SC (package installs) | Not applicable — this plan adds no package-manager install step. |

## Untouched by design

- `lib/crosswake/release_candidate/workflow.ex` — not edited, per this plan's explicit constraint.
- `.planning/workstreams/quality-ratchet-release/STATE.md` and `ROADMAP.md` — not touched, per this
  plan's explicit constraint; the coordinator manages phase progression.
- `recover-android-core` — untouched; native recovery convergence remains Phase 174's scope.
- No shell script was created or modified by this plan; the `shellcheck` requirement is vacuously
  satisfied (nothing to check).

## Verification

| Check | Result |
|---|---|
| `actionlint .github/workflows/hex-publish.yml .github/workflows/release-please.yml .github/workflows/exact-public-proof.yml` | exit 0 |
| `elixir script/check_release_workflow_integrity.exs` | exit 0 — `DONE: 73 of 73 roster checks emitted; 0 failed.` |
| `mix test test/crosswake/proof test/crosswake/release_candidate --max-cases 1` | 819 tests, 0 failures (67 excluded) |
| `mix test --exclude requires_example_host` | 1908 tests, 0 failures (74 excluded) |
| `mix format --check-formatted` | exit 0 |
| `grep -c 'conclusion' 173-NON-VACUITY.md` | 7 |
| `grep -c '\[ \]\|\[x\]\|☑' 173-NON-VACUITY.md` | 0 |

## Known Stubs

None. Every artifact this plan names is wired to a caller or a checker: the drill job is a real,
dispatchable (post-merge) `workflow_dispatch` operation; the checker predicate runs on every
hermetic CI run; the non-vacuity ledger records every check's true status, including the one item
(the fire-drill runtime observation) that is honestly PENDING rather than falsely marked complete.

## Threat Flags

None. No file changed by this plan introduces network, auth, file-access or schema surface outside
the plan's `<threat_model>`. The new `recovery-fire-drill` operation reads no secret and cannot reach
a real publish, by design and by the checker predicate that holds it there.

## Not done here (by design)

No `workflow_dispatch` was taken (structurally impossible pre-merge; see Task 2/3 above). No pull
request was opened; per the `<atomicity_constraint>` this plan carries with 173-01 through 173-03,
the coordinator opens ONE pull request covering all four plans.

## Self-Check: PASSED

`173-NON-VACUITY.md` exists on disk. All five commit hashes (`567f7176`, `50e3670c`, `0480a1f5`,
`08c19383`, `08cc53d9`) resolve in `git log`. `git rev-list --count 3c3f5b8d..HEAD` = 5, matching the
`commits:` frontmatter.
