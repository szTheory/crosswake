# Phase 175: Rehearsal and Publish - Research

**Researched:** 2026-09-18
**Domain:** Multi-registry release execution (Hex, SwiftPM iOS mirror, Maven Central) on top of an
already-repaired, version-generalized release graph
**Confidence:** HIGH

## Summary

This phase does not need to build new rehearsal, retirement, or partial-failure tooling — it needs
to **discover, dispatch, and record evidence from mechanisms that already exist in this repo**, then
execute three irreversible publishes in a specific order. The single biggest finding of this
research: the "rehearsal ceiling" question the ROADMAP flagged as needing research has already been
answered by prior phases' own code. `hex-publish.yml`'s `candidate-rehearsal` operation already
calls `mix hex.publish package --dry-run --yes` **and** `mix hex.build`
[VERIFIED: script/release_candidate/hex_artifacts.sh:206,214]. `ios-mirror-backfill.yml`'s
`candidate-rehearsal` operation already performs `git subtree split` with no push
[VERIFIED: .github/workflows/ios-mirror-backfill.yml:134-154]. `release-please.yml`'s
`android-publish-fire-drill` job already performs a full signed upload to Maven Central's Publisher
API through `VALIDATED` state and then `DROP`s it, freeing the coordinate without ever reaching
`PUBLISHED` (Central's immutability boundary) [VERIFIED: .github/workflows/release-please.yml:996-1161].
None of this is dormant scaffolding — `candidate-rehearsal-hex` and `candidate-rehearsal-ios` are the
exact artifacts `attest-candidate-receipt` already consumes for the canonical candidate receipt used
at 0.2.1. Phase 175's REL-11 work is therefore: dispatch these three existing mechanisms against the
0.2.2 candidate, and file the resulting `rehearsal.json` / fire-drill run evidence in-repo — not
design a new dry-run system.

The second major finding concerns ordering. STATE.md's prior lesson about core-first publishing
(companions failing because they depended on an *unpublished* core version bump) does **not** apply
here: both held companions declare `{:crosswake, "~> 0.2"}` [VERIFIED: packages/crosswake_rulestead/mix.exs:68,
packages/crosswake_chimeway/mix.exs:63], and `crosswake 0.2.1` is already live on Hex
[VERIFIED: `curl https://hex.pm/api/packages/crosswake` → releases include `0.2.1`]. `~> 0.2` is
satisfied by any `0.2.x`, so neither companion needs core 0.2.2 to exist first. The ROADMAP's
"lower-blast-radius companion first, core 0.2.2 next, second companion last" ordering is safe exactly
as written — there is no ordering conflict to surface to the planner on this axis.

The third finding narrows Success Criterion 6/7's scope. `exact-public-proof` in the ordinary release
graph only ever runs for `package: crosswake` [VERIFIED: .github/workflows/release-please.yml:786-793]
— it is not, and was never meant to be, a per-companion proof. `linked-release-rollup`'s `COMPLETE`
state requires all six children (`hex`, `ios_mirror`, `android`, `ios_public_proof`,
`android_public_proof`, `exact_public`) to succeed [VERIFIED: lib/crosswake/release_candidate/workflow.ex:4,27-48]
— this is entirely about the linked `crosswake`/iOS-core/Android-core release, not about either
companion. Success Criterion 7's phrasing ("the second held companion PR is merged and published,
and the linked-release rollup reports COMPLETE") is therefore two independent facts stated together,
not one gate the companion publish triggers — the rollup will already read COMPLETE once 0.2.2's own
graph finishes (Success Criteria 5-6), and merging the second companion afterward doesn't change that
rollup's inputs at all. The planner should verify COMPLETE once, from 0.2.2's own run, and treat the
second companion's Hex-registry check as the independent confirmation SC7 actually needs.

**Primary recommendation:** Structure Phase 175 as (1) a broken-windows triage wave (per STATE.md's
explicit planning guidance) that fixes `check-actions`' hardcoded three-path default before any
publish task runs, (2) a runbook/rehearsal/response-table wave that commits REL-10 and REL-16 and
dispatches the three existing rehearsal mechanisms for REL-11, gated as a hard prerequisite before
any publish step, (3) three publish waves in the ROADMAP's mandated ascending-blast-radius order,
each ending in an independent registry check (not workflow re-inspection), and (4) a DOC-04/DOC-06
documentation wave. Never combine this phase's plans with Phases 169-174.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rehearsal dispatch (Hex/iOS/Maven) | CI / GitHub Actions (`workflow_dispatch`) | — | All three mechanisms are already `workflow_dispatch`-only, trusted-workflow jobs; no application code involved |
| Retire/backfill runbook (REL-10) | Docs (`docs/`) | — | Pure documentation; must exist in git before any publish step runs (locked decision) |
| Partial-failure response table (REL-16) | Docs (`docs/`) | — | Authored ahead of the incident, per the milestone's "derive, don't hardcode" thesis |
| Companion Hex publish (rulestead/chimeway) | CI / GitHub Actions (`publish-hex-rulestead`/`publish-hex-chimeway` jobs) | Hex.pm registry | Triggered by `release-please`'s own tag-created signal; does not touch `approved-release-guard` |
| Core 0.2.2 linked publish (Hex+iOS+Android) | CI / GitHub Actions (`approved-release-guard` → `publish-hex`/`publish-ios-core`/`publish-android-core`) | Hex.pm, SwiftPM mirror repo, Maven Central | Gated on the exact head/tree/base/`approved_version` identity chain built in Phase 171 |
| `exact-public-proof` execution evidence | CI run record (GitHub Actions run ID) + `docs/release-ledger/RELEASE-LEDGER.jsonl` | — | XPUB-06 already makes the durable copy git-committed; REL-14 just needs a real 0.2.2 row |
| Registry-state verification (SC4-6) | External registries (Hex.pm API, GitHub mirror repo, Maven Central repo1) | — | Must be checked independently, never by re-reading workflow YAML (explicit anti-pattern this milestone exists to remove) |

## Standard Stack

This phase installs no new packages and adds no new libraries. It operates entirely through
mechanisms already present in the repo: `mix hex.build`/`mix hex.publish`/`mix hex.retire` (Hex CLI,
part of the `:hex` archive already installed for this project), `git subtree split` (ships with Git),
and the Vanniktech Maven Publish plugin + Sonatype Central Portal Publisher API (already wired in
`packages/crosswake-shell-core-android/build.gradle.kts`).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing existing `candidate-rehearsal`/`android-publish-fire-drill` jobs | Building a new scratch-org / sandbox-registry rehearsal harness | Rejected: the existing mechanisms already exercise the real registries' validation paths (Hex's own dry-run build, Central's own Publisher API through `VALIDATED`) more faithfully than a fake registry could, and building new tooling here directly contradicts this milestone's "don't hand-roll a solved problem" thesis and STACK.md's "almost nothing new should be added to the toolchain" verdict [CITED: .planning/research/v23/SUMMARY.md:27] |
| `git subtree split` for the iOS mirror rehearsal | `splitsh-lite` | Rejected repo-wide already: `splitsh-lite v1.0.1` segfaults in this environment (recorded project decision) and zero live workflow/script file references it anymore [VERIFIED: `grep -rn splitsh .github/ script/ lib/` returns only one unrelated comment in `script/check_ios_mirror_parity.sh:31`] |

**Installation:** None required.

**Version verification:** Not applicable — no new package versions to pin. Existing toolchain
versions are already pinned via `.tool-versions` (`erlang 27.3`, `elixir 1.19.5-otp-27`,
`nodejs 22.14.0`) [VERIFIED: .tool-versions].

## Package Legitimacy Audit

Not applicable. This phase installs no external packages. It publishes six existing, already-audited
packages to registries they are already live on (`crosswake` core is at `0.2.1`; `crosswake_rulestead`
and `crosswake_chimeway` are already at `0.1.0` on Hex.pm — this phase publishes the *next* version of
each, not a new package).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────┐
                    │  Phase 175 plan sequence (this phase)    │
                    └─────────────────────────────────────────┘

  [triage wave]        [runbook/rehearsal wave]         [publish waves, ascending blast radius]
  ┌──────────────┐     ┌───────────────────────┐        ┌──────────────────────────────────────┐
  │ fix           │    │ commit REL-10 runbook │        │ 1. merge PR #147 (rulestead)          │
  │ check-actions │───▶│ commit REL-16 table    │───────▶│    -> publish-hex-rulestead (auto)    │
  │ default paths │    │ dispatch 3 rehearsals: │        │    -> Hex.pm registry check            │
  │ (WINDOWS #35) │    │  - hex-publish.yml     │        │ 2. merge PR #164 (core 0.2.2)          │
  └──────────────┘    │    op=candidate-       │        │    -> approved-release-guard (identity)│
                       │    rehearsal           │        │    -> publish-hex/ios-core/android-core│
                       │  - ios-mirror-         │        │    -> exact-public-proof (package:     │
                       │    backfill.yml        │        │       crosswake only)                  │
                       │    op=candidate-       │        │    -> linked-release-rollup == COMPLETE│
                       │    rehearsal           │        │    -> Hex/iOS-tag/Maven registry checks│
                       │  - release-please.yml  │        │ 3. merge PR #115 (chimeway)            │
                       │    android-publish-    │        │    -> publish-hex-chimeway (auto)      │
                       │    fire-drill          │        │    -> Hex.pm registry check             │
                       │    (workflow_dispatch) │        │    -> re-confirm linked-release-rollup │
                       └───────────────────────┘        │       still COMPLETE (independent fact)│
                                                          └──────────────────────────────────────┘
```

### Recommended Wave Structure

```
Wave 0 (triage, blocks everything below):
  - Fix scripts/ci_monitor.cjs `checkActions()` default path list (currently hardcoded to 3 paths;
    WINDOWS entry 35, STATE.md:72-79) to discover .github/workflows/*.yml and
    .github/actions/**/action.yml by default.

Wave 1 (prerequisite; blocks all publish steps per the locked one-way-door decision):
  - REL-10: write and commit the retire/backfill runbook (Hex/iOS/Maven), record its commit SHA.
  - REL-16: write and commit the multi-registry partial-failure response table.
  - REL-11: dispatch all three existing rehearsal mechanisms against the *actual* 0.2.2 candidate
    ref, capture and commit their evidence (run IDs, rehearsal.json contents, fire-drill deployment
    ID and DROP confirmation).

Wave 2 (fire-drill publish — lower blast radius companion):
  - REL-12: merge PR #147 or #115 (see "Held companion blast-radius" below for the pick).
  - Confirm via independent Hex.pm API check.

Wave 3 (the milestone's thesis — core 0.2.2 through the repaired graph):
  - REL-13: merge PR #164 (0.2.2). This is the two-parent merge that fires `approved-release-guard`.
  - REL-14: confirm `exact-public-proof` executed (not skipped) and passed, by CI run ID, for 0.2.2.
  - Independent registry checks: Hex.pm, iOS mirror tag, Maven Central pom.

Wave 4 (second companion + final confirmation):
  - REL-15: merge the remaining companion PR.
  - Confirm via independent Hex.pm API check, and re-confirm `linked-release-rollup` reads COMPLETE.

Wave 5 (documentation):
  - DOC-04: delete the "this pipeline only publishes 0.2.1" section from
    docs/COMPANION-PUBLISH-RUNBOOK.md.
  - DOC-06: confirm (already true) that no live workflow/script references splitsh-lite, and add
    explicit `git subtree split` documentation to the runbook (folds naturally into REL-10's runbook).
```

Waves 2-4 cannot be parallelized — each is a real irreversible registry mutation and the ROADMAP's
ascending-blast-radius ordering is a locked decision, not a scheduling optimization. Wave 5 can run
in parallel with Wave 4 once Wave 3 is confirmed (0.2.2 must actually be live before the "only
publishes 0.2.1" sentence becomes false).

### Anti-Patterns to Avoid

- **Building a new rehearsal harness:** The three registries already have working, dispatch-only
  rehearsal jobs. Writing new ones duplicates proven mechanisms and risks the exact "second copy
  drifts from the first" defect Phase 173 was built to eliminate (see `exact-public-proof.yml`'s own
  header comment on why it has exactly one copy).
- **Reading `linked-release-rollup`'s YAML to confirm COMPLETE:** SC6/SC7 explicitly require run
  evidence, not workflow inspection — this is literally the milestone's named recurring defect
  ("absence scored as success"). Use the registry/run-ID commands in "Verification Commands" below.
- **Treating SC7's "linked-release rollup reports COMPLETE" as a per-companion gate:** it is not —
  `linked-release-rollup` has no companion inputs at all (see Summary). Do not add companion states
  to it; that would silently expand a check's meaning without an accompanying requirement.
- **Skipping the rehearsal wave "because the mechanism already exists and clearly works":** REL-11's
  success criterion requires the rehearsal *output recorded* for the actual 0.2.2 rehearsal — a
  rehearsal that ran for 0.2.1 during Phase 168 does not satisfy REL-11 for 0.2.2. Dispatch fresh.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex publish rehearsal | A scratch/throwaway Hex organization | `hex-publish.yml` `candidate-rehearsal` operation (`mix hex.publish --dry-run` + `mix hex.build`) | Already dispatches against the real candidate ref and already produces the artifact the canonical receipt consumes; a private Hex org would need its own credentials, its own package names, and would not validate against the real `crosswake` namespace's existing releases |
| iOS mirror rehearsal | A parallel scratch mirror repo | `ios-mirror-backfill.yml` `candidate-rehearsal` operation (`git subtree split` + `git push --dry-run --porcelain`) | Already computes the real split SHA and dry-run-validates the push against the real mirror remote's actual ref state |
| Maven rehearsal | A local-only build with no registry contact | `android-publish-fire-drill`'s validated-upload-then-DROP against the real Central Portal Publisher API | This is the *only* mechanism that actually rehearses Central's real validation (POM completeness, signature verification, checksum matching) — `publishToMavenLocal` alone (used for hermetic CI) never contacts Central at all and would miss upload-time validation failures |
| Multi-registry partial-failure playbook | Ad-hoc incident-time decisions | The existing "Ordinary publication and recovery" + "Five states and one correction" sections of `docs/COMPANION-PUBLISH-RUNBOOK.md`, extended into REL-16's explicit table | The runbook already states the core principles (never retry an immutable success, recover the one missing coordinate, never roll back a proven success) — REL-16 should extend this into a literal per-registry×per-failure-mode table, not invent new principles |

**Key insight:** Every "don't hand-roll" item in this phase resolves to "the mechanism already
exists in this repo, built and proven during Phase 168 for 0.2.1 — use it again for 0.2.2 and the
companions." This phase is an execution/evidence phase, not a build phase.

## Runtime State Inventory

Not applicable in the classic rename/refactor sense — this phase does not rename or migrate anything.
However, because it performs the milestone's only irreversible operations, the equivalent "what
public, external state exists after this phase that this repo does not fully control" questions are
answered here:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Hex.pm published packages | After this phase: `crosswake@0.2.2`, `crosswake_rulestead@0.1.1`, `crosswake_chimeway@0.1.1` will be additional, immutable, permanently-listed releases | None during this phase (by design — this is the phase's purpose); REL-10's runbook must cover retiring any of these forward if a defect is found later |
| iOS mirror repo (`szTheory/crosswake-shell-core-ios`) | New tag `refs/tags/v0.2.2` and `main` fast-forwarded to the new split SHA | None beyond the runbook's re-tag/note recovery procedure being committed first |
| Maven Central (`io.github.sztheory:crosswake-shell-core-android`) | New immutable coordinate `0.2.2` | None beyond the runbook's retire-forward procedure being committed first |
| `docs/release-ledger/RELEASE-LEDGER.jsonl` | New line(s) for `crosswake@0.2.2` (and the companions do not append here — `exact-public-proof` only runs for `package: crosswake`) | Verify the ledger PR (`chore/release-ledger-<run_id>`) is merged after each linked-release run so the row is durable, not stuck as an open PR |
| GitHub required-check registry | No new checks land in this phase unless Wave 0's `check-actions` fix or REL-16's table introduce new merge-blocking scanner IDs | If any new check is added, it must clear the vacuity-taxonomy review per the milestone's Phase 170 convention (VAC-03) before being made merge-blocking |

## Common Pitfalls

### Pitfall 1: Rehearsing the wrong ref
**What goes wrong:** Running `candidate-rehearsal` against the *current* `main` HEAD instead of the
actual Release Please candidate head for PR #164/#147/#115 produces rehearsal evidence that does not
correspond to what will actually be merged and published.
**Why it happens:** The rehearsal workflows take an explicit `candidate_head`/`ref` input; it is easy
to default to the wrong SHA, especially since PR #147 and #115 currently report `mergeStateStatus:
BEHIND` [VERIFIED: `gh pr view 147/115 --json mergeStateStatus`] — Release Please may refresh their
heads again before merge.
**How to avoid:** Capture the exact head SHA immediately before each rehearsal dispatch and again
immediately before merge; if they differ, redo the rehearsal.
**Warning signs:** A rehearsal receipt's `observed_head` not matching the PR's current head at
merge time.

### Pitfall 2: Treating a companion Hex publish as needing the strict identity gate
**What goes wrong:** Assuming PR #147/#115 need to pass through `approved-release-guard` (the
head/tree/base/receipt chain built in Phase 171) before they can publish, and blocking on an
`approved_version` binding that doesn't apply to them.
**Why it happens:** The linked 0.2.2 release and the two companion releases share a release-please.yml
file and a superficially similar "approve then publish" shape, but structurally diverge: companion
publish jobs (`publish-hex-rulestead`, `publish-hex-chimeway`) `needs: release-please` only — never
`approved-release-guard` [VERIFIED: .github/workflows/release-please.yml:301-303,454-461].
**How to avoid:** Merging either companion PR is sufficient to trigger its publish job once
`release-please`'s own tag-creation signal fires; no separate approval receipt is required.
**Warning signs:** Waiting for an `approved_version`/receipt artifact that will never be produced for
a companion-only merge.

### Pitfall 3: Reading `linked-release-rollup`'s COMPLETE as proof that the *companion* publish succeeded
**What goes wrong:** Treating SC7's "linked-release rollup reports COMPLETE" as if it were gated on
the second companion's publish outcome.
**Why it happens:** SC7's prose lists both facts in one sentence.
**How to avoid:** Verify the companion's Hex.pm listing independently (see Verification Commands);
the rollup COMPLETE check only needs to be reconfirmed once, from 0.2.2's own run — see Summary.
**Warning signs:** Writing a new test or check that tries to thread companion publish state into
`Crosswake.ReleaseCandidate.Workflow.rollup!/1`, which structurally has no companion inputs
[VERIFIED: lib/crosswake/release_candidate/workflow.ex:4-15].

### Pitfall 4: Assuming `mix hex.retire` removes the package
**What goes wrong:** Writing the REL-10 runbook's Hex section as if retiring deletes or hides
`0.2.2` from the registry.
**Why it happens:** "Retire" sounds destructive.
**How to avoid:** A retired package "is still resolvable and usable but... flagged as retired... with
a message displayed to users" [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Retire.html]. Retirement
reasons are exactly `renamed`, `deprecated`, `security`, `invalid`, `other` (each requiring a
`--message`), and `mix hex.retire PACKAGE VERSION --unretire` reverses it
[CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Retire.html]. Write the runbook against this real
semantic, not an assumed delete-equivalent.
**Warning signs:** Runbook language implying retirement is a rollback of the publish rather than a
forward-only advisory flag.

### Pitfall 5: Assuming Maven Central supports true rollback
**What goes wrong:** Writing the REL-10 Maven section as a "retire" parallel to Hex's.
**Why it happens:** Surface-level symmetry with the other two registries.
**How to avoid:** Maven Central coordinates are immutable once `PUBLISHED`; the only recovery is
"retire-forward" — publish a new, superseding version and document the defective one, never attempt
to delete or replace `0.2.2` itself. The `android-publish-fire-drill` job's own comment makes this
distinction explicit: "immutability is scoped to PUBLISHED only; VALIDATED deployments are safely
droppable" [VERIFIED: .github/workflows/release-please.yml:1156-1157] — i.e., the *rehearsal* can be
dropped because it never reaches PUBLISHED, but a real publish cannot be undone the same way.
**Warning signs:** Runbook text describing a Maven "retire" command that doesn't exist.

### Pitfall 6: Missing the Wave 0 triage prerequisite
**What goes wrong:** Planning publish tasks without first fixing `checkActions()`'s hardcoded
three-path default, leaving 31 mutable action refs across ten unopened workflow files silently
unaudited during the phase that performs the milestone's only irreversible operations.
**Why it happens:** The publish workflows themselves are already fully SHA-pinned
[VERIFIED: STATE.md:75-76], so it's tempting to treat this as low-risk and defer it.
**How to avoid:** Follow STATE.md's explicit planning guidance (recorded 2026-09-18) — the triage
belongs inside Phase 175 as its first wave, on the reasoning that publish is exactly where a silently
truncated audit scope would matter most.
**Warning signs:** A plan for this phase with no Wave 0 task touching `scripts/ci_monitor.cjs`.

## Code Examples

### Dispatching the Hex candidate rehearsal (REL-11, leg 1)
```bash
# Source: .github/workflows/hex-publish.yml (candidate-rehearsal operation)
gh workflow run hex-publish.yml \
  -f operation=candidate-rehearsal \
  -f candidate_head=<40sha> \
  -f candidate_tree=<40sha> \
  -f candidate_base=<40sha> \
  -f candidate_receipt=<64hex-sha256>
# Produces artifact `candidate-rehearsal-hex` containing rehearsal.json + packages/artifacts.json.
# rehearsal.json's package_count must read 6 and external_state_changed must read false.
```

### Dispatching the iOS mirror candidate rehearsal (REL-11, leg 2)
```bash
# Source: .github/workflows/ios-mirror-backfill.yml (candidate-rehearsal operation)
gh workflow run ios-mirror-backfill.yml \
  -f operation=candidate-rehearsal \
  -f version=0.2.2 \
  -f release_ref=<40sha, must equal candidate_head> \
  -f candidate_head=<40sha> \
  -f candidate_tree=<40sha> \
  -f candidate_base=<40sha> \
  -f candidate_receipt=<64hex-sha256>
# Produces artifact `candidate-rehearsal-ios` containing rehearsal.json + mirror.json.
# mirror.json's state must read PASS, authorization_result PROVEN, external_state_changed false.
```

### Dispatching the Android/Maven fire drill (REL-11, leg 3)
```bash
# Source: .github/workflows/release-please.yml (android-publish-fire-drill job)
gh workflow run release-please.yml --ref main
# This job runs unconditionally on any workflow_dispatch of release-please.yml, uploads the real
# signed bundle to Central Portal, polls to VALIDATED, then DROPs the deployment — the coordinate
# is never marked PUBLISHED and is free for the real release afterward.
```

### Independent registry verification (SC4-6, "not by inspection of the workflow")
```bash
# Hex — confirm a package/version is actually live
curl -sS "https://hex.pm/api/packages/crosswake" \
  | python3 -c "import json,sys; print([r['version'] for r in json.load(sys.stdin)['releases']])"
# Expect '0.2.2' present in the list.

curl -sS "https://hex.pm/api/packages/crosswake_rulestead" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('latest_stable_version'))"
# Expect '0.1.1' after PR #147 merges and publishes.

# iOS mirror — confirm the tag exists at the expected split SHA
git ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios.git | grep v0.2.2

# Maven — confirm the coordinate is live (200, not 404)
curl -sS -o /dev/null -w '%{http_code}\n' \
  "https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/0.2.2/crosswake-shell-core-android-0.2.2.pom"

# exact-public-proof — confirm EXECUTED (not skipped) and PASSED, for the exact version, by run ID
gh run list --workflow release-please.yml --json databaseId,headSha,conclusion,event --limit 10
gh run view <run-id> --json jobs --jq '.jobs[] | select(.name == "shared: exact-public artifact proof body") | {status, conclusion}'
# conclusion must be "success" and status must NOT be a skip — cross-check against
# docs/release-ledger/RELEASE-LEDGER.jsonl's new row for package=crosswake, version=0.2.2, outcome.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `splitsh-lite` for iOS mirror subtree splitting | `git subtree split` | Already landed pre-Phase-175 (confirmed live in `release-please.yml:373` and `script/verify_ios_mirror_backfill.sh` now delegates entirely to `script/release_candidate/ios_mirror.sh`, which never invokes splitsh-lite) | DOC-06's live-code scope is already satisfied; the remaining work is purely documentation (add explicit mention to the runbook) and confirming no operational reference remains (confirmed: none do) |
| 0.2.1-hardcoded version literals in publish gates | `approved_version`-derived gating | Phase 171 | This phase is the first real release exercising the generalized gate for a version other than 0.2.1 |
| Exact-public-proof never executed at any release | `exact-public-proof` runs on every linked-release push with a publication-record signal | Phase 173 | REL-14 is the first opportunity to observe a genuine `success` conclusion (Phase 173's own fire-drill only proved the `failure`-not-`skipped` path) |

**Deprecated/outdated:** `splitsh-lite` is not to be reinstalled or referenced going forward; all live
mirror-split logic already uses `git subtree split`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `crosswake_rulestead` has fewer downstream consumers / lower blast radius than `crosswake_chimeway`, based on all-time Hex download counts (75 vs 106) and the absence of any other package in this repo depending on either at runtime | "Held companion blast-radius pick" below | If download counts do not reflect real external adopter dependency depth (e.g., an external, non-repo consumer depends heavily on one), the "fire drill first" pick could carry more real-world blast radius than assumed. Low risk: this repo has no visibility into external consumers beyond what's public on Hex.pm, and the milestone's own framing treats this as a judgment call requiring justification, not a provably correct answer. |

## Open Questions (RESOLVED)

All three were open at research time and are now resolved by locked decisions in `175-CONTEXT.md`.
The substance below is unchanged; each question carries its resolution inline.

1. **Which of PR #147 / #115 is "lower blast radius" — is download count the right proxy?**
   - **RESOLVED: see D-01, D-02, D-03.** The companion pick, the impact-if-wrong meaning of "blast
     radius", and the "no signal found" (not "definitively zero") qualification are all locked.
   - What we know: `crosswake_rulestead` (PR #147) has 75 all-time Hex downloads; `crosswake_chimeway`
     (PR #115) has 106 [VERIFIED: `curl https://hex.pm/api/packages/crosswake_rulestead` and
     `.../crosswake_chimeway`, 2026-09-18]. Neither is depended on by any other package in this repo
     — `crosswake_chimeway` has a *test-only* `path` dependency on `crosswake_sigra`, which is the
     reverse direction and irrelevant to chimeway's own blast radius
     [VERIFIED: packages/crosswake_chimeway/mix.exs:51]. `crosswake_rulestead` is referenced nowhere
     outside its own package directory and the runbook doc
     [VERIFIED: `grep -rl crosswake_rulestead packages/*/mix.exs docs/`].
   - What's unclear: whether "downstream consumers" should be measured by Hex download count, or by
     some other signal this repo cannot see (e.g. GitHub dependents graph, which was not queried in
     this research pass).
   - Recommendation: Pick `crosswake_rulestead` (PR #147) as the lower-blast-radius fire-drill
     companion — lower download count, and it is the companion explicitly named first in STATE.md's
     PR-triage table. Record this pick and its justification (download count) as a planning decision
     rather than treating it as self-evident.

2. **Do PR #147/#115's `BEHIND` merge states require action before merge?**
   - **RESOLVED: see D-33.** Re-confirm the head immediately before dispatching a rehearsal and again
     immediately before merging; a mismatch means redoing the rehearsal, not reconciling.
   - What we know: `gh pr view` reports `mergeable: MERGEABLE` but `mergeStateStatus: BEHIND` for
     both PRs [VERIFIED: `gh pr view 147/115 --json mergeable,mergeStateStatus`].
   - What's unclear: whether this repo's branch protection requires a branch to be up-to-date with
     `main` before merge (which would block a direct merge until Release Please or a manual rebase
     refreshes the branch), or whether `BEHIND` is cosmetic here.
   - Recommendation: The planner should treat "confirm the PR head is current immediately before
     merge" as an explicit pre-merge step in each publish wave — this is also required anyway by
     Pitfall 1 (rehearse the exact head that will actually merge).

3. **Does REL-16's response table need to be a new document, or an extension of the existing runbook?**
   - **RESOLVED: see D-13.** One document covering both REL-10 and REL-16.
   - What we know: `docs/COMPANION-PUBLISH-RUNBOOK.md` already documents general partial-failure
     principles ("Ordinary publication and recovery", "Five states and one correction") but not a
     literal per-registry × per-failure-mode table.
   - What's unclear: whether REL-10 (retire/backfill runbook) and REL-16 (partial-failure response
     table) should be the same document or two, given they cover overlapping ground.
   - Recommendation: One new document (e.g. `docs/RELEASE-INCIDENT-RESPONSE.md`) covering both REL-10
     and REL-16, cross-linked from `docs/COMPANION-PUBLISH-RUNBOOK.md`, is simplest and avoids
     splitting "what do I do when X registry fails" across two files. Leave the final naming/structure
     to the planner.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `gh` CLI (authenticated, repo write scope) | Dispatching rehearsal workflows, merging PRs, querying run status | ✓ (used throughout this research) | — | — |
| `HEX_API_KEY`, `ORG_GRADLE_PROJECT_mavenCentral*`, `ORG_GRADLE_PROJECT_signingInMemory*`, `MIRROR_DEPLOY_KEY`, `RELEASE_PLEASE_TOKEN` (repo secrets) | All three real publish legs and rehearsal dispatches | Not independently verifiable from this research session (secrets are opaque to `gh`/`curl`); `android-publish-fire-drill`'s own preflight step already asserts all 8 are non-empty at dispatch time | — | None — these are required; the fire-drill's preflight step is itself the verification mechanism, run it first |
| Hex.pm, Maven Central (`repo1.maven.org`), GitHub mirror repo reachability | Independent registry verification (SC4-6) | ✓ (confirmed reachable during this research session) | — | — |

**Missing dependencies with no fallback:** None identified — all required tooling and credentials are
already wired into existing workflows; this phase's risk is entirely in *sequencing and evidence*, not
missing infrastructure.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ExUnit + `mix test`), Elixir 1.19.5-otp-27 / Erlang 27.3 [VERIFIED: .tool-versions] |
| Config file | `mix.exs` (root); companion packages have their own `mix.exs` |
| Quick run command | `mix test test/crosswake/proof/` (targeted release-candidate/proof suites) |
| Full suite command | `mix test` (root); `bash script/verify_repository.mjs` or equivalent umbrella per Phase 166's contract |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-10 | Retire/backfill runbook committed before first publish, SHA recorded | structural/manual | `git log --oneline -1 -- docs/<runbook>.md` compared against the phase's first publish-step commit timestamp | ❌ Wave 1 (new doc) |
| REL-11 | All three rehearsals dispatched and evidence recorded for the 0.2.2 candidate | manual dispatch + evidence capture (not a unit test — this is a real CI dispatch against real registries) | `gh run view <run-id> --json conclusion` for each of the 3 dispatches | N/A — CI-run evidence, not a repo test |
| REL-12/13/15 | Companion/core publishes land and are live | manual (irreversible) + registry check | Commands under "Independent registry verification" above | N/A — real-world state, not a repo test |
| REL-14 | `exact-public-proof` executed and passed for 0.2.2 | CI run inspection | `gh run view <run-id> --json jobs` filtering the shared proof body's job name; cross-check `docs/release-ledger/RELEASE-LEDGER.jsonl` | ✓ mechanism exists (`exact-public-proof.yml`); this phase supplies the first real passing row |
| REL-16 | Response table authored before first publish | structural/manual | Same git-log-before-first-publish-commit check as REL-10 | ❌ Wave 1 (new doc) |
| DOC-04 | "only publishes 0.2.1" section deleted once false | structural | `! grep -q "this pipeline currently publishes exactly one version" docs/COMPANION-PUBLISH-RUNBOOK.md` after 0.2.2 is live | ✓ target text exists today, verified in this research pass |
| DOC-06 | No residual splitsh-lite references; `git subtree split` documented | structural | `! grep -rn splitsh .github/ script/ lib/ docs/` (already passes except docs, which currently has zero mentions of the mirror-split mechanism by name at all) | ✓ — confirmed clean already; only the "document git subtree split explicitly" half remains |

### Sampling Rate
- **Per plan/task:** N/A for the publish waves themselves (these are one-shot irreversible CI
  dispatches, not iterated code changes); the triage wave (Wave 0) and documentation wave (Wave 5)
  follow the repo's normal `mix test` / `verify_repository` cadence.
- **Phase gate:** All registry checks in "Verification Commands" green, `exact-public-proof` run ID
  linked and `success`, `linked-release-rollup` artifact reads `COMPLETE`, before `/gsd-verify-work`.

### Wave 0 Gaps
- None requiring new test files — REL-10/REL-11/REL-16's "evidence" is CI run IDs and committed
  documents, not new ExUnit suites. The existing `test/crosswake/proof/ios_rehearsal_script_test.exs`
  and the Phase 173 fixture suite already cover the *shape* of rehearsal/proof correctness; this
  phase's job is to produce real-world evidence, not new unit coverage.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | No new auth surface; existing GitHub Actions `secrets:` scoping (already SHA-pinned, already `persist-credentials: false` on all non-mutating checkouts) governs this phase's only "authentication," which is credential-scoped workflow dispatch |
| V3 Session Management | no | N/A |
| V4 Access Control | yes | `publish`/`recovery` operations already require exact-identity gates validated against hardcoded Phase 168 constants before checkout or credential load [VERIFIED: .github/workflows/ios-mirror-backfill.yml:320-346, hex-publish.yml:170-219] — Phase 175 does not need new access-control code, but the planner must confirm any *new* dispatch constants (for 0.2.2, not the old Phase 168 SHAs) are correctly threaded if new identity gates are added for this release's own recovery path |
| V5 Input Validation | yes | Existing shape-validated `workflow_dispatch` inputs (40-hex SHA regexes, semver regexes) — no new input surface introduced by this phase |
| V6 Cryptography | no | No new cryptographic operation; existing Vanniktech signing config and SSH deploy-key mechanics are unchanged |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Publishing an unapproved/mutated candidate | Tampering | `approved-release-guard`'s exact head/tree/base/receipt chain (Phase 171) — unchanged by this phase, verified still exact by SC7's own wording ("the identity gate remains exact after the version gate generalizes," Phase 171 SC7) |
| A rehearsal accidentally mutating a real registry | Tampering/EoP | All three rehearsal mechanisms are structurally read-only or explicitly self-reverting: Hex rehearsal never calls `mix hex.publish` without `--dry-run`; iOS rehearsal uses `git push --dry-run --porcelain`; Maven fire-drill DROPs the deployment before it reaches `PUBLISHED`. No new code changes this; the planner should not weaken any of these three properties. |
| Leaking secrets into rehearsal output/logs | Information Disclosure | All three rehearsal jobs already write structured JSON receipts with explicit fields, not raw command output; no new secret-bearing surface is introduced by dispatching them for 0.2.2 instead of 0.2.1 |

## Sources

### Primary (HIGH confidence)
- `.github/workflows/release-please.yml` (full file read, 1593 lines) — `approved-release-guard`,
  `release-please`, `publish-hex-*`, `exact-public-proof`, `linked-release-rollup`,
  `native-release-rollup`, `android-publish-fire-drill` job definitions
- `.github/workflows/hex-publish.yml` (full file read, 489 lines) — `rehearse-hex-candidate`,
  `publish`, `recovery-exact-public-proof`, `recovery-fire-drill` job definitions
- `.github/workflows/ios-mirror-backfill.yml` (full file read) — `rehearse-ios-mirror-candidate`,
  `publish-ios-mirror`, `recover-ios-mirror` job definitions
- `.github/workflows/exact-public-proof.yml` (full file read) — the single shared proof body and
  `record-ledger` job
- `lib/crosswake/release_candidate/workflow.ex:1-70` — `rollup!/1`'s COMPLETE/PARTIAL/BLOCKED logic
- `script/verify_ios_mirror_backfill.sh` (full file read) — confirms delegation to
  `script/release_candidate/ios_mirror.sh`, no splitsh-lite reference
- `script/release_candidate/hex_artifacts.sh:206,214` (grep-verified) — `mix hex.publish package
  --dry-run --yes` and `mix hex.build --output` both present
- `docs/COMPANION-PUBLISH-RUNBOOK.md` (full file read) — candidate authority, exact seven-step
  operator sequence, five states, ordinary/recovery semantics
- Live registry checks performed in this session: `hex.pm/api/packages/crosswake`,
  `.../crosswake_rulestead`, `.../crosswake_chimeway`; `git ls-remote --tags
  https://github.com/szTheory/crosswake-shell-core-ios.git`; Maven `repo1.maven.org` HTTP HEAD for
  `0.2.1` (200)
- `gh pr view 147 / 115 --json ...` — mergeable, mergeStateStatus, files, statusCheckRollup (all
  green CI as of the PR's last run)
- `hexdocs.pm/hex/Mix.Tasks.Hex.Retire.html` — retirement semantics [CITED]

### Secondary (MEDIUM confidence)
- WebSearch results confirming `mix hex.publish --dry-run` builds and validates without publishing
  [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] — corroborated directly by reading
  `hex_artifacts.sh`'s own invocation in this repo (upgraded to VERIFIED for this repo's specific
  usage)

### Tertiary (LOW confidence)
- None used as the basis of any claim in this document.

## Metadata

**Confidence breakdown:**
- Standard stack / rehearsal mechanism ceiling: HIGH — every claim traced to a specific file/line
  read in this session, no external inference required
- Architecture / ordering (core-first vs. blast-radius-first): HIGH — resolved by reading both
  companion `mix.exs` files and the live Hex.pm registry state directly
- Package legitimacy: N/A — no new packages
- Retirement/rollback semantics: MEDIUM-HIGH — Hex semantics confirmed via official hexdocs; Maven
  immutability confirmed both via the fire-drill script's own comment and general Central Portal
  behavior (not independently re-verified against Sonatype's own docs in this session)
- Held-companion blast-radius pick: MEDIUM — download-count proxy is a reasonable but not
  definitive signal; flagged explicitly in Assumptions Log and Open Questions

**Research date:** 2026-09-18
**Valid until:** This research is tied to a specific point-in-time state of two open PRs
(`mergeStateStatus: BEHIND`) and live registry contents; re-verify PR head SHAs and registry state
immediately before executing any publish wave, not just before planning. Treat as valid for planning
purposes for ~7 days; re-check registry/PR state at execution time regardless of elapsed time.
