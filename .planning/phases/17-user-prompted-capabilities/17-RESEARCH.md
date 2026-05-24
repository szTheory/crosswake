# Phase 17: User-Prompted Capabilities - Research

**Researched:** 2026-05-21  
**Domain:** Bounded-bridge notification token retrieval and transfer-bound file picking  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### `notification_token` authority
- **D-01:** `notification_token` owns token retrieval and refresh only. It does not trigger notification authorization prompts.
- **D-02:** Notification authorization remains a separate concern. Phase 17 callers should check `permissions.status` first, and any future prompt-owning flow must use a separately named interactive command or a native-owned flow rather than overloading `notification_token`.
- **D-03:** `notification_token` command semantics must stay deterministic per invocation. Crosswake must not ship a "sometimes prompts, sometimes fetches" command shape.
- **D-04:** If notification authorization or platform token prerequisites are missing, `notification_token` fails closed with a typed denial that names the prerequisite explicitly instead of silently prompting or silently returning empty data.

### `notification_token` reply contract
- **D-05:** A successful `notification_token` reply includes `token` plus a normalized `notification_status` snapshot and optional secondary `detail`. It does not return a bare token.
- **D-06:** `notification_status` reuses the same small Crosswake-owned status vocabulary as `permissions.status`: `granted`, `denied`, or `restricted`. Platform-native nuance stays in secondary `detail`.
- **D-07:** Returned token data is evidence only. It must not imply backend registration, topic subscription, delivery readiness, or end-to-end notification success.
- **D-08:** Top-level bridge semantics stay unchanged: contract or policy failures return `status: "deny"`, while successful bridge execution returns `status: "ok"` with bounded payload fields that Phoenix can branch on.
- **D-09:** Any future Phoenix-side token registration helper remains a separate backend seam. Phase 17 must not standardize provider-specific registration endpoints or collapse backend truth into the bridge.

### `file_picker` authority boundary
- **D-10:** `file_picker` is not a free-standing public authority surface. Public invocation must bind to a declared route-local `transfer_id` whose typed transfer contract justifies the picker.
- **D-11:** Phase 17 supports picker-backed seams only for low-frequency inbound flows: `import` and upload preparation from `source: :native_picker`. Generic filesystem browsing, directory picking, persistent tree access, and broad provider authority remain out of scope.
- **D-12:** Picker results are evidence for a transfer seam, not durable file authority. Returned handles must not be treated as stable long-term access grants without a later explicit contract upgrade.
- **D-13:** Crosswake should bias toward app-sandbox copies or staged import handles for Phoenix-owned routes rather than in-place editing semantics. Copy-vs-access truth must stay explicit per platform behavior.
- **D-14:** MIME/type filters are advisory until verified. Native-provider mismatches must fail closed through transfer verification rather than assuming picker filtering was honored perfectly.
- **D-15:** If a route needs continuous selection, rich provider browsing, editing in place, or permission choreography beyond one-shot import/upload preparation, the interaction should graduate out of bounded bridge into a native-screen or companion surface.

### `file_picker` result contract
- **D-16:** Successful picker replies return a stable top-level shape for both single and multiple selection. The public reply should carry `transfer_id` plus `items: [item]` rather than switching between one item and many.
- **D-17:** Each picked item includes normalized public fields for `handle`, `name`, `mime_type`, and `size_bytes`. `native_type` may appear as optional secondary platform detail.
- **D-18:** `handle` is the stable public field for the selected native reference, but metadata fields other than `handle` are nullable when the platform cannot truthfully provide them.
- **D-19:** The reply must not echo `multiple_allowed`. Multiplicity policy belongs to the request and transfer contract; the reply expresses actual outcome through `items` cardinality.
- **D-20:** Cancellation is a distinct typed outcome, not a fake success with `items: []`.
- **D-21:** Phase 17 must not add durable bookmark, persistable-access, or reopen-later semantics to the first picker result contract.

### Decision delegation posture
- **D-22:** Shift normal implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice would materially change public capability semantics, denial vocabulary, backend-truth posture, rebuild/support claims, or route-owner boundaries.

### the agent's Discretion
- Exact request and response struct names, as long as the public semantics above remain stable and typed.
- Exact denial reason identifiers and copy, as long as missing authorization, unavailable token, canceled picker, and transfer-contract mismatch remain clearly distinct.
- Exact shell-side staging mechanics for picker copies or temporary handles, as long as long-lived authority is not implied.
- Exact optional `detail` keys for notification or picker platform nuance, as long as primary branching remains on Crosswake-owned normalized fields.

### Deferred Ideas (OUT OF SCOPE)
- A separately named interactive notification-permission prompt command, if Crosswake later decides it should own that choreography explicitly
- Phoenix/backend helpers for provider-specific token registration, topic subscription, or reconciliation
- Generic standalone file browsing, directory selection, or persistent document-tree access
- Long-lived document bookmarks, reopen-later semantics, or in-place editing contracts
- Any file-management or notification workflow that needs continuous native authority, heavy platform choreography, or backend/provider coupling beyond a bounded bridge seam
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAP-NOTIFTOKEN | Implement `notification_token` bridge to request and return APNs/FCM tokens. [VERIFIED: .planning/ROADMAP.md] | Use a provider-tagged, evidence-only typed reply; require `permissions.status` preflight; keep bridge request/reply-only by reading a shell-maintained token snapshot refreshed from native startup and token-refresh callbacks. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] |
| CAP-FILEPICKER | Implement `file_picker` bridge to handle OS file selection and return typed results. [VERIFIED: .planning/ROADMAP.md] | Bind picker requests to declared `transfer_id`s only; stage immediate app-sandbox copies; return opaque handles plus nullable metadata; verify MIME/type through the transfer seam instead of trusting picker filtering. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: test/support/router_fixtures.ex] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/topics/providers/document-provider] |
</phase_requirements>

## Summary

`notification_token` should ship as a bounded, evidence-only bridge family whose public contract stays synchronous even though the native token lifecycles are callback-driven. The current iOS and Android bridge channels both evaluate one request into one immediate reply, with no multi-reply subscription path today, so the native shells should maintain an in-memory token snapshot that is refreshed by platform startup and token-refresh callbacks, and the bridge should read that snapshot or fail closed with an explicit prerequisite denial. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] [CITED: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages]

On iOS, Crosswake can truthfully surface an APNs device token when Push Notifications capability and APNs registration are configured; authorization for visible notifications is related but separate, and Apple explicitly distinguishes `requestAuthorization(...)` from `registerForRemoteNotifications()`. On Android, there is no equivalent platform push token surface in the repo today, so Crosswake should treat FCM as a companion-backed provider seam and deny `notification_token` when Firebase Messaging is not configured instead of inventing a fake platform-neutral Android token story. [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29?changes=la] [CITED: https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications?changes=_9_2&language=objc] [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: guides/support_matrix.md] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging]

`file_picker` should stay transfer-bound, not ambient. The cleanest truthful split is `files.pick` as the bounded picker trigger plus declared transfer seams for downstream import or upload preparation. iOS should use `UIDocumentPickerViewController(..., asCopy: true)` so the default story is copy-first, while Android should use `ACTION_GET_CONTENT` for import-copy posture rather than `ACTION_OPEN_DOCUMENT`, which Android documents as the persistent-access path. Both shells should immediately copy selected content into app-controlled staging, return opaque staged handles instead of raw URLs/URIs, and let transfer verification enforce media-type truth before Phoenix treats the result as usable. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: guides/bridge.md] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init%28foropeningcontenttypes%3Aascopy%3A%29?changes=_2] [CITED: https://developer.android.com/guide/topics/providers/document-provider] [CITED: https://developer.android.com/guide/components/intents-common]

**Primary recommendation:** Implement `notification_token` as a provider-tagged snapshot bridge over native refresh callbacks, and implement `file_picker` as a transfer-bound, copy-first staged-handle bridge that never grants durable document authority. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `notification_token` contract and denial vocabulary | API / Backend | Frontend Server (SSR) | Elixir owns the typed bridge contract, manifest/support truth, and denial semantics; Phoenix callers branch on evidence but never own token-provider truth. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| Native token acquisition and refresh | Frontend Server (SSR) | API / Backend | The shell owns APNs/FCM interaction, startup registration, and token-refresh callbacks; backend registration remains a later seam. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] |
| `permissions.status` preflight | Frontend Server (SSR) | API / Backend | Native shells know effective notification status; Elixir normalizes the contract and keeps support truth honest. [VERIFIED: lib/crosswake/bridge/commands/permissions_status.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt] |
| `file_picker` invocation and cancellation | Frontend Server (SSR) | Browser / Client | The shell must present the OS picker and interpret completion/cancel signals; the browser only initiates one low-frequency request. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/reference/android/app/Activity.html] |
| Picker result staging and opaque-handle registry | Frontend Server (SSR) | Database / Storage | Native shells should stage copied content into app-owned temporary storage and expose only temporary handles to the route. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt] |
| Transfer verification and downstream import/upload semantics | API / Backend | Frontend Server (SSR) | Transfer declarations, verification requirements, and result vocabulary are already Elixir-owned contract truth; native shells provide evidence and staged paths/handles only. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: test/support/router_fixtures.ex] |

## Standard Stack

### Core

| Library / Component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| `Crosswake.Bridge.Contract` | `crosswake.bridge@1.0.0` | Canonical request/reply envelope and denial shape | Phase 17 should extend the existing bounded bridge instead of inventing a second async bus. [VERIFIED: lib/crosswake/bridge/contract.ex] |
| `Crosswake.Transfer.Contracts` | `crosswake.transfer@1.0.0` | Typed transfer declarations and result states | `file_picker` already has a route-local authority seam here via `source: :native_picker`; reuse it. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: test/support/router_fixtures.ex] |
| `Crosswake.Bridge.Commands.PermissionsStatus` | current repo | Shared normalized notification status vocabulary | Phase 17 should reuse `granted | denied | restricted` rather than invent a second status family. [VERIFIED: lib/crosswake/bridge/commands/permissions_status.ex] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] |
| `UIApplication.registerForRemoteNotifications()` + APNs | iOS floor `17.0` | iOS device-token acquisition | Apple defines APNs registration and device-token delivery here; this is the truthful iOS token source. [VERIFIED: guides/support_matrix.md] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications?changes=_9_2&language=objc] |
| `UIDocumentPickerViewController(forOpeningContentTypes:asCopy:)` | iOS floor `17.0` | Copy-first iOS document selection | Apple documents explicit copy-vs-open behavior; `asCopy: true` matches Crosswake’s bounded import posture. [VERIFIED: guides/support_matrix.md] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init%28foropeningcontenttypes%3Aascopy%3A%29?changes=_2] |
| `Intent.ACTION_GET_CONTENT` + `CATEGORY_OPENABLE` | Android floor `26` | Copy-first Android content import | Android documents `ACTION_GET_CONTENT` as the import-copy path and `CATEGORY_OPENABLE` as the streamable-file filter. [VERIFIED: guides/support_matrix.md] [CITED: https://developer.android.com/guide/topics/providers/document-provider] [CITED: https://developer.android.com/guide/components/intents-common] [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html] |

### Supporting

| Library / Component | Version | Purpose | When to Use |
|---------------------|---------|---------|-------------|
| `UNUserNotificationCenter` notification settings | iOS current SDK | Notification authorization snapshot | Use to populate `notification_status` and detail before or alongside APNs token reads; do not use it to hide missing prerequisites. [VERIFIED: examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift] [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] |
| `NotificationManagerCompat.areNotificationsEnabled()` | AndroidX current SDK | Effective Android notification-enabled snapshot | Use for `permissions.status` and `notification_token` detail on Android because it captures effective app-level notification enablement. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt] [CITED: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat] |
| `POST_NOTIFICATIONS` runtime permission | Android `33+` behavior | Android user-facing notification permission fact | Use only as prerequisite detail and doctor/support truth; keep prompting out of `notification_token`. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt] [CITED: https://developer.android.com/develop/ui/compose/notifications/notification-permission] |
| `FirebaseMessaging.getToken()` | companion-managed | Android registration-token retrieval | Use only when the Android shell explicitly ships a Firebase companion-backed notification provider. [VERIFIED: guides/support_matrix.md] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] |
| `Messaging.messaging().token` / `didReceiveRegistrationToken` | companion-managed | Apple-side FCM token retrieval when Firebase is intentionally adopted | Use only if Crosswake later wants an iOS FCM provider variant; Phase 17 does not need it for truthful APNs support. [CITED: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ACTION_GET_CONTENT` for Android picker imports | `ACTION_OPEN_DOCUMENT` | `ACTION_OPEN_DOCUMENT` is Android’s persistent-access path; it widens authority Crosswake explicitly wants to avoid in Phase 17. [CITED: https://developer.android.com/guide/topics/providers/document-provider] |
| APNs-only iOS token support in core | iOS FCM token support | FCM on Apple platforms adds companion/provider coupling and APNs-token mapping concerns; keep APNs as the truthful core floor. [CITED: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages] [VERIFIED: guides/support_matrix.md] |
| Opaque staged handles | Raw file URLs / content URIs | Raw native references imply longer-lived authority and platform-specific lifetime rules that Phase 17 explicitly defers. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] |

**Installation:** No new Hex dependency is required in core for Phase 17. Android token retrieval should stay in a companion-managed Firebase dependency rather than entering the core package. [VERIFIED: guides/support_matrix.md] [VERIFIED: lib/crosswake/manifest/builder.ex]

## Concrete File Targets

- `lib/crosswake/bridge/commands/notification_token.ex` should define typed request/response structs, normalized status reuse, provider tagging, and denial-reason helpers for token-unavailable prerequisites. [VERIFIED: lib/crosswake/bridge/commands/permissions_status.ex]
- `lib/crosswake/bridge/commands/file_picker.ex` should define typed request/response structs, `selected | canceled` outcome vocabulary, and `item` structs with `handle`, `name`, `mime_type`, `size_bytes`, and optional `native_type`. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
- `lib/crosswake/bridge/contract.ex` should add the new concrete command id for notification token retrieval and keep `files.pick` as the picker trigger. Recommended command ids: `notification.token.get` and existing `files.pick`. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
- `lib/crosswake/bridge/registry.ex` should map `notification.token.get` to public family `notification_token`, and should promote `files.pick` to public family `file_picker` while preserving the concrete wire command. [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: lib/crosswake/policy/validator.ex]
- `lib/crosswake/manifest/builder.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `guides/capabilities.md`, `guides/bridge.md`, and `guides/support_matrix.md` should move `notification_token` and `file_picker` from compatibility-only/advisory drift into truthful Phase 17 support posture, including prerequisite and rebuild wording. [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: guides/support_matrix.md] [VERIFIED: guides/bridge.md]
- `lib/crosswake/transfer/contracts.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`, and `test/support/router_fixtures.ex` should extend transfer declarations with explicit picker selection policy. Recommended shape: `selection: :single | :multiple` on inbound `source: :native_picker` seams. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: test/support/router_fixtures.ex]
- `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` and `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` should gain dedicated handlers/providers for `notification_token` and `file_picker`, not payload-only lambdas. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt]
- `examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift` should stay the source of normalized notification status, while a new token store/provider handles APNs token snapshots. [VERIFIED: examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift]
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt` should remain the status preflight path, while a new companion-backed token provider handles FCM token snapshots. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt] [VERIFIED: guides/support_matrix.md]
- `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift` and `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt` should evolve from `staged_path` strings toward staged handle resolution for picker-backed imports/uploads. [VERIFIED: examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt]
- Test targets should mirror the existing pattern: `test/crosswake/bridge/*`, `test/crosswake/doctor/*`, `examples/ios_shell_host/CrosswakeShellTests/*`, and `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/*`. [VERIFIED: test/crosswake/bridge/registry_test.exs] [VERIFIED: test/crosswake/doctor/doctor_test.exs] [VERIFIED: examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift] [VERIFIED: examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix route
  -> route policy declares `notification_token` or `file_picker` + transfer seam
  -> manifest builder serializes capability/support/transfer truth
  -> shell activation mounts active route with manifest-backed capability versions
  -> bounded bridge request
     -> `notification.token.get`
        -> shell token store checks latest provider snapshot
        -> status preflight from `permissions.status`
        -> APNs or companion FCM provider returns token evidence
        -> bridge replies `ok` with provider-tagged payload or `deny` with prerequisite reason
     -> `files.pick`
        -> shell resolves declared `transfer_id`
        -> native picker opens with manifest-derived MIME filters + multiplicity
        -> selected content is copied into app staging
        -> shell records opaque handle + best-effort metadata
        -> bridge replies `ok` with `selected` or `canceled`
        -> later transfer command consumes staged handle and verification rules
```

### Recommended Project Structure

```text
lib/crosswake/bridge/commands/
├── notification_token.ex   # typed token request/reply contract
└── file_picker.ex          # typed picker request/reply contract

lib/crosswake/transfer/
└── contracts.ex            # transfer seam extension for picker selection policy

examples/ios_shell_host/CrosswakeShell/
├── NotificationTokenStore.swift
├── FilePickerCoordinator.swift
└── BridgeChannel.swift

examples/android_shell_host/app/src/main/java/dev/crosswake/shell/
├── notification/NotificationTokenProvider.kt
├── picker/FilePickerCoordinator.kt
└── BridgeChannel.kt
```

### Pattern 1: Snapshot Bridge Over Async Token Lifecycles
**What:** Maintain a shell-local in-memory token snapshot that is updated at app launch and token-refresh callbacks, then expose one deterministic request/reply bridge read over that snapshot. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/cloud-messaging/ios/receive-messages] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging]

**When to use:** Use for Phase 17 because Crosswake’s current bridge is one-request/one-reply and the phase explicitly forbids a prompt-owning or non-deterministic token command. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: lib/crosswake/bridge/contract.ex]

**Recommended payload shape:**  
`status: "ok"` with `%{provider, token, notification_status, detail}` on success; `status: "deny"` with reasons such as `notification_prerequisite_missing`, `notification_token_unavailable`, or `notification_provider_unconfigured` on fail-closed paths. The provider should be explicit (`"apns"` or `"fcm"`), because Apple and Android do not expose the same token reality. [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

### Pattern 2: Transfer-Bound Copy-First Picker
**What:** Resolve `files.pick` only when the active route declares a matching inbound transfer seam, derive MIME filters and multiplicity from that seam, immediately copy the selected content into app staging, and return only opaque staged handles plus best-effort metadata. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: test/support/router_fixtures.ex] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

**When to use:** Use for `import` and upload preparation from `source: :native_picker`; do not use it for browsing directories, editing in place, or reopen-later authority. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

**Recommended payload shape:**  
`status: "ok", payload: %{outcome: "selected", transfer_id, items: [...]}` for selections and `status: "ok", payload: %{outcome: "canceled", transfer_id}` for cancellations. Do not represent cancellation as `items: []`, because that hides a real user branch. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

### Pattern 3: Picker Filters Are Hints, Transfer Verification Is Authority
**What:** Pass platform file-type filters into the picker, but still verify the actual staged result against the declared transfer seam before import/upload proceeds. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: lib/crosswake/transfer/contracts.ex]

**When to use:** Always, because both Apple and Android picker ecosystems can return incomplete or provider-specific metadata, and Android explicitly separates import-copy flows from persistent-access flows. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/topics/providers/document-provider]

### Anti-Patterns to Avoid

- **Prompting inside `notification_token`:** Violates D-01 through D-04 and makes the command non-deterministic. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
- **Raw URI / URL exposure as the public picker handle:** iOS security-scoped URLs and Android content URIs have lifetime and authority rules that Phase 17 explicitly does not want to promise. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html]
- **Using `ACTION_OPEN_DOCUMENT` for Crosswake’s first Android import flow:** Android documents it as the persistent-access path; that is the wrong default for a bounded import seam. [CITED: https://developer.android.com/guide/topics/providers/document-provider]
- **Treating token success as delivery readiness:** Crosswake’s own docs and Phase 17 decisions already reject that shortcut. [VERIFIED: guides/capabilities.md] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Android push-token abstraction in core | A fake generic “platform token” provider for Android | Explicit FCM companion-backed provider seam | Android token reality is provider-specific here; the repo already classifies notifications as companion-heavy. [VERIFIED: guides/support_matrix.md] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] |
| iOS or Android durable document authority | Long-lived raw URL/URI bookmarks in Phase 17 | Immediate sandbox copy plus opaque staged handle | Phase 17 explicitly defers reopen-later and in-place editing semantics. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/topics/providers/document-provider] |
| Metadata trust from picker UI alone | Filename / MIME acceptance without verification | Transfer-seam verification against staged content | Picker filters are advisory; provider metadata can be incomplete or misleading. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] |
| Second bridge bus for async callbacks | Background event stream or subscription channel | Existing request/reply bridge plus shell-local token snapshot | The current bridge contract and shell channels are immediate reply paths, and widening them would distort the thesis. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] |

**Key insight:** The hard part of Phase 17 is not opening a picker or asking APNs/FCM for a token. The hard part is keeping authority bounded so Crosswake does not accidentally publish durable file access or push-delivery truth it cannot prove. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Building `notification_token` as a prompt-and-fetch convenience call
**What goes wrong:** The command becomes timing-dependent, user-prompt-dependent, and impossible to reason about from Phoenix. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
**Why it happens:** Apple distinguishes notification authorization from APNs registration, and Android notification permission is also a separate runtime concern on API 33+. [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29?changes=la] [CITED: https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications?changes=_9_2&language=objc] [CITED: https://developer.android.com/develop/ui/compose/notifications/notification-permission]
**How to avoid:** Keep prompting out of the command, require `permissions.status` preflight, and deny with explicit prerequisite reasons when status or provider setup is missing. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
**Warning signs:** Planner language starts saying “request permission and fetch token in one bridge call.” [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

### Pitfall 2: Exposing raw picker URLs / URIs as if they were durable handles
**What goes wrong:** Adopters infer reopen-later authority, while the actual references may be security-scoped, provider-backed, or non-persisted. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html]
**Why it happens:** Native APIs hand back platform references quickly, which makes raw passthrough tempting. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/components/intents-common]
**How to avoid:** Copy into app staging immediately and expose only opaque staged handles. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
**Warning signs:** Public docs mention “save this URI/URL and reopen later” in Phase 17. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]

### Pitfall 3: Choosing Android `ACTION_OPEN_DOCUMENT` for the first picker flow
**What goes wrong:** Crosswake accidentally publishes a persistent-access contract before it has any long-lived authority model. [CITED: https://developer.android.com/guide/topics/providers/document-provider]
**Why it happens:** `ACTION_OPEN_DOCUMENT` looks like the more modern API, but Android’s docs position it as the long-term access path. [CITED: https://developer.android.com/guide/topics/providers/document-provider]
**How to avoid:** Use `ACTION_GET_CONTENT` for import-copy Phase 17 flows and reserve persistent grants for a later explicit contract. [CITED: https://developer.android.com/guide/topics/providers/document-provider] [CITED: https://developer.android.com/guide/components/intents-common]
**Warning signs:** Implementation adds `takePersistableUriPermission(...)` in the first Phase 17 slice. [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html]

### Pitfall 4: Treating `notification_token` as a core-only capability on Android
**What goes wrong:** The support matrix overclaims Android coverage without a real provider dependency. [VERIFIED: guides/support_matrix.md] [VERIFIED: lib/crosswake/manifest/builder.ex]
**Why it happens:** The roadmap language names APNs/FCM together, which can hide the provider asymmetry. [VERIFIED: .planning/ROADMAP.md]
**How to avoid:** Keep Android token retrieval behind an explicit companion-backed provider seam and teach doctor/support matrix to deny when it is absent. [VERIFIED: guides/support_matrix.md] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
**Warning signs:** Planner proposes returning an Android token without adding any provider dependency or shell configuration step. [VERIFIED: guides/support_matrix.md]

## Code Examples

Verified patterns from current sources:

### Existing Bounded Request/Reply Contract
```elixir
# Source: lib/crosswake/bridge/contract.ex
@commands ~w(
  app.info.get
  haptics.impact
  permissions.status
  share.invoke
  files.pick
  transfer.download
  transfer.export
  transfer.import
  transfer.upload.prepare
)
```
Phase 17 should extend this contract, not bypass it. [VERIFIED: lib/crosswake/bridge/contract.ex]

### Existing Transfer Import Declaration Shape
```elixir
# Source: test/support/router_fixtures.ex
transfers: [
  [
    id: :lesson_import,
    intent: :import,
    source: :native_picker,
    verification: :required,
    media_types: ["application/pdf"]
  ]
]
```
`file_picker` should resolve through this seam instead of inventing free-standing file authority. [VERIFIED: test/support/router_fixtures.ex]

### Existing Android Permission Snapshot Pattern
```kotlin
// Source: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt
val notificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
payload["detail.post_notifications_permission"] = status
```
`notification_token` should reuse this prerequisite truth rather than clone it. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One-call prompt + token fetch | Split `permissions.status` preflight from `notification_token` evidence fetch | Locked in Phase 17 context on 2026-05-21 | Keeps bridge deterministic and fail-closed. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] |
| Raw picker path/URI passthrough | Opaque staged handle over copied content | Recommended for Phase 17 based on current transfer posture and platform docs | Preserves route-local bounded authority and honest metadata semantics. [VERIFIED: lib/crosswake/transfer/contracts.ex] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/topics/providers/document-provider] |
| Android persistent document access by default | Android import-copy via `ACTION_GET_CONTENT` | Android docs current as of 2025-05-07 | Aligns first shipped picker flow with Crosswake’s “copy, verify, continue” thesis. [CITED: https://developer.android.com/guide/topics/providers/document-provider] |
| Generic “push token” wording | Provider-tagged token evidence (`apns` / `fcm`) | Recommended for Phase 17 | Prevents false cross-platform equivalence. [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging] |

**Deprecated/outdated:**
- Returning `files.pick` as a compatibility-only bridge command with no public `file_picker` family is outdated once Phase 17 lands; the planner should promote it into a truthful public family while keeping the concrete wire command. [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: lib/crosswake/policy/validator.ex] [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

All major claims in this research were verified in the codebase or cited from official documentation. No user-confirmation blockers remain at research time.

## Open Questions (RESOLVED)

1. **Should iOS Phase 17 expose only APNs tokens, or also expose FCM tokens when a Firebase companion is present?**
   - Resolution: Phase 17 should ship an explicitly provider-tagged `notification_token` response shape, with APNs as the iOS core floor and companion-backed FCM as the Android provider seam. iOS does not need to ship an FCM variant in Phase 17, but the public payload must carry provider-explicit semantics so a later iOS companion variant can be added without breaking the contract. [VERIFIED: guides/support_matrix.md] [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging]
   - Why this is the right Phase 17 choice: It preserves Crosswake's evidence-only posture, avoids fake cross-platform equivalence, and keeps the current support truth honest while leaving room for later provider additions. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [VERIFIED: guides/capabilities.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Elixir contract, manifest, tests | ✓ | Erlang/OTP 28 / Mix present | — |
| `xcodebuild` | iOS example shell verification | ✓ | Xcode 26.0.1 | — |
| `swift` | iOS shell compilation/tests | ✓ | Swift 6.2 | — |
| Java runtime | Android example shell compilation/tests | ✗ | — | — |

**Missing dependencies with no fallback:**
- Android native compilation and test execution on this host are currently blocked by a missing Java runtime. [VERIFIED: local shell probe on 2026-05-21]

**Missing dependencies with fallback:**
- None. [VERIFIED: local shell probe on 2026-05-21]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not a login/auth phase. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Existing route/session model unchanged. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] |
| V4 Access Control | yes | Route-local capability allowlists plus `transfer_id` binding for picker flows. [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: lib/crosswake/transfer/contracts.ex] |
| V5 Input Validation | yes | Typed request structs, capability checks, MIME verification, and fail-closed denials. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/transfer/contracts.ex] |
| V6 Cryptography | no | Push-provider transport is OS/provider-managed; Phase 17 should not add custom crypto. [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [CITED: https://firebase.google.com/docs/cloud-messaging] |

### Known Threat Patterns for Phase 17

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Ambient file authority via raw URI/URL leakage | Elevation of privilege | Copy to app staging, expose opaque handles only, and expire handle registries aggressively. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/reference/kotlin/android/content/Intent.html] |
| MIME or extension spoofing | Tampering | Verify staged content against declared transfer seam before import/upload proceeds. [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md] |
| Notification-token overclaim | Spoofing | Provider-tag payloads, evidence-only docs, and deny missing provider setup. [VERIFIED: guides/capabilities.md] [VERIFIED: guides/support_matrix.md] |
| Route confusion / capability drift | Elevation of privilege | Keep active-route, origin, capability-version, and transfer-seam checks in the existing bridge gate before any side effect. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt] |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/bridge/contract.ex` - current bounded request/reply contract and command set.
- `lib/crosswake/bridge/registry.ex` - manifest-backed capability/transfer allowlist behavior.
- `lib/crosswake/bridge/commands/permissions_status.ex` - normalized notification status vocabulary.
- `lib/crosswake/transfer/contracts.ex` - transfer seam and verification contract.
- `lib/crosswake/manifest/builder.ex` - capability catalog and package/support truth.
- `guides/bridge.md`, `guides/capabilities.md`, `guides/support_matrix.md`, `guides/native_shell.md` - public product posture already claimed by the repo.
- `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`, `PermissionStatusProvider.swift`, `TransferCoordinator.swift` - iOS shell execution patterns.
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`, `PermissionStatusProvider.kt`, `transfer/TransferCoordinator.kt` - Android shell execution patterns.
- `test/support/router_fixtures.ex` - declared `source: :native_picker` seams.
- Apple docs:
  - https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4
  - https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications?changes=_9_2&language=objc
  - https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29?changes=la
  - https://developer.apple.com/documentation/usernotifications/unauthorizationstatus
  - https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
  - https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init%28foropeningcontenttypes%3Aascopy%3A%29?changes=_2
- Android docs:
  - https://developer.android.com/develop/ui/compose/notifications/notification-permission
  - https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat
  - https://developer.android.com/guide/topics/providers/document-provider
  - https://developer.android.com/guide/components/intents-common
  - https://developer.android.com/reference/kotlin/android/content/Intent.html
  - https://developer.android.com/reference/android/app/Activity.html
- Firebase docs:
  - https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging
  - https://firebase.google.com/docs/cloud-messaging/ios/receive-messages
  - https://firebase.google.com/docs/cloud-messaging

### Secondary (MEDIUM confidence)
- None needed beyond the official documentation set above.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - Core Elixir and picker platform APIs are clear, but Android token delivery still depends on a companion/provider choice not yet implemented in this repo. [VERIFIED: guides/support_matrix.md] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging]
- Architecture: HIGH - The bounded bridge, transfer seam, and route-local authority boundaries are explicit in current code and locked phase decisions. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/transfer/contracts.ex] [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
- Pitfalls: HIGH - The main failure modes are well supported by current docs and existing Crosswake guardrails. [VERIFIED: guides/capabilities.md] [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller] [CITED: https://developer.android.com/guide/topics/providers/document-provider]

**Research date:** 2026-05-21  
**Valid until:** 2026-06-20

## RESEARCH COMPLETE

**Phase:** 17 - User-Prompted Capabilities  
**Confidence:** MEDIUM

### Key Findings
- `notification_token` should stay evidence-only and provider-tagged, with prompt ownership explicitly left out of scope. [VERIFIED: .planning/phases/17-user-prompted-capabilities/17-CONTEXT.md]
- The current bridge is synchronous on both iOS and Android, so token retrieval should read a shell-maintained snapshot refreshed by native lifecycle callbacks rather than introduce a new async bus. [VERIFIED: examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt]
- iOS can truthfully support APNs token retrieval in core shell code; Android token retrieval should remain a companion-backed FCM provider seam rather than a fake “platform token.” [CITED: https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns?changes=l_4] [VERIFIED: guides/support_matrix.md] [CITED: https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessaging]
- `file_picker` should be implemented as a transfer-bound, copy-first staged-handle flow: iOS via `UIDocumentPickerViewController(..., asCopy: true)`, Android via `ACTION_GET_CONTENT` plus immediate app-sandbox copy. [CITED: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init%28foropeningcontenttypes%3Aascopy%3A%29?changes=_2] [CITED: https://developer.android.com/guide/topics/providers/document-provider]
- Android execution planning must account for a missing Java runtime on this host before native test automation can pass. [VERIFIED: local shell probe on 2026-05-21]

### File Created
`.planning/phases/17-user-prompted-capabilities/17-RESEARCH.md`

### Ready for Planning
Research complete. Planner can now create Phase 17 plan files.
