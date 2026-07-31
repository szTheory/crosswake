defmodule Crosswake.ProofLane.Generator do
  @moduledoc "Renders the proof lane desired state using missing-only, host-owned writes."

  alias Crosswake.ProofLane.Config

  @template_version 1
  @templates [
    {"test/crosswake_proof_lane/crosswake_proof_lane_test.exs",
     "test/crosswake_proof_lane_test.exs.eex"},
    {"e2e/crosswake_proof_lane/proof_lane.spec.ts", "e2e/proof_lane.spec.ts.eex"},
    {"CrosswakeProofLane/ProofLaneDriver.swift", "ios/ProofLaneDriver.swift.eex"},
    {"CrosswakeProofLane.xcodeproj/project.pbxproj",
     "ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"}
  ]

  @spec generate(Config.t()) :: {:ok, [map()]} | {:error, {String.t(), String.t()}}
  def generate(%Config{} = config) do
    root = host_root(config)

    destinations =
      Enum.map(@templates, fn {relative, template} ->
        {destination(config, relative), template}
      end)

    manifest = Path.join(root, ".crosswake/proof_lane.json")

    with :ok <- validate_destinations(root, Enum.map(destinations, &elem(&1, 0)) ++ [manifest]) do
      results =
        Enum.map(destinations, fn {path, template} ->
          ensure_missing(path, render(template, config))
        end)

      manifest_result = ensure_missing(manifest, Jason.encode!(manifest(config), pretty: true))

      if Enum.any?(results ++ [manifest_result], &match?({:error, _}, &1)) do
        {:error, {"proof_lane.destination_collision", "destination"}}
      else
        {:ok, results ++ [manifest_result]}
      end
    end
  end

  @spec check(Config.t()) :: :ok | {:error, {String.t(), String.t()}}
  def check(%Config{} = config) do
    root = host_root(config)

    required =
      Enum.map(@templates, fn {relative, _} -> destination(config, relative) end) ++
        [Path.join(root, ".crosswake/proof_lane.json")]

    if Enum.all?(required, &File.regular?/1),
      do: :ok,
      else: {:error, {"proof_lane.missing_scaffold", "destination"}}
  end

  @spec diff(Config.t()) :: [String.t()]
  def diff(%Config{} = config) do
    @templates
    |> Enum.map(&elem(&1, 0))
    |> Kernel.++([".crosswake/proof_lane.json"])
    |> Enum.reject(fn relative ->
      path =
        if relative == ".crosswake/proof_lane.json",
          do: Path.join(host_root(config), relative),
          else: destination(config, relative)

      File.exists?(path)
    end)
  end

  defp host_root(config), do: config.ios_shell_root |> Path.dirname() |> Path.dirname()

  defp destination(config, relative) do
    if String.starts_with?(relative, "CrosswakeProofLane") do
      Path.join(config.ios_shell_root, relative)
    else
      Path.join(host_root(config), relative)
    end
  end

  defp validate_destinations(root, paths) do
    if Enum.all?(paths, &within?(root, &1)),
      do: :ok,
      else: {:error, {"proof_lane.unsafe_destination", "destination"}}
  end

  defp within?(root, path) do
    expanded_root = Path.expand(root)
    expanded_path = Path.expand(path)
    expanded_path == expanded_root or String.starts_with?(expanded_path, expanded_root <> "/")
  end

  defp ensure_missing(path, contents) do
    case File.read(path) do
      {:ok, _} ->
        {:reused, path}

      {:error, :enoent} ->
        with :ok <- File.mkdir_p(Path.dirname(path)),
             {:ok, io} <- File.open(path, [:write, :exclusive, :binary]),
             :ok <- IO.binwrite(io, contents),
             :ok <- File.close(io) do
          {:created, path}
        else
          {:error, :eexist} -> {:reused, path}
          {:error, _} -> {:error, path}
        end

      {:error, _} ->
        {:error, path}
    end
  end

  defp render(template, config) do
    EEx.eval_file(template_path(template),
      assigns: [config: config, template_version: @template_version]
    )
  end

  defp template_path(template) do
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/proof_lane", template))
  end

  defp manifest(config) do
    %{
      "schema_version" => 1,
      "template_version" => @template_version,
      "paths" => Enum.map(@templates, &elem(&1, 0)),
      "route_id" => config.route_id
    }
  end
end
