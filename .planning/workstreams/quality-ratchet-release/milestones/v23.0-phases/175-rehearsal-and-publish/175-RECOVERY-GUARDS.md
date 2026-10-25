# Phase 175 Recovery Guards

**Status:** structural proof complete; no workflow dispatch or external mutation performed.

This record covers the local, mutation-tested guards added after the Maven rehearsal
altered the release candidate it was meant to observe. It does not claim a fresh
candidate, registry upload, or physical workflow execution.

## Declared scanner roster

The scanner reads a nonempty two-workflow surface:

1. `.github/workflows/release-please.yml` — push-driven ordinary release graph.
2. `.github/workflows/maven-publish-fire-drill.yml` — manual disposable Maven rehearsal.

Both files are direct scanner inputs: a missing file makes `File.read!/1` fail before
the scanner can report a green result. The isolated-drill guard also requires the
dedicated job, `workflow_dispatch`, disposable `FIRE_DRILL_VERSION`, Central Portal
`USER_MANAGED` upload, `VALIDATED` observation, and `DROP` request.

## Seed-red and green coverage

| Check ID | Decision | Seed mutation (raise-on-no-op) | Observed red result | Final green result |
|---|---|---|---|---|
| `release.rehearsal.maven_isolated` | D-36 | Append `maven-publish-fire-drill` to Release Please; inject `googleapis/release-please-action` or `gh pr create` into the dedicated workflow. | Scanner exits nonzero and reports this ID as `FAIL`. | Scanner reports this ID as `OK`; Release Please has no manual Maven route and the dedicated workflow retains `VALIDATED -> DROP`. |
| `release.recovery.receipt_exact_authority` | D-34 | Change canonical receipt cardinality from exact-one to `-ge 1`; replace each head, tree, or base comparison. | Scanner exits nonzero and reports this ID as `FAIL` for every mutation. | Scanner reports this ID as `OK`; only one unexpired receipt bound to exact head/tree/base is accepted. |
| `release.recovery.no_retry_or_bypass` | D-37 | Insert `gh run rerun`, `gh workflow run`, `retry_failed`, or `individual-registry` beside the guard. | Scanner exits nonzero and reports this ID as `FAIL` for every mutation. | Scanner reports this ID as `OK`; no dispatch, rerun, retry, or individual-registry bypass surrounds ordinary receipt authority. |

The fixture helpers write every seed from real workflow text and raise when a target
cannot be found, so no mutation can silently become an unmodified green fixture.

## Verification

Completed locally:

```sh
MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs \
  test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1
elixir script/check_release_workflow_integrity.exs
```

The focused suite passed (11 tests, 0 failures) and the structural scanner completed
with a nonempty declared check roster and zero failures.

## External-state statement

No GitHub workflow was dispatched. No pull request was created or changed. The historic
run was not retried. No Hex, iOS mirror, Maven Central Portal deployment, registry
coordinate, or remote release state was touched while producing this record.
