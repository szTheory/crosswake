# Release Incident Response

This is the operator contract for recovering a release that has already gone wrong. It is not
pre-flight prose — that lives in [`docs/COMPANION-PUBLISH-RUNBOOK.md`](COMPANION-PUBLISH-RUNBOOK.md).
This document is for the moment a publish step just failed, or an operator suspects it did, and
needs to know what to do right now for Hex, the iOS SwiftPM mirror, or Maven Central.

**Mutation boundary.** Reading a registry, running `git ls-remote`, or running `gh run view` changes
nothing public. `mix hex.publish`, `mix hex.retire`, a push to the mirror's `main` or a mirror tag,
and a Maven Central upload each change public state. Every command below is marked by which side of
that line it is on.

**This document makes no version-specific claims.**

## Irreversibility summary

| Registry | Can the publish be walked back? | Real recovery |
|---|---|---|
| **Hex** | **No.** A published package version cannot be removed or replaced. `mix hex.retire` sets a forward-only advisory flag; it does not delete the version. | Retire forward with a reason, or publish a new version. Existing lockfiles continue to resolve the retired version regardless. |
| **iOS SwiftPM mirror** | **No, not fully.** A mirror tag can be re-pointed and `main` can be corrected, but that only changes what a *new* SwiftPM resolution sees. | Re-point the tag / correct `main` through the mirror's own recovery operation. Consumers who already resolved the old commit through SwiftPM's resolved-package cache are unaffected by the re-point — they keep the old commit until they explicitly re-resolve. |
| **Maven Central** | **No.** A coordinate is permanent the instant it reaches the `PUBLISHED` state. There is no delete, no retire, no overwrite. | Publish a new superseding version and document the defective one. A rehearsal deployment that only reached `VALIDATED` is the one exception — that state is safely `DROP`-able, but a real publish never stops at `VALIDATED`. |

## Mid-sequence partial failure

Every Detect cell below names a live registry response, a run conclusion, or a remote ref listing —
never "re-read the workflow to see whether it would have run." Re-reading the workflow definition
tells you what was *supposed* to happen, not what *did* happen; treating those as equivalent is this
milestone's named recurring defect (absence scored as success).

### Hex

| Detect | Decide | Command | Irreversibility |
|---|---|---|---|
| The dispatched publish job's run conclusion is `failure` and its logs show no `mix hex.publish` step reached completion. | No write occurred. Re-dispatch once the credential or environment problem is fixed. | `gh run view <run-id> --json jobs,conclusion` to confirm the failing step; re-dispatch `hex-publish.yml` with `operation: recovery` once fixed. | **Reversible.** No registry state changed; nothing to undo. |
| The job's logs show `mix hex.publish` started but the run's conclusion is not `success` (network drop, runner failure mid-upload). | Do not assume the upload landed either way. Query Hex directly before doing anything else. | `curl -sS https://hex.pm/api/packages/<pkg> \| python3 -c "import json,sys; print([r['version'] for r in json.load(sys.stdin)['releases']])"` — if the version is present, treat it as published and skip to the next row; if absent, re-dispatch recovery. | **Depends on the query result, not on guessing.** If the upload actually landed, it is **irreversible** from this point forward; if it did not land, nothing changed and the step is reversible. |
| `curl -sS https://hex.pm/api/packages/<pkg>` lists the version as a release. | The publish succeeded. Do not re-publish; `guarded_hex_publish.sh` already treats an exact already-live release as success (`already_live`) and continues to proof rather than erroring, so a second dispatch is safe but a no-op — it will not double-publish. | No corrective command needed; proceed to the next registry leg or to `exact-public-proof`. | **Irreversible.** The version is live; a published Hex release cannot be removed. |
| The published package is later found broken (bad artifact, wrong metadata, runtime crash on install) after `curl` already confirmed it live. | Do not attempt to overwrite or delete the version — Hex has no such operation. Retire it with a reason so `mix hex.info` and the registry UI warn installers, and publish a fixed version. | `mix hex.retire <pkg> <version> security --message "<what is broken>"` (or `deprecated`/`invalid`/`renamed`/`other` — see the reason table below), then publish the fix as a new version. | **Irreversible as a publish; the retirement flag itself is reversible.** The broken version stays live and resolvable forever; only the advisory flag can be reversed with `--unretire`. |
| `mix hex.publish` fails with a "version already exists" style error from the Hex API. | This is a duplicate-publish attempt, not a partial failure — either a previous run already succeeded (see row 2's `curl` check) or the version number was reused by mistake. Confirm via `curl` before touching anything else. | Same `curl` command as row 2. If the *content* differs from what was intended, the version number was reused in error; you must cut a new version — Hex will never let you overwrite an existing one. | **Irreversible.** The existing version at that number cannot be replaced under any circumstance; only a new version number is available going forward. |

### iOS SwiftPM mirror

| Detect | Decide | Command | Irreversibility |
|---|---|---|---|
| The `candidate-rehearsal` or `publish-ios-mirror` run's conclusion is `failure` before the `MIRROR_DEPLOY_KEY`-authenticated push step ran. | No write occurred against the mirror repo. Fix the credential or environment problem and re-dispatch. | `gh run view <run-id> --json jobs,conclusion` to confirm the push step never started. | **Reversible.** No ref on the mirror moved; nothing to undo. |
| The push step started (SSH agent loaded, `known_hosts` populated) but the run conclusion is not `success`. | Do not assume the mirror ref moved either way. Check the mirror repo directly. | `git ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios.git \| grep v<version>` — if the tag is present at the expected split SHA, the push landed; if absent, it did not. | **Depends on the query result.** If it landed, treat the mirror as published for that version (irreversible per the summary table above); if not, the attempt is reversible and can be retried. |
| `git ls-remote` confirms the tag exists at the correct split SHA and `main` has advanced. | The mirror publish succeeded. No further action for this leg. | None. | **Effectively irreversible for already-resolved consumers.** The tag can technically be re-pointed later, but any consumer who already ran `swift package resolve` against it keeps the old commit through SwiftPM's resolved-package cache regardless of what the tag points to next. |
| The mirror tag or `main` is later found to point at the wrong commit (wrong split, corrupted content) after `git ls-remote` already confirmed it live. | Correct it through the mirror's dedicated recovery operation — never a manual force push from a laptop. **As currently written, `recover-ios-mirror` in `ios-mirror-backfill.yml` validates its inputs against a single hardcoded approved transaction — the one landed for an earlier release — before it will touch the mirror at all.** It will refuse any other release's inputs. Using it for a later release's correction requires first landing that release's approved identity in the workflow's validation step — a reviewed code change, not a dispatch input — per `docs/COMPANION-PUBLISH-RUNBOOK.md`'s "Scope of the iOS mirror recovery mode." Recording this limitation here rather than describing a recovery path that does not yet exist for the release in question. | Land the new approved identity in `.github/workflows/ios-mirror-backfill.yml`, then dispatch `operation: recovery` with that identity's `--expected-old-ref`/`--expected-new-ref` pair via `script/release_candidate/ios_mirror.sh recovery`. | **Irreversible for already-resolved consumers, same as above.** Re-pointing corrects what *new* resolutions get; it does not reach anyone who already resolved the bad commit. |
| A dispatch of `publish-ios-mirror` or `recovery` fails because the target tag or ref already exists (duplicate-publish attempt). | The mirror publish path is a fast-forward/atomic push, not a force push, so a tag collision means either a prior run already succeeded (check `git ls-remote` as in row 2) or the version was reused. | Same `git ls-remote` command as row 2. | **Irreversible.** An existing tag on the mirror cannot be silently overwritten by the ordinary publish path; only the dedicated, identity-gated recovery operation can re-point it, and even then already-resolved consumers are unaffected. |

### Maven Central

| Detect | Decide | Command | Irreversibility |
|---|---|---|---|
| The Central Portal upload step fails before returning a deployment id (auth error, network error, malformed bundle). | No deployment was created. Fix the problem and re-dispatch. | `gh run view <run-id> --json jobs,conclusion` to confirm the upload step never returned a deployment id. | **Reversible.** Nothing was uploaded to Central; nothing to undo. |
| A deployment id was returned but polling `POST /api/v1/publisher/status?id=<id>` never reaches `VALIDATED` or `PUBLISHED` before the workflow times out. | The deployment exists in a transient state on Central's side. Poll it directly rather than re-dispatching blindly. | `curl -fsS -X POST -H "Authorization: Bearer <token>" "https://central.sonatype.com/api/v1/publisher/status?id=<deployment-id>"` — read `deploymentState`. If `FAILED`, the deployment is dead and safely ignorable; if `VALIDATED`, decide per the next rows; never re-upload the same coordinate while a deployment for it is still pending. | **Depends on the state read.** A `FAILED` or still-pending deployment that never reached `PUBLISHED` is **reversible** — it can be left alone or dropped. Once `deploymentState` reads `PUBLISHED`, it is **irreversible**. |
| `deploymentState` reads `VALIDATED` and this was a rehearsal (fire-drill), not a real release publish. | Free the coordinate; a `VALIDATED` deployment has not reached the immutability boundary. | `curl -fsS -X DELETE -H "Authorization: Bearer <token>" "https://central.sonatype.com/api/v1/publisher/deployment/<deployment-id>"` — this is the `android-publish-fire-drill` job's own documented step. | **Reversible, but only in this `VALIDATED` state.** Per `release-please.yml`'s own comment on this job: "immutability is scoped to `PUBLISHED` only; `VALIDATED` deployments are safely droppable." That affordance belongs to the rehearsal path and must never be read as meaning a real publish is droppable. |
| The coordinate is confirmed `PUBLISHED` (`curl -o /dev/null -w '%{http_code}' https://repo1.maven.org/maven2/<group>/<artifact>/<version>/` returns `200`) and is later found broken. | Do not attempt to delete, drop, or overwrite it — no such operation exists once `PUBLISHED`. Publish a new superseding version and document the defective one in the changelog. | No corrective command against the broken coordinate itself; the fix is publishing the next version through the ordinary pipeline. | **Irreversible.** The broken artifact stays at that coordinate forever; only a newer version can supersede it in practice, and it never removes the old one from the repository. |
| An upload attempt targets a coordinate that is already `PUBLISHED` (duplicate-publish attempt, version reused). | Central rejects the upload outright; there is no overwrite path. Confirm via the `repo1.maven.org` `200`/`404` check before assuming the retry will work. | `curl -sS -o /dev/null -w '%{http_code}\n' https://repo1.maven.org/maven2/<group>/<artifact>/<version>/` — a `200` means the coordinate is already live and a new upload will fail closed; cut a new version instead. | **Irreversible.** The existing published coordinate cannot be replaced under any circumstance. |

## Retire / backfill after a bad publish

Three subsections, one per registry. Each opens with a copy-runnable command block; the only values
that need editing are the package name and version, and neither appears as a bare literal outside a
fence anywhere in this document.

### Hex

```bash
mix hex.retire PACKAGE VERSION REASON --message "<human-readable explanation>"
```

- `REASON` must be exactly one of the tool's accepted values, each requiring its own `--message`:
  `renamed`, `deprecated`, `security`, `invalid`, `other`.
- Retirement is **advisory only**. The package and version remain resolvable and installable;
  `mix hex.info` and the Hex registry UI display the retirement message to anyone who looks, but
  nothing is removed and nothing stops working for consumers already pinned to that version.
- **Retirement is not a rollback of the publish and must never be treated as one.** The only way to
  reverse the advisory flag itself — not the publish — is:

```bash
mix hex.retire PACKAGE VERSION --unretire
```

### iOS mirror

```bash
bash script/release_candidate/ios_mirror.sh recovery \
  --version <VERSION> \
  --ref <RELEASE_REF> \
  --approval-receipt <RECEIPT> \
  --expected-old-ref <CURRENT_MIRROR_MAIN_SHA> \
  --expected-new-ref <CORRECT_SPLIT_SHA>
```

This is `recover-ios-mirror`'s underlying operation in `ios-mirror-backfill.yml`. As noted in the
matrix above, that job's validation step currently pins every input except `expected_old_ref` to a
single hardcoded approved transaction — the identity landed for the release it was originally built
for — and refuses anything else. That is a fact stated here because it changes what "just run
recovery" means for any later release: a new release's identity must be landed in the workflow first.

State plainly, because it is documented nowhere else in this repository: **re-pointing a mirror tag
does not un-resolve consumers who already fetched the old commit.** SwiftPM's resolved-package cache
holds the previously resolved revision on the consumer's machine. Moving the tag changes what a *new*
`swift package resolve` gets; it does not reach anyone who has already resolved the bad commit. There
is no remote un-resolve operation — the only mitigation is publishing the correction quickly and
communicating it, the same as any other software supply chain.

### Maven

```bash
# There is no retire or delete command for Maven Central. Recovery is always
# forward: publish a new, superseding version through the ordinary pipeline
# and document the defective coordinate (changelog, release notes, GitHub
# advisory if severity warrants it).
```

A coordinate is permanent the instant Central reports it `PUBLISHED`; per `release-please.yml`'s own
comment on the fire-drill job, "immutability is scoped to `PUBLISHED` only; `VALIDATED` deployments
are safely droppable." That `VALIDATED`-to-`DROP` path is the *rehearsal's* affordance for freeing a
coordinate before it ever reaches `PUBLISHED` — it does not apply to a real publish, which always
proceeds through to `PUBLISHED` and is never dropped. Reading rehearsal droppability as meaning a
real publish is droppable is the exact mistake this document exists to prevent.

For pre-flight procedure — the seven-step operator sequence, candidate authority, and the
five-states table for a release still in progress rather than already broken — see
[`docs/COMPANION-PUBLISH-RUNBOOK.md`](COMPANION-PUBLISH-RUNBOOK.md).
