---
phase: 196-spec-and-structure-ratchet
plan: "08"
subsystem: policy
tags: [elixir, policy, structured-diagnostics, finite-product]
requires:
  - phase: 196-07
    provides: Privacy boundary tests and collection ratchet baseline
provides:
  - Atom-keyed structured diagnostics with original source attribution
  - Independent 108-case semantic and staged compiler oracles
  - Five discriminating actual-source corruption controls with exact restoration
affects: [196-14, 196-15, SPEC-05]
tech-stack:
  added: []
  patterns: [paired normalized routes and original sources, literal factored oracle]
key-files:
  created:
    - test/crosswake/policy/finite_product_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/policy-product.json
  modified:
    - lib/crosswake/policy/compiler.ex
    - test/crosswake/policy/compiler_test.exs
    - test/crosswake/policy/route_test.exs
key-decisions:
  - Keep structured NimbleOptions keys through normalization; split actual grouped unknown keys into atom diagnostics.
  - Keep successful normalized routes paired with original sources through duplicates and Validator aggregation.
  - Preserve existing policy intent and distinguish early entry rejection from aggregate semantic validation.
requirements-completed: []
coverage:
  - id: structured-diagnostics
    description: Exact keys, missing identity and original five-field source tuples
    requirement: SPEC-05
    verification:
      - kind: unit
        ref: mix test test/crosswake/policy/compiler_test.exs
        status: pass
    human_judgment: false
  - id: finite-policy-product
    description: Independent normalized and staged 108-case policy products with separate malformed route contracts
    requirement: SPEC-05
    verification:
      - kind: unit
        ref: mix test test/crosswake/policy/finite_product_test.exs test/crosswake/policy/route_test.exs
        status: pass
    human_judgment: false
  - id: corruption-controls
    description: Actual allowed, denied, security, key and source mutations fail intended assertions and restore compiled behavior
    requirement: SPEC-05
    verification:
      - kind: integration
        ref: 196-EVIDENCE/policy-product.json#controls
        status: pass
    human_judgment: false
actuals:
  tokens: 5933
  tasks: 3
  commits: 4
plan_head_before: 1697d1df7c773faf99489a438a2395a90c545975
plan_head_after: e370eee926b65a0d406deae902386faca1f85965
duration: 8min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 08: Independent policy oracle and diagnostic provenance Summary

Structured atom diagnostics retain original route sources, and two independent 108-case policy oracles reject five real production corruptions.

## Performance

- Started: 2026-10-27T16:04:55Z; completed: 2026-10-27T16:13:00Z.
- Three tasks, five task files. Four measured task commits before metadata; 23,732 realized diff characters / 4 = 5,933 estimate-scale tokens. The persisted git ledger supplies both commit boundaries above.

## Accomplishments

- Real NimbleOptions 1.1.1 unknown-option errors contain grouped keys. Compiler normalization retains the structured error, emits one atom-keyed diagnostic per unknown option, and rejects an unsupported key shape explicitly. Missing ID remains `{:id, nil}`. Key selection no longer reads English messages; existing meaningful wording and hints remain.
- Successful `{normalized_route, original_source}` pairs survive filtering and reversal. Duplicate checks consume pairs directly, and Validator receives the corresponding source list. The invalid-first regression checks five exact diagnostics and each original path/helper/verb/file/line tuple, with distinct verbs and source fields.
- The handwritten nine-cell table and independent entry/security/sync rules specify all 108 unique normalized semantic cases. A separate compiler loop executes the same 108 combinations with an explicit early external-island entry rule. Both loops assert input, uniqueness and completed counts equal 108, and compare exact sorted `{key, route_id}` pairs. Omitted security and absent sync are actually omitted in compiler inputs.
- Malformed options, missing fields, non-list boundaries, explicit nil identifier normalization and `new/1` versus `new!/1` are separate examples. Existing explicit nil ID normalization to the string `nil` is preserved; missing ID is rejected.

## Task Commits

1. **196-08-01:** `3c014219` RED regressions; `9c23fb95` minimal compiler fix.
2. **196-08-02:** `1108e94a` independent semantic/staged product and route examples.
3. **196-08-03:** `e370eee9` five actual-source controls, exact diagnostic failure output and nonempty assertion guard.

## Verification

1. `mix test test/crosswake/policy/compiler_test.exs` — initial exit2, 9 tests, 2 intended assertion failures; after fix exit0, 9 tests, 0 failures. Unknown keys had collapsed to runtime, invalid sync had a nil key, and invalid-first input shifted source attribution. Both regression targets executed; no fixture/import/discovery failure occurred.
2. `mix test test/crosswake/policy/finite_product_test.exs test/crosswake/policy/route_test.exs` — exit0, 19 tests, 0 failures; semantic108 and staged108 input/unique/completed assertions passed.
3. `mix test test/crosswake/policy/finite_product_test.exs test/crosswake/policy/compiler_test.exs test/crosswake/policy/route_test.exs` — final exit0, 28 tests, 0 failures after every source restoration and final test edit.
4. `mix format --check-formatted lib/crosswake/policy/compiler.ex test/crosswake/policy/compiler_test.exs test/crosswake/policy/finite_product_test.exs test/crosswake/policy/route_test.exs` — exit0. All touched Elixir files formatted explicitly.
5. `elixir script/check_absence_is_not_success.exs --collections-mode enforce` — exit0, 312 files, 84 existing findings, delta0; no baseline change. An initial delta1 in the new compiler test was fixed with an explicit nonempty errors assertion.

The receipt records the exact source SHA-256 identities, commands, exits, cardinalities, control mutations and restoration outcomes. Compiler final source: `c74d89ca28174b0fc881f537fe2e9ab1ea9d3093d2df88774485f1ccc07787aa`; Validator before/after: `cfd5a07c6e42f646d2556f54570c6fa3d5f3e3d92b606c35f5a9c28c34be5849`. Validator has no retained diff.

## Mutation Controls

Each bounded Python subprocess control saved exact bytes, required a unique mutation anchor and changed bytes, invoked the actual focused `mix test` suite, required exit2 with nonzero ExUnit failures, the named target assertion and its exact pair fragment, and rejected compilation errors. `finally` restored exact bytes and ran the same suite again, recompiling restored production behavior and requiring exit0. All five were rerun against the final test revision. No copied expected report was used.

| Control | Actual corruption | Intended red result | Restored result |
|---|---|---|---|
| allowed_to_denied | Add offline denial for allowed live_view/unavailable cell | Product suite2 tests/2 failures; unexpected offline pair | exit0; exact bytes |
| denied_to_allowed | Disable live_view/local_first denial | Product suite2 tests/2 failures; required offline pair absent | exit0; exact bytes |
| required_security_removed | Disable required-security branch | Product suite2 tests/2 failures; required security pair absent | exit0; exact bytes |
| diagnostic_key_corrupted | Replace derived atom key with a corrupt atom | Compiler suite9 tests/2 failures; grouped unknown pairs wrong | exit0; exact bytes |
| source_attribution_corrupted | Give Validator the first input's source for every success | Compiler suite9 tests/1 failure; exact source tuples wrong | exit0; exact bytes |

An initial allowed-cell probe failed both product assertions, but custom assertion text hid pair differences. Removing that text exposed standard expected/actual output; all five controls then passed the stricter evidence checks. Raw ExUnit failure reports were not retained, following the value-free evidence requirement.

## TDD Gate Compliance

This is an execute plan; configured phase TDD mode is false. Task01 nevertheless has a separate actual RED commit followed by GREEN. The task02 oracle specifies existing semantics and required no production policy change; task03 proves it rejects actual changed behavior. No ExUnit report was presented as a supported-format machine-classified RED receipt. The required source-level controls and semantic failure checks are recorded directly and are not a claim that the later full Muex pilot ran.

## Deviations from Plan

None. Diagnostic/source fixes, route-boundary examples, nonempty assertions and the five controls implement the planned slice. No new runtime behavior, public result shape, dependency or source taxonomy was introduced. Context7 MCP and CLI were unavailable; dependency behavior was checked against the installed NimbleOptions 1.1.1 primary source and actual errors.

## Remaining Scope and Lifecycle

No stubs, skipped tests or unrun plan verifications remain in this slice. No new network, authentication, file-access or schema trust surface was introduced. No tracked files were deleted. Local commits each used the conditional absolute-per-file privacy scan and immediate rescan. No push, PR, merge, tag, publish or remote deletion occurred.

All eight Phase196 requirements and GR-06 remain pending independent verification. The SPEC-05/unclassified assumption remains for the independent checker: this slice implements the explicitly chosen 108-case/staged oracle and malformed/provenance criteria without silently clearing that flag. Other guards, full five-file Muex pilot and CI promotion remain future plans. SDK advance-plan/record-metric/record-session ran with explicit `--ws`; its known phase/progress mismatch is reconciled directly in the scoped STATE and ROADMAP, kept compact.

Last completed phase:195. Active phase196:8/17 plans complete; next plan196-09. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`. Do not repeat plans01–08. Adopter work remains parked.

## Self-Check: PASSED

All five task artifacts exist. Commits `3c014219`, `9c23fb95`, `1108e94a`, and `e370eee9` are ancestors of HEAD. Final receipt hashes match all five inspected source files; five controls have distinct changed hashes and equal original/restored hashes. Final focused tests, formatting and collection enforcement pass.
