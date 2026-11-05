---
phase: 197-public-docs-truth
plan: 02
subsystem: docs-tooling
tags: [docs-report, mix-docs, baseline, requirements-amendment]

requires:
  - phase: 197-public-docs-truth
    provides: "197-01 docs-report with leak and link counters, mix_test_gate.sh"
provides:
  - "docs.warnings counter in script/docs-report (mix docs in dev, no --warnings-as-errors, UNVERIFIED on failure or no doc/index.html)"
  - "ExUnit guard that no workflow references the report, with an injected-reference control"
  - "D-19 baseline on a main-equal tree: 197-DOCS-REPORT.md plus verbatim evidence files"
  - "DOCS-01, DOCS-02, Phase 197 SC1/SC2 and a Phase 199 deferred=none criterion amended to D-04, D-06, D-10, D-12"
affects: [197-03, 197-13, 197-14, 199]

actuals:
  tokens: 19930
  tasks: 3
  commits: 3
plan_head_before: 81d7163f10dcbdf012d852d1ee57014efe11508a
plan_head_after: 8e41045cc6170fd75be18c037a7a7b4232a0a273

tech-stack:
  added: []
  patterns:
    - "Subprocess seam returns {output, exit}; a failed or missing run is UNVERIFIED, the one legitimate zero needs exit 0 plus doc/index.html"
    - "Parse the dependency's real output: warning blocks located by the first `└─ <file>:<n>` line before the next warning"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-DOCS-REPORT.md
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-baseline-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-baseline-detail-197.txt
  modified:
    - script/docs_report.exs
    - test/crosswake/docs_report_test.exs
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/STATE.md

key-decisions:
  - "Location of a warning is the first line starting with the box-drawing corner marker before the next warning, not any line containing path:digits, because quoted source lines in a block can contain such text"
  - "Baseline difference from D-19 is a unit difference: D-19 counted distinct (file, line) pairs, the tool counts occurrences; the tool was not adjusted"

requirements-completed: []

duration: 45min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 02: warnings counter, main baseline, amended requirements Summary

**`script/docs-report` now measures `mix docs` warnings (197 total, 2 in extras on main) with every failed or index-less run UNVERIFIED, the baseline is committed on a tree byte-equal to main before any doc edit, and DOCS-01/DOCS-02/SC1/SC2 state the amended decisions with the superseded clauses replaced in place.**

## Accomplishments

- Task 1 (tracer): parser written against a real `MIX_ENV=dev mix docs` capture (ex_doc 0.40.3). The real two-block fixture (one extras location, one lib location) yields exactly `total=2 extras=1`. A non-zero exit is `mix_docs_failed`, a missing `doc/index.html` is `no_doc_index`, a missing binary is `mix_docs_failed`; a zero-warning successful run is the only `total=0`. A CLI test puts a stub `mix` first on PATH. The workflow guard test reads every file under `.github/workflows/` (non-empty asserted) and has an injected-reference control. `script/docs-report` on the repo exits 0 with four lines in D-15 order.
- Task 2: baseline recorded on main `f842f28279aa0005d9305cac01afd25610036cf0`, branch HEAD `3b8ff2f7`, ex_doc 0.40.3: `docs.warnings total=197 extras=2`, `docs.links broken=0 checked=232 files=30`, `docs.leaks hits=95 allowlisted=0 stale_allowlist=0 files=30`. Precondition diff against `origin/main` exits 0. The DOCS-REPORT commit `1782366b` touches no README.md, CHANGELOG.md or guides/ file.
- Task 3: DOCS-01 and DOCS-02 carry dated amendment notes; the `shows the real published versions` and `matches the versions actually published on Hex` clauses are replaced in place; Phase 199 gains criterion 5 (`deferred=none`); STATE Decisions records the amendment.

## Task Commits

1. Task 1: warnings counter and not-in-CI guard: `3b8ff2f7` (feat)
2. Task 2: baseline on main-equal tree: `1782366b` (docs)
3. Task 3: amend DOCS-01, DOCS-02, SC1/SC2: `8e41045c` (docs)

## Verification Run

- `test/crosswake/docs_report_test.exs` through the gate: 38 tests, 0 failures, verdict PASS (floor 30).
- `test/crosswake/proof/absence_is_not_success_test.exs` through the gate: 59 tests, PASS.
- `mix format --check-formatted` clean on both Elixir files. `grep -rl "docs-report\|docs_report" .github/workflows` prints nothing (exit 1).
- Task 3 greps for both amendment notes, the Phase 199 `deferred=none` criterion, the STATE bullet and the removed/added clauses all exit 0. 15 plan files, 35 task blocks, 15 plans listed in the Phase 197 roadmap entry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's subprocess seam shape differed from the 197-01 seam**
- **Found during:** Task 1
- **Issue:** 197-01 shipped `run: &system_run/2` returning `{:ok, out} | {:error, atom}`; the plan needs `deps.run.("mix", ["docs"], opts)` returning `{output, exit}`.
- **Fix:** replaced it with `system_run/3` wrapping `System.cmd/3` (rescue returns `{"", 127}`); the shared test helper now defaults `run` to a quiet docs stand-in so no fixture test spawns the real `mix docs`. The first 197-01 leak test now asserts `docs.warnings total=0 extras=0` and exit 0 instead of the old `not_measured` line.
- **Files modified:** `script/docs_report.exs`, `test/crosswake/docs_report_test.exs`
- **Commit:** `3b8ff2f7`

**2. [Rule 3 - Blocking] Two Task 3 verify gates were written against the planning-time roadmap**
- **Found during:** Task 3 verify
- **Issue:** the 197-01 state update had already turned the progress row into `| 197. Public docs truth | 1/15 | In Progress | - |` and the `**Plans**` line into `1/15 plans executed, 35 tasks; ...`, so the literal `0/15` grep and the `**Plans**: <n> plans, <m> tasks;` awk could not match even though the facts they protect hold.
- **Fix:** verified the same facts directly: 15 plans listed, 15 `197-*-PLAN.md` files, 35 task blocks, 35 on the roadmap line, progress row 15 plans. The tool-maintained roadmap text was left as it is.
- **Commit:** none needed

**3. [Process] Edits applied with small Python replace scripts instead of Edit calls**
- Every replacement asserted exactly one match first; no other line of the three planning files changed (diffstat 6 insertions, 4 deletions).

## Notes

- Baseline versus D-19: warnings 197/2, TODO 6 and SEED 1 match exactly. `Phase N` (68), `D-NN` (9) and `vNN` (11) are occurrence counts; distinct (file, line) pairs are 43, 7 and 10, which equal D-19's figures. Documented in 197-DOCS-REPORT.md; the tool was not changed.
- Observed while comparing anchor slugs: existing links such as `#attach-first--push3-raises-on-a-socket-that-never-did` use the GitHub slug with a doubled hyphen and do not match ExDoc ids on HexDocs. Recorded in 197-DOCS-REPORT.md, not fixed (counted only this cycle).
- Task 1 found 197 warnings equal to D-19 on first run, so no tool adjustment was made.

## Known Stubs

None.

## Threat Flags

None. Evidence files contain counts and lines from the shipped public docs only.

## Self-Check: PASSED

- FOUND: script/docs_report.exs, test/crosswake/docs_report_test.exs, 197-DOCS-REPORT.md, both baseline evidence files
- FOUND commits: 3b8ff2f7, 1782366b, 8e41045c (ancestors of HEAD)
- `.planning/config.json` still shows an uncommitted modification and is in no commit.
