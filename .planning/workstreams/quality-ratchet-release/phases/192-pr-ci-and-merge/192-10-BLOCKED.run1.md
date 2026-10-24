# Phase 192 Plan 10: BLOCKED (cause: other_prs_changed)

## What was checked and what happened

After the merge I ran the post-merge proof and the first half of the phase gate.

Passed:
- Task 1 (post-merge proof): `postmerge: main green`, and the plan's own verify passes under `sh`. Two parents (main first, tested head second), merge-commit tree equals the tested synthetic merge, Release Please succeeded, its guard succeeded, 16 of 16 publish-class jobs skipped, baselines (releases, tags, six Hex versions) byte-equal to before. See It Run Collateral was still in progress and is recorded as advisory.
- Task 2 steps so far: protection read `required set ok`; remote has no carry-trial or candidate-src refs; tags unchanged; land branch absent (GitHub's merged-branch setting).

Failed:
- Task 2 step 4b. The open-PR list after the merge differs from open-prs-before-192.txt on five PRs other than the Release Please PR: #210, #211, #239, #240, #241 (all Dependabot). Their numbers, branch names and OPEN state are unchanged; only their head commits are new. #238 is unchanged. The plan's rule sets aside only the Release Please PR (#236, whose refresh is also seen), so it requires BLOCKED other_prs_changed.

## Why this looks like an expected Dependabot response, not a change by this phase

GitHub shows each of those five heads as a Dependabot commit made at 23:42:03 to 23:42:17 UTC, about three minutes after the merge at 23:39:29 UTC. The one I checked (#240) has the new merge commit as its parent. That is Dependabot rebasing onto the moved main. This phase made no write to those PRs (gh-writes-192.txt holds only the one create, one bound merge and the one recorded rerun).

This is my reading of the evidence. The plan's gate does not allow it, so I did not weaken the gate myself.

## Not done

Not run: the rest of Task 2 (phase-gate-192.txt, privacy-10-192.txt) and all of Task 3 (handoff edits, recovery after-snapshot). No SUMMARY written.

Written (plain files): baselines-after-192.txt, postmerge-192.txt, remote-refs-192.txt, open-prs-after-192.txt in 192-EVIDENCE.

## Decision needed

Either amend the gate to also set aside Dependabot-branch head refreshes (with `release_please_pr`-style recording, e.g. `dependabot_prs rebased`), or accept this as the recorded finding. Then re-run Task 2 from step 5 and Task 3. Nothing on GitHub needs to change.
