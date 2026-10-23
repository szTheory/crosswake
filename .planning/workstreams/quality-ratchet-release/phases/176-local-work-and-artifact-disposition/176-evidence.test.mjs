import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { pathToFileURL, fileURLToPath } from 'node:url';

const helperPath = path.join(path.dirname(fileURLToPath(import.meta.url)), '176-evidence.mjs');
const loadHelper = async () => import(pathToFileURL(helperPath));

function git(cwd, ...args) {
  const result = spawnSync('git', args, { cwd, encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`git fixture command failed (${args[0]})`);
  return result.stdout;
}
function gitResult(cwd, ...args) { return spawnSync('git', args, { cwd, encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } }); }
function resealPrivateManifest(archive, captureId, manifest) {
  const file = path.join(archive, captureId, 'manifest.json');
  fs.chmodSync(file, 0o600); fs.writeFileSync(file, JSON.stringify(manifest, null, 2) + '\n'); fs.chmodSync(file, 0o400);
  const attest = path.join(archive, '.attestations', `${captureId}.sha256`);
  fs.chmodSync(attest, 0o600); fs.writeFileSync(attest, createHash('sha256').update(fs.readFileSync(file)).digest('hex') + '\n'); fs.chmodSync(attest, 0o400);
}

function fixture(t) {
  const root = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), 'crosswake-176-'));
  const repo = path.join(root, 'repo');
  const archive = path.join(root, 'archive');
  fs.mkdirSync(repo);
  fs.mkdirSync(archive, { mode: 0o700 });
  git(repo, 'init', '-q');
  git(repo, 'config', 'user.email', 'fixture@example.invalid');
  git(repo, 'config', 'user.name', 'Fixture');
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'base\n');
  git(repo, 'add', 'tracked.txt');
  git(repo, 'commit', '-qm', 'fixture baseline');
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  return { root, repo, archive };
}
function phaseArtifacts(repo) {
  const relative = '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/';
  const dir = path.join(repo, relative); fs.mkdirSync(dir, { recursive: true });
  return { dir, publicPath: path.join(dir, '176-INVENTORY.json'), renderedPath: path.join(dir, '176-INVENTORY.md'), publicRelative: `${relative}176-INVENTORY.json` };
}

test('tracer capture restore: staged and edited bytes restore independently with a safe disposition', async (t) => {
  const { repo, archive } = fixture(t);
  const file = path.join(repo, 'tracked.txt');
  fs.writeFileSync(file, 'staged private sentinel\n');
  git(repo, 'add', 'tracked.txt');
  fs.writeFileSync(file, 'worktree private sentinel\n');
  const { capture, verify, render } = await loadHelper();
  const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.equal(captured.rows.length, 1);
  assert.equal(captured.rows[0].disposition, 'retain');
  const verified = verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  assert.equal(verified.ok, true);
  assert.equal(verified.restoredUnits, 2);
  const publicText = render(captured);
  assert.doesNotMatch(publicText, /private sentinel|archive/);
  assert.match(publicText, /retain/);
});

test('the fixture drives the same capture and verify CLI as live work, with temporary storage explicitly gated', (t) => {
  const { repo, archive, root } = fixture(t); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'cli staged'); git(repo, 'add', 'tracked.txt'); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'cli worktree');
  const publicDir = path.join(repo, '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition'); fs.mkdirSync(publicDir, { recursive: true });
  const publicPath = path.join(publicDir, '176-INVENTORY.json'); const publicRelative = '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json';
  const command = (subcommand, ...args) => spawnSync(process.execPath, [helperPath, subcommand, '--repo', repo, '--archive-root', archive, ...args], { cwd: process.cwd(), encoding: 'utf8', env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  const blocked = command('capture', '--public', publicRelative);
  assert.equal(blocked.status, 1);
  assert.match(blocked.stderr, /temporary storage/);
  const captured = command('capture', '--public', publicRelative, '--fixture-temp', 'true');
  assert.equal(captured.status, 0, captured.stderr);
  const inventory = JSON.parse(fs.readFileSync(publicPath, 'utf8'));
  const verified = command('verify', '--public', publicRelative, '--fixture-temp', 'true');
  assert.equal(verified.status, 0, verified.stderr);
  assert.equal(JSON.parse(verified.stdout).captureId, inventory.captureId);
  const rendered = command('render', '--public', publicRelative, '--output', '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md');
  assert.equal(rendered.status, 0, rendered.stderr);
  const audited = command('audit', '--public', publicRelative, '--rendered', '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md', '--fixture-temp', 'true');
  assert.equal(audited.status, 0, audited.stderr);
});

test('equal index and worktree bytes remain separate recoverable partitions', async (t) => {
  const { repo, archive } = fixture(t); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'same bytes'); git(repo, 'add', 'tracked.txt');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.equal(captured.rows.length, 1);
  const restored = verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  assert.equal(restored.restoredUnits, 2);
});

test('source provenance fetches advertised refs only into scratch and validates a real per-path merged candidate', async (t) => {
  const { repo, archive, root } = fixture(t); const base = git(repo, 'rev-parse', 'HEAD').toString('ascii').trim(); const bare = path.join(root, 'origin.git');
  git(root, 'init', '--bare', '--initial-branch=main', '-q', bare); git(repo, 'remote', 'add', 'origin', bare);
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'candidate exact bytes'); git(repo, 'add', 'tracked.txt'); git(repo, 'commit', '-qm', 'published candidate');
  const candidate = git(repo, 'rev-parse', 'HEAD').toString('ascii').trim(); git(repo, 'push', '-q', 'origin', 'HEAD:refs/heads/main');
  git(repo, 'checkout', '-q', '--detach', base); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'candidate exact bytes'); git(repo, 'add', 'tracked.txt');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const result = verify({ repo, archiveRoot: archive, captureId: captured.captureId, _sourceCandidatesForTest: [candidate] });
  assert.equal(result.sourceProvenanceVerified, true, JSON.stringify(result));
  const tree = git(repo, 'rev-parse', `${candidate}^{tree}`).toString('ascii').trim();
  const publicRelative = '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json';
  const publicPath = path.join(repo, publicRelative); fs.mkdirSync(path.dirname(publicPath), { recursive: true });
  const archiveProofPath = path.join(archive, captured.captureId, 'verified-proof.json'); const archiveProof = JSON.parse(fs.readFileSync(archiveProofPath, 'utf8'));
  const frozenComparison = archiveProof.provenance.comparisons[captured.rows[0].rowId];
  const publicRow = { ...captured.rows[0], disposition: 'already merged', comparison: { ...frozenComparison, commit: candidate, tree }, reason: 'Both captured index and worktree bytes exactly match the verified source candidate.' };
  fs.writeFileSync(publicPath, JSON.stringify({ ...captured, rows: [publicRow] }));
  assert.equal(verify({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, _sourceCandidatesForTest: [candidate] }).ok, true);
  const updatedProof = JSON.parse(fs.readFileSync(path.join(archive, captured.captureId, 'verified-proof.json'), 'utf8'));
  assert.equal(updatedProof.provenance.defaultTip.commit, candidate);
  assert.deepEqual(updatedProof.provenance.comparisons[captured.rows[0].rowId].candidates[0], { commit: candidate, tree, headEqual: false, indexEqual: true, worktreeEqual: true, semanticEquivalenceReviewed: false });
});

test('intent-to-add entries keep the empty index version separate from worktree bytes', async (t) => {
  const { repo, archive } = fixture(t); fs.writeFileSync(path.join(repo, 'intent.txt'), 'worktree-only bytes'); git(repo, 'add', '-N', 'intent.txt');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.ok(captured.rows.some((r) => r.path === 'intent.txt'));
  assert.equal(verify({ repo, archiveRoot: archive, captureId: captured.captureId }).ok, true);
});

test('empty Git state is an explicit zero-row capture and malformed records fail closed', async (t) => {
  const { repo, archive } = fixture(t); const { capture, verify, parseStatusRecords, parseIndexRecords } = await loadHelper();
  const empty = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.deepEqual(empty.rows, []);
  assert.equal(verify({ repo, archiveRoot: archive, captureId: empty.captureId }).restoredUnits, 0);
  assert.throws(() => parseStatusRecords(null), /Buffer/);
  assert.throws(() => parseStatusRecords(Buffer.from('M \0', 'binary')), /malformed/);
  assert.throws(() => parseIndexRecords(Buffer.from('100644 broken\0', 'binary')), /malformed/);
  const invalidUtf8 = parseStatusRecords(Buffer.from([0x3f, 0x3f, 0x20, 0xff, 0x00]));
  assert.deepEqual(invalidUtf8[0].path, Buffer.from([0xff]));
});

test('unsupported filesystem rows remain explicit limitations and are not counted as restored', async (t) => {
  const { repo, archive } = fixture(t); const fifo = path.join(repo, 'tracked.txt'); fs.unlinkSync(fifo);
  const made = spawnSync('mkfifo', [fifo]); assert.equal(made.status, 0, made.stderr?.toString());
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const row = captured.rows.find((entry) => entry.path === 'tracked.txt'); assert.ok(row);
  const restored = verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  assert.equal(restored.restoredUnits, 0);
  assert.match(restored.limitations.find((item) => item.rowId === row.rowId).reason, /filesystem type/);
});

test('restore rejects file-parent collisions and symlinked ancestors before writing restored payloads', async (t) => {
  const { repo, archive, root } = fixture(t); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'captured');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const manifestPath = path.join(archive, captured.captureId, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  manifest.rows.push({ rowId: (await import('node:crypto')).randomBytes(16).toString('hex'), pathBytes: Buffer.from('tracked.txt/child').toString('base64'), xy: '??', roles: [], index: [], worktree: { kind: 'absent' } });
  resealPrivateManifest(archive, captured.captureId, manifest);
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: captured.captureId }), /colliding file and parent paths/);

  const outside = path.join(root, 'outside'); fs.mkdirSync(outside); fs.symlinkSync(outside, path.join(repo, 'linked'));
  const another = capture({ repo, archiveRoot: archive, allowTemporary: true }); const linkedManifestPath = path.join(archive, another.captureId, 'manifest.json');
  const linkedManifest = JSON.parse(fs.readFileSync(linkedManifestPath, 'utf8'));
  const linkRow = linkedManifest.rows.find((entry) => entry.pathBytes === Buffer.from('linked').toString('base64'));
  linkRow.pathBytes = Buffer.from('linked/child').toString('base64'); linkRow.worktree = { kind: 'file', mode: 0o600, data: Buffer.from('must-not-escape').toString('base64') };
  resealPrivateManifest(archive, another.captureId, linkedManifest);
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: another.captureId }), /symlink or non-directory parent/);
  assert.equal(fs.existsSync(path.join(outside, 'child')), false);
});

test('anchored no-follow reader fails closed when a real parent directory is swapped for an outside symlink', async (t) => {
  const { repo, root } = fixture(t); const parent = path.join(repo, 'swap'); const old = path.join(repo, 'swap-original'); const outside = path.join(root, 'outside');
  fs.mkdirSync(parent); fs.mkdirSync(outside); fs.writeFileSync(path.join(parent, 'payload'), 'inside-safe-bytes'); fs.writeFileSync(path.join(outside, 'payload'), 'outside-secret-sentinel');
  const marker = path.join(root, 'reader-ready'); const go = path.join(root, 'continue');
  const source = `import { readSourceForTest } from ${JSON.stringify(pathToFileURL(helperPath).href)}; const value=readSourceForTest(process.argv[1],'swap/payload',{marker:process.argv[2],continueFile:process.argv[3]}); process.stdout.write(value.bytes.toString());`;
  const child = spawn(process.execPath, ['--input-type=module', '-e', source, repo, marker, go], { stdio: ['ignore', 'pipe', 'pipe'] });
  let stdout = ''; let stderr = ''; child.stdout.setEncoding('utf8').on('data', (x) => { stdout += x; }); child.stderr.setEncoding('utf8').on('data', (x) => { stderr += x; });
  for (let i = 0; i < 500 && !fs.existsSync(marker); i++) await new Promise((resolve) => setTimeout(resolve, 5));
  assert.equal(fs.existsSync(marker), true, `anchored reader did not reach parent-open barrier: ${stderr}`);
  fs.renameSync(parent, old); fs.symlinkSync(outside, parent); fs.writeFileSync(go, 'go');
  const exit = await new Promise((resolve) => child.on('close', resolve));
  assert.notEqual(exit, 0, 'parent swap must fail closed rather than return data from either new path');
  assert.doesNotMatch(stdout + stderr, /outside-secret-sentinel/);
  assert.equal(fs.readFileSync(path.join(outside, 'payload'), 'utf8'), 'outside-secret-sentinel');
  fs.unlinkSync(parent); fs.renameSync(old, parent);
});

test('rename, deletion, binary data, unusual names, and invalid UTF-8 paths retain byte identity', async (t) => {
  const { repo, archive } = fixture(t);
  fs.renameSync(path.join(repo, 'tracked.txt'), path.join(repo, 'renamed.txt'));
  git(repo, 'add', '-A');
  fs.writeFileSync(path.join(repo, 'binary.bin'), Buffer.from([0, 1, 0xff, 0x0a]));
  fs.writeFileSync(path.join(repo, 'line\nbreak'), 'newline');
  fs.writeFileSync(path.join(repo, ' leading-space'), 'space');
  fs.writeFileSync(path.join(repo, '-leading-dash'), 'dash');
  const invalidPath = Buffer.concat([Buffer.from(repo + path.sep), Buffer.from([0x62, 0x61, 0x64, 0x80])]);
  try { fs.writeFileSync(invalidPath, 'opaque'); } catch (e) { t.diagnostic(`invalid UTF-8 path unsupported: ${e.code}`); }
  const { capture, verify } = await loadHelper();
  const got = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.ok(got.rows.length >= 6);
  assert.ok(got.rows.some((r) => r.path === 'tracked.txt' || r.path === 'renamed.txt'));
  assert.ok(got.rows.some((r) => r.path === null), 'unsafe byte names use opaque row IDs');
  const renderedPaths = got.rows.filter((r) => r.path !== null).map((r) => r.path);
  assert.deepEqual(renderedPaths, [...renderedPaths].sort((a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b))));
  const verified = verify({ repo, archiveRoot: archive, captureId: got.captureId });
  assert.equal(verified.ok, true);
  assert.ok(verified.restoredUnits >= got.rows.length);
});

test('staged mode, binary, symlink replacement, and unmerged index stages are preserved or explicitly limited', async (t) => {
  const { repo, archive } = fixture(t);
  fs.writeFileSync(path.join(repo, 'tracked.txt'), Buffer.from([0, 0xff, 0x42]));
  fs.chmodSync(path.join(repo, 'tracked.txt'), 0o755);
  git(repo, 'add', 'tracked.txt');
  fs.unlinkSync(path.join(repo, 'tracked.txt')); fs.symlinkSync('target-secret', path.join(repo, 'tracked.txt'));
  const { capture, verify } = await loadHelper();
  const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const row = captured.rows.find((r) => r.path === 'tracked.txt');
  assert.equal(row.status.includes('T') || row.status.includes('M'), true);
  assert.equal(verify({ repo, archiveRoot: archive, captureId: captured.captureId }).ok, true);
  assert.doesNotMatch(JSON.stringify(captured), /target-secret|0xff|archiveRoot/);

  git(repo, 'restore', '--staged', '--worktree', '--', 'tracked.txt');
  const defaultBranch = git(repo, 'branch', '--show-current').toString('utf8').trim();
  const side = gitResult(repo, 'checkout', '-qb', 'side'); assert.equal(side.status, 0);
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'side'); git(repo, 'add', 'tracked.txt'); git(repo, 'commit', '-qm', 'side');
  git(repo, 'checkout', '-q', defaultBranch);
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'main'); git(repo, 'add', 'tracked.txt'); git(repo, 'commit', '-qm', 'main');
  const merge = gitResult(repo, 'merge', 'side'); assert.notEqual(merge.status, 0);
  const conflicted = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.ok(conflicted.rows.some((r) => r.status.includes('U')));
  assert.equal(verify({ repo, archiveRoot: archive, captureId: conflicted.captureId }).ok, true);
});

test('capture is exclusive, verification rejects a changed baseline, and unsupported temporary archive is denied', async (t) => {
  const { repo, archive } = fixture(t); const { capture, verify } = await loadHelper();
  assert.throws(() => capture({ repo, archiveRoot: path.join(os.tmpdir(), 'durable-is-not-tmp') }), /temporary storage/);
  const lock = path.join(archive, '.capture.lock'); fs.writeFileSync(lock, '');
  assert.throws(() => capture({ repo, archiveRoot: archive, allowTemporary: true }), /busy/);
  fs.unlinkSync(lock);
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'first dirty bytes');
  const sameState = capture({ repo, archiveRoot: archive, allowTemporary: true });
  fs.writeFileSync(path.join(repo, 'tracked.txt'), 'second dirty bytes');
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: sameState.captureId }), /bytes, kind, or mode changed/);
  git(repo, 'restore', '--worktree', '--', 'tracked.txt');
  const saved = capture({ repo, archiveRoot: archive, allowTemporary: true });
  fs.writeFileSync(path.join(repo, 'later.txt'), 'changed');
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: saved.captureId }), /baseline changed/);
});

test('same-status worktree mutation between freeze and publish leaves only an unverified partial attempt', async (t) => {
  const { repo, archive } = fixture(t); const file = path.join(repo, 'tracked.txt'); fs.writeFileSync(file, 'first same-status bytes');
  const before = git(repo, 'status', '--porcelain=v1', '-z', '--untracked-files=all');
  const { capture } = await loadHelper();
  assert.throws(() => capture({ repo, archiveRoot: archive, allowTemporary: true, _afterSnapshotForTest: () => fs.writeFileSync(file, 'other same-status bytes') }), /worktree bytes, kind, or mode changed during capture/);
  const after = git(repo, 'status', '--porcelain=v1', '-z', '--untracked-files=all');
  assert.deepEqual(after, before, 'the race fixture retains the same status class and path');
  const names = fs.readdirSync(archive);
  assert.equal(names.some((name) => name.startsWith('.partial-')), true);
  assert.equal(names.some((name) => /^\d{8}T\d{6}-[a-f0-9]{16}$/.test(name)), false);
});

test('durable archive roots reject exposed, symlinked, temporary, shared, and nested-checkout locations without chmod', async (t) => {
  const { repo, root } = fixture(t); const { capture, verify } = await loadHelper();
  const exposed = path.join(root, 'exposed'); fs.mkdirSync(exposed, { mode: 0o755 }); fs.chmodSync(exposed, 0o755);
  assert.throws(() => capture({ repo, archiveRoot: exposed, allowTemporary: true }), /permissions expose/);
  assert.equal(fs.statSync(exposed).mode & 0o777, 0o755, 'untrusted root permissions are never repaired in place');
  const linkParent = path.join(root, 'linked-parent'); fs.symlinkSync(root, linkParent);
  assert.throws(() => capture({ repo, archiveRoot: path.join(linkParent, 'archive'), allowTemporary: true }), /symlink/);
  assert.throws(() => capture({ repo, archiveRoot: path.join(fs.realpathSync(os.tmpdir()), 'crosswake-176-live-denied') }), /temporary storage/);
  assert.throws(() => capture({ repo, archiveRoot: '/tmp/crosswake-176-live-denied' }), /temporary storage/);
  assert.throws(() => capture({ repo, archiveRoot: '/private/tmp/crosswake-176-live-denied' }), /temporary storage/);
  assert.throws(() => capture({ repo, archiveRoot: path.join(root, 'Google Drive', 'archive') }), /temporary storage|synchronized/);

  const other = path.join(root, 'other-checkout'); fs.mkdirSync(other); git(other, 'init', '-q'); git(other, 'config', 'user.name', 'Fixture'); git(other, 'config', 'user.email', 'fixture@example.invalid');
  fs.writeFileSync(path.join(other, 'base'), 'base'); git(other, 'add', 'base'); git(other, 'commit', '-qm', 'other base');
  const nested = path.join(other, 'private-archive'); fs.mkdirSync(nested, { mode: 0o700 });
  assert.throws(() => capture({ repo, archiveRoot: nested, allowTemporary: true }), /another Git checkout/);

  const safeRoot = path.join(root, 'private-root'); fs.mkdirSync(safeRoot, { mode: 0o700 });
  const captureResult = capture({ repo, archiveRoot: safeRoot, allowTemporary: true });
  const captureDir = path.join(safeRoot, captureResult.captureId); fs.chmodSync(captureDir, 0o755);
  assert.throws(() => verify({ repo, archiveRoot: safeRoot, captureId: captureResult.captureId }), /permissions expose/);
  assert.equal(fs.statSync(captureDir).mode & 0o777, 0o755, 'read verification refuses and does not repair an exposed capture directory');
});

test('an interrupted capture leaves only a private partial attempt and never a verified capture', async (t) => {
  const { repo, archive } = fixture(t);
  const brokenObject = 'a'.repeat(40);
  git(repo, 'update-index', '--add', '--cacheinfo', `100644,${brokenObject},missing.txt`);
  const { capture } = await loadHelper();
  assert.throws(() => capture({ repo, archiveRoot: archive, allowTemporary: true }), /git cat-file failed/);
  const names = fs.readdirSync(archive);
  assert.equal(names.some((name) => /^\d{8}T\d{6}-[a-f0-9]{16}$/.test(name)), false);
  assert.equal(names.some((name) => name.startsWith('.partial-')), true);
  assert.equal(names.includes('.capture.lock'), false);
});

test('private manifest rejects duplicate path identities before restore', async (t) => {
  const { repo, archive } = fixture(t); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'changed');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const manifestPath = path.join(archive, captured.captureId, 'manifest.json'); const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  manifest.rows.push(structuredClone(manifest.rows[0])); resealPrivateManifest(archive, captured.captureId, manifest);
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: captured.captureId }), /duplicate private path identity/);
});

test('private capture attestation detects manifest tampering before restore and audit reads', async (t) => {
  const { repo, archive } = fixture(t); fs.writeFileSync(path.join(repo, 'tracked.txt'), 'frozen bytes');
  const { capture, verify } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const file = path.join(archive, captured.captureId, 'manifest.json'); fs.chmodSync(file, 0o600); fs.appendFileSync(file, ' '); fs.chmodSync(file, 0o400);
  assert.throws(() => verify({ repo, archiveRoot: archive, captureId: captured.captureId }), /integrity check failed/);
});

test('final audit removes a provisional pass if same-status bytes race after sidecar publication', async (t) => {
  const { repo, archive, root } = fixture(t); const target = path.join(repo, 'tracked.txt'); fs.writeFileSync(target, 'first same-size');
  const { capture, verify, audit } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true }); verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  const { publicPath } = phaseArtifacts(repo); fs.writeFileSync(publicPath, JSON.stringify({ ...captured, writerLedger: [{ path: '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json', owner: 'phase evidence writer', allowedDelta: 'phase-evidence' }] }));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true, _afterSidecarForTest: () => fs.writeFileSync(target, 'other same-size') }), /bytes, kind, or mode changed/);
  assert.equal(fs.existsSync(path.join(archive, captured.captureId, 'final-audit.json')), false, 'failed final audit cannot leave a pass sidecar');
});

test('final audit freezes the entire index even when an owner writes the path', async (t) => {
  const { repo, archive, root } = fixture(t); const ws = path.join(repo, '.planning/workstreams/quality-ratchet-release'); fs.mkdirSync(ws, { recursive: true });
  const statePath = path.join(ws, 'STATE.md'); fs.writeFileSync(statePath, '# State\n\n## Exact Next Action\n\n`$gsd-execute-phase 176 --ws quality-ratchet-release`\n\nExecute Plan 01, then Plan 02.\n\nHistorical bytes stay.\n');
  git(repo, 'add', '.'); git(repo, 'commit', '-qm', 'writer baseline');
  const { capture, verify, audit } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true }); verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  const { publicPath, publicRelative } = phaseArtifacts(repo); const publicData = { ...captured, writerLedger: [{ path: '.planning/workstreams/quality-ratchet-release/STATE.md', owner: 'GSD state', allowedDelta: 'state-handoff' }, { path: publicRelative, owner: 'phase evidence writer', allowedDelta: 'phase-evidence' }] }; fs.writeFileSync(publicPath, JSON.stringify(publicData));
  fs.writeFileSync(statePath, fs.readFileSync(statePath, 'utf8').replace('Execute Plan 01, then Plan 02.', 'Phase 176 complete; begin Phase 177.')); git(repo, 'add', statePath);
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /complete Git index changed/);
});

test('secret-bearing paths are opaque and their payload bytes never enter the private capture', async (t) => {
  const { repo, archive } = fixture(t); const secret = 'known-secret-sentinel-do-not-copy';
  fs.writeFileSync(path.join(repo, 'credentials.pem'), secret);
  const { capture, verify } = await loadHelper(); const result = capture({ repo, archiveRoot: archive, allowTemporary: true });
  const second = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.equal(result.rows[0].path, null);
  assert.notEqual(result.rows[0].rowId, second.rows[0].rowId, 'opaque identity changes between capture attempts');
  assert.doesNotMatch(JSON.stringify(result), /credentials\.pem|known-secret-sentinel/);
  assert.notEqual(result.rows[0].rowId, (await import('node:crypto')).createHash('sha256').update(Buffer.concat([Buffer.from('path\0'), Buffer.from('credentials.pem')])).digest('hex'));
  assert.match(result.rows[0].reason, /excluded by privacy policy/);
  const manifestPath = path.join(archive, result.captureId, 'manifest.json');
  const manifest = fs.readFileSync(manifestPath, 'utf8');
  assert.doesNotMatch(manifest, new RegExp(secret));
  assert.equal(fs.statSync(manifestPath).mode & 0o077, 0);
  assert.ok(verify({ repo, archiveRoot: archive, captureId: result.captureId }).limitations.length > 0);
});

test('credential path policy excludes common credential files without matching token module names', async (t) => {
  const { repo, archive } = fixture(t); const secret = 'credential-path-secret';
  for (const name of ['credentials.json', 'tokens.json', '.npmrc', '.netrc', 'id_ed25519']) fs.writeFileSync(path.join(repo, name), secret);
  fs.writeFileSync(path.join(repo, 'token-handler.mjs'), 'export function tokenRefresh() {}');
  const { capture } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.equal(captured.rows.filter((row) => row.path === null).length, 5);
  assert.ok(captured.rows.some((row) => row.path === 'token-handler.mjs'));
  assert.doesNotMatch(fs.readFileSync(path.join(archive, captured.captureId, 'manifest.json'), 'utf8'), new RegExp(secret));
});

test('policy facts distinguish root tmp from dot tmp and preserve the safe fixture exception', async () => {
  const { policyFacts } = await loadHelper();
  const policy = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'script/repository_artifact_policy.json'), 'utf8'));
  assert.equal(policyFacts(policy, 'tmp/run.log').ignoredPolicyCategory, 'ignored_local_tooling');
  assert.equal(policyFacts(policy, '.tmp/run.log').ignoredPolicyCategory, null);
  assert.equal(policyFacts(policy, '.planning/tmp/run.log').ignoredPolicyCategory, null);
  const fixtureRow = policyFacts(policy, 'examples/phoenix_host/.env', { tracked: true });
  assert.equal(fixtureRow.safeFixture, true);
  assert.equal(fixtureRow.forbiddenToTrackCategory, null);
  assert.equal(policyFacts(policy, 'keys/secret.pem', { tracked: true }).forbiddenToTrackCategory, 'forbidden_secret');
});

test('state projection accepts only the installed six-key and phase-scoped delta; UAT uses assertions', async () => {
  const { validateStateJsonDelta, validateUat } = await loadHelper();
  const before = { contract: '1.0.0', flavor: 'core', milestone: 'v24', phases: [{ number: '176', name: 'Local', status: 'in_progress' }, { number: '177', name: 'Maintenance', status: 'pending' }, { number: '178', name: 'Clean checkout', status: 'pending' }], next: { command: 'old', label: 'old', reason: 'old' }, updated_at: '2026-10-11T00:00:00.000Z' };
  const after = structuredClone(before); after.updated_at = '2026-10-11T01:00:00.000Z'; after.phases[0].status = 'complete'; after.phases[1].status = 'in_progress'; after.next = { command: 'next', label: 'Phase 177', reason: 'handoff' };
  assert.equal(validateStateJsonDelta(before, after), true);
  assert.throws(() => validateStateJsonDelta(before, { ...after, phases: after.phases.map((p, i) => i === 2 ? { ...p, status: 'complete' } : p) }), /178/);
  assert.throws(() => validateStateJsonDelta(before, { ...after, extra: true }), /key shape/);
  const { EXPECTED_UAT_ASSERTIONS } = await loadHelper();
  const passed = EXPECTED_UAT_ASSERTIONS.map((id) => ({ id, required: true, status: 'passed' }));
  assert.equal(validateUat({ assertions: passed, humanOnlyUnmet: false }), true);
  assert.throws(() => validateUat({ assertions: passed.map((a, i) => i === 0 ? { ...a, status: 'pending' } : a) }), /pending/);
  assert.throws(() => validateUat({ assertions: [], humanOnlyUnmet: true }), /empty/);
});
test('malformed required UAT assertion blocks the audit', async () => {
  const { validateUat } = await loadHelper();
  assert.throws(() => validateUat({ assertions: [{ id: 'bad', required: true, status: 'indeterminate' }] }), /malformed required UAT assertion/);
});

test('validation writer admits only seven task-map tail cells, sign-off marks, approval and append-only numeric audit', async () => {
  const { validateValidationDelta } = await loadHelper();
  const live = fs.readFileSync(path.join(path.dirname(helperPath), '176-VALIDATION.md'), 'utf8');
  assert.equal(validateValidationDelta(live, live), true);
  // Test a clean planning epoch as well as the actual installed post-writer
  // document. Running the suite after closeout must not append legacy audit
  // syntax to an already-audited production document.
  const auditAt = live.search(/^## (?:GSD Validation Audits|Validation Audit \d{4}-\d{2}-\d{2})/m);
  const before = (auditAt < 0 ? live : live.slice(0, auditAt)).trimEnd() + '\n';
  let after = before.replace('| Yes | Pass — 1/1 |', '| Yes | Pass — refreshed fixture |').replace('**Approval:** Draft planning contract; execution results pending.', '**Approval:** Plan 01 evidence checked; live recovery pending.');
  after += '\n## GSD Validation Audits\n\n- Gaps found: 4\n- Gaps resolved: 3\n- Gaps escalated: 1\n';
  assert.equal(validateValidationDelta(before, after), true);
  assert.throws(() => validateValidationDelta(before, after.replace('## Wave 0 Requirements', '## Wave 0 Requirement Rewrite')), /changed outside/);
  assert.throws(() => validateValidationDelta(before, after.replace('Gaps resolved: 3', 'Gaps resolved: unknown')), /exact numeric gaps/);
  const { createRequire } = await import('node:module');
  const owner = createRequire(import.meta.url)('<home>/.codex/gsd-core/bin/lib/verification.cjs');
  const installed = owner.planAuditAppend(before, { heading: 'Validation Audit', rows: { 'Gaps found': 0, Resolved: 0, Escalated: 0 }, date: '2026-10-11' });
  assert.equal(validateValidationDelta(before, installed.content), true);
});

test('render distinguishes unresolved causes and includes recovery, equality, policy, JSON link, generator owners and Phase 177 actions', async () => {
  const { render } = await loadHelper();
  const markdown = render({ capturedAt: '2026-10-11T00:00:00Z', rows: [{ rowId: 'a'.repeat(32), path: 'lib/example.ex', status: ' M', disposition: 'retain', reason: 'Semantic review remains open.', nextOwner: 'Phase 177 source owner', nextAction: 'Review linked test behavior.', comparison: { capturedHeadToIndex: 'exactly-equal', capturedIndexToWorktree: 'different', candidates: [{ semanticEquivalenceReviewed: false }] }, recovery: { restoredFromFrozenCapture: true, limitations: [] }, policyFacts: { ignoredByGit: false, trackedInCapturedIndex: true } }], generatedContracts: [{ canonicalSource: 'lib/mix/tasks/generate.ex', regenerationArgv: [['mix', 'example.gen']], outputs: ['generated/example.json'] }], artifactPolicySummary: 'Policy claims reflect Git state.' });
  assert.match(markdown, /176-INVENTORY\.json/); assert.match(markdown, /restored from frozen capture/); assert.match(markdown, /HEAD→index/); assert.match(markdown, /Phase 177 Owner and Action Table/); assert.match(markdown, /mix example\\\.gen/); assert.match(markdown, /1 need semantic review/);
});

test('handoff writer may replace only the active paragraph and cannot rewrite historical next-action text', async () => {
  const { validateStateBodyDelta, validateRoadmapBodyDelta } = await loadHelper();
  const state = '# State\n\n## Exact Next Action\n\n`$gsd-execute-phase 176 --ws quality-ratchet-release`\n\nExecute Phase 176 plan 1, then plan 2.\n\nPhase 174 passed; Phase 175 remains archived at 8/9 with REL-10 breached. The adopter gate is parked.\n\n## Deferred Items\n\nKeep these bytes.\n';
  const next = state.replace('`$gsd-execute-phase 176 --ws quality-ratchet-release`', '`$gsd-discuss-phase 177 --ws quality-ratchet-release`').replace('Execute Phase 176 plan 1, then plan 2.', 'Phase 176 passed; continue with Phase 177 maintenance.');
  assert.equal(validateStateBodyDelta(state, next), true);
  assert.throws(() => validateStateBodyDelta(state, next.replace('Phase 174 passed', 'Phase 174 rewritten')), /outside/);
  const roadmap = state.replace('## Exact Next Action', '## Exact Next Action');
  assert.equal(validateRoadmapBodyDelta(roadmap, next), true);
  assert.throws(() => validateStateBodyDelta(state, state.replace('## Exact Next Action', '## Exact Next Action\n\n`$gsd-execute-phase 176`')), /duplicated|command/);
});

test('roadmap progress writer is limited to Phase 176 cells, Phase 177 status, and the active handoff', async () => {
  const { validateRoadmapDocumentDelta, validateRequirementsDelta } = await loadHelper();
  const before = `# Roadmap\n\n## v24.0 Repository Cleanup & Maintenance\n\n**Status:** Approved 2026-10-11\n\n### Phase Details\n\n- [ ] **Phase 176: Local Work and Artifact Disposition** — classify leftover changes.\n\n## Progress\n\n| Phase | Plans Complete | Status | Completed |\n|---|---|---|---|\n| 176. Local Work and Artifact Disposition | 0/2 | Planned and checked | — |\n| 177. Maintenance and Queue Reconciliation | 0/TBD | Not started | — |\n| 178. Clean Checkout and Final CI | 0/TBD | Not started | — |\n\n## Exact Next Action\n\n\`$gsd-execute-phase 176 --ws quality-ratchet-release\`\n\nExecute the two Phase 176 plans, then run its final audit.\n\nPhase 174 passed; Phase 175 is archived at 8/9 with REL-10 breached.\n`;
  const after = before.replace('**Status:** Approved 2026-10-11', '**Status:** Complete 2026-10-11').replace('- [ ] **Phase 176:', '- [x] **Phase 176:').replace('0/2 | Planned and checked | —', '2/2 | Complete | 2026-10-11').replace('0/TBD | Not started | —', '0/TBD | Ready for discussion | —').replace('`$gsd-execute-phase 176 --ws quality-ratchet-release`', '`$gsd-discuss-phase 177 --ws quality-ratchet-release`').replace('Execute the two Phase 176 plans, then run its final audit.', 'Phase 176 is complete; proceed to the Phase 177 discussion.');
  assert.equal(validateRoadmapDocumentDelta(before, after), true);
  assert.throws(() => validateRoadmapDocumentDelta(before, after.replace('| 178. Clean Checkout and Final CI | 0/TBD | Not started | — |', '| 178. Clean Checkout and Final CI | 0/TBD | Complete | — |')), /outside/);
  const reqBefore = '- [ ] **MAINT-01:** inventory\n- [ ] **MAINT-02:** recovery\n- [ ] **MAINT-03:** later\n- [ ] **MAINT-04:** policy\n| MAINT-01 | Phase 176 | Pending |\n| MAINT-02 | Phase 176 | Pending |\n| MAINT-04 | Phase 176 | Pending |\n| MAINT-03 | Phase 177 | Pending |\n';
  const reqAfter = reqBefore.replace('- [ ] **MAINT-01:', '- [x] **MAINT-01:').replace('- [ ] **MAINT-02:', '- [x] **MAINT-02:').replace('- [ ] **MAINT-04:', '- [x] **MAINT-04:').replaceAll('Phase 176 | Pending', 'Phase 176 | Complete');
  assert.equal(validateRequirementsDelta(reqBefore, reqAfter), true);
  assert.throws(() => validateRequirementsDelta(reqBefore, reqAfter.replace('- [ ] **MAINT-03:', '- [x] **MAINT-03:')), /outside/);
  assert.throws(() => validateRequirementsDelta(reqBefore, reqAfter.replace('Phase 177 | Pending', 'Phase 177 | Complete')), /outside/);
});

test('anchored payload metadata is the file metadata even when parent modes differ', async (t) => {
  const { repo } = fixture(t);
  fs.mkdirSync(path.join(repo, 'parent'), { mode: 0o700 });
  const target = path.join(repo, 'parent', 'payload');
  fs.writeFileSync(target, 'metadata fixture\n', { mode: 0o640 });
  const { readSourceForTest } = await loadHelper();
  const got = readSourceForTest(repo, 'parent/payload');
  assert.equal(got.mode, fs.lstatSync(target).mode & 0o7777);
  assert.equal(got.bytes.toString(), 'metadata fixture\n');
  fs.chmodSync(target, 0o755);
  assert.equal(readSourceForTest(repo, 'parent/payload').mode, 0o755);
});

test('post-capture contract corrections require an exact private original/current binding', async (t) => {
  const { repo, archive } = fixture(t);
  const relative = '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs';
  fs.mkdirSync(path.dirname(path.join(repo, relative)), { recursive: true });
  fs.writeFileSync(path.join(repo, relative), 'original contract\n');
  const { capture, verify, audit } = await loadHelper();
  const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  const { publicPath, publicRelative } = phaseArtifacts(repo);
  fs.writeFileSync(publicPath, JSON.stringify({ ...captured, writerLedger: [
    { path: publicRelative, owner: 'phase evidence', allowedDelta: 'phase-evidence' },
    { path: relative, owner: 'reviewed exact contract correction', allowedDelta: 'scoped-contract-correction' }
  ] }));
  fs.writeFileSync(path.join(repo, relative), 'corrected contract\n');
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }));
  const { createHash } = await import('node:crypto');
  const hash = (text) => createHash('sha256').update(text).digest('hex');
  fs.writeFileSync(path.join(archive, captured.captureId, 'scoped-writer-corrections.json'), JSON.stringify({ captureId: captured.captureId, files: [{ path: relative, originalHash: hash('original contract\n'), correctedHash: hash('corrected contract\n') }] }), { mode: 0o400 });
  assert.equal(audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }).ok, true);
  fs.writeFileSync(path.join(repo, relative), 'unapproved change\n');
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /reviewed exact original\/current binding/);
});

test('the installed GSD publisher emits the real workstream projection shape consumed by the audit', async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-176-state-contract-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const ws = path.join(root, '.planning', 'workstreams', 'quality-ratchet-release'); fs.mkdirSync(ws, { recursive: true });
  const statePath = path.join(ws, 'STATE.md'); const roadmapPath = path.join(ws, 'ROADMAP.md');
  fs.writeFileSync(statePath, '---\ncurrent_phase: 176\n---\n# State\n');
  fs.writeFileSync(roadmapPath, '# Roadmap\n\n## v24.0 Repository Cleanup & Maintenance\n\n## Progress\n\n| Phase | Plans Complete | Status | Completed |\n|---|---|---|---|\n| 176. Local Work and Artifact Disposition | 0/2 | Planned | — |\n| 177. Maintenance and Queue Reconciliation | 0/TBD | Not started | — |\n| 178. Clean Checkout and Final CI | 0/TBD | Not started | — |\n');
  const oldWs = process.env.GSD_WORKSTREAM; process.env.GSD_WORKSTREAM = 'quality-ratchet-release';
  try {
    const { createRequire } = await import('node:module');
    const req = createRequire(import.meta.url);
    const publisher = req('<home>/.codex/gsd-core/bin/lib/state-contract.cjs');
    assert.deepEqual(publisher.publishStateContract(root), { published: true, reason: 'published' });
    const beforeText = fs.readFileSync(path.join(ws, 'state.json'), 'utf8'); const before = JSON.parse(beforeText);
    assert.match(beforeText, /^\{\n  "contract"/); assert.ok(beforeText.endsWith('\n'));
    fs.writeFileSync(roadmapPath, fs.readFileSync(roadmapPath, 'utf8').replace('| 176. Local Work and Artifact Disposition | 0/2 | Planned | — |', '| 176. Local Work and Artifact Disposition | 2/2 | Complete | 2026-10-11 |').replace('| 177. Maintenance and Queue Reconciliation | 0/TBD | Not started | — |', '| 177. Maintenance and Queue Reconciliation | 0/TBD | In Progress | — |'));
    assert.deepEqual(publisher.publishStateContract(root), { published: true, reason: 'published' });
    const afterText = fs.readFileSync(path.join(ws, 'state.json'), 'utf8');
    assert.equal((await loadHelper()).validateStateJsonDelta(before, JSON.parse(afterText)), true);
  } finally { if (oldWs === undefined) delete process.env.GSD_WORKSTREAM; else process.env.GSD_WORKSTREAM = oldWs; }
});

test('Gitlink inventory keeps the commit identity as an explicit retained limitation', async (t) => {
  const { root, repo, archive } = fixture(t);
  const nested = path.join(root, 'nested-repo'); fs.mkdirSync(nested); git(nested, 'init', '-q'); git(nested, 'config', 'user.email', 'fixture@example.invalid'); git(nested, 'config', 'user.name', 'Fixture');
  fs.writeFileSync(path.join(nested, 'source'), 'nested'); git(nested, 'add', 'source'); git(nested, 'commit', '-qm', 'nested');
  const add = gitResult(repo, '-c', 'protocol.file.allow=always', 'submodule', 'add', nested, 'module');
  assert.equal(add.status, 0);
  const { capture, verify } = await loadHelper(); const got = capture({ repo, archiveRoot: archive, allowTemporary: true });
  assert.ok(got.rows.some((r) => r.path === 'module'));
  const restored = verify({ repo, archiveRoot: archive, captureId: got.captureId });
  assert.equal(restored.ok, true);
  assert.ok(restored.limitations.some((r) => r.reason.includes('gitlink')));
});

test('subprocess failures preserve their actual spawn, exit, signal, and timeout shapes', async () => {
  const { probeSubprocess } = await loadHelper();
  assert.equal(probeSubprocess(['/definitely/missing/crosswake-176-executable']).error, 'ENOENT');
  assert.equal(probeSubprocess([process.execPath, '-e', 'process.exit(7)']).status, 7);
  assert.equal(probeSubprocess([process.execPath, '-e', "process.kill(process.pid, 'SIGTERM')"]).signal, 'SIGTERM');
  const timeout = probeSubprocess([process.execPath, '-e', 'setTimeout(()=>{},5000)'], { timeout: 30 });
  assert.ok(timeout.error === 'ETIMEDOUT' || timeout.signal === 'SIGTERM');
});

test('audit rejects duplicate identities, unsafe paths, and a mismatched rendering', async (t) => {
  const { repo, archive } = fixture(t); fs.writeFileSync(path.join(repo, 'untracked.txt'), 'private payload sentinel');
  const { capture, verify, audit, render } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true }); verify({ repo, archiveRoot: archive, captureId: captured.captureId });
  const { publicPath, renderedPath } = phaseArtifacts(repo);
  fs.writeFileSync(publicPath, JSON.stringify(captured, null, 2) + '\n'); fs.writeFileSync(renderedPath, render(captured));
  assert.equal(audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, renderedPath }).ok, true);
  assert.doesNotMatch(fs.readFileSync(renderedPath, 'utf8'), /private payload sentinel|archive/);
  const duplicate = { ...captured, rows: [captured.rows[0], captured.rows[0]] };
  fs.writeFileSync(publicPath, JSON.stringify(duplicate));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath }), /duplicated/);
  const unsafe = { ...captured, rows: captured.rows.map((r) => ({ ...r, path: '/private/secret' })) };
  fs.writeFileSync(publicPath, JSON.stringify(unsafe));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath }), /unsafe/);
});

test('final audit accepts only the named STATE handoff span and rejects historical rewrites or new paths', async (t) => {
  const { repo, archive, root } = fixture(t);
  const ws = path.join(repo, '.planning/workstreams/quality-ratchet-release'); fs.mkdirSync(path.join(ws, 'phases/176-local-work-and-artifact-disposition'), { recursive: true });
  const statePath = path.join(ws, 'STATE.md');
  const uatPath = path.join(ws, 'phases/176-local-work-and-artifact-disposition/176-UAT.md');
  const original = `---\ngsd_state_version: "1.0"\nmilestone: v24.0\ncurrent_phase: 176\ncurrent_phase_name: Local Work\nstatus: executing\nstopped_at: started\nlast_updated: "2026-10-11T00:00:00Z"\nlast_activity: 2026-10-11\nlast_activity_desc: starting\nstate_head: abc\nprogress:\n  total_phases: 3\n  completed_phases: 0\n  total_plans: 2\n  completed_plans: 0\n  percent: 0\nlast_completed_phase: 174\narchived_phase_with_gaps: 175\ncurrent_plan: 1\n---\n# State\n\n## Current Position\n\nPhase: 176 (Local Work) — EXECUTING\nPlan: 1 of 2\nStatus: Executing Phase 176\nLast activity: 2026-10-11 — started\n\n## Exact Next Action\n\n\`$gsd-execute-phase 176 --ws quality-ratchet-release\`\n\nExecute Plan 01, then Plan 02.\n\nPhase 174 passed; Phase 175 remains archived at 8/9 with REL-10 breached. The adopter gate stays parked.\n\n## Archive and Limits\n\nHistorical bytes stay fixed.\n\n## Session\n\n**Last session:** old\n**Stopped at:** old\n**Resume file:** old\n`;
  fs.writeFileSync(statePath, original); git(repo, 'add', '.'); git(repo, 'commit', '-qm', 'capture writer baseline');
  const { publicPath, publicRelative } = phaseArtifacts(repo);
  fs.writeFileSync(statePath, original.replace('status: executing', 'status: capturing'));
  fs.writeFileSync(publicPath, JSON.stringify({ priorEvidence: true }));
  const { capture, verify, audit, EXPECTED_UAT_ASSERTIONS } = await loadHelper(); const captured = capture({ repo, archiveRoot: archive, allowTemporary: true });
  fs.writeFileSync(publicPath, JSON.stringify(captured));
  verify({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath });
  const publicData = { ...captured, writerLedger: [
    { path: '.planning/workstreams/quality-ratchet-release/STATE.md', owner: 'installed GSD state writer', allowedDelta: 'state-handoff' },
    { path: publicRelative, owner: 'phase evidence writer', allowedDelta: 'phase-evidence' },
    { path: '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-UAT.md', owner: 'automated UAT gate', allowedDelta: 'conditional-gate', conditionMet: true, producerReceipt: { path: '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-UAT.md', captureId: captured.captureId, observedStatus: '??' } }
  ] };
  fs.writeFileSync(publicPath, JSON.stringify(publicData, null, 2) + '\n');
  const falseCondition = structuredClone(publicData); falseCondition.writerLedger[2].conditionMet = false; fs.writeFileSync(publicPath, JSON.stringify(falseCondition));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /true condition and artifact-bound producer receipt/);
  fs.writeFileSync(publicPath, JSON.stringify(publicData));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /receipt is stale or does not match/);
  const updated = original.replace('current_phase: 176', 'current_phase: 177').replace('status: executing', 'status: complete').replace('completed_phases: 0', 'completed_phases: 1').replace('completed_plans: 0', 'completed_plans: 2').replace('percent: 0', 'percent: 33').replace('last_completed_phase: 174', 'last_completed_phase: 176').replace('Phase: 176 (Local Work) — EXECUTING', 'Phase: 177 (Maintenance) — PLANNED').replace('Status: Executing Phase 176', 'Status: Phase 176 complete').replace('`$gsd-execute-phase 176 --ws quality-ratchet-release`', '`$gsd-discuss-phase 177 --ws quality-ratchet-release`').replace('Execute Plan 01, then Plan 02.', 'Phase 176 is complete; begin the Phase 177 discussion.').replace('**Last session:** old', '**Last session:** 2026-10-11').replace('**Stopped at:** old', '**Stopped at:** Completed 176-02-PLAN.md').replace('**Resume file:** old', '**Resume file:** None');
  fs.writeFileSync(statePath, updated);
  const passedUat = EXPECTED_UAT_ASSERTIONS.map((id) => ({ id, required: true, status: 'passed' }));
  fs.writeFileSync(uatPath, JSON.stringify({ assertions: passedUat, humanOnlyUnmet: false }));
  assert.equal(audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }).ok, true);
  assert.ok(fs.existsSync(path.join(archive, captured.captureId, 'final-audit.json')));
  fs.writeFileSync(statePath, updated.replace('Phase 174 passed', 'Phase 174 history rewritten'));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /outside its command and active handoff/);
  fs.writeFileSync(statePath, updated); fs.writeFileSync(uatPath, JSON.stringify({ assertions: passedUat.map((a, i) => i === 0 ? { ...a, status: 'pending' } : a) }));
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /pending/);
  fs.writeFileSync(uatPath, JSON.stringify({ assertions: passedUat, humanOnlyUnmet: false }));
  fs.writeFileSync(path.join(repo, 'unowned.txt'), 'new');
  assert.throws(() => audit({ repo, archiveRoot: archive, captureId: captured.captureId, publicPath, final: true }), /unowned changed path/);
});

