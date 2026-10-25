---
phase: 181-core-host-command-seam
reviewed: 2026-10-14T00:00:00Z
depth: standard
base: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
head: 12f84cd950d4574921767df823faed6797c17c26
files_reviewed: 27
files_reviewed_list:
  - lib/crosswake/host_commands.ex
  - lib/crosswake/router.ex
  - lib/crosswake/policy/validator.ex
  - lib/crosswake/policy/compiler.ex
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/manifest/manifest.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/manifest/validator.ex
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/crosswake/shell/shell_package.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
  - examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandSeamTests.swift
  - test/crosswake/manifest/host_commands_test.exs
  - test/crosswake/policy/host_commands_test.exs
  - test/crosswake/router_host_commands_test.exs
  - test/crosswake/doctor/doctor_host_commands_test.exs
  - guides/compatibility.md
  - guides/native_shell_upgrade.md
findings:
  critical: 0
  high: 0
  medium: 4
  low: 6
  info: 3
  total: 13
status: issues_found
---

# Phase 181: Code Review Report (advisory)

**Depth:** standard. **Verified by running:** the Elixir host-command tests (143 tests, 0 failures) and the Swift `HostCommand|OfflineIsland` filter (41 tests, 0 failures) in the candidate repo. No source files were modified.

## Summary

The core shape is sound. The main questions came back clean:

- A `host.*` reference cannot pass without a router declaration. The policy validator is membership-checked against the router registry. `Compiler.compile` always passes a registry, and a router that declares nothing denies every `host.*` reference.
- Swift grants are per-route. Capabilities are `declared ∩ registered ∩ 1.x.y`. `request.capabilities` `host.*` entries are stripped from sessions. The navigation closure drops host entries for non-entry routes.
- In the D-28 legacy path (`hostCommands == nil`), an absent entry id or a non-entry route grants nothing. A JSON `null` decodes to `[:]`, which denies everything.
- Elixir and Swift use the same name grammar and reserved prefixes. The manifest serializer always emits `host_commands`, so a Crosswake-generated manifest never lands in the legacy path.
- I found no way for a host command to leak across routes.

The real defects are narrower:

- the seam-version check is not the major-version check the guides claim it is;
- the legacy path and several fail-closed paths degrade without a diagnostic;
- Elixir and Swift disagree on leading-zero versions;
- the shell-package gate and the doctor have silent-pass paths and path exposure.

## Medium

### M-01: Seam-version demand is `provides >= demands`, not a major check, contradicting the guide
**File:** `ActivationCoordinator.swift:272` (`SemVer.compatible(provides: HostCommandSeam.version, demands: $0)`); `guides/compatibility.md` ("refuses to activate a declaring route when the major versions differ")
**Scenario:**
- A manifest carrying `host_command_seam_version: "0.5.0"` is treated as satisfied, because 1.0.0 >= 0.5.0.
- A shell later bumped to seam 2.0.0 would accept a 1.x manifest as compatible, because 2.0.0 >= 1.0.0.
- The guide promises a major-version refusal. The code is a minimum-floor check.
- On mismatch the route still activates with no host commands. It is not refused. Only the commands are denied (`seam_unsupported`), and that denial is not surfaced anywhere except the bridge reply text.

**Fix:** Either implement a major-equality check via `supportsCommandVersion`-style parsing, or correct the guide to "minimum floor". Add tests for demand `0.5.0` and for a non-parseable demand such as `1.0.0-beta`. The latter falls to raw equality and is denied. That is fail-closed, but it is unasserted.

### M-02: D-28 legacy path grants and denies silently, with no version or declaration check
**File:** `ActivationCoordinator.swift:263-270` (the `guard let declared` else-branch)
**Scenario:**
- For the entry route of a pre-1.2.0 manifest, every `host.*` key in `request.capabilities` that is also registered is granted.
- That grant does not check `route.capabilities`, the 1.x.y version range, or the seam, and it records no diagnostic.
- A baseline activation carrying `host.x.y.z: "9.0.0"` is granted at 9.0.0.
- Unregistered keys were already removed in `loadAndFilterRequest` (`ActivationCoordinator.swift:704-709`) with no diagnostic. This is the "degrades silently" case from AGENTS.md.

**Fix:** In the legacy branch, also require `HostCommandSeam.supportsCommandVersion(version)` and `route.capabilities.contains(key)`. Record `HostCommandDiagnostic` entries for dropped or denied keys, including the filter in `loadAndFilterRequest`.

### M-03: Doctor `stale_host_command_findings` passes silently when the generated fixture is unreadable or malformed
**File:** `lib/crosswake/doctor/doctor.ex` (`stale_host_command_findings`, the `else _ -> []` clause)
**Scenario:**
- `Fixtures/crosswake_manifest.json` is truncated, is not valid JSON, or has no `routes` map.
- The check returns `[]`, the same result as a fresh fixture. Doctor reports no stale host commands while the shell is actually working from a corrupt manifest.
- The shell would also fail to load that manifest at runtime.

**Fix:** Distinguish `{:error, :enoent}` (no fixture, skip) from decode or shape failures, and emit an error check such as `host_commands_unverifiable`.

### M-04: Doctor and gate diagnostics embed absolute local filesystem paths
**File:** `lib/crosswake/doctor/doctor.ex` (`shell_unsupported_finding` message and `details.package_location`); `lib/crosswake/shell/ios_host_generation.ex` (`shell_gate_message`)
**Scenario:**
- `package.location` is `Path.expand(relativePath, managed_root)`, for example `/Users/<name>/…/crosswake-shell-core-ios`.
- It is placed in the doctor message, in `details`, and in the `Mix.raise` text.
- Doctor output flows into proof artifacts and CI logs. AGENTS.md requires no account or device identifiers in doctor output or proof artifacts. A home-directory username is an account identifier.

**Fix:** Report the path relative to the project root, or `local package (relativePath as written in the project)`. Do not emit the expanded absolute path.

## Low

### L-01: Swift accepts leading-zero command versions that Elixir rejects
**File:** `ActivationCoordinator.swift` (`supportsCommandVersion`) vs `lib/crosswake/host_commands.ex:62` (`strict_semver?` → `Version.parse`)
**Scenario:**
- `"01.0.0"` and `"1.00.0"` are digit-only and `Int(parts[0]) == 1`, so Swift grants them.
- Elixir rejects them because `Version.parse` refuses leading zeros.
- This is reachable only with a hand-edited manifest. It breaks the stated "same range enforced independently" parity.
- The Swift tests (`test_command_name_grammar_and_version_range_helpers`) do not cover it.

**Fix:** Reject any segment longer than one character that starts with "0", and add test vectors.

### L-02: A single invalid `host_commands` key fails the whole manifest decode
**File:** `ActivationCoordinator.swift` (`ShellManifest.Route.init(from:)` throws `dataCorruptedError`)
**Scenario:**
- One bad key on one route makes `JSONDecoder` fail for the whole `ShellManifest`.
- All routes then deny, including routes unrelated to host commands.
- It is fail-closed, but the blast radius is the whole app. The cause appears only as `manifest_unavailable` in `hostCommandDiagnostics`, and only on the navigation path, so the reason is not distinguishable from an I/O failure.

**Fix:** Decode the bad route as `hostCommands = [:]` and record a `host_commands_invalid` diagnostic, or at least make the diagnostic distinguish decode errors.

### L-03: `hostCommandDiagnostics` is write-only product state and grows without bound
**File:** `ActivationCoordinator.swift:337,624,630`
**Scenario:**
- Nothing in the product code (lib, packages, examples) reads `hostCommandDiagnostics`. Only tests read it, so the "recorded diagnostics" are not observable by a host or by doctor.
- `manifest_unavailable` and `request_unavailable` are appended on every call with no dedup. Only `recordHostCommandDenials` dedups.
- It is mutated from the navigation-resolver closure, outside any actor annotation.

**Fix:** Dedup all entries or cap the array, and expose it deliberately: a `@Published` property or a documented accessor.

### L-04: Elixir manifest `Validator` checks only one direction and only names
**File:** `lib/crosswake/manifest/validator.ex` (`validate_route_host_commands`)
**Scenario:**
- It verifies that each `host_commands` key is in `route.capabilities`.
- It does not verify the reverse: a `host.*` capability with no `host_commands` entry is accepted.
- It also checks neither the key grammar, the version string, nor that the runtime is a bridge runtime.
- A hand-built or deserialized manifest (`Builder.build` called without the `:host_commands` opt) validates cleanly. Swift then denies the command (`default` message: "did not declare"), which is misleading.

**Fix:** Add the reverse check, and validate grammar and version through `Crosswake.HostCommands`.

### L-05: Registry shape is inconsistent between the policy validator and the builder
**File:** `lib/crosswake/policy/validator.ex` (`registry_name/1` accepts bare binaries) vs `lib/crosswake/manifest/builder.ex:166` (`Map.new(registry)`)
**Scenario:**
- `Manifest.compile(routes_list, host_commands: ["host.a.b.c"])` passes policy validation, because bare names are accepted.
- It then crashes in `Builder.host_commands_for` with `ArgumentError`, because `Map.new` needs tuples. This is an unhelpful crash rather than a diagnostic.
- The `@spec` of `host_commands_for` also admits a `map`, which `Enum.map` in `validate` does not handle.

**Fix:** Normalize via `HostCommands.normalize_registry!` or reject bare names in `host_command_registry/2`.

### L-06: A page-controlled bridge request with no version produces a misleading denial text
**File:** `BridgeChannel.swift:414-423` and `hostCommandDenialText`
**Scenario:**
- A command that is granted in the session but sent with no `capabilities[command]` fails `SemVer.compatible`.
- `session.hostCommandDenials[command]` is nil, so the reply says "Route X did not declare host command Y".
- That is false: the route did declare it. The wire reason is correct (`undeclared_capability`), but the explanation misdirects the integrator.

**Fix:** Add a distinct text for "granted but caller did not supply a compatible version".

## Info

### IN-01: Doc/code mismatch on seam refusal
See M-01. The `compatibility.md` sentence "refuses to activate a declaring route" is also inaccurate on the second point: the route activates and only the commands are withheld.

### IN-02: Duplicate switch arms in the example host
**File:** `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift:447`
The `.offlineIsland` arm is a copy of the `.liveView` arm. Fold them into one arm (`case .liveView(let session), .offlineIsland(let session)`).

### IN-03: `ShellPackage.seam_version_at` and `resolve({:project})` use text scraping
**File:** `lib/crosswake/shell/shell_package.ex:53,87`
Both greps depend on formatting:
- `relativePath = "…";` takes the first match in the pbxproj. This is correct today because the template has exactly one such line, but a second local package would make the gate inspect the wrong package.
- The `\n\}` terminator assumes the closing brace sits at column 0.

A formatting change in either file would make the gate return `nil` (blocked). That is fail-closed, so it is not a bypass. Pin the templates with a test that covers both.

## Test-quality notes (no vacuous tests found)

- The Swift grant-table, denial-message, and navigation tests assert concrete values. The 63-row table checks `rows == 63`.
- `XCTSkip` in `session()` is reached only after an `XCTFail`.
- The Swift test world rewrites every route's `runtime` to `live_view`. The offline-island behavior is covered separately in `OfflineIslandAdmissionTests`, and that suite passed.
- Missing vectors: leading-zero versions (L-01), seam demand `0.x` (M-01), and legacy-path version or declaration gating (M-02).
