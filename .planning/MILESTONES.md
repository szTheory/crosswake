# Project Milestones: Crosswake

## v2.0 Adopter Stress Profiles (Shipped: 2026-05-19)

**Delivered:** Three adopter-shaped exemplar lanes that pressure-tested the v1 Crosswake substrate and turned the resulting proof, diagnostics, and support posture into public product truth.

**Phases completed:** 6-10 (16 plans total)

**Key accomplishments:**
- Published a locked adopter-profile matrix and one shared example-host contract for realistic Crosswake app shapes.
- Proved a Phoenix-owned SaaS approvals lane with host-owned auth and one bounded haptics seam.
- Proved a selective-native claims-evidence corridor with one explicit `:native_screen` route plus route-local pack and transfer seams.
- Proved a local-first study flow with an append-only journal, sync endpoint, offline-island session, and cached read-only history lane.
- Hardened doctor diagnostics, per-profile verification scripts, CI, and support guidance around the rough edges exposed by the exemplars.

**Stats:**
- 86 files changed
- 6,640 insertions and 124 deletions
- 5 phases, 16 plans, 33 tasks
- 3 days from first seed to shipped milestone

**Git range:** `7f87976` → `45b7ea8`

**What's next:** Define the next milestone around Phoenix-first native capabilities, commerce support, and first-party companion seams without collapsing the route-policy thesis into a generic plugin surface.

---

## v3.0 Capability Contract And Packaging (Shipped: 2026-05-20)

**Delivered:** Capability taxonomy, package-boundary policy, commerce seam vocabulary, and proof/support truth that prepared Crosswake for native capability breadth without widening runtime ownership.

**Phases completed:** 11-14 (12 plans total)

**Key accomplishments:**
- Published capability-family taxonomy and route-owner decision rules.
- Classified `core`, `companion`, `example/docs-only`, and deferred surfaces with release and rebuild rules.
- Defined Phoenix-facing commerce and entitlement seams that keep entitlement truth backend-owned.
- Extended doctor, support-matrix, and proof-lane posture for future capability claims.

**Archive:**
- `.planning/milestones/v3.0-ROADMAP.md`
- `.planning/milestones/v3.0-REQUIREMENTS.md`

---

## v3.1 Native Capabilities and Bridge Expansion (Shipped: 2026-05-27)

**Delivered:** The first official low-frequency native capability families across Crosswake's bounded bridge contract, with route-local enforcement, support truth, and CI-backed proof.

**Phases completed:** 15-18 (16 plans total)

**Key accomplishments:**
- Implemented `haptics`, `share`, and `app_info` as base bounded bridge families across host and native shell surfaces.
- Added deep-link activation truth plus `permissions.status` as a read-only, notifications-scoped system-context bridge.
- Added `notification_token` and `file_picker` as asynchronous user-prompted capability families with provider-tagged evidence and transfer-bound staged handles.
- Canonicalized family-first route capability validation while preserving command-aware bridge lookup and the transfer-backed `file_picker` exception.
- Split support-matrix truth into baseline platform support, proof status, and capability-family posture.
- Added the dedicated `Phase 18 Proof` GitHub Actions lane and made it pass across Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

**Verification:**
- `bash script/verify_phase18_contract.sh` — 48 tests, 0 failures.
- `mix test` — 184 tests, 0 failures.
- GitHub Actions `Phase 18 Proof` run `26498172516` — passed in 6m34s.

**Known deferred items at close:** 3 human-UAT checks from Phase 15 remain acknowledged and deferred in `STATE.md`.

**Archive:**
- `.planning/milestones/v3.1-ROADMAP.md`
- `.planning/milestones/v3.1-REQUIREMENTS.md`

**What's next:** Start the next milestone with `$gsd-new-milestone`; the strategic arc currently points toward commerce and entitlement seams or the next operator/companion slice.

---
