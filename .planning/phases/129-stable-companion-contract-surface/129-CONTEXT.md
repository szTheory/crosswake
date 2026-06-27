# Phase 129: Stable Companion Contract Surface - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze and document the **public companion-contract surface** that soon-to-be-extracted Hex packages (`crosswake_rulestead`, `crosswake_rindle`) will depend on — **before** any code moves out of core (extraction begins Phase 130). This phase touches docs, moduledocs, ExDoc grouping, one new guide, and one merge-blocking proof test. **No code behaviour changes, no extraction, no package creation.**

The frozen public surface is exactly five modules:
- `Crosswake.Companion` (behaviour — already public)
- `Crosswake.Companion.State` (currently `@moduledoc false` → promote)
- `Crosswake.Compatibility.Finding` (currently `@moduledoc false` → promote)
- `Crosswake.Compatibility.Target` (currently `@moduledoc false` → promote)
- `Crosswake.Manifest.Types.RouteEntry` (currently `@moduledoc false` → promote)

Requirements: **SEAM-01, SEAM-02, SEAM-03, SEAM-04** (SEAM-05 is verified later when rindle extracts in Phase 132).
</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched (parallel subagents covering Elixir/Phoenix/Ecto/Oban/Broadway ecosystem idiom, DX, and footguns) and synthesized into one coherent, locked set. Decisions are mutually consistent and were chosen to make the contract surface least-surprising for external companion-package authors.

### Stability-note convention (SEAM-01)
- **D-01: Prose `## Stability` section** at the END of each public moduledoc is the stability signal — NOT a custom `@stability` attribute (ExDoc silently ignores unknown metadata keys; zero DX payoff) and NOT `tags:`-only (renders as a subtle sidebar filter, not visible body text). Prose is what an author actually reads.
- **D-02: Three-tier vocabulary, no more** — **public stable** (real `@moduledoc` + `## Stability` section), **private** (`@moduledoc false`), **patch-volatile** (documented-but-not-guaranteed). No patch-volatile modules are needed this phase; only the 5 public types + everything-else-private.
- **D-03: Supplement with `@moduledoc since: "0.1.0"`** on the four promoted types so hexdocs shows a version badge (must appear on its own line AFTER the moduledoc string).
- **D-04: Canonical `## Stability` template** (use verbatim across all 5 — do NOT hand-author per-module wording, it drifts and erodes trust):
  > `Public stable — part of the Crosswake companion contract surface. Semver-protected under \`crosswake\` >= 0.1.0: no breaking changes to this module's struct fields, types, or callbacks without a major version bump. Companion packages (\`crosswake_rulestead\`, \`crosswake_rindle\`, etc.) may safely \`alias\` and pattern-match on this type.`
- **D-05: Replace the stale `Crosswake.Companion` moduledoc line.** Current text ("Companions live in-tree under `lib/crosswake/companions/<name>/` for the v3.5 milestone and may be extracted to separate packages in a future milestone once the seam stabilizes.") is now false — extraction is happening. Replace with frozen-surface framing that names the 5 public modules and states they are semver-stable as of `crosswake` >= 0.1.0, all other modules internal. Place immediately before `## Implementing a companion`.
- **D-06: `RouteEntry` promotion must scope its guarantee.** Add a sentence noting that the OTHER nested modules in `Crosswake.Manifest.Types` (`Root`, `Host`, `Compatibility`, `Capability`, `PackEntry`, `CommerceCorridor`, …) remain `@moduledoc false` and internal — only `RouteEntry.t()` is contract.

### Guide scope & placement (SEAM-02, SEAM-04)
- **D-07: `guides/companion_contract.md` is a pure Diátaxis REFERENCE** — enumerate, don't tutorialize. Heart of it is a 5-row surface table (Module / role / what companion code does with it / stability tier). It does NOT reproduce callback specs (would diverge from `Crosswake.Companion`'s moduledoc — stays DRY via cross-link).
- **D-08: Clean division of responsibility** (no supersession, no rewrite of existing guides):
  - `companion_contract.md` (NEW) = *what is stable / what you may depend on* (reference)
  - `guides/companions.md` (existing) = *how to implement a companion* (how-to + explanation)
  - `guides/compatibility.md` (existing) = *what compatibility ranges to declare* (reference/explanation)
  - Reader journey: contract (what can I use?) → companions (how do I wire it?) → compatibility (what ranges do I declare?). Add a forward cross-link from companions.md to companion_contract.md.
- **D-09: Guide sections** — Intro (calm/explicit/honest brand voice) · Contract Surface table · Stability Tiers (2-bullet defs) · What Is Not Contract (explicit: any `@moduledoc false` module, eval-order internals, `Denial`, private helpers) · Declaring Compatibility (cross-link to `compatibility.md#companion-compatibility-contract`, don't duplicate) · Telemetry Events (the 3 static companion span names companions may observe).
- **D-10: hexdocs placement** — NEW `groups_for_extras` group **"Extension Authors"** holding `companion_contract.md`, positioned between `Truth` and `Advanced/Companions` (distinct audience JTBD: "what can I safely build against?"). NEW `groups_for_modules` entry **"Companion Contract"** listing the 5 modules **by full name** — NOT a regex. `~r/Crosswake\.Compatibility/` would wrongly pull the entire compatibility eval machinery into the contract group.
- **D-11: `@moduledoc false` is a hard prerequisite, not just cosmetic.** The 4 currently-private types are absent from hexdocs entirely; the `groups_for_modules` "Companion Contract" entry would render as an EMPTY heading until they get real moduledocs. Promote moduledocs FIRST.

### Contract-freeze test (SEAM-01 enforcement, success criterion 4)
- **D-12: Inline `behaviour_info(:callbacks)` equality assertion** (option b), matching the established codebase precedent (phase65, phase48, commerce_test). The hardcoded set IS the canonical "pre-phase-129 shape." Use `MapSet.equal?` (equality, not membership) so both removals AND additions fail.
- **D-13: Frozen callback set (6)** — `companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0`. (Confirm against `lib/crosswake/companion.ex` at plan time.)
- **D-14: Moduledoc assertion via `Code.fetch_docs/1`** — assert moduledoc is neither `false`, `:hidden`, nor `:none` (the closed EEP-48 enum) for all 5 types; also assert `@typedoc` present on the `t()` type of the 4 struct-bearing types. NOT `Code.Typespec.fetch_callbacks/1` full-AST comparison — brittle across Elixir versions and overkill; name/arity is the breaking-change boundary, dialyzer + PR diff catch type-narrowing.
- **D-15: Single source of truth for the module list** — derive the "Companion Contract" module set in the test from `Mix.Project.config()[:docs][:groups_for_modules]` rather than a third hardcoded copy, so `mix.exs` ↔ guide ↔ test cannot rot apart.
- **D-16: Test location & lane** — `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`, **untagged** so the existing PR-gating proof lane auto-picks it (no new workflow file). `async: true` (no Application state mutation). Use the existing `Crosswake.TestSupport.ProofAssertions.stable_id_message/7` helper.
- **D-17: Actionable failure UX** — on callback drift, the hint must say: "change `@expected_callbacks` in this test AND the `@callback` defs in companion.ex in the SAME PR so the reviewer sees the intentional shape change." On hidden/missing moduledoc, point at `guides/companion_contract.md` and SEAM-01.
- **D-18: Write-test-first forcing function** — the freeze test will FAIL until the 4 `@moduledoc false` promotions land; that failure is the intended driver, not a bug.

### Shell.Denial boundary (SEAM-03)
- **D-19: ACTIVE enforcement, folded INTO the freeze test** (not a separate file, not passive omission). Add two assertions against the "Companion Contract" `groups_for_modules` set: `Crosswake.Shell.Denial` is **absent**, `Crosswake.Compatibility.Finding` is **present** — guarding both edges of the boundary. Passive-only omission has zero CI value given the real drift risk.
- **D-20: Add a steering note to `Crosswake.Shell.Denial`'s own moduledoc** (it stays a public core type, just not part of the companion seam — no tension, idiomatic à la Plug.Conn caveats):
  > `Core-owned denial envelope. Not part of the companion contract surface. Companion implementations return \`{:deny, Crosswake.Compatibility.Finding.t()}\` from \`route_gated?/2\`; core translates findings into \`Denial\` structs internally. Extension authors should never construct or return a \`Denial\` directly — reach for \`Crosswake.Compatibility.Finding\` instead.`
- **D-21: Guide must explicitly state companions NEVER reference `Denial.reasons/0`** — they emit their own denial-code strings. (`guides/companions.md` line ~167 mentions `Denial.reasons/0` as a support-truth surface; the contract guide must not let an author infer companions author denials.)
- **D-22: Seam-audit finding (informational, no action this phase)** — the FROZEN `Crosswake.Companion` callback surface is clean: `route_gated?/2` speaks `Finding`, never `Denial`. `rulestead`/`rindle` are clean (zero `Denial` refs). `sigra` (`evaluator.ex`, `step_up_ceremony.ex`, `denial_codes.ex`) and `chimeway/resolver.ex` DO alias/construct `Denial`, but those are internal, non-`@behaviour`-conforming surfaces that extract later (EXTRACT-FUT-01). They must NOT be pulled into the contract guide or the "Companion Contract" group. Their in-tree visibility is the reason the D-20 steering note matters (authors cargo-cult the most-read companion code).

### Claude's Discretion
- Exact one-liner microcopy in the guide table rows and intro (within the established brand voice — calm, explicit, technical, honest).
- Precise wording of `ProofAssertions.stable_id_message` stable-id slugs (e.g. `proof.seam_01.companion.callback_shape`).
- Whether the `@typedoc` assertion covers only `t()` or additional exported types — researcher recommends `t()` for the 4 struct types; planner may extend if cheap.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 129" — goal, success criteria (4), depends-on Phase 128.
- `.planning/REQUIREMENTS.md` §SEAM (SEAM-01..05) and §"Out of Scope" — `Shell.Denial` exclusion rationale, module-rename exclusion, lockstep exclusion.
- `.planning/STATE.md` §"v16.0 Roadmap Decisions" — Phase 129 surfaces list + ordering rationale (freeze contract before packages depend on it).

### Contract types to promote/freeze (source files)
- `lib/crosswake/companion.ex` — behaviour, 6 `@callback`s, existing moduledoc (contains the stale line to replace, D-05).
- `lib/crosswake/companion/state.ex` — `@moduledoc false` → promote (D-11).
- `lib/crosswake/compatibility/compatibility.ex` — nested `Finding` and `Target` (both `@moduledoc false` → promote); parent `Crosswake.Compatibility` is NOT contract.
- `lib/crosswake/manifest/types.ex` — nested `RouteEntry` (`@moduledoc false` → promote, D-06); other nested types stay private.
- `lib/crosswake/shell/denial.ex` — add steering note (D-20); keep OUT of companion group (D-19).

### Docs config & guides
- `mix.exs` `defp docs/0` — `extras`, `groups_for_extras`, `groups_for_modules` (add "Extension Authors" + "Companion Contract" — D-10).
- `guides/companions.md` — existing how-to (avoid duplicating; add forward cross-link; note `Denial.reasons/0` mention at ~line 167).
- `guides/compatibility.md` — existing; the new guide cross-links to its "Companion Compatibility Contract" section, doesn't duplicate.
- NEW: `guides/companion_contract.md` (D-07..D-09).

### Test infra
- `test/crosswake/proof/` — existing PR-gating proof lane (untagged tests auto-included); read 1–2 existing proof/drift tests + `Crosswake.TestSupport.ProofAssertions` (`stable_id_message/7`) to match style.
- Precedents for `behaviour_info` membership/equality: `test/crosswake/proof/phase65_*`, `test/crosswake/proof/phase48_*`, `test/crosswake/commerce/contracts_test.exs`.

### Project DNA (voice / OSS conventions)
- `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-integrations-and-companions.md`, `prompts/crosswake-brand-book.md` (microcopy voice; prefer `brandbook/BRAND-SPEC.md` if it supersedes).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.TestSupport.ProofAssertions.stable_id_message/7` — standard merge-blocking failure-message helper; reuse for both callback-shape and moduledoc assertions.
- Existing `behaviour_info(:callbacks)` assertion precedent in 3 test files — copy the idiom (upgrade membership → equality for the freeze).
- `Code.fetch_docs/1` (EEP-48) — returns `{:docs_v1, _, _, _, moduledoc, _, docs}`; moduledoc ∈ `{:none, :hidden, %{"en"=>..}}` (closed enum) and per-entry `docs` carries `@typedoc`s.

### Established Patterns
- `@moduledoc false` is the ecosystem's binary "private" signal (Ecto/Phoenix/Plug). Crosswake's 104 internal modules already use it — the 5 public types are the deliberate exception.
- Proof tests live under `test/crosswake/proof/`, untagged, picked up by the PR-gating lane — no new CI workflow required for Phase 129.
- `route_gated?/2` returns `{:deny, Finding.t()} | :pass` (closed, no bare `term()`); `:pass` is the explicit non-denial — Finding↔Denial separation is already in the type system.

### Integration Points
- `mix.exs` docs config is the single source feeding hexdocs grouping AND (per D-15) the freeze test's module list.
- Phase 130+ extraction depends on this frozen surface; do not change callback shapes or struct fields here.

### Footguns surfaced by research (carry into planning)
- Empty hexdocs group if moduledoc promotion is skipped (D-11).
- Regex in `groups_for_modules` leaking eval machinery (D-10) — use full module names.
- Membership-only callback assertion silently passing on additions — use equality (D-12).
- Checking `moduledoc != false` but not `!= :none`/`:hidden` — check the full closed enum (D-14).
- In-tree sigra/chimeway `Denial` usage as accidental "how companions work" documentation (D-22) — steering note + guide language counter it.
</code_context>

<specifics>
## Specific Ideas

- Stability template (D-04) and Denial steering note (D-20) are provided verbatim above — use as-is, don't re-author.
- Ecosystem exemplars to mirror for grouping: **Broadway** (extension-point groups as first-class, not buried in "Advanced") and **ecto_sql** (core / specification / implementations three-tier split). Anti-pattern to avoid: **Plug** burying `Plug.Conn.Adapter` inside `Plug.Conn`.
- Response-ownership boundary precedent for D-19/D-20: Plug `halt/1`, Guardian `auth_error` callback (host owns the 401), Absinthe middleware `{:error, reason}` → framework envelope, Oban worker `perform/1` → core owns job-state transition. Companion owns *evidence* (`Finding`); core owns *envelope* (`Denial`).
</specifics>

<deferred>
## Deferred Ideas

- **Promoting iOS UAT / other LIFE work** — Phase 134, not here.
- **Removing in-tree `Denial` coupling in sigra/chimeway** — those companions extract in a FUTURE milestone (EXTRACT-FUT-01/02); Phase 129 only documents the boundary and steers authors away. No refactor this phase.
- **`boundary` library for compile-time public/private enforcement** — noted as a possible future hardening (research surfaced it); out of scope for 129's docs-and-one-test footprint.
- **Telemetry as full public API** — Phase 133 (`Crosswake.Telemetry.events/0` + guide). Phase 129's guide only references the 3 static companion span names companions may observe, not the full telemetry contract.

None of the above are scope creep into 129 — all map to existing later phases/milestones.
</deferred>

---

*Phase: 129-Stable Companion Contract Surface*
*Context gathered: 2026-06-25*
