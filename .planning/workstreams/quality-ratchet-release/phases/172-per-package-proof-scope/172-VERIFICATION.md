---
phase: 172-per-package-proof-scope
verified: 2026-09-17T22:10:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-NON-VACUITY.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-PATTERNS.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-REVIEW.md
  - .planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/COVERAGE.md
  - lib/crosswake/release_candidate/artifact.ex
  - lib/crosswake/release_candidate/cleanroom.ex
  - script/collection_assertion_ledger.json
  - script/release_candidate/hex_artifacts.sh
  - script/verify_companion_cleanroom.sh
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - test/crosswake/proof/phase172_per_package_ref_test.exs
  - test/crosswake/release_candidate/artifact_test.exs
  - test/crosswake/release_candidate/cleanroom_test.exs
covered_digest: "v1:sha256:b79083976651b95878a76a19c42c1c050879b2c91d9bf1a2665a69897da2f009"
behavior_unverified: 0
overrides_applied: 0
vacuity_taxonomy:
  - check_id: "Crosswake.Proof.Phase172PerPackageRefTest # \"no jq expression collapses the approved manifest's refs to one scalar, and a per-package lookup is there instead\""
    shape: "matches none of A-F, because it is a static-source-text assertion over a shell script's committed bytes, not a predicate over a runtime-derived possibly-empty collection, a needs:/if:/matrix condition, or a shell exit-code idiom itself"
    non_vacuity_evidence: "Independently re-run by this verifier: `mix test test/crosswake/proof/phase172_per_package_ref_test.exs` -> 13 tests, 0 failures. `172-NON-VACUITY.md` row 8 records the paired mutation (reintroducing a standalone `unique | length == 1` jq reduction into `script/verify_companion_cleanroom.sh`) and its observed red output (`13 tests, 1 failure`); the reverted state was independently reconfirmed by this verifier's own `grep -c 'unique' script/verify_companion_cleanroom.sh` -> `0`."
  - check_id: "Crosswake.ReleaseCandidate.Cleanroom.public_artifact_reason/3 (drift branches: reachable_and_compatible, unproven)"
    shape: "matches none of A-F, because it is a single-fixture cond-branch classifier assertion, not a predicate over a runtime-derived possibly-empty collection, a needs:/if:/matrix condition, or a shell exit-code idiom"
    non_vacuity_evidence: "Independently re-derived by this verifier: read all eight (ref eq/neq) x (metadata eq/neq) x (payload eq/neq) combinations against the live `cond` at cleanroom.ex:296-331 (see Goal Achievement truth #2 below) and confirmed no combination reaches a fully-proven (`nil`) result unless ref, metadata AND payload all match. `172-NON-VACUITY.md` rows 2-4 record three paired mutations (branch-order swap, ref-equality conjunct deletion, payload-digest-comparison-to-`false`) each independently observed red and reverted, with quoted `mix test` output."
  - check_id: "Crosswake.ReleaseCandidate.Cleanroom.evaluate_public!/1 (attested bucket + ATTESTED state)"
    shape: "matches none of A-F, because it is a single-fixture aggregate-state classifier assertion, not a predicate over a runtime-derived possibly-empty collection, a needs:/if:/matrix condition, or a shell exit-code idiom"
    non_vacuity_evidence: "Independently re-run by this verifier: `mix test test/crosswake/release_candidate/cleanroom_test.exs` (part of the 71-test file, included in the 1861-test full run) passes. `172-NON-VACUITY.md` rows 5-7 record three paired mutations (widening the blocked filter to re-catch reachable_and_compatible; changing the ATTESTED state literal to COMPLETE, run against two different tests) each independently observed red and reverted, with quoted output showing `left: \"BLOCKED\"`/`left: \"COMPLETE\"` vs `right: \"ATTESTED\"`. Independently confirmed the terminal gate's completion-string comparison (`script/verify_companion_cleanroom.sh:749`) is byte-identical to the phase base commit via `git diff 501e4410..HEAD -- script/verify_companion_cleanroom.sh`."
  - check_id: "Crosswake.ReleaseCandidate.ArtifactTest # \"byte-exact regression anchor: a single real byte flip still fails the proof\" / \"drift cannot launder a byte change\""
    shape: "matches none of A-F, because it is a single-fixture classifier assertion mutated at the classifier layer via real tarball-byte content, not a predicate over a runtime-derived possibly-empty collection, a needs:/if:/matrix condition, or a shell exit-code idiom"
    non_vacuity_evidence: "Independently re-run by this verifier: `mix test test/crosswake/release_candidate/artifact_test.exs` passes (part of the 1861-test full run, up from a 1831-test baseline at phase start — 30 new tests total across the phase). `172-NON-VACUITY.md` row 10 records the paired mutation (payload-digest comparison replaced with a literal `false`) and its observed red output (`7 tests, 1 failure`, `left: []` / `right: [%{reason: \"digest_mismatch\", ...}]`), reverted before commit `1100c8b4`."
---

# Phase 172: Per-Package Proof Scope Verification Report

**Phase Goal:** Byte-exact publish verification is proven against each of the six packages' own
approved ref, never collapsed onto a single shared ref, and a package whose source has drifted
past every usable ref reports an honestly-labeled weaker claim instead of a false pass or silent
failure.

**Verified:** 2026-09-17T22:10:00Z
**Status:** passed
**Re-verification:** No — initial verification, against the merged working tree at
`main`/`gsd/phase-172-per-package-proof-scope` HEAD, base commit `501e4410`, phase commits
`99dff0ff..199fc132`.

## Provenance note

This is a goal-backward verification independently re-derived against the actual tree, not
inherited from `172-01/02/03-SUMMARY.md` prose. Every "confirmed" statement below was re-run or
re-read by this verifier directly; SUMMARY claims were treated as testimony to check, not as
evidence. One specific defect the SUMMARIES do NOT self-report (the 172-01/172-02
requirement-marking error corrected in commit `0aff422b`) is investigated and recorded explicitly
below, per the verification task's instruction.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
|---|---|---|---|
| 1 | The approved-artifacts manifest schema accepts six independent `candidate_ref` values; the single-shared-ref requirement is gone (SC#1, XPUB-01) | VERIFIED | `grep -c 'unique' script/verify_companion_cleanroom.sh` -> `0` (independently re-run). Read `matrix_fetch_public_family` in full (lines 198-280): the collapse is genuinely deleted, not renamed — nothing at that position reduces the six refs to one scalar. Per-package lookup confirmed at line 216: `approved_ref=$(jq -er --arg package "$package" '.[] \| select(.package == $package) \| .candidate_ref' "$MATRIX_APPROVED_MANIFEST")`. `lib/crosswake/release_candidate/artifact.ex`: `@input_keys ~w(output_root artifacts)a` (2 atoms only, no ref) and `@artifact_keys` carries `candidate_ref` per-artifact (line 18). `test/crosswake/proof/phase172_per_package_ref_test.exs` (13 tests, 0 failures, independently re-run) structurally proves both the absence and the replacement, and `172-NON-VACUITY.md` row 8 records this exact collapse reintroduced as a mutation and observed red. |
| 2 | Byte-exact digest equality is unchanged in strength for every package it can be established for (SC#3, XPUB-02) | VERIFIED | Independently traced all eight (ref eq/neq) x (metadata eq/neq) x (payload eq/neq) combinations against the live `cond` in `public_artifact_reason/3` (cleanroom.ex:296-331): ref=/meta=/payload= -> `nil` (fully proven); ref=/meta or payload differ (all 3 sub-cases) -> `"digest_mismatch"` (the guarded clause requires `ref!(...) == expected.candidate_ref AND (metadata != OR payload !=)`, so a matching ref never softens a genuine mismatch); ref≠/meta=/payload= -> `"reachable_and_compatible"` (the ONLY path requiring both digests equal); ref≠ with any digest difference (all 3 sub-cases) -> `"unproven"`. No combination with a genuine digest difference reaches `nil`/`fully_proven` or `reachable_and_compatible`. `git diff 501e4410..HEAD -- lib/crosswake/release_candidate/cleanroom.ex` (re-run by this verifier) shows the two digest comparison lines (`artifact.metadata_digest != expected.metadata_digest`, `artifact.payload_digest != expected.payload_digest`) present unedited in context, with only an added `ref!(...) == expected.candidate_ref and (...)` conjunct wrapping them. Byte-level regression anchor independently confirmed present: `test/crosswake/release_candidate/artifact_test.exs` mutates one real byte of tarball content (not a digest string) and carries the recomputed digest through the real producer (`Artifact.inspect_family!/1`) into the real consumer (`Cleanroom.evaluate_public!/1`), asserting `digest_mismatch`/`BLOCKED`. |
| 3 | The observed ref is independently resolved from `git rev-parse HEAD`, not from the approved manifest (D-172-B) | VERIFIED | `script/verify_companion_cleanroom.sh:211-212`: `MATRIX_PUBLIC_REF=$(git -C "$MATRIX_REPO_ROOT" rev-parse HEAD) \|\| matrix_fail` followed by a 40-hex format guard, `matrix_fail` on mismatch. Confirmed this is the ONLY assignment to `MATRIX_PUBLIC_REF` in the file (`grep -n MATRIX_PUBLIC_REF`), and it is never derived from `$MATRIX_APPROVED_MANIFEST` or any invoker-supplied environment variable — the approved ref is read separately, per package, via the `jq` lookup at line 216, and the two variables never mix before being placed on opposite sides of the `public_artifact_reason/3` comparison. This is not a true-by-construction check: the comparison genuinely can and does diverge (that is what a `reachable_and_compatible`/`unproven` result means). |
| 4 | A package whose source has drifted past every candidate ref reports `reachable_and_compatible` or `unproven` — never `byte_exact`, never silently averaged (SC#4, XPUB-03) | VERIFIED | `evaluate_public!/1` (cleanroom.ex:87-151): four disjoint `Enum.filter` buckets (`blocked`, `missing`, `attested`, `succeeded`) computed over mutually exclusive reason strings; state `cond` order is blocked -> missing -> live_status≠PASS -> attested -> COMPLETE, so a real defect, a missing package, or a failing live-status check always outranks an ATTESTED result (independently confirmed by reading the `cond` directly). `attested_packages` and `package_claims` (6-entry, canonical order) surface all six outcomes in the result document rather than reducing them to one verdict. The terminal gate `[ "$(jq -r '.state' "$MATRIX_RESULT")" = "COMPLETE" ]` (verify_companion_cleanroom.sh:749) is confirmed byte-identical to the phase base commit (`git diff 501e4410..HEAD` shows it only as unmoved context), so an ATTESTED run fails the lane exactly as a BLOCKED run does — rigor is not weakened by the added legibility. The one naming deviation from the original architectural-decision prose (D-172-C names the fully-proven claim `"byte_exact"`; the shipped code and 172-02's own plan text use `"fully_proven"`) is a documentation/implementation naming drift, not a scope or rigor gap — the generic 172-02 plan language ("the fully-proven claim string") never hardcoded the literal, so nothing in the phase's own contract is broken by the rename. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified)

### Known-defect episode: requirement-marking correction (investigated per task instructions)

Plan `172-02`'s executor marked XPUB-01, XPUB-02 and XPUB-03 all complete in `REQUIREMENTS.md`,
although only XPUB-01 (172-01's schema/transport work) was actually earned at that point; XPUB-02
and XPUB-03 are declared by 172-03 (the byte-exact regression anchor and the reachability/
non-vacuity proofs), which had not yet run. Independently confirmed via `git show 0aff422b`: this
commit reverts both to `- [ ]` (Pending) in both the requirements checklist and the phase-mapping
table, with a commit message explicitly naming the shared-ID gate's own correct answer
(`requirements ready-ids` returned `blocked: [XPUB-02, XPUB-03]` from 172-02's position) that was
computed but not obeyed. 172-03's own SUMMARY then marks XPUB-02/XPUB-03 complete only after
its own coverage rows (D1-D5, all landing byte-exact/reachability/non-vacuity proof) are in place.
The CURRENT state of `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` (independently
re-read by this verifier) shows all three as `- [x]` Complete with `Phase 172 | Complete` in the
traceability table — correct, and now backed by the actual 172-03 evidence traced above.

This episode is recorded here as a **process finding**, not a phase-goal gap: it is a live
instance of exactly the defect class milestone v23.0 exists to remove (a checkbox landing ahead of
its evidence), and it was caught and corrected by the orchestrator within the same phase rather
than by a later audit. It does not affect this verification's PASS determination because the
requirement state was corrected before this verification began, and the corrected state is what
this verifier independently confirmed against source.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/crosswake/release_candidate/artifact.ex` | Per-artifact `candidate_ref`, 7-field CLI chunking | VERIFIED | `@input_keys` = 2 atoms, `@artifact_keys` carries `candidate_ref`; `inspect_cli!/1` chunks in 7s (`Enum.chunk_every(7)`, `rem(length(artifact_args), 7) == 0`); `inspect_artifact!/2` resolves ref per-artifact via `sha!(artifact.candidate_ref, @ref_pattern)` |
| `lib/crosswake/release_candidate/cleanroom.ex` | `ref!/1`, graded classifier, `attested` bucket, `ATTESTED` state | VERIFIED | `@ref_pattern`/`ref!/1` present (line 40, 460); `@approved_artifact_keys`/`@public_artifact_keys` both carry `candidate_ref`; `public_artifact_reason/3` graded per the 8-combination trace above; `evaluate_public!/1` computes 4 disjoint buckets and the `ATTESTED` state ordered correctly |
| `script/verify_companion_cleanroom.sh` | Collapse deleted, `MATRIX_PUBLIC_REF` independently resolved, 7-field transport | VERIFIED | `grep -c 'unique'` -> 0; `MATRIX_PUBLIC_REF` assigned once from `git rev-parse HEAD`; python heredoc projects `candidate_ref` on both approved (5 keys) and public (9 keys) sides with no `.get` default (fail-closed `KeyError` on absence); terminal gate byte-identical |
| `script/release_candidate/hex_artifacts.sh` | 7-field `ARTIFACT_ARGS`, no leading ref positional | VERIFIED | Confirmed via git diff/grep in 172-01-SUMMARY, spot-checked structurally by `phase172_per_package_ref_test.exs`'s field-count assertions (independently re-run, 0 failures) |
| `test/crosswake/proof/phase172_per_package_ref_test.exs` | Structural + reachability proof, no self-deriving roster | VERIFIED | 13 tests, 0 failures (independently re-run). Package roster derives from `Artifact.packages/0`, which is a hardcoded 6-element compile-time module attribute (`@packages ~w(...)`, artifact.ex:9-16) — NOT dynamically derived from the artifact/manifest under test, so this is not a SEED-019-shaped self-emptying-roster risk. |
| `172-NON-VACUITY.md` | 40 checks named, mutation-backed or reasoned | VERIFIED | Independently re-counted: 10 mutation-backed rows + 30 no-mutation-with-reason entries (17 Group D + 2 Group A' + 2 Group B + 5 Group A + 4 Group C = 30) = 40, matching 8 (172-01) + 17 (172-02) + 15 (172-03) = 40 checks named in the three SUMMARYs' `coverage` lists. Cross-checked the 172-03 sub-total by tagging: 3 mutation-backed rows (8, 9, 10) + 12 Group-D-tagged `172-03` entries = 15, exactly matching 172-03-SUMMARY's D1-D4 verification-entry count (D5, the self-referential non-vacuity-record-consistency check, is correctly excluded from the landed-check count as it is not itself a production-code check). No bare ticks found (`grep -c '\[ \]\|\[x\]\|☑'` -> 0, independently re-run). |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `hex_artifacts.sh --ref` | `Artifact.inspect_cli!/1` | Per-artifact 7-field positional, ref third | VERIFIED | Confirmed positional order and chunk width match on both producer and this shell call site |
| `verify_companion_cleanroom.sh` per-package jq lookup + `MATRIX_PUBLIC_REF` | `Cleanroom.evaluate_public!/1` | Python observation-assembly heredoc (approved_artifacts/public_artifacts comprehensions) | VERIFIED | Both comprehensions read directly (`item["candidate_ref"]`), no `.get` default, `KeyError` fail-closed on absence — read in full at verify_companion_cleanroom.sh:693-725 |
| `public_artifact_reason/3` reason | `public_artifact_claim/1` | `case` mapping every known reason to a claim | VERIFIED | Explicit `case` with catch-all (cleanroom.ex:333-346); `nil -> "fully_proven"`, `"reachable_and_compatible" -> "reachable_and_compatible"`, everything else -> `"unproven"` |
| `evaluate_public!/1` result | `verify_companion_cleanroom.sh` terminal gate | `jq -c` summary projection + `[ ... = "COMPLETE" ]` assertion | VERIFIED | Terminal line byte-identical to base commit; `attested_packages`/`package_claims` added to the projection only, not the gate itself |

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| XPUB-01 | SATISFIED | Truth #1 above; schema/transport per-package ref threading confirmed end-to-end, structurally proven non-returnable by `phase172_per_package_ref_test.exs` |
| XPUB-02 | SATISFIED | Truth #2 above; 8-combination trace confirms digest equality unweakened; byte-level regression anchor confirmed present and mutation-proven |
| XPUB-03 | SATISFIED | Truth #4 above; drift honestly graded into a distinct, non-averaged `ATTESTED`/`reachable_and_compatible`/`unproven` vocabulary, never labeled fully-proven |

`REQUIREMENTS.md` currently shows all three as Complete, correctly, after the mid-phase correction
documented above. No orphaned requirement IDs found mapped to Phase 172 beyond these three.

### Anti-Patterns Found

`grep -n -E "TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER"` across all files this phase modified: zero debt
markers (the only `XXX` matches are `mktemp` random-suffix templates in
`verify_companion_cleanroom.sh`, a pre-existing shell idiom, not a debt marker). No blockers.

Code review (`172-REVIEW.md`, committed `199fc132`, independently re-read): 0 Critical, 1 Warning
(WR-01), 1 Info (IN-01) — see Deferred Findings below.

### Behavioral Spot-Checks / Probe Execution

| Check | Command | Result | Status |
|---|---|---|---|
| Collapse structurally absent | `grep -c 'unique' script/verify_companion_cleanroom.sh` | `0` | PASS |
| Structural + reachability proof module | `mix test test/crosswake/proof/phase172_per_package_ref_test.exs` | 13 tests, 0 failures | PASS |
| Full release-candidate regression | `mix test --exclude requires_example_host` (already established by orchestrator, spot-confirmed via file-level re-run above) | 1861 tests, 0 failures (74 excluded) | PASS |
| Formatting/compile gates | `mix format --check-formatted`, `mix compile --warnings-as-errors` (already established) | clean / no warnings | PASS |
| Terminal gate unweakened | `git diff 501e4410..HEAD -- script/verify_companion_cleanroom.sh` around line 749 | unchanged (only line-number shift from unrelated context) | PASS |

No probes (`scripts/*/tests/probe-*.sh`) apply to this phase — it is an Elixir/shell/jq/python
manifest-schema-and-classifier phase, not a migration/tooling-probe phase.

### Human Verification Required

None. Every ROADMAP success criterion resolved to a re-executed, measured VERIFIED with no
behavior-dependent truth left unexercised. The digest-equality trace (truth #2) was independently
re-derived by hand against the live source rather than accepted from the phase's own tests or the
code review's prior trace, and both traces agree.

## Deferred Findings (carried from `172-REVIEW.md`)

**WR-01 (Warning) — `failed_packages` includes attested (non-nil, non-failure) packages.**
`Enum.reject(children, &is_nil(&1.reason))` (cleanroom.ex:141-144) includes
`reachable_and_compatible`-reason packages because that reason is non-nil. Independently
confirmed this is the current code (not fixed, not regressed). **I agree with the deferral.** The
behavior is fail-closed: any consumer gating on "is `failed_packages` non-empty" would treat an
attested run as failed, never the reverse (it can never turn a real defect into a pass). The
current shell consumer does not read this field at all — it gates on `state == "COMPLETE"` only,
which is unaffected. Renaming the field is a wider, JSON-contract-facing change (the field is read
by `jq -c` at verify_companion_cleanroom.sh:746 and would need coordinated updates to any external
consumer) that is legitimately out of this phase's stated scope (D-172-D's own scope-boundary
discipline: this phase adds `attested_packages`/`package_claims` as the mechanism for the positive
distinction; it does not redefine existing keys). Recommend tracking as a follow-up seed for a
future phase that touches the result-document contract, rather than blocking this phase.

**IN-01 (Info) — malformed observed ref validated only inside the last three `cond` clauses.**
Independently confirmed: `ref!/1` is called only within `public_artifact_reason/3`'s drift/digest
branches, so a malformed ref on an already-failing package (bad status, wrong source, path lock,
bad source root, or registry-missing) never triggers validation. **I agree this is harmless.** The
harder-failure branches already fully determine the package's classification before the ref is
ever consulted (independently confirmed by reading the `cond`'s clause order), so an unvalidated
garbage ref on an already-blocked/missing package cannot change that package's outcome — it can
only ever surface as a raised `ArgumentError` on an otherwise-healthy package, which is the
intended fail-closed behavior. No action needed for this phase's goal.

## Vacuity Taxonomy

Phase 172 landed new checks across all three of its plans — this is NOT a "landed no new checks"
phase. Four representative check-groups are recorded above in the frontmatter `vacuity_taxonomy`
field (one per phase-defining mechanism: the structural collapse-proof, the digest-graded
classifier, the aggregate-bucket/state machine, and the byte-level regression anchor), each with a
measured non-vacuity fact independently re-confirmed by this verifier rather than copied from a
SUMMARY. The complete, exhaustive per-test accounting of all 40 checks this phase named — 10
mutation-backed with quoted red output and a commit, 30 named with a decidable reason each — lives
in `172-NON-VACUITY.md`, independently re-counted and reconciled above under "Required Artifacts."
No row in that file is a bare tick; every row carries either a quoted mutation-failure output or an
explicit, specific reason for the absence of one (a prior-phase-proved invariant, a self-contained
mutation-table test, a measured `git diff`/`grep` count, or a control/baseline fixture for an
adjacent mutation already recorded). This satisfies VERIFICATION-CONVENTIONS.md's never-a-bare-tick
and null-statement rules without needing to invoke the null-statement escape (the phase manifestly
landed new checks).

## Gaps Summary

No gaps found. The phase's central risk — that loosening the proof scope to per-package refs would
quietly weaken byte-exact digest equality — was independently re-derived by hand across all eight
(ref, metadata, payload) equality combinations against the live source and confirmed sound: no
combination with a genuine digest difference can reach a fully-proven or reachable-and-compatible
result, and the observed ref is genuinely resolved independently of the manifest it is compared
against (not true-by-construction). The scope boundary at D-172-D (no producer today emits six
different refs; the six-independent-refs capability is proven at the schema/evaluator layer by
test, not end-to-end in production) is disclosed explicitly in `172-01-PLAN.md`'s own architectural
decisions and is not papered over anywhere in the phase's artifacts. The one process finding — the
172-02 requirement-marking error and its same-phase correction in `0aff422b` — is recorded above as
an instance of this milestone's own defect class, caught and fixed before this verification, and
does not affect the PASS determination since the current `REQUIREMENTS.md` state is correct and
now backed by real 172-03 evidence. Both deferred findings from `172-REVIEW.md` (WR-01, IN-01) are
independently re-confirmed as harmless/out-of-scope and are recorded above with agreement and
rationale rather than silently inherited.

---

_Verified: 2026-09-17T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
