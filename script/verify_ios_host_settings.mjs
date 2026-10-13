import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, readSync } from 'node:fs';
import path from 'node:path';

const TARGETS = [
  ['shell', 'CrosswakeShell', 'CrosswakeShell.xcodeproj'],
  ['shell', 'CrosswakeShellTests', 'CrosswakeShell.xcodeproj'],
  ['proof', 'CrosswakeProofLane', 'CrosswakeProofLane.xcodeproj'],
  ['proof', 'CrosswakeProofLaneTests', 'CrosswakeProofLane.xcodeproj'],
  ['proof', 'CrosswakeProofLaneUITests', 'CrosswakeProofLane.xcodeproj'],
];
const CONFIGURATIONS = ['Debug', 'Release'];
const SDKS = ['iphonesimulator', 'iphoneos'];
const SAFE_CAUSES = new Set(['settings_mismatch', 'project_missing', 'metadata_invalid', 'xcodebuild_missing', 'macos_service_denied', 'target_missing', 'project_invalid', 'sdk_unavailable', 'xcodebuild_failed', 'output_invalid']);

function safeFinding(target, configuration, sdk, field, cause) {
  return { target, configuration, sdk, field, cause: SAFE_CAUSES.has(cause) ? cause : 'output_invalid' };
}

function settingsBodyAndDigest(contents) {
  const match = /^\/\/ crosswake-managed-settings-sha256:([a-f0-9]{64})\n/m.exec(contents);
  if (!match) return null;
  const body = contents.slice(match[0].length);
  const digest = createHash('sha256').update(body).digest('hex');
  return digest === match[1] ? body : null;
}

function checkManagedSettings(projectRoot, kind) {
  const settingsPath = kind === 'shell'
    ? path.join(projectRoot, 'crosswake_shell', 'CrosswakeHostSettings.xcconfig')
    : path.join(projectRoot, 'CrosswakeProofSettings.xcconfig');
  try {
    const contents = readFileSync(settingsPath, 'utf8');
    if (kind === 'shell') return contents.includes('CROSSWAKE_APP_BUNDLE_ID =');
    const body = settingsBodyAndDigest(contents);
    if (body === null) return false;
    const pbxPath = path.join(projectRoot, 'CrosswakeProofLane.xcodeproj', 'project.pbxproj');
    const pbx = readFileSync(pbxPath, 'utf8');
    const refs = pbx.match(/baseConfigurationReference = A10000000000000000000019/g) ?? [];
    const resources = /PBXResourcesBuildPhase section \*\/([\s\S]*?)\/\* End PBXResourcesBuildPhase section/.exec(pbx)?.[1] ?? '';
    if (refs.length !== 6 || resources.includes('CrosswakeProofSettings.xcconfig')) return false;
    return true;
  } catch {
    return false;
  }
}

function subprocessCause(child) {
  const diagnostic = `${child.error?.message ?? ''}\n${child.stderr ?? ''}\n${child.stdout ?? ''}`;
  if (child.error?.code === 'ENOENT') return 'xcodebuild_missing';
  if (/operation not permitted|sandbox|not authorized/i.test(diagnostic) || child.error?.code === 'EPERM') return 'macos_service_denied';
  if (/does not contain a target named|target .* not found/i.test(diagnostic)) return 'target_missing';
  if (/project.*(?:malformed|parse|syntax)|could not read project/i.test(diagnostic)) return 'project_invalid';
  if (/SDK .* cannot be located|SDK .* not found|no such SDK/i.test(diagnostic)) return 'sdk_unavailable';
  return 'xcodebuild_failed';
}

function expectedFor(expectedSettings, target, sdk) {
  const appTarget = target === 'CrosswakeShell' || target === 'CrosswakeProofLane';
  const uiTarget = target === 'CrosswakeProofLaneUITests';
  const bundle = target.startsWith('CrosswakeShell')
    ? (appTarget ? expectedSettings.appBundleId : `${expectedSettings.appBundleId}.tests`)
    : appTarget ? expectedSettings.proofAppBundleId : uiTarget
      ? `${expectedSettings.proofAppBundleId}.uitests`
      : `${expectedSettings.proofAppBundleId}.tests`;
  const expected = { PRODUCT_BUNDLE_IDENTIFIER: bundle };
  if (sdk === 'iphonesimulator') {
    expected.CODE_SIGNING_ALLOWED = 'NO';
    expected.CODE_SIGNING_REQUIRED = 'NO';
  } else {
    expected.CODE_SIGN_STYLE = expectedSettings.deviceSigning.mode === 'manual' ? 'Manual' : 'Automatic';
    expected.DEVELOPMENT_TEAM = expectedSettings.deviceSigning.teamId;
  }
  return expected;
}

export function verifyIosHostSettings({ hostRoot, expectedSettings, xcodebuild = 'xcodebuild' }) {
  if (!expectedSettings || typeof expectedSettings !== 'object' ||
      typeof expectedSettings.appBundleId !== 'string' ||
      typeof expectedSettings.proofAppBundleId !== 'string' ||
      !['automatic', 'manual'].includes(expectedSettings.deviceSigning?.mode) ||
      typeof expectedSettings.deviceSigning?.teamId !== 'string') {
    return { ok: false, observedCells: 0, findings: [safeFinding('all', 'all', 'all', 'expected_input', 'output_invalid')] };
  }

  const projectRoot = path.join(hostRoot, 'native', 'ios');
  const findings = [];
  let observedCells = 0;
  for (const [kind, target, projectName] of TARGETS) {
    const project = kind === 'shell'
      ? path.join(projectRoot, 'crosswake_shell', projectName)
      : path.join(projectRoot, projectName);
    if (!checkManagedSettings(projectRoot, kind)) {
      findings.push(safeFinding(target, 'all', 'all', 'managed_settings', 'metadata_invalid'));
      continue;
    }
    for (const configuration of CONFIGURATIONS) for (const sdk of SDKS) {
      const args = ['-project', project, '-target', target, '-configuration', configuration, '-sdk', sdk, '-showBuildSettings', '-json'];
      let child;
      try {
        child = spawnSync(xcodebuild, args, { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024, timeout: 120000 });
      } catch {
        findings.push(safeFinding(target, configuration, sdk, 'build_settings', 'subprocess_failed'));
        continue;
      }
      if (child.error || child.status !== 0) {
        findings.push(safeFinding(target, configuration, sdk, 'build_settings', subprocessCause(child)));
        continue;
      }
      let rows;
      try {
        rows = JSON.parse(child.stdout);
      } catch {
        findings.push(safeFinding(target, configuration, sdk, 'build_settings', 'output_invalid'));
        continue;
      }
      const matches = Array.isArray(rows) ? rows.filter(row => row.target === target && row.buildSettings?.CONFIGURATION === configuration) : [];
      if (matches.length !== 1 || !matches[0]?.buildSettings) {
        findings.push(safeFinding(target, configuration, sdk, 'build_settings', 'output_invalid'));
        continue;
      }
      observedCells += 1;
      const actual = matches[0].buildSettings;
      for (const [field, expected] of Object.entries(expectedFor(expectedSettings, target, sdk))) {
        if (actual[field] !== expected) findings.push(safeFinding(target, configuration, sdk, field, 'settings_mismatch'));
      }
      if (sdk === 'iphoneos' && (actual.CODE_SIGNING_ALLOWED === 'NO' || actual.CODE_SIGNING_REQUIRED === 'NO')) {
        findings.push(safeFinding(target, configuration, sdk, 'device_signing', 'settings_mismatch'));
      }
    }
  }
  return { ok: observedCells === 20 && findings.length === 0, observedCells, findings };
}

function cli() {
  const args = process.argv.slice(2);
  if (args.length !== 2 || args[0] !== '--host-root') {
    process.stdout.write(JSON.stringify({ ok: false, observedCells: 0, findings: [safeFinding('all', 'all', 'all', 'arguments', 'output_invalid')] }));
    process.exitCode = 2;
    return;
  }
  let expectedSettings;
  try { expectedSettings = JSON.parse(readStdinLine()); } catch {
    process.stdout.write(JSON.stringify({ ok: false, observedCells: 0, findings: [safeFinding('all', 'all', 'all', 'expected_input', 'output_invalid')] }));
    process.exitCode = 1;
    return;
  }
  const result = verifyIosHostSettings({ hostRoot: path.resolve(args[1]), expectedSettings });
  process.stdout.write(JSON.stringify(result));
  if (!result.ok) process.exitCode = 1;
}

function readStdinLine() {
  const bytes = Buffer.alloc(1);
  let line = '';
  while (line.length <= 8192) {
    const count = readSync(0, bytes, 0, 1, null);
    if (count === 0 || bytes[0] === 10) break;
    line += bytes.toString('utf8', 0, count);
  }
  return line;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) cli();
