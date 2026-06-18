# Crosswake v13.0 Research Summary

**Project:** Crosswake  
**Milestone:** v13.0 Adopter Confidence & Native Evidence  
**Domain:** Phoenix-native route-policy library with iOS/Android shell evidence, adopter docs, proof-path CI, and support-truth collateral  
**Researched:** 2026-06-18  
**Confidence:** HIGH for repo-local findings; MEDIUM for simulator/emulator collateral repeatability and external ecosystem comparison

## Executive Summary

Crosswake should stay on a single v13.0 milestone: **Adopter Confidence & Native Evidence**. The product substrate is strong after v11.0 and v12.0: `crosswake 0.1.2` is published to Hex, Maven Central, and the SwiftPM mirror; generated shells resolve published native coordinates; and the offline proof now exercises the real IndexedDB outbox, reconnect flush, and Ecto reconciliation path. The remaining gap is not capability breadth. It is whether a skeptical Phoenix SaaS developer can run, see, and trust that proof path without reading milestone archaeology.

The research converges on one recommendation: make the public path current, runnable, visual, and honestly labeled. Fix `TODO-001` or exclude it from adopter proof, reconcile README/CHANGELOG/guides with `0.1.2`, replace stale quick-start and adoption-guide flows with v12 truth, classify checked-in native hosts as either published-coordinate proof or local-development proof, then capture durable browser/native evidence with proof-class labels. The docs should lead with **route policy for Phoenix apps that go mobile**, not a mobile framework, WebView wrapper, bridge API catalog, or universal offline engine.

The main risk is reintroducing ambiguity while trying to make the proof more compelling. Screenshots can overclaim. Simulator/emulator runs can look like supported device coverage. Checked-in local native hosts can masquerade as published install proof. v13 should mitigate this with explicit labels, docs-contract checks, artifact manifests, and a required browser route-tour proof while keeping iOS/Android simulator/emulator evidence advisory unless repeatability and support-matrix promotion criteria are added.

## Single Milestone Recommendation

Keep v13.0 as one milestone with a tight adopter-confidence scope. Do **not** split it into a new native-support milestone or a broad documentation milestone, and do **not** add new capability families to make collateral more impressive.

**Milestone outcome:** a Phoenix adopter can start from README/HexDocs, run a current quick start, understand route ownership, inspect support truth, and see labeled evidence for LiveView, bounded bridge, offline island, and native-screen paths.

**Done enough:**

- `TODO-001` is resolved or explicitly excluded from public proof.
- README, CHANGELOG, quick start, adoption guide, install/native/compatibility docs, ExDoc extras, and support truth agree with `0.1.2` or label old fixture truth.
- Public docs teach v12 offline truth: app-owned IndexedDB outbox, reconnect-triggered flush, `/study/sync`, Ecto idempotency, and no bridge-owned mutation authority.
- Checked-in iOS/Android hosts either prove published `0.1.2` coordinates or are labeled local-development proof everywhere they are referenced.
- Browser collateral is deterministic and CI-artifact-backed; native simulator/emulator collateral is labeled advisory unless promoted by explicit support criteria.

## Key Findings

### Proof Path And Docs

The package/release substrate is real, but public docs drift from it. `mix.exs` is at `0.1.2`, and external package truth was checked by the researchers, but README still says `0.1.0`, CHANGELOG still frames `0.1.2` as pending, quick start has bad commands/path/port, and adoption docs still describe a fictional bridge-owned sync API (`Crosswake.mutate`). Because ExDoc publishes README, CHANGELOG, and guides as extras, this is public documentation drift, not local cleanup.

Must fix:

- Release/version truth across README, CHANGELOG, guides, example manifests, and ExDoc extras.
- `examples/QUICK_START.md` command path: no missing `mix setup`, correct port `4002` unless changed, correct iOS project path, current Android path, and clear proof commands.
- `guides/adoption.md`: remove bridge-owned sync language and teach the v12 real offline path.
- Stale prose saying standalone public shell packages are deferred.
- Docs-contract checks for cheap drift signals: version truth, forbidden stale strings, quick-start command snippets, support-matrix parity.

### Native Evidence Truth

Generated non-local shells are the authoritative public install proof today. Templates and tests render the SwiftPM mirror and Maven Central coordinate at the Crosswake version, release clean-room jobs prove external resolution/builds, and `generator_coordinate_parity` guards the path.

Checked-in native hosts are not yet clean public-coordinate proof: iOS still uses a local Swift package ref, Android still references old `dev.crosswake:shell-core-android:0.1.0`, and READMEs/support wording can be read as adopter proof. Preferred v13 decision: convert checked-in hosts to published-coordinate defaults so screenshots/videos can honestly represent public install truth. Acceptable fallback: label checked-in hosts as local-development proof and route public install evidence through generated clean-room shells only. The current ambiguity is rejected.

### Collateral And CI Evidence

Use a browser-first, CI-artifact-first proof package with a small curated committed screenshot set. The Phoenix host already has deterministic Playwright infrastructure and real offline proof. A required browser route tour should exercise and capture LiveView, bounded bridge, offline island queued/replayed state, and native-screen route-policy/fallback surfaces.

Native iOS/Android evidence should be advisory in v13 unless promotion criteria are explicitly added and met. Existing simulator/emulator scripts are useful build/install/launch hooks, but they do not yet produce screenshots, recordings, logs, or machine-readable evidence manifests. Videos are useful as CI artifacts but should not be committed. Commit only a small optimized screenshot set plus a manifest if the assets are needed in README/guides.

### Support-Truth Guides

The strongest public story is: **Route policy for Phoenix apps that go mobile.** Crosswake's one job is to declare, enforce, and diagnose which runtime owns each route. The docs should organize around route owners and proof labels, not a capability catalog.

Guide priorities:

- A route-policy/start-here guide that teaches owner selection before syntax.
- A web-to-mobile migration guide for existing Phoenix SaaS teams.
- A friendlier support-truth legend before the dense support matrix.
- Troubleshooting/rough-edge docs tied to doctor findings, denial codes, route-unavailable states, and support labels.
- ExDoc grouping around Start, Adopt, Runtime Owners, Truth, and Advanced/Companions.

## Requirement Candidates

| Candidate | Requirement | Acceptance Direction |
|-----------|-------------|----------------------|
| `PROOF-01` | Public proof path is clean and not blocked by known local debt. | Resolve `TODO-001` or exclude it from public proof; proof commands do not depend on known failing/flaky tests. |
| `REL-TRUTH-01` | Public release/docs truth agrees with `0.1.2`. | README/CHANGELOG/guides/ExDoc extras do not claim `0.1.2` is pending or latest is `0.1.0`; fixtures are labeled if intentionally old. |
| `QUICK-01` | Quick start is runnable from a clean checkout. | Exact setup/server/native commands, correct port/path, expected evidence, advisory labels. |
| `ADOPT-01` | Adoption guide teaches real offline proof. | App-owned IndexedDB outbox, reconnect `flushOutbox`, `/study/sync`, Ecto idempotency, no `Crosswake.mutate` mutation authority. |
| `GUIDE-01` | Route-policy guide path is coherent. | Start-here/route-policy/migration/troubleshooting/rough-edge docs linked from README and ExDoc. |
| `NATIVE-01` | Native evidence classification is unambiguous. | Checked-in hosts prove published coordinates or are labeled local-dev proof everywhere; stale GAV/local refs cannot masquerade as public proof. |
| `TRUTH-01` | Support labels are consistent. | README, quick start, native shell guide, support matrix, and artifacts distinguish merge-blocking, advisory, local-dev, generated public-coordinate, JVM hermetic, emulator, and device proof. |
| `COLL-01` | Durable evidence makes route ownership visible. | Screenshots/recordings/artifacts cover LiveView, bounded bridge, offline island, and native-screen path with version/SHA/command/proof-class metadata. |
| `DOCS-GUARD-01` | Cheap documentation drift is mechanically guarded. | Tests/scripts fail on stale version claims, forbidden deferred-shell prose, fictional offline APIs, support-matrix drift, and quick-start command/path/port mistakes. |

## Tradeoffs And Locked Decisions

### Locked Decisions

- v13 is adopter-confidence proof before feature breadth.
- Route ownership remains the organizing model: `:live_view`, bounded bridge, cached read-only, `:offline_island`, `:native_screen`, backend seam, or defer.
- Bridge contracts stay typed, semantic, versioned, route-local, and low-frequency.
- Offline claims stay narrow: cached read-only is not local-first; local-first means explicit outbox/journal, replay, conflict/idempotency behavior, and Phoenix authority.
- Generated public-coordinate shells are already the authoritative install proof; checked-in hosts must be reconciled or labeled before they appear in public collateral.
- Browser proof should be the required deterministic lane; simulator/emulator/native visual evidence stays advisory unless promoted by explicit support criteria.
- Visual collateral supplements mechanical proof; it does not prove dependency resolution, offline reconciliation, device support, camera support, or provider authority by itself.

### Open Tradeoffs For Planning

- **Checked-in host strategy:** prefer converting iOS/Android examples to published `0.1.2` coordinates; fallback to explicit local-dev labels if conversion destabilizes v13.
- **Quick-start shape:** keep one entry point, but split it into clear sections for package evaluation, repo proof, and native advisory evidence.
- **Collateral storage:** commit only a small curated PNG set plus manifest; upload richer Playwright reports, traces, logs, native screenshots, and short recordings as CI artifacts.
- **Native promotion:** do not promote simulator/emulator runs to supported device proof unless v13 adds repeatable promotion criteria and updates support matrix/doctor truth accordingly.

## Implications For Roadmap

Suggested phase structure: **5 phases**, continuing after v12.0 Phase 115.

### Phase 116: Proof Debt And Release Truth

**Rationale:** Public proof cannot be trusted while known local debt and version contradictions remain. This is the first dependency for every later adopter claim.

**Delivers:** `TODO-001` resolved or excluded; README/CHANGELOG/package truth reconciled; stale standalone-package deferred prose removed; initial docs-contract checks for version and forbidden public claims.

**Requirement candidates:** `PROOF-01`, `REL-TRUTH-01`, `DOCS-GUARD-01`.

**Pitfalls to avoid:** burying fixture truth without labels; letting ExDoc publish stale public claims; making proof commands depend on flaky/local debt.

### Phase 117: Route-Policy And Support-Truth Guide Foundation

**Rationale:** The route-owner mental model should be in place before rewriting quick start and collateral captions; otherwise the docs will drift back toward feature catalog language.

**Delivers:** route-policy/start-here guide; web-to-mobile migration guide; support-truth legend; ExDoc grouping updates; guide map around Start, Adopt, Runtime Owners, Truth, Advanced.

**Requirement candidates:** `GUIDE-01`, `TRUTH-01`.

**Pitfalls to avoid:** positioning Crosswake as a mobile framework, WebView wrapper, native API plugin catalog, or LiveView-to-native renderer.

### Phase 118: Runnable Quick Start And Real Adoption Proof

**Rationale:** Once release truth and guide framing are fixed, the first hands-on path can become command-verified without teaching stale architecture.

**Delivers:** rewritten `examples/QUICK_START.md`; adoption guide rewritten around v12 app-owned IndexedDB outbox/reconnect/Ecto proof; quick-start command/path/port verification; links to LiveView, bridge, offline island, and native-screen/advisory evidence.

**Requirement candidates:** `QUICK-01`, `ADOPT-01`, `DOCS-GUARD-01`.

**Pitfalls to avoid:** reintroducing `Crosswake.mutate`, "Sync Engine (Bridge)" mutation authority, broad offline promises, or unverified commands.

### Phase 119: Native Evidence Classification

**Rationale:** Native screenshots and support claims must not be captured until coordinate truth is settled. This phase locks whether checked-in hosts are public-coordinate proof or local-dev proof.

**Delivers:** v13 evidence-label decision; checked-in host coordinate update or explicit local-dev labeling; native host READMEs, quick start, native shell guide, support matrix, and Android UAT wording reconciled; guard against stale native coordinate claims.

**Requirement candidates:** `NATIVE-01`, `TRUTH-01`, `DOCS-GUARD-01`.

**Pitfalls to avoid:** screenshots from local hosts marketed as public install proof; `dev.crosswake:shell-core-android:0.1.0` surviving in public proof; iOS local refs hidden behind "remote" headings.

### Phase 120: Collateral, Artifact CI, And Troubleshooting

**Rationale:** Collateral comes last so every screenshot, recording, manifest, and caption reflects corrected proof truth and native labels.

**Delivers:** required browser route-tour proof with artifact upload; curated committed screenshot set if needed; optional/advisory iOS and Android artifact lanes; artifact manifest validator; troubleshooting guide for doctor findings, denials, route-unavailable states, offline replay/conflict failures, and native evidence caveats.

**Requirement candidates:** `COLL-01`, `TRUTH-01`, `GUIDE-01`.

**Pitfalls to avoid:** treating screenshots as proof of offline correctness; committing videos/reports/logs; making flaky native visuals merge-blocking; implying device/camera/provider support from simulator demos.

### Phase Ordering Rationale

- Proof debt and release truth must come first because every later guide, screenshot, and support claim depends on them.
- Route-policy/support framing should precede quick-start rewrite so commands are attached to the right mental model.
- Quick start and adoption guide should precede collateral because they define which flows are worth capturing.
- Native classification must precede native collateral so evidence cannot silently overclaim public install truth.
- Troubleshooting and artifact CI fit last because they consolidate the corrected proof path into visible, durable adopter evidence.

### Research Flags

Likely needs deeper phase research:

- **Phase 119:** native host coordinate conversion details may require Xcode/Gradle fixture validation before choosing the preferred path.
- **Phase 120:** simulator/emulator capture repeatability and artifact workflow design need hands-on validation before any promotion beyond advisory.

Standard patterns; skip extra research unless implementation finds surprises:

- **Phase 116:** docs drift checks and version truth reconciliation are source-local and well bounded.
- **Phase 117:** route-policy/support guide structure is well supported by repo-local architecture and official docs patterns.
- **Phase 118:** quick-start/adoption rewrite is well specified by existing Phoenix host proof and v12 E2E truth.

## Non-Goals

- No product-code implementation in this research task.
- No new capability families.
- No companion package extraction.
- No broad native runtime expansion or OS/device support matrix expansion.
- No dashboard metrics unless v13 proves `DASH-01` is necessary for adopter evidence visibility.
- No native disk-space budget work unless v13 proves `NTV-01` is necessary for adopter evidence visibility.
- No generic WebView wrapper positioning.
- No LiveView-rendered native UI claim.
- No high-frequency bridge/event-bus surface.
- No app-wide local-first or background-sync promise.
- No production camera/media upload/provider authority claim from native capture demos.
- No required simulator/emulator branch-protection lane in v13 unless promotion criteria are added and met.
- No committed videos, full Playwright reports, generated native build products, simulator devices, or emulator logs.

## Evidence Caveats

- `0.1.2` package truth is high-confidence from repo and registry checks, but `MIRROR_PUSH_TOKEN` write scope remains unexercised until the next iOS mirror release.
- SwiftPM `upToNextMajorVersion` with a `0.1.2` floor is not the same as exact-version proof unless the artifact captures `Package.resolved` or build logs.
- The checked-in native hosts currently do not prove public `0.1.2` coordinates; do not use their screenshots as public install evidence until reconciled or labeled.
- Simulator/emulator evidence is environment-sensitive and should be advisory unless repeated runs and support-matrix promotion criteria justify more.
- Android JVM/hermetic proof is not device proof. Emulator evidence is not physical-device proof.
- Native capture demo evidence is native-screen/transfer-boundary proof, not production camera support or media upload support.
- Browser screenshots make the route-policy story visible, but the actual offline correctness proof remains the v12 E2E assertions: UI-driven queue, IndexedDB observation, reconnect-triggered flush, `/study/sync`, Ecto polling, outbox deletion, and idempotency.
- Playwright reports, traces, logs, and artifacts can contain sensitive data; keep rich artifacts in GitHub Actions storage with bounded retention, not public docs hosting.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Proof path/docs drift | HIGH | Direct source inspection and package truth checks agree across research files. |
| Native evidence truth | HIGH for current drift; MEDIUM for conversion effort | Generator path and checked-in host drift are source-confirmed; actual host conversion should be validated in implementation. |
| Collateral/CI approach | HIGH for browser-first recommendation; MEDIUM for native capture | Existing Playwright proof is deterministic; simulator/emulator capture remains environment-sensitive until exercised. |
| Support guide architecture | HIGH | Route policy, manifest, doctor, support matrix, bridge, and offline contracts align with the guide recommendation. |
| External documentation patterns | MEDIUM | Official docs were checked and are useful as onboarding-shape guidance, but repo truth remains authoritative. |

**Overall confidence:** HIGH for roadmap direction; MEDIUM for native visual evidence repeatability.

### Gaps To Address During Planning

- Decide whether checked-in iOS/Android hosts become published-coordinate proof or local-dev proof.
- Decide the exact evidence-label vocabulary and ensure README, quick start, support matrix, native guide, and artifact manifests use it consistently.
- Validate quick-start commands from a clean checkout before treating them as adopter proof.
- Validate simulator/emulator screenshot/recording commands before promoting any native collateral beyond advisory.
- Determine whether Android UAT guide should be relabeled advisory, narrowed, or removed from first-read docs until current.

## Sources

### Primary Repo Sources

- `.planning/PROJECT.md` — v13 scope, active requirements, constraints, decisions, non-goals.
- `.planning/STATE.md` — active blockers, `TODO-001`, native drift, collateral gap, advisory evidence posture.
- `.planning/research/v13-proof-path-docs.md` — proof-path, release truth, quick-start, adoption-guide drift.
- `.planning/research/v13-native-evidence.md` — native coordinate truth, checked-in host options, simulator/emulator caveats.
- `.planning/research/v13-collateral-ci.md` — artifact taxonomy, browser-first CI recommendation, native advisory lanes.
- `.planning/research/v13-support-truth-guides.md` — route-policy story, support guide map, troubleshooting and docs-contract candidates.

### Repo Areas Inspected By Researchers

- `README.md`, `CHANGELOG.md`, `mix.exs`, `guides/*.md`, `examples/QUICK_START.md`.
- `examples/phoenix_host/*`, including Playwright config and offline E2E proof.
- `examples/ios_shell_host/*`, `examples/android_shell_host/*`.
- `priv/templates/crosswake/shell/**`, `test/mix/tasks/crosswake_gen_shell_test.exs`.
- `.github/workflows/*`, `script/verify_generated_ios_shell.sh`, `script/verify_generated_android_shell.sh`.
- `lib/crosswake/policy/*`, `lib/crosswake/manifest/*`, `lib/crosswake/doctor/*`, `lib/crosswake/support_matrix/*`, `lib/crosswake/bridge/*`, `lib/crosswake/offline/*`.

### External Sources Used By Researchers

- Phoenix, Phoenix LiveView, and ExDoc official docs for onboarding/guide shape.
- Hotwire Native docs for route/path-driven native/web separation patterns.
- Capacitor docs as a contrast for plugin-centric native API positioning.
- GitHub Actions `upload-artifact` docs for artifact taxonomy and upload behavior.
- Playwright CI, screenshot, trace, and video docs for browser artifact strategy.
- Apple Simulator `simctl` and Android `adb`/emulator docs for advisory native capture mechanics.

---
*Research completed: 2026-06-18*  
*Ready for roadmap: yes*
