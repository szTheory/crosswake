# Phase 100: Storage Budget Enforcement - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Offline storage limits are explicitly tracked and gracefully handled at runtime to avoid silent browser eviction. This phase adds budget limits to the offline contracts and builds out the web-tier JS enforcement.

</domain>

<decisions>
## Implementation Decisions

### Eviction Trigger
- **D-01:** Hybrid, Policy-Driven (Auto-evict optional, Manual for core). Do not use a silent, global "auto-evict oldest" strategy. Use a declarative policy model where developers explicitly define what is volatile (optional media) and what requires manual user clearance (required pack data).

### Quota Check Timing
- **D-02:** Block Upfront on Download. Validate byte budgets *before* downloading a content pack. Always reserve a dedicated quota slice specifically for the `Sync Journal` (the append-only mutation queue) to ensure offline progress can always be saved.

### UI Blocking Level
- **D-03:** Hard Block (Unless explicitly configured as Read-Only). If the sync journal's reserved storage budget is exhausted, treat it as a hard boundary preventing entry into the offline island. Do not offer a dismissible "volatile study" warning. Show an explicit, calm boundary card using `Rust 600` (e.g., "Storage is critically full. Please free space before starting this session to ensure your progress is saved.").

### Budget Format (Elixir)
- **D-04:** `StudySessionIsland` stores `:storage_budget` as a raw integer (bytes), matching browser APIs without runtime parsing. Generators and macros accept ergonomic tuples (e.g., `{:mb, 50}`). (Carried forward from previous discussion).

### Claude's Discretion
- The exact API shape for the Elixir manifest constraints (e.g., `reserve_for_journal` and `eviction` blocks) is left to the planner, optimizing for typical offline-sync payload sizes and Phoenix/Ecto idiomatic design.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand & OSS Identity
- `prompts/crosswake-brand-book.md` — Brand constraints: "operational truth over hype," calm, specific, actionable microcopy.
- `prompts/crosswake-elixir-oss-dna.md` — OSS constraints: explicit distinction between host-owned code and library-owned code; ergonomic public contracts.

### Deep Research
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — Explains the nuances of IndexedDB vs Cache API quota eviction and why we need explicit handling.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — Recommends IndexedDB for structured data; confirms the need for robust `.put()` failure handling.

### Relevant Code Surfaces
- `lib/crosswake/offline/contracts.ex` — Where `StudySessionIsland` and `:storage_budget` are defined.
- `examples/phoenix_host/priv/static/offline_study.js` — Target JS integration point.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None specifically for quota management; builds net-new constraints on the existing `StudySessionIsland`.

### Established Patterns
- `examples/phoenix_host/priv/static/offline_study.js` handles IndexedDB explicitly but currently lacks `try/catch` wrappers and storage estimate upfront checks.
- `StudySessionIsland` uses strict behavior fields (`:journal_mode`, `:draft_surface`).

### Integration Points
- `navigator.storage.estimate()` must be integrated into JS bootstrap before downloading `ContentPack`s.
- Manifest API `use Crosswake.Offline.ContentPack` needs explicit quota reservation configurations.

</code_context>

<specifics>
## Specific Ideas

- Error states should be shown *before* the user goes offline. For example: *"Cannot download Daily Study Pack. Requires 150 MB, but only 40 MB is available."*
- The JS should enforce a reserved space for the sync queue. If space isn't available for the mutation queue, the interactive session must not be allowed to start.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 100-Storage Budget Enforcement*
*Context gathered: 2026-06-11*