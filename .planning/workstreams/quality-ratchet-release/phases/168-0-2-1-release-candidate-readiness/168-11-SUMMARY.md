---
phase: 168-0-2-1-release-candidate-readiness
plan: "11"
subsystem: release-readiness
gap_closure: true
tags: [release-truth, changelog, anonymization, merge-blocking-literals]
requires:
  - phase: 168-10
    provides: Version truth guard proving the manifest side of gap 3
provides:
  - Public-facing changelog truth at the live published version
  - A published-version section for the entries that shipped inside 0.2.1
  - Merge-blocking literals realigned in lockstep, none weakened
  - Neutral example application naming across the public installer surface
affects: [changelog, publish-readiness-parity, installer-guide]
actuals:
  tasks: 2
  commits: 3
plan_head_before: c8a83584
tech-stack:
  added: []
  patterns: [literals-before-content, standing-posture-stays-unreleased]
key-files:
  created: []
  modified:
    - CHANGELOG.md
    - guides/install.md
    - test/mix/tasks/crosswake_install_test.exs
    - test/crosswake/proof/phase48_provider_adapter_proof_test.exs
    - test/fixtures/proof/phase52_publish_readiness.json
key-decisions:
  - "Keep the four standing-posture subsections in `[Unreleased]` instead of moving them down with the patch. They describe present support posture, not what shipped, and `unreleased_split?` requires them there with merge-blocking posture — a literally empty `[Unreleased]` would have failed publish parity."
  - "Update the phase 52 publish-readiness fixture's two structural arrays by surgical string replacement rather than re-serializing the JSON. A full re-dump reformatted the single-line fixture into 567 lines and buried a one-line semantic change in unreviewable noise."
  - "Leave the `0.2.0` companion-decoupling bullet untouched — it is a true historical statement about which release carried that refactor, not a stale published-version claim."
patterns-established:
  - "When a documentation truth is pinned by merge-blocking exact literals, move the literals first so the correction is proven by a RED, not assumed."
requirements-completed: [REL-04, REL-05]
requirements-addressed: [REL-04, REL-05]
---

# Plan 168-11 Summary — Changelog published truth reconciled to 0.2.1

## Accomplishments

Closed the public-facing half of verification gap 3. `CHANGELOG.md` had been telling
public readers that the current published Hex release was `0.2.0` and that its own
`[Unreleased]` contents were future planning continuity — while `crosswake 0.2.1` had
been installable since 2026-09-14 and contained exactly those entries.

**Task 1 — anonymization landed first.** The three pending working-tree edits replaced a
real adopter's product name with a neutral example name across prose, fixture module
names, fixture paths, and the derived web-module, policy-module, and OTP-application
spellings. Verified complete: zero occurrences of any spelling remain anywhere in the
tracked repository, not just in the three files.

**Task 2 — published truth corrected under TDD.** Literals moved first (RED), then the
changelog. The shipped Phase 154 entries now sit under `## [0.2.1] — 2026-09-14`; the
three published-version sentences name `0.2.1`.

## Task Commits

| Task | Commit |
|---|---|
| 1 | `94ad91ef` docs(168-11): use a neutral example application name |
| 2 (RED) | `905ac136` test(168-11): pin corrected published release truth |
| 2 (GREEN) | `52135b09` docs(168-11): state 0.2.1 as the published Hex release |

## Evidence and Verification

- RED confirmed: `905ac136` produced 12 tests, 1 failure, naming the missing literal
- `mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs` → 12 tests, 0 failures
- `mix test` → **1689 tests, 0 failures** (74 excluded)
- `npm test` → **132 tests, 0 failures**
- `elixir script/check_release_version_truth.exs` → OK, all three components at `0.2.1`
- `mix test test/mix/tasks/crosswake_install_test.exs` → 11 tests, 0 failures
- `git grep -niE 'getfluent|get_fluent'` across the tracked repository → no matches

Both merge-blocking assertions kept `posture: :merge_blocking`. The assertion count in the
phase 48 changelog test is unchanged at three, and the advisory-posture literal
("Provider/device sandbox proof remains advisory unless promotion criteria pass.") was not
touched. No assertion was weakened, relaxed, or deleted.

## Deviations from Plan

### Deviation 1 — `[Unreleased]` is not empty

- **Plan said:** "open a new empty unreleased heading above it" and "leave the advisory,
  verification-required, and deferred sections exactly where they are", which together
  would have carried all four standing-posture subsections down into `[0.2.1]`.
- **What blocked it:** `unreleased_split?` (`lib/crosswake/doctor/publish_readiness.ex:1006`)
  is a merge-blocking publish-parity requirement that the `[Unreleased]` section itself
  contain `Unpublished support claims`, `Verification-required and advisory surfaces`,
  `Deferred non-shipped claims`, and `Published Hex truth`. An empty `[Unreleased]` fails it.
- **Resolution:** the four standing-posture subsections stay in `[Unreleased]`; only the
  patch content (Upgrade Impact, Security, Added, Fixed, Documentation) moved to `[0.2.1]`.
  This is also the more honest shape — advisory and deferred posture is present-tense, not
  a historical property of one patch.
- **The rejected alternative** was relaxing `unreleased_split?`, which the plan explicitly
  prohibits and which would have traded a real guard for a cosmetic heading.

### Deviation 2 — fixture reconciled (anticipated by the plan's "reconcile any other proof assertion")

`test/fixtures/proof/phase52_publish_readiness.json` pins the changelog's observed section
structure. Restructuring changed `changelog_sections` (gains `0.2.1`) and
`unreleased_subsections` (drops the five patch headings). Both were updated to the real
shape. These are observed-structure fields, not assertions; no category, code, proof-class,
rebuild, or severity field changed.

### Deviation 3 — delivered by pull request, not a push to main

`main` is protected and rejects direct pushes (`GH006`). Delivered on branch
`gsd/phase-168-version-truth-changelog` via **PR #163**, which also carries the five
previously unpushed 168-09 and 168-10 commits.

**Total deviations:** 3 — one forced by a merge-blocking guard, one anticipated by the
plan, one structural.

## Issues Encountered

The first fixture edit re-serialized the whole single-line JSON file, producing a 567-line
diff for a one-line semantic change. Reverted and redone as a surgical string replacement,
so the committed diff is one line.

## Known Stubs

None.

## User Setup Required

None. PR #163 needs review and merge.

## Next Phase Readiness

- Gap 3 is now fully closed: coordinates (168-09), regression guard (168-10), and public
  claim (168-11).
- Gap 1 (CR-01 iOS mirror exact-identity gate) remains, owned by 168-12.
- Gap 2 (stranded canonical receipt commits) remains, owned by 168-13.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-15*
