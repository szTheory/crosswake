# Phase 7: Phoenix SaaS Portal Exemplar - Research

**Researched:** 2026-05-17
**Domain:** Shared-host Phoenix SaaS exemplar planning
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked decisions
- **Product slice:** keep Phase 7 centered on an approvals-led SaaS portal with account health as supporting context, not as the primary story.
- **Route budget:** stay within five primary routes, with the recommended set under `/saas`.
- **Auth posture:** ordinary Phoenix session auth, one lightweight role split, host-owned example code, and authorization enforced in normal Phoenix and LiveView boundaries.
- **Native affordance:** use one low-frequency, supporting `haptics.impact` affordance; keep the approval action and product flow server-authoritative and Phoenix-owned.
- **Support posture:** shell truth, fail-closed denial behavior, and support honesty come before capability demo value.
- **Artifact class:** extend the shared checked-in Phoenix host plus paired iOS and Android example hosts; do not create a separate sample app or alternative proof system.
- **Scope exclusions:** no offline islands, pack-heavy pressure, native capture, transfer-first stories, billing, identity-provider integrations, or starter-app scope drift.

### Agent discretion
- Exact module breakdown for the SaaS lane.
- Exact approval-domain naming and fixture copy.
- Exact route-local placement of `haptics.impact`.
- Exact doc layout as long as support-matrix duplication is avoided.

### Deferred ideas
- Uploads, attachments, or file-pick as the main product slice.
- SSO, MFA, passkeys, org switching, or vendor auth flows.
- Native-screen ownership, broader bridge breadth, or offline write semantics.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SAAS-01 | Phoenix teams can run a SaaS-portal exemplar route set that keeps the majority of authenticated product flows in LiveView while exercising at least one bounded native affordance without shell forking. | Add one authenticated `/saas` lane inside the shared example host, keep all primary routes `:live_view`, and attach exactly one route-local `haptics.impact` capability to a server-authoritative approval confirmation flow. |
| SAAS-02 | Phoenix teams can verify from guides and proof lanes which server-centric mobile-shell boundaries are supported for the SaaS profile and which remain intentionally unsupported. | Extend the existing guide and proof scaffold with SaaS-lane route, capability, denial, and non-goal assertions; keep support status canonical in existing install and support guides. |
</phase_requirements>

## Summary

Phase 7 should prove `routine mobile approvals inside a Phoenix-owned shell`, not “mobile SaaS in general.” The strongest implementation shape is a `CrosswakeExample.SaaSPortal.*` lane inside the shared Phoenix host with five authenticated `:live_view` routes, one lightweight role split, minimal seed data, and one guarded approval action that triggers `haptics.impact` as a supporting confirmation signal. That keeps the product story believable while preserving the locked thesis that the server remains the product owner and the bridge stays low-frequency, typed, and bounded.

The repo already has the right substrate for this. Phase 6 locked the SaaS lane boundary in `guides/adopter_profiles.md` and `examples/phoenix_host/README.md`; the current example host router already demonstrates Crosswake-owned route metadata inside a shared host; and the proof scaffold already checks that later phases extend the checked-in host artifacts rather than introducing parallel sample apps or proof systems. Phase 7 should therefore focus on three things only: `host lane implementation`, `manifest/proof extension`, and `SaaS boundary documentation`.

**Primary recommendation:** plan Phase 7 as three executable plans:
1. establish the authenticated SaaS lane scaffolding and route declarations in the shared example host,
2. implement the LiveView approvals flow plus the bounded `haptics.impact` seam and manifest-backed proof assertions,
3. publish SaaS-boundary docs and extend proof scripts/tests so supported, degraded, and deferred behavior stays explicit.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Authenticated SaaS route ownership | Shared Phoenix example host | Crosswake manifest compilation | Auth stays host-owned, while Crosswake proves route metadata and runtime ownership through the compiled manifest. |
| Approval workflow and role enforcement | LiveView and ordinary Phoenix auth boundaries | Fixture data | The point is a believable Phoenix slice, not a new Crosswake auth system. |
| Native affordance confirmation | Route-local bridge capability declaration | Shell bridge contract | `haptics.impact` should stay route-local and supporting, using existing typed bridge surfaces only. |
| Failure vocabulary and activation truth | Existing shell guides and denial contract | SaaS lane docs | `route unavailable` remains the public shell-truth focus for this lane. |
| Proof and support truth | Existing checked-in host scripts and ExUnit proof tests | SaaS-specific assertions layered on top | Phase 7 should extend the existing artifact class and proof posture rather than replacing it. |

## Standard Stack

### Core
| Surface | Purpose | Why standard here |
|--------|---------|-------------------|
| `examples/phoenix_host` | Shared exemplar artifact class | Phase 6 already locked this as the downstream lane container. |
| Phoenix router + LiveView | Authenticated SaaS route slice | Phase 7 is supposed to feel like ordinary Phoenix app code, not a custom framework layer. |
| Crosswake route metadata in router | Runtime and capability truth | Existing example host and proof tests already compile and inspect manifest truth from router-authored declarations. |
| ExUnit proof tests + shell verification scripts | Public proof posture | Existing Phase 5 and Phase 6 proof scaffolds are already the canonical extension points. |

### Supporting
| Surface | Purpose | When to use |
|--------|---------|-------------|
| `guides/adopter_profiles.md` | Public SaaS profile framing | Keep route names, non-goals, and failure vocabulary aligned with the Phase 6 contract. |
| `guides/native_shell.md` | Shell activation and denial truth | Reuse for fail-closed shell behavior and bounded bridge framing. |
| `guides/support_matrix.md` and `guides/install.md` | Canonical support and proof status | Link to these rather than duplicating support claims in new SaaS docs. |
| `script/verify_adopter_profile_contract.sh` | Shared-host lane boundary guardrail | Extend only if the added checks preserve the existing shared-host contract role. |

## Recommended Architecture

### Route lane

Use one `/saas` route group under shared `crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard` defaults. The recommended route set from context is still the best fit:

- `/saas/dashboard`
- `/saas/accounts/:id`
- `/saas/approvals`
- `/saas/approvals/:id`
- `/saas/settings/profile`

Only the approval-detail route should need the primary capability declaration for `haptics.impact`, because that keeps the affordance tied to one meaningful confirmation moment and prevents the lane from reading like a generic capability demo.

### Auth boundary

Keep all auth and authz in host-owned example code. The best fit is:

- one lightweight user/session fixture layer,
- one `member` versus `approver` distinction,
- router or `live_session` gating for signed-in access,
- `on_mount` or equivalent LiveView assignment boundary,
- approval action authorization re-checked inside the action path.

This preserves the Phase 7 requirement that route policy is not a substitute for Phoenix authorization.

### Manifest and capability posture

Phase 7 should prove that the SaaS lane compiles into manifest truth the same way prior exemplar surfaces do. The plan should therefore include automated assertions for:

- new SaaS route ids present in the manifest,
- all SaaS routes remaining `:live_view`,
- the approval-confirmation route exposing `haptics.impact`,
- no route-local drift into transfer, pack-heavy, native-screen, or offline-island semantics.

### Docs and proof posture

Phase 7 docs should explain:

- what the SaaS lane proves,
- why `route unavailable` remains the failure-vocabulary focus,
- that auth scaffolding is host-owned example code,
- which route classes and native seams remain deferred.

Those docs should then link back to `guides/native_shell.md`, `guides/install.md`, and `guides/support_matrix.md` for canonical shell, install, and support truth.

## Proposed Plan Decomposition

### Plan 07-01: Establish the authenticated SaaS lane in the shared example host

**Goal:** create the route/module/fixture/auth scaffolding needed for the shared host to carry a believable SaaS slice.

**Should cover**
- `/saas` router group and route metadata
- host-owned auth/session and role fixtures
- `CrosswakeExample.SaaSPortal.*` module boundaries
- minimal seed data and approval/account domain scaffolding

**Should not cover**
- native affordance execution details
- shell proof updates beyond route-presence checks
- final guide publication

### Plan 07-02: Implement the approvals flow and bounded capability proof

**Goal:** make the SaaS lane actually exercise the server-centric product flow and one manifest-backed native affordance.

**Should cover**
- dashboard, approvals list/detail, account detail, and settings/profile LiveViews
- guarded approval action
- route-local `haptics.impact` declaration and invocation
- manifest/proof assertions for SaaS routes, runtime, and capability exposure
- alignment checks for iOS and Android checked-in hosts where applicable

**Should not cover**
- broader bridge breadth
- native-screen ownership
- transfer or offline behavior

### Plan 07-03: Publish SaaS boundary docs and final proof-lane wiring

**Goal:** make the support posture explicit and keep proof/documentation honest.

**Should cover**
- SaaS-lane host README updates if needed
- a dedicated guide or guide section describing supported, degraded, and deferred SaaS boundaries
- proof-script and ExUnit updates that prove the SaaS lane extends existing artifact classes and fail-closed shell truth
- explicit cross-links back to install/support/native-shell guides

**Should not cover**
- new support-matrix tables
- new artifact classes
- native or auth capability expansion

## Patterns To Reuse

### Pattern 1: Shared host lane extension
Extend `examples/phoenix_host` and keep all SaaS code under `CrosswakeExample.SaaSPortal.*`. This preserves the locked shared-artifact posture and keeps later exemplar lanes composable.

### Pattern 2: Route-local bounded capability use
Declare `haptics.impact` only where the approval confirmation happens. Avoid “just in case” declarations on the full `/saas` scope.

### Pattern 3: Docs summarize, canonicals own status
Use SaaS docs to explain the lane boundary and link outward for support truth. Do not restate platform baselines or exact generated-shell verification hook names.

### Pattern 4: Layer proof on existing scripts
Extend `test/crosswake/proof/phase5_proof_lane_test.exs`, `test/crosswake/proof/adopter_profile_contract_test.exs`, and related scripts instead of building a SaaS-only harness.

## Anti-Patterns To Block

- Building a separate SaaS sample app or shell project.
- Introducing `Crosswake.Auth` or a shell-aware auth abstraction.
- Using route policy as the main authorization mechanism.
- Making `files.pick`, transfer commands, or `app.info.get` the primary Phase 7 story.
- Reframing denials as graceful generic-container fallback.
- Expanding the lane into notifications, billing, uploads, or analytics-heavy dashboarding.
- Duplicating support status inside the SaaS guide.

## Common Pitfalls

### Pitfall 1: The SaaS lane becomes a generic mobile demo
If the route set expands beyond the approvals-led slice, the phase stops pressuring shell truth and starts chasing feature breadth.

### Pitfall 2: Auth realism turns into auth product scope
One lightweight role split is enough. Anything beyond that weakens the exemplar and creates vendor or protocol scope drift.

### Pitfall 3: Capability proof overshadows product ownership
If `haptics.impact` becomes central to the flow instead of supporting it, the plan starts proving the bridge rather than a believable Phoenix-owned SaaS route set.

### Pitfall 4: Docs silently fork support truth
SaaS-lane docs should explain boundaries, not replace `guides/support_matrix.md` or the install/proof entrypoints.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth abstraction | New Crosswake auth subsystem | Host-owned Phoenix session auth | Phase 7 explicitly says auth remains normal example-app code. |
| Capability bus | Generic bridge command surface | Existing `haptics.impact` bounded contract | The project thesis rejects plugin-bus drift. |
| Separate proof workflow | SaaS-only standalone verification system | Existing Phase 5 and Phase 6 scripts/tests plus SaaS assertions | Public proof remains anchored on the checked-in host artifact class. |
| Support publication | New SaaS status matrix | Existing support/install/native-shell guides | Canonical support truth already has a home. |

**Key insight:** Phase 7 succeeds when an adopter can look at one shared host and see a believable Phoenix-owned mobile SaaS slice that `stays LiveView-first, fails closed honestly, and uses exactly one bounded native seam without shell forks`. Anything broader is likely scope drift.
