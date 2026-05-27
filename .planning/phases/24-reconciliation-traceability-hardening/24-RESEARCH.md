# Phase 24: Reconciliation Traceability Hardening - Research

**Researched:** 2026-05-27
**Domain:** Planning artifact normalization, ExUnit parity testing, YAML frontmatter, append-only audit docs
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Planning artifacts are first-class proof — append-only audit evidence, in-place requirement status flips, and one deterministic merge-blocking parity test.
- **D-02:** Rename `requirements:` → `requirements-completed:` in `21-01-SUMMARY.md` and `21-02-SUMMARY.md`. Preserve list contents exactly.
- **D-03:** Do NOT sweep other phase summaries. Scope is Phase 21 only.
- **D-04:** Flip `- [ ]` to `- [x]` for RECN-01/02/03 bullets. Keep them in the existing `Reconciliation Example` subsection — no `### Validated` subsection.
- **D-05:** Traceability table cells for RECN-01/02/03: phase column → `Phase 21 (validated); Phase 24 (traceability normalized)`, status column → `Complete`. Both literal substrings `Phase 21` AND `Phase 24` MUST appear in same cell.
- **D-06:** No narrative prose explaining the validated-in-21-normalized-in-24 distinction.
- **D-07:** Append `## Re-Audit (Phase 24)` section to `v3.2-MILESTONE-AUDIT.md`. Add `reaudits:` YAML list to frontmatter; leave `status: gaps_found` unchanged.
- **D-08:** Cite the re-audit section from `24-VERIFICATION.md` as canonical re-audit evidence.
- **D-09:** Test path: `test/crosswake/planning/summary_frontmatter_test.exs`.
- **D-10a:** Walk every `.planning/phases/*/*-SUMMARY.md`. If a summary lists requirements, it MUST use `requirements-completed:`. Bare `requirements:` is forbidden.
- **D-10b:** Every ID under `requirements-completed:` MUST exist as a bullet in `.planning/REQUIREMENTS.md`.
- **D-11:** Survey ALL existing SUMMARY files before committing the parity test. If pre-Phase-19 summaries use a third key shape, either backfill OR scope the test to a phase-number floor with an allowlist and inline comment.

### Claude's Discretion
- ExUnit module name, test description strings, helper function decomposition.
- Exact YAML key naming under `reaudits:` entries.
- Exact wording of `## Re-Audit (Phase 24)` body section (must include three-source cross-check table and before/after diff cells).
- Whether REQUIREMENTS.md parsing uses regex or small helper module.

### Deferred Ideas (OUT OF SCOPE)
- Sweep all phase summaries retroactively.
- Expand parity test to assert verification status, commit SHAs, completion dates, plan-number consistency.
- AGENTS.md / CONTRIBUTING notes.
- Phase 20 VERIFICATION.md contradiction.
- Cross-phase reconciliation drift checks.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RECN-01 | Host apps can follow a minimal Phoenix-owned reconciliation inbox example for purchase, restore, webhook, and support evidence. | Implementation exists (Phase 21). Gap is artifact shape: `requirements:` key in Phase 21 SUMMARYs, `[ ]` bullets in REQUIREMENTS.md, `Pending` in traceability table. All three fixed in this phase. |
| RECN-02 | Host apps can follow idempotency guidance using provider-aware identity rather than transient device correlation IDs. | Same artifact gap as RECN-01. Three-source cross-check will show `satisfied` after this phase. |
| RECN-03 | Host apps can project one authoritative entitlement snapshot from verified evidence and expose stale, pending, denied, and granted states clearly. | Same artifact gap as RECN-01 and RECN-02. |
</phase_requirements>

---

## Executive Summary

- Phase 21 verified RECN-01/02/03 in full. The only outstanding gap is artifact-shape inconsistency: Phase 21's two SUMMARY files use `requirements:` instead of the canonical `requirements-completed:` key, causing the audit cross-check to report `partial`. REQUIREMENTS.md and the traceability table also show these as pending/unchecked despite Phase 21's VERIFICATION.md passing.
- The D-11 survey (see Finding 1 below) shows a clean bifurcation: exactly 11 SUMMARY files use `requirements-completed:` (canonical), exactly 2 use `requirements:` (both Phase 21), and zero use a third key shape. No phase-number floor or allowlist is needed — Phase 21 files are the only two that need renaming before the parity test can be committed.
- No new Hex dependencies are required. YAML frontmatter parsing should use inline regex — the surface is simple (key: value or key:\n  - item blocks), the mix.exs dep tree has no YAML library, and adding one for three lines of frontmatter is unjustified.
- The existing CI merge gate (phase23-proof.yml `merge-blocking-commerce-proof` job) uses EXPLICIT test file paths; the new parity test at `test/crosswake/planning/summary_frontmatter_test.exs` will NOT be discovered by CI until that job is amended to include it. `mix test` locally auto-discovers it.
- The audit doc append shape is well-defined: frontmatter gets a new `reaudits:` list (append-only, `status: gaps_found` stays untouched), body gets `## Re-Audit (Phase 24)` at end-of-file with a three-source cross-check table showing before/after for RECN-01/02/03.

**Primary recommendation:** Execute the five artifact edits atomically in a fixed order (survey passes → rename Phase 21 SUMMARY keys → flip REQUIREMENTS.md bullets → update traceability table → append re-audit to audit doc → commit parity test → amend phase23-proof.yml CI step).

---

## Finding 1: D-11 Survey — Full SUMMARY Corpus Inventory [VERIFIED: filesystem]

**Survey date:** 2026-05-27
**Total SUMMARY.md files found:** 13
**Phase directories containing SUMMARYs:** 19, 20, 21, 23 (no phases 1–18 have SUMMARY files)

### By key shape:

| Key Used | Count | Files |
|----------|-------|-------|
| `requirements-completed:` | 11 | All Phase 19 (×3), all Phase 20 (×4), all Phase 23 (×4) |
| `requirements:` | 2 | `21-01-SUMMARY.md`, `21-02-SUMMARY.md` |
| Neither / no requirements key | 0 | — |
| Third key shape | 0 | — |

**Inline vs multi-line list shapes (both are canonical after key rename):**

- Phase 19 and 20 use inline YAML list: `requirements-completed: [COMM-04, COMM-05]`
- Phase 23 uses multi-line YAML list:
  ```yaml
  requirements-completed:
    - SUPP-04
  ```
- Phase 21 uses multi-line list under the wrong key:
  ```yaml
  requirements:
    - RECN-01
    - RECN-02
    - RECN-03
  ```

**D-11 verdict:** No phase-number floor or allowlist is needed. Only `21-01-SUMMARY.md` and `21-02-SUMMARY.md` use the wrong key. Rename both, then commit the parity test — it will pass against all 13 files.

**Critical parsing implication:** The parity test must handle BOTH inline (`[A, B]`) and multi-line (`\n  - A`) YAML list shapes when extracting requirement IDs under `requirements-completed:`. A regex that only handles one shape will produce false negatives.

**D-03 verification:** Confirmed — Phases 19, 20, and 23 all use `requirements-completed:` already. No surprise in the D-03 assumption.

**D-04 verification:** REQUIREMENTS.md has NO `### Validated` subsection, no `### Complete` subsection, and no `### Done` subsection anywhere. The native shape is flat `- [ ]` / `- [x]` bullets under milestone subsection headings. D-04 is safe to implement as specified.

---

## Finding 2: YAML Frontmatter Parsing in Elixir [VERIFIED: mix.exs, filesystem]

**mix.exs dependencies:** `jason ~> 1.4`, `nimble_options ~> 1.1`, `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`. No `yaml_elixir`, `yamerl`, or any YAML library.

**No YAML parser exists in `lib/crosswake/` or test support.** The project has never needed one.

**Recommendation: regex-based parser in the test file itself.** The frontmatter surface is small and well-structured. The test only needs two things:

1. **Detect forbidden key:** Check whether the frontmatter block contains a `requirements:` line that is NOT `requirements-completed:` (i.e., the bare key).
2. **Extract requirement IDs from `requirements-completed:`:** Handle both inline `[A, B, C]` and multi-line `\n  - A` shapes.

**Proposed parsing approach (inline in test, no helper module needed):**

```elixir
# Extract frontmatter (between first pair of `---` lines)
defp parse_frontmatter(content) do
  case Regex.run(~r/\A---\n(.*?)\n---\n/ms, content, capture: :all_but_first) do
    [fm] -> fm
    nil  -> ""
  end
end

# Check for bare `requirements:` key (not `requirements-completed:`)
defp has_bare_requirements_key?(frontmatter) do
  Regex.match?(~r/^requirements:\s*(?:\[|\n\s*-)/m, frontmatter)
end

# Extract IDs from requirements-completed (handles both inline and multi-line)
defp extract_completed_ids(frontmatter) do
  case Regex.run(~r/^requirements-completed:\s*(.+)/ms, frontmatter, capture: :all_but_first) do
    [rest] ->
      # Try inline: [A, B, C]
      inline = Regex.scan(~r/\b([A-Z]+-\d+)\b/, rest) |> Enum.map(fn [_, id] -> id end)
      if inline != [], do: inline, else: []
    nil -> []
  end
end
```

This is sufficient for the two assertions in D-10. No Hex dep required. If the project ever grows a larger planning corpus parser, it can be extracted to a module then.

**Dep cost vs regex tradeoff:** Adding `yaml_elixir` or `yamerl` adds a compile-time dep, a possible NIF, and a lockfile change for three lines of frontmatter with no nesting complexity. Regex is unambiguously lighter and correct for this surface.

---

## Finding 3: ExUnit Parity-Test Idiom Inventory [VERIFIED: filesystem]

Read: `renderer_test.exs`, `commerce_test.exs`, `doctor_test.exs`.

### Shared idioms to mirror:

**Module and file structure:**
- `use ExUnit.Case, async: true` — all three tests use `async: true`; the new test reads static files and has no side-effects, so `async: true` is correct
- Module name matches directory path: `Crosswake.SupportMatrix.RendererTest`, `Crosswake.Guides.CommerceTest`, `Crosswake.DoctorTest` → new test should be `Crosswake.Planning.SummaryFrontmatterTest`

**File path resolution:**
- `commerce_test.exs` uses `@guide_path Path.join([File.cwd!(), "guides", "commerce.md"])` and reads via `setup_all`
- `renderer_test.exs` uses `File.read!("guides/support_matrix.md")` directly (relative to project root)
- New test should use `File.cwd!()` as base + `".planning/phases"` for the glob, consistent with commerce_test pattern

**File walking:**
- `commerce_test.exs` reads a single file in `setup_all` and passes content to each test via context
- No existing test walks a directory glob; the new test IS the first directory-walker
- Pattern to use: `Path.wildcard(Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md"))`

**Assertion shape:**
- `assert content =~ "substring"` with failure message: `renderer_test.exs` uses `, "failure message string"` on assertions that carry diagnostic value
- Key pattern from `renderer_test.exs`: `assert rendered == on_disk, "guides/support_matrix.md drifted from canonical Renderer output; regenerate before merging"` — clear, actionable failure message
- Key pattern from `commerce_test.exs`: loop + per-item assertion: `for role <- canonical_roles do assert ownership_section =~ role, "commerce guide ownership section missing canonical corridor role \`#{role}\`"  end`
- New test should follow this loop-with-message pattern for both assertions (D-10a, D-10b)

**Failure message requirements from D-10:**
- D-10a failure: must name the file path that has the bare `requirements:` key
- D-10b failure: must name the missing requirement ID AND the file path it expected to find it in

**setup_all vs direct reading:**
- `commerce_test.exs` uses `setup_all` for a single static file (reads once, shares across all tests)
- `renderer_test.exs` reads files inline per test (no `setup_all`)
- New test: since it walks multiple files, read them inline in the test body (no `setup_all` needed)

**`async: true` is safe** — test reads `.planning/` files from disk (static files committed to git), no shared mutable state, no process dependencies.

**No shared helper imports** — none of the three cited tests import external helpers for their core assertions. New test should be self-contained.

### Anti-patterns to avoid:
- Do NOT use `assert_raise` or exception-based testing — existing tests use positive/negative assertions only
- Do NOT use `setup` (per-test) when `setup_all` (once per module) suffices for static file content — but for a file-walking test, inline reading is cleaner
- Do NOT assert on field ordering or whitespace beyond what the contract requires

---

## Finding 4: v3.2-MILESTONE-AUDIT.md Append-Only Structure [VERIFIED: filesystem]

### (a) Current frontmatter shape:

```yaml
---
milestone: v3.2
audited: 2026-05-27T12:28:50.272Z
status: gaps_found
scores:
  requirements: 6/12
  phases: 3/4
  integration: 1/3
  flows: 0/5
gaps:
  requirements: [... 6 items with id/status/phase/claimed_by_plans/completed_by_plans/verification_status/evidence ...]
  integration: [... 3 string items ...]
  flows: [... 1 string item ...]
tech_debt: [... 3 items with phase/items keys ...]
nyquist: {compliant_phases, partial_phases, missing_phases, overall}
---
```

### (b) Requirements Cross-Check table format (current):

```markdown
| Requirement | REQUIREMENTS.md | VERIFICATION.md | SUMMARY frontmatter (`requirements-completed`) | Final status |
|-------------|-----------------|-----------------|-----------------------------------------------|--------------|
```
Five columns. For each requirement row: checkbox state, VERIFICATION.md pass/fail with phase citation, whether `requirements-completed` key is present in summaries, and final verdict (`satisfied` / `partial` / `unsatisfied`).

### (c) RECN-01/02/03 evidence rows (current content):

The three RECN rows in the cross-check table currently show:
- REQUIREMENTS.md: `[x]` (Note: audit reads `[x]` even though REQUIREMENTS.md currently shows `[ ]` — the audit was produced at a point when the understanding was that Phase 21 passed; the frontmatter gap is what triggered `partial`)
- VERIFICATION.md: `passed (Phase 21)`
- SUMMARY frontmatter: `missing (requirements-completed not present)`
- Final status: `partial`

The `gaps.requirements` YAML entries for RECN-01/02/03 cite:
```
evidence: "21-VERIFICATION.md passes RECN-01 and REQUIREMENTS.md is [x], but Phase 21 summaries
  use `requirements` instead of `requirements-completed` frontmatter key."
```

### (d) Placement of new `## Re-Audit (Phase 24)` section:

The document ends with `## Recommendation`. The new section should be appended at **end-of-file**, after `## Recommendation`. This is append-only and does not disrupt any existing section boundary. The body section placement is:

```
## Recommendation
[existing content — untouched]

## Re-Audit (Phase 24)
[new content]
```

### (e) `reaudits:` YAML list shape for N≥2 re-audits:

Append to frontmatter as a new top-level key after the last existing key (`nyquist:`):

```yaml
reaudits:
  - phase: 24
    date: "2026-05-27"
    current_status: "satisfied"
    evidence:
      - "Phase 21 SUMMARY frontmatter keys renamed: requirements → requirements-completed (commits: <sha>, <sha>)"
      - "REQUIREMENTS.md RECN-01/02/03 bullets flipped to [x] (commit: <sha>)"
      - "Traceability table updated with Phase 21 + Phase 24 cell (commit: <sha>)"
      - "Parity test test/crosswake/planning/summary_frontmatter_test.exs passes: mix test test/crosswake/planning/summary_frontmatter_test.exs"
```

**Future re-audit appends a new list item** under `reaudits:` — the list structure makes this mechanical. The existing item at index 0 is never mutated.

**The `status: gaps_found` top-level key MUST NOT be changed.** It is the original audit verdict. Derived current state is always in `reaudits[N].current_status`.

---

## Finding 5: REQUIREMENTS.md Traceability Table Cell Format [VERIFIED: filesystem]

### Current table structure (confirmed pipe-separated markdown):

```markdown
| Requirement | Phase | Status |
|-------------|-------|--------|
...
| RECN-01 | Phase 24 | Pending |
| RECN-02 | Phase 24 | Pending |
| RECN-03 | Phase 24 | Pending |
```

Three columns: `Requirement`, `Phase`, `Status`.

### Target cell after Phase 24 (per D-05):

```markdown
| RECN-01 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
| RECN-02 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
| RECN-03 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
```

**No pipe character in the cell content** — the semicolon separator `; ` is safe. No markdown table escaping needed.

**Both literal substrings `Phase 21` and `Phase 24` appear in the Phase column cell.** Future audit-tool substring scan for either string will match.

**Multi-phase cell text is supported by the existing table format** — existing cells like `Completed (19-01, 19-03)` already contain parenthetical text. The cell width is unconstrained.

**D-04 confirmation:** REQUIREMENTS.md has no `### Validated` subsection and no precedent for one. The entire document uses the shape `### Subsection Name` + `- [ ] **REQ-ID**: description` bullets + single traceability table at the bottom. Flipping `[ ]` to `[x]` in-place is the correct mutation.

---

## Finding 6: Merge-Blocking Lane Verification [VERIFIED: filesystem]

### `mix test` local discovery:
- `mix.exs` has no `test_paths` or `test_pattern` overrides
- Default `:test_paths` is `["test"]`; default `:test_pattern` is `"*.{ex,exs}"` filtered by `String.ends_with?(&1, "_test.exs")`
- **`test/crosswake/planning/summary_frontmatter_test.exs` will be auto-discovered by `mix test` locally** without any registration

### CI merge-blocking gate:
- There is NO global `mix test` step in any CI workflow
- **All 4 CI workflows use explicit file paths:**
  - `phase5-proof.yml`: `bash script/verify_phase5_example_hosts.sh`
  - `phase10-proof.yml`: `bash script/verify_phase10...`
  - `phase18-proof.yml`: `bash script/verify_phase18_contract.sh`
  - `phase23-proof.yml` merge-blocking step: explicit `mix test <file1> <file2> ...`

**CRITICAL FINDING:** The new parity test will NOT be in the CI merge gate unless `phase23-proof.yml` is explicitly amended to add `test/crosswake/planning/summary_frontmatter_test.exs` to the `mix test` step in the `merge-blocking-commerce-proof` job.

**This is required for D-09 (merge-blocking lane).** The plan must include an amendment to `phase23-proof.yml`.

The specific step to amend in `phase23-proof.yml`:
```yaml
- name: Run commerce contract tests (doctor + support matrix + renderer + guide)
  run: |
    mix test \
      test/crosswake/doctor/doctor_test.exs \
      test/crosswake/support_matrix/support_matrix_test.exs \
      test/crosswake/support_matrix/renderer_test.exs \
      test/crosswake/guides/commerce_test.exs
      # ADD: test/crosswake/planning/summary_frontmatter_test.exs
```

Or (better for clarity): add a separate step in the merge-blocking job specifically for the planning parity test, consistent with how `phase23_commerce_support_proof_test.exs` has its own step.

---

## Finding 7: Dependency Check [VERIFIED: filesystem]

### New Hex deps required: NONE

`mix.exs` deps: `jason ~> 1.4`, `nimble_options ~> 1.1`, `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`.

The parity test needs only:
- `File.cwd!/0` (stdlib)
- `Path.wildcard/1` (stdlib)
- `File.read!/1` (stdlib)
- `Regex.run/3`, `Regex.match?/2` (stdlib)

No YAML parser needed (Finding 2). No new compile-time or runtime dep of any kind.

### Commerce module surface — untouched:
- `lib/crosswake/commerce/contracts.ex` — NOT touched
- `lib/crosswake/commerce/reconciliation.ex` — NOT touched
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — NOT touched
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — NOT touched
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — NOT touched

Phase 24 mutates planning artifacts (`.planning/` files) and adds one test file. Zero `lib/` or `examples/` changes.

---

## Finding 8: Validation Architecture (Nyquist) [VERIFIED: config.json]

`nyquist_validation: true` in `.planning/config.json`. Validation section is required.

The parity test IS the validation surface for this phase. There are no runtime behaviors to validate — only planning artifact shape correctness.

### Test Coverage Minimum (D-10 compliance):

| Requirement | Behavior | Test Type | Automated Command |
|-------------|----------|-----------|-------------------|
| RECN-01 | Phase 21 SUMMARYs use `requirements-completed:` key | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| RECN-02 | Phase 21 SUMMARYs use `requirements-completed:` key | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| RECN-03 | Phase 21 SUMMARYs use `requirements-completed:` key | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| D-10a | No SUMMARY uses bare `requirements:` key | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| D-10b | Every `requirements-completed:` ID exists in REQUIREMENTS.md | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |

**Wave 0 gaps:**
- [ ] `test/crosswake/planning/` directory does not exist yet — must be created
- [ ] `test/crosswake/planning/summary_frontmatter_test.exs` does not exist yet

**No framework install needed** — ExUnit is already part of the Elixir stdlib; `test/test_helper.exs` is `ExUnit.start()`.

---

## Architecture Patterns

### Execution Order (Dependency-Driven)

The five artifact edits have a strict partial order driven by the D-11 precondition:

```
[Survey passes — D-11 confirmed clean]
        |
        v
[Edit 1] Rename keys in 21-01-SUMMARY.md and 21-02-SUMMARY.md
        |
        v
[Edit 2] Flip RECN bullets in REQUIREMENTS.md ([ ] → [x])
  [parallel with Edit 3 — no dependency between them]
[Edit 3] Update RECN traceability table cells in REQUIREMENTS.md
        |
        v
[Edit 4] Append re-audit to v3.2-MILESTONE-AUDIT.md
        |
        v
[Edit 5] Write and commit parity test
   (run it first as a pre-commit check against current file state)
        |
        v
[Edit 6] Amend phase23-proof.yml to add parity test to merge-blocking step
```

**Why Edit 1 before Edit 5:** D-11 requires the parity test be run against all existing SUMMARY files before committing it. If the Phase 21 keys are renamed first, the parity test passes on the first run. If they are NOT renamed first, the parity test fails on the first run — that is the discovery failure mode D-11 warns about.

### Recommended Project Structure

No new `lib/` structure. One new test directory:

```
test/crosswake/
├── planning/                  # NEW — planning corpus parity tests
│   └── summary_frontmatter_test.exs  # NEW
├── guides/
├── support_matrix/
├── doctor/
└── proof/
```

### Pattern: File-Walker Parity Test

```elixir
defmodule Crosswake.Planning.SummaryFrontmatterTest do
  use ExUnit.Case, async: true

  @summary_glob Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md")

  test "all phase summaries use requirements-completed: not bare requirements:" do
    summaries = Path.wildcard(@summary_glob)
    assert summaries != [], "expected to find SUMMARY.md files at #{@summary_glob}"

    for path <- summaries do
      fm = parse_frontmatter(File.read!(path))
      refute has_bare_requirements_key?(fm),
             "#{path} uses bare `requirements:` key — rename to `requirements-completed:`"
    end
  end

  test "all requirement IDs in requirements-completed: exist in REQUIREMENTS.md" do
    known_ids = parse_requirement_ids_from_requirements_md()
    summaries = Path.wildcard(@summary_glob)

    for path <- summaries do
      fm = parse_frontmatter(File.read!(path))
      ids = extract_completed_ids(fm)

      for id <- ids do
        assert id in known_ids,
               "#{path} lists `#{id}` under requirements-completed: but `#{id}` is not in .planning/REQUIREMENTS.md"
      end
    end
  end

  # ... private helpers: parse_frontmatter/1, has_bare_requirements_key?/1,
  #     extract_completed_ids/1, parse_requirement_ids_from_requirements_md/0
end
```

**Source:** [ASSUMED] — pattern derived from commerce_test.exs and renderer_test.exs idioms observed in codebase.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Full YAML parser | Regex over well-known frontmatter surface | The surface is exactly 2 shapes (inline/multi-line list); adding a YAML dep for 3 regex patterns is unjustified overhead |
| Test file discovery | Custom glob helper | `Path.wildcard/1` (stdlib) | Already used throughout the project for file-walking |

---

## Common Pitfalls

### Pitfall 1: Parity Test Committed Before Phase 21 Key Rename
**What goes wrong:** Test immediately fails on the two `requirements:` keys in Phase 21 summaries, creating a retroactive test failure in git history.
**Why it happens:** D-11 precondition violated — test committed before survey cleanup.
**How to avoid:** Edit 1 (rename Phase 21 keys) BEFORE Edit 5 (commit test). Run `mix test test/crosswake/planning/summary_frontmatter_test.exs` as a pre-commit check.
**Warning signs:** Test output names `21-01-SUMMARY.md` or `21-02-SUMMARY.md` in the failure message.

### Pitfall 2: Regex Handles Only One YAML List Shape
**What goes wrong:** `extract_completed_ids/1` only handles inline `[A, B]` form and silently returns `[]` for multi-line `\n  - A` form (or vice versa), producing false negatives for D-10b.
**Why it happens:** Phase 19/20 summaries use inline form; Phase 23 summaries use multi-line form. Both are present in the corpus.
**How to avoid:** Test the regex against at least one inline and one multi-line fixture before committing.
**Warning signs:** D-10b assertion never fires on any multi-line ID.

### Pitfall 3: Mutating `status: gaps_found` in Audit Doc
**What goes wrong:** Top-level `status:` field flipped to `satisfied`, destroying the historical audit chain.
**Why it happens:** Natural instinct to "fix" the verdict field.
**How to avoid:** D-07 is explicit — add `reaudits:` list, leave `status: gaps_found` untouched. Re-audit result lives in `reaudits[0].current_status: "satisfied"`.
**Warning signs:** `status: satisfied` appears at the top level of `v3.2-MILESTONE-AUDIT.md` frontmatter.

### Pitfall 4: Traceability Cell Uses Phase 21/24 or Phases 21+24 Instead of Literal Substrings
**What goes wrong:** Future audit-tool substring scan for `Phase 21` or `Phase 24` fails if the cell reads `Phase 21/24` or `Phases 21+24`.
**Why it happens:** Abbreviation instinct.
**How to avoid:** D-05 is explicit: "both literal substrings `Phase 21` AND `Phase 24` MUST appear in the same cell." Use the exact cell text: `Phase 21 (validated); Phase 24 (traceability normalized)`.
**Warning signs:** Cell text contains `21/24` or `21+24` or `21 and 24`.

### Pitfall 5: Parity Test Not Added to CI Merge Gate
**What goes wrong:** Test passes locally via `mix test` but never runs in CI because `phase23-proof.yml` uses explicit file paths.
**Why it happens:** `mix test` auto-discovers `test/crosswake/planning/` but the CI workflow does not.
**How to avoid:** Include `phase23-proof.yml` amendment as an explicit plan task (Edit 6).
**Warning signs:** CI `merge-blocking-commerce-proof` job does not list `test/crosswake/planning/summary_frontmatter_test.exs` in its `mix test` command.

### Pitfall 6: REQUIREMENTS.md Bullets Still Show `[ ]` After Phase 24
**What goes wrong:** Traceability table shows `Complete` but bullet checkboxes still show `[ ]`, creating internal inconsistency within REQUIREMENTS.md itself.
**Why it happens:** Edit 2 missed.
**How to avoid:** Edit 2 (flip bullets) and Edit 3 (update table) should be in the same commit or explicitly sequential tasks.

---

## Risks and Surprises

### RISK-1: CI Merge Gate Requires Explicit Amendment (HIGH PRIORITY)
**Finding:** Phase 23's CI (`phase23-proof.yml`) uses explicit test file paths, not `mix test` (all). The parity test will NOT block merges in CI without amending `phase23-proof.yml`.
**Mitigation:** Plan must include a task to add `test/crosswake/planning/summary_frontmatter_test.exs` to the `merge-blocking-commerce-proof` job in `phase23-proof.yml`.

### RISK-2: YAML List Shape Bifurcation (MEDIUM)
**Finding:** The corpus has two YAML list shapes (inline `[A, B]` and multi-line `\n  - A`). The parity test must handle both.
**Mitigation:** Implement `extract_completed_ids/1` to handle both shapes; test against Phase 19 (inline) and Phase 23 (multi-line) files before committing.

### RISK-3: D-11 Survey Result Is Clean (POSITIVE SURPRISE)
**Finding:** No pre-Phase-19 SUMMARY files exist. All 11 non-Phase-21 summaries use `requirements-completed:`. No third key shape found anywhere.
**Impact:** No allowlist needed. No floor cutoff. The parity test applies to all 13 files after Phase 21 is renamed.

---

## Code Examples

### Parsing Frontmatter Inline (Elixir Regex)
[ASSUMED — derived from Elixir stdlib patterns, not from official docs for this specific pattern]

```elixir
# Extract frontmatter block (between opening and closing ---)
defp parse_frontmatter(content) do
  case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
    [fm] -> fm
    nil  -> ""
  end
end

# Detect bare `requirements:` key (not `requirements-completed:`)
# Matches: `requirements:` followed by a space+[ or newline+whitespace+-
defp has_bare_requirements_key?(frontmatter) do
  Regex.match?(~r/^requirements:[ \t]*(?:\[|\r?\n[ \t]+-)/m, frontmatter)
end

# Extract IDs from requirements-completed: (inline or multi-line)
defp extract_completed_ids(frontmatter) do
  case Regex.run(~r/^requirements-completed:[ \t]*(.*)/ms, frontmatter, capture: :all_but_first) do
    [rest] ->
      Regex.scan(~r/\b([A-Z]+-\d+)\b/, rest)
      |> Enum.map(fn [_, id] -> id end)
      |> Enum.uniq()
    nil -> []
  end
end

# Parse bullet IDs from REQUIREMENTS.md
defp parse_requirement_ids_from_requirements_md do
  Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")
  |> File.read!()
  |> then(fn content ->
    Regex.scan(~r/- \[[x ]\] \*\*([A-Z]+-\d+)\*\*/, content)
    |> Enum.map(fn [_, id] -> id end)
  end)
end
```

### Re-Audit Frontmatter YAML Append Shape

```yaml
# Append after existing nyquist: key in v3.2-MILESTONE-AUDIT.md frontmatter
reaudits:
  - phase: 24
    date: "2026-05-27"
    current_status: "satisfied"
    evidence:
      - "21-01-SUMMARY.md: requirements → requirements-completed (commit: <sha>)"
      - "21-02-SUMMARY.md: requirements → requirements-completed (commit: <sha>)"
      - "REQUIREMENTS.md: RECN-01/02/03 bullets flipped to [x] (commit: <sha>)"
      - "REQUIREMENTS.md: traceability table updated with Phase 21 + Phase 24 (commit: <sha>)"
      - "Parity test: test/crosswake/planning/summary_frontmatter_test.exs (mix test passes, 2 tests)"
```

---

## Validation Architecture

> `nyquist_validation: true` in `.planning/config.json` — section required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib, no install) |
| Config file | `test/test_helper.exs` (exists: `ExUnit.start()`) |
| Quick run command | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| RECN-01 | Phase 21 SUMMARYs carry `requirements-completed:` key listing RECN-01 | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 |
| RECN-02 | Phase 21 SUMMARYs carry `requirements-completed:` key listing RECN-02 | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 |
| RECN-03 | Phase 21 SUMMARYs carry `requirements-completed:` key listing RECN-03 | Parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/planning/summary_frontmatter_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/planning/` directory — does not exist; must be created
- [ ] `test/crosswake/planning/summary_frontmatter_test.exs` — covers RECN-01/02/03 and D-10a/D-10b

---

## Environment Availability

Step 2.6: SKIPPED — Phase 24 is purely planning-artifact and test-file changes. No external tools, services, runtimes beyond the standard Elixir/ExUnit setup, which is confirmed present from Phase 23's CI success.

---

## Security Domain

> Step 2.6 security check: this phase edits only `.planning/` markdown/YAML files and adds one ExUnit test. No auth, session, input validation, crypto, or API surface is involved. Security domain is not applicable to this phase.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Regex pattern for frontmatter parsing handles edge cases (e.g., `---` inside body content) | Finding 2, Code Examples | False positive/negative in D-10a or D-10b assertions; mitigated by using the strict `\A---\n...\n---\n` anchor pattern |
| A2 | `Path.wildcard/1` with `"*"` glob depth matches exactly the `.planning/phases/<dir>/<file>-SUMMARY.md` pattern | Finding 3, Architecture | If nested phases have deeper nesting, wildcard misses files; mitigated by verifying wildcard count matches filesystem count |

**If this table is empty after verification:** All other claims were verified directly from filesystem inspection or official Elixir docs.

---

## Open Questions

1. **Should the parity test be in its own step in `phase23-proof.yml` or appended to the existing commerce contract test step?**
   - What we know: Phase 23's `phase23_commerce_support_proof_test.exs` has its own named step for clarity. The commerce contract tests (doctor, support_matrix, renderer, guides) share one step.
   - What's unclear: Whether planning corpus tests are conceptually close enough to "commerce contract tests" to share the step, or separate enough to warrant their own named step.
   - Recommendation: Separate named step — "Run planning corpus parity test" — for discoverability and consistent naming with the phase23 proof step pattern.

2. **Should `24-VERIFICATION.md` re-run `mix test` or just cite the parity test result?**
   - What we know: D-08 says VERIFICATION.md cites the re-audit, does not duplicate the audit body.
   - What's unclear: Whether VERIFICATION.md needs to show the full `mix test` output or just reference the parity test path.
   - Recommendation: VERIFICATION.md shows the `mix test` command + pass count (consistent with Phase 21's VERIFICATION.md format which shows exact commands and results).

---

## Sources

### Primary (HIGH confidence)
- Filesystem read: `.planning/phases/*/*-SUMMARY.md` (all 13 files) — D-11 survey result
- Filesystem read: `mix.exs` — dep tree confirms no YAML library
- Filesystem read: `.planning/v3.2-MILESTONE-AUDIT.md` — frontmatter shape, cross-check table format, RECN evidence rows
- Filesystem read: `.planning/REQUIREMENTS.md` — traceability table column structure, bullet format, no `### Validated` precedent
- Filesystem read: `test/crosswake/guides/commerce_test.exs` — ExUnit idiom extraction
- Filesystem read: `test/crosswake/support_matrix/renderer_test.exs` — ExUnit idiom extraction
- Filesystem read: `test/crosswake/doctor/doctor_test.exs` — ExUnit idiom extraction
- Filesystem read: `.github/workflows/phase23-proof.yml` — CI merge gate uses explicit paths
- Filesystem read: `.planning/config.json` — `nyquist_validation: true`

### Secondary (MEDIUM confidence)
- Elixir `mix help test` output — confirms default `:test_paths`, `:test_pattern`, filter behavior

---

## Metadata

**Confidence breakdown:**
- D-11 survey (SUMMARY corpus state): HIGH — direct filesystem read of all 13 files
- YAML parsing approach: HIGH — mix.exs dep tree confirmed; regex approach derived from stdlib patterns
- ExUnit idiom inventory: HIGH — direct read of all three cited test files
- Audit doc structure: HIGH — direct read of `v3.2-MILESTONE-AUDIT.md`
- CI merge gate gap: HIGH — direct read of `phase23-proof.yml` confirms explicit path enumeration
- Dep check: HIGH — mix.exs confirmed

**Research date:** 2026-05-27
**Valid until:** 60 days (stable artifact layout; no external dependencies)
