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

- [x] **Phase 169: Diagnostic Legibility** - Every release/verification check surfaces its own failing message, and distinguishes "never ran" from "never defined" (verification refreshed and passed 38/38 must-haves; UAT reconciliation complete at 7/7 automated checks, 2026-09-25) (completed 2026-09-25)
- [x] **Phase 170: Vacuous Assertion Remediation** - All 173 SEED-018-flagged sites are classified and every confirmed-vacuous one is rewritten so an empty collection fails (completed 2026-09-16)
- [x] **Phase 171: Version/Authority Split** - The release graph is version-parametric while the approval identity gate stays exact; the `0.2.1` weld and its interim tripwire are both retired atomically (completed 2026-09-17)
- [x] **Phase 172: Per-Package Proof Scope** - Byte-exact publish verification is proven against each package's own approved ref, never one shared ref for all six (completed 2026-09-17)
- [x] **Phase 173: Recovery-Path Proof Convergence** - `exact-public-proof` runs and must pass identically whether a publish happened via the ordinary or the recovery path *(all 4 plans executed and merged (#180); SC#2 satisfied 2026-09-18 by the post-merge fire-drill dispatch, run 35302554800 — the proof job is present and concludes `failure` at `PUBLICATION_RECORD_MISSING`. The first dispatch instead exposed a real defect that made the whole recovery workflow un-dispatchable; repaired in #181. Evidence in `173-NON-VACUITY.md`.)*
- [x] **Phase 174: Clean-Room Host Realism & Adopter Fidelity** - The clean-room lane exercises install, not just compile, on both code paths, and the two named adopter gaps are closed or deferred with a reason *(7/7 plans complete; canonical verification passed 8/8 truths. Matrix installer-before-doctor is captured across all ten profile/pass pairs and independently guarded. See `174-VERIFICATION.md`.)* (completed 2026-09-25)
- [ ] **Phase 175: Rehearsal and Publish** - A fresh successor core release publishes all three coordinates and passes exact-public proof with six-child COMPLETE in its own ordinary run; the second companion is independently live on Hex. Historical partial releases and the REL-10 Gate 1 breach remain recorded. REL-17 now makes the historical evidence gaps a hard stop for every future release until same-candidate controls and negative tests pass.

## Milestone Conventions

Every phase in milestone v23.0 closes with a `vacuity_taxonomy` record: for each new check the
phase landed, its shape against the six-shape vacuity taxonomy and a measured non-vacuity fact.
The rules live in [`VERIFICATION-CONVENTIONS.md`](VERIFICATION-CONVENTIONS.md). Phase 169's original
implementation closeout predates this convention and is covered retroactively by
[`169-VACUITY-TAXONOMY.md`](phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md) rather than
by editing its sealed `169-VERIFICATION.md`. A phase that lands no new checks states that
explicitly in its own record rather than omitting it.

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

**Plans**: 5/6 plans executed

Plans:

**Wave 1**

- [x] 169-01-PLAN.md — Tracer: a failing scanner check's own sentence reaches the maintainer verbatim; `failing` no longer shadowed by `missing` (MSG-01, MSG-03)
- [x] 169-03-PLAN.md — Version-neutral display names and a global duplicate-name scan, landed atomically (MSG-06)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 169-02-PLAN.md — `:unverifiable` / exit 3: could-not-verify is a distinct, documented outcome (FID-02, MSG-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 169-04-PLAN.md — Exit-contract drift guard and canonical-doc link (FID-02)

**Wave 4** *(gap closure after Plan 175-11 trigger isolation)*

- [x] 169-05-PLAN.md — Exact push-only Release Please and dispatch-only Maven fire-drill proof, with non-vacuous re-coupling rejection (MSG-06, G-169-1)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 169-06-PLAN.md — Re-run the focused trigger proof and reconcile diagnosed UAT; phase verification refresh follows (MSG-06, G-169-1)

**Wave structure**: Wave 1 = 169-01 and 169-03 in parallel (no shared files) · Wave 2 = 169-02 ·
Wave 3 = 169-04 · Wave 4 = 169-05 after the deliberately isolated rehearsal architecture ·
Wave 5 = 169-06 fresh UAT proof and evidence reconciliation.

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

**Plans**: 5/5 plans complete
**Wave 1**

- [x] 170-01-PLAN.md — Inventory script, committed classification ledger, and its non-vacuity proof (VAC-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 170-02-PLAN.md — Frozen remediation manifest, guard insertions, and the itemized structural proof (VAC-02)
- [x] 170-04-PLAN.md — `vacuity_taxonomy` phase-close convention and the Phase 169 retroactive addendum (VAC-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 170-03-PLAN.md — Empty-input regression proofs at the high-blast-radius sites (VAC-02)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 170-05-PLAN.md — Phase 170's own taxonomy record and the decidable convention check (VAC-03)

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

**Plans**: 5 plans (one PR — see **Note on atomicity**; no plan is separately mergeable)

- [x] 171-01-PLAN.md — approved_version spine: guard derivation, four publish gates, the new
      `release.publish_gate.no_bare_version_literal` check with its pre-repair-fixture proof, and the
      tripwire deletion (wave 1)

- [x] 171-02-PLAN.md — version-parametric rollup coordinates and the clean-room validator's version
      conjunct removal (wave 2)

- [x] 171-03-PLAN.md — CLI entrypoint format checks plus identity/mirror/status/coordinate
      generalization (wave 2)

- [x] 171-04-PLAN.md — publish and mirror shell scripts, the dispatch workflows, and the scanner's
      remaining self-assertions (wave 3)

- [x] 171-05-PLAN.md — the committed weld inventory, the DOC-05 terminology pass, the measured sweep,
      and the single-PR checkpoint (wave 4)

**Research**: Standard pattern — the receipt-output idiom (`approved-release-guard.outputs.*`) is
already established for head/tree/base; extending it one field is mechanical. Skip phase-level
research.

---

### Phase 172: Per-Package Proof Scope (completed 2026-09-17)

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

**Plans**:

- [x] 172-01-PLAN.md (Wave 1) — thread a per-package `candidate_ref` through the producer, the schema and both shell consumers
- [x] 172-02-PLAN.md (Wave 2) — the four-branch classifier, the derived `claim` field and the distinct `attested` bucket
- [x] 172-03-PLAN.md (Wave 3) — the non-vacuity proofs, including a single-byte real-tarball mutation, and `172-NON-VACUITY.md`

**Research**: Standard pattern — schema loosening with an established per-entry field already
present in the manifest shape. Skipped at phase level, as planned.

**Note (corrected during planning, 2026-09-17)**: this section previously implied the
`unique | length == 1` collapse lives in `cleanroom.ex`. It does not — it is a jq filter at
`script/verify_companion_cleanroom.sh:207`, with a producer-side twin at
`lib/crosswake/release_candidate/artifact.ex:18` (`@input_keys` carries ONE top-level
`candidate_ref` that `inspect_family!/1` broadcasts to all six packages). `cleanroom.ex` has no
`candidate_ref` field at all today, so the concept must be newly threaded in. Two further call
sites the pattern map missed: `script/release_candidate/hex_artifacts.sh:244` and the
observation-assembly comprehension at `verify_companion_cleanroom.sh:692-699`, which whitelists
four keys and drops `candidate_ref` before it reaches the evaluator.

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

**Plans**: 4 plans

Plans:

- [x] 173-01-PLAN.md — tracer: one shared publication-record emitter, one shared record assertion, one reusable proof workflow, both Hex lanes calling it
- [x] 173-02-PLAN.md — fixture proof that the ordinary graph and the recovery graph satisfy the same contract, with a declared lane roster that cannot shrink
- [x] 173-03-PLAN.md — the missing fail-closed rollup case, and a git-committed release ledger that outlives artifact retention
- [x] 173-04-PLAN.md — credential-free fire drill, one real dispatch observation of failed-not-skipped, and the phase's measured non-vacuity record

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

**Plans**: 7/7 plans executed; Phase 174-07 closes the matrix-path ROOM-02 gap

Plans:
**Wave 1**

- [x] 174-01-PLAN.md — Tracer: the legacy path's host gets a real metadata-bearing route, runs
      `mix crosswake.install`, and emits nine `step=` markers — proven by an actual run against live
      `crosswake_rindle 0.1.0` (ROOM-01, ROOM-02, ROOM-04)

- [x] 174-02-PLAN.md — The `manifest_contract` byte-identity guard, pinned to pre-phase commit
      `8bc77c35`, red on drift, on rename, on a deleted call site, and on an empty extraction (ROOM-06)

- [x] 174-03-PLAN.md — SEED-014's two high-severity adopter gaps: a blocking decision on CW-REQ-A's
      breaking vocabulary bump, and CW-REQ-B's refuted-versus-could-not-run exit split (FID-01)

**Wave 2** *(blocked on 174-01)*

- [x] 174-04-PLAN.md — A dispatchable clean-room rehearsal lane, the real rindle CI run recorded by
      run id and job conclusion, and the measured `step=` marker parity between both paths (ROOM-03,
      ROOM-04)

**Wave 3** *(blocked on 174-01 and 174-04)*

- [x] 174-05-PLAN.md — Threadline and sigra diagnosed separately, one root-cause finding each, plus
      the check that neither finding can silently go missing (ROOM-05)

**Wave 4** *(blocked on 174-05)*

- [x] 174-06-PLAN.md — The phase's `vacuity_taxonomy` non-vacuity record and the seven-row
      per-requirement disposition table (ROOM-01..ROOM-06, FID-01)

**Wave 5** *(gap closure; blocked on 174-06)*

- [x] 174-07-PLAN.md — Added `mix crosswake.install` before doctor in the matrix host loop; captured
      and independently verified all ten profile/pass installer-before-doctor runs (ROOM-02)

**Wave structure**: Wave 1 = 174-01, 174-02 and 174-03 in parallel (disjoint file sets) · Wave 2 =
174-04 · Wave 3 = 174-05 · Wave 4 = 174-06 · Wave 5 = 174-07.

**Research**: Standard pattern — pure backport of an already-working, already-tested function
(`matrix_write_host`) into a sibling code path in the same file. Skip phase-level research.
Skipped at phase level, as planned — there is no `174-RESEARCH.md` and therefore no
`174-VALIDATION.md` (Nyquist Dimension 8 not applicable), recorded rather than fabricated around.

**Note (surfaced during planning, 2026-09-18)**: the backport is not a literal copy.
`matrix_write_host` operates on a `phx.new`-generated host; the legacy path generates its host with
`mix new --sup`, so its router lives at `lib/clean_room_host/router.ex` with the module
`CleanRoomHost.Router` and there is no endpoint file. The route-metadata block transfers, the
surrounding mechanics do not. Also: `ROOM-02`'s wording ("the clean-room host") is broader than
Success Criterion 2's ("the legacy path"). Canonical verification found the original narrowed
implementation did not satisfy the phase goal, which requires installer-before-doctor on both
paths. Phase 174-07 closed the matrix path with a real candidate-local run and an independent
order/non-vacuity test; see `174-CLEANROOM-EVIDENCE.md` and `174-NON-VACUITY.md`.

---

### Phase 175: Rehearsal and Publish

**Plan137 execution update (2026-10-10):** Wave40 completed the one-use preflight path. The exact displayed attempt was authorized once and the production runner ran once; the production inspector and independent offline terminal audit passed. The sealed result is UNKNOWN / OBSERVATION_UNAVAILABLE at TAG_DRY_RUN / POLICY / POLICY_MISMATCH, with 16 public requests, 19 Git operations, one helper check, three permission checks, one dry-run, and zero tag/CI. The partial receipt does not establish PREFLIGHT_READY or release authority. Do not retry the consumed attempt or begin another acquisition absent a materially distinct, independently supported path and separate review. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; the release hold remains active. **No GSD command is eligible now.** Reopen only on an independently reproducible local defect suitable for no-network diagnosis or fresh verifiable candidate/policy evidence supporting a distinct bounded observation path and new review. Phase175 remains incomplete; verification/completion are ineligible. See `175-137-SUMMARY.md`.

**Plan136 execution update (2026-10-10):** Plan136/Wave39 completed the distinct local v3 exact-head preflight contract and fake Elixir-to-Node tracer. Its 36 required Node and 16 required ExUnit cases passed exactly once; the full suites passed 158 Node and 55 ExUnit tests, and syntax/format/scoped-diff checks passed. The trace-roster verifier now accounts for Mix's [L#…] completion suffix. No live attempt or external network/provider/credential/helper/hosted-Git access, dry-run, tag, CI, merge, registry or publication occurred; no release requirement or authority is promoted. Plan106 and Plans46–48/89 remain held, and REL-13/14/15/17 remain open. Phase175 remains incomplete and release-blocked. Exact next GSD command: $gsd-plan-phase 175 --ws quality-ratchet-release --skip-research, to prepare a separately reviewed fresh preflight plan; the later tag decision remains distinct.

**Plan73/74/76 execution update (2026-10-03):** Plan73 completed its bounded local adapter and fake-verification work. Plan76 superseded its earlier credential-absent stop and used the existing one-read authorization once. That attempt ended `UNKNOWN_UNVERIFIABLE`; the lifecycle validates as a terminal safe stop, while the preflight path contains only its reservation marker. No valid Plan73 PREFLIGHT_READY artifact exists. Plan74 remains safely blocked before the tag-write decision, and both Plan74 evidence paths remain absent. Plan55/70 stay UNKNOWN; REL-13/17 stay OPEN; candidate readiness stays BLOCKED; merge-policy stays UNKNOWN; release hold stays ACTIVE; Plans45–48 stay held.

**Plan81 execution update (2026-10-05):** The exact-read decision was recorded for the displayed single-use attempt and scope, then the attempt stopped at CREDENTIAL_UNAVAILABLE because the dedicated credential was absent or blank. The terminal lifecycle has no read intent and records zero requests; no readiness artifact or provider observation exists. Both offline terminal and release-held inspections passed. REL-13/14/15/17 remain OPEN, candidate readiness BLOCKED, merge-policy UNKNOWN, release hold ACTIVE, and Plans45–48 remain held. This is a terminal zero-request safe stop; Plan82 supersedes its unnecessary credential assumption with an anonymous-only bounded continuation, and Plan81 is never replayed.

**Plan82 execution update (2026-10-05):** Official REST-shape fixtures and anonymous-only transport passed `node --check` plus 20 offline tests. Exact attempt `f0147212e39ac9b1fd0e7c9905d16e7a`, scope `8f2d7445b30fd7472662580b50c9e4621ad0a3b1153287939a4cc76f25b3bdd8`, was authorized and consumed. The single anonymous observation ended `UNKNOWN/HTTP_UNAVAILABLE` after 4 requests; offline terminal and release-held inspections passed. No retry, credential fallback, token rotation, extra human verification, or CI lane. GSD executor dispatch was unavailable (`orchestrator-worktree`, `exec:null`), so the orchestrator recorded completion without atomic commits. Plan82 must not be replayed. Phase175 remains incomplete; Plans46–48 stay blocked behind halted Plan45; release holds remain active. See `175-82-SUMMARY.md`.

**Superseded post-Plan82 discussion decision (2026-10-05):** Its wait-for-evidence posture was resolved by the fresh anonymous scope read on 2026-10-06. Plan82 remains terminal and must not be retried. See the current Plan84 action below; do not reopen discussion or repeat planning absent new decision-changing facts.

**Historical next GSD action (superseded by Plans75/76):** `$gsd-plan-phase 175 --ws quality-ratchet-release` was the action before the local rulesets-only continuation was planned. Do not repeat phase planning for this repair.

**Goal**: A freshly rehearsed and explicitly authorized successor core candidate and the held
second companion are live through the repaired release graph, with exact-public proof executed and
passed and all six core children COMPLETE in that same ordinary run. The failed 0.2.2 preparation,
0.2.3 PARTIAL, 0.2.4 PARTIAL (Hex only), 0.2.5 PARTIAL, and historical REL-10 Gate 1 breach remain
separately recorded. The 0.2.5 Gate 2 token is consumed; any later candidate requires REL-17 and a
new candidate-specific gate.

**Depends on**: Phases 169, 170, 171, 172, 173, and 174 all complete and green. This phase must
never be combined with any of them in the same plan — "the graph is fixed" and "we shipped 0.2.2"
are deliberately forced into separate checkpoints.

**Requirements**: REL-10, REL-11, REL-12, REL-13, REL-14, REL-15, REL-16, REL-17, DOC-04, DOC-06

**One-way-door note**: This phase contains the milestone's only irreversible operations — Hex
publish, iOS mirror tag push, and Maven upload (project decision D-19). REL-10 required the
retire/backfill runbook to reach the remote graph before the first publish; Gate 1 breached that
condition and cannot be repaired retroactively. Exact remote runbook ancestry remains mandatory
for every subsequent gate. The first companion published historically; the current successor core
requires a fresh Gate 2, and the second companion requires its own later Gate 3. No planning text
authorizes either publication.

**Known release blocker (REL-17):** T-175-35 through T-175-40b remain immutable historical evidence
gaps. The maintainer accepted those gaps only as facts about past events. No future linked release,
recovery, or companion publication may be authorized until all paths consume one immutable,
operation-bound envelope keyed by receipt digest, operation, and leg run; live mutable facts are
re-fetched at authorization and immediately before each side effect; the post-merge envelope binds
the actual merge OID; and the six conditions, including retained/nonempty registry evidence, the
matching response-table row, protected-path/no-bypass proof, and exact runbook ancestry, fail closed
under per-condition and per-path mutation tests. Until then, the release hold is active; a new
candidate or token does not waive it.

**Success Criteria** (what must be TRUE):

1. A retire/backfill runbook covering Hex (`mix hex.retire`), the iOS mirror (re-tag/note), and
   Maven (retire-forward) is committed to the remote publish graph — with its commit SHA recorded and
   verified against exact fetched PR base/head OIDs — before the first publish command in this phase
   is executed. **Gate 1 breach (2026-09-19):** the original local-`HEAD` check passed, but PR #147's
   base, head, and merge excluded the runbook. This criterion is historically unsatisfied and cannot
   be repaired retroactively; remaining gates fail closed on exact remote OIDs.

2. All three publish legs are rehearsed through their last safe, reversible step (`mix hex.build`,
   not `hex.publish`; `git subtree split`, not a tag push) at least once, with the rehearsal output
   recorded.

3. A multi-registry partial-failure response table exists in-repo, authored before the first publish
   in this phase — not derived live during an incident.

4. The lower-blast-radius held companion PR (#147 or #115, whichever has fewer downstream consumers)
   is merged and its package is live on Hex, confirmed by a Hex.pm registry check showing the new
   version.

5. The ordinary-lane defects observed in 0.2.4 and 0.2.5 are corrected and proven by local negative
   controls and safe rehearsals; a freshly authorized successor core candidate then publishes Hex,
   iOS mirror and Maven in one ordinary run, confirmed by three independent exact registry checks.
   Plans 175-26/27 and 175-33 record the local repairs; none substitutes for this fresh-run result.
   The original 0.2.2 preparation and 0.2.3/0.2.4/0.2.5 PARTIAL incidents are never counted as this
   successor; missing coordinates from those versions are not recovered.

6. `exact-public-proof` **executed** (status is not `skipped`) and **passed** in the same successor
   ordinary run, confirmed by its run ID and valid exact artifact — not by re-reading workflow
   definition or by a recovery job. That run's linked rollup reports all six core children successful
   and COMPLETE.

7. The second held companion PR is merged and published behind its own one-way gate and confirmed
   directly on Hex. Its publication is a separate fact from the core linked-release COMPLETE rollup.

8. `docs/COMPANION-PUBLISH-RUNBOOK.md`'s "this pipeline only publishes 0.2.1" section is deleted in
   the same change window that makes it false, and residual `splitsh-lite` references across the repo
   are replaced with `git subtree split` documentation. *(Satisfied 2026-09-18 by 175-05: the section
   deleted at `ed0006e4` (DOC-04), `git subtree split` named in all three mirror-split locations at
   `21b093aa` (DOC-06); the one residual `splitsh` reference — a comment in
   `script/check_ios_mirror_parity.sh:31` — is not a live invocation and was left as-is. A new
   merge-blocking `script/check_release_doc_version_literals.exs` check, wired into
   `crosswake-ci.yml` at `7219968a`, now fails the build if either release document regains a bare
   version literal outside a code fence or loses its invariant sentence.)*

9. The REL-17 known release blocker is enforced before any linked release, recovery, or companion
   publication can reach an irreversible action: all paths consume the same immutable
   operation-bound evidence contract; live mutable facts are re-fetched at authorization and
   immediately before side effects; the post-merge record binds the actual merge OID; registry bytes,
   nonempty parse, matching response-table row, protected-path/no-bypass evidence, and exact runbook
   ancestry are checked for T-175-35 through T-175-40b; and per-condition/per-path mutations prove
   missing, stale, mismatched, or bypassed evidence cannot pass. Until this criterion is satisfied,
   all new release attempts remain blocked.

**Plans:** Plan artifacts are tracked through Plan 175-137; additive Plans118/119 provide the local Plan105 checkout repair and separately gated fresh-read path, while Plan120 is planned as a local-only repair for the observed subtree-split timeout and authorizes no new read. Plan85 completed local-only Wave 1 execution (two autonomous tasks; passing diagnostic tests; no release authority); Plan86 completed local-only Wave 1 execution (14 Plan86 tests, 46 Plan84 tests, 21 Plan85 tests, and named format check passed; no release authority); Plan87 completed local-only Wave 1 execution (11 ExUnit, 10 Node, 81 Plan84–86 regressions and named format/syntax/diff checks passed; no provider or release action). Plan90 completed its local-only Wave 2 read-scope contract repair (14 ExUnit, 13 Node and named format/syntax/diff checks passed; two scoped commits; no workstream evidence, credential or external access). Plan91 completed fake-only operation accounting in six task-scoped commits; ExUnit, Node, Plan84–86 regressions, format and diff checks passed, and all 138 sampled prior evidence files stayed byte-identical. Plan88 is a terminally halted Wave3 attempt whose scope/lifecycle remain immutable and whose old ALLOW is invalid under Plan91; Plan89 is Wave4 and blocked by the halted Plan88. Plan81 is the reviewed Wave 2 D-106 bounded read-only observation and ended at CREDENTIAL_UNAVAILABLE before read intent with zero requests. Plan82's anonymous-only correction passed 20 offline tests. Attempt `f0147212e39ac9b1fd0e7c9905d16e7a` at scope `8f2d7445b30fd7472662580b50c9e4621ad0a3b1153287939a4cc76f25b3bdd8` is terminal UNKNOWN/HTTP_UNAVAILABLE after 4 requests; terminal and release-held inspections passed. It is consumed and must not be retried or replaced without a new plan and authorization. Plan72 and Plan73's local contract are complete. Plan74 completed only its safe blocked branch: Plan73 PREFLIGHT_READY is absent, so no tag decision or Task2 occurred and both Plan74 evidence paths remain absent. Plan76 consumed the existing one-read authorization once and ended UNKNOWN_UNVERIFIABLE; its terminal lifecycle validates, but its preflight path contains only a reservation marker. Do not replay it. Plans45–48 remain held and Phase175 remains incomplete. Plan 175-64 completed one BLOCKED, read-only diagnostic; its workflow-content reason is `invalid_base64_whitespace`, aggregate proof remains UNKNOWN, and no release action followed. Plan 175-65 completed a fresh bounded diagnostic: workflow decoding succeeded, the exact-head aggregate proof is FALSE, and the one-shot D-76 rerun was NOT_REQUESTED. Plan 175-66 completed its reviewed predicate-only diagnostic at the exact immutable run head. It found `workflow_job_coverage` and `observed_job_roster_mismatch` (49 jobs, 47 aggregate dependencies, 49 observed run jobs) and retained only safe IDs/counts. Plan66's artifact/lifecycle pair is terminal and its exact-head workflow bytes were not retained. Plan 175-67 corrected the local evaluator for the manifest-defined `brand-visual` advisory and passed an independently parsed local workflow roster regression (49 jobs, 47 governed dependencies). This local result does not prove remote/local workflow identity. See `phases/175-rehearsal-and-publish/175-66-SUMMARY.md` and `175-67-SUMMARY.md`. No rerun, source, or release operation occurred. Plan 175-55 remains halted after an interrupted execution. Existing plans 175-01..38 and their evidence remain preserved. Plans 175-26/27 and
175-33 completed bounded repairs; Plans 175-28/29 and 175-38 preserve the 0.2.5/0.2.6 blocked or
PARTIAL history; Plans 175-30..32 are superseded. Plans 175-34..37 are complete. Plans 175-39..41
are superseded because the consumed 0.2.6 attempt published none of its coordinates and cannot
supply their same-run proof or companion prerequisites; their occupied incident evidence paths
remain unchanged. New Plan 175-42 is the local authorization-selector and exact source-envelope
binding repair. It prepares no candidate and grants no publication authorization. Plans 175-43..48
cover the local raw-trailer repair, repair-lineage and candidate preparation, a distinct core Gate 2,
same-run proof, held-companion Gate 3, and evidence-backed closeout. Plan 175-44's repair PR merged,
but required CI for fresh candidate PR #219 failed because the iOS mirror lacks `v0.2.6`; Plans
175-45..48 remain blocked. Plan 175-49 is preserved as a blocked one-time reconciliation attempt:
its recorded checkpoint dry-run failed, and later diagnostic retries did not refresh its receipt.
Plan 175-50 performed a new full preflight but is also blocked because the dry-run did not prove
exactly one accepted target ref. Do not resume either plan or reuse either digest. Plans 175-51
and 175-52 halted with ambiguous dry-run status or output and no replay authority. Plan 175-53
halted at the SOURCE boundary with `FULL_CLONE_SPLIT_FAILED`; no reservation or dry-run occurred,
the independent audit was ineligible, and no proof artifact exists. Do not retry it or reuse its
receipt. Plan 175-54 executed once and halted at SOURCE after `FULL_CLONE_SPLIT_FAILED`; it does not
grant a 0.2.7 tag decision, merge, registry, or publication authorization. No existing plan grants
0.2.7 merge or publication authority. Plan 175-55 was a separately reviewed evidence-only follow-up
depending only on completed Plan 175-43. Its executor ended without a terminal response after two
scoped commits and additional uncommitted changes; it is recorded as a halted partial attempt with
no task verification result or evidence receipt. Do not replay it or infer that Task 3 ran. REL-13/17
remain open, the release hold remains active, and planning grants no release, registry, merge or
publication authorization.

Plans:
- [x] 175-104-PLAN.md

**Additive Plan122 index note (2026-10-09):** The preceding overview predates Plans121 and 122. Plan121 remains a consumed terminal read; Plan122 is the new Wave26 local-only classifier repair. The entries below preserve the release hold and do not create a read scope or release authority.
- [x] 175-102-PLAN.md — Wave11 completed as a local-only diagnosis; follow-up commit tracing resolved the hash mismatch as two typos in the later Plan101 summary. No evidence changed; fetch cause remains unknown. See `175-102-SUMMARY.md`.
- [x] 175-95-PLAN.md
- [x] 175-96-PLAN.md — Add closed, local-only diagnostics for the `git subtree split` failure stage; depends on Plan95, Wave5. Independent plan review passed. No public read or release action.
- [x] 175-97-PLAN.md — Preserve current public tag/PR facts through a source-split failure and prepare one fresh anonymous read scope; depends on Plan96, Wave6. Exact ALLOW is required before the public read; no credentials, CI, tag write, or release action.

**Wave 2** *(depends on completed Plan80; execute only after its own exact read decision)*
- [x] 175-81-PLAN.md — Completed the D-106 single-use path at CREDENTIAL_UNAVAILABLE before read intent; zero provider requests, no readiness artifact, and no release authority. The consumed attempt cannot be replayed. Plan82 supersedes the credential requirement. The phase-level REL-13/14/15 coverage blocker remains open. See phases/175-rehearsal-and-publish/175-81-SUMMARY.md.

**Wave 3** *(depends on terminal Plan81; fresh attempt after local validation)*
- [x] 175-82-PLAN.md — Correct documented REST fixtures and the 34-request cap offline; prepare and consume one exact anonymous-read decision. Observation ended UNKNOWN/HTTP_UNAVAILABLE after 4 requests; terminal and release-held inspections passed. No retry, credential fallback, or release authority. See `175-82-SUMMARY.md`.

**Effective Wave 4** *(GSD derives this from Plan82; Plan83 is terminal and Plan84 is now a terminal UNKNOWN safe stop)*
- [x] 175-83-PLAN.md — HALTED after Task1's proven safe stop. Focused tests passed 36/36 and historical compatibility tests passed 24/24. Attempt `8131f42e4099f165cb157d7fc03d7ff4` is consumed at `UNKNOWN/OBSERVATION_UNAVAILABLE`: one request intent, actual request occurrence/count unresolved, zero dry-run/tag/CI attempts. Both offline inspections passed. Task2 is ineligible; no tag or conditional CI choice is offered. Never replay this attempt. See `175-83-SUMMARY.md`; current base/scope must be independently established before new scoped discussion/planning. No release authority follows.

- [x] 175-84-PLAN.md — HALTED after Task1's local gates passed and Task2's sole preflight ended `UNKNOWN/OBSERVATION_UNAVAILABLE`. Attempt `b847ab413396f582ee900bcd445a3dd7`, digest `33d0d92cc080c10d00054e8ba5693ddd0a5f40f2551bdb28c1da0caeae6f98e0`; one request intent, zero confirmed requests, actual count unknown, and zero dry-run/decision/tag/CI attempts. Offline inspection passed. Task3 is ineligible; never replay this attempt. The live acquisition is closed; the distinct local Plan85 twin subsequently completed without reopening it. See `175-84-SUMMARY.md` and the Plan84 evidence pair.

- [x] 175-78-PLAN.md
- [x] 175-79-PLAN.md — Validate and track the receipt helper unchanged, rerun blocked local scanner checks, and refresh only supported structural claims.
- [x] 175-80-PLAN.md — Completed the D-104/D-105 matrix-and-ledger follow-up: 13 local workflow-structure claims now reflect passing named scanner and mutation/order evidence, the exact five-module suite passed, and Windows entry 36 was fixed after both dynamic count gates. Unsupported cells and all release holds remain unchanged; Phase175 remains incomplete. See `phases/175-rehearsal-and-publish/175-80-SUMMARY.md`.

- [x] 175-71-PLAN.md — Additive read-only local diagnosis of retained Plan70 facts and current code paths; preserves UNKNOWN and the release hold.
- [x] 175-70-PLAN.md — HALTED after the one authorized read-only collection exited 1; local inspection validates terminal `collection-failed`, with no artifact, source result, request count, or cause established. The attempt is consumed; no release action followed.
- [x] 175-69-PLAN.md — HALTED after one read-only collection exited 1; artifact absent and partial lifecycle preserved, with no source result, request count, or cause inferred. Do not retry.
- [x] 175-68-PLAN.md — Terminal exact-head diagnostic returned UNKNOWN; the immutable evidence pair validated, with no retry or release action.

- [x] 175-66-PLAN.md

- [x] 175-11-PLAN.md
- [x] 175-12-PLAN.md
- [x] 175-13-PLAN.md
- [x] 175-14-PLAN.md — PARTIAL: one authorized 0.2.3 ordinary graph published Hex only; iOS was separately recovered under PR #200/run 35926844126; Maven remained absent in the recorded snapshot. Keep the summary/evidence immutable.
- [x] 175-18-PLAN.md — Read-only 0.2.3/Maven recovery and fresh PR #201 eligibility reconciliation; no dispatch or mutation.
- [x] 175-19-PLAN.md — PARTIAL/HALTED: fresh PR #201 identity and safe Hex/iOS/Maven rehearsals passed; canonical receipt production is blocked and Gate 2 remains pending.
- [x] 175-24-PLAN.md — Repository-owned canonical receipt producer/attestation integration with missing, stale, matching, privacy, and bypass automation proof; no live dispatch or Gate 2.
- [x] 175-25-PLAN.md — Refresh the post-producer candidate, rerun safe CI/Hex/iOS/Maven evidence, generate and independently attest the exact receipt, and leave Gate 2 pending/null-authorized.
- [x] 175-20-PLAN.md — HALTED_PARTIAL history: exact protected merge and one ordinary graph recorded; Hex 0.2.4 present, iOS tag absent, Maven POM 404, proof skipped; no retries/recovery.
- [ ] 175-21-PLAN.md — SUPERSEDED pending 0.2.4 same-run proof path; see 175-30.
- [ ] 175-22-PLAN.md — SUPERSEDED pending 0.2.4 companion Gate 3 path; see 175-31.
- [ ] 175-23-PLAN.md — SUPERSEDED pending 0.2.4 companion closeout path; see 175-32.
- [x] 175-26-PLAN.md — Repair ordinary iOS Mix/runtime and prove missing/late setup fails; focused suite passed (2026-09-24, `b413827c`).
- [x] 175-27-PLAN.md — Accept exact ordinary Maven successor identity and receipt; keep recovery pin separate (2026-09-24, `1a2c0daf`).
- [x] 175-28-PLAN.md — BLOCKED before merge: PR #206 exact-head CI run `36061805761` failed `ios-mirror-parity-proof` because the known partial 0.2.4 iOS mirror tag is absent; no rehearsal or Gate 2 started.
- [x] 175-29-PLAN.md — New exact Gate 2; one authorized protected merge and ordinary core run.
- [ ] 175-30-PLAN.md — SUPERSEDED: depended on the 0.2.5 same-run proof path; revisit only after a fresh candidate is planned and rehearsed.
- [ ] 175-31-PLAN.md — SUPERSEDED: companion Gate 3 depended on the failed 0.2.5 closeout path.
- [ ] 175-32-PLAN.md — SUPERSEDED: companion publish/closeout depended on the failed 0.2.5 closeout path.
- [x] 175-33-PLAN.md — Receipt contract and external Hex consumer proof repairs; incident postmortem and interim lessons recorded. 0.2.5 remains PARTIAL.
- [x] 175-34-PLAN.md — Pure operation-bound REL-17 contract, linked path tracer, field mutations, and package-scoped companion receipt. *(gap closure)*
- [x] 175-35-PLAN.md — Fresh remote evidence adapters, post-merge registry provenance, and read-only blocked status. *(gap closure)*
- [x] 175-36-PLAN.md — Wire shared fail-closed checks to ordinary, recovery, and all five companion publisher paths; prove guard-removal mutations. *(gap closure; 11 files across three focused tasks)*
- [x] 175-37-PLAN.md — After REL-17 closes, identify and safely rehearse a fresh successor with a new receipt and pending exact evidence. *(gap closure)*
- [x] 175-38-PLAN.md — One protected 0.2.6 merge and one ordinary Release Please attempt; outcome PARTIAL before publishers, with Gate 2 consumed and no coordinates present. *(gap closure; historical candidate-specific decision)*
- [ ] 175-39-PLAN.md — SUPERSEDED: its 0.2.6 exact-public and six-child proof prerequisite was not achieved; replan after a future successful core release.
- [ ] 175-40-PLAN.md — SUPERSEDED: its held PR #115 Gate 3 depends on Plan 175-39's missing same-run proof; replan against a future candidate.
- [ ] 175-41-PLAN.md — SUPERSEDED: its closeout depends on the unsuccessful Plans 175-39/40; replan from later evidence.
- [x] 175-42-PLAN.md — Bind future Gate 2 phrase and trailer to the Hex `leg_run_id` and exact retained source envelope; prove the real workflow and loader reject the iOS ID before publishers. *(gap closure; local only)*
- [x] 175-43-PLAN.md — Bind post-merge live capture to the fetched raw merge trailer, candidate, receipt, operation and Hex leg.
- [x] 175-44-PLAN.md — Stage or verify exact repair lineage; execution halted at Task 2 after fresh candidate PR #219 CI failed because mirror tag `v0.2.6` is absent.
- [x] 175-45-PLAN.md — Revalidate a candidate and capture a distinct, exact core Gate 2 decision before one ordinary core run.
- [ ] 175-46-PLAN.md — Verify the same run's executed exact-public proof and six-child COMPLETE rollup.
- [ ] 175-47-PLAN.md — Gate and observe held PR #115's separate companion publication and direct Hex result.
- [ ] 175-48-PLAN.md — Reconcile current evidence while preserving the historical Gate 1 breach and release hold.
- [x] 175-49-PLAN.md — BLOCKED / DO NOT RESUME: its full preflight failed and the receipt/digest is stale; later diagnostic dry-runs do not authorize a decision.
- [x] 175-50-PLAN.md — BLOCKED / DO NOT RESUME: fresh full preflight stopped because the dry-run did not prove exactly one accepted target ref; do not reuse its digest.
- [x] 175-51-PLAN.md — HALTED / DO NOT RESUME: the preflight invocation returned `RECEIPT_WRITE_FAILED`; its dry-run status is ambiguous. Receipt is `BLOCKED_PREFLIGHT`, zero writes, no decision; any later attempt requires a new plan and digest.
- [x] 175-52-PLAN.md — HALTED / DO NOT RESUME: one reserved dry-run exited 0 with one expected tuple, but unclassified stdout prevented a complete parse; receipt remains blocked with zero writes and no decision.
- [x] 175-53-PLAN.md — HALTED: `FULL_CLONE_SPLIT_FAILED` at SOURCE before reservation; zero dry-run invocations, zero writes, no decision, and no proven artifact. Do not retry or reuse its receipt.
- [x] 175-54-PLAN.md — HALTED at SOURCE: the one bounded source split returned `NONZERO_EXIT` / `FULL_CLONE_SPLIT_FAILED`; no dry-run, tag write, or decision followed. Preserve its receipt; do not replay.
- [x] 175-55-PLAN.md — HALTED / DO NOT REPLAY: executor ended without a terminal report; preserve its two commits and remaining local changes. No verification result or Plan 55 evidence receipt was returned; Task 3 status is unconfirmed.
- [x] 175-56-PLAN.md — Local reconciliation complete; Plan 175-55 Task 3 remains UNKNOWN and cannot be replayed.
- [x] 175-57-PLAN.md — Local fail-closed collector and parity-command correction complete; no external action authorized.
- [x] 175-58-PLAN.md — BLOCKED at the exact-operation checkpoint; the fresh preflight did not authorize source work.
- [x] 175-59-PLAN.md — HALTED after an immutable BLOCKED preflight; transport failure requires a new attempt.
- [x] 175-60-PLAN.md — HALTED after an immutable BLOCKED preflight; run, GraphQL, and branch-declaration collection needed local correction.
- [x] 175-61-PLAN.md — Local exact-head run and GraphQL collector corrections complete with focused regression coverage.
- [x] 175-62-PLAN.md — Fresh preflight BLOCKED; CI rerun NOT_REQUESTED and no source or release action occurred.
- [x] 175-63-PLAN.md — Completed one bounded read-only diagnostic; run/job/status facts were preserved, workflow contents failed strict base64 decoding, and no CI rerun or source/release action occurred.
- [x] 175-64-PLAN.md — Completed the strict-rejection classifier and one fresh bounded read-only diagnostic under an exclusive Plan64 identity. `invalid_base64_whitespace`; aggregate UNKNOWN; no CI rerun or source/release action. See `175-64-SUMMARY.md`.
- [x] 175-65-PLAN.md — Completed one fresh diagnostic; workflow decode succeeded but aggregate proof was FALSE, so D-76 rerun was NOT_REQUESTED. Candidate readiness remains BLOCKED and the release hold ACTIVE. See `175-65-SUMMARY.md`.

Plans 175-08..10 and 175-15..17 remain unexecuted superseded artifacts from the earlier
0.2.2/0.2.3 tracks. Plans 175-21..23 are also unexecuted and superseded after D-39..D-42. Their
contents are preserved, as are the 0.2.3 and 0.2.4 partial evidence. Planning grants no release,
registry, merge or publication authorization; each one-way publication requires a new exact token.

**Wave 1**

- [x] 175-01-PLAN.md — Wave 0 triage: derive the `check-actions` scan scope from the tree and prove the scope gate fails on a narrowed scope
- [x] 175-56-PLAN.md — Reconciled the interrupted Plan 175-55 attempt from local read-only evidence; Plan55 stays UNKNOWN and REL-13/REL-17 and the release hold remain open.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 175-02-PLAN.md — Wave 0 triage: SHA-pin the 31 mutable action refs across the ten affected workflow files

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 175-03-PLAN.md — Wave 0 exit: the five-part exit record, the gate's vacuity row, and the blocking merge gate before Wave 1 — closed via PR #189, merged as `c0774e29`; Wave 1 released

**Wave 4** *(blocked on Wave 3 completion — unblocked)*

- [x] 175-04-PLAN.md — authored `docs/RELEASE-INCIDENT-RESPONSE.md` with its irreversibility summary, registry-grouped failure matrix, and recorded commit SHA at `d3401e51`. The later Gate 1 audit proved the plan's local-`HEAD` ancestry check was not remote release authority; REL-10 remains breached for the first publish.

**Wave 5** *(blocked on Wave 4 completion — unblocked)*

- [x] 175-05-PLAN.md — DOC-04 + DOC-06: delete the false runbook section, de-version its prose, document `git subtree split`, and add the version-literal CI check — deletion at `ed0006e4`, subtree docs at `21b093aa`, CI check driven red-then-green and wired at `7219968a`; Wave 6 unblocked

**Wave 6** *(blocked on Wave 5 completion — unblocked)*

- [x] 175-06-PLAN.md — REL-11: all three publish legs rehearsed against the real `0.2.2` candidate. Hex passed (35410810853); iOS mirror passed (35444279120); repaired Maven fire drill passed (35452376752), reached `VALIDATED` as deployment `8cacc3da-2613-407c-8df1-238b2ad0710c`, then dropped its disposable coordinate. Wave 7 is unblocked, but its publish gate remains explicitly one-way.
- [x] 175-64-PLAN.md — GSD execution Wave 6: completed the bounded Plan64 diagnostic with `invalid_base64_whitespace`; all release holds remain active and Phase 175 remains incomplete.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 175-07-PLAN.md — REL-12: `crosswake_rulestead 0.1.1` is live on Hex and its clean-room proof passed; the manual closeout preserves the independent publish/registry evidence and the Gate 1 incident record.

  **Incident:** PR #147 merged and `crosswake_rulestead 0.1.1` published, but the runbook commit was
  absent from the exact remote merge. The publish is not retroactively compliant; this plan remains
  closed only as a historical-incident reconciliation: REL-10 remains breached, while the repaired
  exact-OID guard has passed for the remaining core candidate's live base/head.

**Historical Wave 8 — superseded, unexecuted**

- [ ] 175-08-PLAN.md — SUPERSEDED historical 0.2.2 Gate 2 path; do not execute.

**Historical Wave 9 — superseded, unexecuted**

- [ ] 175-09-PLAN.md — SUPERSEDED historical 0.2.2 proof path; do not execute.

**Historical Wave 10 — superseded, unexecuted**

- [ ] 175-10-PLAN.md — SUPERSEDED historical 0.2.2 companion path; do not execute.

**Wave 12** *(blocked on Plan 175-42)*

- [x] 175-43-PLAN.md — Bind fetched post-merge evidence to the actual operation-bound release trailer.

**Historical Wave 13 snapshot — superseded by the new repair chain below** *(Plans 175-49..55 remain terminal; at this snapshot, Plans 175-45..48 were held behind halted Plan 175-44. Current Plan45 ordering is governed by the Plan72→73→74 dependency chain.)*

- [x] 175-44-PLAN.md — Verify repair lineage, then stage a fresh candidate and safe rehearsals.
- [x] 175-52-PLAN.md — HALTED: durable blocked receipt and reservation preceded the one permitted dry-run; exit 0 and one expected target tuple were recorded, but unclassified output made the full parse ambiguous. No retry, post-observation, independent audit, proven artifact, tag decision, or release authority.
- [x] 175-53-PLAN.md — HALTED at SOURCE: full-clone subtree split failed before reservation; zero dry-run invocations, no independent audit, no proof artifact, zero writes, and null decision.
- [x] 175-54-PLAN.md — HALTED at SOURCE: the one bounded source split returned `NONZERO_EXIT` / `FULL_CLONE_SPLIT_FAILED`; no dry-run, tag write, or decision followed. Preserve its receipt; do not replay.
- [x] 175-55-PLAN.md — HALTED / DO NOT REPLAY: partial implementation preserved; no returned test results or evidence receipt. Discuss and plan the remaining work before any new evidence attempt.

**Local diagnostic follow-up:**

- [x] 175-67-PLAN.md — Align the aggregate evaluator with the single manifest-defined `brand-visual` advisory; verify the current local workflow using an independently derived synthetic roster. This is diagnostic only and grants no release authority.
- [x] 175-68-PLAN.md — Completed one independently reviewed, read-only exact-head evidence attempt. It returned UNKNOWN with no complete run/check/policy/workflow observation and no workflow digest; the immutable artifact/lifecycle validate. Deep code review found no blocker; WR-01 was fixed so future unavailable facts/counts remain UNKNOWN without changing this artifact. No retry or release action occurred.
- [x] 175-69-PLAN.md — HALTED after its sole reviewed collection invocation exited 1 with unknown result. Plan69 artifact is absent; lifecycle contains only task-entry, reservation, and collection-intent. Attempt consumed; no source result, request count, or cause inferred. Plan68 remains terminal and immutable; its hashes still match. No release authority granted.
- [x] 175-71-PLAN.md — Completed local diagnosis of retained Plan70 facts and current runner/validator/request-boundary/fake paths. Plan70 cause and request occurrence/count remain UNKNOWN; no external or release action.
- [x] 175-76-PLAN.md — Used the existing Plan73 read authorization once after Plan75's local gates passed. Offline inspection confirms a terminal `UNKNOWN_UNVERIFIABLE` safe stop; the preflight path remains a reservation marker, no release action ran, and the authorization is consumed.
- [x] 175-77-PLAN.md — Local-only injected-adapter diagnosis of Plan76's UNKNOWN stop; synthetic findings do not explain Plan76 and grant no release authority.

**Plan85 local diagnosis — Wave 1** *(complete; followed by the separately scoped Plan86 local diagnostic)*

- [x] 175-85-PLAN.md — COMPLETE (local only): the real Elixir-to-Node loopback path, closed diagnostics, boundary limits and cleanup passed. Plan85 ExUnit 21, Node 21, Plan84 regression 46; broader release fixture/ratchet bundle 388 tests, zero failures; final full offline Mix 2,275 tests, zero failures/invalid tests (74 excluded). Five scoped source/test commits. No provider/credential/release action; Plan84 stays terminal UNKNOWN. See `175-85-SUMMARY.md`.

**Plan86 production diagnostics — Wave 1** *(complete; local-only, sequential tasks)*

- [x] 175-86-PLAN.md — Preserved closed collector-process failure classes in a separate sanitized UNKNOWN diagnostic with an offline-only inspector. Plan86 (14 tests), Plan84 regression (46 tests), Plan85 regression (21 tests), and named format check passed; Plan84 bytes/disposition and all release holds remain unchanged. No provider or release action. See `175-86-SUMMARY.md`.
- [x] 175-87-PLAN.md — Built and locally verified the fixed-origin mirror-tag repair adapter with fake-driven tests; no provider, credential, preflight, CI, tag, or release operation. See `175-87-SUMMARY.md`.
- [x] 175-90-PLAN.md — Completed the exact Plan88 read-scope path and full GET/Git authorization contract locally. Temporary-root gates passed 14 ExUnit and 13 Node tests plus named format/syntax/diff checks; invalid scope stops before credential/collector callbacks, GET scope cannot POST, and the fake actor sentinel is absent from artifacts/output. Two scoped commits; no real attempt or workstream evidence. See `175-90-SUMMARY.md`.
- [x] 175-91-PLAN.md — Completed fake-only operation-accounting contract repair in six task-scoped commits. Temporary-root ExUnit, Node, Plan84–86 regressions, formatting, and diff checks passed; all 138 prior evidence files stayed byte-identical. No workstream attempt, credential, provider/Git remote operation, tag, CI, merge, registry, or release action. Its follow-up Plan92 is terminally halted; see `175-92-SUMMARY.md`.
- [x] 175-92-PLAN.md — HALTED at `TRIGGER_UNVERIFIED` after creating and inspecting one attempt-specific path set and sealing a zero-request D-107 HOLD. The verifier rejects self-asserted local metadata because no authenticated origin proof/trust anchor exists in the checkout; the retained run is historical and failed required checks. No read or release action occurred. See `175-92-SUMMARY.md`.
- [x] 175-93-PLAN.md — HALTED at Task3 after an inexact `allow` reply was classified as `READ_NOT_ALLOWED`. Attempt `480db51798d676a00645f29822d951c9` is terminal HOLD with zero requests, zero read intent, zero invocations, and empty parent/child journals. No credential, provider, or Git remote access occurred. See `175-93-SUMMARY.md`.
- [x] 175-94-PLAN.md — Terminal BLOCKED safe stop before any external request; its read-intent revalidation defect was fixed and tested by Plan95. Do not retry or reuse its attempt. See `175-94-SUMMARY.md`.
- [x] 175-88-PLAN.md — Terminal halted safe stop: its historical PENDING scope and reservation lifecycle remain immutable, with zero requests and no authorization or external access. The prior ALLOW is ineligible under Plan91's changed contract. See `175-88-SUMMARY.md`.
- [ ] 175-89-PLAN.md — Held and transitively blocked by halted Plan88; no fresh `PREFLIGHT_READY` result or distinct exact ref/OID write decision exists, so no create-only tag operation is eligible.

**Public exact-head CI recheck (2026-10-06T23:15:43Z):** PR #219 remains on base `e51698528dc667ef89beb951e4eb1ec91da74981` and head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`. Its complete associated check-run roster is 49/49 terminal: 47 success, with `Crosswake CI` and `ios-mirror-parity-proof` failing. The latest check completed 2026-09-28; the parity job failed at `Check iOS SwiftPM mirror parity`. This confirms stale failing CI and does not make Plan45 eligible. Sanitized snapshot: `evidence/175-public-candidate-check-runs-20261006.json`.

**Plan87–90 mirror-tag repair sequence (updated 2026-10-07):** Plan87 Wave 1 is complete; Plan88 initially stopped before writing due its missing scope binding/path. Plan90 Wave2 repaired and independently verified the scope contract. Plan88 Wave3 Task1 prepared one exact PENDING scope with zero requests, and the user returned ALLOW for its attempt/digest. Plan88 Task3 then stopped before authorization, credential lookup, or provider/Git access because the Plan87 evidence/lifecycle contract does not persist exact API and Git operation counts, including failure accounting. A separate local contract repair and validation must precede any fresh read scope; the prior ALLOW cannot be reused after changing that contract. Plan89 is Wave4 and remains gated on a complete fresh PREFLIGHT_READY result and a separate exact write decision. The dated candidate tuple is a stale comparison pin; existing failing CI is stale and all release holds remain active.

**Historical next GSD action after Plan69 (superseded by Plan70):** `$gsd-discuss-phase 175 --ws quality-ratchet-release`. At that point, the instruction was not to retry Plan69, repair its partial lifecycle, or reuse Plan68's terminal evidence.

**Superseded Plan97 handoff (first attempt; 2026-10-07):** Last completed phase: 174; Phase175 remains INCOMPLETE. Plan96 and Plan97 Tasks1–2 are complete. Plan97's focused local checks passed, and one read-only scope is reserved as PENDING with zero public requests. The scope concerns Crosswake source repo `szTheory/crosswake`, source tag `ios-core-v0.2.6`, its iOS mirror repo `szTheory/crosswake-shell-core-ios` (main, `v0.2.5`, and target `v0.2.6` refs), and PR #219 (`0.2.7`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`). It allows anonymous GETs only for those refs, PR #219, and the source/mirror objects needed for validation; Git clone/fetch is fixed to `https://github.com/szTheory/crosswake.git`. Limits: 32 API requests (10-second timeout, 32 KB response cap), at most nine fixed Git calls (clone 180s/fetch 60s/split 120s/other 20s), 240s collector timeout. Attempt `afd4c0548bdbfd9f320beaf23bd644c7`; path-set SHA-256 `568bdf208277f980c79078b7439f5be302e950e527214f8e16586a294d4c2f78`; scope SHA-256 `24fa017842dbf1ca5156c9c5284bf9d2b6d7400ae58ff319ff740a2a8d5c5c78`; contract SHA-256 `ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2`. Awaiting the current user's exact ALLOW or HOLD for this card. If context is cleared before a decision, resume with `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 6`; do not create read intent or contact GitHub before exact ALLOW. This scope does not prove write permission or authorize CI, tag creation, merge, recovery, registry, or publication. REL-13/14/15/17 remain OPEN; readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD. See `175-97-PLAN.md` and `175-96-SUMMARY.md`.

**Current mirror-read repair — Waves 7–8:**

- [x] 175-98-PLAN.md — One approved bounded read preserved the current source/mirror/PR snapshot. Its sealed preflight remains BLOCKED because the collector ran subtree split without checked-out files. A separate local reproduction computed the exact split; see 175-98-SUMMARY.md and evidence/175-plan98-split-reproduction.json.
- [x] 175-99-PLAN.md — Fixed the collector to check out the exact source commit before subtree split, kept the nine-call cap, updated the diagnostic validator, and passed 21 Node plus 11 ExUnit tests. No new public request or release action.
- [x] 175-100-PLAN.md — Wave9: prove the corrected collector in an isolated root and reserve one fresh exact PENDING scope with empty separate parent/child journals and a complete approval card. Planning made no public read or release action.
- [x] 175-101-PLAN.md — Wave10, after Plan100: gate one anonymous read or zero-request HOLD on the new attempt/path-set/scope/contract-bound ALLOW, inspect exact-or-UNKNOWN terminal accounting, and record a sanitized outcome. Planning made no public read or release action.
- [x] 175-102-PLAN.md — Wave11 completed a local-only diagnosis. The authorization/preflight files match the Plan101 execution commit and current bytes; two fingerprints in the later summary were typos and have been corrected with an audit note. The collector still retained no fetch error class/code; no evidence or release state changed.
- [x] 175-103-PLAN.md — Wave12 local-only repair: record one fixed route key plus safe transport class/code on future Plan97 fetch rejection. Independent plan check passed; no new independent evidence or provider read is needed, and this cannot explain consumed Plan101 attempt `41321f55e8cb60c9a4f6c3ddcc62cd89`.
- [x] 175-104-PLAN.md — Wave13 completed one fresh bounded read. The current source split matches mirror main/prior tag and PR #219's recorded candidate facts; mirror target v0.2.6 is absent. Write permission remains UNKNOWN, tag authority NONE, and REL-17 remains active; no write or publication occurred. See 175-104-SUMMARY.md.
- [x] 175-105-PLAN.md — Wave14 consumed one exact read ALLOW and ended UNKNOWN before the first current-information snapshot completed. The saved public-request and Git-operation counts are UNKNOWN; permission/helper checks, dry run, and tag attempts are zero. Do not retry. See `175-105-SUMMARY.md`.
- [x] 175-107-PLAN.md — Wave14 after Plan105: repair safe failure reporting and prove the production apply adapter locally with fake lookups and a temporary bare Git repository. No public read, tag approval, tag write, or release action. See `175-107-PLAN-CHECK.md`.
- [x] 175-108-PLAN.md — Wave15 after Plan107: repaired the shared handoff and reconciled the collection ledger. Focused checks passed; the full Mix suite passed with 2,345 tests, zero failures, and 74 expected exclusions. Local-only; no release action occurred. See 175-108-SUMMARY.md.
- [x] 175-109-PLAN.md — Wave16 after Plans105, 107, and 108: the exact-approved PR #219 lookup exceeded its 16,384-byte response cap and ended terminal UNKNOWN. The body and exact size were not retained; request and later-operation counts remain UNKNOWN. Its attempt and ALLOW are spent. No tag or release authority followed.
- [x] 175-110-PLAN.md — Computed Wave16 after completed Plan108; Plan109's saved terminal result is context, not a success prerequisite. Local-only repair and fake tests set a 262,144-byte GitHub API response cap while keeping the Node apply-evidence file cap at 16,384 bytes and checking exact scope/authorization limits. No new attempt, read or approval occurs in this plan.
- [x] 175-111-PLAN.md — Wave17 completed one exact-approved, bounded Plan105 read. It ended terminal UNKNOWN / OBSERVATION_UNAVAILABLE at MIRROR_REPOSITORY / SHAPE / INVALID_SHAPE. The ALLOW is spent; operation counts remain UNKNOWN, no complete current snapshot exists, and Plan106 remains held. The raw response was not retained, so the exact cause cannot be reconstructed.
- [x] 175-112-PLAN.md — Wave18 local-only repair completed: anonymous mirror permission remains UNKNOWN unless caller-specific write access is independently proved; Elixir rejects UNKNOWN or forged readiness. This cannot establish Plan111's discarded response. See `175-112-SUMMARY.md`.
- [x] 175-113-PLAN.md — Wave19 local-only authenticated permission contract and fake proof completed. Attempt `043375a9084a4e0d4d5a4031dcbb7942` is PENDING at scope digest `92d9124322274a9d2ae3dcc772e2bf86dccde3bd77c1498bc9f8c8f26c05bc03`, with zero operations. No credential lookup or provider request occurred. See `175-113-SUMMARY.md`.
- [x] 175-114-PLAN.md — Wave20 halted with terminal HOLD because its prompt required a copied attempt ID and scope digest. Offline inspection confirms zero credential checks and external operations. Its attempt and prior reply are consumed and remain unchanged.
- [x] 175-115-PLAN.md — HALTED after its fresh ALLOW was used once. The terminal receipt is UNKNOWN / INCOMPLETE_CANDIDATE_FACTS with `diagnostic: null`; it records one credential-helper check, two permission checks, UNKNOWN public-request/Git-operation counts, and zero dry runs/tag attempts. The exact failed step is not known. Do not retry the attempt or reuse its approval; see `175-115-SUMMARY.md`.
- [x] 175-116-PLAN.md — DAG-computed Wave20 local-only repair completed. Closed failure stages and independent API/Git counts now pass fake-only Node and Elixir tests, including legacy receipt inspection and redaction canaries. The repair cannot explain Plan115's historical UNKNOWN. See `175-116-SUMMARY.md`.
- [x] 175-117-PLAN.md — DAG-computed Wave21 complete. Fake-only proof passed (54 Node tests, 20 focused ExUnit tests); the single exact-approved read ended UNKNOWN at `SUBTREE_SPLIT / PROCESS / PROCESS_EXIT_NONZERO`, with 7 exact public requests, 11 exact Git operations, one credential-helper check, two permission checks, zero dry runs, and zero tag attempts. The receipt passed independent inspection; Plan115 stayed byte-identical. No candidate/permission/policy facts were established. See `175-117-SUMMARY.md`.
- [x] 175-118-PLAN.md — Wave22 complete. Both Plan105 split paths check out the pinned source commit before splitting; closed SOURCE_CHECKOUT diagnostics pass fake Node and Elixir proof. Node syntax and 57 tests passed; focused ExUnit 20 tests passed; formatting and scoped diff checks passed. Plan117 remains terminal UNKNOWN and its evidence is unchanged. No read or release operation occurred. See `175-118-SUMMARY.md`.
- [x] 175-119-PLAN.md — Wave23 complete. The single exact-approved read ended terminal UNKNOWN at `SUBTREE_SPLIT / PROCESS / PROCESS_TIMEOUT`, with 7 public requests, Git operations UNKNOWN, one credential-helper check, two permission checks, zero dry runs, and zero tag attempts. The collector's per-process cap is 15 seconds against a 240-second total scope ceiling. No current candidate, permission, or policy facts were established; the attempt and ALLOW are spent. Plan106 remains held. See `175-119-SUMMARY.md`.
- [x] 175-120-PLAN.md — Wave24 local-only gap closure complete. Only `SUBTREE_SPLIT` receives a process timeout up to 240,000 ms, clipped to the unchanged overall deadline; all other processes retain the 15,000 ms cap. Fake-only tests cover clipping, expired deadlines, UNKNOWN timeout/uncertain-exit accounting, no retry or release side effect, and redaction; the named Node suite passed 66 tests. No read scope or release action occurred; changes remain uncommitted because `.git` is read-only.
- [x] 175-121-PLAN.md — Wave25 completed after one exact-approved read. The terminal receipt is UNKNOWN at `SUBTREE_SPLIT / PROCESS / PROCESS_STDERR_NONEMPTY` (7 public requests, 12 Git operations, 1 helper check, 2 permission checks, zero dry runs or tag attempts). The live diagnostic did not retain stderr text or establish current facts. Plan122 later reproduced the pinned split locally, explaining the stderr classification failure; never retry Plan121 or reuse its ALLOW. See `175-121-SUMMARY.md`.
- [x] 175-122-PLAN.md — Wave26 local-only repair complete. A bounded stage-scoped classifier accepts only complete sequential Git subtree progress on successful SUBTREE_SPLIT; exact split stdout, split tree, and package tree checks remain required. Fake-only Node suite passed 90 tests, including Plan121 immutable-hash and active-release-hold assertions. No fresh read, scope, ALLOW, or release action occurred. See `175-122-SUMMARY.md`.
- [x] 175-123-PLAN.md — Wave27 local-only safety repair: add and fake-test strict prepare/inspect modes for a zero-read, zero-dry-run pending scope. Reject malformed/legacy/ALLOW/HOLD/read-intent inputs before callbacks; add no authorize/read route and create no attempt-specific evidence. The existing v2 preflight can try a test push when all checks pass, while the new local modes expose no callback path. A follow-on plan owns the fresh scope/card and separately gated current-facts read.
- [x] 175-124-PLAN.md — Wave28 complete: implemented and fake-tested the separate bounded current-read schema (95 Node, 28 ExUnit), then prepared and inspected exactly one PENDING scope/card with zero usage and no authorization/read intent/current facts. Attempt `0625d6afa47cef001f1241a2aa9787b8`, scope digest `cd09cb599c98757511b125f054042b2965057d7c67bb3944476bd1993ade4984`; see `175-124-SUMMARY.md`. No provider, helper, remote-Git, dry-run, CI, write, or release operation occurred.
- [x] 175-125-PLAN.md — Wave29 complete: exact ALLOW for the bound Plan124 scope/card permitted one read, which ended `UNKNOWN/OBSERVATION_UNAVAILABLE` without retained facts. GitHub/Git/helper/permission counts are UNKNOWN; dry-run/tag/CI counts are zero. No retry; all release holds remain active. Result SHA-256 `e7fb29aa2ca38346bb8a08395a33e6e35a183ac383353d7b9712dec36395fc3c`; see `175-125-SUMMARY.md`.
- [x] 175-126-PLAN.md — Wave30 complete: local repair and fake checks passed; exact ALLOW for attempt `0668e7d55afd7f50c9d93fee58ee4206` was used once. Terminal UNKNOWN / OBSERVATION_UNAVAILABLE; result SHA-256 `25ef7f1d2cf9e84e2477065fb95033f81e6ccf43668d0e7d5122964a6c5c6cf9`. No current facts or failure diagnostic retained; GitHub/Git/helper/permission counts UNKNOWN; dry-run/tag/CI zero. Offline digests and lifecycle reconcile; no retry. See `175-126-SUMMARY.md`.
- [x] 175-127-PLAN.md — Wave31 complete after one exact ALLOW read. Plan127 branch: ALLOW/UNKNOWN. Plan127 result SHA-256: a42e080c2017f588a2edd58e0fd5b0da76799ae9bded58f88a55eb67bdf6725f. No current facts were retained; the safe diagnostic identified the Elixir decoder rejecting the Node current-read result shape. The decoder mismatch is repaired and fake-tested; 32 focused tests, warnings-as-errors compile, formatter, and scoped diff check passed. No retry or release write occurred. See `175-127-SUMMARY.md`.
- [x] 175-128-PLAN.md — Wave32 complete: one approved read ended ALLOW/UNKNOWN with no current facts, result SHA-256 `f05e2d876f140f29b3258da0f7c02cdb3705b056e1b18c29fdef24b1d7fc795f`. A no-network reproduction found and fixed macOS `wc -l` space padding in subtree progress; the 101-test Node suite and pinned local split passed. The attempt and approval are spent. See `175-128-SUMMARY.md`.

**Wave33** *(depends on completed Plan128/Wave32; Plan106 stays HELD)*

- [x] 175-129-PLAN.md — COMPLETE ALLOW/OBSERVED: one fresh displayed approval consumed once for attempt `2ebc63f2e26c895f253bd8b0e37daaf4`; result `58777a251eb80e3bd9a532def80687ee02820a7b3a9343de8bebf70e189cae86` independently verified. Counts 7 GitHub/16 Git/1 helper/2 permission; zero dry-run/tag/CI. Source/mirror identities and ADMIN access observed; candidate version and tag policy UNKNOWN. No release authority; see `175-129-SUMMARY.md`.

**Wave34** *(depends on completed Plan129/Wave33; local-only; Plan106 stays HELD)*

- [x] 175-130-PLAN.md — COMPLETE LOCAL SAFE STOP: exact Plan129 canonical digest/counts/tuple and the named no-network production case passed; both local tasks and all five prescribed checks complete. Version and effective tag policy remain UNKNOWN; no distinct local defect demonstrated. No GSD command eligible until new independent exact-candidate version/policy evidence or a failing no-network defect reproduction. No new scope, external operation, or authority; see `175-130-SUMMARY.md`.

- [ ] 175-106-PLAN.md — HELD in Wave24 despite appearing mechanically runnable in the plan index: its prerequisite is pinned to Plan119's terminal UNKNOWN attempt, and Plan121 cannot satisfy it. Any later tag path requires a separate plan and exact tag ALLOW; REL-17 remains a hard release stop.

**Wave 35** *(COMPLETE LOCAL REPAIR; completed dependency Plan130 / Wave34; no release authority)*

- [x] 175-131-PLAN.md — COMPLETE LOCAL REPAIR: explicit v2 authenticated mirror-ruleset scope, verified identity/write-role prerequisites, immutable card/approval/result binding, legacy scope isolation, and no-network production seam passed. Node 114; affected ExUnit 72 (37 focused); all six full-suite failures reconciled and rerun green. No real attempt/card, external read, or release authority. Candidate version/effective tag policy UNKNOWN; Plan106/46–48/89 HELD; see `175-131-SUMMARY.md`.

**Wave 36** *(planned and verified; depends only on completed Plan131 / Wave35; Plan106 stays HELD)*

- [x] 175-132-PLAN.md — HALTED at local decision recording: Task1 fake gates and fresh card passed; Task2 user ALLOW received; caller collector-digest typo rejected before authorization/read. Reservation-only PENDING evidence, zero access; do not retry. See 175-132-SUMMARY.md.
- [x] 175-133-PLAN.md — COMPLETE LOCAL REPAIR: exact-target inapplicability ordering, two RED/GREEN cases,117 Node/37 ExUnit passing,418 historical artifacts unchanged; no external authority.
- [x] 175-134-PLAN.md — COMPLETE LOCAL CONTRACT/Wave37: exact-head root metadata scope and production tracer passed; CR-01 fixed and independently reviewed;122 Node/39 ExUnit green,421 historical artifacts unchanged. No real preparation/access or release authority.

**Wave 38** *(complete; one ALLOW/OBSERVED exact-head metadata read; all release holds retained)*

- [x] 175-135-PLAN.md — One approved v3 exact-head read audited OBSERVED: version 0.2.7 and complete CREATE_ONLY_ALLOWED policy snapshot; 8 GitHub/16 Git/1 helper/2 permission operations, zero side effects. No release authority.

**Wave 39** *(complete; local-only; depends on completed Plan135/Wave38; Plan106 stays HELD)*

- [x] 175-136-PLAN.md — COMPLETE LOCAL CONTRACT: exact-head root-manifest provenance, complete authenticated policy/permission and same-credential one-ref dry-run through synthetic Mix/Elixir/Node proof; 36 Node and 16 ExUnit required regressions plus all-five-file historical integrity gate passed, followed by 158 Node and 55 ExUnit tests. No real attempt/access or release authority.

**Wave 40** *(complete; one fresh exact-head preflight; all release holds retained)*

- [x] 175-137-PLAN.md — Completed one exact-head production preflight after the complete card and one-use allow. The production inspector and independent offline terminal audit passed; the receipt is UNKNOWN / OBSERVATION_UNAVAILABLE at TAG_DRY_RUN / POLICY / POLICY_MISMATCH, with 16 public requests, 19 Git operations, one helper check, three permission checks, one dry-run, and zero tag/CI. Attempt `6cc49f9e1427613969cee5a64721dbd9` is consumed; no readiness or release authority.

**Wave 41** *(complete; local-only diagnostic classification repair; no new observation)*

- [x] 175-138-PLAN.md — A recognized expected dry-run row with a malformed envelope now reports SHAPE/INVALID_SHAPE. Fake-process regressions prove rejection/readiness remain fail-closed and nonzero process errors retain PROCESS_EXIT_NONZERO. Focused Node cases and syntax/whitespace checks passed; no new observation or release authority. See `175-138-SUMMARY.md`.

**Wave 42** *(complete; local-only parser repair; no new observation)*

- [x] 175-139-PLAN.md — A local bare Git preview showed a `To` banner, the expected new-tag row, then the standard final `Done` line. The collector now accepts that exact optional trailer and still rejects unrelated lines, duplicate trailers, and blank lines. Seven focused fake-process cases, syntax checks, and scoped whitespace checks passed. This likely explains Plan137's rejected preview, but its original output was not saved, so the exact match cannot be confirmed. No remote or release action occurred. See `175-139-SUMMARY.md`.

**Wave 43** *(complete; fresh exact-head preflight ready; no release authority)*

- [x] 175-140-PLAN.md — The fresh card received a new plain `allow`, bound to attempt `9438fec143ddb1beda7168e002b2a12f`; the bounded exact-head preflight ran once. Production inspection and two independent offline audits passed. PR #219 is open at manifest version 0.2.7; the iOS mirror target tag is absent; policy is complete/create-only; the exact object/ref no-write preview accepted one row. Counts: 16 public requests, 19 Git operations, one helper check, three permission checks, one dry-run, zero tag/CI. Result digest `fa0292420accd879a1b108db560f17eced8416528195432adf650421826262e2`. No tag authority follows; Plan106 and Plans46–48/89 stay held. See `175-140-SUMMARY.md`.

**Wave 44** *(halted before authorization; no external operation)*

- [ ] 175-141-PLAN.md — The PENDING card and lifecycle remain preserved; the user's reply was not bound to this attempt. No external operation occurred. Do not reuse that reply.

**Wave 45** *(complete; local tag-apply implementation and verification; no live operation)*

- [x] 175-142-PLAN.md — Added and verified the local Mix/Elixir/Node authorization, durable-intent, bounded-apply, uncertain-delivery, and independent-inspection path. Plan142 ExUnit: 7 passed; Node: 4 passed; Plan141 regressions: 3 passed; syntax, formatting, and whitespace checks passed. All cases used temporary roots and injected adapters. No card, attempt, credential, provider, remote Git, tag, CI, or release action occurred. See `175-142-SUMMARY.md`.

**Wave 46** *(Plan143 complete; terminal UNKNOWN before durable write intent; no release action)*

- [x] 175-143-PLAN.md — Completed with a terminal UNKNOWN result. The fresh ALLOW was consumed once. The production runner persisted no durable write intent or readback, and stopped before its push call; operation counts and current target state remain unknown. Production terminal inspection and independent offline digest/lifecycle/privacy audits passed. No retry and no release gate advance. See `175-143-SUMMARY.md`.

**Current handoff (Plan145 fresh card):** Last completed phase: 174. Phase175 remains incomplete and release-blocked. Plan144 local repair is complete: seven Node and fourteen Elixir tests passed. Plan145/GSD Wave6 Task1 is complete; fresh attempt `a1a99d16fcafae287fdd85d0a3804259` is PENDING with only a local reservation and zero operations. Its full card is ready for display. Next: receive a fresh plain allow/hold for this card, then resume Task2/Task3 only. Exact continuation command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 6`. Do not prepare another card or reuse Plan143 approval. All other release holds remain. No staging, commits or worktrees.

**GSD Wave5**
- [x] 175-144-PLAN.md — Local production credential repair, complete.

**GSD Wave6**
- [ ] 175-145-PLAN.md — Fresh card using the repaired runner.


**Superseded GSD handoff (Plan136 planned and verified; local Wave39 next):** Last completed phase: 174. Latest completed numbered plan: Plan135/Wave38, ALLOW/OBSERVED. Plan136 is planned and independently verified with zero current findings after one revision (one blocker and two warnings resolved). One autonomous local-only plan, two sequential tasks, depends on completed Plan135 and runs alone in Wave39. Current source has a concrete contract gap: the existing ready-preflight v2 derives candidate version from the mutable PR title, while Plan135 proves exact-head manifest version 0.2.7 and complete tag-policy facts under a zero-dry-run metadata-read scope. Plan136 adds a distinct v3 preflight contract and synthetic Mix/Elixir/Node tracer for exact-head manifest provenance, complete authenticated policy/permission and one same-credential create-only single-ref dry-run. No real attempt/card/reservation, authorization, credential/helper/provider/remote-Git access, dry-run, tag, CI, merge, registry or publication occurs in this plan. Its local synthetic receipt cannot satisfy Plan106’s Plan119-pinned precondition or authorize a tag. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 39`**, selecting only Plan136; no repeat of discussion, planning or Wave38, and no execution of held plans. The 52-case required regression roster (36 Node,16 ExUnit), all-five-file Plan135 integrity gate, exact symbol/schema/path inventory, frontmatter/structure and all five failure-direction checks passed plan review. Parent parsed all four Python verification commands and checked the report parser against ten synthetic outcomes; the application suites have not run for this plan. Coverage passed 10/10 requirements,56/56 decisions and66/66 combined items. Compound-command path probes are not_applicable and supply no path-resolvability claim. Research was skipped as requested; its existing context-drift warning remains advisory. Plan135’s sealed result `bfd109757f08e7fda44e106b17b62b963aba3bb3b75b0be9d7810b2aacba463c` and all five sealed raw files remain unchanged; its attempt/ALLOW are consumed. A later live preflight needs a separately reviewed plan, full fresh card and one-use plain allow/hold, followed by independent terminal audit; any tag decision is later and distinct. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE/RELEASE-BLOCKED,115/121 summarized, with five held plans plus unexecuted Plan136. Phase verification/completion and human UAT remain ineligible. Parked adopter work and capability/support truth remain unchanged. No stage/commit/branch switch/worktree under phase overrides.

**Superseded GSD handoff (Plan135 complete; audited facts support bounded follow-up planning):** Last completed phase: 174. Latest completed numbered plan: Plan135/Wave38, ALLOW/OBSERVED, 3/3 tasks complete. The one-use plain `allow` was bound internally to the unchanged displayed attempt `0bb956299110958d644df7ff4e53ca9f` and consumed by exactly one production metadata read. Sealed result SHA-256 `bfd109757f08e7fda44e106b17b62b963aba3bb3b75b0be9d7810b2aacba463c` passed both prescribed terminal audits and independent Python digest/lifecycle/history checks. At `2026-10-10T18:54:25.205331Z`, PR219 is OPEN/non-draft/unmerged; the exact-head root manifest establishes candidate version `0.2.7` with matching head/tree/blob provenance. The source package split equals mirror main and prior v0.2.5; target v0.2.6 is ABSENT; refs were stable. Observed access projects ADMIN/permission TRUE and policy complete=true/tag_policy CREATE_ONLY_ALLOWED; this is a dated snapshot, not effective write or release authority. Actual counts: 8 GitHub GETs, 16 Git operations, 1 helper check, 2 permission checks; zero dry-run/tag/CI. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, limited to reconciling these materially new audited facts with Plan106’s unmet Plan119-pinned PREFLIGHT_READY, fresh effective permission/policy, exact one-ref dry-run and distinct tag decision, plus remaining held release prerequisites. Do not repeat discussion or Wave38, reserve/retry another read, reuse its consumed ALLOW, or execute held plans. Any later external action requires its own reviewed scope and applicable fresh choice. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE, 115/120 summarized; five held incomplete plans remain, so phase verification/completion and human UAT are ineligible. All five reviewed source files and 610 prior phase files outside the active lifecycle were unchanged before parent tracking. No stage/commit/branch switch/worktree under phase overrides.

**Superseded GSD handoff (Plan135 fresh decision checkpoint):** Last completed phase: 174. Latest completed numbered plan: Plan134/Wave37. Plan135/Wave38 Task1 is complete and independently audited. Attempt `0bb956299110958d644df7ff4e53ca9f` is PENDING/reservation-only with zero operation counts, no authorization/result/read intent, and no current facts. The complete generated v3 card was displayed, with scope SHA-256 `cc98cd9457fb26a3dd1597a672bf565420fb87834e4046995f10cbd1eae9575b`, raw-card SHA-256 `9ef1ed2062b594b7d64f338c48882fd80a5c910bdb2258c77f8d2a049b9f3546` and collector SHA-256 `965a115d6c0914844d057248b3f2acac0c89ec863e85d2d77973b6851d9b8ff5`. Task2 awaits fresh plain allow/hold for that exact display. **Exact next GSD command after the choice, if a fresh session is needed: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 38`**, resume Plan135 at Task2/Task3 only; never repeat Task1 or preparation. Derive all bindings from the actual inspector and compare with the display; never manual digest transcription or inherited Plan132 approval. HOLD seals zero access; ALLOW permits one bounded production read and offline terminal audits. No retry or release operation is authorized. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; candidate version UNKNOWN. Phase175 IN PROGRESS/INCOMPLETE,114/120 summarized; no phase verification/completion or human UAT. No stage/commit/worktree by phase overrides.

**Superseded GSD handoff (Plan135 planned and verified):** Last completed phase: 174. Latest completed numbered plan: Plan134/Wave37. Plan135 is independently verified with zero findings; all10 requirements,56 decisions and66 combined coverage items passed. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 38`**, selecting only Plan135. Task1 creates one fresh v3 local reservation, independently inspects it and displays the complete card. Task2 requires fresh plain allow/hold for that display; Task3 derives bindings from the inspector and seals HOLD with zero access or invokes one bounded read on ALLOW. No prior decision transfers, no retries, and no source or release operation is included. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; candidate version UNKNOWN. Phase175 IN PROGRESS/INCOMPLETE,114/120 summarized including original132 halted; no phase verification/completion or human UAT. No stage/commit/worktree by phase overrides.

**Superseded GSD handoff (Plan134 complete; fresh metadata observation next):** Last completed phase: 174. Latest completed numbered plan: Plan134/Wave37, COMPLETE LOCAL CONTRACT. CR-01 was reproduced RED through the production process seam and repaired; 122 Node and39 focused ExUnit tests passed, independent fix review has zero remaining blockers, parent compile and421 historical-artifact integrity checks passed. Candidate version remains UNKNOWN until a new exact-head metadata observation. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, limited to additive Plan135: one fresh v3 metadata-read reservation, full-card display and independent inspection, one-use plain allow/hold gate, and one bounded read/terminal audit only after ALLOW. The spent Plan132 approval cannot transfer. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE,114/119 summarized; no phase verification/completion or human UAT. No stage/commit/worktree by phase overrides.

**Superseded GSD handoff (Plan134 planned and verified):** Last completed phase: 174. Latest completed numbered plan: Plan133/Wave36. Plan134 is planned and independently verified with zero findings; two local-only tasks in Wave37 depend on completed133. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 37`**, selecting only Plan134. Implement the distinct v3 exact-head root-manifest read contract and injected Elixir-to-Node proof, preserving v1/v2 scopes/cards/results/auth/caps. No real attempt/card/reservation/access, stage/commit/worktree or release operation is authorized. Future access needs a separately reviewed full card and fresh one-use allow/hold. Coverage passed all10 requirements,56 decisions and66 combined items. Plan132 is consumed and original safe stop preserved. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; candidate version UNKNOWN. Phase175 IN PROGRESS/INCOMPLETE,113/119 summarized including original132 halted; no phase verification/completion or human UAT.

**Superseded GSD handoff (Plan133 complete; candidate-version contract next):** Last completed phase: 174. Latest completed numbered plan: Plan133/Wave36, COMPLETE LOCAL REPAIR. Both reproduced cases went RED to GREEN; 117 Node and 37 focused ExUnit tests, syntax and whitespace checks passed. The parent independently checked build/syntax, reran the Node suite, and confirmed all 418 historical artifacts unchanged. Plan132 recovery remains consumed OBSERVED and immutable. Current candidate version is still UNKNOWN: the existing reader derives it from the PR title and has no exact-head release-metadata route. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, limited to an additive versioned exact-head release-metadata read contract with injected no-network proof. Any later external read needs a fresh reviewed card and one-use choice. No repeat of discussion, completed Plan133, spent Plan132 or held release plans. All release holds remain: Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE, 113/118 summarized including original132 halted; no phase verification/completion or human UAT. See175-133-SUMMARY.md and175-POST-133-UNBLOCK.md. No stage/commit/worktree by phase configuration.

**Superseded GSD handoff (Plan133 planned and verified):** Last completed phase: 174. Latest completed numbered plan: Plan131/Wave35; Plan132 same-attempt recovery is independently audited OBSERVED and consumed. Plan133 is planned and independently verified after one release-posture guard revision. Its two local-only tasks depend on completed Plan131; runtime DAG places the additive repair in Wave36. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 36`**, selecting only new Plan133, with Plan132 skipped as summarized and never replayed. No real attempt, approval, credential/provider/remote Git, dry-run/tag/CI/merge/publication action is permitted. Known disabled and exact-target-excluded nonempty tag restrictions will be repaired through injected red/green regressions; applicable and unrecognized policy stays fail closed. All 10 requirements and 56 decisions retain phase-plan coverage, with zero checker findings; local tests do not close release requirements. Candidate version and effective tag policy remain UNKNOWN; Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE, 112/118 summarized (Plan132 original halted); no phase verification/completion or human UAT. No stage/commit/worktree under phase configuration.

**Superseded GSD handoff (Plan132 recovery and local defect reproduction):** Last completed phase: 174. Latest completed numbered plan: Plan131/Wave35. Plan132 original local stop is preserved; its user-directed same-attempt recovery now has an independently audited ALLOW/OBSERVED result, SHA-256 `9c925042f1f41e627f46734538c3bbd09fc9500a059055bc2025b97d4f34e28e`, with 7 GitHub/16 Git/1 helper/2 permission operations and zero dry-run/tag/CI. The exact attempt and ALLOW are consumed. Version remains UNKNOWN and effective tag policy UNKNOWN/incomplete; no write or release authority follows. A new source-bound no-network probe reproduces two inapplicability-ordering failures (disabled tag rules and explicit target exclusion), reopening bounded local-only planning. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, limited to that reproduced local classifier defect. Do not repeat discussion, Wave36, preparation, or the consumed read. Candidate-version acquisition and broader applicable rule effects remain separately scoped follow-ups. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Phase175 IN PROGRESS/INCOMPLETE; no phase verification/completion or human UAT. See `175-132-RECOVERY-SUMMARY.md`, `175-POST-132-UNBLOCK.md`, and the local probe. No staging/commit under `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan132 local decision safe stop):** Last completed phase: 174. Latest completed plan: Plan131/Wave35. Latest summarized plan: Plan132/Wave36, HALTED at local decision recording; Task1 and Task2 completed, Task3 read did not run. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. The required no-network gates passed (114 Node and 37 focused ExUnit tests), and one fresh v2 authenticated-policy card was displayed. The user replied `allow` for attempt `d9364591d7faf4a6f9fa70b634bd6c2a`; the sole decision command then supplied a mistyped collector digest and was rejected before authorization. This is an execution input error, not a demonstrated collector or provider defect. No credential/helper, provider, remote Git, dry run, tag, or CI operation occurred. The preserved files remain PENDING/reservation-only with zero counts; authorization/result are absent. Independent canonical-digest, exact-schema, cap/count, raw-card/collector-binding, and structured-privacy audits of the reservation passed. Terminal result audits are inapplicable and are not claimed passed. Disposition UNKNOWN/UNVERIFIED; no current facts acquired. **No GSD command is eligible now.** Do not repeat Wave36, record another decision, run this attempt, prepare another scope under Plan132, or transfer the displayed ALLOW. Reopen only when new evidence supports a materially distinct bounded observation path or a specific failing no-network reproduction establishes a local defect; any later acquisition needs a separately reviewed plan, fresh displayed card, and its own one-use choice. No human verification/UAT is pending. Candidate version and effective tag policy remain UNKNOWN; Plan129 cause remains unproven and its attempt/ALLOW stay spent. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Five held incomplete plans remain, so phase verification/completion is ineligible. No staging or commit under `phase_commit_docs.175=false`. See `175-132-SUMMARY.md` and its exact attempt-derived reservation artifacts.

**Superseded GSD handoff (Plan132 Task2 decision checkpoint):** Last completed phase: 174. Latest completed plan: Plan131/Wave35. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. Plan132/Wave36 Task1 is complete: 114 Node tests and 37 focused ExUnit tests passed before one fresh v2 authenticated-policy reservation. Same-attempt source inspection and independent Task1 checks passed. Attempt `d9364591d7faf4a6f9fa70b634bd6c2a` is PENDING with one reservation, zero operation counts, no authorization/result/read intent, and no current facts. The complete generated card was displayed; Task2 awaits its one-use plain-language `allow` or `hold`, bound internally to this attempt and its scope/card/collector digests. No copied hashes or inherited approval. **Exact next GSD command after the choice, if a fresh session is needed: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 36` — resume Plan132 at Task2/Task3; never repeat Task1 or prepare another attempt.** Scope SHA-256 `39f9bd7c81e1d18ca078dee5af736a9ba0978b6fc9e5d3938428a8964897631b`; raw card SHA-256 `bb3c336e5b5c9ac74f26d17f344083bb58bbd84515af73f62c79c4af2cf4a221`; collector SHA-256 `03440406756419807a98c3adf6e44a370615c5e549693d9058546eefd73a1d2c`. Evidence prefix: `evidence/175-plan131-d9364591d7faf4a6f9fa70b634bd6c2a-policy-read-`. Plan129 attempt/ALLOW remain spent. Candidate version and effective tag policy remain UNKNOWN. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Plan132 is incomplete and phase verification/completion is ineligible. No staging or commit under `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan132 planned and verified; Wave36 next):** Last completed phase: 174. Latest completed plan: Plan131/Wave35, COMPLETE LOCAL REPAIR. Plan132 is planned and independently verified after one bounded audit revision: three sequential tasks in Wave36 depend only on completed Plan131. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 36`.** Execute only Plan132/Wave36: run the existing no-network fake gates, prepare and inspect one fresh v2 authenticated-policy scope/card, then accept a plain-language allow or hold for the complete just-displayed card and bind it internally to that attempt/scope/card/collector. HOLD means zero access; ALLOW permits at most one bounded current-facts read followed by independent offline canonical-digest, exact-schema, lifecycle, count, and privacy audits. No copied hashes, inherited approval, or retry after consumption/uncertainty. The read grants no tag or release authority. Planning created no real attempt/card/reservation/authorization/result, external access, execution summary, or product code change. Candidate version acquisition remains a separate UNKNOWN question; effective tag policy remains UNKNOWN. Plan129 cause stays unproven and its attempt/ALLOW stay spent. Plan106 and Plans46–48/89 remain HELD, including Plan106’s Plan119-pinned prerequisites and separate tag decision. REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Five held incomplete plans plus unexecuted Plan132 remain, so phase verification/completion is ineligible. Do not repeat discussion, planning, or Wave35, execute held plans, or acquire version facts under this plan. Frontmatter/structure and seven failure directions passed; independent review has zero remaining issues; coverage passed 10/10 requirements, 56/56 decisions, and all 66 post-planning items. Research was skipped as requested; stale research/older validation remain historical. All 494 prior plan/summary/evidence files stayed byte-identical. No staging or commit under `phase_commit_docs.175=false`. See `175-132-PLAN.md` and `175-132-PLAN-CHECK.md`.

**Superseded GSD handoff (Plan131 complete; local repair):** Last completed phase: 174. Latest completed plan: Plan131/Wave35, COMPLETE LOCAL REPAIR. Both autonomous tasks passed: the distinct v2 authenticated mirror-ruleset scope, exact card/approval/result binding, verified identity/write-role prerequisite, legacy anonymous-policy compatibility, and real Elixir-to-Node seam are covered by no-network fakes. Node passed 114 tests; the 37 focused ExUnit cases passed within a 72-test affected-module rerun. The full offline Mix run executed 2,370 tests and found six integration failures; all six passed after bounded ledger, lifecycle-cardinality, state-breadcrumb, and planning-whitespace reconciliation. Warnings-as-errors compilation, the 255-site assertion inventory, format/syntax, and global whitespace checks passed. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, confined to a separately reviewed fresh authenticated-policy read scope/card using the repaired collector. This is planning eligibility only: any later external read needs a fresh displayed card and a new one-use plain-language allow/hold bound internally. No real scope/card/attempt, authorization, credential lookup, provider/remote-Git access, dry run, tag, CI, merge, registry, or release operation occurred. Candidate version and effective tag policy remain UNKNOWN; Plan129’s live cause remains unproven and its attempt/ALLOW remain spent. Plan106 and Plans46–48/89 remain HELD; Plan106’s Plan119-pinned prerequisites and separate tag decision remain unmet. REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. The live index is 111/116 complete with five held incomplete plans, so phase verification/completion is ineligible. Do not repeat discussion or Wave35, execute held plans, or acquire version facts under this repair. All 493 pre-existing plan/summary/evidence files stayed byte-identical. No staging or commit under `phase_commit_docs.175=false`. See `175-131-SUMMARY.md`.

**Superseded GSD handoff (Plan131 planned and verified):** Last completed phase: 174. Latest completed plan: Plan130/Wave34, LOCAL SAFE STOP. Plan131 is planned and independently verified for Wave35, with two autonomous local-only tasks depending on completed Plan130. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 35`.** Execute only Plan131/Wave35: introduce an explicit versioned authenticated ruleset-read scope with fixed mirror routes and verified identity/write-role prerequisites, preserve old-scope authentication semantics, and prove the real Elixir-to-Node approval/result seam using injected no-network fakes. Do not prepare a real scope/card/attempt or acquire current facts. Missing bypass fields and unsupported policy stay UNKNOWN; candidate version acquisition is outside this repair. The synthetic reproduction does not establish Plan129's live cause. Plan129's attempt and ALLOW remain spent; no authority transfers. Plan106 and Plans46–48/89 remain HELD; its Plan119-pinned preconditions remain unmet. REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Any later external read requires separate planning, a fresh displayed scope/card, and a new plain-language allow/hold bound internally. A tag operation keeps its separate complete preflight, effective permission/policy, exact-ref dry-run, and decision gates. Planning created no acquisition, card, reservation, authorization, or execution summary. Plan131 passed independent review, frontmatter/structure and six failure-direction checks; phase coverage passed 10/10 requirements, 56/56 decisions, and the 66-item post-planning gate. Research was skipped as requested; prior research/validation are historical. All 471 prior plan/summary/evidence files stayed byte-identical. Five held incomplete plans plus unexecuted Plan131 remain, so phase verification/completion is ineligible. No staging or commit under `phase_commit_docs.175=false`. See `175-131-PLAN.md` and `175-131-PLAN-CHECK.md`.

**Superseded GSD handoff (post-Plan130 local reproduction):** Last completed phase: 174. Latest completed plan: Plan130/Wave34, LOCAL SAFE STOP. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. A new source-bound no-network probe reproduced an authenticated-policy acquisition limitation: currentReadHeaders sends ruleset list/detail GETs anonymously, while GitHub documents that bypass_actors requires requester write access. The probe exited 1 with both simulated requests unauthenticated and complete=false; source SHA-256 matches Plan129's collector. This supports a materially distinct, local-only scope repair; it does not prove the cause of Plan129's live result or supply new candidate/policy facts. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, confined to an explicitly reviewed authenticated ruleset-read boundary and fake regressions. Preserve old scope semantics; do not broaden credential disclosure under a spent approval. Candidate version remains UNKNOWN and is a separate question. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. No acquisition, card, reservation, authorization, or release operation was created. A later external read needs a fresh displayed scope and plain-language allow/hold; no current approval transfers. Do not repeat discussion or Wave34, or execute held plans. See `175-POST-130-UNBLOCK.md`; Plan130's summary and all prior evidence remain unchanged. No staging or commit under `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan130 complete; local safe stop):** Last completed phase: 174. Latest completed plan: Plan130, Wave34, LOCAL SAFE STOP; both autonomous tasks and all five prescribed checks passed. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. **No further GSD command is eligible now.** Reopen only after new independent, authentic, machine-verifiable evidence for the exact PR #219 candidate materially changes the version or effective tag-policy question, or a specific local defect is reproduced with a failing no-network command. No distinct local defect was demonstrated; do not repeat discussion, planning, Wave34, or an identical acquisition. Plan129's terminal OBSERVED result SHA-256 `58777a251eb80e3bd9a532def80687ee02820a7b3a9343de8bebf70e189cae86` was recomputed and its exact counts/tuple checked; attempt `2ebc63f2e26c895f253bd8b0e37daaf4` and ALLOW remain spent. Version and effective tag policy remain UNKNOWN; ADMIN access grants no effective write authority. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Five incomplete held plans remain, so phase verification/completion is ineligible. Any later external read needs a separately reviewed scope, fresh displayed card, and new plain-language allow/hold bound internally; a tag operation requires complete current preflight, effective policy/permission, exact one-ref dry-run, and its own separate decision. Zero new external operations or attempts. No staging or commit because `phase_commit_docs.175=false`. See `175-130-SUMMARY.md`.

**Superseded GSD handoff (Plan130 planned and verified):** Last completed phase: 174. Latest completed plan: Plan129, Wave33, ALLOW/OBSERVED. Plan130 is planned and independently verified for Wave34, with two autonomous local-only tasks and dependency on completed Plan129. Phase175 remains IN PROGRESS and INCOMPLETE / RELEASE-BLOCKED. **Exact next GSD command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 34`.** Execute only Plan130/Wave34: recompute the sealed Plan129 result digest, trace the version and policy UNKNOWN predicates through current source, compare Plan106 prerequisites, and record the ordinary summary with a safe stop or distinct reproduced local-defect disposition. Planning performed no acquisition and created no attempt, card, authorization, or execution summary. Plan129 attempt `2ebc63f2e26c895f253bd8b0e37daaf4` and its ALLOW remain spent; its result SHA-256 is `58777a251eb80e3bd9a532def80687ee02820a7b3a9343de8bebf70e189cae86`. Observed version remains UNKNOWN and tag policy UNKNOWN/incomplete; ADMIN access is not effective write authority. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. The generic index may call Plan106 runnable, but its semantic preconditions and separate tag decision are absent. Five held incomplete plans plus unexecuted Plan130 remain; no phase-level verification/completion is eligible. Research was skipped as requested; its stale-artifact advisory was surfaced. Plan130 passed independent review after one bounded revision, frontmatter/structure/failure-direction checks, 10/10 requirement coverage, 56/56 decision coverage, and the 66-item post-planning coverage gate. No staging or commit because `phase_commit_docs.175=false`. See `175-130-PLAN.md` and `175-130-PLAN-CHECK.md`.

**Superseded GSD handoff (Plan129 complete):** Last completed phase: 174. Latest completed plan: Plan129, Wave33, ALLOW/OBSERVED. Phase175 remains IN PROGRESS and INCOMPLETE. The user's one-use `allow` was bound to attempt `2ebc63f2e26c895f253bd8b0e37daaf4` and its displayed scope/raw-card/collector digests, then consumed by exactly one bounded current read. Result SHA-256 `58777a251eb80e3bd9a532def80687ee02820a7b3a9343de8bebf70e189cae86` passed independent canonical-digest, exact schema/lifecycle/count, binding, and structured-privacy checks. Counts: 7 GitHub GETs, 16 Git operations, 1 helper check, 2 permission checks; dry-run/tag/CI counts all zero. Source package split equals mirror main and prior v0.2.5; target v0.2.6 is ABSENT. PR219 is open/non-draft/unmerged at the matching base/head/tree; observed version UNKNOWN. Observed authenticated access projects ADMIN/permission TRUE; policy complete=false and tag_policy UNKNOWN. Those observations grant no write or release authorization. **Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`**, scoped to evaluating these verified facts and remaining unknown prerequisites in a separately reviewed follow-up. Do not repeat discussion or Wave33, prepare another scope, retry this read, or reuse its ALLOW. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Five incomplete held plans remain, so phase verification/completion is ineligible. No staging or commit because `phase_commit_docs.175=false`. See `175-129-SUMMARY.md`.

**Superseded GSD handoff (Plan129 Task2 decision checkpoint):** Last completed phase: 174. Latest completed plan: Plan128, Wave32. Phase175 remains IN PROGRESS and INCOMPLETE. Plan129 Wave33 Task1 completed: 101 Node tests and 32 focused ExUnit tests passed, with Node syntax, named Elixir format, scoped diff, exact PENDING inspector, unchanged source digests, and canonical scope/reservation digest checks passing. Exactly one fresh attempt `2ebc63f2e26c895f253bd8b0e37daaf4` is PENDING with a single reservation, zero operation counts, and no authorization, result, read intent, or current facts. Task2 is the blocking-human plain-language `allow` or `hold` choice for the complete displayed card. The coordinator binds that reply internally to this attempt, scope, raw card, and collector; the user copies no hashes. Await this choice before any external operation. **Exact next GSD command after the choice, if a fresh session is needed: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 33` — resume Plan129 at Task2/Task3; never repeat Task1 or prepare another attempt.** Plan128's attempt and approval remain spent. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Artifacts remain uncommitted because `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan128 complete):** Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE; the release hold is active. Plan128 branch: ALLOW/UNKNOWN. Plan128 result SHA-256: f05e2d876f140f29b3258da0f7c02cdb3705b056e1b18c29fdef24b1d7fc795f. The one approved read returned no current facts; its approval and attempt are spent. A no-network reproduction identified the cause of the local subtree split failure: macOS `wc -l` space-pads its count. The parser now accepts only bounded spaces in that field, still rejects malformed output, and retains the exact split checks. Verification passed: 101 Node tests and a local pinned split returned the expected object ID across 3,804 records; no network was used and the temporary checkout was removed. **Next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`** to plan one fresh scope using the repaired parser. Any new read needs a new card and the user's plain-language `allow` or `hold`; the coordinator binds it internally, so no hashes need to be copied. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Planning/evidence remain uncommitted because `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan127 complete; read ended UNKNOWN):** Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE; the release hold is active. Plan127 branch: ALLOW/UNKNOWN. Plan127 result SHA-256: a42e080c2017f588a2edd58e0fd5b0da76799ae9bded58f88a55eb67bdf6725f. The read returned no current facts because the Elixir decoder rejected the Node collector's current-read format. This was repaired locally, and the fake-process regression plus 32-test focused suite, warnings-as-errors compile, formatting, and scoped diff check passed. No retry occurred. **Next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`** to plan a fresh, separately approved observation with the repaired wrapper. This attempt and ALLOW are spent; any new read requires a new exact ALLOW. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Artifacts remain uncommitted because `phase_commit_docs.175=false`.

**Superseded GSD handoff (Plan126 plus local wrapper repair):** Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE, and the release hold is active. Plan126's exact ALLOW for attempt `0668e7d55afd7f50c9d93fee58ee4206` was used once; its result remains UNKNOWN with no facts or diagnostic, SHA-256 `25ef7f1d2cf9e84e2477065fb95033f81e6ccf43668d0e7d5122964a6c5c6cf9`. Do not replay it or reuse its approval. The local wrapper failure is repaired: collector errors, invalid output, and exceptions now retain only a safe allowlisted diagnostic; uncertain read counts stay UNKNOWN and raw failure text is discarded. Fake failure/redaction cases passed; the focused ExUnit file passed 31 tests; warnings-as-errors compile, formatting, and scoped diff checks passed. No external read occurred during the repair. The then-next GSD command was `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`; Plan127 above has completed that planning step. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Planning artifacts remain uncommitted because `phase_commit_docs.175=false`.

**Superseded handoff (Plan124 complete; 2026-10-10):** Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE, with the release hold active. Plan124 completed the new bounded current-read route and fake proof (95 Node and 28 focused ExUnit tests). One fresh PENDING scope/card was prepared and inspected once; attempt `0625d6afa47cef001f1241a2aa9787b8`, scope SHA-256 `cd09cb599c98757511b125f054042b2965057d7c67bb3944476bd1993ade4984`, card SHA-256 `f966fd4017d818ce4e1d241a166874d05fdb77ddf7463caa4391f97beea50c2d`. All use counts are zero, no authorization or read intent exists, and candidate/access/policy facts remain unknown. The exact next GSD command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan Plan125 against this exact card. Plan125 must put the exact-scope ALLOW/HOLD immediately before any provider, credential/helper, or remote-Git operation. HOLD means zero access; ALLOW permits one bounded read with terminal UNKNOWN and no retry on failure or ambiguity. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Planning artifacts remain uncommitted because `phase_commit_docs.175=false`.

After Plan124, the next planning command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` for Plan125 against attempt `0625d6afa47cef001f1241a2aa9787b8`, scope SHA-256 `cd09cb599c98757511b125f054042b2965057d7c67bb3944476bd1993ade4984`, and card SHA-256 `f966fd4017d818ce4e1d241a166874d05fdb77ddf7463caa4391f97beea50c2d`. Plan125 must gate any fresh current-facts access behind its exact-scope ALLOW/HOLD.

**Superseded GSD handoff (Plan121 terminal; 2026-10-09):** Plan121's one-use ALLOW and attempt are spent; the terminal read did not reveal its stderr content and established no current release facts. The newly recorded local reproduction supports the bounded Plan122 repair above. Never replay Plan121 or its authorization.

**Superseded GSD handoff (Plans105–108; 2026-10-08):** Last completed phase: 174; Phase175 remains IN PROGRESS and INCOMPLETE. Plan105 Wave13 used its exact read approval once, then stopped before the first complete current-information snapshot. The saved result does not identify which check failed; public-request and Git-operation counts remain UNKNOWN. Permission/helper checks, dry run, and tag attempts were zero. Never retry that attempt or reuse its approval. Plan107 is complete in Wave14. Plan108 completed its local-only Wave15 repair; focused checks passed and the full Mix suite passed with 2,345 tests, zero failures, and 74 expected exclusions. The next GSD command was $gsd-plan-phase 175 --ws quality-ratchet-release --skip-research to scope the next local planning step. Plan106 was Wave16 after Plan108 and remained ineligible until a new, separately planned and approved read completed successfully and produced a fresh ready receipt; any tag write still needed its own exact approval. No tag, CI, merge, registry, or release action occurred. REL-13/14/15/17 remained OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD. See 175-105-SUMMARY.md, 175-107-SUMMARY.md, 175-108-SUMMARY.md, 175-106-PLAN.md, and 175-108-PLAN-CHECK.md.

**Superseded GSD handoff (Plan104 complete; 2026-10-08):** Last completed phase: 174; Phase175 remains INCOMPLETE. Plan104 completed Wave13 with one exact-approved, bounded read. Current facts show the source package split matches mirror `main` and prior tag `v0.2.5`; target mirror tag `v0.2.6` is absent; PR #219 is open, not draft, and not merged, with its base/head/tree matching the historical planning pin. The next GSD command was `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to scope a separate tag-write decision from these facts. This read grants no write permission or tag authority: REL-13/14/15/17 remain OPEN; readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 remain HELD. Keep REL-17 as an independent release stop. See `175-104-SUMMARY.md`.

**Superseded GSD handoff (Plans98–99 complete; 2026-10-07):** Last completed phase: 174; Phase175 remains INCOMPLETE. Plan98 used one approved anonymous read (six API requests, seven Git spawns). It found source tag ios-core-v0.2.6 at 998742856a37a97ae7247f6c532f9c154ea20885, mirror tag v0.2.6 absent, and PR #219 open with its recorded base/head/tree matching the comparison pin. The collector stopped because it cloned without checking out files before git subtree split. A disposable local clone of that exact commit succeeded after checkout: split 424ab96ede1b92f2b751b54bce04c6e607f0f3c8, equal to mirror main and v0.2.5; tree b80f3bf00ef61708120b062bc88738fed88294a9, equal to the source iOS package tree. Plan99 fixed the collector and diagnostic allowlist; Node 21 and Elixir 11 tests passed. The Plan98 terminal preflight remains BLOCKED and unchanged. No second public read, CI, credential lookup, tag write, merge, or release action occurred. Write permission remains UNKNOWN, tag authority NONE, readiness BLOCKED, and the release hold ACTIVE. The exact next command is $gsd-plan-phase 175 --ws quality-ratchet-release --skip-research to plan the next Phase175 gap closure from these facts. Any future public read requires a new exact scope and approval. See 175-98-SUMMARY.md, 175-99-PLAN.md, and 175-99-SUMMARY.md.

**Superseded Plan93 handoff (2026-10-07):** Plan93 Task3 closed attempt `480db51798d676a00645f29822d951c9` as terminal `READ_NOT_ALLOWED` because the reply `allow` omitted required bindings. Inspection confirmed zero requests, zero read intent, zero invocations, empty parent/child journals, and unchanged prior evidence. Do not repeat Plan93 or reuse its attempt or Plan88/92 authority.

**Superseded GSD handoff (Plan91 complete, 2026-10-07):** Last completed phase: 174; Phase175 remains INCOMPLETE. Plan91 completed in six task-scoped fake-only commits, and Wave2 has no incomplete plans. The phase index still lists the old Plan88 scope as ready/runnable, but its ALLOW is invalid under the changed contract. Do not replay Plan88 or execute Plan89; Plan92 is the only selected plan in computed Wave3. The then-next action was to plan a fresh exclusive read scope/evidence path set; Plan92 above now governs. Any future read requires a new exact ALLOW after planning. REL-13/14/15/17 remain OPEN, readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, Plans45–48 HELD.

**Superseded GSD handoff (Plan88 request-accounting blocker, 2026-10-07):** Last completed phase: 174. Plans87 and 90 are complete; Phase175 remains incomplete. Plan88 Task1 is complete and must not be rerun. It created and offline-validated a PENDING scope at `evidence/175-plan87-tag-026-read-scope.json` for attempt `ecf4314b02b8e8aeb6fe2cb32a84395a`, scope SHA-256 `6799ddad912956ce5ff5da7242c9930e1b5d8d957f702ca13918a0a5ab8ef571`, contract SHA-256 `0149f870263a113eb9d7446a6a129597444de9e7097554e3224a910f707e13b5`, request_count 0. Its reservation lifecycle binds the same digest. The user returned ALLOW for that exact scope, but Task3 stopped before authorization, credential lookup, or provider/Git access because actual API/Git operation counts cannot be persisted for terminal accounting. No further GSD action was eligible until the user decided whether to plan a separate local evidence-contract repair. The user approved planning and Plan91 above now governs. Do not reuse the existing ALLOW after changing the collector/contract. A later read requires a fresh exact scope and separate exact ALLOW. Plan89 remains gated on complete PREFLIGHT_READY and a separate exact write decision; REL-13/14/15/17 remain OPEN and all release holds active.

**Superseded GSD handoff (Plan86 complete, 2026-10-06):** Plan85 and Plan86 local Wave 1 work are complete; Phase175 remains incomplete. This was superseded when Plans87–89 were separately planned and Plan87's local implementation completed. Do not follow its former no-command direction or repeat Plan85/86.

**Superseded GSD handoff after Plan85 (2026-10-06):** Last completed phase: 174. Plan85 completed both local-only Wave 1 tasks. No next GSD command is eligible. Fresh, independently verifiable current candidate facts, or new evidence supporting a materially distinct bounded observation path, must support a separately scoped plan and its required authorization before work reopens. Do not repeat Plan85 discussion/planning/execution or replay Plan84/Plans81–83. REL-13/14/15/17 remain OPEN; candidate readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE. The index reports Plans46–48 incomplete and no runnable or ready plan. The generic resolver can treat those held summary gaps as resumable; follow this workstream handoff instead of bare `$gsd-progress --next` or `$gsd-execute-phase 175`. Plan84 actual request count/cause stay UNKNOWN. Local proof grants no live preflight, tag/CI choice, Gate2, merge, recovery, registry mutation or publication authority.

**New repair chain — Wave 2** *(Plan72 local proof depends only on completed Plan71; halted Plans44/70 are read-only terminal context)*

- [x] 175-72-PLAN.md — Implement and prove the exact v0.2.6 tag-repair Mix/process/evidence contract locally with deterministic fakes; no remote operation.

**Historical Wave 14** *(Plans51–55 remain terminal and are never replayed)*

Plans 175-49 through 175-55 remain terminal and are never replayable. Plan 175-54's bounded source
attempt ended with a failed split and no later task became eligible. Plan 175-55 ended mid-execution;
its partial implementation is preserved, but it returned no evidence receipt or verification result.
Any CI rerun, further remote collection beyond Plan66's single reviewed exact-head workflow read, or any source/release operation needs a separate fresh plan and applicable exact authority. Plan 175-64 completed a local classifier and one bounded read-only diagnostic; Plan65 completed its fresh read with aggregate proof FALSE and correctly skipped the rerun. Plan66 then completed one exact-head workflow-content read and diagnosed aggregate coverage omissions; its evidence is terminal. Preserve the release hold and all prior evidence.

- [x] 175-49-PLAN.md — BLOCKED / DO NOT RESUME: its receipt remains stale after a failed checkpoint; later diagnostic dry-runs do not provide a fresh full preflight or decision. Its SUMMARY status is machine-marked `halted` so GSD cannot offer a replay.
- [x] 175-50-PLAN.md — BLOCKED / DO NOT RESUME: fresh full preflight stopped because the dry-run did not prove exactly one accepted target ref; do not reuse its digest.
- [x] 175-51-PLAN.md — HALTED: the single preflight invocation returned `RECEIPT_WRITE_FAILED`; no retry, decision, or write. Any further attempt requires a new plan and digest.

**New repair chain — Wave 3** *(Plan73 depends on local Plan72)*

- [x] 175-73-PLAN.md — Repair and locally prove the bounded production read/evidence contract, then use the already-granted one-read scope only with `CROSSWAKE_PLAN73_READ_TOKEN`; otherwise stop before reservation.

**New repair chain — Wave 4** *(Plan74 depends on a validated Plan73 preflight)*

- [x] 175-74-PLAN.md — BLOCKED before tag-write authorization because Plan73 PREFLIGHT_READY inputs are absent; no reservation, Task2, Plan74 evidence, or remote operation. Release requirements remain open and Phase175 incomplete.

**Held legacy release chain — effective Waves 5–8** *(Plan45 remains halted and now depends on Plans74 and 84; the fresh tag-repair plan is only a prerequisite, not release readiness. Plans46–48 remain dependency-blocked.)*

- [x] 175-45-PLAN.md — HALTED before candidate refresh or Gate 2: no validated Plan73 PREFLIGHT_READY exists, Plan74 safely stopped before its write decision, and PR #219 exact-head CI is not passing. Plan84 is now an additional dependency and cannot clear these release gates. No remote read, authorization, merge, or release action occurred; see `175-45-SUMMARY.md`.
- [ ] 175-46-PLAN.md — BLOCKED by halted Plan45; same-run exact-public proof and six-child COMPLETE remain unverified.
- [ ] 175-47-PLAN.md — BLOCKED by halted Plan45 through Plan46; separate companion publication remains held.
- [ ] 175-48-PLAN.md — BLOCKED by halted Plan45 through Plans46–47; phase disposition remains open.

**Rulesets-only repair chain — Wave 5 → Wave 6** *(execute the explicit wave filter so held release plans cannot be selected)*

- [x] 175-75-PLAN.md — Replace the sunset tag-protection route with the already-approved rulesets observation; add offline route, pagination, applicability, evidence-validator, and Plan74-readiness regression checks in the existing test lane. No remote request.
- [x] 175-76-PLAN.md — After Plan75 local proof, used the previously granted one-read scope once. The lifecycle validates a terminal `UNKNOWN_UNVERIFIABLE` stop; no valid preflight facts or release authority were produced. Do not replay; see `175-76-SUMMARY.md`.

**REL-17 gap-closure order:** 175-34 → 175-35 → 175-36 implemented the shared release guard paths;
175-37 prepared the 0.2.6 candidate, and 175-38 ended PARTIAL before publishers. Plan 175-42 now
repairs the future Gate 2 selector and source-envelope binding locally. Plans 175-39..41 are
superseded because their 0.2.6 publication/proof prerequisites are false and their evidence paths
record the PARTIAL incident. Plan a fresh candidate and its distinct authorization before creating
new same-run proof, companion, or closeout plans. `$gsd-execute-phase 175 --gaps-only` selects only
Plan 175-42. Plans 175-49 and 175-50 are preserved blocked attempts and must not resume. A new
bounded preflight plan is required before any later tag decision. No existing token authorizes a
retry, recovery, merge, or publication.

**Research**: Complete — `175-RESEARCH.md` (2026-09-18). The rehearsal-ceiling question is answered by
this repo's own code: `hex-publish.yml` and `ios-mirror-backfill.yml` each already carry a
`candidate-rehearsal` operation, and `release-please.yml`'s `android-publish-fire-drill` performs a real
signed Central Portal upload through `VALIDATED` then `DROP`. No scratch Hex organization is needed and
no new rehearsal tooling is to be built; this phase dispatches the existing mechanisms and records their
evidence.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|-----------------|--------|-----------|
| 164. Dependency Security and Gate Authority | 5/5 | Shipped | 2026-08-28 |
| 165. Efficient and Maintainable CI | 13/13 | Shipped | 2026-09-09 |
| 166. Clean-Checkout Engineering Quality | 8/8 | Shipped | 2026-09-10 |
| 167. Documentation and Pull-Request Reconciliation | 9/9 | Shipped | 2026-09-12 |
| 168. 0.2.1 Release Candidate Readiness | 13/13 | Shipped | 2026-09-16 |
| 169. Diagnostic Legibility | 6/6 | Complete    | 2026-09-25 |
| 170. Vacuous Assertion Remediation | 5/5 | Complete   | 2026-09-16 |
| 171. Version/Authority Split | 5/5 | Complete | 2026-09-17 |
| 172. Per-Package Proof Scope | 3/3 | Complete    | 2026-09-17 |
| 173. Recovery-Path Proof Convergence | 4/4 | Complete    | 2026-09-18 |
| 174. Clean-Room Host Realism & Adopter Fidelity | 7/7 | Complete    | 2026-09-25 |
| 175. Rehearsal and Publish | 119/124 | In Progress |  |
