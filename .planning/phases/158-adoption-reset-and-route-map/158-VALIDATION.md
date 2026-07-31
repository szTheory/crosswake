---
phase: 158
slug: adoption-reset-and-route-map
status: complete
nyquist_compliant: true
wave_16_complete: true
created: 2026-07-31
updated: 2026-07-31
---

# Phase 158 — Validation Strategy

Phase 158 final reconciliation uses fresh executable evidence from the final Plan-19 tree. The
Plan-19 summary is ordering evidence only; it does not substitute for a fresh behavioral run.
TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | ExUnit with Mix 1.19.5 |
| Focused gates | scanner/context, production Mix-task, route inventory, capability map, and support matrix |
| Complete gate | `mix test --exclude requires_example_host --exclude advisory_only` |
| Boundary | Browser-free, service-free, and no adopter-instance input required |

## Fresh Final-Tree Evidence

All pre-write commands exited zero from the final Plan-19 tree. No private-term configuration was
supplied. This ledger retains only commands, stable references, counts, and outcomes.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Plan-19 ordering check | `test -f .planning/phases/158-adoption-reset-and-route-map/158-19-SUMMARY.md && rg -q 'first_adopter_context_test\|crosswake_adoption_context_scan_test' .planning/phases/158-adoption-reset-and-route-map/158-19-SUMMARY.md && rg -q 'route_inventory_test' .planning/phases/158-adoption-reset-and-route-map/158-19-SUMMARY.md` | Passed; the summary records both focused scanner/Mix-task and route-inventory verification. It is not behavioral proof. |
| Direct scanner and production-task suites | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | Passed: 25 tests, 0 failures. |
| Route-map validator suite | `mix test test/crosswake/adoption/route_inventory_test.exs` | Passed: 16 tests, 0 failures. |
| Capability and support suites | `mix test test/crosswake/capability_map test/crosswake/support_matrix` | Passed: 86 tests, 0 failures. |
| Production scanner | `mix crosswake.adoption_context.scan` | Passed. |
| Formatter | `mix format --check-formatted lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs lib/crosswake/adoption/route_inventory.ex test/crosswake/adoption/route_inventory_test.exs` | Passed. |
| Warnings-as-errors compilation | `mix compile --warnings-as-errors` | Passed. |
| Hermetic complete suite | `mix test --exclude requires_example_host --exclude advisory_only` | Passed. Existing unrelated warnings remained outside this plan’s files. |
| Whitespace | `git diff --check` | Passed. |

## Generic Privacy Evidence

`scan_filesystem/2` enumerates Git repository candidates, classifies each candidate before a file
read, applies generic privacy evaluation to every recognized textual candidate, and returns stable
rule/path diagnostics. Destination-specific public wording checks remain scoped. Explicit raw and
binary exclusions remain narrow.

| Path class | Direct scanner evidence | Production Mix-task evidence | Stable outcome |
| --- | --- | --- | --- |
| Unregistered guide | `first_adopter_context_test` regression | `crosswake_adoption_context_scan_test` regression | Generic privacy violation rejected. |
| Unregistered source | `first_adopter_context_test` regression | `crosswake_adoption_context_scan_test` regression | Generic privacy violation rejected. |
| Action | `first_adopter_context_test` regression | `crosswake_adoption_context_scan_test` regression | Generic privacy violation rejected. |
| Script | `first_adopter_context_test` regression | `crosswake_adoption_context_scan_test` regression | Generic privacy violation rejected. |
| Later-phase planning path | `first_adopter_context_test` regression | `crosswake_adoption_context_scan_test` regression | Generic privacy violation rejected. |
| Generic scan default | Focused direct suite | Focused production-task suite | Every `scan?: true` recognized textual candidate receives generic evaluation. |
| Raw/binary exclusions | Focused direct suite | Production caller delegates to the same scanner | Exclusions stay explicit and classified rather than creating a textual bypass. |
| Diagnostics | Direct and production-task suites | Direct and production-task suites | Outcomes use stable rule/path references; configured terms and matched content are not rendered. |

## Route-Map Boundary Evidence

The focused route suite exercises non-atom and mixed-key map boundaries before any `Keyword`
processing. The validator returns `%ValidationError{}` with the fixed `RI-INVALID` rule,
`unresolved` reference, and `route_row` field; it does not raise `ArgumentError` and does not echo
the supplied key or value.

| Case family | Evidence | Stable outcome |
| --- | --- | --- |
| Non-atom arbitrary map key | `route_inventory_test` focused regression | `%ValidationError{}` with `RI-INVALID` / `unresolved` / `route_row`. |
| Mixed map key and nested value | `route_inventory_test` focused regression | Same fixed error contract; no input echo. |
| Keyword-safe valid row | `route_inventory_test` focused regression | Valid route-local ownership/posture contract remains accepted. |

## Post-Write Evidence

After both ledgers were written, the final artifact gates were rerun against the modified tree.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Production scanner | `mix crosswake.adoption_context.scan` | Passed. |
| Scanner, Mix-task, and route suites | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/adoption/route_inventory_test.exs` | Passed: 41 tests, 0 failures. |
| Whitespace | `git diff --check` | Passed. |

## Validation Sign-Off

- [x] Fresh focused, production, formatting, compilation, complete-suite, and whitespace gates passed.
- [x] Direct and production Mix-task evidence covers guide, source, action, script, and later-phase textual path classes.
- [x] Generic checks are scan-by-default; destination-specific checks and raw/binary exclusions remain scoped.
- [x] Non-atom and mixed-key map input returns the stable, non-echoing validator error before `Keyword` APIs.
- [x] Post-write scanner, focused suites, and whitespace gates passed.
- [x] TODO-002 remains open; adopter-instance completeness remains `unknown_blocking`; RESET-01, RESET-03, Android freeze, and later-phase/non-goal claims are unchanged.
