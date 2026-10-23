---
status: resolved
trigger: "PR 214 exact-head CI run 36322284611 fails proof-requires-example-host at seed 17 (complete-class command_failure, exit 2). Diagnose and fix the root cause, rerun exact-head CI, and merge only if required CI passes under the user's existing conditional authorization."
created: 2026-09-27
updated: 2026-09-27
---

# PR 214 Example Host Seed 17 Failure

## Symptoms

- expected_behavior: The exact-head `proof-requires-example-host` check passes for PR #214.
- actual_behavior: Run 36322284611 fails that check at seed 17; the outer repository verifier reports class `complete`, kind `command_failure`, exit code 2.
- error_messages: `script/verify_repository.sh --stage example-host-proof` recommends `MIX_ENV=test script/check_example_host_isolation.sh --matrix-only`. The nested failure output has not yet been recovered from the hosted job.
- timeline: Observed on 2026-09-27 for PR #214 head `85ba10d98d34e3f19d3135e95a0a3e67fa09328c`.
- reproduction: Run `MIX_ENV=test script/check_example_host_isolation.sh --matrix-only` on the exact PR head in a clean environment, then isolate seed 17.

## Current Focus

- bug_class: heisenbug-mandelbug (same seed manifests different failures under unchanged full-suite inputs)
- hypothesis: Confirmed: async EvidenceGateTest cleared global Mix task state and reran app.config/compile while ExUnit loaded other tests, creating transient dependency cwd/code-path interference.
- test: Completed local exact matrix and hosted exact-head required CI, then merged PR #214 through the protected path.
- expecting: Achieved: all six local matrix classes, 49 hosted checks, and the protected Crosswake CI context passed; PR state is MERGED.
- next_action: No further code or CI action. Preserve this resolved session as the diagnosis record.

reasoning_checkpoint:
  hypothesis: "EvidenceGateTest's async Mix.Task.clear + app.config call can rerun compile/dependency loading while test files compile, corrupting shared cwd/code-path assumptions."
  confirming_evidence:
    - "Exact-head seed-17 complete class failed repeatedly with moving errors, including HexPageTest @root captured under deps/telemetry and Application.app_dir(:crosswake) unknown."
    - "Elixir 1.19.5 source shows Mix.Task.clear clears global Mix.TasksServer, and app.config runs compile."
    - "Changing only EvidenceGateTest to async:false yielded 2095 tests, 0 failures at seed 17."
  falsification_test: "Run the exact matrix with only this change; any recurrence, or repeat failures under fresh runtime dirs, refutes sufficiency."
  fix_rationale: "Synchronous ExUnit modules run after the async phase, avoiding overlap between this global Mix compile path and parallel test-file loading."
  blind_spots: "The exact internal dependency-loading transition was inferred from Mix source and path symptoms rather than captured live; the local matrix and hosted exact-head CI verified the fix."
  candidate_causes:
    - "code: async test invokes global Mix task reset and compile"
    - "environment: local macOS versus hosted Linux timing and dependency caching can alter race exposure"
  and_gate: "yes: global Mix mutation is harmful only when it overlaps test-file compilation or async consumers; the scheduling overlap is the second condition."

## Evidence

- timestamp: 2026-09-27T00:00:00Z
  checked: PR #214 and failed GitHub Actions run 36322284611
  found: PR head is `85ba10d98d34e3f19d3135e95a0a3e67fa09328c`; `proof-requires-example-host` is the only failing required proof check in the CI matrix. Its log reports seed 17, class `complete`, kind `command_failure`, and exit code 2, then recommends `MIX_ENV=test script/check_example_host_isolation.sh --matrix-only`.
  implication: The wrapper's summary is insufficient to choose a fix; the nested matrix command must be reproduced and captured first.

- timestamp: 2026-09-27T14:02:40Z
  checked: clean clone, matrix script, and GitHub failed-job log
  found: The isolated clone is clean at the exact PR head. The matrix runs tagged then complete classes for seed 17; complete runs `CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed 17`. The hosted log shows only the facade's JSON summary, not the captured child log.
  implication: Run the matrix directly to surface the underlying ExUnit failure. The prior shared-worktree Hex permission failure remains an environment confounder, so use private writable homes.

- timestamp: 2026-09-27T14:03:27Z
  checked: first local matrix attempt in isolated clone
  found: Example app dependencies compiled, but root `MIX_ENV=test mix compile` stopped before the matrix because fresh clone lacked root Hex deps (`phoenix_live_view`, `nimble_options`, and others). CI has a root `mix deps.get` step before this job.
  implication: Complete the same root dependency setup, then rerun; this local setup failure does not explain the hosted seed-17 failure.

- timestamp: 2026-09-27T14:09:12Z
  checked: full example-host isolation matrix after matching root dependency setup
  found: Seed 17 tagged class passed. Seed 17 complete class failed with exit 2 after 2095 tests, 1 failure (10 excluded), matching hosted diagnostic. The matrix prints only the last 80 log lines, which contain the summary but omit the earlier failure, and deletes its captured log on exit.
  implication: The failure is reproducible at the exact PR head; run the complete child command with durable capture to identify the test. The diagnostic truncation is a separate observability defect.

- timestamp: 2026-09-27T14:11:20Z
  checked: persistent log from direct complete seed-17 command
  found: The first and only visible failure is `Mix.Tasks.Crosswake.Gen.BridgeHookTest` at `test/mix/tasks/crosswake_gen_bridge_hook_test.exs:53`: `ArgumentError unknown application: :crosswake` from `Application.app_dir(:crosswake, "priv/static/crosswake.esm.js")` in the generator's `source_path/0`. The test module is `async: true`; no explicit `Application.unload(:crosswake)` appears in project test or lib source.
  implication: Need distinguish standalone task defect from test-order or concurrent VM application-state interference before fixing.

- timestamp: 2026-09-27T14:15:50Z
  checked: standalone bridge-hook test and direct complete-class rerun
  found: The bridge-hook file passes 6/6 alone at seed 17. The direct full command again exits 2 with one failure at the same ejection test. Elixir `Application.app_dir/1` reads the global code path through `:code.lib_dir/1`; the analogous shell-generator test is already serialized because of the same shared resource.
  implication: A targeted test-isolation change is supported; rerun the full class to falsify it.

- timestamp: 2026-09-27T14:22:51Z
  checked: full matrix after changing only bridge-hook test to `async: false`
  found: Seed 17 tagged passed, but complete class still failed: 2095 tests, 4 failures. The bridge-hook error disappeared; three Phase174 clean-room parity tests and one release-ledger test instead raised `File.Error` reading valid repo-relative paths (`.github/workflows/release-please.yml`, `script/verify_companion_cleanroom.sh`, and ledger/evidence files). Their module declarations are `async: true`.
  implication: The one-line fix protects one consumer but does not resolve the shared VM cwd/code-path disturbance. The symptom moves with scheduling, so the underlying mutator must be identified and corrected.

- timestamp: 2026-09-27T14:29:00Z
  checked: exact-head seed-17 run with `:file.set_cwd/1`, `:prim_file.set_cwd/1`, and periodic cwd tracing
  found: Early async failures shifted again to existing functions reported undefined and valid relative repo files reported missing. The first traced cwd operations occurred only after async tests ended, from already-serialized `Crosswake.Shell.StatusTest`; no cwd shift was sampled during async failures. A separate concurrent `System.cmd(..., cd: ...)` probe made 2000 calls without moving parent VM cwd.
  implication: The known sync `File.cd!` tests and ordinary `System.cmd` cd handling are not established causes; record cwd at the exact failed file read to distinguish an unobserved brief change from a different filesystem issue.

- timestamp: 2026-09-27T14:43:10Z
  checked: full exact-head seed-17 run with `:file.read_file/1` error tracing
  found: 2095 tests produced five failures. `HexPageTest` compiled its `@root File.cwd!()` as the real clone's `deps/telemetry`, causing CHANGELOG/docs paths to resolve there; Phase165 CI policy test also launched Python with relative script path under `deps/telemetry`. The tracer's own cwd remained repository root and logged no early `set_cwd` event. A separate mirror fixture tag collision was caused by reused temp output.
  implication: The file paths were not deleted. A transient wrong cwd during parallel test compilation is directly visible in compiled attributes, but the mutating process remains to be captured.

- timestamp: 2026-09-27T14:45:00Z
  checked: `:file.get_cwd/0` return trace and async Mix task call sites
  found: The trace produced a different first async relative-file failure (missing favicon) but all sampled `get_cwd` results were the repository root; the transient window was missed. `EvidenceGateTest` is `async: true` and calls `Mix.Task.clear()` immediately before invoking `Crosswake.Release.Gate`, which calls `Mix.Task.run("app.config")`. `CrosswakeReleaseStatusTest` is also async and clears Mix task state, but does not call app.config itself.
  implication: Test a narrow serialization of the app.config caller to discriminate whether its global Mix activity causes the observed cwd/code-path interference.

- timestamp: 2026-09-27T14:50:20Z
  checked: one-line EvidenceGateTest serialization probe with fresh temp runtime
  found: Full seed-17 complete class passed: 2095 tests, 0 failures (10 excluded), 255.0 seconds. Elixir 1.19.5 source confirms `Mix.Task.clear/0` clears global `Mix.TasksServer`, and `Mix.Tasks.App.Config.run/1` invokes `Mix.Task.run("compile", args)`.
  implication: This is the first intervention to remove all moving failures; retain the narrow change and verify the exact matrix before acceptance.

- timestamp: 2026-09-27T14:55:00Z
  checked: exact example-host isolation matrix with the narrow fix
  found: Seed 17 tagged and complete classes passed; seed 101 tagged passed. The matrix is still running seed 101 complete and seed 1009 classes.
  implication: The originally failing required class is green twice with the narrow fix; finish the remaining matrix before committing and rerunning hosted required CI.

- timestamp: 2026-09-27T15:05:00Z
  checked: exact `script/check_example_host_isolation.sh --matrix-only` run with only EvidenceGateTest serialization
  found: All six classes passed: tagged and complete for seeds 17, 101, and 1009. `git diff --check` passed, and the isolated clone contains only the intended one-file edit. The original failing seed-17 complete class also passed a separate direct full run (2095 tests, 0 failures).
  implication: Local fix-acceptance guardrail is green; commit and rerun hosted exact-head required CI.

- timestamp: 2026-09-27T15:08:00Z
  checked: isolated branch commit, current remote base, PR diff, and push
  found: One-file fix committed as `0680dea02fd09c47eef3ccba7afa298d241d60e8`. Remote PR head was still `85ba10d` and base `b232e258` (BEHIND). Merged current main cleanly into the fix branch, producing `717b62b2c07651beba48982c20b6548608beb0a2`; both prior PR head and base are ancestors, `git diff --check` passed, and branch push fast-forwarded successfully. Crosswake CI run 36328329180 started with 48 checks, 47 pending, 0 failing at first observation.
  implication: The PR now has the fix plus current base, and hosted required checks are running. Merge remains conditional on exact-head success.

- timestamp: 2026-09-27T15:11:00Z
  checked: GitHub Actions run identity and protected-context snapshot
  found: Run 36328329180 has head SHA exactly `717b62b2c07651beba48982c20b6548608beb0a2` (independently confirmed by parent). Current branch protection has `strict: true` and one required context, `Crosswake CI`. The run has no failing leaf checks at first progress observation, with the longer proof lanes still pending.
  implication: Monitor the exact-head run to completion and require its protected umbrella context to pass before merge.

- timestamp: 2026-09-27T16:05:46Z
  checked: exact-head hosted CI and protected PR merge
  found: Crosswake CI run 36328329180 completed `success` for exact head `717b62b2c07651beba48982c20b6548608beb0a2`. `proof-requires-example-host` and protected required `Crosswake CI` both reported `SUCCESS`; `ci_monitor pr-checks 214` showed 49 total, 0 failing, 0 pending. Immediately before merge, PR was OPEN/CLEAN/MERGEABLE at the same head and current base `b232e258`; live required-context snapshot remained valid. Protected merge with `--match-head-commit` succeeded. PR state is MERGED at 2026-09-27T16:05:46Z, merge commit `8498252407922801211350bf81f76d964c55bd3c`.
  implication: Original required-CI failure is resolved and PR #214 is merged under the user's conditional authorization.

## Eliminated

- hypothesis: The generator fails in ordinary standalone use because `:crosswake` is never loaded.
  evidence: The same test file passes 6/6 alone at seed 17 with the same compiled package and environment.
  timestamp: 2026-09-27T14:15:50Z

- hypothesis: Serializing only the bridge-hook test fixes the seed-17 full-suite failure.
  evidence: Full matrix with that sole change failed seed 17 complete with four different repo-relative File.Error failures.
  timestamp: 2026-09-27T14:22:51Z

- hypothesis: The already-serialized shell-status or doctor `File.cd!` tests overlap the early async failures.
  evidence: Enhanced trace showed their `:file.set_cwd/1` calls only after the async failures and after the async phase ended.
  timestamp: 2026-09-27T14:29:00Z

## Resolution

- root_cause: Async EvidenceGateTest globally clears Mix task state and invokes app.config/compile during concurrent ExUnit test-file loading; Mix dependency loading can displace cwd/code-path state, producing seed-sensitive wrong-root and unknown-application failures.
- oracle_type: specified (the full example-host isolation matrix must pass every seed/class)
- fix: Serialize EvidenceGateTest because it invokes global Mix compile state, with an explanatory comment in the test module.
- verification: Direct seed-17 complete class passed 2095 tests, 0 failures; exact three-seed tagged+complete isolation matrix passed all six classes; `git diff --check` passed. Hosted run 36328329180 succeeded on exact head 717b62b2 with 49 checks, 0 failures, 0 pending, including protected Crosswake CI. Protected PR merge completed as 8498252407922801211350bf81f76d964c55bd3c.
- files_changed: [test/crosswake/release_candidate/evidence_gate_test.exs]
- code_commit: 0680dea02fd09c47eef3ccba7afa298d241d60e8
- pr_head_after_base_merge: 717b62b2c07651beba48982c20b6548608beb0a2
- merge_commit: 8498252407922801211350bf81f76d964c55bd3c
