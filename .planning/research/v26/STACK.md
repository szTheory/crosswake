# Technology Stack (mechanisms): v26.0 Harden Before Trust

**Project:** Crosswake, workstream `quality-ratchet-release`
**Researched:** 2026-10-15
**Candidate read (read-only):** `/private/tmp/crosswake-phase180-impl` @ `50fcd57`. Every `file:line` below is in the candidate, not in the recovery checkout.
**New dependencies:** none. Everything is git, Elixir stdlib, ExUnit, and copy-paste.
**Overall confidence:** HIGH on git behaviour (read from git-scm.com and reproduced on local git 2.41.0); MEDIUM on ExUnit idioms (hexdocs recalled, not re-fetched).

---

## 1. Clean-tree probe (closes WR-01, WR-02, and two more holes)

### 1.1 What the candidate does today

`lib/crosswake/proof_lane/twin_producers.ex`:

| Line | What |
|------|------|
| 690-709 | `@git_scrub_env`: unsets `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_CONFIG`, `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS` etc.; sets `GIT_OPTIONAL_LOCKS=0`, `GIT_CONFIG_NOSYSTEM=1`, `LC_ALL=C`. **`GIT_CONFIG_GLOBAL`, `HOME`, `XDG_CONFIG_HOME` are not touched.** |
| 716-722 | `run_git/2`: `sh -c 'exec "$@" 2>/dev/null'`, rescues only `ErlangError`. |
| 759-792 | `probe/2`: one `git status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` with `-c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false`, plus `exclude_rules/2` counting active lines in `.git/info/exclude`. Returns `{:ok, status_records, exclude_rules}`. |
| 739-745 | `clean_tree/2`: `:ok` only when both counts are 0. |
| 917-925 | `observe_identities/2` calls `clean_tree(path)` **with no `git_cmd`** (IN-01: a second, un-injectable probe). |
| 989-994 | `checked_identities/3`: probes once, then `observe_identities` probes again. |

The comment at 735 ("any modified, staged, deleted ... path") and the disposition's claim of isolation overstate what the argv enforces.

### 1.2 Verified git semantics (primary: git-scm.com; reproduced on git 2.41.0 in a scratch repo)

- **`git ls-files -v` tags** (git-ls-files docs, `-t`/`-v`): `H` tracked, not unmerged and not skip-worktree; `S` skip-worktree; `M` unmerged; `R` unstaged removal; `C` unstaged modification; `K` file/dir conflict; `?` untracked; `U` resolve-undo. `-v` is `-t` with **lowercase for assume-unchanged** files (so `h`); `-f` lowercases for fsmonitor-valid. `-z` gives NUL-terminated, unquoted `"<tag> <path>"` records. `-t`'s `C`/`R` tags only appear when the corresponding option (`-m`/`-d`) is in play; plain `-v` on a clean index emits `H`/`h`/`S`/`M`.
- **assume-unchanged** (git-update-index docs): the user "promises not to change the file"; Git "omit[s] any checking and assume[s] it has not changed". So `git status` and `git diff-index` both skip the lstat/content check. Reproduced: a modified file with the bit set is absent from `status --porcelain`, and shows as `h` in `ls-files -v`.
- **skip-worktree** (same page): Git treats the file "as unchanged when it is not present" and "will avoid treating the lack of such files as an intentional deletion". Reproduced: modified file with the bit set is absent from `status`; shows as `S`. The sparse-checkout machinery can set this bit legitimately, so `S` is also how a sparse checkout hides content. For a candidate that must equal its commit, any `S` is dirty.
- **`core.filemode=false`** (reproduced): a `chmod -x` is invisible to `status`; `git -c core.filemode=true status` shows ` M run.sh`. A `-c` flag beats repo config, global config, and system config (reproduced: repo set to false, `-c core.filemode=true` read back as true). Neither `status` nor `ls-files -v` flags the mode change with filemode off, so `-c core.filemode=true` is the only fix; a post-hoc `ls-files` check does not help.
- **Important negative result (reproduced):** `-c core.filemode=true` does **not** reveal assume-unchanged or skip-worktree content changes. The two fixes are independent and both required.
- **`git update-index --refresh` / `--really-refresh`** (docs): `--refresh` only re-matches stat info; it "does not calculate a new sha1 file". `--really-refresh` "checks stat information unconditionally, without regard to the assume unchanged setting", but it also **sets** assume-unchanged bits on matching paths, i.e. it writes the index. Do **not** use either in the probe. The probe is read-only by design (`--no-optional-locks`, `GIT_OPTIONAL_LOCKS=0`).
- **Racy timestamps:** `git status` re-hashes content when an index entry's mtime is not strictly older than the index file's (racy-git, git technical docs; recalled, not re-fetched, MEDIUM). Because the probe is `status` and not a bare stat comparison, no extra step is needed. Do not add a `diff-index` second opinion: `diff-index` honours the same assume-unchanged/skip-worktree bits, so it adds no coverage.
- **`core.fsmonitor`:** already pinned `false` at line 766. Keep. With fsmonitor off, `ls-files -f` lowercase tags are irrelevant; use `-v`, not `-f`.
- **Global/system excludes:** `-c core.excludesFile=/dev/null` already neutralises the global ignore (including the `$XDG_CONFIG_HOME/git/ignore` default, which `core.excludesFile` overrides). `.git/info/exclude` cannot be switched off by `-c`, which is why the candidate counts its active lines. That design is sound; keep it. `.gitignore` files are tracked content, so they are part of the commit and need no handling.
- **`core.ignorecase` on APFS:** only matters for case-only renames. A case-only rename shows as nothing under `ignorecase=true`. Low risk for this candidate; not worth an argv change. **Unverified**; record as an accepted residual in the requirement, do not build for it.

### 1.3 Holes found (ranked)

| # | Hole | Candidate evidence | Verified how |
|---|------|--------------------|--------------|
| WR-01 | assume-unchanged / skip-worktree hide edits | No `ls-files` call anywhere in `probe/2`. | Reproduced locally |
| WR-02 | repo or global `core.filemode=false` hides mode-only edits | No `-c core.filemode=...`; global config is read because `GIT_CONFIG_GLOBAL` is unset. | Reproduced locally |
| NEW-A | Global config is otherwise unpinned. `GIT_CONFIG_NOSYSTEM=1` covers only `/etc/gitconfig`; `~/.gitconfig` and `$XDG_CONFIG_HOME/git/config` still apply (e.g. `core.attributesFile`, `core.untrackedCache`, `status.*`). | env list at 690-709 | Reading the code; git-config docs |
| NEW-B | Empty `ls-files` output must not mean "clean". Once the new call exists, an empty/failed read has to be `:unavailable`, otherwise the fix reintroduces the vacuity it closes. | n/a (design point) | Design |
| NEW-C | `$GIT_DIR/info/attributes` is not examined, though `.git/info/exclude` is. Attributes (`filter`, `eol`, `text`) can make a changed file compare clean. | `exclude_rules/2` is the only info/ file read | **Unverified exploit.** Cheap to cover with the same helper; make it a stretch item, not a blocker |
| IN-01 | `observe_identities/2` re-probes without `git_cmd` | lines 924 vs 990 | Reading the code |

### 1.4 Minimal exact change

**Env** (`@git_scrub_env`): add `{"GIT_CONFIG_GLOBAL", "/dev/null"}`. `GIT_CONFIG_GLOBAL` needs git >= 2.32 (release notes, recalled; **unverified by fetch**). Local git is 2.41.0; the test below proves the pin works rather than trusting a version number. Keep `GIT_CONFIG_NOSYSTEM=1`. Do not set `HOME` (other tooling in the same process may need it).

**Common pins**, extracted to one module attribute used by both calls:

```elixir
@git_pins [
  "--no-optional-locks",
  "-c", "core.excludesFile=/dev/null",
  "-c", "core.quotePath=false",
  "-c", "core.fsmonitor=false",
  "-c", "core.filemode=true",          # WR-02
  "-c", "core.untrackedCache=false"    # belt and braces; unverified need
]
```

`core.sparseCheckout` need not be pinned: the `S` tag in step 2 is what catches it.

**Second argv** (`probe/2`, WR-01):

```elixir
["-C", path, "ls-files", "-v", "-z"]
```
(pins first, then `-C`, matching the existing status call). Parse the NUL-split output; a record is `<<tag, ?\s, _path::binary>>`.

```elixir
defp flagged_entries(out) do
  records = String.split(out, <<0>>, trim: true)
  # NEW-B: zero tracked entries can never be "clean". Fail closed.
  if records == [], do: :error, else: {:ok, Enum.count(records, &(not match?(<<?H, ?\s, _::binary>>, &1)))}
end
```

Rule: **every tag except `H` is dirty** (this counts `h`, `S`, `M`, and anything git adds later; an allow-list of one letter is the fail-closed choice, a deny-list of letters is not). Count only; never return a path (matches the existing "output is only counted" contract).

**Return shape:** `probe/2` returns `{:ok, status_records, flagged, exclude_rules}`. `clean_tree/2` is `:ok` only if all three are 0. `dirty_count/2` sums them (WR-03: keep the three counts apart internally so the CLI message can say which class tripped; do not suggest `git status` when `status_records == 0`).

**IN-01:** pass `Keyword.take(opts, [:git_cmd])` into `observe_identities/3` (or have `checked_identities` pass its own verdict in) so there is exactly one probe path. Do not add a new public arity unless needed.

**IN-04:** broaden the `rescue` in `run_git/2` to `[ErlangError, ArgumentError]` and return `:unavailable` without interpolating the message.

**What NOT to add:** `--ignored` to `status` (the twin compiles the example host into the candidate, so ignored `_build` output is expected and would make every run dirty); `update-index --refresh` or `--really-refresh` (writes the index); a `diff-index` second probe (same blind spots); a libgit/NIF dependency; a `.gitconfig` parser.

### 1.5 Tests (real temp git repos; no mocks of git)

Reuse `repo_fixture/1` in `test/crosswake/proof_lane/twin_producers_test.exs:418` (already inits a real repo, already sets `GIT_CONFIG_GLOBAL=/dev/null` for fixture-building at 501-502) and extend `describe "source cleanliness"` (621). Each new test follows the existing pattern: mutate, assert `clean_tree == {:blocked, :source_dirty}` and a **count** from `dirty_count`, then assert a control.

1. `update-index --assume-unchanged tracked_file`, then modify it. Control: `git status --porcelain` is empty (proves the hiding is real, so the test is not vacuous). Assert blocked, `dirty_count == 1`. Do the same with `--skip-worktree`.
2. `git config core.filemode false` in the repo, then `chmod -x`/`+x` a tracked file. Control: plain `git status` is empty. Assert blocked.
3. Global config: write a temp file with `[core] filemode = false`, run the production call with the test process env pointing `GIT_CONFIG_GLOBAL` at it; the scrubbed env must override it. Assert blocked on a mode change and, separately, that clean repos stay `:ok` (guard against the pin breaking the happy path).
4. Zero-tracked-entries repo (`git init`, empty commit allowed with `--allow-empty`): `clean_tree` must be `{:blocked, :prerequisite_missing}`, not `:ok` (NEW-B).
5. `git_cmd` stub that returns `{"", 0}` for `ls-files` only: must block, not pass.
6. Message test for WR-03: with only an exclude rule present, the CLI text must not tell the user to run `git status`.
7. Mutation control for the new guard (repo convention, see 2.3): revert the `ls-files` call in a temp copy or stub it out, and show test 1 goes red. Record in the phase's `mutation-<phase>.log` as phase 183 did.

---

## 2. Non-vacuous assertions and the SEED-018 state

### 2.1 What is already done for SEED-018 (verified)

- Phase 170 audited the population and corrected the seed's count: the true set is the four shapes `assert_all`, `assert_any`, `refute_any`, `refute_all` (header of `script/inventory_collection_assertions.exs`, 861 lines). `assert Enum.any?` is non-vacuous by construction.
- `script/collection_assertion_ledger.json` has **243 rows** in the candidate (135 safe-by-construction, 63 safe-guarded, 41 safe-cardinality-pinned, 4 safe-compile-time-literal; zero `needs-fix`). `script/collection_assertion_remediation.json` has 52 rows and is closed-world and frozen at `0fb0b862`.
- `elixir script/inventory_collection_assertions.exs --check` in the candidate exits 0: "243 classified ... ledger matches the live tree exactly". Phase 180 refreshed it (`736a7d7`), so v25 test code is already in the ledger.
- v25 test files have **8 ledger rows**, none unclassified: `phase180_twin_feasibility_test.exs:40`, `twin_fault_boundary_test.exs:219`, `twin_producers_test.exs:80,265`, `twin_receipt_test.exs:54`, `crosswake_proof_lane_verify_twin_test.exs:269,294,338`.
- The deferred part is **VACG-01**: `absence.collection_assertion_non_empty` in `script/check_absence_is_not_success.exs`. The ledger test only proves every site has a row; it never proves a site is guarded (D-06). The ledger's own `sunset` note says to lift the detection core into the guard and delete the three scaffolding files.

### 2.2 The real v25 gap: the inventory explicitly does not scan `for` or `Enum.each`

Header D-02 of the inventory excludes `for` comprehensions, `Enum.each`, `Enum.reduce` accumulators, and `Stream` chains. v25 uses `for` heavily. Candidate sites where the generator is runtime-derived and no emptiness assertion sits in front of the loop body (verified by reading each):

| Site | Generator | Verdict |
|------|-----------|---------|
| `test/crosswake/proof_lane/twin_receipt_test.exs:289` | `g["sub_observations"]` (decoded JSON) | **Vacuous if any group is empty.** Outer loop is pinned (`length == 10`, ids at 283-284); inner is not. |
| `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:553-560` (`blocked_pairs/1`) | roster-derived, decoded receipt | Callers at 578/595 compare `Enum.uniq == [{1, :source_dirty}]`, so an empty list fails there. Safe by downstream equality. |
| `examples/phoenix_host/.../phase180_twin_feasibility_test.exs:47` | `manifest["routes"]` | Later line asserts `routes["offline-study"]`, plus G6 control at 55-58 asserts a non-empty capability. Safe by sibling control. |
| `twin_producers_test.exs:72/77`, `twin_receipt_test.exs:36,110` | `TwinReceipt.roster()` / `identity_joins()` (compile-time constants) | Safe by construction; add no guard. |
| `twin_producers_test.exs:364-367` (`backend` list) | `Regex.scan` over a source file | **Pinned** by `assert length(backend) == 13` at 370. This is the model pattern. |
| `doctor_host_commands_test.exs:146` | `found` | Has an explicit comment and `codes(found) == [...]` pinning two findings. Safe. |

So the bounded v26 SEED-018 work is: (a) fix `twin_receipt_test.exs:289` with a pre-loop `assert [_ | _] = g["sub_observations"]` (or `refute g["sub_observations"] == []`), (b) leave the other sites, (c) do **not** run a repo-wide sweep. Evidence that repo-wide is not cheap: 243 ledger rows plus the unscanned `for`/`Enum.each` family the inventory chose not to measure.

### 2.3 Idioms and conventions already in the repo

- **Pre-loop floor**, in order of preference: `assert [_ | _] = list` (pattern match; failure message shows the value); `assert length(list) == N` when N is known (strongest: pins the exact count, the repo's `safe-cardinality-pinned` bucket); `refute Enum.empty?(list)`. Prefer exact-count over non-empty wherever the cardinality is stable, since non-empty still lets a collection silently shrink from 10 to 1.
- `Enum.any?` inside `assert` needs nothing; `refute Enum.any?(xs, ...)` needs a floor in front of it (that is why the ledger tracks `refute_any`).
- **Control tests** carry a tag: `@tag phase180_gate: "G6"` for the assertion and `@tag phase180_control: "G6"` for a sibling that proves the scan reads real data (`phase180_twin_feasibility_test.exs:38-58`). Follow this for new guards.
- **Mutation controls** assert that the mutation *changed* something (`absence.mutation_control_asserts_change`, `check_absence_is_not_success.exs`); phase 183 recorded eight in `mutation-183.log`.
- **Ledger non-vacuity tests** (phase170 test, 126-175) mutate a copy of the ledger and require `--check` to go red naming the row. A new guard for VACG-01 should copy this shape.

### 2.4 Self-vacuity in the absence guard itself (new finding)

`script/check_absence_is_not_success.exs` derives `test/**/*.exs` and the seeds/todos globs with `Path.wildcard` (lines 78-84, 178-187) and **prints OK twice and exits 0 when the glob matches nothing**. Verified by running it with `--root` at a path that does not exist: both `[crosswake] OK:` lines, `rc=0`. A wrong `--root`, a moved test tree, or a CI checkout in the wrong directory passes. This is the exact defect class the script polices. The sibling `script/check_exunit_ownership.exs:18-28` already has the right shape (`if paths == [] do fail(...)`). Fix: copy that floor into both derived lists, and also state the scanned counts in the OK lines ("scanned N test files"), so a count of 0 or a sudden drop is visible. Add a test that runs the script against an empty temp root and expects exit 1.

### 2.5 If a VACG-01 guard is added in v26

Only if the roadmap wants it. It must be restricted as SEED-018 step 3 says (collections derived from `Path.wildcard`, `File.read!`, `Regex.scan`, or an `Enum.filter` chain) and must start at zero findings, otherwise it becomes a waived guard. Measure first (AGENTS memory: "measure a check's findings before making it merge-blocking"). Lift the detection core from the inventory script; do not write a second classifier. Recommended default: **do not land the guard in v26**; fix the one known site, add the self-vacuity floor (2.4), and leave VACG-01 deferred with this evidence.

---

## 3. SEED-023 and `assertFullScope`

### 3.1 What it does (`scripts/ci_monitor.cjs:310-321`)

```js
function assertFullScope(actual, expected) {
  if (expected.length === 0) return { ok: false, reason: "expected scope is empty" };
  const expectedSet = new Set(expected);
  const isSubset = actual.every((file) => expectedSet.has(file));
  const isProperSubset = isSubset && actual.length < expected.length;
  if (isProperSubset) return { ok: false, reason: "actual scope is a proper subset of expected scope" };
  return { ok: true };
}
```

Two fail conditions: empty expectation, and `actual` strictly smaller than a re-derived `expected`. Callers: `checkActions` (line 331, default scope only) and the self-test `testCheckActionsScope` (373-400), which proves it red on a narrowed scope and green on equal scope. It is the only caller.

**Limits worth stating** (reading the code):
- `expected` is re-derived from the same discovery function. If discovery itself is too narrow (for example it only matches `*.yml`, not `.yaml`, and `action.yml` only), `actual` and `expected` shrink together and the gate passes. It protects against *drift between derivation and read*, not against a *wrong* derivation. A fixed floor or a pinned count is what covers the second case. Treat the guard as one half; the other half is an independent pin.
- If `actual` has files not in `expected` it returns ok. Probably fine, but note it is a subset check, not equality.

### 3.2 Sweep result (candidate, grep for derive-from-tree shapes in `script/`, `scripts/`, `lib/`)

| File | Shape | Class | Action |
|------|-------|-------|--------|
| `scripts/ci_monitor.cjs` `checkActions` | derive from `.github/` | derive, guarded | done |
| `script/check_absence_is_not_success.exs` | derive `test/**/*.exs`, seeds, todos | derive, **unguarded, proven vacuous (2.4)** | **fix: the real SEED-023 caller** |
| `script/check_exunit_ownership.exs:18` | derive `test/**/*_test.exs` | derive, has `paths == []` floor | none (model) |
| `script/inventory_collection_assertions.exs` | derive `test/**/*.exs`; ledger diff makes shrinkage visible | derive, covered by ledger equality | none |
| `script/check_release_workflow_integrity.exs` | **declared** `@roster_ids` | selector, must NOT be converted | none (reasoning already in `ci_monitor.cjs:271-276`) |
| `lib/crosswake/proof_lane/twin_producers.ex:886` `beam_digest/1` | derive `*.beam` | already `[] -> {:error, :no_beams}` | none |
| `lib/crosswake/proof_lane/twin_journey.ex:150-163` | cleanup globs, then residue check | cleanup, not an assertion; residue check searches only `*.xcresult` while cleanup removes eight patterns | note only; mismatched scope, not a green-on-nothing path |
| `lib/crosswake/doctor/doctor.ex:2244` `expand_globs/2` | derive from declared globs | feeds drift findings; not examined here | out of v25 scope; flag, do not fix |
| `script/verify_hex_tarball.sh`, `script/list_merge_blocking_checks.py`, `script/phase_evidence_path.py` | `find` / glob | **not read in this pass** | classify in the phase; unverified |

### 3.3 Recommendation: copy-paste, not a shared module

The seed itself says extract only if a *second real caller* exists. There is now exactly one second caller (`check_absence_is_not_success.exs`), and it is Elixir, not `.cjs`; a `.cjs` file cannot be imported from Elixir without spawning Node, which would add a runtime dependency to a pure-Elixir check. Therefore:

- Do **not** extract a shared module or a cross-language file.
- In `check_absence_is_not_success.exs`, add the Elixir equivalent, about six lines, mirroring the same semantics and keeping the `reason` strings parallel so a human can grep for both:

```elixir
defp assert_full_scope(actual, expected) do
  cond do
    expected == [] -> {:error, "expected scope is empty"}
    length(actual) < length(expected) and Enum.all?(actual, &(&1 in expected)) ->
      {:error, "actual scope is a proper subset of expected scope"}
    true -> :ok
  end
end
```
  (the `Enum.all?` on `actual` is guarded by the `length` comparison and by `expected == []` above, so it cannot be silently vacuous; add a comment saying so.)
- Add the self-test pattern from `testCheckActionsScope`: a test that feeds a deliberately narrowed list and an equal list and demands red then green.
- Add a **pinned floor** too, because of the limit in 3.1: for example "at least N test files" where N is measured from the tree at the time of writing and recorded in the test. This is the same `safe-cardinality-pinned` idea.
- Add one line to `scripts/ci_monitor.cjs`'s comment (or SEED-023's disposition) saying "second caller: `script/check_absence_is_not_success.exs`, Elixir copy, by design".

---

## 4. SEED-014 C / D / E / F against the candidate

| Item | State in candidate | Mechanism |
|------|--------------------|-----------|
| A (haptics assertion) | Deferred by 174-03. Reopen condition ("release pipeline proven end to end") is **not met**: Phase 175 ended with REL-10 breached. Keep deferred. | Record the evidence in the v26 disposition. |
| B | Closed (174-03). | none |
| C | Not re-checked in this pass. | Check `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` for the hardcoded `commit_ref` zeros. **Unverified.** |
| D | Not re-checked; the only UI item. | Needs the SwiftUI source; **unverified.** |
| **E** | **Still open.** `doctor.ex:379-388` builds the finding with `check/6` and no `details`. `Policy.Warning` (`lib/crosswake/policy/warning.ex:10-27`) **already carries** `unmanaged_paths` (sorted) and `module` as struct fields, so the data is available and no compiler change is needed. `JsonFormatter.check_to_map` (`json_formatter.ex:209-217`) already emits `details: check.details`. | Pass a fourth-argument map at the `check(...)` call: `%{unmanaged_paths: warning.unmanaged_paths, router: inspect(warning.module)}`. Atom keys serialize fine; the module must be a string (`nil` stays `nil`; do not call `Atom.to_string(nil)`, which returns `"nil"`). Paths are route templates, not user data, so no privacy filter needed, but keep them out of telemetry. Test: compile a router with an unmanaged route, run the JSON formatter, decode, and assert `details.unmanaged_paths` equals the sorted list (and assert the list is non-empty first). |
| **F** | **Still open.** `doctor.ex:469-472` filters on `cache_contract != nil or island_contract != nil` before the coherence `Enum.all?` at ~486; a `:local_first` route with no `island_contract` never reaches it. | **Seed's second option does not work as written.** The seed says compile-time rejection is "symmetric with the existing rule that `:cached_read_only` without a `cache_contract` is already invalid". In the candidate, `Policy.Route.validate_offline_contracts/1` (`route.ex:115-137`) only rejects the *reverse* direction (a contract on the wrong `offline` value). A route with `offline: :cached_read_only` and no contract is accepted. |

### 4.1 Recommended F fix (minimal, safe)

Change the filter at `doctor.ex:469-472` to `route.offline != :unavailable or route.cache_contract != nil or route.island_contract != nil`. The `Enum.all?` over `offline_routes` is then guarded by construction for the routes that claim offline behaviour. Then the existing `:cached_read_only -> cache_contract and not island_contract` clause will also start firing on cached-read-only routes without a `cache_contract`; that is correct, but it is a **behaviour change to expect** (some existing fixtures declare `offline: :cached_read_only` with no contract, for example `test/crosswake/router_test.exs:13,28`, `test/crosswake/router_defaults_test.exs:14`, and `crosswake_defaults runtime: :live_view, offline: :cached_read_only` in several doctor tests). Expect doctor-based tests to need an updated expectation or a contract in the fixture; count them before committing to the plan (run the doctor tests after the change).

The expression `route.island_contract` in the `:local_first` branch returns a struct/nil, not a boolean, but it is fine inside `Enum.all?`. Prefer `not is_nil(...)` for clarity if the line is touched.

**Do not** add the compile-time validation to `Policy.Route` in v26. It is a breaking change to a public DSL, there are 31 `offline: :local_first` occurrences across lib/test/examples (many multi-line, so not all can be classified by grep), and the project rule is to avoid contract breaks inside a hardening milestone. If the roadmap still wants it, make it a separate, explicitly breaking phase after a fixture audit. Note also that `new/1` already runs offline contract validation at compile time, so the place to add it later is `validate_offline_contracts/1` (`route.ex:115`), where the reverse direction already lives; the `new/1` and `new!/1` paths both call it.

Also add the F test as a three-part pair: (1) `:local_first` without `island_contract` now reports `offline_posture_incomplete`; (2) the same router with a contract reports `offline_posture_ready`; (3) a route with `offline: :unavailable` and no contracts is still excluded from the `routes` map. The pair proves the filter change did not just flip the verdict everywhere.

---

## 5. Integration order (for the roadmap)

1. Probe hardening (WR-01/02/03, IN-01/04, NEW-A/B): one file, `twin_producers.ex`, plus `twin_producers_test.exs` and the CLI message at the mix task. This is the only change that touches the twin-attested source, so it is the change that forces the `twin-05` run after it.
2. `check_absence_is_not_success.exs` scope floor + Elixir `assert_full_scope` copy + empty-root test (2.4, 3.3). Independent, no twin impact.
3. `twin_receipt_test.exs:289` pre-loop floor (2.2). Test-only.
4. Doctor E, then F (4). E is additive; F changes doctor verdicts on existing fixtures, so land it after E and run the doctor suite.
5. Defer: CW-REQ-A (condition unmet), compile-time F, VACG-01 as a standing guard, repo-wide sweep.

## 6. Confidence and gaps

| Item | Confidence | Note |
|------|------------|------|
| git tag letters, assume-unchanged, skip-worktree, `--really-refresh` | HIGH | fetched from git-scm.com; reproduced on 2.41.0 |
| `-c` beats repo/global config; `core.filemode` effect | HIGH | reproduced |
| `GIT_CONFIG_GLOBAL` minimum version (2.32) | MEDIUM | recalled; the proposed global-pin test proves it on the machine |
| Racy-git handled by `status` | MEDIUM | recalled from git technical docs |
| `info/attributes` can mask changes (NEW-C), `core.untrackedCache` need, `core.ignorecase` | LOW | not reproduced; labelled stretch or residual |
| ExUnit idioms | MEDIUM | `assert pattern = expr` documented at hexdocs.pm/ex_unit/ExUnit.Assertions.html (recalled, not re-fetched) |
| SEED-014 C, D | not checked | no evidence either way |
| Three `script/` files in 3.2 | not read | classify during the phase |

## Sources

- https://git-scm.com/docs/git-ls-files (tags, `-v`, `-f`, `-z`) fetched 2026-10-15
- https://git-scm.com/docs/git-update-index (assume-unchanged, skip-worktree, refresh) fetched 2026-10-15
- Local reproduction: scratch repo under the session scratchpad, git 2.41.0
- Candidate files named inline (`/private/tmp/crosswake-phase180-impl`, HEAD `50fcd57`)
- `.planning/workstreams/quality-ratchet-release/phases/183-*/183-REVIEW-DISPOSITION.md`; `.planning/seeds/SEED-014`, `SEED-018`, `SEED-023`
