# Commerce & Entitlement Contracts

Crosswake does not ship a billing engine or storefront provider SDKs. Instead, it defines a standard vocabulary and explicit backend-owned reconciliation flow for Phoenix apps. This ensures that Phoenix teams can handle native commerce requirements without compromising the security and truth of their entitlement rules.

This guide is structured in three explicit layers so adopters and reviewers can navigate from canonical core contract truth down to advisory playbooks and explicit non-claims:

1. **Commerce Support Truth** — provider-neutral, mechanically enforced core contract surface (vocabulary, corridors, snapshot lanes, denial taxonomy, projection precedence).
2. **Reviewer And Storefront Playbooks** — adopter-facing reviewer notes templates with explicit `Advisory — provider-specific guidance` boundaries; these are copy-and-customize starting points, not core support claims.
3. **Rough Edges And Non-Claims** — explicit list of what Crosswake does NOT ship or claim in the current milestone, expressed in canonical fallback vocabulary.

---

## Commerce Support Truth

This layer is the canonical, provider-neutral core contract surface. Everything below is mechanically enforced by docs-contract tests against `Crosswake.SupportMatrix` and the doctor pipeline. No provider-specific guidance lives in this layer.

### Normalized Commerce Vocabulary

Crosswake exposes five core typed surfaces:

1. `paywall_entry`: Semantic definition of pricing and intent.
2. `purchase_intent`: A request for reconciliation and provider workflow entry.
3. `restore_intent`: A request to restore purchases and begin reconciliation.
4. `entitlement_snapshot`: A backend-issued read model of access truth.
5. `reconciliation_evidence`: The normalized input envelope for purchase, restore, webhook, or support evidence.

### Commerce Corridor Ownership

Crosswake keeps corridor ownership explicit and matrix-first so route authors can see where Phoenix stays in control and where native or companion choreography is mandatory. Every corridor row mirrors the canonical support matrix source (`Crosswake.SupportMatrix.commerce_corridors/0`); guides are rendered artifacts, not independent sources.

| corridor_role | owner_posture | proof_class | native_rebuild_required | phase_19_truth |
| --- | --- | --- | --- | --- |
| `paywall_entry` | `phoenix_owned` | `merge_blocking` | `false` | Keep paywall entry routes Phoenix-owned and declarative; core route/manifest metadata only. |
| `account_management` | `phoenix_owned` | `merge_blocking` | `false` | Keep post-reconciliation account surfaces Phoenix-owned; backend-owned metadata only. |
| `purchase_intent` | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | `true` | Storefront confirmation and purchase execution require native or companion choreography; native adapter or provider SDK code changes require rebuilding and resubmitting the host shell. |
| `restore_intent` | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | `true` | Restore workflows require native or companion choreography; native restore choreography or provider SDK code changes require rebuilding and resubmitting the host shell. |

For Phase 19, provider adapters are out of scope. Crosswake defines seam vocabulary and fallback posture, while StoreKit, Play Billing, and other adapter implementations stay companion or future work.

#### Proof Posture

Commerce corridor checks are split by canonical proof class so CI gates and reviewers can see exactly what blocks merge versus what is informational:

- **`merge_blocking`** (hermetic Phoenix-owned contract proof): corridor declaration, route runtime/ownership posture, canonical denial taxonomy, manifest projection, and reconciliation backend contract. Every commerce corridor row above carries a `merge_blocking` core contract proof class. These checks must pass before a change can land.
- **`advisory`** (provider/storefront/simulator/device evidence): StoreKit, Play Billing, or other provider SDK smoke checks. These run on schedule and on demand, publish artifacts and rough-edge notes, and surface only as supplementary evidence on `purchase_intent` and `restore_intent` corridors.

**Advisory checks cannot redefine core support truth.** An advisory provider check failure does not retract a `merge_blocking` claim, and an advisory check passing does not promote `purchase_intent` or `restore_intent` beyond their declared support posture. By contract, advisory checks cannot redefine the core merge-blocking support claim for any commerce corridor; advisory lanes are not core support truth. Promotion of an advisory lane to merge-blocking requires an explicit requirement/roadmap scope change plus sustained stability evidence; it is never inferred from a green run.

### Entitlement Snapshot Lanes

Crosswake models `entitlement_snapshot` as six explicit semantic lanes:

1. `authority`: backend-owned entitlement verdict (`none`, `active`, `grace`, `billing_retry`, `canceled_scheduled_end`, `revoked`, `refunded`, `expired`).
2. `access`: the route-facing decision (`granted` or `denied`) with reason metadata.
3. `reconciliation`: workflow posture (`pending_purchase`, `pending_restore`, `awaiting_verification`, `projection_refreshed`, `conflict`, `verification_failed`, `stale_authority`).
4. `freshness`: projection confidence (`fresh`, `stale`, `unknown`).
5. `effective`: effective-from / effective-until timing metadata.
6. `evidence`: bounded provenance envelope for reconciliation inputs.

The lanes are orthogonal: pending and verification workflow states belong to reconciliation and never imply direct authority grants.

### Authority vs Evidence

An `entitlement_snapshot` keeps authority and evidence separate by design. Device, storefront, webhook, and support signals are evidence sources that can advance reconciliation, but they cannot directly grant authority.

Device success is evidence, not entitlement. Missing or stale evidence must not silently imply denial, and missing device evidence must not silently imply entitlement success.

States such as `pending_purchase`, `pending_restore`, `awaiting_verification`, `grace`, `billing_retry`, `canceled_scheduled_end`, `revoked`, `refunded`, and `expired` require explicit backend projection semantics. You must evaluate `authority_state`, `access_state`, and freshness posture together rather than treating pending or evidence signals as grants.

### Commerce Moment Map

To keep boundaries explicit, Crosswake classifies commerce moments into these ownership corridors:

- **Phoenix-owned:** pricing, subscription status, entitlement-gated checks, FAQ, billing/account history, post-reconciliation account surfaces.
- **Native-screen required or strong default:** storefront purchase confirmation, restore choreography, offer-code / redeem flows, provider SDK-owned session loops.
- **Thin exception case:** bounded one-shot trigger from a Phoenix-owned route into native commerce UI, only when the surface is genuinely sheet-like (and not a complex multi-step native stack).

### Canonical Corridor Denial And Fallback Codes

Crosswake uses canonical `commerce.corridor.*` IDs across route gates, support matrix, doctor output, and docs. Every denial is `merge_blocking`: corridor failures cannot be reduced to advisory provider/storefront evidence.

| denial_code | fail_closed_reason | fallback | proof_class |
| --- | --- | --- | --- |
| `commerce.corridor.undeclared` | route declared commerce without a canonical corridor profile | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.unsupported` | corridor role or manifest-source posture is unsupported for activation | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.prerequisite_missing` | required corridor prerequisites are missing | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.runtime_incompatible` | route runtime does not satisfy corridor ownership posture | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.entry_denied` | external entry posture conflicts with corridor policy | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.origin_denied` | origin allowlist posture conflicts with corridor policy | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.policy_blocked` | role declaration conflicts with canonical corridor policy | `return_to_phoenix_guidance` | `merge_blocking` |
| `commerce.corridor.pack_incompatible` | required pack/runtime posture is incompatible for the corridor | `return_to_phoenix_guidance` | `merge_blocking` |

### The Canonical Reconciliation Flow

Crosswake requires a backend reconciliation inbox plus an authoritative entitlement projection. The canonical flow is:

1. device or native commerce route emits typed purchase or restore evidence
2. Phoenix persists a reconciliation_attempt
3. backend verification/replay runs through host-owned workers and provider adapters
4. backend updates one authoritative entitlement_snapshot
5. Phoenix/native consumers refresh from that snapshot

### Minimal Reconciliation Inbox Example

Use this minimal sequence when you need a runnable Phoenix-owned reconciliation inbox that stays backend-authoritative:

1. A `purchase`, `restore`, `webhook`, or `support` signal arrives as normalized `reconciliation_evidence`.
2. Phoenix persists append-only evidence events plus a canonical reconciliation attempt record.
3. Host-owned verification workers/processes run provider checks and replay handling.
4. One backend projection updates `entitlement_snapshot` as the single authority source.
5. Phoenix and native surfaces read that snapshot for route decisions.

Ingestion outcomes are non-authoritative by contract: they can move reconciliation work forward, but they do not grant access or set entitlement authority directly.

This reconciliation walkthrough is `example/docs-only` and companion-ready. It is guidance for host implementations, not a required persistence schema, queue layout, or job framework contract.

### Backend Idempotency

Idempotency belongs on the backend. Attempt keys should use provider-aware identity such as provider, original transaction id or purchase token, event id, and event kind. Transient device correlation ids are useful evidence but do not define idempotency keys. Duplicate webhook retries or replacement tokens must be safely handled by your host-owned workers.

Use explicit dual keys in host-owned reconciliation workers:

- `event_key`: dedupe/replay identity for one evidence event (`provider`, `provider_reference`, `event_kind`, `evidence_ref`).
- `subject_key`: serialization identity for authoritative projection ordering (`provider`, `provider_reference`, with optional host `group_id` override).
- `correlation_id`: trace metadata only. A transient device `correlation_id` never defines idempotency identity or authority ownership.

### Deterministic Projection Precedence

Keep one authoritative snapshot and map each evaluation to exactly one top-level output:

| precedence | condition | output | authority posture |
| --- | --- | --- | --- |
| 1 | freshness is `stale` or `unknown` | `stale` | fail closed until fresher backend projection data exists |
| 2 | reconciliation is `pending_purchase`, `pending_restore`, or `awaiting_verification` | `pending` | non-authoritative reconciliation in progress |
| 3 | freshness is `fresh`, reconciliation is resolved, authority is `active`/`grace`/`billing_retry`/`canceled_scheduled_end`, and access decision is granted | `granted` | authoritative backend projection allows access |
| 4 | all other resolved outcomes | `denied` | authoritative backend projection denies access |

Projection updates must enforce monotonic `as_of` ordering so out-of-order evidence cannot overwrite newer authoritative state.

### Fallback Behavior

When commerce capabilities are unavailable, undeclared, or missing evidence, the fallback involves returning to a Phoenix-owned baseline or graceful degradation. Fallback remains a Phoenix-owned guidance or a deliberate native-screen requirement without device authority. Never fail open. If the native commerce shell is unreachable, fall back to Phoenix-owned paywall guidance without attempting unsafe web-based native billing bridges.

---

## Reviewer And Storefront Playbooks

> **Advisory — provider-specific guidance**
>
> Everything in this layer is **advisory**. Reviewer notes, storefront sandbox setup, and provider-specific steps are NOT core support truth. They are copy-and-customize templates for adopters preparing App Store / Play Store submissions and they describe expected behavior of host apps that integrate Crosswake — they do not assert that Crosswake itself ships any storefront adapter. Advisory checks cannot redefine core support truth and advisory lanes are not core support truth.

### How To Use These Templates

Adopters copy these templates into their own reviewer notes, replace placeholders with real sandbox accounts and reconciliation endpoints, and submit the resulting notes to App Store or Play Store reviewers. Crosswake intentionally publishes provider-neutral templates so adopters can pin them to whichever storefront adapter (StoreKit, Play Billing, or future companion adapters) their host app ships. Each template row declares `owner`, `proof_class`, `failure_posture`, and `rebuild_requirement` so reviewers can see exactly what is expected to happen, what does not block merge of Crosswake core, and whether a native rebuild is required to land a fix.

Canonical denial codes in the fallback columns are drawn from `Crosswake.SupportMatrix.commerce_corridor_denial_codes/0`; reviewers should expect the host app to surface return-to-Phoenix guidance keyed on these codes rather than silently failing open.

#### Canonical Source Cross-References

Every reviewer template column maps back to canonical support truth so adopters cannot drift their reviewer notes away from the contract surface. The mapping is mechanically enforced by docs-contract tests (see `test/crosswake/guides/commerce_test.exs`):

| reviewer template column | canonical source | accessor |
| --- | --- | --- |
| `owner` | corridor `owner_posture` | `Crosswake.SupportMatrix.commerce_corridors/0` (each entry's `:owner_posture`) |
| `proof_class` | corridor `proof_class` and `advisory_provider_proof` flag | `Crosswake.SupportMatrix.commerce_corridor_proof_classes/0` |
| `failure_posture` | canonical denial taxonomy (fail-closed reasons + fallback codes) | `Crosswake.SupportMatrix.commerce_corridor_denial_codes/0` plus each corridor entry's `:fallback_behavior` |
| `rebuild_requirement` | corridor `rebuild_requirement` map | `Crosswake.SupportMatrix.commerce_corridors/0` (each entry's `:rebuild_requirement.native_rebuild_required` and `:rebuild_trigger`) |
| corridor role names referenced in templates | canonical corridor role set | `Crosswake.SupportMatrix.commerce_corridors/0` (each entry's `:corridor_role`) |

Adopters who add reviewer rows for additional surfaces (for example, an offer-code flow) must still draw all four metadata columns from these canonical sources. Adding a reviewer surface that does not map to a canonical corridor role is a contract violation, not a documentation choice.

### App Store Reviewer Notes

> **Advisory — provider-specific guidance**
>
> This template is advisory. Crosswake does not ship a StoreKit adapter and does not assert StoreKit-specific behavior as core support truth. The host app team is responsible for the StoreKit integration and for proving its behavior to App Store reviewers.

**Sandbox account setup:** Provide the App Store reviewer with a sandbox Apple ID provisioned with at least one auto-renewable subscription product and one non-consumable purchase product matching the host app's paywall offerings. Document the path to reach the paywall (deep link or guided navigation). Sandbox provisioning is a provider-setup prerequisite (`provider_setup` per `Crosswake.SupportMatrix.commerce_corridor_prerequisite_taxonomy/0`) and is owned by the host app, not Crosswake.

**Reviewer expectation rows:**

| surface | owner | proof_class | failure_posture | rebuild_requirement |
| --- | --- | --- | --- | --- |
| paywall entry (Phoenix-owned route render) | `phoenix_owned` | `merge_blocking` | fail closed with `commerce.corridor.undeclared` or `commerce.corridor.entry_denied` and return-to-Phoenix guidance | no native rebuild required |
| purchase flow (native StoreKit confirmation) | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | fail closed with `commerce.corridor.runtime_incompatible` or `commerce.corridor.prerequisite_missing`; never grant entitlement from device intent alone | native rebuild required for adapter or SDK changes |
| restore flow (native StoreKit restore choreography) | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | fail closed with `commerce.corridor.runtime_incompatible` or `commerce.corridor.unsupported`; backend reconciliation remains sole authority | native rebuild required for restore choreography changes |
| backend reconciliation (host-owned inbox + projection) | `phoenix_owned` | `merge_blocking` | fail closed on `commerce.corridor.prerequisite_missing` when reconciliation inbox is unreachable; never grant entitlement until projection refreshes | no native rebuild required |
| post-reconciliation account management | `phoenix_owned` | `merge_blocking` | fail closed with `commerce.corridor.policy_blocked` when account surface violates corridor policy | no native rebuild required |

**Purchase flow expectations:** Tapping the paywall purchase action must trigger the native StoreKit confirmation sheet (provided by the host app's StoreKit adapter). After successful purchase, the device emits typed `reconciliation_evidence` to the host's reconciliation inbox; the host backend verifies the receipt and updates the authoritative `entitlement_snapshot`. The Phoenix-owned account/entitlement-gated route refreshes from that snapshot. Device success is evidence, not entitlement — the reviewer should observe a brief reconciliation interval before access is granted.

**Restore flow expectations:** Tapping the restore action triggers the native StoreKit restore choreography. Restored receipts arrive at the reconciliation inbox; the host backend verifies and refreshes the `entitlement_snapshot`. Known rough edge: until the backend projection completes, the route may surface a `pending` decision keyed on reconciliation state `pending_restore` or `awaiting_verification` — these are non-authoritative by contract.

**Fallback when native purchase_intent corridor is unavailable:** The host app must fail closed with the canonical `commerce.corridor.prerequisite_missing` or `commerce.corridor.runtime_incompatible` denial code and return-to-Phoenix guidance. The host MUST NOT attempt to bridge the purchase through web-based or unsafe native commerce flows. This matches the canonical fallback posture documented in the support truth layer.

**Backend availability assumptions:** The reviewer should be informed that the host's backend reconciliation endpoints must be reachable for entitlement projection to refresh. Offline purchase replay is explicitly not supported (see Rough Edges And Non-Claims). If the backend is temporarily unreachable, the host should surface a `stale` projection state and continue to fail closed for access decisions until the backend projection refreshes.

**Advisory note on StoreKit adapter:** Crosswake does not ship a StoreKit adapter. The host app team integrates StoreKit directly (or via a future companion adapter) and is responsible for proving StoreKit behavior in submission. StoreKit-specific lanes remain `advisory` and cannot redefine core merge-blocking support truth.

### Play Store Reviewer Notes

> **Advisory — provider-specific guidance**
>
> This template is advisory. Crosswake does not ship a Play Billing adapter and does not assert Play Billing-specific behavior as core support truth. The host app team is responsible for the Play Billing integration and for proving its behavior to Play Store reviewers.

**Test account setup:** Add the Play Store reviewer's Google account to the host app's licensed testers list in Play Console, and provision at least one subscription product and one in-app product matching the host app's paywall offerings. Document the path to reach the paywall. Test account provisioning is a provider-setup prerequisite (`provider_setup` per the canonical taxonomy) and is owned by the host app, not Crosswake.

**Reviewer expectation rows:**

| surface | owner | proof_class | failure_posture | rebuild_requirement |
| --- | --- | --- | --- | --- |
| paywall entry (Phoenix-owned route render) | `phoenix_owned` | `merge_blocking` | fail closed with `commerce.corridor.undeclared` or `commerce.corridor.entry_denied` and return-to-Phoenix guidance | no native rebuild required |
| purchase flow (native Play Billing confirmation) | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | fail closed with `commerce.corridor.runtime_incompatible` or `commerce.corridor.prerequisite_missing`; never grant entitlement from device intent alone | native rebuild required for adapter or SDK changes |
| restore flow (native Play Billing restore choreography) | `native_or_companion_required` | `merge_blocking` (core) + `advisory` (provider) | fail closed with `commerce.corridor.runtime_incompatible` or `commerce.corridor.unsupported`; backend reconciliation remains sole authority | native rebuild required for restore choreography changes |
| backend reconciliation (host-owned inbox + projection) | `phoenix_owned` | `merge_blocking` | fail closed on `commerce.corridor.prerequisite_missing` when reconciliation inbox is unreachable; never grant entitlement until projection refreshes | no native rebuild required |
| post-reconciliation account management | `phoenix_owned` | `merge_blocking` | fail closed with `commerce.corridor.policy_blocked` when account surface violates corridor policy | no native rebuild required |

**Purchase flow expectations via Play Billing:** Tapping the paywall purchase action must launch the native Play Billing purchase flow (provided by the host app's Play Billing adapter). After successful purchase, the device emits typed `reconciliation_evidence` to the host's reconciliation inbox; the host backend verifies the purchase token and updates the authoritative `entitlement_snapshot`. The Phoenix-owned account/entitlement-gated route refreshes from that snapshot. As with the iOS flow, device callbacks are evidence — not entitlement — and the reviewer should observe a brief reconciliation interval before access is granted.

**Restore flow expectations:** Tapping the restore action queries Play Billing for prior purchases; restored purchase tokens arrive at the reconciliation inbox; the host backend verifies and refreshes the `entitlement_snapshot`. Known rough edge: Play Billing surfaces restore results asynchronously, so the route may briefly surface a `pending` decision keyed on reconciliation state `pending_restore` or `awaiting_verification`.

**Fallback when native restore_intent corridor is unavailable:** The host app must fail closed with the canonical `commerce.corridor.prerequisite_missing` or `commerce.corridor.runtime_incompatible` denial code and return-to-Phoenix guidance. The host MUST NOT attempt to bridge the restore through web-based or unsafe native commerce flows.

**Backend availability assumptions:** Same as the App Store template — the host's backend reconciliation endpoints must be reachable for entitlement projection to refresh. Offline purchase replay is explicitly not supported (see Rough Edges And Non-Claims). If the backend is temporarily unreachable, the host should surface a `stale` projection state and continue to fail closed for access decisions.

**Advisory note on Play Billing adapter:** Crosswake does not ship a Play Billing adapter. The host app team integrates Play Billing directly (or via a future companion adapter) and is responsible for proving Play Billing behavior in submission. Play Billing-specific lanes remain `advisory` and cannot redefine core merge-blocking support truth.

### Reviewer/Storefront Notes (Baseline Guidance)

Commerce requires explicit reviewer playbooks. Storefront reviewers will scrutinize purchase and restore flows. Adopters must prepare clear reviewer notes explaining how to trigger paywalls, how test accounts are provisioned, and how the backend handles sandbox vs. production receipts. Crosswake core limits its scope to the reconciliation envelope, meaning the storefront adapter's behavior must be documented and proven by the host app team before submission.

---

## Rough Edges And Non-Claims

This layer explicitly lists what Crosswake does NOT ship or claim in the current milestone. Each item uses canonical fallback vocabulary from the support truth layer so adopters can recognize the boundary in doctor output, support matrix rendering, and corridor denial reasons.

### Non-Goals & explicit Rejections

Crosswake intentionally explicitly avoids:
- **offline purchase replay**: There is no supported way to replay a local device purchase while entirely offline to unlock new permanent entitlements. Commerce requires an online verification step. Offline purchase replay is not shipped in v3.2 and is not on the v3.2 roadmap.
- **device-local authority**: Storefront device callbacks cannot directly transition access state in the core. They provide evidence to the backend. Device-local entitlement authority is not shipped and is explicitly rejected as a contract direction.
- **split-brain truth**: We explicitly reject split-brain paths where client callbacks and server notifications maintain separate truths. Both must feed the same authoritative reconciliation boundary.
- **provider-specific core logic**: Raw Apple, Google, or RevenueCat enum details must not leak into core snapshot contracts.

### Explicit Non-Claims For v3.2

The following surfaces are explicitly **not shipped** in v3.2 and are not asserted as core support truth. Reviewers, adopters, and downstream tooling should treat any provider-specific behavior as host-app responsibility, not Crosswake responsibility:

- **StoreKit adapter is not shipped.** Crosswake does not ship a StoreKit adapter or provide StoreKit-specific runtime code. Any StoreKit integration is host-app or future-companion work; StoreKit lanes remain `advisory` and cannot redefine core merge-blocking support truth. Fallback when StoreKit is unavailable: fail closed with `commerce.corridor.prerequisite_missing` and `return_to_phoenix_guidance`.
- **Play Billing adapter is not shipped.** Crosswake does not ship a Play Billing adapter or provide Play Billing-specific runtime code. Any Play Billing integration is host-app or future-companion work; Play Billing lanes remain `advisory` and cannot redefine core merge-blocking support truth. Fallback when Play Billing is unavailable: fail closed with `commerce.corridor.prerequisite_missing` and `return_to_phoenix_guidance`.
- **Storefront purchase UI is not shipped.** Crosswake does not render storefront purchase or restore UI. Native storefront UI is owned by the host app's StoreKit or Play Billing integration. Fallback when storefront UI is missing: fail closed with `commerce.corridor.runtime_incompatible` and `return_to_phoenix_guidance`.
- **Device-local entitlement authority is not shipped.** Storefront device callbacks are evidence, not authority. The core contract explicitly rejects device-local authority and requires backend-owned entitlement projection. There is no v3.2 path to grant entitlement from a device callback alone.
- **Offline purchase replay is not shipped.** Commerce requires an online verification step. Offline purchase replay is explicitly outside the v3.2 scope and is not on the v3.2 roadmap.

### Known Rough Edges

- During restore flows on either platform, the route may briefly surface a `pending` decision keyed on reconciliation state `pending_restore` or `awaiting_verification` before the backend projection refreshes. This is non-authoritative by contract.
- If the backend reconciliation inbox is temporarily unreachable, projection freshness will degrade to `stale` and access decisions will fail closed until the backend projection refreshes. This is correct behavior, not a bug.
- Advisory provider-specific lanes (StoreKit, Play Billing simulator/device checks) run on schedule and on demand; failures in advisory lanes do not retract any merge-blocking core support claim and passing advisory lanes do not promote any corridor beyond its declared support posture.

*See [guides/capabilities.md](capabilities.md) for the broader capabilities contract and ownership rubric.*
