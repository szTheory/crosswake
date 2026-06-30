# v17.0 Companion Family Completion — Research Synthesis & Locked Design Spine

*Produced 2026-06-30 during `/gsd-new-milestone` from 5 parallel research subagents (core-inversion mechanism, sigra auth hot-path, telemetry public contract + PII, threadline observer, versioning/package-family DX), each grounded in the live codebase + `prompts/` corpus + Elixir ecosystem precedent (Ash, Oban, Phoenix, Swoosh, Broadway, PromEx, Guardian/Pow/Ash.Policy, `:telemetry`).*

## Goal

Extract the remaining three first-party companions — `sigra` (auth), `chimeway` (notifications), `threadline` (audit) — into standalone, independently-versioned, fail-closed Hex packages, **completing the companion family**. Module names preserved (`Crosswake.Companions.Sigra.*` etc.) so the sole adopter touch-point (`config :crosswake, :companions, [...]`) is unchanged and extraction is non-breaking.

## Two reframings that shape the milestone

1. **The "chimeway depends on sigra AuthContext" coupling is a myth at the type level.** Chimeway already correctly types `auth_context: map()` (`lib/crosswake/companions/chimeway/contracts.ex:275`) — a duck-typed plain map, **not** `Sigra.Contracts.AuthContext`. There is no real inter-companion type coupling. Consequence: companions depend **only on core**; the compatibility matrix stays O(N), single `Requires crosswake >= X` column, no inter-companion columns ever.

2. **The real work is a core-decoupling phase that must land green BEFORE any extraction.** Core statically references sigra/chimeway in **four** sites, all of which currently violate the v16.0 "core never compile-depends on a companion" guard for these two companions:
   - `lib/crosswake/telemetry.ex:145,289` — aggregates `Companions.Sigra.Telemetry.event_names()` ++ `Companions.Chimeway.Telemetry.event_names()` and forbidden-metadata-keys.
   - `lib/crosswake/compatibility/route_gate.ex:9,258` — `alias Crosswake.Companions.Sigra.Evaluator`; calls `evaluate_route_auth/3` on the route-activation path.
   - `lib/crosswake/support_matrix/support_matrix.ex:16,226-227,266-269` — `Sigra.Telemetry`, `Sigra.DenialCodes.codes()`, `Chimeway.Telemetry`.
   - `lib/crosswake/doctor/doctor.ex:792,797` — `Sigra.DenialCodes.codes()` / `allowed_detail_keys()`.

   Until inverted onto the registry seam, core will not compile without the companions present — an adopter installing core but not sigra hits a compile error. Highest-priority risk; its own phase.

So v17.0 = **decouple core → extract sigra → extract chimeway → extract threadline**, sequential with green CI gates between, never batched.

## Locked design decisions (D-1..D-9)

- **D-1 — One inversion mechanism: optional behaviour callbacks + runtime registry iteration.** Extend `Crosswake.Companion`; core iterates `Application.get_env(:crosswake, :companions, [])` guarded by `function_exported?/3` and collects contributions with `Enum.flat_map`. **No** new process / ETS registry / compile-time accumulation (`@before_compile` / protocol consolidation conflict with `optional: true` deps). This is the PromEx plugin pattern and extends the `telemetry_events/0` optional callback Phase 129 already shipped. `Application.get_env` only — never `compile_env` (stale-beam footgun); keep `function_exported?`/`Code.ensure_loaded?` in function bodies (EXTRACT-04 guard).

- **D-2 — New optional callbacks:** `forbidden_metadata_keys/0`, `denial_codes/0`, and a **dedicated** auth pair `evaluate_auth/3` + `auth_authority?/0`. Do **not** overload `route_gated?/2` for auth (richer `AuthContext` input, distinct `auth.step_up.*` denial namespace; conflation corrupts the `Finding` type). All new callbacks stay optional so rulestead/rindle are unaffected.

- **D-3 — Fail-closed auth is structural.** Auth-predicated route (`auth_min_level`/`requires_recent_auth`/`auth_posture` set) + no resolved auth companion ⇒ **DENY** `:dependency_missing`. Companion raises during eval ⇒ `try/rescue` ⇒ **deny**. "No eval = allow" reachable only on non-auth routes (avoids Guardian's fail-open `VerifyHeader` footgun). `auth_authority?/0` selects exactly one auth companion; multiple ⇒ first-registered + telemetry warning + doctor flag.

- **D-4 — Companions emit `Finding.t()` (companion-public); core translates to `Denial.t()` (core-private).** Sigra internals (`evaluator`, `handoff`, `step_up_ceremony`, `auth_return`) construct `Denial.t()` directly today → refactor to `Finding.t()` at the package boundary; PII detail-sanitization (`DenialCodes.sanitize_details/1`) stays inside `crosswake_sigra`. **Planner verify:** `Finding.axis` admits `:auth` before locking the contract.

- **D-5 — Telemetry: runtime aggregation + a core baseline PII denylist (defense-in-depth).** `Crosswake.Telemetry.events/0` stays the single discoverable, semver-governed catalog (a genuine differentiator — Oban/Phoenix/Bandit expose no programmatic catalog), aggregating core + runtime companions. PII guard = two layers: per-companion `forbidden_metadata_keys/0` aggregated at runtime **plus** a hardcoded core baseline of the most dangerous keys (auth tokens, identity fields) never delegated — so an absent/misconfigured companion can never silently drop token/identity scrubbing. Cache the resolved forbidden-key set on `attach_default_logger/1` (per-event aggregation otherwise).

- **D-6 — Contract tests split.** Keep core's integration test (existing stub companion) but drop the hardcoded `length(reserved_events) >= 24` assertion (→ shape assertion or stub-seeded). Each companion package owns its own Side-A "declared ⇔ emitted" proof. TELEM-04 Side-B vacuity is unchanged by extraction (`:telemetry` has no wildcard handler) — distribute emitted-side proof to each companion's suite rather than chase a fragile core test.

- **D-7 — Threadline observes purely by telemetry event-name** (`:telemetry.attach_many` over atom lists); **zero** compile deps on the others (verified — threadline's own code references no sibling companion). Owns its forbidden-key list locally (the "derived from sigra's 19 keys" note is provenance, not coupling — freeze as threadline's own). Wrap the audit handler in `try/rescue` (telemetry auto-detaches a raising handler → silent audit blackout). `mix crosswake.gen.audit` template path: `Application.app_dir(:crosswake → :crosswake_threadline)`. Consider making the `Crosswake.Live.Threadline` Phoenix dep optional. Correctly extracted **last** (core telemetry must decouple first).

- **D-8 — Independent versioning; companions depend only on core.** Separate release-please components, **not** in the `linked-versions` lockstep (lockstep = churn anti-pattern, per Ash/Broadway/Oban). Add a moduledoc note to `chimeway/contracts.ex`: *"`auth_context` is intentionally `map()` — do not tighten to `AuthContext.t()`"* to keep the inter-companion dep from creeping back. Compatibility matrix: one row per companion, single `Requires crosswake >= X` column; drift test keyed on the existing HTML-comment contract.

- **D-9 — Recipe gains a "Step 0: core decoupling" prerequisite** (`script/extract_companion.md` was written for clean seams; sigra isn't clean). Publish **sigra → chimeway → threadline sequentially**, registering one release-please component per PR (a misfire mustn't publish all three). Chimeway's clean-room lane must **not** install `crosswake_sigra` (else the decoupling proof is vacuous). Run the carried admin ship-gate (register merge-blocking lanes) before new v17.0 lanes land.

## Implied phase shape (continues from Phase 135 → 136+)

1. **Core decoupling** — invert all four coupling sites onto the registry seam; extend the `Companion` behaviour (D-1/D-2); add the core baseline PII denylist (D-5); extend AST guards to cover core `lib/` files (not just the companion dir). All existing tests + COMPAT-01 + the Phase-129 freeze test stay green. *No publish risk; high refactor risk.*
2. **`crosswake_sigra` extraction** — `Finding`-boundary refactor (D-4); dress rehearsal (path dep) → `hex.publish --dry-run` → clean-room → publish.
3. **`crosswake_chimeway` extraction** — telemetry-only coupling (cleaner); clean-room excludes sigra.
4. **`crosswake_threadline` extraction** — observer; telemetry-by-name; handler hardening; template `app_dir` fix.
5. **Family discipline + close** — compat-matrix rows, per-package contract tests, lifecycle/guards, register merge-blocking lanes.

## Footgun / risk register for the planner

- Removing the `build_reserved_events/0` static calls must be **atomic** — if sigra extracts before chimeway, a half-removal breaks the other. Move to runtime aggregation before removing either in-tree module.
- `support_matrix.ex` `@auth_contract_truth` / `@notification_support_truth` are **module attributes** that call companion functions at module-eval time → convert to `def` runtime helpers (module-attribute eval is the stale-beam trap).
- Audit `Denial.new` call sites across **all** sigra sub-modules (`handoff.ex`, `step_up_ceremony.ex`, `auth_return.ex` import `Handoff.SessionRenewalInstructions`) before extraction — the dependency graph is deeper than the surface files suggest.
- Chimeway clean-room must install `crosswake + crosswake_chimeway + chimeway` but **not** `crosswake_sigra` (vacuity guard).
- Three new unreclaimable Hex names (`crosswake_sigra`/`_chimeway`/`_threadline`) — dress-rehearsal + `--dry-run` mandatory for all three.
- Carried admin ship-gate: `DRY_RUN=0 script/register_required_checks.sh` (needs green-first on main + `BRANCH_PROTECTION_READ_TOKEN`).

## Ecosystem precedent (what to copy / avoid)

- **Copy:** PromEx plugin aggregation (`Enum.flat_map` over configured modules + optional callbacks); Swoosh `validate_dependency/0`; `:telemetry.attach_many` by event-name for decoupled observers; Ash/Broadway/Oban independent per-package versioning + "companions depend only on core."
- **Avoid:** Ash/Spark compile-time extension aggregation (assumes the contributor is compiled with the host — breaks for optional deps); Guardian fail-open `VerifyHeader` ordering footgun; Absinthe `absinthe_phoenix → absinthe_plug` companion-on-companion dep (combinatorial compat pain — cautionary, not a model); per-library telemetry catalogs with no programmatic discovery (Oban Pro "undeclared event" gap).
