defmodule Crosswake.Shell.IOSHostProjectMigration do
  @moduledoc false
  alias Crosswake.Shell.PBXProject

  @identity_keys ~w(CODE_SIGNING_ALLOWED CODE_SIGNING_REQUIRED CODE_SIGN_STYLE CODE_SIGN_IDENTITY DEVELOPMENT_TEAM PROVISIONING_PROFILE PROVISIONING_PROFILE_SPECIFIER CROSSWAKE_APP_BUNDLE_ID CROSSWAKE_SHELL_TEST_BUNDLE_ID CROSSWAKE_PROOF_APP_BUNDLE_ID CROSSWAKE_PROOF_TEST_BUNDLE_ID CROSSWAKE_PROOF_UI_BUNDLE_ID)
  @shell_configs ~w(A10000370000000000000001 A10000380000000000000001 A10000390000000000000001 A100003A0000000000000001 A100003B0000000000000001 A100003C0000000000000001)
  @proof_configs Enum.map(70..77, &("A100000000000000000000" <> Integer.to_string(&1)))

  def preview_contents(contents), do: migrate(contents, spec(:shell))
  def preview_proof_contents(contents), do: migrate(contents, spec(:proof))

  defp spec(:shell) do
    %{
      configs: @shell_configs,
      project: "A10000200000000000000001",
      main_group: "A10000210000000000000001",
      settings_ref: "A10000400000000000000001",
      settings_file: "CrosswakeHostSettings.xcconfig",
      groups: [
        {"A100002F0000000000000001", Enum.take(@shell_configs, 2), nil, nil},
        {"A10000330000000000000001", Enum.slice(@shell_configs, 2, 2), "A100002A0000000000000001",
         "CROSSWAKE_APP_BUNDLE_ID"},
        {"A10000340000000000000001", Enum.slice(@shell_configs, 4, 2), "A100002B0000000000000001",
         "CROSSWAKE_SHELL_TEST_BUNDLE_ID"}
      ]
    }
  end

  defp spec(:proof) do
    %{
      configs: @proof_configs,
      project: "A10000000000000000000060",
      main_group: "A10000000000000000000020",
      settings_ref: "A10000000000000000000019",
      settings_file: "CrosswakeProofSettings.xcconfig",
      groups: [
        {"A10000000000000000000040", Enum.take(@proof_configs, 2), "A10000000000000000000030",
         "CROSSWAKE_PROOF_APP_BUNDLE_ID"},
        {"A10000000000000000000041", Enum.slice(@proof_configs, 2, 2), "A10000000000000000000031",
         "CROSSWAKE_PROOF_TEST_BUNDLE_ID"},
        {"A10000000000000000000042", Enum.slice(@proof_configs, 4, 2), "A10000000000000000000032",
         "CROSSWAKE_PROOF_UI_BUNDLE_ID"},
        {"A10000000000000000000043", Enum.slice(@proof_configs, 6, 2), nil, nil}
      ]
    }
  end

  defp migrate(contents, spec) when is_binary(contents) do
    with {:ok, document} <- PBXProject.parse_document(contents),
         true <- recognized_graph?(document.value, spec) do
      objects = document.children["objects"].children

      edits =
        Enum.flat_map(spec.groups, fn {_list, ids, _target, variable} ->
          Enum.flat_map(ids, &configuration_edits(objects[&1], variable, spec.settings_ref))
        end)

      migrated =
        Enum.reduce(
          Enum.sort_by(edits, fn {start, finish, _} -> {start, finish} end, :desc),
          contents,
          fn {start, finish, replacement}, bytes ->
            binary_part(bytes, 0, start) <>
              replacement <> binary_part(bytes, finish, byte_size(bytes) - finish)
          end
        )

      with {:ok, checked} <- PBXProject.parse(migrated),
           true <- recognized_graph?(checked, spec),
           true <- managed_settings?(checked["objects"], spec) do
        {:ok, %{status: :migration_required, contents: migrated}}
      else
        _ -> error()
      end
    else
      _ -> error()
    end
  rescue
    _ -> error()
  end

  defp recognized_graph?(plist, spec) do
    objects = plist["objects"]
    project = objects[spec.project]
    expected_targets = for {_, _, target, _} <- spec.groups, not is_nil(target), do: target

    with true <- is_map(objects) and Enum.all?(objects, fn {_, value} -> is_map(value) end),
         true <- ids_for(objects, "XCBuildConfiguration") == Enum.sort(spec.configs),
         true <-
           ids_for(objects, "XCConfigurationList") ==
             Enum.sort(Enum.map(spec.groups, &elem(&1, 0))),
         true <- ids_for(objects, "PBXNativeTarget") == Enum.sort(expected_targets),
         true <- ids_for(objects, "PBXProject") == [spec.project],
         true <- plist["rootObject"] == spec.project,
         true <-
           is_list(project["targets"]) and
             Enum.sort(project["targets"]) == Enum.sort(expected_targets),
         true <- project["mainGroup"] == spec.main_group,
         true <- project["projectDirPath"] in [nil, ""] and project["projectRoot"] in [nil, ""],
         true <- settings_reference?(objects, spec),
         true <-
           Enum.all?(spec.groups, fn {list_id, ids, target, variable} ->
             list = objects[list_id]
             owner = if is_nil(target), do: project, else: objects[target]

             list["buildConfigurations"] == ids and
               list["defaultConfigurationName"] in ["Debug", "Release"] and
               owner["buildConfigurationList"] == list_id and
               Enum.all?(Enum.with_index(ids), fn {id, index} ->
                 config = objects[id]

                 config["name"] == if(index == 0, do: "Debug", else: "Release") and
                   is_map(config["buildSettings"]) and
                   if is_nil(variable),
                     do: is_nil(config["baseConfigurationReference"]),
                     else: config["baseConfigurationReference"] in [nil, spec.settings_ref]
               end)
           end) do
      true
    else
      _ -> false
    end
  rescue
    _ -> false
  end

  defp settings_reference?(objects, spec) do
    ref = objects[spec.settings_ref]
    group = objects[spec.main_group]

    parents =
      for {id, object} <- objects,
          object["isa"] == "PBXGroup",
          is_list(object["children"]),
          child <- object["children"],
          child == spec.settings_ref,
          do: id

    ref["isa"] == "PBXFileReference" and ref["path"] == spec.settings_file and
      ref["sourceTree"] == "<group>" and ref["lastKnownFileType"] == "text.xcconfig" and
      group["isa"] == "PBXGroup" and group["sourceTree"] == "<group>" and
      group["path"] in [nil, ""] and
      parents == [spec.main_group]
  end

  defp ids_for(objects, isa),
    do: for({id, object} <- objects, object["isa"] == isa, do: id) |> Enum.sort()

  defp configuration_edits(config, variable, ref) do
    settings = config.children["buildSettings"]
    expected = if is_nil(variable), do: nil, else: "$(#{variable})"

    removals =
      Enum.flat_map(settings.children, fn {key, child} ->
        base = key |> String.split("[", parts: 2) |> hd()

        cond do
          base in @identity_keys ->
            [delete(child.pair)]

          base == "PRODUCT_BUNDLE_IDENTIFIER" and (is_nil(variable) or key != base) ->
            [delete(child.pair)]

          key == "PRODUCT_BUNDLE_IDENTIFIER" and child.value != expected ->
            [replace(child.range, inspect(expected))]

          true ->
            []
        end
      end)

    bundle =
      if not is_nil(variable) and not Map.has_key?(settings.children, "PRODUCT_BUNDLE_IDENTIFIER") do
        {start, _} = settings.range
        [{start + 1, start + 1, " PRODUCT_BUNDLE_IDENTIFIER = #{inspect(expected)};"}]
      else
        []
      end

    base_ref =
      if not is_nil(variable) and not Map.has_key?(config.children, "baseConfigurationReference") do
        {start, _} = config.range
        [{start + 1, start + 1, " baseConfigurationReference = #{ref};"}]
      else
        []
      end

    removals ++ bundle ++ base_ref
  end

  defp managed_settings?(objects, spec) do
    Enum.all?(spec.groups, fn {_, ids, _, variable} ->
      Enum.all?(ids, fn id ->
        config = objects[id]
        settings = config["buildSettings"]
        expected = if is_nil(variable), do: nil, else: "$(#{variable})"

        Enum.all?(Map.keys(settings), fn key ->
          base = key |> String.split("[", parts: 2) |> hd()

          base not in @identity_keys and
            (base != "PRODUCT_BUNDLE_IDENTIFIER" or (not is_nil(variable) and key == base))
        end) and settings["PRODUCT_BUNDLE_IDENTIFIER"] == expected and
          (is_nil(variable) or config["baseConfigurationReference"] == spec.settings_ref)
      end)
    end)
  end

  defp delete({start, finish}), do: {start, finish, ""}
  defp replace({start, finish}, value), do: {start, finish, value}

  defp error,
    do:
      {:error,
       %{cause: :unrecognized_project, repair: "restore the recognized shell project structure"}}
end
