# Phase 161: iOS Pronunciation Pack Seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-03
**Phase:** 161-ios-pronunciation-pack-seam
**Areas discussed:** Provider trust boundary, Restart and invalidation truth, Failure and recovery contract, Phase 159 proof hookup

---

## Provider Trust Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Requirement-bound host provider | Host returns a closed verified-install record bound to Crosswake's exact requirement; core does not consume paths or media. | ✓ |
| Crosswake independently hashes a returned file | Provider returns a final URL and core becomes a second filesystem verifier/inventory owner. | |
| Server-signed install receipt | Backend signature binds publisher provenance in addition to local verification. | |
| Apple-managed assets | Use On-Demand Resources or Background Assets as the storage/download authority. | |

**User's choice:** Consider every option through expert research and select one coherent recommendation set.
**Notes:** Selected the requirement-bound host provider because it preserves the accepted host/core boundary while allowing Crosswake to validate exact closed semantics. Independent core file ownership would widen Phase 161 into generic native storage; receipts and platform-managed assets add unsupported distribution/provenance surface.

---

## Restart and Invalidation Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Persisted display state is authority | Relaunch trusts the last `PackStore` state without storage reconciliation. | |
| Provider invents lifecycle truth | Each host provider exposes its own states and inventory semantics. | |
| Reconciliation-gated Crosswake inventory | Cold launch and completed operations reconcile provider storage into Crosswake's closed inventory before activation. | ✓ |

**User's choice:** Consider every option and make the decision on the user's behalf.
**Notes:** Cold launch begins `checking`; in-progress state never becomes restart authority. Last-known-good bytes survive failed replacement but stale bytes remain blocked. Explicit invalidation revokes trust and remains blocked across relaunch until completed or superseded by a verified reinstall.

---

## Failure and Recovery Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Raw provider errors | Surface native/downloader errors directly for maximum detail. | |
| Small closed reason vocabulary | Map provider failures into stable, non-echoing, low-cardinality reasons and semantic actions. | ✓ |
| One generic failure | Collapse all failures to `failed` and leave diagnosis entirely to the host. | |
| Automatic/background recovery | Retry failed installs without an explicit foreground user action. | |

**User's choice:** Emphasize developer ergonomics, least surprise, learner-friendly UI, accessibility, reliability, privacy, and operational recovery without exposing backend guts.
**Notes:** Crosswake owns semantic state/reason/action and stable diagnostics; the host owns final copy and UI. Recovery is explicit and foreground-only. Reference UX follows the newer `brandbook/BRAND-SPEC.md`, including calm actionable copy, text-not-color state, Dynamic Type, stable focus, reduced motion, and system light/dark behavior.

---

## Phase 159 Proof Hookup

| Option | Description | Selected |
|--------|-------------|----------|
| Fakes and simulated transitions only | Contract-test lifecycle without installing real bytes. | |
| New generic archive/proof subsystem | Crosswake owns generic downloads, storage, archive layout, and new device orchestration. | |
| Extend the existing lane with real fixture bytes | Reference provider performs real verification and atomic install; XCTest/XCUITest retain their existing responsibilities. | ✓ |

**User's choice:** Select a cohesive design that prepares Phase 162 without implementing it or widening the framework.
**Notes:** XCTest owns real-byte and failure contracts; XCUITest owns accessible user-observable install, relaunch, and offline-audio behavior. Fakes supplement but do not replace real bytes. A narrow host proof callback exercises audio without adding public asset lookup. Simulator evidence remains advisory; Phase 162 owns physical-device promotion.

---

## the agent's Discretion

- The user explicitly delegated the final decision set after three parallel `gsd-advisor-researcher` investigations plus reconciliation against the project prompt research and newer brand specification.
- Exact Swift names, private persistence format, actor mechanics, fixture bytes, generated callback name, and accessibility identifier names remain planner discretion.

## Deferred Ideas

- Server-signed receipts and shared publisher provenance.
- Generic asset lookup, archive layout, native storage, background/resumable transfer, delta updates, and eviction policy.
- Physical-device promotion and dated evidence, owned by Phase 162.
- Android pack/device work, microphone capture, offline scoring, and broader native audio controls.
