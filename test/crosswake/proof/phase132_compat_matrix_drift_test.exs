defmodule Crosswake.Proof.Phase132CompatMatrixDriftTest do
  @moduledoc """
  Merge-blocking drift test for COMPAT-03.

  Asserts that every companion's declared `{:crosswake, "~> X.Y"}` Hex requirement
  (extracted from `crosswake_dep/0` in `packages/crosswake_*/mix.exs` via AST parse)
  matches the corresponding row in `guides/companion_compatibility.md`. Bidirectional:
  also asserts no phantom doc rows exist without a real package.

  The companion `mix.exs` is the source of truth; the doc is human-readable. Drift in
  either direction is a merge-blocking failure (code-canonical-with-drift-test, the
  Keathley/Oban idiom).

  Untagged. `async: true` — read-only source and doc file access; no Application state
  mutation. Must NOT carry `:requires_example_host` or `:engine_present` tags.

  Stable ids (COMPAT-03):
    - proof.compat_03.doc_exists
    - proof.compat_03.non_vacuity
    - proof.compat_03.matrix_drift.<pkg>.missing_from_doc
    - proof.compat_03.matrix_drift.<pkg>.version_mismatch
    - proof.compat_03.matrix_drift.<pkg>.phantom_doc_row
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @doc_path Path.join([File.cwd!(), "guides", "companion_compatibility.md"])
  @package_glob "packages/crosswake_*/mix.exs"

  # ---------------------------------------------------------------------------
  # SC#1 — the doc exists (distinct failure from a row being wrong)
  # ---------------------------------------------------------------------------

  test "companion_compatibility.md doc exists" do
    assert File.exists?(@doc_path),
           ProofAssertions.stable_id_message(
             "proof.compat_03.doc_exists",
             "guides/companion_compatibility.md must exist as the human-readable compat matrix",
             "File.exists?(guides/companion_compatibility.md)",
             "companion_compatibility.md is missing — the COMPAT-02 matrix doc was never authored",
             "guides/companion_compatibility.md",
             "author guides/companion_compatibility.md with one row per companion (COMPAT-02)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC#2 — non-vacuity guard: the per-package loop must iterate >= 2 packages,
  # so an empty/single glob can never produce a vacuous pass (Pitfall 3, D-13).
  # ---------------------------------------------------------------------------

  test "at least two companion packages exist (non-vacuity guard)" do
    count = length(Path.wildcard(@package_glob))

    assert count >= 2,
           ProofAssertions.stable_id_message(
             "proof.compat_03.non_vacuity",
             "the drift test must compare >= 2 companion packages to avoid a vacuous pass",
             "Path.wildcard(packages/crosswake_*/mix.exs)",
             "found #{count} companion package(s) — fewer than the 2 required for a real drift comparison",
             @package_glob,
             "confirm packages/crosswake_rulestead and packages/crosswake_rindle both have a mix.exs",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC#3 — forward parity: every companion mix.exs crosswake requirement appears
  # in the doc with the EXACT same literal (no substring/semver equivalence, D-13).
  # ---------------------------------------------------------------------------

  test "every companion mix.exs crosswake requirement matches the doc" do
    doc = File.read!(@doc_path)

    for mix_exs_path <- Path.wildcard(@package_glob) do
      pkg = package_name(mix_exs_path)
      req = extract_crosswake_requirement(mix_exs_path)

      assert is_binary(req),
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.version_mismatch",
               "crosswake_dep/0 in #{pkg} must declare a {:crosswake, req} Hex requirement",
               "AST parse of #{mix_exs_path} crosswake_dep/0",
               "could not extract a crosswake requirement literal from #{pkg} — crosswake_dep/0 was refactored",
               mix_exs_path,
               "restore the `if ..., do: {:crosswake, \"~> X.Y\"}, else: {:crosswake, path: ...}` shape in crosswake_dep/0",
               :merge_blocking
             )

      assert doc_has_package_row?(doc, pkg),
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.missing_from_doc",
               "#{pkg} must have a row in the compat matrix",
               "guides/companion_compatibility.md table rows",
               "#{pkg} is declared as a package but has no `#{pkg}` row in the compat matrix doc",
               "guides/companion_compatibility.md",
               "add a `#{pkg}` row to the matrix table naming its Requires crosswake cell",
               :merge_blocking
             )

      assert doc_row_has_requirement?(doc, pkg, req),
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.version_mismatch",
               "the #{pkg} doc row must name the exact crosswake requirement #{inspect(req)}",
               "guides/companion_compatibility.md #{pkg} Requires crosswake cell",
               "#{pkg} declares {:crosswake, #{inspect(req)}} in mix.exs but the doc row does not contain #{inspect(req)}",
               "guides/companion_compatibility.md",
               "set the #{pkg} Requires crosswake cell to the verbatim literal #{req}",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # SC#4 — reverse parity: no phantom doc rows. Every `crosswake_*` row in the doc
  # must map to a real packages/<pkg>/mix.exs.
  # ---------------------------------------------------------------------------

  test "no phantom doc rows" do
    doc = File.read!(@doc_path)
    real_packages = MapSet.new(Path.wildcard(@package_glob), &package_name/1)

    for pkg <- doc_package_rows(doc) do
      assert MapSet.member?(real_packages, pkg),
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.phantom_doc_row",
               "every compat matrix row must map to a real companion package",
               "guides/companion_compatibility.md table rows vs Path.wildcard(packages/crosswake_*/mix.exs)",
               "the doc names a `#{pkg}` row but packages/#{pkg}/mix.exs does not exist",
               "guides/companion_compatibility.md",
               "remove the phantom `#{pkg}` row or add packages/#{pkg}/mix.exs",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # AST extraction — MUST parse, not grep. A bare grep on `crosswake` returns BOTH
  # the Hex requirement and the `path: "../.."` dev branch (Pitfall 1).
  # ---------------------------------------------------------------------------

  defp extract_crosswake_requirement(mix_exs_path) do
    source = File.read!(mix_exs_path)
    {:ok, ast} = Code.string_to_quoted(source, [])

    {_ast, req} =
      Macro.prewalk(ast, nil, fn
        {:defp, _, [{:crosswake_dep, _, _}, [do: if_expr]]} = node, _acc ->
          {node, extract_hex_req_from_if(if_expr)}

        node, acc ->
          {node, acc}
      end)

    req
  end

  # The do: keyword value of the env-conditional `if` is the Hex 2-tuple literal
  # `{:crosswake, "~> 0.1"}`; the else: branch is the `path:` dev dep we ignore.
  # A fallthrough returning nil makes a refactored resolver fail loudly (the
  # version_mismatch case fires) rather than passing silently.
  defp extract_hex_req_from_if({:if, _, [_cond, [do: {:crosswake, req}, else: _]]})
       when is_binary(req),
       do: req

  defp extract_hex_req_from_if(_), do: nil

  defp package_name(mix_exs_path) do
    mix_exs_path
    |> Path.dirname()
    |> Path.basename()
  end

  # ---------------------------------------------------------------------------
  # Doc-row parsing — key on the package name in column 1, anchored by the pinned
  # HTML-comment column contract (D-12). No markdown-parser dependency.
  # ---------------------------------------------------------------------------

  # A doc table row for a package looks like:
  #   | `crosswake_rindle` | `:rindle` | `0.1.0` | `~> 0.1` | ... |
  # We match a leading-pipe row whose first backticked cell is `crosswake_<name>`.
  @row_regex ~r/^\|\s*`(crosswake_\w+)`\s*\|/m

  defp doc_package_rows(doc) do
    @row_regex
    |> Regex.scan(doc)
    |> Enum.map(fn [_full, pkg] -> pkg end)
  end

  defp doc_has_package_row?(doc, pkg) do
    pkg in doc_package_rows(doc)
  end

  # Assert the package's row names the exact requirement in the DEDICATED
  # "Requires `crosswake`" cell — NOT anywhere on the row. The Engine Dependency
  # cell also contains a `~> 0.1` literal (e.g. `{:rulestead, "~> 0.1", ...}`), so
  # a whole-line String.contains? would pass even when the requirement cell drifts.
  # We resolve the column index from the pinned HTML-comment contract (D-12) and
  # match the exact cell content (reject substring/semver-equivalence, D-13).
  defp doc_row_has_requirement?(doc, pkg, req) do
    with line when is_binary(line) <- package_row_line(doc, pkg),
         idx when is_integer(idx) <- requires_crosswake_column_index(doc),
         cell when is_binary(cell) <- Enum.at(row_cells(line), idx) do
      # Cells are wrapped in backticks in the matrix house-style; compare the
      # backtick-stripped cell to the exact requirement literal.
      String.trim(cell) == "`#{req}`" or String.trim(cell) == req
    else
      _ -> false
    end
  end

  # Locate the zero-based column index of the "Requires `crosswake`" header so the
  # requirement check keys on the named column, not a fragile absolute index. The
  # pinned HTML comment above the table names this cell as the contract anchor.
  defp requires_crosswake_column_index(doc) do
    doc
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      if String.match?(line, ~r/^\|.*Hex Package.*\|/) do
        line
        |> row_cells()
        |> Enum.find_index(fn cell ->
          String.contains?(cell, "Requires") and String.contains?(cell, "crosswake")
        end)
      end
    end)
  end

  defp package_row_line(doc, pkg) do
    doc
    |> String.split("\n")
    |> Enum.find(fn line ->
      String.match?(line, ~r/^\|\s*`#{Regex.escape(pkg)}`\s*\|/)
    end)
  end

  # Split a pipe-delimited markdown row into trimmed cell strings, dropping the
  # empty leading/trailing fragments produced by the bounding pipes.
  defp row_cells(line) do
    line
    |> String.trim()
    |> String.trim_leading("|")
    |> String.trim_trailing("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end
end
