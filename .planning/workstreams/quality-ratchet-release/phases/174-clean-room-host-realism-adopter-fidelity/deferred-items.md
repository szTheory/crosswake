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

## Deferred — `.planning/WINDOWS.md`'s frontmatter counts disagree with its entry list

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
