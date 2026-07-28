---
id: SEED-005
status: planted
planted: 2026-07-27
planted_during: "Phase 153 iOS mirror unblock (v20.0 Native Controls Pack 1) — planted while the native-control vocabulary and the host-owned fallback generator are fresh"
trigger_when: "Surface during Native Controls Pack 2 (or any post-v20 milestone) planning, when the roadmap turns to the WEB side of delegated controls — the themable host-owned fallback every native control implies."
scope: Large
---

# SEED-005: Ship a brand-themable, host-owned WEB equivalent for every control that has a native peer

## Why This Matters

Crosswake's thesis is that an app owns its routes and *delegates* certain UI controls (haptics, share, action menus, and — as v20 sharpens the seam — toasts, alerts, notifications) to a native iOS/Android shell, falling back web-side through **one typed `Shell.Denial` reply** when no native shell is present. Today that fallback is either unstyled or absent: the only live control invocation in the repo is a hand-rolled `<script>` IIFE with no reply path, and v20's plan is to generate a *few* host-owned fallback components for the controls it CUT as native families (toast, confirm). This seed generalizes that from "a handful of CUT controls" into a first-class tier: **for every control Crosswake can dispatch to native, also ship an out-of-the-box, brand-themable web equivalent — generated into the adopter's own codebase (host-owned copy, escape-hatchable to fully custom), themable across every design dimension.**

The load-bearing insight — and the one no component library can copy — is that **for the UI-bearing controls, the native OS surface is either absent or unbrandable, so the themable web equivalent is often the *only* genuinely on-brand surface an adopter can ship.** iOS has no native toast at all (v20 already CUT it as a "category error"); native iOS/Android alerts and notifications expose essentially zero brand surface. Capacitor — the closest architectural sibling (native-primary + web-fallback + typed "unavailable/unimplemented" denials) — proves this negatively: its UI-bearing web fallbacks are a `<pwa-toast>` custom element and `window.confirm`, both unthemable, and developers routinely rip them out and hand-roll branded replacements. That hand-rolling is the recurring, unpaid tax this seed removes. Adopters would stop rebuilding the web versions of controls they already get "for free" natively — and get the web "native" version too, customizable to the degree web controls actually are (more "web"/branded than true-OS-native).

Crucially, this is **coherent with the brand's "no importable component tier" anti-feature (`BRAND-SPEC.md §7`), not a violation of it** — *if* the mechanism stays a generator that copies host-owned, token-wired files into the adopter's tree (like `mix crosswake.gen.offline_ui`), diverge-on-line-one. The "escape hatch to fully custom" framing fits the pillar precisely because generated host-owned files are the adopter's from line one. The seed's job is to name, generalize, and durably record this thesis — most of the primitives already exist in v20 — not to invent a UI kit.

## When to Surface

**Trigger:** Surface during Native Controls Pack 2 (or any post-v20 milestone) planning, when the roadmap turns to the WEB side of delegated controls, host-owned fallback UI, or extending the design-token system.

This seed should be presented during `$gsd-new-milestone` when the milestone scope matches any of these conditions:
- the next milestone is a second native-controls pack, or otherwise widens the set of controls Crosswake delegates
- milestone planning turns to the web/LiveView FALLBACK rendering of controls (generalizing v20's FALL-01/02 `mix crosswake.gen.native_controls_ui`)
- milestone planning turns to extending the design-token system (shadow/elevation, z-index, motion, border-width, padding) or the consumer-drift gate
- adopter/DX evidence shows teams hand-rolling web versions of toast / alert / action-sheet / notification because the native surface can't be branded
- the discussion is about how far "themable out of the box" should go before the adopter drops to fully custom

## Scope Estimate

**Large** — a milestone family (Native Controls Pack 2), not a single phase. It spans (1) extending the DTCG token system by five missing dimensions, (2) a contract-core-vs-generated-shell architecture with an upgrade/diff verb, (3) per-control themable web equivalents built on native platform primitives with non-negotiable a11y, (4) capability-probe + two-typed-denial degradation, (5) honesty + security hardening for any web-platform-API tie-ins, and (6) a11y + themed-visual proof lanes run in BOTH native-shell and web-fallback paths. It depends on v20's `Bridge.push/3` seam and the `gen.native_controls_ui` fallback generator landing first.

## Breadcrumbs

Related code, decisions, and cross-ecosystem prior art (deep multi-lens research fan-out, 2026-07-27):

**In-repo — the seam and generator this generalizes:**
- [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex) — the typed, versioned request/reply envelope (closed `@commands` allowlist); the web equivalent must be generated from this same contract so the fallback can never silently drift from native
- [lib/crosswake/shell/denial.ex](/Users/jon/projects/crosswake/lib/crosswake/shell/denial.ex) — the closed denial vocabulary; the ONE typed reply the themable web equivalent renders from (no-shell / old-shell / undeclared all collapse here)
- [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex) — per-route capability authorization + closed command→capability map
- [lib/crosswake/runtime_line/rebuild_policy.ex](/Users/jon/projects/crosswake/lib/crosswake/runtime_line/rebuild_policy.ex) — OTA-safe vs native-rebuild-required classification (a themable web equivalent is OTA-safe; the native peer is `:native_required`)
- [lib/mix/tasks/crosswake.gen.offline_ui.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.offline_ui.ex) — the verbatim-copy, no-clobber, host-owned generator precedent (no importable `Crosswake.UI.*`); the exact model to generalize
- [examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex) — the current hand-rolled control IIFE (fire-and-forget, no reply path) that the seam replaces

**In-repo — the theming system to extend:**
- [brandbook/tokens/crosswake.tokens.json](/Users/jon/projects/crosswake/brandbook/tokens/crosswake.tokens.json) + [brandbook/tools/compile-tokens.js](/Users/jon/projects/crosswake/brandbook/tools/compile-tokens.js) — the DTCG-source → CSS pipeline the five new dimensions extend (additive `$type`s, no architecture change)
- [brandbook/tokens/tokens.css](/Users/jon/projects/crosswake/brandbook/tokens/tokens.css) — the two-tier `--cw-*` output; tokenizes color/type/radius/base-spacing/focus but NOT shadow/elevation/z-index/motion/border-width/named-padding
- [brandbook/BRAND-SPEC.md](/Users/jon/projects/crosswake/brandbook/BRAND-SPEC.md) — §7 the "no importable component tier" pillar (the load-bearing constraint); §13/§18 already PROSE-spec shadow, motion, and breakpoints — the spec is ahead of the token file on exactly the dimensions controls need
- [brandbook/tools/check-consumer-drift.mjs](/Users/jon/projects/crosswake/brandbook/tools/check-consumer-drift.mjs) — the REQUIRED `brand-structural` drift gate; polices COLOR only today (radius/shadow/z drift uncaught — real drift exists), a candidate to extend

**In-repo — v20's already-written fallback design:**
- [.planning/research/v20/UX-CONTRACT.md](/Users/jon/projects/crosswake/.planning/research/v20/UX-CONTRACT.md) and [.planning/research/v20/API-DESIGN.md](/Users/jon/projects/crosswake/.planning/research/v20/API-DESIGN.md) — FALL-01/02 host-owned fallback components + `Bridge.push/3` + one-branch degradation contract
- [.planning/research/v20/SUMMARY.md](/Users/jon/projects/crosswake/.planning/research/v20/SUMMARY.md) — the control-by-control BUILD/CUT verdicts (toast = CUT as native; alert/confirm = CUT → themable LiveView modal); the "catalog line IN/OUT" rule

**Cross-ecosystem prior art:**
- [Capacitor plugins](https://capacitorjs.com/docs/plugins/web) — closest sibling; two typed denials (`unavailable()` vs `unimplemented()`), `canShare()`/`isPluginAvailable()` capability probes, and the anti-lessons: UI fallbacks (`pwa-toast`, `window.confirm`) are unthemable + depend on a hidden second package ([#1934](https://github.com/ionic-team/capacitor/issues/1934))
- [shadcn/ui registry + CLI `--diff`](https://ui.shadcn.com/docs/cli) and [theming](https://ui.shadcn.com/docs/theming) — the copy-in "you own the code" model and its central un-upgradable-code problem; the registry (not a package) is the reusable unit
- [Zag.js](https://zagjs.com/) / [Radix](https://www.radix-ui.com/primitives) / React Aria / [Melt UI](https://github.com/melt-ui/melt-ui) — behavior/a11y state machines kept SEPARATE from styling; the split this seed must adopt
- [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/patterns/) — the non-negotiable ARIA/keyboard contract per control (alertdialog, menu roving-tabindex + typeahead, live regions)
- [MDN `<dialog>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog) · [Popover API (Baseline Jan 2025)](https://web.dev/blog/popover-api) · [Web Share](https://developer.mozilla.org/en-US/docs/Web/API/Web_Share_API) · `@starting-style` + `allow-discrete` (Baseline 2024) — the platform substrate to build ON, not reimplement
- [Material 3 elevation](https://m3.material.io/styles/elevation/tokens) & [motion tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs) · [Open Props](https://open-props.style/) · Style Dictionary/DTCG — the model for the five new token dimensions
- [Ionic mode system](https://ionicframework.com/docs/theming/platform-styles) & Flutter Cupertino/Material — platform-adaptive prior art (default-adapt-but-always-overridable; don't over-promise auto-adaptation; Shadow-DOM lock-in is the top resentment)
- [Reach UI (unmaintained)](https://github.com/reach/reach-ui/issues/972) / MUI docs backlog — why a solo project must NOT own novel a11y research or an unbounded catalog

## Notes

Future milestone family to preserve — **Native Controls Pack 2** (plausibly `v21.0`+, core-only; no `crosswake_controls` companion, since controls have no external SDK to gate):

### The one-sentence thesis
"The fallback, finished." Ship a brand-themable, host-owned, generator-emitted WEB equivalent for every control Crosswake delegates to native — because the host-owned generator + one-typed-denial fallback already exist as v20 primitives, and for the UI-bearing controls the native surface is absent or unbrandable, so the web equivalent is the only genuinely on-brand surface. **Position it as "stop hand-rolling the web versions of controls you get free natively" — never as a "component library" or "UI kit."**

### THE HARD SCOPE FENCE (the anti-metastasis rule — make it a product constraint)
Generate a web control **only where a native delegate already exists.** NOT tabs, cards, tables, data-grid, rich-text — the moment scope becomes "any nice web component," Crosswake has become DaisyUI/Petal and lost its only differentiation. The parity boundary IS both the scope-bounding mechanism and the defensible position. Publish the rule so "add X" requests self-triage. Secondary IN gate: the control has a settled WAI-ARIA APG pattern; if it can't be CI-proven accessible, it's OUT.

### Architecture — the single most important takeaway (contract-core + generated-shell split)
Reconcile "host-owned + no importable component tier" with "don't orphan a11y/security fixes in copied code" by splitting the control in two:
- **Behavior/contract core — versioned, imported (core, render-agnostic, NO markup):** the typed control contract, the two-typed-denial handling, keyboard/focus/ARIA state (the Zag/Melt/Radix lesson), capability probe. This is NOT a "component tier" — it's the existing `Bridge.Contract`/`Shell.Denial` seam extended. Because it ships via `deps.update`, a11y and security fixes reach the field without per-copy merges — solving shadcn's fatal upgrade problem for the *risky* part.
- **Presentational shell — generated host-owned (the `--cw-*`-token-wired `.heex`/CSS/JS):** fully editable, escape-hatch to custom, diverge-on-line-one. Honors the brand pillar; carries ~95% of brand expression through tokens so the copy rarely needs editing.
- Ship a **registry + `mix crosswake.ui.diff` / `--outdated` 3-way-merge verb + per-file version stamp** from day one — the specific gap that sank naive copy-in tools. No-clobber default, `--dry-run`.

### The token work — the concrete deliverable (5 new DTCG dimensions, role-named, ~6 steps each)
Every overlay control is a *surface + elevation + motion + z-layer* composite; today only the surface fill (color/type/radius) is tokenized, so controls render on-brand flat and off-brand the moment they float/animate/stack. Add, role-named on the semantic tier over numeric primitives (mirrors the existing primitive→semantic split):
- `--cw-elevation-{flat,raised,overlay,modal}` — **MUST be a tint+shadow pair** (Material 3), so dark mode reads depth via tint when box-shadow vanishes. Validate every level in light AND dark.
- `--cw-z-{base,dropdown,sticky,overlay,modal,popover,toast,tooltip}` — a named z-scale; never raw integers in components (retires stacking-context wars).
- `--cw-motion-{enter,exit,emphasized}` — `{duration, easing}` pairs; **reduced-motion collapses to 0ms/none CENTRALLY as a token behavior**, not per-component CSS.
- `--cw-border-width-{hairline,sm,md}`.
- `--cw-space-{2xs..2xl}` — a named padding/gap ramp (retires the current `calc(base*N)` literals and the uncaught hardcoded-`8px`-radius drift).
Keep springs / complex keyframes OUT of the token API (DTCG has no first-class type) — those live in the escape hatch. This is largely "tokenize what `BRAND-SPEC.md` already prose-specs." Consider extending the drift gate to police radius/shadow/z drift, not just color.

### Build ON platform primitives, then theme them (don't reimplement)
- confirm / alert / modal → native **`<dialog showModal()>`** (top layer, focus trap, `::backdrop`, Esc, Baseline 2022).
- menu / tooltip / toast / sheet → **Popover API** (Baseline Jan 2025); CSS anchor-positioning as progressive enhancement with a JS placement fallback (not yet Baseline).
- enter/exit animation → **`@starting-style` + `transition-behavior: allow-discrete`** (Baseline 2024) so platform-based controls don't feel inferior to the native shells they mirror.
- Default open/close/dismiss to **client-only `Phoenix.LiveView.JS`** (no socket round-trip); server-driven is an opt-in flag for durable/authoritative toasts ("saved").
- Scope `--cw-*` theme vars to a **control-root wrapper, never `:root`** (a `:root` theme swap repaints the whole page); compositor-only (`transform`/`opacity`) animations.

### Accessibility is fixed structure; only tokens are themable (non-negotiable)
Generate ARIA roles, `aria-*`, focus management, and keyboard handlers as fixed behavior the adopter can't delete by styling; expose only color/spacing/radius/motion as CSS custom properties. Per-control contract from the APG: toast/notification = one always-mounted live-region host (`role=status` polite / `role=alert` assertive, solves the load-timing footgun once); alertdialog = focus-trap + return-focus + inert background + Esc; menu = roving tabindex + arrow/Home/End + typeahead + `aria-haspopup`/`aria-expanded`; tooltip = focusable trigger + show on focus AND hover. Ship an a11y test harness (axe + keyboard-walk Playwright) run in BOTH the native-shell and web-fallback paths to catch divergence. Where a well-built web control BEATS native: screen-reader consistency, keyboard, i18n/RTL/zoom, CI-testability.

### Degradation contract (adopt Capacitor's two-error split, verbatim in spirit)
Split the denial along two axes, each typed with a code so LiveView/consumers branch: **`unavailable`** (API/native exists but this surface can't right now) vs **`unimplemented`** (deliberately not on this surface). Provide a `canX()` capability probe (like `Share.canShare()` / `isPluginAvailable()`), not just throws. Self-contained — no hidden second package (Capacitor's `pwa-elements` footgun). The web equivalent is generated from the SAME control contract native implements, guaranteeing surface parity.

### Web-platform-API tie-ins — only where support is real and detectable
- **Share** → Web Share behind `canShare()` (clean win; degrade to copy-link where absent, e.g. desktop Firefox).
- **Notification** → Notifications/Push as an OPT-IN PWA enhancement only (iOS 16.4+ home-screen-installed; permission-abuse-gated), never the control's default behavior.
- **Haptics** → NO cross-platform web substrate (iOS Safari has never supported Vibration; Firefox desktop removed it in 129). The web equivalent is purely visual/audio; `navigator.vibrate` is Android-only sugar. **The gaps VALIDATE the product** — precisely where native web fails, a brand-themable DOM control is the only path.

### Risks / antipatterns / footguns to encode
- **Identity drift into "yet another UI kit"** — the gravitational pull from "delegated controls" to "all controls" comes from users, not the roadmap. The parity fence is the only defense.
- **Orphaned fixes** — a11y/security fixes can't reach copied code; the contract-core-vs-shell split + `--diff`/version-stamp is the answer.
- **Bad defaults kill "for free"** — calibrate defaults to "neutral-tasteful, obviously themable" (wired to your tokens), NOT "branded/pretty out of the box"; invest disproportionately in default quality (a11y, keyboard, focus).
- **Native-impersonation spoofing (honesty invariant)** — a themed web toast/modal must look *web*, not fake OS/system chrome; extend Crosswake's advisory/emulator-evidence honesty discipline into a "not-a-system-surface" rule (also a phishing/clickjacking mitigation).
- **Shadow-only elevation** breaks dark mode; **over-tokenizing** every dimension into a var explosion; **Shadow-DOM/`::part` lock-in** (Ionic's #1 resentment); **socket round-trips for presentation-only state**; **a11y-dies-in-themable-controls** (div-soup toasts, un-trapped modals).
- **Don't own novel a11y research or an unbounded catalog** (Reach UI bankruptcy; MUI docs backlog) — build over vetted APG patterns; docs + per-control CI a11y proof are part of "done"; the CI a11y gate IS the scope-bounding mechanism.

### Pre-staged requirement-category skeleton (for `/gsd-new-milestone`)
- **THEME-*** — the five new DTCG token dimensions (elevation/shadow, z, motion, border-width, padding), role-named, light/dark-validated; optional drift-gate extension.
- **WCTRL-*** — per-control themable web equivalents (toast, alert/confirm, action-sheet/menu, tooltip, banner) built on `<dialog>`/Popover, APG-accessible, token-wired.
- **FALL-*** (reuse/generalize v20's family) — the contract-core + generated-shell split, `mix crosswake.gen.native_controls_ui` generalized, the `--diff`/version-stamp upgrade verb, capability probe + two-typed-denial.
- **HRDN-*** — honesty invariant (no fake-native chrome), user-activation/secure-context gating for web-API tie-ins.
- **PROOF-*** — a11y harness in BOTH native + web paths, themed light/dark snapshots, a small fixed cross-browser (Chromium/WebKit/Firefox) matrix.
- **support-truth category** — required per the arc for any milestone that widens Crosswake's public surface.

Rough phase sketch: (1) token-dimension extension + drift-gate; (2) contract-core/shell split + generator + upgrade/diff verb; (3) the un-brandable trio first — toast, alert/confirm, action-sheet/menu — on platform primitives; (4) web-API tie-ins (share) + honesty/security hardening; (5) a11y + themed-visual proof lanes.

### Constraints (carry from v20 / the thesis)
- Keep it a GENERATOR (host-owned copies), never an importable component tier (`BRAND-SPEC.md §7`).
- The behavior/contract core is core, render-agnostic, and versioned; only the presentational shell is generated.
- Stay fail-closed; one typed denial reply; don't drift into a generic plugin bus.
- Enforce the native-parity fence as a hard product constraint, not a guideline.
