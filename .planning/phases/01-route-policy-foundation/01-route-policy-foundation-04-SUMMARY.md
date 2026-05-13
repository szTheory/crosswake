---
phase: 01-route-policy-foundation
plan: 04
subsystem: dx
tags: [elixir, phoenix, mix-task, installer, generator, ios, android]
requires:
  - phase: 01-route-policy-foundation
    provides: router-local policy metadata, compile-time validation, and adoption diagnostics
provides:
  - idempotent Phoenix host installer with explicit router patch markers
  - host-owned Crosswake policy module and install manifest scaffolding
  - iOS and Android shell skeleton generators with ownership handoff docs
  - install guide aligned to the locked Phase 1 taxonomy and boundaries
affects: [manifest, doctor-tooling, native-shell-bootstrap, install-docs]
tech-stack:
  added: []
  patterns: [marker-based-router-patching, host-owned-generated-artifacts, machine-readable-install-manifest]
key-files:
  created:
    - lib/crosswake/install/patcher.ex
    - lib/crosswake/install/manifest.ex
    - lib/mix/tasks/crosswake.install.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/policy_module.ex
    - priv/templates/crosswake/install_manifest.json.eex
    - priv/templates/crosswake/shell/ios/README.md.eex
    - priv/templates/crosswake/shell/android/README.md.eex
    - test/mix/tasks/crosswake_install_test.exs
    - test/mix/tasks/crosswake_gen_shell_test.exs
    - guides/install.md
  modified: []
key-decisions:
  - "Patch existing Phoenix routers additively with explicit markers instead of generating a template-owned host app."
  - "Treat generated Phoenix and native files as host-owned artifacts and say so in both task output and docs."
  - "Keep Phase 1 shell generation limited to skeletons, local fixtures, and handoff docs without implying Phase 3 runtime behavior."
patterns-established:
  - "Installer pattern: marker-based, idempotent patching plus a persisted install manifest for later tooling."
  - "Generator pattern: narrow shell scaffolds include ownership docs and local fixtures but avoid unproven runtime claims."
requirements-completed: [DX-01]
duration: 2min
completed: 2026-05-13
---

# Phase 1 Plan 04: Route Policy Foundation Summary

**Additive Phoenix installer and host-owned iOS/Android shell scaffold generators with manifest tracking and explicit ownership docs**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-13T22:04:56Z
- **Completed:** 2026-05-13T22:06:04Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- Added `mix crosswake.install` to patch Phoenix routers with explicit markers, create a host-owned policy module, and persist a machine-readable install manifest.
- Added `mix crosswake.gen.shell ios|android` to generate narrow native shell skeletons, bundled Phase 1 fixtures, and ownership handoff docs.
- Documented the two-step install path with explicit Phase 1 boundaries, router-local policy authoring, and the reserved `adapter` runtime note.

## Task Commits

1. **Task 1: Implement `mix crosswake.install` as an idempotent host installer** - `233f5c8` (feat)
2. **Task 2: Implement `mix crosswake.gen.shell ios|android` as host-owned shell scaffolding** - `be0d6d3` (feat)
3. **Task 3: Document the install path and ownership boundaries honestly** - `ec002a9` (docs)

## Files Created/Modified
- `lib/mix/tasks/crosswake.install.ex` - additive installer entrypoint and CLI output.
- `lib/crosswake/install/patcher.ex` - explicit marker patching for host router files with idempotent reuse.
- `lib/crosswake/install/manifest.ex` - machine-readable scaffold manifest writer.
- `priv/templates/crosswake/policy_module.ex` - host-owned Crosswake policy module template.
- `priv/templates/crosswake/install_manifest.json.eex` - persisted install manifest template.
- `lib/mix/tasks/crosswake.gen.shell.ex` - iOS and Android shell scaffold generator.
- `priv/templates/crosswake/shell/ios/README.md.eex` - iOS ownership handoff documentation.
- `priv/templates/crosswake/shell/android/README.md.eex` - Android ownership handoff documentation.
- `test/mix/tasks/crosswake_install_test.exs` - installer idempotency and manifest coverage.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - shell generation and ownership doc coverage.
- `guides/install.md` - public additive install path and boundary documentation.

## Decisions Made
- Reused and rewrote the host router import line in place so the installer stays explicit and reviewable instead of hiding behavior in a generated wrapper.
- Left existing generated files untouched on repeat runs to preserve host edits and make idempotent reuse observable in task output.
- Scoped shell output to placeholder source, local fixtures, and ownership docs so the DX does not overclaim manifest activation or native runtime support.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 2 can build doctor and manifest tooling on top of the persisted install manifest and host policy-module shape.
- The install and shell DX now states the Phase 1 taxonomy and ownership boundaries clearly enough for later manifest and shell-boot work to extend without rewording the public contract.

## Self-Check: PASSED
- Summary file exists at `.planning/phases/01-route-policy-foundation/01-route-policy-foundation-04-SUMMARY.md`.
- Task commits `233f5c8`, `be0d6d3`, and `ec002a9` exist in git history.
- Verification rerun passed: `mix test test/mix/tasks/crosswake_install_test.exs test/mix/tasks/crosswake_gen_shell_test.exs`.
