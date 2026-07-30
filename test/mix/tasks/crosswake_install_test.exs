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

    endpoint_path = Path.join(target, "lib/demo_web/endpoint.ex")

    File.write!(
      endpoint_path,
      """
      defmodule DemoWeb.Endpoint do
        use Phoenix.Endpoint, otp_app: :demo

        plug(Plug.Static, at: "/", from: :demo, gzip: false)
      end
      """
    )

    %{target: target, router_path: router_path, endpoint_path: endpoint_path}
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
    assert router_contents =~ "import Phoenix.Router, except: [get: 3, get: 4"
    assert router_contents =~ "import Crosswake.Router"
    refute router_contents =~ "import Phoenix.LiveView.Router"
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

  # D-41: patch what is canonical, print what is not.
  test "patches the endpoint's static plug block, prints the layout wiring, and stays idempotent",
       %{target: target, endpoint_path: endpoint_path} do
    first =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--target", target])
      end)

    endpoint_contents = File.read!(endpoint_path)

    # PATCHED: the static plug block is mechanical and identical across hosts.
    assert endpoint_contents =~ "# crosswake:install:start"
    assert endpoint_contents =~ "plug(Plug.Static,"
    assert endpoint_contents =~ "at: \"/crosswake\""
    assert endpoint_contents =~ "from: :crosswake"
    assert endpoint_contents =~ "only: ~w(crosswake.esm.js)"
    assert endpoint_contents =~ "# crosswake:install:end"

    # The host's own existing static plug is untouched — this is additive.
    assert endpoint_contents =~ "from: :demo"

    # PRINTED, never patched: the layout import, the hooks map, and the element.
    assert first =~ "import {CrosswakeBridge} from \"/crosswake/crosswake.esm.js\";"
    assert first =~ "hooks: {CrosswakeBridge}"
    assert first =~ "phx-hook=\"CrosswakeBridge\""

    # The brand-new install-time failure surface every adopter hits exactly once.
    assert first =~ "NotMountedError"
    assert first =~ "Crosswake.Bridge.attach/1"

    second =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--target", target])
      end)

    assert File.read!(endpoint_path) == endpoint_contents
    assert second =~ "marker_reused"

    # The printed half is not patchable, so the installer says it every time.
    assert second =~ "import {CrosswakeBridge} from \"/crosswake/crosswake.esm.js\";"
  end

  test "a host with no resolvable endpoint is guidance, not an install failure", %{
    target: target,
    endpoint_path: endpoint_path
  } do
    File.rm!(endpoint_path)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--target", target])
      end)

    assert output =~ "endpoint: not found"
    assert output =~ "mix crosswake.gen.bridge_hook"
    assert output =~ "Crosswake install complete"
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
