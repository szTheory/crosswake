# Crosswake Compatibility Boundaries

Crosswake keeps runtime ownership explicit per route and keeps compatibility truth
separate from package versions.

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

## Do I need to rebuild?

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

Promotion rules keep advisory support explicit: StoreKit/Play Billing seams in v3.7 emit reconciliation evidence only, backend projection grants authority, provider/device proof remains advisory unless promotion criteria pass, Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contracts, Phase 56 step-up intent plus Plug/LiveView ceremony, and Phase 57 OAuth/passkey/native auth-return boundary contracts are shipped, refresh-token helpers, provider/device auth proof, telemetry/security closeout, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI are deferred, notification-token readiness is provider-snapshot only, and standalone public shell packages are deferred.

compatibility-window narrowing is distinct from a native rebuild; it belongs to `compatibility-bump only` when only the accepted version window changes.

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

## Non-Goals

- Generic WebView-wrapper positioning
- Lockstep repo-wide version theater
- High-frequency bridge-driven state loops
- Broad support claims beyond the proof-oriented matrix
