defmodule Crosswake.Proof.Phase170GuardExpressionMatchTest do
  @moduledoc """
  VAC-02 / D-12.1: itemized, closed-world structural proof that every site frozen in
  `script/collection_assertion_remediation.json` carries a non-emptiness guard on its
  preceding source line, AND that the guard's argument expression is the SAME expression
  the assertion consumes — not merely a guard on some nearby collection with a similar name.

  Per D-06/D-13 this test enumerates ONLY the frozen manifest's keys. It never scans the
  tree for new call sites and never asserts anything about a site outside the manifest;
  standing, tree-wide, open-world enforcement is VACG-01 and stays deferred.

  ## Why a fixed `display_line - 1` offset is not the predicate

  The plan's original acceptance criterion checked the line immediately above the
  assertion's `display` line for a literal `refute Enum.empty?(` prefix. Against the real,
  `mix format`-settled tree this is wrong for a real subset of rows, for two legitimate
  reasons neither of which is a defect:

    1. `mix format` wraps a long guard call across several physical lines (D-09 explicitly
       permits this: "wrap it and let mix format settle the layout") — the line immediately
       above the assertion is then the guard's closing paren, not its `refute Enum.empty?(`
       opening.
    2. `mix format` inserts a blank line before a multi-clause `fn` argument (the common
       shape for the assertion this guard precedes) — the line immediately above the
       assertion is then blank, and the guard sits one line further up still.

  This module's `guarded_correctly?/2` therefore mirrors
  `script/inventory_collection_assertions.exs`'s own detection idiom: a bounded backward
  scan from the assertion's line for the nearest guard-opening line, followed by the same
  paren-balanced `join_forward` technique the script uses to read a multi-line statement as
  one logical unit (the script's `join_forward/2,3` and `capture_first_arg/1`, mirrored here
  because they are `defp` in the script module and cannot be required into this test process
  without also running the script's own CLI/`System.halt` trailer). The half that matters
  and that the classifier's own coarser root-based matching does NOT do: this predicate
  compares the guard's full, normalized argument expression against the assertion's full,
  normalized expression for EXACT equality, not just a shared leading identifier — this is
  what catches a guard that checks a different-but-similarly-named collection (D-12,
  T-170-06).
  """

  use ExUnit.Case, async: true

  @manifest_path "script/collection_assertion_remediation.json"
  @ledger_path "script/collection_assertion_ledger.json"

  # D-14 / D-24 (Phase 169 precedent): the manifest's real, measured row count as a
  # hard-coded literal, so the closed world cannot silently shrink to nothing. Taken from
  # `script/collection_assertion_remediation.json` as committed by Task 1 (170-02), never
  # re-derived from the file under test.
  @remediated_site_count 52

  @guard_start_regex ~r/^\s*refute\s+Enum\.empty\?\(/
  @max_lookback 20
  @max_join 12

  describe "Task 3: guard presence and expression match, per frozen manifest entry" do
    test "every row in the frozen remediation manifest has a guard whose argument matches the assertion's expression" do
      manifest = load_manifest()
      ledger_by_key = load_ledger_by_key()

      assert manifest["rows"] != [],
             "a closed-world proof over an empty manifest asserts nothing — the manifest " <>
               "must contain at least one row for this test to mean anything"

      failures =
        manifest["rows"]
        |> Enum.map(fn row -> {row, verify_row(row, ledger_by_key)} end)
        |> Enum.reject(fn {_row, result} -> result == :ok end)

      assert failures == [], failure_message(failures)
    end
  end

  describe "Task 3: non-vacuity control (D-14) — the predicate must be capable of returning false" do
    test "a synthetic fixture with the guard line deleted makes guarded_correctly?/2 return false" do
      row = %{
        "display" => "fixture_test.exs:4",
        "expression" => "some_collection"
      }

      # No guard line at all above the assertion — just unrelated setup code. This fixture is
      # written as a heredoc, not a list of quoted strings: script/inventory_collection_
      # assertions.exs's own strip_heredocs/1 treats heredoc contents as DATA (blanking every
      # line so it never scans them as call sites), which is the same idiom the classifier's
      # own test corpus (test/crosswake/proof/phase169_check_name_uniqueness_test.exs) uses
      # for its synthetic fixtures. A bare-string-list fixture would instead make this test
      # file itself contribute rows to the ledger, contradicting the plan's own requirement
      # that this file stay ledger-clean.
      source_lines =
        """
        defmodule FixtureTest do
          test "no guard" do
            some_collection = compute()
            assert Enum.member?(some_collection, :expected) # stand-in for the real assertion; not a flagged shape
          end
        end
        """
        |> String.split("\n")

      refute guarded_correctly?(source_lines, row),
             "expected a missing guard to make the predicate return false"
    end

    test "a synthetic fixture whose guard argument names a different collection makes guarded_correctly?/2 return false" do
      row = %{
        "display" => "fixture_test.exs:5",
        "expression" => "some_collection"
      }

      # Guard present, but it checks a DIFFERENTLY-NAMED collection than the assertion
      # consumes — this is exactly the guard-checks-the-wrong-variable defect D-12/T-170-06
      # exists to catch, which no runtime test can reliably catch.
      source_lines =
        """
        defmodule FixtureTest do
          test "wrong variable guard" do
            some_collection = compute()
            refute Enum.empty?(a_completely_different_collection)
            assert Enum.member?(some_collection, :expected) # stand-in for the real assertion; not a flagged shape
          end
        end
        """
        |> String.split("\n")

      refute guarded_correctly?(source_lines, row),
             "expected a guard on a different expression to make the predicate return false"
    end
  end

  describe "Task 3: population floor (D-14 / D-24) — the closed world cannot silently shrink" do
    test "the frozen manifest's row count is greater than zero and equals @remediated_site_count exactly" do
      manifest = load_manifest()

      assert length(manifest["rows"]) > 0
      assert length(manifest["rows"]) == @remediated_site_count
    end
  end

  describe "Task 3: ledger cross-check — every remediated key reclassified to safe-guarded" do
    test "every key in the frozen remediation manifest is present in the ledger with bucket safe-guarded" do
      manifest = load_manifest()
      ledger_by_key = load_ledger_by_key()

      missing_or_wrong_bucket =
        manifest["rows"]
        |> Enum.reject(fn row ->
          match?({:ok, %{"bucket" => "safe-guarded"}}, Map.fetch(ledger_by_key, row["key"]))
        end)
        |> Enum.map(& &1["display"])

      assert missing_or_wrong_bucket == [],
             "expected every manifest key to be bucket safe-guarded in the regenerated " <>
               "ledger, but these rows were not: #{inspect(missing_or_wrong_bucket)}"
    end
  end

  # ── Cross-check + verification plumbing ─────────────────────────────────────────────────

  # Cross-checks against the regenerated ledger (bucket must be safe-guarded) and, only then,
  # applies this module's OWN structural predicate against the live source file — the ledger's
  # classification alone is not trusted as the proof, since its `guard_line?/2` matches on a
  # coarser shared-root basis than the exact-expression-equality this test requires (D-12.1).
  defp verify_row(row, ledger_by_key) do
    case Map.fetch(ledger_by_key, row["key"]) do
      :error ->
        {:error, "key #{row["key"]} is not present in #{@ledger_path}"}

      {:ok, %{"bucket" => bucket}} when bucket != "safe-guarded" ->
        {:error,
         "ledger bucket for #{row["display"]} is #{inspect(bucket)}, expected safe-guarded"}

      {:ok, ledger_row} ->
        {file, line} = split_display(ledger_row["display"])
        source_lines = read_source_lines(file)
        live_row = %{"display" => "#{file}:#{line}", "expression" => row["expression"]}

        if guarded_correctly?(source_lines, live_row) do
          :ok
        else
          {:error,
           "no guard matching the assertion's expression was found above #{ledger_row["display"]}"}
        end
    end
  end

  defp failure_message([]), do: "no failures"

  defp failure_message(failures) do
    {first_row, first_reason} = List.first(failures)

    "#{length(failures)} row(s) failed the guard/expression-match check; first offending " <>
      "row #{inspect(first_row["display"])}: #{inspect(first_reason)}\n" <>
      "all failing displays: #{inspect(Enum.map(failures, fn {row, _} -> row["display"] end))}"
  end

  # ── The structural predicate (D-12.1) ───────────────────────────────────────────────────

  @doc false
  def guarded_correctly?(source_lines, row) do
    assertion_line = display_line(row["display"])

    with guard_start when not is_nil(guard_start) <-
           find_guard_start(source_lines, assertion_line),
         joined <- join_forward(source_lines, guard_start),
         argument when not is_nil(argument) <- extract_guard_argument(joined) do
      normalize_expression(argument) == normalize_expression(row["expression"])
    else
      _ -> false
    end
  end

  # Bounded backward scan (mirrors the classifier's find_backward/3): the NEAREST line above
  # the assertion, within @max_lookback lines, whose trimmed text opens a
  # `refute Enum.empty?(` call. Blank lines and any interior continuation lines of a
  # multi-line guard above it are transparently skipped by scanning line-by-line rather than
  # assuming any fixed offset.
  defp find_guard_start(lines, assertion_line) do
    floor = max(1, assertion_line - @max_lookback)

    if assertion_line - 1 < floor do
      nil
    else
      Enum.find((assertion_line - 1)..floor//-1, fn line_no ->
        text = Enum.at(lines, line_no - 1) || ""
        Regex.match?(@guard_start_regex, text)
      end)
    end
  end

  # Mirrors script/inventory_collection_assertions.exs's join_forward/3: joins `line_no` with
  # just enough of its following lines to balance its own parens/brackets/braces, so a guard
  # call `mix format` wrapped across several physical lines reads as one logical statement.
  defp join_forward(lines, line_no) do
    line_no
    |> Stream.iterate(&(&1 + 1))
    |> Enum.take(@max_join + 1)
    |> Enum.map(&(Enum.at(lines, &1 - 1) || ""))
    |> Enum.reduce_while({[], 0}, fn line, {acc, depth} ->
      opens = line |> String.graphemes() |> Enum.count(&(&1 in ["(", "[", "{"]))
      closes = line |> String.graphemes() |> Enum.count(&(&1 in [")", "]", "}"]))
      new_depth = depth + opens - closes
      acc = [line | acc]

      if new_depth <= 0, do: {:halt, {acc, new_depth}}, else: {:cont, {acc, new_depth}}
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.join(" ")
  end

  # Extracts the single argument of a joined `refute Enum.empty?(...)` statement via the same
  # paren-balanced capture the classifier's capture_first_arg/1 uses, so a nested call inside
  # the guard's own argument (e.g. `Enum.filter(coll, &(...))`) is captured whole rather than
  # truncated at its first internal close-paren.
  defp extract_guard_argument(joined_text) do
    case Regex.run(~r/refute\s+Enum\.empty\?\(/, joined_text, return: :index) do
      [{start, len}] ->
        after_idx = start + len
        remainder = binary_part(joined_text, after_idx, byte_size(joined_text) - after_idx)
        {argument, _rest} = capture_balanced(remainder, 1, [])
        argument

      nil ->
        nil
    end
  end

  defp capture_balanced(<<>>, _depth, acc),
    do: {acc |> Enum.reverse() |> IO.iodata_to_binary(), ""}

  defp capture_balanced(<<c::utf8, rest::binary>>, depth, acc) do
    char = <<c::utf8>>

    cond do
      char in ["(", "[", "{"] ->
        capture_balanced(rest, depth + 1, [char | acc])

      char in [")", "]", "}"] ->
        new_depth = depth - 1

        if new_depth == 0 do
          {acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}
        else
          capture_balanced(rest, new_depth, [char | acc])
        end

      true ->
        capture_balanced(rest, depth, [char | acc])
    end
  end

  # Mirrors script/inventory_collection_assertions.exs's normalize_expression/1 exactly
  # (collapse whitespace runs, trim, drop a trailing comma, trim again) — duplicated here
  # rather than required from the script, because requiring the script in-process also
  # executes its trailing CLI/System.halt call. This is a small pure-function mirror, not a
  # second copy of the row population D-18 forbids.
  defp normalize_expression(expr) do
    expr
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.trim_trailing(",")
    |> String.trim()
  end

  # ── Manifest / ledger loading ────────────────────────────────────────────────────────────

  defp load_manifest do
    @manifest_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp load_ledger_by_key do
    ledger =
      @ledger_path
      |> File.read!()
      |> Jason.decode!()

    Map.new(ledger["rows"], &{&1["key"], &1})
  end

  defp read_source_lines(relative_path) do
    relative_path
    |> then(&Path.join(File.cwd!(), &1))
    |> File.read!()
    |> String.split("\n")
  end

  defp split_display(display) do
    parts = String.split(display, ":")
    line = parts |> List.last() |> String.to_integer()
    file = parts |> Enum.drop(-1) |> Enum.join(":")
    {file, line}
  end

  defp display_line(display) do
    display |> String.split(":") |> List.last() |> String.to_integer()
  end
end
