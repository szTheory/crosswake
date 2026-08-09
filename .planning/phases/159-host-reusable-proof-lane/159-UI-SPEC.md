---
phase: 159
slug: host-reusable-proof-lane
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-31
---

# Phase 159 — UI Design Contract

> Visual and interaction contract for the proof lane's only visual surface: the generated, test-only iOS probe. This is not a consumer screen or a new operator dashboard. It must make host-backed proof state observable to XCUITest without presenting placeholders as real proof.

---

## Scope and Ownership

- The generated SwiftUI probe is a host-owned test artifact under the configured iOS shell root. It is not product navigation, a generic native screen, a dashboard, or a support surface.
- The host owns the real auth, replay, and pack adapters. The probe only renders their closed, low-cardinality state; it has no credential, replay, mutation, pack, or account authority.
- Browser proof remains the primary web/offline-island coverage. The iOS probe covers only shell boot, backend-authority posture, terminate/relaunch, reconnect, and the later host-supplied replay/pack assertions.
- iOS tooling is advisory and non-promoting in this phase. Android has no UI, test, or parity contract.
- Do not display, persist, log, or expose in accessibility labels raw answers, payloads, media, transcripts, endpoint values, credentials, account/customer identifiers, stable device identifiers, screenshots, traces, or test output.

## Design System

| Property | Value |
|----------|-------|
| Tool | none — native SwiftUI system controls only |
| Preset | not applicable; this repository is not a React/Next.js/Vite UI surface and has no `components.json` |
| Component library | SwiftUI system `Text`, `Button`, and semantic color APIs only |
| Icon library | none; use text status labels rather than decorative icons |
| Font | system San Francisco (`.body` / `.headline`), with Dynamic Type enabled |

No shadcn or third-party registry is in scope. This avoids adding a component system or visual-polish program to a bounded proof scaffold.

---

## Required Probe Composition and Interaction

Render one vertically centered, leading-aligned diagnostic group with 16px gaps and 24px horizontal padding. It contains only the following observable elements, in order:

1. Heading: `Proof lane` (`proof-lane-title`).
2. Backend authority posture: `Backend authority required` (`proof-lane-auth-posture`). This is an informative statement, never an auth success claim.
3. Closed outcome line (`proof-lane-outcome`), sourced from the host adapter/test driver, not a fixed literal. The visible state must be exactly one of `Passed`, `Blocked`, or `Unavailable`, followed by a safe prerequisite label where relevant.
4. Retry control (`proof-lane-reconnect`) labeled `Retry proof check`, only when the host adapter exposes a real retry/reconnect action. Activating it calls that adapter action and refreshes the observable outcome. It must not be a no-op. When no actionable adapter is installed, omit the control rather than rendering a disabled success-looking affordance.

`Passed` is permitted only after the shared Xcode test scheme has executed the host-backed XCTest/XCUITest assertion for the named boundary. A compiled target, launch, static label, or missing adapter must render `Blocked` or `Unavailable`, never `Passed`.

On terminate and relaunch, the probe must again obtain and render host-provided state; it must not fabricate continuity from a fixed Swift value. All four identifiers above are stable XCUITest contracts. The existing `proof-lane-ready` identifier may remain only if bound to actual shell boot state; it cannot be used as evidence of auth, replay, or pack success.

---

## Spacing Scale

Declared values (multiples of 4 only):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Status label to safe rule/prerequisite detail |
| sm | 8px | Heading-to-posture separation and button internal gap |
| md | 16px | Default vertical stack gap; minimum control spacing |
| lg | 24px | Horizontal screen inset and diagnostic group padding |
| xl | 32px | Top/bottom breathing room when the group is vertically centered |
| 2xl | 48px | Not used in this bounded probe |
| 3xl | 64px | Not used in this bounded probe |

Exceptions: native controls must retain the platform's minimum 44×44pt tappable target. No dense table, card grid, sidebar, or dashboard layout is allowed.

---

## Typography

Use exactly these system text roles. Permit Dynamic Type scaling; do not truncate status or remediation text.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Detail / safe rule ID | 14px | regular (400) | 1.4 |
| Body / posture / outcome | 16px | regular (400) | 1.5 |
| Heading / button label | 20px | semibold (600) | 1.2 |

Long outcome and rule text wraps to additional lines inside the 24px insets. It must not ellipsize, horizontally scroll, or reduce below the declared body/detail sizes.

---

## Color

This test probe is intentionally not a branded 60/30/10 marketing composition. Use adaptive SwiftUI semantic surfaces so it remains legible in light and dark modes; the 60/30/10 allocation below is a maximum visual hierarchy, not an invitation to add decoration.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | system background (adaptive; light fallback `#F7F1E6`) | Screen background and ordinary text surface |
| Secondary (30%) | system secondary background (adaptive; light fallback `#EFE6D6`) | Optional single outcome container; omit the container if it adds no clarity |
| Accent (10%) | Wake 700 `#2B756A` | Enabled `Retry proof check` control and keyboard/focus indication only |
| Destructive | Rust 600 `#9A4D35` | Not used: this phase has no destructive action |

Accent reserved for: the enabled, host-backed `Retry proof check` action and its focus state. Never use accent or a green-like treatment to imply `Passed`; every outcome is conveyed by its text label. `Blocked` and `Unavailable` may use the platform's semantic warning/error treatment only alongside their literal labels; color alone is insufficient.

---

## Copywriting Contract

All strings are short, status-oriented, and contain only a stable rule ID or safe prerequisite name. They must never interpolate configuration values, IDs, endpoints, payloads, credentials, raw tool output, or personal data.

| Element | Copy |
|---------|------|
| Primary CTA | `Retry proof check` — render only for a real host adapter retry action |
| Ready / shell heading | `Proof lane` |
| Auth posture | `Backend authority required` |
| Passed state | `Passed — host assertion completed` — allowed only after an executed host-backed test action |
| Blocked state | `Blocked — {safe prerequisite}. Run {safe next command}.` |
| Unavailable state | `Unavailable — {safe prerequisite}. Install or configure the required tool, then run {safe next command}.` |
| Empty state heading | `No proof action is configured` |
| Empty state body | `Add the host proof adapter, then run the generated proof command.` |
| Error state | `Proof blocked — {stable rule ID}. Review the generated configuration and run the documented command.` |
| Destructive confirmation | None — the probe offers no destructive action, file replacement, reset, logout, or evidence deletion |

The `{safe prerequisite}`, `{safe next command}`, and `{stable rule ID}` placeholders are closed/sanitized fields. If a safe next command is unavailable, use `Review the generated proof configuration.` rather than echoing untrusted data.

---

## Accessibility and Test Contract

- The probe is usable with VoiceOver: outcome text, posture text, and the reconnect control have their visible labels as accessibility labels; no hidden test-only success text exists.
- Preserve these stable identifiers: `proof-lane-title`, `proof-lane-auth-posture`, `proof-lane-outcome`, and, when rendered, `proof-lane-reconnect`. Bind them to real adapter state/action, not fixed literals.
- XCUITest must launch, observe the initial outcome, terminate, relaunch, invoke `Retry proof check` when available, and observe the adapter-derived resulting outcome. The shared scheme must execute this UI test plus the XCTest driver contract before the verifier may emit `passed`.
- The interface exposes no loading spinner. While adapter evaluation is in flight, retain the prior non-passing outcome with an accessible `Checking proof prerequisites` status; do not clear the outcome or optimistically show `Passed`.
- There is no consumer navigation, browser-like DOM inspection, credential entry, account selection, media player, or pack-management UI in this phase.

---

## UI Considerations

Applicable state considerations resolved: 1 covered, 1 backstop, 0 unresolved. The confirmed element kinds are `static-content` for the heading, authority posture, and outcome line, plus `interactive-control` for the retry control.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| overflow | Heading, authority posture, outcome, and safe remediation text | ✅ covered | Every text surface reflows within the 24px horizontal insets, wraps to additional lines, and never clips, ellipsizes, horizontally scrolls, or shrinks below its declared text role. |
| long-text | Heading, authority posture, outcome, safe rule/remediation copy, and `Retry proof check` | 🧪 backstop | `{ statement: "XCUITest at an accessibility text size verifies wrapping and reflow within the 24px insets, the retry control's 44×44pt target, and no clipping, ellipsis, or horizontal scroll.", verification: backstop }` |

The closed probe did not raise `empty`, `loading`, `error`, `populated`, `partial`, or `zero-one-many` for the confirmed static-content and interactive-control kinds. The explicit in-flight, empty-configuration, and blocked/unavailable copy contracts remain required above; their omission from this closed taxonomy is not permission to remove them.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable — no React shadcn initialization |
| third-party | none | not applicable |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved by `gsd-ui-checker`; the single non-blocking CTA recommendation is incorporated as `Retry proof check`.

## Sources Applied

- `159-CONTEXT.md`: D-01 through D-23, especially host ownership, actual XCUITest lifecycle, explicit non-passing prerequisites, accessible user-observable state, privacy, read-only safety, and no-dashboard scope.
- `159-RESEARCH.md`: SwiftUI/XCTest/XCUITest as the generated iOS proof stack and the browser corpus as primary web/island proof.
- `159-VERIFICATION.md`: binding contract for the current blockers — fixed labels/no-op reconnect cannot certify host behavior, and build-for-testing alone cannot emit `passed`.
- `AGENTS.md`, governing ADR, adoption brief, and route policy: iOS-only v21, backend authority, fail-closed outcomes, privacy-safe evidence, and the prohibition on product polish or operator dashboards.
- `brandbook/BRAND-SPEC.md`: calm, exact, actionable status copy; text labels rather than color alone; approved semantic palette only where a system control needs one.
