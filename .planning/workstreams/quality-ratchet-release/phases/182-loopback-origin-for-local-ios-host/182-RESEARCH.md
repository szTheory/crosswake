# Phase 182: Loopback Origin for Local iOS Host - Research

**Researched:** 2026-10-14
**Domain:** Elixir/Mix iOS host generator (origin validation, managed outputs, doctor), Apple ATS, iOS Simulator WKWebView load check, Git-based candidate move
**Confidence:** HIGH for in-repo shapes and the Simulator harness (both exercised this session); MEDIUM for Apple ATS semantics (docs ambiguous, observation single-runtime)

All source reads were of the READ-ONLY candidate `/private/tmp/crosswake-phase181-impl` (HEAD `12f84cd950d4574921767df823faed6797c17c26`, tree `e51f069d52b1c1303d8d606d6000ff146654948e`, `git status --porcelain` empty before and after this research). Experiments ran in session scratch only (a throwaway `rsync` copy, since deleted). No Git write happened in any repo.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Decision process**
- **D-01:** The user selected all four gray areas. They asked for a broad fan-out through every relevant lens, an adversarial pass, and one coherent set of recommendations that is followed automatically. Their two "fan-out" boilerplate prompts and their preference for "another copy and paste over another dependency" apply. Four research subagents covered the four areas, and an orchestrator adversarial pass then checked their claims against the candidate source. Section D-20 below records the conflicts that pass resolved.
  - This delegates bounded design judgment within the existing authorization only. It approves no new core capability beyond the loopback mode, no release, and no automatic plan/execute chaining.

**How the mode is switched on**
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

**What the generated app carries**
- **D-06:** `CrosswakeShell/Info.plist` is a managed output: it is in the `gen.shell` template list, and the app target uses `GENERATE_INFOPLIST_FILE = NO` with `INFOPLIST_FILE`.
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
  2. The mode recorded in the generator's managed metadata (`.crosswake/ios_host_generation.json`, or whatever the existing managed-metadata record is).
  3. A generated README banner: "Local loopback build for Simulator demonstration. Not physical, adopter, or release evidence."
  - Do **not** change the manifest or activation JSON wire schema. Manifest schema 1.2.0 and the bridge 1.1.0 from Phase 181 stay as they are, and Android vectors stay frozen. The `http` origin already present in activation is itself a positive signal.
- **D-09:** Toggling the mode changes managed output. `mix crosswake.gen.shell ios --check` reads the mode only from the declaration and reports a mode change as drift: `blocked; cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios`. Removing the mode and regenerating removes the ATS block, so no exception sticks around.
- **D-10:** `mix crosswake.gen.proof_lane` and `Crosswake.ProofLane.Generator.generate/2` refuse a local-mode host config, failing closed with: `physical proof lane refuses origin_mode :local_loopback; loopback reaches the device itself, so use the HTTPS production origin`. On a physical iPhone, `127.0.0.1` is the phone, not the Mac, so the mode is Simulator-only.
- **D-11:** Leave `WKAppBoundDomains` (currently a fixed `example.com`) unchanged in this phase. It has no effect, because `limitsNavigationsToAppBoundDomains` is never set, and doctor checks that the key is present. Follow-up is in the deferred ideas.

**How tools report it**
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

**Verification**
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

**Candidate and move onto Phase 180**
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

**Conflicts resolved in the adversarial pass**
- **D-22:**
  - One researcher assumed `GENERATE_INFOPLIST_FILE = YES` and planned a plist fragment. Source shows the app target uses a real managed `Info.plist` (`YES` applies only to test targets), so the template is conditioned directly.
  - Another researcher thought Info.plist was host-owned, which would leave stale exceptions. It is managed, so `--check` drift (D-09) covers that, and doctor's mismatch error (D-12) is the second guard.
  - One proposal added `origin_mode` to the activation JSON. It was dropped to avoid a wire-schema change after Phase 181's versioned schema (D-08).
  - ATS was not treated as the loopback boundary (D-07).
  - Apple's documentation is ambiguous about whether `127.0.0.1` is covered, so the Simulator load check became mandatory (D-17.7).

### Claude's Discretion
- Exact module placement: whether the mode check lives in `IOSHostConfig` or the generator; and the struct field naming (`origin_mode` stored as an atom).
- How the Info.plist template branches.
- The exact doctor check function name.
- The precise test file layout.
- The cheapest reliable Simulator harness for D-17.7: XCUITest, `simctl` plus a page-reported marker over the test-owned listener, or similar. It must observe an actual WebView load, not only a build.
- Minor wording polish of messages that keeps each cause and repair. Follow `brandbook/BRAND-SPEC.md` voice where guides change.

### Deferred Ideas (OUT OF SCOPE)
- `WKAppBoundDomains` is a fixed `example.com` and has no effect. Whether to derive it from the origin, or to enable `limitsNavigationsToAppBoundDomains`, needs its own decision. Apple's support for IP literals and localhost there is unverified.
- IPv6 loopback (`[::1]`), LAN/`.local` origins and physical-device local mode are not authorized. They need a fresh decision and evidence.
- Per-configuration (Debug/Release) plist splitting: revisit only if hosts later build local and production from one long-lived checkout.
- From 180-04: the island contract uses route id `study-session` but the router id is `offline-study`. That belongs to Phase 180, not this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOOP-01 | `origin_mode: :local_loopback` is the only switch; production stays HTTPS-only; unknown mode, https under mode, mode under `MIX_ENV=prod` denied | `IOSHostConfig` shape and strict key logic (Finding F1); `Mix.env()` fail-closed pattern (Pattern 1); canonicalization probes (Pitfall 6) |
| LOOP-02 | Only `127.0.0.1`/`localhost` + optional port; IPv6, other IPs, `.local`, credentials, path, query, fragment denied | Verified `URI.parse` behavior table (Security Domain); exact-match allowlist after the existing authority cross-check |
| LOOP-03 | Info.plist ATS = exactly `NSAllowsLocalNetworking` + marker; production byte-identical; toggling is drift; Simulator WebView load observed | Finding F2 (Info.plist is NOT managed - reconcile needed), template technique verified byte-identical, Simulator harness verified end to end |
| LOOP-04 | Doctor warning/error/publish; `--check` and inspect name the mode; proof lane refuses; guides/support truth; canonical origin only | Doctor/PublishReadiness/Formatter shapes, `--check-publish` profile finding (F4), proof-lane refusal points, renderer/guide drift tests |
| LOOP-05 | `182-CANDIDATE-MOVE.json` recording the verified move | Phase 180 dirty-path/pin facts verified (F6), git semantics, abort conditions |
</phase_requirements>

## Summary

The change is small in code but has one load-bearing surprise. **CONTEXT D-06/D-22 say `CrosswakeShell/Info.plist` is a managed output. In the candidate source it is not.** The managed set is exactly three files (`Fixtures/crosswake_manifest.json`, `Fixtures/route_activation.json`, `CrosswakeHostSettings.xcconfig`); `Info.plist` is rendered by `ensure_file/2`, which writes only when the file is absent and otherwise returns `:reused`. A toggle after first generation therefore leaves a stale ATS block (or a stale missing block) behind, `--check` cannot see it, and `gen.shell ios` cannot repair it. D-09 ("removing the mode and regenerating removes the ATS block") is only achievable if Phase 182 adds a bounded, recognizing reconcile step for exactly the Crosswake-owned block, modeled on the existing `IOSHostProjectMigration` / `write_migration_project` precedent. Making Info.plist a fourth managed output was evaluated and rejected (breaks every existing host's metadata and the "host-owned" docs). Details and a recommended design are in Finding F2 and Pattern 3. This falls inside the CONTEXT "Claude's Discretion" item "How the Info.plist template branches", but the planner should record it as a deliberate, user-visible implementation decision (Open Question 1).

The rest is mechanical and low risk. `IOSHostConfig.valid_origin/1` is HTTPS-hardcoded and already has the authority cross-check that defeats `URI.parse` leniency (for example `http://127.0.0.1:80:80` parses to a valid-looking port 80 but is rejected by the raw-authority check). Generation, manifest compile and activation already accept an `http://127.0.0.1:4790` origin when handed a struct (verified by running it); only `normalize/1` blocks it. The Info.plist EEx branch can be written so production output is byte-identical (verified by rendering old and new templates). PublishReadiness is a Crosswake-library-release profile (it reads `mix.exs` package name, CHANGELOG, template coordinates), not a host profile, but it is the only existing `:not_ready` surface, so a *conditional* extra readiness check is the least invasive way to give `--check-publish` its refusal without disturbing the pinned `phase52_publish_readiness.json` fixture. `mix crosswake.inspect` has no host/origin section and its JSON is fixture-pinned, so the minimal route is a human-format-only trailing line printed by the Mix task.

The Simulator check is fully feasible with zero new dependencies and was proven end to end this session: a generated ios_host-path project (scratch, test env, ManagedRouter fixture) was patched to the D-06 plist and a minimal WKWebView app, built with `xcodebuild` for the iOS Simulator (~16 s warm), installed and launched on an iPhone 17 simulator (iOS 26.5 runtime, Xcode 26.6); a Python listener on `127.0.0.1` saw `GET /study-session` and the page's JS ping, and the app reported `didFinish`. **An important honest finding for the plan: on this runtime WKWebView also loads `http://127.0.0.1` and `http://localhost` with NO ATS dictionary at all, so the check cannot assert that `NSAllowsLocalNetworking` is necessary. It can (and should) assert that loopback loads under the generated posture AND that the exception stays narrow (`http://example.com/` still fails with `NSURLErrorDomain -1022`).** Do not write a "production plist must fail to load loopback" assertion; it would be false.

**Primary recommendation:** Implement validation in `IOSHostConfig` with an explicit `env:` option that fails closed when Mix is unavailable; put all Info.plist/README/marker logic in one new pure module (`Crosswake.Shell.IOSHostOriginMode`) used by `gen.shell` (render + bounded reconcile + `--check`) and by doctor; add a conditional PublishReadiness check; refuse in both proof-lane entry points; verify with the existing ExUnit suites plus one `script/` Simulator harness that reports `passed|blocked|unavailable` JSON in the style of `verify_generated_ios_shell.sh`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Origin/mode validation (allowlist, canonicalization, prod refusal) | Build tooling (Elixir `IOSHostConfig`) | Doctor (re-reads declaration) | Single strictly validated declaration read by every downstream surface; fails before any output is written |
| Info.plist ATS block + marker emission/removal | Build tooling (gen.shell + new origin-mode module) | Generated app bundle | Output is a generated native artifact; Elixir owns bytes, Xcode merely packages them |
| Loopback boundary (which hosts the app may load) | Crosswake origin allowlist (manifest `allowlisted_origins`, Swift same-origin policy) | ATS as backstop only | `NSAllowsLocalNetworking` admits HTTP to any IP; Crosswake allowlist is the real fence (D-07) |
| Drift/freshness reporting | Build tooling (`gen.shell --check`) | Doctor | `--check` is the freshness authority; doctor is the production-readiness authority; kept separate (D-13) |
| Production-readiness refusal | Doctor / PublishReadiness | Proof-lane generator | `--check-publish` is the only `:not_ready` surface; proof lane refuses because loopback is the phone itself |
| Simulator load evidence | Test harness (script + Simulator) | Generated app (host-owned Swift, test-substituted) | Only an actual WKWebView on a Simulator can settle ATS ambiguity |
| Candidate move | Git in `/private/tmp` clones | Planning dir (JSON record) | Strictly outside the recovery checkout |

## Standard Stack

### Core

No new libraries. Everything uses what the repo already ships. [VERIFIED: `mix.exs` untouched; D-18 says no dependency is justified]

| Tool | Version (observed) | Purpose | Why Standard |
|------|--------------------|---------|--------------|
| Elixir / OTP | 1.19.5 / OTP 27 (`.tool-versions`: `erlang 27.3`, `elixir 1.19.5-otp-27`, `nodejs 22.14.0`) | All source edits and ExUnit | Repo toolchain |
| ExUnit | bundled | Unit/integration | Existing suites |
| EEx | bundled | Info.plist template branching | Already used by `render_template/5` |
| `xcodebuild` / `xcrun simctl` | Xcode 26.6 (17F113), iOS 26.5 runtime | Simulator harness | Already used by `script/verify_generated_ios_shell.sh` |
| Python 3 `http.server` or Node (`node` 22 via asdf) | Python 3.14.4 at `/opt/homebrew/bin/python3` | Test-owned loopback listener | No dependency; Node already used for repo scripts (`priv/crosswake/verify_ios_host_settings.mjs`) |
| `jq`, `shasum`, `git` | system | Candidate-move manifests | Used by Phase 181 `<automated>` blocks |

### Supporting

| Existing module | Purpose | When to Use |
|-----------------|---------|-------------|
| `Crosswake.Shell.IOSHostConfig` | Declaration validation | Extend (do not replace) |
| `Crosswake.Shell.ManagedOutputs` | Managed output publish/check | Reuse its `safe_layout`/atomic-replace discipline via a sibling function; do not extend `@paths` |
| `Crosswake.Shell.IOSHostProjectMigration` + `ManagedOutputs.read_migration_project/write_migration_project` | Precedent for a bounded expected-bytes rewrite of a host-owned file | Model the Info.plist reconcile on it |
| `Crosswake.Doctor.Check`, `Doctor.check/6` (private) | Finding construction | New findings in `doctor.ex` |
| `Crosswake.Doctor.PublishReadiness.result_check/1`, `check/1` | Readiness checks | One conditional check |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bounded Info.plist reconcile | Add Info.plist as 4th `ManagedOutputs` path | Breaks `read_metadata` (`Enum.sort(Map.keys(o)) == Enum.sort(@paths)`), `decode_outputs` (`map_size(e) == 3`), every existing host's metadata, and contradicts "host-owned" docs. Rejected. |
| Bounded reconcile | Leave Info.plist scaffold-once and tell the maintainer to delete it | Violates D-09 ("rerun mix crosswake.gen.shell ios" repair and "no exception sticks around"). Rejected. |
| XCUITest | `simctl` + listener hit + app-written result file | XCUITest needs a test target, signing-free but heavier; `simctl` approach was proven in ~30 lines and needs no new target. Use `simctl`. |
| Mode recorded in `.crosswake/ios_host_generation.json` | Rely on managed `Fixtures/route_activation.json` origin + Info.plist marker | Metadata is digest-only and recovery code compares whole metadata maps; adding a key touches recovery paths for little gain (see F3). Prefer the activation origin as the managed positive signal. |

**Installation:** none.

**Version verification:** not applicable (no packages). Toolchain facts above were read from `.tool-versions`, `xcodebuild -version` (Xcode 26.6, build 17F113), `xcrun simctl list runtimes` (iOS 26.5, 23F77), `python3 --version`.

## Package Legitimacy Audit

No external packages are installed or recommended by this phase. Nothing to audit.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 host config (dev/runner only)            MIX_ENV=prod ----> refuse origin_mode (D-03)
 config :crosswake, :ios_host,                                   ^
   origin_mode: :local_loopback  ----+                           |
                                     v                           |
                         IOSHostConfig.normalize(input, env:)  ---+
                           | origin_mode nil  -> HTTPS-only path (unchanged bytes + messages + new http hint)
                           | origin_mode :local_loopback -> http loopback allowlist (127.0.0.1|localhost[:port])
                           v
                    %IOSHostConfig{origin, origin_mode}
          +----------------+-----------------------------+--------------------+
          v                v                             v                    v
   gen.shell ios     gen.shell ios --check          gen.proof_lane        Doctor.run
   (render+publish)  (+ plist/mode check, D-13)     (refuse local, D-10)  (reads declaration
          |                |                                                + generated outputs)
          |                |                                                    |
   IOSHostGeneration  ManagedOutputs.check (3 files)                  IOSHostOriginMode.inspect_plist
   .render -> manifest/activation (origin passes through unchanged)   -> warning | error(mismatch)
          |                                                                     |
   render_template(Info.plist.eex, origin_mode:)  -- ensure_file (create only)  PublishReadiness (conditional)
          |                                                                     -> --check-publish :not_ready
   IOSHostOriginMode.reconcile(Info.plist, mode)   <- bounded rewrite of ONLY the Crosswake block
          |
          v
   generated project (native/ios/crosswake_shell) --xcodebuild--> .app (Info.plist: ATS + CrosswakeOriginMode)
                                                                       |
                                      Simulator harness: listener(127.0.0.1:P) <-- WKWebView GET /entry + JS ping
```

### Recommended Project Structure

```
lib/crosswake/shell/
├── ios_host_config.ex            # extend: optional :origin_mode key, origin_mode-aware valid_origin
├── ios_host_generation.ex        # defense-in-depth: refuse http origin without :local_loopback
└── ios_host_origin_mode.ex       # NEW: pure plist block / inspect / reconcile / README banner / messages
lib/mix/tasks/crosswake.gen.shell.ex   # pass origin_mode assign; reconcile; --check line; shell_readme banner
lib/mix/tasks/crosswake.gen.proof_lane.ex  # refuse in load_host_config
lib/crosswake/proof_lane/generator.ex      # refuse in normalize_host!
lib/crosswake/doctor/doctor.ex             # ios_host_origin findings (+ publish signal)
lib/crosswake/doctor/publish_readiness.ex  # conditional ios_host origin check
lib/crosswake/doctor/formatter.ex          # optional: local-mode notice line near status
lib/mix/tasks/crosswake.inspect.ex         # human-format trailing origin line
priv/templates/crosswake/shell/ios/Info.plist.eex
script/verify_loopback_origin_simulator.sh # NEW: harness (+ small listener)
test/fixtures/shell/ios/Info.plist.production.golden   # NEW: captured from base BEFORE any edit
```

### Pattern 1: Optional key, fail-closed environment, no struct enforcement change

**What:** `@enforce_keys` is the six required keys and doubles as the struct field list and the strict key set. Add the optional key without enforcing it, otherwise pinned Phase 180 tests that build `%Crosswake.Shell.IOSHostConfig{...}` literals without it stop compiling.

Current source [VERIFIED: lib/crosswake/shell/ios_host_config.ex:4-14, 29-31, quoted verbatim]:
```elixir
  @enforce_keys [
    :router,
    :origin,
    :entry_route_id,
    :app_bundle_id,
    :proof_app_bundle_id,
    :device_signing
  ]
  defstruct @enforce_keys

  @keys @enforce_keys
```
```elixir
      Enum.sort(keys) != Enum.sort(@keys) ->
        {:error,
         "invalid :ios_host declaration keys; set router, origin, entry_route_id, app_bundle_id, proof_app_bundle_id, and device_signing"}
```
The pinned Phase 180 example-host test builds the struct literally [VERIFIED: /private/tmp/crosswake-phase180-impl/examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs:11-19]:
```elixir
    %Crosswake.Shell.IOSHostConfig{
      router: CrosswakeExample.Router,
      origin: @origin,
      entry_route_id: entry,
      app_bundle_id: "org.crosswake.twin",
      proof_app_bundle_id: "org.crosswake.twin.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
```
**Recommended shape** (design sketch, [ASSUMED] until implemented):
```elixir
  defstruct @enforce_keys ++ [origin_mode: nil]     # NOT enforced
  @required @enforce_keys
  @optional [:origin_mode]
  # key check: required exactly present; optional may be present; keep substring "declaration keys" in the error
  # (test/mix/tasks/crosswake_gen_shell_host_test.exs:403 asserts "declaration keys")

  def normalize(input, opts \\ [])     # keep arity-1 callers (gen.shell, gen.proof_lane, tests) working
  # env: Keyword.get(opts, :env, current_env())
  defp current_env do
    if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end
```
`current_env/0` returns `:prod` when Mix is absent so a release/runtime caller can never accept the mode by omission. Tests pass `env: :prod` explicitly because ExUnit async tests run in `MIX_ENV=test`.

**When to use:** all of LOOP-01/02.

### Pattern 2: Scheme-parameterized origin validation reusing the authority cross-check

The existing function [VERIFIED: lib/crosswake/shell/ios_host_config.ex:63-114] derives `authority` by regex on the raw string (`~r{\Ahttps://([^/?#]*)}i`), splits on `":"` with `parts: 2`, compares `authority_host != host`, and validates the port with `~r/\A[0-9]+\z/`. That cross-check is what rejects `http://127.0.0.1:80:80` (see Security Domain table: `URI.parse` accepts it). Keep it; parameterize the scheme regex (`http` vs `https`) and add, for the local branch, `host in ["127.0.0.1", "localhost"]` as an exact string match on the downcased host, followed by the same canonical-port rule (`80` dropped for http, any other 1..65535 kept, leading zeros normalized via `String.to_integer`).

Branch table (messages are the D-05 strings verbatim):

| `origin_mode` | scheme | result |
|---------------|--------|--------|
| absent | https | existing path, unchanged canonicalization and messages |
| absent | http | D-05 production-http message (the new hint appended) |
| `:local_loopback` | http, allowlisted host | `{:ok, "http://127.0.0.1[:port]"}` |
| `:local_loopback` | http, any other host | "invalid local origin; ..." |
| `:local_loopback` | https | "invalid origin_mode; :local_loopback requires an http loopback origin; ..." |
| other atom/value | any | "invalid origin_mode; use :local_loopback or omit the key ..." |
| `:local_loopback` with `env == :prod` | any | "origin_mode :local_loopback is not accepted when MIX_ENV=prod; ..." (check FIRST so prod never reports a softer cause) |

Order matters: validate the mode value and env gate before origin, so an unknown mode never reaches origin parsing. Never echo the supplied origin in any error (existing test: "rejects a malformed origin authority without echoing the supplied host").

### Pattern 3: Info.plist is scaffold-once - add a bounded reconcile (F2)

**Facts** (all [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex]):
- `@ios_templates` contains `{"CrosswakeShell/Info.plist", "ios/Info.plist.eex"}` (line 64) and `render_ios_templates/3` calls `ensure_file(Path.join(root, relative_path), render_template(template_path, capabilities, local, assigns))` (lines 358-367). `ensure_file/2` (lines 551-565) returns `:reused` when the file exists; it never rewrites.
- `render_template/5` (lines 369-386) supplies assigns `capabilities, local, version, template_version, cutout_mode` plus package paths. No host config reaches it.
- `ManagedOutputs` quoted verbatim [VERIFIED: lib/crosswake/shell/managed_outputs.ex:6-10]:
  ```elixir
  @paths [
    "Fixtures/crosswake_manifest.json",
    "Fixtures/route_activation.json",
    "CrosswakeHostSettings.xcconfig"
  ]
  ```
  and `defp decode_outputs(e) when is_map(e) and map_size(e) == 3`, and `read_metadata` requires `Enum.sort(Map.keys(o)) == Enum.sort(@paths)`.
- Docs say host-owned: `lib/crosswake/support_matrix/renderer.ex:...`/`capability_map/renderer.ex` "Host Swift, entitlements, and unrelated project customization remain host-owned"; the `Info.plist.eex` header reads `<!-- Host-owned after generation. See guides/native_shell_upgrade.md -->`; `test/mix/tasks/crosswake_gen_shell_stamp_test.exs` lists `CrosswakeShell/Info.plist` among stamped (scaffold) files; `guides/native_shell.md`: "Swift sources, entitlements, and other host project edits stay host-owned".

**Recommended design** (module `Crosswake.Shell.IOSHostOriginMode`, pure functions, [ASSUMED] design):
1. `block(:local_loopback)` returns the exact D-06 block (leading `\n`, no trailing newline) so it can be spliced.
2. Template: append the block after `LSRequiresIPhoneOS`'s `<true/>` using an end-of-line EEx conditional so production renders exactly as before. Verified this session: rendering the current `Info.plist.eex` and a modified copy with `origin_mode: nil` produced `old == prod` (`prod_identical=true`), and `:local_loopback` produced the D-06 block directly after `<true/>`:
   ```eex
       <key>LSRequiresIPhoneOS</key>
       <true/><%= if @origin_mode == :local_loopback do %>
       <key>NSAppTransportSecurity</key>
       <dict>
           <key>NSAllowsLocalNetworking</key>
           <true/>
       </dict>
       <key>CrosswakeOriginMode</key>
       <string>local_loopback</string><% end %>
       <key>UIApplicationSceneManifest</key>
   ```
   `render_template/5` must pass `origin_mode: nil` by default for EVERY template and for the legacy `--diff` path (`run_diff`), otherwise EEx raises on the missing assign.
3. Reconcile (called from `generate_ios_shell/5` only when `host_config` is present, after `render_ios_templates`): read `CrosswakeShell/Info.plist` with the same safe-layout discipline as `read_migration_project`; compute `desired = strip_exact_block(bytes) |> maybe_insert_block(mode)`.
   - Strip only the exact byte-for-byte block (including the exact `LSRequiresIPhoneOS` anchor). If the file contains `NSAppTransportSecurity` or `CrosswakeOriginMode` in any other shape (host-edited), refuse with `blocked; cause: info_plist_conflict`, never overwrite. Production mode + an unrecognized ATS dict is a hard stop with a repair message (review and remove the exception, or remove the host edit).
   - Insert only when the anchor exists exactly once.
   - Write with expected-bytes compare and atomic replace (mirror `write_migration_project/3`).
4. `--check` / `--diff` (host path): after `ManagedOutputs.check/2`, call `IOSHostOriginMode.inspect_plist(bytes)` against the declared mode. Mismatch prints `[crosswake] checked managed iOS outputs: blocked; cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios` and raises under strict `--check`. Missing Info.plist while a mode is declared is also mismatch (never "production by absence").
5. README: the generated README is `shell_readme/1` (an inline string literal in `gen.shell`), NOT `priv/templates/.../README.md.eex`. [VERIFIED: `crosswake_gen_shell_stamp_test.exs` moduledoc "README.md files are NOT stamped (generated from shell_readme/1 string literal, not .eex)"; `grep README.md.eex lib` finds no renderer]. Put the D-08.3 banner in `shell_readme/2` (platform, origin_mode) appended only in local mode so production README stays byte-identical. README is also scaffold-once, so the banner is only a first-generation convenience unless the same reconcile step manages one exact banner line; do NOT use the README as a detection signal. `README.md.eex` is listed in CONTEXT "Source to change" but is only scanned by `native_evidence_drift_test.exs`; editing it is unnecessary and risks that test.

**Do not** bump `@template_version` (currently 4). Production bytes are identical, and Phase 181 already learned this: commit `12f84cd` is titled "keep shell template version 4; move offlineIsland note to guides only". [VERIFIED: `git log` in candidate]

### Pattern 4: Doctor and PublishReadiness (F4)

**Doctor today does not read `:ios_host` at all** [VERIFIED: `grep ios_host lib` shows no hit in `doctor.ex`]. Add one function group modeled on `host_command_seam_findings/3` (lines ~2398+), which reads `shell_root(:ios, cwd, opts)` and builds findings through private `check/6` (`doctor.ex:2017`):
```elixir
  defp check(severity, code, check_name, message, hint, details \\ %{}) do
    %Check{severity: severity, code: code, check: check_name, message: message, hint: hint, details: details}
  end
```
Inputs: `opts[:ios_host]` (injectable declaration for tests; default `Application.get_env(:crosswake, :ios_host)`), `ios_shell_root` (existing opt), and generated outputs `CrosswakeShell/Info.plist` + `Fixtures/route_activation.json` (the managed, digest-checked origin).

Signals (D-08, any positive local signal counts, absence is never production):
`http` scheme in activation origin, `NSAppTransportSecurity` key in Info.plist, `CrosswakeOriginMode` in Info.plist, declaration `origin_mode`.
- consistent local (mode marker + ATS + http loopback origin, declaration absent or agreeing) -> `:warning` `ios_host.local_loopback_origin`, check `"ios_host_origin"`, details `%{origin: canonical, mode: "local_loopback"}` only.
- any inconsistency (D-12 list) -> `:error` `ios_host.origin_mode_mismatch`, hint "rerun mix crosswake.gen.shell ios".
- HTTPS + no signals -> no finding (paired control).
- Missing `ios_shell_root` / unreadable plist -> no *observation* (do not assert production), but a declared `origin_mode` still yields the warning from the declaration alone.

**PublishReadiness is a library-release profile, not a host profile** [VERIFIED: `lib/crosswake/doctor/publish_readiness.ex`: `publish_parity_check` requires `Keyword.get(package, :name) == "crosswake"` and reads CHANGELOG; `generator_coordinate_parity_check` reads `priv/templates/.../project.pbxproj.eex`; `contract_version_parity_check` reads `examples/ios_shell_host/...`]. It still owns the only `:ready`/`:not_ready` status (`status = if Enum.any?(checks, & &1.blocking), do: :not_ready, else: :ready`), and `Doctor.run` merges `PublishReadiness.findings/1` into the report, so any `blocking: true` check makes `report.status == :error` and `mix crosswake.doctor` raises (`Mix.raise("Crosswake doctor found blocking issues")`). Record the profile mismatch (D-12 asks for it) and still add the refusal here because it is the one existing `--check-publish` surface.

Key constraint: the committed fixture `test/fixtures/proof/phase52_publish_readiness.json` pins `"total_count":11` and the full check list. Add the new check **only when an iOS-host signal exists** (declaration present or generated-output marker found), so hosts/fixtures without it get byte-identical JSON. Use `category: :ios_host_origin` so `PublishReadiness.findings/1` sets `check: Atom.to_string(category)` = `"ios_host_origin"` automatically. De-duplicate: with `check_publish?` true emit only the `:error` finding (via PublishReadiness) and suppress the doctor-level `:warning` of the same code, so the report never carries the same code twice.

Formatter: the human report starts `"Crosswake doctor report"`, `"status: #{status}"`, and `format_support` prints `"support posture: #{status} (blocking: ...)"`. D-12 says no ready-style wording while the finding is present; add a single line right after `status:` such as `origin mode: local loopback (Simulator only; not production-ready)` driven by finding presence. JSON formatter renders findings generically; `details` stays `%{origin:, mode:}` (string keys after encode).

### Pattern 5: Proof-lane refusal at both entry points (D-10)

- `Mix.Tasks.Crosswake.Gen.ProofLane.load_host_config/1` [VERIFIED: lib/mix/tasks/crosswake.gen.proof_lane.ex:128-143] returns `{:ok, nil}` when `opts[:config]` is given and otherwise normalizes `:ios_host`. After a successful normalize, `Mix.raise("IOS-HOST-CONFIG: #{message}")` when `host_config.origin_mode != nil`.
- `Crosswake.ProofLane.Generator.normalize_host!/1` [VERIFIED: generator.ex:677-686] is called by `generate/2`, `check/2`, `diff/2` (lines 40, 105, 125; also `migrate_project_settings`). Library callers bypass the Mix task, so raise `ArgumentError` there too with the D-10 string. Current error convention is `raise ArgumentError, "invalid iOS host configuration: #{reason}"`.
- Gap to note: with `--config PATH`, the task never loads `:ios_host`, so a local-mode declaration is not seen. The refusal covers declared host configs only; record this as an accepted limit (proof-lane `--config` is documented as owning unrelated proof settings).

### Pattern 6: `inspect` has no host section (D-14 fallback)

`Mix.Tasks.Crosswake.Inspect` takes only `--format` and `--router`, builds an `OperatorInspection.Document` (routes, source line with manifest/bridge/runtime versions) and has no origin concept; its JSON is fixture-pinned (`test/fixtures/proof/phase52_operator_inspection.json`). Minimal option that satisfies LOOP-04 "inspect names the mode": in the Mix task only, after `Formatter.render(document)` for the human format, append one line when `Application.get_env(:crosswake, :ios_host)` normalizes to a config with a mode: `host origin: <canonical> (local loopback mode, Simulator only, not production-ready)`; in HTTPS mode print `host origin: <canonical>` only if a declaration exists (or print nothing to avoid noise; D-14 permits either). Do not touch `OperatorInspection.Types`, JSON output, or fixtures. If the planner prefers zero inspect change, D-14 explicitly allows recording "inspect has no host/origin section" and relying on doctor and `--check`; LOOP-04 wording ("`gen.shell --check` and inspect name the mode") argues for the one-line addition.

### Anti-Patterns to Avoid

- **Making `origin_mode` an enforced struct key:** breaks the pinned Phase 180 test literal and any caller building the struct directly.
- **Reading `Mix.env()` unguarded in library code:** crashes where Mix is absent; use the fail-closed helper.
- **Treating "no marker" as production** (D-08 and the AGENTS "absence scored as success" lesson): every detector must have a case where the plist is unreadable/missing.
- **Asserting that the production plist cannot load loopback in the Simulator:** false on iOS 26.5 (observed). Assert narrowness instead.
- **Adding `origin_mode` to activation/manifest JSON:** forbidden by D-08; also would disturb `phase52` fixtures and the Swift fixtures from Phase 181.
- **Overwriting a host-edited Info.plist:** the reconcile must refuse, never repair silently.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plist parsing in Elixir | A plist parser | Exact-string block match + presence checks for `NSAppTransportSecurity`/`CrosswakeOriginMode`/forbidden keys | Generator must run on any OS (no PlistBuddy); the template shape is fixed; `plutil -lint` can validate in the macOS-only harness |
| Atomic file replace + path safety | New atomic write code | The existing `ManagedOutputs` `atomic_replace`/`safe_layout`/`safe_read` discipline (add a sibling `read/write_origin_plist` next to `read/write_migration_project`) | Symlink/escape/pending-state hazards are already handled and tested (`ios_host_migration_security_test.exs`) |
| Loopback HTTP listener | A test framework | `python3 -I -m http.server`-style 15-line handler (used this session) or a `node:http` script | No dependency; test-owned; `-I` avoids ambient imports |
| Simulator build orchestration | New runner | Adapt `script/verify_generated_ios_shell.sh` (`emit_proof_outcome`, `-showdestinations` parsing, hermetic `GIT_CONFIG_*` redirect, `simctl boot/bootstatus/install/launch`) | Proven; already encodes unavailable/blocked outcome semantics |
| Doctor finding type | New taxonomy/banner | `Crosswake.Doctor.Check` + `PublishReadiness.ReadinessCheck` | D-12 |
| Candidate-move bookkeeping | Git wrappers | Plain `git`/`shasum`/`jq` per D-20, with manifest JSON | D-20 forbids stash/rebase/apply |

**Key insight:** every mechanism this phase needs already exists once in the repo (bounded migration of a host-owned file, tamper-evident metadata, an unavailable/blocked Simulator outcome contract). Copy the pattern; do not extend the managed-output set.

## Runtime State Inventory

> Not a rename/migration phase. Included because stale generated state is the central risk.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None - the declaration is Mix config; no datastore keys carry the mode | None - verified by reading `ios_host_config.ex`/`managed_outputs.ex` |
| Live service config | None | None |
| OS-registered state | None. The Simulator harness installs a test app (bundle id from the declaration) and may boot a device | Harness must `terminate`+`uninstall` its app, and `shutdown` only a device it booted (verified cleanup this session: `Booted` count returned to 0) |
| Secrets/env vars | None; `HEX_HOME=/private/tmp/crosswake-phase179-hex` is used by the example-host test only | None |
| Build artifacts / generated state | **An existing generated `native/ios/crosswake_shell/CrosswakeShell/Info.plist` and README survive regeneration (`:reused`)** and `.crosswake/ios_host_generation.json` records only 3 digests | Reconcile step (Pattern 3) + doctor mismatch error; tests must cover prod->local->prod round trip |

## Common Pitfalls

### Pitfall 1: Believing Info.plist is managed (the D-22 premise)
**What goes wrong:** Implementing only a template branch makes fresh generation correct but toggling silently stale; `--check` stays "current" because it never reads the plist; D-09/D-17.3 are unprovable.
**Why:** `ensure_file` is create-only; managed set is 3 files.
**How to avoid:** Pattern 3 reconcile + plist state check in `--check`/`--diff`/doctor; a round-trip test (prod -> local -> prod on the same target) is the proof.
**Warning signs:** A test that only generates into an empty dir.

### Pitfall 2: Missing `@origin_mode` assign
**What goes wrong:** `EEx` raises "assign @origin_mode not available" in `--diff` legacy path, Android templates, tests calling `render_template`.
**How to avoid:** default `origin_mode: nil` inside `render_template/5` for all templates.

### Pitfall 3: EEx whitespace changes production bytes
**What goes wrong:** A conditional on its own line leaves a blank line.
**How to avoid:** end-of-previous-line `<%= if ... do %>` form (verified identical). Golden test captured from the base commit before editing.

### Pitfall 4: Pinned-test and fixture collisions
**What goes wrong:** Enforced struct key breaks Phase 180 pins; unconditional 12th readiness check breaks `phase52_publish_readiness.json` (`total_count: 11`); editing `README.md.eex` can trip `native_evidence_drift_test.exs`; guide wording trips forbidden-claim regexes.
**How to avoid:** optional struct field; conditional readiness check; leave `README.md.eex` alone; in guide text avoid the phrases the drift test forbids: `physical-device support`, `app-store readiness`, `local-development proof`, `device evidence ... support`, `screenshot proof`, `verified Android` [VERIFIED: test/crosswake/guides/native_evidence_drift_test.exs:311-359]. Say "loopback on a physical iPhone is the phone itself" without "support".

### Pitfall 5: `MIX_ENV=prod` generation paths now refuse the mode
**What goes wrong:** `test/mix/tasks/crosswake_gen_shell_host_test.exs` runs `mix crosswake.host_probe` with `{"MIX_ENV", "prod"}` against `examples/phoenix_host`. Phase 180 (180-05 Task 1) will declare a loopback `:ios_host` there; under `MIX_ENV=prod` D-03 will refuse it. Phase 180 must generate under `dev`/`test` (the harness in this research used `MIX_ENV=test`). Flag this in the 182 guide paragraph and the move record (`gate_rerun_required`), not as a 182 code change (D-19: 182 does not touch `examples/phoenix_host/**`).

### Pitfall 6: URI.parse leniency
`URI.parse("http://127.0.0.1:80:80")` returns host `127.0.0.1`, port 80, no error (see table). Keep the raw-authority split + `\A[0-9]+\z` port regex; never rely on `uri.port`.

### Pitfall 7: Swift package pin fingerprint mismatch in the harness
Re-tagging a hermetic clone with the same tag as a real release (`0.2.11`, `v0.2.11`) fails with "Revision ... does not match previously recorded value" because SwiftPM records tag fingerprints per URL. Observed this session. Use a tag no real release can have and that satisfies `upToNextMajorVersion` from `0.2.11` (the generated pbxproj requirement), e.g. `0.9.99` (0.x `upToNextMajor` accepts `<1.0.0`; `0.2.99` was proven to resolve). The existing `CROSSWAKE_IOS_USE_LOCAL_CORE=1` branch of `verify_generated_ios_shell.sh` uses the exact minimum version tag and may hit this on a machine that previously fetched the real tag; the new harness should not copy that detail.

### Pitfall 8: Legacy (no `:ios_host`) generated project does not build
`mix crosswake.gen.shell ios --local` without a declaration writes a pbxproj that references `CrosswakeHostSettings.xcconfig` which only the declared path publishes: `xcodebuild` errored "Unable to open base configuration reference file ... CrosswakeHostSettings.xcconfig". The harness must generate through the declared path (`MIX_ENV=test mix run --no-start` with `Application.put_env(:crosswake, :ios_host, ...)` then `Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", dir])`, verified).

### Pitfall 9: Simulator observation races
`simctl launch` returns before the page loads; poll (listener log + app result file) with a bounded timeout rather than a fixed sleep; truncate shared log files with care (a log truncated while the writer holds an offset becomes sparse and `grep` treats it as binary; use `grep -a`).

## Code Examples

### Verified: production `http` today is rejected, but render accepts it
Running (scratch copy of the candidate, `MIX_ENV=test`):
`IOSHostConfig.normalize(%{... origin: "http://127.0.0.1:4790" ...})` returned
`{:error, "invalid origin; use an absolute HTTPS origin without credentials, path, query, or fragment"}`;
`IOSHostGeneration.render(%IOSHostConfig{origin: "http://127.0.0.1:4790", ...})` returned activation origin `"http://127.0.0.1:4790"`, url `"http://127.0.0.1:4790/study-session"`, manifest `host.origin` `"http://127.0.0.1:4790"` and `allowlisted_origins` `["http://127.0.0.1:4790"]`. Consequence: `render/2` trusts its struct, so add defense-in-depth (refuse `http` origin unless `origin_mode == :local_loopback`) and rely on doctor's "http origin without marker" error for hand-built configs.

### Simulator harness skeleton (all pieces proven this session)
```bash
# 0. preconditions -> emit {"outcome":"unavailable"|"blocked"|"passed","rule_id":"LOOP-IOS-...","scope":"..."} like verify_generated_ios_shell.sh
command -v xcodebuild xcrun python3 >/dev/null || { emit unavailable; exit 3; }
# 1. listener first (port 0), read the bound port, keep it running; log requests (GET path)
# 2. generate with origin http://127.0.0.1:$PORT through the declared path (MIX_ENV=test mix run --no-start gen.exs)
# 3. test-owned replacement of host-owned CrosswakeShell/CrosswakeShellApp.swift (WKWebView, reads Fixtures/route_activation.json "url",
#    optional SIMCTL_CHILD_PROBE_URL override, writes NSTemporaryDirectory()+"result.txt" on didFinish / didFailProvisional (domain+code))
# 4. hermetic core: cp -R packages/crosswake-shell-core-ios -> tmp git repo, tag 0.9.99 and v0.9.99,
#    export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.<tmp>.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/szTheory/crosswake-shell-core-ios.git"
xcodebuild build -project .../CrosswakeShell.xcodeproj -scheme CrosswakeShell \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath $RUN/dd -clonedSourcePackagesDirPath $RUN/spm CODE_SIGNING_ALLOWED=NO
# 5. assert on the BUILT bundle: plutil -p $APP/Info.plist -> NSAppTransportSecurity keys == [NSAllowsLocalNetworking]; CrosswakeOriginMode == local_loopback
# 6. simctl boot (note if it was already booted) / bootstatus -b / install / launch; poll
#    PASS A: listener saw GET /<entry path> AND GET /__loaded (page JS ping) AND result.txt == didFinish
#    PASS B (narrowness): relaunch with SIMCTL_CHILD_PROBE_URL=http://example.com/ -> result.txt "didFailProvisional NSURLErrorDomain -1022", listener saw nothing
#    OBSERVATION only (never an assertion): loopback load result with the ATS block removed
# 7. cleanup: terminate, uninstall, kill listener, shutdown only a device this run booted
```
Observed result this session (iPhone 17, iOS 26.5 sim): generated-and-patched app bundle Info.plist printed `CrosswakeOriginMode => local_loopback` and `NSAppTransportSecurity => { NSAllowsLocalNetworking => true }`; listener saw `HIT /study-session` and `HIT /__loaded`; app wrote `didFinish`. Control: a standalone probe app loaded `http://127.0.0.1:47901/` and `http://localhost:47901/` with `didFinish` both with and without the ATS dict; `http://example.com/` gave `didFailProvisional NSURLErrorDomain -1022` with and without it; the Mac's LAN IP also loaded without any exception. Record the runtime, Xcode and device identifiers in the harness output; the result is for one runtime and says nothing about a physical device.

Build timing observed: ~11-16 s for a warm package cache (generated project, hermetic local package, `CODE_SIGNING_ALLOWED=NO`); cold SPM resolution adds more.

### Candidate-move precheck (reuse Phase 181 `<automated>` style)
```bash
P=<home>/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host
C180=/private/tmp/crosswake-phase180-impl; C182=/private/tmp/crosswake-phase182-impl
test "$(git -C $C180 rev-parse HEAD)" = 12f84cd950d4574921767df823faed6797c17c26
git -C $C182 diff --name-only 12f84cd950d4574921767df823faed6797c17c26..HEAD | sort > "$S/core_paths"
git -C $C180 status --porcelain | cut -c4- | sort > "$S/dirty_paths"
test -z "$(comm -12 "$S/core_paths" "$S/dirty_paths")"      # overlap empty (also catches untracked-vs-added collisions)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ATS `NSExceptionDomains` localhost + `NSExceptionAllowsInsecureHTTPLoads` (prior art in `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist`) | `NSAllowsLocalNetworking` only | iOS 10+/iOS 17 docs | D-06 forbids `NSExceptionDomains`; the repo's hand-owned `Info-Dev.plist` example stays untouched and is covered by a different test (`native_dev_wiring_test.exs`) |
| IP addresses allowed by default (iOS 10-16) | iOS 17+ "ATS no longer allows connections to IP addresses by default" | iOS 17 | Documented; but WKWebView on iOS 26.5 Simulator loaded IP literals without an exception (observed) |

**Deprecated/outdated:** none relevant.

## Apple ATS facts (primary sources)

Fetched from Apple's DocC JSON endpoints (the HTML pages are JS-rendered and returned only titles):
- `NSAllowsLocalNetworking` [CITED: developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking]: "The key controls whether App Transport Security (ATS) allows your app to connect to unqualified domains, .local domains, and IP addresses using IPv4 or IPv6." (the abstract-tag glyphs for `.local` were stripped in extraction; the sentence lists three categories) "In iOS 17, iPadOS 17, and macOS 14, ATS no longer allows connections to IP addresses by default. Add individual IP addresses and classless inter-domain routing (CIDR) ranges in the [NSExceptionDomains] dictionary." and "While ATS doesn't block local loads by default in newer versions of the OS, consider setting [NSAllowsLocalNetworking] to [YES] as a declaration of intent, if appropriate, even if you don't support older OS versions."
- `NSAppTransportSecurity` [CITED: developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity]: lists "Allow insecure loads for web views while maintaining ATS protections elsewhere in your app using the [NSAllowsArbitraryLoadsInWebContent] key", which implies web content is subject to ATS.
- Preventing Insecure Network Connections [CITED: developer.apple.com/documentation/security/preventing-insecure-network-connections]: "ATS doesn't apply to calls your app makes to lower-level networking interfaces".
- The documentation does not say whether `127.0.0.1`/`localhost` in a WKWebView is covered with no exception. The D-17.7 observation answers it for iOS 26.5 Simulator only (loopback loads without the key; unrelated `http://` hosts stay blocked). The Apple Developer Forums thread on Local Network privacy (CONTEXT canonical ref) was not re-fetched; D-06's "loopback exempt from Local Network privacy prompt" is [ASSUMED] from CONTEXT (not re-verified here); the Simulator showed no permission prompt for loopback.

## Golden / byte-identity approach (D-06, D-17.2)

No Info.plist golden exists today. Existing related tests: `crosswake_gen_shell_stamp_test.exs` (stamp presence only) and `native_dev_wiring_test.exs` (hand-owned example plist has no ATS keys / `localhost` token; it reads `examples/ios_shell_host/CrosswakeShell/Info.plist`, which Phase 182 does not touch). Recommended:
1. **Task 1 of the first plan, before any template edit:** render the BASE `Info.plist.eex` with fixed assigns (`version: "GOLDEN"`, `template_version: 4`, `capabilities: []`, `local: false`, `cutout_mode: false`, package path assigns) and commit the bytes as `test/fixtures/shell/ios/Info.plist.production.golden` together with its `shasum -a 256` recorded in the plan summary (same hash must be re-derivable with `git show 12f84cd:priv/templates/crosswake/shell/ios/Info.plist.eex`).
2. Unit test: render the NEW template with `origin_mode: nil` and compare to the golden; render with `:local_loopback` and assert (a) `String.replace(local, block, "") == golden`-equivalent via the exact insertion point, (b) ATS key set equals `["NSAllowsLocalNetworking"]` by extracting keys between `<key>NSAppTransportSecurity</key><dict>` and its `</dict>`, (c) none of `NSAllowsArbitraryLoads`, `NSAllowsArbitraryLoadsInWebContent`, `NSAllowsArbitraryLoadsForMedia`, `NSExceptionDomains` appear in either mode, (d) the new template with `origin_mode: nil` is byte-equal to the base template rendered with the same assigns (also assert in the verification command via `git show`).
3. End-to-end: generate with a declaration lacking `origin_mode` and compare the written `Info.plist` to the golden after normalizing only the version line.
Also keep the whole-generated-tree production comparison: generate before/after the phase for the same declaration and `diff -r` (excluding `.crosswake/shell.json` `generated_at`), proving no other file changed.

## Pinned Phase 180 files and the 21 dirty paths (D-19/D-20)

`/private/tmp/crosswake-phase180-impl` HEAD `12f84cd950d4574921767df823faed6797c17c26` (read-only `rev-parse`/`status` only). [VERIFIED this session]
Pins re-hashed (match CONTEXT prefixes/suffixes):
- `test/crosswake/proof/phase180_twin_feasibility_test.exs` `01df82646c3365b159006c26ec818a55feafd506f007d762d739f66177e756f5`
- `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs` `f7b968909db85040adfd42bc397fec8f70259fa2b7bd3176759b523a9b8aaa19`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift` `a3bcef6ea7f64f90b2e85f6aecc04778334428f709f840c134b7c0ea25355672`

The 21 porcelain paths (8 modified, 13 untracked):
```
 M examples/phoenix_host/e2e/offline_sync.spec.ts
 M examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex
 M examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
 M examples/phoenix_host/lib/crosswake_example/router.ex
 M examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex
 M examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
 M examples/phoenix_host/priv/static/offline_study.js
 M examples/phoenix_host/test/crosswake_example/page_title_test.exs
?? examples/phoenix_host/e2e/offline_accessibility.spec.ts
?? examples/phoenix_host/e2e/offline_recovery.spec.ts
?? examples/phoenix_host/lib/crosswake_example/e2e/twin_fault_controller.ex
?? examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/review.html.heex
?? examples/phoenix_host/test/crosswake_example/e2e/twin_fault_controller_test.exs
?? examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs
?? lib/crosswake/proof_lane/twin_receipt.ex
?? lib/crosswake/proof_lane/twin_runtime.ex
?? lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
?? packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift
?? test/crosswake/proof/phase180_twin_feasibility_test.exs
?? test/crosswake/proof_lane/twin_receipt_test.exs
?? test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
```
Planned 182 change set (above structure) has **no path overlap**. Name-collision cautions for NEW files: do not create anything named `twin_*`, `*verify_twin*`, `phase180_*`, and create nothing under `examples/phoenix_host/**` (checkout would abort with "untracked working tree files would be overwritten" for an added-vs-untracked collision, which is the safe failure but would burn the move). The 180 dirty files do not mention `IOSHost`, `ios_host`, `ManagedOutputs` or `Doctor` (grepped), so the move should compile against the new head; the pinned Phase 180 example test constructs `%IOSHostConfig{}` with six keys, which stays valid only while `:origin_mode` is optional. `git checkout --detach` keeps local modifications for files identical between the two commits, which holds for every dirty tracked path because 182 does not touch them; after the move `git diff --binary HEAD` is expected to hash identically.

## Existing tests to extend and commands

Run from the 182 clone `/private/tmp/crosswake-phase182-impl` (after it exists). Quick suite verified this session in a scratch copy (231 tests passed in 7.7 s; 2 failures were artifacts of the copy lacking `.git` and `examples/`, not real):
```bash
MIX_ENV=test mix test test/crosswake/shell/ios_host_config_test.exs test/crosswake/shell/managed_outputs_test.exs \
  test/crosswake/doctor test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/support_matrix \
  test/crosswake/capability_map test/mix/tasks/crosswake_inspect_test.exs --seed 0
```
| File | Extend for | Pattern to copy |
|------|-----------|-----------------|
| `test/crosswake/shell/ios_host_config_test.exs` (`async: true`, `@valid` map with `https://study.crosswake.test`) | LOOP-01/02 validator matrix, prod env via `env: :prod`, struct default | existing `canonicalizes valid authorities` test |
| `test/crosswake/shell/ios_host_generation_host_commands_test.exs` | origin passthrough, defense-in-depth refusal | |
| `test/mix/tasks/crosswake_gen_shell_host_commands_test.exs` (`Application.put_env(:crosswake, :ios_host, ...)` with restore, `async: false`) | NEW file `crosswake_gen_shell_origin_mode_test.exs`: generate local, plist assertions, `--check` current + mode line, toggle round trip, host-edited plist refusal, README banner | its setup/restore block (lines 7-12) |
| `test/mix/tasks/crosswake_gen_shell_stamp_test.exs` | confirm the stamp still holds in both modes | |
| `test/mix/tasks/crosswake_gen_proof_lane_test.exs` (uses `IOSHostConfig.normalize` at lines 75/141/537) | refusal in task and `Generator.generate/check/diff` | |
| `test/crosswake/doctor/doctor_host_commands_test.exs` (`Doctor.run(route_source:, install_manifest_path:, cwd:, ios_shell_root:)`, tmp-dir fixtures, `@allowed_detail_keys` leak guard) | NEW `doctor_origin_mode_test.exs` with the same helper style and an allowed-keys leak assertion (`[:origin, :mode]` only) | |
| `test/fixtures/proof/phase52_publish_readiness.json` consumer test (`grep phase52_publish_readiness test`) | assert still byte-identical with no iOS-host signal | |
| `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/capability_map/renderer_test.exs`, `test/mix/tasks/crosswake.docs.sync_test.exs` | renderer strings; capability-map guide is asserted byte-identical to renderer output (`capability_map/renderer_test.exs:36-39`). Regenerate guides with `mix crosswake.docs.sync` (Docs.Sync task) | |
| `test/crosswake/guides/native_evidence_drift_test.exs`, `native_shell_upgrade_test.exs`, `release_boundaries_test.exs` | guide wording safety (Pitfall 4) | |
| `test/mix/tasks/crosswake_inspect_test.exs` | the one trailing line, JSON unchanged | |

Swift: no Swift change is expected (D-07). `swift test` stays available for a regression run: `cd packages/crosswake-shell-core-ios && swift test` (Phase 181 acceptance used `grep -Eq 'Executed [1-9][0-9]* tests?, with 0 failures'`). `URL.crosswakeOrigin` already handles `http` and non-default ports [VERIFIED: ActivationCoordinator.swift:830-851, quoted: `case "https": return 443`, `case "http": return 80`], and `grep` of `Sources` finds no `https`-only guard except an unrelated diagnostics URL, so no Swift edit is needed for D-07 (the generated activation passed the real WKWebView in the harness).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reconcile (bounded rewrite of exactly the Crosswake block in a host-owned Info.plist) is the right way to satisfy D-09 given Info.plist is scaffold-once | Pattern 3 | If the user wants Info.plist fully managed, scope grows (metadata migration); confirm before planning (Open Question 1) |
| A2 | Rejecting Info.plist as a 4th managed output (metadata/`map_size == 3` breakage) is acceptable | Alternatives | Low; code evidence is direct |
| A3 | `current_env/0` returning `:prod` when Mix is absent is the desired fail-closed default | Pattern 1 | Low |
| A4 | Adding a conditional PublishReadiness check, omitted when no iOS-host signal exists, keeps `phase52_publish_readiness.json` byte-identical | Pattern 4 | If another test calls `PublishReadiness.run` with a host fixture that has a declaration, the check appears; verify by running the fixture test |
| A5 | Human-format-only trailing line in `mix crosswake.inspect` is "minimal" enough for D-14 | Pattern 6 | If reviewers insist on inspect JSON, fixtures change |
| A6 | Loopback is exempt from the Local Network privacy prompt (CONTEXT D-06) | ATS facts | No prompt appeared in the Simulator; physical-device behavior is out of scope and unverified |
| A7 | The Simulator observation (loopback loads without ATS dict) generalizes beyond iOS 26.5 Simulator | Summary | The harness must not hardcode that expectation; record runtime in output |
| A8 | `0.9.99` is a safe hermetic tag (satisfies `upToNextMajorVersion` from 0.2.11 and cannot collide with a real release) | Pitfall 7 | If SwiftPM treats 0.x `upToNextMajor` differently, use the proven `0.2.99` |

## Open Questions (RESOLVED)

1. **Info.plist ownership (needs explicit acknowledgment in the plan).** — RESOLVED: CONTEXT D-23 (bounded reconcile, not a 4th managed output); implemented by 182-02.
   - Known: CONTEXT D-06/D-22 call Info.plist managed; source shows scaffold-once, 3 managed paths, docs say host-owned.
   - Unclear: whether the user intends a bounded reconcile (this research's recommendation) or fully managed.
   - Recommendation: plan the reconcile (Pattern 3), state the correction in the plan's context section and in the final handoff, and make a host-edited ATS block a fail-closed `blocked` rather than an overwrite.

2. **Where does doctor get "the declaration" in `MIX_ENV=prod` runs?** — RESOLVED: 182-03 raw-declaration rule (`ios_host.origin_mode_mismatch` `:error` when normalize refuses a declaration carrying `origin_mode`).
   - Known: normalize will refuse the mode under prod.
   - Unclear: should doctor surface that refusal as a finding?
   - Recommendation: if `normalize` fails and the raw declaration has an `origin_mode` key, emit `ios_host.origin_mode_mismatch` (`:error`) with the safe reason string; otherwise ignore declaration problems (existing gen.shell already raises them).

3. **README banner lifecycle.** — RESOLVED: create-once banner, never a signal (D-08.3, D-23; 182-02); guide documents the stale-banner case (182-04). Scaffold-once README can keep a stale banner. Recommendation: banner at creation only, never used as a signal; optionally extend the same exact-line reconcile. Low value; the Info.plist marker is the signal.

4. **Mode recorded in managed metadata (D-08.2).** — RESOLVED: no metadata change; activation origin is the managed signal (D-08.2 as corrected, D-23). Metadata is digest-only. Recommendation: treat the managed `Fixtures/route_activation.json` origin (digest-tracked, necessarily `http` when the mode is on because the validator forces it) as the managed positive signal; do not extend `.crosswake/ios_host_generation.json`. If the user wants an explicit field, it must be added in `metadata_for/2` AND the recovery equality checks (`m == s["metadata"]`).

5. **`gen.proof_lane --config`** — RESOLVED (plan revision): the `--config` branch also reads `Application.get_env(:crosswake, :ios_host)` and refuses local mode with the D-10 string (182-04). Original note: skips `:ios_host`; the refusal does not see a local-mode declaration there. Accept and document.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Erlang (asdf) | all ExUnit | yes | 1.19.5 / OTP 27 | none (blocking) |
| Node (asdf) | existing `.mjs` checkers, optional listener | yes | 22.14.0 per `.tool-versions` | Python listener |
| Python 3 | listener | yes | 3.14.4 | Node listener |
| Xcode / `xcodebuild` | harness build | yes | 26.6 (17F113) | blocked, not passed |
| iOS Simulator runtime + devices | harness launch | yes | iOS 26.5 (23F77); iPhone 17 `A6732296-F8FF-4DDC-9ACE-7AEFE685CCC9`, iPhone 17 Pro, others, all Shutdown at start | blocked, not passed |
| SwiftPM | `swift test` regression | yes (`/usr/bin/swift`) | Xcode 26.6 toolchain | n/a (no Swift change planned) |
| `git`, `shasum`, `jq` | candidate move, manifests | yes (jq used by Phase 181 plans) | system | none |
| Network (GitHub for SwiftPM) | harness | not needed | the hermetic `insteadOf` redirect removes it | n/a |

**Missing dependencies with no fallback:** none. The harness must still treat a missing Simulator or toolchain as `blocked`, never `passed` (D-17.7).

## Validation Architecture

> `workflow.nyquist_validation` was not checked as false (config not modified by this research); included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5/OTP 27) for LOOP-01..04; shell harness script for the Simulator check; `jq`/`git` assertions for LOOP-05 |
| Config file | `mix.exs`; `test/test_helper.exs` |
| Quick run command | `cd /private/tmp/crosswake-phase182-impl && MIX_ENV=test mix test test/crosswake/shell test/crosswake/doctor test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/support_matrix test/crosswake/capability_map test/crosswake/guides test/mix/tasks/crosswake_inspect_test.exs test/mix/tasks/crosswake.docs.sync_test.exs --seed 0` |
| Full suite command | `MIX_ENV=test mix test --seed 0` (root) plus `bash script/verify_loopback_origin_simulator.sh` (macOS only, phase evidence, not CI) and, because Swift is untouched, `cd packages/crosswake-shell-core-ios && swift test` only as an optional regression |
| Estimated runtime | quick ~10-20 s; harness ~1-3 min warm |

Capture to a file and test `$?` then grep (Phase 181 rule; never pipe a gate into `tail`): `L=$(mktemp); ... mix test ... >"$L" 2>&1 && grep -Eq '(^|[^0-9])[1-9][0-9]* tests?, 0 failures' "$L"`.

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOOP-01 | no mode + `http` origin denied with D-05 hint; unknown mode value denied; `https` under mode denied; mode under `env: :prod` denied; absent `Mix` -> prod; key set = six + optional; unknown key still denied; struct literal without `origin_mode` still builds | unit | `MIX_ENV=test mix test test/crosswake/shell/ios_host_config_test.exs --seed 0` | extend existing |
| LOOP-02 | accepted: `http://127.0.0.1`, `:4790`, `http://localhost`, `HTTP://LOCALHOST:80` -> `http://localhost`, `127.0.0.1:04790` -> `:4790`; denied table: `[::1]`, `[::1]:80`, `0.0.0.0`, `127.0.0.2`, `127.1`, `2130706433`, `192.168.1.100`, `10.0.0.1`, `study.local`, `127.0.0.1.evil.com`, `localhost@evil.com`, `user:pw@127.0.0.1`, `localhost.`, `:0`, `:65536`, `:`, `:80:80`, path `/`, `?x=1`, `#f`, trailing `\n`; errors never echo the supplied origin; no localhost<->127.0.0.1 rewrite | unit (table-driven) | same file | extend |
| LOOP-03 | production Info.plist == golden; local Info.plist ATS key set == `[NSAllowsLocalNetworking]` + marker; forbidden keys absent in both; fresh `gen.shell ios` writes each; round trip prod->local->prod leaves no ATS/marker; host-edited ATS dict -> blocked, file unchanged; `--check` current after generation and prints the D-13 line only in local mode; mode toggle without regenerate -> `blocked; cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios`; production tree otherwise unchanged | unit + task integration | `MIX_ENV=test mix test test/crosswake/shell/ios_host_origin_mode_test.exs test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs test/mix/tasks/crosswake_gen_shell_stamp_test.exs --seed 0` | Wave 0 |
| LOOP-03 | Simulator: built bundle plist asserted; listener saw entry GET + JS ping; app `didFinish`; `http://example.com/` still `-1022`; Simulator absent -> `blocked` | harness | `bash script/verify_loopback_origin_simulator.sh` -> JSON outcome `passed` | Wave 0 |
| LOOP-04 | local fixture -> exactly one `:warning` `ios_host.local_loopback_origin`, check `ios_host_origin`, details keys exactly `[:mode, :origin]`; HTTPS fixture -> code absent; `--check-publish` local -> `:error`, status `:not_ready`, no duplicate code, Mix task raises; HTTPS -> ready; plist/origin mismatch cases -> `:error` `ios_host.origin_mode_mismatch`; unreadable plist is not treated as production; leak guard (no entry URL, bundle id, team id, signing, path); proof lane task and `Generator.generate/check/diff` refuse with the D-10 string; inspect trailing line; renderers/guides byte-identical after `mix crosswake.docs.sync`; no `NSAllowsArbitraryLoads` in new guide text | unit + task + docs drift | quick run command above | Wave 0 (doctor, origin-mode), extend (proof lane, renderers) |
| LOOP-05 | `182-CANDIDATE-MOVE.json` schema `crosswake.phase182.candidate_move/1`; `overlap == []`; new_head == 180 clone HEAD; new_tree equal; `carried_paths[*].sha256_before == sha256_after` and modes equal; `binary_diff_sha256_before == after`; 3 pins unchanged; `gate_rerun_required == true`; result `moved`/`blocked` | script (`jq -e`, `git rev-parse`, `shasum`) | `jq -e` over the JSON plus `git -C $C180 rev-parse HEAD`/`HEAD^{tree}`/`status --porcelain` comparisons | Wave 0 |

### Sampling Rate
- **Per task commit (in the 182 clone):** the matching quick subset (single test file where possible).
- **Per wave merge:** quick run command above.
- **Phase gate:** full `mix test --seed 0` in the 182 clone, the harness `passed`, the byte-identity golden, `git diff --name-only 12f84cd..HEAD` overlap check, then the move.

### Wave 0 Gaps
- [ ] `test/fixtures/shell/ios/Info.plist.production.golden` - captured from base BEFORE editing the template
- [ ] `test/crosswake/shell/ios_host_origin_mode_test.exs` - pure module (block, inspect, reconcile, forbidden keys)
- [ ] `test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs` - generation, `--check`, toggle round trip, README banner, host-edit refusal
- [ ] `test/crosswake/doctor/doctor_origin_mode_test.exs` - findings, paired control, publish, leak guard
- [ ] `script/verify_loopback_origin_simulator.sh` (+ listener) - D-17.7 harness with `passed|blocked|unavailable` JSON
- [ ] candidate-move verification script/commands (kept in phase evidence, not CI)
- [ ] Framework install: none

## Security Domain

> `security_enforcement` not disabled; ASVS Level 1. The phase adds a deliberately weaker transport posture (cleartext loopback) behind an explicit switch, so the threat model is mainly about the switch not leaking.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Single validated declaration; ATS is backstop, Crosswake allowlist is the boundary |
| V2/V3 Authentication/Session | no | Not touched; activation grants no session/replay authority (guides already say so) |
| V4 Access Control | no | Not touched |
| V5 Input Validation | yes | Exact-match allowlist after structural parse, raw-authority cross-check, no echo of supplied input |
| V6 Cryptography | no | Not touched (no new crypto; sha256 via existing helpers) |
| V7 Error handling/logging | yes | Print only canonical `scheme://host:port`; no entry URL, team, bundle ids, tokens |
| V14 Configuration | yes | Prod refusal, byte-identical prod plist, no ATS wildcards, stale-state detection |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Allowlist bypass `http://127.0.0.1.evil.com` | Spoofing | exact host equality (`URI.parse` host = `"127.0.0.1.evil.com"`, not in allowlist) |
| `http://localhost@evil.com`, `http://127.0.0.1@evil.com` | Spoofing | `userinfo` non-nil rejects; also host is `evil.com` |
| `http://user:pw@127.0.0.1` credentials | Info disclosure | reject any userinfo |
| Case: `HTTP://LocalHost:80` | Tampering | downcase host/scheme; canonical `http://localhost` (matches existing HTTPS behavior) |
| Trailing dot `http://localhost.` / `%2e` encodings | Spoofing | exact match; `host="localhost."`, `"localhost%2e"` not allowed |
| IPv6 `[::1]` (URI host `"::1"`), `[::1]:80` | Spoofing | not in allowlist; also raw-authority split mismatch |
| `0.0.0.0`, `127.0.0.2`, `127.1`, `2130706433`, LAN IPs, `.local` | Spoofing/EoP | exact allowlist only |
| Lenient parse `http://127.0.0.1:80:80` (`URI.parse` accepts) | Tampering | raw-authority port regex `\A[0-9]+\z` over the part after the first `:` |
| Ports `:0`, `:65536`, `:`, `:abc` | Tampering | existing 1..65535 decimal check (note `URI.parse("...:")` yields port 80, so check the raw authority) |
| Trailing newline/space in origin (`"http://127.0.0.1\n"` parses host with `\n`) | Tampering | exact match fails; keep `\z` anchors |
| Mode leaking into production (`MIX_ENV=prod`, shared `config.exs`) | EoP | refuse under prod, fail closed when Mix absent; doc says dev/runner-owned config only |
| Stale ATS exception after switching back to HTTPS | Tampering/Info disclosure | reconcile removes exact block; refuse on unknown ATS shape; doctor `ios_host.origin_mode_mismatch` error on HTTPS + ATS/marker; production readiness refuses local signals |
| Hand-built config with `http` origin and no mode | Tampering | `render/2` defense-in-depth refusal; doctor error "http origin without marker" |
| ATS widening | EoP | tests assert the ATS key set equals `[NSAllowsLocalNetworking]` and absence of `NSAllowsArbitraryLoads*`/`NSExceptionDomains`; the harness narrowness control (`example.com` -> -1022) proves it behaviorally |
| Loopback origin on a physical iPhone (phone itself) | Spoofing/DoS | proof lane refuses; doctor message states it; mode is Simulator-only |
| Diagnostic leakage | Info disclosure | details restricted to `[:origin, :mode]`; assert allowed-keys like `doctor_host_commands_test.exs` `@allowed_detail_keys` |
| ATS gives no protection against LAN `http` in WKWebView on iOS 26.5 Simulator (LAN IP loaded with no exception) | Spoofing | Crosswake's allowlist/same-origin policy is the only fence (reinforces D-07); do not document ATS as the boundary |

Verified `URI.parse` outputs behind these rows were produced this session by running the strings in Elixir 1.19.5 (for example `"http://127.0.0.1:80:80" -> host="127.0.0.1" port=80`, `"http://127.0.0.1:" -> port=80`, `"http://127.0.0.1\n" -> host="127.0.0.1\n"`, `"http://[::1]:4790" -> host="::1" port=4790`, `"http://localhost@evil.com" -> host="evil.com" userinfo="localhost"`).

## Sources

### Primary (HIGH confidence)
- Candidate source at `/private/tmp/crosswake-phase181-impl` (HEAD `12f84cd`): `lib/crosswake/shell/ios_host_config.ex`, `ios_host_generation.ex`, `managed_outputs.ex`, `ios_host_project_migration.ex`; `lib/mix/tasks/crosswake.gen.shell.ex`, `crosswake.gen.proof_lane.ex`, `crosswake.doctor.ex`, `crosswake.inspect.ex`; `lib/crosswake/proof_lane/generator.ex`; `lib/crosswake/doctor/{doctor,check,publish_readiness,formatter,finding_policy}.ex`; `priv/templates/crosswake/shell/ios/*`; `script/verify_generated_ios_shell.sh`; relevant tests listed above.
- Experiments this session: template byte-identity render; `URI.parse` table; `IOSHostConfig`/`render` http probe; generated declared-path project -> patched -> `xcodebuild` -> Simulator launch with listener; standalone WKWebView ATS probe with controls.
- Apple DocC JSON for `NSAllowsLocalNetworking`, `NSAppTransportSecurity`, Preventing Insecure Network Connections (URLs under developer.apple.com/documentation/...).
- `/private/tmp/crosswake-phase180-impl` read-only `rev-parse`, `status --porcelain`, `shasum`.
- `.planning/workstreams/quality-ratchet-release/{REQUIREMENTS,ROADMAP,STATE}.md`, `182-CONTEXT.md`, Phase 181 `181-VALIDATION.md` and PLAN `<automated>` blocks.

### Secondary (MEDIUM confidence)
- git-checkout(1) behavior for carried local modifications (CONTEXT canonical ref; semantic relied on, not re-fetched).

### Tertiary (LOW confidence)
- Apple Developer Forums loopback/Local Network claim (CONTEXT; not re-fetched).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependency; toolchain read directly.
- Architecture: HIGH for shapes (all read) and Info.plist ownership finding (code + test + docs agree); MEDIUM for the recommended reconcile design (new code).
- Pitfalls: HIGH - most reproduced this session.
- Apple ATS semantics: MEDIUM - docs ambiguous; single-runtime observation.

**Research date:** 2026-10-14
**Valid until:** 2026-11-13 (30 days; the harness result depends on the installed Xcode/runtime and should be re-observed if either changes)
