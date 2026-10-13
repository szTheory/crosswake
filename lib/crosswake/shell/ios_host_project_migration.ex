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

    if length(configs) != 6 or not proof_configuration_graph?(contents, ids) do
      error()
    else
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

            _ = {indent, id}
            String.replace(acc, block, clean, global: false)
          end)

        {:ok, %{status: :migration_required, contents: migrated}}
      catch
        :unrecognized_project -> error()
      end
    end
  end

  defp proof_configuration_graph?(contents, target_ids) do
    config_section = section(contents, "XCBuildConfiguration")
    list_section = section(contents, "XCConfigurationList")
    target_section = section(contents, "PBXNativeTarget")
    project_section = section(contents, "PBXProject")
    all_ids = Enum.map(70..77, &("A100000000000000000000" <> Integer.to_string(&1)))

    expected_names =
      Map.new(Enum.with_index(all_ids), fn {id, index} ->
        {id, if(rem(index, 2) == 0, do: "Debug", else: "Release")}
      end)

    configs =
      Regex.scan(~r/(?m)^\s*([A-F0-9]{24}) = \{(.*?)\};/, config_section, capture: :all_but_first)
      |> Map.new(fn [id, body] -> {id, body} end)

    config_sets = %{
      "A10000000000000000000040" => Enum.take(all_ids, 2),
      "A10000000000000000000041" => Enum.slice(all_ids, 2, 2),
      "A10000000000000000000042" => Enum.slice(all_ids, 4, 2),
      "A10000000000000000000043" => Enum.slice(all_ids, 6, 2)
    }

    config_lists_valid =
      Enum.all?(config_sets, fn {id, expected} ->
        with body when is_binary(body) <- object_body(list_section, id),
             [_, values] <- Regex.run(~r/buildConfigurations = \(([^)]*)\)/, body),
             actual <- Regex.scan(~r/[A-F0-9]{24}/, values) |> List.flatten() do
          actual == expected
        else
          _ -> false
        end
      end)

    names_valid =
      map_size(configs) == 8 and
        Enum.all?(expected_names, fn {id, name} ->
          case {Map.get(configs, id),
                Regex.run(~r/\bname = (Debug|Release);/, object_body(config_section, id) || "",
                  capture: :all_but_first
                )} do
            {body, [^name]} when is_binary(body) -> true
            _ -> false
          end
        end)

    targets_valid =
      Enum.all?(
        [
          {"A10000000000000000000030", "A10000000000000000000040"},
          {"A10000000000000000000031", "A10000000000000000000041"},
          {"A10000000000000000000032", "A10000000000000000000042"}
        ],
        fn {id, list_id} ->
          body = object_body(target_section, id)

          is_binary(body) and
            Regex.match?(Regex.compile!("buildConfigurationList = " <> list_id <> "\\b"), body)
        end
      )

    project_valid =
      case object_body(project_section, "A10000000000000000000060") do
        body when is_binary(body) ->
          Regex.match?(~r/buildConfigurationList = A10000000000000000000043\b/, body)

        _ ->
          false
      end

    target_ids == Enum.take(all_ids, 6) and names_valid and config_lists_valid and targets_valid and
      project_valid
  rescue
    _ -> false
  end

  defp section(contents, name) do
    opening = "/* Begin #{name} section */"
    closing = "/* End #{name} section */"

    case String.split(contents, opening, parts: 2) do
      [_, remainder] ->
        case String.split(remainder, closing, parts: 2) do
          [value, _] -> value
          _ -> ""
        end

      _ ->
        ""
    end
  end

  defp object_body(section, id) do
    lines = String.split(section, "\n")
    opening = Regex.compile!("^\\s*" <> id <> ".*= \\{")
    next_object = ~r/^\s*[A-F0-9]{24}(?: \/\*.*?\*\/)? = \{/

    case Enum.find_index(lines, &Regex.match?(opening, &1)) do
      nil ->
        nil

      index ->
        lines
        |> Enum.drop(index)
        |> Enum.take_while(fn line ->
          line == hd(Enum.drop(lines, index)) or not Regex.match?(next_object, line)
        end)
        |> Enum.join("\n")
    end
  end

  defp error,
    do:
      {:error,
       %{cause: :unrecognized_project, repair: "restore the recognized shell project structure"}}
end
