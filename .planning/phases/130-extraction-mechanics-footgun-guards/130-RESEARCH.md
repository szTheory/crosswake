# Phase 130: Extraction Mechanics & Footgun Guards — Research

**Researched:** 2026-06-25
**Domain:** Elixir companion extraction, path-dep dress rehearsal, merge-blocking AST proof guards, fail-closed RouteGate enforcement
**Confidence:** HIGH

---

> **Framing note:** CONTEXT.md is authoritative for all 33 decisions (D-01…D-33). This research does not re-derive them. Its scope is the three open planner investigations (D-10, D-04, D-32) and the Validation Architecture that Nyquist requires.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All 33 decisions (D-01…D-33) as recorded in 130-CONTEXT.md are locked. Summary of the load-bearing ones:

- D-01…D-09: RouteGate owns fail-closed enforcement; `:dependency_missing` Denial synthesized inline in `prepend_gate_evaluation_findings/3`; `missing_kind ∈ {:engine_unvalidated, :adapter_unloadable}`; no cache.
- D-10: Planner must reconcile with existing `on_unavailable` hook before designing RouteGate change. (RESOLVED — see Open Investigation #1 below.)
- D-11…D-18: Bespoke AST proof (no `boundary` lib); frozen MapSet of extracted modules in `Crosswake.CompanionGuard`; EXTRACT-03 scopes to rulestead only; untagged, `async: true`, no `:requires_example_host`.
- D-19…D-27: Poncho `path:` dep, NO `runtime: false`; test split (adapter-behavior → companion lane; COMPAT-01 → core hermetic); delete both `MIX_INCLUDE_*` blocks; `@version "0.1.0"` + marker; copy `StudySessionLive` stub; dress-rehearsal verify (`hex.build --unpack`, `--dry-run`, `--warnings-as-errors`); extraction recipe checklist; root alias `mix companions.test`.
- D-28…D-33: `optional: true` + `@compile {:no_warn_undefined, Rulestead}`; drop FlagSource behaviour; config-indirection for MockFlagSource; `validate_dependency/0` already exists; engine-present test lane via fake top-level `Rulestead` stub in `test/support/engine_present/`; `:engine_present` / `:engine_absent` tags.

### Claude's Discretion
- Exact ExUnit module/file names, stable-id slug strings.
- Whether `missing_kind` lives in `details` as an atom or string (lean atom; serialize at JSON boundary).
- Exact microcopy wording within brand voice.
- Whether the advisory engine-present lane uses a tag + conditional `elixirc_paths` or a separate alias.

### Deferred Ideas (OUT OF SCOPE)
- `FlagSource` behaviour + engine-backed runtime reader.
- Hex publish + release-please component wiring (Phase 131).
- rindle extraction (Phase 132).
- sigra/chimeway extraction (later milestone, EXTRACT-FUT).
- `boundary` library for compile-time layering.
- ETS read-through cache for the dep check.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXTRACT-01 | Core `mix.exs` contains no `MIX_INCLUDE_RULESTEAD`/`MIX_INCLUDE_RINDLE` blocks; companions appear only in adopter/example/test mix files | Verified: both env-hack blocks exist at mix.exs:48-62; DELETE both (rindle source stays in-tree, but its dead dep block goes now per D-21) |
| EXTRACT-02 | `packages/crosswake_rulestead/` is a fully self-contained Hex project; module name `Crosswake.Companions.Rulestead` preserved; tests pass against core as a `path:` dep | Dress-rehearsal verify: `mix hex.build --unpack` + `--dry-run` + `--warnings-as-errors`; poncho idiom confirmed; `mix hex.build` supports `--unpack` (Hex v2.4.2 on Elixir 1.19.5/OTP 28); `@compile {:no_warn_undefined, Rulestead}` required for absent-engine build (D-29) |
| EXTRACT-03 | Merge-blocking guard fails build if any `lib/` file statically references an extracted companion module | AST guard via `Crosswake.CompanionGuard`; frozen MapSet of extracted modules; legitimate Sigra/Chimeway aliases excluded (D-14); core currently has ZERO `path:` companion deps confirming D-13 |
| EXTRACT-04 | Guard verifies `Code.ensure_loaded?` calls for a companion occur inside function bodies, never at module-eval time | 13 call sites in `lib/` verified; all inside `def`/`defp` bodies; AST prune-then-walk + belt regex (D-16) |
| COMPAT-01 | Doctor returns `:error` `companion.dependency_missing`; RouteGate fail-closes the gated route when companion registered+enabled but package absent | Doctor path already exists (rulestead.ex:99-108 + doctor.ex:564-618); RouteGate hot-path enforcement is the new work; inline Denial synthesis mirroring kill-switch pattern (D-03) |
</phase_requirements>

---

## Open Investigation #1 — D-10: `on_unavailable` hook reconciliation (RESOLVED)

**Verdict: `on_unavailable` is a transition-routing field, NOT a denial-production mechanism. The RouteGate dep-check does not route through it.**

### What the code shows

`RouteEntry.on_unavailable :: :deny | {:fallback_phoenix, atom()} | nil` (manifest/types.ex:273).

`on_unavailable` is consumed exclusively in `transition_for_non_notification_denial/2` (route_gate.ex:77-87), which maps a denial's *post-decision transition* — `:halt` vs `{:redirect, id}`. It is read AFTER `prepend_gate_evaluation_findings/3` has already produced the `Denial.t()`.

The `guides/companions.md:48-56` example (line 55: `on_unavailable: :deny`) names the value `:deny` as indicating the route is a hard-deny (no fallback redirect), not a hook into denial production logic. The `:deny` atom is simply the absence of `{:fallback_phoenix, route_id}`.

The doctor (`doctor.ex:625+` `phase_41_gating_findings/1`) reads `on_unavailable` only to emit a `:warning "gating.fallback_route_unknown"` advisory when the fallback target is missing — entirely separate from the fail-closed enforcement path.

**Conclusion for planning:** The new `dependency_missing` Denial is synthesized inline in `prepend_gate_evaluation_findings/3` exactly as D-03 specifies. No existing `on_unavailable` hook to route through. After `prepend_gate_evaluation_findings/3` returns the `[%Denial{reason: :dependency_missing}]`, `transition_for/3` then reads `route.on_unavailable` to decide whether the native app halts or redirects — this is already correct behavior, no change needed.

**Planner action:** Design the RouteGate change around `prepend_gate_evaluation_findings/3` only. No changes to `transition_for_non_notification_denial/2`.

---

## Open Investigation #2 — D-04: Exhaustive `case ... reason` match sites (RESOLVED)

**The `@reasons` enum currently has 12 atoms (verified at denial.ex:14-27). Adding `:dependency_missing` makes 13. The following sites must be updated:**

### Site 1 — `denial.ex:57` `@reasons` list and `@type reason` (lines 14-44)
**Action required:** Add `:dependency_missing` to `@reasons` list AND to `@type reason` union. This is the canonical source; all other sites flow from it.

### Site 2 — `doctor_test.exs:107-121` — HARDCODED exhaustive list
**File:** `test/crosswake/doctor/doctor_test.exs`
**Lines:** 107-121
**The assertion:**
```elixir
assert report.bridge.denial_reasons |> Enum.sort() ==
  Enum.sort([
    "commerce_corridor",
    "compatibility_mismatch",
    "external_entry_denied",
    "gate_denied",
    "inactive_route",
    "kill_switch_active",
    "notification_open_denied",
    "origin_denied",
    "pack_incompatible",
    "step_up_required",
    "undeclared_capability",
    "unavailable_capability"
  ])
```
**Action required:** Add `"dependency_missing"` to this hardcoded list. The planner MUST include this as an acceptance criterion and `read_first` for the denial.ex change plan.

### Site 3 — `bridge_contract_vectors.json` (multiple paths) — GENERATED FIXTURE
**Files:**
- `test/fixtures/bridge_contract_vectors.json`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`
- `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json`

The `denial_reasons` array in these files is generated by `mix crosswake.contract.gen` from `Denial.reasons()`. Adding `:dependency_missing` to `@reasons` means these fixtures must be regenerated (run `mix crosswake.contract.gen`) before the contract drift test passes. **The planner must include a `mix crosswake.contract.gen` step** after the denial.ex change.

### Safe dynamic sites (no action needed)

| File | Line | Pattern | Why safe |
|------|------|---------|----------|
| `operator_inspection.ex` | 387-388 | `reason in Enum.map(Denial.reasons(), &Atom.to_string/1)` | Dynamic — auto-extends |
| `denial.ex` | 92/113 | `ensure_commerce_corridor_payload(:commerce_corridor, ...)` + catch-all | Catch-all wildcard; `:dependency_missing` falls through to `_reason` clause |
| `shell/activation.ex` | 241-242 | `%Denial{reason: :commerce_corridor}` + catch-all | Pattern match, not exhaustive; catch-all handles new reason |
| `doctor/doctor.ex` | 1399 | `Enum.map(Denial.reasons(), &Atom.to_string/1)` | Dynamic — auto-extends |
| `publish_readiness.ex` | 688 | `Enum.map(Denial.reasons(), &Atom.to_string/1)` | Dynamic — auto-extends |
| `mix/tasks/crosswake.contract.gen.ex` | 78 | `Denial.reasons() \|> Enum.map(...)` | Dynamic — auto-extends; drives the fixture regeneration |
| `compatibility.ex` | `recovery_for/*` | Only matches specific axes, not denial reasons | `recovery_for` is called from `finding_to_denial/2` which is NOT invoked for dep-missing (D-03 bypasses it) |

**Summary for planner:** Two hardcoded sites require manual edits (denial.ex enum + doctor_test.exs list). One site requires running `mix crosswake.contract.gen` to regenerate 3 fixture files. All other sites are dynamically derived and auto-extend.

---

## Open Investigation #3 — D-32: `validate_dependency/0` and doctor `companion.dependency_missing` (RESOLVED)

**Both exist exactly as described. Scope confirmed = wire hot-path + extract, not build from scratch.**

### `validate_dependency/0` — rulestead.ex:99-108
```elixir
def validate_dependency do
  if Code.ensure_loaded?(Rulestead) do
    :ok
  else
    {:error, [Rulestead]}
  end
end
```
- Located at rulestead.ex:99-108. [VERIFIED: live codebase grep]
- Returns `{:error, [Rulestead]}` when Rulestead is absent (the normal state in hermetic tests).
- `Code.ensure_loaded?(Rulestead)` is inside a `def` body — EXTRACT-04-clean. [VERIFIED: live codebase grep]

### Doctor `companion.dependency_missing` — doctor.ex:564-618
- `phase_38_companion_seam_findings/0` at doctor.ex:564-618. [VERIFIED: live file read]
- Emits code string `"companion.dependency_missing"` at line 589. [VERIFIED: live file read]
- Uses `{true, {:error, mods}}` pattern; the `mods` list is `[Rulestead]` (a module list, not a string).
- **New work for COMPAT-01:** The doctor finding currently carries `%{missing_modules: mods}` in details. Per D-06, the RouteGate Denial must carry `details.missing_kind ∈ {:engine_unvalidated, :adapter_unloadable}`. The doctor finding and the RouteGate Denial are structurally parallel but NOT identical — they serve different surfaces (cold doctor vs hot gate). Core infers `missing_kind` from WHERE the failure occurred; no new author surface required.
- **D-05 confirmed:** Both surfaces use the same code string `"companion.dependency_missing"`. No translation table.

### RouteGate `prepend_gate_evaluation_findings/3` — route_gate.ex:100-119
The injection site for the new dependency check is the gated-route clause at lines 100-119. The existing inline Denial synthesis for kill-switch (lines 121-147) is the direct idiom to mirror for the dependency-missing case. [VERIFIED: live file read]

---

## Validation Architecture

> Required: Nyquist VALIDATION.md depends on this section. All 5 success criteria (SC#1–SC#5) and 5 requirements (EXTRACT-01..04, COMPAT-01) are mapped below.

### Proof Lane Definitions

| Lane | Tag | CI trigger | Blocking |
|------|-----|-----------|---------|
| **Core hermetic** | untagged (default) | Every PR and push to main | Yes — merge-blocking |
| **Companion lane** | (new CI workflow `phase130-proof.yml` companion job) | Every PR | Yes for structural tests; advisory for engine-present |
| **Engine-present advisory** | `:engine_present` | Schedule + dispatch | No — advisory only |
| **Engine-absent explicit** | `:engine_absent` | Every PR | Yes — merge-blocking |

### SC#1 — No `MIX_INCLUDE_*` in core mix.exs (EXTRACT-01)

| Property | Value |
|----------|-------|
| Proof lane | Core hermetic (untagged) |
| Assertion mechanism | Source assertion: `File.read!(mix_exs_path)` — `refute String.contains?(source, "MIX_INCLUDE_RULESTEAD")` AND `refute String.contains?(source, "MIX_INCLUDE_RINDLE")` |
| Non-vacuity proof | Positive-control test: inject `"MIX_INCLUDE_RULESTEAD"` string into in-memory source, assert it would be detected |
| File | `test/crosswake/proof/phase130_extraction_guards_test.exs` (new, shared with SC#3/SC#4) |
| Automated command | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` |

### SC#2 — `packages/crosswake_rulestead/` is a self-contained Hex project (EXTRACT-02)

| Property | Value |
|----------|-------|
| Proof lane | Companion lane (`phase130-proof.yml` companion job) |
| Assertion mechanism | Three-step verify script: (1) `mix hex.build --unpack -o /tmp/rulestead_unpack` — assert `test/` directory is ABSENT from unpacked tree; assert `lib/crosswake/companions/rulestead.ex` is PRESENT; (2) `mix hex.publish --dry-run` — must exit 0; (3) `mix compile --warnings-as-errors` in `packages/crosswake_rulestead/` in the engine-ABSENT state (no `Rulestead` loaded) |
| Non-vacuity proof | `mix hex.build --unpack` materializes a real directory; assert specific filenames inside it rather than just "directory exists" |
| File | `script/verify_companion_package.sh` (new; parameterized for rindle reuse in Phase 132) |
| Automated command | `(cd packages/crosswake_rulestead && mix hex.build --unpack -o /tmp/rulestead_unpack && mix hex.publish --dry-run && mix compile --warnings-as-errors)` |
| Elixir/Hex version note | Elixir 1.19.5 / OTP 28 / Hex v2.4.2 — `--unpack` and `--dry-run` flags confirmed available. [VERIFIED: `mix help hex.build` + `mix help hex.publish`] |

### SC#3 — Static-ref guard (EXTRACT-03)

| Property | Value |
|----------|-------|
| Proof lane | Core hermetic (untagged, `async: true`) in `Crosswake.Proof.Phase130ExtractionGuardsTest` |
| Assertion mechanism | `Crosswake.CompanionGuard.assert_no_static_refs!/0` — walks `Path.wildcard(Path.join(File.cwd!(), "lib/**/*.ex"))`, parses each with `Code.string_to_quoted/2`, walks AST with `Macro.prewalk/3`, detects `{:__aliases__, _, [:Crosswake, :Companions, :Rulestead]}` nodes (the namespaced alias form), fails with `stable_id_message/7` naming the file and line |
| Non-vacuity proof | Synthetic regression: test that `CompanionGuard.check_source/1` returns `:violation` for a deliberately injected source string containing `Crosswake.Companions.Rulestead` as an alias node, and returns `:ok` for a string containing `Crosswake.Companions.Sigra` (legitimate in-tree companion, must NOT trigger) |
| False-positive guard | String literals (e.g. moduledoc examples) are NOT `{:__aliases__}` AST nodes — confirmed by D-12. No special handling needed for doc strings |
| File | `test/crosswake/proof/phase130_extraction_guards_test.exs` |
| Automated command | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` |

### SC#4 — `Code.ensure_loaded?` placement guard (EXTRACT-04)

| Property | Value |
|----------|-------|
| Proof lane | Core hermetic (same file as SC#3, untagged) |
| Assertion mechanism | AST prune-then-walk: collect `def`/`defp`/`defmacro` body subtrees, assert every `{:., _, [{:__aliases__, _, [:Code]}, :ensure_loaded?]}` node appears inside a body (not at module-eval level). Belt: regex `~r/^[^#\n]*Code\.ensure_loaded\?/m` on raw source to detect any non-indented (module-body) occurrence as an escalation signal |
| Non-vacuity proof | The 13 live `Code.ensure_loaded?` call sites in `lib/` all resolve inside `def`/`defp` bodies — confirmed. The test is non-vacuous because it runs against the actual `lib/**/*.ex` glob (D-17: guard travels with the code). Synthetic regression: inject a fake source file into the glob path using a temp file approach, verify the guard catches a module-eval-level `Code.ensure_loaded?` |
| File | `test/crosswake/proof/phase130_extraction_guards_test.exs` |
| Automated command | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` |

**Additional guard from D-27:** Assert no companion's `{:crosswake, path:}` dep carries `runtime: false` (companion lane, `packages/crosswake_rulestead/mix.exs` source assertion).

### SC#5 — RouteGate fail-closed when companion registered+enabled but package absent (COMPAT-01)

| Property | Value |
|----------|-------|
| Proof lane | Core hermetic (untagged) — MUST NOT be in companion lane; this is the most adopter-critical contract test |
| Assertion mechanism | ExUnit behavior test: `Application.put_env/3` to register a stub companion module (via `:companions` registry seam, NOT an `alias` to the moved source — that would trip EXTRACT-03); `Application.put_env/3` to enable it; stub's `validate_dependency/0` returns `{:error, [SomeModule]}` (simulating absent engine); call `RouteGate.evaluate/4` with a gated route; assert `decision.status == :deny`; assert `decision.denial.reason == :dependency_missing`; assert `decision.denial.details["missing_kind"] == "engine_unvalidated"` (serialized as string at JSON boundary per Claude's Discretion) |
| Non-vacuity | The stub companion is NOT the real `Crosswake.Companions.Rulestead` module — it is a plain module defined in `test/support/` implementing the `@behaviour Crosswake.Companion` callbacks. This verifies the seam, not the moved code. The `:dependency_missing` denial is structurally impossible unless the new RouteGate code is present (proof is non-vacuous). |
| Precedence check | Test must also verify that D-02 precedence (`dependency_missing → kill_switch_active → gate_denied`) holds: a companion whose `validate_dependency/0` returns `{:error, _}` AND whose `kill_switch_active?/1` returns `true` produces `:dependency_missing` (not `:kill_switch_active`) |
| File | `test/crosswake/proof/phase130_fail_closed_contract_test.exs` (new, separate from guard tests for clarity) |
| Automated command | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` |

**D-08 coverage:** Test must also verify that a stub companion whose `validate_dependency/0` raises an exception still produces `:dependency_missing` (the `try/rescue` catch path fires).

### Engine-present / engine-absent lane tagging discipline

Per D-33: default `mix test` = engine-ABSENT (hermetic, merge-blocking). Tests that assert `Code.ensure_loaded?(Rulestead) == true` behavior MUST carry `@tag :engine_present`. Tests that explicitly assert `Code.ensure_loaded?(Rulestead) == false` behavior may carry `@tag :engine_absent` (or be untagged if they run fine in both states).

The fake `Rulestead` stub lives in `test/support/engine_present/` and is appended to `elixirc_paths(:test)` only when the advisory `:engine_present` lane runs. This prevents stale `.beam` leaking into the absent lane. The companion lane CI job must run with `mix clean` before switching between the two states.

**Critical non-vacuity principle (D-17):** The EXTRACT-03 and EXTRACT-04 guards run against `lib/**/*.ex` from `File.cwd!()`. In Phase 130 (in-tree), this is core's own `lib/`. After Phase 131 publishes the package, each companion project's own guard suite runs against its own `lib/` — the guard travels with the code, avoiding the WR-01 vacuous-proof failure mode.

### Requirement → Test Map Summary

| Req ID | SC# | Behavior | Test Type | File | Proof Lane |
|--------|-----|---------|-----------|------|-----------|
| EXTRACT-01 | SC#1 | No `MIX_INCLUDE_*` in core mix.exs | Source assertion | `phase130_extraction_guards_test.exs` | Core hermetic |
| EXTRACT-02 | SC#2 | Package is self-contained, `test/` excluded from tarball | Shell verify + compile | `script/verify_companion_package.sh` | Companion CI job |
| EXTRACT-03 | SC#3 | No static refs to extracted companion in `lib/` | AST walk | `phase130_extraction_guards_test.exs` | Core hermetic |
| EXTRACT-04 | SC#4 | `Code.ensure_loaded?` inside function bodies only | AST prune-walk + belt | `phase130_extraction_guards_test.exs` | Core hermetic |
| COMPAT-01 | SC#5 | RouteGate denies when companion registered+enabled but dep absent | Behavior test | `phase130_fail_closed_contract_test.exs` | Core hermetic |

### Wave 0 Gaps (test infrastructure before implementation)

- [ ] `test/crosswake/proof/phase130_extraction_guards_test.exs` — covers EXTRACT-01/03/04 (SC#1/3/4)
- [ ] `test/crosswake/proof/phase130_fail_closed_contract_test.exs` — covers COMPAT-01 (SC#5)
- [ ] `lib/crosswake/companion_guard.ex` — the `Crosswake.CompanionGuard` support module (AST logic, extracted for reuse and for EXTRACT-04 guard to work against its own source if needed)
- [ ] `script/verify_companion_package.sh` — parameterized dress-rehearsal verify (SC#2/EXTRACT-02)
- [ ] `packages/crosswake_rulestead/` skeleton — `mix.exs`, `lib/`, `test/` directory structure
- [ ] `.github/workflows/phase130-proof.yml` — companion lane CI

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (exists) |
| Quick run command | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs` |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fail-closed dep enforcement (hot path) | RouteGate (core) | — | D-01: core owns the denial envelope; companion cannot construct `Denial` |
| Fail-closed dep enforcement (cold path) | Doctor (core) | — | D-05: shared code string; doctor is the existing cold-path owner |
| Static-ref ban guard | Mix project (core `lib/`) | Companion `lib/` (post-publish) | D-17: guard travels with the code |
| `Code.ensure_loaded?` placement guard | Mix project (core `lib/`) | Companion `lib/` (post-publish) | D-17: same; runs against own `lib/` |
| Adapter source + adapter behavior tests | Companion package (`packages/crosswake_rulestead/`) | — | D-20: SC#1-class adapter tests move to companion lane |
| COMPAT-01 contract test (fail-closed) | Core hermetic lane | — | D-20: most adopter-critical contract test stays merge-blocking in core |
| Package build verification | Mix/Hex tooling (companion) | — | D-24: dress-rehearsal prevents "works with path: but breaks on Hex" bugs |

---

## Standard Stack

No new external dependencies are introduced for Phase 130. All tooling is in-tree or Hex tooling already installed.

### Package Legitimacy Audit

> No new packages. All operations use:
> - Elixir stdlib: `Code.string_to_quoted/2`, `Macro.prewalk/3`, `Path.wildcard/1`, `File.read!/1`, `Application.get_env/3`, `Application.put_env/3`
> - Hex tooling: `mix hex.build --unpack`, `mix hex.publish --dry-run` (Hex v2.4.2 installed, flags confirmed)
> - ExUnit: test framework (built-in)
>
> **No new packages to audit.**

---

## Common Pitfalls

### Pitfall 1: `runtime: false` on the companion's core dep (D-19)
**What goes wrong:** Companion's `mix.exs` declares `{:crosswake, path: "../..", runtime: false}`.
**Why it happens:** Confusion with dev-only deps. `runtime: false` is correct for compile-only tools, not for a runtime dep.
**How to avoid:** Core is a RUNTIME dep of the companion — a real adopter needs `:crosswake` application started. The `path:` dep must NOT carry `runtime: false`. The D-27 guard test asserts this.

### Pitfall 2: Moving ALL rulestead tests wholesale (D-20)
**What goes wrong:** `phase42_rulestead_companion_test.exs` AND `phase43_rulestead_advisory_test.exs` both moved to companion lane. The COMPAT-01 fail-closed proof (that the registered+enabled companion is denied at the gate when the package is absent) is now only in the companion lane — where the package IS present — making it vacuous.
**How to avoid:** Split: adapter-behavior tests (phase42/43 content) go to companion lane; COMPAT-01 RouteGate test stays in core hermetic lane using a stub companion (not an alias to the moved module).

### Pitfall 3: Compile-baking engine presence (D-33)
**What goes wrong:** Engine-present test uses `@compile_env` or module-level `Code.ensure_loaded?` to detect Rulestead. This bakes the detection at compile time, causing stale `.beam` if the dep is removed without `mix clean`.
**How to avoid:** Engine-present test lane loads a fake top-level `Rulestead` stub from `test/support/engine_present/` via conditional `elixirc_paths(:test)`. The check remains runtime (`Code.ensure_loaded?` inside a function body). Always run `mix clean` before switching between engine-present and engine-absent builds in CI.

### Pitfall 4: Blanket `Crosswake.Companions.*` ban in EXTRACT-03 guard (D-14)
**What goes wrong:** Guard bans all `Crosswake.Companions.*` aliases. `route_gate.ex:9` aliases `Crosswake.Companions.Sigra.Evaluator` — guard trips on day one, build broken.
**How to avoid:** Guard uses a frozen MapSet of ONLY extracted modules. In Phase 130, only `Crosswake.Companions.Rulestead` is in the set. When sigra/chimeway extract in a later milestone, the same PR adds them to the MapSet AND refactors the aliases.

### Pitfall 5: "Derive guard set from path deps" phantom (D-13)
**What goes wrong:** Guard tries to derive the extracted-module set by scanning `mix.exs` for `path:` or `crosswake_*` deps.
**Why it happens:** Seems clever. Is broken. Core's `mix.exs` names NO companion path deps (poncho style) — there is nothing to derive from.
**How to avoid:** Hardcode a frozen MapSet in `Crosswake.CompanionGuard`. Comment each entry with its extraction phase.

### Pitfall 6: Missing `@compile {:no_warn_undefined, Rulestead}` (D-29)
**What goes wrong:** Package compiles fine with `optional: true` declared but raises a warning (treated as error by `--warnings-as-errors`) in the engine-ABSENT state because `Rulestead` is referenced in code but not loaded.
**Why it happens:** `optional: true` tells Hex dependency resolution to not require the dep; it does NOT silence the Elixir compiler's undefined-module warning. The two directives are orthogonal.
**How to avoid:** Both `{:rulestead, "~> 0.1", optional: true}` AND `@compile {:no_warn_undefined, Rulestead}` are required in the companion's `mix.exs` and source respectively.

### Pitfall 7: `denial_reasons` fixture drift (D-04 consequence)
**What goes wrong:** `:dependency_missing` is added to `Denial.@reasons` but `mix crosswake.contract.gen` is not run. Three `bridge_contract_vectors.json` files still list 12 reasons. The contract drift test (`contract_drift_test.exs`) checks bridge_protocol_version only (not denial count) but the doctor test (`doctor_test.exs:107-121`) hardcodes the 12-reason list — it fails.
**How to avoid:** After adding `:dependency_missing` to `denial.ex`, run `mix crosswake.contract.gen` and commit the regenerated fixtures. Update `doctor_test.exs` to include `"dependency_missing"` in the hardcoded list.

---

## Dress-Rehearsal Verify Commands (EXTRACT-02 fidelity)

All confirmed available on the development machine (Elixir 1.19.5 / OTP 28 / Hex v2.4.2):

```bash
# 1. Build and unpack — verify files: allowlist excludes test/
cd packages/crosswake_rulestead
mix hex.build --unpack -o /tmp/rulestead_unpack
# Assert: /tmp/rulestead_unpack/test/ does NOT exist
# Assert: /tmp/rulestead_unpack/lib/crosswake/companions/rulestead.ex EXISTS

# 2. Dry-run publish — catch "works locally but breaks on Hex" errors
mix hex.publish --dry-run

# 3. Compile in engine-ABSENT state (the hermetic state)
mix compile --warnings-as-errors
# Requires: @compile {:no_warn_undefined, Rulestead} in rulestead.ex
#           {:rulestead, "~> 0.1", optional: true} in mix.exs
```

**`path:` dep idiom (D-19):**
```elixir
# packages/crosswake_rulestead/mix.exs
defp deps do
  [
    {:crosswake, path: "../.."},           # NO runtime: false — core is a runtime dep
    {:rulestead, "~> 0.1", optional: true} # engine is optional
  ]
end
```

**`@compile` directive (D-29) — required in rulestead.ex:**
```elixir
@compile {:no_warn_undefined, Rulestead}

def validate_dependency do
  if Code.ensure_loaded?(Rulestead) do
    :ok
  else
    {:error, [Rulestead]}
  end
end
```

---

## Architecture Patterns

### RouteGate Dep-Missing Injection Site

The injection point is `prepend_gate_evaluation_findings/3` at route_gate.ex:100-119. The new dep check fires BEFORE the existing kill-switch check (D-02 precedence: `dependency_missing → kill_switch_active → gate_denied`). The existing inline-Denial synthesis for kill-switch (route_gate.ex:121-147) is the direct idiom to mirror:

```elixir
# Pattern to mirror (existing kill-switch synthesis, route_gate.ex:135-146)
denial =
  Denial.new(
    reason: :kill_switch_active,
    message: "kill switch active for companion #{companion.companion_id()}",
    route_id: route.id,
    details: %{"companion_id" => Atom.to_string(companion.companion_id())}
  )

# New dep-missing synthesis (same pattern):
denial =
  Denial.new(
    reason: :dependency_missing,
    message: "[crosswake] companion #{companion.companion_id()} is registered and enabled but its dependency is not loaded. The gate fails closed.",
    route_id: route.id,
    details: %{
      "companion_id" => Atom.to_string(companion.companion_id()),
      "missing_kind" => Atom.to_string(missing_kind)  # :engine_unvalidated or :adapter_unloadable
    }
  )
```

### AST Guard Pattern (mirrors phase129/phase65)

```elixir
# From phase129_companion_contract_freeze_test.exs — idiom to mirror
source = File.read!(Path.join(File.cwd!(), "lib/crosswake/companions/rulestead.ex"))
{:ok, ast} = Code.string_to_quoted(source, file: path)
Macro.prewalk(ast, [], fn
  {:__aliases__, _, [:Crosswake, :Companions, :Rulestead]} = node, acc ->
    {node, [{path, node} | acc]}
  node, acc ->
    {node, acc}
end)
```

### `mix companions.test` Root Alias (D-26)

```elixir
# core mix.exs aliases section
defp aliases do
  [
    "companions.test": ["cmd --cd packages/crosswake_rulestead mix test"],
    "verify": ["companions.test", "test --exclude requires_example_host --exclude advisory_only"]
  ]
end
```

---

## Code Examples

### COMPAT-01 Stub Companion (core hermetic test, NOT an alias to moved source)

```elixir
# In test/crosswake/proof/phase130_fail_closed_contract_test.exs
defmodule Crosswake.TestSupport.StubDepMissingCompanion do
  @behaviour Crosswake.Companion

  def companion_id, do: :stub_dep_missing
  def enabled?(_config), do: true
  def validate_dependency, do: {:error, [SomeAbsentModule]}
  def route_gated?(_route, _target), do: :pass  # would fail-open but dep gate fires first
  def kill_switch_active?(_target), do: false
  def report_state, do: %Crosswake.Companion.State{companion_id: :stub_dep_missing, enabled: true, dependency_status: {:missing, [SomeAbsentModule]}, gate_status: :unconfigured, kill_switch_status: :unconfigured, checked_at: 0}
end
```

### D-33 Engine-Present Lane Tag

```elixir
# In packages/crosswake_rulestead/test/crosswake/proof/phase43_rulestead_advisory_test.exs (moved)
@moduletag :engine_present

test "validate_dependency/0 returns :ok when Rulestead is loaded" do
  assert Rulestead.Companions.Rulestead.validate_dependency() == :ok
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `MIX_INCLUDE_*` env hack for optional companions | `path:` dep (Phase 130) → Hex dep (Phase 131) | Phase 130 | Companions are ordinary optional deps; no env hack in CI |
| Companion tests all in core | Test split: adapter-behavior → companion lane; contract → core | Phase 130 | Core hermetic lane stays fast; companion lane proves the extraction |
| No dep-missing gate enforcement on hot path | `RouteGate` inline `:dependency_missing` Denial | Phase 130 | A misconfigured adopter gets a clear denial, not a silent no-op or crash |
| `boundary` lib for compile-time layering | Bespoke AST guard (`Crosswake.CompanionGuard`) | Phase 130 | Stdlib-only, owned, models "module leaving the app" (boundary lib cannot) |

---

## Security Domain

> `security_enforcement` key absent from config.json — treated as enabled.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | Yes — fail-closed routing | RouteGate `:dependency_missing` denial; `try/rescue` in dep check (D-08) |
| V5 Input Validation | No — internal module loading | `Code.ensure_loaded?` is safe; no user input |
| V6 Cryptography | No | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Companion registered but dep absent → silent route allow | Elevation of privilege | RouteGate fail-closed Denial (D-01/D-02/D-03); `try/rescue` on exception (D-08) |
| Compile-baked engine presence → stale `.beam` confuses test state | Tampering (test integrity) | Runtime probe only; `mix clean` between lane switches; engine stub via `elixirc_paths` (D-33) |
| Static re-coupling of extracted companion → breaks poncho model | Denial of service (future extraction) | EXTRACT-03 AST guard; frozen MapSet; CI gate |
| Module-eval `Code.ensure_loaded?` → stale recompile footgun | Tampering | EXTRACT-04 AST guard |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.19.5 | — |
| OTP/Erlang | All | ✓ | OTP 28 (erts-16.3) | — |
| Hex | EXTRACT-02 dress rehearsal | ✓ | v2.4.2 | — |
| `mix hex.build --unpack` | EXTRACT-02 | ✓ | Confirmed in Hex v2.4.2 | — |
| `mix hex.publish --dry-run` | EXTRACT-02 | ✓ | Confirmed in Hex v2.4.2 | — |

**Missing dependencies with no fallback:** None.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `doctor_test.exs:107-121` is the ONLY hardcoded exhaustive list of denial reasons in the test suite | Open Investigation #2 | A second hardcoded list would remain stale and break tests; planner should `grep -rn "denial_reason.*exact\|Enum.sort.*denial"` test/ as a final check |
| A2 | No iOS or Android test file hardcodes the denial reason count (only the JSON fixtures which are regenerated) | Open Investigation #2 | If Swift/Kotlin tests also hardcode 12, they would need updating too; check `packages/crosswake-shell-core-ios/Tests/` and `packages/crosswake-shell-core-android/src/test/` |

---

## Sources

### Primary (HIGH confidence)

- Live codebase reads — `lib/crosswake/compatibility/route_gate.ex`, `lib/crosswake/companions/rulestead.ex`, `lib/crosswake/shell/denial.ex`, `lib/crosswake/doctor/doctor.ex:564-618`, `lib/crosswake/manifest/types.ex`, `guides/companions.md`, `mix.exs`, `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`, `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- `test/crosswake/doctor/doctor_test.exs:107-121` — hardcoded denial reason list identified
- `test/fixtures/bridge_contract_vectors.json` — 12 denial reasons confirmed
- `.github/workflows/phase43-proof.yml` — CI lane structure for the advisory/hermetic split
- `mix help hex.build` + `mix help hex.publish` — `--unpack` and `--dry-run` flags confirmed
- `.planning/phases/130-extraction-mechanics-footgun-guards/130-CONTEXT.md` — 33 locked decisions, all treated as authoritative [VERIFIED: live file read]
- `.planning/REQUIREMENTS.md` §EXTRACT, §COMPAT-01 [VERIFIED: live file read]
- `.planning/ROADMAP.md` §Phase 130 success criteria [VERIFIED: live file read]

### Secondary (MEDIUM confidence)

- `lib/crosswake/operator_inspection.ex:387-388` — dynamic `Denial.reasons()` call; auto-extends. [VERIFIED: live grep]
- `lib/crosswake/compatibility/compatibility.ex:143-184` — `finding_to_denial/2` axes; does NOT handle `:dependency_missing` (synthesized inline by RouteGate, per D-03). [VERIFIED: live file read]

---

## Metadata

**Confidence breakdown:**
- D-10 (on_unavailable) resolution: HIGH — live code reading confirms `transition_for_non_notification_denial` is the only consumer; no parallel denial-production logic
- D-04 (exhaustive case sites): HIGH — grep confirms exactly 2 sites need manual edits (denial.ex enum, doctor_test.exs list) plus `mix crosswake.contract.gen` for fixtures
- D-32 (validate_dependency + doctor finding): HIGH — both verified at exact file:line, no discrepancy from CONTEXT.md description
- Validation Architecture: HIGH — mirrors established proof patterns from phase129/phase65; all mechanisms are stdlib-only; test lane discipline is identical to phase43

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable codebase; no external API dependencies)
