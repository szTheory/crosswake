# Phase 97: Fix guide accuracy: conn.assigns claim + record_in_multi arity - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix two specific documentation inaccuracies in `guides/threadline.md` identified in milestone audit (WR-02, WR-03):

1. **WR-03 (conn.assigns, line 22):** The guide claims "places it in `conn.assigns[:thread_id]`" but `Crosswake.Plug.Threadline` never calls `Conn.assign/3`. The id is stored in `Logger.metadata` under `:crosswake_thread_id` and echoed in the response header.
2. **WR-02 (record_in_multi arity, line 128):** The guide says "Use `record_in_multi/2`" but the generated template ships `record_in_multi(multi, name, attrs)` — arity 3.

Additionally, add regression-prevention assertions to `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` so neither bug can silently reappear.

No new runtime features. No guide restructuring — targeted line-level fixes only.

</domain>

<decisions>
## Implementation Decisions

### conn.assigns replacement wording (WR-03)

- **D-01:** Replace "places it in `conn.assigns[:thread_id]`" with Option C wording (closes the adoption footgun, matches Crosswake's "operational truth" brand stance, and follows `Plug.RequestId` idiom extended with the downstream read path):

  > "It stores the id in `Logger.metadata` under the `:crosswake_thread_id` key — read it in downstream plugs or controllers via `Logger.metadata()[:crosswake_thread_id]`."

  Rationale: Adopters migrating from the incorrect guide will grep for `conn.assigns` patterns and miss `Logger.metadata`. Giving the explicit read path closes that footgun. The read-path string `Logger.metadata()[:crosswake_thread_id]` is already exercised verbatim in `test/crosswake/plug/threadline_test.exs`, so it is a stable public surface. Research confirms this is the pattern used by Rails `ActionDispatch::RequestId`, Spring Boot MDC docs, and `express-correlation-id`.

### record_in_multi arity (WR-02)

- **D-02:** Change `record_in_multi/2` to `record_in_multi/3` (multi, name, attrs) in the guide. The generated template in `priv/templates/crosswake/audit/ledger.ex.eex` already ships the correct 3-arity function; the guide is the only wrong artifact.

### Parity test regression prevention

- **D-03:** Add 2 targeted assertions to the existing `test/crosswake/proof/phase96_threadline_docs_contract_test.exs`:
  1. `assert guide =~ "Logger.metadata"` — verifies the conn.assigns fix persists.
  2. `assert guide =~ "record_in_multi/3"` — verifies the arity fix persists.
  Both assertions follow the existing custom-failure-message pattern in that file (name the missing contract element + which file to update). Adding to the phase96 file (rather than a new phase97 file) keeps the hermetic lane unified and adds zero new test infrastructure overhead.

### Claude's Discretion
- Exact prose surrounding the fixed lines (e.g., whether to retain the `(posture: :inbound) or mints a new id (posture: :minted)` rhythm or trim slightly).
- Whether to add a brief note about the configurable `:logger_metadata_key` NimbleOptions option alongside D-01 wording (the user approved Option C as-is, so this is at planner's discretion if it aids clarity without adding verbosity).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Guide under fix
- `guides/threadline.md` — The file being fixed. Lines 22 (conn.assigns claim) and 128 (record_in_multi/2 arity) are the two change targets.

### Code surfaces that define the correct behavior
- `lib/crosswake/plug/threadline.ex` — `call/2` never calls `Conn.assign/3`. Thread id goes into `Logger.metadata([{logger_key, id}])` (key defaults to `:crosswake_thread_id` per NimbleOptions schema) and `Conn.put_resp_header`.
- `priv/templates/crosswake/audit/ledger.ex.eex` — Generated template ships `record_in_multi(multi, name, attrs)` — arity 3. This is the source of truth for the correct function signature.

### Parity test to extend
- `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — Existing hermetic parity test. Add 2 assertions (Logger.metadata + record_in_multi/3) following the established custom-failure-message pattern in this file.

### Style and voice references
- `prompts/crosswake-brand-book.md` §6 — "Prefer operational truth over hype. Say what happens, where it happens, and what can fail." Governs the D-01 replacement wording choice.
- `prompts/crosswake-elixir-oss-dna.md` — "docs-contract checks prevent drift; non-goals are written down."

### Milestone audit documenting both bugs
- `.planning/v7.0-MILESTONE-AUDIT.md` — WR-02 and WR-03 entries; the authoritative original bug reports.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Plug.Threadline.init([])[:header_name]` — public NimbleOptions accessor; existing pattern for code-derived parity assertions (used in line 56 of the phase96 test). No new public API needed.
- `Logger.metadata()[:crosswake_thread_id]` — already exercised verbatim in `test/crosswake/plug/threadline_test.exs`; stable string for parity assertion.

### Established Patterns
- Phase 96 parity test custom failure message pattern (e.g., `"guides/threadline.md must document X — add it to the Y section"`) — D-03 assertions MUST follow this shape.
- Phase 96 test: hardcoded strings use `assert guide =~ "exact string"` with a message naming the contract element and target file; code-derived values use `init([])` or public accessors.

### Integration Points
- The fixed guide text becomes anchor targets for the two new parity assertions. The assertions must match the EXACT strings written into the guide (down to backtick formatting or prose wording), so planner must coordinate guide edit and test assertion in the same task/commit.

</code_context>

<specifics>
## Specific Ideas

- The replacement wording (D-01) closes the footgun by explicitly providing the downstream read path `Logger.metadata()[:crosswake_thread_id]` — this is the primary DX win of the phase. Do not weaken it to a vague "Logger.metadata" mention without the read-path example.
- The two new parity assertions are the regression-prevention mechanism. They should be placed near the existing "Propagation Contract" assertions in the phase96 test file (around line 50–70 range) with comments linking back to WR-02/WR-03 in the milestone audit.

</specifics>

<deferred>
## Deferred Ideas

- Configurable `:logger_metadata_key` documentation expansion — if adopters override the default key, the guide's read-path example becomes slightly incorrect. This is a low-risk edge case; a full NimbleOptions options table in the guide is a future documentation enrichment, not this phase.
- Sweep for other guide inaccuracies beyond WR-02/WR-03 — explicitly out of scope per phase boundary. File a new phase if additional inaccuracies are found during implementation.

</deferred>

---

*Phase: 97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity*
*Context gathered: 2026-06-10*
