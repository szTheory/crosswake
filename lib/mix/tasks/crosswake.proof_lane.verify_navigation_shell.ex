defmodule Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShell do
  use Mix.Task
  import Bitwise

  alias Crosswake.ProofLane.{Evidence, NavigationShellAdvisory}

  @shortdoc "Retains digest-bound advisory navigation-shell evidence"
  @switches [destination: :string, observation: :string, run_root: :string]
  @observation_name "navigation-shell-observation.json"
  @nonce_name ".navigation-shell-run-nonce"

  @impl Mix.Task
  def run(args) do
    {options, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if positional != [] or invalid != [] or
         Enum.any?([:destination, :observation, :run_root], &(not is_binary(options[&1]))) do
      Mix.raise("navigation_shell.invalid_options")
    end

    result =
      with {:ok, observation_bytes} <-
             invocation_observation(options[:run_root], options[:observation]),
           {:ok, advisory} <- NavigationShellAdvisory.build(observation_bytes),
           advisory_bytes = NavigationShellAdvisory.encode!(advisory),
           {:ok, evidence_input} <- evidence_input(advisory_bytes),
           {:ok, evidence} <- Evidence.build(evidence_input),
           :ok <- Evidence.promote(evidence_input, options[:destination]),
           {:ok, after_digests} <- NavigationShellAdvisory.subject_digests(),
           true <- secure_equal?(advisory.subject_digests, after_digests),
           {:ok, retained} <-
             File.read(Path.join(options[:destination], "proof-lane-evidence.json")),
           true <- retained == Jason.encode!(Evidence.to_map(evidence)),
           :ok <- Evidence.scan_stage(options[:destination]),
           :ok <-
             Evidence.check(options[:destination], [
               %{kind: :navigation_shell_advisory, canonical_bytes: advisory_bytes}
             ]) do
        :ok
      else
        _ -> :error
      end

    invalidate(options[:run_root], options[:observation])

    if result != :ok, do: Mix.raise("navigation_shell.verification_failed")
  end

  defp invocation_observation(run_root, observation) do
    with {:ok, root} <- private_directory(run_root),
         {:ok, path} <- contained_regular_file(root, observation, @observation_name),
         {:ok, nonce_path} <-
           contained_regular_file(root, Path.join(root, @nonce_name), @nonce_name),
         {:ok, bytes} <- File.read(path),
         {:ok, observation_map} <- NavigationShellAdvisory.decode_observation(bytes),
         {:ok, nonce} <- File.read(nonce_path),
         true <- nonce == observation_map["run_nonce"] do
      {:ok, bytes}
    else
      _ -> {:error, :invalid_navigation_shell_observation}
    end
  end

  defp private_directory(path) when is_binary(path) do
    expanded = Path.expand(path)

    case File.lstat(expanded) do
      {:ok, %{type: :directory, mode: mode}} when (mode &&& 0o077) == 0 -> {:ok, expanded}
      _ -> {:error, :invalid_navigation_shell_root}
    end
  end

  defp private_directory(_), do: {:error, :invalid_navigation_shell_root}

  defp contained_regular_file(root, path, name) when is_binary(path) do
    expanded = Path.expand(path)

    with true <- Path.dirname(expanded) == root,
         ^name <- Path.basename(expanded),
         {:ok, %{type: :regular}} <- File.lstat(expanded) do
      {:ok, expanded}
    else
      _ -> {:error, :invalid_navigation_shell_observation}
    end
  end

  defp contained_regular_file(_, _, _), do: {:error, :invalid_navigation_shell_observation}

  defp invalidate(root, observation) do
    if is_binary(root) and is_binary(observation) do
      root = Path.expand(root)
      observation = Path.expand(observation)

      if Path.dirname(observation) == root do
        File.rm(observation)
        File.rm(Path.join(root, @nonce_name))
      end
    end
  end

  defp evidence_input(advisory_bytes) do
    {:ok,
     %{
       schema_version: "2",
       crosswake_version: "0.1.0",
       template_version: "161",
       commit_ref: "git-0000000000000000000000000000000000000000",
       route_id: "route-0000000000000000",
       assertion_ids: NavigationShellAdvisory.assertion_ids(),
       status: :passed,
       outcome: :passed,
       captured_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
       retention_label: :brief,
       device_class: :unknown,
       approved_hashes: [%{kind: :navigation_shell_advisory, canonical_bytes: advisory_bytes}]
     }}
  end

  defp secure_equal?(left, right),
    do: :crypto.hash_equals(:erlang.term_to_binary(left), :erlang.term_to_binary(right))
end
