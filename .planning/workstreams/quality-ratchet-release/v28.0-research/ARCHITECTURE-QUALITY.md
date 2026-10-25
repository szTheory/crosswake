# v28.0 Research: Architecture, Code Quality and Dependency Posture

**Researched:** 2026-10-24 (read-only audit of `main`, clean tree)
**Overall confidence:** HIGH on measured facts (LOC, xref, deps, tracked files, build results); MEDIUM on judgments (what is "dead", what is "worst"); items marked UNVERIFIED were not run.

Method note: measured with `mix xref graph`, `mix deps.tree`, `mix hex.build --unpack` (scratch dir), `wc`, `grep`, `mix format --check-formatted`, `mix compile --warnings-as-errors --force`. Nothing was installed or written outside this file and the scratch directory. A full lens fan-out was not run as separate agents; the lenses (architect, OTP, Swift, API, security, newcomer) were applied by one reader against local evidence, with no web research. Cited conventions (Elixir library guidelines, Hex metadata, Swift API Design Guidelines) are from the author's knowledge, not fetched this session.

## 1. Executive findings (ranked by leverage)

1. **The core Hex package is about 40% maintainer/proof tooling, not runtime contract.** `lib/` is 48,897 LOC across 156 files; `mix hex.build --unpack` shows the tarball ships all of it (2.8 MB unpacked). Maintainer-only trees shipped to every adopter:
   - `proof_lane/` 7,944 LOC
   - `release_candidate/` 4,417 LOC
   - `release_status.ex` 1,563 LOC
   - `planning/` 1,552 LOC, which reads `.planning/` and is repo-internal by definition
   - `support_matrix/` 2,190 LOC
   - `doctor/publish_readiness.ex` 1,239 LOC
   - roughly 5,400 LOC of `lib/mix/tasks`, much of it release tooling
   That is about 19-20k LOC of tooling against the ADR's "one real Phoenix app, one iPhone". The runtime-contract kernel (`bridge*`, `policy*`, `router*`, `manifest/`, `offline/`, `compatibility/`, `packs/`, `transfer/`, `native_escape/`, `telemetry`) is roughly 12-15k LOC. This is the largest violation of "small, honest surface" in the repo, and it is a packaging problem more than a code problem.
2. **Dependency tree is already small and clean.** Core runtime direct deps are `jason`, `nimble_options`, `phoenix`, `phoenix_live_view`, `telemetry`. `ex_doc` is dev-only. `lazy_html` is test-only and drags `cc_precompiler`/`elixir_make`/`fine` (native precompiled binary, the only supply-chain-interesting dep, test only). `mix.lock` has 23 entries. Swift core has **zero** package dependencies. The only candidate for replacement-by-copy is `nimble_options` in core (3 files), see section 5. Recommendation is to keep the posture and add a ratchet so it cannot grow, not to shrink it.
3. **Repo root has 14 tracked scratch files**, confirmed with `git ls-files`: `fix_bridge_tests.swift`, `fix_generator_test.py`, `fix_pbxproj.py`, `fix_public.py`, `fix_public2.py`, `fix_published.py`, `patch_activation_coordinator_tests.py`, `test_subclass.swift`, `update_main_activity.sh`, `update_pbxproj_for_spm.py`, `update_swift_access.py`, `gen_manifest.exs`, `.tmp-init.txt`, and `crosswake-checkpoint-24c8389.bundle` (434 KB git bundle). They are not in the Hex `files:` allowlist, so they do not ship, but they are the most visible "not a work of art" signal for a newcomer. `fix_public.py` was committed in a "progress and fixes" commit. `.tmp-init.txt` is GSD config residue. The bundle is an opaque binary in a public repo.
4. **Static analysis is thinner than the code volume implies.** Gates present: `mix format --check-formatted` passes now; `mix compile --warnings-as-errors` passes on a forced rebuild and is wired in CI (many lanes). Absent: no credo, no dialyzer/dialyxir, no SwiftLint, no `mix xref` assertion. Whether CI runs `format --check` was not found by grep of `crosswake-ci.yml` (UNVERIFIED, so confirm before claiming it is gated). 26 workflow files exist, including about 13 `phaseNN-proof.yml` named after historical phases.
5. **Xref is nearly acyclic, but one compile-connected cycle exists.** `mix xref graph --format cycles --label compile` reports 1 cycle of length 4 (1 compile, 2 export): `bridge/contract.ex` -> `bridge/denial.ex` -> `manifest/types.ex` (compile) -> `shell/denial.ex` and back. Two more runtime-only cycles of length 2 exist; one is `manifest/builder.ex` <-> `support_matrix/support_matrix.ex`. The Builder <-> SupportMatrix cycle is a layering inversion: the manifest builder (core) and the support matrix (maintainer truth) know each other. The compile-time cycle in the denial/types family is the first one that will cause a recompile storm or a hard-to-debug compile deadlock.

## 2. Architecture map

Layers as they actually exist (inferred from directory plus xref, not documented in one place):

| Layer | Modules (LOC) | Ships to adopters? | Should it? |
|---|---|---|---|
| L0 runtime contract | `bridge.ex` 898, `bridge/*` 1.8k, `policy*` 1.9k, `router*`, `manifest/{types 1515, validator 925, builder 676, serializer}`, `compatibility/` 1.5k, `offline/` 0.9k, `packs/`, `transfer/`, `native_escape/`, `telemetry.ex` 446, `companion*.ex`, `host_commands.ex` | yes | yes |
| L1 adopter dev tooling | `doctor/{doctor 2818, check, formatter}`, `install/`, `shell/` 3k (generator), `operator_inspection/`, `capability_map/`, `adoption/`, `lib/mix/tasks/crosswake.{gen,doctor,inspect,install}*` | yes | yes, but should be a separate namespace boundary |
| L2 maintainer/release/proof | `proof_lane/` 7.9k, `release_candidate/` 4.4k, `release_status.ex` 1.6k, `planning/` 1.6k, `support_matrix/` 2.2k, `doctor/publish_readiness.ex`, `commerce/`, `companions/{store_kit,play_billing}`, release mix tasks | **yes, today** | **no** |

Largest and most complex modules: `doctor/doctor.ex` (2,818 LOC, 3 modules, functions of 126/110/88/79 lines; function names such as `phase_3_posture`, `phase_4_posture`, `phase_10_posture`, `phase_46_auth_findings`, `phase_38_companion_seam_findings`), `proof_lane/twin_producers.ex` 1,904, `support_matrix/support_matrix.ex` 1,676, `release_status.ex` 1,563, `manifest/types.ex` 1,515. In packages, `crosswake_sigra` is 3,969 LOC (`auth_return.ex` 895, `step_up.ex` 832, `handoff.ex` 773); chimeway 1,291, threadline 744, rindle 577, rulestead 202.

Public API vs internals: 111 of 156 core modules carry `@moduledoc false`, which is a good, honest convention (public surface about 45 modules). It is not enforced by a snapshot, so the "public" set drifts silently. There are 563 `@spec`s against 899 public `def`s in `lib/`. Four mix tasks lack a `@moduledoc` entirely: `crosswake.gen.sync`, `crosswake.gen.proof_lane`, `crosswake.proof_lane.verify_navigation_shell`, `crosswake.adoption_context.scan`.

Compile-time deps: only one compile-label cycle (above). Compile-connected fan-in on `manifest/types.ex` (1,515 LOC, compile edge) is the hotspot.

Dead code: UNVERIFIED by tool (no `mix xref unreachable`-style run on 156 files was reported as noise-free). Strong candidates by evidence: `crosswake.gen.native_controls_ui` and `commerce/`, `companions/{store_kit,play_billing}` fall under the ADR stop list ("commerce productionization", "native menu/action-button breadth"). Treat as frozen, not as dead.

Duplicated logic: `Phase N / D-NN` provenance is embedded in code 360 times in `lib/` (comments and function names). This is duplicated planning history in the wrong store; it rots and it blocks reading.

## 3. Grade against the architectural thesis

| Thesis clause | Grade | Evidence |
|---|---|---|
| Phoenix-first, not a universal UI framework | A- | Router and manifest are Phoenix-native; no generic UI abstractions found. |
| Explicit runtime ownership per route | B+ | `offline/SafeObservation` has a closed runtime vocabulary (`@runtimes [:offline_island]`); policy and router carry route identity. Ownership is expressed in data, but no automated test asserts "every route has exactly one owner" at the generated-shell boundary (not verified; recommend F4). |
| Bridge is semantic, typed, versioned, low-frequency | B | `bridge/catalog_guard.ex` (945 LOC) exists and `bridge/reply.ex` is tiny. No frequency guard seen; `Crosswake.Bridge.push/3` is the only server-to-client push, which is fine, but nothing statically prevents a command from carrying continuous state. |
| Fail-closed explicit denials | B | Good: `Denial` structs, closed enums, `with` chains returning `{:error, %Error{rule_id, path}}`. Watch: 106 `rescue`/`catch` sites in `lib/`. `bridge.ex:685, 694, 709` use bare `rescue _ ->` returning `nil`/`""`; they feed only diagnostic message text (route lookup at `bridge.ex:668`), so they are not fail-open, but a bare rescue-all is an unreviewable pattern in a fail-closed codebase. `release_candidate.ex:35,67,137` and the mix tasks (`crosswake.release.gate.ex:50,100`, `crosswake.release.receipt.ex:28,97`) rescue around gate logic, and those are the paths where silent degradation would be a real defect. Audit each. |
| No generic-framework abstractions the ADR rejects | C | Core ships `commerce/`, StoreKit/PlayBilling companions, native-controls UI generator, `proof_lane` twin producers and a 4.4k-LOC release-candidate engine. These are exactly the "breadth" the ADR stop list rejects. They are quarantined by convention, not by packaging. |
| Privacy: no raw payloads in telemetry/doctor | A- | `SafeObservation` is a model: closed keys, closed enums, explicitly "not a redactor". Atom-minting audit: `String.to_atom` at `crosswake.gen.shell.ex:839`, `crosswake.doctor.ex:138`, `crosswake.release.candidate.ex:111` operate on operator/CLI input. Low severity (mix tasks, not the runtime), but it is a pattern a security reviewer will flag. `router.ex:60,160` use `Code.eval_quoted` at macro-expansion time on literal route AST, which is acceptable for a macro and worth a one-line comment. |

## 4. Code-as-art audit

### Ten worst concrete examples (file:line)

1. Repo root: 14 tracked scratch files (see finding 3), e.g. `fix_public.py`, `update_swift_access.py`, `test_subclass.swift`, `.tmp-init.txt`, `crosswake-checkpoint-24c8389.bundle`. Highest visibility, S effort.
2. `lib/crosswake/doctor/doctor.ex:440,450,469,597` (`phase_3_posture`, `phase_4_posture`, `phase_10_posture`): function names encode planning-phase numbers rather than domain concepts. 2,818-line file, 126-line `phase_4_posture`.
3. `lib/crosswake/support_matrix/support_matrix.ex:1114` `validate_phase51_support_truth`: the same history-as-name pattern; plus the file is in a cycle with `manifest/builder.ex`.
4. `lib/crosswake/bridge.ex:685,694,709`: three bare `rescue _ ->` clauses inside one module, the only module whose job is the bridge contract. Replace with explicit `with`/`case` and a named error.
5. `lib/crosswake/bridge/reply.ex` (36 lines, 0 `@spec`, 0 `@doc`) and `lib/crosswake/bridge/denial.ex` (66 lines, 3 specs, no `@doc`): the core wire-contract types are the least documented modules. These should be the best documented.
6. `lib/crosswake/shell/ios_host_origin_mode.ex`: 22 public functions, 1 `@spec`. Same for `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` (17 public, 1 spec).
7. `lib/crosswake/policy/schema.ex`: 43 public functions with 18 specs; this is the schema the whole manifest depends on.
8. `lib/crosswake/offline/safe_observation.ex:18` nested `defmodule Error` has no `@moduledoc`, no `@type`; and `{:error, %Error{rule_id: "CW-..." , path: ...}}` is a stringly rule id while elsewhere denials are atoms (`:scope_inactive`). Inconsistent error-tuple vocabulary: struct with string rule id here, `%Denial{}` in `bridge/denial.ex` and `shell/denial.ex`, bare atoms elsewhere. (Strong exemplar overall, but it exposes the convention gap.)
9. `lib/mix/tasks/crosswake.gen.shell.ex:839` (`String.to_atom(router)`) and 934-LOC mix task: generator logic inside a Mix task rather than a testable module. Same atom pattern at `lib/mix/tasks/crosswake.doctor.ex:138` and `crosswake.release.candidate.ex:111`.
10. `lib/crosswake/doctor/publish_readiness.ex`, `release_status.ex`, `planning/closeout_verifier.ex`, `planning/paths.ex`: a public Hex package containing code that parses the author's own `.planning/` directory. A newcomer reading `lib/` meets the author's GSD process before the product.

Swift (lighter evidence, 5,505 LOC in `CrosswakeShellCore`, 17 files): `ActivationCoordinator.swift` is 894 LOC (largest, the Swift analogue of `doctor.ex`); 22 uses of `@MainActor`/`Sendable`/`actor` across 119 `func`s suggests concurrency annotations are present but not uniform (needs a Swift 6 strict-concurrency pass to know, UNVERIFIED). `try!`/`as!`/`print(` occur twice, force-unwrap `!.` pattern zero by crude grep: good. No SwiftLint config. `Package.swift` still carries the Xcode template comments ("Products define the executables...") and `swift-tools-version: 5.9` with iOS 15 floor. The root scripts `update_swift_access.py`/`fix_public.py` show that `public` access was bulk-regex-patched in, so the public Swift API surface was never designed; audit it deliberately before the first adopter links it.

### Three exemplar modules others should match

1. `lib/crosswake/offline/safe_observation.ex`: closed vocabularies as module attributes, `@enforce_keys`, `{:ok, t} | {:error, Error.t()}` with specs on every public function, `with` chains, moduledoc that states what it is *not*.
2. `lib/crosswake/bridge/denial.ex`: 66 lines, one job, specs present (fix: add `@doc`/`@moduledoc` examples).
3. `lib/crosswake/component_tier_guard.ex` plus `companion_guard.ex`: guards that are themselves architecture fitness functions (they scan for banned namespace minting), with a moduledoc explaining the rule. This is the pattern to generalize in section 6.

### Cross-package consistency

All five companion `mix.exs` files share `@source_url`, Apache-2.0, `links`, `elixir: "~> 1.19"`, `description/0`: good hygiene and consistent. Companion `mix.exs` files contain long decision-ID essays (`D-19`, `D-11/D-13`) in comments, same history-in-code smell as `lib/`. `crosswake_rulestead` (202 LOC) is the shape the others should resemble.

## 5. Dependency posture

**Core (`mix deps.tree`)**: 5 runtime direct deps, resolves to about 20 packages mostly via Phoenix (plug, plug_crypto, phoenix_pubsub, phoenix_template, phoenix_html, websock_adapter, mime). `ex_doc` (+ earmark_parser, makeup*, nimble_parsec) is dev-only. `lazy_html` (+ cc_precompiler, elixir_make, fine) is test-only; it downloads a precompiled NIF, the single highest supply-chain surface, but it is not in the published tarball's runtime and PLV itself requires it for LiveViewTest.

**Companions**: each depends on core (path dep in dev, Hex in publish via `crosswake_dep/0`), `ex_doc` dev/test, and:
- rulestead: optional `rulestead` engine
- rindle: optional `rindle` engine
- sigra: no third-party deps (pure Elixir; 3,969 LOC)
- chimeway: core, test-only sigra
- threadline: optional `plug`, optional `phoenix_live_view`, `nimble_options`, `telemetry`

Lock sizes: root 23 entries; rindle 36 and rulestead 26 (engines pull more), others 19.

**Swift**: no SwiftPM dependencies (`Package.swift` has no `dependencies:`); no `Package.resolved`. Excellent. **Android** (frozen, audit only): `androidx.core-ktx 1.12.0`, `kotlinx-coroutines 1.7.3`, `kotlinx-serialization-json 1.6.0`, `androidx.webkit 1.10.0`. Aged but frozen by ADR; do not touch except for CVE advisories.

**Replace-by-copy candidates (honest ranking)**:
- `nimble_options` in core: used in 3 files (`policy/route.ex`, `policy/schema.ex`, `adoption/route_inventory.ex`); the dep is tiny, maintained by the Dashbit team, and already transitive in the Phoenix ecosystem for most hosts. Keep. Copying would lose validation docs generation. Verdict: do NOT replace.
- `jason`: used in 46 files; already required by Phoenix. Keep.
- `phoenix_live_view` as a **hard** core dep: only about 6 core modules mention LiveView/Component. A host that is not LiveView-first is forced to pull it. Consider making it `optional: true` (as threadline does) if the Phoenix-first thesis admits non-LiveView hosts; otherwise keep and say so. Decision, not a defect; M effort with test cost.
- `telemetry`: keep (standard).
- Nothing else in the tree is a candidate; the "copy-paste over dep" instinct is already satisfied. The risk is in shipped LOC, not deps.

**Hex metadata hygiene**: core and all five companions have description, license, links (Changelog/Docs/GitHub), `files:` allowlist, `source_url`/`homepage_url`. Missing relative to Hex guidance: no `maintainers`, and `mix hex.build` unpack shows the tarball ships `guides/` + `priv/`; `exclude_patterns: ["brandbook"]` suggests a past leak, so assert the file list in CI (see F5). `script/check_dependency_security.sh` exists for advisory checks on root and example.

## 6. Static analysis posture and gate plan

| Tool | Status | Recommendation |
|---|---|---|
| `mix format --check-formatted` | passes locally; CI wiring unverified | **Gate** (confirm wired; add `.formatter.exs` `inputs` for `packages/*` if absent: root formatter only covers `config,lib,test`, so packages and `examples/` appear unchecked) |
| `mix compile --warnings-as-errors` | passes, wired in CI | **Gate** (keep) |
| `mix xref graph --format cycles --label compile` | not run in CI; currently 1 cycle | **Gate** after the one cycle is fixed (ratchet at 0 compile cycles) |
| `mix xref graph --format cycles` (all) | 3 cycles | **Advisory** with a committed baseline of 3, fail on increase |
| credo | not configured | **Advisory only**, start with a tiny `.credo.exs` (`Credo.Check.Readability.ModuleDoc`, `Refactor.Nesting`, `Warning.RaiseInsideRescue`, `Design.AliasUsage` off). Not a gate: it would be a dependency (dev-only) and a noise factory on a 49k-LOC base. Measure findings first (project's own lesson: PR #173, "measure a check's findings before making it merge-blocking"). |
| dialyzer | not configured | **Do not add** to core now. 563 specs over 899 defs plus macros makes a dialyzer PLT cost and noise high for this stage. Revisit for L0 only after the L2 split (mid-term). |
| SwiftLint | not configured | **Advisory**, `swift format`/SwiftLint with a minimal ruleset on `Sources/` only, run in the existing iOS lane. Do not add Swift deps; SwiftLint is a CLI, not a package dependency. |

## 7. Architecture fitness functions (cheap, non-tautological)

Each should be a single ExUnit test or tiny script, failing on a real violation, with a baseline that can only ratchet down.

| ID | Check | How | Non-tautology note |
|---|---|---|---|
| F1 | Zero **compile** cycles; all-cycles count not above baseline 3 | `mix xref graph --format cycles` parsed in a test | fails if someone adds a compile edge on `manifest/types.ex` |
| F2 | **Layer direction:** L0 modules must not reference L2 (`ProofLane`, `ReleaseCandidate`, `ReleaseStatus`, `Planning`, `SupportMatrix`, `Doctor.PublishReadiness`) | `mix xref graph --sink`/`--source` or `Mix.Tasks.Xref` call-graph read, assert no edge L0 -> L2 | Currently fails once for `Manifest.Builder` -> `SupportMatrix`; that is the point. Existing guards (`companion_guard`, `component_tier_guard`) are the template. |
| F3 | **Public API snapshot:** list every non-`@moduledoc false` module and its public `def`/arity into `test/fixtures/public_api.txt`; PR diff must update it | `Code.fetch_docs/1` over `Application.spec(:crosswake, :modules)` | Fails on accidental exposure; makes API review a one-line diff. |
| F4 | **Route ownership closed:** every route in the example host and the generated shell has exactly one of the declared runtimes; no unknown runtime atoms | extend the existing manifest validator test over the example host router | Protects the core thesis directly, not an internal metric. |
| F5 | **Hex tarball content allowlist:** `mix hex.build --unpack` file list equals a committed expectation; no `.planning`-reading modules once L2 is split | CI step using the existing `script/verify_hex_tarball.sh` | Would have caught finding 1. |
| F6 | **Dependency ratchet:** `mix deps.tree` runtime direct deps per package equal a committed list; any new dep requires editing the list with a one-line justification | script comparing `mix deps` output | Directly encodes "another copy-paste is better than another dep". |
| F7 | **Telemetry/doctor privacy:** every telemetry event metadata key is in a closed allowlist | grep/AST scan of `:telemetry.execute` call sites vs allowlist | Backstops the sensitive-data rules in `AGENTS.md`. |
| F8 | **No `rescue _` in L0:** AST scan fails on bare `rescue _ ->` in `lib/crosswake/{bridge,policy,router,offline,manifest,compatibility}` | `Code.string_to_quoted` | Today fails at `bridge.ex:685,694,709`. |
| F9 | **Repo root allowlist:** `git ls-files` of root-level files matches a committed list | 10-line shell | Prevents the scratch-file regression. |

## 8. Ranked recommendations

| # | Horizon | Effort | Recommendation | Depends on |
|---|---|---|---|---|
| R1 | immediate | S | Remove the 14 tracked root scratch files in one PR (`git rm`; move `gen_manifest.exs` to `script/` only if still used, check references first; the bundle is not needed in a public repo). Add F9. | none |
| R2 | immediate | S | Replace three bare `rescue _` in `bridge.ex:685,694,709` with explicit results; add F8 for L0. | none |
| R3 | immediate | S | Break the one compile-connected cycle (`bridge/contract` / `bridge/denial` / `manifest/types` / `shell/denial`), likely by moving the shared denial type into a leaf module with no outgoing edges. Add F1. | none |
| R4 | immediate | S | Add `@moduledoc` to 4 undocumented mix tasks; add `@spec`/`@doc` to `bridge/reply.ex`, `bridge/denial.ex`, `policy/schema.ex`, `shell/ios_host_origin_mode.ex`. | none |
| R5 | near | M | Add F2 (layer direction), F3 (public API snapshot), F5 (tarball allowlist), F6 (dep ratchet) as a single "architecture" ExUnit file plus one CI step; start each at current baseline. Add credo advisory and SwiftLint advisory. | R3 |
| R6 | near | M | Rename `phase_N_*`/`validate_phaseNN_*` functions to domain names (`manifest_posture`, `auth_findings`, `companion_seam_findings`); strip `Phase N / D-NN` provenance from `lib/` comments (360 sites) into the planning archive. Do it mechanically per file, not as a big-bang. | none |
| R7 | near | M | Fix Builder <-> SupportMatrix inversion: support matrix reads manifest, never the reverse. | F2 |
| R8 | mid | L | Split L2 out of the Hex `crosswake` package (new `crosswake_release` or keep as repo-internal `tools/` Mix project not published). Moves about 19k LOC out of every adopter's tarball. Needs a decision on which mix tasks adopters need (`gen.*`, `doctor`, `inspect`, `install`). Do **not** start this during the v21 adopter proof window unless the adopter evidence demands it, because it touches the publish DAG (core-first). | R5, F5 |
| R9 | mid | M | Split `doctor/doctor.ex` (2,818 LOC) by concern, one module per check family; same for `ActivationCoordinator.swift` (894 LOC). | R6 |
| R10 | mid | M | Decide `phoenix_live_view` required vs optional for core. | none |
| R11 | long | M | Revisit dialyzer for L0 only after R8. Swift 6 strict-concurrency pass on `CrosswakeShellCore` with a deliberate public-API review. | R8 |

## 9. Explicit "do NOT do" list

- Do not add dependencies to replace dependencies; the tree is already minimal. Do not copy `nimble_options` or `jason` into core.
- Do not add dialyzer or make credo merge-blocking now.
- Do not generalize `proof_lane`, `release_candidate` or `commerce` into reusable frameworks; shrinking or moving them is the direction.
- (Superseded by user decision, see section 9A: Android is UNFROZEN.) Do not unfreeze Android by copying iOS files; close parity through shared contract vectors.
- Do not rewrite `doctor.ex` or `ActivationCoordinator.swift` in a big bang; split by concern behind green tests.
- Do not add a boundary library (e.g. `boundary`); F2 via xref achieves the same with zero new deps.
- Do not rename public modules for aesthetics; renames of `@moduledoc false` internals only.
- Do not delete `.planning` provenance when stripping code comments; move it, do not lose it.

## 9A. Addendum: Android unfrozen, and stop-list reopening seams

Two user decisions arrived mid-task: Android is unfrozen as soon as possible, and synthetic adopter profiles may reopen ADR stop-list items through the ADR reversal process. Both are applied here. `AGENTS.md` and the ADR still say "Android frozen"; per the project's own rule they must be updated together with this decision (R12).

### Android shell audit (measured)

**Size and shape.** `packages/crosswake-shell-core-android`: 13 main-source Kotlin files plus 4 test files, 2,667 LOC total (iOS: 17 main Swift files, 5,505 LOC including tests). Largest: `ActivationCoordinator.kt` 679, `BridgeChannel.kt` 395, `packs/PackStore.kt` 261, `transfer/TransferCoordinator.kt` 252. Generator templates: 12 Android files under `priv/templates/crosswake/shell/android` (`MainActivity.kt.eex`, `CrosswakeViewModel.kt.eex`, Gradle files, manifest, theme).

**Dependencies (all direct):** `androidx.core:core-ktx 1.12.0`, `kotlinx-coroutines-android 1.7.3`, `kotlinx-serialization-json 1.6.0`, `androidx.webkit 1.10.0`; test `junit 4.13.2` and `org.json 20231013`; publish plugin `com.vanniktech.maven.publish 0.31.0`. Four runtime deps versus Swift's zero. Replace/delete candidates: `androidx.webkit` (the build file comment hedges "we might need", so verify it is actually imported; if not, delete, S). `BridgeChannel.kt` builds replies with `JSONObject`, which forces the `org.json` test dep while kotlinx.serialization is also present: pick one JSON stack (prefer kotlinx.serialization) and drop `org.json` (S-M).

**Gradle/JVM posture:** AGP 8.4.1, Kotlin 1.9.24, Gradle 8.7, `compileSdk 34`, `minSdk 26`, JVM 17 source/target. By October 2026 this is likely well behind current AGP/Kotlin 2.x/compileSdk lines (relies on prior knowledge, not a fetched release page; UNVERIFIED). Start the unfreeze with one deliberate toolchain bump PR validated by the existing hermetic JVM tests plus Maven-local resolution, updating the generator templates in `priv/templates/.../android` in the same PR so library and generated host cannot pin different toolchains. Repositories are locked to `google()` and `mavenCentral()` with `FAIL_ON_PROJECT_REPOS`: good hygiene. `local.properties` exists locally but is not tracked.

**Parity gaps vs iOS (file level):** iOS has `NavigationCoordinator`, `NavigationTopology`, `NavigationTransition`, `NavigationTransitionChannel`, `ServerEvent`, `ConnectionState`, `CrosswakeShellConfig`, `PackProvider` as separate files. Android has no `Navigation*`, `ServerEvent`, `ConnectionState` or `PackProvider` file (pack logic is folded into `packs/PackStore.kt`). `priv/contract_vectors/navigation_topology_vectors.json` exists; Kotlin consumption was not confirmed. Also absent on Android: physical-device proof, offline island with scoped replay, foreground media adapter. Android has 4 test files against iOS's larger set (`HostCommandSeamTests`, `PackStoreTests`, `BridgeConformanceTests`, others).

**Style and static analysis:** no detekt, ktlint, `.editorconfig` or lint config. Crude grep found no `!!`, `GlobalScope`, `println` or `@Suppress` in main sources (best-effort).

**Android recommendations (ordered):**
1. (immediate, S) Remove `androidx.webkit` if unimported.
2. (immediate, M) Parity ledger driven by the shared `priv/contract_vectors/*.json`: both shells must pass the same vectors instead of per-file mirroring (see F10).
3. (near, M) One toolchain bump PR (AGP/Kotlin/Gradle/compileSdk) with templates updated together.
4. (near, M) ktlint advisory plus `.editorconfig`; no detekt yet.
5. (near, L) Port parity pieces only as synthetic profiles demand them: `Navigation*` and `ServerEvent` first (contract surface), media/offline last.
6. (immediate, S) Update `AGENTS.md`, ADR, requirements, capability/support truth together, retiring "Android frozen" as superseded.

**Do not (Android):** do not hand-port Swift to Kotlin line by line; do not add Android device-proof lanes before hermetic vector parity exists; do not let generator template and `build.gradle.kts` pin different toolchains.

### Seams: which stop-list reopenings would be clean vs messy

| Stop-list item | Today's seam | Verdict | Why |
|---|---|---|---|
| Native menu/action-button breadth | `bridge/catalog_guard.ex` (945 LOC), `bridge/commands/*`, `mix crosswake.gen.native_controls_ui`, `capability_map.ex` | CLEAN if added as catalog data | A guarded command catalog is the right seam. Messy risk: generation logic sits inside a Mix task, not a testable module. New controls must be catalog entries plus vectors, not new native switch statements. |
| Commerce productionization | `commerce/` (688 LOC) and `companions/{store_kit,play_billing}` inside core | MESSY | Commerce lives in core, contradicting the extracted-companion rule (`companion_guard.ex`, D-21 "core names no companion"). Clean path: extract to a `crosswake_commerce` companion implementing `Crosswake.Companion` (`enabled?`, `route_gated?`, `kill_switch_active?`, `denial_codes`, `forbidden_metadata_keys` already exist), then extend. |
| Capture/device packs | `packs/`, `native_escape/`, `transfer/`, `offline/content_pack.ex` | MIXED | Contracts are tidy (358 and 308 LOC), but pack logic is duplicated per shell (`PackStore.swift`, `PackStore.kt`). Clean only if pack capabilities are expressed as contract vectors. |
| New companions | `Crosswake.Companion` behaviour, 5 extracted packages, `crosswake_rulestead` (202 LOC) as template | CLEAN | Strongest seam in the repo. Add a generator only when a second new companion appears. |
| Generic/background sync, generic native storage | `offline/{journal,replay,runtime,status}` 863 LOC; `SafeObservation` closed `@runtimes [:offline_island]` | MESSY by design | Each addition changes a closed vocabulary, doctor/telemetry and both shells. Keep the vocabulary closed and versioned; a new runtime needs a contract version bump, not an enum append. |
| Dashboard | `operator_inspection/`, `doctor/json_formatter.ex` | CLEAN | Formatters already separate data from presentation; build out of tree. |
| Android parity | shell packages plus generator templates | CLEAN if vector-driven, MESSY otherwise | See Android section. |

Cross-cutting rule: each reopening is gated by the ADR reversal process citing a named synthetic profile as evidence, and lands as (a) contract data plus vectors, (b) one companion or one catalog entry, (c) a fitness-function baseline update. Reject additions that require editing `case` statements across L0 modules.

**F10 (cross-shell parity):** Swift and Kotlin test suites must consume the same `priv/contract_vectors` files, and a test asserts both reference the same vector-set hash. **F11 (companion boundary):** nothing under `lib/crosswake/` other than `companion*` references `lib/crosswake/companions/`; that directory should be empty after commerce extraction.

**R12** (immediate, S): record Android-unfrozen and the synthetic-profile reversal path in `AGENTS.md`, the ADR, PROJECT and requirements. **R13** (near, M): extract commerce to a companion. **R14** (near, M): Android toolchain bump.

## 10. Gaps and caveats

- Android audit is by file size, build config and crude grep; Kotlin sources were not read line by line and `androidx.webkit` usage was not confirmed.

- Dead-code and duplicated-logic claims are by structure and grep, not by a clean tool run; run `mix xref` per-module unreferenced analysis in a worktree before deleting anything.
- Whether `format --check` and `xref` are in CI was not conclusively determined; verify in `.github/workflows/crosswake-ci.yml`.
- Swift lens is shallow (grep and file sizes); a real Swift 6 concurrency/API-surface review needs a Swift-toolchain run.
- Companion packages were measured by size and `mix.exs` only; their internals were not read line by line.
- No external sources were consulted this session; conventions are from prior knowledge.
