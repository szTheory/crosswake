# Native Shell Guide

Crosswake ships host-owned iOS and Android shells that boot from the bundled
manifest, resolve routes natively first, and fail closed when a route or bridge call
does not satisfy the declared contract. See [guides/adopter_profiles.md](adopter_profiles.md) for adopter-fit framing of the Phoenix SaaS Portal, Selective Native Flow, and Local-First Study Flow lanes.

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
- `pack_incompatible`, `origin_denied`, `inactive_route`, and compatibility failures stay visible instead of transitioning to a degraded state silently.

## Rebuild Guidance

Use the change class first:

- `core-only/no native rebuild` does not require a shell rebuild when the native runtime line and generated shell contract stay unchanged.
- `compatibility-bump only` may tighten support windows without forcing a fresh binary if the shipped shell/runtime is still compatible.
- `native or companion rebuild required` applies when shell templates, native code, entitlements, permissions, platform configuration, or native dependencies change.

Package class must not imply native ownership. Route ownership still comes from the
route policy and manifest contract.

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

## Bridge Boundary

The shell bridge stays bounded to:

- `app.info.get`
- `haptics.impact`
- `files.pick`
- `transfer.download`
- `transfer.export`
- `transfer.import`
- `transfer.upload.prepare`

Everything else is denied.

## Boundary Warnings & Rough Edges

- Command-only bridge, not a generic message bus
- No silent fallbacks
- Host ownership responsibility after generation
- Explicit rebuild expectations whenever native or companion code changes
