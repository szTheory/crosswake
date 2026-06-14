#!/usr/bin/env node
/**
 * brandbook/tools/check-consumer-drift.mjs
 * Structural drift gate for normalized consumer CSS and HEEX files.
 *
 * Scans a curated manifest of normalized consumer files and exits non-zero
 * when any file reintroduces a brand-color drift:
 *   1. Hardcoded hex color literal (#RGB / #RRGGBB / #RRGGBBAA)
 *   2. var(--cw-primitive-*) reference (semantic-only boundary rule)
 *   3. CSS file with zero var(--cw-*) references (token coverage lost)
 *   4. HEEX/template with retired Tailwind utility in class="..." attribute
 *
 * Usage:
 *   node brandbook/tools/check-consumer-drift.mjs [--verbose]
 *
 * Zero additional npm installs — uses only Node built-ins + contrast.mjs.
 */

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PALETTE } from './contrast.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');

// Curated manifest — D-02: NOT a glob. Add new normalized consumers here.
// Excluded (deferred offenders):
//   examples/phoenix_host/priv/static/offline_study.js
//     — #9A4D35/#fee2e2/#ef4444 (innerHTML hardcoded hex)
//   examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
//     — bg-[#F8FAFC] / bg-[#2563EB] (dead Tailwind). NOTE: CONTEXT.md has wrong path;
//     correct path verified: crosswake_example/saas_portal/... (not crosswake_example_web/live/...)
// tokens.css excluded — byte-parity covered by compile-tokens.test.mjs:222 (D-04).
export const MANIFEST = [
  { path: 'examples/phoenix_host/priv/static/css/app.css',                                                        type: 'css' },
  { path: 'priv/static/crosswake/offline.css',                                                                     type: 'css' },
  { path: 'priv/templates/crosswake/offline_ui/offline_page.html.heex.eex',                                       type: 'heex' },
  { path: 'priv/templates/crosswake/offline_ui/offline_root.html.heex.eex',                                       type: 'heex' },
  { path: 'examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex',             type: 'heex' },
];

// Retired Tailwind blocklist — D-03 Rule 4 (HEEX/template files only).
// Derived from NORM-04 test contract at test/mix/tasks/crosswake.gen.offline_ui_test.exs lines 120-127.
// Scoped to class="..." attribute values ONLY — not CSS property text.
// [scrollbar-gutter:stable] is intentionally absent — it is a layout primitive with no token
// equivalent and is not a brand-color drift. Do NOT add it to this list.
const RETIRED_TAILWIND = [
  'flex',          // layout utility — NOTE: must check class attrs only, not CSS text
  'bg-white',      // color utility
  'bg-cw-',        // primitive Tailwind color prefix (matches bg-cw-foam-50 etc.)
  'text-cw-',      // primitive Tailwind color prefix
  'min-h-screen',  // layout utility
  'border-cw-',    // primitive Tailwind border prefix
  'border-gray-',  // Tailwind system gray border
  'space-y-',      // spacing utility
  'max-w-md',      // sizing utility
];

/**
 * Find bare hex color literals in CSS/HEEX content.
 * Matches hex broadly in any position (value separators like ':', '=', ';',
 * ',', '(', whitespace, or quotes — covering custom-property assignment
 * `--x=#fff`, SVG/HTML attributes `fill="#fff"`, and `;#fff` separators).
 * The only excluded case is a CSS `#id` selector that opens a rule block
 * (e.g. `#status { ... }`), which is detected per-line and skipped for the
 * id-token at the head of the selector only.
 * Valid CSS hex lengths: 3, 4, 6, or 8 digits (CSS Color 4 — #RGB, #RGBA,
 * #RRGGBB, #RRGGBBAA). Alternation is ordered longest-first so the
 * full-length token is preferred over a shorter prefix.
 * For 6-digit matches, appends palette name if found (e.g. "#2B756A (wake-700)").
 *
 * @param {string} content - File content to scan
 * @returns {{ line: number, text: string, rule: string }[]}
 */
export function findHexColors(content) {
  const violations = [];
  const lines = content.split('\n');
  // Selector-rule heads: a line whose first non-space token is a selector
  // (starts with '.', '#', ':', a tag name, or '[') and opens a block with '{'.
  // We only suppress an `#id` match when it sits in this selector head, before
  // the '{' — a hex inside the rule body on the same line is still flagged.
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const isSelectorLine = /^\s*[.#:a-zA-Z\[][^{}]*\{/.test(line);
    const braceIdx = line.indexOf('{');
    // Match hex in any position; longest-first alternation ({8}|{6}|{4}|{3}).
    const hexRe = /#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})\b/g;
    let m;
    while ((m = hexRe.exec(line)) !== null) {
      // Skip `#id` selector tokens: on a selector-rule line, a hash that
      // appears in the selector head (before the opening '{') is an id
      // selector, not a color literal. A hash after '{' is a real value.
      if (isSelectorLine && braceIdx !== -1 && m.index < braceIdx) {
        continue;
      }
      const fullMatch = m[0]; // e.g. "#2B756A"
      const hexDigits = m[1]; // e.g. "2B756A"
      // PALETTE lookup for human-readable messages (6-digit only; parseHex throws on 3/8-digit)
      const paletteName = hexDigits.length === 6
        ? (Object.entries(PALETTE).find(([, v]) => v.toUpperCase() === fullMatch.toUpperCase())?.[0] ?? null)
        : null;
      violations.push({
        line: i + 1,
        text: paletteName ? `${fullMatch} (${paletteName})` : fullMatch,
        rule: 'hex-color-forbidden',
      });
    }
  }
  return violations;
}

/**
 * Find var(--cw-primitive-*) references — forbidden in consumer CSS/HEEX.
 * Semantic-only boundary rule: primitives must never cross into consumer files.
 *
 * @param {string} content - File content to scan
 * @returns {{ line: number, text: string, rule: string }[]}
 */
export function findPrimitiveRefs(content) {
  const violations = [];
  const lines = content.split('\n');
  const primitiveRe = /var\(--cw-primitive-/g;
  for (let i = 0; i < lines.length; i++) {
    let m;
    while ((m = primitiveRe.exec(lines[i])) !== null) {
      violations.push({
        line: i + 1,
        text: lines[i].trim(),
        rule: 'primitive-token-forbidden',
      });
    }
  }
  return violations;
}

/**
 * Check that a CSS file contains at least one var(--cw-*) reference.
 * Returns { ok: false } when all semantic token coverage has been lost.
 * Only applied to CSS files (type: 'css') — HEEX files reference tokens via linked CSS.
 *
 * @param {string} content - File content to scan
 * @returns {{ ok: boolean }}
 */
export function checkCssSemanticCoverage(content) {
  return { ok: /var\(--cw-/.test(content) };
}

/**
 * Find retired Tailwind utility classes in class="..." / class='...' attribute
 * values.
 * Scoped to quoted class attribute values ONLY — does not scan CSS property text.
 * This guards against false-positives like `display: flex` in inline <style> blocks.
 *
 * Accepts either quote style and matches across newlines (the `[^"]`/`[^']`
 * negated classes span line breaks), covering single-quoted and newline-wrapped
 * `.heex` class lists.
 *
 * KNOWN GAP (WR-01): `class={...}` HEEX dynamic bindings are NOT scanned. The
 * attribute value is an arbitrary Elixir expression evaluated at runtime, not a
 * literal class list; tokenizing it reliably is out of scope and would produce
 * false positives. Retired utilities introduced exclusively via a dynamic
 * `class={...}` binding are an accepted, documented blind spot of this gate.
 *
 * @param {string} content - File content to scan
 * @returns {{ line: number, text: string, rule: string }[]}
 */
export function findRetiredTailwindInClassAttrs(content) {
  const violations = [];
  // Accept double- or single-quoted class attributes. m[1] = double-quoted
  // body, m[2] = single-quoted body; exactly one is set per match.
  const classRe = /class=(?:"([^"]*)"|'([^']*)')/g;
  let m;
  while ((m = classRe.exec(content)) !== null) {
    const classes = m[1] ?? m[2];
    // Find line number by counting newlines up to match index
    const lineNum = content.slice(0, m.index).split('\n').length;
    // Tokenize on whitespace and match per-class, NOT by unbounded substring.
    // Prefix entries (ending in '-', e.g. 'bg-cw-') use startsWith; exact
    // entries (e.g. 'flex') use strict equality. This prevents 'inline-flex',
    // 'flex-col', 'reflex' etc. from falsely matching the exact token 'flex'.
    const tokens = classes.split(/\s+/).filter(Boolean);
    for (const retired of RETIRED_TAILWIND) {
      const isPrefix = retired.endsWith('-');
      for (const cls of tokens) {
        if (isPrefix ? cls.startsWith(retired) : cls === retired) {
          violations.push({ line: lineNum, text: retired, rule: 'retired-tailwind-class-forbidden' });
        }
      }
    }
  }
  return violations;
}

/**
 * Dispatch per-file-class checks for a manifest entry.
 * Every entry: hex + primitive checks.
 * CSS entries additionally: semantic coverage check.
 * HEEX entries additionally: retired Tailwind class attr check.
 *
 * @param {{ path: string, type: 'css'|'heex' }} entry - Manifest entry
 * @param {string} content - File content
 * @returns {{ line: number, text: string, rule: string }[]}
 */
export function checkFile(entry, content) {
  const violations = [];

  // Rule 1: No bare hex color literals (all file types)
  violations.push(...findHexColors(content));

  // Rule 2: No var(--cw-primitive-*) references (all file types)
  violations.push(...findPrimitiveRefs(content));

  if (entry.type === 'css') {
    // Rule 3: CSS files must have ≥1 var(--cw-*) reference
    const coverage = checkCssSemanticCoverage(content);
    if (!coverage.ok) {
      violations.push({ line: 1, text: entry.path, rule: 'semantic-coverage-lost' });
    }
  }

  if (entry.type === 'heex') {
    // Rule 4: HEEX/template files must not contain retired Tailwind class attrs
    violations.push(...findRetiredTailwindInClassAttrs(content));
  }

  return violations;
}

// IS_MAIN guard — allows module import by Plan 02's test without running the scan.
const IS_MAIN = process.argv[1] === fileURLToPath(import.meta.url);

if (IS_MAIN) {
  const args = process.argv.slice(2);
  const verbose = args.includes('--verbose') || args.includes('-v');

  console.log(`Checking ${MANIFEST.length} consumer file(s) for brand-color drift...`);

  const allViolations = [];

  for (const entry of MANIFEST) {
    const abs = resolve(ROOT, entry.path);
    let content;
    try {
      content = readFileSync(abs, 'utf8');
    } catch (err) {
      allViolations.push({ file: entry.path, violations: [{ line: 0, text: `Cannot read file: ${err.message}`, rule: 'file-read-error' }] });
      console.error(`FAIL: ${entry.path}`);
      console.error(`  - Cannot read file: ${err.message}`);
      continue;
    }

    const violations = checkFile(entry, content);

    if (violations.length > 0) {
      allViolations.push({ file: entry.path, violations });
      console.error(`FAIL: ${entry.path}`);
      for (const v of violations) {
        console.error(`  ${entry.path}:${v.line} — ${v.rule} — ${v.text}`);
        // GitHub Actions annotation
        console.error(`::error file=${entry.path},line=${v.line}::${v.rule} ${v.text}`);
      }
    } else if (verbose) {
      console.log(`  OK: ${entry.path}`);
    }
  }

  if (allViolations.length === 0) {
    console.log(`All ${MANIFEST.length} consumer file(s) passed drift check.`);
    process.exit(0);
  } else {
    console.error(`\n${allViolations.length} file(s) failed drift check. Fix the above before proceeding.`);
    process.exit(1);
  }
}
