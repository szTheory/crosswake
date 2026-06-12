#!/usr/bin/env node
/**
 * build-gallery.mjs
 * Generates brandbook/logo/tournament/index.html from candidate SVGs + gallery-content.mjs.
 *
 * Usage:
 *   node brandbook/tools/build-gallery.mjs
 *
 * Zero npm dependencies — uses only Node built-ins.
 * See gallery-content.mjs to update per-candidate text and the maintainer recommendation.
 */

import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  candidates,
  round2Candidates,
  recommendation,
  round2Recommendation,
  frankenInvitation,
} from './gallery-content.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const CANDIDATES_DIR = resolve(ROOT, 'brandbook/logo/tournament/candidates');
const OUT_FILE = resolve(ROOT, 'brandbook/logo/tournament/index.html');

// ─── SVG helpers ────────────────────────────────────────────────────────────────

/**
 * Load an SVG file and prepare it for inline embedding:
 * - Strip the <?xml ... ?> prolog
 * - Strip XML comments (<!-- ... -->)
 * - Keep currentColor strokes and fills as-is
 * Returns the cleaned SVG string.
 */
function loadSvg(filePath) {
  let src = readFileSync(filePath, 'utf8');
  // Strip XML declaration
  src = src.replace(/<\?xml[^?]*\?>/g, '');
  // Strip XML comments
  src = src.replace(/<!--[\s\S]*?-->/g, '');
  // Collapse excessive whitespace in text nodes (not inside attributes)
  src = src.replace(/\n\s*\n/g, '\n').trim();
  return src;
}

/**
 * Wrap an SVG string in a sized container div.
 * @param {string} svgStr - Cleaned SVG markup
 * @param {number} size - CSS pixel size (width and height)
 * @param {string} extraStyle - Additional inline style on the container
 */
function svgBox(svgStr, size, extraStyle = '') {
  // We need to set width/height on the inline SVG element so it renders at the target size.
  // Replace the <svg ... > opening tag to inject CSS width/height.
  const sized = svgStr.replace(/<svg\b/, `<svg style="width:${size}px;height:${size}px;display:block;"`);
  return `<div class="svg-box" style="width:${size}px;height:${size}px;${extraStyle}">${sized}</div>`;
}

/**
 * Wrap an SVG (non-square viewBox, e.g. lockups) in a container that fills its parent width.
 * Used for lockup SVGs which have wide aspect ratios.
 */
function svgLockupBox(svgStr) {
  const sized = svgStr.replace(/<svg\b/, `<svg style="width:100%;height:auto;display:block;"`);
  return `<div class="lockup-box">${sized}</div>`;
}

/**
 * Build the favicon tab mock HTML for a candidate.
 * The favicon area is a CSS-drawn browser-tab simulation at 16px icon scale.
 * @param {string} markSvgStr - The mark SVG (for A–D) or wordmark SVG (for E–G)
 * @param {string} candidateId - Candidate ID
 * @param {string} label - Tab label text
 */
function faviconMock(markSvgStr, candidateId, label) {
  const iconSized = markSvgStr.replace(
    /<svg\b/,
    `<svg style="width:16px;height:16px;display:inline-block;vertical-align:middle;"`
  );
  return `
    <div class="favicon-mock-wrap">
      <div class="tab-bar">
        <div class="tab-mock">
          <span class="favicon-area">${iconSized}</span>
          <span class="tab-label">${label}</span>
          <span class="tab-close">&times;</span>
        </div>
        <div class="tab-new-btn">+</div>
      </div>
      <div class="browser-toolbar">
        <span class="nav-btn">&larr;</span>
        <span class="nav-btn">&rarr;</span>
        <span class="address-bar">crosswake.dev</span>
      </div>
    </div>`;
}

// ─── Load all SVG files ──────────────────────────────────────────────────────────

const svgCache = {};

function getSvg(filename) {
  if (!svgCache[filename]) {
    svgCache[filename] = loadSvg(resolve(CANDIDATES_DIR, filename));
  }
  return svgCache[filename];
}

// Preload all Round 1 candidate SVGs
const candidateIds = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
for (const id of candidateIds) {
  getSvg(`${id}.svg`);
}
// Preload lockups for R1 marks A–D
for (const id of ['A', 'B', 'C', 'D']) {
  getSvg(`${id}-lockup-horizontal.svg`);
  getSvg(`${id}-lockup-stacked.svg`);
}

// Preload Round 2 SVGs
const r2SvgFiles = [
  'wordmark-t1.svg',
  'B2.svg',
  'wordmark-seamstep.svg',
  'R2D-oport.svg',
  'R2-A-lockup-horizontal.svg',
  'R2-A-lockup-stacked.svg',
  'R2-B-lockup-horizontal.svg',
  'R2-B-lockup-stacked.svg',
  'R2-C-lockup-horizontal.svg',
];
for (const f of r2SvgFiles) {
  getSvg(f);
}

// ─── Round 1 Card builder ────────────────────────────────────────────────────────

function buildCard(candidate, isRecommended = false) {
  const { id, name, concept, rationale, risk } = candidate;
  const svgStr = getSvg(`${id}.svg`);
  const hasLockups = ['A', 'B', 'C', 'D'].includes(id);

  // For typemarks (E–G), viewBox is wide: use a wider box for 256px renders
  const isTypemark = ['E', 'F', 'G'].includes(id);

  // Swatch renders at 256px (for marks) or auto-width-with-height-64 for typemarks
  function swatchRender(swatchClass, label) {
    if (isTypemark) {
      const sized = svgStr.replace(
        /<svg\b/,
        `<svg style="height:64px;width:auto;display:block;max-width:100%;"`
      );
      return `
        <div class="swatch ${swatchClass}">
          <div class="swatch-label">${label}</div>
          <div class="swatch-inner typemark-render">${sized}</div>
        </div>`;
    }
    return `
      <div class="swatch ${swatchClass}">
        <div class="swatch-label">${label}</div>
        <div class="swatch-inner">${svgBox(svgStr, 256)}</div>
      </div>`;
  }

  // Monochrome render
  function monoRender() {
    if (isTypemark) {
      const sized = svgStr.replace(
        /<svg\b/,
        `<svg style="height:48px;width:auto;display:block;max-width:100%;"`
      );
      return `<div class="mono-render typemark-render">${sized}</div>`;
    }
    return `<div class="mono-render">${svgBox(svgStr, 128)}</div>`;
  }

  // Small renders 24px and 16px
  function smallRenders() {
    if (isTypemark) {
      const s24 = svgStr.replace(/<svg\b/, `<svg style="height:24px;width:auto;display:inline-block;vertical-align:middle;"`);
      const s16 = svgStr.replace(/<svg\b/, `<svg style="height:16px;width:auto;display:inline-block;vertical-align:middle;"`);
      return `
        <div class="small-renders">
          <div class="small-render-item"><span class="render-size-label">24px</span>${s24}</div>
          <div class="small-render-item"><span class="render-size-label">16px</span>${s16}</div>
        </div>`;
    }
    return `
      <div class="small-renders">
        <div class="small-render-item"><span class="render-size-label">24px</span>${svgBox(svgStr, 24)}</div>
        <div class="small-render-item"><span class="render-size-label">16px</span>${svgBox(svgStr, 16)}</div>
      </div>`;
  }

  // Favicon mock
  const faviconSvg = svgStr;
  const faviconHtml = faviconMock(faviconSvg, id, name);

  // Lockups section (A–D only)
  let lockupsHtml = '';
  if (hasLockups) {
    const horizSvg = getSvg(`${id}-lockup-horizontal.svg`);
    const stackedSvg = getSvg(`${id}-lockup-stacked.svg`);
    lockupsHtml = `
      <div class="lockups-section">
        <h4 class="section-subtitle">Lockups</h4>
        <div class="lockup-row">
          <div class="lockup-item">
            <span class="lockup-label">Horizontal</span>
            ${svgLockupBox(horizSvg)}
          </div>
          <div class="lockup-item">
            <span class="lockup-label">Stacked</span>
            <div class="stacked-lockup-wrap">${svgLockupBox(stackedSvg)}</div>
          </div>
        </div>
      </div>`;
  }

  const recommendedBadge = isRecommended
    ? `<span class="recommended-badge">Maintainer pick</span>`
    : '';

  return `
<section class="candidate-card" id="candidate-${id}">
  <div class="card-header">
    <h2 class="candidate-id">${id}</h2>
    <div class="candidate-meta">
      <h3 class="candidate-name">${name}${recommendedBadge}</h3>
      <p class="candidate-concept">${concept}</p>
    </div>
  </div>

  <div class="render-matrix">
    <h4 class="section-subtitle">Color contexts</h4>
    <div class="swatch-row">
      ${swatchRender('swatch-foam', 'Foam #F7F1E6')}
      ${swatchRender('swatch-dark', 'Current #09141A')}
      ${swatchRender('swatch-white', 'White')}
    </div>

    <h4 class="section-subtitle">Monochrome</h4>
    <div class="mono-row">
      ${monoRender()}
    </div>

    <h4 class="section-subtitle">Small renders</h4>
    ${smallRenders()}

    <h4 class="section-subtitle">Browser tab (favicon mock, 16px)</h4>
    ${faviconHtml}
  </div>

  ${lockupsHtml}

  <div class="card-copy">
    <div class="rationale-block">
      <h4 class="copy-label">Rationale</h4>
      <p>${rationale}</p>
    </div>
    <div class="risk-block">
      <h4 class="copy-label risk-label">Risk</h4>
      <p>${risk}</p>
    </div>
  </div>
</section>`;
}

// ─── Round 2 Card builder ────────────────────────────────────────────────────────

function buildR2Card(candidate, isRecommended = false) {
  const {
    id, name, concept, rationale, risk, feedbackResponse,
    hasLockups, markFile, lockupHorizFile, lockupStackedFile, typemarkFile, isExploratory,
  } = candidate;

  // Determine primary render SVG and render type
  const isTypemark = !markFile && !!typemarkFile;
  const primarySvgFile = isTypemark ? typemarkFile : markFile;
  const primarySvg = getSvg(primarySvgFile);

  function swatchRender(swatchClass, label) {
    if (isTypemark) {
      const sized = primarySvg.replace(
        /<svg\b/,
        `<svg style="height:64px;width:auto;display:block;max-width:100%;"`
      );
      return `
        <div class="swatch ${swatchClass}">
          <div class="swatch-label">${label}</div>
          <div class="swatch-inner typemark-render">${sized}</div>
        </div>`;
    }
    return `
      <div class="swatch ${swatchClass}">
        <div class="swatch-label">${label}</div>
        <div class="swatch-inner">${svgBox(primarySvg, 256)}</div>
      </div>`;
  }

  function monoRender() {
    if (isTypemark) {
      const sized = primarySvg.replace(
        /<svg\b/,
        `<svg style="height:48px;width:auto;display:block;max-width:100%;"`
      );
      return `<div class="mono-render typemark-render">${sized}</div>`;
    }
    return `<div class="mono-render">${svgBox(primarySvg, 128)}</div>`;
  }

  function smallRenders() {
    if (isTypemark) {
      const s24 = primarySvg.replace(/<svg\b/, `<svg style="height:24px;width:auto;display:inline-block;vertical-align:middle;"`);
      const s16 = primarySvg.replace(/<svg\b/, `<svg style="height:16px;width:auto;display:inline-block;vertical-align:middle;"`);
      return `
        <div class="small-renders">
          <div class="small-render-item"><span class="render-size-label">24px</span>${s24}</div>
          <div class="small-render-item"><span class="render-size-label">16px</span>${s16}</div>
        </div>`;
    }
    return `
      <div class="small-renders">
        <div class="small-render-item"><span class="render-size-label">24px</span>${svgBox(primarySvg, 24)}</div>
        <div class="small-render-item"><span class="render-size-label">16px</span>${svgBox(primarySvg, 16)}</div>
      </div>`;
  }

  const faviconHtml = faviconMock(primarySvg, id, name);

  // Lockups section
  let lockupsHtml = '';
  if (hasLockups) {
    const horizSvg = getSvg(lockupHorizFile);
    lockupsHtml = `
      <div class="lockups-section">
        <h4 class="section-subtitle">Lockups</h4>
        <div class="lockup-row">
          <div class="lockup-item">
            <span class="lockup-label">Horizontal</span>
            ${svgLockupBox(horizSvg)}
          </div>`;
    if (lockupStackedFile) {
      const stackedSvg = getSvg(lockupStackedFile);
      lockupsHtml += `
          <div class="lockup-item">
            <span class="lockup-label">Stacked</span>
            <div class="stacked-lockup-wrap">${svgLockupBox(stackedSvg)}</div>
          </div>`;
    } else {
      lockupsHtml += `
          <div class="lockup-item">
            <span class="lockup-label">Stacked</span>
            <p class="lockup-note">No stacked lockup — seam-step line requires horizontal layout to read the step.</p>
          </div>`;
    }
    lockupsHtml += `
        </div>
      </div>`;
  } else if (isTypemark) {
    lockupsHtml = `<div class="lockups-section"><p class="lockup-note"><strong>Standalone typemark only</strong> — pairing this with a mark creates visual overload (two route signals). Use as wordmark-only, minimum 24px rendered.</p></div>`;
  }

  const recommendedBadge = isRecommended
    ? `<span class="recommended-badge">Maintainer pick</span>`
    : '';
  const exploratoryBadge = isExploratory
    ? `<span class="exploratory-badge">Exploratory</span>`
    : '';

  return `
<section class="candidate-card r2-card" id="candidate-${id}">
  <div class="card-header">
    <h2 class="candidate-id r2-id">${id}</h2>
    <div class="candidate-meta">
      <h3 class="candidate-name">${name}${recommendedBadge}${exploratoryBadge}</h3>
      <p class="candidate-concept">${concept}</p>
    </div>
  </div>

  <div class="render-matrix">
    <h4 class="section-subtitle">Color contexts${isTypemark ? ' (typemark)' : ' (mark only — see lockups for full treatment)'}</h4>
    <div class="swatch-row">
      ${swatchRender('swatch-foam', 'Foam #F7F1E6')}
      ${swatchRender('swatch-dark', 'Current #09141A')}
      ${swatchRender('swatch-white', 'White')}
    </div>

    <h4 class="section-subtitle">Monochrome</h4>
    <div class="mono-row">
      ${monoRender()}
    </div>

    <h4 class="section-subtitle">Small renders</h4>
    ${smallRenders()}

    <h4 class="section-subtitle">Browser tab (favicon mock, 16px)</h4>
    ${faviconHtml}
  </div>

  ${lockupsHtml}

  <div class="card-copy">
    <div class="rationale-block">
      <h4 class="copy-label">Rationale</h4>
      <p>${rationale}</p>
    </div>
    <div class="risk-block">
      <h4 class="copy-label risk-label">Risk</h4>
      <p>${risk}</p>
    </div>
  </div>
  <div class="feedback-response-block">
    <h4 class="copy-label feedback-label">Round-1 feedback response</h4>
    <p class="feedback-response-text">${feedbackResponse}</p>
  </div>
</section>`;
}

// ─── Lineup grid ────────────────────────────────────────────────────────────────

function buildLineupGrid() {
  const cells = candidateIds.map((id) => {
    const svgStr = getSvg(`${id}.svg`);
    const isTypemark = ['E', 'F', 'G'].includes(id);
    let renderHtml;
    if (isTypemark) {
      const sized = svgStr.replace(
        /<svg\b/,
        `<svg style="height:48px;width:auto;display:block;max-width:100%;"`
      );
      renderHtml = `<div class="lineup-svg typemark-lineup">${sized}</div>`;
    } else {
      renderHtml = `<div class="lineup-svg mark-lineup">${svgBox(svgStr, 80)}</div>`;
    }
    return `
    <div class="lineup-cell">
      ${renderHtml}
      <div class="lineup-id">${id}</div>
    </div>`;
  }).join('');

  return `
<section class="lineup-section">
  <h2 class="section-title">Round 1 — equal-size lineup (A–G)</h2>
  <p class="section-intro">Marks at 80px, typemarks scaled to 48px height. All seven round-1 candidates for reference.</p>
  <div class="lineup-grid">
    ${cells}
  </div>
</section>`;
}

// ─── Round 2 Recommendation section ────────────────────────────────────────────

function buildR2RecommendationSection() {
  const rec = round2Recommendation;
  const { candidateId, headline, reasoning } = rec;

  const cand = round2Candidates.find((c) => c.id === candidateId);
  const cardHtml = buildR2Card(cand, true);

  return `
<section class="recommendation-section" id="recommendation">
  <h2 class="section-title">Round 2 — Maintainer recommendation</h2>
  <p class="durability-frame">Judged on: <strong>works at 16px, in one color, in five years.</strong> Not on taste.</p>
  <blockquote class="rec-reasoning">${reasoning}</blockquote>
  <div class="rec-candidate">
    ${cardHtml}
  </div>
  <div class="franken-section">
    <h3 class="franken-title">Franken-picks welcome</h3>
    ${frankenInvitation}
  </div>
</section>`;
}

// ─── Round 1 Recommendation section (preserved) ────────────────────────────────

function buildR1RecommendationSection() {
  const rec = recommendation;
  const { candidateId, reasoning } = rec;
  const cand = candidates.find((c) => c.id === candidateId);
  const cardHtml = buildCard(cand, true);

  return `
<section class="recommendation-section r1-recommendation" id="r1-recommendation">
  <h2 class="section-title">Round 1 — Maintainer recommendation (reference only)</h2>
  <p class="durability-frame">Round 1 was superseded by round-2 feedback. Preserved for provenance.</p>
  <blockquote class="rec-reasoning">${reasoning}</blockquote>
  <div class="rec-candidate">
    ${cardHtml}
  </div>
</section>`;
}

// ─── Page CSS ────────────────────────────────────────────────────────────────────

const PAGE_CSS = `
/* ── Reset & base ──────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: system-ui, -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif;
  font-size: 15px;
  line-height: 1.5;
  background: var(--cw-surface-raised, #EFE6D6);
  color: var(--cw-text-default, #09141A);
  padding: 2rem;
}

/* ── Layout ─────────────────────────────────────────────────────── */
.page-header {
  max-width: 900px;
  margin: 0 auto 3rem;
  border-bottom: 2px solid var(--cw-border-strong, #2B756A);
  padding-bottom: 1.5rem;
}
.page-title { font-size: 2rem; font-weight: 700; margin-bottom: 0.25rem; }
.page-subtitle { font-size: 1rem; color: var(--cw-text-muted, #756D63); }
.durability-headline {
  margin-top: 0.75rem;
  font-size: 1rem;
  font-style: italic;
  color: var(--cw-text-default, #09141A);
  border-left: 3px solid var(--cw-border-strong, #2B756A);
  padding-left: 0.75rem;
}

/* ── Round dividers ──────────────────────────────────────────────── */
.round-divider {
  max-width: 900px;
  margin: 3rem auto 2rem;
  border-bottom: 2px solid var(--cw-border-strong, #2B756A);
  padding-bottom: 0.75rem;
}
.round-divider h2 {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--cw-text-default, #09141A);
  margin-bottom: 0.25rem;
}
.round-divider p {
  font-size: 0.9rem;
  color: var(--cw-text-muted, #756D63);
}

/* ── Round 1 section (reference/collapsed) ─────────────────────── */
.r1-section {
  border-top: 2px dashed var(--cw-border-default, #C9D4CF);
  margin-top: 4rem;
  padding-top: 2rem;
}
.r1-section-header {
  max-width: 900px;
  margin: 0 auto 1.5rem;
}
.r1-section-label {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--cw-text-muted, #756D63);
  margin-bottom: 0.5rem;
}
.r1-section-note {
  font-size: 0.9rem;
  color: var(--cw-text-muted, #756D63);
  font-style: italic;
}

.candidate-card, .recommendation-section, .lineup-section {
  max-width: 900px;
  margin: 0 auto 4rem;
  background: var(--cw-surface-inset, #FFFFFF);
  border-radius: 8px;
  padding: 2rem;
  border: 1px solid var(--cw-border-default, #C9D4CF);
}

/* ── Round 2 card accent ──────────────────────────────────────────── */
.r2-card {
  border-color: var(--cw-border-strong, #2B756A);
  border-width: 1.5px;
}
.r2-id {
  color: var(--cw-border-strong, #2B756A);
}

/* ── Card header ─────────────────────────────────────────────────── */
.card-header {
  display: flex;
  align-items: flex-start;
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}
.candidate-id {
  font-size: 3rem;
  font-weight: 900;
  line-height: 1;
  color: var(--cw-border-strong, #2B756A);
  min-width: 2.5rem;
  flex-shrink: 0;
}
.candidate-name {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.25rem;
}
.candidate-concept {
  font-size: 0.95rem;
  color: var(--cw-text-muted, #756D63);
}
.recommended-badge {
  display: inline-block;
  margin-left: 0.75rem;
  background: var(--cw-border-strong, #2B756A);
  color: #fff;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 0.15rem 0.5rem;
  border-radius: 2px;
  vertical-align: middle;
}
.exploratory-badge {
  display: inline-block;
  margin-left: 0.5rem;
  background: #9A4D35;
  color: #fff;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 0.15rem 0.5rem;
  border-radius: 2px;
  vertical-align: middle;
}

/* ── Section headings ────────────────────────────────────────────── */
.section-title {
  font-size: 1.5rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
  border-bottom: 1px solid var(--cw-border-default, #C9D4CF);
  padding-bottom: 0.5rem;
}
.section-subtitle {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--cw-text-subtle, #7C746A);
  margin: 1.25rem 0 0.5rem;
  font-weight: 600;
}
.section-intro {
  font-size: 0.9rem;
  color: var(--cw-text-muted, #756D63);
  margin-bottom: 1.25rem;
}

/* ── Swatch contexts ─────────────────────────────────────────────── */
.swatch-row {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 0.5rem;
}
.swatch {
  flex: 1 1 240px;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid var(--cw-border-default, #C9D4CF);
}
.swatch-foam  { background: #F7F1E6; color: #09141A; }
.swatch-dark  { background: #09141A; color: #F7F1E6; }
.swatch-white { background: #FFFFFF; color: #09141A; }

.swatch-label {
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 0.35rem 0.75rem;
  opacity: 0.6;
}
.swatch-inner {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
  min-height: 120px;
}
.swatch-inner.typemark-render {
  padding: 1.5rem 1rem;
  min-height: 80px;
  overflow: hidden;
}

/* ── Monochrome render ───────────────────────────────────────────── */
.mono-row {
  margin-bottom: 0.5rem;
}
.mono-render {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #FFFFFF;
  border: 1px solid var(--cw-border-default, #C9D4CF);
  border-radius: 6px;
  padding: 1rem;
  color: #09141A;
}
.mono-render.typemark-render {
  display: block;
  padding: 1rem;
  overflow: hidden;
}

/* ── Small renders ───────────────────────────────────────────────── */
.small-renders {
  display: flex;
  gap: 1.5rem;
  align-items: flex-end;
  flex-wrap: wrap;
  margin-bottom: 0.5rem;
}
.small-render-item {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.25rem;
  background: #F7F1E6;
  border: 1px solid var(--cw-border-default, #C9D4CF);
  border-radius: 6px;
  padding: 0.75rem;
  color: #09141A;
}
.render-size-label {
  font-size: 0.65rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--cw-text-subtle, #7C746A);
}

/* ── Favicon mock ────────────────────────────────────────────────── */
.favicon-mock-wrap {
  display: inline-block;
  border: 1px solid #C0C0C0;
  border-radius: 6px 6px 0 0;
  overflow: hidden;
  font-size: 12px;
  font-family: system-ui, sans-serif;
  background: #E8E8E8;
  min-width: 320px;
}
.tab-bar {
  display: flex;
  align-items: flex-end;
  background: #E8E8E8;
  padding: 6px 6px 0;
  gap: 4px;
}
.tab-mock {
  display: flex;
  align-items: center;
  gap: 5px;
  background: #F5F5F5;
  border: 1px solid #C0C0C0;
  border-bottom: 1px solid #F5F5F5;
  border-radius: 5px 5px 0 0;
  padding: 4px 8px;
  min-width: 160px;
  max-width: 200px;
  overflow: hidden;
}
.favicon-area {
  display: inline-flex;
  align-items: center;
  flex-shrink: 0;
}
.tab-label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 11px;
  color: #333;
}
.tab-close {
  color: #666;
  font-size: 11px;
  flex-shrink: 0;
  cursor: default;
}
.tab-new-btn {
  color: #666;
  font-size: 14px;
  padding: 2px 6px;
  cursor: default;
}
.browser-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #F5F5F5;
  border-top: 1px solid #C0C0C0;
  padding: 4px 8px;
}
.nav-btn {
  font-size: 12px;
  color: #555;
}
.address-bar {
  flex: 1;
  font-size: 11px;
  background: #FFF;
  border: 1px solid #C0C0C0;
  border-radius: 3px;
  padding: 2px 6px;
  color: #333;
}

/* ── Lockups ─────────────────────────────────────────────────────── */
.lockups-section { margin-top: 1.5rem; }
.lockup-row {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
}
.lockup-item {
  flex: 1 1 300px;
}
.lockup-label {
  display: block;
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--cw-text-subtle, #7C746A);
  font-weight: 600;
  margin-bottom: 0.4rem;
}
.lockup-box {
  background: #F7F1E6;
  border: 1px solid var(--cw-border-default, #C9D4CF);
  border-radius: 6px;
  padding: 1rem;
  color: #09141A;
}
.lockup-note {
  font-size: 0.85rem;
  color: var(--cw-text-muted, #756D63);
  font-style: italic;
  padding: 0.5rem 0;
}
.stacked-lockup-wrap {
  max-width: 120px;
}

/* ── Card copy ───────────────────────────────────────────────────── */
.card-copy {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-top: 1.75rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--cw-border-default, #C9D4CF);
}
@media (max-width: 600px) {
  .card-copy { grid-template-columns: 1fr; }
}
.copy-label {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-weight: 700;
  color: var(--cw-text-subtle, #7C746A);
  margin-bottom: 0.35rem;
}
.risk-label { color: #9A4D35; }
.feedback-label { color: var(--cw-border-strong, #2B756A); }
.rationale-block p, .risk-block p {
  font-size: 0.9rem;
  color: var(--cw-text-default, #09141A);
  line-height: 1.6;
}
.feedback-response-block {
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid var(--cw-border-default, #C9D4CF);
}
.feedback-response-text {
  font-size: 0.9rem;
  color: var(--cw-text-default, #09141A);
  line-height: 1.6;
  font-style: italic;
}

/* ── Lineup grid ─────────────────────────────────────────────────── */
.lineup-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  align-items: center;
  justify-content: flex-start;
}
.lineup-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4rem;
}
.lineup-svg { display: flex; align-items: center; justify-content: center; }
.mark-lineup { background: #F7F1E6; border: 1px solid #C9D4CF; border-radius: 6px; padding: 0.5rem; color: #09141A; }
.typemark-lineup { background: #F7F1E6; border: 1px solid #C9D4CF; border-radius: 6px; padding: 0.5rem; color: #09141A; }
.lineup-id {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--cw-text-muted, #756D63);
}

/* ── Recommendation section ──────────────────────────────────────── */
.recommendation-section {
  background: var(--cw-surface-inset, #FFFFFF);
  border: 2px solid var(--cw-border-strong, #2B756A);
}
.r1-recommendation {
  border-color: var(--cw-border-default, #C9D4CF);
  border-width: 1px;
}
.durability-frame {
  font-size: 1rem;
  margin-bottom: 1rem;
}
.rec-reasoning {
  font-size: 0.95rem;
  line-height: 1.7;
  border-left: 3px solid var(--cw-border-strong, #2B756A);
  padding-left: 1rem;
  color: var(--cw-text-default, #09141A);
  margin-bottom: 2rem;
}
.rec-candidate .candidate-card {
  max-width: 100%;
  margin: 0;
  border: 1px solid var(--cw-border-default, #C9D4CF);
}

/* ── Franken section ─────────────────────────────────────────────── */
.franken-section {
  margin-top: 2.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--cw-border-default, #C9D4CF);
}
.franken-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
}
.franken-invite {
  font-size: 0.95rem;
  margin-bottom: 0.5rem;
}
.franken-examples {
  font-size: 0.9rem;
  padding-left: 1.25rem;
  margin-bottom: 1rem;
  line-height: 1.7;
}
.franken-examples li { margin-bottom: 0.35rem; }
.franken-prompt {
  font-size: 1rem;
  font-weight: 600;
  background: var(--cw-surface-raised, #EFE6D6);
  border-left: 3px solid var(--cw-border-strong, #2B756A);
  padding: 0.75rem 1rem;
  border-radius: 0 4px 4px 0;
}

/* ── SVG helper ──────────────────────────────────────────────────── */
.svg-box { display: flex; align-items: center; justify-content: center; overflow: hidden; }
`;

// ─── Assemble the page ───────────────────────────────────────────────────────────

function buildPage() {
  // Round 2 section — leads the page
  const r2Cards = round2Candidates.map((c) => buildR2Card(c)).join('\n');
  const r2RecSection = buildR2RecommendationSection();

  // Round 1 section — for reference only, after Round 2
  const r1Cards = candidates.map((c) => buildCard(c)).join('\n');
  const r1LineupSection = buildLineupGrid();
  const r1RecSection = buildR1RecommendationSection();

  // R2 IDs for sanity check
  const r2Ids = round2Candidates.map(c => c.id);

  return `<!DOCTYPE html>
<!-- GENERATED by build-gallery.mjs — edit gallery-content.mjs and re-run -->
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Crosswake Logo Tournament — Round 2</title>
  <link rel="stylesheet" href="../../tokens/tokens.css">
  <style>${PAGE_CSS}</style>
</head>
<body>

<header class="page-header">
  <h1 class="page-title">Crosswake Logo Tournament — Round 2</h1>
  <p class="page-subtitle">Four candidates responding to round-1 feedback. Round 1 preserved below for reference.</p>
  <p class="durability-headline">Evaluation criterion: which still works at 16px, in one color, in five years.</p>
</header>

<div class="round-divider">
  <h2>Round 2 Candidates</h2>
  <p>All four round-2 candidates below. Round-1 section follows at the bottom of this page.</p>
</div>

${r2Cards}

${r2RecSection}

<div class="r1-section">
  <div class="r1-section-header">
    <p class="r1-section-label">Round 1 — for reference</p>
    <p class="r1-section-note">Round-1 candidates A–G. Kept for provenance. Marks A and B survived to round 2 (as A and B2). Typemarks E/F/G were rejected as a class — see round-2 feedback for diagnosis.</p>
  </div>
  ${r1Cards}
  ${r1LineupSection}
  ${r1RecSection}
</div>

</body>
</html>`;
}

// ─── Write output ────────────────────────────────────────────────────────────────

const html = buildPage();
writeFileSync(OUT_FILE, html, 'utf8');
console.log(`Generated: ${OUT_FILE}`);
console.log(`Size: ${(html.length / 1024).toFixed(1)} KB`);

// Quick sanity checks
const r2Ids = round2Candidates.map(c => c.id);
const checks = {
  'tokens.css link present': html.includes('tokens.css'),
  'swatch-foam class defined': html.includes('swatch-foam'),
  'swatch-dark class defined': html.includes('swatch-dark'),
  'swatch-white class defined': html.includes('swatch-white'),
  'favicon-area class defined': html.includes('favicon-area'),
  'No <img for candidate renders': !html.match(/<img[^>]+src[^>]*>/),
  'currentColor present': html.includes('currentColor'),
  'franken text present': html.toLowerCase().includes('franken'),
  'All 7 R1 candidate ids': candidateIds.every((id) => html.includes(`id="candidate-${id}"`)),
  'All 4 R2 candidate ids': r2Ids.every((id) => html.includes(`id="candidate-${id}"`)),
  'Recommendation section': html.includes('id="recommendation"'),
  'Round 2 section present': html.includes('Round 2'),
  'Round 1 reference section': html.includes('Round 1'),
  'No <text elements in SVG': !html.match(/<text[\s>]/),
};

let allPassed = true;
for (const [check, result] of Object.entries(checks)) {
  const icon = result ? 'OK' : 'FAIL';
  if (!result) allPassed = false;
  console.log(`  ${icon}: ${check}`);
}

if (!allPassed) {
  console.error('\nSome checks failed — review the output above.');
  process.exit(1);
} else {
  console.log('\nAll checks passed.');
}
