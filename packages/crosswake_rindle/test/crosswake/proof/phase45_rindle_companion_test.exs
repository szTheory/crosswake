defmodule Crosswake.Proof.Phase45RindleCompanionTest do
  @moduledoc """
  Adapter-behavior proof lane for the Phase 45 Rindle companion.
  Runs inside the crosswake_rindle companion package as a path: dep.

  This test runs with the rindle engine installed (optional: true dep is included
  in the companion's own mix.lock so Code.ensure_loaded?(Rindle) returns true) —
  the engine-PRESENT context for adapter-behavior testing, mirroring rulestead's
  phase42 D-20 split.

  The engine-ABSENT behavior (validate_dependency/0 returning {:error, [Rindle]})
  and the Doctor dependency_missing finding are proved in the core hermetic lane
  (phase47_companion_arc_test.exs + companions_test.exs) via
  StubRindleAbsentCompanion, where rindle is not in deps. The D-20 test split
  preserves both lanes.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rindle
  alias Crosswake.Doctor

  defmodule MediaRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/media/proof", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "media-proof-lane"
          ]
      end
    end
  end

  setup do
    Application.put_env(:crosswake, :companions, [Rindle])
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rindle)
    end)

    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase45-rindle-proof-#{System.unique_integer([:positive])}"
      )

    router_path = Path.join(target, "lib/demo_web/router.ex")
    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(policy_path))
    File.mkdir_p!(Path.dirname(install_manifest_path))

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        # crosswake:install:start
        import Crosswake.Router
        # crosswake:install:end
      end
      """
    )

    File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")

    install_manifest =
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })

    File.write!(install_manifest_path, install_manifest)

    %{target: target, install_manifest_path: install_manifest_path}
  end

  test "implements the non-gating Rindle companion callbacks" do
    assert Rindle.companion_id() == :rindle
    assert Rindle.enabled?(%{enabled: true})
    refute Rindle.enabled?(%{})

    route = %Crosswake.Manifest.Types.RouteEntry{
      id: "media-proof-lane",
      path: "/media/proof",
      runtime: :live_view
    }

    assert Rindle.route_gated?(route, %Crosswake.Compatibility.Target{}) == :pass
    assert Rindle.kill_switch_active?(%Crosswake.Compatibility.Target{}) == false
  end

  test "validate_dependency/0 returns :ok when the optional Rindle engine is present" do
    assert Rindle.validate_dependency() == :ok
  end

  test "report_state/0 returns a media contract-only companion state (engine present)" do
    state = Rindle.report_state()

    assert %Crosswake.Companion.State{} = state
    assert state.companion_id == :rindle
    assert state.enabled == true
    assert state.dependency_status == :present
    assert state.gate_status == :unconfigured
    assert state.kill_switch_status == :inactive
    assert state.details.surface == :media
    assert state.details.mode == :contract_only
    assert is_integer(state.checked_at)
  end

  test "Doctor emits no companion.dependency_missing finding when Rindle engine is present",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: MediaRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.filter(report.findings, &(&1.code == "companion.dependency_missing")) == [],
           "engine present — expected no dependency_missing; got #{inspect(Enum.map(report.findings, & &1.code))}"
  end

  test "Doctor emits no dependency_missing finding when Rindle is disabled",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :rindle, %{enabled: false})

    report =
      Doctor.run(
        route_source: MediaRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.filter(report.findings, &(&1.code == "companion.dependency_missing")) == []
  end
end
