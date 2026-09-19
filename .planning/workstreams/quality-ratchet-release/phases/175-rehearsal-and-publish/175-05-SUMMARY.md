---
phase: 175-rehearsal-and-publish
plan: 05
subsystem: docs
tags: [release-docs, ci-hygiene, version-literal-check, ios-mirror, git-subtree-split, vacuous-assertion]

requires:
  - phase: 175-04
    provides: "docs/RELEASE-INCIDENT-RESPONSE.md committed with its invariant sentence at d3401e51, discharging SC1's one-way-door bar and giving this plan's new CI check a second file to roster"
provides:
  - "docs/COMPANION-PUBLISH-RUNBOOK.md with the stale single-version warning deleted (DOC-04), all nine outside-fence bare version literals rewritten in state terms, and the invariant sentence at the top"
  - "git subtree split named by name in all three mirror-split locations of the runbook (DOC-06), with the previous splitter confirmed absent from every live workflow/script but one harmless comment"
  - "script/check_release_doc_version_literals.exs — a new merge-blocking CI check, driven red on an injected literal and green on its removal before being trusted, wired into crosswake-ci.yml"
  - "175-DOC-TRUTH.md — the vacuity-taxonomy row (VAC-03) for the new check plus the DOC-04/DOC-06 dispositions with evidence"
affects: [175-rehearsal-and-publish]

actuals:
  tokens: 20820
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Split a single restructured-document edit across two atomic per-task commits by writing the Task-2 (DOC-06) sentences, reverting exactly those three additions to a Task-1-only intermediate, committing, then re-applying them for Task-2's commit — same technique 175-04 used, generalized to three insertion points instead of a truncation boundary."
    - "A version-literal CI check's `--roster` CLI override narrows a SINGLE invocation for testing only (pointing at a scratch copy); the default no-argument path always uses the declared, hardcoded two-file roster, so the same flag that makes the fail-first demonstration possible cannot be used to narrow the check's real scope."

key-files:
  created:
    - script/check_release_doc_version_literals.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-DOC-TRUTH.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-version-literal-check.log
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/scratch/scratch-runbook.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/scratch/scratch-runbook-no-invariant.md
  modified:
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - .github/workflows/crosswake-ci.yml
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md

key-decisions:
  - "The deleted section's final 'Related:' paragraph (exact-ref recovery never runs exact-public-proof) was preserved, not dropped, after re-verifying it against release-please.yml's current exact-public-proof needs: graph (lines 753-763) — still true. Moved into '## Candidate-local versus exact-public proof' with the version literal replaced by 'the previously approved candidate,' per the plan's own suggested home for it."
  - "The runbook does not name the previous splitter (splitsh-lite) at all — grep -c splitsh returns 0 in the runbook. The 'durable mechanism, do not reinstall the previous one' sentence states the rule without naming what it replaced, consistent with the plan's operator-contract-not-changelog framing and its explicit instruction not to add a migration note or history section."
  - "The one remaining `0.2.1` literal in the file (the fenced `mix crosswake.release.candidate --version 0.2.1 --ref <40sha>` example at line 100) was deliberately left untouched — it is inside a code fence, which both the plan's action and the new checker exempt by design."
  - "The version-literal check's vacuity-taxonomy row uses the explicit escape form ('matches none of A-F') rather than a forced-fit letter, reasoned against all six shapes individually in 175-DOC-TRUTH.md, because the check is a closed-world scan over a hardcoded 2-file roster rather than a possibly-empty runtime-derived collection (Shape A) or any workflow-graph/shell-idiom shape (B-F)."

requirements-completed: [DOC-04, DOC-06]

coverage:
  - id: DOC-04
    description: "docs/COMPANION-PUBLISH-RUNBOOK.md's stale 'this pipeline only publishes 0.2.1' section is deleted outright (not softened), its still-true final paragraph is preserved elsewhere reworded, all remaining outside-fence version literals are rewritten in state terms, and the no-version-specific-claims invariant is stated at the top."
    requirement: "DOC-04"
    verification:
      - kind: other
        ref: "grep -c 'TODO-009' docs/COMPANION-PUBLISH-RUNBOOK.md -> 0; grep -c 'This document makes no version-specific claims\\.' -> 1; awk fence-aware three-component literal scan -> 0; grep -cE for the five surviving ## headings -> 5"
        status: pass
    human_judgment: false
  - id: DOC-06
    description: "git subtree split is documented by name as the durable mirror-split mechanism in the rehearsal step, the ordinary-publication section, and the recovery-mode subsection; the previous splitter is confirmed absent from every live workflow/script but one comment; archived .planning/ history is untouched."
    requirement: "DOC-06"
    verification:
      - kind: other
        ref: "grep -c 'git subtree split' docs/COMPANION-PUBLISH-RUNBOOK.md -> 3; grep -rl 'splitsh' .github/ script/ lib/ scripts/ -> script/check_ios_mirror_parity.sh only; git status --porcelain .../milestones/ -> empty"
        status: pass
    human_judgment: false
  - id: D-19-check
    description: "A new merge-blocking CI check fails the build on a bare version literal outside a code fence, or a missing invariant sentence, across a declared two-file roster — demonstrated red on an injected literal and green on its removal before being wired in."
    requirement: "DOC-04"
    verification:
      - kind: other
        ref: ".../evidence/175-version-literal-check.log records exit 1 (injected literal, names scratch-runbook.md:276), exit 0 (literal removed, control case), exit 0 (real roster); crosswake-ci.yml step 'Check release doc version literals' wired; check-actions mutable_refs=0 and check_release_workflow_integrity.exs exit 0 both preserved"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-18
status: complete
---

# Phase 175 Plan 05: Release Documentation Truth + Version-Literal CI Check (DOC-04, DOC-06) Summary

**`docs/COMPANION-PUBLISH-RUNBOOK.md`'s stale "this pipeline only publishes one version" section is gone — deleted, not softened — its prose no longer names a version anywhere outside a fenced command example, `git subtree split` is now named by name everywhere the mirror split happens, and a new merge-blocking CI check makes the exact way this document went false structurally hard to repeat, proven red on an injected literal before it was ever trusted green.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 3/3 complete
- **Commits:** 3 (one per task)

## Accomplishments

- **Task 1 (DOC-04)** — Deleted the `## Before releasing any version other than 0.2.1` section
  outright from `docs/COMPANION-PUBLISH-RUNBOOK.md`: the `**STOP —**` callout, the
  `needs.release-please.outputs.version == '0.2.1'` claim, and the `TODO-009`/`SEED-017`
  paragraph. Confirmed stale before deleting by reading `.github/workflows/release-please.yml`
  directly: `publish-hex` (line 228), `publish-ios-core` (line 560), and `publish-android-core`
  (line 606) now all gate on `needs.release-please.outputs.version ==
  needs.approved-release-guard.outputs.approved_version` — a dynamic per-release binding, not the
  literal the deleted section described. The section's still-true final paragraph (exact-ref
  recovery never runs `exact-public-proof`) was re-verified against that job's current `needs:`
  list (still `[approved-release-guard, release-please, publish-hex, publish-ios-core,
  publish-android-core, clean-room-proof-ios, clean-room-proof-android]`) and preserved, reworded,
  in `## Candidate-local versus exact-public proof`. De-versioned all nine remaining outside-fence
  bare version literals (opening contract line, three linked-coordinate bullets, the
  companion-floors line, the mirror-rehearsal baseline-and-split line, the two status-surface
  lines, and the already-published-version rollback paragraph) and added the invariant sentence
  `This document makes no version-specific claims.` at the top.
- **Task 2 (DOC-06)** — Named `git subtree split` in the three places the mirror split was
  previously described only by effect: `### 5. Run the trusted mirror rehearsal`,
  `## Ordinary publication and recovery`, and `### Scope of the iOS mirror recovery mode`,
  matching `script/release_candidate/ios_mirror.sh`'s live invocation (`git subtree split
  --prefix=packages/crosswake-shell-core-ios "$SOURCE_REF"`, lines 66-67). Re-verified before
  writing that no live workflow or script still invokes the previous splitter: `grep -rl 'splitsh'
  .github/ script/ lib/ scripts/` returns exactly `script/check_ios_mirror_parity.sh`, and only at
  a comment ("no splitsh-SHA-identity comparison," line 31) — left alone, as instructed. The
  runbook does not name the previous splitter at all (`grep -c splitsh` → 0), a deliberate choice
  recorded rather than an oversight. No archived `.planning/` path was touched.
- **Task 3 (D-19)** — Wrote `script/check_release_doc_version_literals.exs`: an Elixir CI-hygiene
  check, copying `check_release_workflow_integrity.exs`'s exit-contract header (`0`/`1`/`3`) and
  `check_absence_is_not_success.exs`'s findings-reporting shape. Two independently callable checks
  composed in `run/1`: bare `X.Y.Z` literals outside fenced blocks, and presence of the invariant
  sentence, both scanned over a declared, never-derived two-file roster
  (`docs/COMPANION-PUBLISH-RUNBOOK.md`, `docs/RELEASE-INCIDENT-RESPONSE.md`). A missing rostered
  file exits `3` (`BLOCKED`) rather than passing vacuously. Proved the check has teeth *before*
  trusting it: copied the runbook to a scratch path under the phase evidence directory, injected a
  bare version literal into a prose line, ran the check against that scratch copy via a
  test-only `--roster` override, and observed exit `1` naming the injected line
  (`evidence/scratch/scratch-runbook.md:276`); removed the literal and observed exit `0` (the
  control case); then ran the real no-argument invocation over the declared roster and observed
  exit `0`. All three exit statuses, each labeled with which run produced it, are recorded in
  `.../evidence/175-version-literal-check.log`. Also confirmed (ad hoc, not required to be logged)
  that removing the invariant sentence from a second scratch copy triggers exit `1`, and that a
  missing rostered file triggers exit `3`. Wired the check as step "Check release doc version
  literals" into `crosswake-ci.yml`'s `release-candidate-fixtures` job, immediately after "Check
  candidate workflow structure," with the remediation line updated in that job's step summary.
  Measured `node scripts/ci_monitor.cjs check-actions` (`mutable_refs=0`) and
  `elixir script/check_release_workflow_integrity.exs` (exit 0) both before and after the edit — no
  regression, and no job-name collision with the `merge-blocking-*` required-checks-audit
  convention since the step was added to an existing, non-`merge-blocking`-named job rather than a
  new job. Wrote `175-DOC-TRUTH.md` recording the VAC-03 vacuity-taxonomy row (escape form,
  reasoned against all six shapes) and the DOC-04/DOC-06 dispositions with their evidence.

## Task Commits

1. **Task 1: Delete the stale single-version warning, de-version runbook prose (DOC-04)** —
   `ed0006e4` (docs)
2. **Task 2: Document `git subtree split` as the durable mirror-split mechanism (DOC-06)** —
   `21b093aa` (docs)
3. **Task 3: The version-literal CI check, driven red before it is trusted (D-19)** —
   `7219968a` (feat)

## Files Created/Modified

- `docs/COMPANION-PUBLISH-RUNBOOK.md` — DOC-04 deletion + de-versioning, DOC-06 `git subtree
  split` documentation, invariant sentence
- `script/check_release_doc_version_literals.exs` (new) — the merge-blocking version-literal +
  invariant-marker CI check
- `.github/workflows/crosswake-ci.yml` — new "Check release doc version literals" step wired into
  `release-candidate-fixtures`
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-DOC-TRUTH.md`
  (new) — vacuity-taxonomy row + DOC-04/DOC-06 dispositions
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-version-literal-check.log`
  (new) — the three-run red/green/green evidence log
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/scratch/scratch-runbook.md`,
  `scratch-runbook-no-invariant.md` (new) — the scratch fixtures the demonstration ran against
- `.planning/workstreams/quality-ratchet-release/STATE.md` — Current Position advanced to plan 6
  of 10, `completed_plans` 31 → 32, `percent` 84 → 86
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Wave 5 row marked `[x]` with commit
  SHAs, Wave 6 unblocked, SC8 marked satisfied with evidence, Phase 175 progress row updated
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — DOC-04 and DOC-06 checked off
  in both the requirement list and the traceability table

## How Each `must_haves` Truth Was Satisfied

1. **The single-version warning section is removed outright (D-17):** `grep -c 'TODO-009'
   docs/COMPANION-PUBLISH-RUNBOOK.md` → `0` — that identifier occurred only inside the deleted
   section.
2. **No bare version literal outside a code fence in either document:** the fence-aware `awk` scan
   (identical to the plan's own acceptance criterion) returns `0` on `COMPANION-PUBLISH-RUNBOOK.md`
   after both tasks; `RELEASE-INCIDENT-RESPONSE.md` was already clean from 175-04 and is unchanged.
   Confirmed independently by `script/check_release_doc_version_literals.exs`'s own real run
   (exit `0`).
3. **Both documents state the invariant at the top, CI-asserted:** `grep -c 'This document makes
   no version-specific claims\.'` → `1` in each file; the new check's `invariant_marker_present/1`
   asserts this and was demonstrated failing when the sentence is removed (scratch copy).
4. **A CI check fails the build on a bare version literal over the declared two-file roster
   (D-19):** `script/check_release_doc_version_literals.exs` wired into `crosswake-ci.yml`;
   roster is a hardcoded module attribute (`grep -c 'RELEASE-INCIDENT-RESPONSE'` → `2`, once in the
   roster and once in a comment referencing it), never derived from a scan.
5. **The check has been observed red on an injection and green on the clean docs:** all three runs
   recorded in `evidence/175-version-literal-check.log` with labeled exit statuses `1`, `0`, `0`.
6. **`git subtree split` named by name in both the ordinary-publication section and the iOS-mirror
   steps (DOC-06):** `grep -c 'git subtree split' docs/COMPANION-PUBLISH-RUNBOOK.md` → `3` — the
   rehearsal step, the ordinary-publication section, and the recovery-mode subsection.
7. **Archived planning history untouched (D-18):** `git status --porcelain
   .planning/workstreams/quality-ratchet-release/milestones/` returned empty after both Task 1 and
   Task 2; this plan's own changes to `.planning/` are confined to this phase's live directory.

## Deviations from Plan

**None against the plan's task instructions.** Two process notes, not deviations:

1. Following 175-04's precedent, the runbook's Task-2 (DOC-06) sentences were drafted together
   with Task-1's (DOC-04) edits for voice consistency, then split into two commits by reverting
   the three DOC-06-specific insertion points to their pre-Task-2 state, committing Task 1, then
   re-applying the DOC-06 sentences and committing Task 2. Both commits were independently
   verified against their own acceptance criteria before being made.
2. The plan's action text suggested checking module attributes via `module_info/1` conceptually
   for a "declared roster read at runtime" shape; in practice `Crosswake.ReleaseDocVersionLiterals`
   exposes a `default_roster/0` function returning the `@rostered_files` attribute directly, which
   is the simpler and more standard way to read a module attribute from a script's top-level code
   in this Elixir version — functionally identical to the declared-never-derived requirement, just
   implemented as a public function rather than reflection.

## Known Stubs

None. Documentation and a CI-hygiene check only — no UI, no wired data source that could be
stubbed.

## Threat Flags

None beyond the plan's own threat model (T-175-22 through T-175-28, T-175-SC), all mitigated as
designed — see `175-05-PLAN.md`'s `<threat_model>`. No new network endpoint, auth path, or schema
change was introduced; the CI check reads local files only.

## Issues Encountered

None. All automated `<verify>` commands in the plan passed on first run against the final
committed state. One design detail required a second pass during drafting: the first `--roster`
implementation attempted to read the module attribute via `module_info/1` at the script's
top-level, which does not expose compile-time attributes for a script compiled this way in this
Elixir version; replaced with a `default_roster/0` public function before the first test run.

## User Setup Required

None.

## Next Phase Readiness

Wave 6 (`175-06-PLAN.md`, REL-11: rehearse all three publish legs against the real `0.2.2`
candidate and record the evidence, the phase's tracer plan) is unblocked. No blockers carried
forward from this plan. The residual `splitsh` comment in `script/check_ios_mirror_parity.sh` is
documented as intentionally left alone (a comment, not a live invocation) and does not block any
later wave.

## Self-Check: PASSED

- FOUND: docs/COMPANION-PUBLISH-RUNBOOK.md
- FOUND: script/check_release_doc_version_literals.exs
- FOUND: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-DOC-TRUTH.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-version-literal-check.log
- FOUND commit: ed0006e4
- FOUND commit: 21b093aa
- FOUND commit: 7219968a

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-18*
