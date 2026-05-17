# Crosswake Install Guide

Crosswake now exposes one install path for the Phoenix host and one scaffold-once path
for the host-owned native shells:

1. `mix crosswake.install`
2. `mix crosswake.gen.shell ios|android`
3. `mix crosswake.doctor --router Elixir.YourAppWeb.Router`
4. `bash script/verify_phase5_example_hosts.sh`
5. `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks`

The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation. Crosswake owns the DSL, manifest contract, doctor surface, and
proof posture. It does not re-own your app files after scaffolding.

If you are deciding whether your app pressure is mostly LiveView, one explicit
native route, or one honest offline island, read
[guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md)
before drilling into the deeper shell, offline, or pack contracts.

Phase 7 extends the checked-in proof lane with the `Phoenix SaaS Portal` exemplar:
an approvals-led, host-owned auth surface that stays mostly `:live_view`, fails closed
with `route unavailable`, and uses one bounded haptics confirmation seam. Support
status still lives in
[guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md);
this guide stays the canonical proof-entry surface.

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
  `guides/support_matrix.md`, `guides/native_shell.md`, `guides/bridge.md`, and
  `guides/packs.md`

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
- it does not turn unsupported routes into generic container fallback
- it does not widen Phase 5 beyond explicit packs, explicit transfers, and one
  native-capture `:native_screen`

Read [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md) for
the shell contract and [guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md)
for the bounded bridge contract. Read
[guides/packs.md](/Users/jon/projects/crosswake/guides/packs.md) for the required-pack,
transfer, and native-capture handoff contract.

## Step 3: Verify Host And Manifest Truth

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

This checks install state, manifest truth, shell generation posture, bounded bridge
truth, and the fail-closed denial vocabulary. Without `--native-checks`, doctor keeps
your local host verification explicit even though the published Phase 5 support matrix
is already proof-backed.

## Step 4: Run The Public Proof Lane

Run:

```sh
bash script/verify_phase5_example_hosts.sh
```

This is the primary proof artifact class Crosswake publishes for adopters. It verifies:

- the checked-in Phoenix example host route truth
- the checked-in Phoenix SaaS Portal boundary wording and proof hooks
- the checked-in iOS example host build/install/launch path
- the checked-in Android example host unit + connected-test path

## Step 5: Re-Run Local Generated-Host Verification

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

With `--native-checks`, doctor executes the generated-host verification hooks:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

The generated-host hooks are secondary verification. They should stay green alongside
the checked-in example hosts, but the public install path is anchored on the example
hosts rather than private local scaffolding.

## Generated Artifact Inventory

Phoenix host artifacts:

- `lib/<app>_web/router.ex`
- `lib/<app>_web/crosswake/policy.ex`
- `priv/crosswake/install_manifest.json`

Native shell artifacts:

- `native/ios/crosswake_shell/*`
- `native/android/crosswake_shell/*`
- `examples/phoenix_host/*`
- `examples/ios_shell_host/*`
- `examples/android_shell_host/*`
- `script/verify_phase5_example_hosts.sh`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

## Ownership Boundary

Crosswake deliberately stays Phoenix-first. Route truth lives in the router and
manifest, runtime activation stays manifest-first, bridge calls stay typed and
low-frequency, pack and transfer work stays foreground-first, and route unavailable
behavior stays explicit. Crosswake is not a generic WebView wrapper.
