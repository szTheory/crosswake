# Crosswake Brand System Audit

**Audited:** 2026-06-11
**Subject:** `prompts/crosswake-brand-book.md`
**Auditor posture:** Senior brand systems director / design-token architect / OSS maintainer

---

## §1 Executive Judgment

**Verdict: Strong enough to build from. Distinctive enough to defend. Not yet implementation-ready — but close.**

The Crosswake brand book has a genuine conceptual center: explicit runtime boundaries expressed through a coastal, technical, muted palette and an architectural visual language. This is not a commodity devtools brand. The wake-seam metaphor is coherent, the palette avoids every adjacent competitor pitfall (React Native cyan, Phoenix purple/orange, Hotwire red, Capacitor blue-purple), and the voice is honest and maintainer-shaped. These are not small achievements.

**Is it strong enough to build from?** Yes. The palette is specified to hex precision, the typography stack is named with weights and fallbacks, the logo direction is concrete, and the voice guidance is specific enough to produce real copy. The gaps (missing iconography detail, under-specified dark mode for non-hero surfaces, absent motion-reduced alternatives beyond a single note) are real but bounded — they do not undermine the foundation.

**Is it distinct enough?** Yes, with one important caveat: Space Grotesk has become a "LLM-default design" choice in 2026, which risks making Crosswake visually generic in the wider devtools space. The brand book is aware of this and the mitigation is already specified: custom `w`/`k` wake-angle letterform cuts are the mandatory conversion from generic starting material to proprietary endpoint. Without those cuts, distinctiveness is at risk. With them, the wordmark becomes irreducibly Crosswake. This is the single highest-leverage improvement.

**Is it implementation-ready?** Partially. Colors and typography are ready. Tokens are not yet structured (addressed in §7). Logo exists only as direction, not as committed SVG (Phase 103). Several surface treatments are under-specified (see §4, §5). The audit and token work this phase completes the foundation for Phase 103 to execute against.

**What must NOT change (D-12 frozen items):**
- Display font family (Space Grotesk — frozen even if Space Grotesk's market saturation worsens; the letter cuts are the differentiator, not a font swap)
- Coastal-muted palette character (Current/Foam/Wake/Brass/Rust families — color math may add Stone 600, but the emotional register stays)
- Wake-seam visual concept (diagonal crossing lines implying runtime boundary traversal)
- Diagonal crossing-mark direction (the Wake Mark geometry is non-negotiable)

**Overall posture:** Preserve what is already strong. The brand has a soul; the work is finishing the implementation infrastructure around it.

## §2 Brand DNA Extraction

### Essence

**Boundary-aware mobility.** Crosswake is the clean trail left by a Phoenix app crossing into mobile runtimes without pretending the boundary disappeared. Every element of the brand should communicate: explicit, honest, durable, technically controlled.

### Audience

Primary: Phoenix/LiveView engineers who need mobile delivery and refuse to pretend all screens are the same runtime. They know Elixir. They care about correctness. They distrust hype. They will read the source.

Secondary: OSS maintainers and technical teams evaluating whether to stake production mobile strategy on a single framework or keep boundaries explicit.

Not: beginners expecting magic, teams seeking a React Native replacement, or anyone whose pitch is "write once, run anywhere."

### Emotional Tone

Calm confidence. Like a well-designed nautical chart: everything in its place, no drama, but the information is precise and the stakes are real. Not cold — warm (the foam palette earns this). Not playful — technical but not terse.

### Technical Promise

Per-route runtime ownership with honest failure modes. The system tells you exactly what runs where, what can fail, and what you own vs. what Crosswake owns.

### Visual Metaphor

**The wake.** The clean trail behind a vessel that has crossed a boundary. Not the crossing itself — the traceable evidence of it. Route lines, wake seams, runtime lanes. The diagram is the product.

### Personality Traits

- Explicit — everything is named: routes, runtimes, capabilities, policies
- Calm — no hype, no "magic," no surprise
- Technical — designed for engineers who read the source code
- Honest — failure modes are documented before features
- OSS-generous — the maintainer shares judgment, not just syntax
- Precise — measurements, contracts, verdicts

### Anti-Traits

- Salesy — no "powerful," "seamless," "next-generation"
- Evasive — no hiding that native development still requires native work
- Trend-chasing — no chasing visual fashions that won't survive two OSS cycles
- Omniscient — no claiming "offline just works" or "all screens are one runtime"

### Design Principles

1. The diagram is the product. Runtime boundaries made visible are the core value.
2. Contrast as contract. Accessible color is not a feature; it is the brand.
3. Technical quiet. Docs should be quieter than marketing; marketing should be honest enough to belong next to docs.
4. One color family per runtime. The palette gives each runtime a distinct signal without competing.

### Voice Principles

Write like a careful maintainer: precise, short, helpful, candid. Prefer "this action needs the server before it can be committed" over "seamlessly syncs in the background." Name failure modes before features.

### Should Feel Like

> Browsing a well-maintained, mature OSS library that respects your intelligence and your time. Like reading a Stripe or Tailwind doc: you trust it, you find what you need, it does not oversell. [inferred from brand book tone + OSS DNA]

### Should Never Feel Like

> A startup pitch, a beach brand, a React clone, or a system that makes mobile "easy" by hiding the complexity you will definitely encounter later. [stated in brand book §3, §4, §22; reinforced throughout]

### Crosswalk Name Adjacency

**Flag for human review.** "Crosswake" is visually close to the discontinued Crosswalk WebView project (Intel, 2013–2017). The brand book acknowledges this. This audit does not resolve potential trademark or confusion risk — a human should verify the Crosswake name is clear from Crosswalk and other "cross-" prefixed mobile tooling before investing in broad collateral. The visual identity and voice work described in this audit are fully safe to execute in parallel with that review. [constraint per audit brief behavior — flag, do not resolve]

## §3 Pressure-Test Scorecard

Scored 1–10 (10 = fully production-ready, no action needed). Score reflects the seed brand book state before Phase 102 execution.

| Criterion | Score | Why | Risk if unaddressed | Fix |
|-----------|-------|-----|---------------------|-----|
| **Distinctiveness** | 7/10 | Palette avoids all adjacent competitor pitfalls. Wake-seam concept has genuine conceptual weight. Space Grotesk with planned letter cuts will be distinctive. Without those cuts, the display font risks generic devtools sameness. | If custom letterform cuts are skipped, wordmark looks generic. | Execute D-11: custom `w`/`k` cuts mandatory in Phase 103. |
| **Developer credibility** | 8/10 | Voice guidance is precise, honest, and maintainer-shaped. The brand book explicitly lists what Crosswake is not. OSS DNA prompt (§24) is strong. Copy blocks are specific, not salesy. | None at high severity. Minor risk: the "coastal" visual metaphor reads as "beach" to some — keep visual treatment technical, not decorative. | TIGHTEN iconography to feel more map/chart than maritime. |
| **Elixir ecosystem fit** | 8/10 | Muted, technical, understated palette. Route-policy API naming is idiomatic Elixir. Microcopy library (§15) has good Elixir-appropriate tone. Atkinson Hyperlegible Next is a strong doc-readability choice. | Space Grotesk is not Elixir-specific — but no font is, and the letter cuts will differentiate. | Keep current stack. Monitor Phoenix/Elixir tooling design trends for ecosystem drift. |
| **Visual coherence** | 7/10 | Palette, motifs, and layout rules are mutually reinforcing. Dark-mode posture is present but under-detailed for non-hero surfaces. Shadow system is appropriately minimal. Grain texture rule (marketing only, never docs/UI) is smart. | Dark mode surface hierarchy may fracture without more explicit guidance. | ADD explicit dark-mode surface mapping in §8 brand book upgrade (§6 here). |
| **Logo readiness** | 5/10 | Direction is clear and buildable. The Wake Mark concept is concrete and geometrically specified. Lockup variants are enumerated. But no committed SVG exists; tournament has not run; ratification pending. | Phase 103 cannot start without AUDT-04 ratification. Downstream phases (105, 106) cannot proceed without a logo. | Execute Phase 103 logo tournament immediately after ratification. |
| **Color-system readiness** | 8/10 | 17 primitives with hex precision. Semantic mapping table exists. CSS variables are specified. D-02 remediation (Stone 600) is math-forced and executable. The seed brand book has no Stone 600 yet — this audit adds it. | Stone 500 failure (4.09:1) is the only true hex defect; it will manifest in UI if not remediated. | Add Stone 600, execute token compilation (Plan 02). |
| **Typography readiness** | 9/10 | Three named fonts, all on Google Fonts, OFL-licensed, weights specified, fallback stacks written. Type scale with token names enumerated. Tracking value specified. | Space Grotesk market saturation without custom cuts — mitigated by D-11. | Maintain. Phase 103 must execute the letter cut brief. |
| **Design-token readiness** | 6/10 | Brand book specifies the raw material (§8, §9, §13) but does not produce DTCG JSON or tokens.css. Token structure is not in the brand book — it is in this audit's §7. | Consumers (app.css, generator templates) cannot reliably consume tokens without the compiled output. | Execute Plan 02 (token compilation) — depends on §7 spec in this plan. |
| **UI component readiness** | 6/10 | Route card, capability matrix, runtime ladder, manifest viewer, badge system are all described. Button states are specified. Code block treatment is precise. But no committed component examples exist yet. | Brand book users will implement inconsistently without more concrete patterns. | ADD component specimen examples in Phase 105 brand book HTML. |
| **Docs/README usefulness** | 7/10 | §14 docs structure is detailed. §22 README guidance is concrete. §6 voice is surface-specific. Install-path and copy-snippet guidance exists. §15 microcopy library is genuinely useful. | README copy does not have a fully ready-to-use opening paragraph (§22 provides direction, not final copy). | ADD final README opening copy in §10 of this audit (brand voice section). |
| **Marketing usefulness** | 7/10 | Taglines, hero options, and three-bullet value proposition (§5) are strong and specific. Landing page architecture (§16) is detailed. But social card format, GitHub repo description, and Hex.pm description are not final copy. | Missing copy blocks create friction at launch-time. | TIGHTEN §10 of this audit with final, ready-to-use copy blocks for all launch surfaces. |
| **Voice/microcopy usefulness** | 8/10 | §15 microcopy library is specific, status-oriented, and correct in tone. Error messages are precise. Empty states are honest. CTA copy is good. Voice principles (§6) are actionable. | Slight gap: no explicit guidance on release note tone or changelog voice. | ADD release-note/changelog tone guidance in brand book §6 upgrade. |
| **Accessibility** | 7/10 | Stone 500 text-pair failure is the only true hex defect (4.09:1 on Foam 50). Stone 600 remediation closes it. All dark-surface pairs pass (5.6–16.6:1). Typography font choices (Atkinson Hyperlegible Next) demonstrate accessibility intent. Focus ring is specified (2px). Reduced-motion note exists. | Stone 500 is still referenced in the brand book as "neutral/muted text on light" — this is wrong after D-02. | Fix semantic mapping in brand book §8 upgrade; enforce via token `$description` restrictions. |
| **Repo/source-control readiness** | 6/10 | Brand book lives in prompts/ as a markdown file — not yet a committed repo artifact with proper directory structure. `.gitignore` needs brandbook tooling entries. `brandbook/` structure is being established in Phase 102. | brandbook/ artifacts may bloat the repo package if not excluded from mix.exs :files properly. | Execute Phase 102 setup tasks; confirm mix.exs :files excludes brandbook/. |
| **Long-term maintainability** | 8/10 | Token JSON → generated CSS pattern ensures consistency. Text-based artifacts (SVG path data, JSON, CSS, markdown) are source-controllable. Size budget (<1 MB for all of brandbook/) is realistic. OSS DNA prompt (§24) is a useful maintenance artifact. | If tokens.css is edited directly rather than regenerated, the committed header is the only guard. | TIGHTEN compile-tokens.js to throw a clear error if someone tries to modify tokens.css directly (advisory; enforcement relies on contributor discipline). |

## §4 Stress Tests

Per surface: is brand-book guidance sufficient, what is missing, what should be added. Untreated surfaces feed §5.

| Surface | Guidance sufficient? | What is present | What is missing |
|---------|---------------------|-----------------|-----------------|
| **GitHub repo header** | Partial | One-liner variants, brand promise, positioning sentence (§1, §5). Color palette specified. | Final committed text for the repo description field. Social preview image spec. |
| **README hero** | Partial | README opening direction (§22). One-liner and positioning sentence (§1, §5). Code snippet guidance (§13). | A fully ready-to-use README opening paragraph. Screenshot/diagram placement rules. |
| **README badges** | Insufficient | Badge style exists (§13 — pill/soft rect, text labels not just colors). Runtime badge examples. | Which specific badges belong in the README header (Hex version, license, CI status format)? Badge color palette for hex.pm badge is unspecified. |
| **Hex.pm page** | Partial | Short one-liner and description copy exists (§5). Voice guidance is applicable. | No explicit Hex.pm-specific copy. The Hex description field (≤ 160 chars) is not committed. |
| **HexDocs page** | Partial | Docs structure (§14) is detailed. Warning box style (§14) is specified. Page template (§14). | No guidance on the docs navigation color treatment in the ExDoc theme. HexDocs has limited theming surface — is that enough? |
| **Docs sidebar** | Insufficient | §14 provides IA structure. | No visual treatment for sidebar typography, active/hover states, or sidebar badge colors. These matter for the ExDoc theme (Phase 105 concern). |
| **Code block styling** | Sufficient | Current 900 background, Foam 50 text, Mist 200 comments, Wake 500 keywords, Brass 500 strings, Rust 600 errors (§13). Copy button guidance exists. | Nothing critical missing. |
| **Terminal snippet** | Sufficient | §13 code block treatment applies. JetBrains Mono specified. | No explicit terminal-prompt style ($, %, ►) — minor gap. |
| **API reference** | Partial | §20 API naming tone is detailed. Voice guidance is precise. §14 page template exists. | No guidance on how Crosswake module/function names appear in prose citations. |
| **Landing hero** | Sufficient | Dark Current background, Wake Mark graphic, headline options A/B/C (§5, §16), CTAs specified, subhead options exist. | No SVG/image spec for hero diagram yet (Phase 103/105 concern — not this phase). |
| **Feature section** | Sufficient | Runtime ladder component described. Three-bullet value prop (§5). Runtime badge colors mapped to runtime tier. | Illustration style guidance exists; no committed illustration template. |
| **Comparison section** | Partial | §3 of brand book explicitly positions against React Native, Hotwire Native, LiveView Native, Capacitor. | No comparison table template. Comparison content is scattered across §3 and §5 — consolidation would help. |
| **Blog post header** | Insufficient | Voice is specified for community posts (§6). | No blog header visual treatment. Font weight/size for post titles is derivable from type scale but not explicitly stated for this surface. |
| **Release announcement** | Insufficient | §6 tone guidance ("transparent, changelog-first") is present. | No release announcement template. This is a high-frequency surface for an OSS library. Brand book §6 upgrade should add one. |
| **Social preview card** | Insufficient | Palette and typography are specified. | No OG/social card format (1200×630px), layout template, or example. This is a hard gap — every link share will use a missing spec. |
| **Favicon** | Partial | Simplified mark at 16px mentioned (§10). Minimum sizes: favicon at 16px (§10). | No ICO/SVG favicon spec. No guidance on which colorway works at 16px. Phase 106 delivers this; gap flagged. |
| **App icon** | Partial | §10 mentions icon mark (Wake Mark only). Minimum 24px for UI. | No rounded-rectangle app icon spec (iOS: 1024×1024 no-mask, Android: adaptive foreground/background layers). Phase 106 concern. |
| **Small monochrome logo** | Sufficient | One-color lockup described. "Keep the mark readable in one color" is explicit (§10). | Only directional, not a committed SVG. Phase 103 delivers. |
| **Dark-mode page** | Partial | Dark-mode semantic mapping is derivable from §8 color system. Code block dark treatment is explicit. | No explicit dark-mode surface hierarchy for non-hero UI (cards, nav, sidebars). Text on dark is underdefined beyond body + code. |
| **Light-mode page** | Sufficient | Foam 50 background, Current 950 body text, full semantic mapping in §8. Layout (§13). | Solid foundation. |
| **Conference slide** | Insufficient | Typography and palette provide a starting point. | No slide template, slide palette subset, slide title/body type size, or guidance on diagram placement on slides. |
| **Architecture diagram** | Sufficient | Runtime lane diagrams described (§11). Wake seam motif. Shape language (§11). Thin map/sounding lines. | No committed diagram template. Illustration style is detailed enough to produce one. |
| **Error/empty/success states** | Sufficient | Microcopy library (§15) covers error, empty, success states. Status color mapping in §8. Warning box style (§14). | Strong foundation. |
| **Example UI components** | Partial | Route card, capability matrix, runtime ladder, manifest viewer (§19). Badge style. Button states (§13). | No committed component HTML or screenshot. Phase 105 delivers. |
| **Mobile landing** | Partial | Landing page direction (§16). Responsive content width is not explicitly addressed (brand book §13 specifies desktop content widths only). | Mobile breakpoints, tap-target guidance (§21 mentions 44px but no breakpoint spec). |
| **Sticker/swag** | Not appropriate yet | Brand book notes are minimal. | No logo as committed SVG = no sticker spec possible. Deferred to post-Phase 103. |

**Summary of gaps feeding §5:**
Critical: social preview card spec missing; dark-mode surface hierarchy is thin.
Important: README badges (which ones, exact format), Hex.pm copy committed, conference slide template, blog/release announcement template, mobile breakpoints.
Nice-to-have: sidebar active/hover treatment, swag format.

## §5 Gaps and Risks

### Critical (blocks execution or creates active user harm)

**1. Generator palette drift (AUDT-03)**

`lib/mix/tasks/crosswake.gen.offline_ui.ex` (lines 67–90) emits a Tailwind config snippet that defines `cw-wake` as a 9-stop **blue** family (500: `#699cc9`, 700: `#3c6d99`) and `cw-brass` as a 9-stop **amber** family (500: `#e1b982`, 700: `#c59a5e`). The brand book and `examples/phoenix_host/assets/css/app.css` define `cw-wake` as a **teal** family (`--cw-wake-700: #2B756A`) and `cw-brass` as a **warm gold** family (`--cw-brass-500: #C98A2E`). These are entirely different color families using the same naming prefix.

**Impact:** Any host app that runs `mix crosswake.gen.offline_ui` and uses the emitted Tailwind config snippet will render the offline UI in blue/amber instead of the canonical teal/brass palette. The generator templates in `priv/templates/crosswake/offline_ui/` reference classes like `border-cw-wake-700` and `border-cw-brass-500` — with the correct names but the wrong colors if the emitted snippet is used.

**Verdict: TIGHTEN** — The naming convention (`cw-wake`, `cw-brass`) is correct; the color values in the emitted snippet are wrong. This is a configuration drift issue, not an architectural one.

**Cost:** This is not fixed in Phase 102. The fix is **NORM-01** in a future milestone: normalize generator templates and `app.css` onto `brandbook/tokens/tokens.css` as the single source of truth for `--cw-*` variables, replacing the Tailwind scale emission with token-based guidance.

**2. Social preview card specification is absent**

There is no OG image format (1200×630px), layout template, logo placement rule, or text treatment for social preview cards. Every link share from GitHub, Hex.pm, or social media will use a blank or auto-generated preview. This blocks GitHub-to-social discoverability before Phase 106 delivers collateral.

**Impact:** GitHub README links, Hex.pm, and any social post share will show a blank or auto-generated preview.

**Verdict: ADD** — Specify the OG card format (1200×630px, Current 950 or Foam 50 background, Wake Mark centered or offset, one-liner, hex/version info). Phase 106 delivers the committed file; Phase 102/103 delivers the spec.

---

### Important (quality degradation later; does not immediately block shipping)

**3. Stone 500 referenced as valid muted text in brand book §8**

The seed brand book §8 still maps `--cw-stone-500` to "Neutral/muted text on light." After D-02, Stone 500 is narrowed to large text ≥24px, disabled states, and decorative use. The brand book needs updating.

**Impact:** Brand book users who implement before the token system is in place will use Stone 500 for normal-size muted text, failing AA (4.09:1).

**Verdict: TIGHTEN** — Update brand book §8 semantic mapping to reflect the Stone 600/Stone 500 role split.

**4. Dark-mode surface hierarchy is underspecified**

The brand book describes the dark hero and code block treatments well, but does not specify how non-hero surfaces (cards, nav, sidebars, secondary panels) should render in dark mode. The semantic mapping from §8 is suggestive but not authoritative for every surface type.

**Impact:** Dark-mode implementations will fracture without an explicit surface hierarchy — some teams will use Current 900 where Current 800 is appropriate, or vice versa.

**Verdict: ADD** — Dark-mode surface hierarchy table (default/raised/inset/inverse mappings with example use cases) is needed in the brand book upgrade (§6).

**5. README badges specification is absent**

The brand book mentions badge style but does not specify which badges belong in the README header, what color treatment they should use, or how hex.pm/CI badges should render alongside brand-styled route/capability badges.

**Impact:** README badge treatment will be improvised at publish time.

**Verdict: ADD** — Specify the README badge set (Hex version, license, CI status) with formatting guidance.

**6. Release announcement / changelog voice is unspecified**

Brand book §6 specifies tone by surface for landing page, docs, API references, error messages, community posts, and UI microcopy. It does not include release notes or changelog announcements — a high-frequency surface for any OSS library.

**Impact:** Release notes risk being inconsistent with the brand voice.

**Verdict: ADD** — Add release-note and changelog voice guidance to brand book §6.

**7. Conference slide treatment is absent**

No slide template, palette subset for projected backgrounds, or guidance on font sizes at slide scale exists. Conference talks are a primary adoption channel for OSS libraries targeting the Elixir community (ElixirConf, Code BEAM).

**Impact:** Slide decks will look inconsistent with the brand.

**Verdict: ADD** — Add conference slide guidance to brand book §9/§13 upgrade.

---

### Nice-to-Have (low risk, low urgency)

**8. Docs sidebar active/hover state is unspecified**

The ExDoc theme sidebar has active and hover states. Exact token mapping (Wake 700 background? Brass 500 accent?) is not specified.

**Verdict: ADD** — Can be resolved during Phase 105 HTML brand book construction.

**9. Swag/sticker format is deferred**

No sticker or swag spec is possible before the logo SVG is committed. This is correctly deferred to post-Phase 103.

**10. Mobile breakpoints for landing page**

Brand book §13 specifies desktop content widths (760–860px docs, 1120–1200px landing). Mobile breakpoints are not specified.

**Verdict: ADD** — Specify mobile-first breakpoints in the brand book §13 upgrade.

## §6 Recommended Brand Book Upgrades

Only sections receiving TIGHTEN / ADD verdicts are listed. KEEP verdicts require no upgrade. No REWORK verdicts were issued — the brand book core is sound and no section warrants a full rewrite at this stage. **Cost (hypothetical REWORK threshold):** a full palette REWORK that shifts emotional character rather than fixing math would cascade color changes across all specimens, Phase 103 logo candidates, and generated CSS — reserved for AUDT-04 ratification if the user disagrees with any unilateral audit decision.

---

### §8 Color System — TIGHTEN (Stone 600 addition + semantic role correction)

**What to add:**
- Add Stone 600 `#756D63` to the core palette table with role "text.muted on light surfaces — 4.53:1 on Foam 50 PASS."
- Correct the semantic mapping: `--cw-stone-500` → "Narrow use: large text ≥24px, disabled, decorative only. Fails AA normal text (4.09:1). Never as body or UI muted text."
- Add the dark-mode surface hierarchy table:

| Surface level | Dark value | Use |
|---------------|------------|-----|
| `surface.default` | `--cw-primitive-current-950` | Page background |
| `surface.raised` | `--cw-primitive-current-900` | Cards, code blocks |
| `surface.inset` | `--cw-primitive-current-800` | Inset panels, nested cards |
| `surface.inverse` | `--cw-primitive-foam-50` | CTA sections, callouts |

- Add to CSS variables block: `--cw-stone-600: #756D63;`

**Why:** Stone 500 is currently listed as valid muted text; this is a WCAG failure that will produce inaccessible UI. The dark-mode hierarchy is needed before any dark-mode surface can be built consistently.

---

### §6 Voice and Tone — ADD (release announcement surface)

**What to add:**

| Surface | Tone |
|---------|------|
| Release notes / changelog | Specific, task-first, no drama. Lead with what changed. State what broke. Separate "what's new" from "what's fixed" from "what's deprecated." Use present tense: "Adds Stone 600 primitive. Fixes text.muted AA contrast." |

**Example release note opening:**

> `crosswake 0.2.0` — Token foundation and brand audit.
>
> Adds `brandbook/` with the design token system, WCAG contrast matrix, and 14-section brand audit. Pins Stone 600 as the corrected text.muted primitive. Flags generator palette drift (fix tracked as NORM-01). No breaking changes to route policy or bridge contracts.

**Why:** Release notes are the primary trust signal for OSS adopters considering version upgrades. The existing voice guidance does not cover this surface.

---

### §9 Typography / §13 Layout — ADD (conference slide guidance)

**What to add:**

Conference slide guidance:
- Use display.lg (56px) for slide titles. Space Grotesk SemiBold.
- Use display.sm (28px) for slide body bullets. Atkinson Hyperlegible Next Regular.
- Use a Current 950 dark background for technical/architecture slides; Foam 50 light background for code-heavy slides.
- Palette subset for slides: Current 950, Foam 50, Wake 700, Brass 500. Avoid all others on slides.
- Wake Mark or a route-seam diagram as the slide header graphic. Never use it as a watermark behind text.
- Slides must pass WCAG AA at projector brightness levels — prefer Current 950 + Foam 50 or white text for maximum contrast.

**Why:** Conference talks are the highest-leverage OSS adoption channel in the Elixir community. Without slide guidance, every presenter will improvise and produce inconsistent visual output.

---

### §13 Layout and UI System — ADD (mobile breakpoints)

**What to add:**

| Breakpoint | Value | Use |
|------------|-------|-----|
| `sm` | 640px | Single-column docs layout |
| `md` | 768px | Two-column doc start |
| `lg` | 1024px | Full sidebar visible |
| `xl` | 1200px | Landing page full width |

Mobile-first: design for 375px+ single-column as the base. Tap targets 44px minimum (§21 guidance applies). Navigation collapses below `md`.

**Why:** §13 only specifies desktop content widths. Without mobile breakpoints, the landing page and docs will be hand-waved during implementation.

---

### Social Preview (§11 / §12 / new) — ADD

**What to add:**

OG card specification:
- Size: 1200×630px
- Background: Current 950 (`#09141A`)
- Logo: Wake Mark (path SVG, centered or upper-left) in Foam 50
- Wordmark: "Crosswake" in Space Grotesk SemiBold, Foam 50, 48px
- One-liner: "Route policy for Phoenix apps that go mobile." Atkinson Hyperlegible Next Regular, Mist 200, 24px
- Optional: Hex/version indicator in JetBrains Mono, Stone 500, 16px, lower-right corner
- Path: `brandbook/social/og-card.svg` (Phase 106 deliverable)

**Why:** This is a hard gap — every link share from day one will show no preview. The spec must exist before Phase 106 executes.

---

### §10 Logo Direction — TIGHTEN (wake mark geometry spec)

**What to add:**

Extend the Wake Mark geometry specification:
- Define exact angle: 16–24 degrees from horizontal (use 20° as the canonical angle for the letterform cut brief).
- Stroke weight: 2.5px at 24px icon size; scale proportionally.
- Wake line count: exactly 3 — the crossing line plus two trailing wake lines.
- Notch/break at crossing point: 1.5× stroke width gap.
- Corner cap style: round (not butt or square).
- Minimum pixel rendering: test at 16px before committing; simplify to 2 strokes at ≤16px.

**Why:** The current direction is buildable but a logo tournament (Phase 103) needs geometry parameters tight enough to evaluate candidates consistently. The current spec has directional language but no measurements.

## §7 Design Token Specification

**Verdict: KEEP with TIGHTEN** — The brand book's color and typography specifications are sound raw material; the audit transcribes them into a locked, structured token system here. Do not invent tokens beyond this spec.

### Architecture Overview

**Two tiers only.** Primitive tokens (internal, never referenced in component CSS) resolve to semantic tokens (public contract). No component tier — this is a deliberate anti-feature. Component-level tokens create naming churn and fragment the public contract without adding value at the library boundary.

**Naming convention:** `--cw-` prefix throughout. Primitives: `--cw-primitive-{family}-{weight}`. Semantics: `--cw-{role}-{variant}`.

**Source of truth:** `brandbook/tokens/crosswake.tokens.json` (W3C DTCG 2025.10 format — `$value`/`$type`/`$description`, group-level `$type`, `{primitive.x.y}` alias syntax). The compiled `brandbook/tokens/tokens.css` is generated output — always edit the JSON and regenerate. CSS header: `/* GENERATED from crosswake.tokens.json — do not edit */`.

**Theming model (D-08):** `:root` holds light-mode semantic values. System dark mode: `@media (prefers-color-scheme: dark) { :root:not([data-theme]) }`. Explicit toggle: `[data-theme="dark"]`. Only the semantic tier flips in dark mode; primitives never change. This is daisyUI-idiomatic for Phoenix 1.8 adopters.

---

### Tier 1: Primitive Tokens (17 total)

16 original palette entries from the brand book plus **Stone 600 `#756D63`** (D-02 remediation — passes AA on Foam 50 at 4.53:1; see Appendix A).

| JSON path | CSS variable | Hex | Role |
|-----------|-------------|-----|------|
| `primitive.current.950` | `--cw-primitive-current-950` | `#09141A` | Primary dark, logo ink, hero background |
| `primitive.current.900` | `--cw-primitive-current-900` | `#0F1E26` | Dark panels, code blocks |
| `primitive.current.800` | `--cw-primitive-current-800` | `#162B35` | Raised dark surfaces |
| `primitive.harbor.700` | `--cw-primitive-harbor-700` | `#254855` | Secondary dark accent, diagrams |
| `primitive.wake.700` | `--cw-primitive-wake-700` | `#2B756A` | Primary action on light |
| `primitive.wake.500` | `--cw-primitive-wake-500` | `#4E9A8E` | Accent on dark surfaces |
| `primitive.kelp.800` | `--cw-primitive-kelp-800` | `#123B36` | Offline/success deep accent |
| `primitive.brass.500` | `--cw-primitive-brass-500` | `#C98A2E` | Signal accent on dark |
| `primitive.brass.700` | `--cw-primitive-brass-700` | `#946017` | Warning text on light surfaces |
| `primitive.foam.50` | `--cw-primitive-foam-50` | `#F7F1E6` | Main light background |
| `primitive.foam.100` | `--cw-primitive-foam-100` | `#EFE6D6` | Warm panel/code-light surface |
| `primitive.mist.200` | `--cw-primitive-mist-200` | `#C9D4CF` | Borders, muted text on dark |
| `primitive.stone.500` | `--cw-primitive-stone-500` | `#7C746A` | Narrow use: large text ≥24px, disabled, decorative. Fails AA normal text on Foam 50 (4.09:1). |
| `primitive.stone.600` | `--cw-primitive-stone-600` | `#756D63` | NEW (D-02): text.muted on light. 4.53:1 on Foam 50 PASS. |
| `primitive.rust.600` | `--cw-primitive-rust-600` | `#9A4D35` | Danger, sensitive, destructive |
| `primitive.plum.700` | `--cw-primitive-plum-700` | `#372D4C` | Bridge/contract accent |
| `primitive.white` | `--cw-primitive-white` | `#FFFFFF` | Text on dark/action surfaces |

Primitives are emitted in `:root` as raw hex values. They must not be referenced in component CSS — only semantic tokens cross the library boundary.

---

### Tier 2: Semantic Tokens (29 total — within D-06 hard cap of 30; exactly 1 slot remains)

#### surface (4 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-surface-default` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-current-950)` |
| `--cw-surface-raised` | `var(--cw-primitive-foam-100)` | `var(--cw-primitive-current-900)` |
| `--cw-surface-inset` | `var(--cw-primitive-white)` | `var(--cw-primitive-current-800)` |
| `--cw-surface-inverse` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-50)` |

#### text (5 tokens)

| Token | Light value | Dark value | Notes |
|-------|-------------|------------|-------|
| `--cw-text-default` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-50)` | |
| `--cw-text-muted` | `var(--cw-primitive-stone-600)` | `var(--cw-primitive-mist-200)` | Dark: mist-200 (12.25:1). Stone 600 on current-950 is 3.66:1 — fails AA normal text. |
| `--cw-text-subtle` | `var(--cw-primitive-stone-500)` | `var(--cw-primitive-mist-200)` | Large text ≥24px, disabled states, decorative only. Stone 500 fails AA normal text on Foam 50 (4.09:1). |
| `--cw-text-inverse` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-current-950)` | |
| `--cw-text-code` | `var(--cw-primitive-foam-50)` | `var(--cw-primitive-foam-50)` | Code block text on Current 900 background |

#### action (6 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-action-bg` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-brass-500)` |
| `--cw-action-fg` | `var(--cw-primitive-white)` | `var(--cw-primitive-current-950)` |
| `--cw-action-bg-dark` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-wake-700)` |
| `--cw-action-fg-dark` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-white)` |
| `--cw-action-hover` | `var(--cw-primitive-current-950)` | `var(--cw-primitive-foam-100)` |
| `--cw-action-focus-ring` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-wake-500)` | Corrected from brass-500 (2.93:1 on white — fails WCAG SC 1.4.11's 3:1 non-text floor) to wake-700 (5.45:1 on white / 4.85:1 on foam-50) — Phase 155 D-33. |

#### border (3 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-border-default` | `var(--cw-primitive-mist-200)` | `var(--cw-primitive-harbor-700)` |
| `--cw-border-subtle` | `var(--cw-primitive-foam-100)` | `var(--cw-primitive-current-800)` |
| `--cw-border-strong` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-mist-200)` |

#### status (5 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-status-success` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` |
| `--cw-status-warning` | `var(--cw-primitive-brass-700)` | `var(--cw-primitive-brass-500)` |
| `--cw-status-error` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` |
| `--cw-status-info` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` |
| `--cw-status-error-fg` | `var(--cw-primitive-white)` | (no `$dark` — pure alias) | Foreground for a filled error/danger surface. 6.02:1 on `--cw-status-error` in both themes — Phase 155 D-27/D-32. |

#### runtime (5 tokens — Crosswake-unique tier)

The `runtime.*` tier is the single most important differentiator in this token system. No other devtools brand book has a runtime-ownership semantic tier. These tokens encode the library's core contract — which UI belongs to which runtime — into the CSS layer itself. They are not status colors dressed up with names; each maps to a distinct semantic role in the Crosswake capability ladder.

| Token | Light value | Dark value | Semantic role |
|-------|-------------|------------|---------------|
| `--cw-runtime-liveview` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` | LiveView server-centric runtime |
| `--cw-runtime-offline` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` | Offline island runtime |
| `--cw-runtime-native` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-brass-500)` | Native screen ownership |
| `--cw-runtime-sensitive` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` | Sensitive / cache-never routes |
| `--cw-runtime-bridge` | `var(--cw-primitive-plum-700)` | `var(--cw-primitive-foam-50)` | Bridge contract surface |

#### overlay (1 token — Phase 155 D-27)

| Token | Light value | Dark value | Notes |
|-------|-------------|------------|-------|
| `--cw-overlay-scrim` | `var(--cw-primitive-current-950a72)` | (no `$dark` — deliberate) | 8-digit hex primitive (`#09141AB8`), not `color-mix()` (iOS 15.0 floor). Full-viewport backdrop behind a host-owned fallback modal/menu panel only. |

---

### Non-Color Tokens

#### Typography (3 tokens, `$type: "fontFamily"`)

| Token | Value |
|-------|-------|
| `font.display` | `"Space Grotesk", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.body` | `"Atkinson Hyperlegible Next", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` |
| `font.mono` | `"JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace` |

**D-11 Mandatory Rider (cascades to Phase 103):** Custom `w`/`k` wake-angle cuts on the wordmark are NON-OPTIONAL. The committed wordmark must not be typesettable in unmodified Space Grotesk. The display font family is FROZEN (D-12 — never changes at ratification), but the letterform customization is mandatory. Phase 103 executes the letter-cut brief.

#### Type Scale (8 tokens, `$type: "dimension"`)

| Token | Size | Line height | Use |
|-------|------|-------------|-----|
| `text.xs` | 12px | 16px | badges, metadata |
| `text.sm` | 14px | 20px | nav, labels |
| `text.md` | 16px | 24px | body |
| `text.lg` | 18px | 28px | lead body |
| `text.xl` | 20px | 30px | card headings |
| `display.sm` | 28px | 36px | docs page title |
| `display.md` | 40px | 48px | landing section title |
| `display.lg` | 56px | 64px | hero headline |

**Tracking:** `text.tracking-tight: -0.02em` — applies to `display.md` and `display.lg` headings.

#### Spacing, Radius, Focus (6 tokens)

| Token | Value | Use |
|-------|-------|-----|
| `spacing.base` | 4px | 4px base grid; all spacing is multiples of this |
| `radius.sm` | 6px | inline code, tiny badges |
| `radius.md` | 10px | buttons, inputs |
| `radius.lg` | 14px | cards |
| `radius.xl` | 20px | hero panels, major diagrams |
| `focus.ring-width` | 2px | visible focus outline in both light and dark modes |

---

### 12-State Mapping (D-09 — TOKN-03 auditability)

States covered: default, hover, active, focus, disabled, selected, success, warning, error, info, subtle, muted. No state requires a dedicated new semantic token unless already defined above.

| State | Strategy | Token(s) involved |
|-------|----------|-------------------|
| **default** | Semantic token default value | All base semantic tokens |
| **hover** | Dedicated semantic token | `--cw-action-hover` |
| **active** | CSS selector (`:active`) applied against semantic tokens | `--cw-action-bg`, `--cw-action-fg` — no new token |
| **focus** | 2px outline using dedicated focus-ring token | `--cw-action-focus-ring` |
| **disabled** | `opacity: 0.45` + accessible label; narrow color use | `--cw-text-subtle` for disabled text |
| **selected** | Pattern: action background + strong border | `--cw-action-bg` + `--cw-border-strong` — no new token |
| **success** | Dedicated status token | `--cw-status-success` |
| **warning** | Dedicated status token | `--cw-status-warning` |
| **error** | Dedicated status token | `--cw-status-error` |
| **info** | Dedicated status token | `--cw-status-info` |
| **subtle** | Text tier variant | `--cw-text-subtle` (large text ≥24px, decorative) |
| **muted** | Text tier variant | `--cw-text-muted` (normal-size secondary text) |

**Critical dark-mode rule:** `--cw-text-muted` on dark surfaces must resolve to `mist-200` (12.25:1 on Current 950 — PASS). Stone 600 on Current 950 is 3.66:1 — fails AA normal text and must never appear as muted text on a dark background. This is enforced structurally in the token JSON `$dark` value and generated CSS dark block.

---

### Stone 600 Remediation (D-02)

Stone 500 (`#7C746A`) on Foam 50 fails AA normal text at 4.09:1 — the only true hex failure in the palette (see Appendix A). The remediation adds **Stone 600 `#756D63`** as a new primitive:
- Stone 600 on Foam 50: **4.53:1 PASS**
- Stone 600 on white: **5.09:1 PASS**
- `text.muted` → Stone 600 (normal-size secondary text on light surfaces)
- `text.subtle` → Stone 500 (large text ≥24px, disabled states, decorative only)

Stone 600 is light-mode-only for text. On dark surfaces, `text.muted` uses `mist-200` (12.25:1). Stone 600 may be used for non-text elements (borders, decorative lines) on dark surfaces, where the 3:1 AA non-text threshold applies (Stone 600 on Current 950 is 3.66:1 — PASS for non-text).

## §8 Logo and Mark System

**Verdict: TIGHTEN the direction; run Phase 103 tournament to produce the committed artifacts.**

The Wake Mark concept is geometrically sound and conceptually honest. A diagonal route line crossing a seam and trailing clean wake lines is both specific to the product's meaning and distinctive from every adjacent brand (atom/React, flame/Phoenix, wire/Hotwire, electric bolt/Ionic). The direction does not require a REWORK; it requires execution. Phase 103 runs the tournament that produces the committed SVG files.

### Logo direction verdict

**TIGHTEN** — The brand book's Wake Mark specification (§10) is buildable. The geometry is described with enough precision to brief a tournament. The missing element is measured constraints and a mandatory letter-cut rider that converts generic starting material into a proprietary endpoint.

### Phase 103 tournament brief

The tournament must produce the following variants. No committed SVGs exist until Phase 103 completes and ratification occurs:

| Variant | Spec |
|---------|------|
| **Horizontal lockup** | Wake Mark + "Crosswake" wordmark on one line. Minimum 128px wide. |
| **Stacked lockup** | Wake Mark above wordmark. For social/README hero use. |
| **Icon mark** | Wake Mark alone. 24px minimum for UI use. |
| **Tiny/favicon mark** | Simplified 2-stroke wake, no small details. Legible at 16px. |

Four logomark concepts and three integrated typemarks are the expected tournament field. Selection is a blocking user checkpoint in Phase 103.

### Wake Mark geometry (mandatory tournament constraints)

- **Crossing angle:** 20° from horizontal (canonical). Acceptable range: 16–24°.
- **Wake line count:** Exactly 3 — the crossing line plus two trailing wake lines.
- **Stroke weight:** 2.5px at 24px icon size. Scale proportionally.
- **Notch/break at crossing point:** 1.5× stroke width gap where the seam boundary is crossed.
- **Corner cap style:** Round (not butt or square).
- **Minimum pixel rendering:** Test at 16px. Simplify to 2 strokes at ≤16px.
- **SVG format:** Path-only. No `<text>` elements in committed SVGs. No rectangular clip-path backgrounds. No embedded fonts.

### Wordmark specification

Starting font: Space Grotesk SemiBold (600). The starting font is FROZEN (D-12 — never changes even if Space Grotesk market saturation worsens).

**D-11 MANDATORY RIDER (non-optional, cascades to Phase 103):**

> The committed wordmark must NOT be typesettable in unmodified Space Grotesk. Custom wake-angle cuts on the `w` and `k` letterforms are required. The `w` cut should echo the wake crossing angle (20°); the `k` arm/leg intersection should carry an angular notch at the same slope. Candidates that do not include these cuts are disqualified from the tournament.

This rider is the single mechanism that converts a generic starting point into an irreducible Crosswake artifact. Phase 103 must execute it.

### Logo colorways

| Context | Mark | Wordmark | Background |
|---------|------|----------|------------|
| **Light primary** | Current 950 | Current 950 | Foam 50 or white |
| **Dark primary** | Foam 50 | Foam 50 | Current 950 |
| **Signal** | Brass 500 | Foam 50 | Current 950 |
| **OSS badge** | Wake 700 | Current 950 | Foam 50 |
| **One-color** | Current 950 or Foam 50 | Same | Any solid |

Only the one-color lockup must be committed in Phase 103; full colorway assets follow in Phase 106.

### Clearspace

- Horizontal lockup: minimum clearspace = x-height of the wordmark on all four sides.
- Icon mark: clearspace = one stroke width + one wake-gap on all sides.
- Never place the mark inside a bounding shape (circle, square, blob, gradient card).

### Minimum sizes

| Variant | Minimum |
|---------|---------|
| Horizontal lockup | 128px wide |
| Stacked lockup | 64px wide |
| Icon mark | 24px (UI), 32px (README) |
| Favicon | 16px (simplified 2-stroke) |

### Logo do/don't

**Do:** geometric strokes, one-color readability, diagonal crossing preserved, warm dark/light contrast, rounded stroke caps.

**Do not:** add literal boats, anchors, ropes, waves, water splashes, neon glow, flame shape, generic app-gradient blob, or an X mark with no wake semantics. Do not place the wordmark over a photograph.

### Misuse examples (Phase 105 to document in brand book HTML)

1. Colorway swap to cyan — rejected; contradicts React Native avoidance.
2. Mark at <12px without simplification — rejected; illegible.
3. Wordmark set in unmodified Space Grotesk — rejected; D-11 violation.
4. Mark inside a drop-shadow card or rounded blob — rejected; adds visual noise.
5. Mark stretched or rotated off 20° — rejected; the crossing angle is the brand geometry.

## §9 Visual Examples and Screenshot Guidance

**No decorative screenshots. Every specimen produced must answer a specific implementation or communication need.**

### Specimens worth producing — ranked by value

| Priority | Specimen | Purpose | Layout/Format | Target path | When to produce |
|----------|----------|---------|----------------|-------------|-----------------|
| P1 | **Route policy code + route card** | Primary product explanation; appears in README hero, landing, docs home | Light: code block left, route card right, 960×480px, Foam 50 bg | `brandbook/specimens/route-card-light.svg` | Phase 103 (before logo; logo not needed for this) |
| P1 | **Runtime ladder diagram** | Shows the 7-tier capability ladder; the single most useful architecture diagram | Dark: vertical lanes labeled, wake lines as dividers, 480×640px, Current 950 bg | `brandbook/specimens/runtime-ladder-dark.svg` | Phase 103 |
| P1 | **Wake Mark — icon mark** | Required for README, Hex.pm, social card, docs masthead | Single-color SVG, exported in Foam 50 and Current 950 variants | `brandbook/logo/wake-mark.svg` | Phase 103 (tournament output) |
| P2 | **Dark hero mockup** | Full landing hero section showing headline + wake mark + CTA | 1200×630px, Current 950 bg, Space Grotesk headline | `brandbook/specimens/hero-dark.svg` | Phase 105 |
| P2 | **OG/social preview card** | Every link share from day one | 1200×630px, Current 950 bg — see §6 spec | `brandbook/social/og-card.svg` | Phase 106 |
| P2 | **Token color swatches** | Token system documentation for HTML brand book | Grid, 3 columns, light/dark variants side by side | `brandbook/specimens/token-swatches.svg` | Phase 105 |
| P3 | **Capability matrix** | Docs component showing iOS/Android/permission/fallback/telemetry | Table component, Foam 50 bg, Wake 700 headers | `brandbook/specimens/capability-matrix.svg` | Phase 105 |
| P3 | **Error/empty/success states** | Microcopy and UI pattern documentation | 3-panel strip, 320×200px each | `brandbook/specimens/ui-states.svg` | Phase 105 |
| P3 | **Conference slide example** | Demonstrates type scale and palette at slide scale | 1920×1080px, Current 950 bg | `brandbook/specimens/slide-dark.svg` | Phase 105 (optional; defer if time-constrained) |

### What not to produce

- Generic device mockup lifestyle shots — the product is the architecture, not the phone.
- Gradient or abstract marketing backgrounds without diagrams.
- Screenshots of competitor UI (for contrast/comparison purposes) — describe in prose instead.
- Any specimen that decorates without demonstrating a specific brand decision.

### Screenshot format rules

- SVG path-only or PNG ≤ 200KB per specimen.
- Diagrams must use the committed palette primitives — no off-palette hex values.
- All text in diagram SVGs must be converted to paths or replaced with foreign-object accessible text before commit (no embedded font binaries).
- Specimens use the committed token CSS variable names in their documentation annotations, not raw hex.

## §10 Brand Voice and Microcopy

**Verdict: TIGHTEN — the voice guidance is directionally strong but does not include ready-to-use copy blocks for every launch surface. This section supplies them.**

### Voice verdict

The seed brand book's voice principles (§6) are sound: write like a careful maintainer, prefer operational truth over hype, explain the boundary, use metaphor sparingly. The microcopy library (§15) is specific and correct in tone. Two gaps: release-note voice was unspecified (addressed in §6 upgrade); and no surface had final copy ready to paste. This section closes both.

### Ready-to-use copy blocks

---

**One-liner (primary):**

> Route policy for Phoenix apps that go mobile.

**One-liner (expanded):**

> Crosswake is a Phoenix-native mobile substrate for declaring which runtime owns each route: LiveView, offline island, native screen, or adapter.

---

**140-character description (GitHub repo description field):**

> Phoenix route policy for mobile apps: LiveView, offline islands, native screens, and bridge contracts without hiding the runtime boundary.

*(138 chars — within the 160-char Hex.pm field; trim to "Route policy for Phoenix apps that go mobile — LiveView, offline islands, native screens." for tighter contexts)*

---

**GitHub repo description (exact text, ≤ 300 chars):**

> Phoenix-native mobile substrate. Declare which runtime owns each route — LiveView, offline island, native screen, or adapter — and keep the boundary explicit. Route policy, capability registry, bridge contracts, and offline islands for Phoenix teams.

---

**Hex.pm description (≤ 160 chars):**

> Route policy for Phoenix apps that go mobile. Declare LiveView, offline, native, and adapter-backed routes explicitly. No write-once magic.

*(140 chars)*

---

**README opening paragraph:**

> Crosswake is a Phoenix-native mobile substrate for route-level runtime policy. It helps a Phoenix app decide which screens stay LiveView, which screens become offline islands, and which screens hand off to host-owned native views.
>
> Each route declares its runtime, capabilities, offline policy, and security posture. Crosswake turns those declarations into a runtime manifest, a native-shell contract, and a set of compatibility gates — so the system tells you exactly what runs where, what can fail, and what you own versus what Crosswake owns.
>
> ```elixir
> route "/study/session",
>   runtime: {:offline_island, "study.session"},
>   content_pack: :daily_study,
>   capabilities: [:audio, :haptics]
> ```

---

**Landing hero headline (Option A — recommended):**

> Phoenix routes, native where it matters.

**Landing hero subheadline:**

> Crosswake gives Phoenix apps a mobile route policy: LiveView for server-centric flows, offline islands for local work, and native screens for device-heavy moments. Every boundary is explicit.

---

**Landing hero headline (Option B — for A/B testing):**

> Declare the crossing.

**Option B subheadline:**

> Crosswake lets Phoenix teams choose the right runtime per route — LiveView, offline island, native screen, or adapter — without blurring the boundary.

---

**Primary CTA:**

> Read the guide

**Secondary CTA:**

> View examples

**Install CTA:**

> Install Crosswake

**Docs entry CTA:**

> Generate a route policy

---

**Three feature blurbs:**

**1. Route-owned runtime policy**
> Declare whether each screen is LiveView, offline, native, or adapter-backed — directly in the route definition. No runtime decision happens implicitly.

**2. Typed native boundaries**
> Version your bridge messages, capability requirements, native screens, and app-binary compatibility. The manifest tells the shell exactly what it needs before activation.

**3. Local-first where it belongs**
> Offline islands, content packs, and event journals give local-first loops explicit contracts. Drafts are drafts. Cached reads are cached reads. Nothing pretends to be a server action.

---

**Three "why this exists" bullets:**

- Phoenix teams ship mobile apps, but not every screen belongs in the same runtime. Crosswake makes that decision explicit, per route, with contracts that fail visibly instead of silently.
- The alternatives — React Native wrappers, LiveView-everywhere optimism, or raw WebView bridges — all hide the boundary. Crosswake declares it.
- Mobile development still requires mobile work. Crosswake does not abstract that away; it structures it so you own what you built and can explain what can fail.

---

**Example error states (ready to paste into UI):**

| State | Copy |
|-------|------|
| Runtime mismatch | "This route requires native runtime `0.3.0` or newer. Update the app or choose another route." |
| Capability unavailable | "Camera capture is not available in this app runtime. The route policy requires `:camera`." |
| Offline commit blocked | "This action needs the server before it can be committed. The draft was saved locally." |
| Sensitive cache blocked | "This route is marked sensitive and will not be cached." |
| Bridge payload rejected | "Crosswake rejected this bridge message because it does not match the registered contract." |

**Example empty states:**

| State | Copy |
|-------|------|
| No offline content | "Nothing has been packed for offline use yet. Sync this route before going offline." |
| No native screen registered | "The route policy points to a native screen, but the host app has not registered it." |
| No capabilities declared | "This route does not request native capabilities." |

**Example success states:**

| State | Copy |
|-------|------|
| Sync confirmed | "Server confirmed. The local draft was committed successfully." |
| Route activated | "Route activated. Native runtime `0.3.1` detected and verified." |
| Pack ready | "Content pack `daily_study` is ready for offline use." |

---

**Example release announcement:**

> **crosswake 0.2.0** — Token foundation and brand audit.
>
> Adds `brandbook/` with the design token system (`crosswake.tokens.json`, `tokens.css`), WCAG contrast matrix, and 14-section brand audit. Introduces Stone 600 (`#756D63`) as the corrected `text.muted` primitive — Stone 500 failed AA normal text at 4.09:1 on Foam 50; Stone 600 passes at 4.53:1. Flags generator palette drift between `mix crosswake.gen.offline_ui` and the canonical brand palette (tracked as NORM-01, future milestone). No breaking changes to route policy, bridge contracts, or offline island APIs.

---

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

### Suite brand note

The szTheory suite (Sigra, Parapet, Chimeway, Threadline, Rindle, Rulestead) is Crosswake's natural companion ecosystem. Voice guidance: reference companion integrations as specific, opt-in seams — not as "works with everything." When mentioning companions, name the specific value: "Threadline adds audit trails for mobile-originated actions" is the right frame. Do not bundle them into a "powerful ecosystem" claim.

## §11 Landing Page and Docs Blueprint

**Verdict: The brand book's §14 and §16 provide the right IA. This section tightens it into an actionable page architecture with explicit copy targets per section.**

### Landing page architecture

**Page 1: Landing (`/`)**

| Section | Content | Visual treatment | CTA |
|---------|---------|-----------------|-----|
| **Hero** | Headline: "Phoenix routes, native where it matters." Subheadline: route policy in one sentence. | Dark Current 950 bg, Wake Mark, sounding lines at <12% opacity, Space Grotesk 56px headline | "Read the guide" (Wake 700) + "View examples" (secondary) |
| **The problem** | "Mobile screens do not all want the same runtime." 4 examples: dashboard stays LiveView, study loop goes offline island, camera capture goes native, billing goes adapter. | Light Foam 50, horizontal runtime lane strip diagram | No CTA — inform only |
| **The solution** | Route policy code block + visual route card beside it. Copy from §10 feature blurbs. | Light surface, Current 900 code block | "Generate a route policy" |
| **Runtime ladder** | 7-tier ladder: LiveView → LiveView+shell → bridge → cached → offline island → native screen → adapter. | Dark Current 950 strip, runtime-color ladder diagram | No CTA |
| **Capabilities and safety** | Capability registry, permission stories, cache-never, sensitive routes. Capability matrix specimen. | Light Foam 100, capability badge row | No CTA |
| **Examples** | 4 example apps: SaaS portal, offline study loop, field inspection, native audio. | Light surface, route card per example | "View examples" |
| **OSS trust** | GitHub link, Hex.pm link, security policy link, maintainer note. Non-commercial tone. | Foam 50, small, quiet typography | "View on GitHub" |
| **Install block** | `mix deps.get crosswake` + first route policy snippet | Current 900 code block, Foam 50 bg | "Read the full guide" |

**Critical anti-pattern:** No hero device mockup showing a generic mobile app screen. The hero visual is the Wake Mark and/or a route-seam diagram. The product is the architecture; the diagram is the product.

---

### Docs architecture

**Top-level IA (matches brand book §14):**

```
docs/
├── Start
│   ├── What Crosswake is          ← one-sentence definition; what it is NOT; first route policy
│   ├── Install                    ← mix.exs + setup
│   ├── First route policy         ← 5-minute walkthrough
│   └── First native shell         ← iOS/Android bootstrap entry point
├── Concepts
│   ├── Runtime ownership          ← the capability ladder explained
│   ├── Route policy               ← DSL reference
│   ├── Capabilities               ← registry, allowlists, permission stories
│   ├── Bridge contracts           ← semantic messages, versioning, fail-closed behavior
│   ├── Offline islands            ← when to use, what you own, what reconciliation means
│   ├── Content packs
│   ├── Sync journals
│   └── Runtime compatibility      ← manifest, gates, version negotiation
├── Guides
│   ├── SaaS mobile shell
│   ├── Offline study loop
│   ├── Field inspection flow
│   ├── Native audio player
│   └── Billing/paywall adapter
├── Reference
│   ├── RoutePolicy DSL
│   ├── Capabilities API
│   ├── NativeScreens
│   ├── Manifest schema
│   └── Mix tasks
├── Adapters
│   ├── iOS
│   ├── Android
│   ├── Billing
│   └── Media
└── Security
    ├── Origin policy
    ├── Route allowlists
    ├── Capability allowlists
    ├── Sensitive routes
    └── Cache policy
```

---

### Docs page template (every concept page)

1. **One-sentence definition** — what is this, in plain language.
2. **When to use it** — concrete trigger condition.
3. **When not to use it** — hard rule, not a hedge.
4. **Minimal code example** — paste-able, under 20 lines.
5. **Failure modes** — what breaks, how it breaks, what the error says.
6. **Security/caching notes** — if relevant.
7. **Testing fixtures** — how to test this in CI.
8. **Related concepts** — links to 2–4 related pages.

Failure modes appear before advanced customization on every page. This is a brand rule, not just a docs preference — it reflects the maintainer's OSS DNA.

---

### Dark/light split

Landing page: dark hero (Current 950) → alternating light/dark section strips. Docs pages: always light (Foam 50 base), dark code blocks. No pure-white (#FFFFFF) backgrounds — use Foam 50 (`#F7F1E6`) throughout for warmth and brand cohesion.

### Typography on docs pages

- Page title: `display.sm` (28px), Space Grotesk SemiBold.
- Section heading: `text.xl` (20px), Space Grotesk Medium.
- Body: `text.md` (16px), Atkinson Hyperlegible Next Regular.
- Code: `text.sm` (14px), JetBrains Mono Regular.
- Warning boxes: Atkinson Hyperlegible Next, Brass 700 on Foam 100 border-left strip.

### Docs warning box copy rule

Warning boxes are for boundary mistakes, not tips. The brand book's example is the model:

> **Boundary warning:** `offline: :read_write` does not mean the server accepted the action. Use a sync journal and show pending state until the server reconciles the event.

"Tip" and "Note" callout boxes that contain non-critical information should be plain inline paragraphs — not styled callout boxes. Callout boxes are reserved for boundary warnings and security notes.

## §12 Repo-Ready Artifact Plan

**Verdict: The brandbook/ directory structure is established in Phase 102. This section defines committed vs generated vs not-committed status for every planned artifact so future phases do not guess.**

### Directory structure

```
brandbook/
├── AUDIT.md                        ← committed; source of truth for verdicts
├── tokens/
│   ├── crosswake.tokens.json       ← committed; W3C DTCG source of truth
│   └── tokens.css                  ← committed (GENERATED — do not edit directly)
├── tools/
│   ├── contrast.mjs                ← committed; zero-dep Node script
│   ├── compile-tokens.js           ← committed; zero-dep Node script (<80 LOC)
│   └── node_modules/               ← NOT committed (.gitignore)
├── logo/                           ← Phase 103 output
│   ├── wake-mark.svg               ← committed; path-only, tournament-selected
│   ├── lockup-horizontal.svg       ← committed; path-only
│   ├── lockup-stacked.svg          ← committed; path-only
│   └── favicon.svg                 ← committed; 2-stroke simplified version
├── specimens/                      ← Phase 103/105 output
│   ├── route-card-light.svg        ← committed; P1 specimen
│   ├── runtime-ladder-dark.svg     ← committed; P1 specimen
│   └── ...                         ← further specimens per §9 priority table
├── social/
│   └── og-card.svg                 ← Phase 106; committed path-only SVG
├── index.html                      ← Phase 105; standalone brand book (no build step)
└── BRAND-SPEC.md                   ← Phase 105; v1.0 successor to prompts/ draft
```

### Committed vs generated vs not-committed

| Artifact | Status | Rule |
|----------|--------|------|
| `brandbook/AUDIT.md` | **Committed** | Source of truth; never auto-generated |
| `brandbook/tokens/crosswake.tokens.json` | **Committed** | Source of truth; edit this, never tokens.css |
| `brandbook/tokens/tokens.css` | **Committed (generated)** | Header: `/* GENERATED from crosswake.tokens.json — do not edit */`. Regenerate by running `node brandbook/tools/compile-tokens.js`. |
| `brandbook/tools/contrast.mjs` | **Committed** | Reproducibility dependency; zero deps |
| `brandbook/tools/compile-tokens.js` | **Committed** | Build tooling; zero npm deps |
| `brandbook/tools/node_modules/` | **NOT committed** | `.gitignore` entry: `/brandbook/tools/node_modules/` |
| `brandbook/tools/fonts/` | **NOT committed** | `.gitignore` entry: `/brandbook/tools/fonts/` |
| `brandbook/logo/*.svg` | **Committed** | Phase 103 output; path-only, no `<text>` |
| `brandbook/specimens/*.svg` | **Committed** | Phase 103/105 output; path-only |
| `brandbook/social/og-card.svg` | **Committed** | Phase 106 output |
| `brandbook/index.html` | **Committed** | Phase 105 output; single-file, no build step |
| `brandbook/BRAND-SPEC.md` | **Committed** | Phase 105 output |

### Naming conventions

- All files: lowercase with hyphens. No spaces. No camelCase.
- SVG files: descriptive noun-phrase names (`route-card-light.svg`, not `spec1.svg`).
- Token JSON keys: lowercase dot-separated (`primitive.current.950`, `text.muted`).
- CSS variables: `--cw-{tier}-{role}-{variant}` pattern.

### README links (when Phase 103/105 artifacts exist)

- `brandbook/AUDIT.md` — link from the repo's top-level `README.md` under a "Brand & Design" section (Phase 106).
- `brandbook/tokens/tokens.css` — link as the token reference for adopters building Phoenix UI that aligns with Crosswake's visual system.
- `brandbook/logo/` — link to the logo lockup variants with usage guidance.

### CI checks

- **Advisory:** `node brandbook/tools/contrast.mjs` — reproduces the WCAG matrix in Appendix A. Output is advisory (print, do not fail); failure would indicate a palette change that must go through AUDT-04 ratification before merging.
- **No automated brandbook CI lane required this milestone.** The token compile step is a pre-commit developer responsibility: `node brandbook/tools/compile-tokens.js` then commit both JSON and CSS.

### Package exclusion

`mix.exs` `:files` allowlist is strict. `brandbook/` is auto-excluded: none of its contents are in the allowlist. No action needed — this was verified in Phase 102 research. The `<1 MB committed` budget for `brandbook/` is the size constraint; enforce by checking before each Phase 103/105/106 commit: `du -sh brandbook/`.

### Suite brand note

`brandbook/AUDIT.md` and `brandbook/tokens/crosswake.tokens.json` are Crosswake-specific artifacts. The szTheory suite's shared design language (typography, spacing, icon geometry, badge styles) will be derived from Crosswake's token system when per-library audits run for Sigra, Parapet, Chimeway, etc. The shared layer does not exist as a committed artifact yet. Crosswake's token naming (`--cw-` prefix) is library-scoped to prevent collision when companion libraries publish their own tokens.

## §13 Prioritized Action Plan

Synthesized from §3–§6 verdicts. Every action is value-tied. No churn for churn's sake.

---

### Do now (blocking; Phase 103 cannot start without these)

**1. Ship tokens.json + tokens.css + Stone 600** *(Phase 102 Plans 02–03 — complete)*
Stone 500 on Foam 50 fails AA normal text (4.09:1). Stone 600 (`#756D63`) is the math-forced remediation (4.53:1 PASS). The token compile step is a developer pre-commit responsibility. Both files are committed as a unit; `tokens.css` carries the `/* GENERATED */` header.

**2. Deliver the completed AUDIT.md** *(This plan — Phase 102 Plan 04)*
The full 14-section audit is the specification document that everything downstream builds against. §7 is the token spec. §8 is the tournament brief. §10 is the copy library. No Phase 103 work begins without a complete audit.

**3. Ratify audit-driven font/color changes** *(AUDT-04 checkpoint — this plan)*
D-12 requires explicit user ratification before Phase 103 consumes the verdicts. Typography is frozen (Space Grotesk + Atkinson Hyperlegible Next + JetBrains Mono — no changes). Stone 600 addition is math-forced (unilateral — listed for transparency). The D-11 mandatory wake-cut rider on the wordmark and the §8 logo direction freeze require the AUDT-04 blocking gate. Phase 103 is blocked until this checkpoint resolves.

---

### Do next (Phase 103 — after AUDT-04 ratification)

**4. Run the Phase 103 logo tournament**
Four logomark concepts + three integrated typemarks. Tournament must produce: wake-mark.svg, lockup-horizontal.svg, lockup-stacked.svg, favicon.svg — all path-only, no `<text>`. D-11 wake-cut rider is mandatory: candidates without custom `w`/`k` letterform cuts are disqualified. Tournament ends with a blocking user-selection checkpoint in Phase 103.

**5. Produce P1 specimens**
Route card light (`brandbook/specimens/route-card-light.svg`) and runtime ladder dark (`brandbook/specimens/runtime-ladder-dark.svg`) are the two highest-value explanatory artifacts. Both can be produced before logo ratification. Do not defer these to Phase 105 — they are needed for the README and landing page.

**6. Specify the social preview card (§6 upgrade)**
The OG card spec exists in §6. The committed file is a Phase 106 deliverable — but the spec must be agreed before Phase 105 executes the HTML brand book. Confirm the spec is approved at AUDT-04 ratification.

---

### Defer (value-positive; not blocking in this milestone)

**7. NORM-01: Normalize generator templates onto tokens.css**
`mix crosswake.gen.offline_ui` emits a Tailwind config snippet with wrong color values (blue/amber instead of the canonical teal/brass palette). This is an AUDT-03 flag, not a Phase 102 fix. Fix tracked as NORM-01 in a future milestone. The generator still works; adopters using the emitted snippet will get wrong colors until this is resolved.

**8. ExDoc sidebar active/hover state tokens**
The ExDoc theme sidebar has active/hover states that are not yet mapped to specific semantic tokens. This is a Phase 105 concern when the HTML brand book and ExDoc theme are being built. The token system has the right primitives; mapping to ExDoc CSS classes is straightforward but not needed before Phase 105.

**9. Conference slide template**
High-leverage for ElixirConf/Code BEAM adoption but not blocking Phase 103 or Phase 105. Phase 105 HTML brand book should include a slide section if the milestone permits; otherwise defer to v10.0.

**10. Mobile landing page breakpoints**
§6 upgrade specifies the breakpoints (`sm`=640px, `md`=768px, `lg`=1024px, `xl`=1200px). These do not require a committed artifact until the actual landing page is built in a future milestone.

---

### Do not do

**11. Full palette REWORK to shift emotional character**
The coastal-muted palette (Current/Foam/Wake/Brass/Rust families) is frozen. A color-family replacement would cascade into all specimens, Phase 103 logo candidates, and generated CSS — substantial cost with no material brand gain. The palette avoids every adjacent competitor pitfall already. If AUDT-04 ratification produces an amendment request, the audit author will evaluate it against this cost ceiling.

**12. Font swap from Space Grotesk**
The display font is frozen (D-12). Market saturation concerns are acknowledged and mitigated by the mandatory D-11 letter cuts. Swapping fonts would invalidate the letterform-cut brief, all Phase 103 tournament work, and every specimen that uses the wordmark. The only exit from Space Grotesk is if the custom letter cuts prove impossible in Phase 103 — in which case the Phase 103 executor surfaces a checkpoint, not a unilateral swap.

**13. Component-level design tokens**
The token system deliberately stops at the semantic tier (29 tokens, hard cap 30 — exactly 1 slot remains as of Phase 155). Adding component-level tokens (button.bg, card.border, etc.) creates naming churn and fragments the public contract without measurable benefit at the library boundary. This is an explicit anti-feature per the D-06 decision.

**14. Animated hero or motion design this milestone**
Motion guidance exists in the brand book (§18). Motion assets are not a Phase 102–106 deliverable. Do not invest in animated hero sequences or wave-line animations until the static identity is complete and verified.

**15. Mascot or character**
The brand book's §17 explicitly warns against "overly cute mascots." Crosswake's visual identity is architectural, not character-driven. There is no brief for a mascot. Do not introduce one.

## §14 Final Quality Gate

This checklist answers the brief's gate questions. Every item must be satisfied before this phase closes and Phase 103 begins.

### Designer can build from this?

- [x] Palette is specified to hex precision with WCAG contrast ratios printed next to pairings.
- [x] Typography stack is named with exact weights, fallback stacks, and type scale values.
- [x] Token system (§7) provides a structured, two-tier DTCG JSON source plus generated CSS — no guessing the variable names.
- [x] Logo geometry is specified with measured constraints (angle, stroke weight, line count, notch, cap style, minimum sizes).
- [x] Dark-mode surface hierarchy is defined (§6 color upgrade table).
- [x] Component and specimen types are enumerated (§9) with paths and formats.

### Engineer can implement from this?

- [x] `brandbook/tokens/tokens.css` is a committed file with `--cw-*` variables ready to import.
- [x] Dark-mode theming model is explicit: `:root` light, `@media` system dark, `[data-theme="dark"]` explicit toggle.
- [x] State handling (hover/focus/active/disabled/selected/status) is fully covered without requiring new tokens (§7 12-state mapping).
- [x] Token JSON is W3C DTCG 2025.10 — engineers can run the compile script to regenerate CSS from source.
- [x] Copy blocks (§10) are ready to paste — no engineer should have to write marketing copy at implementation time.

### Maintainer can keep consistent?

- [x] Single source of truth: edit JSON → run script → commit both. The `/* GENERATED */` header guards against direct CSS edits.
- [x] Size budget constraint: `<1 MB committed` for all of `brandbook/` — checkable with `du -sh brandbook/`.
- [x] WCAG matrix is reproducible: `node brandbook/tools/contrast.mjs` — any future palette change can be checked immediately.
- [x] D-12 frozen items are documented: display font, palette character, wake-seam concept, diagonal crossing-mark direction. Maintainers know what cannot change without ratification.
- [x] Deferred items (NORM-01, AUDT-03 generator drift) are tracked in the planning state and not hidden.

### Contributor can understand?

- [x] AUDIT.md §1 executive judgment is decisive: a contributor can read the first two paragraphs and understand what is strong, what must not change, and what is in progress.
- [x] Every REWORK verdict (none issued in §6 — only TIGHTEN/ADD) carries a stated cost. Hypothetical REWORK cost is explicitly documented in §6.
- [x] The D-11 mandatory rider is stated plainly and repeated in §7, §8, and the ratification checkpoint. A contributor cannot miss it.
- [x] The AUDT-03 generator drift flag is in §5 with a severity label and a cost statement. It is not hidden.

### Marketing without cheese?

- [x] One-liner uses "route policy" and "Phoenix apps that go mobile" — accurate, specific, no hype words.
- [x] CTA copy is verb-first and action-specific ("Read the guide," "Generate a route policy").
- [x] Feature blurbs (§10) are all grounded in a concrete mechanism: "directly in the route definition," "the manifest tells the shell," "explicit contracts."
- [x] "Why this exists" bullets name what the alternatives hide and why that matters — not a generic better/faster/easier claim.
- [x] No occurrence of: powerful, seamless, next-generation, magical, game-changing, one codebase, write once.

### Survives dark mode?

- [x] Semantic tier flips in dark mode; primitives never change.
- [x] `text.muted` on dark → Mist 200 (12.25:1 on Current 950 PASS). Stone 600 is excluded from dark-surface text use.
- [x] Dark-mode surface hierarchy is defined: surface.default → Current 950, surface.raised → Current 900, surface.inset → Current 800, surface.inverse → Foam 50.
- [x] Code block dark treatment is complete and specific (background, text, comments, keywords, strings, errors).
- [x] Focus ring is 2px, visible in both modes (`--cw-action-focus-ring`).

### Survives small sizes?

- [x] Logo has a dedicated 2-stroke favicon variant for ≤16px.
- [x] Icon mark minimum size is 24px; full lockup minimum is 128px wide.
- [x] D-11 letter-cut rider is stated: simplified marks must still read as Crosswake.
- [x] Token scale bottoms out at `text.xs` (12px/16px) for badges/metadata — nothing goes below 12px.
- [x] Wake Mark geometry at 16px: simplify to 2 strokes (constraint documented in §8).

### Survives docs surfaces?

- [x] Docs page template is defined (§11): definition → when to use → when not to → code → failure modes → security → testing → related.
- [x] Warning box style is specified and restricted to boundary mistakes only (not tips).
- [x] Typography on docs pages is specified: page title, section heading, body, code, warning box.
- [x] Docs IA (§11) covers Start → Concepts → Guides → Reference → Adapters → Security.
- [x] Hex.pm description is ready to paste (§10, 140 chars, no hype words).

### Survives social/sharing?

- [x] OG card spec is defined in §6: 1200×630px, Current 950 background, Wake Mark in Foam 50, wordmark, one-liner, version badge.
- [x] GitHub repo description is ready (§10, ≤ 300 chars, accurate and specific).
- [x] Social-safe colorways: Current 950 dark bg with Foam 50 text passes 16.58:1 — every link share will use a legible preview.

### Specific to this library (not generic devtools)?

- [x] `runtime.*` semantic tokens are a Crosswake-unique tier — no other devtools design system has a runtime-ownership semantic layer.
- [x] Wake-seam motif encodes the product's core concept (route crossing a runtime boundary) into the visual system.
- [x] "Declare the crossing. Keep the boundary honest." is a product-specific promise, not a general devtools tagline.
- [x] Copy blocks reference concrete product mechanisms: route policy, offline island, native screen, capability registry, bridge contract. None are generic.

### Avoids thrash?

- [x] No full-palette REWORK issued (stated explicitly in §6 and §13).
- [x] Display font frozen (D-12).
- [x] Stone 600 addition is math-forced and additive — no existing token changes, only a new primitive.
- [x] Semantic role corrections (Stone 500 narrowed, text.muted corrected) are token-level changes only; no visual regression for correctly-used tokens.
- [x] Component tokens explicitly excluded (anti-feature per D-06 decision) — future contributors cannot accidentally introduce them without a plan-level decision.
- [x] Phase 103 is strictly scoped to logo tournament + P1 specimens; it cannot consume the token system or copy blocks until AUDT-04 ratification completes.

---

**Gate result: PASS.** The brand system is complete enough to brief Phase 103. Every non-logo surface has a buildable specification. Every verdict is decisive. Every deferred item is tracked and bounded. AUDT-04 ratification is the final gate before Phase 103 begins.

**AUDT-04 ratification: Approved by maintainer 2026-06-11.** All audit-driven font/color verdicts are frozen. Phase 103 is unblocked.

---

## Appendix A: WCAG Contrast Matrix

Matrix is reproducible: `node brandbook/tools/contrast.mjs`. 21 pairings tested; 4 fail AA normal text (< 4.5:1); of those, 1 is a true hex defect (stone-500/foam-50), 3 are role issues documented via `$description` restrictions in the token JSON.

| Foreground | Background | Ratio | AA | AAA |
|------------|------------|-------|-----|-----|
| foam-50 | current-950 | 16.58:1 | PASS | PASS |
| current-950 | foam-50 | 16.58:1 | PASS | PASS |
| white | wake-700 | 5.45:1 | PASS | FAIL |
| current-950 | brass-500 | 6.35:1 | PASS | FAIL |
| wake-500 | current-950 | 5.62:1 | PASS | FAIL |
| wake-700 | foam-50 | 4.85:1 | PASS | FAIL |
| white | rust-600 | 6.02:1 | PASS | FAIL |
| foam-50 | plum-700 | 11.38:1 | PASS | PASS |
| **stone-500** | **foam-50** | **4.09:1** | **FAIL** | **FAIL** |
| stone-600 | foam-50 | 4.53:1 | PASS | FAIL |
| stone-600 | white | 5.09:1 | PASS | FAIL |
| brass-700 | foam-50 | 4.74:1 | PASS | FAIL |
| wake-500 | foam-50 | 2.95:1 | FAIL | FAIL |
| mist-200 | foam-50 | 1.35:1 | FAIL | FAIL |
| foam-50 | current-900 | 15.14:1 | PASS | PASS |
| mist-200 | current-950 | 12.25:1 | PASS | PASS |
| wake-500 | current-900 | 5.14:1 | PASS | FAIL |
| brass-500 | current-950 | 6.35:1 | PASS | FAIL |
| white | kelp-800 | 12.32:1 | PASS | PASS |
| white | harbor-700 | 9.83:1 | PASS | PASS |
| stone-600 | current-950 | 3.66:1 | FAIL | FAIL |

**21 pairings tested. 4 fail AA normal text (< 4.5:1). 14 fail AAA normal text (< 7:1).**

**Remediation note:** stone-500/foam-50 (4.09:1) is the only true hex defect — fixed by adding Stone 600 and mapping `text.muted` → Stone 600 (4.53:1 PASS). The other three failures are role issues, not hex defects:

- `wake-500/foam-50 (2.95:1)` — Wake 500 is a dark-surface accent; using it as light-surface text is a role misuse. Restriction encoded in `$description`.
- `mist-200/foam-50 (1.35:1)` — Mist 200 is a border and dark-surface text color. Restriction encoded in `$description`.
- `stone-600/current-950 (3.66:1)` — Passes AA non-text (3:1); fails AA normal text. Stone 600 is light-mode-only for text. On dark, `text.muted` maps to `mist-200` (12.25:1 PASS). Stone 600 permitted for non-text elements (borders, decorative) on dark surfaces.

Ratios computed using WCAG 2.2 relative luminance formula with linearization threshold 0.04045 (corrected May 2021).
