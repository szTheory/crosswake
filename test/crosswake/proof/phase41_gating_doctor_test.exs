defmodule Crosswake.Proof.Phase41GatingDoctorTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 41 gating doctor category.

  Proves SC#1 (GATE-05 diagnostics half): Doctor.run/1 emits the dedicated
  "Gating" category findings:
    - :advisory "gating.route_gated" for each gated route (one per route)
    - :error "gating.flag_reference_unknown" when gated_by atom resolves to no registered companion
    - :warning "gating.fallback_route_unknown" when {:fallback_phoenix, route_id} target is absent

  SC#2 (support-matrix gate-state column) is added by plan 02.

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs with @tag :sc1 so the SC#1 tests can
  be run via `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1`.

  async: false — :companions is a shared global Application key; concurrent tests
  would observe each other's companion registrations.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Doctor

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

    gating_findings = Enum.filter(report.findings, &String.starts_with?(&1.code, "gating."))

    assert gating_findings == [],
           "expected no gating findings for non-gated routes; got: #{inspect(gating_findings)}"
  end
end
