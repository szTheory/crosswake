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

## 10. Logo direction {#logo-direction}

### Logo concept

The Crosswake mark should suggest **a route crossing a runtime seam and leaving a clean wake**.

It should not look like an atom, a React logo, a Phoenix flame, a Hotwire wire/plug, a boat logo, a compass rose, a wave/surf company, or a generic X app icon.

### Wake Mark geometry — TIGHTEN (audit §8, §10)

| Parameter | Specification |
|-----------|---------------|
| Crossing angle | 20° from horizontal (canonical). Acceptable range: 16–24°. |
| Wake line count | Exactly 3 — the crossing line plus two trailing wake lines. |
| Stroke weight | 2.5px at 24px icon size. Scale proportionally. |
| Notch/break | 1.5× stroke width gap at the crossing point (explicit boundary seam). |
| Corner cap style | Round (not butt or square). |
| Minimum pixel rendering | Test at 16px. Simplify to 2 strokes at ≤16px. |
| SVG format | Path-only. No `<text>` elements. No rectangular clip-path backgrounds. No embedded fonts. |

### Wordmark specification

Starting font: Space Grotesk SemiBold (600). **Frozen (D-12).** The `w`/`k` wake-angle letter cuts echo the 20° crossing angle — this is a mandatory D-11 requirement. Candidates without cuts are disqualified.

### Lockups

1. **Horizontal lockup:** Wake Mark + Crosswake wordmark. Minimum 128px wide.
2. **Stacked lockup:** Wake Mark above wordmark. For social/README hero. Minimum 64px wide.
3. **Icon mark:** Wake Mark only. 24px minimum for UI; 32px minimum for README.
4. **Tiny/favicon mark:** Simplified 2-stroke wake, no small details. Legible at 16px.

### Logo colorways (ratified)

| Context | Mark | Wordmark | Background |
|---------|------|----------|------------|
| Light primary | Current 950 | Current 950 | Foam 50 or white |
| Dark primary | Foam 50 | Foam 50 | Current 950 |
| Signal | Brass 500 | Foam 50 | Current 950 |
| OSS badge | Wake 700 | Current 950 | Foam 50 |
| One-color | Current 950 or Foam 50 | Same | Any solid |

### Clearspace

- Horizontal lockup: minimum clearspace = x-height of the wordmark on all four sides.
- Icon mark: clearspace = one stroke width + one wake-gap on all sides.
- Never place the mark inside a bounding shape (circle, square, blob, gradient card).

### Minimum sizes (audit §8)

| Variant | Minimum |
|---------|---------|
| Horizontal lockup | 128px wide |
| Stacked lockup | 64px wide |
| Icon mark | 24px (UI), 32px (README) |
| Favicon | 16px (simplified 2-stroke) |

### Logo do/don't

**Do:**
- Use simple geometric strokes.
- Keep the mark readable in one color.
- Preserve the diagonal crossing at 20°.
- Use warm dark/light contrast.
- Use rounded stroke caps.

**Do not:**
- Add literal boats, anchors, ropes, waves, or water splashes.
- Add neon cyan glow.
- Use a flame shape.
- Put the mark inside a generic app-gradient blob.
- Make the mark an X without wake semantics.
- Use the wordmark set in unmodified Space Grotesk (D-11 violation).
- Place the wordmark over a photograph.

### Misuse examples (audit §8)

1. **Colorway swap to cyan** — rejected; contradicts React Native avoidance.
2. **Mark at <12px without simplification** — rejected; illegible.
3. **Wordmark set in unmodified Space Grotesk** — rejected; D-11 violation.
4. **Mark inside a drop-shadow card or rounded blob** — rejected; adds visual noise.
5. **Mark stretched or rotated off 20°** — rejected; the crossing angle is the brand geometry.

---

## 11. Graphic design elements {#graphic-elements}

### Primary motif: wake seams

Wake seams are diagonal or gently curved line groups that imply movement through a boundary.

Rules:
- Use 2–4 parallel lines.
- Stroke: 1.5px to 3px.
- Rounded caps.
- Use Wake 500/700, Mist 200, or Brass 500 depending on surface.
- Keep them sparse.

### Secondary motif: runtime lanes

Use horizontal or vertical lanes to show which runtime owns each route.

Lane labels: `LiveView` / `Offline Island` / `Native Screen` / `Adapter` / `Server Commit`

These diagrams should feel like technical maps, not marketing infographics.

### Tertiary motif: sounding lines

Thin contour-like lines in backgrounds. Rules:
- Opacity below 12%.
- Never behind dense text.
- Use in hero backgrounds, empty states, and open-source README graphics.

### Shape language

- Cards: rounded rectangles, 12–16px radius.
- Badges: pill or soft rectangle, 999px or 6px radius depending density.
- Diagrams: straight lines with rounded joins.
- App screenshots: placed in stable frames, not tilted wildly.

### Social preview card spec — ADD (audit §6)

| Property | Value |
|----------|-------|
| Size | 1200×630px |
| Background | Current 950 (`#09141A`) |
| Logo | Wake Mark in Foam 50 (centered or upper-left) |
| Wordmark | "Crosswake" in Space Grotesk SemiBold, Foam 50, 48px |
| One-liner | "Route policy for Phoenix apps that go mobile." Atkinson Hyperlegible Next Regular, Mist 200, 24px |
| Version badge | JetBrains Mono, Stone 500, 16px, lower-right corner (optional) |
| Path | `brandbook/social/og-card.svg` (Phase 106 deliverable) |

---

## 12. Iconography {#iconography}

### Icon style

- Stroke-based. 1.75px stroke at 24px icon size. Rounded caps and joins. No filled emoji-like icons. No multi-color icons by default.

### Core icons to design

| Concept | Icon direction |
|---------|----------------|
| Route Policy | Split route line with a labeled checkpoint |
| Runtime | Layered frame or lane |
| LiveView | Server dot connected to screen frame |
| Offline Island | Small island/rounded node detached from server line |
| Native Screen | Device frame with solid corner notch |
| Capability | Shield/checkpoint badge |
| Bridge Contract | Two brackets connected by one semantic arrow |
| Content Pack | Box/card stack |
| Media Pack | File stack with play/wave marker |
| Sync Journal | Ordered event ticks |
| Sensitive | Shield with slash or lock, never just red |
| Runtime Gate | Gate/checkpoint line |

### Icon rules

- Icons must still make sense without nautical context.
- Do not use anchors, ship wheels, or compass roses for core technical concepts.
- Do not use platform logos unless discussing platform-specific adapters.

---

## 13. Layout and UI system {#layout-ui-system}

### Layout principles

- Documentation quieter than marketing. Pages structured and navigable. Dense technical pages need breathing room. Every concept page shows a concrete route-policy snippet early.

### Grid

- 4px base grid. Docs content: 760–860px. Landing max: 1120–1200px. Code examples can break wider.

### Mobile breakpoints — ADD (audit §6, §13)

Mobile-first: design for 375px+ single-column as the base. Tap targets 44px minimum. Navigation collapses below `md`.

| Breakpoint | Value | Use |
|------------|-------|-----|
| `sm` | 640px | Single-column docs layout |
| `md` | 768px | Two-column doc start |
| `lg` | 1024px | Full sidebar visible |
| `xl` | 1200px | Landing page full width |

### Radius

| Token | Value | Use |
|-------|-------|-----|
| `radius-sm` | 6px | inline code, tiny badges |
| `radius-md` | 10px | buttons, inputs |
| `radius-lg` | 14px | cards |
| `radius-xl` | 20px | hero panels, major diagrams |

### Shadows

Prefer borders and layered surfaces over heavy shadows. Light card: `0 1px 2px rgba(9,20,26,0.06)` plus border. Dark card: border with `rgba(201,212,207,0.12)`, minimal shadow.

### Buttons

**Primary on light:** Wake 700 bg, White text, Hover: Current 950, Focus: Brass 500 outline 2px.  
**Primary on dark:** Brass 500 bg, Current 950 text, Hover: Foam 100, Focus: Wake 500 outline 2px.  
**Secondary:** Transparent or Foam 50, Border: Mist 200 or Harbor 700.

Button copy: "Read the guide" / "Install Crosswake" / "Generate a route policy" / "View examples" / "Open runtime manifest"

### Badges

Badge style: text labels, not just colors; monospace only for exact code values; muted backgrounds.

Examples: `runtime: live_view` / `offline: cached_read_only` / `capability: camera` / `cache: never` / `sensitive` / `requires_runtime >= 0.3.0`

### Code blocks

- Background: Current 900. Border: Current 800. Text: Foam 50. Comments: Mist 200. Keywords: Wake 500. Strings: Brass 500. Errors: Rust 600 with label.
- Include copy buttons with accessible labels.

---

## 14. Documentation brand system {#documentation-brand-system}

### Docs structure

1. **Start** — What Crosswake is, Install, First route policy, First native shell.
2. **Concepts** — Runtime ownership, Route policy, Capabilities, Bridge contracts, Offline islands, Content packs, Media packs, Sync journals, Runtime compatibility.
3. **Guides** — SaaS mobile shell, Offline study loop, Field inspection flow, Native audio player, Billing/paywall adapter.
4. **Reference** — `Crosswake.RoutePolicy`, `Crosswake.Capabilities`, `Crosswake.NativeScreens`, Manifest schema, Bridge payload schema, Mix tasks.
5. **Adapters** — iOS, Android, Billing, Media, Uploads, Maps.
6. **Security** — Origin policy, Route allowlists, Capability allowlists, Manifest signing, Sensitive routes, Cache policy.

### Documentation page template

Each concept page (in order): One-sentence definition → When to use → When not to use → Minimal code example → Failure modes → Security/caching notes → Testing fixtures → Related concepts.

Failure modes appear **before** advanced customization on every page.

### Warning box style

Warning boxes for boundary mistakes only, not tips.

> **Boundary warning**  
> `offline: :read_write` does not mean the server accepted the action. Use a sync journal and show pending state until the server reconciles the event.

### Docs typography

- Page title: `display-sm` (28px), Space Grotesk SemiBold.
- Section heading: `text-xl` (20px), Space Grotesk Medium.
- Body: `text-md` (16px), Atkinson Hyperlegible Next Regular.
- Code: `text-sm` (14px), JetBrains Mono Regular.
- Warning boxes: Atkinson Hyperlegible Next, Brass 700 on Foam 100 border-left strip.

### README badge specification — ADD (audit §5)

README header badge set: Hex version badge / Apache-2.0 license / GitHub Actions CI status / Brand-styled route/capability badges (muted background, text labels, monospace for code values).

---

## 15. Microcopy library {#microcopy-library}

### Runtime labels

LiveView route / Cached route / Offline island / Native screen / Adapter-backed screen / External browser route / Online-only route

### Status labels

Available offline / Cached read-only / Draft only / Requires connection / Requires native runtime / Waiting for sync / Pending server confirmation / Server confirmed / Capability unavailable / Permission needed / Runtime mismatch / Cache disabled / Sensitive route

### Error messages

| State | Copy |
|-------|------|
| Runtime mismatch | "This route requires native runtime `0.3.0` or newer. Update the app or choose another route." |
| Capability unavailable | "Camera capture is not available in this app runtime. The route policy requires `:camera`." |
| Offline commit blocked | "This action needs the server before it can be committed. The draft was saved locally." |
| Sensitive cache blocked | "This route is marked sensitive and will not be cached." |
| Bridge payload rejected | "Crosswake rejected this bridge message because it does not match the registered contract." |

### Empty states

| State | Copy |
|-------|------|
| No offline content | "Nothing has been packed for offline use yet. Sync this route before going offline." |
| No native screen registered | "The route policy points to a native screen, but the host app has not registered it." |
| No capabilities declared | "This route does not request native capabilities." |

### Success states

| State | Copy |
|-------|------|
| Sync confirmed | "Server confirmed. The local draft was committed successfully." |
| Route activated | "Route activated. Native runtime `0.3.1` detected and verified." |
| Pack ready | "Content pack `daily_study` is ready for offline use." |

### CTA copy

Install Crosswake / Read the route policy guide / Generate native screen stubs / Define a capability / Add an offline island / View the manifest / Run compatibility checks

---

## 16. Landing page direction {#landing-page-direction}

### Page architecture

1. **Hero** — Dark Current background, Wake Mark, headline "Phoenix routes, native where it matters," CTAs "Read the guide" + "View examples."
2. **The problem** — "Mobile screens do not all want the same runtime." Dashboard stays LiveView, study loop goes offline island, camera capture goes native, billing goes adapter.
3. **The solution** — Route policy code block + visual route card.
4. **Runtime ladder** — 7-tier: LiveView → LiveView+shell → bridge → cached → offline island → native screen → adapter.
5. **Capabilities and safety** — Capability registry, permission stories, cache-never, sensitive routes.
6. **Examples** — SaaS portal, field inspection, flashcard/audio study app, native audio player, billing/paywall.
7. **OSS trust** — GitHub link, Hex.pm link, security policy link, maintainer note. Non-commercial tone.
8. **Install block** — Short command + first route policy snippet.

### Landing page visual style

- Dark hero, light docs sections.
- Route cards as product screenshots.
- Diagrams over device mockups.
- Brass accent for "native screen" moments.
- Kelp/wake accent for "offline island" moments.
- No hero device mockup showing a generic mobile app screen.

---

## 17. Acceptable imagery {#acceptable-imagery}

### Use

- Abstract route maps, bathymetric/topographic line patterns, technical diagrams, clean mobile UI screenshots in realistic frames, code and route-policy snippets, system diagrams with lanes and gates.

### Avoid

- Stock photos of people smiling at phones, literal boats, tropical beaches/waves/surfers, neon cyberpunk water, React atom/orbit imagery, Hotwire red heat/wire graphics, Phoenix flame motifs, generic blue-purple SaaS gradients, overly cute mascots.

### Illustration style

- Sparse, geometric, diagrammatic. 1–3 colors per illustration. Use labels. Prefer route/channel metaphors to literal sea objects.

---
