---
phase: 196-spec-and-structure-ratchet
plan: "02"
subsystem: testing
tags: [exunit, optional-proof, manifests, threadline, privacy]
requires:
  - phase: 196-01
    provides: Preserved feature branch, source identity and execution contract
provides:
  - Explicit exclusion of unrequested generated-manifest and Plug proof lanes
  - Fail-closed requested manifest validation against real captured files
  - Executed invalid-input and isolated optional-dependency controls
affects: [196-06, 196-15, 196-17]
tech-stack:
  added: []
  patterns: [merged-exunit-exclusions, subprocess-consumer-controls, closed-diagnostics]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/optional-manifests.json
  modified:
    - test/crosswake/guides/evidence_manifest_test.exs
    - test/test_helper.exs
    - packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs
    - packages/crosswake_threadline/test/test_helper.exs
key-decisions:
  - Any supplied manifest-path value requests proof; generated evidence never uses committed-example artifact fabrication.
  - Optional Plug proof requires MIX_INCLUDE_THREADLINE_PLUG=1 and both real modules; missing dependency controls remove only the subprocess code path.
requirements-completed: []
requirements-addressed: [SPEC-01]
actuals:
  tokens: 4604
  tasks: 2
  commits: 4
commits: 4
plan_head_before: d914f72b1611cd9dc400a4806fda7ccae7881723
plan_head_after: d6f552877523fb2710b94128caff8c70f3e28558
coverage:
  - id: generated-manifest
    description: Unrequested proof is excluded; requested invalid inputs fail with sanitized diagnostics.
    verification:
      - kind: integration
        ref: mix test test/crosswake/guides/evidence_manifest_test.exs
        status: pass
    human_judgment: false
  - id: real-generated-artifact
    description: Existing browser producer supplies a real manifest and captured screenshots to the strict consumer.
    verification:
      - kind: e2e
        ref: npm test -- e2e/route_tour.spec.ts --project=chromium --grep='proves LiveView' --reporter=line
        status: pass
      - kind: integration
        ref: CROSSWAKE_EVIDENCE_MANIFEST_PATH=examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json mix test test/crosswake/guides/evidence_manifest_test.exs
        status: pass
    human_judgment: false
  - id: threadline-plug
    description: Optional-off, isolated missing dependency and real enabled Plug states preserve the other shipment canaries.
    verification:
      - kind: integration
        ref: mix cmd --cd packages/crosswake_threadline mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs
        status: pass
      - kind: integration
        ref: MIX_INCLUDE_THREADLINE_PLUG=1 mix cmd --cd packages/crosswake_threadline mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 02: Strict optional proof lanes Summary

**Unrequested manifest and Plug proofs are explicitly excluded; requested proofs validate real artifacts and dependencies, with sixteen executed subprocess states distinguishing success, exclusion and failure.**

## Accomplishments

- The root helper composes `generated_manifest` into its existing exclusion list only when the path variable is unset. An empty supplied value requests proof and fails. Existing committed-manifest coverage still executes.
- Generated evidence uses its supplied directory and validates file/read/JSON/root/route/capture/artifact prerequisites. Captured routes require nonempty regular artifacts under that directory. Unsupported schema/version or malformed route shapes fail using fixed reason labels without echoing JSON or supplied paths. The committed-example fabrication helper is used only by its existing synthetic fixture tests.
- Threadline composes `threadline_plug` with its existing example-host/advisory exclusions. Requested proof requires both `Plug.Conn` and `Crosswake.Plug.Threadline`, executes `init/1`, and checks the existing header default. All three non-Plug shipment/dependency canaries execute in every child state; the real enabled state covers all four original canaries.
- `196-EVIDENCE/optional-manifests.json` records process exits, integer execution/exclusion counts, relative artifact identity, producer commit, source hashes, and controls. Existing CI producer/consumer commands and browser fixtures were unchanged.

## Execution and source identity

Execution occupied approximately 14:29–14:41 UTC on 2026-10-27 in the existing main checkout on `fix/spec-structure-ratchet`. Initial HEAD was `d914f72b1611cd9dc400a4806fda7ccae7881723`; the prior actual-main base remains `b8398c38`. Source preparation was not repeated, and `docs/195-closeout` remains preserved at `101e853a`.

The existing browser producer ran successfully at `af9a7da5454211ffe60ca8803faac5e73c4880c4`. Its generated manifest contains 33 routes, 20 captured routes and 20 real artifacts. The manifest SHA-256 is `19c6ed9e5511c5ddb5b1af57872734a6556b6cb8be1fe4ef08c56696dc0b45dc`; producer and consumer source hashes are in the receipt. The generated bundle remains in the existing ignored browser-output location; screenshots and payloads were not copied into planning evidence.

## Task commits

| Task | Commit | Result |
| --- | --- | --- |
| 196-02-01 RED | `af9a7da5` | Actual disabled consumer fails the new exclusion assertion |
| 196-02-01 GREEN | `67a46f59` | Strict manifest consumer, exclusions, twelve bad-input controls and real producer receipt |
| 196-02-02 RED | `288762f9` | Actual companion consumer fails the new disabled-canary exclusion assertion |
| 196-02-02 GREEN | `d6f55287` | Strict explicit Plug lane and three executed dependency states |

Each commit ran successful absolute per-file privacy scans conditionally before staging/commit and immediately afterward. No tracked files were deleted. No push, PR, merge, tag, publish, remote deletion or worktree was performed. The four measured commits precede summary/lifecycle metadata; actual tokens are `ceil(18414/4)` over their realized diff.

## Verification

All commands ran sequentially. Root commands ran at repository root; the producer command ran from `examples/phoenix_host`.

| Command | Observed result |
| --- | --- |
| `mix test test/crosswake/guides/evidence_manifest_test.exs` | Exit 0; 10 tests, 0 failures, 1 excluded; final post-task check 8.2s |
| `CROSSWAKE_EVIDENCE_MANIFEST_PATH=examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json mix test test/crosswake/guides/evidence_manifest_test.exs` | Exit 0; 11 tests, 0 failures; 33 routes, 20 captures, 20 artifacts; 6.2s |
| `ERL_FLAGS='+S 2:2' npm test -- e2e/route_tour.spec.ts --project=chromium --grep='proves LiveView' --reporter=line` | Exit 0; 1 real browser test passed; 3.6s |
| `mix cmd --cd packages/crosswake_threadline mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | Exit 0; 4 tests, 0 failures, 1 excluded; 1.6s |
| `MIX_INCLUDE_THREADLINE_PLUG=1 mix cmd --cd packages/crosswake_threadline mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | Exit 0; 5 tests, 0 failures; 1.3s |
| `mix format --check-formatted test/crosswake/guides/evidence_manifest_test.exs test/test_helper.exs packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs packages/crosswake_threadline/test/test_helper.exs` | Exit 0; all touched Elixir formatted explicitly |
| `git diff --check` | Exit 0 |

The twelve requested invalid-manifest children each exit 2 and assert a named closed diagnostic: empty path, missing file, empty file, malformed JSON, wrong root, wrong manifest, wrong version, zero routes, non-map route, zero captures, zero artifacts and missing artifact. Each also asserts that the synthetic private probe and artifact-root path do not appear in output. The disabled child exits 0 with three exclusions (the optional proof plus two recursion-control tests), while all eight committed-manifest examples execute.

Threadline's disabled child exits 0 with three executed tests and two exclusions; its enabled real child exits 0 with four executed tests and only the recursion-control test excluded. Its missing-dependency child removes the real Plug ebin directory from the fresh VM code path, independently checks that `Plug.Conn` cannot load, then executes the actual consumer: four tests, one intended `dependency_required` assertion failure, exit 2. Installed dependency files are not removed or substituted.

The tracer was re-run after its GREEN commit: the entire root file passed again before expansion to the companion implementation. No CI, device, emulator, adopter or broad native-support result is claimed by these local checks.

## TDD evidence

Both initial ExUnit runs failed the intended new exclusion assertion after the real target loaded. The installed RED classifier does not directly parse ExUnit console reports, so native Node TAP assertions wrapped the unchanged actual ExUnit process exits. Both complete native reports returned `RED_EVIDENCE_OK`; semantic inspection confirmed the target assertions failed for the planned behavior rather than dependency-loading or fixture errors.

The locally excluded records are `196-EVIDENCE/tdd-manifest-red.json` (SHA-256 `f4aea0fd733f0242b5084f12504e98648794a9be9a97e6687c7a03e23b628414`) and `196-EVIDENCE/tdd-plug-red.json` (SHA-256 `2128f98ebe44c5f3449642b756128eb4875cf9ef2cbefc8113a2d2a45427c170`). RED precedes GREEN for each task. No refactor-only commit was needed.

## Deviations and issues

- [Rule 3 - Environment] The initial browser launch was denied by the macOS sandbox Mach bootstrap. The same existing producer passed with filesystem escalation; no fixture or browser code changed. An earlier CLI invocation used an ambiguous multi-value project option; the corrected command is recorded above.
- [Rule 3 - Environment] Threadline initially lacked its dependency/build directories. Sharing the root dependencies was rejected by the companion's existing lock, so no shared path override was retained. `mix cmd --cd packages/crosswake_threadline mix deps.get` fetched the existing locked packages but its final Hex registry-cache write was sandbox-denied. Reconciliation showed the package sources present; the unchanged planned test command then compiled and executed them successfully. No install was retried with another name, no package was substituted, and no `mix.exs` or `mix.lock` changed.
- [Rule 1 - Test transport] Passing an empty environment value through `System.cmd` removed it in the child environment. The manifest control now passes the requested path as argv and sets its exact value inside the fresh VM before loading the actual helper. A separate shell/VM probe confirmed that a directly supplied empty environment value is preserved. This keeps absent and empty requests distinct.
- [Rule 3 - Lifecycle] The scoped roadmap updater again returned `missing_phase_details` despite the phase's existing checklist/detail entry. The scoped count, checkbox and exact handoff are updated directly; no flat planning STATE is created. Requirements remain pending because other plans and independent phase verification still own SPEC-01's full acceptance and the other phase requirements.

## Known Stubs

No implementation stubs, skipped tests or unrun plan acceptance commands were added. The pre-existing `with_artifact_fixture/2` writes synthetic fixture bytes for committed-example validator tests (line 603); this is intentional unit-test setup, never a fallback for the generated proof lane. It does not claim browser evidence. Stub and threat-surface scans found no new runtime endpoint, auth path, schema or production file-access surface.

## Next plan

Last completed phase remains 195. Phase196 is executing, 2/17 plans complete; all eight Phase196 requirements and GR-06 remain pending. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at `196-03-PLAN.md`. Do not repeat plans01–02. This executor stops here.

## Self-Check: PASSED

All five declared artifacts and this summary exist. All four task commits are ancestors of HEAD, and the preserved docs ref is unchanged. Dependency declarations/locks, CI wiring and browser fixture sources match the initial HEAD; source hashes in the receipt match the current files. Both planned acceptance commands and real enabled lanes passed after their final code edits.
