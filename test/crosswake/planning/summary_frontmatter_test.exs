defmodule Crosswake.Planning.SummaryFrontmatterTest do
  use ExUnit.Case, async: true

  @summary_glob Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md")

  test "all phase summaries use requirements-completed: not bare requirements:" do
    summaries = Path.wildcard(@summary_glob)
    assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"

    for path <- summaries do
      fm = parse_frontmatter(File.read!(path))

      refute has_bare_requirements_key?(fm),
             "#{path} uses bare `requirements:` key — rename to `requirements-completed:`"
    end
  end

  test "all requirement IDs in requirements-completed: exist in REQUIREMENTS.md" do
    known_ids = parse_requirement_ids_from_requirements_md()
    summaries = Path.wildcard(@summary_glob)
    assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"

    for path <- summaries do
      fm = parse_frontmatter(File.read!(path))
      ids = extract_completed_ids(fm)

      for id <- ids do
        assert id in known_ids,
               "#{path} lists `#{id}` under requirements-completed: but `#{id}` is not in .planning/REQUIREMENTS.md"
      end
    end
  end

  # Extract frontmatter block (between opening and closing ---)
  # Uses \A anchor + multiline dotall to match only the FIRST frontmatter block.
  # Handles both \n and \r\n line endings.
  defp parse_frontmatter(content) do
    case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
      [fm] -> fm
      nil -> ""
    end
  end

  # Detect bare `requirements:` key (not `requirements-completed:`).
  # The pattern matches `requirements:` followed by space+[ (inline list) or
  # newline+indented-dash (multi-line list). It does NOT match `requirements-completed:`
  # because the character after `requirements` in that key is `-`, not `:`.
  defp has_bare_requirements_key?(frontmatter) do
    Regex.match?(~r/^requirements:[ \t]*(?:\[|\r?\n[ \t]+-)/m, frontmatter)
  end

  # Extract IDs from requirements-completed: handling BOTH inline [A, B] and
  # multi-line \n  - A shapes. The corpus has both: Phase 19/20 use inline,
  # Phase 23 uses multi-line (RESEARCH Finding 1).
  # Scope: only the requirements-completed: value, not subsequent YAML keys
  # (which may legitimately reference IDs like D-07 in affects:/patterns:).
  defp extract_completed_ids(frontmatter) do
    cond do
      inline =
          Regex.run(~r/^requirements-completed:[ \t]*\[([^\]]*)\]/m, frontmatter,
            capture: :all_but_first
          ) ->
        scan_ids(hd(inline))

      block =
          Regex.run(
            ~r/^requirements-completed:[ \t]*\r?\n((?:[ \t]+-[^\n]*\r?\n?)+)/m,
            frontmatter,
            capture: :all_but_first
          ) ->
        scan_ids(hd(block))

      true ->
        []
    end
  end

  defp scan_ids(text) do
    Regex.scan(~r/\b([A-Z]+-\d+)\b/, text)
    |> Enum.map(fn [_, id] -> id end)
    |> Enum.uniq()
  end

  # Parse bullet IDs from REQUIREMENTS.md.
  # Matches both checked [ ] and unchecked [x] bullets so the test does not
  # couple to completion status — only to existence of the requirement ID.
  defp parse_requirement_ids_from_requirements_md do
    Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")
    |> File.read!()
    |> then(fn content ->
      Regex.scan(~r/- \[[x ]\] \*\*([A-Z]+-\d+)\*\*/, content)
      |> Enum.map(fn [_, id] -> id end)
    end)
  end
end
