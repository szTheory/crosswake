# Native Shell Guide

Crosswake Phase 3 ships host-owned iOS and Android shells that boot from the bundled
manifest, resolve routes natively first, and fail closed when a route or bridge call
does not satisfy the declared contract.

For product-fit context, read
[guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md)
before using this guide as the deeper shell and native-ownership reference.

## Contract

- Shell projects are `host-owned` after generation.
- Activation is `manifest-first` and `native-first`.
- Unsupported routes land on an explicit `route unavailable` surface.
- LiveView routes mount only inside bounded same-origin web containers.
- Bridge calls stay typed, versioned, request/reply-only, and low-frequency.

For the Phase 7 `Phoenix SaaS Portal` lane, that means authenticated approvals stay
Phoenix-owned inside the shell. The shell may supply one bounded confirmation signal,
but it does not take control of auth or product writes.

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
exists:

- cold start
- deep link / universal link / App Link
- in-app navigation

The shell resolves the requested route against bundled or cached manifest truth,
checks compatibility, origin allowlists, declared packs, and capability posture, and
only then mounts the declared runtime.

## Route Unavailable Surfaces

Crosswake does not silently fall back to a generic web container.

- Denied deep links open a Crosswake-owned `route unavailable` screen.
- In-app activation denials keep the current route stable and interrupt with native UI.
- `pack_incompatible`, `origin_denied`, `inactive_route`, and compatibility failures
  stay visible instead of degrading silently.

The route unavailable surface is part of the product contract, not cleanup work.

For the SaaS lane, `route unavailable` remains the primary degraded behavior:
authentication still belongs to the host, and denied activation stays explicit rather
than degrading into a generic web wrapper.

## iOS Notes

- LiveView routes run inside a bounded `WKWebView`.
- Same-origin navigation stays under `WKNavigationDelegate`.
- `Info.plist` configures `WKAppBoundDomains` so App-Bound Domains remain explicit.

## Android Notes

- LiveView routes run inside a bounded `WebView`.
- App entry is normalized through the activation coordinator before `WebView` setup.
- App Links and denial UI stay explicit in the generated host-owned project.

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

The checked-in example hosts are the public artifact class. `--native-checks` reruns
the generated-host verification hooks against your local shell projects so your
workstation support posture stays explicit.

For exact support status, keep
[guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md)
as the canonical surface and
[guides/install.md](/Users/jon/projects/crosswake/guides/install.md) as the canonical
proof-entry surface.

## Native Capture Escape Hatch

Phase 5 adds one explicit `:native_screen` escape hatch for media capture.

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

Everything else is denied. Read
[guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md) for the exact
request/reply envelope and denial vocabulary.
