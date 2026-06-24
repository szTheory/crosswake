# Phase 126: Additive Native Dev Wiring - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Give the checked-in iOS (`examples/ios_shell_host`, `CrosswakeShell`) and Android
(`examples/android_shell_host`, `dev.crosswake.shell`) example hosts a **strictly
additive** dev path that loads Crosswake routes from the local shared backend
(Phase 125's Docker/`mix phx.server` on port **4700**) — iOS simulator via
`http://localhost:4700`, Android emulator via `http://10.0.2.2:4700` (host loopback).

**The hard invariant:** the checked-in public-coordinate **proof** fixtures and posture
MUST stay byte-untouched — iOS `Info.plist` + `Fixtures/route_activation.json`,
Android `app/src/main/AndroidManifest.xml` + `app/src/main/assets/*.json`. These are
contract-generated proof artifacts other tests depend on. The dev path is a parallel
overlay (Dev scheme / `dev` flavor), never a mutation.

**Requirements:** NDEV-01, NDEV-02, NDEV-03 (see REQUIREMENTS.md — locked).

**NOT in this phase:** launch orchestration / `bin/see-it-run.sh` / ASCII banner
(Phase 127); three-runtime screenshots, screen recording, full `guides/see_it_run.md`,
README routing, `see_it_run_test.exs` (Phase 128). Phase 126 surfaces only the minimal
copy-paste launch commands in `examples/QUICK_START.md`.

**Method:** all four gray areas were researched by parallel subagents (iOS mechanism,
Android mechanism, dev-fixture generation, proof-posture guard + docs) covering
idiom/tradeoffs/cross-ecosystem lessons (Hotwire Native, Flutter flavors, RN, Capacitor,
Expo), synthesized into the one coherent, mutually-reinforcing decision set below.
Confidence: high on all four. Cross-area conflicts were resolved (noted inline).
</domain>

<decisions>
## Implementation Decisions

### iOS — additive `Dev` scheme via a `Debug-Dev` build configuration
- **D-01 (mechanism):** Use a **single app target + a new `Debug-Dev` build configuration
  + a shared `Dev` scheme**. Reject a second app target (doubles pbxproj, every new
  source file must be added twice, violates minimal-footprint OSS-DNA) and reject
  `#if DEBUG` (ATS / `WKAppBoundDomains` are plist keys, not Swift — structurally
  cannot be conditionalized in code; the fixture is a bundle resource). This is the
  Flutter-flavors idiom and keeps the prod target byte-identical.
- **D-02 (scheme + config naming):** Scheme is named **`Dev`** (matches ROADMAP success
  criterion "select the `Dev` scheme in Xcode"); its Launch + Test actions point at the
  **`Debug-Dev`** configuration. Use a hyphen (`Debug-Dev`, not `Debug Dev`) so the
  `xcodebuild -configuration Debug-Dev` CLI needs no quoting. The `.xcscheme` is a
  self-contained shared file (no pbxproj entry needed); it references the existing
  target UUID.
- **D-03 (`Info-Dev.plist`):** `Debug-Dev` sets `INFOPLIST_FILE = CrosswakeShell/Info-Dev.plist`
  (explicit in the Debug-Dev `XCBuildConfiguration`; optionally grouped via a
  `Configs/Dev.xcconfig` `baseConfigurationReference` — Claude's discretion).
  `Info-Dev.plist` is a copy of the prod `Info.plist` plus exactly: ATS
  `NSAppTransportSecurity → NSExceptionDomains → localhost → NSExceptionAllowsInsecureHTTPLoads=true`;
  `WKAppBoundDomains` gains `localhost` (keep `example.com`); `CFBundleDisplayName = "CrosswakeShell Dev"`.
  **Footguns (from research):** `NSAllowsLocalNetworking` alone does NOT permit `http://`
  cleartext (only relaxes cert-trust) — the explicit `localhost` exception is required;
  `127.0.0.1` cannot be used as an `NSExceptionDomains` key (must be the hostname
  `localhost`); if `limitsNavigationsToAppBoundDomains` is on, `WKAppBoundDomains` MUST
  include `localhost` or WebKit silently refuses navigation. The prod `Info.plist` must
  contain none of these keys (guarded — see D-14).
- **D-04 (dev fixture bundling — no library change):** The iOS core (`CrosswakeShellCore`
  `ActivationCoordinator.bundled`) loads a **hardcoded** resource name `route_activation.json`
  from the app bundle. So the Dev build keeps a *parallel sibling* `Fixtures/route_activation-dev.json`
  and a **Run Script build phase on the target, guarded `if [ "$CONFIGURATION" = "Debug-Dev" ]`**,
  copies it over the bundled name:
  `cp "$SRCROOT/Fixtures/route_activation-dev.json" "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/route_activation.json"`.
  The dev fixture is **not** added to the prod Resources build phase, so prod bundles are
  untouched and no `ActivationCoordinator` API change is needed.
- **D-05 (CLI):** `xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme Dev -configuration Debug-Dev -destination 'platform=iOS Simulator,name=iPhone 16' build` (also document the GUI path: `open …xcodeproj`, pick `Dev` scheme, Run). `localhost:4700` is reachable from the simulator directly.

### Android — additive `dev` product flavor (requires a sibling `prod` flavor)
- **D-06 (mechanism + naming — CONFLICT RESOLVED):** Add `flavorDimensions "env"` with
  **two** flavors: **`prod`** (the proof/default build) and **`dev`**. AGP requires every
  variant to carry a dimension once *any* flavor exists, so the proof build needs an
  explicit flavor. **It must be named `prod`, NOT `main`** — `main` is a reserved
  source-set name and a flavor named `main` collides with `src/main` (which is shared by
  all flavors). Proof build = `prodDebug`/`prodRelease`; dev build = `devDebug`/`devRelease`.
- **D-07 (coexistence):** `dev` flavor gets `applicationIdSuffix ".dev"` (+ `versionNameSuffix "-dev"`)
  so the dev app (`dev.crosswake.shell.dev`) and the proof app (`dev.crosswake.shell`)
  install side-by-side on one emulator. Both Debug variants use the debug keystore — no
  signing conflict.
- **D-08 (dev asset override):** `app/src/dev/assets/route_activation.json` overrides the
  main asset **for the dev variant only** via source-set priority (flavor > main);
  `app/src/main/assets/route_activation.json` and the other proof assets
  (`crosswake_manifest.json`, `installed_packs.json`, etc.) are untouched and carried as-is.
  The Android core loads the hardcoded `route_activation.json` from `assets/` — no library
  change.
- **D-09 (manifest overlay + cleartext):** `app/src/dev/AndroidManifest.xml` (with
  `xmlns:tools`) adds `android:networkSecurityConfig="@xml/network_security_config_dev"`
  via `tools:replace="android:networkSecurityConfig"` on `<application>`, and **adds a
  separate non-`autoVerify` intent-filter** for `http://10.0.2.2:4700`. The main manifest
  (`usesCleartextTraffic="false"`, the `autoVerify="true"` filter for
  `https://example.crosswake.invalid`) is untouched — `networkSecurityConfig` takes
  precedence over the inline `usesCleartextTraffic`. `app/src/dev/res/xml/network_security_config_dev.xml`
  permits cleartext **only** for `10.0.2.2` with an explicit
  `base-config cleartextTrafficPermitted="false"` (default-off posture preserved).
  **Footguns (from research):** `autoVerify="true"` on `10.0.2.2` triggers install-time
  asset-link verification that fails and, on API ≤ 30, can break the proof domain's
  verification too — so the dev filter MUST omit `autoVerify`; the `tools` namespace must
  be declared or `tools:replace` silently no-ops; `<debug-overrides>` does NOT gate
  cleartext (only trust anchors) — scope cleartext per-domain instead.
- **D-10 (BLAST RADIUS — planner must handle):** Introducing flavors **renames every
  existing variant**. All current CI / proof-lane / docs Gradle invocations and `adb`
  targets must be migrated to the `prod`-flavored names, e.g. `assembleDebug` →
  `assembleProdDebug`, `testDebugUnitTest` → `testProdDebugUnitTest`,
  `connectedDebugAndroidTest` → `connectedProdDebugAndroidTest`, the `crosswakeApi34`
  managed-device tasks become flavored, and `adb shell am start -n dev.crosswake.shell/…`
  stays on the proof package. **Researcher/planner MUST grep CI workflows, `script/`,
  Makefile, and READMEs for Gradle/`adb` invocations and update them in lockstep** — this
  is the single largest regression risk in the phase. The human-facing dev launch task is
  **`installDevDebug`** (not `installDev`).

### Dev fixtures — GENERATED by `mix crosswake.contract.gen --dev` (single source of truth)
- **D-11 (generate, don't hand-author):** Extend the existing generator with a `--dev`
  flag (`OptionParser.parse!(args, strict: [dev: :boolean])`), mirroring the in-repo
  precedent `mix crosswake.gen.shell --target/--local` and reusing the existing
  `write_if_changed/2` idempotency. Hand-authored fixtures rot silently when the contract
  bumps (`bridge_protocol_version`, capabilities); generation keeps a single source of
  truth — `bridge_protocol_version` from `Crosswake.Bridge.Contract.version()`, shared
  capability/pack constants, and **only `url` / `origin` / `correlation_id` diverge** from
  prod.
- **D-12 (fixtures, committed + honestly tagged):** Run `--dev` once and **commit** the two
  outputs (no secrets; differ from prod only in url/origin/correlation_id). They carry
  `"_generated_by": "mix crosswake.contract.gen --dev"` so they're honestly distinguishable
  from proof fixtures. Targets (route confirmed: router serves `/native/claims/:id/capture`
  → `ClaimCaptureLive`, `route_id: selective-native-claim-capture`):
  - iOS → `examples/ios_shell_host/Fixtures/route_activation-dev.json`,
    `origin: http://localhost:4700`, `url: http://localhost:4700/native/claims/claim-1/capture`.
  - Android → `examples/android_shell_host/app/src/dev/assets/route_activation.json`,
    `origin: http://10.0.2.2:4700`, `url: http://10.0.2.2:4700/native/claims/claim-1/capture`.
  - `manifest_source: "bundled"`, `source: "cold_start"` in both (match prod format).
- **D-13 (don't clobber, don't false-drift):** A **default (no-flag)** `mix crosswake.contract.gen`
  run must NOT write or touch the dev fixtures. In the drift test, add a **separate**
  `@dev_generated_json_paths` list — do **not** add dev paths to `@generated_json_paths`
  or the "seven committed surfaces" prod assertion. Since dev fixtures are committed, the
  dev drift assertion is unconditional (no `File.exists?` gating). The existing
  `compare_generated_surface/3` helper already works on any JSON with root
  `bridge_protocol_version`; it checks the version, not `_generated_by`, so the ` --dev`
  tag is not a false positive.

### Proof-posture guard + CLI launch docs
- **D-14 (guard test):** New `test/crosswake/guides/native_dev_wiring_test.exs`
  (`Crosswake.Guides.NativeDevWiringTest`), living with the other doc-contract/drift
  guards. **Source-derived, not hardcoded** (port from
  `examples/phoenix_host/config/runtime.exs` via the existing
  `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` regex), JSON via `Jason.decode!` key
  lookup (never text-grep on JSON), and **synthetic anti-vacuity regression cases** (house
  idiom from `native_evidence_drift_test.exs` / `contract_drift_test.exs`). Assertions:
  - **Proof untouched:** prod `Info.plist` contains none of `NSAllowsArbitraryLoads` /
    `NSExceptionDomains` / `localhost`; prod iOS + Android fixtures `origin ==
    https://example.crosswake.invalid`; prod `AndroidManifest.xml` has
    `usesCleartextTraffic="false"` and does NOT reference `network_security_config_dev`.
  - **Dev exists:** `Info-Dev.plist`, `route_activation-dev.json`,
    `app/src/dev/assets/route_activation.json`, `app/src/dev/res/xml/network_security_config_dev.xml`.
  - **Dev correct:** dev fixture origins contain the source-derived `localhost:<port>` /
    `10.0.2.2:<port>`; `Info-Dev.plist` contains the localhost cleartext exception;
    `network_security_config_dev.xml` contains `10.0.2.2`. (This also **closes a gap**: the
    existing QUICK_START port scanner only matches a `localhost:` prefix, so `10.0.2.2:4700`
    is otherwise unguarded.)
  - **Dev honestly tagged:** dev `_generated_by` starts with the prod fixture's
    `_generated_by` value (derive from prod, tolerate the ` --dev` suffix).
- **D-15 (docs placement — NDEV-03):** Add **one additive section** to
  `examples/QUICK_START.md` (after the existing Android local-dev walkthrough): "Run
  Against the Local Backend (Dev Wiring)" with the iOS (`-scheme Dev`, plus open-in-Xcode
  path) and Android (`installDevDebug` + `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`)
  commands. Do **not** create a new `guides/` file (Phase 128 owns `guides/see_it_run.md`)
  and do **not** bloat the minimal host READMEs (guarded by `native_evidence_drift_test`).
  The new section must satisfy the existing `quick_start_adoption_drift_test.exs` checks
  (source-derived port, native labels `checked-in public-coordinate proof` /
  `published-coordinate mode` present in the "what this does not change" block).
- **D-16 (honest voice):** Label dev runs as **`advisory native`** evidence — one calm
  sentence ("a successful simulator/emulator run confirms the dev wiring reaches the local
  backend, but does not prove physical-device support"); do not weaken the prod READMEs'
  existing "does not prove … support" language. Brand voice (brand-book): careful
  maintainer, operational truth over hype, caveats placed next to the command that
  triggers them (e.g. JAVA_HOME 17 note right after the Gradle command), payoff before
  toolchain caveats.

### Claude's Discretion (planner/researcher to settle)
- Exact pbxproj UUIDs / insertion points for the `Debug-Dev` config + scheme; whether to
  use a `Configs/Dev.xcconfig` `baseConfigurationReference` vs. setting `INFOPLIST_FILE`
  inline in the Debug-Dev config (both fine; xcconfig slightly cleaner, inline avoids a
  precedence gotcha where GUI/target settings override xcconfig).
- Exact simulator model named in docs (`iPhone 16` is a placeholder).
- Whether `--dev` also accepts a `--backend-url` override later — **defer**; hardcode
  `4700` / `localhost` / `10.0.2.2` now (port is locked by Phase 125).
- Whether to also add `JAVA_HOME=/opt/homebrew/opt/openjdk@17` guidance inline (recommended
  per project memory — gradle needs JDK 17).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"NDEV" — NDEV-01..03 (locked requirement text).
- `.planning/ROADMAP.md` §"Phase 126" — goal + 3 success criteria (the acceptance bar).
- `.planning/phases/125-containerized-shared-backend-port-convention/125-CONTEXT.md` — port
  4700 convention, runtime.exs structure, "proof fixtures are sacred" precedent.

### iOS host — modify additively (NEVER mutate the proof files)
- `examples/ios_shell_host/CrosswakeShell/Info.plist` — prod plist (PROOF; stays untouched).
- `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist` — **create** (D-03).
- `examples/ios_shell_host/Fixtures/route_activation.json` — prod fixture (PROOF; untouched).
- `examples/ios_shell_host/Fixtures/route_activation-dev.json` — **generated** (D-11/D-12).
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` — add `Debug-Dev`
  config + Run Script copy phase (D-01/D-04); minimal, prod target byte-identical.
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/` — add `Dev.xcscheme` (D-02).
- `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` — boots from bundled
  `route_activation.json`; gracefully shows "Connecting…/Retrying…" if backend down (no change).

### Android host — modify additively (NEVER mutate the proof files)
- `examples/android_shell_host/app/build.gradle` — add `flavorDimensions`/`prod`+`dev`
  flavors (D-06/D-07); **triggers variant-rename blast radius (D-10)**.
- `examples/android_shell_host/app/src/main/AndroidManifest.xml` — prod manifest (PROOF; untouched).
- `examples/android_shell_host/app/src/main/assets/route_activation.json` — prod fixture (PROOF; untouched).
- `examples/android_shell_host/app/src/dev/AndroidManifest.xml` — **create** (D-09).
- `examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml` — **create** (D-09).
- `examples/android_shell_host/app/src/dev/assets/route_activation.json` — **generated** (D-11/D-12).
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/MainActivity.kt`,
  `LiveViewFragment.kt` (`isSameOrigin` check), `CrosswakeShellConfig.kt` — boot path (no change).

### Contract generator + drift guards (Elixir)
- `lib/mix/tasks/crosswake.contract.gen.ex` — add `--dev` flag + dev builders + path
  constants (D-11); default run must not write dev fixtures (D-13).
- `lib/mix/tasks/crosswake.gen.shell.ex` — precedent for `--target`/`--local` OptionParser flags.
- `lib/crosswake/shell/fixtures.ex` — fixture construction reference.
- `test/crosswake/contract/contract_drift_test.exs` — `@generated_json_paths`,
  `compare_generated_surface/3`, `write_if_changed` drift idiom; add `@dev_generated_json_paths` (D-13).
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — source-derived port regex,
  `require_contains`, `wrong_port_failures`, native-label checks (mirror for D-14/D-15).
- `test/crosswake/guides/native_evidence_drift_test.exs` — synthetic anti-vacuity regression
  idiom; host-README required-terms (don't break by editing READMEs).
- `test/crosswake/guides/port_registry_test.exs` — minimal source-derived guard example.

### Backend route (dev fixtures point here)
- `examples/phoenix_host/lib/crosswake_example/router.ex` §`scope "/native"` — `/claims/:id/capture`
  → `ClaimCaptureLive`, `route_id: selective-native-claim-capture` (confirmed).
- `examples/phoenix_host/config/runtime.exs` — canonical `PORT` source for the guard test.

### Docs surface (NDEV-03) + voice
- `examples/QUICK_START.md` — add the additive "Run Against the Local Backend" section (D-15).
- `examples/ios_shell_host/README.md`, `examples/android_shell_host/README.md` — keep minimal/honest; do NOT add commands.
- `prompts/crosswake-elixir-oss-dna.md` — honesty/no-drift/install-truth culture.
- `prompts/crosswake-brand-book.md` — voice/tone for the dev-wiring microcopy.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix crosswake.contract.gen` + `write_if_changed/2` — extend with `--dev`; idempotent
  generation already proven. `crosswake.gen.shell --target/--local` is the OptionParser precedent.
- `contract_drift_test.exs` / `quick_start_adoption_drift_test.exs` — source-derived,
  JSON-key-lookup, synthetic-regression drift idiom to copy verbatim for the new guard.
- iOS `Run Script build phase` + Android `productFlavors` / `src/<flavor>/` source sets —
  conventional, ecosystem-idiomatic overlay mechanisms; no library/API change needed.

### Established Patterns
- **Proof fixtures are sacred** — iOS `Info.plist`/`route_activation.json` + Android
  `src/main/AndroidManifest.xml`/`assets/*.json` are contract-generated public-coordinate
  proof; additive dev-wiring must never mutate them (guarded by D-14).
- Native cores load a **hardcoded** `route_activation.json` from the bundle/assets — dev
  wiring overrides that single resource (iOS copy-phase; Android source-set), no API change.
- Doc-contract / drift tests guard every port/route/command claim (DOCS/honesty culture);
  derive from source, never hardcode (avoid the repo's known brittle-closeout failure mode).

### Integration Points
- Dev fixture `url`/`origin` is the only behavioral lever — it points the native WebView at
  `localhost:4700` (iOS sim) / `10.0.2.2:4700` (Android emulator host-loopback).
- ATS (iOS) + `networkSecurityConfig` (Android) gate cleartext; both scoped to the dev
  variant only so the prod/release cleartext posture stays off.
- Android flavor introduction reverberates into CI/proof-lane Gradle + `adb` invocations (D-10).
</code_context>

<specifics>
## Specific Ideas

- The maintainer wanted a single coherent, one-shot recommendation set (not sequential
  one-by-one questions) — delivered via four parallel research subagents (iOS mechanism,
  Android mechanism, fixture generation, proof-posture guard + docs), each weighing
  pros/cons/tradeoffs, Elixir/Android/iOS idiom, and cross-ecosystem lessons (Hotwire
  Native, Flutter flavors, RN, Capacitor, Expo), synthesized into D-01..D-16.
- Symmetry was an explicit design goal: iOS `Dev` scheme ↔ Android `dev` flavor; both are
  additive overlays with a parallel dev fixture and dev-only cleartext, never a mutated
  proof artifact. The two CLI commands read as siblings in the docs.
- Cross-ecosystem lessons applied: Hotwire Native's hand-edited-localhost-URL footgun →
  use tooling (scheme/flavor) instead; Flutter's xcconfig+config+scheme is the iOS idiom;
  scope cleartext to the exact host (never global `usesCleartextTraffic`/`NSAllowsArbitraryLoads`).

### Conflicts resolved during synthesis
- **Android flavor naming:** a researcher proposed a `main` flavor; rejected — `main` is a
  reserved source-set name. Resolved to `prod` + `dev` (D-06).
- **Dev `_generated_by`:** generation chosen over hand-authoring (D-11); the guard asserts
  the dev tag *starts with* the prod tag rather than equals, tolerating the ` --dev` suffix (D-14).
- **Commit vs. gate:** dev fixtures are committed, so the guard's existence/drift assertions
  are unconditional — no `File.exists?` gating (D-12/D-13).
- **iOS bundling:** core loads a hardcoded `route_activation.json`, so a `Debug-Dev`-guarded
  Run Script copy phase replaces it at build time — no `ActivationCoordinator` API change (D-04).
- **Android dev launch task:** `installDevDebug` (flavored), not `installDev` (D-10/D-15).
</specifics>

<deferred>
## Deferred Ideas

- `bin/see-it-run.sh` / `mix crosswake.demo` launch orchestration + brand-voiced ASCII
  banner with honest "proven / needs native build" block → **Phase 127**.
- Full `guides/see_it_run.md` (gameplan-at-top, JTBD-driven), three-runtime screenshots +
  screen recording, README routing to the guide, `test/crosswake/guides/see_it_run_test.exs`
  → **Phase 128** (which will *link* to, not duplicate, the QUICK_START dev-wiring section).
- `mix crosswake.contract.gen --dev --backend-url <url>` parametrization — deferred; the
  port/hosts are hardcoded now (4700 locked by Phase 125).
- Dockerizing the Android emulator — explicitly OUT OF SCOPE (recorded in REQUIREMENTS).

None beyond the above — discussion stayed within phase scope.
</deferred>

---

*Phase: 126-additive-native-dev-wiring*
*Context gathered: 2026-06-22*
