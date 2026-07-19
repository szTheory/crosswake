defmodule Crosswake.Guides.SeeItRunTest do
  use ExUnit.Case, async: true

  # The guide this test guards against drift.
  @target_path "guides/see_it_run.md"

  # Forward-link targets the guide must reference.
  @quick_start_path "examples/QUICK_START.md"
  @hero_command_path "bin/see-it-run.sh"

  # Source-of-truth files — never hardcode values derived from these.
  @phoenix_config_path "examples/phoenix_host/config/runtime.exs"
  @router_path "examples/phoenix_host/lib/crosswake_example/router.ex"

  # D-08 JTBD sections — the guide must carry these seven `##` headings in order.
  @jtbd_sections [
    "## What You'll See",
    "## Run It Now (Zero Toolchain)",
    "## Browse the Route Owners",
    "## Compare All Three Runtimes (Web, iOS, Android)",
    "## Wire a Native Runtime to the Local Backend",
    "## What This Proves (And What It Doesn't)",
    "## Go Deeper"
  ]

  # Gameplan blockquote opener — the orientation hook above the first heading.
  @gameplan_opener "> Boot Crosswake once."

  # ---------------------------------------------------------------------------
  # Readability / source-derived sanity
  # ---------------------------------------------------------------------------

  test "source-derived facts are readable" do
    assert phoenix_host_port() =~ ~r/^\d+$/,
           "expected a numeric port from #{@phoenix_config_path}"

    assert File.exists?(@target_path),
           "expected #{@target_path} to exist"

    assert File.exists?(@quick_start_path),
           "expected #{@quick_start_path} to exist"

    assert File.exists?(@hero_command_path),
           "expected #{@hero_command_path} to exist"

    assert File.exists?(@router_path),
           "expected #{@router_path} to exist (canonical route source)"
  end

  # ---------------------------------------------------------------------------
  # Main drift guard — returns [] means the guide is in sync with source
  # ---------------------------------------------------------------------------

  test "guide contains source-derived facts" do
    guide = {
      @target_path,
      File.read!(@target_path)
    }

    assert_no_drift_failures(scan_guide(guide))
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity cases — each synthetic mutation MUST trigger a specific
  # failure category, proving the guard is not a no-op (D-21 house idiom).
  # ---------------------------------------------------------------------------

  test "scanner rejects wrong port" do
    guide = File.read!(@target_path)
    port = phoenix_host_port()

    mutated = String.replace(guide, "localhost:#{port}", "localhost:4000")

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_wrong_port.md", mutated}),
      :wrong_port
    )
  end

  test "scanner rejects missing route" do
    guide = File.read!(@target_path)

    mutated = String.replace(guide, "/bridge-proof", "/nope")

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_route.md", mutated}),
      :missing_route
    )
  end

  test "scanner rejects missing native posture label" do
    guide = File.read!(@target_path)

    mutated =
      guide
      |> String.replace(~r/advisory/i, "optional")
      |> String.replace("emulator evidence", "emulator only")

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_native_label.md", mutated}),
      :missing_native_label
    )
  end

  test "scanner rejects missing showcase-first proof-secondary copy" do
    guide = File.read!(@target_path)

    missing_showcase = String.replace(guide, ~r/showcase/i, "home")

    missing_proof_secondary =
      String.replace(guide, "Proof routes stay one click deeper", "Proof commands are primary")

    missing_support_truth = String.replace(guide, ~r/support-truth/i, "support status")

    missing_collateral =
      String.replace(
        guide,
        ~r/route-tour assertions prove\s+route-owner semantics/i,
        "screenshots prove everything"
      )

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_showcase.md", missing_showcase}),
      :missing_showcase_first
    )

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_proof_secondary.md", missing_proof_secondary}),
      :missing_proof_secondary
    )

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_support_truth.md", missing_support_truth}),
      :missing_support_truth
    )

    assert_failure_category(
      scan_guide({"synthetic/see_it_run_missing_collateral_boundary.md", missing_collateral}),
      :missing_collateral_boundary
    )
  end

  # ---------------------------------------------------------------------------
  # Structure guard — gameplan blockquote + 7 JTBD sections in order
  # ---------------------------------------------------------------------------

  test "guide carries the gameplan blockquote and 7 JTBD sections in order" do
    contents = File.read!(@target_path)
    assert_no_drift_failures(scan_structure({@target_path, contents}))
  end

  test "structure scanner rejects a missing JTBD section" do
    contents = File.read!(@target_path)
    mutated = String.replace(contents, "## Go Deeper", "## Somewhere Else")

    assert_failure_category(
      scan_structure({"synthetic/see_it_run_missing_section.md", mutated}),
      :missing_section
    )
  end

  test "structure scanner rejects out-of-order JTBD sections" do
    contents = File.read!(@target_path)

    # Swap the first and last section headings to break the canonical order.
    mutated =
      contents
      |> String.replace("## What You'll See", "@@FIRST@@")
      |> String.replace("## Go Deeper", "## What You'll See")
      |> String.replace("@@FIRST@@", "## Go Deeper")

    assert_failure_category(
      scan_structure({"synthetic/see_it_run_out_of_order.md", mutated}),
      :section_out_of_order
    )
  end

  test "structure scanner rejects a missing gameplan blockquote" do
    contents = File.read!(@target_path)
    mutated = String.replace(contents, @gameplan_opener, "> Something else entirely.")

    assert_failure_category(
      scan_structure({"synthetic/see_it_run_missing_gameplan.md", mutated}),
      :missing_gameplan
    )
  end

  # ---------------------------------------------------------------------------
  # ExDoc registration — the guide must be item 2 (after README) in both the
  # extras list and the Start group, sourced from mix.exs (never hardcoded).
  # ---------------------------------------------------------------------------

  test "guide is registered as item 2 in ExDoc extras and Start group" do
    docs = Crosswake.MixProject.project()[:docs]
    extras = docs[:extras]
    start_group = docs[:groups_for_extras][:Start]

    assert Enum.at(extras, 0) == "README.md",
           "expected README.md as the first ExDoc extra"

    assert Enum.at(extras, 1) == @target_path,
           "expected #{@target_path} as ExDoc extra item 2 (after README), got #{inspect(Enum.at(extras, 1))}"

    assert Enum.at(start_group, 0) == "README.md",
           "expected README.md first in the Start group"

    assert Enum.at(start_group, 1) == @target_path,
           "expected #{@target_path} as Start-group item 2 (after README), got #{inspect(Enum.at(start_group, 1))}"
  end

  # ---------------------------------------------------------------------------
  # Guide scanner — returns a flat list of failures (empty = green)
  # ---------------------------------------------------------------------------

  defp scan_guide({path, contents}) do
    port = phoenix_host_port()

    [
      # Source-derived URL — catches stale port.
      # D-18: deriving port from runtime.exs is shared-source, not forbidden duplication.
      require_contains(
        path,
        contents,
        "http://localhost:#{port}",
        :wrong_port,
        "guide must contain the source-derived URL http://localhost:#{port}"
      ),
      require_regex(
        path,
        contents,
        ~r/\bshowcase hub\b[\s\S]{0,220}http:\/\/localhost:#{port}\/|http:\/\/localhost:#{port}\/[\s\S]{0,220}\bshowcase hub\b/i,
        :missing_showcase_first,
        "guide must describe http://localhost:#{port}/ as the showcase hub"
      ),
      require_regex(
        path,
        contents,
        ~r/Proof routes? (?:stay|remain|are|sit)[\s\S]{0,120}(?:one click deeper|secondary)|secondary proof routes?/i,
        :missing_proof_secondary,
        "guide must keep proof routes secondary to the showcase"
      ),
      require_regex(
        path,
        contents,
        ~r/support-truth[\s\S]{0,220}(?:Available today|Proof-backed example|Demo pressure|Future gap)|(?:Available today|Proof-backed example|Demo pressure|Future gap)[\s\S]{0,220}support-truth/i,
        :missing_support_truth,
        "guide must retain support-truth labels and non-claim posture"
      ),
      require_regex(
        path,
        contents,
        ~r/screenshots?[\s\S]{0,260}product surface[\s\S]{0,260}route-tour assertions?[\s\S]{0,260}route-owner semantics|route-tour assertions?[\s\S]{0,260}route-owner semantics[\s\S]{0,260}screenshots?[\s\S]{0,260}product surface/i,
        :missing_collateral_boundary,
        "guide must separate product screenshots from route-owner semantics proof"
      ),

      # Route names from router.ex
      require_contains(
        path,
        contents,
        "/offline",
        :missing_route,
        "guide must name the /offline route"
      ),
      require_contains(
        path,
        contents,
        "/bridge-proof",
        :missing_route,
        "guide must name the /bridge-proof route"
      ),

      # Hero command
      require_contains(
        path,
        contents,
        "bin/see-it-run.sh",
        :missing_command,
        "guide must reference the hero command bin/see-it-run.sh"
      ),
      require_contains(
        path,
        contents,
        "docker compose",
        :missing_command,
        "guide must mention docker compose as the zero-toolchain path"
      ),

      # Forward link to QUICK_START (must link, never duplicate commands)
      require_contains(
        path,
        contents,
        "examples/QUICK_START.md",
        :missing_path,
        "guide must link forward to examples/QUICK_START.md"
      ),

      # Honest native posture labels (D-15, D-06)
      # Note: sharing advisory/simulator/emulator with see_it_run_banner_test.exs is
      # correct — both guard the same honesty contract. D-18 prohibits only asserting
      # the same banner command-literal strings in both files; posture words are shared.
      require_contains(
        path,
        contents,
        "advisory",
        :missing_native_label,
        "guide must carry the 'advisory' posture word"
      ),
      require_contains(
        path,
        contents,
        "simulator",
        :missing_native_label,
        "guide must carry the 'simulator' posture word"
      ),
      require_contains(
        path,
        contents,
        "emulator",
        :missing_native_label,
        "guide must carry the 'emulator' posture word"
      ),

      # Canonical emulator-evidence label (D-15)
      require_contains(
        path,
        contents,
        "emulator evidence",
        :missing_native_label,
        "guide must use the canonical 'emulator evidence' label per support_matrix.md legend"
      ),

      # Support-matrix legend anchor — the D-15 sentence must link to the legend
      require_regex(
        path,
        contents,
        ~r/support_matrix\.md#support-truth-label-legend/,
        :missing_native_label,
        "guide must link to support_matrix.md#support-truth-label-legend for the emulator-evidence term"
      )
    ]
    |> List.flatten()
    |> Kernel.++(documented_path_failures(path, contents))
    |> Kernel.++(wrong_port_failures(path, contents, port))
  end

  # ---------------------------------------------------------------------------
  # Structure scanner — gameplan opener present + 7 JTBD sections in order
  # ---------------------------------------------------------------------------

  defp scan_structure({path, contents}) do
    gameplan =
      require_contains(
        path,
        contents,
        @gameplan_opener,
        :missing_gameplan,
        "guide must open with the gameplan blockquote (#{@gameplan_opener})"
      )

    present =
      Enum.flat_map(@jtbd_sections, fn section ->
        require_contains(
          path,
          contents,
          section,
          :missing_section,
          "guide must carry the JTBD section heading #{inspect(section)}"
        )
      end)

    [gameplan, present, section_order_failures(path, contents)]
    |> List.flatten()
  end

  # Each present section heading must appear in canonical order. Missing sections
  # are reported by :missing_section above and skipped here so we only flag a true
  # ordering violation, never a duplicate of an absence.
  defp section_order_failures(path, contents) do
    located =
      @jtbd_sections
      |> Enum.map(fn section -> {section, line_number(contents, section)} end)
      |> Enum.reject(fn {_section, line} -> is_nil(line) end)

    lines_only = Enum.map(located, fn {_section, line} -> line end)

    if lines_only == Enum.sort(lines_only) do
      []
    else
      out_of_order =
        located
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.filter(fn [{_a, la}, {_b, lb}] -> la > lb end)
        |> Enum.map(fn [{_a, _la}, {section_b, line_b}] ->
          failure(path, :section_out_of_order,
            line: line_b,
            claim: section_b,
            detail: "JTBD section #{inspect(section_b)} appears out of canonical order"
          )
        end)

      out_of_order
    end
  end

  # ---------------------------------------------------------------------------
  # Source derivation helpers (mirrored per-file — house style per CONTEXT.md)
  # ---------------------------------------------------------------------------

  # Derives the demo port from the phoenix_host runtime config.
  # Regex: System.get_env("PORT") || "NNNN" — never hardcode 4700 here.
  defp phoenix_host_port do
    @phoenix_config_path
    |> File.read!()
    |> source_port!(
      ~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/,
      @phoenix_config_path
    )
  end

  # Shared extraction utility — also used by quick_start_adoption_drift_test.exs
  # and see_it_run_banner_test.exs. Shared derivation from a common source is
  # correct (D-18); the prohibition is only on asserting banner command-literal
  # strings in both test files simultaneously.
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
    if String.contains?(contents, needle) do
      []
    else
      [failure(path, category, detail: detail)]
    end
  end

  defp require_regex(path, contents, regex, category, detail) do
    if Regex.match?(regex, contents) do
      []
    else
      [failure(path, category, detail: detail)]
    end
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
      location =
        if failure.line do
          "#{failure.path}:#{failure.line}"
        else
          failure.path
        end

      claim =
        (failure.claim || "")
        |> to_string()
        |> String.trim()

      claim_suffix = if claim == "", do: "", else: " -- #{claim}"

      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp assert_no_drift_failures(failures) do
    assert failures == [],
           "see_it_run guide drift found:\n" <> format_failures(failures)
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

  # Extends the quick_start_adoption prefix regex to also match bin/ and guides/
  # paths so documented_path_failures catches broken links to any repo path.
  defp documented_paths(contents) do
    ~r/(?:examples|script|bin|guides)\/[A-Za-z0-9_.\/-]+/
    |> Regex.scan(contents)
    |> Enum.map(fn [path] -> String.trim_trailing(path, ".,);:`]") end)
    |> Enum.reject(&String.ends_with?(&1, "/"))
    |> Enum.uniq()
  end

  defp documented_path_failures(doc_path, contents) do
    contents
    |> documented_paths()
    |> Enum.reject(&File.exists?/1)
    |> Enum.map(fn missing_path ->
      failure(doc_path, :missing_path,
        line: line_number(contents, missing_path),
        claim: missing_path,
        detail: "documented repo path does not exist"
      )
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
