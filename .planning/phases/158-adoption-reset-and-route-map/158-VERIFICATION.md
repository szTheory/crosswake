---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T14:18:54Z
status: gaps_found
score: 18/22 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Concrete route safety posture cannot inherit from product-surface defaults and promotion is fail-closed."
    status: failed
    reason: "Every safety field accepts status :known_default and promotion_status/1 blocks only :unknown_blocking, so a route whose safety contract is entirely defaults is eligible."
    artifacts:
      - path: "lib/crosswake/adoption/route_inventory.ex"
        issue: "validate_posture/3 accepts :known_default for all safety fields (lines 192-205); promotion_status/1 returns eligible whenever unknown_fields/1 is empty (lines 109-113)."
    missing:
      - "Reject :known_default for safety fields, or make promotion block it, with a regression test."
  - truth: "A concrete local-mutation route has a coherent, explicit authority, scope, fallback, disablement, retention, and recent-auth posture before it is eligible."
    status: failed
    reason: "The validator accepts :not_applicable without a value for every safety field and has no cross-field invariant validation. Contradictory or absent local-mutation safety posture is eligible."
    artifacts:
      - path: "lib/crosswake/adoption/route_inventory.ex"
        issue: "validate_posture/3 accepts :not_applicable unconditionally (lines 198-199); no call validates relationships such as local_first→offline_island/scope/fallback/disablement or recent_auth→recent_auth required."
    missing:
      - "Add route-state invariants and negative tests before promotion can return eligible."
  - truth: "Automated scans reject prohibited adopter identity or personal information across planning, agent, and public-guide surfaces."
    status: failed
    reason: "The privacy scanner has no production or CI caller, its static matrix omits current phase artifacts, and private-term scanning intentionally skips every PLAN file."
    artifacts:
      - path: "lib/crosswake/planning/first_adopter_context.ex"
        issue: "routing_matrix omits 158-03-SUMMARY, 158-04 PLAN/SUMMARY, and VALIDATION; private_term_scanned?/1 excludes *-PLAN.md (lines 191-198)."
    missing:
      - "Wire a merge-blocking filesystem scan over approved planning/agent/public artifact globs and add plan, summary, and validation canaries."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify first-adopter routes, update support truth, and install privacy-safe context routing, while keeping every known first-adopter surface explicitly owned and avoiding prohibited adopter identity data.
**Verified:** 2026-07-31T14:18:54Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Sanitized concrete route patterns validate without resource-instance facts. | ✓ VERIFIED | `RouteInventory.validate/1` validates closed opaque rows; focused test passed. |
| 2 | Missing/blank/nil safety input is explicit or rejected without echoing it. | ✓ VERIFIED | Required-field and non-echoing error checks in `route_inventory_test.exs:31-49` passed. |
| 3 | Duplicate IDs/paths reject and declaration order remains stable. | ✓ VERIFIED | `validate_inventory/1` collision checks plus focused tests at lines 51-87 passed. |
| 4 | Empty inventory blocks promotion. | ✓ VERIFIED | `promotion_status([])` returns `{:blocked, %{reason: :empty_inventory}}` at lines 107-113; tested. |
| 5 | Confirmed values can be eligible and `unknown_blocking` blocks. | ✓ VERIFIED | `unknown_fields/1` and the focused blocked-media test provide this narrow behavior. |
| 6 | Closed size/codec values reject exact private fields. | ✓ VERIFIED | Closed validators and forbidden-field test passed; no raw value is echoed. |
| 7 | Safety posture never silently inherits from defaults. | ✗ FAILED | `:known_default` is accepted for every safety field and a directly executed all-default row returned `{:eligible, row}`. |
| 8 | Local mutation/recent-auth safety combinations are coherent before promotion. | ✗ FAILED | A directly executed `:local_first` row with absent scope/fallback/disablement/retention and contradictory recent-auth posture returned `{:eligible, row}`. |
| 9 | Capability rows use canonical `adoption_implication` with a bounded legacy alias. | ✓ VERIFIED | Renderer has one `normalize_implication/1`; focused compatibility/conflict tests passed. |
| 10 | Capability rendering is deterministic and public wording is narrow. | ✓ VERIFIED | Capability guide renderer parity is true; focused test suite passed. |
| 11 | Every active first-adopter artifact is centrally classified once. | ✗ FAILED | The hard-coded matrix omits current phase artifacts including `158-03-SUMMARY.md`, `158-04-PLAN.md`, `158-04-SUMMARY.md`, and `158-VALIDATION.md`; its drift check cannot see omitted filesystem paths. |
| 12 | Empty/duplicate/unclassified matrix entries fail and matrix iteration is stable. | ✓ VERIFIED | `validate_routing_matrix/1` and its focused synthetic duplicate/empty tests pass for entries supplied to it. |
| 13 | v20 is stopped/partial without a shipped claim; 156-157 are outside active v21 scope. | ✓ VERIFIED | Archive declares `STOPPED / PARTIAL`, no tag, and phases 156-157 stopped; focused test passed. |
| 14 | Generic plus configured private-term scans are safe and non-echoing. | ✗ FAILED | Scanner is only invoked by its tests (`rg` found no non-test caller); therefore no CI or production boundary enforces the scan. |
| 15 | Durable/public codename split is mechanically enforced across scope. | ✗ FAILED | The registered scope is incomplete and PLAN files are excluded from private-term scanning, so the claimed repository-wide enforcement does not hold. |
| 16 | Support guide separates policy completion from adopter/host/device proof. | ✓ VERIFIED | Guide explicitly retains `unknown_blocking` and `verification required`; renderer output equals checked-in guide. |
| 17 | Guide preserves explicit known-surface ownership and narrow iOS/Android/authority boundaries. | ✓ VERIFIED | Route-policy map and support renderer state owner, fallback, Android freeze, one-island, and host-owned `gated_by` boundaries. |
| 18 | Support guide is public-safe and byte-identical to canonical renderer output. | ✓ VERIFIED | Direct `mix run` parity check printed `support guide parity: true`; generic pattern scan found no matches in registered files. |
| 19 | All focused Phase 158 tests pass inside the stated sampling budget. | ✓ VERIFIED | Quick command passed: 100 tests, 0 failures; privileged canary passed: 7 tests, 0 failures (2.0 seconds total). |
| 20 | GET-6 framing, Alpha/v1 split, stop list, and current phase are discoverable. | ✓ VERIFIED | ADR, adoption brief, route map, AGENTS.md, roadmap, and state contain the required documented contract; focused discoverability test passed. |
| 21 | Every known product surface has one stated owner and authority/fallback story. | ✓ VERIFIED | Route-policy map’s default ownership table enumerates study, read-only neighbors, auth/settings/billing, audio, deferred capture, and disablement. |
| 22 | Public planning and guide surfaces reject prohibited identity/personal data. | ✗ FAILED | Same incomplete, unwired scanner defect as truths 11/14/15; an omitted planning artifact can be committed without a scan. |

**Score:** 18/22 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed validator and promotion boundary | ⚠️ HOLLOW | Exists (337 lines) and is tested, but unsafe/default and incoherent rows can promote. |
| `test/crosswake/adoption/route_inventory_test.exs` | Route/privacy/promotion proof | ⚠️ INCOMPLETE | Exists and runs, but contains no default-safety or cross-field-invariant regression. |
| `FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Route ownership and route contract | ✓ VERIFIED | Substantive table and contract; code contradicts its `known_default` safety rule. |
| `lib/crosswake/capability_map.ex` / `renderer.ex` | Canonical implication + compatibility renderer | ✓ VERIFIED | Substantive, wired, and parity-tested. |
| `guides/capability_map.md` | Generated public capability guide | ✓ VERIFIED | Direct renderer byte-parity check passed. |
| `lib/crosswake/planning/first_adopter_context.ex` | Central privacy/context routing | ⚠️ HOLLOW | Substantive library/test seam, but incomplete scope and no enforcing caller. |
| `lib/crosswake/support_matrix/renderer.ex` / `guides/support_matrix.md` | Canonical support truth | ✓ VERIFIED | Renderer is invoked in tests; direct checked-in byte parity passed. |
| `158-VALIDATION.md` | Validation ledger | ⚠️ STALE CLAIM | Exists and is substantive, but its “no unresolved high-severity threat” sign-off is contradicted by the three reproducible blockers above. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route-policy map | RouteInventory | closed vocabulary | ⚠️ PARTIAL | Shared `unknown_blocking` vocabulary exists, but runtime promotion does not enforce the map’s known-default restriction. |
| RouteInventory | Route inventory tests | focused ExUnit | ⚠️ PARTIAL | Imported/exercised tests exist; critical default and cross-field paths are untested. |
| Capability map | capability renderer | `adoption_implication` | ✓ WIRED | Renderer normalizes canonical/legacy inputs and tests exercise it. |
| Capability renderer | capability guide | renderer write/parity | ✓ WIRED | Direct byte-parity check passed. |
| Context scanner | CI/repository filesystem | privacy enforcement | ✗ NOT WIRED | No non-test caller was found. |
| Support renderer | support guide | renderer output/parity | ✓ WIRED | `First Adopter Readiness` exists with space spelling; tool pattern’s hyphen mismatch was false-negative, direct parity proves link. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Capability guide | canonical capability rows | `CapabilityMap.canonical/0` → renderer | Yes | ✓ FLOWING |
| Support guide | canonical support matrix | `SupportMatrix.canonical/0` → renderer | Yes | ✓ FLOWING |
| Context scan | `contents_by_path` | Caller-provided map only | No filesystem/CI producer | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused phase contract | `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 100 tests, 0 failures | ✓ PASS |
| Private-term canary | `CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs` | 7 tests, 0 failures | ✓ PASS |
| Unsafe default promotion | `mix run --no-start -e ...` with all safety values `:known_default` | Returned `{:eligible, row}` | ✗ FAIL |
| Incoherent local mutation promotion | `mix run --no-start -e ...` with `:not_applicable` scope/fallback/disablement/retention and contradictory recent-auth | Returned `{:eligible, row}` | ✗ FAIL |
| Generated-guide parity | `mix run --no-start -e ...` | support and capability parity both `true` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| RESET-01 | 02, 03, 04 | Durable GET-6 decision, scope audit, non-goals, stop list | ✓ SATISFIED | Discoverability docs and capability/support truth are present and focused tests pass. |
| RESET-02 | 01, 04 | Explicit owner, offline, authority, fallback, disablement posture | ✗ BLOCKED | Static default ownership table is present, but executable route promotion accepts inherited and incoherent safety posture. |
| RESET-03 | 03, 04 | v20 stopped/partial; 156-157 absent from active scope | ✓ SATISFIED | Archive and active-roadmap assertions are explicit and test-backed. |
| RESET-04 | 01, 02, 03, 04 | No prohibited adopter identity/personal information | ✗ BLOCKED | Privacy scanner has incomplete coverage and no CI/production enforcement path. |

All requirement IDs declared across Plan frontmatter are present in `REQUIREMENTS.md`; no orphaned Phase 158 requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `route_inventory.ex` | 192-205 | All statuses accepted for safety fields | 🛑 BLOCKER | Defaults may become concrete route authority. |
| `route_inventory.ex` | 198-199 | Unconditional `not_applicable` | 🛑 BLOCKER | A local-mutation route can promote without scope/fallback/disablement/retention. |
| `first_adopter_context.ex` | 19-86, 191-198 | Static incomplete scope and blanket plan exclusion | 🛑 BLOCKER | Prohibited term can enter unscanned planning surfaces. |
| `capability_map/renderer.ex` | 184-191 | Formatting drift | ⚠️ WARNING | `mix format --check-formatted` failed. |
| `renderer_test.exs` | 63, 135-139 | Formatting drift | ⚠️ WARNING | `mix format --check-formatted` failed. |

### Gaps Summary

The review’s three critical findings are genuine. The phase produces useful documentation and generated-guide truth, and the focused suite is green, but the fail-closed executable boundary required by RESET-02 is not achieved: unsafe default or semantically incomplete route rows can become eligible. RESET-04 is also not achieved: the privacy scanner is a test-only library seam with an incomplete hard-coded file list and plan exclusion, not an automated repository gate.

Later phases do not explicitly schedule correction of this route-validator or Phase 158 planning-scan enforcement. These gaps are not deferred.

---

_Verified: 2026-07-31T14:18:54Z_
_Verifier: the agent (gsd-verifier)_
