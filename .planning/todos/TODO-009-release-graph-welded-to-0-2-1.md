---
id: TODO-009
title: The linked release graph is hardcoded to 0.2.1 and will not publish any later version
status: open
created: 2026-09-15
severity: high
surfaced_by: Phase 168 re-verification follow-up — automating the exact-public post-publication proof
relates_to: SEED-012, REL-01, REL-03, PROOF-01
---

# The linked release graph only works for 0.2.1

## Outcome

A linked release of any version publishes through the same approval-gated graph, proves itself
against the public registries afterwards, and rolls up `COMPLETE` — without a workflow edit per
release.

## The defect

`.github/workflows/release-please.yml` names `0.2.1` in 15 places, and five of them are job
`if:` conditions rather than cosmetic labels:

| Line | Job | Effect when version != 0.2.1 |
|---|---|---|
| 223 | `publish-hex` | skipped — nothing publishes to Hex |
| 525 | `publish-ios-core` | skipped |
| 571 | `publish-android-core` | skipped |
| 728 | `exact-public-proof` | skipped |
| 74-76 | `approved-release-guard` | literal `grep -q '@version "0.2.1"'` |

`lib/crosswake/release_candidate/workflow.ex:7-11` pins the same version into `@coordinates`
(`hex:crosswake@0.2.1`, etc.), so even a rollup that ran would describe the wrong coordinates.

So the next genuine release (0.2.2) would tag and then publish nothing, and the rollup would
report `PARTIAL` — correctly, but only because everything downstream was skipped.

## What is NOT wrong

Worth stating, because it constrains the fix:

- **The rollup is fail-closed.** `Workflow.rollup!/1` treats `skipped` as `!= "success"`, so a
  proof that silently does not run produces `PARTIAL`/`BLOCKED`, never `COMPLETE`. Silence is
  not read as success. Preserve this property.
- **The `exact-public` proof already exists and is already wired** to run automatically after
  publication (`release-please.yml:718`), invoking
  `verify_companion_cleanroom.sh --source-mode exact-public`. It is not missing; it is
  version-welded. It has never run because 0.2.1 published through the *recovery* path, and this
  job `needs:` the ordinary `publish-*` jobs.
- **The hardcoding was deliberate.** Phase 168's whole design is that exactly one approved
  transaction can publish. The pinned `PHASE168_*` identity constants are a safety property, not
  debt.

## The tension the fix must resolve

Generalizing the version must not generalize the *authority*. Today "only 0.2.1 may publish" and
"only the approved merge may publish" are enforced by the same literal. Splitting them means the
graph accepts any version while still binding each release to its own approved head/tree/base and
candidate receipt — the identity gate stays exact, the version stops being a constant.

Do not simply delete the `== '0.2.1'` comparisons. That would leave publication gated on
`linked_release` alone.

## Second gap: recovery publications skip the public proof

`exact-public-proof` depends on `publish-hex`/`publish-ios-core`/`publish-android-core`. A release
that completes through exact-ref recovery (as 0.2.1 did) never satisfies those `needs:`, so the
post-publication proof does not run for precisely the releases that took the unusual path and most
warrant proving. Recovery should converge on the same proof.

## Interim guard (landed 2026-09-15)

`release.version_weld.gates_match_declared_version` in
`script/check_release_workflow_integrity.exs` compares the version declared in
`.release-please-manifest.json` against the literal each version-gated job accepts. It is quiet
while they agree and FAILs the moment they diverge — i.e. on the 0.2.2 release pull request,
before it merges. Proof: `test/crosswake/proof/phase168_release_version_weld_test.exs`.

This converts the silent no-op publish into a loud, actionable CI failure. It does **not** fix
anything — the graph is still welded.

**Retire this check as part of closing TODO-009**, together with the literals it guards. Do not
weaken it to keep a bumped manifest green; that restores the exact failure mode it exists to
prevent. Its `welded == []` branch already tells a future reader this, and the coverage test
fails loudly if a fifth version-gated job appears.

## Breadcrumbs

- `.github/workflows/release-please.yml:718-763` — the `exact-public-proof` job
- `lib/crosswake/release_candidate/workflow.ex:4-19` — `@children`, `@coordinates`, `@dependencies`
- `script/verify_companion_cleanroom.sh:113-126` — `exact-public` needs `--approved-manifest`
- `script/check_release_workflow_integrity.exs` — where a "no bare version literal in a publish
  gate" check would belong
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — the operator contract that documents the seven-step sequence

## Observed firing on PR #164 (2026-09-15)

The interim tripwire was confirmed against its real target, not just fixtures. Running
`script/check_release_workflow_integrity.exs` over a manifest declaring `"0.2.2"` produces:

```
FAIL: release.version_weld.gates_match_declared_version - .release-please-manifest.json
declares "0.2.2" but the release graph is welded to ["0.2.1"] (publish-hex accepts 0.2.1;
publish-ios-core accepts 0.2.1; publish-android-core accepts 0.2.1; exact-public-proof
accepts 0.2.1). Those jobs would SKIP, so the release would tag and then publish NOTHING
```

PR #164 (`chore: release main`, proposing 0.2.2) fails CI with 8 red checks and cannot merge.
The guard holds.

### But the operator-facing message does not survive the trip

`release-candidate-fixtures` on #164 reports:

```
root/native publish jobs are not exact path-gated: missing scanner IDs:
release.outputs.paths_released, release.root_hex.path_gate, release.ios.path_gate,
release.android.path_gate
```

That is what a maintainer debugging #164 actually sees. It never mentions the weld, the
declared version, or `SEED-017`. `Crosswake.ReleaseStatus` classifies a scanner that exited
non-zero as *missing IDs* rather than surfacing the failing check's own message, so the
precise, carefully-worded diagnostic the tripwire emits is discarded exactly where it is
needed most.

This is a near relative of the defect class in the v22.0 retrospective. It is not absence
scored as success — the build does go red. It is **the right failure carrying the wrong
explanation**, which costs a maintainer the same debugging hour and invites the conclusion
that the scanner is broken rather than that the release is.

Fold into the `SEED-017` work: when `scanner_ids_result/2` receives a failed scanner, it
should propagate the failing check ids and their messages instead of reporting the required
ids as missing. See `lib/crosswake/release_status.ex:806-820`.
