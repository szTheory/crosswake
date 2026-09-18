---
id: SEED-023
title: The scope-cardinality guard (assertFullScope) only protects check-actions — every other derived-scope check in the repo can still silently truncate
status: dormant
severity: medium
trigger_when: >-
  Surface when adding a new audit/check whose scope is derived from the filesystem
  or a glob, when reviewing `script/check_release_workflow_integrity.exs` or any
  other roster-driven checker for a hardcoded default, or when planning a phase
  whose scope is CI/CD hygiene or vacuous-assertion remediation generally.
  NOT blocking — `check-actions` itself, the one check known to have this defect
  (WINDOWS entry 35), is fully repaired by 175-01/175-02.
created: 2026-09-18
related: [SEED-018, SEED-022]
---

# SEED-023: `assertFullScope` is a reusable guard against scope truncation, but it is reused by exactly one caller

## The finding

175-01 (D-25) deliberately wrote `assertFullScope(actual, expected)` in
`scripts/ci_monitor.cjs` as a standalone, module-level function rather than inlining
the guard into `checkActions()` — specifically so that a future check "inherits it by
construction" rather than by copying. That intent is recorded, but as of Wave 0's close,
`checkActions()` remains the only caller. No other check in `scripts/ci_monitor.cjs`,
and no check outside that file (e.g. `script/check_release_workflow_integrity.exs`'s own
`@roster_ids`, or any other file-discovery-driven audit in `script/`), has been reviewed
for the same truncation risk `check-actions` had: a hardcoded default scope that silently
shrinks relative to what the check's own name and stated purpose claim to cover.

`check_release_workflow_integrity.exs`'s roster is a different, deliberate shape (D-25's
own commentary in `ci_monitor.cjs` notes this): that roster is DECLARED, never derived,
because it is a scope *selector* for per-lane emission checks, and deriving it from the
artifact it polices would let a lane that stopped emitting silently drop out of scope.
That file is explicitly not a candidate for this extension — but the reasoning that
excludes it was worked out ad hoc, once, for one file. No systematic sweep across
`script/` has confirmed which other checks share `check-actions`'s derive-from-filesystem
shape (and therefore need `assertFullScope` or an equivalent) versus
`check_release_workflow_integrity.exs`'s declare-as-selector shape (and therefore
correctly must NOT be converted).

## Why it's out of scope for Wave 0 (D-29)

D-29 explicitly places "extending the cardinality gate beyond `scripts/ci_monitor.cjs`
to other checks in the repo" outside Wave 0. Wave 0's mandate (D-21) was fixing the one
concretely identified defect — `checkActions()`'s three-file default — plus pinning the
31 refs it exposed, not auditing every other check in the repository for the same shape.

## What a remediation would look like

- Enumerate every check under `script/` and `scripts/` whose scope is derived from a
  filesystem walk, glob, or dynamic discovery (candidates: anything using
  `File.ls!`/`Path.wildcard` in Elixir, `fs.readdirSync`/`glob` in Node, `find`/`ls` in
  shell) rather than a literal, deliberately-declared roster.
- For each, classify it against the two shapes this finding names: "derive from the
  tree, must never silently shrink" (convert to use `assertFullScope` or an equivalent)
  versus "declare as a selector, deriving it would hide a regression" (leave alone,
  record the reasoning the way `ci_monitor.cjs`'s own comment does for
  `check_release_workflow_integrity.exs`).
- Extract `assertFullScope` to a location importable by both `.cjs` and any future
  checks outside `ci_monitor.cjs`'s own file, if the audit finds a second real caller —
  premature extraction with zero second callers would be speculative generality Wave 0
  correctly avoided.
