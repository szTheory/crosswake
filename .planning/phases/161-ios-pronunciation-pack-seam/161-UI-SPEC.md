---
phase: 161
slug: ios-pronunciation-pack-seam
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-03
---

# Phase 161 — UI Design Contract

> Retroactive contract for the narrowly scoped, host-owned iOS pronunciation-pack recovery
> surface. It records the governing contract and reference-host implementation; it does not
> broaden Crosswake into a product UI or claim that the unresolved Phase 161 verification gaps
> are closed.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — SwiftUI system components only |
| Preset | not applicable; this is not a React/Next.js/Vite project |
| Component library | SwiftUI (`ScrollView`, `VStack`, `Label`, `Button`) |
| Icon library | SF Symbols (`checkmark.circle.fill`, `exclamationmark.triangle.fill`) |
| Font | iOS Dynamic Type system text styles; no custom font |

Do not introduce shadcn, a web token system, custom brand assets, or a new native design system.
Existing Crosswake brand assets are frozen. The host owns final learner copy and presentation;
Crosswake supplies only semantic lifecycle state, permitted action, stable rule ID, owner, and
accessibility identifiers. [Sources: 161-CONTEXT.md D-14/D-15; RequiredPackView.swift]

---

## Spacing Scale

The reference view uses the host's existing compact SwiftUI rhythm. Preserve these exact values;
do not normalize them into a new application-wide scale.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Not introduced by this surface; retain for host inline alignment only |
| sm | 8px | Gap between lifecycle label and learner message |
| md | 16px | Reserved standard host control separation; no new section required |
| lg | 24px | Horizontal/vertical content inset |
| xl | 32px | Reserved host layout gap; not required by this view |
| 2xl | 48px | Reserved host major break; not required by this view |
| 3xl | 64px | Reserved host page break; not required by this view |

Exceptions: 6px separates developer diagnostics; 20px separates the top-level content groups.
Every actionable control has a minimum 44pt height. [Source: RequiredPackView.swift]

---

## Typography

Use Dynamic Type semantic styles, so the following point values are base sizes rather than fixed
rendered sizes. Keep exactly these four size roles and the two existing weights.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Diagnostic label / route | 13pt (`footnote`) | 400 regular | system Dynamic Type metric |
| Runtime label | 15pt (`subheadline`) | 600 semibold | system Dynamic Type metric |
| Status and learner body | 17pt (`headline` / `body`) | 400 regular for body; 600 semibold for status | system Dynamic Type metric |
| Surface title | 28pt (`title`) | 600 semibold | system Dynamic Type metric |

Do not set a fixed line height, truncate status/copy, or substitute a custom font. Text must wrap
within the scrollable content column under larger Dynamic Type settings. [Sources: 161-CONTEXT.md
D-14; RequiredPackView.swift]

---

## Color

Use system adaptive colors only; no hexadecimal palette is introduced.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `systemGroupedBackground` | Full recovery-surface background |
| Secondary (30%) | SwiftUI `.secondary` foreground style | Runtime label, diagnostics, route label, and passive in-progress status |
| Accent (10%) | System green / system orange semantic status colors | Green only for `available`; orange only for route-blocking `not_installed`, `stale`, and `failed` states |
| Destructive | SwiftUI destructive button role (system red) | “Invalidate downloaded audio” only |

Accent reserved for: the lifecycle `Label` icon/text status only. Color is never the sole state
signal: every state includes an SF Symbol and explicit text. Checking/installing/invalidating use
secondary, not a success or warning accent. System light/dark adaptation is mandatory.
[Sources: 161-CONTEXT.md D-14; RequiredPackView.swift]

---

## Copywriting Contract

Copy remains host-owned, task-oriented, and deliberately excludes URLs, paths, archive names,
size/hash values, credentials, raw provider errors, media, account identifiers, and tokens.

| Element | Copy |
|---------|------|
| Surface title | `Required pronunciation audio` |
| Primary CTA | `Install offline audio`; state-specific alternatives are `Update offline audio` and `Retry download` |
| Missing-pack state | Heading: `Offline audio is required`. Body: `Install offline audio while connected to continue.` |
| Loading state | Checking: `Checking whether offline audio is ready.` Installing: `Installing offline audio. Keep this screen open.` Invalidating: `Removing offline audio before it can be installed again.` No action is offered while an operation is in flight. |
| Ready state | `Pronunciation audio is ready for offline use.` |
| Stale state | Heading: `Offline audio needs an update`. Body: `Update offline audio while connected to continue.` |
| Retryable error | Heading: `Offline audio could not be installed`. Body: `Try the download again while connected.` |
| Corrupt/revoked error | Heading: `Offline audio needs recovery`. Body: `Offline audio could not be verified. Try the download again while connected.` |
| Developer context | Show only safe `Owner: host pack provider`, a stable `PACK-*` rule ID, and a safe remediation. This is secondary text, not learner-facing storage or integrity detail. |
| Destructive confirmation | `Invalidate downloaded audio` is the only destructive control. The existing reference flow does not show a modal confirmation: it immediately enters the explicit `invalidating` blocked state, then requires a separate foreground install. Do not add a confirmation dialog or automatic reinstall in this phase. |

There is no list/collection empty state: a required pack is always either ready or explicitly
route-blocking. Do not substitute an empty placeholder, an online-only fallback, or a silent
automatic retry. [Sources: 161-CONTEXT.md D-11–D-15; RequiredPackView.swift]

---

## Interaction and Accessibility Contract

- The route remains blocked unless the PackStore reports reconciled `available`; this view never
  grants availability or accesses media/storage directly.
- Show exactly one primary foreground action per actionable state: Install for `not_installed`,
  Update for `stale`, Retry for ordinary `failed`. For `digest_mismatch`, `size_mismatch`,
  `invalidation_failed`, or `malformed_provider_result`, hide the primary action and show only
  destructive Invalidate; installation is a later, separate user action.
- `checking`, `installing`, and `invalidating` are non-actionable foreground states. There is no
  background continuation, automatic retry, or silent online degradation.
- Preserve the stable accessibility identifiers: `required-pack-status`,
  `required-pack-primary-action`, `required-pack-invalidate-action`, and `required-pack-owner`.
- Combine the status icon, state label, and learner message into one accessibility element; mark
  it as frequently updating. On lifecycle change, announce the new state label without moving
  VoiceOver focus. Buttons must retain their visible label and at least 44pt height.
- Disable decorative animation for lifecycle changes (`.animation(nil, value: status.state)`),
  preserving reduced-motion-safe transitions. Scroll rather than clip long Dynamic Type content.

The host may change final copy or visual integration only if it preserves these semantic states,
permitted actions, privacy exclusions, accessibility IDs, text-plus-color state signaling, and
fail-closed activation ownership. [Sources: 161-CONTEXT.md D-13/D-14/D-18; RequiredPackView.swift]

---

## UI Considerations

Applicable state considerations resolved: 6 covered, 1 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Required pronunciation audio media prerequisite | ✅ covered | Absence is a blocking `not_installed` state using the documented missing-pack copy and Install action; it is never a blank or generic empty screen. |
| loading | Checking/installing/invalidating lifecycle status | ✅ covered | Show explicit state text, a combined accessible status element, and no action while the foreground operation is in flight. |
| error | Failed/stale/corrupt/revoked pack prerequisite | ✅ covered | Use only a closed semantic rule and safe recovery copy. Ordinary failures Retry; integrity/revocation/malformed outcomes require Invalidate before a later Install. |
| populated | Available offline audio prerequisite | ✅ covered | Show `Offline audio is ready` plus the brief ready copy; route activation, not the view, consumes reconciled availability. |
| overflow | Recovery surface static content | ✅ covered | A `ScrollView` contains the left-aligned stack so diagnostics and Dynamic Type text can scroll rather than clip. |
| long-text | Learner message, developer remediation, route/runtime labels, and button labels | 🧪 backstop | SwiftUI text is not line-limited and must wrap in the scrollable column; retain a held-out large-Dynamic-Type UI test for readable wrapping and reachable controls. |
| partial | Form/list data | ✅ covered | Not applicable: this surface has no form or list-collection. A stale pack is modeled as an explicit blocking lifecycle state, not partial content. |
| zero-one-many | List-collection | ✅ covered | Not applicable: the recovery view represents one required pack at a time and introduces no collection layout. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no shadcn or third-party UI registry is used |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

**Pre-populated from:** 161-CONTEXT.md (D-11 through D-15 and D-18), 161-RESEARCH.md,
REQUIREMENTS.md (PACK-01 through PACK-05), ADR/route-policy constraints, and the executed
reference host (`RequiredPackView.swift` plus its XCTest contract). No additional user choice was
needed: phase decisions already lock scope, ownership, recovery, accessibility, privacy, and
non-goals.
