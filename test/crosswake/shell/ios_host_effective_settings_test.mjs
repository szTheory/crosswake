import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { chmodSync, copyFileSync, mkdirSync, symlinkSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { verifyIosHostSettings } from '../../../script/verify_ios_host_settings.mjs';

const declaration = {
  appBundleId: 'org.crosswake.host',
  proofAppBundleId: 'org.crosswake.host.proof',
  deviceSigning: { mode: 'manual', teamId: 'ABCDE12345' },
};
const automatic = { ...declaration, deviceSigning: { mode: 'automatic', teamId: 'FGHIJ67890' } };

function generateHost(root, host, runTaskCheck = false) {
  const expression = `
    root = System.fetch_env!("CROSSWAKE_MATRIX_ROOT")
    Application.put_env(:crosswake, :ios_host, [
      router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      origin: "https://host-fixture.test",
      entry_route_id: "study-session",
      app_bundle_id: "${host.appBundleId}",
      proof_app_bundle_id: "${host.proofAppBundleId}",
      device_signing: [mode: :${host.deviceSigning.mode}, team_id: "${host.deviceSigning.teamId}"]
    ])
    Application.put_env(:crosswake, :proof_lane, [
      route_id: "route-0123456789abcdef", route_path: "/study/:id",
      indexed_db_database: "proof_lane", indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id", sync_path: "/study/sync",
      evidence_path: "/_proof/evidence", router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      ios_shell_root: Path.join(root, "native/ios")
    ])
    Mix.Task.run("crosswake.gen.shell", ["ios", "--target", root])
    Mix.Task.run("crosswake.gen.proof_lane", ["ios"])
    if ${runTaskCheck ? 'true' : 'false'} do
      Mix.Task.reenable("crosswake.gen.proof_lane")
      Mix.Task.run("crosswake.gen.proof_lane", ["ios", "--check"])
    end
  `;
  execFileSync('mix', ['run', '-e', expression], {
    cwd: process.cwd(),
    env: { ...process.env, MIX_ENV: 'test', CROSSWAKE_MATRIX_ROOT: root },
    stdio: 'pipe',
  });
}

function proofSettings(root) {
  return path.join(root, 'native/ios/CrosswakeProofSettings.xcconfig');
}

function rewriteManagedSettings(file, transform) {
  const contents = readFileSync(file, 'utf8');
  const match = /^\/\/ crosswake-managed-settings-sha256:([a-f0-9]{64})\n([\s\S]*)$/.exec(contents);
  assert.ok(match, 'generated settings have a recognized managed digest');
  const body = transform(match[2]);
  const digest = createHash('sha256').update(body).digest('hex');
  writeFileSync(file, `// crosswake-managed-settings-sha256:${digest}\n${body}`);
}

test('five generated targets resolve all 20 settings cells from the original declaration', { timeout: 600000 }, async t => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'crosswake-ios-matrix-'));
  t.after(() => process.env.CROSSWAKE_KEEP_MATRIX === '1' ? console.log(`retained matrix fixture: ${root}`) : rmSync(root, { recursive: true, force: true }));
  generateHost(root, declaration, true);

  const result = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration });
  assert.equal(result.ok, true, JSON.stringify({ observedCells: result.observedCells, findings: result.findings }));
  assert.equal(result.observedCells, 20);

  const pending = path.join(root, 'native/ios/.crosswake/ios_proof_settings.pending');
  mkdirSync(path.dirname(pending), { recursive: true });
  writeFileSync(pending, 'pending update\n');
  const interruptedBuild = spawnSync('xcodebuild', [
    '-project', path.join(root, 'native/ios/CrosswakeProofLane.xcodeproj'),
    '-target', 'CrosswakeProofLane', '-configuration', 'Debug', '-sdk', 'iphonesimulator', 'build',
  ], { encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024 });
  assert.notEqual(interruptedBuild.status, 0);
  assert.match(`${interruptedBuild.stdout}\n${interruptedBuild.stderr}`, /CROSSWAKE_IOS_PROOF_SETTINGS_INTERRUPTED/);
  rmSync(pending);

  const originalSettings = readFileSync(proofSettings(root), 'utf8');
  rewriteManagedSettings(proofSettings(root), body => body.replace(
    'CROSSWAKE_PROOF_APP_BUNDLE_ID = org.crosswake.host.proof',
    'CROSSWAKE_PROOF_APP_BUNDLE_ID = org.crosswake.wrong.proof',
  ));
  const coherentCorruption = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration });
  assert.equal(coherentCorruption.ok, false);
  assert.ok(coherentCorruption.findings.some(finding => finding.field === 'PRODUCT_BUNDLE_IDENTIFIER' && finding.cause === 'settings_mismatch'));
  writeFileSync(proofSettings(root), originalSettings);

  const projectPath = path.join(root, 'native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj');
  const originalProject = readFileSync(projectPath, 'utf8');
  writeFileSync(projectPath, originalProject.replace(
    'PRODUCT_BUNDLE_IDENTIFIER = "$(CROSSWAKE_PROOF_APP_BUNDLE_ID)";',
    'PRODUCT_BUNDLE_IDENTIFIER = org.crosswake.masked;',
  ));
  const masked = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration });
  assert.equal(masked.ok, false);
  assert.ok(masked.findings.some(finding => finding.field === 'PRODUCT_BUNDLE_IDENTIFIER' && finding.cause === 'settings_mismatch'));
  writeFileSync(projectPath, originalProject);

  rewriteManagedSettings(proofSettings(root), body => `${body}CODE_SIGNING_ALLOWED[sdk=iphoneos*] = NO\n`);
  const unsignedDevice = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration });
  assert.equal(unsignedDevice.ok, false);
  assert.ok(unsignedDevice.findings.some(finding => finding.field === 'device_signing' && finding.cause === 'settings_mismatch'));
  writeFileSync(proofSettings(root), originalSettings);

  writeFileSync(projectPath, originalProject.replace(
    'A10000000000000000000008 /* pronunciation-pack-fixture.bin in Resources */,',
    'A10000000000000000000008 /* pronunciation-pack-fixture.bin in Resources */, CrosswakeProofSettings.xcconfig,',
  ));
  const bundledSettings = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration });
  assert.equal(bundledSettings.ok, false);
  assert.ok(bundledSettings.findings.some(finding => finding.field === 'managed_settings' && finding.cause === 'metadata_invalid'));
  writeFileSync(projectPath, originalProject);

  const malformedInput = spawnSync(process.execPath, [
    path.resolve('script/verify_ios_host_settings.mjs'), '--host-root', root,
  ], { input: '{', encoding: 'utf8' });
  assert.equal(malformedInput.status, 1);
  assert.match(malformedInput.stdout, /expected_input/);
  assert.doesNotMatch(malformedInput.stdout, /ABCDE12345|org\.crosswake/);

  const fakeXcode = path.join(root, 'fake-xcodebuild');
  writeFileSync(fakeXcode, '#!/bin/sh\nprintf "[]\\n"\n');
  chmodSync(fakeXcode, 0o700);
  const missingRows = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration, xcodebuild: fakeXcode });
  assert.equal(missingRows.ok, false);
  assert.ok(missingRows.findings.some(finding => finding.cause === 'output_invalid'));

  writeFileSync(fakeXcode, `#!/bin/sh
target=
configuration=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -target) target=$2; shift 2 ;;
    -configuration) configuration=$2; shift 2 ;;
    *) shift ;;
  esac
done
printf '[{"target":"%s","buildSettings":{"CONFIGURATION":"%s"}},{"target":"%s","buildSettings":{"CONFIGURATION":"%s"}}]\n' "$target" "$configuration" "$target" "$configuration"
`);
  chmodSync(fakeXcode, 0o700);
  const duplicateRows = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration, xcodebuild: fakeXcode });
  assert.equal(duplicateRows.ok, false);
  assert.ok(duplicateRows.findings.some(finding => finding.cause === 'output_invalid'));

  writeFileSync(fakeXcode, '#!/bin/sh\nprintf "private-canary"\nprintf "operation not permitted by macOS service\\n" >&2\nexit 1\n');
  chmodSync(fakeXcode, 0o700);
  const failedXcode = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration, xcodebuild: fakeXcode });
  assert.equal(failedXcode.ok, false);
  assert.ok(failedXcode.findings.some(finding => finding.cause === 'macos_service_denied'));
  assert.doesNotMatch(JSON.stringify(failedXcode), /private-canary|ABCDE12345|org\.crosswake/);
});

test('automatic device signing uses the same declaration oracle and reports no install claim', { timeout: 600000 }, t => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'crosswake-ios-auto-'));
  t.after(() => process.env.CROSSWAKE_KEEP_MATRIX === '1' ? console.log(`retained automatic fixture: ${root}`) : rmSync(root, { recursive: true, force: true }));
  generateHost(root, automatic);
  const result = verifyIosHostSettings({ hostRoot: root, expectedSettings: automatic });
  assert.equal(result.ok, true, JSON.stringify({ observedCells: result.observedCells, findings: result.findings }));
  assert.equal(result.observedCells, 20);
});

test('rejects shell and proof settings referenced through PBX resource object IDs', { timeout: 600000 }, t => {
  const root = mkdtempSync(path.join(os.tmpdir(), 'crosswake-ios-resource-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  generateHost(root, declaration);
  const fakeXcode = path.join(root, 'fake-xcodebuild');
  writeFileSync(fakeXcode, '#!/bin/sh\nprintf "[]\\n"\n');
  chmodSync(fakeXcode, 0o700);

  for (const [kind, projectPath, settingsRef, buildFileId] of [
    ['shell', path.join(root, 'native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj'), 'A10000400000000000000001', 'A10000991000000000000001'],
    ['proof', path.join(root, 'native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj'), 'A10000000000000000000019', 'A10000000000000000000099'],
  ]) {
    const original = readFileSync(projectPath, 'utf8');
    const buildFile = '\n\t\t' + buildFileId + ' = {isa = PBXBuildFile; fileRef = ' + settingsRef + '; };';
    let changed = original.replace('/* End PBXBuildFile section */', buildFile + '\n/* End PBXBuildFile section */');
    const resourceStart = changed.indexOf('/* Begin PBXResourcesBuildPhase section */');
    const resourceEnd = changed.indexOf('/* End PBXResourcesBuildPhase section */', resourceStart);
    const resourceSection = changed.slice(resourceStart, resourceEnd).replace('files = (', 'files = (' + buildFileId + ', ');
    changed = changed.slice(0, resourceStart) + resourceSection + changed.slice(resourceEnd);
    writeFileSync(projectPath, changed);
    const parsed = spawnSync('xcodebuild', ['-list', '-project', path.dirname(projectPath)], { encoding: 'utf8', timeout: 120000 });
    assert.equal(parsed.status, 0, kind + ' PBX resource fixture is accepted by Xcode');
    const result = verifyIosHostSettings({ hostRoot: root, expectedSettings: declaration, xcodebuild: fakeXcode });
    assert.ok(result.findings.some(finding => finding.field === 'managed_settings' && finding.cause === 'metadata_invalid'));
    writeFileSync(projectPath, original);
  }
});

test('CLI entrypoint handles space-containing and symlinked package paths', t => {
  const directory = mkdtempSync(path.join('/private/tmp', 'crosswake checker path '));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const source = path.join(process.cwd(), 'priv/crosswake/verify_ios_host_settings.mjs');
  const copied = path.join(directory, 'ios settings checker.mjs');
  const dependencyPriv = path.join(directory, 'dependency priv checker.mjs');
  copyFileSync(source, copied);
  symlinkSync(source, dependencyPriv);

  for (const entrypoint of [copied, dependencyPriv]) {
    const result = spawnSync(process.execPath, [entrypoint, '--host-root', '/unused'], {
      input: '{}\n', encoding: 'utf8',
    });
    assert.equal(result.status, 1);
    assert.equal(JSON.parse(result.stdout).findings[0].field, 'expected_input');
    assert.doesNotMatch(result.stdout, /ABCDE12345|org\.crosswake/);
  }
});

test('missing expected declaration fails before invoking Xcode', () => {
  const result = verifyIosHostSettings({ hostRoot: '/missing', expectedSettings: null, xcodebuild: 'missing-xcodebuild' });
  assert.equal(result.ok, false);
  assert.equal(result.observedCells, 0);
  assert.equal(result.findings[0].field, 'expected_input');
});
