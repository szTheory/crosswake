# Phase 124: Compatibility Semantics & Adopter Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 124-compatibility-semantics-adopter-truth
**Areas discussed:** Floor-negotiation semantics, Rebuild-class taxonomy + decision table, Doctor mismatch guidance, CHANGELOG impact label (all four selected); capability/pack floor scope

---

## Area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Floor-negotiation semantics (COMPAT-01) | Native == → >= floor; which axes; direction; semver impl | ✓ |
| Rebuild-class taxonomy + decision table (COMPAT-02/03) | 3-class mapping, single canonical source, decision-table-first doc | ✓ |
| Doctor mismatch guidance (COMPAT-04) | New vs extend check; static vs dynamic; action-sequence source | ✓ |
| CHANGELOG impact label (COMPAT-05) | Format, granularity, enforcement, vocabulary | ✓ |

**User's choice:** All four areas.
**Notes:** User requested deep subagent research per area (pros/cons/tradeoffs, what's idiomatic for the Elixir/Phoenix ecosystem, lessons from successful libs in/out of the ecosystem, DX/UX/JTBD lenses, brand-book/oss-dna vision alignment) synthesized into a SINGLE coherent one-shot recommendation set — "so I don't have to think." Four `gsd-advisor-researcher` agents dispatched in parallel; each read live code + `.planning/research/REC-VERSIONING.md`/`REC-CHANGELOG.md`/`ARCHITECTURE.md` + `prompts/` vision docs + web ecosystem.

---

## Floor-negotiation semantics (COMPAT-01)

Research findings → locked decisions D-01..D-06:
- Direction `provides >= demands` (mirrors Elixir `compatible_version?(target, compatibility)`); fail-closed.
- Floor all three axes (not just bridge protocol) — Elixir already floors all three; native `==` on runtime would be NEW drift. Protocol name stays exact.
- FOUR fix sites (BridgeChannel + ActivationCoordinator per platform), not two.
- Hand-port semver, zero deps (reject swift-semver/Kotlin lib — adopter-visible deps + semantic drift). Replicate Elixir fail-closed fallback.
- Ecosystem grounding: protobuf additive-field rule, LSP capability negotiation, Postgres wire-protocol floor, Elixir `Version.match?`.

## Rebuild-class taxonomy + decision table (COMPAT-02/03)

Research correction → locked D-07..D-11:
- The 4-class taxonomy ALREADY ships (`change_class_entries/0` incl. `compatibility-bump only`). Map to 3 rebuild outcomes; do not rename.
- Canonical source = new `rebuild_decision_table/0` rendered into support_matrix.md, auto-covered by phase52 byte-parity guard (reject hand-authored markdown / contract.gen).
- compatibility.md leads with JTBD decision table + denial-signal column; mirrors (not duplicates) the canonical source; new `compatibility_test.exs` with table-before-prose + mirror-agrees-with-renderer teeth.
- Ecosystem: Stripe additive-change allowlist, semver-as-communicated-risk, JTBD upgrade-moment table.

## Doctor mismatch guidance (COMPAT-04)

Research → locked D-12..D-15:
- NEW advisory check (don't overload parity check). Honest two-tier: static advisory baseline, elevate to warning only on detected committed-surface drift; never `:error`.
- Action sequence derived from taxonomy `adopter_action` via `action_sequence_for/1`; share detector with parity check.
- Ecosystem/microcopy: flutter/brew doctor (emit literal next command), rustc `--explain`, honest-diagnostics principle.

## CHANGELOG impact label (COMPAT-05)

Research correction → locked D-16..D-19:
- release-please wired but `skip-changelog: true` → CHANGELOG hand-authored.
- `### Upgrade Impact` subsection first under each version; worst-case headline + per-bullet exceptions when mixed.
- Reuse 4 canonical strings verbatim (no minted tokens; keep rebuild_policy atoms out).
- Honest enforcement: structural (block present) + vocabulary parity; NEVER detect "touches contract" (unprovable). CONTRIBUTING.md for intent gate.
- Ecosystem: Keep-a-Changelog per-release category, conventional-commits BREAKING CHANGE footer, label-rot footgun.

---

## Capability/pack floor scope (decision point)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold in (Recommended) | Convert native capability/pack version == → >= floor too, same helper; eliminates all residual drift | ✓ |
| Defer to follow-up | Keep scope to COMPAT-01's literal axis wording; capability/pack == stays as known residual drift | |
| Fold in, advisory-flag risk | Fold in but gate on a safety vector confirming flooring these axes is semantically safe | |

**User's choice:** Fold in (Recommended).
**Notes:** Makes COMPAT-01 a clean sweep of every native exact-match version footgun, zero residual Elixir-vs-native drift. Captured as D-06.

## Claude's Discretion

Native SemVer helper names/locations + comparison expression; exact vector ids/count (both allow+deny per floored axis incl. capability/pack); `RebuildDecisionEntry` field names + Renderer formatting; compatibility.md JTBD table column wording/order; doctor check `code`/`category`/`details` keys; `### Upgrade Impact` wording template + whether to retro-label historical CHANGELOG entries; CONTRIBUTING.md new vs section. All bounded by D-01..D-19 holding.

## Deferred Ideas

- Pre-release/build-metadata version semantics for contract axes (planner research-flag: match Elixir or declare plain MAJOR.MINOR.PATCH non-goal).
- Pre-publish fixture-verification gate (v14.0 publish step).
- Auto-deriving changelog label from commit/diff analysis (out — honest boundary is human intent-gate).
- Milestone carry-overs: MIRROR_PUSH_TOKEN scope; 2 unrun register-*-gate.sh PATCHes; 4 pre-existing docs-debt test failures (clean up opportunistically during CHANGELOG/guide work).
