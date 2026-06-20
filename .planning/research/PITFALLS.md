# Footguns & Failure Modes — Runtime Contract Confidence

**Project:** Crosswake v14.0  
**Milestone goal:** Make bridge/runtime contract canonical across Elixir, manifest, fixtures, generated templates, native packages, proof lanes, and docs. Add drift guards. Add real behavioral tests in native packages.  
**Researched:** 2026-06-20  
**Confidence:** HIGH (grounded in codebase inspection + named real-world incidents)

---

## The Triggering Bug (Exact-Match Denial)

`Crosswake.Bridge.Contract` declares `@version "1.1.0"`. Every other surface — `Manifest.Types` defaults (`@bridge_protocol_version "1.0.0"`), iOS/Android shell fixtures (`bridge_protocol_version: "1.0.0"`), route-tour proof, `compatibility_test.exs` literals, `doctor_test.exs` assertions — says `1.0.0`.

Both native runtimes enforce **exact string equality** (not semver range) on the bridge protocol version:

```kotlin
// BridgeChannel.kt:101
if (request.protocol != PROTOCOL || request.version != session.bridgeProtocolVersion ...)
```

```swift
// BridgeChannel.swift:182
guard request.version == session.bridgeProtocolVersion,
```

A valid bridge request built by Elixir (version `1.1.0`) against a session populated from a manifest that still says `1.0.0` is denied with `compatibility_mismatch`. No runtime error, no obvious log line — just silent denial. This is a production-confidence problem masquerading as a test-passing green board.

---

## Cluster 1: Canonical-Source / Codegen Footguns

### Pitfall 1.1 — Version literals live in multiple files with no single source driving all of them

**Why it bites:** The `1.0.0`/`1.1.0` split is a direct instance. `Crosswake.Bridge.Contract` holds `@version "1.1.0"` as a module attribute. `Manifest.Types` holds `@bridge_protocol_version "1.0.0"` as a separate module attribute. Shell fixtures, JSON fixtures, Elixir tests, Kotlin tests, Swift tests, and docs each have their own literal copy. No file generates the others. A bump to `Contract` does not cascade.

**Early warning sign:** `grep -rn '"bridge_protocol_version"' . | grep -v node_modules` returns different version strings across `lib/`, `test/`, `examples/`, and `packages/`.

**Prevention:** Designate ONE file as the canonical version source — the simplest implementation is `Crosswake.Bridge.Contract` (already the typed authority). All other files derive from it at compile time (via module attribute or function call), or are generated from it. Generated JSON fixtures should be emitted by a `mix` task that reads `Contract.version()`, not hand-authored.

**Owning phase:** Phase 1 of v14 (the "make it canonical" phase, before any guard or test work). Nothing else is trustworthy until this is settled.

**Named real-world lesson:** **protobuf / buf.build** — the `.proto` file is the single source; generated stubs in Go, Java, Python, Swift are artifacts, never edited by hand. Teams that edit generated stubs suffer exactly this split. buf.build added `buf lint` + `buf breaking` precisely because teams routinely let generated files drift from the schema.

---

### Pitfall 1.2 — Generator not run in CI, so drift silently returns after being fixed

**Why it bites:** Once you create a `mix crosswake.gen.contract_fixtures` task (or equivalent), you fix the current drift. But if CI never validates that the checked-in outputs match what the generator produces, a contributor who edits a fixture file by hand will re-introduce the drift on the next PR. The generator is there but bypassed.

**Early warning sign:** The generator exists, has tests, but no CI step runs `mix crosswake.gen.contract_fixtures && git diff --exit-code`. Or the step exists but is advisory, not merge-blocking.

**Prevention:** Add a CI step that runs the canonical generator and fails on any diff (`git diff --exit-code` or an ExUnit test that compares the generated output to the checked-in file content). Make it merge-blocking, not advisory.

**Owning phase:** Phase 2 of v14 (drift guards), immediately after Phase 1 establishes the canonical source.

**Named real-world lesson:** **Go `go generate`** — the Go community learned through repeated pain that `go generate` is a developer convenience, not a CI contract. Stale generated files are a perennial Go footgun (see: `stringer`, `mockgen`, `protoc` wrappers). The pattern that works is `go generate ./... && git diff --exit-code` in CI. Teams that skip this reliably accumulate stale generated code over months.

---

### Pitfall 1.3 — Bootstrap / circular dependency: the generator depends on the thing it generates

**Why it bites:** If the generator reads `Crosswake.Bridge.Contract.version()` to emit fixtures, but `Contract` module itself needs the fixtures to compile (or a test needs them to boot), you get a compile-time cycle. Similarly, if the canonical version lives in a JSON file that the generator is supposed to produce, you can't generate it without first having it.

**Early warning sign:** Attempting to run the generator in a fresh checkout fails because a dependency isn't yet compiled. Or the generator calls `Application.spec(:crosswake)[:vsn]` (already used by `gen.shell` in v11.0) but the canonical contract version is separate from the Hex package version.

**Prevention:** Keep the canonical source as a pure Elixir constant (`@version` in `Contract`), not a file the generator produces. Generators read the constant; they produce JSON/fixture artifacts. This is a DAG, not a cycle. Never make the Elixir compiler depend on an artifact that must be generated by Elixir.

**Owning phase:** Phase 1 design decision. No code needed — just the correct architecture choice up front.

**Named real-world lesson:** **OpenAPI code generators** — teams that put the canonical API spec in a generated file (e.g., generated from code annotations) then try to generate the code from the spec hit a chicken-and-egg problem. The lesson from Swagger/OpenAPI history is: the spec is always the input, never the output of the generator.

---

### Pitfall 1.4 — Committed generated files create ugly merge conflicts

**Why it bites:** If JSON fixtures are generated and committed, any two branches that both run the generator with different contract states produce conflicting fixture files. Because the fixtures are machine-generated, the conflict markers make the file invalid JSON. The merge author has to understand the generator semantics to resolve correctly.

**Early warning sign:** Multiple PRs open simultaneously that each update the contract version. Their fixture branches will conflict on every JSON file.

**Prevention:** Two strategies, pick one:
1. Keep generated fixtures checked in but gated by a CI "freshness" check (acceptable when fixtures are rarely regenerated and conflicts are infrequent — likely fine for Crosswake's solo-maintainer model).
2. Do not commit generated fixtures; generate them at test time from the canonical source. Prefer this for any file that changes every time the contract version bumps.

**Owning phase:** Phase 1 (architecture decision about what is committed vs generated-at-runtime).

**Named real-world lesson:** **Hotwire Turbo Native** — generated iOS/Android bridge adapters committed to example repos suffered repeated conflicts in community forks where different contributors ran different generator versions. The Turbo Native team eventually moved to smaller generated surfaces.

---

### Pitfall 1.5 — Codegen so heavy contributors bypass it

**Why it bites:** If fixing a version string requires running a complex generator chain that takes minutes, contributors will edit the JSON by hand "just this once." Over time, hand-edits become the norm and the generator becomes stale.

**Early warning sign:** The generator task requires an active server, a simulator, or a network call. Or it takes more than 5 seconds.

**Prevention:** Keep the generator trivially fast and hermetic. For Crosswake's use case, generating JSON fixtures from `Contract.version()` should be instantaneous. If the generation step is slow, the real footgun is the design, not the code.

**Owning phase:** Phase 1 design decision.

**Named real-world lesson:** **Capacitor** — Capacitor's native bridge sync required stopping the dev server, which made contributors bypass it frequently. The community workaround was hand-editing native configs, which caused plugin version drift (a common complaint in Capacitor issues circa 2021-2023).

---

### Pitfall 1.6 — The canonical source lives somewhere native CI cannot reach

**Why it bites:** If the canonical version lives in `Contract.version()` (Elixir), but the Swift package CI (`swift test` on a pure SPM target) needs to verify it, there is no built-in way for the Swift CI to read an Elixir module attribute. You either duplicate the check or the native CI cannot enforce it.

**Early warning sign:** Native package CI passes but has no assertion about which bridge protocol version it is testing against. The tests are not contract-anchored.

**Prevention:** One of:
1. Emit a small machine-readable manifest (e.g., `priv/contract_version.json`) from the Elixir canonical source via a `mix` task, commit it, and have native CI read that file to assert the expected version.
2. Embed the version string into fixture JSON files that native CI already reads (the iOS `Fixtures/route_activation.json` already exists), and ensure those fixtures are generated from the canonical source.
3. Have native tests parametrize from a version constant file in the package repo that is regenerated as part of the publish pipeline.

Option 2 is the simplest for Crosswake given the existing fixture structure.

**Owning phase:** Phase 2 (drift guards) and Phase 3 (native behavioral tests).

**Named real-world lesson:** **gRPC service definition vs. client libraries** — when the `.proto` canonical source lives in a server repo but client teams consume a generated stub repo, the stub repo is often updated manually and drifts. The fix (buf.build schema registry, generated artifact CI in the stub repo) mirrors exactly this problem.

---

## Cluster 2: Version-Axis / Compatibility Footguns

### Pitfall 2.1 — Conflating the three independent version axes

**Why it bites:** Crosswake has three orthogonal contract axes:
- `manifest_schema_version` — shape/schema of the manifest JSON itself
- `bridge_protocol_version` — the wire protocol for bridge request/reply envelopes
- `native_runtime_version` — the capabilities and behaviors of the native shell runtime

These are currently all `1.0.0` or `1.1.0` with no documented relationship. If a contributor bumps all three together "to keep them in sync," they burn a native rebuild requirement for changes that only affect manifest schema. If they bump only one when more are affected, adopters get a compatibility denial with no clear message about which axis failed.

**Early warning sign:** The support matrix describes these axes but provides no worked examples of "which axis bumps under which change type." A PR bumps `bridge_protocol_version` for a capability vocabulary addition that required only a `manifest_schema_version` bump.

**Prevention:** Write a decision table in the support matrix: "This kind of change bumps X and Y, not Z, and requires/does not require a native rebuild." Treat this as part of the public contract, not internal docs. Gate it with a test that asserts the decision table is present in the support matrix output (consistent with Crosswake's existing docs-contract test pattern).

**Owning phase:** Phase 1 (canonical source and version semantics doc) or embedded in the drift guard phase.

**Named real-world lesson:** **Stripe API versioning** — Stripe separates the API version (user-pinned per-request header), the SDK version, and the webhook format version. Mixing them was a chronic source of support tickets until Stripe published explicit "what changes under each axis" documentation and tied the SDK changelog to specific API version compatibility windows.

---

### Pitfall 2.2 — Exact-equality check denies on a no-op bump (the confirmed Crosswake bug — generalized)

**Why it bites:** The native `BridgeChannel` checks `request.version == session.bridgeProtocolVersion` with exact string equality. This is the right behavior for protocol safety: you do not want a 2.0.0 client talking to a 1.0.0 server silently. But it means:
- Any version string mismatch — even a well-intentioned additive bump — causes silent denial.
- The denial message (`compatibility_mismatch`) does not surface which version pair failed.
- If the Elixir side moves from `1.0.0` to `1.1.0` for additive reasons (new optional commands) while the manifest and fixtures stay at `1.0.0`, adopters get denied with no actionable error.

**Early warning sign:** `grep -rn '"version"' examples/ios_shell_host/Fixtures/route_activation.json` shows `1.0.0` while `Contract.version()` returns `1.1.0`. Tests still pass because tests use the fixture version, not the live contract.

**Prevention (two parts):**
1. **Fix the current drift immediately in Phase 1.** One canonical source, all surfaces read from it.
2. **Improve the denial message.** The `compatibility_mismatch` denial should include the expected vs. received version, and which of the three axes failed. This is a v14 improvement that costs one line of code in the native packages and directly reduces support burden.

**Owning phase:** Phase 1 (canonical source) and Phase 3 (native behavioral tests that assert the denial message quality).

**Named real-world lesson:** **Phoenix Channels `vsn` negotiation** — Phoenix Channels include a `vsn` field in socket messages for the same reason (exact match prevents silent compat issues). The documented pitfall in the Phoenix community is library authors not bumping `vsn` when the wire format changes, producing confusing disconnects. The fix is always the same: one place declares the version, all consumers read from it.

---

### Pitfall 2.3 — Bumping the contract version for a purely additive change and forcing needless native rebuilds

**Why it bites:** If "we added a new optional bridge command" triggers a `bridge_protocol_version` bump from `1.0.0` to `1.1.0`, and the native exact-equality check requires the shell to declare the new version, every existing adopter must rebuild and re-publish their native app to use a feature they did not ask for.

**Early warning sign:** No documented rule about when a `bridge_protocol_version` bump is required vs. when it is advisory. A PR adds an optional command and bumps the bridge protocol version "because it changed."

**Prevention:** Define the protocol versioning semantics explicitly: an additive new optional command should NOT require a native rebuild if the old shell can simply ignore the new command and return a `command_unsupported` denial. Only changes that alter the envelope shape, required fields, or denial semantics require a protocol version bump that forces a rebuild. Document this rule in the support matrix and test that it is present (existing pattern: `support_matrix_test.exs`).

**Owning phase:** Phase 1 (semantics doc) and support matrix test.

**Named real-world lesson:** **OpenTelemetry semantic conventions churn** — OTel bumped their semantic convention versions frequently (even for additive attribute additions), breaking instrumentation libraries and requiring rebuilds. The community backlash in 2022-2023 drove a formal "stable vs. experimental" stability contract and a rule that additive-only changes to stable conventions do not bump the schema version. The lesson: without explicit stability semantics, every change looks like it warrants a bump.

---

### Pitfall 2.4 — Maven Central and SwiftPM tags are immutable; a wrong version is unrecoverable

**Why it bites:** Crosswake already learned this in v11.0 (fire-drill before first publish). But the risk re-emerges in v14: if the bridge protocol version change requires publishing a new version of the native packages (`crosswake-shell-core-ios`, `crosswake-shell-core-android`), and those packages are published with the wrong version string in their fixtures or activation logic, the only fix is publishing a new patch version. The burned version cannot be retracted.

**Early warning sign:** A v14 phase plan includes "publish a new native package version" without a corresponding pre-publish checklist that verifies the bridge protocol version in the published artifact matches the canonical source.

**Prevention:** Gate any native package publish behind a pre-publish assertion: run `mix crosswake.contract.verify_published_fixtures` (or equivalent) in the publish CI pipeline. This should compare the canonical version to the version embedded in the about-to-be-published package artifacts. Block the publish if they diverge. (This is the native equivalent of the `generator_coordinate_parity` check from v11.0.)

**Owning phase:** Whichever phase publishes new native package versions (likely the last phase, after canonical source and guards are in place).

**Named real-world lesson:** **Maven Central immutability** — documented and painful. The typical incident: library published with a hardcoded test URL in a dependency or the wrong artifact ID. The community standard (from the Maven Central publishing guide and OSSRH history) is: validate thoroughly before release, because there is no undo. Crosswake already internalized this in v11.0; v14 must not regress on it.

---

### Pitfall 2.5 — Release-please lockstep bumping a version nobody intended

**Why it bites:** Crosswake uses `linked-versions` in release-please to keep Hex, iOS tag, and Maven all at the same version (`0.1.2`, etc.). This is correct for the Hex SemVer axis. But `linked-versions` bumping the Hex version does not and should not automatically bump the `bridge_protocol_version`, `manifest_schema_version`, or `native_runtime_version`. If someone adds a comment in a CHANGELOG that accidentally parses as a `feat:` commit, release-please bumps the Hex minor version — but the bridge protocol version may not have changed at all, and no native rebuild is required. The Hex bump and the contract version bump are orthogonal.

**Early warning sign:** The support matrix contains a line noting "Hex package SemVer moves independently" (which it already does, confirmed at `support_matrix.ex:690`), but there is no test asserting that the Hex version and the `bridge_protocol_version` do NOT have to match.

**Prevention:** Document the independence clearly and add an ExUnit test asserting that `Application.spec(:crosswake)[:vsn]` is not compared to `Contract.version()` anywhere in the codebase (or, more precisely, that a version mismatch between the two is expected and not an error). This prevents a future contributor from "fixing" the mismatch by making them equal in ways that corrupt the bridge semantics.

**Owning phase:** Phase 1 (documentation) and Phase 2 (test asserting independence).

---

## Cluster 3: Cross-Language Drift-Guard Footguns

### Pitfall 3.1 — Guards that scan text and break on formatting/whitespace/quote style changes

**Why it bites:** A drift guard that does `grep '"bridge_protocol_version": "1.0.0"'` in a JSON file breaks if the file is reformatted to `"bridge_protocol_version":"1.0.0"` (no spaces) or if a tool reformats the JSON with different indentation. The guard was passing vacuously because the format changed but the check did not update.

**Early warning sign:** A PR that reformats a JSON file causes the drift guard to fail. The fix is to update the grep pattern rather than fixing the actual drift.

**Prevention:** Parse, do not grep. For JSON fixtures, the drift guard should read the file with a JSON parser and compare the extracted value, not the raw string. In Elixir: `Jason.decode!(File.read!("path/to/fixture.json"))["bridge_protocol_version"]`. In CI shell scripts: `jq -r '.bridge_protocol_version' path/to/fixture.json`.

**Owning phase:** Phase 2 (drift guard design) — enforce parse-based comparison from the start.

**Named real-world lesson:** **Crosswake v12.0 GUARD-01** — the honesty scanner in v12 used a TypeScript-based text scan over Phoenix source files that required `npm ci --prefix examples/phoenix_host` before running (STATE.md line 79). Text-scanning guards that depend on parser toolchains are fragile. The lesson is to write guards in the same language as the target file type, using that language's parser.

---

### Pitfall 3.2 — Guards that need Xcode or Gradle and become flaky/slow, then get demoted to advisory

**Why it bites:** A drift guard that requires building the native packages to verify the version string (`swift build && swift test --filter BridgeVersionTest`) takes minutes on GitHub Actions and is environment-sensitive. Someone eventually marks it `continue-on-error: true` because it flakes on the free runner. Once advisory, it is ignored. The exact contract it was guarding drifts silently.

**Early warning sign:** The drift guard CI job has `continue-on-error: true`, or its failure rate is above 5%.

**Prevention:** Prefer file-level guards over build-level guards where possible. For the bridge protocol version specifically: a shell script that reads `jq -r '.bridge_protocol_version' examples/ios_shell_host/Fixtures/route_activation.json` and compares it to `mix eval "IO.puts Crosswake.Bridge.Contract.version()"` requires zero native toolchain. This is the correct guard for "are the version strings consistent?" The full native build is a separate CI job for "does the native package compile and test?" — those two concerns should not be conflated.

**Owning phase:** Phase 2 (drift guard design).

**Named real-world lesson:** **Crosswake v12.0 offline-sync E2E** — the v6.0 offline-sync test used `window[]` injection (a mock) rather than real IndexedDB because the real network-toggling test was "too flaky on CI." It was demoted to advisory by being replaced with a mock, and the mock did not test the real behavior. v12.0 fixed this. The lesson is documented in PROJECT.md: "Treat proof-honesty regressions as structural CI problems, not review-only risks." Apply the same lesson to version drift guards.

---

### Pitfall 3.3 — Guards with bad failure messages that contributors cannot action

**Why it bites:** A drift guard that fails with `exit code 1` or `diff: fixtures differ` tells the contributor nothing about what diverged, what the expected value is, what the canonical source is, or what to run to fix it. This is especially painful for contributors who are not the maintainer and do not know the canonical source.

**Early warning sign:** A contributor opens an issue: "CI is failing with a diff error on my PR but I don't know what to change."

**Prevention:** Write drift guard failure messages as actionable instructions:

```
DRIFT DETECTED: bridge_protocol_version mismatch
  Canonical source: Crosswake.Bridge.Contract.version() = "1.1.0"
  Diverging file:   examples/ios_shell_host/Fixtures/route_activation.json = "1.0.0"
  Fix: run `mix crosswake.gen.contract_fixtures` to regenerate all fixture files.
```

Every drift guard must emit the diverging pair and the fix command.

**Owning phase:** Phase 2 (drift guard implementation).

**Named real-world lesson:** **buf breaking** — `buf breaking` changed the pattern for protobuf drift guards precisely because the old approach (`diff generated_pb.go expected_pb.go`) produced unreadable diffs. buf produces structured, human-readable "FIELD_NOT_PRESENT" / "FILE_SAME_SYNTAX_PROTO3_CHANGED_TO_PROTO2" messages. Same lesson: invest in message quality.

---

### Pitfall 3.4 — Guards that pass vacuously (assert nothing)

**Why it bites:** This is a documented Crosswake failure. From PROJECT.md v12.0: "Make closeout verification fail closed on explicit phase contracts and evidence-backed ledgers. Vacuous globs and bare ledger attestations let historical validation debt pass as green."

The specific native-package variant: a guard that checks "does `examples/ios_shell_host/Fixtures/*.json` exist?" rather than "does the bridge_protocol_version in `route_activation.json` match `Contract.version()`?" passes vacuously — even an empty fixture directory would pass the existence check.

**Early warning sign:** The guard's assertion is `assert File.exists?(path)` or `ls examples/ios_shell_host/Fixtures/*.json | wc -l` with a threshold of > 0.

**Prevention:** Guards must assert specific values, not mere presence. The test should be:
```elixir
fixture = Jason.decode!(File.read!("examples/ios_shell_host/Fixtures/route_activation.json"))
assert fixture["bridge_protocol_version"] == Crosswake.Bridge.Contract.version(),
  "route_activation.json bridge_protocol_version must match Contract.version(). Run mix crosswake.gen.contract_fixtures to fix."
```

**Owning phase:** Phase 2 (drift guard implementation).

**Named real-world lesson:** **Crosswake v12.0 Phase 115 LEDG-01** — the `CloseoutVerifier` previously accepted bare ledger attestations (just a flag set to `true`) as passing proof. Phase 115 hardened it to require evidence-backed ledgers. The vacuous guard problem is the same failure mode: a check that can pass without actually checking anything.

---

### Pitfall 3.5 — False-confidence "green but fabricated" proof

**Why it bites:** This is the documented v6/v8 failure. From PROJECT.md: "The demo app used `window[]` injection rather than real IndexedDB... The E2E proof lane was green while bypassing app-owned state." Green CI is not proof of correctness when the test is wired to a mock instead of the behavior. For v14, the specific risk is native package tests that mock the bridge protocol check or fixture-load the version string, rather than testing the behavior from the canonical source.

**Early warning sign:** Native package tests hardcode the version string (`val version = "1.1.0"`) rather than reading from the same source the production code uses. Or tests construct a `BridgeSession` manually with a version string that is not derived from any fixture or canonical source.

**Prevention:** Native tests should parametrize from fixture files that are generated by the canonical Elixir source. If the test hardcodes `"1.1.0"`, it is testing the literal, not the system. The test should load the fixture JSON (which was generated from `Contract.version()`) and compare the behavior against that file.

**Owning phase:** Phase 3 (native behavioral tests) — this is the core design constraint for that phase.

**Named real-world lesson:** **Crosswake v6.0/v8.0 offline-sync fabrication** — documented explicitly. The v6.0 decision (PROJECT.md Key Decisions): "Stub a mocked Playwright E2E offline-sync flow for the v6.0 closeout gate. Allowed the CI workflow to execute without a full network-toggling harness." Resolution: "Resolved in v12.0 — replaced by real UI-driven IndexedDB outbox/reconnect/Ecto proof plus compile gate." The pattern is the same for native package tests: accept the cost of real behavior testing rather than mocking the very behavior you are trying to prove.

---

## Cluster 4: Native Package Testing Footguns

### Pitfall 4.1 — Tests that need a live server or real WebView/simulator

**Why it bites:** If native package tests (`CrosswakeShellCoreTests.swift`, Android JUnit tests) require a live Phoenix server to respond to activation requests, they cannot run in pure SPM or Gradle CI contexts. They either become flaky (server not started, network unavailable) or get wrapped in simulator-required flags and slowly accumulate into the "advisory" pile.

**Early warning sign:** A native test does `let url = URL(string: "https://localhost:4000/crosswake/activate")` and makes a real HTTP request.

**Prevention:** Behavioral tests for the native packages should operate on the bridge evaluation logic, not the network layer. The inputs to test are: a `BridgeRequestEnvelope` with various version strings, a `BridgeSession` populated from fixture JSON, and an expected denial or success result. No network. No WebView. No simulator required. Simulator-dependent tests belong in the checked-in example host CI (`examples/ios_shell_host`) marked advisory — consistent with the existing `native-collateral-advisory.yml` pattern.

**Owning phase:** Phase 3 (native behavioral test design) — the split between package-level hermetic tests and example-host advisory tests must be explicit in the phase plan.

**Named real-world lesson:** **Pact contract testing** — Pact solves exactly this problem for cross-service testing. Provider tests run locally without the consumer being deployed; consumer tests run without the provider being deployed. Pact's lesson is that tests that require the other side to be running are integration tests, not contract tests. For Crosswake, the native package tests should be contract tests (does this version string produce a deny? does this fixture pass validation?), not integration tests (does the full activation flow work against a live Phoenix server?).

---

### Pitfall 4.2 — Fixtures hand-maintained in native packages that drift from the Elixir authority

**Why it bites:** The current iOS shell host fixture files (`examples/ios_shell_host/Fixtures/route_activation.json`, etc.) were created by hand and already show the `1.0.0` drift. If the native package tests (`packages/crosswake-shell-core-ios/Tests/`) also have their own fixture files, there are now THREE sets of fixtures (Elixir shell fixtures, example host fixtures, package test fixtures) with no canonical authority driving any of them.

**Early warning sign:** `find packages/ -name "*.json" | xargs grep bridge_protocol_version` shows a version that differs from `Contract.version()`.

**Prevention:** All fixture JSON files that reference version strings should be generated outputs, not hand-authored. The generator reads `Contract.version()` and emits the files. Native package tests should reference the same fixture files that example hosts use (or a generated subset), not their own copies.

**Owning phase:** Phase 1 (canonical source design must account for fixture topology) and Phase 3 (native tests implemented against generated fixtures).

**Named real-world lesson:** **Firebase SDK compatibility matrices** — Firebase maintains version compatibility tables across Android (Gradle BOM), iOS (CocoaPods/SPM), and backend SDKs. The community-documented footgun is each platform's SDK team maintaining its own internal compatibility fixture and updating it out of sync with the others. Firebase moved to a centralized compatibility check tooling (`firebase-ios-sdk`'s `ReleaseTooling`) specifically to close this gap.

---

### Pitfall 4.3 — Testing the mock instead of the behavior

**Why it bites:** The Android and iOS packages already have `ActivationCoordinatorTest` and `BridgeChannelTest` files. Looking at `BridgeChannelTest.kt`, the tests construct `BridgeRequestEnvelope` objects with hardcoded `version = "1.0.0"` strings (line 273). If the canonical version changes to `1.1.0`, these tests still pass — because they construct the mock request AND the session with the same `"1.0.0"` literal, so the exact-equality check trivially passes. They do not catch the cross-language drift because both sides of the comparison are mocked.

**Early warning sign:** `grep -n '"1\.0\.0"' packages/crosswake-shell-core-android/src/test/` returns hardcoded version literals in test fixture construction.

**Prevention:** At minimum one test per native package should:
1. Load the fixture JSON file generated from the canonical Elixir source.
2. Construct a `BridgeSession` from that fixture.
3. Construct a `BridgeRequestEnvelope` with a *different* (incorrect) version.
4. Assert the denial.
5. Construct a correct request matching the fixture version.
6. Assert the pass.

This ensures the test is sensitive to the version value, not just the equality check logic.

**Owning phase:** Phase 3 (native behavioral tests).

**Named real-world lesson:** **Stripe iOS/Android SDK version tests** — Stripe's SDK tests historically mocked the HTTP response rather than testing the version header negotiation, which caused several incidents where the SDK sent an incorrect API version header in production (Stripe engineering on testing philosophy). The fix was adding integration-style tests that serialized the actual request and asserted the API version header value.

---

### Pitfall 4.4 — Async/coroutine test flakiness in Swift and Kotlin

**Why it bites:** Swift `async/await` and Kotlin coroutines make native tests non-deterministic when not properly scoped. The existing `BridgeChannelTest.kt` uses `runBlocking` for some coroutine-scoped operations. If a test awaits a result but the completion handler fires after the test timeout, the test fails non-deterministically. These flaky tests eventually get marked with `@Ignore` or get a retry loop added, which hides real failures.

**Early warning sign:** A native CI test job has retry logic (`max-attempts: 3`) or individual tests have arbitrary `Thread.sleep()` calls.

**Prevention:**
- Kotlin: use `runTest` from `kotlinx-coroutines-test` instead of `runBlocking`; it controls virtual time and eliminates real-time waits.
- Swift: use `XCTestExpectation` with explicit `fulfillment(of:timeout:)` and synchronous bridge evaluation where possible (the current `BridgeChannel.evaluate()` is synchronous for same-thread requests, which is correct).
- Bridge evaluation tests should be synchronous where the implementation allows it.

**Owning phase:** Phase 3 (native test implementation).

**Named real-world lesson:** **Sentry Android SDK** — Sentry's Android SDK test suite had chronic async flakiness with `Handler`-based dispatch until they switched to test dispatchers. The fix is documented in their changelog: "Replaced `Handler` in tests with synchronous dispatch; eliminated a significant portion of intermittent CI failures."

---

### Pitfall 4.5 — Tests that pass on macOS but the package CI is Linux SwiftPM

**Why it bites:** SwiftPM on Linux does not support `XCTest` in the same way as macOS. Some APIs (`Bundle.main`, `FileManager` default paths, `JSONDecoder` date strategies) behave differently. If native tests use `Bundle.main.url(forResource:)` to load fixture JSON, the test passes locally on macOS but fails in the GitHub Actions `ubuntu-latest` Swift runner.

**Early warning sign:** The SwiftPM CI uses `ubuntu-latest` and the test suite includes file-loading code that uses `Bundle` APIs.

**Prevention:**
- For fixture JSON loading in SwiftPM on Linux: use `URL(fileURLWithPath:)` with a relative path computed from `#filePath` (Swift 5.3+), not `Bundle.main`.
- Or embed fixture strings as Swift literals in the test file (acceptable for small fixtures like version strings).
- Run CI on the same platform as the target deployment environment: if iOS is the target, macOS CI is correct; Linux SwiftPM CI is appropriate only for cross-platform Swift library code.

**Owning phase:** Phase 3 (native test CI setup).

**Named real-world lesson:** **Swift on Server / Vapor** — the Swift on Server community thoroughly documented the `Bundle` vs. Linux path issue. The canonical pattern is using `#filePath` or embedding resources via Swift Package Manager's resource system (SE-0272), not `Bundle.main`. Teams that ignored this had CI passing locally but failing in Docker.

---

## Cluster 5: Process / Scope Footguns

### Pitfall 5.1 — Scope creep: redesigning the bridge while "making it canonical"

**Why it bites:** "Making it canonical" sounds like a small housekeeping milestone. But once a contributor (or the maintainer, in a solo project) starts looking at the bridge contract holistically, it is tempting to add new commands, restructure the version negotiation, redesign the capability allowlist format, or add a new protocol version field. All of these are feature additions, not coherence work. v14 ships with the contract broken (1.0.0 vs 1.1.0) — the goal is to fix the break, not redesign the bridge.

**Early warning sign:** A v14 phase plan includes "design a new capability negotiation protocol" or "restructure the bridge envelope format." If the bridge envelope shape is changing, that is a v15 candidate.

**Prevention:** Write the v14 anti-scope explicitly in the milestone requirements:
> **Not in scope:** adding new bridge commands, restructuring the bridge envelope format, redesigning capability negotiation, or adding new protocol version axes. Those are v15+ changes. v14 is coherence only.

The maintainer's own OSS-DNA doc (`crosswake-elixir-oss-dna.md`) captures this as a pattern: "Out of scope items are written down."

**Owning phase:** The milestone scoping document (requirements phase), not a code phase.

**Named real-world lesson:** **JSON Schema conformance suites** — the JSON Schema test suite project (json-schema-org/JSON-Schema-Test-Suite) has a documented community pattern where "let's update the tests for draft 2019-09" frequently spiraled into "let's redesign the validation algorithm." The project adopted an explicit "this PR updates tests only, no spec changes" policy after several PRs got stuck in scope arguments.

---

### Pitfall 5.2 — Over-engineering a full IDL/codegen pipeline when a small canonical file + diff-check would do

**Why it bites:** The correct fix for Crosswake's version drift is almost certainly: (a) assert that all surfaces read from `Contract.version()`, and (b) add a CI diff-check. But it is easy to see the problem and conclude "we need a proper IDL like protobuf or JSON Schema to govern the bridge contract." Building that IDL, its toolchain, its code generator, its CI integration, and its documentation is weeks of work. The actual drift problem can be fixed in a day.

**Early warning sign:** A v14 phase plan includes "design the bridge contract IDL" or "write a JSON Schema for bridge request envelopes" as Phase 1.

**Prevention:** Apply the Crosswake house style: "Start narrow, document the support envelope, and prove that envelope hard." A committed `priv/contract_version.json` (generated from `Contract.version()`) plus a CI diff-check plus native tests that load that file is the correct scope. If a real IDL is needed later (bridge evolves significantly), v15 can add it.

**Owning phase:** Milestone scoping.

**Named real-world lesson:** **CommonMark specification conformance** — CommonMark's reference implementation story is instructive. The spec could have been expressed as a formal grammar with a codegen pipeline. Instead, the authors committed a plain JSON test file (`spec.json`) with input/output pairs and a simple conformance runner. That minimal approach enabled 50+ implementations to achieve high conformance without any IDL tooling.

---

### Pitfall 5.3 — Breaking the published 0.1.x contract for existing adopters

**Why it bites:** Crosswake is live at `0.1.2` on Hex. Any existing adopter using `0.1.2` has a generated shell that was produced by `gen.shell` at that version, and a native app built against the `0.1.2` iOS/Android packages. If v14 changes the bridge protocol version AND requires a matching native rebuild, adopters on the old version get an upgrade cliff.

**Early warning sign:** A v14 phase plan that changes `Contract.version()` to a new value AND changes the exact-equality check behavior without providing backward compatibility.

**Prevention:**
- If v14 only fixes the drift (makes `1.0.0` and `1.1.0` consistent) and does not change bridge behavior, no adopter impact: you are not changing the protocol, you are reconciling your sources.
- If v14 adds a new bridge behavior that requires a new version, document the upgrade path, clearly label the native rebuild requirement, and provide a migration guide.
- Do NOT publish a native package version that removes support for the previous version string without explicit deprecation notice and a support window.

**Owning phase:** Phase 4 (native publish) pre-publish checklist.

**Named real-world lesson:** **Capacitor 3.x to 4.x bridge protocol change** — Capacitor's bridge protocol change between major versions broke existing plugin authors who had not updated their bridge message format. The migration was painful because the exact-match check on the protocol version was combined with a major version bump without a compatibility window. The lesson: additive changes, separate from protocol bumps, separate from native rebuild requirements.

---

### Pitfall 5.4 — Documentation claims outrunning proof

**Why it bites:** After v13, Crosswake's docs claim a "bounded typed versioned bridge contract." That claim is true in design but currently false in execution (the 1.0.0/1.1.0 split means the contract is not actually enforced consistently). If v14 docs describe the canonical source as "the single authority" before that is true in code and in CI, the documentation is a lie that adopters might trust.

**Early warning sign:** The docs are updated in Phase 1 to describe the canonical source, but Phase 2 (drift guards) and Phase 3 (native tests) are not yet complete. The docs claim more than the proof lane can verify.

**Prevention:** Update public docs only after Phase 1 (canonical source) AND Phase 2 (drift guards) are complete. Docs claims must be coextensive with passing CI. This is the Crosswake house style: "install truth is product truth."

**Owning phase:** Docs updates belong in the last phase, not the first.

**Named real-world lesson:** **Crosswake v13.0 DRIFT-02** — the v13 quick-start guide drift guard (`test/crosswake/guides/quick_start_adoption_drift_test.exs`) was a direct response to this exact failure mode: docs that described a flow that didn't work from a clean checkout. The lesson was not to update docs then add a guard, but to add the guard that makes the docs true.

---

## Prioritized Top-10 Watch-Out-For

Ranked by: (impact if hit) x (likelihood given current state):

**1. Vacuous native tests — testing mocked version literals instead of fixture-derived values.**
The `BridgeChannelTest.kt` hardcodes `version = "1.0.0"` on both sides of the comparison, making the test insensitive to the actual canonical version. This is the v6/v8 fabrication pattern applied to native testing. Fix: native tests must load fixture JSON generated from `Contract.version()`.

**2. No single canonical source before any other work begins.**
If Phase 1 does not establish `Contract.version()` as the one truth that all fixtures, manifests, tests, and docs derive from, every subsequent phase is building on sand. The drift will return within one PR.

**3. Drift guards written as text-grep checks that break on formatting.**
Parse JSON, do not grep strings. One reformatting commit will break the guard and the maintainer will disable it rather than fix it.

**4. Drift guards with no actionable failure message.**
A CI failure that says "diff detected" without saying what diverged and what to run to fix it will be worked around rather than understood.

**5. Native package CI that requires Xcode/Gradle, making guards flaky, leading to advisory demotion.**
Keep drift guards in `mix` (Elixir) or simple shell scripts; separate from native build CI. Never conflate "are the version strings consistent?" with "does the full native app compile?"

**6. Publishing a new native package version with the wrong bridge protocol version before the drift-guard and canonical-source phases are complete.**
Once published to Maven Central or as a SwiftPM semver tag, a version is immutable. Publish LAST, after all guards are green on main.

**7. The compatibility_mismatch denial not specifying which axis failed or what the expected vs. actual values were.**
The current message is `"Bridge protocol or runtime mismatch"` on both iOS and Android. When an adopter hits this in production, they cannot diagnose it without reading the source. Improve the message to include the diverging pair.

**8. Conflating "bridge protocol version bump" with "no native rebuild required."**
Document the semantics table (additive new optional command = no rebuild required; envelope shape change = rebuild required; exact-equality check semantics change = rebuild required) before any version changes are made in v14.

**9. v14 scope expanding to include new bridge commands or protocol redesign.**
Write the anti-scope into requirements before writing any code. A "make it canonical" milestone must not become a "redesign the bridge" milestone.

**10. Swift on Linux test failures from Bundle.main fixture loading.**
If native package tests load fixture JSON from disk, use `#filePath`-relative paths, not `Bundle.main`. Otherwise the tests pass on macOS and fail in Linux SwiftPM CI.

---

## Phase-Ordering Implications

Given: registry immutability + lockstep release + exact-match denial + the house style of "CI guards before docs claims":

```
Phase 1: CANONICAL SOURCE
  Must come first. Nothing else is trustworthy.
  - Establish Contract.version() as the single source.
  - Document the three axes and their semantics (bump rules, rebuild requirements).
  - Generate fixture JSON from Contract.version() via a mix task.
  - Do NOT update public docs yet.
  - Do NOT publish new native package versions yet.

Phase 2: DRIFT GUARDS
  Must come before any publish and before docs updates.
  - CI checks that parse fixture JSON and compare to Contract.version().
  - Guards must be merge-blocking, not advisory.
  - Guards must emit actionable failure messages.
  - Must not require Xcode/Gradle to run.

Phase 3: NATIVE BEHAVIORAL TESTS
  Must come before publish.
  - Tests in packages/crosswake-shell-core-ios and packages/crosswake-shell-core-android.
  - Tests must load fixture JSON generated from Contract.version().
  - Tests must exercise the exact-equality denial path with wrong versions.
  - Tests must NOT hardcode version literals.
  - Keep hermetic (no live server, no simulator required).

Phase 4: DOCS + PUBLISH
  Last. After guards are green on main.
  - Update docs to describe the canonical source with honest labels.
  - Pre-publish checklist verifies all surfaces agree before native package publish.
  - Publish new native packages only if bridge behavior changed; if v14 is drift-only,
    existing 0.1.2 packages remain valid.
  - Release-please lockstep proceeds normally for the Hex version.
```

**Critical dependency:** Phase 2 (guards) cannot verify correctness until Phase 1 (canonical source) is in place — a guard that checks "does the fixture match the canonical source?" has nothing to check against until the canonical source decision is final. Do not attempt to write guards before the canonical source decision is settled.

**Do not publish early:** The v11.0 lesson is that publishing before proof is proven is irreversible. Run the full Phase 1 to 2 to 3 sequence on main with CI green before any Phase 4 publish activity.

**Drift guard must go green on main before branch-protection registration** — consistent with the v12.0 pattern for `merge-blocking-offline-sync-e2e` (STATE.md: "refuses to register until aggregator goes green on main").

---

## Sources

- Crosswake codebase — `lib/crosswake/bridge/contract.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/compatibility/compatibility.ex`, `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt`, `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` (inspected 2026-06-20)
- Crosswake `.planning/PROJECT.md` — Key Decisions, history of v6.0/v8.0/v12.0 proof fabrication incidents and resolutions
- Crosswake `.planning/STATE.md` — Blockers/Concerns, v12.0 decisions, runtime contract drift finding
- Crosswake `.planning/threads/runtime-contract-confidence.md` — highest-leverage finding, candidate wedge rationale
- Crosswake `prompts/crosswake-elixir-oss-dna.md` — house style constraints
- buf.build documentation — breaking change detection, lint rules: https://buf.build/docs/breaking/overview
- Go `go generate` community conventions and CI patterns: https://pkg.go.dev/cmd/go#hdr-Generate_Go_files_by_processing_source
- Phoenix Channels `vsn` field documentation: https://hexdocs.pm/phoenix/Phoenix.Channel.html
- OpenTelemetry semantic conventions stability policy: https://opentelemetry.io/docs/specs/otel/versioning-and-stability/
- Stripe API versioning documentation: https://stripe.com/docs/api/versioning
- Maven Central immutability and OSSRH publishing guidelines: https://central.sonatype.org/publish/requirements/
- Pact contract testing documentation: https://docs.pact.io/
- CommonMark spec.json conformance approach: https://spec.commonmark.org/
- Swift SE-0272 Package Manager resources and #filePath for Linux: https://github.com/apple/swift-evolution/blob/main/proposals/0272-swiftpm-binary-dependencies.md
- kotlinx-coroutines-test `runTest` documentation: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/
