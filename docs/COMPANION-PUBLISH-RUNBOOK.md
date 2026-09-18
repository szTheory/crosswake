# Companion Publish Runbook

This is the operator contract for the Crosswake release candidate carrying `approved-release-guard`'s
approval. It keeps the three linked coordinates together, keeps all five companions independently
versioned, and separates reversible evidence from publication. The status and candidate commands are
read-only: neither command publishes, pushes a ref, merges a pull request, or changes a registry.

**This document makes no version-specific claims.**

## Candidate authority

The linked release unit is exactly:

- Hex `crosswake` at the approved version;
- SwiftPM mirror tag `refs/tags/v<approved version>` for `crosswake-shell-core-ios`;
- Maven `io.github.sztheory:crosswake-shell-core-android` at the approved version.

The five `crosswake_*` Hex packages are independent companions. Their current versions and
`crosswake` floors are evidence, not members of the linked approval. Companion pull
requests are excluded from this runbook.

| Package | Required `crosswake` floor |
|---|---|
| `crosswake_rulestead` | `~> 0.2` |
| `crosswake_rindle` | `~> 0.2` |

The exact Release Please head, tree, merge base, workflow blobs, artifact digests, run identity,
and credential checks form the candidate identity. A branch name, a moving pull-request head,
or a successful test count without those bindings is not candidate evidence.

## Exact seven-step operator sequence

### 1. Land the exact five-blob stack

Land the reviewed five-blob dependency stack in its recorded order. Re-read the five blob IDs
from the phase evidence and verify that the candidate base contains each one. If any blob is
missing, reordered, or replaced, stop with `BLOCKED`; do not refresh the candidate.

### 2. Refresh and capture the candidate

Refresh the one Release Please candidate only after all reversible changes have landed. Capture
the full 40-character lowercase head SHA, tree SHA, merge base, and the exact release workflow
blobs. A later push makes the prior capture `STALE` and requires a new capture.

Read local and public truth without mutation:

```bash
mix crosswake.release.status
mix crosswake.release.status --json
mix crosswake.release.status --live
```

### 3. Build and unpack all six packages

From the captured checkout, build and officially unpack the root package plus five companions.
The output directory must not exist before the command starts.

```bash
bash script/release_candidate/hex_artifacts.sh \
  --ref <40sha> \
  --output-dir <new-artifact-directory> \
  --manifest <new-artifact-manifest.json>
```

Success means exactly six non-empty payloads with normalized metadata and payload digests. Zero
packages, an omitted package, an in-repository unpack root, or a changed checkout blocks the
candidate.

### 4. Run candidate-local clean rooms

Run all five host profiles twice from the unpacked candidate artifacts:

```bash
bash script/verify_companion_cleanroom.sh \
  --source-mode candidate-local \
  --artifact-manifest <artifact-manifest.json> \
  --result <new-cleanroom-result.json>
```

Success means six packages, five profiles, two isolated installs per profile, positive public
surface assertions, deliberate negative controls, and zero path-lock leaks. `candidate-local`
proves the reversible payloads; it does not prove that any public registry serves them.

### 5. Run the trusted mirror rehearsal

Use the existing trusted iOS release workflow candidate-rehearsal operation at the captured SHA.
The ordinary pull-request workflow stays credential-free. Only the trusted job may check the
scoped deploy key, and it must record `credentials_exercised=true`,
`authorization_result=AUTHORIZED`, and `external_state_changed=false`. The rehearsal computes the
mirror commit with `git subtree split` over the iOS package path and validates the push with a dry
run; it must not push either ref. The split SHA is deterministic for a given source tree, which is
why the rehearsal's SHA and the publish's SHA are comparable.

### 6. Review the exact receipt

The candidate evaluator consumes normalized artifact, clean-room, coordinate, workflow, mirror,
identity, and credential observations and writes one bounded receipt:

```bash
mix crosswake.release.candidate --version 0.2.1 --ref <40sha> --output-dir <new-receipt-directory>
```

Review `candidate-receipt.json`, its Markdown and terminal projections, and the retained CI and
trusted-workflow artifacts. The receipt must bind the captured head/tree/base and exact workflow
digests, contain non-zero six-package/five-profile proof, report
`credentials_exercised=true`, and still report `external_state_changed=false`. Each projection
must give one next action and must not include credentials, raw remote output, account data, or
private URLs.

### 7. Approve one exact-head merge

The Release Please merge is the single approval boundary. Approve only when the receipt says
`READY FOR APPROVAL` and the pull-request head still equals the captured 40-SHA. That approval
authorizes the fixed post-merge linked graph; it does not authorize companion releases, ref
replacement, unrelated recovery, or a second approval shortcut.

## Five states and one correction

| State | Meaning | One next action |
|---|---|---|
| `BLOCKED` | Required evidence, identity, or authorization is absent or unverifiable. | Repair the named prerequisite and rerun only its owner. |
| `STALE` | Head, tree, base, workflow, or observation no longer matches the capture. | Refresh and recapture the whole exact candidate. |
| `READY FOR APPROVAL` | Every reversible proof and credential rehearsal passed with no external mutation. | Approve the one captured exact-head merge. |
| `PARTIAL` | Approval occurred and at least one linked coordinate is public while another is not complete. | Recover only the named missing coordinate from its exact approved ref. |
| `COMPLETE` | All three linked coordinates and exact-public proof agree with the approved receipt. | Preserve the receipt; take no publication action. |

Never average mixed results into success. Output names one state, one bounded reason, and one next
action. `PARTIAL` retains every proven public success and never rolls it back to make the graph
look atomic.

## Candidate-local versus exact-public proof

`candidate-local` installs from the six officially unpacked local tarballs before approval. It
proves payload content and host compatibility without registry or mirror write authority.

`exact-public` runs only after publication. It fetches the approved six package digests from the
public sources, repeats the five profiles, and requires live linked-coordinate truth. Cached,
repository-local, or merely configured coordinates cannot satisfy exact-public proof.

A release completing through exact-ref recovery does not run `exact-public-proof` at all,
because that job `needs:` the ordinary publish jobs. The previously approved candidate shipped
this way, which is why the post-publication proof has never executed.

The read-only status surface shows the recorded mirror baseline and the candidate public ref
separately. `missing` is a definite public absence; `unavailable` is an unknown after
bounded retries. Both fail closed for linked candidate truth, but the operator copy must not call
an unavailable probe a confirmed absence.

## Ordinary publication and recovery

Ordinary publication is the fixed postapproval Release Please graph: guarded root Hex, iOS
mirror, and Android Maven children followed by exact-public proof and a linked rollup. It uses the
approved merge parent and identical tree; it never selects a mutable branch name. The iOS mirror
child computes the mirror commit with the same `git subtree split` invocation the rehearsal used
at step 5, so the recovery path and the ordinary path cannot diverge in mechanism.

The ordinary publication path never doubles as recovery. Recovery is reachable only after a
`PARTIAL` receipt. It preserves coordinates already proven
public, selects one failed coordinate, and uses that coordinate's exact approved ref. iOS ordinary
publication is atomic fast-forward publication; iOS recovery alone may use the separately
approved exact force-with-lease contract. Hex and Maven artifacts are immutable and must not be
replaced. A lost public success, ambiguous ref, or mismatched receipt blocks recovery.

### Scope of the iOS mirror recovery mode

The `recovery` operation of `ios-mirror-backfill.yml` is the only mode that can
replace the public mirror's `main` with a leased force push. It is bound to the
single approved Phase 168 transaction and to nothing else.

Its first step validates the exact approved identity — release version, merge
OID, approved head, tree, and base, the candidate receipt digest, and the
expected new ref — against values hardcoded in the workflow. That step runs
**before** the checkout of the supplied ref and **before** `MIRROR_DEPLOY_KEY`
is loaded, so an unauthorized dispatch stops without reaching credentials or
running any code from the ref it supplied.

The lease (`expected_old_ref`) is the one input that is not pinned. Recovery
exists because mirror `main` has diverged to a commit that cannot be known in
advance, so the lease is constrained by shape — a 40-character lowercase object
id, distinct from the new ref — rather than by value. It is never accepted
unconstrained.

**A future release that needs to recover the mirror must land a new approved
identity in the workflow first.** The gate will refuse a dispatch carrying any
other transaction, and that refusal is correct: re-pointing it is an approval
decision that belongs in a reviewed change, not in dispatch inputs. The
`recovery.ios.exact_identity_gate` check in
`script/check_release_workflow_integrity.exs` fails closed if the gate is ever
removed or reordered behind the checkout or the credential load.

`git subtree split` is the durable mechanism for computing the mirror commit in both the
ordinary and recovery paths; the previously used external splitter is not to be reinstalled or
referenced going forward.

### Verifying declared version truth after a recovery

Run:

```
elixir script/check_release_version_truth.exs
```

It compares each linked core component's declared version in
`.release-please-manifest.json` against the newest matching published tag
(`hex-v`, `ios-core-v`, `android-core-v`).

| State | Exit | Meaning |
|-------|------|---------|
| `OK` | 0 | Declared version is at or ahead of published truth. Ahead is the normal pre-release state. |
| `FAIL` | 1 | **Declared version truth is behind published truth.** |
| `BLOCKED` | 2 | Published truth could not be established. The answer is *unknown*, not clean. |

This script's `BLOCKED` stays exit `2` — a separate, unchanged vocabulary from
`mix crosswake.release.status`, which uses exit `3` for the same could-not-verify meaning. The two
commands are not interchangeable; see [`mix crosswake.release.status` exit-code
contract](#mix-crosswakereleasestatus-exit-code-contract) below for the canonical release-status
table.

**A `FAIL` is the condition that armed a duplicate release proposal against an
already-published version.** It happens when a release merge is rolled back to
restore an earlier version so Release Please can re-form a candidate, but
publication then completes anyway through exact-ref recovery against the
already-created tag, and the rollback is never undone. Release Please then
correctly re-proposes the published version off the stale manifest; merging that
proposal would attempt to tag over an immutable public tag and republish a live
package. Recover forward: restore declared truth to the published version across
the manifest and its sibling coordinate files, **then** close the stale release
pull request. Never move a published tag or replace a published artifact.

**A `BLOCKED` means release tags were not visible**, typically a shallow
checkout carrying no tags. Re-run with full history (`git fetch --tags`, or a
checkout with `fetch-depth: 0`). Do not read `BLOCKED` as clean.

This guard runs automatically in the `release-candidate-full-proof` job, which is
release-sensitive and already checks out with `fetch-depth: 0`.

## `mix crosswake.release.status` exit-code contract

The canonical exit-code table for `mix crosswake.release.status` lives in one place:
`Crosswake.ReleaseStatus.exit_code/1`'s `@doc`, reachable via `h Crosswake.ReleaseStatus.exit_code/1`
in `iex`, in generated ExDoc, and on hexdocs. This runbook links to it rather than copying it, so
the two never drift apart.

In one sentence: a clean run exits `0`, a run that ran and found a defect exits `1`, and a run that
could not verify exits `3`. `mix crosswake.release.status` now reaches real exit `3` when it could
not verify — for example when the release workflow scanner crashed before finishing. **Do not read
exit 3 as a pass.**

## CI ownership

The existing `Crosswake CI` family always runs stable artifact, coordinate, mirror, clean-room,
workflow, receipt, and package fixtures. Release-sensitive tracked inputs and the refreshed
Release Please candidate additionally run the credential-free six-artifact/five-profile full
matrix against the exact pull-request head. Checkout, object, diff, unknown-classification,
zero-count, stale-head, omitted-leaf, or missing-receipt ambiguity routes to more proof or fails.

The real credentialed mirror rehearsal stays in the trusted release workflow. One-time live
reconciliation stays in phase evidence; it is not a permanent CI lane.

## Explicit exclusions and privacy

- Android breadth is excluded: the existing linked Maven coordinate is checked, but no Android
  feature, generator, JVM, vector, parity, or device scope is added.
- first-adopter activation is excluded; this is infrastructure release proof, not adopter rollout.
- Companion pull requests are excluded; companion versions and floors remain independent.
- Candidate evaluation does not publish, merge, tag, push, open issues, or repair public state.
- Background or generic sync, commerce productionization, dashboards, native UI breadth, and
  brand/showcase work remain excluded.
- Raw answers, media, transcripts, credentials, tokens, account identifiers, stable device IDs,
  private URLs, and proprietary adopter information must not enter status, receipts, artifacts,
  logs, or summaries.

If evidence cannot make one bounded claim without exposing those values, record `BLOCKED` and
name the safe owner to rerun. Do not paste the sensitive input into the correction.
