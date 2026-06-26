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
