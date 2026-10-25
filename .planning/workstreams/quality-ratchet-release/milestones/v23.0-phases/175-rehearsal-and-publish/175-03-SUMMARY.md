---
phase: 175-rehearsal-and-publish
plan: 03
subsystem: infra
tags: [github-actions, ci-hygiene, sha-pin, supply-chain, vacuity-taxonomy, seed-management]

# Dependency graph
requires:
  - phase: 175-01
    provides: check-actions default scope derived from the tree, the assertFullScope guard, and the files=<N> summary field this plan's Row 1/2 read
  - phase: 175-02
    provides: all 31 mutable action refs pinned to SHAs, files=27 actions=252 mutable_refs=0 over the full repo scope, and the full-scope evidence log this plan's Row 2 cites
provides:
  - "175-WAVE0-EXIT.md — all five of D-28's exit criteria carry a decided, independently re-checkable verdict; Row 5 (own PR, merged, CI green) is met with a named merge commit"
  - "The scope-cardinality gate (assertFullScope) is classified Shape A against the milestone's vacuity taxonomy with a measured non-vacuity fact, satisfying VAC-03"
  - "Two D-29 out-of-scope items filed as SEED-022 and SEED-023 rather than left as prose or silently dropped"
  - "Wave 1 (the publish waves) is released — no Wave 1 task begins before this plan's merge confirmation"
affects: [175-rehearsal-and-publish]

actuals:
  tokens: 6643
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Wave-exit closure as a two-step record: an auto task writes four of five verdicts plus the taxonomy/SEED sections, then a blocking human checkpoint closes the fifth (the merge) with the real merge commit SHA, never a promise about a diff that doesn't exist yet."
    - "Re-verify every claim a checkpoint resolution hands you before writing it into a record — independently re-ran check-actions, re-fetched the PR's statusCheckRollup, and re-resolved the erlef/setup-beam v1 tag via gh api rather than citing the orchestrator's report verbatim."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-03-SUMMARY.md
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-WAVE0-EXIT.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md

key-decisions:
  - "The human's merge choice (one PR, all 14 Wave-0 commits, merged as a merge commit rather than squashed) preserves the 175-01/175-02/175-03 commit lineage on main. Verified this session: git log --oneline main --grep=175-01 -> 4, --grep=175-02 -> 3, --grep=175-03 -> 1 at the time of the merge, all present after merge."
  - "Two job-timeout cancellations (native-collateral-advisory's android-emulator-advisory job, see-it-run-collateral's native job) are recorded in Row 5 as unexercised advisory lanes, not rounded up to green — their step-level logs show every pinned action resolving and succeeding before the timeout, which is evidence the pins are fine, but is not the same claim as 'the lane passed.'"
  - "A newly discovered fact (erlef/setup-beam@v1 now resolves to two different pinned SHAs repo-wide: 10 refs at 54075bcc... including 5 introduced by 175-02, and 31 pre-existing refs at fc68ffb9...) is recorded in the Row 4 note as an adjacent-but-distinct observation, per this plan's explicit Task 1 instruction not to file a new SEED for it and to leave SEED-022 as originally worded."

requirements-completed: [VAC-03]

coverage:
  - id: D28-row5
    description: "The Wave 0 pull request is merged into main with CI green and its merge commit SHA is recorded in Row 5 of 175-WAVE0-EXIT.md."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "gh pr view 189 --json statusCheckRollup (re-run this session) -> 49 checks, 48 SUCCESS, 1 SKIPPED, 0 failures, state MERGED"
        status: pass
      - kind: other
        ref: "git log --oneline main | grep c0774e29 (re-run this session) -> present"
        status: pass
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions on post-merge main (re-run this session) -> EXIT=0, files=27 actions=252 mutable_refs=0"
        status: pass
    human_judgment: true
  - id: D28-taxonomy
    description: "The scope-cardinality gate carries a vacuity-taxonomy shape and a measured non-vacuity fact before being treated as authority."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "175-WAVE0-EXIT.md Section 2 — assertFullScope classified Shape A, non-vacuity fact = narrowed case (expected=27 actual=3, red) vs equal-scope control (expected=27 actual=27, green), from 175-01/175-02's own test-check-actions-scope run"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-18
status: complete
---

# Phase 175 Plan 03: Wave 0 Exit — Five-Row Verdict and the Blocking Merge Checkpoint Summary

**All five of D-28's exit criteria now carry a decided, independently re-checkable verdict on disk, closed by PR #189's merge as `c0774e29` with 48 checks passing and 0 failures — Wave 1 is released.**

## Performance

- **Duration:** ~25 min (this continuation session; Task 1 was completed and committed by a prior executor session that halted at the Task 2 checkpoint)
- **Started:** 2026-09-18 (continuation resume)
- **Completed:** 2026-09-18
- **Tasks:** 2 (Task 1 completed in the prior session at commit `e3ae1e36`; Task 2's checkpoint closed this session at commit `dbc2e921`)
- **Files modified:** 1 (`175-WAVE0-EXIT.md`, plus this SUMMARY and STATE.md/ROADMAP.md)

## Checkpoint Resolution

The plan's Task 2 (`checkpoint:human-verify`, `gate="blocking"`) required the human to open, verify,
and merge the Wave 0 pull request before Wave 1 could begin. This continuation session resumed after
that checkpoint had already been resolved: the human authorized a single PR covering all 14 Wave-0
commits, and the orchestrator carried out the merge.

This session did **not** take the checkpoint resolution on faith — every fact cited in Row 5 below was
independently re-verified before being written into the record:

| Fact | Independent re-verification this session |
|---|---|
| Merge commit `c0774e29` is on `main` | `git log --oneline main \| grep c0774e29` -> present, exactly once; `git status -sb` shows `main` in sync with `origin/main` |
| PR #189's check tally (48 pass / 1 skip / 0 fail) | `gh pr view 189 --json statusCheckRollup` re-fetched this session, parsed programmatically for non-`SUCCESS` conclusions -> exactly one, `release-candidate-full-proof`, `conclusion: SKIPPED` |
| Post-merge `mutable_refs=0` | `node scripts/ci_monitor.cjs check-actions` re-run this session, full output redirected to a file (never piped through `tail`), exit code read directly via `$?` -> `EXIT=0`, `files=27 actions=252 mutable_refs=0` |
| Commit lineage survived the merge | `git log --oneline main --grep=175-01` -> 4, `--grep=175-02` -> 3, `--grep=175-03` -> 1, all re-run this session against post-merge `main` |
| `erlef/setup-beam@v1` currently resolves to `54075bcc...` | `gh api repos/erlef/setup-beam/git/refs/tags/v1` -> annotated tag object; dereferenced via `gh api .../git/tags/<sha>` -> commit `54075bcc5e249e4758d363f27d099f55d843f124`, matching the claim |
| Setup-beam SHA split (10 at `54075bcc`, 31 at `fc68ffb9`) | Recounted per-file via `grep -c`/`grep` across every workflow and action file; found the earlier aggregate `xargs grep -o` count had silently dropped `phase43-proof.yml`'s occurrence from its display (filename stripping), corrected by re-counting per-file with `-H`-equivalent flags |

## Diff Confinement Re-Check Against the Real Merge

Row 4 of the exit record was written before a pull request existed, against `origin/main` as a
stand-in base. This session re-checked diff confinement against the PR's actual content
(`git diff --name-only c0774e29^1 c0774e29^2`, the true two-parent merge diff) rather than trusting the
earlier stand-in comparison to still hold: 33 paths, all within `scripts/ci_monitor.cjs`, the ten
mutable-ref workflow files, the two evidence logs, and this phase's own planning artifacts (including
`ROADMAP.md`/`STATE.md`). Zero already-pinned publish workflows (`release-please.yml`,
`hex-publish.yml`, `ios-mirror-backfill.yml`, `exact-public-proof.yml`) appear. The Row 4 note in
`175-WAVE0-EXIT.md` now records this re-check explicitly rather than leaving the stand-in verdict
uncorrected.

## Accomplishments

- **Task 1** (prior session, commit `e3ae1e36`): wrote all four decided verdicts of Section 1 (Rows
  1–4), the Shape-A vacuity-taxonomy row for `assertFullScope` in Section 2, and filed SEED-022 and
  SEED-023 for D-29's two out-of-scope items in Section 3. Row 5 was left **not met** by construction.
- **Task 2** (this session, commit `dbc2e921`): closed Row 5 to **met**, citing PR #189's merge commit
  `c0774e29616272bc37b980ea76b6522224c5d4ad`, its 48-pass/1-skip/0-fail check tally, the four
  dispatch-only proof lanes confirmed separately (two of which hit job-level timeouts on advisory
  steps, recorded honestly as unexercised rather than rounded up to green), and the post-merge
  `check-actions` re-verification. Also re-checked Row 4 against the real merge diff and recorded an
  adjacent (non-gating, no new SEED per this plan's instruction) finding about the `erlef/setup-beam`
  SHA split.

## Task Commits

1. **Task 1: The five-row Wave 0 exit record, the gate's vacuity row, and the two SEED candidates** — `e3ae1e36` (docs) *(prior session)*
2. **Task 2: Confirm the Wave 0 pull request is merged and green before Wave 1 opens** — `dbc2e921` (docs) *(this session)*

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-WAVE0-EXIT.md` — Row 5 closed to **met** with the merge commit, the Row 4 note updated to reflect a re-check against the real PR diff, and an adjacent setup-beam SHA-split finding recorded
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-03-SUMMARY.md` — this summary
- `.planning/workstreams/quality-ratchet-release/STATE.md` — plan position and session record advanced
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — 175-03 marked complete, Wave 4 unblocked

## Deviations from Plan

None against the plan's own tasks — both of D-28's remaining items (Row 5, and the Row 4 re-check
implied by its own caveat) were completed exactly as scoped. One judgment call, not a deviation from
plan text but worth recording: the plan's Task 1 instructed filing D-29's two items as SEEDs "outside
Wave 0," and this session found a third fact (the setup-beam SHA split) that is adjacent to SEED-022's
framing but not identical to it. Per this plan's explicit continuation instructions, this was recorded
as prose in the exit record rather than filed as a third SEED, and SEED-022 was left unedited.

## Known Stubs

None. This plan produces a record document only; no executable code, no UI, no data-wiring surface.

## Threat Flags

None beyond what the plan's own threat model (T-175-11 through T-175-15) already anticipated and
mitigated — see `175-03-PLAN.md`'s `<threat_model>`.

## Issues Encountered

The orchestrator's earlier aggregate `erlef/setup-beam` SHA count (via `xargs grep -o` without
filename output) silently undercounted the `54075bcc...` pin family by one file
(`phase43-proof.yml`) when spot-checked in this session — corrected by re-counting per-file. This
does not change any verdict (the corrected count of 10 matches what the checkpoint resolution
reported), but it is exactly the kind of counting error this milestone's vacuity work exists to catch,
so it is recorded here rather than silently fixed and dropped.

## User Setup Required

None.

## Next Phase Readiness

Wave 1 (the publish waves, 175-04 through 175-10) is released. `175-04-PLAN.md` (REL-10 + REL-16,
`docs/RELEASE-INCIDENT-RESPONSE.md`) is next per `ROADMAP.md`'s wave ordering. No blockers carried
forward from Wave 0. Two SEEDs (SEED-022, SEED-023) and one prose-recorded adjacent finding (the
setup-beam SHA split) are available for a future phase whose scope is CI/CD hygiene or supply-chain
provenance generally; none are blocking.

## Self-Check: PASSED

- FOUND: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-WAVE0-EXIT.md
- FOUND commit: e3ae1e36
- FOUND commit: dbc2e921
- FOUND: .planning/seeds/SEED-022-sha-pin-provenance-audit.md
- FOUND: .planning/seeds/SEED-023-extend-scope-cardinality-gate.md
- FOUND merge commit on main: c0774e29616272bc37b980ea76b6522224c5d4ad

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-18*
