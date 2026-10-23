# Phase 179: iOS Host Setup Without Hand Patches - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Workstream:** quality-ratchet-release

<domain>
## Phase Boundary

Deliver IOS-01, IOS-02 and IOS-03: a maintainer declares public iOS build inputs once in ordinary Phoenix/Mix config, generates or checks the supported shell and proof-test projections, retains native edits, and gets a concrete safe correction when configuration, ownership or generation is incomplete.

Phase 178 is the last completed phase. This discussion carries forward the researched roadmap the user approved; it does not execute generation, prove Xcode settings, complete a requirement, or start Phase 180. The bounded twin, visible study/media/replay composition and twin receipt belong to Phase 180. Recovery-checkout source/Git and historical artifacts remain protected.

</domain>

<decisions>
## Implementation Decisions

### Mandate and remaining judgment

- **D-01:** Carry forward the user's direction to research broadly, resolve tradeoffs into a coherent recommendation set, and avoid making them repeat settled choices. Their “i approve the roadmap” approved the selected synthesis and two-phase scope. There are no unresolved user preference questions for Phase 179; remaining uncertainties require host/Xcode execution. No new questionnaire, research fan-out or automatic plan/execute chain is selected by this invocation.
- **D-02:** Refresh the relevant source facts in an independent qualified preparation surface before planning source edits. Research inspected public source `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`; the recovery checkout is a different source. Reconcile a changed base explicitly. Do not silently include unrelated recovery files, replay PR #238 delivery, or treat a discussion approval as merge/release authority.

### One build declaration, ordinary Mix lifecycle

- **D-03:** Use one ordinary host-owned build-time configuration declaration under `:crosswake` for iOS host inputs, with `:ios_host` as the selected configuration entry. Normalize a closed input structure at the Mix boundary and pass explicit options to generation functions. Those functions do not fetch global application config. `MIX_ENV` selects the ordinary environment; no second configuration DSL or new lasting CLI override path.
- **D-04:** The supported host input set covers router, primary origin, declared entry route, app identity, proof-app/test identity projections and device signing mode/team selection. Reuse the existing `:proof_lane` owner for unrelated proof settings; do not duplicate identity authority between declarations. Document derivation/validation of test identities. Exact subordinate key names and deterministic suffixes are bounded planner discretion, consistent across examples, normalization, generation and diagnostics.
- **D-05:** Require compilation (`@requirements ["compile"]`) so the selected router is available. Never invoke `app.config`, evaluate `runtime.exs`, start Phoenix or obtain unrelated DB/server credentials merely to generate/check bundle inputs. Avoid manual `Config.Reader` recreation of Mix environment selection. The retained Mix experiment proves the lifecycle distinction only; a genuine host integration check remains necessary.
- **D-06:** Preserve existing documented local/dev invocation and local dependency behavior. The new production configuration path is explicit and fail-closed: no fallback to the example host, placeholder origin or ignored production declaration. Existing flags cannot silently replace declared production inputs. Document compatibility and an explicit migration for edited existing projects; do not remove the existing proof-lane `--config` interface as incidental cleanup.

### Native ownership, inspection and recovery

- **D-07:** Native Swift, entitlements, project customizations and host config are host-owned. Scaffold native files only when missing; never overwrite an edited file based only on its generated-looking path. Refresh only recognized Crosswake-managed manifest/static-activation/build-setting projections. Record ownership sufficiently to distinguish a stale managed output from an unrecognized or externally edited output.
- **D-08:** Initial generation wires the supported project to managed settings. Existing edited projects use a documented opt-in migration with an inspectable bounded change; no arbitrary PBX project editor or generator replacement. Reuse the present Xcode project/templates. Preserve valid host edits; a conflict produces a safe concrete repair rather than a successful partial scaffold.
- **D-09:** `--check` and `--diff` are nonwriting inspections of actual outputs against the selected declaration. They must not create directories, stamps or recovery files. Check fails for missing/stale/invalid/conflicting/incomplete managed outputs. Diff shows safe path/field/status categories and remediation without printing private values or their low-entropy hashes. Do not compare production output to a hardcoded example fixture.
- **D-10:** Validate all inputs, ownership and intended destinations before effects. Stage a coherent output set and replace each file atomically. Detect an interrupted multi-output update and make check/build verification deny mixed generations until explicit recovery completes. Preserve prior recognized state needed for recovery. Do not describe several independent renames as a filesystem-wide atomic transaction; select the smallest recovery mechanism that makes interruption reproducible and repairable.

### Effective Xcode settings and privacy

- **D-11:** Project identity/signing through managed `.xcconfig` files, with explicit unsigned simulator and device-capable settings. Inspect effective settings for shell app, proof app and applicable unit/UI-test targets across Debug/Release and simulator/device SDK classes. Test project wiring and higher-precedence settings rather than asserting that generated text contains the desired keys. Exclude configuration files from bundled resources.
- **D-12:** Simulator checks require no Apple credentials. Device settings inspection proves wiring only: it does not assert provisioning assets, signing success, installation or physical support. Missing device configuration is a concrete device-setup limitation and cannot silently force a production unsigned fallback. Host/Xcode owns certificates, profiles and credentials; no credentials become generator inputs or evidence.
- **D-13:** Keep host-private bundle/team/origin values in normal host-owned config or build environment, never real-adopter Crosswake fixtures. Reports retain safe presence/wiring/outcome categories. Reject invalid values without echoing them. Private diagnostic storage remains subject to the payload/identity privacy rules; raw build settings are not automatically safe to retain.

### Canonical route and activation truth

- **D-14:** Compile the selected host router through the existing route-policy/compiler/manifest builder path. Bundle its declared routes and primary origin; derive static activation from a valid declared entry route and that same origin. A supplied router must determine serialized manifest truth, rather than only capabilities while fixed fixtures remain bundled.
- **D-15:** Validate inputs and reject missing, malformed or example production origins and invalid entry routes before writes. Keep origins in manifest JSON, not an unescaped URL in `.xcconfig` where `//` has comment semantics. Development loopback remains an explicit local mode, not a production-origin default.
- **D-16:** Generated activation is static route/runtime configuration. It grants no session, account, scope, credential, installed-media availability or replay authority. Never project reference fixture pack/auth readiness into production authority. Backend/session and installed verified bytes remain their existing owners; missing authority denies the operation.
- **D-17:** Keep primary route/navigation/bridge origin separate from host-owned auth continuation and media acquisition. Auth/CDN origins do not implicitly become bridge allowlists. No SSO/CDN feature expansion or same-origin relaxation is selected.

### Proof, delivery boundaries and maintainer experience

- **D-18:** Plan feasibility checks first: real host compile/config with deliberately absent runtime-only credentials; effective Xcode settings; edited-file preservation and nonwriting checks; conflict/invalid-input denial; interrupted managed-output detection/recovery; host-derived manifest/entry/origin and static-authority rejection. Use meaningful negative controls, not tests that merely repeat rendered strings. Automate assertions; no human UAT substitutes for these checks.
- **D-19:** Reuse current Elixir/OTP, Swift/Xcode, dependencies and existing relevant CI leaves. Promote only stable recurring generation/ownership contracts; no new permanent simulator/reconciliation workflow, dependency upgrades or Android parity. Phase 180 receives a prepared generated candidate; this phase does not implement its runtime runner or scenario receipt.
- **D-20:** Maintainer flow is declare → inspect → generate → check/build → concrete repair if needed. Output begins with what was checked, its result, the safe cause and one corrective action. Add bounded usage/migration examples and synchronize canonical support/capability guidance and rendered guides only where behavior changes. Use current brand/copy conventions; no UI redesign, dashboard or design-system campaign.
- **D-21:** Preserve all protected historical files at original paths, retained private recovery material, six v24 debt records and six v23 acknowledgements. Phase 175 stays 8/9 with REL-10 breached. No source edits, staging, commits, tags, branch/worktree changes or build/generation runs occur in this recovery checkout. Downstream source work must use a qualified independent surface; its authorization and provenance are part of planning, not silently inherited remote write authority.
- **D-22:** The adopter lane stays parked at Phase 163.1-08 Task 2 until a validated sanitized route handoff exists. That input gate reopens the lane; fresh source-bound signed-device proof is subsequently required for promotion. Simulator/reference generation cannot satisfy either adopter authority or physical support. Stop at the three generation requirements; demonstrated broader core/storage/protocol needs remain incomplete rather than creating new scope.

### Agent Discretion

Choose subordinate config keys, test identity derivation, managed metadata/staging format, exact migration steps and safe diagnostics through idiomatic existing patterns. Resolve these during research/planning without another preference questionnaire, subject to the decisions above. No new product capability, public protocol or permission expansion is discretionary.

</decisions>

<canonical_refs>
## Canonical References

Downstream agents MUST read the scoped current files and selected synthesis. Research files describe their dated pre-approval position; the current workstream STATE/ROADMAP own routing. Resolve code references against the selected independent candidate, not the dirty recovery source.

### Governing scope and posture

- `AGENTS.md` — preservation, authorization, privacy and exact workstream handoffs.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure thesis and non-goals.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — DX, stakeholder and proof ownership boundaries.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — route authority and physical promotion gates.
- `.planning/PROJECT.md` — thesis and historical decisions; scoped files supersede its older milestone snapshot.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — IOS-01/02/03 acceptance.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — phase boundary and ordering.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — exact next action.
- `.planning/workstreams/quality-ratchet-release/v25.0-SCOPE.md` — approved scope and exclusions.
- `.planning/workstreams/quality-ratchet-release/v25.0-start/authorization.json` — consumed planning initialization and approved research bindings.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked resume gate.

### Approved research and precedents

- `.planning/research/v25/SUMMARY.md` — selected recommendations; supersedes conflicting specialist alternatives.
- `.planning/research/v25/ARCHITECTURE.md` — decision coverage and ownership flow.
- `.planning/research/v25/CONFIG-LOADING-RESOLUTION.md` — compile-only configuration boundary.
- `.planning/research/v25/build-config-experiment.json` — executed minimal Mix evidence, not full host proof.
- `.planning/research/v25/GENERATION.md` — generation alternatives and primary-source references; apply the loading resolution above.
- `.planning/research/v25/GENERATION-CHALLENGE.md` — ownership, project settings precedence and interrupted updates.
- `.planning/research/v25/DX.md` — host maintainer journey and truthful diagnostics.
- `.planning/research/v25/PITFALLS.md` — bounded failure risks.
- `.planning/research/v25/PROMPT-COVERAGE.md` — all thirteen prompt files considered and current-brand precedence.
- `.planning/research/v25/ROADMAP-PROPOSAL.md` — approved two-phase proposal, not current workflow routing.
- `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-CONTEXT.md` — independent source/proof and preservation constraints; completed phase, not a route to rerun.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` — historical qualified source handoff; refresh selection before new work.
- `brandbook/BRAND-SPEC.md` — current copy/design conventions, superseding old prompt brand guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

No `.planning/codebase` maps are present. A bounded read-only scout found these seams in the recovery source; approved research independently inspected the pinned public source. These observations are planning leads, not proof of current candidate behavior.

### Reusable Assets

- `lib/mix/tasks/crosswake.gen.shell.ex` — supported shell task, iOS template set, missing-only scaffolding, stamp and read-only diff path. Router currently affects capabilities while fixture export remains separate; selected production generation must join those owners.
- `lib/crosswake/manifest/builder.ex` and `lib/crosswake/manifest/manifest.ex` — canonical compiled route manifest and explicit origin options; retain policy semantics.
- `lib/crosswake/shell/activation.ex` — typed static activation contract; reuse without manufacturing runtime authority.
- `lib/crosswake/shell/fixtures.ex` — existing example fixture exporter, including simulated installed pack data. Preserve reference/dev purpose; do not use it as production host truth.
- `lib/mix/tasks/crosswake.gen.proof_lane.ex` and `lib/crosswake/proof_lane/` — closed normalization and additive host-owned generation/check/diff precedent. Preserve its existing interface and test ownership.
- `test/mix/tasks/crosswake_gen_shell_test.exs`, `test/mix/tasks/crosswake_gen_shell_diff_test.exs` and `test/mix/tasks/crosswake_gen_shell_stamp_test.exs` — existing generation/ownership/regression corpus.

### Established Patterns and Integration Points

- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` and `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex` already own app/test projections. The scouted templates hardcode unsigned signing and example identities; effective-setting checks must catch masking when managed xcconfig is introduced.
- Project scaffolding is host-owned; the current diff excludes project UUID noise. Managed settings inspection must cover its actual hook without redefining arbitrary project edits as generator-owned.
- Normal Mix task input normalization → explicit generation options → recognized output checks is the selected seam. Existing Android templates and cheap shared regression coverage retain their frozen posture.
- The minimal build-config experiment already refuted `app.config`; it did not test these full Phoenix/Xcode paths. Plan execution supplies those observations.

</code_context>

<specifics>
## Specific Ideas

The user wants the largest adoption wins with a finite stopping point and upstream research that makes downstream work effective. The approved model is one declaration, no hand patches to managed outputs, safe repair, then one bounded reference twin. Candidate invocations are `MIX_ENV=prod mix crosswake.gen.shell ios --diff`, `--check`, and ordinary generation; new behavior remains proposed until implemented and verified.

</specifics>

<deferred>
## Deferred Ideas

Phase 180 owns the visible generated-WebView/native-media/persistence/replay composition, T01–T10 and derived twin receipt. Physical/adopter promotion remains in the parked adopter lane. Release/PR merge, old debt cleanup, generic sync/storage, Android expansion, new companions/native protocols and brand polish remain excluded. No new deferred idea was introduced during this invocation.

</deferred>

---

*Phase: 179-ios-host-setup-without-hand-patches*
*Context gathered: 2026-10-13*
