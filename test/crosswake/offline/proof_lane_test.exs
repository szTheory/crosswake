Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.Offline.ProofLaneTest do
  use ExUnit.Case, async: true

  alias Crosswake.Doctor
  alias Crosswake.Manifest

  test "repo-local proof lane asserts the narrow cached and study-session offline posture" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(Crosswake.TestSupport.RouterFixtures.ManagedRouter)

    assert manifest.routes["library"].cache_contract.hydration == :sqlite_snapshot
    assert manifest.routes["study-session"].island_contract.sync_seam == "study_reviews"
    assert manifest.routes["study-session"].island_contract.authoritative_source == :phoenix
  end

  test "doctor keeps offline support while generated shell runtime remains verification required" do
    target =
      Path.join(System.tmp_dir!(), "crosswake-offline-proof-#{System.unique_integer([:positive])}")

    install_manifest_path = write_install_fixture!(target)

    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.offline.status == :supported
    assert report.support.status == :verification_required
    assert report.offline.routes["study-session"]["sync_seam"] == "study_reviews"
  end

  test "docs keep the narrow offline claim and shell verification required posture" do
    offline = File.read!("guides/offline.md")
    compatibility = File.read!("guides/compatibility.md")
    support = File.read!("guides/support_matrix.md")

    assert offline =~ "cached read-only"
    assert offline =~ "study-session offline island"
    assert offline =~ "queued for replay"
    assert offline =~ "conflict requires attention"
    assert offline =~ "verification required"

    assert compatibility =~ "script/verify_offline_contract.sh"
  end

  defp write_install_fixture!(target) do
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

    install_manifest_path
  end
end
