---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T00:00:00-04:00
status: complete
score: 58/58 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 57/58
  gaps_closed:
    - "Repository-facing private-term enforcement classifies cached and non-ignored candidates before scanning, including unregistered guides and later-phase artifacts."
  gaps_remaining: []
  regressions: []
gaps: []
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.
**Verified:** 2026-07-31T00:00:00-04:00
**Status:** complete
**Re-verification:** Yes — the sole 57/58 privacy-boundary blocker was re-evaluated from fresh Plan-16 execution evidence.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A session can discover GET-6 framing, Alpha/v1 split, stop list, and current phase. | ✓ VERIFIED | Governing artifacts remain linked from `AGENTS.md`; fresh focused context coverage passed. |
| 2 | Known adopter surfaces have one runtime owner and one authority/fallback story. | ✓ VERIFIED | Route map and fail-closed `RouteInventory` remain unchanged; fresh focused route/context/Mix-task/capability/support suite passed 122 tests. |
| 3 | v20 is preserved as partial work and Phases 156–157 are not represented as shipped active scope. | ✓ VERIFIED | Existing durable stopped/partial evidence remains in place; fresh context coverage passed. |
| 4 | Automated scans reject prohibited private terms from planning, agent, and public-guide surfaces. | ✓ VERIFIED | Fresh Git-backed classification regressions cover unregistered guide, Phase 159, workflow, source, and test candidates; production Mix scan and post-write scan passed. |

**Score:** 58/58 PLAN must-haves verified. The previous privacy-boundary blocker is closed by fresh executable evidence, not by copied historical status.

### Plan Must-Haves Matrix

| Plan | Truths | Status | Evidence |
| --- | ---: | --- | --- |
| 158-01 through 158-14 | 57 | ✓ 57/57 | Previously satisfied policy-contract evidence was preserved; this plan added no new work to RESET-01 through RESET-03. |
| 158-15 | 0 | ✓ IMPLEMENTED | Git candidate enumeration, closed classification, non-echoing diagnostics, and Mix-task regressions are present in the final tree. |
| 158-16 | 1 | ✓ 1/1 | Fresh protected, focused, live-scan, formatter, compile, full-suite, whitespace, and post-write gates all passed. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/planning/first_adopter_context.ex` | Privacy/context routing | ✓ VERIFIED | `git ls-files` candidate enumeration reaches safe classification, content scanning, and stable non-echoing violations. |
| `test/crosswake/planning/first_adopter_context_test.exs` | Repository-boundary tracer | ✓ VERIFIED | Exercises unregistered guide, Phase 159, workflow, source, test, unsafe/symlink, unknown-path, and enumeration-failure cases. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` and protected workflow | Merge gate | ✓ VERIFIED | Production task delegates to `scan_filesystem/2`; protected workflow invokes it and fork bypass remains blocked. |
| `158-VALIDATION.md` and this report | Fresh evidence ledgers | ✓ VERIFIED | Final Markdown artifacts passed the post-write production scan and focused scanner suites. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Git index and non-ignored worktree | candidate classification | `git -C ROOT ls-files --cached --others --exclude-standard -z` | WIRED | Candidate enumeration is deterministic and failure returns `routing.repository_enumeration_failed`. |
| candidate classification | file content scan | `scan_filesystem/2` | WIRED | Safe regular files use ordered classifications; unclassified/unsafe/unreadable paths fail closed. |
| file content scan | Mix task | `Mix.Tasks.Crosswake.AdoptionContext.Scan.run/1` | WIRED | Production regression proves unregistered guide and Phase 159 candidates return rule/path-only private-term violations. |
| Mix task | protected workflow | `mix crosswake.adoption_context.scan --require-private-terms` | WIRED | Trusted provenance runs the protected gate; forks receive a fail-closed bypass block without secret exposure. |

`@artifact_globs` remains public compatibility metadata for named destinations; it is not the discovery authority. No historical archive, ignored raw evidence, Git history, remote, or external source is used as a candidate source.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Privacy scanner | candidate paths | cached and non-ignored Git paths | classified repository-relative entries | ✓ FLOWING |
| Privacy scanner | classified entries | path rules → `scan_filesystem/2` | generic, destination, and protected private-term checks | ✓ FLOWING |
| Mix task | scan result | `scan_filesystem/2` → `run/1` | deterministic success or stable rule/path failure | ✓ FLOWING |
| Protected workflow | trusted-gate status | workflow → production Mix task | merge-blocking protected result without term disclosure | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Protected caller seam | `CROSSWAKE_PRIVATE_ADOPTER_TERMS="$(printf '%s-%s-%s' repository privacy sentinel)" mix test test/crosswake/planning/first_adopter_context_test.exs` | 14 tests, 0 failures | ✓ PASS |
| Route/context/Mix-task/capability/support behavior | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 122 tests, 0 failures | ✓ PASS |
| Live repository scan | `mix crosswake.adoption_context.scan` | passed | ✓ PASS |
| Full hermetic gate | `mix compile --warnings-as-errors && mix test --exclude requires_example_host --exclude advisory_only && git diff --check` | passed | ✓ PASS |
| Post-write evidence scan | `mix crosswake.adoption_context.scan && mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs && git diff --check` | passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source plan(s) | Status | Evidence |
| --- | --- | --- | --- |
| RESET-01 | 01–04, 09–10, 13–14 | ✓ SATISFIED | No change: durable GET-6 framing, support truth, and stop list remain discoverable. |
| RESET-02 | 01, 04–05, 07, 11, 14 | ✓ SATISFIED | No change: closed route/safety/promotion contract remains tested; TODO-002 is `unknown_blocking`. |
| RESET-03 | 03–04, 07, 10, 14 | ✓ SATISFIED | No change: v20 remains stopped/partial without a shipped claim; 156–157 remain outside active v21. |
| RESET-04 | 01–16 | ✓ SATISFIED | Fresh repository-wide candidate classification and non-echoing protected-scan evidence close the former fixed-allowlist bypass. |

### Anti-Patterns Found

None. The prior fixed-allowlist discovery boundary was removed by Plan 158-15 and Plan 158-16 confirmed its replacement from fresh executable evidence.

## Scope Boundaries Preserved

- TODO-002 remains open; concrete adopter-route inputs and adopter-instance completeness remain `unknown_blocking`.
- Phase 159 proof lane, Phase 160 replay, Phase 161 pack installation, and Phase 162 physical-device proof are not implemented or promoted here.
- Android remains frozen. Generic sync, generic storage, new UI/control breadth, identity discovery, and business-line expansion remain out of scope.

---

_Verified: 2026-07-31T00:00:00-04:00_
_Verifier: Plan 158-16 execution gate_
