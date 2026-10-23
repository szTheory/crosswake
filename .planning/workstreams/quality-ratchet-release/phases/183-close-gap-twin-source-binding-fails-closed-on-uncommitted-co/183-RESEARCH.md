# Phase 183: Close gap: twin source binding fails closed on uncommitted code - Research

**Researched:** 2026-10-15
**Domain:** Elixir proof-lane runner (git cleanliness guard), candidate-tree commit sequencing, evidence rerun (twin-04)
**Confidence:** HIGH (code paths read this session; git/Elixir behavior executed in a scratch repo)

All paths below are in the candidate `/private/tmp/crosswake-phase180-impl` (HEAD `da53c54db06e54be5a80fb4be144a70d3fed36a5`, tree `d1cbbe30ffca9da79c5506004ad2bf8c8da38665`, git 2.41.0, Elixir 1.19.5 / OTP 27 from `.tool-versions`) unless noted. Read-only there. [VERIFIED: `git rev-parse`, `git --version`, `.tool-versions`]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01 through D-20 in `183-CONTEXT.md` are the spec, copied by reference (the file is the authority; the planner must read it in full). Summary of the code-bearing ones:

- **D-01** Fail closed on any modified, staged, deleted, renamed or untracked non-ignored path. No working-tree digest. No bypass flag.
- **D-02** One probe: `git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -C <candidate> status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none`. `{"",0}` clean; `{non_empty,0}` -> `{:blocked, :source_dirty}`; anything else -> `{:blocked, :prerequisite_missing}`.
- **D-03** `-c core.excludesFile=/dev/null` required; a `.git/info/exclude` with any non-comment line is `:source_dirty`.
- **D-04** Scrub env for the probe AND the existing `git/2`; `stderr_to_stdout: false` for the probe; rescue `:enoent`.
- **D-05** Git-ignored paths are not dirty.
- **D-06** `freeze/3` is the single authority; probe after the HEAD/tree `same/2` checks and BEFORE `backend_digest`.
- **D-07** `observe_identities/2` re-probes after the last build/run step and re-reads HEAD/tree before and after; `source` and `installed_build` set only if clean and unchanged.
- **D-08** Add `:source_dirty` to `@causes`; mid-run dirty must surface `source_dirty` as first cause.
- **D-09** Keep exit codes (blocked = 2).
- **D-10** Plain-language output, typed count, no paths anywhere.
- **D-11** Refuse a run root inside the candidate tree.
- **D-12** Add the fidelity limit "a source edit made and reverted during a run is not detected".
- **D-13/D-14/D-15** Real-git fixtures, the listed negative controls, fixture fix first, `async: false`, one manual mutation check.
- **D-16..D-20** Per-plan `feat(180-NN)` commits then one last `fix(183-NN)` commit in the candidate; script-generated `twin-04-candidate.json`; append-only history (`183-IDENTITY.json`, annotation sidecar, `183-TWIN-RESULT.json`); new `preflight-04.sh` / `run-once-04.sh`; one run into `twin-04`.

### Claude's Discretion
Helper naming (e.g. `clean_tree/2`), exact wording polish of the D-10 copy, how Phase 180 work splits across per-plan commits, and whether `prepare-record.sh` reuses a small Elixir helper or plain shell.

### Deferred Ideas (OUT OF SCOPE)
- Snapshot-clone run source (closes the D-12 fidelity limit structurally).
- Twin join against the Phase 179 identity/settings projections (`twin_journey.ex:20` hardcodes bundle id `org.crosswake.twin`).
- Other audit debt: 181/182 review findings; the `study-session` route_id label; Nyquist VALIDATION gaps; unknown twin-02 case 3 stall cause.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TWIN-01 | Twin receipt attests the code that ran (source join) | Guard in `freeze/3` + re-probe in `observe_identities/2`; clean-tree probe verified empirically; commit sequencing puts Phase 180 code into the attested tree |
| TWIN-05 | Receipt names causes/limits, fails closed | `:source_dirty` cause atom, `next_action` clause, fidelity limit, exit 2 path (see "Cause flow") |
| TWIN-06 | Run is one-shot into a new root, result reconciles with delivered source | twin-04 prepared-record script, preflight, run-once wrapper, append-only supersede records |
</phase_requirements>

## Summary

The change is small in product code (one guard function, one atom, one fidelity string, one run-root check, one `next_action` clause) and large in sequencing and evidence work. All 60 Phase 180 paths in the candidate are uncommitted (13 modified, 47 untracked); they must all be committed per plan BEFORE any Phase 183 edit, because `twin_producers.ex`, its test, `twin_receipt.ex`, `twin_runtime.ex` and `verify_twin.ex` are themselves untracked, so the 183 guard edit must land as a diff on a committed file. [VERIFIED: `git status --porcelain=v1 --untracked-files=all`, 60 records]

The empirical probe results match D-02/D-03/D-05 with one correction that matters for planning: a file hidden only by `.git/info/exclude` returns an EMPTY porcelain result (exit 0). The status probe cannot see it, so the D-03 rule needs a separate read of `.git/info/exclude` (via `git rev-parse --git-path info/exclude`), exactly as D-03 already says; it is not covered by D-02 alone. [VERIFIED: scratch repo, section "Probe results"]

Two decisions as worded cannot be implemented literally; both have an in-spirit implementation, listed under Blocking/Needs-decision findings. Neither blocks planning.

**Primary recommendation:** Commit the 60 Phase 180 paths per plan first (working tree clean), then implement `TwinProducers.clean_tree/2` (public, injectable `git_cmd`), call it from `freeze/3` and from the journey's post-run identity step, return `{:blocked, :source_dirty}` on both paths so the existing `blocked_receipt/2` writes the receipt, and fix the test fixture before adding the new `describe "source cleanliness"`.

## Blocking / Needs-Decision Findings

None of these makes a locked decision unimplementable in intent. B1 and B3 change HOW a decision is realized.

**B1 (D-08 mechanism as worded does not work; intent achievable).** D-08 says "the producer emits the cause on the source observation." There is no source observation. `TwinReceipt.derive/3` always overwrites roster id `TW-T10-02` with its own `identity_observation/2` (cause is `:identity_unknown` when any join is blocked), so the runner producer's `TW-T10-02` emission (`twin_producers.ex:886`, `emit_runner`) is discarded. [VERIFIED: twin_receipt.ex:280-285 `by_id = Map.put(by_id, @identity_join_roster_id, join_obs)`; twin_receipt.ex:529-545 `identity_observation`]
  - Consequence: if `observe_identities/2` merely omits `source`, the receipt says `identity_unknown`, never `source_dirty`.
  - Recommended realization (uniform for freeze-time and mid-run): the journey returns `{:blocked, :source_dirty}` from its produce function; `conduct/2` already routes `{:blocked, cause}` to `blocked_receipt/2` (verify_twin.ex:118-120), which writes a full all-blocked receipt whose first cause is `<first roster id> source_dirty`. `observe_identities/2` still omits `source`/`installed_build` when dirty or moved (D-07, keeps unit tests simple), and the journey additionally asks `clean_tree/2` and short-circuits to the blocked return. The alternative `TwinRuntime.record_failure(runtime, :source_dirty)` (twin_runtime.ex:168) only changes the printed first cause (first_cause_text, verify_twin.ex:257) and leaves the receipt at `identity_unknown`; use it only if a mid-run block must keep the other 48 observations.

**B2 (D-10 typed `measure` has no home in the current receipt path).** `blocked_receipt/2` hardcodes `measure: nil` (verify_twin.ex:150-158) and `derive` forces `measure: nil` on `TW-T10-02` (twin_receipt.ex:543). `measure_ok/1` allows an integer 0..1_000_000 (twin_receipt.ex:699-702), so storing a count is schema-legal. [VERIFIED: files above]
  - Recommended minimal plumbing that keeps the `{:blocked, atom}` shape D-14 tests assert: in `blocked_receipt/2`, when `cause == :source_dirty`, call `TwinProducers.dirty_count(runtime.candidate_path)` (a thin wrapper over the same probe; returns an integer or `nil`) and set `measure: count` on each blocked observation. The printed first-cause line then needs the count from the same call. Do NOT widen the tuple to three elements.
  - If the planner prefers not to touch `blocked_receipt/2`, the fallback is count-in-stdout only, which conflicts with "not in a string"; surface it as an explicit decision.

**B3 (D-12 adds a literal-checked fidelity limit; old receipts stop validating).** `TwinReceipt.validate/1` compares `fidelity_limits` against `@fidelity_limits` by literal equality (`literal(receipt.fidelity_limits, @fidelity_limits, "TW-RCPT-LIMITS", :limits)`, twin_receipt.ex:341). Adding the fifth string means twin-01..03 `receipt.json` files (4 limits) fail `TwinReceipt.decode/1` under the new code. [VERIFIED: twin_receipt.ex:57-62, 341]
  - Planning consequences: (1) never re-verify the old twin-03 receipt through the new code; the D-18 annotation uses sha256 of `180-TWIN-RESULT.json` only. (2) STATE.md currently pins the four limit strings and `180-07-PLAN` writes `fidelity-limits.txt` from the result; the 183 summary/STATE must list five. (3) `twin_receipt_test.exs` should get one assertion that the list has the new entry. (4) The D-12 string is mixed with existing lowercase "noun phrase" style; keep `"source edit made and reverted during a run not detected"`-style consistency, wording is discretionary.

**B4 (D-04 `stderr_to_stdout: false` leaks stderr).** With `stderr_to_stdout: false` the child's stderr is inherited by the BEAM, not discarded. Git prints the absolute repo path on a dubious-ownership failure, which would land in `twin-04.stderr`. [VERIFIED: scratch run, `System.cmd("sh", ["-c","echo LEAKED_PATH >&2; echo out"], stderr_to_stdout: false)` put `LEAKED_PATH` on the VM's stderr; git `GIT_TEST_ASSUME_DIFFERENT_OWNER=1` printed `fatal: detected dubious ownership in repository at '<abs path>'`]
  - Recommended: run the probe through `System.cmd("sh", ["-c", ~S(exec "$@" 2>/dev/null), "sh", "git" | args], ...)` (verified to suppress: second scratch call printed nothing to captured stderr). `sh` is POSIX on macOS and ubuntu CI. Keep `git/2` (stderr_to_stdout: true, captured and trimmed) as is except for env scrubbing.

**B5 (D-03 info/exclude is invisible to status).** See probe table: `.git/info/exclude` hidden file => `status` empty, exit 0. The extra read is mandatory, not optional. Use `git rev-parse --git-path info/exclude` (verified output `.git/info/exclude` relative to `-C`) and count lines not matching `^\s*(#|$)`. The candidate has 0 such lines. [VERIFIED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Clean-tree probe + freeze gate | Runner library (`TwinProducers`) | Mix task (surfaces cause) | `freeze/3` is already the single identity authority (D-06) |
| Mid-run re-probe | Runner library (`TwinJourney` calls `TwinProducers`) | — | Only the journey knows the "after last step" moment |
| Closed cause + copy | `TwinReceipt` (`@causes`, `@fidelity_limits`) | Mix task (`next_action`) | Closed atom set is the privacy boundary |
| Run-root-inside-candidate refusal | `TwinRuntime.prepare/1` | — | Run root and candidate path are both known only there |
| Prepared record, preflight, run wrapper | Evidence shell scripts in `/private/tmp/crosswake-phase180-run/` | — | One-time evidence tooling, not product (D-17/D-19) |
| Supersede/annotation records | Planning artifacts (`.planning/.../phases/180-*/`, 183 dir) | — | Append-only history (D-18) |

## Standard Stack

No new dependencies (locked). Everything uses `System.cmd/3`, `File`, `Jason` (already a dependency), ExUnit, `git`, `sh`, `shasum`, `jq`.

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| Elixir / OTP | 1.19.5 / 27.3 | runtime and tests | `.tool-versions` [VERIFIED] |
| git | 2.41.0 | probe, fixtures | `git --version` [VERIFIED] |
| ExUnit `@tag :tmp_dir` | stdlib | fixture dirs | already used in other suites; none in the twin tests today [VERIFIED: grep] |

**Package Legitimacy Audit:** No external packages installed in this phase. `slopcheck`/`package-legitimacy` not applicable. Packages removed: none. Packages flagged: none.

## Architecture Patterns

### Current code map (candidate, exact)

`lib/crosswake/proof_lane/twin_producers.ex` [VERIFIED: Read this session]
- `@spec freeze(TwinRuntime.t(), Path.t(), keyword())` at 627; `def freeze(runtime, identity_path, opts \\ [])` at 628. Current `with` chain: `read_identity` 631, `git(path, ["rev-parse","HEAD"])` 632, `git(path, ["rev-parse","HEAD^{tree}"])` 633, `same(head, runtime.candidate_head)` 634, `same(tree, ...)` 635, `lock_digests` 636, `file_digest(study_js)` 637, `backend_digest(runtime, path, opts)` 638. Insert the probe between 635 and 636... but D-06 says BEFORE `backend_digest`; putting it directly after 635 also precedes `lock_digests`, which is cheaper and fine. The `else` at 668-671 passes `{:blocked, _} = blocked` through and maps everything else to `:identity_unknown`, so a probe returning `{:blocked, :source_dirty}` flows unchanged. A bare `:ok` result must be returned on clean (the `with` clause needs `:ok <- ...`).
- `defp read_identity/1` 672; `defp same/2` 685 (`:identity_mismatch`); `defp git/2` 687-692: `System.cmd("git", ["-C", path | args], stderr_to_stdout: true)`, `{out,0}` -> `{:ok, String.trim(out)}`, else `{:blocked, :prerequisite_missing}`. No env scrub, no `rescue` for `:enoent` (an `ErlangError{original: :enoent}` raises; verified on Elixir 1.19.5).
- `defp lock_digests/1` 694; `defp backend_digest/3` 731; `defp write_expectations/2` 772 (writes `expectations.json` into `run_root` at 772-778, AFTER freeze succeeds).
- `@spec observe_identities(map(), map())` 794; `def observe_identities(frozen, live)` 795; HEAD/tree reads at 797-798 via `ok_or_nil(git(...))`; `source:` at ~806 `if(head && tree, do: TwinReceipt.identity_digest([head, tree]))`; `installed_build:` (needs `head && tree`) ~824-831; `backend_build:` also uses `head && tree`. `defp ok_or_nil/1` 852-853.
  - Note: `backend_build` and `dependency_lock` joins are not gated by D-07 in the locked text, but `backend_build` uses `head`/`tree` in its digest. If `head`/`tree` become nil on a moved HEAD, `backend_build` also goes absent. Acceptable (fails closed); document it in the test.
  - The existing test "a tracked media fixture that no longer matches the identity fails TW-T10-02" (twin_producers_test.exs ~528-541) writes `"tampered media"` into a tracked fixture, which makes the fixture repo dirty. After D-07 `source` and `installed_build` go absent in that test, so `by_id(runner(...))["TW-T10-02"].outcome` would become `:blocked`, not `:failed` (`identity_result` returns `:missing` before `:fail`? No: any `:fail` wins over `:missing` at twin_producers.ex:893-897, and `installed_media` still mismatches, so it stays `:failed`). Verify once after implementing; do not assume.
- `@spec runner(map(), map(), [map()])` 865; `identity_result/2` 889-903 ("fail beats missing beats pass").
- `emit_runner` 1096; `attrs/2` 1099-1110 maps results to `{outcome, cause}`; always `measure: nil`.

`lib/crosswake/proof_lane/twin_journey.ex`
- Only call site of `observe_identities`: line 711 (`observed = TwinProducers.observe_identities(ctx.frozen, live)`), inside the function that returns `{:ok, observed, all}`. This is the "after last build/run step" moment for D-07. The producers are called on 713-718 from `inputs`. Tool resolution list at ~211 includes `git`.
- `-derivedDataPath` is `Path.join(ctx.run_root, "dd")` and `-resultBundlePath` is under `ctx.run_root` (twin_journey.ex:64-67). This is why D-11 is a correctness requirement, not hygiene: a run root inside the candidate would put DerivedData into the tree. [VERIFIED]

`lib/crosswake/proof_lane/twin_receipt.ex`
- `@causes` list lines 21-40 (19 atoms, last `:cause_not_retained` at 39; closing `]` at 40). Add `:source_dirty` (before `:cause_not_retained` is conventional). `safe_cause/1` at 192-194 maps unknown to `:cause_not_retained`.
- `@fidelity_limits` lines 57-62; `fidelity_limits/0` 179-180; literal validation at 341; projection copy at 421 and 771.
- `freeze_expectations/1` 206 (spec 209 region); `first_cause/1` 432-442 (sorts failed first, then first non-passed); `identity_observation/2` 529-545; `evaluate_joins/2` 497-511; `measure_ok/1` 699-702.

`lib/crosswake/proof_lane/twin_runtime.ex`
- `prepare/1` line 58-85: `run_root(opts[:run_root])` -> `not_reused(root)` -> `candidate_record(opts[:candidate])` -> `database_path` -> `origin_port` -> `acquire_origin`. D-11 belongs immediately after `candidate_record` (both paths known) and before `database_path`. `run_root/1` 299-313 only `Path.expand`s (no symlink resolution). `candidate_record/1` 330-345 and `candidate_fields/1` 360-385 validate shape and 40-hex head/tree only. `record_failure/2` 168-175 (atom only, `TwinReceipt.safe_cause`), `first_failure/1` 161-164.
- Symlink caveat for D-11: on macOS `/tmp` is a symlink to `/private/tmp`; `Path.expand` does not resolve it. A run root given as `/tmp/x/...` would not string-match a candidate path `/private/tmp/...`. Do the containment test by walking the run root's ancestors and comparing `File.stat/1` `major_device` + `inode` against the candidate directory's, which is symlink-proof and needs no realpath helper. [ASSUMED: macOS `/tmp` -> `/private/tmp` is standard; the candidate path in the prepared record is already the `/private/tmp` form.]

`lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`
- `exit_status_for/1` delegated at 85-86. `journey_plan/2` 106-120 (freeze -> `{:blocked, cause}` pass-through). `conduct/2` ~118-129: `{:blocked, cause} -> blocked_receipt(runtime, cause)` for both plan and produce results; `finish/4` ~131-140; `blocked_receipt/2` ~144-178 (safe_cause, zero digests, all blocked, `measure: nil`, `TwinRuntime.record_failure`, prints cause atom string); `first_cause_text/2` 257-262; `next_action/2` 271-278 has three clauses keyed on `overall_status` (passed/failed/blocked). `summarize/4` 282-.. prints exactly four lines: `result:`, `first cause:`, `report:`, `next action:`.
  - Adding `next_action` for `:source_dirty`: the blocked-receipt call passes `next_action(receipt, cause)` where the second arg is the cause atom, so add a clause BEFORE the generic blocked clause: `defp next_action(%{overall_status: :blocked}, :source_dirty), do: "..."`. It is reachable from `blocked_receipt/2` (cause arg) and from `finish/4` (first failure atom).
  - The D-10 first-cause copy ("The candidate has N uncommitted or untracked files.") is a new sentence in the `first cause:` line; today that line is `"#{id} #{cause}"`. Decide with B2 whether the line stays machine-style (`TW-T01-01 source_dirty`) plus count, or becomes prose. The existing test at verify_twin_test.exs:435 "producer results and public strings stay closed" constrains public strings; re-read it before choosing.

### Cause flow (freeze -> printed output)

```
verify_twin ios --candidate R --run-root D --identity I
  TwinRuntime.prepare            (D-11 refusal here -> {:error, %{cause: :prerequisite_missing, action: ...}} -> summarize(:blocked,...) exit 2, NO receipt)
  conduct(runtime, plan)
    plan.(runtime) = journey_plan -> TwinProducers.freeze/3
        clean_tree/2 -> {:blocked, :source_dirty} | {:blocked, :prerequisite_missing} | :ok
    {:blocked, cause} -> blocked_receipt(runtime, cause)   # writes receipt.json + twin-result.json, exit 2
    {:ok, expectations, produce}
       produce.() = TwinJourney.run -> (build, canary, c1..c5) -> observe step:
            re-probe + HEAD/tree reads -> {:blocked, :source_dirty} (recommended) | {:ok, observed, all}
       {:blocked, cause} -> blocked_receipt(runtime, cause)
       {:ok, observed, obs} -> finish/4 -> TwinReceipt.derive -> write_and_verify -> summarize (exit by overall status)
  summarize prints 4 lines; run/1 halts with the code
```
Exit code: blocked => 2 via `TwinReceipt.exit_status_for` (no change, D-09). `blocked_receipt` failing for a cause not in `@causes` is why D-08 matters: `safe_cause(:source_dirty)` currently returns `:cause_not_retained`. [VERIFIED: twin_receipt.ex:192-194]

Note for D-11 and the preflight: prepare errors happen before any receipt exists, so a run root inside the candidate yields exit 2 and no `receipt.json` (same as the existing "missing run root" cases at verify_twin_test.exs:101).

### Recommended structure for the new code

```elixir
# twin_producers.ex (public so tests and the journey can call it)
@spec clean_tree(Path.t(), keyword()) :: :ok | {:blocked, :source_dirty | :prerequisite_missing}
def clean_tree(path, opts \\ []) do
  git_cmd = Keyword.get(opts, :git_cmd, &System.cmd/3)   # narrow injection, D-13
  ...
end
```
- Env list (D-04) as `{name, nil}` pairs plus `{"GIT_OPTIONAL_LOCKS","0"}`, `{"GIT_CONFIG_NOSYSTEM","1"}`, `{"GIT_TERMINAL_PROMPT","0"}`, `{"LC_ALL","C"}`. `{name, nil}` unsets (verified, Elixir 1.19.5: `System.cmd("sh", [...], env: [{"GIT_DIR", nil}])` printed `GD=unset` with `GIT_DIR=/nonexistent` in the parent; docs: "Specify a value of `nil` to clear (unset) an environment variable") [VERIFIED: scratch run + hexdocs System.cmd/3].
- Optional hardening not in D-04: add `-c core.fsmonitor=false` (accepted by git 2.41, verified exit 0) so a repo-local `core.fsmonitor` hook command is never executed by the probe, and unset `GIT_PREFIX`. Both are additive; flag to the planner as optional.
- Count: `String.split(out, <<0>>, trim: true)` minus the second field of each rename/copy record (a record starting with `R` or `C` in column 1 or 2 consumes the next field). Never use content for anything but the count (D-02).
- `.git/info/exclude`: `git rev-parse --git-path info/exclude` (run through the same scrubbed helper), `File.read`, count lines that are not blank/`#` comments; missing file = clean. Any non-comment line -> `:source_dirty` (count it as 1 for the user-facing count or add the line count; planner choice; do not print the line).

### Anti-Patterns to Avoid
- Parsing porcelain entries for meaning (D-02). Counting records is the only exception.
- `stderr_to_stdout: true` on the probe (corrupts the `-z` stream) AND bare `stderr_to_stdout: false` (leaks the path to the inherited stderr; B4).
- `diff --quiet` + `ls-files --others` (races, takes `index.lock`).
- Faking porcelain output in tests (AGENTS.md "invented happy-path fixture" lesson).
- Writing the run root, identity file, or database into the fixture repo (self-dirtying).
- Committing any 183 edit before every Phase 180 path is committed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dirty detection | working-tree digest, temp-index `write-tree`, per-file stat walker | `git status --porcelain=v1 -z` | Only git applies tracked/ignore/exclude semantics; digest is rejected by D-01 |
| Realpath for D-11 | custom symlink resolver | ancestor walk comparing `File.stat` device+inode | No realpath in Elixir stdlib; inode compare is exact |
| Record JSON writes | custom serializer | `Jason` (already a dep) / `jq` in shell | Existing code uses both |
| Atomic record write | in-place write | write temp file `0600` then `mv -n` / `File.rename` | D-17 atomic rename + refuse overwrite |

## Probe results (scratch repo; git 2.41.0)

Scratch repo: `/private/tmp/claude-501/-Users-<user>-projects-crosswake/8037453f-f79e-49b4-9162-9e5c9f8a44cb/scratchpad/probe/r` with an isolated `HOME` and `XDG_CONFIG_HOME` (global ignore listing `hidden_by_global.txt`). Script: `.../scratchpad/probe.sh`. All run with the exact D-02 flag set. [VERIFIED: executed]

| Case | Output (NUL shown as `|`) | Exit | Matches |
|------|---------------------------|------|---------|
| clean | empty | 0 | D-02 clean |
| untracked file | `?? u.txt|` | 0 | dirty |
| staged-only modify | `M  a.txt|` | 0 | dirty |
| deleted file (unstaged) | ` D a.txt|` | 0 | dirty |
| staged rename | `R  b.txt|a.txt|` (two fields, count 1) | 0 | dirty; count rule |
| ignored by `.gitignore` | empty | 0 | D-05 |
| hidden only by XDG global ignore, default `git status` | empty | 0 | D-03 premise |
| same file, probe with `core.excludesFile=/dev/null` | `?? hidden_by_global.txt|` | 0 | D-03 |
| same file, `GIT_CONFIG_GLOBAL=/dev/null` only | empty | 0 | D-03 "does NOT show it" confirmed |
| hidden only by `.git/info/exclude` | empty | 0 | NOT caught by probe; separate read required (B5) |
| non-repo path | (stderr) | 128 | -> `:prerequisite_missing` |
| dubious ownership (`GIT_TEST_ASSUME_DIFFERENT_OWNER=1`) | stderr with absolute path | 128 | -> `:prerequisite_missing`; path leaks unless stderr is discarded (B4) |
| `GIT_DIR=/nonexistent git rev-parse HEAD` | `fatal: not a git repository` | 128 | leaked `GIT_DIR` redirects git; scrub confirmed necessary |
| `GIT_CONFIG_COUNT/KEY_0/VALUE_0` | `core.excludesFile=/dev/null` honored | 0 | env-injected config works, so unset COUNT/PARAMETERS as D-04 says |

Against the real candidate (read-only probe): 60 NUL records, equal to the default `git status` count of 60; `~/.config/git/ignore` contains only `**/.claude/settings.local.json` and hides nothing in the candidate; `.git/info/exclude` has 0 non-comment lines; `core.excludesFile` unset; `core.autocrlf` unset. [VERIFIED]

## Candidate status: Phase 180 paths grouped by plan (for the D-16 commit sequence)

Source: `git status --porcelain=v1 --untracked-files=all` (60 records), 180 `files_modified` (PLAN frontmatter) and SUMMARY key-files/deviations. Commit per plan in order; "M" = modified tracked, everything else untracked.

**180-01** (`feat(180-01)` or `test(180-01)`; gate tests)
- `test/crosswake/proof/phase180_twin_feasibility_test.exs`
- `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift`

**180-02**: no product paths (planning files only).

**180-03** (receipt/runtime/command skeleton; files later extended by 180-06 but only one version exists on disk)
- `lib/crosswake/proof_lane/twin_receipt.ex`, `lib/crosswake/proof_lane/twin_runtime.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`
- `test/crosswake/proof_lane/twin_receipt_test.exs`, `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`

**180-04** (web island + observation surfaces)
- M `examples/phoenix_host/priv/static/offline_study.js`, M `.../offline_html/index.html.heex`, M `.../controllers/offline_controller.ex`, M `.../lib/crosswake_example/router.ex`, M `.../e2e/replay_authority.ex`, M `.../local_first/sync_controller.ex`, M `examples/phoenix_host/e2e/offline_sync.spec.ts`, M `examples/phoenix_host/test/crosswake_example/page_title_test.exs`
- new: `.../e2e/twin_fault_controller.ex`, `.../offline_html/review.html.heex`, `e2e/offline_accessibility.spec.ts`, `e2e/offline_recovery.spec.ts`, `test/crosswake_example/e2e/twin_fault_controller_test.exs`

**180-05** (generated iOS host)
- M `examples/phoenix_host/config/config.exs`
- Under `examples/phoenix_host/native/ios/crosswake_shell/`: `.crosswake/ios_host_generation.json`, `.crosswake/shell.json`, `CrosswakeHostSettings.xcconfig`, `CrosswakeShell.xcodeproj/project.pbxproj`, `CrosswakeShell/CrosswakeCoordinator.swift`, `CrosswakeShell.entitlements`, `CrosswakeShellApp.swift`, `Info.plist`, `PrivacyInfo.xcprivacy`, `StudyAudioCommandDelegate.swift`, `StudyPackInstaller.swift`, `StudyWebViewController.swift`, `TwinObservationLog.swift`, `CrosswakeShellTests/StudyAudioCommandDelegateTests.swift`, `CrosswakeShellTests/StudyWebViewControllerTests.swift`, `Fixtures/{crosswake_manifest,declared_pack_requirements,installed_packs,pack_inventory,route_activation,route_denial}.json`, `README.md`
  (the 180-05 plan lists the whole `crosswake_shell/` directory; these generator outputs are part of the digest-bound shell, so they belong in the tree)

**180-06** (run machinery)
- `lib/crosswake/proof_lane/twin_fault_boundary.ex`, `twin_journey.ex`, `twin_producers.ex`
- `test/crosswake/proof_lane/twin_fault_boundary_test.exs`, `twin_journey_test.exs`, `twin_producers_test.exs`
- `.../crosswake_shell/CrosswakeShell/TwinHostDriver.swift`, `CrosswakeShellUITests/TwinJourneyUITests.swift`, `CrosswakeShellUITests/TwinCaptureCanaryUITests.swift`, `TwinJourney.xctestplan`, `CrosswakeShellUnit.xctestplan` (deviation 6), `CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme`

**180-07**
- M `guides/see_it_run.md` (the "Run the Reference Twin (Simulator)" section; 180-07 PLAN `files_modified`)

**Paths that belong to no plan's `files_modified` (flag; do not commit silently)**
- M `script/collection_assertion_ledger.json`, M `script/inventory_collection_assertions.exs`, M `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`: the vacuous-assertion ledger update caused by the new 180-03..180-06 twin tests (the 180-07 plan text at line 70 explains: "Seven now have in-place guards... ledger and its pinned totals were regenerated (243 sites)"). Recommend one `test(180-07): classify twin collection assertions in the ledger` commit that goes AFTER the 180-06 commit (ledger entries reference twin test line numbers, so the ledger must match the final committed test content) and BEFORE the 183 fix. Decision for the planner: this is the only group that is not a plan deliverable. [VERIFIED: diff read]
- M `examples/phoenix_host/priv/static/offline_study.js` belongs to 180-04 even though 180-07's identity/digest binds to it.

**Generated/build artifacts that must NOT be committed.** None appear in the 60 records. Ignored and absent from status: `_build/`, `deps/`, `examples/phoenix_host/{_build,deps,node_modules,playwright-artifacts,crosswake_example.db*}` (`.gitignore` lines 24-25, 28, 68 confirmed by `git check-ignore -v`; `playwright-artifacts/` and the sqlite files are listed by `git ls-files --others --ignored --exclude-standard`). [VERIFIED] The xcodebuild DerivedData/result bundle land in the run root (`dd`, `*.xcresult`), outside the tree.

Sequencing hazard: because `git add` must be explicit paths (never `-A` or `.`), and `git commit` author is already `szTheory <szTheory@users.noreply.github.com>`, the safest procedure is a status-driven script that stages each plan's list, commits, and finally asserts `git status --porcelain=v1 --untracked-files=all` is empty before touching a single 183 file. Commit style in the candidate log: `test(182-05): ...`. Co-Authored-By trailer per the session reminder.

Also note commit sizes: the generated `project.pbxproj` and `Fixtures/*.json` are digest-bound; commit them byte-identical (no `mix format`, no line-ending conversion). Run `git diff --stat` equals-zero against the pre-commit worktree hashes: record `git hash-object` of the manifest/activation/study_js/media before committing and compare to the prepared-record digests afterwards (this is what `preflight-04.sh` does from committed bytes).

## Test infrastructure (candidate)

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5), `test/test_helper.exs` with default excludes `requires_example_host`, `engine_present`, `collateral_binaries`, `advisory_only` |
| Async | All twin suites `use ExUnit.Case, async: false` (twin_producers_test.exs:2, verify_twin_test.exs:2). Keep. |
| Existing tmp pattern | `System.tmp_dir!()` + random suffix + `on_exit(File.rm_rf)`; no `@tag :tmp_dir` in the twin suites. ExUnit `:tmp_dir` creates under `<cwd>/tmp/...`, which is git-ignored by `/tmp/` (`.gitignore:68`), so fixtures never dirty the candidate; either pattern is fine. Using `System.tmp_dir!()` keeps D-11 trivially satisfied in tests that go through `prepare/1`; a `:tmp_dir` fixture living INSIDE the candidate tree would trip the new D-11 check in any test that sets `run_root` there. Prefer `System.tmp_dir!()` or put the run root elsewhere. |
| Quick run | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/crosswake/proof_lane/twin_journey_test.exs test/crosswake/proof_lane/twin_fault_boundary_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` |
| Full suite | `cd /private/tmp/crosswake-phase180-impl && mix test --exclude requires_example_host` (CI form, crosswake-ci.yml:425) |
| Related contract gates | `mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`; `mix crosswake.docs.sync --check` |

**Baseline recorded this session (read-only, no file changes; worktree/diff hashes before and after identical; `_build` is gitignored):**
- Five twin files: **72 tests, 0 failures** (2.3 s). `twin_producers_test.exs` alone: **24 tests, 0 failures**. [VERIFIED: ran]
- `test/crosswake/guides` + phase69 + phase170 ledger: **218 tests, 0 failures**, `mix crosswake.docs.sync --check` passed. [VERIFIED: ran]
- Full suite not rerun. The 180-07 plan text records the full candidate suite as 2374 tests with 1 failure, the intended Phase 180 G1 gate test (it fails because the seam exists). Treat that single failure as a known pre-existing baseline, not a regression. [CITED: 180-07-PLAN.md:70; not re-verified]

Test-structure facts the planner needs:
- `describe "freeze/3 and observe_identities/2"` starts at twin_producers_test.exs:418; its `setup` (418-~490) builds the fixture repo with plain `System.cmd("git", ...)`, writes `identity-N.json` INTO the repo AFTER the commit (inside the `identity` closure, `Path.join(dir, "identity-#{...}.json")`), and `runtime(dir)` (defined at 582-593) sets BOTH `run_root: dir` and `candidate_path: dir`. Both are self-dirtying once the guard exists: identity files are untracked; `freeze` writes `expectations.json` into `run_root` (= the repo). Fix per D-15: put identity files and the run root in a sibling directory (e.g. `Path.join(dir, "..")`-style separate temp), keeping the repo path distinct as `candidate_path`.
- Local helper `defp git(dir, args)` is defined inside the describe at 492-493 (asserts exit 0, stderr merged). `live/2` helper at 495.
- Existing tests use positional `{:blocked, :identity_unknown}` pattern matches (lines 515-519, 524): a new guard must not change the order of existing `identity_unknown` checks, so run it after the `read_identity` clause and the `same/2` checks.
- Mix-task suite: `setup` creates `base/candidate` (NOT a git repo) with a `mix.lock`, a `run` dir with 0700, and `record(ctx)` writes a 0600 candidate record with fake `@head`/`@tree`. Producers are injected via `producers:` (functions `{:ok, observed, observations}` or `{:blocked, cause}`), so the freeze guard is not exercised in the mix-task suite; D-15's mix-task case is "injected producers return `{:blocked, :source_dirty}` -> non-passing receipt, exit 2, plain-language cause". Template: the child_timeout first-cause test at verify_twin_test.exs:368 and the blocked-journey test at 396. A D-11 case belongs next to 101/182 ("missing or non-private run root...", "database path outside run root").
- Fixture git isolation (D-13): `HOME` = tmp dir, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` fixed, `-c user.name/user.email`, `commit.gpgsign=false`, `core.autocrlf=false`. Remember to also put `XDG_CONFIG_HOME` in the tmp dir for the "global excludes" case: the scratch run needed it to simulate a user-global ignore without touching the real `~/.config/git/ignore`. The probe itself must not read it (that is the point of the `-c core.excludesFile=/dev/null` control). Because the probe's env is built inside `clean_tree/2` and the test can only set env in its own process, the "global excludesFile still blocks" test must set `XDG_CONFIG_HOME`/`HOME` with `System.put_env` in the test (restore in `on_exit`) so `System.cmd` inherits it; `async: false` makes that safe.
- Collection-assertion ledger gate (IMPORTANT, Wave 0): `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` pins `@audited_site_count 243`, shape counts and bucket counts. Any new test line of the form `assert Enum.all?`, `refute Enum.any?`, `assert Enum.any?`, or similar collection-shaped assertions changes the count and fails that suite until `script/collection_assertion_ledger.json` and the pinned totals are regenerated. Write new 183 assertions as exact-value/equality assertions (`assert result == {:blocked, :source_dirty}`, `assert count == 3`) to avoid ledger churn; if unavoidable, regenerate the ledger in the same `fix(183-NN)` commit and re-run the phase170 suite.

## Common Pitfalls

### Pitfall 1: Committing the guard before the Phase 180 files
**What goes wrong:** The 183 edit shows up as a new-file addition inside the 180-06 commit; history no longer proves the guard is a separate fix and `git merge-base --is-ancestor <fix> HEAD` (D-19) is trivially true for the wrong reasons.
**How to avoid:** Commit all 60 Phase 180 paths (plus the ledger group) first; assert empty porcelain; then edit.

### Pitfall 2: The guard fails the existing "clean" tests
**What goes wrong:** Every existing freeze test turns `:source_dirty` (identity file in repo, run_root = repo).
**How to avoid:** D-15 fixture fix is task 1 of the test plan, verified green before adding the guard.

### Pitfall 3: Self-dirtying by the run itself
**What goes wrong:** Anything the twin run writes into the candidate (xcodebuild DerivedData, result bundles, `expectations.json`, the DB) trips the mid-run probe.
**Evidence it is safe today:** derived data and result bundles go to `ctx.run_root` (`twin_journey.ex:64-67`); the candidate still shows exactly the 60 Phase 180 records after twin-03 ran (no stray untracked output); example host `_build`/`deps`/`*.db*` are ignored. [VERIFIED]
**Residual risk:** an untracked, non-ignored file produced by `mix` under `MIX_ENV=test` (e.g. regenerated `.crosswake/*` or fixtures from `gen.shell`) would block twin-04. Mitigation: `preflight-04.sh` runs `mix crosswake.gen.shell ios --check` (read-only) and the probe; additionally run the full twin build preflight once in a dry state and re-probe before `run-once-04.sh`. Do not run the real twin to find out; reason from the twin-03 post-run status above.

### Pitfall 4: Staged-vs-committed digests
**What goes wrong:** Prepared record digests computed from the worktree can differ from committed bytes (autocrlf, mode, or an edit after commit).
**How to avoid:** D-17 computes from `git show HEAD:<path> | shasum -a 256`; the probe guarantees worktree == HEAD.

### Pitfall 5: Counting rename records twice
**How to avoid:** Two-field rename/copy records (verified `R  b.txt|a.txt|`); test it (staged rename case).

### Pitfall 6: Mid-run block loses the observation set
**What goes wrong:** Recommended B1 return discards the 48 other observations of a run that was otherwise fine. Acceptable (fail closed, rerun with a new root), but document it in the test name and the plan so nobody reads it as a regression.

### Pitfall 7: `Path.expand` vs symlinked temp roots in D-11
See the inode-walk recommendation under `twin_runtime.ex`.

### Pitfall 8: Old receipts fail new validation (B3)
Do not run `TwinReceipt.decode` on twin-01..03 artifacts after the change.

## Code Examples

Probe helper skeleton (shape only; names are discretionary):

```elixir
# Source: D-02/D-04 in 183-CONTEXT.md; behavior verified in a git 2.41.0 scratch repo
@git_scrub_env (for n <- ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
                            GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE
                            GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT
                            GIT_CONFIG_PARAMETERS GIT_PREFIX), do: {n, nil}) ++
               [{"GIT_OPTIONAL_LOCKS", "0"}, {"GIT_CONFIG_NOSYSTEM", "1"},
                {"GIT_TERMINAL_PROMPT", "0"}, {"LC_ALL", "C"}]

# stderr discarded inside the shell wrapper so a dubious-ownership message cannot leak a path
defp probe(git_cmd, path) do
  args = ["--no-optional-locks", "-c", "core.excludesFile=/dev/null", "-c", "core.quotePath=false",
          "-C", path, "status", "--porcelain=v1", "-z", "--untracked-files=all",
          "--ignore-submodules=none"]
  try do
    git_cmd.("sh", ["-c", ~S(exec "$@" 2>/dev/null), "sh", "git" | args],
             env: @git_scrub_env, stderr_to_stdout: false)
  rescue
    ErlangError -> :git_unavailable
  end
end
# {"", 0} -> clean ; {out, 0} -> {:blocked, :source_dirty} ; {_, _} / :git_unavailable -> {:blocked, :prerequisite_missing}
```
Note: if `sh` itself is missing, `System.cmd` raises `:enoent` the same way (rescued). If the injectable `git_cmd` is used in the "git unavailable" test, make the stub raise `ErlangError{original: :enoent}` and also return `{"fatal", 128}` for the non-repo case; use real git for the non-repo case (D-13).

`System.cmd/3` `env:` nil-unset, verified output on Elixir 1.19.5 with `GIT_DIR=/nonexistent` in the parent: `{"GD=unset\n", 0}`. [VERIFIED: scratch run]

## State of the Art / Prior art (already decided, recorded for the plan's rationale)
Go `vcs.modified`, Nix `dirtyRev`, cargo `--allow-dirty`, SLSA/in-toto append-only statements are cited by D-01/D-18. Not re-researched; user-locked.

## Runtime State Inventory (partial rename/migration-adjacent: run-record supersede)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `/private/tmp/crosswake-phase180-run/twin-01..03/` roots, `.stdout/.stderr/.exit/.started`, `twin-run-count.before` (value 2), `twin-run-path` (points at twin-03), `twin-02-candidate.json` (mode 0600, head `da53c54...`) | Leave byte-identical (D-18); create new `twin-04-candidate.json`; `twin-run-count` for the preflight becomes 3 before the run (record it, do not edit the old file) |
| Live service config | none (no external services) | None |
| OS-registered state | Possible leftover `crosswake-phase180-*` simulators and port 4790 listeners | `preflight-04.sh` checks both (D-19) |
| Secrets/env vars | none for the product; shell env may carry `GIT_*` | Scrub in `clean_tree/2` and `git/2` |
| Build artifacts | Candidate `_build` (ignored), example host `_build`/`deps`/`node_modules` (ignored) | None; remain outside the clean probe by `.gitignore` |

`twin-run-path` currently holds the twin-03 path; the new wrapper must not overwrite it silently (write a `twin-run-path-04` or append, planner decision; keep old files untouched per D-18).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | probe, fixtures | yes | 2.41.0 | none needed |
| Elixir/OTP | tests | yes | 1.19.5 / 27.3 | none |
| sh, shasum, jq | scripts | yes (jq used by existing 180-07 gate) | system | none |
| Xcode / simulator | twin-04 run (execution phase only) | not probed here (forbidden to run) | — | preflight checks; the 180-05/06/07 summaries show it worked on this host |
| CI ubuntu leaf with git | new tests | yes per D-15 (git preinstalled) | — | none |

Not probed this session by instruction: simulators, xcodebuild, port 4790.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit, Elixir 1.19.5 / OTP 27, run in the candidate |
| Config file | `test/test_helper.exs` (default excludes; no change needed) |
| Quick run command | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs test/crosswake/proof_lane/twin_receipt_test.exs` |
| Full suite command | `cd /private/tmp/crosswake-phase180-impl && mix test --exclude requires_example_host` (expect only the known G1 gate failure from 180-07-PLAN.md:70) |
| Baseline before change | 72 tests / 0 failures (five twin files); 218 / 0 (guides + phase69 + phase170) |

### Phase Requirements -> Test Map

| Req / Decision | Behavior | Test Type | Automated Command | File Exists? |
|----------------|----------|-----------|-------------------|-------------|
| TWIN-01, D-01/D-06 | clean candidate passes the guard; dirty (modified) blocks `:source_dirty` | unit, real git | `mix test test/crosswake/proof_lane/twin_producers_test.exs` | file yes; new describe "source cleanliness" Wave 0 |
| D-02 | staged-only, deleted, untracked, rename each block; counts exact | unit, real git | same file | no (new) |
| D-03 | file hidden only by global excludesFile still blocks; `.git/info/exclude` non-comment line blocks | unit, real git, `System.put_env` for HOME/XDG | same | no (new) |
| D-05 | `.gitignore`-ignored file does not block | unit, real git | same | no (new) |
| D-04 | `GIT_DIR` set in the test process pointing at a different repo does not redirect HEAD/tree/probe | unit | same | no (new) |
| D-04 / B4 | git missing (injected `git_cmd` raising enoent) -> `:prerequisite_missing`; non-repo path -> `:prerequisite_missing` (real git); no stderr text escapes (`ExUnit.CaptureIO.capture_io(:stderr, ...)` is empty) | unit | same | no (new) |
| D-07 | dirty after freeze => `source` and `installed_build` absent from `observe_identities/2` | unit | same | no (new) |
| D-07 | HEAD moved after freeze (new commit) => join absent | unit, real git | same | no (new) |
| D-07/D-08/B1 | journey/producers path returns `{:blocked, :source_dirty}`; runner outcome never passed | unit (journey stub or producers) | `mix test test/crosswake/proof_lane/twin_journey_test.exs` | file yes; case new |
| TWIN-05, D-08 | `:source_dirty` is in `@causes`; `safe_cause(:source_dirty) == :source_dirty` | unit | `mix test test/crosswake/proof_lane/twin_receipt_test.exs` | file yes; case new |
| TWIN-05, D-09/D-10 | injected producers `{:blocked, :source_dirty}` -> receipt non-passed, exit 2, 4 printed lines, first cause names `source_dirty`, next action text, no paths | unit | `mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | file yes; case new |
| D-10 privacy | file named with marker `zz-leak-marker-<rand>` absent from `inspect(result)`, `expectations.json`, `receipt.json`, `twin-result.json`, captured stdout/stderr; count lands in `measure` | unit, real git | both files | no (new) |
| D-11 | run root inside candidate (including via a symlink alias) -> exit 2 `prerequisite_missing`, no receipt | unit | verify_twin_test.exs | no (new) |
| D-12 / B3 | `fidelity_limits/0` includes the new string; receipt round-trips with 5 limits | unit | twin_receipt_test.exs | case new |
| D-14 twin-03 shape | untracked twin files + modified tracked files at the recorded head/tree blocks | unit, real git | twin_producers_test.exs | no (new) |
| D-15 | existing freeze tests still green after the fixture fix (identity/run_root outside repo) | unit | twin_producers_test.exs | edit |
| TWIN-06, D-16 | `git merge-base --is-ancestor <fix> HEAD`; porcelain empty at run time | shell (`preflight-04.sh`) | `bash /private/tmp/crosswake-phase180-run/preflight-04.sh` | Wave 0 (new script) |
| TWIN-06, D-17 | prepare-record.sh refuses dirty tree, refuses overwrite, mode 0600, digests from `git show` | shell self-test on a scratch repo | `bash prepare-record.sh --selftest` or a scratch-repo smoke | Wave 0 |
| TWIN-06, D-18/D-20 | result reconciliation: `cmp 183-TWIN-RESULT.json twin-04/twin-result.json`; `receipt_sha256` equals sha256 of `receipt.json`; old 180 artifacts byte-identical (sha256 manifest taken before) | shell/jq | verification step | Wave 0 |

### Negative controls (each must FAIL if its guard is removed; D-14 manual mutation check)
Run once, record in verification, do not make a permanent lane:
1. Delete the `clean_tree` call in `freeze/3` -> dirty-modified, staged-only, deleted, untracked, global-excludes, info/exclude, twin-03-shape cases all fail.
2. Remove `-c core.excludesFile=/dev/null` -> the global-excludesFile case fails.
3. Remove the `.git/info/exclude` read -> the info/exclude case fails.
4. Remove env scrubbing -> the `GIT_DIR` redirect case fails.
5. Remove the post-run re-probe / HEAD-tree reads in `observe_identities/2` or the journey -> the dirty-after-freeze and HEAD-moved cases fail.
6. Remove `:source_dirty` from `@causes` -> the receipt and mix-task first-cause cases fail (`cause_not_retained`).
7. Remove the D-11 check -> the run-root-inside-candidate case fails.
8. Replace the shell stderr wrapper with bare `stderr_to_stdout: false` -> the no-stderr-leak case fails.
Each control proves non-vacuity; also assert the clean case passes in the same test module so the controls are not "always blocked".

### Sampling Rate
- Per task commit: quick run command above.
- Per wave merge: full suite command; plus the guides/docs/phase170 gate set and `mix crosswake.docs.sync --check`.
- Phase gate: full suite green except the known G1 gate test; `preflight-04.sh` exit 0; twin-04 `exit 0` with receipt `passed`; `cmp` of the copied result.

### Wave 0 Gaps
- [ ] New `describe "source cleanliness"` in `test/crosswake/proof_lane/twin_producers_test.exs` (and the D-15 fixture fix first).
- [ ] New cases in `twin_receipt_test.exs` (cause atom, fidelity limit) and `crosswake_proof_lane_verify_twin_test.exs` (blocked first cause, exit 2, privacy, D-11).
- [ ] `prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh` in `/private/tmp/crosswake-phase180-run/` (plus a scratch-repo smoke test for the first).
- [ ] Phase170 ledger: avoid new collection-shaped assertions or regenerate the ledger in the same commit (see above).
- [ ] Framework install: none.

## Security Domain

`security_enforcement` is not disabled in the workstream config (treated as enabled). Local developer tool, no network service or user data; ASVS applicability is narrow.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | none |
| V3 Session Management | no | none |
| V4 Access Control | partial | file modes: prepared record 0600, run root 0700 (already enforced in `candidate_record/1` and `run_root/1`) |
| V5 Input Validation | yes | closed atom set for causes (`safe_cause/1`); argv list (no shell interpolation of the candidate path) |
| V6 Cryptography | no new use | existing SHA-256 via `:crypto`/`shasum`; do not hand-roll |
| V7 Logging / Data protection | yes | no paths or file names in stdout, artifacts, receipt, logs (D-10) |

### Threat model inputs

| Threat | STRIDE | Mitigation | Test |
|--------|--------|------------|------|
| Absolute path or file name leaks via git stderr, porcelain bytes, or `inspect(result)` | Information disclosure | discard stderr in the wrapper (B4); never print probe output; return counts/atoms only | marker file test, stderr-capture test |
| Env-injected `GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE`/`GIT_CONFIG_*` redirects HEAD/tree to another repo or turns off excludes | Tampering / Spoofing | env scrub list (D-04) for BOTH `git/2` and the probe | `GIT_DIR` redirect test |
| Repo-local `core.fsmonitor` or hook-ish config executes code during `status` | Elevation / Tampering | optional `-c core.fsmonitor=false`; candidate currently has none | optional probe test |
| Run root inside the candidate (self-dirtying, or an attacker-controlled dir shadowing the candidate) | Tampering | D-11 inode-walk refusal | D-11 test |
| Prepared-record overwrite or stale record reuse (twin-02 record used for twin-04) | Tampering / Repudiation | `prepare-record.sh` refuses overwrite, 0600 atomic write, prints old vs new; preflight recomputes digests from `git show` and compares | script smoke test |
| Edit-then-revert between the two probes (TOCTOU) | Tampering | ACCEPTED: documented as a fidelity limit (D-12); structural fix deferred | fidelity-limit string test |
| `.git/info/exclude` hides a dirty file | Tampering | explicit non-comment-line check (B5) | info/exclude test |
| Dirty identity labeled as authoritative | Repudiation | fail closed, no digest (D-01) | all dirty cases |
| Old passing result (`180-TWIN-RESULT.json`) misread as current | Repudiation | annotation sidecar + `183-TWIN-RESULT.json` supersede (D-18) | verification `cmp`/sha checks |
| Adopter identity | Information disclosure | use "first adopter" only; `guides/see_it_run.md` must keep `grep -c B2C == 0` (180-07 check) | existing guide gates |

## Guide edit (D-16)

`guides/see_it_run.md` section "Run the Reference Twin (Simulator)" is lines 161-184 in the candidate (heading at 161, "Prerequisites:" paragraph at 172-176, "What the receipt proves" 182-184, next section "Go Deeper" at 186). Add the one sentence to the Prerequisites paragraph: "The candidate tree must be clean at the recorded head; a dirty tree is refused." The edit lands in the `fix(183-NN)` commit. The guide is also covered by `test/crosswake/guides/*` and `mix crosswake.docs.sync --check`; both passed on the current candidate guide, rerun after the edit. Authoritative-tree reconciliation of the guide stays out of scope (180-07 "pending reconciliation", sha `3e1263b5...` will change; the STATE.md "Guide pending reconciliation" line must be updated to the new sha in the 183 handoff). [CITED: 180-07-SUMMARY.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | macOS `/tmp` -> `/private/tmp` symlink makes `Path.expand` containment unreliable, so use inode walk | twin_runtime.ex notes | Low: inode walk is correct either way |
| A2 | `sh` is available and POSIX on both macOS and ubuntu CI leaves | B4 | Low; fallback: pass a `git_cmd` that opens a Port without stderr |
| A3 | Ledger-update paths belong in a commit after 180-06 and before the 183 fix | Candidate status | Medium: planner may prefer folding into 180-07; only ordering vs the twin test files matters |
| A4 | `GIT_PREFIX` and `core.fsmonitor=false` hardening is worthwhile | Code examples | Low; optional |
| A5 | Full-suite baseline "2374 tests, 1 failure (G1 gate)" from 180-07-PLAN.md:70 still holds | Test infrastructure | Low; rerun the full suite at the start of execution to refresh |
| A6 | Mid-run whole-run block (B1) is acceptable to the user vs keeping the other 48 observations | B1 | Low; both are fail-closed |

## Open Questions

1. **B2 count plumbing.** Choose between the `dirty_count/1` re-probe inside `blocked_receipt/2` (recommended) and stdout-only count.
   - What we know: `measure` accepts an integer 0..1_000_000; `derive` forces `measure: nil` on `TW-T10-02`, `blocked_receipt` sets nil on all.
   - Recommendation: re-probe in `blocked_receipt/2` for `:source_dirty` only.
2. **First-cause line wording.** Keep `"<id> source_dirty"` (machine style, current format) and put the sentence in `next action`, or print the D-10 prose. Re-read the closed-strings test at verify_twin_test.exs:435 first.
3. **Where to commit the ledger update** (A3).
4. **Whether `twin-run-count`/`twin-run-path` get new `-04` files** rather than edits, to honor D-18 byte-identical history.

## Sources

### Primary (HIGH)
- Candidate source read this session: `twin_producers.ex` (freeze 613-681, git 685-692, observe 785-860, runner 860-1110), `twin_receipt.ex` (1-70, 180-340, 425-545, 695-705), `twin_runtime.ex` (40-120, 278-385), `twin_journey.ex` (55-80, 205-220, 690-725), `crosswake.proof_lane.verify_twin.ex` (60-300), both test files (read in part), `guides/see_it_run.md` diff, `.gitignore`.
- Executed in scratch: git status probe matrix; `System.cmd` env nil-unset and stderr inheritance on Elixir 1.19.5.
- Elixir docs `System.cmd/3` (https://elixir.hexdocs.pm/System.html): nil clears an env var.
- Phase 180 SUMMARY/PLAN files for plan-to-file grouping; `/private/tmp/crosswake-phase180-run/` scripts and record shape.

### Secondary (MEDIUM)
- git docs for `status --porcelain=v1 -z`, `core.excludesFile`, `info/exclude` semantics: behavior confirmed empirically on 2.41.0 rather than re-read from git-scm.com.

### Tertiary (LOW)
- None used for decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new deps.
- Architecture/code map: HIGH, line numbers read this session (re-verify after the 180 commits, since line numbers do not change from committing but will shift after edits).
- Pitfalls: HIGH for B1-B5 (each verified), MEDIUM for Pitfall 3 residual risk.

**Research date:** 2026-10-15
**Valid until:** until the candidate HEAD changes from `da53c54` (the first `feat(180-NN)` commit moves it; re-run the head/tree capture after the commit sequence, before writing `twin-04-candidate.json`).

Note on read-only compliance: no files in the candidate or the recovery checkout were changed. `mix compile`/`mix test` wrote only gitignored `_build` output (worktree and diff hashes identical before and after). A few `git status` calls without `--no-optional-locks` may have refreshed the candidate index's stat cache (`.git` mtime changed); no tree content changed.
