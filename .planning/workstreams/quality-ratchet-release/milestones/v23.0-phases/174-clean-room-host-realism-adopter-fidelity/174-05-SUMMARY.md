---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 05
subsystem: release-infra
tags: [clean-room, exunit, hex, elixir, doctor, diagnosis]

requires:
  - phase: 174-01
    provides: The repaired legacy clean-room harness (real router + metadata, Step 6.5
      `mix crosswake.install`) that this plan's threadline run depends on to reach doctor-green.
  - phase: 174-04
    provides: The confirmed unavailability of CI dispatch from this branch
      (174-CLEANROOM-EVIDENCE.md), which is why both runs in this plan are local invocations.
provides:
  - Two separately recorded root-cause findings for the threadline and sigra clean-room
    failures, each naming a distinct mechanism, each resting on a real run taken in this phase
  - A mechanical ExUnit check (Crosswake.Proof.Phase174CompanionFindingsTest) that discovers its
    required-findings roster from TODO-011's failure table (never the findings directory),
    demonstrated non-vacuous against a one-finding-removed fixture
  - TODO-011 updated with dated pointer lines to both findings and a "Current status" section,
    original failure table left intact
affects: [174-06]

actuals:
  tokens: 37192
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Git-history reconstruction as diagnosis evidence: when a companion's clean-room failure
      can no longer be reproduced with a live retention-expired CI log, reconstruct the exact
      prior harness commit, render its template with the real profile variables, and cite the
      diff commit that changed it — turns 'it passes now' into a named, git-cited mechanism
      instead of an assumption."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-THREADLINE.md
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-SIGRA.md
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-threadline-run.log
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-sigra-run.log
    - test/crosswake/proof/phase174_companion_findings_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/deferred-items.md
  modified:
    - .planning/todos/TODO-011-companion-cleanroom-lane-has-never-been-green.md

key-decisions:
  - "Both threadline and sigra were run at a single version each: threadline has only one Hex
    release (0.1.0), and sigra's 2026-08-09 failing run and 'current latest' are the same release
    (0.1.3) — the release-please failure ran against the version it had just published. No
    version-transition ambiguity existed for either companion, so one real run each sufficed."
  - "For threadline, named the mechanism by proving (via git show on the pre-174-01 commit) that
    the routeless-router Step 4/Step 7 sequence was unconditional across every companion profile
    — not by assuming the 174-01 rindle fix incidentally helped threadline. The finding states
    explicitly what it does NOT claim: the original 2026-07-03 log is unavailable, so a genuinely
    different original cause cannot be fully ruled out, only that the one class of failure this
    reasoning accounts for is independently verified fixed."
  - "For sigra, reconstructed the exact pre-fix harness (commit d3e914da) and rendered its
    no-engine smoke-test branch with PACKAGE=crosswake_sigra to locate TODO-011's cited
    'test/smoke_test.exs:21' precisely — it is the failing test's own definition line
    ('enabled?/1 respects config — false when no :enabled key'), whose body incorrectly refutes
    Sigra.enabled?(%{}) even though sigra defaults to enabled. Commit d16e475a (2026-08-09, same
    day as the failure) is the exact fix: it added sigra to the assert-true branch alongside
    chimeway. This is a different code path and a different commit than threadline's fix."
  - "check_findings_exist/2 takes phase_dir as a parameter rather than reading the module
    attribute directly, specifically so the non-vacuity fixture test can point the same function
    at a temp directory with one finding removed, rather than needing a second near-duplicate
    implementation for the fixture path."
  - "The exclusion rule in phase174_companion_findings_test.exs derives rindle's exclusion from
    TODO-011's own '## Root cause of the rindle failure' heading via regex, never a hardcoded
    'rindle' literal — a future companion TODO-011 diagnoses inline will drop out of the roster
    by the same rule, and a future undiagnosed row enters it automatically."
  - "9 pre-existing failures in the wider test/crosswake/proof suite (unrelated CI-workflow-policy
    tests) were confirmed pre-existing via a disposable git worktree checkout of the pre-plan
    baseline commit, then logged to deferred-items.md rather than fixed — out of this plan's
    scope boundary."

patterns-established: []

requirements-completed: [ROOM-05]

coverage:
  - id: D1
    description: "Threadline's clean-room failure has its own separately recorded root-cause
      finding, resting on a run taken in this phase, naming the mechanism rather than assuming a
      backport fixed it"
    requirement: "ROOM-05"
    verification:
      - kind: other
        ref: "evidence/174-threadline-run.log (785 lines, real local run, exit 0, doctor-green,
          4/4 smoke tests) + 174-FINDING-THREADLINE.md's named mechanism, cited against
          d04397a4~1:script/verify_companion_cleanroom.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sigra's clean-room failure has its own separately recorded root-cause finding,
      distinct from threadline's, naming the specific failing assertion (file, generated line,
      what it asserted)"
    requirement: "ROOM-05"
    verification:
      - kind: other
        ref: "evidence/174-sigra-run.log (573 lines, real local run, exit 0, doctor-green, 4/4
          smoke tests) + 174-FINDING-SIGRA.md's line-21 reconstruction against d3e914da, fix
          cited at commit d16e475a"
        status: pass
    human_judgment: false
  - id: D3
    description: "The requirement that both findings exist and name distinct root causes is
      checked mechanically, with the roster derived from TODO-011's table rather than the
      findings directory, demonstrated non-vacuous"
    requirement: "ROOM-05"
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase174_companion_findings_test.exs — 7 tests, 0
          failures"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-09-18
status: complete
---

# Phase 174 Plan 5: Companion Clean-Room Findings — Threadline and Sigra Diagnosed Independently Summary

**Threadline and sigra both now pass the clean-room harness in a real run taken this phase — and
each has its own root-cause finding naming a distinct, git-cited mechanism (a shared
manifest_contract defect for threadline, a package-unaware smoke-test template branch for
sigra), checked against a roster read from TODO-011, never from the findings directory itself.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-09-18T13:55:00Z (approx.)
- **Completed:** 2026-09-18T14:18:41Z
- **Tasks:** 3/3 completed
- **Files modified:** 7 (2 findings, 2 evidence logs, 1 new test, 1 TODO update, 1 deferred-items log)

## Accomplishments

- Ran `script/verify_companion_cleanroom.sh crosswake_threadline 0.1.0` for real against the live
  published package (its only release): exit 0, doctor-green, 4/4 smoke tests. Wrote
  `174-FINDING-THREADLINE.md` naming the mechanism — the pre-174-01 harness's Step 4
  routeless-router-then-Step 7 doctor sequence was unconditional across every companion profile,
  so the `manifest_contract` failure TODO-011 root-caused for rindle would have reproduced
  identically for threadline; plan 174-01's fix (commit `d04397a4`) is likewise
  profile-independent and closed threadline's path through the same gate. The finding states
  plainly what it does not claim, since the original 2026-07-03 log is retention-expired.
- Ran `script/verify_companion_cleanroom.sh crosswake_sigra 0.1.3` for real against the live
  published package (the same version that failed on 2026-08-09): exit 0, doctor-green, 4/4
  smoke tests. Wrote `174-FINDING-SIGRA.md` naming a *different* mechanism — reconstructed the
  pre-fix harness commit (`d3e914da`) and rendered its no-engine smoke-test branch for sigra to
  locate TODO-011's cited `test/smoke_test.exs:21` exactly: the failing test's own definition
  line, whose body (`refute Sigra.enabled?(%{})`) contradicted sigra's real default-enabled
  behavior. Cited the exact fix commit, `d16e475a` (2026-08-09, same day as the failure), which
  added sigra to the assert-true branch alongside chimeway.
- Added `Crosswake.Proof.Phase174CompanionFindingsTest` (7 tests, 0 failures): discovers the
  three-row roster from TODO-011's failure table, asserts non-emptiness before filtering,
  excludes rindle via a regex match on TODO-011's own "Root cause of the rindle failure" heading
  (never a hardcoded literal), asserts the filtered roster equals exactly `["sigra",
  "threadline"]`, asserts both finding files exist and are not byte-identical, and demonstrates a
  one-finding-removed fixture fails and names the removed companion (manually re-verified by
  mutating `check_findings_exist/2` to always succeed, observing the fixture test go red, then
  restoring the file and re-confirming green).
- Updated `TODO-011` with dated pointer lines under the threadline and sigra rows and a "Current
  status" section recording that all three companions are now diagnosed, while the todo itself
  stays `open` pending the release lane's own CI green run. The original failure table is
  untouched.
- Confirmed `bash script/assert_manifest_contract_unchanged.sh` still exits 0 —
  `lib/crosswake/doctor/doctor.ex` was not touched by this plan.

## Task Commits

Each task was committed atomically:

1. **Task 1: Threadline — its own run, its own root cause, its own finding** — `5060314b` (docs)
2. **Task 2: Sigra — its own run, its own root cause, its own finding** — `710b8578` (docs)
3. **Task 3: The two findings cannot silently become one, or zero** — `ca3bd873` (test)

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-THREADLINE.md`
  — new finding, harness-side root cause, doctor-green.
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-SIGRA.md`
  — new finding, harness-side root cause (distinct mechanism), doctor-green.
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-threadline-run.log`
  — new captured real local run (785 lines).
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-sigra-run.log`
  — new captured real local run (573 lines).
- `test/crosswake/proof/phase174_companion_findings_test.exs` — new roster-completeness proof, 7
  tests.
- `.planning/todos/TODO-011-companion-cleanroom-lane-has-never-been-green.md` — dated pointer
  lines and a "Current status" section added; original table intact.
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/deferred-items.md`
  — new, logs 9 pre-existing (confirmed via baseline worktree) unrelated test failures.

## Decisions Made

See `key-decisions` in the frontmatter above — summarized: single-version runs for both
companions (no version-transition ambiguity existed), git-history reconstruction as the mechanism
for both findings rather than assumption, a parameterized roster-check function reused by both
the real check and its own non-vacuity fixture, and a derived (not hardcoded) exclusion rule for
rindle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `.tool-versions` not honored outside the monorepo — pinned ASDF env vars**
- **Found during:** Task 1, first invocation of the harness
- **Issue:** The harness creates its throwaway host in `$RUNNER_TEMP`/`/private/tmp`, outside
  this repo's `.tool-versions`, so `asdf exec mix ...` failed with "No version is set for
  command mix".
- **Fix:** Exported `ASDF_ELIXIR_VERSION=1.19.5-otp-27` and `ASDF_ERLANG_VERSION=27.3` (this
  repo's own pinned `.tool-versions` values) before invoking the script, matching the precedent
  plan 174-01 recorded ("with ASDF_* pinned").
- **Files modified:** None (environment-only; no script or repo file changed).
- **Verification:** Both runs completed to `state=passed` with these vars set.
- **Committed in:** N/A (environment setup, not a commit).

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking, environment-only, no file changes).
**Impact on plan:** None on scope; this is the same environment workaround plan 174-01 already
established as precedent.

## Issues Encountered

`mix test test/crosswake/proof --max-cases 1` (the plan's own stated overall `<verification>`
command) reports 9 failures across 729 tests. Investigated and confirmed **pre-existing and
unrelated**: checked out the pre-plan baseline commit (`bdc216b6`) into a disposable git worktree
and re-ran the same 8 failing test modules there — the identical 9 failures reproduce at that
commit, before any of this plan's work exists. None of the 9 touch `174-FINDING-*.md`, `TODO-011`,
or `phase174_companion_findings_test.exs`. Logged to `deferred-items.md` per the scope-boundary
rule rather than fixed here. The three phase-174 test files (this plan's and its two siblings')
are collectively 21 tests, 0 failures.

## User Setup Required

None — no external service configuration required. Network access to hex.pm (already available
in this environment) and this repo's own `.tool-versions` values (already known from plan 174-01)
were the only preconditions, both satisfied.

## Non-Vacuity Evidence

| Check | Mutation applied | Observed RED | Observed GREEN (restored) |
|---|---|---|---|
| Companion-findings roster completeness | Replaced `check_findings_exist/2`'s body with an unconditional `{:ok, roster}` | `test Task 3: non-vacuity control ... makes the check fail and names sigra` failed: `match (=) failed ... right: {:ok, [...]}`, plus a Dialyzer-adjacent typing-violation warning on the now-unreachable `{:error, missing}` branch elsewhere in the same file | Restored the file from the pre-mutation backup; `mix test` — 7 tests, 0 failures; `mix format --check-formatted` exits 0 |

## Next Phase Readiness

- Plan 174-06 (the phase's vacuity-taxonomy record, per this plan's objective) can cite both
  findings and this plan's mechanical check directly.
- Both companions are diagnosed and currently green in a real local run; the release lane's own
  CI execution of `clean-room-proof-threadline`/`clean-room-proof-sigra` remains the item plan
  174-04 already recorded as PENDING POST-MERGE (`174-CLEANROOM-EVIDENCE.md`) — this plan does
  not change that pending status, only the diagnosis underneath it.
- `deferred-items.md`'s 9 pre-existing `test/crosswake/proof` failures are a candidate follow-up
  for whichever phase reconciles this milestone's workflow additions, but are not blocking this
  plan's own completion.

---
*Phase: 174-clean-room-host-realism-adopter-fidelity*
*Plan: 05*
*Completed: 2026-09-18*

## Self-Check: PASSED

- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-THREADLINE.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FINDING-SIGRA.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-threadline-run.log
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-sigra-run.log
- FOUND: test/crosswake/proof/phase174_companion_findings_test.exs
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/deferred-items.md
- FOUND commit: 5060314b
- FOUND commit: 710b8578
- FOUND commit: ca3bd873
