---
phase: 193-cleanup-and-new-working-rules
plan: 09
status: complete
requirements: [CLEAN-04, CLEAN-03]
commits: 0
---

# Phase 193 Plan 09: Working rules, PR dispositions and SEED-025 Summary

The agent guide and the workstream state now describe branching from `main` and opening a PR, instead of a temp-folder candidate and a frozen checkout. Nothing was committed (session override); these are plain-file edits on local `main`, which still equals origin/main (`ed853e38`).

## What changed

- AGENTS.md (started from main's copy): added the one-use `allow`/`hold` gate generalized to merges to `main`, merging the release PR, Hex/Maven/iOS publishes, tags and remote branch deletion; the GSD handoff rule, plain-language status rule, one active handoff per workstream, autonomy for local work, the irreversible-operation rule, the workflow-credential lesson, `no command eligible` in one sentence, retiring superseded routes, and testing adapters against real output. New `## How changes land` section with all eight D-16 items. Dropped: the Phase 175 standing authorization, the Phase175 lessons header, the repair-only pushes clause and the duplicate explain-first bullet. All five original sections are intact.
- STATE.md: Current Position, Exact Next Action and Operator Next Steps rewritten; added the `frozen recovery checkout rules` Superseded line at the top of Handoff history plus the previous Exact Next Action as its own Superseded line. All other history lines untouched. `.continue-here.md` carries the same handoff. The four handoff files were all `equal` to main in the plan 07 sweep, so nothing was reconciled from `handoff-retired/`.
- The remaining local copy is recorded honestly: the integration clone was kept by plan 08 (cause `ref_tip_unprotected`: 8 remote-tracking ref tips exist in no backup); 300 of 306 listed items removed, 6 kept.
- ROADMAP.md: the one-line supersession note under `### Ordering rules for v27.0` (bullets unchanged); Phase 193 progress row set to `8/10 | In progress` as the plan specifies.
- PROJECT.md: only the `**Current stage:**` line rewritten; the Android `stays frozen` platform line is unchanged.
- REQUIREMENTS.md: one Future Requirements line pointing to SEED-025. CLEAN-01..04 not flipped (plan 10).
- SEED-025 created in SEED-024's format: WR-01 first (credential-masking gap), then WR-02, IN-01, WR-03, the example-host full-suite CI lane and IN-02, six `Done looks like` items. No code changes.

## PR dispositions (recorded only; no GitHub write)

Live read, 7 open PRs, Crosswake CI per head: #210 hold (CI failure), #211 hold (CI failure, D-24 wording), #236 hold (no release in v27; CI failure), #238 redo after landing (CI success, but files differ from main and touch the 191/192 ledgers), #239, #240, #241 green: merge only as a separate decision with a SHA-pin provenance check. No additional PRs beyond those named. Failure causes recorded as not read. File: `193-PR-DISPOSITIONS.md`.

## Verification

- Task 1: pass. `## How changes land` present; 16 of 16 `rules: d16` lines pass; dropped phrases absent; five main headings present; planning and hex-page tests: 92 tests, 0 failures, `planning_tests rc 0`.
- Task 2: pass (ROADMAP note, STATE supersession line, SEED-025 id/status/order/6 items, REQUIREMENTS, PROJECT stage and Android line).
- Task 3: pass. `rules: result pass` (exit 0); open 7 equals 7 table rows; #211 and #236 rows; `privacy: clean files 10`.
- Script hashes (`193-SCRIPTS.sha256`) re-checked first: all OK. No test, CI lane or workflow added.

## Deviations from Plan

- AGENTS.md wrap: one D-16 phrase (`synthetic merge commit`) first broke across a line and failed the rules check; rewrapped so each fixed phrase sits on one line. Same for one SEED-025 `Done looks like`.
- STATE.md frontmatter (`stopped_at`, `last_updated`) was left as is, since the plan limits edits to the named active sections.

## Evidence

`193-EVIDENCE/planning-tests-09-193.txt`, `open-prs-09-193.txt`, `rules-check-193.txt`, `privacy-09-193.txt`.

## Self-Check: PASSED
