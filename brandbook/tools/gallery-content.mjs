/**
 * gallery-content.mjs
 * Per-candidate metadata consumed by build-gallery.mjs.
 * Edit this file to update rationale, risk, and recommendation text.
 * Run `node brandbook/tools/build-gallery.mjs` to regenerate index.html.
 */

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

export const recommendation = {
  candidateId: 'A',
  headline: 'Maintainer recommendation: Candidate A — Canonical Wake Mark',
  reasoning:
    'Evaluated on durability (works at 16px, in one color, in five years): A is the only candidate whose core geometry survives every reduction. At 16px: three lines, one break — still reads as motion. In one color: no hairlines or hairline-weight strokes to lose. In five years: abstract geometric marks age better than typographic integrations, which are coupled to font licensing and rendering environments. The notch is semantically load-bearing (it represents the packet-in-flight, the thing Crosswake actually routes), not ornamental — that anchors the system story without requiring explanation of letterform modification. B and C are equally rigorous but add complexity that reduces legibility at small sizes. D is the strongest icon-only alternative — if you need a square app icon today, D is the safest path. E is the highest-craft wordmark integration but depends on hairlines that vanish at 16px. F is conceptually precise but carries strikethrough risk. G is durable but does not communicate.',
};

export const frankenInvitation = `
<p class="franken-invite">
  Not sold on a single candidate? Name a combination. Some examples worth considering:
</p>
<ul class="franken-examples">
  <li><strong>A mark + F type treatment</strong> — the Canonical Wake Mark as icon, the Crossing-SS wordmark as full-width text lockup. Two layers of the same geometry.</li>
  <li><strong>D at icon scale + E at wordmark scale</strong> — D (the C monogram) for favicon/app-icon contexts; E (the deepened-w wordmark) for full-width print and web. Separate tools for separate jobs.</li>
  <li><strong>A mark + G type treatment</strong> — the geometric mark carries the identity; the restrained wordmark stays typographically quiet. Maximum separation of duties.</li>
  <li><strong>Your own combination</strong> — any mark (A–D) paired with any type treatment (E, F, or G), or a single candidate as-is.</li>
</ul>
<p class="franken-prompt">
  Reply with: a single letter (A–G), a combination like "mark B + type treatment F," or "adjust: [what you want changed]."
</p>
`;
