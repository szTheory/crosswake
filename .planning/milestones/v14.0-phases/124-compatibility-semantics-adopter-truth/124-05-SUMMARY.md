---
phase: 124-compatibility-semantics-adopter-truth
plan: "05"
subsystem: changelog-upgrade-impact
tags: [changelog, contributing, testing, docs-contract, compat-05]
dependency_graph:
  requires: ["124-02"]
  provides: ["changelog-upgrade-impact-labels", "contributing-intent-gate", "release-boundaries-vocabulary-parity-test"]
  affects: ["CHANGELOG.md", "CONTRIBUTING.md", "test/crosswake/guides/release_boundaries_test.exs"]
tech_stack:
  added: []
  patterns:
    - Keep-a-Changelog per-release ### Upgrade Impact subsection convention
    - worst-case-wins changelog label (fail-safe toward native rebuild)
    - ExUnit vocabulary/legend parity test with shared locked 4-string module attribute
    - historical_changelog_line?/1 reuse for changelog section parsing
key_files:
  created:
    - CONTRIBUTING.md
  modified:
    - CHANGELOG.md
    - test/crosswake/guides/release_boundaries_test.exs
decisions:
  - "CHANGELOG.md [0.1.2] labeled 'native or companion rebuild required' (worst-case-wins) with enumerated core-only/no-native-rebuild exceptions for Threadline + doctor additions"
  - "[0.1.0] also retro-labeled (optional per D-19) with 'native or companion rebuild required' — initial scaffold adoption always requires native build"
  - "Test 1 structural: uses historical_changelog_line?/1 as section delimiter to find ## [x.y.z] releases, asserts exactly one ### Upgrade Impact per section"
  - "Test 2 vocabulary/legend: @upgrade_impact_change_classes module attribute shared across assertions so rename breaks both tests together"
  - "No historical exemption list needed since both existing releases are now labeled; test checks all versioned sections"
  - "CONTRIBUTING.md created as new file (not section in existing doc) — no existing contributor doc existed"
metrics:
  duration: "~5m"
  completed: "2026-06-20"
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 124 Plan 05: Changelog Upgrade-Impact Labels Summary

Adopters can now triage release notes without reading the diff. Each `## [x.y.z]` heading in CHANGELOG.md carries a `### Upgrade Impact` subsection (first, before `### Added`) that headlines the release's highest-impact change class using one of the four verbatim change-class strings from the canonical taxonomy.

## What Was Built

### CHANGELOG.md — ### Upgrade Impact subsections

Added `### Upgrade Impact` as the first subsection under both versioned releases:

**[0.1.2] — 2026-06-17:** Headlined `native or companion rebuild required` (published SwiftPM/Maven native shell packages — worst-case-wins). Enumerated lower-impact exceptions:
- `core-only/no native rebuild` — Threadline observability
- `core-only/no native rebuild` — doctor publish-readiness checks, expanded guide set, seam contracts

**[0.1.0] — 2026-05-29:** Headlined `native or companion rebuild required` (initial release; adopters must scaffold and build native hosts from scratch).

Retro-labeling is optional per D-19; both releases were labeled since the effort was trivial and makes the test unconditionally meaningful.

### CONTRIBUTING.md — Human intent-gate convention (new file)

Created `CONTRIBUTING.md` documenting:
- The four verbatim change-class strings (table with plain-English meanings)
- The worst-case-wins rule with an example of a mixed release
- A how-to-choose checklist (4 decision questions, fail-safe toward rebuild)
- Explicit statement that this is a human review gate (not auto-derived)
- Links to `guides/compatibility.md` and `guides/support_matrix.md#change-classes`

### test/crosswake/guides/release_boundaries_test.exs — Two new test blocks

**@upgrade_impact_change_classes** module attribute added: the locked 4-string list shared across both new tests, so a vocabulary rename breaks guide test + changelog test together (D-19 legend parity requirement).

**TEST 1 — structural** (`upgrade impact — structural: every versioned release has exactly one block`):
- Uses `historical_changelog_line?/1` (same existing private helper, not a copy) to identify `## [x.y.z]` heading lines and split changelog into per-release sections via `split_changelog_into_release_sections/1`
- Asserts exactly one `### Upgrade Impact` per section
- `## [Unreleased]` and prose headings do not match `historical_changelog_line?/1`, so they are excluded from the check

**TEST 2 — vocabulary/legend parity** (`upgrade impact — vocabulary/legend parity: labels use the locked 4-string set and exist in support_matrix.md`):
- Extracts bold labels under `### Upgrade Impact` blocks via `extract_upgrade_impact_labels/1`
- Asserts each label is in `@upgrade_impact_change_classes` (minted tokens fail here)
- Asserts each of the 4 strings still exists verbatim in `guides/support_matrix.md` (legend drift fails here)

**No cry-wolf detection:** The tests do NOT assert "entry touches the contract but lacks a label" — that is explicitly prohibited by D-19 as unprovable from prose.

## Test Results

```
mix test test/crosswake/guides/release_boundaries_test.exs
8 tests, 0 failures  (6 pre-existing + 2 new)
```

Overall test suite: 1149 tests, 5 failures (all 5 are pre-existing, unchanged from before this plan).

## Threat Mitigations

| Threat ID | Disposition | Mitigation Applied |
|-----------|-------------|-------------------|
| T-124-12 | mitigate | Worst-case-wins rule in [0.1.2]: headlines native-rebuild, enumerates lower-impact exceptions for Threadline/doctor |
| T-124-13 | mitigate | Vocabulary/legend parity test: @upgrade_impact_change_classes shared list; rename breaks guide + changelog tests together |
| T-124-14 | accept | No cry-wolf intent detection; human review gate documented in CONTRIBUTING.md |
| T-124-SC | accept | No package-manager installs; markdown + ExUnit only |

## Deviations from Plan

None — plan executed exactly as written. The one judgment call (retro-labeling `[0.1.0]` — marked optional per D-19) was executed since the effort was trivial and makes the structural test unconditionally meaningful rather than vacuously passing on an empty set.

## Known Stubs

None. All Upgrade Impact labels are wired to real release content.

## Self-Check

### Created files exist:
- [x] `CONTRIBUTING.md` — created and verified
- [x] Both `### Upgrade Impact` blocks in `CHANGELOG.md` — verified with `grep -c '### Upgrade Impact' CHANGELOG.md` → 2

### Commits exist:
- [x] `4e1044e` — feat(124-05): add Upgrade Impact subsections to CHANGELOG + CONTRIBUTING intent gate
- [x] `05675ef` — test(124-05): add structural + vocabulary-parity Upgrade Impact tests to release_boundaries_test

## Self-Check: PASSED
