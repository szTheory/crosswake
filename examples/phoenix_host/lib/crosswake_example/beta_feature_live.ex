defmodule CrosswakeExample.BetaFeatureLive do
  @moduledoc """
  Minimal LiveView served only when the Rulestead gate passes.

  Gate denial is handled entirely by `Crosswake.Compatibility.RouteGate` before this
  LiveView mounts — when `MockFlagSource` has `:gated` or `{:rolling_out, _}` set for
  the `:rulestead` companion, the request receives a `:gate_denied` denial and never
  reaches `mount/3`. When `:killed`, it receives a `:kill_switch_active` denial.

  Drive gate states in IEx:
      alias Crosswake.Companions.Rulestead.MockFlagSource

      # block access (gate_denied)
      MockFlagSource.set_flag(:rulestead, :gated)

      # rolling out at 50%
      MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})

      # kill-switch (kill_switch_active)
      MockFlagSource.set_flag(:rulestead, :killed)

      # allow all (no gate denial)
      MockFlagSource.reset()
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :flag_key, :rulestead)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="gating-beta-feature">
      <h2>Beta Feature</h2>
      <p>You have access to the beta feature. Gate passed for companion <code>{@flag_key}</code>.</p>
    </div>
    """
  end
end
