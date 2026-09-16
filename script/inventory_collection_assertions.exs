#!/usr/bin/env elixir

# Builds and diffs the audit ledger for one recurring defect class: a collection
# assertion whose empty case is not a failure. `assert Enum.all?([], f)` is
# TRUE — an empty collection vacuously satisfies "all elements match" — and
# `refute Enum.any?([], f)` PASSES for the identical reason on the negated
# quantifier. Both shapes silently score absence as success.
#
# SEED-018 found 173 `assert Enum.all?`/`assert Enum.any?` sites by grep.
# Phase 170's verified ground truth corrected that count in both directions:
# `assert Enum.any?` is non-vacuous BY CONSTRUCTION (131 of the 173 were
# never actually at risk), while 47 `refute Enum.any?` sites carry the exact
# same defect and were invisible to that grep. The true audited population is
# 220 sites, and a hand-typed `file:line` table would rot the moment any of
# them moved — this repository has already shipped that exact bug once
# (`absence.open_finding_citation_resolves` exists because of it).
#
# This script is therefore a REGENERABLE inventory: it walks the tree, emits
# one classified row per call site, and a committed snapshot is diffed against
# a fresh run by test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs.
# Per D-06, this ledger asserts only that every site has a row and every row
# resolves to a live site — it never asserts that a site is actually guarded.
# That second, tree-wide, open-world assertion is VACG-01 and stays deferred
# (see Future Requirements) precisely so a 220-finding guard does not land
# before the audit and get waived on day one.
#
# Sunset (D-08): when VACG-01 lands as a merge-blocking guard, lift this
# script's detection core into that guard rather than rewriting it, then
# DELETE this script, script/collection_assertion_ledger.json,
# script/collection_assertion_remediation.json, and
# test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs. Two
# mechanisms that can silently disagree about what counts as safe are worse
# than one.
#
# Scope note — two dispositions this scanner consciously does not act on:
#   - D-02: this scan stops at four shapes (`assert_all`, `assert_any`,
#     `refute_any`, `refute_all`). The broader vacuity family (a job `needs:`
#     something that skipped, `continue-on-error` on a one-way-door lane,
#     `if:` conditions that never match, a matrix expanding to zero entries,
#     missing `set -e` / misused `grep -q` / `jq -e`, `Enum.each` without a
#     count assertion, `for` comprehensions, `Enum.reduce` boolean
#     accumulators, unforced `Stream` chains) is owned by Phases 171, 173 and
#     174 and by the VAC-03 checklist, not by this scanner. The one compound
#     shape that would matter most here (`Enum.filter |> Enum.all?/any?`) has
#     zero occurrences in this repository.
#   - D-03: ROADMAP.md success criterion #1 states a total ("173") that the
#     measured ground truth corrects to 220; the correction lives in
#     170-CONTEXT.md and this phase's SUMMARY, and amending the roadmap text
#     itself is a separate, deferred call — exactly how Phase 169 handled its
#     own two arithmetically-wrong success criteria.
#   - D-13: this script is deliberately NOT registered in
#     script/check_absence_is_not_success.exs and NOT added to any
#     required-check registry. It is scaffolding for the audit, not a guard.

defmodule Crosswake.CollectionAssertionInventory do
  @moduledoc false

  @default_scope "test/**/*.exs"
  @default_ledger_relpath "script/collection_assertion_ledger.json"
  @generator "script/inventory_collection_assertions.exs"
  @sunset "When VACG-01 (absence.collection_assertion_non_empty) lands as a merge-blocking guard, lift this script's detection core into that guard rather than rewriting it, then delete script/inventory_collection_assertions.exs, script/collection_assertion_ledger.json, script/collection_assertion_remediation.json, and test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs. Two mechanisms that can silently disagree about what counts as safe are worse than one."

  @row_fields ~w(key shape bucket rationale display enclosing expression)

  @shape_patterns [
    {:assert_all, ~r/assert\s+Enum\.all\?\(/},
    {:assert_any, ~r/assert\s+Enum\.any\?\(/},
    {:refute_any, ~r/refute\s+Enum\.any\?\(/},
    {:refute_all, ~r/refute\s+Enum\.all\?\(/}
  ]

  # ── Public surface ──────────────────────────────────────────────────────

  @doc "Runs the inventory. `root` is always an argument, never File.cwd!() hardcoded, so a test can point it at a @tag :tmp_dir fixture tree."
  def run(root, opts \\ []) do
    ledger_path = Keyword.get(opts, :ledger_path, Path.join(root, @default_ledger_relpath))

    cond do
      Keyword.get(opts, :emit_snapshot, false) ->
        scope = effective_scope(Keyword.get(opts, :scope), ledger_path)
        root |> rows(scope) |> render_snapshot(scope) |> IO.write()
        0

      true ->
        check(root, Keyword.get(opts, :scope), ledger_path)
    end
  end

  # `--scope` is optional for both `--emit-snapshot` and `--check`: an already-committed ledger
  # declares the scope it was generated against (its own "scope" field), so an unqualified
  # invocation regenerates against exactly what was committed rather than silently defaulting
  # to the tree-wide glob and reporting every out-of-scope site as new. Only when no ledger
  # exists yet (bootstrapping a brand-new one) does the tree-wide default apply.
  defp effective_scope(nil, ledger_path) do
    case File.read(ledger_path) do
      {:ok, contents} -> Map.get(JSON.decode!(contents), "scope", @default_scope)
      {:error, _} -> @default_scope
    end
  end

  defp effective_scope(explicit_scope, _ledger_path), do: explicit_scope

  @doc "The pure, ordered row list for a scope glob under root. Deterministic: same tree in, same rows out."
  def rows(root, scope_glob \\ @default_scope) do
    root
    |> Path.join(scope_glob)
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.flat_map(&file_rows(&1, root))
    |> Enum.sort_by(&{&1["display"], &1["key"]})
  end

  @doc """
  Collapses whitespace runs (including newlines from a wrapped multi-line
  call) to a single space, trims, and drops a trailing comma — so
  re-wrapping a flagged assertion across lines changes no key, while
  renaming an identifier inside the expression always changes it.
  """
  def normalize_expression(expr) do
    expr
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.trim_trailing(",")
    |> String.trim()
  end

  @doc """
  `sha256:` + first 16 hex chars of SHA-256 over
  `{enclosing, normalized_expression, ordinal}`. `ordinal` is the 0-based
  index of this row among rows sharing the same {enclosing,
  normalized_expression} pair within one file, in ascending line order —
  the piece that keeps two textually identical adjacent assertions as two
  rows instead of one merged row.
  """
  def row_key(enclosing, normalized_expression, ordinal) do
    digest =
      :crypto.hash(
        :sha256,
        enclosing <> "\0" <> normalized_expression <> "\0" <> Integer.to_string(ordinal)
      )
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    "sha256:" <> digest
  end

  @doc "Deterministic text rendering of the snapshot. Built with an explicit field-ordered key list — never `JSON.encode!` handed a bare map — so regeneration is byte-stable across runs."
  def render_snapshot(rows, scope_glob) do
    rows_json =
      rows
      |> Enum.map(&render_row/1)
      |> Enum.join(",\n")

    rows_block = if rows_json == "", do: "", else: "\n" <> rows_json <> "\n"

    """
    {
      "scope": #{JSON.encode!(scope_glob)},
      "generator": #{JSON.encode!(@generator)},
      "sunset": #{JSON.encode!(@sunset)},
      "rows": [#{rows_block}]
    }
    """
  end

  # ── File-level scan ──────────────────────────────────────────────────────

  defp file_rows(path, root) do
    display_root = relative(path, root)
    stripped = path |> File.read!() |> strip_heredocs()
    lines = String.split(stripped, "\n")
    blocks = test_blocks(lines)

    raw =
      blocks
      |> Enum.flat_map(fn {enclosing, start_line, end_line} ->
        body = lines |> Enum.slice(start_line - 1, end_line - start_line + 1) |> Enum.join("\n")

        body
        |> find_calls()
        |> Enum.map(fn {shape, line_offset, expr} ->
          %{
            enclosing: enclosing,
            shape: shape,
            expression: String.trim(expr),
            normalized: normalize_expression(expr),
            line: start_line + line_offset,
            test_start_line: start_line
          }
        end)
      end)
      |> Enum.sort_by(& &1.line)

    {finished_rows, _counts} =
      Enum.map_reduce(raw, %{}, fn item, counts ->
        pair_key = {item.enclosing, item.normalized}
        ordinal = Map.get(counts, pair_key, 0)
        counts = Map.put(counts, pair_key, ordinal + 1)

        row = %{
          "key" => row_key(item.enclosing, item.normalized, ordinal),
          "shape" => Atom.to_string(item.shape),
          "bucket" => nil,
          "rationale" => nil,
          "display" => "#{display_root}:#{item.line}",
          "enclosing" => item.enclosing,
          "expression" => item.expression
        }

        {{row, item.test_start_line}, counts}
      end)

    Enum.map(finished_rows, fn {row, test_start_line} -> classify(row, lines, test_start_line) end)
  end

  # Heredoc contents are DATA, not code — a fixture inside `"""..."""`
  # describes a call site, it does not create one. Replaced with blank lines
  # so every other line keeps its number. Cloned from
  # script/check_absence_is_not_success.exs's strip_heredocs/1.
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

  # Splits the source into {enclosing_name, start_line, end_line} (both
  # 1-based, inclusive) test blocks. Crude but sufficient, matching this
  # repo's established source-regex-over-heredoc-stripped-text idiom (no real
  # AST parsing anywhere in script/): a test block runs from its
  # `test "..." do` line to the line before the next `test "..." do`, or to
  # EOF. The nearest preceding `describe "..." do` (if any) is prefixed onto
  # the enclosing name so two identically-named tests in different describes
  # never collide.
  defp test_blocks(lines) do
    starts =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _idx} -> Regex.match?(~r/^\s*test\s+"/, line) end)

    starts
    |> Enum.with_index()
    |> Enum.map(fn {{line, idx}, position} ->
      test_name =
        case Regex.run(~r/^\s*test\s+"((?:[^"\\]|\\.)*)"/, line) do
          [_, name] -> name
          nil -> line |> String.trim() |> String.slice(0, 60)
        end

      enclosing =
        case nearest_describe(lines, idx) do
          nil -> test_name
          describe_name -> "#{describe_name} > #{test_name}"
        end

      next_idx =
        case Enum.at(starts, position + 1) do
          {_line, next} -> next
          nil -> length(lines)
        end

      {enclosing, idx + 1, next_idx}
    end)
  end

  defp nearest_describe(lines, idx) do
    lines
    |> Enum.take(idx)
    |> Enum.reverse()
    |> Enum.find_value(fn line ->
      case Regex.run(~r/^\s*describe\s+"((?:[^"\\]|\\.)*)"/, line) do
        [_, name] -> name
        nil -> nil
      end
    end)
  end

  # Finds every flagged call in a test body, returning {shape, 0-based line
  # offset within the body, first-argument expression text}.
  defp find_calls(body) do
    @shape_patterns
    |> Enum.flat_map(fn {shape, pattern} ->
      pattern
      |> Regex.scan(body, return: :index)
      |> Enum.map(fn [{start, len}] ->
        after_paren_index = start + len
        remainder = binary_part(body, after_paren_index, byte_size(body) - after_paren_index)
        {expr, _rest} = capture_first_arg(remainder)
        line_offset = body |> binary_part(0, start) |> count_newlines()
        {shape, line_offset, expr}
      end)
    end)
  end

  defp count_newlines(text), do: text |> String.graphemes() |> Enum.count(&(&1 == "\n"))

  # Captures the first call argument, balancing ( [ { so a wrapped multi-line
  # call is captured whole, stopping at the top-level comma that separates
  # the collection expression from the predicate function (or at the call's
  # own closing paren, for a single-argument call). `depth` starts at 1
  # because the cursor is already inside the opening "(" of Enum.xxx?(.
  #
  # This is source-text balancing, not a real parser: a string literal
  # containing a literal "(" or "," would defeat it. None of the 220 audited
  # call sites contain one (they are all bare identifiers, field accesses,
  # or Enum pipelines) — this matches the crude-but-sufficient idiom already
  # used by script/check_absence_is_not_success.exs.
  defp capture_first_arg(text), do: capture_first_arg(text, 1, [])

  defp capture_first_arg(<<>>, _depth, acc),
    do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), ""}

  defp capture_first_arg(<<c::utf8, rest::binary>>, depth, acc) do
    char = <<c::utf8>>

    cond do
      char in ["(", "[", "{"] ->
        capture_first_arg(rest, depth + 1, [char | acc])

      char in [")", "]", "}"] ->
        new_depth = depth - 1

        if new_depth == 0 do
          {acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}
        else
          capture_first_arg(rest, new_depth, [char | acc])
        end

      char == "," and depth == 1 ->
        {acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}

      true ->
        capture_first_arg(rest, depth, [char | acc])
    end
  end

  # ── Classification (D-07's full five-bucket classifier, in precedence order) ─

  # D-14: a small, explicitly-justified table of sites the general heuristic
  # below cannot syntactically reach — because the pinning/guarding evidence
  # references a DIFFERENT identifier than the flagged expression's own root,
  # a fact only a human reading the surrounding code can establish. D-07's
  # "classification is mechanically bucketed first; humans write rationale
  # only for the residual" applies literally here: every entry below carries
  # a rationale explaining WHY the heuristic can't see it, not just WHAT the
  # answer is.
  @manual_overrides %{
    {"test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs", 92} =>
      {"safe-cardinality-pinned",
       "assertion_ids (bound from the device report telemetry at line 67, `assert_receive {:device, %{assertion_ids: assertion_ids}}`) is asserted equal to a 19-item literal list immediately above (line 69); assertions and assertion_ids are the same underlying collection surfaced under two different field names on the same struct, which a text-only scanner cannot infer from identifier text alone — recorded as a manual override with this citation, not a heuristic match."}
  }

  defp classify(row, lines, test_start_line) do
    row
    |> classify_heuristically(lines, test_start_line)
    |> apply_manual_override()
  end

  defp classify_heuristically(row, lines, test_start_line) do
    cond do
      row["shape"] == "assert_any" ->
        row
        |> Map.put("bucket", "safe-by-construction")
        |> Map.put(
          "rationale",
          "Enum.any?/2 is false on an empty collection, so this assertion FAILS on the empty case by construction — it cannot silently pass on absence."
        )

      compile_time_literal?(row["expression"]) ->
        row
        |> Map.put("bucket", "safe-compile-time-literal")
        |> Map.put("rationale", compile_time_literal_rationale(row["expression"]))

      true ->
        classify_by_backward_scan(row, lines, test_start_line)
    end
  end

  defp classify_by_backward_scan(row, lines, test_start_line) do
    flagged_line = display_line(row["display"])
    root = extract_root(row["expression"])

    case find_backward(lines, test_start_line, flagged_line, &pin_line?(&1, root)) do
      {pin_line, pin_text} ->
        row
        |> Map.put("bucket", "safe-cardinality-pinned")
        |> Map.put(
          "rationale",
          "pinned to an exact set at line #{pin_line} (`#{pin_text}`), which fixes #{root}'s cardinality — the empty case is unreachable while that pin holds."
        )

      nil ->
        case find_backward(lines, test_start_line, flagged_line, &guard_line?(&1, root)) do
          {guard_line, guard_text} ->
            row
            |> Map.put("bucket", "safe-guarded")
            |> Map.put(
              "rationale",
              "guarded by an explicit non-emptiness check on the same collection at line #{guard_line} (`#{guard_text}`)."
            )

          nil ->
            row
            |> Map.put("bucket", "needs-fix")
            |> Map.put(
              "rationale",
              "runtime-derived collection at #{row["display"]}: `#{row["expression"]}` inside test \"#{row["enclosing"]}\" — no preceding cardinality-pinning or emptiness guard was found for this expression; needs-fix pending VAC-02 remediation."
            )
        end
    end
  end

  defp apply_manual_override(row) do
    file = row["display"] |> String.split(":") |> Enum.drop(-1) |> Enum.join(":")
    line = display_line(row["display"])

    case Map.get(@manual_overrides, {file, line}) do
      {bucket, rationale} ->
        row |> Map.put("bucket", bucket) |> Map.put("rationale", rationale)

      nil ->
        row
    end
  end

  defp display_line(display) do
    display |> String.split(":") |> List.last() |> String.to_integer()
  end

  # A collection expression that is EITHER a bare module-attribute reference
  # OR a bracketed list literal cannot be empty at the call site: its
  # contents are fixed at compile time (or, for the attribute case, fixed
  # wherever the attribute itself is declared — this scanner does not chase
  # attribute definitions across files, so a `[]`-valued attribute would be
  # misclassified; none of the 220 audited sites do this).
  defp compile_time_literal?(expr) do
    trimmed = String.trim(expr)

    Regex.match?(~r/^@[a-zA-Z_]\w*$/, trimmed) or
      (String.starts_with?(trimmed, "[") and String.ends_with?(trimmed, "]") and
         not String.contains?(trimmed, "Enum.") and not String.contains?(trimmed, "|>"))
  end

  defp compile_time_literal_rationale(expr) do
    trimmed = String.trim(expr)

    if String.starts_with?(trimmed, "@") do
      "#{trimmed} is a module attribute holding a fixed literal collection; it cannot be empty, so the empty case is unreachable."
    else
      "#{trimmed} is a literal list written directly in source; it cannot be empty by construction."
    end
  end

  # The "root" a guard or pin must reference to count as covering THIS
  # expression: the leading identifier/dotted-path, unwrapping one level of
  # a pipeline (`X |> Enum.filter(...)` → X) or a known collection-producing
  # call (`Enum.filter(X, ...)` / `Map.values(X)` → X) so `report.findings`
  # is recognized as the subject of `report.findings |> Enum.filter(...)`
  # and of `Enum.filter(matrix.release_boundaries, ...)` alike.
  defp extract_root(expr) do
    trimmed = String.trim(expr)

    cond do
      String.contains?(trimmed, "|>") ->
        trimmed |> String.split("|>") |> List.first() |> String.trim() |> extract_root()

      Regex.match?(~r/^(Enum|Map|MapSet|Stream)\.[a-zA-Z_?!]+\(/, trimmed) ->
        case Regex.run(~r/^(Enum|Map|MapSet|Stream)\.[a-zA-Z_?!]+\(/, trimmed) do
          [prefix | _groups] ->
            rest = String.slice(trimmed, String.length(prefix)..-1//1)
            {inner, _rest} = capture_first_arg(rest)
            extract_root(inner)

          nil ->
            trimmed
        end

      true ->
        case Regex.run(~r/^@?[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*/, trimmed) do
          [matched | _groups] -> matched
          nil -> trimmed
        end
    end
  end

  # Searches backward from the line immediately before `flagged_line` to
  # `test_start_line` (inclusive), returning the NEAREST matching line as
  # {line_number, trimmed_text}, or nil. Unbounded within the test body (not
  # a fixed N-line window) because a guard or pin can sit many lines above a
  # SECOND flagged assertion on the same already-guarded collection.
  defp find_backward(_lines, test_start_line, flagged_line, _predicate)
       when flagged_line - 1 < test_start_line,
       do: nil

  defp find_backward(lines, test_start_line, flagged_line, predicate) do
    Enum.reduce_while((flagged_line - 1)..test_start_line//-1, nil, fn line_no, _acc ->
      text = Enum.at(lines, line_no - 1) || ""

      if predicate.(text) do
        {:halt, {line_no, String.trim(text)}}
      else
        {:cont, nil}
      end
    end)
  end

  defp root_word_boundary?(line, root), do: Regex.match?(~r/\b#{Regex.escape(root)}\b/, line)

  # D-07's `safe-guarded`: an explicit non-emptiness check on the SAME
  # collection. This repo's actual idiom (verified against the live tree) is
  # `assert <coll> != []` / `refute <coll> == []`, not literally
  # `refute Enum.empty?/1` — both forms are recognized.
  defp guard_line?(line, root) do
    root_word_boundary?(line, root) and
      (Regex.match?(~r/!=\s*\[\]/, line) or
         Regex.match?(~r/refute\s+.*==\s*\[\]/, line) or
         Regex.match?(~r/refute\s+Enum\.empty\?\(/, line) or
         Regex.match?(~r/assert\s+\[_\s*\|\s*_\]\s*=/, line))
  end

  # D-07's `safe-cardinality-pinned`: an exact equality assertion pinning the
  # element set — `assert Enum.map(coll, ...) == [<literal>]`,
  # `assert coll == [<literal>]`, `assert Enum.map(coll, ...) == @attribute`,
  # or an exact-count pin (`assert (length|map_size)(coll) == <int>`).
  defp pin_line?(line, root) do
    root_word_boundary?(line, root) and
      (Regex.match?(~r/assert\s+.*==\s*\[/, line) or
         Regex.match?(~r/assert\s+.*==\s*@[A-Za-z_]\w*/, line) or
         Regex.match?(~r/assert\s+(length|map_size)\(.*\)\s*==\s*\d+/, line))
  end

  # ── Snapshot rendering ───────────────────────────────────────────────────

  defp render_row(row) do
    fields =
      @row_fields
      |> Enum.map(fn key -> ~s("#{key}": #{JSON.encode!(Map.fetch!(row, key))}) end)
      |> Enum.join(", ")

    "    {" <> fields <> "}"
  end

  # ── --check: regenerate, diff both directions against the committed file ─

  defp check(root, scope_override, ledger_path) do
    case File.read(ledger_path) do
      {:ok, contents} ->
        committed = JSON.decode!(contents)
        committed_rows = Map.get(committed, "rows", [])
        committed_by_key = Map.new(committed_rows, &{&1["key"], &1})

        # An unqualified `--check` uses the scope the ledger itself declares, not the
        # tree-wide default — that is what lets a narrow-scope committed snapshot (Task 1's
        # release-critical subset) pass `--check` with no flags at all.
        scope = scope_override || Map.get(committed, "scope", @default_scope)
        live_rows = rows(root, scope)
        live_by_key = Map.new(live_rows, &{&1["key"], &1})

        live_keys = live_by_key |> Map.keys() |> MapSet.new()
        committed_keys = committed_by_key |> Map.keys() |> MapSet.new()

        unclassified_keys = MapSet.difference(live_keys, committed_keys)
        orphan_keys = MapSet.difference(committed_keys, live_keys)

        if MapSet.size(unclassified_keys) == 0 and MapSet.size(orphan_keys) == 0 do
          IO.puts(
            "[crosswake] OK: #{length(committed_rows)} classified collection-assertion site(s), ledger matches the live tree exactly."
          )

          0
        else
          IO.puts(
            "[crosswake] FAIL: the committed classification snapshot has #{MapSet.size(unclassified_keys)} site(s) not yet classified and #{MapSet.size(orphan_keys)} orphan row(s)."
          )

          unclassified_keys
          |> Enum.map(&Map.fetch!(live_by_key, &1))
          |> Enum.sort_by(& &1["display"])
          |> Enum.each(fn row ->
            IO.puts("[crosswake]   unclassified: #{row["display"]} (#{row["key"]})")
          end)

          orphan_keys
          |> Enum.map(&Map.fetch!(committed_by_key, &1))
          |> Enum.sort_by(& &1["display"])
          |> Enum.each(fn row ->
            IO.puts("[crosswake]   orphan: #{row["display"]} (#{row["key"]})")
          end)

          IO.puts(
            "[crosswake] What to do next: run `elixir #{@generator} --emit-snapshot`, classify any new row with a one-line rationale, and commit the updated snapshot."
          )

          1
        end

      {:error, reason} ->
        IO.puts("[crosswake] FAIL: could not read ledger at #{ledger_path}: #{inspect(reason)}")
        1
    end
  end

  defp relative(path, root), do: Path.relative_to(path, root)
end

# ── CLI ──────────────────────────────────────────────────────────────────

defmodule Crosswake.CollectionAssertionInventory.CLI do
  @moduledoc false

  def parse(argv),
    do:
      parse(argv, %{
        root: File.cwd!(),
        scope: nil,
        ledger: nil,
        emit_snapshot: false,
        check: false
      })

  defp parse([], acc), do: acc
  defp parse(["--root", path | rest], acc), do: parse(rest, %{acc | root: path})
  defp parse(["--scope", glob | rest], acc), do: parse(rest, %{acc | scope: glob})
  defp parse(["--ledger", path | rest], acc), do: parse(rest, %{acc | ledger: path})
  defp parse(["--emit-snapshot" | rest], acc), do: parse(rest, %{acc | emit_snapshot: true})
  defp parse(["--check" | rest], acc), do: parse(rest, %{acc | check: true})
  defp parse([_unrecognized | rest], acc), do: parse(rest, acc)
end

cli = Crosswake.CollectionAssertionInventory.CLI.parse(System.argv())

run_opts =
  [emit_snapshot: cli.emit_snapshot]
  |> then(fn opts -> if cli.scope, do: Keyword.put(opts, :scope, cli.scope), else: opts end)
  |> then(fn opts ->
    if cli.ledger, do: Keyword.put(opts, :ledger_path, cli.ledger), else: opts
  end)

System.halt(Crosswake.CollectionAssertionInventory.run(cli.root, run_opts))
