# Phase 100: Storage Budget Enforcement - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Offline storage limits are explicitly tracked and gracefully handled at runtime to avoid silent browser eviction. This phase adds budget limits to the offline contracts and builds out the web-tier JS enforcement.

</domain>

<decisions>
## Implementation Decisions

### Budget Format (Elixir)
- **D-01:** The `StudySessionIsland` struct should store `:storage_budget` as a raw integer (bytes) — e.g. `50_000_000`. This maps 1:1 to browser APIs like `navigator.storage` without runtime parsing. However, generator and developer-facing APIs should accept ergonomic tuples (e.g. `{:mb, 50}`) or human strings and parse them ahead-of-time before setting the struct field. This provides great Elixir DX while preserving the lowest-level contract as unambiguous "operational truth."

### Pre-eviction Warning (UI)
- **D-02:** Use a calm, specific, actionable persistent banner (not a blocking modal). When `navigator.storage.estimate()` is near limits, show a non-intrusive banner in the island header (e.g., "Storage near limit. Clear old sessions to download more."). This aligns with the brand constraint of "short, status-oriented, no drama" and avoids breaking the flow. 

### Write Failure Fallback (JS)
- **D-03:** Implement graceful degradation to a "Read-only mode" when IndexedDB `put()` throws a `QuotaExceededError`. Catch the error, preserve the local UI state but disable further modifications, and display a status badge/toast ("Storage full. Progress won't be saved."). This honors "local when useful" by letting them finish their current read session instead of force-crashing the view.

### Claude's Discretion
The exact math/threshold for "near limits" (e.g., 90% full or 5MB remaining) for the D-02 warning banner is left to the planner, optimizing for typical offline-sync payload sizes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand & OSS Identity
- `prompts/crosswake-brand-book.md` — Brand constraints: "operational truth over hype," "calm, specific, actionable" microcopy.
- `prompts/crosswake-elixir-oss-dna.md` — OSS constraints: explicit distinction between host-owned code and library-owned code; ergonomic public contracts.

### Deep Research
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — Explains the nuances of IndexedDB vs Cache API quota eviction and why we need explicit handling.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — Recommends IndexedDB for structured data; confirms the need for robust `.put()` failure handling.

### Relevant Code Surfaces
- `lib/crosswake/offline/contracts.ex` — Where `StudySessionIsland` and `:storage_budget` are defined.
- `examples/phoenix_host/priv/static/offline_study.js` — The target file where JS IndexedDB `.put()` calls and `navigator.storage.estimate()` handling will live.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None specifically for quota management; this builds net-new constraints on the existing `StudySessionIsland`.

### Established Patterns
- `examples/phoenix_host/priv/static/offline_study.js` handles IndexedDB explicitly but currently lacks `try/catch` wrappers around `.put()` operations.
- `StudySessionIsland` in `contracts.ex` requires an explicit `:storage_budget` field matching the other strictly-defined behaviors (e.g., `:journal_mode`, `:draft_surface`).

### Integration Points
- `navigator.storage.estimate()` must be integrated into the JS bootstrapping phase before fetching new `ContentPack`s.
- `QuotaExceededError` must be caught on all `store.put()` and `store.add()` calls inside IndexedDB transaction handlers in `offline_study.js`.

</code_context>

<specifics>
## Specific Ideas

- The `QuotaExceededError` handling should immediately update the UI state (e.g., replacing "Syncing..." with "Storage Full (Read-only)") via the JS DOM manipulation.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 100-Storage Budget Enforcement*
*Context gathered: 2026-06-11*