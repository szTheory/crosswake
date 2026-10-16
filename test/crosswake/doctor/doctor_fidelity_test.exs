defmodule Crosswake.Doctor.FidelityTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter

  setup do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-doctor-fidelity-#{System.unique_integer([:positive])}"
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

    File.write!(
      install_manifest_path,
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })
    )

    on_exit(fn -> File.rm_rf!(target) end)

    %{target: target, install_manifest_path: install_manifest_path}
  end

  defp run_doctor(route_source, ctx) do
    Doctor.run(
      route_source: route_source,
      install_manifest_path: ctx.install_manifest_path,
      cwd: ctx.target
    )
  end

  defp findings_with_code(report, code), do: Enum.filter(report.findings, &(&1.code == code))

  defp json_findings_with_code(report, code) do
    decoded = report |> JSONFormatter.render() |> Jason.decode!()
    Enum.filter(decoded["findings"], &(&1["code"] == code))
  end

  defp managed(id, path, opts) do
    %{
      path: path,
      metadata: %{
        crosswake:
          [id: id, security: :standard]
          |> Keyword.merge(opts)
      }
    }
  end

  test "unmanaged_routes details carry the sorted paths and the router name", ctx do
    report = run_doctor(Crosswake.TestSupport.RouterFixtures.DefaultsRouter, ctx)

    assert [finding] = findings_with_code(report, "unmanaged_routes")
    assert finding.severity == :warning

    assert finding.details == %{
             unmanaged_paths: ["/public"],
             router: "Crosswake.TestSupport.RouterFixtures.DefaultsRouter"
           }

    assert [json_finding] = json_findings_with_code(report, "unmanaged_routes")

    assert json_finding["details"] == %{
             "unmanaged_paths" => ["/public"],
             "router" => "Crosswake.TestSupport.RouterFixtures.DefaultsRouter"
           }
  end

  test "unmanaged_routes details from a route list carry a nil router and each path once", ctx do
    routes = [
      managed("a", "/a", runtime: :live_view, offline: :unavailable),
      %{path: "/b", metadata: %{}},
      %{path: "/c", metadata: %{}},
      %{path: "/b", metadata: %{}}
    ]

    report = run_doctor(routes, ctx)

    assert [finding] = findings_with_code(report, "unmanaged_routes")
    assert finding.details == %{unmanaged_paths: ["/b", "/c"], router: nil}

    assert [json_finding] = json_findings_with_code(report, "unmanaged_routes")
    assert json_finding["details"]["router"] == nil
    assert json_finding["details"]["unmanaged_paths"] == ["/b", "/c"]
  end

  test "an offline_island local_first route without island_contract is one offline_posture_incomplete error",
       ctx do
    routes = [
      managed("hole-a", "/hole-a",
        runtime: :offline_island,
        offline: :local_first
      )
    ]

    report = run_doctor(routes, ctx)

    assert [finding] = findings_with_code(report, "offline_posture_incomplete")
    assert finding.check == "offline_posture"
    assert finding.severity == :error
    assert finding.details.incoherent_routes == ["hole-a"]
    assert report.offline.status == :incomplete
    assert report.status == :error
    assert findings_with_code(report, "offline_posture_ready") == []
  end

  test "several unbacked offline_island routes are listed once each in sorted order", ctx do
    routes = [
      managed("hole-b", "/hole-b", runtime: :offline_island, offline: :local_first),
      managed("hole-a", "/hole-a", runtime: :offline_island, offline: :local_first),
      managed("backed", "/a",
        runtime: :offline_island,
        offline: :local_first,
        island_contract: :study_session_v1
      )
    ]

    report = run_doctor(routes, ctx)

    assert [finding] = Enum.filter(report.findings, &(&1.check == "offline_posture"))
    assert finding.code == "offline_posture_incomplete"
    assert finding.details.incoherent_routes == ["hole-a", "hole-b"]
    assert report.offline.status == :incomplete
  end

  test "coherent offline island and cached routes stay supported", ctx do
    report = run_doctor(Crosswake.TestSupport.RouterFixtures.ManagedRouter, ctx)

    assert report.offline.status == :supported
    assert [finding] = findings_with_code(report, "offline_posture_ready")
    assert finding.severity == :advisory
    assert findings_with_code(report, "offline_posture_incomplete") == []
  end

  test "a native_screen local_first route and a cached_read_only route without contracts are not flagged",
       ctx do
    routes = [
      managed("a", "/a", runtime: :native_screen, offline: :local_first),
      managed("b", "/b", runtime: :live_view, offline: :cached_read_only)
    ]

    report = run_doctor(routes, ctx)

    assert report.offline.status == :supported
    assert report.offline.routes == %{}
    assert findings_with_code(report, "offline_posture_incomplete") == []
    assert [finding] = findings_with_code(report, "offline_posture_ready")
    assert finding.severity == :advisory
  end

  test "a manifest with no offline claim reports not_claimed with one advisory finding", ctx do
    routes = [managed("a", "/a", runtime: :live_view, offline: :unavailable)]

    report = run_doctor(routes, ctx)

    assert report.offline.status == :not_claimed
    assert report.offline.routes == %{}
    assert is_list(report.offline.states)
    assert Map.has_key?(report.offline, :telemetry)

    assert [finding] = Enum.filter(report.findings, &(&1.check == "offline_posture"))
    assert finding.code == "offline_posture_not_claimed"
    assert finding.severity == :advisory
    assert finding.message =~ "no routes declare offline behavior"
    assert finding.hint =~ "cached read-only route is not local mutation"
    refute Map.has_key?(finding.details, :incoherent_routes)
    assert findings_with_code(report, "offline_posture_ready") == []
    assert Formatter.render(report) =~ "offline posture: not_claimed"
  end

  test "not_claimed keeps the states, telemetry and routes keys with empty routes in JSON",
       ctx do
    routes = [managed("a", "/a", runtime: :live_view, offline: :unavailable)]

    decoded = routes |> run_doctor(ctx) |> JSONFormatter.render() |> Jason.decode!()

    assert decoded["offline"]["status"] == "not_claimed"
    assert Map.has_key?(decoded["offline"], "states")
    assert Map.has_key?(decoded["offline"], "telemetry")
    assert decoded["offline"]["routes"] == %{}
  end
end
