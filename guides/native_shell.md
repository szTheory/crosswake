# Native Shell Guide

Crosswake ships host-owned iOS and Android shells that boot from the bundled
manifest, resolve routes natively first, and fail closed when a route or bridge call
does not satisfy the declared contract. See [guides/adopter_profiles.md](adopter_profiles.md) for adopter-fit framing of the Phoenix SaaS Portal, Selective Native Flow, and Local-First Study Flow lanes.

The checked-in host paths are `checked-in public-coordinate proof`. The generated
shell path stays `generated public-coordinate proof`, and `--local` stays
`local-dev proof` for maintainer iteration.

## Contract

- Shell projects are `host-owned` after generation.
- Activation is `manifest-first` and `native-first`.
- Unsupported routes land on an explicit `route unavailable` surface.
- LiveView routes mount only inside bounded same-origin web containers.
- Bridge calls stay typed, versioned, request/reply-only, and low-frequency.

## Generated Projects

Generate one or both shells:

```sh
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```

Crosswake writes real native projects under:

- `native/ios/crosswake_shell`
- `native/android/crosswake_shell`

Those projects are scaffold-once outputs. Patch or document upgrades after that point;
do not treat them as safely regeneratable overlays.

When you generate shells with the default non-local path, the proof label is
`generated public-coordinate proof`. When you generate with `--local`, the proof
label is `local-dev proof`.

## Manifest-First Activation

Every app-entry path normalizes into one activation request before any web container
exists. The shell resolves the requested route against bundled or cached manifest
truth, checks compatibility, origin allowlists, declared packs, and capability
posture, and only then mounts the declared runtime.

`deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.

## Route Unavailable Surfaces

Crosswake does not silently fall back to a generic web container.

- Denied deep links open a Crosswake-owned `route unavailable` screen.
- In-app activation denials keep the current route stable and interrupt with native UI.
- `pack_incompatible`, `origin_denied`, `inactive_route`, `external_entry_denied`, and compatibility failures stay visible instead of transitioning to a degraded state silently.

## Do I need to rebuild?

Use the change class first:

- `docs-only` applies to guide or release-note updates that do not alter compatibility declarations.
- `core-only/no native rebuild` does not require a shell rebuild when the native runtime line and generated shell contract stay unchanged.
- `compatibility-bump only` may tighten support windows without forcing a fresh binary if the shipped shell/runtime is still compatible.
- `native or companion rebuild required` applies when shell templates, native code, entitlements, permissions, platform configuration, or native dependencies change.

Package class must not imply native ownership. Route ownership still comes from the
route policy and manifest contract.

See the canonical action-class table at `guides/support_matrix.md#action-classes`
and Promotion rules at `guides/support_matrix.md#promotion-rules`.

Promotion rules keep advisory support explicit: StoreKit/Play Billing seams in v3.7 emit reconciliation evidence only, backend projection grants authority, provider/device proof remains advisory unless promotion criteria pass, Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contracts, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, and Phase 58 telemetry/security closeout are shipped, the bridge is not an auth authority, refresh-token helpers, provider/device auth proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI are deferred, notification-token readiness is provider-snapshot only, and standalone native shell core packages are published through SwiftPM and Maven Central at the Crosswake package version.

compatibility-window narrowing is distinct from a native rebuild; it can reject older combinations without changing shell code when the shipped native runtime line remains compatible.

## Proof Hooks

Published shell support is proof-backed by:

- `bash script/verify_phase5_example_hosts.sh`

Generated-host verification remains part of the contract:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

## Native Capture Escape Hatch

Crosswake adds one explicit `:native_screen` escape hatch for `media_capture`. This is a
native screen surface where native code owns the session loop.

- The runtime label stays visible as `Native capture`.
- Captured media is staged locally first.
- Staged media is not yet transferred.
- Transfer completion is separate from local capture.
- `:adapter` remains deferred.

Crosswake does not silently fall back into a bounded web upload flow. If a route
declares native capture, the shell opens the declared native surface or fails closed.

## Native Commerce Corridors

Declared native commerce routes require the appropriate companion/runtime line and must show explicit fail-closed unavailable guidance when prerequisites are missing. Storefront-sensitive flows like purchase confirmation or native SDK loops run inside explicit native surfaces. Crosswake does not silently fall back to generic web checkouts when native commerce prerequisites are unmet.

## Bridge Boundary

The shell bridge stays bounded to:

- `app.info.get`
- `haptics.impact`
- `permissions.status`
- `files.pick`
- `transfer.download`
- `transfer.export`
- `transfer.import`
- `transfer.upload.prepare`

Everything else is denied.

`permissions.status` is intentionally narrow in Phase 16: it is read-only, one-shot, and supports the `notifications` alias only. It does not request permissions, observe background changes, or expose a generic permission dashboard.

## Boundary Warnings & Rough Edges

- Command-only bridge, not a generic message bus
- No silent fallbacks
- Host ownership responsibility after generation
- Explicit rebuild expectations whenever native or companion code changes

## Permission and Entitlement Templates

When a native runtime or capability requires explicit permissions or platform entitlements, the generated shell projects include permission/entitlement templates. You must manually manage these as part of your host-owned shell. A rebuild is required when these change.

## Diagnostics Export

The diagnostics export seam allows telemetry and diagnostic state to be securely transmitted. See the privacy and diagnostics guidelines.

## Android Verification

Generated Android shell artifacts are supported based strictly on `JVM hermetic proof`.

## Android Device-UAT

For Android, device-UAT and emulator verification lanes are currently advisory.
Use `device evidence` only for named physical-device runs. `JVM hermetic proof`
does not prove emulator evidence or physical-device support.
