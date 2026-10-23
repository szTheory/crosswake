---
phase: 182-loopback-origin-for-local-ios-host
reviewed: 2026-10-14T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/crosswake/shell/ios_host_config.ex
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/crosswake/shell/ios_host_origin_mode.ex
  - lib/crosswake/shell/managed_outputs.ex
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/doctor/formatter.ex
  - lib/crosswake/doctor/publish_readiness.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - lib/mix/tasks/crosswake.inspect.ex
  - priv/templates/crosswake/shell/ios/Info.plist.eex
  - script/verify_loopback_origin_simulator.sh
  - script/loopback_origin_simulator/ProbeApp.swift
  - script/loopback_origin_simulator/generate.exs
  - script/loopback_origin_simulator/listener.py
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/support_matrix/renderer.ex
  - guides/native_shell.md
  - guides/native_shell_upgrade.md
  - guides/capability_map.md
  - guides/support_matrix.md
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 182: Code Review Report

**Reviewed:** 2026-10-14
**Depth:** standard
**Files Reviewed:** 22 (source files in the candidate diff; test files used only as evidence)
**Status:** issues_found

## Summary

The core safety design holds up. I fed 19 hostile origin strings through `IOSHostConfig.normalize/2` in `origin_mode: :local_loopback`, and every one was rejected or canonicalised correctly. They included userinfo, a trailing slash or query or fragment, IPv6, `127.1`, `localhost.`, a port of 0 or 65536 or `+80`, Unicode digits, percent-encoding, a trailing newline and a trailing space. Plain `http` without the mode is refused. The `:prod` refusal works. No error message echoes the supplied origin. The plist reconcile refuses ambiguous shapes. The proof lane, including the `--config` path, refuses a local declaration. The doctor and `--check-publish` paths flag local and mismatch states. The 196 targeted tests pass.

No blockers. The warnings are:
- A half-applied generation state.
- A defense-in-depth hole.
- A vacuous harness assertion.
- Two ways the harness can score a run as passed when its evidence or cleanup failed.
- An unrelated privacy-surface expansion in `mix crosswake.inspect`.

## Warnings

### WR-01: Info.plist reconcile can leave a half-applied generation

**File:** `lib/mix/tasks/crosswake.gen.shell.ex:631-641` (reconcile at 633, managed publish at 643-653)
**Issue:** `generate_ios_shell` writes the README, then runs `reconcile_origin_plist`, then writes fixtures, the manifest and the managed outputs. Two partial-failure cases follow.
- If the reconcile raises on a host-edited plist (the intended refusal), the README has already been created and nothing else has run. The earlier lines of this function are not transactional.
- If the reconcile succeeds and a later `ManagedOutputs.publish` fails, the plist already carries (or has lost) the loopback block while `route_activation.json` and the pbxproj still describe the old origin. Doctor flags this as a mismatch, but the generator itself leaves the state inconsistent.

**Fix:** Validate first with `IOSHostOriginMode.desired/2` before any write, so refusal happens with zero side effects. Apply the plist write immediately before `publish` and run it last. For example:
```elixir
plan = plan_origin_plist(root, origin_mode)   # read + desired, raises on conflict, no write
... existing writes ...
apply_origin_plist(plan)                      # write_origin_plist just before/after publish
```

### WR-02: `IOSHostGeneration.origin_transport/1` guard is weaker than its comment claims

**File:** `lib/crosswake/shell/ios_host_generation.ex:62-71`
**Issue:** The "defense in depth for hand-built structs" check only rejects `http://` when `origin_mode != :local_loopback`. A hand-built `%IOSHostConfig{origin_mode: :local_loopback, origin: "http://evil.example.com"}` (or any other origin) passes it. The prod refusal and the loopback-host allowlist live only in `normalize/2`. `render/2` would then emit the ATS exception, the marker and the arbitrary `http` origin. The Info.plist template renders the block for any struct with `origin_mode == :local_loopback`, without re-checking.
**Fix:** In `origin_transport`, when `mode == :local_loopback`, require the origin to match `~r{\Ahttp://(127\.0\.0\.1|localhost)(:[0-9]{1,5})?\z}`. Alternatively, make `render/2` call the same validation `normalize/2` uses. Optionally re-run the prod-env refusal there.

### WR-03: Harness "owned hashes unchanged" assertion is vacuous

**File:** `script/verify_loopback_origin_simulator.sh:251-262`
**Issue:** `owned_hashes` hashes `Info.plist`, `CrosswakeHostSettings.xcconfig`, `project.pbxproj` and `Fixtures/*.json`. The only operation between the two hash captures is `cp ProbeApp.swift CrosswakeShell/CrosswakeShellApp.swift`, which touches a file that is not hashed. The assertion `crosswake_owned_hashes_unchanged=passed` can therefore never fail. This is the repo's recurring "check green while asserting nothing" defect, and the result is written into the evidence JSON.
**Fix:** Either drop the assertion, or make it meaningful. Hash before the swap, and re-hash after the build (the xcodebuild step, which could rewrite project files) and again at exit. Alternatively, assert that the generated `CrosswakeShellApp.swift` was the only changed path using `git diff --no-index` or a full-tree manifest.

### WR-04: A failed evidence write is silent, so the run can pass with no evidence

**File:** `script/verify_loopback_origin_simulator.sh:169-175`
**Issue:** `cleanup_and_emit` runs under `set +e`, and `printf '%s\n' "$json" >"$EVIDENCE"` is not checked. If the path is unwritable or its directory is missing, the script still exits 0 for `passed`. The caller that asked for `--evidence` receives success with no artifact, which is absence scored as success.
**Fix:** Capture the write status, and on failure log it and override the exit code, for example `exit 4` with the outcome reported as blocked in the stdout JSON. Validate the directory before the long build, not at the end.

### WR-05: Cleanup failure does not affect the outcome

**File:** `script/verify_loopback_origin_simulator.sh:145-175`
**Issue:** If `simctl uninstall` fails, or the Simulator the harness booted is not back to `(Shutdown)`, the script records `app_uninstalled: false` and `device_left_as_found: false` in the JSON but still exits 0 with `outcome: passed`. The header promises cleanup. Also, `WE_BOOTED` only covers booting; line 325 uninstalls any pre-existing app with the probe bundle id on a device the user may already be using.
**Fix:** After cleanup, if `APP_UNINSTALLED != true` or `DEVICE_LEFT_AS_FOUND != true` and the outcome was `passed`, downgrade to `blocked` with rule `LOOP-IOS-CLEANUP` and a non-zero exit. Alternatively, document that cleanup is advisory.

### WR-06: `mix crosswake.inspect` now prints the production host origin

**File:** `lib/mix/tasks/crosswake.inspect.ex:46-65` (line 60 for the non-local case)
**Issue:** The new `with_host_origin/1` appends `host origin: <origin>` for every declared `:ios_host`, including the real HTTPS production origin of the first adopter. Only the local-mode line was in scope. The project rules treat inspection and proof output as sensitive surfaces and say "never record or infer ... revealing links". Printing the production origin in inspection output, which is often pasted into issues and CI logs, is an unrelated privacy-surface widening. Separately, in a `:prod` env a local declaration normalises to an error and is silently omitted, so the "local mode" line vanishes exactly when it matters.
**Fix:** Print a line only for `origin_mode: :local_loopback` (the loopback origin is non-sensitive). Emit nothing for production origins. For a rejected declaration, print a fixed "host origin: declaration invalid" line without any value.

## Info

### IN-01: Ungrammatical, duplicated drift message

**File:** `lib/mix/tasks/crosswake.gen.shell.ex:230-236`
**Issue:** The raise message reads "managed iOS outputs are origin mode changed; ..." because it reuses a template meant for a noun cause. The repair text is also duplicated as a literal on lines 230 and 233.
**Fix:** Use "managed iOS outputs have a changed origin mode; #{repair}" and interpolate `repair` in the info line.

### IN-02: Pipe under `pipefail` can falsely fail the loopback-load check

**File:** `script/verify_loopback_origin_simulator.sh:353-355`
**Issue:** `printf ... | grep -qx` with `pipefail`: `grep -q` can exit early and `printf` can then die with SIGPIPE, giving a non-zero pipeline status. The direction is fail-closed (a pass is reported as a block), but it makes the harness flaky.
**Fix:** Use `grep -qx -- "$a=passed" <<<"$(printf '%s\n' "${ASSERTS[@]}")"` or a bash loop over the array.

### IN-03: No timeouts on the long external steps

**File:** `script/verify_loopback_origin_simulator.sh:242, 287, 322`
**Issue:** `mix run`, `xcodebuild build` and `simctl bootstatus -b` have no timeout. A hung Simulator leaves the script waiting forever. It cannot score a false pass, but it defeats the unattended-evidence goal.
**Fix:** Wrap them with a `timeout` helper (macOS lacks `timeout`, so use a `perl -e alarm` wrapper or a background watchdog). Map expiry to `unavailable`.

### IN-04: Small dead and racy items in the harness

**File:** `script/verify_loopback_origin_simulator.sh:137, 358-374`
**Issue:**
- `local rc=$?` (line 137) is unused.
- The narrowness check compares listener log line counts before and after the control launch. A late `/__loaded` ping from the terminated first launch could land in between and cause a spurious block (fail-closed, but flaky).

**Fix:** Drop `rc`. Snapshot the line count after confirming the first app is terminated, and compare for `GET` lines that are new after the control launch.

---

_Reviewed: 2026-10-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
