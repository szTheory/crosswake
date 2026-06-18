# Requirements: Crosswake - v13.0 Adopter Confidence & Native Evidence

**Defined:** 2026-06-18
**Core Value:** Make Crosswake visibly trustworthy to a skeptical Phoenix SaaS adopter by turning the real v11/v12 substrate into a current, runnable, visual, honestly labeled proof path.

## v1 Requirements

Requirements for milestone v13.0. Each maps to exactly one roadmap phase.

> Research backing every requirement: `.planning/research/SUMMARY.md`, `.planning/research/v13-proof-path-docs.md`, `.planning/research/v13-native-evidence.md`, `.planning/research/v13-collateral-ci.md`, and `.planning/research/v13-support-truth-guides.md`.
>
> **Scope lock:** v13.0 is adopter-confidence proof, not feature breadth. The milestone fixes proof-path drift, guide truth, native evidence classification, and visual/artifact evidence. It does not add capability families, a generic mobile UI layer, broad native runtime support, or app-wide offline claims.
>
> **Hard ordering:** local proof debt and public release truth must be cleaned before quick-start/collateral claims; route-policy/support framing must exist before hands-on guide rewrites; native coordinate truth must be settled before native screenshots are promoted; visual collateral comes last so captions and manifests carry the right proof labels.

### PROOF - Proof Debt And Release Truth

Make the public proof path clean before using it as adopter evidence.

- [ ] **PROOF-01**: `TODO-001` is resolved or explicitly excluded from the public proof path. The deterministic `CrosswakeExample.FlashcardsTest` schema/API drift is fixed or removed from advertised proof commands, the `CrosswakeExample.Chimeway.RegistryNotificationOpenTest` flake is made deterministic or excluded with a narrow reason, and no README/quick-start/proof command depends on known failing or flaky example-host tests.
- [ ] **REL-TRUTH-01**: Public release/docs truth agrees with `crosswake 0.1.2` or labels old fixture truth explicitly. README, CHANGELOG, install/native/compatibility guides, support matrix references, example manifests, ExDoc extras, and native guide prose must not claim latest Hex is `0.1.0`, `0.1.2` is pending, or standalone public shell packages are deferred.
- [ ] **DRIFT-01**: Cheap release-truth drift is mechanically guarded. A test or script fails when public docs reintroduce stale current-version claims, unlabelled `0.1.0` baseline claims, or deferred-standalone-shell prose that contradicts v11.0 release truth.

### GUIDE - Route-Policy And Support-Truth Guide Foundation

Make the adopter mental model obvious before the quick start and collateral teach flows.

- [ ] **GUIDE-01**: A route-policy/start-here guide path explains Crosswake's one job: declare, enforce, and diagnose route ownership for Phoenix apps that go mobile. It covers `:live_view`, bounded bridge, cached read-only, `:offline_island`, `:native_screen`, backend/provider seam, and defer decisions with current route-policy examples and links to manifest/doctor/support truth.
- [ ] **MIGRATE-01**: A web-to-mobile migration guide helps an existing Phoenix SaaS team inventory routes by job-to-be-done, default most routes to Phoenix/LiveView, promote only bounded native affordances where failure can degrade, reserve offline islands for explicit local mutation/replay, and promote native screens only where native runtime ownership is correct.
- [ ] **TRUTH-01**: README, ExDoc grouping, support matrix entry points, and guide maps use one support-truth vocabulary: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, and rebuild-required. The dense support matrix remains canonical but gets a friendlier first-read legend.

### QUICK - Runnable Quick Start And Real Adoption Proof

Turn the first hands-on adopter path into a command-verified proof of the real shipped architecture.

- [ ] **QUICK-01**: `examples/QUICK_START.md` is runnable from a clean checkout and names exact setup/server/native commands, the correct default Phoenix host port (`4002` unless intentionally changed), correct iOS and Android project paths, expected output, proof commands, and which native simulator/emulator steps are advisory.
- [ ] **ADOPT-01**: `guides/adoption.md` teaches v12 truth: app-owned offline island JavaScript, IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, outbox deletion, accepted/rejected/conflict semantics, and no broad background sync. It removes `Crosswake.mutate` and "Sync Engine (Bridge)" mutation authority from public guidance.
- [ ] **DRIFT-02**: Quick-start and adoption guide drift is mechanically guarded. A test or script catches missing setup aliases, wrong port/path claims, forbidden `Crosswake.mutate` examples, and bridge-owned offline mutation language.

### NATIVE - Native Evidence Classification

Make native proof labels impossible to misread before capturing or publishing native collateral.

- [ ] **NATIVE-01**: A v13 evidence-label decision records the valid native evidence classes and applies them consistently. Preferred path: checked-in iOS and Android hosts use published `0.1.2` coordinates by default, while `--local` remains the maintainer/development path. Acceptable fallback: checked-in hosts stay local-development proof only and are labeled that way everywhere.
- [ ] **NATIVE-02**: Native docs and support surfaces are reconciled to the chosen evidence class. Native host READMEs, quick start, README, native shell guide, support matrix, Android UAT guide, generator docs, and artifact captions distinguish published-coordinate proof from local-dev proof and do not describe Android JVM/hermetic or emulator evidence as physical-device support.
- [ ] **DRIFT-03**: Native evidence drift is mechanically guarded. A test or script fails if public proof references stale `dev.crosswake:shell-core-android:0.1.0`, silently uses an unlabelled `XCLocalSwiftPackageReference`, or drops required local-dev/advisory labels for checked-in host evidence.

### COLL - Collateral, Artifact CI, And Troubleshooting

Create seeing-is-believing evidence that is durable, useful, and honestly labeled.

- [ ] **COLL-01**: A deterministic browser route-tour proof runs in CI and captures/links evidence for a Phoenix-owned LiveView route, bounded bridge affordance, offline island queued/replayed state, and native-screen/route-unavailable path. The proof uses semantic assertions for correctness; screenshots are collateral, not the sole correctness check.
- [ ] **COLL-02**: Artifact packaging is explicit and bounded. Evidence bundles include a manifest with Crosswake version, commit SHA, route id, runtime owner, platform, command, proof class, source job, captured-at timestamp, and known limitations. Rich reports/traces/logs/videos are CI artifacts with bounded retention; committed docs assets are limited to a small optimized screenshot set plus manifest if needed.
- [ ] **NATIVE-COLL-01**: iOS simulator and Android emulator screenshots/recordings are captured as advisory evidence where available, with coordinate mode, version, command, route/flow, platform/runtime, and support label. They do not imply physical-device support, camera support, media upload support, provider authority, or merge-blocking support unless promotion criteria are explicitly added and met.
- [ ] **TROUBLE-01**: Troubleshooting and rough-edge docs explain doctor findings, denials, route-unavailable states, native evidence labels, offline replay/conflict failures, and what adopters should change by route owner. Covered examples include undeclared capability, unavailable capability, compatibility mismatch, pack incompatibility, external-entry denial, gate denial, step-up required, and offline conflict/replay outcomes.

## Future Requirements

Deferred to a later milestone. Tracked but not in this roadmap unless v13 proof work proves they are necessary for adopter evidence visibility.

### Operator Metrics

- **DASH-01**: Surface offline adoption and eviction metrics to the deferred `crosswake_dashboard`.

### Native Storage Budgets

- **NTV-01**: Extend storage budgets to native iOS/Android bridge commands that compute available physical disk space.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New capability families | v13 is about trust in the current surface, not expanding the catalog. |
| Companion package extraction | Valuable later, but it does not close the public proof-path drift blocking adopter confidence now. |
| Generic WebView-wrapper positioning | It conflicts with Crosswake's route-owner thesis. |
| LiveView-rendered native widgets | Crosswake is not a LiveView-to-native renderer. |
| High-frequency bridge/event-bus behavior | Bridge contracts stay typed, semantic, route-local, and low-frequency. |
| App-wide local-first or background-sync claims | Offline stays explicit: cached read-only is not local-first, and true offline islands need outbox/journal/replay/reconciliation proof. |
| Required simulator/emulator branch protection | Native visual evidence stays advisory unless repeatability and support-matrix promotion criteria justify promotion. |
| Physical-device, camera, media-upload, or provider-authority claims from simulator demos | Native capture collateral proves route ownership and transfer boundaries only. Backend/provider reconciliation remains authority. |
| Committed videos, Playwright reports, traces, generated native projects, build products, simulator devices, or emulator logs | Rich evidence belongs in CI artifacts with bounded retention; docs should carry a small curated screenshot set if needed. |
| DASH-01 and NTV-01 implementation by default | They remain deferred unless v13 implementation proves they are necessary for evidence visibility. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROOF-01 | 116 | Planned |
| REL-TRUTH-01 | 116 | Planned |
| DRIFT-01 | 116 | Planned |
| GUIDE-01 | 117 | Planned |
| MIGRATE-01 | 117 | Planned |
| TRUTH-01 | 117 | Planned |
| QUICK-01 | 118 | Planned |
| ADOPT-01 | 118 | Planned |
| DRIFT-02 | 118 | Planned |
| NATIVE-01 | 119 | Planned |
| NATIVE-02 | 119 | Planned |
| DRIFT-03 | 119 | Planned |
| COLL-01 | 120 | Planned |
| COLL-02 | 120 | Planned |
| NATIVE-COLL-01 | 120 | Planned |
| TROUBLE-01 | 120 | Planned |

**Coverage:**

- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-06-18*
*Last updated: 2026-06-18 - initial v13.0 requirements from research synthesis*
