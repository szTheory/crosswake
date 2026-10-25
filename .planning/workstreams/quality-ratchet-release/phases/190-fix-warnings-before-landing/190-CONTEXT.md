# Phase 190: Fix warnings before landing - Context

**Gathered:** 2026-10-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the seven carried warnings (FIX-01..07) before the v25/v26 work lands. When the phase is done, nothing that is about to land can pass while checking nothing or report the wrong cause, and the 186 WR-01 loopback residual refuses, as the owner decided.

Where the work happens:
- Code fixes (FIX-04, 05, 06, 07) are commits on `refs/heads/candidate` in `<durable-candidate>`. It starts at HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, tree `f7c4d7dc`, with a clean status.
- Script fixes (FIX-01, 02, 03) are fixed successor scripts in this phase's folder. See D-01.

Out of bounds: no twin run, no Simulator or physical-iPhone run. No git operation in `<recovery-checkout>`: planning files there are edited as plain files only. No push, no PR (Phase 192), no release.

</domain>

<decisions>
## Implementation Decisions

### Where the script fixes live (FIX-01, 02, 03)
- **D-01:** The Phase 188 scripts in `phases/188-freeze-and-twin-05/scripts/` stay byte-for-byte unchanged. They are the record of what ran twin-05. Fixed, self-tested successors go in `phases/190-fix-warnings-before-landing/scripts/` and land with the planning records in Phase 191. `188-REVIEW-DISPOSITION.md` gets a one-line pointer from WR-01, WR-08 and the `g()` integration item to these successors. The successors are not promoted into the candidate as permanent tooling (AGENTS.md: keep one-time commands in phase evidence). — **Reversibility:** reversible — they could be promoted into `script/` later if a lasting gate is needed.
- **D-02:** Roadmap success criterion 5 is reworded to match D-01: the code FIX commits (04–07) are in the candidate with passing tests, and the script FIXes (01–03) are in the 190 folder with passing self-tests. No twin run took place, and the recovery checkout shows no git change. This edit was made to ROADMAP.md at discussion time.
- **D-03 (FIX-01):** The successor privacy scan counts the regular files it actually expands, not the lines in the list. It exits 2 (scope error) when the total is zero, or when any listed directory expands to zero files. Symlinks are refused explicitly with a scope error, never followed silently and never skipped silently. A self-test covers each of these: an empty directory, a directory holding only a symlink, and a list with a missing entry.
- **D-04 (FIX-02):** Every gate label has at least one negative control that makes it fail. That includes `port_4790_free`, `no_leftover_simulator`, `simulator_runtime_available`, `run_env_unsets_build_and_db`, `head_equals_record`, `tree_equals_record`, the 87-count branch of `history_manifest_87_ok`, and the real-mode branch of `mode_resolved`. The controls use stubs: lsof printing output, xcrun listing a `crosswake-phase180-` device, an empty runtimes list, a record with a mismatched head or tree, and a manifest with 86 entries. The self-test also checks that every label the gate can emit has a failing control: label coverage is derived from the gate's source, not from a hand-kept list, so a new label without a control fails the self-test.
- **D-05 (FIX-03):** All successors share one `g()` helper that sets the same environment and pins as the Elixir funnel (`@git_env` and `@git_pins` in `lib/crosswake/proof_lane/twin_producers.ex`). That means the full scrub list plus `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_NO_REPLACE_OBJECTS=1`, `GIT_ATTR_NOSYSTEM=1`, `GIT_OPTIONAL_LOCKS=0`, `GIT_TERMINAL_PROMPT=0`, `LC_ALL=C` and the same `-c` pins, including `core.hooksPath=/dev/null` and `--attr-source=<empty tree>`. The proof is a comparison test: it sets a misleading global config (for example a global excludesFile or `status.showUntrackedFiles=no` in a temp `HOME`) and asserts that the shell `g()` and the Elixir funnel give the same answer. A second check compares the helper's environment and pin list with the funnel's source, so the two cannot drift apart unnoticed.

### Code fixes in the candidate
- **D-06 (FIX-04):** `tracked_children/1` in `twin_runtime.ex` treats `{:noproc, _}`, `{:normal, _}` and `{:shutdown, _}` exits as gone. A `{:timeout, _}` exit is reported as a new `{:error, :registry_timeout}`. On a timeout, `stop_all/1` does not call `Agent.stop/1`, so the registry and its child list stay alive (the origin listener is still closed). The `@spec` gains `:registry_timeout`. The caller at `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:79` shows the timeout in the verdict instead of dropping it. Tests: a slow registry is reported as a timeout and stays alive, and a dead registry is still reported as `:registry_gone`.
- **D-07 (FIX-05):** `Provenance.commit_ref/1` (`lib/crosswake/proof_lane/provenance.ex`) uses the same pinned git environment as the shared funnel, either by reusing or extracting `@git_env` rather than copying it. It also requires `git rev-parse --show-toplevel` to equal the canonicalized `cwd`, and returns `git-unknown` otherwise. New test: a host folder nested inside a temp repo, with no `.git` of its own, must get `git-unknown`. The existing no-`.git` test stays.
- **D-08 (FIX-07, owner decision: refuse):** The refusal is implemented in the preflight's `origin_refusal_for` in `lib/crosswake/proof_lane/physical_iphone_preflight.ex`. `IosHostOriginMode.observe/2` keeps its shared meaning. The preflight refuses with `PI-PREFLIGHT-CONFIG` and a clear reason when the shell root exists and `Info.plist` cannot be read (missing, `eisdir`, permissions), or when `Fixtures/route_activation.json` exists but cannot be read or parsed. An absent `route_activation.json` with a readable production plist still passes. The doc comment is reworded to describe this behaviour exactly. Tests cover `Info.plist` replaced by a directory (blocked), malformed JSON (blocked), and readable production with no activation file (passes).
- **D-09 (FIX-06):** The guard pin (`script/check_absence_is_not_success.exs:64`, `{"test-files", "test/**/*.exs", 249}`) is raised in the last FIX commit. The new value is the count measured by a separate command at that final commit, never derived from the guard's own glob at check time (185 D-03). Today that count is 253, plus any test files Phase 190 adds. Phase 191 counts again on the integration branch and adjusts the pin if `main` changes the count.
- **D-10:** One commit per FIX on `refs/heads/candidate`, each with its tests. The gate is the full mix suite in `<durable-candidate>` compared against the known baseline failures (185 example-host G2/G6 and Swift G4). Pass means no new failure, not zero failures.

### Claude's Discretion
- Exact successor script names and layout in the 190 `scripts/` folder, how the stubs are wired, and how the comparison test drives the Elixir funnel (for example `mix run` in `<durable-candidate>`).
- Whether FIX-05 extracts a small shared git-env module or calls the existing one in `twin_producers.ex`.
- Wording of the refusal reasons, as long as they name the unreadable or malformed file in plain language and leak no paths or sensitive values.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and rules
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — FIX-01..07.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 190 success criteria (criterion 5 reworded per D-02) and the v27.0 ordering rules.
- `.planning/workstreams/quality-ratchet-release/v27.0-SCOPE.md` — milestone scope, the 186 WR-01 "refuse" decision, and the frozen recovery checkout.
- `.planning/workstreams/quality-ratchet-release/milestones/v26.0-closeout/debt-disposition.md` — origin of each FIX item.
- `.planning/workstreams/quality-ratchet-release/milestones/v26.0-MILESTONE-AUDIT.md` — the guard-pin (249 vs 253) and `g()` findings.
- `AGENTS.md` — sensitive-data rules and the rule to keep one-time commands in phase evidence.

### Warning sources
- `.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/188-REVIEW.md` — WR-01 (empty-scope scan) and WR-08 (labels with no negative control).
- `.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/188-REVIEW-DISPOSITION.md` — gets the successor pointers (D-01).
- `.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05/scripts/` — `scan-privacy-188.sh`, `selftest-188.sh`, `run-once-05.sh` and the `g()` copies in `freeze-check-188.sh` and `make-identity-188.sh` (read-only originals).
- `.planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-REVIEW.md` — WR-02 (registry timeout).
- `.planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-CONTEXT.md` — D-03: the pin comes from a separate measurement.
- `.planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-REVIEW.md` — WR-02 (provenance).
- `.planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-REVIEW.md` — WR-01 (preflight unreadable inputs).
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-CONTEXT.md` — `<durable-candidate>` rules and placeholder names.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/crosswake/proof_lane/twin_producers.ex:745-790`: the pinned git funnel (`@git_scrub_names`, `@git_fixed_env`, `@git_pins`). It is the reference for D-05 and D-07.
- `test/support/twin_git_fixtures.ex`: git fixture helpers, useful for the nested-host provenance test and the comparison test.
- `script/check_absence_is_not_success.exs`: the guard with the `test-files` pin row.

### Established Patterns
- Refusal codes such as `PI-PREFLIGHT-CONFIG` (`physical_iphone_preflight.ex:24,65`) are the way the preflight blocks with a reason.
- The rule "absence must not score as success" (memory and AGENTS.md): every new check needs a negative control that proves it can fail.
- Phase scripts use placeholder names (`<durable-candidate>`, `<recovery-checkout>`, `<tmp>`), never real home paths or user names.

### Integration Points
- `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:79`: the consumer of `stop_all/1`. It must show `:registry_timeout`.
- `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`: existing `stop_all` tests to extend.
- `lib/crosswake/shell/ios_host_origin_mode.ex:124-175`: `observe/2` returns `:unreadable` or `:none`. It stays unchanged; the preflight interprets these values.

</code_context>

<specifics>
## Specific Ideas

- The test-file count today is 253 (`find test -name "*.exs"` at `a53fbef`) against the pin of 249.
- The current `g()` copies set `GIT_CONFIG_NOSYSTEM=1` but not `GIT_CONFIG_GLOBAL=/dev/null`, and they miss `GIT_ATTR_NOSYSTEM`, `GIT_NO_REPLACE_OBJECTS`, `core.hooksPath` and `--attr-source`.

</specifics>

<deferred>
## Deferred Ideas

- **184 GAP4-WR-01:** a FIFO at `.git/info/attributes` makes `probe_source/2` wait forever. It is on the same debt list but not in FIX-01..07. Handle it before the next twin run or twin-touching change.
- **Retained review findings** (185 WR-03..05, 186 WR-02, 187 WR-03/04, 188 WR-03/05..07, doctor `Path.relative_to` fallbacks): not in v27 scope.
- Promoting the 190 successor scripts into permanent `script/` tooling: only if a lasting gate is needed later (D-01).

</deferred>

---

*Phase: 190-fix-warnings-before-landing*
*Context gathered: 2026-10-19*
