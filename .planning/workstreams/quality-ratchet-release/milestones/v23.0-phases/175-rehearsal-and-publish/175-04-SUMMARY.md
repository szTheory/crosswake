---
phase: 175-rehearsal-and-publish
plan: 04
subsystem: docs
tags: [release-incident-response, hex, ios-mirror, maven, irreversibility, one-way-door]

requires:
  - phase: 175-03
    provides: Wave 0 exit closed (PR #189 merged as c0774e29), Wave 1 (the publish waves, 175-04+) released
provides:
  - "docs/RELEASE-INCIDENT-RESPONSE.md — the operator contract for a release that has already gone wrong: an above-the-fold irreversibility summary and a 15-row registry-grouped partial-failure matrix (REL-16), plus retire/backfill procedures for Hex, the iOS mirror, and Maven (REL-10)"
  - "175-INCIDENT-DOC-COMMIT.md — the recorded, ancestor-checked commit SHA (d3401e51) discharging SC1's one-way-door bar, plus the two stable heading anchors gates 1-3 cite and three per-registry recovery one-liners"
affects: [175-rehearsal-and-publish]

actuals:
  tokens: 11500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Split a single Write-tool document across two atomic per-task commits by truncating to the Task-1 boundary, committing, then restoring the full content for Task 2's commit — preserves one-commit-per-task discipline without a second Write call re-deriving content."
    - "Record a repo limitation honestly inside the incident doc itself (recover-ios-mirror's hardcoded single-transaction validation) rather than writing a plausible-sounding recovery command for a path that does not yet work for a later release."

key-files:
  created:
    - docs/RELEASE-INCIDENT-RESPONSE.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md
  modified:
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md

key-decisions:
  - "The Maven Irreversibility cells quote release-please.yml's own comment verbatim (\"immutability is scoped to PUBLISHED only; VALIDATED deployments are safely droppable\", verified at lines 1156-1157) so the doc and the workflow cannot drift apart, per D-10."
  - "The iOS mirror recovery subsection states, rather than hides, that recover-ios-mirror's validation step is currently pinned to a single hardcoded approved transaction (the Phase 168 identity) and will refuse any other release's inputs — a real limitation discovered while reading the workflow, recorded as a named row/finding per the plan's scope_boundary instruction rather than presenting a plausible command that would actually be rejected."
  - "175-INCIDENT-DOC-COMMIT.md records d3401e51 (the second of the two content commits) rather than 0e433735 (the first), because it is the commit at which the document reached complete content and its ancestor check necessarily also proves the first commit is present as its parent."

requirements-completed: [REL-10, REL-16]

coverage:
  - id: REL-10-doc
    description: "A retire/backfill runbook covering Hex, the iOS mirror, and Maven is committed before the first publish of this milestone."
    requirement: "REL-10"
    verification:
      - kind: other
        ref: "grep -cE '^## Retire / backfill after a bad publish$' docs/RELEASE-INCIDENT-RESPONSE.md -> 1; grep -c unretire -> 2; grep -c un-resolve -> 2"
        status: pass
      - kind: other
        ref: "git merge-base --is-ancestor d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 HEAD -> exit 0"
        status: pass
    human_judgment: false
  - id: REL-16-matrix
    description: "A multi-registry partial-failure response table exists before the first publish, not derived during an incident."
    requirement: "REL-16"
    verification:
      - kind: other
        ref: "awk '/^## Mid-sequence partial failure$/,/^## Retire/' docs/RELEASE-INCIDENT-RESPONSE.md | grep -E '^\\|' | grep -vE '^\\|[ -]*\\|' | grep -vc Detect -> 15; grep -c 'should consider' -> 0"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-18
status: complete
---

# Phase 175 Plan 04: Incident-Response Documentation (REL-10 + REL-16) Summary

**`docs/RELEASE-INCIDENT-RESPONSE.md` now answers "a publish just went wrong, what do I do right now" for Hex, the iOS mirror, and Maven in one file — an above-the-fold irreversibility summary, a 15-row registry-grouped partial-failure matrix with zero empty or hedged Irreversibility cells, and copy-runnable retire/backfill procedures whose language matches what the tools actually do — with its commit SHA recorded and confirmed an ancestor of `HEAD` before any publish task in this phase runs.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 3/3 complete
- **Commits:** 3 (one per task)

## Accomplishments

- **Task 1** — Wrote `docs/RELEASE-INCIDENT-RESPONSE.md`'s top matter (title, mutation-boundary
  statement, the verbatim invariant sentence), the `## Irreversibility summary` table (three rows,
  Hex/iOS mirror/Maven), and the `## Mid-sequence partial failure` matrix: three registry
  groups, five failure-mode rows each, in the fixed order (auth/credential failure before any
  write; partial upload/job failure; published-but-broken; duplicate-publish attempt;
  post-publication proof failed after underlying publish succeeded). Every Detect cell names a
  live registry response (`curl` against Hex/Maven/`repo1.maven.org`), a run conclusion (`gh run
  view`), or a remote ref listing (`git ls-remote`) — confirmed 15/15 by direct inspection after
  writing, not assumed.
- **Task 2** — Appended `## Retire / backfill after a bad publish` with three registry
  subsections. Hex names all five retirement reasons (`renamed`/`deprecated`/`security`/`invalid`/
  `other`) plus `--unretire` as the reversal and states the version stays resolvable. iOS states
  D-20's fact — re-pointing a mirror tag does not un-resolve consumers who already fetched the old
  commit via SwiftPM's resolved-package cache — documented nowhere else in this repository before
  this commit — and additionally records that `recover-ios-mirror`'s validation step is currently
  hardcoded to a single approved transaction and will refuse any other release's inputs until a
  new identity is landed in the workflow. Maven states there is no retire/delete command and that
  recovery is always a superseding version, quoting `release-please.yml`'s own
  `VALIDATED`/`PUBLISHED` immutability comment verbatim.
- **Task 3** — Committed the document (across the two commits below) and wrote
  `175-INCIDENT-DOC-COMMIT.md`: the full 40-character SHA `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`
  and author date, both stable heading anchors confirmed against GitHub's actual anchor-generation
  algorithm (including the double-hyphen anchor for the slash in "Retire / backfill"), the
  re-runnable `git merge-base --is-ancestor <sha> HEAD` command that discharges SC1, an explicit
  re-derivation rule for a future squash/rebase, and three per-registry recovery one-liners for
  gates 1-3 that point into the document's own rows rather than re-deriving language (D-10).

## Task Commits

1. **Task 1: Irreversibility summary + registry-grouped partial-failure matrix (REL-16)** —
   `0e433735` (docs)
2. **Task 2: Retire/backfill procedures for all three registries (REL-10)** — `d3401e51` (docs)
3. **Task 3: Commit the document and record its SHA against the one-way-door bar** — `d0e831ea`
   (docs)

## Files Created/Modified

- `docs/RELEASE-INCIDENT-RESPONSE.md` (new) — the incident-response document
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md` (new) — the commit-SHA record discharging SC1
- `.planning/workstreams/quality-ratchet-release/STATE.md` — Current Position advanced to plan 5 of 10, `completed_plans` 30 → 31, `percent` 81 → 84
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Wave 4 row marked `[x]` with the commit SHA and unblock note, Wave 5 unblocked, Phase 175 progress row 3/10 → 4/10
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — REL-10 and REL-16 checked off in both the requirement list and the traceability table

## How Each `must_haves` Truth Was Satisfied

1. **Single document, no cross-file jump (D-13):** `docs/RELEASE-INCIDENT-RESPONSE.md` contains
   both REL-10 and REL-16 content; verified by reading the completed file — Hex/iOS/Maven procedures
   and the failure matrix live in the same file, one level below the top-level headings.
2. **Not added to `COMPANION-PUBLISH-RUNBOOK.md` (D-14):** confirmed no edits were made to that
   file — `git show --stat` on all three task commits lists only the new document and the new
   `.planning/` record.
3. **Irreversibility summary above the fold (D-15):** `## Irreversibility summary` appears
   immediately after the invariant sentence, before `## Mid-sequence partial failure`; confirmed by
   `grep -n` line ordering in the file.
4. **Matrix grouped by registry, five rows each (D-16):** confirmed via the plan's own `awk` count
   (15) and by reading the three `### Hex` / `### iOS SwiftPM mirror` / `### Maven Central`
   subheadings in order.
5. **No empty/hedged Irreversibility cell:** `grep -c 'should consider' -> 0`; manually read all 15
   rows' final column — none blank, all declarative ("Reversible.", "Irreversible.", or a stated
   dependency on a query result with both branches spelled out).
6. **Hex forward-only advisory + `--unretire` (verified against Hex's actual documented semantics,
   cited in `175-RESEARCH.md` Pitfall 4):** stated in both the summary table and the Hex retire
   subsection; `grep -c unretire -> 2`.
7. **Maven `PUBLISHED` permanent / `VALIDATED` droppable, rehearsal-only:** stated in the summary
   table, the matrix, and the Maven subsection, quoting the workflow comment verbatim; `grep`
   confirms no Maven retire/delete command exists in the document.
8. **iOS SwiftPM resolved-package cache fact (D-20), previously undocumented:** `grep -c
   un-resolve -> 2`; independently confirmed via `grep -rn "resolved-package\|SwiftPM"
   docs/ .github/` before writing that this fact was absent from the repo's existing docs.
9. **Invariant sentence + zero outside-fence version literals (D-19):** verbatim sentence present
   in line 13 (within the first 40 lines); the plan's own `awk` fence-aware literal scan returns 0
   both after Task 1 and after Task 2.
10. **Commit SHA recorded before any publish step (SC1):** `175-INCIDENT-DOC-COMMIT.md` records
    `d3401e51...` and the `git merge-base --is-ancestor` check exits 0 against `HEAD` at recording
    time; no publish task in this phase has executed.
11. **Heading anchors fixed and confirmed (D-15):** both headings unchanged from the plan's
    verbatim text; anchors independently re-derived using GitHub's actual algorithm and recorded in
    the commit record, including the double-hyphen anchor produced by the `/` in "Retire / backfill."

## Deviations from Plan

**None against the plan's task instructions.** One process note, not a deviation: the plan
describes Task 1 and Task 2 as producing separate commits against the same file
(`docs/RELEASE-INCIDENT-RESPONSE.md`). Because both sections were drafted together for
consistency of voice and cross-references (the Maven retire subsection references the matrix's
Maven rows, for example), the executor wrote the full file once, then split it into two commits by
truncating to the Task 1 boundary, committing, and restoring the full content for Task 2's commit —
preserving one-commit-per-task discipline without re-deriving content in a second draft pass. Both
resulting commits are independently verifiable against the plan's per-task acceptance criteria (the
verify commands were re-run against each commit's actual on-disk state before committing).

**One repo limitation surfaced during Task 2, not invented, not softened:** `recover-ios-mirror`'s
validation step in `.github/workflows/ios-mirror-backfill.yml` is currently hardcoded to a single
approved transaction (the identity landed for an earlier release) and will refuse any other
release's recovery inputs. Per the plan's own `<scope_boundary>` instruction ("If writing the matrix
reveals that a recovery path this repo assumes does not actually exist... record it as an unmet row
with a named reason rather than inventing a plausible command"), this is stated explicitly in both
the matrix row and the retire/backfill subsection rather than writing a copy-runnable command that
the workflow would actually reject for a later release. This is a documentation finding, not a code
change — closing it (landing a new approved identity in the workflow) is out of this plan's scope
and is not tracked as a SEED here because it is not new information beyond what
`docs/COMPANION-PUBLISH-RUNBOOK.md`'s existing "Scope of the iOS mirror recovery mode" section
already states; this plan's contribution is surfacing that same fact in the incident-response
context where an operator under pressure would otherwise miss it.

## Known Stubs

None. This plan produces documentation only — no executable code, no UI, no wired data source that
could be stubbed.

## Threat Flags

None beyond the plan's own threat model (T-175-16 through T-175-21, T-175-SC), all mitigated as
designed — see `175-04-PLAN.md`'s `<threat_model>`. No new network endpoint, auth path, or schema
change was introduced.

## Issues Encountered

None. All automated `<verify>` commands in the plan passed on first execution after two corrections
made during drafting (two outside-fence version literals — `0.2.0`/`0.2.1` in prose describing the
iOS recovery job's pinned identity — were caught by the plan's own `awk` scan before committing and
rewritten to describe the same fact without a bare version number).

## User Setup Required

None.

## Next Phase Readiness

Wave 5 (`175-05-PLAN.md`, DOC-04 + DOC-06: delete the stale "only publishes one version" section
from `docs/COMPANION-PUBLISH-RUNBOOK.md`, de-version its prose, document `git subtree split`, and
add the version-literal CI check this document's own invariant sentence depends on) is unblocked.
No blockers carried forward from this plan. The one iOS mirror recovery limitation noted above is
documented, not hidden, and does not block Wave 5 or any later wave — it only means a real
`recover-ios-mirror` dispatch for this release would need a new approved identity landed first, a
fact now on record for whichever plan reaches that gate.

## Self-Check: PASSED

- FOUND: docs/RELEASE-INCIDENT-RESPONSE.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md
- FOUND commit: 0e433735
- FOUND commit: d3401e51
- FOUND commit: d0e831ea

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-18*
