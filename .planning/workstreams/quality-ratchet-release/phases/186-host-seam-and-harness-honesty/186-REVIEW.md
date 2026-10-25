---
phase: 186-host-seam-and-harness-honesty
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - CHANGELOG.md
  - guides/compatibility.md
  - guides/native_shell.md
  - guides/native_shell_upgrade.md
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/crosswake/shell/shell_package.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandNavigationTests.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift
  - script/verify_loopback_origin_simulator.sh
  - test/crosswake/doctor/doctor_host_commands_test.exs
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/guides/host_command_seam_guide_test.exs
  - test/crosswake/guides/loopback_origin_guide_test.exs
  - test/crosswake/proof_lane/loopback_origin_harness_test.exs
  - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
  - test/crosswake/shell/path_redaction_test.exs
  - test/crosswake/shell/shell_package_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
  - test/mix/tasks/crosswake_doctor_test.exs
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 186: Code Review (bd294007 over 25614cf6)

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed the Phase 186 candidate commit against its base. No structural (fallow) findings were supplied. The core of the work holds up under adversarial reading:

- The legacy-route denial in `grantHostCommands` grants nothing and routes through `recordHostCommandDenials`.
- Doctor's stale check no longer falls through on unreadable or malformed input. Each case has its own reason, and the "unreadable" test uses an `eisdir` fixture rather than chmod.
- `display_location/2` canonicalizes both sides, compares by path component (so a sibling with a shared name prefix is not "inside"), and has no clause that returns a raw absolute path.
- The harness exit trap checks each cleanup status explicitly. The IN-02 `grep -q` under pipefail is gone, and the "huge list" test exercises it.
- The physical-iPhone origin refusal covers all three modes, and the tests assert `device_report` is never called. The positive control proves the refusal is not unconditional.

No blocker was found. The remaining weaknesses are an overclaimed fail-closed comment in the preflight (with a rescue path that is untested and misattributes its cause), and a silent-degrade corner in the harness CLI.

## Warnings

### WR-01: Preflight origin refusal comment claims "a failed observation refuses", but unreadable inputs fall through to `:none` (pass)

**File:** `lib/crosswake/proof_lane/physical_iphone_preflight.ex:277-301` (depends on `lib/crosswake/shell/ios_host_origin_mode.ex`, `observe/2`, `signal?/3`)
**Issue:** The doc comment says "any signal (or a failed observation) refuses rather than passes." That is true only when `observe/2` raises. When `Info.plist` is unreadable, `observe_plist` returns `:unreadable`, which is not a signal. When `Fixtures/route_activation.json` is unreadable or malformed, `observe_activation` returns `:none`. With a production (or absent) declaration, the result is `:none`, so `origin_refusal_for` returns nil and the origin check passes. A host whose generated origin files cannot be read is therefore not refused. This is the absence-scores-as-success pattern AGENTS.md calls out. The existing tests only cover "signal present" and "files readable and production".
**Fix:** Either make the code honor the comment or correct the comment. To honor it, treat an existing shell root with both origin inputs unreadable as a refusal, for example by having `origin_refusal_for` call `File.dir?(root)` and then require at least one readable origin input. Add a test whose `Info.plist` is replaced by a directory (`eisdir`) while `route_activation.json` is absent, and assert it is blocked by `PI-PREFLIGHT-CONFIG`. If the other preflight checks already cover the unreadable-host case, reword the comment to say so.

### WR-02: Untested `rescue` in `origin_refusal_for/2` reports any crash as the local-loopback refusal

**File:** `lib/crosswake/proof_lane/physical_iphone_preflight.ex:302-304`
**Issue:** `rescue _ -> Generator.local_mode_refusal()` is fail-closed, but it labels an unrelated exception (a bug in `observe`, a malformed `:ios_host` shape that raises, a bad `ios_shell_root`) as "this host is local loopback". The mix task then prints that refusal text as `cause`. An operator would regenerate the host in production mode and still be blocked, with no sign of the real fault. No test exercises this branch. It was flagged in the review brief as the untested rescue path, and no test drives it.
**Fix:** Add a distinct cause for the exception path and a test that forces it. For example, pass an `:ios_host` declaration that makes `IOSHostConfig.normalize/1` raise, or a non-binary `ios_shell_root`, and assert the result is blocked with `PI-PREFLIGHT-CONFIG`. Keep the rule id, but use a cause such as "the host origin mode could not be determined" instead of the local-mode text. The refusal then stays fail-closed without misleading the operator.

### WR-03: Harness argument parsing can skip the evidence file or die before the trap, outside the documented exit codes

**File:** `script/verify_loopback_origin_simulator.sh:25-34, 286-303`
**Issue:** Two corners:
1. `--evidence ""` sets `EVIDENCE=""`. The precheck is guarded by `[[ -n "$EVIDENCE" ]]`, so the run proceeds and can end `passed` (exit 0) with no evidence file written. The new D-12 guard is bypassed by passing an empty path. That is a pass on absence.
2. `--evidence` as the last argument makes `shift 2` fail under `set -e` before the EXIT trap is installed. The script exits 1 with no JSON object. The guide documents only 0, 2 and 3, and the header promises "stdout: exactly one JSON object".

Both are reachable by a mistyped or empty shell variable (`--evidence "$OUT"` with `OUT` unset).
**Fix:** Track whether the flag was seen and treat an empty value as an error:
```bash
EVIDENCE_REQUESTED=0
...
--evidence)
  [[ "$#" -ge 2 && -n "${2:-}" ]] || { echo "error: --evidence needs a path" >&2; exit 2; }
  EVIDENCE="$2"; EVIDENCE_REQUESTED=1; shift 2 ;;
```
Better, install the trap first and call `block "LOOP-IOS-EVIDENCE" "--evidence needs a path"` so the failure carries JSON and exit 2. Add a harness test for `--evidence ""`.

## Info

### IN-01: Allow-list for build byproducts is an unverified assumption

**File:** `script/verify_loopback_origin_simulator.sh:584-587, 618-623`
**Issue:** The comment already notes the allow-list is an assumption for Phase 188 to confirm. The allow-list covers only added files under the generated xcodeproj's `project.xcworkspace/` and `xcuserdata/`. A build that adds a file elsewhere in the generated project, for example a derived or cache directory, blocks a genuine run with `LOOP-IOS-OWNED-HASH`. This fails closed, so it is not a correctness bug, but it could cost a Phase 188 run. The generator does not emit `Package.resolved`, so the "changed existing file" case is unlikely. Confirm on the first real run, and record the observed added paths in the evidence.
**Fix:** Have the real run log the sorted list of added paths on success (not only on failure) so the allow-list can be tightened or widened from evidence.

### IN-02: Evidence-writability branch and relative-path edge cases lack a test

**File:** `test/crosswake/proof_lane/loopback_origin_harness_test.exs` (evidence cases), `script/verify_loopback_origin_simulator.sh:297-301`
**Issue:** The "not writable" branch (probe file cannot be created) has no test. The missing-directory, directory-as-path, mv-failure and relative-path cases are covered. Under uid 0 a chmod fixture would assert nothing, so the right fixture is a read-only parent that the test can verify, or an explicit skip. The leftover `.crosswake-loopback-evidence-probe.$$` file is also not asserted absent after a failed `rm`.
**Fix:** Add one case with a parent directory the shell cannot write to, skipped explicitly when the process runs as root, and assert the probe file does not remain.

### IN-03: `display_location/2` resolves `..` in a symlink target lexically before resolving links in the target

**File:** `lib/crosswake/shell/shell_package.ex:418-433`
**Issue:** `walk/3` calls `Path.expand(target, parent)`, which collapses `..` lexically. A target such as `link/../x` where `link` is itself a symlink resolves differently from the filesystem. The effect is only that an in-project path might be shown as `<outside project>` (or the reverse for an exotic layout). It cannot leak a raw path, because every branch returns a project-relative, `<home>/…` or placeholder string. The `"remote " <> _` clause also returns any string with that prefix unredacted, which is correct for values from `resolve/1` but is a latent leak if a caller ever passes a user-supplied string.
**Fix:** Optional. Document the limits in the function comment, or restrict the remote clause to the exact generated form `"remote crosswake-shell-core-ios"`.

### IN-04: `render/2` now evaluates `File.cwd!/0` even when no shell package is supplied

**File:** `lib/crosswake/shell/ios_host_generation.ex:20-24`
**Issue:** `Keyword.get_lazy(opts, :project_root, &File.cwd!/0)` runs while building the arguments for `shell_gate/3`, even for the `:error` clause that deliberately does nothing. The comment on that clause says no `:shell_package` key keeps the "pure byte projection". The pure path now depends on the working directory existing. If the working directory was deleted, `File.cwd!/0` raises.
**Fix:** Resolve the root inside the `{:ok, source}` clause:
```elixir
defp shell_gate(_manifest, :error, _opts), do: :ok
defp shell_gate(manifest, {:ok, source}, opts) do
  project_root = Keyword.get_lazy(opts, :project_root, &File.cwd!/0)
  ...
```

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
