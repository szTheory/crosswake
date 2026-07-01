defmodule Crosswake.Companion do
  @moduledoc """
  Behaviour for first-party Phoenix-native companion integrations.

  A companion is a bounded integration seam between Crosswake's route-policy
  system and an external Elixir library (e.g. rulestead for feature flags,
  rindle for media, sigra for auth).

  The public companion contract surface — the types and callbacks extension packages
  may depend on under semver — is exactly five modules:
  `Crosswake.Companion`, `Crosswake.Companion.State`, `Crosswake.Compatibility.Finding`,
  `Crosswake.Compatibility.Target`, and `Crosswake.Manifest.Types.RouteEntry`. These are
  semver-stable under `crosswake` >= 0.1.0. All other modules in `crosswake` are
  internal implementation details subject to change.

  ## Implementing a companion

  Declare `@behaviour Crosswake.Companion` in your module and implement all
  six required callbacks. No `use Crosswake.Companion` macro exists — the
  behaviour is deliberately thin (D-12 conceptual lineage from
  `Crosswake.Commerce`).

  Register companions at compile time in your host application config:

      config :crosswake, :companions, [MyApp.Companions.Rulestead]

  ## Telemetry events

  Crosswake emits the following static telemetry event-name contracts for
  companion spans. All events are differentiated by
  `%{companion_id: atom(), route_id: binary() | nil}` metadata per Keathley
  conventions.

  - `[:crosswake, :companion, :validate_dependency, :start | :stop | :exception]`
    — emitted in Phase 38 (Plan 02) when the doctor runs
    `validate_dependency/0` for each registered companion. The `:stop`
    metadata includes `result: :ok | {:error, [module()]}`.

  - `[:crosswake, :companion, :route_gate, :start | :stop | :exception]`
    — specified now, emitted in Phase 40 when `RouteGate` calls
    `route_gated?/2`.

  - `[:crosswake, :companion, :kill_switch, :start | :stop | :exception]`
    — specified now, emitted in Phase 40 when `RouteGate` calls
    `kill_switch_active?/1` (short-circuits ahead of `route_gated?/2`).
  """

  alias Crosswake.Companion.State
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types.RouteEntry

  @doc """
  Returns the unique atom identifier for this companion.

  Used as the `companion_id` key in telemetry metadata and in
  `Crosswake.Companion.State` reports.
  """
  @callback companion_id() :: atom()

  @doc """
  Returns whether this companion is enabled for the current host configuration.

  Receives the host-owned config map (arbitrarily shaped, narrowed internally
  by the companion implementation — FunWithFlags-style). This is a host-level
  toggle, NOT a per-route gate (D-03); per-route policy is `route_gated?/2`.

  The host passes a config map supplied via `Application.get_env/3` or
  equivalent. The companion is responsible for extracting and interpreting
  its own keys from the map.
  """
  @callback enabled?(config :: map()) :: boolean()

  @doc """
  Evaluates whether a specific route is gated by this companion's policy.

  Returns `{:deny, Finding.t()}` with evidence the policy compiler consumes,
  or `:pass` (not `nil`) to keep the return type closed (D-06). `:pass` is
  the explicit non-denial value — there is no bare `term()` escape hatch.

  A companion can only FURTHER-RESTRICT access; it can never open a route
  that has already been denied by the core policy. The RouteGate consumes
  this return in Phase 40 (defined-not-wired here).

  `kill_switch_active?/1` short-circuits ahead of this callback — if the kill
  switch is active, `route_gated?/2` is not called.
  """
  @callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) ::
              {:deny, Finding.t()} | :pass

  @doc """
  Returns whether the companion's kill switch is currently active.

  Kill switches are route-independent (D-07) — this callback receives only
  `Target.t()` context, not a route, so kill-switch logic can short-circuit
  ahead of `route_gated?/2` without per-route evaluation overhead.

  Wired into RouteGate in Phase 40. Returns `true` when the kill switch is
  active (route access should be denied for this companion); `false` otherwise.
  """
  @callback kill_switch_active?(context :: Target.t()) :: boolean()

  @doc """
  Validates that all optional dependencies required by this companion are loaded.

  Returns `:ok` if all required modules are present, or
  `{:error, [module()]}` with the list of module(s) that failed
  `Code.ensure_loaded?/1` (Swoosh-style missing-module list, D-08).

  The doctor wraps this call in a
  `[:crosswake, :companion, :validate_dependency]` telemetry span and
  emits a `:companion.dependency_missing` finding when this returns an error
  AND the companion reports `enabled?: true`.
  """
  @callback validate_dependency() :: :ok | {:error, [module()]}

  @doc """
  Reports the current runtime state of this companion as a typed struct.

  Returns a `Crosswake.Companion.State.t()` snapshot at the moment of the
  call. `checked_at` should be `System.monotonic_time(:millisecond)`.

  The `gate_status` and `kill_switch_status` fields are defined in the type
  space now but are only meaningfully populated starting in Phase 40/41 when
  the gating and kill-switch machinery is wired. Implementations should return
  `:unconfigured` for these fields until Phase 40 wiring is complete.
  """
  @callback report_state() :: State.t()

  @doc """
  Returns the telemetry events this companion declares, as `Crosswake.Telemetry.event_doc()` maps.

  This callback is optional. Companions that emit no telemetry events may omit it.
  When implemented, returned events are merged into `Crosswake.Telemetry.events/0`
  at call time and contribute to the published telemetry contract (D-07, TELEM-04).

  The returned list must not include any events with PII-bearing metadata keys. Only
  low-cardinality atom key names (never values) should appear in the `metadata` field
  of each `event_doc` map.
  """
  @callback telemetry_events() :: [Crosswake.Telemetry.event_doc()]

  @doc """
  Returns the list of metadata key atoms this companion considers PII or sensitive.

  This callback is optional. When implemented, the returned atoms are unioned with
  core's baseline PII denylist and scrubbed from all telemetry event metadata before
  the event is forwarded to attached handlers. This prevents companion-specific
  sensitive keys from leaking through the telemetry pipeline (DECOUPLE-05).

  Keys must be atom literals — substring or regex matching is not used. Only add keys
  that genuinely contain sensitive data (credentials, identity fields, tokens).
  """
  @callback forbidden_metadata_keys() :: [atom()]

  @doc """
  Returns the list of denial reason codes this companion may produce.

  This callback is optional. When implemented, the returned codes are incorporated
  into `SupportMatrix.auth_contract_truth/0` and surfaced in the doctor's Phase 46
  auth findings. Codes must be `String.t()` values matching the companion's
  `Crosswake.Shell.Denial.t()` reason strings (DECOUPLE-03).
  """
  @callback denial_codes() :: [String.t()]

  @doc """
  Evaluates whether a specific route permits the given auth context.

  This callback is optional. Companions implementing auth evaluation must also
  implement `auth_authority?/0` returning `true` to be selected as the auth evaluator.
  Core dispatches to at most one `auth_authority?/0` companion per evaluation
  (first-registered wins; multiple authorities emit a telemetry conflict warning).

  Returns `{:allow, result_map}` to permit access, or `{:deny, Finding.t()}`
  to block access with structured restriction evidence. Core translates the
  `Crosswake.Compatibility.Finding.t()` to a `Crosswake.Shell.Denial` via
  `Compatibility.finding_to_denial/2` at the `RouteGate` boundary — companions
  must never construct `Denial` directly (D-137-A). The `:auth` axis and the
  `:code`/`:details` fields on the Finding carry the sub-classification and
  already-sanitized evidence to the translation boundary.

  Core wraps this call in `try/rescue` — if the callback raises, the error is
  rescued and a `:dependency_missing` denial is returned (fail-closed,
  DECOUPLE-04, D-3).

  `route` is the `RouteEntry.t()` being evaluated. `auth_context` is the host-supplied
  map (e.g. from Plug assigns or LiveView socket). `opts` carries call-site keyword
  options forwarded from `RouteGate.evaluate/4`.
  """
  @callback evaluate_auth(
              route :: RouteEntry.t(),
              auth_context :: map(),
              opts :: keyword()
            ) :: {:allow, map()} | {:deny, Finding.t()}

  @doc """
  Returns whether this companion is the designated auth evaluator for the host.

  This callback is optional. When a route is auth-predicated (has `auth_min_level`,
  `requires_recent_auth`, or `auth_posture` set), core scans the companion registry for
  the first companion that exports `auth_authority?/0` and returns `true`, then dispatches
  `evaluate_auth/3` to that companion.

  If no companion returns `true`, auth-predicated routes receive a `:dependency_missing`
  denial (fail-closed). If multiple companions return `true`, the first-registered one
  is used and a telemetry conflict event is emitted (DECOUPLE-04, D-3).
  """
  @callback auth_authority?() :: boolean()

  @optional_callbacks telemetry_events: 0,
                      forbidden_metadata_keys: 0,
                      denial_codes: 0,
                      evaluate_auth: 3,
                      auth_authority?: 0
end
