# Requirements: Crosswake v18.0 Release Integrity & Automated Package Operations

**Defined:** 2026-07-07
**Core Value:** Replace host-owned generated shell code (`ActivationCoordinator`, `BridgeChannel`) with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

## v1 Requirements

### Release Graph Integrity

- [x] **RELG-01**: Maintainers can prove the release workflow uses path-specific gates so companion-only releases cannot publish the core Hex package or native artifacts.
- [x] **RELG-02**: Maintainers can prove release publish/proof jobs are not canceled mid-run by newer release workflow events.
- [x] **RELG-03**: Maintainers can detect stale `release-as` pins only after the relevant companion publish job succeeds.

### Automated Publishing

- [x] **AUTO-01**: The happy-path release train publishes package artifacts from Release Please outputs without maintainer-run `mix hex.publish` commands.
- [x] **AUTO-02**: Core/native artifacts remain lockstep while `crosswake_*` companions remain independently versioned.
- [x] **AUTO-03**: Recovery paths stay exact-ref and idempotent so already-live versions are reported rather than re-published.

### Preflight And Clean-Room Proof

- [x] **PREF-01**: Companion clean-room proof installs the exact just-published companion version and derives the required `crosswake` floor from the package under test.
- [x] **PREF-02**: `mix crosswake.doctor --router` can load a router from a freshly compiled clean-room host before failing with "router unavailable."
- [ ] **PREF-03**: Release integrity has a merge-blocking static test that fails on aggregate gates, stale dependency floors, proof cascades, or missing mirror-token preflight.

### Native Registry Parity

- [ ] **MIRR-01**: The iOS mirror job fails fast when `MIRROR_PUSH_TOKEN` is absent or unusable.
- [ ] **MIRR-02**: iOS and Android clean-room proofs no longer depend on each other when only one native registry path fails.
- [ ] **MIRR-03**: Maintainers have an explicit path to verify or backfill the missing iOS `v0.2.0` mirror tag.

### Release Status DX

- [ ] **STAT-01**: Maintainers can run one local command to inspect core/native lockstep, companion versions, compatibility floors, release-as pins, and release workflow guard status.
- [ ] **STAT-02**: The release status command has JSON output suitable for CI or issue-opening automation.
- [ ] **STAT-03**: Release status can optionally probe live public registries without making live network checks mandatory for normal CI.

## v2 Requirements

### Deferred Product Breadth

- **DASH-01**: Ship `crosswake_dashboard` as a Phoenix-native operator package once release surfaces are trustworthy.
- **SYNCP-01**: Productize offline-sync beyond the current honest proof lane.
- **NTV-01**: Add deeper native disk-budget support.
- **SEED-002**: Resume Phoenix-first native capability and commerce breadth after release infrastructure is reliable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New runtime capabilities or companions | v18 is release-ops coherence, not product breadth. |
| A web dashboard UI | The release operator surface is text/JSON first; dashboard work remains DASH-01. |
| Self-mutating branch protection or secret provisioning | Admin controls should be detected and reported, not applied automatically by CI. |
| Lockstep companion releases | Companions remain independently versioned; only core/native artifacts stay lockstep. |
| App Store/TestFlight/Play internal-track automation | v18 focuses library/package registries, not app distribution tracks. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RELG-01 | Phase 142 | Complete |
| RELG-02 | Phase 142 | Complete |
| RELG-03 | Phase 142 | Complete |
| AUTO-01 | Phase 143 | Complete |
| AUTO-02 | Phase 143 | Complete |
| AUTO-03 | Phase 143 | Complete |
| PREF-01 | Phase 144 | Complete |
| PREF-02 | Phase 144 | Complete |
| PREF-03 | Phase 144 | Pending |
| MIRR-01 | Phase 145 | Pending |
| MIRR-02 | Phase 145 | Pending |
| MIRR-03 | Phase 145 | Pending |
| STAT-01 | Phase 146 | Pending |
| STAT-02 | Phase 146 | Pending |
| STAT-03 | Phase 146 | Pending |

**Coverage:**

- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-07-07*
*Last updated: 2026-07-07 after v18.0 milestone initialization*
