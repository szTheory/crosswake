defmodule Crosswake.Proof.Phase41GatingDoctorTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 41 gating doctor category.

  Proves SC#1 (GATE-05 diagnostics half): Doctor.run/1 emits the dedicated
  "Gating" category findings:
    - :advisory "gating.route_gated" for each gated route (one per route)
    - :error "gating.flag_reference_unknown" when gated_by atom resolves to no registered companion
    - :warning "gating.fallback_route_unknown" when {:fallback_phoenix, route_id} target is absent

  Proves SC#2 (GATE-05 support-matrix half): SupportMatrix.gating_truth/0 maps each
  registered companion's report_state/0 to the D-08 locked gate-state display strings:
    - "gated" for gate_status: :active
    - "rolling_out (N%)" for gate_status: {:rolling_out, n}
    - "killed" for kill_switch_status: :active (overrides gate_status — kill switch first)
  The runtime-distinct column label is also proven (contains "runtime" / "not build-proof").

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs with @tag :sc1 / @tag :sc2 so each
  sub-criterion can be run selectively.

  async: false — :companions is a shared global Application key; concurrent tests
  would observe each other's companion registrations.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.SupportMatrix

  # ---------------------------------------------------------------------------
  # Inline fixture companion — companion_id :test_gating_companion
  # Used to exercise the resolvable gated_by path (:advisory finding only, no :error)
  # ---------------------------------------------------------------------------

  defmodule GatingFixtureCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :test_gating_companion

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :test_gating_companion,
        enabled: true,
        dependency_status: :present,
        gate_status: :active,
        kill_switch_status: :unconfigured,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # ---------------------------------------------------------------------------
  # SC#2 fixture companions — distinct gate states for gating_truth/0 assertions
  # ---------------------------------------------------------------------------

  # GatingActiveCompanion: gate_status: :active -> "gated"
  defmodule GatingActiveCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :sc2_gating_active

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :sc2_gating_active,
        enabled: true,
        dependency_status: :present,
        gate_status: :active,
        kill_switch_status: :inactive,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # RollingOutCompanion: gate_status: {:rolling_out, 10} -> "rolling_out (10%)"
  defmodule RollingOutCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :sc2_rolling_out

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :sc2_rolling_out,
        enabled: true,
        dependency_status: :present,
        gate_status: {:rolling_out, 10},
        kill_switch_status: :inactive,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # KillSwitchActiveCompanion: kill_switch_status: :active AND gate_status: :active
  # -> "killed" (kill switch overrides gate_status — precedence proof)
  defmodule KillSwitchActiveCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :sc2_kill_switch_active

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: true

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :sc2_kill_switch_active,
        enabled: true,
        dependency_status: :present,
        # gate_status is non-inactive to prove kill switch overrides gate_status
        gate_status: :active,
        kill_switch_status: :active,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Hermetic routers for building manifests with gated routes
  # ---------------------------------------------------------------------------

  # Router with:
  #   "gated_known" — gated_by :test_gating_companion (resolvable), on_unavailable: nil (fail-closed)
  #     -> :advisory only
  #   "gated_unknown" — gated_by :unregistered_companion (not registered), on_unavailable: nil
  #     -> :advisory + :error
  #   "gated_fallback_missing" — gated_by :test_gating_companion, on_unavailable: {:fallback_phoenix, :missing_route}
  #     -> :advisory (with hint) + :warning (missing_route not in manifest)
  defmodule GatedRoutesRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gated-known", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated_known",
            runtime: :live_view,
            gated_by: :test_gating_companion
          ]

        live "/gated-unknown", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated_unknown",
            runtime: :live_view,
            gated_by: :unregistered_companion
          ]

        live "/gated-fallback-missing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated_fallback_missing",
            runtime: :live_view,
            gated_by: :test_gating_companion,
            on_unavailable: {:fallback_phoenix, :missing_route}
          ]
      end
    end
  end

  # Minimal router for non-gated scenario
  defmodule MinimalRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
        live "/home", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "home", runtime: :live_view]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Shared setup: temp dir with hermetic install manifest for Doctor.run
  # ---------------------------------------------------------------------------

  setup do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase41-proof-#{System.unique_integer([:positive])}"
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

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion (mirrors phase38/phase40 pattern)
  # ---------------------------------------------------------------------------

  test "phase 41 gating doctor proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 41 gating proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 41 gating proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # SC#1: :advisory "gating.route_gated" per gated route
  # ---------------------------------------------------------------------------

  @tag :sc1
  test "SC#1a: doctor emits :advisory gating.route_gated finding for each gated route",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [GatingFixtureCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: GatedRoutesRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    advisory_findings =
      Enum.filter(report.findings, &(&1.code == "gating.route_gated"))

    assert length(advisory_findings) == 3,
           "expected 3 :advisory gating.route_gated findings (one per gated route), got #{length(advisory_findings)}"

    for finding <- advisory_findings do
      assert finding.severity == :advisory,
             "gating.route_gated finding must use :advisory severity; got #{inspect(finding.severity)}"
    end

    route_ids_found = Enum.map(advisory_findings, & &1.details.route_id) |> MapSet.new()
    expected_ids = MapSet.new(["gated_known", "gated_unknown", "gated_fallback_missing"])
    assert route_ids_found == expected_ids,
           "expected advisory findings for #{inspect(MapSet.to_list(expected_ids))}, got #{inspect(MapSet.to_list(route_ids_found))}"
  end

  @tag :sc1
  test "SC#1b: gated route with {:fallback_phoenix, route_id} advisory finding has non-nil hint",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [GatingFixtureCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: GatedRoutesRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    fallback_advisory =
      Enum.find(report.findings, fn f ->
        f.code == "gating.route_gated" && f.details[:route_id] == "gated_fallback_missing"
      end)

    assert fallback_advisory != nil,
           "expected a gating.route_gated advisory for gated_fallback_missing route"

    assert fallback_advisory.hint != nil,
           "expected non-nil hint for {:fallback_phoenix, ...} route; got nil"

    assert String.contains?(fallback_advisory.hint, "redirect") or
             String.contains?(fallback_advisory.hint, "navigates"),
           "hint should mention redirect behavior; got: #{inspect(fallback_advisory.hint)}"
  end

  # ---------------------------------------------------------------------------
  # SC#1c: :error "gating.flag_reference_unknown" for unresolvable gated_by
  # ---------------------------------------------------------------------------

  @tag :sc1
  test "SC#1c: doctor emits :error gating.flag_reference_unknown for route whose gated_by is not a registered companion",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [GatingFixtureCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: GatedRoutesRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    error_finding =
      Enum.find(report.findings, fn f ->
        f.code == "gating.flag_reference_unknown" && f.details[:route_id] == "gated_unknown"
      end)

    assert error_finding != nil,
           "expected gating.flag_reference_unknown :error finding for gated_unknown route; findings: #{inspect(Enum.map(report.findings, & &1.code))}"

    assert error_finding.severity == :error,
           "gating.flag_reference_unknown must be :error severity; got #{inspect(error_finding.severity)}"

    assert error_finding.details.gated_by == :unregistered_companion,
           "details.gated_by must be :unregistered_companion; got #{inspect(error_finding.details.gated_by)}"
  end

  @tag :sc1
  test "SC#1d: doctor emits :error gating.flag_reference_unknown for all gated routes when companions list is empty",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: GatedRoutesRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    error_findings =
      Enum.filter(report.findings, &(&1.code == "gating.flag_reference_unknown"))

    assert length(error_findings) == 3,
           "expected :error for all 3 gated routes when companions list is empty; got #{length(error_findings)}"

    assert Enum.all?(error_findings, &(&1.severity == :error)),
           "all flag_reference_unknown findings must be :error severity"
  end

  # ---------------------------------------------------------------------------
  # SC#1e: :warning "gating.fallback_route_unknown" for missing fallback target
  # ---------------------------------------------------------------------------

  @tag :sc1
  test "SC#1e: doctor emits :warning gating.fallback_route_unknown when fallback route_id absent from manifest",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [GatingFixtureCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: GatedRoutesRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    warning_finding =
      Enum.find(report.findings, fn f ->
        f.code == "gating.fallback_route_unknown" && f.details[:route_id] == "gated_fallback_missing"
      end)

    assert warning_finding != nil,
           "expected gating.fallback_route_unknown :warning finding for gated_fallback_missing route; findings: #{inspect(Enum.map(report.findings, & &1.code))}"

    assert warning_finding.severity == :warning,
           "gating.fallback_route_unknown must be :warning severity; got #{inspect(warning_finding.severity)}"

    assert warning_finding.details.fallback_route_id == :missing_route,
           "details.fallback_route_id must be :missing_route; got #{inspect(warning_finding.details[:fallback_route_id])}"
  end

  @tag :sc1
  test "SC#1f: no gating findings emitted for routes without gated_by",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [GatingFixtureCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    report =
      Doctor.run(
        route_source: MinimalRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.manifest != nil,
           "MinimalRouter must compile to a non-nil manifest for SC#1f to be meaningful; got manifest=nil in report"

    gating_findings = Enum.filter(report.findings, &String.starts_with?(&1.code, "gating."))

    assert gating_findings == [],
           "expected no gating findings for non-gated routes; got: #{inspect(gating_findings)}"
  end

  # ---------------------------------------------------------------------------
  # SC#2: SupportMatrix.gating_truth/0 gate-state display assertions
  # ---------------------------------------------------------------------------

  @tag :sc2
  test "SC#2a: gating_truth/0 returns gate_state 'gated' for a gate_status: :active companion" do
    Application.put_env(:crosswake, :companions, [GatingActiveCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    truth = SupportMatrix.gating_truth()

    entry = Enum.find(truth, &(&1.companion_id == :sc2_gating_active))

    assert entry != nil,
           "expected a gating_truth entry for :sc2_gating_active; got: #{inspect(truth)}"

    assert entry.gate_state == "gated",
           "expected gate_state 'gated' for gate_status: :active companion; got #{inspect(entry.gate_state)}"
  end

  @tag :sc2
  test "SC#2b: gating_truth/0 returns gate_state 'rolling_out (10%)' for gate_status: {:rolling_out, 10}" do
    Application.put_env(:crosswake, :companions, [RollingOutCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    truth = SupportMatrix.gating_truth()

    entry = Enum.find(truth, &(&1.companion_id == :sc2_rolling_out))

    assert entry != nil,
           "expected a gating_truth entry for :sc2_rolling_out; got: #{inspect(truth)}"

    assert entry.gate_state == "rolling_out (10%)",
           "expected gate_state 'rolling_out (10%)' for {:rolling_out, 10} companion; got #{inspect(entry.gate_state)}"
  end

  @tag :sc2
  test "SC#2c: gating_truth/0 returns gate_state 'killed' for kill_switch_status: :active even when gate_status: :active" do
    Application.put_env(:crosswake, :companions, [KillSwitchActiveCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    truth = SupportMatrix.gating_truth()

    entry = Enum.find(truth, &(&1.companion_id == :sc2_kill_switch_active))

    assert entry != nil,
           "expected a gating_truth entry for :sc2_kill_switch_active; got: #{inspect(truth)}"

    assert entry.gate_state == "killed",
           "expected gate_state 'killed' for kill_switch_status: :active companion (regardless of gate_status); got #{inspect(entry.gate_state)}"
  end

  @tag :sc2
  test "SC#2d: gating_truth_label/0 returns text containing 'runtime' and 'not build-proof'" do
    label = SupportMatrix.gating_truth_label()

    assert is_binary(label),
           "gating_truth_label/0 must return a string; got #{inspect(label)}"

    assert String.contains?(String.downcase(label), "runtime"),
           "gating_truth_label/0 must contain 'runtime' (case-insensitive) to be runtime-distinct from build-proof posture; got: #{inspect(label)}"

    assert String.contains?(label, "not build-proof"),
           "gating_truth_label/0 must contain 'not build-proof' to distinguish from build-proof state; got: #{inspect(label)}"
  end

  @tag :sc2
  test "SC#2e: gating_truth/0 returns all three display strings when all three companion types are registered" do
    Application.put_env(:crosswake, :companions, [
      GatingActiveCompanion,
      RollingOutCompanion,
      KillSwitchActiveCompanion
    ])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    truth = SupportMatrix.gating_truth()

    gate_states = MapSet.new(truth, & &1.gate_state)

    assert MapSet.member?(gate_states, "gated"),
           "expected 'gated' in gate_states; got: #{inspect(MapSet.to_list(gate_states))}"

    assert MapSet.member?(gate_states, "rolling_out (10%)"),
           "expected 'rolling_out (10%)' in gate_states; got: #{inspect(MapSet.to_list(gate_states))}"

    assert MapSet.member?(gate_states, "killed"),
           "expected 'killed' in gate_states; got: #{inspect(MapSet.to_list(gate_states))}"
  end
end
