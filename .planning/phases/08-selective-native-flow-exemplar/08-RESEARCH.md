# Phase 8: Selective Native Flow Exemplar - Research

**Researched:** 2026-05-18 [VERIFIED: system date]
**Domain:** Selective-native exemplar planning for the shared Crosswake example host [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo docs, router, proof tests, and official Phoenix docs reviewed in this session]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

### Product slice
- **D-01:** The selective-native exemplar should be a claims-evidence capture lane, not a billing/paywall lane, scanner lane, receipt/OCR lane, or generic media-upload demo.
- **D-02:** The lane should feel like a believable mobile companion flow where Phoenix owns the queue, detail, and review surfaces, and one native route owns the device-heavy capture step.
- **D-03:** The claims domain is chosen because it pressures the exact seams Crosswake wants to harden in Phase 8: one explicit `:native_screen`, route-local pack readiness, route-local transfer preparation, sensitive-route truth, and fail-closed activation.
- **D-04:** Keep the domain generic and fixture-light. Do not pull the lane toward insurance, healthcare, finance-policy, or vendor-specific compliance semantics.

### Route map and lane structure
- **D-05:** The lane should use four routes under a dedicated `/native` scope:
  - `/native/claims`
  - `/native/claims/:id`
  - `/native/claims/:id/capture`
  - `/native/submissions/:id/review`
- **D-06:** Exactly one route in the lane is `:native_screen`: `/native/claims/:id/capture`.
- **D-07:** The surrounding routes stay Phoenix-owned `:live_view` routes. No second native route, no hidden native fallback, and no generic top-level `/camera` demo route as the public exemplar shape.
- **D-08:** Use nested capture (`/native/claims/:id/capture`) instead of a flat `/native/capture` route so the ownership boundary stays explicit in the URL and does not depend on hidden app state.
- **D-09:** The module and router shape should mirror the existing SaaS lane pattern with a dedicated `CrosswakeExample.SelectiveNative.*` namespace and its own `live_session :selective_native`.

### Pack posture and activation gating
- **D-10:** Use context-dependent pack gating. Only the native capture route should require a pack gate; surrounding Phoenix routes should remain usable without that pack being installed.
- **D-11:** The capture route should declare a route-local required pack and fail closed when the pack is unavailable or incompatible.
- **D-12:** The primary degraded-path vocabulary for this lane is `pack_incompatible`.
- **D-13:** The exemplar must prove both pack-ready and pack-blocked capture activation paths in docs and proof lanes.
- **D-14:** Do not make the whole lane pack-gated, and do not downplay packs enough that Phase 8 stops pressuring `NATIVE-02`.

### Native handoff and submission shape
- **D-15:** The native route should return one staged local artifact to Phoenix, not a multi-artifact draft set, metadata bundle contract, or immediate server submission.
- **D-16:** The intended flow is: Phoenix claim detail -> native capture -> Phoenix review -> explicit `transfer.upload.prepare`.
- **D-17:** `captured locally`, `staged`, `uploaded`, and `reviewed/submitted` are distinct states and must stay visibly distinct in docs, fixtures, and proof.
- **D-18:** Phoenix owns review, submission intent, and any metadata edits. Native owns only the capture step and local staging needed for the explicit handoff.
- **D-19:** Do not imply background upload completion, resumable transfer guarantees, or app-local draft workflows in this phase.

### Security, sensitivity, and review posture
- **D-20:** The lane should use a narrow sensitive corridor rather than marking the entire `/native` lane sensitive.
- **D-21:** Ordinary surrounding routes such as `/native/claims` and `/native/claims/:id` should stay `security: :standard`.
- **D-22:** The native capture route and the immediate review route should be `security: :sensitive`.
- **D-23:** Review must happen before `transfer.upload.prepare`. No auto-upload and no upload-before-review shortcut.
- **D-24:** User-facing posture should stay plain and explicit: captured media is local to the device until the user reviews and confirms upload.
- **D-25:** Failures should stay route-local and fail-closed. Do not broaden the lane into a generic permission or media broker.

### Phoenix and ecosystem idiomaticity
- **D-26:** Keep the Phoenix-owned parts idiomatic: router scope + `live_session`, small bounded fixtures, LiveView list/detail/review surfaces, and Ecto-backed claim/submission state.
- **D-27:** Keep the native-owned part idiomatic to the existing Crosswake substrate: one manifest-declared `:native_screen`, one route-local pack requirement, one explicit transfer seam, one stable denial vocabulary.
- **D-28:** Learn from Hotwire Native’s discipline: most screens remain web-owned, native screens get explicit route ownership, and the bridge does not become a generic workflow bus.
- **D-29:** Learn from Expo/Capacitor and platform-native capture APIs that local media selection/capture should yield local artifacts first, not imply automatic upload or entitlement success.
- **D-30:** Keep DX explicit and unsurprising. Example-host code should read like a clean Phoenix slice plus one disciplined native seam, not like a framework demo or plugin showcase.

### Tradeoffs accepted
- **D-31:** Accept a narrower single-artifact flow because it keeps the selective-native story crisp and avoids Phase 9-style offline draft semantics.
- **D-32:** Accept that the capture route pressures pack readiness and fail-closed activation more than broad media lifecycle realism.
- **D-33:** Accept that the lane proves one canonical selective-native posture rather than multiple alternative native patterns in the same phase.

### Decision delegation posture
- **D-34:** Shift normal implementation decisions left within GSD for this phase. Downstream agents should not re-ask about the product slice, route map, pack posture, single-artifact handoff, or sensitive-corridor review flow unless a proposal would materially change the Phase 8 pressure target.

### the agent's Discretion
- Exact fixture names, sample claim nouns, and seeded copy, as long as the domain stays generic and claims/evidence-oriented.
- Exact route ids and module boundaries beneath `CrosswakeExample.SelectiveNative.*`, as long as there is exactly one `:native_screen` route and the four-route lane shape stays intact.
- Exact pack identifier and staged-artifact metadata fields, as long as the capture route alone owns the pack gate and explicit `transfer.upload.prepare` handoff.
- Exact proof assertions, docs structure, and UI copy, as long as `pack_incompatible`, staged-before-upload truth, and the fail-closed native boundary stay explicit.

### Deferred Ideas (OUT OF SCOPE)
- Billing or paywall native routes, StoreKit/Play Billing, receipt verification, and entitlement sync
- Barcode/NFC scanner flows, fraud-sensitive check-in semantics, or scanner-specific capability expansion
- OCR, receipt parsing, document scanning, or richer media-processing features
- Multi-artifact draft sets, app-local offline draft workflows, or Phase 9-style reconciliation semantics
- Background upload guarantees, resumable transfers, or generic app-wide media-transfer management
- Multiple native-screen families inside the same exemplar lane
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NATIVE-01 | Phoenix teams can run a selective-native exemplar flow that moves one device-heavy or entitlement-adjacent route into explicit native ownership while surrounding routes remain Phoenix-owned. | Add one `CrosswakeExample.SelectiveNative.*` lane under `/native` with exactly four routes, exactly one `:native_screen` route, and one dedicated `live_session :selective_native` that mirrors the existing SaaS lane structure. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| NATIVE-02 | The selective-native exemplar uses declared pack, transfer, and capability seams rather than ad hoc container behavior. | Reuse the existing native-escape, transfer, compatibility, and denial substrate so the capture route alone declares the required pack, returns one staged local artifact, and hands off to explicit `transfer.upload.prepare` after Phoenix review. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/packs.md] [VERIFIED: guides/bridge.md] [VERIFIED: guides/native_shell.md] |
</phase_requirements>

## Summary

Phase 8 should be planned as a targeted migration from the generic Phase 5 `/camera` demo surface to a product-shaped `/native` claims-evidence lane inside the existing shared example host, not as a new abstraction layer and not as a new sample app. The repo already has the needed substrate: public runtime taxonomy, route-local pack and transfer declarations, a single public native-escape contract, fail-closed `pack_incompatible` denials, the shared example-host artifact class, and a proven lane pattern in `CrosswakeExample.SaaSPortal.*`. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: test/crosswake/proof/phase7_saas_lane_test.exs]

The main planning job is therefore decomposition, not invention. Phase 8 should establish the `/native` lane shape and bounded fixtures first, then replace the public generic capture story with the locked nested capture story, then extend proof so the checked-in hosts assert exactly one native route plus both pack-ready and pack-blocked activation paths, and finally refresh the adopter/profile/install/native-shell docs so the public story matches the implementation. That sequence preserves the project thesis that Phoenix owns the surrounding flow while native owns one narrow device-heavy step. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

One planning risk is already visible: Phase 8 context calls for Ecto-backed claim/submission state, but the current repo dependency baseline is still `phoenix`, `phoenix_live_view`, `jason`, and `nimble_options` only. The planner should either keep Phase 8’s state layer narrowly example-host-scoped if Ecto is added, or explicitly surface a decision update before execution if that part of the locked context needs to be relaxed. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Primary recommendation:** Plan Phase 8 in four slices: lane skeleton and router truth, native capture plus staged-review-upload handoff, proof-host and manifest assertions, then adopter-facing guide and rough-edge updates. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: script/verify_phase5_example_hosts.sh]

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` file exists in the repo root, so there are no additional project-local directives beyond `AGENTS.md` and the `.planning/*` artifacts. [VERIFIED: filesystem check in repo root on 2026-05-18]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `/native/claims` queue and `/native/claims/:id` detail truth | API / Backend | Browser / Client | The surrounding selective-native routes are locked to remain Phoenix-owned `:live_view` routes, so claim listing and detail should stay ordinary server-owned LiveViews. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| `/native/claims/:id/capture` activation and device capture | Browser / Client | API / Backend | The capture route is the only route that moves to `:native_screen`, and the shell already owns native escape execution and fail-closed activation. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/native_shell.md] |
| Pack readiness and denial posture for capture | Browser / Client | API / Backend | Shell activation enforces installed-pack compatibility, but the manifest and route declaration stay Phoenix-authored. [VERIFIED: guides/packs.md] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/denial.ex] |
| Staged local artifact handoff and `transfer.upload.prepare` declaration | API / Backend | Browser / Client | Phoenix declares the transfer seam and review boundary, while the shell returns local staged capture data and waits for explicit upload preparation. [VERIFIED: guides/bridge.md] [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] |
| `/native/submissions/:id/review` review-before-upload boundary | API / Backend | Browser / Client | The review route is locked to be Phoenix-owned and sensitive, and LiveView authz/on-mount checks remain the right place for route-local review semantics. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Shared example-host proof, docs alignment, and support posture | API / Backend | Browser / Client | The repo’s public proof class is the checked-in host plus paired shells, and docs must route support status back to the existing support/install surfaces. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: script/verify_phase5_example_hosts.sh] [VERIFIED: guides/support_matrix.md] [VERIFIED: guides/install.md] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir | `~> 1.19` in `mix.exs`, `Mix 1.19.5` locally | Compile the route-policy, manifest, proof, and example-host surfaces. [VERIFIED: mix.exs] [VERIFIED: `mix --version` on 2026-05-18] | This is the repo baseline and all existing Crosswake contract code already lives here. [VERIFIED: mix.exs] |
| Phoenix | `~> 1.8`, locked `1.8.7` in `mix.lock` | Router scopes, pipelines, and manifest source-of-truth host behavior. [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Phase 8 is explicitly Phoenix-first and should extend router scopes instead of inventing a second routing system. [VERIFIED: .planning/PROJECT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://hexdocs.pm/phoenix/routing.html] |
| Phoenix LiveView | `~> 1.1`, locked `1.1.30` in `mix.lock` | Phoenix-owned queue/detail/review routes and route-local `live_session` boundaries. [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Official docs still recommend `live_session` plus `on_mount` for grouping LiveViews with shared authz boundaries, which matches the existing SaaS lane pattern and the locked `live_session :selective_native` direction. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| `Crosswake.Router` + policy/manifest pipeline | repo surface | Compile route-local runtime, pack, transfer, and security truth from Phoenix router declarations. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/manifest/validator.ex] | Phase 8 should reuse the existing declaration-first substrate rather than add an exemplar-only config channel. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| `Crosswake.NativeEscape.Contract` + `Crosswake.NativeEscape.Runtime` | repo surface | Single public native capture contract with explicit local staging and explicit transfer handoff. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] | The contract already encodes the exact Phase 8 truth: one native capture flow, `captured_local` before transfer, and denial when the route is not `:native_screen`. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] |
| `Crosswake.Compatibility`, `Crosswake.Shell.Denial`, and bounded bridge registry | repo surface | Fail-closed activation, route-local pack checks, and bounded `transfer.upload.prepare` exposure. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: lib/crosswake/bridge/contract.ex] | Phase 8 needs to pressure existing denial vocabulary and transfer seams, not widen the bridge. [VERIFIED: guides/bridge.md] [VERIFIED: guides/native_shell.md] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| ExUnit proof lane tests | repo surface | Lock route map, manifest shape, host README wording, and proof ordering. [VERIFIED: test/crosswake/proof/phase5_proof_lane_test.exs] [VERIFIED: test/crosswake/proof/phase7_saas_lane_test.exs] [VERIFIED: test/crosswake/proof/adopter_profile_contract_test.exs] | Use for all Phase 8 lane assertions before native-host verification hooks run. [VERIFIED: script/verify_phase5_example_hosts.sh] |
| Checked-in example hosts | repo surface | Public artifact class for Phoenix, iOS, and Android proof. [VERIFIED: guides/install.md] [VERIFIED: guides/support_matrix.md] | Use for exemplar proof and docs truth; do not replace them with a new sample app. [VERIFIED: examples/phoenix_host/README.md] |
| Existing shell fixtures and transfer coordinators | repo surface | Keep iOS and Android route activation, bridge command, and denial posture aligned with new `/native` route truth. [VERIFIED: examples/ios_shell_host/Fixtures/crosswake_manifest.json] [VERIFIED: examples/android_shell_host/app/src/main/assets/crosswake_manifest.json] [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] | Use when Phase 8 updates activation fixtures from the current SaaS default route to the selective-native route set or adds pack-blocked capture checks. [VERIFIED: test/crosswake/proof/phase5_proof_lane_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared host selective-native lane | A new standalone native-flow sample app | Reject it because the host README, Phase 6 contract, and Phase 7 proof posture all lock the shared example host as the public artifact class. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| Nested `/native/claims/:id/capture` route | A flat `/camera` or `/native/capture` route | Reject it because the locked Phase 8 context requires URL-visible ownership boundaries tied to claim context, not hidden app state or a generic demo path. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| Route-local capture pack gating | Whole-lane pack gating | Reject it because the lock is explicit that only the capture route must gate on the pack. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| Explicit staged -> review -> upload path | Auto-upload or background upload flow | Reject it because existing guides and the native-escape contract already separate captured-local from transferred state, and Phase 8 forbids hidden completion promises. [VERIFIED: guides/packs.md] [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
mix test test/crosswake/proof/phase5_proof_lane_test.exs test/crosswake/proof/adopter_profile_contract_test.exs test/crosswake/proof/phase7_saas_lane_test.exs
```
The repo already has the required Phase 8 substrate dependencies checked into `mix.exs` and `mix.lock`; no additional standard library recommendation is needed at research time. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix router scope "/native"
  -> crosswake_defaults runtime/offline/security
  -> live_session :selective_native with on_mount/authz boundary
  -> LiveView claim queue (/native/claims)
  -> LiveView claim detail (/native/claims/:id)
       -> explicit navigation to capture route
  -> Native capture route (/native/claims/:id/capture)
       -> manifest-first activation
       -> required-pack check
          -> deny with pack_incompatible
          -> or open native capture screen
       -> local artifact staged
       -> native escape result state = captured_local
  -> LiveView review route (/native/submissions/:id/review)
       -> sensitive review + metadata confirmation
       -> explicit transfer.upload.prepare
       -> uploaded/submitted state remains distinct
  -> checked-in proof tests + shell fixtures + docs updates
```
This is the narrowest architecture that satisfies the locked route map while reusing the current Crosswake capture substrate. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/bridge.md]

### Recommended Project Structure

```text
examples/phoenix_host/lib/crosswake_example/
├── router.ex
├── selective_native/
│   ├── fixtures.ex
│   ├── claims.ex
│   ├── submissions.ex
│   ├── on_mount.ex
│   ├── claims_live.ex
│   ├── claim_live.ex
│   └── review_live.ex
└── saas_portal/
    └── ...existing lane...

test/crosswake/proof/
├── phase5_proof_lane_test.exs
├── phase7_saas_lane_test.exs
└── phase8_selective_native_lane_test.exs
```
This mirrors the existing SaaS lane organization and keeps profile isolation inside the shared host artifact class. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal] [VERIFIED: examples/phoenix_host/README.md]

### Pattern 1: Mirror Phase 7’s Lane Skeleton

**What:** Add a dedicated `/native` scope and `live_session :selective_native` with lane-local modules that match the SaaS exemplar’s namespace discipline. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]

**When to use:** Use this first, before any capture logic, so the selective-native flow has a falsifiable route map and proof target from the start. [VERIFIED: .planning/ROADMAP.md]

**Example:**
```elixir
# Source pattern: examples/phoenix_host/lib/crosswake_example/router.ex
scope "/native", CrosswakeExample.SelectiveNative do
  pipe_through [:browser]

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    live_session :selective_native,
      on_mount: [{CrosswakeExample.SelectiveNative.OnMount, :mount_lane}] do
      live "/claims", ClaimsLive,
        crosswake: [id: "native-claims"]

      live "/claims/:id", ClaimLive,
        crosswake: [id: "native-claim"]

      live "/claims/:id/capture", ClaimCaptureLive, :capture,
        crosswake: [
          id: "native-claim-capture",
          runtime: :native_screen,
          security: :sensitive
        ]

      live "/submissions/:id/review", ReviewLive,
        crosswake: [id: "native-submission-review", security: :sensitive]
    end
  end
end
```

### Pattern 2: Keep Capture-Owned Transfer Declarations On The Native Route

**What:** Declare the upload seam on the capture route and let the native-escape runtime emit a `captured_local` result plus a transfer handoff, then let the review route explicitly invoke `transfer.upload.prepare`. [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/bridge.md] [VERIFIED: guides/packs.md]

**When to use:** Use whenever the native route stages a local artifact but Phoenix still owns review and submission intent. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

**Example:**
```elixir
# Source pattern: lib/crosswake/native_escape/runtime.ex
crosswake: [
  id: "native-claim-capture",
  runtime: :native_screen,
  packs: [[id: :claims_capture_assets, version: "1.0.0", kind: :media]],
  transfers: [
    [
      id: :claim_evidence_upload,
      intent: :upload,
      source: :native_capture,
      verification: :required,
      media_types: ["image/*"]
    ]
  ],
  security: :sensitive
]
```

### Pattern 3: Extend The Existing Proof Entry Point, Don’t Fork It

**What:** Add Phase 8 assertions to `script/verify_phase5_example_hosts.sh` and companion proof tests instead of creating a phase-specific standalone script. [VERIFIED: script/verify_phase5_example_hosts.sh] [VERIFIED: test/crosswake/proof/phase5_proof_lane_test.exs]

**When to use:** Use for manifest route-map checks, README/guide wording checks, shell fixture alignment, and pack-ready/pack-blocked path assertions. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: test/crosswake/proof/adopter_profile_contract_test.exs]

### Anti-Patterns to Avoid

- **Generic `/camera` demo persistence:** Do not keep the public selective-native story centered on the root-level `/camera` route once the `/native` lane lands. That route is Phase 5 substrate proof, not the locked Phase 8 exemplar shape. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]
- **Bridge-as-workflow-bus:** Do not use the bounded bridge to coordinate claim review, navigation, or submission authority. The bridge is intentionally limited to semantic commands and denies undeclared work. [VERIFIED: guides/bridge.md] [VERIFIED: lib/crosswake/bridge/registry.ex]
- **Whole-lane sensitivity or pack gating:** Do not mark all `/native` routes sensitive or pack-gated; the lock is a narrow sensitive corridor and route-local pack truth. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]
- **Upload-before-review semantics:** Do not treat local capture as uploaded or submitted. Existing docs already distinguish `staged` from transferred, and Phase 8 explicitly preserves that difference. [VERIFIED: guides/packs.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]
- **Proof sprawl:** Do not add a second proof harness or publish support claims in Phase 8 docs. Support status still belongs in `guides/support_matrix.md` and proof entry still belongs in `guides/install.md`. [VERIFIED: guides/support_matrix.md] [VERIFIED: guides/install.md]

## Concrete Plan Decomposition

### Plan 08-01: Establish The `/native` Lane Skeleton

**Scope:** Add `CrosswakeExample.SelectiveNative.*` modules, the four locked routes, `live_session :selective_native`, and minimal claim/submission fixtures. Preserve the existing root-level Phase 5 substrate routes until Phase 8 proof replaces their public role. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex]

**Why first:** The planner needs a route-truth anchor before capture logic, shell fixtures, or docs can update coherently. [VERIFIED: test/crosswake/proof/phase7_saas_lane_test.exs]

### Plan 08-02: Implement Native Capture And Review Handoff

**Scope:** Move the public native-capture story onto `/native/claims/:id/capture`, declare one route-local required pack, stage one local artifact, keep review and metadata edits in Phoenix, and gate upload behind explicit `transfer.upload.prepare`. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/bridge.md]

**Why second:** This slice pressures `NATIVE-02` directly while staying inside the already-proven Phase 5 substrate. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/05-packs-native-escape-and-proof-lanes/05-RESEARCH.md]

### Plan 08-03: Extend Proof And Shell Fixture Alignment

**Scope:** Add a `phase8_selective_native_lane_test.exs`, update manifest/activation fixture assertions, and extend `script/verify_phase5_example_hosts.sh` so proof covers exactly one native route, route-local pack gating, `pack_incompatible` denials, and staged-before-upload truth. [VERIFIED: script/verify_phase5_example_hosts.sh] [VERIFIED: test/crosswake/proof/phase5_proof_lane_test.exs] [VERIFIED: test/crosswake/proof/adopter_profile_contract_test.exs]

**Why third:** Crosswake’s support posture is proof-backed; the public lane is not real until the checked-in hosts and tests agree on it. [VERIFIED: .planning/PROJECT.md] [VERIFIED: guides/install.md] [VERIFIED: guides/support_matrix.md]

### Plan 08-04: Refresh Public Guides And Rough-Edge Truth

**Scope:** Update `guides/adopter_profiles.md`, `examples/phoenix_host/README.md`, `guides/packs.md`, `guides/native_shell.md`, and `guides/install.md` so they describe the locked `/native` claims-evidence lane, point back to existing support-status surfaces, and explicitly call out pack-blocked capture plus review-before-upload truth. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: guides/packs.md] [VERIFIED: guides/native_shell.md] [VERIFIED: guides/install.md]

**Why fourth:** Current public selective-native wording still uses the older generic route story, so docs must be brought back into alignment after proof and host code stabilize. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Selective-native routing | A second exemplar-specific route registry | The existing Phoenix router + `Crosswake.Router` metadata path | Router introspection, manifest compilation, and proof already flow from Phoenix routes today. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: test/crosswake/router_test.exs] [CITED: https://hexdocs.pm/phoenix/routing.html] |
| Native capture workflow | A new plugin or generic media broker | `Crosswake.NativeEscape.Contract` and `Crosswake.NativeEscape.Runtime` | The repo already exposes one public native escape hatch with explicit local staging and transfer handoff. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/native_escape/runtime.ex] |
| Review boundary | Native-owned submission authority | Phoenix LiveView review route plus explicit upload preparation | Phase 8 explicitly keeps review and submission intent Phoenix-owned. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| Pack failure vocabulary | A new capture-specific denial taxonomy | Existing `pack_incompatible` posture | Compatibility tests and shell fixtures already center pack denials on that reason. [VERIFIED: test/crosswake/compatibility/compatibility_test.exs] [VERIFIED: examples/ios_shell_host/Fixtures/route_denial.json] [VERIFIED: examples/android_shell_host/app/src/main/assets/route_denial.json] |
| Proof workflow | A Phase 8-only verification script | Extend `script/verify_phase5_example_hosts.sh` and proof tests | The shared proof entrypoint is already the locked public artifact contract. [VERIFIED: script/verify_phase5_example_hosts.sh] [VERIFIED: examples/phoenix_host/README.md] |

**Key insight:** Phase 8 succeeds by recontextualizing the existing native-capture substrate into a believable Phoenix-owned product corridor, not by broadening Crosswake’s native surface area. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Leaving The Public Story Split Between `/camera` And `/native`

**What goes wrong:** The code grows a new `/native` lane, but guides and tests still present the generic `/camera` route as the selective-native exemplar. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md]

**Why it happens:** Phase 5 already proved capture substrate, so it is easy to add Phase 8 beside it without retiring the older public wording. [VERIFIED: test/crosswake/proof/phase5_proof_lane_test.exs]

**How to avoid:** Treat Plan 08-04 as required product work, not cleanup, and update the README/guide representative routes in the same phase as proof. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

**Warning signs:** `guides/adopter_profiles.md` or `examples/phoenix_host/README.md` still list `/camera` or `/native/capture` after implementation. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md]

### Pitfall 2: Capture Success Quietly Implies Upload Success

**What goes wrong:** UI copy, fixtures, or tests collapse `captured_local`, review-ready, upload-prepared, and submitted into one success state. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: guides/packs.md]

**Why it happens:** The flow is narrow, so implementers may shortcut terminology to make the demo feel smoother. [ASSUMED]

**How to avoid:** Keep staged state names explicit in fixtures, LiveView copy, and proof assertions, and assert review happens before `transfer.upload.prepare`. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: guides/bridge.md]

**Warning signs:** Tests only assert “uploaded” or “submitted” after the native route returns without checking the review route. [ASSUMED]

### Pitfall 3: The Capture Route Becomes A Generic Permission Broker

**What goes wrong:** Route-local camera capture expands into app-wide permission, media, scanner, or entitlement coordination. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

**Why it happens:** The selective-native lane is adjacent to device APIs, and generic capability growth looks tempting once a native route exists. [VERIFIED: guides/bridge.md]

**How to avoid:** Keep the native route bound to one pack, one artifact, one upload seam, and one stable denial vocabulary. [VERIFIED: lib/crosswake/native_escape/runtime.ex] [VERIFIED: guides/packs.md]

**Warning signs:** New commands or route-local copy mention scanner, OCR, entitlement, or background upload behavior. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

### Pitfall 4: Planner Ignores The Current Dependency Gap Around Ecto

**What goes wrong:** The plan assumes Ecto-backed claim/submission state is free, but the current repo does not yet carry Ecto dependencies or a Phoenix example-host repo layer. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: mix.exs]

**Why it happens:** The locked context asks for Phoenix idiomaticity, while the present repo example-host code is fixture-driven and dependency-light. [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex] [VERIFIED: mix.exs]

**How to avoid:** Put the dependency decision in Wave 0 of planning or explicitly constrain the Phase 8 state layer to the shared example-host only. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

**Warning signs:** Early tasks mention claims/submissions tables or repos without any prior dependency or example-host persistence step. [ASSUMED]

## Code Examples

Verified patterns from repo and official docs:

### Lane-Scoped LiveView Boundary
```elixir
# Source pattern:
# - examples/phoenix_host/lib/crosswake_example/router.ex
# - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
scope "/native", CrosswakeExample.SelectiveNative do
  pipe_through [:browser]

  live_session :selective_native,
    on_mount: [{CrosswakeExample.SelectiveNative.OnMount, :mount_lane}] do
    live "/claims", ClaimsLive
    live "/claims/:id", ClaimLive
    live "/claims/:id/capture", ClaimCaptureLive, :capture
    live "/submissions/:id/review", ReviewLive
  end
end
```

### Native Escape Result Shape
```elixir
# Source: lib/crosswake/native_escape/runtime.ex
{:ok, result} =
  Crosswake.NativeEscape.Runtime.capture_local(
    request,
    local_capture,
    declared_transfers
  )

assert result.state == :captured_local
assert result.transfer_handoff.transfer_intent == :upload
```

### Proof-Lane Manifest Assertion
```elixir
# Source pattern: test/crosswake/proof/phase7_saas_lane_test.exs
assert {:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(CrosswakeExample.Router)

native_routes =
  manifest.routes
  |> Enum.filter(fn {_id, route} -> String.starts_with?(route.path, "/native") end)
  |> Enum.into(%{})

assert native_routes["native-claim-capture"].runtime == :native_screen
assert Enum.count(native_routes, fn {_id, route} -> route.runtime == :native_screen end) == 1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Phase 5 public capture proof centered on `/camera` and a substrate-level `camera` route | Adopter-shaped Phase 8 selective-native lane centered on `/native/claims/:id/capture` with surrounding Phoenix routes | Phase 8 context locked on 2026-05-18 | The public exemplar must become product-shaped without widening the underlying substrate. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| Generic selective-native representative routes in `guides/adopter_profiles.md` and `examples/phoenix_host/README.md` | Locked four-route claims-evidence lane under `/native` | Phase 8 context locked on 2026-05-18 | Docs and proof need synchronized updates so adopter-facing guidance matches the locked exemplar. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |
| Phase 7 proof extends shared hosts with a SaaS lane only | Phase 8 should layer a second lane-specific proof without changing the base proof entrypoint | Phase 7 completed on 2026-05-18; Phase 8 planned next | The proof workflow should grow by lane assertions, not by new harnesses. [VERIFIED: .planning/STATE.md] [VERIFIED: script/verify_phase5_example_hosts.sh] |

**Deprecated/outdated:**
- Treating the generic `/camera` route as the public `Selective Native Flow` exemplar is outdated once Phase 8 lands. The Phase 5 route remains useful substrate proof, but not the canonical adopter-shaped lane. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | UI/state naming shortcuts are a likely implementer temptation in this phase. [ASSUMED] | Common Pitfalls | Low; it only affects wording emphasis, not architecture. |
| A2 | Early implementation may try to reference tables/repos before resolving the Ecto dependency question. [ASSUMED] | Common Pitfalls | Medium; planning order could break if persistence scope is not decided first. |

## Open Questions (RESOLVED)

1. **How literal should the locked “Ecto-backed claim/submission state” decision be in Phase 8 execution?**
   - Resolution: Treat D-26 literally, but keep the scope narrow. Phase 8 should add an example-host-only Ecto-backed claim and submission slice, backed by a small local SQLite repo under `examples/phoenix_host`, and must not widen the root `crosswake` application into a persistence surface. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/config/config.exs]
   - Why this resolves the risk: It satisfies the locked context, keeps the exemplar product-shaped, and preserves the project thesis that Crosswake core owns route/runtime contracts rather than app persistence. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md]
   - Planning consequence: The first execution slice must explicitly include example-host Ecto wiring, repo/application setup, claim/submission schemas, and minimal migration or seed support before later LiveView, shell-proof, and doc work depends on that state boundary. [VERIFIED: examples/phoenix_host/mix.exs] [VERIFIED: examples/phoenix_host/config/config.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Repo-local proof and tests | ✓ | `Mix 1.19.5` | — [VERIFIED: `mix --version` on 2026-05-18] |
| `xcodebuild` | Checked-in iOS host verification | ✓ | `Xcode 26.0.1` | — [VERIFIED: `xcodebuild -version` on 2026-05-18] |
| Java runtime | Android host verification | ✗ | — | None for running Android proof locally. [VERIFIED: `java -version` on 2026-05-18] |
| `adb` | Android connected/instrumented verification | ✗ | — | None for device/emulator-backed Android proof locally. [VERIFIED: `command -v adb` on 2026-05-18] |
| `sdkmanager` | Android SDK management | ✗ | — | None. [VERIFIED: `command -v sdkmanager` on 2026-05-18] |
| `gradle` | Android shell build/test workflow | ✗ | — | Generated Android shell self-bootstrap exists, but local proof still lacks the host tools above. [VERIFIED: .planning/STATE.md] [VERIFIED: `command -v gradle` on 2026-05-18] |

**Missing dependencies with no fallback:**
- Local Android proof execution is currently blocked by missing Java/ADB/SDK tooling. [VERIFIED: `java -version` on 2026-05-18] [VERIFIED: `command -v adb` on 2026-05-18] [VERIFIED: `command -v sdkmanager` on 2026-05-18]

**Missing dependencies with fallback:**
- None. Phase 8 planning can still rely on repo-local ExUnit proof and checked-in fixture updates before native-host execution is retried in a fully provisioned environment. [VERIFIED: script/verify_phase5_example_hosts.sh]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep Phoenix-owned route authz in plugs plus `live_session`/`on_mount`; LiveView docs explicitly require authz checks on mount because navigation inside a session skips the plug pipeline. [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V3 Session Management | yes | Keep session-backed Phoenix ownership for surrounding LiveViews and avoid moving session authority into the shell. [VERIFIED: .planning/phases/07-phoenix-saas-portal-exemplar/07-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex] |
| V4 Access Control | yes | Use route-local `security` metadata, fail-closed activation, and route-local review authorization instead of shell fallback. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: guides/native_shell.md] |
| V5 Input Validation | yes | Reuse typed route, transfer, and native-escape contracts rather than raw maps or ad hoc payloads. [VERIFIED: lib/crosswake/native_escape/contract.ex] [VERIFIED: lib/crosswake/bridge/contract.ex] |
| V6 Cryptography | no | No new crypto surface is implied by the locked Phase 8 lane. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] |

### Known Threat Patterns for Crosswake selective-native flow

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Route activation opens the wrong runtime | Spoofing | Keep manifest-first activation and fail closed to `route unavailable` or `pack_incompatible` before any web container loads. [VERIFIED: guides/native_shell.md] |
| Native capture result is treated as uploaded without review | Tampering | Preserve the explicit state split between local capture, review, upload preparation, and submission. [VERIFIED: guides/packs.md] [VERIFIED: lib/crosswake/native_escape/contract.ex] |
| Bridge command is used outside the active route | Elevation of privilege | The bounded bridge already checks active route, manifest route, origin, capability, and pack posture before any side effect. [VERIFIED: guides/bridge.md] |
| Review-route authz relies only on router grouping | Elevation of privilege | LiveView docs require mount/action checks in addition to plug pipeline protection. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |

## Sources

### Primary (HIGH confidence)
- Local repo artifacts reviewed on 2026-05-18: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md`, Phase 5 research/UI-spec, Phase 6 and 7 context, guides, example-host router/README, proof scripts/tests, `mix.exs`, `mix.lock`, and native escape/bridge/compatibility modules. [VERIFIED: local filesystem reads]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html - `live_session` behavior and scope caveats. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]
- https://hexdocs.pm/phoenix_live_view/security-model.html - mount/authz requirements and `live_session` boundaries. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- https://hexdocs.pm/phoenix/routing.html - Phoenix scope/pipeline behavior. [CITED: https://hexdocs.pm/phoenix/routing.html]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: source audit in this session]

### Tertiary (LOW confidence)
- None beyond the explicit `[ASSUMED]` entries called out in the assumptions log. [VERIFIED: source audit in this session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo dependencies, lockfile versions, router/tests, and official Phoenix docs align. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/phoenix/routing.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]
- Architecture: HIGH - the locked Phase 8 context is unusually specific and fits existing substrate cleanly. [VERIFIED: .planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md] [VERIFIED: lib/crosswake/native_escape/runtime.ex]
- Pitfalls: MEDIUM - most are directly visible from current doc/proof drift, but the Ecto-execution risk still needs a planner decision. [VERIFIED: guides/adopter_profiles.md] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: mix.exs]

**Research date:** 2026-05-18 [VERIFIED: system date]
**Valid until:** 2026-06-17 for repo-local planning assumptions unless locked context or dependency baseline changes first. [ASSUMED]
