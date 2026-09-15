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

  def run(root) do
    findings = mutation_controls(root) ++ stale_citations(root)

    case findings do
      [] ->
        IO.puts("[crosswake] OK: no mutation control asserts a change it never verified.")
        IO.puts("[crosswake] OK: every open finding's test citation resolves to a real test.")
        0

      _ ->
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
  end

  # ── Check 1: a mutation control must prove its mutation changed something ──

  defp mutation_controls(root) do
    root
    |> Path.join("test/**/*.exs")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.flat_map(&mutation_findings(&1, root))
  end

  defp mutation_findings(path, root) do
    path
    |> File.read!()
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

  defp stale_citations(root) do
    [
      Path.join(root, ".planning/todos/*.md"),
      Path.join(root, ".planning/seeds/*.md"),
      Path.join(root, ".planning/**/deferred-items.md")
    ]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.flat_map(&citation_findings(&1, root))
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
    |> Enum.reject(fn {cited_file, cited_line, _} -> citation_resolves?(root, cited_file, cited_line) end)
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

root =
  case System.argv() do
    ["--root", path | _] -> path
    _ -> File.cwd!()
  end

System.halt(Crosswake.AbsenceIsNotSuccess.run(root))
