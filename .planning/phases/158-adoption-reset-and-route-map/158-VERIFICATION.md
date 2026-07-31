---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T17:58:00Z
status: complete
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "Tracked, non-ignored recognized text now receives private-term enforcement through direct and production scanner paths."
  gaps_remaining: []
  regressions: []
gaps: []
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.
**Verified:** 2026-07-31T17:58:00Z
**Status:** complete
**Re-verification:** Yes — the sole RESET-04 classification gap was re-evaluated from fresh final-tree and post-write evidence.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover infrastructure framing, first-adopter/v1 split, stop list, and current phase. | ✓ VERIFIED | ADR, adoption brief, route map, ROADMAP, STATE, and focused context evidence remain aligned. |
| 2 | Every known adopter surface has one runtime owner and one authority/fallback story. | ✓ VERIFIED | Route-policy map supplies owner/offline/authority-fallback rows; focused route tests passed. |
| 3 | v20 is preserved as partial work without representing later stopped work as shipped active scope. | ✓ VERIFIED | ROADMAP and milestone records preserve the stopped/partial posture; focused archive assertion passed. |
| 4 | Automated scans reject prohibited identity or personal information from planning and public adoption artifacts. | ✓ VERIFIED | Fresh direct and production Mix-task evidence covers action, script, and arbitrary future planning candidates; final ledgers also passed the post-write production scan. |

**Score:** 4/4 roadmap must-haves verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed sanitized route contract and promotion boundary | ✓ VERIFIED | Substantive validator functions remain exercised by focused route tests. |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Surface ownership and route-local posture | ✓ VERIFIED | Documents owner/authority/fallback posture and `unknown_blocking`. |
| `lib/crosswake/capability_map.ex` and `lib/crosswake/capability_map/renderer.ex` | Canonical adoption implication and generated support truth | ✓ VERIFIED | Focused capability/support suite passed. |
| `lib/crosswake/planning/first_adopter_context.ex` | Privacy-safe repository context routing | ✓ VERIFIED | Recognized tracked text scans by default; raw/binary exclusions are explicit and unknown candidates fail closed. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` and `.github/workflows/hex-page-proof.yml` | Protected CI enforcement | ✓ VERIFIED | Production task delegates to the repaired scanner and protected workflow invokes the task. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Git-backed candidates | `classify_repository_path/1` | repository enumeration → per-path classification | WIRED | Cached and non-ignored candidates are classified before read. |
| Classification | content checks | classified readable text → file reads → `scan_filesystem/2` | WIRED | Recognized text reaches private-term checks; raw/binary paths remain explicit exclusions. |
| Context scanner | Mix task | `scan_filesystem/2` → `Mix.Tasks.Crosswake.AdoptionContext.Scan.run/1` | WIRED | Focused production task regressions reject all three former bypass classes. |
| Mix task | protected workflow | `mix crosswake.adoption_context.scan --require-private-terms` | WIRED | Workflow keeps the protected caller seam in CI. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Privacy scanner | candidate entries | cached/non-ignored repository enumeration | classification outcome, then readable text content | ✓ FLOWING |
| Classification | scan eligibility | `classify_repository_path/1` | scan-by-default for recognized text; only raw/binary evidence excluded | ✓ FLOWING |
| Content scanner | stable violations | file reads through `scan_filesystem/2` | rule IDs and relative paths | ✓ FLOWING |
| Protected Mix task | scanner violations | `Mix.Tasks.Crosswake.AdoptionContext.Scan.run/1` | production enforcement result | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Protected direct scanner seam | Process-assembled protected-term focused context test | 15 tests, 0 failures | ✓ PASS |
| Action, script, future-planning, raw/binary, and unknown classification | Focused route/context/Mix/capability/support gate | 124 tests, 0 failures | ✓ PASS |
| Production repository scan | `mix crosswake.adoption_context.scan` | Passed before and after ledger writes | ✓ PASS |
| Build and regression safety | Formatter, warnings-as-errors compile, hermetic suite, whitespace check | All exited zero | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 01–04, 09–10, 13–14 | Durable infrastructure decision, scope audit, non-goals, stop list | ✓ SATISFIED | Existing governing artifacts and focused context evidence remain intact. |
| RESET-02 | 01, 04–05, 07, 11, 14 | Explicit runtime ownership/offline/authority/fallback/disablement posture | ✓ SATISFIED | Route map and focused route tests remain green. |
| RESET-03 | 03–04, 07, 10, 14 | Honest v20 stopped/partial archive | ✓ SATISFIED | Existing archive posture remains unchanged. |
| RESET-04 | 01–18 | No prohibited identity or personal information in planning/public adoption artifacts | ✓ SATISFIED | Fresh final-tree direct, Mix-task, live-scan, and post-write evidence closes the tracked-text classification gap. |

### Anti-Patterns Found

None in the inspected Phase 158 privacy-routing implementation. The prior finite planning-range and action/script text exclusions are no longer present in the final-tree classification behavior.

### Boundary Preservation

TODO-002 remains open and first-adopter-instance completeness remains `unknown_blocking`. This verification does not promote Android work, generic sync/storage, physical-device proof, or Phase 159–162 support claims; it only closes the repository text-classification gap.

### Gaps Summary

No Phase 158 verification gaps remain. RESET-04 is closed solely because fresh evidence proves the direct scanner and production Mix task reject the three former bypass classes, preserve narrow explicit exclusions, fail closed for unknowns, and scan the final ledgers successfully.

---

_Verified: 2026-07-31T17:58:00Z_
_Verifier: the agent (gsd-verifier)_
