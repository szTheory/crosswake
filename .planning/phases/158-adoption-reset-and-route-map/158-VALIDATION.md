---
phase: 158
slug: adoption-reset-and-route-map
status: complete
nyquist_compliant: true
wave_12_complete: true
created: 2026-07-31
updated: 2026-07-31
---

# Phase 158 — Validation Strategy

Phase 158 policy-contract validation is complete only for evidence observed during Plan 158-16 on the final Plan-15 tree. Adopter-instance completeness remains `unknown_blocking`; TODO-002 remains open.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | ExUnit with Mix 1.19.5 |
| Focused gate | route inventory, context, Mix-task, capability-map, and support-matrix suites |
| Full gate | `mix test --exclude requires_example_host --exclude advisory_only` |
| Boundary | Browser-free, service-free, and no adopter-instance input required |

## Fresh Plan 158-16 Evidence

Every command below exited zero in this execution before this ledger changed status. The protected test value was assembled in the process from neutral fragments; no completed value, matched content, Git output, or surrounding file content is persisted here.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Plan-15 ordering | `test -f .planning/phases/158-adoption-reset-and-route-map/158-15-SUMMARY.md && rg -q 'mix crosswake\\.adoption_context\\.scan|check-formatted' .planning/phases/158-adoption-reset-and-route-map/158-15-SUMMARY.md` | Passed; summary exists and records focused module, Mix-task, live-scan, and formatter gates green. |
| Protected caller seam | `CROSSWAKE_PRIVATE_ADOPTER_TERMS="$(printf '%s-%s-%s' repository privacy sentinel)" mix test test/crosswake/planning/first_adopter_context_test.exs` | Passed: 14 tests, 0 failures. |
| Focused implementation gate | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | Passed: 122 tests, 0 failures. |
| Live repository scan | `mix crosswake.adoption_context.scan` | Passed. |
| Complete changed-Elixir formatter gate | `mix format --check-formatted lib/crosswake/adoption/route_inventory.ex test/crosswake/adoption/route_inventory_test.exs lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs lib/crosswake/capability_map.ex lib/crosswake/capability_map/renderer.ex` | Passed. The seven paths cover every Elixir source/test changed by Plans 158-11 through 158-15. |
| Warnings-as-errors compile | `mix compile --warnings-as-errors` | Passed. |
| Hermetic full suite | `mix test --exclude requires_example_host --exclude advisory_only` | Passed. Existing unrelated warnings remained non-fatal and outside this plan's changes. |
| Whitespace | `git diff --check` | Passed. |

## Repository-Classification Evidence

`scan_filesystem/2` now receives cached and non-ignored candidates from `git -C ROOT ls-files --cached --others --exclude-standard -z`. Each candidate is classified before a file read: named public/fast-changing paths retain their destinations; active planning artifacts, guides, workflows, source, and tests enter the durable scan; explicit historical/raw/binary/dependency exclusions remain non-scanned; unsafe, unreadable, unclassified, and enumeration failures return stable routing rule/path data. `@artifact_globs` remains compatibility metadata and is not discovery authority.

| Case | Fresh discriminating evidence | Result |
| --- | --- | --- |
| Unregistered guide | Context regression creates `guides/unregistered-adoption-note.md` in a temporary Git repository. | Classified and returns `privacy.private_term` with the relative path only. |
| Later-phase artifact | Context and production Mix-task regressions create a Phase 159 planning Markdown artifact. | Classified and returns `privacy.private_term` with the relative path only. |
| Workflow | Context regression creates an unregistered `.github/workflows/` candidate. | Classified and scanned through the same filesystem entry point. |
| Source | Context regression creates an unregistered `lib/` candidate. | Classified and scanned through the same filesystem entry point. |
| Test | Context regression creates an unregistered `test/` candidate. | Classified and scanned through the same filesystem entry point. |
| Enumeration failure | Context regression uses a missing repository root. | Fails closed as `routing.repository_enumeration_failed` at `repository`. |
| Unknown text | Context regression adds an unsupported text-path shape. | Fails closed as `routing.unclassified_path`, never as a clean scan. |
| Non-echoing diagnostics | Context and Mix-task regressions assemble test inputs only at runtime and inspect error output. | Errors contain stable rule IDs and relative paths; no configured input, matched content, or Git output is exposed. |

## Post-Ledger Privacy Evidence

After both final ledgers were written, the production scanner, focused scanner suites, and whitespace gate were rerun against the final Markdown artifacts. The results below are observed in this execution and are the only basis for final sign-off.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Final-artifact scan | `mix crosswake.adoption_context.scan` | Passed. |
| Final context and Mix-task suites | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | Passed. |
| Final whitespace check | `git diff --check` | Passed. |

## No-Silent-Drop Accounting

| Closure area | Positive evidence | Negative/fail-closed evidence |
| --- | --- | --- |
| Repository candidate discovery | Git-backed cached/non-ignored enumeration reaches path classification. | Enumeration failure returns a stable routing violation. |
| Unregistered repository-facing text | Guide, Phase 159 artifact, workflow, source, and test cases use the production filesystem path. | Unknown text paths produce `routing.unclassified_path`; no default clean fallback exists. |
| Private-term diagnostics | Protected caller seam and production Mix-task regressions pass non-echoing assertions. | Failures contain only stable rule/path data, not input or matched contents. |
| Final evidence artifacts | Final ledgers are repository candidates and pass the post-write production scan. | The post-write gate would block a disclosure or classification failure before sign-off. |

## Validation Sign-Off

- [x] Fresh protected, focused, live-scan, complete-format, warnings-as-errors, hermetic, and whitespace gates passed.
- [x] Fresh unregistered-guide, Phase 159, workflow, source, test, and enumeration-failure evidence proves repository classification is fail closed.
- [x] Post-write scanner and focused scanner-test evidence covers the final Markdown ledgers.
- [x] TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.
- [x] No RESET-01 through RESET-03 work, Android, generic sync/storage, UI, proof-lane, replay, pack, device, identity, or later-phase claim is promoted.

**Approval:** Phase 158 policy-contract validation is complete on fresh repository-classification evidence. Concrete adopter-route inputs remain blocked until TODO-002 is resolved.
