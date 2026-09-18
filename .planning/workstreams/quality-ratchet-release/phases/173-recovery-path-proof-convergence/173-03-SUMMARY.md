---
phase: 173-recovery-path-proof-convergence
plan: 03
subsystem: release-candidate-proof
tags: [elixir, github-actions, workflow_call, release-ledger, jsonl, durability, mutation-testing]
status: complete

# Dependency graph
requires:
  - phase: 173-recovery-path-proof-convergence
    plan: 01
    provides: one reusable exact-public proof body, both lanes calling it, the record emitter idiom
  - phase: 173-recovery-path-proof-convergence
    plan: 02
    provides: the two-graph checker fixtures and the replace_in_job no-op guard
provides:
  - "script/append_release_ledger.sh — the one append-only, idempotent writer of the exact-public proof verdict"
  - "docs/release-ledger/RELEASE-LEDGER.jsonl — the committed copy of record, seeded with three real past releases and a declared backfill boundary"
  - "exact-public-proof.yml record-ledger job — always-runs, applicable-only, continue-on-error, bot-opened pull request with release-as-cleanup's duplicate guard"
  - "Crosswake.ReleaseCandidate.ReleaseLedgerTest — 9 tests: git-show read-back, schema with pinned cardinality, idempotency, append-only ordering, per-field exit codes"
  - "the fail-closed rollup combination the suite never constructed: a skipped exact-public proof beside five successes"
affects: [173-04, 174]

# Actuals (#2632)
actuals:
  tokens: 11206
  tasks: 3
  commits: 5
plan_head_before: ee032ad0

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A JSON Lines ledger committed to git as the copy of record, because on a PUBLIC repository
      no artifact retention value reaches the project's horizon — durability is a property of the
      storage medium, not a number to be tuned."
    - "Durability proven by a MEASURED PAIR about one real run — the artifact copy reports
      expired: true, the ledger copy reads back through git show — rather than by the
      architectural argument that git has no expiry."
    - "A git read-back executed from a scratch cwd in which the file's absence is ASSERTED, so a
      fall-through to the working-tree copy is impossible rather than merely unlikely."
    - "Cardinality pinned at the assertion site: every collection assertion is written as
      `count(conforming) == count(all)` with a lower bound on `count(all)`, so an emptied ledger
      fails instead of passing vacuously."
    - "A closed outcome vocabulary (success/failure/cancelled/skipped) rather than free text, so
      'the proof failed' and 'the proof never ran' cannot converge on one value."
    - "A bookkeeping step marked continue-on-error so it can never veto a release, paired with a
      closing always()-step that reports its real outcome — the failure is defanged, not hidden."
    - "A permission asserted BY VALUE rather than by substring, so a strictly wider grant does not
      turn the check red in the wrong direction, while absence and `none` still do."

key-files:
  created:
    - script/append_release_ledger.sh
    - docs/release-ledger/RELEASE-LEDGER.jsonl
    - test/crosswake/release_candidate/release_ledger_test.exs
  modified:
    - .github/workflows/exact-public-proof.yml
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - test/crosswake/release_candidate/workflow_test.exs
    - test/crosswake/proof/phase173_recovery_proof_convergence_test.exs

decisions:
  - "Both caller jobs gained contents: write / pull-requests: write. A called workflow narrows the caller's token and can never widen it, so the ledger job could not otherwise commit or open a pull request. The proof body keeps its own read-only permissions block, so the grant cannot reach it."
  - "The ledger job lives in exact-public-proof.yml as a SEPARATE job downstream of the proof rather than a final step inside it, so the proof body's job-level permissions stay read-only and the write scope is bounded to the job that needs it."
  - "The record-ledger job is gated on the proof's new `applicable` output, not on its result. A push that is not a linked release has no verdict, and writing a row for it would invent a release event; a FAILING proof, by contrast, is exactly the row most worth having."
  - "The ledger's `ref` field is populated from the reusable workflow's existing `merge_oid` input (a 40-hex SHA is an accepted ref form for the record emitter), so no new workflow input and no further caller edits were required."
  - "All three backfilled rows are non-success. That is this repository's actual history — no post-publish proof lane recorded a passing verdict for any release with expired artifacts — and the header says so explicitly so a reader cannot mistake the absence for a writer that cannot record success."

metrics:
  duration: ~70 min (resumed session)
  completed: 2026-09-17
---

# Phase 173 Plan 03: Fail-Closed Rollup + A Ledger That Does Not Expire — Summary

The two criteria that are not about the graph are closed. The rollup's fail-closed semantics are
proven against the combination the suite could never construct — a *skipped* exact-public proof
beside five successes — with `workflow.ex` byte-unchanged, because the criterion is that those
semantics survived the graph change, not that they were built. And the proof's verdict now has a
home that does not expire: a committed JSON Lines ledger, written by the same workflow that reaches
the verdict, landing through a bot-opened pull request because `main` is protected.

Durability is recorded here as **two measured facts about one real run**, not as the architectural
observation that git has no expiry.

## Commits

| Task | Commit | What |
|---|---|---|
| 1 | `5132e9ca` | the fail-closed case the suite could never construct |
| 2 | `c3eb7cdd` | the ledger, its writer, the record-ledger job, both caller grants |
| — | `2327ba0e` | caller `contents:` grant asserted by value, not by substring |
| 3 | `20c8bd32` | durability proven by measurement — `git show` read-back, schema, idempotency |
| — | `2d4f73f9` | 173-02's permissions negative control re-aimed at the current grant shape |

## Task 1 — the missing fail-closed case (`5132e9ca`, executed before this session's resume)

Landed by the previous executor and verified byte-for-byte on resume rather than redone. Four named
tests were added to `test/crosswake/release_candidate/workflow_test.exs` (+118 lines, test-only):

- `a skipped exact-public proof beside five successes still rolls up not-complete`
- `a skipped exact-public proof is not distinguished from a failed one`
- `no accepted non-success status for the exact-public child ever yields COMPLETE`
- `the rollup still depends on the exact-public proof job and still reads its result`

The first is built **directly**, not folded into the existing every-child loop, because that loop
marks everything after the failed child as skipped and therefore can never reach this shape —
burying the case inside it would have hidden that fact. The third sweeps the whole accepted
non-success set and additionally asserts that everything outside the set is rejected, so the sweep
is exhaustive rather than a sample. The fourth pins the rollup's eight `needs:` entries and the
result read, guarding the edge that converting the proof job into a reusable-workflow caller could
have severed.

Verified on resume:

```
$ mix test test/crosswake/release_candidate/workflow_test.exs
23 tests, 0 failures

$ git diff --stat ee032ad0 HEAD -- lib/crosswake/release_candidate/workflow.ex
(no output)
```

Per the resume instruction, Task 1's own mutation proofs were **not** re-run in this session; they
are recorded in `5132e9ca`'s message. The unchanged-module criterion was re-measured above and
still holds at the end of the plan.

## Task 2 — a ledger the artifact store cannot take away (`c3eb7cdd`)

**`script/append_release_ledger.sh`.** Validates with the same `^[0-9a-f]{40}$` head pattern, the
same semver pattern and the same closed lane list as `script/write_publication_record.sh`, plus a
closed outcome vocabulary and a positive-integer run id. Every field is validated *before* the file
is touched, so a rejected entry never leaves a partial line behind — asserted by the test, which
checks the ledger file was not even created by a rejected call. One distinct exit code per rejected
field (3 head, 4 version, 5 lane, 6 outcome, 7 run id), so a caller's log names *which* field was
wrong. Append-only, and idempotent on `(package, version, approved_head, run_id)` because a re-run
of a failed job is this pipeline's normal recovery motion.

The outcome field records `failure`, `cancelled` and `skipped` as faithfully as `success`. A
pass-only ledger could not distinguish "the proof failed" from "the proof never ran" — the exact
equivalence this milestone exists to break.

**`docs/release-ledger/RELEASE-LEDGER.jsonl`.** Seeded with three rows, every field taken from a
real GitHub Actions run record, none invented:

| run id | date | coordinate | outcome | source of the outcome |
|---|---|---|---|---|
| 28675522926 | 2026-07-03 | crosswake 0.2.0 | `skipped` | no post-publish proof job of any kind ran in that run — literally "the proof never ran" |
| 28691886814 | 2026-07-04 | crosswake_chimeway 0.1.0 | `failure` | job "Clean-room proof — crosswake_chimeway resolvability + doctor" |
| 31325689640 | 2026-08-09 | crosswake_sigra 0.1.3 | `failure` | job "Clean-room proof — crosswake_sigra resolvability + doctor" |

The header declares `backfill_boundary_run_id=31325689640` and, because GitHub run ids increase
monotonically, the backfilled/live classification is decidable for every line — asserted by a test
that fails on any row whose `run_id` will not parse as an integer. The header also records the
per-row provenance above, so no backfilled row claims an exact-public proof job that did not exist
at the time.

**The `record-ledger` job.** Added to `.github/workflows/exact-public-proof.yml` as a separate job
downstream of the proof, `if: always() && needs.exact-public-proof.outputs.applicable == 'true'`
(the proof job publishes a new `applicable` output for this). It appends the verdict, then commits
on a run-scoped branch and opens a pull request following `release-as-cleanup` step for step —
same bot identity, same run-scoped branch name, and the same REST-list duplicate guard that exists
because cleanup pull requests #65/#68/#72 once accumulated. No direct push to the protected default
branch is attempted (T-173-13). The write step is `continue-on-error: true` so bookkeeping can never
veto a release (T-173-14), and a closing `always()` step writes the step's real outcome into
`$GITHUB_STEP_SUMMARY` with recovery instructions, so a ledger that quietly stops being written is
visible on the run page rather than swallowed.

**No retention was tuned.** The only `retention-days` string anywhere in this plan's diff is inside
a comment explaining why raising it is not the mechanism:

```
$ git diff -U0 | grep -n 'retention-days'
17:+  # `retention-days` — on a public repository no retention value reaches this
```

Verify block:

```
$ shellcheck script/append_release_ledger.sh        # exit 0, no findings
$ actionlint .github/workflows/exact-public-proof.yml .github/workflows/release-please.yml .github/workflows/hex-publish.yml
ACTIONLINT_OK
$ while IFS= read -r line; do ... json.loads ... done < docs/release-ledger/RELEASE-LEDGER.jsonl
JSON_OK
```

## Task 3 — durability proven by measurement (`20c8bd32`)

`test/crosswake/release_candidate/release_ledger_test.exs`, 9 tests, on the default hermetic lane
(no tags, no network). It invokes the real script through `System.cmd/3` and reads the real
committed file; it never greps the script's source, because a source-grep cannot tell a script that
appends from one that merely contains the word "append".

The read-back runs `git --git-dir=<repo>/.git show <commit>:docs/release-ledger/RELEASE-LEDGER.jsonl`
from a scratch directory, with `refute File.exists?(Path.join(elsewhere, @ledger))` asserted first
(T-173-12). Deleting the repository's real copy inside a test would be a destructive act a test must
never perform; an empty cwd proves the same thing and the absence is asserted rather than assumed.

### SC#4 — the four measured facts

**Fact 1 and 2 — the run and its date.** Run `31325689640`, created `2026-08-09T17:10:08Z`,
`chore(main): release crosswake_sigra 0.1.3 (#118)`, head
`70edb8077894fd09d4376591782b511c9d8be664`:

```
$ gh api repos/szTheory/crosswake/actions/runs/31325689640 --jq '{id,created_at,conclusion,display_title,head_sha}'
{"conclusion":"failure","created_at":"2026-08-09T17:10:08Z","display_title":"chore(main): release crosswake_sigra 0.1.3 (#118)","head_sha":"70edb8077894fd09d4376591782b511c9d8be664","id":31325689640}
```

**Fact 3 — that run's uploaded artifacts are measurably expired.**

```
$ gh api repos/szTheory/crosswake/actions/runs/31325689640/artifacts \
    --jq '{total_count, artifacts: [.artifacts[] | {name,expired,created_at,expires_at}]}'
{"artifacts":[{"created_at":"2026-08-09T17:13:09Z","expired":true,"expires_at":"2026-08-23T17:13:09Z","name":"native-release-status"}],"total_count":1}
```

1 of 1 artifact for that run reports `"expired": true`; it expired on 2026-08-23, 25 days before
this measurement. The artifact copy of that run's evidence is gone.

**Fact 4 — the same run's ledger line, read back through git.**

```
$ cd /tmp && git --git-dir=/Users/jon/projects/crosswake/.git \
    show c3eb7cdd9d7e8e948bd2e7635f3f6da55918c81e:docs/release-ledger/RELEASE-LEDGER.jsonl | grep 31325689640
{"schema_version":"1.0.0","package":"crosswake_sigra","version":"0.1.3","approved_head":"70edb8077894fd09d4376591782b511c9d8be664","ref":"refs/tags/crosswake_sigra-v0.1.3","lane":"ordinary","run_id":"31325689640","outcome":"failure","recorded_at":"2026-09-18T00:30:56Z"}
```

Two facts, one run: **artifacts 1/1 expired, ledger line 1/1 readable.** The criterion is satisfied
by measurement, not by waiting and not by the architectural argument.

### Recorded mutations (non-vacuity, per VERIFICATION-CONVENTIONS.md)

**M1 — drop a required key from one committed ledger line.** `lane` removed from the first data
line; the schema test went red, naming the count:

```
1) test the committed ledger's shape every non-comment line parses as JSON and carries exactly the required key set
   1 of 3 ledger lines are not JSON objects carrying exactly ["approved_head", "lane", "outcome",
   "package", "recorded_at", "ref", "run_id", "schema_version", "version"]
9 tests, 1 failure
```

Reverted from a scratchpad copy; `git status --porcelain` on the ledger returned empty afterwards.

**M2 — make the writer overwrite rather than append** (`printf ... >> "$LEDGER"` → `>`). Three
tests went red:

```
1) test the writer appending the same run twice leaves one line        left: 1  right: 2
2) test the writer an earlier line is never rewritten by a later append  left: 1  right: 2
3) test the writer a failing verdict is written as faithfully as a passing one  left: 1  right: 4
9 tests, 3 failures
```

Reverted; the suite returned to 9 tests, 0 failures.

**M3 — drop `pull-requests: write` from release-please.yml's proof caller** (proving the new
value-based permission assertion is not vacuous):

```
1) test every caller of the reusable exact-public proof grants actions: read at job level
   .github/workflows/release-please.yml job exact-public-proof grants contents: write without
   pull-requests: write; the ledger job needs both or neither
```

Reverted.

## Deviations from Plan

### 1. [Rule 3 — blocking] Both caller jobs needed `contents: write` / `pull-requests: write`

- **Found during:** Task 2b.
- **Issue:** A called workflow's `permissions:` can only NARROW the token the calling job hands it.
  Both callers declared `actions: read` / `contents: read`, so the `record-ledger` job could never
  have committed or opened a pull request — the ledger would have failed on every real release, and
  the plan's `key_links` chain (verdict → script → file → bot-opened PR) would never have closed.
- **Fix:** Added `contents: write` and `pull-requests: write` to `exact-public-proof` in
  `release-please.yml` and `recovery-exact-public-proof` in `hex-publish.yml`, with a comment at
  each site explaining that the grant exists for the ledger job alone. The proof body keeps its own
  `actions: read` / `contents: read` job-level block, which narrows the token straight back down, so
  the write scopes never reach the proof steps (T-173-02 / T-173-15 intent preserved).
- **Files modified:** `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`.
- **Commit:** `c3eb7cdd`.

### 2. [Rule 1 — bug] 173-01's caller-permission assertion failed on a strictly wider grant

- **Found during:** Task 2, at `mix test test/crosswake/release_candidate`.
- **Issue:** `assert block =~ "contents: read"` went red against `contents: write`, which *includes*
  read. A permission check that fails on a wider grant fails in the wrong direction.
- **Fix:** Read the `contents:` value with a regex and assert it is `read` or `write`; absent,
  `none` or a typo still fail, so this is not a weakening. Added a paired assertion: a `write` grant
  must be accompanied by `pull-requests: write`, because the only reason a caller of a read-only
  proof body holds write is the ledger's pull request — privilege nothing uses is privilege nobody
  notices. Mutation-proven (M3 above).
- **Files modified:** `test/crosswake/release_candidate/workflow_test.exs`.
- **Commit:** `2327ba0e`.

### 3. [Rule 1 — bug] 173-02's permissions negative control became a no-op

- **Found during:** the full `mix test test/crosswake/proof --max-cases 1` run.
- **Issue:** The control mutates the recovery caller by stripping `actions: read` from the literal
  block `permissions:\n actions: read\n contents: read\n`. Deviation 1 changed that literal, so the
  mutation matched nothing. 173-02's `replace_in_job/4` guard caught it and said so out loud —
  "The mutation would be a no-op, so the negative control would assert nothing" — rather than
  letting the control pass green and empty.
- **Fix:** Re-aimed the control's literals at the current grant shape. The control still strips
  `actions: read` and still requires the identity check to go red naming it; only the surrounding
  text moved. The control was NOT deleted, exactly as the guard's own message instructs.
- **Files modified:** `test/crosswake/proof/phase173_recovery_proof_convergence_test.exs`.
- **Commit:** `2d4f73f9`.

### 4. [Rule 3 — blocking] `grep` exit status killed the writer on an empty ledger

- **Found during:** Task 2c, seeding the ledger.
- **Issue:** The idempotency filter piped `grep -v '^#'` under `set -euo pipefail`; a ledger holding
  only the header comment produced no data lines, `grep` exited 1, and the script died before
  writing its first entry.
- **Fix:** Guarded each filter with `|| true` and a comment stating that an all-comment ledger is an
  empty data set, not an error. Verified by seeding the file from empty.
- **Commit:** `c3eb7cdd` (fixed before the commit).

## Authentication Gates

None. The `gh api` reads used for the SC#4 measurement were read-only network calls against public
endpoints; they published nothing and changed nothing.

## Known Stubs

None. Every artifact this plan names is wired to a caller: the script is invoked by the
`record-ledger` job and by the test suite, the ledger holds three real rows, and every test
assertion was demonstrated falsifiable by a recorded mutation.

## Threat Flags

None. The plan's register covers the surface this plan added (T-173-10 outcome faithfulness,
T-173-12 the working-tree fall-through, T-173-13 the protected-branch pull-request path, T-173-14
the ledger vetoing a release / duplicate pull requests). Deviation 1 widens two caller jobs' tokens;
it is in scope for T-173-13 and is bounded by the proof body's own read-only block, asserted by the
value-based permission test.

## Verification

```
$ mix test test/crosswake/release_candidate/release_ledger_test.exs
9 tests, 0 failures

$ mix test test/crosswake/release_candidate/workflow_test.exs
23 tests, 0 failures

$ mix test test/crosswake/release_candidate --max-cases 1
116 tests, 0 failures

$ mix test test/crosswake/proof --max-cases 1
701 tests, 0 failures (67 excluded)

$ git diff --stat ee032ad0 HEAD -- lib/crosswake/release_candidate/workflow.ex
(no output — the rollup module is byte-unchanged by this phase)

$ mix format --check-formatted
FORMAT_OK
```

## Success Criteria

- **ROADMAP SC#3** — holds against the modified graph, proven by the one combination the suite never
  constructed, with `lib/crosswake/release_candidate/workflow.ex` byte-unchanged (measured above).
- **ROADMAP SC#4** — satisfied by a committed ledger rather than a retention setting, and its
  independence from the artifact store is a measured pair of facts about run `31325689640`: the
  artifacts expired on 2026-08-23, the ledger line reads back from commit `c3eb7cdd` today.

## Not Done Here

No pull request was opened: plans 173-01 through 173-04 land together in ONE pull request, opened at
the end of 173-04 (`<atomicity_constraint>`). `STATE.md` and `ROADMAP.md` were deliberately not
touched in this session.

## Self-Check: PASSED

All four named artifacts exist on disk; all five commits (`5132e9ca`, `c3eb7cdd`, `2327ba0e`,
`20c8bd32`, `2d4f73f9`) resolve in `git log`.
