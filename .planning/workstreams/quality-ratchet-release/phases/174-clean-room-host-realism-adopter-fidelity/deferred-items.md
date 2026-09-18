# Deferred items — Phase 174

Out-of-scope discoveries logged here per the executor's scope-boundary rule.

## RESOLVED — 9 `test/crosswake/proof` failures were introduced by plan 174-04, not pre-existing

**Status: fixed in-phase. `mix test test/crosswake/proof --max-cases 1` → 729 tests, 0 failures.**

Plan 174-05 recorded 9 failing CI-workflow-policy tests as "pre-existing," having reproduced
them at commit `bdc216b6` in a disposable worktree. That baseline was plan 174-04's own tip
commit, which already contained `.github/workflows/clean-room-proof-rehearsal.yml`, so the check
established "not caused by 174-05" rather than "not caused by Phase 174." (174-05 did correctly
name the new workflow as the most plausible cause; it did not pursue it, per its scope boundary.)

**Control run that settled it (orchestrator, 2026-09-18):** removing only
`.github/workflows/clean-room-proof-rehearsal.yml` from the working tree took the suite from
**9 failures to 4**, and those 4 were plan 174-04's own `Phase174CleanRoomLaneParityTest`
correctly going red at the absence of the workflow it polices. All 9 policy failures trace to
the new file. An earlier full-suite run in this phase, taken before 174-04 landed, was
1927 tests / 0 failures — consistent with introduction rather than inheritance.

**Root cause**, quoted from the failing assertion in `script/check_ci_leaf_manifest.py`:

```
FAIL: dynamic-authority - .github/workflows/clean-room-proof-rehearsal.yml
(clean-room-proof-rehearsal): display name
'Clean-room proof rehearsal — ${{ inputs.package }}@${{ inputs.version }}' is expression-bearing
  What to do next: replace it with one stable literal name before making it required.
```

The repo's CI leaf-manifest policy forbids an expression-bearing display name on a workflow that
could become a required check: a required check whose name varies per run cannot be bound to a
stable context.

**Fix applied** — the remedy the policy itself prescribes, at the source rather than at the
check: the job's `name:` is now the stable literal `Clean-room proof rehearsal`. Package and
version remain visible via the step's `REHEARSAL_PACKAGE` / `REHEARSAL_VERSION` env. The policy
test was NOT modified — weakening a check to turn a run green is prohibited by 174-04's own plan.

**Verification:** `actionlint` exit 0; `test/crosswake/proof` 729 tests / 0 failures.

**Lesson for the vacuity taxonomy (plan 174-06):** this is the workstream's central defect in
mirror image. "Absence scored as success" is a check green while asserting nothing; here a check
went correctly red and was reclassified as inherited. Same net effect — a true signal discarded.
It survived plan-level verification because that verification asked whether the plan's own test
files passed, not whether the tree did. A plan's verification step should run the suite the
plan's artifacts can affect, not only the files it authored.

## RESOLVED — `.planning/WINDOWS.md`'s frontmatter counts disagreed with its entry list

**Status: fixed by the phase-close orchestrator (commit `eadf9ffe`). `gsd-tools windows status` now
reports `ok: true` at 34/34.** The original record follows, unmodified.

The cause was not a stale count alone: `.planning/WINDOWS.md` carries **two** representations of
the same ledger — a markdown table and a ```` ```json ```` block, and `gsd-tools` parses the JSON.
Entry 34 existed only in the JSON block, so a grep of the table found 33 rows and agreed with the
frontmatter, which made the drift look like a phantom. The fix inserted the missing table row and
bumped `open_count`/`total_count` from 33 to 34. Note also that the 34 open entries are a quality
backlog, not a hard gate — `workflow.windows_enforce` is `false`.

**Original record, as written by plan 174-06:**

**Status: not fixed. Not in this plan's `files_modified` scope (only `174-NON-VACUITY.md` and
`REQUIREMENTS.md`), and `.planning/WINDOWS.md` is a repository-root shared artifact this plan has
no mandate to edit.**

Discovered 2026-09-18 while attempting `gsd-tools windows append` to record Finding A (the
unguarded SC#4 measurement, see `174-NON-VACUITY.md`) in the cross-phase defect register. The
command failed with:

```
Error: Ledger counts disagree with entries: frontmatter open/waived/fixed/total=33/0/0/33 but
entries yield 34/0/0/34.
```

`.planning/WINDOWS.md`'s frontmatter (`open_count: 33`, `total_count: 33`) has not been updated
since entry #34 (Phase 173's `record-ledger`/XPUB-05 finding) was appended — the entry list already
has 34 rows. This is a pre-existing drift from a prior phase's ledger write, not something this
plan introduced, and fixing it would mean editing a file outside this plan's declared scope.
Finding A is therefore recorded in `174-NON-VACUITY.md` only, not in `.planning/WINDOWS.md` — the
ledger append is best-effort per the executor's own protocol, and this failure does not block this
plan's completion. Whoever next touches `.planning/WINDOWS.md` (likely Phase 175's own record, or
a dedicated ledger-repair pass) should reconcile the frontmatter counts before appending further.


## RESOLVED — Finding A: the SC#4 marker measurement was asserted by nothing on disk

**Status: fixed by the phase-close orchestrator, 2026-09-18.**

`174-NON-VACUITY.md` recorded Finding A as deliberately not patched, for a decidable reason: the
legacy path's own CI log could not be captured until `clean-room-proof-rehearsal.yml` merged to the
default branch. Writing a guard before both halves of the comparison existed would have asserted a
false completeness or fabricated the missing half.

That dependency resolved. The post-merge dispatch (run `35366337182`) produced
`evidence/174-rindle-ci-run.log`, so the comparison became measurable — at which point the finding's
reason changed from "pending a real dependency" to "measurable and simply not wired into a test,"
and it was closed.

`test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` went 6 tests → 10: a non-emptiness
gate on both logs that runs before any comparison, the SC#4 count comparison itself, a set-equality
check against the `LEGACY_STEP_MARKERS` roster read out of `script/verify_companion_cleanroom.sh`
(an independent source), and a D-14 non-vacuity control. Demonstrated red by three mutations against
the real evidence files and restored byte-identical. Full detail, including the mutation table, is
under "Closure (2026-09-18)" in [`174-NON-VACUITY.md`](174-NON-VACUITY.md).
