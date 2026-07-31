---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31
status: complete
score: 46/46 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 41/46
  gaps_closed:
    - Opaque route identifiers and generic Phoenix templates are mechanically closed.
    - Standalone prohibited public spelling is rejected by the live scanner contract.
    - Identifying-field matching retains assignment precision and the final registered-artifact scan is green.
    - The renderer and all Plan 158-11 through 158-13 Elixir paths pass the complete formatter gate.
  gaps_remaining: []
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify first-adopter routes, update support truth, and install privacy-safe context routing without widening scope.

**Verified:** 2026-07-31
**Status:** complete
**Re-verification:** Yes — after Plans 158-11 through 158-14

## Goal Achievement

### Observable Truths

| # | Truth | Status | Fresh evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover GET-6 framing, the Alpha/v1 split, stop list, and current phase. | VERIFIED | Governing artifacts and focused context suite passed in Plan 158-14. |
| 2 | Known first-adopter surfaces have explicit owner, offline posture, authority/fallback, and disablement stories, while unsupplied inputs remain blocked. | VERIFIED | Route inventory and support evidence retain closed safety posture and `unknown_blocking` promotion denial. |
| 3 | v20 is preserved as stopped/partial, without shipping 156–157. | VERIFIED | Focused context evidence preserves stopped/partial and inactive-scope truth. |
| 4 | Protected private-term enforcement runs before trusted PR merge and forks cannot consume the secret. | VERIFIED | Protected caller seam passed using runtime-assembled input; workflow behavior remains covered by focused context tests. |
| 5 | Sanitized route rows cannot persist identifying/adopter-specific references. | VERIFIED | Route suite passed with opaque `route-` plus 16 lowercase hexadecimal identifiers and a closed generic path grammar. |
| 6 | Canonical capability/support renderers produce deterministic checked-in guides with the public phrase. | VERIFIED | Focused capability/support suites and complete renderer formatting gate passed. |
| 7 | Privacy/context routing is a passing, non-echoing filesystem gate over registered Phase-158 artifacts. | VERIFIED | `mix crosswake.adoption_context.scan` passed both before and after the final ledgers were written. |
| 8 | The public phrase split is mechanically enforced by the scanner, not only by renderer-specific tests. | VERIFIED | Focused context and Mix-task suites passed with direct and filesystem scanner regressions. |
| 9 | Phase closeout evidence is current and formatting-clean. | VERIFIED | Fresh warnings-as-errors compile, hermetic suite, seven-path formatter, and whitespace gates passed. |

**Score:** 46/46 PLAN must-haves verified. This score closes demonstrated Phase 158 policy-contract gaps only; it is not evidence of adopter-instance completion.

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed route contract and promotion evaluation | VERIFIED | Mechanically opaque references and generic templates fail closed. |
| `test/crosswake/adoption/route_inventory_test.exs` | Route fail-closed regressions | VERIFIED | Focused route suite passed. |
| `FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Layered inventory and unresolved-input boundary | VERIFIED | Remains the durable contract; TODO-002 is still open. |
| Capability map, renderer, and generated guide | Canonical implication / deterministic public output | VERIFIED | Focused suites and complete formatter gate passed. |
| Context scanner, Mix task, and workflow | Privacy routing and merge gate | VERIFIED | Protected, direct, filesystem, live-repository, and Mix-task paths are covered; live scan passed. |
| Support renderer and guide | Honest policy-versus-proof support truth | VERIFIED | Focused support suite passed; physical/device claims remain verification-required. |
| `158-VALIDATION.md` | Reproducible Phase-158 gate evidence | VERIFIED | Current commands and observed results are recorded; final ledger scan passed. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route policy map | `RouteInventory` | Shared closed vocabulary / promotion path | WIRED | Focused route validation passed with opaque reference regressions. |
| Capability canonical data | renderer → capability guide | `Renderer.render/write` plus parity | WIRED | Focused capability suite and renderer format check passed. |
| Support canonical matrix | renderer → support guide | Canonical matrix to deterministic renderer | WIRED | Focused support suite passed. |
| Context scanner | Mix task → workflow | `scan_filesystem/2` / CI commands | WIRED | Protected and live filesystem scanner paths passed. |
| Context globs | Final Phase-158 records | Registered `158-*.md` scan scope | WIRED | Post-write scan passed against this validation and verification evidence. |

## Data-Flow Trace

| Artifact | Data variable | Source → result | Status |
| --- | --- | --- | --- |
| Route inventory | opaque route reference / posture | caller input → closed validator → promotion status | FLOWING, FAIL-CLOSED |
| Context scanner | discovered paths / private terms | registered globs plus process-only environment input → stable rule/path results | FLOWING, NON-ECHOING |
| Renderers | canonical rows / matrix | canonical modules → checked-in Markdown guides | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result |
| --- | --- | --- |
| Protected caller seam | `CROSSWAKE_PRIVATE_ADOPTER_TERMS="$(printf '%s-%s-%s' runtime privacy sentinel)" mix test test/crosswake/planning/first_adopter_context_test.exs` | 12 tests, 0 failures. |
| Route/context/task/capability/support gate | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 120 tests, 0 failures. |
| Live and post-write privacy gate | `mix crosswake.adoption_context.scan` | passed before ledger edits and after both final artifacts were written. |
| Complete changed-Elixir formatting | `mix format --check-formatted` with the seven paths listed in `158-VALIDATION.md` | passed. |
| Compile / hermetic suite / whitespace | `mix compile --warnings-as-errors && mix test --exclude requires_example_host --exclude advisory_only && git diff --check` | passed. |

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| RESET-01 | SATISFIED | Durable governing framing and capability/support evidence remain discoverable and pass focused verification. |
| RESET-02 | SATISFIED | Closed route validation and explicit fail-closed promotion posture pass focused tests; unsupplied instance inputs remain blocked. |
| RESET-03 | SATISFIED | Focused context proof preserves stopped/partial v20 and inactive 156–157 scope. |
| RESET-04 | SATISFIED | Protected caller seam, exact public spelling, precise identifying-field scanner, live filesystem scan, and post-ledger scan all pass. |

## Remaining Boundary

TODO-002 remains open. Adopter-instance completeness is `unknown_blocking` until sanitized concrete route IDs/paths and associated host inputs are supplied. This report does not promote Phase 159–162 work, Android, proof-lane generation, scoped replay, media packs, physical-device proof, generic sync/storage, UI breadth, or any adopter identity fact.

## Conclusion

The four repair groups are closed from fresh Plan 158-14 evidence: opaque route references, exact public spelling, identifying-field precision with a green live scan, and complete renderer formatting. Phase 158 is complete at its policy-contract boundary while its intentionally unsupplied adopter-instance inputs remain blocked.
