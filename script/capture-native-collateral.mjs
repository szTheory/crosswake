#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const args = parseArgs(process.argv.slice(2));
const outputDir = args.outputDir || join(repoRoot, 'native-collateral-artifacts');
// --screenshot-dir redirects ONLY the binary PNG writes (ios-simulator.png /
// android-emulator.png). The manifest + advisory README stay in --output-dir so
// they never clobber a curated collateral README. Defaults to outputDir for
// backward compatibility with the advisory artifact workflow.
const screenshotDir = args.screenshotDir || outputDir;
const dryRun = args.dryRun;
const platforms = args.platform === 'all' ? ['ios', 'android'] : [args.platform];
const capturedAt = new Date().toISOString();
const commitSha = git(['rev-parse', 'HEAD']) || process.env.GITHUB_SHA || 'unknown';
const crosswakeVersion = readVersion();

mkdirSync(outputDir, { recursive: true });
mkdirSync(screenshotDir, { recursive: true });

const manifest = {
  schema_version: '1.0.0',
  crosswake_version: crosswakeVersion,
  commit_sha: commitSha,
  source_job: process.env.GITHUB_JOB || 'native-collateral-advisory',
  captured_at: capturedAt,
  retention_label: 'ci-artifact-14-days',
  routes: platforms.map((platform) => attempt(platform))
};

writeJson(join(outputDir, 'evidence-manifest.json'), manifest);
writeSummary(join(outputDir, 'README.md'), manifest);

console.log(`native collateral manifest: ${join(outputDir, 'evidence-manifest.json')}`);

function attempt(platform) {
  if (platform === 'ios') {
    return attemptIos();
  }

  if (platform === 'android') {
    return attemptAndroid();
  }

  throw new Error(`unsupported platform: ${platform}`);
}

function attemptIos() {
  const command =
    'CROSSWAKE_IOS_PROJECT_ROOT=examples/ios_shell_host bash script/verify_generated_ios_shell.sh';
  const base = entry({
    routeId: 'ios-simulator-route-tour',
    runtimeOwner: 'native_shell',
    platformRuntime: 'ios-simulator',
    command
  });

  if (dryRun) {
    return unavailable(base, 'Dry run requested; iOS simulator tooling was not invoked.');
  }

  const toolReason = missingToolReason([
    ['xcodebuild', 'missing Xcode xcodebuild'],
    ['xcrun', 'missing Xcode xcrun/simctl']
  ]);

  if (toolReason) {
    return unavailable(base, toolReason);
  }

  if (!hasIosRuntime()) {
    return unavailable(base, 'No available iOS simulator runtime was reported by xcrun simctl.');
  }

  const result = run(command, {
    CROSSWAKE_IOS_PROJECT_ROOT: 'examples/ios_shell_host'
  });

  if (result.status !== 0) {
    return unavailable(base, `iOS verification failed: ${lastLines(result.output)}`);
  }

  const screenshot = join(screenshotDir, 'ios-simulator.png');
  const capture = spawnSync('xcrun', ['simctl', 'io', 'booted', 'screenshot', screenshot], {
    cwd: repoRoot,
    encoding: 'utf8'
  });

  if (capture.status !== 0) {
    return unavailable(base, `iOS simulator screenshot failed: ${lastLines(capture.stderr || capture.stdout)}`);
  }

  return captured(base, 'simulator evidence', [relative(outputDir, screenshot)]);
}

function attemptAndroid() {
  const command =
    'CROSSWAKE_ANDROID_PROJECT_ROOT=examples/android_shell_host CROSSWAKE_ANDROID_CONNECTED_TESTS=1 bash script/verify_generated_android_shell.sh';
  const base = entry({
    routeId: 'android-emulator-route-tour',
    runtimeOwner: 'native_shell',
    platformRuntime: 'android-emulator',
    command
  });

  if (dryRun) {
    return unavailable(base, 'Dry run requested; Android emulator tooling was not invoked.');
  }

  const javaCheck = spawnSync('java', ['-version'], { encoding: 'utf8' });
  if (javaCheck.status !== 0) {
    return unavailable(base, 'No runnable Java runtime was available for Android verification.');
  }

  const result = run(command, {
    CROSSWAKE_ANDROID_PROJECT_ROOT: 'examples/android_shell_host',
    CROSSWAKE_ANDROID_CONNECTED_TESTS: '1'
  });

  if (result.status !== 0) {
    return unavailable(base, `Android emulator verification failed: ${lastLines(result.output)}`);
  }

  const screenshot = join(screenshotDir, 'android-emulator.png');
  const capture = spawnSync(
    'adb',
    ['exec-out', 'screencap', '-p'],
    { cwd: repoRoot, encoding: 'buffer' }
  );

  if (capture.status !== 0 || capture.stdout.length === 0) {
    return unavailable(base, `Android emulator screenshot failed: ${lastLines(String(capture.stderr || capture.stdout))}`);
  }

  writeFileSync(screenshot, capture.stdout);
  return captured(base, 'emulator evidence', [relative(outputDir, screenshot)]);
}

function entry({ routeId, runtimeOwner, platformRuntime, command }) {
  return {
    route_id: routeId,
    runtime_owner: runtimeOwner,
    platform_runtime: platformRuntime,
    command,
    proof_class: 'advisory evidence',
    support_label: 'advisory evidence',
    coordinate_mode: 'checked-in public-coordinate proof',
    source_job: process.env.GITHUB_JOB || 'native-collateral-advisory',
    captured_at: capturedAt,
    commit_sha: commitSha,
    artifacts: [],
    retention_label: 'ci-artifact-14-days',
    known_limitations: [
      'Native simulator/emulator collateral is advisory evidence only.',
      'This native collateral does not prove physical-device support, camera support, media-upload support, provider authority, app-store readiness, or merge-blocking native support.'
    ],
    status: 'unavailable'
  };
}

function captured(base, supportLabel, artifacts) {
  return {
    ...base,
    support_label: supportLabel,
    artifacts,
    status: 'captured'
  };
}

function unavailable(base, reason) {
  return {
    ...base,
    status: 'unavailable',
    unavailable_reason: reason
  };
}

function run(command, env) {
  const child = spawnSync('bash', ['-lc', command], {
    cwd: repoRoot,
    env: { ...process.env, ...env },
    encoding: 'utf8'
  });

  return {
    status: child.status,
    output: [child.stdout, child.stderr].filter(Boolean).join('\n')
  };
}

function missingToolReason(tools) {
  for (const [tool, reason] of tools) {
    if (spawnSync('bash', ['-lc', `command -v ${tool}`], { encoding: 'utf8' }).status !== 0) {
      return reason;
    }
  }

  return null;
}

function hasIosRuntime() {
  const result = spawnSync('xcrun', ['simctl', 'list', 'runtimes', 'available'], {
    cwd: repoRoot,
    encoding: 'utf8'
  });

  return result.status === 0 && /com\.apple\.CoreSimulator\.SimRuntime\.iOS/.test(result.stdout);
}

function git(gitArgs) {
  const result = spawnSync('git', gitArgs, { cwd: repoRoot, encoding: 'utf8' });
  return result.status === 0 ? result.stdout.trim() : null;
}

function readVersion() {
  const mix = readFileSync(join(repoRoot, 'mix.exs'), 'utf8');
  const match = mix.match(/@version\s+"([^"]+)"/);
  return match ? match[1] : 'unknown';
}

function writeJson(path, value) {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function writeSummary(path, manifest) {
  const rows = manifest.routes
    .map((route) => `- ${route.route_id}: ${route.status}${route.unavailable_reason ? ` (${route.unavailable_reason})` : ''}`)
    .join('\n');

  writeFileSync(
    path,
    [
      '# Crosswake Native Advisory Evidence',
      '',
      'This bundle is advisory evidence. Browser route-tour correctness remains the merge-blocking proof.',
      'Native simulator/emulator collateral does not prove physical-device support, camera support, media-upload support, provider authority, app-store readiness, or merge-blocking native support.',
      '',
      rows,
      ''
    ].join('\n')
  );
}

function parseArgs(argv) {
  const parsed = { dryRun: false, outputDir: null, screenshotDir: null, platform: 'all' };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--dry-run') {
      parsed.dryRun = true;
    } else if (arg === '--output-dir') {
      parsed.outputDir = argv[++index];
    } else if (arg === '--screenshot-dir') {
      parsed.screenshotDir = argv[++index];
    } else if (arg === '--platform') {
      parsed.platform = argv[++index];
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }

  if (!['all', 'ios', 'android'].includes(parsed.platform)) {
    throw new Error('--platform must be one of all, ios, android');
  }

  return parsed;
}

function lastLines(text) {
  return String(text || '')
    .trim()
    .split('\n')
    .slice(-5)
    .join(' ')
    .slice(0, 600) || 'no diagnostic output';
}
