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

## Bounded First-Adopter iOS Navigation

Phase 161.1 verifies the bounded iOS-only compiled topology, typed stack protocol,
UIKit host composition, marker/insets, and generated host proof. Simulator evidence
is advisory, TODO-002/adopter topology remains `unknown_blocking`, and physical-iPhone
promotion is Phase 162 only.

This is not generic navigation, native leaf rendering, arbitrary restoration or modal
breadth, browser-history authority, or Android parity. Invalid navigation input keeps
the existing explicit Phoenix denial rather than silently falling back to generic
WebView navigation.

Phoenix-owned confirmation is the current required fallback on every platform. Native alert/confirm is stopped and may be reconsidered only after passed physical-iPhone proof, a demonstrated active-adopter route blocker, and an explicit maintainer roadmap decision.

Android retains its frozen generator, Maven, JVM, and shared-vector posture. No new
Android feature, parity, template, emulator/device, or release requirement is active.
No URL, route payload/history, account, device, token, stable ID, screenshot,
transcript, or raw test output is retained as shell-proof evidence.

## Generated Projects

Generate one or both shells:

```sh
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```

Crosswake writes real native projects under:

- `native/ios/crosswake_shell`
- `native/android/crosswake_shell`

Native Swift, entitlements, and project customizations remain host-owned. The Android
generator remains scaffold-once. For iOS, the declared host path below can refresh only
recognized Crosswake-managed manifest, activation, and build-setting outputs; it does
not make the native project a general regeneratable overlay.

## Declared iOS Host Setup

For a production iOS host, declare the build inputs once in the host's ordinary
Phoenix/Mix configuration. `MIX_ENV` selects the normal environment; generation
requires the compiled router but does not start the Phoenix application, evaluate
`runtime.exs`, or load unrelated runtime-server credentials.

```elixir
config :crosswake, :ios_host,
  router: MyAppWeb.Router,
  origin: "https://study.crosswake.test",
  entry_route_id: "study-session",
  app_bundle_id: "org.crosswake.host",
  proof_app_bundle_id: "org.crosswake.host.proof",
  device_signing: [mode: :automatic, team_id: "ABCDE12345"]
```

The declaration accepts exactly `router`, `origin`, `entry_route_id`,
`app_bundle_id`, `proof_app_bundle_id`, and `device_signing`. The origin must be an
absolute HTTPS origin without a path, query, fragment, credentials, or example host;
the entry must be declared by the selected router. The app and proof app identities
must be distinct. Crosswake derives the shell unit-test identity by adding `.tests`
to `app_bundle_id`, and derives the proof unit/UI test identities by adding `.tests`
and `.uitests` to `proof_app_bundle_id`.

For an existing generated iOS host, inspect its recognized managed outputs and project
settings first:

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --diff
```

For a new host, generate from the declaration, then inspect the managed outputs:

```sh
MIX_ENV=prod mix crosswake.gen.shell ios
MIX_ENV=prod mix crosswake.gen.shell ios --check
```

`--diff` and `--check` do not write files. They report safe path/status causes and a
repair command without printing declared values. `--check` fails if managed outputs
are missing, stale, conflicted, or part of an interrupted update. After a passing
check, build the generated Xcode project with the host's normal build settings. For
example, an unsigned simulator build can use:

```sh
xcodebuild -project native/ios/crosswake_shell/CrosswakeShell.xcodeproj \
  -scheme CrosswakeShell -configuration Debug -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO build
```

If an interrupted managed-output update is reported, review the staged generation,
run the explicit recovery, and check again:

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --recover
MIX_ENV=prod mix crosswake.gen.shell ios --check
```

Recovery applies only the recognized prior managed state and refuses a conflicting
host edit. If `--diff` reports that a recognized existing project needs the managed
settings hook, the bounded opt-in migration is:

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --migrate-project-settings
MIX_ENV=prod mix crosswake.gen.shell ios --check
```

That migration updates only the known shell target configuration blocks. It removes
identity/signing overrides in those blocks so the managed xcconfig owns those values;
unrelated PBX customization remains host-owned. If the project structure or target
settings have changed outside the recognized form, migration refuses with an
`unrecognized_project` cause. Review and reconcile that project change manually
before trying the bounded migration again; do not replace the whole PBX file.

`CrosswakeHostSettings.xcconfig` owns the declared shell app identity and signing
settings, and is kept out of bundled app resources. Swift sources, entitlements, and
other host project edits stay host-owned. The shell build is unsigned for simulator
SDKs. Device SDK settings reflect the declared automatic/manual style and team ID,
but checking those settings does not sign, install, or prove support on a physical
iPhone.

The generated manifest and entry activation carry the selected route and primary
origin as static configuration. They grant no session, account, scope, installed
media, or replay authority. Existing `mix crosswake.gen.proof_lane --config PATH`
continues to own unrelated proof-lane settings; it is not a second iOS host
declaration.

The legacy `--router` and `--local` invocation remains available for local/dev use
when no `:crosswake, :ios_host` declaration is selected. With the declaration,
production inputs cannot be silently replaced by those flags. Use only non-production
example values in documentation and tests; a first adopter's real host values belong
in that host's private configuration.

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
