# Phase 181: Core Host-Command Seam - Context

**Gathered:** 2026-10-14
**Status:** Ready for planning
**Workstream:** quality-ratchet-release

<domain>
## Phase Boundary

Phase 181 makes one existing extension seam work end to end. A route lists a host-owned `host.*` command in its own `crosswake:` capabilities. That command is accepted by route policy, appears in the generated manifest and in the entry activation for that route alone, is granted to that route's native session only when the host registered it, and reaches the host's `HostBridgeCommandDelegate`. The bounded iOS shell also admits `offline_island` routes as an explicit, separately named presentation that shares the existing web container. Every other path stays an explicit, fail-closed denial.

The phase closes the confirmed Phase 180 gate facts G1–G4 (plus G6 for the example route) and writes the seam handoff that lets 180-01 rerun in `authorized_seam_rerun` mode. It does **not** build any Phase 180 demonstration piece: no audio playback delegate, media acquisition, free-form input, recovery action, twin runner or receipt. Authority: the user's "allow" in 180-02 (`180-DECISION.json`), plus the user's guidance to do the seam properly ("all this stuff is important if it's nerfed it's not useful"), with declaration-driven projection for every declaring route and a versioned wire contract that never breaks existing hosts silently.

</domain>

<decisions>
## Implementation Decisions

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
  - The example iOS fixtures. (Resolved in plan-phase 2026-10-14: D-19 governs. The committed `examples/ios_shell_host/Fixtures/*` manifests are byte-identical to the Android assets and stay unedited. This item is satisfied by a new generated seam fixture under the Swift package test resources.)

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

### Post-research resolutions (user-confirmed during plan-phase, 2026-10-14)

Research (`181-RESEARCH.md` F1, F8) found that a literal reading of D-03, D-08 and D-17 would leave the pinned Phase 180 gate unable to reach `existing_path_supported`. The user confirmed all three recommended resolutions:

- **D-27 (R1, refines D-03):** `Crosswake.Policy.Validator.validate/3` takes the host-command registry as an option. When it is called without one (the arity-2 call, which the pinned G1 test uses), it checks only grammar, reserved prefixes and runtime for `host.*` capabilities. `Crosswake.Policy.Compiler.compile/2` is the only production caller and always supplies the registry (an empty list when the router declares none), so membership stays fail-closed for every real host. A test must prove that `Compiler.compile` denies an undeclared `host.*` reference, and the Validator doc must state this contract.
- **D-28 (R2, explicit deviation from one D-17 row):** `ShellManifest.Route.hostCommands` is optional. An absent field (a pre-1.2.0 manifest) keeps today's behavior exactly: the host entries already in the entry activation's `capabilities`, filtered by the registered delegate, for the activation's own route only. A present field, including `{}` and JSON `null`, is the sole authority per D-08, and baseline host entries are then ignored. New generated manifests always emit the field. This never widens what a host gets today. The D-17 row "new shell with an old manifest or activation is denied" now holds only when the activation does not carry the command. Plans and the summary must record this deviation where users can see it.
- **D-29 (A3, extends D-15/D-16b):** add the additive manifest key `compatibility.host_command_seam_version`, emitted only when at least one route declares host commands. Old shells ignore it. New shells compare it with `SemVer.compatible(provides: <compiled seam constant>, demands: <key>)` and, when it is not satisfied, deny or block with an actionable "update the shell" message.
- **Ordering (from research):** run the D-25 gate preflight immediately after the Elixir and Swift core plans, before the docs, guide and handoff work, so a mismatch shows up early.

### Claude's Discretion

These are left to the researcher and planner: exact function and module names, the Swift `WebRuntime` naming polish, where the compiled seam-version constant lives, how the generator resolves the shell package version in the reference host, did-you-mean thresholds, diagnostic record format, test file layout and plan split. None of these may weaken a decision above.

</decisions>

<canonical_refs>
## Canonical References

Planning paths resolve in the recovery root `<home>/projects/crosswake`. Code paths resolve in the candidate (D-24).

### Governing scope and authority
- `AGENTS.md`: workstream rules, privacy, the preservation of the recovery checkout, and the Android freeze.
- `.planning/ADR-FIRST-B2C-ADOPTER.md`: thesis, stop list and sensitive-data rules.
- `.planning/PROJECT.md`: thesis and history.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: SEAM-01..06 (this phase) and TWIN-01..06 (Phase 180).
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md`: the Phase 181 goal and success criteria.
- `.planning/workstreams/quality-ratchet-release/STATE.md`: the seam handoff contract and the sole active handoff.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-DECISION.json`: the user's allow that authorizes this scope.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-GATE.json`: confirmed facts G1–G6, pinned gate test SHA-256 values, and the probe route.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-01-SUMMARY.md`: gate results.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-CONTEXT.md`: D-03, D-04 and D-20 (the stop and its accepted limitation) and the T01–T10 ownership that this phase must not build.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-01-PLAN.md`: how the `authorized_seam_rerun` mode consumes the handoff.
- `.planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-CONTEXT.md`: settled generation and managed-output decisions.

### Project research and voice
- `prompts/crosswake-elixir-oss-dna.md`: strict versioning of bridge and capability negotiation; doctor checks; explicit, versioned native seams.
- `prompts/crosswake-research-synthesis.md`: semantic, versioned, low-frequency bridge contracts.
- `prompts/crosswake-integrations-and-companions.md`: host, core and companion ownership.
- `brandbook/BRAND-SPEC.md`: error and microcopy voice (supersedes `prompts/crosswake-brand-book.md`).

### External primary sources (lessons only; none expands scope)
- Tauri v2 capabilities and permissions (https://v2.tauri.app/security/capabilities/): per-scope grants from static files; unknown identifiers rejected.
- Chrome extension permissions (https://developer.chrome.com/docs/extensions/develop/concepts/declare-permissions): declare-then-grant, with authority taken from the manifest and not the page.
- Hotwire Native path configuration and bridge components (https://native.hotwired.dev/): per-path rules resolved on each navigation. Its silent no-op on an unregistered name is the anti-pattern to avoid.
- Swift Decodable behavior with unknown keys (https://developer.apple.com/documentation/swift/decodable); JWS `crit` (https://www.rfc-editor.org/rfc/rfc7515#section-4.1.11): data that older code ignores cannot enforce a requirement on it.
- SemVer (https://semver.org/) and Protobuf field evolution (https://protobuf.dev/programming-guides/proto3/#updating): additive minor changes.
- WKWebsiteDataStore and app-bound domains (https://developer.apple.com/documentation/webkit/wkwebsitedatastore): what the shell does not promise (D-13).

The researchers cited these from their own knowledge and did not fetch them. The phase researcher should verify any that a plan relies on.

</canonical_refs>

<code_context>
## Existing Code Insights

All paths are in the candidate. Line numbers are from base `96e5a63`.

### Integration points
- `lib/crosswake/router.ex`: `__using__/1` ignores options (line 11). Route options flow through `__route_options__`. This is where the `host_commands:` registry is added.
- `lib/crosswake/policy/validator.ex`: `@known_capabilities` closed set (line 9) and `validate_capabilities/2` (line 120). The host-command set is added as a separate input here.
- `lib/crosswake/manifest/builder.ex`: `capability_registry/1` (line 156) and `route_entries/3`. `lib/crosswake/manifest/types.ex` covers `manifest_schema_version` (line 769), `Capability`, and RouteEntry serialization (around line 1244).
- `lib/crosswake/shell/ios_host_generation.ex`: `render/2` builds a single entry activation with empty capabilities.
- `lib/crosswake/shell/activation.ex`: `Request.capabilities` is a map from id to version.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`:
  - `ShellManifest.Route` (around line 135);
  - the version guard in `resolve` (line 359);
  - the runtime guard (around line 446);
  - `makeNavigationCoordinator`, which reuses the baseline (line 495–500);
  - `loadAndFilterRequest`, which filters by registered delegates (line 535–590).
- `BridgeChannel.swift`: `evaluate` version guard (line 183), `evaluateHostCommand` and `capabilityAvailable` (line 410–445).
- `CrosswakeDelegates.swift`: `HostBridgeCommandDelegate` (unchanged).
- `examples/phoenix_host/lib/crosswake_example/router.ex`: the `offline-study` route (around line 246), which gets `capabilities: ["host.study.audio.play"]` plus the router's `host_commands:`.
- `examples/ios_shell_host/CrosswakeShell/*`: the composition root and the container. These must handle `.offlineIsland`.
- `lib/mix/tasks/crosswake.contract.gen.ex`: hard-coded Android vector literals, which stay unchanged.

### Reusable patterns
- `Crosswake.Bridge.raise_undeclared_capability!/3` (`lib/crosswake/bridge.ex`, around line 599) shows the error shape to follow: code, route, what is declared, router location and fix line.
- `SemVer.compatible(provides:demands:)` handles version checks, and unparseable input fails closed.
- Existing tests to extend: `HostBridgeCommandTests.swift` and the Phase 180 gate tests, which are read-only evidence and are not edited.

</code_context>

<specifics>
## Specific Ideas — adversarial resolutions

1. **Versioning premise.** One researcher proposed a conditional `native_runtime_version` floor as the must-understand gate. In the source, both sides of that comparison are generated data, so a floor in the data cannot stop an older binary. Resolution: D-16 adds a compiled-in constant, a fail-closed generation-time gate and an accepted, documented residual.
2. **Manifest field shape.** A proposal changed the route `capabilities` field to versioned objects. That would make every older shell fail to decode the manifest, which breaks all routes. Resolution: D-06 adds a separate `host_commands` object and leaves the existing field unchanged.
3. **Runtime restriction.** A proposal allowed `host.*` only on offline islands. Existing LiveView sessions already use `host.*` commands. Resolution: D-04 allows them on both bridge runtimes and rejects them on runtimes without a bridge session.
4. **Declaration placement.** One lens placed declarations inline as `host_commands:` on each route; another used a central registry with route references. Resolution: D-02 uses a central versioned registry, with routes referencing commands in their existing `capabilities:`, which the gate test and handoff contract require.
5. **New reason codes.** Two lenses proposed new wire reason codes. The reason vocabulary is a pinned contract mirrored in the frozen Android vectors. Resolution: D-18 makes messages and hints specific instead.
6. **Admission opt-in switch.** The DX lens suggested a shell config flag to enable island admission. That would duplicate the route's own runtime declaration. Resolution: D-11 adds no switch.
7. **Island transfer denial.** One proposal denied transfers on islands. That is a new restriction outside the success criteria. It was not adopted and is listed under Deferred Ideas.

</specifics>

<deferred>
## Deferred Ideas

- A generated Swift constants file or enum for host commands, and a static scan of Swift `registeredCommands` for doctor. Both add new generated surface; reconsider if command-name drift is observed.
- Island-specific restrictions beyond the LiveView checks, such as denying transfers on islands. Revisit only with evidence.
- Offline cold start for islands (a service worker or a host-supplied cache), outbox durability guarantees and data-store survival. These belong to Phase 180 evidence or later work.
- Android host-command support, which is frozen.
- All Phase 180 demonstration work (T01–T10).
- Release, publication, merge and PR delivery.

No pending todos matched Phase 181. No SPEC, prior context or checkpoint existed.

</deferred>

---

*Phase: 181-core-host-command-seam*
*Context gathered: 2026-10-14*
