---
phase: 25-address-tech-debt-phase-20-verification-text-phase-24-parity
plan: 02
subsystem: planning-artifacts
tags: [tech-debt, parity-test, hardening, wr-01, wr-02]
requirements-completed: []
---

# Phase 25 Plan 02: Parity Test Hardening Summary

**Hardened `summary_frontmatter_test.exs` with four edits (WR-01 third test, WR-02 helper raise, IN-01 `@requirements_path`, IN-02 `[xX ]`) and created both Phase 25 SUMMARYs in one atomic commit, closing all four advisory items from `24-REVIEW.md`.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-27
- **Completed:** 2026-05-27
- **Tasks:** 3 (applied atomically — Task 1 + Task 2 staged together in Task 3 commit)
- **Files modified:** 3

## Accomplishments

- **WR-01 closed (D-03):** Added a third test — `"every phase summary declares requirements-completed:"` — that asserts every `.planning/phases/*/*-SUMMARY.md` has YAML frontmatter and that the frontmatter contains a parseable `requirements-completed:` key (inline `[..]` or multi-line `\n  - X` shape). Source: `24-REVIEW.md` lines 49–63.
- **WR-02 closed (D-06/D-07):** Tightened `extract_completed_ids/1` by inserting a new third `cond` arm — `Regex.match?(~r/^requirements-completed:/m, frontmatter) -> raise ...` — between the two shape arms and the existing `true -> []` fallback. The raise fires only when the key is present but neither shape matched (bare-key, YAML null, indentation-broken bullet). Empty inline `[]` still parses cleanly via the inline arm (Footgun 2 invariant). Source: `24-REVIEW.md` lines 76–92.
- **IN-01 closed (D-08):** Added `@requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")` compile-time module attribute, symmetric with the existing `@summary_glob`. Refactored `parse_requirement_ids_from_requirements_md/0` body to use `@requirements_path` instead of a runtime `File.cwd!()` call. Source: `24-REVIEW.md` lines 96–100.
- **IN-02 closed (D-09):** Widened REQUIREMENTS.md bullet regex character class from `[x ]` to `[xX ]` so uppercase `[X]` checkboxes (common in some markdown editors) are recognized. Source: `24-REVIEW.md` line 109.
- **Both Phase 25 SUMMARYs created (`25-01-SUMMARY.md`, `25-02-SUMMARY.md`)** declaring `requirements-completed: []` (D-04 canonical tech-debt shape), so the new WR-01 third test passes against Phase 25's own artifacts in the same commit (Footgun 1 / D-10 atomic-commit constraint).

## Task Commits

This plan ships exactly ONE atomic commit containing all three files:

1. **Task 1** — edits to `test/crosswake/planning/summary_frontmatter_test.exs` (not committed alone)
2. **Task 2** — creation of `25-01-SUMMARY.md` and `25-02-SUMMARY.md` (not committed alone)
3. **Task 3** — atomic commit of all three paths together (see commit below)

**Atomic commit:** `test(phase-25): harden summary frontmatter parity (WR-01, WR-02, IN-01, IN-02)` — commit body references D-10 / Footgun 1 atomic-commit constraint and `24-REVIEW.md` as the canonical source of the four fix snippets.

## Pre-Commit Discovery Survey (D-12 / Footgun 3)

Before committing, `mix test test/crosswake/planning/summary_frontmatter_test.exs` was run against the working tree with the strengthened test and both new Phase 25 SUMMARYs present. Full corpus = 16 existing SUMMARYs + 2 new Phase 25 SUMMARYs = 18 total. Result: **3 tests, 0 failures** — all 18 SUMMARYs satisfy the new presence assertion. No pre-existing SUMMARY required backfill. No phase-number floor allowlist added.

## Files Created/Modified

- `test/crosswake/planning/summary_frontmatter_test.exs` — WR-01 third test added; WR-02 raise branch added to `extract_completed_ids/1`; IN-01 `@requirements_path` attribute added; IN-02 `[xX ]` regex widening; `parse_requirement_ids_from_requirements_md/0` refactored to use `@requirements_path`.
- `.planning/phases/25-address-tech-debt-phase-20-verification-text-phase-24-parity/25-01-SUMMARY.md` — NEW; Plan 25-01 summary with `requirements-completed: []` (D-04 canonical tech-debt shape).
- `.planning/phases/25-address-tech-debt-phase-20-verification-text-phase-24-parity/25-02-SUMMARY.md` — NEW; this file; Plan 25-02 summary with `requirements-completed: []`.

## Decisions Made

- D-10 (CONTEXT.md): single atomic commit containing test edits + both SUMMARYs; two-step staging forbidden (Footgun 1).
- D-07 (CONTEXT.md): raise lives in the helper `extract_completed_ids/1`, not in the test body, to protect all future callers.
- D-04 (CONTEXT.md): both Phase 25 SUMMARYs declare `requirements-completed: []` inline (not bare-key, not multi-line block, not null).
- Commit body explicitly references the atomic-commit constraint (`D-10`, `Footgun 1`) for git-archaeology visibility (T-25-02-R01 in the threat model).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- Pre-commit: `mix test test/crosswake/planning/summary_frontmatter_test.exs` — 3 tests, 0 failures (18-SUMMARY corpus).
- Post-commit: `mix test test/crosswake/planning/summary_frontmatter_test.exs` — 3 tests, 0 failures.
- Full suite: `mix test` — exits 0, test count incremented by exactly 1 over Phase 24's count (new third test).
- `git log -1 --name-only` — lists exactly 3 paths (the test file + both SUMMARYs); no `lib/`, `.github/`, `examples/`, or commerce paths (Footgun 4 invariant).
- Footgun 2 invariant: `requirements-completed: []` reaches the inline arm of `extract_completed_ids/1` (capture = `""`, `scan_ids("")` → `[]`), exits before the raise branch. Confirmed by post-commit `mix test` passing against both Phase 25 SUMMARYs.

## Next Phase Readiness

- Phase 25 is complete. Both plans (25-01, 25-02) are shipped.
- The parity guard now has loud failure on three distinct malformed shapes: bare-key (WR-01), present-but-malformed (WR-02), and missing frontmatter block entirely (WR-01 `fm != ""`).
- No blockers for milestone v3.2 archive.

*Phase: 25-address-tech-debt-phase-20-verification-text-phase-24-parity*
*Completed: 2026-05-27*
