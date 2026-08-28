# Phase 159: Host-Reusable Proof Lane - Context

**Gathered:** 2026-07-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `mix crosswake.gen.proof_lane ios` as a bounded, three-day extraction of the existing
Crosswake proof posture into configurable host-owned scaffolding. The task must preserve an
adopter's browser, unit, and fixture corpus; add only the shell/device boundaries the browser
cannot prove; provide non-destructive generate/diff/check behavior; and ensure retained evidence
cannot contain sensitive payload or identity data.

This phase establishes executable proof infrastructure, not the later behavior it will exercise.
Phase 160 supplies scoped replay/auth assertions, Phase 161 supplies verified pack/audio
assertions, and Phase 162 runs the completed lane on a physical iPhone. Phase 159 does not build a
generic sync engine, pack store, device farm, Android lane, new dashboard, or new support taxonomy.
TODO-002 and adopter-instance completeness remain `unknown_blocking`; the configurable scaffold may
ship, but no external-host or physical-device support claim may be promoted from it.

</domain>

<decisions>
## Implementation Decisions

### Host integration footprint

- **D-01:** Generate an **isolated, additive proof-lane namespace** beside the host's existing
  suites. The intended shape is a small Crosswake proof directory under the host's ExUnit tests,
  Playwright tests/support, and configured iOS shell root. Existing specs, fixtures, router files,
  application code, and Playwright configuration remain the host's primary corpus and are never
  reorganized or replaced.

- **D-02:** Every copied file is host-owned from creation. Normal generation writes only missing
  paths, uses stamped provenance and a versioned desired-state manifest, and never offers `--force`
  or silent merge behavior. Re-running fills missing scaffold only; it does not overwrite adopter
  edits.

- **D-03:** The generated browser layer reuses the current semantic sequence—real UI mutation,
  IndexedDB observation, reconnect through app code, backend assertion, empty outbox, and duplicate
  idempotency—through configurable helpers. It must not copy the LearnLoop product model, fixture
  taxonomy, DOM copy, or Ecto schema into the public contract.

- **D-04:** The generator may add new proof-owned files and targets within the configured iOS
  proof area, but the resulting scaffold must compile and run without destructive rewriting of the
  adopter's project. Exact Xcode integration mechanics are left to research/planning; preserving
  host files and producing an executable lane are both acceptance constraints.

### Configuration contract

- **D-05:** Use idiomatic Phoenix application configuration as the durable input contract, scoped
  under `config :crosswake, :proof_lane`. Operational CLI switches select the target/config and
  action (`generate`, `--check`, `--diff`); route, storage, endpoint, router, and shell values are
  not repeated as required flags on every run. This keeps reruns reviewable and avoids leaking
  values through shell history or CI command lines. — **Reversibility:** costly — the configuration
  keys and normalized manifest become adopter-facing generator contracts.

- **D-06:** Validate configuration through one closed, typed normalization boundary. It accepts
  exactly the required route ID/path, IndexedDB database/store, mutation-ID extraction field path,
  sync endpoint, evidence endpoint, router module, and iOS shell root. Reject unknown keys, missing
  keys, unsafe path traversal, invalid route/path shapes, and values outside their closed type.

- **D-07:** Mutation-ID extraction is declarative by default—a closed field path such as
  `client_mutation_id`—rather than evaluated code or a Crosswake-owned domain schema. If a host has
  a genuinely different record shape, it edits the generated host-owned adapter while the proof
  contract still requires one opaque correlation reference.

- **D-08:** Endpoints are host-local path values, not remote URLs or credential-bearing strings.
  Exact host values may live in host configuration and the host-local desired-state manifest, but
  they never enter retained evidence or Crosswake telemetry/diagnostics.

- **D-09:** Configuration errors are calm, non-echoing, and actionable: stable rule ID, safe
  configuration key/path, and the remediation command or expected shape. Never print a rejected
  value. Configuration normalization happens once and feeds every generated language surface so
  Elixir, TypeScript, shell, and Swift cannot drift independently.

### Device scaffold readiness

- **D-10:** Generate **real compiling XCTest and XCUITest wiring**, not README-only placeholders.
  XCTest owns deterministic configuration, evidence-schema, and driver-contract checks. XCUITest
  alone owns app-process and user-flow behavior: launch, accessibility-driven navigation,
  terminate, relaunch, reconnect, and observable outcome.

- **D-11:** Use one narrow test-only driver/probe boundary with closed outcomes such as `passed`,
  `blocked`, and `unavailable`. Missing Phase 160/161 host capabilities must report an explicit
  blocking prerequisite and must never skip/no-op into a passing device claim. The probe carries
  opaque references and low-cardinality outcomes only; it has no auth, replay, pack, credential,
  or mutation authority.

- **D-12:** Phase 159 proves that the harness compiles, launches the shell, preserves the
  backend-authoritative auth-continuity shape, and can exercise a real terminate/relaunch boundary
  without clearing the state being tested. Phase 160 plugs scoped replay/account-switch/logout
  assertions into the same driver. Phase 161 plugs verified install and offline-audio assertions
  into it. Phase 162 runs that same lane against a physical-device destination.

- **D-13:** XCUITest interacts through stable accessibility identifiers and user-observable
  states, not DOM internals, Swift implementation details, credentials, or hidden test authority.
  Backend outcomes come through the configured evidence endpoint. This preserves the JTBD: a solo
  Phoenix maintainer can run one command and learn whether the real host crossing worked, where it
  stopped, and which owner must fix it.

- **D-14:** Simulator/native-toolchain execution remains advisory and non-promoting. Phase 159 may
  add deterministic generator/contract checks to recurring CI, but it does not add a permanent
  physical-device CI lane. Device connection or signing may require bounded human setup; the
  assertions and evidence evaluation remain automated.

### Evidence safety and generated-file lifecycle

- **D-15:** Use a **library-owned typed allowlist evidence builder plus final-artifact scanning**.
  A denylist alone is insufficient. Candidate data is validated before serialization; the final
  staged artifact directory is re-enumerated and scanned before an atomic rename makes evidence
  available.

- **D-16:** The retained evidence schema is versioned and intentionally small: Crosswake and
  template/schema versions, commit/ref, opaque route ID, assertion IDs, low-cardinality
  status/outcome, UTC capture time, retention label, device class, and hashes of specifically
  approved sanitized contract/artifact bytes. No free-form metadata bag exists. —
  **Reversibility:** costly — once hosts consume the schema, incompatible changes require a schema
  version and migration guidance.

- **D-17:** Retained proof must reject raw answers, selected-answer content, mutation payloads,
  account or customer identifiers, credentials, tokens, transcripts, media, endpoints, archive
  details, stable device identifiers, screenshots, traces, console logs, and raw test output.
  `.xcresult` bundles are local/ephemeral inputs only and are never uploaded, committed, or treated
  as the Phase 162 artifact; they may contain screenshots, logs, and device details that cannot be
  safely redacted by assumption.

- **D-18:** Hash only approved sanitized bytes. Do not hash a payload, token, account/device
  identifier, or unreviewed binary and call it redacted evidence; a stable hash can itself become a
  correlating identifier.

- **D-19:** Privacy failures return only a stable rule ID and affected relative path/key. They do
  not echo the match, value, serialized object, stdout/stderr fragment, or surrounding content.
  The final scanner must have negative controls for sensitive keys/values and anti-vacuity coverage
  for newly generated artifact paths.

- **D-20:** `--check` is read-only and machine-oriented: non-zero on invalid configuration,
  missing required scaffold/wiring, unsafe evidence, stale incompatible provenance, or an output
  set that generation cannot satisfy without collision. It does not fail merely because a host
  legitimately edited a host-owned file.

- **D-21:** `--diff` is read-only and human-oriented: show missing paths and safe template changes
  without printing host configuration values or sensitive content. Existing-file differences are
  advisory because the files are host-owned; regeneration never applies the diff automatically.

- **D-22:** Evidence generation and checking are fail-closed and atomic. A failed validation or
  scan leaves no partially promoted evidence artifact. Recovery copy names the failing safe rule
  and the next command/action, follows the current brand voice, uses text labels rather than color
  alone, and keeps normal success output brief.

### Scope and stopping rule

- **D-23:** Preserve the three-day extraction stop. If the isolated helpers cannot parameterize
  the current host browser proof and produce executable iOS wiring inside the time-box, stop
  generalizing and copy the smallest adopter-specific proof slice. Do not respond by adding a
  generic test framework, sync abstraction, Xcode project manager, evidence dashboard, or device
  orchestration service.

### the agent's Discretion

The user selected all four areas and delegated a coherent one-shot recommendation after parallel
research. Planning may choose exact internal module names, generated filenames, config schema
implementation, exit-code numbers, manifest encoding, and non-destructive Xcode wiring mechanism.
It may not weaken host ownership, executable device wiring, explicit unavailable states, browser
test preservation, allowlist evidence, non-echoing privacy failures, or the time-box escape hatch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing first-adopter decisions

- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, proof-lane decision, three-day
  escape hatch, iOS-only posture, sensitive payload rules, executable verification, and stop list.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — full adoption strategy, proof seam, three native
  flows, stakeholder lenses, host/core ownership, and dated sequence.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — unknown-blocking route state, study invariants,
  evidence boundary, and ten-step physical-iPhone exit test.
- `.planning/phases/158-adoption-reset-and-route-map/158-CONTEXT.md` — D-03 promotion gate, D-09
  sensitive exclusions, D-14 routing matrix, D-17 non-echoing scans, and D-20 solo-maintainer rule.
- `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` — unresolved sanitized host inputs;
  must remain open and blocking for adopter proof promotion.
- `AGENTS.md` — repository priority, workflow, privacy restrictions, Android freeze, and stop list.

### Active milestone truth

- `.planning/PROJECT.md` — project thesis, proof-as-product DNA, constraints, and durable decisions.
- `.planning/REQUIREMENTS.md` — PROOF-01 through PROOF-04 and v21 non-goals.
- `.planning/ROADMAP.md` — Phase 159 boundary, time-box, smallest shippable version, success
  criteria, downstream phase ordering, and stop date.
- `.planning/STATE.md` — current position, blockers, deferred work, and unrelated working-tree note.

### Existing generator and proof contracts

- `lib/mix/tasks/crosswake.gen.shell.ex` — current target handling, no-clobber generation,
  desired-state manifest, and read-only `--diff` precedent.
- `test/mix/tasks/crosswake_gen_shell_diff_test.exs` — byte-identical no-write and diff-output
  contracts.
- `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` — stamped host ownership, missing-only rerun,
  path containment, and actionable next-step output.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — smallest current browser proof of real UI,
  IndexedDB outbox, app-driven reconnect, Ecto confirmation, and idempotency.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` — reusable LearnLoop route helper and
  explicit observation-versus-authority boundary.
- `examples/phoenix_host/e2e/support/evidence_manifest.ts` — current evidence vocabulary and the
  broad example-host shape Phase 159 must narrow rather than copy wholesale.
- `script/verify_generated_ios_shell.sh` — current generated-shell build/install smoke seam.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — current iOS
  test-target/project integration baseline.

### Privacy and evidence precedents

- `lib/crosswake/shell/diagnostic_export.ex` — allowlist-by-construction, forbidden-key rejection,
  closed values, and fail-closed redaction precedent.
- `lib/crosswake/planning/first_adopter_context.ex` — Git-backed textual discovery, destination
  routing, exclusions, and non-echoing privacy scan rules.
- `test/crosswake/planning/first_adopter_context_test.exs` — synthetic private-term controls,
  anti-vacuity filesystem discovery, and rule/path-only failures.
- `guides/support_matrix.md` — evidence tiers and the rule that browser, simulator, package, and
  device evidence do not become backend authority.

### Project design and communication DNA

- `prompts/crosswake-research-synthesis.md` — route-owner architecture, proof honesty, bounded
  bridge, and anti-universal-framework conclusions.
- `prompts/crosswake-elixir-oss-dna.md` — generator-plus-library pattern, install truth, host-owned
  code, deterministic/advisory proof split, doctors, and solo-maintainer DX.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — ownership-first conceptual spine, explicit
  boundary questions, proof-label distinctions, and support-truth discipline.
- `brandbook/BRAND-SPEC.md` — current voice and microcopy authority; use calm, exact, actionable,
  status-oriented output and do not rely on color alone.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Mix.Tasks.Crosswake.Gen.Shell`: read-only diff branch, normalized manifest parameters, target
  containment, generated iOS project, and host-owned shell guidance.
- `Mix.Tasks.Crosswake.Gen.NativeControlsUi`: strongest stamped/missing-only copy semantics and
  concise created/reused recovery output.
- `offline_sync.spec.ts` plus `offline_route_proof.ts`: current real browser island proof to extract
  behind route/storage/endpoint/mutation configuration instead of reimplementing.
- `Crosswake.Shell.DiagnosticExport`: typed allowlist sanitizer suitable as the architectural model
  for a narrower proof-evidence builder.
- `Crosswake.Planning.FirstAdopterContext`: non-echoing rule/path scanner and repository
  enumeration patterns reusable for final-artifact scanning.
- Existing iOS shell Xcode project/template and verification script: shell boot/build substrate;
  current gap is real test source and XCUITest/process-lifecycle wiring.

### Established Patterns

- Host-editable presentation/integration code is generated once and never silently overwritten.
- Security-, protocol-, compatibility-, and support-truth invariants remain library-owned and
  versioned.
- Canonical input is normalized once, then derived surfaces are generated and drift-checked.
- Browser/hermetic assertions may be merge-blocking; simulator, physical-device, provider, and
  external-state evidence remains advisory until an explicit promotion gate passes.
- Errors and proof artifacts are closed, low-cardinality, and non-echoing.
- Generated guides/artifacts are useful only when anti-vacuity checks make omission or deletion
  fail visibly.

### Integration Points

- Add the new Mix task, closed config/evidence modules, versioned templates, and generator tests in
  core.
- Extract configurable TypeScript helpers/specs from the current example-host offline proof while
  leaving current tests and fixtures intact.
- Generate proof-owned XCTest/XCUITest sources and non-destructive wiring under the configured iOS
  shell root.
- Add a read-only check/diff lifecycle and a final safe evidence compiler/scanner.
- Add only stable recurring generator/config/privacy contracts to CI; retain physical-device
  reconciliation as Phase 162 evidence.

</code_context>

<specifics>
## Specific Ideas

- Model configuration after Phoenix's established application-level generator defaults rather
  than a second YAML/JSON configuration language or a long list of repeated CLI flags.
- Follow the successful Phoenix/Rails generator lesson: copied code is openly host-modifiable;
  preview/check and no-clobber behavior are separate from regeneration-over-edits.
- Follow Apple's XCTest/XCUITest boundary: unit/contract tests validate values; UI tests launch and
  terminate the app through user-observable accessibility surfaces.
- Follow mature mobile process-death tests: terminate and relaunch while retaining state; never
  clear the persistence being proved.
- Follow Playwright/GitHub artifact lessons selectively: semantic assertions precede collateral,
  retention is explicit, and hashes/attestations do not make unsafe bytes safe to retain.
- CLI JTBD: “Generate the smallest lane, see exactly what was created or blocked, run one safe
  command, and know which host-owned action repairs it.” No graphical UI or design-system expansion
  is warranted in this phase; accessibility applies to app selectors, text-only CLI semantics, and
  non-color status communication.

</specifics>

<deferred>
## Deferred Ideas

- Phase 160 owns scoped replay, logout/account-switch stops, endpoint reauthorization, and auth
  safety behavior plugged into this harness.
- Phase 161 owns real foreground pack installation, integrity, atomic placement, and offline audio
  behavior plugged into this harness.
- Phase 162 owns the dated physical-iPhone run and final narrow support claim.
- Generic test orchestration, generic sync/storage, background work, Android parity/device proof,
  raw `.xcresult` retention, and an evidence dashboard remain outside v21.

</deferred>

---

*Phase: 159-host-reusable-proof-lane*
*Context gathered: 2026-07-31*
