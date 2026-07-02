---
phase: 129-stable-companion-contract-surface
plan: "02"
subsystem: companion-contract-surface
status: complete
tags: [seam, moduledoc, exdoc, guide, hex]
completed: "2026-06-25"
duration: "15m"

dependency_graph:
  requires: [phase129-companion-contract-freeze-test]
  provides: [companion-contract-surface-frozen, companion-contract-guide, companion-contract-hexdocs-groups]
  affects:
    - lib/crosswake/companion.ex
    - lib/crosswake/companion/state.ex
    - lib/crosswake/compatibility/compatibility.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/shell/denial.ex
    - guides/companion_contract.md
    - guides/companions.md
    - mix.exs

tech_stack:
  added: []
  patterns:
    - "@moduledoc since: on own line after closing triple-quote (A1 placement rule)"
    - "@typedoc immediately preceding @type t declaration (EEP-48 association)"
    - "groups_for_modules full-name atom list (no regex) for curated hexdocs groups (D-10)"
    - "guide+extras same-commit rule (Pitfall 2 — orphan-guard safety)"

key_files:
  created:
    - guides/companion_contract.md
  modified:
    - lib/crosswake/companion.ex
    - lib/crosswake/companion/state.ex
    - lib/crosswake/compatibility/compatibility.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/shell/denial.ex
    - mix.exs
    - guides/companions.md
    - test/crosswake/hex_page_test.exs
    - test/crosswake/guides/release_boundaries_test.exs

decisions:
  - "Task 1 and Task 2 split honored: moduledoc promotions committed before guide+groups (satisfies D-11 empty-group prerequisite and Pitfall 2 orphan-guard)"
  - "Companion Contract groups_for_modules uses full module atom list, not regex (D-10 — regex would pull entire Compatibility eval machinery)"
  - "Extension Authors extras group positioned between Truth and Advanced/Companions per D-10 audience JTBD ordering"
  - "guides/companion_contract.md and mix.exs extras registered in same commit (Pitfall 2 — orphan-guard)"

requirements: [SEAM-01, SEAM-02, SEAM-03, SEAM-04]
---

# Phase 129 Plan 02: Stable Companion Contract Surface Summary

Promoted 4 struct types from @moduledoc false, replaced Companion stale v3.5 sentence, added Denial steering note, created companion_contract.md guide, registered ExDoc groups — making the 129-01 freeze proof test fully green.

## What Was Built

### Task 1: Promote struct moduledocs + fix Companion stale line + Denial steering note (commit 405332c)

**lib/crosswake/companion.ex:** Replaced the stale opening paragraph ("Companions live in-tree for the v3.5 milestone...") with the frozen-surface paragraph naming exactly the 5 public modules and asserting semver stability under `crosswake` >= 0.1.0.

**lib/crosswake/companion/state.ex:** Promoted `@moduledoc false` to a real moduledoc with prose description, canonical `## Stability` section, `@moduledoc since: "0.1.0"` on its own line, and `@typedoc "Runtime state snapshot for a companion at a point in time."` immediately before `@type t`.

**lib/crosswake/compatibility/compatibility.ex:** Promoted both nested modules:
- `Crosswake.Compatibility.Target`: real moduledoc describing eval context, `## Stability`, `@moduledoc since: "0.1.0"`, `@typedoc "Request-time evaluation context..."` before `@type t`
- `Crosswake.Compatibility.Finding`: real moduledoc describing restriction evidence, companion→Denial delegation note, `## Stability`, `@moduledoc since: "0.1.0"`, `@typedoc "Restriction evidence emitted by a companion's route_gated?/2 callback."` before `@type t`

**lib/crosswake/manifest/types.ex:** Promoted `Crosswake.Manifest.Types.RouteEntry`: real moduledoc with D-06 scoping sentence using full module names (`Crosswake.Manifest.Types.Root`, `Crosswake.Manifest.Types.Compatibility`, etc.) to avoid naming collision with public `Crosswake.Compatibility`, `## Stability`, `@moduledoc since: "0.1.0"`, `@typedoc "Route definition struct passed to companion gate callbacks."` before `@type t`.

**lib/crosswake/shell/denial.ex:** Appended D-20 verbatim steering note paragraph to existing moduledoc. No `@moduledoc since:` added; Denial stays out of the "Companion Contract" group.

Post-task result: `mix compile --warnings-as-errors` clean; freeze test went from 3 failures to 2 (typedoc now green; guide-exists and Finding-present still pending Task 2 — expected).

### Task 2: Guide + ExDoc groups + cross-link + test guards (commit bbd2449)

**guides/companion_contract.md (created):** Diataxis reference guide with:
- Intro banner cross-linking companions.md and compatibility.md#companion-compatibility-contract
- 5-row Contract Surface table (Module / Role / What companion code does / Stability tier)
- Stability Tiers section (public stable + private bullet definitions)
- "What Is Not Contract" section explicitly listing Denial (including `Denial.reasons/0` prohibition), Manifest.Types nested modules, and parent Crosswake.Compatibility
- Declaring Compatibility section cross-linking compatibility.md without duplication
- Telemetry Events section listing 3 static companion span names, naming Crosswake.Companion moduledoc as source of truth

**mix.exs:** Three changes in same commit:
1. Added `"guides/companion_contract.md"` to extras list (between companions.md and compatibility.md)
2. Added `"Companion Contract": [Crosswake.Companion, Crosswake.Companion.State, Crosswake.Compatibility.Finding, Crosswake.Compatibility.Target, Crosswake.Manifest.Types.RouteEntry]` to `groups_for_modules` — full names, not regex
3. Added `"Extension Authors": ["guides/companion_contract.md"]` to `groups_for_extras` between Truth and Advanced/Companions

**guides/companions.md:** Added forward cross-link sentence near the top pointing to companion_contract.md. Existing `Denial.reasons/0` mention at ~line 167 preserved (accurate for core-operator audience per D-21 scope fence).

**test/crosswake/hex_page_test.exs:** Extended `groups_for_modules` membership loop to include `:"Companion Contract"` and `groups_for_extras` loop to include `:"Extension Authors"`.

Post-task result: 129-01 freeze proof test (6 tests) + hex_page_test (9 tests) = 15 tests, 0 failures.

## Test Results

```
mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs
15 tests, 0 failures

mix test (full suite)
1210 tests, 2 failures (11 excluded)
```

The 2 remaining full-suite failures are pre-existing:
- `Crosswake.Planning.MilestoneTransitionResetTest` — REQUIREMENTS.md header / milestone naming (pre-existing)
- `Crosswake.Proof.Phase52OperatorTruthTest` — publish-readiness JSON fixture (pre-existing)

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Promote 4 struct moduledocs, fix Companion stale line, add Denial steering note | 405332c | lib/crosswake/companion.ex, lib/crosswake/companion/state.ex, lib/crosswake/compatibility/compatibility.ex, lib/crosswake/manifest/types.ex, lib/crosswake/shell/denial.ex |
| 2 | Create companion_contract.md guide, register ExDoc groups, cross-link companions.md | bbd2449 | guides/companion_contract.md, mix.exs, guides/companions.md, test/crosswake/hex_page_test.exs, test/crosswake/guides/release_boundaries_test.exs |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed release_boundaries_test hardcoded groups_for_extras key list**
- **Found during:** Task 2
- **Issue:** `test/crosswake/guides/release_boundaries_test.exs` line 122 had a hardcoded `Keyword.keys(groups) == [:Start, :Adopt, :"Runtime Owners", :Truth, :"Advanced/Companions"]` equality assertion. Adding "Extension Authors" to groups_for_extras broke this test.
- **Fix:** Updated the equality assertion to include `:"Extension Authors"` in its correct ordered position: `[:Start, :Adopt, :"Runtime Owners", :Truth, :"Extension Authors", :"Advanced/Companions"]`
- **Files modified:** test/crosswake/guides/release_boundaries_test.exs
- **Commit:** bbd2449 (included in Task 2 single commit per plan requirement)

## Known Stubs

None. All 5 contract modules have real moduledocs; the guide is fully authored; the ExDoc groups are registered.

## Threat Flags

None — this plan edits moduledocs, one new markdown guide, ExDoc config, and config-assertion tests. No new network surface, no auth paths, no data storage, no runtime behavior change.

## Self-Check: PASSED

- [x] `guides/companion_contract.md` exists on disk
- [x] `lib/crosswake/companion/state.ex` no longer contains `@moduledoc false`
- [x] `lib/crosswake/compatibility/compatibility.ex` Target and Finding no longer contain `@moduledoc false`
- [x] `lib/crosswake/manifest/types.ex` RouteEntry no longer contains `@moduledoc false`
- [x] Commit 405332c present in git log
- [x] Commit bbd2449 present in git log
- [x] 15 tests (freeze proof + hex_page_test) pass: 0 failures
- [x] Full suite: 1210 tests, 2 pre-existing failures only (no regressions introduced)
- [x] `mix compile --warnings-as-errors` clean
