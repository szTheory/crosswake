---
phase: 182-loopback-origin-for-local-ios-host
verified: 2026-10-15T01:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-01-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-01-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-02-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-02-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-03-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-03-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-04-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-04-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-05-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-05-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-06-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-06-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-CANDIDATE-MOVE.json"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-FINAL-HEAD.json"
  - ".planning/workstreams/quality-ratchet-release/phases/182-loopback-origin-for-local-ios-host/182-SIMULATOR.json"
covered_digest: "v3:sha256:8dca03ceee80911a11d5deaee03b6f26c5621cc1553491bc9b2abf84229ad8d3"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 182: Loopback Origin for Local iOS Host Verification Report

**Phase Goal:** In an explicit local/dev `:ios_host` mode, the iOS host generator can use an `http` loopback origin so the Phase 180 twin can load `http://127.0.0.1:4790`; production origin validation stays HTTPS-only and fails closed.
**Verified:** 2026-10-15
**Status:** passed
**Re-verification:** No, initial verification

## Plain-language result

I checked the code in the candidate repo (`/private/tmp/crosswake-phase182-impl`, head `da53c54`, tree `d1cbbe30`), not the summaries. The goal is achieved. A host that adds `origin_mode: :local_loopback` can use `http://127.0.0.1[:port]` or `http://localhost[:port]` outside production. Everything else is still denied. Production output is byte-identical to before. The Simulator evidence is bound to the final head. The Phase 180 working copy sits on the same head with its uncommitted work unchanged. Nothing was changed in any repo by this verification. The only file written is this report.

Not claimed: physical iPhone behavior, and whether the Phase 180 gate passes on the new head (it must be rerun, and the move record says so).

## Observable truths (roadmap success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Without `origin_mode: :local_loopback`, only `https://` accepted; `http` denied with an actionable message; mode refused under prod | VERIFIED | My own probe: `http://127.0.0.1:4790` with no mode returns an error naming `origin_mode: :local_loopback` as the repair. The mode with `env: :prod` is refused. A bogus mode value is refused. `https://` under the mode is refused. When Mix is absent the environment defaults to `:prod` (fail closed). A second guard in `IOSHostGeneration.origin_transport/1` blocks hand-built structs with `http` and no mode. |
| 2 | In the mode, only `http://127.0.0.1` / `http://localhost` (optional port) accepted | VERIFIED | Probe accepted 127.0.0.1, 127.0.0.1:4790, localhost, LOCALHOST:8080 (lowercased) and localhost:80 (canonicalized to `http://localhost`, no host rewrite). Probe denied all of these: `[::1]`, 127.0.0.2, 0.0.0.0, a LAN address, `.local`, credentials, path, query, fragment, port 0, port 99999, empty port, `localhost.`, `127.0.0.1.evil.com`, `localhost@evil.com`, `evil.com:80@127.0.0.1`. |
| 3 | Local output uses only `NSAllowsLocalNetworking` plus a `CrosswakeOriginMode` marker, never arbitrary loads; production unchanged and has no ATS exception; Simulator observes a real loopback load | VERIFIED | Template branch in `Info.plist.eex` emits exactly the one-key ATS dict and the marker only under the mode. `NSAllowsArbitraryLoads` appears in `lib/`, `priv/`, `guides/` and the harness only inside the reconcile module's forbidden-key list. Production golden sha `11e97fa8...` matches 182-CANDIDATE.json, and the 17-file production manifest test passes. `182-SIMULATOR.json`: outcome passed, all 8 assertions passed (listener saw the entry GET and the page's own ping, app reported `didFinish`, built plist ATS keys exactly local-networking, a control load of an external http host was refused with -1022 and never reached the listener), cleanup done. Its head and tree equal the verified head and tree, and the candidate was clean. Per instructions I did not rerun it. |
| 4 | Check, inspect and doctor report the mode honestly; physical proof lane refuses it | VERIFIED | Source and tests: doctor warning `ios_host.local_loopback_origin` (error under `--check-publish`), mismatch error, formatter line, `gen.shell --check/--diff` mode-drift block and one-line notice, inspect `host origin:` line, proof lane refusal in both the config-loading path and the generator, guides and renderers updated. 133 tests across the 9 relevant test files pass on the final head (seed 0, 0 failures). |
| 5 | Phase 180 candidate moved onto the 182 head with uncommitted 180-03/180-04 work and pinned tests unchanged; gate rerun noted | VERIFIED | Live check of `/private/tmp/crosswake-phase180-impl`: HEAD `da53c54`, tree `d1cbbe30`, 21 dirty paths. All 21 hashes match `sha256_after` in `182-CANDIDATE-MOVE.json`. The three pinned tests match their recorded hashes. `git diff --binary HEAD | shasum` equals the recorded `e208f105...`. Overlap with the 33 core-changed paths is empty. `gate_rerun_required: true`. |

**Score:** 5/5. No truth is behavior-dependent without behavioral evidence: the ATS and load behavior has the automated Simulator observation, the validator and drift behavior has passing tests plus my own probe.

## Requirements coverage

| Requirement | Source plan(s) | Status | Evidence |
|-------------|----------------|--------|----------|
| LOOP-01 | 182-01 | SATISFIED | Truth 1 |
| LOOP-02 | 182-01 | SATISFIED | Truth 2 |
| LOOP-03 | 182-02, 182-05 | SATISFIED | Truth 3 (Simulator ran; not blocked) |
| LOOP-04 | 182-02, 182-03, 182-04 | SATISFIED | Truth 4 |
| LOOP-05 | 182-06 | SATISFIED | Truth 5 |

All five IDs in REQUIREMENTS.md appear in plans and are accounted for; none orphaned. REQUIREMENTS.md and ROADMAP.md still show these as Pending and the phase as "In Progress"; updating them is bookkeeping for the orchestrator, not a code gap.

## Evaluation of the approved Phase 134 restamp (commit 10000a0)

Sound. The drift test hashes all shell `.eex` templates and exists to force `mix crosswake.bump_template_version` when a template change alters generated output. `@template_version` is the epoch that `crosswake.shell.status` compares against stamped shells to call existing hosts stale. Phase 182 changed `Info.plist.eex` only by adding a branch that renders nothing unless `origin_mode == :local_loopback`. Production bytes are therefore unchanged, so bumping would mark every existing production host stale for no reason. Evidence that the premise holds, which I checked rather than took on trust: the 182-01 test compares all 17 generated files against a base-commit manifest and the plist against a golden byte for byte, both frozen in a commit before any implementation; those tests pass; the golden hash is unchanged; `@template_version 4` is still in `crosswake.gen.shell.ex`; and the drift test passes with the new hash. The only commit touching the drift test changed one hash and added an explaining comment. Residual note: the local-mode plist block is protected by the reconcile module and its tests rather than by the epoch, and a v4-stamped local-mode host cannot be told apart by epoch from a v4 production host, but only the new generator can produce it and mode drift is detected directly. Not a gap.

## Other checks

- Frozen paths (Android, examples, packages, `.github`, `mix.lock`) have no diff between base and head.
- Candidate repo clean at `da53c54`; the recovery checkout was not written to other than this report.
- Privacy: evidence JSONs contain only the loopback test origin, device model and runtime names; no device identifiers, tokens, bundle ids or team ids.
- Anti-patterns: no debt markers or stubs found in the new core modules I read; summaries list Known Stubs as none.
- Deviations disclosed in summaries (hermetic core tag derived from tree hash, run-local SwiftPM cache, offline deps copy) affect only the test harness.

## Gaps

None.

## Human verification

None required. All claims were checked automatically (code review, probes, tests, hash and binding checks).

---

_Verified: 2026-10-15_
_Verifier: Claude (gsd-verifier)_
