# Phase 17: User-Prompted Capabilities - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 17 delivers Crosswake's first user-mediated native capability flows: `notification_token` and `file_picker`. The phase must keep both surfaces low-frequency, typed, fail-closed, and honest about platform prerequisites. It does not widen into generic permission orchestration, backend push delivery ownership, persistent document authority, directory browsing, or native-screen-heavy file-management flows.

</domain>

<decisions>
## Implementation Decisions

### `notification_token` authority
- **D-01:** `notification_token` owns token retrieval and refresh only. It does not trigger notification authorization prompts.
- **D-02:** Notification authorization remains a separate concern. Phase 17 callers should check `permissions.status` first, and any future prompt-owning flow must use a separately named interactive command or a native-owned flow rather than overloading `notification_token`.
- **D-03:** `notification_token` command semantics must stay deterministic per invocation. Crosswake must not ship a "sometimes prompts, sometimes fetches" command shape.
- **D-04:** If notification authorization or platform token prerequisites are missing, `notification_token` fails closed with a typed denial that names the prerequisite explicitly instead of silently prompting or silently returning empty data.

### `notification_token` reply contract
- **D-05:** A successful `notification_token` reply includes `token` plus a normalized `notification_status` snapshot and optional secondary `detail`. It does not return a bare token.
- **D-06:** `notification_status` reuses the same small Crosswake-owned status vocabulary as `permissions.status`: `granted`, `denied`, or `restricted`. Platform-native nuance stays in secondary `detail`.
- **D-07:** Returned token data is evidence only. It must not imply backend registration, topic subscription, delivery readiness, or end-to-end notification success.
- **D-08:** Top-level bridge semantics stay unchanged: contract or policy failures return `status: "deny"`, while successful bridge execution returns `status: "ok"` with bounded payload fields that Phoenix can branch on.
- **D-09:** Any future Phoenix-side token registration helper remains a separate backend seam. Phase 17 must not standardize provider-specific registration endpoints or collapse backend truth into the bridge.

### `file_picker` authority boundary
- **D-10:** `file_picker` is not a free-standing public authority surface. Public invocation must bind to a declared route-local `transfer_id` whose typed transfer contract justifies the picker.
- **D-11:** Phase 17 supports picker-backed seams only for low-frequency inbound flows: `import` and upload preparation from `source: :native_picker`. Generic filesystem browsing, directory picking, persistent tree access, and broad provider authority remain out of scope.
- **D-12:** Picker results are evidence for a transfer seam, not durable file authority. Returned handles must not be treated as stable long-term access grants without a later explicit contract upgrade.
- **D-13:** Crosswake should bias toward app-sandbox copies or staged import handles for Phoenix-owned routes rather than in-place editing semantics. Copy-vs-access truth must stay explicit per platform behavior.
- **D-14:** MIME/type filters are advisory until verified. Native-provider mismatches must fail closed through transfer verification rather than assuming picker filtering was honored perfectly.
- **D-15:** If a route needs continuous selection, rich provider browsing, editing in place, or permission choreography beyond one-shot import/upload preparation, the interaction should graduate out of bounded bridge into a native-screen or companion surface.

### `file_picker` result contract
- **D-16:** Successful picker replies return a stable top-level shape for both single and multiple selection. The public reply should carry `transfer_id` plus `items: [item]` rather than switching between one item and many.
- **D-17:** Each picked item includes normalized public fields for `handle`, `name`, `mime_type`, and `size_bytes`. `native_type` may appear as optional secondary platform detail.
- **D-18:** `handle` is the stable public field for the selected native reference, but metadata fields other than `handle` are nullable when the platform cannot truthfully provide them.
- **D-19:** The reply must not echo `multiple_allowed`. Multiplicity policy belongs to the request and transfer contract; the reply expresses actual outcome through `items` cardinality.
- **D-20:** Cancellation is a distinct typed outcome, not a fake success with `items: []`.
- **D-21:** Phase 17 must not add durable bookmark, persistable-access, or reopen-later semantics to the first picker result contract.

### Decision delegation posture
- **D-22:** Shift normal implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice would materially change public capability semantics, denial vocabulary, backend-truth posture, rebuild/support claims, or route-owner boundaries.

### the agent's Discretion
- Exact request and response struct names, as long as the public semantics above remain stable and typed.
- Exact denial reason identifiers and copy, as long as missing authorization, unavailable token, canceled picker, and transfer-contract mismatch remain clearly distinct.
- Exact shell-side staging mechanics for picker copies or temporary handles, as long as long-lived authority is not implied.
- Exact optional `detail` keys for notification or picker platform nuance, as long as primary branching remains on Crosswake-owned normalized fields.

</decisions>

<specifics>
## Specific Ideas

- Apple, Android, and Firebase all separate notification permission truth from token registration truth. Crosswake should preserve that separation instead of offering a one-call convenience surface that hides OS-side prerequisites.
- Hotwire Native is a positive reference for bounded, semantic bridge surfaces that stay subordinate to route ownership; Crosswake should copy the discipline, not invent a notification or file plugin bus.
- Tauri's scoped-capability posture is the right warning for `file_picker`: ambient file authority drifts fast once the API stops being route-local and purpose-specific.
- Expo and React Native document-picker ecosystems are useful cautionary examples: normalizing filename, MIME/type, and size is good DX, but "just pick a file" abstractions become misleading once they hide URI lifetime, persistent access, virtual-file quirks, or copy-vs-open semantics.
- The desired DX is cohesive and least-surprise: Phoenix authors should see one explicit notification path (`permissions.status` then `notification_token`) and one explicit picker path (declared transfer seam backed by `source: :native_picker`), not a pile of overlapping mobile convenience APIs.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, Phoenix-first runtime-boundary rules, and v1 scope constraints
- `.planning/REQUIREMENTS.md` — capability, support-truth, and package-boundary expectations that still constrain Phase 17
- `.planning/ROADMAP.md` — Phase 17 goal, plan split, and success criteria
- `.planning/STATE.md` — current milestone status and prior note that Phase 17 carries the permissions-matrix pressure point
- `.planning/milestones/v3.1-CONTEXT.md` — milestone-wide low-frequency capability posture and fail-closed error-handling strategy

### Prior locked decisions
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — bounded bridge rules, typed denial envelopes, and low-frequency semantic command posture
- `.planning/phases/04-honest-offline-contract/04-CONTEXT.md` — explicit staged data handling, app-sandbox bias, and anti-magic contract posture
- `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md` — family-first taxonomy, `notification_token` evidence-only framing, and ownership-first capability rubric
- `.planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md` — doctor/support-matrix expectations for prerequisites, denials, fallback behavior, and rebuild truth
- `.planning/phases/15-base-capability-bridges/15-CONTEXT.md` — command naming, registry allowlisting, and fail-closed bridge conventions
- `.planning/phases/16-system-context-bridges/16-CONTEXT.md` — `permissions.status` narrowed to `notifications` only and normalized-status contract shape

### Prompt lineage and project research
- `prompts/crosswake-brand-book.md` — anti-drift product language and architecture boundary framing
- `prompts/crosswake-elixir-oss-dna.md` — install truth, proof-backed support, and maintainer OSS house-style expectations
- `prompts/crosswake-gsd-project-brief.md` — authoritative route-policy and runtime-ladder framing
- `prompts/crosswake-research-synthesis.md` — stable architecture story and anti-patterns to preserve
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — route/runtime/capability lessons from adjacent ecosystems
- `prompts/elixir-mobile-oss-lib-deep-research.md` — broader library-shape tradeoffs and cautionary examples
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — shell, bridge, and capability-boundary guidance for disciplined surface design

### Current contract and code anchors
- `guides/bridge.md` — bounded bridge contract and denial vocabulary baseline
- `guides/capabilities.md` — capability-family framing, `notification_token` evidence-only posture, and support classifications
- `guides/native_shell.md` — shell-level bridge command framing and native boundary rules
- `lib/crosswake/manifest/builder.ex` — canonical capability metadata, prerequisite truth, and support posture source
- `lib/crosswake/bridge/commands/permissions_status.ex` — normalized notification-status enum and typed request/response pattern
- `lib/crosswake/policy/validator.ex` — current capability vocabulary and route validation seam
- `lib/crosswake/transfer/contracts.ex` — typed, versioned transfer declarations that should anchor picker-backed flows
- `test/support/router_fixtures.ex` — existing `source: :native_picker` examples and transfer-shape expectations
- `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` — current iOS bounded bridge enforcement and command dispatch shape
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` — current Android bounded bridge enforcement and command dispatch shape
- `examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift` — current iOS `notifications` permission-status provider
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt` — current Android `notifications` permission-status provider

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Bridge.Commands.PermissionsStatus` already defines the normalized notification status vocabulary that `notification_token` should reuse instead of inventing a second permission enum.
- `Crosswake.Manifest.Builder.capability_catalog/0` already records `notification_token` as evidence-oriented and companion-leaning, making it the right place to keep support truth aligned with implementation.
- `Crosswake.Transfer.Contracts` already gives Phase 17 a typed seam for `transfer_id`, `intent`, `source`, `verification`, and media-type constraints. `file_picker` should build on that instead of bypassing it.
- Existing iOS and Android `BridgeChannel` implementations already enforce route identity, origin, pack compatibility, and capability-version checks before dispatch, which is the correct bounded seam for both new flows.

### Established Patterns
- Public family names stay separate from low-level command ids.
- Bridge commands remain semantic, typed, low-frequency, and route-local.
- Capability claims stay honest through explicit prerequisites, denial reasons, and support guidance.
- Data or handle surfaces are evidence and bounded inputs, not ambient truth or open-ended authority.

### Integration Points
- `notification_token` should integrate with the existing `permissions.status` notification alias and manifest capability metadata rather than introducing a parallel permission model.
- `file_picker` planning should wire into transfer declarations, manifest output, route policy validation, shell dispatch, and future doctor/support surfaces as one coherent seam.
- Phase 18 doctor and support work will need explicit prerequisite and denial language derived from these Phase 17 decisions, especially for authorization-required, token-unavailable, picker-canceled, and transfer-verification mismatch cases.

</code_context>

<deferred>
## Deferred Ideas

- A separately named interactive notification-permission prompt command, if Crosswake later decides it should own that choreography explicitly
- Phoenix/backend helpers for provider-specific token registration, topic subscription, or reconciliation
- Generic standalone file browsing, directory selection, or persistent document-tree access
- Long-lived document bookmarks, reopen-later semantics, or in-place editing contracts
- Any file-management or notification workflow that needs continuous native authority, heavy platform choreography, or backend/provider coupling beyond a bounded bridge seam

</deferred>

---

*Phase: 17-user-prompted-capabilities*
*Context gathered: 2026-05-21*
