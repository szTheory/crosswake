# Cross-Artifact Drift-Guard & Conformance Architecture

**Project:** Crosswake v14.0 Runtime Contract Confidence
**Domain:** Multi-artifact contract drift prevention — one versioned protocol contract, many consumers
**Researched:** 2026-06-20
**Overall confidence:** HIGH

---

## Problem Statement

The Crosswake bridge protocol version currently lives in at least eight places. The canonical form in `Crosswake.Bridge.Contract` says `1.1.0`. The manifest compatibility defaults in `Crosswake.Manifest.Types`, the shell fixtures in `Crosswake.Shell.Fixtures`, activation fixtures in `examples/ios_shell_host/Fixtures/route_activation.json` and the Android equivalent, and the route-tour proof all say `1.0.0`. The native bridge code in `BridgeChannel.swift` and `ActivationCoordinator.kt` requires EXACT equality on the protocol version field — so an otherwise valid bridge request from the proof lane will be denied by the native runtime because the proof says `1.0.0` and the Elixir contract says `1.1.0`.

The drift surfaces are:

| Surface | Location | Current value |
|---------|----------|---------------|
| Elixir bridge contract | `lib/crosswake/bridge/contract.ex` L10 | `1.1.0` |
| Manifest compatibility defaults | `lib/crosswake/manifest/types.ex` L652 | `1.0.0` |
| Shell activation fixtures | `lib/crosswake/shell/fixtures.ex` L82 | `1.0.0` |
| iOS host fixture | `examples/ios_shell_host/Fixtures/route_activation.json` | `1.0.0` |
| Android host fixture | `examples/android_shell_host/app/src/main/assets/route_activation.json` | `1.0.0` |
| Manifest schema/native runtime defaults | `lib/crosswake/manifest/types.ex` L651-653 | `1.0.0` |
| Docs (compatibility.md, support_matrix.md) | `guides/compatibility.md`, `guides/support_matrix.md` | mentions field names, no literal |
| Generated shell templates | `priv/templates/` | not yet confirmed |

The guard architecture must make it structurally impossible for this disagreement to survive a PR merge.

---

## Real-World Precedents

### 1. `go generate` + `git diff --exit-code` — Committed Codegen Discipline

**How it works.** The canonical source (a schema, interface definition, or annotated Go file) drives code generation at development time. Generated files are committed. CI reruns the generator and then runs `git diff --exit-code` — any difference between the committed state and the freshly generated state fails the build.

**Users.** The Go toolchain itself, `sqlc` (SQL to Go type-safe queries), `buf generate` for protobuf stubs, `templ` (Go HTML templates), OpenAPI generator pipelines, and innumerable internal Go codebases.

**Key properties:**
- Deterministic: same input → same output, every time.
- Self-auditing: the generated artifact is human-readable and code-reviewable.
- Low maintenance: CI never needs to "know" about consumers; the diff gate catches any consumer that failed to regenerate.
- The failure message is exactly `git diff --exit-code` output: which file changed, what line, what value. Contributors see the diff immediately.

**Footguns:**
- Generator non-determinism (e.g. map iteration order, timestamp embedding) causes false positives on every run. The generator must be pure and deterministic.
- If generation requires platform tooling not present on CI (e.g., native SDKs), the check silently skips the platform-specific output.
- Large generated diffs create noisy PRs and slow code review. Mitigated by keeping generated files small and semantically tight (version strings, not entire schemas).

**Worked example (`buf generate --diff`):**
```
# In .github/workflows/ci.yml:
- name: Verify generated files are up to date
  run: |
    buf generate
    git diff --exit-code -- gen/
```
Failure output: `gen/bridge_v1.pb.go: line 14: -const BridgeProtocol = "1.0.0" +const BridgeProtocol = "1.1.0"` — clean, exact, actionable.

### 2. `buf breaking` — Protocol Backwards-Compatibility CI

`buf breaking` compares the current `.proto` schema against a baseline (a Git branch, a BSR module, or a committed image) and reports changes that would break wire compatibility. It surfaces violations as PR annotations at the exact line where the breaking change was introduced.

The key insight: `buf breaking` separates WIRE compatibility from SOURCE compatibility. A field rename breaks generated code but not the binary wire format. A field-type change from `int32` to `string` breaks both. The Crosswake problem is analogous: bridge protocol version drift breaks WIRE compatibility (native denies the request) while other contract fields drifting (command names, envelope shape) would break both wire and source.

**What Crosswake copies from `buf`:**
- Separate "what breaks the wire" from "what breaks generated code" — encode these as separate check tiers.
- Use a committed baseline (the canonical source file) as the reference, not a live service.
- Surface violations at the exact location (file + line) that introduced the drift, not at a downstream consumer.

### 3. `cargo-semver-checks` — Structural SemVer Enforcement

`cargo-semver-checks` uses `rustdoc`'s JSON output to detect when a Rust crate's public API has changed in a way that violates SemVer: a minor version bump that removed or renamed a public function, or a patch bump that changed a type signature. It runs in CI against the diff since the last published version.

**What Crosswake copies:**
- The guard lives at the DEFINITION point (the Elixir module that owns the version), not at every consumer.
- The check is machine-derivable from source structure, not from a manually maintained list.
- It runs after compilation (the compiler already enforces structure), so no native toolchain is needed for the check itself.

### 4. Cross-Language Conformance Test Suites — JSON-Schema, CommonMark, Protocol Buffers

These suites define a body of canonical input/output pairs as committed JSON or plain-text files. Each language implementation runs the same vectors independently and must agree on accept/deny outcomes.

**Protocol Buffers conformance tests** (google/protobuf `conformance/`): A tester process sends serialized messages over a pipe; each language implementation decodes and re-encodes them; the tester compares outputs. The cross-language comparison happens in CI automatically. Violations point to implementation divergence, not spec divergence.

**JSON Schema Test Suite** (json-schema-org/JSON-Schema-Test-Suite): Language-agnostic JSON files, each containing a schema, an instance, and a boolean `valid` expectation. Any implementation loading these files and evaluating them must agree on every `valid` field. The suite is the shared contract; implementations are consumers.

**CommonMark spec**: Over 650 examples embedded in `spec.txt` as `markdown → HTML` pairs. A reference script (`spec_tests.py`) runs them against any Markdown program and reports pass/fail per example.

**Unicode/CLDR conformance** (unicode-org/conformance): Parameterized test data JSON files. Each Unicode algorithm implementation loads the same JSON and must produce identical outputs.

**The shared pattern across all four:**
- The fixtures are committed source-controlled JSON/text — not generated at test time.
- Each implementation loads the fixtures independently, with no shared library code between languages.
- The fixture format is simple (input + expected output), not an RPC or shared runtime.
- Adding a new fixture adds a new row; implementations that fail the new row report a clear per-fixture failure.
- The fixtures themselves serve as executable specification — they are the contract document.

**What Crosswake copies:** Commit a `test/fixtures/contract/vectors/` directory of canonical bridge request/reply pairs with explicit `accept: true/false` and `protocol_version:` fields. Elixir ExUnit tests load and evaluate them; iOS/Android test suites load the same files from a shared fixtures reference and must agree on accept/deny outcomes. The fixtures are the contract.

### 5. Pact / Consumer-Driven Contract Testing — When It Is Overkill

Pact solves the problem of independent teams with separate deploy pipelines: consumer teams publish their expectations; provider teams run those expectations against their deployed API before releasing. The broker manages the contract lifecycle.

**Fit assessment for Crosswake:**
- Crosswake is a single-team in-repo OSS library.
- The iOS and Android packages are co-located in `packages/` in the same repository.
- There is no independent deploy pipeline between consumer and provider teams; a PR changes both.
- The Pact FAQ explicitly calls out "when you control both consumer and provider" as a lower-value case.

**Verdict:** Pact is structural overkill here. It adds: a Pact broker dependency, cross-language Pact client libraries for Swift and Kotlin, a publish/verify lifecycle across CI jobs, and a shared state concept that does not match "one version string in several files." The conformance-vector approach solves the same problem with simpler machinery.

**What Pact would add that conformance vectors do not:** In a true multi-team microservice topology with independent consumers, Pact's "consumer publishes, provider verifies" lifecycle prevents the provider from making a breaking change that the consumer has not yet updated for. Crosswake does not have that topology today; both sides change together in one repo.

---

## Four Approaches — Comparison

### Approach 1: Generate-and-Diff (Committed Codegen + `git diff --exit-code`)

**Concept.** A canonical source file drives a generator that emits: updated `types.ex` defaults, JSON fixture files for iOS/Android, and doc snippets. CI runs the generator, then `git diff --exit-code`. Any uncommitted change fails.

**Pros:**
- Deterministic, zero-flake risk (pure function: same input → same output).
- Forces the contributor to think about ONE place to change: the canonical source.
- The diff is the error message — exact line, exact file, exact expected vs. actual value.
- The generated artifacts are human-readable and reviewable in PRs.
- Composable with established `go generate`, `buf`, `sqlc`, `prisma` discipline.

**Cons:**
- Requires a working generator (`mix crosswake.gen.fixtures` or equivalent). Must be built as part of v14.
- Generator must be deterministic (no timestamps, no random ordering). Easy in Elixir, but requires explicit care.
- If generation requires native tooling (Swift/Kotlin compiler), the CI job cannot run it without Xcode/Gradle. Native source constants cannot be generated without the native SDK.
- Means fixture files are generated, not hand-crafted. Contributors editing fixture behavior must edit the canonical source and regenerate, adding friction if the generator is not obviously discoverable.

**Tradeoffs for native file surfaces:**
- Elixir → JSON fixture generation is tractable: `Crosswake.Shell.Fixtures` already computes these values; making it write committed files is straightforward.
- Elixir → Swift/Kotlin constant generation requires a text-emitting generator (no native compile), which is achievable but footgun-prone: contributors may hand-edit the generated constant without realizing they should regenerate.

**Worked example — failure:**
```
$ mix crosswake.gen.fixtures && git diff --exit-code
diff --git a/examples/ios_shell_host/Fixtures/route_activation.json ...
-  "bridge_protocol_version": "1.0.0",
+  "bridge_protocol_version": "1.1.0",
Exit code 1
```

**Assessment:** The strongest approach for JSON surfaces. Weaker for native Swift/Kotlin because it requires either (a) a text-only generator that emits Swift/Kotlin source without native tooling, fragile against native-side structural changes, or (b) skipping native artifact generation entirely and relying on conformance vectors for cross-language assurance. Use for JSON fixtures; defer native source generation.

---

### Approach 2: Single-Reader Assertion Test (ExUnit Reads Every Surface)

**Concept.** An ExUnit test module (`test/crosswake/contract/drift_guard_test.exs`) reads `Crosswake.Bridge.Contract.version()` as the canonical value, then asserts every other surface by reading files as text:
- `Types.new_compatibility().bridge_protocol_version` (runtime value — refactoring-safe)
- `Crosswake.Shell.Fixtures` activation attributes
- JSON parse of `examples/ios_shell_host/Fixtures/route_activation.json`
- JSON parse of `examples/android_shell_host/app/src/main/assets/route_activation.json`
- Narrow regex on `guides/compatibility.md` for the section mentioning the version

No native toolchain. No generator. Pure Elixir file reading and text matching.

**Precedent in Crosswake.** This is exactly what `Crosswake.Proof.Phase96ThreadlineDocsContractTest` does for the threadline guide, and what `Crosswake.Guides.QuickStartAdoptionDriftTest` does for quick start drift. The pattern is mature and already trusted in this codebase.

**Pros:**
- Zero new infrastructure: ExUnit + `File.read!/1` + `Jason.decode!/1`.
- Runs in the standard `mix test` job, no generator, no git state changes.
- Canonical value is read from a live module attribute (`Crosswake.Bridge.Contract.version/0`), not a separate config file.
- JSON surfaces are parsed structurally, not regex'd — low brittle-scan risk for the high-stakes native fixture files.
- Text scanning of native Swift/Kotlin source for the protocol version constant is feasible and safe for a narrow, stable constant: the assertion is one string, not a full AST parse.
- Consistent with the house pattern: `phase96_threadline_docs_contract_test.exs`, `quick_start_adoption_drift_test.exs`, `closeout_ci_parity_test.exs` all use this shape.

**Cons:**
- Does not prevent the wrong value from being committed — it only fails after the commit. The generator-and-diff approach would catch drift before the commit reaches CI.
- Text-scanning Elixir source for a module attribute is brittle (comment, whitespace). **Mitigated by asserting the RUNTIME value** — `Types.new_compatibility().bridge_protocol_version` — instead of scanning the source file.
- Text-scanning Swift/Kotlin source is moderately brittle. **Mitigated by asserting on the exact file path and constant name** and giving a clear fix instruction in the failure message.
- Does not prove that native code BEHAVES correctly with the version (only that it declares the right string). Behavioral proof requires either compiling native code or using conformance vectors.

**Assessment:** The correct primary mechanism for Crosswake. Pure Elixir, zero new dependencies, directly analogous to existing trusted guards, runs hermetically in CI, produces surgical failure messages. Its weakness — not preventing the commit — is addressed by making the fix command trivial.

---

### Approach 3: Conformance Vector Suite (Cross-Language Golden Fixtures)

**Concept.** A committed directory `test/fixtures/contract/vectors/` contains canonical bridge request/reply JSON pairs with explicit protocol version and accept/deny expectations:

```json
// test/fixtures/contract/vectors/bridge_v1.1.0_haptics_accept.json
{
  "description": "haptics.impact accepted when protocol version matches",
  "request": {
    "protocol": "crosswake.bridge",
    "version": "1.1.0",
    "command": "haptics.impact",
    "capability": "haptics.impact",
    "route_id": "dashboard",
    "active_route_id": "dashboard",
    "origin": "https://example.crosswake.invalid",
    "native_runtime_version": "1.0.0",
    "correlation_id": "vec-001"
  },
  "expected": {
    "accepted": true
  }
}

// test/fixtures/contract/vectors/bridge_version_mismatch_deny.json
{
  "description": "any request with wrong protocol version is denied with compatibility_mismatch",
  "request": {
    "protocol": "crosswake.bridge",
    "version": "0.9.0",
    "command": "haptics.impact",
    "capability": "haptics.impact",
    "route_id": "dashboard",
    "active_route_id": "dashboard",
    "origin": "https://example.crosswake.invalid",
    "native_runtime_version": "1.0.0",
    "correlation_id": "vec-002"
  },
  "expected": {
    "accepted": false,
    "denial_reason": "compatibility_mismatch"
  }
}
```

Elixir ExUnit loads these fixtures and runs them through `Crosswake.Bridge.Contract`. The iOS Swift tests load the same fixture files and run them through `BridgeChannel`. The Android JVM tests do likewise. Every implementation must agree on `accepted` for every vector.

**Pros:**
- Proves behavior, not just string equality. A native implementation that declares `"1.1.0"` but still denies valid requests would fail the `expected.accepted = true` vector.
- Language-agnostic: fixtures are plain JSON. No shared code. Each implementation loads and evaluates independently.
- Fixtures serve as executable specification — they document exactly what the contract means in terms of accept/deny decisions.
- Additive: adding a new vector tests a new behavioral edge case. The contract specification grows with confidence.
- No native toolchain needed in the Elixir CI job — only the Elixir side needs to evaluate vectors.

**Cons:**
- Does not catch VERSION STRING DRIFT by itself — a fixture with `"version": "1.1.0"` will pass against an Elixir implementation that still says `"1.0.0"` if the Elixir code is too permissive. Must be paired with a version-string drift guard.
- Cross-language evaluation requires native CI to be wired up — iOS needs `swift test`; Android needs `./gradlew test`. These are advisory in Crosswake's model.
- More fixture maintenance: every new command, every new denial reason, every version bump needs new or updated vectors.
- The Elixir-only evaluation of vectors only proves Elixir is self-consistent. Cross-language conformance only happens if native CI also runs.

**Assessment:** Conformance vectors are the right mechanism for proving cross-language BEHAVIORAL agreement. They are complementary to the single-reader assertion test, not a replacement. The version drift guard ensures strings agree. The vectors ensure behavior agrees with the strings.

---

### Approach 4: Pact Consumer-Driven Contract Testing

**Concept.** iOS and Android packages publish Pact contracts expressing what bridge request shapes they send and what responses they expect. The Elixir provider verifies these contracts before merging.

**Pros:**
- Establishes an explicit consumer-provider relationship that survives independent evolution.
- Pact broker provides centralized contract history.

**Cons:**
- Crosswake is a single-team in-repo library; Pact is designed for multi-team, multi-repo, independent-deploy scenarios.
- Requires a Pact broker, cross-language Pact libraries for Swift and Kotlin, and a publish/verify lifecycle across CI jobs.
- Significant operational complexity for a single-maintainer OSS library.
- Pact's own documentation calls out "when you control both sides" as a weaker use case.
- The value Pact adds — "consumer teams can change independently without breaking the provider" — does not apply when consumer and provider change in the same PR.

**Verdict:** Skip Pact entirely for Crosswake.

---

## Comparison Table

| Criterion | Generate-and-Diff | Single-Reader Assertion | Conformance Vectors | Pact |
|-----------|:-----------------:|:----------------------:|:-------------------:|:----:|
| Hermetic (no native toolchain) | Partial (JSON yes, Swift/Kotlin no) | Yes | Elixir-side yes | No |
| Catches version string drift | Yes | Yes | Partially (if vectors are version-specific) | Yes |
| Proves behavioral correctness | No | No | Yes | Yes |
| Zero new infrastructure | No (needs generator) | Yes | Minimal (JSON files) | No (needs broker) |
| Fit with existing house pattern | High | Highest (exact existing pattern) | High | Low |
| Contributor fix UX | Excellent (git diff) | Excellent (if messages designed well) | Good per-vector | Complex (broker CLI) |
| Flake risk | Zero (determinism) | Near-zero (pure reads) | Near-zero | Medium (broker availability) |
| Cross-language assurance | No (Elixir JSON gen only) | Text-scan only | Yes (if native CI runs) | Yes |
| Maintenance burden | Low-Medium | Low | Low-Medium | High |

---

## The "Scan Native Files as Text" Question

**Context.** `BridgeChannel.swift` declares `public static let protocolName = "crosswake.bridge"` but does NOT hardcode a version constant — it reads `bridge_protocol_version` from the manifest JSON at runtime. `ActivationCoordinator.kt` similarly reads `bridgeProtocolVersion` from parsed JSON. Neither native file currently has a hardcoded version string that would need updating when the protocol version changes.

The version drift in native code flows through the fixture JSON files, not through a native constant. The iOS fixture `Fixtures/route_activation.json` and the Android fixture `assets/route_activation.json` hardcode `"bridge_protocol_version": "1.0.0"` — and that is what the native code sends when running the example hosts.

**What this means for the guard:**

| Surface | Guard approach | Fragility |
|---------|---------------|-----------|
| Native fixture JSON files | `Jason.decode!/1` + field assertion in ExUnit | Near-zero — JSON is structural |
| Native Swift/Kotlin source (no current hardcoded version) | Not needed currently | N/A |
| If future Swift/Kotlin constant introduced | Narrow regex on exact constant name | Low — stable constant shape |

**Do not attempt to parse Swift AST or Kotlin bytecode in CI without the native toolchain.** The TypeScript AST approach in `check-e2e-honesty.mjs` works because TypeScript has a pure-JS compiler available as an npm package. Swift and Kotlin have no equivalent pure-Elixir or pure-Node parser. A text scan of a narrow, stable constant is acceptable and honest about its limitations; an AST parse without the native compiler is not.

**The deterministic/merge-blocking vs advisory split:**

| Check | Toolchain | Deterministic? | Should Block? |
|-------|-----------|---------------|---------------|
| `Contract.version/0` matches `Types.new_compatibility().bridge_protocol_version` | Elixir only | Yes | Merge-blocking |
| `Contract.version/0` matches `Shell.Fixtures` activation `bridge_protocol_version` | Elixir only | Yes | Merge-blocking |
| JSON parse of `examples/ios_shell_host/Fixtures/route_activation.json` | Elixir only | Yes | Merge-blocking |
| JSON parse of `examples/android_shell_host/.../route_activation.json` | Elixir only | Yes | Merge-blocking |
| ExUnit conformance vectors against Elixir bridge contract | Elixir only | Yes | Merge-blocking |
| `git diff --exit-code` after `mix crosswake.gen.fixtures` | Elixir + git | Yes | Merge-blocking |
| Swift test suite running conformance vectors | Xcode/swift test | Yes | Advisory |
| Android JVM test suite running conformance vectors | Gradle/JVM | Yes | Advisory |
| Manual native integration test on simulator/device | Xcode/simulator | No | Advisory |

The determinism criterion — not complexity — determines blocking status. If a check is deterministic and requires no environment-sensitive tooling, it blocks. If it requires Xcode, Gradle, a simulator, or a device, it is advisory: not because it is flaky, but because it cannot be guaranteed to run on every Linux CI runner.

---

## Failure Message Contract

The failure message is the most important product of a guard. A guard that fails with an opaque error gets bypassed; one that tells the contributor exactly what to change and how will be respected.

**Principles (from `check-e2e-honesty.mjs` precedent):**
1. Lead with what failed in human language, not a code location.
2. State the expected value and the actual value explicitly.
3. Give the single command to fix it.
4. Reference the canonical source location and the requirement it enforces.

**BAD failure message:**
```
** (ExUnit.AssertionError) Assertion with == failed
   left:  "1.0.0"
   right: "1.1.0"
   test/crosswake/contract/drift_guard_test.exs:22
```
This leaves the contributor wondering: which "1.0.0"? Which file? What does "1.1.0" refer to?

**GOOD failure message (target for v14.0):**
```
  ✖  Contract drift detected — bridge_protocol_version disagrees across surfaces.

     Canonical source: Crosswake.Bridge.Contract.version/0 = "1.1.0"
                       (lib/crosswake/bridge/contract.ex, @version attribute)

     Drifted surfaces:
       [FAIL] Types.new_compatibility().bridge_protocol_version
              actual: "1.0.0"  <- should be "1.1.0"
              location: lib/crosswake/manifest/types.ex @bridge_protocol_version

       [FAIL] examples/ios_shell_host/Fixtures/route_activation.json
              bridge_protocol_version: "1.0.0"  <- should be "1.1.0"

       [FAIL] examples/android_shell_host/app/src/main/assets/route_activation.json
              bridge_protocol_version: "1.0.0"  <- should be "1.1.0"

     FIX: Update lib/crosswake/bridge/contract.ex @version to your intended value,
          then run:
            mix crosswake.gen.fixtures
          to regenerate all derived surfaces from canonical contract truth.

          Or if the canonical source is wrong, update only:
            lib/crosswake/bridge/contract.ex  @version
          to match the value used everywhere else, then re-run mix test.

     See guides/compatibility.md for the bridge_protocol_version bump runbook.
```

This message satisfies the principle of least surprise for a contributor who has never seen this guard before. It answers: what drifted, where, what value is expected, and how to fix it in one command.

**Implementation pattern for multi-surface failure accumulation:**
```elixir
defmodule Crosswake.Contract.DriftGuardTest do
  use ExUnit.Case, async: true

  @canonical Crosswake.Bridge.Contract.version()

  test "bridge_protocol_version matches canonical contract across all surfaces" do
    failures = check_all_surfaces(@canonical)

    if failures != [] do
      flunk(format_drift_message(@canonical, failures))
    end
  end

  defp check_all_surfaces(canonical) do
    [
      check_manifest_compatibility(canonical),
      check_shell_fixtures(canonical),
      check_ios_fixture(canonical),
      check_android_fixture(canonical),
      check_docs_section(canonical)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp check_ios_fixture(canonical) do
    path = "examples/ios_shell_host/Fixtures/route_activation.json"
    assert File.exists?(path), "#{path} must exist (anti-rename evasion)"
    actual = path |> File.read!() |> Jason.decode!() |> Map.get("bridge_protocol_version")
    unless actual == canonical, do: {path, "bridge_protocol_version", actual}
  end

  defp format_drift_message(canonical, failures) do
    surface_lines = Enum.map_join(failures, "\n", fn {path, field, actual} ->
      "  [FAIL] #{path}\n         #{field}: #{inspect(actual)}  <- should be #{inspect(canonical)}"
    end)

    """
    \n  ✖  Contract drift detected — bridge_protocol_version disagrees across surfaces.

         Canonical source: Crosswake.Bridge.Contract.version/0 = #{inspect(canonical)}
                           (lib/crosswake/bridge/contract.ex, @version attribute)

         Drifted surfaces:
    #{surface_lines}

         FIX: Run `mix crosswake.gen.fixtures` to regenerate all derived surfaces
              from canonical contract truth, then commit the changes.

              Or if the canonical source is wrong, update only
              lib/crosswake/bridge/contract.ex @version and re-run mix test.

         See guides/compatibility.md for the bridge_protocol_version bump runbook.
    """
  end
end
```

---

## False-Positive / Flakiness Risk

A guard that fires on a clean repo gets skipped or disabled within one milestone. Flakiness is the death of merge-blocking guards.

**Risk analysis:**

| Guard | Flakiness risk | Mitigation |
|-------|---------------|------------|
| `Contract.version/0` vs runtime `Types.new_compatibility()` | Zero — both are compiled module attributes | None needed |
| JSON parse of fixture files | Near-zero — files are committed and deterministic | Assert file exists first (exit code 1 if missing, anti-rename evasion) |
| Text scan of Elixir source for version literal | Low-medium — regex sensitive to whitespace | Assert runtime value instead of source text |
| Text scan of docs for version | Low — narrow, stable section | Use a precise regex; test the scanner on a known-good synthetic file first |
| ExUnit conformance vectors | Near-zero — pure function over committed JSON | Ensure vectors directory is non-empty (anti-delete evasion guard) |
| `git diff --exit-code` after `mix crosswake.gen.fixtures` | Zero if generator deterministic | Add a determinism check: run generator twice, assert no diff between runs |

**Generator determinism** is the only meaningful risk in the generate-and-diff component. Mitigate by:
- Sorting all maps and lists before JSON serialization.
- Omitting `generated_at` from generated artifacts, or using a fixed sentinel value.
- Adding a CI step: run generator twice consecutively, assert no diff. This catches non-determinism before it reaches production CI.

---

## Composing with the Existing Guard Family

Crosswake's existing merge-blocking guard family:
1. **`brand-structural`** — Node.js script scanning CSS/HEEX files for hex color literals and Tailwind utilities. Required status check, branch-protection registered.
2. **`merge-blocking-offline-sync-e2e`** — aggregator job collecting `guard-01-e2e-honesty`, `guard-02-prod-route-absence`, and the E2E Playwright lane.
3. **`generator_coordinate_parity`** — readiness check verifying generated shell native dep coordinates are resolvable.
4. Phase-permanent proof lanes: `merge-blocking-threadline-docs-contract-proof`, `merge-blocking-closeout-proof`, etc.

The pattern for adding a new guard is established:
1. Create a dedicated workflow YAML with a named aggregator job.
2. Aggregator `needs:` all sub-jobs; aggregator is the ONLY required status check in branch protection.
3. Run on `push` and `pull_request`. No path filtering (path filtering causes "Expected — Waiting for status" deadlock on out-of-path PRs).
4. Register the aggregator check name in branch protection after first green on main (one-time manual step, harness-blocked).

**Proposed new guard: `merge-blocking-contract-drift`**

```yaml
# .github/workflows/contract-drift-gate.yml
name: Contract Drift Gate

permissions:
  contents: read

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

jobs:
  contract-drift-exunit:
    name: contract-drift-exunit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@...
        with:
          version-file: .tool-versions
          version-type: strict
      - uses: actions/cache@v4
        with:
          path: _build/test
          key: build-test-${{ hashFiles('mix.lock') }}
      - run: mix deps.get
      - run: mix test test/crosswake/contract/

  contract-drift-fixtures-check:
    name: contract-drift-fixtures-check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@...
        with:
          version-file: .tool-versions
          version-type: strict
      - run: mix deps.get
      - name: Regenerate fixtures and check for uncommitted drift
        run: |
          mix crosswake.gen.fixtures
          git diff --exit-code -- \
            examples/ios_shell_host/Fixtures/ \
            examples/android_shell_host/app/src/main/assets/ \
            test/fixtures/contract/ \
          || (printf '\n  ✖  FIXTURE DRIFT\n\n' &&
              printf '  Committed fixtures disagree with canonical contract.\n\n' &&
              printf '  Canonical source: lib/crosswake/bridge/contract.ex @version\n\n' &&
              printf '  FIX: Run  mix crosswake.gen.fixtures  then commit.\n\n' &&
              false)

  merge-blocking-contract-drift:
    name: merge-blocking-contract-drift
    runs-on: ubuntu-latest
    needs: [contract-drift-exunit, contract-drift-fixtures-check]
    if: always()
    steps:
      - name: Aggregate
        run: |
          if [[ "${{ needs.contract-drift-exunit.result }}" != "success" ||
                "${{ needs.contract-drift-fixtures-check.result }}" != "success" ]]; then
            echo "One or more contract-drift checks failed."
            exit 1
          fi
          echo "All contract-drift checks passed."
```

The advisory native lane goes in a separate workflow file:

```yaml
# .github/workflows/native-contract-conformance-advisory.yml
name: Native Contract Conformance (Advisory)

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

jobs:
  ios-contract-vectors:
    name: ios-contract-vectors
    runs-on: macos-latest
    continue-on-error: true    # ADVISORY — requires Xcode, never blocks merge
    steps:
      - uses: actions/checkout@v4
      - name: Run Swift conformance vector tests
        working-directory: packages/crosswake-shell-core-ios
        run: swift test --filter ConformanceVectorTests

  android-contract-vectors:
    name: android-contract-vectors
    runs-on: ubuntu-latest
    continue-on-error: true    # ADVISORY — requires JVM/Gradle, never blocks merge
    steps:
      - uses: actions/checkout@v4
      - name: Run Android conformance vector tests
        working-directory: packages/crosswake-shell-core-android
        run: ./gradlew test --tests "*.ConformanceVectorTest"
```

---

## Recommendation: The Guard Topology for v14.0

The recommendation is a three-layer topology. Each layer adds a distinct assurance that the others do not provide.

### Layer 1: Single-Reader Assertion Test (Merge-Blocking Core)

**File:** `test/crosswake/contract/drift_guard_test.exs`
**Mechanism:** ExUnit reads canonical value from `Crosswake.Bridge.Contract.version/0` and asserts against all derived surfaces using runtime values (not source text scans) for Elixir surfaces and `Jason.decode!/1` for JSON fixtures.

**Surfaces checked:**
- `Types.new_compatibility().bridge_protocol_version` (runtime value, refactoring-safe)
- `Crosswake.Shell.Fixtures` activation fixture `bridge_protocol_version` value
- JSON parse of `examples/ios_shell_host/Fixtures/route_activation.json["bridge_protocol_version"]`
- JSON parse of `examples/android_shell_host/app/src/main/assets/route_activation.json["bridge_protocol_version"]`
- `Crosswake.Bridge.Contract.protocol/0` matches the `"protocol"` field in the same fixture files
- JSON parse of each vector in `test/fixtures/contract/vectors/` for version field consistency

**Why this is primary:** It is the cheapest, most hermetic, most direct mechanism. Zero new infrastructure. The failure message is designed to name every drifted surface, the canonical source, and the fix command. It is consistent with the existing house pattern used by `phase96_threadline_docs_contract_test.exs`, `quick_start_adoption_drift_test.exs`, and `closeout_ci_parity_test.exs`.

### Layer 2: Generate-and-Diff Fixture Gate (Merge-Blocking Structural)

**Mix task:** `mix crosswake.gen.fixtures`
**CI step:** Run generator, then `git diff --exit-code` on fixture directories.
**Scope:** Generates only the JSON fixture files (`examples/ios_shell_host/Fixtures/`, `examples/android_shell_host/.../assets/`, `test/fixtures/contract/vectors/protocol_version_field.json`). Does NOT attempt to generate Swift/Kotlin source.

**Why both Layer 1 AND Layer 2:** Layer 1 catches the drift in the standard `mix test` run with a precise, human-readable failure message. Layer 2 catches any drift that a contributor introduced by hand-editing fixtures without updating the contract, and cannot be bypassed by commenting out a test assertion. They are complementary, not redundant.

### Layer 3: Conformance Vectors (Cross-Language Behavioral Proof)

**Directory:** `test/fixtures/contract/vectors/`
**Elixir test:** `test/crosswake/contract/conformance_vector_test.exs` — one test per committed vector file.
**Native tests (advisory):** iOS `ConformanceVectorTests.swift` and Android `ConformanceVectorTest.kt` load the same files.

**Minimum initial vector set:**
1. `bridge_v1.1.0_haptics_accept.json` — valid request with canonical protocol version, expect `accepted: true`
2. `bridge_version_mismatch_deny.json` — request with wrong protocol version, expect `accepted: false, denial_reason: "compatibility_mismatch"`
3. `bridge_unknown_command_deny.json` — request with unsupported command, expect `accepted: false`
4. `bridge_origin_denied_deny.json` — request with unallowlisted origin, expect `accepted: false`

**Why vectors are worth committing even if native CI is advisory:** The Elixir-side evaluation proves the Elixir contract code is self-consistent. The native-side evaluation proves cross-language implementations agree. The vectors also serve as executable documentation — anyone reading `bridge_version_mismatch_deny.json` understands exactly what `compatibility_mismatch` means without reading code.

### CI Workflow Structure

```
contract-drift-gate.yml                     (merge-blocking)
├── contract-drift-exunit                   mix test test/crosswake/contract/
├── contract-drift-fixtures-check           mix crosswake.gen.fixtures && git diff --exit-code
└── merge-blocking-contract-drift           aggregator (REGISTERED in branch protection)

native-contract-conformance-advisory.yml    (advisory, continue-on-error: true)
├── ios-contract-vectors                    swift test --filter ConformanceVectorTests
└── android-contract-vectors                ./gradlew test --tests "*.ConformanceVectorTest"
```

### Artifact Inventory

| Artifact | Path |
|----------|------|
| ExUnit drift guard | `test/crosswake/contract/drift_guard_test.exs` |
| ExUnit conformance vectors | `test/crosswake/contract/conformance_vector_test.exs` |
| Vector fixtures | `test/fixtures/contract/vectors/*.json` |
| Mix generator task | `lib/mix/tasks/crosswake.gen.fixtures.ex` |
| CI workflow (merge-blocking) | `.github/workflows/contract-drift-gate.yml` |
| CI workflow (advisory) | `.github/workflows/native-contract-conformance-advisory.yml` |
| Aggregator check name | `merge-blocking-contract-drift` |

### What Does NOT Need to Be Built

- Do not generate Swift/Kotlin source from Elixir. The native packages read version from the JSON manifest; no hardcoded native constant currently needs updating.
- Do not implement Pact. The single-team in-repo topology makes it overkill.
- Do not try to parse Swift AST from Elixir CI. Native behavioral proof happens in advisory native CI.
- Do not path-filter `contract-drift-gate.yml`. Path filtering creates the "Expected — Waiting for status" deadlock.
- Do not scan Elixir source files via regex for `@bridge_protocol_version` text. Call the runtime accessor instead.

---

## Lessons from Real Projects: What to Copy vs. What to Avoid

### Copy

- **`go generate` + `git diff --exit-code`**: The simplest, most trustworthy anti-drift mechanism. The critical property is generator determinism — enforce it with a two-run idempotency check.
- **`buf breaking` failure UX**: Violations surface at the exact line and file where the breaking change was introduced, with a clear rule name. Name the surface, the field, the actual value, the expected value, and the fix command.
- **JSON Schema Test Suite structure**: A flat directory of JSON fixture files with `description`, `input`, and `expected` fields. Language-agnostic, human-readable, versionable. Copy verbatim for Crosswake's conformance vectors.
- **CommonMark's "spec is the test"**: The fixture files ARE the contract document. Anyone reading `bridge_v1.1.0_haptics_accept.json` understands what the bridge contract means without reading code.
- **`mix format --check-formatted` discipline**: `mix crosswake.gen.fixtures && git diff --exit-code` is the same pattern — a canonical emitter run in CI that fails if committed state disagrees with the tool's output.
- **Crosswake's own `check-e2e-honesty.mjs` failure message**: Leads with human-readable violation description, names file and line, explains WHY it is banned, gives the correct alternative. Same pattern for ExUnit drift failure messages.
- **Crosswake's `brand-structural` vs `brand-visual` split**: Deterministic checks are merge-blocking; environment-sensitive checks are advisory. Apply identically: Elixir + JSON parse checks block; native Swift/Kotlin test runs are advisory.
- **Crosswake's aggregator topology**: One named aggregator job (`needs:` all sub-jobs, `if: always()`) is the single required status check. Sub-jobs produce visible signal without being individually required.

### Avoid

- **Regex-scanning Elixir source files for module attributes.** Reformatting the file, adding a comment, or wrapping the value in a string interpolation all break the regex without changing behavior. Assert runtime values (`Crosswake.Bridge.Contract.version/0`) instead.
- **Timestamp or non-deterministic content in generated artifacts.** One timestamp field in a generated JSON makes the generate-and-diff check fail on every CI run. Remove all non-deterministic fields, or use a fixed sentinel.
- **Making native CI merge-blocking before it is reliable.** `swift test` on macOS runners is slower and more environment-sensitive than Elixir on Linux. Advisory-first, promote to blocking only after demonstrated reliability.
- **Publishing "what the contract means" as English prose separate from executable fixtures.** Keep the conformance vectors as the executable spec; keep the prose in `guides/compatibility.md` as navigation to the vectors.
- **Path filtering on the merge-blocking workflow.** The existing CI comments document the "Expected — Waiting for status" deadlock this creates for non-matching PRs. Run on all pushes/PRs, no path filter.
- **Pact.** The "pending pacts" and "WIP pacts" features are legitimate for multi-team coordination. For Crosswake, they would allow the guard to enter a "pending" state that hides a real contract mismatch.

---

## Sources

- [Protocol Buffers conformance tests — protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf/blob/main/conformance/README.md)
- [bufbuild/protobuf-conformance — running Protobuf conformance tests against various libraries](https://github.com/bufbuild/protobuf-conformance)
- [Detecting breaking changes — Buf Docs](https://buf.build/docs/breaking/)
- [Rules and categories — Buf Docs](https://buf.build/docs/breaking/rules/)
- [How to detect breaking changes and lint Protobuf automatically using Gitlab CI and Buf](https://mionskowski.pl/posts/ci-pipeline-for-protobuf/)
- [JSON Schema Test Suite — json-schema-org/JSON-Schema-Test-Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
- [CommonMark spec with reference implementations — commonmark/commonmark-spec](https://github.com/commonmark/commonmark-spec)
- [Unicode / CLDR Data Driven Testing — unicode-org/conformance](https://github.com/unicode-org/conformance)
- [Prisma migration drift detection](https://medium.com/@sivasaravanan101004/prisma-migration-drift-the-silent-schema-killer-and-how-to-stop-it-076a5d756b1a)
- [cargo-semver-checks — crates.io](https://crates.io/crates/cargo-semver-checks)
- [SemVer in Rust: Tooling, Breakage, and Edge Cases — FOSDEM 2024](https://predr.ag/blog/semver-in-rust-tooling-breakage-and-edge-cases/)
- [When to use Pact — Pact Docs](https://docs.pact.io/getting_started/what_is_pact_good_for)
- [Pact FAQ](https://docs.pact.io/faq)
- [go generate + git diff discipline discussion — golangci-lint](https://github.com/golangci/golangci-lint/issues/20)
- [templ: should generated files be committed — a-h/templ](https://github.com/a-h/templ/discussions/419)
- [mix format --check-formatted](https://hexdocs.pm/mix/Mix.Tasks.Format.html)
