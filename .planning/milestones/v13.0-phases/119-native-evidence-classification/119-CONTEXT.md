# Phase 119: Native Evidence Classification - Context

**Gathered:** 2026-06-19T19:28:04Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 119 makes native proof labels impossible to misread before Crosswake captures or publishes native collateral. It records the v13 native evidence-label decision, reconciles checked-in iOS/Android hosts and native docs to that decision, and adds DRIFT-03 so stale native coordinates or missing evidence labels cannot return.

This phase owns evidence classification, native documentation truth, checked-in host coordinate strategy, and a mechanical native evidence drift guard. It does not own screenshot/video capture, artifact packaging, troubleshooting guide expansion, new native capabilities, physical-device proof, provider authority, app-store readiness, DASH-01, or NTV-01.

</domain>

<decisions>
## Implementation Decisions

### Checked-In Host Strategy

- **D-01:** Promote the checked-in iOS and Android hosts to **published-coordinate defaults**. The checked-in iOS host should use the published SwiftPM mirror (`https://github.com/szTheory/crosswake-shell-core-ios.git`) at the Crosswake package version instead of a silent `XCLocalSwiftPackageReference`. The checked-in Android host should use Maven Central `io.github.sztheory:crosswake-shell-core-android:<current Crosswake version>` instead of `dev.crosswake:shell-core-android:0.1.0`.
- **D-02:** Preserve `--local` as the explicit maintainer/development path for source checkout iteration. Local Swift package references and Gradle project dependencies are valid only when the user deliberately asks for local generation or maintainer docs name the path as local-dev proof.
- **D-03:** Do not create a second pair of checked-in public-coordinate hosts or demote public proof to generated-only artifacts. A hybrid/two-host approach would increase drift and make Phase 120 captions harder to understand. One checked-in host pair should match the adopter-facing default; `--local` covers development.
- **D-04:** A successful checked-in host build or simulator/emulator launch proves only the labeled path: coordinate mode plus platform execution environment. It must not imply physical-device support, camera/media-upload support, provider authority, app-store readiness, or merge-blocking native support unless separate promotion criteria and evidence exist.

### Evidence Label Contract

- **D-05:** Use a strict dimensional taxonomy. Native evidence must always keep these dimensions separate:
  - **Proof class:** merge-blocking proof, advisory evidence, verification-required.
  - **Coordinate mode:** generated public-coordinate proof, checked-in public-coordinate proof, local-dev proof.
  - **Execution environment:** JVM hermetic proof, simulator evidence, emulator evidence, device evidence.
  - **Action status:** rebuild-required where native or companion artifacts must be rebuilt.
- **D-06:** Add `checked-in public-coordinate proof` as the explicit label for checked-in iOS/Android hosts after they use published SwiftPM/Maven coordinates by default. Keep `generated public-coordinate proof` for `mix crosswake.gen.shell` non-local output. Keep `local-dev proof` for `--local` and any intentionally local maintainer path.
- **D-07:** Labels must include what the evidence proves and what it does not prove. Examples:
  - `generated public-coordinate proof`: a generated adopter-facing path resolves published SwiftPM/Maven/Hex coordinates; it does not prove checked-in hosts use those coordinates.
  - `checked-in public-coordinate proof`: the checked-in example host resolves published native shell packages by default; it does not prove physical devices, app stores, or provider authority.
  - `JVM hermetic proof`: Android logic passed deterministic JVM-level CI; it is not emulator evidence or physical-device proof.
  - `simulator evidence` / `emulator evidence`: a simulator/emulator run produced advisory platform evidence; it is not physical-device support.
  - `device evidence`: a named physical-device run produced platform evidence; it is not backend/session/provider authority.
- **D-08:** Forbid vague or overloaded claims in public surfaces unless they are immediately qualified by the exact proof label. Forbidden or suspect phrases include "native support", "verified Android", "device verified", "screenshot proof", "published proof" for local refs, "physical-device support" from JVM/emulator evidence, "native with no native work", "just works", "everything works offline", and "write once".

### Native Docs And DX Reconciliation

- **D-09:** Keep `guides/support_matrix.md` and its renderer/source as the canonical label definition. Do not hand-edit generated support-matrix prose if renderer/source changes are required.
- **D-10:** Repeat short inline proof chips beside every native command, native project path, generated template README, Android UAT row, and Phase 120 caption surface. The reader should see the evidence class at the point they run or inspect the proof, not only in the support matrix.
- **D-11:** Use this reading order wherever native evidence appears: what this path proves, command/path, expected result, what it does not prove, next link. This is both DX and UX: the skeptical Phoenix SaaS adopter should not need to reverse-engineer proof class from build files or CI names.
- **D-12:** Reconcile at least these public surfaces to the chosen labels and checked-in host strategy:
  - `README.md`
  - `examples/QUICK_START.md`
  - `examples/ios_shell_host/README.md`
  - `examples/android_shell_host/README.md`
  - `guides/native_shell.md`
  - `guides/support_matrix.md` via renderer/source when applicable
  - `guides/android_uat.md`
  - `guides/install.md`
  - `priv/templates/crosswake/shell/ios/README.md.eex`
  - `priv/templates/crosswake/shell/android/README.md.eex`
  - Future artifact captions prepared for Phase 120.
- **D-13:** Update `guides/android_uat.md` out of stale `v0.1.0` wording. The guide should distinguish current published-coordinate truth, JVM hermetic proof, advisory emulator evidence, and physical-device evidence still requiring explicit proof.
- **D-14:** Public docs should expose user-facing facts: route owner, coordinate mode, platform, command, proof class, expected result, and limitation. Avoid exposing internal implementation guts such as support renderer structs, RouteGate internals, CI plumbing, or stale phase names unless necessary for troubleshooting.
- **D-15:** Use the current brand voice from `brandbook/BRAND-SPEC.md`: careful maintainer prose, operational truth over hype, precise status microcopy, and boundary-first explanations. The older prompt brand book is historical seed material where it conflicts with the ratified brand spec.

### DRIFT-03 Guard

- **D-16:** Add an idiomatic ExUnit docs/source scanner as the primary DRIFT-03 guard, likely `test/crosswake/guides/native_evidence_drift_test.exs` or a similarly focused file. Keep existing generator tests and `PublishReadiness` generator-coordinate parity as supporting coverage, not the whole guard.
- **D-17:** The guard should derive the current package version from `Application.spec(:crosswake, :vsn)` or existing project config patterns. Do not hardcode `0.1.2` except in explicitly historical fixture text.
- **D-18:** Under the selected published-coordinate checked-in host strategy, the guard must fail if:
  - The checked-in iOS host emits a silent `XCLocalSwiftPackageReference`.
  - The checked-in iOS host lacks the `szTheory/crosswake-shell-core-ios` SwiftPM URL or current version requirement.
  - The checked-in Android host references `dev.crosswake:shell-core-android`, a stale version, a local project dependency, or a dynamic dependency version.
  - Public native surfaces reference checked-in native hosts without the required checked-in public-coordinate/advisory environment labels.
  - Public docs describe JVM hermetic proof, simulator evidence, emulator evidence, or screenshots as physical-device support.
- **D-19:** Include synthetic regression tests for the scanner itself. Minimum cases: iOS local ref under published mode, Android stale GAV, Android dynamic version, docs claiming published-coordinate proof for a local path, native path without evidence labels, stale Android UAT current-version wording, and emulator/device overclaim.
- **D-20:** A narrow `mix crosswake.doctor --check-publish` readiness summary may be added if it stays focused on machine-readable native evidence classification. Do not make doctor scan all public prose when the ExUnit docs/source scanner already owns detailed line-level failures.

### User/JTBD Lens

- **D-21:** Primary reader: skeptical Phoenix SaaS adopter deciding whether Crosswake's native path is real. They need to know what command or host proves, where the native dependency comes from, whether it matches the published package version, what platform/environment ran, and what support claims are not implied.
- **D-22:** Maintainer/contributor reader: needs a fast local path for in-repo native package work. That path is `--local` and must be named as local-dev proof, not public-coordinate proof.
- **D-23:** Evaluator/reviewer reader: needs compact labels near screenshots, recordings, docs, and CI artifacts. Phase 119 should define the label/caption contract; Phase 120 captures and packages the evidence.

### Claude's Discretion

The user selected all gray areas and requested a one-shot research-backed recommendation set. Downstream agents may choose exact helper names, scanner module names, failure formatting, support-matrix data shape, and microcopy, as long as they preserve the decisions above. The recommended implementation bias is: one checked-in public-coordinate host pair, support-matrix canonical labels, inline proof chips at point of use, and one focused ExUnit DRIFT-03 scanner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Carry-Forward Decisions

- `.planning/PROJECT.md` - v13 thesis, proof-path constraints, core Crosswake decisions, and Phase 119 active focus.
- `.planning/REQUIREMENTS.md` - NATIVE-01, NATIVE-02, DRIFT-03 requirements and v13 scope lock.
- `.planning/ROADMAP.md` - Phase 119 goal, success criteria, and 119-01/119-02/119-03 plan split.
- `.planning/STATE.md` - Current blocker: checked-in native host drift and need to decide public-coordinate versus local-development proof.
- `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` - Release truth and no-overclaim boundaries.
- `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md` - Support-truth vocabulary and proof labels.
- `.planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md` - Quick-start/adoption decisions and explicit Phase 119 deferrals.

### Product, Brand, And Prompt Context

- `brandbook/BRAND-SPEC.md` - Current ratified voice, label, docs, and microcopy guidance. This supersedes `prompts/crosswake-brand-book.md` where they conflict.
- `prompts/crosswake-elixir-oss-dna.md` - Maintainer house style: install truth, docs-contract guards, proof lanes, support matrices, and explicit rough edges.
- `prompts/crosswake-gsd-project-brief.md` - Route-policy thesis, capability ladder, Phoenix-native priorities, and proof/posture expectations.
- `prompts/crosswake-research-synthesis.md` - Stable architecture story and anti-patterns.
- `prompts/crosswake-integrations-and-companions.md` - Companion/integration scope boundaries.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Mobile shell ecosystem lessons, native/offline proof pitfalls, CI/CD and docs guidance.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Refined OSS/mobile architecture and DX guidance.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - Capability ladder and app archetype stress tests.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` - Flashcard offline-island proof context.
- `prompts/new elixir oss lib prompt.txt` - Original product intent: research-backed recommendations, DX, proof, mobile ecosystem lessons, and avoid overclaiming.

### Native Host And Generator Surfaces

- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` - Checked-in iOS host currently using a local Swift package reference; primary Phase 119 reclassification target.
- `examples/android_shell_host/app/build.gradle` - Checked-in Android host currently referencing stale `dev.crosswake:shell-core-android:0.1.0`; primary Phase 119 reclassification target.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` - Generator template with public SwiftPM default and local branch.
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` - Generator template with Maven Central default and local branch.
- `priv/templates/crosswake/shell/android/settings.gradle.eex` - Local Android project dependency wiring for `--local`.
- `lib/mix/tasks/crosswake.gen.shell.ex` - Generator assigns, `--local` behavior, version derivation, and shell README generation.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - Existing generator coordinate parity and `--local` tests.

### Public Docs And Support Surfaces

- `README.md` - First-read route-policy and support-truth entry point.
- `examples/QUICK_START.md` - Current native steps and advisory/local-development wording from Phase 118.
- `examples/ios_shell_host/README.md` - Checked-in iOS host README lacking proof-class labels.
- `examples/android_shell_host/README.md` - Checked-in Android host README lacking proof-class labels.
- `guides/install.md` - Install/generator path that should distinguish public-coordinate defaults from `--local`.
- `guides/native_shell.md` - Native shell guide, proof hooks, JVM hermetic and Android device-UAT wording.
- `guides/support_matrix.md` - Canonical support-truth label legend and support matrix output.
- `guides/android_uat.md` - Android UAT guide currently carrying stale v0.1.0 wording and needing advisory/device distinctions.
- `guides/adoption.md` - Phase 118 adoption boundary; useful to preserve no-overclaim voice.
- `priv/templates/crosswake/shell/ios/README.md.eex` - Generated iOS README needing current shell/evidence wording.
- `priv/templates/crosswake/shell/android/README.md.eex` - Generated Android README needing current shell/evidence wording.
- `mix.exs` - ExDoc guide wiring, package version, and public guide list.

### Guard And Test Patterns

- `lib/crosswake/support_matrix/support_matrix.ex` - Canonical support matrix data and promotion rules.
- `lib/crosswake/support_matrix/renderer.ex` - Deterministic support matrix renderer; update this if label definitions or generated prose change.
- `test/crosswake/support_matrix/renderer_test.exs` - Renderer parity tests for label legend and output.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Support matrix proof-class and promotion-rule tests.
- `lib/crosswake/doctor/publish_readiness.ex` - Existing `generator_coordinate_parity` readiness check for non-local templates.
- `test/crosswake/doctor/publish_readiness_test.exs` - Existing stale-coordinate generator parity assertions.
- `test/crosswake/guides/release_boundaries_test.exs` - Phase 116 docs-contract scanner pattern.
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` - Phase 118 docs/source scanner pattern and native-label proximity checks.
- `script/verify_phase5_example_hosts.sh` - Existing proof lane that can include checked-in native proof when `CROSSWAKE_PHASE5_NATIVE_PROOFS=1`.
- `script/verify_generated_ios_shell.sh` - iOS generated/checked-in project verification script.
- `script/verify_generated_android_shell.sh` - Android generated/checked-in project verification script.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/mix/tasks/crosswake_gen_shell_test.exs`: Already proves non-local generator templates emit SwiftPM/Maven Central coordinates derived from `Application.spec(:crosswake, :vsn)` and that `--local` emits local Swift/Gradle project references. Phase 119 should not duplicate this; it should extend truth to checked-in hosts and public docs.
- `lib/crosswake/doctor/publish_readiness.ex`: Existing `generator_coordinate_parity_check/1` can remain the machine-readable readiness contract for generated non-local scaffolds. A narrow native evidence summary may be added if useful.
- `test/crosswake/guides/release_boundaries_test.exs` and `test/crosswake/guides/quick_start_adoption_drift_test.exs`: Strong patterns for docs/source scanners with synthetic stale-claim regressions and actionable failure messages.
- `lib/crosswake/support_matrix/renderer.ex`: Canonical place to change generated support-matrix legend/prose.

### Established Patterns

- Crosswake treats docs, support matrices, proof lanes, and drift guards as product surface.
- Deterministic ExUnit scanners are the idiomatic guard for docs/proof truth in this repo.
- Generator output is host-owned, scaffold-once code. Public defaults should match adopter install truth; local source paths should require explicit `--local`.
- Environment-sensitive native evidence remains advisory unless explicitly promoted.

### Integration Points

- Checked-in host files are the main code/doc truth gap: iOS currently uses local SwiftPM, Android currently uses stale local-era GAV.
- Native READMEs and generated README templates need evidence-label language, not just host-owned shell language.
- `guides/android_uat.md` is stale against current `0.1.2` release truth and needs label reconciliation.
- `examples/QUICK_START.md` already carries Phase 118 advisory/local-development caveats; Phase 119 should update it to the new checked-in public-coordinate strategy while keeping simulator/emulator evidence advisory.

</code_context>

<specifics>
## Specific Ideas

- Subagent-backed host recommendation: promote checked-in hosts to published-coordinate defaults because they are public proof artifacts and Phase 119 requirements name this as the preferred path.
- Subagent-backed label recommendation: use strict dimensional taxonomy and add `checked-in public-coordinate proof` rather than overloading `generated public-coordinate proof`.
- Subagent-backed docs recommendation: keep the support matrix canonical but repeat inline proof chips near every command/path/caption where a reader can misread evidence.
- Subagent-backed guard recommendation: add an ExUnit docs/source scanner with synthetic regressions; keep generator tests and publish-readiness parity as supporting coverage.
- External ecosystem lessons applied:
  - Phoenix and Rails generator ecosystems teach scaffolded, host-owned app code with clear generator behavior and tests, not magical ongoing ownership.
  - SwiftPM and Gradle/Android distinguish remote package dependencies from local/project dependencies; local dependency mode should not be presented as public install proof.
  - Hotwire Native separates path configuration, bridge components, and native screens; Crosswake should preserve route/evidence boundaries instead of generic mobile claims.
  - Expo and Capacitor show the value and footguns of generated native projects: generated/native runtime state must be explicit, and manual/generated project ownership needs warnings.
  - ExUnit supports fast deterministic tests and tags; Crosswake's docs/source guard should stay in `mix test` rather than relying on an untested shell script.
- Official sources consulted during discussion:
  - Phoenix generator docs: `https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.html`
  - Mix task docs: `https://hexdocs.pm/mix/1.12/Mix.Task.html`
  - ExUnit docs: `https://ex-unit.hexdocs.pm/1.2.1/ExUnit.Case.html`
  - Apple Xcode package dependency docs: `https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app`
  - Gradle dependency management docs: `https://docs.gradle.org/current/userguide/getting_started_dep_man.html`
  - Android build dependency docs: `https://developer.android.com/build/dependencies`
  - Hotwire Native bridge/path docs: `https://native.hotwired.dev/overview/bridge-components`, `https://native.hotwired.dev/ios/path-configuration`
  - Capacitor docs: `https://capacitorjs.com/docs/`
  - Expo Continuous Native Generation docs: `https://docs.expo.dev/workflow/continuous-native-generation/`
  - Rails generator docs: `https://guides.rubyonrails.org/generators.html`
  - Django reusable app docs: `https://docs.djangoproject.com/en/6.0/intro/reusable-apps/`

</specifics>

<deferred>
## Deferred Ideas

- Phase 120 owns actual screenshot, recording, browser/native route-tour capture, artifact upload, and evidence bundle packaging.
- Phase 120 owns artifact manifest schema/validator unless Phase 119 planning finds a tiny label-only precursor necessary for captions.
- Phase 120 owns full troubleshooting and rough-edge docs for doctor findings, denials, route-unavailable states, offline outcomes, and native evidence caveats.
- Physical-device support, camera/media-upload support, provider authority, app-store readiness, and required simulator/emulator branch protection remain out of Phase 119 unless a future milestone explicitly promotes them.
- DASH-01 and NTV-01 remain deferred unless later v13 work proves they are necessary for evidence visibility.

</deferred>

---

*Phase: 119-Native Evidence Classification*
*Context gathered: 2026-06-19T19:28:04Z*
