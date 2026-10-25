# Requirements: v24.0 Repository Cleanup & Maintenance

**Defined:** 2026-10-11
**Workstream:** quality-ratchet-release
**Core value:** one real Phoenix application on one physical iPhone with explicit route ownership and one honest offline mutation island.
**Scope approved:** MAINT-01 through MAINT-08; SEED-012 included; ecosystem research skipped. See [approved scope](v24.0-SCOPE.md).

## v24.0 Requirements

### Local work and artifact ownership

- [x] **MAINT-01:** Maintainer can inspect an inventory of every local change against merged code, with the compared source commits named.
- [x] **MAINT-02:** Maintainer can see a disposition for each inventoried change and recover unique work before any removal.
- [x] **MAINT-04:** Maintainer can distinguish tracked contracts, ignored transient files and forbidden residue using the existing repository artifact policy.

### Maintenance and queue reconciliation

- [x] **MAINT-03:** Maintainer can use supported release entry points after obsolete release code is removed only where its replacement and callers have been verified.
- [x] **MAINT-05:** Maintainer can see a concrete next action for every open PR and issue in a dated inventory; maintenance triage does not authorize release publication.
- [x] **MAINT-06:** Maintainer can follow corrected maintenance instructions without stale paths or commands, while historical failure records retain their original verdicts.

### Final source verification

- [x] **MAINT-07:** Maintainer can run the existing repository verification command from an exact clean checkout and inspect its results and before/after Git status.
- [x] **MAINT-08:** Maintainer can inspect green CI bound to the final source commit; results from an older or different commit do not satisfy this requirement.

## Future Requirements

No additional capability or package release is selected. Demonstrated defects outside this bounded maintenance scope require a separate decision. The parked adopter workstream retains its existing external gate.

## Out of Scope

| Work | Reason |
|---|---|
| New package release or merging release proposals | Maintenance scope does not select irreversible publication |
| Replaying Phase 175 attempts or repairing REL-10 retrospectively | v23 history is immutable and archived with exceptions |
| Blanket deletion, git clean, or discarding unique local work | Every change requires a disposition and preservation first |
| Style-only refactors or broad phase-ID renaming | Cleanup requires demonstrated obsolescence or a misleading instruction |
| Replacement verification system or new standing reconciliation CI lane | Reuse existing commands, artifact policy and CI authority |
| Adopter promotion, Android breadth, new native controls or companions, generic sync/storage, dashboard | Governing ADR and parked-workstream boundaries remain in force |

## Traceability

Roadmap approved 2026-10-11. Phases 176 and 177 are complete; Phase 178 has five completed plans, final local 9/9 and hosted 48 required checks on the exact same governed merge commit. MAINT-07/08 passed independent verification at 18/18 must-haves and 25/25 decisions. All eight requirements are complete. The milestone audit cross-checked all three sources and found no blockers; six retained debt items remain for scoped closeout review.

| Requirement | Phase | Status |
|---|---|---|
| MAINT-01 | Phase 176 | Complete |
| MAINT-02 | Phase 176 | Complete |
| MAINT-04 | Phase 176 | Complete |
| MAINT-03 | Phase 177 | Complete |
| MAINT-05 | Phase 177 | Complete |
| MAINT-06 | Phase 177 | Complete |
| MAINT-07 | Phase 178 | Complete |
| MAINT-08 | Phase 178 | Complete |

**Coverage:** 8 requirements; 8 mapped; 0 unmapped; each mapped exactly once.

*Last updated: 2026-10-12 after scoped v24.0 milestone audit; see [audit](v24.0-MILESTONE-AUDIT.md) and [current 24-item queue](v24.0-audit/queue-inventory.json). Final proof was warm-cache; two earlier failures retain unknown causes because assertion text was not captured. PR #238 remains open and unmerged.*
