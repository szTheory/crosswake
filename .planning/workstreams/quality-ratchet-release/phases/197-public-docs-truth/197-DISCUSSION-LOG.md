# Phase 197: Public docs truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-29
**Phase:** 197-public-docs-truth
**Areas discussed:** Clean-room docs run, Version truth source, Report-mode docs checks, Android UAT stamp

The user selected all four areas and asked for a research fan-out per area (pros/cons, ecosystem
prior art, footguns, DX, small dependency trees) followed by one coherent set of recommendations.
Four advisor researchers ran in parallel (minimal_decisive tier); the orchestrator ran an
adversarial cross-check, corrected two findings, and presented one bundle, which the user locked.

---

## Clean-room docs run

| Option | Description | Selected |
|--------|-------------|----------|
| Marker-extracted docs leg | Run marked doc blocks verbatim | |
| Hand-mirrored docs leg | Script copies the steps | |
| Hybrid: markers + network-free marker test | Extraction plus a test that every fence is marked | ✓ |

**User's choice:** Lock all (recommended bundle).
**Notes:** Researcher proposed that Phase 197 only reach `result SELFTEST` (real PASS in 199).
Cross-check rejected that as shrinking SC1: the 0.2.11 release commit `7273e6cf` already ships
`gen.bridge_hook`, `Bridge.attach/1` and the esbuild wiring, so a `CLEANROOM_DOCS_REF` input
selector gives a real PASS against 0.2.11 now.

## Version truth source

| Option | Description | Selected |
|--------|-------------|----------|
| Live Hex query in the merge-blocking test | Network in a hermetic gate | |
| Manifest as source, generated cell, advisory live check | Researcher's pick | |
| Recorded registry snapshot | Copied literal with refresh ritual | |
| Delete the Current Version column, link to hex.pm, live check recorded as evidence | Orchestrator correction | ✓ |

**User's choice:** Lock all (recommended bundle).
**Notes:** Cross-check found that a guide-equals-manifest test would turn the release-please PR red
(the bot bumps the manifest, not the guide; hand edits to the bot branch are forbidden). Offered
"Keep version column" as an alternative; not chosen.

## Report-mode docs checks

| Option | Description | Selected |
|--------|-------------|----------|
| Local `script/docs-report`, counts in phase evidence | bearings-report shape, zero CI minutes | ✓ |
| Plus counts in an existing CI step summary | Touches a watched workflow | |
| New non-required CI job | CI cost, signal decay | |

**User's choice:** Lock all (recommended bundle).
**Notes:** Count only this cycle; baseline on main before any doc edit.

## Android UAT stamp

| Option | Description | Selected |
|--------|-------------|----------|
| Honest edit + two-way set-equality test now | Removes stamp and 4 phantoms with a guard | ✓ |
| Correct list only, defer guard to 198 | Leaves drift open a phase | |
| Generate list from registry now | Builds 198's ledger early | |

**User's choice:** Lock all (recommended bundle).

## Gate stance

| Option | Description | Selected |
|--------|-------------|----------|
| Same-PR contract tests merge-blocking; counters report-only | Tests land with 0 findings by construction | ✓ |
| All new tests report-only for one cycle | | |

---

## Claude's Discretion

Marker ids, substitution table, pinned `phx_new` version, `executed` floor value, plan/PR split,
test file names.

## Deferred Ideas

Leak-hit fixes and generator changes; `@moduledoc` leak scan; `docs-ios` leg; Android ledger
generation (198); scheduled advisory `release.status --live` job.
