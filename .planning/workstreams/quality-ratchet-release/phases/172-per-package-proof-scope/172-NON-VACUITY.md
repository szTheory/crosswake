# Phase 172 Non-Vacuity Record

This file carries the measured facts the phase-close verifier needs to populate
`172-VERIFICATION.md`'s `vacuity_taxonomy` field, per
[`VERIFICATION-CONVENTIONS.md`](../../VERIFICATION-CONVENTIONS.md). It is written by the
executor, at execution time, because the verifier cannot re-run a mutation against a tree
that no longer exists in this exact shape once the branch merges — the record here is the
only durable evidence of what was actually run and what it printed.

The six vacuity shapes (`A`-`F`) referenced below are defined at
[`.planning/research/v23/PITFALLS.md`](../../../../research/v23/PITFALLS.md) §"Pitfall 4"
and are not restated here, per that convention's link-never-copy rule.

## Scope and counts

**40 checks** (new or extended tests, plus "other" structural verifications) are named across
the three plan summaries of this phase:

- `172-01-SUMMARY.md` coverage entries D1-D4: **8** checks
- `172-02-SUMMARY.md` coverage entries D1-D8: **17** checks
- `172-03-SUMMARY.md` (this plan's own tests): **15** checks

**10** of those 40 checks carry a mutation that was actually run against the working tree,
observed red, and reverted, in this plan's execution window or in the two preceding plans'
own recorded execution — these are the rows below. The remaining **30** checks are named,
with a reason, in the "Checks landed with no mutation run" section that closes this file;
`8 + 17 + 15 = 40 = 10 + 30` is the checkable equality the convention asks for.

## Mutation-backed rows

| # | Check ID (module # test name, exact) | Shape | Mutation applied | Observed output (quoted) | Commit |
|---|---|---|---|---|---|
| 1 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"approved-artifacts validator rejects a malformed or absent candidate_ref"` | A (see below) | In `validate_approved_artifacts!/1`, replaced `candidate_ref: ref!(artifact.candidate_ref)` with a raw pass-through `candidate_ref: artifact.candidate_ref`, removing the 40-hex validation call. | `mix compile --warnings-as-errors` reported `warning: function ref!/1 is unused`. `mix test test/crosswake/release_candidate/cleanroom_test.exs --only post_publication --max-cases 1`: `1) test approved-artifacts validator rejects a malformed or absent candidate_ref (Crosswake.ReleaseCandidate.CleanroomTest)` / `Expected exception ArgumentError but nothing was raised` / `10 tests, 1 failure (6 excluded)`. | `cee77590` (172-01 Task 3 — mutation applied to the working tree immediately before this commit, reverted before it landed) |
| 2 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"a package whose observed ref drifts but keeps matching bytes reports reachable_and_compatible"` | escape: matches none of A-F, because it is a single-fixture `cond`-branch classifier assertion, not a predicate over a runtime-derived possibly-empty collection, a `needs:`/`if:`/matrix condition, or a shell exit-code idiom. | Swapped the `reachable_and_compatible` and `unproven` `cond` clauses in `public_artifact_reason/3` (kept `digest_mismatch` between them in absolute position). | `1) test a package whose observed ref drifts but keeps matching bytes reports reachable_and_compatible (Crosswake.ReleaseCandidate.CleanroomTest)` / `Assertion with == failed` / `left: [%{reason: "unproven", package: "crosswake_sigra"}]` / `right: [%{reason: "reachable_and_compatible", package: "crosswake_sigra"}]` / `17 tests, 1 failure (6 excluded)`. | `bfc2ea23` (172-02 Task 1) |
| 3 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"a package whose observed ref drifts AND whose digests differ reports unproven, not digest_mismatch"` | escape: same reasoning as row 2. | Deleted the `ref!(artifact.candidate_ref) == expected.candidate_ref and` conjunct from the guarded `digest_mismatch` clause, restoring the plain OR-only digest comparison. | `1) test a package whose observed ref drifts AND whose digests differ reports unproven, not digest_mismatch (Crosswake.ReleaseCandidate.CleanroomTest)` / `left: [%{reason: "digest_mismatch", package: "crosswake_sigra"}]` / `right: [%{reason: "unproven", package: "crosswake_sigra"}]` / `17 tests, 1 failure (6 excluded)`. The SC#3 no-drift regression tests stayed green under this mutation, as predicted (an always-true conjunct's removal cannot flip a no-drift case). | `bfc2ea23` (172-02 Task 1) |
| 4 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"SC#3 regression anchor: a payload_digest change with no ref drift still reports digest_mismatch"` | escape: same reasoning as row 2. | Replaced `artifact.payload_digest != expected.payload_digest` with the literal `false` inside the guarded `digest_mismatch` clause. | `1) test SC#3 regression anchor: a payload_digest change with no ref drift still reports digest_mismatch (Crosswake.ReleaseCandidate.CleanroomTest)` / `left: []` / `right: [%{reason: "digest_mismatch", package: "crosswake_sigra"}]`. A second, pre-existing test (`exact-public proof blocks path, cache, digest, lock-source, and live-status ambiguity`) failed under the same mutation for the same reason. `17 tests, 2 failures (6 excluded)`. | `bfc2ea23` (172-02 Task 1) |
| 5 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"one attested package with five fully-proven packages reports ATTESTED, not COMPLETE"` | escape: same reasoning as row 2 (single-fixture aggregate-state classifier, not a collection predicate). | Two independent mutations both falsify this check: (a) widened the `blocked` filter back to `&(&1.reason not in [nil, "registry_missing"])`, re-catching `reachable_and_compatible`; (b) changed the `attested != []` branch's state literal from `"ATTESTED"` to `"COMPLETE"`. | Mutation (a): `left: "BLOCKED"` / `right: "ATTESTED"` / `23 tests, 2 failures (6 excluded)` (a second test, `"a registry-missing package still reports PARTIAL..."`, raised `ArgumentError` under the same mutation). Mutation (b): `left: "COMPLETE"` / `right: "ATTESTED"` / `25 tests, 2 failures (6 excluded)`. | (a) `3371b297` (172-02 Task 2); (b) `db182d30` (172-02 Task 3) |
| 6 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"a registry-missing package still reports PARTIAL even alongside an attested package"` | escape: same reasoning as row 2. | Same mutation (a) as row 5: widened the `blocked` filter back to catch `reachable_and_compatible`. | `2) test a registry-missing package still reports PARTIAL even alongside an attested package (Crosswake.ReleaseCandidate.CleanroomTest)` / `** (ArgumentError) candidate clean-room input is invalid` / raised from `validate_complete_public_proof/3` — the mutation made the run take the `blocked` path (which validates installs/profile_results against the missing-package fixture's deliberately empty `[]`/`[]`/`"not_run"` shape) instead of the intended `PARTIAL` path. `23 tests, 2 failures (6 excluded)`. | `3371b297` (172-02 Task 2) |
| 7 | `Crosswake.ReleaseCandidate.CleanroomTest` # `"an attested run's state is never the completion string (semantic anchor for the terminal gate)"` | escape: same reasoning as row 2. | Same mutation (b) as row 5: changed the `attested != []` branch's state literal to `"COMPLETE"` locally. | `2) test an attested run's state is never the completion string (semantic anchor for the terminal gate) (Crosswake.ReleaseCandidate.CleanroomTest)` / `left: "COMPLETE"` / `right: "ATTESTED"` / `25 tests, 2 failures (6 excluded)`. Reverted; `git diff --stat` against `HEAD` showed zero residual change before this commit. | `db182d30` (172-02 Task 3) |
| 8 | `Crosswake.Proof.Phase172PerPackageRefTest` # `"no jq expression collapses the approved manifest's refs to one scalar, and a per-package lookup is there instead"` | escape: matches none of A-F, because it is a static-source-text assertion over a shell script's committed bytes, not a predicate over a runtime-derived possibly-empty collection, a `needs:`/`if:`/matrix condition, or a shell exit-code idiom itself. | Inserted a standalone `MUTATION_COLLAPSED_REF=$(jq -er 'map(.candidate_ref) \| unique \| if length == 1 then .[0] else error("candidate ref") end' "$MATRIX_APPROVED_MANIFEST") \|\| matrix_fail` line into `script/verify_companion_cleanroom.sh`, immediately before the per-package fetch loop. | `mix test test/crosswake/proof/phase172_per_package_ref_test.exs`: `1) test the family-wide ref collapse cannot return in the shell transport (SC#1) no jq expression collapses the approved manifest's refs to one scalar, and a per-package lookup is there instead (Crosswake.Proof.Phase172PerPackageRefTest)` / `verify_companion_cleanroom.sh must not reintroduce any \`unique\`-based reduction over the approved manifest's candidate_ref column` / `13 tests, 1 failure`. | `a431f21a` (172-03 Task 1 — mutation applied to the working tree, observed red, reverted before this commit) |
| 9 | `Crosswake.Proof.Phase172PerPackageRefTest` # `"a drifted-but-byte-identical package reaches the reachable_and_compatible claim through the evaluator"` | escape: same reasoning as row 8. | In `public_artifact_reason/3`, replaced the `reachable_and_compatible` branch's return literal with `"digest_mismatch"` (the branch's guard was left unchanged; only its return value was mutated). | `mix test test/crosswake/proof/phase172_per_package_ref_test.exs`: `1) test the three claim strings are reachable through the public evaluator, not merely present in source (SC#4) a drifted-but-byte-identical package reaches the reachable_and_compatible claim through the evaluator (Crosswake.Proof.Phase172PerPackageRefTest)` / `left: "unproven"` / `right: "reachable_and_compatible"` / `13 tests, 1 failure`. (`public_artifact_claim/1`'s catch-all still mapped the mutated `"digest_mismatch"` reason to the `"unproven"` claim, which is why the observed claim is `"unproven"` and not the old `"digest_mismatch"` reason string itself — the reachability test caught the defect exactly as designed.) | `a431f21a` (172-03 Task 1 — mutation applied to the working tree, observed red, reverted before this commit) |
| 10 | `Crosswake.ReleaseCandidate.ArtifactTest` # `"byte-exact regression anchor: a single real byte flip still fails the proof -- silent weakening would show as fully_proven/COMPLETE"` | escape: same reasoning as row 8 (single-fixture classifier assertion, mutated at the classifier layer, not a collection predicate). | Replaced `artifact.payload_digest != expected.payload_digest` with the literal `false` inside the guarded `digest_mismatch` clause of `public_artifact_reason/3` (the same edit shape as row 4, re-run independently against this plan's own new byte-mutation test). | `mix test test/crosswake/release_candidate/artifact_test.exs --max-cases 1`: `1) test byte-exact floor at the tarball layer (SC#3, XPUB-02) byte-exact regression anchor: a single real byte flip still fails the proof -- silent weakening would show as fully_proven/COMPLETE (Crosswake.ReleaseCandidate.ArtifactTest)` / `left: []` / `right: [%{reason: "digest_mismatch", package: "crosswake"}]` / `7 tests, 1 failure`. | `1100c8b4` (172-03 Task 2 — mutation applied to the working tree, observed red, reverted before this commit) |

## Checks landed with no mutation run

The following 30 checks were landed by this phase (new or extended tests, or "other"
structural verifications named in a plan `SUMMARY.md`'s `coverage` list) without an
individually-run, independently-recorded mutation. None is silently omitted; each carries
its own reason below, grouped by why no dedicated mutation was run.

### Group D — control/positive-path or purely structural assertions, no adversarial mutation run in this phase's time-boxed budget

Each plan's task explicitly prescribed a small, named set of mutations (three for 172-01's
Task 3, five for 172-02, two for 172-03's Tasks 1 and 2). These checks are real, passing,
and exercised on every `mix test` run, but no mutation specifically targeting them was run
independently of the rows above.

- `172-01`: `test/crosswake/release_candidate/artifact_test.exs#two artifacts in one family carry their own distinct candidate_ref, not a broadcast value`
- `172-01`: `test/crosswake/release_candidate/cleanroom_test.exs#post-publication adapter fetches exact packages and preapproval command cannot count it (extended script-contract assertions)`
- `172-02`: `a registry-missing package still reports registry_missing even with a drifted approved ref`
- `172-02`: `a malformed observed candidate_ref on an otherwise-healthy package raises ArgumentError` (the adversarial malformed-ref value the fixture constructs is itself the falsifying input; no separate external mutation was layered on top)
- `172-02`: `package_claims always carries exactly six non-empty claims in canonical order`
- `172-03`: `the observed ref is assigned exactly once, from a repository head resolution, never from the approved manifest`
- `172-03`: `neither shell script passes a ref as the first positional into Artifact.inspect_cli!/1, and the root/manifest positionals are there instead`
- `172-03`: `verify_companion_cleanroom.sh's artifact_args append carries exactly the named field count`
- `172-03`: `hex_artifacts.sh's ARTIFACT_ARGS append carries exactly the named field count`
- `172-03`: `Artifact's family-level input keys omit candidate_ref, and the per-artifact keys carry it instead`
- `172-03`: `the candidate-local artifact keys omit candidate_ref, and the approved/public keys carry it instead`
- `172-03`: `the two new reason strings and all three claim strings are typed in the classifier source` (deliberately the grep-only half of the pair; the reachability half is row 9 above)
- `172-03`: `a fully-proven family reaches the fully_proven claim for every package` (baseline/control fixture for rows 9 and the next entry; the mutations recorded in rows 9-10 do not perturb this branch, since it takes neither the drift nor the digest-mismatch `cond` clause)
- `172-03`: `a drifted package whose bytes also differ reaches the unproven claim, never fully_proven, through the evaluator`
- `172-03`: `the claim entry count equals the package count and no package carries two claims, for a fully-proven run`
- `172-03`: `the claim entry count equals the package count and no package carries two claims, for a mixed-claim run`
- `172-03`: `drift cannot launder a byte change: same mutation plus a drifted ref reports unproven, never reachable_and_compatible or fully_proven` (companion/control to row 10; the row-10 mutation cannot reach this branch, since the drifted-ref guard `ref!(...) == expected.candidate_ref` is already false here, short-circuiting past the mutated comparison before it is ever evaluated — confirmed by inspection of `public_artifact_reason/3`'s clause order)

### Group A' — self-contained mutation tests (the check applies its own fixture mutations; no additional external mutation of the check's own machinery was run)

These two tests are themselves loops over a small list of built-in mutation cases
(`for {name, mutate} <- mutations do ... end`), asserting each raises or blocks as expected.
The list is a compile-time literal with 2 (172-01) and 5 (172-02) entries respectively, so the
"possibly-empty collection" failure mode Shape A names is inspectable directly in source
rather than requiring a further external mutation to demonstrate.

- `172-01`: `test/crosswake/release_candidate/artifact_test.exs#rejects package-set, file-list, checksum, path, output, and version mutations (top_level_candidate_ref, malformed_ref cases)` — 8 built-in mutation cases (6 original + 2 added by 172-01: `top_level_candidate_ref`, `malformed_ref`)
- `172-02`: `drift never masks a harder pre-drift failure` — a `for` loop over the five harder pre-drift fixtures (bad status, non-registry source, path lock, bad source root, registry-missing)

### Group B — schema completeness checks whose only failure mode (the six-distinct-packages completeness `unless`) predates and is unchanged by this phase

Phase 171 already proved the completeness `unless` in `validate_approved_artifacts!/1` and its
siblings is minimal (its own falsifiability was established before Phase 172 began, and this
phase's diff to those functions only added the `candidate_ref` field, never touched the
`unless` itself — confirmed by `git diff` in the 172-01/172-02 coverage `D3`/`D8` "other" rows
below). Re-mutating an invariant this phase did not touch was out of scope.

- `172-01`: `test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts schema accepts six independent candidate_ref values in one run`
- `172-01`: `test/crosswake/release_candidate/cleanroom_test.exs#two packages with different candidate_ref values both validate independently in one run`

### Group A — same aggregate-bucket logic already falsified by the row-5/row-6/row-7 mutations, exercised from a different fixture angle

Each of these asserts a derived property (disjointness, cross-consistency, or a text
comparison) of the exact same `blocked`/`attested`/`succeeded` partition and `ATTESTED`/
`COMPLETE` state literals that rows 5-7 above already demonstrated are load-bearing. No
additional mutation was run against these specific assertions independently.

- `172-02`: `a blocked package outranks an attested package - the run still reports BLOCKED`
- `172-02`: `the four public-artifact buckets are disjoint and sum to six`
- `172-02`: `package_claims and succeeded_packages agree on which packages are fully proven`
- `172-02`: `the exact-public terminal gate still requires the completion state, not the attested state`
- `172-02`: `SC#3 regression anchor: a metadata_digest change with no ref drift still reports digest_mismatch` (the `metadata_digest` half of the same OR-clause mutated for row 4's `payload_digest` half; structurally identical failure mode)

### Group C — "other" structural checks measured by a direct count (a diff/grep result), not a mutation

Per `VERIFICATION-CONVENTIONS.md`, a measured count is independently valid non-vacuity
evidence alongside a mutation. These four checks are `git diff`/`grep` observations of an
exact line count, not runtime assertions a mutation can redden; the count itself is the
measured fact, already recorded in the citing `SUMMARY.md`.

- `172-01`: `other: grep -c 'unique' script/verify_companion_cleanroom.sh returns 0; grep -c 'chunk_every(6)' lib/crosswake/release_candidate/artifact.ex returns 0; bash -n on both scripts exits 0` (the `unique` half of this is now additionally covered by row 8's live mutation, which reintroduces exactly the construct this grep polices)
- `172-01`: `other: git diff 9ba10059..HEAD -- lib/crosswake/release_candidate/cleanroom.ex shows zero changed lines inside public_artifact_reason/3`
- `172-02`: `other: git diff bd14220a..HEAD -- lib/crosswake/release_candidate/cleanroom.ex shows the two digest-comparison lines appear only as unedited context/move, never as an edit`
- `172-02`: `other: git diff bd14220a..HEAD -- script/verify_companion_cleanroom.sh shows zero changed lines around the terminal state comparison`

## Reconciliation

- 10 (mutation-backed rows) + 30 (no-mutation checks, all four groups above:
  17 in Group D + 2 in Group A' + 2 in Group B + 5 in Group A + 4 in Group C = 30) = **40**,
  matching the 8 + 17 + 15 = 40 checks named across `172-01-SUMMARY.md`, `172-02-SUMMARY.md`,
  and `172-03-SUMMARY.md`.
