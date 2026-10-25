---
phase: 180-bounded-digital-twin-demonstration
plan: 05
subsystem: example-host generated iOS shell
status: complete
requirements: [TWIN-01, TWIN-02, TWIN-04]
requirements_completed: [TWIN-01, TWIN-02, TWIN-04]
tags: [ios, generated-host, loopback, webkit, avfoundation, observation-log]
key-files:
  created:
    - examples/phoenix_host/native/ios/crosswake_shell/ (generator output plus host-owned files)
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/StudyWebViewController.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/TwinObservationLog.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/StudyPackInstaller.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/StudyAudioCommandDelegate.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShellTests/StudyWebViewControllerTests.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShellTests/StudyAudioCommandDelegateTests.swift
  modified:
    - examples/phoenix_host/config/config.exs
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/CrosswakeShellApp.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/CrosswakeCoordinator.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj
    - .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-IDENTITY.json
    - .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-ORIGIN-DECISION.json
plan_head_before: da53c54db06e54be5a80fb4be144a70d3fed36a5
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
actuals:
  tokens: 60000
  tasks: 3
  commits: 0
---

# Phase 180 Plan 05: Generated iOS host for the twin Summary

The example host now has a generated iOS app bound to the fixed loopback address `http://127.0.0.1:4790`, a visible study WebView that only trusts its own main frame at that address, and a host-owned installer and audio adapter that play the verified installed bytes.

## What was checked and what happened

- The gate check passed before each task (existing path supported, decision not required, 180-04 summary present).
- Task 1: I declared the `:ios_host` host in `examples/phoenix_host/config/config.exs` with `origin_mode: :local_loopback` and generated the app under `MIX_ENV=test`. `mix crosswake.gen.shell ios --check` reports current. The activation fixture has route `offline-study` and origin `http://127.0.0.1:4790`. The generated Info.plist carries only `NSAllowsLocalNetworking` (plus the `CrosswakeOriginMode` marker); `NSAllowsArbitraryLoads` is absent. The project references `packages/crosswake-shell-core-ios` as a local package. The app builds for the owned simulator.
- Task 2: 11 tests in `StudyWebViewControllerTests` pass, using real WKWebView instances and real script messages. They cover forwarding from the own main frame at the primary origin, and dropping messages from a different WebView, from a child frame, and from a different origin (port 4791). They also cover the default persistent data store, the path-class mapping, and the closed observation log (nothing written when the environment flag is unset, out-of-vocabulary records rejected, three separate channel files, exactly five keys, one launch sample per process start).
- Task 3: 12 tests in `StudyAudioCommandDelegateTests` pass: exact registered command, size and SHA-256 checks, atomic replace keeping the previous bytes after a rejected download, 404 reported as media_missing, missing and tampered installed media denied with no network request, unknown asset key denied, real playback with progress above zero from the verified bytes, player held until finish or replaced, and the composition retaining the delegate.
- Full suite: 23 tests, 0 failures. `--check` still passes after the project-file edits.

## Frozen values

- Prepared origin: `http://127.0.0.1:4790` (declared with `origin_mode: :local_loopback`).
- Generated manifest SHA-256: `917ef9d00ee0165853f07d182d980bf6687f596fe9888633cddef14745ac9493`
- Generated activation SHA-256: `085eb4b2af9bb1687b8e44c423f083b7e6fdd42f11f900f1b349c527f3ca48e6`
- Both are recorded in the `generated` object of 180-IDENTITY.json next to the unchanged 180-04 media object (size 33706, SHA-256 `5d8b3f72...bf5b`). The installer's expected size and digest equal the media values.
- 180-ORIGIN-DECISION.json `consumed_by` is now `180-05`.

## What changed

Product files changed only in the candidate `/private/tmp/crosswake-phase180-impl`, uncommitted (commits: 0), as the sequential convention requires. In the recovery checkout only planning files changed; nothing is staged. The owned simulator `crosswake-phase180-unit`, its derived data and all result bundles were deleted. The earlier blocked record is kept as `180-05-BLOCKED.12f84cd.md`.

## Deviations from Plan

1. **[Rule 3 - Blocking] Generation environment and working directory.** The guide says to put `origin_mode` only in dev or runner config, never prod. I put the declaration in `config.exs` (as the plan lists) but inside `if config_env() in [:dev, :test]`, so production config never carries it. The generator finds the local `packages/` directory relative to the working directory, and from `examples/phoenix_host` it saw none and refused (the route declares a host command and needs a local shell core). I generated with `MIX_ENV=test mix run --no-start -e 'File.cd!("../.."); Mix.Tasks.Crosswake.Gen.Shell.run(["ios","--target","examples/phoenix_host"])'`. The result is the same recognized layout.
2. **[Rule 1 - Fact] The manifest digest depends on `MIX_ENV`.** Generating under `dev` gives a different manifest than under `test`; plain `mix crosswake.gen.shell ios --check` (dev) reports stale. The frozen digests are the `MIX_ENV=test` ones, and `--check` was run with `MIX_ENV=test`. 180-06 must generate and check under `MIX_ENV=test`.
3. **[Rule 3 - Blocking] `ONLY_ACTIVE_ARCH=YES` on every xcodebuild call.** Without it the app also builds x86_64 while the local package builds only arm64, so the module is "incompatible" and the build fails. This is a build flag, not a source change.
4. **ATS entry came from the generator.** The plan asked to add `NSAllowsLocalNetworking` to the host Info.plist; the Phase 182 generator already writes it in local mode, so I added nothing by hand.
5. **Presentation case.** The entry route is runtime `offline_island`, so the shell publishes `.offlineIsland(session)`, not `.liveView`. The root view presents the study WebView for both.
6. **Extra host-owned edit.** `CrosswakeCoordinator.swift` (host-owned, not a managed output) now accepts a config and a retained composition, because it built the shell config internally. It was not in the plan's file list.
7. **Capability shape injected into the page.** The study page checks `window.crosswakeBridge.capabilities` as an object keyed by command (the reference host injects an array). The twin injects the session's granted capability map (command to version), which is also what the bridge verifies.
8. **TDD order.** Both test files were written before the implementation files; I did not run a separate failing build before writing the implementation.

## study-session / offline-study mismatch

It did not matter for this plan. The page sends `offline-study` as the bridge route id (matching the session and manifest), so the bridge works. Only `OfflineController.index` builds its island contract under `study-session`; that stays an open note from 180-04, and I did not rename it.

## Unknowns and risks for 180-06

- The generated Info.plist still lists `WKAppBoundDomains` as `example.com` (generator placeholder). I did not set `limitsNavigationsToAppBoundDomains` and did not edit the list. Unit tests cannot show whether WebKit restricts script probes or the bridge for 127.0.0.1 under that list; the first live run in 180-06 will show it.
- The visible controller was tested through its origin gate and observation log, not against a running Phoenix server. The JavaScript probes (island state, outbox counts, retry button) are not exercised yet.
- Roster mapping: a corrupt download records TW-T01-02 failed and TW-T04-05 passed (cause media_corrupt); play against nothing installed records TW-T04-04 passed. 180-06 should confirm that matches its c2 expectation.
- The `launch` key is a per-process ordinal (count of earlier launch samples plus one), not a device identifier.

## Known Stubs

None.

## Threat Flags

None beyond the plan's threat model. The observation log has no free-text field; ATS is local networking only.

## Self-Check: PASSED

- Candidate files exist (four Swift sources, two test files, generated host); `--check` current under `MIX_ENV=test`.
- 180-IDENTITY.json holds both the media and generated objects; the generated digests equal the files.
- Staged files in the recovery checkout: 0. Simulator `crosswake-phase180-unit` no longer listed. No `unit-05-*.xcresult` remains.
