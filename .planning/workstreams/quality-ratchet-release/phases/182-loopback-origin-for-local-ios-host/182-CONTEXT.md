# Phase 182: Loopback Origin for Local iOS Host - Context

**Gathered:** 2026-10-14
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase adds one explicit local/dev mode to the existing `:crosswake, :ios_host` declaration. In that mode, the generated iOS host may use a plain-`http` loopback origin (`http://127.0.0.1[:port]` or `http://localhost[:port]`). The Phase 180 twin can then load `http://127.0.0.1:4790` in the iOS Simulator.

Production origin validation stays HTTPS-only and fails closed. The generated app gets only the ATS `NSAllowsLocalNetworking` exception, and only in this mode. Check, inspect, doctor and the physical proof lane report the mode honestly or refuse it.

The phase ends by moving the Phase 180 candidate onto the new head with a verified, recorded move. The uncommitted 180-03/180-04 work and the three SHA-pinned feasibility tests must stay byte-identical. 180-05 can then rerun from Task 1.

Requirements: LOOP-01 through LOOP-05, in `REQUIREMENTS.md`.

Authority comes from the user's "Allow loopback" choice when 180-05 was blocked (`180-ORIGIN-DECISION.json`). That choice covers only the narrow loopback mode. It does not cover:
- arbitrary `http` origins;
- `NSAllowsArbitraryLoads`;
- Android changes;
- push, merge, release or PR;
- any recovery-checkout Git mutation.

</domain>

<decisions>
## Implementation Decisions

### Decision process
- **D-01:** The user selected all four gray areas. They asked for a broad fan-out through every relevant lens, an adversarial pass, and one coherent set of recommendations that is followed automatically. Their two "fan-out" boilerplate prompts and their preference for "another copy and paste over another dependency" apply. Four research subagents covered the four areas, and an orchestrator adversarial pass then checked their claims against the candidate source. Section D-20 below records the conflicts that pass resolved.
  - This delegates bounded design judgment within the existing authorization only. It approves no new core capability beyond the loopback mode, no release, and no automatic plan/execute chaining.

### How the mode is switched on
- **D-02:** Add one optional key to the existing `:ios_host` declaration: `origin_mode: :local_loopback`.
  - The only accepted value is `:local_loopback`. Leaving the key out means today's HTTPS production validation, unchanged.
  - Do not add a `:production` synonym, a generator CLI flag, a second declaration key such as `:ios_host_local`, or inference from the origin string.
  - Inference is rejected because the origin string would silently become the switch. A CLI flag is rejected because `--check`, doctor and `gen.proof_lane` could not see it, and `:ios_host` already refuses CLI overrides. Note that `--local` already means a local package path.
  - The key set becomes "six required keys plus one optional key". Unknown keys are still rejected. — **Reversibility:** costly — the key is public declaration surface in guides/renderers and host configs; renaming it later means a deprecation path.
- **D-03:** The key belongs in the host's dev or runner-owned config, never in shared `config/config.exs`. `IOSHostConfig` normalization (or the generator) refuses `origin_mode` when `Mix.env() == :prod`:
  - `origin_mode :local_loopback is not accepted when MIX_ENV=prod; remove it from production config`
- **D-04:** Allowed origins in the mode are exactly `http://127.0.0.1` and `http://localhost`, with an optional decimal port from 1 to 65535.
  - Canonicalize the default `:80` away and keep any other port, matching the existing HTTPS canonicalization.
  - Never rewrite `localhost` to `127.0.0.1` or the reverse. They are different origins for cookies and Phoenix `check_origin`, and `localhost` may resolve to `::1`.
  - Phase 180 declares `http://127.0.0.1:4790` exactly.
  - The mode rejects:
    - `[::1]` and every other IPv6 literal;
    - `0.0.0.0` and other `127.x` addresses;
    - private/LAN IPs and `.local` names;
    - credentials, path, query and fragment;
    - `https` origins, because the mode and the scheme must agree.
- **D-05:** Error messages are explicit and actionable, in the existing `invalid …; use …` style. The planner may adjust exact punctuation but must keep each cause and repair:
  - production, `http` origin: `invalid origin; use an absolute HTTPS origin without credentials, path, query, or fragment; for a local Simulator demo only, set origin_mode: :local_loopback with http://127.0.0.1:PORT or http://localhost:PORT`
  - mode set, non-loopback `http` host: `invalid local origin; origin_mode :local_loopback accepts only http://127.0.0.1 or http://localhost with an optional port`
  - mode set, `https` origin: `invalid origin_mode; :local_loopback requires an http loopback origin; remove origin_mode to use an HTTPS origin`
  - unknown mode value: `invalid origin_mode; use :local_loopback or omit the key for HTTPS production origins`
  - The existing "example/placeholder host" rejection stays for HTTPS origins.

### What the generated app carries
- **D-06:** `CrosswakeShell/Info.plist` is the app target's real plist (`GENERATE_INFOPLIST_FILE = NO` with `INFOPLIST_FILE`). It is rendered from the `gen.shell` template list but written by `ensure_file/2` (create once, then host-owned); it is **not** one of the three `ManagedOutputs` paths. See D-23 for how the Crosswake-owned block is kept fresh.
  - **Production (no mode):** the generated Info.plist stays byte-identical to today. It has no `NSAppTransportSecurity` and no Crosswake mode key.
  - **Local loopback mode:** the Info.plist adds exactly the block below. The ATS dictionary's key set must equal `[NSAllowsLocalNetworking]`.

    ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    <key>CrosswakeOriginMode</key>
    <string>local_loopback</string>
    ```

  - Never emit `NSAllowsArbitraryLoads`, `…InWebContent`, `…ForMedia` or `NSExceptionDomains`. Tests assert their absence in both modes.
  - Apple documents that `NSAllowsLocalNetworking` covers IP addresses, which iOS 17+ otherwise blocks by default. `localhost` is an unqualified domain, and the key also serves as a declaration of intent.
  - No `NSLocalNetworkUsageDescription` is needed, because loopback is exempt from the Local Network privacy prompt.
  - Per-configuration (Debug/Release) plists are rejected. They would turn one frozen generated tree into two app identities, against Phase 180 D-19 and D-14. — **Reversibility:** reversible.
- **D-07:** ATS is a backstop, not the loopback boundary, because `NSAllowsLocalNetworking` admits HTTP to any IP. The loopback guarantee comes from Crosswake's origin allowlist (D-04) and the existing same-origin navigation policy. The Swift `URL.crosswakeOrigin` already handles `http` and ports, so no Swift core change is expected.
  - If planning or execution finds that the Swift/coordinator side does need a change, keep it minimal and in scope. Do not add a new protocol.
- **D-08:** Mode markers. Detection must never treat "no marker" as proof of production. Any positive local signal counts: an `http` origin, the ATS key, or `CrosswakeOriginMode`. The markers are:
  1. `CrosswakeOriginMode = local_loopback` in the generated Info.plist. It travels inside the built `.app`, so the Phase 180 receipt can check the binary that actually ran.
  2. The `http` loopback origin in the digest-tracked managed activation output. The mode is not added to the managed-metadata JSON (see D-23).
  3. A generated README banner: "Local loopback build for Simulator demonstration. Not physical, adopter, or release evidence."
  - Do **not** change the manifest or activation JSON wire schema. Manifest schema 1.2.0 and the bridge 1.1.0 from Phase 181 stay as they are, and Android vectors stay frozen. The `http` origin already present in activation is itself a positive signal.
- **D-09:** Toggling the mode changes managed output (the activation origin) and the Crosswake-owned Info.plist block (D-23). `mix crosswake.gen.shell ios --check` reads the mode only from the declaration and reports a mode change, or a plist block that does not match the declaration, as drift: `blocked; cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios`. Removing the mode and regenerating removes the ATS block through the D-23 reconcile, so no exception sticks around.
- **D-10:** `mix crosswake.gen.proof_lane` and `Crosswake.ProofLane.Generator.generate/2` refuse a local-mode host config, failing closed with: `physical proof lane refuses origin_mode :local_loopback; loopback reaches the device itself, so use the HTTPS production origin`. On a physical iPhone, `127.0.0.1` is the phone, not the Mac, so the mode is Simulator-only.
- **D-11:** Leave `WKAppBoundDomains` (currently a fixed `example.com`) unchanged in this phase. It has no effect, because `limitsNavigationsToAppBoundDomains` is never set, and doctor checks that the key is present. Follow-up is in the deferred ideas.

### How tools report it
- **D-12:** Reuse the existing `Crosswake.Doctor.Check` struct and severity rules. Add no new taxonomy and no banner system.
  - Finding code `ios_host.local_loopback_origin`, with `check: "ios_host_origin"`.
  - Detection reads the generated outputs (Info.plist marker/ATS, managed metadata origin) and cross-checks the declaration when one is available.
  - **Normal `mix crosswake.doctor`:** severity `:warning`, exit 0. No "ready"-style summary wording while the finding is present.
    - Message: `This iOS host is generated in local loopback mode and loads <canonical origin> over plain HTTP. On an iPhone, 127.0.0.1 means the phone itself, not your Mac. This build is for local Simulator demonstration only and is not production-ready.`
    - Hint: `Before distributing, remove origin_mode from :ios_host, set origin to your HTTPS production origin, and rerun mix crosswake.gen.shell ios.`
    - Details: `%{origin: canonical scheme://host:port, mode: "local_loopback"}`.
  - **`--check-publish`:** the same code at severity `:error`, report `:not_ready`, nonzero exit. The planner must confirm that `PublishReadiness` is the host-side readiness profile. Source shows it derives route readiness through `OperatorInspection`. If it turns out to be library-release-only, record why and keep the refusal in doctor plus the proof lane.
  - **Inconsistent generated state is an `:error`** (`ios_host.origin_mode_mismatch`, repair `rerun mix crosswake.gen.shell ios`). That covers: ATS keys or the marker with an HTTPS origin; an `http` origin without the marker; or a declaration whose mode differs from the generated outputs.
- **D-13:** `mix crosswake.gen.shell ios --check` keeps its freshness result and exit status. Freshness and production readiness stay separate, so a fresh local build is never reported as blocked. In local mode it adds one line: `origin mode: local loopback (<origin>); Simulator only; not production-ready; before distributing, switch to your HTTPS production origin and regenerate`.
- **D-14:** `mix crosswake.inspect` prints the host origin with `(local loopback mode, Simulator only, not production-ready)` in local mode, and the bare origin in HTTPS mode. This applies only if inspect has a host/origin section or can add one minimally. Otherwise doctor and `--check` carry the report, and the plan records that.
- **D-15:** Privacy: print only the canonical `scheme://host:port` that the validator returns. Never print the entry URL, signing team, bundle IDs, tokens or other `:ios_host` values in these findings.
- **D-16:** Update the support-matrix and capability-map renderer strings (`support_matrix/renderer.ex`, `capability_map/renderer.ex`), and the guides they render, together with `guides/native_shell.md`.
  - Keep "HTTPS primary origin" and add that an explicit `origin_mode: :local_loopback` allows only `http://127.0.0.1`/`http://localhost` for Simulator demonstration, reported as not production-ready.
  - `guides/native_shell.md` gets one short paragraph covering how to switch the mode on and off, the ATS posture, and that loopback on a physical iPhone is the phone itself.
  - Guides never mention `NSAllowsArbitraryLoads` as an option.

### Verification
- **D-17:** All checks are automated (AGENTS zero-human rule). Each required test must prove the behavior actually happens, not just that nothing errored:
  1. **Validator.** Production `http` is denied. Mode plus 127.0.0.1/localhost, with and without a port, is accepted. Every rejected host class in D-04 is denied. `https` under the mode is denied, the unknown mode is denied, and `MIX_ENV=prod` with the mode is denied.
  2. **Generation.** Production Info.plist is byte-identical to the pre-phase template output. Local Info.plist has an ATS key set equal to `[NSAllowsLocalNetworking]` and has the marker. Forbidden ATS keys are absent in both modes.
  3. **Freshness.** `--check` drift appears when the mode toggles, and the local mode line is printed.
  4. **Doctor.** A local fixture gets exactly one warning. An HTTPS fixture shows the code absent (paired control). `--check-publish` reports not ready for local and ready for HTTPS. The stale/mismatch cases produce errors. A leak guard checks that only `scheme://host:port` appears.
  5. **Proof lane** refuses local mode.
  6. **Renderer/guide drift** is caught.
  7. **Simulator load.** One automated iOS Simulator check: generate a local-mode app, build it, launch it, and observe the WKWebView load a page from a test-owned `http://127.0.0.1:<port>` listener under the generated ATS posture. This settles the ambiguity in Apple's documentation before 180-05 depends on it.
     - If no Simulator or toolchain is available, the result is **blocked, not passed**.
     - Keep the check small and test-owned, not the Phase 180 twin runner. No permanent CI simulator lane.
- **D-18:** Stable, fast contracts (items 1–6) may join existing CI leaves where they already run; add no new lane. Elixir checks use the existing test suites. No new dependency is justified.

### Candidate and move onto Phase 180
- **D-19:** Build in a separate clone, following the Phase 181 precedent and the "its own candidate" wording in `180-ORIGIN-DECISION.json`. Never use `git worktree add` from the recovery repo.
  - **Setup:**
    - `git clone --no-hardlinks /private/tmp/crosswake-phase181-impl /private/tmp/crosswake-phase182-impl`
    - push URL set to `no-push-phase182`
    - `git switch -c phase182-impl 12f84cd950d4574921767df823faed6797c17c26`
    - assert HEAD `12f84cd…`, tree `e51f069d…`, clean status
  - Commit Phase 182 work on that branch only. Commits there are authorized by this phase's plans. Never push.
  - **Hard rule:** `git diff --name-only 12f84cd..<182head>` must not touch any of the 21 uncommitted Phase 180 paths. Phase 182 does not edit `examples/phoenix_host/**`. The example host's loopback `:ios_host` declaration stays with 180-05 Task 1 under 180 D-14. — **Reversibility:** reversible.
- **D-20:** The final plan moves the Phase 180 candidate. These are its only writes in `/private/tmp/crosswake-phase180-impl`:
  1. **Precheck.**
     - phase180 HEAD is `12f84cd`;
     - the overlap between the 182 diff paths and the `git status --porcelain` paths is empty;
     - the three pins match:
       - `01df8264…56f5`: `test/crosswake/proof/phase180_twin_feasibility_test.exs`
       - `f7b96890…aa19`: `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs`
       - `a3bcef6e…5672`: `Phase180TwinFeasibilityTests.swift`
     - Verify the full digests against Phase 180 records. Never edit these files.
  2. **Before-manifest** in the scratch dir, not the repo. For each dirty path record:
     - path, porcelain status, sha256 and mode;
     - the sha256 of `git diff --binary HEAD`;
     - plus a safety tarball of the dirty files and the binary diff, made outside Git.
  3. `git -c gc.auto=0 -C /private/tmp/crosswake-phase180-impl fetch /private/tmp/crosswake-phase182-impl phase182-impl`
  4. `git -c gc.auto=0 -C /private/tmp/crosswake-phase180-impl checkout --detach <182head>`. No `-f`, `-m`, stash, rebase, `git am` or `git apply`.
  5. **After-manifest.** Every recorded value must be identical. Check that HEAD equals `<182head>` and that the tree equals the 182 clone's tree.
  - **Abort conditions:** HEAD is not `12f84cd`; a pin mismatches; overlap is not empty; checkout refuses; any after-value differs; the tree mismatches. On abort:
    - record `result: blocked` with the cause;
    - restore from the tarball if needed and check out `12f84cd` again;
    - never force, and never retry with different flags.
- **D-21:** Record the move in `.planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-CANDIDATE-MOVE.json`. It is a plain file and is never committed in the recovery checkout.
  - Schema: `crosswake.phase182.candidate_move/1`.
  - Fields:
    - `candidate`, `source_candidate`, `method: "fetch+checkout --detach"`;
    - `old_head`/`old_tree`, `new_head`/`new_tree`;
    - `core_diff_paths[]`, `overlap: []`;
    - `carried_paths[]` with `{path, status, sha256_before, sha256_after, mode_before, mode_after}`;
    - `pinned_tests[]`, `binary_diff_sha256_before/after`;
    - `verification_commands[]`, `result`, `moved_at`, `safety_backup_path`;
    - `gate_rerun_required: true`.
  - Do not edit `180-CANDIDATE.json`, `180-GATE.json`, `180-05-BLOCKED.md` or `180-ORIGIN-DECISION.json`. Phase 180 consumes the decision: its rerun of the 180-01 gate against `new_head` writes a new verdict bound to that head and keeps the 12f84cd verdict as baseline. Only after `existing_path_supported` does 180-05 rerun from Task 1 and set `consumed_by`.

### Conflicts resolved in the adversarial pass
- **D-22:**
  - One researcher assumed `GENERATE_INFOPLIST_FILE = YES` and planned a plist fragment. Source shows the app target uses a real managed `Info.plist` (`YES` applies only to test targets), so the template is conditioned directly.
  - Another researcher thought Info.plist was host-owned, which would leave stale exceptions. The discussion's adversarial pass wrongly called it managed; plan-phase research (2026-10-14) confirmed it is written by `ensure_file/2` and is not a `ManagedOutputs` path. D-23 replaces that resolution.
  - One proposal added `origin_mode` to the activation JSON. It was dropped to avoid a wire-schema change after Phase 181's versioned schema (D-08).
  - ATS was not treated as the loopback boundary (D-07).
  - Apple's documentation is ambiguous about whether `127.0.0.1` is covered, so the Simulator load check became mandatory (D-17.7).

### Correction from plan-phase research (2026-10-14)
- **D-23:** Info.plist freshness. A template branch alone would leave a stale ATS block after a toggle, because `ensure_file/2` never rewrites an existing Info.plist. Adding Info.plist as a fourth `ManagedOutputs` path is rejected: existing hosts' metadata decode requires exactly three outputs, and the docs call Info.plist host-owned.
  - Instead, a new pure module (working name `Crosswake.Shell.IOSHostOriginMode`), modeled on `IOSHostProjectMigration`, reconciles exactly the Crosswake-owned block: the `NSAppTransportSecurity` dict with only `NSAllowsLocalNetworking`, and `CrosswakeOriginMode`. It compares expected bytes, replaces atomically, and refuses (fails closed with a repair message) when the host has edited the ATS shape into anything else.
  - `gen.shell ios` applies the reconcile in both directions; `--check`, `--diff` and doctor read the plist state and report a mismatch with the declaration.
  - **Production-host exception (plan-check revision, 2026-10-14):** the refusal applies only when local mode is declared. With no `origin_mode`, a host-owned `NSAppTransportSecurity` dict that is not exactly the Crosswake block and carries no `CrosswakeOriginMode` marker is host configuration: the reconcile leaves it byte-for-byte untouched, `--check`/`--diff` report no drift for it, and doctor raises no finding, so existing production hosts do not regress. Only the exact Crosswake block or a `CrosswakeOriginMode` key counts as a local signal (D-08). Under local mode, a non-Crosswake ATS dict is refused fail-closed (`info_plist_conflict`); repair: remove or merge it by hand, then rerun `mix crosswake.gen.shell ios`.
  - **Declared local mode with a missing or unreadable Info.plist** is a mismatch (`:error` in doctor, drift in `--check`), never production by absence and never a mere warning (D-12).
  - The production template still renders byte-identically when no mode is set (D-06).
  - The README banner is written by the inline `shell_readme/1` (not `README.md.eex`), is create-once, and is never used as a detection signal.
  - **Simulator finding:** on the installed iOS 26.5 runtime, WKWebView loads `http://127.0.0.1` and `http://localhost` even with no ATS dict. The D-17.7 check therefore asserts that loopback loads under the generated posture **and** that the exception stays narrow (`http://example.com/` still fails with `NSURLErrorDomain -1022`). It must not assert that the production plist cannot load loopback. This reinforces D-07: the allowlist is the boundary. — **Reversibility:** reversible.

### Claude's Discretion
- Exact module placement: whether the mode check lives in `IOSHostConfig` or the generator; and the struct field naming (`origin_mode` stored as an atom).
- How the Info.plist template branches.
- The exact doctor check function name.
- The precise test file layout.
- The cheapest reliable Simulator harness for D-17.7: XCUITest, `simctl` plus a page-reported marker over the test-owned listener, or similar. It must observe an actual WebView load, not only a build.
- Minor wording polish of messages that keeps each cause and repair. Follow `brandbook/BRAND-SPEC.md` voice where guides change.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authority and boundaries
- `AGENTS.md`: recovery-checkout no-Git-mutation rule, Android freeze, privacy rules, zero-human verification, plain-language handoffs, one active handoff.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-ORIGIN-DECISION.json`: the user's "Allow loopback" decision, its scope, what it does not authorize, and the resume condition.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-05-BLOCKED.md`: the exact validator failure and the resume posture.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-CONTEXT.md`, decisions D-02, D-08, D-13, D-14, D-19, D-20, D-27: loopback origin freezing, the identity freeze, the anti-relabel rule and recovery-checkout preservation.
- `.planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-CANDIDATE.json`: the Phase 181 move precedent (`authorized_seam_rerun`).
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: LOOP-01..05 and v25 boundaries.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md`, Phase 182: goal and success criteria.
- `.planning/ADR-FIRST-B2C-ADOPTER.md`: thesis and stop list.

### Source to change, in the Phase 182 clone (based on candidate head 12f84cd)
- `lib/crosswake/shell/ios_host_config.ex`: strict key set and `valid_origin/1`, HTTPS-only.
- `lib/crosswake/shell/ios_host_generation.ex`: origin projection and managed metadata.
- `lib/mix/tasks/crosswake.gen.shell.ex`: template list (Info.plist ~line 64), `:ios_host` read (~91), CLI-override refusal (~103), `--check` output (~193–207).
- `priv/templates/crosswake/shell/ios/Info.plist.eex`, `README.md.eex`.
- `lib/mix/tasks/crosswake.gen.proof_lane.ex` (~132) and `lib/crosswake/proof_lane/generator.ex`.
- `lib/crosswake/doctor/doctor.ex` (~81 Info.plist check), `lib/crosswake/doctor/check.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/mix/tasks/crosswake.doctor.ex`, `lib/mix/tasks/crosswake.inspect.ex`.
- `lib/crosswake/support_matrix/renderer.ex:137`, `lib/crosswake/capability_map/renderer.ex:81`, and `guides/support_matrix.md`, `guides/capability_map.md`, `guides/native_shell.md`, `guides/native_shell_upgrade.md`.
- `test/crosswake/shell/ios_host_config_test.exs` and the existing shell/doctor test suites.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`: `URL.crosswakeOrigin` already supports `http` (read-only reference).

### External primary sources
- Apple, NSAllowsLocalNetworking: https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking
- Apple, NSAppTransportSecurity: https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity
- Apple, Preventing Insecure Network Connections: https://developer.apple.com/documentation/security/preventing-insecure-network-connections
- Apple Developer Forums, loopback exempt from Local Network privacy: https://developer.apple.com/forums/thread/650810
- git-checkout(1), "Switching branches": https://git-scm.com/docs/git-checkout
- Capacitor config (cleartext/server.url "not for production"): https://capacitorjs.com/docs/config

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `IOSHostConfig.valid_origin/1`: its HTTPS canonicalization (default port removal, host checks) is the pattern for the loopback branch.
- `Crosswake.Doctor.Check` (`severity` `:error`/`:warning`/`:advisory`, `code`, `message`, `hint`, `check`, `details`). Overall status is an error only on `:error` findings.
- `Crosswake.Doctor.PublishReadiness`: the existing `--check-publish` `:ready`/`:not_ready` profile.
- The managed-outputs freshness machinery behind `gen.shell --check`.
- Swift `URL.crosswakeOrigin`, which already handles `http` and ports.

### Established Patterns
- Error strings follow the form `invalid <thing>; <actionable repair>`.
- Doctor codes are snake_case with optional dotted namespaces.
- `:ios_host` is the single, strictly validated declaration read by every downstream surface.
- Generated Info.plist and xcconfig are managed outputs.

### Integration Points
- The `:ios_host` declaration feeds gen.shell, `--check`, gen.proof_lane, renderers, and now doctor.
- The generated Info.plist feeds the built `.app`, which feeds the Phase 180 twin receipt (D-19/D-20 identity, outside this phase).
- The candidate move record (`182-CANDIDATE-MOVE.json`) feeds the Phase 180 gate rerun and then 180-05 Task 1.

</code_context>

<specifics>
## Specific Ideas

- Phase 180 declares exactly `http://127.0.0.1:4790`, not `localhost`. The twin runner binds IPv4 loopback only (180 D-13/D-14).
- Message tone: plain language that says what is wrong and the one next action. It explains that `127.0.0.1` on a physical iPhone is the phone itself.
- Fan-out was user-directed: four research subagents plus an orchestrator adversarial pass. No dependency is added; copying a small pattern beats a dependency.

</specifics>

<deferred>
## Deferred Ideas

- `WKAppBoundDomains` is a fixed `example.com` and has no effect. Whether to derive it from the origin, or to enable `limitsNavigationsToAppBoundDomains`, needs its own decision. Apple's support for IP literals and localhost there is unverified.
- IPv6 loopback (`[::1]`), LAN/`.local` origins and physical-device local mode are not authorized. They need a fresh decision and evidence.
- Per-configuration (Debug/Release) plist splitting: revisit only if hosts later build local and production from one long-lived checkout.
- From 180-04: the island contract uses route id `study-session` but the router id is `offline-study`. That belongs to Phase 180, not this phase.

</deferred>

---

*Phase: 182-loopback-origin-for-local-ios-host*
*Context gathered: 2026-10-14*
