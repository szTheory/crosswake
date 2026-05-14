# Phase 2: Manifest Truth And Compatibility - Research

**Researched:** 2026-05-14
**Domain:** Phoenix-side manifest compilation, layered compatibility validation, doctor diagnostics, and support-matrix generation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Runtime manifest contract shape
- **D-01:** Crosswake should emit one canonical runtime manifest as a single versioned JSON artifact, not a family of loosely coupled manifest files.
- **D-02:** The manifest should be route-entry-first, keyed by Crosswake route `id`, not path-rule-first like Hotwire Native path configuration.
- **D-03:** The manifest should mirror the Phase 1 normalized route surface closely: `id`, route path/pattern, `runtime`, `offline`, `capabilities`, `packs`, `sync`, and `security`, with only minimal additional shell-facing metadata.
- **D-04:** The manifest should have explicit top-level sections for `manifest_schema_version`, `crosswake_version`, generation metadata, host truth, compatibility truth, support-matrix truth, capability registry truth, and compiled routes.
- **D-05:** Capability names and versions should live in a global manifest registry plus per-route allowlists, not only inline inside route entries.
- **D-06:** Support-matrix truth should be machine-readable from the same manifest contract so doctor tooling, docs, and proof lanes derive from one source of truth.
- **D-07:** Remote manifest updates may exist later, but only as versioned manifest replacement or companion data. Crosswake should not depend on unversioned overlays or rule-order semantics that silently change route meaning.

### Compatibility and activation policy
- **D-08:** Crosswake should use layered compatibility, not exact global lockstep and not best-effort degradation.
- **D-09:** Compatibility should be modeled as separate contract axes: `manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, and capability versions; later phases can add pack and sync schema versions without collapsing them into one boolean.
- **D-10:** Native runtime compatibility must be treated separately from manifest schema compatibility. A shell can be structurally able to read a manifest but still be unable to activate specific routes safely.
- **D-11:** Crosswake should support bundled, cached, and remote manifests, with the bundled manifest as guaranteed boot truth and the remote manifest allowed to refine behavior only within the boundaries of the shipped native runtime.
- **D-12:** Route activation must fail closed when required runtime, bridge, origin, capability, or compatibility conditions are not met. Crosswake should not silently fall back to a generic WebView container for incompatible native or offline routes.
- **D-13:** Route-level compatibility gating is required. App boot compatibility alone is not enough because Crosswake’s core thesis is explicit runtime ownership per route.
- **D-14:** OTA-safe manifest or config updates must never imply new native behavior absent from the shipped binary. Remote manifest updates may select among existing runtime/capability options only.
- **D-15:** The first public support matrix should stay narrow and proof-oriented: one active Phoenix line, one active LiveView line, one iOS floor, one Android floor, plus exact shell/runtime artifact versions used in proof lanes.
- **D-16:** Public support posture should distinguish `supported`, `expected but unproven`, and `unsupported` instead of implying broad semver optimism.

### Doctor tooling and diagnostics posture
- **D-17:** Phase 2 should ship one primary public task, `mix crosswake.doctor`, focused on host and manifest truth first, not a broad native-environment preflight.
- **D-18:** Blocking doctor checks should cover installer state, router markers, policy module presence, policy compilation, manifest generation, manifest schema/compatibility validation, and support-matrix consistency.
- **D-19:** Native environment or toolchain checks may exist only as clearly labeled advisory checks behind an explicit flag or sibling task until native shell proof lanes exist.
- **D-20:** Doctor output should default to human-readable terminal output and support a stable structured mode such as `--format json` for CI, docs-contract checks, and future tooling.
- **D-21:** Doctor findings should be separated into `error`, `warning`, and `advisory`, with exit codes driven only by blocking contract failures.
- **D-22:** Doctor should reuse structured compiler diagnostics and machine-readable install-manifest data directly. It should not scrape rendered strings back into structure.
- **D-23:** Compatibility failures should be explained in operator language: route requires newer shell runtime, capability version missing, manifest built for newer bridge major, origin mismatch, or unsupported baseline.

### Documentation and public contract posture
- **D-24:** Phase 2 docs should make runtime ownership, compatibility boundaries, supported baselines, non-goals, and rough edges explicit enough that adopters can self-screen before implementation.
- **D-25:** Crosswake should market Phase 2 as manifest truth and compatibility truth, not as solved shell runtime support. Native shell generation exists, but shell boot/runtime credibility remains Phase 3 work.
- **D-26:** Support matrix and rough-edge docs are product surface, not cleanup work. They should be generated or mechanically checked where practical so written claims do not drift from implementation truth.

### Decision delegation posture
- **D-27:** Shift choices left within GSD by default. Downstream researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes one of these: public product contract, support claims, compatibility policy, route taxonomy, security posture, or long-term upgrade surface.
- **D-28:** For internal implementation details such as module splits, helper naming, serializer organization, report formatting details, and exact code structure, the agent should choose least-surprise Phoenix/Elixir patterns without escalating.

### Claude's Discretion
- Exact manifest field names can be refined during planning as long as the layered contract shape above remains intact.
- Exact support baseline numbers can move with the current stable ecosystem at planning time, but the narrow-matrix posture stays fixed.
- The precise doctor report layout, grouping, and color treatment are agent discretion if the severity model and automation contract stay stable.
- Internal compiler, validator, and serializer module boundaries are agent discretion if they preserve the route-first manifest contract and machine-readable diagnostics.

### Deferred Ideas (OUT OF SCOPE)
- Native shell boot verification, real WebView/WKWebView runtime behavior, and deep-link handoff proof remain Phase 3.
- Typed request/reply bridge execution and capability dispatch remain Phase 3, even though Phase 2 sets the versioning and compatibility posture they must obey.
- Offline island journals, local-first mutation contracts, and reconciliation semantics remain Phase 4.
- Pack lifecycle, native-screen escape hatches, media transfer seams, and full proof lanes remain Phase 5.
- Broad native environment inspection, signing checks, simulator/emulator orchestration, and release/distribution workflows are deferred until the project has proven shell/runtime behavior to validate against.
- Wide compatibility promises across multiple Phoenix/LiveView lines are deferred until proof lanes justify them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MANI-01 | Crosswake compiles declared route policy into a versioned runtime manifest consumable by Phoenix hosts and native shells. | Route-first manifest builder, serializer boundary, route fixture reuse, and canonical top-level contract sections. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| MANI-02 | Crosswake validates manifest schema, compatibility versions, and support matrix rules before release artifacts are produced. | Layered compatibility validator, support-matrix generator/checker, `Version.match?/3` guidance, and doctor blocking checks. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| MANI-04 | Crosswake publishes an explicit support and compatibility matrix covering supported Phoenix, LiveView, iOS, and Android baselines. | Machine-readable support matrix derived from the same manifest/support data plus generated docs and consistency tests. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| DX-02 | Crosswake provides doctor or diagnostics tooling that detects setup, compatibility, capability, and route-policy problems. | `mix crosswake.doctor` should reuse install manifest data, policy compiler diagnostics, manifest validation, and support-matrix validation with human and JSON output. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/crosswake/install/manifest.ex] [VERIFIED: lib/crosswake/policy/diagnostic.ex] |
| DX-04 | Crosswake documentation clearly states supported runtime modes, non-goals, prerequisites, and rough-edge truth for adopters. | Proof-oriented docs posture, generated support matrix, and install-guide extensions that preserve the current ownership-boundary honesty. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: guides/install.md] [VERIFIED: .planning/PROJECT.md] |
</phase_requirements>

## Summary

Phase 2 should stay entirely on the Phoenix/host side: compile the Phase 1 route structs into one canonical JSON manifest, validate layered compatibility and support claims before artifact production, and expose that truth through one primary Mix task, `mix crosswake.doctor`. That matches the locked phase boundary, which explicitly excludes native shell boot proof, bridge execution, and offline runtime behavior. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

The existing code already provides the right substrate for this work. `Crosswake.Policy.Compiler` returns normalized `Route` structs plus machine-readable diagnostics, the install task already persists host-truth state in JSON, and current tests already exercise router introspection, compile errors, and task output. Phase 2 should extend those seams instead of introducing a second registry, a second validator stack, or string-scraping doctor logic. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/policy/route.ex] [VERIFIED: lib/crosswake/policy/diagnostic.ex] [VERIFIED: lib/crosswake/install/manifest.ex] [VERIFIED: test/crosswake/router_test.exs] [VERIFIED: test/mix/tasks/crosswake_install_test.exs]

The highest-value planning decisions are therefore internal structure and verification posture: build a typed manifest struct before encoding JSON, validate each compatibility axis independently with Elixir’s `Version` module, derive the support matrix from the same manifest/support data that doctor consumes, and keep docs/mechanical checks in scope as product surface. That approach satisfies the phase requirements without reopening any public product decisions. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] [VERIFIED: .planning/PROJECT.md]

**Primary recommendation:** Add a narrow `Crosswake.Manifest` pipeline with typed intermediate structs, `Jason` serialization, layered compatibility validators, generated support-matrix artifacts, and a `mix crosswake.doctor` task that reuses compiler/install data directly. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/install/manifest.ex] [CITED: https://hexdocs.pm/jason/Jason.html]

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` file exists at the repo root, so there are no additional project-specific directives beyond `AGENTS.md` and the planning artifacts. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route-policy to manifest compilation | API / Backend | — | The compiler already runs in Elixir against Phoenix router metadata and normalized route structs. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: test/crosswake/router_test.exs] |
| Manifest schema validation | API / Backend | — | Schema and semantic validation belong with the host-owned compiler so native shells only consume already-vetted contract truth. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| Compatibility-axis evaluation | API / Backend | Frontend Server (SSR) | Phase 2 validates manifest, bridge, runtime, and capability version requirements before shipping artifacts; later runtime enforcement in shells depends on this host truth. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| Doctor diagnostics | API / Backend | — | `mix crosswake.doctor` is a host-side task that should inspect install state, router truth, manifest output, and support claims. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] [VERIFIED: lib/mix/tasks/crosswake.install.ex] |
| Support-matrix generation/checking | API / Backend | CDN / Static | The canonical data should be generated in Elixir and then rendered into docs/static artifacts without creating a second hand-edited truth source. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| Adopter-facing compatibility docs | CDN / Static | API / Backend | Published docs are static output, but they should derive mechanically from host-generated support data. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir stdlib `Version` | `1.19.x` | Parse and match compatibility requirements for manifest/schema/runtime/capability axes. | `Version.compare/2` and `Version.match?/3` already provide semver-aware comparisons, including prerelease handling via `allow_pre`. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| Phoenix | `1.8.7` | Router introspection and route metadata source of truth. | The repo is already pinned to Phoenix `~> 1.8`, and Phoenix exposes `__routes__/0` plus `route_info/4` metadata that current tests already consume. [VERIFIED: mix.lock] [VERIFIED: deps/phoenix/lib/phoenix/router.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| Phoenix LiveView | `1.1.30` | Existing runtime baseline for route-policy fixtures and support-matrix claims. | The repo is locked to `1.1.30`; `mix hex.info` shows newer `1.2.0-rc.*` prereleases, so Phase 2 should keep the proven stable line unless planning explicitly chooses RC adoption. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] |
| NimbleOptions | `1.1.1` | Continue validating host-authored option/config shapes at compile time. | The repo already uses a compiled NimbleOptions schema for Phase 1 policy validation, and the docs confirm `validate/2` re-validates schemas on each call, which reinforces keeping schemas compiled once in module attributes. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: mix hex.info nimble_options] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| Jason | `1.4.5` stable line | Encode/decode manifest JSON and doctor JSON output. | `mix hex.info` shows `1.4.5` as the newest stable release while `1.5.0-alpha.*` remains prerelease; using Jason removes the need to extend the current hand-rolled JSON encoder beyond installer scaffolding. [VERIFIED: mix hex.info jason] [CITED: https://hexdocs.pm/jason/Jason.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir `1.19.x` | Golden manifest tests, doctor JSON tests, and support-matrix drift tests. | Use for all new Phase 2 verification; current task and compiler tests already establish the repo pattern. [VERIFIED: test/crosswake/policy/compiler_test.exs] [VERIFIED: test/mix/tasks/crosswake_install_test.exs] |
| `Mix.Task` | bundled with Elixir `1.19.x` | `mix crosswake.doctor` entrypoint and machine-readable CLI output. | Use for the public doctor surface because Phase 1 already exposes installer/generator tasks this way. [VERIFIED: lib/mix/tasks/crosswake.install.ex] [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Jason` manifest encoding | Keep extending `Crosswake.Install.Manifest.json/1` | The current helper is acceptable for the installer scaffold JSON, but Phase 2 manifest and doctor output need a general JSON library with decoding and error handling, not a second bespoke encoder. [VERIFIED: lib/crosswake/install/manifest.ex] [CITED: https://hexdocs.pm/jason/Jason.html] |
| Elixir `Version` per-axis checks | Custom semver parsing | Custom semver logic would recreate prerelease and comparison edge cases the stdlib already handles. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| Generated support matrix | Hand-written docs table only | Hand-written support claims drift from compiler and doctor truth, which directly conflicts with the locked docs posture. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Phoenix is locked at `1.8.7` with a 2026-05-06 release date, `phoenix_live_view` is locked at `1.1.30` and `mix hex.info` shows it was released on 2026-05-05, `nimble_options` is locked at `1.1.1` with a 2024-05-25 release date, and `jason` `1.4.5` is the newest stable release dated 2026-05-05 while `1.5.0-alpha.*` remains prerelease. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info nimble_options] [VERIFIED: mix hex.info jason]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix router metadata
  -> Crosswake.Policy.Compiler
  -> normalized %Crosswake.Policy.Route{}
  -> Crosswake.Manifest.Builder
  -> Crosswake.Manifest.Validator
     -> schema checks
     -> compatibility-axis checks
     -> support-matrix checks
  -> Crosswake.Manifest.Serializer
  -> runtime_manifest.json
     -> mix crosswake.doctor
        -> install manifest truth
        -> policy compile diagnostics
        -> manifest validation results
        -> support-matrix/doc consistency checks
     -> generated support matrix JSON/Markdown
     -> Phase 3 shell fixtures and boot contract
```

The critical boundary is that JSON is the final artifact, not the working model. Build and validate typed Elixir structures first, then encode once at the edge. [VERIFIED: lib/crosswake/policy/route.ex] [VERIFIED: lib/crosswake/policy/compiler.ex] [CITED: https://hexdocs.pm/jason/Jason.html]

### Recommended Project Structure
```text
lib/
├── crosswake/
│   ├── manifest/
│   │   ├── manifest.ex          # public compile/write entrypoint
│   │   ├── builder.ex           # route-first manifest assembly
│   │   ├── serializer.ex        # Jason encoding + deterministic formatting
│   │   ├── validator.ex         # structural + semantic manifest checks
│   │   └── types.ex             # manifest/support/compat structs
│   ├── compatibility/
│   │   ├── compatibility.ex     # shared axis evaluation
│   │   └── route_gate.ex        # route-level compatibility explanations
│   ├── doctor/
│   │   ├── doctor.ex            # orchestrates checks
│   │   ├── check.ex             # finding structs and severity handling
│   │   ├── formatter.ex         # terminal renderer
│   │   └── json_formatter.ex    # stable CI output
│   └── support_matrix/
│       ├── support_matrix.ex    # canonical support data
│       └── renderer.ex          # JSON/Markdown output
└── mix/tasks/
    └── crosswake.doctor.ex      # public task

test/
├── crosswake/manifest/
├── crosswake/compatibility/
├── crosswake/doctor/
├── crosswake/support_matrix/
└── support/
    └── router_fixtures.ex       # extend existing route fixtures
```

This split follows the repo’s existing pattern of small, single-purpose modules under `lib/crosswake/...` and focused ExUnit suites per subsystem. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/policy/diagnostic.ex] [VERIFIED: test/crosswake/policy/compiler_test.exs]

### Pattern 1: Manifest Pipeline Stays Downstream Of The Policy Compiler
**What:** `Crosswake.Manifest` should accept `Compiler.compile/2` output, not router metadata or ad hoc config directly. [VERIFIED: lib/crosswake/policy/compiler.ex]

**When to use:** Always for canonical manifest generation and doctor rechecks. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Example:**
```elixir
# Source: project pattern from lib/crosswake/policy/compiler.ex and lib/crosswake/policy/route.ex
with {:ok, %{routes: routes, warnings: warnings}} <- Crosswake.Policy.Compiler.compile(router),
     {:ok, manifest} <- Crosswake.Manifest.Builder.build(routes, host_truth, support_truth),
     :ok <- Crosswake.Manifest.Validator.validate(manifest) do
  {:ok, manifest, warnings}
end
```

### Pattern 2: Validate Compatibility Per Axis, Then Aggregate Findings
**What:** Store requirements and actuals per axis (`manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, capability versions) and emit one finding per failure. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**When to use:** Manifest build validation, doctor checks, and future shell route-gate explanations. [VERIFIED: .planning/ROADMAP.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/Version.html
Version.match?(actual_runtime_version, required_runtime_range, allow_pre: false)
```

Use `allow_pre: false` for support-matrix and release checks so prerelease shells or host libs do not count as satisfying stable support claims. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html]

### Pattern 3: Doctor Consumes Structured Inputs, Never Rendered Strings
**What:** `mix crosswake.doctor` should orchestrate checks over install manifest data, compiler results, manifest validation, and support-matrix/doc outputs, then render findings at the end. [VERIFIED: lib/crosswake/install/manifest.ex] [VERIFIED: lib/crosswake/policy/diagnostic.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**When to use:** All user-facing and CI-facing diagnostics in this phase. [VERIFIED: .planning/ROADMAP.md]

**Example:**
```elixir
# Source: project pattern from lib/crosswake/policy/diagnostic.ex
%Crosswake.Doctor.Check{
  severity: :error,
  code: :manifest_schema_mismatch,
  message: "manifest requires schema 2.x but this host only supports 1.x",
  details: %{required: "~> 2.0", actual: "1.3.0"}
}
```

### Anti-Patterns to Avoid
- **Manifest-from-router duplication:** Do not re-read Phoenix route metadata in multiple places once `Compiler.compile/2` has already normalized it. [VERIFIED: lib/crosswake/policy/compiler.ex]
- **One boolean compatibility flag:** Do not collapse all compatibility into `compatible?: true|false`; the context explicitly locks separate axes and route-level explanations. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]
- **Compile-time environment truth:** Do not push install-manifest existence, support-matrix checks, or release artifact validation back into Phase 1 compile-time checks. [VERIFIED: .planning/phases/01-route-policy-foundation/01-route-policy-foundation-03-SUMMARY.md]
- **Doctor string scraping:** Do not parse `Diagnostic.format/1` output back into structured findings; reuse structs directly. [VERIFIED: lib/crosswake/policy/diagnostic.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Semver matching | Custom range parser | Elixir `Version.match?/3` and `Version.compare/2` | The stdlib already handles range semantics and prerelease rules. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| Manifest JSON encoding | Expanded manual escape/join logic | `Jason.encode!/2` behind a serializer module | The current custom JSON helper is narrow scaffolding code, not a full manifest codec. [VERIFIED: lib/crosswake/install/manifest.ex] [CITED: https://hexdocs.pm/jason/Jason.html] |
| Doctor output protocol | Ad hoc tuples or strings | Explicit finding structs plus human/JSON formatters | Existing diagnostics are already struct-based, and Phase 2 needs stable CI output. [VERIFIED: lib/crosswake/policy/diagnostic.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| Support claims | Manual README-only tables | Generated JSON plus rendered Markdown checked in tests | Locked docs posture requires support truth to be mechanically checked. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |

**Key insight:** Crosswake already has the right pattern: normalize once, keep structure until the presentation boundary, and let tasks/docs consume the same data model. Phase 2 should repeat that pattern for manifests, compatibility, and support claims. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/install/manifest.ex]

## Common Pitfalls

### Pitfall 1: Two Sources Of Route Truth
**What goes wrong:** A planner adds manifest-only route fields or validators that bypass `Crosswake.Policy.Route`, so manifest output drifts from compile-time route truth. [VERIFIED: lib/crosswake/policy/route.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Why it happens:** It is tempting to assemble JSON straight from router metadata because Phoenix exposes `__routes__/0` and `route_info/4`. [VERIFIED: deps/phoenix/lib/phoenix/router.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]

**How to avoid:** Build manifests only from normalized `Route` structs and add any new shell-facing metadata in one manifest builder layer. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/policy/route.ex]

**Warning signs:** Tests start asserting raw route metadata and manifest JSON separately instead of going through one compiler result. [VERIFIED: test/crosswake/router_test.exs]

### Pitfall 2: Prerelease Versions Accidentally Count As Supported
**What goes wrong:** Support-matrix or doctor checks treat prerelease Phoenix/LiveView/shell versions as satisfying stable requirements. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html]

**Why it happens:** `Version.match?/3` can match prereleases unless `allow_pre: false` is applied for relevant checks. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html]

**How to avoid:** Use stable support ranges and call `Version.match?/3` with `allow_pre: false` for release/support evaluation. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html]

**Warning signs:** Doctor passes on `-rc` or `-alpha` values without emitting warnings or downgrading support status. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html]

### Pitfall 3: Support Matrix Becomes Documentation Theater
**What goes wrong:** README claims broader compatibility than the manifest/support data or proof lanes actually cover. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Why it happens:** Docs are edited separately from code and tests. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**How to avoid:** Generate support artifacts from one support-matrix module and test the rendered docs for consistency. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Warning signs:** Baseline versions appear in Markdown but not in manifest/support JSON fixtures, or vice versa. [VERIFIED: codebase grep]

### Pitfall 4: Doctor Surface Quietly Expands Into Native Preflight
**What goes wrong:** Phase 2 doctor starts checking Xcode, Android SDK, signing, or device state and turns Phase 2 into Phase 3/5 work. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Why it happens:** Diagnostics tasks tend to accrete everything that looks useful. [ASSUMED]

**How to avoid:** Keep blocking checks to installer/policy/manifest/support truth and put any native environment checks behind `--advisory-native` or a sibling task later. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

**Warning signs:** A doctor run fails on missing native toolchains even when manifest compilation and host truth are correct. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]

## Code Examples

Verified patterns from official sources and the current codebase:

### Compatibility Match Without Prereleases
```elixir
# Source: https://hexdocs.pm/elixir/1.19.3/Version.html
Version.match?("1.1.30", "~> 1.1.0", allow_pre: false)
```

### Phoenix Route Introspection For Host Truth
```elixir
# Source: project usage in test/crosswake/router_test.exs
info = Phoenix.Router.route_info(MyAppWeb.Router, "GET", "/library", "example.test")
crosswake_policy = info.crosswake_policy
```

Phoenix documents `route_info/4` as returning compile-time route info plus runtime path params, which makes it appropriate for host-side diagnostics and smoke checks. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]

### Compiled Route Source For Manifest Building
```elixir
# Source: lib/crosswake/policy/compiler.ex
{:ok, %{routes: routes, warnings: warnings}} =
  Crosswake.Policy.Compiler.compile(MyAppWeb.Router, warn_on_unmanaged?: true)
```

### JSON Edge Encoding Boundary
```elixir
# Source: https://hexdocs.pm/jason/Jason.html
json = Jason.encode!(manifest_map)
```

## State Of The Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Named route helpers as the primary route-generation story | `Phoenix.VerifiedRoutes` is the preferred Phoenix path/url generation mechanism. | Phoenix documents Verified Routes as the preferred way in current `Phoenix.Router` docs. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] | Crosswake should keep host-truth route references aligned with current Phoenix ergonomics and not introduce legacy helper-based docs examples. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| One release version interpreted optimistically | Explicit prerelease-aware requirement matching with `allow_pre` control. | Current Elixir `Version` docs for `1.19.3`. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] | Doctor and support-matrix checks can stay honest about RC/alpha baselines. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| Manual support prose | Machine-readable support truth derived from the manifest/support data model. | Locked in Phase 2 context decisions. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] | Prevents docs drift and gives Phase 3 shells a canonical baseline contract. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |

**Deprecated/outdated:**
- Manual JSON assembly for the main runtime manifest should be treated as a stopgap installer pattern, not the Phase 2 contract path. [VERIFIED: lib/crosswake/install/manifest.ex] [CITED: https://hexdocs.pm/jason/Jason.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Diagnostics tasks tend to accrete unrelated native preflight work unless their scope is constrained. | Common Pitfalls | Low; the mitigation is still correct because the phase context explicitly constrains doctor scope. |

## Open Questions

1. **Where should the canonical runtime manifest file live in the host tree?**
   - What we know: Phase 1 already writes `priv/crosswake/install_manifest.json`, and the context wants a canonical JSON runtime artifact. [VERIFIED: lib/mix/tasks/crosswake.install.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]
   - What's unclear: Whether Phase 2 should colocate the runtime manifest under `priv/crosswake/` or generate it under a build/release-specific path. [VERIFIED: codebase grep]
   - Recommendation: Plan around `priv/crosswake/runtime_manifest.json` unless release packaging requirements force a different output path later. [ASSUMED]

2. **Should support-matrix Markdown be generated into `guides/` or `.planning/` first?**
   - What we know: Adopter-facing docs are in `guides/`, while planning artifacts already hold roadmap/research state. [VERIFIED: guides/install.md] [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: Whether the published support matrix should be a guide checked into `guides/` or a generated intermediate rendered elsewhere first. [VERIFIED: codebase grep]
   - Recommendation: Generate canonical JSON first and render checked-in Markdown under `guides/` so public docs stay close to adopters while tests can validate the rendered content. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Authentication policy is not introduced in this phase. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Session handling remains outside the Phase 2 manifest/doctor scope. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Route activation must fail closed on incompatible runtime/capability/origin conditions, so manifest compatibility is part of route access control. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| V5 Input Validation | yes | Validate route policy, manifest fields, support-matrix data, and version ranges through typed structs, NimbleOptions, and `Version`. [VERIFIED: lib/crosswake/policy/schema.ex] [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| V6 Cryptography | no | Phase 2 does not yet define manifest signing or cryptographic verification. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for Manifest/Doctor Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Manifest tampering or stale copied artifacts | Tampering | Regenerate from compiler truth, validate schema/compatibility on doctor runs, and keep bundled manifest as the guaranteed boot truth. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| Unsupported route activation due to optimistic version matching | Elevation of privilege | Route-level fail-closed compatibility checks with per-axis version evaluation and operator-readable failure reasons. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] |
| Host docs claiming unsupported baselines | Repudiation | Generate support claims from machine-readable support truth and test rendered docs for drift. [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] |
| JSON decode atom exhaustion in tooling | Denial of service | Do not decode external JSON keys to atoms; Jason documents atom decoding as creating atoms at runtime. [CITED: https://hexdocs.pm/jason/Jason.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md` - locked Phase 2 contract, doctor posture, support-matrix posture, and scope boundaries.
- `.planning/PROJECT.md` - thesis, support honesty, and product-surface constraints.
- `.planning/REQUIREMENTS.md` - requirement IDs and traceability.
- `.planning/ROADMAP.md` - phase goals and success criteria.
- `lib/crosswake/policy/route.ex` - normalized route contract reused by manifest generation.
- `lib/crosswake/policy/compiler.ex` - canonical compile pipeline.
- `lib/crosswake/policy/diagnostic.ex` - machine-readable diagnostic pattern.
- `lib/crosswake/install/manifest.ex` - existing JSON artifact pattern and current manual encoder.
- `lib/mix/tasks/crosswake.install.ex` - install-manifest truth source.
- `test/crosswake/router_test.exs` and `test/support/router_fixtures.ex` - existing router introspection and fixture patterns.
- `https://hexdocs.pm/elixir/1.19.3/Version.html` - version matching and prerelease semantics.
- `https://hexdocs.pm/jason/Jason.html` - JSON encoding/decoding behavior and atom-decoding caution.
- `https://hexdocs.pm/nimble_options/NimbleOptions.html` - option validation behavior.
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` - route introspection and current Phoenix route-generation posture.

### Secondary (MEDIUM confidence)
- `mix hex.info phoenix` - current stable Phoenix release line and release dates.
- `mix hex.info phoenix_live_view` - repo lock plus current prerelease/stable release list.
- `mix hex.info nimble_options` - current NimbleOptions release line.
- `mix hex.info jason` - stable vs prerelease Jason release line.
- `deps/phoenix/lib/phoenix/router.ex` and `deps/phoenix/lib/phoenix/router/route.ex` - local Phoenix source verifying `__routes__/0`, metadata, and route struct fields.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended libraries are either already in the repo or verified in official docs / `mix hex.info`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info nimble_options] [VERIFIED: mix hex.info jason]
- Architecture: HIGH - the recommended flow extends the current compiler/install seams and directly follows locked Phase 2 decisions. [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/install/manifest.ex] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md]
- Pitfalls: MEDIUM-HIGH - prerelease matching and docs drift are directly verified; native-preflight creep is partly based on experience and is logged as an assumption. [CITED: https://hexdocs.pm/elixir/1.19.3/Version.html] [VERIFIED: .planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md] [ASSUMED]

**Environment availability audit:** SKIPPED because this phase is code/config/docs work on existing Elixir tooling and introduces no required external services, databases, or platform CLIs beyond the project’s current `mix` environment. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: mix.exs]

**Research date:** 2026-05-14
**Valid until:** 2026-06-13
