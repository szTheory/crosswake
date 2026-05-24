# Phase 18: Operational Diagnostics And Enforcement - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 18 hardens Crosswake's operational truth for the first v3.1 capability set. In scope are route-local enforcement, doctor diagnostics, support-matrix truth, and final proof shape for `app_info`, `haptics`, `share`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`. This phase does not broaden capability semantics, add new native families, reopen route-owner doctrine, or hide pending proof gaps behind vague support language.

</domain>

<decisions>
## Implementation Decisions

### Route-local enforcement posture
- **D-01:** Keep the public route-policy surface family-first for ordinary capabilities. Phoenix authors should continue declaring semantic family vocabulary such as `app_info`, `haptics`, `share`, `permissions.status`, and `notification_token`, not bridge transport ids.
- **D-02:** Keep enforcement internals command-aware and fail-closed. The bridge registry and shell dispatch path should continue validating the concrete bounded command at runtime even when the route policy stays semantic.
- **D-03:** Preserve `file_picker` as an explicit transfer-backed exception rather than a plain family-only capability. `files.pick` remains authorized only through a declared route-local `transfer_id` whose seam validates as `source: :native_picker` and fits the typed transfer contract.
- **D-04:** `deep_link` remains manifest-first activation truth, not a route-local bridge command. Phase 18 must not pull `deep_link` into the bounded bridge allowlist or make route capabilities responsible for external-entry authority.
- **D-05:** Route policy, manifest metadata, doctor guidance, and support docs should explain the model as: semantic family declaration for normal bounded capabilities, plus explicit transfer-backed authority where a family would otherwise imply ambient file power.
- **D-06:** Avoid exposing bridge command ids as the primary DSL truth. Command names may evolve or multiply; the public policy contract should stay stable and family-first unless a later phase intentionally ships a family with multiple materially different public operations.

### Validator and denial semantics
- **D-07:** Policy validation should reject unknown or unsupported family vocabulary at compile time, while runtime bridge lookup should remain the fail-closed authority for concrete command, active-route, origin, compatibility, and transfer-seam checks.
- **D-08:** Runtime denials should keep route- and operator-facing reasons explicit rather than generic. Missing route declaration, missing transfer seam, wrong transfer intent, unsupported shell capability, incompatible runtime line, and external-entry denials should remain distinguishable in doctor and proof surfaces.
- **D-09:** `share` should be normalized into the same family-first enforcement story as other ordinary bounded capabilities. The system should not keep drifting between public family ids and command ids in ways that force adopters to think in protocol details.

### Doctor severity model
- **D-10:** Keep a mixed blocking-and-advisory doctor posture. `mix crosswake.doctor` should block on contract, compatibility, rebuild-truth, and declared-support dishonesty; it should use warning or advisory findings for environment-sensitive or point-in-time operational state.
- **D-11:** Blocking findings should include at least: unsupported route/runtime usage, undeclared capability authority on a route, missing required transfer-backed declaration for `file_picker`, shell capability mismatches for declared core capabilities, missing static native permission/config prerequisites, missing required companion compatibility truth, and rebuild-sensitive runtime-line mismatches.
- **D-12:** Advisory or warning findings should include at least: pending environment-sensitive proof lanes, user-denied permission state snapshots, transient provider token unavailability, and missing local workstation tooling when the public contract can still be described honestly without claiming support has already been proven there.
- **D-13:** Doctor output should keep remediation copy concrete and next-step oriented. Findings should tell operators what to add, rerun, declare, or rebuild rather than only naming a failed check.
- **D-14:** Downstream planning may introduce an explicit doctor taxonomy table or helper module so severity assignment does not drift across capability families over time.

### Support-matrix and proof-truth posture
- **D-15:** Support truth should become more explicit about three different things: platform baseline support, runtime-line or proof-lane verification state, and capability-family posture. Crosswake should not collapse those into one coarse label where doing so hides pending proof gaps.
- **D-16:** Keep baseline host/platform support claims where earlier proof still legitimately holds, but represent the unresolved Android Phase 17 JVM lane as `verification_required` at the relevant runtime or capability-proof layer until that proof actually runs.
- **D-17:** Advisory and companion-heavy families should be rendered distinctly from merge-blocking core family truth. `notification_token` in particular should not read as equally proven simply because it is implemented; its support posture must stay aligned with companion and proof-class constraints.
- **D-18:** Do not solve proof-truth gaps with caveat-only prose. If a support statement is materially weaker because proof is still pending, the status model or rendered structure should show that directly.
- **D-19:** Downstream agents may choose the smallest schema or rendering change that cleanly separates baseline support from capability-proof truth, but they should prefer explicit status structure over footnote sprawl.

### Final integrated proof shape
- **D-20:** Use a layered proof strategy rather than one monolithic “everything in one story” acceptance flow.
- **D-21:** Keep contract and invariant checks in ExUnit-level manifest, validator, registry, doctor, and support-matrix tests. Those are the fast, merge-blocking truth anchors.
- **D-22:** Keep platform-specific shell tests targeted and capability-aware rather than trying to move all confidence into one expensive end-to-end lane.
- **D-23:** Add one narrow integrated acceptance slice for the bounded bridge families that belong together operationally: `app_info`, `haptics`, `share`, `permissions.status`, `notification_token`, and `file_picker`.
- **D-24:** Keep `deep_link` proven in an activation-first acceptance slice rather than forcing it into the bounded-bridge acceptance flow. This preserves the architecture boundary that external entry is shell activation truth, not bridge authority.
- **D-25:** The integrated proof should be believable and route-natural, not a synthetic demo lane that exists only to touch every capability in one user story. Preserve failure isolation and support honesty over demo neatness.

### Delegation posture
- **D-26:** Shift ordinary implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should not re-ask about exact helper names, formatter layout, test file names, or support-table column naming unless a choice would materially change public support claims, denial vocabulary, or route-owner boundaries.
- **D-27:** The only decisions worth escalating back to the user are ones that would materially widen capability authority, weaken fail-closed behavior, or overclaim public support before proof exists.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, fail-closed posture, support-truth doctrine, and Phoenix-first ownership rules
- `.planning/REQUIREMENTS.md` — current contract and support requirements that still constrain v3.1 work
- `.planning/ROADMAP.md` — Phase 18 goal, plan split, and success criteria
- `.planning/STATE.md` — current milestone status and explicit note about the pending Android proof lane
- `.planning/MILESTONE-ARC.md` — arc-level rules for capability expansion, support truth, and proof posture
- `.planning/milestones/v3.1-CONTEXT.md` — milestone-wide framing for low-frequency capabilities and operational truth expectations

### Prior locked phase decisions
- `.planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md` — doctor/support-matrix expectations, proof split, and rough-edge truth
- `.planning/phases/15-base-capability-bridges/15-CONTEXT.md` — command naming, allowlist posture, and bounded bridge discipline
- `.planning/phases/16-system-context-bridges/16-CONTEXT.md` — `deep_link` activation boundary and `permissions.status` read-only posture
- `.planning/phases/17-user-prompted-capabilities/17-CONTEXT.md` — `notification_token` and `file_picker` semantics, denial posture, and transfer-backed file authority limits

### Prompt lineage and research
- `prompts/crosswake-brand-book.md` — anti-drift product language and boundary framing
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style, install truth, proof-lane expectations, and DX lessons from sibling Elixir libraries
- `prompts/crosswake-research-synthesis.md` — stable architecture story and anti-patterns to preserve
- `prompts/crosswake-gsd-project-brief.md` — authoritative route-policy and runtime-ladder framing
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — three-plane architecture lessons, route/config separation, and typed native boundary guidance
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — ecosystem lessons for route/runtime/capability boundaries
- `prompts/elixir-mobile-oss-lib-deep-research.md` — broader product-shape tradeoffs and cautionary examples

### Current code and guide anchors
- `lib/crosswake/policy/validator.ex` — current family vocabulary validation seam
- `lib/crosswake/manifest/builder.ex` — canonical capability catalog, prerequisites, denial, and fallback metadata
- `lib/crosswake/bridge/registry.ex` — current command-aware allowlist and `file_picker` transfer-backed enforcement
- `lib/crosswake/doctor/doctor.ex` — doctor report model, support posture calculation, and proof findings
- `lib/crosswake/doctor/formatter.ex` — human-readable doctor rendering
- `lib/mix/tasks/crosswake.doctor.ex` — current task exit behavior and CLI contract
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical support-truth source and release-boundary metadata
- `guides/bridge.md` — bounded bridge framing and current enforcement claims
- `guides/capabilities.md` — family-first public vocabulary and package-boundary framing
- `guides/native_shell.md` — manifest-first activation and shell-boundary guidance
- `guides/support_matrix.md` — current public support rendering that Phase 18 will refine
- `test/crosswake/bridge/registry_test.exs` — current fail-closed command, transfer, and capability tests
- `test/crosswake/doctor/doctor_test.exs` — current doctor severity, proof, and support-posture tests
- `test/support/router_fixtures.ex` — route-policy fixtures including `source: :native_picker` seams
- `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` — iOS bounded bridge enforcement and denial copy
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` — Android bounded bridge enforcement and denial copy
- `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` — iOS shell proof for capability denials and route-local enforcement
- `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` — Android shell proof for capability denials and route-local enforcement

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Bridge.Registry` already implements the right architectural split for this phase: command-aware runtime lookup with a special transfer-backed path for `files.pick`.
- `Crosswake.Manifest.Builder.capability_catalog/0` already holds capability prerequisites, denial ids, proof class, and rebuild posture; Phase 18 should extend that truth, not duplicate it elsewhere.
- `Crosswake.Doctor` already models `:error`, `:warning`, `:advisory`, plus `:verification_required` support posture. The phase should deepen this model rather than replace it.
- Existing shell tests already prove many denial cases across iOS and Android. Phase 18 should add targeted coverage where operational truth is still missing instead of inventing a brand new proof system.

### Established Patterns
- Public vocabulary is family-first; transport details are subordinate.
- Route ownership and authority stay explicit and fail closed.
- Environment-sensitive proof can be advisory while hermetic contract truth remains merge-blocking.
- Crosswake prefers explicit denial, fallback, and rebuild truth over convenience-oriented ambiguity.

### Integration Points
- `Crosswake.Policy.Validator` should become stricter where family normalization or public vocabulary drift remains ambiguous.
- `Crosswake.Doctor` and support-matrix rendering need a clearer expression of baseline support versus pending runtime/capability verification.
- Guide updates must stay aligned with manifest truth so `share`, `notification_token`, and `file_picker` do not drift between docs, validator vocabulary, and shell behavior.
- Final proof should connect ExUnit contract checks, shell tests, and one narrow integrated acceptance shape without collapsing `deep_link` into the bridge story.

</code_context>

<specifics>
## Specific Ideas

- The most coherent public story is: Crosswake route policy names semantic families; the manifest maps those families to concrete bounded commands and prerequisites; the registry and shells enforce concrete command truth fail-closed.
- Tauri is the best cautionary security analogue: explicit scoped authority is good, but public configuration should not become an ever-growing transport permission matrix.
- Hotwire Native is the best positive activation analogue: route behavior and external-entry rules should stay explicit and ordered, not ambient.
- Expo and React Native permission/document-picker ecosystems are useful DX lessons: normalize the public contract, separate status from request flows, and stay explicit about when file handles or provider tokens are evidence rather than durable truth.
- Phoenix/Plug/Ecto idioms favor a small semantic public API plus strict internal validation and good error messages. Phase 18 should follow that pattern rather than expose shell protocol trivia to Phoenix authors.
- User preference for this phase: push ordinary judgment left into GSD and return only for unusually high-impact support or authority changes.

</specifics>

<deferred>
## Deferred Ideas

- Public route-policy declaration by concrete bridge command id remains deferred unless a later phase intentionally introduces multi-operation families that justify it.
- Broad capability-inspection UI or operator dashboards remain deferred; this phase should sharpen truth and diagnostics first.
- Any change that would make `file_picker` a generic filesystem authority rather than a transfer-backed seam remains explicitly deferred.
- Any attempt to widen `notification_token` into permission-request orchestration remains deferred.
- A single monolithic “all capabilities in one hero demo” proof lane remains deferred unless a future milestone needs it for a public showcase rather than support truth.

</deferred>

---

*Phase: 18-operational-diagnostics-and-enforcement*
*Context gathered: 2026-05-21*
