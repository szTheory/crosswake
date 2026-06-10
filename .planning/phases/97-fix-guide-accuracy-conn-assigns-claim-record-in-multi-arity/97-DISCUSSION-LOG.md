# Phase 97: Fix guide accuracy: conn.assigns claim + record_in_multi arity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity
**Areas discussed:** conn.assigns wording, Parity test regression guard

---

## conn.assigns wording

| Option | Description | Selected |
|--------|-------------|----------|
| Option A — Minimal: Logger.metadata key | "stores it in Logger.metadata under the :crosswake_thread_id key" — precise, minimal, no extra guidance | |
| Option B — Configurable: mention NimbleOptions default | "stores it in Logger.metadata under the configured :logger_metadata_key (default: :crosswake_thread_id)" — reflects adopter override capability | |
| Option C — With downstream read path | "stores it in Logger.metadata under :crosswake_thread_id — read it in downstream plugs or controllers via Logger.metadata()[:crosswake_thread_id]" | ✓ |

**User's choice:** Option C — use it as-is
**Notes:** User requested subagent research (pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Plug patterns, cross-framework lessons, DX considerations). Research confirmed Option C is closest to `Plug.RequestId` idiom extended with downstream read path, matches Crosswake "operational truth" brand stance, and follows patterns from Rails `ActionDispatch::RequestId`, Spring Boot MDC docs, and `express-correlation-id`. The read-path string `Logger.metadata()[:crosswake_thread_id]` is already exercised verbatim in the test suite, making it a stable anchor.

---

## Parity test regression guard

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add to phase96 test | Add 2 assertions to phase96_threadline_docs_contract_test.exs: guide contains "Logger.metadata" and "record_in_multi/3" | ✓ |
| Yes — new phase97 test file | Create test/crosswake/proof/phase97_guide_accuracy_test.exs | |
| No — guide fix only | Narrow scope: doc fix alone is sufficient | |

**User's choice:** Add to phase96 test (recommended)
**Notes:** Neither bug was caught by any existing test. Adding to the phase96 file keeps the hermetic lane unified with zero new test infrastructure. Both assertions follow the existing custom-failure-message pattern.

---

## Claude's Discretion

- Exact prose surrounding the fixed lines (whether to retain the `(posture: :inbound) or mints a new id (posture: :minted)` rhythm verbatim or trim slightly)
- Whether to add a brief mention of the configurable `:logger_metadata_key` NimbleOptions option alongside D-01 wording

## Deferred Ideas

- Configurable `:logger_metadata_key` documentation expansion — NimbleOptions options table in the guide for adopters who override the default key; low-risk edge case, not this phase.
- Sweep for other guide inaccuracies beyond WR-02/WR-03 — explicitly out of scope; file a new phase if found during implementation.
