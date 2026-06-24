# Crosswake Troubleshooting

Start with the copied finding or symptom, then fix the route owner that owns the
decision. Crosswake failures are meant to stay explicit: the shell, bridge,
offline island, or backend seam should say why a route could not continue instead
of falling through to a generic web container.

Use this guide with [route_policy.md](route_policy.md), [bridge.md](bridge.md),
[offline.md](offline.md), [adoption.md](adoption.md),
[native_shell.md](native_shell.md), and the support-truth labels in
[support_matrix.md](support_matrix.md#support-truth-label-legend). The canonical
doctor output is guarded by `test/crosswake/doctor/doctor_test.exs`.

## Symptom And Finding Index

| Finding or symptom | Route owner to check | First command |
|--------------------|----------------------|---------------|
| `undeclared_capability` | bounded bridge | `mix crosswake.doctor --router Elixir.YourAppWeb.Router` |
| `unavailable_capability` | bounded bridge or backend/provider seam | `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` |
| `compatibility_mismatch` | Phoenix/LiveView route plus shell runtime line | `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` |
| `pack_incompatible` | native screen or pack-backed route | `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` |
| `external_entry_denied` | Phoenix/LiveView route entry policy | `mix crosswake.doctor --router Elixir.YourAppWeb.Router` |
| `gate_denied` | backend/provider seam | `mix crosswake.doctor --router Elixir.YourAppWeb.Router` |
| `step_up_required` | backend/provider seam | `mix crosswake.doctor --router Elixir.YourAppWeb.Router` |
| `route unavailable` or `route_unavailable` | native screen or manifest-first activation | `mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks` |
| native evidence label confusion | support-truth labels | `mix test test/crosswake/guides/native_evidence_drift_test.exs` |
| rejected offline replay | offline island | `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts` |
| conflict replay outcome | offline island | `mix crosswake.doctor --router Elixir.YourAppWeb.Router` |

## Phoenix/LiveView Owner

Use this section when Phoenix still owns the route: rendering, auth posture, data
authority, and the product action stay server-owned.

### `external_entry_denied`

**What you see:** a deep link, notification open, or external activation is
denied with `external_entry_denied`, or the shell stays on a route unavailable
surface.

**Who owns the fix:** the Phoenix route owner. The route must explicitly allow
external entry before the shell can activate it from outside the current app
flow.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** update the route
policy `entry` posture for the route that should be externally reachable, or keep
it internal and update the caller to route through a manifest-known internal
flow. Then rerun doctor and the relevant route proof.

**Proof label:** `merge-blocking proof` when the route policy and doctor contract
pass.

**What this does not prove:** it does not prove native-screen support, device
support, or that every external URL is safe. It only proves this manifest-known
route has the declared entry posture.

### `compatibility_mismatch`

**What you see:** activation or bridge execution fails with
`compatibility_mismatch`, often after a manifest, bridge protocol, native runtime,
or package version change.

**Who owns the fix:** the route owner and release owner together. Phoenix owns
the route policy and manifest truth; the shell owner owns the compatible native
runtime line.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

**Change this route policy, host setup, or proof command:** check
[compatibility.md](compatibility.md) and [native_shell.md](native_shell.md). If
the change is `core-only/no native rebuild`, keep the native runtime line stable
and rerun doctor/support proof. If the change touches native code, generated
shell projects, entitlements, permissions, or native dependencies, treat it as
`rebuild-required` and rerun generated-shell verification.

**Proof label:** `verification-required` until the compatible route, manifest,
and shell proof pass; promoted paths need the relevant `merge-blocking proof`.

**What this does not prove:** it does not prove the current device or simulator
build is supported. Compatibility truth is separate from `emulator evidence` and
`device evidence`.

## Bounded Bridge Owner

Use this section when the route remains Phoenix-owned but asks native code for one
low-frequency semantic action. The bridge never owns navigation, rendering,
offline mutation, or backend authority.

### `undeclared_capability`

**What you see:** a bridge call is denied with `undeclared_capability`, or a
route-tour bridge payload names a capability the route did not declare.

**Who owns the fix:** the Phoenix route owner. The route policy must declare the
capability family before the bounded bridge may run it.

**Run this:**

```bash
bash script/verify_bounded_bridge_proof.sh
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** add the capability to
the specific route only if the user job really needs that bounded native
affordance. For the checked-in proof, `/bridge-proof` declares `share`; ordinary
LiveView routes should continue without native side effects.

**Proof label:** `merge-blocking proof` for the bounded bridge contract;
screenshots or native UI are only `advisory evidence`.

**What this does not prove:** it does not prove a native share sheet, high
frequency events, local writes, or shell navigation authority.

### `unavailable_capability`

**What you see:** the route declares a capability, but the manifest, shell,
companion, provider, or support posture cannot supply it and returns
`unavailable_capability`.

**Who owns the fix:** the route owner decides whether to keep the route
Phoenix-owned without the affordance, add the required host/native setup, or move
the flow to a native screen or backend/provider seam.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

**Change this route policy, host setup, or proof command:** restore the missing
capability family, generated shell verification, companion prerequisite, or
provider setup named by doctor/support truth. If the capability is only advisory,
document the fallback instead of treating it as required support.

**Proof label:** `verification-required` until the missing capability path has an
explicit proof lane; `advisory evidence` cannot widen support truth by itself.

**What this does not prove:** it does not prove provider authority, native device
support, or entitlement/session authority. It only proves the declared route can
or cannot access the named capability.

## Cached Read-Only Owner

Use this section when a route can show stale data but cannot create local
canonical mutations.

### cached read-only mistaken for offline mutation

**What you see:** a cached route is expected to replay edits, or support output
shows stale/cached posture while product copy implies full offline behavior.

**Who owns the fix:** the route owner. Cached read-only is a degraded read; an
offline island owns local mutation.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** keep the route as
`offline: :cached_read_only` when stale display is enough. Move only the route
that owns local mutation to `runtime: :offline_island` with an outbox or journal,
then prove it with an end-to-end replay test.

**Proof label:** cached read-only posture can be covered by `merge-blocking
proof`; it is not local-first mutation proof.

**What this does not prove:** it does not prove drafts, outbox replay,
background sync, conflict resolution UI, or app-wide offline behavior.

## Offline Island Owner

Use this section when one route owns local-first work with a durable outbox or
journal and Phoenix/Ecto reconciliation.

### rejected offline replay

**What you see:** `/study/sync` returns a rejected record, the browser keeps the
local outbox entry, or the UI reports sync failed with queued records retained.

**Who owns the fix:** the offline-island route owner and Phoenix sync endpoint.
The browser owns local queueing; Phoenix/Ecto owns validation and canonical
persistence.

**Run this:**

```bash
cd examples/phoenix_host
npx playwright test e2e/offline_sync.spec.ts
```

**Change this route policy, host setup, or proof command:** inspect the semantic
event fields, especially `client_mutation_id`, `card_id`, and `rating`. Fix the
island event shape or the `/study/sync` validation path so rejected records stay
visible and accepted records are deleted from IndexedDB only after Phoenix
confirms them. See [adoption.md](adoption.md#replay-outcomes).

**Proof label:** `merge-blocking proof` for the browser route-tour/offline-sync
semantic path; screenshots are collateral only.

**What this does not prove:** it does not prove broad background sync, bridge
mutation authority, or native/provider authority over offline work. Bridge mutation authority is not part of Crosswake's offline path.

### conflict replay outcome

**What you see:** doctor or route-local status uses `conflict`,
`conflict_requires_attention`, or conflict/replay language instead of accepting a
queued event.

**Who owns the fix:** the offline-island route owner and backend reconciliation
owner. Conflict is a product state that needs explicit user or backend handling.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** keep conflict
outcomes visible. Add route-local reconciliation UI or backend rules that explain
which canonical state wins, then prove accepted, rejected, and conflict outcomes
separately.

**Proof label:** `merge-blocking proof` only when the route-local replay and
conflict behavior are asserted semantically.

**What this does not prove:** it does not prove collaborative merge behavior,
silent last-write-wins safety, background replay, or a general sync engine.

## Native Screen Owner

Use this section when native code owns the session loop, or when a shell refuses
activation before a web container loads.

### `pack_incompatible`

**What you see:** a native-screen route or pack-backed bridge route fails with
`pack_incompatible`.

**Who owns the fix:** the native-screen route owner and host shell owner. The
route declared a pack requirement the shell cannot satisfy.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

**Change this route policy, host setup, or proof command:** verify the route-local
pack id/version in route policy, regenerate or rebuild the host shell when a
native or companion pack changes, and rerun generated-shell verification. If the
pack is not available, keep the route fail-closed instead of degrading into a
generic web upload or generic bridge call.

**Proof label:** `verification-required` until the native/pack proof lane passes;
changes that touch native packages are `rebuild-required`.

**What this does not prove:** it does not prove camera support, media-upload
support, provider authority, or physical-device support.

### `route_unavailable` or route unavailable screen

**What you see:** the shell opens a route unavailable screen, or doctor reports
`route unavailable=yes` while checking manifest-first activation.

**Who owns the fix:** the native shell host owner and route owner. The shell is
correct to fail closed when the route is missing, externally denied, pack
incompatible, inactive, or runtime-incompatible.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
bash script/verify_phase5_example_hosts.sh
```

**Change this route policy, host setup, or proof command:** confirm the route id
exists in the manifest, the entry posture is right, packs are compatible, and the
native screen is intentionally owned by native code. Do not bypass the shell by
loading a generic web container for a route whose owner is `:native_screen`.

**Proof label:** `merge-blocking proof` for fail-closed manifest-first behavior;
`checked-in public-coordinate proof` only says checked-in hosts resolve published
coordinates by default.

**What this does not prove:** it does not prove simulator, emulator, physical
device, app-store, camera, or provider support.

### native evidence label confusion

**What you see:** a screenshot, simulator run, emulator run, or checked-in host
path is described as native support without separating coordinate mode, execution
environment, proof class, and limitation.

**Who owns the fix:** the docs/evidence owner and native host owner.

**Run this:**

```bash
mix test test/crosswake/guides/native_evidence_drift_test.exs
mix test test/crosswake/guides/evidence_manifest_test.exs
```

**Change this route policy, host setup, or proof command:** use the labels from
[support_matrix.md](support_matrix.md#support-truth-label-legend) literally.
Checked-in native hosts are `checked-in public-coordinate proof`; generated hosts
are `generated public-coordinate proof`; `--local` is `local-dev proof`.
Simulator or emulator capture is `advisory evidence` unless promotion criteria
explicitly move it. Use `emulator evidence` or `device evidence` only for named
runs that actually occurred.

**Proof label:** native collateral starts as `advisory evidence`; browser
route-tour correctness remains the `merge-blocking proof`.

**What this does not prove:** advisory native collateral does not prove
physical-device support, camera support, media-upload support, provider
authority, app-store readiness, or merge-blocking native support.

## Backend/Provider Seam Owner

Use this section when the device or provider emits evidence, but Phoenix/backend
remains authority for sessions, access, commerce, notification opens, or
entitlements.

### `gate_denied`

**What you see:** route activation fails with `gate_denied`, often because a
RouteGate predicate, feature gate, kill switch, entitlement, or policy check
blocked access.

**Who owns the fix:** the backend/provider seam owner. The shell should not grant
access around backend policy.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** fix the backend gate
predicate, route policy, entitlement projection, or feature flag source. Keep the
denial explicit until backend authority says the user may enter.

**Proof label:** `merge-blocking proof` for fail-closed gate behavior.

**What this does not prove:** it does not prove provider/device evidence can
grant authority. Device and provider signals are evidence until backend
projection accepts them.

### `step_up_required`

**What you see:** an auth-sensitive route denies entry with `step_up_required` or
a doctor finding such as `auth.step_up_required_contract`.

**Who owns the fix:** the backend/session authority owner. Step-up is a
server-owned ceremony; bridge state or native cache state cannot skip it.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router
```

**Change this route policy, host setup, or proof command:** keep `auth_posture`,
`auth_return`, recent-auth windows, and step-up intent handling route-local and
backend-owned. Prove handoff, step-up completion, auth-return replay, and
telemetry through the existing auth contract tests before relaxing access.

**Proof label:** `merge-blocking proof` for session-authority contract behavior.

**What this does not prove:** it does not prove native auth UI, passkey/provider
SDK support, refresh-token helpers, direct shell token authority, or device-owned
session authority.

### backend/provider evidence stays non-authoritative

**What you see:** a purchase, restore, media capture, notification token, or
provider callback is available, but access or workflow state remains pending,
awaiting verification, rejected, or stale.

**Who owns the fix:** the backend/provider seam owner.

**Run this:**

```bash
mix crosswake.doctor --router Elixir.YourAppWeb.Router --native-checks
```

**Change this route policy, host setup, or proof command:** project provider or
device evidence through backend-owned reconciliation before changing authority.
Use [support_matrix.md](support_matrix.md) and [capabilities.md](capabilities.md)
to keep provider adapters, notification tokens, media evidence, and entitlement
snapshots evidence-only until the backend accepts them.

**Proof label:** provider/device collateral is `advisory evidence` until a
specific backend-owned promotion rule and proof lane pass.

**What this does not prove:** it does not prove entitlement authority, session
authority, media availability, push delivery, or physical-device support.
