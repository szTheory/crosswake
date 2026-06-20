# Phase 123: Native Package Behavioral Proof - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Give the published iOS (`crosswake-shell-core-ios`, SwiftPM) and Android (`crosswake-shell-core-android`, Maven) shell-core packages **real behavioral tests** for the six key behaviors — (1) activation success/failure, (2) bridge denial on version mismatch, (3) capability allowlist enforcement, (4) active-route check, (5) pack-version check, (6) delegate/escape-hatch behavior — all anchored to the single committed `bridge_contract_vectors.json` (a gen-task output seeded in Phase 121), so a bridge-protocol-version bump in the Elixir authority fails the Elixir, Swift, and Kotlin suites until vectors are regenerated. Stand up CI lanes whose required-vs-advisory split matches the project's established hermetic-blocking / native-toolchain-advisory rule.

Covers requirements **NTEST-01 through NTEST-04**. This is test-and-CI work that *consumes and extends* the Phase-121 canonical artifacts; it does **not** change the bridge protocol, add bridge commands, restructure envelopes, or refactor production decision logic (the test seams already exist).

**Not in this phase:** native `>=` min-version-floor reconciliation (`BridgeChannel.swift:182`, `BridgeChannel.kt:101` exact-match → floor) and the compatibility guide / support-matrix / changelog upgrade-impact labels — **Phase 124 / COMPAT-***. Any native-package publish (deferred until all four v14.0 phases are green on main).

</domain>

<decisions>
## Implementation Decisions

### A. Vector coverage model (NTEST-01, -02, -03) — "Hybrid"
- **D-01:** Read "all six behaviors parametrized from `bridge_contract_vectors.json`" **pragmatically, not maximally-literally.** The **bridge `evaluate()` request→reply behaviors become rich data-driven vectors** (version mismatch, unknown command / capability allowlist, capability-version mismatch, inactive route, pack incompatible, and delegate-missing denial + an `app.info.get` success). The **activation `resolve()`/`activate()` behaviors** (LiveView success vs `Denied`/`RequiredPack`) and **delegate-success escape-hatch paths** are **code-level tests that LOAD their expected version + denial-reason constants from the same JSON**. Net: every one of the six behaviors is version-anchored to the file (a bump fails it), without forcing whole manifest/delegate object-graphs into JSON.
- **D-02:** The current 3-vector seed (`vec-001-version-mismatch-deny`, `vec-002-unknown-command-deny`, `vec-003-canonical-version-ok`) is **expanded** to cover the bridge denial set above. This requires growing the vector schema to add a **`session_override`** block (the bridge `evaluate()` decision reads `routeId`, `capabilities`, `routeRequiredPacks`, `installedPacks`, `allowedOrigin` from the *session*, not the request) alongside the existing `request_override`. Each vector: `id`, `description`, `request_override`, `session_override`, `expected_outcome` (`ok`/`deny`), `expected_denial_reason` (nullable).
- **D-03:** Expanding the vectors means **editing the Phase-121 canonical Elixir source** — `lib/mix/tasks/crosswake.contract.gen.ex` `vectors_json/4` (and whatever helper enumerates the scenario list) — then regenerating. This is **in-scope and expected**: the gen task's own moduledoc says the seed set is "consumed by Phase 123." The Elixir constant remains the version authority; the vector *scenarios* are authored in the gen task. Phase 123 does NOT introduce a second hand-maintained version literal anywhere (see D-10).

### B. Vector delivery to native suites (NTEST-01) — "gen-emits per-package copies"
- **D-04:** Extend `mix crosswake.contract.gen` to **also write DO-NOT-EDIT copies** of `bridge_contract_vectors.json` into the two native test resource locations: the iOS test bundle resources (e.g. `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/`) and `packages/crosswake-shell-core-android/src/test/resources/`. Each package stays self-contained when consumed standalone from SwiftPM/Maven (no monorepo-relative path traversal, no symlink).
- **D-05:** **GUARD-02 (generate-and-diff) covers the new copies automatically** — it diffs whatever the gen task emits, so adding outputs needs no GUARD-02 change. **Optionally extend GUARD-01's tripwire list** (Phase 122 D-01) to parse-assert the two new generated JSON copies for a friendlier local `mix test` failure; planner discretion, but call it out so it isn't silently skipped. The repo-root `test/fixtures/bridge_contract_vectors.json` remains the canonical emitted artifact; the native copies are byte-identical derivatives.
- **D-06:** Swift requires the file declared as a **test-target resource in `Package.swift`** (`.copy("Resources/")` or `.process(...)` on the `testTarget`) — `Package.swift` currently declares **no resources**, so this is a required edit. Kotlin loads it via `javaClass.getResourceAsStream("/bridge_contract_vectors.json")` from `src/test/resources/` (standard, no build change beyond the resource existing).

### C. CI topology & registration (NTEST-04) — "Dedicated gate + register script"
- **D-07:** **New purpose-named workflow `.github/workflows/native-behavioral-proof-gate.yml`**, mirroring the Phase-122 `contract-drift-gate.yml` idiom (one gate per domain; the native-package proof is an orthogonal domain from contract-drift). It contains:
  - `android-package-unit` — `./gradlew test` in `packages/crosswake-shell-core-android/`, **JVM-only, no emulator**, **merge-blocking**.
  - `ios-package-unit` — `swift test` in `packages/crosswake-shell-core-ios/` on **`macos-latest`, no simulator**, **advisory** (NOT in the aggregator). macOS Xcode is a native toolchain → advisory per the locked project split; this overrides `NATIVE-TESTING.md` §10, which wrongly wanted iOS merge-blocking.
  - `merge-blocking-native-behavioral-proof` — `re-actors/alls-green@release/v1` aggregator, `needs:` **only** the Android job, `if: always()`. This aggregator name is the **sole new required status check**.
- **D-08:** **New `script/register-native-gate.sh`,** a near-verbatim clone of `script/register-contract-gate.sh`: `gh` admin scope, **green-first refuse guard** (exit 2 until `merge-blocking-native-behavioral-proof` has ≥1 successful run on `main`, matching on the *aggregator* conclusion), granular `gh api -X PATCH` to `required_status_checks` with `strict:true` + `unique_by(.context)`. **Script + document the PATCH; do NOT auto-toggle branch protection** (historically human/harness-gated — v12.0 pattern).
- **D-09:** **The Elixir "third suite" is split across two existing/new pieces.** The *version-field* "bump fails the Elixir suite" property is **already delivered by Phase 122 GUARD-01**, which parse-asserts `test/fixtures/bridge_contract_vectors.json`'s `bridge_protocol_version` against `Crosswake.Bridge.Contract.version()` — do **not** duplicate it. Phase 123 adds a **new Elixir *behavioral* vector test** that runs each vector's `request_override`/`session_override` through the Elixir bridge decision path and asserts `expected_outcome`/`expected_denial_reason` — the anti-vacuous proof that the vectors describe *real* Elixir behavior, not just native assertions (PITFALLS anti-vacuous rule). **RESEARCH QUESTION (flag for researcher):** confirm the Elixir side has a single bridge `evaluate`-equivalent decision seam the vectors can drive; if the decision logic is spread across `Crosswake.Bridge` / compatibility / manifest modules, the planner must pick the seam (or a thin test harness) that mirrors the native `evaluate()` contract. This Elixir behavioral test runs in the normal `mix test` invocation (already merge-blocking via existing lanes); it need not live in the new native gate.

### D. Native version-source discipline (NTEST-01) — "Reject native version constants"
- **D-10:** **Native tests assert against the `bridge_protocol_version` loaded from the committed vectors JSON — NOT a hardcoded native constant.** Explicitly **reject** `NATIVE-TESTING.md` §9's recommendation to add `BridgeChannel.protocolVersion` (Swift) / `BridgeChannel.PROTOCOL_VERSION` (Kotlin) constants: a per-platform version literal is a **new drift surface**, exactly what v14.0 exists to eliminate. The whole point of the shared vectors file is that there is *one* place the version lives. Tests read it from the loaded file at runtime. (Capture this loudly — the stale research doc says the opposite and downstream agents will read it.)

### E. Locked-by-prior-work (not re-litigated; listed so the planner doesn't skip)
- **D-11:** Test seams already exist — **no production refactor.** iOS: `BridgeChannel.evaluate(_:completion:)` (public), `ActivationCoordinator.resolve(request:manifest:)`/`activate(_:)` (public), `PackStore(requiredVersions:inventory:)`. Android: `BridgeChannel.evaluateForTesting(request): String` (public test seam), `ActivationCoordinator(config, manifestLoader, requestLoader, packStore)`, `PackStore.inMemory(...)`. Delegate stubs are trivial anonymous types in test files (no mocking library).
- **D-12:** The existing iOS test file `Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` is **corrupted** — its bytes contain literal `\n` escape sequences (`import XCTest\nfinal class ... {}` as a single line) and will not compile. It must be **replaced** with real test files, not patched.
- **D-13:** Frameworks: **XCTest** (iOS) + **JUnit 4** (Android, already in `build.gradle.kts`). The six decision seams are **synchronous**, so most tests need no coroutines. **Add `kotlinx-coroutines-test` and use `runTest` (never `runBlocking`)** only where a test exercises an async path (e.g. `PackStore.installRequiredPack()`'s `delay()`). Do NOT migrate to swift-testing / JUnit 5 (Package.swift min is `swift-tools-version 5.9`; JUnit 4 matches the published-lib norm). Tests must run with **no simulator (iOS) / no emulator (Android)** and must not *claim* device/simulator support.
- **D-14:** Denial-reason strings in both native runtimes already match the JSON `denial_reasons` vocabulary (`compatibility_mismatch`, `undeclared_capability`, `unavailable_capability`, `inactive_route`, `pack_incompatible`, `origin_denied`, `external_entry_denied`). Assert on the reply's reason *string/JSON*, not on an internal `guard`/branch firing (Capacitor/Sentry "don't test the fake" lesson).

### Claude's Discretion
- Exact test file names/locations and how the hybrid vectors are iterated in each language (XCTest manual loop vs per-vector method; JUnit parametrized or per-vector `@Test`); the precise `session_override`/`request_override` field set in the expanded schema (provided it carries enough to drive every bridge denial); whether GUARD-01's tripwire list gains the two native copies (D-05); the exact Swift `Package.swift` resource rule (`.copy` vs `.process`); CI cache keys / step ordering (mirror existing gate jobs keyed on `mix.lock` / Gradle); and the precise Elixir behavioral-test seam pending the D-09 research answer — all planner/researcher discretion, provided D-01..D-14 hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone planning
- `.planning/ROADMAP.md` — Phase 123 goal + success criteria 1–4 (vectors as sole source; six behaviors; XCTest no-sim / JUnit no-emulator JVM; required-vs-advisory split). **Roadmap criterion 4 is authoritative where it conflicts with research** (Swift = advisory, not blocking).
- `.planning/REQUIREMENTS.md` — NTEST-01..04 definitions and the phase-ordering non-negotiable note.
- `.planning/phases/121-canonical-contract-source/121-CONTEXT.md` + `121-VERIFICATION.md` — what Phase 121 actually shipped: canonical = the Elixir constant `Crosswake.Bridge.Contract.version()` (`1.1.0`), NOT a `priv/contract/*.json`; gen task = `mix crosswake.contract.gen`; vectors file is a gen output. **Authoritative over older research docs where they conflict.**
- `.planning/phases/122-drift-guards/122-CONTEXT.md` — GUARD-01 parse-assert surfaces (the vectors JSON is already a tripwire), GUARD-02 generate-and-diff (auto-covers new gen outputs), and the `register-*.sh` green-first + documented-PATCH registration pattern to clone.

### Research (read for principles + concrete test code; treat its CI + native-constant claims as superseded)
- `.planning/research/NATIVE-TESTING.md` — the deep behavioral-test design. **Has full working XCTest + JUnit test examples (§3, §4) and the seam inventory (§6, §9) — use these.** BUT **superseded on two points:** (a) §10 wants iOS merge-blocking — roadmap says advisory (D-07); (b) §9 recommends native version constants — rejected (D-10). It also predates 121, so where it describes the vectors file as hand-edited, the shipped reality is gen-emitted (D-03).
- `.planning/research/PITFALLS.md` — anti-vacuous / assert-specific-values proof (drives D-09's Elixir behavioral test) and parse-not-grep.
- `.planning/research/ARCHITECTURE.md`, `.planning/research/STACK.md` — three-axis version model, generate-and-diff discipline, hermetic-blocking vs native-advisory split rationale.

### Code to change / create (canonical source + gen)
- `lib/mix/tasks/crosswake.contract.gen.ex` — `vectors_json/4` (line ~49) and the four output paths (`@vectors_path` line 35); **extend to author the expanded vector set + emit the two native copies** (D-03, D-04). Keep `write_if_changed` + sorted-key emit (GUARD-02 determinism).
- `lib/crosswake/bridge/contract.ex:10` (`@version "1.1.0"`), `version/0` (~line 105) — the version authority the vectors carry; tests read it from the JSON, never re-hardcode it.
- `test/fixtures/bridge_contract_vectors.json` — current 3-vector seed; the canonical emitted artifact to expand.

### Code to test (native seams — already exist, no refactor)
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` — `evaluate(_:completion:)` (public; version check ~line 181, route ~188, origin ~193, capability ~198, pack ~210). `ActivationCoordinator.swift` — `resolve(request:manifest:)`/`activate(_:)` (public), `RouteDenialReason` enum (lines 17–25). `PackStore.swift` — `blockingStatus(for:)`. `CrosswakeDelegates.swift` — six delegate protocols. `Package.swift` — add test resources. Replace the corrupted `Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift`.
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt` — `evaluateForTesting(request): String` (line ~307; version check ~101, route ~105, capability ~113, pack ~125). `ActivationCoordinator.kt` — `activate(request): ShellPresentation`, `RouteDenialReason` enum (~line 28). `packs/PackStore.kt` — `inMemory(...)` (~line 87), `blockingStatus(...)`. `CrosswakeDelegates.kt` — delegate interfaces. `build.gradle.kts` — add `kotlinx-coroutines-test`. `src/test/java/dev/crosswake/shell/core/CrosswakeShellConfigTest.kt` — existing JUnit pattern to extend.

### CI / registration to mirror (v12.0 / Phase-122 pattern)
- `.github/workflows/contract-drift-gate.yml` + `.github/workflows/offline-sync-e2e-gate.yml` — the sibling-jobs + single `re-actors/alls-green` aggregator topology to mirror as `native-behavioral-proof-gate.yml`.
- `script/register-contract-gate.sh` — the green-first-guard + granular-PATCH + script-not-auto-toggle registration pattern to clone as `script/register-native-gate.sh`.
- `.github/workflows/native-collateral-advisory.yml` — the existing advisory native lane (unchanged; confirms the advisory-native idiom).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Test seams already exist on both platforms** (D-11) — `evaluate()`/`evaluateForTesting()`, injected-loader `ActivationCoordinator`, `PackStore.inMemory()`. NATIVE-TESTING.md §3/§4 ships nearly-complete copy-paste XCTest + JUnit suites against these.
- `mix crosswake.contract.gen` — hermetic, idempotent (`write_if_changed`), sorted-key JSON. Extend its vector list + add two emit targets; no new pipeline.
- Phase 122 GUARD-01/GUARD-02 — already guard the vectors file's version field + generated-output freshness; the native copies inherit GUARD-02 coverage for free.
- `script/register-contract-gate.sh` + `re-actors/alls-green` — the entire gate + branch-protection machinery; Phase 123 instantiates a third copy.

### Established Patterns
- **One purpose-named gate workflow per domain → one `alls-green` aggregator = sole required check** (v12.0 / Phase 122). Followed verbatim (D-07).
- **Hermetic = merge-blocking; native toolchain (Xcode/Gradle-emulator) = advisory.** JVM Gradle is deterministic/hermetic → Android lane blocking; macOS Xcode → iOS lane advisory (D-07).
- **Single-source-or-it-drifts:** every version literal lives once (the Elixir constant → vectors JSON → native copies). No per-platform constant (D-10).
- **Anti-vacuous proof:** vectors must be exercised behaviorally in Elixir too, not merely asserted by native (D-09).

### Integration Points
- `mix crosswake.contract.gen` → now also writes iOS + Android test-resource copies of the vectors (new outputs; GUARD-02 diffs them).
- `Package.swift` testTarget → gains a `resources:` declaration (new; currently none).
- `build.gradle.kts` → gains `testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test")` (only if an async path is tested).
- `native-behavioral-proof-gate.yml`'s `merge-blocking-native-behavioral-proof` aggregator → new required status check, registered out-of-band via `register-native-gate.sh` + documented PATCH.
- New Elixir behavioral vector test → runs in existing `mix test` lanes (already blocking); GUARD-01 continues to own the version-field assertion.

</code_context>

<specifics>
## Specific Ideas

- "Bump the version → three suites go red" is the headline guarantee (criterion 1). Mechanically: a bump makes the committed vectors stale → **GUARD-01 fails (Elixir version-field)** + **GUARD-02 fails (generated outputs stale)**; regenerating updates the repo-root file AND the two native copies, and the native/Elixir *behavioral* vector tests then assert against the refreshed expected values. The "all three" property is the union of GUARD-01/02 (Elixir) + the native suites loading the regenerated copies.
- The bridge `evaluate()` decision reads route/capability/pack/origin from the **session**, not the request — so the expanded vector schema needs `session_override`, not just `request_override` (D-02). This is why the 3-vector seed (request-only) can't express the route/pack/capability denials.
- Delegate escape-hatch is proved by two symmetric tests per delegate-backed command: delegate present → `ok`; delegate absent → `deny` (`undeclared_capability`/`unavailable_capability`). The delegate protocols are already in `CrosswakeDelegates.{swift,kt}`.

</specifics>

<deferred>
## Deferred Ideas

- **Native `>=` min-version-floor reconciliation** (`BridgeChannel.swift:182`, `BridgeChannel.kt:101` exact-match → floor) + compatibility guide / support-matrix / changelog upgrade-impact labels — **Phase 124 / COMPAT-***.
- **Pre-publish fixture-verification gate** (`mix crosswake.contract.verify_published_fixtures` blocking native-package publish on version divergence) — belongs to the v14.0 publish step after all four phases are green.
- **swift-testing / JUnit 5 migration** and **Linux SwiftPM test support** (gating `@Published`/SwiftUI behind `#if canImport`) — explicitly out; macOS-only advisory is honest and sufficient (NATIVE-TESTING.md §6.3 Option B). Note for a future hardening pass only.
- **Turbine / StateFlow assertions** for reactive presentation streams — only if a future behavior needs stream-level proof; the six target behaviors are synchronous.

None of these are scope creep into 123 — they are explicitly-ordered later phases or post-milestone hardening.

</deferred>

---

*Phase: 123-native-package-behavioral-proof*
*Context gathered: 2026-06-20*
