# Requirements: v21.0 First B2C Adopter Readiness

**Milestone goal:** Prove one real Phoenix application's offline study flow on one physical iPhone
without widening Crosswake into a generic sync, storage, native-control, or multi-platform
framework.

**Adopter naming:** Durable artifacts use **First B2C Adopter**. Public guides use **first
adopter**. Never store identifying business or personal information.

**Customer Alpha:** If Alpha is web-only, Crosswake has no Alpha requirement. The route inventory
is a bounded public-v1 design input and must not delay the adopter's monolith, billing, or customer
work.

**Verification posture:** Automatable acceptance uses executable unit, integration, E2E, device,
or artifact checks rather than conversational verification or manual UAT. Checks enter CI only
when they protect a recurring contract; one-time reconciliation remains phase evidence.

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

- [x] **PROOF-01:** `mix crosswake.gen.proof_lane ios` copies host-owned configurable ExUnit,
  Playwright, shell, and physical-device proof scaffolding without overwriting host files.

- [x] **PROOF-02:** The scaffold accepts route ID/path, IndexedDB database/store, mutation-ID
  extraction, sync endpoint, evidence endpoint, router, and iOS shell root.

- [x] **PROOF-03:** Browser proof preserves an adopter's existing browser/unit/fixture corpus and
  adds only shell/offline-island coverage that browser automation cannot provide.

- [x] **PROOF-04:** Generated evidence rejects raw mutation payloads, account identifiers, media,
  tokens, and stable device identifiers.

### SCOPE — Privacy-safe replay and auth safety

- [x] **SCOPE-01:** Journal and replay envelopes carry an opaque `scope_ref`; the outbox partitions
  entries by scope.

- [x] **SCOPE-02:** Logout and account switching stop replay, and cross-scope replay fails closed.
- [x] **SCOPE-03:** Replay re-checks backend session authority, route authorization, and
  server-side feature state before applying queued mutations.

- [x] **SCOPE-04:** Raw answer payloads are excluded from telemetry, doctor output, inspection,
  logs, aggregates, and evidence artifacts.

- [x] **SCOPE-05:** `crosswake_sigra` remains the adapter for backend session-authority evidence;
  credentials, provider/device identity, and token authority remain outside Crosswake core.

### PACK — Foreground iOS pronunciation media

- [x] **PACK-01:** The iOS shell exposes a host-supplied foreground pack-provider seam for status,
  install, and invalidate.

- [x] **PACK-02:** No provider, interrupted transfer, insufficient storage, wrong size, wrong
  digest, wrong version, or failed atomic install never reports `available`.

- [x] **PACK-03:** One immutable pronunciation archive becomes available only after expected-size
  and SHA-256 verification followed by atomic installation.

- [x] **PACK-04:** Crosswake owns declaration, lifecycle, inventory, activation denial, and
  diagnostics; the host owns URL/auth/CDN/layout/codecs/retention/storage budget/download UI.

- [x] **PACK-05:** Background transfer, delta updates, generic eviction, Android storage, offline
  scoring, microphone capture, and generic content distribution remain explicitly unclaimed.

### NAV — First-adopter iOS navigation shell

- [ ] **NAV-01:** A compiled first-adopter topology declares stable root-tab IDs, root routes,
  pushed-detail presentation, and parent relationships without transferring leaf-route ownership
  away from Phoenix, offline islands, or native screens.

- [ ] **NAV-02:** The host-owned iOS shell renders native root tabs and pushed detail navigation
  with edge-swipe/back behavior while the existing route resolver remains authoritative for each
  destination's runtime owner.

- [ ] **NAV-03:** Web/native stack synchronization is typed, versioned, and fail-closed:
  `push_patch` changes the current web route without growing the native stack, while
  `push_navigate` produces one idempotent native transition.

- [ ] **NAV-04:** The shell publishes live `--cw-safe-area-top`, `--cw-safe-area-right`,
  `--cw-safe-area-bottom`, and `--cw-safe-area-left` CSS custom properties across viewport changes;
  keyboard occlusion is represented separately as `--cw-keyboard-inset-bottom`.

- [ ] **NAV-05:** The document root receives a synchronous, declarative native-shell marker before
  app CSS evaluates, without a custom user-agent or any account, device, or stable identity value.

- [ ] **NAV-06:** Executable graph, synchronization, simulator, accessibility-focus, and bounded
  device checks prove the shell contract without claiming Android parity or generic navigation.

- [ ] **NAV-07:** Canonical and generated support truth says Phoenix-owned confirmation is the
  current required fallback; native alert/confirm remains reversible only after physical-iPhone
  proof, a demonstrated active-adopter route blocker, and an explicit maintainer roadmap decision.

### DEVICE — Physical-iPhone adoption proof

- [x] **DEVICE-01:** A physical iPhone installs one verified pronunciation pack and plays its audio
  while offline.

- [x] **DEVICE-02:** The offline study route queues selected and free-form answers, survives
  kill/relaunch, reconnects, and reconciles exactly once until its outbox is empty.

- [x] **DEVICE-03:** Rejected and conflict outcomes are visible and recoverable; no silent
  last-write-wins path exists.

- [x] **DEVICE-04:** Logout and account switching produce no cross-scope replay.
- [x] **DEVICE-05:** A host flag disables route entry and replay server-side without losing queued
  events or requiring a new binary.

- [x] **DEVICE-06:** The dated proof artifact contains only runtime versions, route identifiers,
  device class, low-cardinality outcomes, and redacted hashes.

- [x] **DEVICE-07:** The resulting support claim stays narrow: one adopter flow, one iOS runtime
  line, no Android/background/generic-storage/multiple-island claim.

### ALPHA — Bounded reference-host integration

- [x] **ALPHA-01:** The anonymous First B2C Adopter reference host installs one foreground, versioned learning
  bundle containing a card manifest plus exact image and pronunciation-audio assets; every
  manifest and asset byte is verified before atomic availability.

- [x] **ALPHA-02:** The selected offline study route renders only from the installed bundle across
  offline use and kill/relaunch, and never claims generic native storage or background content
  synchronization.

- [x] **ALPHA-03:** Reconnect revalidates backend-owned session, opaque scope, route, and feature
  authority before ordered idempotent replay of the one review mutation; account switch, logout,
  revocation, and disablement deny without scope crossing.

- [x] **ALPHA-04:** Browser, iOS, and physical-proof automation demonstrate the bounded bundle and
  replay lifecycle while retaining only redacted contract evidence; a connected signed iPhone is
  the sole remaining human setup gate.

### COMPOSE — Physical adopter composition closure

- [ ] **COMPOSE-01:** A current host-owned sanitized handoff validates through the closed route
  inventory and compiles a ready navigation topology before adopter binding, physical execution,
  evidence publication, or support promotion; fixture and simulator output remain non-promoting.

- [ ] **COMPOSE-02:** The eligible physical host composes the delivered bounded iOS navigation shell
  and its coordinator with a host-supplied study leaf, preserving typed transitions, retained stacks,
  marker, and live inset contracts without a second route authority.

- [ ] **COMPOSE-03:** The physical host reaches offline-media availability only through one
  host-private `PackProvider` and fresh `PackStore` reconciliation, preserving verified atomic
  manifest/image/audio install, relaunch, rollback, and revocation truth.

- [ ] **COMPOSE-04:** Device-caused rejection, conflict, logout, account-switch, entry-disablement,
  and replay-disablement cases traverse the normal iPhone-to-Phoenix path, preserve scoped queued
  work, and pair device-observed recovery with independent backend authority checks.

- [ ] **COMPOSE-05:** Exact approved physical-marker and reference-host media routing remains
  privacy-safe and fail-closed; only redacted device/backend evidence may join, with raw handoff,
  payload, account, scope, media, endpoint, and device details excluded.

- [ ] **COMPOSE-06:** Closure requires fresh composed-target automation, a source-bound physical
  run against validated TODO-002 input, outstanding Nyquist validation, and a fresh milestone audit;
  fixture or simulator evidence cannot substitute for the signed-device execution.

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
| RESET-01 | Phase 158 | Complete |
| RESET-02 | Phase 158 | Complete |
| RESET-03 | Phase 158 | Complete |
| RESET-04 | Phase 158 | Complete |
| PROOF-01 | Phase 159 | Complete |
| PROOF-02 | Phase 159 | Complete |
| PROOF-03 | Phase 159 | Complete |
| PROOF-04 | Phase 159 | Complete |
| SCOPE-01 | Phase 160 | Complete |
| SCOPE-02 | Phase 160 | Complete |
| SCOPE-03 | Phase 160 | Complete |
| SCOPE-04 | Phase 160 | Complete |
| SCOPE-05 | Phase 160 | Complete |
| PACK-01 | Phase 161 | Complete |
| PACK-02 | Phase 161 | Complete |
| PACK-03 | Phase 161 | Complete |
| PACK-04 | Phase 161 | Complete |
| PACK-05 | Phase 161 | Complete |
| NAV-01 | Phase 161.1 | Complete |
| NAV-02 | Phase 161.1 | Complete |
| NAV-03 | Phase 161.1 | Complete |
| NAV-04 | Phase 161.1 | Complete |
| NAV-05 | Phase 161.1 | Complete |
| NAV-06 | Phase 161.1 | Complete |
| NAV-07 | Phase 161.1 | Complete |
| DEVICE-01 | Phase 162 | Complete |
| DEVICE-02 | Phase 162 | Complete |
| DEVICE-03 | Phase 162 | Complete |
| DEVICE-04 | Phase 162 | Complete |
| DEVICE-05 | Phase 162 | Complete |
| DEVICE-06 | Phase 162 | Complete |
| ALPHA-01 | Phase 163 | Complete |
| ALPHA-02 | Phase 163 | Complete |
| ALPHA-03 | Phase 163 | Complete |
| ALPHA-04 | Phase 163 | Complete |
| DEVICE-07 | Phase 162 | Complete |
| COMPOSE-01 | Phase 163.1 | Pending |
| COMPOSE-02 | Phase 163.1 | Pending |
| COMPOSE-03 | Phase 163.1 | Pending |
| COMPOSE-04 | Phase 163.1 | Pending |
| COMPOSE-05 | Phase 163.1 | Pending |
| COMPOSE-06 | Phase 163.1 | Pending |

**Coverage:** The prior 36/36 phase-local requirements remain mapped and complete. Six audit-derived
COMPOSE requirements map to Phase 163.1 as Pending; they close cross-phase composition gaps and do
not reopen or reassign the prior ledger. Stable ALPHA identifiers remain limited to the anonymous
First B2C Adopter reference-host integration slice.

---
*Requirements defined: 2026-07-30*
*Last updated: 2026-08-28 after Phase 163.1 composition-gap ledger addition*
