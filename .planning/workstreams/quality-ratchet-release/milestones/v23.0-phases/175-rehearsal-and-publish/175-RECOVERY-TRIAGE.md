# Phase 175 — Read-Only Recovery Triage

**Observed:** `2026-09-24T01:54:23Z`  
**Disposition:** `PARTIAL` for core `0.2.3`; `CANDIDATE_FOR_FULL_PREFLIGHT` for PR #201 / `0.2.4` only.

## 0.2.3 current state

Release Please run `35898407350` completed with overall `failure` on merge
`4df029d3799d2db18003471019c42126878572f8`. The approved-candidate guard, Release Please, and
Hex publish jobs succeeded; the iOS mirror and Maven publish jobs failed; exact-public proof skipped;
the linked release rollup failed. These are workflow outcomes, not registry results.

The separately authorized iOS recovery run `35926844126` completed successfully on the PR #200 merge
`3a74c59dde3c3e59dced18ed693c42d081687368`. Direct observations are independent:

| Registry | Exact coordinate | Current observation | Result |
| --- | --- | --- | --- |
| Hex | `crosswake@0.2.3` | Package release list includes `0.2.3` | Present |
| iOS mirror | `refs/tags/v0.2.3` | Ref resolves to `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, matching the exact approved 0.2.3 rehearsal split | Present |
| Maven Central | `io.github.sztheory:crosswake-shell-core-android:0.2.3` POM | HTTP `404` | Publicly absent |

No Maven Central deployment ID or local Portal credentials are available for a read-only deployment
status query. The Portal's internal deployment state is therefore `UNKNOWN`; the public `404` does
not establish whether a deployment was created or what its internal state is.

The exact Gate 2 response `publish fresh core 35809832762` was consumed by PR #196's one ordinary
`0.2.3` graph. It is not reusable for a retry, Maven recovery, PR #201, or any later version. The iOS
recovery was a distinct, separately authorized transaction and does not authorize Maven recovery.
No workflow dispatch, failed-job retry, historic-run retry, tag movement, merge, or publish was
performed here. REL-10 remains historically **BREACHED** at Gate 1; later ancestry evidence cannot
retroactively repair it.

## Maven recovery authority

The checked-in route confirms **0.2.3 recovery is not supported** by `recover-android-core`. It pins package
`crosswake` to merge `b780a19863936619394087f1ffd384f1dca17c93`, approved head
`1051ab90cf75e918c6f596f84578ac77eadf45af`, approved tree
`ecf63228243bfe7c2d6a377be996aa374b31d91f`, and candidate receipt
`359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78`. The workflow checks this
identity before checking out trusted recovery tooling at
`e089bfc0e8a4edf0b024a2a284c8a384216bd64d` and the immutable payload. The 0.2.3 merge/head/tree
and receipt do not match that Phase 168 transaction. A matching version or public `404` is not
recovery authority. Read-only verification: inspect the `recover-android-core` job in
`.github/workflows/hex-publish.yml`, `script/release_candidate/android_publication.sh`, then run
`elixir script/check_release_workflow_integrity.exs`.

## REL-12 verification

Plan 175-07 records `requirements-completed: [REL-12]` and
`status: complete_with_historical_incident`. Independently re-queried Release Please run
`35461665164`: overall, `Publish crosswake_rulestead to Hex.pm`, and
`Clean-room proof — crosswake_rulestead resolvability + doctor` all concluded `success`. The direct
Hex package API still lists `crosswake_rulestead@0.1.1`. REL-12 remains complete; this does not alter
REL-10's separate historic breach.

## PR #201 / 0.2.4 candidate status

At the observation time, PR #201 is open and non-draft, targets `main`, and proposes `0.2.4` on the
exact Release Please branch `release-please--branches--main`. Live remote base/head refs match
`3a74c59dde3c3e59dced18ed693c42d081687368` /
`2fdf71b917e3538c6ecc74d1894602e82926281e`; the head tree is
`57491062742dc18aa1daec33bb8068844a193851`. The PR is `MERGEABLE` / `CLEAN`, and compare reports
zero commits behind. Crosswake CI run `35927192087` completed successfully for that exact head;
GitHub reports 49 successful checks, zero failures, and zero pending. The live strict branch policy
requires `Crosswake CI`. The runbook ancestry verifier passed independently for both exact base and
head OIDs. Direct queries found all three 0.2.4 coordinates absent: Hex `crosswake@0.2.4`, iOS
`refs/tags/v0.2.4`, and the exact Maven Central POM (HTTP `404`).

PR #201 `0.2.4` is `CANDIDATE_FOR_FULL_PREFLIGHT` only. This is eligibility for Plan 175-19 to run
its own full fresh preflight and rehearsal; it is not Gate 2 readiness, a merge instruction, or publish
authority. It is not publish authorization; no Gate 2 preparation or authorization is emitted here. The 0.2.3 release remains an
honest partial until its Maven coordinate and any exact recovery authority are separately resolved;
the newer candidate is not evidence of 0.2.3 publication.
