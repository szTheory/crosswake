defmodule Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShell do
  use Mix.Task

  alias Crosswake.ProofLane.{Evidence, NavigationShellAdvisory}

  @shortdoc "Retains digest-bound advisory navigation-shell evidence"
  @switches [destination: :string]

  @impl Mix.Task
  def run(args) do
    {options, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if positional != [] or invalid != [] or not is_binary(options[:destination]) do
      Mix.raise("navigation_shell.invalid_options")
    end

    with {:ok, advisory} <- NavigationShellAdvisory.build(),
         advisory_bytes = NavigationShellAdvisory.encode!(advisory),
         {:ok, evidence_input} <- evidence_input(advisory_bytes),
         {:ok, evidence} <- Evidence.build(evidence_input),
         :ok <- Evidence.promote(evidence_input, options[:destination]),
         {:ok, after_advisory} <- NavigationShellAdvisory.build(),
         true <- secure_equal?(advisory.subject_digests, after_advisory.subject_digests),
         {:ok, retained} <-
           File.read(Path.join(options[:destination], "proof-lane-evidence.json")),
         true <- retained == Jason.encode!(Evidence.to_map(evidence)),
         :ok <- Evidence.scan_stage(options[:destination]),
         :ok <-
           Evidence.check(options[:destination], [
             %{
               kind: :navigation_shell_advisory,
               canonical_bytes: NavigationShellAdvisory.encode!(after_advisory)
             }
           ]) do
      :ok
    else
      _ -> Mix.raise("navigation_shell.verification_failed")
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
       assertion_ids:
         ~w(PL-IOS-NAV-TOPOLOGY PL-IOS-NAV-PATCH-DEPTH PL-IOS-NAV-NAVIGATE-ONCE PL-IOS-NAV-RESTORE PL-IOS-NAV-TABS-BACK PL-IOS-NAV-MARKER-INSETS PL-IOS-NAV-FOCUS),
       status: :passed,
       outcome: :passed,
       captured_at: "2026-08-04T00:00:00Z",
       retention_label: :brief,
       device_class: :unknown,
       approved_hashes: [%{kind: :navigation_shell_advisory, canonical_bytes: advisory_bytes}]
     }}
  end

  defp secure_equal?(left, right) do
    :crypto.hash_equals(:erlang.term_to_binary(left), :erlang.term_to_binary(right))
  end
end
