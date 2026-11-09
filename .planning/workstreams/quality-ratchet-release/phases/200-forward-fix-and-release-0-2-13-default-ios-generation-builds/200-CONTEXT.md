# Phase 200: Forward fix and release 0.2.13: default iOS generation builds - Context

**Gathered:** 2026-11-08
**Status:** Ready for planning
**Source:** Phase 199 diagnosis (this session) plus the user's recorded direction: "Follow your recommendations. Go for it." (2026-11-08)

<domain>
## Phase Boundary

Phase 199 published 0.2.12 to Hex, Maven Central and the iOS mirror. Its post-publish iOS clean-room proof then failed (release run 42494651844, job "Clean-room proof - iOS swift build", xcodebuild exit 65: `Unable to open base configuration reference file .../CrosswakeHostSettings.xcconfig`). The run ended PARTIAL (`ios_public_proof`); issue 281 was opened by the failure alert and PR 280 is the next release PR.

Diagnosis (reproduced locally with the exact 0.2.12 source, `lib`, `priv` and `script` at HEAD equal to tag `hex-v0.2.12`):
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` references `CrosswakeHostSettings.xcconfig` unconditionally (six references; added in phase 179-03 `feat(179-03): project declared iOS host settings`). The 0.2.11 template had none.
- `lib/mix/tasks/crosswake.gen.shell.ex` renders host outputs (the xcconfig, manifest and activation fixtures) only when the host declares `:crosswake, :ios_host`. Without it `host_outputs` is nil, the pbxproj is still written, and the xcconfig is not.
- A plain `mix crosswake.gen.shell ios --target DIR` therefore yields a project that cannot build. The first adopter's own configuration is not known to be affected; hosts that declare `:ios_host` write the file.
- No pre-release check builds a default-generated project; the only check that did is the post-publish clean-room, which runs after the irreversible steps.

This phase ships the fix forward as 0.2.13 and adds the gate that would have caught it. It is not a redesign of iOS host generation.

</domain>

<decisions>
## Implementation Decisions

### The defect and its test
- The default iOS generation path (no `:ios_host`) must produce a project whose every referenced file exists.
- A regression test runs the real generator (not a fixture) on the default path and asserts that every file the generated project references is present. Before the fix it fails (six references, no file); after the fix it passes. Record the before and after.
- Output for hosts that declare `:ios_host` is unchanged: managed-output hashes in `test/fixtures/shell/ios/production_generation.sha256.json` and the existing managed-outputs, migration-graph and origin-mode tests keep passing without editing their expectations.

### The pre-release gate
- Add a check that builds the default-generated project with `xcodebuild` (iOS Simulator SDK, code signing off) before any release, so a release can not ship a project that fails this build.
- Measure the check's findings before making it merge-blocking (the project's "absence scored as success" rule): show it failing on the 0.2.12 behavior and passing on the fix, and record its run time and runner cost.
- Keep CI cost in view: use `script/ci_cost_report.sh` after CI runs and flag any duplicated full-suite runs or uncached jobs. Promote into required CI only because it protects a recurring contract with stable, actionable feedback; no new required job without that measurement.

### The release
- The fix is released as 0.2.13 through the same release-please pipeline and the same gated mechanism built in Phase 199 (four protected approval environments, tag gate, ordered publishers Hex then Maven then iOS mirror, post-publish mirror tag check, candidate receipt and trailer).
- Every irreversible step is its own displayed, one-use gate with a plain-language `allow`: the release PR merge, the tags, the Hex publish, the Maven publish, the iOS mirror publish, and any Maven fire-drill dispatch. Approvals are never standing and never transfer from Phase 199 or from this CONTEXT. The user's "Go for it" authorizes the work up to each gate, not the gates.
- A PR to `main` (the fix itself) merges under the standing exception only when Crosswake CI is green on the exact head, with a merge commit pinned to that head, saying which commit CI ran on.
- 0.2.13 is complete only when its release run ends COMPLETE, including the iOS clean-room proof and the exact-public proof, and the ledger entry exists.

### Reconciling 0.2.12
- 0.2.12 is permanent. Nothing is re-run or re-approved under a used `allow`. Release run 42494651844 stays as recorded (PARTIAL).
- Disposition in writing: issue 281, PR 280 (the next release PR) and the PARTIAL status. Whether to retire 0.2.12 on Hex (an advisory only) is a separate one-way decision that needs its own displayed gate if it is made at all; it is not part of the default scope.
- The threadline companion 0.1.1 (PR 262), deferred from Phase 199, is either released after 0.2.13 with its own gates or recorded as deferred with the condition that reopens it.
- Phase 199 plans 13-19 stay on hold. Phase 199 closeout (including pushing the local `docs/199-release-0-2-12` branch, which carries a privacy item: eight retained pre-merge source files contain the maintainer's public noreply commit email) is its own work and is not done by Phase 200.

### Working rules (from AGENTS.md)
- Branch from current `origin/main` as `<type>/<topic>` with a conventional prefix; one PR per change; merge commit only; privacy scan before every push and rescan after any new commit (privacy-193.sh needs absolute paths as separate arguments; use plain `git diff --name-only` for the file list, not zsh-specific forms).
- Never name the real early adopter; use "first adopter".
- Zero-human verification by default: run and check, do not create UAT handoffs for things automation can verify. A plan agent cannot see the user's replies, so the orchestrator displays each gate and performs each gated action itself after a fresh drift recheck.

### Claude's Discretion
- How to fix: make the default path write the settings file, or stop referencing it on the default path, or another approach that makes the default output build. Choose the smallest change that keeps `:ios_host` output byte-identical and is honest about what the default path means, and justify it in the plan.
- Where the new build check lives and how it is invoked (an existing macOS CI job, a release-candidate pre-merge step, a script under `script/`), within the cost rules above.
- The requirement ID(s) for this phase and the plan breakdown, waves and test file names.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project posture and rules
- `AGENTS.md` - working rules, approval gates, standing merge exception, privacy rules
- `.planning/BEARINGS.md` - posture invariants, tripwires, do-not-re-open list
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` - Phase 200 entry and success criteria
- `.planning/workstreams/quality-ratchet-release/STATE.md` - current position and handoff

### The defect
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` - unconditional `CrosswakeHostSettings.xcconfig` references
- `priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex` - the missing file's template
- `lib/mix/tasks/crosswake.gen.shell.ex` - host outputs rendered only with a declared `:ios_host` (see `host_outputs`, `generate_ios_shell/6`)
- `lib/crosswake/shell/ios_host_generation.ex` - renders the settings file and managed outputs
- `lib/crosswake/shell/managed_outputs.ex` - managed output list and publication
- `script/verify_ios_release_host.sh` - the consumer-host clean-room generation the failed job ran
- `test/fixtures/shell/ios/production_generation.sha256.json` and `test/mix/tasks/crosswake_gen_shell_host_test.exs` - existing declared-config expectations that must keep passing

### The release mechanism being reused
- `.github/workflows/release-please.yml` - guard, tag gate, ordered publishers, `release-mirror-tag-check`, `clean-room-proof-ios`
- `script/check_release_workflow_integrity.exs` - scanner roster (currently 106 checks)
- `.planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-DECISIONS.md` - gate protocol (D-01..D-08) every gate here follows
- `.planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-12-SUMMARY.md` and `199-EVIDENCE/core-run-final-199.json` - the PARTIAL run as recorded
- `docs/RELEASE-INCIDENT-RESPONSE.md` - per-step approval gates and the mid-sequence partial-failure runbook

</canonical_refs>

<specifics>
## Specific Ideas

- Reproduction: in this repo at tag `hex-v0.2.12`, `mix crosswake.gen.shell ios --target <empty dir>` writes `native/ios/crosswake_shell/CrosswakeShell.xcodeproj` with six `CrosswakeHostSettings.xcconfig` references and no `CrosswakeHostSettings.xcconfig` file.
- The failing CI evidence: run 42494651844, job "Clean-room proof - iOS swift build"; the error names `.../native/ios/crosswake_shell/CrosswakeHostSettings.xcconfig`.
- The existing release rehearsal for docs (REL-06) was run against published 0.2.11, not a build of the candidate's generated output; the new gate closes that.

</specifics>

<deferred>
## Deferred Ideas

- Retiring 0.2.12 on Hex (advisory only); decide separately and gate it if wanted.
- Phase 199 plans 13-19 and its closeout; the threadline companion release unless folded in after 0.2.13.
- Any redesign of iOS host generation beyond making the default output build.

</deferred>

---

*Phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds*
*Context gathered: 2026-11-08 via the Phase 199 diagnosis and the user's direction*
