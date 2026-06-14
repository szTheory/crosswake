# Phase 111: Generator Rewire, Clean-Room Proof & Release — Research

**Researched:** 2026-06-14
**Domain:** Elixir EEx generator rewire, GitHub Actions clean-room CI, Hex/SPM/Maven lockstep release
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-12 (carried from 110) — Version sourcing.**
Inject version at generate-time from `Application.spec(:crosswake)[:vsn]`. When run from the source checkout (not an installed dep) this returns `nil` → emit a clear error, never a `nil`/literal version. iOS uses `upToNextMajorVersion`/`from:` (NOT `exactVersion`, NOT `branch:`).

**D-13 (carried from 110) — Tag-name format.**
The `ios-mirror` job tags the mirror with the same `tag_name` output as `publish-hex` uses. Stay consistent across all three registries.

**D-02 (carried from 110) — Target version is `0.1.2`** via `release-as: "0.1.2"` already in release-please-config.json.

**D-04 (carried from 110) — Remove `release-as` pin** in a `chore:` commit immediately after `0.1.2` ships. This removal is part of REL-01's tail.

**D-01 — Verify-after, not gate-before.** The clean-room lane runs after all three publishes complete. Gate-before creates a chicken-and-egg deadlock against unpublished artifacts.

**D-01a — Wiring.** New `clean-room-proof.yml` with `needs: [release-please, publish-hex, publish-ios-core, publish-android-core]`, gated `if: needs.release-please.outputs.releases_created`. Scaffolds host in `$RUNNER_TEMP` outside the monorepo, no `--local`, no `packages/` access.

**D-01b — Pin to just-cut version.** Use `needs.release-please.outputs.version`, NOT `latest`.

**D-01c — Registry propagation patience.** Maven Central can take ~30 min → poll with exponential backoff. Mirror git-tag is near-instant but add a short retry.

**D-01d — Release-time only.** Per-merge regression protection is PROOF-02 (static parity guard), not the clean-room lane.

**D-02 (PROOF-02) — Extend existing doctor infra.** New `generator_coordinate_parity` ReadinessCheck in `Crosswake.Doctor.PublishReadiness` with `blocking: true`, `proof_class: :merge_blocking`. Static parse only (not live network); dual-surface in test file.

**D-02a — Static parse assertions.** `EEx.eval_file` both templates with `local: false` and the live version, then assert: (1) `github.com/szTheory/crosswake-shell-core-ios`; (2) `io.github.sztheory:crosswake-shell-core-android`; (3) live version string present; (4) no `XCLocalSwiftPackageReference`; (5) no `project(':crosswake`.

**D-02b — Dual surface.** Mirror same assertions in `crosswake_gen_shell_test.exs`.

**D-03 — `guides/install.md` stays canonical.** No new quickstart.md.

**D-03a — Whitelist fix.** Add `"guides/adoption.md"` to `PublishReadiness.@allowed_docs`.

**D-03b — Reframe the one contradictory sentence** in `adoption.md` §1. The generated shell is a thin host-owned wrapper whose native deps resolve from published registries — not vendored code. The eject trap is eliminated by the published-core architecture, not by avoiding generation.

**D-03c — Cross-links + truth pass.** `adoption.md` gains a header note pointing to `install.md`; `install.md` gains a one-line back-reference to `adoption.md`. Reconcile `support_matrix.md` and `CHANGELOG.md`.

### Claude's Discretion
- Exact CI job/step structure, runner matrix, SHA-pins for new actions, poll/backoff script shapes.
- The generated app's own `versionName`/`MARKETING_VERSION` (adopter's app version) is NOT a satellite version under GEN-01 — leave a sensible default.
- Exact wording of the `adoption.md` reframe and cross-link copy.

### Deferred Ideas (OUT OF SCOPE)
- Per-PR clean-room variant requiring live published artifacts.
- GitHub Immutable Releases / mirror landing-page README.
- Real device/emulator proof lanes, route-policy-101, troubleshooting, companion extraction, SPI submission.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEN-01 | `mix crosswake.gen.shell` injects live `crosswake` version from `Application.spec(:crosswake)[:vsn]` — no hardcoded version literal in any template; every native dep version derives from that single source. | `render_template/3` already passes `assigns:` keyword list; add `version:` key. Nil-guard pattern described in §EEx Section. |
| GEN-02 | Default (non-`--local`) iOS and Android templates reference correct published coordinates — iOS `github.com/szTheory/crosswake-shell-core-ios` with `upToNextMajorVersion`/`from:`, Android `io.github.sztheory:crosswake-shell-core-android`. | Exact broken lines confirmed via file inspection; exact replacement text in §Template Rewire. |
| PROOF-01 | Clean-room CI lane scaffolds a host outside the monorepo (no `--local`, no `packages/`) and confirms `swift build` + `gradle build` resolve published deps and compile. | CI job structure in §Clean-Room CI Lane. Needs: ordering, propagation polling, runner matrix. |
| PROOF-02 | Permanent doctor "published-dep parity" check asserts generated coordinates are version-matched and non-monorepo. `blocking: true`, `proof_class: :merge_blocking`. | `build_checks/4` pipeline and `ReadinessCheck` struct fully read. Insertion pattern in §Parity Guard. |
| DOCS-01 | `guides/adoption.md`, `support_matrix.md`, and `CHANGELOG.md` reconciled to published install truth. No 404 install path. | `adoption.md` §1 contradictory sentence identified. `@allowed_docs` whitelist gap documented. |
| REL-01 | Hex `0.1.2` cut last, after `gen.shell` emits correct coordinates, so published Hex version + iOS mirror tag + Android Maven artifact are all at `0.1.2`. Post-cut `release-as` pin removed via `chore:` commit. | `release-please-config.json` has `"release-as": "0.1.2"` already. Removal sequence in §Release Sequence. |
</phase_requirements>

---

## Summary

Phase 111 is the last-mile distribution correctness phase. Phase 110 wired the publish pipeline and lockstep infrastructure; this phase (a) fixes the broken generator output to reference the correct published coordinates, (b) adds two permanent guards against regression (a static doctor parity check and a release-time clean-room proof), (c) reconciles the public docs, and (d) cuts the real coordinated 0.1.2 release.

The work is surgical and high-confidence: every file to touch is identified, the exact broken lines are known (from direct template inspection), the ReadinessCheck struct API is fully understood (from reading publish_readiness.ex), the existing test file shape is understood (from reading the test), and the CI workflow shape is derived from the existing phase79-proof.yml + release-please.yml patterns.

The single non-trivial sequencing constraint within this phase: templates must be rewired and the parity guard must be passing BEFORE the release PR is merged. The clean-room proof only runs after all three publish jobs complete, so its first green run is necessarily post-cut — that is by design (D-01d) and must not be treated as a phase blocker.

The critical "nil-guard" for `Application.spec(:crosswake)[:vsn]` is the most subtle EEx decision: when running from a source checkout rather than an installed dep, `Application.spec/2` may return `nil` (the app is not loaded into the application environment via `mix app.start`). The generator must detect this and raise a helpful error rather than silently producing `nil` as a version string in the output.

**Primary recommendation:** Implement in wave order — (1) rewire gen.shell + templates, (2) add parity guard + test assertions, (3) doc reconciliation, (4) clean-room CI job, (5) cut release + remove pin.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version injection into templates | Elixir Mix Task (`gen.shell`) | EEx template (`@version` assign) | Task reads `Application.spec` at generate-time; template is stateless output |
| Coordinate correctness enforcement (per-merge) | Doctor check (`PublishReadiness`) | ExUnit test (`gen_shell_test.exs`) | Static, fast, cheap. Doctor enforces on `--check-publish` in CI; test enforces on plain `mix test`. |
| Coordinate correctness proof (post-release) | GitHub Actions (`clean-room-proof.yml`) | — | Requires live published artifacts; can only run post-publish. |
| Doc truth enforcement | `@allowed_docs` whitelist in `PublishReadiness` | Manual doc edit | Whitelist ensures docs are present; content truth requires author review. |
| Release cut and lockstep advancement | GitHub Actions (`release-please.yml`) | Manual merge of Release PR | Automated: merge PR → release-please creates tag/release → publish jobs fan out. |

---

## Standard Stack

### Core (all pre-existing; no new runtime deps introduced by this phase)

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Elixir `EEx` | stdlib (≥ 1.19, project-pinned) | Template rendering in `gen.shell` | Already used; `EEx.eval_file/2` takes `assigns:` keyword list |
| `Application.spec/2` | Elixir stdlib | Version retrieval at generate-time | The LiveView Native pattern; already used elsewhere in the codebase |
| `Crosswake.Doctor.PublishReadiness` | existing module | Home for new parity ReadinessCheck | Already wired into `doctor.ex` via `check_publish?` → `build_checks/4` |
| `release-please-action` | v4.1.3 (SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7`) as pinned in `release-please.yml` | Release PR creation and version bumping | Already configured with manifest mode + linked-versions |
| `googleapis/release-please` (manifest) | 17.x (shipped with action v4.1.3) | `linked-versions` plugin, lockstep version advancement | Already configured |

### CI Actions Used by clean-room-proof.yml (new — SHA-pin required)

| Action | Current SHA in repo | Purpose |
|--------|-------------------|---------|
| `actions/checkout@v4` | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` (already pinned) | Checkout monorepo on ubuntu; also used on macOS |
| `erlef/setup-beam` | `fc68ffb90438ef2936bbb3251622353b3dcb2f93` (already pinned) | Install Elixir on macOS runner for `mix crosswake.gen.shell` |
| `actions/setup-java@v4` | `c1e323688fd81a25caa38c78aa6df2d33d3e20d9` (already pinned in release-please.yml) | JDK 17 on ubuntu runner for `./gradlew` |

**SHA-pinning rule (house standard):** All new actions must be pinned to a full commit SHA with `# vX.Y.Z` comment. CVE-2025-30066 demonstrated that tag-based references are backdoorable. [CITED: .planning/research/REC-PIPELINE.md]

### Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Static `EEx.eval_file` for parity guard | Live `mix crosswake.gen.shell` subprocess | ~3 min BEAM startup for a 100 ms assertion; no structural benefit. |
| `clean-room-proof.yml` as separate file | Add jobs to `release-please.yml` | Separate file is cleaner (house pattern: `phaseNN-proof.yml`); easier to read CI graph. Either works architecturally since both are gated on same conditions. |
| `upToNextMajorVersion` in `.pbxproj` | `exactVersion` (current) | Exact pinning forces adopters to manually bump the scaffold on every patch/minor Crosswake release. `upToNextMajorVersion` flows patch/minor automatically. |

**Installation:** No new packages to install. This phase is all file edits and a new CI workflow.

---

## Package Legitimacy Audit

No external packages are installed in this phase. The phase is entirely:
- Elixir source edits (stdlib only)
- CI YAML authoring (new workflow file)
- Doc edits (Markdown)

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
BEFORE Phase 111
  mix crosswake.gen.shell ios   --> project.pbxproj  (broken: crosswake/ org, exactVersion 0.1.0)
  mix crosswake.gen.shell android --> app/build.gradle (broken: dev.crosswake:..., hardcoded 0.1.0)

AFTER Phase 111

  Application.spec(:crosswake)[:vsn]  <-- mix.exs @version "0.1.2" (single source of truth)
         |
         v
  gen.shell task render_template/3
    assigns: [capabilities:, local:, version: "0.1.2"]
         |
         +---> project.pbxproj.eex (@local == false branch)
         |       repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git"
         |       kind = upToNextMajorVersion; minimumVersion = 0.1.2
         |
         +---> app/build.gradle.eex (@local == false branch)
                 implementation("io.github.sztheory:crosswake-shell-core-android:0.1.2")

PARITY GUARD (per-merge, merge-blocking)
  mix crosswake.doctor --check-publish
    --> PublishReadiness.build_checks/4
          --> generator_coordinate_parity ReadinessCheck
                EEx.eval_file(ios_template, assigns: [local: false, version: vsn, capabilities: []])
                EEx.eval_file(android_template, assigns: [local: false, version: vsn, capabilities: []])
                asserts: correct org, correct GAV, version present, no local leaks
  
  mix test
    --> crosswake_gen_shell_test.exs
          same coordinate assertions on rendered output

CLEAN-ROOM PROOF (post-release only)
  release-please.yml: release_created == true
    +-- publish-hex
    +-- publish-ios-core   ]
    +-- publish-android-core ] all complete
                               |
                               v
                 clean-room-proof.yml
                   macOS runner:
                     mkdir -p $RUNNER_TEMP/proof-host
                     mix archive.install hex crosswake --version $VERSION
                     mix crosswake.gen.shell ios --target $RUNNER_TEMP/proof-host
                     swift build (resolves github.com/szTheory/crosswake-shell-core-ios v$VERSION)
                   ubuntu runner:
                     mix crosswake.gen.shell android --target $RUNNER_TEMP/proof-host
                     ./gradlew build (resolves io.github.sztheory:...:$VERSION)

RELEASE SEQUENCE (REL-01)
  1. Merge docs + template changes to main
  2. release-please opens Release PR for 0.1.2
  3. Human merges PR → release-please creates tag + GitHub Release
  4. publish-hex, publish-ios-core, publish-android-core fan out in parallel
  5. clean-room-proof runs after all three complete
  6. chore: commit removes "release-as": "0.1.2" from release-please-config.json
```

### Recommended Project Structure (delta — new/changed files only)

```
crosswake/
├── lib/mix/tasks/crosswake.gen.shell.ex       MODIFIED — add version assign to render_template/3
├── priv/templates/crosswake/shell/
│   ├── ios/CrosswakeShell.xcodeproj/
│   │   └── project.pbxproj.eex                MODIFIED — fix org + upToNextMajorVersion + @version
│   └── android/app/
│       └── build.gradle.eex                   MODIFIED — fix GAV + @version
├── lib/crosswake/doctor/publish_readiness.ex  MODIFIED — new ReadinessCheck + @allowed_docs add
├── test/mix/tasks/crosswake_gen_shell_test.exs MODIFIED — add coordinate assertions
├── .github/workflows/
│   └── clean-room-proof.yml                   NEW — post-release acceptance gate
├── guides/
│   ├── adoption.md                            MODIFIED — reframe §1 + add cross-link header
│   ├── install.md                             MODIFIED — add back-reference to adoption.md
│   ├── support_matrix.md                      MODIFIED — reconcile to published truth
│   └── CHANGELOG.md                           MODIFIED — add [0.1.2] entry
└── release-please-config.json                 MODIFIED — remove "release-as" pin post-cut
```

---

## EEx Template Mechanics

### How `render_template/3` passes assigns

[VERIFIED: direct source inspection `lib/mix/tasks/crosswake.gen.shell.ex` line 136-141]

Current implementation:

```elixir
defp render_template(template_path, capabilities, local) do
  template =
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

  EEx.eval_file(template, assigns: [capabilities: capabilities, local: local])
end
```

The `assigns:` keyword list maps directly to `@key` variables in the EEx template. The template currently receives `@capabilities` and `@local`.

**Required change:**

```elixir
defp render_template(template_path, capabilities, local) do
  template =
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

  version = fetch_version!()
  EEx.eval_file(template, assigns: [capabilities: capabilities, local: local, version: version])
end

defp fetch_version! do
  case Application.spec(:crosswake, :vsn) do
    nil ->
      Mix.raise("""
      Could not determine crosswake version from Application.spec(:crosswake, :vsn).
      When running mix crosswake.gen.shell from the library source checkout, the
      application may not be started. Run: mix app.start && mix crosswake.gen.shell ...
      Or install crosswake as a Hex dependency in your host project first.
      """)

    vsn ->
      to_string(vsn)
  end
end
```

**Why `Application.spec/2` can return nil from source checkout:** [ASSUMED]
`Application.spec(:crosswake, :vsn)` reads from the application registry. When `mix crosswake.gen.shell` runs inside the crosswake repo without an explicit `mix app.start`, the `:crosswake` OTP application may not be started and its spec may not be loaded. The `to_string()` call on `nil` produces `"nil"` which would silently appear in the generated coordinate — a subtle bug. The nil-guard prevents this.

**Alternative approach (simpler, no nil risk):** Since `mix.exs` defines `@version` as a module attribute, the task can also read it from `Mix.Project.config()[:version]` — this is always available inside a Mix task context regardless of whether the OTP app is started. However, D-12 specifies `Application.spec(:crosswake)[:vsn]` to mirror the installed-dep consumer perspective. The nil-guard bridges both cases.

**Practical recommendation:** Check `Application.spec(:crosswake, :vsn)` first; fall back to `Mix.Project.config()[:version]` if nil. This makes the task work both from source and from an installed dep:

```elixir
defp fetch_version! do
  version =
    Application.spec(:crosswake, :vsn) ||
    Keyword.get(Mix.Project.config(), :version)

  case version do
    nil ->
      Mix.raise("Could not determine crosswake version. Ensure the app is loaded or mix.exs @version is set.")
    vsn ->
      to_string(vsn)
  end
end
```

[ASSUMED — fallback to Mix.Project.config() is a planner's-discretion implementation detail within D-12's nil-guard requirement]

### iOS Template Change (project.pbxproj.eex)

**Current broken block** (lines 52-62): [VERIFIED: direct file inspection]

```
/* Begin XCRemoteSwiftPackageReference section */
    B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
        isa = XCRemoteSwiftPackageReference;
        repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git";
        requirement = {
            kind = exactVersion;
            version = 0.1.0;
        };
    };
/* End XCRemoteSwiftPackageReference section */
```

**Required replacement:**

```
/* Begin XCRemoteSwiftPackageReference section */
    B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
        isa = XCRemoteSwiftPackageReference;
        repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git";
        requirement = {
            kind = upToNextMajorVersion;
            minimumVersion = <%= @version %>;
        };
    };
/* End XCRemoteSwiftPackageReference section */
```

Changes: (1) `crosswake/` → `szTheory/` in org; (2) `exactVersion` → `upToNextMajorVersion`; (3) `version = 0.1.0` → `minimumVersion = <%= @version %>`.

The `MARKETING_VERSION = 1.0` field at line 326/350 (the adopter's own app version) is NOT changed — it is the host app's own version, not the dep coordinate, per Claude's Discretion.

### Android Template Change (app/build.gradle.eex)

**Current broken line** (line 54): [VERIFIED: direct file inspection]

```groovy
  implementation 'dev.crosswake:shell-core-android:0.1.0'
```

**Required replacement:**

```groovy
  implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")
```

Changes: (1) `dev.crosswake` → `io.github.sztheory` group ID; (2) `shell-core-android` → `crosswake-shell-core-android` artifact ID; (3) `0.1.0` → `<%= @version %>` dynamic version.

Note: `versionName "0.1.0"` at line 15 (the adopter's own Android app version in `defaultConfig`) is NOT changed — same reasoning as `MARKETING_VERSION` above.

---

## Published-Dep Parity Guard

### Existing `build_checks/4` pipeline

[VERIFIED: direct source inspection `lib/crosswake/doctor/publish_readiness.ex` lines 161-172]

```elixir
defp build_checks(cwd, support_matrix, inspection, opts) do
  [
    publish_parity_check(cwd, opts),
    companion_dependency_health_check(inspection),
    provider_adapter_readiness_check(support_matrix, inspection),
    notification_token_readiness_check(support_matrix, inspection),
    auth_session_predicate_readiness_check(support_matrix, inspection),
    native_shell_verification_gap_check(support_matrix, inspection),
    docs_support_parity_check(cwd, opts),
    proof_posture_check(support_matrix, inspection)
  ]
end
```

**Insertion point:** Append `generator_coordinate_parity_check(cwd)` as the second-to-last or last check. The check does not depend on `support_matrix` or `inspection`, only on `cwd` (to locate template files). Adding it to the list is the entire wiring — `build_checks/4` is already called by `run/1`, and `findings/1` already maps non-passing checks to the output stream.

### ReadinessCheck struct shape

[VERIFIED: direct source inspection `lib/crosswake/doctor/publish_readiness.ex` lines 44-91]

All `@enforce_keys` fields must be provided: `id`, `code`, `category`, `severity`, `result`, `blocking`, `message`, `hint`, `docs_reference`, `proof_class`, `rebuild_requirement`, `claim_scope`, `details`.

Use the `result_check/1` helper (lines 569-577) which sets `result: :pass/:fail`, `severity: :advisory/:error`, `blocking: not passed?` automatically from a `passed?` boolean:

```elixir
defp generator_coordinate_parity_check(cwd) do
  version = Application.spec(:crosswake, :vsn) |> to_string()
  
  ios_template = Path.join(cwd, "priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex")
  android_template = Path.join(cwd, "priv/templates/crosswake/shell/android/app/build.gradle.eex")

  {ios_ok?, ios_errors} = check_ios_template(ios_template, version)
  {android_ok?, android_errors} = check_android_template(android_template, version)

  errors = ios_errors ++ android_errors

  result_check(
    id: "generator.coordinate_parity",
    code: if(errors == [], do: "diag.generator.coordinate_parity_ok", else: "diag.generator.coordinate_parity_failed"),
    category: :generator_coordinate_parity,
    passed?: ios_ok? and android_ok?,
    message: if(errors == [],
      do: "generated native dep coordinates point at published registries with version #{version}",
      else: "generator coordinate parity failed: #{Enum.join(errors, "; ")}"
    ),
    hint: "Run mix crosswake.gen.shell ios|android (without --local) and inspect the generated dep coordinates.",
    docs_reference: "guides/install.md",
    proof_class: :merge_blocking,
    claim_scope: "Generated native dep coordinate truth",
    details: %{
      version: version,
      ios_template: ios_template,
      android_template: android_template,
      errors: errors
    }
  )
end

defp check_ios_template(template_path, version) do
  rendered = EEx.eval_file(template_path, assigns: [local: false, version: version, capabilities: []])
  errors =
    []
    |> require_truth(rendered =~ "github.com/szTheory/crosswake-shell-core-ios", "iOS URL missing szTheory org")
    |> require_truth(rendered =~ version, "iOS template missing version #{version}")
    |> require_truth(rendered =~ "upToNextMajorVersion", "iOS template must use upToNextMajorVersion")
    |> require_truth(not (rendered =~ "XCLocalSwiftPackageReference"), "iOS non-local branch must not emit XCLocalSwiftPackageReference")
    |> require_truth(not (rendered =~ "crosswake/crosswake-shell-core-ios"), "iOS template must not reference old crosswake/ org")
  {errors == [], Enum.reverse(errors)}
end

defp check_android_template(template_path, version) do
  rendered = EEx.eval_file(template_path, assigns: [local: false, version: version, capabilities: []])
  errors =
    []
    |> require_truth(rendered =~ "io.github.sztheory:crosswake-shell-core-android", "Android GAV missing io.github.sztheory")
    |> require_truth(rendered =~ version, "Android template missing version #{version}")
    |> require_truth(not (rendered =~ "dev.crosswake"), "Android template must not reference dev.crosswake group")
    |> require_truth(not (rendered =~ "project(':crosswake"), "Android non-local branch must not reference local project")
  {errors == [], Enum.reverse(errors)}
end
```

Note: `require_truth/3` already exists in the module (lines 610-611) — reuse it directly.

### `@allowed_docs` whitelist addition

[VERIFIED: direct source inspection `lib/crosswake/doctor/publish_readiness.ex` lines 16-25]

Current list: `["guides/support_matrix.md", "guides/compatibility.md", "guides/companions.md", "guides/commerce.md", "guides/native_shell.md", "guides/capabilities.md", "guides/install.md", "CHANGELOG.md"]`

Missing: `"guides/adoption.md"` (already a `mix.exs` extra; the whitelist inconsistency is the bug to fix per D-03a).

Add `"guides/adoption.md"` to the list. No other changes to `docs_support_parity_check/2` — it already uses the whitelist correctly.

---

## Test Assertions (crosswake_gen_shell_test.exs)

### What already exists

[VERIFIED: direct source inspection `test/mix/tasks/crosswake_gen_shell_test.exs`]

The test already:
- Renders iOS scaffold to `tmp_dir!()` and reads `ios_project` (the `.pbxproj`)
- Renders Android scaffold to `tmp_dir!()` and reads `android_app_build`
- Asserts `ios_project =~ "XCRemoteSwiftPackageReference"` and `refute =~ "XCLocalSwiftPackageReference"` (line 55-56)
- Has `--local` flag test (line 191+) that asserts local vs remote reference

### Assertions to add (per D-02b)

In the "generates iOS scaffold" test, after the existing assertions on `ios_project`:

```elixir
# GEN-01/GEN-02: verify correct published coordinates
ios_version = Application.spec(:crosswake, :vsn) |> to_string()
assert File.read!(ios_project) =~ "github.com/szTheory/crosswake-shell-core-ios"
assert File.read!(ios_project) =~ "upToNextMajorVersion"
assert File.read!(ios_project) =~ ios_version
refute File.read!(ios_project) =~ "crosswake/crosswake-shell-core-ios"
refute File.read!(ios_project) =~ "exactVersion"
```

In the "generates Android scaffold" test, after existing assertions on `android_app_build`:

```elixir
# GEN-01/GEN-02: verify correct published coordinates
android_version = Application.spec(:crosswake, :vsn) |> to_string()
assert File.read!(android_app_build) =~ "io.github.sztheory:crosswake-shell-core-android"
assert File.read!(android_app_build) =~ android_version
refute File.read!(android_app_build) =~ "dev.crosswake"
```

In the `--local` test, add refutations to confirm local branch does NOT include remote coordinates:

```elixir
refute File.read!(ios_project) =~ "szTheory/crosswake-shell-core-ios"
refute File.read!(android_app_build) =~ "io.github.sztheory"
```

---

## Clean-Room CI Lane

### Job design

[ASSUMED — concrete implementation within Claude's Discretion per D-01]

The clean-room proof needs two runners (macOS for `swift build`, ubuntu for `gradle build`). These can be two separate jobs or a matrix — two jobs is cleaner for CI graph readability and allows independent failure reporting.

Key constraints:
- Must NOT check out the monorepo into a path where `packages/` is accessible to the build tools
- Must use `mix archive.install hex crosswake --version $VERSION` to install the exact just-cut version
- Must generate into `$RUNNER_TEMP` which is outside any checkout
- Must pin to `needs.release-please.outputs.version` (not `latest`)

```yaml
name: Clean-Room Proof

on:
  workflow_run:
    workflows: ["Release Please"]
    types: [completed]

# Alternate wiring per D-01a: could also be jobs appended to release-please.yml.
# Separate file follows the phaseNN-proof.yml house pattern.
# If separate file: use workflow_run trigger with `if: github.event.workflow_run.conclusion == 'success'`
# and gate on release_created output exposed via workflow_run artifacts.
# Simpler: append as jobs to release-please.yml under needs: [release-please, publish-hex, publish-ios-core, publish-android-core].
# The CONTEXT.md specifies D-01a calls for new clean-room-proof.yml following phaseNN-proof.yml pattern.
# BUT: separate file cannot easily access `needs.release-please.outputs.*` from another workflow.
# Resolution: append as jobs in release-please.yml. This is architecturally equivalent to
# phase75-closeout-gate.yml being a separate file — use whichever the planner judges cleaner.
# See Open Questions #1.
```

**Recommended: append as jobs in `release-please.yml`** to avoid the workflow_run output-passing problem. The "separate file" pattern (phaseNN-proof.yml) is for PR merge-gating, not release-time post-publish gates.

```yaml
  clean-room-proof-ios:
    name: Clean-room proof — iOS swift build
    needs: [release-please, publish-hex, publish-ios-core, publish-android-core]
    if: ${{ needs.release-please.outputs.releases_created == 'true' }}
    runs-on: macos-15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force

      - name: Install crosswake archive at just-cut version
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: mix archive.install hex crosswake $VERSION --force

      - name: Generate iOS shell outside monorepo
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          TARGET="$RUNNER_TEMP/clean-room-proof-ios"
          mkdir -p "$TARGET"
          mix crosswake.gen.shell ios --target "$TARGET"

      - name: swift build (resolves published dep)
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          PROJECT_ROOT="$RUNNER_TEMP/clean-room-proof-ios/native/ios/crosswake_shell"
          cd "$PROJECT_ROOT"
          # Retry for tag propagation clock skew (near-instant but add short retry)
          for i in 1 2 3; do
            swift build && break
            echo "swift build attempt $i failed, retrying in 30s..."
            sleep 30
          done

  clean-room-proof-android:
    name: Clean-room proof — Android gradle build
    needs: [release-please, publish-hex, publish-ios-core, publish-android-core]
    if: ${{ needs.release-please.outputs.releases_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict

      - uses: actions/setup-java@c1e323688fd81a25caa38c78aa6df2d33d3e20d9 # v4.8.0
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force

      - name: Install crosswake archive at just-cut version
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: mix archive.install hex crosswake $VERSION --force

      - name: Generate Android shell outside monorepo
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          TARGET="$RUNNER_TEMP/clean-room-proof-android"
          mkdir -p "$TARGET"
          mix crosswake.gen.shell android --target "$TARGET"

      - name: gradle build with Maven Central propagation polling
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          PROJECT_ROOT="$RUNNER_TEMP/clean-room-proof-android/native/android/crosswake_shell"
          cd "$PROJECT_ROOT"
          chmod +x gradlew
          # Maven Central propagation can take up to ~30 min.
          # Mirror the existing publish-hex hex.pm poll pattern.
          MAX_ATTEMPTS=40
          DELAY=45
          for i in $(seq 1 $MAX_ATTEMPTS); do
            if ./gradlew build --no-daemon; then
              echo "gradle build succeeded on attempt $i"
              exit 0
            fi
            echo "Attempt $i/$MAX_ATTEMPTS: gradle build failed (Maven Central may not have propagated yet). Retrying in ${DELAY}s..."
            sleep $DELAY
          done
          echo "gradle build failed after $MAX_ATTEMPTS attempts (~30 min). Maven Central propagation timeout."
          exit 1
```

**Note on `mix archive.install` from clean-room:** This installs the crosswake Mix archive globally on the runner, making `mix crosswake.gen.shell` available as a Mix task. The generated files land in `$RUNNER_TEMP/clean-room-proof-*` which has no access to the monorepo's `packages/` directory. [ASSUMED — `mix archive.install hex crosswake $VERSION` is the correct idiom; verify that `gen.shell` is exposed as a Mix task in the archive, not just as a dep task]

**Alternative if archive doesn't expose tasks:** Check out the monorepo, `cd $RUNNER_TEMP` to escape it, and run `mix --no-start crosswake.gen.shell` referencing the monorepo's `mix.exs` explicitly. But this defeats clean-room isolation. The cleaner approach: use `MIX_HOME` + `mix archive.install` per standard Mix archive conventions. [ASSUMED]

### Maven Central propagation timing

[CITED: .planning/research/PITFALLS.md Pitfall 1, .planning/research/SUMMARY.md §Architecture Approach]

Maven Central propagation after `publishToMavenCentral` (Vanniktech, `automaticRelease=true`) can take up to 30 minutes before artifacts appear in `mavenCentral()` resolution. The existing `publish-hex` job polls hex.pm for up to 6 minutes (36 × 10s). For Maven Central, use a longer patience window: 40 attempts × 45s = 30 minutes maximum.

---

## Doc Reconciliation

### adoption.md required changes

[VERIFIED: direct file inspection — adoption.md §1]

Current contradictory sentence (§1 "Integrate the Crosswake Shell"):
> "Avoid generating host-owned shell code. Instead, rely on standalone dependencies to eliminate the 'eject trap'."

This directly contradicts the product thesis: `mix crosswake.gen.shell` IS the install path. The sentence was written before the v5.0 standalone-package architecture was complete.

**D-03b reframe:** Change the framing so "generate the thin wrapper, let it resolve published deps" is the message, not "avoid generation":

New §1 language (within D-03b's intent; exact wording is Claude's Discretion):
> "The generated shell is a **thin, host-owned wrapper** — a scaffold you own and review. Its native dependencies (SPM for iOS, Maven for Android) resolve automatically from **published registries** (`github.com/szTheory/crosswake-shell-core-ios` and Maven Central `io.github.sztheory:crosswake-shell-core-android`), not from vendored or monorepo-local paths. The 'eject trap' is eliminated by the published-core architecture: you own the thin wrapper, not the library internals."

Add header note pointing to `install.md`:
```markdown
> For the definitive install sequence, see [guides/install.md](install.md).
```

**D-03c cross-link in `install.md`:** Add one line near the top:
```markdown
> See [guides/adoption.md](adoption.md) for offline-sync architecture context and the rationale for the generated shell pattern.
```

### CHANGELOG.md requirements

The existing `PublishReadiness.published_hex_truth?/1` check (line 668-672) requires:
- `"## [0.1.0]"` section present
- `"## [Unreleased]"` section with 4 required subsections

For 0.1.2: add a `## [0.1.2]` section. The check at line 207-209 verifies `changelog =~ "[#{expected_version}]"` — so `## [0.1.2]` must be present when `@version "0.1.2"` is set.

The `no_false_shipped_claims?/1` check (line 674-685) verifies 5 specific strings are absent — verify the reconciled CHANGELOG.md does not introduce any of: `"StoreKit provider adapter shipped"`, `"Play Billing provider adapter shipped"`, `"Chimeway delivery is supported"`, `"standalone native shell packages are shipped"`, `"full Sigra machinery is shipped"`.

---

## Release Sequence (REL-01)

### Pre-flight checklist before merging the release PR

The 4 human-UAT items from `110-HUMAN-UAT.md` are prerequisites. All are currently `[pending]`:
1. Android publish fire-drill (validated-upload → drop) — confirms credentials work
2. Lockstep-truth CI lane — confirms version coordinates agree on 0.1.0 before bumping
3. GPG public key on two keyservers
4. Sonatype namespace `io.github.sztheory` verified

These must pass before the release PR for 0.1.2 is merged, or the publish jobs will fail.

### Release PR mechanics

`release-please-config.json` already has `"release-as": "0.1.2"` for the root package. When the release PR is merged, release-please will:
1. Create git tag (currently this would be component-prefixed — see manifest mode tag behavior below)
2. Create GitHub Release
3. Emit `releases_created: true`, `tag_name`, `version: "0.1.2"` as job outputs

**Note on tag_name in manifest mode:** [VERIFIED: `release-please.yml` line 38-42 comments]

The existing workflow already handles this: it uses `releases_created` (plural) as the gate (not `release_created` singular), and passes `tag_name` from the root-package output to downstream jobs. The comment in the workflow explains: "For the root package (path '.'), release-please-action v4 writes per-path outputs UNPREFIXED." Confirm `tag_name` is the bare root tag (e.g., `v0.1.2`) not a component-prefixed one before using it in `publish-ios-core`.

### Post-cut `release-as` pin removal (D-04)

Immediately after 0.1.2 ships and all CI jobs are green, commit:

```json
// release-please-config.json — remove "release-as" from root package
{
  "packages": {
    ".": {
      "component": "hex",
      "release-type": "elixir",
      // "release-as": "0.1.2",   <-- REMOVE THIS LINE
      ...
    }
  }
}
```

Commit message: `chore: remove release-as pin after 0.1.2 ships`

This is the #1 post-bootstrap footgun: leaving `"release-as": "0.1.2"` in the config causes every subsequent release PR to propose 0.1.2 indefinitely. [CITED: .planning/research/REC-PIPELINE.md Footgun 2]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version propagation into templates | Custom version-file reader or constant | `Application.spec(:crosswake, :vsn)` + `Mix.Project.config()[:version]` fallback | Derives from the authoritative runtime source, not a copied constant. LiveView Native pattern. |
| Coordinate parsing/validation | Regex-parse the rendered `.pbxproj` | `EEx.eval_file` the template itself with test assigns | The template is the source of truth; rendering it IS the parse. |
| Maven Central propagation wait | Fixed `sleep 1800` | Exponential backoff / polling loop mirroring existing `publish-hex` hex.pm poll | Adapts to actual propagation time; doesn't burn CI minutes unnecessarily. |
| iOS tag availability wait | Fixed sleep | Short retry loop (3 attempts × 30s) | Git tags are near-instant post-push; clock skew is the only concern. |

**Key insight:** This phase has no novel infrastructure problems. Every hard problem (lockstep versioning, propagation waiting, sha-pinning, parity checking) is already solved in the existing codebase. The work is surgical application of established patterns to new files.

---

## Common Pitfalls

### Pitfall 1: `nil` version string silently appearing in generated output

**What goes wrong:** `Application.spec(:crosswake, :vsn)` returns `nil` from a source checkout when the OTP app is not started. `to_string(nil)` produces `"nil"`. The generated `.pbxproj` gets `minimumVersion = nil;` — syntactically valid `.pbxproj` content, no render error, but obviously wrong.

**Why it happens:** EEx rendering succeeds regardless of the assign value. No error is raised. The test may pass if it only checks that a version string is present without checking it's non-nil. [ASSUMED: depends on how the test asserts version]

**How to avoid:** Nil-guard in `fetch_version!/0` before passing to `assigns:`. Raise `Mix.raise/1` with a clear message if nil. Also add test assertion: `refute File.read!(ios_project) =~ "minimumVersion = nil"`.

**Warning signs:** Generated `.pbxproj` contains `minimumVersion = nil` or `= ;`.

### Pitfall 2: Clean-room job accessing monorepo `packages/` directory

**What goes wrong:** If the Elixir `gen.shell` task is run from within the monorepo checkout (using a `--target` inside the checkout), and if any local SPM/Gradle config resolution searches parent directories, the generated project could accidentally resolve against `packages/crosswake-shell-core-ios` or `packages/crosswake-shell-core-android` rather than the published registries.

**Why it happens:** SwiftPM and Gradle both search parent directories for local package overrides in some configurations.

**How to avoid:** Generate into `$RUNNER_TEMP/...` (outside the monorepo checkout). Do NOT use `--target tmp/...` inside the checkout. The `$RUNNER_TEMP` directory is guaranteed to be outside the checkout path on GitHub Actions runners. [CITED: .planning/phases/111-generator-rewire-clean-room-proof-release/111-CONTEXT.md D-01a]

### Pitfall 3: Leaving `"release-as": "0.1.2"` in config permanently

**What goes wrong:** Every Release PR after 0.1.2 will also propose version 0.1.2. The PR is immediately in conflict with the manifest that now records 0.1.2 as already shipped. This produces a non-obvious release-please error and blocks all future releases.

**Why it happens:** Forgetting to commit the removal immediately after the cut.

**How to avoid:** Include the `chore: remove release-as pin` commit as a Wave 4 task in the plan. It must be merged to main after the 0.1.2 release is confirmed successful. [CITED: .planning/research/REC-PIPELINE.md Footgun 2, CONTEXT.md D-04]

### Pitfall 4: Generator parity check failing because `capabilities` assign is missing

**What goes wrong:** When `EEx.eval_file` is called in the parity guard with `assigns: [local: false, version: vsn, capabilities: []]`, if the template tries to iterate over `@capabilities` and the assign is omitted, EEx raises a `KeyError` rather than returning a useful parity check failure.

**Why it happens:** The parity guard is a simplified `render_template/3` — it must provide all three assigns (`capabilities`, `local`, `version`) even if `capabilities` is just `[]` for the parity assertion.

**How to avoid:** Always pass `capabilities: []` as the assigns value in the parity guard's `EEx.eval_file` calls. [VERIFIED: `render_template/3` currently passes `assigns: [capabilities: capabilities, local: local]` — three assigns required after this phase]

### Pitfall 5: `adoption.md` edit accidentally introducing a false claim

**What goes wrong:** The reframe of §1 could accidentally state that the generated shell "never needs to be regenerated" or "resolves automatically without any setup", overstating the installed-dep story.

**Why it happens:** Editing for clarity in one direction while missing a nuance.

**How to avoid:** D-03b is explicit: reframe (don't delete), and "the eject trap is eliminated by the published-core architecture." Do not claim `gen.shell` can be run without Crosswake installed. Do not claim native deps resolve without adding the Hex dep first. Run `mix doctor --check-publish` after the edit to confirm no false claims are introduced.

---

## Runtime State Inventory

This is a template-rewire and doc-reconciliation phase, not a rename/migration. The only "runtime state" concern is the `release-please-config.json`'s `"release-as"` pin, which must be removed post-cut.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None | — |
| Live service config | Hex 0.1.0 currently published; 0.1.2 will be the new release | publish-hex job handles; no manual action |
| OS-registered state | None | — |
| Secrets/env vars | 8 secrets required by Phase 110 SETUP.md — all must be provisioned before cut | Human precondition; see 110-HUMAN-UAT.md |
| Build artifacts | `release-please-config.json` has `"release-as": "0.1.2"` pin | Must remove in chore: commit post-cut (D-04) |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All Elixir tasks | ✓ | 1.19.5 (`.tool-versions`) | — |
| OTP | All Elixir tasks | ✓ | 27.3 (`.tool-versions`) | — |
| `EEx` | parity guard, gen.shell | ✓ | stdlib | — |
| `mix crosswake.gen.shell` | clean-room proof | ✓ (in-repo; archive install for CI) | current | — |
| macOS 15 runner | `swift build` in clean-room proof | ✓ (GitHub-hosted) | macos-15 | — |
| ubuntu runner | `gradle build` in clean-room proof | ✓ (GitHub-hosted) | ubuntu-latest | — |
| JDK 17 (Temurin) | `gradle build` | ✓ (via `actions/setup-java`) | 17 | — |
| Published iOS mirror tag `v0.1.2` | clean-room `swift build` | Phase 110 wired; depends on UAT passing | — | — |
| Published Maven artifact `io.github.sztheory:...:0.1.2` | clean-room `gradle build` | Phase 110 wired; depends on UAT passing | — | — |

**Missing dependencies with no fallback:** The clean-room proof is blocked until Phase 110 UAT items 1-4 are exercised. This is expected (D-01d): the proof's first green run happens post-0.1.2 cut.

---

## Validation Architecture

> Nyquist validation is ENABLED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GEN-01 | `Application.spec(:crosswake)[:vsn]` is the version in generated coordinates — no literal | Unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ (add assertions) |
| GEN-01 | Nil-guard raises helpful error when version is nil | Unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ (add test case) |
| GEN-02 | iOS non-local branch: `szTheory` org, `upToNextMajorVersion`, `@version` | Unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ (add assertions) |
| GEN-02 | Android non-local branch: `io.github.sztheory` GAV, `@version` | Unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ (add assertions) |
| GEN-02 | `--local` branch: still emits `XCLocalSwiftPackageReference` / `project(':crosswake-shell-core-android')` (regression guard) | Unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ (existing test, verify still passes) |
| PROOF-01 | `swift build` exits 0 on macOS runner with published dep | CI (post-release) | `clean-room-proof-ios` job in `release-please.yml` | ❌ Wave 0 (new job) |
| PROOF-01 | `gradle build` exits 0 on ubuntu runner with published dep | CI (post-release) | `clean-room-proof-android` job in `release-please.yml` | ❌ Wave 0 (new job) |
| PROOF-02 | `mix doctor --check-publish` fails if iOS template emits wrong org or local reference | Unit + doctor check | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` + `mix crosswake.doctor --check-publish` | ✅ (add assertions + new ReadinessCheck) |
| PROOF-02 | `mix doctor --check-publish` fails if Android template emits wrong GAV or local reference | Unit + doctor check | Same | ✅ (add assertions + new ReadinessCheck) |
| PROOF-02 | `mix doctor --check-publish` passes when coordinates are correct | Unit + doctor check | Same | ✅ (add assertions + new ReadinessCheck) |
| DOCS-01 | `guides/adoption.md` in `@allowed_docs` — `docs_support_parity_check` passes | Doctor check | `mix crosswake.doctor --check-publish` | ✅ (add to whitelist) |
| DOCS-01 | No false-shipped-claims strings in CHANGELOG.md | Doctor check | `mix crosswake.doctor --check-publish` (via `no_false_shipped_claims?`) | ✅ (verify after doc edit) |
| DOCS-01 | `CHANGELOG.md` has `## [0.1.2]` section | Doctor check | `mix crosswake.doctor --check-publish` (via `publish_parity_check`) | ✅ (add section to CHANGELOG) |
| REL-01 | Hex 0.1.2 published | CI (release) | `publish-hex` job Hex.pm poll exits 0 | ✅ (existing job) |
| REL-01 | iOS mirror tag `v0.1.2` on `szTheory/crosswake-shell-core-ios` | CI (release) | `publish-ios-core` job exits 0 | ✅ (existing job from Phase 110) |
| REL-01 | Android `io.github.sztheory:crosswake-shell-core-android:0.1.2` on Maven Central | CI (release) | `publish-android-core` job exits 0 | ✅ (existing job from Phase 110) |
| REL-01 | `release-as` pin removed from `release-please-config.json` | Manual verification | `grep "release-as" release-please-config.json` returns no match | ✅ (file edit post-cut) |

### Sampling Rate

- **Per task commit:** `mix test test/mix/tasks/crosswake_gen_shell_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host && mix crosswake.doctor --check-publish`
- **Phase gate:** Full suite green + all CI jobs green + Hex 0.1.2 verified on hex.pm before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `clean-room-proof-ios` job in `.github/workflows/release-please.yml` — covers PROOF-01 (iOS)
- [ ] `clean-room-proof-android` job in `.github/workflows/release-please.yml` — covers PROOF-01 (Android)
- [ ] `generator_coordinate_parity_check/1` function in `publish_readiness.ex` — covers PROOF-02

*(Existing test infrastructure in `crosswake_gen_shell_test.exs` is present; only additional assertions and the nil-guard test case are needed — no new test file required.)*

---

## Security Domain

> `security_enforcement` is not explicitly disabled. This section is required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Yes (template assigns) | EEx `assigns:` keyword list; no user-controlled input enters the template rendering path |
| V6 Cryptography | No (signing is Phase 110 concern) | — |
| V10 Malicious Code (supply chain) | Yes (new CI job installs `hex crosswake` from registry) | Archive install pins to exact version; GitHub Actions SHA-pinned per CVE-2025-30066 |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious `hex crosswake` archive installed at wrong version | Tampering | Pin to `needs.release-please.outputs.version` explicitly; do not use `latest` |
| Tag hijacking on `szTheory/crosswake-shell-core-ios` mirror | Spoofing | No force-push; tag protection on mirror repo; tag only created once per release (Phase 110 pattern) |
| Backdoored GitHub Actions via tag reference | Tampering | SHA-pin all actions per CVE-2025-30066; house standard already in place in `release-please.yml` |
| EEx injection via version string | Tampering | `Application.spec/2` returns an OTP vsn charlist; `to_string/1` produces a safe semver string; no user input enters the assigns path |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `exactVersion` SwiftPM pinning | `upToNextMajorVersion` / `from:` | This phase | Adopters receive patch/minor updates without regenerating the shell |
| Hardcoded `dev.crosswake:shell-core-android:0.1.0` | Dynamic `io.github.sztheory:crosswake-shell-core-android:<%= @version %>` | This phase | Eliminates satellite version drift (LiveView Native bug pattern) |
| 404 iOS URL `github.com/crosswake/...` | Correct `github.com/szTheory/crosswake-shell-core-ios.git` | This phase | First time the generated URL is actually resolvable |
| No parity guard | `generator_coordinate_parity` ReadinessCheck (merge-blocking) | This phase | Structural analog to v10.0 `brand-structural` drift gate |
| adoption.md §1 discourages generation | Reframed to: generate the thin wrapper, deps resolve from published registries | This phase | Removes the documentation contradiction |

**Deprecated/outdated patterns this phase eliminates:**
- `exactVersion` in iOS template: replaced with `upToNextMajorVersion`/`minimumVersion`
- `crosswake/` org in iOS URL: replaced with `szTheory/`
- `dev.crosswake:shell-core-android` group ID: replaced with `io.github.sztheory:crosswake-shell-core-android`
- Hardcoded `0.1.0` version in templates: replaced with `<%= @version %>`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Application.spec(:crosswake, :vsn)` returns nil from source checkout when OTP app is not started | EEx Template Mechanics | If it always returns the version from Mix project metadata, the nil-guard is unnecessary but harmless |
| A2 | `Mix.Project.config()[:version]` is always available inside a Mix task, regardless of OTP app state | EEx Template Mechanics | If it can also be nil, both fallback paths need a different approach (e.g., parse mix.exs directly) |
| A3 | `mix archive.install hex crosswake $VERSION` makes `mix crosswake.gen.shell` available on the CI runner without a checkout | Clean-Room CI Lane | If gen.shell is not exposed via archive (only available as a dep task), the clean-room proof needs a different scaffolding approach (e.g., shallow checkout + cd $RUNNER_TEMP pattern) |
| A4 | `clean-room-proof` jobs as appended jobs in `release-please.yml` (not a separate file) is the correct architectural choice given output-passing constraints | Clean-Room CI Lane | If a separate workflow file approach with `workflow_run` trigger is preferred for organizational clarity, the job structure works but output-passing requires a different mechanism |
| A5 | The `@capabilities` assign must be provided as `[]` (not omitted) when calling `EEx.eval_file` in the parity guard | Parity Guard | If templates guard against missing @capabilities, it could be omitted safely |
| A6 | The `tag_name` output from `release-please` job in manifest mode is the bare root package tag (e.g., `v0.1.2`) and is safe to use for `publish-ios-core` mirror push | Release Sequence | If it is component-prefixed, the iOS mirror tag would be wrong and SwiftPM would not resolve it — confirmed mitigated by existing workflow comment at line 38-42 noting root package outputs are UNPREFIXED |

**If this table is empty:** All claims in this research were verified or cited. Since A1-A6 are present, the planner should consider implementation notes that guard against these assumptions.

---

## Open Questions

1. **`clean-room-proof.yml` as separate file vs. appended jobs in `release-please.yml`**
   - What we know: CONTEXT.md D-01a says "New `clean-room-proof.yml` (follows the `phaseNN-proof.yml` house precedent)". But `phaseNN-proof.yml` is for PR-merge-gating; separate workflow files cannot easily access `needs.release-please.outputs.*` from another workflow.
   - What's unclear: Whether the CONTEXT.md's "`clean-room-proof.yml`" naming is prescriptive about a separate file or just a naming suggestion for the logical concept.
   - Recommendation: Append as jobs in `release-please.yml` for output-passing simplicity. Use the name `clean-room-proof-ios` / `clean-room-proof-android` as job names within that file. The separate-file pattern (like `phase75-closeout-gate.yml`) works for PR gates but not for release-time output-dependent jobs without extra artifact-passing machinery.

2. **`mix archive.install` approach for clean-room proof vs. shallow checkout + cd**
   - What we know: `mix archive.install hex crosswake $VERSION` is the standard way to make a Hex package's Mix tasks available globally.
   - What's unclear: Whether `gen.shell` is exposed as a global Mix task via the archive (it uses `use Mix.Task` which should make it global) vs. only available when `crosswake` is a dep in a Mix project.
   - Recommendation: Test locally before implementing the CI job: `mix archive.install hex crosswake 0.1.0 && mix crosswake.gen.shell ios --help`. If it works, use archive install. If not, use a tmp Phoenix project with `crosswake` as a dep instead.

3. **`generator_coordinate_parity_check` access to template path from `cwd`**
   - What we know: The parity guard receives `cwd` (the project root). Templates are at `priv/templates/crosswake/shell/ios/...` relative to the project root.
   - What's unclear: Whether `EEx.eval_file` with an absolute path derived from `cwd` works when called from the doctor context (not inside a running app where `Application.app_dir/2` resolves priv). Using `Path.join(cwd, "priv/templates/...")` directly should work fine for the static check.
   - Recommendation: Use `Path.join(cwd, "priv/templates/crosswake/shell/...")` in the parity guard rather than `Application.app_dir(:crosswake, ...)` — the latter requires the OTP app to be loaded and its priv dir to be locatable.

---

## Sources

### Primary (HIGH confidence)

- Direct file inspection: `lib/mix/tasks/crosswake.gen.shell.ex` — confirmed `render_template/3` signature and existing assigns
- Direct file inspection: `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — confirmed broken org/kind/version at lines 56-60
- Direct file inspection: `priv/templates/crosswake/shell/android/app/build.gradle.eex` — confirmed broken GAV at line 54
- Direct file inspection: `lib/crosswake/doctor/publish_readiness.ex` — confirmed `ReadinessCheck` struct, `build_checks/4` pipeline, `result_check/1` helper, `require_truth/3`, `@allowed_docs` list
- Direct file inspection: `lib/crosswake/doctor/doctor.ex` — confirmed `check_publish?` → `PublishReadiness.run/1` wiring
- Direct file inspection: `test/mix/tasks/crosswake_gen_shell_test.exs` — confirmed existing test structure, tmp_dir! helper, existing assertions
- Direct file inspection: `.github/workflows/release-please.yml` — confirmed manifest-mode output names, `releases_created` gate, existing publish job shapes, existing SHA pins
- Direct file inspection: `.github/workflows/phase79-proof.yml` — confirmed house proof-lane pattern
- Direct file inspection: `.github/workflows/phase75-closeout-gate.yml` — confirmed house closeout-gate pattern
- Direct file inspection: `release-please-config.json` — confirmed `"release-as": "0.1.2"` is present, linked-versions configured
- Direct file inspection: `.release-please-manifest.json` — confirmed `"." : "0.1.0"` baseline
- Direct file inspection: `mix.exs` — confirmed `@version "0.1.0" # x-release-please-version`
- Direct file inspection: `guides/adoption.md` — confirmed contradictory sentence in §1
- Prior phase research: `.planning/research/SUMMARY.md`, `STACK.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `REC-PIPELINE.md` — HIGH confidence, all grounded in repo file inspection
- `.planning/phases/111-generator-rewire-clean-room-proof-release/111-CONTEXT.md` — locked decisions D-01 through D-04 + carried-forward from Phase 110

### Secondary (MEDIUM confidence)

- `.planning/research/REC-PIPELINE.md` — release-please footguns, SHA-pinning, `"release-as"` removal sequencing [repo-local, grounded in oarlock live pipeline evidence]

### Tertiary (LOW confidence — flag for validation)

- A1-A6 in Assumptions Log above — implementation details not verified via official docs or tool output

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all pre-existing; no new packages; confirmed via direct file inspection
- Architecture: HIGH — all files inspected; exact broken lines known; exact replacement text specified
- Pitfalls: HIGH (critical pitfalls 1-3) / MEDIUM (pitfalls 4-5)
- EEx mechanics: HIGH (existing usage confirmed) / ASSUMED (nil behavior from source checkout)
- Clean-room CI: HIGH (pattern confirmed from existing proof lanes) / ASSUMED (archive install approach)

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable domain; no fast-moving dependencies introduced)
