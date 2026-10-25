# Generation API and Ownership Challenge

**Decision:** Use the Phoenix host declaration as authoring truth, selected by the ordinary Mix environment. Run one generator/check command that loads config and compiles the selected router, writes only recognized Crosswake-managed resources, and reports conflicts before writes. Activation is a static route/runtime fixture; session, account, scope, and replay authorization remain host/runtime facts.

## Consumer API and precedence

Use the host's normal `config/config.exs` plus environment config, with the public production origin declared in `config/prod.exs` (or the host's equivalent config imported there):

```elixir
config :crosswake, :ios_host,
  router: MyAppWeb.Router,
  origin: "https://study.example.org",
  bundle_id: "org.example.study",
  ui_test_bundle_id: "org.example.study.uitests",
  signing: [mode: :automatic, team_id: "ABCDE12345"]
```

Consumer path:

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --diff
MIX_ENV=prod mix crosswake.gen.shell ios --check
MIX_ENV=prod mix crosswake.gen.shell ios
```

`MIX_ENV` selects the compiled host configuration; values in `:ios_host` are authoritative. Do not add a second `--config` file or let routine CLI options silently override router, origin, or signing identity. Preserve the existing `--router` only as a compatibility path for legacy local/dev generation; if both declaration and override are supplied, fail with a clear conflict unless an explicitly documented dev-only override is used. Production generation requires the declaration. `--diff` is read-only, `--check` fails on stale/missing managed output without writing, and the no-flag task refreshes only recognized managed files.

Declare `@requirements ["app.config"]` so the task reads `Application.get_env/3` after host config loads. Mix documents `app.config` as loading/configuring applications and `runtime.exs`; task docs call it the minimum requirement for interacting with host config. Do **not** call `Mix.Task.run("app.start")`: it starts application supervision trees and can boot Phoenix or external services. Repo compatibility is Elixir `~> 1.19`, Phoenix `~> 1.8` (locked 1.8.13), LiveView `~> 1.1` (1.1.33), Plug 1.19.5 transitively; reference host Ecto is 3.13.6. No dependency upgrade is proposed. Sources: [Mix task requirements](https://mix.hexdocs.pm/main/Mix.Task.html), [`mix app.config`](https://mix.hexdocs.pm/Mix.Tasks.App.Config.html), [`mix app.start`](https://mix.hexdocs.pm/Mix.Tasks.App.Start.html), repository [`mix.exs`](../../../mix.exs) and [`mix.lock`](../../../mix.lock).

## Managed-file ownership and regeneration

Keep Phoenix config and native Swift/Xcode project structure host-owned. The first generator may create the Xcode project and wire app/UI-test targets to a marked `CrosswakeHost.xcconfig`; later runs must not rewrite arbitrary `.pbxproj` structure. The generator owns only (a) the marked xcconfig's Crosswake build settings and (b) canonical bundled manifest/activation JSON. On regeneration: validate every input and existing managed-file marker/schema first; compute all outputs in memory; show diff/check result; then atomically replace only recognized Crosswake-managed files. If a target is edited, marker/schema is unknown, or a destination collides with an unowned file, stop before any write and report the path plus repair action. Never overwrite host edits, silently keep stale manifest data, or partially update manifest and activation.

Use `.xcconfig` only for identity/signing/build variables such as bundle IDs, development team, signing style, and SDK conditions. Do not store the URL origin there: Xcode uses `//` as a comment delimiter, so an `https://...` value can be parsed as a comment. Put the public origin in Phoenix host config and serialized manifest JSON. Apple also documents that Xcode project/target settings have higher precedence than mapped `.xcconfig` values; the project template must reference variables (for example `PRODUCT_BUNDLE_IDENTIFIER = $(CROSSWAKE_IOS_BUNDLE_ID)`) instead of hard-coding values that mask them. Test resolved settings with `xcodebuild -showBuildSettings` for app and UI-test targets, Debug/Release, simulator/device SDKs. Deselect all targets when adding the `.xcconfig` file so Xcode does not embed it as a bundle resource. Sources: [Apple build-setting precedence](https://developer.apple.com/documentation/xcode/configuring-the-build-settings-of-a-target/), [Apple `.xcconfig` setup/comments/target exclusion](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project/).

## Origin preconditions and authority boundary

Before any output write, require exactly one canonical production HTTPS origin from the selected host config. Reject missing/placeholder origin, userinfo, non-HTTPS schemes, wildcard hosts, path beyond `/`, query, fragment, malformed host/port, and ambiguous trailing syntax. Normalize and compare origins structurally, not via string-prefix matching. Permit localhost only for explicit dev/test generation. Error messages identify the config key and remediation without echoing the configured value. Validate the selected router's current Crosswake route declarations and require every emitted route to resolve against the same canonical origin. If auth or media use a different origin, require a separate explicit host-owned allowlist of exact HTTPS origins; do not silently widen route matching. Existing builder behavior sets each route's allowlist to `[origin]`, so extending that safely requires a narrow manifest-builder change and explicit tests, not wildcard fallback.

Generated activation must contain only static route/runtime facts needed to validate and open a route: route ID, runtime kind, canonical URL/origin, manifest version/digest if the existing contract requires them, and static capability/runtime metadata. It must not create or imply a logged-in session, account, scope, token, identity-provider result, replay grant, or server acceptance. At launch the host resolves real session/auth authority, maps identity to an opaque scope, and separately authorizes replay; absent authority remains denied. This follows the governing ADR and the DX/Twin constraint that activation is configuration, never user authorization.

## Chosen path and implementation experiments

The chosen path is the split ownership design from `GENERATION.md`, narrowed to one source of truth: host Phoenix config plus `MIX_ENV`, with CLI limited to `--diff`, `--check`, and legacy nonproduction compatibility. It retains existing Mix ergonomics without duplicating lasting config in shell flags or an opaque second config file. Preserve current dev/test invocation; production behavior becomes explicit and fail-closed.

Before implementation, verify: (1) a fixture Mix task reads selected `:ios_host` under `app.config` without starting Phoenix; (2) conflicting files and multi-output failure cause zero partial writes; (3) `xcodebuild -showBuildSettings` resolves each target/config/SDK and the bundle excludes xcconfig. Also test URL serialization and explicit secondary-origin allowlists. Stop after these pass; no generic project editor is justified.

**Conflict for research synthesis:** `GENERATION.md` currently proposes one `origin` in a generated xcconfig/native-origin setting. This challenge recommends excluding the origin from `.xcconfig`, leaving it solely in host config plus manifest JSON, and allowing only additional explicit auth/media origin entries if the host requires them. Both reports agree generated activation is static-only and cannot confer session/replay authority.
