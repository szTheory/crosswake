---
phase: 191-integration-branch-and-local-suite
plan: 10
status: blocked
cause: unexpected_red
land_v25_v27_moved: false
---

# Phase 191 Plan 10: BLOCKED (unexpected_red)

## In plain words

The five planning-carry commits were built on the trial branch `carry-trial` and the first four checked out exactly as expected. The fifth (v27.0) is not green. Two tests fail at that commit, and so does `mix crosswake.adoption_context.scan`, for one reason: the carried file `191-RESEARCH.md` (Phase 191's own research record) contains an awk field reference (a dollar sign directly followed by two digits), which the first-adopter context scanner reads as a money amount (rule `privacy.commercial_detail`). Nothing is wrong with the carry tool or the other 2,600 or so carried files. `land/v25-v27` has not moved; it is still the RESOLVER commit.

## Failing check

- Subset gate at v27.0 (`EV/suite-CARRY-v27.0.txt`): 951 tests, 2 failures, both in `Crosswake.Planning.FirstAdopterContextTest`: "live registered artifacts scan clean while the Phase 158 review remains discovered" and "public and durable scans enforce the phrase split with stable rule and path violations". Both name one path, the 191-RESEARCH.md record, and the one rule.
- `mix crosswake.adoption_context.scan` at the v27.0 head exits 1 with the same single finding.
- Cause (closed list): `unexpected_red`.

The scanner rule matches `$` followed by digits in prose files. Lines 177 and 423 of 191-RESEARCH.md quote an awk field written as `$` plus `10` while explaining the earlier Phase 189 finding. The Phase 189 plan files get the braced form from the `dollar` rows in `carry-table-191.tsv`; 191-RESEARCH.md has no such row. Other Phase 191 files that mention `$` plus a digit are not flagged (checked: only this file trips the rule).

## Suggested fix (needs a decision, not done here)

Either (a) add a `dollar A,M` row for the 191-RESEARCH.md path to `carry-table-191.tsv` (same mechanical `$NN` to `${NN}` rewrite already used for the three Phase 189 plans, A-6), or (b) reword the two lines in the recovery working-tree copy. Then re-cut on a new trial branch (`carry-trial-2`) and rerun the five commits. Plan 12's sync will meet the same rule for any later Phase 191 record that spells `$` plus a digit (this plan's own SUMMARY/BLOCKED files avoid it).

## What was completed and what is intact

- Pre-cut checks passed: recovery git state unchanged; 5 main-side planning additions (Phase 175) all byte-identical in the recovery tree; 0 planning paths in the code commits; label consistent (`v27.0 Land and Clean Up (Phases 189 to 193) - in progress` in STATE, REQUIREMENTS.md header and PROJECT.md heading).
- Cut manifest (base = MAIN_SHA): exit 0, 0 unmatched, 0 ignored-not-excluded, 0 symlinks. Delta A 2525, M 13, D 141; excluded 46; same-path identical 1767 (358 with a pattern, untouched); moved 120 untransformed + 4 transformed; transformed 244; buckets v23.0 1781, v24.0 189, v25.0 258, v26.0 177, v27.0 274. manifest_sha256 `f53b728aaff94dc7bae6ee6b6c5849ba8f18ea07e991790cae174b63c54d6101` (kept in run folder `cut` plus `EV/carry-manifest-191.tsv`).
- Carry commits on `carry-trial` (parent of v23.0 is the RESOLVER commit `70fada0d`), each only under `.planning/`:
  - v23.0 `3d2d2f47269c3d071471f09b59bef98c2a24e4ee` (1648 files; R100 pairs 115 = expected_pure_moves 115; transformed_moves 4)
  - v24.0 `1e83a500a3cc852c969a715bc52b19bcd98e5708`
  - v25.0 `9179a927b7f1e9a50f1f72f6116b4ebb6002e621`
  - v26.0 `6692a683409a3f8707829445f551adfa13d93a6a`
  - v27.0 `28a48db77583e4b502ae76b8f219ef343884fae1`
- Subset gate: v23.0 to v26.0 pass with exactly the two A-1 allowed red tests (`EV/carry-expected-red-191.txt`); v27.0 fails as above.
- Other planning-sensitive checks at the v27.0 head: `phase167_pr_dispositions` JS test exit 0; integrity script exit 0; ledger `--check` exit 0; adoption scan exit 1 (same finding).

## Not done (because the plan stops at the failed check)

Independent floor and `carry-191.sh verify`, the privacy pre-check scan, the fast-forward of `land/v25-v27`, and the final check-line records. `carry-floor-191.sh` was written (syntax-checked only by design review; not yet run).

## Deviations to know before the retry

1. The plan's subset path list omits `test/crosswake/release_candidate/evidence_live_test.exs`. Without it, two Phase175LinkedAuthorizationTest tests fail with `EvidenceLiveTest.fixture/1 is undefined` (a test-selection effect, not a carry effect). I added that file as a fifth subset path (floor 5) for every carry run.
2. `suite-gate-191.sh` counts the nested ExUnit failure header printed inside the Phase135 derived assertion as an extra failure, so it stops with `failure names unparsed` whenever the A-1 derived assertion fires. I ran a patched copy from the run folder (`gatepatch/`, header match anchored to two-space indent); the committed script is unchanged. It needs the same one-line fix before Plan 12 if used at any red commit.
3. The A-1 allowed set was written as the two full ExUnit names (`test ... (Module)`), which is the form the gate compares.
4. Every manifest-listed source file must stay byte-stable between cut and the v27.0 apply (apply re-hashes). Phase 191 evidence files that are in the manifest (`heads-191.txt`, `scan-triage-191.tsv`, `carry-precut-191.txt`) were therefore NOT appended to during the run; carry heads and commit lines are kept in the run folder (`heads-carry.txt`, `commits-carry.txt`) and are listed above. `carry-precut-191.txt` holds only the five pre-cut lines and `cut_time`. They must be appended after the final carry commit.
5. A-14: no terms were loaded and no scan was run yet. The actual chain has 11 labels with PRIVACY after G1; RESOLVER `70fada0d` is the parent of v23.0.
6. The 191-02 dry run (base = the durable candidate) and this cut (base = MAIN_SHA) differ: A 2525 vs 2474 and v27.0 274 vs 223, since more Phase 191 files exist now and the base differs.
7. Trailer used: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, as the plan specifies.

Commit in the recovery checkout: none (D-23).
