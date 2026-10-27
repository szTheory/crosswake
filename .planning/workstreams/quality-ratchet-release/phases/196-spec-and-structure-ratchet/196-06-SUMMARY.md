---
phase: 196-spec-and-structure-ratchet
plan: "06"
subsystem: testing
tags: [elixir, ast, lexical-analysis, absence, multiset, actual-main]
requires:
  - phase: 196-05
    provides: Completed preceding slice and committed source/capture contract
provides:
  - Branch-local collection presence facts and exact residual multiset enforcement
  - Actual-main measurement of the final committed tool capsule
  - Real-script controls for lexical, multiplicity, parsing, reading and scope failures
affects: [196-15, SPEC-02, phase-verification]
tech-stack:
  added: []
  patterns: [native AST lexical traversal, explicit report mode, metadata-free expression digests, real subprocess controls]
key-files:
  created:
    - script/absence_collection_ast.exs
    - script/fixtures/absence_collection_baseline.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/absence-tracer.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-absence.json
  modified:
    - script/check_absence_is_not_success.exs
    - test/crosswake/proof/absence_is_not_success_test.exs
    - test/crosswake/proof/phase132_compat_matrix_drift_test.exs
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/measurement-controls.json
key-decisions:
  - "Presence facts belong to exact collection bindings and reachable lexical branches; shadowing invalidates them."
  - "Residual identity is file plus enclosing context plus SHA256 of the metadata-free normalized expression, with literal occurrence counts and reviewed rationale."
  - "Collection default remains report-only; Plan15 owns default promotion. Analysis errors fail in either mode."
  - "Capture isolation rejects repository-related or unknown-cwd mutable processes; proven foreign processes are unrelated."
requirements-completed: []
requirements-addressed: [SPEC-02]
coverage:
  - id: absence-lexical-multiset
    description: Same-collection branch dominance and new/increased/stale occurrence discrimination
    requirement: SPEC-02
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/absence_is_not_success_test.exs
        status: pass
    human_judgment: false
  - id: absence-actual-main
    description: Final committed capsule measured on actual origin/main with exact restoration
    verification:
      - kind: other
        ref: 196-EVIDENCE/main-absence.json
        status: pass
    human_judgment: false
actuals:
  tokens: 35001
  tasks: 3
  commits: 9
plan_head_before: ac5d08680836374e3d481d5030306a5d5b2aa6b5
plan_head_after: 010764c1f8e4d4e02e320c9f954ba1e9b7a9ed4a
duration: 19min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 06: Branch-sensitive absence guard Summary

Native AST traversal now detects unproved collection assertions, glob loops and literal success, while an explicitly reviewed 84-occurrence multiset prevents new, increased or stale exceptions.

## Accomplishments

- Preserved mutation-change and open-citation checks. The collection checker defaults to report-only and supports explicit enforcement, root selection and a fixture baseline. No CI configuration or default promotion changed.
- Scope independently compares wildcard discovery with recursive walking for root ExUnit and exactly five companions. Root minimum remains the independently measured existing 253 floor; current and actual-main root counts are 259. Companion counts are chimeway10, rindle8, rulestead3, sigra19 and threadline12: 311 ExUnit files, plus 48 planning inputs in the actual-main capsule roster, totaling359.
- Fixed the three direct glob loops in the two named owners. The compatibility test asserts exactly five companion Mix files. Both workflow tests assert nonempty workflow collections before iterating, with the release workflow excluded before the second collection's cardinality check. All original assertions remain.
- Baseline has84 explicit count1 occurrences:82 universal predicates and2 historical glob inventories. Each row is exact file/context/expression identity and carries a rationale. Intentional absence predicates remain explicit residuals; producer/helper cardinality is not invented. The two manifest `assert true` fallbacks measured on main were already removed by196-02 and are absent from the candidate baseline.
- The normalized expression commitment is SHA256 over the metadata-free AST's unlimited structural representation, not a source line or whole-file hash. Context remains readable; duplicate normalized expressions in different contexts stay distinct. There is no baseline refresh command or repository-source discovery in the baseline.

## Task Commits

| Task | Commits | Result |
| --- | --- | --- |
| 196-06-01 | `7f8debd4`, `ed930893`, `48f4d657`, `d03cce70` | Phase-only deletion tracer RED/GREEN, report-only capsule, necessary capture-helper correction, first actual-main receipt before root wiring |
| 196-06-02 | `b822bc0e`, `e642c62d` | Known-glob RED/GREEN, three repaired loops, exact reviewed residual baseline |
| 196-06-03 | `a7b73865`, `c3642591`, `010764c1` | Actual-script controls, demonstrated lexical/read/order fixes, final matching receipt |

Nine commits are measured from the persisted plan ledger through010764c1; this excludes the later SUMMARY/lifecycle commit. Tokens35001 are ceiling(chars/4) over that realized git diff, not harness tokens. Ten implementation/evidence files changed. The measured task-commit span is approximately19minutes, beginning15:32:22Z; initial context loading is excluded.

## Commands and Results

All commands ran sequentially from the repository root in the existing feature checkout.

1. `elixir .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/absence-tracer.exs` — final exit0,2 tests/0 failures. The first planned RED was exit2,1 test/1 assertion failure: the safe fixture expected0 while the unimplemented collection CLI returned2. The subsequent known-owner RED was2 tests/1 failure on the exact phase132 glob finding. Both GREEN checks passed after implementation.
2. `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs self-test` — exit0,33 controls passed (10 source,23 capture); fixed-schema receipt retained in `measurement-controls.json`.
3. `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard absence --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-absence.json` — final exit0,359 subjects, guard process exit0. Initial capture was committed before the root test changed; subsequent captures followed capsule changes. Final candidate is `c36425911006728c3562c20ab01bbbc4a0554b10`, actual origin/main is `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97`.
4. `elixir script/check_absence_is_not_success.exs --collections-mode enforce` — final exit0,311 ExUnit files,84 findings,delta0. Existing legacy scopes also passed. The captured main report has89 occurrences:82 unsafe_collection,5 glob_without_count,2 literal_true. Main is measured honestly; it is not required to match the repaired candidate baseline.
5. `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs test/crosswake/proof/phase165_ci_integrity_test.exs` — exit0,35 tests/0 failures.
6. `mix test test/crosswake/proof/absence_is_not_success_test.exs` — final exit0,58 tests/0 failures,28.2seconds. No temporary measurement exclusion remains. First full RED was55 tests/2 intended failures (identity sort and sanitized unreadable-source result). Two added shadow-binding controls also failed on their intended expected1/actual0 assertions before the lexical fix. A temporary `--exclude main_measurement` run proved57 behavioral cases while awaiting committed-capsule recapture; the final unexcluded run passed all58.
7. Explicit `mix format` covered every touched Elixir script, fixture and test. Every scoped commit used fresh absolute per-file conditional privacy scans and immediate rescans. Final actual-main privacy-before/after both exited0 over130 changed candidate files.

## Control Coverage

Real checker subprocesses discriminate deleting only a guard, guarding another collection, sibling/post-branch guards, late guards, rebinding, filtered collections, shadowed fn/for/with bindings, empty/unknown attributes, literal true, direct/rebound glob comprehensions and piped universals. Positive controls cover same-branch dominance, concrete list/attribute/attribute-alias evidence, positive length/count assertions, guarded glob iteration, explicit-empty results, positive existential assertions, quoted AST and string/sigil data.

Multiset controls admit exactly one synthetic residual, reject a duplicate with count2/baseline1, distinguish another context, reject stale removal without rewriting the baseline, and preserve output under recreation/discovery ordering. Malformed source, unreadable source, empty companion and wildcard-subset scope each fail with the intended closed category in report and enforce modes. Existing invocation/scope/citation/mutation controls remain in the same suite.

## Final Source and Restoration Evidence

| Tool | Git blob | SHA256 |
| --- | --- | --- |
| checker | `9a76cbb7917a0760d35362519cb7f45cccc06fae` | `47a5af1084c5786534caac036bb8e37d58d14cc7dc6ad3328dc64f718ba1553d` |
| AST helper | `436a0e5a4b79dc6329fe1024895ef966c619e3bf` | `8bf7976323593b1c6c93704b6d066da376e903bde0c603f32c5f4f5e3da3a1d4` |
| reviewed baseline | `aaba49c5517487dae992c3d1f06accd7614743d1` | `1ead5e6e7d72275bb2ad81af9ff1aca1c7add72a85e4c2365cd4d811d9438a8f` |

Capture restored branch `fix/spec-structure-ratchet` and exact candidate HEADc3642591. Index SHA256 `b36d31211fb64b48f93b1b5260f757e10ecad38d395d2ec53b80bde4bfb83ce7`,6140 tracked files and0 untracked files matched the saved inventory. Subject hashes, declared capsule hashes and protected source hashes were checked before/after. The final root test independently checks current tool hashes against the receipt. No candidate worktree was created; scratch contained extracted tools only.

## Deviations from Plan

**1. [Rule 3 - Blocking] Repository-scoped capture process isolation**
- Actual capture initially refused `mutable_process_active` before detachment because the helper rejected every machine-wide BEAM process. Read-only ps/lsof evidence identified persistent unrelated processes outside Crosswake; one retained an unlinked cwd whose parent existed. No foreign process was stopped.
- The correction keeps repository cwd/descendants, explicit repository arguments and unknown cwd/parent fail-closed. A kernel-reported unlinked cwd is resolved through its existing parent, then checked for repository containment. Synthetic controls cover missing cwd/parent, removed foreign/repository cwd and explicit repository arguments; real child processes in two disposable git repositories prove foreign acceptance, local refusal and post-exit acceptance.
- Files: phase `scripts/measure-main.mjs` and `196-EVIDENCE/measurement-controls.json`. Commit48f4d657;33 helper controls passed before the successful capture. The gate was narrowed to its declared isolation purpose, never bypassed.

**2. [Rule 1 - Bug] Closed failures, semantic order and binding shadowing**
- The required real-script controls demonstrated legacy read! bypassing `read_error`, internal map order differing from semantic identity order, and shadowed local variables borrowing outer facts.
- Scoped fixes sanitize the legacy reader handoff, sort by file/context/expression/category, invalidate local pattern bindings and fail analysis errors in either mode. Commitc3642591. Final58-test run and matching actual-main recapture passed; baseline remained84 exact entries.

## Limits and Next Action

Lifecycle handlers were invoked with explicit `--ws quality-ratchet-release`. `state.advance-plan` needed a labeled prose plan position in addition to frontmatter; after adding it the handler advanced6to7. The known SDK decorated-roadmap/progress parser returned a missing-phase-details refusal and inconsistent phase percentages. ROADMAP checkboxes/table/handoff and compact STATE were reconciled directly to six retained phase summaries,36/47 total plans,77%,six milestone phases and next plan07. Requirements were deliberately not marked complete.

This is bounded lexical analysis, not interprocedural proof or arbitrary Elixir evaluation. Baseline residuals are reviewed debt under a delta contract, not new guarantees about old producers. No stubs, skipped implementation tests or unrun plan acceptance commands remain. Fixture filenames containing TODO and literal test vocabulary containing placeholders are data, not unfinished implementation. No new endpoint, authentication path, production schema or package dependency was introduced; file input and sanitized proof verdicts remain inside the plan threat model.

All eight Phase196 requirements and GR-06 remain pending independent phase verification. Last completed phase remains195. Phase196 is executing,6/17 plans complete; next eligible action is `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-07-PLAN.md. Plan15 owns recurring default promotion. No push, PR, merge, publish, tag, remote deletion or approval transfer occurred.

## Self-Check: PASSED

All11 implementation/evidence/SUMMARY paths exist; all9 recorded commits are ancestors of HEAD010764c1. The measured ledger base isac5d0868; no tracked file was deleted by this plan. The final unexcluded acceptance suite passed58/58 and enforcement passed with84 findings/delta0 after the final capsule capture. The33-control helper receipt remains present. Requirement completion is intentionally deferred to independent phase verification.
