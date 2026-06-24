# v13.0 Proof Path, Docs, and Quick-Start Drift Research

**Project:** Crosswake  
**Focus:** v13.0 Adopter Confidence & Native Evidence - proof-path/docs/quick-start drift  
**Researched:** 2026-06-18  
**Confidence:** HIGH for repo drift and package truth; MEDIUM for ecosystem comparison

## Executive Summary

Crosswake has enough real substrate for a skeptical Phoenix SaaS adopter to take it seriously: `crosswake` is at `0.1.2` in `mix.exs`, external package checks confirmed Hex latest `0.1.2`, Maven Central latest/release `0.1.2`, and the SwiftPM mirror tag `v0.1.2`. v11 and v12 also left strong repo truth: generated shells resolve published native coordinates, and the offline proof now exercises the real IndexedDB outbox and reconnect flush.

The adopter-facing path does not yet communicate that truth cleanly. README still says current Crosswake is `0.1.0`; CHANGELOG says `0.1.2` is pending and not on Hex; `examples/QUICK_START.md` uses a missing `mix setup`, wrong iOS path, old port, and a bridge-only flow; `guides/adoption.md` still describes a bridge-owned sync engine and fictional `Crosswake.mutate`; several guide snippets still say standalone public shell packages are deferred. Because ExDoc publishes README, CHANGELOG, and these guides as extras, the drift is not just repo-local cleanup - it is packaged public documentation drift.

The v13 requirement should be framed as "make the proof path current, runnable, visual, and honestly labeled." Do not use v13 for new capability breadth. The strongest roadmap shape is: fix local proof debt first, reconcile release/docs truth second, then reconcile native host evidence and capture visual collateral, then add route-policy/troubleshooting/migration guide polish with docs-contract checks.

## Repo Evidence

### What Is Solid Today

- Core thesis is consistent: README says runtime ownership is explicit per route and lists the right non-goals (`README.md:13-40`).
- README already has a useful guide map and install/proof posture (`README.md:42-85`, `README.md:119-141`).
- `mix.exs` package truth is current: `@version "0.1.2"` and package files include `README.md`, `CHANGELOG.md`, and `guides` (`mix.exs:4`, `mix.exs:69-80`).
- ExDoc is configured to publish README, CHANGELOG, install/support/adoption/user-flow/native-shell/offline/etc. as extras, grouped under Setup/Capabilities/Guides (`mix.exs:83-127`).
- Support matrix now states the correct published non-local shell path: iOS SwiftPM mirror and Android Maven Central at Hex-matched versions (`guides/support_matrix.md:3-9`, `guides/support_matrix.md:41-46`).
- Native generator templates are correct for the public install path: iOS non-local template uses `https://github.com/szTheory/crosswake-shell-core-ios.git` plus `minimumVersion = @version`; Android non-local template uses `io.github.sztheory:crosswake-shell-core-android:@version` (`priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex:53-60`, `priv/templates/crosswake/shell/android/app/build.gradle.eex:50-55`).
- Publish-readiness checks guard against regression to local iOS packages or the old Android GAV (`lib/crosswake/doctor/publish_readiness.ex:579-628`).
- Planning truth is clear that v13 is proof-path consolidation, not feature expansion (`.planning/PROJECT.md:83-99`, `.planning/STATE.md:57-62`).

### Drift That Blocks Adopter Confidence

- README baseline still says `Crosswake version 0.1.0` while package/release truth is `0.1.2` (`README.md:143-151`, `mix.exs:4`).
- CHANGELOG still says latest published Hex is `0.1.0` and labels `0.1.2` as unreleased/pending, contradicting package truth and external registry checks (`CHANGELOG.md:28-35`).
- `examples/QUICK_START.md` uses `mix setup`, but the example host only defines a `test` alias and has no setup alias (`examples/QUICK_START.md:20-24`, `examples/phoenix_host/mix.exs:26-31`).
- Quick start says the server runs on `http://localhost:4000`; the example host defaults to port `4002`, and Playwright also uses `4002` (`examples/QUICK_START.md:27`, `examples/phoenix_host/config/config.exs:8-14`, `examples/phoenix_host/playwright.config.ts:10-24`).
- Quick start iOS path is wrong: it says `examples/ios_shell_host/ios_shell_host.xcodeproj`, but the repo path is `examples/ios_shell_host/CrosswakeShell.xcodeproj` (`examples/QUICK_START.md:37-40`; repo tree).
- Quick start demonstrates only the bridge/share happy path, not the v12 real IndexedDB outbox/reconnect proof or the three adopter lanes (`examples/QUICK_START.md:62-72`).
- Adoption guide still says "Sync Engine (Bridge)" intercepts offline mutations and shows `Crosswake.mutate(...)`; this contradicts v12's app-owned IndexedDB outbox/reconnect proof and risks teaching a non-existent public API (`guides/adoption.md:11-16`, `guides/adoption.md:25-45`).
- Native shell, install, and compatibility guides still include stale generated prose that says standalone public shell packages are deferred, even though v11 shipped them (`guides/native_shell.md:64`, `guides/install.md:148`, `guides/compatibility.md:79`).
- Checked-in iOS host uses a local Swift package reference (`examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj:53-57`).
- Checked-in Android host uses app version `0.1.0` and stale dependency `dev.crosswake:shell-core-android:0.1.0` instead of the published Maven coordinate (`examples/android_shell_host/app/build.gradle:10-16`, `examples/android_shell_host/app/build.gradle:62-64`).
- Example manifests and install manifest still contain `crosswake_version: 0.1.0`; this may be fixture truth, but it must be labeled or regenerated because adopters will read checked-in hosts as proof artifacts.
- `TODO-001` remains open for pre-existing example-host test failures: deterministic Flashcards schema/API drift and flaky Chimeway registry isolation (`.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md:20-45`).
- No durable adopter-facing screenshots or videos were found outside older brand/render verification artifacts. The thread explicitly records this as a v13 confidence gap (`.planning/threads/adoption-evidence-demo.md:23-38`).

## Pros, Cons, and Tradeoffs

### Make Checked-In Native Hosts Use Published Coordinates

**Pros:** strongest adopter story; examples match generator/release truth; screenshots can be read as public install evidence.  
**Cons:** local development becomes slower or less convenient when editing native core and host together; may require fixture regeneration and more careful upgrade notes.  
**Recommendation:** prefer this for v13 unless it destabilizes proof lanes. If local native iteration is still needed, add an explicit local-dev variant or `--local` regeneration note, not stale checked-in defaults.

### Label Checked-In Hosts As Local-Development Proof

**Pros:** lowest implementation risk; honest if examples are meant to exercise repo-local native core.  
**Cons:** weaker adopter confidence; creates two proof stories: generator proves public coordinates, checked-in host proves local development.  
**Recommendation:** acceptable only if README/quick start route adopters to generated clean-room proof first and clearly label checked-in hosts as local proof.

### Keep One Quick Start Versus Split "Evaluate" And "Maintain"

**Pros of one path:** lower cognitive load; matches Phoenix/Oban style.  
**Cons:** Crosswake has three proof classes: public install, repo example host, native simulator collateral. One page can become too dense.  
**Recommendation:** root quick start should be one runnable path with explicit tabs/sections: "Evaluate package", "Run example proof", "Run native evidence." Deeper guides should be linked, not duplicated.

### Visual Collateral As Advisory Evidence

**Pros:** screenshots/video make the route-policy thesis concrete; strong for skeptical adopters.  
**Cons:** simulator/device proof is environment-sensitive; promoting it to merge-blocking too early creates flaky support claims.  
**Recommendation:** capture and publish screenshots/short recordings, but label them advisory unless v13 also creates repeatable CI support strong enough to promote them.

## Idiomatic Phoenix/Elixir Guidance To Steal

Official ecosystem docs converge on a few patterns Crosswake should adopt:

- Phoenix gives a tiny "Try it now" path before full docs: install generator, create app, then link to complete installation. Crosswake should put the shortest runnable proof path above the guide map, not bury it behind planning concepts.
- Phoenix `mix phx.new` docs make installer flags and defaults explicit. Crosswake should document `mix crosswake.gen.shell ios|android` defaults, `--local`, target path, and what is host-owned after generation.
- LiveView docs start with "what is it", one small runnable example, then split guides by server-side/client-side concerns. Crosswake should start with one Phoenix SaaS route example, then split guide entry points by route owner: LiveView, bounded bridge, offline island, native screen.
- Oban provides automatic/semi-automatic/manual install paths and ends installation with a verification step. Crosswake should mirror this: package install, shell generation, doctor, proof lane, then "you are ready" with next links.
- Ash offers new-project and existing-project install paths, plus a self-contained tutorial with goals, requirements, and "what next." Crosswake should explicitly separate "new Phoenix host evaluation" from "existing SaaS migration" instead of making adopters infer it.
- Oban/Ash both document requirements before commands. Crosswake quick start should list Elixir/Phoenix, Xcode, Android Studio, ports, DB setup, and which steps are optional/advisory.

Avoid copying:

- Huge all-in-one README tutorials. Crosswake's README should stay a map plus first runnable path; deep explanation belongs in guides.
- Runnable examples that are not proof-backed. Crosswake's own docs-only boundary says promotion requires proof and support-matrix updates.
- Capability catalog sprawl. Route owner should remain the organizing principle, not a mobile API menu.

## What A Phoenix SaaS Adopter Needs Today

1. A 10-minute "is this real?" path:
   - install `{:crosswake, "~> 0.1.2"}` or `~> 0.1` with current version callout;
   - run installer/generator/doctor;
   - run one proof command that succeeds without knowing milestone archaeology.
2. A repo example path that starts cleanly:
   - exact `cd examples/phoenix_host`;
   - exact dependency/database commands;
   - exact port (`4002` unless changed);
   - no missing `mix setup`.
3. A route-policy mental model:
   - one SaaS LiveView route;
   - one bounded bridge affordance;
   - one offline-island route;
   - one native-screen route;
   - explicit denial/fallback behavior.
4. Native evidence truth:
   - generated public-coordinate path is clearly distinguished from checked-in local-dev hosts;
   - screenshots/video label platform, command, commit, package version, and whether evidence is advisory or merge-blocking.
5. Rough-edge guidance:
   - host-owned shell after generation;
   - no safe overwrite regeneration over edits;
   - offline island is foreground/route-local, not app-wide background sync;
   - bridge is low-frequency request/reply, not an event bus;
   - native evidence does not imply broad device support.

## Adopter DX Risks

| Risk | Severity | Why It Matters | Mitigation |
|------|----------|----------------|------------|
| Public version contradiction | High | README/CHANGELOG currently tell adopters not to trust `0.1.2` even though it is published. | Update README/CHANGELOG and add a docs-contract test against package/registry truth. |
| Non-runnable quick start | High | Missing `mix setup`, wrong iOS path, wrong port create immediate failure. | Make quick start command-verified in CI or a local script. |
| Fictional offline API | High | `Crosswake.mutate` and bridge-owned sync undercut v12's honesty work. | Rewrite adoption guide around app-owned IndexedDB outbox, reconnect listener, Ecto reconciliation. |
| Native host coordinate ambiguity | High | Adopters cannot tell whether examples prove public install or monorepo-local development. | Choose published-coordinate examples or label local-dev proof explicitly. |
| ExDoc amplifies drift | Medium | Stale README/CHANGELOG/guides ship into package docs. | Treat ExDoc build as public proof surface; add link/anchor/version checks. |
| Visual evidence absent | Medium | Mechanical proof is strong but not immediately legible to a maintainer evaluating fit. | Capture screenshot/video artifacts with labels and advisory/support status. |
| Support matrix overclaims device proof | Medium | It marks iOS/Android supported, while Android notes JVM hermetic and device-UAT advisory. | Add a concise "support truth legend" in README/quick start and align guide prose. |

## Recommended v13 Requirements

### REQ-1: Public Release Truth Reconciliation

README, CHANGELOG, ExDoc extras, support matrix, install/native/compatibility guides, Android UAT, example install manifests, and public guide links must agree with `0.1.2` package truth or explicitly label older fixture truth.

Acceptance criteria:

- README current baseline says `0.1.2` or uses `Application.spec`/Hex-neutral wording that cannot stale easily.
- CHANGELOG marks `[0.1.2]` as released with the correct date and updates compare links.
- No public guide says latest Hex is `0.1.0`, `0.1.2` is pending, or standalone public shell packages are deferred.
- ExDoc builds with the corrected extras.
- A docs-contract check fails if README/CHANGELOG/mix version truth diverges.

### REQ-2: Runnable Quick Start

`examples/QUICK_START.md` must become a command-verified path for a Phoenix SaaS evaluator.

Acceptance criteria:

- Commands work from repo root and name the correct example host setup commands.
- Server port matches config (`4002` by default) or uses `PORT=` consistently.
- iOS project path is correct.
- Android path is correct.
- Quick start includes the proof command(s) and expected evidence for LiveView, bounded bridge, offline island, and native screen.
- The guide states which native simulator/emulator steps are advisory.

### REQ-3: Adoption Guide Real Offline Proof

`guides/adoption.md` must teach v12 truth: app-owned offline island, IndexedDB outbox, reconnect-triggered flush, server/Ecto reconciliation, and explicit idempotency/conflict semantics.

Acceptance criteria:

- Removes or clearly rejects `Crosswake.mutate` and "Sync Engine (Bridge)" wording.
- Links to `guides/offline.md`, the example offline route, and the E2E proof lane.
- Explains cached read-only vs true offline island in adopter language.
- States non-goals: no app-wide sync, no background sync, no bridge-owned mutation authority.

### REQ-4: Native Evidence Truth

Checked-in iOS/Android hosts must either prove published coordinates or be labeled local-development proof everywhere they are referenced.

Acceptance criteria:

- iOS checked-in host no longer silently uses `XCLocalSwiftPackageReference` as public proof, or README labels it local-dev proof.
- Android checked-in host no longer references `dev.crosswake:shell-core-android:0.1.0` as public proof, or README labels it local-dev proof.
- Generated shell docs show the public published-coordinate path and `--local` path separately.
- Support matrix, README, quick start, and native shell guide use the same classification.

### REQ-5: Seeing-Is-Believing Collateral

Capture durable evidence for one Phoenix host and both native shells, without overpromoting simulator/device support.

Acceptance criteria:

- Screenshots or short recordings exist for: Phoenix LiveView route, bounded bridge route, offline island with queued/replayed state, native screen/route unavailable or capture path.
- Artifacts include commit SHA, package version, platform, command used, and support status.
- README or quick start links the artifacts.
- Device/simulator evidence remains advisory unless promotion criteria are explicitly added and met.

### REQ-6: Local Proof Debt Removed From Public Path

`TODO-001` must be resolved or explicitly excluded from the public proof path.

Acceptance criteria:

- `CrosswakeExample.FlashcardsTest` deterministic field/API drift is fixed or removed from the advertised proof lane.
- Chimeway registry test flake is made deterministic or excluded from adopter proof with a narrow reason.
- Public proof commands do not depend on known failing/flaky tests.
- STATE/TODO truth is updated after resolution.

### REQ-7: Guide Map For Existing Phoenix SaaS Migration

Add or tighten web-to-mobile migration guidance for Phoenix SaaS teams.

Acceptance criteria:

- Starts from existing Phoenix routes and classifies them into `:live_view`, bounded bridge, cached read-only, `:offline_island`, and `:native_screen`.
- Includes a small route-policy example and a "do not migrate this" section.
- Links back to support matrix and native rebuild guidance.

## Suggested Phase Shape

1. **Proof Debt And Release Truth**
   - Resolve/exclude `TODO-001`.
   - Reconcile README/CHANGELOG/package/native-shell deferred prose.
   - Add docs-contract checks.

2. **Runnable Quick Start And Adoption Guide**
   - Rewrite `examples/QUICK_START.md`.
   - Rewrite `guides/adoption.md` around the real outbox/reconnect proof.
   - Verify commands from a clean repo checkout or CI job.

3. **Native Host Evidence Truth**
   - Decide published-coordinate examples vs local-dev labeling.
   - Update checked-in host READMEs, support matrix, and guide references.
   - Re-run generated shell proof.

4. **Visual Collateral And Migration Guide**
   - Capture screenshots/recordings.
   - Add route-policy/web-to-mobile migration guide.
   - Label simulator/emulator evidence advisory unless promoted.

## Explicit Non-Goals

- No new capability families.
- No companion package extraction.
- No broad native runtime expansion.
- No native device support promotion unless repeatable proof and promotion criteria are added.
- No generic WebView wrapper positioning.
- No LiveView-driven native UI rendering.
- No app-wide offline or background sync claim.
- No new dashboard metrics unless v13 proof work proves DASH-01 is necessary.
- No native disk-space budget work unless v13 proof work proves NTV-01 is necessary.

## Sources

Repo-local sources:

- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/threads/adoption-evidence-demo.md`
- `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`
- `README.md`
- `CHANGELOG.md`
- `mix.exs`
- `guides/*.md`
- `examples/QUICK_START.md`
- `examples/phoenix_host/*`
- `examples/ios_shell_host/*`
- `examples/android_shell_host/*`
- `prompts/crosswake-elixir-oss-dna.md`
- `prompts/crosswake-research-synthesis.md`
- `prompts/crosswake-gsd-project-brief.md`

External sources checked:

- Phoenix homepage and "Try it now": https://www.phoenixframework.org/
- Phoenix `mix phx.new` docs: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html
- Phoenix LiveView welcome docs: https://phoenix-live-view.hexdocs.pm/welcome.html
- Oban docs and installation guide: https://oban.hexdocs.pm/Oban.html and https://oban.hexdocs.pm/installation.html
- Ash homepage and getting-started guide: https://www.ash-hq.org/ and https://ash.hexdocs.pm/get-started.html
- Hex package API for Crosswake: https://hex.pm/api/packages/crosswake
- Maven metadata for Android core: https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/maven-metadata.xml
- SwiftPM mirror tags checked via `git ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios.git`

## Method Notes

The repo-local findings are direct source inspection and should be treated as HIGH confidence. The ecosystem comparison is source-verified against official docs, but intentionally brief; use it for onboarding pattern guidance, not for broad market claims. The local GSD research-plan seam failed in this environment with a missing `package.json` module, so official web/docs lookups were used directly for the ecosystem comparison.
