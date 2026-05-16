# Native Shell Guide

Crosswake Phase 3 ships host-owned iOS and Android shells that boot from the bundled
manifest, resolve routes natively first, and fail closed when a route or bridge call
does not satisfy the declared contract.

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

## iOS Notes

- LiveView routes run inside a bounded `WKWebView`.
- Same-origin navigation stays under `WKNavigationDelegate`.
- `Info.plist` configures `WKAppBoundDomains` so App-Bound Domains remain explicit.

## Android Notes

- LiveView routes run inside a bounded `WebView`.
- App entry is normalized through the activation coordinator before `WebView` setup.
- App Links and denial UI stay explicit in the generated host-owned project.

## Proof Hooks

Support claims stay blocked until both generated-project proof hooks pass:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

Without passing proof hooks, doctor reports `verification required` and support
remains narrow. A single passing platform is not enough to widen public claims.

## Bridge Boundary

The shell bridge stays bounded to:

- `app.info.get`
- `haptics.impact`
- `files.pick`

Everything else is denied. Read
[guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md) for the exact
request/reply envelope and denial vocabulary.
