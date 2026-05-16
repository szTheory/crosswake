# Crosswake Install Guide

Crosswake now exposes one install path for the Phoenix host and one scaffold-once path
for the host-owned native shells:

1. `mix crosswake.install`
2. `mix crosswake.gen.shell ios|android`
3. `mix crosswake.doctor --router Elixir.YourAppWeb.Router`
4. `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks`

The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation. Crosswake owns the DSL, manifest contract, doctor surface, and
proof posture. It does not re-own your app files after scaffolding.

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
- points follow-up diagnostics at `mix crosswake.doctor`, `guides/compatibility.md`,
  `guides/support_matrix.md`, `guides/native_shell.md`, and `guides/bridge.md`

Repeated installer runs are idempotent. Existing marker blocks are reused instead
of duplicating router edits, and existing host-owned policy files are left alone.

## Step 2: Generate Host-Owned Native Shells

Run one of:

```sh
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```

What it does:

- creates a host-owned shell project under `native/<platform>/crosswake_shell`
- bundles the canonical manifest, activation, route-unavailable, and declared-pack fixtures
- scaffolds manifest-first activation, explicit route unavailable UI, and the bounded
  bridge channel for `app.info.get`, `haptics.impact`, and `files.pick`

What it does not do:

- it does not safely regenerate over host edits
- it does not broaden support claims past the generated-project proof hooks
- it does not turn unsupported routes into generic container fallback

Read [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md) for
the shell contract and [guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md)
for the bounded bridge contract.

## Step 3: Verify Host And Manifest Truth

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

This checks install state, manifest truth, shell generation posture, bounded bridge
truth, and the fail-closed denial vocabulary. If shell proof hooks have not been
executed yet, doctor reports `verification required` and blocks support claims.

## Step 4: Run Generated-Project Proof Hooks

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

With `--native-checks`, doctor executes:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Crosswake publishes shell support only when both generated-project proof hooks pass
on the same host-owned artifact class adopters ship. Until then, iOS and Android
support remains `verification required`.

## Generated Artifact Inventory

Phoenix host artifacts:

- `lib/<app>_web/router.ex`
- `lib/<app>_web/crosswake/policy.ex`
- `priv/crosswake/install_manifest.json`

Native shell artifacts:

- `native/ios/crosswake_shell/*`
- `native/android/crosswake_shell/*`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

## Ownership Boundary

Crosswake deliberately stays Phoenix-first. Route truth lives in the router and
manifest, runtime activation stays manifest-first, bridge calls stay typed and
low-frequency, and route unavailable behavior stays explicit. Crosswake is not a
generic WebView wrapper and does not claim shell support ahead of proof.
