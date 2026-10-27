# Phase 196: Spec and structure ratchet — Pattern Map

**Mapped:** 2026-10-27
**Scope:** `--ws quality-ratchet-release`; bounded source inspection on `docs/195-closeout`.
**Files analyzed:** 20 assignment groups below; grouped native readers and proposed helper names are intentional, not an executor file manifest.
**Analogs:** Five primary reuse families; in-place owners provide additional local seams. New adapters have partial matches only.

## File Classification

Paths marked **proposed** are suggested organization, not existing files. All existing analog paths named here were verified with `git ls-files`; no installed mirrors are analogs.

| New/modified file or bounded file group | Role | Data flow | Closest analog | Match quality |
|---|---|---|---|---|
| `test/crosswake/guides/evidence_manifest_test.exs` | test | file-I/O | Own committed-manifest test, lines 82–92 | exact |
| `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | test | request-response | Own Plug canary, lines 46–59 | exact, unsafe fallback replaced |
| `test/test_helper.exs`; `packages/crosswake_threadline/test/test_helper.exs` | config | batch | Root helper exclusion pipeline, lines 13–59 | exact / role-match |
| `test/crosswake/bridge/bridge_behavioral_vector_test.exs` | test | file-I/O | Own corpus reader and evaluator, lines 61–87 | exact |
| Swift `BridgeConformanceTests`, `BridgeReplyLegTests` under `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/` | test | file-I/O | Own existing decoded-corpus loops; BridgeConformance lines 211–245 | exact |
| Kotlin `BridgeConformanceTest`, `BridgeReplyLegTest` under `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/` | test | file-I/O | Own existing JSON readers; BridgeConformance lines 157–167 | exact |
| Swift `ActivationConformanceTests`, `OfflineIslandAdmissionTests`, `Phase180TwinFeasibilityTests`, `NavigationCoordinatorTests`; Kotlin `ActivationConformanceTest` | test | file-I/O | Existing reader owners; research consumer inventory identifies metadata versus verdict use | exact |
| `script/check_absence_is_not_success.exs`; **proposed** absence baseline | utility/config | batch/transform | Existing checker scope and exit contract, lines 64–157; AST mechanics from ComponentTierGuard | exact + partial AST |
| `test/crosswake/proof/absence_is_not_success_test.exs` | test | batch/file-I/O | Own disposable-tree subprocess helpers | exact |
| `lib/crosswake/offline/safe_observation.ex`; `test/crosswake/offline/{safe_observation,journal}_test.exs` | model/test | transform | Existing validated projections and exact-error tests | exact |
| `lib/crosswake/policy/compiler.ex`; existing compiler/route tests; **proposed** `test/crosswake/policy/finite_product_test.exs` | service/test | transform | CompilerTest route fixture builder, lines 250–262 | exact / role-match |
| `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/error.ex` if structured-key correction requires them | model | transform | Existing Route/Compiler boundary; keep source paired with normalized route | exact |
| **Proposed** `lib/crosswake/bridge/protocol_version.ex`; `lib/crosswake/bridge/contract.ex`; `lib/crosswake/manifest/types.ex` | utility/model | transform | Contract `version/0`, line 106; Types default, line 772 | partial leaf / exact callers |
| `lib/crosswake/bridge.ex` | service | request-response/file-I/O | Own advisory location helpers, lines 666–710 | exact, rescue behavior replaced |
| `lib/crosswake/compatibility/route_gate.ex`; corresponding existing behavioral tests | service/test | request-response | Own dependency/auth extension containment, lines 138–169 and 309–323 | exact, preserve denial authority |
| **Proposed** `script/check_architecture_ratchet.exs` and semantic rescue-exception baseline | utility/config | batch/transform | ComponentTierGuard parser; absence checker scope/exit behavior | partial |
| **Proposed** runtime-dependency baseline and child evaluator (may live in architecture helper) | config/utility | batch | Root aliases' sequential project roster, `mix.exs:74–86`; evaluated Threadline declarations | partial |
| **Proposed** `test/crosswake/proof/architecture_ratchet_test.exs` and fixture Mix projects | test | batch/file-I/O | Absence checker subprocess fixture tests | role/data-flow match |
| `test/js/ci_secret_masking.test.mjs`; existing verification wiring only as needed (`mix.exs`, `script/repository_verification_stages.json`, `.github/workflows/crosswake-ci.yml`) | test/config | batch | Existing derived-secret analyzer and spawned Bash controls; existing verification entry points | exact |
| **Proposed phase-owned** Muex wrapper, real-report fixtures, pilot decision/evidence | utility/test | batch/file-I/O | Subprocess test contract and fail-closed artifact checks only; report schema has no exact local analog | partial |

## Pattern Assignments

### 1. Optional evidence and vector readers

Copy the root helper's **single merged exclusion list**, `test/test_helper.exs:13–24,59`:

```elixir
exclude =
  []
  |> then(fn acc ->
    if System.get_env("MIX_INCLUDE_RULESTEAD") == "1",
      do: acc,
      else: [{:advisory_only, true} | acc]
  end)
# Existing pipeline continues; configure once after all exclusions are composed.
if exclude != [], do: ExUnit.configure(exclude: exclude)
```

Use that organization for explicit optional evidence tags. The generated-manifest owner's `case` at lines 95–104 and Threadline's `Code.ensure_loaded?` branch are defect sites, not skip patterns to copy. Keep the committed example's real validator call:

```elixir
# test/crosswake/guides/evidence_manifest_test.exs:90–92
with_artifact_fixture(manifest, fn artifact_root ->
  assert validate_manifest(manifest, artifact_root) == :ok
end)
```

For generated evidence, use its supplied artifact root, not this synthetic committed-example fixture. A supplied invalid path remains an enabled failure.

Retain each language's real evaluator, then surround it with independently pinned load/execution checks. Existing read/filter seams:

```elixir
# test/crosswake/bridge/bridge_behavioral_vector_test.exs:61–62,81–87
@vectors_path "test/fixtures/bridge_contract_vectors.json"
@vectors Jason.decode!(File.read!(@vectors_path))
# In the test:
vectors = @vectors["vectors"]
for vector <- vectors do
  # Existing native_only filter follows; increment actual executions inside it.
end
```

```swift
// BridgeConformanceTests.swift:211–219 (directory in classification table)
let bridgeVersion = vectorsFile.bridgeProtocolVersion
for vector in vectorsFile.vectors {
    if vector.elixirOnly == true { continue }
    // Preserve the real BridgeChannel.evaluate assertions below this seam.
}
```

```kotlin
// BridgeConformanceTest.kt:157–167 (directory in classification table)
val vectors = vectorsJson.getJSONArray("vectors")
for (i in 0 until vectors.length()) {
    val vector = vectors.getJSONObject(i)
    if (vector.optBoolean("elixir_only", false)) continue
    // Preserve the real status/denial checks.
}
```

Research inventories 15 loaded request cases, 9/14/14 eligible Elixir/Swift/Kotlin cases, 2 reply-leg cases, and a separate navigation topology corpus of 5 with 1 selected case. Confirm at execution and count completed evaluations after filters. Metadata-only readers get read-boundary counts, not fictional JSON verdict execution counts. Structural readers such as `test/crosswake/contract/contract_drift_test.exs` remain a separate inventory category. Generator source is `lib/mix/tasks/crosswake.contract.gen.ex`; do not edit generated corpus data merely to satisfy counts.

### 2. AST scripts and discriminating fixture tests

Primary analogs: `lib/crosswake/component_tier_guard.ex`, `script/check_absence_is_not_success.exs`, and `test/crosswake/proof/absence_is_not_success_test.exs`.

Parser/error shape to copy from ComponentTierGuard, lines 287–291:

```elixir
case Code.string_to_quoted(source, []) do
  {:ok, ast} -> wrap(checker.(ast))
  {:error, detail} -> {:violation, [{:unparseable_source, detail}]}
end
```

Its `Macro.prewalk/3` accumulator at lines 294–308 is appropriate for finding syntax. Collection safety needs a new lexical traversal carrying branch-local collection facts; a flat prewalk alone does not prove reachability. Strip AST metadata for normalized identity, retain enclosing test/function and multiplicity, and use lines only for current diagnostics. Reuse no collection inventory heuristic that treats arbitrary attributes or `[]` as nonempty.

The absence checker provides independent discovery and fail-closed scope checks, lines 142–154:

```elixir
actual =
  root |> Path.join(glob) |> Path.wildcard() |> Enum.filter(&File.regular?/1) |> Enum.sort()
expected = expected_scope(label, root)
error =
  case assert_full_scope(actual, expected) do
    {:error, reason} -> reason
    :ok -> if length(actual) >= min, do: nil, else: "below pinned minimum"
  end
```

Extend the independent walk and exact project scope for companions. Keep the checker's `run/2 -> 0 | 1` and reporting contract; do not replace its existing mutation/citation checks.

Subprocess fixture pattern, absence test lines 326–344:

```elixir
defp run(root, extra_argv), do: run_argv(["--root", Path.expand(root) | extra_argv])
defp run_argv(argv) do
  System.cmd("elixir", [@script | argv], stderr_to_stdout: true, cd: @repo_root)
end
# Fixture creation uses File.mkdir_p!/1 and File.write!/2 beneath tmp.
```

Use source-string fixtures for guard-only deletion, wrong collection/branch, duplicate baseline occurrence, empty attribute, literal true, renamed rescue and parse failure. Assert the source mutation changed text before asserting the new failure. Fixtures containing unsafe code must be treated as data, not findings in the guard's own test file.

### 3. Privacy boundaries and policy oracle

Use existing local aliases and `ExUnit.Case`; preserve `SafeObservationTest`'s `async: false` rationale rather than introducing VM-global cwd changes in async tests. Its exact telemetry/doctor map assertions at lines 19–38 are stronger examples than broad `Enum.any?` message checks.

The production projection pattern revalidates forged structs, `lib/crosswake/offline/safe_observation.ex:45–56`:

```elixir
def validate(%__MODULE__{} = observation) do
  observation |> Map.drop([:__struct__]) |> new()
end
def to_telemetry(%__MODULE__{} = observation) do
  with {:ok, observation} <- validate(observation) do
    # Existing bounded projection.
  end
end
```

Preserve revalidation for logger and doctor. Repair the demonstrated anchor defect at lines 94–97; test every accepted projection boundary with synthetic canaries. `JournalTest:38–44` already asserts `assert_raise ArgumentError, "CW-OFFLINE-SCOPE-REF"`; copy that exact-error approach for the suffix boundary table. Journal source lines 100–108 raises only the constant error, never rejected input.

For the new finite-product test, copy CompilerTest's route builder, lines 250–262:

```elixir
metadata =
  case Keyword.fetch(opts, :crosswake) do
    {:ok, crosswake} -> %{crosswake: crosswake}
    :error -> %{}
  end
%{path: path, metadata: metadata,
  helper: Keyword.get(opts, :helper, "route"), verb: Keyword.get(opts, :verb, :get)}
```

Build the expected 108-case oracle independently. Replace the older English-message membership checks with exact sorted `{key, route_id}` expectations. Compiler's `normalize_route/1:90–104` currently calls `validation_key(Exception.message(error))`; `validation_key/1:175–184` is the correction seam, not a reusable key extractor. Preserve the structured error across Route normalization. `duplicate_id_errors/2:107–119` indexes compressed routes back into managed routes: carry successful route/source pairs instead, with mixed-invalid-batch attribution tests. Changes to Route/Error are conditional on that minimal structured representation; no wider schema redesign.

### 4. Xref, version leaf and rescue exceptions

Use the existing subprocess fixture machinery for real temporary Mix projects. There is **no tracked local xref ratchet to copy**. The pinned Mix CLI is the adapter authority: fresh compile, independent source/manifest coverage, compile-label and compile-connected zero gates, then all-cycle maximum with `--fail-above`. Do not introduce SCC logic, human-output parsing or `--only-direct`. Measure the repaired maximum; research's four total SCCs are not the repaired baseline.

The new version leaf is a tiny dependency-free utility. Preserve `lib/crosswake/bridge/contract.ex:106`'s public `def version, do: @version` API through delegation, and change `lib/crosswake/manifest/types.ex:772`'s compile-time default to the leaf. Avoid denial serializer movement.

Bridge's three location helpers (`lib/crosswake/bridge.ex:666–710`) are advisory. Replace raising reads and wildcard rescues with explicit internal results; consume failures at the existing location fallback so authoring failures retain their original authority.

Two intentional extension boundaries are distinct from these helpers. Preserve the route gate's current sanitized result, lines 155–161:

```elixir
rescue
  _ ->
    result = {{:error, nil}, :adapter_unloadable}
    {result,
     %{companion_id: companion.companion_id(), route_id: route.id, exception: true}}
```

The wildcard syntax above must change; its denial and bounded metadata are the reusable behavior. The auth boundary at lines 309–323 likewise returns `{:deny, Denial.new(reason: :dependency_missing, ...)}`. Introduce only the two reviewed semantic records for broad named containment, keyed by file/function/normalized clause and call target. The AST checker must reject missing, stale, duplicate and additional records. Preserve catch containment and exercise arbitrary custom exceptions without recording exception contents.

### 5. Six Mix dependency surfaces

The root alias list (`mix.exs:74–86`) is the explicit five-companion roster alongside core. Copy its sequential process model, not its dependency fetching: production declaration evaluation must not call `deps.get`.

Threadline is the useful declaration-shape example, `packages/crosswake_threadline/mix.exs:45–50,58–61`:

```elixir
{:plug, "~> 1.0", optional: true},
{:phoenix_live_view, "~> 1.1", optional: true},
{:nimble_options, "~> 1.1"},
{:telemetry, "~> 1.0"},
{:ex_doc, "~> 0.38", only: :dev, runtime: false}
# crosswake_dep/0:
if System.get_env("CROSSWAKE_RELEASE") == "1",
  do: {:crosswake, "~> 0.2"},
  else: {:crosswake, path: "../.."}
```

Evaluate core plus `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline` in isolated child Mix processes for both declaration branches. Normalize tuple shapes, production availability, runtime flag and optionality; compare exact roster and names/classifications with nonblank purposes. Version/path spelling is not this baseline. The six `mix.exs` files are **inputs**, not six files requiring product edits. The new evaluator/baseline has no exact existing analog; use the subprocess fixture family for optional-dep addition, prod promotion, runtime flag, missing project and missing-purpose controls.

### 6. Node grammar and execution checks

Keep implementation in `test/js/ci_secret_masking.test.mjs`. Existing exportable helpers allow direct synthetic tests without a parser dependency. `ASSIGN:1069`, `runBlockBounds:1093–1102`, and the use loop at `1169` identify the old grammar's extension seams. Keep derivation state run-local; account for denied/unknown constructs before assignment filtering can discard them.

Copy the execution/negative-control relationship, lines 1337–1343:

```javascript
const protectedLog = runnerMaskedLog(runDerivation(script, user, pass), [user, pass]);
const leaked = leakedSecrets(protectedLog, watched);
assert.ok(leaked.length === 0, `leaked: ${leaked.length} value(s) reached the step log`);
const stripped = script.split("\n").filter((l) => !l.includes("::add-mask::")).join("\n");
const control = leakedSecrets(runnerMaskedLog(runDerivation(stripped, user, pass), [user, pass]), watched);
assert.ok(control.length >= 1, "control: without add-mask the derived token must leak");
```

`runDerivation:1320–1327` uses `spawnSync("bash", ["-c", ...])`, an explicit synthetic environment and withheld stderr on failure. `runnerMaskedLog:1196–1206` registers only stdout command lines and masks later output. Reuse these to distinguish parsing from actual expansion/registration/order. New findings should contain file/category, not RHS or credential values. Preserve nonsecret metadata output writes and the existing bounded derivation depth.

### 7. Real-report adapters and pilot evidence

No existing tracked Muex adapter/report fixture exists. Reuse subprocess status assertions and synthetic negative-control conventions, then implement the schema adapter from the pinned tool's **actual captured nonempty output** described in RESEARCH. A zero-source preflight is not that fixture. Do not fabricate `mutations_generated` or infer behavioral kills from invalid/timeout/no-coverage outcomes.

Keep installation and full pilot execution outside this mapping pass. Wrapper ownership is phase-local; project `mix.exs` and `mix.lock` remain free of Muex. Verify process success, fresh report identity, nonzero complete totals, known statuses, allowed target paths and useful outcomes per target before accepting the report. Use normalized before/after text plus mutator/file for survivor identity. Keep real Mix graph-output tests separate from Muex JSON tests; their dependencies have different failure contracts.

## Shared Patterns

- **Imports:** ExUnit aliases near the module header; native tests retain their current test framework/imports; Node keeps built-in `node:test`, strict assertions and child processes.
- **Authority:** No new auth middleware. Existing policy and route-gate denials remain authoritative; optional proof exclusion never authorizes a route.
- **Errors:** Return closed outcomes for expected diagnostic failures; fail tooling on read/parse/empty-scope errors. Never retain raw extension exceptions or rejected sensitive values.
- **Baselines:** Reviewed semantic identities with multiplicity and explicit stale-entry handling. No automatic refresh. Line citations here aid implementation and are not baseline keys.
- **Concurrency:** Fresh child processes for Mix evaluation; no concurrent VM-global cwd changes. Keep current test async settings unless isolation evidence supports changing them.
- **Wiring:** Reuse existing verification/test lanes after actual-main report-mode evidence. Root formatting omits scripts/companions by default, so explicitly format touched Elixir files there. No new recurring mutation lane follows from the pilot.

## No Exact Analog Found

| Target | Missing pattern | Planner action |
|---|---|---|
| Branch-sensitive absence multiset | Existing guard is lexical; ComponentTierGuard is syntactic | Add bounded lexical facts and fixture controls, preserving discovery floors |
| Xref threshold/coverage adapter | No current xref guard | Use pinned Mix behavior and real fixture projects |
| Semantic rescue exceptions | Existing component guard has no comparable exceptions | Implement two exact reviewed records and stale/duplicate checks |
| Evaluated six-project dependency baseline | Existing aliases only orchestrate test commands | Add isolated declaration evaluation and normalized classification |
| Muex report adapter | No committed real report | Capture pinned tool output first; derive schema fixtures from it |

## Metadata

**Search scope:** root `lib/`, `test/`, `script/`, six Mix projects, iOS/Android test owners, existing workflow/verification references.
**Primary extraction families:** optional exclusions, fail-closed scanner discovery, AST predicates, subprocess fixtures, Node executed masking controls. Search stopped after these strong matches; no external research, pilot, source edits or test runs were performed.
**Planning status:** Phase 195 remains last completed; Phase 196 context/research are available and implementation is unstarted. This document supplies patterns, not verification evidence or a changed lifecycle handoff.
