defmodule Mix.Tasks.Crosswake.BumpTemplateVersion do
  use Mix.Task

  @shortdoc "Increment @template_version and recompute the drift test hash"

  @moduledoc """
  Maintainer task: increments the integer `@template_version` in
  `lib/mix/tasks/crosswake.gen.shell.ex` AND recomputes and rewrites
  `@checked_in_hash` in `test/crosswake/proof/phase134_template_version_drift_test.exs`.

  Run this whenever any `.eex` shell template changes. Both edits happen atomically
  in a single invocation — never bump the integer without rewriting the hash, or
  vice versa (D-05, pitfall 7).

  ## Usage

      mix crosswake.bump_template_version

  No arguments are accepted.

  ## How it works

  1. Reads `lib/mix/tasks/crosswake.gen.shell.ex`, finds the `@template_version N`
     line, and replaces it with `@template_version N+1`.
  2. Recomputes the SHA-256 over the sorted `.eex` template glob —
     exactly the same algorithm as `live_template_hash/0` in the drift test
     (`priv/templates/crosswake/shell/**/*.eex`, sorted, concatenated, SHA-256,
     lowercase hex) so the hash matches byte-for-byte.
  3. Reads `test/crosswake/proof/phase134_template_version_drift_test.exs`, finds
     the `@checked_in_hash "..."` literal on its own line, and replaces the quoted
     value with the new hash.
  """

  @gen_shell_path "lib/mix/tasks/crosswake.gen.shell.ex"
  @drift_test_path "test/crosswake/proof/phase134_template_version_drift_test.exs"
  @template_glob "priv/templates/crosswake/shell/**/*.eex"

  @impl Mix.Task
  def run(_args) do
    root = File.cwd!()
    gen_shell_file = Path.join(root, @gen_shell_path)
    drift_test_file = Path.join(root, @drift_test_path)

    # Step 1: Read gen.shell.ex, find @template_version N, write N+1.
    gen_shell_contents = File.read!(gen_shell_file)

    {current_version, bumped_contents} =
      case Regex.run(~r/@template_version\s+(\d+)/, gen_shell_contents) do
        [full_match, version_str] ->
          current = String.to_integer(version_str)
          bumped = current + 1

          updated =
            String.replace(
              gen_shell_contents,
              full_match,
              "@template_version #{bumped}"
            )

          {current, updated}

        nil ->
          Mix.raise(
            "[crosswake] could not find @template_version integer in #{@gen_shell_path}. " <>
              "Expected a line like: @template_version 1"
          )
      end

    File.write!(gen_shell_file, bumped_contents)
    new_version = current_version + 1

    # Step 2: Recompute SHA-256 over sorted .eex templates.
    # This MUST be byte-for-byte identical to live_template_hash/0 in the drift test.
    new_hash =
      Path.join(root, @template_glob)
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(&File.read!/1)
      |> Enum.join()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    # Step 3: Read drift test, replace @checked_in_hash "..." with new hash.
    drift_test_contents = File.read!(drift_test_file)

    updated_drift_test =
      Regex.replace(
        ~r/@checked_in_hash "[0-9a-f]*"/,
        drift_test_contents,
        "@checked_in_hash \"#{new_hash}\""
      )

    if updated_drift_test == drift_test_contents do
      Mix.raise(
        "[crosswake] could not find @checked_in_hash line in #{@drift_test_path}. " <>
          "Expected a line like: @checked_in_hash \"0000...0000\""
      )
    end

    File.write!(drift_test_file, updated_drift_test)

    Mix.shell().info(
      "[crosswake] bumped template_version to #{new_version}; drift hash updated to #{new_hash}."
    )
  end
end
