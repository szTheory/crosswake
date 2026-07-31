---
phase: 158
slug: adoption-reset-and-route-map
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-31
updated: 2026-07-31
---

# Phase 158 — Validation Strategy

Phase 158 policy-contract validation is complete only for evidence observed during Plan 158-14.
Adopter-instance completeness remains `unknown_blocking`; TODO-002 remains open.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | ExUnit with Mix 1.19.5 |
| Focused gate | route inventory, context, Mix-task, capability-map, and support-matrix suites |
| Full gate | `mix test --exclude requires_example_host --exclude advisory_only` |
| Boundary | Browser-free, service-free, and no adopter-instance input required |

## Fresh Plan 158-14 Evidence

Every command below exited zero in this execution before this ledger was marked complete. The protected test value is assembled by the shell from neutral fragments; neither its completed value nor any matched content is persisted here.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Implementation-summary ordering | `test -f .planning/phases/158-adoption-reset-and-route-map/158-11-SUMMARY.md && test -f .planning/phases/158-adoption-reset-and-route-map/158-12-SUMMARY.md && test -f .planning/phases/158-adoption-reset-and-route-map/158-13-SUMMARY.md` | Three required summaries present; each reports its focused gate green. |
| Protected caller seam | `CROSSWAKE_PRIVATE_ADOPTER_TERMS="$(printf '%s-%s-%s' runtime privacy sentinel)" mix test test/crosswake/planning/first_adopter_context_test.exs` | 12 tests, 0 failures. |
| Focused implementation gate | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | 120 tests, 0 failures. |
| Live filesystem scan | `mix crosswake.adoption_context.scan` | passed. |
| Complete changed-Elixir formatter gate | `mix format --check-formatted lib/crosswake/adoption/route_inventory.ex test/crosswake/adoption/route_inventory_test.exs lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs lib/crosswake/capability_map.ex lib/crosswake/capability_map/renderer.ex` | passed. |
| Warnings-as-errors compile | `mix compile --warnings-as-errors` | passed. |
| Hermetic full suite | `mix test --exclude requires_example_host --exclude advisory_only` | passed. Existing unrelated suite warnings did not originate from this plan and did not prevent the command from exiting zero. |
| Whitespace | `git diff --check` | passed. |

The formatter list is complete for every Elixir source or test changed by Plans 158-11 through 158-13: `route_inventory.ex`, its test, `first_adopter_context.ex`, its test, the Mix-task test, `capability_map.ex`, and `capability_map/renderer.ex`.

## Post-Ledger Privacy Evidence

After both final ledgers were written, the registered filesystem scan and focused scanner paths were rerun against the final artifacts themselves:

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Final-artifact scan | `mix crosswake.adoption_context.scan` | passed. |
| Final focused context and Mix-task suites | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | passed. |
| Final whitespace check | `git diff --check` | passed. |

## Task and Threat Mapping

| Plan / task | Requirement | Threat reference | Current enforcement |
| --- | --- | --- | --- |
| 158-11 Task 1 | RESET-02, RESET-04 | T-158-G14-01, T-158-G14-04 | Opaque fixed-format route IDs and closed generic Phoenix templates reject identifying or malformed references without echoing input. |
| 158-12 Task 1 | RESET-04 | T-158-G14-02, T-158-G14-03 | Public prose rejects standalone prohibited spelling; synthetic protected input remains process-only. |
| 158-12 Task 2 | RESET-04 | T-158-G14-03, T-158-G14-05 | Identifying vocabulary requires a key-plus-assignment shape, preserving live scan coverage without trapping review prose. |
| 158-13 Task 1 | RESET-01, RESET-04 | T-158-G14-01 | Deterministic capability renderer is included in the complete explicit formatter ledger. |
| 158-14 Task 1 | RESET-01 through RESET-04 | T-158-G14-01 through T-158-G14-06 | Fresh focused, live scan, formatter, warnings-as-errors, hermetic, whitespace, and post-ledger gates control the status above. |

## No-Silent-Drop Accounting

| Closure area | Positive evidence | Negative/fail-closed evidence |
| --- | --- | --- |
| Opaque route references | Focused route suite passes with closed route-ID/template validation. | Customer-like IDs and non-generic paths reject without copying supplied content. |
| Exact public spelling | Focused context and Mix-task suites pass. | The standalone prohibited hyphenated wording has a stable violation path. |
| Identifying-field precision and live scan | Live scan passes against the registered phase artifacts. | Field vocabulary remains detected only when shaped as an assignment; safe review terminology is not treated as a secret. |
| Renderer formatting | Complete seven-path formatter gate passes. | Formatter drift in any Plan 11-13 Elixir path fails the explicit command. |

No source probe is silently dropped or promoted beyond its evidence. This closes the Phase 158 policy-contract gate, not adopter-instance integration.

## Validation Sign-Off

- [x] Fresh protected, focused, live-scan, complete-format, warnings-as-errors, hermetic, and whitespace gates passed.
- [x] Post-write scanner and focused scanner-test evidence covers the final registered Markdown ledgers.
- [x] Plans 158-11 through 158-14 are mapped to their current task and threat evidence.
- [x] TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.
- [x] No Android, generic sync/storage, UI, proof-lane, replay, pack, device, identity, or later-phase claim is promoted.

**Approval:** Phase 158 policy-contract validation is complete on fresh evidence. Concrete adopter-route inputs remain blocked until TODO-002 is resolved.
