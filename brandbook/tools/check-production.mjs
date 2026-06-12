#!/usr/bin/env node
/**
 * brandbook/tools/check-production.mjs
 * Structural validator for production SVG assets in brandbook/logo/.
 *
 * Extends check-candidates.mjs (checkSvg) with two production-only assertions:
 *   1. No literal <text elements in any file (D-04/D-09: path-only requirement)
 *   2. For files whose name contains "favicon", root viewBox must equal "0 0 16 16"
 *
 * Scans all *.svg under brandbook/logo/ EXCLUDING brandbook/logo/tournament/
 * (tournament candidates are gated by check-candidates.mjs separately).
 *
 * Exits non-zero listing every violating file, mirroring check-candidates output style.
 *
 * Usage:
 *   node brandbook/tools/check-production.mjs [--verbose]
 *
 * Zero additional npm installs — uses only Node built-ins + check-candidates.mjs.
 *
 * D-04: No blind path-node surgery — files must be path/line-only
 * D-05: Validator is part of the mandatory render-verify + structural-check loop
 * D-09: Path-only, no <text, no full-bleed rect
 */

import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkSvg } from './check-candidates.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const LOGO_DIR = resolve(ROOT, 'brandbook/logo');
const TOURNAMENT_DIR = resolve(ROOT, 'brandbook/logo/tournament');

const args = process.argv.slice(2);
const verbose = args.includes('--verbose') || args.includes('-v');

/**
 * Recursively collect all .svg files under dir, excluding excludeDir tree.
 * @param {string} dir - Directory to scan
 * @param {string} excludeDir - Absolute path of directory subtree to skip
 * @returns {string[]} Sorted array of absolute file paths
 */
function collectSvgs(dir, excludeDir) {
  const results = [];
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return results;
  }
  for (const entry of entries) {
    const full = resolve(dir, entry.name);
    if (entry.isDirectory()) {
      if (full === excludeDir) continue; // skip tournament/
      results.push(...collectSvgs(full, excludeDir));
    } else if (entry.isFile() && entry.name.endsWith('.svg')) {
      results.push(full);
    }
  }
  return results.sort();
}

const files = collectSvgs(LOGO_DIR, TOURNAMENT_DIR);

if (files.length === 0) {
  console.log('No SVG files found in brandbook/logo/ (excluding tournament/). Nothing to validate.');
  process.exit(0);
}

console.log(`Checking ${files.length} production SVG(s) in brandbook/logo/ (excluding tournament/)...`);

const allViolations = [];

for (const filePath of files) {
  const filename = relative(ROOT, filePath);
  let content;
  try {
    content = readFileSync(filePath, 'utf8');
  } catch (err) {
    allViolations.push({ file: filename, issues: [`Cannot read file: ${err.message}`] });
    continue;
  }

  // Run shared checkSvg from check-candidates (well-formed, no text, no full-bleed rect, viewBox)
  const issues = checkSvg(content, filename);

  // Production-only assertion 1: no <text at all (D-04/D-09)
  // checkSvg already catches <text> elements — this is an explicit belt-and-suspenders guard
  const hasText = /<text[\s>/]/i.test(content);
  if (hasText && !issues.some(v => v.includes('<text'))) {
    issues.push(`contains <text element(s) — production files must be path-only (D-04/D-09)`);
  }

  // Production-only assertion 2: favicon viewBox must be "0 0 16 16" (D-09)
  const basename = filePath.split('/').pop();
  if (basename.toLowerCase().includes('favicon')) {
    const vbMatch = content.match(/viewBox\s*=\s*["']([^"']+)["']/);
    if (!vbMatch) {
      issues.push(`favicon file missing viewBox — required to be "0 0 16 16" (D-09)`);
    } else {
      const vb = vbMatch[1].trim();
      if (vb !== '0 0 16 16') {
        issues.push(`favicon viewBox "${vb}" must equal "0 0 16 16" (D-09)`);
      }
    }
  }

  if (issues.length > 0) {
    allViolations.push({ file: filename, issues });
    console.error(`FAIL: ${filename}`);
    for (const issue of issues) {
      console.error(`  - ${issue}`);
    }
  } else if (verbose) {
    console.log(`  OK: ${filename}`);
  }
}

if (allViolations.length === 0) {
  console.log(`All ${files.length} production SVG(s) passed structural validation.`);
  process.exit(0);
} else {
  console.error(`\n${allViolations.length} file(s) failed production validation. Fix the above issues before proceeding.`);
  process.exit(1);
}
