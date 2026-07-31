# Requirements: v21.0 First B2C Adopter Readiness

**Milestone goal:** Prove one real Phoenix application's offline study flow on one physical iPhone
without widening Crosswake into a generic sync, storage, native-control, or multi-platform
framework.

**Adopter naming:** Durable artifacts use **First B2C Adopter**. Public guides use **first
adopter**. Never store identifying business or personal information.

**Customer Alpha:** If Alpha is web-only, Crosswake has no Alpha requirement. The route inventory
is a bounded public-v1 design input and must not delay the adopter's monolith, billing, or customer
work.

## v1 Requirements

### RESET — Adoption boundary and route ownership

- [x] **RESET-01:** The infrastructure-versus-business-line decision, reversal condition, scope
  audit, non-goals, and stop list are durable and discoverable.

- [x] **RESET-02:** Every known first-adopter surface has an explicit runtime owner, offline
  posture, authority boundary, fallback, and remote-disable posture.

- [x] **RESET-03:** v20 is recorded as stopped/partial without a shipped claim or release tag, and
  Phases 156-157 are absent from active scope.

- [x] **RESET-04:** Planning and public adoption artifacts contain no prohibited adopter identity
  or personal information.

### PROOF — Host-reusable proof lane

- [ ] **PROOF-01:** `mix crosswake.gen.proof_lane ios` copies host-owned configurable ExUnit,
  Playwright, shell, and physical-device proof scaffolding without overwriting host files.

- [ ] **PROOF-02:** The scaffold accepts route ID/path, IndexedDB database/store, mutation-ID
  extraction, sync endpoint, evidence endpoint, router, and iOS shell root.

- [ ] **PROOF-03:** Browser proof preserves an adopter's existing browser/unit/fixture corpus and
  adds only shell/offline-island coverage that browser automation cannot provide.

- [ ] **PROOF-04:** Generated evidence rejects raw mutation payloads, account identifiers, media,
  tokens, and stable device identifiers.

### SCOPE — Privacy-safe replay and auth safety

- [ ] **SCOPE-01:** Journal and replay envelopes carry an opaque `scope_ref`; the outbox partitions
  entries by scope.

- [ ] **SCOPE-02:** Logout and account switching stop replay, and cross-scope replay fails closed.
- [ ] **SCOPE-03:** Replay re-checks backend session authority, route authorization, and
  server-side feature state before applying queued mutations.

- [ ] **SCOPE-04:** Raw answer payloads are excluded from telemetry, doctor output, inspection,
  logs, aggregates, and evidence artifacts.

- [ ] **SCOPE-05:** `crosswake_sigra` remains the adapter for backend session-authority evidence;
  credentials, provider/device identity, and token authority remain outside Crosswake core.

### PACK — Foreground iOS pronunciation media

- [ ] **PACK-01:** The iOS shell exposes a host-supplied foreground pack-provider seam for status,
  install, and invalidate.

- [ ] **PACK-02:** No provider, interrupted transfer, insufficient storage, wrong size, wrong
  digest, wrong version, or failed atomic install never reports `available`.

- [ ] **PACK-03:** One immutable pronunciation archive becomes available only after expected-size
  and SHA-256 verification followed by atomic installation.

- [ ] **PACK-04:** Crosswake owns declaration, lifecycle, inventory, activation denial, and
  diagnostics; the host owns URL/auth/CDN/layout/codecs/retention/storage budget/download UI.

- [ ] **PACK-05:** Background transfer, delta updates, generic eviction, Android storage, offline
  scoring, microphone capture, and generic content distribution remain explicitly unclaimed.

### DEVICE — Physical-iPhone adoption proof

- [ ] **DEVICE-01:** A physical iPhone installs one verified pronunciation pack and plays its audio
  while offline.

- [ ] **DEVICE-02:** The offline study route queues selected and free-form answers, survives
  kill/relaunch, reconnects, and reconciles exactly once until its outbox is empty.

- [ ] **DEVICE-03:** Rejected and conflict outcomes are visible and recoverable; no silent
  last-write-wins path exists.

- [ ] **DEVICE-04:** Logout and account switching produce no cross-scope replay.
- [ ] **DEVICE-05:** A host flag disables route entry and replay server-side without losing queued
  events or requiring a new binary.

- [ ] **DEVICE-06:** The dated proof artifact contains only runtime versions, route identifiers,
  device class, low-cardinality outcomes, and redacted hashes.

- [ ] **DEVICE-07:** The resulting support claim stays narrow: one adopter flow, one iOS runtime
  line, no Android/background/generic-storage/multiple-island claim.

## Out of Scope

| Surface | Reason |
| --- | --- |
| Generic app-wide sync | Domain authority and conflicts stay host-owned |
| Background sync | Active app and active route are sufficient for the first proof |
| Silent last-write-wins | Conflicts must remain explicit |
| Multiple proven offline islands | One study flow is the honest adoption unit |
| Generic productionized native pack storage | v21 permits one host-supplied iOS foreground adapter only |
| Broad runtime sync helpers | Test scaffolding may be reusable; domain reconciliation may not |
| Android feature, device, parity, or release work | Android is frozen outside the adopter's public v1 |
| Native menu/action-button work | Does not unblock the adopter |
| New companion packages | No adopter need justifies ecosystem expansion |
| Brandbook, showcase, profile, or launch polish | Business-line investment, not adopter infrastructure |
| Capture/device controls, commerce productionization, dashboard | Named future pressure, not v21 |
| Microphone capture and offline pronunciation scoring | Playback and study replay must prove first |

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| RESET-01 | Phase 158 | Gaps Found |
| RESET-02 | Phase 158 | Gaps Found |
| RESET-03 | Phase 158 | Gaps Found |
| RESET-04 | Phase 158 | Gaps Found |
| PROOF-01 | Phase 159 | Pending |
| PROOF-02 | Phase 159 | Pending |
| PROOF-03 | Phase 159 | Pending |
| PROOF-04 | Phase 159 | Pending |
| SCOPE-01 | Phase 160 | Pending |
| SCOPE-02 | Phase 160 | Pending |
| SCOPE-03 | Phase 160 | Pending |
| SCOPE-04 | Phase 160 | Pending |
| SCOPE-05 | Phase 160 | Pending |
| PACK-01 | Phase 161 | Pending |
| PACK-02 | Phase 161 | Pending |
| PACK-03 | Phase 161 | Pending |
| PACK-04 | Phase 161 | Pending |
| PACK-05 | Phase 161 | Pending |
| DEVICE-01 | Phase 162 | Pending |
| DEVICE-02 | Phase 162 | Pending |
| DEVICE-03 | Phase 162 | Pending |
| DEVICE-04 | Phase 162 | Pending |
| DEVICE-05 | Phase 162 | Pending |
| DEVICE-06 | Phase 162 | Pending |
| DEVICE-07 | Phase 162 | Pending |

**Coverage:** 25/25 requirements mapped. No Crosswake Alpha requirements.

---
*Requirements defined: 2026-07-30*
*Last updated: 2026-07-30 after adopter-priority reset*
