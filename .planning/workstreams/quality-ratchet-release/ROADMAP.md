# Roadmap: v22.0 Quality Ratchet & Release Readiness

## Overview

v22.0 tightens Crosswake's internal quality and release path without reopening product or mobile
breadth. The work first establishes trustworthy dependency-security and merge-gate authority, then
reduces CI cost without hiding proof, ratchets clean-checkout repository quality, reconciles public
and pull-request truth, and finishes with a fully verified 0.2.1 release candidate. The parked
First B2C Adopter lane remains independently resumable in its own workstream and is not a dependency
of this roadmap.

## Phases

**Phase Numbering:** Sequential phase IDs continue after parked Phase 163.1. Phase 164 begins this
independent workstream; the numbering does not imply that parked adopter work must resume first.

- [x] **Phase 164: Dependency Security and Gate Authority** - Establish patched dependencies and one fail-closed authoritative path for every required result. (completed 2026-08-28)
- [ ] **Phase 165: Efficient and Maintainable CI** - Reduce runner cost and duplicate work while preserving visible, named proof.
- [ ] **Phase 166: Clean-Checkout Engineering Quality** - Make the supported repository verification surfaces deterministic, focused, and clean.
- [ ] **Phase 167: Documentation and Pull-Request Reconciliation** - Align public truth, preserve the parked lane, and resolve ambiguous open PR state.
- [ ] **Phase 168: 0.2.1 Release Candidate Readiness** - Prove package-family consistency and prepare an exact, approval-gated release candidate.

## Phase Details

### Phase 164: Dependency Security and Gate Authority

**Goal**: Maintainers can trust that patched dependencies and every required merge result fail closed through one authoritative path.
**Depends on**: Nothing in this workstream (Phase 163.1 remains parked independently)
**Requirements**: SEC-01, SEC-02, SEC-03, CIG-01, CIG-02, CIG-03, CIG-04
**Success Criteria** (what must be TRUE):

  1. A maintainer can audit the root project and example host and receive zero known security advisories while Phoenix, Phoenix LiveView, Plug, and both lockfiles remain inside declared public compatibility ranges.
  2. A pull request exposes one stable, actionable dependency-security result, and introducing a known advisory makes that result fail closed.
  3. Every merge-blocking check context has one authoritative producer, and every intended ExUnit test file—including example-host-tagged tests—is exercised by at least one required path.
  4. State-mutating tests pass both alone and in the complete suite without leaving changed application configuration, code paths, files, or databases behind.
  5. Required aggregators visibly distinguish irrelevant work from failed, cancelled, or missing work, and only the explicitly irrelevant case is neutral.

**Plans**: 5 plans

- [x] 164-05-PLAN.md

- [x] 164-01-PLAN.md
- [x] 164-02-PLAN.md
- [x] 164-03-PLAN.md
- [x] 164-04-PLAN.md

### Phase 165: Efficient and Maintainable CI

**Goal**: Maintainers receive faster, cheaper CI feedback without losing named proof or authoritative results.
**Depends on**: Phase 164
**Requirements**: CIP-01, CIP-02, CIP-03, CIP-04, CIP-05, CIP-06, CIP-07
**Success Criteria** (what must be TRUE):

  1. Pure Elixir and Android/JVM proof runs on Linux, while macOS is used only by jobs that invoke Apple tooling.
  2. Pull-request updates do not repeat equivalent push work, obsolete cycles cancel within bounded timeouts, and a newer authoritative run cannot be cancelled by an older one.
  3. Dependency and build caches restore only when the relevant lockfiles and complete language/JDK/Gradle toolchain identities match.
  4. A documentation-only pull request receives an always-visible merge result without scheduling unrelated build, browser, Android, or Apple proof.
  5. A maintainer can compare reproducible before/after workflow count, runner selection, queue time, and execution time, and can still identify each named proof behind the consolidated reusable orchestration.

**Plans**: 11/13 plans executed

Plans:
**Wave 1**

- [x] 165-01-PLAN.md — Capture the pre-change baseline and prove the documentation-only tracer.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 165-02-PLAN.md — Harden classification, manifest, and closed umbrella policy.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 165-03-PLAN.md — Build trusted monotonic obsolete-run cancellation.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 165-04-PLAN.md — Correct runner placement, cache identity, and timeouts.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 165-05-PLAN.md — Consolidate core, security, hermetic, and commerce PR proof.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 165-06-PLAN.md — Consolidate the first domain-proof cohort.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 165-07-PLAN.md — Consolidate the remaining phase-era domain proof.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 165-08-PLAN.md — Consolidate native, browser, package, and cross-runtime proof.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 165-09-PLAN.md — Finish the PR graph and recurring Phase 165 contract gate.

**Wave 10** *(blocked on Wave 9 completion)*

- [x] 165-10-PLAN.md — Prove live behavior and add Crosswake CI authority green-first.

**Wave 11** *(blocked on Wave 10 completion)*

- [x] 165-11-PLAN.md — Approve or reject the exact legacy-context retirement.

**Wave 12** *(blocked on Wave 11 completion)*

- [ ] 165-12-PLAN.md — Apply approved retirement and remove migration-only compatibility conclusions.

**Wave 13** *(blocked on Wave 12 completion)*

- [ ] 165-13-PLAN.md — Bind the landed final graph to an exact remote SHA and capture matched after evidence.

### Phase 166: Clean-Checkout Engineering Quality

**Goal**: Maintainers can verify the whole supported repository from a clean checkout and receive concise failures without residue or misleading code paths.
**Depends on**: Phase 165
**Requirements**: ENG-01, ENG-02, ENG-03, ENG-04
**Success Criteria** (what must be TRUE):

  1. From a clean checkout, the root suite, example host, browser proof, iOS package, Android package, formatter, and warnings-as-errors checks complete deterministically.
  2. A maintainer reviewing milestone-touched code can identify explicit ownership boundaries and focused modules, with no known dead branch, accidental duplication, or misleading compatibility fallback remaining.
  3. Generated, temporary, secret-bearing, editor, and local-only artifacts are either intentionally tracked or excluded, and a complete clean verification run leaves Git clean.
  4. Repository quality failures name a current, actionable correction without stale phase labels, contradictory comments, or unactionable warning noise.

**Plans**: TBD

### Phase 167: Documentation and Pull-Request Reconciliation

**Goal**: Maintainers see one current account of supported behavior and can understand the disposition of every open change without disturbing parked adopter work.
**Depends on**: Phase 166
**Requirements**: DOC-01, DOC-02, DOC-03
**Success Criteria** (what must be TRUE):

  1. Public guides, support and capability truth, architecture notes, contribution guidance, and release runbooks agree with verified behavior and current package versions.
  2. A maintainer can resume the First B2C Adopter workstream from its parked state without reconstruction; its durable content remains codename-only and its status names only the real external route/device authority.
  3. Every open pull request has an unambiguous current disposition: merged, rebased, superseded, closed, or explicitly deferred with a current reason.

**Plans**: TBD

### Phase 168: 0.2.1 Release Candidate Readiness

**Goal**: Maintainers can approve an exact Crosswake 0.2.1 candidate knowing every reversible package-family and release check has passed.
**Depends on**: Phase 167
**Requirements**: REL-01, REL-02, REL-03, REL-04, REL-05
**Success Criteria** (what must be TRUE):

  1. A throwaway host resolves, compiles, registers, and doctors every supported published companion without a false harness failure.
  2. iOS mirror operations use explicit cross-repository authority, fail loudly when it is absent or insufficient, and expose an automated idempotent 0.2.0 backfill command whose immutable tag write still requires explicit maintainer approval.
  3. Core, companion, Android, and iOS coordinates and compatibility floors agree, and deliberate drift is rejected by automated checks.
  4. The exact Crosswake 0.2.1 candidate commit passes package audit, build, tests, documentation generation, clean-room installation, and release-status verification.
  5. Every reversible release preparation step is automated, and the remaining irreversible package or tag publication is presented as one explicit maintainer approval rather than performed implicitly.

**Plans**: TBD

## Progress

**Execution Order:** Phase 164 → Phase 165 → Phase 166 → Phase 167 → Phase 168

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 164. Dependency Security and Gate Authority | 5/5 | Complete    | 2026-08-28 |
| 165. Efficient and Maintainable CI | 11/13 | In Progress|  |
| 166. Clean-Checkout Engineering Quality | 0/TBD | Not started | - |
| 167. Documentation and Pull-Request Reconciliation | 0/TBD | Not started | - |
| 168. 0.2.1 Release Candidate Readiness | 0/TBD | Not started | - |

---
*Roadmap created: 2026-08-28 for workstream `quality-ratchet-release`*
