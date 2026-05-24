# Phase 16: System Context Bridges - Research

**Researched:** 2026-05-20
**Domain:** Manifest-first deep-link entry policy and narrow read-only permission status bridges
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Deep-link authority and activation model
- **D-01:** In Phase 16, `deep_link` remains inbound shell activation only. Universal links, app links, notifications, and app-entry URLs normalize into manifest-first activation before any runtime mounts.
- **D-02:** Phase 16 does **not** add an outbound `deep_link` bridge command or any route-local navigation authority. Outbound behavior stays ordinary Phoenix URL generation and shell/native platform linking outside the bounded bridge.
- **D-03:** Downstream planning should treat inbound deep-link handling as part of the shell activation contract, not the bridge contract. The bridge must not become a navigation bus.

### Deep-link declaration posture
- **D-04:** Deep-link entry must be explicitly declared in route policy metadata and derived into manifest truth. Deep-linkability is fail-closed by default, not ambient across every manifest route.
- **D-05:** The route policy should support scope defaults plus per-route overrides, but the underlying model stays explicit opt-in. Defaults must not silently widen sensitive or internal routes.
- **D-06:** Activation denials and diagnostics must distinguish between "route does not exist" and "route exists but is not approved for external entry." Support truth and doctor output should surface that difference explicitly.

### `permissions.status` scope
- **D-07:** The first shipped `permissions.status` contract stays narrow, read-only, and capability-keyed. It should cover only point-of-need permission facts that align to immediate Crosswake capability prerequisites and near-term proof/doctor work.
- **D-08:** Phase 16 must not expose a broad generic OS-permission snapshot surface, app-wide permission dashboard semantics, or permission-request orchestration. Request flows remain separate later-phase work.
- **D-09:** Any permission alias exposed publicly must be something Crosswake can name, document, diagnose, and fail closed around in route policy, support matrix, and doctor output.

### `permissions.status` reply shape
- **D-10:** The primary Phoenix-facing reply contract should use a small Crosswake-owned normalized status enum, with optional platform detail carried in a secondary field.
- **D-11:** Route logic and normal caller ergonomics should branch on the normalized primary status first. Platform-native facts such as limited scope, requestability, or native status labels may appear in `detail`, but `detail` must remain secondary.
- **D-12:** The public primary contract must not depend on platform-specific status strings or pretend to know richer blocked/requestability states than a read-only check can honestly guarantee on both iOS and Android.

### Decision delegation posture
- **D-13:** Shift normal implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes public contract semantics, fail-closed behavior, support claims, security posture, or compatibility/versioning rules.

### Claude's Discretion
- Exact route-policy field naming for explicit deep-link entry metadata, as long as it reads as route-entry policy rather than bridge capability authority.
- Exact normalized status enum member names and optional detail field names, as long as the contract stays small, typed, and stable across platforms.
- Exact internal registry structure for mapping capability prerequisites to permission aliases, as long as the public `permissions.status` surface remains narrow and honest.
- Exact doctor copy, denial wording, and guide wording, as long as "inactive route" and "not approved for external entry" remain clearly distinct.

### Deferred Ideas (OUT OF SCOPE)
- Outbound deep-link ergonomics, if later needed, should arrive as Phoenix-side URL helpers or a separately named family rather than widening `deep_link` into route-local bridge authority.
- Broad app-wide permission dashboards, generic permission brokers, or request flows belong in later phases if the capability/support posture ever proves them honestly.
- Rich platform-specific permission state exposure as a primary public contract is explicitly deferred; only secondary detail escape hatches are acceptable in this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAP-DEEPLINK | Implement `deep_link` handling as manifest-first shell activation with explicit route-entry approval, not as a bridge navigation bus. [VERIFIED: .planning/ROADMAP.md] | Add route-entry metadata to policy and manifest, extend shell activation denial vocabulary, and align doctor/support proof around inbound-only activation. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| CAP-PERMSTATUS | Implement `permissions.status` as a narrow read-only capability query that callers can use before later permission-sensitive flows. [VERIFIED: .planning/ROADMAP.md] | Add a typed bridge command/reply, capability-keyed alias registry, normalized primary status enum, and doctor/support truth for supported aliases only. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 16 should be planned as two tightly bounded contract extensions, not as general mobile-platform plumbing. Deep-link work belongs in the existing shell activation pipeline, where Phoenix route policy compiles into manifest truth and both shells decide allow or deny before any runtime mounts. The missing contract seam is explicit route-entry approval metadata plus a denial split between "route is absent/inactive" and "route exists but is not approved for external entry." Current code already has the right activation architecture, but Elixir and iOS still use exact-path matching while Android already supports `:segment` matching for manifest paths. [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] [VERIFIED: .planning/PROJECT.md]

`permissions.status` should ship as a small typed bridge surface for point-of-need facts only. The narrowest honest first public posture is a capability-keyed query with a Crosswake-owned primary enum of `granted | denied | restricted`, plus optional `detail` fields for platform-native nuance such as iOS `notDetermined`, `provisional`, `ephemeral`, or `limited`, and Android requestability or notification-block state. Apple exposes richer per-framework authorization states, while Android’s general runtime permission check is still primarily granted-vs-denied and uses rationale APIs for request flow guidance rather than stable cross-platform state truth. [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] [CITED: https://developer.apple.com/documentation/avfoundation/avauthorizationstatus] [CITED: https://developer.apple.com/documentation/photos/phauthorizationstatus?changes=_3] [CITED: https://developer.apple.com/documentation/contacts/cnauthorizationstatus/limited] [CITED: https://developer.android.com/training/permissions/requesting] [CITED: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat]

**Primary recommendation:** Add manifest-derived `entry` metadata for inbound deep links, introduce a new activation denial for entry-disallowed routes, and ship `permissions.status` as a typed read-only query with a small normalized enum and alias set scoped to near-term proof and doctor needs. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deep-link entry approval truth | API / Backend | Browser / Client | Phoenix route metadata and manifest generation are the source of truth, while the shell enforces that truth at activation time. [VERIFIED: lib/crosswake/policy/router_metadata.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| Incoming URL normalization and pre-mount denial UI | Browser / Client | API / Backend | iOS and Android coordinators already normalize incoming URLs and present denial UI before runtime mount. [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] |
| Route-entry denial taxonomy and serialization | API / Backend | Browser / Client | `Crosswake.Shell.Denial` is the shared typed contract, and both shells mirror its reason vocabulary. [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] |
| `permissions.status` query contract | API / Backend | Browser / Client | Elixir owns the typed bridge protocol and support truth, while native shells execute the platform check and return normalized payloads. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] |
| Doctor/support proof for entry policy and permission aliases | API / Backend | Browser / Client | Doctor and support matrix are generated from core truth, but they verify shell artifacts and native prerequisites. [VERIFIED: lib/crosswake/doctor/doctor.ex] [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` in project, `1.19.5` on this machine | Phoenix-side policy, manifest, bridge, doctor, and tests | Phase 16 extends existing core modules instead of adding a sidecar service. [VERIFIED: mix.exs] [VERIFIED: environment `elixir --version`] |
| Phoenix | `~> 1.8`, locked `1.8.7` | Router metadata source for route-entry policy | Existing route policy is authored inline with Phoenix routes. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Phoenix LiveView | `~> 1.1`, locked `1.1.30` | Route-owner baseline for Phoenix-owned screens | Deep-link entry remains route activation into existing LiveView ownership, not a new runtime model. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| NimbleOptions | `~> 1.1`, locked `1.1.1` | Typed policy schema validation | Existing route-policy options already flow through `Crosswake.Policy.Schema`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Crosswake manifest / bridge / shell contracts | manifest `1.0.0`, bridge `1.0.0`, runtime line `1.0.0` | Stable typed contract surfaces to extend | Current activation and bridge work already hangs off these versioned contracts. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/shell/activation.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swift / Xcode | Swift `6.2`, Xcode `26.0.1` | iOS activation and permission-status handlers | Use for inbound URL matching, route-entry denial presentation, and iOS permission adapters. [VERIFIED: environment `swift --version`] [VERIFIED: environment `xcodebuild -version`] |
| Android SDK APIs via checked-in shell | Android floor `26` | Android activation and permission-status handlers | Use for app links / intent activation and permission-status queries. [VERIFIED: guides/support_matrix.md] [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex] |
| `NotificationManagerCompat` | AndroidX Core API | Effective notification-enabled check on Android | Use for the first `notifications` alias instead of inventing app-local notification state. [CITED: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat] |
| `UNUserNotificationCenter` authorization settings | Apple platform API | Notification authorization state on iOS | Use for the first `notifications` alias on iOS. [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manifest-first entry metadata | Shell-local allowlists or a second path-rule system | Conflicts with Crosswake’s single source of route truth and reintroduces a parallel routing contract. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |
| Inbound-only `deep_link` family | Outbound bridge command or navigation bus | Violates locked Phase 16 decisions and widens bridge authority beyond the active route. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| Normalized primary permission enum | Raw platform status strings in the public contract | Makes caller logic platform-specific and breaks D-10 through D-12. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| Capability-keyed permission aliases | Broad OS permission snapshot | Violates the bounded-bridge thesis and creates proof/doctor scope Crosswake cannot support honestly. [VERIFIED: guides/capabilities.md] |

**Installation:**
```bash
mix deps.get
```
No new Hex dependency is required for the core Elixir side of Phase 16. Native work stays inside the existing checked-in iOS and Android shells. [VERIFIED: mix.exs] [VERIFIED: examples/ios_shell_host/CrosswakeShell] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell]

## Architecture Patterns

### System Architecture Diagram

```text
Incoming URL / universal link / app link
  -> iOS/Android ActivationCoordinator normalizes request
  -> manifest route lookup with dynamic-segment matching
  -> route-entry policy check
     -> route missing/inactive -> route unavailable surface
     -> route exists but entry denied -> route unavailable surface with entry-denied reason
     -> route allowed -> runtime activation (LiveView or native_screen)

Phoenix route metadata
  -> Crosswake.Policy.Schema / Route / Compiler
  -> Crosswake.Manifest.Builder / Types / Validator
  -> manifest routes + capability registry + support truth
  -> shells + doctor + support matrix consume same canonical truth

LiveView route needing permission preflight
  -> bounded bridge request (`permissions.status.get`) [ASSUMED]
  -> native alias adapter
     -> iOS platform authorization API
     -> Android platform authorization / notifications-enabled API
  -> normalized Crosswake reply (`granted|denied|restricted` + detail)
  -> Phoenix route decides whether to continue, degrade, or explain
```

### Recommended Project Structure
```text
lib/crosswake/
├── policy/                 # Route metadata schema, normalization, validation
├── manifest/               # Route-entry serialization and support truth
├── shell/                  # Activation request/decision and denial vocabulary
├── bridge/                 # Typed request/reply protocol, command registry, payload structs
├── doctor/                 # Operator-facing diagnostics and proof checks
└── support_matrix/         # Generated public support truth

examples/ios_shell_host/CrosswakeShell/    # iOS activation + bridge handlers
examples/android_shell_host/app/src/main/java/dev/crosswake/shell/  # Android activation + bridge handlers
examples/phoenix_host/lib/crosswake_example/router.ex               # Example host route-entry declarations
```

### Concrete File Targets

- `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/compiler.ex`, and `lib/crosswake/policy/validator.ex` should gain explicit route-entry metadata and validation because route policy already enters the system through those modules. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/policy/route.ex] [VERIFIED: lib/crosswake/policy/compiler.ex] [VERIFIED: lib/crosswake/policy/validator.ex]
- `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`, and `lib/crosswake/manifest/validator.ex` should serialize and validate the new entry metadata because current route entries and capability metadata are built there. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: lib/crosswake/manifest/validator.ex]
- `lib/crosswake/shell/activation.ex`, `lib/crosswake/shell/denial.ex`, `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift`, and `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt` should implement the entry check and denial split because that is the current activation path. [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt]
- `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, and a new `lib/crosswake/bridge/commands/permissions_status.ex` module should host the typed request/reply contract because existing bounded-bridge commands follow that pattern. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: lib/crosswake/bridge/commands/app_info.ex] [VERIFIED: lib/crosswake/bridge/commands/share.ex]
- `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `guides/native_shell.md`, `guides/bridge.md`, `guides/capabilities.md`, and `guides/support_matrix.md` should be updated because the public support contract already renders from those surfaces. [VERIFIED: lib/crosswake/doctor/doctor.ex] [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex] [VERIFIED: guides/native_shell.md] [VERIFIED: guides/bridge.md] [VERIFIED: guides/capabilities.md] [VERIFIED: guides/support_matrix.md]

### Pattern 1: Manifest-Derived Entry Policy
**What:** Add an explicit route-entry field on each manifest route, derived from Phoenix route metadata, with default-deny semantics for external entry. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**When to use:** Every shell activation source that originates outside the active Phoenix route, especially deep links, app links, universal links, and notification-open URLs. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
**Example:**
```elixir
# Source: lib/crosswake/manifest/builder.ex
Types.new_route_entry(
  id: route.id,
  path: path,
  runtime: route.runtime,
  capabilities: route.capabilities,
  allowlisted_origins: [origin]
)
```
Phase 16 should extend this existing route-entry construction path rather than adding shell-only config. [VERIFIED: lib/crosswake/manifest/builder.ex]

### Pattern 2: Route-Unavailable UI, Distinct Denial Reasons
**What:** Keep one route-unavailable surface for users, but add a distinct machine-readable denial for "entry denied" separate from "inactive route." [VERIFIED: guides/native_shell.md] [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**When to use:** Whenever a deep link resolves to a known route whose runtime is valid but whose route-entry policy rejects external activation. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**Example:**
```elixir
# Source: lib/crosswake/shell/denial.ex
@reasons [
  :compatibility_mismatch,
  :undeclared_capability,
  :unavailable_capability,
  :origin_denied,
  :inactive_route,
  :pack_incompatible
]
```
Phase 16 should extend this shared vocabulary instead of inventing shell-specific strings. [VERIFIED: lib/crosswake/shell/denial.ex]

### Pattern 3: Narrow Typed Permission Query
**What:** Add one request/reply bridge command whose payload names a Crosswake permission alias and whose reply returns a normalized primary status plus optional detail. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**When to use:** Before later bounded-bridge or native-screen flows whose public contract depends on explicit prerequisite truth, starting with notification enablement. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/crosswake/manifest/builder.ex]
**Example:**
```elixir
# Source: lib/crosswake/bridge/commands/app_info.ex
defmodule Crosswake.Bridge.Commands.AppInfo.Response do
  @enforce_keys [:version, :build, :bundle_id]
  defstruct [:version, :build, :bundle_id]
end
```
Phase 16 should follow this typed payload-module pattern for `permissions.status`. [VERIFIED: lib/crosswake/bridge/commands/app_info.ex]

### Anti-Patterns to Avoid
- **Outbound deep-link bridge command:** Locked out by D-01 through D-03 and would turn the bridge into a navigation bus. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
- **Ambient deep-linkability for every route:** Current route entries have no entry-policy field, so leaving activation ambient would fail open relative to the phase contract. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
- **Primary permission contract based on platform strings:** Apple and Android expose different status vocabularies; Crosswake should normalize instead of leaking them. [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] [CITED: https://developer.apple.com/documentation/avfoundation/avauthorizationstatus] [CITED: https://developer.android.com/training/permissions/requesting]
- **Broad permission dashboard semantics:** Directly conflicts with D-08 and the existing docs-only warning posture. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] [VERIFIED: guides/capabilities.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deep-link route reachability | A second route config system or shell-local allowlist file | Existing Phoenix route metadata -> manifest builder -> shell activation flow | Crosswake already has one route truth pipeline; duplicating it will drift. [VERIFIED: lib/crosswake/policy/router_metadata.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| Dynamic deep-link path matching | Ad hoc regex scattered across shells | One shared segment-aware matching rule mirrored in Elixir and iOS, based on the Android implementation already present | Android already proves the required `:segment` behavior; planner should make other tiers converge on it. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] |
| Permission truth | A generic permission broker or cached app-wide snapshot | OS APIs at query time plus typed normalization | Permission state is platform- and version-sensitive; stale cached truth will become dishonest fast. [CITED: https://developer.android.com/training/permissions/requesting] [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] |
| Notification permission state on Android | Local booleans inferred from previous prompts | `NotificationManagerCompat.areNotificationsEnabled()` and, on API 33+, runtime permission facts in detail | Android exposes the effective notification-enabled check directly. [CITED: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat] |
| Permission requestability as a public primary state | Cross-platform `promptable` or `blocked_forever` enum | Secondary detail only, or later request-flow-specific contracts | Android rationale APIs are guidance for request UX, not a stable public state model. [CITED: https://developer.android.com/training/permissions/requesting] |

**Key insight:** The hard part of Phase 16 is not asking the OS for state. The hard part is preserving Crosswake’s one-source-of-truth posture so route-entry and prerequisite truth remain typed, bounded, and supportable. [VERIFIED: .planning/PROJECT.md]

## Common Pitfalls

### Pitfall 1: Reusing `inactive_route` for entry-denied routes
**What goes wrong:** A route that exists in the manifest but is not approved for external entry is reported as if it does not exist. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**Why it happens:** Current denial vocabulary only distinguishes route absence, compatibility, origin, capability, and packs. [VERIFIED: lib/crosswake/shell/denial.ex]
**How to avoid:** Add a new stable denial reason for entry rejection and keep `route unavailable` as the shared UI surface. [VERIFIED: guides/native_shell.md] [ASSUMED]
**Warning signs:** Doctor/support text cannot tell operators whether they forgot to declare entry approval or shipped the wrong manifest. [VERIFIED: .planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md]

### Pitfall 2: Exact-path matching on some tiers only
**What goes wrong:** Dynamic routes like `/saas/approvals/:id` deep-link on Android but fail on iOS or in Elixir-side activation tests. [VERIFIED: .planning/PROJECT.md] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: lib/crosswake/shell/activation.ex]
**Why it happens:** Android already uses segment-aware matching, while Elixir and iOS still compare literal path strings. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] [VERIFIED: lib/crosswake/shell/activation.ex]
**How to avoid:** Lift Android’s matcher into a shared contract and add cross-tier fixtures for segment routes. [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt]
**Warning signs:** Tests only cover `/dashboard`-style static routes, and no route-entry proof fixture covers `:id` segments. [VERIFIED: test/crosswake/shell/activation_test.exs]

### Pitfall 3: Shipping a primary permission enum that is too rich
**What goes wrong:** Callers branch on states like `not_determined`, `limited`, or `provisional` as if they mean the same thing on both platforms. [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] [CITED: https://developer.apple.com/documentation/photos/phauthorizationstatus?changes=_3] [CITED: https://developer.android.com/training/permissions/requesting]
**Why it happens:** iOS exposes several permission-family-specific statuses, but Android general runtime permission APIs do not expose the same public shape. [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] [CITED: https://developer.android.com/training/permissions/requesting]
**How to avoid:** Keep the primary enum to `granted | denied | restricted`, move platform specifics into `detail`, and treat unsupported aliases as denials, not statuses. [ASSUMED]
**Warning signs:** Public docs start listing per-platform state tables in the main API description instead of the detail appendix. [ASSUMED]

### Pitfall 4: Expanding `permissions.status` beyond near-term proof needs
**What goes wrong:** The bridge becomes a generic permission snapshot or request broker before Crosswake can document and diagnose it honestly. [VERIFIED: guides/capabilities.md] [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**Why it happens:** "Status" sounds harmless, so scope creep is easy. [ASSUMED]
**How to avoid:** Start with the smallest public alias set tied to real downstream phases, and require every alias to have support-matrix and doctor truth. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
**Warning signs:** A planner proposes camera, contacts, location, microphone, or photo-library status in Phase 16 without proof/doctor updates for each alias. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

Verified patterns from current sources:

### Dynamic Path Matching Pattern
```kotlin
// Source: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt
private fun routePathMatches(routePath: String, requestPath: String): Boolean {
    val routeSegments = routePath.trim('/').split('/').filter { it.isNotEmpty() }
    val requestSegments = requestPath.trim('/').split('/').filter { it.isNotEmpty() }

    if (routeSegments.size != requestSegments.size) {
        return false
    }

    return routeSegments.zip(requestSegments).all { (routeSegment, requestSegment) ->
        routeSegment.startsWith(":") || routeSegment == requestSegment
    }
}
```
[VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt]

### Typed Bridge Reply Pattern
```elixir
# Source: lib/crosswake/bridge/contract.ex
Crosswake.Bridge.Contract.ok_reply(request, %{
  "status" => "granted",
  "detail" => %{"platform_status" => "authorized"}
})
```
This is the reply shape pattern Phase 16 should reuse for `permissions.status`, with a typed payload module on the Elixir side. [VERIFIED: lib/crosswake/bridge/contract.ex] [ASSUMED]

### Route Policy Metadata Attachment Pattern
```elixir
# Source: lib/crosswake/policy/router_metadata.ex
compiled = Route.new!(crosswake_options)

metadata
|> Map.put(:crosswake, crosswake_options)
|> Map.put(:crosswake_policy, compiled)
```
This is the correct seam for new route-entry policy fields. [VERIFIED: lib/crosswake/policy/router_metadata.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Exact literal path equality during activation | Segment-aware route matching for manifest paths, already implemented on Android and required project-wide for deep links | Locked in project decisions by 2026-05-19 and still partially unimplemented as of 2026-05-20 | Prevents valid dynamic-segment deep links from failing closed on some tiers. [VERIFIED: .planning/PROJECT.md] [VERIFIED: examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt] [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift] |
| Generic plugin-style permission surfaces | Small normalized primary answer plus optional detail, capability-keyed and read-only | Locked for Phase 16 on 2026-05-20 | Keeps caller ergonomics cross-platform while avoiding dishonest state claims. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] [CITED: https://developer.android.com/training/permissions/requesting] [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] |

**Deprecated/outdated:**
- Treating `deep_link` as a bridge/navigation capability is outdated for this project and explicitly rejected; it remains shell activation truth. [VERIFIED: guides/bridge.md] [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
- Treating `permissions.status` as `example/docs-only` support is outdated for Phase 16 planning, though it is still the current implementation state and must be promoted carefully with proof truth. [VERIFIED: guides/support_matrix.md] [VERIFIED: lib/crosswake/manifest/builder.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The public bridge command should be named `permissions.status.get` to preserve current command naming discipline. | Architecture Patterns / Code Examples | Low; naming can change without altering the core boundary if the planner keeps family-vs-command separation clear. |
| A2 | The primary normalized permission enum should be exactly `granted | denied | restricted`. | Summary / Common Pitfalls | Medium; if the team wants `unknown` or `not_determined` in the primary enum, downstream route logic and docs will need different branching guidance. |
| A3 | The first shipped public alias set should begin with `notifications` only, because it is the clearest near-term prerequisite for Phase 17 while file-picker flows often rely on system pickers rather than runtime permissions. | Summary / Open Questions | Medium; if additional aliases are required immediately, support matrix, doctor, and native adapters expand in scope. |
| A4 | A new denial code such as `entry_not_allowed` is the best machine-readable split for routes that exist but are not approved for external entry. | Pattern 2 / Common Pitfalls | Low; the exact string can vary, but a distinct reason is still required by locked decisions. |

## Open Questions (RESOLVED)

1. **Initial public alias set for `permissions.status`**
   - **Resolution:** Phase 16 should ship with `notifications` as the only public alias.
   - **Why:** It is the clearest near-term prerequisite for later milestone work, has direct doctor/support value, and keeps the first public contract narrow enough to avoid generic permission-broker drift. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] [CITED: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat]
   - **Planning impact:** Any additional alias requires its own proof, doctor coverage, and support-truth updates in a later phase or follow-on plan.

2. **Shape of route-entry policy**
   - **Resolution:** Phase 16 should use a small structured field for route-entry policy, even if the first public value set only expresses external-entry allow/deny.
   - **Why:** Scope defaults plus per-route overrides are already required, and a structured field preserves room for source-specific entry policy later without forcing a second shape migration or collapsing the concept into bridge authority. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md]
   - **Planning impact:** Route policy, manifest serialization, and activation checks should all treat entry policy as explicit route-entry metadata rather than a capability flag or boolean hidden in shell-only config.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core contract, tests, doctor | ✓ | `1.19.5` | — |
| Erlang/OTP | Elixir runtime | ✓ | `28` | — |
| Swift / Xcode | iOS shell activation and permission adapters | ✓ | Swift `6.2`, Xcode `26.0.1` | — |
| Java runtime | Android shell build/proof | ✗ | — | None for actual Android builds |
| Android build tooling | Android shell build/proof | ✗ | — | None until a JDK is installed |

**Missing dependencies with no fallback:**
- Java/JDK for Android shell builds and proof execution. [VERIFIED: environment command output]

**Missing dependencies with fallback:**
- None. The checked-in Android shell cannot be built on this machine until a Java runtime is installed. [VERIFIED: environment command output]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 16 does not change user identity flows directly. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| V3 Session Management | no | This phase should not add client authority over session or navigation state. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | yes | Route-entry approval must stay manifest-backed and fail closed. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| V5 Input Validation | yes | Route-entry metadata and permission aliases should be validated in `Policy.Schema`, `Policy.Validator`, and manifest validation. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/policy/validator.ex] [VERIFIED: lib/crosswake/manifest/validator.ex] |
| V6 Cryptography | no | No new cryptographic surface is introduced here. [VERIFIED: phase scope] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged external entry into an internal route | Elevation of Privilege | Explicit manifest entry policy plus shell-side pre-mount enforcement. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| Confused-deputy navigation through a bridge command | Elevation of Privilege | Do not add outbound deep-link bridge commands; keep navigation outside the bounded bridge. [VERIFIED: .planning/phases/16-system-context-bridges/16-CONTEXT.md] |
| Permission-state spoofing by stale client cache | Tampering | Query platform APIs at call time and treat unsupported aliases as typed denials. [CITED: https://developer.android.com/training/permissions/requesting] [CITED: https://developer.apple.com/documentation/usernotifications/unauthorizationstatus] |
| Overbroad support claims for unsupported aliases or platforms | Repudiation | Extend support matrix and doctor with explicit prerequisites, denial behavior, and proof class per alias. [VERIFIED: .planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md] [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex] |

## Sources

### Primary (HIGH confidence)
- Project planning context: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/milestones/v3.1-CONTEXT.md`, `.planning/phases/16-system-context-bridges/16-CONTEXT.md`
- Prior locked contexts: `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md`, `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md`, `.planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md`, `.planning/phases/15-base-capability-bridges/15-CONTEXT.md`
- Current code truth: `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/router_metadata.ex`, `lib/crosswake/policy/compiler.ex`, `lib/crosswake/policy/validator.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/validator.ex`, `lib/crosswake/shell/activation.ex`, `lib/crosswake/shell/denial.ex`, `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/support_matrix/support_matrix.ex`
- Current native/code-guide truth: `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt`, `examples/phoenix_host/lib/crosswake_example/router.ex`, `guides/native_shell.md`, `guides/bridge.md`, `guides/capabilities.md`, `guides/support_matrix.md`

### Secondary (MEDIUM confidence)
- Apple Developer Documentation: `UNAuthorizationStatus`, `AVAuthorizationStatus`, `PHAuthorizationStatus`, `CNAuthorizationStatus.limited`
- Android Developers: runtime permission guide, `NotificationManagerCompat`

### Tertiary (LOW confidence)
- None. All non-project claims used here were verified against official Apple or Android documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - almost all recommendations extend existing project modules and versioned contracts already present in the repo.
- Architecture: HIGH - the shell activation boundary, manifest pipeline, and support-truth model are all strongly locked by prior phases and current code.
- Pitfalls: HIGH - the key failure modes are directly visible in current code and reinforced by official platform permission docs.

**Research date:** 2026-05-20
**Valid until:** 2026-06-19
