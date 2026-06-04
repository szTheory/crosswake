# Phase 71: Notification-Driven Workflow Proof - Pattern Map

**Mapped:** 2026-06-04
**Phase:** 71 - notification-driven-workflow-proof
**Output role:** planner implementation analogs only

## Scope Extracted From Context And Research

Phase 71 should prove a deterministic notification re-entry workflow over existing Chimeway, RouteGate, and Sigra contracts. The expected implementation surface is narrow:

1. Create `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`.
2. Likely fix/lock Chimeway denial mapping in `lib/crosswake/companions/chimeway/resolver.ex` and `lib/crosswake/companions/chimeway/denial_codes.ex`.
3. Likely align example-host registry action matching in `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` plus its registry test.
4. Likely adjust RouteGate notification-source denial transition in `lib/crosswake/compatibility/route_gate.ex` plus `test/crosswake/compatibility/route_gate_test.exs`.
5. Create `.github/workflows/phase71-proof.yml`.
6. Optionally update support/docs/operator truth only if public prose needs to reflect the new proof posture.

Do not introduce a `NotificationWorkflow`, generic notification action registry, push delivery proof, native/APNs/FCM proof, notification center, or endpoint-backed E2E lane.

## Data Flow To Prove

`NotificationOpenEvidence` -> inline `IntentConsumer.consume_intent/1` -> `%OpenResolution{state: :valid}` -> `Resolver.resolve/3` -> manifest route lookup -> route-local `notification_open` action allowlist -> `RouteGate.evaluate/4` with `activation_source: :notification` and backend-projected Sigra `AuthContext` -> either `{:allow, decision}` with `transition: :activate` or support-safe denial with `transition: :halt`.

Payload possession is evidence only. The proof may place `auth_context` on the evidence struct because that is the current API shape, but test prose/helpers should treat it as backend-projected fixture state, not notification payload authority.

## Target File Patterns

### `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`

**Role:** new merge-blocking hermetic ExUnit proof.

**Closest analogs:**

- `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` - product-shaped adversarial proof and hermeticity self-scan.
- `test/crosswake/proof/phase63_notification_seam_proof_test.exs` - prior Chimeway example-host route-open proof; use as context, not the merge-gate spine.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` and `test/crosswake/compatibility/route_gate_test.exs` - Sigra denial matrix and auth-context fixture style.
- `test/crosswake/companions/chimeway/resolver_test.exs` - resolver pass-through and denial basics.

**Concrete module shape:**

```elixir
defmodule Crosswake.Proof.Phase71NotificationWorkflowProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution
  alias Crosswake.Companions.Chimeway.Resolver
  alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts
  alias Crosswake.Manifest.Types.Compatibility
  alias Crosswake.Manifest.Types.Host
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
end
```

`async: false` is conservative proof-lane precedent. If no application env or telemetry handlers are touched, `async: true` is technically possible, but Phase 70 used `async: false` for proof predictability.

**Inline intent consumer pattern:**

```elixir
defmodule StatefulIntentConsumer do
  @behaviour Crosswake.Companions.Chimeway.IntentConsumer

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution

  @impl true
  def consume_intent(%NotificationOpenEvidence{} = evidence) do
    case {evidence.open_ref, evidence.binding_ref, evidence.route_id, evidence.action_ref} do
      {"open_valid", "binding_active", "saas_approval", "approve"} ->
        {:ok, %OpenResolution{open_ref: "open_valid", state: :valid, resolved_at: fixed_now()}}

      {"open_expired", _, _, _} ->
        {:ok, %OpenResolution{open_ref: "open_expired", state: :expired, resolved_at: fixed_now()}}

      {"open_replayed", _, _, _} ->
        {:ok, %OpenResolution{open_ref: "open_replayed", state: :replayed, resolved_at: fixed_now()}}

      {"open_revoked", _, _, _} ->
        {:ok, %OpenResolution{open_ref: "open_revoked", state: :binding_revoked, resolved_at: fixed_now()}}

      {"open_action_mismatch", _, _, _} ->
        {:ok, %OpenResolution{open_ref: "open_action_mismatch", state: :action_mismatch, resolved_at: fixed_now()}}
    end
  end
end
```

Keep the consumer pure and local. Do not require example-host Repo, Endpoint, PubSub, APNs, FCM, devices, simulators, or network.

**Inline manifest route shape:**

```elixir
%Root{
  compatibility: %Compatibility{
    manifest_schema_version: "2.0.0",
    bridge_protocol_version: "1.0.0",
    native_runtime_version: "1.0.0"
  },
  host: %Host{origin: "https://example.test"},
  capability_registry: %{},
  routes: %{
    "saas_approval" => %RouteEntry{
      id: "saas_approval",
      path: "/saas/approvals/:approval_id",
      runtime: :live_view,
      entry: :external,
      notification_open: [actions: ["tap", "approve"]],
      auth_min_level: :mfa,
      requires_recent_auth: 300,
      auth_posture: :strict_recent
    }
  }
}
```

`RouteEntry` fields are defined in `lib/crosswake/manifest/types.ex`: `notification_open`, `auth_min_level`, `requires_recent_auth`, `auth_posture`, and `on_unavailable` serialize into manifest truth. `notification_open` validation lives in `lib/crosswake/policy/schema.ex` and accepts booleans, keyword lists, or maps with atom actions, while existing resolver tests use string action refs in manifest fixtures. Planner should preserve compatibility with current resolver behavior unless it intentionally normalizes action types.

**Sigra auth-context helper signatures:**

```elixir
assert {:ok, lane} =
         SigraContracts.new_session_authority_lane(%{
           session_ref: "session_ref_123",
           subject_ref: "actor_123",
           org_id: "org_123",
           state: :active,
           assurance_level: :mfa,
           authn_methods: [:password, :totp],
           authenticated_at: "2026-06-04T00:04:00Z",
           last_seen_at: "2026-06-04T00:05:00Z",
           idle_expires_at: "2026-06-04T00:30:00Z",
           absolute_expires_at: "2026-06-05T00:00:00Z",
           session_version: 7,
           as_of: "2026-06-04T00:05:00Z",
           remembered: false,
           cached: false
         })

assert {:ok, context} =
         SigraContracts.new_auth_context(%{
           actor_id: "actor_123",
           org_id: "org_123",
           mfa_level: :mfa,
           auth_age: 60,
           session_authority_lane: lane,
           as_of: "2026-06-04T00:05:00Z"
         })
```

Use lane overrides for negatives: `state: :revoked`, `assurance_level: :password`, `auth_age_seconds: 600`, `remembered: true`, `cached: true`, expired timestamps, or mismatched session version.

**Core assertions to lock:**

```elixir
assert {:allow, decision} = Resolver.resolve(manifest, evidence, StatefulIntentConsumer)
assert decision.status == :allow
assert decision.transition == :activate
```

```elixir
assert {:deny, denial} = Resolver.resolve(manifest, stale_auth_evidence, StatefulIntentConsumer)
assert denial.reason == :step_up_required
assert denial.code == "auth.step_up.stale_auth"
```

If asserting fallback-bypass behavior through `Resolver`, route fixture should include `on_unavailable: {:fallback_phoenix, :dashboard}` and notification activation must still halt after auth denial. Existing `RouteGate.transition_for/3` currently redirects fallback denials before checking `activation_source`, so expect a red proof until RouteGate is adjusted.

**Minimum denial matrix:**

- unknown route -> `:notification_open_denied`, `notification.open.route_mismatch`
- route lacks `notification_open` -> `:notification_open_denied`, `notification.open.policy_denied`
- unsupported manifest action -> `:notification_open_denied`, `notification.open.unsupported_action`
- expired intent -> `:notification_open_denied`, `notification.open.expired`
- replayed intent -> `:notification_open_denied`, `notification.open.replayed`
- revoked/non-active binding -> `:notification_open_denied`, `notification.open.binding_revoked`
- binding mismatch -> `:notification_open_denied`, `notification.open.binding_mismatch`
- route mismatch -> `:notification_open_denied`, `notification.open.route_mismatch`
- action mismatch -> `:notification_open_denied`, likely new `notification.open.action_mismatch`
- missing auth -> `:step_up_required`, `auth.step_up.missing_context`
- invalid auth -> `:step_up_required`, `auth.step_up.invalid_context`
- weak assurance -> `:step_up_required`, `auth.step_up.insufficient_assurance`
- stale recent auth -> `:step_up_required`, `auth.step_up.stale_auth`
- revoked authority lane -> `:step_up_required`, `auth.step_up.revoked`
- remembered/cached authority on strict route -> existing Sigra remembered/cached denial codes
- fallback route configured -> notification-source denial halts, no dashboard/home redirect

**Redaction self-scan pattern:**

Add hostile evidence metadata containing token/payload/PII-ish keys and assert no denial details leak them:

```elixir
metadata: %{
  raw_token: "raw-token-must-not-leak",
  apns_token: "apns-token-must-not-leak",
  fcm_token: "fcm-token-must-not-leak",
  provider_payload: %{"aps" => %{"alert" => "secret"}},
  notification_title: "Private title",
  notification_body: "Private body",
  route_params: %{"approval_id" => "secret"},
  actor_id: "actor-private",
  session_ref: "session-private",
  device_id: "device-private",
  ip: "203.0.113.10",
  user_agent: "private-agent",
  email: "person@example.test"
}
```

Use `inspect(denial)` and `denial.details` to refute raw values. Existing `DenialCodes.sanitize_details/1` only allows `:open_ref`, `:binding_ref`, `:action_kind`, `:evaluated_at`, `:route_id`, and `:action_ref`.

**Hermeticity self-scan guard:**

Use Phase 70 style but expect zero `Code.require_file` calls:

```elixir
source = File.read!(__ENV__.file) |> String.downcase()

refute source =~ "endpoint"
refute source =~ "repo"
refute source =~ "pubsub"
refute source =~ "apns"
refute source =~ "fcm"
refute source =~ "device"
refute source =~ "simulator"
refute source =~ "system.cmd"
```

Allow literal `"apns"`/`"fcm"` only if the proof includes non-claim assertions; if so, make the self-scan check structured around forbidden runtime calls rather than blanket substrings.

### `lib/crosswake/companions/chimeway/resolver.ex`

**Role:** likely implementation fix for denial code normalization and route-auth pass-through preservation.

**Closest analogs:**

- Existing `resolve/3` flow in the same file.
- `test/crosswake/companions/chimeway/resolver_test.exs` for unit-level expectation style.

**Current signature:**

```elixir
def resolve(%Root{} = manifest, %NotificationOpenEvidence{} = evidence, intent_consumer)
```

**Current flow to preserve:**

1. `Map.get(manifest.routes, evidence.route_id)`
2. deny unknown route as `notification.open.route_mismatch`
3. deny missing/false `notification_open` as `notification.open.policy_denied`
4. deny unsupported action as `notification.open.unsupported_action`
5. call `intent_consumer.consume_intent(evidence)`
6. on `%OpenResolution{state: :valid}`, delegate to `RouteGate.evaluate/4` with `activation_source: :notification` and `auth_context: evidence.auth_context`
7. return `{:allow, decision}` or `{:deny, decision.denial}`

**Likely change pattern:**

Replace interpolated state-to-code mapping:

```elixir
deny(route, "notification.open.#{state}", %{intent_state: state})
```

with a private canonicalizer:

```elixir
defp denial_code(:revoked), do: "notification.open.binding_revoked"
defp denial_code(:binding_revoked), do: "notification.open.binding_revoked"
defp denial_code(:action_mismatch), do: "notification.open.action_mismatch"
defp denial_code(state) when state in [:expired, :replayed, :binding_mismatch, :route_mismatch],
  do: "notification.open.#{state}"
defp denial_code(_state), do: "notification.open.policy_denied"
```

Do not translate Sigra `auth.step_up.*` denials into Chimeway vocabulary. RouteGate denial pass-through is the desired behavior.

### `lib/crosswake/companions/chimeway/denial_codes.ex`

**Role:** canonical notification-open denial vocabulary and details sanitizer.

**Closest analogs:**

- Same file's existing function-per-code style.
- `test/crosswake/companions/chimeway/denial_codes_test.exs`.

**Existing public functions:**

```elixir
notification_open_expired/0
notification_open_replayed/0
notification_open_binding_revoked/0
notification_open_route_mismatch/0
notification_open_binding_mismatch/0
notification_open_unsupported_action/0
notification_open_policy_denied/0
sanitize_details/1
```

**Likely addition:**

```elixir
@spec notification_open_action_mismatch() :: String.t()
def notification_open_action_mismatch, do: "notification.open.action_mismatch"
```

Keep allowed detail keys low-cardinality. If action mismatch details are needed, existing `:action_ref` is already allowed; do not add route params, token refs, actor refs, session refs, payloads, title/body, IP, email, or user agent.

### `test/crosswake/companions/chimeway/resolver_test.exs`

**Role:** focused regression tests for resolver denial mapping and Sigra pass-through.

**Closest analog:** current `MockIntentConsumer` maps `open_ref` strings to `%OpenResolution{state: state}`.

**Pattern to extend:**

```elixir
def consume_intent(%NotificationOpenEvidence{open_ref: open_ref}) do
  state = String.to_atom(open_ref)
  {:ok, %OpenResolution{open_ref: open_ref, state: state, resolved_at: DateTime.utc_now()}}
end
```

Add tests for:

- `open_ref: "revoked"` maps to `notification.open.binding_revoked`, not `notification.open.revoked`.
- `open_ref: "action_mismatch"` maps to `notification.open.action_mismatch`.
- RouteGate auth denial still returns `reason: :step_up_required` and `auth.step_up.*` code.

### `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`

**Role:** example-host precedent for backend-owned token binding and one-time open intent lifecycle.

**Closest analogs:**

- `issue_notification_open_intent/1`
- `consume_intent/1`
- `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs`

**Current key signatures:**

```elixir
def issue_notification_open_intent(attrs)
```

```elixir
@impl Crosswake.Companions.Chimeway.IntentConsumer
def consume_intent(%NotificationOpenEvidence{} = evidence)
```

**Current validation cond checks:**

```elixir
cond do
  intent.state != "issued" -> {:error, :replayed}
  DateTime.compare(intent.expires_at, now) == :lt -> {:error, :expired}
  intent.binding_ref != evidence.binding_ref -> {:error, :binding_mismatch}
  intent.route_id != evidence.route_id -> {:error, :route_mismatch}
  true -> {:ok, :valid}
end
```

**Likely change pattern:**

Add an action comparison before `true`:

```elixir
intent.action_ref != evidence.action_ref ->
  {:error, :action_mismatch}
```

Be careful with nil/backward compatibility. Existing issue tests often omit `action_ref`; planner should choose whether omitted stored action means no action binding or whether Phase 71 requires issued intents to include action. If preserving old tests, compare only when `intent.action_ref` is non-nil:

```elixir
is_binary(intent.action_ref) and intent.action_ref != evidence.action_ref ->
  {:error, :action_mismatch}
```

**Revoked binding vocabulary:**

Current binding lookup returns `{:error, :revoked}` when no active binding row exists. Planner can either change registry to `{:error, :binding_revoked}` or leave registry returning `:revoked` and normalize in resolver. Public proof should lock `notification.open.binding_revoked`.

### `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex`

**Role:** schema precedent confirming one-time intents already store `action_ref`.

**Closest analog:** same schema and migration for existing Chimeway open intents.

**Useful pattern:**

```elixir
schema "chimeway_notification_open_intents" do
  field(:open_ref, :string)
  field(:binding_ref, :string)
  field(:route_id, :string)
  field(:action_ref, :string)
  field(:state, :string, default: "issued")
  field(:expires_at, :utc_datetime)
  field(:consumed_at, :utc_datetime)
end
```

No schema change appears necessary for Phase 71.

### `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs`

**Role:** supporting example-host lifecycle regression if registry action matching is changed.

**Closest analog:** current tests for expired intent, binding mismatch, successful consume, and revoked binding.

**Patterns to add:**

```elixir
test "consume_intent/1 validates action_ref mismatch", %{open_ref: open_ref, binding_ref: binding_ref} do
  Registry.issue_notification_open_intent(%{
    open_ref: open_ref,
    binding_ref: binding_ref,
    route_id: "dashboard",
    action_ref: "approve",
    expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
  })

  evidence = %NotificationOpenEvidence{
    route_id: "dashboard",
    open_ref: open_ref,
    binding_ref: binding_ref,
    provider: :apns,
    action_ref: "tap",
    auth_context: %{}
  }

  assert {:ok, resolution} = Registry.consume_intent(evidence)
  assert resolution.state == :action_mismatch
end
```

If registry revoked binding state is changed, update current revoked assertion from `:revoked` to `:binding_revoked`; otherwise assert resolver normalizes it.

### `lib/crosswake/compatibility/route_gate.ex`

**Role:** likely implementation fix for notification-source auth denial behavior.

**Closest analogs:**

- Existing `transition_for/3` in same file.
- `test/crosswake/compatibility/route_gate_test.exs` for RouteGate behavior.

**Current transition order:**

```elixir
defp transition_for(:allow, _route, _opts), do: :activate

defp transition_for(:deny, %RouteEntry{on_unavailable: {:fallback_phoenix, id}}, _opts) do
  {:redirect, id}
end

defp transition_for(:deny, _route, opts) do
  if Keyword.get(opts, :activation_source) == :in_app_navigation do
    :stay_put
  else
    :halt
  end
end
```

**Likely change pattern:**

Add a notification-specific denial clause before fallback:

```elixir
defp transition_for(:deny, _route, opts)
     when Keyword.get(opts, :activation_source) == :notification,
     do: :halt
```

Elixir guards cannot call `Keyword.get/2`; implement as a regular function clause/body before fallback:

```elixir
defp transition_for(:deny, _route, opts) do
  case Keyword.get(opts, :activation_source) do
    :notification -> :halt
    :in_app_navigation -> :stay_put
    _ -> fallback_or_halt(route)
  end
end
```

Preserve current `:in_app_navigation -> :stay_put` behavior and fallback redirects for non-notification activations unless the planner intentionally changes broader semantics.

### `test/crosswake/compatibility/route_gate_test.exs`

**Role:** focused RouteGate regression for notification-source denials.

**Closest analog:** existing tests for Sigra denial matrix and RouteGate auth delegation.

**Pattern to add:**

Build a `%RouteEntry{on_unavailable: {:fallback_phoenix, :dashboard}, auth_min_level: :mfa, requires_recent_auth: 300}` route in an inline manifest or router fixture. Evaluate with `activation_source: :notification` and missing/stale auth:

```elixir
decision =
  RouteGate.evaluate(manifest, "secure_with_fallback", target,
    activation_source: :notification,
    auth_context: stale_context
  )

assert decision.status == :deny
assert decision.denial.reason == :step_up_required
assert decision.transition == :halt
```

Also keep a non-notification fallback assertion if needed to prove no unrelated fallback regression.

### `lib/crosswake/companions/sigra/contracts.ex`

**Role:** no expected implementation change; fixture builder source.

**Closest analog:** `test/crosswake/compatibility/route_gate_test.exs` helper `auth_context/1`.

**Useful signatures:**

```elixir
new_session_authority_lane(map() | keyword()) ::
  {:ok, SessionAuthorityLane.t()} | {:error, keyword()}

new_auth_context(map() | keyword()) ::
  {:ok, AuthContext.t()} | {:error, keyword()}
```

Use `AuthContext` and `SessionAuthorityLane` structs for backend-projected state. Do not pass raw maps as authority in the Phase 71 happy path.

### `lib/crosswake/companions/sigra/evaluator.ex`

**Role:** no expected implementation change; canonical auth denial behavior.

**Closest analog:** `test/crosswake/compatibility/route_gate_test.exs`.

**Useful behavior to assert through RouteGate/Resolver:**

- nil auth context -> `auth.step_up.missing_context`
- invalid context -> `auth.step_up.invalid_context`
- lane `state: :revoked` or `revoked_at` -> `auth.step_up.revoked`
- weak assurance -> `auth.step_up.insufficient_assurance`
- recent auth age over route max -> `auth.step_up.stale_auth`
- remembered/cached on strict route -> `auth.step_up.remembered_not_allowed` / `auth.step_up.cached_not_allowed`

Details are sanitized through `Crosswake.Companions.Sigra.DenialCodes.sanitize_details/1`. Do not add Chimeway wrapping around these denials.

### `lib/crosswake/companions/chimeway/contracts.ex`

**Role:** no expected implementation change; typed evidence and resolution structs.

**Closest analog:** `test/crosswake/companions/chimeway/contracts_test.exs`.

**Useful structs:**

```elixir
%NotificationOpenEvidence{
  route_id: "saas_approval",
  open_ref: "open_valid",
  binding_ref: "binding_active",
  provider: :apns,
  action_ref: "approve",
  auth_context: auth_context,
  action_kind: :tap,
  evaluated_at: "2026-06-04T00:05:00Z",
  metadata: %{}
}
```

```elixir
%OpenResolution{
  open_ref: "open_valid",
  state: :valid,
  reason: nil,
  resolved_at: "2026-06-04T00:05:00Z",
  metadata: %{}
}
```

### `lib/crosswake/policy/schema.ex` and `lib/crosswake/manifest/types.ex`

**Role:** no expected implementation change unless action normalization drift is discovered.

**Closest analogs:**

- Policy schema `validate_notification_open/1`
- Manifest `RouteEntry` fields and `serialize_notification_open/1`

**Important pattern:**

Policy type says `notification_open_declaration :: true | %{actions: [atom()]}`, but resolver tests use string actions in inline manifest fixtures. Generated route policy may normalize atom actions while hand-built test manifests may use strings. Planner should decide whether Phase 71 proof follows resolver-test string action precedent or generated-policy atom action shape. Avoid broad schema changes unless a red test demonstrates drift.

### `lib/crosswake/shell/denial.ex`

**Role:** no expected implementation change; canonical denial envelope.

**Closest analogs:** Resolver and Sigra evaluator `Denial.new/1` usage.

**Pattern:**

Chimeway resolver denials should use:

```elixir
Denial.new(
  reason: :notification_open_denied,
  code: "notification.open.expired",
  message: "notification open resolution failed",
  route_id: route_id,
  details: sanitized
)
```

Sigra denials should remain:

```elixir
reason: :step_up_required
code: "auth.step_up.*"
```

### `lib/crosswake/companions/chimeway/telemetry.ex` and `lib/crosswake/companions/chimeway/redaction.ex`

**Role:** likely no implementation change; redaction/low-cardinality precedent.

**Closest analogs:**

- `test/crosswake/companions/chimeway/telemetry_test.exs`
- `test/crosswake/companions/chimeway/redaction_test.exs`
- Phase 63 telemetry redaction assertions.

Use as references if proof introduces telemetry assertions. Prefer denial-detail redaction in Phase 71 unless the planner explicitly needs telemetry coverage.

### Optional docs/support/operator files

**Role:** only update if Phase 71 changes public truth or stale prose would confuse adopters.

**Likely files:**

- `guides/support_matrix.md`
- `guides/companions.md`
- `guides/user_flows.md`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/operator_inspection.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/mix/tasks/crosswake.doctor.ex`

**Closest analogs:**

- `guides/support_matrix.md` already distinguishes notification-token/open readiness from APNs/FCM delivery.
- `lib/crosswake/support_matrix/support_matrix.ex` has Chimeway support copy: notification token/open readiness is supported/resolvable while APNs/FCM delivery remains deferred and unsupported.
- `lib/crosswake/operator_inspection.ex` already exposes `notification_open` posture.

**Pattern:**

Allowed copy direction:

- "notification-open workflow proof is hermetic route activation proof"
- "token/open evidence is not auth authority"
- "RouteGate and Sigra decide activation"
- "APNs/FCM delivery is not part of this proof"

Forbidden copy direction:

- "push delivered"
- "notification guaranteed"
- "opened from APNs/FCM"
- "user authenticated by notification"
- "real-time push workflow"

### `.github/workflows/phase71-proof.yml`

**Role:** new targeted CI proof lane.

**Closest analog:** `.github/workflows/phase70-proof.yml`.

**Concrete workflow shape:**

```yaml
name: Phase 71 Proof

permissions:
  contents: read

on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      lane:
        description: "Proof lane to run"
        required: true
        default: merge-blocking
        type: choice
        options:
          - merge-blocking
          - advisory
          - all
  schedule:
    - cron: "0 6 * * 1"

env:
  DEVELOPER_DIR: /Applications/Xcode_26.0.app/Contents/Developer

jobs:
  merge-blocking-notification-workflow-proof:
    name: merge-blocking notification workflow proof (hermetic)
    runs-on: macos-15
    timeout-minutes: 20
    if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || (github.event_name == 'workflow_dispatch' && (inputs.lane == 'merge-blocking' || inputs.lane == 'all')) }}
    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
      - name: Setup BEAM
        uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - name: Install Elixir dependencies
        run: mix deps.get
      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors
      - name: Run hermetic Phase 71 notification workflow proof
        run: mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs

  advisory-push-provider-device-proof:
    name: advisory push provider/device proof (APNs + FCM)
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    if: ${{ github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && (inputs.lane == 'advisory' || inputs.lane == 'all')) }}
    continue-on-error: true
    steps:
      - name: Advisory lane status summary
        run: |
          echo "::notice title=Advisory push proof::APNs/FCM delivery, tray behavior, Focus/Doze/background delivery, and real devices are advisory only."
          echo "::notice::This job never gates merge and passing runs do not auto-promote support posture."
```

Keep pinned action SHAs and `permissions: contents: read`. Native/device/APNs/FCM evidence must remain advisory and non-promoting.

## Likely Created Or Modified Files

| File | Role | Data flow | Closest analog | Planner notes |
|------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | Create; merge-blocking proof | Evidence -> inline intent consumer -> Resolver -> RouteGate -> Sigra -> allow/deny | `phase70_subscription_saas_commerce_proof_test.exs`, `phase63_notification_seam_proof_test.exs` | Primary phase artifact; pure ExUnit, no example-host Repo. |
| `lib/crosswake/companions/chimeway/resolver.ex` | Likely modify | Intent state -> canonical denial code; valid intent -> RouteGate | same file, `resolver_test.exs` | Normalize `:revoked`/`:binding_revoked`; add `:action_mismatch`; preserve Sigra pass-through. |
| `lib/crosswake/companions/chimeway/denial_codes.ex` | Likely modify | Canonical code functions + sanitized details | `denial_codes_test.exs` | Add `notification_open_action_mismatch/0` if locking that code. |
| `test/crosswake/companions/chimeway/resolver_test.exs` | Likely modify | Resolver state mapping and auth denial pass-through | existing resolver tests | Add revoked-binding and action-mismatch regression. |
| `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` | Likely modify | Ecto intent consume validates stored intent vs evidence | registry consume tests | Compare stored `action_ref` to evidence; decide nil compatibility. |
| `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` | Likely modify | Example-host intent lifecycle coverage | existing expired/binding/revoked tests | Add action mismatch; maybe update revoked expected state. |
| `lib/crosswake/compatibility/route_gate.ex` | Likely modify | Denied route activation -> transition | `route_gate_test.exs` | Notification-source denials should halt before fallback redirect. |
| `test/crosswake/compatibility/route_gate_test.exs` | Likely modify | RouteGate notification auth denial transition | existing Sigra matrix | Add fallback-bypass regression. |
| `.github/workflows/phase71-proof.yml` | Create; CI | compile + targeted proof | `.github/workflows/phase70-proof.yml` | Merge-blocking hermetic macOS job; advisory push/device notices only. |
| `guides/companions.md` | Optional modify | Public companion truth | support/docs parity tests | Fix stale Chimeway open-routing language only if planner includes docs wave. |
| `guides/support_matrix.md` | Optional modify | Support posture | current notification row | Keep delivery unsupported; add route-activation proof wording if needed. |
| `guides/user_flows.md` | Optional modify | User-flow guidance | existing flow guide | Clarify Chimeway + Sigra interplay without delivery overclaims. |
| `lib/crosswake/support_matrix/support_matrix.ex` | Optional modify | Support truth data | support matrix accessors | Only if adding Phase 71 proof posture to machine-readable support truth. |
| `lib/crosswake/operator_inspection.ex` | Optional modify | Operator route truth | current `notification_open` reporting | Only if proof exposes new route/open/auth workflow status. |

## Planning Risks To Preserve

- Resolver currently maps arbitrary states with `"notification.open.#{state}"`; this can produce `notification.open.revoked` instead of canonical `notification.open.binding_revoked`.
- Example-host registry stores `action_ref` but currently validates state, expiry, binding ref, and route id only.
- RouteGate currently redirects fallback routes before considering notification activation source; this can hide auth denials.
- Full step-up continuation is out of scope because current resolver consumes open intent before RouteGate auth succeeds.
- `NotificationOpenEvidence.auth_context` must not be described as notification payload authority.
- Do not let proof wording imply APNs/FCM delivery, tray display, push metrics, Focus/Doze/background behavior, provider credentials, or real-device opens.

## PATTERN MAPPING COMPLETE
