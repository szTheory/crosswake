# Roadmap: Quality Ratchet & Release Readiness

## Milestones

- ✅ **v22.0 Quality Ratchet & Release Readiness** — Phases 164-168 (shipped 2026-09-16)
- 🚧 **v23.0 Release Pipeline Repair & Proof-Lane Truth** — Phases 169-175 (planning)

## Phases

<details>
<summary>✅ v22.0 Quality Ratchet & Release Readiness (Phases 164-168) — SHIPPED 2026-09-16</summary>

- [x] Phase 164: Dependency Security and Gate Authority (5/5 plans) — completed 2026-08-28
- [x] Phase 165: Efficient and Maintainable CI (13/13 plans) — completed 2026-09-09
- [x] Phase 166: Clean-Checkout Engineering Quality (8/8 plans) — completed 2026-09-10
- [x] Phase 167: Documentation and Pull-Request Reconciliation (9/9 plans) — completed 2026-09-12
- [x] Phase 168: 0.2.1 Release Candidate Readiness (13/13 plans) — completed 2026-09-16, 1 item deferred

Full detail: [`milestones/v22.0-ROADMAP.md`](milestones/v22.0-ROADMAP.md)

**Closeout type:** `override_closeout`. Phases 167 and 168 carried `stale` verification at close
(covered files changed after their verification ran), and 9 seeds were deliberately left
unacknowledged. See `MILESTONES.md` for the recorded overrides.

</details>

### v23.0 Release Pipeline Repair & Proof-Lane Truth (planning)

- [x] **Phase 169: Diagnostic Legibility** - Every release/verification check surfaces its own failing message, and distinguishes "never ran" from "never defined" (completed 2026-09-16)
- [ ] **Phase 170: Vacuous Assertion Remediation** - All 173 SEED-018-flagged sites are classified and every confirmed-vacuous one is rewritten so an empty collection fails
- [ ] **Phase 171: Version/Authority Split** - The release graph is version-parametric while the approval identity gate stays exact; the `0.2.1` weld and its interim tripwire are both retired atomically
- [ ] **Phase 172: Per-Package Proof Scope** - Byte-exact publish verification is proven against each package's own approved ref, never one shared ref for all six
- [ ] **Phase 173: Recovery-Path Proof Convergence** - `exact-public-proof` runs and must pass identically whether a publish happened via the ordinary or the recovery path
- [ ] **Phase 174: Clean-Room Host Realism & Adopter Fidelity** - The clean-room lane exercises install, not just compile, on both code paths, and the two named adopter gaps are closed or deferred with a reason
- [ ] **Phase 175: Rehearsal and Publish** - `crosswake 0.2.2` and the two held companion PRs are live through the repaired graph, and `exact-public-proof` has actually executed and passed for 0.2.2

## Phase Details

### Phase 169: Diagnostic Legibility

**Goal**: A maintainer reading any release or verification check failure sees that check's own
message, and the system never reports "missing" when the true state is "failing" or "never ran."

**Depends on**: Nothing (first phase; pure diagnostics refactor, no release-graph behavior change)

**Requirements**: MSG-01, MSG-02, MSG-03, MSG-06, FID-02

**Success Criteria** (what must be TRUE):

1. A deliberately failing release check (e.g. a fixture reproducing the PR #164 defect) surfaces
   its own verbatim `detail` message in `Crosswake.ReleaseStatus`'s output — not a generic "missing
   check IDs" list — confirmed by a test asserting the exact string appears.
2. A scanner run that terminates early is reported distinctly from a check ID that was never
   defined, with a message naming how many checks after the last observed failure never ran —
   confirmed by a test exercising both cases and asserting different, correctly-labeled output.
3. The three release check display names carrying `0.2.1` are renamed to version-neutral names, and
   a uniqueness assertion over required-check names fails when two names collide — confirmed by a
   test that introduces a duplicate and watches the assertion fail.
4. A verification command exercised twice — once finding a real defect, once unable to run at all —
   exits with two different, documented statuses, confirmed by running both cases and diffing the
   exit codes.

**Plans**: 4/4 plans executed

Plans:
**Wave 1**

- [x] 169-01-PLAN.md — Tracer: a failing scanner check's own sentence reaches the maintainer verbatim; `failing` no longer shadowed by `missing` (MSG-01, MSG-03)
- [x] 169-03-PLAN.md — Version-neutral display names and a global duplicate-name scan, landed atomically (MSG-06)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 169-02-PLAN.md — `:unverifiable` / exit 3: could-not-verify is a distinct, documented outcome (FID-02, MSG-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 169-04-PLAN.md — Exit-contract drift guard and canonical-doc link (FID-02)

**Wave structure**: Wave 1 = 169-01 and 169-03 in parallel (no shared files) · Wave 2 = 169-02 ·
Wave 3 = 169-04.

**Research**: Standard pattern — pure Elixir refactor of an existing function plus a new pure-syntax
scanner check; the coverage-test shape already exists in the repo to copy. Skip phase-level research.

---

### Phase 170: Vacuous Assertion Remediation

**Goal**: Every site SEED-018 flagged as a candidate "absence scored as success" defect is actually
classified, and every one confirmed vacuous is rewritten to fail on an empty collection — without
introducing a merge-blocking guard ahead of that audit.

**Depends on**: Nothing. Independent of every other phase in this milestone — startable in parallel
from the beginning, alongside Phase 174 (Clean-Room Host Realism). Must complete before Phase 175
(Rehearsal and Publish) opens, since Phase 175 is where an unaudited vacuous check could silently
pass a one-way-door step.

**Requirements**: VAC-01, VAC-02, VAC-03

**Success Criteria** (what must be TRUE):

1. Each of the 173 SEED-018-flagged sites has a recorded classification (genuinely vacuous vs.
   safe) committed in-repo (e.g. a table or ledger keyed by file:line), confirmed by counting rows
   against the 173 total.
2. Every site confirmed vacuous is rewritten so a test with an empty collection input now fails
   where it previously passed — confirmed by a regression test per rewritten site (or a shared
   fixture harness covering the set) demonstrating the "empty now fails" property.
3. `absence.collection_assertion_non_empty` (VACG-01) is **not** added as a merge-blocking guard in
   this milestone — confirmed by its absence from any required-check registration — because landing
   the guard before the audit produces a wall of red that gets waived, teaching the team red is
   negotiable. It remains tracked under Future Requirements for a later milestone.
4. Every new check landed by *any* phase of this milestone (169, 171, 172, 173, 174, 175) has been
   checked against the six-shape vacuity taxonomy (bare `Enum.all?`/`any?` on a possibly-empty
   collection; a job `needs:` something that silently skipped; `continue-on-error` on a lane feeding
   a one-way door; `if:` conditions that silently never match; a matrix expanding to zero entries;
   missing `set -e`/misused `grep -q`/`jq -e`) before being made merge-blocking — confirmed as a
   review checklist item applied at the close of each of those phases, not a code change owned by
   this phase itself.

**Plans**: 5 plans
**Wave 1**

- [ ] 170-01-PLAN.md — Inventory script, committed classification ledger, and its non-vacuity proof (VAC-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 170-02-PLAN.md — Frozen remediation manifest, guard insertions, and the itemized structural proof (VAC-02)
- [ ] 170-04-PLAN.md — `vacuity_taxonomy` phase-close convention and the Phase 169 retroactive addendum (VAC-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 170-03-PLAN.md — Empty-input regression proofs at the high-blast-radius sites (VAC-02)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 170-05-PLAN.md — Phase 170's own taxonomy record and the decidable convention check (VAC-03)

**Research**: Standard pattern — an audit-and-classify pass plus mechanical test rewrites at
already-identified sites. Skip phase-level research.

---

### Phase 171: Version/Authority Split

**Goal**: Any semver version can run the full publish → proof → rollup graph with no workflow edit,
while an unapproved merge still cannot publish at any version — and the check that would have
caught the original `0.2.1` weld lands in the same change that removes it.

**Depends on**: Phase 169 (reads its own CI failures through the new diagnostic seam while under
development, though not a hard technical dependency)

**Requirements**: MSG-04, MSG-05, WELD-01, WELD-02, WELD-03, WELD-04, WELD-05, WELD-06, WELD-07,
WELD-08, DOC-05

**Note on atomicity**: `release.publish_gate.no_bare_version_literal` (MSG-04/MSG-05) and the D1
version/authority fix (WELD-01..08) are **one phase, landed together in the same PR** — not two
plans that could merge independently. If the check merged before the fix, it would correctly and
permanently fail against `main` (the four bare-literal gates still exist) — blocking every other PR
until this phase finishes. If the fix merged before the check, there would be no proof the
generalization is safe. Both risks are the same failure mode SUMMARY.md warns against: "either
`main` goes permanently red or the check is meaninglessly advisory for that window." This phase's
plan sequencing must land the check and the fix in one commit/PR, with the check's own non-vacuity
proof (run against a pre-fix fixture of the workflow file) as part of that same change.

**Success Criteria** (what must be TRUE):

1. `release.publish_gate.no_bare_version_literal` runs against a pre-repair fixture of the workflow
   file and fails, proving it is non-vacuous — confirmed by a test that pins the fixture and asserts
   the failure.
2. `approved-release-guard`'s receipt output carries an `approved_version` field bound alongside the
   existing head/tree/base — confirmed by inspecting a real or rehearsed guard run's output.
3. Grepping `release-please.yml` for a bare `0.2.1` (or any other literal version) inside any
   publish-gating `if:` clause across `publish-hex`, `publish-ios-core`, `publish-android-core`, and
   `exact-public-proof` returns zero matches; each instead compares against `approved_version`.
4. `Crosswake.ReleaseCandidate.Workflow`'s coordinate/dependency derivation is a function of an input
   version, not a frozen module attribute — confirmed by a test calling it with two different
   versions and observing two different results.
5. `cleanroom.ex:236`'s `== "0.2.1"` comparison no longer exists in the source (confirmed by grep),
   and the weld inventory table (all 18 originally-flagged files) is committed in-repo with every row
   classified as live gate / fixture / docstring / display string, with zero remaining "live gate"
   rows referencing a bare version literal.
6. The `release.version_weld.gates_match_declared_version` tripwire file is deleted from the repo
   (not disabled, not weakened) in the same commit that lands the successor check as merge-blocking.
7. A rehearsed unapproved-merge attempt still cannot publish at any version — confirmed by a test
   asserting the identity gate (head/tree/base match) remains exact after the version comparison
   generalizes.

**Plans**: TBD

**Research**: Standard pattern — the receipt-output idiom (`approved-release-guard.outputs.*`) is
already established for head/tree/base; extending it one field is mechanical. Skip phase-level
research.

---

### Phase 172: Per-Package Proof Scope

**Goal**: Byte-exact publish verification is proven against each of the six packages' own approved
ref, never collapsed onto a single shared ref, and a package whose source has drifted past every
usable ref reports an honestly-labeled weaker claim instead of a false pass or silent failure.

**Depends on**: Phase 171 (consumes `approved_version` and the removed `cleanroom.ex:236` weld —
same module, same test fixtures)

**Requirements**: XPUB-01, XPUB-02, XPUB-03

**Success Criteria** (what must be TRUE):

1. The approved-artifacts manifest schema accepts six independent `candidate_ref` values — confirmed
   by a test asserting the schema no longer enforces `unique | length == 1` across packages.
2. `validate_approved_artifacts!/1` (or its successor) resolves and validates each package against
   its own ref, confirmed by a fixture where two packages carry different refs and both validate
   independently in one run.
3. Byte-exact digest equality is unchanged in strength for every package it can be established for —
   confirmed by a regression test that a non-drifted package still requires byte-for-byte tarball
   match.
4. A package whose source has drifted past every candidate ref reports `reachable_and_compatible` (or
   `unproven`) — never `byte_exact`, and never silently averaged into one green result — confirmed by
   a fixture that forces drift and inspects the reported result type.

**Plans**: TBD

**Research**: Standard pattern — schema loosening (removing a `unique | length == 1` collapse) with
an established per-entry field already present in the manifest shape. Skip phase-level research.

---

### Phase 173: Recovery-Path Proof Convergence

**Goal**: `exact-public-proof` runs, and must pass, for a publish that happened through the ordinary
release-please path or through the recovery/dispatch path — identically, with no silent-skip case.

**Depends on**: Phase 171 (`approved_version` gate). Touches a disjoint file set from Phase 172
(`needs:` graph and publish scripts vs. `cleanroom.ex`/manifest schema) — the two may be planned and
executed in parallel once Phase 171 is merged.

**Requirements**: XPUB-04, XPUB-05, XPUB-06, XPUB-07

**Success Criteria** (what must be TRUE):

1. `exact-public-proof`'s `needs:` is satisfied by a publication-record signal for the exact
   `{package, version, approved_head}` triple, demonstrated identically from a fixture representing
   the ordinary graph and one representing `workflow_dispatch` recovery.
2. A missing publication record causes `exact-public-proof` to fail with a named "record missing"
   result — confirmed by a run where the record is absent and the job's result is `failed`, not
   `skipped`.
3. The rollup's fail-closed semantics are unchanged: an existing or new test asserting `skipped`
   still counts as not-success passes against the modified graph.
4. The proof's evidence outlives the default 14-day artifact retention — either `retention-days` is
   raised in the workflow file, or a durable release-ledger entry recording pass/fail is committed to
   the repo for at least one real run, confirmed by inspecting the committed record after the
   retention window would otherwise have expired.

**Plans**: TBD

**Research**: Needs phase-level research (`/gsd-plan-phase --research-phase 173`) — confirm GitHub
Actions' current `workflow_call`/`workflow_dispatch` composition rules before writing YAML for the
recovery convergence, and confirm the current org-level `retention-days` cap (flagged UNVERIFIED —
"up to 400 days, org policy permitting" — by research).

---

### Phase 174: Clean-Room Host Realism & Adopter Fidelity

**Goal**: The clean-room proof lane exercises what an adopter actually does — declare a route, run
`mix crosswake.install`, then `doctor` — on both the legacy and matrix code paths, without weakening
`doctor`'s own contract, and the two named high-severity adopter gaps are closed or explicitly
deferred.

**Depends on**: Independent of Phases 171-173 (touches only the legacy path's host-generation steps
in `verify_companion_cleanroom.sh`). May be planned and executed starting as early as Phase 169,
since diagnosing whether threadline/sigra's failures persist is calendar-bound — each only
reproduces against a live Hex release.

**Requirements**: ROOM-01, ROOM-02, ROOM-03, ROOM-04, ROOM-05, ROOM-06, FID-01

**Success Criteria** (what must be TRUE):

1. The legacy positional clean-room path's generated host declares a real Crosswake route with
   capability metadata before `doctor` runs — confirmed by inspecting the host generated during an
   actual run.
2. The legacy path runs `mix crosswake.install` before `doctor` — confirmed by the run log showing
   the install step executed, not merely present in the script.
3. `clean-room-proof-rindle` executes against the live published `crosswake_rindle 0.1.0` and passes
   — confirmed by a green CI run, not by code inspection.
4. The legacy path's log output carries `step=`-style markers grep-able at the same granularity as
   the matrix path — confirmed by grepping a captured run's log for both paths and finding parity.
5. Threadline and sigra clean-room runs each have their own separately recorded root-cause finding
   (not assumed fixed by the backport, not lumped together) — confirmed by two distinct written
   findings, whether the runs are still red or have gone green.
6. `doctor`'s `manifest_contract` check source is byte-identical before and after this phase
   (confirmed by diffing against git history) — the harness was fixed, not the contract.
7. SEED-014's CW-REQ-A and CW-REQ-B are each either closed, with a passing check demonstrating the
   close, or carry an explicit recorded deferral reason in-repo.

**Plans**: TBD

**Research**: Standard pattern — pure backport of an already-working, already-tested function
(`matrix_write_host`) into a sibling code path in the same file. Skip phase-level research.

---

### Phase 175: Rehearsal and Publish

**Goal**: `crosswake 0.2.2` and the two held companion PRs (#147, #115) are live on Hex, the iOS
mirror, and Maven through the fully repaired, version-generalized graph, and the post-publication
proof has actually executed and passed for 0.2.2 — confirmed by run evidence, not by inspection of
the workflow.

**Depends on**: Phases 169, 170, 171, 172, 173, and 174 all complete and green. This phase must
never be combined with any of them in the same plan — "the graph is fixed" and "we shipped 0.2.2"
are deliberately forced into separate checkpoints.

**Requirements**: REL-10, REL-11, REL-12, REL-13, REL-14, REL-15, REL-16, DOC-04, DOC-06

**One-way-door note**: This phase contains the milestone's only irreversible operations — Hex
publish, iOS mirror tag push, and Maven upload (project decision D-19). Per the locked decision, the
retire/backfill runbook (REL-10) covering all three registries **must be committed to the repo
before any publish step in this phase executes.** Nothing in this phase should be merged or run
without that runbook already committed. Publishes proceed in ascending blast-radius order: the
lower-blast-radius held companion first, as the fire-drill for the repaired clean-room lane; core
0.2.2 next; the second held companion last.

**Success Criteria** (what must be TRUE):

1. A retire/backfill runbook covering Hex (`mix hex.retire`), the iOS mirror (re-tag/note), and
   Maven (retire-forward) is committed to the repo — with its commit SHA recorded — before the first
   publish command in this phase is executed.
2. All three publish legs are rehearsed through their last safe, reversible step (`mix hex.build`,
   not `hex.publish`; `git subtree split`, not a tag push) at least once, with the rehearsal output
   recorded.
3. A multi-registry partial-failure response table exists in-repo, authored before the first publish
   in this phase — not derived live during an incident.
4. The lower-blast-radius held companion PR (#147 or #115, whichever has fewer downstream consumers)
   is merged and its package is live on Hex, confirmed by a Hex.pm registry check showing the new
   version.
5. `crosswake 0.2.2` is live on Hex, the iOS mirror, and Maven, confirmed by independent registry
   checks against all three targets.
6. `exact-public-proof` **executed** (status is not `skipped`) and **passed** for `0.2.2`, confirmed
   by a linked CI run ID/URL for that exact version — not by re-reading the workflow definition.
7. The second held companion PR is merged and published, and the linked-release rollup reports
   `COMPLETE`.
8. `docs/COMPANION-PUBLISH-RUNBOOK.md`'s "this pipeline only publishes 0.2.1" section is deleted in
   the same change window that makes it false, and residual `splitsh-lite` references across the repo
   are replaced with `git subtree split` documentation.

**Plans**: TBD

**Research**: Needs phase-level research (`/gsd-plan-phase --research-phase 175`) — confirm whether a
scratch/throwaway Hex organization or a `mix hex.publish --dry-run`-shaped mechanism actually exists
for full-graph rehearsal beyond `mix hex.build`; this affects how much of the graph can be exercised
before the real one-way door.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|-----------------|--------|-----------|
| 164. Dependency Security and Gate Authority | 5/5 | Shipped | 2026-08-28 |
| 165. Efficient and Maintainable CI | 13/13 | Shipped | 2026-09-09 |
| 166. Clean-Checkout Engineering Quality | 8/8 | Shipped | 2026-09-10 |
| 167. Documentation and Pull-Request Reconciliation | 9/9 | Shipped | 2026-09-12 |
| 168. 0.2.1 Release Candidate Readiness | 13/13 | Shipped | 2026-09-16 |
| 169. Diagnostic Legibility | 4/4 | Complete    | 2026-09-16 |
| 170. Vacuous Assertion Remediation | 0/TBD | Not started | - |
| 171. Version/Authority Split | 0/TBD | Not started | - |
| 172. Per-Package Proof Scope | 0/TBD | Not started | - |
| 173. Recovery-Path Proof Convergence | 0/TBD | Not started | - |
| 174. Clean-Room Host Realism & Adopter Fidelity | 0/TBD | Not started | - |
| 175. Rehearsal and Publish | 0/TBD | Not started | - |
