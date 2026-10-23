# Phase 185: Checks that cannot pass empty - Context

**Gathered:** 2026-10-16 (revised the same day after the fan-out review)
**Status:** Ready for planning

<domain>
## Phase Boundary

Every v25-era check that iterates or scans must fail loudly when its input is missing or empty, so a green result always means something was examined (GUARD-01, GUARD-02, GUARD-03). Concretely:

- `script/check_absence_is_not_success.exs` stops printing OK on a nonexistent root, an empty derived scope, or a scope below its pinned count.
- The v25 test loops the collection-assertion ledger does not scan are measured in report mode, and the one known unguarded loop (`twin_receipt_test.exs:289`) gets a non-empty floor.
- `TwinRuntime.stop_children/1` and `lock_digests/1` stop reporting success after observing nothing.

Out of scope: a repo-wide non-empty blocking rule (VACG-01), the ledger scaffolding sunset, any change to the twin receipt schema, and any twin run.

All product work happens in the candidate `/private/tmp/crosswake-phase180-impl`, which is on a detached HEAD at `b898e110` (`fix(184-14)`). Evidence goes in `/private/tmp/crosswake-phase180-run`. The recovery checkout stays at `d0f3e2f1` with nothing staged or committed.

</domain>

<decisions>
## Implementation Decisions

**How these were reached.** On 2026-10-16 the user accepted the first four recommendations as one set. They then asked for a fan-out review of every decision point and for the best recommendations to be followed without further questions. Four research agents worked read-only against the candidate at `b898e110`: the absence checker, the loop measurement, the twin cleanup semantics, and an adversarial review of the first draft. The decisions below are the synthesis, and they supersede the first draft. The rationale and evidence are in `185-DISCUSSION-LOG.md`. The governing principle: every guard needs a source of truth independent of the thing it guards, a red run before its fix, and a mutation control that reverts it. An error or count that nobody reads is itself an absence-scored-as-success risk, and is recorded as such.

### Absence checker (GUARD-01)
- **D-01: Two independent derivations plus a pin.** For each scope, `actual` is the `Path.wildcard` result filtered to regular files with `File.regular?`, so a directory named `x.exs` is not counted. `expected` is a separate walk of the same root filtered to the same suffix (`:filelib.fold_files/5` or an `File.ls!` walk), at the glob's own depth: recursive for `**` globs (test files, deferred-items), depth-1 for the depth-1 planning globs (`todos/*.md`, `seeds/*.md`), because GSD moves closed todos into `todos/pending/` and `todos/completed/` and a recursive walk would report a false proper subset. *(Walk-depth wording amended 2026-10-16 during planning; see 185-01.)* It is never a second call of the same wildcard, and never `git ls-files`: fixture roots are not git repos, and git's pathspec `*` crosses `/`.
  - Compare the two with an Elixir copy of `assertFullScope` (`scripts/ci_monitor.cjs:310-321`), with no shared module, no Node and no dependency. The reason strings are the same as in JS: `expected scope is empty` and `actual scope is a proper subset of expected scope`.
  - A comment notes the JS loophole (extras in `actual` are allowed) and says the regular-file filter is what closes it.
  - The walk includes dot-directories, so a test hidden in `test/.hid/` shows up as a proper subset.
  - Do not edit `scripts/ci_monitor.cjs`. The "second caller: Elixir copy, by design" note goes in the SEED-023 file under `.planning/seeds/` as a plain uncommitted planning edit.
- **D-02: Strict invocation, distinct exit codes.** Arguments are parsed strictly. Only `--root <dir>` and the test-only flag from D-03 are accepted. No argument at all means the current working directory, which is today's documented default and is kept.
  - Exit **2** for an unusable invocation, before anything is derived: a root that does not exist, a root that is not a directory, `--root` with no value, or an unknown argument. The message is `[crosswake] FAIL: root does not exist: <path>` or `is not a directory`, with the path expanded. This matches the repo's `0|1|2` convention (`verify_twin.ex`) and ESLint's exit 2 for "no files matching".
  - Exit **1** for scope failures and for findings. If any scope floor fails, the content checks are skipped and the output says so.
- **D-03: One `@scopes` table of pinned minimums.** Each entry is `{label, glob, min}` and is a literal in the script.
  - **Test files:** `min` is the count measured at Phase 185's **final** candidate commit, after the phase's own new test files land. Do not use the plan-time count; it was 249 at `b898e110`. The pin is a minimum (`>=`): adding files never goes red, and removing files is the reviewed event. A comment states the known limit: adding 50 files and deleting 50 others stays green.
  - **Planning scopes** (`.planning/todos/*.md`, `.planning/seeds/*.md`, `.planning/**/deferred-items.md`): `min` is **1** for each, checked separately. This meets the requirement's "pinned expected count" literally, with a pin of 1. Planning lifecycle is driven by GSD tooling outside this repo's code: GSD's own todo workflow moves closed todos into `todos/pending/` and `todos/completed/` (`gsd-core/workflows/check-todos.md:135`), so a measured pin would churn. A wrong root is already caught by the test-file pin.
  - A test-only flag, `--min-test-files N`, lets fixtures avoid 249 files. The "repository itself" test runs without it, and so proves the default pin.
  - No automatic ratchet. Raising the pin is a freeze-checklist item (Phase 188), recorded in Deferred.
- **D-04: Output keeps the existing phrases.** The two OK sentences that tests grep (`absence_is_not_success_test.exs:25-26`) stay word for word, with the counts added at the end.
  - Example: `...never verified (scanned 249 test files, pin 249; N shared helpers build a mutation).`
  - Example: `...to a real test (todos 12, seeds 23, deferred-items 11; M open citations checked).`
  - A failure line is `[crosswake] FAIL: scope <label>: <reason>: scanned=<n> expected=<m> pin=<p>`, followed by one hint sentence: lower that `@scopes` entry in the same change and say why, or fix `--root`. The hint never suggests a command that rewrites the pin.
- **D-05: Self-tests run as a real subprocess, from a green baseline.** They keep the existing `System.cmd("elixir", [@script, "--root", tmp])` shape and assert the exit code and the message. A `baseline!(tmp)` helper seeds one test file, one todo, one seed and one `deferred-items.md`, and fixtures run with `--min-test-files 1`. Every existing fixture moves onto the baseline, or all current tests would go red for the wrong reason.
  - Each red case changes exactly one thing from the baseline.
  - Root cases: a nonexistent root, a root that is a file, a bare `--root`, and an unknown flag (each exit 2).
  - Scope cases: an empty test scope; each planning glob empty (three cases); test count below the pin; a proper subset via a dot-directory test file; a directory named `x.exs` not counted.
  - The equal case passes.
  - The repository-itself test also proves the real counts meet the pins.
  - Each test name names the scope and floor type, so the verifier can map them to success criterion 1.

### v25 loop measurement and floors (GUARD-02)
- **D-06: The scope.** The headline scope is the 45 test files added or modified by v25 (phases 179–183), from `git diff --name-only --diff-filter=AM d0dbdf7 50fcd57 | grep '_test\.exs$'`. They are measured at the candidate HEAD, and the command and the count are recorded. Phase 184's later twin test files go in a separate, informational "Phase 184 supplement" section, which does not change the headline count. Loops written in v25 inside files v25 did not touch are out of scope, which is accepted.
- **D-07: Measure with a one-off AST scan, then classify each hit by hand.** A read-only scanner walks `Code.string_to_quoted/2` output and flags `for`, `Enum.each`, `Enum.reduce`, `Enum.map` and `Enum.flat_map` whose body contains `assert` or `refute`. It is kept with its output in the phase directory as evidence, and is not wired into CI.
  - The scanner asserts it found exactly 45 files, each of them present.
  - It prints a per-file site count, including zeros.
  - It must flag `twin_receipt_test.exs:289` before the fix, which proves it can see a real site.
  - The table header lists its blind spots: assertions in helpers called from a loop, `with`/`Stream`/`Enum.all?` shapes, filter-only bodies.
  - The research pass found about 94 sites. The committed scan is authoritative.
- **D-08: Table vocabulary reuses the ledger's buckets.** `185-LOOP-MEASUREMENT.md` uses `safe-by-construction`, `safe-guarded`, `safe-cardinality-pinned`, `safe-compile-time-literal` and `needs-fix`, plus a `disposition_basis` column (the guard's line, or the reason). A fixed row shows a before → after disposition. No new bucket enters the ledger.
- **D-09: Every runtime-derived `needs-fix` site in the 45 files is fixed in this phase.** GUARD-02 says loops "assert a non-empty collection before iterating", and these are local floors, not a repo-wide rule. The research pass found these, all inside the 45 files; the committed scan confirms or extends the list:
  - `twin_receipt_test.exs:289`;
  - `doctor/doctor_origin_mode_test.exs:360` (refute-only over a derived list);
  - `proof/phase64_runtime_line_policy_test.exs:412` and `:460` (they filter, then assert the same predicate);
  - `mix/tasks/crosswake_proof_lane_verify_twin_test.exs:582` and `:640` (refute-only; `lines` could be empty);
  - the scanner also re-checks `phase64_runtime_line_policy_test.exs:382`, `crosswake_gen_shell_host_test.exs:134` and `phase180_twin_feasibility_test.exs:47`.
  
  `doctor_test.exs:859` is deliberately conditional ("IF such findings appear"). Prefer making the condition explicit: if the fixture is meant to produce such findings, assert at least one. Only if it can legitimately be empty, record it as a `waived-by-design` row in the report, never in the ledger, with its basis. That is the only waiver allowed.
- **D-10: The strongest floor that holds.** Where a source of truth fixes the count, use it.
  - For `twin_receipt_test.exs:289`, inside the outer loop: `assert [_ | _] = g["sub_observations"]`, then `assert length(g["sub_observations"]) == expected[g["id"]]`, where `expected` is built from `TwinReceipt.roster/0`. The roster is a compile-time constant, a different code path from the projection.
  - Elsewhere, use an exact count where it is stable, and `assert [_ | _] =` otherwise. A floor always goes before the loop or at the head of its body, never after it.
- **D-11: Mutation controls that bite for the right reason.** Use the Phase 184 harness shape:
  - a throwaway copy of the candidate and a separate `MIX_BUILD_PATH`;
  - one `perl -0pi` edit, with sha256 before and after required to differ;
  - only the target test file run;
  - `control N: ... failed as expected in "<test>" (rc=… N tests, M failures)` lines in `mutation-185.log`;
  - no zero-test runs;
  - control 0 run unmutated and passing;
  - a sha256 manifest proving the real candidate is unchanged.
  
  For `:289`, mutate the projection in the temp copy so one group's `sub_observations` is `[]`. Do not mutate the test's input, which would trip `twin_receipt.ex:~586` for a different reason. The log must name the new floor assertion as the one that failed. A paired negative control (same mutation, floor reverted) must pass, which shows the floor is what catches it.
- **D-12: No repo-wide blocking rule.** None lands, even if the table ends at zero findings (SUMMARY C9, CHALLENGE K4). VACG-01 and the ledger-scaffolding sunset stay deferred.

### Twin cleanup that saw nothing (GUARD-03, `stop_children`)
- **D-13: `{:error, :registry_gone}`, detected without a race.** `stop_children/1` reads the registry inside `try do Agent.get(...) catch :exit, _ -> ... end`, instead of calling `Process.alive?` and then `Agent.get`. A dead registry returns `{:error, :registry_gone}`.
  - The registry is an unlinked `Agent.start` (`twin_runtime.ex:94`), and children are OS process groups that only it tracks. A gone registry therefore means children may be orphaned, and `:ok` would be a false success.
  - A live registry with zero children returns `:ok`.
  - The `@spec` of `stop_children/1` and `stop_all/1` becomes `:ok | {:error, :child_still_alive | :registry_gone}`.
  - `stop_all/1` always closes the origin listener, and tries `Agent.stop` inside `catch :exit`. It then returns the registry error, never short-circuiting.
  - `mark_exited/2` tolerates a registry that dies mid-stop the same way. `first_failure/1` and `record_failure/2` keep their documented tolerant behaviour, but switch from `Process.alive?` to `catch :exit`.
  - No "stopped" flag and no `start_link`. Calling stop twice is a bug signal, and Go, Rust and Python treat a double release as reportable.
- **D-14: Callers still don't act on it, but that is now pinned, not accidental.** `twin_journey.ex:745` (`finish/2`) and `verify_twin.ex:79` (`after`) keep their current verdict behaviour: mapping to `:cause_not_retained` would misexplain a leak, and changing the verdict is receipt-touching. One test kills the registry, then runs the finish/stop path, and asserts no raise and an unchanged verdict, so the discard is a visible, tested decision.
  - The planner enumerates the nine existing `:ok = stop_*` test sites, with their call order, before editing. Research found none that run after a previous stop.
  - Deferred records this as a known "error nobody reads" risk, with a reopen trigger.

### Lockfile count (GUARD-03, `lock_digests`)
- **D-15: All three lock sites require both lockfiles.**
  - (a) `twin_producers.ex:1469` `lock_digests/2` (source gate): drop the `File.stat` pre-filter and digest every entry of `@lock_rels` directly, which also removes a race between the stat and the read. Return `{:ok, digests}` only when every digest is `{:ok, _}`; otherwise return `{:blocked, :identity_unknown}`.
  - (b) **`lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:226` `lock_digests/1` (freeze side), the load-bearing site.** Today it keeps whichever lockfiles exist and fails only when none do, with the non-closed `{:error, :lock_files_missing}`. When the same file is missing at both freeze and observation, expected and observed are both `digest([a])`, and the join passes. Require both; a missing lockfile maps to the closed `:identity_unknown`, through the existing blocked-receipt path.
  - (c) The observation in `twin_producers.ex:~1598`: `locks` becomes `nil` unless both digests are present, and both `locks != []` gates (`dependency_lock` ~1609, `backend_build` ~1639) test it. A nil already reports as `identity_unknown` (`twin_receipt.ex:~505`).
  - `:identity_unknown`, not `:prerequisite_missing`: the preflight hint for it already says "a candidate with both lockfiles" (`twin_preflight.ex:~139-141`). No new cause atom, and the receipt stays `@schema_version 1`.
- **D-16: Tests through the public entry points, plus mutation controls.**
  - Use real temp candidates through `TwinProducers.source_gate`, and through the freeze path in `VerifyTwin` with injected producers.
  - Cases: root lockfile only, host lockfile only, on each side; an unreadable lockfile (chmod 000; skipped when running as root); a both-present control that stays green.
  - Recorded mutation reverts, each naming the failing test: (i) the dead-registry `else: []` / catch returning `[]`; (ii) `results == []` / `digests == []`; (iii) `locks != []`.

### Gates and conventions (carried from Phase 184)
- **D-17:** The gate conventions carry over from Phase 184.
  - Executor and verifier run on sonnet. Executors dispatch with isolation none, with `record-dispatch-isolation` written right before each dispatch.
  - Red runs come before every fix.
  - Full-suite runs are compared to the baseline (the only known failure is `phase180_twin_feasibility_test.exs:30`), and no two runs share a `MIX_BUILD_PATH`.
  - Regression gates also include the Phase 184 probe tests (`twin_source_probe_test.exs`, `twin_producers_test.exs`) and a read-only real-candidate source probe that shows all zeros. *(Amended 2026-10-16 during planning: the all-zero term is carried by `TwinProducers.probe_source` on a HEAD copy and on the committed candidate, the Phase 184 real-probe form. The `twin_preflight` command's four-line contract has no count field and, with no prepared record on the real candidate, stops before its source step; so it is also run read-only on the committed candidate and must report `result: blocked` with no run root created. See 185-05.)*
  - Before any fix, confirm that every `@scopes` glob is non-empty in the candidate (measured 249 / 12 / 23 / 11 at `b898e110`).
  - Phase 185 makes one candidate commit at the end, on top of `b898e110`, with the trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - No twin run, no Simulator, no xcodebuild, no twin-05; the push URL stays `no-push-phase180`.
  - Never pipe a gated check into `tail`.
  - A blocked plan writes `NN-BLOCKED.md`.
  - `mix crosswake.adoption_context.scan` is gated on its five known findings staying unchanged, not on exit 0.

### Claude's Discretion
- Exact wording of messages and hints, within D-04.
- The internal shape of the walk in D-01.
- The scanner's code, within D-07.
- Fixture layout.
- Plan split and wave order. The three requirements are independent (checker / loops / twin runtime and producers), and all three plans feed one final gates-and-commit plan.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and resolved decisions
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — GUARD-01..03 text, inclusion rule, candidate location
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §Phase 185 — goal and four success criteria
- `.planning/research/v26/SUMMARY.md` — resolved decisions (C9: no standing non-empty rule in v26), phase 185 row
- `.planning/research/v26/CHALLENGE.md` — C9 (checker vacuous on nonexistent root, verified), C11 (`stop_children` dead registry), R3 (`twin_receipt_test.exs:289` belongs in this phase), K4 (no VACG-01)
- `.planning/research/v26/STACK.md` §2 (v25 loop sites, idioms, mutation-control convention) and §3 (assertFullScope semantics, limits, Elixir copy sketch)
- `.planning/research/v26/FEATURES.md` §GUARD and DEF-JS — sweep of other SEED-023 candidates (no change needed elsewhere)
- `.planning/research/v26/PITFALLS.md` P-B — measure before blocking; self-referential cardinality is not a floor
- `.planning/research/v26/ARCHITECTURE.md` §Question 5 — `lock_digests` exact-count fix
- `.planning/seeds/SEED-023*.md`, `.planning/seeds/SEED-018*.md` — seed intent (SEED-018 limited to v25 code)

### Prior phase
- `.planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-CONTEXT.md` — D-01..D-42 probe decisions, gate conventions (mutation log, baseline comparison, one commit)
- `.planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-DISPOSITION.md` — open GAP4 items; none belong to this phase

### Project rules
- `AGENTS.md` — checkout rule, sensitive-data rules, zero-human verification, keep one-time checks as phase evidence rather than CI lanes

</canonical_refs>

<code_context>
## Existing Code Insights (candidate at `b898e110`)

### Reusable Assets
- `scripts/ci_monitor.cjs:310-321` `assertFullScope` and its self-test `testCheckActionsScope` (≈373-400): the semantics and test shape to copy.
- `script/check_exunit_ownership.exs:18-28`: an existing Elixir `if paths == [] do fail(...)` floor; the model shape.
- `test/crosswake/proof_lane/twin_producers_test.exs:364-370`: the pinned-count model (`assert length(backend) == 13`).
- `phase180_twin_feasibility_test.exs:38-58`: the `@tag phase180_gate` / `@tag phase180_control` sibling-control convention.

### Established Patterns
- `check_absence_is_not_success.exs` `run/1` (≈line 53) composes `mutation_controls(root) ++ stale_citations(root)`. Its scopes are bare `Path.wildcard` calls: `mutation_controls/1` around 76-82, and `stale_citations/1` around 175-186 with three globs. The entry point (≈329-335) parses `--root` and calls `System.halt(run(root))`.
- The checker runs only through `test/crosswake/proof/absence_is_not_success_test.exs` (in `mix test`). It is also mentioned in `script/inventory_collection_assertions.exs` comments. No CI lane runs it as a script, and none is added.
- `twin_runtime.ex:227-243`: `stop_children/1` defaults to `[]` for a dead registry, then `Enum.all?([])` returns true, so it returns `:ok`. `stop_all/1` calls it, then closes the origin listener and stops the Agent.
- `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:213-236`: `freeze/1` and its own `lock_digests/1` (lstat + regular filter, `digests == []` only, `{:error, :lock_files_missing}`), the freeze-side lock site.
- `twin_producers.ex:619`: `@lock_rels`. `:1469` `lock_digests/2` filters by `File.stat` and blocks only when the result is empty. `:715` is its only caller, in the source gate. `:1598`/`:1609`/`:1639`: observation repeats the narrowing with `locks != []`.
- `twin_receipt_test.exs:283-292`: the outer groups loop is pinned (`length == 10`, ids T01..T10). The inner `sub_observations` loop is not.

### Integration Points
- `twin_journey.ex:745` (`finish/2`) and `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:79` (`after`) call stop functions and discard the result. Their verdict behaviour is left unchanged and pinned by a test (D-14).
- `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` (≈152-548) and `test/crosswake/proof_lane/twin_runtime_check_test.exs` (≈118-163) assert `:ok = stop_all/stop_children`. Check each for a dead-registry call order.

</code_context>

<specifics>
## Specific Ideas

- Every guard here needs a red run before its fix and a mutation control that reverts it. "The test passes" is not evidence that the guard bites.
- The pinned test-file count must come from a measurement taken at the final candidate commit (D-03), never from a number derived by the same glob at check time. A self-referential count cannot fail (PITFALLS P-B).
- The entry point also falls back to the current directory for an unrecognised argument today (`_ -> File.cwd!()`), so a typo such as `--rot /x` scans the wrong tree and passes. D-02's strict parsing closes this.

</specifics>

<deferred>
## Deferred Ideas

- **A stop failure changes the run verdict:** feed a non-`:ok` `stop_children`/`stop_all` result from `twin_journey.ex:745` and `verify_twin.ex:79` into the twin verdict, with an honest cause.
  - Until then, the error is unread by design, and that is a known absence-scored-as-success risk that D-14 pins with a test.
  - Reopen trigger: the next twin-touching change that already changes the cause list or receipt (Phase 188 or later), or any run that leaves a process behind.
- **Registry ownership through `start_link` or a monitor:** only if orphaned children are ever observed.
- **Raising the test-file pin:** a Phase 188 freeze-checklist item. Compare the scanned count with the pin and raise the pin in a reviewed edit.
- **VACG-01:** a repo-wide merge-blocking non-empty rule, plus the ledger-scaffolding sunset (`inventory_collection_assertions.exs`, both JSONs, the phase170 ledger test).
  - Reopen trigger: a milestone that scopes it, with a whole-tree measurement showing zero findings.
- **The scanner's blind spots (D-07):** loops whose assertions live in helpers, and `with`/`Stream`/`Enum.all?` shapes. Reopen with VACG-01.
- **`strip_heredocs` in the absence checker:** it toggles on any line containing `"""`, so an odd number of fences blanks the rest of a file. This is a pre-existing fragility, not a v25 path. Reopen if a finding is ever missed in a file with unbalanced fences.
- **SEED-023 sites not read** (`script/verify_hex_tarball.sh`, `script/list_merge_blocking_checks.py`, `script/phase_evidence_path.py`): not v25 code. Reopen when a later milestone sweeps non-v25 scanners.
- **`twin_journey.ex:150-163` scope mismatch:** the residue check searches only `*.xcresult`, while cleanup removes eight patterns. Noted only; it is not a green-on-nothing path.

</deferred>

---

*Phase: 185-checks-that-cannot-pass-empty*
*Context gathered: 2026-10-16*
