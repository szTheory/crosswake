# Phase 51: Support Matrix and Native Rebuild Truth - Research

**Researched:** 2026-06-01  
**Domain:** Crosswake support-truth contracts (support/proof/severity/rebuild/action/promotion)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep split canonical axes. Do not introduce one global
  `ready | degraded | blocked | deferred` lifecycle status as canonical support
  truth.
- **D-02:** Preserve these axes as independent machine-visible concepts:
  support status, proof class, diagnostic severity, rebuild/change/action
  requirement, denial reason, claim scope, and derived condition status.
- **D-03:** Support status remains narrow:
  `supported | verification_required | unsupported`.
- **D-04:** Proof class remains separate from support status:
  `merge_blocking | advisory | not_applicable` where needed for readiness
  checks.
- **D-05:** Diagnostic severity remains separate from both support and proof:
  `error | warning | advisory`. Severity is triage urgency, not a support claim.
- **D-06:** Operator conditions may exist only as derived wrappers over the raw
  axes. They are useful for CI/support querying, but they must never become a
  second source of truth.
- **D-07:** Internal Elixir should use closed atoms/structs where the codebase
  already does. JSON and rendered docs must expose stable string labels.
- **D-08:** Public docs must not invent synonyms such as "healthy",
  "production-ready", "green", or "degraded" unless they are explicitly derived
  human prose and the raw axes remain adjacent.
- **D-09:** Use a two-axis rebuild contract: `change_class` answers what
  changed, and `action_class` answers who must do what before the claim is safe.
- **D-10:** Keep current change classes as machine-stable labels unless the
  planner finds an unavoidable naming gap:
  `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and
  `native or companion rebuild required`.
- **D-11:** Add explicit action classes or equivalent machine fields for these
  subjects:
  `native_shell`, `companion_native`, `provider_adapter`, `route_manifest`,
  `compatibility`, and `docs_only`.
- **D-12:** Route-derived rebuild truth is necessary but insufficient. Phase 51
  must also cover non-route release surfaces: shell templates, native
  dependencies, entitlements/permissions, companion-native code, provider SDKs,
  compatibility windows, and docs-only support claims.
- **D-13:** A route/manifest or Phoenix-owned change can be core-only when
  compatibility axes and capability majors stay in range. Native code,
  generated shell projects, entitlements, permissions, platform config,
  provider SDKs, and companion-native integration require native or companion
  rebuild truth.
- **D-14:** Compatibility-window narrowing must be distinct from native rebuild:
  it may fail closed for unsupported combinations without requiring every
  already-compatible adopter to rebuild.
- **D-15:** Human guidance should answer "Do I need to rebuild?" directly, but
  machine output must expose the underlying subject, change class, action class,
  compatibility signal, required proof, and reasons.
- **D-16:** Use criteria-as-code promotion rules for any support claim that can
  move from advisory/verification-required to merge-blocking/supported.
- **D-17:** A promotion rule should include at least: `claim_id`, evidence class,
  required evidence set, minimum consecutive passes or equivalent repeatability
  threshold, freshness window, failure budget, required platforms/providers,
  required docs anchors, rebuild class, check ids, and demotion trigger.
- **D-18:** Environment-sensitive proof remains advisory until its promotion
  rule is satisfied. Provider, storefront, simulator, physical-device, and
  delivery proof must not become merge-blocking by implication.
- **D-19:** Promotion and demotion must be auditable. If a formerly
  merge-blocking lane becomes flaky, stale, or unsupported by current
  compatibility windows, the rule should define how it falls back to advisory or
  verification-required.
- **D-20:** Examples in docs should use contract-shaped examples, such as a
  future `purchase_intent.provider.storekit` claim promoting only after named
  StoreKit lanes, docs/support/doctor parity, rebuild guidance, and changelog
  truth are all present.
- **D-21:** Do not use governance-only checklists as the primary promotion
  mechanism. Human review can approve intent, but machine-readable criteria must
  carry the support claim.
- **D-22:** Public guidance must explicitly state that StoreKit and Play Billing
  adapters are not shipped in v3.6.
- **D-23:** Public guidance must explicitly state that Sigra remains
  contract-only for route predicates and `:step_up_required`; full handoff,
  ceremony, passkey, OAuth, refresh-token, and native auth UI are deferred.
- **D-24:** Public guidance must explicitly state that notification-token
  readiness is provider-snapshot readiness only; Chimeway delivery,
  notification-open routing, and push delivery guarantees are deferred.
- **D-25:** Public guidance must explicitly state that standalone public shell
  packages are deferred until the production shell runtime-line milestone.
- **D-26:** Advisory proof must remain visible in support matrix, doctor
  readiness, and operator inspection. It must not be rendered as supported by
  omission.
- **D-27:** Missing readiness must never silently pass as supported. A missing
  row, missing promotion rule, missing docs anchor, or missing rebuild reason
  should produce a warning/error/advisory finding according to the risk.

### the agent's Discretion
- Exact struct/module names are planner discretion. Strong default: extend
  `Crosswake.SupportMatrix` with typed rows/accessors instead of introducing an
  unrelated policy module.
- Exact `action_class` names are planner discretion if the subject/action split
  remains machine-visible and docs-rendered.
- Exact promotion thresholds are planner discretion per claim, but thresholds
  must be explicit and conservative. Prefer no promotion over weak promotion.
- Exact guide layout is planner discretion. Bias toward generated tables plus
  short explanatory prose and anchored examples.

### Deferred Ideas (OUT OF SCOPE)
- StoreKit or Play Billing adapter implementation.
- Full Sigra handoff, ceremony, passkey, OAuth, refresh-token, or native auth UI machinery.
- Chimeway delivery integration, notification-open routing, or push delivery proof.
- Standalone public shell packages.
- Phase 52 full proof/docs-contract lane, except focused tests needed to make Phase 51 truth credible.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUPP-01 | Support matrix truth distinguishes supported, verification-required, advisory, merge-blocking, rebuild-required, and unsupported states across routes, capabilities, companions, commerce, auth, notifications, and shell artifacts. | Keep split axes from `SupportMatrix` + `OperatorInspection` + `PublishReadiness`; add machine-stable action/promotion vocabulary into canonical truth and derive all renderers/checks from it. [VERIFIED: codebase grep] |
| SUPP-02 | Public guidance explains native rebuild requirements, advisory-to-merge-blocking promotion criteria, and rough edges without implying StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, or standalone shell packages have shipped. | Keep docs generated by `SupportMatrix.Renderer`, add explicit non-claims and promotion-rule rows with parity tests and doctor checks. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 51 should be an extension phase, not a rewrite: `Crosswake.SupportMatrix` is already the canonical vocabulary source, `Crosswake.OperatorInspection` already derives route-level support/proof/rebuild/conditions, and `Crosswake.Doctor.PublishReadiness` already carries stability for severity/result/proof/rebuild fields. Planning should preserve this architecture and add missing canonical vocabularies (especially action-class and promotion-rule truth) in one place. [VERIFIED: codebase grep]

`guides/support_matrix.md` is already byte-locked to `SupportMatrix.Renderer.render/1`, so public guidance updates should be implemented by extending typed truth and renderer sections, then keeping docs-contract tests strict. [VERIFIED: codebase grep]

**Primary recommendation:** Extend `Crosswake.SupportMatrix` typed entries with `action_class` + promotion-rule records, then consume those fields in renderer, operator inspection, and publish-readiness checks without creating a second policy source. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first route-policy thesis; no generic UI framework drift. [VERIFIED: codebase grep]
- Keep per-route runtime ownership explicit; no generic WebView fallback posture. [VERIFIED: codebase grep]
- Keep bridge contracts semantic/typed/versioned/low-frequency. [VERIFIED: codebase grep]
- Keep offline claims explicit and honest. [VERIFIED: codebase grep]
- Treat diagnostics/support matrices/proof lanes/docs rough edges as product surface. [VERIFIED: codebase grep]
- Respect v1 scope boundaries and deferred integrations. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical support/proof/rebuild/action vocabulary | API / Backend | Database / Storage | Lives in Elixir typed structs/constants and drives machine contracts. [VERIFIED: codebase grep] |
| Route-level derived support conditions | API / Backend | — | `OperatorInspection` computes derived conditions from manifest + support truth. [VERIFIED: codebase grep] |
| Publish/readiness diagnostics | API / Backend | — | `PublishReadiness` emits stable check contract and severities. [VERIFIED: codebase grep] |
| Public support matrix guide | Frontend Server (SSR) | CDN / Static | Markdown is generated from backend canonical data and shipped as docs. [VERIFIED: codebase grep] |
| Rebuild/adopter action guidance | API / Backend | Frontend Server (SSR) | Canonical in change classes; rendered for humans in guides. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | project runtime | Canonical typed support contracts and diagnostics | Existing codebase and tests are built on typed Elixir structs/modules. [VERIFIED: codebase grep] |
| ExUnit | built-in | Regression and docs-contract locking | Existing suite already locks support/inspection/doctor and renderer parity. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | `~> 1.8` (project support matrix target) | Route source for inspection | Use for route-authoritative inspection and manifest compilation. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `SupportMatrix` | New policy module | Creates duplicate truth and drift risk across renderer/doctor/inspection. [VERIFIED: codebase grep] |
| Typed atoms + structs | ad-hoc strings/maps only | Weakens compile-time guardrails and machine-stable vocabulary checks. [VERIFIED: codebase grep] |

## Package Legitimacy Audit

No external package installation is required for Phase 51 research/planning scope; section is N/A. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram
```text
Route Policy -> Manifest.Builder -> SupportMatrix.canonical
                                      |-> Renderer -> guides/support_matrix.md
                                      |-> OperatorInspection -> route support/proof/rebuild/conditions
                                      |-> PublishReadiness -> check-publish checks/findings
                                                        -> doctor CLI JSON/human output
```

### Recommended Project Structure
```text
lib/crosswake/support_matrix/        # Canonical vocab + renderer
lib/crosswake/operator_inspection/   # Derived route-facing truth
lib/crosswake/doctor/                # Publish/readiness checks
guides/                              # Generated and parity-locked public docs
test/crosswake/...                   # Hermetic contract + docs parity tests
```

### Pattern 1: Canonical-First Docs Generation
**What:** Keep guide text generated from typed support truth, not prose-authored tables. [VERIFIED: codebase grep]  
**When to use:** Any update to support vocab/rebuild semantics/non-claims. [VERIFIED: codebase grep]

### Pattern 2: Split Axes, Derived Conditions
**What:** Keep support status, proof class, severity, result, rebuild, and condition records separate; conditions are derived only. [VERIFIED: codebase grep]  
**When to use:** Operator/doctor expansions for SUPP-01.

### Anti-Patterns to Avoid
- **Single readiness state:** Collapses independent truth axes and violates locked decisions. [VERIFIED: codebase grep]
- **Doc-only edits for support truth:** Causes parity drift if not sourced from `SupportMatrix`. [VERIFIED: codebase grep]
- **Promoting advisory proof implicitly:** Must require explicit criteria-as-code rule. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown support tables | Manual prose table maintenance | `Crosswake.SupportMatrix.Renderer` | Already deterministic + byte-identity tested. [VERIFIED: codebase grep] |
| Route inspection schema | One-off map building in each caller | `Crosswake.OperatorInspection.Types` + `to_map/1` | Keeps schema versioning and stable JSON labels. [VERIFIED: codebase grep] |
| Publish readiness outputs | Ad-hoc doctor warnings | `Crosswake.Doctor.PublishReadiness.ReadinessCheck` contract | Stable ids/codes/severity/result/proof/rebuild fields already enforced. [VERIFIED: codebase grep] |

## Common Pitfalls

### Pitfall 1: Axis Collapse
**What goes wrong:** `proof_class` or severity is treated as support status.  
**How to avoid:** Keep status/proof/severity/result/rebuild/action fields distinct in types/tests. [VERIFIED: codebase grep]

### Pitfall 2: Secondary Source of Truth
**What goes wrong:** New module defines action/promotion truth outside `SupportMatrix`.  
**How to avoid:** Add canonical accessors in `SupportMatrix` and consume everywhere else. [VERIFIED: codebase grep]

### Pitfall 3: Missing Non-Claims
**What goes wrong:** Docs imply shipped StoreKit/Play/Sigra full/Chimeway/standalone shells.  
**How to avoid:** Explicit non-claim rows and checks in renderer + publish-readiness tests. [VERIFIED: codebase grep]

## Code Examples

### Canonical change classes
```elixir
# Source: /Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex
SupportMatrix.canonical().change_classes
# => docs-only | core-only/no native rebuild | compatibility-bump only | native or companion rebuild required
```

### Deterministic guide rendering
```elixir
# Source: /Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex
rendered = Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())
File.write!("guides/support_matrix.md", rendered)
```

### Route-derived support/proof/rebuild
```elixir
# Source: /Users/jon/projects/crosswake/lib/crosswake/operator_inspection.ex
doc = Crosswake.OperatorInspection.inspect(route_source: MyAppWeb.Router)
doc.routes["checkout"].support
doc.routes["checkout"].rebuild
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prose-maintained support matrix | Canonical typed matrix rendered to docs and parity-tested | v3.2-v3.5 | Reduced drift and machine stability. [VERIFIED: codebase grep] |
| Route checks only | Route checks + publish-readiness sidecar with stable IDs/codes | Phase 50 (2026-06-01) | Better operator diagnostics without replacing route truth. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ASVS category mapping below reflects project threat model for this phase. [ASSUMED] | Security Domain | Medium; planner may under/over-specify controls. |

## Open Questions (RESOLVED)

1. **Action-class encoding location**
   - What we know: Must be machine-visible and canonical. [VERIFIED: codebase grep]
   - Resolution: Put the canonical action-class registry in `Crosswake.SupportMatrix` and reference action-class ids from change-class rows, route-derived rebuild maps, doctor checks, and docs renderer output. Do not attach an independent hand-authored action-class table to each consumer.
   - Planning implication: Plan 51-01 should create the typed registry and accessors first; Plans 51-02 and 51-03 consume those accessors only.

2. **Promotion-rule persistence**
   - What we know: Criteria-as-code required, auditable promotion/demotion required. [VERIFIED: codebase grep]
   - Resolution: Start with typed module constants/accessors in `Crosswake.SupportMatrix`, using `PromotionRuleEntry` structs from `Crosswake.Manifest.Types`. Do not embed promotion rules into generated manifests in Phase 51 unless a consumer already needs manifest transport.
   - Planning implication: Phase 51 should expose promotion rules through support-matrix, renderer, operator-inspection, and doctor-readiness contracts; persistence or manifest transport is deferred until a future native/provider runtime line needs it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | support/inspection/doctor code + tests | ✓ | Elixir 1.19.5 / OTP 28 | — |
| `mix` | ExUnit and task execution | ✓ | Mix 1.19.5 | — |
| `git` | docs parity + workflow continuity | ✓ | 2.41.0 | — |

**Missing dependencies with no fallback:** none detected.  
**Missing dependencies with fallback:** none detected.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix) [VERIFIED: codebase grep] |
| Config file | `mix.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUPP-01 | Split vocab stays stable across support/proof/rebuild/conditions | unit/contract | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/doctor/publish_readiness_test.exs -x` | ✅ |
| SUPP-02 | Public guidance + non-claims + rebuild/promotion truth remain explicit | docs-contract | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/companions_test.exs test/crosswake/guides/capabilities_test.exs -x` | ✅ |

### Sampling Rate
- **Per task commit:** support-matrix + renderer tests
- **Per wave merge:** support-matrix + inspection + publish-readiness + guide parity tests
- **Phase gate:** `mix test` full suite

### Wave 0 Gaps
- Add Phase 51 tests for new `action_class` canonical vocabulary and renderer columns. [VERIFIED: codebase grep]
- Add Phase 51 tests for promotion-rule structure presence and advisory→merge-blocking criteria visibility. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Sigra predicate posture remains contract-only and fail-closed (`step_up_required`). [VERIFIED: codebase grep] |
| V3 Session Management | yes | Auth freshness predicates represented as readiness, not implied full session support. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Route ownership + denial vocabulary + fail-closed semantics. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Typed structs/closed enums for support/check vocabularies. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase 51 scope is support-truth/docs/diagnostics, not crypto primitives. [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/crosswake/.planning/phases/51-support-matrix-and-native-rebuild-truth/51-CONTEXT.md` — locked phase decisions/scope.
- `/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex` — canonical support vocabulary and change classes.
- `/Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex` — deterministic docs renderer.
- `/Users/jon/projects/crosswake/lib/crosswake/operator_inspection.ex` and `/Users/jon/projects/crosswake/lib/crosswake/operator_inspection/types.ex` — derived support/rebuild/condition contracts.
- `/Users/jon/projects/crosswake/lib/crosswake/doctor/publish_readiness.ex` — stable publish-readiness check contract.
- `/Users/jon/projects/crosswake/guides/support_matrix.md` — current generated public surface.
- `/Users/jon/projects/crosswake/test/crosswake/support_matrix/support_matrix_test.exs`
- `/Users/jon/projects/crosswake/test/crosswake/support_matrix/renderer_test.exs`
- `/Users/jon/projects/crosswake/test/crosswake/operator_inspection/operator_inspection_test.exs`
- `/Users/jon/projects/crosswake/test/crosswake/doctor/publish_readiness_test.exs`
- `/Users/jon/projects/crosswake/.planning/REQUIREMENTS.md`
- `/Users/jon/projects/crosswake/.planning/STATE.md`
- `/Users/jon/projects/crosswake/AGENTS.md`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing stack/contracts are explicit and tested.
- Architecture: HIGH - module boundaries and data flow are implemented and stable.
- Pitfalls: HIGH - directly derived from failing modes guarded in tests and locked decisions.

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01
