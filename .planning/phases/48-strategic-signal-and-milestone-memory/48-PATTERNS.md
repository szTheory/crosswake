# Phase 48: Strategic Signal and Milestone Memory - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 6  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/MILESTONE-ARC.md` | config | transform | `.planning/MILESTONE-ARC.md` | exact |
| `.planning/milestones/v3.6-CLOSEOUT.md` (or `.planning/milestones/<milestone>-CLOSEOUT.md`) | config | batch | `.planning/milestones/v3.5-MILESTONE-AUDIT.md` | role-match |
| `test/crosswake/planning/milestone_closeout_parity_test.exs` | test | batch | `test/crosswake/planning/summary_frontmatter_test.exs` | role+flow |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |

## Pattern Assignments

### `.planning/MILESTONE-ARC.md` (config, transform)

**Analog:** `.planning/MILESTONE-ARC.md`

**Strategic queue field pattern** (lines 75-100):
```markdown
### Active: v3.6 Operator Truth and Production Diagnostics

**Objective**
- ...

**Why now**
- ...

**Key outputs**
- ...

**Non-goals**
- ...

**Proof required**
- ...
```

**Dependency discipline pattern** (lines 207-215):
```markdown
## Dependency Graph

- `v3.6 Operator Truth` precedes ...
- `v3.7 Commerce Provider Adapters` depends on ...
- `v3.8 Sigra Full Auth` depends on ...
```

**Closeout checklist pattern** (lines 229-241):
```markdown
## Milestone Closeout Checklist

- `PROJECT.md` current state, active/validated requirements, and key decisions.
- `MILESTONE-ARC.md` strategic queue, dependencies, open research flags, and durable lessons.
- `ROADMAP.md` phase status parity.
- `REQUIREMENTS.md` archived or reset state.
- `STATE.md` milestone/frontmatter consistency.
- Threads/seeds ...
- Verification reports ...
- Validation ledgers ...
- Changelog/release continuity ...
```

---

### `.planning/milestones/v3.6-CLOSEOUT.md` (config, batch)

**Analog:** `.planning/milestones/v3.5-MILESTONE-AUDIT.md` (primary), `.planning/milestones/v3.4-MILESTONE-AUDIT.md` (secondary)

**Frontmatter ledger shape pattern** (v3.5 lines 1-45):
```yaml
---
milestone: v3.5
milestone_name: First-Party Companions
audited: 2026-05-31T13:50:20-04:00
status: passed
scores:
  requirements: 15/15
  phases: 10/10
  integration: 6/6
  flows: 4/4
gaps:
  requirements: []
  phases: []
  integration: []
  flows: []
resolved_gaps:
  - phase: "43"
    status: "resolved"
    evidence: "..."
tech_debt:
  - phase: "39"
    items:
      - "..."
nyquist:
  compliant_phases: ["41", "45", "46"]
  partial_phases: ["39", "40", "42", "43", "47"]
  missing_phases: ["38"]
  overall: "partial"
---
```

**Readiness table pattern** (v3.5 lines 57-68):
```markdown
## Readiness Summary

| Check | Result | Evidence |
|-------|--------|----------|
| Roadmap analyze | Passed | `gsd-sdk query roadmap.analyze` ... |
| Requirements table | Passed | ... |
| Phase summaries | Passed | ... |
| Phase verification files | Passed | ... |
```

**Append-only gap resolution pattern** (v3.5 lines 115-121):
```markdown
## Resolved Audit Gaps

| Gap | Resolution |
|-----|------------|
| ... | ... |
```

**Validation bookkeeping pattern** (v3.4 lines 97-107):
```markdown
## Nyquist Compliance (discovery only)

| Phase | VALIDATION.md | `nyquist_compliant` | Status |
|-------|---------------|---------------------|--------|
| ... |
```

---

### `test/crosswake/planning/milestone_closeout_parity_test.exs` (test, batch)

**Analog:** `test/crosswake/planning/summary_frontmatter_test.exs`

**ExUnit module/setup pattern** (lines 1-13):
```elixir
defmodule Crosswake.Planning.SummaryFrontmatterTest do
  use ExUnit.Case, async: true

  @summary_glob Path.join(File.cwd!(), ".planning/milestones/v3.3-phases/*/*-SUMMARY.md")
  @requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")

  defp archived_summaries, do: Path.wildcard(@summary_glob)
```

**Parity assertions pattern** (lines 14-47):
```elixir
test "all phase summaries use requirements-completed: not bare requirements:" do
  for path <- archived_summaries() do
    fm = parse_frontmatter(File.read!(path))
    refute has_bare_requirements_key?(fm), "..."
  end
end
```

**Fail-loud parser pattern** (lines 72-95):
```elixir
cond do
  inline = Regex.run(...) -> ...
  block = Regex.run(...) -> ...
  Regex.match?(~r/^requirements-completed:/m, frontmatter) ->
    raise "requirements-completed: is present but neither inline `[A, B]` nor multi-line `  - X` shape parsed"
  true -> []
end
```

**ID extraction/normalization pattern** (lines 97-113):
```elixir
Regex.scan(~r/\b([A-Z]+-\d+)\b/, text)
|> Enum.map(fn [_, id] -> id end)
|> Enum.uniq()
```

---

### `.planning/PROJECT.md` (config, transform)

**Analog:** `.planning/PROJECT.md`

**Canonical-arc reference pattern** (lines 42-50):
```markdown
## Next Milestone Candidates

The strategic source of truth remains `.planning/MILESTONE-ARC.md`. Current queue after v3.6:

- **Commerce provider adapters (v3.7)** ...
- **Full Sigra auth/session machinery (v3.8)** ...
```

**Requirement statements for strategic memory/closeout** (lines 94-95):
```markdown
- [ ] **STRAT-01**: ...
- [ ] **STRAT-02**: Maintainers have a milestone closeout checklist ...
```

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md`

**Phase detail pattern** (lines 75-86):
```markdown
**Phase 48: Strategic Signal and Milestone Memory**

Goal: Make `.planning/MILESTONE-ARC.md` the current strategic source of truth after v3.5.

Requirements: STRAT-01, STRAT-02

Success criteria:
1. ...
2. ...
3. ...
4. The milestone closeout checklist covers ...
```

**Milestone phase checklist shape** (lines 66-72):
```markdown
- [ ] Phase 48: ...
- [ ] Phase 49: ...
- [ ] Phase 50: ...
```

---

### `.planning/STATE.md` (config, transform)

**Analog:** `.planning/STATE.md`

**State frontmatter/status pattern** (lines 1-14):
```yaml
---
gsd_state_version: 1.0
milestone: v3.6
milestone_name: Operator Truth and Production Diagnostics
status: Ready for phase discussion
last_updated: "2026-05-31T18:29:41.418Z"
progress:
  total_phases: 6
  completed_phases: 0
---
```

**Operational continuity pattern** (lines 64-88):
```markdown
## Deferred Items
| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
...

## Operator Next Steps
- Start Phase 48 with /gsd-discuss-phase 48
```

## Shared Patterns

### Canonical Source Referencing
**Sources:** `.planning/PROJECT.md` lines 44-45, `.planning/ROADMAP.md` lines 77-79  
**Apply to:** `PROJECT.md`, `ROADMAP.md`, `STATE.md` updates in this phase
```markdown
The strategic source of truth remains `.planning/MILESTONE-ARC.md`.
```

### Closeout Ledger As Structured Frontmatter + Evidence Tables
**Sources:** `.planning/milestones/v3.5-MILESTONE-AUDIT.md` lines 1-45 and 57-68  
**Apply to:** new closeout artifact (`<milestone>-CLOSEOUT.md`) and closeout checklist sections
```yaml
status: passed
scores:
  requirements: 15/15
gaps:
  requirements: []
resolved_gaps:
  - phase: "43"
    status: "resolved"
    evidence: "..."
```

### Left-Shifted Deterministic Parity Tests
**Source:** `test/crosswake/planning/summary_frontmatter_test.exs` lines 14-47, 72-95  
**Apply to:** any new closeout/arc parity test in `test/crosswake/planning/*`
```elixir
assert Regex.match?(..., fm), "..."
...
Regex.match?(..., frontmatter) -> raise "..."
```

### Roadmap/Requirements Validation Command Convention
**Source:** `.planning/milestones/v3.5-MILESTONE-AUDIT.md` lines 61 and 138-140  
**Apply to:** closeout evidence and CI/local parity checks
```text
gsd-sdk query roadmap.analyze
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | All implied files have close role/flow analogs in current repo. |

## Metadata

**Analog search scope:** `.planning/`, `.planning/milestones/`, `test/crosswake/planning/`  
**Files scanned:** 8 primary files + grep inventory across `.planning` and `test`  
**Pattern extraction date:** 2026-05-31
