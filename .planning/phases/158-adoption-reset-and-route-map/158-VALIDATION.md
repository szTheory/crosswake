---
phase: 158
slug: adoption-reset-and-route-map
status: complete
nyquist_compliant: true
wave_14_complete: true
created: 2026-07-31
updated: 2026-07-31
---

# Phase 158 — Validation Strategy

Phase 158 reconciliation is based only on final Plan-17-tree evidence collected during Plan 158-18. TODO-002 remains open, and adopter-instance completeness remains `unknown_blocking`.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | ExUnit with Mix 1.19.5 |
| Focused gate | route inventory, context, Mix-task, capability-map, and support-matrix suites |
| Full gate | `mix test --exclude requires_example_host --exclude advisory_only` |
| Boundary | Browser-free, service-free, and no adopter-instance input required |

## Fresh Final-Tree Evidence

Every pre-write command below exited zero from the final Plan-17 tree. The protected input was assembled only in the process from neutral fragments; this ledger records commands, stable rule/path cases, counts, and outcomes only.

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Plan-17 ordering check | `test -f .planning/phases/158-adoption-reset-and-route-map/158-17-SUMMARY.md && rg -q 'mix crosswake\\.adoption_context\\.scan|check-formatted' .planning/phases/158-adoption-reset-and-route-map/158-17-SUMMARY.md` | Passed; ordering summary exists and records focused direct, Mix-task, live-scan, and formatter gates. It is not behavioral proof. |
| Protected direct scanner seam | `CROSSWAKE_PRIVATE_ADOPTER_TERMS="$(printf '%s-%s-%s' repository privacy sentinel)" mix test test/crosswake/planning/first_adopter_context_test.exs` | Passed: 15 tests, 0 failures. |
| Focused route/context/Mix/support gate | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | Passed: 124 tests, 0 failures. |
| Production caller | `mix crosswake.adoption_context.scan` | Passed. |
| Plan-17 formatter gate | `mix format --check-formatted lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | Passed. |
| Warnings-as-errors compile | `mix compile --warnings-as-errors` | Passed. |
| Hermetic full suite | `mix test --exclude requires_example_host --exclude advisory_only` | Passed. Existing unrelated warnings remained non-fatal and outside this plan's changes. |
| Whitespace | `git diff --check` | Passed. |

## Repository-Classification Evidence

`scan_filesystem/2` enumerates cached and non-ignored candidates, sends each through `classify_repository_path/1` before a file read, and then applies private-term checks to recognized textual candidates. Explicit raw-evidence and binary exclusions remain narrow. Enumeration, unreadable, symlink, and unknown candidates return stable rule/path routing violations instead of a clean result.

| Case | Direct scanner evidence | Production Mix-task evidence | Result |
| --- | --- | --- | --- |
| Action candidate | Focused temporary-repository regression covers `.github/actions/`. | Focused task regression invokes `Mix.Tasks.Crosswake.AdoptionContext.Scan.run/1` for the same class. | Classified text is read and rejected by the private-term rule. |
| Script candidate | Focused temporary-repository regression covers `script/`. | Focused task regression invokes the production task for the same class. | Classified text is read and rejected by the private-term rule. |
| Arbitrary future planning candidate | Focused temporary-repository regression covers a future phase path outside the historic finite range. | Focused task regression invokes the production task for the same class. | Classified text is read and rejected by the private-term rule. |
| Recognized text default | Direct regression proves recognized tracked text is scanned by default. | Production task regression proves the caller preserves that classification. | No subtree-specific text bypass exists. |
| Raw/binary evidence | Direct regression covers raw fixture exclusion and binary classification. | Production scanner remains limited to readable classified text. | Only explicit raw/binary evidence is excluded. |
| Unknown candidate | Direct regression uses an unsupported candidate shape. | Focused scanner suite preserves caller failure behavior. | Fails closed with a stable routing rule/path violation. |
| Diagnostics | Direct and Mix-task regressions inspect errors. | Production task surfaces scanner violations. | Rule IDs and relative paths only; no configured input or matched content is emitted. |

## Post-Write Privacy Evidence

After both reconciliation ledgers were written, the following final-artifact gate passed against the modified working tree:

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Final-artifact scan | `mix crosswake.adoption_context.scan` | Passed. |
| Final context and Mix-task suites | `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` | Passed. |
| Final whitespace check | `git diff --check` | Passed. |

## Validation Sign-Off

- [x] Fresh protected, focused, production, formatter, compile, hermetic, and whitespace gates passed.
- [x] Fresh direct and Mix-task evidence rejects action, script, and arbitrary future planning text.
- [x] Recognized text scans by default; explicit raw/binary exclusions remain narrow; unknown candidates fail closed.
- [x] Final Markdown ledgers pass the post-write production scan and focused scanner suites.
- [x] TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`.
- [x] RESET-01 through RESET-03, Android freeze, generic sync/storage, device proof, and later-phase support claims are unchanged.

**Approval:** RESET-04 reconciliation is complete on fresh final-tree and post-write evidence. Concrete first-adopter inputs remain blocked until TODO-002 is resolved.
