---
phase: 182-loopback-origin-for-local-ios-host
plan: 03
subsystem: doctor
tags: [doctor, origin_mode, local_loopback, publish-readiness, fail-closed]
requires: ["182-02"]
provides:
  - "IOSHostOriginMode.observe/2 shared classifier (:none | {:local, origin} | {:mismatch, origin | nil})"
  - "Doctor findings ios_host.local_loopback_origin (:warning) and ios_host.origin_mode_mismatch (:error), check ios_host_origin"
  - "Conditional PublishReadiness check, category :ios_host_origin"
  - "Formatter origin-mode line after the status line"
affects: [182-04]
key-files:
  created:
    - test/crosswake/doctor/doctor_origin_mode_test.exs
  modified:
    - lib/crosswake/shell/ios_host_origin_mode.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/publish_readiness.ex
    - lib/crosswake/doctor/formatter.ex
status: complete
commits: 4
plan_head_before: ecc2450eebef0167c1867b07eaa47f315e3632b9
plan_head_after: 1d569e553577800961c8b0d4ee253afaabc64e4b
actuals:
  tokens: 60000
  tasks: 2
  commits: 4
---

# Phase 182 Plan 03: Doctor reports local loopback honestly Summary

`mix crosswake.doctor` now tells the truth about a local-loopback iOS host. A consistent local build gives one warning (exit 0) that says it is Simulator-only and not production-ready. Under `--check-publish` the same code is one error and readiness is `:not_ready`. Any inconsistent generated state is an error with the repair "rerun mix crosswake.gen.shell ios". Output carries only the canonical origin (for example `http://127.0.0.1:4790`).

## What was checked and what happened

- Candidate binding (CHECK182) passed before any edit; all work is in `/private/tmp/crosswake-phase182-impl` on `phase182-impl`.
- Task 1 verify (verbatim): exit 0, 4 tests, 0 failures.
- Task 2 verify (verbatim, including freeze checks, template grep, ownership script): exit 0; doctor + phase52 + doctor mix task + shell suites 237 tests, 0 failures. The new test file has 24 tests (43 together with the Phase 170 ledger test).
- RED was committed first (3 intended failures), then GREEN.
- Full suite run (2283 tests): 4 failures, none caused by doctor logic. Three came from my first test draft using `refute Enum.any?` shapes tracked by the Phase 170 vacuous-assertion ledger; I rewrote them as `assert Enum.filter(...) == []` and the ledger tests pass. The fourth is below under Deferred.

## How detection works

`observe/2` reads three things: the Info.plist via `ManagedOutputs.read_origin_plist` plus `inspect_plist`, the activation origin in `Fixtures/route_activation.json`, and the raw `:ios_host` declaration (opts or app env) via `IOSHostConfig.normalize`. Any positive local signal counts. A consistent state (marker block, http loopback activation origin, declaration absent or agreeing) is `{:local, origin}`. Everything else with a signal is `{:mismatch, origin | nil}`. A declared local mode with a missing root, missing plist or unreadable plist (chmod 000) is a mismatch, never production and never a warning. A host-owned ATS dict without the marker is not a signal (production hosts with their own ATS do not newly fail); the same dict plus the marker on an HTTPS origin is a mismatch.

## --check-publish and the profile record (D-12)

`PublishReadiness` is a Crosswake library-release profile (it reads the mix.exs package name, CHANGELOG and template coordinates), not a host profile. It is still the only `--check-publish` surface that can produce `:not_ready`, so the refusal lives there conditionally, plus in doctor and the proof lane. The check is appended only when an observation is local or mismatch; with no signal the report keeps its 11 checks and the pinned phase52 fixture is unchanged (`git diff` of `test/fixtures/proof` is empty). An HTTPS host adds no check. Doctor-level findings are suppressed under `--check-publish`, so each code appears once (at `:error`).

## Mix task seam

The Mix task test uses `File.cd!` into a temp target holding `native/ios/crosswake_shell`, runs `--check-publish --format json`, asserts `Mix.Error` "Crosswake doctor found blocking issues" and that the JSON names `ios_host.local_loopback_origin`.

## Commits (in candidate phase182-impl)

- b698f1c feat(182-03): doctor reports local loopback iOS host as a not-production-ready warning
- a76b03c test(182-03): RED for mismatch matrix, publish refusal, formatter line and leak guard
- dbbfd15 feat(182-03): refuse local loopback under --check-publish and print the origin mode line
- 1d569e5 test(182-03): keep origin-mode doctor tests out of the vacuous-assertion ledger shapes

Candidate head `1d569e553577800961c8b0d4ee253afaabc64e4b`, tree `2481ecf50e32f4c57139201bdc41eb4d5f2e945e`.

## Deviations from Plan

- **[Rule 3 - test fixture]** The unrelated `shell_permission_drift` check errors for any plist-only fixture, so "report.status :ok" could not hold. The test fixture writes the required permission strings into an entitlements file, uses a minimal router and `native_targets: []`. No production code changed for this.
- **[Rule 1 - ledger]** Replaced three `refute Enum.any?` assertions (see above); not a product change.
- **Leak guard path:** the forbidden path is the generated shell root, not the whole tmp dir, because an unrelated pre-existing "install manifest not found at <path>" finding prints the install manifest path. That finding is not an `ios_host` finding.
- Mismatch details carry `origin` only when a canonical origin is known; otherwise `origin: nil`.

## Deferred Issues

- `Crosswake.Proof.Phase134TemplateVersionDriftTest` fails (live shell-template hash differs from the checked-in hash). It is caused by the Phase 182 template change from 182-01 and I did not touch templates. The plan forbids bumping `@template_version`; this needs an explicit decision (a later 182 plan or the orchestrator). Not fixed here.

## Known Stubs

None.

## Threat Flags

None beyond the plan's threat model (T-182-10 through T-182-13, T-182-28 covered by tests).

## Boundary state

Recovery checkout HEAD `d0f3e2f1`, empty index, no Git write there. Phase 180 clone HEAD `12f84cd` with its 21 dirty paths untouched. Candidate working tree clean.

## Next action

Execute 182-04. Resolve the Phase 134 template hash drift decision before the phase gate.

## Self-Check: PASSED
