# Phase 185: Checks that cannot pass empty - Research

**Researched:** 2026-10-16
**Domain:** Elixir test-suite and script hygiene (fail-closed scope checks, loop floors, twin runtime cleanup and lockfile identity). No external packages.
**Confidence:** HIGH for code locations, current behaviour and test impact (all read or run in the candidate this session). MEDIUM for the loop triage of the roughly 30 runtime-sourced sites (hand-read, but final classification belongs to the committed scanner run).

All code was read in the candidate `/private/tmp/crosswake-phase180-impl` at `b898e1104b0feafdb569d1ae42972cb4e1c46629` (`git rev-parse HEAD` this session; `git status --short` empty). Nothing was written there. Scratch files (scanner prototype, fixture) live only in the session scratchpad.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01 .. D-17 in `185-CONTEXT.md` are LOCKED. Research below implements them; it does not re-open them. Summary of what each locks, so the planner can cite without re-reading:

- **D-01** Two independent derivations plus a pin. `actual` = `Path.wildcard` filtered with `File.regular?`; `expected` = separate recursive walk (`:filelib.fold_files/5` or `File.ls` walk), never the same wildcard twice, never `git ls-files`. Elixir copy of `assertFullScope` (`scripts/ci_monitor.cjs:310-321`), reason strings `expected scope is empty` and `actual scope is a proper subset of expected scope`. Walk includes dot-directories. Do NOT edit `scripts/ci_monitor.cjs`; the "second caller: Elixir copy, by design" note goes in the SEED-023 file as a plain uncommitted planning edit.
- **D-02** Strict argv. Only `--root <dir>` and `--min-test-files N`. No argument = cwd. Exit **2** for unusable invocation (root missing, root not a directory, `--root` without value, unknown argument) before anything is derived; exit **1** for scope failures and findings; scope failure skips content checks and says so.
- **D-03** One `@scopes` table `{label, glob, min}`. Test files: `min` = count measured at Phase 185's FINAL candidate commit (not 249 unless no test file is added). Planning scopes (todos, seeds, deferred-items): `min` 1 each, separate. Test-only flag `--min-test-files N`. No auto-ratchet.
- **D-04** Keep the two OK sentences word for word, append counts. Failure line `[crosswake] FAIL: scope <label>: <reason>: scanned=<n> expected=<m> pin=<p>` plus one hint sentence that never suggests a command that rewrites the pin.
- **D-05** Self-tests stay real subprocesses (`System.cmd("elixir", [@script, "--root", tmp])`). `baseline!(tmp)` seeds one test file, one todo, one seed, one `deferred-items.md`; fixtures run with `--min-test-files 1`. Each red case changes exactly one thing. Root cases (4, each exit 2); scope cases (empty test scope; each planning glob empty x3; below pin; dot-dir proper subset; directory named `x.exs` not counted); equal case passes; repository-itself test proves real counts meet pins. Test names name the scope and floor type.
- **D-06** Headline scope = the 45 v25 test files from `git diff --name-only --diff-filter=AM d0dbdf7 50fcd57 | grep '_test\.exs$'`, measured at candidate HEAD; Phase 184 files go in a separate informational supplement.
- **D-07** One-off AST scanner (`Code.string_to_quoted/2`), flags `for`, `Enum.each/reduce/map/flat_map` whose body has `assert`/`refute`; kept with its output in the phase dir, not wired into CI; asserts exactly 45 files present; prints per-file count including zeros; must flag `twin_receipt_test.exs:289` before the fix; header lists blind spots.
- **D-08** `185-LOOP-MEASUREMENT.md` reuses ledger buckets `safe-by-construction`, `safe-guarded`, `safe-cardinality-pinned`, `safe-compile-time-literal`, `needs-fix`, plus `disposition_basis`; a before to after row. No new bucket in the ledger.
- **D-09** Every runtime-derived `needs-fix` site in the 45 files is fixed in this phase. `doctor_test.exs:859` is the only allowed `waived-by-design` (report only, never the ledger).
- **D-10** Strongest floor that holds. For `twin_receipt_test.exs:289`: `assert [_ | _] = g["sub_observations"]` then `assert length(g["sub_observations"]) == expected[g["id"]]` where `expected` is built from `TwinReceipt.roster/0`. Floor goes before the loop or at the head of its body.
- **D-11** Mutation controls in the Phase 184 shape (throwaway copy, separate `MIX_BUILD_PATH`, one `perl -0pi`, sha256 before/after must differ, only the target test file, `control N: ... failed as expected in "<test>" (rc=... N tests, M failures)` lines in `mutation-185.log`, no zero-test runs, control 0 unmutated passing, sha256 manifest proving the real candidate unchanged). For `:289` mutate the PROJECTION in the temp copy so one group's `sub_observations` is `[]`, not the test input. Paired negative control (same mutation, floor reverted) must pass.
- **D-12** No repo-wide blocking rule lands, even at zero findings.
- **D-13** `stop_children/1` returns `{:error, :registry_gone}`, detected via `try Agent.get ... catch :exit` (no `Process.alive?` then `Agent.get` race). Live registry with zero children returns `:ok`. `@spec` of `stop_children/1` and `stop_all/1` becomes `:ok | {:error, :child_still_alive | :registry_gone}`. `stop_all/1` always closes the origin listener, tries `Agent.stop` inside `catch :exit`, then returns the registry error. `mark_exited/2` tolerates a registry dying mid-stop. `first_failure/1` and `record_failure/2` keep tolerant behaviour but switch from `Process.alive?` to `catch :exit`. No "stopped" flag, no `start_link`.
- **D-14** Callers still discard the result (`twin_journey.ex:745`, `verify_twin.ex:79`); one test pins that. Planner enumerates the nine `:ok = stop_*` test sites with call order first.
- **D-15** All three lock sites require both lockfiles: (a) `twin_producers.ex:1469` `lock_digests/2` drops the `File.stat` pre-filter and returns `{:ok, digests}` only when every digest is `{:ok, _}` else `{:blocked, :identity_unknown}`; (b) `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:226` `lock_digests/1` (freeze side, load-bearing) requires both, missing maps to closed `:identity_unknown` via the blocked-receipt path; (c) `twin_producers.ex:~1598` observation `locks` becomes `nil` unless both digests present, both `locks != []` gates (~1609, ~1639) test it. No new cause atom, receipt stays `@schema_version 1`.
- **D-16** Tests through public entry points (`TwinProducers.source_gate`, freeze path in `VerifyTwin` with injected producers) on real temp candidates. Cases: root-only, host-only on each side; unreadable lockfile (chmod 000, skipped as root); both-present control. Recorded mutation reverts naming the failing test: (i) dead-registry `else: []` / catch returning `[]`; (ii) `results == []` / `digests == []`; (iii) `locks != []`.
- **D-17** Phase 184 gate conventions: sonnet executor/verifier, `record-dispatch-isolation` before each dispatch, red runs before fixes, full-suite compared to baseline (only known failure `phase180_twin_feasibility_test.exs:30`), no two runs share a `MIX_BUILD_PATH`, regression gates include `twin_source_probe_test.exs`, `twin_producers_test.exs` and a read-only real-candidate preflight showing all zeros, confirm every `@scopes` glob non-empty before any fix (249 / 12 / 23 / 11), ONE candidate commit at the end on top of `b898e110` with trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no twin run / Simulator / xcodebuild / twin-05, push URL stays `no-push-phase180`, never pipe a gated check into `tail`, blocked plan writes `NN-BLOCKED.md`, `mix crosswake.adoption_context.scan` gated on its five known findings unchanged (not exit 0).

### Claude's Discretion
- Exact wording of messages and hints, within D-04.
- The internal shape of the walk in D-01.
- The scanner's code, within D-07.
- Fixture layout.
- Plan split and wave order (three independent requirements; all three feed one final gates-and-commit plan).

### Deferred Ideas (OUT OF SCOPE)
- A stop failure changing the run verdict (feeding non-`:ok` `stop_children`/`stop_all` into the twin verdict); reopen on the next twin-touching change that alters the cause list or receipt (Phase 188+) or a run that leaves a process behind.
- Registry ownership via `start_link` or a monitor.
- Raising the test-file pin (Phase 188 freeze-checklist item).
- VACG-01 repo-wide merge-blocking non-empty rule and the ledger-scaffolding sunset.
- Scanner blind spots (helper-asserted loops, `with`/`Stream`/`Enum.all?` shapes).
- `strip_heredocs` fragility in the absence checker.
- SEED-023 sites not read (`script/verify_hex_tarball.sh`, `script/list_merge_blocking_checks.py`, `script/phase_evidence_path.py`).
- `twin_journey.ex:150-163` residue-scope mismatch.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GUARD-01 | `script/check_absence_is_not_success.exs` exits non-zero on nonexistent root / empty derived scope / below pinned count, via an Elixir copy of `assertFullScope`, no shared module, no new dependency | Sections "Checker (GUARD-01)": current code, verbatim `assertFullScope`, Elixir copy, glob-versus-walk behaviours verified by running, strict argv, test rewrite plan |
| GUARD-02 | v25 loops not covered by the ledger assert a non-empty collection before iterating (`twin_receipt_test.exs:289`); report-mode table records each site and its disposition | Sections "Loop measurement (GUARD-02)": scanner design and prototype results (45 files, 96 hits), per-site triage, mutation recipe for `:289` |
| GUARD-03 | `TwinRuntime.stop_children/1` errors when registry gone; `lock_digests/1` fails closed unless both lockfiles digested | Sections "Twin cleanup and lockfiles (GUARD-03)": exact current code, all callers, nine test sites, test-fixture fallout of requiring both lockfiles |
</phase_requirements>

## Summary

The three requirements are independent and small in production code (one script, one lib module with two helper tweaks, three lock sites) but wide in test fallout. Four findings change planning materially and are not in CONTEXT:

1. **Requiring both lockfiles at the freeze side turns about 20 tests red for a fixture reason.** `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:25` builds its candidate with only a root `mix.lock`. Every test that runs `VerifyTwin.execute` with injected producers reaches `freeze/1` and would block with `identity_unknown`. The setup must also write `examples/phoenix_host/mix.lock`, and the three git-fixture tests (`git add mix.lock` at ~564, 606, 626) must also add the host lock, otherwise it is an untracked file and the typed dirty count changes from 1 to 2.
2. **The loop population is bigger than D-09's list.** A prototype AST scan of the exact 45 files finds 96 loop-with-assert sites; 52 iterate a literal, 14 a syntactically non-empty list expression, and 30 a runtime-sourced collection. Hand-triage of those 30 gives the D-09 sites plus a few more genuine floors (see the triage table). `needs-fix` list is therefore: `twin_receipt_test.exs:289`, `:110` (`TwinReceipt.identity_joins()`), `doctor_origin_mode_test.exs:360`, `phase64_runtime_line_policy_test.exs:416` and `:460`, `crosswake_proof_lane_verify_twin_test.exs:640`, `crosswake_gen_shell_origin_mode_test.exs:99` and `:336`, and (floor-after-loop, judgement) `examples/.../phase180_twin_feasibility_test.exs:47`. `doctor_test.exs:859` is the one waiver.
3. **D-14's journey half cannot be tested by running the journey.** `TwinJourney.finish/2` is private and only reachable through a real Simulator run, which is forbidden. Pin the discarded result with a source-reading test (the repo already does this at `twin_journey_test.exs:159`) and pin the `VerifyTwin` `after` half behaviourally.
4. **Ledger drift.** `script/inventory_collection_assertions.exs --check` compares full rows including `display` (`file:line`). Editing files that hold ledger rows and shift line numbers (`phase64_runtime_line_policy_test.exs` row at `:596`, `twin_producers_test.exs` rows at `:80`/`:265`, `crosswake_proof_lane_verify_twin_test.exs` rows at `:269`/`:294`/`:338`) makes `--check` fail until `--emit-snapshot` regenerates the ledger. One plan must own that regeneration and verify the diff is display-only.

**Primary recommendation:** Execute as two parallel waves of independent plans (checker; loops; twin runtime and locks) feeding one final plan that owns ledger regeneration, the pin literal, the mutation log, the full-suite baseline comparison and the single commit. Give `crosswake_proof_lane_verify_twin_test.exs` to exactly one plan (the twin plan) and route the `:640` floor through it.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scope-floor checking for the absence checker | Repo script (`script/*.exs`, run as a subprocess by an ExUnit test) | none | No CI lane runs it directly; the only runner is `absence_is_not_success_test.exs` in `mix test` [VERIFIED: grep of repo, see Sources] |
| Loop floors | Test layer (ExUnit files) | none | Assertions live in the tests themselves; no lib change |
| Twin registry teardown result | Library (`lib/crosswake/proof_lane/twin_runtime.ex`) | Mix task and journey callers (unchanged verdict) | Registry is the only tracker of OS process groups |
| Lockfile identity (freeze) | Mix task `crosswake.proof_lane.verify_twin` freeze path | `TwinProducers.freeze/3` source gate | Two separate freeze paths exist (injected-producer path and real journey path) |
| Lockfile identity (observation) | `TwinProducers.observe_identities/3` | `TwinReceipt` (nil join becomes `identity_unknown`) | Join absence is the existing blocked signal |

## Standard Stack

No external packages are installed or added (GUARD-01 forbids a new dependency; GUARD-02/03 touch only existing modules).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5-otp-27 [VERIFIED: `.tool-versions` in candidate, `elixir --version` run in candidate] | script and test runtime | pinned by `.tool-versions` |
| ExUnit | bundled | tests and `@tag :tmp_dir` | all existing tests use it |
| `Code.string_to_quoted/2`, `Macro.prewalk/3` | stdlib | the one-off loop scanner | no dependency |
| `:filelib.fold_files/5` | OTP stdlib | independent recursive walk (D-01) | verified below to include dot-dirs and regular files only |

### Package Legitimacy Audit
No external packages are recommended; `package-legitimacy` was not needed. **Packages removed due to [SLOP] verdict:** none. **Packages flagged [SUS]:** none.

### Environment trap: asdf shim
`elixir` is an asdf shim that resolves the version from `.tool-versions` in the current directory. Run from `/tmp` or from the scratchpad it fails with exit **126** ("No version is set for command elixir"). Always `cd` into the candidate (or another directory with a `.tool-versions`) first. This also explains why a naive "run the script from elsewhere" probe appears to "exit non-zero for a bad root" for the wrong reason. [VERIFIED: reproduced this session]

## Architecture Patterns

### System Architecture Diagram (data flow for the three changes)

```
GUARD-01  argv --> strict parse --[bad]--> exit 2 (FAIL: root does not exist / not a directory / unknown arg)
                      |
                      v ok
              for each @scopes {label, glob, min}:
                 actual   = Path.wildcard(root/glob) |> filter File.regular?
                 expected = independent recursive walk (dot-dirs included, regular files, same suffix/basename)
                 assert_full_scope(actual, expected)  --[empty / proper subset]--> scope FAIL
                 length(actual) >= min                --[below pin]-------------> scope FAIL
                      |
        any scope FAIL --> print FAIL lines + "content checks skipped" --> exit 1
                      |
                      v all scopes ok
        mutation_controls ++ stale_citations --> findings? --> exit 1 : print OK lines WITH counts, exit 0

GUARD-03 stop   TwinRuntime.stop_children(runtime)
                    Agent.get(registry) --catch :exit--> {:error, :registry_gone}
                    ok -> terminate each child -> :ok | {:error, :child_still_alive}
                stop_all: stop_children -> close origin listener -> try Agent.stop catch :exit -> return first result
                callers (twin_journey finish/2, verify_twin after) DISCARD the result (pinned by a test)

GUARD-03 locks  freeze (verify_twin freeze/1) --lock_digests/1--> both lstat-regular + readable? --no--> {:blocked, :identity_unknown}
                freeze (journey path) TwinProducers.source_gate -> lock_digests/2 -> every @lock_rels digest {:ok,_}? --no--> {:blocked, :identity_unknown}
                observe_identities: locks = list of both digests or nil; dependency_lock and backend_build joins need non-nil locks
                nil join --> TwinReceipt blocked identity_unknown (twin_receipt.ex:505-537)
```

### Recommended file ownership

```
script/check_absence_is_not_success.exs                       # plan A
test/crosswake/proof/absence_is_not_success_test.exs          # plan A
.planning/seeds/SEED-023-extend-scope-cardinality-gate.md     # plan A (planning checkout, uncommitted note)
lib/crosswake/proof_lane/twin_runtime.ex                      # plan B
lib/crosswake/proof_lane/twin_producers.ex                    # plan B
lib/mix/tasks/crosswake.proof_lane.verify_twin.ex             # plan B
test/crosswake/proof_lane/twin_runtime_check_test.exs         # plan B
test/crosswake/proof_lane/twin_producers_test.exs             # plan B
test/crosswake/proof_lane/twin_journey_test.exs               # plan B (source-pin test)
test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs      # plan B (setup + lock tests + the :640 floor)
test/crosswake/proof_lane/twin_receipt_test.exs               # plan C
test/crosswake/doctor/doctor_origin_mode_test.exs             # plan C
test/crosswake/proof/phase64_runtime_line_policy_test.exs     # plan C
test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs       # plan C
examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs  # plan C
185-LOOP-MEASUREMENT.md + scanner + scan output (phase dir)   # plan C
script/collection_assertion_ledger.json, mutation-185.log, pin literal check, commit  # plan D
```

### Pattern 1: independent-derivation floor (GUARD-01)

**What:** `actual` and `expected` come from different traversal mechanisms; the pin is a literal. Comparison is a faithful Elixir copy of the JS guard.

Verbatim JS source (`scripts/ci_monitor.cjs:310-321`) [VERIFIED: read this session]:

```js
function assertFullScope(actual, expected) {
  if (expected.length === 0) {
    return { ok: false, reason: "expected scope is empty" };
  }
  const expectedSet = new Set(expected);
  const isSubset = actual.every((file) => expectedSet.has(file));
  const isProperSubset = isSubset && actual.length < expected.length;
  if (isProperSubset) {
    return { ok: false, reason: "actual scope is a proper subset of expected scope" };
  }
  return { ok: true };
}
```

Reason strings (verbatim): `expected scope is empty`, `actual scope is a proper subset of expected scope`. The loophole: if `actual` holds an element not in `expected` then `isSubset` is false and the result is `ok: true`, so extras are allowed. The JS self-test (`testCheckActionsScope`, lines 373-400 area) drives a narrowed case red and an equal control green; the Elixir tests mirror that through the subprocess.

Elixir copy (sketch, within Claude's discretion on naming):

```elixir
# Elixir copy of assertFullScope (scripts/ci_monitor.cjs:310-321). Same reasons, same semantics,
# including the JS loophole: extras in `actual` are allowed because `isSubset` is then false.
# The File.regular? filter on `actual` is what closes that hole for this checker, since a
# directory named x.exs is the only way `actual` could hold something `expected` does not.
defp assert_full_scope(_actual, []), do: {:error, "expected scope is empty"}

defp assert_full_scope(actual, expected) do
  expected_set = MapSet.new(expected)
  subset? = Enum.all?(actual, &MapSet.member?(expected_set, &1))

  if subset? and length(actual) < length(expected),
    do: {:error, "actual scope is a proper subset of expected scope"},
    else: :ok
end
```

Note `Enum.all?(actual, ...)` over an empty `actual` is true (vacuous): empty `actual` with non-empty `expected` therefore correctly reports "proper subset". This is the one place the vacuous `all?` is load-bearing and intentional; put a comment on it. (The repo's ledger scans only `assert/refute Enum.all?` in tests, so this lib/script use is not a ledger site.)

### Pattern 2: loop floor with an independent source of truth (GUARD-02, D-10)

For `twin_receipt_test.exs:289` the roster is a compile-time attribute (`@roster`), exposed by `TwinReceipt.roster/0` [VERIFIED: `lib/crosswake/proof_lane/twin_receipt.ex:150-168`]. Per-group counts T01..T10 = 4,5,3,7,4,5,5,3,5,8 (total 49, matches the brief). Sketch:

```elixir
expected_counts = Map.new(TwinReceipt.roster(), &{&1.id, length(&1.sub_observations)})

for g <- decoded["groups"] do
  assert g |> Map.keys() |> Enum.sort() == ["id", "status", "sub_observations"]
  assert [_ | _] = g["sub_observations"]
  assert length(g["sub_observations"]) == Map.fetch!(expected_counts, g["id"])

  for e <- g["sub_observations"] do
    assert e |> Map.keys() |> Enum.sort() == ["cause", "id", "outcome", "owner"]
  end
end
```

Caveat to record honestly in the measurement table: `TwinReceipt.project/2` builds `groups` from `receipt.groups`, and `receipt.groups` also derive from the roster. The independence is between the projection code path (`project/2`, `twin_receipt.ex:389-430`) and the compile-time constant, not between two unrelated data sources. That is still enough to catch a projection that drops sub-observations, which is exactly the mutation in D-11.

### Anti-Patterns to Avoid
- **Second call of the same wildcard as `expected`:** self-referential, cannot fail (PITFALLS P-B).
- **Recursive walk for the single-level planning globs:** `.planning/todos/*.md` and `.planning/seeds/*.md` are depth-1 globs. A recursive `expected` walk would count `todos/pending/*.md` or `todos/completed/*.md` (GSD moves closed todos there per CONTEXT D-03) that `actual` cannot see, producing a false "proper subset" red. Use a depth-1 `File.ls` listing filtered to regular `*.md` for those two scopes. Only the `test/**/*.exs` scope and the `deferred-items.md` scope are recursive. [VERIFIED: glob depth in current script; no nested dirs exist today: `ls -d .planning/todos/*/ .planning/seeds/*/` found none]
- **`assert Enum.all?(` in any new test line:** Phase 184's gate rejects added lines matching `^\+.*(assert|refute)[[:space:]]+Enum\.(all|any)\?\(` in the test diff (`184-14-PLAN.md` automated verify), and the ledger would gain unclassified rows. Use `assert [_ | _] = x`, `length/1` comparisons, or `Enum.each` with a preceding floor.
- **Mutating the test's input for the `:289` control:** trips `twin_receipt.ex` validation (`group_ok` at ~578-590, `TW-RCPT-SUBS`) for a different reason; mutate `project/2` instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recursive file walk | custom recursion with symlink handling | `:filelib.fold_files(dir_charlist, ~c".*\\.exs$", true, fun, [])` | Verified: includes dot-dirs, returns regular files only (skips a directory named `dir.exs`). Needs charlists. |
| Mutation harness | new bespoke harness | copy `/private/tmp/crosswake-phase180-run/mutate-184-13.sh` (rsync copy excluding `.git`, `apply()` with sha before/after, `touch_file`/`restore_all`, `totals`, `has_header`) | Already proven across 184-07..14; D-11 says use this shape |
| Ledger regeneration | hand-edit JSON | `elixir script/inventory_collection_assertions.exs --emit-snapshot` then `--check` | Rows are keyed by hash of `{enclosing, expression, ordinal}`; `display` carries the line, so only `display` changes on a pure shift |
| AST traversal | regex over source text | `Code.string_to_quoted!/2` + `Macro.prewalk/3` | `for` bodies, pipes, multi-line forms |
| Registry liveness | `Process.alive?` then `Agent.get` | `try ... catch :exit, _ ->` | The check-then-act race is exactly the D-13 defect class |

**Key insight:** every guard in this phase needs a source of truth independent of the thing it guards. Where none exists (an arbitrary runtime list), the honest floor is `[_ | _]` and the measurement table says so.

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted per template.

## Checker (GUARD-01)

### Current behaviour (verified by running)
Run from the candidate directory against bad invocations [VERIFIED: `elixir script/check_absence_is_not_success.exs --root /nonexistent-xyz` etc.]:

| Invocation | Output | Exit |
|---|---|---|
| `--root /nonexistent-xyz` | both OK lines | **0** |
| `--root` (no value) | both OK lines (falls back to `File.cwd!()`) | **0** |
| `--bogus` | both OK lines (falls back to `File.cwd!()`) | **0** |

Entry point (verbatim, `script/check_absence_is_not_success.exs`, end of file) [VERIFIED: read]:

```elixir
root =
  case System.argv() do
    ["--root", path | _] -> path
    _ -> File.cwd!()
  end

System.halt(Crosswake.AbsenceIsNotSuccess.run(root))
```

`run/1` composes `mutation_controls(root) ++ stale_citations(root)`; the OK lines printed are exactly:

```
[crosswake] OK: no mutation control asserts a change it never verified.
[crosswake] OK: every open finding's test citation resolves to a real test.
```

The scopes are bare `Path.wildcard` calls: `Path.join(root, "test/**/*.exs")` in `mutation_controls/1` and, in `stale_citations/1`, `.planning/todos/*.md`, `.planning/seeds/*.md`, `.planning/**/deferred-items.md`. `stale_citations` unions them with `Enum.uniq`.

### Glob versus walk (verified on a fixture: `test/a_test.exs`, `test/.hid/h_test.exs`, `test/dir.exs/` (a directory), `test/ok/b_test.exs`)
- `Path.wildcard("test/**/*.exs")` returns `a_test.exs`, **`dir.exs`** (the directory), `ok/b_test.exs`; it **skips** `.hid/h_test.exs`.
- `Enum.filter(&File.regular?/1)` drops `dir.exs`.
- `:filelib.fold_files(~c"test", ~c".*\\.exs$", true, ...)` returns `.hid/h_test.exs`, `a_test.exs`, `ok/b_test.exs` (dot-dirs included, directory excluded).
- `Path.wildcard(..., match_dot: true)` includes `.hid` and `dir.exs`.
So `expected - actual` is exactly the dot-directory files (the proper-subset case), and D-01's `File.regular?` filter is what keeps a directory named `x.exs` from being counted in `actual`. Both claims are `[VERIFIED: ran in candidate, fixture in session scratchpad]`.

### Measured counts in the candidate (at `b898e110`)
`{249, 12, 23, 11}` for test files, todos, seeds, deferred-items; 249 regular files; fold_files also 249; no dot-dir test files; 11 `deferred-items.md` and none under a dot-dir. [VERIFIED: ran]. The count for the test pin must be re-measured at the final commit; if no plan adds a test FILE (all new tests go into existing files, as recommended below) the pin stays 249.

### Walk specifics per scope (so `expected` is independent but comparable)
| Scope | actual | expected (independent) | Why |
|---|---|---|---|
| `test/**/*.exs` | wildcard filtered `File.regular?` | `:filelib.fold_files` on `root/test`, regex `.*\.exs$`, recursive | recursion matches `**`; includes dot-dirs |
| `.planning/todos/*.md` | wildcard filtered | `File.ls(root/.planning/todos)` filtered to `.md` and `File.regular?` (depth 1 only) | glob is depth 1 |
| `.planning/seeds/*.md` | same | same on seeds | same |
| `.planning/**/deferred-items.md` | wildcard filtered | recursive walk of `root/.planning`, basename equal to `deferred-items.md`, dot-dirs included | `**` skips dot-dirs; basename equality, not suffix |

The planning min is **1** (D-03), so for those scopes `assert_full_scope` plus `length(actual) >= 1` is the whole contract.

### Strict argv (D-02) implementation notes
- Use `OptionParser.parse(argv, strict: [root: :string, min_test_files: :integer])` or a hand-rolled head-match; any `invalid`/`rest` entry means exit 2. `--root` with no value: `OptionParser` reports it as invalid with `strict`, so exit 2 holds. A non-integer `--min-test-files` is also exit 2.
- Root checks: `File.exists?` false gives `[crosswake] FAIL: root does not exist: <Path.expand(path)>`; exists but `not File.dir?` gives `... is not a directory`. Both exit 2 (the repo's `0|1|2` convention is in `verify_twin.ex` `exit_status_for` docs: "Maps a status or unknown rule id to the exit status (0, 1 or 2)" [VERIFIED: read]).
- Exit through `System.halt(code)` as today.
- Content checks must be skipped when any scope fails (D-02) and the output must say so, so a failing scope never reads as "no findings".
- OK lines keep the two sentences verbatim and append counts (D-04), e.g. `... never verified (scanned 249 test files, pin 249; N shared helpers build a mutation).` The existing test greps `"no mutation control asserts a change it never verified"` and `"every open finding's test citation resolves to a real test"` (`absence_is_not_success_test.exs:25-26`) [VERIFIED: read]; both substrings survive if the counts come after the sentence body, and the trailing period handling must be checked (the current line ends `...verified.`; D-04's example puts the counts before the period: `verified (scanned ...).`, which still contains the grepped substring).

### Test rewrite plan (existing file `test/crosswake/proof/absence_is_not_success_test.exs`)
Read in full this session. Facts the planner needs:
- `run/1` helper: `System.cmd("elixir", [@script, "--root", Path.expand(root)], stderr_to_stdout: true, cd: @repo_root)`. The `cd: @repo_root` is what gives the shim a `.tool-versions`; keep it.
- Existing fixtures write only a `test/sample_test.exs` or `test/cited_test.exs` and optionally one `.planning/todos/TODO-999-sample.md`. Under the new floors every one of them would fail on empty seeds/deferred scopes, so all must move onto `baseline!(tmp)` (D-05) and run with `--min-test-files 1`. The repository-itself test must stay flagless (it proves the real pin).
- `write_todo!` writes `.planning/todos/TODO-999-sample.md`; `baseline!` should write a differently named todo (or the same helper with a no-citation body) so both can coexist without overwriting.
- Existing 9 tests (1 repo-itself, 3 mutation-control, 6 citation: count them as 1 + 3 + 6 = 10 `test` blocks) stay green after the baseline move; the new red cases are additions (4 root, 1 empty test scope, 3 empty planning scopes, 1 below pin, 1 dot-dir subset, 1 directory-named-`x.exs`, 1 equal case; about 11 to 12 new tests).
- Scope-failure case for "dot-directory proper subset": put an extra `test/.hid/h_test.exs` beside the baseline file; `actual` = baseline file only, `expected` = baseline + hidden, so it is a proper subset and fails (exit 1). Do not combine with any other change.
- "directory named `x.exs` not counted": create `test/x.exs/` (a directory) and run with `--min-test-files 2`; expected exit 1 (below pin) because the directory is not counted. Combined with `--min-test-files 1` it would stay green, which is the "not counted" half; assert both so the test cannot pass for the wrong reason.

### SEED-023 note
Plain uncommitted edit in the planning checkout `<home>/projects/crosswake/.planning/seeds/SEED-023-extend-scope-cardinality-gate.md` [VERIFIED: file exists, read]. Its prose says `check-actions` "remains the only caller"; add a short "second caller: Elixir copy in `script/check_absence_is_not_success.exs`, by design (no shared module)" note. Do not touch `scripts/ci_monitor.cjs`.

## Loop measurement (GUARD-02)

### Population (verified)
`git diff --name-only --diff-filter=AM d0dbdf7 50fcd57 | grep '_test\.exs$'` run in the candidate returns **45** files [VERIFIED: ran; list saved in the session scratchpad as `v25files.txt`]. Two of them are example-host files (`examples/phoenix_host/test/crosswake_example/...`) and one name appears twice in different dirs (`phase180_twin_feasibility_test.exs` under both `test/crosswake/proof/` and `examples/phoenix_host/test/crosswake_example/`).

### Prototype scanner (run read-only against the 45 files)
Full source is embedded in the Code Examples section. Results of the prototype [VERIFIED: ran]:

- 45 files all present; **96** loop-with-assert sites; 19 files have 0.
- Classification of the enumerated expression: 52 literal (list literal, `@attr`, `~w`, range, tuples), 14 syntactically non-empty list expression (`[a, b] ++ x`, non-empty list containing calls), **30 runtime**.
- The prototype flags `twin_receipt_test.exs:289` with `guard=none` (the D-07 "must flag before fix" requirement is met).
- Prior assertions are only credited as a guard candidate when they sit in the same `test`/`def` body (scope is reset at `test`, `def`, `defp`, `setup`, `describe`); the first prototype leaked guards from earlier tests in the module and was wrong. The committed scanner must keep that reset. The guard heuristic is only a hint ("candidate:Lnnn"); each is confirmed by hand.

Per-file site counts (headline table input; zeros included), paths relative to the candidate:
`examples/.../e2e/twin_fault_controller_test.exs`=2, `examples/.../host_command_seam_test.exs`=0, `examples/.../page_title_test.exs`=0, `examples/.../phase180_twin_feasibility_test.exs`=1, `test/crosswake/doctor/doctor_host_commands_test.exs`=1, `doctor_origin_mode_test.exs`=5, `doctor_test.exs`=3, `guides/host_command_seam_guide_test.exs`=5, `guides/loopback_origin_guide_test.exs`=1, `guides/native_shell_upgrade_test.exs`=3, `manifest/builder_test.exs`=0, `manifest/host_command_seam_fixture_test.exs`=0, `manifest/host_commands_test.exs`=0, `manifest/manifest_test.exs`=0, `operator_inspection/formatter_test.exs`=0, `operator_inspection_host_commands_test.exs`=0, `policy/host_commands_test.exs`=5, `proof/phase134_template_version_drift_test.exs`=0, `proof/phase170_vacuous_assertion_ledger_test.exs`=2, `proof/phase180_twin_feasibility_test.exs`=0, `proof/phase64_runtime_line_policy_test.exs`=8, `proof_lane/recovery_edges_test.exs`=0, `proof_lane/template_contract_test.exs`=7, `proof_lane/twin_fault_boundary_test.exs`=0, `proof_lane/twin_journey_test.exs`=1, `proof_lane/twin_producers_test.exs`=4, `proof_lane/twin_receipt_test.exs`=5, `router_host_commands_test.exs`=5, `shell/host_command_seam_swift_constant_test.exs`=0, `shell/ios_host_config_test.exs`=7, `shell/ios_host_generation_host_commands_test.exs`=3, `shell/ios_host_migration_graph_test.exs`=0, `shell/ios_host_migration_security_test.exs`=1, `shell/ios_host_origin_mode_test.exs`=3, `shell/managed_outputs_test.exs`=0, `shell/shell_package_test.exs`=0, `support_matrix/renderer_test.exs`=6, `test/mix/tasks/crosswake.docs.sync_test.exs`=2, `crosswake_doctor_test.exs`=0, `crosswake_gen_proof_lane_test.exs`=6, `crosswake_gen_shell_host_commands_test.exs`=0, `crosswake_gen_shell_host_test.exs`=3, `crosswake_gen_shell_origin_mode_test.exs`=3, `crosswake_inspect_test.exs`=0, `crosswake_proof_lane_verify_twin_test.exs`=4. (Total 96. The committed scan is authoritative and may differ slightly if the final scanner treats pipes differently; see blind spots.)

### Triage of the 30 runtime-sourced sites (hand-read this session)

`needs-fix` = fix in this phase. Line numbers are the `for`/`Enum.each` line at `b898e110`.

| Site | Collection | Disposition | Basis / required floor |
|---|---|---|---|
| `proof_lane/twin_receipt_test.exs:289` | `g["sub_observations"]` (inner loop; outer pinned `length == 10` at ~283-286) | **needs-fix** | exact floor from `TwinReceipt.roster/0` per group (see Pattern 2) |
| `proof_lane/twin_receipt_test.exs:110` | `TwinReceipt.identity_joins()` (function returning `@identity_joins`, 7 atoms at `twin_receipt.ex:45-53`) | **needs-fix** (not in D-09's list) | body `assert`s per join; if the function returned `[]` the whole test would pass. Floor: `joins = TwinReceipt.identity_joins(); assert length(joins) == 7` before the loop. Cheap and exact. |
| `proof_lane/twin_receipt_test.exs:286` | `decoded["groups"]` | safe-guarded | `assert length(decoded["groups"]) == 10` at the line above |
| `doctor/doctor_origin_mode_test.exs:360` | `origin_findings(report) ++ Enum.filter(report.findings, ...ios_host.)`, refute-only | **needs-fix** | bind `findings = ...` and `assert [_ | _] = findings` inside the `reports` loop before iterating. Executor must confirm non-emptiness by the green run on the unmutated tree (test at ~372 pins `[finding] = origin_findings(report)` for the same first two report shapes, so non-empty there; the third report (`check_publish?: true`) is the one to watch). If a report legitimately yields none, floor the concatenation across all three reports instead. |
| `doctor/doctor_origin_mode_test.exs:351` | `reports` bound to a literal 3-element list in the same test | safe-by-construction | |
| `doctor/doctor_origin_mode_test.exs:356`, `:364` | `forbidden` bound to a literal list (`forbidden = [` at 335) | safe-by-construction | |
| `doctor/doctor_origin_mode_test.exs:370` | literal list of 2 tuples | safe-compile-time-literal | |
| `proof/phase64_runtime_line_policy_test.exs:416` | `ios_entries = ... Enum.filter(device_verified)` then `for entry <- ios_entries` asserting the same predicate | **needs-fix** | the loop is a tautology over a filter; add `assert [_ | _] = ios_entries` before the loop, with a message naming that a canonical iOS `:device_verified` entry must exist |
| `proof/phase64_runtime_line_policy_test.exs:460` | `android_entries` filter on `:jvm_hermetic`, same shape | **needs-fix** | same floor |
| `proof/phase64_runtime_line_policy_test.exs:382` | `json_runtime_lines` | safe-guarded | `assert is_list(rebuild_matrix) and length(rebuild_matrix) > 0` immediately above, mapped 1:1 |
| `proof/phase64_runtime_line_policy_test.exs:93`, `:113` | literal lists bound in the test | safe-by-construction | |
| `proof/phase64_runtime_line_policy_test.exs:192` | `action_classes` | safe-guarded | `assert length(action_classes) > 0` at ~190 |
| `proof/phase64_runtime_line_policy_test.exs:249` | `matrix` | safe-guarded | `assert is_list(matrix) and length(matrix) > 0` at ~238 |
| `proof/phase64_runtime_line_policy_test.exs:757` | `android_entries` | safe-guarded | `assert length(android_entries) > 0` at ~754 |
| `mix/tasks/crosswake_proof_lane_verify_twin_test.exs:640` | `texts` x `[candidate, home, marker]`; `texts = lines ++ [two File.read!]` | **needs-fix** | `{2, lines}` is not length-pinned; `lines` could be empty and the refutes over it silently skip. Floor: `assert length(lines) == 4` before the loop (the sibling test at ~569 already pins the 4 literal lines). |
| `mix/tasks/crosswake_proof_lane_verify_twin_test.exs:582` | `lines ++ [files]` | safe-guarded | `assert lines == [ ...4 items... ]` at ~574-579 precedes it |
| `mix/tasks/crosswake_gen_shell_origin_mode_test.exs:99` | `expected = manifest["files"]` read from a golden JSON | **needs-fix** (not in D-09's list) | preceded only by `assert Enum.sort(Map.keys(actual)) == Enum.sort(Map.keys(expected))`, which passes when both are empty (golden `{}` and nothing generated). Floor: `assert map_size(expected) > 0` before the loop (an exact count is possible but couples to the golden file; the executor should read `@manifest` and prefer the exact count only if it is stable). |
| `mix/tasks/crosswake_gen_shell_origin_mode_test.exs:336` | `Crosswake.Shell.IOSHostOriginMode.forbidden_ats_keys()` (returns `@forbidden_ats_keys`, `ios_host_origin_mode.ex:23`), refute-only | **needs-fix** | if it returned `[]` the "no forbidden ATS keys" assertion is vacuous. Floor: bind the keys, `assert [_ | _] = keys`. |
| `mix/tasks/crosswake_gen_shell_origin_mode_test.exs:331` | literal list of 2 declarations | safe-compile-time-literal | |
| `mix/tasks/crosswake_gen_shell_host_test.exs:134` | `native_paths` | needs a quick read | bound earlier from a literal/derived list; likely safe-by-construction; confirm in the committed scan |
| `mix/tasks/crosswake_gen_shell_host_test.exs:411` | `invalid_cases` literal 6-tuple list | safe-by-construction | |
| `doctor/doctor_test.exs:859` | `advisory_commerce_findings`, refute/assert inside the loop | **waived-by-design** (the only waiver, D-09) | the in-file comment says "Today no commerce finding emits proof_class :advisory directly"; the contract is conditional ("IF such findings appear"). Asserting at least one would be false today. Record as a report-only row with this basis; do not touch the ledger. |
| `doctor/doctor_test.exs:907` | `advisory_findings` | safe-guarded | `assert advisory_findings != []` at ~910 |
| `doctor/doctor_test.exs:1083` | `sensitive_artifacts` literal list bound at 1063 | safe-by-construction | |
| `doctor/doctor_host_commands_test.exs:146` | `found` | safe-guarded | `assert codes(found) == [two codes]` pins exactly two findings; comment says so |
| `guides/host_command_seam_guide_test.exs:126` | `files` = `~w(...) |> Enum.map` | safe-by-construction | |
| `proof/phase170_vacuous_assertion_ledger_test.exs:115` | `committed["rows"]` | safe-guarded | `assert committed["rows"] != []` at 113 |
| `proof_lane/twin_producers_test.exs:77` | literal 6-tuple list with positive counts | safe-by-construction | also `refute Enum.empty?(observations)` and `length == count` in the body |
| `shell/ios_host_config_test.exs:70` | `cases` literal list | safe-by-construction | |
| `shell/ios_host_origin_mode_test.exs:139` | `cases` literal list of 3 | safe-by-construction | |
| `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs:47` | `manifest["routes"]`, refute-only loop | **needs-fix (judgement)** | `assert manifest["routes"]["offline-study"]["runtime"] == "offline_island"` follows the loop in the same test, so an empty routes map already fails the test, but D-10 wants the floor BEFORE the loop. Add `assert map_size(manifest["routes"]) > 0` before. This file belongs to the example host mix project (see Test commands). |
| remaining `literal` and `nonempty_list_expr` sites (66) | list literals, `@attr`, `~w`, ranges, `a ++ [..]` | safe-compile-time-literal / safe-by-construction | the committed scan lists each row |

So the actionable fix list is: twin_receipt `:289` and `:110`; doctor_origin_mode `:360`; phase64 `:416`, `:460`; verify_twin `:640`; gen_shell_origin_mode `:99` and `:336`; phase180 example `:47`. `doctor_test.exs:859` is waived. This is a superset of D-09's seven. D-09 says "the committed scan confirms or extends the list", so extending is within scope; flag it to the user in the plan summary.

### Scanner blind spots found while building the prototype (add to the table header)
- **Pipe form:** `xs |> Enum.each(fn ... end)` makes the `Enum` call carry only the function argument; the prototype then reports the function body as the "source". The committed scanner must unwrap `{:|>, _, [lhs, call]}` and use `lhs` as the enumerable.
- Assertions in helpers called from a loop; `with`, `Stream`, `Enum.all?`/`any?` shapes; loops whose body only filters; `for` inside macros that generate `test` blocks are caught only if the generated body contains `assert`.
- The guard hint recognizes `length(`, `Enum.count`, `[_ | _]`, `!= []`, `empty?`, `> 0`, `Enum.at` in an earlier assert in the same test body that mentions a variable of the enumerable; it cannot see a guard in a helper or `setup`.
- Examples-host test files are parsed but cannot be executed by the main suite.

## Twin cleanup and lockfiles (GUARD-03)

### `TwinRuntime` current code (`lib/crosswake/proof_lane/twin_runtime.ex`) [VERIFIED: read]
- Registry: `{:ok, registry} = Agent.start(fn -> %{children: %{}, first_failure: nil} end)` inside `commit/1` (line ~94). Unlinked, so a crashed owner does not kill it and a killed registry does not kill the owner.
- `first_failure/1` (~line 202):
  ```elixir
  @spec first_failure(t()) :: atom() | nil
  def first_failure(%__MODULE__{registry: registry}) do
    if Process.alive?(registry), do: Agent.get(registry, & &1.first_failure), else: nil
  end
  ```
- `record_failure/2`: `@spec record_failure(t(), atom()) :: :ok`; `if Process.alive?(registry) do Agent.update(...) else :ok end`.
- `stop_children/1` (lines ~227-233):
  ```elixir
  @spec stop_children(t()) :: :ok | {:error, :child_still_alive}
  def stop_children(%__MODULE__{registry: registry} = runtime) do
    children =
      if Process.alive?(registry), do: Agent.get(registry, &Map.values(&1.children)), else: []

    results = Enum.map(children, &terminate(runtime, &1))
    if Enum.all?(results, &(&1 == :ok)), do: :ok, else: {:error, :child_still_alive}
  end
  ```
- `stop_all/1` (~236-243): `@spec stop_all(t()) :: :ok | {:error, :child_still_alive}`; `result = stop_children(runtime)`; `if runtime.origin_listener, do: :gen_tcp.close(...)`; `if Process.alive?(registry), do: Agent.stop(registry)`; `result`.
- `mark_exited/2` (private, ~277): `if Process.alive?(registry), do: Agent.update(registry, &update_in(&1, [:children], ...))`. Called from `terminate/2` (after the port closes) and from `await_exit/2`.

Behaviour of `Agent` on a dead process, verified: `Agent.get`, `Agent.update`, `Agent.stop` on a stopped pid and `Agent.get(nil, ...)` all raise `exit` with reason `:noproc` [VERIFIED: ran in candidate]. So `catch :exit, _` covers dead pid, nil registry and a call timeout. (A timeout would be reported as `:registry_gone`; accept and comment.)

Recommended shape (D-13):

```elixir
@spec stop_children(t()) :: :ok | {:error, :child_still_alive | :registry_gone}
def stop_children(%__MODULE__{registry: registry} = runtime) do
  case tracked_children(registry) do
    {:ok, children} ->
      results = Enum.map(children, &terminate(runtime, &1))
      # A live registry with zero children is a real "nothing to stop": :ok.
      if Enum.all?(results, &(&1 == :ok)), do: :ok, else: {:error, :child_still_alive}

    :gone ->
      {:error, :registry_gone}
  end
end

defp tracked_children(registry) do
  {:ok, Agent.get(registry, &Map.values(&1.children))}
catch
  :exit, _ -> :gone
end

def stop_all(%__MODULE__{registry: registry} = runtime) do
  result = stop_children(runtime)
  if runtime.origin_listener, do: :gen_tcp.close(runtime.origin_listener)

  try do
    Agent.stop(registry)
  catch
    :exit, _ -> :ok
  end

  result
end
```

`first_failure/1`, `record_failure/2`, `mark_exited/2`: replace the `Process.alive?` guard with `try ... catch :exit, _ -> nil` / `-> :ok`. Keep the existing comment on `record_failure/2` ("A registry already released by stop_all/1 keeps no further causes...").

### Every caller of the stop functions (verified by grep)
| Site | Call | Result handling |
|---|---|---|
| `lib/crosswake/proof_lane/twin_journey.ex:745` (`finish/2`, private) | `TwinRuntime.stop_children(runtime)` | **discarded** (statement position, comment at 744 explains the command's own `stop_all/1` releases the registry) |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:79` (`after` of `try`) | `TwinRuntime.stop_all(runtime)` | **discarded** |
| other `lib/` users of `first_failure`/`record_failure` | `verify_twin.ex:136` (`first_failure`), `:187` (`record_failure`); `twin_runtime.ex` internal | tolerant paths |

### The nine `:ok = stop_*` test sites, in call order (D-14 requirement) [VERIFIED: read all]
| # | File:line | Call | Prior stop on this runtime? |
|---|---|---|---|
| 1 | `crosswake_proof_lane_verify_twin_test.exs:160` | `assert :ok = TwinRuntime.stop_all(runtime)` | no (fresh `prepare`) |
| 2 | `:238` | `assert :ok = TwinRuntime.stop_all(runtime)` | no (after a timed-out child; registry live) |
| 3 | `:248` | `assert :ok = TwinRuntime.stop_all(runtime)` | no |
| 4 | `:399` | `:ok = TwinRuntime.stop_children(runtime)` (inside a producer) | no; the command's `after` stop_all runs AFTER |
| 5 | `:413` | `:ok = TwinRuntime.stop_children(runtime)` (producer) | no |
| 6 | `:427` | `:ok = TwinRuntime.stop_all(runtime)` (producer, test "a registry already released before the receipt never crashes the command") | no; the command's `after` `stop_all` then runs on the already-stopped registry (a DOUBLE stop, return value discarded) |
| 7 | `:439` | `:ok = TwinRuntime.stop_all(runtime)` (second producer in the same test, other run root) | no; same double stop afterwards |
| 8 | `:548` | `:ok = TwinRuntime.stop_children(runtime)` (`dirty_producers/0`) | no |
| 9 | `twin_runtime_check_test.exs:132` | `assert :ok = TwinRuntime.stop_all(runtime)` | no |
Also bare, non-asserting calls: `verify_twin_test.exs:215`, `:270`; `twin_runtime_check_test.exs:163`. None of the nine runs after a previous stop, so none turns red. **But sites 6 and 7 create the dead-registry call in production code**: the command's `after` `stop_all` now returns `{:error, :registry_gone}`, discarded; the tests continue to assert the exit code and receipt, which pins "no raise, unchanged verdict" for the `VerifyTwin` half of D-14 for free. Also `blocked_receipt` calls `record_failure/2` after the producer stopped the registry (tolerant path) and `finish/4` calls `first_failure/1` (tolerant path); both must keep working under the `catch :exit` rewrite. The existing test at `:425` already proves those.

Registries in other fixtures are `Agent.start_link` (`twin_producers_test.exs:871`, `test/support/twin_git_fixtures.ex:57`, `twin_fault_boundary_test.exs:284`): to simulate a dead registry in those use `Agent.stop(registry)`, never `Process.exit(pid, :kill)` (linked: kills the test process). With `TwinRuntime.prepare/1` (unlinked `Agent.start`) either works.

Red test for stop_children (fails on the current code, passes after):
```elixir
test "stop_children reports registry_gone, not :ok, when the registry is already gone", ctx do
  {:ok, runtime} = TwinRuntime.prepare(candidate: record(ctx), run_root: ctx.run_root)
  Agent.stop(runtime.registry)
  assert {:error, :registry_gone} = TwinRuntime.stop_children(runtime)
  assert {:error, :registry_gone} = TwinRuntime.stop_all(runtime)   # listener still closed
  # and: a live registry with zero children is :ok (control)
end
```
Include the origin-listener assertion (port re-listenable after `stop_all`, same technique as `verify_twin_test.exs:152-165`) so the "always closes the origin" clause of D-13 is tested. Add a mid-stop race test only if cheap (kill the registry from a spawned process while a child is tracked); the unit-level `mark_exited` tolerance is covered by the dead-registry `stop_all` with a tracked sleeping child started before the registry is stopped: start a child, `Agent.stop` registry, call `stop_all`; expect `{:error, :registry_gone}`, and note the child itself is then orphaned by design (deferred item). The test must clean up the child (`kill -s KILL -- -pid`) in `on_exit`.

### D-14 pin for the journey half
`TwinJourney.finish/2` is `defp` and runs only inside `TwinJourney.run/2` (a real Simulator run). Do not run it. Pin by reading the source, the technique already used at `test/crosswake/proof_lane/twin_journey_test.exs:159` (`assert source =~ "TwinProducers.checked_identities("`). Sketch: read `lib/crosswake/proof_lane/twin_journey.ex`, assert the line matching `~r/^\s+TwinRuntime\.stop_children\(runtime\)\s*$/m` exists and no line of the form `= TwinRuntime.stop_children(` or `case TwinRuntime.stop_children(` exists, with a comment that changing this is the deferred "stop failure changes the verdict" item. The `VerifyTwin` half is pinned behaviourally by tests 6 and 7 above plus one new test where the producer kills the registry with `Agent.stop(runtime.registry)` and returns the normal full-producer result, asserting `{0, [..passed..]}` or the unchanged blocked verdict.

### Lock sites (verbatim current code) [VERIFIED: read]

`twin_producers.ex:619`: `@lock_rels ["mix.lock", "examples/phoenix_host/mix.lock"]`

(a) source gate, `twin_producers.ex:1469-1479`:
```elixir
defp lock_digests(path, digest) do
  results =
    for rel <- @lock_rels, match?({:ok, _}, File.stat(Path.join(path, rel))) do
      digest.(Path.join(path, rel))
    end

  cond do
    results == [] -> {:blocked, :identity_unknown}
    Enum.all?(results, &match?({:ok, _}, &1)) -> {:ok, Enum.map(results, fn {:ok, d} -> d end)}
    true -> {:blocked, :identity_unknown}
  end
end
```
Only caller: `source_gate/3`, line 715: `{:ok, locks} <- lock_digests(path, digest),` where `digest = Keyword.get(opts, :file_digest, &file_digest/1)` (line 714). The `else` of that `with` maps `{:blocked, _}` through and anything else to `{:blocked, :identity_unknown}` (lines ~719-721 region). Fix:
```elixir
defp lock_digests(path, digest) do
  results = for rel <- @lock_rels, do: digest.(Path.join(path, rel))

  if results != [] and Enum.all?(results, &match?({:ok, _}, &1)),
    do: {:ok, Enum.map(results, fn {:ok, d} -> d end)},
    else: {:blocked, :identity_unknown}
end
```
`file_digest/2` returns `{:error, reason}` for a missing file (it `File.open`s, `@spec ... {:ok, String.t()} | {:error, term()}`), so a missing lockfile now blocks. Existing tests: the fixtures `repo_fixture/1` (`twin_producers_test.exs:~415-440`) and `TwinGitFixtures.repo!/0` write BOTH locks, so they stay green. The existing test `"an unreadable lock file blocks the source gate instead of raising"` (`twin_source_probe_test.exs:~1060`) injects `file_digest:` and stays green.

Ordering trap for new tests: `source_gate/3` runs `clean_tree` BEFORE `lock_digests`. Deleting a tracked lockfile in a git fixture makes the tree dirty and returns `{:blocked, :source_dirty}`, never reaching the lock check. To prove the lock gate, build a fixture that never had the host lock (omit the `File.write!` for it before `git add -A`/commit) or inject `file_digest:`; the harness in `TwinGitFixtures` would need a small variant (an option to skip one lockfile) so the committed tree is clean and only the lock count differs. For an unreadable file use `File.chmod!(path, 0o000)` AFTER commit (mode bits other than the executable bit are not tracked by git, so the tree stays clean; verify with `clean_tree`), skip when `System.get_env("USER") == "root"`/uid 0.

(b) freeze side, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:226-236`:
```elixir
defp lock_digests(candidate_path) do
  digests =
    for rel <- ["mix.lock", "examples/phoenix_host/mix.lock"],
        path = Path.join(candidate_path, rel),
        match?({:ok, %{type: :regular}}, File.lstat(path)),
        {:ok, bytes} <- [File.read(path)] do
      :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
    end

  if digests == [], do: {:error, :lock_files_missing}, else: {:ok, digests}
end
```
Called only from `freeze/1` (line 214), which is used only by `injected_plan/1` (line ~95 region: `injected_plan(producers)` → `with {:ok, expectations} <- freeze(runtime)`). The real journey path uses `TwinProducers.freeze/3` instead (`journey_plan/2`). `{:error, :lock_files_missing}` currently reaches `conduct/2`'s `other -> failure(other)`, which prints `first cause: unknown` (via `inspect_safe`) and is NOT a blocked receipt. Fix: require every rel to be a regular, readable file, else return `{:blocked, :identity_unknown}`; `injected_plan`'s `with` passes a non-matching value through, and `conduct/2` already has `{:blocked, cause} -> blocked_receipt(runtime, cause)` [VERIFIED: read lines 108-123]. `:identity_unknown` is in `TwinReceipt`'s closed cause list (`twin_receipt.ex:27`) so `TwinReceipt.safe_cause/1` keeps it. Keep the `lstat` regular check per file: a symlinked lockfile used to be silently skipped and now blocks (note it in the summary; the real candidate's locks are regular files).

Note `blocked_receipt/2` itself freezes expectations with `lock_digests: [zero]`, which is unrelated and unchanged.

(c) observation, `twin_producers.ex:1598`: `locks = for rel <- @lock_rels, d = digest_or_nil(Path.join(path, rel)), do: d`; gates at `dependency_lock: if(locks != [], ...)` and `backend_build: if(live[:backend_build] && head && tree && locks != [], ...)`. Fix:
```elixir
lock_list = Enum.map(@lock_rels, &digest_or_nil(Path.join(path, &1)))
locks = if Enum.all?(lock_list, & &1), do: lock_list      # nil unless BOTH digested
...
dependency_lock: if(locks, do: TwinReceipt.identity_digest(locks)),
...
backend_build: if(live[:backend_build] && head && tree && locks, do: ...)
```
`digest_or_nil/1` is `ok_or_nil(file_digest(path))` (line 1668). The final `Enum.reject(fn {_k, v} -> is_nil(v) end)` already drops nil joins; `TwinReceipt` turns an absent join into `blocked, :identity_unknown` (`twin_receipt.ex:505-537` region [VERIFIED: grep lines]).

Observation red test: after `TwinProducers.freeze` on the clean `repo_fixture`, `File.rm!(host mix.lock)` and call `TwinProducers.observe_identities(frozen, live(frozen))`; today `observed` still has `:dependency_lock` (built from one digest, a mismatch value); after the fix `refute Map.has_key?(observed, :dependency_lock)` and likewise `:backend_build`. Deleting the file also makes the tree dirty, which affects only `source`/`head`/`tree`, not `dependency_lock`, so the assertion stays specific.

### Test fallout of requiring both lockfiles at the freeze side (important)
`test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:25` writes only `mix.lock` into the candidate. Every `VerifyTwin.execute(..., producers: ...)` that gets past `prepare` runs `freeze/1`, so after fix (b) these block with `identity_unknown` instead of reaching the producers: the passing-run test (~281), the observed-failure/missing-observation tests (~346-360), child-timeout (~368), the stop_children tests (~396-420), released-registry (~425-447), producer-result tests (~449-480), run-root-inside-candidate tests (~484-520), and the dirty-candidate tests (~562-640). Fix in `setup`: `File.mkdir_p!(Path.join(candidate, "examples/phoenix_host"))` and write `examples/phoenix_host/mix.lock`. Then the git-based tests (`git_in(ctx.candidate, ["add", "mix.lock"])` at ~564, ~606, ~626) must also add the host lock (`["add", "mix.lock", "examples/phoenix_host/mix.lock"]`), or the untracked host lock raises `modified/untracked` counts (the exact-count assertions `"1 changed or untracked file"` and `measure 2` would break). `twin_runtime_check_test.exs:22` also writes only `mix.lock` but never reaches freeze; leave it.

Red-before-fix tests for (b): candidate with only the root lock → `{2, [_, "first cause: identity_unknown", report, _]}` with a receipt file written; candidate with only the host lock → same; both present → existing green behaviours (control).

## Test commands that work in the candidate

All commands run from `/private/tmp/crosswake-phase180-impl` (shim requires `.tool-versions`). Use a dedicated `MIX_BUILD_PATH` per run; no two concurrent runs share one. Evidence goes to `/private/tmp/crosswake-phase180-run` (`RUNS`). [VERIFIED: command shapes taken from `gate-184-13.sh` and `184-14-PLAN.md`, read this session]

| Purpose | Command |
|---|---|
| Focused test files | `MIX_BUILD_PATH=$RUNS/_build_185_NN_test mix test test/crosswake/proof/absence_is_not_success_test.exs` |
| Twin quick suite (184 gate) | `MIX_BUILD_PATH=$B mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/crosswake/proof_lane/twin_runtime_check_test.exs test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/crosswake/proof_lane/twin_journey_test.exs test/crosswake/proof_lane/twin_fault_boundary_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` |
| Full suite | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > $RUNS/<name>.full.out 2>&1` (unset build path on purpose: nested mix runs in phase135/phase52 proof tests rebuild a shared `MIX_BUILD_PATH`; 184-10 deviation 1). Exit not gated; compare the extracted failure set. |
| Failure extractor | `bash $RUNS/extract-184-07.sh <full.out> > <x>.failures`; then `cmp -s <x>.failures $RUNS/baseline-184.failures`. Baseline failure set = exactly one line: `test/crosswake/proof/phase180_twin_feasibility_test.exs:30` (baseline exit 2, "2399 tests, 1 failure (78 excluded)"). |
| Guides, docs parity, ledger | `MIX_BUILD_PATH=$B mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`; `elixir script/inventory_collection_assertions.exs --check`; `MIX_BUILD_PATH=$BD mix crosswake.docs.sync --check` |
| Compile and format | `MIX_BUILD_PATH=$BD mix compile --force --warnings-as-errors`; `mix format --check-formatted <touched files>` |
| ExUnit ownership | `elixir script/check_exunit_ownership.exs` (any new `*_test.exs` must still be owned; only needed if a file is added) |
| Absence checker directly | `elixir script/check_absence_is_not_success.exs --root <dir> [--min-test-files N]` |
| Adoption scan | `MIX_BUILD_PATH=$BD mix crosswake.adoption_context.scan > $RUNS/adoption-scan-185.out 2>&1`; extract `sed -E 's/^\*\* \(Mix\) //' ... \| grep -E '^routing\.' \| sort` and `cmp -s` against `$RUNS/adoption-scan-head-184.findings` (five known findings; exit code not gated) |
| Real-candidate preflight (read-only) | `MIX_ENV=test MIX_BUILD_PATH=$B mix run --no-start -e 'IO.inspect(Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()))'` must print exactly `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (the 184 evidence files `real-probe-184-13.out` contain that term). On an uncommitted working tree it will not be zero, so run it against a pre-commit copy as 184-14 did (`/private/tmp/crosswake-184-13-preprobe`) and again on the committed tree. |
| Example-host tests | `examples/phoenix_host` has `deps` and `_build` present [VERIFIED: `ls`]. The main suite excludes them (`--exclude requires_example_host`). To verify the `phase180_twin_feasibility_test.exs:47` edit run `cd examples/phoenix_host && MIX_BUILD_PATH=$RUNS/_build_185_ex mix test test/crosswake_example/phase180_twin_feasibility_test.exs`. Unverified whether that project compiles offline here: treat as MEDIUM and have the plan fall back to parse-only plus a formatted-code check if it cannot run. |

"Pin guard": the repo-itself checker test (flagless) is the pin guard for the test-file count; `twin_producers_test.exs:364-370` (`assert length(backend) == 13`) is the model for pinned counts.

### Which existing tests go red under the new floors
- `absence_is_not_success_test.exs`: all 9 fixture tests (every `@tag :tmp_dir` case) fail until moved onto `baseline!` plus `--min-test-files 1`. The repo-itself test passes if the pin equals the real count.
- `crosswake_proof_lane_verify_twin_test.exs`: roughly 20 tests until the setup writes the host lock and the three git tests add it (see above).
- `twin_producers_test.exs` / `twin_source_probe_test.exs`: green (their fixtures carry both locks); verify by running.
- `phase170_vacuous_assertion_ledger_test.exs` / `--check`: red on display drift after any edit that shifts a ledger row (see Ledger).
- No other test is expected to change. `twin_runtime_check_test.exs` and `twin_fault_boundary_test.exs` do not call freeze.

### Ledger drift handling (owned by the final plan)
Rows live in `script/collection_assertion_ledger.json` (243 rows; scope `test/**/*.exs`; buckets in use: safe-by-construction 135, safe-guarded 63, safe-cardinality-pinned 41, safe-compile-time-literal 4 [VERIFIED: parsed]). Keys are hashes of `{enclosing, normalized expression, ordinal}`, so a pure line shift changes only `display`; `--check` compares the full row and reports `mismatched ... display` [VERIFIED: read `check/3`]. After all test edits: `elixir script/inventory_collection_assertions.exs --check`; if it fails, `--emit-snapshot`, then prove with a JSON diff that only `display` fields changed (no new, removed or re-bucketed rows). `script/collection_assertion_remediation.json` is a frozen closed-world file not covered by `--check`; Phase 184 did not touch it. The `frozen_at`/`generator` header of the ledger may also change under `--emit-snapshot` (it runs `git rev-parse HEAD`, line ~110); inspect the diff and keep the header stable if the existing convention is to leave it.

## Plan-split suggestion

Wave 1 (parallel, file-disjoint):
- **185-01 (GUARD-01):** checker script, its test, SEED-023 note. Pre-fix red run: with the old script, the new red cases (root missing, empty scope) must show exit 0 (that is the red). Then fix, then green. Pin literal left as a placeholder equal to 249 and flagged for 185-04 to confirm.
- **185-02 (GUARD-03):** `twin_runtime.ex`, `twin_producers.ex`, `verify_twin.ex`, plus the five test files listed under plan B above (including the `:640` floor in `verify_twin_test.exs`, the setup change, and the lock-gate fixture variant). Red tests first (stop_children dead registry; missing-lock freeze on each side; observation join), run them red, then fix, then green.
- **185-03 (GUARD-02):** scanner and `185-LOOP-MEASUREMENT.md`, plus floors in `twin_receipt_test.exs`, `doctor_origin_mode_test.exs`, `phase64_runtime_line_policy_test.exs`, `crosswake_gen_shell_origin_mode_test.exs`, and the example-host file. Do NOT touch `crosswake_proof_lane_verify_twin_test.exs` (owned by 185-02); the table row for `:640` is written by 185-04 after both merge, or 185-03 writes it as "fixed in 185-02".

Wave 2:
- **185-04 (gates and commit):** reads the final tree; confirms pin literal equals the scanned test-file count (edit the literal if any plan added a test file); regenerates the ledger if drifted; runs the mutation harness (`mutation-185.log`); runs the full suite and baseline comparison, adoption scan, real-candidate preflight, ownership, docs sync, compile, format; makes the single commit with the Opus 5.5 trailer; writes `185-LOOP-MEASUREMENT.md` finalization and the Phase 184 supplement.

Caveat from project memory: Crosswake executors dispatch with forced isolation none, so even "parallel" plans share one candidate directory. Keep the plans file-disjoint as above, and give each wave-1 plan its own `MIX_BUILD_PATH`. If the orchestrator runs them sequentially (likely), order 185-02 before 185-03 is irrelevant because they are disjoint.

## Mutation controls (D-11 / D-16) - concrete recipes

Harness: copy `/private/tmp/crosswake-phase180-run/mutate-184-13.sh` (rsync copy of the candidate excluding `.git` into a throwaway dir, `export MIX_BUILD_PATH=$BM`, `apply()` requires sha256 before != after, `restore_all`, `totals`, `has_header`, log line format `control N: <what>: failed as expected in "<test>" (rc=R N tests, M failures)`, umask 022 recorded in the header, a pre-mutation sha256 manifest of the candidate's changed paths verified after, `test ! -e` on the throwaway dir at the end). Control 0 is the unmutated copy passing. The copy has no `.git`, so only run test files that make their own git fixtures (all the twin tests do).

Suggested controls (each mutation is a single `perl -0pi` and each names the test that must fail; write the regex from the actual edited source, as 184-14 required):
1. **GUARD-01 floors reverted** (script in the copy): replace the exit-2 root check with the old fallback; expected fail: the four root-case tests. Separately: remove the `assert_full_scope` call; expected fail: empty-scope and dot-dir tests. Separately: pin set to 0; expected fail: below-pin test.
2. **`:289` floor:** mutate `project/2` in the copy: `perl -0pi -e 's/for e <- g\.sub_observations do/for e <- (if g.id == "T01", do: [], else: g.sub_observations) do/' lib/crosswake/proof_lane/twin_receipt.ex` (verify the exact text against the file, lines ~401-410). Run only `twin_receipt_test.exs`; expect failure naming "project/2 returns exactly the pinned closed key set" at the new `[_ | _]` assertion. **Paired negative control:** same mutation with the floor lines removed from the test copy; that test must PASS (this proves the floor, not something else, catches it). The log line must say which assertion failed (ExUnit output includes the failing `assert` text; capture and grep for the `[_ | _]` or `length(...) == ...` line).
3. **`stop_children`:** revert the catch to return `[]` (the old `else: []` behaviour): expected fail: the new dead-registry test.
4. **freeze (b):** revert `digests == []` form: expected fail: the missing-host-lock and missing-root-lock freeze tests.
5. **source gate (a):** restore the `File.stat` pre-filter: expected fail: the omitted-host-lock `source_gate` test.
6. **observation (c):** restore `locks != []`: expected fail: the observation-join test.
7. **loop floors**: for each new floor, either a projection mutation that empties the collection, or revert the floor line; at minimum the `:289` pair, one for `phase64` `:416` (mutate by changing the filter predicate in the test copy so it matches nothing: the floor must fail while the pre-fix loop passes), and `:640`.

The `.git`-less copy and `mix test` of a single file keep each control fast. No zero-test runs: the log gate `grep -cE '\(rc=[0-9]+ 0 tests'` must be 0.

## Common Pitfalls

### Pitfall 1: fixtures that pass the new floors by accident
**What goes wrong:** a baseline that includes more than one of each thing masks a floor (e.g. two todos so deleting one stays above the pin).
**How to avoid:** baseline holds exactly one of each (matching pin 1), each red case removes or changes exactly one thing; the equal case sits exactly on the pin.

### Pitfall 2: exit code 126 from the shim read as "script fails closed"
**What goes wrong:** running `elixir script/...` from a directory without `.tool-versions` exits 126, which looks like a red.
**How to avoid:** self-tests keep `cd: @repo_root`; assert the specific message and exit code (2 vs 1), never only non-zero.

### Pitfall 3: recursive `expected` for depth-1 globs (see Anti-Patterns)

### Pitfall 4: lock check hidden behind the dirty-tree check
`source_gate` returns `:source_dirty` before it ever digests a lockfile; a "deleted lockfile" test proves nothing about locks (see the ordering trap).

### Pitfall 5: untracked host lock changes dirty counts in verify_twin git tests
Covered above; the exact-count assertions will fail with 2 instead of 1.

### Pitfall 6: `Process.exit(registry, :kill)` on a linked registry kills the test
Use `Agent.stop/1` for `Agent.start_link` fixtures.

### Pitfall 7: `Agent.stop` on a dead registry exits `:noproc`
`stop_all/1` must wrap it; a double stop (producer stopped it, then the command's `after`) is routine in the test suite (sites 6 and 7).

### Pitfall 8: floors placed after the loop
D-10 requires the floor before the loop or at its head. The example-host `:47` edit and the `:289` edit must put the assertion first.

### Pitfall 9: ledger display drift and `assert Enum.all?` in new tests
See Ledger drift. Avoid `assert/refute Enum.all?/any?` in added lines.

### Pitfall 10: pin timing
The pin must be the count at the FINAL commit, taken by an independent measurement (`find test -name '*.exs' -type f | wc -l` gave 249 at `b898e110`, equal to the glob count). If a plan adds a test file, 185-04 edits the literal; a gate asserts the script's printed `scanned N` equals `pin M` at the final commit (equality at that moment, `>=` forever after).

### Pitfall 11: absence scored as success in the new code itself
An exit-2 branch nobody reads, or a scope message that prints but whose caller ignores the code, is the same defect. The self-tests assert exit codes through the real subprocess. The unread `{:error, :registry_gone}` is the accepted, pinned, deferred exception (D-14).

## Footguns (summary)
1. asdf shim exit 126 outside a `.tool-versions` directory.
2. The verify_twin test candidate has only the root lock; ~20 tests go red until the setup and the git-adds are updated.
3. `source_gate` checks tree cleanliness before locks.
4. Depth-1 planning globs versus a recursive walk.
5. `Path.wildcard` skips dot-dirs and counts directories; `fold_files` does the opposite (this is the design, but both must be exercised in tests).
6. `Agent.start` (unlinked) in production versus `Agent.start_link` in several test fixtures.
7. `finish/2` unreachable without a Simulator: use a source-reading pin.
8. Ledger `display` drift after line shifts.
9. Two files named `phase180_twin_feasibility_test.exs` (main suite one has the baseline failure at `:30`; the example-host one is a separate mix project).
10. The `strip_heredocs` toggle in the checker is a known fragility: a new heredoc with an odd number of `"""` in the checker's own test file blanks the rest of that file for the scanner; keep fixtures balanced.
11. `OptionParser` with `strict:` returns invalid pairs for `--root` without a value; check that branch is reached rather than falling to cwd.
12. Unexpected: a lone `--root` was previously silently cwd; fixture-less callers (nothing in CI) are unaffected, but any local habit of `elixir script/check_absence_is_not_success.exs --root` now exits 2 by design.

## Code Examples

### Loop scanner (one-off, read-only; prototype that produced the numbers above)
```elixir
# Phase 185 D-07. Usage: cd <candidate> && elixir loop_scan.exs . <filelist>
defmodule LoopScan do
  @enum_funs [:each, :map, :reduce, :flat_map, :all?, :any?, :filter, :reject, :with_index]
  @assert_names [:assert, :refute, :assert_receive, :refute_receive, :assert_raise, :assert_in_delta]

  def main([root, list]) do
    files = list |> File.read!() |> String.split("\n", trim: true)
    if length(files) != 45, do: raise("expected exactly 45 files, got #{length(files)}")
    rows =
      for f <- files do
        path = Path.join(root, f)
        unless File.regular?(path), do: raise("missing file #{f}")
        sites = path |> File.read!() |> Code.string_to_quoted!(columns: false) |> sites([])
        {f, Enum.sort_by(sites, & &1.line)}
      end
    for {f, sites} <- rows do
      IO.puts("#{f}\t#{length(sites)}")
      for s <- sites, do: IO.puts("  L#{s.line}\t#{s.kind}\tsrc=#{s.src_class}\tguard=#{s.guard}\t#{s.src}")
    end
    IO.puts("TOTAL files=#{length(rows)} sites=#{rows |> Enum.map(fn {_, s} -> length(s) end) |> Enum.sum()}")
  end

  # `prior` = statements preceding the node in every enclosing block, reset at test/def/setup/describe
  defp sites({:__block__, _, stmts}, prior) do
    stmts |> Enum.with_index() |> Enum.flat_map(fn {st, i} -> sites(st, prior ++ Enum.take(stmts, i)) end)
  end
  defp sites({:for, m, args} = node, prior) do
    {gens, body} = split_for(args)
    here =
      if has_assert?(body) do
        enum = gens |> Enum.filter(&match?({:<-, _, _}, &1)) |> Enum.map(fn {:<-, _, [_, e]} -> e end)
        [site(:for, m, enum, prior)]
      else [] end
    here ++ children(node, prior)
  end
  defp sites({{:., _, [{:__aliases__, _, [:Enum]}, fun]}, m, args} = node, prior) when fun in @enum_funs do
    here = if Enum.any?(args, &has_assert?/1), do: [site(:"Enum.#{fun}", m, Enum.take(args, 1), prior)], else: []
    here ++ children(node, prior)
  end
  defp sites({n, _, args} = node, _prior) when n in [:test, :def, :defp, :setup, :describe, :property] and is_list(args),
    do: children(node, [])
  defp sites(node, prior), do: children(node, prior)
  # TODO (committed version): unwrap {:|>, _, [lhs, call]} so a piped Enum call reports `lhs` as the source.

  defp children({a, _, args}, prior) when is_list(args), do: sites_list([a | args], prior)
  defp children({a, b}, prior), do: sites_list([a, b], prior)
  defp children(l, prior) when is_list(l), do: sites_list(l, prior)
  defp children(_, _), do: []
  defp sites_list(l, prior), do: Enum.flat_map(l, &sites(&1, prior))

  defp split_for(args) do
    {opts, gens} = case List.last(args) do l when is_list(l) -> {l, Enum.drop(args, -1)}; _ -> {[], args} end
    {gens, Keyword.get(opts, :do) || Keyword.get(opts, :reduce) || []}
  end

  defp has_assert?(ast) do
    {_, found} = Macro.prewalk(ast, false, fn
      {n, _, a} = node, _ when n in @assert_names and is_list(a) -> {node, true}
      node, acc -> {node, acc}
    end)
    found
  end

  defp site(kind, m, enums, prior) do
    src = enums |> Enum.map(&Macro.to_string/1) |> Enum.join(" ; ") |> String.replace(~r/\s+/, " ") |> String.slice(0, 90)
    %{kind: kind, line: m[:line], src: src, src_class: src_class(enums), guard: guard(enums, prior)}
  end

  defp src_class(enums) do
    cond do
      Enum.all?(enums, &literal?/1) -> :literal
      Enum.all?(enums, &nonempty_list_expr?/1) -> :nonempty_list_expr
      true -> :runtime
    end
  end
  defp nonempty_list_expr?([_ | _]), do: true
  defp nonempty_list_expr?({:++, _, [a, b]}), do: nonempty_list_expr?(a) or nonempty_list_expr?(b)
  defp nonempty_list_expr?({:.., _, _}), do: true
  defp nonempty_list_expr?(_), do: false
  defp literal?(l) when is_list(l), do: Enum.all?(l, &literal?/1)
  defp literal?({:@, _, _}), do: true
  defp literal?({:sigil_w, _, _}), do: true
  defp literal?({:.., _, [a, b]}), do: literal?(a) and literal?(b)
  defp literal?({a, b}), do: literal?(a) and literal?(b)
  defp literal?(x) when is_binary(x) or is_atom(x) or is_number(x), do: true
  defp literal?({:{}, _, l}), do: literal?(l)
  defp literal?(_), do: false

  defp guard(enums, prior) do
    vars = enums |> Enum.flat_map(&vars/1) |> Enum.uniq()
    hit = Enum.find(prior, fn st -> has_assert?(st) and card?(st) and Enum.any?(vars, &(&1 in vars(st))) end)
    if hit, do: "candidate:L#{elem(hit, 1)[:line] || "?"}", else: "none"
  end
  defp vars(ast) do
    {_, acc} = Macro.prewalk(ast, [], fn {n, _, c} = node, a when is_atom(n) and is_atom(c) -> {node, [n | a]}; node, a -> {node, a} end)
    acc
  end
  defp card?(ast), do: Regex.match?(~r/length\(|Enum\.count|\[_ \| _\]|!= \[\]|empty\?|> 0|Enum\.at/, Macro.to_string(ast))
end
LoopScan.main(System.argv())
```
The committed scanner should additionally write the phase-dir output with a header that lists the blind spots and the exact command and count used to produce the file list. It must fail (raise) if `twin_receipt_test.exs` line 289 is not among the reported sites, to satisfy D-07's "proves it can see a real site".

### AST shapes that count as loop sites
| Shape | AST | Notes |
|---|---|---|
| `for x <- xs, do: assert ...` / `do ... end` | `{:for, meta, [gens..., [do: body]]}` | `reduce:` option puts the body in `do:` with `->` clauses |
| `Enum.each(xs, fn x -> assert ... end)` | `{{:., _, [{:__aliases__, _, [:Enum]}, :each]}, meta, [xs, fn]}` | |
| piped `xs |> Enum.each(fn ...)` | `{:|>, _, [xs, call_with_one_arg]}` | prototype misreports the source; unwrap in the committed version |
| `Enum.map/flat_map/reduce` with assert in the fn | same as each | |

### Elixir 'wait, is it empty?' idioms to use for floors
`assert [_ | _] = coll` (non-empty), `assert length(coll) == N` (exact), `assert map_size(m) > 0`. Not `assert Enum.all?`/`Enum.any?`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bare `Path.wildcard` scope plus fallback-to-cwd argv | Strict argv, two derivations, pinned minimum | this phase | A green result implies something was examined |
| `Process.alive?` then `Agent.get` | `try/catch :exit` | this phase | closes the check-then-act race |
| Keep whichever lockfiles exist | Require both | this phase | identity joins can no longer compare narrowed digests |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `doctor_origin_mode_test.exs:360`'s collection is non-empty for all three reports (the third uses `check_publish?: true`) | Triage | If a report yields none, the per-report floor fails green-run; executor falls back to flooring the concatenation. Confirmed only by running the edited test. |
| A2 | `gen_shell_host_test.exs:134` `native_paths` is bound from a literal/derived non-empty list (read only the loop, not its definition) | Triage | One more `needs-fix` row if it is runtime-derived and unguarded |
| A3 | The example-host test project can run `mix test` offline in this environment | Test commands | If not, `:47` fix is verified by parse and format only; note it in the measurement table |
| A4 | `phase180_twin_feasibility_test.exs:859`-style waiver (`doctor_test.exs:859`) basis: the in-file comment says no advisory commerce finding exists today; not re-proven by running the doctor in this session | Triage | If findings do exist, an explicit `[_ | _]` floor is the better fix (D-09's preference) |
| A5 | `golden manifest["files"]` in `crosswake_gen_shell_origin_mode_test.exs:99` is non-empty (it is a committed golden file) | Triage | `map_size(expected) > 0` would then fail on the unmutated tree; the green run tells |
| A6 | Symlinked lockfiles do not occur in the real candidate (freeze (b) now blocks them) | Lock sites | Real-candidate preflight would show a new `identity_unknown`; real-candidate check in 185-04 covers it |

All other claims are tagged inline: [VERIFIED] items were read or run this session in the candidate; nothing from external sources was needed.

## Open Questions (RESOLVED)

1. **Will the test-file pin remain 249?**
   - Known: no required plan adds a test file; new tests fit existing files.
   - Unclear: an executor may choose a new file for the lock-gate fixtures.
   - Recommendation: forbid new test files in 185-01..03 (keeps 249 and `check_exunit_ownership` untouched); 185-04 re-measures anyway.
   - **RESOLVED:** plans 185-01..04 add no test file; 185-05 Task 1 re-measures the pin against an independent `find` count and stops (BLOCKED) on mismatch.
2. **Does the executor want the committed scanner's output stored as `.tsv` or inside `185-LOOP-MEASUREMENT.md`?**
   - Recommendation: raw scan output `185-LOOP-SCAN.txt` plus the hand-classified table in the `.md`, both in the planning phase directory.
   - **RESOLVED:** 185-03 writes `185-LOOP-SCAN.txt`, `185-LOOP-SCAN.184.txt` and `185-LOOP-MEASUREMENT.md` in the phase directory.
3. **`--emit-snapshot` header churn** (`frozen_at`): check the diff and keep only `display` changes.
   - **RESOLVED:** 185-05 Task 1 compares key-sorted rows with `display` removed (jq + cmp), so only `display`/header changes are accepted.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir via asdf shim | all scripts and tests | yes (only inside a `.tool-versions` directory) | 1.19.5-otp-27 | none needed |
| `perl` | mutation harness `apply()` | yes (used by 184 harness) | system | n/a |
| `rsync` | mutation copy | yes (used by 184 harness) | system | `cp -R` excluding `.git` |
| `git` | scanner file list, fixtures | yes | repo uses 2.41+ per preflight text | none |
| `examples/phoenix_host/deps` and `_build` | verifying the `:47` edit | present on disk | n/a | parse and format only |
| Simulator / xcodebuild | NOT used | n/a | n/a | n/a (forbidden) |

**Missing dependencies with no fallback:** none.

## Validation Architecture

(`workflow.nyquist_validation` is `true` in `<home>/projects/crosswake/.planning/config.json`; section included.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (existing); no change |
| Quick run command | `MIX_BUILD_PATH=$RUNS/_build_185_NN_test mix test <file>` |
| Full suite command | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host`, failures `cmp` against `baseline-184.failures` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GUARD-01 | nonexistent root, root-is-file, bare `--root`, unknown arg each exit 2 with the stated message | subprocess | `mix test test/crosswake/proof/absence_is_not_success_test.exs` (new tests; fail direction: old script exits 0) | file exists, tests new (Wave 0 = write red first) |
| GUARD-01 | empty test scope; each of 3 planning scopes empty; below pin; dot-dir proper subset; dir named `x.exs` uncounted; equal passes; repo itself meets pins | subprocess | same file | new tests in existing file |
| GUARD-01 | OK lines print counts (`scanned`, `pin`) and keep old phrases | subprocess | same; plus `elixir script/check_absence_is_not_success.exs` in the candidate prints counts | existing + new assertion |
| GUARD-01 | script reverts bite | mutation | `mutation-185.log` controls 1a-1c | harness, new |
| GUARD-02 | `twin_receipt_test.exs:289` floor; mutation emptying one group's projection fails it for the right reason; negative control passes | unit + mutation | `mix test test/crosswake/proof_lane/twin_receipt_test.exs` and the harness | file exists; edits new |
| GUARD-02 | every other `needs-fix` floor holds on the unmutated tree | unit | `mix test` on each edited file (twin_receipt, doctor_origin_mode, phase64, verify_twin, gen_shell_origin_mode) and the example-host file | files exist |
| GUARD-02 | measurement table covers all 45 files, includes zeros, includes `:289` before fix | scan | `cd candidate && elixir <scanner> . <filelist>` exits 0 and prints `TOTAL files=45`; scanner raises if `:289` not found | new one-off |
| GUARD-02 | no new repo-wide blocking rule | diff inspection | `git diff --stat` of the final commit lists no new check script/workflow; `git diff` has no `+.*(assert|refute)[[:space:]]+Enum\.(all|any)\?\(` | gate |
| GUARD-03 | `stop_children`/`stop_all` return `{:error, :registry_gone}` on a dead registry; live empty registry `:ok`; origin still closed | unit | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs` (fail direction: old code returns `:ok`) | file exists, tests new |
| GUARD-03 | callers still discard (verdict unchanged) | unit | verify_twin tests 6/7 plus new dead-registry producer test; source-pin test in `twin_journey_test.exs` | exists + new |
| GUARD-03 | freeze (b) requires both lockfiles; each side missing gives `first cause: identity_unknown` and a written receipt, exit 2 | integration | `mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | exists + new, setup updated |
| GUARD-03 | source gate (a) blocks when one lockfile absent or unreadable; both present passes | unit | `mix test test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_source_probe_test.exs` | exists + new |
| GUARD-03 | observation (c) drops `dependency_lock`/`backend_build` unless both digested | unit | `twin_producers_test.exs` | new |
| GUARD-03 | each reverted fix is detected | mutation | `mutation-185.log` controls 3-6 | harness |
| all | no regressions; only baseline failure remains | suite | full suite `cmp` to `baseline-184.failures`; twin quick suite; ledger `--check`; docs sync; compile warnings-as-errors; format; adoption scan findings `cmp`; real-candidate probe all zeros | gates in 185-04 |

### Sampling Rate
- **Per task commit (no commits are made per task; per task completion):** the focused `mix test` file(s) for that task.
- **Per wave merge:** the twin quick suite plus `absence_is_not_success_test.exs`.
- **Phase gate:** full suite failure set equals baseline, ledger/docs/compile/format/adoption/probe green, mutation log complete with control 0 passing, candidate sha256 manifest unchanged by the harness, before the single commit and before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] Red tests written and run RED before each fix (record the red output in RUNS).
- [ ] `baseline!/1` helper and `--min-test-files` plumbing in the checker test.
- [ ] A `TwinGitFixtures` variant (or option) that omits one lockfile before the commit.
- [ ] `mutate-185.sh` derived from `mutate-184-13.sh`.
- [ ] Committed scanner and `185-LOOP-SCAN.txt`.
None of this needs a new framework install.

## Security Domain

`security_enforcement` is not set in config (absent means enabled), so a short section is included; this phase has little attack surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | yes | strict argv parsing in the checker; closed cause atoms in the receipt (`:identity_unknown` already closed) |
| V6 Cryptography | no | lockfile digests use existing `:crypto.hash(:sha256, ...)` and `file_digest/2`; do not add anything |
| V7 Error handling and logging | yes | failure messages must not leak absolute candidate paths into receipts or proof output; the checker prints the expanded `--root` only to the local console by D-02; `blocked_receipt` already carries only the closed cause |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent narrowing of the identity join (one lockfile) | Tampering | require both digests, absent join becomes `identity_unknown` |
| Check passing on empty/missing input | Repudiation / Tampering | floors and pins as designed |
| Path or home-dir leakage in twin receipts | Information disclosure | keep the existing `refute text =~ candidate/home/marker` tests (verify_twin_test ~562-640) green after the setup change |
| Orphaned OS process groups after a lost registry | DoS (local) | `{:error, :registry_gone}` surfaces it; owner change deferred |

Adopter privacy: nothing in this research names or infers the adopter; fixtures use synthetic content (`"%{}\n"`).

## Sources

### Primary (HIGH confidence) - read or executed this session
- Candidate `/private/tmp/crosswake-phase180-impl` @ `b898e110`: `script/check_absence_is_not_success.exs`, `test/crosswake/proof/absence_is_not_success_test.exs`, `scripts/ci_monitor.cjs:300-405`, `lib/crosswake/proof_lane/twin_runtime.ex`, `twin_producers.ex` (lines 612-735, 1455-1500, 1555-1667), `twin_receipt.ex` (27, 45-53, 150-179, 385-430, 575-600, 717-729), `twin_journey.ex` (730-750), `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `twin_preflight.ex` (80-150), `script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json`, `script/check_exunit_ownership.exs`, and the v25 test files named in the triage.
- Executed in the candidate: the checker with bad argv (exit 0, three cases), `Path.wildcard` versus `:filelib.fold_files` on a fixture, Agent-on-dead-pid exit reasons, the 45-file scanner prototype, counts 249/12/23/11.
- `/private/tmp/crosswake-phase180-run`: `gate-184-13.sh`, `mutate-184-13.sh`, `mutation-184-13.log`, `baseline-184.failures` (one line), `baseline-184.exit` (2), `baseline-184.full.out` ("2399 tests, 1 failure (78 excluded)"), `real-probe-184-13.out`.
- `<home>/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/185-.../185-CONTEXT.md`, `REQUIREMENTS.md` (GUARD-01..03 text), `184-14-PLAN.md` (gate conventions), `.planning/seeds/SEED-023-extend-scope-cardinality-gate.md`.

### Secondary / Tertiary
- None; no web or Context7 research was needed (stdlib behaviour verified by running).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new.
- Architecture and current code: HIGH, read and run.
- Loop triage: MEDIUM; the committed scan plus the green/red runs finalize it.
- Pitfalls: HIGH for the verify_twin fixture fallout and the clean-tree ordering (read the code paths), MEDIUM for example-host executability.

**Research date:** 2026-10-16
**Valid until:** until the candidate moves off `b898e110` (line numbers are commit-specific); otherwise stable.
