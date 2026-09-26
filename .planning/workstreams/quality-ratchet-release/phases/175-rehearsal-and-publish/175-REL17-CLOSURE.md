# REL-17 Publication Control Closure

Plan 175-36 closes the local control implementation for release creation, ordinary publication, recovery, companion publication, and final script mutation boundaries. The same operation-bound REL-17 validator is invoked at each boundary after job setup and again immediately before the external side effect. `GH_TOKEN` is passed into each final publisher step so the fresh live read can execute.

The approved-release guard accepts exactly one `REL17-AUTHORIZATION: <one-line JSON>` trailer from the immutable protected merge message. It checks the trailer's exact key set, operation, package, version, candidate OIDs, receipt and CI run/artifact selectors, policy fingerprint, runbook commit, and typed authorization string. It publishes the compact context to downstream jobs only after a fresh post-merge gate pass. Unclassified or mixed version changes fail before Release Please runs.

The context loader rejects stale or mismatched tuples before writing runner state. Its consumed authorization file is created under a private umask with mode 0600. Linked release is core-only; companion publication is package-scoped; recovery is limited to the six exact Hex package identities, with Maven and iOS recovery remaining core-scoped. The legacy Phase 168 iOS mirror entry checks out trusted current-main tooling separately from its pinned payload and re-fetches evidence before SSH credentials. Its historical receipt alone cannot pass the new gate.

## Mutation Coverage

The scanner declares 17 REL-17-specific checks inside its full 98-check exact roster. It covers the approved guard, Release Please action, three ordinary core jobs, three recovery jobs, the legacy iOS mirror entry, five companion jobs, and Hex/iOS/Maven final script boundaries. ExUnit mutations remove each ordinary, recovery, and companion job gate; remove final Hex, both iOS push, and Maven gates; omit a companion job; remove a declared REL-17 roster member; remove final-step `GH_TOKEN`; reorder Release Please's gate; and remove the unclassified-version fail-closed branch. Every mutation changes its fixture and fails its named check.

Authorization-context tests accept complete linked-release and recovery contexts, all six recovery package identities, all five companion package identities, and Chimeway's exact third-leg selector. Changed merge OIDs, changed policy fingerprints, consumed old authorization, and operation substitution block before `$GITHUB_ENV` or the authorization file is written. Pure and live validator tests confirm the same package/operation scope.

## Verification Evidence

All commands ran locally. No workflow dispatch, merge, registry mutation, mirror push, or human UAT was performed.

```text
$ elixir script/check_release_workflow_integrity.exs
[crosswake] OK: release.scanner.roster_exact - emitted 98 check IDs match the declared @roster_ids exactly
[crosswake] DONE: 98 of 98 roster checks emitted; 0 failed.
exit 0

$ MIX_ENV=test mix test test/crosswake/proof/phase175_rel17_publish_paths_test.exs --max-cases 1
10 tests, 0 failures
exit 0

$ MIX_ENV=test mix test test/crosswake/proof/phase175_rel17_recovery_paths_test.exs --max-cases 1
7 tests, 0 failures
exit 0

$ MIX_ENV=test mix test test/crosswake/proof/phase175_rel17_wiring_test.exs --max-cases 1
8 tests, 0 failures
exit 0

$ MIX_ENV=test mix test test/crosswake/release_candidate/evidence_gate_test.exs --max-cases 1
8 tests, 0 failures
exit 0

$ MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs --max-cases 1
7 tests, 0 failures
exit 0

$ actionlint .github/workflows/release-please.yml .github/workflows/hex-publish.yml .github/workflows/ios-mirror-backfill.yml
no findings; exit 0

$ bash -n script/guarded_hex_publish.sh script/release_candidate/ios_mirror.sh script/release_candidate/android_publication.sh script/release_candidate/load_release_evidence_context.sh
$ git diff --check
no findings; exit 0

$ mix format --check-formatted lib/crosswake/release_candidate/evidence_gate.ex lib/crosswake/release_candidate/evidence_live.ex script/check_release_workflow_integrity.exs test/support/release_workflow_fixtures.ex test/support/phase175_rel17_fixtures.ex test/crosswake/proof/phase175_rel17_publish_paths_test.exs test/crosswake/proof/phase175_rel17_recovery_paths_test.exs test/crosswake/proof/phase175_rel17_wiring_test.exs test/crosswake/release_candidate/evidence_gate_test.exs test/crosswake/release_candidate/evidence_live_test.exs
no findings; exit 0
```

## ASVS Disposition

The four Plan 175-36 threat findings are mitigated at the local control boundary:

- High privilege bypass: fresh shared-gate checks are required before release creation, credentials, and every external mutation.
- High operation spoofing: linked release, recovery, and companion publication use distinct typed operation/package selectors; the exact consumed authorization and candidate tuple are checked.
- High workflow tampering: every declared call site has an independent named scanner check and seeded mutation.
- Medium information disclosure: blocked output uses closed reasons, and raw source evidence remains in the intended private evidence artifacts.

No high finding remains open for this plan. The closure is local implementation and mutation evidence only. Fresh candidate artifacts, a fresh exact authorization trailer, and the subsequent planned release evidence remain required before any publishing workflow can pass.
