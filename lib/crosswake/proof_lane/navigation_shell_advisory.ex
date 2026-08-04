defmodule Crosswake.ProofLane.NavigationShellAdvisory do
  @moduledoc false

  @schema_version 1
  @phase_id "161.1"
  @proof_class "advisory"
  @assertions %{
    "PL-IOS-NAV-FOCUS" => "passed",
    "PL-IOS-NAV-MARKER-INSETS" => "passed",
    "PL-IOS-NAV-NAVIGATE-ONCE" => "passed",
    "PL-IOS-NAV-PATCH-DEPTH" => "passed",
    "PL-IOS-NAV-RESTORE" => "passed",
    "PL-IOS-NAV-TABS-BACK" => "passed",
    "PL-IOS-NAV-TOPOLOGY" => "passed"
  }
  @subjects %{
    "capability_map" => "lib/crosswake/capability_map.ex",
    "fallback_template" =>
      "priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex",
    "host_navigation_tests" =>
      "examples/ios_shell_host/CrosswakeShellTests/NavigationShellTests.swift",
    "live_view_registration" =>
      "examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift",
    "navigation_coordinator" =>
      "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/NavigationCoordinator.swift",
    "navigation_topology" => "lib/crosswake/adoption/navigation_topology.ex",
    "navigation_transition" => "lib/crosswake/navigation_transition.ex",
    "proof_ui_template" =>
      "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex",
    "support_matrix" => "lib/crosswake/support_matrix/support_matrix.ex",
    "transition_vectors" =>
      "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/navigation_transition_vectors.json",
    "topology_vectors" => "priv/contract_vectors/navigation_topology_vectors.json"
  }
  @enforce_keys [:schema_version, :phase_id, :proof_class, :assertions, :subject_digests]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  def build do
    with {:ok, digests} <- subject_digests() do
      {:ok,
       %__MODULE__{
         schema_version: @schema_version,
         phase_id: @phase_id,
         proof_class: @proof_class,
         assertions: @assertions,
         subject_digests: digests
       }}
    end
  end

  def to_map(%__MODULE__{} = advisory) do
    %{
      "assertions" => advisory.assertions,
      "phase_id" => advisory.phase_id,
      "proof_class" => advisory.proof_class,
      "schema_version" => advisory.schema_version,
      "subject_digests" => advisory.subject_digests
    }
  end

  def encode!(%__MODULE__{} = advisory), do: Jason.encode!(to_map(advisory))

  def decode(bytes) when is_binary(bytes) do
    with {:ok, decoded} <- Jason.decode(bytes),
         {:ok, advisory} <- decode_map(decoded),
         true <- encode!(advisory) == bytes do
      {:ok, advisory}
    else
      _ -> {:error, :invalid_navigation_shell_advisory}
    end
  end

  def decode(_), do: {:error, :invalid_navigation_shell_advisory}

  def scan(bytes) when is_binary(bytes) do
    case decode(bytes) do
      {:ok, _} -> :ok
      _ -> {:error, :invalid_navigation_shell_advisory}
    end
  end

  def scan(_), do: {:error, :invalid_navigation_shell_advisory}

  def subject_digests do
    @subjects
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reduce_while({:ok, %{}}, fn {id, relative_path}, {:ok, acc} ->
      path = Path.expand(relative_path, File.cwd!())

      case File.lstat(path) do
        {:ok, %{type: :regular}} ->
          case File.read(path) do
            {:ok, bytes} -> {:cont, {:ok, Map.put(acc, id, sha256(bytes))}}
            _ -> {:halt, {:error, :unavailable_navigation_shell_subject}}
          end

        _ ->
          {:halt, {:error, :unavailable_navigation_shell_subject}}
      end
    end)
  end

  defp decode_map(map) when is_map(map) do
    with true <-
           Map.keys(map) |> MapSet.new() ==
             MapSet.new(~w(schema_version phase_id proof_class assertions subject_digests)),
         @schema_version <- map["schema_version"],
         @phase_id <- map["phase_id"],
         @proof_class <- map["proof_class"],
         true <- map["assertions"] == @assertions,
         true <- valid_digests?(map["subject_digests"]) do
      {:ok,
       struct!(__MODULE__,
         schema_version: @schema_version,
         phase_id: @phase_id,
         proof_class: @proof_class,
         assertions: @assertions,
         subject_digests: map["subject_digests"]
       )}
    else
      _ -> {:error, :invalid_navigation_shell_advisory}
    end
  end

  defp decode_map(_), do: {:error, :invalid_navigation_shell_advisory}

  defp valid_digests?(digests) when is_map(digests) do
    Map.keys(digests) |> MapSet.new() == Map.keys(@subjects) |> MapSet.new() and
      Enum.all?(digests, fn {id, digest} ->
        Map.has_key?(@subjects, id) and is_binary(digest) and
          String.match?(digest, ~r/\A[a-f0-9]{64}\z/)
      end)
  end

  defp valid_digests?(_), do: false

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
end
