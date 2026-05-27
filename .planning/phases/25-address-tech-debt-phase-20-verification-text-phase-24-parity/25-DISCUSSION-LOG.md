# Phase 25: Address tech debt: Phase 20 verification text + Phase 24 parity test WR-01/02 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 25-address-tech-debt-phase-20-verification-text-phase-24-parity
**Areas discussed:** WR-01 presence-required scope, WR-02 fix location, Plan packaging, Bonus IN-01..04 from 24-REVIEW

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| WR-01 presence-required scope | Does every SUMMARY require `requirements-completed:` (Phase 25's own SUMMARY then needs explicit empty list), or only summaries that close requirements (Phase 25 omits the key)? | ✓ |
| WR-02 fix location: helper vs test | Raise in `extract_completed_ids/1` (review's suggestion — strictest, affects every future caller) vs. assert in test 2 that key-present implies >=1 ID (narrower). | ✓ |
| Plan packaging | One plan with three atomic commits (Phase 20 text fix + WR-01 + WR-02) vs. three separate plans. | ✓ |
| Bonus IN-01..04 from 24-REVIEW | ROADMAP scope is just WR-01/02 + Phase 20. The four info-level items (cwd compile-vs-runtime, uppercase `[X]`, dedup assert, workflow_dispatch doc) are advisory — include or defer? | ✓ |

**User's choice:** All four areas selected for discussion.

---

## WR-01 presence-required scope

| Option | Description | Selected |
|--------|-------------|----------|
| A: Required for every SUMMARY; empty list allowed | Every SUMMARY must declare `requirements-completed:` with a parseable value. Tech-debt phases use `requirements-completed: []`. With WR-02's loud fallback, a bare key with no value raises. Strictest, no escape hatch. | ✓ |
| B: Required only when closing requirements | Phase 25 omits the key entirely. Convention-based; re-introduces the WR-01 silent-omission hole the audit flagged. | |
| C: Required + tech-debt opt-out flag | Every SUMMARY needs the key OR an explicit `tech-debt: true` (or similar) frontmatter flag. New schema surface to document and maintain. | |

**User's choice:** A — Required for every SUMMARY; empty inline list `[]` is the canonical tech-debt shape.

**Notes:** Captured as D-03, D-04, D-05 in CONTEXT.md. Phase 25's own 25-01-SUMMARY.md and 25-02-SUMMARY.md declare `requirements-completed: []` literally. The existing inline regex `[^\]]*` capture handles the empty case cleanly without any regex change. No opt-out flag — the empty `[]` shape already encodes "this phase closes no requirements".

---

## WR-02 fix location: helper vs test

| Option | Description | Selected |
|--------|-------------|----------|
| A: Raise in `extract_completed_ids/1` helper | Helper itself raises when `requirements-completed:` is present but neither inline `[..]` nor block `\n  - X` shape matches. Empty inline `[]` still parses cleanly. Strictest; future callers inherit the contract. | ✓ |
| B: Assert in test 2 | Helper stays permissive (returns `[]` on no-match). Test adds a third assertion: key present implies the extracted IDs list parsed successfully. Narrower blast radius; test carries the contract. | |

**User's choice:** A — Raise lives in the helper.

**Notes:** Captured as D-06, D-07 in CONTEXT.md. Helper has exactly one caller today (the test) but pushing strictness into the helper protects every future caller (planning tooling, doc generators, IEx) without re-litigating the contract. Footgun #2 in CONTEXT.md explicitly captures that the raise condition must be `Regex.match?(~r/^requirements-completed:/m, ...)` only AFTER both shape arms have failed, so the inline `[]` empty case doesn't trip it.

---

## Plan packaging

| Option | Description | Selected |
|--------|-------------|----------|
| Two plans, split along natural seam | 25-01: Phase 20 VERIFICATION.md text fix. 25-02: Parity test hardening (WR-01 third test + WR-02 helper raise + Phase 25 SUMMARYs declaring `requirements-completed: []`). Test changes and new SUMMARYs are coupled; splitting them would fail the new presence assertion mid-phase. | ✓ |
| One plan, three atomic commits | All three items in one plan, sequenced commits. Simplest; tech-debt-batch pattern. Slight risk: if commits land out of order during execution, the parity test fails the missing-key check on Phase 25's own incomplete SUMMARY. | |
| Three plans, one per item | Maximum isolation. 25-01 Phase 20, 25-02 WR-01, 25-03 WR-02. Highest ceremony for the smallest items in the milestone. | |

**User's choice:** Two plans, split along natural seam.

**Notes:** Captured as D-10, D-11 in CONTEXT.md. 25-01 is independent (Phase 20 text fix, one-line delete). 25-02 bundles the test-file hardening AND the two new Phase 25 SUMMARYs into a single atomic commit because committing the strengthened test first would fail the new presence assertion against Phase 25's own incomplete SUMMARYs. Footgun #1 in CONTEXT.md captures this commit-ordering coupling.

---

## Bonus IN-01..04 from 24-REVIEW

| Option | Description | Selected |
|--------|-------------|----------|
| Include IN-01 + IN-02; defer IN-03 + IN-04 | IN-01 (cwd consistency) and IN-02 (`[xX ]` checkbox parsing) are one-line fixes in the file 25-02 is already touching; IN-02 is a real silent-drop bug. IN-03 (dedup) and IN-04 (workflow doc) are pure style/docs in a different concern — defer to backlog. | ✓ |
| Strict scope: defer all four | ROADMAP phase name is explicit: WR-01/02 + Phase 20 only. Track IN-01..04 to backlog. Lowest scope-creep risk. | |
| Include all four | Close every advisory item from 24-REVIEW.md in this phase. Expands 25-02 to also touch `.github/workflows/phase23-proof.yml` for IN-04. | |

**User's choice:** Include IN-01 + IN-02 in 25-02; defer IN-03 + IN-04.

**Notes:** Captured as D-08, D-09 in CONTEXT.md (in-scope items) and the "Deferred Ideas" section (IN-03, IN-04). Rationale: 25-02 is already opening `summary_frontmatter_test.exs`; IN-01 and IN-02 are mechanical fixes in that exact file. IN-02 is the same silent-drop failure mode the rest of the phase exists to close (uppercase `[X]` would silently drop a requirement ID from `known_ids`). IN-03 is pure dedup ergonomics; IN-04 lives in `.github/workflows/phase23-proof.yml` (different concern, CI ergonomics not parity-guard strictness).

---

## Claude's Discretion

- Exact wording of the raise message in `extract_completed_ids/1` (must name offending file path and attempted shape).
- Exact wording of the third test description string in `summary_frontmatter_test.exs`.
- Exact commit messages (within Crosswake's existing conventional-commits convention).
- Whether the new third test uses an inline helper or extends `parse_frontmatter/1` to detect emptiness.
- Whether D-11's "natural order" (25-01 first, then 25-02) is achieved via wave ordering or simple sequencing in execute-phase.

## Deferred Ideas

- **IN-03** — duplicate `assert summaries != []` dedup via `setup_all`. Stylistic; not correctness.
- **IN-04** — `workflow_dispatch` documentation or input-gating in `phase23-proof.yml`. CI ergonomics; different concern.
- Sweep all SUMMARYs for additional frontmatter consistency (uniform `phase:`/`plan:`/`tags:` shape) — defer until drift is observed.
- `mix crosswake.planning.audit` CLI task — optional ergonomics on top of the merge-blocking test; not contract.
- Rewrite line 61 of 20-VERIFICATION.md to match a canonical "Final Determination" idiom — out of scope per D-02 (minimal-fix discipline from audit).
- Backfill Nyquist VALIDATION.md coverage for Phases 19/20/23/24 — discovery-only, never merge-blocking; belongs in a separate `/gsd-validate-phase` follow-up per the audit's own recommendation (line 343).
