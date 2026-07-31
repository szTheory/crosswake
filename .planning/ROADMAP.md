# Roadmap: Crosswake

## Milestones

- ✅ **v19.0 Showcase Apps & Capability Map** — Phases 147-152.1 (shipped 2026-07-12)
- ⏹ **v20.0 Native Controls Pack 1** — Phases 153-157 (stopped/partial 2026-07-30; no
  shipped claim or tag)

- 🚧 **v21.0 First B2C Adopter Readiness** — Phases 158-162 (active)

Older shipped milestones remain indexed in `.planning/MILESTONES.md`.

## v21.0 First B2C Adopter Readiness

**Goal:** Prove one real Phoenix application's offline study flow on one physical iPhone while
resisting framework generalization.

**Strategy source:** `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md`

**Operating rule:** Crosswake is infrastructure for the First B2C Adopter. If customer Alpha is
web-only, the Crosswake Alpha list is empty. Complete the one-day route inventory, then pause
Crosswake until the public-v1 mobile path is active.

**Stop date:** After 2026-08-18, do no further Crosswake work except defects demonstrated by Phase
162 evidence. Reconsider broader investment only after two independent active adopters or a
separately funded business-line mandate.

- [ ] **Phase 158: Adoption Reset and Route Map** — close GET-6, archive v20 honestly, freeze the
  surface-area audit, classify adopter routes, update support truth, and install privacy-safe
  context routing.

- [ ] **Phase 159: Host-Reusable Proof Lane** — generate configurable host-owned browser,
  shell, offline-island, and physical-device proof scaffolding.

- [ ] **Phase 160: Scoped Replay and Auth Safety** — enforce account-scoped outboxes, payload
  redaction, backend reauthorization, auth continuity, and server-side disablement.

- [ ] **Phase 161: iOS Pronunciation Pack Seam** — replace simulated availability with one
  host-supplied foreground iOS install path that verifies and atomically installs real bytes.

- [ ] **Phase 162: Physical-iPhone Adoption Proof** — prove offline answers, offline audio,
  kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote
  disablement on a physical iPhone.

## Phase Details

### Phase 158: Adoption Reset and Route Map

**Target:** 2026-07-31
**Effort:** 1 focused day
**Depends on:** Nothing
**Requirements:** RESET-01, RESET-02, RESET-03, RESET-04
**Plans:** 4 plans

Plans:
**Wave 1**

- [ ] 158-01-PLAN.md — Trace one sanitized route through closed validation and blocked promotion.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 158-02-PLAN.md — Canonicalize adoption implications and regenerate capability truth.
- [ ] 158-03-PLAN.md — Centralize privacy/context routing and lock stopped-v20 discoverability.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 158-04-PLAN.md — Reconcile public support truth and complete the Nyquist phase gate.

**Smallest shippable version:** Durable ADR, updated agent guide, one-day route-policy map, honest
v20 stopped/partial archive, refreshed requirements/roadmap/state, canonical capability/support
truth, and codename-only Linear drafts.

**Success criteria:**

1. A new session can discover the infrastructure framing, Alpha/v1 split, stop list, and current
   phase without re-deriving them.

2. Every known adopter surface has one runtime owner and one authority/fallback story.
3. v20 is preserved as partial work without representing Phases 156-157 as shipped.
4. Automated scans reject the prohibited real adopter name from planning, agent, and public-guide
   surfaces.

### Phase 159: Host-Reusable Proof Lane

**Target:** 2026-08-03 through 2026-08-05
**Effort:** 3 focused days
**Depends on:** Phase 158
**Requirements:** PROOF-01, PROOF-02, PROOF-03, PROOF-04

**Smallest shippable version:** `mix crosswake.gen.proof_lane ios` copies a host-owned scaffold
configured by explicit route, storage, mutation, endpoint, router, and shell-root values. It reuses
the current browser offline proof instead of inventing a second test system.

**Time-box:** If the scaffold cannot reuse existing host tests in three days, stop generalizing and
copy the smallest adopter-specific test slice.

**Success criteria:**

1. Generation is non-destructive and supports a diff/check mode.
2. Existing browser tests and fixtures remain the primary web/island coverage.
3. Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio.
4. Evidence generation fails when sensitive payload or identity fields appear.

### Phase 160: Scoped Replay and Auth Safety

**Target:** 2026-08-06 through 2026-08-07
**Effort:** 2 focused days
**Depends on:** Phase 159
**Requirements:** SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05

**Smallest shippable version:** Opaque scope on every envelope, scope-partitioned outbox,
logout/account-switch replay stop, endpoint reauthorization, raw-payload redaction, and host flag
checks at entry and replay.

**Success criteria:**

1. Cross-scope replay is impossible under tests.
2. Raw answers never enter telemetry, doctor output, inspection, or evidence.
3. `crosswake_sigra` adapts backend authority without making the WebView or shell a token authority.
4. A disabled path preserves queued data and visibly fails closed.

### Phase 161: iOS Pronunciation Pack Seam

**Target:** 2026-08-10 through 2026-08-13
**Effort:** 4 Crosswake days; expect 3-5 adopter integration days outside this repo
**Depends on:** Phase 160
**Requirements:** PACK-01, PACK-02, PACK-03, PACK-04, PACK-05

**Smallest shippable version:** One iOS `PackProvider` protocol with foreground status, install, and
invalidate; no provider means unavailable; availability follows verified size, SHA-256, and atomic
rename only.

**Success criteria:**

1. Simulated timed transitions can no longer imply real pack availability.
2. All corrupt, interrupted, missing, stale, or unconfigured paths fail closed.
3. Host and Crosswake ownership is explicit and tested.
4. Generic native content-pack storage remains a non-claim.

### Phase 162: Physical-iPhone Adoption Proof

**Target:** 2026-08-14 through 2026-08-18
**Effort:** 2-3 focused days plus adopter/backend availability
**Depends on:** Phase 161 and a runnable adopter host
**Requirements:** DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07

**Smallest shippable version:** A dated, redacted physical-iPhone artifact proving the ten-step exit
test in the adopter route-policy map.

**Success criteria:**

1. Verified pronunciation audio plays offline.
2. Selected and free-form answers survive offline use and kill/relaunch.
3. Reconnect applies accepted events exactly once and exposes rejection/conflict recovery.
4. Account switching, logout, and server disablement fail closed without losing or crossing data.
5. The support claim remains one adopter flow on one iOS runtime line.

## Frozen and stopped work

### Cheap to keep, frozen

- Brand tokens and existing brand assets.
- Current capability/support taxonomy.
- Existing Android generator, Maven artifact, JVM tests, and shared contract vectors.
- Existing showcase fixtures and proof hosts.

### Stop paying for now

- Brandbook, showcase hub, and adopter-profile polish.
- General launch, positioning, and framework marketing collateral.
- Native menu/action-button and broader native-control catalog work.
- Android feature parity, emulator/device proof, template expansion, and release requirements.
- New companion packages.
- Capture/device-control packs, commerce/paywall productionization, operator dashboard, and generic
  sync/native-storage productization.

- New support-truth labels unless the existing taxonomy cannot state a physical-device fact
  honestly.

## Non-goals that remain defended

- Generic app-wide sync.
- Background sync.
- Silent last-write-wins.
- Multiple proven offline-island workflows.
- Productionized generic native content-pack storage.
- Broad reusable runtime sync helpers.

The only boundary movement allowed in v21 is privacy-safe envelope constraints, reusable test
scaffolding, and one host-supplied foreground iOS pack adapter.

---
*Roadmap reset: 2026-07-30*
