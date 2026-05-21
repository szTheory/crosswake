# Crosswake Support Matrix

This guide stays narrow and proof-oriented. The published iOS and Android shell claims
below are backed by the checked-in example hosts plus the generated-shell verification
hooks that now pass on the same host-owned artifact classes adopters ship.

## Status Legend

- supported
- verification required
- unsupported

## Phoenix

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| phoenix | ~> 1.8 | supported | phase-2-proof-lane | - | Phoenix host install and manifest generation are the stable baseline. |

## LiveView

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| phoenix_live_view | ~> 1.1 | supported | phase-2-proof-lane | [View Boundaries](offline.md#boundary-warnings--rough-edges) | LiveView remains server-owned and route-first. |

## iOS

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| ios | 17.0 | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned iOS shell boot is proof-backed by the checked-in example host and generated-shell verification hook. |

## Android

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| android | 26 | supported | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned Android shell boot is proof-backed by the checked-in example host and generated-shell verification hook. |

## Shell Artifacts

| Target | Version | Status | Proof | Boundaries | Notes |
|--------|---------|--------|-------|------------|-------|
| ios_shell | 0.1.0 | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated iOS shell artifacts are supported while the Phase 5 iOS verification hook stays green. |
| android_shell | 0.1.0 | supported | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated Android shell artifacts are supported while the Phase 5 Android verification hook stays green. |

## Capability Families

| Family | Owner | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |
|--------|-------|---------|-------|---------|---------------|--------|----------|-------|
| app_info | bounded_bridge | core | merge-blocking | none | declared route capability; bounded bridge support | undeclared_capability | Phoenix route continues without native app metadata | [Guide](bridge.md#bounded-bridge) |
| deep_link | bounded_bridge | core | merge-blocking | none | bundled or cached manifest; shell activation support; explicit route entry approval | route_unavailable | show route unavailable surface that distinguishes inactive routes from routes that reject external entry | [Guide](native_shell.md#manifest-first-activation) |
| document_scan | native_screen | defer | advisory | companion-required | document-scan runtime; policy-heavy proof lane | unavailable_capability | defer document scan support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
| entitlement_snapshot | backend_seam | core | merge-blocking | companion-required | backend entitlement authority; reconciliation hook | unavailable_capability | treat device-side state as evidence instead of final entitlement truth | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| haptics | bounded_bridge | core | merge-blocking | none | declared route capability; bounded bridge support | undeclared_capability | Phoenix route continues without native confirmation feedback | [Guide](bridge.md#bounded-bridge) |
| media_capture | native_screen | companion | merge-blocking | native-required | native screen route; capture pack availability | pack_incompatible | fail closed instead of degrading into a bounded web upload flow | [Guide](native_shell.md#native-capture-escape-hatch) |
| notification_token | bounded_bridge | companion | advisory | companion-required | declared route capability; bounded bridge support; notification authorization already resolved; provider token snapshot available | unavailable_capability | treat notification token replies as provider-tagged evidence instead of backend registration truth | [Guide](capabilities.md#bounded-bridge) |
| paywall_entry | backend_seam | core | merge-blocking | companion-required | backend entitlement contract; storefront guidance | unavailable_capability | fall back to Phoenix-owned paywall guidance without device authority | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| permissions.status | bounded_bridge | core | merge-blocking | none | declared route capability; bounded bridge support; notifications alias only | undeclared_capability | route continues without native notification permission snapshot authority | [Guide](capabilities.md#bounded-bridge) |
| purchase_intent | backend_seam | core | merge-blocking | companion-required | backend reconciliation; provider-specific adapter | unavailable_capability | treat purchase events as reconciliation inputs, not entitlement truth | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| reconciliation_evidence | backend_seam | core | merge-blocking | companion-required | backend reconciliation; device callback or webhook | unavailable_capability | treat evidence as asynchronous payload without blocking route entry | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| restore_intent | backend_seam | core | merge-blocking | companion-required | backend reconciliation; storefront-aware adapter | unavailable_capability | keep restore flow backend-owned until adapter truth is explicit | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| scanner | native_screen | defer | advisory | companion-required | scanner-native runtime; policy-heavy proof lane | unavailable_capability | defer scanner support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
| share | bounded_bridge | core | advisory | none | truthful semantic share contract | unavailable_capability | keep content in the Phoenix-owned route until a share seam is declared | [Guide](capabilities.md#bounded-bridge) |

## Packaging Ledger

`crosswake` remains the one primary public package. Companions are first-party-scoped typed boundaries, not plugin-market surfaces.

| Surface | Class | Why | Release Burden | Public Guide |
|---------|-------|-----|----------------|--------------|
| `crosswake` primary package | core | Route-policy DSL, manifest contract, compatibility axes, bounded-bridge vocabulary, shell generators, doctor, support matrix, release rules, and proof posture stay in one obvious Phoenix-first package. | Hex package SemVer moves independently, while support truth still follows manifest_schema_version, bridge_protocol_version, and native_runtime_version. | [Guide](install.md#package-surface) |
| Phoenix-facing commerce seam vocabulary | core | `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` stay normalized and backend-truthful in core without embedding storefront providers. | Semantics may evolve in core, but provider adapters and native storefront logic remain outside the base package. | [Guide](capabilities.md#packaging-ledger) |
| Provider adapters and native-heavy integrations | companion | Storefront adapters, media/upload/capture, rollout, auth/session, notifications, and audit/operator seams carry native binary churn or backend coupling beyond core. | First-party companions declare minimum compatible ranges against core, compatibility axes, and capability-family majors. | [Guide](compatibility.md#companion-compatibility-contract) |
| Checked-in example hosts and install walkthroughs | example/docs-only | Examples, walkthroughs, reviewer playbooks, and vendor recipes teach boundaries and proof posture without becoming separate runtime packages. | Not first-class supported as package surfaces; promotion requires reclassification plus proof and support-matrix updates. | [Guide](capabilities.md#docs-only-boundary) |
| Standalone public shell packages | defer | Separately versioned shell artifacts stay deferred until release choreography and compatibility policy are mature enough to support them honestly. | No first-class package commitment yet; any future promotion must land with runtime-line rules and rebuild guidance. | [Guide](compatibility.md#runtime-line-rules) |

## Release And Versioning Policy

package versions alone do not define support truth.

| Target | Versioning | Compatibility Contract | Release Rule |
|--------|------------|------------------------|--------------|
| core | Independent SemVer for the `crosswake` Hex package. | package versions alone do not define support truth; manifest_schema_version, bridge_protocol_version, and native_runtime_version stay canonical. | Manifest-major, bridge-major, and runtime-line changes must update support docs and doctor before release. |
| companion | Independent SemVer per first-party companion. | Each companion declares minimum compatible ranges for core, all three compatibility axes, and exposed capability-family majors. | Companion support cannot expand until the adapter publishes explicit compatibility ranges and fail-closed guidance. |
| ios_shell | Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |
| android_shell | Platform artifact build numbers may differ, but the shell publishes against the shared native runtime line. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |

## Change Classes

| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |
|--------------|--------------|----------------|----------------------|----------------|
| docs-only | Guides, wording, examples, support notes, or advisory docs changed without changing manifest semantics, compatibility-axis values, capability versions, shell templates, companion code, or proof expectations. | Read the updated guidance and rerun docs integrity only. | No compatibility-axis or capability-version change. | docs integrity only |
| core-only/no native rebuild | Core Elixir behavior, docs generation, doctor, support rendering, or validation changed inside the already-supported schema, bridge, runtime, and capability versions. | Update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells. | Existing manifest_schema_version, bridge_protocol_version, native_runtime_version, and capability majors stay in line. | core contract + doctor/support proof |
| compatibility-bump only | Compatibility declarations or package windows narrowed so some older combinations now fail closed, but a fresh binary is not automatically required for already-compatible adopters. | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | manifest_schema_version, bridge_protocol_version, native_runtime_version, or capability required-version declarations changed support windows. | fail-closed compatibility fixtures |
| native or companion rebuild required | Native code, generated shell projects, entitlements, permissions, platform config, native dependencies, or companion-native integration code changed. | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | Every rebuild-required change carries explicit compatibility declarations, especially native_runtime_version, bridge_protocol_version, manifest_schema_version, and capability required-version shifts. | core proof plus generated-shell or companion verification lanes |
