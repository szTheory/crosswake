# Crosswake Support Matrix

This guide stays narrow and proof-oriented. Generated-shell coordinate support is
backed by release-time clean-room proof plus generated-shell verification hooks.
The checked-in native hosts are `checked-in public-coordinate proof`; the explicit
maintainer path stays `local-dev proof` behind `--local`.
The default non-local generator path resolves native shell cores from `github.com/szTheory/crosswake-shell-core-ios`
and Maven Central `io.github.sztheory:crosswake-shell-core-android` at the Crosswake
Hex package version; the release-time clean-room proof promotes that path after the
coordinated cut.

## Support-Truth Label Legend

Use these labels literally. Each label says what the evidence proves and what it does not prove.

| Label | What it proves | What it does not prove |
|-------|----------------|------------------------|
| merge-blocking proof | Required deterministic proof that must pass before the claim can merge. | It does not prove every platform/device path or any unsupported owner class. |
| advisory evidence | Useful evidence that informs confidence but does not block standard merge flow. | It does not widen support truth by itself. |
| checked-in public-coordinate proof | A checked-in host path resolves published SwiftPM/Maven coordinates by default. | It is not a device, simulator, or emulator support claim and it does not cover `--local`. |
| local-dev proof | A checked-in or local host path works for maintainers in this repository. | It is not generated public-coordinate proof. |
| generated public-coordinate proof | A generated adopter-facing path resolves published SwiftPM/Maven/Hex coordinates. | It does not prove checked-in local hosts use those coordinates. |
| JVM hermetic proof | Android logic passed deterministic JVM-level CI. | JVM hermetic proof is not emulator evidence or physical-device proof. |
| emulator evidence | A simulator or emulator run produced advisory platform evidence. | Emulator evidence is not physical-device proof. |
| device evidence | A physical-device run produced platform evidence. | Device evidence is not backend/session authority. |
| verification-required | A claim needs an explicit verification lane before it can be treated as supported. | It is not a failure-open support claim. |
| rebuild-required | A change touches native or companion surfaces that require rebuilding the host artifact. | It is not implied by docs-only or core-only/no native rebuild changes. |

Support status is not device evidence: `supported` is not the same as device-verified.
Visual collateral is not correctness proof by itself.
Device/provider evidence is not backend/session authority.
Cached read-only is not offline mutation.
Bridge is not high-frequency or mutation authority.

## Interaction-Class Legend

`manifest_schema_version` moved `1.0.0` -> `1.1.0` (Phase 154, CTRL-05/D-55): additive, native-inert — the iOS and Android shells decode neither the new `interaction` field nor the widened `Capability` enforce-keys, so this is `compatibility-bump only`, not rebuild-required.

Every capability declared in `Crosswake.Manifest.Builder.capability_catalog/0` now also declares an explicit `Capability.interaction` value alongside `Capability.rebuild`, enforced at compile time by `@enforce_keys`. Use these labels literally.

**Guarantee strength, stated honestly (D-45/D-52).** That `@enforce_keys` widening is the only part of the Phase 154 catalog line that is structurally impossible to violate: a capability declaring neither `interaction` nor `rebuild` does not compile, and no reviewer or CI job is involved. Every other part of the bounded-bridge contract is CI-caught rather than structural. `Crosswake.Bridge.CatalogGuard` is a merge-blocking structural test proving there is no dynamic-registration seam, no streaming seam, no external SDK inside the bridge tree, and native command enum parity in both directions — but a gate caught in CI is a gate a maintainer can still walk through deliberately, one honest control at a time. Read `guides/bridge.md#guarantee-strength-what-is-structural-and-what-is-ci-caught` before treating either as airtight.

| Interaction Class | What it means |
|--------------------|----------------|
| fire-and-forget | The bridge dispatches the command and the route continues without waiting on a completion payload. A request-acknowledgement payload (for example `share`'s `%{"outcome" => "requested"}`) does not change this — fire-and-forget means no completion is claimed, not that no payload is returned. |
| device-answer | The device autonomously answers with data — a snapshot or metadata read that does not require the user to make a choice. |
| user-answer | Completing the command requires an explicit user choice or action (for example picking a file) before a result exists. |

## Status Legend

- supported
- verification required
- unsupported

## Phoenix

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| phoenix | ~> 1.8 | supported | supported | phase-2-proof-lane | - | Phoenix host install and manifest generation are the stable baseline. |

## LiveView

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| phoenix_live_view | ~> 1.1 | supported | supported | phase-2-proof-lane | [View Boundaries](offline.md#boundary-warnings--rough-edges) | LiveView remains server-owned and route-first. |

## iOS

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| ios | 17.0 | supported | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | bounded iOS-only compiled topology, typed stack protocol, UIKit host composition, marker/insets, and generated host proof are verified in Phase 161.1; simulator advisory evidence remains distinct, TODO-002/adopter topology is unknown_blocking, and physical-iPhone promotion is Phase 162 only. |

## Android

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| android | 26 | supported | supported | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Android retains its frozen generator, Maven, JVM, and shared-vector posture. Checked-in Android host boot is `checked-in public-coordinate proof`; JVM hermetic CI evidence remains separate. Android is frozen during first adopter iOS readiness: no new feature, parity, device, template, or release claim. |

## Shell Artifacts

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| ios_shell | Hex-matched | supported | verification required | clean-room-proof-ios; script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Bounded iOS shell evidence excludes generic navigation, native leaf rendering, arbitrary restoration/modal breadth, and browser-history authority. Default non-local scaffolds resolve `https://github.com/szTheory/crosswake-shell-core-ios.git` via SwiftPM at the Crosswake package version; release-time clean-room proof confirms external resolution and `swift build`. advisory — not wired as a required CI lane; macOS/Xcode toolchain not guaranteed in CI. |
| android_shell | Hex-matched | supported | supported | native-behavioral-proof-gate / android-generated-shell-unit; script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated Android shell artifacts retain the frozen generator, Maven, JVM, and shared-vector posture based strictly on `JVM hermetic proof` via the merge-blocking android-generated-shell-unit CI lane (native-behavioral-proof-gate). JVM hermetic proof is not emulator evidence or physical-device proof. This existing posture is frozen during first adopter iOS readiness; no parity/device/template/release expansion is claimed. |

## First Adopter Readiness

The policy contract is policy-contract complete, while concrete adopter-instance input remains `unknown_blocking`. Known surface ownership is discovery context, not host or device proof. `unknown_blocking` blocks host-proof and physical-device promotion.

Example-host, simulator, package-version, and policy-contract evidence do not prove an external host or physical device. Route-local safety fields do not inherit from surface defaults. Cached read-only is not mutation, and one offline island does not claim generic sync.

| Surface | Current truth | Promotion evidence | Boundary |
|---------|---------------|--------------------|----------|
| host-reusable offline/shell proof | verification required | A generated host-owned scaffold runs against an external Phoenix router, real route/storage identifiers, existing browser tests, and the iOS shell flow. | Policy completion and example-host proof do not automatically transfer to a host application. |
| privacy-safe scoped replay | verification required | Opaque scope references, scope-partitioned outbox, logout/account-switch stops, endpoint reauthorization, and redacted evidence all pass. | The existing host-owned `gated_by` seam remains the server-side disablement authority; raw mutation payloads, account identifiers, media, transcripts, tokens, and stable device identifiers are never diagnostics. |
| foreground iOS pronunciation pack | verification required | A host provider downloads real bytes, verifies expected size and SHA-256, and atomically installs one immutable archive before reporting available. | Current timed native pack transitions are simulated lifecycle evidence, not productionized native content-pack storage. |
| physical-iPhone offline study | device evidence | A committed post-exit physical-device record supports one first adopter offline-study flow on one recorded iOS runtime line. | This device-evidence state is limited to one flow on one recorded iOS runtime line. It does not claim Android. It does not claim background replay or sync. It does not claim generic storage or sync. It does not claim multiple offline islands. It does not claim simulator substitution. It does not claim every iPhone. v20 is stopped/partial; it has no shipped support claim. |
| Android during first adopter readiness | advisory evidence frozen at current posture | Android is frozen at its existing generator, Maven, JVM, and shared-vector posture. | No new Android feature, parity, template, emulator/device, or release requirement is active. |

Generic sync is not claimed.

## Capability Families

| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |
|--------|-------|---------|----------|--------------|---------|-------|---------|---------------|--------|----------|-------|
| app_info | bounded_bridge | bounded_bridge | supported | verification required | core | merge-blocking | none | declared route capability; bounded bridge support | undeclared_capability | Phoenix route continues without native app metadata | [Guide](bridge.md#bounded-bridge) |
| deep_link | activation | activation_first | supported | supported | core | merge-blocking | none | bundled or cached manifest; shell activation support; explicit route entry approval | route_unavailable | show route unavailable surface that distinguishes inactive routes from routes that reject external entry | [Guide](native_shell.md#manifest-first-activation) |
| document_scan | native_screen | native_screen | unsupported | unsupported | defer | advisory | companion-required | document-scan runtime; policy-heavy proof lane | unavailable_capability | defer document scan support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
| entitlement_snapshot | backend_seam | backend_seam | supported | verification required | core | merge-blocking | companion-required | backend entitlement authority; reconciliation hook; freshness posture (fresh/stale/unknown) surfaced before access checks | unavailable_capability | Fail closed for access decisions when snapshot freshness is stale or unknown until refreshed backend authority is available; pending and awaiting_verification states never grant entitlement. | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| file_picker | bounded_bridge | transfer_backed | supported | verification required | core | merge-blocking | native-required | declared transfer_id; bounded bridge support; inbound native_picker transfer seam; copy-first staged handle plus transfer verification | undeclared_capability | keep the route on Phoenix-owned import guidance until a copy-first native_picker seam is declared and verified | [Guide](capabilities.md#bounded-bridge) |
| haptics | bounded_bridge | bounded_bridge | supported | verification required | core | merge-blocking | none | declared route capability; bounded bridge support | undeclared_capability | Phoenix route continues without native confirmation feedback | [Guide](bridge.md#bounded-bridge) |
| media_capture | native_screen | native_screen | supported | verification required | companion | merge-blocking | native-required | native screen route; capture pack availability | pack_incompatible | fail closed instead of degrading into a bounded web upload flow | [Guide](native_shell.md#native-capture-escape-hatch) |
| notification_token | bounded_bridge | provider_snapshot | supported | verification required | companion | advisory | companion-required | declared route capability; bounded bridge support; notification authorization already resolved; provider token snapshot available | unavailable_capability | treat notification token replies as provider-tagged evidence instead of backend registration truth | [Guide](capabilities.md#bounded-bridge) |
| paywall_entry | backend_seam | backend_seam | supported | verification required | core | merge-blocking | companion-required | backend entitlement contract; storefront guidance | unavailable_capability | fall back to Phoenix-owned paywall guidance without device authority | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| permissions.status | bounded_bridge | alias_snapshot | supported | verification required | core | merge-blocking | none | declared route capability; bounded bridge support; notifications alias only | undeclared_capability | route continues without native notification permission snapshot authority | [Guide](capabilities.md#bounded-bridge) |
| purchase_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking | companion-required | backend reconciliation; provider-specific adapter | unavailable_capability | treat purchase events as reconciliation inputs, not entitlement truth | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| reconciliation_evidence | backend_seam | backend_seam | supported | verification required | core | merge-blocking | companion-required | backend reconciliation; device callback or webhook; pending and awaiting_verification reconciliation states stay non-granting | unavailable_capability | Treat device/storefront/webhook/support evidence as non-authoritative reconciliation input; pending_purchase, pending_restore, and awaiting_verification remain non-granting until backend projection refreshes authority. | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| restore_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking | companion-required | backend reconciliation; storefront-aware adapter | unavailable_capability | keep restore flow backend-owned until adapter truth is explicit | [Guide](capabilities.md#backend-seams-and-deferred-surfaces) |
| scanner | native_screen | native_screen | unsupported | unsupported | defer | advisory | companion-required | scanner-native runtime; policy-heavy proof lane | unavailable_capability | defer scanner support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
| share | bounded_bridge | bounded_bridge | supported | supported | core | advisory | none | truthful semantic share contract | undeclared_capability | keep content in the Phoenix-owned route until a share family is declared | [Guide](capabilities.md#bounded-bridge) |

## Bridge Reply Delivery

Reply delivery is stated per path. A bounded-bridge family being `supported` means the route is authorized to dispatch it and the denial contract holds; it does not by itself mean a NATIVE reply travels back on every platform yet.

| Reply path | Baseline | Proof Status | Notes |
|------------|----------|--------------|-------|
| server-synthesized denial | supported | merge-blocking | Every platform including a plain browser with no shell at all. No shell, an unwired hook, and a shell refusal each resolve to exactly one typed denial; there is no configuration in which a push resolves to silence (CTRL-02). |
| Android native reply | supported | JVM hermetic proof | The shipped Android shell core has been duplex since day one — the page receives a reply proxy and the reply travels back as a JSON string. |
| iOS native reply | verification required | merge-blocking | The return leg exists in-repo from Phase 154: the reply sink evaluates JavaScript against the hook's landing pad, with Swift unit tests and committed contract vectors. Phase 156 was stopped, so no native-menu release promotes this path. It must ship only as needed for the first adopter runtime line and remains narrower than physical-device proof. Until then an iOS route still receives the server-synthesized denial rather than a native reply. |

Fire-and-forget families do not wait on the iOS leg: `haptics.impact` is already present in the shipped closed command enum of both native cores, so its proof needs no native release.

## Commerce Corridors

| corridor_role | owner_posture | prerequisite_classes | prerequisites | denial_codes | fallback_behavior | proof_class | rebuild_requirement |
|---------------|---------------|----------------------|---------------|--------------|-------------------|-------------|---------------------|
| paywall_entry | phoenix_owned | route_declaration; backend_reconciliation | route declares commerce corridor binding; backend entitlement contract available | commerce.corridor.undeclared; commerce.corridor.entry_denied; commerce.corridor.origin_denied | Keep the paywall route Phoenix-owned and return explicit declaration guidance when a corridor check fails. | merge-blocking | native_rebuild_required=false: Core route/manifest metadata only — Phoenix-owned paywall changes do not require a native shell rebuild. |
| account_management | phoenix_owned | route_declaration; backend_reconciliation | route declares commerce corridor binding; backend entitlement projection available | commerce.corridor.undeclared; commerce.corridor.policy_blocked; commerce.corridor.prerequisite_missing | Return to backend-owned account management guidance and fail closed until prerequisites are restored. | merge-blocking | native_rebuild_required=false: Core route/manifest metadata only — backend-owned account surfaces do not require a native shell rebuild. |
| purchase_intent | native_or_companion_required | native_adapter; provider_setup; backend_reconciliation | native or companion storefront corridor implemented; backend reconciliation ingest enabled | commerce.corridor.runtime_incompatible; commerce.corridor.unsupported; commerce.corridor.pack_incompatible; commerce.corridor.prerequisite_missing | Fail closed with return-to-Phoenix guidance; never grant entitlement authority from device intent alone. | merge-blocking | native_rebuild_required=true: Native adapter or provider SDK code changes require rebuilding and resubmitting the host shell. |
| restore_intent | native_or_companion_required | native_adapter; provider_setup; backend_reconciliation | native or companion restore corridor implemented; backend reconciliation ingest enabled | commerce.corridor.runtime_incompatible; commerce.corridor.unsupported; commerce.corridor.pack_incompatible; commerce.corridor.prerequisite_missing | Fail closed with restore guidance and keep entitlement truth backend-owned until evidence is reconciled. | merge-blocking | native_rebuild_required=true: Native restore choreography or provider SDK code changes require rebuilding and resubmitting the host shell. |

## Packaging Ledger

`crosswake` remains the one primary public package. Companions are first-party-scoped typed boundaries, not plugin-market surfaces.

| Surface | Class | Why | Release Burden | Public Guide |
|---------|-------|-----|----------------|--------------|
| `crosswake` primary package | core | Route-policy DSL, manifest contract, compatibility axes, bounded-bridge vocabulary, shell generators, doctor, support matrix, release rules, and proof posture stay in one obvious Phoenix-first package. | Hex package SemVer moves independently, while support truth still follows manifest_schema_version, bridge_protocol_version, and native_runtime_version. | [Guide](install.md#package-surface) |
| Phoenix-facing commerce seam vocabulary | core | `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` stay normalized and backend-truthful in core without embedding storefront providers. | Semantics may evolve in core, but provider adapters and native storefront logic remain outside the base package. | [Guide](capabilities.md#packaging-ledger) |
| Provider adapters and native-heavy integrations | companion | Storefront adapters, media/upload/capture, rollout, auth/session, notifications, and audit/operator seams carry native binary churn or backend coupling beyond core. | First-party companions declare minimum compatible ranges against core, compatibility axes, and capability-family majors. | [Guide](compatibility.md#companion-compatibility-contract) |
| Checked-in example hosts and install walkthroughs | example/docs-only | Examples, walkthroughs, reviewer playbooks, and vendor recipes teach boundaries and proof posture without becoming separate runtime packages. | Not first-class supported as package surfaces; promotion requires reclassification plus proof and support-matrix updates. | [Guide](capabilities.md#docs-only-boundary) |
| Standalone native shell core packages | core | The generated shell stays host-owned, while reusable native core logic resolves from SwiftPM and Maven Central packages instead of monorepo-local paths. | Native core versions move in lockstep with the Hex package through release-please linked versions; clean-room proof verifies the external install path at release time. | [Guide](install.md#step-2-generate-host-owned-native-shells) |

## Release And Versioning Policy

package versions alone do not define support truth.

| Target | Versioning | Compatibility Contract | Release Rule |
|--------|------------|------------------------|--------------|
| core | Independent SemVer for the `crosswake` Hex package. | package versions alone do not define support truth; manifest_schema_version, bridge_protocol_version, and native_runtime_version stay canonical. | Manifest-major, bridge-major, and runtime-line changes must update support docs and doctor before release. |
| companion | Independent SemVer per first-party companion. | Each companion declares minimum compatible ranges for core, all three compatibility axes, and exposed capability-family majors. | Companion support cannot expand until the adapter publishes explicit compatibility ranges and fail-closed guidance. |
| ios_shell | SwiftPM core package version is lockstep with the Hex package; host app build numbers remain adopter-owned. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |
| android_shell | Maven Central core artifact version is lockstep with the Hex package; host app build numbers remain adopter-owned. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |

## Change Classes

| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |
|--------------|--------------|----------------|----------------------|----------------|
| docs-only | Guides, wording, examples, support notes, or advisory docs changed without changing manifest semantics, compatibility-axis values, capability versions, shell templates, companion code, or proof expectations. | Read the updated guidance and rerun docs integrity only. | No compatibility-axis or capability-version change. | docs integrity only |
| core-only/no native rebuild | Core Elixir behavior, docs generation, doctor, support rendering, or validation changed inside the already-supported schema, bridge, runtime, and capability versions. | Update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells. | Existing manifest_schema_version, bridge_protocol_version, native_runtime_version, and capability majors stay in line. | core contract + doctor/support proof |
| compatibility-bump only | Compatibility declarations or package windows narrowed so some older combinations now fail closed, but a fresh binary is not automatically required for already-compatible adopters. | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | manifest_schema_version, bridge_protocol_version, native_runtime_version, or capability required-version declarations changed support windows. | fail-closed compatibility fixtures |
| native or companion rebuild required | Native code, generated shell projects, entitlements, permissions, platform config, native dependencies, or companion-native integration code changed. | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | Every rebuild-required change carries explicit compatibility declarations, especially native_runtime_version, bridge_protocol_version, manifest_schema_version, and capability required-version shifts. | core proof plus generated-shell or companion verification lanes |

## Rebuild Decision Table

| Axis | Change Kind | Rebuild Class | Adopter Action | Denial Signal | Guide Anchor |
|------|-------------|---------------|----------------|---------------|--------------|
| manifest_schema_version | additive | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | compatibility_mismatch | guides/compatibility.md#manifest_schema_version |
| manifest_schema_version | breaking | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | compatibility_mismatch | guides/compatibility.md#manifest_schema_version |
| bridge_protocol_version | additive | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | compatibility_mismatch | guides/compatibility.md#bridge_protocol_version |
| bridge_protocol_version | breaking | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | compatibility_mismatch | guides/compatibility.md#bridge_protocol_version |
| native_runtime_version | additive | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. Note: unlike schema/protocol axes, native runtime additive bumps always require a rebuild because the runtime lives in the binary. | compatibility_mismatch | guides/compatibility.md#native_runtime_version |
| native_runtime_version | breaking | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | compatibility_mismatch | guides/compatibility.md#native_runtime_version |
| capability_version (core-owned) | additive | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | undeclared_capability | guides/compatibility.md#capability-version |
| capability_version (native/companion) | additive | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | undeclared_capability | guides/compatibility.md#capability-version |
| capability_version | breaking | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | undeclared_capability | guides/compatibility.md#capability-version |
| docs_wording | additive | docs-only | Read the updated guidance and rerun docs integrity only. | n/a | guides/support_matrix.md#change-classes |
| core_elixir_behavior | additive | core-only/no native rebuild | Update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells. | n/a | guides/support_matrix.md#change-classes |

## Action Classes

| action_class | subject | required_action | rebuild_required | reason | guide_anchor |
|--------------|---------|-----------------|------------------|--------|--------------|
| docs_only | Public guides, examples, and support notes | Read updated guidance and rerun docs integrity checks. | false | Docs-only changes do not change manifest semantics, compatibility axes, native code, or proof expectations. | guides/support_matrix.md#action-classes |
| route_manifest | Phoenix route policy and manifest metadata | Update the Hex package, regenerate manifest truth, and run core contract plus doctor/support proof. | false | Route and manifest metadata can stay core-only when schema, bridge, runtime, and capability major versions remain compatible. | guides/support_matrix.md#action-classes |
| compatibility | Compatibility windows and required version declarations | Check compatibility windows and run fail-closed compatibility fixtures before release. | false | A narrowed support window may reject older combinations without requiring already-compatible adopters to rebuild. | guides/compatibility.md#runtime-line-rules |
| native_shell | iOS or Android shell artifacts and native runtime line | Rebuild affected shells, publish the updated runtime line, and rerun generated-shell verification lanes. | true | Native code, entitlements, permissions, platform config, and generated shell projects require host shell rebuild verification. | guides/native_shell.md#boundary-warnings--rough-edges |
| companion_native | First-party companion bindings or companion-native surfaces | Verify companion dependency health, compatibility ranges, and fail-closed fallback posture before widening support. | true | Companion-native integrations can carry native binary churn or backend coupling beyond core route metadata. | guides/companions.md#support-truth-and-proof-posture |
| provider_adapter | Storefront/provider SDK adapters | Keep provider proof advisory until adapter implementation, provider setup, backend reconciliation, docs, and promotion criteria all pass. | true | Provider SDK adapters require native/provider setup and cannot be treated as shipped support from seam-only contracts. | guides/commerce.md#provider-adapter-defers |

## Promotion Rules

Promotion rules keep advisory proof visible until evidence, docs, platform, and demotion criteria are all satisfied.

| claim_id | current_state | promotes_to | evidence_class | required_evidence | minimum_consecutive_passes | freshness_window | failure_budget | required_platforms | required_docs_anchors | change_class | action_class | check_ids | demotion_trigger |
|----------|---------------|-------------|----------------|-------------------|----------------------------|------------------|----------------|--------------------|-----------------------|--------------|--------------|-----------|------------------|
| shell.ios.generated_project | merge-blocking | supported | generated_shell | script/verify_generated_ios_shell.sh; support matrix parity | 1 | current release branch | zero merge-blocking failures | ios | guides/support_matrix.md; guides/native_shell.md | native or companion rebuild required | native_shell | diag.shell.verification_required | Demote to verification_required when generated-shell proof fails or native_runtime_version support narrows. |
| shell.android.generated_project | advisory | merge-blocking | generated_shell | script/verify_generated_android_shell.sh; Java-enabled BridgeChannel proof | 2 | current release branch | zero merge-blocking failures | android | guides/support_matrix.md; guides/native_shell.md | native or companion rebuild required | native_shell | diag.shell.verification_required | Keep or demote to verification_required when Android JVM or generated-shell proof is stale or unavailable. |
| notification_token.provider_snapshot | advisory | merge-blocking | provider_snapshot | notification_token capability contract; provider-tagged snapshot fixtures | 2 | current release branch | zero contract failures | ios; android | guides/support_matrix.md; guides/capabilities.md | native or companion rebuild required | companion_native | diag.notification.token_provider_snapshot_only | Demote when provider snapshot proof is stale, missing, or confused with Chimeway delivery support. |
| auth.sigra.session_authority | merge-blocking | merge-blocking | session_authority_handoff_step_up_auth_return_contract | auth posture route fixtures; session authority evaluator proof; step_up_required denial-code proof; single-use handoff ticket lifecycle proof; server-record redemption and audit proof; server-owned step-up intent lifecycle proof; shared Plug/LiveView ceremony proof; OAuth/passkey/native auth-return envelope proof; host-owned auth-return attempt replay proof; verified-link-first native return proof; low-cardinality auth telemetry proof; security closeout proof | 1 | current release branch | zero contract failures | ios; android | guides/support_matrix.md; guides/companions.md | native or companion rebuild required | companion_native | diag.auth.sigra_session_authority | Demote if route predicates, auth_posture, auth_return route policy, step_up_required/auth.handoff/auth.step_up_intent/auth.return denial codes, auth telemetry metadata, handoff/step-up/auth-return server-record proof, security closeout, or Sigra docs drift from support truth. |
| purchase_intent.provider.storekit | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | ios | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.storekit.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until StoreKit adapter, provider setup, docs parity, and backend reconciliation proof all pass. |
| restore_intent.provider.storekit | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | ios | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.storekit.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until StoreKit restore evidence stays backend-owned and proof/docs parity pass. |
| purchase_intent.provider.play_billing | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | android | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.play_billing.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until Play Billing adapter, provider setup, docs parity, and backend reconciliation proof all pass. |
| restore_intent.provider.play_billing | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | android | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.play_billing.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until Play Billing restore evidence stays backend-owned and proof/docs parity pass. |
| shell.android.jvm_hermetic | advisory | merge-blocking | jvm_hermetic_ci | script/verify_generated_android_shell.sh; Java-enabled JVM BridgeChannel hermetic proof; support-matrix rebuild_matrix parity; docs-contract parity for Android runtime-line | 3 | current release branch, within 30 CI runs | zero consecutive failures; single failure resets counter | android | guides/support_matrix.md; guides/native_shell.md#android-verification | native or companion rebuild required | native_shell | diag.shell.android.jvm_hermetic; diag.shell.verification_required | Demote to verification_required when Android JVM hermetic CI proof is stale, fails, or coverage drops below the freshness window. jvm_hermetic promotion MUST NOT be read as device_verified — CI-level evidence is not device/emulator evidence. |
| shell.android.device_verified | advisory | merge-blocking | device_verified | Android emulator advisory lane evidence (Phase 68); device-UAT checklist completion (Phase 68); capability-parity-locked device proof; docs-contract parity for Android device-verified runtime-line | 3 | current release branch, within 10 device-UAT runs | zero consecutive failures; single failure resets counter | android | guides/support_matrix.md; guides/native_shell.md#android-device-uat | native or companion rebuild required | native_shell | diag.shell.android.device_verified; diag.shell.verification_required | Device/emulator proof is unavailable until Phase 67 (Android shell implementation) and Phase 68 (Android verification closure and device-UAT checklist). jvm_hermetic promotion MUST NOT be read as device_verified — CI-level JVM hermetic evidence does not constitute real-device or emulator proof. Demote to verification_required if device-UAT evidence is stale or if the device lane drops below the freshness window. |

## Notification Surface (v3.9)

Crosswake provides explicitly bounded support for notifications via the Chimeway companion.

**Supported:**
- **Token binding:** The `notification_token` capability resolves local push tokens.
- **notification-open routing:** Notification open resolved through RouteGate for manifest-known routes and route-local action allowlists.
- **Route activation proof:** The notification-open workflow proof is hermetic route activation proof. RouteGate and Sigra decide activation; token/open evidence is not auth authority.
- **Resolution limits:** Bounded bridge operations ensure requests complete predictably.
- **Evidence redaction:** Diagnostic output actively redacts sensitive identifiers.

**Deferred (Not Supported):**
- **APNs/FCM delivery execution:** APNs/FCM delivery is not part of this proof, and Crosswake does not act as a push delivery service.
- **Push metrics:** Delivery and read-receipt metrics are not tracked by the core framework.
- **Deep UI native presentation:** Custom native notification UI presentation is left to the host shell.

**Strict Telemetry Contract:**
The telemetry event structure `[:crosswake, :notification, :*]` exposes low-cardinality delivery status and routing outcomes. **Raw payload data, device tokens, and PII are strictly forbidden and explicitly stripped from all diagnostic output.**

## Media Evidence Recovery Surface (v4.1)

Crosswake provides a hermetic Rindle proof for simulated media recovery.

**Supported:**
- **Recovery proof:** Rindle media/evidence recovery proof is hermetic and merge-blocking.
- **Simulated degradation:** Simulated network degradation is proof-only and deterministic.
- **Backend authority:** Local capture evidence is not availability authority; backend verification is required before media becomes available.
- **Proof copy:** `Capture recorded locally; media is not available yet`, `Device evidence recorded; backend verification still required`, `This proof does not use a real storage provider`, and `Local capture evidence does not grant media availability`.

**Deferred (Not Supported):**
- **Real storage providers:** Host applications own storage target choice and persistence.
- **Native camera/media picker capture:** Capture UX remains host-owned.
- **Background transfer and device network toggling:** These remain advisory/deferred and never gate merge.
- **Generic sync:** Phase 72 does not ship a broad sync engine.

## Public Non-Claims And Rough Edges

- StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass.
- Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contract machinery, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, Phase 58 auth telemetry/security closeout, and Phase 73 auth-sensitive admin workflow proof are shipped for route predicates, `auth_posture`, route-local `auth_return`, `:step_up_required`, canonical `auth.handoff.*`, canonical `auth.step_up_intent.*`, canonical `auth.return.*` denial codes, stable `[:crosswake, :auth, ...]` telemetry events, low-cardinality diagnostic metadata, and proof that persistent shell session state does not grant admin access; refresh-token helpers, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, native auth UI, and generic audit machinery remain deferred. Promotion requires an executable host reference proof covering reconnect, backend reauthorization before replay, logout, expiry, revocation, and account switching; documentation alone cannot promote a deferred item.
- APNs/FCM push delivery execution, delivery metrics, and deep UI native notification presentation remain deferred; notification support focuses strictly on token binding, notification-open routing, RouteGate/Sigra route activation proof, and diagnostic telemetry.
- Standalone native shell core packages are consumed by generated host-owned wrappers through SwiftPM and Maven Central; device/emulator proof and broader native runtime claims remain deferred until separately proven.
- Native pack lifecycle transitions currently prove contract behavior, not production byte download, integrity verification, atomic installation, eviction, background transfer, or generic content storage.
- First adopter work may add one host-supplied foreground iOS pronunciation-pack adapter. Generic app-wide sync, background sync, silent last-write-wins, multiple proven islands, broad reusable runtime sync helpers, and generic productionized native pack storage remain unclaimed.
- Android remains available at its existing generated-shell/JVM proof posture but is frozen during first adopter iOS readiness; frozen does not mean device-verified.
