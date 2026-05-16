# Crosswake Brand Identity Guide

Version: 0.1 draft  
Use case: open-source Elixir/Phoenix library identity, documentation, landing pages, UI/UX components, logo direction, microcopy, and future LLM context.

---

## 1. Brand summary

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
- Not “write once, run anywhere.”
- Not “offline magically works.”

**What Crosswake is:**

- A route policy system.
- A mobile runtime manifest.
- A native-shell and bridge contract layer.
- A capability registry.
- An offline/content/media pack substrate.
- A disciplined escape hatch into native screens.

---

## 2. Brand essence

### Essence

**Boundary-aware mobility.**

Crosswake should feel like a stable channel through rough technical water: calm, precise, durable, and honest about what owns what.

### Personality

- **Calm:** no hype, no panic, no “magic.”
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

---

## 3. Competitive and conflict guardrails

Crosswake sits near several established ideas but should not visually or verbally imitate them.

### Avoid confusing Crosswake with React Native

React Native’s common promise is React-to-native development. Crosswake should not claim “learn once, write anywhere,” should not use React atom/orbit imagery, and should not use bright cyan-on-dark as its primary identity.

**Avoid:** atom marks, orbital rings, neon cyan hero art, “native components from one UI language,” “write once.”

**Use instead:** route policy, runtime boundaries, manifest, capability gates, server/native/local ownership.

### Avoid confusing Crosswake with Hotwire Native

Hotwire Native is web-first and wraps server-rendered web content in a native shell. Crosswake can learn from route/path configuration and bridge patterns, but the brand must not look like Hotwire, speak like Hotwire, or claim the same conceptual center.

**Avoid:** red/orange heat language, “HTML over the wire” phrasing, “web content is all the app,” wire/plug graphics.

**Use instead:** crossing, wake, seam, route policy, capability registry, offline/media/native-screen ownership.

### Avoid confusing Crosswake with LiveView Native

LiveView Native is about using Phoenix LiveView to build native applications and serve web/non-web clients. Crosswake should not present itself as “LiveView renders native UI.”

**Avoid:** “Native LiveView,” “render native UI from LiveView,” Phoenix flame-like marks, purple/orange flame emphasis.

**Use instead:** Phoenix-native mobile deployment substrate; route-by-route runtime selection.

### Avoid confusing Crosswake with Capacitor/Ionic

Capacitor is a native runtime for web apps with native API plugins. Crosswake should not be plugin-sprawl-first or JavaScript runtime-first.

**Avoid:** “native runtime for web apps,” plugin marketplace language, electric blue/purple app-platform gradients.

**Use instead:** Phoenix route policy, typed contracts, explicit capabilities, telemetry, and host-owned native screens.

### Avoid Crosswalk confusion

“Crosswake” is visually close to the old Crosswalk WebView project. Crosswake should never call itself a WebView runtime, Crosswalk successor, or Chromium runtime.

**Avoid:** “Crosswalk,” “WebView engine,” “Chromium runtime,” browser-engine messaging.

---

## 4. Naming system

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

## 5. Taglines and messaging

### Primary tagline

> Declare the crossing.

### Secondary taglines

- Keep every mobile route honest.
- Phoenix routes, native where it matters.
- Server where it sings. Native where it must. Offline where it matters.
- A route policy layer for Phoenix apps on mobile.
- Cross the web/native seam without hiding it.

### Homepage hero options

**Option A**

> Phoenix routes, native where it matters.
>
> Crosswake gives Phoenix apps a mobile route policy: LiveView for server-centric flows, offline islands for local work, and native screens for device-heavy moments.

**Option B**

> Declare the crossing.
>
> Crosswake lets Phoenix teams choose the right runtime per route—LiveView, offline island, native screen, or adapter—without blurring the boundary.

**Option C**

> Mobile apps without pretending every screen is the same screen.
>
> Crosswake turns route policy, native capabilities, offline packs, bridge contracts, and runtime compatibility into explicit Phoenix-native primitives.

### Three-bullet value proposition

- **Route-owned runtime policy:** declare whether each screen is LiveView, offline, native, or adapter-backed.
- **Typed native boundaries:** version bridge messages, capability requirements, native screens, and app-binary compatibility.
- **Local-first where it belongs:** use offline islands, content packs, media packs, and event journals without making unsafe server actions look offline.

---

## 6. Voice and tone

### Voice principles

**Write like a careful maintainer.**  
Precise, short, helpful, and candid.

**Explain the boundary.**  
Crosswake exists to make runtime ownership explicit. The docs should repeatedly clarify what runs on the server, in the shell, in the WebView, in local JS, and in native code.

**Prefer operational truth over hype.**  
Say what happens, where it happens, and what can fail.

**Use metaphor sparingly.**  
“Wake,” “crossing,” “seam,” “channel,” and “island” are allowed, but technical documentation should not become nautical cosplay.

### Tone by surface

| Surface | Tone |
|---|---|
| Landing page | Confident, concise, architectural |
| Docs | Precise, direct, example-heavy |
| API references | Boring on purpose; exact names and failure modes |
| Error messages | Calm, specific, actionable |
| Release notes | Transparent, changelog-first |
| Community posts | OSS-friendly, curious, pragmatic |
| UI microcopy | Short, status-oriented, no drama |

### Write this way

- “This route requires a native screen in app runtime `>= 0.3.0`.”
- “Cached read-only means the user can view stale data, not submit changes.”
- “Use an offline island when the interaction loop must continue without the server.”
- “The camera capability is requested at point of use.”
- “The bridge message is semantic; progress events stay native.”

### Do not write this way

- “Native mobile with no native work.”
- “Everything works offline.”
- “Just add Crosswake.”
- “Magic bridge.”
- “One codebase for every app.”
- “Never write Swift or Kotlin again.”

---

## 7. Visual identity overview

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

- Current
- Wake
- Seam
- Route
- Channel
- Manifest
- Shell
- Island
- Signal
- Boundary

### Visual anti-keywords

- Tropical
- Splashy
- Cyber-neon
- Atom/orbit
- Flame
- Lightning bolt
- Generic app gradient
- Plug/socket
- Cartoon boat
- Surf brand

---

## 8. Color system

The Crosswake palette should be recognizably different from React Native cyan, Hotwire red/orange, Phoenix purple/orange flame energy, and Capacitor/Ionic electric blue/purple.

The palette is coastal, muted, technical, and warm: deep current, kelp, foam, brass, and rust.

### Core palette

| Token | Hex | Role |
|---|---:|---|
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
| `--cw-stone-500` | `#7C746A` | Neutral/muted text on light |
| `--cw-rust-600` | `#9A4D35` | Danger, sensitive, destructive, policy risk |
| `--cw-plum-700` | `#372D4C` | Bridge/contract accent, rare supporting color |
| `--cw-white` | `#FFFFFF` | Text on dark/action surfaces |

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
| Disabled | Stone 500 with low-contrast border, never as the only state cue |

### Approved color pairings

Use these pairings for readable UI:

| Foreground | Background | Intended use |
|---|---|---|
| Foam 50 | Current 950 | Hero text, dark docs shell |
| Current 950 | Foam 50 | Body text |
| White | Wake 700 | Primary buttons on light |
| Current 950 | Brass 500 | Primary buttons on dark |
| Wake 500 | Current 950 | Links/highlights on dark |
| Wake 700 | Foam 50 | Links on light |
| White | Rust 600 | Sensitive/danger badges |
| Foam 50 | Plum 700 | Bridge/contract badges |

### Color usage rules

1. Use **Current 950** and **Foam 50** as the main brand contrast.
2. Use **Wake 700/500** for route motion, links, and active states.
3. Use **Brass 500** sparingly as a signal color. It should feel important.
4. Use **Rust 600** only for destructive, sensitive, or policy-risk states.
5. Do not use bright cyan as a hero accent.
6. Do not use hot red/orange gradients.
7. Do not use purple/orange flame gradients.
8. Do not rely on color alone; pair status colors with text labels and icons.

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
  --cw-stone-500: #7C746A;
  --cw-rust-600: #9A4D35;
  --cw-plum-700: #372D4C;
  --cw-white: #FFFFFF;
}
```

---

## 9. Typography

### Primary display type

**Space Grotesk**

Use for:

- Logo wordmark exploration.
- Landing-page hero headings.
- Section headings.
- Short callouts.

Recommended weights:

- 500 Medium for headings.
- 600 SemiBold for hero.
- 700 Bold rarely.

Style:

- Tight but readable tracking: `-0.02em` for large headings.
- Avoid all-caps except tiny labels.
- Do not overuse; it should give character, not dominate docs.

### Primary body/UI type

**Atkinson Hyperlegible Next**

Use for:

- Documentation body text.
- UI labels.
- Component copy.
- Long-form guides.

Recommended weights:

- 400 Regular for body.
- 500 Medium for UI labels.
- 600 SemiBold for cards and nav.

Rationale:

- Friendly, legible, and less generic than Inter.
- Good for OSS docs where clarity is a brand feature.

### Code type

**JetBrains Mono**

Use for:

- Code blocks.
- Inline code.
- CLI examples.
- Version and manifest values.

Recommended weights:

- 400 Regular for code blocks.
- 500 Medium for inline code or emphasized tokens.

### Fallback stacks

```css
--cw-font-display: "Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--cw-font-body: "Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--cw-font-mono: "JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace;
```

### Type scale

| Token | Size | Line height | Use |
|---|---:|---:|---|
| `text-xs` | 12px | 16px | badges, metadata |
| `text-sm` | 14px | 20px | nav, labels, small docs |
| `text-md` | 16px | 24px | body |
| `text-lg` | 18px | 28px | lead body |
| `text-xl` | 20px | 30px | card headings |
| `display-sm` | 28px | 36px | docs page title |
| `display-md` | 40px | 48px | landing section title |
| `display-lg` | 56px | 64px | hero headline |

---

## 10. Logo direction

### Logo concept

The Crosswake mark should suggest **a route crossing a runtime seam and leaving a clean wake**.

It should not look like:

- An atom.
- A React logo.
- A Phoenix flame.
- A Hotwire wire/plug.
- A boat logo.
- A compass rose.
- A wave/surf company.
- A generic X app icon.

### Recommended mark structure

**The Wake Mark:**

- A diagonal route line crossing from lower-left to upper-right.
- Two or three offset wake lines trailing behind it.
- A small break/notch where the crossing happens, implying an explicit boundary.
- Rounded stroke caps.
- Geometry based on 16-degree or 24-degree angles.
- Works in one color at 16px.

### Wordmark

- Text: `Crosswake` or `crosswake`.
- Primary recommendation for OSS/dev docs: **Crosswake**.
- Secondary option for package/docs masthead: **crosswake**.
- Use Space Grotesk SemiBold as the starting point.
- Consider custom cuts on the `w` or `k` to echo the wake angle.

### Lockups

1. **Horizontal lockup:** Wake Mark + Crosswake wordmark.
2. **Stacked lockup:** Wake Mark above wordmark for social/README hero.
3. **Icon mark:** Wake Mark only.
4. **Tiny mark:** simplified two-stroke wake, no small details.

### Logo colorways

| Context | Mark | Wordmark | Background |
|---|---|---|---|
| Light primary | Current 950 | Current 950 | Foam 50 or white |
| Dark primary | Foam 50 | Foam 50 | Current 950 |
| Signal | Brass 500 | Foam 50 | Current 950 |
| OSS badge | Wake 700 | Current 950 | Foam 50 |
| One-color | Current 950 or Foam 50 | Same | Any solid |

### Clear space

- Minimum clear space: height of the lowercase `x` in the wordmark on all sides.
- For icon-only mark: clear space equals one stroke width plus one wake gap.

### Minimum sizes

- Full horizontal lockup: 128px wide minimum.
- Icon mark: 24px minimum for UI.
- Favicon: simplified mark at 16px.

### Logo do/don’t

Do:

- Use simple geometric strokes.
- Keep the mark readable in one color.
- Preserve the diagonal crossing.
- Use warm dark/light contrast.

Do not:

- Add literal boats, anchors, ropes, waves, or water splashes.
- Add neon cyan glow.
- Use a flame shape.
- Put the mark inside a generic app-gradient blob.
- Make the mark an X without wake semantics.

---

## 11. Graphic design elements

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

Example lane labels:

- `LiveView`
- `Offline Island`
- `Native Screen`
- `Adapter`
- `Server Commit`

These diagrams should feel like technical maps, not marketing infographics.

### Tertiary motif: sounding lines

Thin contour-like lines can appear in backgrounds. They should suggest depth and navigation without being literal maps.

Rules:

- Opacity below 12%.
- Never behind dense text.
- Use in hero backgrounds, empty states, and open-source README graphics.

### Shape language

- Cards: rounded rectangles, 12–16px radius.
- Badges: pill or soft rectangle, 999px or 6px radius depending density.
- Diagrams: straight lines with rounded joins.
- App screenshots: placed in stable frames, not tilted wildly.

### Texture

Use subtle grain only in large marketing backgrounds. Never use grain in docs code blocks or UI components.

---

## 12. Iconography

### Icon style

- Stroke-based.
- 1.75px stroke at 24px icon size.
- Rounded caps and joins.
- No filled emoji-like icons.
- No multi-color icons by default.

### Core icons to design

| Concept | Icon direction |
|---|---|
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

## 13. Layout and UI system

### Layout principles

- Documentation should be quieter than marketing.
- Pages should feel structured and navigable.
- Dense technical pages need breathing room.
- Every concept page should show a concrete route-policy snippet early.

### Grid

- Use a 4px base grid.
- Main docs content width: 760–860px.
- Landing page max width: 1120–1200px.
- Code examples can break wider when necessary.

### Radius

| Token | Value | Use |
|---|---:|---|
| `radius-sm` | 6px | inline code, tiny badges |
| `radius-md` | 10px | buttons, inputs |
| `radius-lg` | 14px | cards |
| `radius-xl` | 20px | hero panels, major diagrams |

### Shadows

Crosswake should prefer borders and layered surfaces over heavy shadows.

- Light card: `0 1px 2px rgba(9,20,26,0.06)` plus border.
- Dark card: border with `rgba(201,212,207,0.12)`, minimal shadow.
- Avoid floating SaaS-card clichés.

### Buttons

Primary on light:

- Background: Wake 700.
- Text: White.
- Hover: Current 950.
- Focus: Brass 500 outline, 2px.

Primary on dark:

- Background: Brass 500.
- Text: Current 950.
- Hover: Foam 100.
- Focus: Wake 500 outline, 2px.

Secondary:

- Transparent or Foam 50 surface.
- Border: Mist 200 or Harbor 700.
- Text: Current 950 or Foam 50 depending background.

Button copy:

- “Read the guide”
- “Install Crosswake”
- “Generate a route policy”
- “View examples”
- “Open runtime manifest”

Avoid:

- “Get started instantly”
- “Ship magically”
- “Build native with no native code”

### Badges

Badges are central to Crosswake UI because the product is about explicit route state.

Badge examples:

- `runtime: live_view`
- `runtime: native_screen`
- `offline: cached_read_only`
- `capability: camera`
- `cache: never`
- `sensitive`
- `requires_runtime >= 0.3.0`

Badge style:

- Use text labels, not just colors.
- Use monospace only for exact code values.
- Use muted backgrounds; let labels do the work.

### Cards

Core card types:

1. **Route Card**  
   Shows route, runtime, offline policy, capabilities.

2. **Capability Card**  
   Shows platform support, permission story, fallback, failure modes.

3. **Runtime Card**  
   Shows ownership, examples, footguns.

4. **Adapter Card**  
   Shows package, native requirements, host-owned implementation.

### Code blocks

Preferred dark code block:

- Background: Current 900.
- Border: Current 800.
- Text: Foam 50.
- Comments: Mist 200.
- Atoms/keywords: Wake 500.
- Strings: Brass 500.
- Errors/warnings: Rust 600 with label.

Code blocks should include copy buttons with accessible labels.

---

## 14. Documentation brand system

### Docs structure

Recommended top-level docs IA:

1. **Start**
   - What Crosswake is
   - Install
   - First route policy
   - First native shell

2. **Concepts**
   - Runtime ownership
   - Route policy
   - Capabilities
   - Bridge contracts
   - Offline islands
   - Content packs
   - Media packs
   - Sync journals
   - Runtime compatibility

3. **Guides**
   - SaaS mobile shell
   - Offline study loop
   - Field inspection flow
   - Native audio player
   - Billing/paywall adapter

4. **Reference**
   - `Crosswake.RoutePolicy`
   - `Crosswake.Capabilities`
   - `Crosswake.NativeScreens`
   - Manifest schema
   - Bridge payload schema
   - Mix tasks

5. **Adapters**
   - iOS
   - Android
   - Billing
   - Media
   - Uploads
   - Maps

6. **Security**
   - Origin policy
   - Route allowlists
   - Capability allowlists
   - Manifest signing
   - Sensitive routes
   - Cache policy

### Documentation page template

Each concept page should include:

1. One-sentence definition.
2. When to use it.
3. When not to use it.
4. Minimal code example.
5. Failure modes.
6. Security/caching notes.
7. Testing fixtures.
8. Related concepts.

### Warning box style

Use warning boxes for boundary mistakes, not generic “tips.”

Example:

> **Boundary warning**  
> `offline: :read_write` does not mean the server accepted the action. Use a sync journal and show pending state until the server reconciles the event.

### Docs copy rules

- Start with the concrete route example when possible.
- Put caveats near the code that triggers them.
- Prefer “server-authoritative” over “secure.”
- Prefer “host-owned native screen” over “generated native feature.”
- Explain failure modes before advanced customization.

---

## 15. Microcopy library

### Runtime labels

- LiveView route
- Cached route
- Offline island
- Native screen
- Adapter-backed screen
- External browser route
- Online-only route

### Status labels

- Available offline
- Cached read-only
- Draft only
- Requires connection
- Requires native runtime
- Waiting for sync
- Pending server confirmation
- Server confirmed
- Capability unavailable
- Permission needed
- Runtime mismatch
- Cache disabled
- Sensitive route

### Error messages

**Runtime mismatch**

> This route requires native runtime `0.3.0` or newer. Update the app or choose another route.

**Capability unavailable**

> Camera capture is not available in this app runtime. The route policy requires `:camera`.

**Offline commit blocked**

> This action needs the server before it can be committed. The draft was saved locally.

**Sensitive cache blocked**

> This route is marked sensitive and will not be cached.

**Bridge payload rejected**

> Crosswake rejected this bridge message because it does not match the registered contract.

### Empty states

**No offline content**

> Nothing has been packed for offline use yet. Sync this route before going offline.

**No native screen registered**

> The route policy points to a native screen, but the host app has not registered it.

**No capabilities declared**

> This route does not request native capabilities.

### CTA copy

- Install Crosswake
- Read the route policy guide
- Generate native screen stubs
- Define a capability
- Add an offline island
- View the manifest
- Run compatibility checks

---

## 16. Landing page direction

### Page architecture

1. **Hero**
   - Dark Current background.
   - Wake Mark or route seam graphic.
   - Headline: “Phoenix routes, native where it matters.”
   - Subhead explaining route-by-route runtime ownership.
   - CTAs: “Read the guide” and “View examples.”

2. **The problem**
   - “Mobile screens do not all want the same runtime.”
   - Show examples: dashboard, study loop, audio player, camera capture, billing.

3. **The route policy solution**
   - Show `route "/study/session"` code snippet.
   - Visual route card beside it.

4. **Runtime ladder**
   - LiveView → LiveView + shell → bridge → cached route → offline island → native screen → adapter.

5. **Capabilities and safety**
   - Capability registry, permission stories, cache-never, sensitive routes.

6. **Examples**
   - SaaS portal.
   - Field inspection.
   - Flashcard/audio study app.
   - Native audio player.
   - Billing/paywall.

7. **OSS trust section**
   - Small, non-commercial tone.
   - Link to GitHub, Hex, docs, security policy.

8. **Install block**
   - Short command.
   - First policy snippet.

### Landing page visual style

- Dark hero, light docs sections.
- Use route cards as product screenshots.
- Use diagrams over device mockups.
- Device mockups can appear, but only to show boundary decisions, not generic app glamour.
- Use brass accent for “native screen” moments.
- Use kelp/wake accent for “offline island” moments.

---

## 17. Acceptable imagery

### Use

- Abstract route maps.
- Bathymetric/topographic line patterns.
- Technical diagrams of runtime boundaries.
- Clean mobile UI screenshots in realistic frames.
- Subtle coastal/harbor textures if abstracted.
- Code and route-policy snippets.
- System diagrams with lanes and gates.
- Close-up device edges, not lifestyle stock as the main identity.

### Avoid

- Stock photos of people smiling at phones.
- Literal boats as the main visual.
- Tropical beaches, waves, surfers.
- Neon cyberpunk water.
- React-like atom/orbit imagery.
- Hotwire-like red heat/wire graphics.
- Phoenix flame motifs.
- Generic blue-purple SaaS gradients.
- Overly cute mascots.

### Illustration style

- Sparse, geometric, diagrammatic.
- 1–3 colors per illustration.
- Use labels.
- Prefer route/channel metaphors to literal sea objects.

---

## 18. Motion and interaction

### Motion principle

Motion should feel like a clean crossing: directional, controlled, and useful.

### Approved motion

- Panels crossing a seam horizontally or diagonally.
- Route line drawing from server to native/offline lane.
- Badges resolving from “pending” to “server confirmed.”
- Subtle wake-line reveal in hero.

### Motion timing

- Microinteractions: 120–160ms.
- Panel transitions: 180–240ms.
- Hero/diagram animation: 600–900ms, once, non-essential.

### Reduced motion

- Always provide reduced-motion behavior.
- Replace line-draw animations with simple fades or static diagrams.
- Do not use looping wave motion behind documentation text.

---

## 19. UI component examples

### Route card

```txt
/study/session
runtime: offline_island
content_pack: daily_study
media_pack: card_media
capabilities: audio, haptics
sync: study_reviews
```

Design:

- Top-left route path in JetBrains Mono.
- Runtime badge under route.
- Capability chips in muted row.
- Small “Boundary warning” line if sensitive/offline/server-authoritative.

### Runtime ladder component

Seven horizontal rows:

1. LiveView
2. LiveView + native shell
3. Bridge component
4. Cached route
5. Offline island
6. Native screen
7. Native SDK adapter

Use muted rows with one active highlight. Avoid rainbow gradients.

### Capability matrix

Columns:

- Capability
- iOS
- Android
- Permission story
- Web fallback
- Failure mode
- Telemetry

Use check labels, not just check icons.

### Manifest viewer

A docs component showing:

- App runtime version.
- Supported native screens.
- Supported bridge protocol.
- Route policy hash.
- Manifest signature status.

This can become a signature visual component for Crosswake.

---

## 20. API naming tone

The API should sound declarative and policy-oriented.

Preferred:

```elixir
use Crosswake.RoutePolicy
use Crosswake.Capabilities
use Crosswake.NativeScreens

route "/study/session",
  runtime: {:offline_island, "study.session"},
  content_pack: :daily_study,
  media_pack: :card_media,
  sync: :study_reviews,
  capabilities: [:audio, :haptics]
```

Avoid API names that sound too magical:

```elixir
mobile_magic "/study/session"
auto_native "/audio/player"
offline_everything true
```

---

## 21. Accessibility standards

Crosswake’s brand should be accessible by default because the product is about explicit control and responsible mobile UX.

### Required

- Normal text should meet at least WCAG AA contrast.
- Important UI boundaries should not rely on color alone.
- Touch targets should be at least 24px by 24px, with larger preferred targets for mobile UI.
- Focus rings must be visible in both light and dark modes.
- Reduced-motion mode must preserve meaning.
- Code snippets must be readable without syntax colors.

### Recommended

- Prefer 16px body text minimum.
- Prefer 44px high mobile buttons when designing app UI.
- Do not place thin wake lines behind text.
- Include labels in runtime diagrams.

---

## 22. Community and OSS identity

Crosswake is non-commercial OSS. The identity should feel credible and durable, not venture-backed or salesy.

### OSS voice

- Credit inspirations without imitating them.
- Acknowledge tradeoffs.
- Write migration notes and failure cases.
- Prefer public roadmap language over feature hype.
- Keep docs useful even before the library is mature.

### README tone

The README should start with a concrete explanation and a code snippet, not a big claim.

Suggested README opening:

> Crosswake is a Phoenix-native mobile substrate for route-level runtime policy. It helps a Phoenix app decide which screens stay LiveView, which screens become offline islands, and which screens hand off to host-owned native views.

Then show a route-policy snippet.

---

## 23. Brand do/don’t summary

### Do

- Use “route policy” as the mental model.
- Show runtime choices side by side.
- Make security, cache, and native capability boundaries visible.
- Use dark current, warm foam, kelp, and brass.
- Use Space Grotesk, Atkinson Hyperlegible Next, and JetBrains Mono.
- Use diagrams, cards, and code as primary visuals.
- Keep copy candid and maintainable.

### Don’t

- Claim Crosswake replaces native development.
- Claim all apps can be one runtime.
- Use bright cyan atom visuals.
- Use red/orange hot-wire visuals.
- Use Phoenix flame-style marks.
- Hide platform caveats.
- Treat offline state as server confirmation.
- Turn every bridge message into high-frequency UI state.

---

## 24. LLM context block

Use this block when asking an LLM to generate Crosswake docs, landing pages, UI copy, component designs, or brand assets.

```md
You are creating material for Crosswake, an open-source Elixir/Phoenix library.

Crosswake is a Phoenix-native mobile substrate for declaring which runtime owns each mobile route: LiveView, offline island, native screen, or adapter. The brand is calm, explicit, technical, OSS-first, and boundary-aware. Crosswake must not be framed as React Native, Flutter, Capacitor, Hotwire Native, LiveView Native, or a generic WebView wrapper. It is not “write once, run anywhere” and not “native with no native code.”

Core promise: Declare the crossing. Keep the boundary honest.

Visual identity:
- Deep Current #09141A
- Current #0F1E26
- Wake Green #2B756A
- Wake Teal #4E9A8E
- Kelp #123B36
- Brass #C98A2E
- Brass Dark #946017
- Foam #F7F1E6
- Foam Deep #EFE6D6
- Mist #C9D4CF
- Rust #9A4D35
- Plum #372D4C

Typography:
- Space Grotesk for display/headings/logo exploration.
- Atkinson Hyperlegible Next for body/UI/docs.
- JetBrains Mono for code.

Visual motifs:
- Wake seams, route lines, runtime lanes, manifest cards, capability badges.
- Avoid atom/orbit logos, flames, hot red/orange wire motifs, neon cyan, generic blue-purple SaaS gradients, literal boat imagery, beach/surf imagery.

Voice:
- Write like a careful maintainer.
- Be precise and candid.
- Explain what runs where.
- Prefer operational truth over hype.
- Mention failure modes, compatibility, cache policy, permissions, and server authority.

Preferred phrases:
- Route policy for Phoenix apps that go mobile.
- Phoenix routes, native where it matters.
- Server where it sings. Native where it must. Offline where it matters.
- This route is cached read-only.
- This action needs the server before it can be committed.
- The host app owns this native screen.

Avoid phrases:
- Magic bridge.
- Just works offline.
- Write once, run anywhere.
- Never write native code again.
- Native mobile with no native work.
- One runtime for every screen.
```

---

## 25. First implementation checklist

For a designer/developer starting from this guide:

1. Design the Wake Mark in one color first.
2. Build light and dark logo lockups.
3. Create a small palette sheet with Current/Foam/Wake/Brass/Rust.
4. Build a docs homepage using the dark hero + route-policy code block.
5. Create route cards, runtime badges, and capability chips.
6. Create one flagship diagram: route policy chooses LiveView, offline island, native screen.
7. Write README opening with the one-liner and API snippet.
8. Check color contrast and focus rings before polishing visuals.
9. Avoid competitor-adjacent colors and metaphors during every review.
10. Keep the first release visually quiet, technical, and trustworthy.
```
