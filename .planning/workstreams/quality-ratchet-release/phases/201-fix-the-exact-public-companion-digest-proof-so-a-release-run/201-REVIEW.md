---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
reviewed: 2026-11-09T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/crosswake/release_candidate/artifact.ex
  - test/crosswake/release_candidate/artifact_real_tarball_test.exs
  - test/crosswake/planning/agents_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 201: Code Review Report

**Reviewed:** 2026-11-09
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed `Artifact.inspect_metadata!/3` and its `build_env` handling, the new real-tarball test, and the AGENTS.md contract test. Source was read from a scratch worktree of origin/main at af1dd94e. The `mix test` run was not possible in that worktree (deps are not fetched), so no tests were executed; the review is by reading and by cross-checking the live AGENTS.md and BEARINGS.md text against the contract test's phrases (all phrases are present).

The core change is sound in the direction that matters. `build_env!/1` runs for every package before the digest is computed, accepts only `nil` or exactly `[{"hex", <semver>}]`, and raises the generic `ArgumentError` otherwise. The exclusion works by package name, and any name not in `@build_env_excluded_packages` keeps `build_env` in the digest. Both unlisted and near-miss names (for example `crosswake_rulestead2`, or the core name) therefore fail toward a digest mismatch, not toward a silent match. `inspect_family!/1` additionally pins the exact ordered six-package list, and `metadata["name"]` must equal the declared package. I found no way for a hostile `build_env` to make a digest match when it should not: for the five companions the field is deliberately ignored, and everything else in the metadata and the file payload remains digested.

No blockers. The findings are about the test suite not pinning the five-name list, a duplicated and re-read decision in `provenance_line/1`, and a one-sided contract test.

## Warnings

### WR-01: Exclusion list is verified for one of five companions only, and no near-miss or unlisted-name control exists

**File:** `test/crosswake/release_candidate/artifact_real_tarball_test.exs:113-140` (list at `lib/crosswake/release_candidate/artifact.ex:21`)
**Issue:** Every companion-exclusion test uses `crosswake_rulestead`. A typo or omission in `@build_env_excluded_packages` for `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway` or `crosswake_threadline` would pass the whole suite. The failure would only show up as a live release-run digest mismatch, which is the exact defect this phase fixed. There is also no test that a near-miss or unlisted package name (for example `crosswake_rulestead_x`, `crosswake_rulesteadd`) keeps `build_env` digested, which is the fail-closed half of the claim. The comment at `artifact.ex:350` ("A package missing from the list keeps it as well") is untested.
**Fix:** Parameterize the "injecting a different build_env changes no digest" test over `Artifact.packages() -- ["crosswake"]`. Reuse the rulestead fixture and rewrite the `name` term to the package under test, since `metadata["name"]` must equal the declared package. Add the inverse control: for an unlisted name such as `"crosswake_rulestead_x"` (with `name` rewritten to match), assert that `put_build_env` with a different semver changes `metadata_digest`. Expose `@build_env_excluded_packages` or a `build_env_digested?/1` helper to assert directly that it equals `packages()` minus `"crosswake"`.

### WR-02: `provenance_line/1` re-derives the exclusion decision and re-reads the metadata file from disk after inspection

**File:** `lib/crosswake/release_candidate/artifact.ex:121-142`
**Issue:**
1. The "digested yes/no" decision is duplicated (`package not in @build_env_excluded_packages` here and `drop_build_env/2` at line 217). The log line is described as provenance for the proof, but it is not derived from what the digest actually did. If one site changes and the other does not, the log would assert a digest property that is false.
2. It re-consults `hex_metadata.config` from `unpacked_root` after `inspect_family!` returned. That file is not covered by any digest in the walk (`hex_metadata.config` is excluded at lines 274-278), and there is a window between validation and this second read. The logged `build_env_hex` is therefore not guaranteed to be the value that was validated. It is also not guaranteed to be the value the digest saw.
3. `{:ok, terms} = ...` raises `MatchError` here. `inspect_cli!/1` rescues only `File.Error` (line 106), so a failure at this point is a raw `MatchError` instead of the module's `ArgumentError` "candidate artifact input is invalid" contract. It still fails closed, but the error contract is inconsistent with `inspect_family!/1` and `inspect_single!/2`, which both rescue `MatchError`.
**Fix:** Have `inspect_metadata!/3` return the validated build_env Hex version. Log from that, and compute "digested" from one shared helper, for example `defp build_env_digested?(package), do: package not in @build_env_excluded_packages`, used by both `drop_build_env/2` and the log. If the observation must not widen (it is encoded to the manifest and into receipts), return it via a separate internal struct, or log inside `inspect_artifact!` where the data is already in hand.

### WR-03: AGENTS.md contract test is positive-only, so stale contradictory gate text would pass

**File:** `test/crosswake/planning/agents_contract_test.exs:9-43`
**Issue:** The test asserts that 11 phrases are present. It never asserts that the superseded wording is absent. The previous AGENTS.md rule read "The gate is required for merging the release PR, any Hex, Maven or iOS publish, creating or pushing tags, and deleting a remote branch". If that sentence were left behind, or reintroduced by a bad merge, alongside the new "standing exceptions" paragraph, every assertion would still pass. The policy would then be self-contradictory, and an agent could read the gate as required. The pinned phrase "Hex, Maven and iOS mirror publishes need no gate" is the one that weakens a safety gate, so a test that guards it should also guard against the opposite statement. The `negative control` tests (lines 65-78) only prove that removing a phrase makes `gate_ok?` false. That is guaranteed by construction, since `gate_ok?` is `all? contains?`, so they add no real signal beyond the first test's own presence check.
**Fix:** Add a refute for the superseded sentences, for example `refute String.contains?(collapse(text), "The gate is required for merging the release PR")` and `refute ... "any Hex, Maven or iOS publish, creating or pushing tags"`. Replace the tautological negative controls with one control that mutates the text to contain the stale sentence and asserts the predicate rejects it.

## Info

### IN-01: `build_env` shape is rigidly one-key, so a future Hex that adds a second key breaks all six packages

**File:** `lib/crosswake/release_candidate/artifact.ex:353-360`
**Issue:** Only `[{"hex", semver}]` is accepted. If Hex later stamps extra toolchain keys (for example OTP or Elixir versions) into `build_env`, every package fails closed with the generic "candidate artifact input is invalid" and no indication that `build_env` was the cause. That is safe, but it blocks release and is hard to diagnose. For the five companions the value is now ignored by the digest, so strict shape matters less there. The validation is also unbounded in length: `Version.parse` accepts arbitrarily long pre-release and build segments, and the value flows into the stderr provenance line. The charset is restricted by semver, so there is no log-injection route, but `requirement!/1` caps length at 80 and this field does not.
**Fix:** Optionally cap the version length (for example `byte_size(version) in 1..64`). Consider a distinct, still-generic internal reason code for `build_env` rejection so a Hex shape change is quickly attributable.

### IN-02: `build_env!(nil)` conflates a missing key with an explicit `nil` value

**File:** `lib/crosswake/release_candidate/artifact.ex:351`
**Issue:** `metadata["build_env"]` is `nil` both when the key is absent and when the file has `{"build_env", nil}`. Both are accepted. For the core, the two forms digest differently (absent key versus `{"build_env", nil}`), so this is not a bypass. For companions the field is dropped either way. It is a minor looseness in a validator that is documented as fail-closed.
**Fix:** Distinguish with `Map.fetch(metadata, "build_env")` and reject an explicit `nil` value.

### IN-03: `@build_env_excluded_packages` is a hand-maintained literal with no tie to `@packages`

**File:** `lib/crosswake/release_candidate/artifact.ex:9-21`
**Issue:** The list is the intended set "all packages except core", but nothing enforces that it is a subset of `@packages` or that it excludes exactly `crosswake`. Deriving it as `@packages -- ["crosswake"]` would auto-exclude any future sixth package, which conflicts with the documented "missing from the list keeps it" default, so a derived list is not obviously better. A compile-time subset assertion (or the test in WR-01) closes the drift gap without changing the default.
**Fix:** Add a compile-time guard such as `true = Enum.all?(@build_env_excluded_packages, &(&1 in @packages))`, plus the WR-01 test.

### IN-04: `inspect_single!/2` is a test-only public seam in a production module and bypasses the package-membership check

**File:** `lib/crosswake/release_candidate/artifact.ex:111-119`
**Issue:** It is `@doc false` and called only from the new test (a repo grep shows no other caller). It skips the `package_names == @packages` check that `inspect_family!/1` enforces, so it can inspect an unlisted package name. That is useful for the near-miss controls in WR-01, but it is also a way to produce an `observation` that the family path would reject. It is unreachable from `hex_artifacts.sh`, which goes through `inspect_cli!/1`. Test-only API surface in a release authority module is a small maintenance and misuse risk.
**Fix:** Keep it, but state in its `@doc false` comment that it is a test seam and must not be used for release evidence. Alternatively route the tests through `inspect_family!/1` with a prepared six-artifact set.

### IN-05: `assert_raise ArgumentError` shape tests cannot distinguish the `build_env` rejection from any other invalidity

**File:** `test/crosswake/release_candidate/artifact_real_tarball_test.exs:54-109`
**Issue:** All rejection paths raise the same message, "candidate artifact input is invalid", and the tests do not assert on the message. A shape test would pass if the fixture mutation broke something else (a rewrite error, a path or ownership issue). The passing "injecting the rebuild's own build_env" test acts as a positive control for the writer, which mostly mitigates this. The residual gap is that the shape tests only prove "something raised".
**Fix:** Add a distinguishing marker where it is cheap, for example one test that applies a build_env mutation which is shape-valid (positive control, no raise) next to each shape-invalid variant using the same `put_build_env` helper in the same test body. Or have `build_env!/1` raise with a distinct internal reason that the test can match.

---

_Reviewed: 2026-11-09_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
