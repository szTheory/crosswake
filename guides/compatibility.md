# Crosswake Compatibility Boundaries

## Do I need to rebuild? (start here)

Every compatibility question reduces to one of four outcomes. Find your change type below, then follow the action column.

| Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor |
|-------------|--------------|---------------|----------------|------------------------------|--------------|
| Docs or wording updated | docs_wording | docs-only | Read the updated guidance and rerun docs integrity only. | n/a | [Change Classes](support_matrix.md#change-classes) |
| Core Elixir behavior changed inside existing axis values | core_elixir_behavior | core-only/no native rebuild | Update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells. | n/a | [Change Classes](support_matrix.md#change-classes) |
| `manifest_schema_version` narrowed (additive) | manifest_schema_version | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | `compatibility_mismatch` | [Compatibility Axes](#compatibility-axes) |
| `manifest_schema_version` breaking change | manifest_schema_version | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | `compatibility_mismatch` | [Compatibility Axes](#compatibility-axes) |
| `bridge_protocol_version` narrowed (additive) | bridge_protocol_version | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | `compatibility_mismatch` | [Compatibility Axes](#compatibility-axes) |
| `bridge_protocol_version` breaking change | bridge_protocol_version | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | `compatibility_mismatch` | [Compatibility Axes](#compatibility-axes) |
| `native_runtime_version` any change (additive or breaking) | native_runtime_version | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | `compatibility_mismatch` | [Runtime Line Rules](#runtime-line-rules) |
| Core-owned capability version narrowed | capability_version | compatibility-bump only | Check the compatibility window, confirm your shipped shell/runtime is still in range, and run fail-closed compatibility fixtures. | `undeclared_capability` | [Compatibility Axes](#compatibility-axes) |
| Native/companion capability version changed | capability_version | native or companion rebuild required | Rebuild the affected shell or companion, publish the updated runtime line, and rerun generated-shell or companion verification lanes. | `undeclared_capability` | [Compatibility Axes](#compatibility-axes) |
| Pack declared as required but not installed | capability_version | native or companion rebuild required | Rebuild the affected shell or companion and ensure the required pack is installed and version-compatible. | `pack_incompatible` | [Companion Compatibility Contract](#companion-compatibility-contract) |

**The `native_runtime_version` asymmetry:** `manifest_schema_version` and `bridge_protocol_version` additive bumps map to `compatibility-bump only` *precisely because* the native floor is now `>=` (D-01/D-02) — an older shell that satisfies the floor requirement remains valid. `native_runtime_version` has **no** additive-without-rebuild row: the runtime ships in the binary, so every `native_runtime_version` move — additive or breaking — is `native or companion rebuild required`.

Crosswake keeps runtime ownership explicit per route and keeps compatibility truth
separate from package versions.

`checked-in public-coordinate proof`, `generated public-coordinate proof`, and
`local-dev proof` are evidence labels, not compatibility guarantees.

## Compatibility Axes

Crosswake evaluates compatibility through separate contract axes:

- `manifest_schema_version`
- `bridge_protocol_version`
- `native_runtime_version`

The shell may parse a manifest and still refuse activation or bridge execution if a
route requires a newer shell runtime, a newer bridge major, a missing declared pack,
or an unavailable capability version. Crosswake does not silently downgrade those
cases into generic WebView behavior.

## Package Versions Versus Compatibility Axes

Package versions alone do not answer support or rebuild questions.
package versions alone do not answer support or rebuild questions.

- `crosswake` uses package SemVer for Hex publication
- compatibility truth stays on `manifest_schema_version`, `bridge_protocol_version`, and `native_runtime_version`
- capability families keep their own major/minor expectations
- support claims come from the generated support matrix and doctor output, not from package numbers alone

Runtime ownership still stays explicit per route. Package class does not imply native
authority over a route.

## Companion Compatibility Contract

Future companions must declare minimum compatible ranges for:

- `crosswake` core
- `manifest_schema_version`
- `bridge_protocol_version`
- `native_runtime_version`
- any exposed capability-family majors

That keeps companion support explicit and fail closed instead of pretending every
published package version can interoperate safely.

Storefront-sensitive commerce work follows this contract. Provider adapters and native SDK wrappers carry `native or companion rebuild required` guidance and explicit compatibility declarations, rather than prose-only notes. You must rebuild when commerce companion prerequisites change.

Concretely, the canonical commerce corridor rebuild truth (mirrored from `Crosswake.SupportMatrix.commerce_corridors/0`) is:

- `paywall_entry` and `account_management` — `native_rebuild_required: false`. Phoenix-owned core route/manifest metadata changes do not require a native shell rebuild.
- `purchase_intent` and `restore_intent` — `native_rebuild_required: true`. Native adapter or provider SDK code changes require rebuilding and resubmitting the host shell.

See [guides/commerce.md](commerce.md) for the full corridor ownership matrix and proof-class posture.

## Release Choreography

Use the compatibility axes to describe release impact.

- Manifest-shape break: bump `manifest_schema_version` major, then update support docs and doctor before release.
- Bridge-envelope break: bump `bridge_protocol_version` major, then publish compatible shell artifacts before support expands.
- Native-code or entitlement change: move to a new `native_runtime_version` line and mark the change as rebuild required.
- Compatibility-window narrowing: treat it as `compatibility-bump only`, publish the new supported ranges, and keep older combinations fail closed.

## Do I need to rebuild? (legacy prose)

Crosswake enforces explicit rebuild guidance to maintain honest support claims and compatibility boundaries:

- **Docs-only changes:** Do not require native rebuilds and should run docs integrity checks.
- **Core-only/no native rebuild changes:** Update core route/manifest logic and rerun doctor/support proof while the native runtime line stays unchanged.
- **Compatibility-bump only changes:** Narrow supported ranges and keep older combinations fail-closed without treating the narrowing itself as shell code churn.
- **Bumping `native_runtime_version`:** Mandates an explicit native rebuild and submission to the app stores.
- **Bumping `bridge_protocol_version`:** Requires generating and publishing a compatible shell artifact update, followed by an explicit rebuild.
- **Adding new `companion` packages:** Especially native-backed ones, requires updating the shell project dependencies, adjusting entitlements, and performing an explicit native rebuild and submission.

You cannot bypass these rules with hot code pushes or cached manifests. Changing runtime native dependencies or bridge protocols requires a full native build cycle.

See the canonical action-class table at `guides/support_matrix.md#action-classes`
and Promotion rules at `guides/support_matrix.md#promotion-rules`.

Promotion rules keep advisory support explicit: StoreKit/Play Billing seams in v3.7 emit reconciliation evidence only, backend projection grants authority, provider/device proof remains advisory unless promotion criteria pass, Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contracts, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, and Phase 58 telemetry/security closeout are shipped, refresh-token helpers, provider/device auth proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI are deferred, notification-token readiness is provider-snapshot only, and standalone native shell core packages are published through SwiftPM and Maven Central at the Crosswake package version.

compatibility-window narrowing is distinct from a native rebuild; it belongs to `compatibility-bump only` when only the accepted version window changes.

## The `shell_unreachable` Boundary

Crosswake core owns a closed denial vocabulary. Companions own a separate `Finding` axis.
`shell_unreachable` — the fourteenth reason, added in Phase 154 — sits on the core side of
that line, and the distinction is load-bearing for companion authors.

**A companion must never return `shell_unreachable`.** It is minted only by core, only on
the server, and only for the one situation a companion is definitionally not in: no shell
answer could be obtained at all. A companion that ran far enough to form an opinion is by
construction reachable, so the reason would be false on its face. There is no companion
`Finding` axis that maps onto it, and none is planned.

What core mints it for is named in `details.failing_moment`:

- `no_transport` — the page never had a shell channel.
- `hook_not_wired` — a shell was present but the page never installed the bridge hook.
- `reply_timeout` — the ask was dispatched and no reply arrived before the backstop fired.
- `transport_error` — the channel existed and failed mid-flight.

One reason, four moments. Adopter code branches on the reason; an operator diagnoses with
the moment. Companion authors describing an unreachable dependency of their own should use
their own `Finding` vocabulary, not this reason.

### Native reason strings today, and what the server does with them

Crosswake claims one typed denial **at the adopter boundary**. That is the honest scope,
and it is narrower than "one denial vocabulary on the wire". Both halves of the gap are
known, counted, and tracked rather than papered over:

- **Eight fixed strings** emitted by shipped native code today fall outside the closed
  fourteen-reason set. They are enumerated one by one, each with an inline justification
  and a site, in `Crosswake.Bridge.CatalogGuard`. A ninth turns a merge-blocking gate red,
  so the set cannot grow quietly.
- **Five public delegate seams** on the iOS and Android shell cores accept a bare `String`
  denial reason from an adopter's own host code. No static enumeration can bound a field an
  adopter fills in, so this half is explicitly labelled non-mechanical in the guard's
  moduledoc rather than pretended into the allowlist.

The server is tolerant by design, and that tolerance is permanent: an unrecognized reason
string resolves to `unavailable_capability`, the raw value is preserved at
`details.raw_reason`, and no atom is minted. Already-shipped shell binaries emit their
strings forever, so this decoder can never be removed even after the vocabulary is closed.
The practical consequence for you: match on the typed reason your `handle_info/2` receives,
and treat `details.raw_reason` as diagnostic detail rather than as a branch key.

Closing both halves is deferred, not forgotten. Half one is a rename affordable with the
next native release; half two changes public adopter-implemented types on both platforms
and is a breaking change needing its own major-version story. Both are tracked in
`.planning/seeds/SEED-008-native-denial-vocabulary.md`, which is also what a reviewer
should cite if a future claim upgrades "one typed denial at the adopter boundary" into "one
vocabulary on the wire" before that work lands.

## Runtime Line Rules

iOS and Android shell artifacts publish against the same runtime line even if their
platform-specific artifact build numbers differ.

If a change touches native code, permissions, entitlements, registration, or packaged
runtime behavior, it belongs to the `native or companion rebuild required` class.

## Manifest Sources

Crosswake recognizes `bundled`, `cached`, and `remote` manifest sources.

- `bundled` is guaranteed boot truth shipped in the binary.
- `cached` is previously trusted manifest truth retained by the app.
- `remote` may refine behavior only inside the shipped native runtime and versioned
  compatibility contract.

Remote updates stay constrained to versioned replacement or explicitly versioned
companion data.

## Failure Posture

Crosswake activation is fail-closed.

- Route activation runs manifest-first and native-first before any web container loads.
- Unsupported or unsafe routes land on a Crosswake-owned `route unavailable` surface.
- Bridge execution is request/reply-only and denies side effects on
  `compatibility_mismatch`, `origin_denied`, `inactive_route`,
  `undeclared_capability`, `unavailable_capability`, and `pack_incompatible`.
- When no shell answer can be obtained at all, core synthesizes a `shell_unreachable`
  denial rather than leaving the ask unanswered. There is no configuration in which a
  bridge push resolves to silence.

## Change Class Examples

- Change class `docs-only`: clarify a guide or release note without changing compatibility declarations.
- Change class `core-only/no native rebuild`: tighten manifest validation while keeping the same supported axis values.
- Change class `compatibility-bump only`: narrow a supported shell/core window so older combinations fail closed.
- Change class `native or companion rebuild required`: change generated shell code, entitlements, or runtime dependencies.

## Proof Boundary

Published shell support is proof-backed by:

- `bash script/verify_phase5_example_hosts.sh`
- `bash script/verify_offline_contract.sh`

Generated-host verification remains part of the compatibility contract:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Run `mix crosswake.doctor` for manifest, support, and release-policy posture, then
run `mix crosswake.doctor --native-checks` to re-run the generated-host hooks against
your local shell projects.

`--local` stays the explicit maintainer path, and successful native shell or
emulator runs do not imply physical-device support.

## Non-Goals

- Generic WebView-wrapper positioning
- Lockstep repo-wide version theater
- High-frequency bridge-driven state loops
- Broad support claims beyond the proof-oriented matrix
