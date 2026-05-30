# Phase 43: Rulestead Hermetic+Advisory Proof And Guide - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 43-rulestead-hermetic-advisory-proof-and-guide
**Areas discussed:** Advisory lane depth, guides/companions.md scope

---

## Advisory Lane Depth

| Option | Description | Selected |
|--------|-------------|----------|
| A: Real Rulestead.Snapshot adapter | Build a real `Crosswake.Companions.Rulestead.Snapshot` module wired to `Rulestead.Snapshot` API. Add rulestead as optional dep. Advisory lane exercises actual flag reads, not just dep presence. Full integration proof but API-stability risk. | |
| B: Echo-placeholder advisory job | Mirror the commerce advisory pattern: advisory job is echo stmts + documented promotion path. Rulestead stays absent from mix.exs entirely. Weakest reading of PROOF-01. | |
| C: Optional dep + same suite, validate_dependency :ok | Add rulestead as optional/conditional dep to mix.exs. Advisory CI runs Phase 42 proof suite with rulestead present. `validate_dependency/0` proves `:ok` when dep is present. Real adapter documented as promotion target. | ✓ |

**User's choice:** C — Optional dep + same suite, validate_dependency :ok (recommended)
**Notes:** ROADMAP SC#2 language "same suite with rulestead present" directly supports Option C. Avoids API-stability risk of building a real Snapshot adapter against a v0.x library. The real adapter is explicitly the advisory-to-merge-blocking promotion target, not Phase 43 scope.

---

## guides/companions.md Scope

| Option | Description | Selected |
|--------|-------------|----------|
| A: Rulestead section only, no intro | Minimal Phase 43 scope. File starts with raw rulestead content, no framing. Phase 47 adds structure. | |
| B: Explicit placeholder headings for rindle/sigra | Rulestead section + "coming in Phase 44-47" headings for other companions. Creates implied surface-area commitments before they're scoped. | |
| C: Rulestead section + short companion-pattern intro | Create `guides/companions.md` with a 2-4 sentence intro on the companion pattern, then the complete rulestead section. Matches every other guide in the project. Intro applies universally — nothing wasted when Phase 47 expands the file. | ✓ |

**User's choice:** C — Rulestead section + short companion-pattern intro (recommended)
**Notes:** Established guides pattern requires an orientation intro. Option B rejected because placeholder headings constitute implicit surface-area commitments inconsistent with the maintainer's OSS house style (public claims must be narrow and documented).

---

## Claude's Discretion

- `phase43-proof.yml` job names and exact structure
- macOS-15 vs. ubuntu-latest runner for advisory job
- timeout-minutes values (20 hermetic, 30 advisory per phase34 pattern)
- Whether advisory lane runs on weekly schedule or workflow_dispatch only
- Exact mechanism for excluding rulestead from hermetic lane dep tree (env-var conditional, `:only` env, or post-install step in advisory CI)
- How to handle the Phase 42 `validate_dependency/0` assertion tension between hermetic (expects `{:error, ...}`) and advisory (expects `:ok`) contexts — planner decides (separate advisory test file vs. conditional assertion)
- Exact anchor strings in `companions_test.exs` beyond the D-08 minimum set
- Exact advisory-lane CI job steps (dep-get invocation to include rulestead)

## Deferred Ideas

- Real `Rulestead.Snapshot` adapter — explicitly the advisory-to-merge-blocking promotion target; deferred due to rulestead v0.x API stability
- Rindle/Sigra guide sections — Phases 44-47
- Full companion arc overview section — Phase 47
- `mix crosswake.gen.companion` generator — deferred until rindle validates the convention
