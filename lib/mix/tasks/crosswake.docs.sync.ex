defmodule Mix.Tasks.Crosswake.Docs.Sync do
  use Mix.Task

  @shortdoc "Synchronizes generated Crosswake documentation projections"

  @moduledoc """
  Synchronizes the checked-in support and capability guides with their canonical
  executable owners.

      mix crosswake.docs.sync
      mix crosswake.docs.sync --check

  The default form writes changed projections idempotently. The `--check` form
  renders and compares in memory without writing or staging files.
  """

  alias Crosswake.CapabilityMap.Renderer, as: CapabilityRenderer
  alias Crosswake.SupportMatrix
  alias Crosswake.SupportMatrix.Renderer, as: SupportRenderer

  @remediation "mix crosswake.docs.sync"

  @impl Mix.Task
  def run([]) do
    results =
      projections()
      |> Enum.map(fn projection ->
        {projection.target, projection.write.()}
      end)

    Mix.shell().info("crosswake.docs.sync complete")

    Enum.each(results, fn {target, {:ok, action}} ->
      Mix.shell().info("  #{action}: #{target}")
    end)
  end

  def run(["--check"]) do
    drift =
      projections()
      |> Enum.flat_map(fn projection ->
        expected = projection.render.()

        case File.read(projection.target) do
          {:ok, ^expected} ->
            []

          {:ok, _different} ->
            [projection]

          {:error, :enoent} ->
            [projection]

          {:error, reason} ->
            Mix.raise(
              "could not read generated documentation target #{projection.target}: #{:file.format_error(reason)}; run `#{@remediation}`"
            )
        end
      end)

    case drift do
      [] ->
        Mix.shell().info("crosswake.docs.sync --check passed")

      projections ->
        details =
          Enum.map_join(projections, "\n", fn projection ->
            "  source=#{projection.source} target=#{projection.target}"
          end)

        Mix.raise("generated documentation is out of date:\n#{details}\nrun `#{@remediation}`")
    end
  end

  def run(_args) do
    Mix.raise(
      "invalid arguments for crosswake.docs.sync; expected exactly `mix crosswake.docs.sync` or `mix crosswake.docs.sync --check`"
    )
  end

  defp projections do
    [
      %{
        source: "lib/crosswake/capability_map.ex",
        target: "guides/capability_map.md",
        render: &CapabilityRenderer.render/0,
        write: &CapabilityRenderer.write/0
      },
      %{
        source: "lib/crosswake/support_matrix/support_matrix.ex",
        target: "guides/support_matrix.md",
        render: fn -> SupportRenderer.render(SupportMatrix.canonical()) end,
        write: fn ->
          SupportRenderer.write("guides/support_matrix.md", SupportMatrix.canonical())
        end
      }
    ]
  end
end
