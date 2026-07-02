# Phase 130: Extraction Mechanics & Footgun Guards - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Move the `Crosswake.Companions.Rulestead` **adapter** out of core into a standalone
`packages/crosswake_rulestead/` Hex project as a `path:` dep (a **no-publish dress
rehearsal** — the irreversible Hex publish is Phase 131), kill the `MIX_INCLUDE_*`
env hack, and stand up merge-blocking guards so core can never statically re-couple to
an extracted companion. Module name `Crosswake.Companions.Rulestead` is **preserved**
(non-breaking). Wire the runtime fail-closed enforcement so a registered+enabled
companion whose dependency is absent denies its gated route.

Requirements: **EXTRACT-01, EXTRACT-02, EXTRACT-03, EXTRACT-04, COMPAT-01.**

**Out of scope (defer):** Hex publish + release-please component wiring (Phase 131);
rindle extraction (Phase 132); the `FlagSource` behaviour + engine-backed runtime reader
(`Rulestead.Snapshot`-style — already a named deferral); sigra/chimeway extraction
(later milestone, EXTRACT-FUT).

### Three distinct things named "rulestead" (do not conflate — load-bearing)
1. `Crosswake.Companions.Rulestead` — the **adapter** in core → moves to `packages/crosswake_rulestead/`. **EXTRACT-03 bans static refs to THIS from core `lib/`.**
2. `Rulestead` (top-level) — the **external engine** Hex lib the adapter probes via `Code.ensure_loaded?(Rulestead)`. **EXTRACT-04 governs the call-site of this probe; it must NOT be banned.** COMPAT-01 toggles **this** module's presence.
3. `Crosswake.Companions.Rulestead.MockFlagSource` — an in-tree Agent used as the proof/demo flag source. Moves to the package's `test/support/`.
</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched in **two passes** (8 parallel subagents total): pass 1
established the shape; pass 2 red-teamed each against the project's own research corpus
(`prompts/`, `brandbook/BRAND-SPEC.md`, `guides/companions.md`) and the operator /
companion-author / adopter / contributor JTBD lenses. Every load-bearing fact below was
verified against the live code. Decisions are mutually coherent — the test-split in D-3x
is the reconciliation point between the fail-closed locus (①) and packaging (③).

### ① Fail-closed locus (COMPAT-01) — core-owned in RouteGate
- **D-01: Core (`RouteGate`) owns fail-closed-on-missing-dependency; companions never self-deny and never construct a `Denial`.** Preserves the locked Phase-129 Finding↔Denial boundary (D-19/D-20). Matches the brand promise "keep the boundary honest" and the Plug/Guardian/Oban "framework owns the envelope, plugin supplies evidence" idiom.
- **D-02: Precedence `dependency_missing → kill_switch_active → gate_denied`.** The dependency check fires FIRST: a companion whose code/engine isn't loaded cannot be trusted to answer kill-switch or gate questions, and `route_gated?/2` already fail-OPENS to `:pass` when its flag source is down — so absence must be caught upstream by a fail-CLOSED mechanism. RouteGate already filters to enabled+gated companions; keep that filter ahead of the dep check (a *disabled* companion with a missing dep is advisory, not a denial).
- **D-03: Synthesize the dependency-missing `Denial` INLINE in `prepend_gate_evaluation_findings/3`** (mirroring the existing inline kill-switch synth at route_gate.ex), **NOT** via `finding_to_denial/2` and **NOT** as a new `Finding` axis — dep-missing is a companion-lifecycle fact, not a compatibility axis; keep the axis space clean.
- **D-04: Add `:dependency_missing` to the closed `Crosswake.Shell.Denial.@reasons`** (currently **12** reasons — verified — this becomes the 13th) **and** to `@type reason`. JSON is safe (serialized via `Atom.to_string`), but the planner MUST grep for exhaustive `case ... reason` matches (shell, JSON formatter, operator inspection) and add a clause.
- **D-05: Reuse the SAME code string `"companion.dependency_missing"`** the doctor already emits (doctor.ex:589) across the cold (doctor) and hot (RouteGate) surfaces — one greppable identifier, no translation table.
- **D-06: Carry `details.missing_kind ∈ {:engine_unvalidated, :adapter_unloadable}`** so remediation diverges while the code string stays shared. `:engine_unvalidated` = `validate_dependency/0` returned `{:error,_}` (external engine absent → "add the dep"); `:adapter_unloadable` = the `:companions` registry names a module that won't load (config/typo → "fix the registry"). Flattening them ships a misleading remediation (violates the brand's "name what happened, what to do next"). The author still just returns `{:error, [module()]}`; **core infers `missing_kind` from WHERE the failure occurred** — zero new author-facing surface.
- **D-07: NO cache — live-compute on the gate path.** Drop the pass-1 `:persistent_term` snapshot. RouteGate already reads `Application.get_env(:crosswake, :companions, [])` live every evaluation; a cached dep-snapshot would manufacture a doctor(live)↔RouteGate(cached) TOCTOU and break the `Application.put_env` proof fixtures. Brand "no decision you cannot inspect" reinforces this. (If profiling ever demands caching: ETS read-through with the doctor reading the SAME cache — never `:persistent_term`.)
- **D-08: Fail closed even on a raise.** Wrap the registry-module-load check AND `validate_dependency/0` in `try/rescue/catch`; any exception → `:dependency_missing` + `missing_kind: :adapter_unloadable` + telemetry `:exception`. "Never crash" includes failing-closed on the check itself erroring.
- **D-09: Advisory softening lives only at doctor SEVERITY, never at the gate.** A route that names a companion via `gated_by` is load-bearing by definition → fail-closed is non-negotiable. No per-companion `fail_open` flag (would violate the brand promise). An enabled-but-*unused* companion with a missing dep may be `:warning` in the doctor, but a gated route always denies.
- **D-10 (PLANNER INVESTIGATION — do not skip): reconcile with the existing `on_unavailable` route-policy key.** `guides/companions.md:207` lists `on_unavailable` as an existing route-policy usage alongside `gated_by`/`auth_min_level`. There may already be a `RouteEntry.on_unavailable` (`:deny`) hook that COMPAT-01 enforcement should route THROUGH rather than inventing parallel logic. Confirm at plan time before designing the RouteGate change.

### ② Guard design (EXTRACT-03 static-ref + EXTRACT-04 ensure_loaded?-placement)
- **D-11: Bespoke AST proof, NOT the `boundary` library.** `boundary` can't model "a module leaving the app," can't express EXTRACT-04's call-site-position rule, adds a compile dep against lean-core discipline, and was explicitly deferred in Phase 129. Corpus mandates "named verification commands over opaque shell soup" and "fitness-functions are part of the product."
- **D-12: AST-primary; DROP `mix xref` entirely.** `mix xref`'s programmatic surface is unstable across Elixir minors and can't run cleanly from inside an ExUnit process (= the "opaque shell soup" the DNA warns against). The mechanism is `Code.string_to_quoted/2` + `Macro.prewalk/3` over `Path.wildcard(Path.join(File.cwd!(), "lib/**/*.ex"))` — stdlib-only, fully owned, immune to the `MyApp.Companions.Rulestead` moduledoc-example false-positive (string literals are not `{:__aliases__}` nodes).
- **D-13: Source of truth = a FROZEN HARDCODED MapSet in `Crosswake.CompanionGuard`** (the pass-1 "derive from `crosswake_*` `path:` deps" idea is a **phantom — verified core `mix.exs` has zero `path:`/`crosswake_*` deps and core names NO companion, so there is nothing to derive from, ever**). The set holds ONLY modules extracted so far (`Crosswake.Companions.Rulestead` now; `Crosswake.Companions.Rindle` added in 132), each with a comment naming its extraction phase. The DNA's "everything is named / inventories are intentional" makes the explicit set *more* honest, not less.
- **D-14: Scope EXTRACT-03 to the frozen set ONLY — never a blanket `Crosswake.Companions.*` ban.** Verified: core legitimately `alias`es `Companions.Sigra.*` (route_gate.ex:9, support_matrix, doctor.ex:790, policy/schema.ex:7) and `Companions.Chimeway.*` — these extract in a LATER milestone. A blanket ban bricks the build day one. When sigra/chimeway extract, the same PR adds them to the MapSet AND refactors those core aliases behind the seam — the guard turning red is the signal the refactor is incomplete.
- **D-15: Disambiguate the match targets.** EXTRACT-03 matches the **namespaced `Crosswake.Companions.Rulestead`** alias/remote-call AST nodes. EXTRACT-04 matches the **`Code.ensure_loaded?` call AST node (any argument)** — it must NOT key on raw `Rulestead` text (that would false-positive on the legitimate runtime probe).
- **D-16: EXTRACT-04 = AST prune-then-walk + a cheap textual belt.** Collect `def`/`defp`/`defmacro` body ASTs, assert every `Code.ensure_loaded?` node is reachable only inside one; assert zero at module-eval/`@attr` position. Add a belt regex flagging `Code.ensure_loaded?` at module-body indentation to escalate the macro/`unquote`-injected edge cases (low frequency today — all 13 call sites are direct `if Code.ensure_loaded?` inside functions — but non-zero going forward). AST stays authoritative; belt only escalates.
- **D-17: Cross-package = the guard TRAVELS WITH THE CODE.** Glob root is `Path.join(File.cwd!(), "lib/**/*.ex")`; each project runs its own guard suite against its own `lib/`. Core can NOT reach into `packages/*/lib/` (separate Mix projects, no path deps). In Phase 130 (in-tree) the core guard naturally covers `lib/crosswake/companions/**`; post-publish each package's EXTRACT-04 guard runs against its own `lib/` — non-vacuous because it ships with the code. (Avoids the WR-01 "vacuous proof" failure mode.)
- **D-18: One test file, two `describe` blocks, shared `Crosswake.CompanionGuard` support module.** Untagged, in the existing PR-gating proof lane — **must NOT carry `:requires_example_host`** (that tag would exclude it from the hermetic default lane). `async: true` (read-only source/config). ArchUnit/import-linter gold standard = one fitness-function suite, not scattered files.

### ③ Path-dep dress-rehearsal fidelity (EXTRACT-02)
- **D-19: Poncho-style `packages/crosswake_rulestead/` with a ONE-WAY dep `{:crosswake, path: "../.."}` — NO `runtime: false`.** (Pass-1 had `runtime: false` — that is an **ERROR**: core is a RUNTIME dep of the companion; `runtime: false` would leave `:crosswake`'s app un-started for a real adopter, a latent prod footgun the rehearsal wouldn't catch.) Two-way (core test-deps the companion) is rejected: a `path:` dep never carries the dependency's `test/support`, so two-way couldn't run the moved tests anyway, and it'd make core name a companion. Idiom = Membrane/Ash/Nerves poncho (independent semver, core never compile-deps a plugin).
- **D-20: TEST SPLIT (critical — do not "move all tests wholesale").** SC#1-class adapter-behavior tests (flag-state translation; phase42/phase43) → the **companion lane**. The **COMPAT-01 fail-closed contract test STAYS in core's hermetic lane** and exercises the companion through the `@behaviour` + `:companions` registry seam (register a stub/registry entry — NOT an `alias` to the moved source, which would re-couple and trip EXTRACT-03). Rationale: SC#5's "registered+enabled but package absent" state is only real where the engine is genuinely absent, and the most adopter-critical contract test must stay merge-blocking in core.
- **D-21: Delete BOTH `MIX_INCLUDE_*` blocks** (rulestead AND rindle) from core `mix.exs` — SC#1 says "no companion-conditional dep block." Rindle source stays in-tree until 132, but its dead env-hack dep block goes now. Core names no companion in any env.
- **D-22: `@version "0.1.0"` + a `# x-release-please-version` marker** in the companion `mix.exs` ONLY. Do NOT touch `.release-please-manifest.json` / `release-please-config.json`, and do NOT join the `linked-versions: "crosswake"` group (`hex`/`ios-core`/`android-core` @ 0.1.2 lockstep) — that's Phase 131. `crosswake_rulestead` 0.1.0 vs the external `rulestead` engine 0.1.6 is fine (different packages, different names) — document, don't engineer.
- **D-23: Copy a 3-line `StudySessionLive` stub into the companion's `test/support/`.** It's the sole test/support dep of the moved phase42 test and a contract-free `<div>` LiveView route target — no drift seam, no shared published test-support package (over-engineering), no trimming (the gated route needs a `live` target).
- **D-24: Dress-rehearsal fidelity beyond "it compiles":** the verify step runs `mix hex.build --unpack` (assert the `files:` allowlist + `test/` EXCLUDED), `mix hex.publish --dry-run`, and `mix compile --warnings-as-errors` in the package — these catch the "works with `path:` but breaks on Hex" class of bug BEFORE the irreversible 131 publish. Commit the companion's own `mix.lock` + CI `--check-locked`; document the `path:` → `{:crosswake, "~> 0.1"}` lock pivot for 131 in the checklist.
- **D-25: Ship a reusable extraction recipe — a parameterized checklist (`script/extract_companion.md`) + verify script, NOT a generator** (over-engineering for N=2 known companions). Makes rindle (132) mechanical → SEAM-05 becomes a passing test, not a hope. Headline structure: move source (preserve module names) → split tests (SC#1 → companion lane, SC#5 → core lane) → copy minimal test/support stubs → companion mix.exs (version+marker, `{:crosswake, path:}` no `runtime: false`) → commit lock → delete `MIX_INCLUDE_{COMPANION}` → wire CI lane + root alias → run verify script → run the three guards → DON'T touch release-please.
- **D-26: Root alias so contributors never need a bare `cd`.** `mix companions.test` (`cmd --cd packages/crosswake_rulestead mix test`) folded into a `mix verify` umbrella — the `cd packages/... && mix test`-only affordance is a DX wart.
- **D-27: Guard test asserting no companion core-dep carries `runtime: false`** (cheap; prevents the D-19 error recurring on rindle).

### ④ Engine-dep & test-support relocation (EXTRACT-02/04) — revise by SUBTRACTION
- **D-28: `{:rulestead, "~> 0.1", optional: true}` in the PACKAGE mix.exs + keep the runtime `Code.ensure_loaded?(Rulestead)` probe** (the Swoosh gold-standard optional-dep idiom). `optional: true` gives the adopter an installable handle; the probe stays runtime.
- **D-29: `@compile {:no_warn_undefined, Rulestead}` is REQUIRED, not optional.** Verified: `optional: true` alone does NOT silence the undefined-module warning in the engine-ABSENT build (the hermetic/COMPAT-01 state) — the two serve different jobs. Both are needed for the standalone package to compile `--warnings-as-errors`.
- **D-30: DROP the `FlagSource` behaviour + engine-backed default reader from Phase 130 (scope creep).** The corpus already names the engine reader as deferred (`mock_flag_source.ex` moduledoc), and shipping a `Rulestead.Snapshot`-shaped default couples the dress rehearsal to the engine's runtime read API (the DNA "unstable upstream extension point" footgun). The seam is the right *eventual* design — introduce it when the real engine reader lands, not in an extraction-mechanics phase.
- **D-31: Minimum fix to keep `lib/` compiling once `MockFlagSource` → `test/support/`: a one-symbol `Application.compile_env(:crosswake, [:rulestead, :flag_source], nil)` indirection** (Swoosh/Oban config-resolved idiom, NOT a Mox-style behaviour — there's exactly one eventual real backend). `lib/` references the indirection symbol, never the test module; shipped default `nil` → honest "no flag source configured" state (already fail-closed-gated upstream by `validate_dependency/0`). `MockFlagSource` moves to `test/support/` and is wired via `:test` config.
- **D-32: COMPAT-01 fail-closed locus = `validate_dependency/0` via `Code.ensure_loaded?(Rulestead)` — ALREADY implemented (rulestead.ex:99-108) AND already documented (`guides/companions.md:31`).** The doctor side of COMPAT-01 exists; the NEW work is the RouteGate hot-path enforcement (①) + the extraction. EXTRACT-04 guard is honest against this code today.
- **D-33: Two dep-states WITHOUT `MIX_INCLUDE`, never compile-baked.** Default `mix test` = engine-ABSENT (hermetic, merge-blocking; `Code.ensure_loaded?(Rulestead)` false → fail-closed; `@compile no_warn_undefined` lets it compile). Advisory green lane = a `test/support/engine_present/` **fake top-level `Rulestead` stub** appended to `elixirc_paths(:test)` only when the advisory lane is selected → `Code.ensure_loaded?` true at RUNTIME (presence is not compile-baked, so no stale-recompile footgun). Tag `:engine_present` / `:engine_absent`; the advisory lane runs with its own build dir / `mix clean` front to avoid a stale stub `.beam` leaking into the absent lane.

### Claude's Discretion
- Exact ExUnit module/file names, stable-id slug strings (e.g. `proof.extract_03.static_ref.<file>`), and the precise `Crosswake.CompanionGuard` helper API.
- Whether `missing_kind` lives in `details` as an atom or a string (lean atom; serialize at the JSON boundary).
- Exact microcopy wording within the brand voice (calm/explicit/honest, `[crosswake]` prefix, "the gate fails closed." present-tense). Draft strings for the doctor `:error` (both `missing_kind`s) and the two guard failure messages were produced in research — use as starting points, refine in voice.
- Whether the advisory engine-present lane uses a tag + conditional `elixirc_paths` or a separate alias — pick the cleaner of the two at plan time.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 130" — goal + 5 success criteria (SC#5 pins the fail-closed scenario verbatim); §"Phase 131"/"Phase 132" for what is deferred (publish, rindle).
- `.planning/REQUIREMENTS.md` §EXTRACT (EXTRACT-01..04), §COMPAT-01.
- `.planning/STATE.md` §"v16.0 Roadmap Decisions" — independent versioning, core never compile-deps a companion, phase-130 no-publish dress rehearsal, establish-pattern-first.
- `.planning/phases/129-stable-companion-contract-surface/129-CONTEXT.md` — the FROZEN contract surface (5 public modules), the Finding↔Denial ownership boundary (D-19/D-20), the `behaviour_info` freeze idiom, and `ProofAssertions.stable_id_message/7`.

### Core source to change / move
- `mix.exs` lines ~48-62 — the `MIX_INCLUDE_RULESTEAD`/`RINDLE` blocks to DELETE (both); `files:` allowlist (~line 78) + `elixirc_paths(:test)` to mirror in the package.
- `lib/crosswake/companions/rulestead.ex` — the adapter to move; `validate_dependency/0` (99-108) + `report_state/0` (121) hold the `Code.ensure_loaded?(Rulestead)` probe (already function-body, EXTRACT-04-clean); `route_gated?/2`/`kill_switch_active?/1` fail-OPEN to `:pass`/`false` on absent flag source (the reason the dep gate must be upstream).
- `lib/crosswake/companions/rulestead/mock_flag_source.ex` — moves to package `test/support/`; moduledoc already frames the engine reader as deferred.
- `lib/crosswake/compatibility/route_gate.ex` — `prepend_gate_evaluation_findings/3` (~100-130) is the inline-synthesis wiring site; existing kill-switch (121-147) + gate (149+) inline-`Denial` patterns to mirror; live `Application.get_env` read at :104.
- `lib/crosswake/shell/denial.ex` — `@reasons` (12 entries, lines 14-27) + `@type reason` to extend with `:dependency_missing`.
- `lib/crosswake/doctor/doctor.ex` — existing `companion.dependency_missing` `:error` finding (~564-618, code string at :589) to reuse + branch remediation on `missing_kind`.
- Legitimate sibling-companion static refs that SCOPE the EXTRACT-03 guard (must stay legal): `lib/crosswake/compatibility/route_gate.ex:9`, `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex:790`, `lib/crosswake/policy/schema.ex:7` (Sigra/Chimeway).

### Tests & guides
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` (SC#1 adapter-behavior + SC#3a; sole test/support dep = `Crosswake.TestSupport.StudySessionLive`) and `phase43_rulestead_advisory_test.exs` (engine-present green path; zero test/support deps) — split per D-20.
- `test/support/router_fixtures.ex` — `StudySessionLive` stub to copy (D-23).
- `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` + `phase65_diagnostic_export_seam_test.exs` — AST/source-assertion + self-match-avoidance idiom to mirror.
- `guides/companions.md` — §:31 documents `companion.dependency_missing` `:error` fail-closed; §:195 "Not a fail-open optional-dependency model"; §:207 the existing `on_unavailable` route-policy key (D-10); §:64 frames `MockFlagSource` as proof fixture.
- `guides/companion_contract.md` — the frozen 5-module surface the extraction must not widen.

### Project DNA / brand voice (microcopy + architecture stance)
- `prompts/crosswake-elixir-oss-dna.md` — fail-honestly stance (:128), "proof lanes are part of the product"/"no opaque shell soup", lean-core, "keep host-owned concerns in host code" (:121), sibling-package/independent-versioning guidance, the "unstable upstream extension point" footgun (:213).
- `prompts/crosswake-integrations-and-companions.md` — adapter↔engine relationship, "specific opt-in seams" not a "powerful ecosystem", integration heuristics (:226-238).
- `brandbook/BRAND-SPEC.md` (supersedes `prompts/crosswake-brand-book.md`) — §6 error-message rule ("name what happened, what to do next", calm/specific/actionable), §2 honest/explicit DNA, §4 `[crosswake]` CLI prefix + domain nouns, §20 "no decision you cannot inspect", §22 "name the specific value".
- `release-please-config.json` + `.release-please-manifest.json` — the `linked-versions: "crosswake"` group (`hex`/`ios-core`/`android-core` @ 0.1.2) the companion must NOT join (Phase 131 concern).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.TestSupport.ProofAssertions.stable_id_message/7` — merge-blocking failure-message helper; reuse for both guards' microcopy.
- Existing inline-`Denial` synthesis in `RouteGate.check_kill_switches/3` — copy the idiom for the dependency-missing `Denial` (D-03).
- `validate_dependency/0`'s `{:error, [module()]}` shape (rulestead.ex) — the Swoosh missing-module-list idiom; keep verbatim.
- The doctor's `companion.dependency_missing` `:error` finding — already built; extend with `missing_kind` branching rather than re-implementing.

### Established Patterns
- Optional dep = `optional: true` declaration + runtime `Code.ensure_loaded?` probe + `@compile {:no_warn_undefined, Mod}` (Swoosh/Phoenix/Oban). `store_kit`/`play_billing` already use the probe half.
- Proof tests live untagged under `test/crosswake/proof/`, auto-picked by the PR-gating hermetic lane (avoid `:requires_example_host`).
- `Code.string_to_quoted/2` + `Macro.prewalk/3` over `Path.wildcard` is the repo's idiomatic source/AST assertion mechanism (phase65/phase129).
- Companions FURTHER-RESTRICT only; a broken companion restricts to nothing → fail-closed is the purest expression (companion.ex:84-86).

### Integration Points
- `RouteGate.prepend_gate_evaluation_findings/3` — the single hot-path enforcement site; live `Application.get_env(:crosswake, :companions)` read (no compile-time coupling to companions — preserve).
- `Denial.@reasons` closed enum — adding `:dependency_missing` ripples to exhaustive matches; sweep before adding.
- `mix.exs` `elixirc_paths(:test)` + `files:` allowlist — the package mirrors these; the engine-present fake `Rulestead` rides a conditional `elixirc_paths`.
- The frozen companion-contract module set (Phase 129) — the ④ subtraction (no `FlagSource` behaviour) keeps that surface from widening.

### Footguns surfaced by research (carry into planning)
- **`runtime: false` on the companion's core dep is WRONG** — core is a runtime dep (D-19).
- **"Derive guard set from path deps" is a phantom** — core names no companion; hardcode a frozen MapSet (D-13).
- **Blanket `Companions.*` ban bricks the build** — Sigra/Chimeway legitimately referenced (D-14).
- **`:persistent_term` cache → doctor↔RouteGate TOCTOU + breaks `put_env` fixtures** — live-compute (D-07).
- **Move-all-tests-wholesale orphans COMPAT-01** from the merge-blocking core lane — split (D-20).
- **Shipping `MockFlagSource` as a `lib/` runtime default** silently fail-opens — config-indirection + move to test/support (D-31).
- **Compile-baking engine presence** (`@attr Code.ensure_loaded?`) = stale-recompile footgun — keep the probe in a function body; the engine-present test toggles a runtime-loaded stub (D-16/D-33).
- **Guard vacuity after the move** if it only scans core `lib/` — guard travels with the code (D-17).
</code_context>

<specifics>
## Specific Ideas

- Microcopy drafts (brand voice) exist for: doctor `:error` for `missing_kind: :engine_unvalidated` ("…its dependency is not loaded… companion dependencies are not pulled transitively; the host app declares them") and `:adapter_unloadable` ("…registered in :companions but its module … will not load. Check the module name — this is a registration error, not a missing dependency"); runtime denial message ("…the gate fails closed."); and both guard failures (leading `[crosswake]`, naming the boundary crossed + the one fix + the stale-recompile/compile-vs-runtime footgun). Use as starting points, finalize in voice.
- Adopter mix.exs target shape (Swoosh-grade, hides packaging guts): `{:crosswake, "~> 0.1"}` + `{:crosswake_rulestead, "~> 0.1", optional: true}` + `{:rulestead, "~> 0.1.6"}`, then `config :crosswake, :companions, [Crosswake.Companions.Rulestead]` + `config :crosswake, :rulestead, enabled: true`.
- Ecosystem exemplars: Membrane/Ash/Nerves (poncho, core never compile-deps a plugin, independent semver); Swoosh/Oban (config-resolved test-vs-prod, behaviour only when multiple real backends); Envoy/OPA `failure_mode_allow: false` (gateway owns the fail-closed default). ArchUnit/import-linter (one fitness-function suite, teaching messages); dependency-cruiser (cautionary tale against regex/grep detection).
</specifics>

<deferred>
## Deferred Ideas

- **`FlagSource` behaviour + engine-backed (`Rulestead.Snapshot`-style) runtime reader** — the right eventual seam, but out of Phase-130 extraction-mechanics scope; introduce when the real engine reader lands.
- **Hex publish + release-please separate-component wiring** — Phase 131 (EXTRACT-05/06).
- **rindle extraction via the identical recipe** + cross-package compat matrix — Phase 132 (EXTRACT-07).
- **sigra/chimeway extraction** (refactor the 5 legitimate core aliases behind the seam, add to the guard MapSet) — later milestone (EXTRACT-FUT); Phase 130 only keeps them legal.
- **`boundary` library for compile-time layering** — possible future hardening; rejected for this phase (can't model module-leaving-the-app or call-site rules; lean-core).
- **ETS read-through cache for the dep check** — only if profiling shows the live check is hot; doctor must read the same cache.

None of the above are scope creep into 130 — all map to existing later phases/milestones.
</deferred>

---

*Phase: 130-Extraction Mechanics & Footgun Guards*
*Context gathered: 2026-06-25*
