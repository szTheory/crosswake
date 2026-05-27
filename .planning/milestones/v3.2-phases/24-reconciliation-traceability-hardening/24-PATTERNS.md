# Phase 24: Reconciliation Traceability Hardening — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 6 (2 modified planning artifacts, 2 modified REQUIREMENTS/AUDIT docs, 1 created test, 1 modified CI workflow)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/21-reconciliation-example/21-01-SUMMARY.md` | planning artifact (modify) | transform (key rename) | `.planning/phases/23-commerce-support-and-proof-closure/23-03-SUMMARY.md` | exact (same frontmatter shape) |
| `.planning/phases/21-reconciliation-example/21-02-SUMMARY.md` | planning artifact (modify) | transform (key rename) | `.planning/phases/23-commerce-support-and-proof-closure/23-03-SUMMARY.md` | exact (same frontmatter shape) |
| `.planning/REQUIREMENTS.md` | planning artifact (modify) | transform (checkbox flip + table cell update) | `.planning/REQUIREMENTS.md` existing rows for COMM/ENTL as canonical shape reference | self-referential |
| `.planning/v3.2-MILESTONE-AUDIT.md` | planning artifact (modify/append) | append-only event log | existing file body — append at EOF after `## Recommendation` | self-referential (append pattern) |
| `test/crosswake/planning/summary_frontmatter_test.exs` | test (create) | file-I/O, parity/contract walker | `test/crosswake/guides/commerce_test.exs` + `test/crosswake/support_matrix/renderer_test.exs` | role-match (same parity-test idiom class) |
| `.github/workflows/phase23-proof.yml` | CI config (modify) | event-driven | same file — "Run commerce contract tests" step lines 80–91 | self-referential (append to step) |

---

## Pattern Assignments

---

### `.planning/phases/21-reconciliation-example/21-01-SUMMARY.md` (planning artifact, key rename)

**Analog:** `.planning/phases/23-commerce-support-and-proof-closure/23-03-SUMMARY.md`

**Target canonical frontmatter shape** (lines 53–55 of 23-03-SUMMARY.md):
```yaml
requirements-completed:
  - SUPP-05
```

**Current (wrong) shape** in both Phase 21 SUMMARY files (lines 6–9 of 21-01-SUMMARY.md):
```yaml
requirements:
  - RECN-01
  - RECN-02
  - RECN-03
```

**Exact transformation:**
- Line 6: change `requirements:` → `requirements-completed:`
- Lines 7–9: preserve exactly — list contents are correct, only the key is wrong
- No other lines change

**After transformation (target state):**
```yaml
requirements-completed:
  - RECN-01
  - RECN-02
  - RECN-03
```

**Also note:** Phase 19 and Phase 20 summaries use inline YAML list shape as an alternative canonical form:
```yaml
requirements-completed: [COMM-04, COMM-05]
```
Both inline and multi-line are canonical. Phase 21 uses multi-line; preserve that shape after rename.

---

### `.planning/phases/21-reconciliation-example/21-02-SUMMARY.md` (planning artifact, key rename)

**Analog:** Same as 21-01-SUMMARY.md above — identical transformation.

**Current (wrong) shape** (lines 6–9 of 21-02-SUMMARY.md):
```yaml
requirements:
  - RECN-01
  - RECN-02
  - RECN-03
```

**Exact transformation:** Same as 21-01 — rename `requirements:` → `requirements-completed:`, preserve list contents exactly.

---

### `.planning/REQUIREMENTS.md` (planning artifact, two mutations)

**Analog (checkbox shape):** Existing `[x]` bullets in the same file for COMM/ENTL requirements. The COMM rows are the canonical already-flipped shape.

**Mutation 1 — Flip bullets (lines 73–75):**

Current:
```markdown
- [ ] **RECN-01**: Host apps can follow a minimal Phoenix-owned reconciliation inbox example for purchase, restore, webhook, and support evidence.
- [ ] **RECN-02**: Host apps can follow idempotency guidance that uses provider-aware identity rather than transient device correlation IDs.
- [ ] **RECN-03**: Host apps can project one authoritative entitlement snapshot from verified evidence and expose stale, pending, denied, and granted states clearly.
```

Target (change `[ ]` → `[x]` on each line, keep bullets in their existing subsection, no structural change):
```markdown
- [x] **RECN-01**: Host apps can follow a minimal Phoenix-owned reconciliation inbox example for purchase, restore, webhook, and support evidence.
- [x] **RECN-02**: Host apps can follow idempotency guidance that uses provider-aware identity rather than transient device correlation IDs.
- [x] **RECN-03**: Host apps can project one authoritative entitlement snapshot from verified evidence and expose stale, pending, denied, and granted states clearly.
```

**Mutation 2 — Traceability table cells (lines 122–124):**

Current:
```markdown
| RECN-01 | Phase 24 | Pending |
| RECN-02 | Phase 24 | Pending |
| RECN-03 | Phase 24 | Pending |
```

Target (both literal substrings `Phase 21` AND `Phase 24` must appear in the Phase column cell per D-05):
```markdown
| RECN-01 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
| RECN-02 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
| RECN-03 | Phase 21 (validated); Phase 24 (traceability normalized) | Complete |
```

**Critical constraint:** Do NOT use `Phase 21/24`, `Phase 21+24`, or `Phases 21 and 24` — the literal substrings `Phase 21` and `Phase 24` must each appear independently in the same cell for future audit-tool substring scans (D-05, Footgun 3).

**Analog for table cell multi-phase text:** Existing cells like `Completed (19-01, 19-03)` in the same table show that parenthetical multi-value cells are already the native shape; the cell width is unconstrained.

---

### `.planning/v3.2-MILESTONE-AUDIT.md` (planning artifact, append-only)

**Analog:** Same file's existing frontmatter and body — the existing shape defines the append target.

**Mutation 1 — Append `reaudits:` YAML key to frontmatter:**

Current last frontmatter key (lines 76–84):
```yaml
nyquist:
  compliant_phases:
    - "Phase 21"
  partial_phases: []
  missing_phases:
    - "Phase 19"
    - "Phase 20"
    - "Phase 22"
  overall: "partial"
---
```

Target (append `reaudits:` list after `nyquist:` block, before closing `---`):
```yaml
nyquist:
  compliant_phases:
    - "Phase 21"
  partial_phases: []
  missing_phases:
    - "Phase 19"
    - "Phase 20"
    - "Phase 22"
  overall: "partial"
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
---
```

**Critical constraint:** The top-level `status: gaps_found` field on line 4 MUST NOT be changed — it is the original audit verdict. All derived current state lives in `reaudits[].current_status` (D-07, Footgun 2).

**Mutation 2 — Append `## Re-Audit (Phase 24)` body section at EOF:**

Current EOF (line 187):
```markdown
`/gsd-plan-milestone-gaps`
```
(End of `## Recommendation` section — no trailing newline section after it.)

Append after the last line, separated by a blank line:

```markdown

## Re-Audit (Phase 24)

**Re-audited:** 2026-05-27
**Trigger:** Phase 21 SUMMARY frontmatter key normalization (`requirements:` → `requirements-completed:`)
**Scope:** RECN-01, RECN-02, RECN-03 only

### Three-Source Cross-Check: RECN-01/02/03

| Requirement | REQUIREMENTS.md | VERIFICATION.md | SUMMARY frontmatter (`requirements-completed:`) | Final status |
|-------------|-----------------|-----------------|------------------------------------------------|--------------|
| RECN-01 | before: `[ ]` → after: `[x]` | passed (Phase 21) — unchanged | before: missing (`requirements:` key) → after: listed (`requirements-completed:`) | **satisfied** |
| RECN-02 | before: `[ ]` → after: `[x]` | passed (Phase 21) — unchanged | before: missing (`requirements:` key) → after: listed (`requirements-completed:`) | **satisfied** |
| RECN-03 | before: `[ ]` → after: `[x]` | passed (Phase 21) — unchanged | before: missing (`requirements:` key) → after: listed (`requirements-completed:`) | **satisfied** |

### What Changed

- `.planning/phases/21-reconciliation-example/21-01-SUMMARY.md`: `requirements:` key renamed to `requirements-completed:`. List contents (RECN-01/02/03) preserved exactly.
- `.planning/phases/21-reconciliation-example/21-02-SUMMARY.md`: Same rename.
- `.planning/REQUIREMENTS.md`: RECN-01/02/03 bullets flipped from `[ ]` to `[x]`. Traceability table cells updated from `Phase 24 / Pending` to `Phase 21 (validated); Phase 24 (traceability normalized) / Complete`.
- `test/crosswake/planning/summary_frontmatter_test.exs`: New merge-blocking parity test. Passes against all 13 `.planning/phases/*/*-SUMMARY.md` files.

### Original Gap (from initial audit)

The initial audit found RECN-01/02/03 as `partial` because Phase 21's two SUMMARY files used `requirements:` instead of the canonical `requirements-completed:` key, preventing the cross-check from detecting completion. Phase 21's `21-VERIFICATION.md` was already green and the implementation was fully verified — the gap was purely artifact-shape inconsistency.

### Re-Audit Verdict

RECN-01, RECN-02, and RECN-03 are now **satisfied**. All three sources agree: REQUIREMENTS.md checkboxes are `[x]`, VERIFICATION.md passes, and SUMMARY frontmatter uses `requirements-completed:` with the correct IDs listed.

Parity test evidence: `mix test test/crosswake/planning/summary_frontmatter_test.exs` → 2 tests, 0 failures.
```

---

### `test/crosswake/planning/summary_frontmatter_test.exs` (test, create)

**Analog 1 (primary — loop + per-item assertion with message):** `test/crosswake/guides/commerce_test.exs`
**Analog 2 (failure-message style):** `test/crosswake/support_matrix/renderer_test.exs`
**Analog 3 (layout reference):** `test/crosswake/doctor/doctor_test.exs`

**Module declaration pattern** (from commerce_test.exs lines 1–9):
```elixir
defmodule Crosswake.Guides.CommerceTest do
  use ExUnit.Case, async: true

  @guide_path Path.join([File.cwd!(), "guides", "commerce.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end
```

**Adapted for new test** — module name follows the `Crosswake.<Subsystem>.<Name>Test` convention; path constant uses `File.cwd!()` as base (matching commerce_test.exs convention); no `setup_all` needed (file-walker reads inline):
```elixir
defmodule Crosswake.Planning.SummaryFrontmatterTest do
  use ExUnit.Case, async: true

  @summary_glob Path.join(File.cwd!(), ".planning/phases/*/*-SUMMARY.md")
```

**Loop-with-message assertion pattern** (from commerce_test.exs lines 190–193):
```elixir
for role <- canonical_roles do
  assert ownership_section =~ "`#{role}`",
         "commerce guide ownership section missing canonical corridor role `#{role}` (support matrix declares: #{inspect(support_matrix_roles)})"
end
```

**Adapted for D-10a** (no-bare-requirements assertion):
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

**Adapted for D-10b** (every listed ID exists in REQUIREMENTS.md):
```elixir
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
```

**Failure-message clarity pattern** (from renderer_test.exs line 146–147):
```elixir
assert rendered == on_disk,
       "guides/support_matrix.md drifted from canonical Renderer output; regenerate before merging"
```
Each assertion carries an actionable message naming the file and the exact fix required — copy this style exactly.

**Private helper pattern** — helpers are self-contained in the test file (no external imports in any of the three analog tests). The four helpers needed:

```elixir
# Extract frontmatter block (between opening and closing ---)
# Use \A anchor + multiline dotall to match only the FIRST frontmatter block
defp parse_frontmatter(content) do
  case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
    [fm] -> fm
    nil  -> ""
  end
end

# Detect bare `requirements:` key (not `requirements-completed:`)
# Must NOT match `requirements-completed:` — negative lookahead ensures this
defp has_bare_requirements_key?(frontmatter) do
  Regex.match?(~r/^requirements:[ \t]*(?:\[|\r?\n[ \t]+-)/m, frontmatter)
end

# Extract IDs from requirements-completed: (handles BOTH inline [A, B] and multi-line \n  - A)
# CRITICAL: corpus has both shapes — Phase 19/20 inline, Phase 23 multi-line (RESEARCH Finding 1)
defp extract_completed_ids(frontmatter) do
  case Regex.run(~r/^requirements-completed:[ \t]*(.*)/ms, frontmatter, capture: :all_but_first) do
    [rest] ->
      Regex.scan(~r/\b([A-Z]+-\d+)\b/, rest)
      |> Enum.map(fn [_, id] -> id end)
      |> Enum.uniq()
    nil -> []
  end
end

# Parse bullet IDs from REQUIREMENTS.md — matches both [ ] and [x] bullets
defp parse_requirement_ids_from_requirements_md do
  Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")
  |> File.read!()
  |> then(fn content ->
    Regex.scan(~r/- \[[x ]\] \*\*([A-Z]+-\d+)\*\*/, content)
    |> Enum.map(fn [_, id] -> id end)
  end)
end
```

**`async: true` is correct** — test reads only static `.planning/` files, no shared mutable state, no process dependencies (same posture as all three analog tests).

**No `setup_all`** — directory-walker reads files inline per test body (inline reading is cleaner for multi-file walks than sharing via context).

**No external helper imports** — none of the three analog tests import external helpers for core assertions; this test should also be fully self-contained.

**New directory to create:** `test/crosswake/planning/` — does not exist yet. The file creates it implicitly when written; no explicit mkdir needed in Elixir test tooling.

---

### `.github/workflows/phase23-proof.yml` (CI config, modify)

**Analog:** Same file — the existing "Run commerce contract tests" step (lines 80–91) is the pattern to extend.

**Current step (lines 80–91):**
```yaml
      - name: Run commerce contract tests (doctor + support matrix + renderer + guide)
        # Plan 23-01/02/03 contract tests for the commerce_summary surface,
        # support matrix enrichment, and layered commerce docs hub. All are
        # merge-blocking because they exercise canonical truth without
        # depending on provider SDKs.
        run: |
          mix test \
            test/crosswake/doctor/doctor_test.exs \
            test/crosswake/support_matrix/support_matrix_test.exs \
            test/crosswake/support_matrix/renderer_test.exs \
            test/crosswake/guides/commerce_test.exs
```

**Option A — Add a separate named step** (recommended per RESEARCH Finding 6 open question — mirrors how `phase23_commerce_support_proof_test.exs` has its own step for discoverability):
```yaml
      - name: Run planning corpus parity test
        # Phase 24: merge-blocking parity test asserting (a) no SUMMARY file uses
        # bare `requirements:` key and (b) every requirements-completed: ID exists
        # in .planning/REQUIREMENTS.md. Hermetic — reads only static planning
        # artifact files committed to git.
        run: mix test test/crosswake/planning/summary_frontmatter_test.exs
```

**Option B — Append to existing step** (simpler, fewer steps):
```yaml
      - name: Run commerce contract tests (doctor + support matrix + renderer + guide + planning parity)
        run: |
          mix test \
            test/crosswake/doctor/doctor_test.exs \
            test/crosswake/support_matrix/support_matrix_test.exs \
            test/crosswake/support_matrix/renderer_test.exs \
            test/crosswake/guides/commerce_test.exs \
            test/crosswake/planning/summary_frontmatter_test.exs
```

**Placement:** Insert the new step (or append to existing step) inside the `merge-blocking-commerce-proof` job, NOT the `advisory-commerce-proof` job. The advisory job is guarded by `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}` and runs only weekly — the parity test must be in the merge-blocking job guarded by PR/push events.

**Critical constraint:** Without this amendment, `mix test` discovers `test/crosswake/planning/summary_frontmatter_test.exs` locally but CI will never run it — all four CI workflows use explicit file paths, not `mix test` (all). This is the non-obvious gap flagged in RESEARCH Finding 6 / RISK-1.

---

## Shared Patterns

### Frontmatter Key Convention (applies to both SUMMARY edits)
**Source:** `.planning/phases/23-commerce-support-and-proof-closure/23-03-SUMMARY.md` lines 53–55
**Apply to:** 21-01-SUMMARY.md and 21-02-SUMMARY.md
```yaml
requirements-completed:
  - SUPP-05
```
The key is `requirements-completed:` (with hyphen between "requirements" and "completed"). The bare key `requirements:` is reserved for PLAN-style artifacts, not SUMMARY artifacts.

### Append-Only Planning Artifact Pattern (applies to MILESTONE-AUDIT edit)
**Source:** Phase 21 D-04 (append-only normalized evidence events) and Phase 23 D-11 (proof-lane evidence preservation), cited in CONTEXT.md
**Apply to:** `v3.2-MILESTONE-AUDIT.md` frontmatter and body
Pattern: Never overwrite historical snapshot fields. Append new list entries to `reaudits:` YAML key; add new `## Re-Audit (Phase N)` section at EOF. The original `status:` verdict field is immutable historical evidence.

### ExUnit Parity Test Module Convention (applies to new test)
**Source:** `test/crosswake/guides/commerce_test.exs` line 1; `test/crosswake/support_matrix/renderer_test.exs` line 1; `test/crosswake/doctor/doctor_test.exs` line 3
**Apply to:** `test/crosswake/planning/summary_frontmatter_test.exs`
```elixir
use ExUnit.Case, async: true
```
All three analog tests use `async: true`. The new test reads only static committed files — `async: true` is correct and required.

### File Path Base Convention (applies to new test)
**Source:** `test/crosswake/guides/commerce_test.exs` line 4
**Apply to:** `test/crosswake/planning/summary_frontmatter_test.exs`
```elixir
@guide_path Path.join([File.cwd!(), "guides", "commerce.md"])
```
Use `File.cwd!()` as the base, not relative paths. The test is run from the project root.

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Execution Order Reminder (from RESEARCH.md Architecture Patterns)

The partial order is strictly dependency-driven:

1. Rename Phase 21 SUMMARY keys (Edit 1) — must come BEFORE committing parity test
2. Flip REQUIREMENTS.md bullets (Edit 2) — parallel with Edit 3
3. Update REQUIREMENTS.md traceability table cells (Edit 3) — parallel with Edit 2
4. Append re-audit to v3.2-MILESTONE-AUDIT.md (Edit 4)
5. Write and commit parity test (Edit 5) — run `mix test test/crosswake/planning/summary_frontmatter_test.exs` as pre-commit check before committing
6. Amend phase23-proof.yml to add parity test to merge-blocking step (Edit 6)

**Why Edit 1 before Edit 5:** If Phase 21 keys are NOT renamed before the parity test is committed, the test will immediately fail on `21-01-SUMMARY.md` and `21-02-SUMMARY.md`, creating a retroactive failure in git history (RESEARCH Pitfall 1).

---

## Metadata

**Analog search scope:** `.planning/phases/`, `test/crosswake/`, `.github/workflows/`
**Files scanned:** 12 (6 analog files read in full; 2 bash greps for targeted line extraction)
**Pattern extraction date:** 2026-05-27
