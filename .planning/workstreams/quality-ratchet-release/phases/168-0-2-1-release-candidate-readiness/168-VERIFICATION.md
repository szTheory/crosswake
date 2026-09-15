---
phase: 168-0-2-1-release-candidate-readiness
verified: 2026-09-15T18:00:00Z
status: gaps_found
score: 2/5 must-haves verified
covered_files: [".github/workflows/crosswake-ci.yml", ".github/workflows/hex-publish.yml", ".github/workflows/ios-mirror-backfill.yml", ".github/workflows/release-please.yml", ".planning/workstreams/quality-ratchet-release/REQUIREMENTS.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-01-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-01-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-02-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-02-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-03-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-03-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-04-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-04-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-05-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-05-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-06-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-06-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-07-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-07-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-REVIEW.md", "lib/crosswake/release_candidate.ex", "lib/crosswake/release_candidate/artifact.ex", "lib/crosswake/release_candidate/cleanroom.ex", "lib/crosswake/release_candidate/coordinate.ex", "lib/crosswake/release_candidate/identity.ex", "lib/crosswake/release_candidate/mirror.ex", "lib/crosswake/release_candidate/projection.ex", "lib/crosswake/release_candidate/receipt.ex", "lib/crosswake/release_candidate/workflow.ex", "lib/crosswake/release_status.ex", "lib/mix/tasks/crosswake.release.candidate.ex", "lib/mix/tasks/crosswake.release.status.ex", "mix.exs", "script/check_release_workflow_integrity.exs", "script/release_candidate/android_publication.sh", "script/release_candidate/hex_artifacts.sh", "script/release_candidate/ios_mirror.sh", "script/verify_companion_cleanroom.sh", "script/verify_hex_publish_dry_run.sh", "script/verify_ios_mirror_backfill.sh"]
covered_digest: "v1:sha256:ce2c15455e964971a52db22a3f07002bfefcb0f9515536ce4109c995ec1815ec"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "iOS mirror operations use explicit cross-repository authority and fail loudly when it is absent or insufficient (SC2 / REL-02)"
    status: failed
    reason: "168-REVIEW.md CR-01 (critical, unresolved): the recover-ios-mirror job in .github/workflows/ios-mirror-backfill.yml is the one mode that can force-with-lease refs/heads/main on the public iOS mirror, yet — unlike every sibling irreversible job in the same release-candidate authority chain (hex-publish.yml publish/recover-android-core, ios-mirror-backfill.yml publish-ios-mirror) — it has no PHASE168_* hardcoded exact-identity validation step before checkout. Confirmed directly: `grep -n PHASE168` on ios-mirror-backfill.yml shows the constants used by publish-ios-mirror and baseline jobs but none inside the recover-ios-mirror job body (lines 393-424). Any actor with workflow_dispatch permission can supply a structurally-valid but arbitrary expected_old_ref/expected_new_ref pair and force-push main as long as live ancestry reads DIVERGED and the dry-run porcelain check passes — with no binding to the one approved 0.2.1 recovery transaction."
    artifacts:
      - path: ".github/workflows/ios-mirror-backfill.yml"
        issue: "recover-ios-mirror job (lines 393-424) missing the same exact-identity authorization gate present in publish-ios-mirror, hex-publish.yml publish (recovery), and hex-publish.yml recover-android-core"
    missing:
      - "Add a PHASE168_*-style hardcoded exact-identity validation step to recover-ios-mirror (matching the pattern already used in the three sibling jobs) before checkout/credential use, or explicitly document why recovery is intentionally left general-purpose."
  - truth: "The exact Crosswake 0.2.1 candidate commit's readiness is captured as one canonical, durable receipt that a maintainer actually reviewed and approved (SC4 / SC5, REL-04 / REL-05)"
    status: failed
    reason: "Plan 168-08's primary deliverable artifacts — evidence/phase168-candidate-receipt.json (canonical READY FOR APPROVAL authority) and evidence/phase168-candidate-receipt.md (maintainer dossier) — do not exist anywhere in the working tree or in the history reachable from origin/main or local main. `git log --all` shows both files were created in commit 9160f3c0 ('feat(168-08): capture exact ready candidate receipt') and referenced again in 3c825ea2 ('docs(168-08): record exact approval checkpoint'), but both commits exist only on the local, unmerged branch gsd/phase-168-0-2-1-release-candidate-readiness (`git merge-base --is-ancestor 9160f3c0 HEAD` = false; `git merge-base --is-ancestor 9160f3c0 origin/main` = false), which is not pushed to origin. The only surviving evidence artifact on main is evidence/phase168-candidate-refresh.json, itself stale — pinned to Release Please PR #57 head 3d2b5073..., which SUMMARY 168-08 says was later superseded by further landings up to head 1051ab90cf75e918c6f596f84578ac77eadf45af. 168-08-SUMMARY.md itself is untracked in git (never committed) per current git status. `mix crosswake.release.status` (read-only, no --live) independently confirms this: it reports the 0.2.1 candidate as state=BLOCKED with next action 'run mix crosswake.release.status --live, then capture the exact candidate receipt' — i.e. the tool the phase built agrees no receipt has been captured on this branch."
    artifacts:
      - path: ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.json"
        issue: "MISSING — never landed on main; only exists in an unmerged, unpushed local branch commit (9160f3c0)"
      - path: ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.md"
        issue: "MISSING — same as above"
      - path: ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-SUMMARY.md"
        issue: "Untracked in git — the plan's own completion record was never committed"
    missing:
      - "Regenerate and commit the canonical candidate receipt (JSON + Markdown) against the truly current, mergeable candidate identity, or recover and land the existing 9160f3c0/3c825ea2 commits."
      - "Commit 168-08-SUMMARY.md."
      - "Reconcile against the fact that hex.pm, the iOS mirror, and Maven Central already show crosswake@0.2.1 live (published 2026-09-14T03:52:13Z, ~8h after 168-08's SUMMARY completion timestamp) while this repository's mix.exs still reads @version \"0.2.0\" and no maintainer-approval receipt is present in git history — see human_verification item 1."
deferred: []
advisory: []
behavior_unverified_items:
  - truth: "A throwaway host resolves, compiles, registers, and doctors every supported PUBLISHED companion without a false harness failure (SC1 / REL-01), specifically the exact-public post-publication proof mode"
    test: "Run `script/verify_companion_cleanroom.sh` in its exact-public/post-publication mode (per 168-04's must-haves) against the now-actually-published crosswake@0.2.1 and companion packages on Hex/SwiftPM/Maven, per docs/COMPANION-PUBLISH-RUNBOOK.md's seven-step sequence."
    expected: "All five companion profiles (Rulestead, Rindle, Sigra, Chimeway, Threadline) install twice from exact registry sources (zero path locks), pass non-vacuous registration/Doctor checks, and match the approved normalized digests, ending in a live-status COMPLETE."
    why_human: "This is a real-network, stateful, long-running proof (generates Phoenix hosts, resolves real registries) that the verifier cannot safely or quickly execute as a spot-check; the repo only contains fixture-backed unit coverage for this mode (test/crosswake/release_candidate/cleanroom_test.exs --only post_publication), not a captured live run against the now-published packages."
human_verification:
  - test: "Reconcile the already-live crosswake@0.2.1 publication with this phase's designed one-approval release graph"
    expected: "The maintainer should be able to point to the exact candidate receipt (head/tree/base/checks) that was approved before hex.pm, the iOS mirror (refs/tags/v0.2.1), and Maven Central all went live at 0.2.1 on 2026-09-14T03:52:13Z."
    why_human: "`mix crosswake.release.status --live` (read-only, run during this verification) shows the 0.2.1 candidate state as COMPLETE — hex, ios-core, and android-core coordinates are all confirmed public — so the release did happen. But no candidate-receipt artifact recording an explicit maintainer approval exists anywhere in this repository's git history (see gap 2), and mix.exs on main still reads @version \"0.2.0\" (never bumped by the normal Release Please flow reachable from HEAD). This pattern — an irreversible publish having occurred without a corresponding in-repo approval record — is exactly the failure mode CR-01 describes for the ungated iOS mirror recovery path. A maintainer needs to confirm whether the actual 0.2.1 publish went through the reviewed, receipt-bound flow this phase built, or through an out-of-band/recovery path, and if the latter, treat CR-01 as urgent rather than routine."
  - test: "Run the exact-public clean-room proof against the live-published 0.2.1 companion family"
    expected: "See behavior_unverified_items above."
    why_human: "Requires real network access to Hex/SwiftPM/Maven and generates real Phoenix hosts; out of scope for a fast, non-mutating verification pass."
---

# Phase 168: 0.2.1 Release Candidate Readiness Verification Report

**Phase Goal:** Maintainers can approve an exact Crosswake 0.2.1 candidate knowing every reversible package-family and release check has passed.
**Verified:** 2026-09-15T18:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (roadmap SC) | Status | Evidence |
|---|---------|--------|----------|
| 1 | SC1 — throwaway host resolves/compiles/registers/doctors every supported **published** companion without false harness failure (REL-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `lib/crosswake/release_candidate/cleanroom.ex` + `script/verify_companion_cleanroom.sh` implement a real, twice-installed, five-profile candidate-local matrix (66 tests pass, incl. `cleanroom_test.exs`); the exact-public/post-publication mode exists and has fixture-backed unit tests but has not been run against the packages now actually live on Hex/SwiftPM/Maven — no captured evidence of that live run exists in the repo. |
| 2 | SC2 — iOS mirror uses explicit cross-repository authority and fails loudly when absent/insufficient (REL-02) | ✗ FAILED | 168-REVIEW.md CR-01 (critical, unresolved): `recover-ios-mirror` job lacks the `PHASE168_*` exact-identity gate every sibling irreversible job has. Confirmed by direct grep of `.github/workflows/ios-mirror-backfill.yml`. |
| 3 | SC3 — core/companion/Android/iOS coordinates and compatibility floors agree, protected by drift checks (REL-03) | ✓ VERIFIED | `elixir script/check_release_workflow_integrity.exs` — all 20 checks OK (exit 0); `mix crosswake.release.status` and `--live` both report lockstep manifest/config agreement and live registry match; `coordinate_test.exs` + `workflow_test.exs` pass. |
| 4 | SC4 — the exact 0.2.1 candidate commit passes package audit, build, tests, docs generation, clean-room installation, and release-status verification (REL-04) | ✗ FAILED | The one artifact meant to bind and prove this ("exact candidate commit passes everything") — `evidence/phase168-candidate-receipt.json` — does not exist on main; only a stale, superseded `phase168-candidate-refresh.json` remains. `mix crosswake.release.status` independently reports the candidate as `BLOCKED` pending capture of this receipt. |
| 5 | SC5 — all reversible release work automated; remaining irreversible publish presented as one explicit maintainer approval, not performed implicitly (REL-05) | ✗ FAILED | No maintainer-approval receipt exists in git history reachable from main (see gap 2), yet `mix crosswake.release.status --live` shows crosswake@0.2.1 is already live on Hex, the iOS mirror, and Maven Central (published 2026-09-14T03:52:13Z). Without the receipt, there is no verifiable record that the publish was gated by the one explicit approval this phase was built to require — see human_verification item 1. |

**Score:** 2/5 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/release_candidate/{identity,receipt,projection}.ex` | Deterministic candidate identity/receipt/projections | ✓ VERIFIED | Present, substantive (169/222/50 lines), `receipt_test.exs` + `crosswake_release_candidate_test.exs` pass |
| `lib/crosswake/release_candidate/{artifact,coordinate}.ex` | Hex artifact + coordinate/floor validation | ✓ VERIFIED | Present, substantive, `artifact_test.exs` + `coordinate_test.exs` pass |
| `lib/crosswake/release_candidate/cleanroom.ex` | Five-profile clean-room matrix policy | ✓ VERIFIED | Present, substantive (443 lines), `cleanroom_test.exs` passes |
| `lib/crosswake/release_candidate/mirror.ex` | Closed mirror-mode policy | ✓ VERIFIED | Present, substantive (437 lines), `mirror_test.exs` passes |
| `lib/crosswake/release_candidate/workflow.ex` | Postapproval graph rollup policy | ✓ VERIFIED | Present, substantive (177 lines), `workflow_test.exs` passes |
| `.github/workflows/{release-please,hex-publish,ios-mirror-backfill,crosswake-ci}.yml` | Trusted rehearsal + guarded publication graph | ⚠️ PARTIAL | Present, exact-identity gates present on 3 of 4 irreversible jobs; `recover-ios-mirror` missing gate (CR-01) |
| `.../evidence/phase168-entry-landing.json` | Exact five-blob landing receipt | ✓ VERIFIED | Present, tracked, committed |
| `.../evidence/phase168-candidate-refresh.json` | Protected-default + refreshed PR identity | ⚠️ STALE | Present but pinned to a superseded PR #57 head per 168-08-SUMMARY's own narrative |
| `.../evidence/phase168-candidate-receipt.json` | Canonical exact-head READY FOR APPROVAL receipt | ✗ MISSING | Not present on main or origin/main; only exists on an unmerged, unpushed local branch commit (9160f3c0) |
| `.../evidence/phase168-candidate-receipt.md` | Maintainer dossier | ✗ MISSING | Same as above |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `script/release_candidate/hex_artifacts.sh` | `lib/crosswake/release_candidate/artifact.ex` | normalized manifest | ✓ WIRED | `hex_artifacts.sh` invoked by `artifact_test.exs`/`hex-publish.yml`; digests consumed by `Artifact` module |
| `lib/crosswake/release_candidate/coordinate.ex` | `release-please-config.json` | linked-versions group | ✓ WIRED | `check_release_workflow_integrity.exs` check `release.version_graph.lockstep_core_native_only` passes |
| `script/release_candidate/ios_mirror.sh` | `lib/crosswake/release_candidate/mirror.ex` | normalized Git observations | ✓ WIRED | `mirror_test.exs` exercises baseline/candidate/publish/recovery modes end-to-end |
| `.github/workflows/release-please.yml` | `.github/workflows/hex-publish.yml` / `ios-mirror-backfill.yml` | approved head/tree/receipt propagation | ⚠️ PARTIAL | Propagation present for `publish`/`recover-android-core`/`publish-ios-mirror`; absent for `recover-ios-mirror` (CR-01) |
| `.../evidence/phase168-candidate-refresh.json` | `.../evidence/phase168-candidate-receipt.json` | exact identity reuse | ✗ NOT_WIRED | Target file does not exist — chain terminates at the stale refresh artifact |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Release-candidate Elixir test suite | `mix test test/crosswake/release_candidate/ test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs` | 66 tests, 0 failures | ✓ PASS |
| Structural workflow integrity scanner | `elixir script/check_release_workflow_integrity.exs` | 20/20 checks OK, exit 0 | ✓ PASS |
| Workflow YAML lint | `actionlint .github/workflows/{release-please,hex-publish,ios-mirror-backfill,crosswake-ci}.yml` | no findings | ✓ PASS |
| Read-only release status (no network) | `mix crosswake.release.status` | candidate state `BLOCKED`, "capture the exact candidate receipt" | ✓ PASS (confirms gap 2 independently) |
| Read-only release status (live registries) | `mix crosswake.release.status --live` | candidate state `COMPLETE`, hex/ios/maven all public at 0.2.1 | ✓ PASS (confirms live publish already occurred — see human_verification item 1) |

### Anti-Patterns Found

None. Scanned all 39 files listed in 168-REVIEW.md's `files_reviewed_list` for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER`; only matches are `mktemp ...XXXXXX` template strings and one pre-existing PR-body string literal (`_TODO_release_as`), neither of which is a debt marker in the phase's own work.

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|-----------------|--------|----------|
| REL-01 | 168-04, 168-07, 168-08 | ⚠️ NEEDS HUMAN | Candidate-local proof verified; exact-public (published-companion) proof unexercised against live registry — see behavior_unverified_items |
| REL-02 | 168-05, 168-06, 168-07, 168-08 | ✗ BLOCKED | CR-01: recover-ios-mirror missing exact-identity gate |
| REL-03 | 168-03, 168-06, 168-07, 168-08 | ✓ SATISFIED | Structural scanner + release-status + tests all agree |
| REL-04 | all 8 plans | ✗ BLOCKED | Canonical candidate receipt missing from main |
| REL-05 | 168-01, 168-02, 168-06, 168-07, 168-08 | ✗ BLOCKED | No in-repo maintainer-approval record despite live publish already having occurred |

No orphaned requirements: REQUIREMENTS.md maps exactly REL-01 through REL-05 to Phase 168, and all five IDs appear in at least one plan's `requirements:` frontmatter (168-01/02: REL-04/05; 168-03: REL-03/04; 168-04: REL-01/04; 168-05: REL-02/04; 168-06: REL-02/03/04/05; 168-07 and 168-08: all five).

### Human Verification Required

1. **Reconcile the already-live 0.2.1 publication with the missing approval receipt.** `mix crosswake.release.status --live` (read-only, executed during this verification) confirms crosswake@0.2.1, the iOS mirror tag, and the Android/Maven coordinate are all already public (Hex registry `inserted_at: 2026-09-14T03:52:13Z`). But no candidate-receipt artifact recording an explicit maintainer approval exists in this repository's git history, and `mix.exs` on main still declares `@version "0.2.0"`. A maintainer needs to determine whether the live publish went through the reviewed, receipt-bound release graph this phase built, or through an out-of-band/recovery path — and if the latter, treat CR-01 (the ungated `recover-ios-mirror` job) as the likely mechanism and escalate its remediation priority accordingly, rather than treating it as routine cleanup.
2. **Run the exact-public clean-room proof against the now-published companion family.** `script/verify_companion_cleanroom.sh`'s post-publication mode has only fixture-backed unit coverage in the repo; it has not been run against the real, now-live registries and no such run is captured as evidence. This is a real-network, stateful check outside the scope of a fast non-mutating verification pass.

### Gaps Summary

Two must-haves are blocked by concrete, reproducible evidence rather than uncertainty:

1. **CR-01 (SC2 / REL-02):** the `recover-ios-mirror` GitHub Actions job — the single most dangerous mode in this phase's mirror authority chain (it is the only one capable of `force-with-lease`-pushing the public iOS mirror's `main`) — lacks the hardcoded exact-identity gate every sibling irreversible job in the same file and phase enforces. This is a real, unresolved security-relevant gap flagged by the phase's own code review and independently confirmed here by direct inspection of the workflow file.
2. **Missing canonical receipt (SC4 / SC5 / REL-04 / REL-05):** the phase's central deliverable — a durable, committed record of the exact candidate identity a maintainer reviewed and approved before any irreversible publish — does not exist on `main`. It was produced once, on an unmerged local branch that never landed, and `168-08-SUMMARY.md` itself was never committed. Independently, this repository's own `mix crosswake.release.status` tooling confirms the gap (`BLOCKED`, "capture the exact candidate receipt").

These two gaps compound: the actual 0.2.1 package family is already live in production (confirmed via `--live` status and the public Hex API) with no committed evidence of the one explicit approval this phase's entire design exists to require. This is escalated as the top human-verification item rather than assumed benign, because it sits precisely on the failure surface CR-01 describes.

No deferred items were identified — nothing in the gaps above maps cleanly onto a later milestone phase's stated goal or success criteria (this is the terminal phase of the `quality-ratchet-release` workstream's roadmap as currently defined).

---

_Verified: 2026-09-15T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
