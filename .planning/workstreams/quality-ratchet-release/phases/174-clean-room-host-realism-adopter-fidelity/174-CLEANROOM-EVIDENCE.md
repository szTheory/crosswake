# Phase 174 Plan 4: Clean-Room Proof Rehearsal — Real-Run Evidence

This file records what actually happened when Task 3 attempted to run the clean-room proof
rehearsal against live `crosswake_rindle 0.1.0` in CI, and the marker-parity measurement that
depends on it. Per this milestone's rule, a criterion left unstated must never be readable as
satisfied — every section below states an explicit **satisfied** or **not-satisfied / pending**
verdict; none is left to be inferred.

## SC#3 — the clean-room proof has actually executed in CI, recorded by run id and job conclusion

**Verdict: SATISFIED — closed 2026-09-18 by a real post-merge dispatch.**

> **CLOSED.** PR #184 merged to `main` as `bb570820`, putting
> `clean-room-proof-rehearsal.yml` on the default branch and removing the platform restriction
> recorded below. The dispatch was then re-run and succeeded:
>
> ```
> gh workflow run clean-room-proof-rehearsal.yml --ref main \
>   -f package=crosswake_rindle -f version=0.1.0 \
>   -f engine_package=rindle -f engine_module=Rindle
> ```
>
> | Field | Value |
> |---|---|
> | Run id | `35366337182` |
> | URL | https://github.com/szTheory/crosswake/actions/runs/35366337182 |
> | Job | `Clean-room proof rehearsal` |
> | Job conclusion | `success` (read from the run, not inferred) |
> | Package under test | live published `crosswake_rindle 0.1.0` from hex.pm |
> | Captured log | `evidence/174-rindle-ci-run.log` (1270 lines) |
>
> Final harness line from that log, verbatim:
>
> ```
> [crosswake] OK: verify_companion_cleanroom: package=crosswake_rindle version=0.1.0 \
> core_floor=~> 0.2 selected_core=0.2.1 profile=engine-present state=passed
> ```
>
> The `mix crosswake.install` step (Step 6.5, added by plan 174-01 and never previously exercised
> in CI — the Info finding IN-01 in `174-REVIEW.md`) executed and passed, at log line 1108,
> genuinely before `step=doctor` at line 1234.
>
> The original pending record is preserved below, unaltered, because it is the honest account of
> what was true during the phase.

**Original verdict during phase execution: NOT SATISFIED — PENDING POST-MERGE OBSERVATION.**

`clean-room-proof-rehearsal.yml` is a new `workflow_dispatch` workflow added on this feature
branch (`phase-174-clean-room-host-realism`), which has never been pushed to `szTheory/crosswake`
on GitHub (this execution session ran with no push authority — see the executor's hard
constraints). GitHub does not dispatch a `workflow_dispatch` workflow that does not exist on the
repository's default branch, regardless of the `--ref` supplied to the dispatch command. This is
the documented, expected obstacle (Phase 173 precedent, `173-NON-VACUITY.md`), not a defect in
this plan's work.

### Dispatch attempt 1 — verbatim command and verbatim refusal

Command run:

```bash
gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism \
  -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle
```

Verbatim output:

```
HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch (https://api.github.com/repos/szTheory/crosswake/actions/workflows/clean-room-proof-rehearsal.yml)
```

Exit code: `1`.

No run id was created — the dispatch never reached the point of creating a workflow run at all,
so there is nothing to read a job-level conclusion from. Per `173-NON-VACUITY.md`'s standard, an
absent job list is never read as "not skipped" — there being no run at all is stated as exactly
that, not glossed as a near-pass.

### Read-only search for an already-existing real run

Before concluding, this task searched for any already-existing real run of the clean-room lanes
whose log could legitimately be captured instead. `gh run list --workflow=release-please.yml
--limit 60` was inspected: every `clean-room-proof-*` job across all 60 most recent runs (spanning
2026-07-29 through 2026-09-18) reports `conclusion: "skipped"` — none has ever executed, because
no run in that window created a component release that satisfies the job's
`${component}_release_created == 'true'` gate. This matches `TODO-011`'s recorded finding
verbatim ("the companion clean-room lane has been green at zero of three releases inspected") and
extends it: it has been *skipped* at every release-please run inspected, not merely non-green.
There is no historical real run to substitute for a fresh dispatch.

### What is required to close this out

Once this branch merges to `main` (making `clean-room-proof-rehearsal.yml` visible to
`workflow_dispatch` on the default branch), re-run:

```bash
gh workflow run clean-room-proof-rehearsal.yml --ref main \
  -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle
```

then read the **job-level** conclusion (not only the run's top-level conclusion) via:

```bash
gh run list --workflow=clean-room-proof-rehearsal.yml --limit 1 --json databaseId
gh run view <run-id> --json jobs --jq '.jobs[] | {name, conclusion}'
```

and update this section with the real run id, its URL, the job conclusion, and the satisfied /
not-satisfied verdict, before ROOM-03 can be marked closed.

## SC#4 — `step=` marker granularity parity between the legacy and matrix paths, measured from captured logs

**Verdict: SATISFIED — closed 2026-09-18. Both sides are now measured from captured CI logs.**

> **CLOSED.** The SC#3 dispatch above produced the missing legacy-path CI log, so the comparison
> SC#4 actually asks for — grep two captured CI logs, do not read the script — is now possible
> and has been performed:
>
> | Path | Captured log | Distinct `step=` markers | Roster |
> |---|---|---|---|
> | legacy positional | `evidence/174-rindle-ci-run.log` (run `35366337182`) | **9** | compile, deps, doctor, generate, install, metadata, register, router, smoke |
> | matrix | `evidence/174-matrix-ci-run.log` (run `35324177344`) | **6** | build, dry-run, generate, install-generator, normalize, official-unpack |
>
> Measurement command, run unpiped against each file:
> `grep -oE 'step=[a-z0-9-]+' <log> | sort -u | wc -l`
>
> **9 ≥ 6** — the legacy roster's granularity is finer than the matrix roster's, satisfying the
> criterion. Both counts come from real captured CI logs; neither was read off the script.
>
> The original partially-measured record is preserved below, unaltered.

**Original verdict during phase execution: PARTIALLY MEASURED — matrix side is real-CI-log-backed;
legacy side's CI-log requirement is PENDING the same post-merge dispatch as SC#3, for the same
root cause.**

SC#4 asks for the parity measurement to be made by grepping two **captured CI logs**, not by
reading the script. The matrix path runs routinely in ordinary CI (`crosswake-ci.yml`'s
`release-candidate-full-proof` job runs on every PR), so a real captured CI log for it was
available immediately. The legacy positional path only ever runs in CI inside the
`clean-room-proof-*` release-lane jobs — which, per the SC#3 section above, have never executed a
single time in this repository's history — or inside this plan's not-yet-mergeable rehearsal
workflow. There is therefore no real CI log of the legacy path to capture yet, for the identical
structural reason SC#3 is pending, not a separate defect.

### Matrix path — real captured CI log

Source: `crosswake-ci.yml` run
[35324177344](https://github.com/szTheory/crosswake/actions/runs/35324177344), job
`release-candidate-full-proof` (job id `105533330884`), conclusion `success`, captured
2026-09-18 via:

```bash
gh run view --job=105533330884 --log > \
  .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-matrix-ci-run.log
```

`grep -c 'step=' evidence/174-matrix-ci-run.log` → **30** matching lines.

Distinct `step=` marker names found (`grep -o 'step=[a-zA-Z_-]*' evidence/174-matrix-ci-run.log |
sort -u`):

```
step=build
step=dry-run
step=generate
step=install-generator
step=normalize
step=official-unpack
```

**Matrix roster: 6 distinct markers** (`build`, `dry-run`, `generate`, `install-generator`,
`normalize`, `official-unpack`).

### Legacy path — CI log not obtainable yet; local real-run log recorded for context only

No captured CI log of the legacy positional path exists (see SC#3). The committed
`evidence/174-legacy-rindle-local-run.log` (from Plan 174-01, real run against live published
`crosswake_rindle 0.1.0`, executed locally rather than in CI) is the closest available real
evidence and is recorded here **only as directional context, explicitly not counted toward this
criterion's stated method** ("measured by grepping the two captured logs" means two *CI* logs):

`grep -c 'step=' evidence/174-legacy-rindle-local-run.log` → 9 matching lines. Distinct markers:
`compile`, `deps`, `doctor`, `generate`, `install`, `metadata`, `register`, `router`, `smoke` — 9
distinct markers, matching the `LEGACY_STEP_MARKERS` roster declared in
`script/verify_companion_cleanroom.sh` and independently asserted in
`test/crosswake/proof/phase174_cleanroom_host_realism_test.exs`.

If this local-run count is read informally against the matrix's real CI count: 9 >= 6, i.e. the
legacy roster would satisfy granularity parity. This is **not** a substitute for the criterion's
required method and is not scored as a satisfied verdict for SC#4 — it is recorded so the pending
determination is not read as "unknown direction," only "not yet measured the way this criterion
requires."

### What is required to close this out

Once the SC#3 post-merge dispatch (above) produces a real
`evidence/174-rindle-ci-run.log`, grep it for `step=`, record its distinct marker roster and
count here, and state the final comparative verdict (legacy count >= matrix count, both counted
from real captured CI logs) explicitly.

## Every dispatch attempt, red or not

| # | Command | Result |
|---|---|---|
| 1 | `gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle` | `HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch` — no run created |
| 2 | `gh workflow run clean-room-proof-rehearsal.yml --ref main -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle` (2026-09-18, after PR #184 merged as `bb570820`) | **Accepted.** Run `35366337182`, job `Clean-room proof rehearsal`, conclusion `success`. Log captured to `evidence/174-rindle-ci-run.log`. |

No `script/verify_companion_cleanroom.sh` edit was made in this task: the refusal is a GitHub
platform-level restriction on dispatching a not-yet-merged `workflow_dispatch` workflow, not a
harness defect. Task 3b's harness-repair path does not apply here.
