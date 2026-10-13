defmodule Crosswake.Shell.IOSHostProjectMigration do
  @moduledoc false
  @known_ids ~w(A10000370000000000000001 A10000380000000000000001 A10000390000000000000001 A100003A0000000000000001 A100003B0000000000000001 A100003C0000000000000001)
  @identity_keys ~w(CODE_SIGNING_ALLOWED CODE_SIGNING_REQUIRED CODE_SIGN_STYLE CODE_SIGN_IDENTITY DEVELOPMENT_TEAM PROVISIONING_PROFILE_SPECIFIER)

  def preview_contents(contents) when is_binary(contents) do
    pattern = Regex.compile!("(?m)^([ \\t]*)([A-F0-9]{24}).* = \\{\\n(?s:.*?)^\\1\\};")

    configs =
      Regex.scan(pattern, contents)
      |> Enum.map(fn [block, _indent, id] ->
        name =
          case Regex.run(~r/\n\s*name = (Debug|Release);/, block, capture: :all_but_first) do
            [value] -> value
            _ -> nil
          end

        {block, id, name}
      end)
      |> Enum.filter(fn {block, _, _} ->
        String.contains?(block, "isa = XCBuildConfiguration;")
      end)

    ids = Enum.map(configs, fn {_, id, _} -> id end) |> Enum.sort()

    if ids != Enum.sort(@known_ids) or
         Enum.any?(configs, fn {_, _, n} -> n not in ["Debug", "Release"] end) do
      error()
    else
      try do
        migrated =
          Enum.reduce(configs, contents, fn {block, id, _}, acc ->
            target? = id in Enum.drop(@known_ids, 2)
            ref = "A10000400000000000000001"

            refs =
              Regex.scan(~r/baseConfigurationReference = ([A-F0-9]{24})/, block,
                capture: :all_but_first
              )

            if target? and refs != [] and refs != [[ref]], do: throw(:unrecognized_project)

            clean =
              Enum.reduce(@identity_keys, block, fn key, value ->
                String.replace(
                  value,
                  Regex.compile!("^\\s*" <> key <> " = [^;]+;\\n", "m"),
                  ""
                )
              end)
              |> String.replace(~r/^\s*PRODUCT_BUNDLE_IDENTIFIER = [^;]+;\n/m, "")

            clean =
              if target? do
                variable =
                  if id in Enum.slice(@known_ids, 2, 2),
                    do: "CROSSWAKE_APP_BUNDLE_ID",
                    else: "CROSSWAKE_SHELL_TEST_BUNDLE_ID"

                Regex.replace(
                  ~r/(buildSettings\s*=\s*\{)/,
                  clean,
                  fn prefix ->
                    prefix <> "\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"$(#{variable})\";"
                  end,
                  global: false
                )
              else
                clean
              end

            clean =
              if target? and refs == [] do
                String.replace(
                  clean,
                  "isa = XCBuildConfiguration;\n",
                  "isa = XCBuildConfiguration;\n\t\t\tbaseConfigurationReference = #{ref} /* CrosswakeHostSettings.xcconfig */;\n",
                  global: false
                )
              else
                clean
              end

            String.replace(acc, block, clean, global: false)
          end)

        {:ok, %{status: :migration_required, contents: migrated}}
      catch
        :unrecognized_project -> error()
      end
    end
  end

  def preview_proof_contents(contents) when is_binary(contents) do
    ids = for number <- 70..75, do: "A100000000000000000000" <> Integer.to_string(number)
    ref = "A10000000000000000000019"

    pattern =
      Regex.compile!(
        "(?m)^([ \\t]*)(" <> Enum.join(ids, "|") <> ") = \\{isa = XCBuildConfiguration;.*?\\};$"
      )

    configs = Regex.scan(pattern, contents)

    graph_valid? = proof_configuration_graph?(contents, ids)

    if not graph_valid? do
      error()
    else
      if length(configs) != 6 do
        {:ok, %{status: :migration_required, contents: contents}}
      else
        migrate_proof_configs(contents, configs, ids, ref)
      end
    end
  end

  defp migrate_proof_configs(contents, configs, ids, ref) do
    try do
      migrated =
        Enum.reduce(configs, contents, fn [block, indent, id], acc ->
          if not Regex.match?(~r/name = (Debug|Release);/, block),
            do: throw(:unrecognized_project)

          refs =
            Regex.scan(~r/baseConfigurationReference = ([A-F0-9]{24})/, block,
              capture: :all_but_first
            )

          if refs != [] and refs != [[ref]], do: throw(:unrecognized_project)

          clean =
            block
            |> String.replace(~r/PRODUCT_BUNDLE_IDENTIFIER = [^;]+; /, "")
            |> String.replace(~r/CODE_SIGNING_(?:ALLOWED|REQUIRED) = [^;]+; /, "")
            |> String.replace(~r/CODE_SIGN_STYLE = [^;]+; /, "")
            |> String.replace(~r/DEVELOPMENT_TEAM = [^;]+; /, "")
            |> String.replace(~r/PROVISIONING_PROFILE_SPECIFIER = [^;]+; /, "")

          variable =
            cond do
              id in Enum.take(ids, 2) -> "CROSSWAKE_PROOF_APP_BUNDLE_ID"
              id in Enum.slice(ids, 2, 2) -> "CROSSWAKE_PROOF_TEST_BUNDLE_ID"
              true -> "CROSSWAKE_PROOF_UI_BUNDLE_ID"
            end

          clean =
            clean
            |> String.replace(
              "buildSettings = {",
              "buildSettings = { PRODUCT_BUNDLE_IDENTIFIER = \"$(#{variable})\";",
              global: false
            )

          clean =
            if refs == [],
              do:
                String.replace(
                  clean,
                  "isa = XCBuildConfiguration;",
                  "isa = XCBuildConfiguration; baseConfigurationReference = #{ref} /* CrosswakeProofSettings.xcconfig */;",
                  global: false
                ),
              else: clean

          _ = indent
          String.replace(acc, block, clean, global: false)
        end)

      {:ok, %{status: :migration_required, contents: migrated}}
    catch
      :unrecognized_project -> error()
    end
  end

  defp proof_configuration_graph?(contents, target_ids) do
    all_ids = Enum.map(70..77, &("A100000000000000000000" <> Integer.to_string(&1)))

    config_sets = %{
      "A10000000000000000000040" => Enum.take(all_ids, 2),
      "A10000000000000000000041" => Enum.slice(all_ids, 2, 2),
      "A10000000000000000000042" => Enum.slice(all_ids, 4, 2),
      "A10000000000000000000043" => Enum.slice(all_ids, 6, 2)
    }

    with {:ok, plist} <- Crosswake.Shell.PBXProject.parse(contents),
         objects when is_map(objects) <- plist["objects"],
         configs <-
           objects
           |> Enum.filter(fn {_id, object} -> object["isa"] == "XCBuildConfiguration" end)
           |> Map.new(),
         lists <-
           objects
           |> Enum.filter(fn {_id, object} -> object["isa"] == "XCConfigurationList" end)
           |> Map.new(),
         targets <-
           objects
           |> Enum.filter(fn {_id, object} -> object["isa"] == "PBXNativeTarget" end)
           |> Map.new(),
         projects <-
           objects
           |> Enum.filter(fn {_id, object} -> object["isa"] == "PBXProject" end)
           |> Map.new(),
         true <- Map.keys(configs) |> Enum.sort() == Enum.sort(all_ids),
         true <- map_size(lists) == 4,
         true <-
           Enum.all?(all_ids, fn id ->
             object = configs[id]

             expected =
               if rem(Enum.find_index(all_ids, &(&1 == id)), 2) == 0, do: "Debug", else: "Release"

             object["name"] == expected
           end),
         true <-
           Enum.all?(config_sets, fn {id, expected} ->
             lists[id]["buildConfigurations"] == expected
           end),
         true <-
           Enum.all?(
             [
               {"A10000000000000000000030", "A10000000000000000000040"},
               {"A10000000000000000000031", "A10000000000000000000041"},
               {"A10000000000000000000032", "A10000000000000000000042"}
             ],
             fn {id, list_id} -> targets[id]["buildConfigurationList"] == list_id end
           ),
         true <- map_size(targets) == 3,
         true <- map_size(projects) == 1,
         true <-
           projects["A10000000000000000000060"]["buildConfigurationList"] ==
             "A10000000000000000000043",
         true <- target_ids == Enum.take(all_ids, 6) do
      true
    else
      _ -> false
    end
  rescue
    _ -> false
  end

  defp error,
    do:
      {:error,
       %{cause: :unrecognized_project, repair: "restore the recognized shell project structure"}}
end
