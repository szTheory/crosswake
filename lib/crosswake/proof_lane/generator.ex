defmodule Crosswake.ProofLane.Generator do
  @moduledoc "Renders a host-owned proof lane with atomic, missing-only writes."

  alias Crosswake.ProofLane.{Config, GeneratorFS}

  @schema_version 1
  @template_version 2
  @templates [
    {"test/crosswake_proof_lane/crosswake_proof_lane_test.exs",
     "test/crosswake_proof_lane_test.exs.eex"},
    {"e2e/crosswake_proof_lane/proof_lane.spec.ts", "e2e/proof_lane.spec.ts.eex"},
    {"e2e/crosswake_proof_lane/support/proof_lane.ts", "e2e/support/proof_lane.ts.eex"},
    {"e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts",
     "e2e/support/proof_lane_host_adapter.ts.eex"},
    {"CrosswakeProofLane/ProofLaneDriver.swift", "ios/ProofLaneDriver.swift.eex"},
    {"CrosswakeProofLane/ProofLaneApp.swift", "ios/ProofLaneApp.swift.eex"},
    {"CrosswakeProofLaneTests/ProofLaneContractTests.swift",
     "ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"},
    {"CrosswakeProofLaneUITests/ProofLaneUITests.swift",
     "ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"},
    {"CrosswakeProofLane.xcodeproj/project.pbxproj",
     "ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"},
    {"CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme",
     "ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex"}
  ]

  @type finding :: %{rule_id: String.t(), path: String.t(), remediation: String.t()}
  @type diff_entry :: %{path: String.t(), status: :missing | :different | :current}

  @spec generate(Config.t()) ::
          {:ok, [%{path: String.t(), status: :created | :reused}]}
          | {:error, {String.t(), String.t()}}
  def generate(%Config{} = config) do
    config = normalize!(config)
    root = host_root!(config)
    desired = desired(config)

    GeneratorFS.with_lifecycle(fn ->
      with {:ok, results} <- ensure_files(root, desired),
           :ok <- interrupt_before_manifest(),
           {:ok, manifest_result} <- ensure_manifest(root, desired) do
        {:ok, Enum.sort_by(results ++ [manifest_result], & &1.path)}
      end
    end)
  end

  @spec check(Config.t()) :: :ok | {:error, [finding()]}
  def check(%Config{} = config) do
    config = normalize!(config)
    root = host_root!(config)
    desired = desired(config)

    GeneratorFS.with_lifecycle(fn ->
      findings =
        missing_findings(root, desired) ++ manifest_findings(root, desired)

      case findings |> Enum.uniq() |> Enum.sort_by(& &1.path) do
        [] -> :ok
        findings -> {:error, findings}
      end
    end)
  end

  @spec diff(Config.t()) :: [diff_entry()]
  def diff(%Config{} = config) do
    config = normalize!(config)
    root = host_root!(config)
    desired = desired(config)

    GeneratorFS.with_lifecycle(fn ->
      desired
      |> Kernel.++([manifest_desired(desired)])
      |> Enum.map(fn %{path: path, relative: relative, contents: contents} ->
        status =
          case GeneratorFS.read(root, relative) do
            {:ok, ^contents} -> :current
            {:ok, _} -> :different
            _ -> :missing
          end

        %{path: path, status: status}
      end)
      |> Enum.sort_by(& &1.path)
    end)
  end

  defp desired(config) do
    Enum.map(@templates, fn {relative, template} ->
      %{
        path: relative,
        relative: destination_relative(relative),
        contents: render(template, config)
      }
    end)
  end

  defp ensure_files(root, desired) do
    Enum.reduce_while(desired, {:ok, []}, fn entry, {:ok, results} ->
      case ensure_missing(root, entry.relative, entry.contents, entry.path) do
        {:ok, result} -> {:cont, {:ok, [result | results]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp ensure_manifest(root, desired) do
    manifest = manifest_desired(desired)

    case GeneratorFS.read(root, manifest.relative) do
      {:ok, _} ->
        {:ok, %{path: manifest.path, status: :reused}}

      {:error, :missing} ->
        ensure_missing(root, manifest.relative, manifest.contents, manifest.path)

      {:error, :unsafe} ->
        {:error, {"PL-GENERATE-DESTINATION", manifest.path}}
    end
  end

  defp ensure_missing(root, relative, contents, relative_path) do
    case GeneratorFS.write(root, relative, contents) do
      {:ok, status} -> {:ok, %{path: relative_path, status: status}}
      {:error, _} = error -> error
    end
  end

  defp interrupt_before_manifest do
    if Process.get(:crosswake_proof_lane_interrupt_before_manifest) do
      {:error, {"PL-GENERATE-INTERRUPTED", "manifest"}}
    else
      :ok
    end
  end

  defp missing_findings(root, desired) do
    Enum.flat_map(desired, fn %{path: path, relative: relative} ->
      case GeneratorFS.status(root, relative) do
        :regular -> []
        :missing -> [finding("PL-GENERATE-MISSING", path, "run mix crosswake.gen.proof_lane ios")]
        :unsafe -> [finding("PL-GENERATE-DESTINATION", path, "use a contained iOS shell root")]
      end
    end)
  end

  defp manifest_findings(root, desired) do
    manifest = manifest_desired(desired)

    case GeneratorFS.read(root, manifest.relative) do
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

      {:error, :missing} ->
        [finding("PL-GENERATE-MISSING", manifest.path, "run mix crosswake.gen.proof_lane ios")]

      _ ->
        [finding("PL-GENERATE-DESTINATION", manifest.path, "use a contained iOS shell root")]
    end
  end

  defp manifest_desired(desired) do
    %{
      path: ".crosswake/proof_lane.json",
      relative: ".crosswake/proof_lane.json",
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

  defp host_root!(config) do
    case Config.host_root(config) do
      {:ok, root} -> root
      {:error, error} -> raise error
    end
  end

  defp normalize!(%Config{} = config) do
    case Config.normalize(Map.from_struct(config)) do
      {:ok, normalized} -> normalized
      {:error, error} -> raise error
    end
  end

  defp destination_relative(relative) do
    if String.starts_with?(relative, "CrosswakeProofLane") do
      Path.join(["native", "ios", relative])
    else
      relative
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
end
