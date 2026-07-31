---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T18:04:57Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: complete
  previous_score: 4/4
  gaps_closed: []
  gaps_remaining:
    - "Repository-wide generic privacy rules are not applied to every scanned textual artifact."
    - "RouteInventory.validate/1 crashes on non-atom map keys instead of returning a safe structured error."
  regressions: []
gaps:
  - truth: "Planning and public adoption artifacts are protected by privacy-safe context routing, including generic personal/commercial-detail rules."
    status: failed
    reason: "Scannable but unregistered text is read and private-term checked, but generic_violations/2 is skipped unless policy_scan? is true. An unregistered guide containing a generic commercial-detail pattern returns no violation when the configured-term list is empty."
    artifacts:
      - path: "lib/crosswake/planning/first_adopter_context.ex"
        issue: "policy_scan_path?/1 limits generic policy enforcement to named artifacts and Phase 158; all other recognized text follows the empty policy_violations/2 clause."
    missing:
      - "Apply generic privacy checks to every scan?: true artifact, and keep destination-specific checks scoped only where necessary."
      - "Add direct scanner and production Mix-task regressions for generic violations in unregistered guide/source/action/script/later-phase paths."
  - truth: "Unsupported route-row map input is rejected through a stable, non-echoing validation error."
    status: failed
    reason: "validate/1 accepts maps via Map.to_list/1 then calls Keyword.keys/1. A map containing a non-atom unknown key raises ArgumentError before RouteInventory can return ValidationError."
    artifacts:
      - path: "lib/crosswake/adoption/route_inventory.ex"
        issue: "normalize_input/1 does not reject non-atom keys before reject_forbidden_fields/1 and reject_unknown_fields/1 use Keyword APIs."
    missing:
      - "Validate map keys before Keyword processing and return a stable generic field/reference without interpolating an untrusted key."
      - "Add a regression proving non-atom key and value input cannot crash or appear in Exception.message/1."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.
**Verified:** 2026-07-31T18:04:57Z
**Status:** gaps_found
**Re-verification:** Yes — independent re-verification after a prior `complete` report.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A session can discover the infrastructure framing, Alpha/v1 split, stop list, and active phase. | ✓ VERIFIED | `AGENTS.md`, ADR, adoption brief, route map, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` contain the framing; the focused context test passes. |
| 2 | Each known adopter surface has an explicit runtime owner, offline posture, authority/fallback story, with unknown route facts blocked. | ✓ VERIFIED | Route-policy map supplies the surface table and blocks adopter-instance completion; `RouteInventory` rejects defaults for safety fields and `promotion_status/1` blocks empty/unknown inventories. 38 focused route/context/Mix-task tests pass. |
| 3 | v20 is preserved as stopped/partial without presenting Phases 156–157 as shipped. | ✓ VERIFIED | `.planning/milestones/v20.0-ROADMAP.md` states `STOPPED / PARTIAL`, prohibits a completion tag, and identifies 156–157 as incomplete; roadmap and milestone index agree. |
| 4 | Automated privacy scanning protects planning and public adoption artifacts against prohibited identity and personal/commercial detail. | ✗ FAILED | Generic privacy rules are skipped for non-named scanned text. A temporary tracked `guides/unregistered.md` with a generic commercial-detail pattern returned `[]` from `scan_filesystem(root, [])`. |
| 5 | Invalid route-row map input receives the documented safe, stable validator error. | ✗ FAILED | Passing a map with a non-atom unknown key raises `ArgumentError` from `Keyword.keys/1`, not `{:error, %ValidationError{}}`; no existing regression covers this boundary. |

**Score:** 3/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed route contract and promotion boundary | ⚠️ PARTIAL | Exists, is substantive, and is exercised; non-atom map-key validation is unwired from the safe-error boundary. |
| `test/crosswake/adoption/route_inventory_test.exs` | Route safety/privacy regression proof | ⚠️ PARTIAL |  Focused tests pass but do not exercise non-atom map keys. |
| `lib/crosswake/planning/first_adopter_context.ex` | Repository privacy routing and scanner | ⚠️ PARTIAL | Candidate enumeration and private-term flow work, but generic policy flow is gated by `policy_scan?`. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` | Production privacy gate | ⚠️ PARTIAL | Delegates correctly to `scan_filesystem/2`, therefore reproduces the generic-policy coverage gap. |
| `lib/crosswake/capability_map.ex` / `renderer.ex` | Canonical support implication and generated guide | ✓ VERIFIED | Artifact checks pass; focused renderer tests pass and public guide does not contain the durable codename/hyphenated public phrase. |
| `lib/crosswake/support_matrix/renderer.ex` / `guides/support_matrix.md` | Honest generated support truth | ✓ VERIFIED | Artifact checks and focused renderer tests pass. |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Explicit layered owner/authority contract | ✓ VERIFIED | Documents closed statuses, all required safety fields, unknown-blocking state, and TODO-002 remains open. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route-policy map | `RouteInventory` | Shared status vocabulary and promotion boundary | ✓ WIRED | `unknown_blocking`, `known_default`, and validator entry points agree. |
| `RouteInventory` | Route inventory tests | Public validate-to-promotion paths | ⚠️ PARTIAL | Tests cover normal/sanitized paths but omit the non-atom map-key error path. |
| Context scanner | Mix task | `scan_filesystem/2` result becomes Mix failure | ✓ WIRED | The task delegates directly; temporary-root result proves the same generic-policy bypass reaches production caller. |
| Context scanner | CI workflow | `mix crosswake.adoption_context.scan` | ✓ WIRED | Workflow calls both normal and trusted protected scans; mutable third-party action tags remain a review warning, not this phase-goal blocker. |
| Capability/support renderers | Guides | Renderer tests and generated Markdown | ✓ WIRED | Focused renderer tests passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `FirstAdopterContext` | repository candidate entries | `git ls-files --cached --others --exclude-standard -z` → classification → file reads | Yes, but generic policy checks are conditional on `policy_scan?` | ⚠️ HOLLOW POLICY FLOW |
| `RouteInventory` | normalized route fields | caller map/keyword input → validation → promotion status | Yes for atom-key inputs; non-atom key reaches Keyword API exception | ⚠️ PARTIAL |
| Capability/support guides | canonical rows/support matrix | renderer input → Markdown output | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Route/context/Mix-task focused behavior | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | 38 tests, 0 failures | ✓ PASS (coverage incomplete) |
| Capability/support rendering | `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs test/crosswake/support_matrix/renderer_test.exs` | 32 tests, 0 failures | ✓ PASS |
| Compile boundary | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Normal repository scanner | `mix crosswake.adoption_context.scan` | `adoption context scan passed` | ✓ PASS (does not prove generic coverage) |
| Generic rule on unregistered guide | temporary tracked guide → `scan_filesystem(root, [])` | returned `[]` despite generic commercial-detail pattern | ✗ FAIL |
| Non-atom route map key | `RouteInventory.validate/1` with synthetic string key | raises `ArgumentError` from `Keyword.keys/1` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 01–04, 07–18 | Durable infrastructure decision, audit, non-goals, and stop list | ✓ SATISFIED | Governing docs and focused context tests retain the discoverable reset and deterministic maps. |
| RESET-02 | 01, 04–05, 07, 14 | Every known surface has explicit owner/posture/authority/fallback/disablement | ✓ SATISFIED | Route-policy map and support truth give each known surface a story; unknown concrete rows remain promotion-blocked. |
| RESET-03 | 03–04, 07, 14 | v20 stopped/partial; 156–157 absent from active scope | ✓ SATISFIED | v20 archive and active v21 roadmap are consistent and explicit. |
| RESET-04 | 01–04, 06–18 | Planning and public artifacts contain no prohibited identity or personal information | ✗ BLOCKED | Repository scanner has a demonstrable generic-rule bypass for unregistered, otherwise scanned text. |

No orphaned Phase 158 requirements were found: all four requirement IDs appear in plan frontmatter and are accounted for above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/planning/first_adopter_context.ex` | 301–304, 399–402 | Generic policy gate restricted to named paths/Phase 158 | 🛑 BLOCKER | New textual artifacts can bypass generic privacy rules. |
| `lib/crosswake/adoption/route_inventory.ex` | 148, 151–162 | Map normalization feeds non-atom keys to Keyword APIs | 🛑 BLOCKER | Invalid untrusted input escapes the module's structured safe-error contract. |
| `.github/workflows/hex-page-proof.yml` | 38, 41 | Third-party actions use movable tags | ⚠️ WARNING | Trusted CI executes mutable action revisions; pin to reviewed SHAs separately. |

### Gaps Summary

The phase is not ready to proceed. The normal and protected private-term scanner flow is wired, but its generic personal/commercial privacy checks are not repository-wide: recognized text outside the named list can be scanned and still receive no generic policy evaluation. This falsifies the claimed privacy-safe context-routing boundary and blocks RESET-04.

Separately, the route inventory advertises map input and safe stable errors, yet a non-atom map key crashes in `Keyword.keys/1`. The code-review claim that this path echoes a key was not confirmed—the actual observed defect is an unhandled exception—but that still fails the validator's documented safe-error contract.

TODO-002 remains open; adopter-instance completeness, later phases, Android posture, and `.planning/config.json` were not altered.

---

_Verified: 2026-07-31T18:04:57Z_
_Verifier: the agent (gsd-verifier)_
