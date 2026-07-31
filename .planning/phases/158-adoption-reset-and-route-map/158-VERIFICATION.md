---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T16:00:59Z
status: gaps_found
score: 41/46 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/11
  gaps_closed:
    - "Trusted same-repository pull requests now run the protected private-term scan; forks fail closed without repository-secret exposure."
    - "The generated capability guide now uses the approved public phrase and remains byte-identical to its renderer."
    - "The ledger uses explicit formatter inputs and a runtime-assembled protected canary."
  gaps_remaining:
    - "The route inventory accepts customer-like identifiers and path segments despite its opaque/sanitized contract."
    - "The privacy scanner treats the prohibited hyphenated public spelling as compliant."
    - "The current Phase 158 scan and focused context test fail because the scanned review artifact trips the generic identifying-field pattern."
  regressions:
    - "lib/crosswake/capability_map/renderer.ex fails mix format --check-formatted."
gaps:
  - truth: "A sanitized concrete Phoenix route pattern can be validated without recording an adopter-specific fact."
    status: failed
    reason: "RouteInventory accepts arbitrary human-readable route_id and path_pattern strings, including customer-like values, and retains them in its validated struct."
    artifacts:
      - path: "lib/crosswake/adoption/route_inventory.ex"
        issue: "validate_route_id/1 permits any lowercase slug and validate_path_pattern/2 permits arbitrary static path segments."
    missing:
      - "Constrain route references to mechanically opaque IDs and an allowlisted non-identifying route-template grammar; add negative regressions."
  - truth: "The durable codename/public phrase split is mechanically enforced across the registered public scope."
    status: failed
    reason: "destination_violations/3 accepts both the approved phrase and the prohibited hyphenated variant, so the scanner emits no violation for a public artifact containing only that variant."
    artifacts:
      - path: "lib/crosswake/planning/first_adopter_context.ex"
        issue: "The public_phrase regex at line 176 is /first adopter|first-adopter/i."
    missing:
      - "Require only the approved phrase, reject the hyphenated spelling with a stable rule ID, and add scanner-path regression coverage."
  - truth: "The unmodified repository passes the enforcing filesystem privacy gate and the focused RESET-04 suite."
    status: failed
    reason: "The scanner's own Phase-158 glob includes 158-REVIEW.md; that report contains the generic customer-name phrase and causes both the real Mix gate and the context test to fail."
    artifacts:
      - path: ".planning/phases/158-adoption-reset-and-route-map/158-REVIEW.md"
        issue: "Line 74 matches privacy.identifying_field."
      - path: "test/crosswake/planning/first_adopter_context_test.exs"
        issue: "The clean-repository assertion fails with the live scan result."
    missing:
      - "Make the generic identifying-field rule precise enough to avoid safe review terminology, or revise the reviewed artifact without weakening detection of actual sensitive fields; then prove the real gate passes."
  - truth: "The Phase 158 validation ledger's formatting evidence remains reproducible."
    status: failed
    reason: "The changed capability renderer currently fails the repository formatter, while the final ledger does not include that changed file in its explicit formatting command."
    artifacts:
      - path: "lib/crosswake/capability_map/renderer.ex"
        issue: "mix format --check-formatted reports unformatted match clauses at lines 184-190."
      - path: ".planning/phases/158-adoption-reset-and-route-map/158-VALIDATION.md"
        issue: "Its explicit formatter list omits the changed renderer."
    missing:
      - "Format the renderer and record a fresh phase gate that includes all changed Elixir sources."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify first-adopter routes, update support truth, and install privacy-safe context routing without widening scope.

**Verified:** 2026-07-31T16:00:59Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover GET-6 framing, the Alpha/v1 split, stop list, and current phase. | ✓ VERIFIED | `AGENTS.md`, ADR, brief, roadmap, state, and the context regression expose the required framing. |
| 2 | Known first-adopter surfaces have explicit owner, offline posture, authority/fallback, and disablement stories, while unsupplied inputs remain blocked. | ✓ VERIFIED | Route map/support guide state the layered policy contract; `RouteInventory` blocks empty and `unknown_blocking` promotion and rejects inherited safety defaults. |
| 3 | v20 is preserved as stopped/partial, without shipping 156–157. | ✓ VERIFIED | v20 archive, milestones, roadmap, and context test retain stopped/partial, no-tag, inactive-scope truth. |
| 4 | Protected private-term enforcement runs before trusted PR merge and forks cannot consume the secret. | ✓ VERIFIED | Workflow lines 55–66 use same-repository provenance, secret-backed protected scan, and a secret-free fork failure path. |
| 5 | Sanitized route rows cannot persist identifying/adopter-specific references. | ✗ FAILED | A direct public API call accepts `route_id: "acme-customer"` and `path_pattern: "/customer/acme-customer"`. |
| 6 | Canonical capability/support renderers produce deterministic checked-in guides with the public phrase. | ✓ VERIFIED | 103 targeted tests passed; capability and support byte parity each evaluated `true`; guide scan found no prohibited public spelling. |
| 7 | Privacy/context routing is a passing, non-echoing filesystem gate over registered Phase-158 artifacts. | ✗ FAILED | `mix crosswake.adoption_context.scan` fails with only `privacy.identifying_field .planning/phases/158-adoption-reset-and-route-map/158-REVIEW.md`; it does not echo matched content. |
| 8 | The public phrase split is mechanically enforced by the scanner, not only by renderer-specific tests. | ✗ FAILED | Direct `FirstAdopterContext.scan/1` with the public guide changed to `first-adopter` returns no guide violation. |
| 9 | Phase closeout evidence is current and formatting-clean. | ✗ FAILED | The live focused context test is red and `mix format --check-formatted lib/crosswake/capability_map/renderer.ex` is red. |

**Score:** 41/46 PLAN must-haves verified (0 present, behavior-unverified). The five failed plan-level truths are the four grouped blockers below plus the Plan 06 clean-repository claim, which fails for the same live scanner defect.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed route contract and promotion evaluation | ✗ PARTIAL | Substantive and tested for statuses/invariants, but the two supposedly opaque reference fields accept identifying values. |
| `test/crosswake/adoption/route_inventory_test.exs` | Route fail-closed regressions | ⚠️ PARTIAL | 12 route tests are included in the passing 103-test run, but no regression rejects customer/taxonomy-like route references. |
| `FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Layered inventory and unresolved-input boundary | ✓ VERIFIED | Documents explicit route-local fields, `unknown_blocking`, and open TODO-002. |
| Capability map, renderer, and generated guide | Canonical implication / deterministic public output | ⚠️ PARTIAL | Data flow and byte parity work, but the renderer is unformatted. |
| Context scanner, Mix task, and workflow | Privacy routing and merge gate | ✗ PARTIAL | Wiring and secret boundary exist; public-phrase rule is incomplete and the real scan is currently red. |
| Support renderer and guide | Honest policy-versus-proof support truth | ✓ VERIFIED | Renderer feeds the generated guide; physical/device claims remain `verification required`. |
| `158-VALIDATION.md` | Reproducible Phase-158 gate evidence | ✗ PARTIAL | It is substantive and records prior evidence, but its formatting list omits a changed unformatted file and the live focused context gate is red. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route policy map | `RouteInventory` | Shared closed vocabulary / promotion path | WIRED | Tests exercise `validate` and `promotion_status`; the privacy constraint within that path is incomplete. |
| Capability canonical data | renderer → capability guide | `Renderer.render/write` plus parity | WIRED | Direct byte-parity spot-check passed. |
| Support canonical matrix | renderer → support guide | `SupportMatrix.canonical` → `Renderer.render` | WIRED | Direct byte-parity spot-check passed. |
| Context scanner | Mix task → workflow | `scan_filesystem/2` / CI commands | WIRED BUT FAILING | The workflow calls the task correctly, but the task presently exits non-zero. |
| Context globs | current/future Phase-158 records | `.planning/phases/.../158-*.md` | WIRED | The review report is discovered, demonstrating the link and the false-positive failure. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Route inventory | route ID / path / postures | caller input → validator → promotion status | ⚠️ UNSAFE | Values flow and are retained, including arbitrary customer-like strings. |
| Context scanner | discovered entries / private terms | destination globs + process-only environment input | ⚠️ PARTIAL | Real files are scanned with non-echoing rule/path output, but public-wording detection is incomplete and a safe review term makes the gate red. |
| Renderers | canonical rows/matrix | canonical modules → Markdown guides | ✓ FLOWING | Both current guides equal renderer output. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Route, task, capability, and support focused regressions | `mix test test/crosswake/adoption/route_inventory_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 103 tests, 0 failures | ✓ PASS |
| Full current focused Phase-158 suite | `mix test ... first_adopter_context_test.exs ...` | 112 tests, 1 failure: clean scan assertion | ✗ FAIL |
| Real filesystem privacy gate | `mix crosswake.adoption_context.scan` | `privacy.identifying_field .../158-REVIEW.md` | ✗ FAIL |
| Public phrase scanner | `mix run -e` invoking `FirstAdopterContext.scan/1` on `first-adopter` guide content | No guide violation | ✗ FAIL |
| Route-reference sanitization | `mix run -e` invoking public `RouteInventory.validate/1` | Returned `{:ok, %RouteInventory{route_id: "acme-customer", path_pattern: "/customer/acme-customer"}}` | ✗ FAIL |
| Changed renderer formatting | `mix format --check-formatted lib/crosswake/capability_map/renderer.ex` | Exit non-zero; lines 184–190 differ | ✗ FAIL |
| Compile / full test suite | Fresh gate evidence supplied with this verification: `mix compile --warnings-as-errors` and 1321 tests / 0 failures after `77bd46a4` | Does not exercise the privacy bypasses above | ℹ️ NOT OVERRIDING |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 02, 03, 04, 09, 10 | Durable infrastructure framing, reversal, audit, non-goals, stop list | ✓ SATISFIED | Governing artifacts and generated truth are present, wired, and tested. |
| RESET-02 | 01, 04, 05, 07, 10 | Explicit owner/offline/authority/fallback/disablement posture | ✓ SATISFIED | Layered map and public route-validation/promotion regressions demonstrate closed safety posture; concrete input stays blocked. |
| RESET-03 | 03, 04, 10 | Honest stopped/partial v20, 156–157 outside active scope | ✓ SATISFIED | Archive and regression evidence are consistent. |
| RESET-04 | 01, 02, 03, 04, 06, 07, 08, 09, 10 | Planning/public artifacts contain no prohibited identity or personal information | ✗ BLOCKED | Opaque route input is not mechanically protected; scanner accepts forbidden public spelling and its live registered-artifact run is red. |

All four IDs declared in Plan frontmatter occur in `REQUIREMENTS.md`. No Phase 158 requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `route_inventory.ex` | 159–175 | Unbounded opaque reference inputs | 🛑 BLOCKER | Customer/proprietary values can enter a durable validated inventory. |
| `first_adopter_context.ex` | 175–182 | Forbidden hyphenated wording treated as compliant | 🛑 BLOCKER | Public scanner cannot enforce the required wording/privacy boundary. |
| `158-REVIEW.md` / scanner test | 74 / 57–60 | Registered artifact makes the gate fail | 🛑 BLOCKER | The actual merge-gate command and full focused suite are not green. |
| `capability_map/renderer.ex` | 184–190 | Formatter drift | ⚠️ WARNING | Phase validation evidence is not fully reproducible. |
| Phase source/test set | — | No untracked TODO/FIXME/XXX stub marker found | ℹ️ INFO | The only TODO-002 references are intentional open-adopter-input tracking. |

### Gaps Summary

The prior gap-closure work genuinely fixed trusted-PR protected scanning, public-guide wording, and the original ledger command shapes. It did not establish the broader privacy-safe context-routing outcome: the route-inventory boundary is bypassable, the generic scanner does not reject the prohibited public spelling, and the live scan/test gate fails on a registered review artifact. These are Phase 158 requirements, not later-phase work, so nothing is deferred.

**Exact next action:** return Phase 158 to gap closure. First tighten `RouteInventory` route-reference validation and the public phrase scanner, then resolve the scanner false positive without suppressing real sensitive-field detection; format the capability renderer; finally rerun the real filesystem scan, the full Phase-158 focused suite, and the supplied compile/full-suite gate before replacing this report.

---

_Verified: 2026-07-31T16:00:59Z_
_Verifier: the agent (gsd-verifier)_
