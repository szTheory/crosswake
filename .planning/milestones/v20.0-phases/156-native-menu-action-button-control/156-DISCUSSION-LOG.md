# Phase 156: Native Menu & Action-Button Control - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 156-native-menu-action-button-control
**Areas discussed:** Native trigger ownership, declared actions versus runtime state, platform
presentation, disabled and destructive actions

---

## Native trigger ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Phoenix-owned trigger | Ordinary LiveView button opens the fallback and invokes native enhancement through `Bridge.push/3`. | ✓ |
| Shell-owned toolbar button | Route activation creates persistent native toolbar/navigation chrome. | |
| DOM-declared bridge component | Native behavior is authorized/inferred from HEEx attributes à la Hotwire Native. | |
| Host-registered native trigger | Adopter registers arbitrary native menu/button handlers. | |

**User's choice:** Discuss all options with parallel expert research and make the decision.
**Notes:** Selected Phoenix ownership because it preserves the shipped request/reply seam,
complete browser fallback, route-local authority, and mutation ownership. Shell chrome belongs
with native navigation.

---

## Declared actions versus runtime state

| Option | Description | Selected |
|--------|-------------|----------|
| Fully static policy menu | Router contains ids, labels, ordering, disabled state, and copy. | |
| Policy allowlist + runtime projection | Policy owns ids/safety/fallback; LiveView owns localized labels and record state. | ✓ |
| Fully dynamic payload | Policy declares only the family; each invocation may send arbitrary actions. | |
| Host module/MFA source | Router points at code that generates the menu contract. | |

**User's choice:** Discuss all options with strong Phoenix/Elixir DX and least-surprise emphasis;
make one coherent recommendation.
**Notes:** The selected split keeps router policy authoritative without turning router files into
Gettext/view-state stores. It retains Phase 155's frozen runtime shape.

---

## Platform presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Platform-adaptive native menu | iOS action sheet/popover and Android anchored PopupMenu share semantics, not pixels. | ✓ |
| Modal sheet on both | Custom/Material bottom sheets force closer visual parity. | |
| Anchored menu on both | iOS UIMenu and Android PopupMenu optimize for compact placement but weaken iOS dismissal reply. | |
| Fallback only | Keep the Phase 155 Phoenix menu and defer native UI. | |

**User's choice:** Research UI/UX, accessibility, platform precedent, JTBD, and user psychology;
make the decision.
**Notes:** Platform-adaptive chrome best serves the native JTBD without adding an Android UI
framework or fighting platform conventions. Explicit anchoring is mandatory and fail-closed.

---

## Disabled and destructive actions

| Option | Description | Selected |
|--------|-------------|----------|
| Visible disabled explanatory rows | Keep `id:nil` rows present, disabled, and self-explanatory. | ✓ |
| Omit unavailable actions | Hide actions that cannot currently be selected. | |
| Native destructive confirmation | Native owns confirmation and mutation progression. | |
| Runtime-unrestricted semantics | Runtime may change destructive/icon/availability semantics outside policy. | |

**User's choice:** Research all tradeoffs and make the decision as part of the coherent set.
**Notes:** Visible explanations preserve Phase 155 behavior and avoid mysterious omissions.
Destructive actions sort last, return only an id, and continue through the host-owned confirm;
Phoenix reauthorizes before mutation.

---

## the agent's Discretion

- The user explicitly delegated all four areas after requesting parallel expert research.
- Three `gsd-advisor-researcher` tracks covered Phoenix/Elixir API design, native UI/accessibility,
  and bridge/proof/release architecture.
- Follow-up research resolved the exact minimal route-policy shape and typed trigger-anchor
  contract.

## Deferred Ideas

- Shell-owned toolbar/navigation action buttons.
- Multiple named menus per route.
- Rendered cross-platform icon vocabulary.
- Native confirm dialogs.
- Generic host presenter/plugin registries.
- Large/searchable/nested menus and continuous native state.
