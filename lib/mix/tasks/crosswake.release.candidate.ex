defmodule Mix.Tasks.Crosswake.Release.Candidate do
  use Mix.Task

  @shortdoc "Evaluate an exact Crosswake release candidate"

  @moduledoc """
  Evaluates one exact Crosswake candidate and writes its authoritative receipt from named evidence.

      mix crosswake.release.candidate --version <semver> --ref <40sha> \
        --evidence-dir <dir> --output-dir <dir> --ci-run-id <id> --hex-run-id <id> \
        --ios-run-id <id> --maven-run-id <id>

  The command accepts run selectors, never caller-provided receipt JSON or receipt bytes.
  """

  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @output_options ~w(version ref output_dir)a

  @impl Mix.Task
  def run(args), do: run(args, [])

  @doc false
  def run(args, task_opts) do
    parsed = parse!(args)

    candidate_opts = Keyword.get(task_opts, :candidate_opts)

    run_opts =
      case parsed do
        %{evidence_dir: evidence_dir} = options ->
          selectors =
            Map.take(options, [
              :version,
              :ref,
              :ci_run_id,
              :hex_run_id,
              :ios_run_id,
              :maven_run_id
            ])

          [
            version: options.version,
            ref: options.ref,
            output_dir: options.output_dir,
            input_adapter: fn ->
              Crosswake.ReleaseCandidate.EvidenceInput.load!(evidence_dir,
                version: selectors.version,
                ref: selectors.ref,
                ci_run_id: selectors.ci_run_id,
                hex_run_id: selectors.hex_run_id,
                ios_run_id: selectors.ios_run_id,
                maven_run_id: selectors.maven_run_id
              )
            end
          ]

        options when is_list(candidate_opts) ->
          Keyword.merge(options, candidate_opts)

        _options ->
          Mix.raise("invalid release candidate command")
      end

    result = Crosswake.ReleaseCandidate.run!(run_opts)
    Mix.shell().info(result.terminal)

    if Crosswake.ReleaseCandidate.exit_code(result.receipt) != 0 do
      Mix.raise("release candidate is #{result.receipt.state}")
    end

    result
  end

  defp parse!(args) when is_list(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [
          version: :string,
          ref: :string,
          output_dir: :string,
          evidence_dir: :string,
          ci_run_id: :string,
          hex_run_id: :string,
          ios_run_id: :string,
          maven_run_id: :string
        ]
      )

    keys = Keyword.keys(opts)

    evidence_options =
      @output_options ++ ~w(evidence_dir ci_run_id hex_run_id ios_run_id maven_run_id)a

    valid? =
      invalid == [] and argv == [] and Enum.uniq(keys) == keys and
        Enum.sort(keys) == Enum.sort(evidence_options) and
        exact_option_counts?(args, evidence_options)

    if valid? do
      base = %{
        version: opts[:version],
        ref: opts[:ref],
        output_dir: opts[:output_dir],
        evidence_dir: opts[:evidence_dir]
      }

      Map.merge(
        base,
        Map.new(~w(ci hex ios maven)a, fn kind ->
          key = String.to_atom("#{kind}_run_id")
          {key, positive_run_id!(Keyword.fetch!(opts, key))}
        end)
      )
      |> validate_identity!()
    else
      legacy_valid? =
        invalid == [] and argv == [] and Enum.uniq(keys) == keys and
          Enum.sort(keys) == Enum.sort(@output_options) and
          exact_option_counts?(args, @output_options) and valid_base_options?(opts)

      if legacy_valid? do
        Keyword.take(opts, @output_options)
      else
        Mix.raise("invalid release candidate command")
      end
    end
  end

  defp parse!(_args), do: Mix.raise("invalid release candidate command")

  defp exact_option_counts?(args, keys) do
    Enum.all?(keys, fn key ->
      option = "--" <> String.replace(Atom.to_string(key), "_", "-")
      Enum.count(args, &(&1 == option)) == 1
    end)
  end

  defp valid_base_options?(opts) do
    is_binary(opts[:version]) and Regex.match?(@version_pattern, opts[:version]) and
      is_binary(opts[:ref]) and Regex.match?(@sha_pattern, opts[:ref]) and
      is_binary(opts[:output_dir]) and opts[:output_dir] != "" and
      not String.contains?(opts[:output_dir], <<0>>)
  end

  defp validate_identity!(options) do
    unless valid_base_options?(options) and is_binary(options.evidence_dir) and
             options.evidence_dir != "" and not String.contains?(options.evidence_dir, <<0>>),
           do: Mix.raise("invalid release candidate command")

    options
  end

  defp positive_run_id!(value) do
    case Integer.parse(value) do
      {run_id, ""} when run_id > 0 -> run_id
      _ -> Mix.raise("invalid release candidate command")
    end
  end
end
