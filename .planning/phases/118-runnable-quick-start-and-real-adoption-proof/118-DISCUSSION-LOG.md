# Phase 118: Runnable Quick Start And Real Adoption Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-19T14:51:03Z
**Phase:** 118-Runnable Quick Start And Real Adoption Proof
**Areas discussed:** Quick-start command path, Proof coverage, Adoption guide story, DRIFT-02 guard strictness

---

## Quick-Start Command Path

| Option | Description | Selected |
|--------|-------------|----------|
| Phoenix-style setup alias + split walkthrough/proof commands | Add `setup`, `ecto.setup`, and `ecto.reset`; quick start uses visible Mix commands for first run and explicit Playwright commands for proof. | yes |
| Explicit commands only, no new aliases | No code change; document `mix deps.get`, `mix ecto.create`, `mix ecto.migrate`, optional seed, and `mix phx.server` directly. | |
| Script-first quick-start verifier | Hide the full path behind a single verifier script such as `script/verify_quick_start.sh`. | |
| Native-first or all-in-one proof path | Lead with iOS/Android project paths and native build/run commands. | |

**User's choice:** Selected all areas and delegated one-shot research-backed recommendations to Claude.
**Notes:** Subagent recommendation selected the Phoenix-style setup alias path. Rationale: it is idiomatic for Phoenix, reduces clean-checkout friction, keeps commands visible, and avoids turning the quick start into an opaque script. The proof section must warn that Playwright starts its own `MIX_ENV=test` server on port `4002`.

---

## Proof Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Tiered quick-start ladder | Phoenix smoke first, Playwright offline correctness proof second, bounded bridge proof third, manifest/native-owned contract proof fourth, advisory native UI steps last. | yes |
| CI-proof-first quick start | Lead with maintainer/CI proof scripts instead of a product walkthrough. | |
| Native-forward quick start | Lead with simulator/emulator/device run steps. | |
| Smoke-only quick start with proof links | Start server and show routes, but link deeper proof elsewhere. | |

**User's choice:** Selected all areas and delegated recommendations.
**Notes:** Subagent recommendation selected the tiered ladder. Rationale: it satisfies Phase 118's command-verified proof goal without overclaiming native evidence before Phase 119. Playwright offline proof is the first required correctness proof after Phoenix smoke. Native UI steps stay advisory.

---

## Adoption Guide Story

| Option | Description | Selected |
|--------|-------------|----------|
| Real flashcard demo walkthrough | Teach the concrete shipped flow from `/offline` through IndexedDB and `/study/sync`. | |
| Reusable offline-island recipe | Teach a transferable route-local recipe for adopter apps. | |
| Both: proof walkthrough first, recipe second | Anchor in the real demo, then extract reusable guidance. | yes |

**User's choice:** Selected all areas and delegated recommendations.
**Notes:** Subagent recommendation selected "both." Rationale: the guide needs to prove current truth and help adopters apply it. It must remove stale bridge-owned mutation language, explain accepted/rejected/conflict vocabulary honestly, and avoid broad background-sync or app-wide local-first claims.

---

## DRIFT-02 Guard Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit docs-contract scanner with repo-derived facts | Derive facts from repo files and fail on wrong port/path/commands/forbidden offline authority language. | yes |
| Literal guide assertions only | Pin exact guide strings and headings with simple assertions. | |
| Standalone Node/Bash docs scanner | Add a separate scanner script outside Mix. | |
| Executable markdown/doctest-style command runner | Execute documented commands from Markdown. | |

**User's choice:** Selected all areas and delegated recommendations.
**Notes:** Subagent recommendation selected an ExUnit scanner, likely `test/crosswake/guides/quick_start_adoption_drift_test.exs`. Rationale: it matches the existing `release_boundaries_test.exs` pattern, runs in normal `mix test`, can derive current repo facts, and can include synthetic regression cases with clear failure messages. It should be strict on proof truth and loose on copy.

---

## Claude's Discretion

- User explicitly requested a one-shot perfect recommendation set after considering all areas, subagent research, prompts, ecosystem lessons, DX, architecture, proof posture, user persona, JTBD, and UI/UX where applicable.
- Claude selected the coherent set captured in `118-CONTEXT.md`: Phoenix-style setup alias, walkthrough-then-proof quick start, tiered proof ladder, adoption guide as real proof plus reusable recipe, and ExUnit docs-contract guard.

## Deferred Ideas

- Native evidence classification remains Phase 119.
- Native screenshots/recordings/artifact collateral remain Phase 120.
- Full troubleshooting and rough-edge docs remain Phase 120.
- Standalone quick-start verifier script is optional later, not Phase 118's primary path.
- Executable Markdown command runner belongs to later proof/UAT work, not DRIFT-02.
