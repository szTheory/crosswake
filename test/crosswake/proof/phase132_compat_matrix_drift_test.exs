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
    - proof.compat_03.no_version_literal
    - proof.compat_03.no_registry_state_words
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @doc_path Path.join([File.cwd!(), "guides", "companion_compatibility.md"])
  @package_glob "packages/crosswake_*/mix.exs"
  @install_path "guides/install.md"
  @runbook_path "docs/COMPANION-PUBLISH-RUNBOOK.md"

  # A doc table row for a package looks like:
  #   | `crosswake_rindle` | `:rindle` | link | `~> 0.2` | ... |
  # We match a leading-pipe row whose first backticked cell is `crosswake_<name>`.
  @row_regex ~r/^\|\s*`(crosswake_\w+)`\s*\|/m

  test "both extracted companion manifests and READMEs match the current core floor" do
    expected_floor = expected_core_floor()

    for mix_exs_path <- extracted_companion_mix_files() do
      package = package_name(mix_exs_path)
      readme_path = Path.join(Path.dirname(mix_exs_path), "README.md")
      manifest = File.read!(mix_exs_path)
      readme = File.read!(readme_path)

      assert compatibility_surface_errors(manifest, readme, package, expected_floor) == []
    end
  end

  test "the companion package contract detects manifest-only and README-only floor drift" do
    expected_floor = expected_core_floor()
    manifest = File.read!("packages/crosswake_rulestead/mix.exs")
    readme = File.read!("packages/crosswake_rulestead/README.md")

    assert compatibility_surface_errors(
             String.replace(manifest, expected_floor, "~> 0.1", global: false),
             readme,
             "crosswake_rulestead",
             expected_floor
           ) == [:manifest_core_floor, :manifest_readme_core_floor]

    assert compatibility_surface_errors(
             manifest,
             String.replace(readme, expected_floor, "~> 0.1", global: false),
             "crosswake_rulestead",
             expected_floor
           ) == [:manifest_readme_core_floor]
  end

  test "the complete extracted-companion transaction matches install, matrix, and runbook truth" do
    expected_floor = expected_core_floor()
    guide = File.read!(@doc_path)
    install = File.read!(@install_path)
    runbook = File.read!(@runbook_path)

    assert readme_dependency_requirement(install, "crosswake") == expected_floor

    for mix_exs_path <- extracted_companion_mix_files() do
      package = package_name(mix_exs_path)
      manifest_floor = extract_crosswake_requirement(mix_exs_path)

      assert package_row_cell(guide, package, "Requires `crosswake`") == "`#{manifest_floor}`"

      assert runbook_floor(runbook, package) == manifest_floor
    end
  end

  test "the complete transaction rejects the old two-manifest-only patch" do
    expected_floor = expected_core_floor()
    guide = File.read!(@doc_path)
    install = File.read!(@install_path)
    runbook = File.read!(@runbook_path)

    stale_guide =
      Enum.reduce(extracted_companion_packages(), guide, fn package, text ->
        replace_package_row_floor(text, package, "~> 0.1")
      end)

    stale_install = String.replace(install, expected_floor, "~> 0.1", global: false)

    stale_runbook =
      Enum.reduce(extracted_companion_packages(), runbook, fn package, text ->
        replace_runbook_floor(text, package, "~> 0.1")
      end)

    refute readme_dependency_requirement(stale_install, "crosswake") == expected_floor

    for package <- extracted_companion_packages() do
      refute package_row_cell(stale_guide, package, "Requires `crosswake`") ==
               "`#{expected_floor}`"

      refute runbook_floor(stale_runbook, package) == expected_floor
    end
  end

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
    companion_mix_files = Path.wildcard(@package_glob)
    assert length(companion_mix_files) == 5

    for mix_exs_path <- companion_mix_files do
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
  # SC#5 — O(N) structural guard (D-07): the "no inter-companion columns"
  # invariant made real. Parse the header row, drop col 0 (`Hex Package`, whose
  # DATA rows legitimately name `crosswake_*` packages but whose HEADER cell is
  # `Hex Package`), and refute any remaining HEADER cell matching `crosswake_\w+`.
  # A future `Requires crosswake_sigra` header column must fail HERE, keeping the
  # matrix O(N) (companions depend on core only, never on each other).
  # ---------------------------------------------------------------------------

  test "no header column beyond col 1 names another companion package (O(N) guard)" do
    doc = File.read!(@doc_path)
    header_cells = header_row_cells(doc)

    assert is_list(header_cells) and length(header_cells) >= 2,
           ProofAssertions.stable_id_message(
             "proof.compat_03.no_inter_companion_columns",
             "the compat matrix header row must be locatable to enforce the O(N) column guard",
             "guides/companion_compatibility.md header row (line matching `| Hex Package | ... |`)",
             "could not locate a header row with >= 2 columns — the matrix header was reshaped or removed",
             "guides/companion_compatibility.md",
             "restore the `| Hex Package | Companion ID | Latest on Hex | Requires `crosswake` | Engine Dependency |` header",
             :merge_blocking
           )

    # Drop col 0 (`Hex Package`) — every column beyond it must be a per-companion
    # AXIS, never a per-companion COLUMN. A `crosswake_\w+` token in a header cell
    # beyond col 0 is an inter-companion column (e.g. "Requires crosswake_sigra").
    offending =
      header_cells
      |> Enum.drop(1)
      |> Enum.filter(&String.match?(&1, ~r/crosswake_\w+/))

    assert offending == [],
           ProofAssertions.stable_id_message(
             "proof.compat_03.no_inter_companion_columns",
             "no compat matrix header column beyond col 1 may name a specific companion package",
             "header cells (col 1..N) matched against ~r/crosswake_\\w+/",
             "header column(s) #{inspect(offending)} name a specific companion — the matrix must stay O(N) (companions depend on core only, never on each other)",
             "guides/companion_compatibility.md",
             "remove the inter-companion column; per-companion facts belong in the single `Requires `crosswake`` axis, not a new column",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC#6 — the matrix states no registry fact of its own (DOCS-02, D-10, D-11).
  # A copied version literal or a hand-kept registry-state word goes stale the
  # moment a release ships, so no table row may carry one; package presence is
  # read from the live registry (`mix crosswake.release.status --live`), never
  # pinned here. Each check has an injection control so it cannot pass vacuously.
  # ---------------------------------------------------------------------------

  test "no matrix table row carries a three-part version literal" do
    doc = File.read!(@doc_path)

    assert matrix_version_literals(doc) == [],
           ProofAssertions.stable_id_message(
             "proof.compat_03.no_version_literal",
             "the compat matrix must not carry a hand-copied package version",
             "three-part version literals in the matrix table rows",
             "matrix row(s) #{inspect(matrix_version_literals(doc))} carry a version literal that will drift from the registry",
             "guides/companion_compatibility.md",
             "remove the literal; the `Latest on Hex` link is the registry's own answer",
             :merge_blocking
           )
  end

  test "an injected version literal turns the matrix check red (control)" do
    doc = File.read!(@doc_path)
    injected = String.replace(doc, "`:rindle` |", "`:rindle` 0.1.0 |", global: false)

    refute injected == doc, "the injection must change the guide text"
    assert matrix_version_literals(injected) == [{"crosswake_rindle", "0.1.0"}]
  end

  test "version literal matching is whole-literal: two-part requirements stay legal" do
    row = "| `crosswake_x` | `:x` | link | `~> 0.2` | `{:x, \"~> 0.1\"}` |"
    doc = "| Hex Package | A |\n|---|---|\n" <> row <> "\n"

    assert matrix_version_literals(doc) == []

    assert matrix_version_literals(String.replace(doc, "`~> 0.2`", "0.2.11")) ==
             [{"crosswake_x", "0.2.11"}]
  end

  test "no matrix table row states a registry fact (unpublished, not yet, hexdocs)" do
    doc = File.read!(@doc_path)

    assert matrix_registry_state_words(doc) == [],
           ProofAssertions.stable_id_message(
             "proof.compat_03.no_registry_state_words",
             "the compat matrix must not state registry or docs-hosting state by hand",
             "`unpublished`, `not yet` and `hexdocs` in the matrix table rows (header included)",
             "matrix row(s) #{inspect(matrix_registry_state_words(doc))} state a registry fact nothing checks",
             "guides/companion_compatibility.md",
             "remove the wording; presence is checked by the recorded `mix crosswake.release.status --live` run",
             :merge_blocking
           )
  end

  test "an injected registry-state word turns the matrix check red (control)" do
    doc = File.read!(@doc_path)
    injected = String.replace(doc, "`:rindle` |", "`:rindle` not yet on hexdocs |", global: false)

    refute injected == doc, "the injection must change the guide text"

    assert [{"crosswake_rindle", _words}] = matrix_registry_state_words(injected)

    readded =
      String.replace(doc, "| Engine Dependency |", "| Engine Dependency | hexdocs |",
        global: false
      )

    refute readded == doc, "the header injection must change the guide text"
    assert matrix_registry_state_words(readded) != []
  end

  test "the matrix has exactly the 5 extracted companion rows, in any order (non-vacuity floor)" do
    doc = File.read!(@doc_path)
    expected = MapSet.new(Path.wildcard(@package_glob), &package_name/1)

    assert MapSet.size(expected) == 5
    assert matrix_rows_check(doc, expected) == :ok
  end

  test "the row-set check is a set equality, not an inclusion or a count (controls)" do
    doc = File.read!(@doc_path)

    two_package = MapSet.new(extracted_companion_packages())
    assert MapSet.size(two_package) == 2
    assert matrix_rows_check(doc, two_package) == {:error, :row_set_mismatch}

    expected = MapSet.new(Path.wildcard(@package_glob), &package_name/1)

    no_rows =
      doc
      |> String.split("\n")
      |> Enum.reject(&String.match?(&1, @row_regex))
      |> Enum.join("\n")

    refute no_rows == doc, "dropping the rows must change the guide text"
    assert matrix_rows_check(no_rows, expected) == {:error, :row_set_mismatch}
    assert matrix_rows_check("", expected) == {:error, :row_set_mismatch}

    # one row dropped: fewer than the 5 extracted companions
    one_short =
      doc
      |> String.split("\n")
      |> Enum.reject(&String.match?(&1, ~r/^\|\s*`crosswake_threadline`\s*\|/))
      |> Enum.join("\n")

    refute one_short == doc
    assert matrix_rows_check(one_short, expected) == {:error, :row_set_mismatch}
  end

  test "row order does not change the matrix verdict (control)" do
    doc = File.read!(@doc_path)
    expected = MapSet.new(Path.wildcard(@package_glob), &package_name/1)
    lines = String.split(doc, "\n")

    first = Enum.find_index(lines, &String.match?(&1, ~r/^\|\s*`crosswake_rulestead`\s*\|/))
    last = Enum.find_index(lines, &String.match?(&1, ~r/^\|\s*`crosswake_threadline`\s*\|/))

    reordered =
      lines
      |> List.replace_at(first, Enum.at(lines, last))
      |> List.replace_at(last, Enum.at(lines, first))
      |> Enum.join("\n")

    refute reordered == doc, "the reorder must change the guide text"
    assert matrix_rows_check(reordered, expected) == :ok
    assert matrix_version_literals(reordered) == []
    assert matrix_registry_state_words(reordered) == []
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
  #
  # TODO(core-1.0, D-09): when core reaches 1.0.0 a companion may declare a
  # COMPOUND requirement to span the major boundary, e.g. `~> 0.1 or ~> 1.0`.
  # That parses as an `{:or, _, [left, right]}` AST node in the do: position, not
  # a bare `req` binary, so this matcher will fall through to nil and surface as a
  # cryptic `version_mismatch` drift failure. Widen `extract_hex_req_from_if/1`
  # (and the doc-cell comparison in `doc_row_has_requirement?/3`) to accept the
  # `or`-constraint form at that point. Do NOT add `or`-parsing now — no companion
  # declares a compound requirement yet, and speculatively widening the matcher
  # would weaken the exact-literal drift guarantee for the single `~> 0.1` form.
  defp extract_hex_req_from_if({:if, _, [_cond, [do: {:crosswake, req}, else: _]]})
       when is_binary(req),
       do: req

  defp extract_hex_req_from_if(_), do: nil

  defp expected_core_floor do
    [_, major, minor] = Regex.run(~r/@version\s+"(\d+)\.(\d+)\.\d+"/, File.read!("mix.exs"))
    "~> #{major}.#{minor}"
  end

  defp extracted_companion_mix_files do
    ~w(crosswake_rulestead crosswake_rindle)
    |> Enum.map(&Path.join(["packages", &1, "mix.exs"]))
  end

  defp extracted_companion_packages do
    extracted_companion_mix_files() |> Enum.map(&package_name/1)
  end

  # The matrix table: every line from the `Hex Package` header to the first
  # non-table line (header and separator rows included).
  defp matrix_table_rows(doc) do
    doc
    |> String.split("\n")
    |> Enum.drop_while(&(not String.match?(&1, ~r/^\|.*Hex Package.*\|/)))
    |> Enum.take_while(&String.starts_with?(&1, "|"))
  end

  defp row_label(line) do
    line |> row_cells() |> List.first() |> to_string() |> String.trim("`")
  end

  # `{package, literal}` for every whole three-part version literal in a matrix
  # row. Whole-literal matching: `0.2.11` is one literal, `~> 0.2` is none.
  defp matrix_version_literals(doc) do
    for line <- matrix_table_rows(doc),
        [literal] <- Regex.scan(~r/\b\d+\.\d+\.\d+\b/, line) do
      {row_label(line), literal}
    end
  end

  # `{package, words}` for every matrix row (header included) that states
  # registry or docs-hosting state by hand.
  defp matrix_registry_state_words(doc) do
    for line <- matrix_table_rows(doc),
        words = List.flatten(Regex.scan(~r/unpublished|not yet|hexdocs/i, line)),
        words != [] do
      {row_label(line), words}
    end
  end

  # Order-independent set equality of the `crosswake_*` package rows against the
  # expected package set; an empty or short matrix is an error, not a pass.
  defp matrix_rows_check(doc, expected_packages) do
    packages =
      for line <- matrix_table_rows(doc),
          [_, pkg] <- [Regex.run(@row_regex, line)],
          do: pkg

    if packages != [] and length(packages) == MapSet.size(MapSet.new(packages)) and
         MapSet.new(packages) == expected_packages do
      :ok
    else
      {:error, :row_set_mismatch}
    end
  end

  defp compatibility_surface_errors(manifest, readme, package, expected_floor) do
    manifest_floor = extract_crosswake_requirement_from_source(manifest)
    readme_core_floor = readme_dependency_requirement(readme, "crosswake")
    companion_version = package_version(manifest)
    readme_companion_floor = readme_dependency_requirement(readme, package)

    []
    |> maybe_error(manifest_floor != expected_floor, :manifest_core_floor)
    |> maybe_error(readme_core_floor != manifest_floor, :manifest_readme_core_floor)
    |> maybe_error(
      readme_companion_floor != version_floor(companion_version),
      :independent_companion_version
    )
    |> maybe_error(
      not String.contains?(manifest, "{:crosswake, path: \"../..\"}"),
      :development_path_dependency
    )
    |> Enum.reverse()
  end

  defp extract_crosswake_requirement_from_source(source) do
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

  defp readme_dependency_requirement(readme, package) do
    case Regex.run(~r/\{:\Q#{package}\E,\s*"([^"]+)"\}/, readme) do
      [_, requirement] -> requirement
      _ -> nil
    end
  end

  defp package_version(manifest) do
    case Regex.run(~r/@version\s+"(\d+\.\d+\.\d+)"/, manifest) do
      [_, version] -> version
      _ -> nil
    end
  end

  defp version_floor(version) do
    case String.split(to_string(version), ".") do
      [major, minor, _patch] -> "~> #{major}.#{minor}"
      _ -> nil
    end
  end

  defp maybe_error(errors, true, error), do: [error | errors]
  defp maybe_error(errors, false, _error), do: errors

  defp package_row_cell(doc, package, header) do
    with cells when is_list(cells) <- header_row_cells(doc),
         index when is_integer(index) <- Enum.find_index(cells, &(&1 == header)),
         line when is_binary(line) <- package_row_line(doc, package) do
      line |> row_cells() |> Enum.at(index)
    else
      _ -> nil
    end
  end

  defp runbook_floor(runbook, package) do
    case Regex.run(~r/^\|\s*`#{Regex.escape(package)}`\s*\|\s*`([^`]+)`\s*\|$/m, runbook) do
      [_, floor] -> floor
      _ -> nil
    end
  end

  defp replace_package_row_floor(doc, package, floor) do
    Regex.replace(
      ~r/^(\|\s*`#{Regex.escape(package)}`\s*\|.*?\|\s*)`~> 0\.2`(\s*\|.*)$/m,
      doc,
      "\\1`#{floor}`\\2",
      global: false
    )
  end

  defp replace_runbook_floor(runbook, package, floor) do
    Regex.replace(
      ~r/^(\|\s*`#{Regex.escape(package)}`\s*\|\s*)`~> 0\.2`/m,
      runbook,
      "\\1`#{floor}`",
      global: false
    )
  end

  defp package_name(mix_exs_path) do
    mix_exs_path
    |> Path.dirname()
    |> Path.basename()
  end

  # ---------------------------------------------------------------------------
  # Doc-row parsing — key on the package name in column 1, anchored by the pinned
  # HTML-comment column contract (D-12). No markdown-parser dependency.
  # ---------------------------------------------------------------------------

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
    |> header_row_cells()
    |> then(fn
      cells when is_list(cells) ->
        Enum.find_index(cells, fn cell ->
          String.contains?(cell, "Requires") and String.contains?(cell, "crosswake")
        end)

      _ ->
        nil
    end)
  end

  # The trimmed cells of the matrix HEADER row, using the same
  # `^\|.*Hex Package.*\|` idiom `requires_crosswake_column_index/1` established.
  # Returns a list of trimmed cell strings, or nil if no header row is present.
  defp header_row_cells(doc) do
    doc
    |> String.split("\n")
    |> Enum.find(&String.match?(&1, ~r/^\|.*Hex Package.*\|/))
    |> case do
      nil -> nil
      line -> row_cells(line)
    end
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
