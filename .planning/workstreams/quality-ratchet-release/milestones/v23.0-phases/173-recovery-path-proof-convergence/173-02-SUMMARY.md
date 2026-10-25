---
phase: 173-recovery-path-proof-convergence
plan: 02
subsystem: release-candidate-proof
tags: [elixir, github-actions, workflow_call, hex-publish, publication-record, mutation-testing]
status: complete

# Dependency graph
requires:
  - phase: 173-recovery-path-proof-convergence
    plan: 01
    provides: one emitter, one assertion script, one reusable proof body, both lanes calling it
provides:
  - "release.recovery.publication_record_identical — per-lane emitter flags, argument values, artifact template, actions: read grant, and the two callers' uses: compared as equal strings"
  - "release.recovery.proof_record_fails_closed — the shared body always runs, swallows nothing, and sources its expected triple from its own inputs"
  - "release.recovery.proof_applicability_lane_gated — the one zero-exit branch is reachable from the ordinary lane only"
  - "Crosswake.ReleaseWorkflowFixtures — the one fixture harness for the workflow integrity scanner, shared by the phase-142 and phase-173 proof modules"
  - "test/crosswake/proof/phase173_recovery_proof_convergence_test.exs — 11 fixtures, on the hermetic always-running CI lane"
affects: [173-03, 173-04, 174]

# Actuals (#2632)
actuals:
  tokens: 12901
  tasks: 3
  commits: 5
plan_head_before: ca23ffcb

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A scope selector (the lane roster) declared as a literal constant, never derived from
      the artifact it polices — proven by a recorded mutation that replaces it with a scan and
      observes it shrink away from the non-compliant lane (SEED-019)."
    - "Two references compared as EQUAL STRINGS against one declared constant, rather than each
      matched against a permissive pattern that both can satisfy while naming different files
      (SEED-020)."
    - "One declared artifact-name template rendered three ways (two producers, one consumer) and
      each rendering compared for equality — the template is the single source, not a shape each
      site independently resembles."
    - "A paired mutated-red / control-green assertion in ONE test body: a red-only assertion
      cannot distinguish a check that is sensitive to the fixture from one that fails on every
      input."
    - "A conjunct that FORBIDS a shape is falsified separately from the conjunct that REQUIRES
      its opposite; otherwise the forbidding one is indistinguishable from dead code."
    - "An exemption that FOLLOWS the reference it exempts (reusable-workflow timeout bounds)
      rather than simply skipping it — a bare exemption scores absence as success."

key-files:
  created:
    - test/crosswake/proof/phase173_recovery_proof_convergence_test.exs
    - test/support/release_workflow_fixtures.ex
  modified:
    - .github/workflows/exact-public-proof.yml
    - .github/workflows/crosswake-ci.yml
    - script/check_release_workflow_integrity.exs
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase142_release_integrity_test.exs
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - test/crosswake/release_candidate/publication_record_test.exs

decisions:
  - "A THIRD check ID (release.recovery.proof_applicability_lane_gated) was added beyond the two the plan named, to carry the orchestrator's root-cause finding. A separate ID rather than a fourth conjunct inside proof_record_fails_closed, so the FAIL line names the defect precisely."
  - "hex-publish.yml's approved_head / merge_oid inputs were deliberately NOT tightened to required: true. The rehearsal and android-recovery operations in the same workflow legitimately run without them, so form-level requiredness would force operators to type junk values that then satisfy the -n checks — actively worse than the workflow-side guard, which workflow_call and API dispatch cannot bypass."
  - "The reusable proof body's job display name was changed to \"shared: exact-public artifact proof body\". It is not a registered required context (required_check_policy.json lists only \"Crosswake CI\"), so branch protection is unaffected."
  - "WINDOWS.md entry #33 is left OPEN. The fix narrows it but does not subsume it — see \"WINDOWS entry #33\" below."

metrics:
  duration: ~95 min
  completed: 2026-09-17
---

# Phase 173 Plan 02: Recovery-Path Proof Convergence Summary

The convergence 173-01 wired is now a checkable claim: two fixtures — one modelling the ordinary
release graph, one modelling the `workflow_dispatch` recovery graph — are evaluated by one checker
against one **declared** lane roster, each half has its own fixture that turns the check red on its
own, and the roster is proven, by mutation, not to shrink away from a lane that stops complying.
A reachable false-green inside the artifact 173-01 built to eliminate false-greens was found by the
orchestrator and fixed at the root.

## Commits

| Task | Commit | What |
|---|---|---|
| finding | `8c3f60dd` | the recovery lane can no longer skip the exact-public proof |
| 1 | `f5d0175c` | three checker predicates, the declared `@proof_lanes` roster, the new path override |
| — | `ef71b4b6` | repair of the three merge-blocking lanes 173-01 left red |
| 2 | `a15c4f12` | harness extracted to `test/support/`; 11 fixtures; both recorded mutations |
| 3 | `2f5a34c6` | the new fixtures put on the hermetic always-running CI lane |

---

## The orchestrator's finding: a reachable false-green, fixed at the root

**The escape, measured on both sides.** `.github/workflows/exact-public-proof.yml`'s only zero-exit
branch fired whenever `APPROVED_HEAD` and `MERGE_OID` were both empty. `hex-publish.yml` declares
both as `required: false` with `default: ''`, and the recovery caller passes them straight through.
Measured by extracting the applicability step's `run:` body verbatim and executing it directly:

| lane | approved_head | merge_oid | before (`ca23ffcb`) | after |
|---|---|---|---|---|
| recovery | empty | empty | **exit 0**, `GITHUB_OUTPUT` = `applicable=false` | **exit 1** |
| ordinary | empty | empty | exit 0, `applicable=false` | exit 0, `applicable=false` |
| recovery | 40-hex | 40-hex | exit 0, `applicable=true` | exit 0, `applicable=true` |
| bogus | empty | empty | exit 1 (lane rejected) | exit 1 (lane rejected) |

Before the fix, a maintainer who dispatched a recovery publish and left those two fields blank got:
a real publish → `recovery-exact-public-proof` runs → `applicable=false` → every proof step skipped
by its step-level `if:` → **job concludes `success`**, having proved nothing.

**The fix.** The lane is now validated FIRST, before any branch can exit zero, and the
not-applicable branch is gated on `[ "$LANE" != "ordinary" ]`. A recovery call exists only because a
publish already happened, so "not a linked release" is never a truthful answer for it. The refusal
carries a named result and a what-to-do-next line:

```
[crosswake] FAIL: PROOF_APPLICABILITY_UNDETERMINED - the recovery lane reached the exact-public proof with neither an approved head nor a merge oid.
[crosswake] A recovery call follows a publish that already happened, so the proof always applies to it; skipping it here would conclude success having proved nothing.
[crosswake] What to do next: re-dispatch .github/workflows/hex-publish.yml supplying the approved_head and merge_oid inputs (plus candidate_receipt_run_id) for the coordinate you recovered.
```

**Which check covers it:** `release.recovery.proof_applicability_lane_gated`, a third new check ID
beyond the two the plan named. Its fixture restores the un-laned branch (`if [ "$LANE" != "ordinary" ]`
→ `if false`) and asserts the check red, paired with an unmutated control asserted green in the same
test body. A second fixture moves the lane `case` back below the applicability branch — the exact
pre-fix ordering — and asserts the ordering conjunct red on its own. Observed red output:

```
[crosswake] FAIL: release.recovery.proof_applicability_lane_gated - recovery lane
(.github/workflows/hex-publish.yml job recovery-exact-public-proof): the not-applicable branch is
not lane-gated: expected if [ "$LANE" != "ordinary" ]; then guarding it, so a recovery call with
both approved_head and merge_oid blank would skip every proof step and still conclude success |
the lane gate must be evaluated BEFORE the applicable=false marker is written | the recovery-lane
refusal must report the named result PROOF_APPLICABILITY_UNDETERMINED | the recovery-lane refusal
must exit non-zero -- fix in .github/workflows/exact-public-proof.yml; rerun with `elixir
script/check_release_workflow_integrity.exs`, and `mix test
test/crosswake/proof/phase173_recovery_proof_convergence_test.exs` for the fixture that reproduces it
```

**On tightening `hex-publish.yml`'s inputs to `required: true`** — deliberately NOT done, and the
workflow-side guard is not a substitute for it but the whole of it. Two of the three operations that
workflow exposes (`candidate-rehearsal`, `android-recovery`) legitimately run without an
`approved_head`/`merge_oid` pair in the recovery sense, so form-level requiredness would push
operators to type placeholder values, which then satisfy the `-n` checks downstream — strictly worse
than a blank. And as the orchestrator noted, `workflow_call` and REST dispatch bypass form-level
requiredness anyway. The refusal is stated in the body where neither can reach around it.

### WINDOWS entry #33 — left OPEN, and why

Entry #33 records that the record-assertion step carries a step-level
`if: steps.applicability.outputs.applicable == 'true'`. This fix makes that marker **unfalsifiable
for the recovery lane** — `applicable=false` is now unreachable there. It does **not** subsume the
entry, because the ordinary lane's not-applicable branch is still live by design, so a step-level
`if:` on a marker that can be `false` still exists in the file. The entry is narrowed from "either
lane can skip" to "the ordinary lane can legitimately skip", which is the intended behaviour, but
the shape the entry names is still present. Left open rather than closed on a partial fix.

---

## Task 1 — the checker decides the contract per lane

`EXACT_PUBLIC_PROOF_WORKFLOW_PATH` joins the seven existing `path_from_env/2` overrides.
`@proof_lanes` declares the two lanes as a literal, with a comment addressed to the next reader who
is tempted to replace it with a scan. Three predicates iterate it.

`release.recovery.publication_record_identical` reads, per lane: the emitter's **flag names in
order** (compared against `@record_emitter_flags`, not merely "the script is mentioned"), the
`--lane` / `--package` / `--approved-head` **argument values** against the lane's declared
expressions, the upload artifact name against `@record_artifact_template` rendered for that lane,
`if-no-files-found: error`, and a job-level `permissions:` block granting `actions: read` — with the
detail string stating in so many words that this one is an authorization property, not a shape one,
and that actionlint cannot decide it. Across lanes it compares the two `uses:` values for **string
equality** against one declared constant, and requires the shared body's consumer to render the same
artifact template.

`release.recovery.proof_record_fails_closed` reads the job's `if:`, the assertion step, the absence
of `|| true` / `continue-on-error` / `set +e`, the presence of all three input-sourced env
assignments, the absence of any step-derived one, and the absence of a `secrets:` key.

Verify block, run as written:

| Command | Result |
|---|---|
| `elixir script/check_release_workflow_integrity.exs` | exit 0 — `DONE: 72 of 72 roster checks emitted; 0 failed.` |
| `... \| grep -c '<the two IDs>'` | **3** — see note below |

**Note on the second `<verify>` — the plan's instrument, corrected, not the assertion weakened.**
The plan expects `>= 4` and explains why: "each ID must appear in both the ROSTER line and its own
result line". That is exactly what the tree does — but `grep -c` counts **matching lines**, not
occurrences, and both IDs share the single ROSTER line. The artifact satisfies the stated property;
the measuring instrument does not measure it. Measured with the instrument the plan describes:

```
$ grep -o 'release.recovery.publication_record_identical\|release.recovery.proof_record_fails_closed' out | wc -l
4
$ grep -n '...' out
1:[crosswake] ROSTER: 72 ...          <- both IDs
47:[crosswake] OK: release.recovery.publication_record_identical - ...
48:[crosswake] OK: release.recovery.proof_record_fails_closed - ...
```

4 occurrences over 3 lines. Nothing was relaxed to make this pass.

## Task 2 — two graphs, each half proven red on its own

The phase-142 module's private harness was **extracted**, not copied, into
`test/support/release_workflow_fixtures.ex`. Phase 142 now delegates to it and still passes **60
tests, 0 failures**. The new module adds the eighth override key plus `remove_step!/3`, which is
built on the existing raise-on-no-op guard rather than beside it.

11 tests, one per behavior line:

| Fixture (mutation of the REAL file) | Check turned red |
|---|---|
| ordinary lane's `Write the publication record` step deleted | `publication_record_identical` |
| recovery lane's same step deleted **+ control asserted green** | `publication_record_identical` |
| the two callers name different reusable workflows (records intact) | `publication_record_identical` |
| recovery caller's `permissions:` loses `actions: read` | `publication_record_identical` |
| job `if:` gates on an upstream result | `proof_record_fails_closed` |
| assertion swallowed — `continue-on-error: true` AND `\|\| true` | `proof_record_fails_closed` |
| expected version read out of the record | `proof_record_fails_closed` |
| a record-derived value ADDED beside the input-derived ones | `proof_record_fails_closed` |
| the un-laned branch restored **+ control asserted green** | `proof_applicability_lane_gated` |
| the lane validated only after the branch that exits zero on it | `proof_applicability_lane_gated` |
| the real tree | all three green |

The eighth row exists because removing an always-true conjunct from an `AND` proves nothing: the
"expected version read out of the record" fixture flips both the requiring and the forbidding
conjunct at once, so a separate fixture flips only the forbidding one, leaving all three
input-sourced assignments in place.

`mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` →
**11 tests, 0 failures**.

### Recorded mutation 1 (plan-required) — the identity check weakened to presence-only

The per-lane and cross-lane problem lists were replaced by a single conjunct: is the emitter script
name mentioned anywhere across the two lane files. Observed:

```
11 tests, 4 failures
  1) test ... the ORDINARY lane losing its record-writing step turns the identity check red
  2) test ... a caller job losing its actions: read grant turns the identity check red
  3) test ... two callers naming different reusable workflows turn the identity check red,
     though both lanes still write a record
  4) test ... the RECOVERY lane losing its record-writing step turns the identity check red,
     while an unmutated control stays green
```

Both lane-removal tests **and** the different-paths test fail, exactly as the plan's acceptance
criterion predicts: removing the emitter from one lane leaves the other lane's mention intact, so a
lane-agnostic presence check reports green on a tree with a non-compliant lane. Reverted; the
checker file is byte-identical to its committed state (`git diff --stat` empty).

### Recorded mutation 2 (plan-required) — the declared roster replaced by a scan

`@proof_lanes` replaced, inside `publication_record_identical`, by
`Enum.filter(@proof_lanes, & the lane's publish job already mentions the emitter)`. Observed:

```
11 tests, 2 failures
  1) test ... the RECOVERY lane losing its record-writing step ... while an unmutated control stays green
  2) test ... the ORDINARY lane losing its record-writing step turns the identity check red
```

and inside those failures, the scanner's own green line:

```
[crosswake] OK: release.recovery.publication_record_identical - all 1 declared lanes (recovery)
[crosswake] OK: release.recovery.publication_record_identical - all 1 declared lanes (ordinary)
```

The roster shrank to one lane and reported **green** about a tree where the other lane had stopped
emitting a record. That is T-173-06 / SEED-019 demonstrated rather than asserted, and it is why the
roster is a literal with a comment forbidding the "cleanup" that would reintroduce it. Reverted;
checker byte-identical.

## Task 3 — the hermetic lane, measured rather than inferred

Both new checks' detail strings name the lane, the workflow file, the job, and two runnable
reproductions (`elixir script/check_release_workflow_integrity.exs` and the fixture module). Sample
live FAIL output is quoted in the finding section above and in commit `2f5a34c6`.

**The plan asked for measurement, not inference. A coverage gap was found.** The
`release-candidate-fixtures` job's own two commands were run locally:

| Command (verbatim from the job) | Exit | Measurement |
|---|---|---|
| `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs --max-cases 1 --trace` | 0 | 127 tests, 0 failures; `grep -c Phase173RecoveryProofConvergenceTest` = **0** |
| `elixir script/check_release_workflow_integrity.exs` | 0 | **3** `OK:` lines, one per new check ID |

So the **checks** were already merge-blocking on every pull request, but the **fixtures that prove
them non-vacuous were not**: the new module lives under `test/crosswake/proof`, and every lane that
runs that tree is gated on `classification == 'full_proof'`. Per the plan's "if, and only if"
clause, the module was added to the fixtures job's test list, and the step summary's remediation
line was moved with it so it remains a command an operator can paste. Re-measured after the edit:
**138 tests, 0 failures**, `grep -c Phase173RecoveryProofConvergenceTest` = **1**.

---

## Deviations from Plan

### [Rule 1 — bug] The orchestrator's finding (root cause, `8c3f60dd`)

Described in full above. The fix is in the workflow body, not in a check that merely observes it;
the check exists to keep it fixed.

### [Rule 2 — missing critical functionality] A third check ID

The plan names two check IDs. The finding needs a third,
`release.recovery.proof_applicability_lane_gated`, so the FAIL line names the defect precisely rather
than reporting "fails-closed violated". All three are in `@roster_ids`, so roster-exactness covers
them. The plan's `<verify>` greps for the two named IDs and is unaffected.

### [Rule 3 — blocking issue] Three merge-blocking lanes 173-01 left red (`ef71b4b6`)

This plan's own `<verify>` block requires `mix test test/crosswake/proof --max-cases 1` to pass. On
arrival it was **13 failures across 9 modules**, none of them touching this plan's new files, all of
it 173-01 fallout — 173-01 ran actionlint plus three named suites and never ran the full proof suite.

1. **Duplicate producer display name** (9 of the 13). The extracted reusable workflow's job carried
   `release-please.yml`'s caller name verbatim, so two producers shared one display name and
   `script/list_merge_blocking_checks.py --producers` failed closed. The shared body renamed to
   `"shared: exact-public artifact proof body"`; both callers keep `"release:"` / `"recovery:"`.
   Not a registered required context, so branch protection is untouched.
2. **An unbounded reusable-workflow caller job.** `timeout-minutes` is not among the keys GitHub
   accepts on a `uses:` job, so phase-165's "every workflow job is bounded" rule was unsatisfiable
   for the new caller. Rather than exempt `uses:` jobs — which would score absence as success, since
   a remote reusable body would pass by having no local timeout to examine — the rule now FOLLOWS the
   reference and requires the called workflow's jobs to carry the bound, failing closed on a
   reference it cannot follow. Proven both ways: deleting the callee's `timeout-minutes: 60` turns it
   red, and repointing a caller at `szTheory/other/.github/workflows/...@main` turns it red with
   *"calls ... which this check cannot follow to verify its bound"*.
3. **Two unclassified collection-assertion sites.** 173-01's `publication_record_test.exs` added two
   `assert Enum.all?(codes, ...)` over a runtime-derived list with no cardinality pin — vacuously
   true on an empty list, the exact VAC-02 shape this milestone exists to remove. Fixed **at the
   site** with `assert length(codes) == 3` rather than absorbed as a ledger override, so both now
   classify mechanically as `safe-cardinality-pinned`. Ledger regenerated (227 → 229 rows, zero
   `needs-fix`); phase-170's pinned literals moved with it (`@audited_site_count` 227→229,
   `safe-cardinality-pinned` 30→32, `assert_all` 46→48); the reconciliation delta stays exactly 6.

### [Rule 3 — blocking issue] The harness extracted to `test/support/`

The plan's constraint is to extend the live fixture machinery, not stand up a parallel harness. The
machinery was `defp` inside the phase-142 module, so genuinely sharing it meant extracting it.
Phase 142 delegates and still passes 60/0.

### Plan instrument corrected, not assertion weakened

Task 1's second `<verify>` uses `grep -c` for a count of occurrences. Both measurements are reported
above; the stated property holds (4 occurrences), the line count is 3. No assertion was relaxed.

## Threat mitigations applied

| Threat | Where |
|---|---|
| T-173-06 (roster shrinks to exclude a non-compliant lane) | `@proof_lanes` is a literal with a comment forbidding a derived scan; recorded mutation 2 observes the scan version report `all 1 declared lanes` green. |
| T-173-07 (presence-only assertion passes while callers name different files) | `Enum.uniq(uses_values) == [@exact_public_proof_uses]`; the different-paths fixture keeps both records intact and still goes red. |
| T-173-08 (a negative control red on every input) | Two tests assert mutated-red AND control-green in the same body, with the control's green asserted explicitly and `refute output =~ "[crosswake] FAIL:"`. |
| T-173-09 (a mutation that no-ops after drift) | Every fixture goes through `ReleaseWorkflowFixtures.replace_in_job/4` or `remove_step!/3`, which raise at the mutation site. |
| T-173-16 (a caller silently loses `actions: read`) | Required per lane via `job_key(caller, "permissions")` — narrower than the block, so an explanatory YAML comment cannot satisfy it — with a fixture that removes it. |
| T-173-SC (package installs) | Not applicable — this plan adds no package-manager install step. |

## Vacuity trap avoided

173-01 recorded a check that nearly shipped asserting a YAML **comment**. The permission conjunct
here reads `job_key(caller_block, "permissions")`, which returns only the block's own continuation
lines, and `job_blocks/1` strips full-line comments before any of it. Every conjunct in all three
checks compares against a **non-empty declared expectation** (`@record_emitter_flags`,
`@record_artifact_template`, `@exact_public_proof_uses`, the lane's own expressions), so an absent
subject yields `[]` / `nil` / `""` and fails — it can never match by being empty.

## Untouched by design

- `recover-android-core` — **byte-identical** to `ca23ffcb` (`git diff ca23ffcb..HEAD` shows no
  change to that job). Native recovery convergence is Phase 174's scope.
- `script/write_publication_record.sh`, `script/assert_publication_record.sh` — unchanged; this plan
  decides properties about how they are called, not what they do.
- Both callers' `with:` mappings, every action SHA pin, the `phase168-candidate-receipt-*` schema.

## Verification

| Check | Result |
|---|---|
| `elixir script/check_release_workflow_integrity.exs` | exit 0 — `DONE: 72 of 72 roster checks emitted; 0 failed.` |
| `mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs` | 11 tests, 0 failures |
| `mix test test/crosswake/proof --max-cases 1` | **701 tests, 0 failures** (67 excluded) |
| `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` | 109 tests, 0 failures |
| `mix test test/crosswake/proof/phase142_release_integrity_test.exs --max-cases 1` | 60 tests, 0 failures |
| `mix format --check-formatted` | exit 0 |
| `actionlint` on `exact-public-proof.yml` and `crosswake-ci.yml` | exit 0 |
| `python3 script/list_merge_blocking_checks.py --producers` | exit 0 |
| `elixir script/inventory_collection_assertions.exs --check` | `OK: 229 classified collection-assertion site(s), ledger matches the live tree exactly.` |

Every `<verify>` block in the plan was run as written; where one measured the tree with the wrong
instrument, both readings are reported above and the assertion was left intact.

## Known Stubs

None. No stub, skipped test, or unrun `<verify>` was left behind by this plan.

## Threat Flags

None. No file changed by this plan introduces network, auth, file-access or schema surface outside
the plan's `<threat_model>`. The one authorization-relevant change — the reusable body's job display
name — is not a registered required context.

## Not done here (by the plan's own constraints)

No pull request was opened; Phase 173 lands as ONE PR at the end of 173-04. `STATE.md` and
`ROADMAP.md` were not touched. The three untracked workstream sidecars
(`config.json`, `milestone.lock`, `state.json`) were left untracked.

## Self-Check: PASSED

Both created files exist on disk. All five commit hashes (`8c3f60dd`, `f5d0175c`, `ef71b4b6`,
`a15c4f12`, `2f5a34c6`) resolve in `git log`. `git rev-list --count ca23ffcb..HEAD` = 5, matching
the `commits:` frontmatter.
