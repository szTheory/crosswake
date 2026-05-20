# Crosswake

> **Declare the crossing.**
> Phoenix-native route policy for apps that go mobile.

Crosswake is an open-source Elixir library for shipping iOS and Android apps from
Phoenix applications without pretending one runtime should own every screen.
Server-centric routes can stay LiveView, device-heavy flows can move into explicit
native screens, and local-first work can live in honest offline islands.

## What this is

Crosswake gives Phoenix apps a mobile runtime contract built around:

- route policy
- a versioned runtime manifest
- host-owned native shells
- a bounded bridge for low-frequency native affordances
- explicit pack and transfer seams
- offline islands and cached read-only routes

The core idea is simple: **runtime ownership is explicit per route**.

## What this is not

Crosswake is not:

- React Native for Phoenix
- a generic WebView wrapper
- LiveView rendering native UI directly
- a universal shared UI framework
- “write once, run anywhere”
- “offline magically works”

## Choose your path

### Evaluating Crosswake

Start with:

- [guides/adopter_profiles.md](guides/adopter_profiles.md) for the three target app shapes
- [guides/install.md](guides/install.md) for the public install and proof path
- [guides/support_matrix.md](guides/support_matrix.md) for the current supported baseline
- [examples/phoenix_host/README.md](examples/phoenix_host/README.md) for the shared exemplar host contract

### Integrating Crosswake

Use the current host-owned path:

```bash
mix deps.get
mix crosswake.install
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

Then run the checked-in proof lane:

```bash
bash script/verify_phase5_example_hosts.sh
```

Crosswake owns the DSL, manifest contract, doctor tooling, and proof posture.
Your Phoenix host and generated shells are **host-owned** after generation.

### Contributing or maintaining

Read:

- [AGENTS.md](AGENTS.md)
- [guides/install.md](guides/install.md)
- [guides/native_shell.md](guides/native_shell.md)
- [guides/packs.md](guides/packs.md)
- [guides/offline.md](guides/offline.md)

The checked-in example hosts under `examples/` are the primary public proof artifacts.

## Architecture at a glance

Crosswake is strongest when teams can answer these route-by-route questions clearly:

- Which routes stay `:live_view`?
- Which routes can be cached read-only?
- Which flows need an `:offline_island`?
- Which routes must become `:native_screen`?
- Which capabilities, packs, transfers, and security posture does each route need?

The current runtime ladder is:

1. `:live_view`
2. `:live_view` inside a native shell
3. `:live_view` plus bounded native affordances
4. cached read-only routes
5. `:offline_island`
6. `:native_screen`

## Where Crosswake fits

Crosswake is currently shaped around three adopter profiles:

- **Phoenix SaaS Portal**: mostly LiveView, one bounded native affordance
- **Selective Native Flow**: mostly Phoenix-owned, one explicit native route
- **Local-First Study Flow**: one honest offline island plus cached neighbors

See [guides/adopter_profiles.md](guides/adopter_profiles.md) for the profile matrix,
representative routes, and explicit non-goals.

## Proof and support posture

Crosswake treats diagnostics, support truth, and proof lanes as part of the product
surface.

- [guides/support_matrix.md](guides/support_matrix.md) is the canonical support-status surface.
- [guides/install.md](guides/install.md) is the canonical install and proof-entry guide.
- `bash script/verify_phase5_example_hosts.sh` is the primary checked-in proof lane.
- `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` reruns the local generated-shell verification hooks.

Crosswake stays deliberately narrow and explicit. Unsupported or incompatible routes
fail closed onto explicit denial behavior instead of silently degrading into a generic
container.

## Guide map

- [guides/install.md](guides/install.md) — Phoenix install path and native shell generation
- [guides/native_shell.md](guides/native_shell.md) — manifest-first activation and shell contract
- [guides/bridge.md](guides/bridge.md) — bounded bridge vocabulary
- [guides/packs.md](guides/packs.md) — required packs, transfers, and native capture handoff
- [guides/offline.md](guides/offline.md) — cached read-only and offline-island posture
- [guides/compatibility.md](guides/compatibility.md) — compatibility and denial posture

## Current baseline

- Elixir `~> 1.19`
- Phoenix `~> 1.8`
- Phoenix LiveView `~> 1.1`
- Crosswake version `0.1.0`

See [mix.exs](mix.exs) and [guides/support_matrix.md](guides/support_matrix.md) for
the current package and platform baseline.
