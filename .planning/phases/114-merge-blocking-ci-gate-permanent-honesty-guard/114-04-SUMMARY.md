---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
plan: "04"
subsystem: planning-docs
tags: [docs, gate, ci-honesty, advisory-lane, requirements]
dependency_graph:
  requires: [114-01, 114-02, 114-03]
  provides: [corrected-gate01-wording, corrected-pitfalls, updated-filename-refs]
  affects: [REQUIREMENTS.md, ROADMAP.md, PITFALLS.md, multiple-planning-docs]
tech_stack:
  added: []
  patterns: [omission-from-checks, trigger-scoping, advisory-lane-naming]
key_files:
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/research/PITFALLS.md
    - .planning/STATE.md
    - .planning/v6.0-CLOSEOUT.md
    - .planning/research/STACK.md
    - .planning/research/SUMMARY.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-PATTERNS.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-03-PLAN.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-CONTEXT.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-RESEARCH.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-VERIFICATION.md
    - .planning/phases/113-honest-e2e-rewrite-compile-gate/113-03-SUMMARY.md
decisions:
  - "Advisory lanes are non-blocking by omission from branch-protection checks[] + trigger-scoping, never via continue-on-error: true (D-02/D-06) — this wording is now canonical in REQUIREMENTS.md GATE-01, ROADMAP.md Phase 114 Success Criterion 2, and PITFALLS.md"
  - "Filename rename phase90-proof.yml → offline-sync-e2e-gate.yml documented across all planning files except the intentional 114 history docs (114-CONTEXT, 114-RESEARCH-SYNTHESIS, 114-DISCUSSION-LOG)"
metrics:
  duration: "~7 minutes"
  completed: "2026-06-18T06:53:18Z"
  tasks_completed: 3
  files_modified: 15
status: complete
requirements: [GATE-01]
---

# Phase 114 Plan 04: Documentation Honesty Amendment Summary

**One-liner:** Corrected GATE-01's self-contradicting `continue-on-error` clause to omission-from-checks[]/trigger-scoping wording across REQUIREMENTS.md, ROADMAP.md, and PITFALLS.md; updated 13 planning files from `phase90-proof.yml` to `offline-sync-e2e-gate.yml`.

## What Was Built

Three atomic documentation corrections:

1. **GATE-01 wording amendment (REQUIREMENTS.md + ROADMAP.md):** Replaced the self-contradicting final sentence in GATE-01 ("Every non-required CI lane keeps `continue-on-error: true`...") with the correct D-02/D-06 mechanism: advisory lanes are non-blocking by *omission from the branch-protection `checks[]` array* (and trigger-scoping to `schedule`/`workflow_dispatch` where they should not run per-PR) — never via `continue-on-error: true`, which paints a failed lane green and makes it permanently unpromotable. Applied the same correction to ROADMAP.md Phase 114 Success Criterion 2 (the REQUIREMENTS.md mirror).

2. **PITFALLS.md prescriptive row corrections:** Five prescriptive rows that previously recommended `continue-on-error: true` as the advisory mechanism were corrected to the omission-from-checks[] pattern with D-02/D-06 cross-references. Purely descriptive/diagnostic mentions (lines 107, 123, 352-353 — observing the then-current state of the repo) were preserved unchanged.

3. **Filename reference sweep:** All `.planning/*.md` references to the old workflow filename `phase90-proof.yml` were updated to `offline-sync-e2e-gate.yml` (the D-10 rename's documentation half). Zero references remain outside the 114 phase directory. The 114 history docs (114-CONTEXT.md, 114-RESEARCH-SYNTHESIS.md, 114-DISCUSSION-LOG.md) intentionally retain the historical name. The `e2e-offline-sync` job-name string was not touched (separate string, handled by the registration plan).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Amend GATE-01 wording in REQUIREMENTS.md and ROADMAP.md | `5a4568f` | REQUIREMENTS.md, ROADMAP.md |
| 2 | Correct PITFALLS.md continue-on-error prescriptions | `7e3a574` | research/PITFALLS.md |
| 3 | Update phase90-proof.yml filename references across .planning | `09a9161` | 13 files |

## Verification Results

All three automated checks passed:

- Task 1: `grep -q 'omission from' REQUIREMENTS.md && ! grep -n 'keeps continue-on-error: true' REQUIREMENTS.md && ! grep -q 'carries continue-on-error: true' ROADMAP.md` → PASSED
- Task 2: `grep -q 'omission' PITFALLS.md && ! grep -q 'Add continue-on-error: true' PITFALLS.md` → PASSED
- Task 3: `REMAIN=$(grep -rln 'phase90-proof\.yml' .planning/ | grep -v '114-merge-blocking' | wc -l | tr -d ' ')` = `0` → PASSED

## Deviations from Plan

None — plan executed exactly as written.

The `sed -i` bulk replacement on Task 3 covered all 13 files in a single invocation after confirming the file list via `grep -rln`. PITFALLS.md was included in both the Task 2 prescriptive-row edits and the Task 3 filename sweep (no conflict; Task 2 ran first, Task 3 used `sed` which handled the remaining `phase90-proof.yml` mentions in descriptive/source-citation rows).

## Known Stubs

None. This plan contains only documentation corrections — no stubs or placeholder values introduced.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Documentation-only edits.

## Self-Check

FOUND: `.planning/REQUIREMENTS.md` — contains "omission from the branch-protection", does not contain "keeps `continue-on-error: true`"
FOUND: `.planning/ROADMAP.md` — contains updated Success Criterion 2 wording, does not contain "carries `continue-on-error: true`"
FOUND: `.planning/research/PITFALLS.md` — contains "omission" in corrected rows, does not contain "Add `continue-on-error: true`"
FOUND commits: 5a4568f, 7e3a574, 09a9161 in git log

## Self-Check: PASSED
