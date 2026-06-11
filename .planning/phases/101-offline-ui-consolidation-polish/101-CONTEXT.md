# Phase 101: Offline UI Consolidation & Polish - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Consolidating the offline sync capabilities into a brand-aligned, generator-scaffolded UI. This phase covers generating the `OfflineController`, its template, separating it from the LiveView websocket lifecycle, enforcing vanilla-JS budgets, and applying Crosswake Brand Book styling with honest microcopy.

</domain>

<decisions>
## Implementation Decisions

### Generator route injection
- **D-01:** The `mix crosswake.gen.offline_ui` generator will **not** auto-inject routes into the host's `router.ex`. Idiomatic Phoenix generators (`mix phx.gen.auth`, etc.) print instructions to the console (e.g., `Add the following to your router.ex...`). This respects the "operational truth" and avoids AST parsing brittleness.

### Tailwind dependency
- **D-02:** The generated templates will rely on standard Tailwind utility classes, assuming the host uses Phoenix 1.7's default Tailwind setup. The generator will output instructions on how to extend the host's `tailwind.config.js` with Crosswake Brand Book colors (Wake Green, Brass). No standalone CSS payload will be injected.

### Microcopy localization
- **D-03:** Honest microcopy strings ("Available offline", "Pending server confirmation") will be hardcoded as plain text in the generated `.html.heex` templates. Since the files are host-owned, this maximizes transparency and makes it trivial for adopters to edit or wrap in `gettext` themselves. Do not force a Gettext dependency on the generator.

### JS payload stripping
- **D-04:** The generator will scaffold a dedicated `offline_root.html.heex` layout. This layout explicitly omits Phoenix.js, LiveView JS, and `app.js` to save bandwidth and prevent offline socket reconnection thrashing. It will only load a lightweight, vanilla-JS `offline.js` for the island logic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand & OSS Identity
- `prompts/crosswake-brand-book.md` — Brand constraints: "operational truth over hype," "honest microcopy."
- `prompts/crosswake-elixir-oss-dna.md` — OSS constraints: "Install truth is product truth," "Explicit distinction between host-owned code and library-owned code."

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phoenix `mix phx.gen.html` pattern for printing post-generation instructions.

### Established Patterns
- Host-owned generation over library-hidden magic. The generated Offline UI is fully owned by the adopter once generated.

</code_context>

<specifics>
## Specific Ideas

- Adhere strictly to vanilla-JS for the offline island; React/Alpine are out of scope.
- Microcopy must be honest about state (e.g., "Draft only" when not synced).

</specifics>

<deferred>
## Deferred Ideas

- None.

</deferred>