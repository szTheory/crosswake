#!/usr/bin/env elixir

# Guards against one recurring defect class: a check that keeps running, keeps
# reporting success, and has stopped asserting anything.
#
# The v22.0 retrospective found this shape five independent times — publication
# jobs that skip on a version mismatch and report nothing; `mix test path:63`
# against a test that had moved to :65, printing "0 tests, 0 failures" and
# EXITING 0; a negative control whose mutation silently did nothing; a test
# branch that had never executed; and a receipt comparison that was one refactor
# away from becoming permanently, vacuously true.
#
# None of those failed. Four of the five were green for months. The common
# property is that ABSENCE — of a match, of a mutation, of a file, of an
# executed branch — was scored as SUCCESS.
#
# This scanner encodes the two instances that can be detected statically with no
# false positives. It is deliberately narrow: a noisy guard gets waived, and a
# waived guard is worth less than no guard, because it also teaches people that
# red is negotiable.

Code.require_file("absence_collection_ast.exs", __DIR__)

defmodule Crosswake.AbsenceIsNotSuccess do
  @moduledoc false

  @mutation_hint """
  A mutation-based negative control must assert that its mutation CHANGED
  something. Checking only that the pattern matched before replacing is not
  enough: a replacement can match and still produce identical output.

  That is a real bug this repository shipped. In phase168_release_version_weld_test
  the replacement "\\\\1" <> "0.9.9" was read by Regex.replace as capture group 10,
  not group 1 followed by a version. The regex matched, the replace ran, the
  output was unchanged, and the control asserted that an UNMUTATED file still
  passed — reporting success for the opposite of what it claimed to test.

  Compare the result against its source and fail loudly when they are equal.
  """

  @citation_hint """
  A `file.exs:LINE` citation in an OPEN finding must point at a real test.

  When a test moves, the citation goes stale silently: `mix test path:63` against
  a line that no longer holds a test prints "0 tests, 0 failures" and EXITS 0. It
  reads as a pass. Six items in Phase 121 were carried as known failures for
  months on citations like this; when finally re-run, every one passed, and one
  cited a line that matched no test at all.

  Update the line, or mark the entry `status: resolved` if it no longer applies.
  Entries already marked resolved are skipped: those are historical records, and
  a record is allowed to describe where something used to be.
  """

  # Every scope the checker reads, as literal {label, glob, min}. A scope that is
  # empty, narrower than an independent walk, or below its min fails closed (exit
  # 1) before any content check runs, so a green result means files were examined.
  #
  # The test-files min is a minimum measured at the phase's final commit: adding
  # files never goes red, removing files is the reviewed event (lower the entry in
  # the same change and say why). Adding 50 files and deleting 50 others stays
  # green: a known limit. The pin is raised at each landing to a count measured by
  # a separate command at that commit, never from this script's own glob.
  # --min-test-files N replaces only the test-files min (for fixtures); nothing
  # ratchets automatically and nothing rewrites a pin.
  @scopes [
    {"test-files", "test/**/*.exs", 253},
    {"todos", ".planning/todos/*.md", 1},
    {"seeds", ".planning/seeds/*.md", 1},
    {"deferred-items", ".planning/**/deferred-items.md", 1}
  ]

  def run(root, opts \\ []) do
    results = Enum.map(@scopes, &derive_scope(&1, root, opts))
    failures = Enum.filter(results, &(&1.error != nil))

    if failures != [] do
      Enum.each(failures, fn r ->
        IO.puts(
          "[crosswake] FAIL: scope #{r.label}: #{r.error}: scanned=#{length(r.actual)} expected=#{length(r.expected)} pin=#{r.min}"
        )

        IO.puts(
          "[crosswake]   Lower that @scopes entry in the same change and say why, or fix --root if it points at the wrong tree."
        )
      end)

      IO.puts("[crosswake] FAIL: content checks were skipped because a scope floor failed.")
      1
    else
      by_label = Map.new(results, &{&1.label, &1.actual})
      test_files = Map.fetch!(by_label, "test-files")

      planning =
        ["todos", "seeds", "deferred-items"]
        |> Enum.flat_map(&Map.fetch!(by_label, &1))
        |> Enum.uniq()
        |> Enum.sort()

      findings = mutation_controls(test_files, root) ++ stale_citations(planning, root)
      legacy = report(findings, results, test_files)
      collections = collections(root, opts, results)
      max(legacy, collections)
    end
  end

  defp collections(root, opts, results) do
    alias Crosswake.AbsenceCollectionAST, as: AST
    {files, findings} = AST.scan(root, opts)

    baseline_path =
      Keyword.get(
        opts,
        :collections_baseline,
        Path.join(__DIR__, "fixtures/absence_collection_baseline.exs")
      )

    baseline =
      try do
        {entries, _bindings} = Code.eval_file(baseline_path)
        if is_list(entries), do: entries, else: raise("invalid baseline")
      rescue
        _ -> :invalid
      end

    {valid, changes} =
      if baseline == :invalid, do: {false, []}, else: AST.delta(findings, baseline)

    Enum.each(findings, fn finding ->
      IO.puts(
        "[crosswake] collection #{finding.category} count=#{finding.count} file=#{finding.file} context=#{finding.context} expression=#{finding.expression}"
      )
    end)

    Enum.each(changes, fn {kind, id, actual, expected} ->
      IO.puts(
        "[crosswake] collection #{kind} #{id.category} file=#{id.file} context=#{id.context} count=#{actual} baseline=#{expected}"
      )
    end)

    unless valid, do: IO.puts("[crosswake] collection invalid_baseline")
    planning = results |> Enum.reject(&(&1.label == "test-files")) |> Enum.flat_map(& &1.actual)

    scanned =
      (files ++ planning) |> Enum.map(&Path.relative_to(&1, root)) |> Enum.uniq() |> Enum.sort()

    closed =
      findings
      |> Enum.group_by(&{&1.file, &1.category})
      |> Enum.sort()
      |> Enum.map(fn {{file, category}, entries} ->
        %{file: file, category: category, count: Enum.sum(Enum.map(entries, & &1.count))}
      end)

    receipt = %{
      schema_version: 1,
      guard: "absence",
      scanned_files: scanned,
      counts: %{
        files: length(scanned),
        projects: 6,
        collections: Enum.sum(Enum.map(findings, & &1.count)),
        findings: length(findings)
      },
      findings: closed
    }

    IO.puts("PHASE196_REPORT " <> AST.json(receipt))
    mode = Keyword.get(opts, :collections_mode, "enforce")

    IO.puts(
      "[crosswake] collections mode=#{mode} files=#{length(files)} findings=#{length(findings)} delta=#{length(changes)}"
    )

    analysis_failed =
      Enum.any?(
        findings,
        &(&1.category in ["read_error", "parse_error", "scope_empty", "scope_mismatch"])
      )

    if not valid or analysis_failed or (mode == "enforce" and changes != []), do: 1, else: 0
  end

  defp report([], results, test_files) do
    pin = Enum.find(results, &(&1.label == "test-files")).min

    counts =
      results
      |> Enum.reject(&(&1.label == "test-files"))
      |> Enum.map_join(", ", &"#{&1.label} #{length(&1.actual)}")

    IO.puts(
      "[crosswake] OK: no mutation control asserts a change it never verified (scanned #{length(test_files)} test files, pin #{pin})."
    )

    IO.puts(
      "[crosswake] OK: every open finding's test citation resolves to a real test (#{counts})."
    )

    0
  end

  defp report(findings, _results, _test_files) do
    Enum.each(findings, fn {id, where, detail, hint} ->
      IO.puts("[crosswake] FAIL: #{id}")
      IO.puts("[crosswake]   where: #{where}")
      IO.puts("[crosswake]   what:  #{detail}")
      IO.puts(indent(hint))
      IO.puts("")
    end)

    IO.puts("[crosswake] FAIL: #{length(findings)} check(s) would pass while asserting nothing.")
    1
  end

  defp derive_scope({label, glob, default_min}, root, opts) do
    min =
      if label == "test-files",
        do: Keyword.get(opts, :min_test_files, default_min),
        else: default_min

    # actual: the glob, filtered to regular files (a directory named x.exs is not a test).
    actual =
      root |> Path.join(glob) |> Path.wildcard() |> Enum.filter(&File.regular?/1) |> Enum.sort()

    # expected: a separate walk, never a second wildcard and never git ls-files.
    expected = expected_scope(label, root)

    error =
      case assert_full_scope(actual, expected) do
        {:error, reason} -> reason
        :ok -> if length(actual) >= min, do: nil, else: "below pinned minimum"
      end

    %{label: label, actual: actual, expected: expected, min: min, error: error}
  end

  defp expected_scope("test-files", root), do: fold(Path.join(root, "test"), ~c"\\.exs$")

  defp expected_scope("deferred-items", root),
    do: fold(Path.join(root, ".planning"), ~c"(^|/)deferred-items\\.md$")

  defp expected_scope("todos", root), do: depth_one(Path.join(root, ".planning/todos"))
  defp expected_scope("seeds", root), do: depth_one(Path.join(root, ".planning/seeds"))

  # Recursive walk, dot-directories included, regular files only. A missing
  # directory yields an empty list.
  defp fold(dir, regex) do
    if File.dir?(dir) do
      dir
      |> String.to_charlist()
      |> :filelib.fold_files(regex, true, fn file, acc -> [List.to_string(file) | acc] end, [])
      |> Enum.sort()
    else
      []
    end
  end

  # The planning globs are depth 1: a recursive walk would count todos/pending and
  # todos/completed, which the glob cannot see.
  defp depth_one(dir) do
    case File.ls(dir) do
      {:ok, names} ->
        names
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&Path.join(dir, &1))
        |> Enum.filter(&File.regular?/1)
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  # An Elixir copy of assertFullScope from scripts/ci_monitor.cjs, by design (no
  # shared module, no Node). The JS lets extras in `actual` pass; the File.regular?
  # filter on `actual` is what closes that loophole here. The vacuous Enum.all? over
  # an empty actual is intentional: it makes an empty actual a proper subset.
  defp assert_full_scope(actual, expected) do
    cond do
      expected == [] ->
        {:error, "expected scope is empty"}

      not Enum.all?(expected, &(&1 in actual)) ->
        {:error, "actual scope is a proper subset of expected scope"}

      true ->
        :ok
    end
  end

  # ── Check 1: a mutation control must prove its mutation changed something ──

  defp mutation_controls(test_files, root) do
    Enum.flat_map(test_files, &mutation_findings(&1, root))
  end

  defp mutation_findings(path, root) do
    # Collection analysis owns the closed read_error finding. Never allow a
    # legacy read! stacktrace to bypass that fail-closed, sanitized verdict.
    source =
      case File.read(path) do
        {:ok, bytes} -> bytes
        {:error, _} -> ""
      end

    source
    |> strip_heredocs()
    |> function_blocks()
    # Only SHARED helpers. An inline `mutated = String.replace(...)` in a test
    # body sits a few lines above its own assertion, where a no-op is visible and
    # usually fails loudly anyway: those tests assert a SPECIFIC failure, which an
    # unmutated input cannot produce. The silent case is a defp used by several
    # call sites, where nothing local shows that the mutation stopped biting.
    |> Enum.filter(fn {kind, _name, _body} -> kind == :function end)
    |> Enum.filter(&builds_mutation?/1)
    |> Enum.reject(&asserts_change?/1)
    |> Enum.map(fn {_kind, name, _body} ->
      {"absence.mutation_control_asserts_change", "#{relative(path, root)} — #{name}",
       "builds a mutated value but never compares it to its source, so a no-op replacement would pass silently",
       @mutation_hint}
    end)
  end

  # Heredoc contents are DATA, not code — a fixture inside `"""..."""` describes
  # a module, it does not define one. Without this the scanner reads its own test
  # fixtures as real functions and reports findings against code that does not
  # exist. Replaced with blank lines so every other line keeps its number.
  defp strip_heredocs(source) do
    {stripped, _} =
      source
      |> String.split("\n")
      |> Enum.map_reduce(false, fn line, inside? ->
        fence? = String.contains?(line, ~s("""))

        cond do
          fence? -> {"", not inside?}
          inside? -> {"", inside?}
          true -> {line, inside?}
        end
      end)

    Enum.join(stripped, "\n")
  end

  # Split a module into {function_name, body} pairs. Crude but sufficient: a
  # function runs from its `def`/`defp` line to the next one at the same indent.
  defp function_blocks(source) do
    lines = String.split(source, "\n")

    starts =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _} ->
        # `test "..." do` and `describe "..." do` are boundaries too. Without
        # them a test body leaks into the preceding defp and gets attributed to
        # a function that never touched it — the guard's own false positive.
        Regex.match?(~r/^\s*defp?\s+[a-z_][A-Za-z0-9_?!]*/, line) or
          Regex.match?(~r/^\s*(test|describe|property)\s+"/, line)
      end)

    starts
    |> Enum.with_index()
    |> Enum.map(fn {{line, index}, position} ->
      {kind, name} =
        case Regex.run(~r/^\s*defp?\s+([a-z_][A-Za-z0-9_?!]*)/, line) do
          [_, captured] -> {:function, captured}
          nil -> {:test_body, line |> String.trim() |> String.slice(0, 60)}
        end

      next =
        case Enum.at(starts, position + 1) do
          {_, next_index} -> next_index
          nil -> length(lines)
        end

      {kind, name, lines |> Enum.slice(index, next - index) |> Enum.join("\n")}
    end)
  end

  defp builds_mutation?({_kind, _name, body}) do
    Regex.match?(~r/\bmutat[a-z_]*\s*=/, body) and
      Regex.match?(~r/(Regex|String)\.replace\(/, body)
  end

  # Any comparison of the mutated value against something else counts: an
  # explicit `==`/`!=`, or a pattern like `^mutated` / `mutated == block`. What
  # must NOT count is merely checking the pattern exists BEFORE replacing — that
  # is the precondition, and the bug lives in the postcondition.
  defp asserts_change?({_kind, _name, body}) do
    Regex.match?(~r/\bmutat[a-z_]*\s*(==|!=)/, body) or
      Regex.match?(~r/(==|!=)\s*mutat[a-z_]*\b/, body)
  end

  # ── Check 2: an open finding's test citation must resolve ──

  defp stale_citations(planning_files, root) do
    Enum.flat_map(planning_files, &citation_findings(&1, root))
  end

  defp citation_findings(path, root) do
    lines = path |> File.read!() |> String.split("\n")

    lines
    |> strip_fences()
    |> Enum.with_index(1)
    |> Enum.reject(fn {line, index} -> line == :fenced or resolved_entry?(lines, index) end)
    |> Enum.flat_map(fn {line, line_number} ->
      ~r/(test\/[A-Za-z0-9_\/.-]+\.exs):(\d+)/
      |> Regex.scan(line)
      |> Enum.map(fn [_, cited_file, cited_line] ->
        {cited_file, String.to_integer(cited_line), line_number}
      end)
    end)
    |> Enum.reject(fn {cited_file, cited_line, _} ->
      citation_resolves?(root, cited_file, cited_line)
    end)
    |> Enum.map(fn {cited_file, cited_line, line_number} ->
      {"absence.open_finding_citation_resolves",
       "#{relative(path, root)}:#{line_number} → #{cited_file}:#{cited_line}",
       citation_detail(root, cited_file, cited_line), @citation_hint}
    end)
  end

  # Replace fenced-code lines with :fenced. A citation inside a fence is a
  # QUOTATION — a reproduction command, a log excerpt, a path inside some other
  # checkout — not a live reference into this repository, and validating it would
  # be guessing.
  defp strip_fences(lines) do
    {stripped, _} =
      Enum.map_reduce(lines, false, fn line, inside? ->
        fence? = String.starts_with?(String.trim_leading(line), "```")

        cond do
          fence? -> {:fenced, not inside?}
          inside? -> {:fenced, inside?}
          true -> {line, inside?}
        end
      end)

    stripped
  end

  # A citation is exempt when the ENTRY it belongs to is marked resolved, not
  # merely when the same line says so: the bullet carries the citation and the
  # `status:` sits on a continuation line beneath it. Historical records are
  # allowed to name a line that has since moved — that is what a record is for.
  defp resolved_entry?(lines, index) do
    own_entry =
      lines
      |> Enum.drop(index - 1)
      |> Enum.take(entry_span(lines, index))

    # A record often declares resolution once, in the SECTION HEADING above its
    # items ("## Pre-existing failures ... RESOLVED in Phase 135"), not on every
    # line beneath it. Reading only the entry misses that and re-opens a finding
    # the file already closed.
    heading =
      lines
      |> Enum.take(index - 1)
      |> Enum.reverse()
      |> Enum.find(&Regex.match?(~r/^\s*#/, &1))
      |> List.wrap()

    Enum.any?(own_entry ++ heading, &resolution_marker?/1)
  end

  defp resolution_marker?(line) do
    downcased = String.downcase(line)

    String.contains?(line, "status: resolved") or
      String.contains?(downcased, "resolved in ") or
      String.contains?(downcased, "resolved 20") or
      String.contains?(downcased, "fixed in ") or
      String.contains?(downcased, "**fixed:**") or
      String.contains?(downcased, "previously")
  end

  # The entry runs to the next bullet or heading, capped so a citation in loose
  # prose cannot inherit a `status: resolved` from far below it.
  defp entry_span(lines, index) do
    lines
    |> Enum.drop(index)
    |> Enum.take(8)
    |> Enum.find_index(&Regex.match?(~r/^\s*([-*+]\s|#)/, &1))
    |> case do
      nil -> 8
      offset -> offset + 1
    end
  end

  # A citation to a file that does not exist here is NOT the defect this guard
  # exists for. `mix test missing.exs:21` exits 1 and says so — it fails loudly,
  # and it is often a path inside a generated host or another repository. The
  # silent case, verified empirically, is a line that has MOVED inside a file
  # that still exists: that run prints "0 tests, 0 failures" and exits 0.
  defp citation_resolves?(root, cited_file, cited_line) do
    full = Path.join(root, cited_file)

    with true <- File.exists?(full),
         lines <- full |> File.read!() |> String.split("\n"),
         line when is_binary(line) <- Enum.at(lines, cited_line - 1) do
      Regex.match?(~r/^\s*(test|describe|property)\s+"/, line)
    else
      # File absent: out of scope, treated as resolved (it fails loudly on its own).
      false -> true
      _ -> false
    end
  end

  defp citation_detail(root, cited_file, cited_line) do
    full = Path.join(root, cited_file)

    nearest = nearest_test(full, cited_line)

    "line #{cited_line} holds no test#{nearest}. A location-scoped run against it reports \"0 tests, 0 failures\" and exits 0"
  end

  defp nearest_test(full, cited_line) do
    full
    |> File.read!()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _} -> Regex.match?(~r/^\s*(test|describe|property)\s+"/, line) end)
    |> Enum.min_by(fn {_, number} -> abs(number - cited_line) end, fn -> nil end)
    |> case do
      {_, number} -> " (nearest is :#{number})"
      nil -> ""
    end
  end

  defp relative(path, root), do: Path.relative_to(path, root)

  defp indent(text) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", &"[crosswake]   #{&1}")
  end
end

usage_fail = fn message ->
  IO.puts("[crosswake] FAIL: #{message}")
  System.halt(2)
end

{opts, rest, invalid} =
  OptionParser.parse(System.argv(),
    strict: [
      root: :string,
      min_test_files: :integer,
      collections_mode: :string,
      collections_baseline: :string
    ]
  )

if invalid != [] do
  {flag, _} = hd(invalid)
  usage_fail.("unusable argument: #{flag} (expected --root PATH and --min-test-files N)")
end

if rest != [] do
  usage_fail.(
    "unknown argument: #{Enum.join(rest, " ")} (expected --root PATH and --min-test-files N)"
  )
end

root = Keyword.get(opts, :root) || File.cwd!()

unless Keyword.get(opts, :collections_mode, "enforce") in ["report", "enforce"],
  do: usage_fail.("invalid collections mode")

expanded = Path.expand(root)

unless File.exists?(expanded), do: usage_fail.("root does not exist: #{expanded}")
unless File.dir?(expanded), do: usage_fail.("root is not a directory: #{expanded}")

System.halt(Crosswake.AbsenceIsNotSuccess.run(expanded, opts))
