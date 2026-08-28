# Phase 156: Native Menu & Action-Button Control - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `action_menu` as the first genuinely new native control on the Phase 154
request/reply seam:

1. A Phoenix route explicitly authorizes one action-menu contract and its generated fallback.
2. A Phoenix-owned trigger invokes the control through `Crosswake.Bridge.push/3`.
3. The same bounded action projection renders through the existing host-owned fallback or a real
   platform-native presenter.
4. iOS and Android return exactly one typed `selected` or `dismissed` outcome.
5. Hermetic native contract vectors prove dispatch, validation, selection, dismissal, and denial
   without making simulator/emulator evidence merge-blocking.

This phase does **not** create a generic native toolbar/navigation system, a component framework,
a host-registrable menu plugin, or native mutation authority. Phoenix still owns the route,
localized copy, authorization, destructive confirmation, and business mutation.

The user selected all four gray areas and delegated the decisions after parallel research. Three
`gsd-advisor-researcher` tracks covered Phoenix/Elixir API design, native UI/accessibility, and
bridge/proof/release architecture. The decisions below are the coherent synthesis.

</domain>

<decisions>
## Implementation Decisions

### Trigger ownership and the action-button meaning

- **D-01:** **The Phase 156 action button is Phoenix-owned.** It is an ordinary, accessible
  button in the LiveView that opens the already-rendered Phase 155 fallback and invokes
  `Crosswake.Bridge.push(socket, "action_menu", ...)` as native enhancement. The wire command
  remains `action_menu.present`. This preserves the server-initiated request/reply seam and keeps
  the no-shell/browser path complete.

- **D-02:** **Do not add shell-owned toolbar or navigation-bar chrome in this phase.** A persistent
  shell button would need a second native-to-LiveView command path, route-transition lifecycle,
  stale-manifest reconciliation, and native navigation ownership that Crosswake has not yet
  designed. That belongs with the native-navigation shell, not the first bounded control.
  — **Reversibility:** costly — once adopters rely on shell-owned route chrome, removing it would
  require native-host and route-policy migrations.

- **D-03:** Reject Hotwire-style DOM declaration and generic DOM scanning for authority.
  Crosswake may learn progressive enhancement from Hotwire Native, but route policy and the
  manifest remain the authorization source. The hook never searches for a nearby button,
  infers from ARIA, scans roles, or treats page structure as a second capability registry.

- **D-04:** The JTBD is deliberately narrow: a person viewing a Phoenix-owned route taps its
  visible Actions button, receives platform-native choice chrome, chooses one allowed action or
  dismisses, and Phoenix decides what happens next. If a workflow needs persistent native
  toolbar state, continuous client authority, or native-side action composition, it has crossed
  out of this bounded-control phase.

### Explicit trigger anchoring

- **D-05:** `Bridge.push/3` gains an **explicit `anchor_id:` option for `action_menu`**. The
  adopter passes the exact DOM id of the Phoenix trigger. The generated/example trigger uses the
  same id for fallback `aria-controls`, `aria-expanded`, and focus return. This is the only
  public anchor input; adopters do not pass screen coordinates.
  — **Reversibility:** costly — the option and its failure behavior become adopter-facing API.

- **D-06:** The library-owned hook resolves only `document.getElementById(anchor_id)`, measures
  that element, and appends typed presentation metadata to the outgoing request:
  anchor id, WebView-coordinate rectangle, viewport size, and source
  `explicit_trigger`. Coordinates are a transport/presentation fact produced by the client, not
  route policy and not caller-authored business data.

- **D-07:** A missing, duplicated/unresolvable, zero-size, offscreen, or stale anchor **fails
  closed before native presentation**. Core returns one typed denial and leaves the host-owned
  fallback usable. Never guess the active element, nearest button, WebView center, or screen
  corner. The denial copy is developer-facing; end users continue to see the fallback rather
  than bridge terminology.

### Minimal route-policy API

- **D-08:** Add one sibling route-policy key, `action_menu:`, paired with
  `capabilities: ["action_menu"]`. Phase 156 supports **one default action-menu contract per
  route**, not multiple named menus. Multiple menu identities would add public nesting, stable
  menu ids, and reply routing before the first control proves the model.

- **D-09:** The minimal declaration is:

  ```elixir
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    capabilities: ["haptics", "action_menu"],
    action_menu: [
      actions: [
        %{id: "flag", destructive: false, icon: nil},
        %{id: "reassign", destructive: false, icon: nil},
        %{id: "delete", destructive: true, icon: nil}
      ],
      fallback: :generated
    ]
  ]
  ```

  `id` is a stable, unique, non-empty action identifier. `destructive` is an immutable safety
  classification. `icon` is reserved and must be `nil` in this phase. `fallback` has the single
  Phase 156 value `:generated`, making fallback behavior explicit as MENU-01 requires.
  — **Reversibility:** one-way — route-policy and manifest field shapes become published
  contracts consumed by generated shells and companion-visible route metadata.

- **D-10:** Policy declares authorization and safety invariants, **not localized labels, ordering,
  per-record visibility, or disabled reasons**. Router files are the wrong home for Gettext copy
  and record-dependent view state. This follows Phoenix's normal split: router metadata declares
  the boundary; the LiveView projects current presentation state.

- **D-11:** Adding `action_menu:` without `capabilities: ["action_menu"]`, or declaring the
  capability without its structured contract, is a compile-time validation error with calm,
  actionable remediation. No parallel `controls:` authorization list is introduced.

### Runtime projection and validation

- **D-12:** Each invocation supplies the exact frozen Phase 155 action shape:

  ```elixir
  actions :: [
    %{
      id: String.t() | nil,
      label: String.t(),
      destructive: boolean(),
      icon: nil
    }
  ]
  ```

  The same value is assigned to the host fallback and passed to the bridge, so native and web do
  not derive two independent menus. Labels are localized in the LiveView. Ordering and
  record-specific visibility are runtime concerns.

- **D-13:** Every selectable runtime id must be a subset of the route-policy allowlist;
  `destructive` must exactly match policy; `icon` must remain `nil`; labels must be nonblank;
  non-nil ids must be unique. Invalid projections fail **before** native dispatch and name the
  route, action, violated invariant, and fix. Full-dynamic menus authorized only by the family
  string are rejected.

- **D-14:** `id: nil` retains Phase 155's exact meaning: a visible, disabled, non-selectable
  explanatory row whose localized label contains the reason, for example
  `Reassign job — needs a supervisor`. It is allowed in the runtime projection, is never
  replyable, and does not add a fifth `disabled` or `disabled_reason` field. Native must not
  silently omit it, because omission hides useful availability truth and diverges from fallback.

- **D-15:** An empty runtime action list does not present native chrome. It remains an honest
  fallback empty state and resolves through a typed denial/fallback outcome rather than opening
  an empty OS menu. Planning may set a conservative documented item/label ceiling, but it must
  preserve the core UX guidance: short, scannable menus; a workflow that needs a large dynamic
  command palette is not this bounded control.

- **D-16:** The intended call shape is:

  ```elixir
  socket
  |> assign(menu_open: true, menu_actions: actions)
  |> Crosswake.Bridge.push("action_menu",
    ref: :approval_actions,
    payload: %{"actions" => actions},
    anchor_id: "approval-actions-trigger",
    timeout: :infinity
  )
  ```

  `push/3` continues to accept the capability family; registry code maps it to
  `action_menu.present`. No per-family public wrapper or generic control dispatcher is added.

### Native presentation and platform ownership

- **D-17:** Use a **semantic platform-adaptive presenter**, not pixel parity:
  - iOS: `UIAlertController.Style.actionSheet`; bottom-sheet idiom on iPhone and mandatory
    popover anchoring to the validated WebView-coordinate trigger rectangle on iPad.
  - Android: `PopupMenu` anchored to the explicit trigger rectangle through one bounded native
    anchor adapter/view owned by the action-menu presenter.

  Both are real OS-native menu surfaces. Crosswake defines semantics and outcomes; each platform
  owns chrome, motion, dark/light/system appearance, font scaling, focus, and dismissal idiom.

- **D-18:** Do not add an Android Material bottom-sheet dependency merely to make both platforms
  look alike. It adds a UI framework, custom focus/scrim/inset lifecycle, and dependency/version
  surface where the platform popup already fits a short overflow menu. If Android cannot create
  a valid bounded anchor from the explicit rectangle, deny and keep the Phoenix fallback; never
  silently substitute centered custom UI.

- **D-19:** iPad anchoring is a hard correctness gate. An action sheet is never presented without
  a valid `sourceView` and `sourceRect`; anchor failure denies before UIKit presentation. This is
  the same crash class Phase 157 must guard for share, solved here at the contract boundary.

- **D-20:** Platform divergence is intentional and documented. iOS may present a sheet/popover
  while Android presents an anchored popup. The guarantee is the same allowlisted actions,
  semantics, and typed outcome—not identical pixels or placement.

### Action semantics, accessibility, and user psychology

- **D-21:** Native items use the localized `label` as the visible and spoken name. System controls
  carry VoiceOver/TalkBack roles, enabled state, focus, text scaling, contrast, light/dark/system
  appearance, and native tap-outside/Back/dismiss behavior. Trigger copy remains verb-first and
  familiar (`Actions` / `More actions`), never protocol terminology.

- **D-22:** Disabled explanatory rows remain present and disabled on both platforms. Their reason
  must be understandable from the label alone; color or disabled styling is never the only
  signal. Empty labels, duplicate ids, selectable nil ids, or a reply selecting a disabled row
  fail closed.

- **D-23:** Destructive actions sort last and use the platform's destructive treatment where one
  exists, but color is supplementary. Native selection performs **no mutation and no native
  confirmation**. It returns the id; Phoenix reauthorizes against current domain state and opens
  the existing host-owned destructive confirm before mutation. This preserves the permanent
  decision that confirm is Phoenix-owned.

- **D-24:** Icons remain reserved and unrendered in Phase 156. Android does not guarantee menu
  icon display, and one-platform icons would create false parity and make labels less
  self-sufficient. Adding a portable icon vocabulary is a later, separately versioned decision.

- **D-25:** Accessibility proof is semantic, not visual theater: test the item labels, enabled
  state, destructive attribute where supported, exactly-one dismissal callback, and platform
  adapter wiring. Do not claim that hostless XCTest/JVM vectors prove real VoiceOver/TalkBack
  speech, final pixels, or device interaction. Optional device evidence stays advisory.

### Typed reply, authority, and races

- **D-26:** Every successful native presentation returns exactly one `status: :ok` reply with
  one of two explicit outcomes:

  ```elixir
  %{"outcome" => "selected", "action_id" => id}
  %{"outcome" => "dismissed"}
  ```

  Dismissal is a first-class answer, including iOS cancel/tap-outside and Android Back/tap-
  outside. It is never silence, never an error, and never encoded as selection of the first row.
  — **Reversibility:** one-way — adopter `handle_info/2` clauses will pattern-match this payload.

- **D-27:** A selected id is untrusted user input, not authority. Core rejects ids absent from the
  in-flight projected menu before adopter delivery. The LiveView then rechecks current
  authorization/domain state before any mutation. Ecto/Phoenix business logic remains the final
  authority.

- **D-28:** Preserve Phase 155's **fallback-first, native-enhance** model. The fallback renders
  from assigns in the same server round trip; native presentation overlays/enhances it. A denial
  leaves the fallback available. `:shell_unreachable` adds no end-user error copy; a stale-binary
  denial may render the existing inline update guidance.

- **D-29:** Native and fallback answers share the Phase 154 exactly-once table. Whichever resolves
  the ref first wins. If the fallback wins while native chrome is open or queued, the library
  must also cancel/dismiss that native presentation so a stale menu cannot appear afterward.
  Implement this as bounded internal protocol behavior associated with the original correlation
  id, not a second adopter callback or generic native UI registry.

- **D-30:** When native wins, adopter reply handling closes the fallback assign. When native
  dismisses, it closes the fallback without mutation. When fallback wins, its existing generated
  handler calls `Bridge.resolve/2`; a late native selection/dismissal is dropped before adopter
  code and emits bounded telemetry.

### Structured wire contract and old-shell truth

- **D-31:** Bump `Crosswake.Bridge.Contract` from `1.1.0` to an additive `1.2.0` contract and
  widen request payloads from string maps to typed structured JSON values on both native
  packages. Do not JSON-encode the action list inside a string. Existing scalar payloads remain
  valid structured values.
  — **Reversibility:** one-way — published native envelope decoders and committed vectors consume
  the payload representation.

- **D-32:** `action_menu` is core-owned, `interaction: :user_answer`,
  `rebuild: :native_required`, and merge-blocking once the vector proof lands. The release,
  support matrix, changelog, doctor, and generated-shell guidance must all name the required
  update → regenerate → native rebuild/resubmit → deploy sequence.

- **D-33:** Correct Phase 154 D-29 / Phase 155 D-56 with a real mechanism:
  before posting, the hook checks the shell-injected `action_menu` capability/version fact. A
  reachable native transport that lacks the compatible family emits a fact event; Elixir alone
  constructs `%Crosswake.Shell.Denial{reason: :unavailable_capability}` with required/available
  version and `failing_moment: :native_capability_unavailable`. The old binary never receives an
  unknown command.

- **D-34:** Keep failure layers distinct:
  - missing route declaration or action contract: loud server-side authoring raise;
  - runtime action outside the policy allowlist: loud server-side validation failure;
  - old/stale binary missing `action_menu`: typed `:unavailable_capability` denial;
  - no transport, hook missing, transport error, or reply timeout: `:shell_unreachable`;
  - known command with route/envelope capability mismatch: `:undeclared_capability`;
  - selected unknown/disabled id: drop/fail closed before mutation.

  Do not globally relabel every arbitrary native enum miss merely to repair the legitimate
  old-binary path; the preflight and protocol-version gate make that path truthful.

### Proof, observability, and non-claims

- **D-35:** Extend the one canonical `test/fixtures/bridge_contract_vectors.json` and regenerate
  both native mirrors. Vectors must drive the real Swift and Kotlin evaluation paths and cover:
  structured action dispatch, selectable subset validation, selected reply, dismissed reply,
  disabled nil-id rows, destructive metadata, capability absence, route/capability mismatch,
  duplicate/unknown ids, and malformed/empty actions.

- **D-36:** Proof must be anti-vacuous:
  - both native harnesses consume the same committed vectors;
  - fake presenters record the decoded native presentation model and drive both select and
    dismiss callbacks;
  - at least one negative control mutates/removes the menu native case and makes the lane red;
  - source/structural checks pin the real UIKit/Android presenter adapter without pretending
    source presence proves pixels;
  - the existing browser route-tour continues to prove fallback-first behavior and no mutation
    on denial.

- **D-37:** The merge-blocking claim is **contract and dispatch behavior without a simulator or
  emulator**. Explicit non-claims: not real VoiceOver/TalkBack speech, not pixel parity, not
  platform animation quality, not the adopter's edited fallback, and not native toolbar
  ownership. Optional simulator/device accessibility and visual evidence is advisory.

- **D-38:** Add bounded telemetry for requested, presented, selected, dismissed, denied,
  cancelled, and dropped outcomes. Metadata may include route id, capability, command, outcome,
  denial reason, and bounded action count; never action labels, action ids, DOM ids, raw
  coordinates, record ids, or the opaque adopter `ref`.

### the agent's Discretion

The user delegated all four decision areas after requesting parallel expert research. Planning
retains discretion over private type/module names, the bounded native anchor adapter's internal
implementation, exact conservative action/label ceilings, test-file organization, and
developer-facing microcopy—provided the public shapes, failure layering, authority boundaries,
accessibility semantics, and proof non-claims above remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and phase contracts

- `.planning/PROJECT.md` — v20 thesis, core value, scope, and native-control support/proof posture.
- `.planning/REQUIREMENTS.md` — MENU-01..03 and PROOF-03; native confirm remains permanently out
  of scope.
- `.planning/ROADMAP.md` — Phase 156 goal, dependencies, success criteria, and D-56 record
  correction.
- `.planning/STATE.md` — current phase position, prior-phase implementation decisions, and
  release/mirror status.
- `.planning/phases/154-the-control-contract-seam/154-CONTEXT.md` — request/reply seam,
  exactly-once rules, denial layers, payload ceiling, and deferred menu cancellation.
- `.planning/phases/155-host-owned-fallback-components/155-CONTEXT.md` — fallback-first model,
  frozen action shape, disabled/destructive semantics, D-56 correction, and generated-host
  ownership.
- `.planning/phases/153.1-ci-gate-integrity-and-runner-cost/153.1-CONTEXT.md` — required-check
  integrity and non-vacuous gate constraints.

### v20 research corpus

- `.planning/research/v20/SUMMARY.md` — menu/action-button wedge verdict and milestone synthesis.
- `.planning/research/v20/API-DESIGN.md` — earlier public API alternatives; superseded where this
  context differs.
- `.planning/research/v20/UX-CONTRACT.md` — JTBD, `action_menu` vocabulary, distinct dismissal,
  fallback, and accessibility research.
- `.planning/research/v20/GROUND-TRUTH.md` — current code gaps, structured-policy requirement,
  rebuild class, and catalog-line stress test.
- `.planning/research/v20/PRIOR-ART.md` — Hotwire Native, Capacitor, Expo, Flutter, React Native,
  and platform footguns.
- `.planning/research/v20/RELEASE-STRATEGY.md` — native proof-lane and release constraints; note
  that the roadmap later chose real native menu chrome for Phase 156.
- `.planning/research/v20/VISION-COHERENCE.md` — core ownership and the bounded-control ceiling.

### Project DNA and brand

- `prompts/crosswake-elixir-oss-dna.md` — install truth, public-contract honesty, generator vs
  library ownership, proof lanes, and protocol discipline.
- `prompts/crosswake-gsd-project-brief.md` — authoritative Phoenix-first route/runtime stance and
  preference for decisive recommendations.
- `prompts/crosswake-research-synthesis.md` — route policy as center of gravity and the
  low-frequency semantic bridge ceiling.
- `brandbook/BRAND-SPEC.md` — authoritative brand, error/microcopy voice, accessibility-as-
  contract, no hidden bridge magic, and platform-respect guardrails. It supersedes
  `prompts/crosswake-brand-book.md`.
- `prompts/crosswake-brand-book.md` — historical seed only; do not use where it conflicts with
  `brandbook/BRAND-SPEC.md`.

### Public API and manifest integration

- `lib/crosswake/policy/schema.ex` — NimbleOptions route schema and sibling structured-key
  precedents.
- `lib/crosswake/policy/route.ex` — normalized public route contract.
- `lib/crosswake/policy/validator.ex` — capability vocabulary and cross-field validation.
- `lib/crosswake/manifest/types.ex` — public `RouteEntry`, manifest schema version, and JSON
  serialization.
- `lib/crosswake/manifest/builder.ex` — capability catalog, route entries, rebuild/proof class,
  and manifest generation.
- `lib/crosswake/bridge.ex` — `push/3`, `resolve/2`, exactly-once state, timers, fact decoding,
  and D-29 payload note.
- `lib/crosswake/bridge/contract.ex` — protocol/version, request/reply envelopes, and command
  vocabulary.
- `lib/crosswake/bridge/registry.ex` — family-to-command mapping and route authorization.
- `lib/crosswake/shell/denial.ex` — closed denial vocabulary and failure-layer semantics.
- `priv/static/crosswake.esm.js` — library-owned transport, shell facts, anchoring, and reply
  correlation integration point.

### Fallback and showcase integration

- `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex` — canonical generated
  fallback source and Phase 156 handoff.
- `examples/phoenix_host/lib/crosswake_example_web/components/crosswake_fallbacks.ex` — committed
  generated artifact with frozen action semantics.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` — real trigger,
  assigns, fallback handlers, destructive confirm, and migration target.
- `examples/phoenix_host/e2e/evidence_panel.spec.ts` — denial/dead-air/contrast proof precedent.
- `examples/phoenix_host/e2e/route_tour.spec.ts` — semantic-first route-tour proof.

### Native contract and proof

- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` — current
  string-map envelope, closed enum, capability checks, and iOS dispatch.
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt`
  — current string-map envelope, closed enum, Android duplex replies, and dispatch.
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift`
  — hostless Swift vector harness.
- `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt`
  — Android JVM vector harness.
- `test/fixtures/bridge_contract_vectors.json` — canonical committed vector source.
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`
  — generated iOS mirror.
- `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` —
  generated Android mirror.

### Current official platform/ecosystem references used in discussion

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — public LiveView hook and
  callback model.
- `https://native.hotwired.dev/overview/bridge-components` — progressive enhancement precedent
  and the HTML-authority tradeoff Crosswake rejects.
- `https://developer.apple.com/design/human-interface-guidelines/action-sheets` — iOS action
  sheet semantics and destructive/cancel guidance.
- `https://developer.android.com/develop/ui/views/components/menus` — Android popup menu,
  selection, and dismissal behavior.
- `https://developer.android.com/guide/topics/ui/accessibility/principles` — Android labeling,
  target, and accessibility semantics.
- `https://v2.tauri.app/security/capabilities/` — explicit per-surface capability-grant precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Crosswake.Bridge.push/3`, `resolve/2`, and the per-mount in-flight table already provide the
  only public invocation and exactly-once primitives this control needs.
- The library-owned `crosswake.esm.js` hook already owns transport discovery, injected shell
  facts, ack/reply correlation, and no-shell fact reporting; explicit anchor measurement belongs
  there rather than in adopter JavaScript.
- The generated `action_menu/1` already provides the frozen item shape, localized runtime data,
  empty/disabled states, destructive ordering, focus return, and fallback handlers.
- The canonical native vector corpus and two existing hostless harnesses are the right proof lane;
  no new workflow or required-check name is needed.

### Established Patterns

- Route policy uses a flat capability family list plus sibling structured declarations when a
  boundary needs typed parameters (`commerce`, `transfers`, `notification_open`).
- Phoenix owns mutations and current domain authorization. Native replies are typed user input,
  never authority.
- Generated presentation remains host-owned; protocol-sensitive hook/native behavior remains
  library-owned.
- Proof extends existing named lanes, uses one canonical source, ships negative controls, and
  states its non-claims beside the assertion.
- Manifest schema, bridge protocol, native runtime, support matrix, doctor, and changelog are
  version axes that must move together when structured menu payloads land.

### Integration Points

- Route schema/struct/manifest serialization gain the `action_menu` declaration.
- Capability catalog and registry gain `action_menu` / `action_menu.present`.
- Bridge request encoding and both native envelope decoders gain structured JSON values.
- The hook gains explicit anchor measurement, stale-binary capability preflight, and coupled
  native cancellation.
- Both native cores gain one bounded presenter abstraction plus real platform adapters.
- The example ApprovalLive becomes the adopter-facing end-to-end proof: one Phoenix trigger, one
  runtime action projection, one fallback, and one typed native reply handler.

</code_context>

<specifics>
## Specific Ideas

- **“One semantic contract, platform-owned chrome.”** The same allowed action projection may
  appear as an iOS action sheet/popover and an Android popup menu without pretending those
  surfaces are pixel-identical.
- **“Selected is input, not authority.”** The native control reports what the person chose;
  Phoenix decides whether that choice is still allowed and performs the mutation.
- **“Explicit anchor or honest fallback.”** A missing trigger rectangle never becomes guessed
  placement or a crash.
- The best default demo remains a desktop browser with no shell: the branded fallback works
  completely, while a current native shell replaces the choice surface with native chrome.
- Great DX means one family declaration, one structured policy sibling, ordinary Gettext/runtime
  assigns, one `Bridge.push/3`, and ordinary `handle_info/2` pattern matching—not a second DSL,
  JS registry, or native callback framework.

</specifics>

<deferred>
## Deferred Ideas

- **Shell-owned toolbar/navigation action buttons** → the native-navigation shell milestone.
  It needs route-transition ownership and an inbound native action path, not a hidden extension
  of `action_menu.present`.
- **Multiple named action menus per route** → reconsider only after real adopter pressure proves
  one route-level contract insufficient.
- **Rendered cross-platform icon vocabulary** → later control-contract version; Phase 156 keeps
  the reserved `icon` field nil and unrendered.
- **Generic host-registered native presenter/plugin registry** → rejected by the catalog line;
  not a future extension of this capability.
- **Native confirm dialogs** → permanently out of scope; destructive selection continues into
  the host-owned Phase 155 confirm.
- **Large command palettes, searchable menus, nested submenus, contextual long-press state
  machines, and continuous native toolbar state** → separate native-screen/navigation
  capabilities, not this low-frequency request/reply control.

</deferred>

---

*Phase: 156-native-menu-action-button-control*
*Context gathered: 2026-07-30*
