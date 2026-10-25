# Phase 181: Core Host-Command Seam - Research

**Researched:** 2026-10-14
**Domain:** Elixir route-policy/manifest/activation generation + Swift bounded iOS shell (host-command declaration, per-route authority, offline-island admission, versioned wire contract)
**Confidence:** HIGH on source facts (all read this session at candidate HEAD `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`); MEDIUM on the three design resolutions in "Decisions the planner must surface" (they interpret pinned tests against locked decisions)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions


### Method

- **D-01:** The user selected all four areas and asked for a full fan-out: five parallel research lenses (declaration, per-route authority, island admission, versioning/requirements, host-author DX across the `prompts/` corpus), an adversarial pass, and one coherent set of recommendations to follow automatically. Recommendations below are the post-adversarial synthesis. Where a researcher's proposal conflicted with candidate source or another lens, the source-verified resolution is recorded (see `<specifics>`). No unanswered user preference is silently defaulted.

### How routes declare host commands (G1)

- **D-02:** The host declares its host-command set **once**, with versions, on the router: `use Crosswake.Router, host_commands: [{"host.study.audio.play", "1.0.0"}]` (tuple list, no atom creation; a compile-time list from a shared module, e.g. `MyApp.HostCommands.all()`, is accepted for multi-router hosts). `use Crosswake.Router` currently ignores its options, so this is additive. Routes reference commands **by name only** in their existing `crosswake:` `capabilities:` list, e.g. `capabilities: ["host.study.audio.play"]`. This matches the Phase 180 gate test and handoff contract ("declares `host.study.audio.play` in its `crosswake:` capabilities list"). Routes never carry a version, so the version has exactly one source. — **Reversibility:** costly — router DSL option and manifest shape become host-facing API once released.
- **D-03:** The validator treats host commands as a **separate input**, not as members of `@known_capabilities`. The closed core capability set stays closed, and a broad `audio` stand-in is still rejected by the existing mechanism. Rules:
  - Command grammar is `^host\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`: at least three segments, at most four, no wildcards or globs.
  - Reserved prefixes (`host.crosswake.`, `host.bridge.`) are rejected.
  - Duplicate ids and versions that are not strict SemVer raise a `CompileError` at the `use` line.
  - A route's `host.*` capability must be in the router's declared set. Otherwise it is an explicit validation error, never ignored. A host with no `host_commands:` has an empty set, so existing routes are unaffected and any `host.*` reference is denied with the fix.
- **D-04:** `host.*` capabilities are allowed on runtimes that have a web bridge session: `:live_view` and `:offline_island`. Existing LiveView sessions already carry `host.*` commands (`HostBridgeCommandTests`), so restricting host commands to islands would break current behavior. A `host.*` capability on runtimes without a bridge session (`:native_screen`, `:adapter`, any other) is a compile-time validation error that names the runtime.
- **D-05:** Compile-time errors copy the in-repo precedent `Crosswake.Bridge.raise_undeclared_capability!/3`: a stable bracketed code, the route id, what is declared now, the router file and line, and a copy-paste fix line. Wording follows `brandbook/BRAND-SPEC.md`: calm, specific, actionable. Codes are `[crosswake.route.unknown_host_command]`, with a did-you-mean using `String.jaro_distance` over the declared ids and the declared list, and `[crosswake.route.host_command_runtime]`. Malformed declarations name the expected `host.<namespace>.<action>` shape.

### Per-route authority at runtime (G2, G3)

- **D-06:** The manifest route entry is the **single source of per-route authority**:
  - Each route entry gains an additive `host_commands` object (`{"host.study.audio.play": "1.0.0"}`, keys sorted, deterministic, version from D-02). Non-declaring routes emit `{}`.
  - The existing `capabilities: [String]` field keeps its current shape. Changing it to objects would make older shells fail to decode the whole manifest.
  - `Builder.capability_registry/1` also gets a `host_command`-family `Types.Capability` entry (owner host) for each referenced command. Declared-but-unreferenced commands are not emitted.
- **D-07:** `IOSHostGeneration.render/2` projects the **entry route's own** `host_commands` into the activation request's `capabilities` map. It uses the same function that builds the manifest entry, not config and not a hard-coded route. Fixture parity is a test assertion: entry activation capabilities equal the manifest's entry-route `host_commands`. It is not a second authority. A non-declaring entry route yields `{}`. This satisfies the Phase 180 G2 gate shape for the probe route.
- **D-08:** The native shell computes each route's session capabilities at resolve time with one pure function. For `host.*`, a session capability is granted exactly when all three hold:
  - the route's manifest `host_commands` declares it;
  - the host's `HostBridgeCommandDelegate.registeredCommands` contains it;
  - its declared version is SemVer-compatible with what this shell supports.

  Existing non-host families keep their current per-delegate filters. `makeNavigationCoordinator` stops copying `baseline.capabilities` into every route. Navigation, incoming URLs, deep links and back navigation all re-resolve through the same function, and no route's session inherits another route's commands. The baseline activation contributes runtime facts only (origin, versions, installed packs, entry route). The bridge check in `BridgeChannel.evaluateHostCommand` stays as it is: prefix, capability equal to command, registered delegate, and a version-compatible session entry. The public `HostBridgeCommandDelegate` protocol is unchanged (no source break for hosts).
- **D-09:** A command that is declared but not granted, because it is unregistered or its version is unsupported, is recorded with its reason when the session is built. The record carries only the route id, command name and reason; no payload, scope, account or device identifier. The shell then denies explicitly at dispatch. It is never removed silently. The current `try?` fallback to an empty manifest in navigation stays deny-all but must produce a diagnostic.
- **D-10:** The test matrix must show that projection is **driven by each route's own declaration and not hard-coded**. This closes the accepted 180 D-04/D-20 limitation:
  - Elixir property test over randomly generated route sets: each route's manifest `host_commands` equals its own declaration.
  - Two-declaring-route fixture with disjoint commands, each tested as the entry route (activation equals its own declaration), plus a non-declaring entry route.
  - Mutation check: hard-coding the probe route in the projection must turn tests red.
  - Swift table test over routes × registered set (including none) × version ok/unsupported.
  - Navigation matrix: A→B→A, a deep link to B, and back navigation. Each step's session equals a fresh resolve.
  - Cross-leak test: a command registered only for route A and invoked on route B is denied. A registered command that no route declares is never granted.

  The second declaring route lives in **test-only router fixtures**, not in the example router (no example breadth). The example router only adds the `offline-study` declaration and its `host_commands:` registry.

### Offline-island admission (G4)

- **D-11:** `LiveViewSession` gains `runtime: WebRuntime` (`.liveView` / `.offlineIsland`, default `.liveView`, so existing call sites are unchanged). `ShellPresentation` gains an explicit `.offlineIsland(LiveViewSession)` case. `resolve` replaces `guard route.runtime == "live_view"` with a closed, exact, case-sensitive allowlist switch over `"live_view"` and `"offline_island"`; `default` is denied. Hosts map `.offlineIsland` to the same container. The exhaustive-switch source break for host apps is intended: it makes ownership visible, and the example host, generated template and upgrade notes must handle it. No shell config switch is added for admission, because the route's own `runtime: :offline_island` is the explicit declaration and a second switch would duplicate it. — **Reversibility:** costly — public `ShellPresentation` case and session field become Swift API once released.
- **D-12:** Islands go through the same checks, in the same order, as LiveView routes:
  - native-runtime compatibility;
  - route active;
  - existing external-entry denial (islands are internal-only, matching the validator);
  - pack blocking (a missing pack returns `.requiredPack`, never `.offlineIsland`);
  - origin allowlist;
  - per-route host commands from D-08.

  No new island-only restrictions are invented in this phase. The container already uses the persistent default `WKWebsiteDataStore` and app-bound navigation, and it has no LiveView-socket coupling, so no WebKit work is needed.
- **D-13:** The shell explicitly does **not** promise:
  - offline cold start (the shell does not cache or serve island HTML or JavaScript);
  - outbox durability, replay or auth (the island and backend own these);
  - service workers (host app-bound-domain configuration);
  - data-store survival under storage pressure;
  - generic sync, background sync or native storage.

  Guides must say this plainly. Phase 180's T05 relaunch evidence is its own observation, not a shell guarantee.
- **D-14:** Runtimes that are not admitted stay denied with `compatibility_mismatch`. The message stays "This runtime is not available in the bounded shell." The hint becomes accurate: "The bounded shell opens live_view and offline_island routes only. Use a declared native capture route or update the shell." The old hint, which pointed at native capture for every runtime, misleads for unknown runtimes. The native-capture path and its denials are unchanged.

### Versioning, old/new combinations and requirements (SC5)

- **D-15:** The wire change is additive. `manifest_schema_version` goes from 1.1.0 to 1.2.0. The bridge protocol stays at 1.1.0, because the envelope and reply shape do not change. The Swift decoder keeps lenient unknown-key decoding and reads `host_commands` with `decodeIfPresent`, defaulting to empty, which means no host commands and not "allow every registered command". A present-but-malformed `host_commands` (wrong type or a bad command name) makes manifest loading throw. That surfaces as the existing explicit "Shell boot blocked" denial; the shell never drops the field and continues. — **Reversibility:** one-way once published — schema 1.2.0 becomes a released wire contract; no release is in this phase.
- **D-16:** **Version gate correction (adversarial finding).** Today's native-runtime check (`ActivationCoordinator.swift:359`, `BridgeChannel.swift:183`) compares two generated data files: manifest compatibility against activation. It never compares against the compiled shell binary, so a data-only "floor" cannot stop an older shell. The phase therefore:
  - (a) adds a compiled-in shell constant for the host-command seam version;
  - (b) has the new shell compare declared host commands against that constant, not only against data;
  - (c) adds a fail-closed **generation-time** gate. When any route declares host commands, generation refuses to project them unless it can establish that the host's resolved `crosswake-shell-core-ios` is at or above the seam version (for example from the host project's package resolution, or a path dependency in the reference host). If the version cannot be determined, generation blocks with a concrete fix rather than guessing.
  - (d) records an accepted residual. An older Swift package already built into an app, fed by newer fixtures generated outside that gate, would still reuse the entry baseline on navigation. That is documented in the upgrade notes ("upgrade core and shell together") and checked by doctor where it can be determined.
- **D-17:** Every old/new combination keeps working or fails explicitly:

  | Combination | Outcome |
  |---|---|
  | Hosts with no declaring routes | Output is unchanged apart from the schema string. Old shells keep working. |
  | New shell with an old manifest or activation | Host commands are empty, so any `host.*` request is denied (`undeclared_capability`). |
  | New shell, declared command, no registered delegate | Denied at dispatch with the route and command named. |
  | Old shell with a new manifest | The schema field is ignored. The old shell never reads `host_commands`, so it grants nothing it did not already grant. The entry-activation residual is covered by D-16. |

  The adversarial tests are listed in D-10 and D-12, plus: `host_commands: null` or `[]` grants nothing; a malformed field blocks boot; a downgraded shell never silently grants.
- **D-18:** **No new wire reason codes.** The existing reason vocabulary (`undeclared_capability`, `unavailable_capability`, `compatibility_mismatch`, `origin_denied`, …) is a pinned contract, mirrored in the frozen Android vectors. Only messages and hints get more specific, and they must name the route id and command, for example "Route offline-study did not declare host command host.study.audio.play." with the hint "Add it to this route's crosswake: capabilities and to host_commands on use Crosswake.Router, then regenerate." This replaces the generic "outside the host-declared contract" text where the cause is known.
- **D-19:** Android stays frozen and byte-identical. The literal `{"manifest_schema_version", "1.1.0"}` and `native_runtime_version` values in `lib/mix/tasks/crosswake.contract.gen.ex` stay, so the Android vectors and assets do not change. Run `contract_drift_test.exs`. If it couples the vector literal to the constant, adjust the test, not the vectors. A check asserts that the Android vector and asset bytes are unchanged.
- **D-20:** Update the support and guide truth together, with no release or publication:
  - CHANGELOG Unreleased: additive, iOS-only, Android unchanged.
  - Compatibility, support-matrix, bridge, native-shell upgrade and architecture guides.
  - `docs/_contract_snippet.md` and the support-matrix renderer and its test.
  - The Elixir tests that pin 1.1.0.
  - The example iOS fixtures.

  Guides say "first adopter", never a real name.
- **D-21:** Add the requirements **SEAM-01 to SEAM-06** to the workstream `REQUIREMENTS.md`, mapped to Phase 181 and the six success criteria. Done during this discussion (see the traceability table). On completion, the TWIN rows' blocked text becomes "unblocked by SEAM-01..06; awaiting 180-01 gate rerun".

### Diagnostics and DX

- **D-22:** The minimal host-author path has three touch points:
  1. the router (`host_commands:` registry plus the route's `capabilities:` reference);
  2. the Swift delegate (`registeredCommands` plus `handle`);
  3. the existing generation command.

  Authors never edit manifest or activation fixtures, and they never need to understand the intersection rule. Every denial names the route and command and gives one fix.
- **D-23:** Diagnostics reuse existing surfaces; there is no new dashboard or taxonomy:
  - **Doctor** reports two things: a stale generated manifest versus the router's per-route host commands, and the D-16 shell-package version gate where it can be determined.
  - **Inspect** prints the route → runtime → host commands allowed. It only extends an existing per-route capability view where one exists (planner verifies).
  - **Shell-side record:** the session-build record from D-09.

  All of these carry only route ids, command names and reasons (ADR sensitive-data rules). A static Swift scan of `registeredCommands` and a generated Swift constants file are deferred; see Deferred Ideas.

### Execution boundary and handoff

- **D-24:** Implement in a **new** candidate, `/private/tmp/crosswake-phase181-impl`, derived from the Phase 179/180 base, HEAD `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, tree `0514b6244ec814c1d0701d580b04651f70f57019`. `/private/tmp/crosswake-phase180-impl` stays untouched as gate evidence, including its three untracked gate test files pinned by SHA-256 in `180-GATE.json`, which this phase must not edit. Commits happen only in the 181 candidate. The recovery checkout gets no Git mutation or product-source edit. Planning files are written here as untracked plain files.
- **D-25:** On completion, write `phases/180-bounded-digital-twin-demonstration/180-SEAM-HANDOFF.json` with:
  - schema `crosswake.phase180.seam_handoff/1`;
  - `decision_candidate_head` and `base_head` both `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`;
  - `source_repo` set to the 181 candidate path;
  - `repaired_head` and `repaired_tree`;
  - `authorized_paths`, the exact changed product, test and guide paths;
  - `probe_route_id` `offline-study`, which declares `host.study.audio.play`.

  Then rename `180-01-SUMMARY.md` and `180-02-SUMMARY.md` to `*-SUMMARY.baseline.md`. Before writing the handoff, run the Phase 180 gate tests read-only against the repaired head as a preflight. Copy the test files from the 180 candidate after checking their pinned SHA-256 values. Expect G1–G4 and G6 to no longer be confirmed. Report the actual outcome; the authoritative rerun is 180-01's own.
- **D-26:** Automate every assertion. There is no human-verify checkpoint, because everything here is checkable by ExUnit, XCTest and artifact inspection. Phase 181 adds no audio playback, media, free-form, recovery, twin runner or receipt; those remain Phase 180. Android, generic sync and storage, native breadth, new dependencies, release, merge and publication are all out of scope.

### Claude's Discretion

These are left to the researcher and planner: exact function and module names, the Swift `WebRuntime` naming polish, where the compiled seam-version constant lives, how the generator resolves the shell package version in the reference host, did-you-mean thresholds, diagnostic record format, test file layout and plan split. None of these may weaken a decision above.

### Deferred Ideas (OUT OF SCOPE)


- A generated Swift constants file or enum for host commands, and a static scan of Swift `registeredCommands` for doctor. Both add new generated surface; reconsider if command-name drift is observed.
- Island-specific restrictions beyond the LiveView checks, such as denying transfers on islands. Revisit only with evidence.
- Offline cold start for islands (a service worker or a host-supplied cache), outbox durability guarantees and data-store survival. These belong to Phase 180 evidence or later work.
- Android host-command support, which is frozen.
- All Phase 180 demonstration work (T01–T10).
- Release, publication, merge and PR delivery.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEAM-01 | Router-level versioned `host_commands` registry; routes reference by name; undeclared/misspelled/malformed/reserved/wrong-runtime fail with actionable error | Validator seam (`validate/2`, `validate_capabilities/2`), router macro seam (import-vs-use finding F2), `Policy.Error` shape, G1 pinned-test conflict (F1) |
| SEAM-02 | Manifest carries each route's own `host_commands`; entry activation carries only the entry route's declaration; never probe-keyed | `Builder.route_entries/3`, `Types.RouteEntry`/`to_map`, `IOSHostGeneration.render/2`, generation tests, mutation check |
| SEAM-03 | Native session grants only declared ∧ registered ∧ version-compatible commands; re-resolved on navigation/deep link; denial names route and command | `ActivationCoordinator.resolve`, `makeNavigationCoordinator`, `loadAndFilterRequest`, `BridgeChannel.evaluateHostCommand`; G3 pinned-test conflict (F1) |
| SEAM-04 | Bounded shell admits `offline_island` as explicit `.offlineIsland` presentation; others denied with accurate hint | `ShellPresentation`, `LiveViewSession`, resolve guard at `ActivationCoordinator.swift:445`, example host switch |
| SEAM-05 | Additive wire change (manifest 1.2.0, bridge 1.1.0, Android byte-identical); old/new matrix; compiled constant + generation gate; guides/support truth together | `Types.manifest_schema_version`, contract.gen literals, pinned tests list, gen-shell package requirement, F3/F4/F9/F11 |
| SEAM-06 | `180-SEAM-HANDOFF.json` + `*-SUMMARY.baseline.md` renames | 180-01 `authorized_seam_rerun` steps R1-R6, pinned test SHA-256 values |
</phase_requirements>

## Summary

The seam crosses five layers that already exist and are individually small: route policy (`Crosswake.Policy.Validator`, called only from `Crosswake.Policy.Compiler`), manifest build (`Crosswake.Manifest.Builder`/`Types`), activation generation (`Crosswake.Shell.IOSHostGeneration.render/2`), the Swift activation resolver (`ActivationCoordinator.resolve`) and the bridge (`BridgeChannel.evaluateHostCommand`, which needs no change in authority logic). Every layer was read at the candidate. Baselines run green at the candidate: 211 root tests across policy/router/manifest/shell/contract/compatibility, 39 Swift package tests, 7 example-host gate tests, and an example-host `xcodebuild build` (all run in a scratch clone, not in the 180 candidate).

Reading the three pinned Phase 180 gate test files against the locked decisions surfaced two real conflicts that will keep the Phase 180 rerun from ever reaching `existing_path_supported` if the decisions are implemented literally (F1 below), plus several repo facts the CONTEXT did not know: the example router and the installer use `import Crosswake.Router`, not `use` (so D-02's `use ... host_commands:` option is unreachable for them); the committed iOS/Android manifest fixtures are stale and byte-identical (regenerating would produce a large unrelated diff and change Android bytes); and several guards pin source line numbers, source digests and the closed denial vocabulary. None changes the architecture; all change the plan.

**Primary recommendation:** Build bottom-up in four plans (policy+router registry → manifest+activation generation → Swift resolver+admission+tests → handoff/guides/Android-freeze proof), run the D-25 gate preflight right after the Elixir and Swift core changes (not last), and put the two F1 resolutions in front of the user as explicit confirmations before execution.

## Decisions the planner must surface (do not silently default)

### F1. Two pinned gate tests contradict literal D-03 / D-08 / D-17 (needs confirmation)

The three Phase 180 test files are byte-pinned by SHA-256 in `180-GATE.json` and must not be edited. I copied them into a scratch clone and confirmed the SHA-256 values match (`01df8264...`, `f7b96890...`, `a3bcef6e...`) and that all pass at baseline. `existing_path_supported` requires every gating fact G1-G4 to be refuted by an executed gate test (the gate test must FAIL its asserting body) **and** every control to pass **and** all four invariants held [CITED: 180-01-PLAN.md D-26 text, lines 28-29].

**G1 (policy).** The pinned gate calls `Crosswake.Policy.Validator.validate/2` (arity 2, no registry input) with route `capabilities: ["host.study.audio.play"]` on `runtime: :offline_island` and asserts exactly one error, `key == :capabilities`, message containing the command [VERIFIED: test/crosswake/proof/phase180_twin_feasibility_test.exs, G1 gate]. Under D-03 literally (empty registry ⇒ any `host.*` denied with an error whose message names the command) this test still passes, so G1 stays `confirmed` forever and the verdict stays `stop_missing_seam`.

- **Recommended resolution R1:** `Validator.validate/3` takes `opts[:host_commands]`. When the option is **absent** (the arity-2 call) the validator checks only grammar, reserved prefixes and runtime for `host.*` capabilities (accepts a well-formed one on `:live_view`/`:offline_island`). `Crosswake.Policy.Compiler.compile/2` is the **only production caller** [VERIFIED: grep `Validator.validate` in lib: `lib/crosswake/policy/compiler.ex:45` only] and **always** supplies the registry (empty list when the router declares none), so membership is enforced fail-closed in every real path. State this in the Validator doc and add a test that `Compiler.compile` on a router with no registry denies a `host.*` reference. This keeps D-03's behavior for every real host.
- If the user rejects R1, G1 cannot be refuted by the pinned test and the rerun will report `stop_missing_seam`; say so rather than hiding it.

**G3 (native session).** The pinned Swift control `test_G3_control_exported_request_carrying_command_reaches_delegate` builds a manifest route with **no host-command declaration** (`ShellManifest.Route(id:path:runtime:entry:capabilities: [] ...)`), feeds an activation request that carries `host.study.audio.play`, registers the delegate, calls `bootstrapIfNeeded()`, and requires `session.capabilities[command] == "1.0.0"` and delivery to the delegate [VERIFIED: Phase180TwinFeasibilityTests.swift, G3 control]. The gate test is the same setup and asserts the session **lacks** the command. Under D-08 literally (manifest `host_commands` is the sole authority; baseline "contributes runtime facts only") the control **fails** (so G3 becomes `unavailable` and the verdict `blocked_gate_unavailable`) and the gate test keeps passing.

- **Recommended resolution R2 (legacy-manifest compatibility):** `ShellManifest.Route.hostCommands` is `[String:String]?`. `nil` means the manifest has no `host_commands` field for the route (a pre-1.2.0 manifest). For a `nil` route the resolver keeps today's behavior exactly: host entries already present in the entry activation's `capabilities`, filtered by the registered delegate (the existing `loadAndFilterRequest` rule) **for the activation's own route only**. For a non-`nil` route (present field, including `{}` and JSON `null`) the manifest is the **sole** authority per D-08 and baseline host entries are ignored. New generated manifests always emit the field, so generated hosts never use the legacy path. This never widens what a host gets today, satisfies SC5 ("existing hosts keep working"), and makes the pinned control green. It deviates from the D-17 row "new shell with old manifest or activation ⇒ denied" only for the case "old manifest AND an activation that explicitly carries the command"; the row stays true for "old manifest, activation without it".
- Record R2 in the plan as an explicit, user-visible deviation. If rejected, G3 cannot reach refuted.

**Consequence for ordering:** run the D-25 preflight (copy the three pinned test files into the 181 candidate, verify SHA-256, run, expect G1-G4 and G6 gate tests to FAIL and controls/invariants to pass, then delete the copies) immediately after the Elixir and Swift core plans, so a mismatch is found before docs, guides and handoff work.

### F2. The example router and the installer use `import Crosswake.Router`, not `use`

`use Crosswake.Router` is `defmacro __using__(_opts)` that ignores options [VERIFIED: lib/crosswake/router.ex:11]. But `CrosswakeExample.Router` is `use Phoenix.Router` plus a hand-written `import Phoenix.Router, except: [...]` and `import Crosswake.Router` between `# crosswake:install:start/end` markers [VERIFIED: examples/phoenix_host/lib/crosswake_example/router.ex:67-92], and the installer test asserts `router =~ "import Crosswake.Router, except: [get: 4, live: 4], warn: false"` [VERIFIED: test/mix/tasks/crosswake_install_test.exs:260]. `use Crosswake.Router` appears only in some tests, never in guides or lib.

**Recommendation:** implement the registry as a macro importable by both styles, `crosswake_host_commands [{"host.study.audio.play", "1.0.0"}]` (module-attribute backed, registers a `@before_compile` once, defines `__crosswake_host_commands__/0`), and make `use Crosswake.Router, host_commands: ...` call the same code path. The example router calls the macro form. Malformed declarations raise `CompileError` at the macro call line (D-03). `Policy.Compiler` reads `source.__crosswake_host_commands__()` when `function_exported?/3`, otherwise `opts[:host_commands]`, otherwise `[]` (Compiler also accepts a bare list of route maps in tests [VERIFIED: compiler.ex:22-23, 80-82]). This is an extension of D-02's mechanism, not of its meaning (one registry, versions only there, routes by name).

### F3. Committed manifest fixtures are stale and shared with Android

`examples/ios_shell_host/Fixtures/crosswake_manifest.json` and `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` are byte-identical [VERIFIED: `cmp` identical] and both are written by `examples/phoenix_host/gen_manifest.exs` [VERIFIED: file read, writes both paths]. Freshly compiling `CrosswakeExample.Router` today differs from the committed fixture in `generated_at` (fixture 2026-06-02), `navigation_topology`, the `learnloop_daily_pack` pack, the `bridge-proof` route and more [VERIFIED: diff in scratch clone]. So regenerating would (a) create a large unrelated diff and (b) change Android bytes, violating D-19. `contract_drift_test.exs` only checks the bridge version at `compatibility.bridge_protocol_version` for both manifests [VERIFIED: contract_drift_test.exs:19-23, 66-90].

**Recommendation:** do not regenerate either committed manifest wholesale and do not run `gen_manifest.exs` as is. Prove the new wire shape with a dedicated, generated-and-drift-tested seam fixture pair (e.g. `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json`, produced by an Elixir test or small mix helper from a test-only two-declaring-route router, compared byte-for-byte by an ExUnit test) that the Swift tests decode. Leave `examples/ios_shell_host/Fixtures/*` alone unless the plan chooses a minimal hand edit; if `gen_manifest.exs` is touched, make it iOS-only. D-20's "example iOS fixtures" is satisfied by the new fixture plus the example router's `offline-study` declaration. Planner confirms.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Declare host commands + versions (registry) | Phoenix router macro (host, compile time) | — | Single version source; host owns names |
| Reference a command from a route | Route `crosswake:` capabilities (host, compile time) | Policy validator | Existing declaration surface; gate contract |
| Reject undeclared/unknown/reserved/wrong-runtime | Policy validator/compiler (Elixir) | Router macro (registry-shape errors) | Fail closed before any manifest exists |
| Per-route authority on the wire | Generated manifest route entry `host_commands` | Capability registry entry (owner host) | Single source; additive field |
| Entry activation capabilities | `IOSHostGeneration.render/2` using the same function as the manifest entry | — | Not a second authority; parity test |
| Session grant (declared ∧ registered ∧ compatible) | Swift `ActivationCoordinator` (pure resolver) | `HostBridgeCommandDelegate.registeredCommands` | Authority from manifest, registration from host |
| Command dispatch to host | Swift `BridgeChannel.evaluateHostCommand` (unchanged logic) | `HostBridgeCommandDelegate.handle` | Already enforces prefix, capability, registration, version |
| Offline-island admission | Swift resolver + host presentation switch | Example host view | Shell admits; host maps to shared container |
| Wire/version gate | Compiled shell constant + generation gate | Doctor | Data-only floors cannot stop an older binary (D-16) |
| Handoff + baselines | Planning files in recovery root | 181 candidate git | Product work only in candidate |

## Standard Stack

No new libraries, packages or dependencies (D-26). Everything below already exists at the candidate.

### Core
| Component | Version | Purpose | Why standard here |
|-----------|---------|---------|-------------------|
| Elixir / OTP | 1.19.5 / 27.3 | Core, validator, manifest, generation | `.tool-versions`; `elixir --version` ran this session [VERIFIED: tool run] |
| ExUnit | bundled | All Elixir assertions | Existing suites |
| Swift / XCTest (SwiftPM) | Swift 6.3.3, tools 5.9, `.iOS(.v15)`, `.macOS(.v12)` | Shell core package + unit tests | `swift test` ran 39 tests green [VERIFIED: tool run] |
| Xcode / xcodebuild | 26.6; iOS Simulator 26.5 devices present | Example-host compile check for the new enum case | `xcodebuild build` of `examples/ios_shell_host` succeeded in 29 s [VERIFIED: tool run] |
| jq, git, node 22.14 | system / `.tool-versions` | Handoff checks | Used by 180-01 verify commands |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generative property test via StreamData | Seeded deterministic generator in plain ExUnit (`:rand.seed(:exsss, {1,2,3})`) | StreamData is not in `mix.lock` (0 matches in root and example host); adding it violates "no new dependencies". D-10's "property test" is met by a fixed-seed generated route-set loop. |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed or added by this phase. Disposition: not applicable. Packages removed (SLOP): none. Packages flagged (SUS): none.

## Architecture Patterns

### System Architecture Diagram

```
router file                                             host Swift
  crosswake_host_commands [{"host.x.y.z","1.0.0"}]        HostBridgeCommandDelegate.registeredCommands
  route capabilities: ["host.x.y.z"]                               |
        |                                                          |
        v                                                          v
Policy.Compiler.compile(router) --reads registry--> Validator.validate/3
   (grammar, reserved, dup, semver, unknown+did-you-mean, runtime in [:live_view,:offline_island])
        | errors -> Policy.Diagnostic (fail closed, [crosswake.route.*] codes)
        v ok
Manifest.Builder.build
   route entry: capabilities [names] + host_commands %{name=>version} (sorted; {} if none)
   capability_registry: + Capability{id: name, family: "host_command", owner: :host, version}
   manifest_schema_version "1.2.0"
        |
        +--> IOSHostGeneration.render/2: entry route's host_commands -> activation.capabilities (same fn)
        |        + generation gate (D-16c): shell version/seam can be established, else block with fix
        v
bundled Fixtures: crosswake_manifest.json, route_activation.json
        |
        v  (device)
ShellManifest.Route.hostCommands (decodeIfPresent semantics: absent=nil, null/{}=empty, malformed=throw -> "Shell boot blocked")
        |
resolve(request, manifest) -- one pure function used by activate, bootstrap, deep link, navigation resolver
   version guard -> route active -> external entry -> pack block -> runtime allowlist {live_view,offline_island}
   -> origin -> grantedHostCommands(route) = declared ∧ registered ∧ version-ok  (+ record denials: route, command, reason)
        |
        +--> .liveView(LiveViewSession) or .offlineIsland(LiveViewSession{runtime:.offlineIsland})
                  |
                  v  host maps both to the shared WKWebView container
            BridgeChannel.evaluateHostCommand (unchanged authority) -> delegate.handle
```

### Recommended file touch map (candidate-relative; line numbers at `96e5a63`)

| Layer | Files | Change |
|-------|-------|--------|
| Router registry | `lib/crosswake/router.ex` (`__using__/1` line 11) | `crosswake_host_commands/1` macro, `use` option sugar, `@before_compile`, `__crosswake_host_commands__/0`, CompileError on malformed/dup/non-SemVer/reserved |
| Policy | `lib/crosswake/policy/validator.ex` (`validate/2` line ~24, `@known_capabilities` line 9, `validate_capabilities/2` line 120), `lib/crosswake/policy/compiler.ex` (line 45) | `validate/3`; host-command branch separate from `@known_capabilities`; new `Policy.Error`s; Compiler supplies registry |
| Manifest types | `lib/crosswake/manifest/types.ex` (`@manifest_schema_version "1.1.0"` line 769; `RouteEntry` struct 283-306; `new_route_entry` ~875; `to_map(%RouteEntry{})` ~1230; `Capability.owner` type 178) | `host_commands` field, serialization (always emit `{}`), schema `"1.2.0"`, owner `:host` |
| Manifest validation | `lib/crosswake/manifest/validator.ex` (owner vocabulary at ~603-610; `route_capability_declared?` ~680) | add `:host` to owner vocab; validate host_commands keys ⊆ route capabilities and match registry versions |
| Builder | `lib/crosswake/manifest/builder.ex` (`capability_registry/1` 156; `route_entries/3` ~194-207) | host-command registry entries (family `"host_command"`, not equal to id), per-route `host_commands` through one shared function |
| Generation | `lib/crosswake/shell/ios_host_generation.ex` (`render/2`, `Activation.new_request` at ~21-30 passes no capabilities) | pass `capabilities: entry.host_commands` (same function), generation gate |
| Swift | `Sources/CrosswakeShellCore/ActivationCoordinator.swift` (`ShellManifest.Route` 135; `LiveViewSession` 190; `ShellPresentation` 216; `resolve` 358; runtime guard 445; session build 478-491; `makeNavigationCoordinator` 496-505; `loadAndFilterRequest` 535) | per F1/R2; `WebRuntime`; `.offlineIsland`; per-route grant function; denial records; accurate hint |
| Swift bridge | `Sources/CrosswakeShellCore/BridgeChannel.swift` (`evaluateHostCommand` 410-440) | only message/hint specificity (D-18); edits must stay **after line 292** (see F4) |
| New Swift file | `Sources/CrosswakeShellCore/HostCommandSeam.swift` | compiled seam constant + grammar check (adding a file shifts no pinned line) |
| Example host | `examples/phoenix_host/lib/crosswake_example/router.ex` (route `offline-study` in `crosswake_defaults` block, ~line 246), `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` (`presentationView` switch at 399-446) | declaration; `.offlineIsland` case mapped to `LiveViewContainerView` |
| Template | `priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex` | prints `String(describing: coordinator.state)`, no exhaustive switch, so no break; README note only |

### Pattern: pure per-route grant function (Swift)

```swift
// Shape only; names are discretionary (CONTEXT). One function, used by every path.
struct HostCommandGrant { let granted: [String: String]; let denied: [(command: String, reason: String)] }
func grantHostCommands(route: ShellManifest.Route,
                       baseline: [String: String],        // entry activation capabilities
                       isEntryRoute: Bool,
                       registered: Set<String>) -> HostCommandGrant
// route.hostCommands == nil  -> legacy (R2): baseline host.* ∩ registered, entry route only
// route.hostCommands != nil  -> declared ∩ registered, version parseable/compatible; baseline ignored
```

`resolve` calls it; `makeNavigationCoordinator`'s closure stops copying `baseline.capabilities` into the request (`ActivationCoordinator.swift:500`) and instead passes only runtime facts, then `resolve` applies the function. `ActivationRequest.forIncomingURL` also copies `baseline.capabilities` (line 99) — harmless once `resolve` ignores request host entries for non-legacy routes, but keep the test that proves it.

### Anti-Patterns to Avoid
- **Keying projection to the probe route or to config:** the Phase 180 gate cannot detect it (accepted limitation); the 181 test matrix (D-10) is the only guard. Mutation check required.
- **Adding `host.*` ids to `@known_capabilities`:** keeps the core set closed (D-03).
- **Changing the existing `capabilities: [String]` field shape:** breaks older shells (decoding the whole manifest).
- **New wire reason codes:** the vocabulary is pinned and mirrored in Android vectors (D-18). Also `check_native_denial_reasons` scans native sources for out-of-vocabulary strings (F4).
- **Silent drop of a malformed `host_commands`:** must throw so boot is blocked.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version comparison (Swift) | new semver parser | `SemVer.compatible(provides:demands:)` | Fail-closed on unparseable [VERIFIED: SemVer.swift] |
| Strict SemVer check (Elixir) | regex-only | `Version.parse/1` plus rejecting normalized short forms | Elixir stdlib; the Compatibility module normalizes `1.0` to `1.0.0` but the registry must be strict (D-03) |
| Did-you-mean | custom distance | `String.jaro_distance/2` over declared ids (D-05) | Stdlib |
| Error shape | new exception type | `Crosswake.Policy.Error` + `Diagnostic`; `Crosswake.Bridge.raise_undeclared_capability!/3` as wording precedent | `lib/crosswake/bridge.ex:~599` |
| Wire fixture parity | hand-written JSON | Elixir-generated fixture + drift test, Swift decodes it | Same technique as `bridge_contract_vectors.json` (contract.gen) |
| Property testing | add StreamData | seeded generated loop | No new deps |

## Runtime State Inventory

Not a rename/refactor phase. Omitted.

## Common Pitfalls

### Pitfall 1: Pinned source-line and digest guards
**What goes wrong:** `lib/crosswake/bridge/catalog_guard.ex` pins `BridgeChannel.swift:128` (`case unavailable(reason:...)`), `:133` (`case deny(reason:...)`), `:286`, `:292` and asserts them in `test/crosswake/proof/phase154_catalog_guard_test.exs:524-525`; it also scans emitted denial reasons in `BridgeChannel.swift`, `CrosswakeShellApp.swift`, `LiveViewContainerViewController.swift` against the closed vocabulary [VERIFIED: catalog_guard.ex:40-60, 130-160, 225-260]. `NavigationShellAdvisory` records subject digests of `NavigationCoordinator.swift`, `capability_map.ex`, `support_matrix.ex` and others [VERIFIED: navigation_shell_advisory.ex:12-30].
**Avoid:** do not insert lines in `BridgeChannel.swift` above line 292; keep new denial strings to the existing reason vocabulary; do not edit `NavigationCoordinator.swift` (the resolver closure lives in `ActivationCoordinator.swift`). If the support-matrix renderer or `support_matrix.ex` text must change, run the navigation-shell advisory tests and expect digest churn to be advisory only; check before assuming.
**Warning signs:** `phase154_catalog_guard_test`, `navigation_shell_advisory_test` red.

### Pitfall 2: Doctor's manifest-contract check is byte-pinned
`script/assert_manifest_contract_unchanged.sh` compares `manifest_compile_check/1` and its single call line in `lib/crosswake/doctor/doctor.ex` byte-for-byte to a baseline pinned at commit `8bc77c35` [VERIFIED: script header]. Add the D-23 doctor checks as **new functions** (precedent: `phase_66_generator_drift_findings/3`, doctor.ex:163) and never edit those two regions. Run `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs`.

### Pitfall 3: Support-matrix pollution by the new registry entry
`capability_family_entries/1` emits a support-matrix row for every registry capability where `capability.id == capability.family` [VERIFIED: support_matrix.ex:1076-1080]. `Types.new_capability/1` defaults `family` to `id` [VERIFIED: types.ex:846]. A host-command entry must set `family: "host_command"` (≠ id) or every host command becomes a support-matrix family and the rendered guides/drift tests move. Also defaults are fail-closed `rebuild: :native_required`, which makes doctor's `capability_rebuild_findings` warn for every route that declares one (doctor.ex ~2060-2085); choose `rebuild:` deliberately (a host command does need a native delegate, so `:native_required` is honest, but state the warning in the guide) and add `:host` to the owner vocab in `Manifest.Validator` (list `[:bounded_bridge, :native_screen, :backend_seam, :activation, :defer]` at validator.ex ~603-610) and the `Capability.owner` typespec (types.ex:178). `OperatorInspection` prints route capabilities from the registry (owner, proof, rebuild), so D-23's inspect view extends for free once the registry entry exists; do not add inspection JSON fields (golden fixtures `test/fixtures/proof/phase52_operator_inspection.json`).

### Pitfall 4: Elixir-side compatibility requires the request to carry route-declared capabilities
`Compatibility.validate_capabilities/4` emits a `:capability_version` finding for every capability a route declares that the activation `capabilities` map does not carry at the registry version (`compatible_version?(nil, "1.0.0")` is `false`) [VERIFIED: compatibility.ex:435-470, 699-710]. Once `offline-study` declares the command, any Elixir test that runs `Activation.resolve` for `offline-study` with an activation lacking it will deny. D-07's projection handles the entry activation; the registry entry's version must equal the router-declared version. Grep and fix tests that resolve `offline-study` (candidates: `examples/phoenix_host/test/...local_first/*`, `learn_loop/dashboard_live_test.exs`, `physical_iphone_authority_fixture.ex`).

### Pitfall 5: Swift public/internal initializers used by pinned tests
`ShellManifest.Route` uses the implicit memberwise init and the pinned test calls `ShellManifest.Route(id:path:runtime:entry:capabilities:packs:transfers:allowlistedOrigins:)`. `LiveViewSession` is built memberwise in `HostBridgeCommandTests`, `NavigationCoordinatorTests`, `NavigationTransitionTests` and the gate tests. New fields must have defaults and must not remove the memberwise init: `var hostCommands: [String:String]? = nil` (declared last), `var runtime: WebRuntime = .liveView`, `var hostCommandDenials: [String:String] = [:]` (all last). Put the distinguishing `init(from:)` (absent vs null vs `{}` vs malformed) in an **extension** so the implicit memberwise init survives; verify with `swift build`.

### Pitfall 6: `RequiredPackPresentation.runtimeLabel` is hard-coded `"LiveView"` (line 400)
Islands blocked by a pack go through the same branch; label should reflect the runtime. Change it without altering `.requiredPack` semantics (D-12: a missing pack returns `.requiredPack`, never `.offlineIsland`).

### Pitfall 7: Android byte-change
`gen_manifest.exs` writes the Android manifest asset too (F3); `contract.gen.ex` writes Android vectors at line 193 `{"manifest_schema_version", "1.1.0"},` and the docs snippet at line ~494 with the same literal. Keep the vector literal (D-19) but make only `docs_snippet/1` read `Crosswake.Manifest.Types.manifest_schema_version()` (D-20). No Swift or Kotlin test reads the vector's `manifest_schema_version` [VERIFIED: grep in packages tests]. Baseline pins for the freeze proof: Android subtree objects `examples/android_shell_host` = `0857a4f0fbcd63567b20d3d48997d388be3702f8`, `packages/crosswake-shell-core-android` = `d425cff4fd4cf4ffbfefd04c849d2e555d4ff2c8` at `96e5a63`; `test/fixtures/bridge_contract_vectors.json` SHA-256 `3b64c8d8...0064c0`; Android manifest asset `ddefdb47...898e7`; activation asset `e69af23a...a66065`.

### Pitfall 8: Silent degrade at navigation
`makeNavigationCoordinator` falls back with `(try? loadManifest()) ?? ShellManifest(... "0.0.0", routes: [:])` (line 497) and `guard ... let baseline = try? self.requestLoader() else { return .denied }`. D-09 keeps deny-all but needs a diagnostic record (route-less reason). Also the navigation resolver uses the **unfiltered** baseline (`requestLoader()` not `loadAndFilterRequest`), so today navigation sessions already inherit unregistered caps; the new resolver must not.

### Pitfall 9: Handoff mechanics
180-01 R4 requires every path from `git diff --name-only 96e5a63 <repaired_head>` to start with an `authorized_paths` entry and none to be one of the three Phase 180 test paths [CITED: 180-01-PLAN.md line 74]. Copy the pinned test files into the 181 candidate only for the preflight, never `git add` them, and delete them before computing `repaired_head`. R1 also needs `git merge-base --is-ancestor 96e5a63 repaired_head` (commit on top of a clone of the 179 candidate), `repaired_tree` from `git rev-parse repaired_head^{tree}`, and `mix.lock` / `examples/phoenix_host/mix.lock` unchanged (R5). `authorized_paths` should list exact files (plus the new test files and guides), not broad prefixes like `lib/`.

## Code Examples

### Existing denial precedent to copy (wording/shape)
```elixir
# Source: lib/crosswake/bridge.ex:~599 raise_undeclared_capability!/3
message = """
[crosswake.bridge.undeclared_capability] route #{inspect(state.route_id)} never \
declared the #{inspect(capability_family)} capability family.
...
    #{fix_line}
"""
```
New route-policy errors are `Crosswake.Policy.Error` structs (`message`, `hint`, `key`, `file`, `line`) built by `build_error/3` from the managed route's `source` [VERIFIED: validator.ex:240-255, error.ex]; use `key: :capabilities` for unknown/runtime errors and put `[crosswake.route.unknown_host_command]` / `[crosswake.route.host_command_runtime]` at the start of `message`.

### Existing host-command bridge check (unchanged)
```swift
// Source: BridgeChannel.swift:410-425
guard request.command.hasPrefix("host."), request.capability == request.command,
      let delegate = config.hostBridgeCommandDelegate,
      delegate.registeredCommands.contains(request.command),
      capabilityAvailable(for: request) else { /* deny undeclared_capability */ }
```

### Pinned gate observables the repair must flip
```swift
// G4 gate: resolve() on an offline_island route must stop returning .denied (test then fails => refuted)
guard case let .denied(denial) = result else { XCTFail("Expected denied, got \(result)"); return }
XCTAssertTrue(denial.message.contains("bounded shell"))
```
The hint (not the message) changes (D-14); the message "This runtime is not available in the bounded shell." stays for non-admitted runtimes [VERIFIED: ActivationCoordinator.swift:445-455].

## Gate Contract Details (for SEAM-06 and 180-01)

- **Rerun reads** `180-SEAM-HANDOFF.json` with keys: `schema` = `"crosswake.phase180.seam_handoff/1"`; `decision_candidate_head` (must equal `180-DECISION.json.candidate_head` = `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, and that file's `decision` = `"allow"`); `base_head` (= same SHA); `source_repo` (absolute path; the 181 candidate); `repaired_head`; `repaired_tree`; `authorized_paths` (non-empty array of path prefixes); `probe_route_id` (`"offline-study"`, must declare `host.study.audio.play` in the **repaired** `CrosswakeExample.Router`, machine-checked by invariant `G2_probe_matches_declaration` with `PHASE180_BASE_KIND=authorized_seam_rerun`) [CITED: 180-01-PLAN.md lines 26, 72-74].
- **Mode selection** also requires that `180-01-SUMMARY.md` and `180-02-SUMMARY.md` were renamed to `*-SUMMARY.baseline.md` (names not ending in `-SUMMARY.md`) [CITED: 180-01-PLAN.md line 72].
- **Verdict logic** (G1-G4 gating, G6 non-gating): `existing_path_supported` only if all four gating facts are refuted by executed gate tests, all five controls passed, all four invariants held, no forced cause; a failed control forces that fact `unavailable` [CITED: 180-01-PLAN.md line 28, 156]. Pinned invariants that must keep holding: `G2_nondeclaring_clean`, `G2_probe_matches_declaration`, `G3_no_manufacture`, `G3_deny_absent`.
- **What the probe route must satisfy after repair:** `IOSHostGeneration.render(%IOSHostConfig{router: CrosswakeExample.Router, origin: "https://study.crosswake.test", entry_route_id: probe, app_bundle_id: "org.crosswake.twin", proof_app_bundle_id: "org.crosswake.twin.proof", device_signing: %{mode: :automatic, team_id: "ABCDE12345"}})` must return `{:ok, _}` with default config only, and its activation `capabilities` must equal `%{"host.study.audio.play" => "1.0.0"}` (gate G2 refuted) [VERIFIED: example gate test]. The compiled manifest `routes["offline-study"]["capabilities"]` must contain `host.study.audio.play` (G6 refuted), keep `runtime == "offline_island"`, and some other route must still have non-empty capabilities (G6 control).

## F8-F11 Further design resolutions (recommendations, discretionary unless noted)

### F8. Meaning of D-08 condition 3 and D-16(b)
The delegate protocol registers command **names only** (`registeredCommands: [String]`), and the command version is host-defined, so the shell cannot know a "supported" version per command. Recommended reading: condition 3 = the declared version is strict SemVer (else deny with reason "unsupported version") **and** the manifest's required seam level is satisfied by the compiled constant. For the constant to be compared against something, the manifest must carry a required seam level. Recommended additive field: `compatibility.host_command_seam_version` emitted only when any route declares host commands (old shells ignore unknown keys; new shell compares `SemVer.compatible(provides: HostCommandSeam.version, demands: that)` and denies/blocks with an update-the-shell message). This is an extra additive key beyond D-15's text; flag to the user. [ASSUMED]
### F9. Generation gate must pass in default `render/1`
The G2 gate calls `render/1` with only the six-field `IOSHostConfig` (struct has exactly `router, origin, entry_route_id, app_bundle_id, proof_app_bundle_id, device_signing` [VERIFIED: ios_host_config.ex:4-13]); the gate must therefore succeed without project context. Recommended: `render/2` accepts `opts[:shell_package]`; the mix task (which knows the managed root) resolves it from the host project (local `XCLocalSwiftPackageReference relativePath` → read the package's `HostCommandSeam.swift` constant; remote → `Package.resolved` version, else `minimumVersion` in `project.pbxproj`) and passes it; when no context is supplied, generation pins the shell it generates (the pbxproj template pins `minimumVersion = <core version>` [VERIFIED: project.pbxproj.eex:72-79]) so the gate passes by construction. If a context is supplied but cannot be resolved, block with a concrete fix (D-16c). Core and iOS shell versions are lock-stepped by release-please `linked-versions` (`hex`, `ios-core`, `android-core`) and `.release-please-manifest.json` shows all three at `0.2.11` [VERIFIED], so a minimum shell version equal to the first core release carrying the seam is the natural floor; that version is unknown until release-please cuts it (open question 3).
### F10. Seeded generative test, no dependency
See Standard Stack alternatives.
### F11. Docs literal split
Make `docs_snippet/1` in `crosswake.contract.gen.ex` print the canonical manifest schema (1.2.0) while the vectors literal stays 1.1.0, then regenerate only `docs/_contract_snippet.md` via the generator's idempotent write (it must not rewrite Android outputs: run it and assert `git diff --exit-code` on the Android paths).

## Tests That Pin the Old Values (will change or must be re-baselined)

Manifest schema `"1.1.0"` pins: `test/crosswake/manifest/manifest_test.exs:54,69,87`, `test/crosswake/manifest/builder_test.exs:284-285`, `test/crosswake/doctor/doctor_test.exs:140,294`, `test/mix/tasks/crosswake_doctor_test.exs:143`, `test/crosswake/proof/phase64_runtime_line_policy_test.exs:171` [VERIFIED: grep]. Rendered guides: `guides/compatibility.md`, `guides/support_matrix.md` (renderer text at `lib/crosswake/support_matrix/renderer.ex:267` says "moved 1.0.0 -> 1.1.0 (Phase 154...)"), `docs/_contract_snippet.md`, `guides/architecture.md:111` (shows `"1.0.0"`, already stale). Regenerate rendered guides with `mix crosswake.docs.sync` and run `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/guides/compatibility_test.exs`, `test/mix/tasks/crosswake.docs.sync_test.exs`, `test/crosswake/guides/native_shell_upgrade_test.exs`, `test/crosswake/guides/release_boundaries_test.exs`. CHANGELOG Unreleased gets additive iOS-only note (Android unchanged). Do not claim a release.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Activation carries every capability for every route (baseline copied on navigation) | Per-route grant from manifest declaration ∩ registration | This phase | Closes cross-route inheritance |
| Bounded shell denies every non-`live_view` runtime | Closed allowlist `{live_view, offline_island}` | This phase | Island routes mount in the shared container |
| `ShellPresentation` has 5 cases | adds `.offlineIsland(LiveViewSession)` | This phase | Exhaustive-switch source break for host apps is intended (D-11) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | R1 (validate/2 without registry checks grammar/runtime only; Compiler always supplies registry) is acceptable to the user | F1 | If rejected, G1 cannot be refuted; rerun verdict stays `stop_missing_seam` |
| A2 | R2 (legacy path for manifests with no `host_commands` field) is acceptable | F1 | If rejected, pinned G3 control fails; rerun verdict `blocked_gate_unavailable` |
| A3 | Extra additive `compatibility.host_command_seam_version` key is acceptable | F8 | Without it the compiled constant has nothing to compare against; D-16(b) is vacuous |
| A4 | Generation gate resolves package version from pbxproj/Package.resolved/local path as described | F9 | A different resolver is fine; the default-render-passes property is the hard requirement |
| A5 | `crosswake_host_commands/1` macro plus `use` option sugar is the right reading of D-02 for import-style routers | F2 | Alternative: module attribute only; same behavior |
| A6 | `rebuild: :native_required` for the host-command registry entry | Pitfall 3 | Doctor warning noise vs understated cost |
| A7 | First seam-carrying release version is decided at release time (not by this phase) | F9 | Floor constant needs a release-please-managed marker |

## Open Questions (RESOLVED)

1. **F1 R1/R2 confirmation** (see above). Recommendation: present both to the user as one pair of explicit confirmations before `$gsd-execute-phase 181`; plan proceeds with R1/R2 as the default because the user's guidance is "do it properly, not nerfed" and the phase must make the rerun reach `existing_path_supported`. RESOLVED: user confirmed R1 and R2 on 2026-10-14 (CONTEXT D-27, D-28).
2. **F8 manifest-level seam key.** Recommendation: adopt A3 or explicitly record that D-16(b) is satisfied only by the generation gate plus doctor. RESOLVED: user confirmed the additive key (CONTEXT D-29).
3. **Minimum shell floor value.** Recommendation: derive from the core version via a release-please extra-file marker, set at the release that publishes the seam; this phase publishes nothing, so the gate compares against the compiled constant for local-path hosts and records "cannot determine" (block with fix) for remote hosts until a release exists. RESOLVED: plan 181-03 Task 1 (remote shell packages blocked with a fix until a seam release exists; local path must carry the constant).
4. **Fixture policy (F3).** Recommendation: new generated seam fixture pair; leave committed manifests alone. RESOLVED: plan 181-02 Task 2 (new generated seam fixture; committed manifests untouched per D-19).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | all Elixir tests | yes | 1.19.5 / OTP 27 | none needed |
| Swift toolchain | SwiftPM tests | yes | 6.3.3 | none |
| Xcode + iOS Simulator | example-host compile check | yes | 26.6, iOS 26.5 sim devices | `-destination 'generic/platform=iOS Simulator'` build needs no booted device |
| jq, git, node (asdf 22.14) | handoff and verify commands | yes | system | none |
| Candidate source `/private/tmp/crosswake-phase179-impl` | derive 181 candidate | yes | HEAD `96e5a63e...`, tree `0514b624...`, clean tracked tree | none |
| `/private/tmp/crosswake-phase181-impl` | execution | not yet created | — | create per commands below |
| Hex deps for offline build | `mix deps.get` | present in 180 candidate (`deps/`, `examples/phoenix_host/deps`) | — | `mix deps.get` must leave lockfiles unchanged |

The recovery checkout does **not** contain commit `96e5a63` (`git cat-file -t 96e5a63e` fails there); all source reads must use the candidate clones, not `git -C <home>/projects/crosswake show`.

**Candidate creation (D-24):**
```bash
git clone --no-local /private/tmp/crosswake-phase179-impl /private/tmp/crosswake-phase181-impl
git -C /private/tmp/crosswake-phase181-impl checkout --detach 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
git -C /private/tmp/crosswake-phase181-impl remote set-url --push origin no-push-phase181
# assert HEAD^{tree} == 0514b6244ec814c1d0701d580b04651f70f57019; mix deps.get in root and examples/phoenix_host; git diff --exit-code -- mix.lock examples/phoenix_host/mix.lock
```
Committing on a detached HEAD is fine for the handoff (it only needs the commit object and ancestry), but a named local branch (e.g. `phase181-impl`) avoids losing commits to gc.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (root and `examples/phoenix_host`), XCTest via SwiftPM, xcodebuild compile check |
| Config file | `mix.exs`; `packages/crosswake-shell-core-ios/Package.swift` |
| Quick run command | `cd /private/tmp/crosswake-phase181-impl && MIX_ENV=test mix test test/crosswake/policy test/crosswake/router_test.exs test/crosswake/manifest test/crosswake/shell test/crosswake/contract test/crosswake/compatibility --seed 0` (211 tests / 17 s at baseline) |
| Swift quick | `cd packages/crosswake-shell-core-ios && swift test` (39 tests / ~60 s cold, 0.15 s test time) |
| Example host | `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/<file>.exs --seed 0` |
| Host compile | `xcodebuild build -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'generic/platform=iOS Simulator' -derivedDataPath <scratch> CODE_SIGNING_ALLOWED=NO` (29 s at baseline) |
| Full suite | `MIX_ENV=test mix test` in root and example host, `swift test`, plus the guard scripts below |

Never pipe a gate to `tail`/`grep` and read the pipeline's status as the result (project memory: piped checks mask exit codes). Capture to a file, test `$?`, then grep the file.

### Phase Requirements to Test Map

| Req | Behavior | Test Type | Automated Command (new files proposed; names discretionary) | Failing signal | File Exists? |
|-----|----------|-----------|-------------------|----------------|--------------|
| SEAM-01 | declared `host.*` accepted; undeclared, misspelled (did-you-mean), reserved `host.crosswake.`/`host.bridge.`, malformed grammar, duplicate id, non-SemVer version, wrong runtime (`:native_screen`, `:adapter`) rejected with codes | unit | `mix test test/crosswake/policy/host_commands_test.exs test/crosswake/router_host_commands_test.exs` | accept of any rejected case; message lacks route id/code/fix line | Wave 0 |
| SEAM-01 | `validate/2` default admits grammar-valid `host.*`, `Compiler.compile` with empty registry denies (R1) | unit | same file | `Compiler` accepts an undeclared command | Wave 0 |
| SEAM-01 | `crosswake_host_commands/1` works under `import Crosswake.Router` and `use ... host_commands:`; CompileError at macro line | unit | `router_host_commands_test.exs` | no CompileError for dup/malformed | Wave 0 |
| SEAM-02 | each route's manifest `host_commands` equals its own declaration for fixed-seed generated route sets | unit | `mix test test/crosswake/manifest/host_commands_test.exs` | any route's map differs | Wave 0 |
| SEAM-02 | two declaring routes with disjoint commands, each rendered as entry route: activation `capabilities` equals own declaration; non-declaring entry yields `{}`; parity with manifest entry | unit | `mix test test/crosswake/shell/ios_host_generation_host_commands_test.exs` (router fixtures in `test/support/`) | cross-leak or probe-keyed result | Wave 0 |
| SEAM-02 | mutation: hard-coding the probe route in the projection turns the matrix red | unit/script | a test that swaps in a mutated projection function via an injectable seam (or `script/` mutation runner) and asserts failure | mutation stays green | Wave 0 |
| SEAM-02 | registry entry has `family: "host_command"`, owner `:host`, absent from support-matrix families | unit | `mix test test/crosswake/support_matrix test/crosswake/manifest/validator_test.exs` | new support-matrix row appears | partly exists |
| SEAM-02 | example router: `offline-study` declares the command; nothing else does | example | `cd examples/phoenix_host && mix test test/crosswake_example/host_command_seam_test.exs` | G6/G2 invariants | Wave 0 |
| SEAM-03 | Swift table: routes x registered set (incl. none) x version ok/unsupported; legacy `nil` vs `{}` vs null vs malformed | XCTest | `swift test --filter HostCommandSeamTests` | granted without declaration; granted without registration | Wave 0 |
| SEAM-03 | navigation matrix A->B->A, deep link to B, back: each session equals a fresh resolve; cross-leak (registered only for A, invoked on B) denied; registered-but-undeclared never granted | XCTest | `swift test --filter HostCommandNavigationTests` | session differs from fresh resolve | Wave 0 |
| SEAM-03 | denial message names route and command; reasons only from existing vocabulary | XCTest + ExUnit | `swift test --filter HostCommandSeamTests` plus `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | out-of-vocabulary reason or pinned-line drift | exists (guard) |
| SEAM-04 | `offline_island` resolves to `.offlineIsland` (same checks/order as live_view); missing pack gives `.requiredPack`; external entry, bad origin denied; `native_screen` path unchanged; unknown runtime denied with new hint | XCTest | `swift test --filter OfflineIslandAdmissionTests` | island returns `.denied`/`.liveView` | Wave 0 |
| SEAM-04 | example host compiles with exhaustive switch handling `.offlineIsland` | compile | the `xcodebuild build` command above | build error "switch must be exhaustive" | exists (project) |
| SEAM-05 | manifest schema `"1.2.0"` emitted; bridge protocol still `"1.1.0"`; `host_commands` is `{}` for non-declaring; old pins updated | unit | `mix test test/crosswake/manifest test/crosswake/doctor test/crosswake/proof/phase64_runtime_line_policy_test.exs` | stale `"1.1.0"` assertions | exists, edit |
| SEAM-05 | Swift decodes 1.2.0 fixture; unknown keys tolerated; malformed `host_commands` blocks boot ("Shell boot blocked"); absent/null/[]/{} grant nothing new | XCTest | `swift test --filter HostCommandWireTests` | decode accepts malformed | Wave 0 |
| SEAM-05 | Android byte-freeze | script/test | `git diff --exit-code 96e5a63efab657f89f3ac84d5b1d84ff5da5d822 -- examples/android_shell_host packages/crosswake-shell-core-android test/fixtures/bridge_contract_vectors.json packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json` (run from candidate; must exit 0; no pipe) | any diff | Wave 0 |
| SEAM-05 | `mix test test/crosswake/contract/contract_drift_test.exs`; `mix crosswake.contract.gen` then `git diff --exit-code` on vector and Android paths | unit | as shown | drift | exists |
| SEAM-05 | generation gate: default `render/1` passes; context with undeterminable shell blocks with fix; local-path with seam constant passes | unit | `mix test test/crosswake/shell/ios_host_generation_host_commands_test.exs` | gate silent-allows on unknown | Wave 0 |
| SEAM-05 | guides/support truth consistent | unit | `mix crosswake.docs.sync --check` if available (verify flag) and `mix test test/crosswake/guides test/crosswake/support_matrix test/mix/tasks/crosswake.docs.sync_test.exs` | rendered drift | exists |
| SEAM-05 | doctor: stale manifest vs router host commands; `manifest_compile_check` bytes unchanged | unit/script | `bash script/assert_manifest_contract_unchanged.sh` and `mix test test/crosswake/proof/phase174_manifest_contract_immutability_test.exs test/crosswake/doctor` | script exit nonzero | exists |
| SEAM-06 | preflight: copy the three pinned test files, verify SHA-256, run them against repaired head: G1-G4, G6 gate tests fail (refuted), controls pass, invariants hold | script | `shasum -a 256` compare to `180-GATE.json.test_files_sha256`; root `--only phase180_gate`; example `--only phase180_gate --only phase180_invariant` with `PHASE180_BASE_KIND=authorized_seam_rerun PHASE180_PROBE_ROUTE=offline-study`; `PHASE180_EXPORT_DIR=<example>/_build/phase180/probe swift test --filter Phase180TwinFeasibilityTests` (export first with `--only phase180_export`) | gate test passing (still confirmed) or a control failing | Wave 0 |
| SEAM-06 | handoff JSON valid and bound | script | `jq -e` over schema, `decision_candidate_head==base_head==96e5a63e...`, `git cat-file -e`, `rev-parse repaired_head^{tree}==repaired_tree`, `merge-base --is-ancestor`, diff paths subset of `authorized_paths`, none are the three test paths; both SUMMARY files renamed `*.baseline.md` | any jq/git nonzero | Wave 0 |

### Sampling Rate
- **Per task commit:** the matching quick command above (root subset or `swift test --filter`), run in the 181 candidate.
- **Per wave merge:** root quick command + `swift test` + example-host test dir + `xcodebuild build`.
- **Phase gate:** full root and example-host `mix test`, `swift test`, `check_exunit_ownership.exs`, `script/assert_manifest_contract_unchanged.sh`, Android freeze diff, then the D-25 preflight.

### Wave 0 Gaps
- [ ] New ExUnit files listed above, with router fixtures under `test/support/` (compiled in test via `elixirc_paths: ["lib", "test/support"]` [VERIFIED: mix.exs:41]); mark example-host-dependent root tests `requires_example_host` per `script/check_exunit_ownership.exs` classification (read it before adding tests; new tests must be owned by a CI lane).
- [ ] New Swift test files and the generated seam fixture resource.
- [ ] 181 candidate creation + dependency fetch check.
- [ ] Update `script/collection_assertion_ledger.json`/remediation only if the collection-assertion inventory script reports new files (run `mix run script/inventory_collection_assertions.exs` equivalent per its header; verify before assuming).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | backend auth authority untouched |
| V3 Session Management | no | shell session is a presentation record, not an auth session |
| V4 Access Control | yes | declaration-driven least privilege: command granted only if route-declared and host-registered; deny by default; manifest authority; no cross-route inheritance |
| V5 Input Validation | yes | strict command grammar `^host\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`, 3-4 segments, no wildcards, reserved prefixes; strict SemVer; malformed manifest field throws |
| V6 Cryptography | no | none introduced (SHA-256 only for evidence comparison via `shasum`) |
| V7 Logging | yes | grant/deny records carry only route id, command name, reason; no payload, scope, account, device id (ADR sensitive-data rules) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Route B invokes a command only route A declared (privilege inheritance) | Elevation of privilege | per-route grant function; cross-leak and navigation matrix tests |
| Silent grant for a downgraded or older shell | Elevation/Spoofing | compiled seam constant, generation gate, additive manifest field ignored by old shells grants nothing new (F9/F8) |
| Malformed `host_commands` silently dropped | Tampering | decode throws; "Shell boot blocked" |
| Probe-keyed projection passes the gate | Spoofing | declaration-driven tests with two declaring routes plus mutation check |
| Diagnostics leaking payloads | Information disclosure | records limited to route id, command, reason; test asserts no other fields |
| Wildcard/glob commands | Elevation | grammar forbids; test |

## Sources

### Primary (HIGH confidence, read or run this session)
- Candidate source at `/private/tmp/crosswake-phase180-impl` (HEAD `96e5a63e...`): `lib/crosswake/router.ex`, `policy/{validator,compiler,route,schema,error,diagnostic}.ex`, `manifest/{builder,types,validator,manifest}.ex`, `shell/{ios_host_generation,ios_host_config,activation}.ex`, `compatibility/compatibility.ex`, `bridge/catalog_guard.ex`, `support_matrix/support_matrix.ex`, `operator_inspection.ex`, `doctor/doctor.ex`, `mix/tasks/crosswake.contract.gen.ex`, `crosswake.gen.shell.ex`; Swift `ActivationCoordinator.swift`, `BridgeChannel.swift`, `CrosswakeDelegates.swift`, `CrosswakeShellConfig.swift`, `NavigationCoordinator.swift`, `SemVer.swift`, `CrosswakeShell.swift`; example router, `CrosswakeShellApp.swift`, `gen_manifest.exs`; pinned Phase 180 tests; `.release-please-manifest.json`, `release-please-config.json`.
- Phase docs: `181-CONTEXT.md`, `180-GATE.json`, `180-DECISION.json`, `180-CANDIDATE.json`, `180-01-PLAN.md`, `REQUIREMENTS.md` (SEAM-01..06), `STATE.md`.
- Tool runs in a scratch clone (not the 180 candidate): `swift test` (39 pass), root subset (211 pass), example-host gate tests (7 pass), `xcodebuild build` (succeeded), manifest recompile diff.

### Secondary / Tertiary
- External primary sources listed in CONTEXT (Tauri, Chrome permissions, Hotwire Native, Swift Decodable, JWS crit, SemVer, Protobuf, WKWebsiteDataStore) were not fetched; no plan decision here relies on them. `[ASSUMED]` if cited in guides; verify before quoting.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new and every tool run.
- Architecture/file map: HIGH, read at the candidate.
- F1 conflict analysis: HIGH on the mechanics (read test bodies and verdict rules), MEDIUM on user acceptance of R1/R2.
- F8/F9 resolver details: MEDIUM, design recommendations.
- Pitfalls: HIGH (guards read directly).

**Research date:** 2026-10-14
**Valid until:** until the candidate base head changes (the base is pinned; re-check only if `96e5a63` changes)
