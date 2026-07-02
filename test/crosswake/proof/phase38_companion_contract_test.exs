defmodule Crosswake.Proof.Phase38CompanionContractTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 38 companion seam contract.

  Proves SC#1 (behaviour satisfiable with no extra boilerplate), SC#2
  (enabled companion with missing optional dep → fail-closed :error finding from
  the doctor — silent fail-open is structurally impossible), and SC#4 (the real
  [:crosswake, :companion, :validate_dependency] telemetry span emits with
  companion_id metadata, Keathley static-name convention).

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs UNtagged so the existing
  phase34-proof.yml `mix test --exclude requires_example_host` lane picks it up
  with no new CI file (D-13).

  Application.get_env is used in phase_38_companion_seam_findings/0 (not
  compile_env) specifically so this proof test can register fixtures at runtime
  via put_env and observe the registration inside the doctor pipeline. All put_env
  calls are paired with on_exit cleanup to avoid leaking state across tests.
  """

  # async: false — SC#2 and SC#4 both write the shared global
  # Application.put_env(:crosswake, :companions, ...) key; running them
  # concurrently lets one test observe another's companion list (CR-01).
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.Target
  alias Crosswake.Doctor
  alias Crosswake.Manifest.Types.RouteEntry

  # Minimal hermetic router providing a single route for Doctor.run
  defmodule MinimalRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
        live "/home", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "home", runtime: :live_view]
      end
    end
  end

  # Shared setup for tests that need to run Doctor.run hermetically.
  # Creates a temp directory with a minimal install manifest so Doctor.run
  # has a valid install context (mirrors phase23 proof setup).
  setup do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase38-proof-#{System.unique_integer([:positive])}"
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

    # Save/restore :companions so per-test put_env + delete_env cleanup does not
    # destroy the application-env default added in mix.exs in Phase 136 gap closure.
    original_companions = Application.get_env(:crosswake, :companions, [])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original_companions) end)

    %{target: target, install_manifest_path: install_manifest_path}
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion (mirrors phase33 guard)
  # ---------------------------------------------------------------------------

  test "phase 38 companion contract proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 38 companion proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 38 companion proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # SC#1 — behaviour satisfaction: all 6 callbacks compile with no extra boilerplate
  # ---------------------------------------------------------------------------

  test "SC#1: StubCompanion satisfies all 6 Crosswake.Companion callbacks at compile time" do
    # companion_id/0
    assert Crosswake.TestSupport.StubCompanion.companion_id() == :stub_companion

    # enabled?/1 — ignores the config map, returns true
    assert Crosswake.TestSupport.StubCompanion.enabled?(%{}) == true
    assert Crosswake.TestSupport.StubCompanion.enabled?(%{enabled: false}) == true

    # route_gated?/2 — :pass (the closed non-denial value, D-06)
    route_entry = %RouteEntry{id: "test-route", path: "/test", runtime: :live_view}
    target = %Target{}
    assert Crosswake.TestSupport.StubCompanion.route_gated?(route_entry, target) == :pass

    # kill_switch_active?/1 — false
    assert Crosswake.TestSupport.StubCompanion.kill_switch_active?(target) == false

    # validate_dependency/0 — :ok (dependency present)
    assert Crosswake.TestSupport.StubCompanion.validate_dependency() == :ok

    # report_state/0 — returns a Crosswake.Companion.State struct
    assert match?(%Crosswake.Companion.State{}, Crosswake.TestSupport.StubCompanion.report_state())

    state = Crosswake.TestSupport.StubCompanion.report_state()
    assert state.companion_id == :stub_companion
    assert state.enabled == true
    assert state.dependency_status == :present
    assert state.gate_status == :unconfigured
    assert state.kill_switch_status == :unconfigured
    assert is_integer(state.checked_at)
  end

  # ---------------------------------------------------------------------------
  # SC#2 — fail-closed doctor error: enabled companion with missing dep → :error
  # ---------------------------------------------------------------------------

  test "SC#2: doctor emits companion.dependency_missing :error when enabled companion's validate_dependency returns {:error, mods}",
       %{target: target, install_manifest_path: install_manifest_path} do
    # BrokenCompanion.enabled?/1 always returns true; no separate config put_env needed.
    # We register the companion list and clean up on_exit to avoid leaking state.
    Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.BrokenCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: MinimalRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))

    assert finding != nil,
           "expected a companion.dependency_missing finding but got none; findings: #{inspect(report.findings)}"

    assert finding.severity == :error,
           "expected finding.severity == :error but got #{inspect(finding.severity)}"

    assert %{missing_modules: [Crosswake.TestSupport.DeliberatelyAbsentLib]} = finding.details

    assert String.contains?(finding.message, "Elixir.Crosswake.TestSupport.DeliberatelyAbsentLib") or
             String.contains?(finding.message, "DeliberatelyAbsentLib"),
           "expected finding.message to name the absent module; got: #{inspect(finding.message)}"

    assert finding.check == "companion.broken_companion",
           "expected finding.check == 'companion.broken_companion' but got #{inspect(finding.check)}"

    # Fail-closed: the report status must be :error when this finding is present
    assert report.status == :error,
           "expected report.status == :error when a companion.dependency_missing finding is present"
  end

  # ---------------------------------------------------------------------------
  # SC#4 — telemetry span: [:crosswake, :companion, :validate_dependency] emits :stop
  # ---------------------------------------------------------------------------

  test "SC#4: doctor emits [:crosswake, :companion, :validate_dependency, :stop] telemetry with companion_id metadata",
       %{target: target, install_manifest_path: install_manifest_path} do
    test_pid = self()

    handler_id = "phase38-test-handler-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:crosswake, :companion, :validate_dependency, :stop],
      fn _event, _measurements, metadata, _config ->
        send(test_pid, {:telemetry_stop, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # Register StubCompanion (result :ok) to trigger the span via Doctor.run
    Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.StubCompanion])
    on_exit(fn -> Application.delete_env(:crosswake, :companions) end)

    Doctor.run(
      route_source: MinimalRouter,
      install_manifest_path: install_manifest_path,
      cwd: target
    )

    assert_receive {:telemetry_stop, %{companion_id: :stub_companion, result: :ok}}, 1000
  end
end
