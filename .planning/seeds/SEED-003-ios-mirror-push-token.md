---
id: SEED-003
status: harvested
planted: 2026-07-03
planted_during: "Phase 141 core-first publish — core crosswake 0.2.0 went live on Hex + Android Maven, but the iOS mirror push failed"
trigger_when: "Surface before the next native shell-core release, when doing a release/CI-infrastructure hardening pass, or as soon as an iOS native adopter needs to resolve crosswake-shell-core-ios >= 0.2.0."
scope: Small
resolved_on: 2026-10-26
resolved_by: "quality-ratchet-release Phase 195 (REL-06): mirror tag v0.2.11 present with tree identity; deploy-key push; merge-blocking parity gate"
---

# SEED-003: Fix the iOS mirror push token (MIRROR_PUSH_TOKEN) so shell-core-ios publishes on release

## Why This Matters

The `Mirror iOS core to split repo` job in `.github/workflows/release-please.yml` splits `packages/crosswake-shell-core-ios` with `splitsh-lite` and pushes the subtree + a `v<version>` tag to the standalone mirror repo `github.com/szTheory/crosswake-shell-core-ios.git` — that tag is what SwiftPM resolves for iOS native adopters.

At the **core 0.2.0 publish (2026-07-03)** this job **failed 403**:

```
remote: Permission to szTheory/crosswake-shell-core-ios.git denied to github-actions[bot].
fatal: unable to access '.../crosswake-shell-core-ios.git/': The requested URL returned error: 403
```

The job pushes with the default `github-actions[bot]` `GITHUB_TOKEN`, which has no write access to the **separate** mirror repo. So:
- ✅ Core `crosswake 0.2.0` published to **Hex** and **Android Maven Central**.
- ❌ **iOS SwiftPM `0.2.0` was never tagged/pushed** to the mirror repo — iOS native adopters cannot resolve `crosswake-shell-core-ios >= 0.2.0`.

This is the long-standing **"MIRROR_PUSH_TOKEN scope unexercised"** note finally exercised. It did **not** block the v17.0 Hex companion family (those are Elixir packages depending on core Hex).

## When to Surface

**Trigger:** before the next native shell-core release, during a release/CI-infra hardening pass, or when an iOS adopter needs `crosswake-shell-core-ios >= 0.2.0`.

## What To Do

1. Create/scope a PAT (or fine-grained token / GitHub App installation token) with **push** access to `szTheory/crosswake-shell-core-ios`; store it as a repo secret (e.g. `MIRROR_PUSH_TOKEN`).
2. Wire it into the `Mirror iOS core to split repo` job's `MIRROR_TOKEN` (replace the default `GITHUB_TOKEN`). Do the same audit for the Android/other mirror jobs if they rely on the default token.
3. **Backfill 0.2.0**: after the token works, re-run the mirror job for the `hex-v0.2.0` release, or manually `splitsh-lite --prefix=packages/crosswake-shell-core-ios` and push the subtree + `v0.2.0` tag, so iOS 0.2.0 is resolvable.
4. Add a proof/guard so a future mirror-push 403 fails loudly (or alerts) rather than silently leaving iOS a version behind.

## Scope Estimate

**Small** — a token/secret configuration + one workflow wiring change + a one-time 0.2.0 backfill. No product code.

## Resolution

Closed on measured evidence, not on token rotation. The record is `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/seed003-mirror-tag-195.txt`.

- The mirror carries `refs/tags/v0.2.11`, and its tree equals the monorepo tree of `ios-core-v0.2.11:packages/crosswake-shell-core-ios` (tree identity: yes).
- The 403 came from pushing with the default `GITHUB_TOKEN`. The `publish-ios-core` job now pushes over SSH with the `MIRROR_DEPLOY_KEY` deploy key.
- The merge-blocking parity lane (`script/check_ios_mirror_parity.sh`) is the loud-failure guard asked for in item 4; it passed (rc 0) in the evidence run.
- The `MIRROR_PUSH_TOKEN` rotation route (items 1 and 2) was not executed, and stays on the do-not-re-open list.
- `script/verify_published_cleanroom.sh 0.2.11` also builds the mirror tag with `swift build` from a clean directory (`cleanroom-0.2.11-195.txt`).
