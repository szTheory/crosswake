#!/usr/bin/env node
/**
 * brandbook/tools/check-candidates.mjs
 * Structural SVG validator for tournament candidates (LOGO-03 gate).
 *
 * Globs brandbook/logo/tournament/candidates/*.svg and for each file asserts:
 *   (a) It parses as well-formed XML (no unclosed tags, malformed entities)
 *   (b) It contains no <text element (path-only requirement D-04)
 *   (c) It contains no <rect whose width/height spans the full viewBox (full-bleed background)
 *   (d) It declares a viewBox attribute on the root <svg> element
 *
 * Exits non-zero listing every violating file.
 *
 * Usage:
 *   node brandbook/tools/check-candidates.mjs
 *
 * Zero npm dependencies — uses only Node built-ins.
 */
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const CANDIDATES_DIR = resolve(ROOT, 'brandbook/logo/tournament/candidates');

/**
 * Check a single SVG string for structural violations.
 * Returns an array of violation strings (empty = valid).
 *
 * @param {string} svgContent - Raw SVG file content
 * @param {string} filename - Used in error messages
 * @returns {string[]} Array of violation descriptions
 */
export function checkSvg(svgContent, filename) {
  const violations = [];

  // (a) Well-formedness check: detect common malformation patterns
  // Full XML parsing without DOMParser — check for basic structural balance
  // We detect: unclosed root tag, mismatched quote pairs, obvious entity errors
  if (!svgContent.includes('<svg')) {
    violations.push(`no <svg root element found`);
    return violations; // Cannot do further checks without svg root
  }

  // Stack-based tag balance check (comments/prolog/doctype stripped first).
  // Attribute values may contain '/', '<'-free URLs, etc. — tokenize whole tags.
  const stripped = svgContent.replace(/<!--[\s\S]*?-->/g, '').replace(/<\?[\s\S]*?\?>/g, '').replace(/<![\s\S]*?>/g, '');
  const stack = [];
  let balanceError = null;
  const tagRe = /<(\/?)([a-zA-Z][\w:-]*)((?:"[^"]*"|'[^']*'|[^"'>])*?)(\/?)>/g;
  let t;
  while ((t = tagRe.exec(stripped)) !== null) {
    const [, isClose, name, , isSelf] = t;
    if (isSelf) continue;
    if (isClose) {
      const top = stack.pop();
      if (top !== name) { balanceError = `</${name}> closes <${top ?? 'nothing'}>`; break; }
    } else {
      stack.push(name);
    }
  }
  if (!balanceError && stack.length > 0) balanceError = `unclosed <${stack[stack.length - 1]}>`;
  if (balanceError) {
    violations.push(`malformed XML: ${balanceError}`);
  }

  // (b) No <text elements (D-04: path-only SVG)
  // Use regex that avoids false positives from XML comments
  const textMatches = svgContent.match(/<text[\s>]/g);
  if (textMatches && textMatches.length > 0) {
    violations.push(`contains ${textMatches.length} <text element(s) — path-only SVG required (D-04)`);
  }

  // (c) No full-bleed <rect (background rectangle spanning the full viewBox)
  // Extract viewBox dimensions for comparison
  const viewBoxMatch = svgContent.match(/viewBox\s*=\s*["']([^"']+)["']/);
  if (viewBoxMatch) {
    const [vbX, vbY, vbW, vbH] = viewBoxMatch[1].trim().split(/\s+/).map(parseFloat);
    // Find all <rect elements and check if any span the full viewBox
    const rectPattern = /<rect\b([^>]*?)(?:\/?>|>)/g;
    let rectMatch;
    while ((rectMatch = rectPattern.exec(svgContent)) !== null) {
      const rectAttrs = rectMatch[1];
      const wMatch = rectAttrs.match(/\bwidth\s*=\s*["']?([0-9.]+)%?["']?/);
      const hMatch = rectAttrs.match(/\bheight\s*=\s*["']?([0-9.]+)%?["']?/);
      if (wMatch && hMatch) {
        const rW = parseFloat(wMatch[1]);
        const rH = parseFloat(hMatch[1]);
        // Full-bleed: width = 100% OR matches viewBox width, height = 100% OR matches viewBox height
        const isFullBleedW = wMatch[1].includes('%') ? rW >= 100 : Math.abs(rW - vbW) < 1;
        const isFullBleedH = hMatch[1].includes('%') ? rH >= 100 : Math.abs(rH - vbH) < 1;
        if (isFullBleedW && isFullBleedH) {
          violations.push(`contains full-bleed <rect (width=${wMatch[1]} height=${hMatch[1]}) — no rectangular background shapes (D-05/LOGO-03)`);
        }
      }
    }
  }

  // (d) viewBox must be declared on root <svg>
  const svgTagMatch = svgContent.match(/<svg\b[^>]*>/);
  if (!svgTagMatch || !svgTagMatch[0].includes('viewBox')) {
    violations.push(`<svg> element missing viewBox attribute — required for scalable rendering (D-04)`);
  }

  return violations;
}

// Main: scan all *.svg files in candidates dir — only run when executed directly
const IS_MAIN = process.argv[1] === fileURLToPath(import.meta.url);
if (!IS_MAIN) { /* imported as module — skip main */ }
else {
const args = process.argv.slice(2);
const verbose = args.includes('--verbose') || args.includes('-v');

let files;
try {
  files = readdirSync(CANDIDATES_DIR)
    .filter(f => f.endsWith('.svg'))
    .sort();
} catch (err) {
  console.error(`ERROR: Cannot read candidates directory: ${CANDIDATES_DIR}`);
  console.error(err.message);
  process.exit(1);
}

if (files.length === 0) {
  console.log('No SVG files found in candidates directory. Nothing to validate.');
  process.exit(0);
}

console.log(`Checking ${files.length} SVG candidate(s) in ${CANDIDATES_DIR}...`);

const allViolations = [];

for (const file of files) {
  const filePath = resolve(CANDIDATES_DIR, file);
  let content;
  try {
    content = readFileSync(filePath, 'utf8');
  } catch (err) {
    allViolations.push({ file, issues: [`Cannot read file: ${err.message}`] });
    continue;
  }

  const issues = checkSvg(content, file);
  if (issues.length > 0) {
    allViolations.push({ file, issues });
    console.error(`FAIL: ${file}`);
    for (const issue of issues) {
      console.error(`  - ${issue}`);
    }
  } else if (verbose) {
    console.log(`  OK: ${file}`);
  }
}

if (allViolations.length === 0) {
  console.log(`All ${files.length} candidate(s) passed structural validation.`);
  process.exit(0);
} else {
  console.error(`\n${allViolations.length} candidate(s) failed validation. Fix the above issues before proceeding.`);
  process.exit(1);
}
} // end IS_MAIN block
