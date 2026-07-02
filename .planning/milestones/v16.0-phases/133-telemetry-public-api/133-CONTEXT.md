# Phase 133: Telemetry Public API - Context

**Gathered:** 2026-06-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `Crosswake.Telemetry` as a documented, semver-governed public API that **aggregates the telemetry surface that already exists** in the codebase — it is an aggregating facade, not greenfield instrumentation. Four deliverables (TELEM-01..04):

1. `Crosswake.Telemetry.events/0` — the canonical, runtime-aggregated catalog of every `[:crosswake, ...]` event across companion/RouteGate, doctor, sigra, chimeway, threadline, offline (+ configured companion packages).
2. `guides/telemetry.md` — documents each event's measurements + metadata; stop-metadata ⊇ start-metadata; linked under a hexdocs "Telemetry" group.
3. `Crosswake.Telemetry.attach_default_logger/1` — opt-in structured logger; **core never auto-attaches**.
4. A **bidirectional** declared⇔emitted contract test (TELEM-04).

**Not in scope:** broad new instrumentation of every rule/diagnostic (additive minors later); renaming companion-package events (a `crosswake_rindle` concern); building the DASH-01 dashboard (this is its prerequisite).
</domain>

<decisions>
## Implementation Decisions

### Scope — what `events/0` enumerates (Area 1)
- **D-01:** Seed = **events that already emit.** v1 `events/0` enumerates the 5 already-emitting Keathley-compliant span prefixes (`[:crosswake, :companion, :validate_dependency|:route_gate|:kill_switch]`, `[:crosswake, :threadline, :request]`) expanded to their `:start`/`:stop`/`:exception` triples, plus the existing in-tree `event_names/0` surfaces. **Do NOT instrument-now.** Adding events later is a non-breaking minor (ecosystem consensus: Ecto/Phoenix/Finch/Oban all grew telemetry incrementally).
- **D-02:** **Reconcile the existing declared-but-unemitted events** (Sigra/Chimeway/Offline `event_names/0` entries that don't yet fire). Move them to a `reserved`/planned tier that is EXCLUDED from the "must-emit" half of the contract test — OR down-scope `events/0` to emitting events only. Decide in planning; the invariant is: **every event in the "must-emit" tier of `events/0` is actually emitted.**
- **D-03:** Write an explicit semver statement in the moduledoc + guide: *"telemetry events are public API — additions are minor, removals/renames are major (breaking)."* More rigorous than Ecto/Phoenix document in writing.

### `events/0` return shape (Area 2)
- **D-04:** **Self-describing maps**, not flat name lists: `%{event: [atom,...], description: String.t(), measurements: [atom()], metadata: [atom()]}`. Keys named exactly `event/description/measurements/metadata` (telemetry_registry vocabulary, made runtime-usable). `measurements`/`metadata` are **atom-key lists** (NOT stringified type sigs) so the contract test can mechanically verify real keys.
- **D-05:** **Aggregate at RUNTIME**, never compile-time constants. `events/0` calls each subsystem's `event_names/0`/`metadata_keys/0` at call time (the v7.0 SupportMatrix audit flagged compile-time constants as a stale-`.beam` drift risk). Reuse existing per-module `metadata_keys/0` to populate the `metadata` field.
- **D-06:** Return `Enum.uniq |> Enum.sort`. Optionally also expose a `spannable_events/0` helper (telemetry_registry-style start/stop/exception grouping) for dashboard DX — planner's discretion.

### Companion events + core independence (Area 3)
- **D-07:** **Runtime registry via an OPTIONAL behaviour callback.** Add `@callback telemetry_events() :: [event_doc()]` + `@optional_callbacks telemetry_events: 0` to `Crosswake.Companion`. `events/0` walks `Application.get_env(:crosswake, :companions, [])` and merges via `function_exported?(mod, :telemetry_events, 0)`. This is the chosen option over (a) federated-no-unified-catalog and (b) core-hardcodes-companion-events.
- **D-08:** **Core names NO companion module** — it iterates the runtime `:companions` registry value and calls the callback. Passes the `CompanionGuard` grep in substance (no `{:__aliases__}` ref to a companion); use `function_exported?/3` (not `Code.ensure_loaded?`) and keep it inside a function body (respects EXTRACT-04). In-tree sigra/chimeway/threadline `*.Telemetry` modules ARE referenced statically (allowed — they're in-tree, not extracted).
- **D-09:** **Extracted adapters self-declare** their engine's events (e.g. `crosswake_rindle` adapter implements `telemetry_events/0` returning `[:rindle, :media, :transcode, :*]`). The adapter is the right home — it already probes the engine via `Code.ensure_loaded?`. Treat the behaviour addition as a deliberate, documented change to the semver-stable companion contract surface (SEAM).
- **D-10:** **Fail-closed:** a host with no companions configured gets only core+in-tree events; never a crash. The catalog is correctly per-host.

### Keathley naming enforcement (Area 4)
- **D-11:** **No in-tree renames.** The in-tree `[:crosswake, ...]` span events are already compliant — no action.
- **D-12:** Non-compliant `[:rindle, :media, :transcode, stage]` events are a **`crosswake_rindle` package concern** (pre-1.0): normalize to a compliant span triple in that package's own CHANGELOG, NOT this phase. Phase 133 enforces the convention going forward only via the contract test.

### `attach_default_logger/1` (supporting)
- **D-13:** Model on `Oban.Telemetry.attach_default_logger/1`: signature `attach_default_logger(level | opts)`, stable handler id `"crosswake-default-logger"`, rely on `:telemetry`'s `{:error, :already_exists}` (no custom double-attach guard), ship `detach_default_logger/0`. Derive the attached event list from `events/0`.
- **D-14:** Two modern improvements over Oban: (1) **`encode: false` by default** — emit a structured map into `Logger` metadata, let the app's formatter handle JSON (keep `encode: true` available); (2) **force `:exception` events to `:error`** regardless of the configured `:level` so failures aren't hidden under `:info`.
- **D-15:** Default logger inherits **PII-safety for free** from the existing `forbidden_metadata_keys/0` denylist scrubbing — log only subsystem context metadata, never PII.

### Contract test TELEM-04 (supporting)
- **D-16:** **Federated, non-vacuous.** Core suite proves core+in-tree: (a) declared structural set equals `@core_events` + in-tree `event_names/0` (exact, ordered — existing sigra/chimeway assertion style); (b) declared⇒emitted via `:telemetry_test.attach_event_handlers(self(), events)` driving the real code paths + asserting declared measurement/metadata keys ⊆ emitted keys; (c) emitted⇒declared via an ETS catch-all recording every `[:crosswake, ...]` event seen during the suite, asserting `recorded ⊆ declared`.
- **D-17:** **Merge mechanism proven via a `test/support` stub companion** implementing `telemetry_events/0` and registered in test config — asserts its declared events appear in `events/0` WITHOUT core naming a real companion. Real-companion emission is proven in each companion package's OWN suite (the federation, mirroring the CompanionGuard "travels with the code" D-17 precedent).

### Brand / docs (supporting)
- **D-18:** Add a new **`Telemetry`** group to `mix.exs` `groups_for_extras` (after `Truth`) AND `groups_for_modules` (after `"Companion Contract"`, containing `Crosswake.Telemetry` + the per-subsystem `*.Telemetry` modules). Add `guides/telemetry.md` to `extras:` and the new extras group.
- **D-19:** `guides/telemetry.md` follows the brandbook §14 concept order: definition → when to use → **when NOT to use** → minimal example → **failure modes** → security/PII → testing fixtures → related. State what telemetry is NOT (mirror the `Threadline.Telemetry` moduledoc: not APM, not distributed tracing, not a generic event bus; augments host observability). No "seamless/magic/plugin/powerful/universal" (BRAND-SPEC §4). Event names in JetBrains Mono.
- **D-20:** Names stay "boring on purpose," declarative, no `auto_*`/`magic` (BRAND-SPEC §20). Log/CLI prefix `[crosswake]`; messages calm/specific/actionable.

### Claude's Discretion
- Exact module/file layout, the `reserved`-tier mechanism vs down-scoping (D-02), whether to ship `spannable_events/0` (D-06), the precise `event_doc` typespec, and the doc-generator (mix task vs inline) — planner decides, consistent with the decisions above.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §TELEM (TELEM-01..04, lines ~44-47) — the four deliverables.
- `.planning/ROADMAP.md` "Phase 133" — goal + 4 success criteria (Keathley naming, stop⊇start metadata, opt-in logger, bidirectional test).

### Existing telemetry house pattern (the facade aggregates these)
- `lib/crosswake/threadline/telemetry.ex` — reference module: `event_names/0`, `metadata_keys/0`, `forbidden_metadata_keys/0`, `valid_event_name?/1`, `new_event/1`, `execute/3`; silent-drop sanitizer; "NOT an APM/tracing/event-bus" moduledoc framing.
- `lib/crosswake/companions/sigra/telemetry.ex` — `@event_names` (14), `[:crosswake, :auth, ...]`, fullest forbidden-key set.
- `lib/crosswake/companions/chimeway/telemetry.ex` — `[:crosswake, :notification, ...]`; raises on unknown event name.
- `lib/crosswake/offline/telemetry.ex` — `:status_transition`/`:terminal_outcome` discrete events; `terminal_outcomes/0` enum.
- `lib/crosswake/companion.ex` — the `@behaviour` (6 callbacks) + "## Telemetry events" moduledoc; the file `events/0` extends.

### Emission sites = the honest seed set (D-01)
- `lib/crosswake/compatibility/route_gate.ex:139,191,219` — `[:crosswake, :companion, :dependency_check|:kill_switch|:route_gate]` spans.
- `lib/crosswake/doctor/doctor.ex:573` — `[:crosswake, :companion, :validate_dependency]` span.
- `lib/crosswake/plug/threadline.ex:66` — `[:crosswake, :threadline, :request]` span.

### Independence + aggregation precedent
- `lib/crosswake/companion_guard.ex` — the merge-blocking guard; bans only `{:__aliases__}` refs to frozen companion modules; documents that atom/string event names never trip it. Constrains D-07/D-08.
- `lib/crosswake/support_matrix/support_matrix.ex:684` + `guides/support_matrix.md:193` — existing "Strict Telemetry Contract" aggregation; v7.0 audit lesson → call the per-module fns at RUNTIME (D-05).
- `lib/crosswake/shell/diagnostic_export.ex:59` — canonical 19-key forbidden-metadata set (reuse for D-15).

### Brand / DX
- `brandbook/BRAND-SPEC.md` §4 (forbidden words), §6 (API "boring on purpose"; failure-modes-first), §14 (concept-page order), §20 (declarative API naming, no `auto_*`/`magic`), §22 (describe companions by specific value). **Newer than `prompts/crosswake-brand-book.md` — prefer brandbook.**
- `prompts/elixir-mobile-oss-lib-deep-research.md` (~lines 618-1040) — Keathley spans, low-cardinality/no-PII, "augment not replace host observability."
- `prompts/crosswake-elixir-oss-dna.md` — "telemetry should reflect meaningful domain events, not low-level noise."

### Downstream consumer (shape `events/0` to serve it)
- `.planning/REQUIREMENTS.md:68` (DASH-01, deferred) — `crosswake_dashboard` (Oban-Web model) consumes the v16.0 telemetry contract → `events/0` must be self-describing, low-cardinality, PII-free (reinforces D-04).

### Ecosystem prior art
- `Oban.Telemetry.attach_default_logger/1` (canonical logger prior art), `telemetry_registry` (decoupled event declaration), `:telemetry_test.attach_event_handlers/2` (source at `packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Per-subsystem `*.Telemetry` modules (`event_names/0` + `metadata_keys/0` + `forbidden_metadata_keys/0` + PII scrubbing) — `events/0` aggregates these at runtime.
- `Application.get_env(:crosswake, :companions, [])` runtime registry (read in route_gate/doctor/support_matrix) — the seam `events/0` walks for companion events (D-07).
- `forbidden_metadata_keys/0` denylist (canonical 19-key set) — gives the default logger PII-safety for free (D-15).
- `:telemetry.span/3` already used for the 5 compliant emissions — start/stop/exception + duration + `telemetry_span_context` for free.

### Established Patterns
- House telemetry contract pattern (static `@event_names` + exact-equality test) — extend to self-describing entries (D-04) and runtime aggregation (D-05).
- CompanionGuard "travels with the code" (D-17 precedent) — federate the TELEM-04 emission proof into each companion's suite (D-16/D-17).
- Optional behaviour callbacks + `function_exported?/3` runtime probing — the EXTRACT-04-safe pattern for D-07/D-08.

### Integration Points
- New `lib/crosswake/telemetry.ex` (`events/0`, `attach_default_logger/1`, `detach_default_logger/0`).
- New `@callback telemetry_events/0` + `@optional_callbacks` on `lib/crosswake/companion.ex` (companion contract surface change — SEAM-aware).
- `mix.exs` docs groups (D-18); new `guides/telemetry.md` (D-19).
- `test/support` stub companion + new core proof test `test/crosswake/proof/phase133_telemetry_contract_test.exs` (D-16/D-17).

</code_context>

<specifics>
## Specific Ideas

- Model `attach_default_logger/1` directly on Oban's (read its API), then apply the two upgrades (D-14).
- `event_doc` shape mirrors `telemetry_registry`'s `%{event, description, measurements, metadata}` but with atom-key lists.
- Optional `spannable_events/0` à la telemetry_registry for dashboard ergonomics.
</specifics>

<deferred>
## Deferred Ideas

- **Broad per-rule / per-diagnostic instrumentation** — emit telemetry from more subsystems/paths; ships as additive minors after 133 (zero semver cost). Not this phase.
- **Rindle event normalization** (`[:rindle, :media, :transcode, stage]` → compliant span triple) — belongs to the `crosswake_rindle` package + its CHANGELOG, not core (D-12).
- **DASH-01 operator dashboard** (`crosswake_dashboard`) — the consumer of this contract; deferred milestone (PROJECT.md). 133 is its prerequisite.

</deferred>

---

*Phase: 133-Telemetry Public API*
*Context gathered: 2026-06-27*
</content>
</invoke>
