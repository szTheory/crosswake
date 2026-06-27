# ---------------------------------------------------------------------------
# Stub companions: plain modules implementing @behaviour Crosswake.Companion.
# Defined OUTSIDE the test module to avoid nested-module resolution issues.
# NOT aliases to Crosswake.Companions.Rulestead — avoids EXTRACT-03 (D-20).
# ---------------------------------------------------------------------------

defmodule Crosswake.TestSupport.StubDepMissingCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_dep_missing

  @impl true
  def enabled?(_config), do: true

  # Returns {:error, [SomeAbsentModule]} to simulate the engine being absent.
  @impl true
  def validate_dependency, do: {:error, [SomeAbsentModule]}

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_dep_missing,
      enabled: true,
      dependency_status: {:missing, [SomeAbsentModule]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end
end

# Stub companion with kill switch ON: proves D-02 precedence (dep_missing beats kill_switch).
defmodule Crosswake.TestSupport.StubDepMissingKillSwitchOnCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_dep_missing_ks_on

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: {:error, [SomeAbsentModule]}

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: true

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_dep_missing_ks_on,
      enabled: true,
      dependency_status: {:missing, [SomeAbsentModule]},
      gate_status: :unconfigured,
      kill_switch_status: :active,
      checked_at: 0
    }
  end
end

# Stub companion whose validate_dependency/0 raises — tests D-08 try/rescue.
defmodule Crosswake.TestSupport.StubDepRaisesCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_dep_raises

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: raise("simulated engine load failure")

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_dep_raises,
      enabled: true,
      dependency_status: {:missing, []},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end
end

defmodule Crosswake.Proof.Phase130FailClosedContractTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 130 COMPAT-01 (SC#5).

  Proves that RouteGate.evaluate/4 fails closed (returns :dependency_missing
  denial) when a companion is registered and enabled but its dependency package
  is absent. This test uses a stub companion (NOT an alias to the moved source
  module — that would trip EXTRACT-03, D-20) to verify the seam contract.

  Also proves D-02 precedence (dependency_missing beats kill_switch_active) and
  D-08 (a companion whose validate_dependency/0 raises still produces :dependency_missing).

  async: false — Application.put_env(:crosswake, :companions, ...) is a shared
  global key (D-07, no cache). The stub companion's config key is also shared.

  These tests are RED until Plan 02 wires the check_dependencies/2 function into
  RouteGate.prepend_gate_evaluation_findings/3.
  """

  # async: false — Application.put_env(:crosswake, :companions, ...) is a shared global key (D-07)
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest
  alias Crosswake.TestSupport.ProofAssertions

  # ---------------------------------------------------------------------------
  # Minimal hermetic router with a gated route for stub companions.
  # Uses StudySessionLive (test/support stub) — no phoenix_host dependency.
  # ---------------------------------------------------------------------------

  defmodule StubGatingRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gating/stub-feature", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gating-stub-feature",
            gated_by: :stub_dep_missing,
            on_unavailable: :deny
          ]
      end
    end
  end

  defmodule StubKillSwitchOnRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gating/stub-ks", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gating-stub-ks",
            gated_by: :stub_dep_missing_ks_on,
            on_unavailable: :deny
          ]
      end
    end
  end

  defmodule StubDepRaisesRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gating/stub-raises", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gating-stub-raises",
            gated_by: :stub_dep_raises,
            on_unavailable: :deny
          ]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Setup: save/restore :companions and companion config keys (D-07)
  # ---------------------------------------------------------------------------

  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])
    original_stub_config = Application.get_env(:crosswake, :stub_dep_missing, %{})
    original_ks_config = Application.get_env(:crosswake, :stub_dep_missing_ks_on, %{})
    original_raises_config = Application.get_env(:crosswake, :stub_dep_raises, %{})

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
      Application.put_env(:crosswake, :stub_dep_missing, original_stub_config)
      Application.put_env(:crosswake, :stub_dep_missing_ks_on, original_ks_config)
      Application.put_env(:crosswake, :stub_dep_raises, original_raises_config)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # SC#5 — COMPAT-01: RouteGate denies with :dependency_missing (D-01/D-03)
  # RED until Plan 02 wires check_dependencies/2 into prepend_gate_evaluation_findings/3
  # ---------------------------------------------------------------------------

  test "COMPAT-01 SC#5: RouteGate denies with :dependency_missing when companion dep absent" do
    Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.StubDepMissingCompanion])
    Application.put_env(:crosswake, :stub_dep_missing, %{enabled: true})

    assert {:ok, %{manifest: manifest}} = Manifest.compile(StubGatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-stub-feature", target)

    assert decision.status == :deny,
           ProofAssertions.stable_id_message(
             "proof.compat_01.sc5.deny_status",
             "RouteGate must deny when companion dep is absent",
             "RouteGate.evaluate/4",
             "decision.status was #{inspect(decision.status)} — expected :deny",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 must wire check_dependencies/2 into prepend_gate_evaluation_findings/3 (COMPAT-01)",
             :merge_blocking
           )

    assert decision.denial.reason == :dependency_missing,
           ProofAssertions.stable_id_message(
             "proof.compat_01.sc5.denial_reason",
             "RouteGate denial reason must be :dependency_missing",
             "RouteGate.evaluate/4",
             "decision.denial.reason was #{inspect(decision.denial && decision.denial.reason)} — expected :dependency_missing",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 must synthesize Denial.new(reason: :dependency_missing, ...) inline in check_dependencies/2 (COMPAT-01, D-03)",
             :merge_blocking
           )

    assert decision.denial.details["missing_kind"] == "engine_unvalidated",
           ProofAssertions.stable_id_message(
             "proof.compat_01.sc5.missing_kind",
             "denial details.missing_kind must be \"engine_unvalidated\" when validate_dependency/0 returns {:error, _}",
             "RouteGate.evaluate/4 -> Denial.new details",
             "details[\"missing_kind\"] was #{inspect(decision.denial && decision.denial.details["missing_kind"])} — expected \"engine_unvalidated\"",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 check_dependencies/2 must set details[\"missing_kind\"] = \"engine_unvalidated\" (D-06)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # D-02 precedence: dependency_missing beats kill_switch_active
  # RED until Plan 02 wires check_dependencies/2 before check_kill_switches
  # ---------------------------------------------------------------------------

  test "D-02 precedence: dependency_missing beats kill_switch_active when both apply" do
    Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.StubDepMissingKillSwitchOnCompanion])
    Application.put_env(:crosswake, :stub_dep_missing_ks_on, %{enabled: true})

    assert {:ok, %{manifest: manifest}} = Manifest.compile(StubKillSwitchOnRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-stub-ks", target)

    assert decision.status == :deny,
           "expected :deny for companion with both dep missing and kill switch on"

    assert decision.denial.reason == :dependency_missing,
           ProofAssertions.stable_id_message(
             "proof.d02.precedence.dep_missing_beats_kill_switch",
             "dependency_missing must precede kill_switch_active in D-02 denial precedence order",
             "RouteGate.evaluate/4",
             "decision.denial.reason was #{inspect(decision.denial && decision.denial.reason)} — expected :dependency_missing",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 must run check_dependencies/2 BEFORE check_kill_switches in prepend_gate_evaluation_findings/3 (D-02)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # D-08: validate_dependency/0 raising still produces :dependency_missing
  # Tests the try/rescue catch path in check_dependencies/2
  # RED until Plan 02 wires the try/rescue
  # ---------------------------------------------------------------------------

  test "D-08: validate_dependency/0 raising an exception still produces :dependency_missing" do
    Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.StubDepRaisesCompanion])
    Application.put_env(:crosswake, :stub_dep_raises, %{enabled: true})

    assert {:ok, %{manifest: manifest}} = Manifest.compile(StubDepRaisesRouter)
    target = %Target{}

    decision = RouteGate.evaluate(manifest, "gating-stub-raises", target)

    assert decision.status == :deny,
           "expected :deny when companion validate_dependency/0 raises"

    assert decision.denial.reason == :dependency_missing,
           ProofAssertions.stable_id_message(
             "proof.d08.raise_yields_dependency_missing",
             "validate_dependency/0 raising must still produce :dependency_missing denial (D-08)",
             "RouteGate.evaluate/4",
             "decision.denial.reason was #{inspect(decision.denial && decision.denial.reason)} — expected :dependency_missing",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 check_dependencies/2 must wrap companion.validate_dependency() in try/rescue (D-08)",
             :merge_blocking
           )

    assert decision.denial.details["missing_kind"] == "adapter_unloadable",
           ProofAssertions.stable_id_message(
             "proof.d08.raise_missing_kind_adapter_unloadable",
             "when validate_dependency/0 raises, missing_kind must be \"adapter_unloadable\"",
             "RouteGate.evaluate/4 -> Denial.new details",
             "details[\"missing_kind\"] was #{inspect(decision.denial && decision.denial.details["missing_kind"])} — expected \"adapter_unloadable\"",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 02 check_dependencies/2 rescue path must set missing_kind: :adapter_unloadable (D-06)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-18).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 130 fail-closed contract proof file must not carry @moduletag: tags — it runs untagged (D-18)"
  end
end
