defmodule Crosswake.Proof.Phase45RindleCompanionTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 45 Rindle companion.

  The optional Rindle dependency is intentionally absent in this lane.
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

  test "validate_dependency/0 fails closed while optional Rindle library is absent" do
    assert Rindle.validate_dependency() == {:error, [:"Elixir.Rindle"]}
  end

  test "report_state/0 returns a media contract-only companion state" do
    state = Rindle.report_state()

    assert %Crosswake.Companion.State{} = state
    assert state.companion_id == :rindle
    assert state.enabled == true
    assert state.dependency_status == {:missing, [:"Elixir.Rindle"]}
    assert state.gate_status == :unconfigured
    assert state.kill_switch_status == :inactive
    assert state.details.surface == :media
    assert state.details.mode == :contract_only
    assert is_integer(state.checked_at)
  end

  test "Doctor emits companion.dependency_missing :error when Rindle is enabled and absent",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: MediaRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))

    assert finding != nil,
           "expected companion.dependency_missing; got #{inspect(Enum.map(report.findings, & &1.code))}"

    assert finding.severity == :error
    assert finding.check == "companion.rindle"
    assert finding.details.missing_modules == [:"Elixir.Rindle"]
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
