# Phase 179 Security Repair 02

Candidate HEAD: `e25f17bdaf096409a5238066d1e727e769dc365f`

## T-179-04 — migration filesystem boundary

**Commit:** `0baf4c9` (`fix(179): T-179-04 contain shell project migration I/O`)

`report_project_migration/2` now reads and writes the fixed PBX project path through `Crosswake.Shell.ManagedOutputs`. The API reuses bounded reads, trusted temporary-root alias handling, ancestor and component `lstat` checks, managed-layout checks, and the pending-generation boundary. Writes recheck the expected current bytes before replacement. Unsafe paths, a pending generation, conflicts, and missing projects return bounded safe causes.

New semantic regressions cover ancestor symlinks, a symlinked Xcode project directory, a symlinked project file, and pending managed-output state. Before the repair, both `--diff` and apply returned success for the symlink cases; apply could operate through the outside project. Pending state also returned success. After the repair, all four cases deny both actions and assert the outside/project bytes remain unchanged.

**Validation:** `mix test test/crosswake/shell/ios_host_migration_security_test.exs` — 4 tests, 0 failures. `git diff --check` passed after the candidate changes.

## T-179-05 — complete proof PBX graph and bundle identity

**Commit:** `e25f17b` (`fix(179): T-179-05 validate complete PBX configuration graphs`)

Added a dependency-free OpenStep plist tokenizer/parser that ignores comments and accepts legal whitespace, quoting, nested settings, and multiline objects while rejecting duplicate dictionary IDs. Proof migration now validates the full configuration, list, target, and project graph: the eight recognized configurations and names, four exact lists, the three target references, and the project reference. Extra configurations/lists, duplicate IDs, and remapped list/target references fail closed. Supported unrelated PBX content remains untouched.

Pre-fix behavioral evidence: a multiline `Preview` configuration and a duplicate configuration-list ID were accepted; a legal reformat of a recognized configuration was rejected. The fixed regressions pass. The additional remapped-target and duplicate-configuration-ID assertions were added after the parser change, so no test-first failure is claimed for those two individual assertions.

Shell migration now removes old target bundle overrides and projects the declared app/test variables into all four app/test Debug/Release configurations. Project configurations remain without target bundle projections. The test oracle is the ordinary `host_declaration()` value held in the test, independent of generated xcconfig, manifest, or metadata. Current and legacy migrations are exercised; both are checked through actual `xcodebuild -showBuildSettings -json` for app and test targets in Debug and Release, and current migration is asserted idempotent.

**Validation:** `mix compile --warnings-as-errors` passed. Focused config, managed-output, shell migration, and proof graph tests passed: 39 tests, 0 failures. The maintained shell-host integration test passed separately: 3 tests, 0 failures, including its actual Xcode control. Formatting and `git diff --check` passed. Xcode checks required the already-authorized local escalation for normal cache/log writes; the successful Xcode results contained the expected declared app/test identities.

## Evidence limits

The first Xcode attempt under the restricted sandbox could not write Xcode caches/logs; it was repeated under the authorized local-check escalation and passed. No broad phase proof leaves were rerun, as directed; the earlier broad results apply only to their earlier candidate. No phase completion claim is made here.
