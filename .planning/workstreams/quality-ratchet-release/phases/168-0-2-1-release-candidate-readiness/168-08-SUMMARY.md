---
phase: 168-0-2-1-release-candidate-readiness
plan: "08"
subsystem: release-readiness
tags: [release-candidate, exact-head, github-actions, package-proof, trusted-rehearsal, tdd]
requires:
  - phase: 168-07
    provides: Candidate CI, read-only linked release status, and the single-approval operator boundary
provides:
  - Reversible Phase 168 readiness implementation landed through protected default before candidate capture
  - Canonical exact-head READY FOR APPROVAL receipt with complete package, clean-room, workflow, mirror, and repository proof
  - Explicit maintainer approval bound to one candidate head and receipt digest without performing a release mutation
affects: [phase-168-postapproval, linked-0.2.1-release, release-please-pr-57]
actuals:
  tokens: 23274
  tasks: 3
  commits: 34
plan_head_before: f75f25110e68b2ef5d1884068af00e17eff42506
tech-stack:
  added: []
  patterns: [exact-head-receipt, reversible-before-approval, credentialed-no-mutation-rehearsal, immutable-linked-release]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-08-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-08-task2-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-refresh.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.md
  modified:
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/hex-publish.yml
    - .github/workflows/ios-mirror-backfill.yml
    - script/release_candidate/hex_artifacts.sh
    - script/release_candidate/ios_mirror.sh
    - script/verify_companion_cleanroom.sh
key-decisions:
  - "Bind release authority only to PR #57 head 1051ab90cf75e918c6f596f84578ac77eadf45af, tree ecf63228243bfe7c2d6a377be996aa374b31d91f, and protected-default base 9533049d1ee5239b122b43749ff90f8ace7c7f6b."
  - "Treat receipt SHA-256 359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78 as the exact approval authority; any identity drift invalidates it."
  - "Record the maintainer's exact approval but leave merging, tags, publication, mirror mutation, and postapproval dispatch to a separately revalidated executor."
  - "Keep companion PRs 115, 146, and 147 outside the linked 0.2.1 authorization."
patterns-established:
  - "Land every reversible correction before refreshing Release Please candidate authority."
  - "A trusted rehearsal may exercise credentials only through a dry-run that proves authority while retaining external_state.changed=false."
  - "One canonical JSON receipt owns identity and proof; the Markdown dossier is its privacy-safe maintainer projection."
requirements-completed: [REL-01, REL-02, REL-03, REL-04, REL-05]
requirements-addressed: [REL-01, REL-02, REL-03, REL-04, REL-05]
duration: 6h 10m
completed: 2026-09-13
status: complete
---

# Phase 168 Plan 08: Exact Candidate Approval Boundary Summary

**All reversible 0.2.1 readiness work landed before a fresh Release Please candidate was bound to complete trusted proof, producing one exact receipt and one explicitly approved—but still unexecuted—irreversible release decision.**

## Performance

- **Duration:** 6h 10m
- **Started:** 2026-09-13T13:41:05Z
- **Completed:** 2026-09-13T19:50:48Z
- **Tasks:** 3
- **Files modified:** 29
- **Commits:** 34 measured from `f75f25110e68b2ef5d1884068af00e17eff42506`

## Accomplishments

- Landed the Phase 167 entry handoff and every reversible Phase 168 release correction through protected default, with exact-head CI before each protected merge and no package, tag, or mirror mutation.
- Refreshed Release Please PR `#57` only after those landings and captured exact head `1051ab90cf75e918c6f596f84578ac77eadf45af`, tree `ecf63228243bfe7c2d6a377be996aa374b31d91f`, and base `9533049d1ee5239b122b43749ff90f8ace7c7f6b`.
- Proved candidate CI at 49/49, six package artifacts, five twice-installed clean-room profiles, exact linked coordinate floors, complete companion deferral markers, repository-wide pinned verification, and a credentialed real-mirror dry-run with no external change.
- Created canonical receipt SHA-256 `359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78`, state `READY FOR APPROVAL`, 12/12 closed checks, and exactly one next action.
- Presented the one D-20 decision and recorded the maintainer's exact approval while deliberately leaving PR merge and the complete postapproval release graph unexecuted for independent final revalidation.

## Task Commits

1. **Task 1 RED: reject stale/unlanded candidate authority** — `1c5dc159`
2. **Task 1 GREEN and reversible landing/capture chain** — `e92d04d7`, `5c5dc551`, `0ee83248`, `512cbb24`, `7d4b7a09`, `4169dba8`, `031f9bb1`, `aecd4a9d`, `f19614dd`, `62a78ef1`, `2ab6e2e1`, `97f9d4ef`, `05be5657`, `2a319dd9`, `f3076798`, `34a1efc2`, `f4bed1af`, `6b15315c`, `a066441f`, `019a7ea7`, `e5fd739c`, `bcbab3a3`
3. **Protected-default reversible merges** — `6e9ea285`, `2d482724`, `c1a26462`, `bb3b4eea`, `9533049d` (plus branch integration `e92d04d7` and `f75f2511` baseline ancestry)
4. **Task 2 RED: block incomplete trusted proof** — `0d28876a`
5. **Task 2 GREEN: canonical READY receipt and dossier** — `9160f3c0`
6. **Task 3: record exact maintainer approval without mutation** — `3c825ea2`

The plan ledger also contains the Phase 167 handoff records `8f113cca` and `6e9ea285`, the protected-default integration `f75f2511` ancestry boundary, merge synchronization `fd067fde`, and deferred operational-hygiene seed `fb7bb678`.

## Evidence and Verification

- Candidate CI run `34776247650` completed successfully at the exact approved head with 49 of 49 checks successful.
- Trusted Hex rehearsal `34777036279` and trusted iOS/mirror rehearsal `34777037998` completed successfully from the final candidate capture digest.
- The pinned clean repository evidence run passed all nine declared stages: repository preflight, root, example host, browser, iOS, Android, formatting, warnings, and final cleanliness.
- Receipt schema validation passed with identical bound/observed identities, 12 unique passing checks, six package digests, five clean-room proof digests, proven mirror authority, and `external_state.changed=false`.
- Receipt-to-dossier projection checks and privacy canaries passed; no URL, actor, credential, log, adopter fact, or other prohibited datum entered tracked evidence.
- Final live revalidation confirmed the exact PR head/tree/base, six config/workflow blobs, four cited run identities, three excluded companion heads and cursor-complete markers, parked-state blob, registry absence, semantic-tag absence, and unchanged mirror refs.
- Public Hex and Maven `0.2.1` coordinates remained absent; mirror `v0.2.1` remained absent and mirror main remained `658d60253c58b7e0aedb576f16f40766fa677f23`.
- Focused receipt tests passed 6 tests with zero failures; mirror portability tests passed 14 tests with zero failures.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
| --- | --- | --- | --- | --- |
| Reversible landing and candidate capture | `1c5dc159` | Reversible correction chain ending `bcbab3a3` | Included in focused correction commits | Pass |
| Trusted receipt | `0d28876a` | `9160f3c0` | Canonical generator projection retained | Pass |
| macOS Bash 3 mirror runtime regression | `019a7ea7` | `e5fd739c` | Minimal fallback initialization | Pass |

Both planned RED records were persisted and accepted by `gsd_run check tdd-red-evidence`. The supplemental Bash 3 RED failed for the intended portability reason before the minimal GREEN correction.

## Decisions Made

- The pre-phase and intermediate PR `#57` heads are superseded evidence, never release authority. Only the final refreshed identity may be merged after a fresh independent equality check.
- The linked immutable scope is exactly `crosswake@0.2.1`, `crosswake-shell-core-ios@0.2.1`, and `io.github.sztheory:crosswake-shell-core-android:0.2.1`; companions remain independent.
- Credential proof means a trusted real-remote dry-run with authorization checked and no write. It does not authorize the rehearsal itself to mutate a mirror.
- D-19 partial success is retained rather than hidden: already-public children remain immutable, and recovery uses exact authorized refs or a forward fix/new version—never moved tags or replaced packages.
- The maintainer's exact approval is recorded as authorization, not execution. A separate executor must independently revalidate immediately before merging PR `#57`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made exact-candidate proof portable and hermetic**

- **Found during:** Task 1 clean candidate execution
- **Issue:** The candidate proof assumed local runtime layout, retained temporary build state, complete Git history, and public availability of an unpublished core dependency.
- **Fix:** Added the fixed-purpose runner boundary, invocation-owned artifacts, exact-object history acquisition, candidate-local dependency seeding, and clean package isolation.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`, `script/verify_companion_cleanroom.sh`, related workflow and proof tests
- **Commits:** `5c5dc551`, `512cbb24`, `7d4b7a09`, `4169dba8`, `031f9bb1`, `aecd4a9d`, `f19614dd`, `62a78ef1`

**2. [Rule 1 - Bug] Preserved no-mutation mirror rehearsal under credentialed execution**

- **Found during:** Task 1 trusted rehearsal
- **Issue:** The mirror evaluator had runtime-drift and diagnostic paths that could invalidate dry-run purity or conceal the exact failure.
- **Fix:** Isolated evaluator diagnostics, pinned the runtime boundary, and required the reconnect/authority proof before trusted dispatch.
- **Files modified:** `script/release_candidate/ios_mirror.sh`, `.github/workflows/ios-mirror-backfill.yml`, mirror proof tests
- **Commits:** `2ab6e2e1`, `97f9d4ef`, `05be5657`, `2a319dd9`

**3. [Rule 1 - Bug] Made candidate truth and manifest checks release-aware**

- **Found during:** Task 1 after the first protected landing
- **Issue:** Exact candidate checks treated the legitimate Release Please refresh and manifest posture as stale ordinary-branch state.
- **Fix:** Bound evaluation to the release candidate's exact version/ref and required manifest-consistent `0.2.1` truth.
- **Files modified:** `.github/workflows/crosswake-ci.yml`, `.github/workflows/hex-publish.yml`, release status and proof tests
- **Commits:** `f3076798`, `34a1efc2`

**4. [Rule 3 - Blocking] Resolved trusted candidate dependency acquisition**

- **Found during:** Task 2 trusted workflow dispatch
- **Issue:** Trusted clean-room execution could not resolve the unpublished candidate core using ordinary registry fallback.
- **Fix:** Supplied exact candidate-local artifacts through the existing trusted proof boundary and retained credential-free diagnostics.
- **Files modified:** `.github/workflows/hex-publish.yml`, `script/verify_companion_cleanroom.sh`
- **Commit:** `6b15315c`

**5. [Rule 1 - Bug] Fixed macOS Bash 3 empty-array failure**

- **Found during:** Task 2 pinned full repository verification
- **Issue:** `RUNTIME=()` became an unbound array under Bash 3.2 with `set -u`, causing the real mirror dry-run evaluator to fail despite valid inputs.
- **Fix:** Initialized the fallback command as `RUNTIME=(env)` and added a regression assertion requiring the non-empty portable fallback.
- **Files modified:** `script/release_candidate/ios_mirror.sh`, `test/crosswake/release_candidate/mirror_test.exs`
- **Commits:** `019a7ea7` RED, `e5fd739c` GREEN

**6. [Rule 1 - Verification] Replaced stale aggregate PR-disposition comparison with bounded live authorities**

- **Found during:** Task 1 final capture verification
- **Issue:** The plan's literal Phase 167 aggregate live comparison encoded the old default/candidate snapshot and correctly failed after authorized Phase 168 landings and Release Please refreshes.
- **Fix:** Retained its 15-case self-test, then checked each excluded PR's cursor-complete singleton deferral marker plus exact live heads/states and the refreshed candidate/default identities independently.
- **Files modified:** Evidence only; no production code
- **Verification:** All three pagination checks passed with the same marker digest, and the complete final live identity check passed.

**Total deviations:** 6 auto-fixed (4 correctness bugs, 2 blocking execution/verification issues).
**Impact on plan:** Every correction tightened the planned exact-candidate or no-mutation boundary. No new release coordinate, workflow family, credential scope, publication path, or adopter feature was introduced.

### AGENTS.md-driven adjustments

- Preserved the untracked workstream runtime files and parked first-adopter state throughout execution.
- Kept every proof codename-safe and omitted adopter identity, customer facts, credentials, private URLs, and raw workflow diagnostics.
- Used automated artifact, registry, Git, and workflow checks for all reversible assertions; human action was reserved solely for the designed irreversible approval.

## Issues Encountered

- Release Please refreshed the candidate repeatedly as necessary reversible fixes landed. Every superseded head was retained explicitly, then rejected as authority.
- A direct unpinned ad-hoc clone lacked the repository's governed toolchain and failed preflight. It was not treated as release evidence; the authoritative pinned exact-candidate run passed all nine stages and supplies the receipt's `repository.all` digest.
- Trusted workflow credentials were available and proven through the prescribed dry-run. No authentication gate or credential exposure occurred.

## Known Stubs

None.

## User Setup Required

None. The exact approval is already recorded. The authorized merge and postapproval graph remain separate execution work and require fresh identity revalidation, not new configuration.

## Next Phase Readiness

- Root may independently revalidate receipt SHA-256 `359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78` against PR `#57` head `1051ab90cf75e918c6f596f84578ac77eadf45af`, tree `ecf63228243bfe7c2d6a377be996aa374b31d91f`, and base `9533049d1ee5239b122b43749ff90f8ace7c7f6b` immediately before the authorized merge.
- Plan 168-08 performed no merge, publication, tag, mirror push, or postapproval dispatch. External release state is still unchanged and safe to stop.
- After the exact merge, the existing guarded graph owns linked child publication, exact public proofs, and fail-closed `COMPLETE`/`PARTIAL` rollup.

## Provenance and what happened after this record was written

*Added 2026-09-15 by plan 168-13. Everything above is preserved as written on
2026-09-13 and was accurate at that date. This section records what the September
forensic pass established afterwards; it corrects the reader's frame, not the
historical record.*

**Where the receipt actually lived.** The canonical receipt and this dossier were
captured on the branch `gsd/phase-168-0-2-1-release-candidate-readiness`, in
commits `9160f3c0` (which created `phase168-candidate-receipt.json` and the
dossier) and `3c825ea2` (which appended only the approval outcome to the
dossier). That branch was never merged or pushed, so for two days the phase's
central deliverable existed only in a local object store. Plan 168-13 recovered
both files byte-for-byte and landed them on protected default. The sibling
evidence files listed in `key-files` were already tracked; only these two were
stranded.

**The approval preceded every irreversible action.** The recorded approval of
head `1051ab90cf75e918c6f596f84578ac77eadf45af` with receipt digest
`359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78` is timestamped
`2026-09-13T19:49:41Z`. The three publication runs executed on 2026-09-14,
roughly eight hours later. Publication ran through gated recovery jobs
(`Recover Hex package`, `Recover approved Android core from exact merge`, and
`Publish approved iOS mirror tag and main atomically`), each of which compares
the approval receipt against the `PHASE168_CANDIDATE_RECEIPT` constant that
equals this receipt's digest. Record and mechanism describe the same
transaction.

**The statements above about external state are dated, not current.** This
summary correctly reports publication state `NONE` and `external_state.changed`
`false` *as of capture*. Those coordinates are now live. The receipt is
deliberately not edited to say otherwise: a pre-publication capture that is
retroactively rewritten to describe the publication is no longer evidence of
what was approved.

**The attestation operation cannot reproduce this receipt.** The
`candidate-receipt-attestation` operation added by `ad8fbada` validates four
pre-publication conditions — the Hex release endpoint returns 404, origin
carries no `0.2.1` tags, the Maven POM returns 404, and the mirror carries no
`v0.2.1` tag. All four are now false, so dispatching it today fails rather than
producing a receipt. It also uploads a retention-limited workflow artifact
rather than committing a durable file. Recovering the stranded commits was the
remaining viable path and is the one taken.

**For the next phase that needs this authority:** capture the receipt *and land
it on protected default* before publication, not after. A receipt that is
correct but unreachable cannot answer the question it exists to answer.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-13*
