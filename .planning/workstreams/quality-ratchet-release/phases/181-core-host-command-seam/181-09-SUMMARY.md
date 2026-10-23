---
phase: 181-core-host-command-seam
plan: 09
status: complete
requirements: [SEAM-05]
candidate: /private/tmp/crosswake-phase181-impl
plan_head_before: 84c8f3560c830afae872fc1b586e9ff7f37f2239
plan_head_after: f338ea00f195f5b26860d5865b2c69e74ccb0d69
commits: 3
actuals:
  tasks: 2
  commits: 3
---

# Phase 181 Plan 09: Host-author guides and guide truth test Summary

The guides now describe the host-command seam as shipped in 181-01..08: three author touch points, the per-route grant rule, the 1.x.y version range, the upgrade combination table with the entry-route deviation, the remote shell package gate and its fix, the `.offlineIsland` switch change, and the plain offline non-promises. A hermetic test locks the wording. Nothing claims a release, device result or adopter result.

## Commits (candidate, branch phase181-impl)

| Task | SHA | Content |
|---|---|---|
| 1 (tracer) | 68f87e1 | route_policy.md "Host commands" section; new host_command_seam_guide_test.exs (3 tests) |
| 2 | 6b876a4 | bridge.md, native_shell_upgrade.md, native_shell.md, offline.md, iOS template README; test grown to 9 tests |
| fix | f338ea0 | template_version 4 to 5 and drift hash, via `mix crosswake.bump_template_version` |

Candidate HEAD after last commit: `f338ea00f195f5b26860d5865b2c69e74ccb0d69`. Tree clean. Nothing pushed.

## Guides changed

- guides/route_policy.md: both router styles, grammar, reserved prefixes, ^1.0.0 range, runtimes, two error codes with example, three touch points.
- guides/bridge.md: per-route grant rule, re-resolution, `undeclared_capability` kept, no new reason code, touch points.
- guides/native_shell_upgrade.md: four-row combination table, entry-route legacy sentence, doctor findings, upgrade core and shell together, remote-package gate with fix, `case .offlineIsland`.
- guides/offline.md and guides/native_shell.md: offline island admission and the D-13 non-promises.
- priv/templates/crosswake/shell/ios/README.md.eex: `.offlineIsland` and router declaration note.
- CHANGELOG untouched (no new Unreleased heading).

## Verification (each captured to a file, exit code checked, after the last commit)

- Root `MIX_ENV=test mix test`: 2218 tests, 0 failures (78 excluded). Run after the template bump, before its commit; the commit contains exactly that content.
- examples/phoenix_host: 150 tests, 0 failures.
- `mix crosswake.docs.sync --check`: passed.
- `test/crosswake/guides`: 191 tests, 0 failures. host_command_seam_guide_test.exs: 9 tests.
- check_exunit_ownership.exs: OK line printed.

## Deviations

**1. [Rule 3 - Blocking] Template drift guard.** Editing the iOS template README (required by D-20) changed the pinned shell template hash and failed Phase134TemplateVersionDriftTest. I ran the maintainer task `mix crosswake.bump_template_version`, which raised `@template_version` in gen.shell from 4 to 5 and rewrote the checked-in hash. Consequence for later plans and the release: generated shell stamps now say template version 5, and the upgrade guide has no Template Version 5 entry (the guide's existing entries stop at version 2; versions 3 and 4 were not listed there either). A reviewer may prefer to fold the bump into the eventual release decision; it is isolated in commit f338ea0 and can be dropped together with the README edit.

**2. Test helper normalizes whitespace** so line-wrapped guide prose is matched by explicit substrings. No Enum.any?/all? collection assertions used.

## Known Stubs

None.

## Next action

Execute 181-10 in the same candidate, starting from f338ea0. No push, merge or release is authorized. Recovery checkout and the Phase 180 candidate were not modified.

## Self-Check: PASSED

## Orchestrator follow-up fix

Commit 12f84cd9 (`fix(181-09): keep shell template version 4; move offlineIsland note to guides only`) reverted the iOS README.md.eex note and the `@template_version` 4 to 5 bump (and the phase134 hash rewrite), honoring D-20 and the Android freeze. The `.offlineIsland` assertion now lives only against guides/native_shell_upgrade.md. Candidate HEAD: 12f84cd950d4574921767df823faed6797c17c26. Guides, phase134, docs.sync --check, exunit ownership and the full suite (2218 tests, 0 failures) all pass.
