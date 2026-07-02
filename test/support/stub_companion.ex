defmodule Crosswake.TestSupport.StubRulesteadAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Rulestead with the engine absent from core deps.

  Used in core tests (phase42, phase47, companions guide) that registered
  `Crosswake.Companions.Rulestead` before Phase 130 extracted it to
  `packages/crosswake_rulestead/`. The stub has `companion_id: :rulestead` so
  Doctor findings carry `finding.check == "companion.rulestead"`.

  `validate_dependency/0` returns `{:error, [:"Elixir.Rulestead"]}` because
  rulestead is absent from core deps (EXTRACT-01 guard, D-21).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :rulestead

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [:"Elixir.Rulestead"]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :rulestead, %{})

    %Crosswake.Companion.State{
      companion_id: :rulestead,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [:"Elixir.Rulestead"]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule Crosswake.TestSupport.StubRindleAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Rindle with the engine absent from core deps.

  Used in core tests (phase47, companions guide) that registered
  `Crosswake.Companions.Rindle` before Phase 132 extracted it to
  `packages/crosswake_rindle/`. The stub has `companion_id: :rindle` so
  Doctor findings carry `finding.check == "companion.rindle"`.

  `validate_dependency/0` returns `{:error, [:"Elixir.Rindle"]}` because
  rindle is absent from core deps (EXTRACT-01 guard, D-21).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :rindle

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [:"Elixir.Rindle"]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :rindle, %{})

    %Crosswake.Companion.State{
      companion_id: :rindle,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [:"Elixir.Rindle"]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule Crosswake.TestSupport.StubChimewayAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Chimeway with the package absent from core deps.

  Models the post-Phase-138 extracted state where `Crosswake.Companions.Chimeway`
  is not in core deps. The stub has `companion_id: :chimeway` so Doctor findings
  carry `finding.check == "companion.chimeway"`.

  `validate_dependency/0` returns `{:error, [Crosswake.Companions.Chimeway]}` to
  model chimeway absent from core deps (EXTRACT-01 guard, D-21).

  Note: `auth_authority?/0` is intentionally absent. Chimeway is a notification
  companion, not an auth authority — it has no auth_authority?/0 callback in the
  real implementation either. This stub correctly omits it (CHIME-02).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :chimeway

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [Crosswake.Companions.Chimeway]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :chimeway, %{})

    %Crosswake.Companion.State{
      companion_id: :chimeway,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [Crosswake.Companions.Chimeway]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule Crosswake.TestSupport.StubSigraAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Sigra with the engine absent from core deps.

  Used in core tests that need to drive the auth fail-closed `:dependency_missing`
  path after Phase 137 extracts `Crosswake.Companions.Sigra` to the standalone
  `packages/crosswake_sigra/` package. Once extracted, Sigra is no longer a core
  dep, so any test exercising the absent-authority path must register this stub
  instead of the real `Crosswake.Companions.Sigra` module.

  `companion_id/0` returns `:sigra` so Doctor findings carry `finding.check ==
  "companion.sigra"`. `validate_dependency/0` returns `{:error, [Crosswake.Companions.Sigra]}`
  to model sigra absent from core deps (post-extraction state).

  `auth_authority?/0` returns `false` — the engine (Sigra.Evaluator) is absent, so
  this stub has no auth authority. This drives the `:dependency_missing` fail-closed
  deny path: an auth-predicated route with no companion reporting `auth_authority? == true`
  in the registry yields `:dependency_missing` (D-137-D, research assumption A1).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :sigra

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [Crosswake.Companions.Sigra]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :sigra, %{})

    %Crosswake.Companion.State{
      companion_id: :sigra,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [Crosswake.Companions.Sigra]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end

  @impl true
  def auth_authority?, do: false
end

defmodule Crosswake.TestSupport.StubCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_companion

  @impl true
  def enabled?(_config), do: true

  @impl true
  def route_gated?(_route, _context), do: :pass

  @impl true
  def kill_switch_active?(_context), do: false

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule Crosswake.TestSupport.BrokenCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :broken_companion

  @impl true
  def enabled?(_config), do: true

  @impl true
  def route_gated?(_route, _context), do: :pass

  @impl true
  def kill_switch_active?(_context), do: false

  @impl true
  def validate_dependency, do: {:error, [Crosswake.TestSupport.DeliberatelyAbsentLib]}

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :broken_companion,
      enabled: true,
      dependency_status: {:missing, [Crosswake.TestSupport.DeliberatelyAbsentLib]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end

defmodule Crosswake.TestSupport.StubTelemetryCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_telemetry

  @impl true
  def enabled?(_config), do: true

  @impl true
  def route_gated?(_route, _context), do: :pass

  @impl true
  def kill_switch_active?(_context), do: false

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_telemetry,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end

  # Optional callback — proves the companion telemetry_events/0 merge mechanism (D-17).
  # @impl true required: Elixir 1.19 tracks optional callbacks in behaviour_info(:callbacks)
  # and warns if @impl is absent (contrary to earlier Elixir convention).
  @impl true
  def telemetry_events do
    [
      %{
        event: [:crosswake, :stub_telemetry, :example],
        tier: :active,
        description:
          "Stub telemetry event for testing the companion merge mechanism (TELEM-04 D-17).",
        measurements: [:duration],
        metadata: [:companion_id]
      }
    ]
  end
end
