---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T15:16:07Z
status: gaps_found
score: 8/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 18/22
  gaps_closed:
    - "Concrete route safety posture rejects known_default and local-mutation/recent-auth incoherence before promotion."
    - "Phase 158 planning artifacts are now dynamically discovered and scanned; PLAN files no longer have a private-term exemption."
  gaps_remaining:
    - "Protected private-term enforcement is not a pull-request merge gate."
  regressions:
    - "The documented synthetic protected-term test now fails against Phase 158's own scanned artifacts."
    - "The ledger claims mix format --check-formatted exits zero, but that exact command exits non-zero."
gaps:
  - truth: "Automated scans reject the prohibited real adopter name from planning, agent, and public-guide surfaces before a pull request can merge."
    status: failed
    reason: "The pull_request workflow runs only the generic scan. The secret-backed --require-private-terms scan is skipped for every pull request and runs only after a push to main or manual dispatch."
    artifacts:
      - path: ".github/workflows/hex-page-proof.yml"
        issue: "The protected scan is guarded by if: github.event_name != 'pull_request', so same-repository PRs can merge without the real-term check."
    missing:
      - "Run the protected scan for trusted same-repository PRs, and make fork handling fail closed or require a trusted maintainer/merge-queue check before merge."
  - truth: "The capability guide uses only the public phrase first adopter."
    status: failed
    reason: "The generated public guide still contains four instances of the forbidden hyphenated variant first-adopter."
    artifacts:
      - path: "guides/capability_map.md"
        issue: "Lines 13, 21, 59, and 69 use first-adopter."
    missing:
      - "Update the canonical capability implication strings, regenerate the guide, and add a regression that rejects the hyphenated public wording."
  - truth: "The post-gap validation ledger records only gates that actually pass."
    status: failed
    reason: "Two commands claimed as green in 158-VALIDATION.md fail in the current codebase: the exact no-argument formatter command and the documented synthetic protected-term test."
    artifacts:
      - path: ".planning/phases/158-adoption-reset-and-route-map/158-VALIDATION.md"
        issue: "It asserts formatting passed and that the protected canary command passed, despite contrary current results."
      - path: "test/crosswake/planning/first_adopter_context_test.exs"
        issue: "With the documented protected-test value, its caller-seam assertion fails because scanned Phase 158 artifacts contain that literal."
    missing:
      - "Use a runnable formatter invocation with explicit inputs or configure .formatter.exs; remove/rework the literal synthetic term from scanned durable artifacts; then rerun and record the actual gate chain."
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing, while keeping adopter-instance completeness fail-closed.

**Verified:** 2026-07-31T15:16:07Z  
**Status:** gaps_found  
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover the infrastructure framing, Alpha/v1 split, stop list, and current phase. | ✓ VERIFIED | `AGENTS.md`, ADR, brief, route map, roadmap, and state contain the framing; `FirstAdopterContextTest` exercises those files. |
| 2 | Every known surface has explicit owner, offline, authority/fallback, and disablement posture; missing concrete inputs remain fail-closed. | ✓ VERIFIED | Route map and generated support guide distinguish defaults from concrete inventory; `RouteInventory` rejects `known_default`, blocks `unknown_blocking`, and its negative/positive promotion tests passed. |
| 3 | v20 is retained as stopped/partial, without shipping Phases 156–157. | ✓ VERIFIED | v20 roadmap and milestones explicitly say stopped/partial, no completion tag, and 156–157 incomplete; focused context test passed. |
| 4 | Automated scans reject prohibited private terms before merge on planning, agent, and public-guide surfaces. | ✗ FAILED | The protected private-term workflow step is skipped on every `pull_request`; only generic checks run before merge. |
| 5 | Sanitized route rows are closed, collision-safe, ordered, privacy-safe, and block empty/unknown inventory promotion. | ✓ VERIFIED | `RouteInventory` and 12 focused tests cover validation, non-echoing errors, collisions, order, empty inventory, and `unknown_blocking`. |
| 6 | Concrete route promotion cannot inherit defaults or admit incoherent local-mutation/recent-auth state. | ✓ VERIFIED | `validate_posture/3` rejects `:known_default`; invariant checks require offline-island/actionable mutation and reject contradictory auth state. Executed route tests pass. |
| 7 | Capability truth has one canonical implication field with bounded legacy compatibility and deterministic generated output. | ✓ VERIFIED | `CapabilityMap.Row` enforces `adoption_implication`; renderer's `normalize_implication/1` handles legacy/equal/conflicting inputs; focused renderer tests passed. |
| 8 | The public capability guide uses only `first adopter`. | ✗ FAILED | `guides/capability_map.md` still renders `first-adopter` at lines 13, 21, 59, and 69. |
| 9 | The filesystem scanner discovers current/future approved Phase 158 planning artifacts and emits only rule/path evidence. | ✓ VERIFIED | Destination globs include `158-*.md`; temporary PLAN/SUMMARY/VALIDATION canaries are tested, and `mix crosswake.adoption_context.scan` passed. |
| 10 | The generic scanner is wired into the merge-blocking workflow and protected runs fail closed without secret input. | ✓ VERIFIED | Workflow invokes the Mix task on PRs and protected events; direct `--require-private-terms` without the variable exits with `privacy.private_terms_required secret.input`. |
| 11 | The validation ledger is reconciled only from passing post-gap gates. | ✗ FAILED | `mix format --check-formatted` exits non-zero without formatter inputs; the documented synthetic protected-term command fails on scanned Phase 158 files, contrary to the ledger. |

**Score:** 8/11 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed route contract and promotion evaluation | ✓ VERIFIED | Substantive validator with closed fields/statuses, invariants, collision checking, and public API tests. |
| `test/crosswake/adoption/route_inventory_test.exs` | Route fail-closed regressions | ✓ VERIFIED | 12 behavioral tests executed successfully as part of the 111-test focused command. |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Layered contract and unresolved-input boundary | ✓ VERIFIED | Documents route-local fields, no concrete adopter row, `unknown_blocking`, and TODO-002's open state. |
| `lib/crosswake/capability_map.ex` + `renderer.ex` | Canonical implication migration and deterministic renderer | ✓ VERIFIED | Canonical field and one normalizer are implemented and exercised. |
| `guides/capability_map.md` | Generated public capability guide | ⚠️ PARTIAL | Renderer parity is wired, but its public wording violates the plan truth. |
| `lib/crosswake/planning/first_adopter_context.ex` | Dynamic privacy-context discovery/scanning | ✓ VERIFIED | Globs, discovery, rule/path-only result shape, and non-echoing private-term logic are substantive and exercised. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` | Repository privacy gate | ✓ VERIFIED | Delegates to the scanner; normal run passed and missing protected input fails closed. |
| `.github/workflows/hex-page-proof.yml` | Merge-blocking privacy enforcement | ⚠️ PARTIAL | Generic gate is wired on PRs, but the protected term gate is not. |
| `lib/crosswake/support_matrix/renderer.ex` + `guides/support_matrix.md` | Honest policy-versus-proof support truth | ✓ VERIFIED | Focused support tests passed; guide retains `verification required` for host/device proof while inputs are unknown. |
| `158-VALIDATION.md` | Honest post-gap Nyquist evidence | ✗ STUBBED EVIDENCE | Ledger exists and is detailed, but its stated successful formatter and synthetic protected-term results are not reproducible. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Route policy map | `RouteInventory` | Shared closed status/field vocabulary | WIRED | Route test reads the map and asserts vocabulary/invariant terms. |
| `RouteInventory` | Route tests | Public validate-to-promotion path | WIRED | Negative status/invariant paths and eligible state executed. |
| Capability map | Capability guide | Renderer write/parity path | WIRED | Focused capability tests pass; wording content is still wrong. |
| Context scanner | Mix task | `scan_filesystem/2` delegation | WIRED | Task invokes scanner and tests assert exit/error behavior. |
| Workflow | Mix task | CI `run: mix crosswake.adoption_context.scan` | PARTIAL | The generic link is wired, but secret-backed enforcement is absent from PRs. |
| Support renderer | Support guide | Renderer parity test | WIRED | Included in passing focused suite. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `RouteInventory` | route postures | caller input → closed validation → promotion state | Synthetic, validated route values | ✓ FLOWING |
| Context scanner | discovered entries and protected terms | filesystem glob discovery; environment at task boundary | Approved artifact files; terms remain in memory | ✓ FLOWING |
| Support/capability renderers | canonical rows | canonical modules → renderer → checked-in guide | Canonical row data, byte-parity tests | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase route/context/capability/support behaviors | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 111 tests, 0 failures | ✓ PASS |
| Generic filesystem scan | `mix crosswake.adoption_context.scan` | `adoption context scan passed` | ✓ PASS |
| Missing protected input fails closed | `mix crosswake.adoption_context.scan --require-private-terms` | `privacy.private_terms_required secret.input` | ✓ PASS |
| Documented synthetic protected-term path | `CROSSWAKE_PRIVATE_ADOPTER_TERMS=<documented test value> mix test test/crosswake/planning/first_adopter_context_test.exs` | 9 tests, 1 failure; seven Phase 158 artifacts match | ✗ FAIL |
| Hermetic suite | `mix test --exclude requires_example_host --exclude advisory_only` | Exit 0; pre-existing compiler warnings emitted | ✓ PASS |
| Claimed formatter gate | `mix format --check-formatted` | Exit non-zero: no inputs configured | ✗ FAIL |
| Whitespace | `git diff --check` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 02, 03, 04 | Durable infrastructure decision, scope audit, non-goals, stop list | ✓ SATISFIED | Governing documents, capability/support truth, and focused context/capability/support tests. |
| RESET-02 | 01, 04, 05, 07 | Explicit owner/offline/authority/fallback/disablement posture | ✓ SATISFIED | Route validator's known-default and cross-field promotion tests pass; unknown input remains blocked. |
| RESET-03 | 03, 04 | Honest stopped/partial v20 and inactive 156–157 scope | ✓ SATISFIED | v20 archive wording and focused regression test. |
| RESET-04 | 01, 02, 03, 04, 06, 07 | No prohibited adopter identity or personal information in planning/public artifacts | ✗ BLOCKED | Scanner implementation exists but protected-term check is absent on PRs; public guide wording truth and claimed validation evidence also fail. |

All four IDs declared by Plan frontmatter (`RESET-01` through `RESET-04`) are present in `REQUIREMENTS.md`. No Phase 158 requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.github/workflows/hex-page-proof.yml` | 55–58 | Protected privacy scan skipped on every PR | 🛑 BLOCKER | A same-repository PR can merge private-term content before the check runs on `main`. |
| `guides/capability_map.md` | 13, 21, 59, 69 | `first-adopter` public wording | 🛑 BLOCKER | Violates the explicit public-phrase must-have. |
| `158-VALIDATION.md` | Observed post-gap gate table | Claims non-reproducible green gates | 🛑 BLOCKER | Completion evidence is not auditable. |

### Gaps Summary

The original route-promotion gaps are closed: the validator now rejects inherited safety status and incoherent local-mutation/recent-auth posture through tested public APIs. The dynamic scanner also covers current and future approved Phase 158 artifacts without emitting matched content.

However, the phase goal is not achieved. RESET-04 remains fail-open at the merge boundary because PRs do not receive secret-backed protected-term enforcement. The generated capability guide violates its public-phrase contract, and the validation ledger claims two gates that do not reproduce. These are Phase 158 concerns, not items explicitly deferred to later roadmap phases.

---

_Verified: 2026-07-31T15:16:07Z_  
_Verifier: the agent (gsd-verifier)_
