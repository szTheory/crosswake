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
  @remediation_row_fields ~w(key shape display enclosing expression)
  @remediation_note "This list is closed-world and frozen: it is the exact set of sites phase 170 rewrote, it will not grow to cover a site added later, and standing tree-wide enforcement is VACG-01's deferred job."

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
      Keyword.get(opts, :emit_remediation, false) ->
        emit_remediation(root, ledger_path)

      Keyword.get(opts, :emit_snapshot, false) ->
        scope = effective_scope(Keyword.get(opts, :scope), ledger_path)
        root |> rows(scope) |> render_snapshot(scope) |> IO.write()
        0

      true ->
        check(root, Keyword.get(opts, :scope), ledger_path)
    end
  end

  # `--emit-remediation`: projects the CURRENT committed ledger's `needs-fix` rows into the
  # closed-world remediation manifest (D-12.1). This reads the already-committed ledger rather
  # than rescanning the tree, because once guards are inserted those rows reclassify to
  # `safe-guarded` and a fresh scan would find nothing left to freeze — the manifest must be
  # generated BEFORE any guard lands.
  defp emit_remediation(root, ledger_path) do
    ledger_path
    |> File.read!()
    |> JSON.decode!()
    |> Map.get("rows", [])
    |> Enum.filter(&(&1["bucket"] == "needs-fix"))
    |> Enum.sort_by(&{&1["display"], &1["key"]})
    |> render_remediation(frozen_at(root))
    |> IO.write()

    0
  end

  defp frozen_at(root) do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: root)
    String.trim(sha)
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

  @doc """
  Deterministic text rendering of the closed-world remediation manifest (D-12.1). `rows` is the
  ledger's `needs-fix` subset, already sorted by `{display, key}`; `frozen_at` is the git SHA of
  HEAD at generation time. Row fields are a narrower projection than the full ledger row — no
  `bucket`/`rationale`, since by definition every row here is `needs-fix` until the guard lands.
  """
  def render_remediation(rows, frozen_at) do
    rows_json =
      rows
      |> Enum.map(&render_remediation_row/1)
      |> Enum.join(",\n")

    rows_block = if rows_json == "", do: "", else: "\n" <> rows_json <> "\n"

    """
    {
      "frozen_at": #{JSON.encode!(frozen_at)},
      "generator": #{JSON.encode!(@generator)},
      "note": #{JSON.encode!(@remediation_note)},
      "rows": [#{rows_block}]
    }
    """
  end

  defp render_remediation_row(row) do
    fields =
      @remediation_row_fields
      |> Enum.map(fn key -> ~s("#{key}": #{JSON.encode!(Map.fetch!(row, key))}) end)
      |> Enum.join(", ")

    "    {" <> fields <> "}"
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
  # Task 2 (170-02) discovery: inserting the mechanical `refute Enum.empty?` fix at every
  # `needs-fix` row and running the affected test files (per the plan's own instruction) turned
  # 8 of the 60 rows genuinely red — not because the guard was mis-inserted, but because each of
  # these 8 sites is a verified positive-path or negative-control test whose collection is
  # PERMANENTLY empty by the correctness of the code under test (a clean validation producing
  # zero errors, a stamp-matching drift check producing zero findings, a fully-retired legacy CI
  # context list, a script/swift positional-placeholder file producing zero privacy findings, and
  # a NOOP mirror-evaluation fixture with by-design empty push_arguments). No text-only heuristic
  # can distinguish "runtime-derived and never checked" from "runtime-derived and PROVEN always
  # empty by this test's own arrange step" — that distinction only surfaces by actually running
  # the guard against real code, exactly as D-14 anticipated. Recorded as manual overrides with
  # per-site citations, not widened heuristics; the closest-fitting existing bucket
  # (`safe-cardinality-pinned`) is reused because each site's cardinality (zero) is pinned by its
  # own fixture construction, not by a literal preceding `assert coll == [...]` this scanner's
  # `pin_line?/2` can see.
  #
  # CR-01 gap-closure (code review, 170-06): this table used to be keyed by `{file, line}` —
  # the one place in this whole scanner where line number, not content, decided a classification.
  # Every OTHER row in the ledger is keyed by a content hash of `{enclosing, normalized
  # expression, ordinal}` specifically so a moved-but-unchanged assertion produces zero diff
  # noise; keying this table by line number meant the exact opposite failure mode was possible
  # here — a moved-but-unchanged assertion could silently stop matching its override, reverting
  # silently to an unguarded classification with no test noticing (see 170-REVIEW.md CR-01). This
  # already manifested once: plan 170-03 had to repair two of these entries after line drift.
  # The table is now keyed by the SAME `row["key"]` content hash the rest of the ledger uses, so
  # an override tracks its call site through arbitrary line movement instead of breaking on it.
  # The `# file:line` comment above each entry is retained purely for human navigation — it plays
  # no role in the lookup.
  @manual_overrides %{
    # test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:92
    "sha256:cce3a74c3adbbdca" =>
      {"safe-cardinality-pinned",
       "assertion_ids (bound from the device report telemetry at line 67, `assert_receive {:device, %{assertion_ids: assertion_ids}}`) is asserted equal to a 19-item literal list immediately above (line 69); assertions and assertion_ids are the same underlying collection surfaced under two different field names on the same struct, which a text-only scanner cannot infer from identifier text alone — recorded as a manual override with this citation, not a heuristic match."},
    # test/crosswake/manifest/validator_test.exs:86 — rationale corrected by WR-03 gap-closure
    # (code review, 170-06): the previously recorded rationale claimed a "different, later
    # Validator.validate(manifest) call (same expression, same test, second occurrence)" in this
    # test. No such second call exists — the test has exactly one `Validator.validate(manifest)`
    # call. Re-verified against the real code path instead of re-asserting the old text.
    "sha256:e98dd963a0991078" =>
      {"safe-cardinality-pinned",
       "the test's own title (\"an empty unknown-blocking topology remains a valid non-promoting manifest section\") states the intent: an empty topology entries list combined with `:unknown_blocking` status legitimately validates with ZERO errors overall, not merely zero NT-MANIFEST-ROOT_REQUIRED errors — confirmed via `mix test test/crosswake/manifest/validator_test.exs:81`, `Validator.validate(manifest) == []`. This is the same positive-path \"the fixture validates cleanly\" shape as the sibling override immediately below (line 303): the `refute Enum.any?/2` check is permanently vacuous by the correctness of the code under test, not by an unguarded gap."},
    # test/crosswake/manifest/validator_test.exs:303
    "sha256:6bdd78c41b8ae37e" =>
      {"safe-cardinality-pinned",
       "`errors = Validator.validate(manifest_fixture())` validates the plain, unmutated, default-valid fixture — a clean manifest with no commerce declarations legitimately produces zero errors. Running the naively-inserted `refute Enum.empty?(errors)` here turned a real, currently-passing test red (confirmed via `mix test test/crosswake/manifest/validator_test.exs:302`, `errors == []`), proving this is a positive-path \"the default fixture validates cleanly\" check, not an unguarded defect."},
    # test/crosswake/manifest/validator_test.exs:455
    "sha256:fff91e7a3749f39f" =>
      {"safe-cardinality-pinned",
       "`errors = Crosswake.Policy.Validator.validate(routes, managed_routes)` validates two semantically-valid routes (\"reader\", \"capture\") — the test title (\"policy validation prefers family-first capability vocabulary\") and the later `invalid_route`/`invalid_errors` split confirm the FIRST `errors` binding is intentionally the zero-error case; a separate, deliberately-invalid route is validated afterward to prove the positive detection path. Confirmed via `mix test test/crosswake/manifest/validator_test.exs:434`, `errors == []`."},
    # test/crosswake/manifest/validator_test.exs:456
    "sha256:3398111c1c522c75" =>
      {"safe-cardinality-pinned",
       "same `errors` binding and same rationale as line 455 immediately above — this is the second of two `refute Enum.any?(errors, ...)` checks against the same permanently-empty positive-path result."},
    # test/crosswake/proof/phase165_ci_integrity_test.exs:154
    "sha256:b72e83b1cb382bec" =>
      {"safe-cardinality-pinned",
       "`manifest[\"legacy_compatibility_contexts\"]` is the retired-legacy-CI-context list; per PROJECT.md, CI was consolidated from twenty-seven legacy contexts to a single required `Crosswake CI` umbrella in v22.0 (Phase 165), so this list is genuinely, permanently empty going forward. Confirmed via `mix test`, the naive guard turned this real, currently-passing negative-control test red."},
    # test/crosswake/release_candidate/mirror_test.exs:227
    "sha256:d151d66128c154ab" =>
      {"safe-cardinality-pinned",
       "the loop iterates `[baseline_fixture(), candidate_fixture(), publish_fixture()]`; `baseline_fixture/0` sets `remote.main == remote.tag == split_sha` (identical ancestry, `dry_run.status: \"NOT RUN\"`) — the same NOOP-ancestry shape the file's own `equal` fixture (line ~160, and the phase 170 empty-input regression added immediately after it) asserts produces `push_arguments: []` explicitly. `Mirror.evaluate!/1` legitimately returns empty `push_arguments` for this specific fixture; confirmed via `mix test`, the naive guard turned this real, currently-passing test red. (Line renumbered by plan 170-03's own empty-input regression addition; content and citation unchanged from plan 170-02.)"},
    # test/crosswake/doctor/doctor_test.exs:1790
    "sha256:83f0be7bcec980d6" =>
      {"safe-cardinality-pinned",
       "the enclosing test is explicitly named a \"negative control\" (\"a stamp matching the current template_version produces no drift finding\") — `Doctor.native_controls_ui_findings/1` is asserted to return zero findings when the stamp already matches, by design. Confirmed via `mix test test/crosswake/doctor/doctor_test.exs:1774`, `findings == []`. (Line renumbered by plan 170-03's own empty-input regression addition; content and citation unchanged from plan 170-02.)"},
    # test/crosswake/planning/first_adopter_context_test.exs:281
    "sha256:36575ec13936cbc3" =>
      {"safe-cardinality-pinned",
       "the enclosing test's title (\"positional placeholders are preserved\") states the intent: `$1`/`$0.0` inside a `.sh`/`.swift` file are recognized as positional placeholders, not commercial amounts, so `scan_filesystem/2` legitimately returns zero violations for this fixture — the contrast case to the same test's earlier prose-file assertion, which DOES produce `privacy.commercial_detail` violations for `.md`/`.html`/`.svg` paths with identical dollar amounts. Confirmed via `mix test test/crosswake/planning/first_adopter_context_test.exs:267`, `scan_filesystem(root, []) == []`."}
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

  # CR-01 gap-closure (code review, 170-06): looked up by `row["key"]` — the same content hash
  # (`{enclosing, normalized expression, ordinal}`) every other row is keyed by — instead of the
  # previous `{file, line}` lookup, so an override tracks its call site through line movement
  # instead of silently stopping to match on it.
  defp apply_manual_override(row) do
    case Map.get(@manual_overrides, row["key"]) do
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
        # Trailing `["string key"]`/['string key'] subscripts are part of the root: without
        # them, `manifest["proof_leaves"]` and `manifest["legacy_compatibility_contexts"]`
        # would both collapse to the bare identifier "manifest" and a guard/pin on ONE key
        # would falsely cover every other bracket-indexed key on the same map.
        case Regex.run(
               ~r/^@?[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*(\[("[^"]*"|'[^']*')\])*/,
               trimmed
             ) do
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
      joined = join_forward(lines, line_no)

      if predicate.(joined) do
        {:halt, {line_no, String.trim(text)}}
      else
        {:cont, nil}
      end
    end)
  end

  # A guard/pin call that `mix format` wraps across several physical lines
  # (D-09 explicitly allows this: "wrap it and let mix format settle the
  # layout") reads as one logical statement for detection purposes even
  # though `guard_line?`/`pin_line?` test a single string. This joins `line_no`
  # with just enough of its FOLLOWING lines to balance its own parens/brackets
  # before the predicate ever sees it — a single-line call balances on its own
  # line and this is a no-op, so it changes nothing for the common case.
  # Bounded to 10 extra lines so an unrelated later statement can never be
  # absorbed by a call this scanner failed to close.
  defp join_forward(lines, line_no, max_extra \\ 10) do
    line_no
    |> Stream.iterate(&(&1 + 1))
    |> Enum.take(max_extra + 1)
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

  # `\b` only fires at a word/non-word transition. A root ending in `]` (a bracket-string
  # subscript like `manifest["proof_leaves"]`) has no such transition at its own close, so a
  # literal `\b` suffix would never match — only add the boundary marker on whichever edge of
  # the root is actually a word character.
  defp root_word_boundary?(line, root) do
    leading = if Regex.match?(~r/^[a-zA-Z0-9_@]/, root), do: "\\b", else: ""
    trailing = if Regex.match?(~r/[a-zA-Z0-9_]$/, root), do: "\\b", else: ""
    Regex.match?(Regex.compile!(leading <> Regex.escape(root) <> trailing), line)
  end

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

        # CR-01 gap-closure (code review, 170-06): a key present on both sides used to be
        # considered a match with no further inspection — so a row whose CONTENT changed (most
        # importantly its `bucket`) while its key stayed the same was invisible to this check.
        # This is the completeness gap `@manual_overrides` used to be exposed to via `{file,
        # line}` keying (now fixed separately by content-hash keying) and, more generally, is
        # exactly the kind of check-that-asserts-nothing this phase exists to eliminate. For
        # every key present in BOTH snapshots, compare the full row — not just its presence.
        mismatched_keys =
          MapSet.intersection(live_keys, committed_keys)
          |> Enum.filter(fn key ->
            Map.fetch!(live_by_key, key) != Map.fetch!(committed_by_key, key)
          end)
          |> MapSet.new()

        if MapSet.size(unclassified_keys) == 0 and MapSet.size(orphan_keys) == 0 and
             MapSet.size(mismatched_keys) == 0 do
          IO.puts(
            "[crosswake] OK: #{length(committed_rows)} classified collection-assertion site(s), ledger matches the live tree exactly."
          )

          0
        else
          IO.puts(
            "[crosswake] FAIL: the committed classification snapshot has #{MapSet.size(unclassified_keys)} site(s) not yet classified, #{MapSet.size(orphan_keys)} orphan row(s), and #{MapSet.size(mismatched_keys)} row(s) whose content has drifted from the live tree."
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

          mismatched_keys
          |> Enum.map(fn key ->
            {Map.fetch!(committed_by_key, key), Map.fetch!(live_by_key, key)}
          end)
          |> Enum.sort_by(fn {committed_row, _live_row} -> committed_row["display"] end)
          |> Enum.each(fn {committed_row, live_row} ->
            diffs =
              committed_row
              |> Map.keys()
              |> Enum.filter(fn field ->
                Map.get(committed_row, field) != Map.get(live_row, field)
              end)
              |> Enum.map(fn field ->
                "#{field}: committed=#{inspect(Map.get(committed_row, field))} live=#{inspect(Map.get(live_row, field))}"
              end)
              |> Enum.join("; ")

            IO.puts(
              "[crosswake]   mismatched: #{committed_row["display"]} (#{committed_row["key"]}) — #{diffs}"
            )
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
        emit_remediation: false,
        check: false
      })

  defp parse([], acc), do: acc
  defp parse(["--root", path | rest], acc), do: parse(rest, %{acc | root: path})
  defp parse(["--scope", glob | rest], acc), do: parse(rest, %{acc | scope: glob})
  defp parse(["--ledger", path | rest], acc), do: parse(rest, %{acc | ledger: path})
  defp parse(["--emit-snapshot" | rest], acc), do: parse(rest, %{acc | emit_snapshot: true})

  defp parse(["--emit-remediation" | rest], acc),
    do: parse(rest, %{acc | emit_remediation: true})

  defp parse(["--check" | rest], acc), do: parse(rest, %{acc | check: true})
  defp parse([_unrecognized | rest], acc), do: parse(rest, acc)
end

cli = Crosswake.CollectionAssertionInventory.CLI.parse(System.argv())

run_opts =
  [emit_snapshot: cli.emit_snapshot, emit_remediation: cli.emit_remediation]
  |> then(fn opts -> if cli.scope, do: Keyword.put(opts, :scope, cli.scope), else: opts end)
  |> then(fn opts ->
    if cli.ledger, do: Keyword.put(opts, :ledger_path, cli.ledger), else: opts
  end)

System.halt(Crosswake.CollectionAssertionInventory.run(cli.root, run_opts))
