defmodule Crosswake.Bridge.LocationDiagnosticsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Bridge
  alias Crosswake.Bridge.UndeclaredCapabilityError
  alias Crosswake.Manifest.Types

  defmodule BrokenReflection do
    def __routes__, do: raise(ArgumentError, "synthetic_private_hint")
  end

  test "unavailable route reflection preserves the original authoring error" do
    for router <- [nil, UnavailableRouter, BrokenReflection] do
      message = authoring_error(router)
      assert message =~ "[crosswake.bridge.undeclared_capability]"
      assert message =~ "capabilities: [\"haptics\"]"
      assert message =~ "router location unavailable"
      refute message =~ "synthetic_private_hint"
    end
  end

  test "diagnostic helpers use explicit outcomes and finite rescue classes" do
    {:ok, ast} = "lib/crosswake/bridge.ex" |> File.read!() |> Code.string_to_quoted()

    {_, helpers} =
      Macro.prewalk(ast, [], fn
        {:defp, _, [{name, _, _}, _]} = node, acc
        when name in [:find_router_route, :router_source_file, :best_effort_line_suffix] ->
          {node, [node | acc]}

        node, acc ->
          {node, acc}
      end)

    assert length(helpers) == 3

    for helper <- helpers do
      text = Macro.to_string(helper)
      assert text =~ "{:ok,"
      assert text =~ "{:error,"
      refute text =~ "_ ->"
    end
  end

  test "missing, unreadable and malformed source hints cannot replace authoring errors" do
    root = Path.join(System.tmp_dir!(), "bridge-location-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    for {name, content, suffix} <- [
          {"missing", nil, ""},
          {"directory", :directory, ""},
          {"invalid", <<255>>, ""},
          {"no_hint", "defmodule SourceWithoutHint do\nend", ""},
          {"valid", "# router\nid: \"diagnostic\"", ":2"}
        ] do
      file = Path.join(root, name)

      case content do
        nil -> :ok
        :directory -> File.mkdir_p!(file)
        bytes -> File.write!(file, bytes)
      end

      module = Module.concat(__MODULE__, "Source#{name}")

      Code.compile_string(
        """
        defmodule #{inspect(module)} do
          def __routes__ do
            [%{metadata: %{crosswake_policy: Crosswake.Policy.Route.new!(id: "diagnostic", runtime: :live_view, offline: :unavailable)}}]
          end
        end
        """,
        file
      )

      message = authoring_error(module)
      assert message =~ "Router location: #{file}#{suffix}\n"
      assert message =~ "[crosswake.bridge.undeclared_capability]"
      refute message =~ "File.Error"
      refute message =~ "synthetic_private_hint"
    end
  end

  defp authoring_error(router) do
    manifest =
      Types.new_root(
        crosswake_version: "0.2.11",
        generated_at: "2026-10-27T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: %{},
        routes: %{
          "diagnostic" =>
            Types.new_route_entry(
              id: "diagnostic",
              path: "/diagnostic",
              runtime: :live_view,
              offline: :unavailable,
              capabilities: []
            )
        }
      )

    socket = %Phoenix.LiveView.Socket{
      router: router,
      view: __MODULE__,
      private: %{crosswake_bridge: %{manifest: manifest, route_id: "diagnostic"}}
    }

    error = assert_raise UndeclaredCapabilityError, fn -> Bridge.push(socket, "haptics") end
    error.message
  end
end
