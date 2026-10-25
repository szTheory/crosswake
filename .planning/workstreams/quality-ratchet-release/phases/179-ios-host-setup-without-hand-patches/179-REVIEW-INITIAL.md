---
phase: 179-ios-host-setup-without-hand-patches
reviewed: 2026-10-13T22:05:18Z
depth: standard
review_head_sha: b6594664270ebc7a4434612c0840f6d3b887f805
review_tree_sha: 5caddd85b30cdfc174a66ab9d403c66122ceb07c
files_reviewed: 29
files_reviewed_list:
  - guides/capability_map.md
  - guides/native_shell.md
  - guides/native_shell_upgrade.md
  - guides/support_matrix.md
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/shell/ios_host_config.ex
  - lib/crosswake/shell/ios_host_generation.ex
  - lib/crosswake/shell/ios_host_project_migration.ex
  - lib/crosswake/shell/managed_outputs.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - lib/mix/tasks/crosswake.gen.shell.ex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofSettings.xcconfig.eex
  - priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex
  - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
  - script/collection_assertion_ledger.json
  - script/verify_ios_host_settings.mjs
  - test/crosswake/guides/native_shell_upgrade_test.exs
  - test/crosswake/proof/phase134_template_version_drift_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/crosswake/shell/ios_host_config_test.exs
  - test/crosswake/shell/ios_host_effective_settings_test.mjs
  - test/crosswake/shell/managed_outputs_test.exs
  - test/mix/tasks/crosswake.docs.sync_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
  - test/mix/tasks/crosswake_gen_shell_host_test.exs
findings:
  critical: 7
  warning: 1
  info: 0
  total: 8
status: issues_found
---

# Phase 179: Code Review Report

**Reviewed:** 2026-10-13T22:05:18Z  
**Depth:** standard  
**Files Reviewed:** 29  
**Status:** issues_found

## Summary

The Phase179 source diff contains seven blocking correctness/security defects and one path-compatibility defect. The findings cover invalid origins accepted into generated resources, unsafe filesystem and migration recovery behavior, incomplete Xcode settings checks, and a checker dependency omitted from the published package. The existing focused and proof runs do not cover these cases. This was a read-only source review; no tests were run.

## Critical Issues

### CR-01: [BLOCKER] Accepts malformed and out-of-range HTTPS ports

**File:** `lib/crosswake/shell/ios_host_config.ex:63-75`
**Issue:** Validation checks scheme, host, path, query, fragment, and userinfo but never checks the authority's port. Elixir's `URI.parse/1` accepts values such as `https://host.example:abc` with a default HTTPS port, and accepts port `65536`; `valid_origin/1` therefore accepts and later serializes these invalid origins into the manifest and activation URL.
**Fix:** Validate the raw authority's optional port as decimal digits in the valid TCP port range before accepting the origin, reject an empty or malformed port, and serialize a canonical URI.

### CR-02: [BLOCKER] Managed output paths can escape through an ancestor symlink

**File:** `lib/crosswake/shell/managed_outputs.ex:304-325`
**Issue:** `safe_layout/1` uses `Path.expand/1` and `lstat`s only the final `root`; `safe_components/2` begins traversal at that root. A symlink in any parent component is followed while checking the final root and is never rejected, so preflight and publication can write or recovery can replace files in the symlink target outside the requested host tree.
**Fix:** Walk every component from a trusted filesystem root to the requested root with `lstat` and reject symlinks, or resolve the root and verify it remains inside an explicitly trusted target boundary before any read or write.

### CR-03: [BLOCKER] Proof settings are published before all scaffold destinations are checked

**File:** `lib/crosswake/proof_lane/generator.ex:139-163`
**Issue:** The managed settings entry is prepended to `templates`, and `ensure_files/2` writes entries sequentially. A later unsafe or unrecognized scaffold destination can fail after `CrosswakeProofSettings.xcconfig` has already been published, leaving a partially generated project with settings that claim the host's identities/signing configuration.
**Fix:** Preflight ownership and path safety for every desired scaffold and the manifest before publishing any file; stage the full output set and promote it only after all checks pass, with rollback/recovery for interrupted promotion.

### CR-04: [BLOCKER] Proof project migration accepts unrecognized build configurations

**File:** `lib/crosswake/shell/ios_host_project_migration.ex:75-87`
**Issue:** `preview_proof_contents/1` scans only the six hardcoded IDs and succeeds when those six are found. An additional valid `XCBuildConfiguration` such as a Preview configuration is ignored, yet migration reports success and rewrites the recognized blocks. Its bundle/signing overrides remain outside the managed xcconfig contract.
**Fix:** Parse and validate the complete proof project configuration graph. Require exactly the expected six target configurations and their expected configuration lists/names; fail closed on any additional or remapped configuration.

### CR-05: [BLOCKER] Proof recovery overwrites edits made after interruption

**File:** `lib/crosswake/proof_lane/generator.ex:329-340,365-375`
**Issue:** Recovery trusts the staged prior bytes and calls `restore_prior/4` without checking the current settings file against either the published generation or the prior snapshot. If a host edits the file after an interrupted update, `--recover` replaces or deletes that edit and then removes the pending marker and recovery record.
**Fix:** Record the intended generation and compare the current file with the prior and intended bytes before restoring. On any third value, return a conflict and retain the recovery evidence for manual reconciliation.

### CR-06: [BLOCKER] Effective-settings checker can miss settings bundled as resources

**File:** `script/verify_ios_host_settings.mjs:29-43`
**Issue:** The shell branch returns after checking for a text marker and never inspects the shell PBX Resources phase. For proof, the exclusion check searches the Resources section for the filename comment; a valid object-ID reference without that comment is not detected. The checker can therefore report all settings cells as valid while the managed xcconfig is included in an app's resources.
**Fix:** Parse the PBX project object graph and resolve each Resources phase file ID through `PBXBuildFile` to its `PBXFileReference`. Assert that neither shell nor proof settings file is present in any app resource phase; cover the object-ID form with a schema-valid project fixture.

### CR-07: [BLOCKER] Published package omits the checker required by proof-lane checks

**File:** `lib/mix/tasks/crosswake.gen.proof_lane.ex:142-146`
**Issue:** The task resolves `../../../script/verify_ios_host_settings.mjs` relative to its installed source directory. `mix.exs` packages only `lib`, `priv`, `mix.exs`, docs, and guides, so Hex installations do not contain `script/verify_ios_host_settings.mjs`. A packaged host with `:ios_host` configuration reaches the missing script, returns no checker JSON, and `--check` fails as an invalid response.
**Fix:** Move the checker into a packaged `priv` path and resolve it with `:code.priv_dir(:crosswake)`, or explicitly include the script in the package manifest; verify the built Hex archive contains and executes it.

## Warnings

### WR-01: [WARNING] CLI entry-point check fails when the script path contains spaces

**File:** `script/verify_ios_host_settings.mjs:165`
**Issue:** `new URL(import.meta.url).pathname` contains percent-escaped characters, while `process.argv[1]` contains the filesystem path. When the installation path includes a space, the equality check fails and the CLI never calls `cli()`.
**Fix:** Convert the module URL with `fileURLToPath(import.meta.url)` before comparing it with `process.argv[1]`.

---

_Reviewed: 2026-10-13T22:05:18Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
