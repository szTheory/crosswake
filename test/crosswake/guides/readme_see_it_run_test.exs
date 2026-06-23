defmodule Crosswake.Guides.ReadmeSeeItRunTest do
  use ExUnit.Case, async: true

  # Guards the README "## See it run" section against drift: the hero command,
  # the montage image (well-formed straight-quote <img>, not smart quotes), the
  # three route owners, source-derived port, the advisory native label, and the
  # forward links to the guide and QUICK_START. UAT 3 — fully automated.

  @readme_path "README.md"
  @guide_path "guides/see_it_run.md"
  @quick_start_path "examples/QUICK_START.md"
  @hero_command "bin/see-it-run.sh"

  @section_heading "## See it run"
  @prev_heading "## What this is not"
  @next_heading "## Choose your path"

  @montage_url "https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/three-runtime-montage.png"
  @legend_anchor "guides/support_matrix.md#support-truth-label-legend"

  # Source-of-truth file — never hardcode the port derived from it.
  @phoenix_config_path "examples/phoenix_host/config/runtime.exs"

  # ---------------------------------------------------------------------------
  # Readability / source-derived sanity
  # ---------------------------------------------------------------------------

  test "source-derived facts are readable" do
    assert phoenix_host_port() =~ ~r/^\d+$/,
           "expected a numeric port from #{@phoenix_config_path}"

    assert File.exists?(@readme_path), "expected #{@readme_path} to exist"
    assert File.exists?(@guide_path), "expected #{@guide_path} to exist"
    assert File.exists?(@quick_start_path), "expected #{@quick_start_path} to exist"
  end

  # ---------------------------------------------------------------------------
  # Main drift guard — [] means the section is in sync with source
  # ---------------------------------------------------------------------------

  test "README See it run section contains source-derived facts" do
    assert_no_drift_failures(scan_section({@readme_path, see_it_run_section()}))
  end

  test "README See it run section sits between What-this-is-not and Choose-your-path" do
    contents = File.read!(@readme_path)
    assert_no_drift_failures(scan_order({@readme_path, contents}))
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity cases — each synthetic mutation MUST trigger a specific
  # failure category, proving the guard is not a no-op (D-21 house idiom).
  # ---------------------------------------------------------------------------

  test "scanner rejects wrong port" do
    section = see_it_run_section()
    port = phoenix_host_port()
    mutated = String.replace(section, "localhost:#{port}", "localhost:4000")

    assert_failure_category(
      scan_section({"synthetic/readme_wrong_port.md", mutated}),
      :wrong_port
    )
  end

  test "scanner rejects missing route" do
    mutated = String.replace(see_it_run_section(), "/bridge-proof", "/nope")

    assert_failure_category(
      scan_section({"synthetic/readme_missing_route.md", mutated}),
      :missing_route
    )
  end

  test "scanner rejects missing native posture label" do
    mutated =
      see_it_run_section()
      |> String.replace(~r/advisory/i, "optional")
      |> String.replace("emulator evidence", "emulator only")

    assert_failure_category(
      scan_section({"synthetic/readme_missing_native_label.md", mutated}),
      :missing_native_label
    )
  end

  test "scanner rejects a broken (smart-quote) montage image tag" do
    # Replace the straight-quote attribute delimiter with a smart quote — the
    # exact regression that silently breaks image rendering in HTML.
    mutated = String.replace(see_it_run_section(), ~s(src="), "src=”")

    assert_failure_category(
      scan_section({"synthetic/readme_broken_image.md", mutated}),
      :broken_image
    )
  end

  test "order scanner rejects the section appearing before What-this-is-not" do
    contents = File.read!(@readme_path)

    mutated =
      contents
      |> String.replace(@section_heading, "@@MOVED@@")
      |> String.replace(@prev_heading, @section_heading <> "\n\nmoved up\n\n" <> @prev_heading)
      |> String.replace("@@MOVED@@", "## removed placeholder")

    assert_failure_category(
      scan_order({"synthetic/readme_out_of_order.md", mutated}),
      :section_out_of_order
    )
  end

  # ---------------------------------------------------------------------------
  # Section scanner — returns a flat list of failures (empty = green)
  # ---------------------------------------------------------------------------

  defp scan_section({path, contents}) do
    port = phoenix_host_port()

    [
      # Hero command
      require_contains(path, contents, @hero_command, :missing_command,
        "section must front the hero command #{@hero_command}"),

      # Source-derived URL — catches stale port
      require_contains(path, contents, "http://localhost:#{port}", :wrong_port,
        "section must reference the source-derived URL http://localhost:#{port}"),

      # Well-formed montage image — straight-quote src delimiter + canonical URL.
      # A smart-quote src=”...” breaks rendering and fails this check.
      require_contains(path, contents, ~s(src="#{@montage_url}"), :broken_image,
        "montage <img> must use a straight-quote src=\"#{@montage_url}\" (no smart quotes)"),

      # Three route owners from router.ex
      require_contains(path, contents, "`/offline`", :missing_route,
        "section must name the /offline route"),
      require_contains(path, contents, "`/bridge-proof`", :missing_route,
        "section must name the /bridge-proof route"),
      require_regex(path, contents, ~r/`\/`\s+—\s+home/, :missing_route,
        "section must name the `/` home route owner"),

      # Honest native posture labels (D-15, D-06)
      require_contains(path, contents, "advisory", :missing_native_label,
        "section must carry the 'advisory' posture word"),
      require_contains(path, contents, "emulator evidence", :missing_native_label,
        "section must use the canonical 'emulator evidence' label"),
      require_contains(path, contents, @legend_anchor, :missing_native_label,
        "advisory blockquote must link to #{@legend_anchor}"),

      # Forward links — never duplicate the guide, link to it
      require_contains(path, contents, @guide_path, :missing_link,
        "section must forward-link to #{@guide_path}"),
      require_contains(path, contents, @quick_start_path, :missing_link,
        "section must forward-link to #{@quick_start_path}")
    ]
    |> List.flatten()
    |> Kernel.++(wrong_port_failures(path, contents, port))
  end

  # ---------------------------------------------------------------------------
  # Order scanner — section must sit between its neighbours
  # ---------------------------------------------------------------------------

  defp scan_order({path, contents}) do
    prev = line_number(contents, @prev_heading)
    section = line_number(contents, @section_heading)
    next = line_number(contents, @next_heading)

    missing =
      [{@prev_heading, prev}, {@section_heading, section}, {@next_heading, next}]
      |> Enum.filter(fn {_h, line} -> is_nil(line) end)
      |> Enum.map(fn {heading, _line} ->
        failure(path, :missing_section, detail: "README must contain heading #{inspect(heading)}")
      end)

    cond do
      missing != [] ->
        missing

      prev < section and section < next ->
        []

      true ->
        [
          failure(path, :section_out_of_order,
            line: section,
            claim: @section_heading,
            detail:
              "#{inspect(@section_heading)} must appear after #{inspect(@prev_heading)} and before #{inspect(@next_heading)}"
          )
        ]
    end
  end

  # Slice the README down to the "## See it run" section (heading → next `## `).
  defp see_it_run_section do
    @readme_path
    |> File.read!()
    |> String.split("\n")
    |> Enum.drop_while(&(not String.starts_with?(&1, @section_heading)))
    |> case do
      [] -> raise "could not find #{@section_heading} in #{@readme_path}"
      [heading | rest] -> [heading | Enum.take_while(rest, &(not String.starts_with?(&1, "## ")))]
    end
    |> Enum.join("\n")
  end

  # ---------------------------------------------------------------------------
  # Source derivation helpers (mirrored per-file — house style per CONTEXT.md)
  # ---------------------------------------------------------------------------

  defp phoenix_host_port do
    @phoenix_config_path
    |> File.read!()
    |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @phoenix_config_path)
  end

  defp source_port!(contents, regex, path) do
    case Regex.run(regex, contents) do
      [_match, port] -> port
      _ -> raise "could not derive port from #{path}"
    end
  end

  # ---------------------------------------------------------------------------
  # Per-file helpers (copied per file — house idiom, not extracted to a module)
  # ---------------------------------------------------------------------------

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle), do: [], else: [failure(path, category, detail: detail)]
  end

  defp require_regex(path, contents, regex, category, detail) do
    if Regex.match?(regex, contents), do: [], else: [failure(path, category, detail: detail)]
  end

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      claim: Keyword.get(opts, :claim),
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn failure ->
      location = if failure.line, do: "#{failure.path}:#{failure.line}", else: failure.path
      claim = (failure.claim || "") |> to_string() |> String.trim()
      claim_suffix = if claim == "", do: "", else: " -- #{claim}"
      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp assert_no_drift_failures(failures) do
    assert failures == [],
           "README See it run drift found:\n" <> format_failures(failures)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end

  defp lines(contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
  end

  defp line_number(contents, needle_or_regex) do
    contents
    |> lines()
    |> Enum.find_value(fn {line, line_number} ->
      cond do
        is_binary(needle_or_regex) and String.contains?(line, needle_or_regex) -> line_number
        is_struct(needle_or_regex, Regex) and Regex.match?(needle_or_regex, line) -> line_number
        true -> nil
      end
    end)
  end

  defp wrong_port_failures(path, contents, expected_port) do
    contents
    |> lines()
    |> Enum.flat_map(fn {line, line_number} ->
      ~r/(?:localhost:|PORT=)(\d+)/
      |> Regex.scan(line)
      |> Enum.reject(fn [_match, port] -> port == expected_port end)
      |> Enum.map(fn [claim, _port] ->
        failure(path, :wrong_port,
          line: line_number,
          claim: claim,
          detail: "expected source-derived port #{expected_port}"
        )
      end)
    end)
  end
end
