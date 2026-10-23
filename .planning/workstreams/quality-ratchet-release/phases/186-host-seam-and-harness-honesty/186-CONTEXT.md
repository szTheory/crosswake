# Phase 186: Host seam and harness honesty - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

<domain>
## Phase Boundary

The host-command seam denies rather than silently grants. Doctor reports instead of passing when it cannot read its inputs. No output about package paths leaks an absolute home path or username. The loopback Simulator harness cannot report a pass after its own failure. Physical-iPhone proof preparation refuses a host generated in local loopback mode.

Requirements: SEAM-07, SEAM-08, SEAM-09, LOOP-06, LOOP-07. Manifest schema 1.2.0 and the public API stay unchanged. There is no new CI lane. The twin, Simulator, xcodebuild and twin-05 are not run in this phase; Phase 188 reruns the twin.

Code truth is the product candidate `/private/tmp/crosswake-phase180-impl` (detached HEAD `25614cf6`, push URL disabled). Planning files in the recovery checkout stay plain uncommitted files.

</domain>

<decisions>
## Implementation Decisions

**How these were reached.** On 2026-10-16 a read-only research agent read the 181 and 182 reviews, the 184 and 185 decisions and the candidate code. It returned one coherent recommendation, and the user approved all of it as one set. The rationale is in `186-DISCUSSION-LOG.md`.

**Carried forward from Phases 184 and 185:**
- Every guard has a source of truth that is independent of the thing it guards.
- Every guard has a red run before its fix and a recorded mutation control that reverts the fix.
- Nothing skipped, unreadable or cleanup-failed may score as success.
- There is no new CI lane.
- All of the phase's code lands in one candidate commit.

### Legacy manifest denial (SEAM-07)
- **D-01: Grant nothing on a legacy route.** This applies in `ActivationCoordinator.swift` (legacy branch around :274-282) when a manifest route has no `host_commands` key.
  - The native session denies every `host.*` name in `route.capabilities`, plus the request's `host.*` keys on the entry route.
  - Reasons:
    - A command whose version fails `supportsCommandVersion` gets `version_unsupported`.
    - Every other command gets `not_registered`, read as "the manifest did not register it for this route".
  - Denials go through the existing `recordHostCommandDenials` (around :643). Declared names that are not registered, which today are dropped silently (around :704-709), therefore also produce a diagnostic.
  - There is no compatibility window; the repair is to regenerate.
  - Reversibility: costly. It is a behaviour change for already-generated hosts, so add a CHANGELOG "Unreleased" line.
- **D-02: One new doctor finding, `host_commands_legacy_manifest`.**
  - It fires for a fixture route that has no `host_commands` key.
  - Severity:
    - `:error` when the router declares host commands on that route;
    - `:warning` otherwise.
  - Details: `%{route_ids, platform}`. Hint: "Run mix crosswake.gen.shell ios".
  - The stale check (D-04) skips those routes, so each problem gets exactly one code.
  - The guide explains the legacy shape and the repair.
- **D-03: What does not change.**
  - Manifest schema 1.2.0.
  - The `LiveViewSession` fields.
  - The bridge reason texts in `BridgeChannel.swift` (:438-465). The `not_registered` text is pinned in `HostCommandSeamTests.swift:330-331`.
  - No new reason string is added.
  - Accepted limit: on a legacy route, a registered command at a supported version gets the `not_registered` text ("this app has not registered it"), which is slightly misleading. The doctor finding and the guide carry the real repair.

### Stale check (SEAM-08)
- **D-04: Keep the single code `host_commands_stale` at severity `:error`** (`doctor.ex` around :2448-2482). Each case gets its own message and its own `details.reason`:
  - `unreadable`: any `File.read` error other than `:enoent`.
  - `malformed`: any of these:
    - decoding fails;
    - the top level is not a map;
    - `routes` is missing or is not a map;
    - a route is not a map;
    - `host_commands` is not a map of strings to strings.
  - `route_missing`: a router route with non-empty `host_commands` is absent from the fixture.
  
  These cases replace the `else _ -> []` fall-through (around :2481), which passes silently today.
- **D-05: An absent fixture stays "skipped", but visibly.**
  - Today an absent fixture returns `[]`.
  - The fix emits an `:advisory` finding, `host_commands_stale_skipped`. It fires only when the iOS root exists and some router route declares host commands.
  - Advisory findings do not change doctor's pass/fail status (around :213), so the skip is visible but scores neither as a pass nor as a fail.

### Path redaction (SEAM-09)
- **D-06: One copied helper, with no new module and no new dependency.**
  - The helper is `@doc false` `ShellPackage.display_location(location, project_root)`, placed in `lib/crosswake/shell/shell_package.ex`, the module that owns `location`.
  - Its body is copied from `relative_path/2` in `lib/mix/tasks/crosswake.gen.shell.ex` (around :793).
  - Rules:
    - a path inside the project becomes project-relative;
    - a path under the home directory becomes `<home>/…`;
    - anything else becomes `<outside project>`;
    - a `remote …` value is left unchanged.
  - Canonicalize paths before comparing them, and never return the input unchanged (see Footguns).
- **D-07: Callers.**
  - Doctor's host-command and package message and `details.package_location` (`doctor.ex` around :2522, :2529), with the root set to the current working directory.
  - `shell_gate_message` (`lib/crosswake/shell/ios_host_generation.ex` around :95, :121), with the root passed in through `render_opts` from `gen.shell` (around :134).
  - Raised errors about package paths.
- **D-08: The sentinel-directory test.**
  - The project lives in a temp directory whose name contains a sentinel string.
  - The test asserts that neither the sentinel nor `System.user_home!()` appears in any of these:
    - the `host_commands` and package doctor findings (message, hint and details);
    - the gate's `{:error, msg}`;
    - a rescued `Mix.raise` text;
    - the phase evidence files.
  - The scan covers only the host-command and package surfaces, as SEAM-09 says ("about package paths"). Other absolute paths that doctor already prints are deferred.
- **D-09: The M-01 fix is a guide edit only.** In `guides/compatibility.md` (around :54-56), replace "refuses to activate … when the major versions differ" with floor wording: the route activates, and each declared command is denied with `seam_unsupported`. Add a matching needle to `test/crosswake/guides/host_command_seam_guide_test.exs`. The code's floor semantics do not change.

### Loopback harness (LOOP-06)
- **D-10: Exit logic.**
  - Keep `set -euo pipefail` and the EXIT trap.
  - Inside `cleanup_and_emit`, which deliberately runs under `set +e`, check each status explicitly.
- **D-11: Hash coverage (182 WR-03).**
  - Take a full-tree hash list at three points: before the swap, after the build, and at exit.
  - The only change allowed is `CrosswakeShell/CrosswakeShellApp.swift`, and its new hash must equal `ProbeApp.swift`.
  - Zero changes also fails.
- **D-12: Evidence writing (182 WR-04).**
  - Check before the build that the evidence directory is writable.
  - Write to a temp file and then `mv` it into place, checking both steps.
  - On failure the result is `blocked`, with rule `LOOP-IOS-EVIDENCE` and exit 2.
- **D-13: Cleanup (182 WR-05).** If the run passed but the app was not uninstalled, or the device was not restored to how it was found, the result is `blocked`, with rule `LOOP-IOS-CLEANUP` and exit 2.
  - The WR-05 fix makes 182 IN-02 load-bearing. The `grep -q` under pipefail (around :159) can wrongly report "not shut down", so capture the output into a variable first.
- **D-14: Prove it with ExUnit and PATH shims, never a Simulator.**
  - Follow the pattern in `test/crosswake/proof_lane/ios_verifier_test.exs`: a bin directory plus a `*_SHIM_MODE` variable.
  - Run against a temp git repo that holds copies of the script and its helpers.
  - Shim `mix`, `xcrun`, `xcodebuild` and `plutil`. The `simctl launch` shim GETs the listener and writes `result.txt`.
  - Replace `/usr/libexec/PlistBuddy` (around :312) with `plutil -extract CFBundleIdentifier raw`, since PlistBuddy cannot be shimmed.
  - Each case changes exactly one thing from a passing baseline.
- **D-15: Documentation.**
  - Add a short "manual Simulator harness" paragraph to `guides/native_shell.md`, in the Declared iOS Host Setup section (around :57).
  - It gives the command and the exit codes 0, 2 and 3, and says the harness is manually run phase evidence, not a CI lane.
  - Do not edit the generated guides (`capability_map.md`, `support_matrix.md`).

### Physical-iPhone preparation (LOOP-07)
- **D-16: Write the test first, red.**
  - Drive `PhysicalIphone.run_with/2` in each of `--preflight-only`, `--readiness` and `--run`, with every host callback passing.
  - Cases:
    - (a) a local `:ios_host` declaration;
    - (b) a real local-mode `gen.shell` output on disk, with a production declaration.
  - Assert that the result is blocked and that `device_report` is never called.
  - Research found that none of the physical-iPhone task, the preflight or the host module reads the origin mode, so a fix is expected. The red run is what decides it.
- **D-17: The fix, only if D-16 is red.**
  - In `run_with`, read `Keyword.get_lazy(options, :ios_host, …)` (the same pattern as `doctor.ex` around :2424).
  - Call `IOSHostOriginMode.observe/2`.
  - Any result other than `:none` maps to the existing `PI-PREFLIGHT-CONFIG` rule, using the text from `Generator.local_mode_refusal/0`.
  - No new rule id.

### Order of work
- **D-18: Plans and sequencing.**
  - All of Phase 186's `doctor.ex` edits (D-02, D-04, D-05 and the doctor side of D-07) go in one plan, which does not run in parallel with any other plan that touches `doctor.ex`.
  - The Swift (D-01), harness (D-10..D-15) and iPhone-preparation (D-16/17) plans are independent. Under the forced isolation `none` they still run one at a time in the shared tree.
  - A final plan:
    - runs the full gates against the Phase 185 baseline;
    - records the mutation controls;
    - makes one `fix(186)` candidate commit;
    - checks the committed candidate with the source probe and the read-only preflight.
  - Phase 187 builds on that commit.
- **D-19: The Phase 185 review warnings stay out of scope.**
  - WR-02, WR-04 and WR-05 touch the twin.
  - WR-03 belongs to the absence checker.
  - Reuse WR-05's lesson here: prefer an `eisdir` fixture (the path is a directory) for "unreadable". Any chmod-based test must skip explicitly under uid 0, and must never report a pass that asserted nothing.

### Claude's Discretion
- The exact wording of the messages and hints, within the codes and reasons above.
- How fixtures are laid out, and which test files the new cases go in.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and governance
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §Phase 186: the goal and the five success criteria.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: SEAM-07, SEAM-08, SEAM-09, LOOP-06 and LOOP-07, plus the deferral list (around :108).
- `.planning/workstreams/quality-ratchet-release/STATE.md`
- `AGENTS.md`: the checkout rules, sensitive data rules, frozen Android and the "no new CI lane" rule.
- `.planning/research/v26/SUMMARY.md`, `ARCHITECTURE.md`, `FEATURES.md`, `PITFALLS.md` and `CHALLENGE.md`

### Source findings
- `.planning/workstreams/quality-ratchet-release/phases/181-core-host-command-seam/181-REVIEW.md` and `181-REVIEW-DISPOSITION.md`: M-01 to M-04, and the `180-SEAM-HANDOFF.json` binding.
- `.planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-REVIEW.md` and `182-REVIEW-DISPOSITION.md`: WR-03, WR-04, WR-05 and IN-02.

### Carried-forward posture
- `.planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-CONTEXT.md`
- `.planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-CONTEXT.md` and `185-REVIEW-DISPOSITION.md`

### Candidate code (`/private/tmp/crosswake-phase180-impl`)
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/shell/shell_package.ex`, `ios_host_generation.ex` and `ios_host_origin_mode.ex`
- `lib/mix/tasks/crosswake.gen.shell.ex` and `crosswake.gen.proof_lane.ex`
- `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`
- `lib/crosswake/proof_lane/physical_iphone_preflight.ex`, `physical_iphone_host.ex` and `generator.ex` (the refusal around :677-695)
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` and `BridgeChannel.swift`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandSeamTests.swift`, `HostCommandNavigationTests.swift` and `Resources/host_command_seam_fixture.json`
- `test/crosswake/doctor/doctor_host_commands_test.exs`
- `test/crosswake/guides/host_command_seam_guide_test.exs`
- `test/crosswake/proof_lane/ios_verifier_test.exs` (the shim pattern)
- `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` and `crosswake_gen_proof_lane_test.exs`
- `script/verify_loopback_origin_simulator.sh` and `script/loopback_origin_simulator/`
- `guides/compatibility.md`, `native_shell_upgrade.md` and `native_shell.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `recordHostCommandDenials`, in `ActivationCoordinator.swift`: the existing path for recording denials, reused for legacy routes.
- `relative_path/2`, in `gen.shell`: the body that the redaction helper is copied from.
- `Generator.local_mode_refusal/0`: refusal text for local mode that LOOP-07 reuses.
- `IOSHostOriginMode.observe/2`: observes the origin mode for LOOP-07.
- The PATH-shim pattern in `ios_verifier_test.exs`.
- The shared `host_command_seam_fixture.json` `legacy_manifest`, read by both Swift and Elixir. It is the independent source of truth for SEAM-07.

### Established Patterns
- Doctor finding severities: `:error`, `:warning` and `:advisory`. Advisory findings do not change the status.
- Exit codes 0, 2 and 3 in the harness, and the `0|1|2` convention elsewhere.
- Mutation controls follow the Phase 184/185 shape:
  - a throwaway copy of the candidate and a private `MIX_BUILD_PATH`;
  - one edit, with sha256 before and after required to differ;
  - no zero-test runs.

### Integration Points
- `doctor.ex` is edited again in Phase 187, so 186's doctor edits land first, in one plan.
- The Swift change moves the package head and so affects the `180-SEAM-HANDOFF.json` binding. Run `swift test` (not xcodebuild) and the Phase 180 Swift tests. Phase 188 refreshes the handoff records.

</code_context>

<specifics>
## Specific Ideas

### Footguns to flag for planning and execution
- Existing tests that pin the old behaviour must flip, red first:
  - `HostCommandNavigationTests.swift:95-116` (the legacy grant);
  - the guide needle "keeps working for the entry route only" (`host_command_seam_guide_test.exs:73`) and `guides/native_shell_upgrade.md:70-76`;
  - `doctor_host_commands_test.exs:66-86`, whose "stale" fixture deletes the key, which is now the legacy shape. Rewrite it as a version mismatch.
- `Path.relative_to/2` returns an outside path unchanged, so it would leak it. On macOS, `/var` vs `/private/var` breaks prefix matching. Canonicalize first, and never fall back to the raw input.
- A sentinel scan over all of doctor's output would hit leaks that existed before this phase (`doctor.ex` around :266-367, :1008, :2546). Keep the scan scoped as in D-08.
- `/usr/libexec/PlistBuddy` cannot be shimmed and is absent on Linux CI; use `plutil`.
- `grep -q` under pipefail gives false negatives (182 IN-02). Capture the output into a variable first.
- A chmod-000 test asserts nothing when run as root (185 WR-05). Use `eisdir`, or skip explicitly.
- Unverified by research:
  - whether `shasum` exists on the Ubuntu CI image (prefer a portable hash, or guard for it);
  - whether the LOOP-07 test actually goes red;
  - what "evidence files" covers beyond the phase logs and the harness JSON. No existing writer puts package paths into an evidence file; record what was scanned.

</specifics>

<deferred>
## Deferred Ideas

- 182 WR-06: `inspect` prints the production origin, a privacy issue next to SEAM-09.
- 182 IN-03: the harness has no timeouts.
- The harness uninstalls an app the user may already have installed on that Simulator (around :325).
- 185 WR-03: `--min-test-files` accepts 0. It belongs to the absence checker.
- 185 WR-02, WR-04 and WR-05: carried to the next change that touches the twin.
- Other absolute paths in doctor output, outside the host-command and package surfaces.
- `hostCommandDeniedVersions` is empty on legacy routes.
- Already deferred in REQUIREMENTS.md: 181 L-01, L-02, L-04, L-05 and L-06; 182 WR-01, WR-02 and WR-06.

</deferred>

---

*Phase: 186-host-seam-and-harness-honesty*
*Context gathered: 2026-10-16*
