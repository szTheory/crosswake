# Phase 173 Plan 04: Fire-Drill Non-Vacuity Record

This file carries the one observation static fixtures cannot make — whether a real dispatch
of `hex-publish.yml`'s `recovery-fire-drill` operation reports its own job `conclusion` as
`failure`, not `skipped`, when the shared exact-public proof body is reached with a
deliberately absent publication record — plus, per `VERIFICATION-CONVENTIONS.md`, the measured
non-vacuity facts for every check this phase (173-01 through 173-04) landed.

## Task 2/3 — the fire-drill runtime observation

**Status: PENDING.** No `workflow_dispatch` of `recovery-fire-drill` was attempted in this
execution session — this is Case B of Task 3's checkpoint, but for a reason distinct from the
platform-refusal case the plan names.

### Why this is Case B, and why the reason differs from the plan's anticipated one

The plan's Task 2d anticipates GitHub *rejecting* a branch-scoped dispatch because the new
`recovery-fire-drill` operation option does not yet exist on the default branch (`workflow_dispatch`
resolves the workflow definition itself from the default branch, even though it runs the file at the
named ref). That specific rejection was never reached here, because a precondition earlier in the
chain was never satisfied: **a `workflow_dispatch` of a ref requires that ref to exist on the
remote**, and this execution session operates under an explicit governing constraint —

> "Do NOT push, do NOT open a PR. I handle the single phase PR at the end."

— issued because Phase 173 lands as ONE pull request covering 173-01 through 173-04 together (the
`<atomicity_constraint>` all four plans carry), opened by the requesting maintainer after this plan
closes, not by the executor mid-phase. Pushing the branch to attempt a pre-merge dispatch would
violate that constraint directly. Verified before writing this section:

```
$ git rev-parse HEAD
567f717688b1cf4eff4ccd9def31acecc57b3c96
$ git ls-remote origin refs/heads/gsd/phase-173-recovery-path-proof-convergence
(no output — the branch does not exist on the remote)
```

The branch is not on the remote, no push was performed, and therefore no `workflow_dispatch` API
call was made at all — there is nothing to quote as a rejection message, because the attempt itself
was never made. This is recorded explicitly rather than glossed over: **an unattempted dispatch and
a rejected dispatch are not the same fact**, and reporting the former as the latter would itself be
the vacuity this phase exists to remove. No static assertion is presented anywhere in this file as a
substitute for the runtime observation the plan asks for.

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

Whoever runs this must update this section — replacing "PENDING" with "TAKEN" and filling in the run
URL, run id, the quoted per-job conclusion, the quoted record-missing message, and the confirmed
job list — before ROADMAP Success Criterion 2 for Phase 173 is considered met. Until then, **Success
Criterion 2 is explicitly NOT satisfied by this file** — it is pending a maintainer action named
above, and no phase-close verifier may read this file as satisfying it on the strength of the static
fixtures landed in Task 1 alone.

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
