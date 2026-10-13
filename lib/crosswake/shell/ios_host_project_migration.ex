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
              block
              |> String.replace(~r/^\s*PRODUCT_BUNDLE_IDENTIFIER = [^;]+;\n/m, "")
              |> then(fn text ->
                if target? do
                  Enum.reduce(@identity_keys, text, fn key, value ->
                    String.replace(
                      value,
                      Regex.compile!("^\\s*" <> key <> " = [^;]+;\\n", "m"),
                      ""
                    )
                  end)
                else
                  text
                end
              end)

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

  defp error,
    do:
      {:error,
       %{cause: :unrecognized_project, repair: "restore the recognized shell project structure"}}
end
