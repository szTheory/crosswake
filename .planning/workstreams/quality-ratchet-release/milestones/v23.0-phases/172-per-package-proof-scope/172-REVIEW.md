---
phase: 172-per-package-proof-scope
reviewed: 2026-09-17T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/crosswake/release_candidate/artifact.ex
  - lib/crosswake/release_candidate/cleanroom.ex
  - script/verify_companion_cleanroom.sh
  - script/release_candidate/hex_artifacts.sh
  - script/collection_assertion_ledger.json
  - test/crosswake/release_candidate/artifact_test.exs
  - test/crosswake/release_candidate/cleanroom_test.exs
  - test/crosswake/proof/phase172_per_package_ref_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 172: Code Review Report

**Reviewed:** 2026-09-17T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 172 replaces a single shared `candidate_ref` broadcast across all six packages with a
per-package ref, adds a graded `reachable_and_compatible` / `digest_mismatch` / `unproven`
classification in `Cleanroom.public_artifact_reason/3`, and threads an `attested`
bucket/`"ATTESTED"` state through `evaluate_public!/1`. I traced all eight (ref eq/neq) x (meta
eq/neq) x (payload eq/neq) combinations through the `cond` in
`lib/crosswake/release_candidate/cleanroom.ex:296-331` by hand against the actual source:

- ref=, meta=, payload= → falls through to `nil` (fully proven). Correct.
- ref=, meta=, payload≠ / meta≠, payload= / meta≠, payload≠ → all three hit the `digest_mismatch`
  clause (`ref!(...) == expected.candidate_ref and (metadata_digest != .. or payload_digest !=
  ..)`). Correct — a matching ref never softens a genuine digest mismatch.
- ref≠, meta=, payload= → hits `reachable_and_compatible`, the one clause requiring *both*
  digests to compare equal. This is the only path into the graded pass, and it is provably not
  reachable by any of the six mismatch cases above it.
- ref≠, meta=, payload≠ / ref≠, meta≠, payload= / ref≠, meta≠, payload≠ → none of these can
  satisfy the `reachable_and_compatible` guard (it needs both digests equal); they all fall
  through to the `ref!(...) != expected.candidate_ref → "unproven"` clause. `"unproven"` reasons
  are excluded from the `attested`/`succeeded` allow-list in the `blocked` filter
  (`cleanroom.ex:99-103`), so they still gate the run — a drifted ref never launders a real
  digest mismatch into a passing bucket.

I independently re-derived this from the source rather than trusting the phase's own tests, and
it holds. `blocked`, `missing`, `attested`, `succeeded` are computed as four `Enum.filter` passes
over the same six-element list with mutually exclusive predicates (`nil`, `"registry_missing"`,
`"reachable_and_compatible"`, and "everything else" respectively), so they partition the list
with no gap and no overlap for every reason string the classifier can emit (`registry_missing`,
`invalid_status`, `source_not_registry`, `path_lock_present`, `source_root_invalid`,
`digest_mismatch`, `unproven`, `reachable_and_compatible`, `nil`).

The shell changes (`verify_companion_cleanroom.sh`, `hex_artifacts.sh`) correctly regroup
artifact positionals from 6 to 7 fields per package in both the append site and the CLI
destructure in `artifact.ex` (`Enum.chunk_every(7)` unpacking exactly
`[package, version, candidate_ref, tarball, unpacked_root, outer_checksum, source]`, matching
the shell's append order field-for-field in both scripts). `MATRIX_PUBLIC_REF` is derived from
`git -C "$MATRIX_REPO_ROOT" rev-parse HEAD` and validated against a 40-hex-char pattern
immediately (`|| matrix_fail`) before any use, so it cannot be empty or malformed at any of its
three use sites (the artifact_args append, the log line, and nowhere else). The Python
observation-assembly heredoc now whitelists fields explicitly instead of splatting `**item`,
which incidentally also fixes what looks like it would have been a pre-existing schema mismatch
under the old splat (the raw producer-manifest records carry `files`/`requirements`/
`outer_checksum`, which are not in `@public_artifact_keys` and would have failed the exact-map
check) — that is an improvement, not a regression, so I did not record it as a finding.

Test quality is high: `phase172_per_package_ref_test.exs` pairs every "construct X is gone"
grep-style assertion with a "construct Y is there instead" assertion (per this milestone's own
absence-scored-as-success convention), the byte-exact regression anchors in `artifact_test.exs`
mutate real tarball bytes and carry the recomputed digest through the real producer and
consumer rather than comparing hand-written strings, and the ledger/pinned-count updates in
`phase170_vacuous_assertion_ledger_test.exs` and `collection_assertion_ledger.json` are
consistent with the one new collection-assertion site the phase's own SUMMARY says it added.

I found one Warning worth fixing (a misleading field name) and one Info item (asymmetric input
validation timing that is not exploitable but is worth knowing about). No Critical findings.

## Warnings

### WR-01: `failed_packages` includes non-failed (attested) packages

**File:** `lib/crosswake/release_candidate/cleanroom.ex:141-144`
**Issue:** `failed_packages` is computed as `Enum.reject(children, &is_nil(&1.reason))`, which
includes packages whose `reason` is `"reachable_and_compatible"` — i.e., packages in the new
`attested` bucket, which is not a failure state (the run can still complete with `"ATTESTED"`,
and the whole point of 172-02 was to give this bucket a *softer*, non-blocking classification
distinct from `blocked`). This is deliberate and directly tested
(`test/crosswake/release_candidate/cleanroom_test.exs`: `"a package whose observed ref drifts
but keeps matching bytes reports reachable_and_compatible"` asserts
`result.failed_packages == [%{package: "crosswake_sigra", reason: "reachable_and_compatible"}]`),
so it is not a correctness bug in this diff's own terms. However, the field name itself is a
quality/maintainability risk: any future caller (a new shell consumer, a dashboard, a different
proof module) that reads `failed_packages` and treats a non-empty list as "something failed"
will misclassify an attested-but-not-yet-fully-proven package as a failure, or conversely a
caller who filters `succeeded_packages ++ failed_packages == package_count` will double-count.
The current shell consumer avoids this by gating on `state == "COMPLETE"` alone, but the field
name does not communicate its own semantics.
**Fix:** Rename the field (e.g. `unresolved_packages` or `non_succeeded_packages`) to make clear
it is "not fully proven" rather than "failed," or split it into `blocked_packages` (strictly the
`blocked` bucket) and keep `attested_packages` as the separate, already-present field for the
softer bucket. If the name must stay for backward compatibility with existing consumers, add a
doc comment on the field's definition site noting that it also carries non-blocking
`reachable_and_compatible` entries.

## Info

### IN-01: Malformed observed `candidate_ref` is validated only when reached, not upfront

**File:** `lib/crosswake/release_candidate/cleanroom.ex:296-331` (validated only in
`public_artifact_reason/3`'s `cond` clauses via `ref!/1`)
**Issue:** `expected.candidate_ref` (the approved side) is always validated as a 40-hex string in
`validate_approved_artifacts!/1` (`cleanroom.ex:240`), unconditionally, for every package.
The observed side's `artifact.candidate_ref`, however, is only passed through `ref!/1` inside
the last three `cond` clauses of `public_artifact_reason/3`. If an artifact fails an earlier
check in the same `cond` (e.g. `artifact.status != "PASS"` → `"invalid_status"`, or the
`registry_missing` clause), the function returns before ever calling `ref!` on the observed ref,
so a malformed/garbage `candidate_ref` on an already-failing or already-missing package will
silently pass through `Map.take`/normalization into the `%{... candidate_ref: artifact.candidate_ref, ...}`
result map (`cleanroom.ex:272-281`) without raising, whereas the identical garbage value on an
otherwise-healthy package raises `ArgumentError` (confirmed by the test at
`cleanroom_test.exs`: `"a malformed observed candidate_ref on an otherwise-healthy package raises
ArgumentError"`). This is not exploitable — a package that already failed for another reason is
still correctly bucketed as failed/missing regardless of what garbage sits in its unvalidated
`candidate_ref` field, and the reason precedence order (status → source → path_lock → root →
ref/digest) is otherwise correct and matches the stated design ("drift never masks a harder
pre-drift failure," tested directly). It is, however, an inconsistency worth naming: the schema
nominally requires every public artifact to carry a well-formed `candidate_ref`
(`@public_artifact_keys` includes it unconditionally), but enforcement of that requirement is
conditional on which `cond` branch is reached, not universal.
**Fix:** If a well-formed `candidate_ref` is meant to be a hard schema invariant for every public
artifact (not just the ones that reach the drift-comparison clauses), call `ref!(artifact.candidate_ref)`
once, unconditionally, near the top of `public_artifact_reason/3` (or inline in
`validate_public_artifacts!/1` alongside the existing `path_lock_count` type check), so validation
timing does not depend on which failure reason fires first. If the current conditional-validation
behavior is intentional (e.g. a `MISSING` package's ref is genuinely meaningless and should be
allowed to be garbage), a short comment at the `ref!` call sites would save a future reader from
re-deriving this reasoning.

---

_Reviewed: 2026-09-17T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
