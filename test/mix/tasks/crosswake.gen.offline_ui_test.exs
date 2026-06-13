defmodule Mix.Tasks.Crosswake.Gen.OfflineUiTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Crosswake.Gen.OfflineUi, only: [run: 1]
  import ExUnit.CaptureIO

  @tmp_dir "tmp_offline_ui_test"

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  test "generates offline UI templates in target Phoenix application directories" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    controller_path = Path.join([@tmp_dir, "lib", "test_app_web", "controllers", "offline_controller.ex"])
    root_layout_path = Path.join([@tmp_dir, "lib", "test_app_web", "components", "layouts", "offline_root.html.heex"])
    page_path = Path.join([@tmp_dir, "lib", "test_app_web", "controllers", "offline_html", "offline_page.html.heex"])
    js_path = Path.join([@tmp_dir, "assets", "js", "offline.js"])

    assert File.exists?(controller_path)
    assert File.exists?(root_layout_path)
    assert File.exists?(page_path)
    assert File.exists?(js_path)

    controller_content = File.read!(controller_path)
    assert controller_content =~ "defmodule TestAppWeb.OfflineController do"

    # also let's verify page content
    page_content = File.read!(page_path)
    assert page_content =~ "Offline Workspace"

    # js content
    js_content = File.read!(js_path)
    assert js_content =~ "checkStorageBudget"
  end

  test "outputs standard instructions to Mix.shell().info" do
    output = capture_io(fn ->
      run(["--dir", @tmp_dir, "--app", "TestApp"])
    end)

    assert output =~ "Offline UI components generated successfully!"
    assert output =~ "get \"/offline\""
    assert output =~ "TestAppWeb.OfflineController"
    assert output =~ "cw-wake-700"
    assert output =~ "cw-brass-500"
    assert output =~ "tailwind.config.js"
    assert output =~ "Configure esbuild to bundle offline.js"
  end
end
