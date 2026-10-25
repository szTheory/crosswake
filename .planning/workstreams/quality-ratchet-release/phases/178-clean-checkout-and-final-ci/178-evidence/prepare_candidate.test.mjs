import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import {
  BASE_COMMIT,
  BASE_TREE,
  INITIAL_PATHS,
  REPAIR_PATHS,
  ALLOWED_PATHS,
  replayBundle,
  assertDerivedSnapshots,
  runTracerFixture,
  validateBundle,
  safeFailure,
  assertDeliveryPathSafe,
  assertCleanProof,
} from './prepare_candidate.mjs';

test('the real Git tracer applies tracked and byte-bearing untracked outputs and clones exact commit', () => {
  const result = runTracerFixture();
  assert.equal(result.commit, result.proofHead);
  assert.equal(result.tree, result.proofTree);
  assert.equal(result.proofStatus, 'clean');
  assert.deepEqual(result.paths, ['note.txt', 'new.bin']);
  assert.equal(result.newFileBytesMatch, true);
  assert.equal(result.gitResultShape.status, 0);
});

test('initial and renewed path selections retain six required files and add exactly two derived snapshots', () => {
  assert.deepEqual(INITIAL_PATHS, [
    'README.md',
    'docs/COMPANION-PUBLISH-RUNBOOK.md',
    'docs/RELEASE-INCIDENT-RESPONSE.md',
    'test/crosswake/guides/release_boundaries_test.exs',
    'test/crosswake/release_candidate/companion_receipt_test.exs',
    'test/crosswake/release_candidate/evidence_gate_test.exs',
  ]);
  assert.deepEqual(REPAIR_PATHS, [
    'script/collection_assertion_ledger.json',
    'script/collection_assertion_remediation.json',
    'test/crosswake/guides/release_boundaries_test.exs',
  ]);
  assert.equal(ALLOWED_PATHS.length, 8);
  assert.equal(new Set(ALLOWED_PATHS).size, 8);
});

test('public projection contains only allowlisted source identity and omits private roots and digests', () => {
  const publicFile = new URL('./candidate-source.json', import.meta.url);
  const projection = JSON.parse(fs.readFileSync(publicFile, 'utf8'));
  assert.deepEqual(Object.keys(projection).sort(), [
    'schemaVersion', 'phase', 'plan', 'status', 'sourceBaseCommit', 'sourceBaseTree',
    'candidateCommit', 'candidateTree', 'selectedPaths', 'selectedCount', 'proofClone',
    'canonicalMainMatchesBase', 'retainedRows', 'historicalReaderComparisons', 'requirements',
  ].sort());
  assert.equal(JSON.stringify(projection).includes('private'), false);
  assert.equal(JSON.stringify(projection).includes('Sha256'), false);
  assert.equal(JSON.stringify(projection).includes('/private/tmp/'), false);
  assert.equal(JSON.stringify(projection).includes('private-sentinel'), false);
});

test('wrong base, altered patch, omitted path, extra path and escaping symlink fail closed', () => {
  const patch = Buffer.from('diff --git a/README.md b/README.md\n');
  const valid = { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, patchBase64: patch.toString('base64'), patchBytes: patch.length, patchDigest: createHash('sha256').update(patch).digest('hex'), untrackedFiles: 0, untracked: [] };
  const expected = { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: ['README.md'] };
  assert.equal(validateBundle(valid, expected).ok, true);
  assert.equal(validateBundle(valid, { ...expected, baseCommit: 'c'.repeat(40) }).cause, 'wrong-base');
  const altered = Buffer.from(patch); altered[0] ^= 1;
  const tamperedResult = validateBundle({ ...valid, patchBase64: altered.toString('base64') }, expected);
  assert.equal(tamperedResult.cause, 'invalid-bundle');
  assert.equal(JSON.stringify(tamperedResult).includes('private-sentinel'), false);
  assert.equal(validateBundle(valid, { ...expected, paths: ['README.md', 'extra.txt'] }).cause, 'path-set-mismatch');
  assert.equal(validateBundle(valid, { ...expected, paths: [] }).cause, 'path-set-mismatch');
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-symlink-'));
  try {
    const repo = path.join(root, 'repo'); fs.mkdirSync(repo);
    const outside = path.join(root, 'outside'); fs.mkdirSync(outside);
    fs.symlinkSync(outside, path.join(repo, 'escape'));
    assert.throws(() => assertDeliveryPathSafe(repo, 'escape/payload.bin'), error => error.safeCause === 'symlink-escape');
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('real Git rejects tampered patch and path traversal controls with normal subprocess result fields', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-controls-'));
  try {
    const repo = path.join(root, 'repo'); fs.mkdirSync(repo);
    const call = args => spawnSync('git', ['-C', repo, ...args], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' } });
    assert.equal(call(['init', '-q']).status, 0);
    fs.writeFileSync(path.join(repo, 'base.txt'), 'base\n'); assert.equal(call(['add', 'base.txt']).status, 0); assert.equal(call(['commit', '-qm', 'base']).status, 0);
    fs.writeFileSync(path.join(repo, 'base.txt'), 'changed\n');
    const originalPatch = call(['diff', '--binary']).stdout;
    const applyRepo = path.join(root, 'apply-repo');
    const cloneResult = spawnSync('git', ['clone', '--no-local', repo, applyRepo], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
    assert.equal(cloneResult.status, 0);
    const tamperedPatch = Buffer.from('@@ malformed but valid base64 @@\n');
    const tampered = spawnSync('git', ['-C', applyRepo, 'apply', '--binary', '--'], { input: tamperedPatch, encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
    assert.notEqual(tampered.status, 0);
    assert.equal(tampered.signal, null);
    const traversal = Buffer.from('diff --git a/../escape b/../escape\nnew file mode 100644\nindex 0000000..e69de29\n');
    const rejected = spawnSync('git', ['-C', repo, 'apply', '--binary', '--'], { input: traversal, encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
    assert.notEqual(rejected.status, 0);
    assert.equal(rejected.signal, null);
    assert.equal(JSON.stringify({ status: rejected.status, cause: safeFailure('path-set-mismatch').cause }).includes('private-sentinel'), false);
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('CLI failure output keeps private path sentinels out of stdout and stderr', () => {
  const script = new URL('./prepare_candidate.mjs', import.meta.url);
  const sentinel = '/private/tmp/private-sentinel-do-not-print';
  const result = spawnSync(process.execPath, [script.pathname, '--prepare'], {
    encoding: 'utf8', env: { ...process.env, CROSSWAKE_178_PRIVATE_HANDOFF_ROOT: sentinel, CROSSWAKE_178_DELIVERY_ROOT: '', CROSSWAKE_178_PROOF_ROOT: '' },
  });
  assert.notEqual(result.status, 0);
  assert.equal(`${result.stdout}${result.stderr}`.includes(sentinel), false);
  assert.match(result.stderr, /missing-environment/);
});

test('validator subprocess rejects wrong base, tampered bytes and path-set drift without leaking sentinels', () => {
  const moduleUrl = new URL('./prepare_candidate.mjs', import.meta.url).href;
  const source = `import {validateBundle} from ${JSON.stringify(moduleUrl)};import{createHash}from'node:crypto';const p=Buffer.from('diff --git a/README.md b/README.md\\n');const d=createHash('sha256').update(p).digest('hex');const b={baseCommit:${JSON.stringify(BASE_COMMIT)},baseTree:${JSON.stringify(BASE_TREE)},patchBase64:p.toString('base64'),patchBytes:p.length,patchDigest:d,untrackedFiles:0,untracked:[]};const expected={baseCommit:${JSON.stringify(BASE_COMMIT)},baseTree:${JSON.stringify(BASE_TREE)},paths:['README.md']};const bad=Buffer.from(p);bad[0]^=1;const outputs=[validateBundle({...b,baseCommit:'private-sentinel'},expected).cause,validateBundle({...b,patchBase64:bad.toString('base64')},expected).cause,validateBundle(b,{...expected,paths:['README.md','extra']}).cause];process.stdout.write(JSON.stringify(outputs));`;
  const result = spawnSync(process.execPath, ['--input-type=module', '-e', source], { encoding: 'utf8', env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  assert.equal(result.status, 0);
  assert.deepEqual(JSON.parse(result.stdout), ['wrong-base', 'invalid-bundle', 'path-set-mismatch']);
  assert.equal(`${result.stdout}${result.stderr}`.includes('private-sentinel'), false);
});

test('wrong-head clean and dirty proof clones are rejected by the check helper', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-dirty-'));
  try {
    const repo = path.join(root, 'repo'); fs.mkdirSync(repo);
    const git = (...args) => {
      const r = spawnSync('git', ['-C', repo, ...args], { encoding: 'utf8', env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
      assert.equal(r.status, 0, 'fixture Git setup failed');
      return r.stdout.trim();
    };
    git('init', '-q'); git('config', 'user.name', 'Fixture'); git('config', 'user.email', 'fixture@example.invalid');
    fs.writeFileSync(path.join(repo, 'base.txt'), 'base\n'); git('add', 'base.txt'); git('commit', '-qm', 'base');
    const expectedCommit = git('rev-parse', 'HEAD'); const expectedTree = git('rev-parse', 'HEAD^{tree}');
    fs.writeFileSync(path.join(repo, 'base.txt'), 'later\n'); git('add', 'base.txt'); git('commit', '-qm', 'later');
    assert.equal(git('status', '--porcelain'), '');
    assert.throws(() => assertCleanProof(repo, expectedCommit, expectedTree), error => error.safeCause === 'dirty-proof');
    fs.writeFileSync(path.join(repo, 'dirty.txt'), 'dirty\n');
    assert.throws(() => assertCleanProof(repo, git('rev-parse', 'HEAD'), git('rev-parse', 'HEAD^{tree}')), error => error.safeCause === 'dirty-proof');
    assert.equal(safeFailure('dirty-proof').cause, 'dirty-proof');
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('clean proof validation never writes the raw index even when its TREE cache is absent', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-readonly-index-'));
  try {
    const repo = path.join(root, 'repo'); fs.mkdirSync(repo);
    const git = (...args) => {
      const r = spawnSync('git', ['-C', repo, ...args], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
      assert.equal(r.status, 0, `fixture Git setup failed: ${args[0]}`); return Buffer.from(r.stdout || []);
    };
    git('init', '-q'); git('config', 'user.name', 'Fixture'); git('config', 'user.email', 'fixture@example.invalid');
    fs.writeFileSync(path.join(repo, 'tracked.txt'), 'base\n'); git('add', 'tracked.txt'); git('commit', '-qm', 'base');
    const commit = git('rev-parse', 'HEAD').toString().trim(); const tree = git('rev-parse', 'HEAD^{tree}').toString().trim();
    const indexPath = path.join(repo, '.git', 'index'); const raw = fs.readFileSync(indexPath);
    assert.equal(raw.toString('ascii', 0, 4), 'DIRC');
    assert.equal(raw.readUInt32BE(4), 2, 'fixture expects a v2 index');
    const entryCount = raw.readUInt32BE(8); let offset = 12;
    for (let i = 0; i < entryCount; i += 1) {
      const start = offset; const flags = raw.readUInt16BE(offset + 60); offset += 62;
      if (flags & 0x4000) offset += 2;
      const nul = raw.indexOf(0, offset); assert.notEqual(nul, -1);
      offset = nul + 1; offset += (8 - ((offset - start) % 8)) % 8;
    }
    const extensions = []; const extensionEnd = raw.length - 20; let cursor = offset;
    while (cursor + 8 <= extensionEnd) {
      const signature = raw.toString('ascii', cursor, cursor + 4); const length = raw.readUInt32BE(cursor + 4);
      assert.ok(cursor + 8 + length <= extensionEnd);
      extensions.push({ signature, bytes: raw.subarray(cursor, cursor + 8 + length) }); cursor += 8 + length;
    }
    const withoutTree = Buffer.concat([raw.subarray(0, offset), ...extensions.filter(item => item.signature !== 'TREE').map(item => item.bytes)]);
    assert.ok(extensions.some(item => item.signature === 'TREE'), 'fixture should begin with a cache-tree extension');
    const digest = createHash('sha1').update(withoutTree).digest();
    const noTreeIndex = Buffer.concat([withoutTree, digest]); fs.writeFileSync(indexPath, noTreeIndex);
    assert.equal(git('status', '--porcelain=v1', '-z', '--untracked-files=all').length, 0);
    const before = fs.readFileSync(indexPath);
    assert.equal(assertCleanProof(repo, commit, tree), true);
    assert.deepEqual(fs.readFileSync(indexPath), before, 'read-only proof check must preserve every index byte');
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

function fixtureSnapshots(root, { lineShift = 0, bucketMutation = false, membershipMutation = false, frozenMutation = false } = {}) {
  const scriptDir = path.join(root, 'script'); fs.mkdirSync(scriptDir, { recursive: true });
  const buckets = ['safe-by-construction', 'safe-guarded', 'safe-cardinality-pinned', 'safe-compile-time-literal'];
  const counts = [134, 60, 32, 4]; let rows = [];
  for (let i = 0; i < 230; i++) {
    const bucket = buckets[counts.findIndex((_, j) => i < counts.slice(0, j + 1).reduce((a, b) => a + b, 0))];
    rows.push({ key: `ledger-${String(i).padStart(3, '0')}`, shape: 'assertion', bucket: bucketMutation && i === 0 ? 'safe-guarded' : bucket, rationale: `guard at line ${100 + i + lineShift}`, display: `test/file.ex:${100 + i + lineShift}`, enclosing: `case at line ${100 + i + lineShift}`, expression: `assertion-${i}` });
  }
  if (membershipMutation) rows.pop();
  const ledger = { scope: 'script/**/*.ex', generator: 'inventory', sunset: 'never', rows };
  const remediationRows = Array.from({ length: 52 }, (_, i) => ({ key: `frozen-${String(i).padStart(2, '0')}`, shape: 'assertion', display: `test/frozen.ex:${500 + i + lineShift}`, enclosing: `guard at line ${500 + i + lineShift}`, expression: `frozen-${i}` }));
  if (frozenMutation) remediationRows[0].expression = 'changed-frozen-expression';
  const remediation = { frozen_at: 'immutable', generator: 'inventory', note: 'frozen membership', rows: remediationRows };
  fs.writeFileSync(path.join(scriptDir, 'collection_assertion_ledger.json'), JSON.stringify(ledger));
  fs.writeFileSync(path.join(scriptDir, 'collection_assertion_remediation.json'), JSON.stringify(remediation));
}

test('derived snapshots permit only line-reference movement with frozen row membership and invariants', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-derived-'));
  try {
    const before = path.join(root, 'before'); const after = path.join(root, 'after'); fs.mkdirSync(before); fs.mkdirSync(after);
    fixtureSnapshots(before); fixtureSnapshots(after, { lineShift: 9 });
    assert.deepEqual(assertDerivedSnapshots(before, after).bucketCounts, {
      'safe-by-construction': 134, 'safe-cardinality-pinned': 32,
      'safe-compile-time-literal': 4, 'safe-guarded': 60,
    });
    for (const option of [{ bucketMutation: true }, { membershipMutation: true }, { frozenMutation: true }]) {
      const bad = path.join(root, `bad-${Object.keys(option)[0]}`); fs.mkdirSync(bad); fixtureSnapshots(bad, option);
      assert.throws(() => assertDerivedSnapshots(before, bad), error => error.safeCause === 'derived-snapshot-drift');
    }
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});

test('real Git replays an initial actual-shape bundle and a three-path repair bundle cumulatively', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-renewal-fixture-'));
  try {
    const source = path.join(root, 'source'); fs.mkdirSync(source);
    const git = repo => (...args) => {
      const r = spawnSync('git', ['-C', repo, ...args], { encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' } });
      assert.equal(r.status, 0, `Git fixture command failed: ${args[0]}`); return Buffer.from(r.stdout || []);
    };
    const run = git(source); run('init', '-q'); run('config', 'user.name', 'Fixture'); run('config', 'user.email', 'fixture@example.invalid');
    const initialPaths = INITIAL_PATHS; const repairPaths = REPAIR_PATHS;
    for (const rel of [...initialPaths, ...repairPaths]) { const file = path.join(source, rel); fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, 'base\n'); }
    run('add', '--', ...[...initialPaths, ...repairPaths]); run('commit', '-qm', 'base');
    const baseCommit = run('rev-parse', 'HEAD').toString().trim(); const baseTree = run('rev-parse', 'HEAD^{tree}').toString().trim();
    for (const rel of initialPaths) fs.writeFileSync(path.join(source, rel), 'initial\n');
    const firstPatch = run('diff', '--binary');
    const originalBundle = { baseCommit, baseTree, patchBase64: firstPatch.toString('base64'), patchBytes: firstPatch.length, patchDigest: createHash('sha256').update(firstPatch).digest('hex'), untrackedFiles: 0, untracked: [] };
    run('add', '--', ...initialPaths); run('commit', '-qm', 'old candidate');
    const oldCommit = run('rev-parse', 'HEAD').toString().trim(); const oldTree = run('rev-parse', 'HEAD^{tree}').toString().trim();
    for (const rel of repairPaths) fs.writeFileSync(path.join(source, rel), 'repaired\n');
    const secondPatch = run('diff', '--binary');
    const repairBundle = { baseCommit: oldCommit, baseTree: oldTree, patchBase64: secondPatch.toString('base64'), patchBytes: secondPatch.length, patchDigest: createHash('sha256').update(secondPatch).digest('hex'), untrackedFiles: 0, untracked: [] };
    run('add', '--', ...repairPaths); run('commit', '-qm', 'source repair');
    const finalTree = run('rev-parse', 'HEAD^{tree}').toString().trim();
    const replay = path.join(root, 'replay'); const cloneResult = spawnSync('git', ['clone', '--no-local', source, replay], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } }); assert.equal(cloneResult.status, 0);
    // Move replay to the canonical fixture base and apply both production bundles through the shared validator.
    const gitReplay = git(replay); gitReplay('checkout', '--detach', baseCommit);
    replayBundle(replay, originalBundle, { baseCommit, baseTree, paths: initialPaths });
    for (const rel of initialPaths) gitReplay('add', '--', rel);
    assert.equal(gitReplay('write-tree').toString().trim(), oldTree);
    replayBundle(replay, repairBundle, { baseCommit: oldCommit, baseTree: oldTree, paths: repairPaths }, { statusPaths: [...new Set([...initialPaths, ...repairPaths])] });
    for (const rel of [...initialPaths, ...repairPaths]) gitReplay('add', '--', rel);
    assert.equal(gitReplay('write-tree').toString().trim(), finalTree);
    assert.deepEqual([...new Set([...initialPaths, ...repairPaths])].sort(), ALLOWED_PATHS);
    gitReplay('commit', '-qm', 'renewed fixture');
    assert.equal(gitReplay('status', '--porcelain=v1').toString().trim(), '');
  } finally { fs.rmSync(root, { recursive: true, force: true }); }
});
