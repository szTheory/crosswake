# Phase 198: Android foreign-host proof - Research

**Researched:** 2026-11-05
**Domain:** Cross-platform contract-parity evidence (Elixir generators/renderers), Kotlin JVM unit tests for an Android library, and a networked Gradle foreign-host CI leg
**Confidence:** HIGH on the Gradle, foreign-host and Kotlin findings (all run locally this session); MEDIUM on the CI-placement and promotion-script mechanics (read, not executed)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Premise corrections (the planner must carry these)
- **D-01:** AND-01 and ROADMAP SC1 say the ledger is generated "from `priv/contract_vectors/*.json`". That directory holds only `navigation_topology_vectors.json` (5 vectors, Elixir-only, read by no Swift/Kotlin test). The corpus Swift and Kotlin both consume is `test/fixtures/bridge_contract_vectors.json` (15 request vectors, 2 reply-leg vectors), written by `mix crosswake.contract.gen` to three byte-identical copies (`test/fixtures/`, iOS `Tests/.../Resources/`, Android `src/test/resources/`). The ledger therefore reads BOTH locations. The corpus is NOT moved (moving churns Phase 196 pins, `script/repository_artifact_policy.json`, `contract_drift_test.exs`, and would ship it in the Hex package). Record the wording fix in REQUIREMENTS and ROADMAP through a recorded roadmap change, never by silently reinterpreting. — **Reversibility:** reversible — wording and glob only.
- **D-02:** `androidx.webkit` IS imported (`BridgeChannel.kt` lines 4-5, `WebViewCompat.addWebMessageListener`), so the SC2 clause "absent if no source imports it" does not fire; keep it in core, replace the false "may need" comment with "imported by BridgeChannel.kt (addWebMessageListener)". The generated template's `webkit:1.15.0` line in `priv/templates/crosswake/shell/android/app/build.gradle.eex:64` is dead weight, but removing it forces a `@template_version` bump and drift-hash and test edits; record it as a deferred item, not Phase 198 work.

### AND-01 Parity ledger and vector-set hash
- **D-03:** Ledger is a generated PUBLIC guide `guides/parity_ledger.md`, rendered through `mix crosswake.docs.sync` as a third projection (source `lib/crosswake/parity_ledger.ex`, renderer `Crosswake.ParityLedger.Renderer` mirroring `CapabilityMap.Renderer`). Regenerate-no-diff is enforced by the existing `docs.sync --check` CI step. It stays out of `Crosswake.SupportMatrix`. Rejected: ledger as non-public `contract.gen` artifact (fails the "team can see" goal; native runs never assert on bytes they load).
- **D-04:** "Vector-set hash" = `sha256:` + lowercase hex of the corpus file's RAW BYTES, never re-encoded. No canonical-JSON hashing (three new bug surfaces; generator already emits sorted-key bytes and a byte-diff gate exists). Add `.gitattributes` `text eol=lf` for the three copies and `priv/contract_vectors/*.json`. Today the shared set is exactly one file; an ExUnit pin `length(shared_corpora) == 1` forces a deliberate decision if a second appears (expected future rule: hash over sorted `"<hex>  <name>\n"` lines; do not build it now). Non-shared corpora (topology, navigation transition) are listed with per-file hashes, `shared: no`, informational only.
- **D-05:** `contract.gen` also writes generated constants: iOS `Tests/CrosswakeShellCoreTests/VectorSetHash.swift` (Tests root, not `Resources/`) and Android `src/test/java/dev/crosswake/shell/core/VectorSetHash.kt` (`internal object VectorSet { const val SHA256 = "..." }`). Add both paths to `generated_contracts[0].output_paths` in `script/repository_artifact_policy.json`. Handwritten loader helpers (`VectorCorpus.loadVerifiedBytes()` on Kotlin, Swift equivalent using `CryptoKit.SHA256`, no `#if canImport` skip) assert bytes equal the constant, and EVERY consumer's load step calls it (`BridgeConformanceTest`, `BridgeReplyLegTest`, `ActivationConformanceTest`, Swift `setUp`s). One explicit mismatch test per platform.
- **D-06:** `test/crosswake/parity_ledger_test.exs` asserts: three copies equal; each native constant matches via a strict anchored regex with exactly one match (zero fails); the guide contains the hash; a two-sided consumer registry (declared consumers exist and name their corpus; scanning `packages/*/src/test` and `Tests/` finds no undeclared consumer). Pure helper `ParityLedger.compare_references/1` follows the `compare_*` idiom of `contract_drift_test.exs`. Negative controls required: Swift differs from Kotlin; constant differs from corpus; constant file missing or regex matches zero; empty corpus; one mutated byte in a tmp copy; `docs.sync --check` fails on a tampered tmp ledger. One-time phase evidence (not CI): flip one byte in each native resource copy and confirm `./gradlew test` and the Swift suite go red.
- **D-07:** Ledger content is fully derived, nothing hand-listed per vector. Table 1: one row per corpus (file, sha256, shared, Elixir/Swift/Android consumer, pinned executions). Table 2: one row per vector (id, expected outcome and denial reason, Elixir/Swift/Android), with `elixir_only` vectors showing native "not applicable", `native_only` showing Elixir "not applicable", and navigation-transition/topology showing Android "no consumer" (honest gap, never "pending"). Vocabulary is "JVM test executed"; the ledger test rejects `emulator`, `device-verified`, `supported on Android`. Header states: the hash proves identical corpus BYTES, not semantic equivalence of assertions; evidence is CI on the repository head, not on a published artifact; regeneration command `mix crosswake.contract.gen && mix crosswake.docs.sync`. Pinned counts stay hand-written and independent (15 loaded, 14 native, 9 Elixir, reply-leg 2; Phase 196 D-05: never derive from the same collection).
- **D-08:** The new guide carries the same D-26 "not in a published release yet" qualifier until 0.2.12; add it to the Phase 199 SC6 removal list and to `unreleased_claim_qualifier_test.exs`. Update pins: `phase166_repository_quality_test.exs` (~195), `test/js/repository_verification.test.mjs` (~54), `mix.exs` `extras`/`groups_for_extras`.

### AND-02 Kotlin test floor and JSON stack
- **D-09 (JSON stack, recorded in writing):** Production keeps the platform `org.json` (zero runtime dependency). Tests swap the Crockford `org.json:json:20231013` for the AOSP-derived `com.vaadin.external.google:android-json:0.0.20131108.vaadin1` (Apache-2.0), because Crockford is stricter than the device (`getString` coercion, JSON `null`, duplicate keys, comments) and would let a "non-string rejected" test pass on the JVM and be false on a phone. The AOSP copy returns a raw `Iterator` from `keys()`: fix the 6 call sites in `BridgeConformanceTest.kt` (lines ~86, 87, 100, 101, 147, 148) with `.map { it as String }`. Never set `unitTests.isReturnDefaultValues = true`. Rejected: kotlinx.serialization in production (rewrites ~8 files, keeps a runtime dep, changes the POM, no demonstrated defect; revisit only on a shown parity or security defect, v29+); vendoring AOSP org.json (1.5k security-sensitive lines to own). Record as an ADR A1 note or a Phase 198 DECISIONS entry. Claim stays JVM-hermetic: this was not run against a real device.
- **D-10:** Remove dead `kotlinx-serialization-json:1.6.0` and the `kotlin.plugin.serialization` plugin from `packages/crosswake-shell-core-android/build.gradle.kts` (verified in a scratch copy: compiles, 4 test classes pass, webkit kept). Leave the generated root template's `apply false` plugin line (harmless, asserted by `crosswake_gen_shell_test.exs:221`). The published POM shrinks starting with the next release; the foreign-host leg targets an already-published version so is unaffected. — **Reversibility:** costly — changes the published POM at the next publish; hosts that transitively relied on kotlinx-serialization would break (none known; core has no usage).
- **D-11:** Add production hardening, fail closed: `BridgeRequestEnvelope(JSONObject)` rejects required fields that are not JSON strings, including JSON `null` (~5 lines). Two `internal` extractions so the listener boundary is JVM-testable without a WebView: `BridgeChannel.parseBody(body: String?): BridgeRequestEnvelope?` and `BridgeChannel.listenerAllows(isMainFrame: Boolean, sourceOrigin: String): Boolean`. Payload stringification unchanged. Malformed-envelope silent drop (no correlation id to echo) is recorded as intentional.
- **D-12:** New tests, separately authored, no new shared vectors (Swift/Elixir pins and Phase 196 controls untouched): `BridgeChannelBoundaryTest.kt` (~14-16 tests) and `SemVerBoundaryTest.kt` (5) for about 30 against the floor of 25, plus a test-only `BridgeFixtures.kt` with copied `makeSession`/`makeRequest` helpers (copy over editing `BridgeConformanceTest.kt`). Do NOT convert the vector loop to a JUnit `Parameterized` runner. Boundary cases the planner must cover: wrong protocol (`crosswake.bridge2`, empty, `Crosswake.Bridge`); malformed request version (`""`, `abc`, `1.0.0-beta`, `1.0.0.0`, overflow; `1` and `1.0` accepted); route_id/active_route_id mismatch each direction; origin near-misses (trailing slash, `http://`, other port, uppercase host, the userinfo-spoof origin (`https://app.example.com` followed by an at-sign and `evil.test`), `null`, empty); command near-misses (case, trailing space, empty, `app.info.get.x`); command/capability mismatch and aliases; pack authority (request-claimed packs do not satisfy, `pack@` empty demand, one of two missing, unversioned matches any); capability gating; deny-before-side-effects with a positive control (counter 0 vs 1); denial precedence; deny reply shape and privacy (sentinel secret never in the denial JSON, `payload` is `{}`); transfer commands with null coordinator; `files.pick` Deferred without sink; `permissions.status` missing/unknown alias; envelope parse cases; listener gate (non-main-frame, origin differs); command-set parity (`BridgeCommand` wire values superset of vector `commands`, extras exactly `{server.event.push, server.state.update}` as an independent literal). `SemVerBoundaryTest`: null/blank false; equal true; patch-lower false; unparseable falls back to raw equality both ways; negative/overflow fails closed.
- **D-13 (pin mechanism, no rotting literal):** `script/check_kotlin_test_floor.py` plus `script/check_kotlin_test_floor_test.py` (precedent: `verify_android_public_build_test.py`), hooked after the Gradle run in the `android-package-proof` stage (`script/repository_verification_stages.json`). Asserts: tests >= 25 (the one literal, a ratchet floor), failures 0, skipped 0; XML count equals non-`@Ignore` `@Test` count in `src/test` (derived equality); `BridgeChannelBoundaryTest` alone has >= 10 testcases; a short list of load-bearing named tests present and passing. Count ONE variant only (`testDebugUnitTest`; `./gradlew test` also runs release and summing double-counts) and force execution (`cleanTestDebugUnitTest` or `--rerun-tasks`) because an unchanged task reports UP-TO-DATE with stale XML. Negative controls as fixture XML: 24 tests; one skipped; boundary class missing; zero XML files; debug+release double-counted. Update or retire the `tests: 12` pin in Phase 196 `phase-evidence.mjs:533` as phase history; leave `vector-controls.mjs` and its 15/14 pins alone.
- **D-14 (adversarial findings, decided here so they are not pinned silently):** `server.event.push` and `server.state.update` skip `capabilityAvailable` (only the request-supplied capability string is compared), emit `invalid_payload` which is not in vector `denial_reasons`, and are Android-only (not in iOS or the shared vectors). `server.state.update` with an unknown state returns `ok` and changes nothing. Phase 198 does NOT change these behaviors (A1: existing contracts only); it documents them in the ledger as "Android-only, outside shared vectors, ungated" and adds a characterization test explicitly named as current behavior, with the gap logged in Deferred with owner, trigger and receiver. If the user prefers fail-closed gating now, that is a one-line scope override recorded here before planning.

### AND-03 Foreign-host proof
- **D-15:** New `script/verify_android_foreign_host.sh`, reusing `verify_android_release_host.sh` UNCHANGED for host generation (a `mix new` host depending on Hex `crosswake == V`, then `mix crosswake.gen.shell android` with no `--local`). Leave `verify_android_public_build.sh` alone (release lane, pinned, called from `release-please.yml:1208`), and keep `verify_generated_android_shell.sh` as the hermetic merge-blocking lane (it injects `mavenLocal()`/`--local`, exactly what this leg forbids). Copy the output contract of `verify_published_cleanroom.sh` (exit 0/1/2; `curl --max-time --retry --proto =https`; `foreign-host: leg <name> PASS ...`, `foreign-host: FAIL <leg> <reason>`, `foreign-host: result PASS|FAIL`; selftest overrides only with a selftest flag) and apply Phase 195 WR-05: report `not_published` and `resolve_failed` as separate reasons. Rejected: sed-ing a checkout-generated project to the published version (asserts the wrong thing; useful only as a later extra leg after 0.2.12).
- **D-16 (no version literal):** Coordinate group/artifact come from the publisher's own declaration (`coordinates("io.github.sztheory", "crosswake-shell-core-android", ...)` in `packages/crosswake-shell-core-android/build.gradle.kts`). Version = highest non-prerelease present on BOTH Maven Central `maven-metadata.xml` and the Hex releases API for `crosswake` (0.2.11 today, checked live). Network failure = `resolve_failed`; empty intersection = `not_published`; optional `X.Y.Z` override must still exist on both. After generation assert the `implementation(...)` line in the generated `app/build.gradle` equals `group:artifact:V` exactly. Evidence and step summary say "published V, not head version". Maven Central via `mavenCentral()` (Central Portal publisher), anonymous reads.
- **D-17 (anti-vacuous guards, all three required):** (1) the script writes a host-owned `ForeignHostResolveTest.kt` that imports pure Kotlin classes from the AAR, asserts behavior, and asserts the class loaded from the Gradle-cache `io.github.sztheory` path (the generated app has no `app/src/test`, so otherwise `testDebugUnitTest` is NO-SOURCE and passes testing nothing); parse `build/test-results/testDebugUnitTest/TEST-*.xml` requiring tests >= 1, failures/errors/skipped 0, else `no_tests`. (2) AAR byte check: sha256 of the AAR in `modules-2/files-2.1/io.github.sztheory/.../V/` equals Maven's `.aar.sha256`. (3) Settings check: generated `settings.gradle` has no `mavenLocal()`, no `include ':crosswake-shell-core-android'`, no `project(`. Clean env: fresh `HOME` and `GRADLE_USER_HOME`, no credentials, `~/.m2/repository/io/github/sztheory` absent, no `ORG_GRADLE_PROJECT_*`; job needs only `contents: read`. Before the positive build delete `$GRADLE_USER_HOME/caches/modules-2/files-2.1/io.github.sztheory` and use `--refresh-dependencies` so a warm cache cannot fake the fetch.
- **D-18 (negative control that fails for the right reason):** Copy the generated project, append `-negctl` to the artifactId only (assert the sed matched exactly one line). Preconditions: `curl` of the bad `.pom` returns HTTP 404 (absent, not offline); `gradlew :app:testDebugUnitTest --dry-run` exits 0; the positive leg already passed with the same `GRADLE_USER_HOME`. Run `:app:testDebugUnitTest` (NOT `:app:dependencies`, which exits 0 with FAILED text). Pass = non-zero exit AND output contains `Could not find io.github.sztheory:crosswake-shell-core-android-negctl:V` AND `Could not resolve all files for configuration`. `Could not GET`/`UnknownHost`/`Read timed out`/`Connection` = `control_inconclusive` (never a pass); exit 0 = `control_passed`; other errors = `control_wrong_reason`. No `--offline`. UNVERIFIED: the exact Gradle 8 message and the exit-code behavior come from agent knowledge, not a local run; confirm on the first CI run before relying on them.
- **D-19 (CI placement):** New advisory job `android-foreign-host` in `.github/workflows/crosswake-ci.yml`, gated like `android-generated-shell-unit` (`needs: [classify-change]`, `full_proof`), `ubuntu-latest`, ~25 min timeout, NOT in the umbrella's `needs`, no `continue-on-error` or `|| true`. Generalise `script/check_ci_leaf_manifest.py` (hardcodes `ADVISORY_JOBS = ("brand-visual",)` and a single `brand_visual` block, lines ~65 and ~321-329) into a loop over `ADVISORY_JOBS` with the same checks. Cache the generated `gradlew` distribution in `~/.crosswake/gradle` keyed on `gradle-wrapper.properties`. Add a deterministic selftest `script/verify_android_foreign_host_test.py` (fake `curl`/`gradlew`: no tests, network-error control, control exits 0, wrong-reason control) run in the existing hermetic `android-generated-shell-unit` job, keeping hermetic and advisory lanes separate (invariant 10). Cost expectation 8-12 billable min uncached, 4-6 cached (UNMEASURED); run `script/ci_cost_report.sh` after the first PR and record the job's minutes against the ~250 baseline.
- **D-20 ("two clean runs" derived, never hand-stamped):** The job uploads a JSON evidence artifact (`android-foreign-host-evidence`: target version, head SHA, test count, control reason `could_not_find`, git blob hash of the script). New `script/android_foreign_promotion.sh` reads Crosswake CI run history via `gh api`; a clean run = job `success`, evidence present with tests >= 1 and reason `could_not_find`, script blob hash equals the current script (any edit resets the count), head SHA distinct from other counted runs; skipped counts as neither clean nor reset; count consecutive qualifying runs newest first, stopping at the first ran-and-failed; no auto-retry. Prints `android_foreign: clean_runs=N/2 eligible=yes|no`, `UNVERIFIED` on any read failure, names the head SHA; add one line to `script/bearings_report.exs`. Promotion itself is a reviewed PR moving the job into `FINAL_PROOF_LEAVES` and the umbrella `needs`; how a skipped run is treated by the umbrella (skip-as-pass hazard) is decided in that PR.

### Claim ceiling (SC4)
- **D-21:** Typed ceiling in code, owned by `lib/crosswake/support_matrix/support_matrix.ex`: `@android_evidence_order [:not_claimed, :jvm_hermetic, :emulator, :device]`, `@android_evidence_ceiling :jvm_hermetic` (comment: raising it needs an ADR A1 amendment), `android_evidence_levels/0`, `android_evidence_ceiling/0`, `android_evidence_label/1` (labels `"not claimed"`, `"JVM hermetic proof"`, `"emulator evidence"`, `"device evidence"`), `validate_android_evidence!/1` (raises `ArgumentError` on unknown or above-ceiling; follow `validate_adoption_claim!` in `capability_map.ex`), and `android_boundary/0` returning the one canonical boundary sentence that replaces the hand-pasted copies (`support_matrix.ex` ~446/~473, `support_matrix/renderer.ex` ~380, `capability_map/renderer.ex` ~163). Existing pins that assert the sentence switch to `SupportMatrix.android_boundary()`. No new label taxonomy (BEARINGS): only existing legend labels plus the plain absence string "not claimed", which is not an evidence level and is not added to the legend. Rejected: ledger-only `android_parity_level` taxonomy.
- **D-22:** Add `:android_evidence` to `Crosswake.CapabilityMap.Row` (default `:not_claimed`; Android bridge/shell-core row `:jvm_hermetic`; `canonical/0` validates each row), and an "Android evidence" column after "Proof posture" in the capability map renderer, kept out of the D-26-qualified `:ios_host` section. The support matrix gets no new column; the ceiling renders once from `android_boundary/0` in the legend area and points to the ledger. If the 11-column capability map is judged unacceptable, fall back to the typed ceiling on the ledger only plus the scanner extension (criterion 4's capability-map half then rests on pins and regexes; record that honestly).
- **D-23:** The ledger's Android cell is COMPUTED, never authored: `:jvm_hermetic` only when the Swift and Kotlin vector-set hashes match and the consumer registry confirms execution; otherwise `:not_claimed`, passed through `validate_android_evidence!`. New `test/crosswake/guides/android_claim_ceiling_test.exs` (async, network-free, merge-blocking after a first run confirms 0 findings by construction): a pure `ceiling_violations(table_text)` parses markdown tables by header and checks every Android-column cell is in the allowed set; non-empty floor (table and column present, `JVM hermetic proof` count >= 1, rendered counts equal typed counts from `canonical/0`); negative controls (`validate_android_evidence!(:emulator)` and `(:device)` raise; a row with `android_evidence: :device` fails `canonical/0`; a fabricated table with an "emulator evidence" cell violates; a table with a missing column violates; mutating one rendered Android cell differs from the checked-in file).
- **D-24:** Backstop prose scan: add `guides/capability_map.md` and the ledger guide to `@scanned_paths` in `test/crosswake/guides/native_evidence_drift_test.exs` and two `:device_support_overclaim` patterns (`\bAndroid\b.*\b(emulator|device|physical)[- ](verified|tested|proven|support)` and `\b(emulator|device)-verified Android\b`), extending the existing negative control rather than writing a second scanner. MEASURE first: run once over the guides and record how many existing lines it flags (support matrix has ~11 Android lines mentioning emulator/device/verified); reword false positives in the renderer, not the test; do not make it merge-blocking until the measurement is recorded (BEARINGS tripwire).
- **D-25:** Phase 197 interplay: D-26 `@claims` gets no Android token; new text names no `:ios_host`, `1.2.0` or unpublished behavior, so Phase 199 SC6 stays a pure removal; add no new "Phase NN" text (docs-report leak counter matches `Phase [0-9]+`; the `shell.android.device_verified` rule at `support_matrix.ex` ~1549-1579 already contains "Phase 67/68", rewording optional); `phase68_android_uat_test.exs` and `android_uat.md` unchanged.

### Claude's Discretion

- Exact file/module names beyond those listed, plan and wave split, and PR grouping (one checkout, sequential waves; the existing convention).
- Whether to include the `parseBody`/`listenerAllows` extractions or test only `evaluateForTesting` plus the envelope constructor (D-11 prefers the extractions; the planner may fall back if they prove invasive).
- Choice of Kotlin probe class for `ForeignHostResolveTest.kt` (`CrosswakeShellConfig` or `SemVer`).

### Deferred Ideas (OUT OF SCOPE)

- Gating `server.event.push` / `server.state.update` fail-closed and denying unknown `server.state.update` values (D-14). Owner: Android bridge maintainers; trigger: a phase that claims bridge-command breadth or promotes these commands into shared vectors; receiver: v29 Android/bridge phase (no receiver exists today, so the planner records it as a debt row with that owner and trigger).
- Removing the dead `webkit:1.15.0` line from the generated app template (needs `@template_version` bump). Trigger: the next template change.
- Aligning the example host's `org.json:json:20240303` with the test artifact. Trigger: next example-host touch.
- Extra foreign-host leg that generates from the PR checkout and seds the version (after 0.2.12 is published).
- Promotion of the foreign-host leg to required (after two derived clean runs, via a reviewed PR; skipped-run handling decided there).
- Canonical-JSON hashing, kotlinx.serialization migration, vendored org.json: only on the triggers named in D-04 and D-09.
- Retargeting the proof to 0.2.12: automatic once both registries carry it (D-16); Phase 199 owns the release.

</deferred>
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AND-01 | A parity ledger is generated with an Android column, and a test asserts Swift and Kotlin reference the same vector-set hash | Corpus facts and hash approach (Corrections C1, C4, C14); `contract.gen` and `docs.sync` extension points; pins that must move (C9) |
| AND-02 | Kotlin core JVM tests rise from 12 to at least 25 incl. `BridgeChannel` boundary cases; `androidx.webkit` removed if unused; JSON-stack choice in writing | Verified JSON-stack swap (C5, C18); verified current behavior of `SemVer` and the envelope (C6); test-floor checker placement (C7) |
| AND-03 | A fresh foreign Gradle project from `mix crosswake.gen.shell android` resolves the published Maven coordinate and passes JVM tests on Linux CI (advisory), with a wrong-coordinate negative control | Whole foreign-host flow executed locally against published 0.2.11 (C1, C2, C3, C12); CI placement (C15) |
</phase_requirements>

## Summary

CONTEXT.md is detailed and mostly sound. This session executed the riskiest parts of it instead of trusting them: the full foreign-host flow against the published 0.2.11 artifact (generate from Hex, resolve from Maven Central with a fresh `GRADLE_USER_HOME`, run a host-owned JVM test, run the wrong-coordinate control), and the D-09/D-10 JSON-stack swap in a scratch copy. Both work. The D-18 control messages, which CONTEXT marked UNVERIFIED, are now verified verbatim for Gradle 8.7 and AGP 8.4.1.

Eighteen places where CONTEXT's premise or mechanism is wrong or incomplete are listed in "Corrections to CONTEXT" below. The five that change plans: (C1) the "class loaded from the `modules-2/files-2.1/io.github.sztheory` path" anti-vacuity assertion cannot pass because AGP unit tests load the class from a `transforms-4` runtime jar; (C6) `SemVer` does not fail closed on negative components, so the D-12 `SemVerBoundaryTest` as written cannot pass without a production change; (C7) the `android-package-proof` stage schema is closed and its argv is pinned, so "hook after the Gradle run in the stage" needs a different mechanism; (C4) `navigation_topology_vectors.json` IS read by a Swift test; (C9/C10) several pins and an existing overclaim regex interact with the new guide text.

**Primary recommendation:** Execute CONTEXT D-01..D-25 as locked, applying the corrections below; build the foreign-host script around the verified shape (Hex-generated host, fresh HOME and GRADLE_USER_HOME, Maven `.aar.sha256` byte check, host-owned `ForeignHostResolveTest.kt` read from `app/build/test-results/testDebugUnitTest`, control run on `:app:testDebugUnitTest`).

## Corrections to CONTEXT (the planner must carry these)

Each item was checked this session. None reverses a locked decision's intent; each changes a mechanism, a number or a pin.

| # | CONTEXT says | Reality | Evidence | Planning consequence |
|---|---|---|---|---|
| C1 | D-17(1): assert the probe class loaded from the Gradle-cache `io.github.sztheory` path | The unit-test classloader loads it from `$GRADLE_USER_HOME/caches/transforms-4/<hash>/transformed/crosswake-shell-core-android-0.2.11-runtime.jar`. The `io.github.sztheory` path holds only the `.pom`, `.module` and `.aar` | [VERIFIED: local run 2026-11-05] printed `PROBE codesource=file:/.../fh/home/.gradle/caches/transforms-4/36df014c3ce1c3aa966a626718c6dc3e/transformed/crosswake-shell-core-android-0.2.11-runtime.jar`; AAR found at `.../modules-2/files-2.1/io.github.sztheory/crosswake-shell-core-android/0.2.11/280fa186d632a986b23cb7bfdd78674c2ddd2fcc/crosswake-shell-core-android-0.2.11.aar` | Assert the code source starts with the run's `GRADLE_USER_HOME` + `/caches/` and its file name equals `crosswake-shell-core-android-<V>-runtime.jar`. Do not hardcode `transforms-4`. Template the version and `GRADLE_USER_HOME` into the host-owned test file from the script (do not rely on the test JVM inheriting env). Keep the separate AAR byte check (D-17(2)) as the check on the `io.github.sztheory` path |
| C2 | D-17(1): parse `build/test-results/testDebugUnitTest/TEST-*.xml` | In the generated project the XML is at `app/build/test-results/testDebugUnitTest/` (module `app`) | [VERIFIED: local run] file `app/build/test-results/testDebugUnitTest/TEST-dev.crosswake.shell.ForeignHostResolveTest.xml` | Read `app/build/...` in the foreign-host script. The core package (`check_kotlin_test_floor.py`) reads `packages/crosswake-shell-core-android/build/test-results/testDebugUnitTest/` |
| C3 | D-18: exact Gradle 8 message UNVERIFIED | Verified. Wrong-artifact run exits 1 at `:app:checkDebugAarMetadata`; both required strings present | [VERIFIED: local run, Gradle 8.7, AGP 8.4.1] output: `Execution failed for task ':app:checkDebugAarMetadata'.` / `> Could not resolve all files for configuration ':app:debugRuntimeClasspath'.` / `> Could not find io.github.sztheory:crosswake-shell-core-android-negctl:0.2.11.` / `Searched in the following locations:` listing `https://dl.google.com/dl/android/maven2/...` then `https://repo.maven.apache.org/maven2/...`. `--dry-run` of the same task exited 0. Pre-check `curl` of the bad `.pom` returned HTTP 404 | D-18 stands as written. Match the two substrings literally; the first has a trailing `.` in Gradle's output so match without it. Both `google()` and `mavenCentral()` are searched, so "Could not find" requires a miss on both; offline gives `Could not GET` instead (the control must treat that as inconclusive, as D-18 says). A harmless `Warning: SDK processing. This version only understands SDK XML versions up to 3` line appears with locally installed cmdline-tools; ignore it |
| C4 | D-01: `navigation_topology_vectors.json` is "read by no Swift/Kotlin test" | `NavigationCoordinatorTests.swift` reads it and executes 1 of its 5 vectors (`synthetic_authorized_root`) via a cwd-relative `../../priv/contract_vectors/...` path. No Kotlin test reads it. `navigation_transition_vectors.json` (4 vectors) is a Swift resource that no Swift test source names; only `lib/crosswake/proof_lane/navigation_shell_advisory.ex` references it | [VERIFIED: `NavigationCoordinatorTests.swift:39-40` read this session] `let vectorURL = URL(fileURLWithPath: "../../priv/contract_vectors/navigation_topology_vectors.json", relativeTo: ...)` and `"CW-VECTOR-LOADED expected 5"`, `$0.id == "synthetic_authorized_root"` | The ledger's consumer columns for topology must read: Elixir yes, Swift yes (1 of 5 executed), Android no consumer. Derive the Swift cell by scanning for the file name; never hand-declare. The D-06 two-sided registry must include this Swift reader or its own "no undeclared consumer" scan fails on day one |
| C5 | D-09: fix 6 `keys()` call sites | There are 3 `.keys()` call sites (lines 85, 99, 146 of `BridgeConformanceTest.kt`); each is followed by an `associateWith { x.getString(it) }` line, which is why six line numbers appear | [VERIFIED: file read] and [VERIFIED: scratch run] swapping the dependency and replacing `.keys().asSequence()` with `.keys().asSequence().map { it as String }` at those 3 sites compiled and passed 12/12 | Edit 3 sites. `android-json`'s `keys()` is a raw `Iterator`; the production `toStringMap` still works at runtime (verified, see C18) |
| C6 | D-12: `SemVerBoundaryTest` includes "negative/overflow fails closed" | Overflow does fall back to raw string equality (fail-closed unless the strings are byte-equal). Negative components are NOT rejected: `Int.toIntOrNull` parses them, so `-1.0.0` is a valid version and a demand of `-1.0.0` is satisfied by `0.0.0`. A leading `+` also parses | [VERIFIED: scratch run, JVM] `SemVer.compatible("-1.0.0","0.0.0")=false`; `("0.0.0","-1.0.0")=true`; `("+1.0.0","1.0.0")=true`; `("2147483647.0.0","-1.0.0")=false` (by accidental `Int` subtraction overflow); `("99999999999.0.0","1.0.0")=false`; `("99999999999.0.0","99999999999.0.0")=true`; `("1.0.0-beta","1.0.0")=false` and the reverse `=false`; `("1.0.0-beta","1.0.0-beta")=true`; `("1.0.0.0","1.0.0.0")=true`; `("1","1.0")=true`; `("abc","abc")=true`. Source: `SemVer.kt:55-61` `val ints = parts.mapNotNull { it.toIntOrNull() }` and `:69` `val diff = a[i] - b[i]` | Decision needed (Open Question 1). Recommended: a two-line hardening in `SemVer.parse` (accept only `^[0-9]+$` per part; this also rejects `+`, and removes the subtraction-overflow accident because components are then non-negative) so the stated "fails closed" holds, consistent with D-11's fail-closed hardening and with Elixir's `Version.parse` returning `:error` for such input [ASSUMED: Elixir behavior not run this session]. If the user declines production changes to `SemVer`, the test must instead be named as a characterization of current behavior |
| C7 | D-13: hook `check_kotlin_test_floor.py` "after the Gradle run in the android-package-proof stage" | The stage record schema is closed (`stageKeys` is a fixed list in `verify_repository.mjs`), `argv` is one fixed command with no shell syntax, and `test/js/repository_verification.test.mjs:1072` pins `assert.deepEqual(androidStage.argv, ["./gradlew", "--no-daemon", "test"])` | [VERIFIED: `verify_repository.mjs:16`, `:877-879`; `repository_verification.test.mjs:1072`; stage JSON read] | Two workable options, recommended first. (A, recommended) add a separate step to the existing `android-package-unit` job right after `script/verify_repository.sh --stage android-package-proof`, running `python3 script/check_kotlin_test_floor.py --run` (the checker forces `cleanTestDebugUnitTest testDebugUnitTest` itself, about 20 s) and add `python3 script/check_kotlin_test_floor_test.py` to the same job. No schema or pin changes. (B) change the stage `argv` to the checker wrapper and update the pin at `:1072` plus any evidence-capture references. Option A loses local `verify_repository.sh --all` coverage; document the one-command local form `python3 script/check_kotlin_test_floor.py --run` in the job's remediation line |
| C8 | D-22: "`canonical/0` validates each row" | `CapabilityMap.canonical/0` today builds rows through `row/1` and only `first_adopter_claims/0` pipes through `validate_adoption_claim!`. Rows are not validated at all. Also three Android-evidence vocabularies already exist | [VERIFIED: `capability_map.ex:176-215`, `:595-606`] and [VERIFIED: `support_matrix.ex:399` `evidence_tier: :jvm_hermetic`; `:1212` hint listing `:jvm_hermetic, :emulator_advisory, or :none`; legend rows at `support_matrix/renderer.ex:248-250` "JVM hermetic proof", "emulator evidence", "device evidence"] | Adding `validate_android_evidence!` to `canonical/0` is new code, not a one-line addition. Reuse the existing atom `:jvm_hermetic` and the three existing legend labels so no new label taxonomy appears (BEARINGS do-not-reopen). Record the mapping from the new `@android_evidence_order` atoms (`:emulator`, `:device`) to the older `verification_method` atoms (`:emulator_advisory`, `:device_verified`) in a code comment so a reader does not see two unrelated vocabularies |
| C9 | D-05/D-08: add two native constant paths to `generated_contracts[0].output_paths`; update phase166 pin (~195) and `repository_verification.test.mjs` (~54) | Both the legacy record and the docs-sync record are pinned by exact equality; `output_paths` must also stay sorted and unique (checked by the verifier). The docs record needs `guides/parity_ledger.md`. The contract.gen record needs the two constant files | [VERIFIED: `phase166_repository_quality_test.exs:167-199` read; `verify_repository.mjs:858` `contract.output_paths.join("\0") !== [...contract.output_paths].sort().join("\0")`; `repository_verification.test.mjs:52-57` read] | Edit: `repository_artifact_policy.json` (both records), `phase166_repository_quality_test.exs` (both asserts), `repository_verification.test.mjs` (the multi-record fixture), `mix.exs` extras and `groups_for_extras` (the guide is listed in two places, `mix.exs:137` area and `:202` area). Keep `output_paths` in byte-sorted order (the verifier rejects unsorted lists). For example `.../Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json` sorts before `.../Tests/CrosswakeShellCoreTests/VectorSetHash.swift` (`R` < `V`), and `.../src/test/java/...` sorts before `.../src/test/resources/...` (`j` < `r`); compute the order with a sort rather than by eye |
| C10 | D-24: backstop regexes; "support matrix has ~11 Android lines mentioning emulator/device/verified" | Measured with the two proposed patterns: 0 hits in `capability_map.md` and `native_shell.md`, 2 hits in `support_matrix.md` (lines 242 and 287), both legitimate negations or a gated-rule identifier. Separately the EXISTING pattern `\b(emulator evidence\|device evidence\|JVM hermetic proof)\b.*\bsupport\b` will fire on any capability-map row that carries a `JVM hermetic proof` cell followed by text containing the word `support` (7 of the 25 current rows contain `support`, for example "support-matrix diagnostics") | [VERIFIED: ran both regexes over the three guides, python `re` case-insensitive; line 242 is the `shell.android.device_verified` rule row, line 287 is "that posture is not device-verified"; existing pattern read at `native_evidence_drift_test.exs:369`] | Reword line 287's source (the renderer) rather than loosen the test (D-24). For line 242 either reword the `shell.android.device_verified` rule text (D-25 allows) or add a negation lookbehind to the regex. When choosing which capability-map rows get `:jvm_hermetic`, run the existing scanner over the rendered guide first; give `:jvm_hermetic` only to rows (bridge/shell-core) whose later cells avoid the word `support`, or render the Android cell so it does not share a line-scan hit. Record the measured counts (0, 0, 2 plus the 7-row exposure) before making the scan merge-blocking |
| C11 | D-05/D-12: Phase 196 controls untouched | A hash check in every native loader fires BEFORE the Phase 196 mutation controls' intended diagnostics (`CW-VECTOR-LOADED expected 15`, `CW-VECTOR-COMPLETED ...`). Phase 196 `vector-controls.mjs` asserts the intended diagnostic text for its removed/empty/all-excluded mutations | [VERIFIED: `vector-controls.mjs:300-304` read: `assert.ok(result.output.includes(diagnostic), 'intended-diagnostic-missing')`; `:410-424` Kotlin specs pin `symbol: 'all bridge contract vectors pass status and denial-reason assertions'`, `testCount: 3`, `loaded: 15`, `completed: 14`] | Re-running Phase 196's controls after Phase 198 will report `intended-diagnostic-missing` for mutated-corpus cases. That is the stronger gate working, not a regression: record it as superseded phase history (the script lives under `.planning/`, no test or CI step runs it; verified by grep of `test/` and `script/`). Preserve in `BridgeConformanceTest`: the test name `all bridge contract vectors pass status and denial-reason assertions`, `testCount` of 3 in that class, and the `CW-VECTOR-MISSING` diagnostic on a missing resource (the hash helper must run after the missing-resource check) |
| C12 | D-15/D-17(3): the generated settings has no `mavenLocal()` or `include` | Confirmed for the PUBLISHED generator. Note the published 0.2.11 generator emits `template_version: 3`; head emits `@template_version 4`. The foreign host therefore proves the published generator's output, not head's | [VERIFIED: local run] generated `settings.gradle` header `// Generated by crosswake 0.2.11 (template_version: 3)`, no `mavenLocal()`, ends `include ':app'`; `crosswake.gen.shell.ex:34` `@template_version 4`; the app line is `implementation("io.github.sztheory:crosswake-shell-core-android:0.2.11")` | D-17(3) works as written. State in the evidence that it is the published generator. Assertions must match both template versions (anchor on the `implementation("...")` line, not on header text). When 0.2.12 publishes, the leg exercises template_version 4 automatically |
| C13 | D-08 vs D-25: the new guide carries the D-26 qualifier and joins `unreleased_claim_qualifier_test.exs` `@claims`, yet D-25 says the new text names no `:ios_host` or `1.2.0` | `@claims` is `{guide, token}` pairs and the test requires every section mentioning the token to carry `not in a published release yet` and `[Unreleased]` | [VERIFIED: `unreleased_claim_qualifier_test.exs:23-33` read] | The planner must pick a token that exists in the guide, for example `vector-set hash`, and confirm CHANGELOG `[Unreleased]` exists. The token is arbitrary; its job is to make the qualifier mandatory and the removal in Phase 199 mechanical. Also add the guide to the Phase 199 SC6 removal list (ROADMAP edit through a recorded roadmap change) |
| C14 | D-05: "Swift `setUp`s" | Five Swift suites load the corpus: `BridgeConformanceTests`, `BridgeReplyLegTests`, `ActivationConformanceTests`, `OfflineIslandAdmissionTests`, `Phase180TwinFeasibilityTests`. Three Kotlin suites load it: `BridgeConformanceTest`, `BridgeReplyLegTest`, `ActivationConformanceTest` (`CrosswakeShellConfigTest` does not) | [VERIFIED: grep of `forResource: "bridge_contract_vectors"` in `Tests/`; `vector-controls.mjs:316-323` reader inventory rows] | Eight loader call sites to change in total. Phase 196's 17-row reader inventory (`vector-controls.mjs:310-330`) is the existing precedent for a consumer registry; the ledger registry should cover the six native and two Elixir behavioral readers and may cite that inventory rather than re-deriving structural readers (contract_drift, publish_readiness, etc.) |
| C15 | D-20: "reads Crosswake CI run history" | `crosswake-ci.yml` triggers on `pull_request` only (no push or schedule). A run's `head_sha` is the PR head; GitHub also tests a synthetic merge commit | [VERIFIED: `.github/workflows/crosswake-ci.yml:1-8` read: `on:\n  pull_request:`] | "Two clean runs" means two PR runs on distinct PR head SHAs. The promotion script must report `head_sha` (what the PR contained) and say CI ran on the synthetic merge (AGENTS.md "say which commit CI actually ran on"). Docs-only PRs skip the job (`classification == 'full_proof'`), which D-20 already treats as neither clean nor reset |
| C16 | (not in CONTEXT) | Phase 197's PR 268 is open and unmerged, and this work edits the same guides (`guides/capability_map.md`, `guides/support_matrix.md`, their renderers, `unreleased_claim_qualifier_test.exs`) | [VERIFIED: STATE.md `Exact Next Action` read; `git status` shows branch `docs/197-public-docs-truth`] | Branch Phase 198 from current `origin/main` after PR 268 merges (AGENTS.md "branch from current origin/main"). Doing renderer work before then guarantees rebase conflicts in the D-26 qualifier paragraphs |
| C17 | D-16: optional `X.Y.Z` override | Registry facts at research time | [VERIFIED: curl] Maven `maven-metadata.xml` lists `0.1.2, 0.2.0, 0.2.1, 0.2.8, 0.2.9, 0.2.10, 0.2.11` with `<release>0.2.11</release>`; Hex `crosswake` releases begin `0.2.11, 0.2.10, 0.2.9, 0.2.5, 0.2.4, 0.2.3` (Hex has releases Maven lacks, so the intersection rule is load-bearing); `.aar.sha256` for 0.2.11 returns HTTP 200 with `ce617279241c22024a92b06fdc45191759cabf3d7eb33aa82409c080b7870226`; the downloaded AAR's `shasum -a 256` equals that value | Highest-on-both today is 0.2.11. Compare versions numerically per component, not as strings (`0.2.9` vs `0.2.11`). Hex release objects may carry a `retired` field [ASSUMED]; decide whether to skip retired versions |
| C18 | D-09/D-11: Crockford is stricter than the device; JSON null accepted as a string today | Confirmed for the AOSP-derived library the swap installs. `getString` coerces numbers, JSON null (to the 4-character string `null`) and objects. Duplicate keys: last wins; comments and single-quoted keys parse; trailing text after the object is ignored; `[]` and `""` throw `JSONException`. Map values in `capabilities` and `payload` are also coerced (`{"n":5}` gives `"5"`, `{"z":null}` gives `"null"`, a nested object gives its JSON text) | [VERIFIED: scratch run with `com.vaadin.external.google:android-json:0.0.20131108.vaadin1`] probe output: `getString(null) => null` (printed from a Kotlin `String`, no NPE, so the value is the string `null`), `getString(num) => 5`, `getString(obj) => {"b":1}`, `dupkey => y`, `comment => x`, `trailing garbage => app.info.get`, `single-quote keys => b`, `array body => THROW JSONException`, `empty body => THROW JSONException`, `version number => 1`, `full env w/ maps => {a=1, z=null, n=5}{k={"x":1}}` | D-11 hardens only the 9 required string fields; map-value coercion stays and must be characterized, not "fixed" (payload stringification is explicitly unchanged in D-11). Swift decodes the same fields through `Codable` `String`, which rejects non-strings (`BridgeChannel.swift:43-55`), so D-11 is parity with iOS and A1-compatible |

## Architectural Responsibility Map

No browser or CDN tier is involved. The tiers here are repository components.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vector-set hash computation and constants | Elixir generator (`mix crosswake.contract.gen`) | Native test targets (Swift, Kotlin) | The generator already owns the three byte-identical corpus copies; native sides only assert their copy equals the constant |
| Parity ledger rendering and no-diff gate | Elixir renderer (`Crosswake.ParityLedger.Renderer`) via `docs.sync` | CI `docs.sync --check` step | Same projection pattern as the capability map and support matrix |
| Android evidence ceiling | `Crosswake.SupportMatrix` (typed owner) | Capability map and ledger renderers; ExUnit scanners | Typed owner prevents hand-pasted copies of the boundary sentence |
| JVM behavioral tests for the bridge boundary | Kotlin package `crosswake-shell-core-android` | Python floor checker | Behavior lives in Kotlin; the count and non-vacuity guard is a repository script |
| Foreign-host resolution proof | Bash script + Gradle in a throwaway project | CI advisory job; Python selftest | Needs real registries and a real Gradle build, so it stays out of the hermetic lane (BEARINGS invariant 10) |
| "Two clean runs" promotion derivation | GitHub Actions run history read by a script | `script/bearings_report.exs` line | Derived from CI, never hand-stamped (BEARINGS tripwire) |

## Standard Stack

### Core (all already in the repo; no new runtime dependency anywhere)

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| Gradle (wrapper-less custom `gradlew`) | 8.7 | Builds the core package and generated shell | [VERIFIED: `gradle-wrapper.properties` in package and template: `distributionUrl=...gradle-8.7-bin.zip`] |
| Android Gradle Plugin | 8.4.1 | `com.android.library` / `application` | [VERIFIED: `settings.gradle.kts` pluginManagement and template `build.gradle.eex`] |
| Kotlin | 1.9.24 | Core package language | [VERIFIED: same files] |
| JUnit | 4.13.2 | JVM test runner | [VERIFIED: `build.gradle.kts:45`] |
| JDK | Temurin 17 on CI; Homebrew `openjdk@17` locally | Gradle toolchain | [VERIFIED: `setup-android-jvm/action.yml` default `java-version: "17"`; local run with `JAVA_HOME=/opt/homebrew/opt/openjdk@17`] |
| ExUnit, Jason | repo versions | Elixir tests and JSON encode (generator already uses Jason pretty output) | [VERIFIED: `crosswake.contract.gen.ex` `Jason.encode!(pretty: true)`] |
| Python stdlib (`unittest`, `xml.etree.ElementTree`, `hashlib`, `subprocess`) | 3.12+ on ubuntu-latest [ASSUMED: runner Python minor], 3.14.4 locally | Floor checker, selftests (precedent `verify_android_public_build_test.py`) | [VERIFIED: that file read] |
| bash, curl, jq, shasum/sha256sum | system | Foreign-host script | [VERIFIED: present locally; `verify_published_cleanroom.sh` uses the same] |

### Changed dependencies (CONTEXT D-09, D-10)

| Change | Detail | Verification |
|--------|--------|--------------|
| Test dep swap | `org.json:json:20231013` becomes `com.vaadin.external.google:android-json:0.0.20131108.vaadin1` (Apache-2.0) | [VERIFIED: resolves from Maven Central, POM license read; scratch build green 12/12] |
| Removal | `kotlinx-serialization-json:1.6.0` and the `org.jetbrains.kotlin.plugin.serialization` plugin from `build.gradle.kts` | [VERIFIED: scratch build green after removal (12/12); `grep -rn "kotlinx.serialization\|@Serializable" src` returned no match, so no source uses it] |
| Keep | `androidx.webkit:webkit:1.10.0` | [VERIFIED: `BridgeChannel.kt:4-5` imports `androidx.webkit.WebMessageCompat` and `androidx.webkit.WebViewCompat`; `:60` calls `WebViewCompat.addWebMessageListener`] |

Also edit the stale comment at `build.gradle.kts:42`, "Note: Android bridge may use WebKit/WebView and we might need androidx.webkit", to say it is imported by `BridgeChannel.kt` (`addWebMessageListener`). Leave the `settings.gradle.kts` `pluginManagement` plugin declaration for `kotlin.plugin.serialization` or remove it in the same edit; it is unused either way (the scratch build passed with it present). Keep line 10 `version = "0.2.11" // x-release-please-version` byte-intact: release-please and `release-please.yml:109-110` (`gradle_version_at ... build.gradle.kts`) parse it.

### Alternatives considered (all rejected by CONTEXT, listed so the planner does not reopen them)

| Instead of | Could use | Why not |
|------------|-----------|---------|
| Platform `org.json` in production | kotlinx.serialization | Rewrites about 8 files, keeps a runtime dependency, changes the POM, no demonstrated defect (D-09) |
| Raw-byte sha256 | Canonical-JSON hash | Three new bug surfaces; generator already emits sorted-key bytes (D-04) |

**Installation:** no install step. Verification: `cd packages/crosswake-shell-core-android && JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew --no-daemon cleanTestDebugUnitTest testDebugUnitTest` (about 20 s warm; measured 17-24 s).

## Package Legitimacy Audit

The `package-legitimacy` seam covers npm, PyPI and crates only; the one added artifact is a Maven coordinate, so the seam was not applicable and no seam verdict exists. Checks done by hand against Maven Central.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `com.vaadin.external.google:android-json:0.0.20131108.vaadin1` | Maven Central | one version, `lastUpdated` 2014-03-03 | not available from Maven Central | POM url `developer.android.com/sdk` (AOSP-derived; no GitHub repo) | no seam verdict; manual: name locked by CONTEXT D-09, POM license Apache License 2.0, resolves, scratch build green | Approved, test scope only, never in the published POM. No `checkpoint:human-verify` (AGENTS.md zero-human default: the check is automated, resolution plus green tests) |
| `kotlinx-serialization-json:1.6.0` | Maven Central | n/a | n/a | JetBrains | n/a | REMOVED from the core package (dead dependency) |
| `org.json:json:20231013` | Maven Central | n/a | n/a | stleary/JSON-java | n/a | REMOVED from test scope |

**Packages removed due to [SLOP] verdict:** none (seam not applicable to Maven)
**Packages flagged as suspicious [SUS]:** none; the single-version, 2014-era publish is a stability note for a test-only artifact, not a supply-chain signal. The Maven Central POM and license were read, but whether the artifact is the same code used transitively by other test stacks is [ASSUMED].

## Architecture Patterns

### System Architecture Diagram

```
                           ┌────────────────────────────────────────────────────────┐
 mix crosswake.contract.gen│ writes 3 byte-identical corpus copies + 2 constant files│
 (Elixir, hermetic)  ─────►│  test/fixtures/bridge_contract_vectors.json            │
                           │  iOS Tests/.../Resources/...json                       │
                           │  Android src/test/resources/...json                    │
                           │  iOS  Tests/CrosswakeShellCoreTests/VectorSetHash.swift│
                           │  Kotlin src/test/java/.../core/VectorSetHash.kt        │
                           └──────────────┬─────────────────────────────────────────┘
                                          │ sha256 of RAW bytes (D-04)
        ┌─────────────────────────────────┼──────────────────────────────────┐
        ▼                                 ▼                                  ▼
 Swift loaders (5 suites)         Kotlin loaders (3 suites)          Elixir ParityLedger
 CryptoKit SHA256 == constant     MessageDigest SHA-256 == constant   reads 3 copies + constants
 else fail                        else fail                           + scans consumers
        │                                 │                                  │
        │                                 │                                  ▼
        │                                 │            mix crosswake.docs.sync ──► guides/parity_ledger.md
        │                                 │                         │ (--check in CI docs job = no-diff gate)
        │                                 │                         ▼
        │                                 │            parity_ledger_test.exs: copies equal, constants match,
        │                                 │            registry two-sided, negative controls
        ▼                                 ▼
  swift test (iOS lane)         ./gradlew testDebugUnitTest ──► XML ──► check_kotlin_test_floor.py
                                (android-package-unit job)               (>=25, 0 fail/skip, derived equality)

 Foreign-host leg (advisory CI job, networked):
 Hex+Maven registries ─► pick V (highest non-prerelease on BOTH) ─► verify_android_release_host.sh (unchanged)
   ─► generated project ─► asserts: implementation line == group:artifact:V; settings has no mavenLocal/include
   ─► fresh HOME + GRADLE_USER_HOME, drop cached io.github.sztheory, write ForeignHostResolveTest.kt
   ─► gradlew --refresh-dependencies :app:testDebugUnitTest ─► app/build/test-results XML (tests>=1)
   ─► AAR sha256 == Maven .aar.sha256 ─► negctl copy (artifactId+"-negctl") ─► must fail "Could not find ..."
   ─► evidence JSON artifact ─► android_foreign_promotion.sh (derives clean_runs=N/2 from run history)
```

### Recommended Project Structure (new or changed files)

```
lib/crosswake/parity_ledger.ex                      # source: corpus facts, consumer registry, compare_references/1
lib/crosswake/parity_ledger/renderer.ex             # mirrors CapabilityMap.Renderer render/0 + write/0
lib/mix/tasks/crosswake.docs.sync.ex                # third projection
lib/mix/tasks/crosswake.contract.gen.ex             # + VectorSetHash.swift / .kt writers
lib/crosswake/support_matrix/support_matrix.ex      # + android evidence ceiling API (D-21)
lib/crosswake/capability_map.ex (+ renderer.ex)     # + :android_evidence field, column (D-22)
guides/parity_ledger.md                             # generated
.gitattributes                                      # new file; narrow patterns only (text eol=lf)
packages/crosswake-shell-core-android/
  build.gradle.kts                                  # dep swap, serialization removal, comment fix
  src/main/.../BridgeChannel.kt                     # requireString, parseBody, listenerAllows
  src/main/.../SemVer.kt                            # (if Open Question 1 = harden)
  src/test/.../BridgeChannelBoundaryTest.kt         # ~14-16 tests
  src/test/.../SemVerBoundaryTest.kt                # 5 tests
  src/test/.../BridgeFixtures.kt                    # copied makeSession/makeRequest
  src/test/.../VectorCorpus.kt                      # handwritten loadVerifiedBytes()
  src/test/.../VectorSetHash.kt                     # GENERATED
packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/
  VectorSetHash.swift (GENERATED), VectorCorpus.swift (handwritten loader helper)
script/verify_android_foreign_host.sh               # + verify_android_foreign_host_test.py
script/check_kotlin_test_floor.py                   # + check_kotlin_test_floor_test.py
script/android_foreign_promotion.sh
script/check_ci_leaf_manifest.py                    # ADVISORY_JOBS loop
.github/workflows/crosswake-ci.yml                  # android-foreign-host job + extra steps
test/crosswake/parity_ledger_test.exs
test/crosswake/guides/android_claim_ceiling_test.exs
```

### Pattern 1: Hash the bytes, compare in the loader (Kotlin)

**What:** one handwritten helper that every Kotlin loader calls; the constant is generated.
**When:** all three Kotlin suites that load the corpus (C14).
**Example:**
```kotlin
// src/test/java/dev/crosswake/shell/core/VectorSetHash.kt  (GENERATED by mix crosswake.contract.gen)
package dev.crosswake.shell.core
internal object VectorSet { const val SHA256 = "<64 lowercase hex>" }

// src/test/java/dev/crosswake/shell/core/VectorCorpus.kt  (handwritten)
package dev.crosswake.shell.core
import java.security.MessageDigest
internal object VectorCorpus {
    fun loadVerifiedBytes(): ByteArray {
        val stream = VectorCorpus::class.java.getResourceAsStream("/bridge_contract_vectors.json")
            ?: throw AssertionError("CW-VECTOR-MISSING bridge_contract_vectors.json")  // keep the 196 diagnostic first
        val bytes = stream.use { it.readBytes() }
        val actual = MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it) }
        if (actual != VectorSet.SHA256) {
            throw AssertionError("CW-VECTOR-HASH expected ${VectorSet.SHA256} got $actual")
        }
        return bytes
    }
}
```
Source: JDK `MessageDigest`, local scratch verification of the surrounding build; the helper itself is a design sketch, not run [ASSUMED]. Use `bytes.toString(Charsets.UTF_8)` for the JSON text so parsing sees exactly the hashed bytes.

### Pattern 2: Fail-closed required-string extraction (Kotlin, D-11)

```kotlin
// BridgeChannel.kt  (replace json.getString(...) in the BridgeRequestEnvelope(JSONObject) constructor)
private fun JSONObject.requireString(name: String): String {
    val value = opt(name)
    if (value !is String) throw org.json.JSONException("$name must be a JSON string")
    return value
}
```
Why `opt(...) is String`: under the AOSP-derived library `getString` returns `"null"` for JSON null and coerces numbers (C18), so a `getString`-based check cannot reject them. `JSONObject.NULL` is not a `String`, so it is rejected. Nine required fields: `protocol, version, command, capability, route_id, active_route_id, origin, native_runtime_version, correlation_id` [VERIFIED: `BridgeChannel.kt:368-377` read].

Extractions (internal, no WebView needed):
```kotlin
internal fun parseBody(body: String?): BridgeRequestEnvelope? {
    val text = body ?: return null
    return try { BridgeRequestEnvelope(JSONObject(text)) } catch (_: Exception) { null }
}
internal fun listenerAllows(isMainFrame: Boolean, sourceOrigin: String): Boolean =
    isMainFrame && sourceOrigin == session.allowedOrigin
```
`attach` keeps its behavior: `parseRequest` becomes `parseBody(message.data)`; the origin guard calls `listenerAllows(isMainFrame, sourceOrigin.toString())` [VERIFIED current logic: `BridgeChannel.kt:65-77`]. The existing silent drop on an unparseable body stays and is recorded as intentional (no correlation id to echo).

### Pattern 3: Ledger renderer mirrors CapabilityMap.Renderer

`render/0` returns a binary; `write/1` returns `{:ok, :created | :reused | :updated}`; `docs.sync` gets a third projection map `%{source:, target:, render:, write:}` [VERIFIED: `capability_map/renderer.ex:140-170` pattern and `crosswake.docs.sync.ex:73-91` read]. The `--check` branch needs no change. Read the corpus and native constants at run time, never at compile time (Hex consumers compile `lib/` without `packages/`).

### Pattern 4: Foreign-host script contract

Copy the output contract of `verify_published_cleanroom.sh` [VERIFIED: header read]: exit 0/1/2, `curl --max-time ... --retry ... --proto =https`, lines `foreign-host: leg <name> PASS ...`, `foreign-host: FAIL <leg> <reason>`, `foreign-host: result PASS|FAIL`, selftest overrides honored only under a selftest flag. Reasons to implement: `not_published`, `resolve_failed` (separate, per Phase 195 WR-05), `no_tests`, `settings_mismatch`, `coordinate_mismatch`, `aar_checksum_mismatch`, `control_passed`, `control_inconclusive`, `control_wrong_reason`.

Environment for the Gradle steps (verified working locally): `env HOME=<fresh> GRADLE_USER_HOME=<fresh>/.gradle JAVA_HOME=... ANDROID_HOME=<runner sdk> ./gradlew --no-daemon --refresh-dependencies :app:testDebugUnitTest`, with `<fresh>/.crosswake/gradle` pre-seeded from the cached Gradle 8.7 distribution (the custom `gradlew` caches the distribution under `$HOME/.crosswake/gradle`, not under `GRADLE_USER_HOME`: [VERIFIED: `gradlew.eex:12`]). Seeding the distribution does not weaken the proof, since it is not the artifact under test. Host generation (mix, asdf) must run under the REAL HOME; only the Gradle steps get the fresh one. No `local.properties` was needed: `ANDROID_HOME` alone worked [VERIFIED: local run].

### Anti-Patterns to Avoid

- **Counting `./gradlew test`:** it runs debug and release; summing double-counts (D-13). Count only `testDebugUnitTest`, forced with `cleanTestDebugUnitTest`.
- **`:app:dependencies` as the negative control:** exits 0 with FAILED text (D-18). Use `:app:testDebugUnitTest`.
- **Asserting the AAR path from the test JVM** (C1).
- **Authoring the ledger's Android cell:** D-23 requires it computed (`:jvm_hermetic` only when hashes match and the registry confirms execution).
- **Hand-pasting the Android boundary sentence again:** the five current copies are textually different (`support_matrix.ex:446`, `:473`, `renderer.ex:380`, `:401`, capability-map renderer "Android is unfrozen only for proof and parity of existing contracts"), and `renderer_test.exs:56` and `:425` pin the long form verbatim; D-21 `android_boundary/0` must keep the pinned wording or those two pins move together with it.
- **Citing line numbers in new allowlists or tests** (BEARINGS: key by file plus normalized text). The line numbers in this document are research pointers only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Generated-doc no-diff gate | New CI step | `mix crosswake.docs.sync --check`, already in the docs job (`crosswake-ci.yml:122`) | One new projection entry gets the gate for free |
| Markdown table parsing for the ceiling test | Regex-per-line scanner | A header-driven parser in `android_claim_ceiling_test.exs` (D-23) with a non-empty floor | A line regex cannot distinguish the Android column from other columns |
| JUnit XML counting | Gradle console parsing | `xml.etree.ElementTree` over `TEST-*.xml` | Phase 196 already rejects console totals (`vector-controls.mjs:406`) |
| Maven/Hex version intersection | Hardcoded version | `maven-metadata.xml` plus `https://hex.pm/api/packages/crosswake` (both anonymous, both verified) | D-16; numeric component compare |
| Wrong-coordinate failure detection | `curl` for status only | Gradle build exit plus both message substrings (C3) | Distinguishes "absent" from "offline" |
| SHA-256 | Custom | `hashlib`/`shasum -a 256`/`:crypto.hash(:sha256, ...)`/`MessageDigest`/`CryptoKit` | Stdlib on all four platforms |
| Host project generation | New generator | `script/verify_android_release_host.sh --version V --host-root D --target D` unchanged (D-15) | Verified: generates under `$target/native/android/crosswake_shell/` |

**Key insight:** the phase's value is in the guards (non-empty floors, mutations that go red, reason-specific failures), not in the happy path. Every new check below ships with the mutation that turns it red.

## Runtime State Inventory

Not a rename/migration phase. Omitted. One adjacent fact for the planner: the published POM for `crosswake-shell-core-android` changes only at the NEXT publish (D-10), so nothing registered in Maven Central, Hex or hosts changes during this phase.

## Common Pitfalls

### Pitfall 1: The probe test passes while testing nothing
**What goes wrong:** the generated app has no `app/src/test`; `testDebugUnitTest` reports NO-SOURCE and exits 0.
**How to avoid:** write the host-owned `ForeignHostResolveTest.kt` (shape verified: `package dev.crosswake.shell`, probe `CrosswakeShellConfig`, a public pure-Kotlin data class [VERIFIED: `CrosswakeShellConfig.kt`]); require `tests >= 1`, no failures, errors or skips in `app/build/test-results/testDebugUnitTest/*.xml`, else `no_tests`. `testImplementation 'junit:junit:4.13.2'` is already in the generated app [VERIFIED: template line 70].
**Warning sign:** `NO-SOURCE` in Gradle output.

### Pitfall 2: A warm cache fakes the fetch
**How to avoid:** fresh `GRADLE_USER_HOME`, delete `caches/modules-2/files-2.1/io.github.sztheory` before the positive build, `--refresh-dependencies`, and the AAR byte check (D-17). On a developer machine `~/.m2/repository/io/github/sztheory` exists (found locally) but the generated settings has no `mavenLocal()`; the settings check (D-17(3)) is what proves it cannot be used.

### Pitfall 3: Control fails for the wrong reason
**How to avoid:** classification table verified in C3. Preconditions: 404 on the bad `.pom`, `--dry-run` exit 0, positive leg already passed with the same `GRADLE_USER_HOME`. Treat `Could not GET`, `UnknownHost`, `Read timed out`, `Connection` as `control_inconclusive`.

### Pitfall 4: Stale or double-counted JUnit XML
**How to avoid:** `cleanTestDebugUnitTest testDebugUnitTest`; derived equality of XML count and non-`@Ignore` `@Test` count; known multiplier traps are the data-driven vector test (one `@Test`, one XML testcase, 14 internal vectors) and any future `Parameterized` runner (D-12 forbids converting).

### Pitfall 5: `SemVer` tests asserting what the code does not do
See C6. Write each expectation from the measured table, and decide Open Question 1 before authoring `SemVerBoundaryTest`.

### Pitfall 6: Characterizing the device with a stand-in
`android-json` is AOSP-derived, not the device. Every doc line and test name must say JVM, never "on Android" (D-07 vocabulary: "JVM test executed"; the ledger test rejects `emulator`, `device-verified`, `supported on Android`).

### Pitfall 7: Unchecked hash churn
The three corpus copies are produced by Jason pretty-printing with an explicit "fewer than 32 keys" ordering assumption [VERIFIED: `crosswake.contract.gen.ex` comment block read]. A Jason upgrade or a generator edit changes all three copies and the hash together; the constants and ledger must be regenerated in the same commit (`mix crosswake.contract.gen && mix crosswake.docs.sync`). The no-diff gate and the three-copy equality test catch a forgotten regeneration.

### Pitfall 8: Windows/CRLF would break byte hashes
No `.gitattributes` exists today [VERIFIED: `ls .gitattributes` fails]. Create it with only the narrow patterns (the three corpus copies, `priv/contract_vectors/*.json`, and the two generated constant files), not a global `* text=auto`.

### Pitfall 9: Release-parse regression
Edits to `build.gradle.kts` must keep the `version = "..." // x-release-please-version` line and the `coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())` call intact; the foreign-host script reads the coordinate from that call (D-16) and release-please reads the version line.

### Pitfall 10: Advisory job accidentally becomes authority
`check_ci_leaf_manifest.py` must keep refusing `continue-on-error`, `|| true`, umbrella membership and compatibility-projection membership for every advisory job; tests at `phase165_ci_integrity_test.exs:137-157` assert brand-visual specifically and need a sibling assertion for the new job.

## Code Examples

### Verified: foreign-host probe test (host-owned, written by the script)
```kotlin
// app/src/test/java/dev/crosswake/shell/ForeignHostResolveTest.kt
// VERIFIED shape: this exact structure passed against published 0.2.11 (local run).
// The script must additionally template V and GRADLE_USER_HOME and assert as in C1.
package dev.crosswake.shell

import dev.crosswake.shell.core.CrosswakeShellConfig
import org.junit.Assert.assertTrue
import org.junit.Test

class ForeignHostResolveTest {
    @Test
    fun coreComesFromResolvedArtifact() {
        assertTrue(CrosswakeShellConfig().registeredCapabilities.isEmpty())
        val loc = CrosswakeShellConfig::class.java.protectionDomain.codeSource.location.toString()
        assertTrue(loc, loc.contains("crosswake-shell-core-android"))
        // add: loc startsWith file:<GRADLE_USER_HOME>/caches/ and endsWith crosswake-shell-core-android-<V>-runtime.jar
    }
}
```

### Verified: AAR byte check
```bash
# VERIFIED locally: both sides equal ce617279...0226 for 0.2.11
want="$(curl --fail --silent --max-time 60 --proto =https \
  "https://repo.maven.apache.org/maven2/io/github/sztheory/crosswake-shell-core-android/${V}/crosswake-shell-core-android-${V}.aar.sha256")"
aar="$(find "$GRADLE_USER_HOME/caches/modules-2/files-2.1/io.github.sztheory/crosswake-shell-core-android/$V" -name '*.aar')"
got="$(shasum -a 256 "$aar" | cut -d' ' -f1)"   # sha256sum on Linux
[ "$got" = "$want" ] || fail aar_checksum_mismatch
```
The `.sha256` file holds the bare hex digest with no file name [VERIFIED: curl output]. Use `sha256sum` on the Linux runner (BSD `shasum` exists on macOS only; the script must pick whichever exists).

### Verified: negative control and classification
```bash
# VERIFIED locally. Copy the generated project, change ONLY the artifactId, assert exactly one line changed.
sed -i.bak "s#crosswake-shell-core-android:${V}#crosswake-shell-core-android-negctl:${V}#" app/build.gradle
out="$(env HOME=... GRADLE_USER_HOME=... ./gradlew --no-daemon :app:testDebugUnitTest 2>&1)"; rc=$?
# pass iff rc != 0 AND out contains
#   "Could not find io.github.sztheory:crosswake-shell-core-android-negctl:${V}"
#   AND "Could not resolve all files for configuration"
# 'Could not GET' | 'UnknownHost' | 'Read timed out' | 'Connection'  -> control_inconclusive
# rc == 0 -> control_passed (the control did not fail: the proof is vacuous)
```
Use `sed -i.bak` (portable across GNU and BSD sed; verified with BSD sed locally; GNU accepts the same form).

### Floor checker core (design sketch, not run)
```python
# script/check_kotlin_test_floor.py  -- stdlib only
import glob, re, sys, xml.etree.ElementTree as ET
FLOOR = 25  # the one literal: a ratchet floor, not a pin of the current count
def junit_totals(dirpath):
    t = f = s = 0; per_class = {}
    files = sorted(glob.glob(f"{dirpath}/TEST-*.xml"))
    for p in files:
        r = ET.parse(p).getroot()
        t += int(r.get("tests", 0)); f += int(r.get("failures", 0)) + int(r.get("errors", 0)); s += int(r.get("skipped", 0))
        per_class[r.get("name")] = int(r.get("tests", 0))
    return t, f, s, per_class, len(files)
def source_test_count(src_dir):
    n = 0
    for p in glob.glob(f"{src_dir}/**/*.kt", recursive=True):
        text = open(p, encoding="utf-8").read()
        # count '@Test' not preceded on the previous annotation line by '@Ignore'
        n += len(re.findall(r"^\s*@Test\b", text, re.M)) - len(re.findall(r"@Ignore\b[^\n]*\n\s*@Test\b|@Test\b[^\n]*\n\s*@Ignore\b", text))
    return n
```
Controls required as fixture XML: 24 tests, one skipped, boundary class absent, zero XML files, debug plus release double-counted (D-13). Phase 196's `freshJunit`/`sumJunit` (`phase-evidence.mjs:489-504`) is the precedent for summing and freshness by mtime.

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| `org.json:json` (Crockford) on the JVM test classpath | AOSP-derived `android-json` | Closer to device coercion semantics; tests that assert rejection of non-strings become meaningful |
| `./gradlew test` count | `cleanTestDebugUnitTest testDebugUnitTest` XML | No double count, no UP-TO-DATE blind spot |

**Deprecated/outdated in this repo:** the `tests: 12` pin at `.planning/.../196-.../scripts/phase-evidence.mjs:533` is phase history (D-13): leave or annotate as superseded; do not edit `vector-controls.mjs`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Elixir `Version.parse/1` returns `:error` for `-1.0.0` and `+1.0.0`, so a Kotlin hardening matches Elixir | C6 | Hardening would diverge from Elixir instead of matching it; low (fail-closed either way) |
| A2 | ubuntu-latest has Python 3.12+ and `sha256sum`, `jq`, `curl` | Standard Stack | Script portability; trivially checked in the first CI run |
| A3 | Crockford `org.json` `getString` throws on non-string (the contrast D-09 relies on) | State of the Art | Only affects the rationale text, not behavior; the AOSP side is verified |
| A4 | Hex release objects can carry a `retired` marker the script should skip | C17 | A retired version could be picked; low (it still resolves) |
| A5 | `android-json` is the same artifact other JVM test stacks use transitively | Package Legitimacy | Supply-chain comfort only; version is pinned and test-scoped |
| A6 | CI cost of the foreign-host leg is 5-8 billable minutes (local fresh-cache build took 67 s plus Hex deps and Gradle distribution download) | Environment | Cost report after the first PR (D-19) replaces this estimate |
| A7 | `gh api` can list `Crosswake CI` runs, jobs and artifacts for the promotion script without extra scopes when the user is authenticated; artifact ZIP download needs auth even on a public repo | Open Question 4 | Promotion script might need a token in CI context; it runs locally per D-20, so low |

## Open Questions (RESOLVED)

All five questions were resolved at planning time; each resolution is recorded in `198-DECISIONS.md` (Plan 01 Task 3) and implemented by the plan named.

1. **Harden `SemVer` (reject negative and `+` components) or characterize current behavior?**
   - Known: C6 table; `SemVerBoundaryTest` as written in D-12 cannot pass for negatives without a change; D-11 already adds fail-closed production hardening.
   - Recommendation: harden (two lines in `SemVer.parse`: require `^[0-9]+$` per part). It stays inside A1 (existing contract, stricter denial) and removes the subtraction-overflow accident. Record the choice in the Phase 198 decisions. If declined, rename the tests as current-behavior characterization and log a debt row (owner, trigger, receiver).
   - **RESOLVED: harden.** Implemented by Plan 01 Task 2 (digit-only `SemVer.parse`, `SemVerBoundaryTest`). The divergence from the iOS `SemVer.swift` reference (which uses `Int(_:)` and so still accepts `+1` and `-1` components) is recorded in `198-DECISIONS.md` with a debt row (Plan 01 Task 3).
2. **Option A vs B for the floor checker hook (C7).** Recommendation: A (job step, no schema or pin edits).
   - **RESOLVED: Option A.** Implemented by Plan 03 Task 3 (separate steps in `android-package-unit`; stage argv unchanged).
3. **Capability-map "Android evidence" column placement (C8, C10).** D-22 accepts the 11th column with a fallback. Recommendation: build it, but run the existing overclaim scanner over the rendered guide before choosing which rows carry `:jvm_hermetic`; if more than a handful of rows would need rewording, use D-22's documented fallback and record it honestly.
   - **RESOLVED: build the 11th column.** Implemented by Plan 06 Task 1 (with the C10 check before choosing `:jvm_hermetic` rows).
4. **Promotion script runtime (D-20).** Confirm in plan whether it only runs locally and from `bearings_report.exs`, or also in CI. Artifact download needs authentication; the local `gh` is logged in [VERIFIED: `gh auth status`].
   - **RESOLVED: local only** (directly and through `bearings_report.exs`), because artifact download needs an authenticated `gh` and Crosswake CI is pull-request only. Implemented by Plan 10.
5. **Which token for the `@claims` entry (C13)?** Recommendation: `vector-set hash` (appears in every section that describes the hash).
   - **RESOLVED: `vector-set hash`.** Implemented by Plan 08 Task 3.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| JDK 17 | Gradle, floor checker `--run` | yes | Homebrew openjdk@17 (`JAVA_HOME=/opt/homebrew/opt/openjdk@17`) | CI uses Temurin 17 via setup-java |
| Android SDK (platform 34, build-tools) | AGP | yes | `$HOME/.crosswake/android-sdk` | CI runner SDK via `ANDROID_HOME` |
| Gradle 8.7 distribution | custom gradlew | yes | cached at `~/.crosswake/gradle/gradle-8.7` | auto-download from services.gradle.org |
| Elixir/Mix | contract.gen, docs.sync, ExUnit, host generation | yes | Mix 1.19.5 / OTP 27 | none needed |
| Python | selftests, floor checker | yes | 3.14.4 | none |
| curl, jq, xmllint | foreign-host script | yes | system | none |
| gh | promotion script, `ci_cost_report.sh` | yes, authenticated as `szTheory` | n/a | `UNVERIFIED` output per D-20 |
| swift | Swift loader changes | yes | Swift 6.3.3 | none; CryptoKit available on macOS |
| Network: Maven Central, hex.pm, dl.google.com, services.gradle.org | foreign-host leg | yes (verified this session) | n/a | the leg reports `resolve_failed`, never PASS |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir), JUnit 4.13.2 via Gradle (Kotlin), XCTest (Swift), Python `unittest` (scripts) |
| Config file | `packages/crosswake-shell-core-android/build.gradle.kts`; `Package.swift`; none for Python (precedent `verify_android_public_build_test.py`) |
| Quick run (Kotlin) | `cd packages/crosswake-shell-core-android && JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew --no-daemon cleanTestDebugUnitTest testDebugUnitTest` (about 20 s) |
| Quick run (Elixir) | `mix test test/crosswake/parity_ledger_test.exs test/crosswake/guides/android_claim_ceiling_test.exs test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/unreleased_claim_qualifier_test.exs` |
| Quick run (scripts) | `python3 script/check_kotlin_test_floor_test.py && python3 script/verify_android_foreign_host_test.py && python3 script/check_ci_leaf_manifest.py` (check how the manifest checker is invoked for its self-test before wiring) |
| Full suite | `mix test` (about 3,100 tests per STATE.md) plus `swift test` in `packages/crosswake-shell-core-ios` plus the Gradle command above |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AND-01 | Three corpus copies byte-equal; each native constant equals the corpus sha256 (anchored regex, exactly one match) | unit | `mix test test/crosswake/parity_ledger_test.exs` | Wave 0 |
| AND-01 | Swift and Kotlin reference the same hash; mismatch fails (negative controls: Swift differs, constant differs, constant file missing or regex zero matches, empty corpus, one mutated byte in a tmp copy) | unit | same | Wave 0 |
| AND-01 | Regenerate-no-diff for `guides/parity_ledger.md`; tampered tmp ledger fails `--check` | integration | `mix crosswake.docs.sync --check` and `mix test test/mix/tasks/crosswake.docs.sync_test.exs` | exists, extend |
| AND-01 | Native loaders go red on a flipped byte | one-time evidence (not CI) | flip one byte in each native resource copy, run `./gradlew test` and `swift test`, restore | phase evidence |
| AND-02 | Kotlin tests >= 25, 0 failures, 0 skipped, XML count equals `@Test` count, boundary class >= 10, named load-bearing tests present | script | `python3 script/check_kotlin_test_floor.py --run` and `python3 script/check_kotlin_test_floor_test.py` | Wave 0 |
| AND-02 | `BridgeChannel` boundary cases from D-12 | unit (JVM) | Gradle quick run above | Wave 0 |
| AND-02 | `androidx.webkit` kept with truthful comment; `kotlinx-serialization` absent from `build.gradle.kts` | unit (Elixir file-content assertion) or grep in the floor checker | add a small ExUnit or checker assertion | Wave 0 |
| AND-03 | Selftest: no tests, network-error control, control exits 0, wrong-reason control, not_published vs resolve_failed, coordinate mismatch | script | `python3 script/verify_android_foreign_host_test.py` | Wave 0 |
| AND-03 | Real run against published V; positive passes, control fails for the right reason | networked, advisory CI | `bash script/verify_android_foreign_host.sh` (CI job `android-foreign-host`) | Wave 0 |
| AND-03 | Advisory job cannot affect required authority | structural | `python3 script/check_ci_leaf_manifest.py` plus `mix test test/crosswake/proof/phase165_ci_integrity_test.exs` | exists, extend |
| SC4 | No Android evidence cell above `JVM hermetic proof`; non-empty floor; controls | unit | `mix test test/crosswake/guides/android_claim_ceiling_test.exs` | Wave 0 |

### Sampling Rate
- **Per task commit:** the quick command for the area touched (Kotlin, Elixir or scripts).
- **Per wave merge:** all three quick runs plus `mix crosswake.docs.sync --check`.
- **Phase gate:** full `mix test`, `swift test`, Gradle run, floor checker, and a measured advisory-job run (cost via `script/ci_cost_report.sh` against the 250-minute baseline) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/crosswake/parity_ledger_test.exs`
- [ ] `test/crosswake/guides/android_claim_ceiling_test.exs`
- [ ] `script/check_kotlin_test_floor_test.py` and `script/verify_android_foreign_host_test.py`
- [ ] `BridgeChannelBoundaryTest.kt`, `SemVerBoundaryTest.kt`, `BridgeFixtures.kt`, `VectorCorpus.kt` (Kotlin), `VectorCorpus.swift` (Swift)
- [ ] Framework install: none (everything is already in the repo and verified runnable)

Every new check must record a non-empty floor and the mutation that turns it red in its test (BEARINGS tripwire).

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | `LiveViewSession` is exercised only as a test fixture |
| V4 Access Control | yes | Origin and route-scope denial in `BridgeChannel` (fail closed); tests assert deny-before-side-effects with a positive control |
| V5 Input Validation | yes | D-11 `requireString` rejects non-string required fields; `parseBody` null/garbage handling; version strings through `SemVer` |
| V6 Cryptography | yes (integrity only) | SHA-256 from each platform's stdlib; never hand-rolled; used for corpus bytes and AAR bytes, not secrecy |
| V10 Malicious Code / V14 Config | yes | Foreign-host leg: no credentials, `contents: read`, https-only curl, byte-checked AAR, no `mavenLocal()` |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Origin spoofing near-misses (the userinfo-spoof origin (`https://app.example.com` followed by an at-sign and `evil.test`), trailing slash, port, case, `null`, empty) | Spoofing | Exact string equality against `session.allowedOrigin` (current behavior); boundary tests pin it |
| Request-claimed pack or capability authority | Elevation of privilege | Session-owned `installedPacks`; request-supplied packs ignored; tested |
| Sensitive data leaking into denial replies | Information disclosure | `deny()` emits `payload: {}`; test with a sentinel secret that never appears in the denial JSON |
| Dependency confusion or typosquat in the control | Tampering | Control uses a coordinate verified absent by HTTP 404 before the run; AAR sha256 equals Maven's published digest |
| Credential exposure in the advisory job | Information disclosure | No secrets, fresh HOME, no `ORG_GRADLE_PROJECT_*`, job `permissions: contents: read` (workflow default `crosswake-ci.yml:3-4`) |
| Silent degradation (a check green while asserting nothing) | Repudiation | Non-empty floors, `no_tests`, reason-specific failures, `UNVERIFIED` on any read failure |
| Sensitive offline payloads in proof artifacts | Information disclosure | Evidence JSON carries only version, SHA, counts, reason and blob hash; no payloads, tokens or device identifiers (AGENTS.md sensitive-data rules) |

Adopter-name rule: nothing in this phase needs or contains an adopter identity; the ledger, guide text and evidence must use only "first adopter" if the term appears at all.

## Sources

### Primary (HIGH confidence): executed or read this session
- Local runs (2026-11-05): baseline Gradle test 12/12 green; scratch swap (android-json, serialization removed) green; JSON and `SemVer` probes; full foreign-host flow against published 0.2.11 including AAR sha256 and negative control (scratch directory under the session scratchpad).
- Maven Central `maven-metadata.xml`, `.aar.sha256`, `android-json` POM; `https://hex.pm/api/packages/crosswake`.
- Repo files read: `BridgeChannel.kt`, `SemVer.kt`, `build.gradle.kts`, `settings.gradle.kts`, `BridgeConformanceTest.kt`, `CrosswakeShellConfig.kt`, `CrosswakeDelegates.kt`, `FilesPickResult.kt`, template `app/build.gradle.eex` / `settings.gradle.eex` / `build.gradle.eex` / `gradlew.eex`, `crosswake.contract.gen.ex`, `crosswake.docs.sync.ex`, `capability_map.ex`, `capability_map/renderer.ex`, `support_matrix/renderer.ex` (legend), `verify_android_release_host.sh`, `verify_android_public_build.sh` (+ test), `verify_generated_android_shell.sh`, `verify_published_cleanroom.sh` (header), `check_ci_leaf_manifest.py`, `repository_verification_stages.json`, `verify_repository.mjs` (schema), `crosswake-ci.yml` (Android jobs, brand-visual), `setup-android-jvm/action.yml`, `NavigationCoordinatorTests.swift`, `vector-controls.mjs`, `phase-evidence.mjs`, `native_evidence_drift_test.exs`, `unreleased_claim_qualifier_test.exs`, `phase166_repository_quality_test.exs`, `repository_verification.test.mjs`, BEARINGS, ADR A1.

### Secondary (MEDIUM)
- Elixir `Version.parse` behavior on negative components (A1, not run).

### Tertiary (LOW)
- None relied on.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, every version read from checked-in files and exercised.
- Architecture: HIGH for the foreign-host and Kotlin parts (executed); MEDIUM for the Elixir ledger and CI placement (read, not built).
- Pitfalls: HIGH, most were reproduced.

**Research date:** 2026-11-05
**Valid until:** 2026-11-19 (0.2.12 publication would retarget the foreign-host leg; AGP, Gradle or Hex API changes would move C1 and C3)
