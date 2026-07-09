# Companion Publish Runbook

This runbook describes the current package-family release operating model for
Crosswake Hex packages. The publish path is now guarded CI automation, not a
maintainer's local `mix hex.publish` loop.

## Current Operating Model

The Release Please Release PR merge is the human approval boundary. After that
merge, CI owns the happy-path publish path for every package Release Please says
was released.

For Hex packages, the release workflow routes root `crosswake` and all five
`crosswake_*` companions through `script/guarded_hex_publish.sh`:

- `crosswake`
- `crosswake_rulestead`
- `crosswake_rindle`
- `crosswake_sigra`
- `crosswake_chimeway`
- `crosswake_threadline`

The helper verifies the checked-out package/version, checks the exact Hex.pm
package release endpoint, and then chooses one of two states:

- Exact package/version is already live: report success, skip publish, and let
  proof continue.
- Exact package/version is not live: run deps, compile, tests, dry-run, publish,
  and poll until Hex.pm reports the exact version.

Core Hex, iOS core, and Android core remain the only lockstep release group.
Companion packages remain independently versioned Release Please components.

## Already-Live State

Hex packages are immutable after the public release window. Treat an exact live
package/version as registry state, not as a failed duplicate publish.

Expected already-live success copy:

```text
[crosswake] OK: crosswake_sigra 0.1.1 is already live on Hex.pm; no publish attempted. Continuing to proof.
```

Expected fail-closed copy:

```text
[crosswake] FAIL: Hex.pm returned HTTP 500 for crosswake_sigra 0.1.1.
[crosswake] What to do next: Retry after confirming Hex.pm status; do not publish until registry identity can be checked.
```

The important operator facts are package, release ref, version, registry state,
live artifact, proof, cleanup PR, and the next safe command. Do not rely on
prose scraping for machine state; helper outputs include `package`, `version`,
`publish_state`, `hex_release_url`, and `checked_sha` for later status tooling.

## Manual Recovery

Manual dispatch is exact-ref Hex recovery and fire-drill only. It is not the
happy path and should not be used when the Release Please publish train is
healthy.

Use the `Hex publish (manual recovery)` workflow with:

- `package`: one of the six Hex packages listed above.
- `ref`: either a full 40-character lowercase commit SHA or an explicit
  `refs/tags/vX.Y.Z` release tag ref.
- `release_version`: the expected package version at that ref.

The workflow rejects branch-shaped and bare version-looking refs before
checkout, including `release/v0.2.0`, `feature/v0.2.0`,
`refs/heads/release/v0.2.0`, bare `v0.2.0`, `main`, and `master`. It prints the
checked-out SHA before calling the guarded helper.

Recovery remains Hex-only in Phase 143. SwiftPM mirror recovery, Maven Central
recovery, and the missing iOS `v0.2.0` mirror backfill are native-registry
operations with their own guarded path below.

## iOS Mirror Backfill

The canonical path for the missing SwiftPM mirror tag is verify-first:

```bash
script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0
```

Verification mode does not require `MIRROR_PUSH_TOKEN` and does not mutate the
public mirror. Mutation is explicit:

```bash
script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 --apply
```

The operator wrapper is the `iOS mirror backfill` workflow. It exposes
`version`, `release_ref`, `apply`, and `update_main` inputs and delegates the
release identity, split, registry, and tag checks to the script.

Expected states:

- Exact already-present mirror tag: `[crosswake] OK`, exit 0, no push.
- Missing mirror tag in verify-only mode: `[crosswake] OK`, exit 0, next action
  names the apply command/workflow.
- Mismatched mirror tag: `[crosswake] FAIL`, exit nonzero, no automatic delete or
  move of `refs/tags/v0.2.0`.

Before any apply-mode mutation, the script verifies root Hex `crosswake 0.2.0`,
Android Maven `io.github.sztheory:crosswake-shell-core-android:0.2.0`, the
lockstep Release Please refs (`hex-v0.2.0`, `ios-core-v0.2.0`,
`android-core-v0.2.0`), and `.release-please-manifest.json` version truth.
Rerunning the original release workflow is not the primary recovery path because
Hex and Maven coordinates are immutable once live; use the backfill path to
repair only the missing SwiftPM mirror tag.

## Companion Floors

Mixed floors are intentional release truth:

| Hex package | Requires `crosswake` |
|---|---|
| `crosswake_rulestead` | `~> 0.1` |
| `crosswake_rindle` | `~> 0.1` |
| `crosswake_sigra` | `~> 0.2` |
| `crosswake_chimeway` | `~> 0.2` |
| `crosswake_threadline` | `~> 0.2` |

A companion that needs a newer core API bumps its own floor in its own release.
Do not preemptively constrain older-compatible companions to a newer core line.

## Release Status

Use the release-status task for the current read-only operator view:

```bash
mix crosswake.release.status
mix crosswake.release.status --json
mix crosswake.release.status --live
```

Default status reads checked-in source, release config, package files, workflow
guards, and scanner evidence only. It does not call public registries, GitHub
APIs, or workflow artifacts. Use `--json` when CI or issue tooling needs the
stable machine contract; consumers should key on `code`, `status`, `source`,
`next_action`, and structured component fields, not prose.

Use `--live` only when public registry presence matters. Live probes are
advisory and distinguish `ok`, `missing`, and `unavailable` for Hex, Maven
Central, and the SwiftPM mirror. A `missing` result means the exact artifact or
tag was checked and absent. An `unavailable` result means network, registry, or
tooling state prevented an honest absence claim.

The status task is read-only. Mutation stays in the guarded release surfaces:
`script/guarded_hex_publish.sh`, the Release Please publish jobs,
`script/verify_ios_mirror_backfill.sh`, and the `iOS mirror backfill` workflow.

## Required Check Boundary

The `publish-hex-*` and `clean-room-proof-*` jobs are post-merge release jobs.
They are skipped on normal PRs and MUST NOT be registered as required PR checks.
Registering them would deadlock ordinary PRs waiting for statuses that cannot
run before merge.

Keep merge-blocking proof on the semantic workflow checks and source tests. The
post-merge publish/proof jobs are release execution evidence, not PR gates.

## Historical Phase Boundaries

Phase 143 owns the guarded automatic Hex publish train and exact-ref Hex
recovery.

Phase 144 owns clean-room exactness completion: exact just-published companion
installs, derived core floors, and fresh-router doctor loading.

Phase 145 owns native registry recovery and parity: SwiftPM mirror credential
preflight, Maven/SwiftPM recovery semantics, native proof decoupling, and iOS
mirror backfill through `script/verify_ios_mirror_backfill.sh` and the
`iOS mirror backfill` workflow.

## Irreversible Registry Warning

Once `mix hex.publish` completes, the package version is public registry state.
Do not retry a failed release by forcing an overwrite path. First check whether
the exact version is already live. If it is live, continue to proof or recovery
verification. If identity cannot be proven, stop and inspect the release ref,
GitHub release/tag, Hex.pm package page, and workflow logs before retrying.
