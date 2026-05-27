# Phase 25: Address Tech Debt — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (2 modified, 2 new)
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/20-entitlement-lifecycle-semantics/20-VERIFICATION.md` | planning-artifact | n/a (one-line delete) | Self (read-verify-delete) | exact |
| `test/crosswake/planning/summary_frontmatter_test.exs` | test | file-I/O + transform | `test/crosswake/support_matrix/renderer_test.exs` | role-match (same parity-test idiom) |
| `.planning/phases/25-.../25-01-SUMMARY.md` | planning-artifact (summary) | n/a (new file) | `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` | exact (inline `requirements-completed: []` shape) |
| `.planning/phases/25-.../25-02-SUMMARY.md` | planning-artifact (summary) | n/a (new file) | `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` | exact (inline `requirements-completed: []` shape) |

---

## Pattern Assignments

### `.planning/phases/20-entitlement-lifecycle-semantics/20-VERIFICATION.md` (planning-artifact, one-line delete)

**Analog:** Self — read line 61 and 63 directly; no structural pattern to copy.

**Target state confirmed** (lines 59–63, full `## Final Determination` section):
```
## Final Determination

Phase 20 goal is achieved. All required ENTL-01, ENTL-02, and ENTL-03 semantics are implemented with runtime fail-closed evidence-source enforcement and regression coverage.

Phase 20 goal is mostly implemented, but not fully achieved due to unresolved ENTL-03 runtime fail-closed enforcement gap for invalid evidence source values.
```

**What to do:** Delete line 63 only. The file currently ends at line 64 (blank after the sentence). After the delete, the file ends at line 62 (the kept sentence at line 61 becomes the last non-blank line). Do not alter line 61, the `## Final Determination` heading, any other section, or the frontmatter.

**Resulting final section after delete:**
```
## Final Determination

Phase 20 goal is achieved. All required ENTL-01, ENTL-02, and ENTL-03 semantics are implemented with runtime fail-closed evidence-source enforcement and regression coverage.
```

---

### `test/crosswake/planning/summary_frontmatter_test.exs` (test, file-I/O + transform)

**Analog:** `test/crosswake/support_matrix/renderer_test.exs` — canonical "rendered artifact stays in sync with canonical truth" idiom. All parity tests in this project use `async: true`, assert corpus non-empty before iterating, and name the failing path in every assertion message.

**Current file structure** (lines 1–95 — full file, 95 lines):

Module + compile-time glob attribute (lines 1–4):
```elixir
defmodule Crosswake.Planning.SummaryFrontmatterTest do
  use ExUnit.Case, async: true

  @summary_glob Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md")
```

Test 1 — bare-key detector (lines 6–16):
```elixir
  test "all phase summaries use requirements-completed: not bare requirements:" do
    summaries = Path.wildcard(@summary_glob)
    assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"

    for path <- summaries do
      fm = parse_frontmatter(File.read!(path))

      refute has_bare_requirements_key?(fm),
             "#{path} uses bare `requirements:` key — rename to `requirements-completed:`"
    end
  end
```

Test 2 — known-ID cross-reference (lines 18–32):
```elixir
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
```

`parse_frontmatter/1` helper (lines 37–42):
```elixir
  defp parse_frontmatter(content) do
    case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
      [fm] -> fm
      nil -> ""
    end
  end
```

`extract_completed_ids/1` — current form (lines 57–76):
```elixir
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
```

`parse_requirement_ids_from_requirements_md/0` — current form (lines 87–94):
```elixir
  defp parse_requirement_ids_from_requirements_md do
    Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")
    |> File.read!()
    |> then(fn content ->
      Regex.scan(~r/- \[[x ]\] \*\*([A-Z]+-\d+)\*\*/, content)
      |> Enum.map(fn [_, id] -> id end)
    end)
  end
```

**Four changes to make (D-03, D-06, D-08, D-09):**

**Change 1 — D-08: Add `@requirements_path` compile-time attribute** (insert after line 4):
```elixir
  @requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")
```

**Change 2 — D-03/WR-01: Add third test** (insert after test 2, before the first `defp`):
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
Source: `24-REVIEW.md` lines 49–63 (canonical WR-01 fix snippet). The assertion `fm != ""` also catches the compounding-silence case from `parse_frontmatter/1` returning `""` on missing frontmatter.

**Change 3 — D-06/WR-02: Tighten `extract_completed_ids/1`** (replace lines 57–76):
```elixir
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

      # Key present but neither shape matched — fail loudly instead of returning [].
      Regex.match?(~r/^requirements-completed:/m, frontmatter) ->
        raise "requirements-completed: is present but neither inline `[A, B]` nor multi-line `  - X` shape parsed"

      true ->
        []
    end
  end
```
Source: `24-REVIEW.md` lines 76–92 (canonical WR-02 fix snippet). The raise message must name the offending shape; CONTEXT.md Claude's Discretion allows exact wording as long as the message names what was attempted. The inline arm `[^\]]*` already matches empty `[]` — the raise branch is never reached for `requirements-completed: []`.

**Change 4 — D-09/IN-02: Widen checkbox character class in `parse_requirement_ids_from_requirements_md/0`** (line 91, replace `[x ]` with `[xX ]`):
```elixir
      Regex.scan(~r/- \[[xX ]\] \*\*([A-Z]+-\d+)\*\*/, content)
```
Source: `24-REVIEW.md` line 109 (canonical IN-02 fix snippet).

**Also update `parse_requirement_ids_from_requirements_md/0` to use `@requirements_path`** (line 88, replace the runtime `Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")` with the module attribute):
```elixir
  defp parse_requirement_ids_from_requirements_md do
    @requirements_path
    |> File.read!()
    |> then(fn content ->
      Regex.scan(~r/- \[[xX ]\] \*\*([A-Z]+-\d+)\*\*/, content)
      |> Enum.map(fn [_, id] -> id end)
    end)
  end
```

---

### `.planning/phases/25-.../25-01-SUMMARY.md` (planning-artifact, new)

**Analog:** `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` — inline `requirements-completed: [COMM-04, COMM-05]` shape. The empty-list variant `requirements-completed: []` is the canonical tech-debt shape per D-04.

**Frontmatter shape to copy from** (`19-01-SUMMARY.md` lines 1–43):
- Opens with `---`
- Key-value YAML: `phase:`, `plan:`, `subsystem:`, `tags:`, other descriptive keys
- `requirements-completed: [COMM-04, COMM-05]` — inline bracket form on a single line
- Closes with `---`
- Followed by `# Phase N Plan NN: ... Summary` heading and prose body

**Required frontmatter for 25-01-SUMMARY.md:**
```yaml
---
phase: 25-address-tech-debt-phase-20-verification-text-phase-24-parity
plan: 01
subsystem: planning-artifacts
tags: [tech-debt, doc-fix, verification-text]
requirements-completed: []
---
```
The `requirements-completed: []` inline empty-list is mandatory per D-04. No multi-line block form. No bare key. No null value.

**Multi-line shape reference** (for contrast — do NOT use for tech-debt SUMMARYs):
`24-01-SUMMARY.md` lines 6–9:
```yaml
requirements-completed:
  - RECN-01
  - RECN-02
  - RECN-03
```

---

### `.planning/phases/25-.../25-02-SUMMARY.md` (planning-artifact, new)

**Analog:** Same as 25-01 — `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` inline shape.

**Required frontmatter for 25-02-SUMMARY.md:**
```yaml
---
phase: 25-address-tech-debt-phase-20-verification-text-phase-24-parity
plan: 02
subsystem: planning-artifacts
tags: [tech-debt, parity-test, hardening, wr-01, wr-02]
requirements-completed: []
---
```

---

## Shared Patterns

### Async Parity Test Posture
**Source:** `test/crosswake/planning/summary_frontmatter_test.exs` line 2 + `test/crosswake/support_matrix/renderer_test.exs` line 1
**Apply to:** The test file being modified (confirm it retains `async: true`)
```elixir
use ExUnit.Case, async: true
```
All parity tests in this codebase use `async: true`. The hardened test must preserve this.

### Corpus Non-Empty Guard Before Iteration
**Source:** `test/crosswake/planning/summary_frontmatter_test.exs` lines 8, 21
**Apply to:** The new third test block (D-03)
```elixir
summaries = Path.wildcard(@summary_glob)
assert summaries != [], "expected SUMMARY.md files at #{@summary_glob}"
```
Every test that iterates over the wildcard result asserts the result is non-empty first, naming the glob path in the message. The third test must follow the same guard pattern.

### Path-in-Message Failure Clarity
**Source:** `test/crosswake/planning/summary_frontmatter_test.exs` lines 13–14, 28–29
**Apply to:** All assertions inside the per-path `for` loop in the new third test
```elixir
assert ...,
       "#{path} is missing required `requirements-completed:` key"
```
Every assertion that evaluates per-file includes the file `path` interpolated into the message. This is the established idiom — a failing test names the offending file without requiring a stack trace to locate it.

### Compile-Time Module Attribute for Filesystem Paths
**Source:** `test/crosswake/planning/summary_frontmatter_test.exs` line 4
**Apply to:** The new `@requirements_path` attribute (D-08)
```elixir
@summary_glob Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md")
```
`File.cwd!()` is called at compile time inside a module attribute. `@requirements_path` must use the identical pattern for symmetry — not a runtime `Path.join` call inside the function body.

### Loud-Failure Over Silent-Acceptance (Raise in Helper)
**Source:** `24-REVIEW.md` lines 84–86 (WR-02 fix snippet)
**Apply to:** `extract_completed_ids/1` third `cond` arm
```elixir
    Regex.match?(~r/^requirements-completed:/m, frontmatter) ->
      raise "requirements-completed: is present but neither inline `[A, B]` nor multi-line `  - X` shape parsed"
```
The raise fires at helper level (D-07), not test level. The helper has exactly one caller today; this protects all future callers. The `true -> []` fallback that follows only fires when the key is genuinely absent.

---

## No Analog Found

None. All four files have direct analogs in the codebase.

---

## Metadata

**Analog search scope:** `.planning/phases/`, `test/crosswake/planning/`, `test/crosswake/support_matrix/`, `24-REVIEW.md`
**Files scanned:** 6 analog reads + 1 target read
**Existing SUMMARY corpus size:** 16 files across phases 19–24
**Pattern extraction date:** 2026-05-27
