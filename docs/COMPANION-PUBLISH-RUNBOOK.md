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
recovery, and the missing iOS `v0.2.0` mirror backfill belong to Phase 145.

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

## Required Check Boundary

The `publish-hex-*` and `clean-room-proof-*` jobs are post-merge release jobs.
They are skipped on normal PRs and MUST NOT be registered as required PR checks.
Registering them would deadlock ordinary PRs waiting for statuses that cannot
run before merge.

Keep merge-blocking proof on the semantic workflow checks and source tests. The
post-merge publish/proof jobs are release execution evidence, not PR gates.

## Phase Boundaries

Phase 143 owns the guarded automatic Hex publish train and exact-ref Hex
recovery.

Phase 144 owns clean-room exactness completion: exact just-published companion
installs, derived core floors, and fresh-router doctor loading.

Phase 145 owns native registry recovery and parity: SwiftPM mirror credential
preflight, Maven/SwiftPM recovery semantics, native proof decoupling, and iOS
mirror backfill.

Phase 146 owns full release-status DX: local text output, JSON output, optional
live registry probes, and any issue-opening automation.

## Irreversible Registry Warning

Once `mix hex.publish` completes, the package version is public registry state.
Do not retry a failed release by forcing an overwrite path. First check whether
the exact version is already live. If it is live, continue to proof or recovery
verification. If identity cannot be proven, stop and inspect the release ref,
GitHub release/tag, Hex.pm package page, and workflow logs before retrying.
