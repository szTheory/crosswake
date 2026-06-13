# Phase 102 Audit Brief — Brand Book Pressure Test Specification

**Source:** User-supplied pressure-test prompt (verbatim intent preserved, condensed for execution). This is the specification for `brandbook/AUDIT.md` (AUDT-01). The executor acts as: senior brand systems director, product designer, UI/UX lead, developer advocate, design-token architect, and OSS maintainer with strong taste in developer tools, Elixir libraries, technical documentation, and high-signal marketing.

**Subject:** `prompts/crosswake-brand-book.md` (the seed brand book), grounded against `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-research-synthesis.md`, and `prompts/crosswake-integrations-and-companions.md`.

**Prime directive:** All killer, no filler. Do not create churn for no reason. Preserve what is already strong. Only recommend changes that materially improve clarity, distinctiveness, usability, accessibility, developer trust, implementation readiness, or brand-system coherence. Produce the critical audit BEFORE generating or rewriting anything.

## Decision framework (every element gets a verdict)

- **KEEP** — strong, do not change
- **TIGHTEN** — directionally right; needs sharper wording, better constraints, clearer examples, or implementation details
- **REWORK** — generic, contradictory, inaccessible, hard to execute, or off-strategy. **Every REWORK requires a stated cost** (what it forces downstream)
- **ADD** — missing section/artifact that would make the brand book more useful
- **REMOVE** — fluff, vague language, decorative rules, redundant sections, maintenance burden without value

## Analysis lenses (the 10 lenses; map onto the 14 output sections below)

1. **Strategic distinctiveness** — meaningfully distinct from adjacent OSS/devtools/Elixir projects? Avoids generic tropes (abstract gradients, meaningless nodes, fake futurism, unjustified hexagons, blue-purple sameness, vague innovation language)? Strong conceptual center? Recognizable without the name?
2. **Developer credibility** — trustworthy to engineers? No over-marketing, hype, enterprise fluff, visual gimmicks? Voice fits OSS norms: precise, useful, confident, generous, technically literate, low-BS? Credible on GitHub, Hex.pm, HexDocs, conference slides, social previews?
3. **Elixir ecosystem fit** — appropriate for BEAM-adjacent audiences, Phoenix/LiveView users, pragmatic engineers? Respects ecosystem taste: thoughtful, durable, understated, technically elegant? Supports README heroes, HexDocs, Livebook examples, changelogs, release notes, package metadata?
4. **Graphic design quality** — coherent visual language? Colors/typography/spacing/iconography/layout/logo/imagery specific enough to execute? Decisions justified by brand concept or arbitrary? Palette works light/dark/print/low-contrast/small surfaces? Right amount of constraints (not too few → inconsistency; not too many → fragility)?
5. **UI/UX buildout usefulness** — can a designer/engineer build real interfaces from it? Design tokens or tokenizable primitives? Semantic color roles, not just raw colors? States defined (hover/active/focus/disabled/success/warning/error/info/selected/muted/subtle/emphasized)? Components covered (buttons, cards, alerts, code blocks, callouts, nav, tabs, badges, feature grids, comparison tables, install snippets, terminal blocks, diagrams, empty/error states)?
6. **Accessibility & durability** — WCAG contrast expectations met (use the scripted matrix)? Accessible alternatives for decorative color? Logo works at favicon size, in monochrome, on transparent/light/dark/colored backgrounds? Typography practical, readable, license-safe? No proprietary assets or hard-to-reproduce effects?
7. **Brand voice & UX microcopy** — specific enough to guide README/docs/errors/landing/release notes/issue templates/CLI output/UI labels? Say-this/not-this examples? Distinguishes marketing/docs/error/success/warning/empty-state voices? Taglines, one-liners, short/long descriptions, package blurbs ready for use?
8. **Marketing & positioning** — could produce a compelling landing page? Clarifies audience, problem, promise, proof, differentiators, use cases, objections, CTAs? Copy blocks for: GitHub repo description, README intro, Hex.pm description, HexDocs intro, landing hero, social preview, launch post, changelog announcement? No unbacked "powerful/simple/robust/seamless/next-generation"?
9. **Artifact readiness** — convertible into committed repo files? Durable, text-based, source-controllable artifacts (SVG, JSON tokens, CSS variables, markdown, templates)? File names, directory structure, asset formats recommended?
10. **Multi-library brand architecture** — distinct per-library while belonging to the szTheory suite (sigra, parapet, rindle, chimeway, threadline…)? What's shared (typography, layout grid, docs patterns, badge styles, icon geometry, naming, release-note style) vs unique? Avoid identical-twins AND unrelated-strangers failure modes.

## Required output structure for brandbook/AUDIT.md (14 sections)

1. **Executive judgment** — direct, opinionated: strong enough to build from? distinct enough? implementation-ready? over/under-specified or balanced? highest-leverage improvement? what must NOT change?
2. **Brand DNA extraction** — essence, audience, emotional tone, technical promise, visual metaphor, personality traits, anti-traits, design principles, voice principles, "should feel like…", "should never feel like…" (mark inferred items)
3. **Pressure-test scorecard** — 1–10 scores with Why/Risk/Fix for: distinctiveness, developer credibility, Elixir ecosystem fit, visual coherence, logo readiness, color-system readiness, typography readiness, design-token readiness, UI component readiness, docs/README usefulness, marketing usefulness, voice/microcopy usefulness, accessibility, repo/source-control readiness, long-term maintainability
4. **Stress tests** — per surface, is guidance sufficient and what's missing: GitHub repo header, README hero, README badges, Hex.pm page, HexDocs page, docs sidebar, code block styling, terminal snippet, API reference, landing hero, feature section, comparison section, blog post header, release announcement, social preview card, favicon, app icon, small monochrome logo, dark-mode page, light-mode page, conference slide, architecture diagram, error/empty/success states, example UI components, mobile landing, sticker/swag (only if appropriate)
5. **Gaps and risks** — Critical (blocks execution) / Important (quality issues later) / Nice-to-have. Strict, no filler.
6. **Recommended brand book upgrades** — rewrite/expand ONLY sections that need work
7. **Design token specification** — the locked spec (see CONTEXT.md decisions; tokens.json + tokens.css are the deliverable)
8. **Logo and mark system** — evaluate logotype/symbol/combination/monogram options; define the system the tournament must produce (variants, clearspace, min sizes, usage/misuse). Tournament itself is Phase 103.
9. **Visual examples and screenshot guidance** — what specimens are worth producing (purpose/layout/format/path/when-worth-it); no decorative screenshots
10. **Brand voice and microcopy** — verdict + concrete ready-to-use copy: one-liner, 140-char description, GitHub repo description, Hex.pm description, README opening, landing hero headline + subheadline, CTAs, three feature blurbs, three "why this exists" bullets, example error/empty/success states, example release announcement
11. **Landing page and docs blueprint** — practical page architecture tied to voice + visual system
12. **Repo-ready artifact plan** — committed vs generated vs not-committed, naming conventions, README links, CI checks
13. **Prioritized action plan** — Do now / Do next / Defer / Do not do (concrete, value-tied)
14. **Final quality gate** — checklist: designer can build? engineer can implement? maintainer can keep consistent? contributor can understand? marketing without cheese? survives dark mode/small sizes/docs/social? specific to this library? avoids thrash?

## Behavior constraints

- No flattery unless earned; no false certainty; mark assumptions explicitly
- Fewer, stronger recommendations; concrete; tastefully critical
- No full redesign unless the system truly fails (it does not — preserve the strong core)
- License-safe fonts only; no embedded font files; reproducible imagery only
- Flag legal/trademark concerns (e.g., Crosswalk project name adjacency) for human review rather than pretending to resolve them

## Be especially skeptical of

Generic palettes · unjustified gradients · trendy-fragile effects · logo concepts that don't scale · mascots without reason · abstract marks with no meaning · SaaS-sounding voice guidelines · marketing copy that hides technical value · raw-color-only tokens · inspirational-but-unbuildable sections · ego artifact lists · any recommendation causing thrash without clear payoff
