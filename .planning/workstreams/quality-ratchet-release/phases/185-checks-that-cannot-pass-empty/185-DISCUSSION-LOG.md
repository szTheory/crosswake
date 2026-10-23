# Phase 185: Checks that cannot pass empty - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-16
**Phase:** 185-checks-that-cannot-pass-empty
**Areas discussed:** Absence checker floors, Cleanup that saw nothing, Lockfile count, v25 loop scope

Advisor mode was active (USER-PROFILE.md exists). No new advisor researchers were spawned, because the v26 research (SUMMARY, CHALLENGE, STACK, FEATURES, PITFALLS, ARCHITECTURE) already covered every area, and the user had asked for its synthesized recommendations to be followed. The orchestrator checked the candidate code at `b898e110`, then presented one recommendation for each area together, in a single question (per the research-then-recommend preference).

---

## All four areas (presented together)

| Option | Description | Selected |
|--------|-------------|----------|
| Accept all (Recommended) | Exact pin for test files, non-empty for planning globs; `registry_gone` error with callers unchanged (deferred); both lockfiles or `:identity_unknown` on both sides; measure v25 loops in report mode, fix `twin_receipt_test:289`, no blocking rule | ✓ |
| Revisit cleanup errors | Whether a failed or empty cleanup should change the twin run's verdict now | |
| Revisit pinned counts | A looser test-file floor, or exact pins for the planning globs | |
| Revisit loop scope | Measure beyond v25-touched test files, or add a blocking rule if zero findings | |

**User's choice:** Accept all (Recommended)
**Notes:** none.

---

## Claude's Discretion

- Failure-message wording, mutation details, fixture layout, how the per-glob floor is structured, and the plan split.

## Deferred Ideas

- Propagating cleanup failure into the twin verdict (receipt-touching).
- VACG-01 and the ledger scaffolding sunset.
- SEED-023 sites that were not read and are outside v25.
- The `twin_journey` residue-scope mismatch (note only).

---

## Fan-out review (2026-10-16, same session)

The user asked for every decision point to be enumerated, researched with subagents through all relevant lenses (architecture, SRE/test reliability, security, maintainer DX, verifier), challenged adversarially, and then for the best coherent recommendations to be followed. Four read-only sonnet agents ran against the candidate at `b898e110`.

| Agent | Key findings | Effect on CONTEXT |
|---|---|---|
| Absence checker | The script also exits 0 for a root that is a file, for a bare `--root`, and for an unknown argument (it falls back to the cwd). `Path.wildcard` counts a directory named `x.exs` and skips dot-directories, while `:filelib.fold_files` does the opposite. `git ls-files` is unusable (non-git fixtures; `*` crosses `/`). Tests grep two OK phrases (test:25-26). Every existing fixture would go red under the floors. | D-01 (independent walk plus regular-file filter), D-02 (strict args, exit 2 vs 1), D-03 (`@scopes` table, `--min-test-files`), D-04 (keep the phrases), D-05 (`baseline!` helper, new cases) |
| Loop measurement | About 94 loop sites in the 45 files. Beyond `:289`, unguarded runtime-derived sites: `doctor_origin_mode_test:360`, `phase64_runtime_line_policy_test:412/460`, `verify_twin_test:582/640`, plus a deliberate conditional at `doctor_test:859`. Per-group counts are fixed by the roster. Mutating the test input would fail for the wrong reason. | D-06..D-11 (AST scan with self-checks, ledger vocabulary, fix every needs-fix site, roster-derived exact count, projection mutation plus paired negative control) |
| Twin cleanup | **A second freeze-side lock site, `verify_twin.ex:226`** (verified by the orchestrator): it keeps whichever lockfiles exist and returns a non-closed atom; the same file missing on both sides passes. `Process.alive?` followed by `Agent.get` is racy; catch `:exit` instead. The registry is unlinked, and children are OS process groups only it tracks. No test calls stop twice. | D-13 (catch `:exit`, `stop_all` still closes the listener), D-14 (pin the callers' behaviour with a test), D-15 (three lock sites, digest directly, `:identity_unknown`), D-16 (public entry points, three reverts) |
| Adversarial review | The planning scopes lacked a "pinned count". `expected` was undefined (risk of a self-referential glob). The pin would go stale-low if taken at plan time. The OK-line change broke existing tests. The error nobody reads. Exit code unspecified. A pre-fix measurement was needed. Phase 184 regression gates needed naming. The `ci_monitor.cjs` edit was out of path. | D-01, D-03 (pin of 1 for planning; final-commit measurement), D-04, D-14, D-02, D-17 |

**Conflicts resolved:**
- **Planning floors.** The adversarial review wanted measured pins; the checker research wanted floors of 1. Floors of 1 won, as literal pins in the same table: GSD's own todo workflow moves todos into `pending/` and `completed/`, so measured pins would churn into waivers. A wrong root is caught by the test-file pin.
- **Trailer.** The adversarial review questioned the Opus trailer. The session's attribution instruction names `Claude Opus 5.5`, so it stays.
- **SEED-023 note.** The review said planning files must stay unmodified. That is not the rule: planning files are edited as plain uncommitted files; only staging and commits are forbidden. The note goes in the SEED-023 file.

**Rejected:** `git ls-files` as `expected`; JSON or test-file pins; an automatic ratchet; an idempotent "stopped" flag; `start_link`; mapping a stop failure to `:cause_not_retained` (misleading); a new cause atom; a repo-wide rule.
