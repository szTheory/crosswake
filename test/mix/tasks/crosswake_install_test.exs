defmodule Mix.Tasks.Crosswake.InstallTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @task "crosswake.install"

  setup do
    target = tmp_dir!("crosswake-install")

    router_path = Path.join(target, "lib/demo_web/router.ex")
    File.mkdir_p!(Path.dirname(router_path))

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        use DemoWeb, :router
        import Phoenix.LiveView.Router

        scope \"/\", DemoWeb do
          get \"/\", PageController, :home
          live \"/library\", LibraryLive
        end
      end
      """
    )

    %{target: target, router_path: router_path}
  end

  test "creates policy scaffolding, patches the router with explicit markers, and stays idempotent",
       %{target: target, router_path: router_path} do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--target", target])
      end)

    assert output =~ "idempotent"
    assert output =~ "marker"
    assert output =~ "install manifest"

    router_contents = File.read!(router_path)
    assert router_contents =~ "# crosswake:install:start"
    assert router_contents =~ "import Crosswake.Router"
    assert router_contents =~ "except: [live: 2, live: 3, live: 4]"
    assert router_contents =~ "@crosswake_policy_module DemoWeb.Crosswake.Policy"

    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    assert File.exists?(policy_path)
    assert File.read!(policy_path) =~ "Host-owned Crosswake policy entrypoint"
    assert File.read!(policy_path) =~ "DemoWeb.Router"

    manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")
    manifest_contents = File.read!(manifest_path)
    assert manifest_contents =~ "\"policy_module\": \"DemoWeb.Crosswake.Policy\""

    assert manifest_contents =~
             "\"markers\": [\"# crosswake:install:start\", \"# crosswake:install:end\"]"

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--target", target])
      end)

    assert output =~ "marker_reused"
    assert output =~ "policy module: lib/demo_web/crosswake/policy.ex (reused)"

    assert File.read!(router_path) == router_contents
    assert File.read!(manifest_path) == manifest_contents
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
