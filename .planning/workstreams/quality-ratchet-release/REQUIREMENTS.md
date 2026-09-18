# Requirements: Crosswake v23.0 Release Pipeline Repair & Proof-Lane Truth

**Defined:** 2026-09-15
**Workstream:** quality-ratchet-release
**Core Value:** Crosswake stays safe to change, inexpensive to verify, pleasant to review, and ready to release without weakening Phoenix-first runtime contracts or honest support claims.

**Milestone thesis:** The release pipeline already has the hard parts — an exact head/tree/base identity gate, a fail-closed rollup, a clean-room adopter harness, and a byte-exact post-publish digest proof. All three defects this milestone repairs share one root habit: *a fact that should have been derived got hardcoded, and nothing was built to catch it drifting.* Every requirement below generalizes an existing mechanism. None loosens what it proves.

**Exit criterion:** `crosswake 0.2.2` is live, published through the version-generalized graph, and `exact-public-proof` **actually executed and passed** for it. "Wired but never run" is not done.

Source: `.planning/research/v23/SUMMARY.md` (decision set, adjudicated divergences, build order).

## v23.0 Requirements

### Diagnostic Legibility

- [x] **MSG-01**: A maintainer reading a failed release check sees the failing check's own message verbatim, not a list of check IDs
- [x] **MSG-02**: A failed scanner that terminated early is reported as "terminated early" and distinguished from a check ID that was never defined
- [x] **MSG-03**: A check that fails while other required IDs are absent surfaces the failure, not the absence — `missing` never shadows `failing`
- [x] **MSG-04**: `release.publish_gate.no_bare_version_literal` fails when any publish-gating `if:` clause contains a bare version literal
- [x] **MSG-05**: `release.publish_gate.no_bare_version_literal` is proven non-vacuous against a pre-repair fixture of the workflow file — it demonstrably would have caught the original weld
- [x] **MSG-06**: The three release check display names carrying `0.2.1` are renamed to version-neutral names, and duplicate required-check names fail a uniqueness assertion

### Version / Authority Split

- [x] **WELD-01**: A completed weld inventory classifies every `0.2.1` occurrence across the 18 affected files as live gate, fixture, docstring, or display string, and is recorded in-repo
- [x] **WELD-02**: `approved-release-guard` emits an `approved_version` output bound into the same receipt that already binds approved head, tree, and base
- [x] **WELD-03**: `publish-hex`, `publish-ios-core`, `publish-android-core`, and `exact-public-proof` gate on the release version matching `approved_version`, not on a literal
- [x] **WELD-04**: `Crosswake.ReleaseCandidate.Workflow` derives `@coordinates` and `@dependencies` from the release version rather than frozen module attributes
- [x] **WELD-05**: The Elixir-side weld at `cleanroom.ex:236` is removed as the same defect class one layer down
- [x] **WELD-06**: A release of any semver version runs the full publish → proof → rollup graph with no workflow edit
- [x] **WELD-07**: The interim `release.version_weld.gates_match_declared_version` tripwire is deleted — not disabled, not weakened — in the same change that removes the literals it guarded
- [x] **WELD-08**: An unapproved merge still cannot publish at any version — the identity gate remains exact after the version gate generalizes

### Post-Publication Proof

- [x] **XPUB-01**: Each of the six packages in the approved manifest carries its own `candidate_ref`; the single-shared-ref requirement is gone
- [x] **XPUB-02**: Byte-exact digest equality against the published tarball is unchanged in strength for every package it can be established for
- [x] **XPUB-03**: A package whose source has drifted since its own publish tag reports a separately-named weaker claim, never a `byte_exact` result and never silently averaged into one green check
- [x] **XPUB-04**: `exact-public-proof` runs on a publication-record signal satisfied identically by the ordinary and the recovery publish path
- [x] **XPUB-05**: A missing publication record fails the proof hard; it is never expressed as a skipped job
- [x] **XPUB-06**: The proof result outlives its 14-day artifact retention — durably recorded in-repo or with retention raised
- [x] **XPUB-07**: The fail-closed rollup semantics are preserved verbatim — `skipped` still counts as not-success

### Clean-Room Host Realism

- [x] **ROOM-01**: The clean-room host declares a real Crosswake route with capability metadata before `doctor` runs
- [x] **ROOM-02**: The clean-room host runs `mix crosswake.install` before `doctor`, exercising what an adopter actually performs
- [ ] **ROOM-03**: `clean-room-proof-rindle` passes against the live published `crosswake_rindle 0.1.0`
- [x] **ROOM-04**: The legacy positional path's logging reaches grep-able parity with the matrix path's `step=` markers
- [ ] **ROOM-05**: The threadline and sigra clean-room failures are diagnosed as separate findings with their own recorded root causes
- [x] **ROOM-06**: `doctor`'s `manifest_contract` check is unchanged in strength — the harness was fixed, not the contract

### Adopter Proof Fidelity

- [ ] **FID-01**: SEED-014's two high-severity adopter gaps (CW-REQ-A, CW-REQ-B) are closed or explicitly deferred with a recorded reason
- [x] **FID-02**: A verification command that ran and found a defect exits differently from one that could not run at all

### Vacuous Assertion Audit

- [x] **VAC-01**: All 173 sites flagged by SEED-018 are audited and classified as genuinely vacuous or safe
- [x] **VAC-02**: Every assertion confirmed vacuous is rewritten so that an empty collection fails
- [x] **VAC-03**: Every new check added by this milestone is checked against the six-shape vacuity taxonomy before it is made merge-blocking

### Release Execution

- [ ] **REL-10**: A retire/backfill runbook covering Hex, the iOS mirror, and Maven is committed before the first publish of this milestone
- [ ] **REL-11**: All three publish legs are rehearsed to the last safe step — through `mix hex.build` not `hex.publish`, through subtree extraction not tag push
- [ ] **REL-12**: The lower-blast-radius held companion PR publishes live as the fire-drill for the repaired clean-room lane
- [ ] **REL-13**: `crosswake 0.2.2` publishes through the version-generalized graph to Hex, the iOS mirror, and Maven
- [ ] **REL-14**: `exact-public-proof` executed and passed for `0.2.2` — confirmed by run evidence, not by inspection of the workflow
- [ ] **REL-15**: The second held companion PR publishes, and the linked release rollup reports `COMPLETE`
- [ ] **REL-16**: A multi-registry partial-failure response table exists before the first publish, not derived during an incident

### Documentation Truth

- [ ] **DOC-04**: `docs/COMPANION-PUBLISH-RUNBOOK.md`'s "this pipeline only publishes 0.2.1" section is deleted the moment it becomes false — not softened
- [x] **DOC-05**: One word is used for each domain concept across CLI, CI check names, docs, and code; the "manifest" collision is resolved
- [ ] **DOC-06**: Residual `splitsh-lite` references are removed; `git subtree split` is documented as the durable mirror-split mechanism

## Future Requirements

Deferred to a later milestone. Tracked, not in this roadmap.

### Supply-Chain Surface

- **PROV-01**: Adopter-facing provenance or attestation surface, once Hex or Maven can consume attestations
- **PROV-02**: iOS mirror static deploy key replaced with a short-lived GitHub App token (SEED-003 hardening half)
- **PROV-03**: `diffoscope` side-channel for digest-mismatch triage

### Proof Quality

- **VACG-01**: `absence.collection_assertion_non_empty` as a merge-blocking guard — **only after** VAC-01/VAC-02 land. Guard-before-audit produces a wall of red that gets waived, which teaches the team that red is negotiable.

  **Sunset step (D-08), recorded here so the later deletion is a documented step and not a cold
  judgment call):** when VACG-01 lands, lift `script/inventory_collection_assertions.exs`'s
  detection core into the new guard rather than rewriting it from scratch, then **delete**:

  - `script/inventory_collection_assertions.exs`
  - `script/collection_assertion_ledger.json`
  - `script/collection_assertion_remediation.json`
  - `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`

  Reason: two mechanisms that can silently disagree about what counts as safe are worse than one.
  A regenerable inventory and a merge-blocking guard checking the same shapes by two independently
  maintained implementations would eventually drift apart, and neither the ledger test nor the
  guard would be able to tell you which one is right.

- **VACG-02**: `verify_repository.sh` must surface the failing stage's own child output, not just
  `FAIL <stage-id>; corrective-command=...`. Observed 2026-09-17 on PR #176: the
  `example-host-proof` stage failed in CI and the entire job log contained exactly one line about
  it — no test output, no assertion, no exit detail — so the only way to learn what broke was to
  reproduce the stage locally. This is the same shape as the defects VAC-01..03 target, one layer
  up: a red signal that carries no information about the thing it names. Fix belongs wherever the
  stage runner captures child stdio (`script/verify_repository.mjs`), and must apply to every
  stage, not just this one.

### Consolidation

- **CONS-01**: Delete the legacy positional clean-room path once the backport has proven stable across a release cycle

## Out of Scope

Explicitly excluded, with reasoning, to prevent re-adding.

| Feature | Reason |
|---------|--------|
| GitHub OIDC / trusted publishing | Neither Hex.pm nor Maven Central Portal exposes a trusted-publisher flow to federate to |
| `actions/attest-build-provenance`, cosign, SLSA | Real future value, but no registry in play consumes attestations today; would refactor a working system off the critical path |
| GitHub Environments as a replacement for `approved-release-guard` | Answers "did a human click" — not "is this the exact approved head/tree/receipt". A regression, not a generalization |
| Hex package signing | Does not exist on Hex.pm |
| npm-provenance-style adopter badges | No Hex.pm rendering surface — write-only |
| Force-linking the six packages into one candidate ref | Re-creates the lockstep bottleneck that companion extraction (v16.0/v17.0) deliberately tore apart; contradicts D-15/D-16 |
| Relaxing byte-exact digest equality to a reachability check | Byte-exactness is the entire value of exact-public; loosening it makes the proof decorative |
| Narrowing `doctor`'s `manifest_contract` | Weakening a contract to make a harness pass — the named anti-pattern in TODO-009 and TODO-011 |
| Marking the clean-room lane advisory or non-blocking | A proof that has never passed is a finding, not noise |
| Wholesale rename of all ~22 required CI check names | Real branch-protection and queue-deadlock cost (SEED-007's PR #84 incident: 78 runs, 3 hours, for an unrelated docs PR) |
| Merge queue adoption (SEED-007) | Severable; a distinct decision about proof culture, not a release-pipeline defect |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MSG-01 | Phase 169 | Complete |
| MSG-02 | Phase 169 | Complete |
| MSG-03 | Phase 169 | Complete |
| MSG-04 | Phase 171 | Complete |
| MSG-05 | Phase 171 | Complete |
| MSG-06 | Phase 169 | Complete |
| WELD-01 | Phase 171 | Complete |
| WELD-02 | Phase 171 | Complete |
| WELD-03 | Phase 171 | Complete |
| WELD-04 | Phase 171 | Complete |
| WELD-05 | Phase 171 | Complete |
| WELD-06 | Phase 171 | Complete |
| WELD-07 | Phase 171 | Complete |
| WELD-08 | Phase 171 | Complete |
| XPUB-01 | Phase 172 | Complete |
| XPUB-02 | Phase 172 | Complete |
| XPUB-03 | Phase 172 | Complete |
| XPUB-04 | Phase 173 | Complete |
| XPUB-05 | Phase 173 | Met — fire-drill run 35302554800 (2026-09-18): the proof job is present and concludes `failure` at `PUBLICATION_RECORD_MISSING` (exit 4), while five sibling jobs in the same run read `skipped`, so the value is not a constant. Evidence in `173-NON-VACUITY.md`. |
| XPUB-06 | Phase 173 | Complete |
| XPUB-07 | Phase 173 | Complete |
| ROOM-01 | Phase 174 | Complete |
| ROOM-02 | Phase 174 | Complete |
| ROOM-03 | Phase 174 | Pending |
| ROOM-04 | Phase 174 | Complete |
| ROOM-05 | Phase 174 | Pending |
| ROOM-06 | Phase 174 | Complete |
| FID-01 | Phase 174 | Pending |
| FID-02 | Phase 169 | Complete |
| VAC-01 | Phase 170 | Complete |
| VAC-02 | Phase 170 | Complete |
| VAC-03 | Phase 170 | Complete |
| REL-10 | Phase 175 | Pending |
| REL-11 | Phase 175 | Pending |
| REL-12 | Phase 175 | Pending |
| REL-13 | Phase 175 | Pending |
| REL-14 | Phase 175 | Pending |
| REL-15 | Phase 175 | Pending |
| REL-16 | Phase 175 | Pending |
| DOC-04 | Phase 175 | Pending |
| DOC-05 | Phase 171 | Complete |
| DOC-06 | Phase 175 | Pending |

**Coverage:**

- v23.0 requirements: 42 total
- Mapped to phases: 42
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-15*
*Last updated: 2026-09-15 after v23.0 roadmap revision (Phases 169-175, VAC-01/02/03 split into its own Phase 170, 100% coverage)*
