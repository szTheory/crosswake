defmodule Mix.Tasks.Crosswake.Gen.BridgeHookTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Crosswake.Bridge.Contract
  alias Mix.Tasks.Crosswake.Gen.BridgeHook

  @task "crosswake.gen.bridge_hook"

  setup do
    target = tmp_dir!("crosswake-gen-bridge-hook")
    %{target: target}
  end

  describe "the refusal (D-33)" do
    test "with no flag it writes nothing and prints all three wiring fragments", %{target: target} do
      output = run_task(["--dir", target])

      # It REFUSES: nothing at all is written into the host.
      assert Path.wildcard(Path.join(target, "**/*")) == []

      # The refusal IS the teaching surface, so it must carry the whole wiring.
      assert output =~ "did not generate anything, on purpose"

      # 1. the endpoint static plug block
      assert output =~ "plug(Plug.Static,"
      assert output =~ "at: \"/crosswake\""
      assert output =~ "from: :crosswake"
      assert output =~ "only: ~w(crosswake.esm.js tokens.css)"

      # 2. the layout import line and the hooks-map entry
      assert output =~ "import {CrosswakeBridge} from \"/crosswake/crosswake.esm.js\";"
      assert output =~ "hooks: {CrosswakeBridge}"

      # 3. the single hook element
      assert output =~ "phx-hook=\"CrosswakeBridge\""
    end

    test "the refusal explains why the hook is library-owned and names the escape valve", %{
      target: target
    } do
      output = run_task(["--dir", target])

      assert output =~ "library-owned"
      assert output =~ "second package registry"
      assert output =~ "mix crosswake.gen.bridge_hook --eject"
      assert output =~ "mix crosswake.doctor"
    end
  end

  describe "the eject" do
    test "--eject writes a copy carrying a protocol-version stamp", %{target: target} do
      output = run_task(["--dir", target, "--eject"])

      path = Path.join(target, "priv/static/crosswake.esm.js")
      assert File.exists?(path)
      assert output =~ "created priv/static/crosswake.esm.js"

      contents = File.read!(path)
      assert contents =~ "crosswake:bridge-hook:ejected protocol=#{Contract.version()}"

      # It is the real hook, not a placeholder.
      assert contents =~ "messageHandlers"
      assert contents =~ "__reply"
      assert contents =~ "export const CrosswakeBridge"
    end

    test "running the eject twice is idempotent and does not duplicate the stamp", %{
      target: target
    } do
      run_task(["--dir", target, "--eject"])

      path = Path.join(target, "priv/static/crosswake.esm.js")
      first = File.read!(path)

      output = run_task(["--dir", target, "--eject"])

      assert output =~ "reused priv/static/crosswake.esm.js"
      assert File.read!(path) == first

      stamps =
        first
        |> String.split(BridgeHook.stamp_prefix())
        |> length()
        |> Kernel.-(1)

      assert stamps == 1
    end

    test "--path redirects the eject destination", %{target: target} do
      run_task(["--dir", target, "--eject", "--path", "priv/static/vendor/crosswake.esm.js"])

      assert File.exists?(Path.join(target, "priv/static/vendor/crosswake.esm.js"))
      refute File.exists?(Path.join(target, "priv/static/crosswake.esm.js"))
    end
  end

  test "rejects unknown switches", %{target: target} do
    assert_raise Mix.Error, fn ->
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--dir", target, "--nope"])
      end)
    end
  end

  defp run_task(args) do
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, args)
    end)
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
