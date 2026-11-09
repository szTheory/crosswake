defmodule Mix.Tasks.Crosswake.Gen.ShellDefaultReferencesTest do
  # Mix task state, the app env and Application.app_dir/1 are process-wide test resources.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.Shell.PBXProject

  @task "crosswake.gen.shell"
  @settings "CrosswakeHostSettings.xcconfig"

  # The default path (no `:crosswake, :ios_host` declaration) must write a project whose
  # every referenced file exists. 0.2.12 wrote six mentions of the settings file in the
  # project and never wrote the file, so xcodebuild stopped with exit 65.
  setup do
    previous = Application.fetch_env(:crosswake, :ios_host)
    Application.delete_env(:crosswake, :ios_host)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:crosswake, :ios_host, value)
        :error -> Application.delete_env(:crosswake, :ios_host)
      end
    end)

    :ok
  end

  for {form, args} <- [{"no-flag remote form", []}, {"--local form", ["--local"]}] do
    test "default iOS generation (#{form}) writes every file its project references" do
      target = tmp_dir!("crosswake-default-refs")
      args = unquote(args)
      root = generate_default!(target, args)

      project = parse_project!(root)
      references = referenced_files(project)

      # Non-empty floor: the template has ten `<group>` file references.
      assert map_size(references) >= 10,
             "expected at least 10 group file references, found #{map_size(references)}"

      assert missing_files(root, references) == []

      # The four build configurations (two targets, Debug and Release) each resolve their
      # base configuration to a file that exists.
      base_configurations = base_configuration_ids(project)
      assert length(base_configurations) == 4

      for id <- base_configurations do
        relative = Map.fetch!(references, id)
        assert relative == @settings
        assert File.regular?(Path.join(root, relative))
      end

      isas = project |> objects() |> Map.values() |> Enum.map(& &1["isa"])

      if args == ["--local"] do
        assert "XCLocalSwiftPackageReference" in isas
        refute "XCRemoteSwiftPackageReference" in isas
      else
        assert "XCRemoteSwiftPackageReference" in isas
        refute "XCLocalSwiftPackageReference" in isas
      end
    end
  end

  test "negative control: a tree without the settings file is reported missing by the same helper" do
    target = tmp_dir!("crosswake-default-refs-negative")
    root = generate_default!(target, [])

    assert missing_files(root, root |> parse_project!() |> referenced_files()) == []

    File.rm!(Path.join(root, @settings))

    assert missing_files(root, root |> parse_project!() |> referenced_files()) == [@settings]
  end

  test "default settings carry the placeholder identity, unsigned simulator builds, and no managed metadata" do
    target = tmp_dir!("crosswake-default-settings")
    root = generate_default!(target, [])
    settings = File.read!(Path.join(root, @settings))

    assert settings =~ "CROSSWAKE_APP_BUNDLE_ID = dev.crosswake.shell"
    assert settings =~ "CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO"
    refute File.exists?(Path.join(root, ".crosswake/ios_host_generation.json"))
  end

  test "a host edit to the default settings file survives a second default generation" do
    target = tmp_dir!("crosswake-default-scaffold-once")
    root = generate_default!(target, [])
    settings_path = Path.join(root, @settings)
    edited = File.read!(settings_path) <> "// host edit\n"
    File.write!(settings_path, edited)

    generate_default!(target, [])

    assert File.read!(settings_path) == edited
  end

  defp generate_default!(target, args) do
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["ios", "--target", target] ++ args)
    end)

    Path.join(target, "native/ios/crosswake_shell")
  end

  defp parse_project!(root) do
    path = Path.join(root, "CrosswakeShell.xcodeproj/project.pbxproj")
    assert {:ok, project} = PBXProject.parse(File.read!(path))
    project
  end

  defp objects(project), do: Map.fetch!(project, "objects")

  # Maps each `<group>` file reference id to its path relative to the project root, resolved
  # through the PBXGroup `path` chain from the main group.
  defp referenced_files(project) do
    objects = objects(project)

    main_group =
      objects |> Map.fetch!(Map.fetch!(project, "rootObject")) |> Map.fetch!("mainGroup")

    walk_group(objects, main_group, "", %{})
  end

  defp walk_group(objects, group_id, prefix, acc) do
    group = Map.fetch!(objects, group_id)
    here = if group["path"], do: Path.join(prefix, group["path"]), else: prefix

    Enum.reduce(Map.get(group, "children", []), acc, fn child_id, acc ->
      child = Map.fetch!(objects, child_id)

      case child do
        %{"isa" => "PBXGroup"} ->
          walk_group(objects, child_id, here, acc)

        %{"isa" => "PBXFileReference", "sourceTree" => "<group>", "path" => path} ->
          Map.put(acc, child_id, Path.join(here, path))

        _other ->
          acc
      end
    end)
  end

  defp missing_files(root, references) do
    references
    |> Map.values()
    |> Enum.reject(&File.exists?(Path.join(root, &1)))
    |> Enum.sort()
  end

  defp base_configuration_ids(project) do
    project
    |> objects()
    |> Map.values()
    |> Enum.filter(&(&1["isa"] == "XCBuildConfiguration" and &1["baseConfigurationReference"]))
    |> Enum.map(& &1["baseConfigurationReference"])
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf(path) end)
    path
  end
end
