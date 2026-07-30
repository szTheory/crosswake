# Crosswake Install Guide

Crosswake keeps one primary package surface: `crosswake`. Companion-ready and
docs-only surfaces stay explicit, but there is still one primary install path for the
Phoenix host and one scaffold-once path for host-owned native shells.

> Start with [guides/route_policy.md](route_policy.md) for route-owner decisions and
> [guides/web_to_mobile_migration.md](web_to_mobile_migration.md) for an operational
> Phoenix route inventory pass.
> See [guides/adoption.md](adoption.md) for offline-sync architecture context and the rationale for the generated shell pattern.

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
and [guides/web_to_mobile_migration.md](web_to_mobile_migration.md)
for the route inventory pass before drilling into the deeper shell, offline, or pack
contracts. Use [guides/route_policy.md](route_policy.md) as the owner-decision map.

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
- patches `lib/<app>_web/endpoint.ex` with the static plug block that serves the bridge hook
- generates a host-owned policy module at `lib/<app>_web/crosswake/policy.ex`
- writes `priv/crosswake/install_manifest.json` so later tooling can inspect what Crosswake created or reused
- prints the layout wiring it deliberately does not patch (see Step 1b)
- points follow-up diagnostics at `mix crosswake.doctor`, `guides/compatibility.md`, `guides/support_matrix.md`, `guides/native_shell.md`, `guides/bridge.md`, and `guides/packs.md`

Repeated installer runs are idempotent. Existing marker blocks are reused instead
of duplicating router edits, and existing host-owned policy files are left alone.

## Step 1b: Wire The Bridge Hook

The client half of the bridge is one dependency-free ESM file that ships from
Crosswake's own `priv/static/`. It is library-owned on purpose: its single most
important job is reporting the "no native transport is reachable" fact, which is what
turns a missing shell into an honest typed denial instead of silence. Crosswake does
not generate a host-owned copy of it and does not publish it to npm — a second copy or
a second registry would open a second version axis on exactly the code that decides
whether the fail-closed contract holds.

`mix crosswake.install` patches the part that is mechanical (the endpoint plug) and
prints the part that is not. Run `mix crosswake.gen.bridge_hook` at any time to see all
three fragments again — it refuses to generate anything and prints the wiring instead:

```elixir
# lib/<app>_web/endpoint.ex — patched for you by mix crosswake.install
# crosswake:install:start
plug(Plug.Static,
  at: "/crosswake",
  from: :crosswake,
  gzip: false,
  only: ~w(crosswake.esm.js)
)
# crosswake:install:end
```

```javascript
// your layout's module script — yours to place
import {CrosswakeBridge} from "/crosswake/crosswake.esm.js";
const liveSocket = new LiveSocket("/live", Socket, {params, hooks: {CrosswakeBridge}});
```

```heex
<%!-- ONE element per page. Client events broadcast to EVERY mounted hook, so a
      second element would post every bridge request to the shell twice. --%>
<div id="crosswake-bridge" phx-hook="CrosswakeBridge" phx-update="ignore"></div>
```

If you genuinely need a host-owned copy, `mix crosswake.gen.bridge_hook --eject` writes
one carrying a protocol-version stamp. You own it from that moment on, and
`mix crosswake.doctor` warns when its stamp falls behind
`Crosswake.Bridge.Contract.version/0`.

### You must attach the bridge before you push

This is the one new install-time failure surface, and every adopter hits it exactly
once. `Crosswake.Bridge.push/3` raises `Crosswake.Bridge.NotMountedError` on a socket
that never called `Crosswake.Bridge.attach/1`. Crosswake never guesses a route id, so a
missing attach is a named, loud, first-push failure rather than a silent no-op.

```elixir
def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(crosswake_manifest: MyAppWeb.Crosswake.Policy.manifest(), crosswake_route_id: "my-route")
    |> Crosswake.Bridge.attach()

  {:ok, socket}
end
```

`attach/1` requires `:crosswake_manifest` and `:crosswake_route_id` to already be
assigned. `on_mount: Crosswake.Bridge` works too, as long as it runs after whatever
hook assigns those two. See [guides/bridge.md](bridge.md) for `push/3`, the reply
`handle_info/2` clause, and `resolve/2`.

`mix crosswake.doctor` greps your assets tree and your HEEx templates for the hook and
names it when it finds nothing. That grep is best-effort and never authoritative — it
cannot see a hook registered through a bundler alias. The authoritative detector is the
runtime wiring deadline: the server arms it on every push and delivers a
`:shell_unreachable` denial when no acknowledgement arrives.

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

## Native Evidence Labels

- `generated public-coordinate proof` is the default non-local shell generation path.
- `local-dev proof` is the explicit `--local` maintainer path.
- `checked-in public-coordinate proof` is the label for the checked-in iOS and Android host proof surfaces.
- None of those labels imply simulator, emulator, or physical-device support.

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

See the canonical action-class table at `guides/support_matrix.md#action-classes`
and Promotion rules at `guides/support_matrix.md#promotion-rules`.

Promotion rules keep advisory support explicit: StoreKit/Play Billing seams in v3.7 emit reconciliation evidence only, backend projection grants authority, provider/device proof remains advisory unless promotion criteria pass, Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contracts, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, and Phase 58 telemetry/security closeout are shipped, refresh-token helpers, provider/device auth proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI are deferred, notification-token readiness is provider-snapshot only, and standalone native shell core packages are published through SwiftPM and Maven Central at the Crosswake package version.

compatibility-window narrowing is distinct from a native rebuild; it can be `compatibility-bump only` when the shipped native runtime line remains compatible.

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
