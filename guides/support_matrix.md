# Crosswake Support Matrix

This guide stays narrow and proof-oriented. The published iOS and Android shell claims
below are backed by the checked-in example hosts plus the generated-shell verification
hooks that now pass on the same host-owned artifact classes adopters ship.

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
| ios | 17.0 | supported | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned iOS shell boot is proof-backed by the checked-in example host and generated-shell verification hook. |

## Android

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| android | 26 | supported | verification required | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Host-owned Android shell boot is baseline-supported, but the current repository truth still requires the Java-enabled BridgeChannel proof lane to pass before Android support can be claimed as fully verified. |

## Shell Artifacts

| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |
|--------|---------|----------|--------------|------------|------------|-------|
| ios_shell | 0.1.0 | supported | supported | script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated iOS shell artifacts are supported while the Phase 5 iOS verification hook stays green. |
| android_shell | 0.1.0 | supported | verification required | script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated Android shell artifacts remain baseline-supported, but repository support truth stays verification-required until the Java-enabled BridgeChannel proof lane passes. |

## Capability Families

| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |
|--------|-------|---------|----------|--------------|---------|-------|---------|---------------|--------|----------|-------|
| app_info | bounded_bridge | bounded_bridge | supported | verification required | core | merge-blocking | none | declared route capability; bounded bridge support | undeclared_capability | Phoenix route continues without native app metadata | [Guide](bridge.md#bounded-bridge) |
| deep_link | activation | activation_first | supported | supported | core | merge-blocking | none | bundled or cached manifest; shell activation support; explicit route entry approval | route_unavailable | show route unavailable surface that distinguishes inactive routes from routes that reject external entry | [Guide](native_shell.md#manifest-first-activation) |
| document_scan | native_screen | native_screen | supported | supported | defer | advisory | companion-required | document-scan runtime; policy-heavy proof lane | unavailable_capability | defer document scan support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
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
| scanner | native_screen | native_screen | supported | supported | defer | advisory | companion-required | scanner-native runtime; policy-heavy proof lane | unavailable_capability | defer scanner support until native and proof posture are explicit | [Guide](capabilities.md#explicit-defers) |
| share | bounded_bridge | bounded_bridge | supported | supported | core | advisory | none | truthful semantic share contract | undeclared_capability | keep content in the Phoenix-owned route until a share family is declared | [Guide](capabilities.md#bounded-bridge) |

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
| auth.sigra.session_authority | merge-blocking | merge-blocking | session_authority_handoff_contract | auth posture route fixtures; session authority evaluator proof; step_up_required denial-code proof; single-use handoff ticket lifecycle proof; server-record redemption and audit proof | 1 | current release branch | zero contract failures | ios; android | guides/support_matrix.md; guides/companions.md | native or companion rebuild required | companion_native | diag.auth.sigra_session_authority | Demote if route predicates, auth_posture, step_up_required/auth.handoff denial codes, handoff server-record proof, or Sigra docs drift from support truth. |
| purchase_intent.provider.storekit | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | ios | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.storekit.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until StoreKit adapter, provider setup, docs parity, and backend reconciliation proof all pass. |
| restore_intent.provider.storekit | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | ios | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.storekit.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until StoreKit restore evidence stays backend-owned and proof/docs parity pass. |
| purchase_intent.provider.play_billing | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | android | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.play_billing.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until Play Billing adapter, provider setup, docs parity, and backend reconciliation proof all pass. |
| restore_intent.provider.play_billing | advisory | merge-blocking | provider_adapter | deterministic adapter contract proof; backend reconciliation authority proof; docs-contract parity proof; advisory storefront/provider lane evidence | 3 | current adapter release | zero entitlement-authority failures | android | guides/support_matrix.md; guides/commerce.md | native or companion rebuild required | provider_adapter | diag.provider.play_billing.advisory_proof; diag.provider.adapter_shipped_seams | Remain advisory until Play Billing restore evidence stays backend-owned and proof/docs parity pass. |

## Public Non-Claims And Rough Edges

- StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass.
- Sigra session-authority route evaluation and Phase 55 handoff ticket/server-record contract machinery are shipped for route predicates, `auth_posture`, `:step_up_required`, and canonical `auth.handoff.*` denial codes; ceremony, passkey/OAuth/native auth-return validation, refresh-token helpers, provider/device proof, and native auth UI remain deferred.
- notification-token readiness is provider-snapshot only and not delivery support; Chimeway delivery, notification-open routing, and push-delivery guarantees are not shipped in v3.6.
- Standalone public shell packages are deferred; generated iOS and Android shell projects remain host-owned scaffolds and checked-in example proof artifacts.
