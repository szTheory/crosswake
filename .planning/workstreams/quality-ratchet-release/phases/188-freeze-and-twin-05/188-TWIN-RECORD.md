# Phase 188 twin-05 record

A pass means the Simulator twin saw every one of its ten observation groups and all seven identity joins pass against the frozen candidate a53fbef; it does not mean a physical iPhone, a signed device, a real first adopter or a cryptographic certification was involved.

## What was checked

- One twin-05 run (gate attempt 1, run id `twin-037ff19e6d010e32`) against the frozen candidate `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`), launched once by `run-once-05.sh`.
- Before the sentinel, the gate record `go-no-go-05.1.json` showed all 30 labels passing, with a null cause. Among them were the read-only `twin_preflight_allowed` (exit 0, root still empty), `head_equals_record`, `record_digests_match_git_show`, `identity_matches_record`, `root_is_private_dir` and `root_empty`.
- The freeze record's criterion-1 sentence: "One frozen candidate commit means the cumulative tree at the single final HEAD a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4, which carries every v26 change since 50fcd57, not one commit since 50fcd57."
- The D-12 refinement: the dedicated build path `_build_188_twin05/attempt-1` was used only for the outer compile, the Elixir probe and the read-only preflight. `verify_twin` itself ran with both the build-path and database-path variables unset (gate label `run_env_unsets_build_and_db`).

## What happened

- Sentinel time 2026-10-16T21:20:12Z; exit status 0.
- `result: passed (exit 0)`
- `first cause: none`
- `next action: Copy twin-result.json byte for byte into the planning artifact`
- Report path: `/private/tmp/crosswake-phase180-run/twin-05/receipt.json` (run-local; not copied into planning).
- `assert-twin-05.sh` printed `assert: ok`: 10 groups, 7 joins, 49 unique observations, 5 limits and the receipt digest. The negative self-test (`--only A01-A15`) passed 15 of 15 again afterwards.
- Group outcomes, from 188-TWIN-RESULT.json:
- T01: passed
- T02: passed
- T03: passed
- T04: passed
- T05: passed
- T06: passed
- T07: passed
- T08: passed
- T09: passed
- T10: passed
- Identity joins, all passed with a null cause: source, dependency_lock, generated_resources, served_static, installed_media, installed_build, backend_build.

## Fidelity limits the receipt states

1. simulator not physical speaker
2. simulator not signed device
3. synthetic_test_authority not real adopter
4. trusted local runner not cryptographic certification
5. source edit made and reverted during a run not detected

## Planning-record limits the receipt cannot vouch for

- ignored files are not counted
- the Phase 179 identity join is deferred
- DEBT-IDENT: the twin attests the hardcoded bundle id org.crosswake.twin (twin_journey.ex:20), not the generated identity

## Open warnings not exercised by twin-05

- 186 WR-01 and 186 WR-02 (not on the Simulator twin path; 188-CONTEXT D-04)
- 187 WR-02 (`commit_ref` with a nested host directory) and 187 WR-04 (public `provenance_known?/1`)
- 184 GAP4-WR-01 (bounded read of git local files)
- 185 WR-02, 185 WR-03, 185 WR-04 and 185 WR-05
- The five carried `routing.unclassified_path` adoption-scan findings under the example host's iOS shell directory
- Leftover Simulator devices named `crosswake-phase180-*` after the run: 0, so the 185 WR-02 reopen trigger did not fire

## Residual external gates

1. physical iPhone signed-device run
2. first adopter sanitized route handoff

## Byte copy

- Source `twin-05/twin-result.json` sha256: `cf3035ff789cd1696db0d54de133deab6f4299480c05c1420d1aff75fb79c448`
- Copy `188-TWIN-RESULT.json` sha256: `cf3035ff789cd1696db0d54de133deab6f4299480c05c1420d1aff75fb79c448` (cmp: identical)
- `receipt_sha256`: `3da8ce94a527c647efc221a287fa397659a7caa430562d5b02c89ed5067de2b9`, which equals the sha256 of the run-local receipt
- The scan before the copy covered `twin-result.json` alone: 1 file, 0 hits.

## Run-root scan (informational)

`scan-privacy-188.sh` read the twin-05 directory, twin-05.stdout, twin-05.stderr, twin-05.started, twin-05.exit and twin-run-path-05 without changing them: rc 0, 24 files, 0 hits. This scan covers every class, including the router module and doctor key classes, so the D-07(c) post-run observation is that no router module name and no doctor key appear in the run outputs. None of these files was edited or copied.

## Did anything change

- The candidate is unchanged: HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`, a 0-byte porcelain and the push URL `no-push-phase180`.
- The example-host SQLite files crosswake_example.db, -shm and -wal kept their size and sha256 from before the launch to after the exit.
- The history manifest still gives rc 0 with 87 OK after the run, and twin-04's result is still cmp-identical to 183-TWIN-RESULT.json.
- Run roots: exactly five (`twin-01`..`twin-05`), one `twin-05.started`, no `twin-06`.
- The recovery checkout has no staged change. Nothing was committed, pushed, tagged or merged.

## Next action

Run `$gsd-verify-work 188 --ws quality-ratchet-release` to rerun the D-21 checks. After it passes, v26.0 is ready for milestone audit/close with `$gsd-audit-milestone --ws quality-ratchet-release`. Delivering the candidate commits into the authoritative tree still needs separate authorization.
