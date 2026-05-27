---
phase: 24-reconciliation-traceability-hardening
reviewed: 2026-05-27T20:53:58Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - test/crosswake/planning/summary_frontmatter_test.exs
  - .github/workflows/phase23-proof.yml
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 24: Code Review Report

**Reviewed:** 2026-05-27T20:53:58Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the new ExUnit parity test enforcing the `requirements-completed:` SUMMARY frontmatter convention and the GitHub Actions workflow wiring it into the merge-blocking lane. The post-fix regex pair (inline `[A, B]` + multi-line block) correctly handles the current corpus, and the bare-`requirements:` detector correctly avoids matching `requirements-completed:` (the `-` boundary prevents collision with `:`). Hermeticity, async-safety, and shell-injection posture all look clean.

Two warning-level concerns reduce the strength of the parity guard: the test does **not** assert presence of `requirements-completed:` (so a SUMMARY that omits the key entirely passes silently), and the second test has no failing-case coverage (a malformed multi-line `requirements-completed:` block whose indentation breaks the regex would silently extract zero IDs and report "no unknown IDs"). Both are coverage gaps in a guard that is itself marketed as a coverage closure (RECN-01..03 traceability).

Info-level items are stylistic — minor consistency between compile-time and runtime cwd resolution, an uppercase `[X]` checkbox edge case in REQUIREMENTS.md parsing, and small duplication in the two test bodies.

## Warnings

### WR-01: Missing-key escape hatch — SUMMARY without `requirements-completed:` passes silently

**File:** `test/crosswake/planning/summary_frontmatter_test.exs:6-32`
**Issue:** Neither test asserts that `requirements-completed:` is present in each SUMMARY frontmatter.

- Test 1 only `refute`s the bare-`requirements:` key.
- Test 2 calls `extract_completed_ids/1`, which returns `[]` via the third `cond` arm (`true -> []`) when neither inline nor block regex matches.
- A SUMMARY file that omits `requirements-completed:` entirely (typo, copy-paste mistake, drift) therefore extracts zero IDs and asserts nothing.

This is the exact failure mode the phase is meant to defend against — a planning artifact that forgets to declare which requirement it closes. The post-merge incident noted in the prompt (ce19633) caught a regex bug; an analogous "field absent" regression would not be caught at all by the current shape.

`parse_frontmatter/1` also silently falls back to `""` when no `---` block is found (line 38-42), compounding the silence: a SUMMARY missing its YAML frontmatter entirely also passes.

**Fix:** Add a third assertion (either inline in test 2 or as a third `test` block) that requires every SUMMARY to declare the field:

```elixir
test "every phase summary declares requirements-completed:" do
  summaries = Path.wildcard(@summary_glob)
  assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"

  for path <- summaries do
    fm = parse_frontmatter(File.read!(path))

    assert fm != "",
           "#{path} has no YAML frontmatter block"

    assert Regex.match?(~r/^requirements-completed:[ \t]*(?:\[|\r?\n[ \t]+-)/m, fm),
           "#{path} is missing required `requirements-completed:` key"
  end
end
```

### WR-02: Multi-line block regex silently extracts zero IDs on indentation drift

**File:** `test/crosswake/planning/summary_frontmatter_test.exs:57-76`
**Issue:** The block-shape regex `^requirements-completed:[ \t]*\r?\n((?:[ \t]+-[^\n]*\r?\n?)+)/m` requires the bullets to start with one-or-more `[ \t]` (any amount of indentation). If a future SUMMARY uses zero-indentation bullets (a YAML lint mistake — `requirements-completed:\n- RECN-01`), neither the inline arm nor the block arm matches and the function returns `[]` via the `true -> []` fallback. The known-ID assertion in test 2 then has nothing to check and silently passes.

Combined with WR-01 (no presence assertion), this means **two distinct malformed shapes (key absent, key present with un-indented bullets) both pass the parity guard**. A defender that silently accepts ill-formed input is worse than one that loudly rejects, because reviewers stop scrutinizing the field.

**Fix:** Either tighten the fallback so an unmatched `requirements-completed:` raises, or assert that extraction produced at least one ID when the key is present:

```elixir
defp extract_completed_ids(frontmatter) do
  cond do
    inline = Regex.run(~r/^requirements-completed:[ \t]*\[([^\]]*)\]/m, frontmatter, capture: :all_but_first) ->
      scan_ids(hd(inline))

    block = Regex.run(~r/^requirements-completed:[ \t]*\r?\n((?:[ \t]+-[^\n]*\r?\n?)+)/m, frontmatter, capture: :all_but_first) ->
      scan_ids(hd(block))

    # Key present but neither shape matched — fail loudly instead of returning [].
    Regex.match?(~r/^requirements-completed:/m, frontmatter) ->
      raise "requirements-completed: is present but neither inline `[A, B]` nor multi-line `  - X` shape parsed"

    true ->
      []
  end
end
```

## Info

### IN-01: Inconsistent cwd resolution — compile-time vs runtime

**File:** `test/crosswake/planning/summary_frontmatter_test.exs:4, 88`
**Issue:** `@summary_glob` resolves `File.cwd!()` at compile time (module attribute), while `parse_requirement_ids_from_requirements_md/0` resolves `File.cwd!()` at runtime. With `mix test` from the project root this is fine, but the two paths can diverge in unusual invocation paths (custom Mix tasks, IEx-driven re-runs after `cd`).
**Fix:** Pick one. Either make both compile-time module attributes, or both runtime calls. Compile-time is fine for project tests; recommend `@requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")` next to `@summary_glob` for symmetry.

### IN-02: REQUIREMENTS.md ID parser is case-sensitive on `[x]`

**File:** `test/crosswake/planning/summary_frontmatter_test.exs:91`
**Issue:** Pattern `- \[[x ]\] \*\*([A-Z]+-\d+)\*\*` accepts only lowercase `x` (or space) in the checkbox. The current corpus uses lowercase, so this is not currently a bug; but a future hand-edit using uppercase `[X]` (common in some markdown editors / CommonMark renderers) would drop that requirement from `known_ids`, causing test 2 to falsely report the ID as "not in REQUIREMENTS.md" the next time a SUMMARY references it.
**Fix:** Broaden the character class:

```elixir
Regex.scan(~r/- \[[xX ]\] \*\*([A-Z]+-\d+)\*\*/, content)
```

### IN-03: Duplicate `assert summaries != []` guard

**File:** `test/crosswake/planning/summary_frontmatter_test.exs:8, 21`
**Issue:** Both tests independently check that the wildcard returned at least one path. Minor duplication; consider hoisting to a `setup` block or a small helper for clarity. Not a correctness issue.
**Fix:** Optional — extract to a helper or `setup_all`:

```elixir
setup_all do
  summaries = Path.wildcard(@summary_glob)
  assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"
  {:ok, summaries: summaries}
end
```

### IN-04: Workflow `workflow_dispatch` runs both lanes simultaneously

**File:** `.github/workflows/phase23-proof.yml:59, 118`
**Issue:** The merge-blocking job's `if:` includes `workflow_dispatch`, and the advisory job's `if:` also includes `workflow_dispatch`. A manual dispatch therefore triggers **both** jobs. This may be intentional (manual ad-hoc full-lane run), but is not documented in the workflow comments, which only explain the schedule/PR distinctions. A reviewer dispatching the workflow to check just the advisory lane will inadvertently spend macos-15 minutes on the merge-blocking job too.
**Fix:** Either document the intent inline, or add a workflow input (`workflow_dispatch.inputs.lane: merge-blocking | advisory | both`) and gate each job's `if:` on that input.

---

_Reviewed: 2026-05-27T20:53:58Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
