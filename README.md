<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header-dark.svg">
    <img src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/readme-header.svg" alt="Crosswake">
  </picture>
</p>

# Crosswake

> **Declare the crossing.**
> Phoenix-native route policy for apps that go mobile.

Crosswake is an open-source Elixir library for shipping iOS and Android apps from
Phoenix applications without pretending one runtime should own every screen.
Server-centric routes can stay LiveView, device-heavy flows can move into explicit
native screens, and local-first work can live in honest offline islands.

Crosswake's one job is to declare, enforce, and diagnose which runtime owns each
route as a Phoenix app crosses into mobile.

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

## See it run

```bash
bin/see-it-run.sh
```

Boots the shared backend on port 4700 and auto-opens `http://localhost:4700/`,
the showcase hub for the checked-in example host. Requires Docker.

<img
  src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/three-runtime-montage.png"
  alt="Three-runtime Crosswake comparison: web (localhost:4700), iOS Simulator (emulator evidence — advisory native, not a physical device), Android Emulator (emulator evidence — advisory native, not a physical device)"
  width="900"
/>

Open the showcase hub first at `http://localhost:4700/`. It introduces the
SaaS/Admin, Field Service, and Learning/Training lanes with route-owner labels
before asking you to inspect proof routes.

The root route `/` — home showcase hub, LiveView route, cached read-only — is
the newcomer entrypoint for this checked-in host.

Proof routes stay one click deeper and are secondary to the product-shaped
showcase:

- `/offline` — offline island (app-owned, socketless)
- `/bridge-proof` — bounded bridge (share capability)
- `/native/claims` — native-pressure route list

Support-truth labels in this first run stay narrow: `Available today` and
`Proof-backed example` describe web proof surfaces, while `Demo pressure` and
`Future gap` describe native-control candidates that are not shipped broadly.
Showcase screenshots explain the product surface; route-tour assertions prove
route-owner semantics.

**Read Capability Map:** [guides/capability_map.md](guides/capability_map.md)
separates available support, proof-backed examples, demo pressure, future gaps,
and v20 next-pack candidates. Screenshots remain collateral after route-tour
assertions, not proof posture.

> **Advisory native collateral.** The iOS Simulator and Android Emulator frames above are
> `emulator evidence` — advisory, not physical-device proof. A successful simulator or
> emulator run confirms the dev wiring reaches the local backend, but does not prove
> it works on a physical device. See the
> [support-truth label legend](guides/support_matrix.md#support-truth-label-legend).

For a guided walkthrough: [guides/see_it_run.md](guides/see_it_run.md).
For the full proof command reference: [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md).

## Choose your path

### Evaluating Crosswake

Start with:

- [guides/route_policy.md](guides/route_policy.md) for the start-here route-owner map
- [guides/web_to_mobile_migration.md](guides/web_to_mobile_migration.md) for an operational Phoenix route inventory pass
- [guides/user_flows.md](guides/user_flows.md) for the fastest JTBD and user-flow ramp-up
- [guides/adopter_profiles.md](guides/adopter_profiles.md) for the three target app shapes
- [guides/install.md](guides/install.md) for the public install and proof path
- [guides/support_matrix.md](guides/support_matrix.md) for the current supported baseline
- [examples/phoenix_host/README.md](https://github.com/szTheory/crosswake/blob/main/examples/phoenix_host/README.md) for the shared exemplar host contract

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

- [AGENTS.md](https://github.com/szTheory/crosswake/blob/main/AGENTS.md)
- [guides/install.md](guides/install.md)
- [guides/native_shell.md](guides/native_shell.md)
- [guides/packs.md](guides/packs.md)
- [guides/offline.md](guides/offline.md)
- [docs/COMPANION-PUBLISH-RUNBOOK.md](docs/COMPANION-PUBLISH-RUNBOOK.md) and `mix crosswake.release.status [--json] [--live]` for package-family release status.

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
For the fastest "how would I actually use this in my app?" pass, start with
[guides/user_flows.md](guides/user_flows.md).

## Proof and support posture

Crosswake treats diagnostics, support truth, and proof lanes as part of the product
surface.

- [guides/support_matrix.md](guides/support_matrix.md) is the canonical support-status surface.
- [guides/support_matrix.md#support-truth-label-legend](guides/support_matrix.md#support-truth-label-legend) defines support-truth labels: merge-blocking proof, advisory evidence, checked-in public-coordinate proof, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, and rebuild-required.
- [guides/troubleshooting.md](guides/troubleshooting.md) maps doctor findings, denial reasons, route-unavailable states, offline replay outcomes, and native evidence labels to route-owner fixes.
- [guides/install.md](guides/install.md) is the canonical install and proof-entry guide.
- The checked-in `examples/ios_shell_host` and `examples/android_shell_host` hosts are `checked-in public-coordinate proof`; use `--local` only for maintainer/local-dev proof.
- `bash script/verify_phase5_example_hosts.sh` is the primary checked-in proof lane.
- The route-tour evidence path uses `merge-blocking proof` for browser semantic assertions, manifest labels for artifacts, and `advisory evidence` for native simulator/emulator collateral.
- `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` reruns the local generated-shell verification hooks.

Crosswake stays deliberately narrow and explicit. Unsupported or incompatible routes
fail closed onto explicit denial behavior instead of silently degrading into a generic
container.

## Guide map

- [guides/install.md](guides/install.md) — Phoenix install path and native shell generation
- [guides/route_policy.md](guides/route_policy.md) — start-here route-owner decisions and DSL examples
- [guides/web_to_mobile_migration.md](guides/web_to_mobile_migration.md) — route inventory pass for existing Phoenix SaaS apps
- [guides/user_flows.md](guides/user_flows.md) — JTBD and route-by-route adopter ramp-up
- [guides/native_shell.md](guides/native_shell.md) — manifest-first activation and shell contract
- [guides/bridge.md](guides/bridge.md) — bounded bridge vocabulary
- [guides/packs.md](guides/packs.md) — required packs, transfers, and native capture handoff
- [guides/offline.md](guides/offline.md) — cached read-only and offline-island posture
- [guides/compatibility.md](guides/compatibility.md) — compatibility and denial posture
- [guides/support_matrix.md](guides/support_matrix.md) — proof classes, support labels, and rebuild truth
- [guides/troubleshooting.md](guides/troubleshooting.md) — route-owner fixes for doctor findings, denials, offline outcomes, and native evidence labels

## Current baseline

- Elixir `~> 1.19`
- Phoenix `~> 1.8`
- Phoenix LiveView `~> 1.1`
- Crosswake version `0.2.0` <!-- x-release-please-version -->
- Generated non-local native shell core coordinates resolve at the Crosswake package version.

See [mix.exs](mix.exs) and [guides/support_matrix.md](guides/support_matrix.md) for
the current package and platform baseline.
