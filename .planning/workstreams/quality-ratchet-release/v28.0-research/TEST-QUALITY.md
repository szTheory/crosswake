# TEST & SPEC QUALITY research (v28.0 rolling roadmap)

Researched: 2026-10-24. Read-only on the repo. The only external side effect was a throwaway mutation-tool probe in the session scratchpad, outside the repo.

Scope update applied (coordinator decision): **Android is UNFROZEN as soon as possible.** Kotlin is first-class below. AGENTS.md still says "Android frozen"; that line must be reconciled with this decision (roadmap item N-7).

Confidence key: HIGH = measured in repo or primary docs. MED = inferred from sampling. LOW = unverified.

---

## 1. Inventory (HIGH, measured by grep and `ls`)

| Suite | Tests | Layout and notes |
|---|---|---|
| Elixir core (`test/`) | about 2,720 `test "..."` | 227 files under `test/crosswake`, 25 under `test/mix`, 86 under `test/crosswake/proof`. Support code in `test/support` (compiled via `elixirc_paths`). JSON vectors in `test/fixtures`. |
| `packages/crosswake_sigra` | 139 | 18 files |
| `packages/crosswake_threadline` | 98 | 11 files |
| `packages/crosswake_rindle` | 62 | 7 files |
| `packages/crosswake_chimeway` | 53 | 9 files |
| `packages/crosswake_rulestead` | 12 | 2 files |
| `examples/phoenix_host` | 166 | 51 files. Excluded from core `mix test` by `:requires_example_host`. Runs in the `proof-requires-example-host` CI leaf. |
| Swift SPM core (`packages/crosswake-shell-core-ios`) | about 100 `func test` | 13 files, about 2,960 source LOC |
| Swift example hosts | part of about 203 `func test` repo-wide | ios_shell_host (unit and UI), phoenix_host/native/ios (proof-lane, twin UI). UI tests need Xcode. |
| **Kotlin/Android** | **29 `@Test` repo-wide** | Core: `crosswake-shell-core-android` has 4 files and 12 tests for about 2,030 source LOC (JUnit 4.13.2 and org.json only). Example host: 5 files, 17 tests, 2 of them instrumented (`androidTest`, device-only). |
| JS | 5 `.mjs` files in `test/js` | `node --test`. Dependency-free root `package.json`. |

Exclusion tags set in `test/test_helper.exs`, all default-on exclusions:
- `:advisory_only` (unless `MIX_INCLUDE_RULESTEAD=1`)
- `:collateral_binaries`
- `:engine_present`
- `:requires_example_host`
- `:requires_xcodebuild` (auto, when xcodebuild is absent)

Other tags: `:post_publication` (25 uses), `:tmp_dir` (74), and many phase-named tags such as `:phase153_ios_mirror_unblock`, `:diag_02`.

CI: `crosswake-ci.yml` has leaf jobs including `android-package-unit` and `android-generated-shell-unit`. There are about 20 `phaseNN-proof.yml` workflows and `required-checks-audit`.

**Structural observations:**
1. The Elixir suite is two populations.
   - Behavioural unit tests of `lib/`: policy, manifest, bridge, offline.
   - A large "proof/meta" population (86 files in `proof/`, plus 217 `File.read` sites) that asserts facts about workflow YAML, scripts, docs and release graphs.
   - These meta-tests are the project's real moat, because of "absence scored as success". They are also where the vacuity risk concentrates.
2. Behavioural coverage of the core domain modules is thin relative to line count (see section 6). Offline has 4 to 5 tests per module.
3. Kotlin has about one-eighth of Swift's test density for a comparable shell. The Android core suite is mostly vector consumption (BridgeConformance, BridgeReplyLeg, ActivationConformance).
4. There are zero property tests and no StreamData anywhere in the repo, in `mix.exs`, the lock files, or the packages. `mix.exs` has no Credo, no ExCoveralls and no mutation tool. The Elixir dependency tree is small by design (jason, nimble_options, phoenix, phoenix_live_view, telemetry, plus lazy_html in test).

---

## 2. Weak-spec hunt (HIGH on counts, MED on prevalence judgments)

Method: regex scans over `test/`, `packages/*/test`, `examples/phoenix_host/test`, plus targeted reads. The repo already has a SEED-018 ledger: `script/collection_assertion_ledger.json` and `script/inventory_collection_assertions.exs`.

### 2.1 Vacuous collection assertions (the SEED-018 family)
- **Already audited:** 243 ledger rows, bucketed as 135 safe-by-construction, 63 safe-guarded, 41 cardinality-pinned and 4 compile-time-literal. None is open.
- **The ledger is frozen and closed-world.** Its note says it "will not grow to cover a site added later". VACG-01, the standing guard, is still deferred. Every new site since the freeze is unchecked.
- **Fresh counts:**
  - `assert Enum.all?` / `assert Enum.any?`: 245 raw lines.
  - `assert ... |> Enum.all?`: 73.
  - `for` comprehensions over `Path.wildcard` with no cardinality assert: at least 3 sites, e.g. `test/crosswake/proof/phase165_ci_integrity_test.exs:822` and `:864`, and `phase132_compat_matrix_drift_test.exs:165`. A `for` with an empty generator passes silently.
    - D-02 of the ledger scanner explicitly excludes `for` comprehensions, `Enum.each` and `Enum.reduce`, and assigns them to "VAC-03 checklist" prose.
    - `phase165_ci_integrity_test.exs:822` is partly mitigated: it follows `uses:` references and asserts on the existence of the called file. The outer loop still has no `refute workflows == []`.
- **Verdict:** estimated 20 to 40 new unguarded sites since the freeze (MED, extrapolated). **Strengthen, do not remove.** The fix is one line per site, an explicit non-empty assertion on the derived collection.

### 2.2 Literal tautologies
- `assert true` in three places:
  - `test/crosswake/guides/evidence_manifest_test.exs:98`. When `CROSSWAKE_EVIDENCE_MANIFEST_PATH` is unset, the test passes by asserting nothing. This is "absence scored as success" in its purest form.
  - `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs:59`. Skips silently when Plug.Conn is not loaded (optional dep).
  - `test/crosswake/proof/absence_is_not_success_test.exs:361` is a fixture-writing helper that creates a sample test. It is **not** a defect.
- **Action:** convert the first two to `@tag :requires_x` plus exclusion, or to a visible `ExUnit` skip, so the run summary shows "N excluded". A silently-green test that did nothing is worse than an excluded test that says so.
- `refute false`: zero hits.

### 2.3 Shape-only assertions
- 168 `assert is_binary/is_map/is_atom(...)` calls. Many are fine as type-contract pins. Weak examples:
  - `test/crosswake/proof_lane/loopback_origin_harness_test.exs:396` (`assert is_map(json)`)
  - `test/mix/tasks/crosswake_shell_status_test.exs:130` (`is_map(decoded["platforms"])`)
  - Several `is_binary(next_action)` checks (`crosswake_release_status_test.exs:363`) that do not check the content.
- 50 `assert {:ok, _x} =` match-only assertions. Prevalence of weak ones: MED, estimated 15 to 25%. **Strengthen** by asserting one load-bearing field of the returned value, or remove where an adjacent assertion already covers it.

### 2.4 "Does not raise" tests
- 26 hits for "does not raise / no crash / without raising". Most are good: the title says "without raising" but the assertion checks the returned error shape, for example `crosswake_proof_lane_twin_preflight_test.exs:321` (exit 2) and `evidence_test.exs:422` (asserts non-echo).
- Weak: `phase154_catalog_guard_test.exs:259`, "assert_catalog_closed!/0 does not raise on the shipped tree". This is a legitimate gate. It is correct only if the catalog is non-empty, so verify that one cardinality pin exists.
- `phase60_chimeway_registry_test.exs:753` comment "no crash" needs a read.
- **Verdict:** low prevalence. Spot-fix only.

### 2.5 Echo tests (assert what was just set)
The clearest cases are in the offline contract:
- `test/crosswake/offline/replay_test.exs`, "replay requests are typed and route-scoped from journal entries". It builds an Entry with `route_id: "study-session"` and asserts `request.route_id == "study-session"`.
- Same file, "replay outcomes are explicit accepted rejected or conflict results". It constructs `accepted/rejected/conflict` and asserts the field it just passed in.
- `journal_test.exs` first test: same shape (builds entry, asserts fields equal inputs).
- These are mapping tests over `struct!`. They do catch a field-mapping swap, for example `idempotency_key` mapped from `client_mutation_id`. They would not catch the real risks: scope partitioning, replay authority, scope-ref bounds, redaction.
- **Verdict: strengthen** by replacing the fixed literals with a property (distinct generated values per field, so a swap is detectable) or a mutation-style assertion. Do not delete.

### 2.6 Compiler error assertions are existence-only
- `test/crosswake/policy/compiler_test.exs` asserts errors by `Enum.any?(errors, &String.contains?(&1.message, ...))`. This is safe against vacuity (`any?` on empty is false). Two weaknesses:
  1. It never asserts the **exact** error set, so extra spurious errors, or an error mapped to the wrong route, pass.
  2. `Compiler.validation_key/1` (`lib/crosswake/policy/compiler.ex`) classifies errors by `String.contains?(message, ":runtime")`, falling through to `nil`. A message mentioning `:id` inside a `:runtime` message gets the wrong key. Existing tests do not pin `key`, so nil or wrong keys are invisible.
- **Strengthen:** assert `{key, route_id}` pairs exactly.

### 2.7 Implementation-detail and source-grep tests (largest class)
- 217 `File.read` call sites that match lib, script, yml or md paths (190 files read files). Many are deliberate (CI contract tests), and for workflows there is no other oracle.
- Risk: string-matching a shell script or YAML snapshot such as `assert script =~ "--update-main"` (`phase145_ios_backfill_script_test.exs:20`) pins wording, not behaviour. It breaks on harmless refactors and passes on semantically wrong changes.
- **Verdict:** keep where YAML is the product. For scripts, prefer executing the script with a fake environment. Do **not** bulk-rewrite (see do-NOT list).

### 2.8 Snapshot/golden self-blessing
- **Good news:** no auto-bless mechanism found (no `UPDATE_SNAPSHOT`, `BLESS` or similar). Goldens are regenerated explicitly via `mix crosswake.contract.gen`, and the vector tests derive their version from the file, so a stale file fails (documented in `bridge_behavioral_vector_test.exs`).
- **Residual risk:** vectors are generated by Elixir and consumed by Swift and Kotlin. If Elixir and the generator are wrong together, everything agrees. This is single-oracle risk, which property tests plus a hand-written spec table partly mitigate.

### 2.9 Single-failure vector design hides precedence bugs
- `bridge_behavioral_vector_test.exs` documents that each vector must trigger **exactly one** check, because Elixir `bridge_findings/2` prepends findings and the first element is the last check that fired.
- The same file documents that Elixir and native check **order** differ. Whenever a request violates two rules, Elixir and native may deny with different reasons. No test covers multi-violation requests.
- **This is the highest-value property target in the repo** (see P1).

### 2.10 Skipped and dead tests
- Elixir: no `@tag :skip` in real tests. The two `@moduletag :skip` hits are fixture strings in `phase164_exunit_ownership_test.exs`.
- Swift:
  - `XCTSkip` in `Phase180TwinFeasibilityTests` (4, env-gated)
  - `HostCommandNavigationTests:22` and `:30` ("denied")
  - `HostCommandSeamTests:108`
  - `ProofLaneUITests:22`
  - These are **runtime skips that are invisible as green**. The environment-gated ones are acceptable only if some lane proves they run. `HostCommandNavigationTests` skips on "denied" mid-test: if the guard condition is always true, the test never asserts. Verify (MED).
- Kotlin: no `@Ignore`. Several `assertNotNull` (`DiagnosticExportTest` 3, `LiveViewBootInstrumentedTest` 3, `BridgeReplyLegTest` 2) are presence-only. Strengthen.
- Duplication: not measured. Likely heavy in `phaseNN_*` proof files that restate the same invariant for each phase, but I cannot cite pairs. **LOW confidence.**

### 2.11 Kotlin-specific weak spots (new under the unfreeze)
- Only 12 JVM tests guard 2,030 LOC of core shell. `BridgeConformanceTest` has 3 `@Test` methods, one of which is a single data-driven loop (`all bridge contract vectors pass...`). If the vector file loads with zero vectors, the loop passes. Check for a count pin. The same pattern exists in Swift `BridgeConformanceTests` and `ActivationConformanceTests`.
- Kotlin's version of SEED-018 is `vectors.forEach { assert }` with no `assertTrue(vectors.length() > 0)`. Grep for `.all {` found none, but loop-style iteration exists (`for` over `getJSONArray`).
- `BridgeReplyLegTest` correctly fails loudly on a missing vector ("missing committed reply-leg vector $id — regenerate with mix crosswake.contract.gen"). Copy that pattern into the others.

---

## 3. Property-based testing

### 3.1 Tooling decision (opinionated)
- **Elixir: `stream_data` as `only: :test`.** It is the de-facto standard, maintained under the elixir-lang org with ExUnitProperties, and it has no runtime dependencies in the test env. Cost is one test-only dep with a flat tree.
  - This is the one place the "copy-paste over dep" value deserves a deliberate exception: a hand-rolled generator and shrinker is a poor copy-paste target, because shrinking is the whole value.
  - Mitigate by confining it to `test/properties/` and the packages that need it (not the published package runtime). Declare it `only: :test` in core.
  - PropEr is the alternative. It is Erlang-first with a stateful-testing story, but it adds friction and a second DSL. Not recommended.
- **Finite domains do not need properties.** Route policy is a finite cross-product of runtime x offline x entry x security x sync. **Enumerate it exhaustively** with a `for` over the product and assert the validator verdict against a hand-written spec table. That is stronger than random sampling and needs no dep. Use StreamData only for open domains (strings, ids, maps).
- **Swift:** no first-class property library is a clear winner. Options are SwiftCheck (long-standing, but low maintenance; I did not verify current status, **LOW**) or a 30-line seeded `SystemRandomNumberGenerator`-based loop inside XCTest. For the small wire surface, **recommend the copy-paste loop**: a seeded RNG that prints its seed on failure, 200 iterations, no dependency. Swift Testing parameterized tests (`@Test(arguments:)`) cover the finite-domain case natively.
- **Kotlin (new):** Kotest property module (`kotest-property`) is the standard JVM property library. It is a test-only Gradle dependency, usable under JUnit 4 or 5 via kotest-assertions-core plus the property module. JUnit's `@Parameterized` handles finite domains. Same recommendation as Swift: for a wire surface of about 10 commands, a seeded `kotlin.random.Random` loop in a plain `@Test` (about 25 lines, prints the seed on failure) avoids a dependency. I could not verify Kotest's current release or API in this session (my web search returned nothing for Kotest, **LOW**), so confirm before adopting.
- Nothing changes for JS: `node --test` with a seeded loop.

### 3.2 Candidate properties (ranked by value)

| # | Property | Module | Why it pays |
|---|---|---|---|
| P1 | **Verdict equivalence across Elixir, Swift, Kotlin.** Generate sessions and requests with random subsets of violations. Elixir `Compatibility.bridge_findings/2` produces an allow/deny and a reason. Dump the generated corpus as JSON committed alongside the fixed vectors, and have Swift and Kotlin assert the same allow/deny. For multi-violation inputs, assert the *set* of reasons or the primary reason under a documented precedence. | `lib/crosswake/compatibility`, `bridge/contract`, native BridgeChannel | The only place where three implementations of one security decision exist. Today only single-violation vectors are tested. |
| P2 | **Denial is total and closed.** For any request and any manifest, the result is either allow or a denial whose reason is in the closed vocabulary. It never raises and never returns `nil`. | `bridge/denial.ex`, `shell/denial` | Fail-closed is a stated core rule. |
| P3 | **scope_ref grammar.** For any binary: `Journal.scope_ref!/1` accepts iff it matches `\Av[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}\z`. Rejection messages never contain the input (non-echo). | `offline/journal.ex` | Boundaries: 15 and 16, 128 and 129 chars, newline injection. `\z` versus `$` is a classic bug. Existing tests use one invalid string. |
| P4 | **Observation is closed over privacy.** For any map input to `SafeObservation.new/1`: either `{:error, _}` or a projection whose keys are a subset of the closed vocabulary and whose values are atoms or bounded non-negative integers. No binary other than `route-<16 hex>` survives. Feed adversarial strings (emails, tokens) into every field, and assert the output contains none. | `offline/safe_observation.ex` | The Sensitive Data Rules guard, as a property over arbitrary inputs. |
| P5 | **Scope partitioning.** For any interleaving of journal entries across N scopes, grouping and replay-selection per scope never mixes scopes, and switching scope yields an empty or denied view. Today this is a contract, so the property should target whatever pure selection function exists, and the Swift outbox once it is explicit. | offline journal, Swift outbox | SEED-023 (scope cardinality) is the same class. |
| P6 | **Manifest render determinism and order independence.** For any route list: `render(build(routes))` is identical for any permutation of route declaration order where order is not semantically significant, and `render` called twice is byte-identical. | `manifest/serializer.ex`, `builder.ex` | The serializer sorts keys but not lists. Which list orders are significant needs to be pinned. Idempotent `write/2` also needs the property "second write returns `:reused`". |
| P7 | **Build then validate.** Any route set that `Policy.Compiler.compile/2` accepts yields a manifest where `Manifest.Validator.validate/1` returns `:ok`. | `policy/*`, `manifest/*` | Catches builder and validator drift, which are two independent encodings of the same rules. |
| P8 | **Compiler errors are well-formed.** For any option combination, `compile/2` returns `{:ok, _}` or errors that all have a non-nil `key` and `route_id`. This is a regression target for the `validation_key` fall-through to `nil`. For the finite option product, enumerate exhaustively. | `policy/compiler.ex` | Concrete, likely to find a real defect. |
| P9 | **Wire JSON round-trip.** For any request or reply map, `Jason.decode(Jason.encode(x)) == x` for the contract structs, and `to_map` is injective over distinct field values (this replaces the echo tests in 2.5). | `bridge/contract`, `bridge/reply`, `offline/replay` | There is no decode side in the manifest, so the round-trip is only meaningful on the bridge wire. |
| P10 | **Native decoders reject unknown versions.** For any `protocol_version` not in the supported set, native returns the version-mismatch denial and never allows. | Swift BridgeChannel, Kotlin BridgeChannel | A fail-closed property on the versioned wire. |

Not worth property-testing: doctor, release_status, support_matrix and the proof_lane producers. They are string and report assembly with many fixtures, and the proof/meta tests cover them.

---

## 4. Mutation testing

### 4.1 Elixir tool survey (HIGH, primary sources plus a local probe)

| Tool | Status | Verdict |
|---|---|---|
| **Muex** (hex.pm/packages/muex) | v0.12.0, published 2026-10-21, MIT, publisher mudasobwa, 28 versions, about 22.7K downloads. Runtime dep: `jason` only, and the project already has jason. Docs state Elixir ~> 1.14, with CI on 1.14 to 1.16 and OTP 25 to 26. | **Only live option.** Young project (CI matrix stale versus its release cadence). |
| Muzak (free) | Free tier of the commercial Muzak Pro. Elixir Forum reports no updates and failure on Elixir 1.14 (an older thread). Randomly samples mutations. | Not recommended. |
| Exavier | Last maintained Nov 2020 (per the Muex comparison page). | Abandoned. |
| Darwin | Last maintained Dec 2020. | Abandoned. |

**Local probe (HIGH):** I ran Muex 0.12.0 in a throwaway project in the scratchpad (not in the repo), on Elixir 1.19.5 / OTP 27, the same toolchain as the repo. Observed:
- It compiled and ran: 48 files plus jason. Elixir 1.19 is therefore fine in practice despite the documented CI range.
- It does **not** need to be a project dep to run, but `{:muex, only: :test, runtime: false}` works. The docs also mention `mix archive.install hex muex` or an escript.
- Defaults silently produced nothing. With the default file filter, a small file was dropped (complexity below `--min-score` 20), and with `--no-filter` the default optimizer reduced 19 mutations to 0 ("Reduction: 100%"). The output was "No mutations to test; nothing to score." Only `--no-optimize` produced the real mutants: `>=` to `>`, literal 18 to 19 and 17, argument swap, pipe-stage drop and guard-to-`when true`.
- With `--fail-at 0` that zero-mutation run exits 0 (green, nothing tested). With the default threshold of 80 the task raises. The tool therefore has the **same absence-as-success hazard** this repo is built to avoid. Any wrapper must assert `mutations_generated > 0` from the JSON report.
- Features that matter here: `--since <ref>` (PR-scoped mutation), `--coverage-guided` (run only covering tests), `--format json --output`, `--files`, `--test-paths`, `--fail-at`, `--preset phoenix`, trivial-compiler-equivalence filtering.
- Unverified: behaviour on this repo's real modules. The probe was a 2-function file. A timed pilot on one module is needed (N-1 below).

### 4.2 In-repo copy-paste harness evaluation
- **Mutation controls already exist in the repo as a hand-written pattern:** 13 mutation controls in phase 184-08, the 8 controls in phase 183, and `absence.mutation_control_asserts_change` in `script/check_absence_is_not_success.exs`, which requires a control to assert its mutation changed something. These are targeted, hand-picked mutants of CI/workflow text, not AST mutation of Elixir logic.
- An AST harness is about 150 to 250 lines: `Code.string_to_quoted`, a `Macro.prewalk` that swaps operators (`==`/`!=`, `>=`/`>`, `and`/`or`, `in`/`not in`, `true`/`false`, `:ok`/`:error`), recompile the module with `Code.compile_quoted` and run the module's test file.
- **Verdict: do not write it at first.** Muex already does this, has `jason` as its only dep (already present), and sits outside the shipped package (test-only). A harness would hit the hard parts: equivalent-mutant filtering, per-mutant timeouts, recompiling modules with persistent_term or ETS state, and test selection. Writing it is a wheel-spin unless Muex fails the pilot. Fall back to the harness **only if** the pilot fails, and then scope it to about 4 pure modules.

### 4.3 Swift and Kotlin
- **Swift: Muter** (muter-mutation-testing/muter). Last push reported Nov 10, 2025 (aggregator, MED), 546 stars, 32 open issues, supports SPM and Xcode projects, Homebrew install. I found no explicit Xcode 16/26 compatibility statement (**unverified**), so a pilot against `crosswake-shell-core-ios` is required. SPM mutation of the 2,960-LOC core is feasible. Run only on a Mac runner, advisory.
- **Kotlin: PIT (pitest) via `info.solidsoft.pitest` Gradle plugin** (gradle-pitest-plugin; README shows 1.15.0 with a Kotlin DSL). PIT works on JVM bytecode, so it covers Kotlin without Kotlin-specific mutators, but it generates many noise mutants from Kotlin-generated null checks and inlined code. The commercial Arcmutate "Kotlin" extension exists to filter these. I could not confirm details in this session (**LOW**). It is test-only and fits the JVM-only `crosswake-shell-core-android` module (JUnit 4 works with PIT). The Android Gradle Plugin integration is not first-class, since pitest-android plugins are third-party and I could not verify them. **Recommendation:** extract pure-JVM logic and run PIT on the core library module only, not the Android app module.

### 4.4 How to run mutation testing without CI busywork
1. **Advisory, scheduled, never merge-blocking at first.** One weekly workflow (or local `script/mutation.sh`) over a fixed allowlist of critical modules. Output: one JSON report and a one-line summary appended to the run summary.
2. **Scope to about 6 modules** (section 6 list). Not the whole tree: doctor, release_status and proof_lane are huge and low-risk per mutant.
3. **Survivor triage is the real cost.** Rules to keep it bounded:
   - Each survivor is classified within one pass as `kill` (add or strengthen a test), `equivalent` (record in a small allowlist file with a reason) or `ignore-noise`.
   - The allowlist is keyed by file, mutator and normalized source text, **not by line number**. Line-keyed allowlists rot (the repo's own `file.exs:LINE` citation lesson).
   - Set the threshold per module from the *measured baseline* (ratchet up only). Measure before gating (feedback_absence_scored_as_success).
4. **Wrapper must fail on zero mutations generated.** This is the hazard observed in the probe.
5. **PR-scoped optional mode** (`--since origin/main`) for changes touching critical modules only. Promote to a required check only after survivor noise is under control, for example a 4-week stable window. Per AGENTS.md: "Promote checks into CI only when they protect a recurring contract and provide stable, actionable feedback."

---

## 5. Spec-quality guards

State: no Credo and no `.credo.exs`. The repo uses standalone `script/*.exs` scanners (`check_absence_is_not_success.exs`, `inventory_collection_assertions.exs`), which are already a copy-paste-style architecture.

**Recommendation: extend the existing scanner. Do not add Credo.** Credo is a large dependency tree (bunt, file_system, jason) in the repo, and these checks are only meaningful for tests. The repo already has an AST scanner with tests (`absence_is_not_success_test.exs`).

Checks, in order of value:
1. `absence.collection_assertion_non_empty` (this is VACG-01). The detection core already exists in the inventory script (the D-08 sunset says to lift it). Scope it to the **new-site delta**: fail only on sites not in the frozen ledger, via diff against `main` (`git diff` added lines) or a key allowlist. That avoids "173 findings that get waived" (SEED-018's concern) and costs about one session.
2. `absence.for_over_glob_without_cardinality`. A `for` or `Enum.each` over `Path.wildcard` or `File.ls!` inside a test with no `refute ... == []`, count-pin or `assert [_|_]`. About 3 known sites today.
3. `absence.assert_true`: literal `assert true`/`refute false` in a test body (not in a heredoc fixture), excluding the fixture-writing case. About 2 real sites today.
4. `absence.silent_env_gate`: a test whose only assertions sit in a `case System.get_env(...)` or `if Code.ensure_loaded?` branch, with a `nil ->` or `else` branch containing no assertion other than `assert true`. Fix by tagging and excluding instead. Fewer than 5 sites (MED).
5. `spec.no_assertion`: a `test` body with no `assert`, `refute`, `assert_*`, `assert_raise`, `assert_receive`, `flunk` or call to a local helper whose name starts with `assert`/`verify`. Tests that call helpers need an allowlist or a transitive helper check. **Measure first**; it will have false positives.
6. Swift: a grep gate for `XCTSkip` whose reason is not an env-var name or an explicit capability probe. Low priority.
7. Kotlin: a grep or Gradle gate for `@Test` fun bodies with no `assert*` or `fail(`, plus loops over vector arrays with no preceding size assertion.

Measure the findings of each check before making it merge-blocking.

---

## 6. Spec coverage of the 5 most critical modules (MED, from reading code and tests)

Criticality: the core thesis is route policy resolution, the bridge decision, the manifest wire, and the offline scope/replay boundary, which is the first adopter's one mutation island.

| Module (LOC) | Tests | Happy | Error | Boundary | Notes |
|---|---|---|---|---|---|
| `Policy.Compiler` + `Route` + `Validator` (216+451+394) | compiler 7, route 13, schema 20 | **B+**: all runtimes, commerce, entry defaults | **B**: four contradictions plus enum errors, but existence-only matching, `key` and `route_id` not pinned, nil-key fall-through untested | **C**: no empty route list, no duplicate id *plus* invalid in the same route, no path collisions, no property over the option product | The finite option matrix is the best exhaustive-test target. |
| `Bridge` + `Contract` + `Denial` + `Registry` (898+208+66+217) | contract 13, registry 12, vector 1 (data-driven), push 49 | **A-**: push has 49 tests | **B+**: each denial reason has a vector | **C**: single-violation vectors only. Precedence and multi-violation are untested. Unknown or huge `protocol_version`, malformed correlation_id and size limits are not seen in the tests I sampled. | The Elixir and native order difference is documented but not property-tested. |
| `Manifest` (Builder, Types, Validator, Serializer) (676+1515+925+54) | builder 18, validator 20, types 20, manifest 11, fixtures | **A-** | **B**: validator has 20 tests | **C+**: no determinism or permutation properties. `Serializer.write` branches (`:created`, `:reused`, `:updated`, read error `raise`) are partly covered. The unreadable-file branch is likely untested. | Largest module by LOC. `types.ex` at 1,515 LOC is a mutation-testing target. |
| `Offline.Journal` + `Replay` + `SafeObservation` + `Contracts` (109+154+124+140) | journal 3, replay 4, safe_observation 3, contracts 5 | **B**: echo-style (2.5) | **B-**: scope_ref rejection covered with one bad string and one missing | **D**: no boundary tests on the 16/128 char length, `\z` newline, replay status transitions, or idempotency-key reuse. **No scope-partition test is visible at this layer.** `SafeObservation`: 3 tests for 124 LOC with 9 enum and measurement branches (measurement 0 and 1,000,000 edges). | **Weakest coverage for the most sensitive module** (privacy and fail-closed). |
| Shell native bridge channels (Swift `BridgeChannel` and Kotlin `BridgeChannel`) | Swift about 100 across the core, Kotlin 12 JVM plus 6 in the host | Swift **B+**, Kotlin **C+** | Swift B, Kotlin C (loop over vectors only) | **C** and **D** | Kotlin has little behavioural test beyond the shared vectors. Android shell logic that is untested by vectors (activation coordinator, navigation) has 7 and 3 tests. |

Pattern: happy-path coverage is good, error coverage is decent (vector-driven), **boundary and combination coverage is the consistent gap**. That is exactly what properties and mutation testing address.

---

## 7. Ranked recommendations (horizon, effort, dependencies)

### Immediate (this milestone, before anything else)
| ID | Action | Effort | Depends on |
|---|---|---|---|
| I-1 | **Fix the known silent tests.** `evidence_manifest_test.exs:98` and `phase139_threadline_cleanroom_test.exs:59`: tag and exclude, or assert a prerequisite. For the vector-consuming tests (Elixir, Swift, Kotlin), assert vector-count greater than 0 and equal to an expected pin. Copy the `BridgeReplyLegTest` "missing committed vector" failure style. | S | none |
| I-2 | **Land VACG-01 as a delta-only guard** (checks 1 to 3 of section 5) in `check_absence_is_not_success.exs`: fail only on new sites not in the Phase 170 ledger. Fix the roughly 3 `for` and `assert true` sites in the same change. This closes the SEED-018 loop without a 200-finding wall. | M | I-1 |
| I-3 | **Audit the Swift `XCTSkip` sites** (`HostCommandNavigationTests:22,30`, `HostCommandSeamTests:108`). Prove each guard condition is false in some lane, or convert to `XCTAssert`. | S | none |
| I-4 | **Add the SafeObservation and scope_ref boundary tests** by hand (the P3 and P4 cases as example-based tests: boundary lengths, `\n` injection, measurement 0 and 1,000,000 and 1,000,001, adversarial strings in each field). They cost nothing in deps and establish the specs the properties will generalize. | S | none |

### Near (next 1 to 2 milestones)
| ID | Action | Effort | Depends on |
|---|---|---|---|
| N-1 | **Muex pilot on 3 to 4 pure modules** (`Offline.SafeObservation`, `Offline.Journal`, `Policy.Compiler`/`Route`, `Bridge.Contract`). Use `--no-optimize` (or verify the optimizer's output), `--format json`, and a wrapper that fails on zero mutants. Record baseline scores and survivors. Decide to adopt or drop based on measured runtime and survivor noise. | M | I-4 (so the first survivors are not trivially from missing boundary tests) |
| N-2 | **Add `stream_data` (test-only) and write P2, P3, P4, P8** plus the exhaustive policy-matrix table test. Property files in `test/properties/`. Deterministic seed in CI and a printed seed on failure. | M | I-4 |
| N-3 | **P1 differential corpus.** Extend `mix crosswake.contract.gen` to emit a generated multi-violation corpus (seeded, committed, bounded to about 200 cases). Swift and Kotlin vector tests consume it. Document the precedence policy, or reconcile the check-order difference (a product decision, not just a test). | M | N-2 |
| N-4 | **Kotlin test density to parity** for the core: vector count pins, `BridgeChannel` boundary cases, activation coordinator error paths. Aim to bring the 12 JVM tests to roughly 40 before adding new Android features. | M | the Android unfreeze scope |
| N-5 | Strengthen the weak spots: compiler error `{key, route_id}` pins (2.6), replay echo tests (2.5), the worst `is_map`/`{:ok, _}` shape-only assertions (2.3). Do this opportunistically when a module is touched, not as a sweep. | S each | none |
| N-6 | Weekly advisory mutation workflow for the Elixir allowlist (one job, JSON artifact, one-line summary, fail only on zero mutants or a baseline regression). | S | N-1 |
| N-7 | Reconcile AGENTS.md (Android freeze language) with the unfreeze decision, plus requirements, roadmap and state per the "update together" rule. Also state how Android verification is gated (Gradle JVM lane already exists as `android-package-unit`). | S | decision recorded |

### Mid
| ID | Action | Effort | Depends on |
|---|---|---|---|
| M-1 | Property tests for native sides: P10 and P1 in Swift (seeded loop) and Kotlin (seeded `Random` loop, or Kotest if the pilot justifies a dep). | M | N-3 |
| M-2 | PIT pilot on `crosswake-shell-core-android` (JVM module only), advisory, baseline then ratchet. Muter pilot on `crosswake-shell-core-ios` on a Mac runner. | M | N-1 (so the survivor-triage process is already proven) |
| M-3 | Extend the scanner with `silent_env_gate` and `no_assertion` (checks 4 and 5) **after** measuring their findings. | M | I-2 |
| M-4 | Outbox and scope-partition properties (P5) once the Swift outbox and replay authorization exist as a pure, testable unit. | M | the adopter offline-island work |
| M-5 | Turn the P6 and P7 manifest and builder properties on, and promote the weekly mutation run to a PR-scoped `--since` check if survivors are stable. | S to M | N-2, N-6 |

### Long
| ID | Action | Effort |
|---|---|---|
| L-1 | If Muex passes the pilot and survives a 4-week stable window, make a module-scoped score threshold merge-blocking for the 3 to 4 most critical modules only. | S |
| L-2 | Reduce proof/meta test duplication across the `phaseNN_*` files: consolidate tests asserting the same invariant, driven by mutation survivors, not by taste. | M |
| L-3 | Execute rather than grep shell scripts in contract tests, where the script is the product (2.7), as scripts change. | M |

---

## 8. Explicit do-NOT list

- **Do not** add Credo for this. It is a large tree for a handful of test-only checks. Extend the existing `script/*.exs` scanner.
- **Do not** land a merge-blocking guard that emits hundreds of findings. SEED-018's reasoning stands. Delta-only guards and measured-first thresholds only.
- **Do not** write an in-repo AST mutation harness before the Muex pilot fails. It is a wheel-spin.
- **Do not** use Muex's default optimizer output as evidence. It produced zero mutants on a trivial file and exited 0 under a permissive threshold. Require a mutants-generated count greater than 0.
- **Do not** run mutation testing over `doctor`, `release_status`, `support_matrix` and `proof_lane/*` (about 10K LOC of report assembly). Cost far exceeds signal.
- **Do not** mutation-test the YAML, shell or workflow meta-tests with an AST tool. The hand-written mutation-control pattern (`absence.mutation_control_asserts_change`) is the right instrument there.
- **Do not** bulk-rewrite the 217 source-grep tests. Convert one only when it breaks on a harmless refactor or misses a real change.
- **Do not** adopt SwiftCheck, Kotest or any PBT dependency for the native sides before a seeded 25-line loop proves insufficient.
- **Do not** use a line-number-keyed survivor allowlist (stale-citation lesson).
- **Do not** treat PBT as a replacement for exhaustive enumeration of finite domains (route policy matrix).
- **Do not** make mutation or property jobs required checks in their first milestone. Advisory, baseline, then ratchet.
- **Do not** count Android coverage as parity based on the same shared vectors alone. Vectors prove protocol conformance, not shell behaviour.

---

## 9. Gaps and unverified claims

- Muex on the repo's actual modules: runtime, equivalent-mutant noise and Phoenix-DSL behaviour are unmeasured. Only a 2-function probe ran (LOW to MED for the adoption call, HIGH that it runs on Elixir 1.19.5/OTP 27).
- Muter on Xcode 26 and PIT on Kotlin, and Kotest and SwiftCheck current status: not verified (the Kotest search returned nothing, Muter has no stated Xcode compatibility, and PIT's Kotlin noise is third-party-sourced).
- Duplicate-test prevalence is not measured.
- The fresh `assert Enum.all?` sites since the ledger freeze were not classified. The 20 to 40 estimate is extrapolated.
- Weak-spec prevalence percentages (2.3) are sampled, not exhaustive.
- Swift per-module test counts are `func test` greps. `@Test` (Swift Testing) uses were not separately counted.

## Sources

- Muex: https://hex.pm/packages/muex and https://muex.hexdocs.pm/comparison.html (comparison of Muex, Darwin, Exavier). Local probe v0.12.0 in the scratchpad.
- Muzak: https://hexdocs.pm/muzak/muzak.html. Elixir Forum thread "Mutation testing on Elixir 1.14?" (https://elixirforum.com/t/mutation-testing-on-elixir-1-14/51926).
- Muter: https://github.com/muter-mutation-testing/muter (activity via a third-party aggregator).
- gradle-pitest-plugin: https://github.com/szpak/gradle-pitest-plugin
- Repo evidence: `.planning/seeds/SEED-018-vacuous-collection-assertions.md`, `script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json`, `script/check_absence_is_not_success.exs`, `test/test_helper.exs`, and the test files cited inline.
