defmodule Mix.Tasks.Crosswake.ProofLane.ChimewayNotificationPhysical do
  use Mix.Task

  alias Crosswake.ProofLane.{ChimewayNotificationPhysicalProof, Evidence, PhysicalIphoneContract}

  @shortdoc "Promotes a source-bound Chimeway notification physical proof record"
  @switches [input: :string, destination: :string, ios_runtime_line: :string, json: :boolean]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case run_with(args) do
      {:ok, result} -> Mix.shell().info(Jason.encode!(result))
      {:error, rule_id} -> Mix.raise(rule_id)
    end
  end

  @doc false
  def run_with(args) do
    with {options, [], []} <- OptionParser.parse(args, strict: @switches),
         true <- options[:json] == true,
         input when is_binary(input) <- options[:input],
         destination when is_binary(destination) <- options[:destination],
         runtime when is_binary(runtime) <- options[:ios_runtime_line],
         {:ok, runtime} <- PhysicalIphoneContract.ios_runtime_line(runtime),
         {:ok, candidate} <- read_candidate(input),
         {:ok, report} <- report(candidate),
         :ok <- ChimewayNotificationPhysicalProof.validate_report(report),
         {:ok, sha} <- clean_revision(),
         canonical_bytes <- canonical_bytes(report, runtime),
         evidence_input <- evidence_input(candidate, report, runtime, sha, canonical_bytes),
         :ok <- Evidence.promote(evidence_input, destination),
         :ok <- ChimewayNotificationPhysicalProof.validate_source_bound(report, destination),
         {:ok, result} <- safe_result(candidate, report, sha, destination) do
      {:ok, result}
    else
      {:error, rule_id} when is_binary(rule_id) -> {:error, rule_id}
      {:error, %Evidence.Error{rule_id: rule_id}} -> {:error, rule_id}
      _ -> {:error, "CW-NOTIFICATION-PHYSICAL-OPTIONS"}
    end
  end

  defp read_candidate(path) do
    with true <- Path.type(path) == :absolute,
         {:ok, bytes} <- File.read(path),
         true <- byte_size(bytes) <= 8_192,
         {:ok, candidate} <- Jason.decode(bytes),
         true <-
           Map.keys(candidate) |> Enum.sort() ==
             ~w(assertions chimeway_facts device_class outcome run_ref schema_version) do
      {:ok, candidate}
    else
      _ -> {:error, "CW-NOTIFICATION-PHYSICAL-INPUT"}
    end
  end

  defp report(%{
         "schema_version" => 1,
         "device_class" => "physical_iphone",
         "outcome" => "passed",
         "assertions" => assertions,
         "chimeway_facts" => %{
           "delivery_succeeded" => "passed",
           "apns_provider_accepted" => "passed",
           "trace_explainable" => "passed"
         }
       })
       when is_list(assertions) do
    parsed =
      Enum.map(assertions, fn
        %{"id" => id, "owner" => owner, "outcome" => outcome} = entry
        when map_size(entry) == 3 ->
          with {:ok, owner} <- existing_atom(owner),
               {:ok, outcome} <- existing_atom(outcome) do
            %{id: id, owner: owner, outcome: outcome}
          else
            _ -> :invalid
          end

        _ ->
          :invalid
      end)

    if Enum.any?(parsed, &(&1 == :invalid)),
      do: {:error, "CW-NOTIFICATION-PHYSICAL-REPORT"},
      else: {:ok, parsed}
  end

  defp report(_), do: {:error, "CW-NOTIFICATION-PHYSICAL-REPORT"}

  defp existing_atom(value) when is_binary(value) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ -> :error
  end

  defp existing_atom(_), do: :error

  defp clean_revision do
    with {sha, 0} <- System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true),
         sha <- String.trim(sha),
         true <- Regex.match?(~r/\A[0-9a-f]{40}\z/, sha),
         {status, 0} <- System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true),
         true <- status == "" do
      {:ok, sha}
    else
      _ -> {:error, "CW-NOTIFICATION-PHYSICAL-REVISION"}
    end
  end

  defp canonical_bytes(report, runtime) do
    Jason.encode!(%{
      "schema_version" => 1,
      "device_class" => "physical_iphone",
      "ios_runtime_line" => runtime,
      "outcome" => "passed",
      "assertions" =>
        Enum.map(report, fn entry ->
          %{
            "id" => entry.id,
            "owner" => Atom.to_string(entry.owner),
            "outcome" => Atom.to_string(entry.outcome)
          }
        end)
    })
  end

  defp evidence_input(candidate, report, runtime, sha, canonical_bytes) do
    route_digest = :crypto.hash(:sha256, candidate["run_ref"]) |> Base.encode16(case: :lower)

    %{
      schema_version: "1",
      crosswake_version: Mix.Project.config()[:version],
      template_version: "1",
      commit_ref: "git-" <> sha,
      route_id: "route-" <> binary_part(route_digest, 0, 16),
      assertion_ids: Enum.map(report, & &1.id),
      status: :passed,
      outcome: :passed,
      captured_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      retention_label: :brief,
      device_class: :physical_iphone,
      ios_runtime_line: runtime,
      approved_hashes: [
        %{kind: :chimeway_notification_run_contract, canonical_bytes: canonical_bytes}
      ]
    }
  end

  defp safe_result(candidate, report, sha, destination) do
    with {:ok, evidence_sha256} <- digest_file(Path.join(destination, "proof-lane-evidence.json")),
         {:ok, completion_marker_sha256} <- digest_file(Path.join(destination, ".complete")) do
      {:ok,
       %{
         schema_version: 1,
         owner: "crosswake",
         outcome: "passed",
         run_ref: candidate["run_ref"],
         crosswake_sha: sha,
         evidence_sha256: evidence_sha256,
         completion_marker_sha256: completion_marker_sha256,
         assertions:
           Enum.map(report, fn entry ->
             %{
               id: entry.id,
               owner: Atom.to_string(entry.owner),
               outcome: Atom.to_string(entry.outcome)
             }
           end)
       }}
    end
  end

  defp digest_file(path) do
    case File.read(path) do
      {:ok, bytes} -> {:ok, :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)}
      _ -> {:error, "CW-NOTIFICATION-PHYSICAL-EVIDENCE"}
    end
  end
end
