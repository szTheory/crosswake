# First B2C Adopter Adoption Brief

## Reader and action

This brief is for a future maintainer or GSD session arriving without conversation history. After
reading it, the maintainer should be able to rank any proposed Crosswake work, reject work that
does not unblock the first adopter, and route the next task to the correct v21 phase.

The adopter is intentionally identified only as **First B2C Adopter**. Do not add identifying
business, founder, pricing, geography, customer, proprietary-taxonomy, or revealing-link details.

## Retrieval anchors

Use these terms to find this strategy:

- `GET-6`
- `First B2C Adopter`
- `first adopter`
- `infrastructure not business line`
- `web-only Alpha`
- `offline study island`
- `host-reusable proof lane`
- `scoped replay`
- `pronunciation pack`
- `physical iPhone`
- `Android frozen`
- `crosswake_sigra ownership`
- `stop building`

## Executive decision

Crosswake is infrastructure for the First B2C Adopter. It is not currently operated as a separate
business line.

The forcing function is one real Phoenix application running one real offline study session on one
physical iPhone, including real offline pronunciation audio and exactly-once replay. Framework
work stops after that dated proof except for defects the proof demonstrates.

The framing reverses only when:

1. two independent active adopters need overlapping generalized behavior; or
2. Crosswake receives a separately funded business-line mandate with its own schedule and success
   metrics.

Drifting between the two framings is not an option. It creates business-line costs without a
business-line forcing function.

## Surface-area audit

### Needed for the first adopter

| Surface | Why it stays active |
| --- | --- |
| Route-policy DSL and runtime manifest | Every route needs one explicit runtime owner and fallback |
| `:offline_island` journal, outbox, and reconciliation contract | The study session is the reason Crosswake exists |
| Cached read-only route posture | Path, dashboard, and history need honest degraded behavior |
| Bounded typed bridge | Audio and narrowly justified native affordances need a low-frequency seam |
| iOS shell generator and Swift package | Public v1 includes iPhone |
| Fail-closed denial posture | Framework and product bugs will arrive together |
| Existing `gated_by` seam | A shipped binary needs server-side disablement |
| `crosswake_sigra` route/session contract | Shell evidence must project backend authority without becoming token authority |
| LearnLoop browser offline proof | It is the closest existing study-island evidence |
| Doctor and troubleshooting entry points | A team of one needs self-service failure diagnosis |
| Host-reusable proof scaffolding | Existing adopter tests must survive the migration |
| One host-supplied iOS pack adapter | Real offline pronunciation bytes must replace simulated availability |

### Cheap to keep, but freeze

| Surface | Freeze rule |
| --- | --- |
| Brand tokens and existing assets | Keep working assets; no new brand-system program |
| Capability and support-truth taxonomy | Keep current labels; add no taxonomy unless existing labels cannot state device truth |
| Existing showcase fixtures and proof hosts | Preserve as evidence; no product-polish cycle |
| Android generator and Maven artifact | Keep building at current posture when shared code requires it |
| Android JVM tests and shared vectors | Preserve cheap hermetic regression coverage |
| Existing adopter-profile documents | Keep historical context; do not expand or promote them |
| Existing companion packages | Maintain compatibility; do not add companions |

### Business-line investment to stop paying for

| Surface | Verdict |
| --- | --- |
| Brandbook refinement | Stop |
| Showcase-hub polish | Stop |
| Three-profile narrative expansion | Stop |
| Launch, positioning, and marketing collateral | Stop |
| New support-truth label families | Stop unless existing vocabulary is technically insufficient |
| Native menu/action-button Phase 156 | Stop |
| Bundled Phase 157 native-control hardening/promotion program | Stop as a milestone |
| Android feature parity | Stop |
| Android emulator/device proof | Stop |
| Android template expansion | Stop |
| New companion adapters | Stop |
| Capture/device-controls pack | Stop |
| Commerce/paywall productionization | Stop |
| Operator dashboard | Stop |
| Generic offline-sync or native-storage productization | Stop |
| Broad reusable sync helpers | Stop |

Do not delete cheap existing assets merely to demonstrate focus. “Stop” means remove from active
roadmap, parity obligations, polish work, and launch expectations.

## Milestone split

### Customer Alpha

If customer Alpha is web-only, the Crosswake deliverable list is empty.

The only permitted early activity is the one-day route inventory because it can expose offline,
auth, and media design mistakes while they are cheap. It must not delay the Phoenix monolith,
billing, or customer acquisition.

### Public v1

Public v1 requires:

1. generated iOS shell integrated with a real host;
2. one offline study island;
3. account-scoped journal and replay;
4. offline pronunciation audio installed from verified real bytes;
5. backend-authoritative auth continuity;
6. server-side disablement at route entry and replay;
7. host-reusable browser/shell/device proof; and
8. a dated physical-iPhone artifact.

Crosswake is on the public-release path, not automatically the revenue-critical Alpha path.

## First move: the route-policy map

The route inventory is the right first move. It takes one focused day and needs:

- exact route IDs and paths;
- mutation actions and payload categories;
- cache staleness tolerance;
- auth level, recent-auth, logout, and account-switch behavior;
- expected audio archive sizes and codecs;
- online, offline, denied, corrupt-pack, and disabled fallbacks; and
- the host flag used to disable study entry and replay.

Default ownership:

| Surface | Owner |
| --- | --- |
| Study session | `:offline_island` |
| Learning path, dashboard, history | LiveView with cached read-only neighbors |
| Auth, settings, billing | `:live_view` |
| Pronunciation playback | Offline-island asset consumption |
| Microphone capture and offline scoring | Deferred |
| Auth continuity | `crosswake_sigra` plus backend authority |
| Emergency disablement | Host flag source through `gated_by` |

## Highest-impact Crosswake change

Build `mix crosswake.gen.proof_lane ios`.

The generator should copy host-owned, configurable ExUnit, Playwright, shell, and physical-device
proof scaffolding. Configuration includes route ID/path, IndexedDB database/store, mutation-ID
extraction, sync endpoint, evidence endpoint, router, and iOS shell root.

Time-box the extraction to three focused days. If existing host tests cannot be reused by then,
stop generalizing and copy the smallest adopter-specific proof slice.

Why the alternatives lose:

- Route mapping is essential, but it is a bounded adoption activity rather than a reusable
  framework change.
- Pack installation is a narrower risk and follows proof scaffolding.
- Most auth contract machinery already exists.
- A one-off device run creates evidence but not a repeatable host test system.
- More native controls do not unblock the study flow.

## Testing seam

The adopter can use Crosswake's proof posture, but not unchanged.

Preserve:

- the adopter's browser-driven end-to-end tests;
- unit tests;
- real fixture corpus;
- Crosswake's browser network-toggle and IndexedDB replay proof;
- generated-shell verification;
- Swift contract vectors; and
- doctor checks.

Add only three native flows:

1. shell boot and auth continuity;
2. offline answer, kill/relaunch, reconnect, and exactly-once replay; and
3. verified pack installation followed by offline audio playback.

Playwright remains the browser and offline-island web proof. XCTest/XCUITest plus a physical-device
artifact covers the shell and device-only boundaries. Simulator evidence remains advisory.

This is worth building because discarding an existing test corpus during the LiveView/mobile
transition would recreate a known rewrite failure mode.

## Pronunciation media gap

The gap is real and bounded. Current native pack stores simulate lifecycle transitions; they do not
download, verify, and atomically install production bytes.

The smallest honest version:

1. an iOS `PackProvider` supports foreground status, install, and invalidate;
2. no provider means not installed or failed, never available;
3. the host downloads one immutable archive into application-support storage;
4. the host verifies expected size and SHA-256;
5. the host atomically renames the verified archive into place; and
6. Crosswake activation remains denied until installed inventory matches the route requirement.

Ownership:

- Crosswake owns declaration, lifecycle vocabulary, installed inventory, activation denial, and
  diagnostics.
- The host owns URLs, authentication, CDN, archive and lesson layout, codecs, retention, storage
  budget, download UI, and failure copy.

The non-goal moves only enough to claim one host-supplied foreground iOS adapter. Crosswake still
does not claim generic productionized native content-pack storage.

Estimated effort: four focused Crosswake days and three to five adopter integration days.

## Privacy and replay obligation

Offline answers can include user-authored free-form content. The obligation crosses three layers:

- Crosswake core requires an opaque `scope_ref`, treats payloads as sensitive, and redacts them
  from telemetry, doctor, inspection, and evidence.
- The journal/outbox contract partitions entries by scope and stops replay on logout or account
  switch.
- The host maps scope to an account, authorizes every replay, and owns encryption, retention, and
  logout cleanup.

Raw answers must never enter cross-user aggregates. Evidence may contain versions, route IDs,
low-cardinality outcomes, and redacted hashes only.

## Auth and identity ownership

| Owner | Responsibility |
| --- | --- |
| Crosswake core | Route auth requirements, opaque scope envelope, fail-closed activation/replay denial, no credential authority |
| `crosswake_sigra` | Adapt backend session-authority projection, assurance/recent-auth checks, expiry/version/revocation/step-up denials, handoff and auth-return contracts |
| Sigra | Sessions, credentials, MFA, providers, revocation, identity records, backend authority |
| Host | Cookie/WebView configuration, account-to-scope mapping, endpoint authorization, logout cleanup, feature flags, product UX, provider wiring |

Host-specific behavior that must not become reusable Crosswake API:

- answer-event schema;
- curriculum and lesson taxonomy;
- pronunciation rubric, transcript, or scoring model;
- media archive layout and CDN paths;
- account and subscription model;
- exact flag names and rollout cohorts;
- product copy;
- authentication provider adapters; and
- business-specific retention policy.

## Server-side disablement

Do not build a Crosswake flag service.

Use the existing `gated_by` route seam and a host-supplied flag source. The replay endpoint must
re-check the flag and session authority. Disabled paths preserve queued events and show a visible
blocked state. App-review rollout, cohorts, and operational flag naming remain host-owned.

This prevents App Store review latency from turning one broken native path into an unbounded outage.

## iOS-only posture

Shipping iOS-only avoids:

- a second native implementation;
- TalkBack and Android interaction review;
- Android device/emulator evidence;
- parity-driven template work;
- Android-specific storage and lifecycle behavior;
- another release and compatibility obligation; and
- debugging two platform stacks while the product and framework fail together.

Retain the Android generator, Maven artifact, JVM tests, and shared vectors. Freeze everything else.
Shared-contract changes should keep existing hermetic Android checks green when cheap, but must not
create new parity scope.

## Non-goal defense

| Non-goal | First-adopter pressure | Boundary |
| --- | --- | --- |
| Generic app-wide sync | One study island needs replay | Hold: only route-local contract |
| Background sync | Transit use creates reconnect pressure | Hold: sync while app and route are active |
| Silent last-write-wins | Answer conflicts may occur | Hold: accepted, rejected, and conflict stay explicit |
| Multiple proven islands | Neighbor routes need offline access | Hold: cached read-only is enough |
| Productionized native pack storage | Offline audio needs real bytes | Move minimally: one host-supplied foreground iOS adapter |
| Broad reusable sync helpers | Host tests need reuse | Hold runtime boundary; reusable test scaffolding is allowed |

The boundary must not quietly turn Crosswake into a generic sync engine.

## Hands-off and operational lens

Diagnostics are over-invested in taxonomy and under-invested in “prove my host.”

Prefer:

- one command that tells a maintainer why their route, replay, pack, or shell cannot prove;
- explicit denial states;
- redacted artifacts;
- reproducible host proof;
- fail-closed version and capability mismatches; and
- recovery guidance that names the host-owned action.

Avoid:

- new label systems;
- dashboards before a real adopter;
- diagnostics that log payloads for convenience;
- silent fallback from offline mutation to online-only behavior;
- treating a timed UI transition as installed storage; and
- support claims derived from package versions alone.

## Stakeholder lens summary

| Lens | Priority | Footgun to avoid |
| --- | --- | --- |
| Learner/user | Offline study and audio survive transit, relaunch, and reconnect | Lost or cross-account answers |
| Product | Alpha can validate revenue without mobile blocking it | Letting substrate work delay customer learning |
| Design/UX | Clear offline, queued, conflict, missing-pack, and disabled states | Silent degradation or fake availability |
| Accessibility | Preserve web fallbacks; prove native semantics only where native UI ships | Adding native UI without device/accessibility proof |
| Architecture | One owner per route; backend authority remains explicit | Generic WebView or generic sync abstraction |
| Security/privacy | Scope isolation, replay reauthorization, payload redaction | Diagnostics becoming a data-exfiltration path |
| Testing | Preserve existing tests; add only device-bound gaps | Rewriting and discarding fixtures |
| DevOps/release | Minimize binary changes; make support truth reproducible | App Store hotfix assumptions |
| SRE/operations | Remote disablement and self-service diagnostics | Broken replay continuing after a kill switch |
| Solo maintainer | Time-box every framework change and stop after device proof | Endless “substrate not ready” work |

## Proxy failure audit

The canonical historical labels are not stored. Until sanitized labels are supplied, test every
decision against these proxy risks:

1. framework work starves the adopter;
2. a team of one accumulates operational surface;
3. unvalidated mobile behavior is treated as knowledge;
4. a rewrite discards valuable tests;
5. offline support is overclaimed; and
6. App Store latency leaves no server-side escape hatch.

## Dated execution order

| Phase | Target | Focused Crosswake effort |
| --- | --- | --- |
| 158 | 2026-07-31 | Adoption reset and route map — 1 day |
| 159 | 2026-08-03 through 2026-08-05 | Host-reusable proof lane — 3 days |
| 160 | 2026-08-06 through 2026-08-07 | Scoped replay and auth safety — 2 days |
| 161 | 2026-08-10 through 2026-08-13 | iOS pronunciation-pack seam — 4 days |
| 162 | 2026-08-14 through 2026-08-18 | Physical-iPhone proof — 2 to 3 days plus adopter availability |

After 2026-08-18, stop Crosswake work except for defects demonstrated by Phase 162.

## Physical-iPhone milestone

The exit artifact must prove:

1. online installation of one verified pronunciation pack;
2. offline study start;
3. selected and free-form offline answers;
4. offline audio playback;
5. kill/relaunch persistence;
6. exactly-once reconciliation and empty outbox;
7. recoverable rejection and conflict;
8. no cross-scope replay after logout or account switch;
9. server-side disablement of entry and replay without data loss; and
10. redacted evidence only.

Passing proves one adopter flow on one iOS runtime line. It does not prove generic sync,
background sync, generic storage, multiple islands, Android, or every iPhone.

## What to do next

Run `$gsd-discuss-phase 158`.

Use the route-policy map to collect sanitized route IDs, mutation categories, staleness, auth
posture, media budgets, fallbacks, and disablement behavior. Then plan only Phase 158. Do not jump
to Phase 159 implementation until the route inventory is frozen.

