# Crosswake Install Guide

Crosswake Phase 1 exposes a two-step, additive setup path:

1. `mix crosswake.install`
2. `mix crosswake.gen.shell ios|android`

The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation. Crosswake owns the DSL, router-local compile-time validation,
and setup tasks; it does not retain ownership of your app files after they are
created.

## Phase 1 Public Contract

- Runtime classes are `:live_view`, `:offline_island`, and `:native_screen`.
- Policy is authored `router-local` next to Phoenix routes through `crosswake: [...]`
  metadata and `crosswake_defaults`.
- Compile-time validation in Phase 1 checks local declaration shape and contradictions.
- `adapter remains reserved` for later extension. It is not a usable Phase 1 runtime.

## Step 1: Install Crosswake Into A Phoenix Host

Run:

```sh
mix crosswake.install
```

What it does:

- patches `lib/<app>_web/router.ex` with explicit Crosswake marker lines
- keeps LiveView router imports compatible with the Crosswake `live` macro
- generates a host-owned policy module at `lib/<app>_web/crosswake/policy.ex`
- writes `priv/crosswake/install_manifest.json` so later tooling can inspect what
  Crosswake created or reused

Repeated installer runs are idempotent. Existing marker blocks are reused instead
of duplicating router edits, and existing host-owned policy files are left alone.

## Step 2: Generate A Native Shell Skeleton

Run one of:

```sh
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```

What it does:

- creates a narrow shell skeleton under `native/<platform>/crosswake_shell`
- includes ownership docs that say the generated shell is host-owned and editable
- bundles a local fixture describing the Phase 1 route-policy handoff

What it does not do in Phase 1:

- it does not prove shell boot
- it does not activate runtime manifests
- it does not claim bridge behavior or Phase 3 runtime support

## Generated Artifact Inventory

Phoenix host artifacts:

- `lib/<app>_web/router.ex` - patched with explicit Crosswake markers
- `lib/<app>_web/crosswake/policy.ex` - host-owned policy entrypoint
- `priv/crosswake/install_manifest.json` - machine-readable scaffold manifest

Native shell artifacts:

- `native/ios/crosswake_shell/README.md`
- `native/ios/crosswake_shell/Sources/AppShell.swift`
- `native/ios/crosswake_shell/Fixtures/phase1_route_policy.json`
- `native/android/crosswake_shell/README.md`
- `native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/AppShell.kt`
- `native/android/crosswake_shell/app/src/main/assets/phase1_route_policy.json`

## Ownership Boundary

Crosswake deliberately avoids a `crosswake.new` full-app template in Phase 1. The
installer and generator make ownership boundaries explicit: route truth stays in the
router, compile-time checks stay local, and generated Phoenix or native files are
user-owned after scaffolding.
