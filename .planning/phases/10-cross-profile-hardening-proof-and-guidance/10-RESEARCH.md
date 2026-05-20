<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Isolated Proof Lanes (Install Truth = Product Truth):** Proof lanes will be isolated, per-profile verification scripts. We will not build a monolithic "kitchen sink" test app. Instead, use hermetic scripts (e.g., `script/verify_saas_profile.sh`, `script/verify_local_first.sh`) that generate a clean Phoenix host, install Crosswake, configure specific route policy, and prove the boundary.
2. **Native Compilation Strategy:** Compile native shells only for a single flagship "example host" to avoid CI combinatorial explosion. Unit test manifest and code generation for all adopter profiles using ExUnit. Configure one merge-blocking CI lane for full `xcodebuild` and `./gradlew` strictly against the flagship host.
3. **The "Honest Boundary" Documentation Hybrid:** No centralized `ROUGH_EDGES.md` graveyard. Use a hybrid approach:
    - **Localized Prose:** Every feature guide gets a "Boundary Warnings & Rough Edges" section.
    - **Generated Matrix:** `Crosswake.SupportMatrix` generates `guides/support_matrix.md` with links directly to localized warnings.
4. **Strict Stabilization Scope (No API Expansion):** Phase 10 is a Contract Locking Phase. Do not expand the Elixir API or bloat the `RoutePolicy` DSL. Instead:
    - Upgrade `mix crosswake.doctor` to catch failure states and warn loudly.
    - Document gaps as explicit boundaries.
    - Ensure proof lanes validate fallback to native escapes.

### the agent's Discretion
None explicitly listed. Discretion is limited to the mechanical execution of the locked Contract Locking Phase strategy.

### Deferred Ideas (OUT OF SCOPE)
- Expanding Elixir API or `RoutePolicy` DSL to cover exemplar gaps.
- Centralized `ROUGH_EDGES.md` graveyard.
- Monolithic "kitchen sink" test app.
- Full native shell compilation for every exemplar profile.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HARD-01 | Phoenix teams can express the exemplar flows without app-local shell forks, undocumented bridge behavior, or generic plugin-bus patterns. | Addressed by upgrading `mix crosswake.doctor` to enforce boundary constraints instead of expanding API scope. |
| HARD-02 | Contributors can run deterministic proof lanes that validate each exemplar's declared support posture across docs, host code, and runtime hooks. | Handled via Pattern 1: Hermetic Bash scripts orchestrating ExUnit tests (e.g., `script/verify_saas_profile.sh`) against the shared host. |
| HARD-03 | Adopters can read guidance and diagnostics that explain which profile pressures are first-class, which are rough edges, and where future capability expansion begins. | Implemented via the Honest Boundary Hybrid documentation strategy (localized warnings mapped from `Crosswake.SupportMatrix`). |
</phase_requirements>

# Phase 10: Cross-Profile Hardening, Proof, and Guidance - Research

**Researched:** 2026-05-19
**Domain:** Crosswake Verification, Documentation, and CI Hardening
**Confidence:** HIGH

## Summary

Phase 10 is the capstone Contract Locking Phase for the v1.0 milestone. Its primary objective is to solidify the boundaries established by the three exemplar profiles (SaaS Portal, Selective Native, Local-First) without expanding the Elixir API or inflating the `RoutePolicy` DSL. Instead of "fixing" gaps uncovered by these exemplars, Phase 10 explicitly documents them as boundaries to guarantee "first hour" adopter honesty. 

To achieve this, the architecture pivots away from monolithic test apps and centralized "rough edges" documents. Proof lanes become hermetic, profile-specific bash scripts that orchestrate Elixir-level (`ExUnit`) generation and validation tests, while restricting the heavy native compilation (`xcodebuild`/`./gradlew`) to a single flagship example host. Finally, the documentation architecture moves to a hybrid model where localized "Boundary Warnings" in feature guides act as the definitive source of truth, linked directly from the canonical `Crosswake.SupportMatrix`.

**Primary recommendation:** Enforce the "No API Expansion" rule strictly. Focus all engineering effort on upgrading `Crosswake.Doctor` diagnostics, writing hermetic `script/verify_*.sh` bash scripts, and refactoring guides to include "Boundary Warnings & Rough Edges."

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Proof Lanes (CI validation) | **CLI / Scripts** | ExUnit | Isolated `script/verify_*.sh` bash scripts orchestrate clean-slate Elixir ExUnit testing without requiring heavy native builds per profile. |
| Native Shell Compilation | **Native Build** | — | Restricted to the single flagship `examples/*_shell_host` to prove iOS/Android structurally sound without CI explosion. |
| Gap Diagnostics | **Elixir Backend** | `mix crosswake.doctor` | `Crosswake.Doctor` catches unsupported feature combinations exposed by exemplars and fails loudly. |
| Support Matrix Truth | **Documentation** | `Crosswake.SupportMatrix` | Generates a high-level matrix (`guides/support_matrix.md`) that links out to localized guide prose. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bash | Core OS | Hermetic proof lanes | `script/verify_*.sh` is the project's standard approach for deterministic, isolated verification. |
| ExUnit | ~> 1.15 | Profile testing | Used natively within the Crosswake test suite (e.g., `test/crosswake/proof/*_test.exs`). |
| Mix | Core OS | Task orchestration | `mix crosswake.doctor` remains the primary diagnostic interface. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hermetic Bash scripts | Fastlane / FastCI | Too heavy; Crosswake's ethos prefers raw bash and strict CI boundary enforcement. |
| One native compilation lane | Matrix native CI | Matrix CI causes combinatorial explosion; testing manifest generation in ExUnit is vastly faster and sufficient for profile testing. |

## Architecture Patterns

### Pattern 1: Hermetic Proof Scripts
**What:** Creating localized `script/verify_<profile>.sh` scripts instead of relying on a single kitchen-sink verification script.
**When to use:** For validating Phase 7, 8, and 9 exemplars.
**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Verifying SaaS Profile Contract..."
# Orchestrate specific ExUnit lane for the profile
mix test test/crosswake/proof/phase7_saas_lane_test.exs
# Verify specific documentation contracts
grep -Fq "Boundary Warnings" guides/adopter_profiles.md
```

### Pattern 2: Honest Boundary Hybrid
**What:** Dispersing rough edge documentation into the exact feature guides they affect, rather than a separate file.
**When to use:** When a limitation or gap is identified during the exemplar implementation (e.g., lack of background sync for Local-First).
**Example:**
In `guides/offline.md` at the bottom:
```markdown
## Boundary Warnings & Rough Edges
- **Background Sync:** True background synchronization while the app is swiped away is not supported in the v1 substrate. Fall back to manual reconciliation hooks upon app resume.
```

### Anti-Patterns to Avoid
- **API Scope Creep:** Attempting to modify `Crosswake.RoutePolicy` or add new Elixir configuration options to "handle" a missing feature exposed by the exemplars.
- **Centralized Rough Edges:** Pushing all caveats to a `ROUGH_EDGES.md` file where developers will miss them during implementation.
- **Native Test Matrix Explosion:** Running `xcodebuild` or `./gradlew build` for every exemplar profile variation in CI.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Central CI Matrix | Complex GitHub Actions matrix for all profiles | Hermetic Bash (`script/verify_*.sh`) + ExUnit | Crosswake relies on Elixir-level unit testing for manifest/code generation, reserving full native compilation for one flagship host. |
| Status Matrix | Hand-typed `support_matrix.md` | `Crosswake.SupportMatrix.Renderer` | Ensures documentation truth is generated directly from Elixir code (`support_matrix.ex`). |

## Common Pitfalls

### Pitfall 1: Leaking Native Logic into Proof Lanes
**What goes wrong:** Adding `xcodebuild` steps inside `verify_saas_profile.sh` or `verify_local_first.sh`.
**Why it happens:** Misunderstanding the scope of "Proof Lane" testing.
**How to avoid:** Keep `script/verify_generated_ios_shell.sh` separate and strictly tied to the single canonical example host. Profile scripts should *only* invoke Elixir tests and `grep` checks.
**Warning signs:** CI times spike above 5-10 minutes due to redundant compilation.

### Pitfall 2: Silently Swallowing Gaps
**What goes wrong:** A gap identified in the Local-First exemplar is handled by ignoring it or writing a hack in the example host.
**Why it happens:** Reluctance to admit a framework limitation.
**How to avoid:** Explicitly code `Crosswake.Doctor` to flag the gap as an error, and document it under "Boundary Warnings" in the relevant guide.

## Code Examples

### Upgrading the Doctor to Catch Gaps
```elixir
# lib/crosswake/doctor/doctor.ex
defp validate_exemplar_boundaries(findings, manifest) do
  # Catch situations where a route tries to use unsupported native APIs
  Enum.reduce(manifest.routes, findings, fn {_id, route}, acc ->
    if route.runtime == :offline_island and "background_sync" in route.capabilities do
      [
        check(
          :error,
          "unsupported_capability",
          "route_policy",
          "Route #{route.path} requests background_sync which is an explicit v1 boundary",
          "Remove background_sync capability. See Boundary Warnings in guides/offline.md"
        )
        | acc
      ]
    else
      acc
    end
  end)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Centralized `ROUGH_EDGES.md` | Localized "Boundary Warnings" in guides | Phase 10 | Contextualizes limitations exactly where developers read how to use the feature. |
| Monolithic Kitchen Sink App | Hermetic `verify_<profile>.sh` scripts | Phase 10 | Matches the adopter "first hour" experience precisely and prevents state leakage across tests. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExUnit tests for Phase 8/9 already exist but need orchestration | Architecture Patterns | If they don't exist, we must build them as part of the hermetic script scaffolding. |
| A2 | `script/verify_phase5_example_hosts.sh` currently runs everything | Architecture Patterns | We must carefully separate the Elixir tests from the Native builds if we split out the hermetic scripts. |

## Open Questions (RESOLVED)

1. **Test Extraction** (RESOLVED)
   - What we know: `verify_phase5_example_hosts.sh` currently runs `phase7_saas_lane_test.exs`, `phase8_selective_native_lane_test.exs`, and `phase9_local_first_lane_test.exs` synchronously.
   - What's unclear: Should we split this into separate `verify_saas_profile.sh` etc. or just update `verify_phase5_example_hosts.sh` to be the master orchestration script?
   - Recommendation: The Context explicitly asks for "isolated, per-profile verification scripts (e.g. `script/verify_saas_profile.sh`)". We should break them out.
   - Resolution: We will extract these into separate hermetic bash scripts as recommended.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | Hermetic proof lanes | ✓ | — | — |
| `mix` / `elixir` | Doctor upgrades, ExUnit validation | ✓ | — | — |

**Missing dependencies with no fallback:**
- None. This phase operates strictly within the existing Crosswake/Elixir toolchain.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `Crosswake.Doctor` and `Crosswake.RoutePolicy` compile-time checks |

### Known Threat Patterns for Elixir / Crosswake

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misconfigured Route Policy | Information Disclosure | `Crosswake.Doctor` must fail loudly if sensitive capabilities are requested without proper explicit offline/runtime modes. |
