# Phase 180: Bounded Digital Twin Demonstration - Pattern Map

**Mapped:** 2026-10-13
**Code root (read-only):** `/private/tmp/crosswake-phase179-impl` (HEAD `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, verified). All paths below are relative to it unless prefixed `.planning/`.
**Files analyzed:** 14 new/modified surfaces
**Analogs found:** 13 / 14 (the native playback adapter has a precedent only, not a join analog)

Tracked-source note: all analogs are in the candidate checkout, a separate repo. Candidate paths were read directly from disk. Run `git ls-files` inside the candidate before the planner cites a path as an edit target.

## 1. Feasibility / scope gate (D-03 / D-04) - confirmed anchors

The string `host.study.audio.play` appears nowhere in the candidate (greps found no file). That is expected, because the command is only proposed. The three connected facts are:

| Fact | Anchor | What it shows |
|---|---|---|
| A. Route declaration rejects the command | `lib/crosswake/policy/validator.ex:9-21` (`@known_capabilities`), `:120-135` (`validate_capabilities/2`) | The known set is `Manifest.Builder.public_route_capability_ids() ++ compatibility_route_capability_ids() ++ ~w(audio background_audio background_sync document_preview generic_plugin_bus lock_screen_controls microphone webrtc)`. Any other string produces `%{key: :capabilities, message: "unknown capability ..."}`. Lists are in `lib/crosswake/manifest/builder.ex:13-38`, accessors at `:185-189`. `host.*` ids are not in them. |
| B. Generated activation omits route capabilities | `lib/crosswake/shell/ios_host_generation.ex:21-30` | `Activation.new_request(route_id:, url:, source: :cold_start, origin:, manifest_source: :bundled, bridge_protocol_version:, native_runtime_version:, correlation_id:)` has no `capabilities:` key. `lib/crosswake/shell/activation.ex:74-90` defaults it with `Keyword.get(attrs, :capabilities, %{})` (`:90`), and `to_map` emits it at `:164`. |
| C. Native bridge requires the exact command in the session | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:409-428` (`evaluateHostCommand`), `:437-447` (`capabilityAvailable(for request:)`), `:53` (`LiveViewSession.capabilities`) | Needs `request.command.hasPrefix("host.")`, `request.capability == request.command`, a non-nil `config.hostBridgeCommandDelegate`, `delegate.registeredCommands.contains(command)`, and `session.capabilities[command]` present and `SemVer.compatible`. Failure returns a deny with reason `undeclared_capability`. |
| D. Registration is not route authority | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift:36-50` (`registeredCapabilities` appends `hostBridgeCommandDelegate.registeredCommands`); `CrosswakeDelegates.swift:33-40` (`HostBridgeCommandDelegate`); `:11` (`public weak var hostBridgeCommandDelegate`) | The delegate is held weakly, so the host must retain it strongly. |
| E. Swift activation field | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:39,53,68,81,99,199,238,488` | `capabilities` is carried through activation and filtered. It is not manufactured. |

### Existing tests that exercise the join (analogs for a bounded feasibility test)

**Test A, policy rejection.** `test/crosswake/manifest/validator_test.exs:430-476`.

- It builds `Crosswake.Policy.Route.new!(id:, runtime: :live_view, offline: :cached_read_only, capabilities: [...], security: :standard)` and a `managed_routes` list `[%{path:, helper:, verb: :get, source: %{file: "test", line: 1}}]`.
- It calls `Crosswake.Policy.Validator.validate(routes, managed_routes)` and asserts:

```elixir
assert Enum.any?(invalid_errors, fn error ->
  error.route_id == "bad" and
    String.contains?(error.hint, "semantic Crosswake capability families")
end)
```

- Copy it with `capabilities: ["host.study.audio.play"]` and with `["audio"]`. The twin test should assert the rejection exists, with no core change. It is `async` and pure.

**Test B, activation projection.** `test/crosswake/shell/ios_host_config_test.exs:84-117` calls `IOSHostGeneration.render(%IOSHostConfig{...})` and decodes `first.activation` with Jason. The existing assertions are `first_activation["route_id"]`, `["url"]`, and `refute Map.has_key?(first_activation, "scope_ref")`. The helper `config(router, entry_route_id)` is at `:120-140`. The `ManagedRouter` fixtures are defined at the top of the file.

- The feasibility test should assert `Jason.decode!(first.activation)["capabilities"] == %{}` (or the key is absent) for the study route. It should also assert the manifest has no `host.study.audio.play` capability entry.

**Test C, native.** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostBridgeCommandTests.swift:1-60`.

- Positive: `session(capabilities: ["host.accrue.purchase": "1.0.0"])` plus `CrosswakeShellConfig(hostBridgeCommandDelegate: delegate)` returns `status == "ok"`.
- Negative: an unlisted command returns `denial.denial.reason == "undeclared_capability"`, and `delegate.commands.isEmpty`.
- Native tests are not runnable under D-27 and the "no builds/tests" constraint. Use Test C only as source-level evidence that the session must carry the key. The bounded feasibility check should be the Elixir tests A and B (pure, fast, no simulator).
- The existing `host.accrue.purchase` delegate test shows the delegate and bridge half works when the session already carries the capability. The gap is only declaration and projection.

**Planner note.** The gate is a test that asserts the current rejection or omission and reports TWIN-01..06 incomplete. It must not edit `validator.ex`, `ios_host_generation.ex`, `activation.ex` or `builder.ex` (D-04). Candidate for the new file: `test/crosswake/proof/phase180_twin_feasibility_test.exs`. Tests under `test/crosswake/proof/` are the repo's phase-proof convention. The recovery tree has `phase142_release_integrity_test.exs`, `phase153_ios_mirror_unblock_test.exs` and `phase165_ci_integrity_test.exs`. Confirm which exist in the candidate before picking a name.

## File Classification

| New/Modified file | Role | Data flow | Closest analog | Match |
|---|---|---|---|---|
| `test/crosswake/proof/phase180_twin_feasibility_test.exs` (new) | test | request-response (pure) | `test/crosswake/manifest/validator_test.exs:430`, `test/crosswake/shell/ios_host_config_test.exs:84` | exact for the join |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (new) | mix task | batch / request-response | `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`, `crosswake.proof_lane.verify_navigation_shell.ex` | role-match |
| `lib/crosswake/proof_lane/twin_receipt.ex` (new, twin-only) | utility / schema | transform | `lib/crosswake/proof_lane/physical_iphone_contract.ex`, `lib/crosswake/offline/safe_observation.ex` | role-match (mirror only) |
| `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` (new) | test | batch | `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | exact |
| `test/crosswake/proof_lane/twin_receipt_test.exs` (new) | test | transform | `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs`, `navigation_shell_advisory_test.exs`, `recovery_edges_test.exs` | role-match |
| `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex` (modify, recovery) | controller | request-response | itself, `:7-35` | exact |
| `.../controllers/offline_html/index.html.heex` (modify, free-form control, recovery) | template | request-response | itself | exact |
| `examples/phoenix_host/priv/static/offline_study.js` (modify) | component (client) | event-driven | itself | exact |
| `examples/phoenix_host/lib/crosswake_example/local_first/{study,replay_admission,review_event}.ex` (read-only; free-form already supported) | model/service | CRUD | themselves | exact |
| `examples/phoenix_host/config/runtime.exs` (read-only; runner passes env) | config | n/a | `:8-24` | exact |
| `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift`, `LiveViewContainerViewController.swift` (modify, only if gate clears) | provider / view controller | event-driven | themselves; `NavigationRouteDelegate` at `CrosswakeShellApp.swift:157` | exact |
| `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift` (modify, only if gate clears) | provider | file-I/O | itself | exact |
| new host-private audio playback adapter (only if gate clears) | provider | event-driven | `examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift:407,466-468,542,579-581`, `HostLearningBundleProvider.swift` | precedent only |
| `examples/ios_shell_host/CrosswakeShellTests/*` and `CrosswakeShellUITests/*` (only if gate clears) | test | event-driven | `CrosswakeShellTests/PronunciationPackProviderTests.swift`, `CrosswakeShellUITests/NavigationShellTests.swift` | role-match |

## Pattern Assignments

### `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (mix task)

**Analog A:** `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` (121 lines).

**Imports and switches** (lines 1-12):
```elixir
defmodule Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShell do
  use Mix.Task
  import Bitwise
  alias Crosswake.ProofLane.{Evidence, NavigationShellAdvisory}
  @shortdoc "Retains digest-bound advisory navigation-shell evidence"
  @switches [destination: :string, observation: :string, run_root: :string]
```

**Strict option parsing, fail-closed** (lines 14-22). The invalid-options path raises a stable id with `Mix.raise("navigation_shell.invalid_options")`, and the final failure is `Mix.raise("navigation_shell.verification_failed")` (line 51).
```elixir
{options, positional, invalid} = OptionParser.parse(args, strict: @switches)
if positional != [] or invalid != [] or Enum.any?(..., &(not is_binary(options[&1]))) do
```

**Private run-root and contained-file checks** (lines 66-92). Copy `private_directory/1` (`lstat`, directory, `mode &&& 0o077 == 0`) and `contained_regular_file/3`. Both are needed for D-13 and D-16.

**Run invalidation** (lines 94-103): `invalidate/2` removes the observation and nonce after the run. This is the stale and reused run-binding precedent for D-20.

**Nonce binding** (lines 56-64): `nonce == observation_map["run_nonce"]`. Mirror this for run binding.

**Analog B (exit codes):** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`.

- Line 69: `if status, do: System.halt(status)`.
- Lines 105-134: `exit_status_for/1` maps `"PI-REPORT-OUTCOME"` to `1`, `:readiness_blocked` to `2`, and uses an explicit catch-all to `2`.
- Lines 134+: `classification_label/1` ("refuted" for 1).
- Emits JSON with an `exit_classification` field (moduledoc lines 16-22).
- Mapping onto D-22: 0 pass, 1 observed failure ("refuted"), 2 blocked or missing prerequisite. The catch-all-to-2 rule means an unknown rule id degrades to "could not run", never to a defect or a pass. Note `Crosswake.ReleaseStatus` uses a distinct exit 3 for could-not-verify, which D-22 asks to reconcile.

**Caveat:** the physical task's `System.cmd` calls are unbounded (research notes). Do not copy any process-run pattern from it. D-16 requires bounded, handle-tracked children (`Port`/`System.cmd` plus an explicit timeout).

**Report path convention:** the navigation task writes through `Evidence.promote(evidence_input, destination)` to `proof-lane-evidence.json` and then rescans with `Evidence.scan_stage` and `Evidence.check`. A twin command should write a separate twin report to a run-owned private path, not reuse `Evidence` promotion (D-18, which says not to reuse the physical-only promotion gate).

### `lib/crosswake/proof_lane/twin_receipt.ex` (closed, versioned, twin-only)

**Mirror (do NOT extend) `physical_iphone_contract.ex`** (97 lines).

Schema constants (lines 7-31):
```elixir
@schema_version 2
@owners [:device_local, :backend_authority, :evidence_promotion]
@outcomes [:passed, :blocked, :unavailable]
@assertions [%{id: "PI-PACK-INSTALL-AUDIO", owner: :device_local}, ...]  # 19 entries
```

Exact-roster validation (lines 50-95):
```elixir
def validate_report(report) when is_list(report) do
  if Enum.all?(report, &exact_report_entry_shape?/1) do
    ...
    cond do
      length(report) != length(@assertions) or Enum.uniq(supplied_ids) != supplied_ids or
          Enum.sort(supplied_ids) != Enum.sort(expected_ids) -> {:error, "PI-ASSERTIONS-COMPLETE"}
      supplied_ids != expected_ids -> {:error, "PI-ASSERTIONS-ORDER"}
      not Enum.all?(report, &valid_report_entry?/1) -> {:error, "PI-ASSERTIONS-OWNER"}
      true -> :ok
```
and `exact_report_entry_shape?/1` (`map_size == 3` and a key-set equality check).

Twin adaptations:
- Use a distinct id prefix (for example `TW-T01-...`).
- Use owners such as `:app_process`, `:webview`, `:host_adapter`, `:phoenix_ecto`, `:runner`.
- Use a distinct `@schema_version`.
- Use a different module name.
- Key the roster on T01-T10 groups with closed sub-observation sets (D-17).
- Keep the status derivation as failed over blocked over passed (D-18).
- Never import `PhysicalIphoneContract`, because the 19-assertion roster belongs to that contract.

**Safe-observation precedent: `lib/crosswake/offline/safe_observation.ex`** (124 lines).

- `exact_atom_keys` (lines 99-103): `Map.keys(attrs) |> MapSet.new() == MapSet.new(@replay_keys ++ @doctor_keys)`.
- Closed enums (lines 10-15).
- Route-id shape check (`~r/^route-[0-9a-f]{16}$/`, line 106).
- Bounded integer measurements (lines 115-123: `is_integer, >= 0, <= 1_000_000`).
- Structured error: `%Error{rule_id: "CW-SAFE-OBSERVATION-...", path: ...}` (line 122).
- Moduledoc: "This is deliberately not a redactor ... callers construct the small observation from declared values." This matches D-21 (construct closed observations at source).
- `new/1` then `validate/1` round trip (lines 31-50), which re-validates before projecting.

**Evidence precedent: `lib/crosswake/proof_lane/evidence.ex`** (719 lines). Defines `Evidence.Error` at line 45 and `scan_stage`, `check` and `promote`. Grep for the forbidden-field scan before cloning ideas for D-20's sensitive-field rejection. Do not call `Evidence.promote` for twin output.

### `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`

**Analog:** `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs`.

- Uses `use ExUnit.Case, async: false`.
- Defines `@task "crosswake.proof_lane.verify_navigation_shell"` and calls `Mix.Task.reenable(@task)` then `Mix.Task.run(@task, [...])`.
- Asserts `is_nil(Mix.Task.run(...))` for success.
- Asserts the observation and nonce files no longer exist (`refute File.exists?`).
- Uses `on_exit(fn -> File.rm_rf(root) end)` and a `run_fixture()` helper that creates a private root.
- For negatives (absent, fabricated or stale observation), assert `Mix.raise` messages. For exit-code tests, call `exit_status_for/1` directly, as the physical task exposes it with `@doc false`.
- AGENTS.md rule: exercise the production adapter with the dependency's real return shape. Fixtures must be generated through the real producer, not invented.

### Example Phoenix host island (confirmed locations)

All under `examples/phoenix_host/`:

| CONTEXT path | Actual in candidate | Status |
|---|---|---|
| `lib/crosswake_example/router.ex` | present in the candidate at `examples/phoenix_host/lib/crosswake_example/router.ex` (requalified during planning; offline-study route at lines 246-253, /_e2e guard at 587-630) | Plans cite this path. The earlier "missing" note came from an incomplete directory listing and is superseded. |
| `lib/crosswake_example_web/controllers/offline_controller.ex` | exists; `index/2` at `:7`; `recovery_route: recovery_route_capability()` at `:29`; `defp recovery_route_capability, do: %{status: "unavailable", destination: nil}` at `:35` with a TODO-002 comment at `:33` | present |
| `.../offline_html/index.html.heex` | exists | present |
| `priv/static/offline_study.js` | exists (also `storage_logic.js`, `storage_budget.test.js`) | present |
| `lib/crosswake_example/local_first/study.ex` | exists; list of event keys including `"free_form_answer"` at `:37` | present |
| `.../local_first/replay_admission.ex` | exists; `@event_keys`, `@free_form_event_keys`, `@physical_proof_event_keys` at `:7-16`; `authorize/4` at `:21-40` | present |
| `.../local_first/review_event.ex` | exists; `field(:free_form_answer, :string)` at `:12`; `validate_length(:free_form_answer, max: 4096)` at `:34` | present |
| other local_first | `sync_controller.ex`, `replay_auth.ex`, `physical_iphone_authority.ex`, `physical_iphone_run_provenance.ex`, `study_session_live.ex`, `study_history_live.ex` | extra owners to read |
| `config/runtime.exs` | exists; `port = String.to_integer(System.get_env("PORT") \|\| "4700")` at `:12`; `http: [ip: ip, port: port]` at `:14-15`; `System.get_env("DATABASE_PATH") \|\| Path.expand("../crosswake_example.db", ...)` at `:17-22` | present |
| `playwright.config.ts` | exists; `workers: 1` at `:30`; `port: 4700` at `:77`; `reuseExistingServer: repositoryVerify ? false : !process.env.CI` at `:78` | present |
| `e2e/offline_sync.spec.ts` | `e2e/` contains it plus `offline_storage.spec.ts`, `crosswake_proof_lane/`, `support/` | present |

**Free-form pattern (T03).** Backend admission already accepts `["card_id", "client_mutation_id", "free_form_answer", "rating"]` (`replay_admission.ex:9`, validated near `:65`, `:85`, `:95`). The visible gap is the template and `offline_study.js`. The planner should read the existing rating control wiring in `offline_html/index.html.heex` and `offline_study.js` and add the free-form input to the same outbox path. Preserve the existing selected-answer Playwright tests.

**Replay authority pattern (T06-T09).** `replay_admission.ex:21-40` shows the `with` chain: `valid_scope`, `valid_event`, `resolve(:session)`, `matching_scope`, `resolve(:route)`, `enabled?`, `sigra_allows?`, `domain_allows?`, which returns `{:allow, %{route: route}}` or `{:deny, closed_reason(reason)}`. Fault controls must prepare authority through these callbacks (`opts`), not return a canned `{:allow, ...}` (D-13, D-15).

**Runtime isolation hazard (D-13).** Defaults fall back to a repository-relative DB and port 4700. The runner must set `DATABASE_PATH` to a private run-root path and verify it before migration, and set `PORT` to the prepared origin's port. Do not call the existing E2E setup that drops the default DB.

### iOS reference host (examples/ios_shell_host)

Confirmed present: `CrosswakeShell/CrosswakeShellApp.swift`, `LiveViewContainerViewController.swift`, `PronunciationPackProvider.swift`, plus `RequiredPackView.swift`, `NavigationShellViewController.swift`. Tests: `CrosswakeShellTests/{DiagnosticExportManagerTests,NavigationShellTests,PronunciationPackProviderTests,RequiredPackViewTests}.swift`, `CrosswakeShellUITests/{NavigationShellTests,RequiredPackViewAccessibilityTests}.swift`. Fixtures: `Fixtures/{crosswake_manifest,route_activation,route_activation-dev,declared_pack_requirements,installed_packs,pack_inventory,route_denial}.json`.

Key anchors:
- `CrosswakeShellApp.swift:307-311` builds `HostPronunciationPackConfiguration.provider()` and passes `packProvider:`, `appInfoDelegate:`, `hapticsDelegate:` into the config. No `hostBridgeCommandDelegate:` is passed. A strongly retained delegate would be added here, but only if the gate clears.
- `CrosswakeShellApp.swift:157` is `NavigationRouteDelegate` (a small host-owned delegate class to copy for shape), and `:8-33` are `AppInfoProvider`, `HapticsProvider` and `UIActionDelegates` (`ObservableObject` retained via `@StateObject` at `:168`; `:173` holds `routeDelegate` as a `let`). The retention-by-owner pattern is the model for the strong reference, since `CrosswakeShellConfig.hostBridgeCommandDelegate` is `weak`.
- `LiveViewContainerViewController.swift:287-291`: `WKUserContentController`, `.add(bridgeChannel, name: BridgeChannel.handlerName)`, plus the navigation transition channel. A host-local wrapper for `message.webView` and frame identity (D-07) would be added here. `BridgeChannel.userContentController` (`BridgeChannel.swift:170-178`) currently ignores `message.webView` and `frameInfo`, and only decodes `message.body as? String`.
- Host command delegate contract: `HostBridgeCommandDelegate` (`CrosswakeDelegates.swift:33-40`), `registeredCommands` plus `handle(command:payload:correlationID:completion:)`. The completion result type is `BridgeChannel.CommandResult` with `.success(payload)` and `.deny(reason, message, hint)` (`BridgeChannel.swift:~420-432`).
- Pack provider: `PronunciationPackProvider.swift` (opaque installed artifact, no asset resolver, bundled source). `PackProviderFixtureTests.swift` and `PackStoreTests.swift` are the core analogs. `PronunciationPackProviderTests.swift` is the host-test analog.

**Precedent only (not substitutes):** `examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift` has `private var audioPlayer: AVAudioPlayer?` (`:407`, `:542`), `AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)` (`:466`, `:579`), and `AVAudioPlayer(contentsOf: assetURL(audio, under: root))` (`:468`) or `contentsOf: audioURL` (`:581`). D-07 requires binding the player to the verified bytes. Use `AVAudioPlayer(data:)` rather than a path re-open. `HostLearningBundleProvider.swift` is the asset verification precedent. Neither is the app under test.

## Shared Patterns

### Fail-closed, closed vocabulary with stable rule ids
**Source:** `physical_iphone_contract.ex:50-95`, `safe_observation.ex:99-123`.
**Apply to:** the twin receipt module, the verify_twin task, producer negative controls.
Use exact key sets, enum membership, bounded integers, structured `{:error, rule_id}` and a catch-all that degrades to "blocked" rather than crashing or passing.

### Strict Mix task shell
**Source:** `crosswake.proof_lane.verify_navigation_shell.ex:14-22,66-103`.
**Apply to:** `verify_twin`.
Strict `OptionParser`, a stable `Mix.raise` id, a private run-root check, contained-file checks and post-run invalidation of observations and nonce.

### Test shape for Mix tasks
**Source:** `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs`.
`async: false`, `Mix.Task.reenable`, a private temp root with `on_exit` cleanup.

### Pure policy and generation assertions
**Source:** `validator_test.exs:430-476` and `ios_host_config_test.exs:84-117`. Use these for the stop-gate and for anti-overclaim checks that need no runtime.

### Strong delegate retention
**Source:** `CrosswakeShellApp.swift:157-173`. Core holds `weak var hostBridgeCommandDelegate` (`CrosswakeShellConfig.swift:11`). The host must own the strong reference.

## No Analog Found

| File / concern | Role | Data flow | Reason |
|---|---|---|---|
| Bounded, handle-tracked subprocess runner with a process-group kill and reap (D-16) | utility | batch | Existing proof tasks use unbounded `System.cmd`. The planner must design it from the Elixir `Port` and `System.cmd` docs with explicit timeouts. |
| Invocation-owned loopback fault boundary for WebKit and native requests (D-08) | utility | streaming | No existing proxy or fault-injection precedent was found. The Phoenix e2e `lib/crosswake_example/e2e/` directory exists and should be read by the planner (not read here) before concluding none exists. |
| Host-local `message.webView` / `WKFrameInfo` identity wrapper (D-07) | provider | event-driven | `BridgeChannel` does not inspect `message.webView` or `frameInfo`. There is no existing analog. |
| Free-form entry control in the visible island and a positive saved-answers recovery destination (D-10/D-11) | component | CRUD | Backend accepts the field, and the UI and recovery destination are absent (`offline_controller.ex:33-35`). |
| Twin-only independent identity joins (installed executable, served JS bytes, backend build) (D-19) | utility | transform | No analog. The nearest is the digest-bound `NavigationShellAdvisory.subject_digests` pattern (called at `verify_navigation_shell.ex:~36`). Read `lib/crosswake/proof_lane/navigation_shell_advisory.ex` before reusing the idea. |

## Paths in CONTEXT that do not exist or need confirmation in the candidate

- `examples/phoenix_host/lib/crosswake_example/router.ex` exists (requalified during planning); the earlier absent note is superseded.
- `host.study.audio.play` has no occurrences anywhere (expected, since it is only proposed).
- `Crosswake.Policy.Validator` is at `lib/crosswake/policy/validator.ex` (confirmed). No `test/crosswake/policy/validator_test.exs` exists, and the relevant test lives at `test/crosswake/manifest/validator_test.exs`.
- `lib/crosswake/proof_lane/physical_iphone_contract.ex` and `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` exist as stated.
- Not read (listed by name only): `lib/crosswake/offline/status.ex`, `lib/crosswake/proof_lane/navigation_shell_advisory.ex`, the contents of `examples/phoenix_host/lib/crosswake_example/e2e/`, `offline_html/index.html.heex` and `offline_study.js` bodies, `HostLearningBundleProvider.swift` bodies, and `PronunciationPackProvider.swift` bodies. The planner must read them before writing task actions.

## Metadata

**Analog search scope:** `lib/crosswake/{policy,shell,proof_lane,offline,manifest}`, `lib/mix/tasks`, `packages/crosswake-shell-core-ios`, `examples/ios_shell_host`, `examples/phoenix_host/{lib,config,priv/static,e2e,native}`, `test/{crosswake,mix}`.
**Pattern extraction date:** 2026-10-13
**Read-only:** nothing was run (no build, tests or generators), and no candidate or recovery source file was modified.
