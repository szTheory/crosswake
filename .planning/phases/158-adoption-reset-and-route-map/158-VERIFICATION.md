---
phase: 158-adoption-reset-and-route-map
verified: 2026-07-31T18:51:00Z
status: complete
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Generic privacy rules now evaluate every recognized textual repository candidate."
    - "RouteInventory.validate/1 now rejects arbitrary non-atom map keys before Keyword processing."
  gaps_remaining: []
  regressions: []
---

# Phase 158: Adoption Reset and Route Map Verification Report

**Phase Goal:** Close GET-6, archive v20 honestly, freeze the surface-area audit, classify adopter
routes, update support truth, and install privacy-safe context routing.

**Status:** complete — fresh final-tree and post-write evidence closes exactly the two prior
blockers. TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.

## Re-verified Blockers

| Prior gap | Fresh evidence | Verdict |
| --- | --- | --- |
| Generic privacy rules were not applied to every scanned textual artifact. | The focused direct and production Mix-task suites passed (25 tests, 0 failures), covering unregistered guide, source, action, script, and later-phase paths; the live production scan passed before and after ledger writes. | CLOSED |
| `RouteInventory.validate/1` crashed on non-atom map keys. | The focused route suite passed (16 tests, 0 failures), including non-atom and mixed-key map cases returning the fixed `RI-INVALID` / `unresolved` / `route_row` `%ValidationError{}` without input echo. | CLOSED |

## Goal Achievement

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Infrastructure framing, Alpha/v1 split, stop list, and active phase remain discoverable. | VERIFIED | Governing planning artifacts remain unchanged; focused context checks pass. |
| 2 | Known adopter surfaces retain explicit runtime owner, posture, authority, fallback, and blocked unknown route facts. | VERIFIED | Route policy and route-inventory suite pass; concrete adopter input remains blocked. |
| 3 | v20 remains stopped/partial and Phases 156–157 are not represented as shipped. | VERIFIED | Existing milestone, roadmap, and support truth remain unchanged. |
| 4 | Generic privacy scanning protects recognized textual planning and public artifacts. | VERIFIED | Git enumeration → classification → generic evaluation → `scan_filesystem/2` → production Mix task is covered by fresh focused and live scans. |
| 5 | Invalid route-row map input returns a stable safe validator error. | VERIFIED | Caller map → atom-key normalization → pre-`Keyword` validation → `%ValidationError{}` is covered by fresh route tests. |

**Score:** 5/5 truths verified.

## Artifact and Key-Link Verification

| Link | Status | Evidence |
| --- | --- | --- |
| Repository candidate enumeration → classification → generic evaluation | WIRED | Every recognized textual `scan?: true` entry receives generic privacy evaluation; destination wording stays destination-scoped. |
| `scan_filesystem/2` → production `mix crosswake.adoption_context.scan` | WIRED | Direct and production suites cover the same five path classes; the live task passed pre- and post-write. |
| Caller map → pre-`Keyword` atom-key normalization → `%ValidationError{}` | WIRED | Non-atom and mixed-key inputs return `RI-INVALID` / `unresolved` / `route_row`, not an exception. |
| Route policy map → route inventory → promotion boundary | WIRED | Closed vocabulary and `unknown_blocking` promotion block remain covered by the route suite. |

## Fresh Gate Evidence

| Gate | Result |
| --- | --- |
| Focused scanner/Mix-task suites | 25 tests, 0 failures |
| Focused route-inventory suite | 16 tests, 0 failures |
| Capability/support suites | 86 tests, 0 failures |
| Production scanner, formatter, warnings-as-errors compile, hermetic suite, whitespace | Passed |
| Post-write production scanner | Passed |
| Post-write scanner/Mix-task/route suites | 41 tests, 0 failures |
| Post-write whitespace | Passed |

## Requirement Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| RESET-01 | SATISFIED | Durable infrastructure decision and non-goals remain unchanged. |
| RESET-02 | SATISFIED | Route-local ownership and malformed-map safety boundary are executable and fail closed. |
| RESET-03 | SATISFIED | v20 stopped/partial truth remains unchanged. |
| RESET-04 | SATISFIED | Generic privacy evaluation covers the demonstrated textual path classes through direct and production seams. |

## Scope and Privacy Integrity

- TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.
- No adopter-instance fact, malformed input, runtime canary, matched content, Git output, or sensitive
  payload is persisted in this report.
- Android remains frozen; later-phase, UI, API, schema, generic sync, and generic storage claims are
  unchanged.

_Verified from fresh final-tree and post-write automated evidence on 2026-07-31._
