defmodule Crosswake.Compatibility do
  @moduledoc """
  Layered compatibility evaluation for manifests and route activation.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Compatibility, as: CompatibilityTruth
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Packs.Runtime, as: PackRuntime

  defmodule Target do
    @moduledoc """
    Evaluation context passed to companion callbacks `route_gated?/2` and
    `kill_switch_active?/1`.

    Carries the request-time compatibility context: runtime versions, origin,
    active route, capabilities, and pack state. Companion implementations
    receive this struct and may read any field but must not construct it directly.

    ## Stability

    Public stable — part of the Crosswake companion contract surface. Semver-protected
    under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
    types, or callbacks without a major version bump. Companion packages
    (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
    pattern-match on this type.
    """
    @moduledoc since: "0.1.0"

    defstruct [
      :manifest_schema_version,
      :bridge_protocol_version,
      :native_runtime_version,
      :origin,
      :active_route_id,
      manifest_source: :bundled,
      capabilities: %{},
      packs: %{}
    ]

    @typedoc "Request-time evaluation context passed to companion gate and kill-switch callbacks."
    @type t :: %__MODULE__{
            manifest_schema_version: String.t() | nil,
            bridge_protocol_version: String.t() | nil,
            native_runtime_version: String.t() | nil,
            origin: String.t() | nil,
            active_route_id: String.t() | nil,
            manifest_source: :bundled | :cached | :remote,
            capabilities: %{optional(String.t()) => String.t()},
            packs: %{optional(String.t()) => term()}
          }
  end

  defmodule Finding do
    @moduledoc """
    Typed restriction evidence returned by `route_gated?/2` and `evaluate_auth/3`.

    Companion implementations return `{:deny, %Finding{}}` to signal that a
    route is restricted. Core translates findings into `Crosswake.Shell.Denial`
    structs internally — companions must never construct `Denial` directly.

    Required fields: `:axis` (atom identifying the policy axis, e.g. `:route`)
    and `:message` (human-readable explanation). Optional fields add structured
    evidence for logging and support surfaces.

    ## Auth-classification fields (`:code` and `:details`)

    `:code` carries a sub-classification string for auth-axis findings
    (e.g. `"auth.step_up.stale_auth"`). Auth companions MUST populate `:code`;
    a nil code downgrades to the string form of the denial reason at the
    `finding_to_denial/2` boundary (documented nil-code downgrade, T-137-03).

    `:details` carries an already-sanitized map of structured evidence for
    auth-axis findings. For `:auth` axis, `finding_to_denial/2` passes
    `:details` through UNMERGED (no `:axis` key injected) so sanitization
    applied at the companion source is preserved exactly.

    These two fields are additive — non-breaking to `crosswake_rulestead` and
    `crosswake_rindle` companions whose findings carry neither field (both
    default to nil / `%{}`).

    ## Stability

    Public stable — part of the Crosswake companion contract surface. Semver-protected
    under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
    types, or callbacks without a major version bump. Companion packages
    (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
    pattern-match on this type.
    """
    @moduledoc since: "0.1.0"

    @enforce_keys [:axis, :message]
    defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject, :code, details: %{}]

    @typedoc "Restriction evidence emitted by a companion's `route_gated?/2` or `evaluate_auth/3` callback."
    @type t :: %__MODULE__{
            axis: atom(),
            message: String.t(),
            required: String.t() | atom() | nil,
            available: String.t() | atom() | nil,
            hint: String.t() | nil,
            route_id: String.t() | nil,
            subject: String.t() | nil,
            code: String.t() | nil,
            details: map()
          }
  end

  alias Crosswake.Shell.Denial

  @spec validate_contract(CompatibilityTruth.t()) :: [map()]
  def validate_contract(%CompatibilityTruth{} = compatibility) do
    []
    |> validate_contract_version(compatibility, :manifest_schema_version)
    |> validate_contract_version(compatibility, :bridge_protocol_version)
    |> validate_contract_version(compatibility, :native_runtime_version)
    |> validate_supported_manifest_sources(compatibility)
    |> validate_remote_updates(compatibility)
  end

  @spec route_findings(Root.t(), String.t(), Target.t()) :: [Finding.t()]
  def route_findings(%Root{} = manifest, route_id, %Target{} = target) do
    route_findings(manifest, route_id, target, [])
  end

  @spec route_findings(Root.t(), String.t(), Target.t(), keyword()) :: [Finding.t()]
  def route_findings(%Root{} = manifest, route_id, %Target{} = target, opts) do
    route = Map.get(manifest.routes, route_id)

    []
    |> validate_route_presence(route_id, route)
    |> validate_external_entry(route, opts)
    |> validate_notification_open(route, opts)
    |> validate_manifest_schema(manifest.compatibility, target, route)
    |> validate_bridge_protocol(manifest.compatibility, target, route)
    |> validate_native_runtime(manifest.compatibility, target, route)
    |> validate_capabilities(route, manifest.capability_registry, target)
    |> validate_packs(route, target)
    |> validate_manifest_source(manifest.compatibility, target, route)
    |> validate_origin(route, manifest.host.origin, target.origin)
  end

  @spec bridge_findings(Root.t(), Contract.Request.t()) :: [Finding.t()]
  def bridge_findings(%Root{} = manifest, %Contract.Request{} = request) do
    route = Map.get(manifest.routes, request.route_id)
    target = bridge_target(request)

    []
    |> validate_active_route(request)
    |> validate_route_presence(request.route_id, route)
    |> validate_bridge_command(route, manifest.capability_registry, request)
    |> validate_bridge_protocol(manifest.compatibility, target, route)
    |> validate_native_runtime(manifest.compatibility, target, route)
    |> validate_packs(route, target)
    |> validate_origin(route, manifest.host.origin, request.origin)
  end

  @spec finding_to_denial(Finding.t(), keyword()) :: Denial.t()
  def finding_to_denial(%Finding{} = finding, opts \\ []) do
    route_id = Keyword.get(opts, :route_id, finding.route_id)

    {reason, code, recovery, details} =
      case finding.axis do
        :route ->
          {:inactive_route, nil, recovery_for(:inactive_route, opts), %{}}

        :active_route ->
          {:inactive_route, nil, recovery_for(:inactive_route, opts), %{}}

        :entry ->
          {:external_entry_denied, nil, recovery_for(:external_entry_denied, opts), %{}}

        :notification_open ->
          {:notification_open_denied, nil, recovery_for(:notification_open_denied, opts), %{}}

        :origin ->
          {:origin_denied, nil, %{}, %{}}

        :bridge_command ->
          {:undeclared_capability, nil, %{}, capability_details(finding)}

        :capability_registry ->
          {:undeclared_capability, nil, %{}, capability_details(finding)}

        :capability_version ->
          {:unavailable_capability, nil, %{}, capability_details(finding)}

        :pack_version ->
          {:pack_incompatible, nil, recovery_for(:pack_incompatible, opts),
           pack_details(finding, opts)}

        :auth ->
          # D-137-B: auth sub-classification is carried in finding.code; details are
          # already sanitized by the companion source (DenialCodes.sanitize_details/1).
          # Pass details through UNMERGED — no :axis key injected (audit fix ①).
          {:step_up_required, finding.code, %{}, finding.details}

        axis ->
          if axis in commerce_corridor_axes() do
            {code, recovery, details} = commerce_corridor_denial(axis, finding, opts)
            {:commerce_corridor, code, recovery, details}
          else
            {:compatibility_mismatch, nil, recovery_for(:compatibility_mismatch, opts), %{}}
          end
      end

    details =
      cond do
        finding.axis == :auth ->
          # :auth details are already sanitized; pass through UNMERGED (audit fix ①).
          # base_details/1 injects :axis for all axes and :auth is not in the sigra
          # allowlist, so an unguarded merge would smuggle a non-allowlisted key into
          # already-sanitized auth details.
          details

        finding.axis == :pack_version and Keyword.has_key?(opts, :current_route_id) ->
          details

        true ->
          Map.merge(base_details(finding), details)
      end

    Denial.new(
      reason: reason,
      code: code || Atom.to_string(reason),
      route_id: route_id,
      message: finding.message,
      hint: finding.hint,
      details: details,
      recovery: recovery
    )
  end

  defp validate_contract_version(errors, compatibility, axis) do
    case Map.get(compatibility, axis) do
      value when is_binary(value) and value != "" ->
        errors

      _other ->
        [
          %{
            key: axis,
            message: "#{axis} must be declared",
            hint: "set a version string for #{axis}"
          }
          | errors
        ]
    end
  end

  defp validate_supported_manifest_sources(errors, %CompatibilityTruth{} = compatibility) do
    if compatibility.supported_manifest_sources == [] do
      [
        %{
          key: :supported_manifest_sources,
          message: "compatibility must declare bundled, cached, or remote manifest sources",
          hint: "set supported_manifest_sources to the allowed manifest source modes"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_remote_updates(errors, %CompatibilityTruth{} = compatibility) do
    invalid =
      compatibility.remote_updates
      |> Enum.reject(&(&1 in [:versioned_replacement, :versioned_companion_data]))

    if invalid == [] do
      errors
    else
      [
        %{
          key: :remote_updates,
          message:
            "remote updates must stay within versioned manifest replacement or versioned companion data",
          hint:
            "remove #{Enum.map_join(invalid, ", ", &inspect/1)} and keep remote updates constrained to versioned replacement or companion data"
        }
        | errors
      ]
    end
  end

  defp validate_route_presence(errors, route_id, nil) do
    [
      %Finding{
        axis: :route,
        route_id: route_id,
        message: "route #{route_id} is not present in the manifest",
        hint: "compile route policy into the manifest before attempting activation"
      }
      | errors
    ]
  end

  defp validate_route_presence(errors, _route_id, _route), do: errors

  defp validate_external_entry(errors, nil, _opts), do: errors

  defp validate_external_entry(errors, %RouteEntry{} = route, opts) do
    if external_activation?(Keyword.get(opts, :activation_source)) and route.entry != :external do
      [
        %Finding{
          axis: :entry,
          route_id: route.id,
          subject: Atom.to_string(route.entry),
          required: :external,
          available: route.entry,
          message: "route #{route.id} does not allow external entry",
          hint: "declare entry: :external on the route policy before opening it from an inbound deep link"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_notification_open(errors, nil, _opts), do: errors

  defp validate_notification_open(errors, %RouteEntry{} = route, opts) do
    if Keyword.get(opts, :activation_source) == :notification and is_nil(route.notification_open) do
      [
        %Finding{
          axis: :notification_open,
          route_id: route.id,
          required: "notification_open: true",
          available: "nil",
          message: "route #{route.id} does not allow notification open",
          hint: "declare notification_open: true on the route policy before opening it from a push notification"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_manifest_schema(errors, _compatibility, _target, nil), do: errors

  defp validate_manifest_schema(
         errors,
         %CompatibilityTruth{} = compatibility,
         %Target{} = target,
         %RouteEntry{id: route_id}
       ) do
    if compatible_version?(target.manifest_schema_version, compatibility.manifest_schema_version) do
      errors
    else
      [
        finding(
          :manifest_schema_version,
          route_id,
          compatibility.manifest_schema_version,
          target.manifest_schema_version,
          "manifest schema #{compatibility.manifest_schema_version} is newer than the shell can read",
          "ship a shell that supports manifest schema #{compatibility.manifest_schema_version}"
        )
        | errors
      ]
    end
  end

  defp validate_bridge_protocol(errors, _compatibility, _target, nil), do: errors

  defp validate_bridge_protocol(
         errors,
         %CompatibilityTruth{} = compatibility,
         %Target{} = target,
         %RouteEntry{id: route_id}
       ) do
    if compatible_version?(target.bridge_protocol_version, compatibility.bridge_protocol_version) do
      errors
    else
      [
        finding(
          :bridge_protocol_version,
          route_id,
          compatibility.bridge_protocol_version,
          target.bridge_protocol_version,
          "route requires bridge protocol #{compatibility.bridge_protocol_version} but the shell exposes #{target.bridge_protocol_version || "none"}",
          "upgrade the shell bridge before activating #{route_id}"
        )
        | errors
      ]
    end
  end

  defp validate_native_runtime(errors, _compatibility, _target, nil), do: errors

  defp validate_native_runtime(
         errors,
         %CompatibilityTruth{} = compatibility,
         %Target{} = target,
         %RouteEntry{id: route_id}
       ) do
    if compatible_version?(target.native_runtime_version, compatibility.native_runtime_version) do
      errors
    else
      [
        finding(
          :native_runtime_version,
          route_id,
          compatibility.native_runtime_version,
          target.native_runtime_version,
          "route requires newer shell runtime #{compatibility.native_runtime_version}",
          "ship a binary with native runtime #{compatibility.native_runtime_version} before activating #{route_id}"
        )
        | errors
      ]
    end
  end

  defp validate_capabilities(errors, nil, _registry, _target), do: errors

  defp validate_capabilities(errors, %RouteEntry{} = route, registry, %Target{} = target) do
    Enum.reduce(route.capabilities, errors, fn capability_id, acc ->
      case Map.get(registry, capability_id) do
        nil ->
          [
            finding(
              :capability_registry,
              route.id,
              capability_id,
              nil,
              "route requires capability #{capability_id}, but it is not declared in the manifest registry",
              "declare capability #{capability_id} in the manifest registry before activating #{route.id}",
              capability_id
            )
            | acc
          ]

        capability ->
          required_version = Map.get(capability, :version)
          available_version = Map.get(target.capabilities, capability_id)

          if compatible_version?(available_version, required_version) do
            acc
          else
            [
              finding(
                :capability_version,
                route.id,
                required_version,
                available_version,
                "route requires capability #{capability_id} at #{required_version}",
                "bundle capability #{capability_id} at #{required_version} or remove it from the route allowlist",
                capability_id
              )
              | acc
            ]
          end
      end
    end)
  end

  defp validate_packs(errors, nil, _target), do: errors

  defp validate_packs(errors, %RouteEntry{} = route, %Target{} = target) do
    Enum.reduce(route.packs, errors, fn pack_requirement, acc ->
      {pack_id, required_version} = parse_pack_requirement(pack_requirement)
      lifecycle = PackRuntime.lifecycle(pack_requirement, Map.get(target.packs, pack_id))

      if PackRuntime.available?(lifecycle) do
        acc
      else
        [
          finding(
            :pack_version,
            route.id,
            required_version || "present",
            lifecycle_available_value(lifecycle),
            pack_message(pack_id, required_version, lifecycle),
            pack_hint(pack_id, required_version, lifecycle),
            pack_id
          )
          | acc
        ]
      end
    end)
  end

  defp validate_manifest_source(errors, _compatibility, _target, nil), do: errors

  defp validate_manifest_source(
         errors,
         %CompatibilityTruth{} = compatibility,
         %Target{} = target,
         %RouteEntry{id: route_id}
       ) do
    if target.manifest_source in compatibility.supported_manifest_sources do
      errors
    else
      [
        %Finding{
          axis: :manifest_source,
          route_id: route_id,
          required:
            compatibility.supported_manifest_sources
            |> Enum.map_join(", ", &Atom.to_string/1),
          available: target.manifest_source,
          message:
            "route cannot activate from #{target.manifest_source} manifest source because the shell only supports #{Enum.map_join(compatibility.supported_manifest_sources, ", ", &Atom.to_string/1)} manifests",
          hint:
            "use bundled or cached manifest truth until the shipped shell supports #{target.manifest_source} manifests"
        }
        | errors
      ]
    end
  end

  defp validate_origin(errors, nil, _expected_origin, _actual_origin), do: errors

  defp validate_origin(
         errors,
         %RouteEntry{id: route_id, allowlisted_origins: origins},
         expected_origin,
         actual_origin
       ) do
    allowed_origins = if origins == [], do: [expected_origin], else: origins

    if actual_origin in allowed_origins do
      errors
    else
      [
        %Finding{
          axis: :origin,
          route_id: route_id,
          required: Enum.join(allowed_origins, ", "),
          available: actual_origin,
          message:
            "origin mismatch for #{route_id}; expected #{Enum.join(allowed_origins, ", ")}",
          hint: "bind the route to an allowlisted origin before activating it"
        }
        | errors
      ]
    end
  end

  defp validate_active_route(errors, %Contract.Request{
         route_id: route_id,
         active_route_id: active_route_id
       }) do
    if route_id == active_route_id do
      errors
    else
      [
        %Finding{
          axis: :active_route,
          route_id: route_id,
          required: route_id,
          available: active_route_id,
          message: "bridge request route #{route_id} is not the active route #{active_route_id}",
          hint: "execute bounded bridge calls only for the active route"
        }
        | errors
      ]
    end
  end

  defp validate_bridge_command(errors, nil, _registry, _request), do: errors

  defp validate_bridge_command(
         errors,
         %RouteEntry{} = route,
         registry,
         %Contract.Request{} = request
       ) do
    case Registry.command_capability(request.command) do
      nil ->
        [
          finding(
            :bridge_command,
            route.id,
            Enum.join(Registry.allowed_commands(), ", "),
            request.command,
            "bridge command #{request.command} is outside the bounded Phase 3 command set",
            "use app.info.get, haptics.impact, or files.pick",
            request.command
          )
          | errors
        ]

      capability_id ->
        errors
        |> validate_bridge_capability_identity(route, request, capability_id)
        |> validate_bridge_capability_route(route, capability_id)
        |> validate_bridge_capability_version(route, registry, request, capability_id)
    end
  end

  defp validate_bridge_capability_identity(errors, route, request, capability_id) do
    if request.capability == capability_id do
      errors
    else
      [
        finding(
          :bridge_command,
          route.id,
          capability_id,
          request.capability,
          "bridge command #{request.command} must declare capability #{capability_id}",
          "align the bridge envelope capability with manifest truth",
          capability_id
        )
        | errors
      ]
    end
  end

  defp validate_bridge_capability_route(errors, route, capability_id) do
    if capability_id in route.capabilities do
      errors
    else
      [
        finding(
          :capability_registry,
          route.id,
          capability_id,
          nil,
          "route #{route.id} does not declare capability #{capability_id} for bridge execution",
          "add #{capability_id} to the route capability allowlist before opening the bridge command",
          capability_id
        )
        | errors
      ]
    end
  end

  defp validate_bridge_capability_version(errors, route, registry, request, capability_id) do
    case Map.get(registry, capability_id) do
      nil ->
        [
          finding(
            :capability_registry,
            route.id,
            capability_id,
            nil,
            "route requires capability #{capability_id}, but it is not declared in the manifest registry",
            "declare capability #{capability_id} in the manifest registry before executing #{request.command}",
            capability_id
          )
          | errors
        ]

      %Capability{version: required_version} ->
        available_version = Map.get(request.capabilities, capability_id)

        if compatible_version?(available_version, required_version) do
          errors
        else
          [
            finding(
              :capability_version,
              route.id,
              required_version,
              available_version,
              "bridge command #{request.command} requires capability #{capability_id} at #{required_version}",
              "bundle capability #{capability_id} at #{required_version} before executing #{request.command}",
              capability_id
            )
            | errors
          ]
        end
    end
  end

  defp bridge_target(%Contract.Request{} = request) do
    %Target{
      manifest_schema_version: Types.manifest_schema_version(),
      bridge_protocol_version: request.version,
      native_runtime_version: request.native_runtime_version,
      origin: request.origin,
      active_route_id: request.active_route_id,
      capabilities: request.capabilities,
      packs: request.installed_packs
    }
  end

  defp compatible_version?(available, required)
       when is_binary(available) and is_binary(required) do
    case {normalize_version(available), normalize_version(required)} do
      {{:ok, normalized_available}, {:ok, normalized_required}} ->
        Version.compare(normalized_available, normalized_required) != :lt

      _other ->
        available == required
    end
  end

  defp compatible_version?(_available, _required), do: false

  defp normalize_version(value) do
    parts = String.split(value, ".")

    normalized =
      case parts do
        [major] -> "#{major}.0.0"
        [major, minor] -> "#{major}.#{minor}.0"
        [_, _, _] -> value
        _other -> value
      end

    Version.parse(normalized)
  end

  defp finding(axis, route_id, required, available, message, hint) do
    %Finding{
      axis: axis,
      route_id: route_id,
      required: required,
      available: available,
      message: message,
      hint: hint
    }
  end

  defp finding(axis, route_id, required, available, message, hint, subject) do
    %Finding{
      axis: axis,
      route_id: route_id,
      required: required,
      available: available,
      message: message,
      hint: hint,
      subject: subject
    }
  end

  defp parse_pack_requirement(pack_requirement) do
    case String.split(pack_requirement, "@", parts: 2) do
      [pack_id, required_version] -> {pack_id, required_version}
      [pack_id] -> {pack_id, nil}
    end
  end

  defp lifecycle_available_value(%{version: version}) when is_binary(version), do: version
  defp lifecycle_available_value(%{state: state}), do: state

  defp pack_message(pack_id, nil, %{state: :not_installed}),
    do: "route requires pack #{pack_id}, but it is not installed in the shell"

  defp pack_message(pack_id, required_version, %{state: :not_installed}),
    do:
      "route requires pack #{pack_id} at #{required_version}, but it is not installed in the shell"

  defp pack_message(pack_id, required_version, %{state: :stale, version: available_version}),
    do:
      "route requires pack #{pack_id} at #{required_version}, but the shell exposes #{available_version}"

  defp pack_message(pack_id, required_version, %{state: :invalidating}),
    do:
      "route requires pack #{pack_id} at #{required_version}, but the shell is invalidating that pack"

  defp pack_message(pack_id, required_version, %{state: :failed, failure: %{reason: :verification_missing}}),
    do:
      "route requires pack #{pack_id} at #{required_version}, but the shell has not verified the installed pack yet"

  defp pack_message(pack_id, required_version, %{state: state}),
    do:
      "route requires pack #{pack_id} at #{required_version}, but the shell reports #{state}"

  defp pack_hint(pack_id, nil, %{state: :not_installed}),
    do: "install pack #{pack_id} in the shell before activating the route"

  defp pack_hint(pack_id, required_version, %{state: :stale}),
    do: "install or update pack #{pack_id} to #{required_version} before activating the route"

  defp pack_hint(pack_id, required_version, %{state: :invalidating}),
    do: "wait for invalidation to finish, then reinstall pack #{pack_id} at #{required_version}"

  defp pack_hint(pack_id, required_version, %{state: :failed}),
    do: "verify or reinstall pack #{pack_id} at #{required_version} before activating the route"

  defp pack_hint(pack_id, required_version, _lifecycle),
    do: "install or update pack #{pack_id} to #{required_version} before activating the route"

  defp base_details(finding) do
    %{}
    |> maybe_put(:axis, finding.axis)
    |> maybe_put(:required, finding.required)
    |> maybe_put(:available, finding.available)
    |> maybe_put(:subject, finding.subject)
  end

  defp capability_details(finding), do: %{} |> maybe_put(:capability_id, finding.subject)

  defp pack_details(_finding, opts) do
    %{}
    |> maybe_put(:current_route_id, Keyword.get(opts, :current_route_id))
  end

  defp recovery_for(:inactive_route, opts) do
    case Keyword.get(opts, :fallback_route_id) do
      nil ->
        %{}

      fallback_route_id ->
        %{
          mode: :safe_fallback,
          fallback_route_id: fallback_route_id,
          actions: [:retry, :open_safe_fallback]
        }
    end
  end

  defp recovery_for(:external_entry_denied, opts) do
    case Keyword.get(opts, :fallback_route_id) do
      nil ->
        %{actions: [:retry]}

      fallback_route_id ->
        %{
          mode: :safe_fallback,
          fallback_route_id: fallback_route_id,
          actions: [:retry, :open_safe_fallback]
        }
    end
  end

  defp recovery_for(:notification_open_denied, opts) do
    case Keyword.get(opts, :fallback_route_id) do
      nil ->
        %{actions: [:retry]}

      fallback_route_id ->
        %{
          mode: :safe_fallback,
          fallback_route_id: fallback_route_id,
          actions: [:retry, :open_safe_fallback]
        }
    end
  end

  defp recovery_for(:pack_incompatible, opts) do
    base = %{actions: [:retry, :update_app]}

    case Keyword.get(opts, :activation_source) do
      :deep_link ->
        case Keyword.get(opts, :fallback_route_id) do
          nil ->
            Map.put(base, :mode, :safe_retry)

          fallback_route_id ->
            %{
              mode: :safe_fallback,
              fallback_route_id: fallback_route_id,
              actions: [:retry, :open_safe_fallback, :update_app]
            }
        end

      _other ->
        %{}
    end
  end

  defp recovery_for(:compatibility_mismatch, opts) do
    if Keyword.get(opts, :activation_source) == :deep_link do
      %{actions: [:retry, :update_app], mode: :safe_retry}
    else
      %{}
    end
  end

  defp commerce_corridor_axes do
    [
      :commerce_corridor_undeclared,
      :commerce_corridor_unsupported,
      :commerce_corridor_prerequisite_missing,
      :commerce_corridor_runtime_incompatible,
      :commerce_corridor_entry_denied,
      :commerce_corridor_origin_denied,
      :commerce_corridor_policy_blocked,
      :commerce_corridor_pack_incompatible
    ]
  end

  defp commerce_corridor_denial(:commerce_corridor_undeclared, finding, opts) do
    details =
      %{}
      |> maybe_put(:corridor_ref, finding.subject || finding.required)
      |> maybe_put(:role, finding.available)

    recovery =
      commerce_recovery(
        opts,
        :declare_corridor,
        [:return_to_phoenix_guidance, :declare_corridor_or_disable_commerce_route]
      )

    {"commerce.corridor.undeclared", recovery, details}
  end

  defp commerce_corridor_denial(:commerce_corridor_unsupported, _finding, opts) do
    recovery =
      commerce_recovery(opts, :route_gate, [:return_to_phoenix_guidance, :review_supported_roles])

    {"commerce.corridor.unsupported", recovery, %{}}
  end

  defp commerce_corridor_denial(:commerce_corridor_prerequisite_missing, finding, opts) do
    details =
      %{}
      |> maybe_put(:prerequisite, finding.subject || finding.required)

    recovery =
      commerce_recovery(
        opts,
        :prerequisite,
        [:return_to_phoenix_guidance, :declare_corridor_or_disable_commerce_route]
      )

    {"commerce.corridor.prerequisite_missing", recovery, details}
  end

  defp commerce_corridor_denial(:commerce_corridor_runtime_incompatible, finding, opts) do
    details =
      %{}
      |> maybe_put(:required_runtime, finding.required)
      |> maybe_put(:available_runtime, finding.available)

    recovery = commerce_recovery(opts, :runtime, [:return_to_phoenix_guidance, :update_app])

    {"commerce.corridor.runtime_incompatible", recovery, details}
  end

  defp commerce_corridor_denial(:commerce_corridor_entry_denied, _finding, opts) do
    recovery = commerce_recovery(opts, :entry, [:return_to_phoenix_guidance, :retry])
    {"commerce.corridor.entry_denied", recovery, %{}}
  end

  defp commerce_corridor_denial(:commerce_corridor_origin_denied, _finding, opts) do
    recovery = commerce_recovery(opts, :origin, [:return_to_phoenix_guidance])
    {"commerce.corridor.origin_denied", recovery, %{}}
  end

  defp commerce_corridor_denial(:commerce_corridor_policy_blocked, finding, opts) do
    details =
      %{}
      |> maybe_put(:policy, finding.required)
      |> maybe_put(:available, finding.available)

    recovery =
      commerce_recovery(
        opts,
        :policy,
        [:return_to_phoenix_guidance, :declare_corridor_or_disable_commerce_route]
      )

    {"commerce.corridor.policy_blocked", recovery, details}
  end

  defp commerce_corridor_denial(:commerce_corridor_pack_incompatible, finding, opts) do
    recovery = commerce_recovery(opts, :pack, [:return_to_phoenix_guidance, :update_app])
    {"commerce.corridor.pack_incompatible", recovery, pack_details(finding, opts)}
  end

  defp commerce_recovery(opts, mode, actions) do
    %{
      mode: mode,
      actions: actions,
      fallback: :return_to_phoenix_guidance,
      corridor_action: :declare_corridor_or_disable_commerce_route,
      activation_source: Keyword.get(opts, :activation_source)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp external_activation?(source), do: source in [:deep_link, :notification]
end
