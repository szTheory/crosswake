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

## Breadcrumbs

- `.github/workflows/release-please.yml:718-763` — the `exact-public-proof` job
- `lib/crosswake/release_candidate/workflow.ex:4-19` — `@children`, `@coordinates`, `@dependencies`
- `script/verify_companion_cleanroom.sh:113-126` — `exact-public` needs `--approved-manifest`
- `script/check_release_workflow_integrity.exs` — where a "no bare version literal in a publish
  gate" check would belong
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — the operator contract that documents the seven-step sequence
