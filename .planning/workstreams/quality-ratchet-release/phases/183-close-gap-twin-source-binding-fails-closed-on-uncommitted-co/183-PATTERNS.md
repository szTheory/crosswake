# Phase 183: Close gap: twin source binding fails closed on uncommitted code - Pattern Map

**Mapped:** 2026-10-15
**Files analyzed:** 13 new/modified
**Analogs found:** 13 / 13 (all in-file or sibling-file analogs; no external pattern needed)

All paths are relative to the candidate `/private/tmp/crosswake-phase180-impl` (HEAD `da53c54`) unless absolute. Run-root scripts are in `/private/tmp/crosswake-phase180-run/`. Line numbers were read this session and will not move from committing, but they shift after the first 183 edit.

**Tracked-source note (gate #3645):** the analog files (`twin_producers.ex`, `twin_receipt.ex`, `twin_runtime.ex`, `crosswake.proof_lane.verify_twin.ex` and both test files) are UNTRACKED in the candidate today (`git ls-files --error-unmatch` fails). They are the Phase 180 deliverables, not gitignored mirrors, and become tracked when the per-plan `feat(180-NN)` commits land. They are not install/runtime mirrors, so naming them is correct. The run-root scripts are evidence tooling outside any git tree. Every 183 edit must land after the Phase 180 commits, as a diff on committed files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/proof_lane/twin_producers.ex` (add `clean_tree/2`, harden `git/2`, guard in `freeze/3`, gate in `observe_identities/2`) | service/utility | request-response (subprocess) | same file `git/2`, `same/2`, `freeze/3` | exact (in-file) |
| `lib/crosswake/proof_lane/twin_journey.ex` (~711 mid-run re-probe, return `{:blocked, :source_dirty}`) | service | batch/sequential | same file observe step + `journey_plan` blocked pass-through | exact (in-file) |
| `lib/crosswake/proof_lane/twin_receipt.ex` (`@causes`, `@fidelity_limits`) | model | transform | same file lists | exact (in-file) |
| `lib/crosswake/proof_lane/twin_runtime.ex` (D-11 check in `prepare/1`) | service | request-response | same file `run_root/1`, `not_reused/1`, `database_path/2` | exact (in-file) |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (`next_action/2` clause, `blocked_receipt/2` measure) | controller (mix task) | request-response | same file `next_action/2`, `blocked_receipt/2` | exact (in-file) |
| `guides/see_it_run.md` (one sentence) | doc | n/a | same section 161-184 | exact |
| `test/crosswake/proof_lane/twin_producers_test.exs` (fixture fix + `describe "source cleanliness"`) | test | real-git fixture | same file `describe "freeze/3 and observe_identities/2"` 418-593 | exact |
| `test/crosswake/proof_lane/twin_receipt_test.exs` | test | transform | existing cases in file | role-match |
| `test/crosswake/proof_lane/twin_journey_test.exs` | test | stub | existing cases in file | role-match |
| `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | test | injected producers | cases at 368, 396, 435 | exact |
| `/private/tmp/crosswake-phase180-run/prepare-record.sh` | script | file-I/O | `twin-02-candidate.json` shape + `gate.sh` style | partial |
| `/private/tmp/crosswake-phase180-run/preflight-04.sh` | script | request-response checks | `gate.sh` (`&&` chain of jq/git checks) | role-match |
| `/private/tmp/crosswake-phase180-run/run-once-04.sh` | script | batch | `run-once-03.sh` | exact |

## Pattern Assignments

### `twin_producers.ex`: `clean_tree/2`, `git/2`, `freeze/3`, `observe_identities/2` (service, subprocess request-response)

**Analog:** same file. Current `freeze/3` `with` chain (lines 628-639, 668-671):

```elixir
def freeze(runtime, identity_path, opts \\ []) do
  path = runtime.candidate_path

  with {:ok, identity} <- read_identity(identity_path),
       {:ok, head} <- git(path, ["rev-parse", "HEAD"]),
       {:ok, tree} <- git(path, ["rev-parse", "HEAD^{tree}"]),
       :ok <- same(head, runtime.candidate_head),
       :ok <- same(tree, runtime.candidate_tree),
       # <-- INSERT `:ok <- clean_tree(path, opts),` HERE (D-06): after same/2, before lock_digests/backend_digest
       {:ok, locks} <- lock_digests(path),
       {:ok, study_js} <- file_digest(Path.join(path, @study_js_rel)),
       {:ok, backend} <- backend_digest(runtime, path, opts) do
  ...
  else
    {:blocked, _} = blocked -> blocked      # carries {:blocked, :source_dirty} unchanged
    _ -> {:blocked, :identity_unknown}
  end
```

Helpers to harden (685-692). Today there is no env scrub and no `:enoent` rescue:

```elixir
defp same(a, b), do: if(a == b, do: :ok, else: {:blocked, :identity_mismatch})

defp git(path, args) do
  case System.cmd("git", ["-C", path | args], stderr_to_stdout: true) do
    {out, 0} -> {:ok, String.trim(out)}
    _ -> {:blocked, :prerequisite_missing}
  end
end
```

Apply: add `env: @git_scrub_env` to `git/2` and wrap in `try ... rescue ErlangError -> {:blocked, :prerequisite_missing}`. The new `clean_tree/2` is public with `opts[:git_cmd]` (default `&System.cmd/3`), env list and the shell stderr-discard wrapper copied from RESEARCH "Code Examples" (lines 311-331). It runs the D-02 flag set, plus a second scrubbed `rev-parse --git-path info/exclude` read counting non-blank, non-`#` lines (B5). Returns `:ok | {:blocked, :source_dirty} | {:blocked, :prerequisite_missing}`. Add a thin `dirty_count/1` (integer or nil) over the same probe for B2.

`observe_identities/2` (795-852). `head`/`tree` come from `ok_or_nil(git(...))`, and `source`/`installed_build`/`backend_build` all gate on `head && tree`:

```elixir
head = ok_or_nil(git(path, ["rev-parse", "HEAD"]))
tree = ok_or_nil(git(path, ["rev-parse", "HEAD^{tree}"]))
...
source: if(head && tree, do: TwinReceipt.identity_digest([head, tree])),
...
installed_build: if(Enum.all?(installed, & &1) && served && head && tree && is_boolean(live[:executable_stable]), ...)
```

Apply (D-07): read head/tree, probe `clean_tree`, read head/tree again; set `head`/`tree` to `nil` unless clean and both reads equal `frozen.head`/`frozen.tree`. This reuses the existing nil-means-absent mechanism and needs no new branch in the map. `backend_build` also goes absent (acceptable, fail closed; RESEARCH line 111).

Caveat: an existing test (`a tracked media fixture ... fails TW-T10-02`, 528-541) dirties the fixture repo. Verify its outcome stays `:failed` after the guard (fail beats missing, `identity_result` 889-903).

### `twin_journey.ex` (service)

**Analog:** the observe step at ~711 plus `journey_plan` pass-through in `verify_twin.ex` 106-120. Only call site:

```elixir
observed = TwinProducers.observe_identities(ctx.frozen, live)
...
all = observations ++ TwinProducers.runner(ctx.frozen.expectations, observed, observations)
{:ok, observed, all}
```

Apply (B1): immediately before `observe_identities`, call `TwinProducers.clean_tree(ctx.frozen.candidate_path)`; on `{:blocked, cause}` return `{:blocked, cause}` from the function so `conduct/2` routes to `blocked_receipt/2`. `{:blocked, cause}` is already a legal return of `TwinJourney.run` (see `journey_plan`). The receipt's `TW-T10-02` observation is always overwritten by `derive` (twin_receipt.ex:280-285), so a runner-emitted `source_dirty` cause would be discarded. Do not rely on it.

### `twin_receipt.ex` (model, closed sets)

**Analog:** same file, `@causes` (21-40) and `@fidelity_limits` (57-62):

```elixir
@causes [
  :observation_missing, ... :session_control_unavailable,
  :cause_not_retained
]
@fidelity_limits [
  "simulator not physical speaker",
  "simulator not signed device",
  "synthetic_test_authority not real adopter",
  "trusted local runner not cryptographic certification"
]
```

`safe_cause/1` (192-194) is the reason the atom must be in the list:

```elixir
def safe_cause(cause) when cause in @causes, do: cause
def safe_cause(_), do: :cause_not_retained
```

Apply: add `:source_dirty` before `:cause_not_retained`; append one lowercase noun-phrase limit, e.g. `"source edit made and reverted during a run not detected"`. `validate/1` compares limits by literal equality (line 341), so twin-01..03 receipts stop decoding (B3). Never re-decode them. `measure_ok/1` (699-702) already accepts integers 0..1_000_000 for the B2 count.

### `twin_runtime.ex`: D-11 run-root-inside-candidate refusal (service)

**Analog:** same file. `prepare/1` chain (58-85) and the `failure/2` return style of `run_root/1`, `not_reused/1`:

```elixir
with {:ok, root} <- run_root(opts[:run_root]),
     :ok <- not_reused(root),
     {:ok, record} <- candidate_record(opts[:candidate]),
     # <-- INSERT `:ok <- outside_candidate(root, record.candidate_path),`
     {:ok, db} <- database_path(root, opts[:database_path]),
```

```elixir
{:error, failure(:prerequisite_missing, "Create a private run root directory (mode 0700) and run again with it")}
```

Apply: new `defp outside_candidate/2` walking the run root's ancestors and comparing `File.stat/1` `major_device` + `inode` with the candidate directory's (symlink-proof for `/tmp` vs `/private/tmp`). On a match return `{:error, failure(:prerequisite_missing, "Use a run root outside the candidate tree and run again")}`. No receipt is written for prepare errors; exit 2 with `summarize(:blocked, ...)`.

### `crosswake.proof_lane.verify_twin.ex` (mix task conduct/output)

**Analog:** same file. `conduct/2` (118-129) already routes `{:blocked, cause}` to `blocked_receipt/2`. `next_action/2` (271-278):

```elixir
defp next_action(%{overall_status: :passed}, _), do: "Copy twin-result.json byte for byte ..."
defp next_action(%{overall_status: :failed}, _), do: "Fix the first observed failure ..."
defp next_action(%{overall_status: :blocked}, _), do: "Supply the first missing observation or prerequisite ..."
```

Apply: add BEFORE the generic blocked clause

```elixir
defp next_action(%{overall_status: :blocked}, :source_dirty),
  do: "Commit or remove them in the candidate, prepare a new run record, and run again in a new run folder. Run `git status` in the candidate to see them."
```

`blocked_receipt/2` (144-185) builds all-blocked observations with `measure: nil`. Apply (B2): when `cause == :source_dirty`, set `measure: TwinProducers.dirty_count(runtime.candidate_path)` (integer or nil) on each blocked observation. It prints `summarize(:blocked, Atom.to_string(cause), report, next_action(receipt, cause))`, so the `first cause:` line is the atom today. Output is exactly four lines (`result:`, `first cause:`, `report:`, `next action:`). Decide D-10 wording: keep machine style plus a count, or prose "The candidate has N uncommitted or untracked files." Either way, no paths. Re-read the closed-strings test (435) first.

### `guides/see_it_run.md`

Prerequisites paragraph (lines 172-176) ends "...a first result is never overwritten." Append the single sentence "The candidate tree must be clean at the recorded head; a dirty tree is refused." Keep `grep -c B2C == 0`. Rerun `mix test test/crosswake/guides`, `phase69_docs_contract_parity_test.exs`, `mix crosswake.docs.sync --check`.

### `twin_producers_test.exs`: fixture fix and `describe "source cleanliness"` (test, real git)

**Analog:** `describe "freeze/3 and observe_identities/2"` setup (418-480). Self-dirtying patterns to remove (D-15):

```elixir
dir = Path.join(System.tmp_dir!(), "twin-freeze-" <> Base.encode16(:crypto.strong_rand_bytes(4)))
...
path = Path.join(dir, "identity-#{System.unique_integer([:positive])}.json")   # untracked file INSIDE repo
File.write!(path, Jason.encode!(Map.merge(base, overrides)))
...
runtime(dir) | candidate_path: dir     # runtime/1 (582-593) sets run_root: dir too, so expectations.json lands in the repo
```

Apply: create a sibling `aux` temp dir; write `identity-N.json` there; build `runtime` with `run_root: aux`, `database_path: Path.join(aux, ...)`, `candidate_path: dir`. Make this change first and verify the existing 24 tests are green before adding the guard.

Reuse the setup's fixture git style (existing uses plain `System.cmd("git", ...)` with `-c user.email=t@example.test -c user.name=t commit -q -m fixture`) and the local `defp git(dir, args)` helper (492-493, asserts exit 0). Add isolation per D-13: `HOME`/`XDG_CONFIG_HOME` in the tmp dir, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=/dev/null`, fixed dates, `commit.gpgsign=false`, `core.autocrlf=false`. The "global excludesFile still blocks" case must `System.put_env` for HOME/XDG and restore in `on_exit` (`async: false` makes that safe). Clean-pass assertion pattern to copy (505-513):

```elixir
assert {:ok, frozen} = TwinProducers.freeze(ctx.runtime, ctx.identity.(%{}), backend_digest: fn -> {:ok, String.duplicate("9", 64)} end)
observed = TwinProducers.observe_identities(frozen, live(frozen))
assert observed == frozen.expectations.joins
```

Blocked assertion style: `assert {:blocked, :identity_unknown} = TwinProducers.freeze(ctx.runtime, no_media, opts)`. Use `assert result == {:blocked, :source_dirty}`.

Ledger hazard: `phase170_vacuous_assertion_ledger_test.exs` pins 243 collection-shaped assertion sites. Use exact-equality assertions, not `assert Enum.all?`/`refute Enum.any?`. Otherwise regenerate `script/collection_assertion_ledger.json` in the same `fix(183-NN)` commit. `@tag :tmp_dir` is not used in the twin suites today; a `:tmp_dir` fixture lives under the candidate's `tmp/` (gitignored). Prefer `System.tmp_dir!()` so D-11 is not tripped.

For the `git_cmd` unavailable case, inject `fn _, _, _ -> raise ErlangError, original: :enoent end` and use real git for the non-repo case. Capture stderr with `ExUnit.CaptureIO.capture_io(:stderr, fn -> ... end)` for the B4 no-leak assertion.

### `crosswake_proof_lane_verify_twin_test.exs` (test, injected producers)

**Analog:** the blocked-journey test (396-405):

```elixir
producers = fn runtime, _expectations ->
  :ok = TwinRuntime.stop_children(runtime)
  {:blocked, :attachment_check_unavailable}
end
assert {2, [_, "first cause: attachment_check_unavailable", report, _]} =
         VerifyTwin.execute(args(ctx, record(ctx)), producers: producers)
assert report == "report: " <> Path.join(ctx.run_root, "receipt.json")
{:ok, receipt} = TwinReceipt.decode(File.read!(Path.join(ctx.run_root, "receipt.json")))
assert receipt.overall_status == :blocked
```

Apply: copy with `{:blocked, :source_dirty}`; assert exit 2, receipt `:blocked`, the first-cause text names `source_dirty` (this fails with `cause_not_retained` if the atom is missing from `@causes`), and the next-action text. Add a D-11 case next to the missing-run-root cases (~101/182): `ctx.base/candidate` is NOT a git repo and the run root is a sibling `ctx.base/run`; a run root created inside `ctx.candidate` (mode 0700) must yield exit 2 and no `receipt.json`. New run roots follow the existing pattern (`File.mkdir!(other); File.chmod!(other, 0o700)`).

Closed-strings test (435-472) asserts, for the source of the task and runtime files:

```elixir
source = File.read!("lib/mix/tasks/crosswake.proof_lane.verify_twin.ex")
refute source =~ "gen.shell"
refute source =~ "B2C"
refute File.read!("lib/crosswake/proof_lane/twin_runtime.ex") =~ "B2C"
```

Constraint on new strings: the D-10 next-action must not contain "gen.shell" or "B2C". The mix-task suite does not exercise `freeze/3`'s guard (the candidate there is not a git repo and producers are injected); the guard is covered in the producers suite.

### `twin_receipt_test.exs` / `twin_journey_test.exs`

Add: `TwinReceipt.safe_cause(:source_dirty) == :source_dirty`; `fidelity_limits/0` contains the new string (5 entries) and a receipt round-trips; a journey case where the stubbed probe is dirty returns `{:blocked, :source_dirty}` with the runner outcome never `:passed`.

### `/private/tmp/crosswake-phase180-run/run-once-04.sh` (script, batch)

**Analog:** `run-once-03.sh` in full (zsh, hardcoded absolute paths, stdout/stderr/exit captured):

```zsh
#!/bin/zsh
R=/private/tmp/crosswake-phase180-run/twin-03
cd /private/tmp/crosswake-phase180-impl
MIX_ENV=test mix crosswake.proof_lane.verify_twin ios --candidate /private/tmp/crosswake-phase180-run/twin-02-candidate.json --run-root $R --identity <home>/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-IDENTITY.json > $R.stdout 2> $R.stderr
echo $? > $R.exit
```

Apply: `R=.../twin-04`; `--candidate .../twin-04-candidate.json`; `--identity` points at `183-IDENTITY.json` in the 183 phase dir. Per D-19 add `set -eu`, run `preflight-04.sh` first, create the run root (mode 0700, as `run_root/1` requires) and write `twin-04.started` before the run. Capture the exit status without `set -e` aborting: use `set +e; ...; rc=$?; set -e; echo $rc > $R.exit`. Write `twin-run-path-04` rather than overwriting the existing `twin-run-path` (D-18; contents currently `.../twin-03`). Existing files to leave byte-identical: `twin-01..03*`, `run-once-0[123].sh`, `twin-run-count.before` (value `2`), `twin-run-path`, `twin-02-candidate.json`.

### `/private/tmp/crosswake-phase180-run/preflight-04.sh` (script, check chain)

**Analog:** `gate.sh` structure: one line of `jq -e ... && jq -e ... && test ... && git -C $C merge-base --is-ancestor <sha> HEAD && ...`, exits non-zero on first failure. Excerpt of reusable idioms:

```sh
P=<phase dir>; C=/private/tmp/crosswake-phase180-impl
test "$(git -C $C rev-parse --show-toplevel)" = "$(jq -r .git_top_level $P/180-CANDIDATE.json)" \
&& git -C $C merge-base --is-ancestor "$(jq -r .candidate_head $P/180-GATE.json)" HEAD
```

Do NOT reuse the gate itself (it checks the Phase 180 planning gate and the stale `12f84cd` lineage). Apply: write `set -eu` with one check per line and a message on failure (no paths printed beyond fixed labels). Checks: clean probe (same flags as D-02; non-empty output fails; also the `info/exclude` non-comment line check); HEAD/tree equal the record's `expected_head`/`expected_tree` (`jq -r`); `merge-base --is-ancestor <fix sha> HEAD`; the record's three `resource_digests` and one `fixture_digests` equal fresh `git show HEAD:<path> | shasum -a 256`; record mode 0600 (`stat -f %Lp` on macOS); port 4790 no listener (`lsof -nP -iTCP:4790 -sTCP:LISTEN` empty); no `crosswake-phase180-*` simulator in `xcrun simctl list`; `twin-04`, `twin-04.started`, `twin-04.exit` absent; run count recorded (new file, do not edit `twin-run-count.before`); `MIX_ENV=test mix crosswake.gen.shell ios --check` current. Digest source paths are the constants `@manifest_rel`, `@activation_rel`, `@media_rel`, `@study_js_rel` in `twin_producers.ex`; read them there, do not hardcode from memory.

### `/private/tmp/crosswake-phase180-run/prepare-record.sh` (script, file-I/O)

**Analog (shape only):** `twin-02-candidate.json` (mode `-rw-------`, 569 bytes), keys exactly as `candidate_fields/1` requires:

```json
{ "candidate_path": "/private/tmp/crosswake-phase180-impl",
  "expected_head": "<40 hex>", "expected_tree": "<40 hex>",
  "origin": "http://127.0.0.1:4790",
  "resource_digests": ["<manifest>", "<activation>", "<study_js>"],
  "fixture_digests": ["<media>"] }
```

Order of `resource_digests` matches `resources = [identity.manifest, identity.activation, study_js]` in `freeze/3`. `fixture_digests` is `[identity.media]`. No existing script writes a record (twin-02's was hand-written), so mechanics follow D-17: same clean probe; `git rev-parse HEAD` and `HEAD^{tree}`; digests via `git show HEAD:<path> | shasum -a 256`; `umask 077`; write a temp file in the run root, then `mv -n` (refuse overwrite: if `twin-04-candidate.json` exists, exit non-zero); print old (twin-02 record) vs new values. Build JSON with `jq -n --arg ...` rather than string concatenation. Add a scratch-repo smoke test.

## Shared Patterns

### Closed-cause, no-path output
**Source:** `twin_receipt.ex` `safe_cause/1` (192-194) and `@causes`. **Apply to:** every new failure path. Return atoms or integer counts only; never echo probe output, file names or absolute paths into stdout, receipt, `expectations.json` or logs. Test with a marker-named file refuted in `inspect(result)`, `expectations.json`, `receipt.json`, `twin-result.json` and captured stdout/stderr.

### `{:blocked, atom}` flow
**Source:** `freeze/3` `else` (668-671) and `conduct/2`. **Apply to:** `clean_tree/2`, the journey short-circuit. `{:blocked, _} = blocked -> blocked` passes causes through; anything else collapses to `:identity_unknown`, so new guards must return the `{:blocked, :source_dirty}` tuple.

### Scrubbed git subprocess
**Source:** new `@git_scrub_env` (RESEARCH lines 312-317; nil-unset verified on Elixir 1.19.5). **Apply to:** `git/2`, `clean_tree/2`, and the `info/exclude` read. Use the shell `exec "$@" 2>/dev/null` wrapper for the `-z` probe (bare `stderr_to_stdout: false` leaks to inherited stderr, B4).

### Real-git fixtures
**Source:** `twin_producers_test.exs` setup (418-480). **Apply to:** all dirty-state tests. No faked porcelain output (AGENTS.md invented-fixture lesson). Add one manual mutation check in verification (RESEARCH negative controls 1-8); no permanent lane.

### Append-only evidence
**Source:** D-18. **Apply to:** all run-root and phase-180 artifacts. Never edit `180-IDENTITY.json`, `180-TWIN-RESULT.json`, `run-once-03.sh` or `twin-0[123]*`. Add `183-IDENTITY.json` (with `supersedes`), `180-TWIN-RESULT.twin-03.annotation.json` and `183-TWIN-RESULT.json` (byte-copy, `cmp`-checked).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `outside_candidate/2` inode-ancestor walk in `twin_runtime.ex` | utility | file-I/O | No existing realpath or containment helper. `database_path/2` uses `String.starts_with?(expanded, root <> "/")`, which is string-only and not symlink-proof. Use the RESEARCH `File.stat` device+inode walk. |
| `prepare-record.sh` | script | file-I/O | The only prior record was hand-written; no generator exists. Use the D-17 spec and the key list in `candidate_fields/1`. |
| Commit-sequencing script for the 60 Phase 180 paths | script | batch | No analog. Follow RESEARCH "Candidate status": explicit paths per plan, never `git add -A`, assert empty porcelain before touching any 183 file. |

## Metadata

**Analog search scope:** candidate `lib/crosswake/proof_lane/`, `lib/mix/tasks/`, `test/crosswake/proof_lane/`, `test/mix/tasks/`, `guides/see_it_run.md`; run root `/private/tmp/crosswake-phase180-run/`.
**Files scanned:** about 14 (targeted reads plus RESEARCH's verified code map).
**Pattern extraction date:** 2026-10-15
