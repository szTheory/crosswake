# Phase 103 Round 2: Logo Tournament — Creative Direction Research

**Researched:** 2026-06-12
**Domain:** Wordmark type treatment, systematic letterform modification, mark energy analysis
**Confidence:** HIGH (SVG anatomy verified from source files; design principles verified from named case studies)

---

## Why Round 1 Failed

The round-1 treatments (E, F, G) performed local letterform surgery: one glyph mutated, eight stock. The w-cuts in `wordmark-custom.svg` applied angled lines only to the two inner apexes of the w, leaving all other letterforms untouched. At reading speed the eye compares the w against its neighbors, finds a mismatch, and reads it as an error rather than a decision.

The diagnosis from `103-ROUND2-FEEDBACK.md` is exact: **local surgery = glitch; system or single gesture = intentional.** Round 2 must satisfy one of two tests:

1. The custom detail appears on every eligible letterform (system), or
2. The custom detail exists as one independent element against otherwise-pristine letterforms (gesture).

Never a middle position.

---

## Part 1: Design Principles — What the Evidence Says

### 1.1 When Custom Details Read as Intentional

Evidence from named cases, ranked by mechanism:

**FedEx (negative space / single gesture):** The arrow between E and x was not drawn — it arises from the spatial relationship of two unmodified letterforms. This is the purest form of single-gesture thinking: the detail is not added to a letter, it emerges from the system. Zero letters were surgically modified. [CITED: Lindon Leader / wilogo.fr analysis]

**Braun wordmark (systematic construction):** Braun's custom typeface ("Braun Linear", 2023) applied a single constructive principle — racetrack-shaped terminals — consistently across every letterform. No letter is exempt from the rule. The result reads as a typeface decision, not a modification. [CITED: typeroom.eu / Iconwerk case study]

**Lufthansa (Otl Aicher, Ulm School tradition):** The Lufthansa identity uses a custom corporate typeface where terminal geometry follows a single grid-derived angle throughout. Systematic application — not selective application — is what creates the "designed" perception. [CITED: hvdfonts.com / logotyp.us]

**Linear (machine-precision editing):** Linear's wordmark uses a typeface "specifically edited for LINEAR." The edit is not one letter — it is a consistent geometric treatment applied to achieve a machined quality throughout. [CITED: linear.app/brand]

**Raycast (OpenType stylistic sets as system):** Raycast's typographic treatment applies consistent OpenType alternates (ss02, ss03, ss08) — not single-letter overrides. Every instance of the affected letterforms gets the same treatment, making it read as a typeface choice rather than a designer's tweak. [ASSUMED from Raycast brand research]

### 1.2 The Failure Taxonomy

| Failure Mode | What It Looks Like | Why It Fails |
|---|---|---|
| Local surgery | One letter modified, rest stock | Eye immediately detects inconsistency; reads as typo |
| Weight mismatch | Cut detail at different optical weight than surrounding strokes | Detail looks pasted-in, not grown-from |
| Misplaced detail | Cut at a geometrically arbitrary terminal (not a "natural" anatomical point) | Reads as damage rather than design |
| Competing gestures | Route element + letterform cuts + wake trailing all in same lockup | Visual noise defeats all three signals |

The round-1 w-cuts failed the first and third tests: local (only w), and the cut landed on the inner-valley apexes which are the most visually active point in the letter — maximally conspicuous and maximally inconsistent with neighbors.

### 1.3 The Two Routes to "Intentional"

**Route A — System:** Apply one angle rule to every terminal or apex in the word that can accept it without destroying legibility. The detail becomes invisible as a modification and visible as a typographic character.

**Route B — Gesture:** Leave every letterform completely stock. Insert one independent graphic element that interacts with the type spatially (above, below, through the counter of a specific letter). The stock type becomes the "straight man"; the gesture is the entire design statement.

Both routes work. Mixing them (modifying some letters AND adding an independent gesture) almost always fails — the viewer gets two competing claims about what the wordmark is "doing."

---

## Part 2: Letterform Anatomy Inventory

Source: `brandbook/logo/tournament/candidates/wordmark-base.svg` and `wordmark-custom.svg`, Space Grotesk SemiBold 600 at 72px, pinned commit 877f891. All coordinates are SVG user units from the viewBox `3.74 0 362.66 72.00`.

### 2.1 Terminal Inventory — Full Word

Space Grotesk SemiBold has **flat-cut terminals** (not rounded). At SemiBold weight the terminals are slightly oblique — they exit at roughly 15–20° from horizontal on curved letters, and at 90° on stems. The stroke contrast is minimal (near-monolinear) but not zero.

| Glyph | Terminal(s) | Location (approx SVG coords) | Terminal type | Cuttable at 20°? | Notes |
|---|---|---|---|---|---|
| **C** | Upper tail | ~(38, 24.5) exiting upper-right | Open bowl terminal, angled ~20–25° in stock | YES — already near 20° | Minimal gain; already close to angle |
| **C** | Lower tail | ~(38, 66.8) exiting lower-right | Open bowl terminal, angled ~20–25° in stock | YES | Symmetric with upper |
| **r** | Arm tip | ~(72.36, 35.14) right terminus of arm | Horizontal arm end | YES — strong candidate | Clean flat end; 20° cut here has clear geometric payoff |
| **o** | (none) | — | Closed counter | N/A (closed) | O is the seam-crossing candidate for T2 |
| **s** (×2) | Upper terminal | ~(120, 35) / ~(158, 35) upper-left area | Curved spine exit | YES but fragile | Spines exit at ~30–40°; forcing to 20° may torque the letter |
| **s** (×2) | Lower terminal | ~(151, 71) / ~(189, 71) lower-right area | Curved spine exit | YES but fragile | Same caveat |
| **w** | Left outer tip | ~(195.12, 35.28) | V-stroke top terminus | YES — primary candidate | Top of leftmost stroke; visible, clean |
| **w** | Right outer tip | ~(245.66, 35.28) | V-stroke top terminus | YES — primary candidate | Symmetric with left outer |
| **w** | Inner valley L | ~(207–208, 65–66) | Bottom valley of left V | YES — but was already cut in round 1 | Round-1 cut was HERE; the failure location |
| **w** | Inner valley R | ~(232–233, 65–66) | Bottom valley of right V | YES — same as above | Avoid repeating round-1 failure site |
| **a** | Tail tip | ~(287.86, 64–70) right | Curved tail terminus | YES — clean candidate | Tail exits at natural downward angle; 20° cut reads well |
| **k** | Arm tip | ~(327.89, 35.28) upper-right | Diagonal arm terminus | YES — structural candidate | High visibility; arm already runs at ~40°, 20° flat-cut shortens slope |
| **k** | Leg tip | ~(328.46, 70.85) lower-right | Diagonal leg terminus | YES — symmetric | Leg runs at ~40°; 20° cut reads as intentional slope alignment |
| **e** | Crossbar right end | ~(366.41, 52.49) | Horizontal bar terminus | YES — subtle | Small terminal; cut here is low-visibility but contributes to system |
| **e** | Tail/aperture | ~(355, 64–65) lower | Curved tail exit | YES | Pairs with e's crossbar for double-terminal consistency |

### 2.2 Anatomy Notes for Path Surgery

- The **o** at position 2 has its counter center at approximately (95.26, 53.06) in SVG coordinates. The counter is roughly circular, r ≈ 11.25u at 72px scale. Entry/exit notch positions for T2(b): left wall at ~(84, 53), right wall at ~(107, 53) — these are the clean seam-notch insertion points.
- The **w** inner valley coordinates from `wordmark-custom.svg` show the round-1 cuts: valley-L at (203.75, 63.84)→(211.75, 66.76) and valley-R at (229.03, 63.84)→(237.03, 66.76). These cuts placed the detail at the most conspicuous (highest-contrast) point in the w. For T1, shift to the **outer tips** instead.
- The **k** arm/leg vertex in `wordmark-custom.svg` shows the round-1 notch: stem exit at (307.68, 51.40)→(313.68, 53.58). This IS at a natural anatomical point (the waist of the k), but it is still a local modification with no echo elsewhere. Pairing it with T1's system fixes this.
- Space Grotesk's stroke weight at 600/72px is approximately **8–9 SVG units** on vertical strokes. At lockup scale (e.g., 40px rendered), that's roughly 4.5–5px rendered. The 20° cut depth should be 0.5–0.75× stroke width: cut depth = 4–6 SVG units at source scale.

### 2.3 What NOT to Touch

| Element | Reason |
|---|---|
| o (counter) | Closed letterform; any modification destroys the shape. O is reserved as a T2 gesture landing point only. |
| C bowl curve | The C's internal bowl curves are load-bearing for legibility; never modify the curve itself, only the terminal ends |
| s spine curves | The s spines have complex curvature that makes 20° cuts easily distort the letter's rhythm; treat with caution or skip |
| r descender/stem | The r stem is short; the only real terminal is the arm tip |
| a bowl | The a bowl is closed at the bottom; the shoulder curve is not a terminal location |
| Kern spacing | Do not adjust kerning as part of T1; kerning is already set by the generator |

---

## Part 3: Treatment Specifications

### T1 — Systematic Terminal Cuts

**Concept:** Apply a consistent 20° exit-angle cut to every naturally terminal-bearing stroke in the word. The cut angle echoes the Wake Mark's canonical 20° crossing angle. No single letter is singled out — the angle becomes the wordmark's typographic DNA.

**The principle that makes this work vs. round 1:** The round-1 w-cuts modified two inner-valley apexes — the deepest, most visually prominent notch points in the letter, which catch the eye immediately. T1 instead targets the **outer tips and open terminal ends** — points where the stroke simply stops, and where a 20° cut reads as "the stroke was built on this slope" rather than "this stroke was cut."

**Cut geometry:**
- Angle: 20° from horizontal (matching Wake Mark canonical angle)
- Cut depth: 5 SVG units at source scale (72px) — approximately 0.6× stroke width
- Method: Replace the final point of the terminal with a two-node angled flat; the flat's normal vector points at 20° from vertical (i.e., the cut face is perpendicular to the 20° direction)
- Do NOT extend strokes beyond their natural bounds. Only reshape the terminal endpoint.

**Terminal selection — apply the cut to these, in this priority:**

| Priority | Glyph | Terminal | Rationale |
|---|---|---|---|
| MUST | **w** | Left outer tip (~195.12, 35.28) | Outer tips are the natural apex points; replacing round-1's inner-valley error |
| MUST | **w** | Right outer tip (~245.66, 35.28) | Symmetric; creates visual bracketing of the w |
| MUST | **k** | Arm tip (~327.89, 35.28) | High-visibility; arm already exits at a diagonal; 20° cut aligns slope language |
| MUST | **k** | Leg tip (~328.46, 70.85) | Symmetric with arm; the k becomes fully "on-angle" |
| SHOULD | **r** | Arm tip (~72.36, 35.14) | Clean horizontal terminus; 20° cut is clear and optically satisfying |
| SHOULD | **a** | Tail tip (~287.86, 67) | Tail exits naturally; cut here extends the system into the word's second half |
| CONSIDER | **e** | Crossbar right (~366.41, 52.49) | Last letter; system bookending; low-risk since it's the bar end |
| SKIP | **C** | Both terminals | Already at ~20° in stock Space Grotesk; cutting them changes nothing visible |
| SKIP | **s** (×2) | All four terminals | s spine curves exit at 30–40°; forcing 20° would torque the letters; the system works without s |
| SKIP | **o** | N/A | Closed letterform |

**What NOT to touch:** The w's inner valleys (round-1 failure site). The k's arm/leg central vertex (round-1 other failure site — replace the round-1 k path entirely with ONLY the tip cuts, discarding the waist notch). Every other glyph path is stock.

**Risk assessment:** LOW. This approach touches only natural anatomical endpoints, not load-bearing curves. The cut is shallow (0.6× stroke width). The system spans w, k, r, and a — four of nine letters — giving enough rhythm without over-treating. The s and C letters intentionally carry no cut, which gives the eye contrast and doesn't make the word feel over-engineered.

**Visual check before committing:** Render at 40px, 20px, and 16px. At 16px, terminal cuts typically become invisible — that is correct behavior. The mark reads identically to stock at 16px; the cut only enriches at display sizes. If any cut reads as a "nick" or damage at 40px, the depth is too great — reduce to 3–4 SVG units.

**Lockup pairing:** T1 is quiet enough that either A or B can accompany it without double-signaling. No restrictions.

---

### T2 — Single Integrated Gesture (Two Candidates)

Both T2 candidates leave ALL letterforms completely stock (base wordmark, no cuts). The route element is the entire design statement.

#### T2-A: Wake Underline with Seam Step

**Concept:** A horizontal route line runs beneath the complete wordmark at baseline minus 6–8 SVG units clearance. At the midpoint between the two s letters (approximately x=188, coinciding with the "cross|wake" word boundary), the line performs a perpendicular step of 4–5 SVG units — the Seam Shift gesture from mark B, translated to the wordmark's horizontal axis. The route continues at the same height on the right half. No letterforms are touched.

**Why this is the strongest single-gesture option:** The "cross|wake" boundary is linguistically meaningful — this is exactly where the brand name describes the crossing. The step visualizes the seam at the semantic boundary in the word itself. It requires zero letterform modification, is legible at any size, and cannot be reproduced by typing the name in any font.

**Exact geometry:**
- Line weight: match the Wake Mark's stroke weight proportionally. At lockup scale where the wordmark is rendered at ~36px cap-height, the Wake Mark strokes are approximately 3.3px. The underline should be **2.5px rendered** (slightly thinner than the Wake Mark strokes to subordinate to the type, not compete).
- Line runs from x=3.74 (wordmark left edge) to x=366.40 (wordmark right edge) in SVG source units, at y=80 (8 units below the baseline of 72).
- Step location: x=188 (midpoint of the gap between the second s and the w). Step direction: perpendicular to the horizontal baseline = vertical. Step amount: 5 SVG units downward (line continues at y=85 after the step).
- Step connector: a short vertical segment of length 5 SVG units connecting y=80 to y=85 at x=188. Hard 90° join with round caps — this matches B's seam step geometry exactly.
- Do NOT add the step at any other location. One seam step, one seam.

**Color in lockup:** Use the line at currentColor (same ink as wordmark) for one-color use. In signal colorway: Wake 700 line on Foam 50.

**Lockup pairing:** T2-A pairs cleanly with mark A (Canonical Wake Mark) — the step in the wordmark underline echoes B's gesture without being B. Can also pair with mark B, but the double-step may read as redundant. **Recommendation: pair T2-A with mark A in the lockup.**

#### T2-B: The O as the Seam Crossing Port

**Concept:** The o's counter is the crossing point. A route line at 20° passes through the o's counter, entering through a 1.5×-stroke-width notch on the left wall and exiting through a matching notch on the right wall — exactly the Wake Mark geometry, at miniature scale, inside one letter. All other letterforms are completely stock.

**Why this is a strong alternative:** The o is position 3 in the word, placing the seam early. The o is the only geometrically closed letter in "crosswake," making it a natural "gate" or "port" shape. A route passing through a closed oval is directly legible as "crossing through a boundary" without requiring any wordmark-level underline or addition. The detail is self-contained within one letter — but because it's the route itself passing through (not a cut to the letterform), it reads as a composition rather than surgery.

**Critical distinction from local surgery:** In T2-B, the letterform o is NOT modified. The route element is a separate SVG path layered over (or within the counter of) the o. The o path data is unchanged. This is composition, not surgery — same as placing mark A next to the wordmark.

**Exact geometry:**
- Route segment inside o: a straight line at 20° slope, passing through the o's counter center (~95.26, 53.06 in source units). Line extends from the left inner wall (~84, 53) to the right inner wall (~107, 53) in straight-line terms at 20° slope.
- Entry notch on left wall: at approximately (80, 57) — the left edge of the o's counter at the 20° crossing height. Remove 1.5× stroke width (≈12 SVG units) of the o's left wall path to create the entry gap.
- Exit notch on right wall: at approximately (110, 49) — right edge, symmetrically. Same gap size.
- Route line: extends 8–10 SVG units beyond each notch (slightly overshoot the counter wall), with round caps. Stroke weight: matches Wake Mark (6.667 SVG units at 64-unit grid scale; proportionally ~5 SVG units at wordmark 72px scale).
- The route does NOT extend beyond the o's bounding box. It is a contained gesture.

**Risk:** This is the highest-risk T2 option. At small sizes (below 20px rendered), the notch in the o may read as a broken letter. Test at 20px, 16px, 14px before committing. If the notch disappears cleanly into the stroke weight at small sizes, this is acceptable. If it reads as a damaged o, the minimum use size for this wordmark variant must be gated at 24px — document this constraint.

**Lockup pairing:** T2-B is visually busy when paired with marks A or B (route crosses a letter AND the mark shows a route). Recommended use: standalone wordmark only (no lockup mark). Or pair with a significantly quieter mark if one is produced in round 2. Flag this pairing constraint in the gallery.

---

### T3 — The k as the Route

**Concept:** The k's leg IS a diagonal — at roughly 40° in stock. Rebuild the k so its arm and leg are replaced by the route line passing through the stem, at 20° slope (not the stock 40°), with a 1.5×-stroke-width notch at the point where the route crosses the stem. The route extends slightly beyond the k's natural bounds (perhaps 4–6 SVG units past the arm tip and leg tip) to read as a route that continues rather than a letter stroke that stops. All other letterforms are completely stock.

**The round-1 failure vs. this approach:** The round-1 k cut (in `wordmark-custom.svg`) notched the arm/leg vertex at the stem — a local modification of one feature of one letter. T3 rebuilds the arm AND leg together as a single diagonal route element at the canonical 20° angle. The difference is structural: round-1 kept the k's geometry and added a notch; T3 changes the k's geometry so the arm/leg IS a route line. This is closer to a custom glyph than a cut.

**Honest assessment of failure risk:** This is STILL a local treatment. It modifies one letter against eight stock letters. The mitigation is to pair T3 with T1 (systematic terminal cuts across w, k, r, a) — then the k's route-arm is not an isolated anomaly but one expression of a word-wide angular language. Without T1 as a companion, T3 fails by the same logic as round 1.

**Recommended approach:** Do NOT present T3 alone. Present T3 + T1 as a combined treatment — they share the same 20° angle DNA. The combined treatment reads as: "the wordmark is built on 20° geometry throughout, and the k makes that geometry explicit."

**Exact geometry for T3:**
- Discard the round-1 k path entirely. Start from the stock k path (`glyph-7-k` in `wordmark-base.svg`).
- The stem (x=294.70 to 302.98, y=20.45 to 70.85) is unchanged.
- Replace the arm/leg divergence (currently: arm at ~40° upper-right, leg at ~40° lower-right, vertex at ~310.68, 52.49) with a SINGLE diagonal at 20° slope passing through the stem intersection point.
- Route arm: from stem intersection at (302.98, 52) upward-right at 20° slope to approximately (332, 41.6). Extends ~4 SVG units beyond the original arm tip.
- Route leg: same diagonal, continuing downward-left from stem intersection — but because it's a through-route, the "leg" is the same line extended downward-right from (302.98, 52) to approximately (332, 63.4) at 20° slope. Wait — this makes the arm and leg the SAME line through the stem (a straight route), which is the cleaner reading: one route line crosses the k's stem at 20°, entering left of stem and exiting right of stem with a 1.5× notch at the crossing.
- Notch at stem crossing: 1.5× stroke width gap (same as Wake Mark protocol). The route is broken at the stem, with the stem visible as the seam boundary.
- Cap style: round, matching the Wake Mark.
- Stroke weight: match the other k elements optically — approximately the same rendered weight as the adjacent a's bowl strokes.

**The visual read:** The k reads as a letter with a route line passing through it, rather than a letter with a leg. At display sizes (36px+) this is clear and intentional. At 16px it will likely read as a normal k or a slightly different k — which is acceptable.

**Lockup pairing:** T3+T1 combined is the natural pairing. Mark A (Canonical Wake Mark) is the appropriate lockup mark — the k's internal route echoes the Wake Mark without competing. Do NOT pair T3+T1 with mark B (double route vocabulary in a single lockup: B's seam step PLUS T3's route-k is too much).

---

### T4 — Mono-Weight Redraw Feasibility Assessment

**Concept:** Redraw "Crosswake" in strokes matching the Wake Mark's stroke weight and round caps — a "drawn with the same pen" logotype. The mark and wordmark would share identical stroke weight, cap style, and monolinear character.

**Feasibility verdict: OUT OF SCOPE for one week, but not impossible in principle.**

**Why out of scope:**
- Space Grotesk SemiBold is NOT monolinear. At 600 weight it has measurable stroke contrast (thicks ~8–9u, thins ~5–6u at 72px source scale). The Wake Mark IS monolinear. To match them, you would need to either: (a) use a lighter Space Grotesk weight (300 or 400), which reduces stroke weight substantially and may not match the mark's 6.667u stroke; or (b) redraw the wordmark from scratch on monolinear geometry — which is a custom typeface project, not a surgical path edit.
- Google Fonts candidates: Quicksand (rounded monolinear geometric) and Comfortaa (rounded geometric) both have the right stroke character but are entirely different letterform families. They are not Space Grotesk with modifications — they are different typefaces. Using them would violate D-12 (Space Grotesk is FROZEN as the wordmark foundation). [ASSUMED — Quicksand/Comfortaa character assessment from training knowledge, not verified via source tool in this session]

**Correct long-term path:** If a drawn-same-pen logotype is wanted after Phase 103, the path is: generate wordmark outlines at Space Grotesk 300 weight, then expand strokes to match the Wake Mark weight. This is a Phase 104+ task requiring the production path editor workflow.

**Round 2 verdict:** Do not attempt T4 in round 2. Note it as a future refinement direction for the ratified treatment.

---

## Part 4: Seam Shift Energy Verdict

### Is B's perpendicular step on-brand?

Brand personality from `prompts/crosswake-brand-book.md §6` and §2: **calm, explicit, technical, boundary-honest, OSS-generous, precise**.

The perpendicular step reads as: a boundary was crossed and the system recorded it. The route continues — it was not stopped or broken — but its position changed to reflect a seam crossing. This is exactly the product's behavior: the route continues after the crossing, but the boundary is visible.

**Verdict: YES, the step is on-brand — with conditions.**

The step is on-brand when it reads as **precise** (clean geometry, controlled scale) and **explicit** (the step is clearly intentional, not a rendering artifact). It is off-brand if it reads as **erratic** (step size too large, looks like the line glitched) or **energetic in a startup-pitch sense** (dynamic, exciting). Crosswake is never exciting.

### Calibration parameters for the step to read calm + explicit:

| Parameter | Round 1 B spec | Round 2 recommended spec | Rationale |
|---|---|---|---|
| Step size | 6 SVG units perpendicular (5.64u y-displacement) | **4 SVG units perpendicular (3.76u y-displacement)** | Smaller step reads as precise instrument correction rather than dramatic shift |
| Connector type | Short perpendicular line (90° join) | **Hard 90° join with round caps — KEEP** | The sharp right angle is the most explicit geometry; round caps soften it slightly; a 20° parallelogram jog would read as a different event entirely |
| Step direction | Downward (perpendicular below the route) | **Keep downward** | Route steps "into" the seam, which reads as a descent/entry to the boundary |
| Seam position | At x=32 (geometric center of 64-unit grid) | **Keep at geometric center** | Centered seam reads as symmetric, intentional, cartographic |
| Wake lines | Two trailing lines at equal spacing | **Shorten wake lines to 24u (currently 32u)** | Slightly tighter wake spacing reads more precise, less dramatic |

### Recommended Step: B-refined

Refine mark B per the above parameters. The existing B.svg seam connector `(32,32)→(34.05,37.64)` is a 5.64u perpendicular displacement. Reduce to a 3.76u displacement: new endpoint `(33.37, 35.76)`. Wake lines shorten from 32u to 24u. All other geometry preserved.

---

## Part 5: Round 2 Mark Lineup

Maximum 3 marks. Each must be genuinely evaluable — no straw men.

### Mark A-refined: Canonical Wake Mark with T1 Wordmark

**What it is:** Mark A (unchanged geometry) + the stock wordmark with T1 systematic terminal cuts applied to w (outer tips only), k (arm + leg tips only), r (arm tip), and a (tail tip). The w and k inner modifications from round 1 are discarded.

**Why it belongs:** A-refined tests whether the systematic terminal approach solves the round-1 "local surgery" failure. The mark is neutral and proven. The wordmark change is the variable under test. This is the safest round-2 candidate and the most likely winner for production use.

**Risk:** LOW. Terminal cuts at outer tips are optically safe. The system spans four letters. At small sizes, the cuts are invisible and the wordmark reads as stock.

**Gallery instruction for generator:** Start from `wordmark-base.svg`. Apply T1 cuts to glyph-5-w outer tips and glyph-7-k arm/leg tips. Discard the `wordmark-custom.svg` path for both letters — start fresh from base.

---

### Mark B-refined: Seam Shift (Recalibrated)

**What it is:** Mark B with the step reduced from 6u to 4u perpendicular displacement, wake lines shortened from 32u to 24u. Paired with the STOCK wordmark (no letterform modifications — the mark is doing all the work).

**Why it belongs:** B is the user-selected energetic candidate; the question was "is that energy on-brand?" This refined version answers with: yes, at controlled scale. The wordmark is stock because B's gesture is already strong — adding T1 cuts here would be competing visual vocabularies.

**Risk:** MEDIUM. The step energy may still read as too dynamic at large display sizes. Gallery must show B-refined at multiple scales, especially at 24px and 48px where the step-to-stroke-weight ratio tells the true story.

**Gallery instruction:** Update B.svg per recalibration spec above. Pair with `wordmark-base.svg` (no cuts).

---

### Mark A×B Hybrid: Wake Mark + Seam-Step Wordmark Underline (T2-A)

**What it is:** Mark A (unmodified Canonical Wake Mark) + T2-A wordmark treatment (stock letterforms + seam-step underline at the "cross|wake" boundary). The underline's step echoes B's seam-shift gesture at the wordmark level. No letterform modifications.

**Why it belongs:** This tests whether the B-style gesture can be moved from the mark into the wordmark, making the mark quieter (A) while keeping the seam-step reading. This is the highest-concept candidate: the wordmark itself declares the crossing.

**Risk:** MEDIUM-HIGH. The underline must be very precisely calibrated — too heavy and it competes with the wordmark; too light and it's invisible. At small sizes the underline may disappear entirely. Gallery must show the underline-only variant as well as the full lockup, so the user can evaluate the wordmark standalone.

**Gallery instruction:** Mark A unchanged. Wordmark: `wordmark-base.svg` (stock, no cuts) with a separate `<path>` underline element added to the SVG, per T2-A geometry spec.

---

## Part 6: Lockup Pairing Rules

| Wordmark treatment | Compatible marks | Restricted pairings | Reason |
|---|---|---|---|
| T1 (systematic terminal cuts) | A, B | None restricted | T1 is quiet; any mark can accompany it |
| T2-A (seam-step underline) | A only | Avoid B | A+T2-A: mark is clean, wordmark carries the seam gesture. B+T2-A: double seam-step = redundant |
| T2-B (o as seam port) | Standalone wordmark only | Avoid A and B in lockup | Mark + route-o is visual overload; use as wordmark-standalone treatment |
| T3+T1 (k-as-route + systematic cuts) | A only | Avoid B | k's internal route + B's external seam step = competing vocabularies |
| Stock wordmark (no modifications) | A, B | None | Stock wordmark works with any mark |

**General lockup rule:** If the wordmark carries a route gesture (T2-A underline, T3 route-k), the lockup mark must be the quieter of the two surviving marks (A). Never pair a route-gesture wordmark with a seam-step mark — the two route signals fight.

---

## Part 7: Risk Register

| Treatment | Risk | Severity | Mitigation |
|---|---|---|---|
| T1 on w outer tips | Optical weight of cut tip may be lighter than the stem | LOW | Cut depth ≤ 0.6× stroke width; verify at 40px |
| T1 on k tips | k arm/leg exit angle change may look abrupt | LOW | Use the same 5u cut depth as other terminals |
| T1 on r arm | r arm is short; cut may dominate | MEDIUM | If it reads as damage, skip r and keep only w/k/a |
| T2-A underline | At small sizes the step becomes a jog or disappears | MEDIUM | Gate minimum lockup size at 64px wide; gallery shows 32px failure |
| T2-B o-port | Broken o reads as typo at small sizes | HIGH | Gate minimum size at 24px rendered; flag in gallery card |
| T3+T1 combined | k rebuilt at 20° may read as a different letter | MEDIUM | The notch and the stem are still present; at 20px the k reads normally |
| B-refined step | Step may still read as too energetic for the brand | MEDIUM | Gallery must show B-refined alongside A-refined at identical scale |

---

## Part 8: Implementation Instructions for Round 2 Gallery

### File layout

```
brandbook/logo/tournament/candidates/
  A.svg                      (UNCHANGED — keep round-1 A as provenance)
  B.svg                      (UNCHANGED — keep round-1 B as provenance)
  A-refined.svg              (NEW: mark A + T1 wordmark cuts — generate fresh)
  B-refined.svg              (NEW: mark B recalibrated + stock wordmark)
  AB-hybrid.svg              (NEW: mark A + T2-A underline wordmark)
  wordmark-T1.svg            (NEW: wordmark with T1 cuts only, no mark — standalone artifact)
  wordmark-T2A.svg           (NEW: stock wordmark + seam-step underline, no mark)
```

### Generator note for wordmark-T1.svg

Start from `wordmark-base.svg`. Apply T1 cuts following this order:
1. Replace glyph-5-w outer-tip L endpoint (~195.12, 35.28): add a 5u cut at 20° slope.
2. Replace glyph-5-w outer-tip R endpoint (~245.66, 35.28): symmetric cut.
3. Remove the round-1 inner-valley cuts (discard the modified `wordmark-custom.svg` w path).
4. Replace glyph-7-k arm tip (~327.89, 35.28): 5u cut at 20°.
5. Replace glyph-7-k leg tip (~328.46, 70.85): 5u cut at 20°.
6. Remove the round-1 k waist-notch (discard the modified `wordmark-custom.svg` k path).
7. Replace glyph-1-r arm tip (~72.36, 35.14): 4u cut at 20° (slightly shallower, arm is thin).
8. Replace glyph-6-a tail tip (~287.86, 67): 5u cut at 20°.

### Generator note for B-refined.svg

Start from `B.svg`. Modify the seam connector:
- Old: `(32,32)→(34.05,37.64)` — 5.64u perpendicular displacement.
- New: `(32,32)→(33.37,35.76)` — 3.76u perpendicular displacement.
- Adjust the post-seam route segment 2 start point: old `(34.05,37.64)`; new `(33.37,35.76)`.
- Wake lines: shorten from 32u to 24u. Recompute endpoints keeping same centers.

### Generator note for AB-hybrid.svg (T2-A underline)

Start from `A.svg` for the mark. For the wordmark element in the lockup SVG:
- Use `wordmark-base.svg` paths (completely stock — no letter cuts).
- Add underline path: horizontal line at y=80 (source units), x=3.74 to x=188. Then vertical step at x=188 from y=80 to y=85. Then horizontal continuation x=188 to x=366.40 at y=85.
- Stroke weight: 4.5 SVG units at source scale (proportional to Wake Mark's 6.667u at 64-unit grid, scaled for wordmark coordinate space).
- Stroke-linecap: round. Stroke-linejoin: miter (for the clean 90° corner at the step).
- Color: currentColor (same as wordmark).

---

## Sources

### Primary (HIGH confidence — verified from source files)
- `brandbook/logo/tournament/candidates/wordmark-base.svg` — all glyph path coordinates, terminal locations, stroke anatomy
- `brandbook/logo/tournament/candidates/wordmark-custom.svg` — round-1 cut geometry (failure analysis)
- `brandbook/logo/tournament/candidates/A.svg` — mark A geometry (canonical Wake Mark)
- `brandbook/logo/tournament/candidates/B.svg` — mark B geometry (Seam Shift, step parameters)
- `brandbook/AUDIT.md §8` — geometry constraints, D-11 rider, D-12 frozen decisions
- `prompts/crosswake-brand-book.md §6` — voice/personality for energy verdict
- `.planning/phases/103-logo-tournament/103-ROUND2-FEEDBACK.md` — round-1 failure diagnosis

### Secondary (MEDIUM confidence — named cases, verified via official brand pages)
- [linear.app/brand](https://linear.app/brand) — Linear wordmark edit confirmation
- [hvdfonts.com/custom-cases/lufthansa](https://www.hvdfonts.com/custom-cases/lufthansa) — Lufthansa systematic terminal design
- [typeroom.eu — Braun Linear bespoke typeface](https://www.typeroom.eu/iconwerk-braun-linear-bespoke-typeface) — Braun systematic racetrack terminal treatment
- [wilogo.fr — FedEx logo analysis](https://www.wilogo.fr/en/blog/logo-fedex-fleche-cachee) — single-gesture / negative space principle

### Tertiary (ASSUMED — training knowledge, flagged)
- Quicksand and Comfortaa as mono-weight rounded geometric candidates for T4 — character assessment from training data, not verified via source tool in this session. T4 is DEFERRED regardless, so this does not affect implementation.
- Raycast OpenType stylistic set application as systematic-treatment example — partially confirmed by search results, full detail ASSUMED.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Quicksand and Comfortaa are rounded monolinear geometrics that could seed a T4 redraw | T4 assessment | Low — T4 is deferred; wrong font names would not affect round 2 |
| A2 | Raycast's brand uses consistent OpenType alternates across all instances, not selective per-glyph overrides | Part 1.1 | Low — used only as a supporting example; principle holds from verified sources |
| A3 | s-terminal spine exits at 30–40° (T1 skip recommendation) | Part 2.1 | Medium — if the s spines in Space Grotesk SemiBold actually exit closer to 20°, they could join T1's system; verify visually before final implementation |

---

## Metadata

**Confidence breakdown:**
- Failure analysis: HIGH — derived from direct SVG path data comparison
- Terminal inventory: HIGH — derived from `wordmark-base.svg` coordinates
- T1 specification: HIGH — geometry is directly calculable from confirmed path data
- T2-A geometry: HIGH — derived from confirmed wordmark coordinate space
- T2-B geometry: MEDIUM — notch insertion into o requires test render to confirm legibility
- T3 geometry: MEDIUM — rebuilding k arm/leg as a through-route needs visual verification
- B-refined recalibration: HIGH — arithmetic from confirmed B.svg parameters
- Seam Shift energy verdict: HIGH — derived from verified brand book personality spec

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 (stable domain — Space Grotesk path data is pinned, brand spec is frozen)
