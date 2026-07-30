defmodule Mix.Tasks.Crosswake.Gen.NativeControlsUiTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Crosswake.Gen.NativeControlsUi, only: [run: 1]

  @tmp_dir Path.join(System.tmp_dir!(), "crosswake-gen-native-controls-ui-test")

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

    :ok
  end

  defp component_path(dir), do: Path.join([dir, "lib", "demo_web", "components", "crosswake_fallbacks.ex"])
  defp stylesheet_path(dir), do: Path.join([dir, "priv", "static", "assets", "crosswake_fallback.css"])

  defp drain_shell_messages do
    Stream.repeatedly(fn ->
      receive do
        {:mix_shell, :info, [msg]} -> {:ok, msg}
      after
        0 -> :halt
      end
    end)
    |> Enum.take_while(&(&1 != :halt))
    |> Enum.map(fn {:ok, msg} -> msg end)
  end

  test "first run in an empty tmp dir creates exactly two files and prints a created line for each" do
    run(["--dir", @tmp_dir, "--app", "Demo"])

    component = component_path(@tmp_dir)
    stylesheet = stylesheet_path(@tmp_dir)

    assert File.exists?(component)
    assert File.exists?(stylesheet)

    # Exactly two files — the artifact count is a constant, not data-driven (E5/zero-one-many).
    all_files = Path.wildcard(Path.join(@tmp_dir, "**/*")) |> Enum.filter(&File.regular?/1)
    assert length(all_files) == 2

    messages = Enum.join(drain_shell_messages(), "\n")
    assert messages =~ "created"
    assert messages =~ "crosswake_fallbacks.ex"
    assert messages =~ "crosswake_fallback.css"
  end

  test "second run in the same dir writes nothing: byte-identical, and a skip line names each existing file" do
    run(["--dir", @tmp_dir, "--app", "Demo"])
    drain_shell_messages()

    component = component_path(@tmp_dir)
    stylesheet = stylesheet_path(@tmp_dir)

    component_hash_before = :crypto.hash(:sha256, File.read!(component))
    stylesheet_hash_before = :crypto.hash(:sha256, File.read!(stylesheet))

    run(["--dir", @tmp_dir, "--app", "Demo"])
    messages = Enum.join(drain_shell_messages(), "\n")

    component_hash_after = :crypto.hash(:sha256, File.read!(component))
    stylesheet_hash_after = :crypto.hash(:sha256, File.read!(stylesheet))

    assert component_hash_before == component_hash_after
    assert stylesheet_hash_before == stylesheet_hash_after

    assert messages =~ "reused"
    assert messages =~ "crosswake_fallbacks.ex"
    assert messages =~ "crosswake_fallback.css"
  end

  test "partial tree: deleting only the CSS file and re-running recreates it and reports the component skipped" do
    run(["--dir", @tmp_dir, "--app", "Demo"])
    drain_shell_messages()

    stylesheet = stylesheet_path(@tmp_dir)
    File.rm!(stylesheet)
    refute File.exists?(stylesheet)

    run(["--dir", @tmp_dir, "--app", "Demo"])
    messages = Enum.join(drain_shell_messages(), "\n")

    assert File.exists?(stylesheet)
    assert messages =~ "created"
    assert messages =~ "crosswake_fallback.css"
    assert messages =~ "reused"
    assert messages =~ "crosswake_fallbacks.ex"
  end

  test "both written files begin with the stamp and carry the current template_version" do
    run(["--dir", @tmp_dir, "--app", "Demo"])

    component_content = File.read!(component_path(@tmp_dir))
    stylesheet_content = File.read!(stylesheet_path(@tmp_dir))

    stamp = Mix.Tasks.Crosswake.Gen.NativeControlsUi.stamp_prefix()
    version = Mix.Tasks.Crosswake.Gen.NativeControlsUi.template_version()

    assert String.starts_with?(component_content, "# #{stamp}")
    assert component_content =~ "template_version=#{version}"

    assert String.starts_with?(stylesheet_content, "/* #{stamp}")
    assert stylesheet_content =~ "template_version=#{version}"
  end

  test "the printed next-steps output contains all three handle_event clause names, the stylesheet link, and the offer-undo guidance" do
    run(["--dir", @tmp_dir, "--app", "Demo"])
    messages = Enum.join(drain_shell_messages(), "\n")

    assert messages =~ ~s|handle_event("crosswake_fallback_answer", %{"answer" => "confirm"}, socket)|
    assert messages =~ ~s|handle_event("crosswake_fallback_dismiss", _params, socket)|
    assert messages =~ ~s|handle_event("crosswake_fallback_answer", _params, socket)|

    assert messages =~ ~s|<link rel="stylesheet" href="/assets/crosswake_fallback.css" />|

    assert messages =~
             "If you can offer undo instead of asking \"are you sure?\", offer undo instead of this modal."
  end

  test "a destination directory that cannot be written raises via Mix.raise carrying a formatted reason, not a bare File.Error" do
    blocked_dir = Path.join(@tmp_dir, "blocked")
    File.mkdir_p!(blocked_dir)
    # Make the parent a regular file, so mkdir_p underneath it fails deterministically
    # regardless of the running user's filesystem permissions (Rule 1 — a chmod-based
    # test is flaky when run as root/CI).
    blocked_path = Path.join(blocked_dir, "not_a_directory")
    File.write!(blocked_path, "occupied")

    assert_raise Mix.Error, ~r/could not (create directory|write|read)/, fn ->
      run(["--dir", blocked_path, "--app", "Demo"])
    end
  end

  test "drift guard: the sorted SHA-256 of the two templates is non-vacuous (glob resolves to >= 2 files)" do
    templates =
      Path.wildcard(
        Path.join([File.cwd!(), "priv", "templates", "crosswake", "native_controls_ui", "*.eex"])
      )

    assert length(templates) >= 2
  end
end
