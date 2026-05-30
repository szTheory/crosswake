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
