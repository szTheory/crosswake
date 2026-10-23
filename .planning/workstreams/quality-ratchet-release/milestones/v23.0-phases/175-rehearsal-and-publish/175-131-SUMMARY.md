---
phase: 175
plan: 131
subsystem: release-candidate
tags: [current-facts, policy-read, authenticated-read, plan105]
dependency-graph:
  requires: [Plan 130 local reproduction, Plan 105 current-facts read, Plan 124 scoped replay]
  provides: [scoped authenticated repository-policy read]
  affects: [Plan 105 mirror-tag rehearsal]
tech-stack:
  added: []
  patterns: [versioned read scope, fake transport production-seam test]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-131-SUMMARY.md]
  modified:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/state.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-VALIDATION.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-PATTERNS.md
decisions:
  - Policy reads use a separate v2 scope and exact authenticated ruleset routes while preserving v1 anonymous current-facts behavior.
  - Policy access requires matching verified identity, a collaborator role of ADMIN, WRITE, or MAINTAIN, and explicit TRUE permission.
  - Missing, null, malformed, or unsupported bypass data remains UNKNOWN; ADMIN is not treated as effective tag-write authority.
metrics:
  duration: 34m
  completed: 2026-10-10
  tasks: 2
  files: 14
  commits: 0
  plan_head_before: 0773bb4843302f562d48438922f4b88898b7a6b2
  plan_head_after: 0773bb4843302f562d48438922f4b88898b7a6b2
status: complete
actuals:
  tokens: 22233
  tokens_estimated: true
  token_scope: executor estimate; parent integration work excluded
  tasks: 2
  commits: 0
---

# Phase 175 Plan 131: Scoped Policy Read Summary

Added an isolated Plan131 v2 current-facts read scope that adds authentication to the exact ruleset list/detail GET routes after verified identity and explicit collaborator write permission. Existing `/user` and collaborator permission reads remain authenticated, and Plan124 v1 ruleset requests remain anonymous.

## Completed Tasks

1. Added Plan131 policy-read scope, card, authorization, lifecycle, result, and four explicit Mix modes. The legacy v1 current-facts contract remains intact.
2. Added collector policy-route authentication and fail-closed access checks, Node contract tests, and an ExUnit tracer that runs the real Elixir adapter through the actual Node collector with injected fake credential, fetch, and process implementations.

The production-seam tracer used only a synthetic temporary root and fake transports: 7 fake GitHub GETs, 16 fake Git operations, 1 synthetic credential lookup, and 2 permission checks. It asserted the complete ordered route/header sequence, including auth on `/user`, collaborator permission, and both policy GETs. It observed no external network activity and performed no dry run, tag, CI, merge, registry, publication, or release action. Denial and HOLD paths made no policy GET or collector call; card/scope/lifecycle/auth/result tampering, cross-version auth, and replay were rejected before another adapter call. No real attempt, card, or authorization was created in workstream evidence.

## Verification

- Node collector suite: 114 tests passed, 0 failed, 0 skipped.
- Focused ExUnit suite: all 37 cases passed again within the final 72-test affected-module rerun, 0 failures.
- Named policy-auth tracer passed through the real Elixir production adapter and actual Node collector.
- V2 Node matrix covered the exact 262,144-byte body boundary and overflow, HTTP/redirect/JSON/body-shape failures, four-page and sixteen-detail limits plus over-limit cases, returned numeric detail routes, missing credentials, UNKNOWN/READ/TRIAGE denials, and WRITE/MAINTAIN/ADMIN access.
- V2 policy completeness remains false when known applicability is mixed with UNKNOWN applicability, or when conditions/rule shapes are unsupported. Legacy v1 behavior remains covered.
- ExUnit evidence covers tampered cards before decision and after ALLOW, rehashed auth schema swaps in both directions, lifecycle schema substitution, malformed result, wrong auth path, changed collector, rehashed scope tampering, absent decision, HOLD, and no callback on replay/tamper.
- The ALLOW result, authorization, lifecycle, and card were checked for canonical hashes and scope/card/auth/event/result bindings, plus absence of plaintext/base64 credential, login, raw response text, and temporary path leakage.
- Node syntax check passed; Mix format check passed for all three Elixir files; scoped `git diff --check` passed.
- TDD RED evidence for this acceptance pass: ExUnit initially showed missing inspected card digest and allowed a tampered card at decision time (36 tests, 2 failures); the v2 Node policy-completeness matrix showed an applicable-plus-UNKNOWN ruleset set incorrectly reported complete. These assertions pass after the fixes.

## Decisions Made

- Additional authenticated routes are exactly the fixed mirror ruleset list and returned numeric detail GET routes. The policy scope has a distinct `crosswake-plan105-current-facts-read-scope/v2` contract and Plan131-prefixed persisted artifacts.
- The rendered card shows v2 and describes policy routes as additional to the authenticated `/user` and collaborator-permission checks. The raw card digest is exposed by inspect and is cross-bound into the exact-key Plan131 authorization; decision and run boundaries compare the saved card with its canonical bytes.
- A policy read proceeds only when `/user` identity matches and collaborator permission is explicitly TRUE for ADMIN, WRITE, or MAINTAIN. This does not infer bypass or effective tag-write authority from ADMIN.
- Omitted, null, malformed, or unsupported bypass and permission shapes remain UNKNOWN.
- `currentPullVersion` and candidate version remain UNKNOWN.
- Workstream execution policy sets `phase_commit_docs.175=false`; consequently no files were staged and no task or summary commit was created.

## Deviations from Plan

The post-wave integration gate required bounded reconciliation outside the five implementation/test files: pin the new lifecycle assertions to exactly four events, regenerate the assertion ledger (two added rows and one shifted row), update its measured totals, remove an existing resume breadcrumb from STATE, and strip seven existing trailing-whitespace lines from PATTERNS. All six full-suite failures then passed. The orchestrator also updated workstream tracking and appended executed validation; no prior plan, summary, or evidence was rewritten. The explicitly supplied no-commit phase policy was followed.

## TDD Gate Compliance

RED was demonstrated by the card-integrity ExUnit assertions and v2 policy-completeness Node assertion before their fixes. GREEN was demonstrated by the named ExUnit/Node tracers and full focused suites after implementation. No commits were made because phase 175 explicitly disables commits.

## Preserved Workstream State

This local read addition does not establish Plan129's cause; its ALLOW remains spent. Plan106 HELD; Plans46–48/89 HELD; candidate version UNKNOWN. REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; effective write remains UNKNOWN; tag authority remains NONE; merge policy remains UNKNOWN; release hold remains ACTIVE. No phase-wide verification was performed.

## Self-Check: PASSED

The summary file exists; both local tasks, prescribed name/hold/version guards and integration reconciliation passed. The five implementation/test files plus bounded integration and workstream tracking changes are accounted for. All 493 pre-existing plan/summary/evidence files remain byte-identical, and index/HEAD/branch remain unchanged as required by phase policy.

## Orchestrator Integration Gate and Handoff

Warnings-as-errors compilation passed. The full offline Mix run completed in 738.8 seconds with 2,370 tests, six failures and 74 excluded cases. The six failures were three assertion-ledger checks, the state breadcrumb check, its nested Phase135 proof, and the navigation proof’s global whitespace gate. After the bounded reconciliation above, `mix test --failed --trace --max-cases 1` passed all six, followed by a full affected-module run of 72 tests with zero failures. This records the initial failures and verified fixes; it does not claim that a second full-tree run occurred. The final Node suite passed 114 tests; the assertion inventory passed 255 sites; Node syntax, named Elixir format and global whitespace checks passed. The existing isolated public Hex cache was used with `HEX_OFFLINE=1`; no dependency installation or new CI lane was added.

The post-execution index reports 111/116 complete and only Plans106/46/47/48/89 incomplete. Plan106 is mechanically listed ready but remains semantically HELD because its Plan119-pinned preflight, permission/policy, dry-run and separate tag decision prerequisites are unmet. Phase175 remains IN PROGRESS / INCOMPLETE / RELEASE-BLOCKED; last completed phase remains 174. No phase verifier or phase completion ran.

Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`, confined to a separately reviewed fresh authenticated-policy read scope/card using the repaired collector. A later external read still requires a fresh displayed card and its own one-use plain-language allow/hold. Candidate version acquisition remains a separate unresolved question. Do not repeat discussion/Wave35, resume held plans, transfer Plan129’s spent ALLOW, or infer tag/release authority from local fake success. Requirements, ADRs, public support truth and guide renderings were unchanged because no live outcome or support decision changed. No files were staged or committed.
