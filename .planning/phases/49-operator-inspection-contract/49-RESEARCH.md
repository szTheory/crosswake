# Phase 49: Operator Inspection Contract - Research

**Researched:** 2026-05-31  
**Domain:** Phoenix/Elixir operator inspection contract (route-centric diagnostics + machine JSON)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a hybrid boundary: add a first-class `mix crosswake.inspect` task backed by a reusable `Crosswake.OperatorInspection` module. Do not make operators use `doctor` or raw manifest/support-matrix APIs as the primary inspection interface.
- **D-02:** `doctor` remains findings-first diagnostics. Inspection is inventory/readiness-first. Future doctor readiness work may consume `Crosswake.OperatorInspection`, but Phase 49 should not bury the inspection contract behind `mix crosswake.doctor --inspect`.
- **D-03:** The inspector must source truth from existing compiled route policy, `Crosswake.Manifest`, `Crosswake.SupportMatrix`, companion registry state, doctor finding semantics, and `Crosswake.Shell.Denial` vocabulary. It must not duplicate canonical support, denial, or capability truth by hand.
- **D-04:** The command shape should be boring and discoverable: `mix crosswake.inspect --router Elixir.YourAppWeb.Router --format human|json`. Human format is the default; JSON is the CI/support contract.
- **D-05:** The public module should expose a stable programmatic API such as `Crosswake.OperatorInspection.inspect/1` or `from_manifest/2`. Exact function names are planner discretion, but the module owns the inspection contract and renderers call into it.
- **D-06:** Keep the command separate from `crosswake.doctor` because ecosystem precedent strongly separates inventory/inspection from diagnostics.
- **D-07:** Use a versioned, route-centric inspection document. The route entry is the authority for ownership, runtime, capability, commerce, companion, auth, notification, support, denial, and rebuild truth.
- **D-08:** Add derived indexes and findings sidecars only as views over route entries. Indexes and findings must never become independent authority that can contradict `routes`.
- **D-09:** Recommended top-level JSON fields: `schema_version`, `generated_at`, `crosswake_version`, `source`, `summary`, `routes`, `indexes`, `findings`, `provenance`.
- **D-10:** Recommended per-route field categories: `id/path/runtime/entry`, `ownership`, `offline`, `capabilities`, `commerce`, `companion`, `auth`, `notifications`, `support`, `rebuild`, `denials`, `conditions`.
- **D-11:** Versioning rule: tools may ignore unknown fields in compatible minor versions; unsupported major versions must fail closed.
- **D-12:** Serialize public enums as strings in JSON; keep Elixir internals typed and use existing `Types.to_map/1` style where appropriate.
- **D-13:** Do not use Ecto schemas/changesets; use plain structs, closed vocabularies, constructors, validators, and renderers.
- **D-14:** Preserve split vocabularies (support status, severity, proof posture, rebuild class, denial reason, gate state, condition status).
- **D-15:** Use support statuses from `Crosswake.SupportMatrix.statuses/0`: `supported`, `verification_required`, `unsupported`.
- **D-16:** Use finding severities: `error`, `warning`, `advisory`.
- **D-17:** Use proof classes: `merge_blocking`, `advisory`.
- **D-18:** Use rebuild/change-class language: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, `native or companion rebuild required`.
- **D-19:** Use denial reasons from `Crosswake.Shell.Denial.reasons/0`.
- **D-20:** Add condition-like records (`type/status/reason/severity/message/route_id/details`) as additive wrappers only.
- **D-21:** Never collapse output into single opaque readiness states that hide raw axes.
- **D-22:** Provider adapter readiness must remain deferred/verification-required.
- **D-23:** Notification readiness is token/provider snapshot visibility only; no delivery claims.
- **D-24:** Auth readiness is Sigra contract-only predicates plus fail-closed `:step_up_required`; no full auth machinery claims.
- **D-25:** Companion readiness may report typed seam truth only; no generic plugin-bus behavior.
- **D-26:** Rebuild requirements must be visible where support posture changes.
- **D-27:** Human output should be concise and route-centric.
- **D-28:** JSON output is the stable contract.
- **D-29:** Keep filters simple (`--route`, `--format`, optionally `--only-errors`/`--check`).
- **D-30:** Errors should point to route ids/policy keys/denial codes/guide paths.
- **D-31..D-36:** Preserve explicit/fail-closed contract posture and avoid severity/support conflation.

### the agent's Discretion
- Exact file layout and internal struct/module naming.
- Exact derived index set.
- Exact human table layout.
- Exact doctor integration (bias: reusable core now; deeper doctor composition in Phase 50).

### Deferred Ideas (OUT OF SCOPE)
- `mix crosswake.doctor --check-publish` (Phase 50).
- Support-matrix expansion/native rebuild public guidance (Phase 51).
- Full docs-contract + hermetic operator-surface locks (Phase 52).
- StoreKit/Play Billing/full Sigra/Chimeway/standalone shell claims.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPER-01 | Single operator-facing output for route ownership/runtime/capabilities/commerce/companions/auth/rebuild | Route-centric schema and `mix crosswake.inspect` + `Crosswake.OperatorInspection` seam using manifest/support/doctor vocabularies [VERIFIED: codebase grep] |
| OPER-02 | Machine-readable output consumable by CI/support | Stable JSON formatter + versioned schema + enum-string serialization + deterministic tests [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 49 should be implemented as a new inspection pipeline parallel to doctor, not as a doctor mode. The existing code already has most source truth needed: manifest route fields, support statuses, denial vocabulary, auth contract rows, companion gate truth, and notification provider vocabulary. The missing piece is a dedicated operator contract module plus task/renderers that compose these into route-authoritative output. [VERIFIED: codebase grep]

The highest-risk failure mode is creating duplicate authority (custom statuses or invented vocabularies) that diverges from canonical modules. Planning should enforce route-first assembly and derive indexes/findings/conditions from routes so JSON remains stable and CI-safe while human output remains concise. [VERIFIED: codebase grep]

**Primary recommendation:** Implement `Crosswake.OperatorInspection` as a typed aggregation layer fed by `Manifest.compile/1`, `SupportMatrix`, `Doctor` findings, `Shell.Denial`, and companion/auth/notification surfaces, then expose it via new `mix crosswake.inspect --router ... --format human|json`. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compile route policy and manifest for inspection | API / Backend | — | Mix task and manifest builder run in Elixir host runtime [VERIFIED: codebase grep] |
| Build route-centric inspection contract | API / Backend | — | Contract is server-side Elixir structs/maps rendered to human/json [VERIFIED: codebase grep] |
| Render machine-readable JSON for CI/support | API / Backend | — | Existing doctor JSON formatter pattern is Elixir-side [VERIFIED: codebase grep] |
| Surface companion/gate/auth/denial/readiness vocab | API / Backend | Database / Storage | Values come from runtime modules and env-backed companion state [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Keep Phoenix-first thesis; do not reframe as universal UI framework. [VERIFIED: codebase grep]
- Keep per-route runtime ownership explicit. [VERIFIED: codebase grep]
- Keep bridge contracts typed/versioned/low-frequency. [VERIFIED: codebase grep]
- Keep offline claims explicit (cached vs local-first mutation). [VERIFIED: codebase grep]
- Treat diagnostics/support/proof/rough edges as product surface. [VERIFIED: codebase grep]
- Respect v1 scope boundaries and deferred breadth. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` (project requirement) | Host contract + Mix task implementation | Existing codebase standard/runtime baseline [VERIFIED: codebase grep] |
| Phoenix | `1.8.7` (lockfile) | Router source compiled for inspection | Existing route policy source of truth [VERIFIED: codebase grep] |
| Jason | `1.4.5` (lockfile) | Stable JSON serialization | Already used for machine-readable doctor output [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Crosswake.Manifest` / `Types` | in-repo | Route/capability/commerce/auth fields | Authoritative route payload source [VERIFIED: codebase grep] |
| `Crosswake.SupportMatrix` | in-repo | statuses/proof/rebuild/auth contract/gating truth | Canonical support vocabulary and rebuild language [VERIFIED: codebase grep] |
| `Crosswake.Doctor.Check` and findings | in-repo | severity + typed findings | Use as findings sidecar seed [VERIFIED: codebase grep] |
| `Crosswake.Shell.Denial` | in-repo | denial vocabulary | Canonical denial reasons for route denials [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New `mix crosswake.inspect` | Extend `mix crosswake.doctor` | Violates locked decision boundary and mixes inventory with diagnostics [VERIFIED: codebase grep] |
| Route-authoritative JSON | Findings-only JSON | Cannot satisfy OPER-01 inventory requirements alone [VERIFIED: codebase grep] |

**Installation:** No new external packages recommended for Phase 49. Reuse existing dependencies. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No new external packages are required by this phase; Package Legitimacy Gate is not triggered. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

`mix crosswake.inspect --router RouterModule`  
-> parse args (`--router`, `--format`)  
-> compile route policy (`Manifest.compile/1`)  
-> gather canonical vocab/state (`SupportMatrix`, `Denial.reasons/0`, companion gate/auth/notification truths, doctor findings)  
-> build route-authoritative inspection doc (`Crosswake.OperatorInspection`)  
-> derive `summary/indexes/findings/conditions` from route entries  
-> render (`OperatorInspection.Formatter` or `.JSONFormatter`)  
-> print output and fail closed on blocking contract errors.

### Recommended Project Structure
```text
lib/
├── crosswake/operator_inspection.ex
├── crosswake/operator_inspection/types.ex
├── crosswake/operator_inspection/formatter.ex
├── crosswake/operator_inspection/json_formatter.ex
└── mix/tasks/crosswake.inspect.ex

test/
├── mix/tasks/crosswake_inspect_test.exs
├── crosswake/operator_inspection/operator_inspection_test.exs
└── crosswake/operator_inspection/formatter_test.exs
```

### Pattern 1: Route-Authoritative Contract Assembly
**What:** Build one map/struct per route from manifest route entries, then derive cross-route indexes.  
**When to use:** Always for inspection JSON and human summary.  
**Example:** Reuse route fields already present in `Types.RouteEntry` and serialize enums to strings in formatter layer. [VERIFIED: codebase grep]

### Pattern 2: Canonical Vocabulary Reuse
**What:** Pull statuses/severities/proof/rebuild/denials from existing modules, never duplicate literals.  
**When to use:** Any support/readiness finding or route condition.  
**Example:** `SupportMatrix.statuses/0`, `Doctor.Check.severity`, `Shell.Denial.reasons/0`. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- Inventing a new “overall readiness state” as authoritative.
- Emitting human prose as machine contract.
- Copy-pasting support/denial literals into new modules.
- Treating advisories as supported.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON encoding/pretty output | Custom encoder | `Jason.encode!/2` pattern from doctor formatter | Already battle-tested with nil/false edge handling [VERIFIED: codebase grep] |
| Support vocabulary | New enum set | `SupportMatrix` accessors and change-class rows | Prevents support-truth drift [VERIFIED: codebase grep] |
| Denial taxonomy | Route-local strings | `Shell.Denial.reasons/0` + commerce corridor codes | Keeps fail-closed parity [VERIFIED: codebase grep] |
| Mix CLI parsing | Ad hoc argv parsing | `OptionParser` pattern from `crosswake.doctor` task | Consistent CLI ergonomics [VERIFIED: codebase grep] |

**Key insight:** Phase 49 is mostly contract composition, not new domain logic; minimizing new vocab/state is the safest path.

## Common Pitfalls

### Pitfall 1: Duplicate Authority
**What goes wrong:** `indexes`/`findings` disagree with `routes`.  
**Why it happens:** Building sidecars first, routes second.  
**How to avoid:** Make routes canonical and derive all summaries/indexes from them.  
**Warning signs:** Route id appears in finding/index but missing in `routes`.

### Pitfall 2: Severity/Support Conflation
**What goes wrong:** Advisory findings interpreted as supported routes.  
**Why it happens:** Using severity as support posture.  
**How to avoid:** Keep support status and severity as separate fields.  
**Warning signs:** CI checks only `severity != error` and ignores support status.

### Pitfall 3: Deferred Feature Overclaim
**What goes wrong:** Notification/auth/provider fields imply shipped delivery/full-auth/provider adapters.  
**Why it happens:** Unbounded wording in human/json fields.  
**How to avoid:** Encode deferred/verification-required with explicit reasons.  
**Warning signs:** Terms like “delivery ready”, “OAuth ready”, “StoreKit supported” appear.

## Code Examples

### Mix Task Pattern
```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: [format: :string, router: :string])
if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")
```
Source: `lib/mix/tasks/crosswake.doctor.ex` [VERIFIED: codebase grep]

### JSON Enum Serialization Pattern
```elixir
%{status: Map.get(report, :status) |> Atom.to_string()}
```
Source: `lib/crosswake/doctor/json_formatter.ex` [VERIFIED: codebase grep]

### Canonical Vocab Reuse
```elixir
SupportMatrix.statuses()
Crosswake.Shell.Denial.reasons()
```
Source: `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/shell/denial.ex` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Operator truth spread across doctor/manifest/support docs | Dedicated operator inspection contract + machine JSON (Phase 49 target) | 2026-05-31 planning lock | Enables CI/support consumption without prose scraping |

**Deprecated/outdated:**
- Using only `mix crosswake.doctor` output for inventory-style operator inspection. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Ecosystem precedence (Terraform/Kubernetes/Rails/Django split patterns) supports keeping inspect and doctor separate | User Constraints/Summary | Low: project decisions already lock this regardless |

## Open Questions

1. **Should Phase 49 include `--route`/`--only-errors` now or defer to later?**
   - What we know: Decision allows simple filters.
   - What's unclear: Minimum scoped option set expected by maintainers.
   - Recommendation: Plan core contract first; add one optional filter only if low-risk.

2. **How much of doctor findings should be mirrored versus recomputed in inspection?**
   - What we know: Decisions prefer reuse, not duplication.
   - What's unclear: Exact coupling boundary to keep Phase 50 composition simple.
   - Recommendation: Include route-relevant findings only; keep full diagnostic expansion in doctor.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | Task + contract build + tests | ✓ | OTP 28 / Mix present | — |
| Node/npm | Existing docs/tooling scripts only | ✓ | node `v22.14.0`, npm `11.1.0` | — |
| ExUnit | Validation architecture | ✓ | via `test/test_helper.exs` | — |

**Missing dependencies with no fallback:**
- None found.

**Missing dependencies with fallback:**
- None found.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project default) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPER-01 | Route-centric operator inventory contains required axes | unit/integration | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` | ❌ Wave 0 |
| OPER-02 | Machine-readable JSON contract stable and parseable | unit/task | `mix test test/crosswake/operator_inspection/json_formatter_test.exs test/mix/tasks/crosswake_inspect_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/operator_inspection/operator_inspection_test.exs`
- **Per wave merge:** `mix test test/crosswake/operator_inspection/*.exs test/mix/tasks/crosswake_inspect_test.exs`
- **Phase gate:** `mix test`

### Wave 0 Gaps
- [ ] `test/crosswake/operator_inspection/operator_inspection_test.exs`
- [ ] `test/crosswake/operator_inspection/json_formatter_test.exs`
- [ ] `test/crosswake/operator_inspection/formatter_test.exs`
- [ ] `test/mix/tasks/crosswake_inspect_test.exs`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Contract-only auth predicates from manifest/support truth; fail-closed `step_up_required` |
| V3 Session Management | no | Deferred full session machinery remains out of scope |
| V4 Access Control | yes | Route ownership/runtime + denial-code visibility fail closed |
| V5 Input Validation | yes | Strict CLI option parsing + typed structs/constructors |
| V6 Cryptography | no | No new cryptographic flows in Phase 49 |

### Known Threat Patterns for Elixir operator-inspection stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming support/readiness in machine output | Tampering | Canonical vocabulary reuse + proof tests |
| Route/operator data mismatch | Integrity | Route-authoritative schema + derived indexes |
| Misleading severity usage in CI | Repudiation | Keep severity distinct from support status fields |

## Sources

### Primary (HIGH confidence)
- `/.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` - locked decisions and scope.
- `/lib/mix/tasks/crosswake.doctor.ex` - CLI pattern (`--router`, `--format`, fail-closed behavior).
- `/lib/crosswake/doctor/doctor.ex` - diagnostics report + findings structure + manifest compile path.
- `/lib/crosswake/doctor/check.ex` - severity vocabulary.
- `/lib/crosswake/doctor/json_formatter.ex` - JSON formatting conventions and edge-case handling.
- `/lib/crosswake/manifest/types.ex` and `/lib/crosswake/manifest/builder.ex` - route/capability/commerce/auth field authority.
- `/lib/crosswake/support_matrix/support_matrix.ex` - support statuses, auth contract truth, gating truth, change classes.
- `/lib/crosswake/shell/denial.ex` - canonical denial vocabulary.
- `/lib/crosswake/bridge/commands/notification_token.ex` - provider snapshot vocabulary.
- `/test/mix/tasks/crosswake_doctor_test.exs`, `/test/crosswake/doctor/*`, `/test/crosswake/support_matrix/*`, `/test/crosswake/proof/phase46_*`, `/test/crosswake/proof/phase47_*` - precedent test patterns.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing in-repo dependencies and lockfile.
- Architecture: HIGH - phase context has explicit locked decisions and current seams are clear.
- Pitfalls: HIGH - directly observed from existing formatter/doctor/support proof patterns.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
