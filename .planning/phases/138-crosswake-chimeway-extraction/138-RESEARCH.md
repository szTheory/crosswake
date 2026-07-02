# Phase 138: crosswake_chimeway Extraction - Research

**Researched:** 2026-07-02
**Domain:** Elixir companion extraction — no-engine pure-Elixir package + Hex publish pipeline
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHIME-01 | `chimeway` source + tests move to standalone `packages/crosswake_chimeway/` Hex project (own `mix.exs`, own `@version`), preserving `Crosswake.Companions.Chimeway.*` namespace. | Source file inventory confirmed: 6 sub-modules + facade. Test split table confirmed against live filesystem. Extraction recipe `script/extract_companion.md` proven on rulestead/rindle/sigra. |
| CHIME-02 | `crosswake_chimeway` depends only on core — no `crosswake_sigra` dependency; `auth_context` stays typed `map()` with a moduledoc note; clean-room lane installs `crosswake + crosswake_chimeway` but NOT `crosswake_sigra`. | VERIFIED: Zero `Sigra.*` references anywhere in chimeway source. `auth_context: map()` at `contracts.ex:275`. Clean-room script already has no-engine mode. Vacuity issue identified: smoke test needs chimeway-specific assertion (see Critical Finding). |
| CHIME-03 | `crosswake_chimeway` publishes to Hex as independent `release-please` component, preceded by dress rehearsal and gated by `hex.publish --dry-run` + clean-room before publish. | release-please-config.json, manifest, and release-please.yml patterns read verbatim. Chimeway block is a clone of the sigra block. 10-step gate sequence confirmed. |
</phase_requirements>

## Summary

Phase 138 is the second companion extraction in v17.0, and it is **simpler than Phase 137** in one critical way: chimeway has **zero compile-time dependency on sigra** (confirmed by live code grep). The "chimeway→sigra AuthContext dependency is a myth" claim is VERIFIED — chimeway uses `auth_context: map()` (a plain Elixir map), not `Sigra.Contracts.AuthContext`. No boundary-type refactor (analogous to Phase 137's `Finding` boundary work) is needed.

**However, chimeway's `Resolver` module has one complication sigra did not:** it uses `Crosswake.Shell.Denial` directly via `alias Crosswake.Shell.Denial` at `resolver.ex:13` and calls `Denial.new(...)` in `deny_no_route/3` (L99-106). After extraction, the `crosswake_chimeway` package will depend on core (which exports `Denial` as a core-private type). The question is: should `Resolver` emit `Denial.t()` directly (as a core-public type for its callers), or must it refactor to `Finding.t()` at the boundary? Since chimeway is NOT an auth companion (it is a notification companion), and `Resolver.resolve/3` is called by host code that processes `{:deny, Denial.t()}` results — **the resolver's denial output can remain `Denial.t()` for now**, since `Crosswake.Shell.Denial` is a core module that the package depends on. The package's `mix.exs` depends on `{:crosswake, "~> 0.1"}`, which includes `Denial`. This is structurally identical to how `crosswake_rindle` can use core types.

**Critical vacuity risk (unique to chimeway vs. sigra):** The `verify_companion_cleanroom.sh` no-engine smoke test asserts `refute Chimeway.enabled?(%{})` — but chimeway's `enabled?/1` defaults to `true` when the `:enabled` key is absent. This test assertion will **fail** for chimeway. The smoke test needs a chimeway-specific variant: `assert Chimeway.enabled?(%{})` and a positive `forbidden_metadata_keys/0` canary, similar to how rindle added a `media_state_vocabulary/0` canary. The clean-room script must be updated to handle this, or the clean-room CI job must supply a custom smoke override.

**Primary recommendation:** Follow `script/extract_companion.md` Steps 1-12 for chimeway (no-engine mode, no Finding boundary refactor needed), update the clean-room script's no-engine smoke test `enabled?` assertion for chimeway, and add a chimeway-specific canary to prove `Crosswake.Companions.Chimeway.Telemetry.event_names/0` shipped in the tarball.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Notification open resolution (Resolver.resolve/3) | Package (chimeway) | Core (RouteGate, which Resolver delegates to) | Resolver is chimeway-internal; it delegates to RouteGate for auth-predicated routing |
| Token binding registry (host-owned, example-host) | Host Application | — | Token bindings stay in host Ecto schemas; chimeway only provides the contract types |
| PII redaction (token scrubbing) | Package (chimeway.Redaction) | — | Raw-token boundary enforcement is chimeway-internal |
| Telemetry events/forbidden-keys aggregation | Core (Telemetry, via registry) | Package (Chimeway.Telemetry) | Core calls chimeway's `telemetry_events/0` + `forbidden_metadata_keys/0` at runtime |
| Package publication | CI (release-please) | Human gate (PR merge) | Standard rulestead/rindle/sigra pattern |
| Clean-room verification | CI (clean-room-proof-chimeway) | — | Post-publish lane; no-engine mode in verify_companion_cleanroom.sh |

## Standard Stack

### Core (no new deps — this is source + CI movement)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` | `~> 0.1` (Hex dep when CROSSWAKE_RELEASE=1) | Core runtime dep of the package | Env-conditional pattern proven on rulestead/rindle/sigra |
| `elixir` | `~> 1.19` | Language runtime | Matches core and sigra mix.exs |

### No Engine Optional Dep

Chimeway has no third-party engine library (unlike rulestead/rindle). Notification machinery is pure Elixir. No `{:some_engine, "~> 0.1", optional: true}` line is needed. `validate_dependency/0` on the facade returns `:ok` unconditionally. [VERIFIED: live code read — `chimeway.ex:29` `def validate_dependency, do: :ok`]

**Consequence for recipe:** Steps 6 (engine_present stub) and the `engine-present.test` alias are OMITTED for chimeway, identical to sigra. [VERIFIED: live code read]

### Supporting CI Infrastructure (already in repo)

| Script/File | Purpose |
|-------------|---------|
| `script/verify_companion_cleanroom.sh` | Post-publish clean-room verification (parametric, no-engine mode) |
| `script/strip_release_as.py` | Auto-strips one-shot `release-as` pin (PROOF-03) |
| `script/register_required_checks.sh` | Admin-only green-first required-check registration |
| `release-please-config.json` | Add chimeway component block (clone sigra block) |
| `.release-please-manifest.json` | Add `"packages/crosswake_chimeway": "0.1.0"` |
| `.github/workflows/release-please.yml` | Add ~100 lines: chimeway outputs + 3 new jobs |

## Package Legitimacy Audit

No new external packages are installed by this phase. `crosswake_chimeway` is a first-party package extracted from the monorepo. No third-party packages are added to any `mix.exs`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `crosswake_chimeway` | First-party (new) | — | — | github.com/szTheory/crosswake | First-party | Created by this phase |
| `crosswake` (as dep) | First-party | — | — | github.com/szTheory/crosswake | First-party | Already in use by rulestead/rindle/sigra packages |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

## No-Sigra-Dep Verification (the Linchpin)

**Claim: chimeway has zero compile-time reference to any `Sigra.*` module.**

**VERIFIED against live code (2026-07-02):**

```bash
$ grep -rn "Sigra\|sigra\|AuthContext" lib/crosswake/companions/chimeway/ lib/crosswake/companions/chimeway.ex
lib/crosswake/companions/chimeway/contracts.ex:255:      :auth_context
lib/crosswake/companions/chimeway/contracts.ex:263:      :auth_context,
lib/crosswake/companions/chimeway/contracts.ex:275:            auth_context: map(),
lib/crosswake/companions/chimeway/resolver.ex:46:              auth_context: evidence.auth_context
```

Every hit is `auth_context` as a plain `map()` field name or value — there is **no** `Crosswake.Companions.Sigra.*` reference, no `alias Sigra`, no `Sigra.Contracts.AuthContext` type. [VERIFIED: live code grep, 2026-07-02]

**The claim is TRUE.** Chimeway extraction does not require any inter-companion decoupling work before proceeding. The clean-room lane can install `crosswake + crosswake_chimeway` without `crosswake_sigra` and chimeway will compile cleanly.

**`auth_context: map()` moduledoc guard note (CHIME-02 requirement):**
The `NotificationOpenEvidence` struct at `contracts.ex:269-279` already types `auth_context: map()`. A moduledoc note must be added to `contracts.ex` (or a `@doc` note on the `NotificationOpenEvidence` module) stating: *"`auth_context` is intentionally `map()` — do not tighten to `AuthContext.t()` from `crosswake_sigra`; doing so would create an inter-companion dependency."* (D-8) [ASSUMED — exact wording; the requirement is VERIFIED]

## Drift Verification Report

### chimeway.ex facade — optional callbacks wired (Phase 136 gap-closure)

**Live code (chimeway.ex:58-76):**
```elixir
@impl true
def forbidden_metadata_keys, do: ChimewayTelemetry.forbidden_metadata_keys()

@impl true
def telemetry_events do
  ChimewayTelemetry.event_names()
  |> Enum.map(fn name ->
    %{event: name, tier: :reserved, description: "...", measurements: [], metadata: ChimewayTelemetry.metadata_keys()}
  end)
end
```

The `forbidden_metadata_keys/0` and `telemetry_events/0` optional callbacks ARE implemented and delegating to `ChimewayTelemetry`. Chimeway is NOT an auth authority — there is no `auth_authority?/0` callback (comment at line 55 confirms: "Chimeway is NOT an auth authority — auth_authority?/0 is intentionally absent"). [VERIFIED: live code read]

**`mix.exs` application/0 env comment (live, L28-31):**
```elixir
# In-tree registration bridge — Chimeway only after Phase-137 sigra extraction.
# Phase-138 extraction: remove Crosswake.Companions.Chimeway from this list when
# that module is extracted to the crosswake_chimeway package.
env: [companions: [Crosswake.Companions.Chimeway]]
```
Phase 137 already removed Sigra from this list and left Chimeway as the sole in-tree companion. Phase 138 removes `Crosswake.Companions.Chimeway` from this `env:` list and the `chimeway.ex` facade from core. [VERIFIED: live code read]

### resolver.ex — Denial.new usage (the one complication)

`resolver.ex:13` has `alias Crosswake.Shell.Denial` and calls `Denial.new(...)` in `deny_no_route/3` at L99-106 and `deny/2` at L109-111. After extraction to `packages/crosswake_chimeway/`, the package depends on `{:crosswake, "~> 0.1"}`, which exports `Crosswake.Shell.Denial`. Unlike sigra (which had a D-4 boundary mandate to emit `Finding` not `Denial`), chimeway is a notification companion whose `Resolver.resolve/3` return signature `{:allow, Decision.t()} | {:deny, Denial.t()}` is used by host code directly. **No Finding boundary refactor is required for chimeway.** The package will simply depend on core's `Denial` type as it does today. [VERIFIED: live code read + no analogous D-138-A decision exists]

**Key difference from sigra:** Sigra required D-137-A (emit `Finding` at package boundary because `evaluate_auth/3` returns into RouteGate's accumulator). Chimeway's `Resolver.resolve/3` is called by host code, not by core — it does not flow through any core accumulator that enforces a companion-public type. `Denial` is accessible from packages that depend on core.

### companion_guard.ex — chimeway already in banned list

`companion_guard.ex:44-46` already includes `"Crosswake.Companions.Chimeway"` in `@extracted_companion_names`. This means after extraction, any new static reference to chimeway in core `lib/` would fail the CI guard. [VERIFIED: live code read]

The extraction guard passes because: core's telemetry, route_gate, support_matrix, and doctor were all decoupled in Phase 136. Chimeway is registered in the `companion_guard.ex` `@extracted_companion_names` list but the guard's scope exclusion (`lib_files -- companion_files`) still allows references within `lib/crosswake/companions/chimeway/`. After extraction, those files will not be in core anymore. [VERIFIED: live code read]

### Source Files to Move (CHIME-01)

All move from `lib/crosswake/companions/chimeway/` to `packages/crosswake_chimeway/lib/crosswake/companions/chimeway/`:

[VERIFIED: live filesystem grep]
- `contracts.ex` (sub-modules: TokenEvidence, TokenBinding, ProviderFeedback, BindingEvent, BindingResult, NotificationOpenEvidence, OpenResolution)
- `denial_codes.ex`
- `intent_consumer.ex`
- `redaction.ex`
- `resolver.ex` (contains `alias Crosswake.Shell.Denial` — keep, no refactor needed)
- `telemetry.ex`

Plus the facade: `lib/crosswake/companions/chimeway.ex` → `packages/crosswake_chimeway/lib/crosswake/companions/chimeway.ex`

**Diff from sigra:** Sigra had 8 sub-modules. Chimeway has 6 sub-modules. No `step_up.ex`, `step_up_ceremony.ex`, `auth_return.ex`, `handoff.ex`, `evaluator.ex` equivalents — chimeway is notification machinery, not auth machinery.

### Test Split Verification (CHIME-01)

**Core chimeway test files confirmed present:** [VERIFIED: live filesystem]

| File | Classification | Lane |
|------|---------------|------|
| `test/crosswake/companions/chimeway_test.exs` | Facade contract test | MOVE → package |
| `test/crosswake/companions/chimeway/contracts_test.exs` | Chimeway-internal | MOVE → package |
| `test/crosswake/companions/chimeway/denial_codes_test.exs` | Chimeway-internal | MOVE → package |
| `test/crosswake/companions/chimeway/redaction_test.exs` | Chimeway-internal | MOVE → package |
| `test/crosswake/companions/chimeway/resolver_test.exs` | Chimeway-internal (Resolver.resolve/3) | MOVE → package |
| `test/crosswake/companions/chimeway/telemetry_test.exs` | Chimeway-internal | MOVE → package |
| `test/crosswake/proof/phase59_chimeway_contract_test.exs` | Integration — uses `SupportMatrix`, `Chimeway.report_state()`, `Telemetry`, `Redaction`, `Contracts` | **SPLIT** — see below |
| `test/crosswake/proof/phase60_chimeway_registry_test.exs` | Host-integration (`@requires_example_host`); source-level assertions on example-host files | STAY in core |

**Phase59 split analysis:**

| Test in phase59 | Calls | Lane |
|-----------------|-------|------|
| "TOKN-02 lifecycle semantics stay explicit..." | `Contracts.lifecycle_mapping/0` | MOVE → package |
| "seeded raw token is absent from...output" | `Redaction`, `Telemetry.metadata/1`, `Contracts.to_map/1` | MOVE → package |
| "companion state and support matrix..." | `Chimeway.report_state()` AND `SupportMatrix.notification_support_truth/0` | **SPLIT** — SupportMatrix assertion STAYS in core |
| "public Chimeway structs never define raw token aliases" | `TokenEvidence`, `TokenBinding`, `ProviderFeedback`, `BindingEvent`, `BindingResult` | MOVE → package |
| "delivery_accepted remains provider handoff evidence only" | `Contracts.new_provider_feedback/1`, `Contracts.to_map/1` | MOVE → package |

**Phase59 split result:**
- `packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs` — 4 tests (TOKN-02, raw-token absence, public-struct aliases, delivery_accepted)
- New/retained in core: the `SupportMatrix.notification_support_truth/0` assertion portion (1 test) — stays as `test/crosswake/proof/phase59_chimeway_support_truth_test.exs`

**Phase71 — in sigra package, uses `Chimeway.Resolver` (must MOVE to chimeway package):**
`packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs` currently lives in the sigra package because it was moved there during Phase 137. However, it uses `Crosswake.Companions.Chimeway.Resolver` as its PRIMARY subject (plus `Sigra.Contracts` for auth context setup). After chimeway extraction, this test's primary dependency is the chimeway package. It must move: `packages/crosswake_sigra/.../phase71_notification_workflow_proof_test.exs` → `packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs`. The test registers Sigra via `Application.put_env` in setup — this still works in the chimeway package test suite if the chimeway package depends on `crosswake` (which provides the companions registry), and the test additionally lists `crosswake_sigra` as a test dependency via path dep OR registers a stub. [ASSUMED — exact dependency strategy for phase71's Sigra alias; planner must decide: path dep on sigra in chimeway test suite, OR replace SigraContracts alias with plain maps]

**Phase73 — in sigra package, uses SigraContracts but primarily tests auth+chimeway integration:**
`packages/crosswake_sigra/test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` — check if it uses chimeway or just sigra. [NEEDS PLANNER VERIFICATION — may stay in sigra package if chimeway is not directly exercised]

## Architecture Patterns

### System Architecture Diagram

```
[Host Application]
    config :crosswake, :companions, [Crosswake.Companions.Chimeway]
         |
         v
[Host code calls Chimeway.Resolver.resolve/3]
    |
    +-- Resolver.resolve(%Root{}, %NotificationOpenEvidence{}, intent_consumer)
    |       |
    |       +-- Route lookup (manifest.routes)
    |       +-- notification_open_allowed?(route)
    |       +-- action_allowed?(route, evidence.action_ref)
    |       +-- intent_consumer.consume_intent(evidence)
    |               |
    |               v (host-owned: DB lookup, idempotency)
    |         {:ok, %OpenResolution{state: :valid}}
    |               |
    |               v
    |       +-- RouteGate.evaluate(manifest, evidence.route_id, target,
    |               activation_source: :notification,
    |               auth_context: evidence.auth_context)   [core]
    |               |
    |               v (auth_context is plain map() — no Sigra dep)
    |         {:allow, Decision.t()} | {:deny, Denial.t()}
    |       |
    |       v
    |   {:allow, Decision.t()} or {:deny, Denial.t()}   [to host]
    |
    +-- Rejection paths: deny_no_route/3, deny/2
            |
            v
      Denial.new(reason: :notification_open_denied, code: chimeway_code, ...)
      [Denial is a core type; accessible because crosswake_chimeway depends on crosswake]

[Telemetry registry (core)]
    Application.get_env(:crosswake, :companions, [])
    |-- Chimeway.telemetry_events/0  (optional callback)
    |-- Chimeway.forbidden_metadata_keys/0  (optional callback)
    v
  Aggregated into Crosswake.Telemetry catalog

[Clean-room CI lane]
    crosswake + crosswake_chimeway  (NO crosswake_sigra)
    |
    v
  smoke test: Chimeway.validate_dependency() == :ok
              Chimeway.companion_id() == :chimeway
              Chimeway.enabled?(%{}) == true  ← NOTE: chimeway defaults to true
              Chimeway.forbidden_metadata_keys() != []  ← non-vacuous canary
  doctor:   mix crosswake.doctor --router CleanRoomHost.Router  → exit 0
```

### Recommended Package Structure

```
packages/crosswake_chimeway/
├── lib/
│   └── crosswake/
│       └── companions/
│           ├── chimeway.ex                # facade + @behaviour Crosswake.Companion
│           └── chimeway/
│               ├── contracts.ex           # TokenEvidence, TokenBinding, NotificationOpenEvidence, etc.
│               ├── denial_codes.ex        # DenialCodes.sanitize_details/1 lives here (PII source-scrub)
│               ├── intent_consumer.ex     # @callback consume_intent/1 behaviour
│               ├── redaction.ex           # raw-token boundary helpers
│               ├── resolver.ex            # Resolver.resolve/3; uses Crosswake.Shell.Denial (core dep)
│               └── telemetry.ex           # 10 event names + forbidden metadata keys
├── test/
│   ├── crosswake/
│   │   ├── companions/
│   │   │   └── chimeway/
│   │   │       ├── contracts_test.exs      (MOVED from core)
│   │   │       ├── denial_codes_test.exs   (MOVED from core)
│   │   │       ├── redaction_test.exs      (MOVED from core)
│   │   │       ├── resolver_test.exs       (MOVED from core)
│   │   │       └── telemetry_test.exs      (MOVED from core)
│   │   ├── companions/
│   │   │   └── chimeway_test.exs           (MOVED from core)
│   │   └── proof/
│   │       ├── phase59_chimeway_contract_test.exs   (SPLIT from core — 4 tests)
│   │       ├── phase71_notification_workflow_proof_test.exs  (MOVED from sigra package)
│   │       └── phase138_chimeway_cleanroom_test.exs  (NEW — non-vacuous clean-room proof)
│   ├── support/
│   │   └── study_session_live.ex  (copied from crosswake_sigra/test/support/ or crosswake_rindle)
│   └── test_helper.exs
├── mix.exs                        # @version "0.1.0" # x-release-please-version
├── mix.lock
├── config/
│   └── config.exs                 # minimal
├── README.md
├── LICENSE
└── CHANGELOG.md
```

### Pattern 1: mix.exs for crosswake_chimeway (clone sigra mix.exs exactly)

```elixir
# Source: packages/crosswake_sigra/mix.exs (verified live code read)
defmodule CrosswakeChimeway.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_chimeway,
      version: @version,
      name: "crosswake_chimeway",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # NOTE: No ENGINE_PRESENT_LANE branch — chimeway has no optional engine library.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [crosswake_dep()]
    # NOTE: No optional engine dep — chimeway has no third-party engine library.
  end

  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp description, do: "Chimeway notification companion adapter for the Crosswake route-policy system."

  defp package do
    [
      name: "crosswake_chimeway",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_chimeway",
        "GitHub" => @source_url
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

[VERIFIED: pattern confirmed against live sigra/rindle/rulestead mix.exs files]

### Pattern 2: release-please-config.json chimeway block (clone sigra block)

```json
"packages/crosswake_chimeway": {
  "component": "crosswake_chimeway",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "_TODO_release_as": "ONE-SHOT override (Phase 138 / recipe Step 12f / Pitfall 6): remove 'release-as' after the first crosswake_chimeway Release PR merges. chimeway is independently versioned — NOT in the linked-versions lockstep group (D-8).",
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_chimeway/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",          "hidden": true },
    { "type": "docs",     "section": "Documentation",          "hidden": true },
    { "type": "test",     "section": "Tests",                  "hidden": true },
    { "type": "ci",       "section": "Continuous Integration", "hidden": true },
    { "type": "refactor", "section": "Refactoring",            "hidden": true },
    { "type": "build",    "section": "Build System",           "hidden": true }
  ]
}
```

[VERIFIED: pattern matches live sigra block in release-please-config.json]

### Pattern 3: .release-please-manifest.json addition

Add to the existing JSON object (currently 6 keys: `.`, ios, android, rulestead, rindle, sigra):
```json
"packages/crosswake_chimeway": "0.1.0"
```
[VERIFIED: live manifest read — "packages/crosswake_sigra": "0.1.0" is the model]

### Pattern 4: release-please.yml additions (~100 lines)

**Sub-block 1: outputs additions (add after sigra outputs, ~L61)**
```yaml
# Companion: crosswake_chimeway (Phase 138 — independently versioned, NOT in lockstep)
chimeway_release_created: ${{ steps.release.outputs['packages/crosswake_chimeway--release_created'] }}
chimeway_tag_name: ${{ steps.release.outputs['packages/crosswake_chimeway--tag_name'] }}
chimeway_version: ${{ steps.release.outputs['packages/crosswake_chimeway--version'] }}
```

**Sub-block 2: publish-hex-chimeway job (mirror publish-hex-sigra verbatim with s/sigra/chimeway/g)**

**Sub-block 3: clean-room-proof-chimeway job (mirror clean-room-proof-sigra verbatim with s/sigra/chimeway/g)**
```yaml
- name: Run clean-room proof (D-16 — logic lives in script; YAML stays thin)
  run: >
    bash script/verify_companion_cleanroom.sh
    crosswake_chimeway
    "${{ needs.release-please.outputs.chimeway_version }}"
```

**Sub-block 4: release-as-cleanup and release-failure-alert condition updates**
- Add `chimeway_release_created` to `release-as-cleanup` if: condition
- Add chimeway strip block inside the if chain
- Add `publish-hex-chimeway` and `clean-room-proof-chimeway` to `release-failure-alert` needs:

[VERIFIED: pattern matches live sigra additions in release-please.yml at L56-61, L335-430, L892-924, L926-965, L976-990]

### Pattern 5: Clean-room smoke test modification for chimeway

**Critical difference from sigra:** `verify_companion_cleanroom.sh` no-engine smoke test asserts:
```
test "enabled?/1 respects config — false when no :enabled key" do
  refute ${COMPANION_MODULE_SUFFIX}.enabled?(%{})  # ← WILL FAIL for chimeway
end
```

But chimeway's `enabled?/1` defaults to `true` when no `:enabled` key. The script needs a chimeway-specific variant. **Options:**
1. (Preferred) Update `verify_companion_cleanroom.sh` to detect when `PACKAGE=crosswake_chimeway` and emit a chimeway-specific smoke assertion: `assert Chimeway.enabled?(%{})`.
2. Add a `ENABLED_DEFAULT` parameter to the script.

The chimeway clean-room smoke test should assert:
```elixir
test "validate_dependency/0 returns :ok (no engine dep — pure-Elixir notification machinery)" do
  assert Chimeway.validate_dependency() == :ok
end

test "companion_id/0 returns :chimeway" do
  assert Chimeway.companion_id() == :chimeway
end

test "enabled?/1 defaults to true (chimeway enabled by default)" do
  assert Chimeway.enabled?(%{})   # ← chimeway defaults to true, unlike sigra
end

test "enabled?/1 respects config — false when enabled: false" do
  refute Chimeway.enabled?(%{enabled: false})
end

# Non-vacuous canary: proves Telemetry sub-module shipped in the tarball
test "Chimeway.Telemetry.event_names/0 returns 10 notification events (canary: Telemetry shipped)" do
  events = Crosswake.Companions.Chimeway.Telemetry.event_names()
  assert is_list(events) and length(events) == 10,
         "Chimeway.Telemetry.event_names/0 should return 10 events — Telemetry module may be missing from tarball"
end
```

[VERIFIED: chimeway.ex:15-17 shows enabled? defaults to true; telemetry.ex:10-21 shows exactly 10 event names]

### Pattern 6: Non-vacuous chimeway clean-room ExUnit proof

Unlike sigra (which needs `Application.put_env` + RouteGate assertion to prove real evaluation), chimeway's clean-room non-vacuity is simpler: chimeway is NOT an auth companion, so its primary public seam is `Resolver.resolve/3` and `Telemetry.event_names/0`. The proof must:
1. Register chimeway as a companion (`Application.put_env`)
2. Assert chimeway's `telemetry_events/0` callback contributes events to `Crosswake.Telemetry.events/0` (proves the registry callback is live)
3. Assert `forbidden_metadata_keys/0` returns chimeway's 19-key set (proves the forbidden-key aggregation is live)
4. Verify chimeway is NOT an auth authority (`function_exported?(Chimeway, :auth_authority?, 0) == false`)

```elixir
# packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs
defmodule Crosswake.Proof.Phase138ChimewayCleanroomTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Chimeway
  alias Crosswake.Companions.Chimeway.Telemetry, as: ChimewayTelemetry

  setup do
    # REQUIRED: chimeway cannot self-register; test must register it explicitly.
    original = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Chimeway])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
    :ok
  end

  test "clean-room non-vacuity: chimeway registered → telemetry_events/0 contributes to core catalog" do
    # With chimeway registered, Crosswake.Telemetry.events/0 must include chimeway events
    all_events = Crosswake.Telemetry.events()
    chimeway_event_names = ChimewayTelemetry.event_names()

    # At least one chimeway event must appear in the aggregated catalog
    chimeway_events_in_catalog =
      Enum.filter(all_events, fn event ->
        event.event in chimeway_event_names
      end)

    assert chimeway_events_in_catalog != [],
           "chimeway events must appear in Crosswake.Telemetry.events/0 when registered"
  end

  test "clean-room non-vacuity: chimeway registered → forbidden_metadata_keys aggregated" do
    aggregated = Crosswake.Telemetry.forbidden_metadata_keys()
    chimeway_keys = ChimewayTelemetry.forbidden_metadata_keys()

    for key <- chimeway_keys do
      assert key in aggregated,
             "chimeway forbidden key :#{key} must be in aggregated forbidden_metadata_keys"
    end
  end

  test "chimeway is NOT an auth authority (CHIME-02: no sigra dep)" do
    # Chimeway must not implement auth_authority?/0 — that callback belongs to sigra
    refute function_exported?(Chimeway, :auth_authority?, 0),
           "Chimeway must not export auth_authority?/0 — it is a notification companion, not auth"
  end

  test "clean-room: crosswake_sigra is NOT in deps (vacuity guard)" do
    # The crosswake_chimeway package must list only crosswake as a Crosswake dep
    deps = Mix.Project.config()[:deps]
    dep_names = Enum.map(deps, fn
      {name, _} -> name
      {name, _, _} -> name
    end)
    refute :crosswake_sigra in dep_names,
           "crosswake_chimeway must NOT depend on crosswake_sigra (CHIME-02)"
  end
end
```

[ASSUMED — exact API surface of `Crosswake.Telemetry.forbidden_metadata_keys/0`; planner should verify this function exists as a public API]

### Anti-Patterns to Avoid

- **Moving all tests wholesale without splitting (D-20 test split violation):** `phase59_chimeway_contract_test.exs`'s `SupportMatrix.notification_support_truth/0` assertion MUST stay in core (SupportMatrix is core-internal). Moving it breaks the notification support truth proof.
- **Leaving phase71 in sigra package after chimeway extraction:** phase71's primary subject is `Chimeway.Resolver`. It must move to the chimeway package.
- **Using `application: [env: [...]]` self-registration in the package:** packages CANNOT self-register into core's Application env. The clean-room proof MUST use `Application.put_env` in test setup.
- **Gating clean-room on `releases_created` (aggregate):** must gate on `chimeway_release_created` (per-component).
- **Forgetting `CROSSWAKE_RELEASE=1`** on all mix steps in `publish-hex-chimeway`.
- **Not adding chimeway to the `companion_compatibility.md` matrix in Phase 138:** FAMILY-01 is Phase 140, but the chimeway row should be added here (or at minimum planned). The compat matrix drift test (`phase132_compat_matrix_drift_test.exs`) will fail if chimeway is published but the matrix lacks its row.
- **Assuming `enabled?(%{})` is `false` for chimeway in the clean-room smoke test:** chimeway defaults to `true`, unlike the script's existing no-engine assertion. The script MUST be patched.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `release-as` cleanup after first publish | Manual edit + PR | `script/strip_release_as.py` (auto, PROOF-03) | Already parametric; add chimeway to `release-as-cleanup` job `if:` condition only |
| Clean-room verification | Custom CI steps | `script/verify_companion_cleanroom.sh` (parametric, no-engine mode) | Already handles poll + throwaway host + doctor; chimeway invocation: `bash script/verify_companion_cleanroom.sh crosswake_chimeway 0.1.0` |
| Required-check registration | `gh api` one-liners | `script/register_required_checks.sh` | Green-first preflight built in |
| StubChimewayAbsentCompanion | Novel implementation | Mirror `StubSigraAbsentCompanion` in `test/support/stub_companion.ex` | Chimeway is not an auth companion so no `auth_authority?/0` needed; `validate_dependency` returns `{:error, [Crosswake.Companions.Chimeway]}` |
| Compat-matrix chimeway row | Manual HTML | Mirror the sigra row, with "none" for Engine Dependency | Chimeway has no engine dep |

## Runtime State Inventory

> Chimeway extraction is a source-move + CI-registration operation, not a rename/rebrand.
> Runtime state inventory for rename triggers does not apply. Verified: no chimeway-specific
> stored data, service config, OS-registered state, secrets, or build artifacts need migration.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — chimeway token binding state lives in host Ecto schemas (not in crosswake package) | None |
| Live service config | None — chimeway is registered via core Application env; after extraction, host switches config from in-tree to package | None (host config update is adopter-side) |
| OS-registered state | None | None |
| Secrets/env vars | `HEX_API_KEY` CI secret (already present for sigra) | None — same key reused |
| Build artifacts | `lib/crosswake/companions/chimeway.ex` + `lib/crosswake/companions/chimeway/` in-tree files removed from core | Removing from core, adding to package |

## Common Pitfalls

### Pitfall 1: Clean-room smoke test `enabled?(%{})` assertion mismatch
**What goes wrong:** `verify_companion_cleanroom.sh`'s no-engine smoke test asserts `refute Chimeway.enabled?(%{})` — but chimeway's `enabled?/1` returns `true` when no `:enabled` key is present. The clean-room CI job will FAIL on this test.
**Why it happens:** The script's no-engine mode was written for sigra (which also defaults to `true`... so this may have already been addressed). Verify whether `verify_companion_cleanroom.sh` has a chimeway-specific case or whether it will actually fail.
**How to avoid:** Patch `verify_companion_cleanroom.sh` to emit `assert Chimeway.enabled?(%{})` when `PACKAGE=crosswake_chimeway`, or refactor to pass an `ENABLED_DEFAULT` sentinel.
**Warning signs:** `clean-room-proof-chimeway` fails with "expected false but got true" on the `enabled?` test.

### Pitfall 2: `release-as` one-shot footgun (same as sigra)
**What goes wrong:** `release-as: "0.1.0"` is required for the first chimeway publish but permanently overrides subsequent releases if not stripped.
**Why it happens:** release-please treats `release-as` as a permanent override.
**How to avoid:** Wire `chimeway_release_created` to the `release-as-cleanup` job's `if:` condition. The `release-as-cleanup` job will auto-strip it.

### Pitfall 3: Vacuous clean-room proof (no-register = no events in catalog)
**What goes wrong:** If the chimeway clean-room ExUnit test doesn't `Application.put_env(:crosswake, :companions, [Chimeway])` in setup, the `forbidden_metadata_keys/0` and `telemetry_events/0` callbacks are never called by core's telemetry aggregation. The test passes vacuously (no assertion fires on an empty list).
**How to avoid:** Always include `Application.put_env` + `on_exit` cleanup in setup, AND assert on non-empty lists. The `forbidden_metadata_keys/0` canary in the clean-room ExUnit proof achieves this.

### Pitfall 4: phase71 test left in sigra package after chimeway extraction
**What goes wrong:** `packages/crosswake_sigra/test/.../phase71_notification_workflow_proof_test.exs` uses `Crosswake.Companions.Chimeway.Resolver` as its primary subject. After chimeway extraction, the sigra package no longer depends on chimeway, so this test fails to compile in the sigra package.
**Why it happens:** Phase 137 moved phase71 to the sigra package because it registered Sigra. But Chimeway.Resolver is the primary test subject.
**How to avoid:** Move phase71 to `packages/crosswake_chimeway/test/crosswake/proof/`. The test must add `crosswake_sigra` as a path dep in chimeway's test dependencies (or replace `Sigra.Contracts` aliases with plain map fixtures to avoid the dep), OR register a struct shim.

### Pitfall 5: StubChimewayAbsentCompanion needs no `auth_authority?/0`
**What goes wrong:** Planner mirrors `StubSigraAbsentCompanion` verbatim and adds `auth_authority?: false`. Chimeway is NOT an auth companion — `auth_authority?/0` is not in the Companion behaviour for notification companions.
**How to avoid:** `StubChimewayAbsentCompanion` should NOT implement `auth_authority?/0`. The companion_guard comment at `chimeway.ex:55` confirms: "Chimeway is NOT an auth authority — auth_authority?/0 is intentionally absent." [VERIFIED: live code read]

### Pitfall 6: `companion_compatibility.md` not updated in Phase 138
**What goes wrong:** After chimeway publishes, the `phase132_compat_matrix_drift_test.exs` fails because it checks that all published packages have matrix rows. Actually the drift test checks FROM the matrix TO the package, not the reverse — but the matrix is incomplete.
**How to avoid:** Add the chimeway row to `guides/companion_compatibility.md` as part of Phase 138's CI wiring plan. No engine dep for chimeway — use "none" or remove the engine column entry.

## Code Examples

### StubChimewayAbsentCompanion pattern

```elixir
# Add to test/support/stub_companion.ex (after StubSigraAbsentCompanion)
defmodule Crosswake.TestSupport.StubChimewayAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Chimeway with the package absent from core deps.

  Used in core tests that prove the runtime notifications support_truth outcome
  after Phase 138 extracts Crosswake.Companions.Chimeway to the standalone
  packages/crosswake_chimeway/ package.

  companion_id/0 returns :chimeway so Doctor findings carry "companion.chimeway".
  validate_dependency/0 returns {:error, [Crosswake.Companions.Chimeway]} to model
  chimeway absent from core deps (post-extraction state).

  Chimeway is NOT an auth companion — auth_authority?/0 is intentionally ABSENT.
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :chimeway

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [Crosswake.Companions.Chimeway]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :chimeway, %{})
    %Crosswake.Companion.State{
      companion_id: :chimeway,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [Crosswake.Companions.Chimeway]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end

  # NOTE: forbidden_metadata_keys/0 and telemetry_events/0 are intentionally ABSENT
  # from this stub — when chimeway is absent, core's telemetry aggregation gets zero
  # contribution from chimeway. This is the expected behavior.
  #
  # NOTE: auth_authority?/0 is intentionally ABSENT — chimeway is NOT an auth companion.
end
```

### Chimeway row in companion_compatibility.md

```markdown
| `crosswake_chimeway` | `:chimeway` | `0.1.0` | `~> 0.1` | none (pure-Elixir notification machinery) | [hexdocs.pm/crosswake_chimeway](https://hexdocs.pm/crosswake_chimeway) |
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Chimeway `telemetry.ex` events aggregated via static `@notification_support_truth` module attribute | Runtime aggregation via `forbidden_metadata_keys/0` + `telemetry_events/0` optional callbacks | Phase 136 (DECOUPLE-01/03) | Core no longer compile-depends on chimeway |
| Chimeway compiled into core, self-registered via `mix.exs` application/0 env | Standalone `crosswake_chimeway` Hex package, host-registered | Phase 138 | Non-breaking (module names preserved) |
| `Crosswake.Companions.Chimeway` banned in companion_guard but still in core | `Crosswake.Companions.Chimeway` moved out of core `lib/` | Phase 138 | Guard enforcement becomes structural (no in-tree files to exempt) |

**No deprecated patterns introduced:** Chimeway extraction does not require a Finding-boundary refactor (that was sigra-specific). `Resolver.deny_no_route/3` continues to use `Denial.new` since `Denial` is a core type accessible to packages depending on core.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `verify_companion_cleanroom.sh` enabled? assertion will fail for chimeway (defaults to true) | Pitfall 1 | If sigra also defaults to true and the script passed, this may not be an issue — but the assertion text says `refute enabled?(%{})` which would fail for chimeway. Planner must verify. |
| A2 | `Crosswake.Telemetry.forbidden_metadata_keys/0` exists as a public function callable from chimeway's clean-room proof | Pattern 6 / Code Examples | If this function is not public, the clean-room assertion needs a different approach |
| A3 | phase73 (`phase73_auth_sensitive_admin_workflow_proof_test.exs`) can stay in sigra package even after chimeway extraction | Test Split Verification | If phase73 uses `Chimeway.Resolver` directly, it must move to chimeway package too |
| A4 | phase71's `Sigra.Contracts` aliases can be handled by adding `crosswake_sigra` as a test dep in chimeway OR by replacing with plain map fixtures | Pitfall 4 | If `crosswake_sigra` path dep in chimeway test suite creates circular issues, plain map fixtures are the fallback |
| A5 | `companion_compatibility.md` drift test scans only existing rows (FROM matrix TO package) not the reverse | Pitfall 6 | If the drift test also asserts that all published packages have rows, Phase 138 must add the chimeway row |

## Open Questions

1. **phase73 disposition — sigra package or chimeway package?**
   - What we know: phase73 (`phase73_auth_sensitive_admin_workflow_proof_test.exs`) is in the sigra package and its name implies auth-sensitive admin workflow. It may exercise both sigra auth evaluation and chimeway notification machinery together.
   - What's unclear: Whether `Chimeway.Resolver` or chimeway internals are directly exercised in phase73.
   - Recommendation: Planner reads phase73's module aliases; if `Crosswake.Companions.Chimeway.*` is aliased, move to chimeway package. If it tests only sigra + RouteGate, leave in sigra package.

2. **`verify_companion_cleanroom.sh` `enabled?(%{})` assertion behavior**
   - What we know: sigra also defaults to `true` via `Map.get(config, :enabled, Map.get(config, "enabled", true))`. Yet the no-engine smoke test asserts `refute Chimeway.enabled?(%{})`.
   - What's unclear: Did this assertion PASS for sigra because sigra's `enabled?(%{})` is also `true`? If so, the assertion was wrong/vacuous for sigra too, and the script needs patching for chimeway regardless.
   - Recommendation: Planner patches the script unconditionally: emit `assert Chimeway.enabled?(%{})` for chimeway (defaults true) to match actual contract.

3. **Phase71's Sigra.Contracts dependency in chimeway test suite**
   - What we know: phase71 uses `alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts` for building auth context maps.
   - What's unclear: Whether `SigraContracts.new_auth_context/1` builds a plain map or a sigra-specific struct.
   - Recommendation: If `SigraContracts.new_auth_context/1` returns a plain map (`%{mfa_level: ..., ...}`), replace the alias with plain map literals in the chimeway package's copy of phase71, eliminating the sigra dep. If it returns a sigra-specific struct, add `crosswake_sigra` as a test-only path dep in chimeway's mix.exs.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All build steps | ✓ | 1.19+ (per .tool-versions) | — |
| Hex CLI | `hex.publish` | ✓ | In CI via erlef/setup-beam | — |
| `HEX_API_KEY` secret | `hex.publish` | Expected ✓ | CI secret (used by rulestead/rindle/sigra) | — |
| `RELEASE_PLEASE_TOKEN` secret | Release PR + cleanup PR CI trigger | Expected ✓ | CI secret (existing) | `github.token` (but won't chain-trigger CI on cleanup PR) |
| `script/register_required_checks.sh` | Task #1 (human admin action) | ✓ | In repo | — |
| `packages/crosswake_sigra/` | Phase71 test dep (if Sigra.Contracts used) | ✓ | Path dep (local) | Replace with plain map fixtures |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** `RELEASE_PLEASE_TOKEN` → can use `github.token` but cleanup PRs won't trigger CI automatically.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `packages/crosswake_chimeway/test/test_helper.exs` (create in Wave 0) |
| Quick run command | `cd packages/crosswake_chimeway && mix test` |
| Full suite command | `mix test --include integration` (from repo root via `mix companions.test` alias) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHIME-01 | All sub-modules compile in package context | compile | `cd packages/crosswake_chimeway && mix compile --warnings-as-errors` | ❌ Wave 0 — package does not exist yet |
| CHIME-01 | Moved tests pass in package lane | unit | `cd packages/crosswake_chimeway && mix test` | ❌ Wave 0 |
| CHIME-01 | No Crosswake.Companions.Chimeway refs remain in core lib/ | structural | `grep -r "Crosswake.Companions.Chimeway" lib/ && echo FAIL \|\| echo CLEAN` | Runs inline |
| CHIME-02 | No Sigra.* reference inside packages/crosswake_chimeway/ | structural | `grep -r "Crosswake.Companions.Sigra\|crosswake_sigra" packages/crosswake_chimeway/lib/` | Runs inline |
| CHIME-02 | auth_context: map() moduledoc note present in contracts.ex | structural | `grep "auth_context.*map()\|do not tighten" packages/crosswake_chimeway/lib/crosswake/companions/chimeway/contracts.ex` | ❌ Wave 0 (note to add) |
| CHIME-02 | crosswake_chimeway mix.exs does NOT list crosswake_sigra as dep | structural | `grep "crosswake_sigra" packages/crosswake_chimeway/mix.exs && echo FAIL \|\| echo CLEAN` | Runs inline |
| CHIME-02 | Clean-room: chimeway registered → telemetry events contributed | integration | `cd packages/crosswake_chimeway && mix test test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` | ❌ Wave 0 |
| CHIME-02 | Clean-room: chimeway has NO auth_authority?/0 callback | integration | In phase138_chimeway_cleanroom_test.exs | ❌ Wave 0 |
| CHIME-03 | path-dep dress rehearsal passes mix test | integration | `CROSSWAKE_RELEASE=0 cd packages/crosswake_chimeway && mix test` | ❌ Wave 0 |
| CHIME-03 | hex.publish --dry-run succeeds | CI | `CROSSWAKE_RELEASE=1 mix hex.publish --dry-run --yes` | CI-only |
| CHIME-03 | release-please component registered and independent (NOT in linked-versions) | structural | Verify release-please-config.json NOT in linked-versions group | Manual |

### Backstop Tests (Required — must exist before phase gate)

1. **Non-vacuous clean-room ExUnit proof** — `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs`
   - Asserts: `put_env` registers chimeway → `Crosswake.Telemetry.events/0` includes chimeway events → `forbidden_metadata_keys/0` contributes chimeway's 19 keys
   - Vacuity guard: assert list is non-empty; assert chimeway has no `auth_authority?/0`

2. **No-sigra-dep structural guard** — inline grep
   - `grep -r "Crosswake.Companions.Sigra\|crosswake_sigra\|:crosswake_sigra" packages/crosswake_chimeway/lib/ && echo FAIL || echo CLEAN`
   - Run as part of Wave 1 commit gate

3. **auth_context: map() guard** — `resolver_test.exs` (moved to package)
   - The `test "passes through RouteGate denial for auth-predicated route"` test at `resolver_test.exs:L164` asserts `denial.reason == :dependency_missing` — this confirms that chimeway never evaluates auth itself (no sigra dep needed for notification routing).

4. **Support truth stays in core** — `test/crosswake/proof/phase59_chimeway_support_truth_test.exs`
   - The `SupportMatrix.notification_support_truth/0` assertion must remain in core and pass after chimeway is extracted.

### Sampling Rate

- **Per task commit:** `cd packages/crosswake_chimeway && mix test && mix compile --warnings-as-errors`
- **Per wave merge:** Full core suite + chimeway lane: `mix test --exclude requires_example_host && cd packages/crosswake_chimeway && mix test`
- **Phase gate:** Full suite green + clean-room proof green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `packages/crosswake_chimeway/` directory skeleton (mix.exs, mix.lock, config/config.exs, README.md, CHANGELOG.md, LICENSE)
- [ ] `packages/crosswake_chimeway/test/test_helper.exs` — `ExUnit.start(exclude: [:requires_example_host, :advisory_only])`
- [ ] `packages/crosswake_chimeway/test/support/study_session_live.ex` — copy from crosswake_sigra/test/support/ (needed for phase71 notification workflow proof)
- [ ] `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` — non-vacuous clean-room ExUnit proof
- [ ] Framework install: `cd packages/crosswake_chimeway && mix deps.get` (after mix.exs is written)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No (chimeway is notification-only; auth is sigra's domain) | — |
| V3 Session Management | Partial (chimeway's Resolver delegates to RouteGate for auth-predicated routes) | RouteGate fail-closed; `:dependency_missing` if no auth companion registered |
| V4 Access Control | Yes | `Resolver.resolve/3` checks `notification_open_allowed?/1` before any evaluation |
| V5 Input Validation | Yes | `DenialCodes.sanitize_details/1` allowlist (6 safe keys); `Redaction.fingerprint_token/2` HMAC; `Contracts` validation pipeline |
| V6 Cryptography | Partial | `Redaction.fingerprint_token/2` uses `:crypto.mac(:hmac, :sha256)` — standard OTP, not hand-rolled |

### Known Threat Patterns for chimeway extraction

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw push token leak via telemetry metadata | Information Disclosure | `Telemetry.forbidden_metadata_keys/0` (19 keys: `:token`, `:raw_token`, `:device_token`, etc.) + core baseline denylist |
| Raw token leak via Contracts.to_map/1 serialization | Information Disclosure | `TokenEvidence`, `TokenBinding` etc. never declare raw token fields (struct-level enforcement, Phase 59 proof) |
| Vacuous clean-room proof (no register = no telemetry events from chimeway) | Tampering (test bypass) | `put_env` in setup + explicit non-empty list assertions in phase138 cleanroom test |
| `auth_context` type tightening to `Sigra.AuthContext.t()` by future contributor | Elevation of Privilege (inter-companion dep) | Moduledoc guard note in `NotificationOpenEvidence` (CHIME-02); `companion_guard.ex` bans cross-companion static aliases |
| `release-as: "0.1.0"` re-publishing stale version | Tampering (supply chain) | PROOF-03 auto-cleanup; `release-as-staleness-gate.yml` |
| Empty feedback token selector invalidating all bindings (CR-01 regression) | Denial of Service | `Resolver` flow requires `intent_consumer.consume_intent/1` first; raw feedback concerns are host-owned registry API; chimeway package ships only the contract types |

## Sources

### Primary (HIGH confidence)
- Live code reads: `lib/crosswake/companions/chimeway.ex`, `lib/crosswake/companions/chimeway/{contracts,denial_codes,intent_consumer,redaction,resolver,telemetry}.ex` — all chimeway source files
- Live code grep: no `Sigra.*` references in chimeway source (CHIME-02 linchpin verified)
- `packages/crosswake_sigra/mix.exs` — package structure template
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml` — CI wiring patterns (sigra blocks read verbatim)
- `script/verify_companion_cleanroom.sh` — full script read, no-engine mode confirmed, `enabled?` assertion identified
- `test/support/stub_companion.ex` — `StubSigraAbsentCompanion` template for `StubChimewayAbsentCompanion`
- Test file inventory: `test/crosswake/companions/chimeway_test.exs`, `test/crosswake/companions/chimeway/` (5 files), `test/crosswake/proof/phase59_chimeway_contract_test.exs`, `test/crosswake/proof/phase60_chimeway_registry_test.exs`
- `packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs` — confirmed uses `Chimeway.Resolver` as primary subject
- `lib/crosswake/companion_guard.ex` — `Crosswake.Companions.Chimeway` already in `@extracted_companion_names`
- `mix.exs` — `env: [companions: [Crosswake.Companions.Chimeway]]` with Phase-138 extraction comment

### Secondary (MEDIUM confidence)
- `.planning/research/v17-companion-family-completion.md` — D-1..D-9 design spine
- `.planning/phases/137-crosswake-sigra-extraction/137-RESEARCH.md` — sigra precedent, extraction recipe, CI wiring patterns
- `.planning/phases/137-crosswake-sigra-extraction/137-CONTEXT.md` — locked decisions D-137-A..D

### Tertiary (LOW confidence)
- A1-A5 in Assumptions Log — inferred from pattern/precedent, not directly verified in this session

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; patterns directly read from live sigra package and CI files
- No-sigra-dep verification: HIGH — confirmed by live grep across all chimeway source files
- Architecture: HIGH — all source files read; test files enumerated; CI patterns verified
- Clean-room script enabled? issue: HIGH — `chimeway.ex:16-17` confirms default `true`; script line 271 shows `refute enabled?(%{})` which would fail
- Pitfalls: HIGH — smoke test issue VERIFIED against live code; phase71 move confirmed by live read
- CI wiring: HIGH — exact patterns read from live release-please.yml sigra blocks

**Research date:** 2026-07-02
**Valid until:** 2026-08-01 (stable Elixir ecosystem; code drift is the main risk after Phase 137 wave 5 publishes)
