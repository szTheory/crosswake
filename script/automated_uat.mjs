#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const phase150 = {
  phase: '150',
  phaseName: 'field-service-showcase',
  uatPath: '.planning/phases/150-field-service-showcase/150-UAT.md',
  manifestPath: 'examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json',
  source: [
    '150-01-SUMMARY.md',
    '150-02-SUMMARY.md',
    '150-03-SUMMARY.md',
    '150-04-SUMMARY.md',
    '150-05-SUMMARY.md',
    '150-06-SUMMARY.md',
    '150-07-SUMMARY.md',
  ],
  tests: [
    {
      name: 'Cold Start Smoke Test',
      expected:
        'Playwright starts the Phoenix example host from scratch with `ecto.drop`, `ecto.create`, `ecto.migrate`, and `phx.server`; `/fieldserv/jobs` loads live Fieldserv data after that cold start.',
      proof: 'route-tour Playwright webServer command plus Fieldserv route assertions',
    },
    {
      name: 'Fieldserv Jobs Queue',
      expected:
        'Opening `/fieldserv/jobs` shows a product-first Fieldserv jobs queue with realistic jobs, assets, technicians, dispatcher/reviewer context, technician state, evidence blockers, route-owner badges, and stable links into job detail pages.',
      proof: 'focused ExUnit field_service tests plus `fieldserv-jobs` route-tour manifest entry',
    },
    {
      name: 'Fieldserv Job Detail',
      expected:
        'Opening a Fieldserv job detail page shows realistic asset, dispatch, reviewer, inspection, notes/activity, evidence timeline, cached read-only posture, route/support truth, and clear links to inspection, native capture, and evidence review.',
      proof: 'focused ExUnit field_service tests plus `fieldserv-job-detail` route-tour manifest entry',
    },
    {
      name: 'Inspection Workspace',
      expected:
        'Opening a job inspection workspace shows checklist rows, cached read-only/degraded posture, future offline-island requirements, and a server-recorded inspection event action without claiming local-first mutation, journals, or outbox support.',
      proof: 'negative route-tour copy assertions plus `fieldserv-inspection` route-tour manifest entry',
    },
    {
      name: 'Native Capture Handoff',
      expected:
        'Opening a job capture route shows a native-screen handoff/fallback with camera capability, media pack, capture-upload transfer metadata, permission truth, scanner/document-scan future pressure, and navigation back into Fieldserv evidence review without browser camera or scanner controls.',
      proof: 'router metadata assertions plus `fieldserv-capture-handoff` route-tour manifest entry',
    },
    {
      name: 'Backend Evidence Review',
      expected:
        'Opening evidence review shows device evidence, backend verification pending, backend verified, and backend rejected as closed server-side states. Using the review actions updates Fieldserv evidence through backend-authoritative transitions, not device-owned availability.',
      proof: 'focused evidence ExUnit tests plus `fieldserv-evidence-review` route-tour manifest entry',
    },
    {
      name: 'Route Diagnostics and Support Truth',
      expected:
        'Fieldserv pages expose inline diagnostics and support labels derived from route metadata. They distinguish LiveView, native-screen capture, cached read-only offline posture, future native gaps, and unsupported scanner/document-scan/permission breadth without claiming shipped support.',
      proof: 'diagnostics ExUnit tests plus route-tour diagnostics assertions',
    },
    {
      name: 'Showcase Reset and Deterministic Data',
      expected:
        'Running or triggering the showcase reset returns deterministic Fieldserv counts and digest data. Reloading the lane after reset shows the same believable jobs, assets, technician state, route posture, and evidence rows without duplicate or drifting fixture data.',
      proof: 'showcase reset ExUnit tests plus route-tour reset preflight',
    },
    {
      name: 'Fieldserv Browser Proof',
      expected:
        'The route-tour proof walks jobs -> detail -> inspection -> native capture -> evidence review and passes semantic assertions for route IDs, runtime ownership, support labels, cached read-only posture, permission truth, backend verification, visible focus, mobile/dark/reduced-motion coverage, and no horizontal overflow before screenshots are treated as collateral.',
      proof: 'route-tour Playwright proof and evidence-manifest validation',
    },
  ],
  commands: [
    {
      label: 'focused Fieldserv ExUnit proof',
      cwd: 'examples/phoenix_host',
      command: [
        'mix',
        'test',
        '--warnings-as-errors',
        'test/crosswake_example/field_service',
        'test/crosswake_example/showcase/catalog_test.exs',
        'test/crosswake_example/showcase/reset_test.exs',
      ],
    },
    {
      label: 'route-tour Playwright proof',
      cwd: 'examples/phoenix_host',
      command: ['npx', 'playwright', 'test', 'e2e/route_tour.spec.ts'],
      env: { CI: '1' },
    },
    {
      label: 'route-tour evidence manifest ExUnit proof',
      cwd: '.',
      command: ['mix', 'test', 'test/crosswake/guides/evidence_manifest_test.exs'],
      env: {
        CROSSWAKE_EVIDENCE_MANIFEST_PATH:
          'examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json',
      },
    },
  ],
  capturedRoutes: [
    'fieldserv-jobs',
    'fieldserv-job-detail',
    'fieldserv-inspection',
    'fieldserv-capture-handoff',
    'fieldserv-evidence-review',
  ],
  pressureRoutes: [
    'fieldserv-capture-pressure',
    'fieldserv-scanner-pressure',
    'fieldserv-document-scan-pressure',
    'fieldserv-media-upload-pressure',
    'fieldserv-offline-inspection-pressure',
  ],
};

const specs = new Map([[phase150.phase, phase150]]);

main();

function main() {
  const args = parseArgs(process.argv.slice(2));
  const spec = specs.get(args.phase);

  if (!spec) {
    die(`unsupported phase ${args.phase}; supported phases: ${[...specs.keys()].join(', ')}`);
  }

  if (args.mode === 'write') {
    runProofCommands(spec);
    const manifest = readAndValidateManifest(spec);
    writeUat(spec, manifest);
    console.log(`automated UAT complete: ${spec.uatPath}`);
    return;
  }

  const manifest = readAndValidateManifest(spec);
  validateUat(spec, manifest);
  console.log(`automated UAT check passed: ${spec.uatPath}`);
}

function parseArgs(argv) {
  const parsed = { phase: null, mode: null };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    }

    if (arg === '--phase') {
      parsed.phase = argv[index + 1];
      index += 1;
      continue;
    }

    if (arg === '--write') {
      parsed.mode = claimMode(parsed.mode, 'write');
      continue;
    }

    if (arg === '--check') {
      parsed.mode = claimMode(parsed.mode, 'check');
      continue;
    }

    die(`unknown argument: ${arg}`);
  }

  if (!parsed.phase) {
    die('missing --phase <number>');
  }

  if (!parsed.mode) {
    die('choose exactly one mode: --write or --check');
  }

  return parsed;
}

function claimMode(current, next) {
  if (current && current !== next) {
    die('choose exactly one mode: --write or --check');
  }

  return next;
}

function printHelp() {
  console.log(`Usage: node script/automated_uat.mjs --phase 150 (--write | --check)

Modes:
  --write  Run the automated proof commands, validate evidence, and rewrite the phase UAT file.
  --check  Validate the existing UAT file and route-tour evidence without rewriting tracked files.
`);
}

function runProofCommands(spec) {
  for (const proofCommand of spec.commands) {
    const display = formatCommand(proofCommand);
    console.log(`\n==> ${proofCommand.label}`);
    console.log(`    ${relativePath(proofCommand.cwd)}$ ${display}`);

    const result = spawnSync(proofCommand.command[0], proofCommand.command.slice(1), {
      cwd: path.join(repoRoot, proofCommand.cwd),
      env: { ...process.env, ...(proofCommand.env ?? {}) },
      stdio: 'inherit',
    });

    if (result.error) {
      die(`${proofCommand.label} failed to start: ${result.error.message}`);
    }

    if (result.status !== 0) {
      die(`${proofCommand.label} exited with ${result.status}`);
    }
  }
}

function readAndValidateManifest(spec) {
  const manifestPath = path.join(repoRoot, spec.manifestPath);

  if (!existsSync(manifestPath)) {
    die(`missing route-tour evidence manifest: ${spec.manifestPath}`);
  }

  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  const routes = new Map((manifest.routes ?? []).map(route => [route.route_id, route]));
  const artifactRoot = path.dirname(manifestPath);

  for (const routeId of spec.capturedRoutes) {
    const route = requireRoute(routes, routeId);
    assertEqual(route.status, 'captured', `${routeId} status`);
    assertEqual(route.proof_class, 'merge-blocking', `${routeId} proof_class`);

    if (!Array.isArray(route.artifacts) || route.artifacts.length === 0) {
      die(`route ${routeId} has no artifacts`);
    }

    for (const artifact of route.artifacts) {
      const artifactPath = path.join(artifactRoot, artifact);
      if (!existsSync(artifactPath)) {
        die(`route ${routeId} missing artifact ${artifact}`);
      }
    }
  }

  for (const routeId of spec.pressureRoutes) {
    const route = requireRoute(routes, routeId);
    assertEqual(route.status, 'unavailable', `${routeId} status`);

    if (route.proof_class === 'merge-blocking') {
      die(`route ${routeId} must not claim merge-blocking proof`);
    }

    if (!route.unavailable_reason) {
      die(`route ${routeId} missing unavailable_reason`);
    }
  }

  console.log(
    `validated route-tour manifest: ${spec.capturedRoutes.length} captured Fieldserv routes, ${spec.pressureRoutes.length} pressure rows`,
  );

  return manifest;
}

function requireRoute(routes, routeId) {
  const route = routes.get(routeId);
  if (!route) {
    die(`route-tour manifest missing route ${routeId}`);
  }
  return route;
}

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    die(`${label}: expected ${expected}, got ${actual}`);
  }
}

function writeUat(spec, manifest) {
  const uatPath = path.join(repoRoot, spec.uatPath);
  const existing = existsSync(uatPath) ? readFileSync(uatPath, 'utf8') : '';
  const started = existing.match(/^started:\s*(.+)$/m)?.[1] ?? new Date().toISOString();
  const updated = new Date().toISOString();
  const content = renderUat(spec, manifest, started, updated);

  writeFileSync(uatPath, content);
}

function renderUat(spec, manifest, started, updated) {
  const tests = spec.tests
    .map((test, index) => {
      const number = index + 1;
      return `### ${number}. ${test.name}
expected: ${test.expected}
result: pass
proof: ${test.proof}`;
    })
    .join('\n\n');

  const commandList = spec.commands
    .map(command => `- \`${command.cwd === '.' ? '' : `cd ${command.cwd} && `}${formatCommand(command)}\``)
    .join('\n');

  const captured = spec.capturedRoutes.map(routeId => `- ${routeId}`).join('\n');
  const pressure = spec.pressureRoutes.map(routeId => `- ${routeId}`).join('\n');

  return `---
status: complete
phase: ${spec.phase}-${spec.phaseName}
source: [${spec.source.join(', ')}]
started: ${started}
updated: ${updated}
---

## Current Test

[testing complete]

## Tests

${tests}

## Summary

total: ${spec.tests.length}
passed: ${spec.tests.length}
issues: 0
pending: 0
skipped: 0
blocked: 0

## Automated Evidence

automated_by: script/automated_uat.mjs
manifest: ${spec.manifestPath}
manifest_schema_version: ${manifest.schema_version}
manifest_commit: ${manifest.commit_sha}
manifest_source_job: ${manifest.source_job}
manifest_retention: ${manifest.retention_label}

commands:
${commandList}

captured_fieldserv_routes:
${captured}

fieldserv_pressure_rows:
${pressure}

visual_threshold: Semantic and layout assertions pass; screenshots are collateral artifacts, not pixel baselines.

## Gaps

[none]
`;
}

function validateUat(spec, manifest) {
  const uatPath = path.join(repoRoot, spec.uatPath);

  if (!existsSync(uatPath)) {
    die(`missing UAT file: ${spec.uatPath}`);
  }

  const uat = readFileSync(uatPath, 'utf8');
  const requiredFragments = [
    'status: complete',
    `[testing complete]`,
    `total: ${spec.tests.length}`,
    `passed: ${spec.tests.length}`,
    'issues: 0',
    'pending: 0',
    'automated_by: script/automated_uat.mjs',
    `manifest_schema_version: ${manifest.schema_version}`,
    'visual_threshold: Semantic and layout assertions pass',
  ];

  for (const fragment of requiredFragments) {
    if (!uat.includes(fragment)) {
      die(`UAT file missing expected fragment: ${fragment}`);
    }
  }

  const passCount = (uat.match(/^result: pass$/gm) ?? []).length;
  if (passCount !== spec.tests.length) {
    die(`expected ${spec.tests.length} passing UAT results, found ${passCount}`);
  }

  console.log(`validated UAT file: ${spec.tests.length}/${spec.tests.length} automated checkpoints passed`);
}

function relativePath(cwd) {
  return cwd === '.' ? '.' : cwd;
}

function formatCommand(command) {
  const envPrefix = Object.entries(command.env ?? {})
    .map(([key, value]) => `${key}=${shellQuote(value)}`)
    .join(' ');
  const executable = command.command.map(shellQuote).join(' ');

  return envPrefix ? `${envPrefix} ${executable}` : executable;
}

function shellQuote(value) {
  if (/^[A-Za-z0-9_./:@%+=,-]+$/.test(value)) {
    return value;
  }

  return `'${value.replaceAll("'", "'\\''")}'`;
}

function die(message) {
  console.error(`automated_uat: ${message}`);
  process.exit(1);
}
