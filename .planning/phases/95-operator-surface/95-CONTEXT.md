# Phase 95: Operator Surface - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the CLI operator surface (`mix crosswake.threadline`), doctor findings, and support matrix posture for the Threadline audit feature.

</domain>

<decisions>
## Implementation Decisions

### Timeline Visualization
- **D-01:** Use a structured text tree with Unicode connectors (similar to `mix deps.tree` or `mix phx.routes`) rather than a dense, wide table. A tree intuitively maps the Native → Bridge → Phoenix sequence without horizontal scrolling, offering vastly superior DevEx.

### Empty State Behavior
- **D-02:** Cleanly print the ephemeral posture message ("Posture: Ephemeral. No ledger configured.") and exit 0. Since the ledger is opt-in, ephemeral is a valid, documented state, not a failure. Exiting 1 would violate the principle of least surprise and break CI scripts.

### PII Violation Verbosity
- **D-03:** List the exact offending keys and the Ecto schema/module name, but do *not* attempt AST parsing for line numbers. In Elixir, data-centric error reporting is idiomatic; AST parsing is brittle and prone to false positives in macro-heavy code.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architectural Threads
- `.planning/threads/threadline-audit.md` — Canonical definition of the Threadline audit feature, detailing the `X-Crosswake-Thread-Id` header, ledger schema, and text-only operator UI goal.
- `.planning/research/SUMMARY.md` — The north star research containing the context around threadline vs APM boundaries.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Doctor checks framework: Hooks directly into the existing `Crosswake.Doctor` logic and output formats.
- Support truth matrix: Expands `Crosswake.SupportMatrix` (or similar module) with `@audit_ledger_support_truth` rows.

### Established Patterns
- Doctor tasks in Elixir commonly return structured console warnings/errors.
- Opt-in features in Crosswake fail-closed on security/PII but fallback gracefully for unconfigured optional layers.
- Text-tree visualization follows idiomatic Elixir CLI tools (e.g., `mix deps.tree`, `mix phx.routes`).

### Integration Points
- `mix crosswake.doctor` task for Threadline configuration checks.
- `mix crosswake.threadline` CLI task for operator inspection.

</code_context>

<specifics>
## Specific Ideas

- Emulate the clean, structured output of tools like `mix deps.tree` for the `mix crosswake.threadline` table output.

</specifics>

<deferred>
## Deferred Ideas

- A visual LiveDashboard / LiveView timeline UI is deferred to a future `crosswake_dashboard` package (as noted in project requirements).

</deferred>

---

*Phase: 95-Operator Surface*
*Context gathered: 2026-06-09*
