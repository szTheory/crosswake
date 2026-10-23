---
phase: 175-rehearsal-and-publish
plan: 02
subsystem: infra
tags: [github-actions, ci-hygiene, sha-pin, supply-chain]

# Dependency graph
requires:
  - phase: 175-01
    provides: check-actions default scope derived from .github/workflows/*.yml + .github/actions/**/action.yml at run time, gated by a reusable assertFullScope guard, plus the files=<N> summary field this plan's verification reads
provides:
  - "All 31 mutable third-party action refs across the ten workflow files 175-01 made visible are now 40-character commit SHAs with trailing # v<version> comments"
  - "node scripts/ci_monitor.cjs check-actions with no arguments now reports files=27 actions=252 mutable_refs=0, a true statement about the whole repository"
  - "required-checks-audit.yml's BRANCH_PROTECTION_READ_TOKEN-reading job no longer loads any third-party action at a mutable ref"
affects: [175-rehearsal-and-publish]

actuals:
  tokens: 10200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "SHA-pin resolution order: reuse an existing in-repo pin for the same action+tag first; only call `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` (dereferencing annotated `tag`-type objects via `git/tags/<sha>`) when no in-repo pin exists."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-check-actions-full-scope.log
  modified:
    - .github/workflows/required-checks-audit.yml
    - .github/workflows/see-it-run-collateral.yml
    - .github/workflows/native-collateral-advisory.yml
    - .github/workflows/phase68-proof.yml
    - .github/workflows/phase45-proof.yml
    - .github/workflows/phase43-proof.yml
    - .github/workflows/phase132-proof.yml
    - .github/workflows/phase130-proof.yml
    - .github/workflows/phase34-proof.yml
    - .github/workflows/phase23-proof.yml

key-decisions:
  - "erlef/setup-beam@v1 was ambiguous in-repo (two pre-existing SHAs: 54075bcc5e249e4758d363f27d099f55d843f124 and fc68ffb90438ef2936bbb3251622353b3dcb2f93). Resolved fresh per the plan's rule 3 rather than guessing: gh api repos/erlef/setup-beam/git/ref/tags/v1 returned an annotated tag object (54075bcc...) which, dereferenced via git/tags, points to commit 54075bcc5e249e4758d363f27d099f55d843f124 — matching the FIRST existing pin, not the second. Used 54075bcc... for every erlef/setup-beam@v1 pin this plan wrote (phase68-proof.yml, phase45-proof.yml, phase43-proof.yml, phase132-proof.yml, phase130-proof.yml). Left the pre-existing fc68ffb9... pins elsewhere in the repo untouched, per the plan's scope boundary (this plan does not re-pin already-pinned files)."
  - "ReactiveCircus/android-emulator-runner@v2 also resolved to an annotated tag object; dereferenced via git/tags to commit a421e43855164a8197daf9d8d40fe71c6996bb0d, which is the SHA actually pinned (not the tag object's own SHA)."

requirements-completed: [VAC-03]

coverage:
  - id: D1
    description: "All 31 mutable third-party action refs across the ten affected workflow files are now 40-character commit SHAs with trailing version comments; required-checks-audit.yml's branch-protection-token job carries zero mutable refs."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions .github/workflows/{required-checks-audit,see-it-run-collateral,native-collateral-advisory,phase68-proof,phase45-proof}.yml -> files=5 actions=29 mutable_refs=0"
        status: pass
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions .github/workflows/{phase43-proof,phase132-proof,phase130-proof,phase34-proof,phase23-proof}.yml -> files=5 actions=10 mutable_refs=0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Repository-wide check-actions (no arguments) proves mutable_refs=0 over the full derived scope, not just the ten touched files, with the run recorded to evidence."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions (no args) -> files=27 actions=252 mutable_refs=0, exit 0; evidence/175-check-actions-full-scope.log"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-09-18
status: complete
---

# Phase 175 Plan 02: Pin the 31 mutable action refs Summary

**Every third-party `uses:` reference across the ten workflow files `175-01` made visible is now a 40-character commit SHA with a version comment, and `node scripts/ci_monitor.cjs check-actions` with no arguments reports `files=27 actions=252 mutable_refs=0` — a true statement about the whole repository, not three files.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-18T19:03:00Z
- **Completed:** 2026-09-18T19:09:00Z
- **Tasks:** 2
- **Files modified:** 11 (10 workflow files, 1 new evidence log)

## Before/After Measurement

| | files= | actions= | mutable_refs= | exit |
|---|---|---|---|---|
| Before (orchestrator's starting measurement) | 27 | 252 | 31 | 1 |
| After Task 1 (5 heaviest files, scoped run) | 5 | 29 | 0 | 0 |
| After Task 2 (remaining 5 files, scoped run) | 5 | 10 | 0 | 0 |
| After Task 2 (full repo, no arguments) | 27 | 252 | **0** | **0** |

The full-scope `mutable_refs=0` result is recorded verbatim (via direct redirect, not a pipeline) at
`.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-check-actions-full-scope.log`,
with `observed_exit_status=0` and `freshly_computed_expected_file_count=27` appended as final lines.

## Accomplishments

- **Task 1** pinned all 23 mutable refs in the five heaviest files (`required-checks-audit.yml`,
  `see-it-run-collateral.yml`, `native-collateral-advisory.yml`, `phase68-proof.yml`,
  `phase45-proof.yml`), including the `required-checks-audit.yml` job that reads
  `secrets.BRANCH_PROTECTION_READ_TOKEN` — confirmed byte-identical secret reference before/after.
  - Reused existing in-repo pins verbatim: `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7`,
    `actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7`,
    `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1`.
  - Freshly resolved via `gh api` for four actions with no in-repo pin:
    - `charmbracelet/vhs-action@v2` -> `f6d7db07a432fcd3b06772628d36a57f96d95dcf` (commit object, direct)
    - `peter-evans/create-pull-request@v8` -> `5f6978faf089d4d20b00c7766989d076bb2fc7f1` (commit object, direct)
    - `actions/download-artifact@v8` -> `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` (commit object, direct)
    - `ReactiveCircus/android-emulator-runner@v2` -> tag object `4c44018e...` was an annotated `tag`
      type; dereferenced via `gh api repos/ReactiveCircus/android-emulator-runner/git/tags/4c44018e...`
      to commit `a421e43855164a8197daf9d8d40fe71c6996bb0d`
  - Resolved the ambiguous `erlef/setup-beam@v1` fresh per rule 3: `gh api .../git/ref/tags/v1`
    returned annotated tag object `0f75c294...`; dereferenced to commit
    `54075bcc5e249e4758d363f27d099f55d843f124`, matching the FIRST of the two existing in-repo pins,
    not the second (`fc68ffb90438ef2936bbb3251622353b3dcb2f93`).
- **Task 2** pinned the remaining 8 mutable refs in `phase43-proof.yml`, `phase132-proof.yml`,
  `phase130-proof.yml`, `phase34-proof.yml`, `phase23-proof.yml` — every ref here was either
  `actions/checkout@v7` or `erlef/setup-beam@v1`, both reused verbatim from Task 1's resolutions with
  no re-resolution. Then ran `node scripts/ci_monitor.cjs check-actions` with no arguments and recorded
  the full-scope proof to evidence.

## Task Commits

1. **Task 1: Pin the 23 mutable refs in the five heaviest workflow files** - `dddc88f7` (fix)
2. **Task 2: Pin the remaining 8 mutable refs and prove the full scope is clean** - `91c3fdb7` (fix)

## Files Created/Modified

- `.github/workflows/required-checks-audit.yml` - pinned `actions/checkout@v7`
- `.github/workflows/see-it-run-collateral.yml` - pinned 11 refs across three jobs (checkout, setup-node, vhs-action, upload-artifact, download-artifact x2, create-pull-request)
- `.github/workflows/native-collateral-advisory.yml` - pinned 6 refs across two jobs (checkout, setup-node, upload-artifact, x2 each)
- `.github/workflows/phase68-proof.yml` - pinned checkout, setup-beam, android-emulator-runner (setup-java was already pinned)
- `.github/workflows/phase45-proof.yml` - pinned checkout, setup-beam
- `.github/workflows/phase43-proof.yml` - pinned checkout, setup-beam
- `.github/workflows/phase132-proof.yml` - pinned checkout, setup-beam
- `.github/workflows/phase130-proof.yml` - pinned checkout, setup-beam
- `.github/workflows/phase34-proof.yml` - pinned checkout (local `./.github/actions/setup-elixir-cache` left alone, correctly not third-party)
- `.github/workflows/phase23-proof.yml` - pinned checkout (same local-action exclusion)
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-check-actions-full-scope.log` - full stdout/stderr of the no-argument repo-wide `check-actions` run, plus appended observed exit status and freshly computed expected file count

## Decisions Made

- See `key-decisions` in frontmatter for the two annotated-tag dereferences (erlef/setup-beam, ReactiveCircus/android-emulator-runner) and how the ambiguous erlef/setup-beam pin was resolved without guessing.
- The pre-existing `erlef/setup-beam@v1` -> `fc68ffb90438ef2936bbb3251622353b3dcb2f93` pins elsewhere in the repo (e.g. `see-it-run-collateral.yml:53,124,197`, `native-collateral-advisory.yml:19,62`, `release-please.yml`, `hex-publish.yml`, `exact-public-proof.yml`, `clean-room-proof-rehearsal.yml`, `.github/actions/setup-elixir-cache/action.yml`) were left untouched. This plan's scope is the 31 refs `175-01` flagged as mutable; those lines were already pinned (not mutable) before this plan started, so they were correctly out of scope. This is a pre-existing dual-SHA-per-tag state in the repo that this plan does not silently reconcile, per the plan's explicit instruction ("this plan does not re-pin already-pinned files").

## Deviations from Plan

None — plan executed exactly as written. Both tasks' acceptance criteria and verify blocks were run and passed as specified, including the byte-identical secret check, the uses-only diff check, the untouched-publish-workflows check, and the scope-parity check.

One clarifying note on the repo-wide "single-SHA-per-tag" acceptance criterion (Task 2): a naive
`grep -rhoE` across the whole repo shows `erlef/setup-beam v1` mapping to two different SHAs
(`54075bcc...` used by this plan and `fc68ffb9...` pre-existing elsewhere). This is NOT a violation
introduced by this plan — every pin this plan's diff wrote for `erlef/setup-beam@v1` uses the single
SHA `54075bcc5e249e4758d363f27d099f55d843f124`, confirmed via `git diff --stat` isolated to this
plan's two commits. The dual-SHA state is pre-existing repository history the plan's scope boundary
correctly excludes from remediation (see Decisions Made above).

## Issues Encountered

None. `gh` was already authenticated (`szTheory` account) so no auth gate was hit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mutable_refs=0` is now a true statement about the whole repository. Wave 0's broken-windows
  triage (D-21 through D-28) is fully satisfied on the SHA-pinning side; `175-01` already satisfied
  the discovery/gate side. Wave 0 exit criterion 5 (own PR, merged before Wave 1 starts) is an
  orchestration/process step outside this plan's file scope.
- No blockers. The four already-pinned publish workflows (`release-please.yml`, `hex-publish.yml`,
  `ios-mirror-backfill.yml`, `exact-public-proof.yml`) remain untouched, confirmed by `git diff
  --name-only` against them returning empty.

## Self-Check: PASSED

- FOUND: .github/workflows/required-checks-audit.yml
- FOUND: .github/workflows/see-it-run-collateral.yml
- FOUND: .github/workflows/native-collateral-advisory.yml
- FOUND: .github/workflows/phase68-proof.yml
- FOUND: .github/workflows/phase45-proof.yml
- FOUND: .github/workflows/phase43-proof.yml
- FOUND: .github/workflows/phase132-proof.yml
- FOUND: .github/workflows/phase130-proof.yml
- FOUND: .github/workflows/phase34-proof.yml
- FOUND: .github/workflows/phase23-proof.yml
- FOUND: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-check-actions-full-scope.log
- FOUND commit: dddc88f7
- FOUND commit: 91c3fdb7

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-18*
