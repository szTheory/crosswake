defmodule Crosswake.Guides.AndroidClaimCeilingTest do
  @moduledoc """
  No Android column in a public guide may show evidence above the JVM hermetic ceiling (D-23).

  The test parses the markdown tables of the capability map, the parity ledger and the support
  matrix by header. Every body cell in a column headed exactly `Android evidence` or `Android`
  must be one of the labels up to `Crosswake.SupportMatrix.android_evidence_ceiling/0`, or one of
  the ledger's plain cells. Raising the ceiling is an ADR amendment, not an edit to this test.

  Network-free: it reads only checked-in guides.
  """

  use ExUnit.Case, async: true

  alias Crosswake.CapabilityMap
  alias Crosswake.SupportMatrix

  @capability_map "guides/capability_map.md"
  @parity_ledger "guides/parity_ledger.md"
  @support_matrix "guides/support_matrix.md"

  @android_headers ["Android evidence", "Android"]

  # Per-vector execution cells and the ledger's explicit non-claims. None of these asserts
  # evidence above the ceiling.
  @plain_cells [
    "JVM test executed",
    "ExUnit executed",
    "Swift test executed",
    "not applicable",
    "no consumer",
    "-"
  ]

  describe "guides stay at or below the ceiling" do
    for guide <- [@capability_map, @parity_ledger, @support_matrix] do
      test "#{guide} has no Android cell above the ceiling" do
        text = File.read!(unquote(guide))

        assert ceiling_violations(text) == [],
               "#{unquote(guide)}: Android cells above the JVM hermetic ceiling: " <>
                 inspect(ceiling_violations(text))
      end
    end
  end

  describe "floor" do
    test "the checks read real Android columns and the typed counts match the rendered counts" do
      map_tables = tables(File.read!(@capability_map))
      ledger_tables = tables(File.read!(@parity_ledger))

      assert Enum.any?(map_tables, &("Android evidence" in &1.header)),
             "the capability map has no table with an `Android evidence` column"

      assert Enum.any?(ledger_tables, fn table ->
               Enum.any?(table.header, &(&1 in @android_headers))
             end),
             "the parity ledger has no Android column"

      jvm_label = SupportMatrix.android_evidence_label(:jvm_hermetic)

      rendered_jvm_map_rows =
        map_tables
        |> Enum.filter(&("Android evidence" in &1.header))
        |> Enum.flat_map(&column_cells(&1, "Android evidence"))
        |> Enum.count(&(&1 == jvm_label))

      typed_jvm_rows =
        Enum.count(CapabilityMap.canonical(), &(&1.android_evidence == :jvm_hermetic))

      assert typed_jvm_rows > 0, "no typed capability row carries JVM hermetic proof"

      assert rendered_jvm_map_rows == typed_jvm_rows,
             "capability map renders #{rendered_jvm_map_rows} JVM hermetic rows, " <>
               "typed truth has #{typed_jvm_rows}"

      all_cells =
        for text <- [File.read!(@capability_map), File.read!(@parity_ledger)],
            table <- tables(text),
            header <- table.header,
            header in @android_headers,
            cell <- column_cells(table, header),
            do: cell

      assert jvm_label in all_cells,
             "`#{jvm_label}` appears in no Android column of the capability map or the ledger"
    end
  end

  describe "negative controls" do
    test "a fabricated emulator or device cell is a violation" do
      emulator = """
      | Capability | Android evidence |
      |------------|------------------|
      | bridge | emulator evidence |
      """

      device = """
      | Capability | Android evidence |
      |------------|------------------|
      | bridge | device evidence |
      """

      assert [%{cell: "emulator evidence"}] = ceiling_violations(emulator)
      assert [%{cell: "device evidence"}] = ceiling_violations(device)
    end

    test "a required table without an Android column is reported" do
      text = """
      | Capability | Proof |
      |------------|-------|
      | bridge | JVM hermetic proof |
      """

      assert [%{reason: :missing_android_column}] = ceiling_violations(text, require_column: true)
      assert ceiling_violations(text) == []
    end

    test "one mutated rendered cell in a copy of the capability map is caught" do
      original = File.read!(@capability_map)
      jvm_label = SupportMatrix.android_evidence_label(:jvm_hermetic)

      copy = replace_first_android_cell(original, jvm_label, "device evidence")

      if copy == original do
        raise "control did not change the copy: no Android cell holds #{jvm_label}"
      end

      assert copy != File.read!(@capability_map)
      assert ceiling_violations(original) == []
      assert [%{cell: "device evidence"}] = ceiling_violations(copy)
    end

    test "the typed validator raises above the ceiling" do
      assert_raise ArgumentError, fn -> SupportMatrix.validate_android_evidence!(:emulator) end
      assert_raise ArgumentError, fn -> SupportMatrix.validate_android_evidence!(:device) end
    end
  end

  # Allowed Android-column cells: every label up to the typed ceiling, plus the plain cells.
  defp allowed_cells do
    levels = SupportMatrix.android_evidence_levels()
    ceiling_index = Enum.find_index(levels, &(&1 == SupportMatrix.android_evidence_ceiling()))

    labels =
      levels
      |> Enum.take(ceiling_index + 1)
      |> Enum.map(&SupportMatrix.android_evidence_label/1)

    labels ++ @plain_cells
  end

  # Returns `[%{table:, row:, cell:}]` for every Android-column cell outside the allowed set.
  # With `require_column: true`, a table without an Android column adds
  # `%{table:, reason: :missing_android_column}`.
  defp ceiling_violations(text, opts \\ []) do
    allowed = allowed_cells()
    require_column? = Keyword.get(opts, :require_column, false)

    text
    |> tables()
    |> Enum.with_index()
    |> Enum.flat_map(fn {table, table_index} ->
      android_headers = Enum.filter(table.header, &(&1 in @android_headers))

      cond do
        android_headers == [] and require_column? ->
          [%{table: table_index, reason: :missing_android_column}]

        android_headers == [] ->
          []

        true ->
          for header <- android_headers,
              {cell, row_index} <- Enum.with_index(column_cells(table, header)),
              cell not in allowed,
              do: %{table: table_index, row: row_index, cell: cell}
      end
    end)
  end

  defp column_cells(table, header) do
    index = Enum.find_index(table.header, &(&1 == header))
    Enum.map(table.rows, &Enum.at(&1, index, ""))
  end

  # Walks lines outside code fences. A table starts at a `|` line followed by a separator line
  # of dashes and pipes; it ends at the first line that does not start with `|`.
  defp tables(text) do
    lines = String.split(text, "\n")
    {tables, _fence} = collect_tables(lines, false, [])
    Enum.reverse(tables)
  end

  defp collect_tables([], fence?, acc), do: {acc, fence?}

  defp collect_tables([line | rest], fence?, acc) do
    trimmed = String.trim(line)

    cond do
      String.starts_with?(trimmed, "```") ->
        collect_tables(rest, not fence?, acc)

      fence? ->
        collect_tables(rest, fence?, acc)

      String.starts_with?(line, "|") and match?([sep | _] when is_binary(sep), rest) and
          separator?(hd(rest)) ->
        {body, remaining} = Enum.split_while(tl(rest), &String.starts_with?(&1, "|"))
        table = %{header: split_cells(line), rows: Enum.map(body, &split_cells/1)}
        collect_tables(remaining, fence?, [table | acc])

      true ->
        collect_tables(rest, fence?, acc)
    end
  end

  defp separator?(line) do
    String.starts_with?(line, "|") and Regex.match?(~r/^\|[\s:|-]+\|?\s*$/, line) and
      String.contains?(line, "-")
  end

  # Splits on unescaped `|`; drops the leading and trailing empty fragments.
  defp split_cells(line) do
    line
    |> String.trim()
    |> String.replace("\\|", "\u0000")
    |> String.split("|")
    |> Enum.drop(1)
    |> drop_trailing_empty()
    |> Enum.map(fn cell ->
      cell |> String.replace("\u0000", "|") |> String.trim() |> String.replace("`", "")
    end)
  end

  defp drop_trailing_empty(cells) do
    case List.last(cells) do
      "" -> Enum.drop(cells, -1)
      _ -> cells
    end
  end

  # Rewrites the first body cell of an `Android evidence` column that equals `from`.
  defp replace_first_android_cell(text, from, to) do
    lines = String.split(text, "\n")
    do_replace(lines, nil, false, from, to, [])
  end

  defp do_replace([], _index, _done?, _from, _to, acc),
    do: acc |> Enum.reverse() |> Enum.join("\n")

  defp do_replace([line | rest], index, done?, from, to, acc) do
    cond do
      done? ->
        do_replace(rest, index, true, from, to, [line | acc])

      String.starts_with?(line, "|") and "Android evidence" in split_cells(line) and
          not separator?(line) ->
        idx = Enum.find_index(split_cells(line), &(&1 == "Android evidence"))
        do_replace(rest, idx, false, from, to, [line | acc])

      is_integer(index) and String.starts_with?(line, "|") and not separator?(line) ->
        cells = split_cells(line)

        if Enum.at(cells, index) == from do
          new_line = rewrite_cell(line, index, to)
          do_replace(rest, index, true, from, to, [new_line | acc])
        else
          do_replace(rest, index, false, from, to, [line | acc])
        end

      not String.starts_with?(line, "|") ->
        do_replace(rest, nil, false, from, to, [line | acc])

      true ->
        do_replace(rest, index, false, from, to, [line | acc])
    end
  end

  # Replaces the `index`th cell (0-based, after the leading pipe) while keeping other cells.
  defp rewrite_cell(line, index, to) do
    fragments = String.split(line, "|")
    # fragments[0] is the empty text before the leading pipe, cells start at 1.
    fragments
    |> List.update_at(index + 1, fn _ -> " #{to} " end)
    |> Enum.join("|")
  end
end
