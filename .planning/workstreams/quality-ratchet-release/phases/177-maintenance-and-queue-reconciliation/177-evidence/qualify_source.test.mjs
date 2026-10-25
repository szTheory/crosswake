import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, readdirSync, lstatSync, chmodSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { fetchAttestedCommit, qualifySource } from './qualify_source.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const cli = path.join(here, 'qualify_source.mjs');
const gsdTools = '<home>/.codex/gsd-core/bin/gsd-tools.cjs';
const run = (cmd, args, cwd, env = process.env) => spawnSync(cmd, args, { cwd, env, encoding: 'utf8' });
const git = (cwd, ...args) => {
  const r = run('git', args, cwd);
  assert.equal(r.status, 0, `git ${args.join(' ')} failed: ${r.stderr}`);
  return r.stdout.trim();
};
const invoke = (verb, args, env = process.env) => run(process.execPath, [cli, verb, ...args], here, env);
const temp = () => mkdtempSync(path.join(os.tmpdir(), 'crosswake-177-qualify-'));
const snapshot = (p) => {
  const s = lstatSync(p);
  return { mode: s.mode & 0o777, mtime: s.mtimeMs, bytes: readFileSync(p) };
};

test('probe checks installed GSD response keys and real git subprocess behavior', () => {
  const root = temp();
  try {
    const repo = path.join(root, 'source');
    mkdirSync(repo);
    git(root, 'init', '--bare', 'remote.git');
    git(root, 'clone', path.join(root, 'remote.git'), repo);
    git(repo, 'config', 'user.name', 'Fixture');
    git(repo, 'config', 'user.email', 'fixture@example.invalid');
    writeFileSync(path.join(repo, 'file.txt'), 'fixture\n');
    git(repo, 'add', 'file.txt'); git(repo, 'commit', '-m', 'fixture');
    git(repo, 'push', '-u', 'origin', 'HEAD');
    const r = invoke('probe', ['--repo', repo, '--public', path.join(root, 'binding.json')]);
    assert.equal(r.status, 0, r.stderr);
    const result = JSON.parse(r.stdout);
    assert.equal(result.probe, 'passed');
    assert.equal(Object.hasOwn(result.gsd, 'project_root'), false);
    assert.equal(Object.hasOwn(result.gsd, 'default_workspace_base'), false);
    assert.equal(result.git.clone.exitCode, 0);
    assert.equal(result.git.checkout.exitCode, 0);
    assert.equal(result.git.fetch.exitCode, 0);
    assert.equal(result.gsd.is_git_repo, true);
    assert.equal(result.gsd.repository_name, 'crosswake');
    assert.equal(result.gsd.workspace_base_configured, true);
    assert.doesNotMatch(JSON.stringify(result), new RegExp(root.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('public errors omit private paths, stderr, sentinels, payloads, and invalid flag values', () => {
  const root = temp();
  const sentinel = 'PRIVATE_PATH_SENTINEL_177';
  try {
    const privatePath = path.join(root, `${sentinel}-missing.json`);
    const missing = invoke('probe', ['--repo', privatePath, '--public', path.join(root, 'public.json')]);
    assert.notEqual(missing.status, 0);
    assert.match(missing.stderr, /class=ENOENT/);
    assert.doesNotMatch(`${missing.stdout}${missing.stderr}`, new RegExp(sentinel));
    assert.doesNotMatch(`${missing.stdout}${missing.stderr}`, new RegExp(root.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    const invalid = invoke('probe', ['--repo', root, '--unknown', `${sentinel}{"account":"PRIVATE_PAYLOAD_SENTINEL"}`]);
    assert.notEqual(invalid.status, 0);
    assert.match(invalid.stderr, /cause=usage-denied/);
    assert.doesNotMatch(`${invalid.stdout}${invalid.stderr}`, /PRIVATE_PATH_SENTINEL_177|PRIVATE_PAYLOAD_SENTINEL/);
    const repo = path.join(root, `${sentinel}-repo`); const clone = path.join(root, 'clone'); const handoff = path.join(root, 'handoff');
    mkdirSync(repo); mkdirSync(clone); mkdirSync(handoff, { mode: 0o700 });
    const subprocessFailure = invoke('qualify', [
      '--repo', repo, '--clone', clone, '--base-commit', 'a'.repeat(40), '--base-tree', 'b'.repeat(40),
      '--inventory', path.join(root, 'inventory.json'), '--maintenance', path.join(root, 'maintenance.json'),
      '--archive-root', path.join(root, 'archive'), '--handoff-root', handoff, '--public', path.join(root, 'public.json'),
    ]);
    assert.notEqual(subprocessFailure.status, 0);
    assert.match(subprocessFailure.stderr, /git stage=config cause=nonzero-exit exit=1/);
    assert.doesNotMatch(`${subprocessFailure.stdout}${subprocessFailure.stderr}`, /PRIVATE_PATH_SENTINEL_177|PRIVATE_PAYLOAD_SENTINEL|\/private\//);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('canonical fetch adapter uses its fixed URL, exact SHA, and object-only Git behavior', () => {
  const root = temp();
  try {
    const remote = path.join(root, 'canonical.git'); const seed = path.join(root, 'seed');
    git(root, 'init', '--bare', remote); mkdirSync(seed); git(seed, 'init');
    git(seed, 'config', 'user.name', 'Fixture'); git(seed, 'config', 'user.email', 'fixture@example.invalid');
    writeFileSync(path.join(seed, 'source.txt'), 'attested source\n'); git(seed, 'add', 'source.txt'); git(seed, 'commit', '-m', 'attested');
    const commit = git(seed, 'rev-parse', 'HEAD'); const tree = git(seed, 'rev-parse', 'HEAD^{tree}');
    git(seed, 'remote', 'add', 'origin', remote); git(seed, 'push', 'origin', 'HEAD');
    const makeEmptyClone = (name) => { const clone = path.join(root, name); mkdirSync(clone); git(clone, 'init'); return clone; };
    const actualFetch = (clone, expectedTree) => fetchAttestedCommit(clone, commit, expectedTree, (program, argv, options) => {
      assert.equal(program, 'git');
      assert.deepEqual(argv.slice(2, 5), ['fetch', '--no-write-fetch-head', '--no-tags']);
      assert.equal(argv[5], 'https://github.com/szTheory/crosswake.git');
      assert.equal(argv[6], commit);
      const localArgv = [...argv]; localArgv[5] = remote;
      return spawnSync(program, localArgv, options);
    });
    const clone = makeEmptyClone('success-clone');
    const beforeHeadFile = readFileSync(path.join(clone, '.git', 'HEAD'));
    const result = actualFetch(clone, tree);
    assert.equal(result.commit, commit);
    assert.equal(result.tree, tree);
    assert.deepEqual(readFileSync(path.join(clone, '.git', 'HEAD')), beforeHeadFile);
    assert.equal(git(clone, 'status', '--porcelain'), '');
    assert.equal(git(clone, 'cat-file', '-e', `${commit}^{commit}`), '');

    const mismatchClone = makeEmptyClone('mismatch-clone');
    assert.throws(() => actualFetch(mismatchClone, 'f'.repeat(40)), (error) => {
      assert.equal(error.publicCause?.cause, 'attestation-mismatch');
      assert.doesNotMatch(error.message, /PRIVATE|canonical\.git/);
      return true;
    });
    assert.equal(git(mismatchClone, 'status', '--porcelain'), '');

    const failedClone = makeEmptyClone('failed-clone');
    const missingCommit = 'e'.repeat(40);
    assert.throws(() => fetchAttestedCommit(failedClone, missingCommit, 'd'.repeat(40), (program, argv, options) => {
      const localArgv = [...argv]; localArgv[5] = remote;
      return spawnSync(program, localArgv, options);
    }), (error) => {
      assert.deepEqual(error.publicCause, { program: 'git', stage: 'fetch', cause: 'nonzero-exit', exitCode: 128 });
      assert.doesNotMatch(error.message, /canonical\.git|PRIVATE_PATH_SENTINEL/);
      return true;
    });

    const subprocessCases = [
      (program, argv, options) => spawnSync('/missing/PRIVATE_PATH_SENTINEL/git', argv, options),
      (_program, _argv, options) => spawnSync(process.execPath, ['-e', 'process.kill(process.pid, "SIGTERM")'], options),
    ];
    for (const [index, spawn] of subprocessCases.entries()) {
      assert.throws(() => fetchAttestedCommit(`/private/PRIVATE_PATH_SENTINEL/${index}`, commit, tree, spawn), (error) => {
        assert.equal(error.publicCause?.program, 'git');
        assert.equal(error.publicCause?.stage, 'fetch');
        assert.ok(['spawn-error', 'signal'].includes(error.publicCause?.cause));
        assert.doesNotMatch(error.message, /PRIVATE_PATH_SENTINEL/);
        return true;
      });
    }
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('argv allowlists reject wrong-verb, duplicate, unknown, positional, empty, and missing values before effects', () => {
  const root = temp();
  try {
    const repo = path.join(root, 'repo'); mkdirSync(repo); git(repo, 'init');
    const publicPath = path.join(root, 'public.json');
    const bad = [
      ['probe', ['--repo', repo, '--clone', path.join(root, 'side-effect')]],
      ['probe', ['--repo', repo, '--repo', repo]],
      ['probe', ['--repo', repo, '--unknown', 'x']],
      ['probe', ['--repo', repo, 'extra']],
      ['probe', ['--repo', '']],
      ['probe', ['--repo']],
      ['qualify', ['--scope', 'tracer', '--scope', 'complete']],
      ['qualify', ['--scope', 'bad']],
      ['record-patch', ['--owner', '177-04']],
    ];
    for (const [verb, args] of bad) assert.notEqual(invoke(verb, args).status, 0, `${verb} ${args.join(' ')}`);
    assert.equal(readdirSync(root).some((n) => n === 'side-effect'), false);
    assert.equal(requireExists(publicPath), false);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

function requireExists(p) { try { lstatSync(p); return true; } catch { return false; } }

test('tracer qualification pins base, preserves HEAD/index/worktree separately, and overlays a nonconflicting row', () => {
  const root = temp();
  try {
    const source = path.join(root, 'source'); mkdirSync(source); git(source, 'init');
    git(source, 'config', 'user.name', 'Fixture'); git(source, 'config', 'user.email', 'fixture@example.invalid');
    git(source, 'config', 'remote.origin.url', 'https://github.com/szTheory/crosswake.git');
    writeFileSync(path.join(source, 'tracked.txt'), 'base\n'); git(source, 'add', '.'); git(source, 'commit', '-m', 'base');
    const sourceHead = git(source, 'rev-parse', 'HEAD'); const sourceTree = git(source, 'rev-parse', 'HEAD^{tree}');
    const sourceBranch = git(source, 'branch', '--show-current');
    git(source, 'checkout', '-b', 'candidate'); writeFileSync(path.join(source, 'tracked.txt'), 'remote\n'); git(source, 'add', 'tracked.txt'); git(source, 'commit', '-m', 'candidate');
    const base = git(source, 'rev-parse', 'HEAD'); const tree = git(source, 'rev-parse', 'HEAD^{tree}');
    git(source, 'checkout', sourceBranch);
    writeFileSync(path.join(source, 'tracked.txt'), 'staged\n'); git(source, 'add', 'tracked.txt'); writeFileSync(path.join(source, 'tracked.txt'), 'worktree\n');
    const staged = git(source, 'show', ':tracked.txt');
    assert.equal(staged, 'staged');
    writeFileSync(path.join(source, 'new-owner.ex'), 'independent owner row\n');
    const clone = path.join(root, 'clone'); git(root, 'clone', source, clone); git(clone, 'checkout', '-b', 'workspace/fixture'); git(clone, 'checkout', '--detach', 'HEAD');
    git(clone, 'config', 'remote.origin.url', 'https://github.com/szTheory/crosswake.git');
    git(clone, 'checkout', '--detach', base);
    assert.equal(git(clone, 'rev-parse', 'HEAD^{tree}'), tree);
    const captureId = '20261012024114124-721bf696c185e4de';
    const archive = path.join(root, 'archive'); mkdirSync(archive, { mode: 0o700 });
    const captureDir = path.join(archive, captureId); mkdirSync(captureDir, { mode: 0o700 });
    const attestDir = path.join(archive, '.attestations'); mkdirSync(attestDir, { mode: 0o700 });
    const digest = (value) => createHash('sha256').update(value).digest('hex');
    const rowId = 'a'.repeat(32); const addedId = 'b'.repeat(32);
    const manifest = { format: 1, captureId, source: { head: sourceHead, headTree: sourceTree }, rows: [
      { rowId, pathBytes: Buffer.from('tracked.txt').toString('base64'), xy: ' M', index: [{ stage: 0, mode: '100644', snapshot: { kind: 'file', mode: 0o644, data: Buffer.from('staged\n').toString('base64') } }], worktree: { kind: 'file', mode: 0o644, data: Buffer.from('worktree\n').toString('base64') } },
      { rowId: addedId, pathBytes: Buffer.from('new-owner.ex').toString('base64'), xy: '??', index: [], worktree: { kind: 'file', mode: 0o644, data: Buffer.from('independent owner row\n').toString('base64') } },
    ] };
    const manifestBytes = Buffer.from(JSON.stringify(manifest));
    const proof = { captureId, manifestHash: digest(manifestBytes), provenance: { verified: true, candidates: [{ commit: base, tree, ancestor: true, parentsVerified: true }] }, rows: { [rowId]: {}, [addedId]: {} } };
    const proofBytes = Buffer.from(JSON.stringify(proof));
    writeFileSync(path.join(captureDir, 'manifest.json'), manifestBytes, { mode: 0o400 }); chmodSync(path.join(captureDir, 'manifest.json'), 0o400);
    writeFileSync(path.join(captureDir, 'verified-proof.json'), proofBytes, { mode: 0o400 }); chmodSync(path.join(captureDir, 'verified-proof.json'), 0o400);
    writeFileSync(path.join(attestDir, `${captureId}.sha256`), `${digest(manifestBytes)}\n`, { mode: 0o400 }); chmodSync(path.join(attestDir, `${captureId}.sha256`), 0o400);
    writeFileSync(path.join(attestDir, `${captureId}.proof.sha256`), `${digest(proofBytes)}\n`, { mode: 0o400 }); chmodSync(path.join(attestDir, `${captureId}.proof.sha256`), 0o400);
    const inventory = { captureId, rows: [{ rowId, path: 'tracked.txt', status: ' M' }, { rowId: addedId, path: 'new-owner.ex', status: '??' }], sourceComparison: { candidates: [{ commit: base, tree }] } };
    const maintenance = { rows: [{ rowId, semanticOwner: 'Phase 177 source owner for tracked.txt.' }, { rowId: addedId, semanticOwner: 'Phase 177 source owner for new-owner.ex.' }] };
    const inventoryPath = path.join(root, 'inventory.json'); const maintenancePath = path.join(root, 'maintenance.json');
    writeFileSync(inventoryPath, JSON.stringify(inventory)); writeFileSync(maintenancePath, JSON.stringify(maintenance));
    const handoff = path.join(root, 'handoff'); mkdirSync(handoff, { mode: 0o700 });
    const binding = path.join(root, 'binding.json');
    const sourceEnv = { CROSSWAKE_177_BASE_COMMIT: base, CROSSWAKE_177_BASE_TREE: tree };
    const withSourceEnv = (fn) => {
      const prior = Object.fromEntries(Object.keys(sourceEnv).map((key) => [key, process.env[key]]));
      Object.assign(process.env, sourceEnv);
      try { return fn(); } finally { for (const [key, value] of Object.entries(prior)) value == null ? delete process.env[key] : process.env[key] = value; }
    };
    const localFetch = (cloneRoot, commit, commitTree) => fetchAttestedCommit(cloneRoot, commit, commitTree, (program, argv, options) => {
      assert.equal(program, 'git');
      assert.equal(argv[0], '-C');
      assert.equal(argv[2], 'fetch');
      assert.equal(argv[5], 'https://github.com/szTheory/crosswake.git');
      const localArgv = [...argv]; localArgv[5] = source;
      return spawnSync(program, localArgv, options);
    });
    const qualify = (scope, treeValue) => withSourceEnv(() => qualifySource({
      '--scope': scope, '--repo': source, '--clone': clone, '--base-commit': base, '--base-tree': treeValue,
      '--inventory': inventoryPath, '--maintenance': maintenancePath, '--archive-root': archive,
      '--handoff-root': handoff, '--public': binding,
    }, localFetch));
    qualify('tracer', tree);
    const publicBinding = JSON.parse(readFileSync(binding, 'utf8'));
    assert.equal(publicBinding.status, 'tracer-qualified');
    assert.deepEqual(publicBinding.tracer.partitions, ['HEAD', 'index', 'worktree']);
    assert.equal(publicBinding.tracer.status, 'safe-overlay');
    const privateFiles = readdirSync(handoff);
    assert.ok(privateFiles.includes('partitions.json'));
    const privateParts = JSON.parse(readFileSync(path.join(handoff, 'partitions.json'), 'utf8'));
    assert.equal(Buffer.from(privateParts.rows.find((r) => r.rowId === rowId).partitions.head.bytes, 'base64').toString(), 'base\n');
    assert.equal(Buffer.from(privateParts.rows.find((r) => r.rowId === rowId).partitions.index.bytes, 'base64').toString(), 'staged\n');
    assert.equal(Buffer.from(privateParts.rows.find((r) => r.rowId === rowId).partitions.worktree.bytes, 'base64').toString(), 'worktree\n');
    assert.equal(readFileSync(path.join(clone, 'new-owner.ex'), 'utf8'), 'independent owner row\n');
    assert.equal(git(clone, 'status', '--porcelain').includes('new-owner.ex'), true);
    assert.ok(!JSON.stringify(publicBinding).includes(String(root)));
    assert.throws(() => qualify('complete', 'c'.repeat(40)), /clone is not checked out at the attested source commit\/tree/);
    qualify('complete', tree);
    const completeBinding = JSON.parse(readFileSync(binding, 'utf8'));
    assert.equal(completeBinding.counts.blockedConflict, 1);
    assert.equal(completeBinding.rows.find((r) => r.rowId === rowId).status, 'blocked-conflict');
    assert.equal(readFileSync(path.join(clone, 'tracked.txt'), 'utf8'), 'remote\n');
    const attestation = path.join(attestDir, `${captureId}.sha256`); chmodSync(attestation, 0o600); writeFileSync(attestation, 'tampered\n'); chmodSync(attestation, 0o400);
    assert.throws(() => qualify('complete', tree), /private archive attestation mismatch/);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('sealed 0400 archive bytes, modes and mtimes are read-only; exposed archive is rejected', () => {
  const root = temp();
  try {
    const archive = path.join(root, 'archive'); mkdirSync(archive, { mode: 0o700 });
    const capture = path.join(archive, 'capture'); mkdirSync(capture, { mode: 0o700 });
    const manifest = path.join(capture, 'manifest.json'); const proof = path.join(capture, 'verified-proof.json'); const att = path.join(capture, 'attestation.sha256');
    for (const file of [manifest, proof, att]) { writeFileSync(file, 'sealed'); chmodSync(file, 0o400); }
    const before = [manifest, proof, att].map(snapshot);
    const result = invoke('probe', ['--repo', root, '--public', path.join(root, 'public.json')], { ...process.env, CROSSWAKE_177_FIXTURE_ARCHIVE: archive });
    assert.equal(result.status, 0, result.stderr);
    const after = [manifest, proof, att].map(snapshot);
    for (let i = 0; i < before.length; i++) {
      assert.equal(after[i].mode, 0o400);
      assert.equal(after[i].mtime, before[i].mtime);
      assert.deepEqual(after[i].bytes, before[i].bytes);
    }
    chmodSync(archive, 0o755);
    const denied = invoke('probe', ['--repo', root, '--public', path.join(root, 'public.json')], { ...process.env, CROSSWAKE_177_FIXTURE_ARCHIVE: archive });
    assert.notEqual(denied.status, 0);
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test('all planned downstream record-patch owner argv shapes parse and unknown owners deny', () => {
  for (const owner of ['177-02', '177-03', '177-05']) {
    const r = invoke('record-patch', ['--owner', owner, '--clone', '/missing/clone', '--base-commit', 'a'.repeat(40), '--base-tree', 'b'.repeat(40), '--handoff-root', '/missing/handoff', '--public', '/missing/binding.json']);
    assert.notEqual(r.status, 2, `${owner} was rejected as parser usage`);
  }
});

test('record-patch requires a complete binding and privately bundles untracked bytes with replay proof', () => {
  const root = temp();
  try {
    const source = path.join(root, 'source'); const clone = path.join(root, 'clone'); const handoff = path.join(root, 'handoff');
    mkdirSync(source); mkdirSync(handoff, { mode: 0o700 });
    git(source, 'init'); git(source, 'config', 'user.name', 'Fixture'); git(source, 'config', 'user.email', 'fixture@example.invalid');
    git(source, 'config', 'remote.origin.url', 'https://github.com/szTheory/crosswake.git');
    writeFileSync(path.join(source, 'tracked.txt'), 'base\n'); git(source, 'add', 'tracked.txt'); git(source, 'commit', '-m', 'base');
    const base = git(source, 'rev-parse', 'HEAD'); const tree = git(source, 'rev-parse', 'HEAD^{tree}');
    git(root, 'clone', source, clone); git(clone, 'config', 'user.name', 'Fixture'); git(clone, 'config', 'user.email', 'fixture@example.invalid');
    writeFileSync(path.join(clone, 'tracked.txt'), 'changed\n'); const untrackedBytes = Buffer.from('new source owner\n'); writeFileSync(path.join(clone, 'new-owner.txt'), untrackedBytes);
    const makeBinding = (status) => {
      const payload = { schemaVersion: 1, phase: 177, plan: 8, captureId: 'fixture', baseCommit: base, baseTree: tree, status, scope: 'complete', rows: [], counts: { unresolved: 0 }, semanticSelection: { status: status === 'complete-qualified' ? 'complete' : 'partial' }, patches: [] };
      return { ...payload, bindingDigest: createHash('sha256').update(JSON.stringify(payload)).digest('hex') };
    };
    const publicPath = path.join(root, 'binding.json'); writeFileSync(publicPath, JSON.stringify(makeBinding('qualified-with-blocked-rows')));
    const argv = ['record-patch', '--owner', '177-02', '--clone', clone, '--base-commit', base, '--base-tree', tree, '--handoff-root', handoff, '--public', publicPath];
    assert.notEqual(invoke('record-patch', argv.slice(1)).status, 0, 'partial binding must be denied');
    writeFileSync(publicPath, JSON.stringify(makeBinding('complete-qualified')));
    const result = invoke('record-patch', argv.slice(1));
    assert.equal(result.status, 0, result.stderr);
    const publicBinding = JSON.parse(readFileSync(publicPath, 'utf8'));
    assert.equal(publicBinding.patches[0].owner, '177-02');
    assert.equal(Object.hasOwn(publicBinding.patches[0], 'patchDigest'), false);
    assert.equal(JSON.stringify(publicBinding).includes(handoff), false);
    const bundlePath = path.join(handoff, 'cumulative-177-02.bundle.json');
    const bundle = JSON.parse(readFileSync(bundlePath, 'utf8'));
    assert.equal(bundle.untrackedFiles, 1);
    assert.equal(Buffer.from(bundle.untracked[0].bytes, 'base64').toString(), untrackedBytes.toString());
    assert.equal((lstatSync(bundlePath).mode & 0o777), 0o600);
    assert.equal(JSON.parse(readFileSync(path.join(handoff, 'cumulative-177-02.json'), 'utf8')).untrackedFiles, 1);
  } finally { rmSync(root, { recursive: true, force: true }); }
});
