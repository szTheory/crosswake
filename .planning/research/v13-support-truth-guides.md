# v13.0 Support-Truth Guides Research

**Project:** Crosswake  
**Milestone:** v13.0 Adopter Confidence & Native Evidence  
**Focus:** support-truth guide set and route-policy story  
**Researched:** 2026-06-18  
**Confidence:** HIGH for repo-local evidence; MEDIUM for ecosystem comparison

## Executive Takeaway

Crosswake's adoption story should be: **Route policy for Phoenix apps that go mobile.** Its one job is to make runtime ownership explicit per route, then enforce and diagnose that contract through manifest truth, compatibility gates, bounded bridge denials, offline contracts, native-shell proof, and a support matrix. The docs should not lead with "mobile framework", "native runtime", or a capability catalog. Those phrases steer Phoenix SaaS developers toward the wrong mental model.

The shipped substrate supports this story. Route policy exposes exactly three runtime owners (`:live_view`, `:offline_island`, `:native_screen`) and three offline states (`:unavailable`, `:cached_read_only`, `:local_first`). The manifest builder turns those route declarations into route entries, capability registry entries, pack/transfer seams, support matrix truth, and compatibility metadata. Doctor inspects install state, manifest truth, shells, bridge, offline posture, support posture, and publish readiness. The bridge is typed, versioned, request/reply-only, and route-local. The v12 offline proof now exercises the real IndexedDB outbox, reconnect flush, Ecto state, outbox deletion, and idempotency.

The adoption risk is not lack of architecture. It is public explanation drift and evidence labeling. README still says Crosswake `0.1.0` while package truth is `0.1.2`. CHANGELOG still says `0.1.2` is pending. `examples/QUICK_START.md` contains a missing `mix setup`, wrong port, wrong iOS project path, and a bridge-only proof flow. `guides/adoption.md` still teaches a bridge-owned `Crosswake.mutate` sync path that does not match the shipped v12 app-owned IndexedDB outbox. Native evidence is split: generated shell templates and tests prove published SwiftPM/Maven coordinates, while checked-in native hosts still carry local or old coordinates. v13 should make those distinctions impossible to miss.

## Current Shipped Evidence

| Surface | Shipped Evidence | Adoption Meaning | v13 Guide Implication |
|---------|------------------|------------------|-----------------------|
| Product thesis | `README.md` says runtime ownership is explicit per route and lists non-goals: not React Native for Phoenix, not generic WebView wrapper, not LiveView rendering native UI, not universal UI, not magic offline. `brandbook/BRAND-SPEC.md` uses the one-liners "Route policy for Phoenix apps that go mobile" and "declaring which runtime owns each route". | The positioning is already correct. | Promote this as the first adopter sentence everywhere. Avoid a second, broader tagline in quick start or ExDoc. |
| Route policy | `Crosswake.Policy.Schema` accepts `:live_view`, `:offline_island`, and `:native_screen`, with `:unavailable`, `:cached_read_only`, and `:local_first`. `Crosswake.Policy.Route` validates cache contracts, island contracts, gating posture, entry policy, auth posture, packs, and transfers. `Crosswake.Policy.Validator` rejects local-first LiveView routes, unavailable offline islands, unsupported external offline islands, sync without offline support, missing security, duplicate seams, and provider-specific commerce vocabulary. | Crosswake is policy-first, not wrapper-first. | Add a public route-policy guide that teaches owner selection before syntax. |
| Manifest truth | `Crosswake.Manifest.Builder` builds a route-first manifest from compiled policy, including runtime, offline, entry, cache/island contracts, capabilities, packs, sync, transfers, security, origins, gating, auth, and notification-open metadata. | Runtime ownership becomes inspectable data, not prose. | Every guide should show how a route declaration becomes manifest/support/doctor truth. |
| Capability ownership | The capability catalog classifies `deep_link` as activation, `app_info`/`haptics`/`share`/`file_picker` as bounded bridge, `media_capture` as native screen, and commerce as backend seam. Each capability carries proof class, rebuild posture, denial, fallback, and guide anchor. | Capability choice is subordinate to route owner. | Guide maps must resist a "plugin API menu" layout. Start from route owner, then discuss capabilities. |
| Bounded bridge | `Crosswake.Bridge.Contract` is `crosswake.bridge` version `1.1.0`, request/reply-only, with a small command allowlist. `Crosswake.Bridge.Registry` requires an active manifest route and declared capability or transfer seam before a command is allowed. | The bridge is semantic, typed, route-local, and low-frequency. | Bridge guide microcopy should say "native affordance" and "request/reply" instead of "native API access layer". |
| Offline | `Crosswake.Offline.Contracts` distinguishes cached read-only routes from the study-session island with append-only journal, explicit reconciliation, checkpoint requirement, Phoenix authority, budget, reserve, and eviction. `guides/offline.md` explicitly says no generic sync, no broad background sync, and no app-wide offline claim. | Offline is a narrow proof-backed workflow, not a broad product promise. | Rewrite adoption guide around app-owned IndexedDB outbox plus Phoenix/Ecto reconciliation, not bridge-owned mutation. |
| v12 proof lane | `examples/phoenix_host/e2e/offline_sync.spec.ts` now drives `/offline` through real UI, verifies no LiveView socket, observes IndexedDB, reconnects, waits for `/study/sync`, polls Ecto, verifies outbox deletion, and proves duplicate idempotency. `offline_study.js` owns `flushOutbox()` and the `online` listener. | Crosswake can prove one real local-first route without pretending the whole app is offline. | Quick start and adopter guide should use this as the flagship "offline island" evidence. |
| Native shell truth | Generated non-local iOS template resolves `https://github.com/szTheory/crosswake-shell-core-ios.git` at `@version`; generated Android template resolves `io.github.sztheory:crosswake-shell-core-android:@version`. Generator tests reject local iOS refs, old Android GAV, and mismatched coordinates. | The public generator path has real distribution evidence. | Native guide must distinguish generated public-coordinate proof from checked-in local-dev hosts. |
| Checked-in native hosts | `examples/ios_shell_host` still uses `XCLocalSwiftPackageReference` and `examples/android_shell_host/app/build.gradle` still uses `dev.crosswake:shell-core-android:0.1.0`. Example manifests still say `0.1.0`. | Public readers can misread checked-in hosts as current published-coordinate proof. | Either update checked-in hosts to prove `0.1.2` published coordinates or label them local-development proof wherever linked. |
| Doctor and support | `Crosswake.Doctor` is host-truth-first and reports install manifest, manifest, shells, bridge, offline, support, commerce, publish readiness, and findings. `Crosswake.SupportMatrix` is canonical truth shared across manifest, doctor, and docs. | Diagnostics and support truth are product surface. | Add a friendlier first-read support legend before sending users into the dense matrix. |
| Guide set | `guides/user_flows.md` already contains the strongest mental model: "Who should own this route?" and the three canonical jobs: Phoenix SaaS portal, selective native flow, local-first study flow. | The correct adoption story exists but is not yet the obvious entry path. | Promote this into README, ExDoc grouping, and a route-policy/migration guide. |

## Drift And Evidence Gaps

| Gap | Evidence | Why It Hurts Adoption | v13 Acceptance Direction |
|-----|----------|-----------------------|--------------------------|
| Version truth drift | README current baseline says `0.1.0`; `mix.exs` says `0.1.2`; CHANGELOG says `0.1.2` is unreleased and pending. | A skeptical adopter sees the first public page contradict the package. | Reconcile README, CHANGELOG, guides, example manifests, and ExDoc extras with `0.1.2` or label old fixtures. |
| Non-runnable quick start | `examples/QUICK_START.md` uses `mix setup`, says port `4000`, points to `examples/ios_shell_host/ios_shell_host.xcodeproj`, and only tests share bridge. | The first hands-on path fails before the route-policy idea can land. | Replace with a command-verified proof path covering LiveView, bounded bridge, offline island, and native screen/advisory evidence. |
| Fictional offline bridge API | `guides/adoption.md` says "Sync Engine (Bridge)" intercepts mutations and shows `Crosswake.mutate(...)`. | It teaches a non-existent and architecturally wrong API that undermines v12 honesty. | Rewrite around app-owned offline island JS, IndexedDB outbox, reconnect flush, Ecto endpoint, replay outcomes, and idempotency. |
| Stale "standalone packages deferred" prose | `guides/install.md`, `guides/native_shell.md`, and `guides/compatibility.md` still say standalone public shell packages are deferred. | It contradicts v11 distribution truth and makes native support look unfinished in the wrong way. | Remove or replace with published-coordinate plus local-dev labeling. |
| Android UAT overclaim | `guides/android_uat.md` says last verified v0.1.0 and lists many capability families as "Verified" in an unchecked advisory checklist. | It blurs JVM hermetic, emulator/device, and provider proof. | Convert to advisory checklist with status labels, or remove from first-read docs until evidence is current. |
| Dense support matrix | `guides/support_matrix.md` is canonical but mixes baseline, proof status, package class, proof class, rebuild, denial, fallback, and promotion rules. | Correct but intimidating. New readers may equate "supported" with device-verified. | Add a "support truth in five labels" explainer in README/quick start and link into the full matrix. |
| Collateral gap | Planning state records no durable adopter screenshots/videos/artifact uploads for browser/native demo paths. | Mechanical proof is strong but not legible to a maintainer doing fast evaluation. | Capture evidence with commit SHA, command, package version, platform, route owner, and proof/advisory status. |
| Open example-host TODO | `TODO-001` remains open for pre-existing example-host failures and flake. | Public proof should not depend on known local debt. | Resolve or exclude from public proof path with explicit scope note. |

## Adopter Mental Model

### Crosswake's One Job

Crosswake's one job is **to let a Phoenix team declare, enforce, and diagnose which runtime owns each route as the app crosses into mobile**.

Use this framing:

- Phoenix-owned routes stay LiveView.
- Phoenix-owned routes can ask the shell for one bounded native affordance.
- Some routes can degrade to cached read-only behavior.
- One route can become an offline island with a real local journal/outbox and explicit replay.
- One device-heavy route can become a native screen.
- Support truth, doctor output, route-unavailable denials, and proof labels tell the team what is actually supported.

Do not frame Crosswake as:

- a mobile UI framework
- a WebView wrapper
- a LiveView-to-native renderer
- a generic plugin API
- a universal offline engine
- a "build iOS/Android from Phoenix" promise without the route-owner qualifier

### Route-Owner Decision Rules

| Question | Route Owner | Use When | Must Say In Docs | Evidence To Show |
|----------|-------------|----------|------------------|------------------|
| Is Phoenix still the obvious authority? | `:live_view` | SaaS dashboard, account page, approvals, settings, billing history. | "Phoenix owns rendering, state, auth, and writes; the shell only activates the route honestly." | `saas-dashboard`, `saas-approval`, manifest route entry, RouteGate activation. |
| Does the route need one native affordance? | `:live_view` plus bounded bridge | Haptics, app info, share, permission snapshot, file picker with transfer seam. | "The route stays Phoenix-owned; native returns one typed reply or denial." | `bridge-proof`, bridge allowlist, `undeclared_capability` fallback. |
| Is stale local reading acceptable but mutation unsafe? | `:live_view` plus `offline: :cached_read_only` | Study history, library/reference pages, safe neighbor screens. | "Cached read-only is not local-first." | cache contract, offline status labels, doctor/support matrix. |
| Must one workflow continue mutating offline? | `:offline_island` plus `offline: :local_first` | Study session, training checklist, one local-first loop. | "This route has local mutation, journal/outbox, explicit replay, and conflict visibility; the app is not globally offline." | `/offline`, IndexedDB outbox, `/study/sync`, Ecto proof, idempotency. |
| Is the device session loop the product? | `:native_screen` | Camera evidence capture, scanner/document scan when proven, storefront-sensitive native flows. | "Native owns this route; no silent web fallback." | selective native claim capture, transfer seam, pack gating, route unavailable. |
| Is truth actually backend/provider owned? | backend seam or companion, not bridge authority | Commerce, entitlement, auth, notification token/open, media evidence. | "Device evidence is not authority until backend reconciliation promotes it." | support matrix commerce/auth/notification truth, denial vocabulary. |
| Is the flow broad, high-frequency, or unproven? | Defer | Game loops, realtime AV, background location/nav, generic plugin catalog, app-wide sync. | "Outside current thesis until proof, support, and promotion criteria exist." | explicit non-goal/deferral table. |

### Migration Path For A Phoenix SaaS Developer

1. Inventory existing Phoenix routes by user job, not by controller/live module type.
2. Mark almost everything `:live_view` first.
3. Add `entry: :external` only to routes that should be activated from links, notifications, or shell entry points.
4. Add bounded bridge capabilities only where failure can degrade without changing product authority.
5. Mark read-only degraded surfaces with `offline: :cached_read_only`; never use this for mutation.
6. Promote exactly one local-first route to `:offline_island` only when user progress must continue offline and replay/conflict behavior is acceptable.
7. Promote exactly one device-heavy corridor to `:native_screen` when native permission/session control is the correct runtime.
8. Run `mix crosswake.doctor` and inspect denial/fallback/support truth before treating the route as adoptable.
9. Capture proof for each route-owner class the app actually uses.

The migration guide should include a "do not migrate this" section:

- Do not move normal SaaS forms native just because the app is mobile.
- Do not route high-frequency client state through the bridge.
- Do not claim offline mutation by caching a LiveView page.
- Do not make a provider/device event authoritative without backend reconciliation.
- Do not treat checked-in local native hosts as proof of published package coordinates unless they actually use those coordinates.

## Recommended Guide Map

| Guide Surface | Job | Must Contain | Current State | v13 Action |
|---------------|-----|--------------|---------------|------------|
| `README.md` | First 90 seconds. State what Crosswake is, what it is not, and the shortest proof path. | One-job sentence, path selector, current version, proof/advisory legend, guide map. | Good thesis; stale version; proof path too terse. | Update version truth and add "Evaluate in 10 minutes" path. |
| `guides/start_here.md` or promoted `guides/user_flows.md` | First conceptual read. | "Who owns this route?", three canonical jobs, owner decision tree. | `user_flows.md` is strong but not framed as the canonical start. | Promote, rename, or link as the first ExDoc guide. |
| `guides/route_policy.md` | Core route-policy story. | DSL fields, owner decision rules, route examples, compiler diagnostics, manifest output, denial/fallback table. | No dedicated route-policy guide despite route policy being the product center. | Add it. It should be the anchor for GUIDE-01. |
| `guides/web_to_mobile_migration.md` | Existing Phoenix SaaS adoption path. | Route inventory worksheet, default-to-LiveView rule, bounded bridge additions, offline/native promotion criteria, anti-migration examples. | Migration advice is scattered across user flows, adopter profiles, install, native shell, offline. | Add a concise migration guide and link from README/install. |
| `guides/install.md` | Package install and generator proof. | `{:crosswake, "~> 0.1"}`, installer, generator, host-owned shell, doctor, native proof hooks, `--local` vs public coordinates. | Good sequence; stale deferred standalone package sentence. | Fix stale truth and clarify public-coordinate/local-dev paths. |
| `examples/QUICK_START.md` | Runnable repo proof. | Exact commands, port, DB setup, correct iOS/Android paths, expected evidence, advisory labels. | Contains bad commands/path/port and only bridge proof. | Rewrite and verify. |
| `guides/adoption.md` | Demo architecture. | Phoenix host authority, native shell role, offline island, IndexedDB outbox, `/study/sync`, Ecto idempotency, test lane. | Currently teaches bridge-owned sync and `Crosswake.mutate`. | Rewrite around v12 truth or remove until accurate. |
| `guides/support_truth.md` or README section | Human support legend. | Status, proof status, proof class, package class, rebuild required, advisory vs merge-blocking. | Full matrix has the data but is dense. | Add a friendly legend before the matrix. |
| `guides/support_matrix.md` | Canonical support and promotion reference. | Generated tables, proof hooks, promotion rules, public non-claims. | Canonical but too dense for first read; native host statement needs v13 reconciliation. | Keep canonical, update native evidence labels, link into friendlier guide. |
| `guides/troubleshooting.md` | Diagnostics and route-unavailable UX. | Common doctor findings, compile diagnostics, denial codes, "what to do next" by route owner. | Diagnostics exist in code; guide coverage is scattered. | Add a troubleshooting guide tied to doctor and denial vocabulary. |
| `guides/native_shell.md` | Native shell contract. | Manifest-first activation, route unavailable, host-owned shell, rebuild classes, generated/public deps vs local dev, advisory device proof. | Strong contract; stale standalone package sentence; Android advisory truth appears later. | Fix drift and make evidence classes obvious near top. |
| `guides/bridge.md` | Bounded bridge reference. | Request/reply envelope, command allowlist, denials, one-shot capability examples. | Good. | Keep, but ensure quick start references families, not commands. |
| `guides/offline.md` | Offline contract reference. | Cached read-only vs offline island, outbox/replay/conflict, rough edges. | Good narrow framing; shell verification wording may need update. | Link from adoption and quick start; reconcile proof hook status. |
| `guides/android_uat.md` | Advisory Android checklist. | JVM hermetic vs emulator/device vs provider status, last verified version, capability-by-capability evidence. | Stale and overclaims verification. | Relabel advisory or remove from primary map until current. |

### ExDoc Navigation

Crosswake already uses ExDoc extras and groups. v13 should reorganize the groups around how adopters think:

- **Start:** README, Start Here/User Flows, Quick Start.
- **Adopt:** Install, Route Policy, Web-to-Mobile Migration.
- **Runtime Owners:** LiveView/Phoenix-owned routes, Bridge, Offline, Native Shell, Packs/Transfers.
- **Truth:** Support Matrix, Compatibility, Troubleshooting, Android UAT.
- **Advanced/Companions:** Commerce, Companions, Threadline.

This matches idiomatic Elixir/Phoenix documentation patterns: a small runnable path first, then guides, then reference. Phoenix's public site puts "Try it now" commands before deeper docs, and the `mix phx.new` docs list flags, install behavior, and examples directly. ExDoc supports grouping extras, which Crosswake already uses; v13 should use that mechanism to make the route-owner path more obvious.

## UX/DX Microcopy Guidance

### Preferred Positioning Copy

- "Route policy for Phoenix apps that go mobile."
- "Declare which runtime owns each route."
- "Phoenix owns this route; the shell may provide one bounded native affordance."
- "This route is cached read-only. Local mutation is not allowed."
- "This route is an offline island with an app-owned outbox and explicit replay."
- "This route is native-owned. Crosswake will fail closed instead of silently falling back to a web upload."
- "Device evidence is not backend authority."
- "Simulator/device evidence is advisory unless promotion criteria say otherwise."
- "Run doctor to see manifest, support, bridge, offline, and shell posture."

### Avoid Or Replace

| Avoid | Use Instead | Why |
|-------|-------------|-----|
| "Build native apps from Phoenix" | "Declare route ownership for Phoenix apps that go mobile" | Avoids universal UI/framework implication. |
| "WebView wrapper" | "Host-owned native shell with manifest-first activation" | Wrapper language hides policy and diagnostics. |
| "Native API access" | "Bounded native affordance" | Prevents plugin-catalog expectations. |
| "Sync engine in the bridge" | "App-owned outbox plus Phoenix reconciliation endpoint" | The bridge must not become mutation authority. |
| "Offline support" | "Cached read-only route" or "offline island" | Forces honest scope. |
| "Verified Android" | "JVM hermetic", "emulator advisory", or "device verified" | Keeps proof class visible. |
| "Supported capability" without status | "Supported with verification required" or "advisory" | Avoids support overclaim. |
| "Fallback to web" | "Route unavailable" or "Phoenix-owned fallback" | No silent generic container behavior. |
| "Plugin" | "Capability family", "companion", or "defer" | Crosswake is not a plugin marketplace. |

### Denial And Diagnostic Copy Patterns

Good denial copy is short, route-specific, and action-oriented:

- `Route unavailable: this shell cannot activate "selective-native-claim-capture" because capture assets are missing. Update the app or return to the claim detail route.`
- `Native affordance skipped: "haptics" is not declared for "saas-approval". The Phoenix approval can still complete.`
- `Offline mutation blocked: this route is cached read-only. Move this workflow to an offline island if local progress must continue.`
- `Compatibility mismatch: this manifest requires bridge protocol 2.x, but the app binary supports 1.x. Rebuild the shell or serve a compatible manifest.`
- `Provider evidence only: this purchase event is queued for backend reconciliation and does not grant entitlement yet.`

Avoid:

- `Something went wrong.`
- `Native bridge failed.`
- `Unsupported plugin.`
- `Offline sync failed` without saying whether data is saved locally, queued, rejected, or conflicted.

### Collateral Captions

Every screenshot or short recording should carry:

- route id
- route owner (`:live_view`, bounded bridge, `:offline_island`, `:native_screen`)
- platform/browser
- package version
- commit SHA
- command used
- proof class: merge-blocking, advisory, or local-dev proof
- whether the route is Phoenix-owned, native-owned, or local-first

Example caption:

`offline-study | :offline_island | Chromium Playwright | crosswake 0.1.2 | commit <sha> | npm test -- offline_sync.spec.ts | merge-blocking proof | IndexedDB outbox -> /study/sync -> Ecto idempotency`

## Ecosystem Comparison

### Idiomatic Phoenix And Elixir Library Docs

Official Phoenix docs and HexDocs patterns favor:

- a short "try it now" command path before conceptual depth;
- explicit generator commands and flags;
- runnable examples that match project defaults;
- module/reference docs separated from guides;
- ExDoc extras grouped by reader task.

Crosswake should copy that shape, but with more support-truth labeling than a normal Phoenix library because Crosswake crosses runtime, native, and proof boundaries. The README should stay compact. The route-policy and migration guides should carry the conceptual weight. The support matrix should remain canonical reference, not the first onboarding surface.

Relevant official docs:

- Phoenix homepage "Try it now" uses direct commands for installing `phx_new` and creating a project: https://www.phoenixframework.org/
- `mix phx.new` docs document install behavior, options, and examples in one task page: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html
- Phoenix LiveView module docs open with the process/event/diff model and point beginners to a welcome guide: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- ExDoc supports grouping extras and modules, which Crosswake already uses: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html

### Lessons From Hotwire Native

Hotwire Native is the closest mental-model neighbor because it is route/path driven and web-first while still allowing bridge components and native screens. Its official docs explicitly separate path configuration, bridge components, navigation, and native screens. That separation is useful: readers understand that not every screen or feature has the same owner.

Crosswake should borrow:

- path/route configuration as a first-class concept;
- progressive enhancement language for small native affordances;
- explicit "native screen" escape hatch language;
- bundled configuration as reliable boot truth before remote/cached refinement.

Crosswake should not borrow:

- "web content displayed natively" as the core value;
- "native animations and behaviors automatically" as the main promise;
- a bridge-component catalog vibe that would compete with Crosswake's route-owner story.

Relevant official docs:

- Hotwire Native bridge components explain the web/native communication role and when fully native implementation is appropriate: https://native.hotwired.dev/overview/bridge-components
- Hotwire Native path configuration supports bundled, cached, and remote configuration: https://native.hotwired.dev/android/path-configuration
- Hotwire Native navigation can be customized by path configuration rules or manual Swift/Kotlin routing: https://native.hotwired.dev/reference/navigation

### Lessons From Capacitor

Capacitor is a useful contrast, not a model to emulate. Its docs are intentionally plugin-centric: JavaScript interfaces directly with native APIs, official/community plugins wrap platform differences, and app APIs expose lifecycle/deeplink state. That is correct for Capacitor, but the opposite of Crosswake's thesis.

Crosswake should borrow:

- crisp install snippets for native surfaces;
- clear per-platform notes when native project files must be edited;
- explicit plugin/API reference structure for low-level commands.

Crosswake should avoid:

- leading with native API access;
- presenting a plugin marketplace or broad device API catalog;
- implying a consistent cross-platform JavaScript API is the product.

Relevant official docs:

- Capacitor plugin docs present plugin APIs as the main bridge to native APIs: https://capacitorjs.com/docs/plugins
- Capacitor App API docs show per-platform project edits for custom scheme/deeplink handling: https://capacitorjs.com/docs/apis/app

## Requirements And Acceptance Criteria

### STG-01: One-Job Positioning And Route-Policy Guide

**Requirement:** The public docs must explain Crosswake's one job before any capability list: declare, enforce, and diagnose route ownership for Phoenix apps crossing into mobile.

Acceptance criteria:

- README, HexDocs main page, install guide, and quick start use one consistent one-liner.
- A dedicated `guides/route_policy.md` exists or `guides/user_flows.md` is promoted into that role with a route-policy section.
- Guide includes owner decision rules for `:live_view`, bounded bridge, cached read-only, `:offline_island`, `:native_screen`, backend seam, and defer.
- Guide shows one Phoenix router example for each supported owner class using current semantic capability families.
- Guide explains what manifest/doctor/support output is created from those route declarations.
- No first-read doc frames Crosswake as a universal UI framework, generic WebView wrapper, or LiveView-native renderer.

### STG-02: Support-Truth Guide Map

**Requirement:** The guide set must make support truth easy to navigate without forcing adopters to decode the full support matrix first.

Acceptance criteria:

- README has a "support truth in five labels" section: status, proof status, proof class, package class, rebuild required.
- `guides/support_matrix.md` remains canonical, generated/parity-checked, and linked from every capability/native/offline guide.
- New or updated troubleshooting guide maps common doctor findings and denial codes to route-owner fixes.
- ExDoc groups put Start/Adopt/Runtime Owners/Truth/Advanced in an adopter-readable order.
- Support truth labels distinguish merge-blocking, advisory, verification-required, JVM hermetic, emulator/device, and local-dev proof.

### STG-03: Proof Path And Guide Drift Cleanup

**Requirement:** The public proof path must be runnable and current.

Acceptance criteria:

- README and CHANGELOG agree with package truth or explicitly label fixture truth.
- `examples/QUICK_START.md` commands work from a clean checkout and use the correct example host setup commands, port, and iOS/Android project paths.
- Quick start demonstrates or links to proof for: Phoenix LiveView route, bounded bridge, offline island, and native screen/route-unavailable path.
- `guides/adoption.md` removes `Crosswake.mutate` and "Sync Engine (Bridge)" mutation authority.
- Adoption guide describes the v12 path: app-owned IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, accepted/rejected/conflict semantics, and no broad background sync.
- Stale "standalone public shell packages are deferred" language is removed or replaced.

### STG-04: Native Evidence Truth

**Requirement:** Native examples and guides must distinguish published-coordinate proof from local-development proof.

Acceptance criteria:

- Checked-in iOS host either uses published SwiftPM coordinate for current `0.1.2` proof or is labeled local-dev proof wherever linked.
- Checked-in Android host either uses `io.github.sztheory:crosswake-shell-core-android:0.1.2` proof or is labeled local-dev proof wherever linked.
- `--local` generator mode is documented as a maintainer/development path, not public install proof.
- Support matrix, native shell guide, quick start, README, and example host READMEs use the same classification.
- Android UAT guide no longer says stale v0.1.0 verification or lists unchecked provider/device capabilities as simply "Verified".
- Simulator/device evidence remains advisory unless promotion rules are met and documented.

### STG-05: Collateral And Evidence Receipts

**Requirement:** Seeing-is-believing collateral must make route ownership visible without promoting unproven support.

Acceptance criteria:

- Durable screenshots or short recordings exist for: Phoenix-owned LiveView route, bounded bridge affordance, offline island queued/replayed state, and native-screen/route-unavailable path.
- Each artifact caption includes route id, route owner, platform, command, package version, commit SHA, proof class, and advisory/support status.
- README or quick start links those artifacts.
- Collateral artifacts do not imply broad native device support unless the same status is present in support matrix and doctor proof.

### STG-06: Diagnostics As Product Surface

**Requirement:** Doctor, route-unavailable surfaces, and denials must be explained as adoption tools, not maintainer-only debug output.

Acceptance criteria:

- Troubleshooting guide includes examples for `undeclared_capability`, `unavailable_capability`, `compatibility_mismatch`, `pack_incompatible`, `external_entry_denied`, `gate_denied`, `step_up_required`, and offline conflict/replay failures.
- Each example says what route owner is involved and what the adopter should change.
- Quick start includes expected successful doctor output or at least expected proof surfaces.
- Route-unavailable copy distinguishes unsupported route, unsupported external entry, missing pack, origin denial, and compatibility mismatch.

### STG-07: Docs-Contract Tests

**Requirement:** v13 guide truth must be guarded mechanically where drift is cheap to detect.

Acceptance criteria:

- Test fails if README/CHANGELOG/package version truth diverges after release.
- Test fails if public guides contain "0.1.0" in current-baseline context without fixture labeling.
- Test fails if public guides say standalone public shell packages are deferred.
- Test fails if `guides/adoption.md` contains `Crosswake.mutate` or "Sync Engine (Bridge)" as mutation authority.
- Test fails if support-matrix rendered output and `guides/support_matrix.md` drift.
- Test or script verifies quick-start command snippets enough to catch missing `mix setup`, wrong port, and wrong iOS project path.

## Suggested Roadmap Shape

1. **Proof Debt And Truth Reconciliation**
   - Resolve or exclude TODO-001 from public proof.
   - Fix README/CHANGELOG/version truth and stale standalone-package language.
   - Add drift tests for version and forbidden support claims.

2. **Route-Policy And Migration Guide Set**
   - Add route-policy guide and web-to-mobile migration guide.
   - Promote `guides/user_flows.md` as Start Here or fold its mental model into the new route-policy guide.
   - Reorganize ExDoc guide groups.

3. **Runnable Quick Start And Adoption Guide**
   - Rewrite `examples/QUICK_START.md`.
   - Rewrite `guides/adoption.md` around app-owned offline proof.
   - Verify commands and expected evidence.

4. **Native Evidence Labels And Support Matrix**
   - Decide published-coordinate checked-in hosts vs explicit local-dev labels.
   - Reconcile native host READMEs, support matrix, native shell guide, Android UAT guide, README, and quick start.
   - Keep simulator/device proof advisory unless promoted.

5. **Collateral And Troubleshooting**
   - Capture labeled screenshots/recordings.
   - Add diagnostics/troubleshooting guide and route-unavailable copy examples.
   - Link artifacts from README/quick start.

## Non-Goals

- No product-code implementation in this research task.
- No new capability families.
- No broad native runtime expansion.
- No companion extraction.
- No generic plugin marketplace.
- No LiveView-rendered native UI claim.
- No generic WebView-wrapper positioning.
- No high-frequency bridge/event-bus surface.
- No app-wide local-first or background-sync promise.
- No promotion of simulator/device/provider proof from advisory to supported without repeatable proof and support-matrix promotion rules.
- No broad provider/storefront authority claim; backend reconciliation remains authority.
- No rewrite of checked-in native hosts unless a later implementation phase explicitly chooses that path.

## Source Notes

Repo-local sources inspected:

- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/MILESTONES.md`
- `.planning/research/v13-proof-path-docs.md`
- `README.md`
- `CHANGELOG.md`
- `mix.exs`
- `lib/crosswake/policy/*`
- `lib/crosswake/manifest/*`
- `lib/crosswake/doctor/*`
- `lib/crosswake/support_matrix/*`
- `lib/crosswake/bridge/*`
- `lib/crosswake/offline/*`
- `lib/crosswake/shell/*`
- `guides/*.md`
- `examples/QUICK_START.md`
- `examples/phoenix_host/*`
- `examples/ios_shell_host/*`
- `examples/android_shell_host/*`
- `test/**`
- `prompts/crosswake-research-synthesis.md`
- `brandbook/BRAND-SPEC.md`

External sources checked:

- Phoenix homepage: https://www.phoenixframework.org/
- Phoenix `mix phx.new` docs: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html
- Phoenix LiveView module docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- ExDoc `mix docs` docs: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
- Hotwire Native bridge components: https://native.hotwired.dev/overview/bridge-components
- Hotwire Native Android path configuration: https://native.hotwired.dev/android/path-configuration
- Hotwire Native navigation reference: https://native.hotwired.dev/reference/navigation
- Capacitor plugin docs: https://capacitorjs.com/docs/plugins
- Capacitor App API docs: https://capacitorjs.com/docs/apis/app

Method note: the GSD research-plan seam was attempted for the web comparison, but this environment's `gsd-tools.cjs` fallback reported `Unknown command: research-plan`. Official web sources were read directly instead. Repo-local evidence remains the authority for Crosswake conclusions.
