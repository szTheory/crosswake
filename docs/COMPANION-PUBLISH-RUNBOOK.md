# Companion Publish Runbook

This is the operator contract for the Crosswake `0.2.1` release candidate. It keeps the
three linked coordinates together, keeps all five companions independently versioned, and
separates reversible evidence from publication. The status and candidate commands are
read-only: neither command publishes, pushes a ref, merges a pull request, or changes a registry.

## Candidate authority

The linked release unit is exactly:

- Hex `crosswake 0.2.1`;
- SwiftPM mirror tag `refs/tags/v0.2.1` for `crosswake-shell-core-ios`;
- Maven `io.github.sztheory:crosswake-shell-core-android:0.2.1`.

The five `crosswake_*` Hex packages are independent companions. Their current versions and
`crosswake` floors are evidence, not members of the linked `0.2.1` approval. Companion pull
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
`authorization_result=AUTHORIZED`, and `external_state_changed=false`. The rehearsal may inspect
the recorded `v0.2.0` baseline and dry-run the `v0.2.1` split; it must not push either ref.

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

The read-only status surface shows the `v0.2.0` mirror baseline and the candidate public ref
`v0.2.1` separately. `missing` is a definite public absence; `unavailable` is an unknown after
bounded retries. Both fail closed for linked candidate truth, but the operator copy must not call
an unavailable probe a confirmed absence.

## Ordinary publication and recovery

Ordinary publication is the fixed postapproval Release Please graph: guarded root Hex, iOS
mirror, and Android Maven children followed by exact-public proof and a linked rollup. It uses the
approved merge parent and identical tree; it never selects a mutable branch name.

The ordinary publication path never doubles as recovery. Recovery is reachable only after a
`PARTIAL` receipt. It preserves coordinates already proven
public, selects one failed coordinate, and uses that coordinate's exact approved ref. iOS ordinary
publication is atomic fast-forward publication; iOS recovery alone may use the separately
approved exact force-with-lease contract. Hex and Maven artifacts are immutable and must not be
replaced. A lost public success, ambiguous ref, or mismatched receipt blocks recovery.

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
