# Phase 95: Operator Surface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 95-operator-surface
**Areas discussed:** Timeline visualization, Empty state behavior, PII violation verbosity

---

## Timeline visualization

| Option | Description | Selected |
|--------|-------------|----------|
| Tree Visualization | Structured text tree with Unicode connectors (like `mix deps.tree`) | ✓ |
| Dense Table | Strict tabular format showing all data points horizontally | |

**User's choice:** Tree Visualization
**Notes:** Decided autonomously based on user request for a "perfect set of recommendations." A tree intuitively maps the Native → Bridge → Phoenix sequence without horizontal scrolling, offering vastly superior DevEx.

---

## Empty state behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Exit 0 | Cleanly print the ephemeral posture message and exit cleanly | ✓ |
| Exit 1 | Emit an error and fail the command when no ledger is configured | |

**User's choice:** Exit 0
**Notes:** Decided autonomously. Since the ledger is opt-in, ephemeral is a valid, documented state, not a failure. Exiting 1 would violate the principle of least surprise and break CI scripts.

---

## PII violation verbosity

| Option | Description | Selected |
|--------|-------------|----------|
| Keys + Module | List exact offending keys and the Ecto schema/module name | ✓ |
| AST Parsing | Attempt to parse the AST to point to the file and line number | |

**User's choice:** Keys + Module
**Notes:** Decided autonomously. In Elixir, data-centric error reporting is idiomatic; AST parsing is brittle and prone to false positives in macro-heavy code.

---

## Claude's Discretion

All areas were delegated to Claude for a one-shot recommendation.

## Deferred Ideas

- A visual LiveDashboard / LiveView timeline UI is deferred to a future `crosswake_dashboard` package.
