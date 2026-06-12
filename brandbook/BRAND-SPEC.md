# Crosswake Brand Identity Specification

**Version:** v1.0  
**Date:** 2026-06-11  
**Status:** Ratified — supersedes `prompts/crosswake-brand-book.md` (historical seed, remains untouched).  
**Audit provenance:** All AUDIT verdicts from `brandbook/AUDIT.md` applied (AUDT-04 ratified 2026-06-11).

---

## 1. Brand summary {#brand-summary}

**Name:** Crosswake  
**Package style:** `crosswake`  
**Module namespace:** `Crosswake`  
**Pronunciation:** `cross-wake`  
**Preferred capitalization:** Crosswake, not CrossWake, Cross Wake, or Cross-Wake.

**Core idea:** Crosswake is the clean trail left by a Phoenix app crossing into mobile runtimes without pretending the boundary disappeared.

**Primary one-liner:**

> Crosswake is a Phoenix-native mobile substrate for declaring which runtime owns each route: LiveView, offline island, native screen, or adapter.

**Shorter one-liner:**

> Route policy for Phoenix apps that go mobile.

**Positioning sentence:**

> Crosswake helps Phoenix teams ship mobile apps by making runtime boundaries explicit: server-centric screens stay LiveView, device-heavy flows go native, and local-first work lives in offline islands.

**Brand promise:**

> Declare the crossing. Keep the boundary honest.

**What Crosswake is not:**

- Not a React Native clone.
- Not a Phoenix-flavored Flutter.
- Not a generic WebView wrapper.
- Not a promise that every screen can be one runtime.
- Not "write once, run anywhere."
- Not "offline magically works."

**What Crosswake is:**

- A route policy system.
- A mobile runtime manifest.
- A native-shell and bridge contract layer.
- A capability registry.
- An offline/content/media pack substrate.
- A disciplined escape hatch into native screens.

---

## 2. Brand essence {#brand-essence}

### Essence

**Boundary-aware mobility.**

Crosswake should feel like a stable channel through rough technical water: calm, precise, durable, and honest about what owns what.

### Personality

- **Calm:** no hype, no panic, no "magic."
- **Explicit:** every route, capability, cache mode, and native dependency is named.
- **Technical:** designed for maintainers who care about correctness.
- **Open:** OSS-first, practical, community-readable.
- **Mobile-native where necessary:** respectful of iOS/Android realities.
- **Phoenix-native:** server truth, route declarations, telemetry, clear contracts.

### Brand pillars

1. **Declare the crossing**  
   Each route declares its runtime, capabilities, offline policy, media/content packs, and security posture.

2. **Keep each runtime honest**  
   LiveView owns server-centric flows. Native owns platform-heavy flows. Offline islands own local-first loops.

3. **No hidden bridge magic**  
   Bridge messages are semantic, versioned, low-frequency, and testable.

4. **Local when useful, server-authoritative when required**  
   Offline work should distinguish drafts, cached reads, local events, and online commits.

5. **Designed for maintainers**  
   Every feature should have a manifest, telemetry, test fixtures, failure modes, and docs.

### DNA (from audit §2)

| Trait | Expression |
|-------|------------|
| Explicit | Everything is named: routes, runtimes, capabilities, policies |
| Calm | No hype, no "magic," no surprise |
| Technical | Designed for engineers who read the source code |
| Honest | Failure modes documented before features |
| OSS-generous | Maintainer shares judgment, not just syntax |
| Precise | Measurements, contracts, verdicts |

**Anti-traits:** Salesy, Evasive, Trend-chasing, Omniscient

### Design principles

1. The diagram is the product. Runtime boundaries made visible are the core value.
2. Contrast as contract. Accessible color is not a feature; it is the brand.
3. Technical quiet. Docs quieter than marketing; marketing honest enough to belong next to docs.
4. One color family per runtime. The palette gives each runtime a distinct signal without competing.

---

## 3. Competitive and conflict guardrails {#competitive-guardrails}

Crosswake sits near several established ideas but should not visually or verbally imitate them.

### Avoid confusing Crosswake with React Native

**Avoid:** atom marks, orbital rings, neon cyan hero art, "native components from one UI language," "write once."

**Use instead:** route policy, runtime boundaries, manifest, capability gates, server/native/local ownership.

### Avoid confusing Crosswake with Hotwire Native

**Avoid:** red/orange heat language, "HTML over the wire" phrasing, "web content is all the app," wire/plug graphics.

**Use instead:** crossing, wake, seam, route policy, capability registry, offline/media/native-screen ownership.

### Avoid confusing Crosswake with LiveView Native

**Avoid:** "Native LiveView," "render native UI from LiveView," Phoenix flame-like marks, purple/orange flame emphasis.

**Use instead:** Phoenix-native mobile deployment substrate; route-by-route runtime selection.

### Avoid confusing Crosswake with Capacitor/Ionic

**Avoid:** "native runtime for web apps," plugin marketplace language, electric blue/purple app-platform gradients.

**Use instead:** Phoenix route policy, typed contracts, explicit capabilities, telemetry, and host-owned native screens.

### Avoid Crosswalk confusion

**Avoid:** "Crosswalk," "WebView engine," "Chromium runtime," browser-engine messaging.

---

## 4. Naming system {#naming-system}

### Product and package names

- Product: **Crosswake**
- Hex package: `crosswake`
- Core namespace: `Crosswake`
- Mix tasks: `mix crosswake.gen.*`
- CLI/log prefix: `[crosswake]`

### Preferred concept names

Use these consistently:

- Route Policy
- Runtime
- Native Shell
- Bridge Contract
- Native Screen
- Capability
- Capability Registry
- Runtime Manifest
- Offline Island
- Content Pack
- Media Pack
- Sync Journal
- Compatibility Gate
- Host App
- App Binary

### Avoid these names

- Plugin, unless referring to third-party ecosystems.
- Magic, sprinkle, seamless, universal.
- Cross-platform UI framework.
- WebView wrapper as the main descriptor.
- Native LiveView.
- Write once.

---

## 5. Taglines and messaging {#taglines-messaging}

### Primary tagline

> Declare the crossing.

### Secondary taglines

- Keep every mobile route honest.
- Phoenix routes, native where it matters.
- Server where it sings. Native where it must. Offline where it matters.
- A route policy layer for Phoenix apps on mobile.
- Cross the web/native seam without hiding it.

### Homepage hero options

**Option A (recommended)**

> Phoenix routes, native where it matters.
>
> Crosswake gives Phoenix apps a mobile route policy: LiveView for server-centric flows, offline islands for local work, and native screens for device-heavy moments.

**Option B**

> Declare the crossing.
>
> Crosswake lets Phoenix teams choose the right runtime per route — LiveView, offline island, native screen, or adapter — without blurring the boundary.

**Option C**

> Mobile apps without pretending every screen is the same screen.
>
> Crosswake turns route policy, native capabilities, offline packs, bridge contracts, and runtime compatibility into explicit Phoenix-native primitives.

### Three-bullet value proposition

- **Route-owned runtime policy:** declare whether each screen is LiveView, offline, native, or adapter-backed.
- **Typed native boundaries:** version bridge messages, capability requirements, native screens, and app-binary compatibility.
- **Local-first where it belongs:** use offline islands, content packs, media packs, and event journals without making unsafe server actions look offline.

### Ready-to-use copy blocks (from audit §10)

**GitHub repo description (≤ 300 chars):**

> Phoenix-native mobile substrate. Declare which runtime owns each route — LiveView, offline island, native screen, or adapter — and keep the boundary explicit. Route policy, capability registry, bridge contracts, and offline islands for Phoenix teams.

**Hex.pm description (≤ 160 chars):**

> Route policy for Phoenix apps that go mobile. Declare LiveView, offline, native, and adapter-backed routes explicitly. No write-once magic.

---

## 6. Voice and tone {#voice-and-tone}

### Voice principles

**Write like a careful maintainer.**  
Precise, short, helpful, and candid.

**Explain the boundary.**  
Crosswake exists to make runtime ownership explicit. The docs should repeatedly clarify what runs on the server, in the shell, in the WebView, in local JS, and in native code.

**Prefer operational truth over hype.**  
Say what happens, where it happens, and what can fail.

**Use metaphor sparingly.**  
"Wake," "crossing," "seam," "channel," and "island" are allowed, but technical documentation should not become nautical cosplay.

### Tone by surface

| Surface | Tone |
|---------|------|
| Landing page | Confident, concise, architectural |
| Docs | Precise, direct, example-heavy |
| API references | Boring on purpose; exact names and failure modes |
| Error messages | Calm, specific, actionable |
| Release notes / changelog | Specific, task-first, no drama. Lead with what changed. State what broke. Separate "what's new" from "what's fixed" from "what's deprecated." Use present tense: "Adds Stone 600 primitive. Fixes text.muted AA contrast." |
| Community posts | OSS-friendly, curious, pragmatic |
| UI microcopy | Short, status-oriented, no drama |

### Write this way

- "This route requires a native screen in app runtime `>= 0.3.0`."
- "Cached read-only means the user can view stale data, not submit changes."
- "Use an offline island when the interaction loop must continue without the server."
- "The camera capability is requested at point of use."
- "The bridge message is semantic; progress events stay native."

### Do not write this way

- "Native mobile with no native work."
- "Everything works offline."
- "Just add Crosswake."
- "Magic bridge."
- "One codebase for every app."
- "Never write Swift or Kotlin again."

### Release announcement voice — ADD (audit §6)

Release notes are the primary trust signal for OSS adopters evaluating version upgrades. Use present tense. Lead with what changed. State what broke explicitly.

**Example release note:**

> `crosswake 0.2.0` — Token foundation and brand audit.
>
> Adds `brandbook/` with the design token system, WCAG contrast matrix, and 14-section brand audit. Pins Stone 600 as the corrected text.muted primitive. Flags generator palette drift (fix tracked as NORM-01). No breaking changes to route policy or bridge contracts.

### Voice rules summary

| Surface | Tone | Hard rule |
|---------|------|-----------|
| Landing hero | Confident, architectural | No unbacked "powerful/seamless/next-generation" |
| README | Direct, example-first | Show code before making claims |
| Docs | Precise, caveat-near-code | Failure modes before advanced usage |
| Error messages | Calm, specific, actionable | Name what happened, what to do next |
| Empty states | Honest, non-apologetic | No "coming soon" or "nothing here yet" |
| Success states | Brief, specific | Confirm the concrete action, not the vibe |
| Release notes | Task-first, changelog-first | Lead with what changed; state what broke |
| CTAs | Verb-first | "Read the guide" not "Get started instantly" |
| Package metadata | Factual, ≤ 160 chars | No hype words; every claim is verifiable |

---

## 7. Visual identity overview {#visual-identity}

### Visual concept

Crosswake should look like a **technical navigation system**, not a beach brand.

The visual language is:

- Deep current backgrounds.
- Warm foam surfaces.
- Kelp/sea-glass route lines.
- Brass signal accents.
- Diagonal wake seams.
- Structured route cards.
- Thin map/sounding lines.
- Explicit labels and badges.

### Visual keywords

- Current, Wake, Seam, Route, Channel, Manifest, Shell, Island, Signal, Boundary

### Visual anti-keywords

- Tropical, Splashy, Cyber-neon, Atom/orbit, Flame, Lightning bolt, Generic app gradient, Plug/socket, Cartoon boat, Surf brand

### Design token spec — token tiers (from audit §7)

**Architecture: Two tiers only.**

- **Primitive tokens** (`--cw-primitive-{family}-{weight}`): internal, never referenced in component CSS. Emit raw hex in `:root`.
- **Semantic tokens** (`--cw-{role}-{variant}`): public contract. Only semantic tokens cross the library boundary.

**No component tier** — deliberate anti-feature per D-06.

**Theming model:** `:root` holds light-mode values. System dark: `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }`. Explicit toggle: `[data-theme="dark"]`. Only the semantic tier flips in dark mode; primitives never change.

**Source of truth:** `brandbook/tokens/crosswake.tokens.json` (W3C DTCG 2025.10 format). Compiled `tokens.css` is generated — never edit directly.

### Dark-mode surface hierarchy — ADD (audit §8)

| Surface level | Dark value | Light value | Use |
|---------------|------------|-------------|-----|
| `surface.default` | `--cw-primitive-current-950` | `--cw-primitive-foam-50` | Page background |
| `surface.raised` | `--cw-primitive-current-900` | `--cw-primitive-foam-100` | Cards, code blocks |
| `surface.inset` | `--cw-primitive-current-800` | `--cw-primitive-white` | Inset panels, nested cards |
| `surface.inverse` | `--cw-primitive-foam-50` | `--cw-primitive-current-950` | CTA sections, callouts |

---

## 8. Color system {#color-system}

The Crosswake palette is coastal, muted, technical, and warm: deep current, kelp, foam, brass, and rust. It avoids React Native cyan, Hotwire red/orange, Phoenix purple/orange, and Capacitor/Ionic blue-purple.

### Core palette

| Token | Hex | Role |
|-------|-----|------|
| `--cw-current-950` | `#09141A` | Primary dark, logo ink, hero background |
| `--cw-current-900` | `#0F1E26` | Dark panels, code blocks |
| `--cw-current-800` | `#162B35` | Raised dark surfaces |
| `--cw-harbor-700` | `#254855` | Secondary dark accent, diagrams |
| `--cw-wake-700` | `#2B756A` | Primary action on light, links, route lines |
| `--cw-wake-500` | `#4E9A8E` | Accent on dark, hover, highlights |
| `--cw-kelp-800` | `#123B36` | Offline/success deep accent |
| `--cw-brass-500` | `#C98A2E` | Signal accent on dark, native-screen emphasis |
| `--cw-brass-700` | `#946017` | Warning text on light surfaces |
| `--cw-foam-50` | `#F7F1E6` | Main light background |
| `--cw-foam-100` | `#EFE6D6` | Warm panel/code-light surface |
| `--cw-mist-200` | `#C9D4CF` | Borders, muted text on dark |
| `--cw-stone-600` | `#756D63` | **NEW (D-02 remediation):** text.muted on light surfaces — 4.53:1 on Foam 50 PASS |
| `--cw-stone-500` | `#7C746A` | Narrow use: large text ≥24px, disabled, decorative only. Fails AA normal text (4.09:1). Never as body or UI muted text. |
| `--cw-rust-600` | `#9A4D35` | Danger, sensitive, destructive, policy risk |
| `--cw-plum-700` | `#372D4C` | Bridge/contract accent, rare supporting color |
| `--cw-white` | `#FFFFFF` | Text on dark/action surfaces |

### Stone 600 remediation — TIGHTEN (audit §8, D-02)

Stone 500 (`#7C746A`) on Foam 50 fails AA normal text at 4.09:1. The fix adds **Stone 600 `#756D63`** as the corrected `text.muted` primitive:

- Stone 600 on Foam 50: **4.53:1 PASS**
- Stone 600 on white: **5.09:1 PASS**
- `text.muted` → Stone 600 (normal-size secondary text on light surfaces)
- `text.subtle` → Stone 500 (large text ≥24px, disabled states, decorative only)

**Critical dark-mode rule:** `--cw-text-muted` on dark surfaces must resolve to `mist-200` (12.25:1 on Current 950 — PASS). Stone 600 on Current 950 is 3.66:1 — fails AA normal text and must never appear as muted text on a dark background.

### Semantic color mapping

| Semantic use | Preferred color |
|---|---|
| Primary CTA on light | Wake 700 with white text |
| Primary CTA on dark | Brass 500 with Current 950 text |
| Link on light | Wake 700 |
| Link on dark | Wake 500 or Brass 500 |
| LiveView runtime | Harbor 700 / Mist 200 |
| Offline island | Kelp 800 / Wake 500 |
| Native screen | Brass 500 / Current 950 |
| Sensitive or cache-never | Rust 600 / White |
| Bridge contract | Plum 700 / Foam 50 |
| Media pack | Tide/Harbor family, not cyan |
| Muted text on light | Stone 600 (not Stone 500) |
| Disabled text | Stone 500, large text ≥24px only, with accessible label |

### 12-State Mapping table — ADD (audit §7, D-09 TOKN-03)

| State | Strategy | Token(s) involved |
|-------|----------|-------------------|
| **default** | Semantic token default value | All base semantic tokens |
| **hover** | Dedicated semantic token | `--cw-action-hover` |
| **active** | CSS `:active` selector against semantic tokens | `--cw-action-bg`, `--cw-action-fg` — no new token |
| **focus** | 2px outline using dedicated focus-ring token | `--cw-action-focus-ring` |
| **disabled** | `opacity: 0.45` + accessible label; narrow color use | `--cw-text-subtle` for disabled text |
| **selected** | Action background + strong border | `--cw-action-bg` + `--cw-border-strong` — no new token |
| **success** | Dedicated status token | `--cw-status-success` |
| **warning** | Dedicated status token | `--cw-status-warning` |
| **error** | Dedicated status token | `--cw-status-error` |
| **info** | Dedicated status token | `--cw-status-info` |
| **subtle** | Text tier variant | `--cw-text-subtle` (large text ≥24px, decorative) |
| **muted** | Text tier variant | `--cw-text-muted` (normal-size secondary text) |

### Approved color pairings

| Foreground | Background | Ratio | AA | Intended use |
|---|---|---|---|---|
| Foam 50 | Current 950 | 16.58:1 | PASS | Hero text, dark docs shell |
| Current 950 | Foam 50 | 16.58:1 | PASS | Body text |
| White | Wake 700 | 5.45:1 | PASS | Primary buttons on light |
| Current 950 | Brass 500 | 6.35:1 | PASS | Primary buttons on dark |
| Wake 500 | Current 950 | 5.62:1 | PASS | Links/highlights on dark |
| Wake 700 | Foam 50 | 4.85:1 | PASS | Links on light |
| White | Rust 600 | 6.02:1 | PASS | Sensitive/danger badges |
| Foam 50 | Plum 700 | 11.38:1 | PASS | Bridge/contract badges |
| **Stone 600** | **Foam 50** | **4.53:1** | **PASS** | Muted text on light (corrected) |
| Stone 500 | Foam 50 | 4.09:1 | **FAIL** | — do not use for normal text — |

### Color usage rules

1. Use **Current 950** and **Foam 50** as the main brand contrast.
2. Use **Wake 700/500** for route motion, links, and active states.
3. Use **Brass 500** sparingly as a signal color. It should feel important.
4. Use **Rust 600** only for destructive, sensitive, or policy-risk states.
5. Do not use bright cyan as a hero accent.
6. Do not use hot red/orange gradients.
7. Do not use purple/orange flame gradients.
8. Do not rely on color alone; pair status colors with text labels and icons.
9. **Stone 600** is the corrected muted-text color for light surfaces. Do not use Stone 500 for normal-size body or UI muted text.

### CSS variables

```css
:root {
  --cw-current-950: #09141A;
  --cw-current-900: #0F1E26;
  --cw-current-800: #162B35;
  --cw-harbor-700: #254855;
  --cw-wake-700: #2B756A;
  --cw-wake-500: #4E9A8E;
  --cw-kelp-800: #123B36;
  --cw-brass-500: #C98A2E;
  --cw-brass-700: #946017;
  --cw-foam-50: #F7F1E6;
  --cw-foam-100: #EFE6D6;
  --cw-mist-200: #C9D4CF;
  --cw-stone-600: #756D63; /* NEW — D-02 remediation */
  --cw-stone-500: #7C746A; /* narrow use: large text, disabled, decorative only */
  --cw-rust-600: #9A4D35;
  --cw-plum-700: #372D4C;
  --cw-white: #FFFFFF;
}
```

See `brandbook/tokens/tokens.css` for the full semantic token layer with dark-mode overrides.

---

## 9. Typography {#typography}

### Primary display type

**Space Grotesk**

Use for: logo wordmark, landing-page hero headings, section headings, short callouts.

Recommended weights: 500 Medium (headings), 600 SemiBold (hero), 700 Bold (rare).

Style: tight tracking `-0.02em` for large headings. Avoid all-caps except tiny labels.

**D-11 MANDATORY RIDER:** The committed wordmark must NOT be typesettable in unmodified Space Grotesk. Custom wake-angle cuts on the `w` and `k` letterforms are required. This is non-optional and cascades to Phase 103.

### Primary body/UI type

**Atkinson Hyperlegible Next**

Use for: documentation body text, UI labels, component copy, long-form guides.

Recommended weights: 400 Regular (body), 500 Medium (UI labels), 600 SemiBold (cards and nav).

Rationale: Friendly, legible, less generic than Inter; clarity is a brand feature for OSS docs.

### Code type

**JetBrains Mono**

Use for: code blocks, inline code, CLI examples, version and manifest values.

Recommended weights: 400 Regular (code blocks), 500 Medium (inline code or emphasized tokens).

### Fallback stacks

```css
--cw-font-display: "Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--cw-font-body: "Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--cw-font-mono: "JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace;
```

### Type scale

| Token | Size | Line height | Use |
|-------|------|-------------|-----|
| `text-xs` | 12px | 16px | badges, metadata |
| `text-sm` | 14px | 20px | nav, labels, small docs |
| `text-md` | 16px | 24px | body |
| `text-lg` | 18px | 28px | lead body |
| `text-xl` | 20px | 30px | card headings |
| `display-sm` | 28px | 36px | docs page title |
| `display-md` | 40px | 48px | landing section title |
| `display-lg` | 56px | 64px | hero headline |

**Tracking:** `-0.02em` applies to `display-md` and `display-lg`.

### Conference slide guidance — ADD (audit §6, §9)

- Use `display-lg` (56px) for slide titles. Space Grotesk SemiBold.
- Use `display-sm` (28px) for slide body bullets. Atkinson Hyperlegible Next Regular.
- Use Current 950 dark background for technical/architecture slides; Foam 50 light background for code-heavy slides.
- Palette subset for slides: Current 950, Foam 50, Wake 700, Brass 500. Avoid all others.
- Wake Mark or a route-seam diagram as the slide header graphic. Never use it as a watermark behind text.
- Slides must pass WCAG AA at projector brightness — prefer Current 950 + Foam 50 or white text for maximum contrast.

---
