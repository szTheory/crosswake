---
phase: 196-spec-and-structure-ratchet
plan: "10"
subsystem: testing
tags: [elixir, ast, rescue, privacy, actual-main]
requires:
  - phase: 196-09
    provides: Completed compile-structure slice and fixed actual-main capsule contract
provides:
  - Explicit advisory location results preserving original authoring errors and location fallbacks
  - Two exact semantic arbitrary-extension containment records with unchanged closed denials
  - Six-family rescue ratchet with real-script controls and final-blob actual-main findings
affects: [196-15, ARCH-02, phase-verification]
tech-stack:
  added: []
  patterns: [finite diagnostic rescues, literal semantic records, independent scope discovery]
key-files:
  created:
    - test/crosswake/bridge/location_diagnostics_test.exs
    - script/check_rescue_boundaries.exs
    - script/fixtures/rescue_boundary_exceptions.exs
    - test/crosswake/proof/rescue_boundary_ratchet_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-rescue.json
  modified: [lib/crosswake/bridge.ex, lib/crosswake/compatibility/route_gate.ex, test/crosswake/compatibility/compatibility_test.exs]
key-decisions:
  - "Advisory reflection/read/text failures return closed internal results; existing error class, remediation and location fallbacks remain authoritative."
  - "Only the dependency and auth extension call sites retain named arbitrary-exception containment; dependency throws remain caught and exits retain their existing propagation."
  - "Review records bind file, module, function arity, normalized complete rescue clause and protected call; all six source families require nonempty independent discovery."
requirements-completed: []
requirements-addressed: [ARCH-02]
coverage:
  - id: advisory-authority
    description: Real authoring errors survive unavailable reflection and missing/unreadable/invalid source hints
    verification:
      - kind: integration
        ref: mix test test/crosswake/bridge/location_diagnostics_test.exs test/crosswake/router_test.exs
        status: pass
    human_judgment: false
  - id: extension-containment
    description: Arbitrary exceptions and existing throw/exit semantics preserve closed denial metadata
    verification:
      - kind: integration
        ref: mix test test/crosswake/compatibility/compatibility_test.exs
        status: pass
    human_judgment: false
  - id: six-family-rescue-ratchet
    description: Exact two-site exception review and real-script source/record/scope controls
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/rescue_boundary_ratchet_test.exs
        status: pass
      - kind: other
        ref: 196-EVIDENCE/main-rescue.json
        status: pass
    human_judgment: false
actuals:
  tokens: 11211
  tasks: 3
  commits: 9
plan_head_before: b9b30202d873cd00e293e392450caa79a6405159
plan_head_after: 05e5258e640d2b3177578c33d70e8cc36c8f1e80
duration: 12min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 10: Exact rescue boundaries Summary

Three advisory bridge helpers return explicit closed results, while a native AST ratchet permits arbitrary-extension exception containment only at two reviewed route-gate sites.

## Accomplishments

- `find_router_route/2`, `router_source_file/1` and `best_effort_line_suffix/2` now return `{:ok, value}` or `{:error, closed_reason}`. Reflection uses finite expected exception classes; source reading uses `File.read/1`. Invalid UTF8 and absent line matches are closed hint failures. Existing consumers translate these results into the same unavailable-router, unknown-file or empty-suffix fallbacks. No new public API, authorization success, raw exception output or catch-all was added.
- Real `Bridge.push/3` tests preserve `UndeclaredCapabilityError`, its stable message/remediation and absence of synthetic exception text with nil/missing/broken route reflection. Compiled router fixtures point at missing paths, directories, invalid UTF8, text without the hint and a valid line2 hint. Existing push integration tests also passed, including the established diagnostic messages and dispatch behavior.
- Exactly two `_extension_error` rescue clauses preserve their existing sanitized return values. The companion dependency call still produces `dependency_missing` with `missing_kind=adapter_unloadable`; the auth-authority call still produces `dependency_missing` with its existing companion-id details. Arbitrary custom exception classes remain contained. Dependency `throw` remains caught; dependency `exit` still propagates because the original one-pattern catch handles throws only. No catch was broadened or added to auth.
- The two literal records bind repository-relative file, module, function/arity, metadata-free complete clause and protected call target. They name `companion.validate_dependency()` in `check_dependencies/2` and `authority.evaluate_auth(route, auth_context, opts)` in `prepend_auth_evaluation_denials/4`. The scanner does not evaluate executable record expressions. Records must be exactly two, valid, unique and each match exactly one site; no refresh mode or module/file blanket allowance exists.
- Recursive filesystem discovery and independent wildcard discovery agree on the full six-family roster. Each family must contain a root file or descendant; directory-only families are valid. Parse/read/symlink failures and empty overall/subset scopes fail closed. Wildcards and renamed/dynamic whole-exception rescues fail outside the records. Finite bare classes, bare class lists, named single/list classes and direct original-exception reraises remain valid. String fixtures stay data.
- The enforcing root test was created after a committed guard was measured on actual main. A later finite-syntax correction received another committed-capsule capture before final acceptance. The root test verifies both current tool SHA256 and Git blob identities, checks every retained main subject against its actual Git object, and runs current repository enforcement.

## Task Commits

| Task | Commits | Result |
| --- | --- | --- |
|196-10-01|`cec7522e`, `984d1ef3`|Structural-contract RED, preserved real authoring behavior and explicit-result GREEN|
|196-10-02|`c27da212`, `dc67ffcb`|Named-clause RED, preserved custom exception/throw/exit behavior and two semantic records|
|196-10-03|`7fa11971`, `c85e75ba`, `c469ac1d`, `4437ac1c`, `05e5258e`|Report guard, truthful subject findings, measured main, finite-syntax RED/GREEN, final capture and 30 guard tests|

Nine commits are measured from the persisted ledger through05e5258e, excluding the later SUMMARY/lifecycle commit. Actual tokens11211 are ceiling(44843 realized diff characters/4) across eight task files. Approximate duration12minutes includes context loading; the recorded task commits span16:30:08Z–16:39:28Z.

## Commands and Results

All mutable commands ran sequentially in the one existing feature checkout.

1. `mix test test/crosswake/bridge/location_diagnostics_test.exs test/crosswake/router_test.exs` initially executed5 tests with exactly one intended failure on the explicit-result contract; the real unavailable-reflection authoring assertion passed already. Initial fixture compile/setup mistakes were corrected before accepting this RED and are not claimed as behavioral evidence. After implementation and source-hint controls, the planned pair passed6 tests. `mix test` of those files plus `test/crosswake/bridge/push_test.exs` passed55 tests/0 failures.
2. `mix test test/crosswake/compatibility/compatibility_test.exs` executed17 tests with one intended named-clause assertion failure before changing the two rescue clauses. Custom exception, throw, exit and telemetry controls already passed against the prior behavior. After the change,17 tests/0 failures. Dependency stop metadata is asserted exactly apart from the opaque span context; neither decision nor metadata contains the custom exception payload. Auth denial remains closed without its exception payload.
3. `elixir script/check_rescue_boundaries.exs --mode report --root .` and final `--mode enforce --root .` each exited0 on the candidate with42 files,9 rescue clauses,2 matching records and0 findings.
4. `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard rescue --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-rescue.json` succeeded for the final committed capsule4437ac1c11b4125021a21468a6592ddb9678d6a9. Actual origin/mainb8398c38e7d92c8bb99dcbc87fdb2370a47e6e97 has41 subjects,9 clauses,0 matching named records,5 broad-rescue findings and2 stale-record findings. Guard exit1 is retained honestly; capture exit0 means source identity and restoration were verified, not that main was green.
5. `mix test test/crosswake/proof/rescue_boundary_ratchet_test.exs:61` demonstrated a real finite-syntax fixture RED (exit2,1 test/1 failed assertion: guard code1 rather than0), then GREEN (exit0,1 test/0 failures) after allowing finite bare lists and named singleton classes. The final full guard suite has30 passing tests: repository and finite-syntax positives plus28 negative controls. An earlier fixture expected7 files instead of8; correcting that count was test maintenance, not a production RED.
6. Final combined command: `mix test test/crosswake/bridge/location_diagnostics_test.exs test/crosswake/router_test.exs test/crosswake/compatibility/compatibility_test.exs test/crosswake/proof/rescue_boundary_ratchet_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs test/crosswake/proof/phase136_decouple_proof_test.exs` — exit0,62 tests/0 failures,10.8seconds. This includes all planned commands and nine existing dependency/auth regression tests. No implementation changed afterward.
7. Explicit `mix format --check-formatted` covered all seven touched Elixir production/script/fixture/test paths, exit0. `measure-main.mjs verify-source` exited0, independently verifying1359 source records. Every local commit used fresh conditional absolute per-file privacy scans and immediate rescans; final capture scanned160 changed candidate files before and after, both exit0.

## Executed Guard Controls

The tests create source trees and invoke the actual Elixir script; they do not invent accepted reports. Each negative control asserts process exit1 and its specific nonempty finding category. The positive fixture contains all six directory-only families and the real route-gate source.

- Wildcard, renamed whole exception, dynamic classes and empty class list produce `broad_rescue`; a new root-file broad clause in each of the six families also produces it, including nested descendants.
- Missing, malformed, duplicate, stale-clause, wrong-function, wrong-call and executable/nonliteral record inputs produce `rescue_exception_mismatch`. Executable input is never evaluated and its synthetic message never appears in output.
- The same clause moved to another function, placed around another protected call, changed to another denial result, or moved to another module cannot borrow a record. Duplicating an exact site fails multiplicity.
- Malformed source and invalid UTF8 produce `parse_error`. A real mode000 regular file and a broken symlink produce `read_error`. Removing a complete family produces `scope_mismatch`; empty overall discovery produces `scope_empty`.
- Finite class forms, direct reraise, and a string containing rescue-like text pass with exactly8 fixture files,7 clauses and2 reviewed exceptions. Output contains only relative input paths, labels and counts, never parser/record exception contents or the temporary root.

## Final Source and Restoration Evidence

|Tool|Git blob|SHA256|
|---|---|---|
|guard|`d12f05a9e406bc66a9b2b5f92294f8ccd8640a7f`|`02761ec435e06008f73d0e9b4736377f654eb95f3285b9e48cbbeb5e96370a62`|
|records|`0872c8db399f4c8e34ed383a40f2f688103dfd9e`|`2c9cafb4a4734a5d2b8a5da534d9168fe6df0f55c433a90f32fec7a3edba2df0`|

Final capture restored branch fix/spec-structure-ratchet and exact HEAD4437ac1c. Index SHA2560865f179fb8773f6637108d907d495aaab7e786bf68b4f362618d316c974b75d,6158 tracked files and0 untracked files matched the saved inventory. Capsule and subject hashes were checked before/after; no worktree was created. Both final tool blobs still match the receipt. No guard code changed after the final capture.

## Deviations and Limits

- [Rule1 - Bug] The first capture correctly rejected `guard_finding_invalid`: stale-record findings named the tool record file outside the actual subject roster. No receipt was accepted, and the helper restored the exact clean candidate. Findings now name the affected scoped route-gate source; the next capture succeeded. This changes attribution, not which failures count.
- [Rule1 - Bug] Initial record text interpolated the quoted auth clause instead of remaining literal. Escaping that interpolation restored a parseable literal review record before scanner acceptance. Initial AST traversal also encountered a generated function name; metadata-free normalization handles it without suppressing scanned code. These development corrections are included in7fa11971.
- [Rule1 - Bug] A real finite-syntax fixture exposed overrejection of bare class lists and named singleton classes. The focused failing assertion preceded4437ac1c; that minimal fix passed, and final capture was renewed.
- [Process deviation] Tasks1/2 change internal structure while preserving public behavior: real authoring and extension-denial assertions were already green; their explicit-result/named-clause contract assertions supplied RED. Task3's initial guard implementation preceded its fixture assertions; only the finite-syntax correction has pre-change fixture RED/GREEN. No machine-classified or fully behavior-first TDD compliance is claimed. Mandatory ledger entry41 in `.planning/WINDOWS.md` preserves this for independent review. Workflow tdd_mode is false.
- [Rule3 - Environment] Initial Git metadata writes were sandbox-denied, without source loss; authorized scoped commits and same-checkout capture succeeded with filesystem escalation. The configured Claude executor identifier is unavailable in this runtime; the inherited supported model executed the work.
- Scoped lifecycle handlers were invoked explicitly with `--ws quality-ratchet-release`; known SDK progress/decorated-row mismatches were reconciled directly in the compact workstream state/roadmap. The final lifecycle retains6 phases,40/47 total plans(85%) and10/17 active-phase plans. Requirements stay unchecked pending independent verification.
- No stubs, skipped implementation tests, unrun plan acceptance command, new endpoint, auth path, schema or dependency remains. New filesystem/process inputs are the existing plan threat boundary. The guard intentionally scans six source families and rejects semantically unreviewed containment; it is not a general exception-flow or interprocedural verifier. ARCH-02's exception-authority taxonomy assumption remains explicitly unclassified for independent review.

Last completed phase remains195. Phase196 is executing,10/17 plans complete; exact next command is `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-11-PLAN.md. Do not repeat plans01-10. All eight Phase196 requirements and GR-06 remain pending independent verification. No push, PR, merge, publish, tag, remote deletion or approval transfer occurred.

## Self-Check: PASSED

All eight task artifacts exist and all nine recorded task commits are ancestors of HEAD05e5258e. The persisted ledger measures9 commits and44843 diff characters. Final62/62 tests, format, source verification and enforcement passed after the last implementation change; both capsule hashes still match the actual-main receipt. No tracked file was deleted.
