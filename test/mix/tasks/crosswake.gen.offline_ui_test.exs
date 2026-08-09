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

  test "does NOT copy tokens.css into the host — it is served by Crosswake, not generated" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    tokens_css_path = Path.join([@tmp_dir, "priv", "static", "assets", "tokens.css"])
    refute File.exists?(tokens_css_path),
      "tokens.css must NOT be copied into the host — it is served at /crosswake/tokens.css, " <>
        "not host-owned (D-26); a copy here would silently drift from every future token addition"
  end

  test "generated offline_root.html.heex links tokens.css before app.css" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    root_layout_path = Path.join([@tmp_dir, "lib", "test_app_web", "components", "layouts", "offline_root.html.heex"])
    root_layout_content = File.read!(root_layout_path)

    # tokens.css is now a plain href served by Crosswake's own Plug.Static, not a
    # verified-router-path helper — the URL is not a route in the host's router.
    assert root_layout_content =~ ~s(href="/crosswake/tokens.css"),
      "Expected offline_root.html.heex to link the library-served /crosswake/tokens.css"

    tokens_index = :binary.match(root_layout_content, "tokens.css")
    app_index = :binary.match(root_layout_content, "app.css")

    assert tokens_index != :nomatch,
      "Expected offline_root.html.heex to contain a tokens.css link"
    assert app_index != :nomatch,
      "Expected offline_root.html.heex to contain an app.css link"

    {tokens_pos, _} = tokens_index
    {app_pos, _} = app_index

    assert tokens_pos < app_pos,
      "Expected tokens.css link to appear before app.css link in offline_root.html.heex"
  end

  test "outputs standard instructions to Mix.shell().info" do
    output = capture_io(fn ->
      run(["--dir", @tmp_dir, "--app", "TestApp"])
    end)

    assert output =~ "Offline UI components generated successfully!"
    assert output =~ "get \"/offline\""
    assert output =~ "TestAppWeb.OfflineController"
    assert output =~ "/crosswake/tokens.css",
      "Next steps must tell the adopter tokens.css is served by Crosswake, not copied"
    refute output =~ "copied tokens.css",
      "Must not claim the generator copies tokens.css — it no longer does (D-26)"
  end

  test "generated output contains semantic token references, not Tailwind classes" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    page_path = Path.join([@tmp_dir, "lib", "test_app_web", "controllers", "offline_html", "offline_page.html.heex"])
    root_path = Path.join([@tmp_dir, "lib", "test_app_web", "components", "layouts", "offline_root.html.heex"])

    page_content = File.read!(page_path)
    root_content = File.read!(root_path)
    combined = page_content <> root_content

    # Contains semantic token class references
    assert combined =~ "cw-offline-"

    # Contains no Tailwind layout/color classes
    refute combined =~ "flex", "Should not contain 'flex' Tailwind class"
    refute combined =~ "bg-white", "Should not contain 'bg-white' Tailwind class"
    refute combined =~ "bg-cw-foam-50", "Should not contain primitive Tailwind color"
    refute combined =~ "text-cw-current-950", "Should not contain primitive Tailwind color"
    refute combined =~ "min-h-screen", "Should not contain Tailwind layout class"
    refute combined =~ ~r/border-cw-/, "Should not contain Tailwind border-cw- classes"
    refute combined =~ "border-gray-", "Should not contain Tailwind system gray borders"
    refute combined =~ "--cw-primitive-", "Should not reference primitive tier tokens"
  end

  test "generated offline.css contains semantic token references and no primitives" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    offline_css_path = Path.join([@tmp_dir, "priv", "static", "assets", "offline.css"])
    assert File.exists?(offline_css_path)

    css_content = File.read!(offline_css_path)
    assert css_content =~ "var(--cw-surface-default)", "offline.css must reference semantic tokens"
    assert css_content =~ "var(--cw-text-default)"
    assert css_content =~ "--cw-action-focus-ring"
    refute css_content =~ "--cw-primitive-", "offline.css must not reference primitive tier"
  end

  test "offline.css copy uses no-clobber semantics — does not overwrite existing file" do
    # First run — creates the file
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    offline_css_path = Path.join([@tmp_dir, "priv", "static", "assets", "offline.css"])
    assert File.exists?(offline_css_path)

    # Overwrite with custom content to simulate host customization
    custom_content = "/* custom offline styles */"
    File.write!(offline_css_path, custom_content)

    # Second run — must NOT overwrite
    output = capture_io(fn ->
      run(["--dir", @tmp_dir, "--app", "TestApp"])
    end)

    assert File.read!(offline_css_path) == custom_content,
      "Expected ensure_file to preserve existing offline.css (no-clobber), but it was overwritten"
    assert output =~ "reused",
      "Expected 'reused' in output when offline.css already exists"
  end

  test "offline_root links offline.css after tokens.css and app.css" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    root_path = Path.join([@tmp_dir, "lib", "test_app_web", "components", "layouts", "offline_root.html.heex"])
    content = File.read!(root_path)

    # Guard against :nomatch so a missing link fails with a clear assertion, not a MatchError
    assert content =~ "tokens.css", "offline_root must link tokens.css"
    assert content =~ "app.css", "offline_root must link app.css"
    assert content =~ "offline.css", "offline_root must link offline.css"

    {tokens_pos, _} = :binary.match(content, "tokens.css")
    {app_pos, _}    = :binary.match(content, "app.css")
    {offline_pos, _} = :binary.match(content, "offline.css")

    assert tokens_pos < app_pos,    "tokens.css must precede app.css"
    assert app_pos < offline_pos,   "app.css must precede offline.css"
  end
end
