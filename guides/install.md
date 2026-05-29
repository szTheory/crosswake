# Crosswake Install Guide

Crosswake keeps one primary package surface: `crosswake`. Companion-ready and
docs-only surfaces stay explicit, but there is still one primary install path for the
Phoenix host and one scaffold-once path for host-owned native shells.

1. `mix crosswake.install`
2. `mix crosswake.gen.shell ios|android`
3. `mix crosswake.doctor --router Elixir.YourAppWeb.Router`
4. `bash script/verify_phase5_example_hosts.sh`
5. `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks`

The generated Phoenix and native files are `host-owned`, reviewable, and editable
after generation. Crosswake owns the DSL, manifest contract, doctor surface, support
matrix, and release-boundary policy. It does not re-own your app files after scaffolding.

## Package Surface

There is one primary `crosswake` package plus explicitly bounded companion-ready and
docs-only surfaces. Package class does not override route ownership.

If you are deciding whether your app pressure is mostly LiveView, one explicit
native route, or one honest offline island, read
[guides/adopter_profiles.md](adopter_profiles.md)
for the Phoenix SaaS Portal, Selective Native Flow, and Local-First Study Flow profiles
before drilling into the deeper shell, offline, or pack contracts.

## Add Crosswake To Your Dependencies

Add `crosswake` to the deps in your Phoenix host's `mix.exs`:

```elixir
def deps do
  [
    {:crosswake, "~> 0.1"}
  ]
end
```

Then fetch it:

```sh
mix deps.get
```

## Step 1: Install Crosswake Into A Phoenix Host

Run:

```sh
mix crosswake.install
```

What it does:

- patches `lib/<app>_web/router.ex` with explicit Crosswake marker lines
- keeps LiveView router imports compatible with the Crosswake `live` macro
- generates a host-owned policy module at `lib/<app>_web/crosswake/policy.ex`
- writes `priv/crosswake/install_manifest.json` so later tooling can inspect what Crosswake created or reused
- points follow-up diagnostics at `mix crosswake.doctor`, `guides/compatibility.md`, `guides/support_matrix.md`, `guides/native_shell.md`, `guides/bridge.md`, and `guides/packs.md`

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
- scaffolds manifest-first activation, explicit route unavailable UI, and the bounded bridge channel

What it does not do:

- it does not safely regenerate over host edits
- it does not turn unsupported routes into generic container fallback
- it does not widen support beyond explicit, proof-backed surfaces

Read [guides/native_shell.md](native_shell.md) for
the shell contract and [guides/bridge.md](bridge.md)
for the bounded bridge contract.

## Step 3: Verify Host And Manifest Truth

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

This checks install state, manifest truth, shell generation posture, bounded bridge
truth, release policy posture, and fail-closed denial vocabulary.

## Step 4: Run The Public Proof Lane

Run:

```sh
bash script/verify_phase5_example_hosts.sh
```

This is the primary proof artifact class Crosswake publishes for adopters.

## Step 5: Re-Run Local Generated-Host Verification

Run:

```sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

With `--native-checks`, doctor executes the generated-host verification hooks:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

## Do I need to rebuild?

Use the four public change classes first, before raw version numbers:

- `docs-only` -> read the updated guidance and run docs integrity only
- `core-only/no native rebuild` -> update core and rerun core contract + doctor/support proof
- `compatibility-bump only` -> confirm your compatibility window and run fail-closed compatibility fixtures
- `native or companion rebuild required` -> rebuild the affected shell or companion and rerun generated-shell or companion verification lanes

The matching proof lanes are:

- docs integrity only
- core contract + doctor/support proof
- fail-closed compatibility fixtures
- generated-shell or companion verification lanes

The generated support matrix remains authoritative:
[guides/support_matrix.md](support_matrix.md)

## Docs-Only Install Boundary

The install walkthrough is useful product guidance, but it is `not first-class supported`
as a separate package surface. It teaches the primary `crosswake` install path and the
boundary between host-owned artifacts and Crosswake-owned contract surfaces.

### Route owner

Install guidance does not change route ownership. Phoenix routes remain Phoenix-owned unless a route policy explicitly declares otherwise.

### Why not core/companion

This walkthrough explains package and artifact boundaries. It is not itself a runtime package, and it does not promote host scaffolding into a companion surface.

### Host-owned responsibilities

The host reviews generated files, owns shell project edits after generation, reruns proof hooks, and decides when local rebuilds are needed.

### Prerequisites

A Phoenix host, explicit router wiring, generated policy module, and the proof scripts referenced by the support matrix.

### Denial behavior

If install or compatibility truth is incomplete, `mix crosswake.doctor` reports blocking issues instead of inferring that the host is correctly wired.

### Fallback behavior

Crosswake falls back to explicit diagnostics and route-unavailable posture, not silent package promotion or generic shell behavior.

### Native rebuild required

Only when your change lands in the `native or companion rebuild required` class. Docs-only install guidance and core-only policy changes do not automatically imply a native rebuild.
