#!/usr/bin/env node
// brandbook/tools/contrast.mjs
// WCAG 2.2 contrast matrix for the Crosswake palette.
// Usage: node brandbook/tools/contrast.mjs
// Output: markdown table to stdout — Foreground | Background | Ratio | AA | AAA
// Zero npm dependencies.

import { fileURLToPath } from 'node:url';

// WCAG 2.2 linearization threshold: 0.04045 (corrected May 2021; not 0.03928)
function linearize(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

// Validates hex string format before parseInt (ASVS V5 input validation)
function parseHex(hex) {
  const clean = hex.replace('#', '');
  if (!/^[0-9a-fA-F]{6}$/.test(clean)) {
    throw new Error(`Invalid hex color: ${hex}`);
  }
  return [
    parseInt(clean.slice(0, 2), 16),
    parseInt(clean.slice(2, 4), 16),
    parseInt(clean.slice(4, 6), 16),
  ];
}

function contrast(hex1, hex2) {
  const [r1, g1, b1] = parseHex(hex1);
  const [r2, g2, b2] = parseHex(hex2);
  const l1 = luminance(r1, g1, b1);
  const l2 = luminance(r2, g2, b2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

// 17 primitive colors (16 original + Stone 600 per D-02)
const PALETTE = {
  'current-950': '#09141A',
  'current-900': '#0F1E26',
  'current-800': '#162B35',
  'harbor-700':  '#254855',
  'wake-700':    '#2B756A',
  'wake-500':    '#4E9A8E',
  'kelp-800':    '#123B36',
  'brass-500':   '#C98A2E',
  'brass-700':   '#946017',
  'foam-50':     '#F7F1E6',
  'foam-100':    '#EFE6D6',
  'mist-200':    '#C9D4CF',
  'stone-500':   '#7C746A',
  'stone-600':   '#756D63',
  'rust-600':    '#9A4D35',
  'plum-700':    '#372D4C',
  'white':       '#FFFFFF',
};

// Approved pairings matrix (20+ pairs per RESEARCH.md Finding 4)
// Covers all key semantic pairings and WCAG boundary cases
const PAIRS = [
  // Light surface pairings
  ['foam-50',    'current-950'],  // 16.58 PASS
  ['current-950', 'foam-50'],     // 16.58 PASS
  ['white',      'wake-700'],     // 5.45 PASS
  ['current-950', 'brass-500'],   // 6.35 PASS
  ['wake-500',   'current-950'],  // 5.62 PASS
  ['wake-700',   'foam-50'],      // 4.85 PASS
  ['white',      'rust-600'],     // 6.02 PASS
  ['foam-50',    'plum-700'],     // 11.38 PASS
  ['stone-500',  'foam-50'],      // 4.09 FAIL (AA boundary case — the only true hex failure)
  ['stone-600',  'foam-50'],      // 4.53 PASS (D-02 addition)
  ['stone-600',  'white'],        // 5.09 PASS
  ['brass-700',  'foam-50'],      // 4.74 PASS
  ['wake-500',   'foam-50'],      // 2.95 FAIL (role issue: dark-surface only)
  ['mist-200',   'foam-50'],      // 1.35 FAIL (role issue: border/dark-surface only)
  ['foam-50',    'current-900'],  // 15.14 PASS
  ['mist-200',   'current-950'],  // 12.25 PASS
  ['wake-500',   'current-900'],  // 5.14 PASS
  ['brass-500',  'current-950'],  // 6.35 PASS
  ['white',      'kelp-800'],     // 12.32 PASS
  ['white',      'harbor-700'],   // 9.83 PASS
  ['stone-600',  'current-950'],  // 3.66 non-text only
];

// Main-module guard: only print the matrix when run directly
// (`node contrast.mjs`, the AUDIT.md reproducibility command). When imported
// (contrast.test.mjs, check-consumer-drift.mjs) the matrix MUST stay silent so
// it does not pollute importers' stdout (#drift-gate output hygiene).
const IS_MAIN = process.argv[1] === fileURLToPath(import.meta.url);

if (IS_MAIN) {
  // Main: compute ratios and print markdown table
  const AA_TEXT_THRESHOLD = 4.5;
  const AAA_TEXT_THRESHOLD = 7.0;

  const rows = PAIRS.map(([fg, bg]) => {
    const ratio = contrast(PALETTE[fg], PALETTE[bg]);
    const aa = ratio >= AA_TEXT_THRESHOLD ? 'PASS' : 'FAIL';
    const aaa = ratio >= AAA_TEXT_THRESHOLD ? 'PASS' : 'FAIL';
    return { fg, bg, ratio, aa, aaa };
  });

  console.log('| Foreground | Background | Ratio | AA | AAA |');
  console.log('|------------|------------|-------|-----|-----|');
  rows.forEach(({ fg, bg, ratio, aa, aaa }) => {
    console.log(`| ${fg} | ${bg} | ${ratio.toFixed(2)}:1 | ${aa} | ${aaa} |`);
  });

  const totalPairs = rows.length;
  const failAA = rows.filter(r => r.aa === 'FAIL').length;
  const failAAA = rows.filter(r => r.aaa === 'FAIL').length;

  console.log('');
  console.log(`**${totalPairs} pairings tested. ${failAA} fail AA normal text (< ${AA_TEXT_THRESHOLD}:1). ${failAAA} fail AAA normal text (< ${AAA_TEXT_THRESHOLD}:1).**`);
  console.log('');
  console.log('_Note: Pairs where FAIL reflects a role issue (not a hex defect):_');
  console.log('_wake-500/foam-50 (2.95:1) — dark-surface accent only_');
  console.log('_mist-200/foam-50 (1.35:1) — border and dark-surface text only_');
  console.log('_stone-600/current-950 (3.66:1) — non-text UI elements only (passes 3:1 AA non-text)_');
}

export { linearize, luminance, parseHex, contrast, PALETTE };
