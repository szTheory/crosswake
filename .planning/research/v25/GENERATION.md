# v25 Research: iOS Host Setup and Generation Boundary

**Scope:** IOS-01, IOS-02, IOS-03; host-owned identity/signing inputs, regeneration, and production bundled manifest/activation.  
**Source baseline checked:** approved public `main` pin `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b` through the read-only GitHub Contents API. The recovery checkout is dirty and older; local code was not treated as current implementation truth.  
**Confidence:** High for pinned generator/template behavior and Apple/Elixir conventions; medium for the recommended public API until a focused implementation spike exercises Xcode project wiring and config-loading behavior.

## Decision in one sentence

Use a **split authoring/build model**: one explicit, host-committed `:crosswake, :ios_host` declaration owns router, deployment origin, app/test bundle IDs, signing mode, and team/profile selectors; a single Mix generator reads that declaration and the compiled host router, then refreshes only Crosswake-managed outputs (the bundled manifest, activation fixture, and a small included `.xcconfig`). Keep generated Swift and the Xcode project host-owned after initial creation. CLI flags select the config/environment or bootstrap the declaration, but do not become the lasting source of truth. Require an explicit production origin and fail before writing a production bundle when it is absent, malformed, or the reserved `https://example.crosswake.invalid` default.

This is the smallest design that solves the observed mismatch without turning Crosswake into an Xcode project editor or a generic native build framework. It follows Crosswake’s established generator-plus-library pattern and the governing rule that runtime ownership remains explicit and host-owned.

## What the pinned code does today

At the approved pin, `mix crosswake.gen.shell ios` accepts `--router`, but the router is only compiled to collect capability IDs. `Crosswake.Shell.Fixtures.export/1` separately serializes a fixed dashboard route, fixed pack inventory, and `Types.default_origin()` (`https://example.crosswake.invalid`). `generate_ios_shell/4` writes those fixtures with `ensure_file/2`, which creates missing files and preserves existing ones. It writes a sidecar `.crosswake/shell.json`, but the sidecar records only router/local/target parameters and does not drive fixture regeneration. The Xcode project template has hard-coded `dev.crosswake.shell` and `dev.crosswake.shell.tests`, an empty team, and signing disabled for its project/app/test configurations. So a router flag does not currently produce a host-derived production manifest or activation, and re-running generation does not repair an existing fixture.

Relevant pinned sources: [`crosswake.gen.shell`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/mix/tasks/crosswake.gen.shell.ex), [`Crosswake.Shell.Fixtures`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/shell/fixtures.ex), [`Crosswake.Manifest.Builder`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/manifest/builder.ex), [`Crosswake.Manifest.Types`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/crosswake/manifest/types.ex), and the [`iOS project template`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex). `Crosswake.Manifest.Builder.build/3` already accepts an explicit `:origin` or `:host`; use that existing manifest boundary rather than inventing another serializer.

The generated shell README calls the project host-owned/editable and says it is not safely regeneratable over host edits. Separately, the proof-lane generator already demonstrates a useful safer pattern: closed normalized config, exact keys, non-echoing errors, missing-only writes, `--check`, and `--diff`. The setup design should keep this ownership clarity, while permitting deterministic refresh of narrowly designated generated outputs. Do not silently flip all native output to library-owned.

## Three viable ownership designs

| Design | Example caller | Strengths | Costs and risks | Compatibility and maintenance |
|---|---|---|---|---|
| **CLI-centric** | `mix crosswake.gen.shell ios --router MyAppWeb.Router --origin https://app.example.test --bundle-id com.example.app --team-id ABC1234567 --signing automatic` | Discoverable for a one-off; easy to script; explicit values at invocation; simple to add without changing host config. | Long command and escaping; values can leak into shell history/process listings; every regenerate must repeat them or rely on generator metadata; CLI metadata may become stale after route/config changes. Cannot safely take secrets as flags. | Preserves existing commands, but storing enough options to regenerate creates a second config format. New options accrete and caller scripts become an API. Good bootstrap/override surface only, not source of truth. |
| **Phoenix declaration-owned** | `config :crosswake, :ios_host, router: MyAppWeb.Router, origin: ..., bundle_id: ..., team_id: ...`; then `mix crosswake.gen.shell ios` | Idiomatic single host-owned declaration; less CLI repetition; router/origin/identity evolve with the Phoenix app; easy for maintainers to inspect and validate. Router route metadata remains authoritative for policies. | Config loading by a library can be opaque; `Application` environment is global; deployment origin may be placed in `runtime.exs`, which runs immediately before app startup, while bundle assets must already be generated during build. Requires explicit environment selection and clear compile/build-vs-runtime docs. | Small API surface and backwards-compatible defaulting for existing dev/test invocation. Must avoid requiring `config/runtime.exs` as the only build input. Mix/config version conventions must remain aligned with supported Phoenix/Elixir versions. |
| **Split generator + host/build config (recommended)** | Declare `:ios_host` once; run `MIX_ENV=prod mix crosswake.gen.shell ios --config config/config.exs` (or the normal host config path); verify with `mix crosswake.gen.shell ios --check`. | Keeps authoring truth in host config, uses current Phoenix route declarations, and gives the Mix command an explicit build target. The generator can validate, diff, and atomically update only managed resources. `.xcconfig` makes Xcode settings inspectable and can express simulator/device differences. | Slightly more conceptual surface: host declaration, target env, managed outputs. Need a stable generated-file contract, lock/atomic-write behavior, and a one-time project-template hook. | Existing `--router`, `--local`, and default dev behavior can remain as compatibility shims. Add opt-in config-driven production generation, then deprecate ambiguous no-origin production defaults. Avoid automatic rewrite of host-owned Xcode project/Swift files. |

Phoenix’s own generators are a precedent for code generation and project-local template overrides, while warning that template overrides can need maintenance across Phoenix upgrades. Elixir’s Config docs advise libraries against relying on application environment as global storage; therefore normalize caller-supplied config into a closed struct and have the Mix task pass it into pure generation/validation functions. Plug’s `init/1`/`call/2` option boundary and Ecto’s host-configured Repo/adapter boundary support the same principle: Crosswake consumes explicit host-owned declarations and does not own host database/auth/runtime authority.

## Recommended caller contract

The exact key names are a proposed API, not shipped support. Keep public configuration closed, typed, documented, and non-echoing. Make `bundle_id`, `team_id`, origin, and profile selector plain values. Do not add signing passwords, private keys, certificates, provisioning profile bytes, account IDs, or secrets to this config.

```elixir
# config/config.exs or an explicitly selected host config file
config :crosswake, :ios_host,
  router: MyAppWeb.Router,
  origin: "https://app.example.test",
  bundle_id: "com.example.study",
  test_bundle_id: "com.example.study.proof-tests",
  signing: :automatic,
  team_id: "ABC1234567"
```

```sh
# The target environment is explicit because this command produces bundled build inputs.
MIX_ENV=prod mix crosswake.gen.shell ios --check
MIX_ENV=prod mix crosswake.gen.shell ios --diff
MIX_ENV=prod mix crosswake.gen.shell ios
```

The generator should compile `MyAppWeb.Router` through the existing route-policy compiler, build the canonical manifest with `Crosswake.Manifest.Builder.build(routes, managed_routes, origin: origin)`, serialize via the canonical manifest serializer, and derive activation from a selected valid host route plus that same origin. Never derive activation from a separate default fixture. Manifest and activation must share the same canonical origin and route IDs. Production mode must reject the reserved example origin, non-HTTPS origins, credentials, path/query/fragment, wildcard host, and invalid app/team/profile syntax; localhost is allowed only for explicit dev/test targets. Errors should name a configuration key and remediation, never print configured values.

Do not depend on `runtime.exs` as the only production build input. It is appropriate for late deployment values/secrets, but the native bundle is created before app startup. If hosts deliberately inject the public origin at release runtime, startup must compare it with the bundled host/origin and fail closed on mismatch; that is a separate runtime consistency check, not a reason to ship an example URL. This public origin is not itself a secret.

### Regeneration and file ownership

Keep the initial `.xcodeproj` and generated Swift scaffold host-owned/editable. At first generation, have the project reference a small `CrosswakeHost.xcconfig` through build-configuration file references. Thereafter classify outputs:

| Output | Owner after creation | Regeneration rule |
|---|---|---|
| Swift entrypoints, entitlements, app project structure | Host | Create missing only; never overwrite edits automatically. |
| `CrosswakeHost.xcconfig` with Crosswake identity/signing keys | Crosswake-managed generated file, host inputs remain the config declaration | Deterministically replace only if its generator marker/schema is recognized; otherwise stop with a repair instruction. Provide `--diff` and `--check`. |
| Bundled manifest and activation JSON | Crosswake-managed generated resources | Deterministically refresh from router + target origin; write temp sibling then atomic replace. No “reuse stale file” success. |
| `.crosswake/shell.json` | Crosswake metadata | Record schema/template version and non-sensitive input digest/target; omit origin, bundle/team/profile values and all runtime secrets from logs/proof. A digest may also be identifying, so avoid including it in public proof artifacts. |

This split prevents the current missing-only writer from preserving an obsolete production manifest while also avoiding clobbering host edits to Swift/PBX project structure. A config or template epoch mismatch should produce a readable `--diff` and actionable error; do not auto-merge arbitrary `.pbxproj` edits. Include a dry-run and check mode before updates. Preserve current invocation behavior in non-production and keep `--router` as a compatibility override until documented deprecation.

## Identity and signing posture

Use host-owned `.xcconfig` values referenced by the app and proof targets, not textual mutation of the `.pbxproj` on every run. Apple documents `.xcconfig` as plain-text layered build configuration, with project settings, configuration-file settings, and target settings taking precedence in a defined order. Therefore, make target settings reference the declared variables (`PRODUCT_BUNDLE_IDENTIFIER = $(CROSSWAKE_IOS_BUNDLE_ID)`, etc.) instead of hard-coding values that mask `.xcconfig`; test the *effective* settings with Xcode’s `-showBuildSettings` for each target/configuration/sdk.

```xcconfig
// CrosswakeHost.xcconfig: generated from the host's :ios_host declaration
CROSSWAKE_IOS_BUNDLE_ID = com.example.study
CROSSWAKE_IOS_TEST_BUNDLE_ID = com.example.study.proof-tests
CROSSWAKE_IOS_TEAM_ID = ABC1234567

PRODUCT_BUNDLE_IDENTIFIER = $(CROSSWAKE_IOS_BUNDLE_ID)
DEVELOPMENT_TEAM = $(CROSSWAKE_IOS_TEAM_ID)
CODE_SIGN_STYLE = Automatic
CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO
CODE_SIGNING_REQUIRED[sdk=iphonesimulator*] = NO
CODE_SIGNING_ALLOWED[sdk=iphoneos*] = YES
CODE_SIGNING_REQUIRED[sdk=iphoneos*] = YES
```

The test bundle target gets its own `PRODUCT_BUNDLE_IDENTIFIER`; apply the team/signing settings to the app and device UI-test runner targets that Xcode actually signs. Keep simulator and device builds explicit: simulator/hermetic proof remains unsigned; device build settings are device-capable and use automatic signing by default. Manual signing can be supported with a profile name/UUID selector, but certificates/private keys and installed profiles are provisioned in Xcode/keychain/CI credentials by the host. Configuration generation and `xcodebuild -showBuildSettings` inspection do not prove that signing assets exist or that a device can install the build. Keep that physical signed-device check separate as IOS-02 states.

Do not leave `CODE_SIGNING_ALLOWED = NO` at a project or target layer that overrides the device `.xcconfig`. Conversely, do not make simulator signing depend on Apple credentials. Test propagation for Debug/Release, app/test targets, `iphonesimulator`, and `iphoneos`; the public report may include target/setting names and pass/fail only, not team or bundle values.

## Worked design calls

| Question | Decision | Reason |
|---|---|---|
| Where does app identity live? | Host config declaration; generated `.xcconfig` projects it into Xcode. | One editable, reviewable authority while supporting Xcode-native settings inspection. |
| Where does route ownership come from? | Host Phoenix router’s existing Crosswake route metadata/compiler. | Avoid a second route DSL and preserve explicit per-route runtime ownership. |
| How is production origin selected? | Explicit build-target host config, optionally selected by an explicit CLI config/environment. | A bundled offline manifest must have production values at build time; runtime-only values arrive too late. |
| What does regenerate own? | Only canonical manifest/activation and marked `.xcconfig`; native project/app source remain host-owned. | Prevent stale policy while avoiding destructive project editing. |
| What proves signing setup? | Effective Xcode build-setting inspection for device/simulator and app/test targets. | Verifies wiring without pretending credentials or physical install are proven. |
| What is not emitted? | Secrets, profile bytes, private IDs, origin/team/bundle values in public proof/logs. | Minimize exposure; redact input values even for validation errors. |

## Security and maintenance constraints

- Fail closed on missing/placeholder production origin and any disagreement between generated route origins and the native allowed-origin configuration. Never let a build silently ship `example.crosswake.invalid`.
- Validate origins as origins, not arbitrary URLs. Reject userinfo, path, query, fragment, wildcard, non-HTTPS production schemes, and trailing ambiguity before writing files.
- Use a validated atom/module value from config; do not turn unchecked CLI text into atoms. Existing `String.to_atom/1` router parsing deserves a bounded allow/lookup fix in the implementation work, especially for arbitrary CLI input.
- Keep route manifests data-only and canonical. Build from the compiled router and the same origin used by activation; generated activation must pass the existing manifest validator/resolver.
- No public proof includes raw host config or field values. A privacy-safe error is `IOS-CONFIG-ORIGIN: origin; set a production HTTPS origin in :crosswake, :ios_host`, not a printed URL.
- Treat Xcode-generated UUID churn as project-file maintenance; do not use broad string replacement or claim arbitrary project-edit preservation.
- Phoenix route metadata is compile-time route truth; `Phoenix.Router.routes/1` and route info provide the route inventory. Keep Ecto adapters/Repos and auth/business schemas host-owned.

## Proposed corrections to IOS-01 / IOS-02 / IOS-03

| Requirement | Tighten to implementation-ready acceptance |
|---|---|
| **IOS-01** | “Maintainer declares app and proof-test bundle IDs, team ID, signing mode, router, and deployment origin in one documented host-owned config. Initial generation wires those values into the app/test Xcode targets. Regeneration preserves the host declaration and native edits, refreshes only recognized Crosswake-managed settings/resources, and gives `--diff`/`--check` with non-echoing errors. No credential material enters generated artifacts, logs, or proof.” Explicitly define simulator/device target coverage and backwards-compatible CLI behavior. |
| **IOS-02** | “Generated app and UI-test targets resolve device-capable signing settings (bundle IDs, team, automatic/manual style, optional profile selector) and simulator builds remain explicitly unsigned. Automated `xcodebuild -showBuildSettings` checks verify effective settings for Debug/Release and each relevant target/SDK. This proves configuration propagation only; it does not claim profile availability, signing success, installation, or physical-device proof.” |
| **IOS-03** | “The production bundled manifest and activation are rendered from the selected host Phoenix router’s current Crosswake route declarations and one explicit configured production HTTPS origin. The same origin populates manifest route allowlists, activation URL, and native-origin policy. Production generation fails before writes if origin is missing, placeholder, malformed, or inconsistent; regeneration refreshes only recognized generated resources and never falls back to an example origin.” |

## Non-goals and remaining gaps

Do not add Android work, generic Xcode project rewriting, a broad native generator framework, signing credential management, profile/certificate download, release publishing, background distribution, another route DSL, runtime server-manifest authority, or adopter-specific/private configuration. Do not turn simulator evidence into physical-device evidence.

The decision is implementation-ready enough to plan. Remaining uncertainty belongs in small local experiments: verify Xcode `.xcconfig` precedence for the generated project’s app/unit/UI test targets and SDK conditions; confirm the host config is available to the Mix task at the selected build stage; and verify atomic replacement/error behavior against the production file adapter and the existing actual-output fixture. If Xcode prevents a stable `.xcconfig` hook without rewriting a host-owned project, stop and choose a narrowly scoped first-generation project hook plus config-only regeneration; do not expand into arbitrary `.pbxproj` patching.

## Sources

- [Phoenix `mix phx.gen` generators and project-local template overrides](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.html)
- [Phoenix router route metadata and inventory APIs](https://phoenix.hexdocs.pm/Phoenix.Router.html)
- [Elixir `Config`, including application environment cautions and `runtime.exs` timing](https://hexdocs.pm/elixir/Config.html)
- [Phoenix deployment configuration and secrets in `runtime.exs`](https://hexdocs.pm/phoenix/deployment.html)
- [Plug module boundary: `init/1` normalizes options, `call/2` receives initialized options](https://plug.hexdocs.pm/readme.html)
- [Ecto Repo adapter and host application configuration boundary](https://ecto.hexdocs.pm/Ecto.Repo.html)
- [Apple: adding `.xcconfig` build configuration and precedence](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)
- [Apple: Xcode build settings reference (`PRODUCT_BUNDLE_IDENTIFIER`, team, signing style/profile)](https://developer.apple.com/documentation/Xcode/build-settings-reference)
- [Apple: distribution to registered devices and automatic/manual provisioning](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)
- [Apple: Swift packages and using a reusable package in an app](https://developer.apple.com/documentation/Xcode/swift-packages)
- [Capacitor iOS configuration as a contrast: native Info.plist and capabilities remain Xcode project concerns](https://capacitorjs.com/docs/ios/configuration)
- Crosswake prior art: `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-gsd-project-brief.md`, `prompts/elixir-mobile-oss-lib-deep-research.md`, `prompts/elixir-mobile-oss-refined-plan-deep-research.md`, and `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md`. These informed DX and ownership choices; current ADR/scope takes precedence over their older breadth.
