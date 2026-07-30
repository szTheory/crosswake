/**
 * GUARD-01 — AST-based E2E honesty check for pinned route proof specs
 *
 * Purpose: Prevent future PRs from silently reverting an honest E2E proof back to
 * injection-based fabrication, or deleting one outright. Pinned specs are the
 * offline-sync route proof (phases 112–113) and the bridge evidence panel proof
 * (phase 154-08), which mechanizes what was previously a human verification gate —
 * a gate nothing else would notice the loss of. This script parses
 * the spec via the TypeScript compiler API (AST, not regex) and bans three fabrication
 * shapes unconditionally — no bypassable `// OBSERVATION_ONLY` allowlist (D-05).
 *
 * Three banned shapes (exit 1 if any detected):
 *   1. inject-global:    string literal matching `crosswake_offline_mutations`
 *   2. fetch-in-evaluate: fetch/XMLHttpRequest/sendBeacon call INSIDE a page.evaluate callback
 *   3. minted-uuid:      crypto.randomUUID property access, or a `uuid` import
 *
 * Legitimate constructs that are NOT flagged:
 *   - IndexedDB reads (indexedDB.open) inside page.evaluate — observation only
 *   - window.dispatchEvent(new Event('online')) inside page.evaluate — env simulation
 *   - page.request.post (APIRequestContext) OUTSIDE page.evaluate — duplicate-flush
 *
 * Missing spec file → exit 1 (anti-rename/delete evasion).
 *
 * See REQUIREMENTS.md GUARD-01 and the phase 112–113 honest rewrite.
 *
 * Dependency resolution: typescript is pinned as an explicit devDependency in
 * examples/phoenix_host/package.json. This script resolves it from that location
 * so the CI guard-01 job can run `npm ci --prefix examples/phoenix_host` once and
 * use the same install as the Playwright e2e-proof job.
 */

import { readFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

// Resolve the path to the directory containing THIS script, then walk up to the repo root.
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');

// typescript lives in examples/phoenix_host/node_modules — resolve from there.
// Run `npm ci --prefix examples/phoenix_host` before this script in CI.
const requireFrom = createRequire(path.join(REPO_ROOT, 'examples/phoenix_host/package.json'));
let ts;
try {
  ts = requireFrom('typescript');
} catch (e) {
  console.error('\n  ✖ GUARD-01 cannot run — typescript module not found.\n');
  console.error('  Run: npm ci --prefix examples/phoenix_host');
  console.error('  Then retry: node script/check-e2e-honesty.mjs\n');
  process.exit(1);
}

const FILES = [
  'examples/phoenix_host/e2e/evidence_panel.spec.ts',
  'examples/phoenix_host/e2e/offline_sync.spec.ts',
  'examples/phoenix_host/e2e/route_tour.spec.ts',
  'examples/phoenix_host/e2e/support/offline_route_proof.ts',
];

/** Violations accumulated: [lineNumber, ruleId, message] */
const V = [];

/** True if node is a `.evaluate(...)` call expression */
const isEvaluate = n =>
  ts.isCallExpression(n) &&
  ts.isPropertyAccessExpression(n.expression) &&
  n.expression.name.text === 'evaluate';

/** True if node is a network call: fetch/XMLHttpRequest identifier, or .fetch/.sendBeacon property access */
const isNetwork = n => {
  if (!ts.isCallExpression(n)) return false;
  const c = n.expression;
  if (ts.isIdentifier(c)) return c.text === 'fetch' || c.text === 'XMLHttpRequest';
  if (ts.isPropertyAccessExpression(c)) return c.name.text === 'fetch' || c.name.text === 'sendBeacon';
  return false;
};

for (const file of FILES) {
  if (!existsSync(file)) {
    console.error(`\n  ✖ GUARD-01 FAILED — ${file} is missing.\n`);
    console.error('  Every pinned route proof file must exist. A rename or deletion defeats the honesty guard.');
    console.error('  See REQUIREMENTS.md GUARD-01, COLL-01, and the route-tour offline-study proof.\n');
    process.exit(1);
  }

  const src = readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, src, ts.ScriptTarget.Latest, /*setParentNodes=*/true);

  /** 1-based line number of an AST node */
  const at = n => sf.getLineAndCharacterOfPosition(n.getStart(sf)).line + 1;

  (function walk(node) {
    // Rule 1: banned global injection symbol as a string literal
    if (ts.isStringLiteral(node) && /crosswake_offline_mutations/.test(node.text)) {
      V.push([
        file,
        at(node),
        'inject-global',
        "Forbidden string literal 'crosswake_offline_mutations' — this is the injected global from the fake " +
        "fabrication pattern. The offline-study route proof reads from the app-owned IndexedDB outbox, never injects a global.",
      ]);
    }

    // Rule 2: check uuid import (import ... from 'uuid') or require('uuid')
    if (ts.isImportDeclaration(node)) {
      const specifier = node.moduleSpecifier;
      if (ts.isStringLiteral(specifier) && specifier.text === 'uuid') {
        V.push([
          file,
          at(node),
          'minted-uuid',
          "import from 'uuid' detected — the offline-study route proof READS client_mutation_id from IndexedDB " +
          "(minted by the app), never imports a uuid library to mint its own.",
        ]);
      }
    }

    // Rule 3: randomUUID property access (crypto.randomUUID)
    if (ts.isPropertyAccessExpression(node) && node.name.text === 'randomUUID') {
      V.push([
        file,
        at(node),
        'minted-uuid',
        "crypto.randomUUID() in offline-study proof — the test READS client_mutation_id from IndexedDB " +
        "(app-generated UUID, E2E-03b), never mints its own. See REQUIREMENTS.md GUARD-01.",
      ]);
    }

    // Rule 4: scan INSIDE page.evaluate callbacks for network calls only
    if (isEvaluate(node) && node.arguments[0]) {
      (function scan(inner) {
        if (isNetwork(inner)) {
          V.push([
            file,
            at(inner),
            'fetch-in-evaluate',
            "fetch()/XMLHttpRequest/sendBeacon inside page.evaluate — this is a fabrication shape. " +
            "The offline-study app code must flush the outbox on reconnect, not the route-tour test. " +
            "IndexedDB reads and window.dispatchEvent in the same callback are intentionally NOT flagged.",
          ]);
        }
        ts.forEachChild(inner, scan);
      })(node.arguments[0]);
      // Note: we continue walking the rest of the tree via the fall-through below.
      // The evaluate callback was already scanned above (network-only scan).
      // We still need ts.forEachChild(node, walk) to catch outer-level violations.
    }

    ts.forEachChild(node, walk);
  })(sf);
}

if (V.length > 0) {
  console.error(`\n  ✖ E2E honesty check FAILED — offline-study proof regressed toward fabrication.\n`);
  for (const [file, ln, rule, msg] of V) {
    console.error(`  ${file}`);
    console.error(`  [${rule}] line ${ln}`);
    console.error(`      ${msg}\n`);
  }
  console.error('  The offline-study E2E and route-tour proof must prove the REAL path:');
  console.error('    UI click → IndexedDB outbox → app-driven reconnect flush → Ecto confirms one row');
  console.error('  NOT fabricate it via window[] injection, fetch-in-evaluate, or minted UUIDs.');
  console.error('  See REQUIREMENTS.md GUARD-01, COLL-01, and the phase 112–113 honest rewrite.\n');
  process.exit(1);
}

console.log(`  ✓ E2E honesty check passed — ${FILES.join(', ')} observe real app behavior.`);
