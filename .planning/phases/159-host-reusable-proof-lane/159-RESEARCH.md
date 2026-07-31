# Phase 159: Host-Reusable Proof Lane - Research

**Researched:** 2026-07-31
**Domain:** Phoenix-hosted proof-scaffold generation, safe evidence compilation, and bounded iOS XCTest/XCUITest wiring
**Confidence:** HIGH for repository seams; MEDIUM for Apple test-target guidance

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Generate an **isolated, additive proof-lane namespace** beside the host's existing suites. The intended shape is a small Crosswake proof directory under the host's ExUnit tests, Playwright tests/support, and configured iOS shell root. Existing specs, fixtures, router files, application code, and Playwright configuration remain the host's primary corpus and are never reorganized or replaced.
- **D-02:** Every copied file is host-owned from creation. Normal generation writes only missing paths, uses stamped provenance and a versioned desired-state manifest, and never offers `--force` or silent merge behavior. Re-running fills missing scaffold only; it does not overwrite adopter edits.
- **D-03:** The generated browser layer reuses the current semantic sequence—real UI mutation, IndexedDB observation, reconnect through app code, backend assertion, empty outbox, and duplicate idempotency—through configurable helpers. It must not copy the LearnLoop product model, fixture taxonomy, DOM copy, or Ecto schema into the public contract.
- **D-04:** The generator may add new proof-owned files and targets within the configured iOS proof area, but the resulting scaffold must compile and run without destructive rewriting of the adopter's project.
- **D-05:** Use idiomatic Phoenix application configuration as the durable input contract, scoped under `config :crosswake, :proof_lane`. Operational CLI switches select the target/config and action (`generate`, `--check`, `--diff`); route, storage, endpoint, router, and shell values are not repeated as required flags on every run.
- **D-06:** Validate configuration through one closed, typed normalization boundary. It accepts exactly the required route ID/path, IndexedDB database/store, mutation-ID extraction field path, sync endpoint, evidence endpoint, router module, and iOS shell root. Reject unknown keys, missing keys, unsafe path traversal, invalid route/path shapes, and values outside their closed type.
- **D-07:** Mutation-ID extraction is declarative by default—a closed field path such as `client_mutation_id`—rather than evaluated code or a Crosswake-owned domain schema. If a host has a genuinely different record shape, it edits the generated host-owned adapter while the proof contract still requires one opaque correlation reference.
- **D-08:** Endpoints are host-local path values, not remote URLs or credential-bearing strings. Exact host values may live in host configuration and the host-local desired-state manifest, but they never enter retained evidence or Crosswake telemetry/diagnostics.
- **D-09:** Configuration errors are calm, non-echoing, and actionable: stable rule ID, safe configuration key/path, and the remediation command or expected shape. Never print a rejected value. Configuration normalization happens once and feeds every generated language surface so Elixir, TypeScript, shell, and Swift cannot drift independently.
- **D-10:** Generate **real compiling XCTest and XCUITest wiring**, not README-only placeholders. XCTest owns deterministic configuration, evidence-schema, and driver-contract checks. XCUITest alone owns app-process and user-flow behavior: launch, accessibility-driven navigation, terminate, relaunch, reconnect, and observable outcome.
- **D-11:** Use one narrow test-only driver/probe boundary with closed outcomes such as `passed`, `blocked`, and `unavailable`. Missing Phase 160/161 host capabilities must report an explicit blocking prerequisite and must never skip/no-op into a passing device claim. The probe carries opaque references and low-cardinality outcomes only; it has no auth, replay, pack, credential, or mutation authority.
- **D-12:** Phase 159 proves that the harness compiles, launches the shell, preserves the backend-authoritative auth-continuity shape, and can exercise a real terminate/relaunch boundary without clearing the state being tested. Phase 160 plugs scoped replay/account-switch/logout assertions into the same driver. Phase 161 plugs verified install and offline-audio assertions into it. Phase 162 runs that same lane against a physical-device destination.
- **D-13:** XCUITest interacts through stable accessibility identifiers and user-observable states, not DOM internals, Swift implementation details, credentials, or hidden test authority. Backend outcomes come through the configured evidence endpoint.
- **D-14:** Simulator/native-toolchain execution remains advisory and non-promoting. Phase 159 may add deterministic generator/contract checks to recurring CI, but it does not add a permanent physical-device CI lane.
- **D-15:** Use a **library-owned typed allowlist evidence builder plus final-artifact scanning**. A denylist alone is insufficient. Candidate data is validated before serialization; the final staged artifact directory is re-enumerated and scanned before an atomic rename makes evidence available.
- **D-16:** The retained evidence schema is versioned and intentionally small: Crosswake and template/schema versions, commit/ref, opaque route ID, assertion IDs, low-cardinality status/outcome, UTC capture time, retention label, device class, and hashes of specifically approved sanitized contract/artifact bytes. No free-form metadata bag exists.
- **D-17:** Retained proof must reject raw answers, selected-answer content, mutation payloads, account or customer identifiers, credentials, tokens, transcripts, media, endpoints, archive details, stable device identifiers, screenshots, traces, console logs, and raw test output. `.xcresult` bundles are local/ephemeral inputs only and are never uploaded, committed, or treated as the Phase 162 artifact.
- **D-18:** Hash only approved sanitized bytes. Do not hash a payload, token, account/device identifier, or unreviewed binary and call it redacted evidence; a stable hash can itself become a correlating identifier.
- **D-19:** Privacy failures return only a stable rule ID and affected relative path/key. They do not echo the match, value, serialized object, stdout/stderr fragment, or surrounding content. The final scanner must have negative controls for sensitive keys/values and anti-vacuity coverage for newly generated artifact paths.
- **D-20:** `--check` is read-only and machine-oriented: non-zero on invalid configuration, missing required scaffold/wiring, unsafe evidence, stale incompatible provenance, or an output set that generation cannot satisfy without collision. It does not fail merely because a host legitimately edited a host-owned file.
- **D-21:** `--diff` is read-only and human-oriented: show missing paths and safe template changes without printing host configuration values or sensitive content. Existing-file differences are advisory because the files are host-owned; regeneration never applies the diff automatically.
- **D-22:** Evidence generation and checking are fail-closed and atomic. A failed validation or scan leaves no partially promoted evidence artifact. Recovery copy names the failing safe rule and the next command/action, follows the current brand voice, uses text labels rather than color alone, and keeps normal success output brief.
- **D-23:** Preserve the three-day extraction stop. If the isolated helpers cannot parameterize the current host browser proof and produce executable iOS wiring inside the time-box, stop generalizing and copy the smallest adopter-specific proof slice. Do not respond by adding a generic test framework, sync abstraction, Xcode project manager, evidence dashboard, or device orchestration service.

### the agent's Discretion

The user selected all four areas and delegated a coherent one-shot recommendation after parallel research. Planning may choose exact internal module names, generated filenames, config schema implementation, exit-code numbers, manifest encoding, and non-destructive Xcode wiring mechanism. It may not weaken host ownership, executable device wiring, explicit unavailable states, browser test preservation, allowlist evidence, non-echoing privacy failures, or the time-box escape hatch.

### Deferred Ideas (OUT OF SCOPE)

- Phase 160 owns scoped replay, logout/account-switch stops, endpoint reauthorization, and auth safety behavior plugged into this harness.
- Phase 161 owns real foreground pack installation, integrity, atomic placement, and offline audio behavior plugged into this harness.
- Phase 162 owns the dated physical-iPhone run and final narrow support claim.
- Generic test orchestration, generic sync/storage, background work, Android parity/device proof, raw `.xcresult` retention, and an evidence dashboard remain outside v21.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PROOF-01 | Generate configurable host-owned ExUnit, Playwright, shell, and device scaffolding without overwrites. | Missing-only generator, provenance manifest, containment and lifecycle tests. |
| PROOF-02 | Accept route, IndexedDB, mutation extraction, endpoints, router, and iOS shell root. | One closed `ProofLane.Config.normalize/1` boundary; config-only secret-safe inputs. |
| PROOF-03 | Preserve host browser/unit/fixture corpus; add only non-browser boundaries. | Parameterized support helper plus XCTest/XCUITest boundary split. |
| PROOF-04 | Reject raw payloads, account IDs, media, tokens, and stable device IDs from evidence. | Typed allowlist compiler, staged-directory final scan, atomic promotion, negative controls. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first route-policy/runtime-contract scope; do not generalize into a UI framework. [VERIFIED: AGENTS.md]
- Keep route runtime ownership explicit; bridge contracts remain typed, versioned, semantic, and low-frequency. [VERIFIED: AGENTS.md]
- Keep one offline mutation island honest; preserve fail-closed denials and one-command host proof. [VERIFIED: AGENTS.md]
- v21 is iOS-only: no Android features, templates, parity, proof, or release work. [VERIFIED: AGENTS.md]
- Do not put sensitive payload, identity, credentials, tokens, media, transcripts, endpoints, or stable device IDs in evidence, diagnostics, logs, telemetry, or proof artifacts. [VERIFIED: AGENTS.md]
- Use automated checks as the gate where possible; physical-device connection may need setup, but assertions and evidence evaluation remain automated. [VERIFIED: AGENTS.md]

## Summary

Phase 159 should be a compact generator-plus-library slice, not a new test system. The existing shell generator already has the right lifecycle precedents: a manifest-backed read-only diff branch and missing-only generation, while the native-controls generator demonstrates explicit provenance stamps, containment checks, and host-owned reruns. The current Playwright helper already proves the required browser sequence—real UI mutation, IndexedDB observation, app-driven reconnect, backend confirmation, empty outbox, and idempotent duplicate replay—so extraction means parameterizing that helper's contract, not copying its fictional model or fixtures. [VERIFIED: codebase grep]

Use one normalized `config :crosswake, :proof_lane` input to render all generated surfaces. The library should own validation, manifests, evidence schema/scanning, and deterministic contract tests; the generated host owns its adapter, selectors, fixtures, router integration, and every copied file. Keep iOS process testing in a separate XCUITest target: Apple documents `XCUIApplication` as the proxy that launches, terminates, and monitors the app, while XCTest/XCUITest targets cover direct contract and UI-flow work respectively. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication]

**Primary recommendation:** Implement a no-new-dependency `mix crosswake.gen.proof_lane ios` around a closed Elixir config/manifest/evidence compiler, copied host-owned ExUnit/Playwright/XCTest/XCUITest adapters, and a generated proof-owned iOS target; enforce missing-only generation, read-only check/diff, and staged allowlist evidence promotion.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Config normalization and generation lifecycle | API / Backend | — | Mix/Elixir owns typed contract validation and safe filesystem behavior. [VERIFIED: codebase grep] |
| Browser offline proof | Browser / Client | API / Backend | Playwright observes IndexedDB and UI; app-driven sync plus evidence endpoint confirm backend state. [VERIFIED: codebase grep] |
| Replay/auth outcomes | API / Backend | Browser / Client | Phase 159 only preserves the backend-authoritative seam; Phase 160 supplies authorization/replay assertions. [VERIFIED: 159-CONTEXT.md] |
| Shell boot and kill/relaunch | Browser / Client | API / Backend | XCUITest controls the app process through accessible UI and obtains low-cardinality backend outcome through the endpoint. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication] |
| Retained evidence | API / Backend | CDN / Static | Elixir compiles and scans safe bytes before a local artifact is promoted; no raw runtime artifact is retained. [VERIFIED: 159-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Elixir/Mix + existing `Jason` | `jason` 1.4.5 locked | Mix task, typed normalization, manifest/evidence JSON. | Existing project dependency and generator precedent; no package addition. [VERIFIED: mix.lock] |
| Existing Playwright + TypeScript | Playwright 1.60.0 lock; TypeScript 5.9.3 | Retain browser/island semantic proof and parameterized host adapter. | Existing host proof stack; no parallel browser framework. [VERIFIED: examples/phoenix_host/package-lock.json] |
| XCTest + XCUITest | Xcode 26.6 locally installed | Contract/wiring checks and app lifecycle/UI path. | Apple-supported test target split; UI automation controls launch/terminate. [CITED: https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| Elixir standard library (`Path`, `File`, `:crypto`) | OTP 28 local | Containment, atomic files, SHA-256 of approved bytes. | Implement safe lifecycle without widening dependencies. [VERIFIED: local environment] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Extract existing Playwright helper | New generic mobile/device framework | Violates the three-day stop and replaces host primary coverage. [VERIFIED: 159-CONTEXT.md] |
| Static generated Xcode target/project fragment | Xcode project manager dependency | Adds a new general-purpose tool and collision surface; prohibited by the time-box. [VERIFIED: 159-CONTEXT.md] |
| Typed allowlist plus scan | Denylist-only redaction | Cannot safely represent the closed retention contract. [VERIFIED: 159-CONTEXT.md] |

**Installation:** No packages should be installed for this phase. [VERIFIED: codebase grep]

## Package Legitimacy Audit

Not applicable: Phase 159 uses existing locked dependencies and platform frameworks; it must not introduce an external package. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
host config :crosswake, :proof_lane
             |
             v
ProofLane.Config.normalize/1 --invalid--> safe rule-id/key + non-zero check
             |
             v
desired-state manifest + provenance stamps
             |
             +--> missing-only copied ExUnit / Playwright host adapters
             +--> proof-owned XCTest + XCUITest source and iOS target wiring
             |
             v
browser: UI -> IndexedDB -> app reconnect -> host backend assertion
XCUITest: launch -> accessibility UI -> terminate -> relaunch -> evidence endpoint
             |
             v
typed Evidence.build -> stage dir -> enumerate + final scan -> atomic rename
                                      |                         |
                                      +--unsafe--> safe rule-id/path, no artifact
```

### Recommended Project Structure

```text
lib/crosswake/proof_lane/          # config, desired state, evidence compiler/scanner
lib/mix/tasks/crosswake.gen.proof_lane.ex
priv/templates/crosswake/proof_lane/ios/
test/crosswake/proof_lane/         # pure normalization/evidence/scanner tests
test/mix/tasks/                    # no-clobber, check, diff byte/no-write tests
examples/phoenix_host/e2e/support/ # refactored configurable helper; existing spec stays primary
```

### Pattern 1: Normalize once, render many

**What:** Parse `Application.get_env(:crosswake, :proof_lane)` into one closed struct, then pass only that struct to manifest, templates, and command behavior. [VERIFIED: 159-CONTEXT.md]

**When to use:** Always; no template or CLI branch may parse host values independently. [VERIFIED: 159-CONTEXT.md]

```elixir
# Source: repository generator + Phase 159 locked contract
with {:ok, config} <- Crosswake.ProofLane.Config.normalize(Application.get_env(:crosswake, :proof_lane)),
     :ok <- Crosswake.ProofLane.Check.run(config) do
  Crosswake.ProofLane.Generate.missing_only(config)
end
```

### Pattern 2: Host ownership plus desired-state observability

**What:** Stamp every initially copied file; write a versioned manifest of desired paths/template versions; on rerun, create only absent files. Existing bytes are advisory in `--diff`, never merge inputs. [VERIFIED: codebase grep]

**When to use:** Every generated ExUnit, TS, Swift, project-wiring, and guide file. [VERIFIED: 159-CONTEXT.md]

### Pattern 3: Boundary-specific test targets

**What:** XCTest asserts deterministic configuration/schema/driver contracts; XCUITest alone launches, navigates using accessibility identifiers, terminates, relaunches, and asserts observable outcome. Apple describes UI testing as using controls rather than direct app-code execution. [CITED: https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project]

**When to use:** Do not use XCUITest to duplicate Playwright's browser proof or to inspect DOM/private Swift state. [VERIFIED: 159-CONTEXT.md]

### Pattern 4: Validate, stage, scan, promote

**What:** Serialize only a typed allowlist; write to a sibling staging directory, recursively enumerate every candidate path, scan safe textual/structured content and reject forbidden keys/values, then atomically rename only after all checks pass. [VERIFIED: 159-CONTEXT.md]

**When to use:** Every retained evidence write and `--check` evidence inspection. [VERIFIED: 159-CONTEXT.md]

### Anti-Patterns to Avoid

- **Replacing host suites/config:** violates host ownership and destroys the primary corpus. [VERIFIED: 159-CONTEXT.md]
- **`--force`, three-way merge, or automatic diff apply:** can silently overwrite host edits. [VERIFIED: 159-CONTEXT.md]
- **Evaluated mutation extractors:** permits code/config authority where only a closed field path is needed. [VERIFIED: 159-CONTEXT.md]
- **Device test skip/no-op for unimplemented Phase 160/161 behavior:** emit `blocked`/`unavailable`, never a passing claim. [VERIFIED: 159-CONTEXT.md]
- **Retaining `.xcresult`, screenshots, traces, logs, or raw output:** these are local inputs, not safe evidence. [VERIFIED: 159-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Browser offline test system | New generic test harness | Existing Playwright helper/spec refactored behind config. | It already proves real UI, IndexedDB, reconnect, backend state, outbox-empty, and idempotency. [VERIFIED: codebase grep] |
| Host-file update engine | Merge/force regeneration | Missing-only copy, stamps, manifest, read-only check/diff. | Existing generators establish safe host ownership. [VERIFIED: codebase grep] |
| iOS process automation | Custom simulator shell scripts | XCUITest's `XCUIApplication` target. | Platform API launches/terminates and awaits app state. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication] |
| Redaction policy | Free-form metadata or denylist | Typed allowlist evidence builder + final scan. | Existing diagnostic exporter shows fail-closed closed-key design. [VERIFIED: codebase grep] |

**Key insight:** Crosswake owns a small proof contract and safe generation lifecycle; hosts own their domain fixtures, selectors, routes, and adapters. [VERIFIED: 159-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Mutating host-owned files during a “safe” rerun
**What goes wrong:** regeneration overwrites a legitimate adapter edit or rewrites a host project. [VERIFIED: 159-CONTEXT.md]
**How to avoid:** assert target containment before every write; `File.read` first; create only `:enoent`; test byte-identical reruns and `--diff` snapshots. [VERIFIED: codebase grep]

### Pitfall 2: Treating a device test as a second browser suite
**What goes wrong:** private DOM/implementation probing duplicates browser coverage and becomes fragile. [VERIFIED: 159-CONTEXT.md]
**How to avoid:** browser keeps semantic offline/replay proof; XCUITest limits itself to shell boot, accessible flow, terminate/relaunch, and backend outcome. [VERIFIED: 159-CONTEXT.md]

### Pitfall 3: A passing test with absent later-phase capabilities
**What goes wrong:** a skipped/no-op probe promotes unimplemented auth/replay/audio claims. [VERIFIED: 159-CONTEXT.md]
**How to avoid:** closed `passed | blocked | unavailable` driver results, with stable prerequisite rule IDs. [VERIFIED: 159-CONTEXT.md]

### Pitfall 4: Sanitizing before serialization but not scanning final output
**What goes wrong:** an extra generated file or attachment bypasses the allowlist. [VERIFIED: 159-CONTEXT.md]
**How to avoid:** stage, re-enumerate, scan, and atomic-rename; test negative controls and generated-path anti-vacuity. [VERIFIED: 159-CONTEXT.md]

## Code Examples

### Non-destructive check/diff shape

```elixir
# Source: existing Mix.Tasks.Crosswake.Gen.Shell diff-no-write precedent
case action do
  :check -> Crosswake.ProofLane.Check.run(config) # no File.write
  :diff -> Crosswake.ProofLane.Diff.render(config) # no File.write
  :generate -> Crosswake.ProofLane.Generate.missing_only(config)
end
```

### XCUITest lifecycle boundary

```swift
// Source: Apple XCUIApplication documentation
let app = XCUIApplication()
app.launch()
XCTAssertTrue(app.staticTexts["crosswake-proof-ready"].waitForExistence(timeout: 10))
app.terminate()             // do not clear app persistence
app.launch()
XCTAssertTrue(app.staticTexts["crosswake-proof-relaunched"].waitForExistence(timeout: 10))
```

### Evidence promotion shape

```elixir
# Source: Phase 159 D-15 through D-22
with {:ok, evidence} <- Evidence.build(allowed_input),
     :ok <- Evidence.write_stage(stage, evidence),
     :ok <- Evidence.scan_stage(stage),
     :ok <- File.rename(stage, final) do
  :ok
else
  {:error, {rule_id, safe_path}} -> {:error, {rule_id, safe_path}}
end
```

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Browser-only or README-only native proof | Separate executable XCTest contract and XCUITest UI targets. | Keeps deterministic checks fast and lifecycle assertions real. [CITED: https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project] |
| Evidence manifest with broad example-host vocabulary | Small versioned allowlist plus final artifact scan. | Prevents evidence from becoming a data-exfiltration surface. [VERIFIED: 159-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A static proof-owned Xcode target/project fragment can be added under the configured shell root without a project-manager dependency. | Architecture Patterns | If host Xcode layouts defeat the bounded fragment, invoke D-23 and copy the smallest adopter-specific slice. [ASSUMED] |

## Open Questions

1. **Exact non-destructive Xcode wiring mechanism**
   - What we know: the current generated project template already has a unit-test target and project file baseline. [VERIFIED: codebase grep]
   - What's unclear: whether a proof-owned companion `.xcodeproj` is sufficient for the target host or a host-local copied project fragment is required. [ASSUMED]
   - Recommendation: spike only the current example-host layout first; if safe reusable wiring is not executable within the three-day limit, take D-23's adopter-specific slice. [VERIFIED: 159-CONTEXT.md]

2. **Sanitized adopter configuration values**
   - What we know: TODO-002 remains open and adopter-instance completeness is `unknown_blocking`. [VERIFIED: STATE.md]
   - What's unclear: real route/storage/endpoint/selector values. [VERIFIED: FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md]
   - Recommendation: ship only configuration validation/scaffold capability; do not promote external-host or physical-device support. [VERIFIED: 159-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix | Generator and tests | ✓ | OTP 28 | — [VERIFIED: local environment] |
| Node/npm | Existing Playwright helper | ✓ | Node 22.14.0 / npm 11.1.0 | — [VERIFIED: local environment] |
| Host Playwright dependencies | Existing browser proof | ✓ | installed under `examples/phoenix_host` | Existing host runner remains primary. [VERIFIED: local environment] |
| Xcode/XCTest/XCUITest | Compile/wiring and simulator-advisory test | ✓ | Xcode 26.6 | Keep simulator run advisory; physical destination belongs to Phase 162. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None for Phase 159 scaffold/contract work. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit; existing Playwright; generated XCTest/XCUITest. [VERIFIED: codebase grep] |
| Config file | `mix.exs`, `examples/phoenix_host/playwright.config.ts`, generated Xcode project. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane` (Wave 0 files). [ASSUMED] |
| Full suite command | `mix test` plus the existing host Playwright offline spec; generated shell verification remains advisory. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| PROOF-01 | Missing-only generation, stamps, containment, rerun no-clobber | ExUnit Mix-task | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs` | ❌ Wave 0 |
| PROOF-02 | Closed config rejects unknown/missing/unsafe values non-echoingly | ExUnit unit | `mix test test/crosswake/proof_lane/config_test.exs` | ❌ Wave 0 |
| PROOF-03 | Helper preserves semantic browser sequence; iOS source/target compiles | Playwright structural + generated-project build | existing offline spec; `script/verify_generated_ios_shell.sh` adapted | ❌ Wave 0 |
| PROOF-04 | allowlist, final scan, atomic no-promotion, negative controls | ExUnit unit/integration | `mix test test/crosswake/proof_lane/evidence_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused ExUnit test file plus formatter. [ASSUMED]
- **Per wave merge:** `mix test`; existing browser proof when its helper changes. [VERIFIED: codebase grep]
- **Phase gate:** full suite green; simulator/native execution advisory only, never promotion. [VERIFIED: AGENTS.md]

### Wave 0 Gaps

- [ ] `test/mix/tasks/crosswake_gen_proof_lane_test.exs` — generator/check/diff/no-clobber/containment.
- [ ] `test/crosswake/proof_lane/config_test.exs` — normalized closed config and non-echo errors.
- [ ] `test/crosswake/proof_lane/evidence_test.exs` — allowlist/final scan/atomic promotion/negative controls.
- [ ] Generated iOS XCTest/XCUITest fixture target compile test, extending the existing shell verification seam.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Evidence driver has no auth authority; Phase 160 plugs backend reauthorization. [VERIFIED: 159-CONTEXT.md] |
| V3 Session Management | yes | Preserve backend-authoritative auth continuity; do not clear state under test. [VERIFIED: 159-CONTEXT.md] |
| V4 Access Control | yes | Host evidence endpoint and later replay authorization remain backend-owned. [VERIFIED: 159-CONTEXT.md] |
| V5 Input Validation | yes | One closed typed config normalization boundary, path containment, unknown-key rejection. [VERIFIED: 159-CONTEXT.md] |
| V6 Cryptography | yes | Hash only explicitly approved sanitized bytes via platform crypto; never hash sensitive identifiers/payloads. [VERIFIED: 159-CONTEXT.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Config path traversal/collision | Tampering | Expand/contain every destination; missing-only write; `--check` fails collision. [VERIFIED: 159-CONTEXT.md] |
| Secrets or identity in CLI/evidence/logs | Information disclosure | Config file inputs, non-echoing errors, typed allowlist, final scanner. [VERIFIED: 159-CONTEXT.md] |
| Unsafe staged artifact promoted after partial failure | Tampering | Stage directory plus final scan plus atomic rename; no final artifact on failure. [VERIFIED: 159-CONTEXT.md] |
| False device-proof pass | Repudiation | Closed driver outcomes; `blocked`/`unavailable` are failures to promote, not skips. [VERIFIED: 159-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Repository generator/proof/evidence sources named in `159-CONTEXT.md` — lifecycle, browser proof, allowlist, and Xcode baseline inspected. [VERIFIED: codebase grep]
- `AGENTS.md`, ADR, route-policy map, state, roadmap, requirements, and Phase 159 context — locked scope and privacy constraints. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- [Apple XCUIApplication documentation](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication) — launch, terminate, app state. [CITED: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication]
- [Apple adding tests to Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project) — unit/UI target split and UI controls. [CITED: https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies are existing locked/project or local platform tools. [VERIFIED: codebase grep]
- Architecture: HIGH — locked phase decisions align with existing generator/evidence seams. [VERIFIED: codebase grep]
- Pitfalls: HIGH — directly constrained by D-01 through D-23 and existing regression tests. [VERIFIED: codebase grep]

**Research date:** 2026-07-31
**Valid until:** 2026-08-30 for repository patterns; recheck Apple/Xcode behavior before changing test target mechanics.
