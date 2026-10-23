# Phase 186: Host seam and harness honesty - Research

**Researched:** 2026-10-16
**Domain:** Swift shell activation (host-command seam), Elixir doctor and generation gates, bash Simulator harness, physical-iPhone proof preparation
**Confidence:** HIGH for code locations and current behaviour (all read this session in the candidate); MEDIUM for Linux CI tool availability and for what Xcode writes into the generated project during a build (not run, by rule)

Code truth is the candidate checkout `/private/tmp/crosswake-phase180-impl` (detached HEAD `25614cf6`, `fix(185)`). Provenance tags: `[VERIFIED: path:lines]` means I opened that file this session and quote the value; `[ASSUMED]` means not verified here.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward from Phases 184 and 185:**
- Every guard has a source of truth that is independent of the thing it guards.
- Every guard has a red run before its fix and a recorded mutation control that reverts the fix.
- Nothing skipped, unreadable or cleanup-failed may score as success.
- There is no new CI lane.
- All of the phase's code lands in one candidate commit.

**Legacy manifest denial (SEAM-07)**
- **D-01: Grant nothing on a legacy route.** This applies in `ActivationCoordinator.swift` (legacy branch around :274-282) when a manifest route has no `host_commands` key.
  - The native session denies every `host.*` name in `route.capabilities`, plus the request's `host.*` keys on the entry route.
  - Reasons: a command whose version fails `supportsCommandVersion` gets `version_unsupported`; every other command gets `not_registered`, read as "the manifest did not register it for this route".
  - Denials go through the existing `recordHostCommandDenials` (around :643). Declared names that are not registered, which today are dropped silently (around :704-709), therefore also produce a diagnostic.
  - There is no compatibility window; the repair is to regenerate.
  - Reversibility: costly. It is a behaviour change for already-generated hosts, so add a CHANGELOG "Unreleased" line.
- **D-02: One new doctor finding, `host_commands_legacy_manifest`.** Fires for a fixture route that has no `host_commands` key. Severity `:error` when the router declares host commands on that route; `:warning` otherwise. Details: `%{route_ids, platform}`. Hint: "Run mix crosswake.gen.shell ios". The stale check (D-04) skips those routes, so each problem gets exactly one code. The guide explains the legacy shape and the repair.
- **D-03: What does not change.** Manifest schema 1.2.0. The `LiveViewSession` fields. The bridge reason texts in `BridgeChannel.swift` (:438-465); the `not_registered` text is pinned in `HostCommandSeamTests.swift:330-331`. No new reason string. Accepted limit: on a legacy route, a registered command at a supported version gets the `not_registered` text ("this app has not registered it"), which is slightly misleading; the doctor finding and the guide carry the real repair.

**Stale check (SEAM-08)**
- **D-04: Keep the single code `host_commands_stale` at severity `:error`** (`doctor.ex` around :2448-2482). Each case gets its own message and its own `details.reason`:
  - `unreadable`: any `File.read` error other than `:enoent`.
  - `malformed`: decoding fails; the top level is not a map; `routes` is missing or is not a map; a route is not a map; `host_commands` is not a map of strings to strings.
  - `route_missing`: a router route with non-empty `host_commands` is absent from the fixture.
  These cases replace the `else _ -> []` fall-through (around :2481), which passes silently today.
- **D-05: An absent fixture stays "skipped", but visibly.** The fix emits an `:advisory` finding, `host_commands_stale_skipped`. It fires only when the iOS root exists and some router route declares host commands. Advisory findings do not change doctor's pass/fail status (around :213).

**Path redaction (SEAM-09)**
- **D-06: One copied helper, no new module, no new dependency.** `@doc false` `ShellPackage.display_location(location, project_root)` in `lib/crosswake/shell/shell_package.ex`. Body copied from `relative_path/2` in `lib/mix/tasks/crosswake.gen.shell.ex` (around :793). Rules: inside the project becomes project-relative; under the home directory becomes `<home>/…`; anything else becomes `<outside project>`; a `remote …` value is left unchanged. Canonicalize paths before comparing, and never return the input unchanged.
- **D-07: Callers.** Doctor's host-command and package message and `details.package_location` (`doctor.ex` around :2522, :2529), root = current working directory. `shell_gate_message` (`lib/crosswake/shell/ios_host_generation.ex` around :95, :121), root passed through `render_opts` from `gen.shell` (around :134). Raised errors about package paths.
- **D-08: The sentinel-directory test.** The project lives in a temp directory whose name contains a sentinel string. Assert neither the sentinel nor `System.user_home!()` appears in: the `host_commands` and package doctor findings (message, hint, details); the gate's `{:error, msg}`; a rescued `Mix.raise` text; the phase evidence files. Scope is only the host-command and package surfaces. Other absolute paths doctor already prints are deferred.
- **D-09: The M-01 fix is a guide edit only.** In `guides/compatibility.md` (around :54-56), replace "refuses to activate … when the major versions differ" with floor wording: the route activates, and each declared command is denied with `seam_unsupported`. Add a matching needle to `test/crosswake/guides/host_command_seam_guide_test.exs`. Code floor semantics do not change.

**Loopback harness (LOOP-06)**
- **D-10: Exit logic.** Keep `set -euo pipefail` and the EXIT trap. Inside `cleanup_and_emit` (deliberately `set +e`), check each status explicitly.
- **D-11: Hash coverage (182 WR-03).** Full-tree hash list at three points: before the swap, after the build, at exit. Only `CrosswakeShell/CrosswakeShellApp.swift` may change, and its new hash must equal `ProbeApp.swift`. Zero changes also fails.
- **D-12: Evidence writing (182 WR-04).** Check before the build that the evidence directory is writable. Write to a temp file then `mv` into place, checking both. On failure the result is `blocked`, rule `LOOP-IOS-EVIDENCE`, exit 2.
- **D-13: Cleanup (182 WR-05).** If the run passed but the app was not uninstalled, or the device was not restored to how it was found, the result is `blocked`, rule `LOOP-IOS-CLEANUP`, exit 2. This makes 182 IN-02 load-bearing: the `grep -q` under pipefail (around :159) can wrongly report "not shut down", so capture the output into a variable first.
- **D-14: Prove with ExUnit and PATH shims, never a Simulator.** Follow `test/crosswake/proof_lane/ios_verifier_test.exs`: a bin directory plus a `*_SHIM_MODE` variable. Run against a temp git repo holding copies of the script and helpers. Shim `mix`, `xcrun`, `xcodebuild`, `plutil`. The `simctl launch` shim GETs the listener and writes `result.txt`. Replace `/usr/libexec/PlistBuddy` (around :312) with `plutil -extract CFBundleIdentifier raw`. Each case changes exactly one thing from a passing baseline.
- **D-15: Documentation.** Short "manual Simulator harness" paragraph in `guides/native_shell.md`, Declared iOS Host Setup (around :57): the command, exit codes 0, 2 and 3, and that it is manually run phase evidence, not a CI lane. Do not edit generated guides (`capability_map.md`, `support_matrix.md`).

**Physical-iPhone preparation (LOOP-07)**
- **D-16: Write the test first, red.** Drive `PhysicalIphone.run_with/2` in each of `--preflight-only`, `--readiness` and `--run`, every host callback passing. Cases: (a) a local `:ios_host` declaration; (b) a real local-mode `gen.shell` output on disk, with a production declaration. Assert blocked and that `device_report` is never called. The red run decides whether a fix is needed.
- **D-17: The fix, only if D-16 is red.** In `run_with`, read `Keyword.get_lazy(options, :ios_host, …)` (same pattern as `doctor.ex` around :2424). Call `IOSHostOriginMode.observe/2`. Any result other than `:none` maps to the existing `PI-PREFLIGHT-CONFIG` rule, using the text from `Generator.local_mode_refusal/0`. No new rule id.

**Order of work**
- **D-18:** All of Phase 186's `doctor.ex` edits (D-02, D-04, D-05, doctor side of D-07) go in one plan, not parallel with any other plan touching `doctor.ex`. Swift (D-01), harness (D-10..D-15) and iPhone-preparation (D-16/17) plans are independent but run one at a time (forced isolation `none`). A final plan runs the full gates against the Phase 185 baseline, records the mutation controls, makes one `fix(186)` candidate commit, and checks the committed candidate with the source probe and the read-only preflight. Phase 187 builds on that commit.
- **D-19:** The Phase 185 review warnings stay out of scope (WR-02, WR-04, WR-05 touch the twin; WR-03 belongs to the absence checker). Prefer an `eisdir` fixture for "unreadable". Any chmod-based test must skip explicitly under uid 0 and never report a pass that asserted nothing.

### Claude's Discretion
- The exact wording of the messages and hints, within the codes and reasons above.
- How fixtures are laid out, and which test files the new cases go in.

### Deferred Ideas (OUT OF SCOPE)
- 182 WR-06 (`inspect` prints the production origin); 182 IN-03 (harness has no timeouts); the harness uninstalls an app the user may already have installed (around :325); 185 WR-03 (`--min-test-files` accepts 0); 185 WR-02, WR-04, WR-05; other absolute paths in doctor output outside the host-command and package surfaces; `hostCommandDeniedVersions` is empty on legacy routes; already deferred in REQUIREMENTS.md: 181 L-01, L-02, L-04, L-05, L-06; 182 WR-01, WR-02, WR-06.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEAM-07 | Legacy-shaped manifest route (no `host_commands` key) denies each registered `host.*` command; doctor reports it with repair hint; guide explains; schema and public API unchanged | Swift branch map, test flips, doctor `host_commands_legacy_manifest`, guide/CHANGELOG sites below |
| SEAM-08 | `host_commands_stale` errors on unreadable/malformed fixture and router route missing from manifest; absent fixture stays visibly skipped | Current `with … else _ -> []` quoted, fixture recipes, `:advisory` mechanism |
| SEAM-09 | Only project-relative paths in doctor, gate messages, raised text, evidence; one copied helper; guide version wording matches floor semantics | `relative_path/2` and `shell_gate_message` sites, canonicalization footgun, sentinel recipe, compatibility.md floor wording |
| LOOP-06 | Harness exits non-zero on uncovered hash, evidence-write failure, uninstall/restore failure; documented as manual evidence | Full script walk, shim design, Linux availability |
| LOOP-07 | Regression test: physical-iPhone proof preparation refuses a local-loopback host; preflight code only if test is red | Read-through shows red by construction; injection keys |
</phase_requirements>

## Summary

All five requirements are tractable with the decisions as locked; no library or package is added, so there is no package-legitimacy exposure. The main work is a one-branch Swift change, a single doctor edit session, a bash-script hardening with an ExUnit shim suite, and one preflight check. Three facts the plan must absorb:

1. `swift test` runs locally on this machine (Swift 6.3.3, macOS 26) with `--scratch-path` outside the candidate, so the SEAM-07 red/green is locally verifiable and is also what CI's `ios-package-unit` runs. The candidate's Swift baseline is already red in one pre-existing test (`Phase180TwinFeasibilityTests.test_G4_gate_bounded_shell_denies_offline_island_runtime`): 86 tests, 2 skipped, 1 failure. That is a baseline to record, not a regression to fix here. [VERIFIED: ran `swift test --scratch-path /private/tmp/crosswake-phase180-run/_swiftbuild_186_research`, output in `swift-186-research-full.out`: "Executed 86 tests, with 2 tests skipped and 1 failure (0 unexpected)"]
2. A second Swift test pins the old legacy grant and is invisible in CI because it is skipped: `Phase180TwinFeasibilityTests.test_G3_control_exported_request_carrying_command_reaches_delegate` asserts `XCTAssertEqual(live.capabilities[command], "1.0.0")` on a manifest whose route has no `hostCommands` (legacy). It `XCTSkip`s unless `PHASE180_EXPORT_DIR` is set (Phase 188's twin sets it). D-01 will make it red there. It must be rewritten in this phase (give the manifest route `hostCommands: [command: "1.0.0"]` and `capabilities: [command]`, or flip the assertion to a denial). [VERIFIED: Phase180TwinFeasibilityTests.swift:75-76 `throw XCTSkip("PHASE180_EXPORT_DIR is not set")`; `makeManifest` builds `ShellManifest.Route(... capabilities: [] ...)` with no `hostCommands`]
3. `relative_path/2` in `gen.shell` is not the redaction rule D-06 describes. It returns a `..`-walk relative path for any destination (including outside the project), never `<home>/…` or `<outside project>`. "Copy its body" means reuse the common-prefix algorithm for the inside-project branch; the home and outside branches are new code, and symlink canonicalization has no stdlib function (Elixir has no `File.realpath`), so the helper needs a small private component-wise resolver. See Pitfall 1.

**Primary recommendation:** Five sequential plans: (01) doctor.ex + ShellPackage + gen.shell/ios_host_generation, (02) Swift + guides + CHANGELOG, (03) harness + shim suite, (04) LOOP-07 red test then fix, (05) final gates, mutation controls, one `fix(186)` commit.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deny `host.*` on legacy route | Native shell (Swift `grantHostCommands`) | Generated manifest fixture | Session grants are decided natively; the manifest only supplies the declaration |
| Report legacy/stale/unreadable fixture | Mix tooling (doctor) | Generated fixtures on disk | Doctor reads the generated iOS fixture and compares to the compiled router manifest |
| Path redaction | Shared Elixir helper at output sites | Callers (doctor, gen.shell gate) | Redact at print time; `ShellPackage.resolve` keeps raw locations because the gate and tests compare them |
| Harness pass/fail honesty | Bash script (exit/emit trap) | ExUnit shim suite | Script owns the verdict; tests drive it with fake tools |
| Refuse local-loopback host for device proof | Mix task / preflight | Generator refusal at generation time | Generation already refuses; preparation must independently refuse (independent source of truth) |

## Standard Stack

No new packages. Everything uses what is already in the candidate.

### Core
| Tool | Version | Purpose | Evidence |
|------|---------|---------|----------|
| Elixir / OTP | 1.19.5 / 27.3 | ExUnit tests, doctor, tasks | [VERIFIED: `.tool-versions` "erlang 27.3 / elixir 1.19.5-otp-27"] |
| SwiftPM `swift test` | Swift 6.3.3 (local), CI `macos-latest` | Native seam tests | [VERIFIED: `swift --version`; CI job `ios-package-unit` runs `script/verify_repository.sh --stage ios-package-proof`, whose stage argv is `["swift", "test"]` in `repository_verification_stages.json`] |
| bash + python3 + git | system | Harness and shim suite | [VERIFIED: script header and test pattern] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New Elixir realpath dependency | Private component-wise symlink resolver in the helper | D-06 forbids a new module/dependency; the resolver is about 15 lines |
| Real `plutil` on macOS only | PATH shim `plutil` | Shim runs on Linux CI too; D-14 requires it |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed or recommended by this phase. **Packages removed due to SLOP:** none. **Packages flagged SUS:** none. The legitimacy gate is not applicable.

## Architecture Patterns

### System Architecture Diagram

```
manifest (router, compiled) ──┐
                              ├─> Doctor.host_command_seam_findings
generated iOS fixture JSON ───┘      │
  Fixtures/crosswake_manifest.json   ├─ read error != enoent ─────────> host_commands_stale (reason unreadable)   :error
                                     ├─ enoent + router declares ─────> host_commands_stale_skipped               :advisory
                                     ├─ decode/shape bad ─────────────> host_commands_stale (reason malformed)    :error
                                     ├─ route has no host_commands key > host_commands_legacy_manifest            :error if router declares, else :warning
                                     ├─ declaring route absent ───────> host_commands_stale (reason route_missing):error
                                     └─ commands differ ──────────────> host_commands_stale (existing)            :error
shell package (pbxproj) ──> ShellPackage.resolve ──> satisfies? ──> host_command_shell_unsupported
                                         location ──> ShellPackage.display_location(location, cwd) ──> message + details

native boot: manifest + activation ──> grantHostCommands(route, request, entryRouteID, registered, seamDemand)
   hostCommands == nil (legacy) ─> (granted [:], denials {host.* in route.capabilities, + request host.* on entry route})
   ──> recordHostCommandDenials ──> hostCommandDiagnostics ; session.hostCommandDenials ──> BridgeChannel denial text

verify_loopback_origin_simulator.sh: tools/binding -> listener -> generate -> hash(before) -> swap probe -> hash(after build) -> install/launch -> hash(exit)
   EXIT trap cleanup_and_emit: uninstall/shutdown -> cleanup verdict -> evidence temp-write + mv -> emit JSON -> exit

PhysicalIphone.run_with ──> mode switch ──> PhysicalIphonePreflight.{readiness,check} ──> [add] origin-mode observation ──> PI-PREFLIGHT-CONFIG
```

### Recommended Project Structure (files by plan)

```
Plan 01  lib/crosswake/doctor/doctor.ex
         lib/crosswake/shell/shell_package.ex            (display_location/2)
         lib/crosswake/shell/ios_host_generation.ex      (shell_gate_message root)
         lib/mix/tasks/crosswake.gen.shell.ex            (render_opts :project_root)
         test/crosswake/doctor/doctor_host_commands_test.exs
         test/crosswake/shell/shell_package_test.exs, ios_host_generation_host_commands_test.exs
         test/mix/tasks/crosswake_gen_shell_host_commands_test.exs
         (new) test/crosswake/shell/path_redaction_test.exs  (sentinel suite)
Plan 02  packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
         packages/.../Tests/CrosswakeShellCoreTests/{HostCommandNavigationTests,HostCommandSeamTests,Phase180TwinFeasibilityTests}.swift
         guides/native_shell_upgrade.md, guides/compatibility.md, CHANGELOG.md
         test/crosswake/guides/host_command_seam_guide_test.exs
Plan 03  script/verify_loopback_origin_simulator.sh, guides/native_shell.md
         (new) test/crosswake/proof_lane/loopback_origin_harness_test.exs
         test/crosswake/guides/loopback_origin_guide_test.exs (needle)
Plan 04  test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs (red first)
         lib/crosswake/proof_lane/physical_iphone_preflight.ex  (only if red)
Plan 05  gates, mutation harness in RUNS, fix(186) commit
```

### Pattern 1: SEAM-07 Swift legacy branch

Current code. [VERIFIED: ActivationCoordinator.swift:272-282]
```swift
guard let declared = route.hostCommands else {
    // D-28 legacy path: absent field keeps today's behavior, entry route only.
    guard let entryRouteID, route.id == entryRouteID else { return ([:], [:]) }
    var granted: [String: String] = [:]
    for (key, version) in request.capabilities where key.hasPrefix("host.") && registered.contains(key) {
        granted[key] = version
    }
    return (granted, [:])
}
```
How reasons are decided today on the declared path: [VERIFIED: :287-299] seam check first (`denials[command] = "seam_unsupported"`), then `!registered.contains(command)` gives `"not_registered"`, then `!HostCommandSeam.supportsCommandVersion(version)` gives `"version_unsupported"`, else granted. `supportsCommandVersion` is strict MAJOR.MINOR.PATCH with major equal to `supportedCommandMajor` (= 1) [VERIFIED: :880-887, :856].

Recommended replacement (shape, planner to finalize):
```swift
guard let declared = route.hostCommands else {
    // Legacy (pre-1.2.0) manifest: the manifest registered nothing for this route. Grant nothing.
    var denials: [String: String] = [:]
    for name in route.capabilities where name.hasPrefix("host.") { denials[name] = "not_registered" }
    if let entryRouteID, route.id == entryRouteID {
        for (name, version) in request.capabilities where name.hasPrefix("host.") {
            denials[name] = HostCommandSeam.supportsCommandVersion(version) ? "not_registered" : "version_unsupported"
        }
    }
    return ([:], denials)
}
```
Why this works with the surrounding code:
- The caller strips `host.*` from the session capabilities and merges only `grant.granted`, then calls `recordHostCommandDenials(routeID:denials:)` [VERIFIED: :589-596 `var sessionCapabilities = request.capabilities.filter { !$0.key.hasPrefix("host.") }`, `sessionCapabilities.merge(grant.granted)`, `recordHostCommandDenials(routeID: route.id, denials: grant.denials)`]. Empty `granted` therefore yields no `host.*` in the session.
- `loadAndFilterRequest` removes unregistered `host.*` keys from the request before resolve [VERIFIED: :705 `for key in filteredCapabilities.keys where key.hasPrefix("host.") {`]. That is why the declared names must come from `route.capabilities`: they are the only record of an unregistered declared name, which is what makes the "silently dropped" case produce a diagnostic.
- `recordHostCommandDenials` appends `HostCommandDiagnostic(routeID:command:issue:)` sorted by command and dedupes [VERIFIED: :644-651].
- `hostCommandDeniedVersions` stays empty on legacy (`(route.hostCommands ?? [:]).filter …`, :610); the `version_unsupported` bridge text then falls back to "an unsupported version" [VERIFIED: BridgeChannel.swift:454 `session.hostCommandDeniedVersions[command] ?? "an unsupported version"`]. Deferred by CONTEXT; do not touch.
- Navigation: for a non-entry route the resolver already strips baseline `host.*` (`let inherited = routeID == baseline.routeID`, :634-636), so only `route.capabilities` contributes denials there.

Tests that pin the old grant and must flip red first:
- `HostCommandNavigationTests.test_legacy_entry_route_keeps_its_registered_command_and_other_routes_get_nothing` (:95-116) asserts `entry.capabilities[seamLessonCommand] == "1.0.0"` and `entry.hostCommandDenials == [:]`. Rewrite: capabilities has no `host.*`, `hostCommandDenials == [seamLessonCommand: "not_registered"]`, diagnostics contain the denial, push to review route denies `host.review.camera.scan`, `plain` route has none.
- `test_legacy_activation_lacking_the_command_grants_nothing` (:118-128) still passes on the capability assertion; extend it to assert the denial.
- Add: legacy request carrying `host.lesson.audio.play` at `"2.0.0"` gives `version_unsupported`; legacy with delegate registered `[]` still gives `not_registered`; the legacy `plain` route yields no diagnostics.
- `Phase180TwinFeasibilityTests.test_G3_control_exported_request_carrying_command_reaches_delegate` (skipped in CI; see Summary item 2).
- The fixture's `legacy_manifest` is the independent source of truth: routes `lesson` and `review` have `host.*` in `capabilities` and no `host_commands` key; `plain` has none [VERIFIED: ran a python read of `host_command_seam_fixture.json`: `legacy_manifest` routes: `lesson ABSENT ['host.lesson.audio.play']`, `plain ABSENT []`, `review ABSENT ['host.review.camera.scan']`]. Its `compatibility` still says `manifest_schema_version` `1.2.0`.
- Pinned texts that must stay: `test_denial_message_not_registered` asserts "Route \(seamLessonID) declared host command \(seamLessonCommand), but this app has not registered it." [VERIFIED: HostCommandSeamTests.swift:326-332].

How the plan verifies Swift without xcodebuild: run `swift test --scratch-path <RUNS>/_swiftbuild_186_NN` from `packages/crosswake-shell-core-ios` (SwiftPM, no Simulator, no xcodebuild). Package declares `.macOS(.v12)` so it builds on the host [VERIFIED: Package.swift]. Red first: write/flip the tests, run, record failing test names; fix; run green; expected final shape is 86+N tests, 2 skipped, exactly 1 failure (the pre-existing G4), so gate on `cmp` of the failing-test set against a recorded baseline, not on exit 0 (exit is 1 until the G4 test is fixed elsewhere). CI lane: `ios-package-unit` (`macos-latest`) running the same `swift test`. Also add Elixir-side source assertions only as a supplement (an Elixir test reading the Swift file already exists as precedent: `test/crosswake/shell/host_command_seam_swift_constant_test.exs` reads the same file to check the seam constant; do not move or rename `HostCommandSeam`).

### Pattern 2: Doctor findings, the structures to reuse

- Finding struct: `Crosswake.Doctor.Check` with `@type severity :: :error | :warning | :advisory` and fields `[:severity, :code, :message, :hint, :check, details: %{}]` [VERIFIED: lib/crosswake/doctor/check.ex:7-9].
- Constructor: `defp check(severity, code, check_name, message, hint, details \\ %{})` [VERIFIED: doctor.ex:2033].
- Status: `status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok)` [VERIFIED: doctor.ex:~211-213]. `:warning` and `:advisory` do not fail doctor. `host_command_findings` is concatenated into the report at :206.
- How doctor knows the router declares host commands on a route: the compiled manifest entry. `declaring = manifest.routes |> Enum.filter(fn {_id, entry} -> entry.host_commands != %{} end)` [VERIFIED: doctor.ex:2433-2437]. `entry.host_commands` is a map of command name to version, `%{}` when none (`Manifest.Types` defaults `host_commands: %{}`).
- Rendering always emits the key: `"host_commands" => host_commands_object(route.host_commands)` [VERIFIED: lib/crosswake/manifest/types.ex:1276]. Therefore a 1.2.0-generated fixture always has `host_commands` on every route, and a missing key identifies a pre-1.2.0 (legacy) fixture without ambiguity. Existing test confirms: `decoded["manifest"]["routes"]["plain"]["host_commands"] == %{}` [VERIFIED: host_command_seam_fixture_test.exs:82].
- Doctor's iOS root: `shell_root(:ios, cwd, opts)` = `Path.expand(opts[:ios_shell_root] || "native/ios/crosswake_shell", cwd)` [VERIFIED: doctor.ex:1805-1820, 67].

Current stale function, exact (the `else _ -> []` is the SEAM-08 defect). [VERIFIED: doctor.ex:2448-2482]
```elixir
defp stale_host_command_findings(manifest, root) do
  with {:ok, bytes} <- File.read(Path.join(root, "Fixtures/crosswake_manifest.json")),
       {:ok, %{"routes" => generated}} when is_map(generated) <- Jason.decode(bytes) do
    manifest.routes |> Enum.sort_by(&elem(&1, 0)) |> Enum.flat_map(fn {route_id, entry} ->
      generated_commands =
        case Map.get(generated, route_id) do
          %{"host_commands" => commands} when is_map(commands) -> commands
          _ -> %{}
        end
      if Map.has_key?(generated, route_id) and generated_commands != entry.host_commands do
        ... check(:error, "host_commands_stale", "host_commands",
             "Route #{route_id} host commands in the generated iOS manifest differ from the router declaration",
             "Run mix crosswake.gen.shell ios to regenerate the manifest; do not edit generated fixtures",
             %{route_id: route_id, commands: commands, platform: :ios})
      ...
  else
    _ -> []
  end
end
```
Note two silent paths besides the fall-through: a fixture route absent from `generated` is skipped by `Map.has_key?`, and a route without the key is silently treated as `%{}`.

Recommended restructure (one function, ordered, each case one finding):
1. `File.read` -> `{:error, :enoent}` -> if any `declaring` route: `[check(:advisory, "host_commands_stale_skipped", "host_commands", ..., hint, %{platform: :ios})]` else `[]`. Any other `{:error, posix}` -> `check(:error, "host_commands_stale", ..., %{reason: "unreadable", error: Atom.to_string(posix), platform: :ios})`. Do not put the path in message or details; name the file as `Fixtures/crosswake_manifest.json` (relative).
2. Decode + validate shape (pure function returning `{:ok, generated_routes}` or `:malformed`): decode ok, top-level map, `"routes"` is a map, every value is a map, if `"host_commands"` is present it is a map whose keys and values are all binaries. (CONTEXT note: Swift decodes `"host_commands": null` as `[:]`; D-04 says doctor treats non-map as malformed. Follow D-04; flag this in a comment.)
3. Per router route (sorted): fixture lacks the route -> if router entry declares -> `reason: "route_missing"` (`route_id`, `commands`); fixture route lacks the key -> collect into legacy groups (skip stale compare); else compare as today.
4. Legacy findings: group by severity. `:error` group = legacy fixture routes whose router entry declares; `:warning` group = the rest. One finding each, `details: %{route_ids: sorted, platform: :ios}`, hint "Run mix crosswake.gen.shell ios". (CONTEXT does not say whether one finding per route or per group; the `route_ids` plural list implies per group.)
5. Keep the genuine mismatch finding's details unchanged `%{route_id, commands, platform}` (the existing equality assertion at doctor_host_commands_test.exs:80-84 stays valid once its fixture is changed to a version mismatch); adding `reason: "mismatch"` is optional and would require editing that assertion.
Advisory placement: `host_command_seam_findings` already returns `[]` when the iOS root does not exist (`if File.dir?(root)`), which matches D-05 "fires only when the iOS root exists" [VERIFIED: doctor.ex:2441-2447].

Existing doctor tests to rewrite (footgun list from CONTEXT, confirmed):
- `"a stale generated route is one error finding naming route and commands"` (:66-86) deletes the key -> now legacy. Change `mutate` to set `"host_commands" => %{"host.lesson.audio.play" => "1.1.0"}` for the genuine mismatch, and add a new legacy test with the key deleted.
- `"finding details only carry the allowed keys"` (:126-146) deletes the key and expects `["host_command_shell_unsupported", "host_commands_stale"]`; switch to a version-mismatch mutation, and extend `@allowed_detail_keys` (:7-14) with `:route_ids`, `:reason`, `:error` as used.
- All other existing cases build fixtures through `managed_root/4` via `Manifest.render`, so they carry the key and remain green.

SEAM-08 fixture recipes (ExUnit, all use `managed_root(dir, DeclaringRouter, pbx, mutate)` then overwrite the fixture):
- unreadable (D-19): replace the file with a directory: `File.rm!(fixture); File.mkdir_p!(fixture)` so `File.read` returns `{:error, :eisdir}`. Platform independent and works as root. Do not use chmod; if a chmod variant is wanted, `@tag`-skip explicitly when `System.cmd("id", ["-u"])` is `"0"` and never let it pass vacuously.
- malformed: write each of `"{not json"`, `"[]"`, `~s({"routes": []})`, `~s({})`, `~s({"routes": {"lesson": "x"}})`, `~s({"routes": {"lesson": {"host_commands": []}}})`, `~s({"routes": {"lesson": {"host_commands": {"host.a.b": 1}}}})`. Assert one `host_commands_stale`, `details.reason == "malformed"` each (use a `for` over cases and assert the case list is non-empty).
- route_missing: `mutate` = `update_in(manifest, ["routes"], &Map.delete(&1, "lesson"))`. Router `DeclaringRouter` declares `host.lesson.audio.play` on `lesson` [VERIFIED: existing test details `route_id: "lesson", commands: ["host.lesson.audio.play"]`].
- absent: do not write the fixture (`File.rm!`) -> exactly `["host_commands_stale_skipped"]` with severity `:advisory`; and `report.status` is not made `:error` by it (check `Enum.any?(report.findings, &(&1.severity == :error and &1.check == "host_commands"))` is false). Non-declaring router + absent fixture -> no finding.

### Pattern 3: SEAM-09 redaction helper and sites

Output sites that print an absolute package location [VERIFIED]:
- Doctor `shell_unsupported_finding/5`: message `"... the crosswake-shell-core-ios at #{package.location} cannot honor it: #{found}"` and `details.package_location: package.location` (doctor.ex:2516-2535). `host_command_shell_findings/2` has no `cwd` parameter today; thread `cwd` from `host_command_seam_findings(manifest, cwd, opts)`.
- Gate: `shell_gate_message(route_id, command, location, found)` interpolates `at #{location}` (ios_host_generation.ex:95); called with `package.location` at :121 and with the literal `"the managed project"` at :126-130 (already safe). `render/2` reads `opts` (`Keyword.fetch(opts, :shell_package)`, :20); add `project_root` via `Keyword.get(opts, :project_root, File.cwd!())` so existing callers and tests that omit it are redacted by default.
- `gen.shell` builds `render_opts = [generated_at: ..., shell_package: shell_package_context(managed_root, local_ios_package())]` (:134-137); add `project_root: File.cwd!()`. Gate errors are raised by `{:error, reason} -> Mix.raise(reason)` (:141), so the raised text is fixed by fixing the message. `target = Path.expand(opts[:target] || File.cwd!())` (:88); D-07 says root = current working directory; keep `File.cwd!()`.
- `ShellPackage.resolve/1` returns raw locations (`location: dir`, `Path.expand(relative, managed_root)`), and `shell_package_test.exs` compares them; keep `resolve` unchanged and redact only at the print sites.
- No other site prints a package path: `local_package_assigns` writes relative paths into generated project files (not messages).

Helper contract (`@doc false`, in `shell_package.ex`):
```elixir
def display_location("remote " <> _ = location, _root), do: location
def display_location(location, root) when is_binary(location) and is_binary(root) do
  loc = canonical(location); root = canonical(root)
  cond do
    inside?(loc, root)  -> relative_inside(root, loc)           # "." or "a/b" (copy relative_path/2's common-prefix body)
    home_rel = home_relative(loc) -> "<home>/" <> home_rel
    true -> "<outside project>"
  end
end
```
- `Path.relative_to/2` returns an outside path unchanged, so never use it as the final answer (it would leak). Never fall back to the input.
- `inside?` must be component-wise (`Path.split` prefix), not `String.starts_with?`, or `/proj-evil` matches `/proj`.
- Home: `System.user_home!()`. Confirmed that `System.put_env("HOME", …)` does not change it: running `elixir -e 'System.put_env("HOME","/tmp/fakehome"); IO.inspect(System.user_home!())'` printed the real home. [VERIFIED: ran locally] So a test cannot fake the home with env; assert the pure function against `Path.join(System.user_home!(), "x/shell-pkg")` (no filesystem needed) and assert outputs never contain `System.user_home!()`.
- Canonicalization: no stdlib realpath. Write `canonical/1` that `Path.expand`s, then walks components resolving symlinks with `File.read_link/1` (bounded, e.g. 32 hops, nonexistent tail kept lexical). On macOS, the temp root `/var/folders/...` is a symlink to `/private/var/...` and `File.cwd!/0` returns the physical path, so lexical prefix matching fails and a real in-project path would print `<outside project>` (safe but wrong). Test portably by creating the symlink yourself: `File.ln_s!(real_dir, link)` and passing the project as the link and the location as the real path (and vice versa). Do not rely on `/var` existing.

Sentinel test recipe (D-08), new file `test/crosswake/shell/path_redaction_test.exs` (or add to `doctor_host_commands_test.exs`):
- `sentinel = "SENTINEL-186-#{System.unique_integer([:positive])}"`; project dir `Path.join(System.tmp_dir!(), sentinel)`; package dir `Path.join(project, "shell-pkg")` (inside) and a second package outside the project (`Path.join(System.tmp_dir!(), sentinel <> "-outside/pkg")`).
- Doctor: run as in `findings/3` with `cwd: project`; take findings whose `check == "host_commands"` (and `host_command_shell_unsupported` forced by seam version `0.9.0`); serialize `inspect(finding, limit: :infinity)` per finding (message, hint, details) and assert none contains `sentinel` or `System.user_home!()`; also assert the finding list is non-empty and that the redacted forms appear (`"shell-pkg"` for the inside case, `"<outside project>"` for the outside case) so the test cannot pass vacuously.
- Gate: `IOSHostGeneration.render(config, shell_package: {:local, pkg}, project_root: project)` -> `{:error, msg}` -> refute sentinel and home in `msg`, assert `msg =~ "cannot honor it"`.
- Raised text: run `Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", project])` inside `File.cd!(project)` as the existing test does (`crosswake_gen_shell_host_commands_test.exs:26-66`), rescue `Mix.Error`, scan `error.message`.
- Evidence files: define as (a) the harness evidence JSON written by the LOOP-06 shim suite and (b) any file the redaction tests write. No existing writer puts package paths into an evidence file, so (a) is scanned for the temp-repo sentinel and `System.user_home!()`; in addition the final plan greps the phase's own summary/verification artifacts for the home prefix. State this definition in the plan so "scanned: none found" is not read as "scanned everything".

M-01 guide wording. Current text, quoted: [VERIFIED: guides/compatibility.md:54-57] "A new iOS shell compares it with the seam version it was compiled with and refuses to activate a declaring route when the major versions differ. An older shell does not read the key and ignores it." Code truth: `let seamOK = seamDemand.map { SemVer.compatible(provides: HostCommandSeam.version, demands: $0) } ?? true` then `denials[command] = "seam_unsupported"` for every declared command [VERIFIED: ActivationCoordinator.swift:284-289], and `compatible` is `provides >= demands` [VERIFIED: SemVer.swift:14-15, 30]. Replacement meaning: the route still activates; if the shell's seam version is lower than the manifest's `host_command_seam_version`, each declared command on the route is denied with `seam_unsupported`; a shell at or above it is fine. Needle for `host_command_seam_guide_test.exs` (it flattens whitespace via `flat/1`): e.g. `"denied with `seam_unsupported`"` plus `refute text =~ "refuses to activate"`. Existing needles are on `native_shell_upgrade.md` and others, not on compatibility.md, so this is a new test.

Other guide/CHANGELOG sites:
- `guides/native_shell_upgrade.md:70` table row and :74-77 paragraph say the old manifest "keeps working for the entry route only" and pin needle `"keeps working for the entry route only"` at host_command_seam_guide_test.exs:75; both must change together. New row: old manifest = field absent, every `host.*` command on every route denied, doctor reports `host_commands_legacy_manifest`, repair `mix crosswake.gen.shell ios`. Update the doctor sentence at :62 to also name `host_commands_legacy_manifest`; the needle list already includes `host_commands_stale` and `host_command_shell_unsupported`.
- CHANGELOG: `## [Unreleased]` -> `### Unpublished support claims` bullets starting `* **...**` [VERIFIED: CHANGELOG.md:12-14]. Add a bullet that does NOT start with `**Host-command seam` because `host_command_seam_guide_test.exs:41` uses `Regex.run(~r/\* \*\*Host-command seam[^\n]*/, changelog)` and expects exactly the first-match entry text. Suggest `* **Legacy-manifest denial (iOS shell, not released).** ...`. After editing run the changelog-reading tests: `test/crosswake/guides/host_command_seam_guide_test.exs`, `release_boundaries_test.exs`, `hex_page_test.exs`, `doctor/formatter_test.exs`, `mix/tasks/crosswake_release_status_test.exs`, `planning/closeout_verifier_test.exs` (all reference CHANGELOG.md).

### Pattern 4: LOOP-06 harness, full walk of `script/verify_loopback_origin_simulator.sh`

Structure [VERIFIED: file read, 385 lines]:
- :11 `set -euo pipefail`. :13 `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"`; :14 `HELPERS="${ROOT_DIR}/script/loopback_origin_simulator"`; :15 `XCODEBUILD="${CROSSWAKE_IOS_XCODEBUILD_BIN:-xcodebuild}"`. Only option is `--evidence PATH` (:22-25); anything else exits 1.
- Verdict state: `OUTCOME`, `FINAL_RC=2`, `FAILED_RULES`, `CAUSE`, `ASSERTS`, `OBSERVATIONS`, `APP_UNINSTALLED="true"`, `DEVICE_LEFT_AS_FOUND="true"` (:33-55).
- `block RULE CAUSE` sets outcome `blocked`, rc 2, then `exit 2`; `unavailable` sets rc 3 then `exit 3` (:63-80). Both call `exit`, so they must NOT be called from inside the EXIT trap (an `exit` there skips the emit). In `cleanup_and_emit` set `OUTCOME`, `FINAL_RC`, `FAILED_RULES`, `CAUSE`, assertions directly.
- `emit_json` (:82-134) prints one JSON object via `python3 -I -`, schema `"crosswake.phase182.simulator/1"`; `cleanup` block carries `"device_left_as_found"` and `"app_uninstalled"`. No path appears in any field, so the evidence JSON cannot carry a home path.
- `cleanup_and_emit` (:136-176): `local rc=$?` (unused), `set +e`, default outcome `blocked`/`LOOP-IOS-UNEXPECTED` if unset; if `UDID`, `BUNDLE_ID`, `INSTALLED == 1`: terminate then `if xcrun simctl uninstall ... ; then APP_UNINSTALLED="true" else "false"` (:145-152); kill listener; if `WE_BOOTED == 1`: `xcrun simctl shutdown`, then `if xcrun simctl list devices 2>/dev/null | grep -F "$UDID" | grep -q "(Shutdown)"; then DEVICE_LEFT_AS_FOUND="true" else "false"` (:157-164); `rm -rf "$RUN"`; `json="$(emit_json)"`; `printf '%s\n' "$json"`; `if [[ -n "$EVIDENCE" ]]; then printf '%s\n' "$json" >"$EVIDENCE"; fi` (:169-171, unchecked: WR-04); `if [[ "$OUTCOME" == "passed" ]]; then exit 0; fi; exit "$FINAL_RC"` (:172-175). The two false flags never change the outcome: WR-05.
- IN-02 occurs twice: :159 (`pipefail` is not turned off by `set +e`, and `grep -F | grep -q` can SIGPIPE the first grep when `simctl list` output is large) and :354 `printf '%s\n' "${ASSERTS[@]}" | grep -qx "$a=passed"`. Replace with variable capture and bash tests: `list="$(xcrun simctl list devices 2>/dev/null)"; line="$(grep -F "$UDID" <<<"$list" || true)"; [[ "$line" == *"(Shutdown)"* ]]` and `[[ " ${ASSERTS[*]} " == *" $a=passed "* ]]`.
- Step 0 (:180-193): `cd "$ROOT_DIR"`, `git rev-parse HEAD`, `git status --porcelain` must be empty or `block "LOOP-IOS-CANDIDATE-DIRTY"`; tool loop `for tool in "$XCODEBUILD" xcrun python3 mix git plutil shasum` -> `unavailable "LOOP-IOS-TOOLCHAIN"`; `xcodebuild -version`; device pick via `xcrun simctl list devices available -j` + `python3 -I -c` (:198-217), `IFS='|' read -r UDID DEVICE_STATE DEVICE_NAME RUNTIME_NAME`; `RUN=$(mktemp -d "${TMPDIR:-/tmp}/crosswake-loopback-sim.XXXXXX")`.
- Step 1 listener (:226-237): real `python3 -I listener.py LOG` prints the port; refuses 4790.
- Step 2 generate (:242): `MIX_ENV=test mix run --no-start "$HELPERS/generate.exs" "$GEN" "$PORT"` (argv 3 and 4 are GEN and PORT for a shim); then requires `$PROJ/CrosswakeShell.xcodeproj` directory (:247-248) where `PROJ="$GEN/native/ios/crosswake_shell"`.
- Step 3 swap (:251-262): `owned_hashes()` = `(cd "$PROJ" && shasum -a 256 CrosswakeShell/Info.plist CrosswakeHostSettings.xcconfig CrosswakeShell.xcodeproj/project.pbxproj Fixtures/*.json)`; `cp "$HELPERS/ProbeApp.swift" "$PROJ/CrosswakeShell/CrosswakeShellApp.swift"`; the swapped file is not in the hash list (WR-03). `[[ "$HASH_BEFORE" == "$HASH_AFTER" && -n "$HASH_BEFORE" ]]`.
- Step 4 hermetic core (:265-278): `tar` copy of `$ROOT_DIR/packages/crosswake-shell-core-ios` (needs that directory to exist in the test repo), `git init/add/commit/tag` in `$RUN/core`.
- Step 5 build (:281-313): `$XCODEBUILD build -project "$PROJ/CrosswakeShell.xcodeproj" -scheme ... -derivedDataPath "$DD" ...`; `APP="$DD/Build/Products/Debug-iphonesimulator/${SCHEME}.app"` must be a dir; `plutil -extract NSAppTransportSecurity json -o - "$APP/Info.plist"` piped to python expecting `NSAllowsLocalNetworking True`; `plutil -extract CrosswakeOriginMode raw -o - ...` must be `local_loopback`; bundle id via `/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier'` (:312) -> change to `plutil -extract CFBundleIdentifier raw -o - "$APP/Info.plist"`.
- Step 6/7 (:316-374): boot (`simctl boot`, `bootstatus -b`), `uninstall ... || true` (:325, deferred per CONTEXT), `install`, `INSTALLED=1`, `launch`, `get_app_container ... data`, `poll_until` for `listener_has "/study-session"`, `"/__loaded"` and `result_is "didFinish"` against `$DATA_DIR/tmp/result.txt`; control relaunch with `SIMCTL_CHILD_PROBE_URL="http://example.com/"` expects result `didFailProvisional NSURLErrorDomain -1022` and no new listener lines.
- Step 8 (:377-385): HEAD unmoved, tree still clean, then `OUTCOME="passed"; FINAL_RC=0`.

Required script changes (D-10..D-13, one concern each):
1. Hash (D-11): replace `owned_hashes` with a full-tree list `(cd "$PROJ" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256)` captured at three points (before the swap, after the build, at exit in the trap before cleanup removes `$RUN`). Compare as maps: the only differing path allowed is `./CrosswakeShell/CrosswakeShellApp.swift`, whose new hash must equal `shasum -a 256 "$HELPERS/ProbeApp.swift"`; zero differing paths fails; any other difference, removal, or an unexpected addition fails with `LOOP-IOS-OWNED-HASH`. FOOTGUN [ASSUMED, cannot verify without running xcodebuild]: building `-project` can write `project.xcworkspace/xcshareddata/swiftpm/Package.resolved` and `xcuserdata/` inside the generated project, which a naive "no new files" rule would flag on every real run. Recommendation: after-build and at-exit comparisons check that every file present in the before-swap list is unchanged (except the swap target) and either allow-list additions under `CrosswakeShell.xcodeproj/project.xcworkspace/` and `xcuserdata/` or fail only on additions outside `.xcodeproj/`; record the choice. Phase 188's real run is where this is first exercised, so an unexpected-addition rule should name the paths in `CAUSE` to make a first real run diagnosable.
2. Evidence (D-12): before step 1 (before any long work) if `-n "$EVIDENCE"`: require `[[ ! -d "$EVIDENCE" ]]` and a writable existing parent directory (test with a probe: `: >"$EVIDENCE.probe.$$"` then `rm`), else `block "LOOP-IOS-EVIDENCE"`. Note the script `cd "$ROOT_DIR"` at :180 so a relative `--evidence` resolves against the clone; resolve it to an absolute path before the `cd`, or document. In the trap: write `"$EVIDENCE.tmp.$$"` then `mv`, each checked (`if ! printf ... >tmp || ! mv tmp "$EVIDENCE"`); on failure `OUTCOME="blocked"; FINAL_RC=2; FAILED_RULES+=("LOOP-IOS-EVIDENCE")`, recompute `json="$(emit_json)"` so stdout agrees with the exit code, remove the temp file. A bare `mv file existing_dir` succeeds by moving into the directory, hence the `-d` refusal. Decide for an already blocked/unavailable run whether to keep its exit code (recommended: keep 2 or 3, append the rule id, log to stderr) because the pass-to-blocked downgrade is the load-bearing case.
3. Cleanup (D-13): after the cleanup block, `if [[ "$OUTCOME" == "passed" && ( "$APP_UNINSTALLED" != "true" || "$DEVICE_LEFT_AS_FOUND" != "true" ) ]]` then set `blocked`, rc 2, rule `LOOP-IOS-CLEANUP`, cause "cleanup did not complete" (no paths). Must run before `emit_json` and before the evidence write.
4. IN-02 (:159 and :354) as above. Also drop the unused `local rc=$?`.
5. PlistBuddy -> `plutil` (:312).

PATH-shim pattern in `ios_verifier_test.exs` [VERIFIED: lines 1-34, 362-420]: `setup` creates `root = Path.join(System.tmp_dir!(), "ios-verifier-#{System.unique_integer([:positive])}")` with a `bin` dir and `on_exit(fn -> File.rm_rf!(root) end)`; a helper (`write_xcodebuild/1`) `File.write!`s a bash script into `bin` that `case "${CROSSWAKE_IOS_SHIM_MODE:-success}" in` selects behaviour and can trace argv to `CROSSWAKE_IOS_XCODEBUILD_TRACE`; the test runs `System.cmd("bash", [@script, ...], stderr_to_stdout: true, env: [{"PATH", bin <> ":" <> System.get_env("PATH")}, {"CROSSWAKE_IOS_SHIM_MODE", mode}, ...])`, asserts the exit status and `Jason.decode(String.trim(output))`. Note: with `stderr_to_stdout: true` the harness's stderr `log` lines mix into stdout, so the harness test must NOT use that flag when it needs to parse stdout JSON (D-12 requires "exactly one JSON object"); capture stdout and stderr separately (e.g. `System.cmd` without the flag, and `stderr` goes to the console, or redirect via `sh -c '... 2>file'`).

Shim set for an end-to-end ExUnit drive (no Simulator):
- Temp git repo ("clone") created per test: copy `script/verify_loopback_origin_simulator.sh` and `script/loopback_origin_simulator/{ProbeApp.swift,generate.exs,listener.py}` to the same relative paths, add a minimal `packages/crosswake-shell-core-ios/Package.swift` (any file; it is only `tar`red), then `git init -q`, `git add -A`, `git -c user.email=t@t -c user.name=t commit -q -m c` so `git status --porcelain` is empty. Shim state, evidence output and `TMPDIR` must live OUTSIDE the clone, or the dirty check at :183 and :380 trips. Use an absolute `--evidence` path outside the clone. Set `TMPDIR` to a per-test dir so `RUN` and the `crosswake-loopback-*.last.log` copies land there (and assert `RUN` was removed).
- `bin/mix`: `$1=run $2=--no-start $3=<generate.exs> $4=GEN $5=PORT`. Create `GEN/native/ios/crosswake_shell/{CrosswakeShell.xcodeproj/project.pbxproj,CrosswakeShell/Info.plist,CrosswakeShell/CrosswakeShellApp.swift,CrosswakeShell/CrosswakeCoordinator.swift,CrosswakeHostSettings.xcconfig,Fixtures/crosswake_manifest.json}` and write `$5` to `$STATE/port` (the launch shim needs the port; the script does not export it).
- `bin/xcodebuild`: `-version` prints `Xcode 16.0` and a build line; `build ...` parses `-derivedDataPath` and creates `$DD/Build/Products/Debug-iphonesimulator/CrosswakeShell.app/Info.plist`; parses `-project` to find the generated project dir for mutation modes. Respects `CROSSWAKE_IOS_XCODEBUILD_BIN` unset (default `xcodebuild` on PATH).
- `bin/plutil`: `-extract NSAppTransportSecurity json -o - FILE` prints `{"NSAllowsLocalNetworking":true}`; `-extract CrosswakeOriginMode raw -o - FILE` prints `local_loopback`; `-extract CFBundleIdentifier raw -o - FILE` prints `org.crosswake.loopbackprobe`. (A shim on macOS shadows the real one, which is intended.)
- `bin/xcrun` (`simctl` subcommands): `list devices available -j` -> `{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-18-0":[{"udid":"FAKE-UDID","state":"Shutdown","name":"iPhone 17","isAvailable":true}]}}`; plain `list devices` -> `    iPhone 17 (FAKE-UDID) (Shutdown)` (or `(Booted)` / a very large repeated block in the cleanup modes); `boot`, `bootstatus`, `install`, `terminate` exit 0; `uninstall` exits 0 except in the cleanup mode, where it must fail only AFTER a launch (state file) because :325 also calls `uninstall` and ignores the result; `get_app_container ... data` prints `$STATE/data` and `mkdir -p $STATE/data/tmp`; `launch`: first launch does `python3 -I -c 'import urllib.request,sys; [urllib.request.urlopen(sys.argv[1]+p).read() for p in ("/study-session","/__loaded")]' http://127.0.0.1:$(cat $STATE/port)` and writes `didFinish` to `$STATE/data/tmp/result.txt`; when `SIMCTL_CHILD_PROBE_URL` is set (control) it writes `didFailProvisional NSURLErrorDomain -1022` and does not touch the listener.
- `bin/shasum`: needed only if the host lacks it (see Environment Availability). When `System.find_executable("shasum")` is nil, write a shim that `exec sha256sum "${@:3}"` (the script always calls `shasum -a 256 ...`).
- `bin/mv` (evidence-write failure injection only): delegates to the real `mv` except fails when the destination equals the evidence path.
- Real tools used: `git`, `python3`, `tar`, `mktemp`, `sed`, `tr`, `head`, `wc`, `seq`, `grep`.

Cases (each changes exactly one thing from the passing baseline; expected exit and rule):
| Case | One change | Expect |
|------|-----------|--------|
| baseline | none | exit 0, `outcome: passed`, evidence file equals stdout JSON, `cleanup.app_uninstalled == true`, `device_left_as_found == true` |
| hash-other-file | build shim rewrites `CrosswakeShell/CrosswakeCoordinator.swift` | exit 2, `LOOP-IOS-OWNED-HASH` (old script passes: WR-03) |
| hash-swap-target | build shim rewrites `CrosswakeShellApp.swift` with other bytes | exit 2, same rule |
| hash-zero-change | generated `CrosswakeShellApp.swift` already equals `ProbeApp.swift` | exit 2, same rule |
| hash-at-exit | launch shim touches a generated file | exit 2, same rule |
| evidence-dir-missing | `--evidence` parent missing | exit 2, `LOOP-IOS-EVIDENCE`, xcodebuild trace shows no `build` call |
| evidence-target-is-dir | `--evidence` is a directory | exit 2, same rule |
| evidence-mv-fails | `mv` shim fails | exit 2, same rule, no partial `.tmp` left, stdout JSON says `blocked` |
| uninstall-fails | `uninstall` fails after launch | exit 2, `LOOP-IOS-CLEANUP` |
| shutdown-not-restored | `list devices` shows `(Booted)` after shutdown | exit 2, `LOOP-IOS-CLEANUP` |
| shutdown-huge-list | `list devices` prints 200000 lines containing the UDID, first `(Shutdown)` | exit 0 passes only with the IN-02 fix (mutation control: revert the capture) |
Always assert stdout parses as exactly one JSON object and that its `rule_ids` and exit status agree; assert no sentinel/home string in stdout or evidence. Tests for the pre-existing `unavailable` (3) path are optional.

Runtime cost: each case is one short script run (listener startup loop is ≤10 s but normally under 1 s; shims write results synchronously so `poll_until` returns immediately). Avoid cases that make `poll_until 90` wait.

CI placement: these are ordinary ExUnit tests; the `mix test` jobs run on `ubuntu-latest` (e.g. `crosswake-ci.yml` runs `mix test --exclude requires_example_host`) while `ios-package-unit` and the `phase18/79-ios-proof` jobs are on `macos`. [VERIFIED: grep of `runs-on` and `mix test` lines in `.github/workflows/crosswake-ci.yml`]. Therefore the shim suite must pass on Linux as well as macOS. No new lane (D-15 says harness stays manual). Document with a paragraph in `guides/native_shell.md` after the local-loopback paragraph (the `origin_mode: :local_loopback` paragraph ends before "For an existing generated iOS host", about :88-98); add a needle to `test/crosswake/guides/loopback_origin_guide_test.exs`.

### Pattern 5: LOOP-07 physical-iPhone preparation

Read-through result: `run_with/2` has three mutually exclusive modes via `invalid_mode?` (`Enum.count([:preflight_only, :readiness, :run], &(parsed[&1] == true)) != 1`) and requires `--json` [VERIFIED: physical_iphone.ex:139-160, 193-196]:
- `--readiness` -> `{:readiness, readiness_result(options)}` via `PhysicalIphonePreflight.readiness(options)`; the `PI-PREFLIGHT-CONFIG` entry is `readiness_entry(@config_rule, config_ready?(options))` where `config_ready?` is `match?({:ok, _}, config(options))` and `config/1` is only `Config.normalize(Keyword.get(options, :config))` [VERIFIED: preflight.ex:30-38, 106-107, 126-131].
- `--preflight-only` -> `PhysicalIphonePreflight.check(options)`; `{:ready, contract}` returns `{:ready, contract}`; `{:config_error, _}` maps to `{:blocked, "PI-PREFLIGHT-CONFIG"}` [VERIFIED: preflight.ex:56-65].
- `--run` -> same `check`, then `invoke_runner` calls `report_from(options, :device_report, contract)` [VERIFIED: physical_iphone.ex:226-247].
Nothing reads the origin mode: `git grep ios_host` over `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` and `lib/crosswake/proof_lane/` returned nothing. The refusal exists only at generation time (`Generator.normalize_host!/1` raising `@local_mode_refusal`, and `gen.proof_lane`'s `refuse_local_mode!`). [VERIFIED: generator.ex:677-694, gen.proof_lane.ex:158] So with a local declaration and all callbacks passing, `--readiness` would return outcome `"ready"`, `--preflight-only` `{:ready, _}` and `--run` `{:passed, _}` with `device_report` invoked: the D-16 tests will be RED by construction in all three modes for both cases. The red run still must be recorded.

Injection: `run_with(["--run", "--json"], ready_options() ++ [ios_host: [...]  , device_report: fn _ -> send(parent, :device_report_called); device_report() end, backend_report: ..., cleanup_run: ...])`. `ready_options/0` and `device_report/0`, `backend_report/0` already exist in `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` (:321-385 region; `ready_options` sets `config.ios_shell_root: "/tmp/crosswake/native/ios"`). Assert `{:blocked, %{outcome: "blocked", rule_id: "PI-PREFLIGHT-CONFIG"}}` for `--run`/`--preflight-only`, `{:readiness, %{outcome: "blocked"}}` with the `PI-PREFLIGHT-CONFIG` check `state == "blocked"` for `--readiness`, and `refute_received :device_report_called`. Add a control: same options with a production `:ios_host` (or none) still passes (`{:passed, _}` / `{:ready, _}`), so the test cannot be satisfied by blocking everything.
- Case (a): `ios_host:` a declaration that `IOSHostConfig.normalize` accepts as local, e.g. `[router: Crosswake.TestSupport.RouterFixtures.ManagedRouter, origin: "http://127.0.0.1:4790", origin_mode: :local_loopback, entry_route_id: "study-session", app_bundle_id: "org.crosswake.host", proof_app_bundle_id: "org.crosswake.host.proof", device_signing: [mode: :automatic, team_id: "ABCDE12345"]]` (shape taken from `generate.exs`, [VERIFIED: script/loopback_origin_simulator/generate.exs]). `observe_declaration` returns `{:local, canonical}`, a positive signal; result is `{:mismatch, origin}` or `{:local, origin}`, never `:none` [VERIFIED: ios_host_origin_mode.ex `observe/2` and `signal?/3`].
- Case (b): production declaration plus real local-mode output on disk. `ios_shell_root` must be absolute, end in `native/ios`, and equal its own `Path.expand` with no `..`; the managed shell root to observe is `Path.join(config.ios_shell_root, "crosswake_shell")` (proof lane files live at `native/ios/CrosswakeProofLane...`, gen.shell writes `native/ios/crosswake_shell`) [VERIFIED: config.ex:62-70,162-172; generator.ex:69; gen.shell.ex `managed_root = Path.join(target, "native/ios/crosswake_shell")`]. Build the fixture as `doctor_origin_mode_test.exs` does: golden production plist `test/fixtures/shell/ios/Info.plist.production.golden`, `elem(IOSHostOriginMode.desired(golden, :local_loopback), 1)` written to `CrosswakeShell/Info.plist`, and `Fixtures/route_activation.json` with `{"origin":"http://127.0.0.1:4790"}`. With a production declaration the result is `{:mismatch, origin}` (plist `:local_loopback` + activation `http` + declared `:production`). Alternatively, produce the files with the real `Mix.Tasks.Crosswake.Gen.Shell` under `MIX_ENV=test` (the case name says "real gen.shell output"); the hand-built pair above is the cheaper, deterministic equivalent and uses the same observer inputs.

Fix placement (D-17 says `run_with`): a check only in `run_with` before the mode branch would cover all three modes, but `readiness` reports per-check state, so the cleanest single place that also makes the `PI-PREFLIGHT-CONFIG` readiness entry honest is `PhysicalIphonePreflight.config/1` (both `readiness/1` and `check/1` call it). Implement a small helper there: `declaration = Keyword.get_lazy(options, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)`; derive `root` from the normalized config (`Path.join(config.ios_shell_root, "crosswake_shell")`); `IOSHostOriginMode.observe(root, declaration) == :none` else `{:config_error, :local_loopback}`. This reaches the same rule from `run_with` via `check`/`readiness`; call this out as the only departure from D-17's wording for the planner to confirm. Use the text `Generator.local_mode_refusal()` ("physical proof lane refuses origin_mode :local_loopback; loopback reaches the device itself, so use the HTTPS production origin" [VERIFIED: generator.ex:677]); the blocked result map only carries `outcome` and `rule_id` today, so attaching the text requires an added optional key (adding a key does not break existing partial-map assertions; no exact-map equality assertions exist in the physical-iphone test files per grep) or logging it; leave to discretion. Important: an `:ios_host` value is only reached when the host application config is loaded; the task `run/1` already calls `Mix.Task.run("app.config")` first, so `Application.get_env` works there.

Existing tests are unaffected when no `:ios_host` is set and `/tmp/crosswake/native/ios/crosswake_shell` does not exist: `observe` returns `:none` (plist `:unreadable`, activation `:none`, declaration `:undeclared`).

### Anti-Patterns to Avoid
- Calling `block`/`unavailable` inside `cleanup_and_emit` (they `exit`).
- Using `Path.relative_to/2` or returning the input as the redaction fallback.
- `set +e` assumed to relax pipefail inside the trap (it does not).
- A hash assertion that compares two captures with no input changed between them (the WR-03 defect itself); every hash case must be able to go red, which the table above forces.
- Treating a skipped Swift test as coverage.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fake Simulator for the harness | A mock xcodebuild that mimics Xcode | Minimal PATH shims keyed by `*_SHIM_MODE`, per `ios_verifier_test.exs` | Only the argv shapes the script uses matter |
| Origin-mode detection for LOOP-07 | New plist/URL parsing | `IOSHostOriginMode.observe/2` | Already classifies plist, activation and declaration |
| Refusal text | New string | `Generator.local_mode_refusal/0` | D-17 |
| Finding structs | New struct | `Crosswake.Doctor.Check` via `check/6` | Existing severity set |
| Denial reasons | New reason string | Existing `not_registered` / `version_unsupported` | D-03 |

## Runtime State Inventory

Not a rename/refactor/migration phase in the data sense, but D-01 changes behaviour for already-generated hosts:
| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None: no datastore holds these strings (verified by reading the touched modules) | none |
| Live service config | None | none |
| OS-registered state | None | none |
| Secrets/env vars | None | none |
| Build artifacts | Already-generated iOS hosts carry `Fixtures/crosswake_manifest.json` from older generators; after D-01 their routes with `host.*` capabilities are denied at runtime until `mix crosswake.gen.shell ios` is rerun | CHANGELOG line (D-01), doctor `host_commands_legacy_manifest`, guide row |

## Common Pitfalls

### Pitfall 1: `relative_path/2` is not a redactor
**What goes wrong:** copying it verbatim returns `../../..`-style strings for outside paths (structure leak) and nothing for `<home>/…`. [VERIFIED: gen.shell.ex:793-806]
**How to avoid:** copy only the common-prefix body for the inside branch; add the home and outside branches; canonicalize both sides first.
**Warning signs:** a unit test with a location under `System.user_home!()` that expects `<home>/…`; a symlinked project root; `/proj-evil` vs `/proj`.

### Pitfall 2: Existing tests pin old behaviour
Flip red first: HostCommandNavigationTests:95-116; `host_command_seam_guide_test.exs:75` needle; `native_shell_upgrade.md:70-77`; `doctor_host_commands_test.exs:66-86` and :126-146; the skipped Phase180 Swift control.

### Pitfall 3: Swift baseline is already red
`swift test` exits 1 before any change because of the Phase 180 G4 test. Gate on the exact failing set. [VERIFIED: ran]

### Pitfall 4: Trap re-entrancy and stdout/exit disagreement
After an evidence-write failure the stdout JSON must be re-emitted as `blocked`, or stdout says passed while exit is 2.

### Pitfall 5: Relative `--evidence`
The script `cd`s to `ROOT_DIR` at :180 before anything uses `$EVIDENCE`, so a relative path lands inside the clone and can dirty it at the final check. Resolve before the `cd` or require absolute.

### Pitfall 6: `stderr_to_stdout: true` in the harness test
The harness logs to stderr; merging it breaks the single-JSON-object assertion.

### Pitfall 7: Doctor `cwd` default
`host_command_shell_findings` has no `cwd`; omitting it from the helper call would redact against the wrong root and every in-project package would print `<outside project>`.

### Pitfall 8: pbxproj vs build writes (see Pattern 4 item 1) [ASSUMED]

## Code Examples

Mutation-control shape to copy from RUNS (Phase 185): `mutate-185.sh` (helpers `apply`, `restore_all`, `totals`, sha256 before != after) [VERIFIED: referenced in 185-05-PLAN.md; `/private/tmp/crosswake-phase180-run/mutate-185.sh` exists].

Verify command style (copy from 185):
```bash
C=/private/tmp/crosswake-phase180-impl; RUNS=/private/tmp/crosswake-phase180-run
cd $C && MIX_BUILD_PATH=$RUNS/_build_186_01_test mix test test/crosswake/doctor/doctor_host_commands_test.exs > $RUNS/doctor-186-01.out 2>&1; echo $? > $RUNS/doctor-186-01.exit
test "$(cat $RUNS/doctor-186-01.exit)" = 0 && grep -Eq '^[1-9][0-9]* tests, 0 failures' $RUNS/doctor-186-01.out
```
(never pipe a gating command into tail/head; no two mix runs share a MIX_BUILD_PATH; the full suite runs with `MIX_BUILD_PATH` unset.)

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Legacy route: entry route keeps a registered `host.*` grant | Legacy route grants nothing (D-01) | Behaviour change for old hosts; regenerate |
| `host_commands_stale` silent on any read/decode failure | Explicit reasons | Unreadable/malformed score as errors |
| Harness verdict independent of cleanup/evidence | Cleanup and evidence failures downgrade to `blocked` | No pass after own failure |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `shasum` exists on GitHub `ubuntu-latest` (perl `shasum`) | Environment Availability | The harness shim suite fails on Linux CI; mitigated by writing a `bin/shasum` shim (via `sha256sum`) when `System.find_executable("shasum")` is nil |
| A2 | `xcodebuild build -project` may write `Package.resolved`/`xcuserdata` into the generated `.xcodeproj` | Pattern 4 item 1 | A strict "no additions" full-tree rule would fail a real run in Phase 188; verified only when the twin/harness is run |
| A3 | Proof-lane managed shell root is `Path.join(ios_shell_root, "crosswake_shell")` | Pattern 5 | Wrong root would make `observe` see `:unreadable` and miss case (b); confirm with one grep when implementing |
| A4 | Doctor legacy findings group per severity (one finding per group), not per route | Pattern 2 | Test shape differs; CONTEXT's `route_ids` list supports grouping |
| A5 | Preflight `config/1` is an acceptable home for the LOOP-07 check (vs literally in `run_with`) | Pattern 5 | Planner may prefer D-17's literal placement; either reaches `PI-PREFLIGHT-CONFIG` |

## Open Questions

1. **Placement of the LOOP-07 check (A5).** Recommendation: in `PhysicalIphonePreflight.config/1` so readiness is honest; confirm with the user only if the literal D-17 wording is required.
2. **Evidence-write failure on an already failed run.** Recommendation: keep the existing non-zero exit code and append `LOOP-IOS-EVIDENCE`; only the passed-to-blocked downgrade is mandatory.
3. **Pre-existing Swift G4 failure.** Out of scope here; record it in the baseline so the 186 gate compares failing sets. Decide separately whether it is fixed before CI (it would fail `ios-package-unit` as is).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| swift / SwiftPM | SEAM-07 verification | yes | Swift 6.3.3, macOS 26 | none needed |
| xcodebuild | (must not be run) | present | n/a | n/a; shimmed in tests |
| shasum | harness hash lists, shim suite | yes locally (`/usr/bin/shasum`) | n/a | Linux: [ASSUMED] present; else `bin/shasum` shim over `sha256sum` |
| plutil | harness | yes locally (`/usr/bin/plutil`), absent on Linux | n/a | PATH shim (always installed by the test) |
| python3 | harness and listener | yes (Homebrew locally; ubuntu runner has python3) | n/a | none |
| git | harness clone + temp repo | yes | n/a | none |
| Elixir/OTP | all ExUnit | yes | 1.19.5 / 27.3 | none |

**Missing dependencies with no fallback:** none. **With fallback:** `shasum` and `plutil` on Linux via shims, so the shim tests are not macOS-only.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) and XCTest via `swift test` |
| Config file | `test/test_helper.exs`; `packages/crosswake-shell-core-ios/Package.swift` |
| Quick run command | `cd /private/tmp/crosswake-phase180-impl && MIX_BUILD_PATH=/private/tmp/crosswake-phase180-run/_build_186_NN_test mix test <file> > $RUNS/<name>-186-NN.out 2>&1; echo $? > $RUNS/<name>-186-NN.exit` |
| Full suite command | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > $RUNS/fix-186.full.out 2>&1`, failure set `cmp` against `$RUNS/fix-185.failures` (single line `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`; extractor `$RUNS/extract-184-07.sh`) |
| Swift run command | `cd packages/crosswake-shell-core-ios && swift test --scratch-path $RUNS/_swiftbuild_186_NN > $RUNS/swift-186-NN.out 2>&1` (exit 1 expected until the G4 test is repaired elsewhere; gate on the failing-test set) |

### Phase Requirements -> Test Map
| Req / Criterion | Behavior | Test Type | Automated Command (MIX_BUILD_PATH under `$RUNS`) | File | Failure looks like |
|-----------------|----------|-----------|----------------------------------------|------|-------------|
| SEAM-07 / SC1 | Legacy route denies each registered `host.*` with `not_registered` / `version_unsupported`; no grant; diagnostics recorded | XCTest | `swift test --scratch-path $RUNS/_swiftbuild_186_02 --filter HostCommand` | `HostCommandNavigationTests.swift`, `HostCommandSeamTests.swift` (existing, flipped) | old code: `capabilities[host.lesson.audio.play] == "1.0.0"` instead of `[:]` |
| SEAM-07 / SC1 | Doctor `host_commands_legacy_manifest` (`:error` vs `:warning`), stale skips legacy routes | ExUnit | `mix test test/crosswake/doctor/doctor_host_commands_test.exs` (`_build_186_01_test`) | existing, rewritten | legacy fixture yields `host_commands_stale`, or no finding |
| SEAM-07 / SC1 | Guide row, upgrade paragraph, CHANGELOG line; manifest 1.2.0 and public API unchanged | ExUnit | `mix test test/crosswake/guides test/crosswake/manifest/host_command_seam_fixture_test.exs` (`_build_186_02_test`) | `host_command_seam_guide_test.exs` | missing needle |
| SEAM-08 / SC2 | unreadable (eisdir), malformed (7 shapes), route_missing each one `:error` `host_commands_stale` with `details.reason`; absent -> `host_commands_stale_skipped` `:advisory` | ExUnit | same doctor file | existing, new tests | `[]` returned (old fall-through) |
| SEAM-09 / SC3 | Sentinel and `System.user_home!()` absent from doctor findings, gate `{:error, msg}`, rescued `Mix.Error`, evidence JSON; `display_location` rules incl. symlink and prefix-collision | ExUnit | `mix test test/crosswake/shell/path_redaction_test.exs test/crosswake/shell/shell_package_test.exs test/crosswake/shell/ios_host_generation_host_commands_test.exs test/mix/tasks/crosswake_gen_shell_host_commands_test.exs` | new + existing | message contains the sentinel or home |
| SEAM-09 / SC3 | Compatibility guide floor wording | ExUnit | `mix test test/crosswake/guides/host_command_seam_guide_test.exs` | existing, new test | text still has "refuses to activate" |
| LOOP-06 / SC4 | Each broken-state shim exits non-zero with the named rule; baseline exits 0 | ExUnit (bash via PATH shims) | `mix test test/crosswake/proof_lane/loopback_origin_harness_test.exs` (`_build_186_03_test`) | new | exit 0 on a broken state, or wrong rule id |
| LOOP-06 / SC4 | Harness documented as manual evidence, exit codes 0/2/3 | ExUnit | `mix test test/crosswake/guides/loopback_origin_guide_test.exs` | existing + needle | missing paragraph |
| LOOP-07 / SC5 | `--preflight-only`, `--readiness`, `--run` blocked with `PI-PREFLIGHT-CONFIG` for (a) local declaration and (b) real local-mode output; `device_report` never called; production control passes | ExUnit | `mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/physical_iphone_preflight_test.exs` (`_build_186_04_test`) | existing, new tests | `{:passed, _}` / `{:ready, _}` returned, or `:device_report_called` received |

Gate regex per file: `grep -Eq '^[1-9][0-9]* tests, 0 failures' $RUNS/<out>`; never accept 0 tests.

### Sampling Rate
- Per task: the focused file for that task (red run recorded before the fix, kept in `$RUNS` as `*-186-NN.red.out`).
- Per plan: all files owned by the plan plus `mix format --check-formatted` for changed files and `mix compile --warnings-as-errors` (dev build path).
- Phase gate (plan 05): full suite failure set equals `fix-185.failures`; Swift failing set equals the recorded baseline plus nothing; guides tests, `mix crosswake.docs.sync --check`, adoption scan routing findings `cmp` against the 185 record, `git diff` shows nothing under `.github/`, no Android path, no new `script/` file, and no generated guide changed.

### Wave 0 Gaps
- [ ] Record Swift baseline now: `swift-186-research-full.out` shows 86 tests, 2 skipped, 1 failure (G4) - copy the failing-test list into `$RUNS/swift-baseline-186.failures`.
- [ ] New test files: `test/crosswake/shell/path_redaction_test.exs`, `test/crosswake/proof_lane/loopback_origin_harness_test.exs`.
- [ ] Harness test helpers: clone builder, shim writers, state dir outside the clone.
- [ ] `mutate-186.sh` derived from `mutate-185.sh` (throwaway copy `/private/tmp/crosswake-186-mutation`, own `MIX_BUILD_PATH`, sha256 before/after must differ, no zero-test runs).

### Mutation controls (red-first and revert evidence)
Each runs only its target file in the throwaway copy and must show a named failing test; add a paired negative where a floor/guard could be removed together with the mutation.
1. Swift: restore the old legacy grant -> named legacy tests fail (`swift test --filter`).
2. doctor: restore `else _ -> []` -> unreadable and malformed tests fail.
3. doctor: drop the `host_commands_stale_skipped` emission -> absent test fails.
4. doctor: remove legacy skip in stale comparison -> exactly-one-code assertion fails.
5. doctor: remove the route_missing branch -> route_missing test fails.
6. `display_location`: return input unchanged -> sentinel tests fail.
7. `display_location`: remove canonicalization -> symlink test fails.
8. `display_location`: use `String.starts_with?` -> prefix-collision test fails.
9. compatibility.md: restore "refuses to activate" -> guide test fails.
10. harness: restore the 4-file hash list -> hash cases fail.
11. harness: remove the evidence precheck / the `mv` check / the cleanup downgrade (three controls) -> matching cases fail.
12. harness: revert the IN-02 capture -> `shutdown-huge-list` fails.
13. preflight: remove the origin-mode check (if added) -> all three LOOP-07 modes fail.
Also record that the unmutated candidate files are byte-identical before and after (sha256 manifest), and that nothing was mutated inside the real candidate.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Strict shape validation of the generated fixture JSON (SEAM-08); `supportsCommandVersion` grammar on versions |
| V7 Error Handling and Logging | yes | No absolute paths or usernames in findings, gate text, raised text or evidence (SEAM-09) |
| V12 Files and Resources | yes | Evidence written via temp + `mv` after a writable-dir check; refuse a directory target |
| V2/V3/V4 | no | No authentication or session surface changes |
| V6 Cryptography | no | `shasum -a 256` is integrity comparison only |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Home path / username disclosure in diagnostics | Information disclosure | `display_location/2` with canonicalization; sentinel test |
| Silent grant on a legacy route | Elevation of privilege | Deny by default; doctor error |
| Unreadable input scored as pass | Repudiation / tampering | Explicit `unreadable` / `malformed` errors |
| Symlink-based prefix confusion | Information disclosure | Component-wise canonical comparison, bounded hops |
| Harness reports pass after cleanup/evidence failure | Repudiation | Downgrade to `blocked`, exit 2 |

## Sources

### Primary (HIGH confidence, read this session in `/private/tmp/crosswake-phase180-impl`)
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` (grant function, `resolve`, `recordHostCommandDenials`, `loadAndFilterRequest`, `HostCommandSeam`), `BridgeChannel.swift`, `SemVer.swift`, `Package.swift`
- Swift tests: `HostCommandNavigationTests`, `HostCommandSeamTests`, `HostCommandWireTests`, `Phase180TwinFeasibilityTests`, `Resources/host_command_seam_fixture.json`
- `lib/crosswake/doctor/doctor.ex`, `check.ex`; `lib/crosswake/shell/shell_package.ex`, `ios_host_generation.ex`, `ios_host_origin_mode.ex`; `lib/mix/tasks/crosswake.gen.shell.ex`, `crosswake.proof_lane.physical_iphone.ex`; `lib/crosswake/proof_lane/{physical_iphone_preflight,physical_iphone_host,config,generator}.ex`
- `script/verify_loopback_origin_simulator.sh` and `script/loopback_origin_simulator/*`
- `test/crosswake/proof_lane/ios_verifier_test.exs`, `test/crosswake/doctor/doctor_host_commands_test.exs`, `doctor_origin_mode_test.exs`, `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs`, `crosswake_gen_shell_host_commands_test.exs`, `test/crosswake/guides/host_command_seam_guide_test.exs`
- `guides/compatibility.md`, `native_shell_upgrade.md`, `native_shell.md`, `CHANGELOG.md`; `.github/workflows/crosswake-ci.yml`; `script/repository_verification_stages.json`
- Local runs: `swift test --scratch-path` (baseline), `elixir -e` for `System.user_home!`

### Secondary / planning
- `186-CONTEXT.md`, 182 REVIEW (WR-03, WR-04, WR-05, IN-02), 185 VALIDATION/05-PLAN (verify-command and mutation-harness style), `$RUNS/fix-185.failures`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new
- Architecture / code locations: HIGH, read and quoted
- Pitfalls: HIGH for items verified here; A1-A3 are MEDIUM
- Harness Linux behaviour: MEDIUM (not executed here by rule)

**Research date:** 2026-10-16
**Valid until:** the candidate head changes (re-check line numbers if `25614cf6` moves)

## Project Constraints (from AGENTS.md)
- Zero-human verification: every claim above is checked by an automated command; no `checkpoint:human-verify`.
- Do not stage, commit, branch, stash or create worktrees in this checkout; the single `fix(186)` commit is made in the candidate by plan 05 only.
- No Android work, no new CI lane, no generated-guide edits, no twin/Simulator/xcodebuild runs; Phase 188 reruns the twin.
- Sensitive data: no adopter identity; no home path or username in any artifact (the final plan greps phase artifacts for the home prefix); redacted forms use `<home>` and `<outside project>`.
- Write user-facing summaries in plain language, outcome first.

## Suggested Plan Split (D-18)

| Plan | Scope | Files owned | Depends on |
|------|-------|-------------|-----------|
| 186-01 | SEAM-07 doctor half, SEAM-08, SEAM-09 code: all `doctor.ex` edits, `display_location/2`, gate root plumbing, sentinel suite | doctor.ex, shell_package.ex, ios_host_generation.ex, gen.shell.ex, the listed doctor/shell/gen tests | none (must finish before Phase 187; no other plan touches doctor.ex) |
| 186-02 | SEAM-07 Swift + guides + CHANGELOG + M-01 | ActivationCoordinator.swift, Swift tests, three guides, CHANGELOG, guide test | 01 (guide cites the doctor code) |
| 186-03 | LOOP-06 harness + shim suite + native_shell.md paragraph | harness script, new test, native_shell.md, loopback guide test | 02 |
| 186-04 | LOOP-07 red test, then fix if red | physical_iphone_test.exs, preflight.ex | 03 |
| 186-05 | Final gates vs Phase 185 baseline, mutation controls, one `fix(186)` commit, source probe + read-only preflight on the committed candidate | RUNS files only, then the commit | 01-04 |

Each plan: red tests written and run RED first (output kept), fix, green focused run, format, no commit until plan 05.
