# Phase 43: Rulestead Hermetic+Advisory Proof And Guide - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the CI proof posture for the rulestead companion and the first section
of `guides/companions.md` locked by a docs-contract test.

**Delivers:**
- A dedicated `phase43-proof.yml` CI workflow with two jobs:
  - `merge-blocking-rulestead-proof` — hermetic, macOS-15, runs on PR + push + workflow_dispatch; rulestead absent from dep tree; proves all fail-closed behavior passes
  - `advisory-rulestead-proof` — `continue-on-error: true`, schedule + workflow_dispatch only; rulestead present as optional dep; runs the same Phase 42 proof suite and proves `validate_dependency/0` returns `:ok`
- `guides/companions.md` — new file; short companion-pattern intro (2-4 sentences) + complete rulestead section covering `gated_by` DSL, gate-state semantics, kill-switch behavior, and MockFlagSource as the mock swap target
- `test/crosswake/guides/companions_test.exs` — docs-contract test asserting key anchor strings in the guide match live code

**Satisfies:** PROOF-01 (hermetic + advisory lanes), PROOF-02 (rulestead section of guides/companions.md)

**In scope:**
- `phase43-proof.yml` — new CI workflow file with hermetic and advisory jobs
- rulestead added to `mix.exs` as an optional/conditional dep (mechanism: planner decides — env-var conditional or `:only` environment; the hermetic lane must compile and run WITHOUT rulestead; the advisory lane must compile and run WITH rulestead)
- Phase 42 proof test update: the `validate_dependency/0` assertion that currently asserts `{:error, [:"Elixir.Rulestead"]}` is correct in the hermetic context; in the advisory context it should assert `:ok` — planner decides whether this is a separate advisory test file or a conditional assertion
- `guides/companions.md` — created fresh (file does not exist)
- `test/crosswake/guides/companions_test.exs` — new docs-contract test
- Promotion path documented in the CI workflow header (same style as phase34-proof.yml)

**Out of scope:**
- Real `Rulestead.Snapshot` adapter (optional dep presence + validate_dependency :ok is sufficient for Phase 43 advisory lane; real flag-reading adapter is the Phase 43 advisory-to-merge-blocking promotion target)
- Rindle or Sigra sections in guides/companions.md — Phases 44-47
- Placeholder headings for rindle/sigra in the guide (avoid implied surface-area commitments)
- Full companion arc guide overview — Phase 47
- `mix crosswake.gen.companion` generator — deferred (v3.5+ future phase)

</domain>

<decisions>
## Implementation Decisions

### ① Advisory lane depth — LOCKED
- **D-01:** Option C. Add rulestead as an optional/conditional dep to `mix.exs`. The advisory CI job runs the existing Phase 42 proof suite with rulestead present. The key proof point: `validate_dependency/0` returns `:ok` when the dep is present, vs. `{:error, [:"Elixir.Rulestead"]}` when absent (hermetic lane). The real `Rulestead.Snapshot` adapter is explicitly documented as the advisory-to-merge-blocking promotion target — NOT shipped in Phase 43.
- **D-02:** The ROADMAP SC#2 language "same suite with rulestead present" is the authority here. The advisory lane does not need new test files; it runs the Phase 42 proof suite in an environment where `Code.ensure_loaded?(Rulestead)` returns true.
- **D-03:** Promotion path (documented in CI workflow header) requires: (1) real `Rulestead.Snapshot` adapter shipped and in-tree, (2) advisory lane exercising actual flag reads (not just dependency presence), (3) sustained stability evidence, (4) explicit roadmap scope change. Follows the 4-condition `promotion_path` from phase34-proof.yml.

### ② Hermetic dep isolation mechanic — Claude's Discretion
- Planner decides HOW rulestead is excluded from the hermetic lane while included in the advisory lane. Options: environment-variable conditional in `mix.exs` (`if System.get_env("MIX_INCLUDE_RULESTEAD") == "1", do: [...], else: []`), `:only` custom env (e.g., `only: :advisory`), or the advisory CI job performs a `mix deps.get` step that force-includes the optional dep. The constraint is hard: hermetic lane MUST compile and pass without rulestead in the dep tree; advisory MUST compile and pass with it present.
- The Phase 42 proof test's `validate_dependency/0` assertion (`assert Crosswake.Companions.Rulestead.validate_dependency() == {:error, [:"Elixir.Rulestead"]}`) is correct for the hermetic context. If the advisory lane runs the same test file, this assertion will fail (because rulestead IS present). Planner decides: add a separate advisory-specific test file that inverts the assertion, or use a `System.get_env` guard inside the test, or restructure so the hermetic and advisory lanes run different test targets.

### ③ guides/companions.md scope — LOCKED
- **D-04:** Create `guides/companions.md` fresh (file does not exist). Structure:
  1. **Short companion-pattern intro** (2-4 sentences): what the companion pattern is — how companions gate routes via the `Crosswake.Companion` behaviour, the role of optional deps and fail-closed semantics, and the hermetic+advisory proof posture they carry. This intro applies universally (not rulestead-specific) so nothing is wasted when Phase 47 expands the file.
  2. **Rulestead section** (complete): `gated_by` DSL declaration, gate-state semantics (`:gated` → deny, `{:rolling_out, n}` → deny with percentage, `:killed` → kill-switch short-circuit), kill-switch behavior and fail-closed guarantee, MockFlagSource as the dev/test mock swap target (with example of how to set flag state), and a note on the real flag-reading adapter as the production swap target.
- **D-05:** No rindle/sigra headings or placeholder sections. The guide's scope is explicit: rulestead companion, companion pattern intro. Phase 47 adds more sections without needing to clean up placeholders.
- **D-06:** The rulestead section must use exact DSL vocabulary that matches live code (`gated_by`, `on_unavailable: :deny`, `:kill_switch_active`) so the docs-contract test can assert string presence against canonical symbols.

### ④ Docs-contract test — LOCKED
- **D-07:** Test file: `test/crosswake/guides/companions_test.exs`. Pattern: mirrors `test/crosswake/guides/commerce_test.exs` — `File.read!("guides/companions.md")`, `setup_all` returning the content, individual tests asserting `content =~ "anchor_string"`. Use `async: false` for consistency with the guides test pattern (though these tests are read-only).
- **D-08:** Key anchors to assert (planner may refine): `"gated_by"`, `"kill_switch"`, `"MockFlagSource"`, `"on_unavailable"`, `"fail-closed"` (or equivalent canonical phrase). At least one `function_exported?` check confirming a live code symbol referenced in the guide actually exists (e.g., `SupportMatrix.gating_truth/0` or `Doctor.run/2`).

### Claude's Discretion
- Exact `phase43-proof.yml` job names and structure — follow `phase34-proof.yml` naming conventions (`merge-blocking-rulestead-proof`, `advisory-rulestead-proof`)
- macOS-15 vs. ubuntu-latest runner choices (follow phase34/41 pattern: macOS for merge-blocking, ubuntu for advisory placeholder steps if any)
- Exact timeout-minutes values — 20 for hermetic, 30 for advisory (following phase34 pattern)
- Exact CI workflow header comment explaining the hermetic+advisory split (follow phase34-proof.yml style closely — the header there is the canonical explanation template)
- Whether the advisory lane runs on a weekly schedule (Monday 06:00 UTC) or only on workflow_dispatch — the commerce advisory runs weekly; the rulestead advisory may too since it's the same pattern
- Exact anchor strings in the docs-contract test (beyond the D-08 minimum set above)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 43" — goal, success criteria SC#1–SC#3 (authoritative scope definition)
- `.planning/REQUIREMENTS.md` §PROOF — PROOF-01, PROOF-02 (the two requirements this phase satisfies)

### CI workflow pattern (hermetic+advisory split)
- `.github/workflows/phase34-proof.yml` — **primary pattern reference**: two-job split, `continue-on-error: true` advisory job, schedule trigger, 4-condition promotion path in the header comment. This is the template for `phase43-proof.yml`.
- `.github/workflows/phase41-proof.yml` — hermetic-only pattern reference (for contrast: no advisory job, simpler structure)

### Phase 42 proof test (the "same suite" the advisory lane runs)
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — the test file Phase 43 reuses in both lanes; the `validate_dependency/0` assertion (`{:error, [:"Elixir.Rulestead"]}` in hermetic) needs handling for the advisory lane where it returns `:ok`. Planner must resolve this tension.

### Companion behaviour and implementation (what the proof lanes verify)
- `lib/crosswake/companion.ex` — `Crosswake.Companion` behaviour; `validate_dependency/0` callback contract
- `lib/crosswake/companions/rulestead.ex` (or `rulestead/rulestead.ex`) — `Crosswake.Companions.Rulestead` companion impl; `validate_dependency/0` implementation using `Code.ensure_loaded?(:"Elixir.Rulestead")`
- `lib/crosswake/companions/rulestead/mock_flag_source.ex` — `MockFlagSource` Agent; the mock swap target documented in the guide

### Docs-contract test pattern
- `test/crosswake/guides/commerce_test.exs` — **primary pattern reference** for `companions_test.exs`: `File.read!` guide, `setup_all`, `assert content =~ "anchor"`, `function_exported?` checks
- `guides/commerce.md` — reference for guide style and voice (companion guide should match this quality level)

### mix.exs (dep addition target)
- `mix.exs` — where rulestead optional dep is added; currently has no rulestead entry; `deps/0` function is the target

### Prior phase context
- `.planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-CONTEXT.md` — D-04 (advisory Rulestead.Snapshot adapter deferred to Phase 43), D-10 (validate_dependency checks `Code.ensure_loaded?(Rulestead)`)
- `.planning/phases/40-runtime-gate-evaluation-and-fail-closed-denial/40-CONTEXT.md` — gate-state semantics reference (D-03/D-05: OpenFeature-shaped finding, `:gate_denied`/`:kill_switch_active`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `phase34-proof.yml` — copy the two-job structure, header comment, `if:` guard on the hermetic job, `continue-on-error: true` on the advisory job, schedule cron expression, and the advisory lane status summary step
- `test/crosswake/guides/commerce_test.exs` — copy the `File.read!` + `setup_all` + `assert content =~` test structure verbatim; adjust for companions.md anchors
- `Crosswake.Companions.Rulestead.MockFlagSource` — already exists at `lib/crosswake/companions/rulestead/mock_flag_source.ex`; document this as the mock swap target in the guide
- `phase42_rulestead_companion_test.exs` — the "same suite" that both CI lanes run (with and without rulestead in dep tree)

### Established Patterns
- Proof test files are untagged (no `@moduletag`), picked up by `mix test --exclude requires_example_host` automatically
- Advisory jobs use ubuntu-latest when no macOS-specific steps exist; switch to macOS-15 only when the advisory step requires it (e.g., a Simulator step)
- Hermetic jobs use macOS-15 for BEAM compilation consistency with the full test suite
- `async: false` in all companion proof tests (global `Application.put_env` state)
- Guide anchor strings should map 1:1 to canonical code symbols (function names, DSL keys) so the docs-contract test stays mechanically verifiable

### Integration Points
- `mix.exs` `deps/0` — add rulestead dep here (conditional or optional); no other mix.exs changes
- `.github/workflows/` — new `phase43-proof.yml` alongside existing proof YAMLs
- `test/crosswake/guides/` — new `companions_test.exs` alongside `commerce_test.exs`
- `guides/` — new `companions.md` alongside existing guide files

</code_context>

<specifics>
## Specific Ideas

- The Phase 42 `validate_dependency/0` test asserts `{:error, [:"Elixir.Rulestead"]}` — this is CORRECT in the hermetic context (rulestead absent). In the advisory context (rulestead present), the same assertion would fail. One clean resolution: the advisory CI job runs a SEPARATE test file (e.g., `phase43_rulestead_advisory_test.exs`) that inverts the assertion (`assert Rulestead.validate_dependency() == :ok`) and keeps phase42's hermetic test unchanged. Planner decides.
- The promotion-path in the CI workflow header should explicitly name what the real `Rulestead.Snapshot` adapter looks like (the API surface it consumes from the rulestead library) — this documents the advisory-to-merge-blocking path more concretely than the commerce placeholder, since rulestead is a szTheory library that Crosswake could ship an adapter for in a future phase.
- The `guides/companions.md` rulestead section should include a short code snippet showing how to set MockFlagSource state in a test (e.g., `MockFlagSource.set_flag(:rulestead, :killed)`) — this makes the guide immediately actionable for adopters writing their own tests.

</specifics>

<deferred>
## Deferred Ideas

- **Real `Rulestead.Snapshot` adapter** — the production swap target for MockFlagSource; reads actual flag state from `Rulestead.Snapshot` or `Rulestead.Runtime`. This is explicitly the advisory-to-merge-blocking promotion target; deferred from Phase 43 to preserve API-stability (rulestead is at v0.x). When shipped, the advisory lane upgrades from "dep presence + validate_dependency :ok" to "actual flag reads exercised hermetically."
- **Rindle/Sigra guide sections** — Phases 44-47 add these to companions.md. No placeholders left in Phase 43's file.
- **Full companion arc guide (Phase 47)** — overview section, non-goals (chimeway seam-only, full sigra machinery, threadline), cross-companion docs-contract parity. Phase 43 only adds the intro + rulestead section.
- **`mix crosswake.gen.companion` generator** — deferred until the second companion (rindle) validates the convention.

</deferred>

---

*Phase: 43-rulestead-hermetic-advisory-proof-and-guide*
*Context gathered: 2026-05-30*
