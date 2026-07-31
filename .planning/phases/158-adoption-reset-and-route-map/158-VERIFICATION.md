---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T17:28:24Z
status: gaps_found
score: 3/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: complete
  previous_score: 58/58
  gaps_closed: []
  gaps_remaining:
    - "Repository-facing private-term enforcement scans every relevant tracked, non-ignored planning and CI artifact."
  regressions:
    - "The prior report's claimed Git-backed repository-wide scanner omits tracked .github/actions/, script/, and future .planning phase artifacts."
gaps:
  - truth: "Automated scans reject prohibited adopter identity or personal information from planning and public adoption artifacts."
    status: failed
    reason: "The protected filesystem scanner excludes some tracked, non-ignored repository paths before private-term checks, including future planning artifacts. A synthetic temporary-repository probe returned zero violations for three excluded candidate classes."
    artifacts:
      - path: "lib/crosswake/planning/first_adopter_context.ex"
        issue: "classify_repository_path/1 routes explicit exclusions to scan?: false; phase_artifact_path?/1 has a fixed Phase 158-162 range."
      - path: "test/crosswake/planning/first_adopter_context_test.exs"
        issue: "Regression coverage proves an unregistered workflow path but not .github/actions/, script/, or future-phase planning candidates."
      - path: "test/mix/tasks/crosswake_adoption_context_scan_test.exs"
        issue: "Production task regression covers an unregistered guide and Phase 159 only, not the excluded classes."
    missing:
      - "Classify all tracked, non-ignored textual repository artifacts as scan candidates by default; retain only explicit raw/binary evidence exclusions."
      - "Remove action/script exclusions and replace the finite phase range with a future-safe planning classification."
      - "Add direct and Mix-task regressions for the formerly excluded candidate classes with rule/path-only assertions."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.
**Verified:** 2026-07-31T17:28:24Z
**Status:** gaps_found
**Re-verification:** Yes — previous closeout report independently re-evaluated.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover infrastructure framing, Alpha/v1 split, stop list, and current phase. | ✓ VERIFIED | `AGENTS.md` links governing artifacts; ADR records GET-6 and reversal conditions; ROADMAP/STATE name Phase 158 and the stop date. Focused context test passed. |
| 2 | Every known adopter surface has one runtime owner and one authority/fallback story. | ✓ VERIFIED | Route-policy map supplies owner/offline/authority-fallback rows; `RouteInventory` rejects missing/unknown safety posture and blocked promotion. Focused route tests passed. |
| 3 | v20 is preserved as partial work without representing Phases 156-157 as shipped active scope. | ✓ VERIFIED | ROADMAP and MILESTONES identify v20 as stopped/partial, not shipped/no completion tag; focused context test passed. |
| 4 | Automated scans reject prohibited adopter identity or personal information from planning and public adoption artifacts. | ✗ FAILED — BLOCKER | The scanner is wired into CI but deliberately sets `scan?: false` for some tracked textual candidates. A fresh synthetic temporary-repository probe covering an action, script, and future planning artifact returned `violations=0`; future planning artifacts therefore bypass protected-term enforcement. |

**Score:** 3/4 roadmap must-haves verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed sanitized route contract and promotion boundary | ✓ VERIFIED | Substantive public validator functions; exercised by focused route tests. |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Surface ownership and route-local posture | ✓ VERIFIED | Documents each owner/authority/fallback and `unknown_blocking`; matches validator vocabulary. |
| `lib/crosswake/capability_map.ex` and `lib/crosswake/capability_map/renderer.ex` | Canonical adoption implication and generated support truth | ✓ VERIFIED | Renderer write paths exist; focused parity/compatibility tests passed. |
| `lib/crosswake/support_matrix/renderer.ex` and `guides/support_matrix.md` | Generated narrow support claim | ✓ VERIFIED | Renderer has write path; parity assertion at `renderer_test.exs:346` was exercised in the focused suite. |
| `lib/crosswake/planning/first_adopter_context.ex` | Privacy-safe repository context routing | ✗ HOLLOW — BLOCKER | Substantive and called by the Mix task, but data flow discards excluded textual candidates before content/private-term checks. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` and `.github/workflows/hex-page-proof.yml` | Protected CI enforcement | ⚠️ PARTIAL | Workflow invokes the Mix task, including protected-term mode, but inherits the scanner bypass. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route-policy map | `RouteInventory` | Closed status/field vocabulary and focused route tests | WIRED | `unknown_blocking`, `known_default`, empty inventory, and promotion cases are exercised. |
| Capability/support renderers | Checked-in guides | renderer write paths and byte-parity tests | WIRED | Focused suite: 122 tests, 0 failures. |
| Git-backed candidates | Context scanner content checks | `repository_candidates` → classification → `filesystem_content_violations` | NOT_WIRED FOR ALL CANDIDATES | Explicit exclusions result in `scan?: false`, so private-term checks never receive those candidate contents. |
| Context scanner | Mix task | `scan_filesystem/2` | PARTIAL | Delegation is present, but it propagates the exclusion bypass. |
| Mix task | protected workflow | `mix crosswake.adoption_context.scan --require-private-terms` | PARTIAL | The command is present for trusted provenance; its candidate coverage is incomplete. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Route inventory | validated row/posture | public validator input | Closed structured values with blocked promotion for unknowns | ✓ FLOWING |
| Generated guides | canonical map/matrix rows | Elixir canonical sources | Deterministic rendered Markdown with parity tests | ✓ FLOWING |
| Privacy scanner | candidate entries | cached and non-ignored Git paths | Some textual candidates are explicitly marked non-scanned before read/check | ✗ DISCONNECTED FOR EXCLUDED CLASSES |
| Protected Mix task | scanner violations | `scan_filesystem/2` | Stable rule/path output for scanned candidates only | ⚠️ STATIC BOUNDARY |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Route, context, Mix-task, capability, and support behavior | Focused `mix test` across the six phase test targets | 122 tests, 0 failures | ✓ PASS |
| Generic live repository scan | `mix crosswake.adoption_context.scan` | `adoption context scan passed` | ✓ PASS — insufficient for protected-term scope |
| Formatting of Phase 158 sources/tests | Explicit `mix format --check-formatted` list | Exit 0 | ✓ PASS |
| Excluded candidate private-term enforcement | Fresh temporary Git repository, synthetic non-sensitive canary assembled at runtime | 3 candidate paths; 0 violations | ✗ FAIL |

The passing scanner tests are misleading for this truth: they cover an unregistered workflow under `.github/workflows/` and Phase 159, but not the explicitly excluded action/script paths or phases beyond the fixed range.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 01–04, 09–10, 13–14 | Durable infrastructure decision, scope audit, non-goals, stop list | ✓ SATISFIED | ADR, adoption brief, route map, AGENTS, ROADMAP, and STATE are discoverable and focused context test passes. |
| RESET-02 | 01, 04–05, 07, 11, 14 | Explicit runtime ownership/offline/authority/fallback/disablement posture | ✓ SATISFIED | Route map and closed `RouteInventory` implementation; focused route tests pass. |
| RESET-03 | 03–04, 07, 10, 14 | Honest v20 stopped/partial archive; 156–157 absent from active scope | ✓ SATISFIED | MILESTONES/ROADMAP text and focused archive assertion pass. |
| RESET-04 | 01–16 | No prohibited identity or personal information in planning/public adoption artifacts | ✗ BLOCKED | Future planning artifacts and other tracked textual classes can bypass configured private-term enforcement. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/planning/first_adopter_context.ex` | 284–288 | Finite phase artifact classification | 🛑 Blocker | Future planning artifacts become excluded from private-term scanning. |
| `lib/crosswake/planning/first_adopter_context.ex` | 320–340 | Explicit action/script exclusions preceding general text classification | 🛑 Blocker | Tracked textual CI/script candidates are dropped before protected-term checks. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the inspected Phase 158 implementation files.

### Gaps Summary

Phase 158 does achieve its adoption framing, route-policy, support-truth, and v20 archive outcomes. It does not achieve the required privacy-safe context-routing outcome: the protected scan is not repository-wide despite the prior report’s claim. This is an **Escalation Gate**: privacy coverage must be repaired and re-verified before Phase 159 proceeds.

Recommended next action: create a narrow gap-closure plan for RESET-04 that makes tracked, non-ignored textual artifacts scan-by-default, preserves explicit raw/binary exclusions and non-echoing diagnostics, and adds production-seam regressions for the three bypass classes.

---

_Verified: 2026-07-31T17:28:24Z_
_Verifier: the agent (gsd-verifier)_
