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

_(pending)_

## §6 Recommended Brand Book Upgrades

_(pending)_

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

### Tier 2: Semantic Tokens (27 total — within D-06 hard cap of 30)

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
| `--cw-action-focus-ring` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-wake-500)` |

#### border (3 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-border-default` | `var(--cw-primitive-mist-200)` | `var(--cw-primitive-harbor-700)` |
| `--cw-border-subtle` | `var(--cw-primitive-foam-100)` | `var(--cw-primitive-current-800)` |
| `--cw-border-strong` | `var(--cw-primitive-wake-700)` | `var(--cw-primitive-mist-200)` |

#### status (4 tokens)

| Token | Light value | Dark value |
|-------|-------------|------------|
| `--cw-status-success` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` |
| `--cw-status-warning` | `var(--cw-primitive-brass-700)` | `var(--cw-primitive-brass-500)` |
| `--cw-status-error` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` |
| `--cw-status-info` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` |

#### runtime (5 tokens — Crosswake-unique tier)

The `runtime.*` tier is the single most important differentiator in this token system. No other devtools brand book has a runtime-ownership semantic tier. These tokens encode the library's core contract — which UI belongs to which runtime — into the CSS layer itself. They are not status colors dressed up with names; each maps to a distinct semantic role in the Crosswake capability ladder.

| Token | Light value | Dark value | Semantic role |
|-------|-------------|------------|---------------|
| `--cw-runtime-liveview` | `var(--cw-primitive-harbor-700)` | `var(--cw-primitive-mist-200)` | LiveView server-centric runtime |
| `--cw-runtime-offline` | `var(--cw-primitive-kelp-800)` | `var(--cw-primitive-wake-500)` | Offline island runtime |
| `--cw-runtime-native` | `var(--cw-primitive-brass-500)` | `var(--cw-primitive-brass-500)` | Native screen ownership |
| `--cw-runtime-sensitive` | `var(--cw-primitive-rust-600)` | `var(--cw-primitive-rust-600)` | Sensitive / cache-never routes |
| `--cw-runtime-bridge` | `var(--cw-primitive-plum-700)` | `var(--cw-primitive-foam-50)` | Bridge contract surface |

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

_(pending)_

## §9 Visual Examples and Screenshot Guidance

_(pending)_

## §10 Brand Voice and Microcopy

_(pending)_

## §11 Landing Page and Docs Blueprint

_(pending)_

## §12 Repo-Ready Artifact Plan

_(pending)_

## §13 Prioritized Action Plan

_(pending)_

## §14 Final Quality Gate

_(pending)_

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
