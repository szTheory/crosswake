---
phase: 168-0-2-1-release-candidate-readiness
verified: 2026-09-15T22:10:00Z
status: human_needed
score: 5/6 must-haves verified (1 present, behavior-unverified)
covered_files: [".github/workflows/crosswake-ci.yml", ".github/workflows/hex-publish.yml", ".github/workflows/ios-mirror-backfill.yml", ".github/workflows/release-please.yml", ".planning/workstreams/quality-ratchet-release/REQUIREMENTS.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-01-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-01-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-02-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-02-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-03-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-03-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-04-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-04-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-05-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-05-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-06-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-06-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-07-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-07-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-09-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-09-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-10-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-10-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-11-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-11-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-12-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-12-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-13-PLAN.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-13-SUMMARY.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-REVIEW.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.json", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.md", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-refresh.json", ".planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-entry-landing.json", ".release-please-manifest.json", "CHANGELOG.md", "docs/COMPANION-PUBLISH-RUNBOOK.md", "guides/install.md", "lib/crosswake/release_candidate.ex", "lib/crosswake/release_candidate/artifact.ex", "lib/crosswake/release_candidate/cleanroom.ex", "lib/crosswake/release_candidate/coordinate.ex", "lib/crosswake/release_candidate/identity.ex", "lib/crosswake/release_candidate/mirror.ex", "lib/crosswake/release_candidate/projection.ex", "lib/crosswake/release_candidate/receipt.ex", "lib/crosswake/release_candidate/workflow.ex", "lib/crosswake/release_status.ex", "lib/mix/tasks/crosswake.release.candidate.ex", "lib/mix/tasks/crosswake.release.status.ex", "mix.exs", "script/check_release_version_truth.exs", "script/check_release_workflow_integrity.exs", "script/release_candidate/android_publication.sh", "script/release_candidate/hex_artifacts.sh", "script/release_candidate/ios_mirror.sh", "script/verify_companion_cleanroom.sh", "script/verify_hex_publish_dry_run.sh", "script/verify_ios_mirror_backfill.sh", "test/crosswake/proof/phase168_version_truth_test.exs"]
covered_digest: "v1:sha256:ca7380cc03ba5042125e2a5e1ab76ba1fe1b8fbf7270ccfad11790eaeb2158c4"
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: "2/5"
  previous_verified: 2026-09-15T18:00:00Z
  closure_work: "plans 168-09 through 168-13, merged to main via PR #163 (MERGED 2026-09-15T17:29:30Z, 49/49 checks, 0 failed); main now at merge commit 02c6c838"
  gaps_closed:
    - "Gap 1 (SC2 / REL-02) — CR-01: recover-ios-mirror now carries an exact-identity authorization gate that precedes both checkout and the deploy-key load"
    - "Gap 2 (SC4 / SC5 / REL-04 / REL-05) — the canonical candidate receipt (JSON + Markdown) is on main byte-for-byte, and 168-08-SUMMARY.md is committed"
    - "Gap 3 (REL-03 / REL-04) — repository version truth restored to 0.2.1 across all 11 reverted files, CHANGELOG reconciled, PR #158 closed unmerged, regression guard added and wired into CI"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
advisory:
  - finding: "`mix crosswake.release.status` without `--live` still prints candidate state BLOCKED with next action \"run mix crosswake.release.status --live, then capture the exact candidate receipt\", even though the canonical receipt now exists on main. `Crosswake.ReleaseStatus.candidate_state/2`'s deterministic (live=false) clause at lib/crosswake/release_status.ex:245-248 is a fixed literal that never inspects the receipt file, so the message now misdescribes repository state to an operator who has not passed --live."
    category: other
    reason: "Operator-honesty/clarity nit, not a correctness failure: the BLOCKED means \"live truth unknown\", which is the correct fail-closed posture. The prior verification cited this same output as independent confirmation of gap 2; that reading was over-broad — the deterministic path never read the receipt. Resolution would be to reword the next action (e.g. \"live registry truth not checked; run --live\") so it stops implying a missing artifact."
    evidence_status: "none provided — new-scope observation, no deterministic failing artifact; recorded as advisory per the re-verification evidence gate"
  - finding: "`mix crosswake.release.status --live` reports WARNING release.live_registry_bootstrap_pending — crosswake_rindle@0.1.0 missing on hex (release-as bootstrap pin still set, no release tag)."
    category: other
    reason: "Out of Phase 168 scope by D-15/D-16 (the 0.2.1 approval covers only the linked core Hex/iOS/Android unit; companions are independently versioned). The tool reports it as a WARNING with its own next action and it does not affect any SC1-SC5 truth."
    evidence_status: "none provided — expected, self-describing tool warning"
behavior_unverified_items:
  - truth: "A throwaway host resolves, compiles, registers, and doctors every supported PUBLISHED companion without a false harness failure (SC1 / REL-01), specifically the exact-public post-publication proof mode"
    test: "Run `script/verify_companion_cleanroom.sh` in its exact-public/post-publication mode (per 168-04's must-haves) against the now-actually-published crosswake@0.2.1 and companion packages on Hex/SwiftPM/Maven, per docs/COMPANION-PUBLISH-RUNBOOK.md's seven-step sequence."
    expected: "All five companion profiles (Rulestead, Rindle, Sigra, Chimeway, Threadline) install twice from exact registry sources (zero path locks), pass non-vacuous registration/Doctor checks, and match the approved normalized digests, ending in a live-status COMPLETE."
    why_human: "This is a real-network, stateful, long-running proof (generates Phoenix hosts, resolves real registries) that the verifier cannot safely or quickly execute as a spot-check; the repo only contains fixture-backed unit coverage for this mode (test/crosswake/release_candidate/cleanroom_test.exs --only post_publication), not a captured live run against the now-published packages."
    carried_from: "2026-09-15T18:00:00Z verification — re-checked and still holds; no captured live-mode run exists on main."
resolved_escalations:
  - question: "Did the already-live crosswake@0.2.1 publication bypass this phase's gated release graph? (raised as human_verification item 1 in the original pass)"
    answer: "NO — refuted by CI forensics on 2026-09-15. All three publications ran through jobs that DO carry the PHASE168_* exact-identity gate. CR-01's ungated job was never exercised."
    resolved_by: "orchestrator forensic pass, /gsd-execute-phase 168, user-authorized"
    evidence:
      - "Release Please PR #57 WAS merged as b780a19863936619394087f1ffd384f1dca17c93 on 2026-09-13, and IS an ancestor of origin/main (`git merge-base --is-ancestor b780a198 origin/main` = true). mix.exs AT THAT TAG reads @version \"0.2.1\"."
      - "Tags refs/tags/hex-v0.2.1, refs/tags/ios-core-v0.2.1 and refs/tags/android-core-v0.2.1 all exist on origin, all pointing at b780a198."
      - "Hex publish: run 34803888729, workflow_dispatch on main @81ad5ce2, 2026-09-14T03:49:15Z — job 'Recover Hex package' = success (the other two jobs skipped). Hex inserted_at 03:52:13Z matches."
      - "Maven Central: run 34804081347, workflow_dispatch on main @81ad5ce2, 2026-09-14T03:52:48Z — job 'Recover approved Android core from exact merge' = success."
      - "iOS mirror: run 34803135968, workflow_dispatch @dfc353f2, 2026-09-14T03:35:39Z — job 'Publish approved iOS mirror tag and main atomically' (publish-ios-mirror, WHICH IS GATED) = success; 'Recover approved iOS mirror main' = SKIPPED."
      - "Across all 15 most recent ios-mirror-backfill.yml runs, the ungated recover-ios-mirror job has NEVER run non-skipped. CR-01 is a latent hole, not the mechanism used."
    consequence: "CR-01 was a real defect and a real gap, but ROUTINE (latent, unexercised), not URGENT. It was closed on its merits by plan 168-12 — see truth 2 below."
  - question: "Why does main read @version \"0.2.0\" when 0.2.1 is published and tagged?"
    answer: "Deliberate. Commit c7edcd78 'fix(168-08): restore untagged candidate state' (2026-09-13T16:04:02-0400) reverted mix.exs and 10 sibling coordinate files from 0.2.1 back to 0.2.0 so Release Please could form a fresh candidate. The recovery dispatches that completed publication ran ~8h LATER against the already-tagged b780a198 — exact-ref recovery mode working as designed."
    consequence: "Not a bypass, but it left a genuine live inconsistency (gap 3). Resolved 2026-09-15 by plans 168-09/168-10/168-11 — see truth 6 below."
  - question: "Why is there no phase168-candidate-receipt.json on main?"
    answer: "The receipt mechanism was CHANGED mid-phase and the replacement was never invoked. Commit ad8fbada added an 'Attest canonical exact-head candidate receipt' job to ios-mirror-backfill.yml that UPLOADS READY authority as a trusted-workflow artifact rather than committing a file. That job is gated on operation == 'candidate-receipt-attestation' and has only ever appeared as SKIPPED."
    consequence: "Resolved by plan 168-13 via the alternative route (recover and land the stranded commits) rather than the attestation dispatch. The receipt on main is byte-for-byte identical to the one produced at 3c825ea2 — verified by SHA-256 below. The attest-candidate-receipt job remains available at ios-mirror-backfill.yml:165 but was not needed."
human_verification:
  - test: "Run the exact-public clean-room proof against the live-published 0.2.1 companion family"
    expected: "See behavior_unverified_items above."
    why_human: "Requires real network access to Hex/SwiftPM/Maven and generates real Phoenix hosts; out of scope for a fast, non-mutating verification pass."
---

# Phase 168: 0.2.1 Release Candidate Readiness Verification Report

**Phase Goal:** Maintainers can approve an exact Crosswake 0.2.1 candidate knowing every reversible package-family and release check has passed.
**Verified:** 2026-09-15T22:10:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plans 168-09 … 168-13, merged via PR #163)

## Prior Gap Disposition

| # | Prior gap (2026-09-15T18:00:00Z) | Verdict | Primary evidence |
|---|----------------------------------|---------|------------------|
| 1 | CR-01 — `recover-ios-mirror` ungated (SC2 / REL-02) | **resolved** | `.github/workflows/ios-mirror-backfill.yml:413-439` gate; `recovery.ios.exact_identity_gate` OK in `check_release_workflow_integrity.exs`; fail-first reproduced at the red commit |
| 2 | Canonical receipt stranded (SC4 / SC5 / REL-04 / REL-05) | **resolved** | Receipt JSON+MD tracked on `main`; JSON SHA-256 `359ef8a5…6c78` equals the `PHASE168_CANDIDATE_RECEIPT` constant in both workflows and is byte-identical to `3c825ea2` |
| 3 | Repository version truth behind published (REL-03 / REL-04) | **resolved** | `elixir script/check_release_version_truth.exs` exits 0 with 3/3 OK; all 11 reverted files read 0.2.1 with zero 0.2.0 residue; CHANGELOG states 0.2.1 published; PR #158 `state=CLOSED, mergedAt=null` |

### Gap 1 detail — `recover-ios-mirror` exact-identity gate

Read directly from the merged file, not from the summary:

- **Ordering.** The gate step `Validate exact Phase 168 iOS recovery authority` is at line **413**, the first step of the job body (job starts at 393, `steps:` at 400). `actions/checkout@` is at line **441** and `webfactory/ssh-agent@` (which loads `secrets.MIRROR_DEPLOY_KEY`) is at line **449**. The gate therefore precedes **both**, so an unauthorized dispatch reaches neither attacker-chosen code nor credentials. The scanner enforces this structurally via `gate_precedes_credentials_and_checkout?/1` (byte-offset comparison inside the `recover-ios-mirror` job block only — `job_blocks/1` scoping means a matching constant elsewhere in the file cannot satisfy it).
- **Constants compared, not merely declared.** All six declared `PHASE168_*` constants are consumed by a comparison: `PHASE168_MERGE_OID` (432), `PHASE168_APPROVED_HEAD` (433), `PHASE168_APPROVED_TREE` (434), `PHASE168_APPROVED_BASE` (435), `PHASE168_CANDIDATE_RECEIPT` (436), `PHASE168_MIRROR_SPLIT` (437), plus a literal `RELEASE_VERSION = 0.2.1` check (431). Zero declared-but-unused constants. The scanner independently asserts each of those seven comparison strings.
- **`expected_old_ref` is shape-constrained, not free.** Line 438 `printf '%s' "$EXPECTED_OLD_REF" | grep -Eq '^[0-9a-f]{40}$'` and line 439 `[ "$EXPECTED_OLD_REF" != "$EXPECTED_NEW_REF" ]`. This is the only unpinned input and the design reason is documented in-file (401-412): recovery exists precisely because mirror `main` has diverged to a commit not knowable in advance, so the lease cannot be pinned the way `publish-ios-mirror` pins `PHASE168_MIRROR_MAIN`. The scanner additionally asserts the lease is *not* pinned to `PHASE168_MIRROR_MAIN`, so the check cannot be satisfied by copying the publish job's gate wholesale.
- **Guard is non-vacuous (fail-first reproduced by this verifier).** A detached worktree at the red commit `0949020f` (test-before-fix) runs `elixir script/check_release_workflow_integrity.exs` and emits `FAIL: recovery.ios.exact_identity_gate`; at `HEAD` the same check emits `OK`. The worktree was removed and pruned.

### Gap 2 detail — canonical candidate receipt

- Both `evidence/phase168-candidate-receipt.json` (10090 bytes) and `.md` (7119 bytes) are present **and tracked** (`git ls-files`).
- `shasum -a 256` of the JSON on `main` = `359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78` (64 hex chars). This is byte-identical to `git show 3c825ea2:<path>` for both files (JSON `359ef8a5…6c78`, MD `7d39617e…1df3`) — the recovery was byte-for-byte, and **PROHIBITION-NO-RECEIPT-REWRITE was honored**. This verifier read the receipt only; it was not regenerated, reformatted, or re-dated.
- That same digest is the pinned `PHASE168_CANDIDATE_RECEIPT` in `ios-mirror-backfill.yml` (lines 331, 427) and `hex-publish.yml` (lines 172, 304), each compared at lines 341 / 436 / 199 / 313. The receipt file and the four workflow authority gates are now one closed loop; previously the constants pointed at a file that did not exist on `main`.
- The receipt binds the approved head: `identity.bound.head` = `identity.observed.head` = `identity.bound.ref` = `1051ab90cf75e918c6f596f84578ac77eadf45af`, tree `ecf63228…`, base `9533049d…`, mirror split `424ab96e…`, mirror main `658d6025…` — each matching the corresponding pinned workflow constant exactly. `state` = `READY FOR APPROVAL`, `next_action` = `approve_exact_candidate`, `credentials.mirror_write_authority` = `PROVEN`, `external_state.changed` = `false`, `schema_version` = `1.0.0`, with 13 proofs, 6 package digests, 4 workflow digests, 12 checks.
- `168-08-SUMMARY.md` is now tracked, and carries the dated `## Provenance and what happened after this record was written` section (line 194, "Added 2026-09-15 by plan 168-13"), preserving the 2026-09-13 record as written.

### Gap 3 detail — version truth

- `elixir script/check_release_version_truth.exs` → exit **0**, `OK` for `.`, `packages/crosswake-shell-core-ios`, `packages/crosswake-shell-core-android`, each "declared 0.2.1, newest published 0.2.1".
- All 11 files reverted by `c7edcd78` now contain `0.2.1` and **zero** `0.2.0` occurrences (checked individually: `mix.exs`, `.release-please-manifest.json`, `README.md`, `examples/android_shell_host/app/build.gradle`, both example `crosswake_manifest.json`s, both `evidence-manifest.example.json`s, `examples/phoenix_host/priv/crosswake/install_manifest.json`, `guides/android_uat.md`, `packages/crosswake-shell-core-android/build.gradle.kts`).
- `CHANGELOG.md:32` — "The current published Hex release is `0.2.1`"; `CHANGELOG.md:34` — `## [0.2.1] — 2026-09-14` marked "> Published release."; `:18` names the published family. The `[Unreleased]` section is explicitly labeled as planning continuity, not a newer installable release.
- `gh pr view 158 --json state,mergedAt` → `{"state":"CLOSED","mergedAt":null}` — closed unmerged, as decided. The live hazard recorded in the prior report is retired.
- The guard is wired into CI at `.github/workflows/crosswake-ci.yml:190` (`Prove declared version truth is not behind published tags`), inside the `release-candidate-full-proof` job, ahead of candidate identity validation — and documented at `docs/COMPANION-PUBLISH-RUNBOOK.md:186`.
- The guard is genuinely tri-state (`# Exit codes: 0 OK, 1 FAIL, 2 BLOCKED`, `System.halt(1|2|0)`), and `test/crosswake/proof/phase168_version_truth_test.exs` covers all three branches non-vacuously (12 tests incl. two FAIL cases, four BLOCKED cases, semantic-vs-lexicographic newest, non-conforming tag names ignored, and "guard mutates nothing").

## Goal Achievement

### Observable Truths

| # | Truth (roadmap SC) | Status | Evidence |
|---|---------|--------|----------|
| 1 | SC1 — throwaway host resolves/compiles/registers/doctors every supported **published** companion without false harness failure (REL-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged from the prior pass. `lib/crosswake/release_candidate/cleanroom.ex` + `script/verify_companion_cleanroom.sh` implement the real five-profile, twice-installed candidate-local matrix; the exact-public/post-publication mode exists with fixture-backed unit tests but has still not been run against the packages live on Hex/SwiftPM/Maven, and no captured live run exists on `main`. Routed to human verification. |
| 2 | SC2 — iOS mirror uses explicit cross-repository authority and fails loudly when absent/insufficient (REL-02) | ✓ VERIFIED | Was FAILED (CR-01). `recover-ios-mirror` gate at `ios-mirror-backfill.yml:413-439` precedes checkout (441) and ssh-agent/deploy-key (449); all six pinned constants compared; lease shape-constrained to 40-hex and distinct from the new ref. Held in place by `recovery.ios.exact_identity_gate` (OK), proven non-vacuous by a red-commit run that FAILs. All four irreversible jobs in the chain now gated. |
| 3 | SC3 — core/companion/Android/iOS coordinates and compatibility floors agree, protected by drift checks (REL-03) | ✓ VERIFIED | `elixir script/check_release_workflow_integrity.exs` → **67 OK / 0 FAIL, exit 0** (was 20/20; +47 checks since, including the new recovery gate). `mix crosswake.release.status` reports all 8 deterministic checks OK; `--live` adds `OK release.candidate_public_truth`. `actionlint` clean on all four release workflows. |
| 4 | SC4 — the exact 0.2.1 candidate commit passes package audit, build, tests, docs generation, clean-room installation, and release-status verification (REL-04) | ✓ VERIFIED | Was FAILED. The canonical receipt now exists on `main`, binds head `1051ab90…`/tree `ecf63228…`/base `9533049d…` with identical `bound` and `observed` identities, carries 13 proof results and 6 package digests, and its SHA-256 is the constant four workflow gates compare against. The stale `phase168-candidate-refresh.json` is now a bound input to it (`Candidate refresh SHA-256 e80f9e85…`) rather than a dead end. |
| 5 | SC5 — all reversible release work automated; remaining irreversible publish presented as one explicit maintainer approval, not performed implicitly (REL-05) | ✓ VERIFIED | Was FAILED. `evidence/phase168-candidate-receipt.md` is the maintainer dossier, leading with the exact intended first line ("READY FOR APPROVAL. Reversible checks PASS 12/12. Mirror write authority PASS; dry-run only; no refs or packages changed. Next: review the dossier, then approve release PR head `1051ab90…`"), naming the linked immutable scope and `next_action: approve_exact_candidate`. Combined with resolved_escalations[0] (all three live publications ran through gated jobs), the approval boundary is now both designed and evidenced in-repo. |
| 6 | Repository version truth agrees with what is actually published (SC3-adjacent / REL-03, REL-04) — *added by the 2026-09-15 forensic pass* | ✓ VERIFIED | Was FAILED. Version-truth guard exits 0 (3/3 OK), 11/11 files restored to 0.2.1 with no 0.2.0 residue, CHANGELOG reconciled, PR #158 CLOSED unmerged, and a tri-state regression guard is wired into `release-candidate-full-proof` so a rollback-after-publish cannot silently re-arm a duplicate release. |

**Score:** 5/6 truths verified (1 present, behavior-unverified)

No `coincidental-reliance` flags: each VERIFIED truth rests on evidence the code itself establishes (pinned constants compared in-file, a digest that binds artifact to gate, a guard wired into a CI job and proven to fail at its red commit), not on undeclared preconditions, incidental ordering, or fixture-only setup.

### Deferred Items

None.

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | Non-`--live` `mix crosswake.release.status` still says "capture the exact candidate receipt" although the receipt now exists; the deterministic clause (`release_status.ex:245-248`) never reads the file | other | new-scope wording/clarity issue; fail-closed behavior is correct, no deterministic failing artifact |
| 2 | `crosswake_rindle@0.1.0` missing on Hex (bootstrap pin still set) surfaced as a `--live` WARNING | other | out of Phase 168 scope per D-15/D-16; self-describing tool warning with its own next action |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/release_candidate/{identity,receipt,projection}.ex` | Deterministic candidate identity/receipt/projections | ✓ VERIFIED | Present, substantive; covered by the passing suite below |
| `lib/crosswake/release_candidate/{artifact,coordinate}.ex` | Hex artifact + coordinate/floor validation | ✓ VERIFIED | Present, substantive, tests pass |
| `lib/crosswake/release_candidate/cleanroom.ex` | Five-profile clean-room matrix policy | ✓ VERIFIED | Present, substantive (443 lines), `cleanroom_test.exs` passes |
| `lib/crosswake/release_candidate/mirror.ex` | Closed mirror-mode policy | ✓ VERIFIED | Present, substantive (437 lines), `mirror_test.exs` passes |
| `lib/crosswake/release_candidate/workflow.ex` | Postapproval graph rollup policy | ✓ VERIFIED | Present, substantive (177 lines), `workflow_test.exs` passes |
| `.github/workflows/{release-please,hex-publish,ios-mirror-backfill,crosswake-ci}.yml` | Trusted rehearsal + guarded publication graph | ✓ VERIFIED | Was ⚠️ PARTIAL. Exact-identity gates now present on **all four** irreversible jobs (`hex-publish` publish/recovery + `recover-android-core`, `ios-mirror-backfill` `publish-ios-mirror` + `recover-ios-mirror`); `actionlint` clean |
| `script/check_release_version_truth.exs` | Tri-state published-vs-declared version guard | ✓ VERIFIED | New (168-10). 201+ lines, exits 0/1/2, wired at `crosswake-ci.yml:190`, documented in the runbook, 12 tests incl. FAIL and BLOCKED branches |
| `test/crosswake/proof/phase168_version_truth_test.exs` | Non-vacuous guard coverage | ✓ VERIFIED | New (168-10). 12 named tests covering OK/FAIL/BLOCKED, semantic ordering, tag-name filtering, and non-mutation |
| `.../evidence/phase168-entry-landing.json` | Exact five-blob landing receipt | ✓ VERIFIED | Present, tracked, committed |
| `.../evidence/phase168-candidate-refresh.json` | Protected-default + refreshed PR identity | ✓ VERIFIED | Was ⚠️ STALE. Now a bound input of the canonical receipt (`Candidate refresh SHA-256 e80f9e85…`), no longer a terminal artifact |
| `.../evidence/phase168-candidate-receipt.json` | Canonical exact-head READY FOR APPROVAL receipt | ✓ VERIFIED | Was ✗ MISSING. Tracked on `main`, 10090 bytes, SHA-256 `359ef8a5…6c78` = the constant in both publication workflows; byte-identical to `3c825ea2` |
| `.../evidence/phase168-candidate-receipt.md` | Maintainer dossier | ✓ VERIFIED | Was ✗ MISSING. Tracked, 7119 bytes, SHA-256 `7d39617e…1df3`, byte-identical to `3c825ea2` |
| `.../168-08-SUMMARY.md` | Plan 168-08 completion record | ✓ VERIFIED | Was ✗ UNTRACKED. Now tracked with a dated provenance appendix (168-13) that preserves the original text |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `script/release_candidate/hex_artifacts.sh` | `lib/crosswake/release_candidate/artifact.ex` | normalized manifest | ✓ WIRED | Unchanged; `artifact_test.exs` + `hex-publish.yml` exercise it |
| `lib/crosswake/release_candidate/coordinate.ex` | `release-please-config.json` | linked-versions group | ✓ WIRED | `release.version_graph.lockstep_core_native_only` OK |
| `script/release_candidate/ios_mirror.sh` | `lib/crosswake/release_candidate/mirror.ex` | normalized Git observations | ✓ WIRED | `mirror_test.exs` exercises baseline/candidate/publish/recovery |
| `.github/workflows/release-please.yml` | `hex-publish.yml` / `ios-mirror-backfill.yml` | approved head/tree/receipt propagation | ✓ WIRED | Was ⚠️ PARTIAL. Propagation now enforced on all four irreversible jobs |
| `.../evidence/phase168-candidate-receipt.json` | `ios-mirror-backfill.yml` + `hex-publish.yml` | `PHASE168_CANDIDATE_RECEIPT` SHA-256 | ✓ WIRED | Was ✗ NOT_WIRED. File digest equals the pinned constant at 4 comparison sites |
| `script/check_release_version_truth.exs` | `.github/workflows/crosswake-ci.yml` | `release-candidate-full-proof` step | ✓ WIRED | Line 190, ahead of candidate identity validation |
| `script/check_release_workflow_integrity.exs` | `.github/workflows/ios-mirror-backfill.yml` | `recovery.ios.exact_identity_gate` | ✓ WIRED | Job-block-scoped, order-aware, proven to fail at the red commit |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `phase168-candidate-receipt.json` | `identity.observed.*` | real captured CI run 34776247650 + rehearsal runs 34777036279 / 34777037998, all COMPLETED/SUCCESS at head `1051ab90…` | ✓ | ✓ FLOWING |
| `check_release_version_truth.exs` | newest published version | `git tag` history parsed semantically, compared to `.release-please-manifest.json` | ✓ — returns concrete `0.2.1` per component, and BLOCKED (never OK) when tags are unreadable | ✓ FLOWING |
| `recover-ios-mirror` gate | `PHASE168_*` | hardcoded pins that must equal dispatch inputs; digest traced to a real on-disk receipt | ✓ | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Release-candidate + version-truth Elixir suite | `mix test test/crosswake/release_candidate/ test/crosswake/proof/phase168_version_truth_test.exs test/mix/tasks/crosswake_release_candidate_test.exs test/mix/tasks/crosswake_release_status_test.exs` | **78 tests, 0 failures** (was 66) | ✓ PASS |
| Structural workflow integrity scanner | `elixir script/check_release_workflow_integrity.exs` | **67 OK / 0 FAIL, exit 0** | ✓ PASS |
| Recovery gate fail-first (non-vacuity) | same scanner in a detached worktree at red commit `0949020f` | `FAIL: recovery.ios.exact_identity_gate` | ✓ PASS (guard is real) |
| Version truth guard | `elixir script/check_release_version_truth.exs` | 3/3 OK, exit 0 | ✓ PASS |
| Receipt digest binding | `shasum -a 256 …receipt.json` vs `PHASE168_CANDIDATE_RECEIPT` | `359ef8a5…6c78` == constant | ✓ PASS |
| Receipt byte-for-byte recovery | `git show 3c825ea2:<path> \| shasum -a 256` | identical for both JSON and MD | ✓ PASS |
| Workflow YAML lint | `actionlint` on the four release workflows | no findings | ✓ PASS |
| Read-only release status (no network) | `mix crosswake.release.status` | 8/8 checks OK; candidate `BLOCKED` = "live not checked" (see advisory 1) | ✓ PASS |
| Read-only release status (live registries) | `mix crosswake.release.status --live` | candidate `COMPLETE`; `OK release.candidate_public_truth`; hex/ios/maven all public at 0.2.1 | ✓ PASS |
| PR #158 disposition | `gh pr view 158 --json state,mergedAt` | `CLOSED`, `mergedAt: null` | ✓ PASS |
| PR #163 disposition | `gh pr view 163 --json state,statusCheckRollup` | `MERGED` 2026-09-15T17:29:30Z, 49 checks, 0 failed | ✓ PASS |
| Exact-public clean-room, post-publication mode | (not run) | requires live registries + generated hosts | ? SKIP → human verification |

No release state was mutated by this verification: no publish, tag, push, dispatch, merge, or mirror write. The one worktree created for the fail-first check was detached, read-only, and removed with `git worktree remove --force` + `prune`. Uncommitted working-tree files were left untouched.

### Probe Execution

No `scripts/*/tests/probe-*.sh` exist in this repository and no PLAN/SUMMARY for phase 168 declares a probe path. The equivalent runnable checks for this phase are the two `script/check_release_*.exs` scanners, both executed above.

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
|-------------|-----------------|--------|----------|
| REL-01 | 168-04, 168-07, 168-08 | ⚠️ NEEDS HUMAN | Candidate-local proof verified; exact-public proof still unexercised against live registries — see behavior_unverified_items |
| REL-02 | 168-05, 168-06, 168-07, 168-08, **168-12** | ✓ SATISFIED | Was BLOCKED. CR-01 closed: gate present, ordered, complete, shape-constrained, CI-enforced, fail-first proven |
| REL-03 | 168-03, 168-06, 168-07, 168-08, **168-09, 168-10** | ✓ SATISFIED | 67/67 integrity checks + version-truth guard + release-status agreement |
| REL-04 | all 13 plans | ✓ SATISFIED | Was BLOCKED. Canonical receipt on `main`, digest-bound to four workflow gates, version truth restored |
| REL-05 | 168-01, 168-02, 168-06, 168-07, 168-08, **168-11, 168-13** | ✓ SATISFIED | Was BLOCKED. Maintainer dossier committed; CHANGELOG states published truth; forensics confirm every live publication ran through a gated job |

No orphaned requirements: REQUIREMENTS.md maps exactly REL-01 through REL-05 to Phase 168, and all five appear in at least one plan's `requirements:` frontmatter.

### Anti-Patterns Found

None. Scanned the files changed between `3804ffd7` and `02c6c838` (`crosswake-ci.yml`, `ios-mirror-backfill.yml`, `check_release_version_truth.exs`, `check_release_workflow_integrity.exs`, `phase168_version_truth_test.exs`, `CHANGELOG.md`, `COMPANION-PUBLISH-RUNBOOK.md`, `guides/install.md`, the receipt artifacts, and the 168-08 … 168-13 summaries) for `TBD|FIXME|XXX`. Zero debt markers; the only prior-noted `XXXXXX` matches are `mktemp` template strings, which are not debt markers.

### Human Verification Required

1. **Run the exact-public clean-room proof against the now-published companion family.** `script/verify_companion_cleanroom.sh`'s post-publication mode has only fixture-backed unit coverage in the repo; it has not been run against the real, now-live registries and no such run is captured as evidence. Trigger: the seven-step sequence in `docs/COMPANION-PUBLISH-RUNBOOK.md`. Expected: all five companion profiles install twice from exact registry sources with zero path locks, pass non-vacuous registration/Doctor checks, match the approved normalized digests, and end in a live-status `COMPLETE`. Why human: real-network, stateful, long-running; generates Phoenix hosts and resolves real registries — presence checks cannot see it.

   *Note:* the prior report's human-verification item 1 ("reconcile the already-live publication with the missing approval receipt") is **retired**. Both of its premises are now resolved — the receipt exists on `main` and is digest-bound to the gates, and the forensic pass established that all three publications ran through gated jobs (resolved_escalations[0]).

### Gaps Summary

**No gaps remain.** All three gaps from the 2026-09-15T18:00:00Z report are closed, each confirmed against the merged code rather than the summaries:

1. **CR-01 (SC2 / REL-02) — resolved.** The `recover-ios-mirror` job now proves the exact approved Phase 168 transaction before it checks out a dispatch-supplied ref and before `MIRROR_DEPLOY_KEY` is loaded. All six pinned constants are compared, not merely declared; the one input recovery genuinely cannot pin — the lease — is shape-checked to a 40-hex id distinct from the new ref rather than left free. A structural scanner check holds the gate, its ordering, and its completeness in place, and that check demonstrably FAILs at the pre-fix commit, so it is not a tautology.
2. **Canonical receipt (SC4 / SC5 / REL-04 / REL-05) — resolved.** The receipt JSON and Markdown are on `main`, byte-for-byte identical to the originals at `3c825ea2` (prohibition honored), and the JSON's SHA-256 is exactly the `PHASE168_CANDIDATE_RECEIPT` constant that four irreversible workflow jobs compare against. The chain that previously terminated at a stale refresh artifact now closes.
3. **Version truth (REL-03 / REL-04) — resolved.** `main` declares `0.2.1` everywhere the post-publication rollback had reverted it, the CHANGELOG names `0.2.1` as the published Hex release, PR #158 is closed unmerged so no duplicate 0.2.1 can be cut, and a tri-state guard with non-vacuous FAIL/BLOCKED coverage runs in `release-candidate-full-proof` so the same rollback-after-publish cannot silently recur.

One item remains outstanding and is the sole reason this report is `human_needed` rather than `passed`: the exact-public, post-publication clean-room proof (SC1 / REL-01) is present and wired but has never been exercised against the live registries. It is a genuine live-network judgment item, not a code defect.

---

_Verified: 2026-09-15T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
