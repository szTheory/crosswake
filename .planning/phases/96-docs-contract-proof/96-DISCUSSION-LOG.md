# Phase 96: Docs-Contract + Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 96-Docs-Contract + Proof
**Areas discussed:** Parity mechanism, Hermetic lane shape, Advisory lane design, Guide structure

---

**Process note:** Advisor mode (minimal_decisive tier). Round 1: four parallel research agents produced comparison tables grounded in repo conventions. When presented for selection, the user requested a deeper second research round for all four areas: ecosystem idioms (Elixir/Plug/Ecto/Phoenix), lessons from comparable libs in other ecosystems, footguns, DX/ergonomics emphasis, and `prompts/` research dir grounding — with instructions to one-shot a coherent recommendation set rather than asking again. Round 2 ran four deeper agents; their recommendations were locked directly per the user's standing decision-handling profile.

## Parity Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid code-derived | Loop Telemetry public functions; derive header via `Plug.Threadline.init([])`; hardcode 15 frozen ledger columns with Doctor co-location comment | ✓ |
| Pure hardcoded strings | All assertions as literals matching release_boundaries_test.exs | |
| Hybrid + new `canonical_columns/0` public fn | Full compile-linkage but new public API on shipped 0.x lib | deferred |

**User's choice:** Deep-research round → locked hybrid (round-2 upgrade: header derived from `init([])` instead of hardcoded).
**Notes:** Per-key named failures with custom messages; assert prose-form strings, not atom syntax.

---

## Hermetic Lane Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit file list in phase96-proof.yml | Matches all 20+ existing proof workflows; fails closed on renamed files | ✓ |
| Tag-based `--only` | Breaks phase52/64/65 untagged-module hermetic lane guards | |

**User's choice:** Deep-research round → locked explicit file list.
**Notes:** Round 2 added: pinned-SHA actions, `permissions: contents: read`, `timeout-minutes`, separate `mix compile --warnings-as-errors` step, job id `merge-blocking-threadline-docs-contract-proof`, branch-protection registration sequencing.

---

## Advisory Lane Design

| Option | Description | Selected |
|--------|-------------|----------|
| Committed schema + ExUnit + non-blocking workflow | Commit gen.audit output; ExUnit seeds via record_in_multi; separate advisory workflow | ✓ (with round-2 correction) |
| Fresh gen.audit in CI + bash script | No committed artifacts; fragile string matching | |

**User's choice:** Deep-research round → locked committed schema + ExUnit, with a material round-2 correction: NOT `continue-on-error: true` (failed jobs render green on PRs — GitHub UX trap). Instead the repo's phase23-proof.yml pattern: schedule/dispatch-gated job + weekly Monday cron + `::notice` annotation.
**Notes:** `Mix.Shell.Process` over bare capture_io; `Mix.Task.reenable` before every run; `async: false` (no SQLite sandbox); seeded events must set `tier`.

---

## Guide Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Contract-first rewrite | 10-section H2 outline: is/is-not → contract → posture → schema table → PII → operations → doctor → limitations → non-claims | ✓ |
| Extend in place | Append sections after existing prose; weaker reading order | |

**User's choice:** Deep-research round → locked contract-first rewrite with the brand-book/SQLite-"Appropriate Uses" voice and exact microcopy anchors (D-10).
**Notes:** Two distinct forbidden lists (telemetry denylist vs ledger-side 8-key PII guard) must not be conflated; anti-scope language anchors to REQUIREMENTS.md Out of Scope table.

## Claude's Discretion

- Ledger table column phrasing, prose length, workflow file-list ordering.
- Docs-contract test location (`test/crosswake/proof/` anchor recommended).

## Deferred Ideas

- `Crosswake.Audit.Ledger.canonical_columns/0` public introspection — extract only when a third consumer needs it.
- Hash-chain verification task + `crosswake_dashboard` UI — remain documented non-claims.
