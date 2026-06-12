/**
 * gallery-content.mjs
 * Per-candidate metadata consumed by build-gallery.mjs.
 * Edit this file to update rationale, risk, and recommendation text.
 * Run `node brandbook/tools/build-gallery.mjs` to regenerate index.html.
 */

// ─── Round 2 candidates ────────────────────────────────────────────────────────

export const round2Candidates = [
  {
    id: 'R2-A',
    name: 'A + T1 Wordmark',
    concept: 'Canonical Wake Mark paired with systematic 20-degree terminal cuts on w, k, r, and a — the angle becomes the wordmark DNA.',
    rationale:
      'The round-1 type failures (E/F/G) applied local surgery to one letter against eight stock. T1 fixes this by applying the same 20-degree cut angle to the natural outer tips of four letters: w outer tips, k arm and leg, r arm, and a tail. No single letter is singled out. At reading speed the cuts do not register as modifications — they read as typographic character. At display size the geometric echo of the Wake Mark angle is clear. The mark is unchanged; the variable under test is the wordmark treatment.',
    risk:
      'At 16px rendered, the terminal cuts close into the stroke and disappear — the wordmark reads as stock Space Grotesk. This is correct behavior and acceptable: the identity is preserved at any size, and the cut enrichment is a display-size reward. Risk of "looks like a typo" is LOW because all four modified letters have the same cut geometry at natural anatomical endpoints.',
    feedbackResponse:
      'Round-1 rejection: "w looks weird, doesn\'t fit with other letters." T1 response: shifted from inner-valley cuts (most visually active points) to outer tips (anatomically natural endpoints). Expanded from one letter to four. The eye now compares w-k-r-a and finds consistent angular language, not an isolated anomaly.',
    hasLockups: true,
    markFile: 'A.svg',
    lockupHorizFile: 'R2-A-lockup-horizontal.svg',
    lockupStackedFile: 'R2-A-lockup-stacked.svg',
  },
  {
    id: 'R2-B',
    name: 'B2 + T1 Wordmark',
    concept: 'Seam Shift recalibrated (3.76u step, calmer energy) paired with T1 systematic terminal cuts — the step and the cuts share the same 20-degree angle DNA.',
    rationale:
      'Mark B was "more energetic" — the question is whether that energy is on-brand. B2 answers by reducing the seam connector step from 5.64u to 3.76u perpendicular displacement. The step now reads as a precise instrument correction, not a dramatic shift. The wake lines remain at 24u. Paired with T1 wordmark cuts, the 20-degree angle language is coherent from mark to type: both the step direction and the cut faces are perpendicular to the same canonical wake angle.',
    risk:
      'The step, even at 3.76u, may still read as "dynamic" rather than "calm" at display sizes. Below 24px the step merges with the route into a bent line — evaluate at 24px and 48px specifically. The T1 wordmark adds type-level complexity; verify the combination does not feel over-designed.',
    feedbackResponse:
      'Round-1 assessment: B "seems more energetic — u decide if that\'s on or off brand." B2 response: energy is on-brand at controlled scale. Step reduced for precision. Paired with T1 (same angular DNA) to unify mark and wordmark language. Gallery shows at identical scale as R2-A for direct comparison.',
    hasLockups: true,
    markFile: 'B2.svg',
    lockupHorizFile: 'R2-B-lockup-horizontal.svg',
    lockupStackedFile: 'R2-B-lockup-stacked.svg',
  },
  {
    id: 'R2-C',
    name: 'A + Seam-Step Line',
    concept: 'Canonical Wake Mark with stock letterforms plus a single horizontal route line that steps down 5u at the cross|wake word boundary — the wordmark declares the crossing.',
    rationale:
      'T2-A is the single-gesture alternative: every letterform is completely stock. The design statement is the underline alone. At the midpoint between the second s and the w (x=188, the "cross|wake" linguistic seam), the horizontal line performs a 5-unit perpendicular step and continues. The step visualizes the seam at the exact semantic boundary in the word itself. No letterform modification needed — the composition is the identity. Mark A is clean precisely because the wordmark is doing all the narrative work.',
    risk:
      'The underline needs precise weight calibration — too heavy and it competes with the wordmark; too light and it becomes invisible, especially at reduced sizes. Below 64px wide, the step jog may disappear entirely and the line reads as a plain underline. Gallery shows this at 32px width to surface the failure mode. Minimum recommended lockup width: 64px.',
    feedbackResponse:
      'Round-1 type rejections were all about letterform modifications. T2-A responds by making zero letterform modifications. The gestural route line is entirely compositional — same principle as placing mark A next to the wordmark, but the composition is integrated into the wordmark itself. Avoids the "looks like a typo" failure class entirely.',
    hasLockups: true,
    markFile: 'A.svg',
    lockupHorizFile: 'R2-C-lockup-horizontal.svg',
    lockupStackedFile: null,
  },
  {
    id: 'R2-D',
    name: 'O-Port Typemark',
    concept: 'Stock letterforms + a 20-degree route line that visibly passes through the o counter. Exploratory standalone — no mark lockup.',
    rationale:
      'T2-B positions the o as the crossing gate: the only closed letter in "crosswake," it becomes a physical port through which the route passes. The route line merges with the filled walls (both currentColor) and is visible inside the open counter, creating the read of a route emerging from the letter walls. This is composition, not surgery: the o path is completely unchanged. The detail is self-contained within one letter — not a system across multiple glyphs, not an underline. Standalone wordmark only per pairing rules.',
    risk:
      'HIGH risk at small sizes: below 20px rendered, the route inside the counter may read as a broken o (damaged letterform) rather than an intentional route crossing. Minimum size gate: 24px rendered. At 16px evaluate carefully — if the counter collapses into the wall weight, the route is invisible and the wordmark reads as stock. Flagged EXPLORATORY: this approach has the highest risk of reading as a typographic error.',
    feedbackResponse:
      'Addresses the round-1 local-surgery critique by using a fundamentally different mechanism: the route is a separate compositional element, not a modification to the letterform. The o is not changed. However, it still applies the design detail to one letter in isolation — this is the weakest response to the "local surgery" critique. Its strength is conceptual clarity (o as port), not systematic coherence.',
    hasLockups: false,
    markFile: null,
    lockupHorizFile: null,
    lockupStackedFile: null,
    typemarkFile: 'R2D-oport.svg',
    isExploratory: true,
  },
];

// ─── Round 1 candidates (kept for provenance) ───────────────────────────────

export const candidates = [
  {
    id: 'A',
    name: 'Canonical Wake Mark',
    concept: 'Pure route geometry: a notched navigation line trailed by two wake lines at 20°.',
    rationale:
      'Three parallel strokes — the route split by a 1.5x-stroke notch plus two receding wake lines — encode the Crosswake model (a packet traversing runtimes) without a single letterform. The geometry is irreducibly specific: notch position, 20° angle, and wake spacing are all derived from the system spec, not decoration. In one color or five colors, at 64px or 16px, it reads as motion with a purpose.',
    risk:
      'At 16px the notch gap (≈1.5px rendered) can close into a continuous line, losing the semantic break. The three parallel strokes may read as a generic progress indicator or "signal bars" to viewers unfamiliar with navigation iconography.',
  },
  {
    id: 'B',
    name: 'Seam Shift',
    concept: 'Route line steps perpendicular at the seam boundary — continuous momentum, visible join.',
    rationale:
      'Where A breaks the route, B shifts it: the route crosses the seam boundary at x=32 with a visible perpendicular step (6 units, one stroke-width) before continuing at the same 20° slope. This makes the seam a feature rather than a gap — the logo literally shows a route adapting at a boundary. Two trailing wake lines follow the post-seam segment, anchoring momentum.',
    risk:
      'The three-stroke cluster (pre-seam route + connector + post-seam route) reads as a zigzag at small sizes. Below 20px the perpendicular connector merges with the route, producing an ambiguous bent line rather than a deliberate step. May read as a construction artifact rather than intentional geometry.',
  },
  {
    id: 'C',
    name: 'Crossing Lanes',
    concept: 'Two runtime lanes gated by a continuous route line crossing between them.',
    rationale:
      'C escalates the runtime metaphor: two parallel strokes represent independent runtime tiers (lanes), each gated at the crossing point with a 1.5x-stroke notch, while the unbroken route line passes through both gates continuously. The image is a road crossing a double-track railway — presence acknowledged, flow uninterrupted. Communicates multiplicity and traversal simultaneously.',
    risk:
      'Five strokes in a small square reads as clutter. At 16px all five lines compress into a nearly-solid bar. The concept requires knowing that two of the strokes are "lanes" and one is the "route" — without context, it is simply a bundle of parallel lines at an angle.',
  },
  {
    id: 'D',
    name: 'Wake Monogram',
    concept: 'The letter C, counter broken by a 20° wake diagonal — favicon-first, 2-stroke simplicity.',
    rationale:
      'Designed from the favicon backward: at 16px this is two strokes — a C arc and a diagonal cut — and nothing gets lost. The C is deliberately not a standard C: the wake diagonal breaks the counter, making the glyph a Crosswake artifact rather than a letter. The choice of C over "cw" was deliberate; cw at 4×4 pixels is indistinct, while a single arc with a diagonal cut reads as a unique mark.',
    risk:
      'Without context, reads as a logo for any company whose name starts with C. The brand story (the diagonal is a wake angle, not a style choice) requires explanation. May be confused with a copyright symbol or a plain C lettermark at distance.',
  },
  {
    id: 'E',
    name: 'Wake-W Typemark',
    concept: 'The w letterform re-cut: deepened 20° apex slashes turn the w itself into a crossing glyph.',
    rationale:
      'E integrates the brand geometry into the wordmark letter that already carries the name — the w in "wake." Both inner w apexes are re-cut 5.84 units deeper than the baseline D-06 treatment, making the cuts read as deliberate slashes rather than typographic refinements. A trailing hairline wake exits the w\'s right shoulder at exactly 20° into the space before the a, creating visual momentum. The wordmark is the mark; no separate icon needed.',
    risk:
      'At 16px the deepened apex cuts in the w read as broken letterforms rather than designed geometry. The hairline wake (stroke-width 0.65–0.85) disappears entirely at small sizes. Wordmark-only identities are vulnerable to environments requiring square/icon formats — app icons, favicons, and monogram uses all require a separate derived asset.',
  },
  {
    id: 'F',
    name: 'Crossing-SS Typemark',
    concept: 'A route line at 20° crosses the full wordmark height, notched precisely at the cross|wake boundary.',
    rationale:
      'F is the most narratively explicit candidate: the route line enters from outside the wordmark, traverses its full height at 20°, and breaks with a 1.5x-stroke notch exactly at the semantic gap between "cross" and "wake" (x=192, between the second s and the w). The line is heavier than E\'s hairlines (stroke-width 1.8) so it registers against the wordmark mass without blending in. The concept is legible as a diagram before it is legible as a logo.',
    risk:
      'The route line visually bisects the wordmark and may read as a strikethrough or an editorial mark on the text, particularly on first encounter. At small sizes the notch break (≈0.5px gap at 16px) is invisible, making the line appear to slice the word. Intellectually precise, but may communicate "crossed out" rather than "crossing."',
  },
  {
    id: 'G',
    name: 'Terminal Cuts Typemark',
    concept: 'Quiet 20° clip marks at the four outermost w and k stroke terminals — the angle is there if you look.',
    rationale:
      'G is the deliberate restraint option: four tiny accent strokes (±2.5 units at 20°) clip the outer tips of w and k, plus a single notch on the w center column. At 256px these read as precise angular character — the kind of detail that rewards close inspection without announcing itself. At 16px the clips tighten the wordmark terminals without reading as separate elements. The wordmark remains essentially legible without design knowledge; the brand geometry rewards familiarity.',
    risk:
      'Too subtle: at normal reading sizes the terminal cuts are nearly invisible, and the wordmark reads as a typographic refinement rather than a branded mark. The system geometry story — 20° wake angle, route and runtime, cross and wake — is not communicated; it must be explained. Offers little distinctiveness over a standard Space Grotesk wordmark.',
  },
];

// ─── Round 2 maintainer recommendation ───────────────────────────────────────

export const round2Recommendation = {
  candidateId: 'R2-A',
  headline: 'Maintainer recommendation: R2-A — Canonical Wake Mark + T1 Wordmark',
  reasoning:
    'Evaluated on durability (works at 16px, in one color, in five years): R2-A is the most conservative candidate that directly answers the round-1 failure. The T1 wordmark treatment fixes exactly the diagnosed problem — local surgery becomes a system — while the mark geometry is unchanged and proven. At 16px the terminal cuts disappear and the wordmark reads as stock Space Grotesk; this is correct behavior. At display sizes the 20-degree cut language quietly echoes the Wake Mark without competing. R2-B is a strong alternative if the seam-step energy reads correctly at your target sizes — verify at 24px and 48px before committing. R2-C is the highest-concept candidate and the most fragile: the underline weight and step calibration are sensitive to the render environment. R2-D is exploratory and should not be ratified without testing at actual product sizes.',
};

// ─── Round 1 maintainer recommendation (preserved for reference) ─────────────

export const recommendation = {
  candidateId: 'A',
  headline: 'Maintainer recommendation: Candidate A — Canonical Wake Mark',
  reasoning:
    'Evaluated on durability (works at 16px, in one color, in five years): A is the only candidate whose core geometry survives every reduction. At 16px: three lines, one break — still reads as motion. In one color: no hairlines or hairline-weight strokes to lose. In five years: abstract geometric marks age better than typographic integrations, which are coupled to font licensing and rendering environments. The notch is semantically load-bearing (it represents the packet-in-flight, the thing Crosswake actually routes), not ornamental — that anchors the system story without requiring explanation of letterform modification. B and C are equally rigorous but add complexity that reduces legibility at small sizes. D is the strongest icon-only alternative — if you need a square app icon today, D is the safest path. E is the highest-craft wordmark integration but depends on hairlines that vanish at 16px. F is conceptually precise but carries strikethrough risk. G is durable but does not communicate.',
};

// ─── Franken invitation (Round 2) ────────────────────────────────────────────

export const frankenInvitation = `
<p class="franken-invite">
  Not sold on a single candidate? Name a combination or adjustment. Some round-2 options:
</p>
<ul class="franken-examples">
  <li><strong>R2-A mark + R2-C underline</strong> — the T1 wordmark cuts AND the seam-step underline in the same lockup. The research flags this as double-signaling; flag your comfort level with that.</li>
  <li><strong>R2-B mark + stock wordmark</strong> — B2 seam shift with completely untouched Space Grotesk. Let the mark carry everything, wordmark is neutral.</li>
  <li><strong>R2-A at display + mark A at 16px</strong> — T1 wordmark for hero contexts, Canonical Wake Mark for favicon/app icon. Separate tools for separate jobs.</li>
  <li><strong>T1 cuts on fewer glyphs</strong> — if w+k feels sufficient, drop r and a. The system still works with two letters.</li>
  <li><strong>Your own call</strong> — a single ID (R2-A through R2-D), a combination, "adjust: [what you want different]," or "advance to R1 mark A + stock wordmark."</li>
</ul>
<p class="franken-prompt">
  Reply with a single ID, a combination, or "adjust: [description]."
</p>
`;
