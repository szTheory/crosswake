---
phase: 199-release-0-2-12
reviewed: 2026-11-10T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/crosswake/planning/first_adopter_context.ex
  - test/crosswake/planning/first_adopter_context_test.exs
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/parity_ledger/renderer.ex
  - test/crosswake/guides/changelog_unreleased_wording_test.exs
  - test/crosswake/guides/host_command_seam_guide_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - script/collection_assertion_ledger.json
  - .github/workflows/crosswake-ci.yml
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
  necessity: 0
status: issues_found
---

# Phase 199: Code Review Report

**Reviewed:** 2026-11-10
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed from a detached worktree of origin/main at 323227b5, diffed against cbb90031. I ran the four touched test files there (78 tests, 0 failures) and `mix crosswake.docs.sync --check` (passed).

**`.awk` scan rule: safe.** `.awk` is added to `@scannable_extensions` in one place, and `scannable_text_path?/1` matches with `Path.extname/1`, which is case-sensitive. A path like `helper.AWK` or any unknown extension still falls through to `:unclassified` and becomes a `routing.unclassified_path` violation, so the allowlist still fails closed. The new test checks both sides. `discover_paths/1` filters on `scan?: true`, so the `[awk_path]` assertion proves the file is classified for scanning, not merely not rejected. The only `.awk` file tracked in the repo is `gate-order-200.awk`, under a phase directory (`phase_artifact_path?` is not what matches it; the extension rule does). Nothing is wrongly skipped.

**Ledger and pin arithmetic: consistent.** I recomputed the committed JSON: 288 rows, `assert_any` 145, `assert_all` 84, `refute_any` 59, and buckets `safe-by-construction` 145, `safe-guarded` 83, `safe-cardinality-pinned` 51, `safe-compile-time-literal` 9. These match `@audited_site_count`, `@shape_counts` and `@bucket_counts`. The two rows removed from the JSON (the changelog `:ios_host` guard and the deleted qualifier test's `sections(text)` row) match the two `assert Enum.any?` sites that left the tree, so the "raw grep over-counts by exactly 5" reconciliation still holds. The `assert_any == safe-by-construction` invariant is intact.

**CI timeout: scoped to one job.** The 20 to 30 minute change is commit be6f1031, which is not in the cbb90031..323227b5 diff (it predates that range). It touches a single hunk, the `phase130-core-hermetic-proof` job at line 624, and no other job's timeout changed. The stated measurement (19.9 min max) is the only evidence offered, and it is in a comment beside the change.

**Release claims verified against Hex.** I downloaded crosswake 0.2.11 and 0.2.12 from repo.hex.pm. 0.2.11 has no parity ledger modules and no `ios_host` reference; 0.2.12 has both. So "from 0.2.12 on; 0.2.11 and earlier do not" is factually correct as worded.

No blockers. The findings below concern the strength and durability of the rewritten guards.

## Warnings

### WR-01: Changelog guard forbids `:ios_host` in `[Unreleased]` permanently and pins boilerplate

**File:** `test/crosswake/guides/changelog_unreleased_wording_test.exs:112-118`
**Issue:** The rewritten test asserts `refute unreleased() =~ ":ios_host"`, `refute unreleased() =~ "not released"`, and pins the literal sentence "There are no unpublished support claims at this time." These encode a point-in-time fact (nothing is unpublished right now) as a permanent invariant. The first legitimate future unreleased entry that mentions `:ios_host` (a new declaration option, for instance), or any entry using the words "not released", fails this test, and it fails against the wording rule's own intent. The `:ios_host` refute is also broader than the claim it protects, which is "do not list the 0.2.12-shipped declaration as unpublished". The test can pass for the wrong reason only if the section were empty, but the positive sentence assertion prevents that, so absence is not scored as success here. The weakness is durability, not vacuity.
**Fix:** Drop the blanket `:ios_host` refute, or scope it to the specific shipped claims, for example refute a line that contains both `:ios_host` and `published release`/`not released`. Keep the positive assertion tied to the heading rather than the boilerplate sentence, for example assert the "Unpublished support claims" subsection either lists claims or states there are none.

## Info

### IN-01: Deleting `unreleased_claim_qualifier_test.exs` leaves hand-authored guides unguarded

**File:** `test/crosswake/guides/unreleased_claim_qualifier_test.exs` (deleted); `guides/native_shell.md:64`, `guides/compatibility.md:47`, `guides/architecture.md:108`
**Issue:** The removed test enforced, per heading-delimited section, that every mention of `:ios_host`, `1.2.0` or "vector-set hash" carried a version qualifier. The renderer-generated guides (`capability_map`, `support_matrix`, `parity_ledger`) are still covered by `docs.sync --check`. The hand-authored `native_shell.md`, `compatibility.md` and `architecture.md` now have no check that a new mention of the declaration or schema `1.2.0` names the version that first emits it. The deletion was planned (the old moduledoc says Phase 199 removes it), and the claims are now published, so this is residual risk only.
**Fix:** If wanted, keep a cheap positive pin per hand-authored guide (assert the "0.2.11 and earlier" sentence is present), as `host_command_seam_guide_test.exs` now does for `native_shell_upgrade.md`.

### IN-02: Rewritten host-command tests lean on absence assertions

**File:** `test/crosswake/guides/host_command_seam_guide_test.exs:39-43, 96-101`
**Issue:** `refute changelog =~ ~r/\* \*\*Host-command seam/` and `refute changelog =~ ~r/\* \*\*Legacy-manifest denial/` pass if the entries are reworded or removed for any reason, so on their own they assert only absence. The tests do add a real positive on the upgrade guide (the "Android shell is unchanged" sentence, the `mix crosswake.gen.shell ios` command and `host_commands_legacy_manifest`), so the tests are not vacuous. Two details weaken them slightly. The Android assertion dropped "its vectors and its assets" and now checks only "The Android shell is unchanged". The legacy-manifest repair is asserted by two substrings that need not be adjacent.
**Fix:** Optional. Assert the Android sentence in full if the vectors/assets claim is still intended to be public, and assert the repair command and the denial code inside the same paragraph.

### IN-03: `.awk` test has no content positive control

**File:** `test/crosswake/planning/first_adopter_context_test.exs:339-353`
**Issue:** The awk fixture content is `BEGIN { print "safe" }`, so `scan_filesystem(root, []) == []` cannot distinguish "scanned and clean" from "scanned but a content rule never ran on `.awk`". The `discover_paths/1` assertion does prove the file is in the scan set, and the existing tests prove content rules run on other extensions, so this is low risk. A one-line control would make the test self-proving.
**Fix:** Reuse the private-term pattern from the nearby tests: write a canary term into the `.awk` file and assert `scan_filesystem(root, [term])` returns `privacy.private_term` for that path.

### IN-04: Guides state "from 0.2.12 on" without noting 0.2.12 was a PARTIAL release

**File:** `lib/crosswake/capability_map/renderer.ex:82`, `lib/crosswake/support_matrix/renderer.ex:137`, `lib/crosswake/support_matrix/renderer.ex:274`
**Issue:** The wording is accurate (verified against the published tarballs), but `.planning/workstreams/quality-ratchet-release/ROADMAP.md` (Phase 200 goal) records that 0.2.12's default `mix crosswake.gen.shell ios` wrote an Xcode project that did not build, forward-fixed in 0.2.13. A reader who takes "from 0.2.12 on" literally and pins 0.2.12 lands on the defective release. This is a public-guide honesty point rather than a code defect. Separately, `parity_ledger/renderer.ex:13` renders the same qualifier sentence twice in `guides/parity_ledger.md` (lines 12 and 18) because `@qualifier` is emitted in two places; that duplication predates this change.
**Fix:** Optionally name the first release where default generation builds (0.2.13) where the guides discuss default iOS generation, and drop one of the two parity-ledger qualifier emissions.

---

_Reviewed: 2026-11-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
