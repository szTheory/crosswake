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

**Verification rule:** Automate every automatable acceptance claim. Human action is reserved for
credentials, external approvals, or irreversible trust steps; it does not replace executable
assertions. Add CI only for recurring contract value.

**Stop date:** After 2026-08-18, do no further Crosswake work except defects demonstrated by Phase
162 evidence. Reconsider broader investment only after two independent active adopters or a
separately funded business-line mandate.

- [x] **Phase 158: Adoption Reset and Route Map** — close GET-6, archive v20 honestly, freeze the (completed 2026-07-31)
  surface-area audit, classify adopter routes, update support truth, and install privacy-safe
  context routing.

- [x] **Phase 159: Host-Reusable Proof Lane** — generate configurable host-owned browser,
  shell, offline-island, and physical-device proof scaffolding (completed 2026-08-01).

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
**Plans:** 20/20 plans complete
**Verification:** Complete (4/4 roadmap must-haves); fresh final-tree direct, production, and
post-write evidence confirms generic textual privacy enforcement and stable route-map validation.

Plans:
**Wave 1**

- [x] 158-01-PLAN.md — Trace one sanitized route through closed validation and blocked promotion.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 158-02-PLAN.md — Canonicalize adoption implications and regenerate capability truth.
- [x] 158-03-PLAN.md — Centralize privacy/context routing and lock stopped-v20 discoverability.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 158-04-PLAN.md — Reconcile public support truth and complete the Nyquist phase gate.

**Wave 4** *(gap closure; blocked on Wave 3 completion)*

- [x] 158-05-PLAN.md — Make concrete-route safety and cross-field promotion invariants fail closed.
- [x] 158-06-PLAN.md — Enforce non-echoing first-adopter privacy scans over filesystem and CI surfaces.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 158-07-PLAN.md — Reconcile Phase 158 validation only after every gap-closure gate passes.

**Wave 6** *(gap closure; blocked on Wave 5 completion)*

- [x] 158-08-PLAN.md — Enforce protected private-term checks across trusted PR and fail-closed fork paths.
- [x] 158-09-PLAN.md — Repair canonical public capability wording and regenerate the guide.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 158-10-PLAN.md — Reconcile Phase 158 validation from a freshly passing, privacy-safe gate chain.

**Wave 8** *(gap closure; blocked on Wave 7 completion)*

- [x] 158-11-PLAN.md — Enforce opaque route IDs and a closed sanitized Phoenix path grammar.
- [x] 158-12-PLAN.md — Enforce exact public spelling and precise live identifying-field scans.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 158-13-PLAN.md — Format the capability renderer and prove all changed Elixir sources.

**Wave 10** *(blocked on Waves 8-9 completion)*

- [x] 158-14-PLAN.md — Rerun the complete gate and reconcile validation plus verification.

**Wave 11** *(gap closure; blocked on Wave 10 completion)*

- [x] 158-15-PLAN.md — Replace the fixed privacy allowlist with fail-closed repository candidate classification and unregistered-artifact regressions.

**Wave 12** *(blocked on Wave 11 completion)*

- [x] 158-16-PLAN.md — Reconcile validation and verification from fresh repository-wide privacy evidence.

**Wave 13** *(gap closure; blocked on Wave 12 completion)*

- [x] 158-17-PLAN.md — Make tracked textual action, script, and arbitrary future-phase artifacts scan by default and prove both scanner seams.

**Wave 14** *(blocked on Wave 13 completion)*

- [x] 158-18-PLAN.md — Reconcile validation and verification from fresh final-tree and post-write evidence.

**Wave 15** *(gap closure; blocked on Wave 14 completion)*

- [x] 158-19-PLAN.md — Close repository-wide generic privacy enforcement and malformed route-map input gaps.

**Wave 16** *(blocked on Wave 15 completion)*

- [x] 158-20-PLAN.md — Reconcile both remaining blockers from fresh final-tree and post-write evidence.

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
**Plans:** 14/14 plans executed
**Verification:** Complete (23/23 must-haves verified) — a fresh final-tree gate separately passed
post-create read/write/fsync cleanup, focused generator/config/template/iOS/evidence checks, the
real Phoenix-host browser corpus, generated shared XCTest/XCUITest execution, shell syntax, and
formatting. PROOF-01 through PROOF-04 are complete; TODO-002 remains open and adopter-instance
completeness remains `unknown_blocking`.

Plans:
**Wave 1**

- [x] 159-01-PLAN.md — Trace one Phoenix config through host-owned browser, ExUnit, iOS, and safe-evidence scaffolding.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 159-02-PLAN.md — Complete closed config plus collision-safe generate/check/diff lifecycle behavior.
- [x] 159-03-PLAN.md — Preserve the primary browser corpus and compile explicit XCTest/XCUITest boundaries.
- [x] 159-04-PLAN.md — Enforce typed allowlist evidence, final staged scanning, and atomic promotion.

**Wave 3** *(gap closure; independently blocked on the relevant executed Wave 2 plan)*

- [x] 159-05-PLAN.md — Confine every generator action to a normalized non-root host `native/ios` layout.
- [x] 159-06-PLAN.md — Restore type-checked browser proof and make unavailable iOS verification non-passing.
- [x] 159-07-PLAN.md — Bind retained identifiers and hashes to safe canonical sources and close promotion TOCTOU.

**Wave 4** *(gap closure; independently blocked on the relevant executed Wave 3 plan)*

- [x] 159-08-PLAN.md — Confine every generator filesystem action against symlink ancestors and ancestor-swap races.
- [x] 159-10-PLAN.md — Run the primary Phoenix-host browser corpus and enforce opaque mutation IDs.
- [x] 159-11-PLAN.md — Make malformed evidence lifecycle hooks fail closed without retained state.

**Wave 5** *(native gap closure; blocked on filesystem confinement)*

- [x] 159-09-PLAN.md — Execute host-adapter-backed XCTest/XCUITest through a shared scheme without persistent global mutation.

**Wave 6** *(blocked on all prior gap plans)*

- [x] 159-12-PLAN.md — Reconcile Phase 159 only from a fresh complete automated proof gate.

**Wave 7** *(gap closure; blocked on Wave 6 completion)*

- [x] 159-13-PLAN.md — Repair post-create and publication-collision cleanup with deterministic regressions.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 159-14-PLAN.md — Run the complete fresh final-tree gate and reconcile evidence-backed status.

**Cross-cutting constraints:**

- Generation and evidence promotion use collision-safe staged writes; interruption or a concurrent writer cannot overwrite host files or expose a partial retained artifact.
- Running generation twice with the same normalized configuration creates only missing scaffold and preserves every existing host-owned byte.
- Concurrent or interrupted generation fails closed on destination collisions and leaves existing host-owned files unchanged.

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
