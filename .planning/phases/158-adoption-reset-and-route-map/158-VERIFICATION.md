---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T19:14:35Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter routes, update support truth, and install privacy-safe context routing.

**Verified:** 2026-07-31T19:14:35Z
**Status:** passed
**Re-verification:** No — the prior report used unsupported `complete` status and had no structured `gaps:` section, so this is an independent current-tree verification.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new session can discover the GET-6 infrastructure framing, Alpha/v1 split, reversal conditions, stop list, and current phase without re-deriving them. | ✓ VERIFIED | The ADR, adoption brief, `AGENTS.md`, roadmap, and state retain the governing decision; `first_adopter_context_test.exs` exercises these documents and passed in the focused run. |
| 2 | Known first-adopter surfaces have explicit runtime ownership, offline posture, authority/fallback, and remote-disable story; concrete unknown facts cannot be promoted. | ✓ VERIFIED | The route-policy map supplies the surface table and closed route-local contract. `RouteInventory` rejects inferred/default safety posture and returns explicit `unknown_blocking`/empty-inventory promotion blocks; route tests passed. |
| 3 | Support truth is canonical, public, deterministic, and honest about frozen/deferred scope. | ✓ VERIFIED | `CapabilityMap` canonical rows use `adoption_implication`; its renderer and generated guide use public `first adopter` wording. Support-matrix tests prove policy completion stays separate from host/device proof, Android remains frozen, and v20 carries no shipped claim. |
| 4 | v20 is preserved as stopped/partial without a shipped claim or tag, and Phases 156–157 are outside active scope. | ✓ VERIFIED | `ROADMAP.md`, `STATE.md`, and the v20 archive state stopped/partial/no completion tag. The context test checks the same archive and refutes 156/157 in active v21 content. |
| 5 | Privacy-safe context routing scans all recognized textual repository candidates and returns stable rule/path diagnostics without private content. | ✓ VERIFIED | Git-backed enumeration feeds classification, generic checks, and `scan_filesystem/2`; the production Mix task calls that scanner. Direct and Mix-task tests cover unregistered guide/source/action/script/future-phase paths, non-echoing output, fail-closed unclassified/enumeration cases, and all passed. |
| 6 | The review fixes close the detected bypasses without relaxing the protected trust boundary. | ✓ VERIFIED | `.svg` is textual/scannable; context-aware one-digit, multi-digit, and decimal commercial values are tested; duplicate keyword fields fail as `RI-DUPLICATE_FIELD` before NimbleOptions. The workflow deliberately blocks fork bypasses while protected scanning only runs with trusted provenance; its contract test passed. |

**Score:** 6/6 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/adoption/route_inventory.ex` | Closed, sanitized route-row validation and promotion boundary | ✓ VERIFIED | 444 substantive lines; public validation/promotion APIs are called by the 17 route-inventory tests. Map-key normalization, duplicate-field rejection, collision checks, and blocked promotion are implemented before unsafe Keyword/NimbleOptions behavior. |
| `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` | Route ownership/defaults and honest concrete-row contract | ✓ VERIFIED | Explicit surface owner/fallback table, route-local safety fields, status vocabulary, and `unknown_blocking` external-input boundary. |
| `lib/crosswake/planning/first_adopter_context.ex` | Repository context classification and safe privacy scan | ✓ VERIFIED | 300+ substantive lines of Git candidate enumeration, path classification, generic/destination checks, stable diagnostics, and raw/binary exclusions. Invoked by the production Mix task and direct tests. |
| `lib/mix/tasks/crosswake.adoption_context.scan.ex` | Production enforcement entry point | ✓ VERIFIED | Reads only configured terms, fail-closes `--require-private-terms` without them, calls `scan_filesystem/2`, and formats only rule/path output. |
| `lib/crosswake/capability_map.ex`, `lib/crosswake/capability_map/renderer.ex`, `guides/capability_map.md` | Canonical and rendered public capability truth | ✓ VERIFIED | Canonical field, single conflict-safe legacy normalizer, renderer, byte-identical guide, and tests are wired. |
| `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/support_matrix/renderer.ex`, `guides/support_matrix.md` | Honest support posture | ✓ VERIFIED | Rendered support guide distinguishes policy contracts from future host/device proof and freezes Android posture. |
| `.github/workflows/hex-page-proof.yml` | CI privacy gate and protected-secret boundary | ✓ VERIFIED | Generic scan always runs; trusted same-repository PRs/main/manual dispatch run the secret-required scan; untrusted forks fail closed instead of bypassing it. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Route-policy map | `RouteInventory` | Shared statuses and promotion contract | WIRED | Plan artifact/key-link verifier found all declared Plan-01 links; focused route tests exercise the public APIs. |
| Git candidate enumeration | Context privacy checks | `repository_candidates` → classification → `filesystem_content_violations` | WIRED | Recognized text has `scan?: true`; generic checks run before destination-specific checks. Direct tests cover five unregistered path classes. |
| Context scanner | Production Mix task | `Scan.run/1` → `scan_filesystem/2` | WIRED | Production task tests and `mix crosswake.adoption_context.scan` passed. |
| Capability canonical rows | Renderer and guide | `adoption_implication` normalizer → `Renderer.render/write` | WIRED | Renderer tests cover canonical/legacy equal/conflicting forms and generated guide parity. |
| Protected workflow | Secret-required scanner | trusted-provenance condition + `--require-private-terms` | WIRED | Workflow contract test proves the trusted branch and explicit fork-block boundary. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable/source | Produces real data | Status |
| --- | --- | --- | --- |
| Route inventory | Caller rows → normalization → closed struct → promotion status | Synthetic sanitized rows and malformed boundary inputs; no hardcoded eligible inventory | ✓ FLOWING |
| Context scanner | Git cached/non-ignored candidates → classified regular files → content checks | Live repository scan completed successfully; temporary Git repositories prove reject paths | ✓ FLOWING |
| Capability/support guides | Canonical maps → renderer output | Generated guide parity is exercised by renderer tests | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Route validation, promotion, duplicate-field, and map-key failure contracts | `mix test test/crosswake/adoption/route_inventory_test.exs` (within focused run) | Passing | ✓ PASS |
| Direct and production privacy enforcement, including SVG and contextual one-digit currency | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` (within focused run) | Passing | ✓ PASS |
| Capability/support truth and generated rendering | `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs test/crosswake/support_matrix/renderer_test.exs` (within focused run) | Passing | ✓ PASS |
| Current-tree production privacy scan | `mix crosswake.adoption_context.scan` | `adoption context scan passed` | ✓ PASS |
| Changed Elixir source quality | `mix format --check-formatted … && mix compile --warnings-as-errors && git diff --check` | Exit 0 | ✓ PASS |

**Focused combined run:** 80 tests, 0 failures (6.0s).

### Probe Execution

Step 7c: SKIPPED — no Phase-158 `scripts/*/tests/probe-*.sh` or phase-declared probe was present. The production Mix task above is the runnable enforcement seam and was executed directly.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RESET-01 | 01, 02, 03 and reconciliation plans | Durable infrastructure decision, reversal condition, scope audit, non-goals, and stop list are discoverable. | ✓ SATISFIED | ADR/brief/agent guide/context tests and canonical capability truth preserve the framing. |
| RESET-02 | 01, 04, 05, 11, 19, 20 | Known surfaces have explicit owner/posture/authority/fallback/disablement; unknown concrete inputs do not promote. | ✓ SATISFIED | Route map, closed validator, promotion invariants, and focused route tests. TODO-002 remains the documented external-input gate. |
| RESET-03 | 03, 04 and reconciliation plans | v20 is stopped/partial and Phases 156–157 are absent from active scope. | ✓ SATISFIED | Archived roadmap/state text plus automated context assertion. |
| RESET-04 | 01, 03, 06, 12, 15, 17, 19, 20 | Planning/public adoption artifacts reject prohibited identity and personal/commercial data. | ✓ SATISFIED | Repository-wide candidate scan, generic privacy rules, non-echoing output, current production scan, and regression coverage for SVG/one-digit prices. |

No orphaned Phase-158 requirements were found: all four IDs mapped to the phase are declared by its plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/capability_map.ex` | 61 | Comment contains “placeholder” | ℹ️ Info | It explicitly prohibits placeholders; no user-visible stub or incomplete implementation. |
| `lib/crosswake/support_matrix/renderer.ex` | 463 | Comment contains “placeholder” | ℹ️ Info | Existing renderer fallback description; no Phase-158 debt marker or hollow data flow. |

No `TBD`, `FIXME`, or `XXX` debt marker was found in the verified Phase-158 implementation files.

## Scope and External-Input Boundary

`TODO-002` remains `status: open`, and the route-policy map continues to state that adopter-instance completeness is `unknown_blocking`. This is an intentional, executable fail-closed boundary awaiting sanitized adopter input—not a missing Phase-158 implementation. No Android, generic sync/storage, device-proof, UI/API/schema, or later-phase support claim was promoted.

The user-owned `.planning/config.json` modification was present before verification and was not changed.

## Gaps Summary

None. All roadmap success criteria and the requested post-review regressions have current-tree automated evidence. Phase goal achieved.

---

_Verified: 2026-07-31T19:14:35Z_
_Verifier: the agent (gsd-verifier)_
