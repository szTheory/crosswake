defmodule Crosswake.ProofLane.Generator do
  @moduledoc "Renders a host-owned proof lane with atomic, missing-only writes."

  alias Crosswake.ProofLane.Config

  @schema_version 1
  @template_version 1
  @templates [
    {"test/crosswake_proof_lane/crosswake_proof_lane_test.exs",
     "test/crosswake_proof_lane_test.exs.eex"},
    {"e2e/crosswake_proof_lane/proof_lane.spec.ts", "e2e/proof_lane.spec.ts.eex"},
    {"e2e/crosswake_proof_lane/support/proof_lane.ts", "e2e/support/proof_lane.ts.eex"},
    {"CrosswakeProofLane/ProofLaneDriver.swift", "ios/ProofLaneDriver.swift.eex"},
    {"CrosswakeProofLane.xcodeproj/project.pbxproj",
     "ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"}
  ]

  @type finding :: %{rule_id: String.t(), path: String.t(), remediation: String.t()}
  @type diff_entry :: %{path: String.t(), status: :missing | :different | :current}

  @spec generate(Config.t()) ::
          {:ok, [%{path: String.t(), status: :created | :reused}]}
          | {:error, {String.t(), String.t()}}
  def generate(%Config{} = config) do
    root = host_root(config)
    desired = desired(config)

    with :ok <- validate_destinations(root, desired),
         {:ok, results} <- ensure_files(desired),
         :ok <- interrupt_before_manifest(),
         {:ok, manifest_result} <- ensure_manifest(root, desired) do
      {:ok, Enum.sort_by(results ++ [manifest_result], & &1.path)}
    end
  end

  @spec check(Config.t()) :: :ok | {:error, [finding()]}
  def check(%Config{} = config) do
    root = host_root(config)
    desired = desired(config)

    findings =
      validate_destinations_findings(root, desired) ++
        missing_findings(root, desired) ++ manifest_findings(root, desired)

    case findings |> Enum.uniq() |> Enum.sort_by(& &1.path) do
      [] -> :ok
      findings -> {:error, findings}
    end
  end

  @spec diff(Config.t()) :: [diff_entry()]
  def diff(%Config{} = config) do
    root = host_root(config)

    desired(config)
    |> Kernel.++([manifest_desired(root, desired(config))])
    |> Enum.map(fn %{path: path, destination: destination, contents: contents} ->
      status =
        case File.read(destination) do
          {:ok, ^contents} -> :current
          {:ok, _} -> :different
          _ -> :missing
        end

      %{path: path, status: status}
    end)
    |> Enum.sort_by(& &1.path)
  end

  defp desired(config) do
    root = host_root(config)

    Enum.map(@templates, fn {relative, template} ->
      %{
        path: relative,
        destination: destination(root, relative),
        contents: render(template, config)
      }
    end)
  end

  defp ensure_files(desired) do
    Enum.reduce_while(desired, {:ok, []}, fn entry, {:ok, results} ->
      case ensure_missing(entry.destination, entry.contents, entry.path) do
        {:ok, result} -> {:cont, {:ok, [result | results]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp ensure_manifest(root, desired) do
    manifest = manifest_desired(root, desired)
    path = manifest.destination

    case File.read(path) do
      {:ok, _} -> {:ok, %{path: manifest.path, status: :reused}}
      {:error, :enoent} -> promote_manifest(path, manifest.contents, manifest.path)
      {:error, _} -> {:error, {"PL-GENERATE-COLLISION", manifest.path}}
    end
  end

  defp promote_manifest(path, contents, relative_path) do
    staging = path <> ".staging-" <> Integer.to_string(System.unique_integer([:positive]))

    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, io} <- File.open(staging, [:write, :exclusive, :binary]),
         :ok <- IO.binwrite(io, contents),
         :ok <- File.close(io) do
      case File.ln(staging, path) do
        :ok ->
          File.rm(staging)
          {:ok, %{path: relative_path, status: :created}}

        {:error, :eexist} ->
          File.rm(staging)
          {:ok, %{path: relative_path, status: :reused}}

        {:error, _} ->
          File.rm(staging)
          {:error, {"PL-GENERATE-MANIFEST", "manifest"}}
      end
    else
      {:error, _} ->
        File.rm(staging)
        {:error, {"PL-GENERATE-MANIFEST", "manifest"}}
    end
  end

  defp ensure_missing(path, contents, relative_path) do
    with :ok <- File.mkdir_p(Path.dirname(path)) do
      case File.open(path, [:write, :exclusive, :binary]) do
        {:ok, io} ->
          case IO.binwrite(io, contents) do
            :ok ->
              :ok = File.close(io)
              {:ok, %{path: relative_path, status: :created}}

            {:error, _} ->
              File.close(io)
              {:error, {"PL-GENERATE-WRITE", relative_path}}
          end

        {:error, :eexist} ->
          {:ok, %{path: relative_path, status: :reused}}

        {:error, _} ->
          {:error, {"PL-GENERATE-WRITE", relative_path}}
      end
    else
      {:error, _} -> {:error, {"PL-GENERATE-WRITE", relative_path}}
    end
  end

  defp interrupt_before_manifest do
    if Process.get(:crosswake_proof_lane_interrupt_before_manifest) do
      {:error, {"PL-GENERATE-INTERRUPTED", "manifest"}}
    else
      :ok
    end
  end

  defp validate_destinations(root, desired) do
    if validate_destinations_findings(root, desired) == [],
      do: :ok,
      else: {:error, {"PL-GENERATE-DESTINATION", "destination"}}
  end

  defp validate_destinations_findings(root, desired) do
    Enum.flat_map(desired ++ [manifest_desired(root, desired)], fn %{
                                                                     path: path,
                                                                     destination: destination
                                                                   } ->
      if within?(root, destination) do
        []
      else
        [finding("PL-GENERATE-DESTINATION", path, "use a contained iOS shell root")]
      end
    end)
  end

  defp missing_findings(_root, desired) do
    Enum.flat_map(desired, fn %{path: path, destination: destination} ->
      if File.regular?(destination),
        do: [],
        else: [finding("PL-GENERATE-MISSING", path, "run mix crosswake.gen.proof_lane ios")]
    end)
  end

  defp manifest_findings(root, desired) do
    manifest = manifest_desired(root, desired)

    case File.read(manifest.destination) do
      {:ok, contents} when contents == manifest.contents ->
        []

      {:ok, _} ->
        [
          finding(
            "PL-GENERATE-PROVENANCE",
            manifest.path,
            "review template provenance and run the generator"
          )
        ]

      _ ->
        [finding("PL-GENERATE-MISSING", manifest.path, "run mix crosswake.gen.proof_lane ios")]
    end
  end

  defp manifest_desired(root, desired) do
    %{
      path: ".crosswake/proof_lane.json",
      destination: destination(root, ".crosswake/proof_lane.json"),
      contents:
        Jason.encode!(%{
          "schema_version" => @schema_version,
          "template_version" => @template_version,
          "paths" => Enum.map(desired, & &1.path),
          "provenance" => "crosswake:proof-lane"
        })
    }
  end

  defp finding(rule_id, path, remediation),
    do: %{rule_id: rule_id, path: path, remediation: remediation}

  defp host_root(config), do: config.ios_shell_root |> Path.dirname() |> Path.dirname()

  defp destination(root, relative) do
    if String.starts_with?(relative, "CrosswakeProofLane") do
      Path.join([root, "native", "ios", relative])
    else
      Path.join(root, relative)
    end
  end

  defp within?(root, path) do
    expanded_root = Path.expand(root)
    expanded_path = Path.expand(path)
    expanded_path == expanded_root or String.starts_with?(expanded_path, expanded_root <> "/")
  end

  defp render(template, config) do
    EEx.eval_file(template_path(template),
      assigns: [config: config, template_version: @template_version]
    )
  end

  defp template_path(template) do
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/proof_lane", template))
  end
end
