defmodule Crosswake.ProofLane.NavigationShellAdvisory do
  @moduledoc false

  @schema_version 1
  @phase_id "161.1"
  @proof_class "advisory"
  @assertion_ids ~w(PL-IOS-NAV-TOPOLOGY PL-IOS-NAV-PATCH-DEPTH PL-IOS-NAV-NAVIGATE-ONCE PL-IOS-NAV-RESTORE PL-IOS-NAV-TABS-BACK PL-IOS-NAV-MARKER-INSETS PL-IOS-NAV-FOCUS)
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
  @enforce_keys [
    :schema_version,
    :phase_id,
    :proof_class,
    :assertions,
    :observation_digest,
    :subject_digests
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  def assertion_ids, do: @assertion_ids

  def build(observation_bytes) when is_binary(observation_bytes) do
    with {:ok, observation} <- decode_observation(observation_bytes),
         {:ok, digests} <- subject_digests() do
      {:ok,
       %__MODULE__{
         schema_version: @schema_version,
         phase_id: @phase_id,
         proof_class: @proof_class,
         assertions: passed_assertions(observation["assertion_ids"]),
         observation_digest: sha256(observation_bytes),
         subject_digests: digests
       }}
    end
  end

  def build(_), do: {:error, :invalid_navigation_shell_advisory}

  def decode_observation(bytes) when is_binary(bytes) do
    with {:ok, map} <- Jason.decode(bytes),
         true <- Jason.encode!(map) == bytes,
         true <-
           Map.keys(map) |> MapSet.new() ==
             MapSet.new(~w(assertion_ids outcome run_nonce schema_version scope)),
         @schema_version <- map["schema_version"],
         "advisory" <- map["scope"],
         "passed" <- map["outcome"],
         @assertion_ids <- map["assertion_ids"],
         true <- valid_nonce?(map["run_nonce"]) do
      {:ok, map}
    else
      _ -> {:error, :invalid_navigation_shell_observation}
    end
  end

  def decode_observation(_), do: {:error, :invalid_navigation_shell_observation}

  def to_map(%__MODULE__{} = advisory) do
    %{
      "assertions" => advisory.assertions,
      "observation_digest" => advisory.observation_digest,
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
             MapSet.new(
               ~w(assertions observation_digest phase_id proof_class schema_version subject_digests)
             ),
         @schema_version <- map["schema_version"],
         @phase_id <- map["phase_id"],
         @proof_class <- map["proof_class"],
         true <- valid_assertions?(map["assertions"]),
         true <- valid_digest?(map["observation_digest"]),
         true <- valid_digests?(map["subject_digests"]) do
      {:ok,
       struct!(__MODULE__,
         schema_version: @schema_version,
         phase_id: @phase_id,
         proof_class: @proof_class,
         assertions: map["assertions"],
         observation_digest: map["observation_digest"],
         subject_digests: map["subject_digests"]
       )}
    else
      _ -> {:error, :invalid_navigation_shell_advisory}
    end
  end

  defp decode_map(_), do: {:error, :invalid_navigation_shell_advisory}

  defp passed_assertions(ids), do: Map.new(ids, &{&1, "passed"})

  defp valid_assertions?(assertions) when is_map(assertions) do
    Map.keys(assertions) |> MapSet.new() == MapSet.new(@assertion_ids) and
      Enum.all?(assertions, fn {_id, outcome} -> outcome == "passed" end)
  end

  defp valid_assertions?(_), do: false

  defp valid_digests?(digests) when is_map(digests) do
    Map.keys(digests) |> MapSet.new() == Map.keys(@subjects) |> MapSet.new() and
      Enum.all?(digests, fn {id, digest} ->
        Map.has_key?(@subjects, id) and valid_digest?(digest)
      end)
  end

  defp valid_digests?(_), do: false
  defp valid_nonce?(nonce), do: valid_digest?(nonce)

  defp valid_digest?(digest),
    do: is_binary(digest) and String.match?(digest, ~r/\A[a-f0-9]{64}\z/)

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
end
