# Phase 183: Close gap: twin source binding fails closed on uncommitted code - Context

**Gathered:** 2026-10-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the one integration blocker from the v25.0 milestone audit. The twin receipt's `source` and `installed_build` joins must attest the code that actually ran:

- The runner refuses, with a named cause, to produce a passing source join from a candidate with uncommitted or untracked changes.
- The Phase 180 code goes into the attested candidate tree as ordinary commits in the `/private/tmp` candidate.
- The twin then runs once into a new run root (D-16 of Phase 180).

Requirements reopened for attestation only: TWIN-01, TWIN-05 and TWIN-06. All 20 v25.0 requirements stay complete. This phase does not add twin scenarios, groups or observations, and it does not change the physical-iPhone schema.

</domain>

<decisions>
## Implementation Decisions

The user locked D-01 (fail closed, not a working-tree digest) and the scope (identity-projection join deferred). D-02..D-20 are the synthesized recommendation set from a four-way research fan-out on 2026-10-15: git mechanics and prior art, mid-run integrity and causes, provenance and rerun, and test design. The orchestrator then ran an adversarial pass and checked the disputed claims in the candidate and in a scratch repo. Downstream agents follow them as locked unless the code disproves a stated fact.

### Source binding rule (locked by the user)
- **D-01:** Fail closed. A candidate with any modified, staged, deleted, renamed or untracked non-ignored path cannot produce a passing `source` or `installed_build` join. The receipt keeps a plain git HEAD/tree that names the delivered commit. Do NOT bind a working-tree digest (rejected option): Go's `vcs.modified` and Nix's `dirtyRev` show that annotating a dirty identity instead of voiding it lets dirty runs look authoritative. No bypass flag (cargo `--allow-dirty` lesson). — **Reversibility:** reversible — local runner check; receipt schema unchanged apart from one closed cause atom.

### Clean-tree probe mechanics
- **D-02:** Run one probe with both the exit code and the output checked:
  ```
  git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false \
      -C <candidate> status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none
  ```
  - `{"", 0}` means clean.
  - `{non_empty, 0}` means `{:blocked, :source_dirty}`.
  - Anything else (non-zero exit, dubious-ownership/safe.directory error, corrupt index, missing repo) means `{:blocked, :prerequisite_missing}`.

  Rules for the probe:
  - Never parse entries for meaning; any byte means dirty. The only exception is counting NUL-separated records for the user-facing count, where a rename's second field is not counted.
  - Never auto-set `safe.directory`.
  - Do not use `diff --quiet` + `ls-files --others`: two commands race each other and need an index refresh that takes `index.lock`.
  - Do not use a temp-index `write-tree` comparator. It writes blob objects into the candidate's object store and adds nothing over an empty porcelain result.
- **D-03:** `-c core.excludesFile=/dev/null` is required. It was verified on git 2.41.0 in a scratch repo:
  - A file covered only by the user's XDG global ignore (`~/.config/git/ignore`) is hidden from a default `git status`.
  - With `-c core.excludesFile=/dev/null` that file is shown.
  - `GIT_CONFIG_GLOBAL=/dev/null` alone does NOT show it, because the XDG default still applies.

  Only the committed `.gitignore` files plus `.git/info/exclude` count. Treat a `.git/info/exclude` with any non-comment line as `:source_dirty` too: it is local, uncommitted and invisible to review. The candidate currently has 0 such lines.
- **D-04:** Scrub the environment for the probe AND for the existing `git/2` helper (`twin_producers.ex` ~687). A leaked `GIT_DIR` would make `rev-parse HEAD` describe a different repo from the one probed.
  - Unset: `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_COMMON_DIR`, `GIT_NAMESPACE`, `GIT_CEILING_DIRECTORIES`, `GIT_CONFIG`, `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`. Use `{name, nil}` in the `System.cmd` `env:`.
  - Set: `GIT_OPTIONAL_LOCKS=0`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_TERMINAL_PROMPT=0`, `LC_ALL=C`.
  - The probe uses `stderr_to_stdout: false`, because stderr would corrupt the `-z` stream.
  - Rescue the `System.cmd` `:enoent` (git missing) and return `{:blocked, :prerequisite_missing}`. Today `git/2` would crash instead of blocking.

  No new dependency (copy over dep).
- **D-05:** Git-ignored paths are not dirty. This is checked: `_build/`, `deps/`, `node_modules/`, `playwright-artifacts/`, the example `crosswake_example.db*`, SwiftPM `.build/`, `DerivedData`, `tmp/`, `__pycache__`, and key/secret patterns are all ignored. They are outputs or state, and are covered separately by the lock digests, the compiled-beam backend digest and the run-root database (Phase 180 D-13). There are no submodules, no nested repos, no skip-worktree/assume-unchanged entries, and `core.autocrlf` is unset. Phantom dirt from future line-ending settings fails closed, which is acceptable.

### Where the check runs and how it surfaces
- **D-06:** `TwinProducers.freeze/3` is the single authority. Run the probe right after the HEAD/tree `same/2` checks and BEFORE `backend_digest`, so a dirty candidate is never compiled. The existing blocked pass-through carries the cause. An optional fast-fail check when the prepared record is loaded (`twin_runtime.ex` `candidate_record/1`) is allowed, but it is not the gate, because the tree can change between the record and the freeze.
- **D-07:** `observe_identities/2` reruns the probe after the last build/run step, and re-reads HEAD/tree both before and after it. `source`, and therefore `installed_build`, is set only when:
  - the probe is clean, and
  - HEAD/tree are unchanged across both reads and equal the frozen values.

  Otherwise the join is absent and the group is blocked (Phase 180 D-19).
- **D-08:** Add `:source_dirty` to the closed `@causes` list (`twin_receipt.ex` ~21-40). Without it, `safe_cause/1` turns it into `:cause_not_retained` and the specific cause is lost. A mid-run dirty probe must report `source_dirty` as the first cause, not the generic `identity_unknown`: the producer emits the cause on the source observation. A control asserts the first-cause text names it.
- **D-09:** Keep the existing exit codes. Blocked maps to exit 2 (`exit_status_for`), so no new exit code is needed.
- **D-10:** Plain-language output with a typed count. Add a `next_action` clause for `:source_dirty`.
  - First cause: "The candidate has N uncommitted or untracked files."
  - Next action: "Commit or remove them in the candidate, prepare a new run record, and run again in a new run folder. Run `git status` in the candidate to see them."

  Privacy and format rules:
  - The count goes in the cause's typed `measure` field, not in a string.
  - Paths are never written to stdout, artifacts, logs or the receipt, because mix output gets captured into logs and CI (Phase 180 D-21).
- **D-11:** The runner refuses a run root inside the candidate tree (prerequisite cause). Otherwise its own `expectations.json` and database would dirty the tree, and the guard would block every run. The real run root `/private/tmp/crosswake-phase180-run/` is already outside the candidate.
- **D-12:** Add a fidelity limit to `@fidelity_limits` (`twin_receipt.ex` ~55): "a source edit made and reverted during a run is not detected". Two probes cannot see an edit-then-revert. The receipt is a trusted-runner record, not cryptographic (Phase 180 D-20). The structural fix is to build from a snapshot clone owned by the run root. It is deferred, because `candidate_path` feeds the freeze, host build, installed-app paths and tracked digests, and re-pointing it is a refactor.

### Tests (negative controls)
- **D-13:** Use real git for every dirty-state case; faked porcelain output is the invented-fixture trap the AGENTS.md lesson warns about.
  - Fixtures go in a new `describe "source cleanliness"` with `@tag :tmp_dir`.
  - Fixture git runs with an isolated env: `HOME` set to the tmp dir, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=/dev/null`, fixed author/committer dates, and `-c user.name/email`, `commit.gpgsign=false`, `core.autocrlf=false`.
  - Add one narrow injectable `git_cmd` option only for the "git unavailable" case.
- **D-14:** Required cases in `twin_producers_test.exs`:
  - clean proceeds past the guard;
  - a modified tracked file blocks `:source_dirty`;
  - a staged-only change blocks;
  - a deleted file blocks;
  - an untracked file blocks;
  - a repo-`.gitignore`d file does not block;
  - a file ignored only by a global excludesFile still blocks;
  - a non-comment `.git/info/exclude` entry blocks;
  - dirty-after-freeze leaves `source` absent, and the runner outcome is blocked with first cause `source_dirty`, never passed;
  - a HEAD moved after freeze leaves the join absent;
  - git unavailable or a non-repo path gives `:prerequisite_missing`, not a pass;
  - a fixture with twin-03's exact shape (untracked twin files plus modified tracked files at the recorded head/tree) blocks.

  Privacy assertions: create a file named with a distinctive marker, then refute the marker in `inspect(result)`, `expectations.json` and the receipt, and assert the count is in `measure`.
- **D-15:** Fix the existing fixture first. The current setup (~418-464) writes `identity-N.json` into the repo after the commit, and uses the repo as `run_root`. Every existing "clean" test would therefore start failing with `:source_dirty`. Move the identity file and run root outside the repo.

  In the mix-task test, add a case: producers returning `{:blocked, :source_dirty}` yield a non-passing receipt, exit 2 and the plain-language cause.

  Further rules:
  - Keep `async: false`.
  - Record one manual mutation check in verification: remove the guard, and the dirty cases must fail. Do not create a permanent lane.
  - The tests run in the existing `crosswake-ci.yml` full `mix test` leaves (ubuntu, git preinstalled), so no new lane is needed.

### Delivery into the attested tree and the rerun
- **D-16:** Commit in the candidate `/private/tmp/crosswake-phase180-impl` on top of `da53c54`. Never in the recovery checkout.
  - The Phase 180 work goes in as per-plan conventional commits (`feat(180-NN): ...`, matching the repo style).
  - Then LAST, one `fix(183-NN): ...` commit carries the guard, its negative tests and a one-line guide addition to `guides/see_it_run.md` (twin section ~161-186): "The candidate tree must be clean at the recorded head; a dirty tree is refused." The fix must be an ancestor of, or equal to, the attested run HEAD.
  - Nothing is committed after the prepared record is written.

  Delivery into the authoritative tree is out of scope and needs separate authorization. — **Reversibility:** reversible — candidate-only commits in a temporary clone.
- **D-17:** The prepared record is produced by a script, never by hand. Today it was hand-written, and `candidate_record/1` validates only its shape. Write `/private/tmp/crosswake-phase180-run/prepare-record.sh`. This is a one-time evidence tool kept with the run records, not a product command. It:
  - refuses a dirty tree using the same D-02/D-03 probe;
  - reads HEAD and `HEAD^{tree}`;
  - computes the manifest, activation, static JS and media sha256 from committed bytes (`git show HEAD:<path> | shasum -a 256`), not the worktree;
  - writes `twin-04-candidate.json` with mode 0600 via an atomic rename;
  - refuses to overwrite an existing record;
  - prints the old values next to the new ones.
- **D-18:** History is append-only (the SLSA/in-toto pattern: an immutable statement, corrected by a new statement that references the old one).
  - Leave twin-01..03 roots, their stdout/stderr/exit files, `run-once-03.sh`, `180-TWIN-RESULT.json` and `180-IDENTITY.json` byte-identical.
  - Add `183-IDENTITY.json` with `supersedes: "180-IDENTITY.json"` and the committed head/tree, and pass it as the identity input for twin-04.
  - Add the sidecar `180-TWIN-RESULT.twin-03.annotation.json`. It carries the subject (sha256 of `180-TWIN-RESULT.json`), the note "passed against an incompletely identified source (uncommitted Phase 180 code over da53c54)" and `superseded_by: "183-TWIN-RESULT.json"`.
  - A passing twin-04 result is byte-copied to `183-TWIN-RESULT.json`, checked with `cmp` and against `receipt_sha256`. The Phase 183 summary states that it supersedes the 180 result for TWIN-01/05/06 attestation.
- **D-19:** Write a new `preflight-04.sh`; do not reuse `gate.sh`, which validates the Phase 180 planning gate and the stale `12f84cd` lineage. It exits non-zero on the first failure, checking:
  - the clean probe;
  - HEAD and tree equal the record;
  - `git merge-base --is-ancestor <fix> HEAD`;
  - the record digests equal freshly recomputed `git show` hashes;
  - the record mode is 0600;
  - port 4790 has no listener;
  - no `crosswake-phase180-*` simulator exists;
  - `twin-04` and its `.started`/`.exit` files are absent;
  - the run count is recorded;
  - `mix crosswake.gen.shell ios --check` is current under the right `MIX_ENV`.

  `run-once-04.sh` (`set -eu`) runs the preflight, writes `twin-04.started`, runs once and captures the exit status. All of this is automated; no human step.
- **D-20:** One run into `twin-04` (Phase 180 D-16). Any failure means diagnose, then use a new root (`twin-05`); never reuse a root.

### Claude's Discretion
- Helper naming (e.g. `clean_tree/2`), exact wording polish of the D-10 copy, how Phase 180 work splits across per-plan commits, and whether `prepare-record.sh` reuses a small Elixir helper or plain shell.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Gap source
- `.planning/v25.0-MILESTONE-AUDIT.md`: the blocker (`twin_producers.ex:632-633`, `:797-798`) and the closing-the-gap guidance

### Phase 180 decisions this phase must keep
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-CONTEXT.md`: D-16 (one run per root), D-19 (freeze/observe identities; unknown identity blocks), D-20 (negative controls), D-21 (privacy-safe artifacts), D-25 (fast CI leaves), D-27 (recovery checkout preserved)
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-07-SUMMARY.md`: the twin-03 run record to annotate
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-IDENTITY.json`: stale identity record (`12f84cd`)
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-TWIN-RESULT.json`: current twin-03 result

### Governing rules
- `AGENTS.md`: fail-closed and silent-degradation rule; sensitive-data rules; recovery checkout limits; real-subprocess fixture lesson
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: TWIN-01, TWIN-05, TWIN-06

</canonical_refs>

<code_context>
## Existing Code Insights

All paths are in the candidate `/private/tmp/crosswake-phase180-impl`. The Phase 180 files are still untracked there.

### Reusable Assets
- `lib/crosswake/proof_lane/twin_producers.ex`:
  - `freeze/3` (~line 627) already chains `git/2` and `same/2` in a `with`; add the clean-tree guard there.
  - `git/2` (~687) maps a subprocess failure to `:prerequisite_missing`.
  - `same/2` (~685) yields `:identity_mismatch`.
- `observe_identities/2` (~797) re-reads HEAD/tree with `ok_or_nil`; returning nil makes the join absent, so the group is blocked.
- `lib/crosswake/proof_lane/twin_receipt.ex`:
  - `freeze_expectations/1` (~209) derives expected `source`/`installed_build` from head and tree.
  - `first_cause/1` (~431) reports the first cause.
- `lib/crosswake/proof_lane/twin_runtime.ex` (~60-85) loads the prepared record (`candidate_record/1`) into `candidate_head`/`candidate_tree`.

### Established Patterns
- `{:blocked, atom}` causes, closed atom sets, and no raw paths or values in artifacts.
- Run records live in `/private/tmp/crosswake-phase180-run/` (`twin-NN/`, `twin-NN.exit`, `run-once-NN.sh`, `twin-NN-candidate.json`).

### Integration Points
- `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (~153, ~205) passes the runtime head/tree into the receipt.
- The tests to extend are `test/crosswake/proof_lane/twin_producers_test.exs` and `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`.

</code_context>

<specifics>
## Specific Ideas

- The user's chosen preview, verbatim intent: at freeze, a non-empty `git status --porcelain --untracked-files=all` gives `{:blocked, :source_dirty}`, and head/tree must equal the prepared record. At observe, the same check runs again, and the source join is absent if anything changed mid-run. Then commit Phase 180 in the candidate, write a new prepared record (twin-04) and run once into twin-04.

</specifics>

<deferred>
## Deferred Ideas

- Snapshot-clone run source (build from a run-owned `git clone --local` so mid-run edits are structurally impossible; closes the D-12 fidelity limit).
- Twin join against the Phase 179 identity/settings projections. `twin_journey.ex:20` hardcodes bundle id `org.crosswake.twin`. This is audit tech debt; the user chose to defer it out of Phase 183.
- The other audit debt stays as recorded in `.planning/v25.0-MILESTONE-AUDIT.md`:
  - 181/182 review findings;
  - the `study-session` route_id label;
  - Nyquist VALIDATION gaps;
  - the unknown twin-02 case 3 stall cause.

</deferred>

---

*Phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co*
*Context gathered: 2026-10-15*
