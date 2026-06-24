---
phase: 121-canonical-contract-source
reviewed: 2026-06-20T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/shell/fixtures.ex
  - lib/mix/tasks/crosswake.contract.gen.ex
  - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt
  - test/crosswake/compatibility/compatibility_test.exs
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/proof/phase18_deep_link_activation_lane_test.exs
  - test/crosswake/shell/activation_test.exs
  - test/mix/tasks/crosswake_doctor_test.exs
  - examples/android_shell_host/app/src/main/assets/route_activation.json
  - examples/ios_shell_host/Fixtures/route_activation.json
  - test/fixtures/bridge_contract_vectors.json
  - docs/_contract_snippet.md
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 121: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 121 collapses the bridge-protocol-version axis onto a single Elixir authority
(`Crosswake.Bridge.Contract.version/0` = `"1.1.0"`) and derives four non-Elixir
contract surfaces from it via `mix crosswake.contract.gen`. The core mechanics are
sound and were verified empirically:

- **Compile-time derivation is correct.** `lib/crosswake/manifest/types.ex:652`
  reads `Crosswake.Bridge.Contract.version()` into a module attribute. `mix xref`
  confirms this creates a `(compile)` dependency, so `Types` recompiles when the
  canonical `@version` changes — no stale-value bug.
- **Generator is idempotent.** Re-running `mix crosswake.contract.gen` produced
  zero git diff; all four files reported `unchanged`. Verified.
- **Axis discipline holds where intended.** `bridge_protocol_version=1.1.0` with
  `native_runtime_version=1.0.0` is correct, deliberate separation in the generated
  fixtures, docs snippet, and vectors.
- **Seed vectors are accurate.** `vec-002` (unknown command → `undeclared_capability`)
  matches the live mapping at `compatibility.ex:127`.
- **Kotlin fail-closed change is correct.** `ActivationFixtures.loadManifest` now
  `error()`s when the `compatibility` block / `native_runtime_version` is absent,
  replacing a silent default — a genuine hardening.

However, the phase regenerated `route_activation.json` to `1.1.0` in both example
apps while leaving the sibling `crosswake_manifest.json` in the same asset bundle at
`bridge_protocol_version: 1.0.0` — re-introducing, inside a single example app, the
exact drift this phase exists to eliminate (CR-01). Three quality/robustness warnings
and two info items follow.

## Critical Issues

### CR-01: Example manifest/activation bridge-protocol drift defeats the phase's purpose

**File:** `examples/android_shell_host/app/src/main/assets/route_activation.json:3` (and `examples/ios_shell_host/Fixtures/route_activation.json:3`)
**Companion stale file:** `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` / `examples/ios_shell_host/Fixtures/crosswake_manifest.json`

**Issue:** The generator regenerated each example's `route_activation.json` to the
canonical `bridge_protocol_version: "1.1.0"`. The sibling `crosswake_manifest.json`
in the **same** asset directory still carries `bridge_protocol_version: "1.0.0"`
(verified: `git log` shows it was last touched in phases 116/54/46, predating the
version bump). Within one example app's bundled assets, the manifest and the
activation request now disagree on the bridge-protocol axis — precisely the
1.1.0-vs-1.0.0 drift Phase 121 was chartered to collapse.

Confirmed via `Crosswake.Manifest.Types.new_compatibility().bridge_protocol_version`
returning `"1.1.0"` at runtime, while the committed example manifests read `"1.0.0"`.

The example `crosswake_manifest.json` is not one of the four paths in
`crosswake.contract.gen`, and `mix crosswake.gen.shell` writes to `target/native/...`
(a host scaffold dir), not to `examples/`. So nothing regenerated these committed
example manifests, and no generate-and-diff guard covers them.

Runtime impact is currently masked — the Kotlin `resolve/2` only compares
`nativeRuntimeVersion` (`1.0.0 == 1.0.0`), so the example still boots — but the
shipped contract surface is now self-contradictory and the drift-elimination
guarantee is false for the example hosts.

**Fix:** Bring the example manifests under the canonical authority. Either (a) add
the two `crosswake_manifest.json` example paths to `crosswake.contract.gen`'s
generated set (emitting `compatibility.bridge_protocol_version` from
`Crosswake.Bridge.Contract.version()`), or (b) regenerate them via the
`Crosswake.Shell.Fixtures`-backed path and wire a CI generate-and-diff that fails on
drift. At minimum, update both files now:

```json
"compatibility": {
  "bridge_protocol_version": "1.1.0",
  ...
}
```

and add a guard so a future `@version` bump cannot leave them behind again.

## Warnings

### WR-01: Generator's determinism rationale is factually wrong; idempotency is incidental, not guaranteed

**File:** `lib/mix/tasks/crosswake.contract.gen.ex:174-189`

**Issue:** The comment block claims byte-stable output is achieved because
`Map.new/1` on a sorted keyword list "produces a map whose key insertion order
matches the sort, and Jason iterates it in that order on OTP 26+." This is incorrect.
Jason iterates BEAM maps in internal storage order, not insertion order. Verified
empirically: a 40-key map (`> 32` entries, where Elixir switches from the ordered
"flatmap" to a hash array-mapped trie) Jason-encodes in hash order
(`{"k3":..,"k34":..,"k28":..}`), **not** sorted and **not** insertion-ordered. The
`Enum.sort_by/2` sorts the keyword list, but `Map.new/1` then discards that order.

Today every generated object has fewer than 32 keys, so the small-map term ordering
happens to be stable and output is deterministic — which is why the idempotency
check passes. But the guarantee rests on an undocumented size constraint, not on the
mechanism the code claims. If any generated object grows past 32 keys, ordering
becomes non-deterministic and `write_if_changed` will churn / break idempotency.

**Fix:** Either sort at encode time independent of map storage (e.g. encode a sorted
list of pairs through a custom Jason encoder, or build with `Jason.OrderedObject`),
or correct the comment to state the real invariant and add an assertion/guard that
no emitted object exceeds the small-map threshold. Recommended: drop the
`Map.new/1` round-trip and encode the already-sorted pairs structure directly so
ordering is explicit and size-independent.

### WR-02: `write_if_changed` error branch can leak a partially-handled write failure

**File:** `lib/mix/tasks/crosswake.contract.gen.ex:218-239`

**Issue:** The `case File.read(path)` only distinguishes `:ok`, `{:error, :enoent}`,
and a catch-all `{:error, reason}` that calls `Mix.raise`. But the `:ok` branches and
the `:enoent` branch both call `File.write!/2`, whose own failure (permissions,
read-only FS, disk full) raises a raw `File.Error` rather than the friendly
`Mix.raise` message the read path provides. The error handling is asymmetric:
read failures get a formatted message, write failures get a bare stacktrace. For a
generator meant to be run routinely in CI and by contributors, the write path
deserves the same treatment.

**Fix:** Wrap the writes (or switch to `File.write/2` and match the result) so a
write failure raises through `Mix.raise("could not write #{relative_path}: ...")`,
matching the read-error branch.

### WR-03: `convert_value` clause ordering makes empty-list and nil handling unreachable for the common path

**File:** `lib/mix/tasks/crosswake.contract.gen.ex:201-212`

**Issue:** `convert_value(pairs) when is_list(pairs) and pairs != []` (line 201) is
defined before `convert_value([])` (210) and `convert_value(nil)` (211). The first
clause guards `pairs != []`, so `[]` correctly falls through to line 210 — that part
is fine. But the structure is fragile: the head clause re-implements the
`pairs_list?` dispatch that `pairs_to_map` already performs, and the two functions
(`pairs_to_map`/`convert_value`) duplicate the same list-vs-pairs branching logic.
This duplication is a maintenance hazard — a future edit to one branch (e.g. handling
a new nested array shape) must be mirrored in the other or nested values will be
silently mis-encoded. There is no test exercising a nested array-of-objects path
through the generator to catch such a divergence.

**Fix:** Unify the recursion into a single `convert/1` that pattern-matches on shape
once, eliminating the parallel `pairs_to_map` / `convert_value` branching. Add a
generator unit test that round-trips a nested array-of-objects vector and asserts
byte-stable output.

## Info

### IN-01: Dead private function `requiredPacks` in Kotlin coordinator

**File:** `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt:546-551`

**Issue:** `private fun requiredPacks(route)` is defined but never called anywhere in
the file (grep confirms the only occurrence is the definition). It parses
`pack@version` strings into a map — functionality that overlaps with `PackStore`
handling elsewhere. Dead code in a published shell-core package.

**Fix:** Remove `requiredPacks`, or wire it into the pack-resolution path if it was
intended to be used.

### IN-02: Generated `denial_reasons` array carries reasons not exposed in the Kotlin `RouteDenialReason` enum

**File:** `test/fixtures/bridge_contract_vectors.json:18-31` vs `packages/.../ActivationCoordinator.kt:28-36`

**Issue:** The generated vectors enumerate 12 denial reasons (including
`commerce_corridor`, `gate_denied`, `kill_switch_active`, `step_up_required`,
`notification_open_denied`), but the Kotlin `RouteDenialReason` enum defines only 7
(missing those 5). This is not introduced by Phase 121 and the vectors correctly
mirror the Elixir `Denial.@reasons` authority, so the Elixir side is canonical and
right. Flagging only so the native-proof consumer (Phase 123) is aware the Kotlin
enum is a strict subset — a vector referencing one of the 5 unmapped reasons would
have no native counterpart to assert against.

**Fix:** No action required in Phase 121. Track for Phase 123 native-proof: either
extend the Kotlin enum or scope the conformance vectors to the reasons the native
shell actually models.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
