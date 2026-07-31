---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T00:00:00-04:00
status: gaps_found
score: 57/58 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: complete
  previous_score: 46/46
  gaps_closed: []
  gaps_remaining:
    - "Repository-facing private-term enforcement does not classify or scan unregistered tracked artifacts."
  regressions:
    - "The prior 46/46 ledger treated a fixed Phase-158 artifact allowlist as a complete privacy boundary."
gaps:
  - truth: "A centralized privacy/context routing matrix classifies and scans every active repository-facing first-adopter artifact, so configured private terms cannot bypass the protected CI gate."
    status: failed
    reason: "scan_filesystem/2 discovers only the fixed @artifact_globs allowlist. It omits 25 of 27 tracked guides and every phase directory other than Phase 158; an unregistered guide, source, test, workflow, or later-phase artifact is never read and therefore cannot emit privacy.private_term."
    artifacts:
      - path: "lib/crosswake/planning/first_adopter_context.ex"
        issue: "discovered_entries/1 expands only @artifact_globs (lines 29-51), with no tracked-file enumeration or fail-closed unclassified-path check."
      - path: "test/crosswake/planning/first_adopter_context_test.exs"
        issue: "Future-artifact coverage creates only .planning/phases/158-adoption-reset-and-route-map paths; no regression proves an unregistered guide, workflow, source/test, or later phase fails."
    missing:
      - "Derive scan targets from tracked, non-ignored repository files or maintain exhaustive permitted directory rules and fail on every unclassified repository-facing path."
      - "Add a regression that puts a process-assembled private-term canary in an unregistered guide and a later-phase artifact and asserts privacy.private_term without echoing content."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.
**Verified:** 2026-07-31T00:00:00-04:00
**Status:** gaps_found
**Re-verification:** Yes — prior completion ledger independently rechecked after `158-REVIEW.md` CR-01.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A session can discover GET-6 framing, Alpha/v1 split, stop list, and current phase. | ✓ VERIFIED | `AGENTS.md` links the governing ADR, adoption brief, route map, roadmap, and state; focused context tests passed. |
| 2 | Known adopter surfaces have one runtime owner and one authority/fallback story. | ✓ VERIFIED | Route map enumerates ownership/fallbacks; `RouteInventory` validates closed route rows and blocks empty/unknown inventories; 66 focused tests passed. |
| 3 | v20 is preserved as partial work and Phases 156–157 are not represented as shipped active scope. | ✓ VERIFIED | `.planning/milestones/v20.0-ROADMAP.md` says `STOPPED / PARTIAL`, no shipped/tag claim, and lists 156–157 as stopped; context test passes. |
| 4 | Automated scans reject prohibited private terms from planning, agent, and public-guide surfaces. | ✗ FAILED | The protected workflow invokes the task, but task discovery is a narrow fixed allowlist. It never scans most tracked guides or any later phase, so a configured term can bypass CI. |

**Score:** 57/58 PLAN must-haves verified. The failed privacy-boundary truth is also Roadmap success criterion 4 and blocks goal achievement.

### Plan Must-Haves Matrix

| Plan | Truths | Status | Evidence |
| --- | ---: | --- | --- |
| 158-01 | 7 | ✓ 7/7 | Route inventory source is substantive, documents match the closed vocabulary, and focused route tests passed. |
| 158-02 | 4 | ✓ 4/4 | Canonical implication normalizer, deterministic renderer, and guide parity are implemented and exercised. |
| 158-03 | 6 | ⚠ 5/6 | The matrix, v20 archive assertions, and non-echoing behavior exist; its claimed complete active-path classification is false outside the fixed list. |
| 158-04 | 5 | ✓ 5/5 | Support renderer emits policy-vs-proof boundary; renderer tests and source→guide path are present. |
| 158-05 | 5 | ✓ 5/5 | `known_default`, cross-field safety, and eligible synthetic-row checks are exercised through public promotion APIs. |
| 158-06 | 5 | ✓ 5/5 within declared Phase-158 scope | Globs scan the listed Phase-158 PLAN/SUMMARY/VALIDATION artifacts and workflow/task wiring exists; this does not repair the broader failed privacy boundary. |
| 158-07 | 4 | ✓ 4/4 | Validation ledger records the specified focused and formatting evidence. |
| 158-08 | 3 | ✓ 3/3 | Workflow has trusted-PR secret gate and fork fail-closed path; workflow test passes. |
| 158-09 | 3 | ✓ 3/3 | Capability guide wording/parity and frozen scope are covered by renderer tests. |
| 158-10 | 4 | ✓ 4/4 | Ledger has explicit command/input accounting and does not contain a complete protected canary literal. |
| 158-11 | 3 | ✓ 3/3 | Opaque `route-` + 16-lowercase-hex grammar and non-echoing path validation are in the public validation path. |
| 158-12 | 3 | ✓ 3/3 | Registered-artifact spelling and identifying-field checks return rule/path-only failures. |
| 158-13 | 2 | ✓ 2/2 | Renderer format and deterministic guide behavior are covered. |
| 158-14 | 4 | ✓ 4/4 | Final ledger references the repaired gates and keeps TODO-002/later-phase claims bounded. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed route contract/promotion boundary | ✓ VERIFIED | 426 substantive lines; validates opaque IDs/path grammar before postures and blocks empty/unknown inventories. |
| `test/crosswake/adoption/route_inventory_test.exs` | Fail-closed route regressions | ✓ VERIFIED | Included in 66 passing focused tests. |
| `lib/crosswake/capability_map/renderer.ex` and `guides/capability_map.md` | Canonical deterministic public capability truth | ✓ VERIFIED | `normalize_implication/1`, `render/1`, `write/0`, and byte-parity tests are wired. |
| `lib/crosswake/support_matrix/renderer.ex` and `guides/support_matrix.md` | Honest policy/proof support truth | ✓ VERIFIED | Renderer emits `unknown_blocking` proof boundary; support renderer tests pass. |
| `lib/crosswake/planning/first_adopter_context.ex` | Privacy/context routing | ✗ HOLLOW | Substantive and wired to Mix/CI, but its fixed allowlist leaves repository-facing paths outside all scan/data flow. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` and workflow | Merge gate | ✗ PARTIAL | Workflow runs task on trusted PR/main/manual and blocks forks, but the invoked scanner has incomplete coverage. |
| Route map and v20 roadmap | Durable route/v20 contract | ✓ VERIFIED | Explicit `unknown_blocking` and stopped/partial/no-shipped claims are present and tested. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route policy map | `RouteInventory` | Shared closed vocabulary/promotion | WIRED | `unknown_blocking`/`known_default` documented and executable; focused tests pass. |
| Capability data | capability renderer → guide | Normalizer/render/write + parity | WIRED | Direct symbols and parity test present. |
| Support matrix | support renderer → guide | Render/write + parity | WIRED | `First Adopter Readiness` emitted at renderer line 331; focused test passes. |
| Workflow | Mix privacy task → context scanner | `mix crosswake.adoption_context.scan` → `scan_filesystem/2` | PARTIAL / BLOCKER | Invocation is real, but `discovered_entries/1` only expands fixed allowlist globs. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Route inventory | route postures | caller input → validators → `promotion_status/1` | Closed, fail-closed rows | ✓ FLOWING |
| Capability/support guides | canonical rows/matrix | canonical modules → renderers → checked-in Markdown | Generated deterministic content | ✓ FLOWING |
| Privacy scanner | entries/private terms | `@artifact_globs` → `Path.wildcard/1` → content scan | Only registered subset; unregistered paths absent | ✗ HOLLOW |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Route, context, Mix-task, capability, and support behavior | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs test/crosswake/support_matrix/renderer_test.exs` | 66 tests, 0 failures | ✓ PASS |
| Registered repository scan | `mix crosswake.adoption_context.scan` | `adoption context scan passed` | ✓ PASS (insufficient scope) |
| Unregistered repository artifact scan | Static trace of `@artifact_globs` and `discovered_entries/1` | No tracked-file enumeration/unclassified-path rejection; 25/27 tracked guides and non-158 phases are absent | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
| --- | --- | --- | --- |
| RESET-01 | 01–04, 09–10, 13–14 | ✓ SATISFIED | Discoverable GET-6 decision, route/support/capability truth, and stop list are present. |
| RESET-02 | 01, 04–05, 07, 11, 14 | ✓ SATISFIED | Closed route/safety/promotion contract passes focused tests; TODO-002 remains correctly `unknown_blocking`. |
| RESET-03 | 03–04, 07, 10, 14 | ✓ SATISFIED | v20 archive is stopped/partial without a shipped claim; 156–157 excluded from active v21. |
| RESET-04 | 01–04, 06–14 | ✗ BLOCKED | The secret-aware gate does not cover all planning/public adoption artifacts; fixed allowlist permits silent bypass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/planning/first_adopter_context.ex` | 29–51, 158–176 | Fixed narrow allowlist used as privacy boundary | 🛑 BLOCKER | New repository-facing artifacts are not classified or scanned. |
| `test/crosswake/planning/first_adopter_context_test.exs` | 107–133 | Future test limited to Phase 158 paths | ⚠️ WARNING | Passing test does not exercise the missing unregistered/later-phase error path. |

## Gaps Summary

CR-01 is confirmed independently. The current scanner is not a fail-closed repository privacy gate: `discovered_entries/1` expands 19 explicit entries only, including two guide files and Phase 158 alone. It does not derive from tracked files and does not report paths that match no allowlist rule. Consequently a later-phase file, a new public guide, a workflow, or most source/tests containing a configured protected term cannot be detected by the CI command even though the command exits zero.

This is not deferred: phases 159–162 concern proof, replay, pack installation, and device evidence, not the Phase-158 privacy-routing contract. TODO-002 is intentionally `unknown_blocking` and does not affect this policy-contract verdict.

---

_Verified: 2026-07-31T00:00:00-04:00_
_Verifier: the agent (gsd-verifier)_
