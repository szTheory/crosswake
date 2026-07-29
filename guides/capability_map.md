# Crosswake Capability Map

This guide is rendered from `Crosswake.CapabilityMap`. It classifies what Crosswake supports today, what the v19 showcase proves, what is demo pressure, what remains a future gap, and what v20 Native Controls Pack 1 should consider next.

## What works today

Available today means the support claim is backed by typed route policy, manifest/support truth, and an explicit fallback. It is not a blanket device, provider, or plugin claim.

- **Route policy DSL and runtime ownership** — Available today; Use as the policy gate for every Native Controls Pack 1 affordance.
- **Deep link and native shell activation** — Available today; Keep activation truth as the shell boundary for any new control entry points.
- **Bounded bridge app info** — Available today; Model low-frequency request/reply controls on this route-local contract.
- **Bounded bridge haptics** — Available today; Promote into Native Controls Pack 1 as a hardened route-local control.
- **Read-only permission status** — Available today; Pack 1 may include read-only snapshots only; permission requests remain out of scope.

## What evidence exists

The v19 showcase gives proof-backed examples and demo pressure across AdminPilot, Fieldserv, LearnLoop, bridge, offline study, native fallback, and capability-pressure rows. Screenshots are collateral after route-tour assertions; screenshots are not proof posture.

Cached read-only is not offline mutation. Backend projection required means provider or storefront evidence is reconciliation input until the backend grants authority.

- **Bounded bridge share** — Advisory evidence; Candidate for Native Controls Pack 1 only with explicit platform support truth.
- **Notification token evidence snapshot** — Advisory evidence; Pack 1 may reference provider snapshots, but APNs/FCM delivery and universal notification handling stay outside core.
- **AdminPilot approval haptics pressure** — Proof-backed example; Use as the reference route-local success-feedback control for Pack 1.
- **Scanner and QR scan** — Future gap; Defer to Capture & Device Controls.
- **Document scan** — Future gap; Defer to Capture & Device Controls.
- **Media upload and evidence availability** — Future gap; Defer to Capture & Device Controls.
- **LearnLoop socketless offline study island** — Proof-backed example; Use as evidence for later Offline Sync/Native Storage Productization, not Pack 1.
- **Backend-owned mocked entitlement projection** — Demo pressure; Keep commerce/provider support out of Native Controls Pack 1.

## What v20 will do

v20 Native Controls Pack 1 should stay route-local, typed, versioned, low-frequency, and fail-closed. It should prioritize bounded controls and keep capture/device, commerce/paywall productionization, offline sync/native storage, and operator dashboard work as named later packs.

### Next-pack candidates

- **Fieldserv native capture handoff** — Next-pack candidate; Promote only after Capture & Device Controls proof exists.
- **Native alert and confirm affordances** — Next-pack candidate; Candidate for v20 Native Controls Pack 1.
- **Native menu and action-button affordances** — Next-pack candidate; Candidate for v20 Native Controls Pack 1.
- **Native toast and review prompt** — Next-pack candidate; Candidate for v20 Native Controls Pack 1 with strict platform policy truth.

### Deferred later packs

- **Offline field inspection mutation** — Future gap; Defer to Offline Sync/Native Storage Productization.
- **Native storage for content packs** — Future gap; Defer to Offline Sync/Native Storage Productization.
- **Reusable sync helpers** — Future gap; Defer to Offline Sync/Native Storage Productization.
- **StoreKit, Play Billing, and RevenueCat production integration** — Future gap; Defer to Commerce/Paywall Productionization later.

## Detailed Capability Rows

| Capability or surface | Display label | Route or evidence source | Current category | Route runtime owner | Package owner | Proof posture | Rebuild | Denial/fallback behavior | v20 implication |
|-----------------------|---------------|--------------------------|------------------|---------------------|---------------|---------------|---------|--------------------------|-----------------|
| Route policy DSL and runtime ownership | Available today | guides/route_policy.md and compiled router metadata | shipped | live view | core | merge-blocking | No rebuild required | Routes fail closed through explicit runtime policy, manifest validation, and support-matrix diagnostics. | Use as the policy gate for every Native Controls Pack 1 affordance. |
| Deep link and native shell activation | Available today | guides/native_shell.md and bridge/native behavioral proof | shipped | native shell | native shell | merge-blocking | No rebuild required | Inactive or unsupported route entry falls back to route-unavailable guidance instead of hidden WebView navigation authority. | Keep activation truth as the shell boundary for any new control entry points. |
| Bounded bridge app info | Available today | guides/bridge.md and manifest capability catalog | shipped | bounded bridge | core | merge-blocking | No rebuild required | Phoenix route continues without native app metadata when the route has not declared the capability. | Model low-frequency request/reply controls on this route-local contract. |
| Bounded bridge haptics | Available today | AdminPilot approval route and guides/bridge.md | shipped | bounded bridge | core | merge-blocking | No rebuild required | Approval state remains Phoenix/server authoritative; haptics is optional confirmation feedback. | Promote into Native Controls Pack 1 as a hardened route-local control. |
| Bounded bridge share | Advisory evidence | bridge-proof route and guides/capabilities.md | demoed | bounded bridge | core | advisory | No rebuild required | Content stays in the Phoenix-owned route when a share family is undeclared or unavailable. | Candidate for Native Controls Pack 1 only with explicit platform support truth. |
| Read-only permission status | Available today | permissions.status capability family | shipped | bounded bridge | core | merge-blocking | No rebuild required | Route continues without native notification permission snapshot authority when undeclared. | Pack 1 may include read-only snapshots only; permission requests remain out of scope. |
| Notification token evidence snapshot | Advisory evidence | notification_token capability family and Chimeway support truth | demoed | bounded bridge | first-party companion | advisory | Companion rebuild required | Token replies are provider-tagged evidence, not backend registration truth or delivery proof. | Pack 1 may reference provider snapshots, but APNs/FCM delivery and universal notification handling stay outside core. |
| AdminPilot approval haptics pressure | Proof-backed example | /saas/approvals/approval-1 route-tour proof | demoed | bounded bridge | core | merge-blocking | No rebuild required | Phoenix approval mutation commits server state first; native haptics can fail without changing approval authority. | Use as the reference route-local success-feedback control for Pack 1. |
| Fieldserv native capture handoff | Next-pack candidate | /fieldserv/jobs/:id/capture handoff evidence | next-pack candidate | native screen | native shell | not-yet-proven | Native rebuild required | The host app owns this native screen; browser evidence review remains backend-verification truth. | Promote only after Capture & Device Controls proof exists. |
| Scanner and QR scan | Future gap | Fieldserv capability pressure rows | missing | future native control | deferred | unsupported | Companion rebuild required | Scanner requests remain unavailable instead of falling through to generic plugin support. | Defer to Capture & Device Controls. |
| Document scan | Future gap | Fieldserv capability pressure rows | missing | future native control | deferred | unsupported | Companion rebuild required | Document scan stays unavailable until native session ownership and proof posture are explicit. | Defer to Capture & Device Controls. |
| Media upload and evidence availability | Future gap | Fieldserv evidence review route | missing | future native control | deferred | unsupported | Native rebuild required | Backend verification, not device evidence, determines whether media evidence is available. | Defer to Capture & Device Controls. |
| Offline field inspection mutation | Future gap | Fieldserv cached read-only posture | deferred | future native control | deferred | not-yet-proven | No rebuild required | Cached read-only remains explicit; local mutation needs a journal, outbox, retry, and reconciliation path. | Defer to Offline Sync/Native Storage Productization. |
| LearnLoop socketless offline study island | Proof-backed example | /learnloop/study/session and offline route-tour proof | demoed | offline island | example/docs-only | merge-blocking | No rebuild required | Browser-owned IndexedDB outbox and reconciliation visibility are local to the offline island; server reset does not clear browser-owned state. | Use as evidence for later Offline Sync/Native Storage Productization, not Pack 1. |
| Native storage for content packs | Future gap | LearnLoop content-pack pressure | deferred | future native control | deferred | not-yet-proven | Native rebuild required | Content packs remain browser/example evidence until native storage budgets and eviction behavior are explicit. | Defer to Offline Sync/Native Storage Productization. |
| Reusable sync helpers | Future gap | LearnLoop replay and history diagnostics | deferred | future native control | deferred | not-yet-proven | No rebuild required | The example outbox proves one route-local flow, not a universal sync engine. | Defer to Offline Sync/Native Storage Productization. |
| Backend-owned mocked entitlement projection | Demo pressure | /learnloop/subscription and commerce guide | demoed | backend projection | example/docs-only | advisory | Companion rebuild required | Backend projection remains entitlement authority; device or storefront evidence never grants access. | Keep commerce/provider support out of Native Controls Pack 1. |
| StoreKit, Play Billing, and RevenueCat production integration | Future gap | guides/commerce.md and LearnLoop pressure | deferred | backend projection | deferred | not-yet-proven | Native rebuild required | Provider events are reconciliation evidence until backend projection grants entitlement authority. | Defer to Commerce/Paywall Productionization later. |
| Native alert and confirm affordances | Next-pack candidate | v20 Pack 1 candidate from v19 evidence | next-pack candidate | future native control | core | not-yet-proven | Native rebuild required | Until declared and proven, routes must keep Phoenix-owned confirmation surfaces. | Candidate for v20 Native Controls Pack 1. |
| Native menu and action-button affordances | Next-pack candidate | v20 Pack 1 candidate from AdminPilot and Fieldserv pressure | next-pack candidate | future native control | core | not-yet-proven | Native rebuild required | Actions remain Phoenix-owned until route policy, allowlists, and fallback behavior are explicit. | Candidate for v20 Native Controls Pack 1. |
| Native toast and review prompt | Next-pack candidate | v20 Pack 1 candidate from showcase feedback pressure | next-pack candidate | future native control | core | not-yet-proven | Native rebuild required | Routes must treat toast/review prompts as optional UX evidence, not navigation or backend authority. | Candidate for v20 Native Controls Pack 1 with strict platform policy truth. |
